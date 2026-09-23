;;; hhub-tst-att.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
;;;
;;; Verifies that an email ATTACHMENT survives the asynchronous email path :
;;;
;;;     send-email-async --> "Send Email Actor" mailbox --> send-generic-email-behavior --> hhubsendmail
;;;
;;; The property under test is the positional contract of hhubsendmail :
;;;
;;;     (hhubsendmail to subject body &optional from attachments-list)
;;;
;;; Attachments are the FIFTH argument and `from` is the FOURTH, so a caller that passes an
;;; attachment list fourth silently mails that list as the envelope sender. The recording stub
;;; below is copied lambda list for lambda list from hhub/core/dod-ui-utl.lisp, and test 0 diffs
;;; the copy against the source file, so the stub cannot drift away from production and leave a
;;; green suite behind.
;;;
;;; SMTP is never contacted : a recording stub stands in for hhubsendmail, so the suite is
;;; offline, deterministic and leaves no mail in anybody's inbox.
;;;
;;; TWO WAYS TO RUN IT, and the file works out which one it is in :
;;;
;;;   internal (the application image, e.g. SLIME) : the framework, the constants and
;;;     registration.lisp are already loaded, so the harness loads nothing and redefines nothing.
;;;     It only defines the suite, and prints the call to make. Loading does NOT run it, because
;;;     running it swaps hhubsendmail for the recording stub for the duration -- in a live image
;;;     that window would swallow any mail a request thread tried to send, so it is opt-in :
;;;
;;;         (run-hhub-attachment-harness)      ; or just (hhub-att) for short
;;;
;;;     The real hhubsendmail is saved and put back by UNWIND-PROTECT, so an error in the suite
;;;     cannot leave the live SMTP sender replaced.
;;;
;;;   standalone (a bare SBCL, no application) : the harness bootstraps :nstores, shims
;;;     bordeaux-threads / uuid / hhub-log-message, stubs the HTML packages, loads the three real
;;;     files and runs the suite on load :
;;;
;;;         sbcl --non-interactive --load hhub/test/hhub-tst-att.lisp
;;;
;;; Either way (run-hhub-attachment-harness) is safe to call repeatedly and returns T on success.

;; ── Bootstrap ────────────────────────────────────────────────────────────────
;; The one form that has to run before (in-package :nstores) : a bare SBCL has no :nstores, and
;; the actor model is compiled inside it. In the application image com.nstores.app already carries
;; the :nstores nickname, so this is a no-op there.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :nstores)
    (defpackage :nstores (:use :cl))))

(in-package :nstores)

(defun hhub-att-harness-dir ()
  "Repository hhub/ root : derived from this file's location, with an absolute fallback."
  (let ((lt (or *load-truename* *load-pathname*)))
    (if (and lt (search "/hhub/test/" (namestring lt)))
	(directory-namestring (merge-pathnames "../" (directory-namestring lt)))
	;; else the absolute fallback
	"/home/ubuntu/ninestores/hhub/")))

(defun att-test-dir ()
  "Scratch directory for the attachment files. Removed again at the end of a run."
  (merge-pathnames "test/tmp-att/" (hhub-att-harness-dir)))

;; Which of the two modes this is. Decided ONCE, at load time, before anything is loaded : if the
;; application is already in the image then everything below that exists only to stand in for the
;; application is skipped, and the suite is left for the caller to run deliberately.
(defparameter *att-internal-p* (fboundp 'hhub-read-file)
  "True when this file is being loaded into an image that already carries the application.
   Set at the top of the file, before the harness loads anything of its own.")

;; ── Reporting helper ─────────────────────────────────────────────────────────
;; SBCL's assert wants its second argument to be a LIST OF PLACES, so (assert test (expr) "why")
;; is a compile-time error and the assertion silently never runs. This reports any expression
;; instead, which is what these checks actually need.
(defmacro att-assert (test-form values-form &optional (string ""))
  `(let ((observed ,values-form))
     (unless ,test-form
       (error "~&ATTACHMENT CHECK FAILED: ~A~%  observed: ~S" ,string observed))))

;; ── Test doubles ─────────────────────────────────────────────────────────────
;; bordeaux-threads, uuid and hhub-log-message are stood in only when the running image does not
;; already provide them, exactly as hhub-tst-act.lisp does it.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *hhub-att-shims-bt-p* (null (find-package :bt)))
  (defparameter *hhub-att-shims-uuid-p* (null (find-package :uuid))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (when *hhub-att-shims-bt-p*
    (defpackage :bt (:use :cl)
		(:export #:make-lock #:with-lock-held #:make-condition-variable
			 #:condition-wait #:condition-notify #:make-thread
			 #:destroy-thread #:thread-alive-p)))
  (when *hhub-att-shims-uuid-p*
    (defpackage :uuid (:use :cl) (:export #:make-v1-uuid))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (when *hhub-att-shims-bt-p*
    (defun bt:make-lock (&optional name) (declare (ignore name)) (sb-thread:make-mutex))
    (defmacro bt:with-lock-held ((lock) &body body) `(sb-thread:with-mutex (,lock) ,@body))
    (defun bt:make-condition-variable (&optional name) (declare (ignore name))
      (sb-thread:make-waitqueue))
    (defun bt:condition-wait (condition-variable lock)
      (sb-thread:condition-wait condition-variable lock))
    (defun bt:condition-notify (condition-variable) (sb-thread:condition-notify condition-variable))
    (defun bt:make-thread (function &key name)
      (sb-thread:make-thread function :name (or name "actor")))
    (defun bt:destroy-thread (thread) (sb-thread:terminate-thread thread))
    (defun bt:thread-alive-p (thread) (and thread (sb-thread:thread-alive-p thread))))
  ;; Deliberately at the TOP LEVEL of this EVAL-WHEN, not inside the WHEN below. A DEFVAR nested
  ;; in a conditional is not a top-level form, so the compiler never proclaims it -- and when the
  ;; shim is NOT wanted (:uuid already exists, which is the case in the application image) the WHEN
  ;; is false at compile time and the DEFUN that follows warns "undefined variable". SBCL counts
  ;; that warning as failure-p, so the whole file reports a failed compile.
  (defvar *hhub-att-uuid-counter* 0
    "Counter behind the uuid shim. Kept in this package rather than reached for through the uuid
     package's own internals, which would leak a foreign variable into the real library's home.")
  (when *hhub-att-shims-uuid-p*
    (defun uuid:make-v1-uuid ()
      (format nil "00000000-0000-1000-8000-~12,'0D" (incf *hhub-att-uuid-counter*)))))

(unless (fboundp 'hhub-log-message)
  (defun hhub-log-message (str)
    (write-string (format nil "[att] ~A" str) *trace-output*)
    nil))

;; ── Stand-ins for the HTML side of registration.lisp ─────────────────────────
;; registration.lisp renders its templates through cl-who and enables the clsql reader syntax at
;; load time. None of that is exercised by this suite. In the application image the real packages
;; exist and every guard below is skipped; in a bare image they are stubbed.
;;
;; The cl-who stubs are MACROS THAT DISCARD THEIR BODY, not bare symbols. A bare symbol is not a
;; macro, so registration.lisp's HTML forms would compile as ordinary function calls -- which is
;; where "undefined function :TR", "undefined function :IMG" and "The function *STANDARD-OUTPUT*
;; is undefined, and its name is reserved by ANSI CL" came from. Discarding the body means the
;; template HTML is never compiled, which is correct: this suite tests the attachment path, not
;; the rendering.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :cl-who)
    (defpackage :cl-who (:use :cl) (:export #:with-html-output-to-string #:str)))
  (unless (find-package :clsql)
    (defpackage :clsql (:use :cl) (:export #:file-enable-sql-reader-syntax))))

;; The discarded-template marker lives in THIS package and never in cl-who's. A guard around a form
;; cannot protect the READ of it : writing cl-who::att-discarded-template makes the reader intern a
;; new name in the CL-WHO package the moment it reads the form, and CL-WHO is LOCKED in the
;; application image -- so the compile died with
;;
;;     Lock on package CL-WHO violated when interning ATT-DISCARDED-TEMPLATE while in package
;;     COM.NSTORES.APP
;;
;; before any guard could run. Reading only ever names existing cl-who symbols now.
(defun att-discarded-template ()
  "Reached only if something actually calls a template the harness threw away."
  (error "This template was discarded by the hhub-tst-att cl-who stand-in."))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (macro-function 'cl-who:with-html-output-to-string)
    ;; (var &rest options) rather than the real (var &optional stream &key prologue indent) : the
    ;; mixture of &OPTIONAL and &KEY in one lambda list earns a STYLE-WARNING, and the guard around
    ;; this DEFMACRO does NOT stop it being compiled -- a guard is a runtime test, the compiler
    ;; still compiles the body. Loose destructuring accepts the same call shape with no warning.
    (defmacro cl-who:with-html-output-to-string ((var &rest options) &body body)
      "Stand-in that throws the template away : see the note above."
      (declare (ignore var options body))
      '(att-discarded-template)))
  (unless (macro-function 'cl-who:str)
    (defmacro cl-who:str (value)
      (declare (ignore value))
      '(att-discarded-template)))
  (unless (macro-function 'clsql:file-enable-sql-reader-syntax)
    (defmacro clsql:file-enable-sql-reader-syntax () nil))
  ;; Only needed so the reader can read the real hhubsendmail out of dod-ui-utl.lisp in test 0.
  ;; Nothing here ever calls it : the recording stub is what actually "sends".
  (unless (find-package :cl-smtp)
    (defpackage :cl-smtp (:use :cl) (:export #:send-email))))

;; registration.lisp defines (defmethod send-test-email (customer) ...), which only needs the class
;; to exist. GUARDED, because in the application image CUSTOMER is a real persistable class and
;; redefining it as an empty one would destroy every slot on it.
(unless (find-class 'customer nil)
  (defclass customer () ()))

;; dod-ini-sys.lisp normally holds this, and must be special before registration.lisp is compiled
;; or send-email-async would not see the binding the tests make around each case. Guarded so the
;; live value in the application image is never touched.
(unless (boundp '*NSTGENERICEMAILACTOR*)
  (defvar *NSTGENERICEMAILACTOR* nil))

;; ── The real code under test ─────────────────────────────────────────────────
;; Each file is loaded ONLY when what it provides is missing, exactly as hhub-tst-act.lisp does it.
;; In the application image all three are already in the image, and re-loading nst-bl-act.lisp
;; would redefine the actor class underneath the live actors.
(unless (boundp '*HHUBSMTPSENDER*)                                          ; SMTP constants
  (load (merge-pathnames "core/extkeys.lisp" (hhub-att-harness-dir))))

(unless (fboundp 'send-message)                                             ; the actor framework
  (load (merge-pathnames "core/nst-bl-act.lisp" (hhub-att-harness-dir))))

(unless (fboundp 'send-email-async)                                         ; the path under test
  (load (merge-pathnames "email/templates/registration.lisp" (hhub-att-harness-dir))))

;; ── The recording stand-in for hhubsendmail ──────────────────────────────────
(defvar *att-lock* (bt:make-lock "att-record"))
(defvar *att-record* '()
  "Recorded calls, oldest first : plists with :to :subject :body :from :attachments.")
(defvar *att-fail-plan* (make-hash-table :test #'equal)
  "Subject -> number of remaining stub failures, so a send can be made to fail on demand.")

(defun att-recorded () (bt:with-lock-held (*att-lock*) (reverse *att-record*)))
(defun att-clear ()
  (bt:with-lock-held (*att-lock*) (setf *att-record* '()))
  (clrhash *att-fail-plan*))

(defun att-plan-failures (subject n)
  "Makes the stub fail the next N attempts at SUBJECT."
  (setf (gethash subject *att-fail-plan*) n))

(defun make-att-test-file (name content)
  "Writes CONTENT to a scratch file and returns its pathname."
  (let ((path (merge-pathnames name (att-test-dir))))
    (ensure-directories-exist path)
    (with-open-file (s path :direction :output :if-exists :supersede :if-does-not-exist :create)
      (write-string content s))
    path))

(defun att-clean-test-dir ()
  (let ((dir (att-test-dir)))
    (when (probe-file dir)
      (sb-ext:run-program "/bin/rm" (list "-rf" (namestring dir))
			  :input nil :output nil :error nil)
      nil)))

;; Copied lambda list for lambda list from hhub/core/dod-ui-utl.lisp:516. Test 0 keeps the copy
;; honest. The record is pushed BEFORE the failure is signalled, because a real SMTP send can also
;; have been accepted by the server and then fail on the read : that is what makes a retry duplicate
;; a mail, and test 5 pins that behaviour down instead of pretending it away.
;;
;; Deliberately NOT named hhubsendmail : in the application image that name belongs to the live SMTP
;; sender, and a plain DEFUN here would replace it for the rest of the session -- including if the
;; suite errored half way through. The suite swaps it in and puts the original back instead.
(defun att-recording-hhubsendmail (to subject body
				   &optional (from *HHUBSMTPSENDER*) attachments-list)
  (let ((remaining (gethash subject *att-fail-plan* 0)))
    (when (plusp remaining)
      (setf (gethash subject *att-fail-plan*) (1- remaining)))
    (bt:with-lock-held (*att-lock*)
      (push (list :to to :subject subject :body body :from from :attachments attachments-list)
	    *att-record*))
    (when (plusp remaining)
      (error "recording stub failure for ~S~%" subject))
    t))

(defun att-install-recorder ()
  "Swaps hhubsendmail for the recording stub. Returns the definition that was there, or NIL.
   NIL is the honest answer for the name being unbound, which is how the suite tells 'there was
   nothing to put back' from 'the original was the function NIL'."
  (let ((saved (and (fboundp 'hhubsendmail) (symbol-function 'hhubsendmail))))
    (setf (symbol-function 'hhubsendmail) #'att-recording-hhubsendmail)
    saved))

(defun att-restore-recorder (saved)
  (if saved
      (progn (setf (symbol-function 'hhubsendmail) saved) t)
      ;; else there was no hhubsendmail before this : leave none behind
      (progn (fmakunbound 'hhubsendmail) nil)))

(defmacro with-att-recorder (&body body)
  "Runs BODY with hhubsendmail recording instead of sending, and always restores it afterwards."
  `(let ((saved (att-install-recorder)))
     (unwind-protect (progn ,@body)
       (att-restore-recorder saved))))

;; ── The actor, wired the way nst-server-context.lisp wires it ────────────────
;; Same behaviour, statefulness, retry policy and mailbox bound as production, except for a short
;; retry delay so the suite does not sleep for seconds.
(defmacro with-email-actor ((var &rest initargs) &body body)
  `(let ((,var (make-instance 'nst-actor
			      :name "Send Email Actor Test"
			      :behavior #'send-generic-email-behavior
			      :stateful t
			      :state-clean-callback (function (lambda (actor) (declare (ignore actor)) nil))
			      :initial-state 0
			      :retry-limit 1
			      :retry-delay 0.05
			      :max-queue-size 200
			      ,@initargs)))
     (start-actor ,var)
     (unwind-protect
	  (let ((*NSTGENERICEMAILACTOR* ,var))
	    (att-assert (wait-until (lambda () (member (actor-thread-state ,var) '(:waiting :running))))
			(actor-thread-state ,var)
			"the email actor should reach waiting/running")
	    ,@body)
       (destroy-actor ,var))))

;; ── 0. the stub must still mirror the real hhubsendmail ──────────────────────
(defun att-source-lambda-list ()
  "Reads the real hhubsendmail lambda list out of hhub/core/dod-ui-utl.lisp.
   Reading starts at the defun and not at the top of the file on purpose : the other 1400 lines
   mention packages this harness has no reason to stub (cl-ppcre among them), and the reader would
   need every one of them to walk past them."
  (let ((src (merge-pathnames "core/dod-ui-utl.lisp" (hhub-att-harness-dir))))
    (with-open-file (s src)
      (let ((*read-eval* nil))
	(loop for line = (read-line s nil nil)
	      while line
	      when (search "(defun hhubsendmail " line)
		;; the rest of the form is read straight out of the file stream
		return (let ((*package* (find-package :nstores)))
			 (read (make-concatenated-stream
				(make-string-input-stream
				 (concatenate 'string line (string #\Newline)))
				s)
			       nil :eof)))))))

(defun test-att-stub-mirrors-source ()
  (format t "~&0. the recording stub mirrors the real hhubsendmail~%")
  (let ((form (att-source-lambda-list))
	(stub '(to subject body &optional (from *HHUBSMTPSENDER*) attachments-list)))
    (att-assert (consp form) form "hhubsendmail was not found in dod-ui-utl.lisp")
    (att-assert (eq (car form) 'defun) (car form))
    (att-assert (eq (cadr form) 'hhubsendmail) (cadr form))
    (let ((real (caddr form)))
      (att-assert (equal real stub) (list :source real :stub stub)
		  "the stub no longer mirrors the real hhubsendmail lambda list, so this suite could pass while production puts the attachment list in the FROM slot"))
    (format t "   source lambda list ~S matches the stub.~%" (caddr form))))

;; ── 1. regression : the five existing three-argument callers ─────────────────
(defun test-att-without-attachments ()
  (format t "~&1. a three-argument send still uses the default sender and no attachment~%")
  (att-clear)
  (with-email-actor (actor)
    (att-assert (eq t (send-email-async "cust@example.com" "Welcome to Nine Stores" "<p>hi</p>"))
		nil "send-email-async should report that the actor accepted the message")
    (att-assert (wait-until (lambda () (= (length (att-recorded)) 1))) (att-recorded)
		"the actor should have sent exactly one mail")
    (let ((m (first (att-recorded))))
      (att-assert (equal (getf m :to) "cust@example.com") m "the recipient should be unchanged")
      (att-assert (equal (getf m :subject) "Welcome to Nine Stores") m "the subject should be unchanged")
      (att-assert (equal (getf m :body) "<p>hi</p>") m "the body should be unchanged")
      (att-assert (equal (getf m :from) *HHUBSMTPSENDER*) m
		  "a three-argument send must take the default sender, not the attachment slot")
      (att-assert (null (getf m :attachments)) m
		  "a three-argument send must carry no attachment"))
    (att-assert (= (actor-messages-processed actor) 1) (actor-messages-processed actor))))

;; ── 2. the attachment reaches the sender ────────────────────────────────────
(defun test-att-reaches-sender ()
  (format t "~&2. an attachment reaches hhubsendmail through the actor~%")
  (att-clear)
  (let* ((path (make-att-test-file "invoice-1.pdf" "%PDF-1.4 first invoice"))
	 (atts (list path)))
    (with-email-actor (actor)
      (send-email-async "cust@example.com" "Your invoice" "<p>see attached</p>" atts)
      (att-assert (wait-until (lambda () (= (length (att-recorded)) 1))) (att-recorded)
		  "the actor should have sent exactly one mail")
      (let ((m (first (att-recorded))))
	(att-assert (eq (getf m :attachments) atts) (getf m :attachments)
		    "the attachment list must arrive untouched : no copy, no coercion, no truncation")
	(att-assert (equal (getf m :from) *HHUBSMTPSENDER*) (getf m :from)
		    "the sender must still be the sender when an attachment is present")
	(att-assert (equal (getf m :subject) "Your invoice") m)
	(att-assert (probe-file path) path
		    "the attachment is read at send time, so it must still exist afterwards"))
      (att-assert (= (actor-messages-processed actor) 1) (actor-messages-processed actor))
      (att-assert (= (length (actor-dead-letters actor)) 0) (actor-dead-letters actor)))))

;; ── 3. FIFO, and no cross-talk between queued attachments ───────────────────
(defun test-att-per-message-and-fifo ()
  (format t "~&3. queued invoices keep their order and their own attachment~%")
  (att-clear)
  (let* ((paths (loop for i from 1 to 3
		      collect (make-att-test-file (format nil "inv-~A.pdf" i)
						  (format nil "body ~A" i)))))
    (with-email-actor (actor)
      (loop for p in paths for n from 1
	    do (send-email-async (format nil "cust~A@example.com" n)
				 (format nil "Invoice ~A" n)
				 (format nil "<p>~A</p>" n)
				 (list p)))
      (att-assert (wait-until (lambda () (= (length (att-recorded)) 3))) (att-recorded)
		  "all three mails should have been sent")
      (let ((ms (att-recorded)))
	(att-assert (equal (mapcar (lambda (m) (getf m :subject)) ms)
			   '("Invoice 1" "Invoice 2" "Invoice 3"))
		    (mapcar (lambda (m) (getf m :subject)) ms)
		    "messages must stay FIFO")
	(loop for m in ms for p in paths for n from 1
	      do (att-assert (equal (getf m :to) (format nil "cust~A@example.com" n)) m)
		 (att-assert (equal (getf m :attachments) (list p)) (getf m :attachments)
			     "each mail must carry its own attachment, never a neighbour's")))
      (att-assert (= (actor-messages-processed actor) 3) (actor-messages-processed actor)))))

;; ── 4. the inline fallback when the actor is not up ─────────────────────────
(defun test-att-inline-fallback ()
  (format t "~&4. with no actor the mail is sent inline, attachment and sender intact~%")
  (att-clear)
  (let* ((path (make-att-test-file "fallback.pdf" "fallback body"))
	 (atts (list path))
	 (*NSTGENERICEMAILACTOR* nil))
    (att-assert (eq t (send-email-async "cust@example.com" "Inline" "<p>x</p>" atts)) nil
		"the inline fallback should return T rather than lose the mail")
    (att-assert (= (length (att-recorded)) 1) (att-recorded)
		"the inline fallback should have sent the mail at once")
    (let ((m (first (att-recorded))))
      (att-assert (eq (getf m :attachments) atts) (getf m :attachments)
		  "the inline fallback must pass the attachment in the fifth slot")
      (att-assert (equal (getf m :from) *HHUBSMTPSENDER*) (getf m :from)
		  "this is the trap : (hhubsendmail to subject body atts) would put the attachment list in the FROM slot, so the sender has to be passed explicitly"))))

;; ── 5. a retried send : the attachment survives, and the mail is duplicated ──
(defun test-att-retry-keeps-attachment ()
  (format t "~&5. a retried send presents the same attachment (and duplicates the mail)~%")
  (att-clear)
  (let* ((path (make-att-test-file "retry.pdf" "retry body"))
	 (atts (list path))
	 (subject "Retried invoice"))
    (att-plan-failures subject 1)                 ;; the first attempt fails after the server "saw" it
    (with-email-actor (actor)
      (send-email-async "cust@example.com" subject "<p>retry</p>" atts)
      (att-assert (wait-until (lambda () (= (actor-messages-processed actor) 1)) :timeout 5)
		  (actor-messages-processed actor) "the retry should have succeeded")
      (att-assert (= (actor-messages-retried actor) 1) (actor-messages-retried actor)
		  "the failed attempt should be counted as one retry")
      (att-assert (= (actor-messages-failed actor) 0) (actor-messages-failed actor)
		  "a send that succeeded on the retry is not a failure")
      (att-assert (= (length (actor-dead-letters actor)) 0) (actor-dead-letters actor)))
    (let ((ms (att-recorded)))
      (att-assert (= (length ms) 2) (length ms)
		  "a retried send attempts the mail twice : the duplicate-mail hazard the actor KB warns about, unchanged by the attachment")
      (att-assert (every (lambda (m) (eq (getf m :attachments) atts)) ms)
		  (mapcar (lambda (m) (getf m :attachments)) ms)
		  "the retry must present the same attachment object")
      (att-assert (every (lambda (m) (equal (getf m :from) *HHUBSMTPSENDER*)) ms)
		  (mapcar (lambda (m) (getf m :from)) ms)
		  "every attempt must use the real sender"))))

;; ── 6. a dead letter still carries the attachment ───────────────────────────
(defun test-att-dead-letter-keeps-attachment ()
  (format t "~&6. a dead letter keeps the attachment so the send can be replayed~%")
  (att-clear)
  (let* ((path (make-att-test-file "dead.pdf" "dead body"))
	 (atts (list path))
	 (subject "Undeliverable invoice"))
    (att-plan-failures subject 10)                ;; never succeeds
    (with-email-actor (actor)
      (send-email-async "cust@example.com" subject "<p>dead</p>" atts)
      (att-assert (wait-until (lambda () (= (length (actor-dead-letters actor)) 1)) :timeout 5)
		  (actor-dead-letters actor) "the mail should be dead lettered after the retries")
      (att-assert (= (actor-messages-failed actor) 1) (actor-messages-failed actor))
      (att-assert (= (actor-messages-retried actor) 1) (actor-messages-retried actor))
      (let* ((dl (first (actor-dead-letters actor)))
	     (payload (getf dl :message)))
	(att-assert (stringp (getf dl :error)) dl "the dead letter must keep the real error string")
	(att-assert (plusp (getf dl :at)) dl)
	;; The payload is the thunk, so replaying it recovers the whole mail including the file.
	(multiple-value-bind (to subj body atts*) (funcall payload)
	  (declare (ignorable body))
	  (att-assert (equal to "cust@example.com") to)
	  (att-assert (equal subj subject) subj)
	  (att-assert (eq atts* atts) atts*
		      "the dead letter must still yield the attachment, or an outage would silently drop the invoice PDF"))))))

;; ── Suite driver ────────────────────────────────────────────────────────────
(defun run-attachment-tests ()
  (test-att-stub-mirrors-source)
  (test-att-without-attachments)
  (test-att-reaches-sender)
  (test-att-per-message-and-fifo)
  (test-att-inline-fallback)
  (test-att-retry-keeps-attachment)
  (test-att-dead-letter-keeps-attachment)
  (att-clean-test-dir)
  (format t "~&All attachment checks passed.~%"))

(defvar *att-harness-failures* 0
  "Number of suites that failed in the last run of this harness.")

(defun run-hhub-attachment-harness ()
  "Runs the attachment suite and reports. Returns T when everything passed.
   Safe to call repeatedly, and safe in a live image : hhubsendmail is put back by UNWIND-PROTECT."
  (format t "~&==== Email attachment harness (send-email-async -> actor -> hhubsendmail) ====~%")
  (setf *att-harness-failures* 0)
  (handler-case
      (with-att-recorder
	(att-assert (eq (symbol-function 'hhubsendmail) #'att-recording-hhubsendmail)
		    (symbol-function 'hhubsendmail)
		    "the recording stub should be installed for the duration of the suite")
	(run-attachment-tests)
	(format t "~&==== Email attachment harness: PASS ====~%")
	t)
    (error (e)
      (incf *att-harness-failures*)
      (ignore-errors (att-clean-test-dir))
      (format t "~&==== Email attachment harness: FAIL ====~%~A~%" e)
      nil)))

(defun hhub-att ()
  "Short alias for (run-hhub-attachment-harness), for the SLIME REPL."
  (run-hhub-attachment-harness))

(eval-when (:load-toplevel :execute)
  (if *att-internal-p*
      ;; In the application image, running the suite swaps the live SMTP sender out for the
      ;; duration, so it is the caller's decision and NOT a side effect of loading this file.
      (format t "~&hhub-tst-att loaded into an image that already has the application.~%  ~
                 Nothing was loaded or redefined. Run ~S to check the attachment path.~%"
	      '(run-hhub-attachment-harness))
      ;; else standalone : load-and-run is the whole point of the file, exactly as hhub-tst-act.lisp
      (progn
	(run-hhub-attachment-harness)
	(when (and (plusp *att-harness-failures*)
		   (not (interactive-stream-p *standard-input*)))
	  (sb-ext:exit :code 1)))))
