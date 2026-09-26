;;; REHEARSE THE REAL BOOT — startup/load.lisp, end to end — WITHOUT LISTENING.
;;;
;;; This exists to protect a restart. `init.lisp` wraps the boot in a handler-case that
;;; PRINTS the error and carries on, so a boot failure is silent: the process stays up,
;;; `(start-das)` never runs, and the application has NO ACCEPTOR. That is exactly how the
;;; build-order defect (PENDING-WORK §1c) would have presented — as a site that simply
;;; does not answer, with nothing obvious to explain it.
;;;
;;; So this runs the SAME file the service loads, with ONE stub: `hunchentoot:start` does
;;; not listen. Everything else the boot does happens for real — the 16 dependencies, the
;;; whole tree, the acceptor's construction, the DB connection, the session secret, the
;;; cached lists, the template tables, the business server, the function symbol table.
;;; NO PORT IS BOUND, so this cannot conflict with the running image, and it is not
;;; "starting a server" — nothing is served.
;;;
;;; What it CANNOT prove: that the port binds, and that requests are served. That is the
;;; restart, and only the restart.
;;;
;;; Errors are NOT swallowed here — the opposite of init.lisp — because the whole point
;;; is to see them.

(load "~/quicklisp/setup.lisp")
;; The two things startup/load.lisp assumes are already in place, done the way init.lisp
;; and this session's tooling do them.
(ql:quickload :swank :silent t)                 ; init.lisp quickloads swank FIRST; the
                                                ; tree reads the package at compile time
(push "/home/ubuntu/ninestores/hhub/" asdf:*central-registry*)
(push #p"/tmp/nst-asdf/clsql-dist/clsql-20221106-git/" asdf:*central-registry*)
;; clsql-mysql's C component writes its foreign library into a source directory owned by
;; hunchentoot; the writable copy above is what makes it loadable as another user.

(format t "~&REHEARSAL: stubbing hunchentoot:start so nothing listens~%")
(let ((real-start (symbol-function 'hunchentoot:start))
      (started '()))
  (setf (symbol-function 'hunchentoot:start)
        (lambda (acceptor &rest args)
          (declare (ignore args))
          ;; Record what WOULD have been served, then do not listen.
          (push (list :would-listen
                      :port (ignore-errors (hunchentoot:acceptor-port acceptor))
                      :class (class-name (class-of acceptor)))
                started)
          acceptor))
  (unwind-protect
       (handler-case
           (progn
             ;; THE REAL BOOT, the same file /etc/init.d/hunchentoot's init.lisp loads.
             (load "/home/ubuntu/ninestores/startup/load.lisp")
             (format t "~&REHEARSAL: startup/load.lisp COMPLETED~%")
             (format t "~&REHEARSAL: acceptors it tried to start: ~S~%" (reverse started))
             (in-package :nstores)
             (format t "~&REHEARSAL: server-running-p = ~S~%" *server-running-p*)
             ;; The two classes the invoice API needs, and the dispatcher that routes to it.
             (dolist (c '(nst-invh nst-invitm NstInvhResponseModel invh-public-url-response
                          invh-detail-response))
               (format t "~&REHEARSAL:   class ~A = ~A~%" c (and (find-class c nil) t)))
             (format t "~&REHEARSAL:   com-hhub-api-dispatch fbound = ~A~%"
                     (and (fboundp 'com-hhub-api-dispatch) t))
             (format t "~&REHEARSAL:   find-api-route /invoices/23/public = ~A~%"
                     (let ((r (find-api-route :get "/hhub/api/v1/invoices/23/public")))
                       (and r (api-route-key r))))
             (format t "~&REHEARSAL: RESULT = BOOT OK (nothing was listening)~%")
             (sb-ext:exit :code 0))
         (error (c)
           (format t "~&~%REHEARSAL: RESULT = BOOT FAILED~%REHEARSAL:   ~A~%" c)
           ;; init.lisp would swallow this; here it is the finding.
           (sb-ext:exit :code 1)))
    (setf (symbol-function 'hunchentoot:start) real-start)))
