;;; nst-bl-act.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.


;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ======================================================================
;;; NINE STORES ACTOR MODEL
;;;
;;; One OS thread per actor, a FIFO mailbox and a behaviour. The rules the
;;; implementation keeps, and that the tests at the bottom of this file check:
;;;
;;;   * a producer never waits for a behaviour. send-message enqueues and
;;;     returns; the behaviour runs outside the actor lock.
;;;   * messages are processed in the order they were sent (FIFO).
;;;   * a failing behaviour is contained : it is retried per the actor's retry
;;;     policy, then dead lettered. It never kills the actor thread.
;;;   * the mailbox is bounded, so one slow downstream cannot grow it forever.
;;;   * a caller that needs an answer asks with send-message-and-wait, and the
;;;     behaviour answers with actor-reply.
;;;   * a supervisor notices an actor whose thread died and revives it, keeping
;;;     the actor object (and therefore every caller's reference) valid.
;;;   * shutdown is cooperative : the message in flight is allowed to finish.
;;; ======================================================================

(defvar *nst-actor-registry* (make-hash-table :test 'equal)
  "Registered actors by name. The supervisor health checks exactly these.")

(defvar *nst-actor-supervisor-interval* 5
  "Seconds between supervisor health checks.")

(defvar *nst-actor-supervisor-thread* nil
  "Thread running supervise-actors, started by start-actor-supervisor.")

(defvar *nst-actor-supervisor-stop* nil
  "Set to T to ask the supervisor thread to end its loop.")

(defvar *nst-actor-shutdown-grace* 5
  "Seconds destroy-actor waits for the message in flight before killing the thread.")

(defvar *actor-reply* nil
  "The reply envelope of the message being processed, bound around a behaviour so that a
   behaviour which was asked a question can answer it with (actor-reply value).")

;;; ----------------------------------------------------------------------
;;; Messages and replies
;;; ----------------------------------------------------------------------

(defstruct actor-message
  "A typed message. PAYLOAD is what the behaviour receives, which may be anything the
   behaviour understands (a thunk, a keyword, a plist, a domain object). REPLY, when present,
   is the envelope the asking caller is waiting on."
  (payload nil)
  (reply nil))

(defstruct actor-reply
  "Envelope carrying an answer back to a caller blocked in send-message-and-wait."
  (lock (bt:make-lock))
  (condition (bt:make-condition-variable))
  (ready-p nil)
  (values nil)
  (error nil))

(defun reply-with-values (reply values error)
  "Delivers VALUES and ERROR to whoever is waiting on REPLY."
  (when reply
    (bt:with-lock-held ((actor-reply-lock reply))
      (setf (actor-reply-values reply) values
	    (actor-reply-error reply) error
	    (actor-reply-ready-p reply) t)
      (bt:condition-notify (actor-reply-condition reply))))
  values)

(defun actor-reply (value &optional error)
  "Answers the caller waiting on the message being processed, if there is one, and returns
   VALUE. A behaviour that was asked a question must call this, otherwise the caller times out."
  (reply-with-values *actor-reply* (list value) error)
  value)

;;; ----------------------------------------------------------------------
;;; The actor
;;; ----------------------------------------------------------------------

(defclass nst-actor ()
  ((id :reader id
       :initform (format nil "~A" (uuid:make-v1-uuid)))
   (name
    :initarg :name
    :reader actor-name
    :initform "unnamed-actor")
   (behavior
    :initarg :behavior
    :reader actor-behavior
    :initform nil)
   (state
    :initarg :initial-state
    :accessor actor-state
    :initform nil)
   (actor-state-clean-callback
    :initarg :state-clean-callback
    :accessor actor-state-clean-callback
    :initform nil)
   (stateful
    :initarg :stateful
    :reader actor-stateful
    :initform nil)
   ;; mailbox : QUEUE is the oldest cons, QUEUE-TAIL the newest, so enqueue is O(1)
   (queue
    :initform '()
    :accessor actor-queue)
   (queue-tail
    :initform nil
    :accessor actor-queue-tail)
   (lock
    :initform (bt:make-lock)
    :reader actor-lock)
   (condition
    :initform (bt:make-condition-variable)
    :reader actor-condition)
   (thread-state
    :initform :created 
    :accessor actor-thread-state)
   (thread
    :initform nil
    :accessor actor-thread)
   (role
    :initarg :role
    :reader actor-role
    :initform nil)
   (created-at
    :initform (get-universal-time)
    :reader actor-created-at)
   (last-active-at
    :initform (get-universal-time)
    :accessor actor-last-active-at)
   (priority
    :initarg :priority
    :accessor actor-priority
    :initform :normal)
   (message-count
    :initform 0
    :accessor actor-message-count)
   (messages-processed
    :initform 0
    :accessor actor-messages-processed)
   (messages-failed
    :initform 0
    :accessor actor-messages-failed)
   (messages-retried
    :initform 0
    :accessor actor-messages-retried)
   (messages-dropped
    :initform 0
    :accessor actor-messages-dropped)
   (dead-letters
    :initform '()
    :accessor actor-dead-letters)
   (restart-count
    :initform 0
    :accessor actor-restart-count)
   (retry-limit
    :initarg :retry-limit
    :accessor actor-retry-limit
    :initform 0)
   (retry-delay
    :initarg :retry-delay
    :accessor actor-retry-delay
    :initform 1)
   (max-queue-size
    :initarg :max-queue-size
    :initform 100
    :accessor actor-max-queue-size))
  (:documentation "Class representing an actor with message queue and behavior."))

(defgeneric send-message (actor message &optional bulk-processing-mode-p))
(defgeneric process-messages (actor))
(defgeneric get-state (actor))
(defgeneric stop-actor (actor))
(defgeneric start-actor (actor))
(defgeneric destroy-actor (actor))


(defmethod initialize-instance :after ((self nst-actor) &key)
  "Start the actor thread after initialization."
  (with-slots (thread-state thread name) self 
    (setf thread (bt:make-thread
		  (lambda () (process-messages self))
                  :name name))
    (setf thread-state :created)))

;;; ----------------------------------------------------------------------
;;; Mailbox
;;; ----------------------------------------------------------------------

(defun %enqueue-message (actor message)
  "Adds MESSAGE at the tail of the mailbox. Caller holds the actor lock."
  (if (actor-queue actor)
      (setf (cdr (actor-queue-tail actor)) (list message)
	    (actor-queue-tail actor) (cdr (actor-queue-tail actor)))
      ;;else the mailbox was empty
      (setf (actor-queue actor) (list message)
	    (actor-queue-tail actor) (actor-queue actor)))
  message)

(defun %dequeue-message (actor)
  "Removes and returns the oldest message. Caller holds the actor lock."
  (let ((message (car (actor-queue actor))))
    (setf (actor-queue actor) (cdr (actor-queue actor)))
    (unless (actor-queue actor)
      (setf (actor-queue-tail actor) nil))
    message))

(defun actor-queue-depth (actor)
  "Number of messages waiting in the mailbox."
  (length (actor-queue actor)))

;;; ----------------------------------------------------------------------
;;; Process Messages
;;; ----------------------------------------------------------------------

(defmethod process-messages ((self nst-actor))
  "Processes messages continuously, waiting if the queue is empty. The message is taken under
the actor lock and the behaviour is then run outside it : a slow behaviour must never stop
other threads from sending. A failing behaviour is retried per the actor's retry policy and
then dead lettered, so it can never take the actor thread down."
  (with-slots (state lock last-active-at stateful  thread-state condition queue behavior name
	       retry-limit retry-delay messages-processed messages-failed messages-retried
	       dead-letters) self
    (loop
      (let ((message nil))
	;; --- take the next message, waiting while there is nothing to do ---
	(bt:with-lock-held (lock)
	  (loop
	    (cond
	      ((eq thread-state :terminated)
	       (return-from process-messages nil))  ;; Stop processing and exit when terminated
	      ((eq thread-state :stopped) ;; if Actor is stopped, then just wait
	       (bt:condition-wait condition lock))
	      ((null queue)  ;; Wait if queue is empty
	       (setf thread-state :waiting)
	       (bt:condition-wait condition lock))
	      ((eq thread-state :running)  ;; take the oldest message and leave the lock
	       (setf message (%dequeue-message self))
	       (return))
	      (t (bt:condition-wait condition lock)))))
	;; --- run the behaviour with no lock held ---
	(let ((payload (if (actor-message-p message) (actor-message-payload message) message))
	      (reply (if (actor-message-p message) (actor-message-reply message) nil)))
	  (setf last-active-at (get-universal-time))
	  (loop for attempt from 1
		for handled = nil
		do (handler-case
		       (progn
			 (let ((*actor-reply* reply))
			   (if stateful
			       (setf state (funcall behavior state payload))
			       ;; else
			       (funcall behavior payload)))
			 (incf messages-processed)
			 (setf handled t))
		     (error (e)
		       (if (< attempt (1+ retry-limit))
			   (progn
			     (incf messages-retried)
			     (hhub-log-message (format nil "actor ~A : attempt ~D on ~A failed (~A), retrying in ~As~%"
						       name attempt (type-of payload) e retry-delay))
			     (when (and retry-delay (> retry-delay 0))
			       (sleep retry-delay)))
			   ;; else the message fails for good : keep it for inspection and answer the asker
			   (progn
			     (incf messages-failed)
			     (push (list :message payload :error (format nil "~A" e) :at (get-universal-time))
				   dead-letters)
			     (hhub-log-message (format nil "actor ~A : giving up on ~A (~A), dead lettered~%"
						       name (type-of payload) e))
			     (reply-with-values reply nil e)
			     (setf handled t)))))
		until handled))))))

;;; ----------------------------------------------------------------------
;;; Start, Stop, Destroy, Restart
;;; ----------------------------------------------------------------------

(defmethod get-state ((actor nst-actor))
  "The actor's current state, which is whatever its behavior returned last."
  (actor-state actor))

(defmethod start-actor ((actor nst-actor))
  "Starts the actor if it is not already running."
  (with-slots (lock thread-state condition) actor
    (bt:with-lock-held (lock)
      (unless (eq thread-state :terminated)
	(setf thread-state :running)))
    (bt:condition-notify condition)))  ;; Wake up thread if waiting

(defmethod stop-actor ((actor nst-actor))
  "Stops the actor without destroying the thread. Messages sent afterwards are queued, and a
plain send-message wakes it again : use flush-actor to process a batch deliberately."
  (with-slots (thread-state condition lock) actor
  (bt:with-lock-held (lock)
    (unless (eq thread-state :terminated)
      (setf thread-state :stopped)))
    (bt:condition-notify condition)))  ;; Wake up thread to stop

(defmethod destroy-actor ((actor nst-actor))
  "Stops the actor, lets the message in flight finish, then releases it. The grace period
matters : killing the thread outright can interrupt a behaviour half way through a database or
S3 write."
  (let ((thread (actor-thread actor))
	(name (actor-name actor)))
    (bt:with-lock-held ((actor-lock actor))
      (setf (actor-thread-state actor) :terminated)
      (when (functionp (actor-state-clean-callback actor))
	(handler-case (funcall (actor-state-clean-callback actor) actor)
	  (error () (funcall (actor-state-clean-callback actor)))))
      (setf (actor-state-clean-callback actor) nil))
    (bt:condition-notify (actor-condition actor))
    (loop repeat (round (* *nst-actor-shutdown-grace* 50))
	  until (not (and thread (bt:thread-alive-p thread)))
	  do (sleep 0.02))
    (when (and thread (bt:thread-alive-p thread))
      (hhub-log-message (format nil "actor ~A did not stop within ~As, terminating its thread~%"
				name *nst-actor-shutdown-grace*))
      (bt:destroy-thread thread))
    (unregister-actor actor)
    (bt:with-lock-held ((actor-lock actor))
      (setf (actor-thread actor) nil
	    (actor-queue actor) '()
	    (actor-queue-tail actor) nil
	    (actor-state actor) nil))))

(defun actor-alive-p (actor)
  "True when ACTOR's thread exists and is alive."
  (let ((thread (actor-thread actor)))
    (and thread (bt:thread-alive-p thread))))

(defun restart-actor (actor &key (reason "thread not alive"))
  "Replaces a dead actor thread with a fresh one. The actor object itself is kept, so every
global and closure that already refers to this actor keeps working, and any message left in the
mailbox is processed by the new thread."
  (unless (eq (actor-thread-state actor) :terminated)
    (incf (actor-restart-count actor))
    (hhub-log-message (format nil "actor supervisor : restarting ~A (~A)~%" (actor-name actor) reason))
    (setf (actor-thread actor) (bt:make-thread (lambda () (process-messages actor))
					      :name (actor-name actor)))
    (setf (actor-thread-state actor) :running)
    (bt:condition-notify (actor-condition actor)))
  actor)

(defun flush-actor (actor)
  "Wakes ACTOR so that everything queued with bulk-processing-mode-p is processed now."
  (with-slots (lock thread-state condition) actor
    (bt:with-lock-held (lock)
      (unless (eq thread-state :terminated)
	(setf thread-state :running)))
    (bt:condition-notify condition))
  actor)

;;; ----------------------------------------------------------------------
;;; Send Message
;;; ----------------------------------------------------------------------

(defmethod send-message ((actor nst-actor) message &optional (bulk-processing-mode-p nil))
  "Sends a message to the actor's queue and notifies it. Returns T when the message was
accepted and NIL when the mailbox was full, in which case the message is dropped and counted.
MESSAGE is either a function (the behaviour's input, or a question for the behaviour to answer)
or an actor-message carrying a payload and a reply envelope.

BULK-PROCESSING-MODE-P queues the message without waking the actor : call flush-actor to
process such a batch."
  (with-slots (lock thread-state condition queue message-count messages-dropped max-queue-size name) actor
    (let ((accepted nil))
      (bt:with-lock-held (lock)
	(unless (eq thread-state :terminated)
	  (if (or (null max-queue-size) (< (length queue) max-queue-size))
	      (progn
		(%enqueue-message actor message)
		(incf message-count)
		(unless bulk-processing-mode-p
		  (setf thread-state :running))
		(setf accepted t))
	      ;; else the mailbox is full : refuse rather than grow without bound
	      (incf messages-dropped))))
      (unless accepted
	(hhub-log-message (format nil "actor ~A : mailbox full (~A messages), message dropped~%"
				  name (or max-queue-size "unbounded"))))
      (when accepted
	(bt:condition-notify condition))
      accepted)))

(defun send-message-and-wait (actor message &key (timeout 30))
  "Asks ACTOR a question and waits for the answer. MESSAGE is what the behaviour receives, and
the behaviour has to answer it with (actor-reply value). Returns three values : the answer, T
when an answer arrived, and the error (or :timeout, or :mailbox-full) otherwise.

Note that bordeaux-threads has no timed condition wait, so this polls the envelope."
  (let* ((reply (make-actor-reply))
	 (asked (send-message actor (make-actor-message :payload message :reply reply))))
    (if (null asked)
	(values nil nil :mailbox-full)
	(loop with deadline = (+ (get-internal-real-time) (* timeout internal-time-units-per-second))
	      until (actor-reply-ready-p reply)
	      until (> (get-internal-real-time) deadline)
	      do (sleep 0.01)
	      finally (if (actor-reply-ready-p reply)
			  (let ((answer-error (actor-reply-error reply)))
			    (return (values (first (actor-reply-values reply))
					    (null answer-error)
					    answer-error)))
			  (return (values nil nil :timeout)))))))

;;; ----------------------------------------------------------------------
;;; Supervision and status
;;; ----------------------------------------------------------------------

(defun register-actor (actor)
  "Puts ACTOR under the supervisor's care."
  (setf (gethash (actor-name actor) *nst-actor-registry*) actor)
  actor)

(defun unregister-actor (actor)
  "Removes ACTOR from the supervisor's care."
  (remhash (actor-name actor) *nst-actor-registry*)
  actor)

(defun supervise-actors ()
  "Health check : revives any registered actor whose thread has died unexpectedly."
  (let ((revived '()))
    (maphash (lambda (name actor)
	       (declare (ignore name))
	       (unless (or (eq (actor-thread-state actor) :terminated) (actor-alive-p actor))
		 (restart-actor actor :reason "thread not alive")
		 (push (actor-name actor) revived)))
	     *nst-actor-registry*)
    revived))

(defun start-actor-supervisor (&key (interval *nst-actor-supervisor-interval*))
  "Starts the thread that keeps registered actors alive. Returns the supervisor thread."
  (unless (and *nst-actor-supervisor-thread* (bt:thread-alive-p *nst-actor-supervisor-thread*))
    (setf *nst-actor-supervisor-stop* nil)
    (setf *nst-actor-supervisor-thread*
	  (bt:make-thread
	   (lambda ()
	     (loop until *nst-actor-supervisor-stop*
		   do (sleep interval)
		      (unless *nst-actor-supervisor-stop*
			(handler-case (supervise-actors)
			  (error (e) (hhub-log-message (format nil "actor supervisor raised ~A~%" e)))))))
	   :name "Actor Supervisor")))
  *nst-actor-supervisor-thread*)

(defun stop-actor-supervisor ()
  "Stops the supervisor thread."
  (setf *nst-actor-supervisor-stop* t)
  (when (and *nst-actor-supervisor-thread* (bt:thread-alive-p *nst-actor-supervisor-thread*))
    (bt:destroy-thread *nst-actor-supervisor-thread*))
  (setf *nst-actor-supervisor-thread* nil))

(defun actor-status (actor)
  "An alist describing ACTOR : mailbox depth, counters and health."
  (list (cons :name (actor-name actor))
	(cons :id (id actor))
	(cons :thread-state (actor-thread-state actor))
	(cons :alive (actor-alive-p actor))
	(cons :queue-depth (actor-queue-depth actor))
	(cons :sent (actor-message-count actor))
	(cons :processed (actor-messages-processed actor))
	(cons :failed (actor-messages-failed actor))
	(cons :retried (actor-messages-retried actor))
	(cons :dropped (actor-messages-dropped actor))
	(cons :dead-letters (length (actor-dead-letters actor)))
	(cons :restarts (actor-restart-count actor))
	(cons :last-active-at (actor-last-active-at actor))))

(defun actors-status-report ()
  "A text report of every registered actor, for the log or a status page."
  (with-output-to-string (s)
    (format s "~&~D registered actor(s)~%" (hash-table-count *nst-actor-registry*))
    (maphash (lambda (name actor)
	       (declare (ignore name))
	       ;; flatten the alist, whose entries are (key . value) pairs, into key value key value
	       (format s "~&  ~{~A: ~A~^   ~}~%"
		       (loop for (key . value) in (actor-status actor) append (list key value))))
	     *nst-actor-registry*)))

;;; ======================================================================
;;; TESTS
;;; ======================================================================

(defun wait-until (predicate &key (timeout 3) (step 0.01))
  "Waits until PREDICATE returns true, or TIMEOUT seconds have passed. Returns its last value."
  (let ((deadline (+ (get-internal-real-time) (* timeout internal-time-units-per-second))))
    (loop until (funcall predicate)
	  until (> (get-internal-real-time) deadline)
	  do (sleep step)
	  finally (return (funcall predicate)))))

(defmacro with-test-actor ((var &rest initargs) &body body)
  "Runs BODY with VAR bound to a fresh actor, and always destroys it afterwards."
  `(let ((,var (make-instance 'nst-actor ,@initargs)))
     (unwind-protect (progn ,@body)
       (destroy-actor ,var))))

(defun test-counter-actor ()
  "Tests the actor lifecycle, its mailbox and its failure handling using standard assert."
  (format t "Starting test for counter actor...~%")

  ;; ---- 1. lifecycle and state -------------------------------------------------
  (with-test-actor (counter :name "Counter Actor Testing" :behavior #'counter-behavior
			    :initial-state 0 :stateful t)
    (assert (eq (actor-thread-state counter) :created) (counter)
            "Actor should start in 'created' state.")

    (start-actor counter)
    (assert (wait-until (lambda () (member (actor-thread-state counter) '(:waiting :running))))
	    (counter) "Actor should be in 'waiting' or 'running' state after start.")

    (send-message counter (lambda () :increment))
    (assert (wait-until (lambda () (= (actor-state counter) 1))) (counter)
            "Counter state should be 1 after :increment.")

    (send-message counter (lambda () :increment))
    (assert (wait-until (lambda () (= (actor-state counter) 2))) (counter)
            "Counter state should be 2 after another :increment.")

    (send-message counter (lambda () :decrement))
    (assert (wait-until (lambda () (= (actor-state counter) 1))) (counter)
            "Counter state should be 1 after :decrement.")

    ;; ---- 2. stopping and bulk queueing -------------------------------------
    (stop-actor counter)
    (assert (wait-until (lambda () (eq (actor-thread-state counter) :stopped))) (counter)
            "Actor should be in 'stopped' state after stop.")

    (send-message counter (lambda () :increment) t)   ;; bulk : queued, actor not woken
    (sleep 0.1)
    (assert (= (actor-state counter) 1) (counter)
            "Counter state should remain 1 while the actor is stopped.")

    (start-actor counter)
    (assert (wait-until (lambda () (= (actor-state counter) 2))) (counter)
            "The queued bulk message should be processed after start-actor.")

    (stop-actor counter)
    (send-message counter (lambda () :increment) t)
    (sleep 0.1)
    (flush-actor counter)                              ;; bulk batch flushed on demand
    (assert (wait-until (lambda () (= (actor-state counter) 3))) (counter)
            "flush-actor should process a queued bulk message."))

  ;; ---- 3. destroy ------------------------------------------------------------
  (let ((counter (make-instance 'nst-actor :name "Counter Destroy Test" :behavior #'counter-behavior
				:initial-state 0 :stateful t)))
    (destroy-actor counter)
    (assert (eq (actor-thread-state counter) :terminated) (counter)
            "Actor should be in 'terminated' state after destroy.")
    (assert (not (actor-alive-p counter)) (counter)
	    "Actor thread should be gone after destroy."))

  ;; ---- 4. a producer must not wait for a behaviour ---------------------------
  (with-test-actor (slow :name "Slow Actor" :stateful t :initial-state 0
			 :behavior (lambda (state message) (funcall message) (sleep 0.5) state))
    (send-message slow (lambda () :first))
    (sleep 0.1)                                        ;; the actor is inside its 0.5s behaviour
    (let ((start (get-internal-real-time)))
      (send-message slow (lambda () :second))
      (let ((elapsed (/ (- (get-internal-real-time) start) internal-time-units-per-second)))
	(assert (< elapsed 0.2) (elapsed)
		"send-message must not block while the actor is busy.")))
    (assert (wait-until (lambda () (= (actor-messages-processed slow) 2)) :timeout 3) (slow)
	    "Both messages should be processed."))

  ;; ---- 5. FIFO order ---------------------------------------------------------
  (let ((order '()))
    (with-test-actor (fifo :name "FIFO Actor" :stateful t :initial-state 0
			   :behavior (lambda (state message) (push (funcall message) order) state))
      (sleep 0.05)
      (dolist (token '(:a :b :c)) (send-message fifo (lambda () token)))
      (assert (wait-until (lambda () (= (length order) 3))) (order)
	      "All three messages should be processed.")
      (assert (equal (reverse order) '(:a :b :c)) (order)
	      "Messages should be processed in the order they were sent.")))

  ;; ---- 6. bounded mailbox ----------------------------------------------------
  (with-test-actor (bounded :name "Bounded Actor" :stateful t :initial-state 0 :max-queue-size 1
			    :behavior (lambda (state message) (funcall message) (sleep 0.3) state))
    (send-message bounded (lambda () :first))
    (sleep 0.05)
    (assert (send-message bounded (lambda () :second)) nil "One queued message should fit.")
    (assert (null (send-message bounded (lambda () :overflow))) nil
	    "A message sent to a full mailbox should be refused.")
    (assert (= (actor-messages-dropped bounded) 1) (bounded)
	    "The refused message should be counted as dropped."))

  ;; ---- 7. retry, then success ------------------------------------------------
  (let ((attempts 0))
    (with-test-actor (retrying :name "Retrying Actor" :stateful t :initial-state 0
			       :retry-limit 2 :retry-delay 0.05
			       :behavior (lambda (state message)
					   (declare (ignore message))
					   (incf attempts)
					   (when (< attempts 3) (error "transient failure"))
					   (incf state)))
      (send-message retrying (lambda () :work))
      (assert (wait-until (lambda () (= (actor-state retrying) 1))) (retrying)
	      "The message should succeed on the third attempt.")
      (assert (= (actor-messages-retried retrying) 2) (retrying)
	      "Both failed attempts should be counted as retries.")
      (assert (= (actor-messages-failed retrying) 0) (retrying)
	      "A message that eventually succeeded must not be counted as failed.")))

  ;; ---- 8. dead letter after the retries are exhausted ------------------------
  (with-test-actor (doomed :name "Doomed Actor" :stateful t :initial-state 0 :retry-limit 1 :retry-delay 0.05
			   :behavior (lambda (state message) (funcall message) (error "permanent failure") state))
    (send-message doomed (lambda () :never))
    (assert (wait-until (lambda () (= (actor-messages-failed doomed) 1))) (doomed)
	    "The message should fail permanently.")
    (assert (= (length (actor-dead-letters doomed)) 1) (doomed)
	    "The failed message should be kept in the dead letters.")
    (assert (actor-alive-p doomed) (doomed)
	    "A failing message must not kill the actor thread.")
    (assert (= (actor-messages-processed doomed) 0) (doomed)
	    "A message that failed permanently must not be counted as processed."))

  ;; ---- 9. error containment : the next message still runs --------------------
  (let ((processed '()))
    (with-test-actor (survivor :name "Survivor Actor" :stateful t :initial-state 0
			       :behavior (lambda (state message) (push (funcall message) processed) state))
      (send-message survivor (lambda () (error "boom")))
      (send-message survivor (lambda () :survived))
      (assert (wait-until (lambda () (member :survived processed))) (processed)
	      "The actor should carry on with the next message after one fails.")
      (assert (actor-alive-p survivor) (survivor) "The actor thread should still be alive.")))

  ;; ---- 10. ask and answer ----------------------------------------------------
  (with-test-actor (echo :name "Echo Actor" :stateful t :initial-state 0
			 :behavior (lambda (state message) (actor-reply (funcall message)) state))
    (multiple-value-bind (answer answered error)
	(send-message-and-wait echo (lambda () :hello) :timeout 2)
      (declare (ignore error))
      (assert (and answered (eq answer :hello)) (answer)
	      "send-message-and-wait should return the answer given with actor-reply.")))

  (with-test-actor (silent :name "Silent Actor" :stateful t :initial-state 0
			   :behavior (lambda (state message) (declare (ignore message)) state))
    (multiple-value-bind (answer answered error)
	(send-message-and-wait silent (lambda () :ignored) :timeout 0.2)
      (declare (ignore answer))
      (assert (and (null answered) (eq error :timeout)) (error)
	      "An unanswered question should time out.")))

  (with-test-actor (failer :name "Failing Answerer" :stateful t :initial-state 0
			   :behavior (lambda (state message) (funcall message) (error "cannot answer") state))
    (multiple-value-bind (answer answered error)
	(send-message-and-wait failer (lambda () :question) :timeout 2)
      (declare (ignore answer))
      (assert (and (null answered) (typep error 'error)) (error)
	      "A question whose behaviour fails should come back as an error, not a timeout.")))

  ;; ---- 11. supervision -------------------------------------------------------
  (with-test-actor (supervised :name "Supervised Actor" :stateful t :initial-state 0
			       :behavior (lambda (state message) (funcall message) (incf state)))
    (register-actor supervised)
    (bt:destroy-thread (actor-thread supervised))      ;; simulate a dead actor thread
    (assert (wait-until (lambda () (not (actor-alive-p supervised)))) (supervised)
	    "The actor thread should be dead.")
    (let ((revived (supervise-actors)))
      (assert (member "Supervised Actor" revived :test #'equal) (revived)
	      "The supervisor should report the revived actor."))
    (assert (actor-alive-p supervised) (supervised) "The supervisor should revive the actor.")
    (assert (= (actor-restart-count supervised) 1) (supervised) "The restart should be counted.")
    (send-message supervised (lambda () :after-restart))
    (assert (wait-until (lambda () (= (actor-state supervised) 1))) (supervised)
	    "The revived actor should process messages again.")
    (unregister-actor supervised))

  ;; ---- 12. cooperative shutdown ---------------------------------------------
  (let* ((finished nil)                              ;; let* : the behaviour closes over it
	 (actor (make-instance 'nst-actor :name "Graceful Actor" :stateful t :initial-state 0
			      :behavior (lambda (state message) (funcall message) (sleep 0.2)
					  (setf finished t) state))))
    (send-message actor (lambda () :long))
    (sleep 0.05)
    (destroy-actor actor)                              ;; must let the behaviour finish
    (assert finished (actor) "destroy-actor should let the message in flight finish.")
    (assert (eq (actor-thread-state actor) :terminated) (actor)
	    "Actor should be terminated after destroy."))

  ;; ---- 13. status report -----------------------------------------------------
  (with-test-actor (reported :name "Reported Actor" :stateful t :initial-state 0
			     :behavior (lambda (state message) (funcall message) state))
    (register-actor reported)
    (send-message reported (lambda () :ping))
    (assert (wait-until (lambda () (= (actor-messages-processed reported) 1))) (reported)
	    "The actor should process the ping.")
    (let ((status (actor-status reported)))
      (assert (equal (cdr (assoc :name status)) "Reported Actor") (status)
	      "Status should carry the actor name.")
      (assert (= (cdr (assoc :processed status)) 1) (status)
	      "Status should carry the processed counter."))
    (assert (search "Reported Actor" (actors-status-report)) nil
	    "The status report should mention the registered actor.")
    (unregister-actor reported))

  (format t "All tests passed successfully!~%")
  t)

(defun run-actor-tests () (test-counter-actor))

;; Run Test
;;(test-counter-actor)

;=======================================================================================================

(defun counter-behavior (state message)
  (multiple-value-bind (msg) (funcall message)
    (cond
      ((eq msg :increment) (+ state 1))
      ((eq msg :decrement) (- state 1))
      (t (format t "Unknown message: ~A~%" msg) state))))

;; Create a stateful counter actor
(defparameter *counter* (make-instance 'nst-actor
				       :name "Counter Actor"
                                       :behavior #'counter-behavior
                                       :initial-state 0
                                       :stateful t))

;; (setf *counter* nil) to delete the actor.
