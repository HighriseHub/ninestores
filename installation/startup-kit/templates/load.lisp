;;; load.lisp — Quicklisp dependency load + system start. Rendered by
;;; installation/startup-kit/05-install-hunchentoot-service.sh into
;;; @REPO@/startup/load.lisp and loaded by init.lisp inside the image.
;;;
;;; This file is also useful on its own: loading it into a bare SBCL gives you a
;;; running application without detachtty (as the dev user, for a debug session).
;;;
;;; NOTE the two distinct steps:
;;;   * ql:quickload pulls and compiles the EXTERNAL libraries (this is the slow
;;;     part on a cold machine: it compiles everything from source);
;;;   * ql:quickload :nstores compiles/loads hhub/ itself, and (start-das) starts
;;;     the acceptor, the actors and the template caches.
;;; `start-das' is a Lisp call, never a shell command.

;; the checkout's own system definition lives here
(push "@REPO@/hhub/" asdf:*central-registry*)

(in-package :cl-user)

;; external dependencies. cl-async needs libuv (libuv1-dev); clsql-mysql needs
;; the MySQL client library (libmysqlclient-dev) — both come from 02.
(ql:quickload '(:uuid :secure-random :drakma :cl-json :cl-who :hunchentoot
                :clsql :clsql-mysql :cl-smtp :parenscript :cl-async :cl-csv
                :cl-base64 :priority-queue :blackbird :cl-yaml))

;; the platform itself
(ql:quickload :nstores)

(in-package :nstores)

;; start the acceptor, the business server and the background actors
(start-das)

;;; Reaching this line means the image is serving. If it is NOT here when you
;;; look, the error above it is the whole story — that is what
;;; ~@APP_USER@/log/hunchentoot.dribble exists for.
(format t "~&HHUB platform started at ~A~%" (mysql-now))
