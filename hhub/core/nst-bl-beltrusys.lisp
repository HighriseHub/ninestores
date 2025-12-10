;; bo-knowledge.lisp
(in-package :nstores)

;;; BO-KNOWLEDGE: wrapper for a BusinessObject plus TCUF provenance

(defclass bo-knowledge ()
  ((truth
    :initarg :truth
    :accessor bo-knowledge-truth
    :documentation "One of +true+, +false+, +unknown+, +contradiction+ (i.e. :T/:F/:U/:C).")
   (payload
    :initarg :payload
    :accessor bo-knowledge-payload
    :documentation "The domain object when truth = +true+; otherwise NIL or conflict payload.")
   (provenance
    :initarg :provenance
    :accessor bo-knowledge-provenance
    :initform '()
    :documentation "List of sources (strings or symbols) that contributed to this knowledge.")
   (timestamp
    :initarg :timestamp
    :accessor bo-knowledge-timestamp
    :initform (get-universal-time)
    :documentation "Time when this bo-knowledge was created/observed.")))

;;; Convenience constructor
(defun make-bo-knowledge (&key truth payload provenance timestamp)
  "Create a bo-knowledge instance. PROVENANCE may be a single value or a list."
  (make-instance 'bo-knowledge
                 :truth (or truth +unknown+)
                 :payload payload
                 :provenance (cond ((null provenance) '())
                                   ((listp provenance) provenance)
                                   (t (list provenance)))
                 :timestamp (or timestamp (get-universal-time))))

;;; Create from a boundary-result like (TRUTH PAYLOAD &optional SOURCE)
(defun bo-knowledge-from-boundary (boundary-result &key (default-source nil))
  "Convert boundary-result (list or values) into a bo-knowledge instance.
   boundary-result is expected like (TRUTH PAYLOAD &optional SOURCE ...)."
  (destructuring-bind (truth payload &rest rest) boundary-result
    (make-bo-knowledge :truth truth
                       :payload (if (eq truth +true+) payload nil)
                       :provenance (or (and rest (if (= (length rest) 1) (first rest) rest))
                                       default-source)
                       :timestamp (get-universal-time))))

;;; Predicates
(defgeneric bo-known-true-p (k)
  (:documentation "Return T if bo-knowledge is known true."))
(defmethod bo-known-true-p ((k bo-knowledge)) (eq (bo-knowledge-truth k) +true+))

(defgeneric bo-known-false-p (k)
  (:documentation "Return T if bo-knowledge is known false."))
(defmethod bo-known-false-p ((k bo-knowledge)) (eq (bo-knowledge-truth k) +false+))

(defgeneric bo-unknown-p (k)
  (:documentation "Return T if bo-knowledge is unknown."))
(defmethod bo-unknown-p ((k bo-knowledge)) (eq (bo-knowledge-truth k) +unknown+))

(defgeneric bo-contradictory-p (k)
  (:documentation "Return T if bo-knowledge is contradictory."))
(defmethod bo-contradictory-p ((k bo-knowledge)) (eq (bo-knowledge-truth k) +contradiction+))

;;; Safe payload accessor: returns domain object only for :T
(defgeneric bo-safe-payload (k)
  (:documentation "Return payload only when truth is :T; otherwise NIL."))
(defmethod bo-safe-payload ((k bo-knowledge))
  (when (bo-known-true-p k)
    (bo-knowledge-payload k)))

;;; Provenance helpers
(defgeneric bo-add-provenance (k source)
  (:documentation "Return a new bo-knowledge with SOURCE added to provenance (non-destructive)."))
(defmethod bo-add-provenance ((k bo-knowledge) source)
  (make-bo-knowledge :truth (bo-knowledge-truth k)
                     :payload (bo-knowledge-payload k)
                     :provenance (remove-duplicates (append (bo-knowledge-provenance k) (list source))
                                                   :test #'equal)
                     :timestamp (bo-knowledge-timestamp k)))

(defgeneric bo-merge-provenance (k1 k2)
  (:documentation "Return merged provenance list (deduped)"))
(defmethod bo-merge-provenance ((k1 bo-knowledge) (k2 bo-knowledge))
  (remove-duplicates (append (bo-knowledge-provenance k1) (bo-knowledge-provenance k2))
                     :test #'equal))

;;; Merge two bo-knowledge objects according to knowledge ordering
(defgeneric bo-merge (k1 k2)
  (:documentation "Merge two bo-knowledge instances under Belnap knowledge ordering."))

(defmethod bo-merge ((k1 bo-knowledge) (k2 bo-knowledge))
  ;; Use your knowledge-join and merge-payloads helpers from nst-mult-logic.lisp
  (let* ((s1 (bo-knowledge-truth k1))
         (s2 (bo-knowledge-truth k2))
         (merged-truth (knowledge-join s1 s2))
         ;; payload merging: when both have payloads, merge-payloads returns either merged payload or a :conflict list
         (p1 (bo-knowledge-payload k1))
         (p2 (bo-knowledge-payload k2))
         (merged-payload (merge-payloads p1 p2))
         (merged-provenance (bo-merge-provenance k1 k2))
         ;; escalate payload->nil for non-:T states except when conflict payload present
         (final-payload (cond
                          ((eq merged-truth +true+) merged-payload)
                          ((and (listp merged-payload)
                                (eq (first merged-payload) :conflict))
                           merged-payload) ; keep conflict detail as payload
                          (t nil))))
    ;; If payload conflict exists, ensure truth is contradiction
    (when (and (listp merged-payload)
               (eq (first merged-payload) :conflict))
      (setf merged-truth +contradiction+))
    (make-bo-knowledge :truth merged-truth
                       :payload final-payload
                       :provenance merged-provenance
                       :timestamp (max (bo-knowledge-timestamp k1)
                                       (bo-knowledge-timestamp k2)))))

;;; n-ary merge
(defun bo-merge* (&rest klist)
  "Merge multiple bo-knowledge objects (fold left using bo-merge)."
  (reduce #'bo-merge klist :initial-value (make-bo-knowledge :truth +unknown+ :payload nil :provenance '())))

;;; Convert back to a boundary/result list if needed: (TRUTH PAYLOAD SOURCE)
(defun bo-knowledge->boundary-result (k &optional (preferred-source nil))
  "Return a boundary-style list like (TRUTH PAYLOAD SOURCE...)."
  (list (bo-knowledge-truth k)
        (bo-knowledge-payload k)
        (or preferred-source (first (bo-knowledge-provenance k)))))

;;; human readable summary
(defun bo-knowledge-summary (k)
  (format nil "~A | payload: ~A | provenance: ~A | ts: ~A"
          (bo-knowledge-truth k)
          (bo-knowledge-payload k)
          (bo-knowledge-provenance k)
          (bo-knowledge-timestamp k)))

;;; Small utility: lift an existing boundary-result (list) into bo-knowledge, merging in source if payload already contains provenance
(defun boundary-result->bo (boundary-result &key (default-source nil))
  "Wrapper around bo-knowledge-from-boundary that normalizes payload provenance if payload is itself a bo-knowledge or plist."
  (let ((k (bo-knowledge-from-boundary boundary-result :default-source default-source)))
    ;; if payload is already a bo-knowledge, merge them
    (if (typep (bo-knowledge-payload k) 'bo-knowledge)
        (bo-merge k (bo-knowledge-payload k))
        k)))

(defmacro with-bo-knowledge-check (bo-knowledge &body status-clauses)
  "Enforces clean architecture by requiring explicit handling of all four 
   TCUF states (T, F, U, C) whenever calling an external/unreliable API 
   or boundary function. The API-CALL must return two values: (PAYLOAD STATUS).
   The result payload is made available to all status clauses under the
   variable name 'payload', and the status is available as 'status'."
  `(with-slots (truth payload provenance timestamp) ,bo-knowledge
     (case-truth truth
       ;; We manually map the :KEY to the user-supplied body:
       (:T ,@(cdr (assoc :T status-clauses)))
       (:F ,@(cdr (assoc :F status-clauses)))
       (:U ,@(cdr (assoc :U status-clauses)))
       (:C ,@(cdr (assoc :C status-clauses)))
       (otherwise (error "Boundary function returned invalid status: ~a" truth)))))
