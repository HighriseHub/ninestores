;;; nst-bl-beltrusys.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

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

;;; Provenance is ALWAYS a list — enforced here, not by convention.
;;;
;;; WHY: the slot documents "List of sources", every consumer in the tree calls
;;; (append (bo-knowledge-provenance k) …) on it (hhub-bl-egn, nst-bl-CustomerUser,
;;; bo-add-provenance, bo-merge-provenance — ~20 call sites), and bo-merge /
;;; bo-add-provenance would do (append "a string" …) and signal
;;; "not of type LIST" if it were not. make-bo-knowledge has always normalized;
;;; the boundary macros in nst-mult-logic.lisp build the class with make-instance
;;; and passed PROVENANCE straight through, so a knowledge object from
;;; with-db-call carried a bare STRING.
;;;
;;; That surfaced as a 500 in a products API call (2026-09-13): ?exists found a
;;; soft-deleted product, tried to merge :T with :F to build the :C
;;; contradiction, and bo-merge-provenance blew up on (append "nst-prd/?exists …"
;;; (list "नियम-2 …")). The WAREHOUSE ?exists has the identical latent bug on its
;;; :C path (uk_gstin_name_tenant held by a soft-deleted row) — that path is
;;; listed as "not yet run" in nst-bl-apidefs2-CONTEXT.md §11, which is why it
;;; had never fired.
;;;
;;; Normalizing on initialize-instance fixes every construction path at once,
;;; including future ones, and is what makes the slot's own documentation true.
(defun bo-provenance-as-list (provenance)
  "PROVENANCE (a single value, a list, or NIL) → always a list."
  (cond ((null provenance) '())
        ((listp provenance) provenance)
        (t (list provenance))))

(defmethod initialize-instance :after ((k bo-knowledge) &rest initargs
                                       &key &allow-other-keys)
  "Force the provenance slot into list shape whatever the caller passed."
  (declare (ignore initargs))
  (setf (bo-knowledge-provenance k)
        (bo-provenance-as-list (bo-knowledge-provenance k))))

;;; Convenience constructor
(defun make-bo-knowledge (&key truth payload provenance timestamp)
  "Create a bo-knowledge instance. PROVENANCE may be a single value or a list."
  (make-instance 'bo-knowledge
                 :truth (or truth +unknown+)
                 :payload payload
                 :provenance (bo-provenance-as-list provenance)
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


;;; ═══════════════════════════════════════════════════════════════════════
;;; CONJOIN — composing the outcome of a SEQUENCE of steps
;;; ═══════════════════════════════════════════════════════════════════════
;;;
;;; WHY THIS IS NOT bo-merge. bo-merge/knowledge-join is the INFORMATION-ORDER
;;; JOIN (⊔i): "more information wins". Its table is
;;;
;;;     (T,T)=T   (T,F)=C   (T,U)=T   (T,C)=C
;;;     (F,F)=F   (F,U)=F   (U,U)=U   (·,C)=C
;;;
;;; and that is CORRECT for gathering evidence from several sources: a source that
;;; says T out-ranks one that says nothing, so (T,U) really is T.
;;;
;;; It is WRONG for sequencing. A compound verb like order->invoice asks a
;;; different question — "did ALL of this happen?" — and under ⊔i a step whose
;;; outcome is unknowable is silently absorbed: (T,U)=T reports SUCCESS for an
;;; action with a step we could not determine. That is a false success, the most
;;; dangerous answer this architecture can give.
;;;
;;; SO: ⊔i gathers evidence; conjoin composes steps. The rules below are chosen
;;; for the SEQUENCE question, and each one is a deliberate refusal to over-claim:
;;;
;;;   all :T               → :T   the action completed
;;;   all :F               → :F   definitively nothing happened — and ONLY then,
;;;                               because :F is what tells a caller "safe to retry"
;;;   any :C               → :C   a step is in contradiction; a human must look
;;;   some :T and some :F  → :C   PARTIAL APPLICATION. Step 1 says "it completed",
;;;                               step 2 says "it did not" — we were told both, which
;;;                               is exactly Belnap :C. Deliberately NOT :F: reporting
;;;                               failure would invite a blind retry that re-applies
;;;                               the steps that DID commit.
;;;   otherwise (any :U)   → :U   a step's outcome is unknowable, so we cannot state
;;;                               one. Also not :F, for the same retry reason: a :U
;;;                               step may have committed.
;;;
;;; ORDER-INDEPENDENT BY CONSTRUCTION, and that is not a stylistic choice: these
;;; rules are a function of the SET of step outcomes, not of the order they arrive
;;; in. The natural PAIRWISE version is NOT associative — (T,U)→U erases the fact
;;; that a T was seen, so a later F can no longer detect the partial application:
;;;
;;;     ((T,U),F) = (U,F) = U        but the set {T,U,F} is C
;;;     ((T,F),U) = (C,U) = C        while ((T,U),F) = U  — same three steps!
;;;
;;; A fold-left would therefore give different verdicts for the same three step
;;; outcomes depending on their order. Conjoin is deliberately N-ARY, there is no
;;; pairwise entry point to misuse, and bo-conjoin* folds nothing: it reads the
;;; whole list at once.

(defparameter *knowledge-truths* (list +true+ +false+ +unknown+ +contradiction+)
  "The four values a bo-knowledge truth may take. Conjoin validates against this
   rather than defaulting an unrecognized value to :U — a typo'd truth is a
   programming error, and quietly calling it 'unknown' would hide it.")

(defun knowledge-conjoin (truths)
  "The verdict for a SEQUENCE of step outcomes: (list of :T/:F/:U/:C) → one value.
   See the section header for the rules and for why this is not bo-merge.

   Reads the WHOLE list: there is no pairwise version, because the rules are not
   associative under pairwise folding."
  (when (null truths)
    (error "knowledge-conjoin: no steps. A compound verb with an empty step list is a programming error; answering :T would let the bug masquerade as success."))
  (dolist (truth truths)
    (unless (member truth *knowledge-truths*)
      (error "knowledge-conjoin: unrecognized truth ~S — expected one of ~S" truth *knowledge-truths*)))
  (cond
    ((every (lambda (tr) (eq tr +true+)) truths)          +true+)
    ((every (lambda (tr) (eq tr +false+)) truths)         +false+)
    ((some  (lambda (tr) (eq tr +contradiction+)) truths) +contradiction+)
    ((and (some (lambda (tr) (eq tr +true+)) truths)
          (some (lambda (tr) (eq tr +false+)) truths))    +contradiction+)
    (t                                                   +unknown+)))

(defun bo-conjoin (klist)
  "Compose a LIST of bo-knowledge step results into ONE verdict.
   The n-ary sibling of bo-merge* for sequencing rather than evidence-gathering —
   read the section header before using either.

   PROVENANCE IS THE UNION of every step's (deduped), which is the point: a
   compound verdict must be able to name every step that produced it. Payload is
   the DECISIVE step's — the first step whose truth equals the verdict, or, for a
   partial application (where the verdict :C appears in no single step), the first
   :F, because that is the step that stopped the sequence."
  (when (null klist)
    (error "bo-conjoin: no step results. A compound verb with an empty step list is a programming error; answering :T would let the bug masquerade as success."))
  (let* ((verdict (knowledge-conjoin (mapcar #'bo-knowledge-truth klist)))
         (decisive (or (find verdict klist :key #'bo-knowledge-truth)
                       (find +false+ klist :key #'bo-knowledge-truth)
                       (first klist))))
    (make-bo-knowledge
     :truth verdict
     :payload (bo-knowledge-payload decisive)
     :provenance (remove-duplicates
                  (loop for k in klist append (bo-knowledge-provenance k))
                  :test #'equal)
     :timestamp (reduce #'max klist :key #'bo-knowledge-timestamp))))

(defun bo-conjoin* (&rest klist)
  "Convenience: bo-conjoin over &rest arguments. Named with a star to sit beside
   bo-merge*, but note it is NOT a fold — see the section header."
  (bo-conjoin klist))

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
