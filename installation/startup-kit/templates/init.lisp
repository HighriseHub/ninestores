;;; init.lisp — what the acceptor image does at boot. Rendered by
;;; installation/startup-kit/05-install-hunchentoot-service.sh into
;;; @REPO@/startup/init.lisp, then loaded by start-hunchentoot through
;;; detachtty. SBCL also reads ~@APP_USER@/.sbclrc first (Quicklisp setup),
;;; which is why ql:quickload works below.
;;;
;;; Order matters here:
;;;   1. Swank FIRST, so that if the system load below fails you still have a
;;;      REPL on :@SWANK_PORT@ to find out why (and to fix it without a restart);
;;;   2. load the system, guarded — a failure must not take the image down
;;;      before it reaches the shutdown socket, or the box has no acceptor AND
;;;      no way to stop it cleanly;
;;;   3. then block on the shutdown port, which is the ONLY thing keeping the
;;;      image alive. When something connects, fall through and quit.

(ql:quickload 'swank)

(defparameter *shutdown-port* @SHUTDOWN_PORT@) ; must match /etc/init.d/hunchentoot
(defparameter *swank-port* @SWANK_PORT@)       ; remote interaction (swank-eval.py)

(defparameter *swank-server*
  (swank:create-server :port *swank-port* :dont-close t))
(format t "~&Swank listening on ~A~%" *swank-port*)

;;; Load the platform BEFORE blocking for the shutdown signal.
(handler-case
    (load "@REPO@/startup/load.lisp")
  (error (e)
    ;; Deliberately do not re-signal: a load error must leave Swank reachable so
    ;; the failure can be diagnosed in the live image. Look for this line in
    ;; ~@APP_USER@/log/hunchentoot.dribble.
    (format t "~&ERROR DURING SYSTEM LOAD: ~A~%" e)))

;;; Shutdown channel: bind, listen, accept exactly one connection, close.
;;; `telnet 127.0.0.1 *shutdown-port*' from the init script's stop branch is the
;;; whole protocol. Nothing else may hold this port — a second image cannot start
;;; while this one lives.
(let ((socket (make-instance 'sb-bsd-sockets:inet-socket
                             :type :stream :protocol :tcp)))
  (sb-bsd-sockets:socket-bind socket #(127 0 0 1) *shutdown-port*)
  (sb-bsd-sockets:socket-listen socket 1)
  (multiple-value-bind (client-socket addr port)
      (sb-bsd-sockets:socket-accept socket)
    (declare (ignore addr port))
    (sb-bsd-sockets:socket-close client-socket)
    (sb-bsd-sockets:socket-close socket)))

;;; Take every other thread down with us, Swank included, then quit.
(format t "~&Shutdown requested on port ~A — terminating threads~%" *shutdown-port*)
(dolist (thread (sb-thread:list-all-threads))
  (unless (equal sb-thread:*current-thread* thread)
    (sb-thread:terminate-thread thread)))
(sleep 1)
(sb-ext:quit)
