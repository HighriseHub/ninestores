;;; hhub-tst-act.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
;;;
;;; Verification harness for the actor model in core/nst-bl-act.lisp.
;;;
;;; House style: like the other hhub-tst-*.lisp files this runs in the :nstores package.
;;; Inside a loaded nstores image nothing is redefined : bordeaux-threads, uuid and
;;; hhub-log-message are the real ones, and the framework is already loaded. From a bare
;;; SBCL the bootstrap below stands those three in with SBCL primitives and loads the
;;; framework, so the file is self-verifiable :
;;;
;;;     sbcl --non-interactive --load hhub/test/hhub-tst-act.lisp
;;;
;;; The suite itself (test-counter-actor / run-actor-tests) lives with the framework, so
;;; that the actor model is tested in the same file that implements it. Loading this file
;;; runs the suite once, prints a pass/fail summary and exits 1 on failure when stdin is
;;; not interactive. Call (run-hhub-actor-harness) to run it again without reloading.

;; ── Bootstrap ────────────────────────────────────────────────────────────────
;; The one form that has to run before (in-package :nstores) : a bare SBCL has no :nstores,
;; and the actor model is compiled inside it.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :nstores)
    (defpackage :nstores (:use :cl))))

(in-package :nstores)

(defun hhub-actor-harness-dir ()
  "Repository hhub/ root : derived from this file's location when it is loaded from the
   checkout, with an absolute fallback for ad-hoc runs."
  (let ((lt (or *load-truename* *load-pathname*)))
    (if (and lt (search "/hhub/test/" (namestring lt)))
	(directory-namestring (merge-pathnames "../" (directory-namestring lt)))
	;; else the absolute fallback
	"/home/ubuntu/ninestores/hhub/")))

;; ── Test doubles ─────────────────────────────────────────────────────────────
;; bordeaux-threads, uuid and hhub-log-message are only stood in when the running image does
;; not already provide them, so this harness can also be loaded inside the application.
;; Each shim is a thin layer over SBCL, so the suite still runs against real OS threads,
;; real mutexes and real condition variables.
;;
;; The flags are recomputed on every load and the definitions below are wrapped in them, so
;; a compiled harness loaded into an image that has the real libraries redefines nothing.
;; Creating the packages happens in forms of their own : the reader needs :bt to exist before
;; it can read the bt: symbols that follow.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *hhub-actor-harness-shims-bt-p* (null (find-package :bt))
    "True when this image has no bordeaux-threads and the harness has to shim it.")
  (defparameter *hhub-actor-harness-shims-uuid-p* (null (find-package :uuid))
    "True when this image has no uuid library and the harness has to shim it."))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (when *hhub-actor-harness-shims-bt-p*
    (defpackage :bt (:use :cl)
		(:export #:make-lock #:with-lock-held #:make-condition-variable
			 #:condition-wait #:condition-notify #:make-thread
			 #:destroy-thread #:thread-alive-p)))
  (when *hhub-actor-harness-shims-uuid-p*
    (defpackage :uuid (:use :cl) (:export #:make-v1-uuid))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (when *hhub-actor-harness-shims-bt-p*
    (defun bt:make-lock (&optional name) (declare (ignore name)) (sb-thread:make-mutex))
    (defmacro bt:with-lock-held ((lock) &body body) `(sb-thread:with-mutex (,lock) ,@body))
    (defun bt:make-condition-variable (&optional name) (declare (ignore name))
      (sb-thread:make-waitqueue))
    (defun bt:condition-wait (condition-variable lock)
      (sb-thread:condition-wait condition-variable lock))
    (defun bt:condition-notify (condition-variable)
      (sb-thread:condition-notify condition-variable))
    (defun bt:make-thread (function &key name)
      (sb-thread:make-thread function :name (or name "actor")))
    (defun bt:destroy-thread (thread) (sb-thread:terminate-thread thread))
    (defun bt:thread-alive-p (thread) (and thread (sb-thread:thread-alive-p thread))))
  (when *hhub-actor-harness-shims-uuid-p*
    (defvar uuid::*harness-uuid-counter* 0)
    (defun uuid:make-v1-uuid ()
      (format nil "00000000-0000-1000-8000-~12,'0D" (incf uuid::*harness-uuid-counter*)))))


(defun hhub-actor-harness-dir ()
  "Repository hhub/ root : derived from this file's location when loaded from the checkout,
   with an absolute fallback for ad-hoc runs."
  (let ((lt (or *load-truename* *load-pathname*)))
    (if (and lt (search "/hhub/test/" (namestring lt)))
	(directory-namestring (merge-pathnames "../" (directory-namestring lt)))
	;; else the absolute fallback
	"/home/ubuntu/ninestores/hhub/")))

;; The framework logs retries, dead letters and supervisor restarts through this. The real
;; one appends to the business functions log file and is left alone when the app is loaded.
(unless (fboundp 'hhub-log-message)
  (defun hhub-log-message (str)
    (write-string (format nil "[actor] ~A" str) *trace-output*)
    nil))

;; Load the actor model when this harness runs on its own. Inside the app image the suite is
;; already there, and reloading the file would redefine the actor class under live actors.
(unless (fboundp 'test-counter-actor)
  (load (merge-pathnames "core/nst-bl-act.lisp" (hhub-actor-harness-dir))))

(defvar *actor-harness-failures* 0
  "Number of suites that failed in the last run of the harness.")

(defun run-hhub-actor-harness ()
  "Runs the actor model suite and reports. Returns T when everything passed."
  (format t "~&==== Actor model harness (core/nst-bl-act.lisp) ====~%")
  (setf *actor-harness-failures* 0)
  (handler-case
      (progn
	(run-actor-tests)
	(format t "~&==== Actor model harness: PASS ====~%")
	t)
    (error (e)
      (incf *actor-harness-failures*)
      (format t "~&==== Actor model harness: FAIL ====~%~A~%" e)
      nil)))

;; Loading this file runs the suite once. From the REPL you can then call
;; (run-hhub-actor-harness) to re-run without reloading.
;; The sb-ext:exit below only fires when stdin is non-interactive (script/CI), so a failed
;; suite never kills a REPL session.
(eval-when (:load-toplevel :execute)
  (run-hhub-actor-harness)
  (when (and (plusp *actor-harness-failures*)
	     (not (interactive-stream-p *standard-input*)))
    (sb-ext:exit :code 1)))
