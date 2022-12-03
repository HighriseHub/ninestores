(ql:quickload 'swank)

;; define some parameters for easier update
(defparameter *shutdown-port* 6200)  ; The port SBCL will be listening for shutdown
                                     ; this port is the same used in /etc/init.d/hunchentoot
(defparameter *swank-port* 4016)     ; The port used for remote interaction with slime

;; Start the Swank server
(defparameter *swank-server*
  (swank:create-server :port *swank-port* :dont-close t))

;;;Do not do anything here. Just create the swank port, start swank server and exit. 


;;; We need a way to actually kill this baby so we
;;; setup a socket listening on a specific port.
;;; When we want to stop the lisp process we simply
;;; telnet to that port as run by the stop section
;;; of the /etc/init.d/hunchentoot script.
;;; This thread will block execution until the
;;; connection comes in on the specified port,
(let ((socket (make-instance 'sb-bsd-sockets:inet-socket
                             :type :stream :protocol :tcp)))

  ;; Listen on a local port for a TCP connection
  (sb-bsd-sockets:socket-bind socket #(127 0 0 1) *shutdown-port*)
  (sb-bsd-sockets:socket-listen socket 1)

  ;; When it comes, close the sockets and continue
  (multiple-value-bind (client-socket addr port)
      (sb-bsd-sockets:socket-accept socket)
    (sb-bsd-sockets:socket-close client-socket)

    (sb-bsd-sockets:socket-close socket)))

;;; Here we go about closing all the running threads
;;; including the Swank Server we created.
(dolist (thread (sb-thread:list-all-threads))
  (unless (equal sb-thread:*current-thread* thread)
    (sb-thread:terminate-thread thread)))
(sleep 1)
(sb-ext:quit)
