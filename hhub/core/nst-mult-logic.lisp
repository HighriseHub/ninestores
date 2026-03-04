;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;;; nst-bl-crud-macros.lisp
;;;;
;;;; CRUD-specific database boundary macros built on top of the
;;;; Belnap Four-Valued (TCUF) truth system defined in
;;;; nst-mult-logic.lisp and nst-bl-beltrusys.lisp.
;;;;
;;;; Each macro wraps a single DB form, catches errors, interprets
;;;; row/object counts, and returns a BO-KNOWLEDGE instance whose
;;;; TRUTH slot carries one of :T :F :U :C.
;;;;
;;;; ─────────────────────────────────────────────────────────────
;;;;  TRUTH-VALUE SEMANTICS BY OPERATION
;;;; ─────────────────────────────────────────────────────────────
;;;;
;;;;  ┌─────────────┬──────────────────────────────────────────────┬───────────────────────────────────────────────┬────────────────────────────────────────────┬──────────────────────────────────────────────┐
;;;;  │  Operation  │ :T  (True)                                   │ :F  (False)                                   │ :U  (Unknown)                              │ :C  (Contradiction)                          │
;;;;  ├─────────────┼──────────────────────────────────────────────┼───────────────────────────────────────────────┼────────────────────────────────────────────┼──────────────────────────────────────────────┤
;;;;  │ CREATE      │ Insert committed; payload = new entity/id.   │ Constraint violation: the record cannot       │ Network/DB error; we do NOT know whether    │ Two distinct records were apparently          │
;;;;  │             │ Exactly one row was added, confirmed.        │ exist as provided (duplicate PK, NOT NULL,    │ the row was committed. Treat as "maybe      │ created from one insert (e.g. a REPLACE INTO  │
;;;;  │             │                                              │ FK violation).  Nothing was written.          │ inserted".  Do NOT assume success.          │ deleted an old row and inserted a new one,    │
;;;;  │             │                                              │                                               │                                            │ returning 2 affected rows).                  │
;;;;  ├─────────────┼──────────────────────────────────────────────┼───────────────────────────────────────────────┼────────────────────────────────────────────┼──────────────────────────────────────────────┤
;;;;  │ READ-ONE    │ Exactly one record found; payload = entity.  │ No record found for the given key.  The       │ DB error or timeout; presence/absence of    │ More than one record returned for a           │
;;;;  │             │                                              │ entity definitively does not exist.           │ the record is unknown.                     │ query that must return at most one row.       │
;;;;  │             │                                              │                                               │                                            │ Data-integrity violation; investigate.        │
;;;;  ├─────────────┼──────────────────────────────────────────────┼───────────────────────────────────────────────┼────────────────────────────────────────────┼──────────────────────────────────────────────┤
;;;;  │ READ-ALL    │ One or more records found; payload = list.   │ Empty result set.  There are definitively no  │ DB error or timeout; the result set is      │ Result set contains logically inconsistent    │
;;;;  │             │                                              │ matching records right now.                   │ unknown.                                   │ rows (e.g. duplicate PKs detected in the     │
;;;;  │             │                                              │                                               │                                            │ returned list).                              │
;;;;  ├─────────────┼──────────────────────────────────────────────┼───────────────────────────────────────────────┼────────────────────────────────────────────┼──────────────────────────────────────────────┤
;;;;  │ UPDATE      │ Exactly 1 row affected; payload = updated    │ 0 rows affected; the target record does not   │ DB error or timeout; we do NOT know if the  │ More than 1 row affected when the WHERE       │
;;;;  │             │ entity (if re-fetched) or rows-affected = 1. │ exist (or already matches the new values).    │ update was applied.                        │ clause was meant to be unique.  Possible      │
;;;;  │             │                                              │                                               │                                            │ data corruption; rollback if possible.        │
;;;;  ├─────────────┼──────────────────────────────────────────────┼───────────────────────────────────────────────┼────────────────────────────────────────────┼──────────────────────────────────────────────┤
;;;;  │ DELETE      │ Exactly 1 row deleted; payload = deleted-id  │ 0 rows deleted; target record does not exist. │ DB error or timeout; we do NOT know if the  │ More than 1 row deleted when the WHERE        │
;;;;  │             │ or rows-affected = 1.                        │ Idempotent delete can treat this as :T if     │ delete was committed.                      │ clause was meant to be unique.  Unintended    │
;;;;  │             │                                              │ desired (see :allow-idempotent key).          │                                            │ bulk delete; alert immediately.              │
;;;;  └─────────────┴──────────────────────────────────────────────┴───────────────────────────────────────────────┴────────────────────────────────────────────┴──────────────────────────────────────────────┘
;;;;
;;;; ─────────────────────────────────────────────────────────────
;;;;  CONTRACT FOR DB-FORM RETURN VALUES
;;;; ─────────────────────────────────────────────────────────────
;;;;
;;;;  with-db-create  — DB-FORM returns (values new-entity &optional second-entity)
;;;;                    second-entity present  → :C
;;;;
;;;;  with-db-read-one  — DB-FORM returns a single object or NIL,
;;;;                      OR a list.  More than one element → :C.
;;;;
;;;;  with-db-read-all  — DB-FORM returns a list (possibly empty).
;;;;                      An optional PK-EXTRACTOR function can be
;;;;                      supplied to detect duplicate PK → :C.
;;;;
;;;;  with-db-update / with-db-delete
;;;;                    — DB-FORM returns (values rows-affected &optional entity)
;;;;                      rows-affected drives :T/:F/:C.
;;;;
;;;; ─────────────────────────────────────────────────────────────
;;;;  CONDITION CLASSES FOR :F DISCRIMINATION
;;;; ─────────────────────────────────────────────────────────────
;;
;; Subclass this in your adapter layer to mark constraint violations
;; as a *definitive* :F rather than the generic :U catch-all.
;;

;;;; ─────────────────────────────────────────────────────────────
;;;;  USAGE EXAMPLES
;;;; ─────────────────────────────────────────────────────────────

#|
;;; ── CREATE ──────────────────────────────────────────────────
(let ((k (with-db-create (insert-user! {:name "Alice" :email "a@b.com"}))))
  (with-bo-knowledge-check k
    (:T (format t "Created user: ~A~%" payload))
    (:F (format t "Rejected: ~A~%" payload))   ; constraint violation detail
    (:U (format t "Unknown commit state; schedule idempotency check.~%"))
    (:C (format t "CRITICAL: two records created from one insert: ~A~%" payload))))

;;; ── READ-ONE ────────────────────────────────────────────────
(let ((k (with-db-read-one (find-user-by-id db 42))))
  (with-bo-knowledge-check k
    (:T (format t "Found: ~A~%" payload))
    (:F (format t "No user with id 42.~%"))
    (:U (format t "DB unavailable; cannot confirm existence.~%"))
    (:C (format t "CRITICAL: duplicate rows for id 42: ~A~%" payload))))

;;; ── READ-ALL ────────────────────────────────────────────────
(let ((k (with-db-read-all (find-orders-by-customer db customer-id)
           :source "DB/Orders"
           :pk-extractor #'order-id)))
  (with-bo-knowledge-check k
    (:T (format t "~A orders found.~%" (length payload)))
    (:F (format t "No orders for customer.~%"))
    (:U (format t "DB error; order list unavailable.~%"))
    (:C (format t "CRITICAL: duplicate order PKs in result: ~A~%" payload))))

;;; ── UPDATE ──────────────────────────────────────────────────
(let ((k (with-db-update (update-email! db 42 "new@example.com"))))
  (with-bo-knowledge-check k
    (:T (format t "Updated successfully: ~A~%" payload))
    (:F (format t "No record found to update.~%"))
    (:U (format t "DB error; update state unknown. Retry with caution.~%"))
    (:C (format t "CRITICAL: ~A rows updated — possible data corruption.~%"
                (second payload)))))

;;; ── DELETE (strict) ─────────────────────────────────────────
(let ((k (with-db-delete (delete-user! db 42) :source "DB/UserDelete")))
  (with-bo-knowledge-check k
    (:T (format t "Deleted: ~A~%" payload))
    (:F (format t "User 42 not found.~%"))
    (:U (format t "DB error; delete state unknown.~%"))
    (:C (format t "CRITICAL: ~A rows deleted — alert SRE immediately!~%"
                (second payload)))))

;;; ── DELETE (idempotent — useful for soft-delete / dedup flows) ──
(let ((k (with-db-delete (delete-token! db token)
                          :allow-idempotent t
                          :source "DB/TokenDelete")))
  (with-bo-knowledge-check k
    (:T (format t "Token is gone (deleted or was already absent).~%"))
    (:F (error "Should not happen when :allow-idempotent is T"))
    (:U (format t "DB error; token deletion state unknown.~%"))
    (:C (format t "CRITICAL: multiple tokens matched — investigate!~%"))))
|#
;;;; Belnap Four-Valued Logic (FDE) Implementation for E-commerce Decision Making

;; 1. Define the Four Truth Values
(defconstant +true+         :T     "Truth Only (P is true, not false)")
(defconstant +false+        :F     "False Only (P is false, not true)")
(defconstant +unknown+      :U     "Unknown (Missing information, API failure)")
(defconstant +contradiction+ :C     "Contradiction (Conflicting information)")

;; Helper macro for concisely checking for the four values
(defmacro case-truth (truth &body clauses)
  "A specialized CASE macro for logic values."
  `(case ,truth
     ((+true+ :T) ,@(cdr (assoc :T clauses)))
     ((+false+ :F) ,@(cdr (assoc :F clauses)))
     ((+unknown+ :U) ,@(cdr (assoc :U clauses)))
     ((+contradiction+ :C) ,@(cdr (assoc :C clauses)))
     (otherwise (error "Invalid truth value: ~a" ,truth))))

;; --- LOGIC OPERATORS ---

;; 2. NOT Operator (my-not)
;; Truth Table: T -> F, F -> T, U -> U, C -> C
(defun my-not (p)
  "Implements the logical NOT operator for FDE logic."
  (case-truth p
    (:T +false+)
    (:F +true+)
    (:U +unknown+)
    (:C +contradiction+)))

;; 3. AND Operator (my-and)
;; Defined by the intersection of information states (less information wins)
(defun my-and (p q)
  (cond
    ((or (eq p +false+) (eq q +false+)) +false+)
    ((eq p +true+) q)
    ((eq q +true+) p)
    ((and (eq p +unknown+) (eq q +unknown+)) +unknown+)
    ((and (eq p +contradiction+) (eq q +contradiction+)) +contradiction+)
    ((or (and (eq p +unknown+) (eq q +contradiction+))
         (and (eq p +contradiction+) (eq q +unknown+)))
     +false+)
    (t (error "Unhandled AND case: ~a, ~a" p q))))

;; 4. OR Operator (my-or)
;; Defined by the union of information states (more information wins)
(defun my-or (p q)
  "Implements the logical OR operator for FDE logic.
   (Based on the join operation of the Truth lattice.)"
  (cond
    ;; If either P or Q is T, the result is T (T is dominant)
    ((or (eq p +true+) (eq q +true+)) +true+)
    ;; If one is F, the result is the other one (F is identity)
    ((eq p +false+) q)
    ((eq q +false+) p)
    ;; Remaining cases: U, C, (U OR U), (C OR C), (U OR C)
      ((and (eq p +unknown+) (eq q +unknown+)) +unknown+)
      ((and (eq p +contradiction+) (eq q +contradiction+)) +contradiction+)
      ;; If one is U and the other is C, FDE treats this as True (T)
      ;; because C contains True information.
      ((or (and (eq p +unknown+) (eq q +contradiction+))
           (and (eq p +contradiction+) (eq q +unknown+))) +true+)
      (t (error "Unhandled OR case: ~a, ~a" p q))))

(defun knowledge-meet (p q)
  "Intersection of knowledge (common certainty)."
  (cond
    ((or (eq p +unknown+) (eq q +unknown+)) +unknown+)
    ((or (eq p +true+) (eq q +true+)) +true+)
    ((or (eq p +false+) (eq q +false+)) +false+)
    ((or (eq p +contradiction+) (eq q +contradiction+)) +contradiction+)
    (t +unknown+)))

(defun knowledge-join (a b)
  "Combines knowledge states from two sources (union of knowledge)."
  (cond
    ;; If either is contradiction, the result stays contradiction.
    ((or (eq a +contradiction+) (eq b +contradiction+)) +contradiction+)
    ;; Contradiction arises if one says true and the other false.
    ((and (eq a +true+) (eq b +false+)) +contradiction+)
    ((and (eq a +false+) (eq b +true+)) +contradiction+)
    ;; Otherwise, prefer the more informative one.
    ;; If either is known (T or F), pick that.
    ((eq a +true+) +true+)
    ((eq b +true+) +true+)
    ((eq a +false+) +false+)
    ((eq b +false+) +false+)
    ;; If both are unknown, stays unknown.
    ((and (eq a +unknown+) (eq b +unknown+)) +unknown+)
    ;; Default fallback.
    (t +unknown+)))

(defmacro with-knowledge-check (api-call &body knowledge-clauses)
  `(multiple-value-bind (payload status) ,api-call
     (let ((knowledge status))
       (case-truth knowledge
         (:U ,@(cdr (assoc :U knowledge-clauses)))
         (:T ,@(cdr (assoc :T knowledge-clauses)))
         (:F ,@(cdr (assoc :F knowledge-clauses)))
         (:C ,@(cdr (assoc :C knowledge-clauses)))
         (otherwise (error "Invalid knowledge value: ~a" knowledge))))))


(defun merge-payloads (p1 p2)
  "Merge two payloads intelligently.
   If both are equal, return one.
   If one is NIL, return the other.
   If they differ, return a list of both to mark conflict."
  (cond
    ((equal p1 p2) p1)
    ((null p1) p2)
    ((null p2) p1)
    (t (list :conflict p1 p2))))

(defun merge-knowledge (result1 result2)
  "Merges two boundary results of the form (STATUS PAYLOAD)
   according to Belnap knowledge ordering.
   Returns a new (STATUS PAYLOAD) pair."
  (destructuring-bind (status1 payload1) result1
    (destructuring-bind (status2 payload2) result2
      (let* ((merged-status (knowledge-join status1 status2))
             (merged-payload (merge-payloads payload1 payload2)))
        ;; If payloads conflict, escalate status to :C
        (when (and (listp merged-payload)
                   (eq (car merged-payload) :conflict))
          (setf merged-status +contradiction+))
        (list merged-status merged-payload)))))

(defun merge-knowledge* (&rest results)
  (reduce #'merge-knowledge results))


(defmacro with-boundary-check (api-call &body status-clauses)
  "Enforces clean architecture by requiring explicit handling of all four 
   TCUF states (T, F, U, C) whenever calling an external/unreliable API 
   or boundary function. The API-CALL must return two values: (PAYLOAD STATUS).
   The result payload is made available to all status clauses under the
   variable name 'payload', and the status is available as 'status'."
  (let ((payload-sym (gensym "PAYLOAD"))
        (status-sym (gensym "STATUS"))
	(source-sym (gensym "SOURCE")))
    ;; 1. Use multiple-value-bind to unpack the two return values (data and status)
    ;; We use GENSYMs here to prevent name clashes with other variables, 
    ;; but the subsequent LET makes them available to the user clauses.
    `(destructuring-bind (,status-sym ,payload-sym ,source-sym) ,api-call
       ;; 2. Make the unpacked values available to the user's clauses
       (let ((payload ,payload-sym)  ;; User can access this as 'payload'
             (status ,status-sym) ;; User can access this as 'status'
	     (source ,source-sym))  ;; User can access this as 'source' 
         ;; 3. Enforce the required status handling using the pre-defined case-truth
         (case-truth status
           ;; We manually map the :KEY to the user-supplied body:
           (:T ,@(cdr (assoc :T status-clauses)))
           (:F ,@(cdr (assoc :F status-clauses)))
           (:U ,@(cdr (assoc :U status-clauses)))
           (:C ,@(cdr (assoc :C status-clauses)))
           (otherwise (error "Boundary function returned invalid status: ~a" status)))))))




(define-condition db-constraint-violation (error)
  ((message :initarg :message :reader constraint-message))
  (:documentation
   "Signal this (or a subclass) from your DB adapter when a constraint
    violation occurs (duplicate key, NOT NULL, FK violation, check
    constraint, etc.).  with-db-create will map this to :F."))

(define-condition db-not-found (error)
  ()
  (:documentation
   "Optionally signal from a DB adapter when a required record is
    definitively absent.  Treated as :F in read/update/delete macros."))

;;;; ─────────────────────────────────────────────────────────────
;;;;  INTERNAL HELPERS
;;;; ─────────────────────────────────────────────────────────────

(defun %log-db-error (operation error-object backtrace)
  "Append a DB error to the business-functions log file."
  (with-open-file (stream *hhubbusinessfunctionslogfile*
                          :direction :output
                          :if-exists :append
                          :if-does-not-exist :create)
    (format stream "DB-~A Error (~A): ~A~%~A~%"
            operation
            (mysql-now)
            error-object
            backtrace)))

(defun %detect-duplicate-pks (rows pk-extractor)
  "Return T if PK-EXTRACTOR applied to ROWS yields any duplicate values."
  (when pk-extractor
    (let ((keys (mapcar pk-extractor rows)))
      (not (= (length keys)
              (length (remove-duplicates keys :test #'equal)))))))



;;;; ─────────────────────────────────────────────────────────────
;;;;  1.  WITH-DB-CREATE
;;;;      Wraps a db-save call intended to INSERT a new row.
;;;; ─────────────────────────────────────────────────────────────
;;;;
;;;;  Caller responsibilities BEFORE this macro:
;;;;    1. (init dbas bo)                      ; attach the BusinessObject
;;;;    2. (setcompany dbas company)            ; set the tenant
;;;;    3. (copy-businessobject-to-dbobject dbas) ; sync BO → DB row
;;;;
;;;;  PRE-FLIGHT (optional keyword form) — a CLSQL SELECT expression that
;;;;  returns a list.  If the list is non-empty, the macro short-circuits
;;;;  to :C without attempting the save (catches race conditions / stale
;;;;  in-memory caches).

(defmacro with-db-create ((dbas &key (source "DB/Create") pre-flight))
  "INSERT boundary macro for CLSQL via DBAdapterService.db-save.

   Returns a BO-KNOWLEDGE instance.  Status-clauses (:T ...) (:F ...) 
   (:U ...) (:C ...) are optional; if omitted the bo-knowledge is 
   returned and you can branch with WITH-BO-KNOWLEDGE-CHECK."
  (let ((dbas-gs    (gensym "DBAS"))
        (pf-rows-gs (gensym "PF-ROWS"))
        (bk-gs      (gensym "BK"))
        (err-gs     (gensym "ERR"))
        (bt-gs      (gensym "BT")))
    `(let* ((,dbas-gs ,dbas)
            ;; ── Step 1: optional pre-flight duplicate check ─────────────
            (,bk-gs
              ,(if pre-flight
                   `(handler-case
                        (let ((,pf-rows-gs ,pre-flight))
                          (when (and (listp ,pf-rows-gs)
                                     (> (length ,pf-rows-gs) 0))
                            ;; A row already exists → :C, skip the save
                            (make-bo-knowledge
			     :truth +contradiction+
			     :payload ,pf-rows-gs
			     :provenance ,source)))
                      (error (,err-gs)
                        ;; Pre-flight itself failed; commit status unknown → :U
                        (make-bo-knowledge
			 :truth +unknown+
			 :payload nil
			 :provenance ,source)))
                   nil)))

       ;; ── Step 2: run db-save only if no early :C or :U was captured ───
       (or ,bk-gs
           (handler-case
               (progn
                 ;; db-save calls clsql:update-records-from-instance
                 (db-save ,dbas-gs)
		 (Copy-DBObject-To-BusinessObject ,dbas-gs)
		 (make-bo-knowledge
		  :truth +true+
		  :payload (getbusinessobject ,dbas-gs)
		  :provenance ,source))

             ;; :F — definitive constraint rejection; row was never written
             (db-constraint-violation (,err-gs)
               (make-bo-knowledge
		:truth +false+
                :payload (list :constraint-violation
                                   (constraint-message ,err-gs))
                :provenance ,source))

             ;; :U — hhub-database-error is what db-save signals on CLSQL
             ;;      failure (see existing db-save handler-case)
             (hhub-database-error (,err-gs)
               (declare (ignore ,err-gs))
               (make-bo-knowledge
		:truth +unknown+
		:payload nil
		:provenance ,source))

             ;; :U — any other unexpected error
             (error (,err-gs)
               (let ((,bt-gs (sb-debug:list-backtrace)))
                 (%log-crud-error "CREATE" ,err-gs ,bt-gs)
                 (make-bo-knowledge
		  :truth +unknown+
		  :payload nil
		  :provenance ,source))))))))


;;;; ─────────────────────────────────────────────────────────────
;;;;  WITH-DB-UPDATE
;;;; ─────────────────────────────────────────────────────────────

(defmacro with-db-update ((dbas &key (source "DB/Update") pre-flight)
                          &body body)
  "UPDATE boundary macro for CLSQL via DBAdapterService.db-save.

   Caller responsibilities BEFORE this macro:
     1. (init dbas updated-bo)                     ; attach updated BO
     2. (setcompany dbas company)                  ; set tenant context
     3. (copy-businessobject-to-dbobject dbas)     ; flush new values to DB row

   PRE-FLIGHT (strongly recommended) — a CLSQL SELECT expression that
   returns a list of rows matching the update target.  Drives :F and :C
   detection.  Without it, :F cannot be produced because CLSQL does not
   return rows-affected from db-save.

   Returns a BO-KNOWLEDGE instance.  Use WITH-BO-KNOWLEDGE-CHECK to
   branch on the result.  BODY is unused and reserved for future use."
  (declare (ignore body))
  (let ((dbas-gs    (gensym "DBAS"))
        (pf-rows-gs (gensym "PF-ROWS"))
        (bk-gs      (gensym "BK"))
        (err-gs     (gensym "ERR"))
        (bt-gs      (gensym "BT")))
    `(let* ((,dbas-gs ,dbas)
            ;; ── Step 1: optional pre-flight existence + uniqueness check ─
            (,bk-gs
              ,(if pre-flight
                   `(handler-case
                        (let ((,pf-rows-gs ,pre-flight))
                          (cond
                            ;; :F — target entity does not exist; skip save
                            ((or (null ,pf-rows-gs)
                                 (and (listp ,pf-rows-gs)
                                      (null ,pf-rows-gs)))
                             (make-bo-knowledge
                              :truth      +false+
                              :payload    nil
                              :provenance ,source))

                            ;; :C — >1 row for a unique key; skip save to
                            ;;      prevent bulk mutation of multiple rows
                            ((and (listp ,pf-rows-gs)
                                  (> (length ,pf-rows-gs) 1))
                             (make-bo-knowledge
                              :truth      +contradiction+
                              :payload    ,pf-rows-gs
                              :provenance ,source))

                            ;; Exactly 1 live row found — proceed to save
                            (t nil)))

                      (error (,err-gs)
                        ;; Pre-flight itself failed; update state unknown → :U
                        (let ((,bt-gs (sb-debug:list-backtrace)))
                          (%log-crud-error "UPDATE/PREFLIGHT" ,err-gs ,bt-gs)
                          (make-bo-knowledge
                           :truth      +unknown+
                           :payload    nil
                           :provenance ,source))))
                   ;; No pre-flight — proceed directly to save
                   ;; :F and :C cannot be detected without pre-flight
                   nil)))

       ;; ── Step 2: run db-save only if pre-flight did not short-circuit ─
       (or ,bk-gs
           (handler-case
               (progn
                 ;; db-save calls clsql:update-records-from-instance
                 ;; CLSQL mutates the dbobject in-place; no return value
                 (db-save ,dbas-gs)
                 ;; Sync DB truth back into the BusinessObject
                 (copy-dbobject-to-businessobject ,dbas-gs)
                 (make-bo-knowledge
                  :truth      +true+
                  :payload    (getbusinessobject ,dbas-gs)
                  :provenance ,source))

             ;; :F — constraint violation during save (e.g. unique index
             ;;      conflict on the new field values being written)
             (db-constraint-violation (,err-gs)
               (make-bo-knowledge
                :truth      +false+
                :payload    (list :constraint-violation
                                  (constraint-message ,err-gs))
                :provenance ,source))

             ;; :U — CLSQL wrapped DB error; update state is unknown
             (hhub-database-error (,err-gs)
               (declare (ignore ,err-gs))
               (make-bo-knowledge
                :truth      +unknown+
                :payload    nil
                :provenance ,source))

             ;; :U — any other unexpected error
             (error (,err-gs)
               (let ((,bt-gs (sb-debug:list-backtrace)))
                 (%log-crud-error "UPDATE" ,err-gs ,bt-gs)
                 (make-bo-knowledge
                  :truth      +unknown+
                  :payload    nil
                  :provenance ,source))))))))



(defmacro with-db-delete ((dbas
                           &key
                             (source           "DB/Delete")
                             pre-flight
                             (allow-idempotent nil))
                          &body body)
  "SOFT-DELETE boundary macro for CLSQL via DBAdapterService.db-delete.

   db-delete (inherited from DBAdapterService) sets DELETED_STATE to
   'Y' on the dbobject and calls clsql:update-record-from-slot.
   No hard DELETE is ever issued against the database.

   Caller responsibilities BEFORE this macro:
     1. (setcompany dbas company)   ; set tenant context
     2. Ensure dbobject is loaded   ; db-delete needs a populated dbobject

   PRE-FLIGHT (strongly recommended) — a CLSQL SELECT expression that
   returns a list of LIVE rows (DELETED_STATE = 'N') matching the delete
   target.  Drives :F and :C detection.

   ALLOW-IDEMPOTENT (default NIL) — when T, a pre-flight returning 0
   live rows is promoted to :T with payload :already-absent.  Use for
   cleanup jobs and token-expiry flows where you only assert 'this
   record must not be live', not 'I must be the one who deleted it'.

   Returns a BO-KNOWLEDGE instance.  Use WITH-BO-KNOWLEDGE-CHECK to
   branch on the result.  BODY is unused and reserved for future use."
  (declare (ignore body))
  (let ((dbas-gs    (gensym "DBAS"))
        (pf-rows-gs (gensym "PF-ROWS"))
        (bk-gs      (gensym "BK"))
        (err-gs     (gensym "ERR"))
        (bt-gs      (gensym "BT")))
    `(let* ((,dbas-gs ,dbas)
            ;; ── Step 1: optional pre-flight live-row check ───────────────
            (,bk-gs
              ,(if pre-flight
                   `(handler-case
                        (let ((,pf-rows-gs ,pre-flight))
                          (cond
                            ;; :F / :T(idempotent) — no live row found
                            ((or (null ,pf-rows-gs)
                                 (and (listp ,pf-rows-gs)
                                      (null ,pf-rows-gs)))
                             (if ,allow-idempotent
                                 ;; Record is already absent — desired state
                                 ;; achieved regardless of who deleted it
                                 (make-bo-knowledge
                                  :truth      +true+
                                  :payload    '(:already-absent t)
                                  :provenance ,source)
                                 ;; Caller expected a live record; it is gone
                                 (make-bo-knowledge
                                  :truth      +false+
                                  :payload    nil
                                  :provenance ,source)))

                            ;; :C — >1 live row for a unique key; skip
                            ;;      db-delete to prevent bulk soft-deletion
                            ((and (listp ,pf-rows-gs)
                                  (> (length ,pf-rows-gs) 1))
                             (make-bo-knowledge
                              :truth      +contradiction+
                              :payload    ,pf-rows-gs
                              :provenance ,source))

                            ;; Exactly 1 live row found — proceed to delete
                            (t nil)))

                      (error (,err-gs)
                        ;; Pre-flight itself failed; deletion state unknown → :U
                        (let ((,bt-gs (sb-debug:list-backtrace)))
                          (%log-crud-error "DELETE/PREFLIGHT" ,err-gs ,bt-gs)
                          (make-bo-knowledge
                           :truth      +unknown+
                           :payload    nil
                           :provenance ,source))))
                   ;; No pre-flight supplied
                   ;; :F and :C cannot be detected; proceed directly
                   nil)))

       ;; ── Step 2: run db-delete only if pre-flight did not short-circuit
       (or ,bk-gs
           (handler-case
               (progn
                 ;; db-delete sets DELETED_STATE="Y" then calls
                 ;; clsql:update-record-from-slot on the dbobject
                 (db-delete ,dbas-gs)
                 ;; Sync the DELETED_STATE back into the BusinessObject
                 (copy-dbobject-to-businessobject ,dbas-gs)
		 (make-bo-knowledge
                  :truth      +true+
                  :payload    (getbusinessobject ,dbas-gs)
                  :provenance ,source))

             ;; :U — CLSQL wrapped DB error; deletion state is unknown
             (hhub-database-error (,err-gs)
               (declare (ignore ,err-gs))
               (make-bo-knowledge
                :truth      +unknown+
                :payload    nil
                :provenance ,source))

             ;; :U — any other unexpected error
             (error (,err-gs)
               (let ((,bt-gs (sb-debug:list-backtrace)))
                 (%log-crud-error "DELETE" ,err-gs ,bt-gs)
                 (make-bo-knowledge
                  :truth      +unknown+
                  :payload    nil
                  :provenance ,source))))))))


;;;; ─────────────────────────────────────────────────────────────
;;;;  2.  WITH-DB-READ-ONE
;;;;      Wraps db-fetch which does a CLSQL SELECT expecting ≤1 row.
;;;; ─────────────────────────────────────────────────────────────
;;;;
;;;;  db-fetch must return a LIST (CLSQL select always returns a list).
;;;;  The macro inspects the list length to determine truth, then calls
;;;;  Copy-DbObject-To-BusinessObject on success so the caller gets a
;;;;  fully populated BusinessObject in the payload.

(defmacro with-db-read-one ((dbas row-id &key (source "DB/ReadOne")))
  "SELECT-one boundary macro for CLSQL via DBAdapterService.db-fetch.

   Calls (db-fetch DBAS ROW-ID), inspects the returned list length,
   and returns a BO-KNOWLEDGE instance."
  (let ((dbas-gs  (gensym "DBAS"))
        (rowid-gs (gensym "ROWID"))
        (rows-gs  (gensym "ROWS"))
        (bk-gs    (gensym "BK"))
        (err-gs   (gensym "ERR"))
        (bt-gs    (gensym "BT")))
    `(let* ((,dbas-gs  ,dbas)
            (,rowid-gs ,row-id)
            (,bk-gs
              (handler-case
                  (let ((,rows-gs (db-fetch ,dbas-gs ,rowid-gs)))
                    (cond
                      ;; :C — CLSQL returned >1 row; PK uniqueness violated
                      ((and (listp ,rows-gs) (> (length ,rows-gs) 1))
                       (make-bo-knowledge :truth +contradiction+
					  :payload ,rows-gs
					  :provenance ,source))

                      ;; :F — empty list / NIL; entity definitively absent
                      ((or (null ,rows-gs)
                           (and (listp ,rows-gs) (null ,rows-gs)))
                       (make-bo-knowledge
			:truth +false+
			:payload nil
			:provenance ,source))

                      ;; :T — exactly one row; sync BO from DB object
                      (t
                       (copy-dbobject-to-businessobject ,dbas-gs)
		       (make-bo-knowledge
			:truth +true+
                        :payload (getbusinessobject ,dbas-gs)
                        :provenance     ,source))))

                ;; :F — adapter explicitly signals absence
                (db-not-found (,err-gs)
                  (declare (ignore ,err-gs))
                  (make-bo-knowledge
		   :truth +false+
		   :payload nil
		   :provenance ,source))

                ;; :U — CLSQL wrapped DB error
                (hhub-database-error (,err-gs)
                  (declare (ignore ,err-gs))
                  (make-bo-knowledge
		   :truth +unknown+
		   :payload nil
		   :provenance ,source))

                ;; :U — any other error
                (error (,err-gs)
                  (let ((,bt-gs (sb-debug:list-backtrace)))
                    (%log-crud-error "READ-ONE" ,err-gs ,bt-gs)
                    (make-bo-knowledge
		     :truth +unknown+
		     :payload nil
		     :provenance ,source))))))
       ,bk-gs)))


;;;; ─────────────────────────────────────────────────────────────
;;;;  3.  WITH-DB-READ-ALL
;;;;      Wraps db-fetch-all which does a CLSQL SELECT returning ≥0 rows.
;;;; ─────────────────────────────────────────────────────────────

(defmacro with-db-read-all ((dbas &key (source "DB/ReadAll") pk-extractor))
  "SELECT-many boundary macro for CLSQL via DBAdapterService.db-fetch-all.

   PK-EXTRACTOR (optional) — a one-arg function (lambda (bo) ...) that
   returns the primary-key value for a row in the result list.  When
   supplied, the list is scanned for duplicates; any duplicate promotes
   status to :C.

   Returns a BO-KNOWLEDGE instance.  Payload on :T is the list returned
   by db-fetch-all (typically a list of CLSQL view-class instances)."
  (let ((dbas-gs  (gensym "DBAS"))
        (rows-gs  (gensym "ROWS"))
        (bk-gs    (gensym "BK"))
        (err-gs   (gensym "ERR"))
        (bt-gs    (gensym "BT")))
    `(let* ((,dbas-gs ,dbas)
            (,bk-gs
              (handler-case
                  (let ((,rows-gs (db-fetch-all ,dbas-gs)))
                    (cond
                      ;; :F — no results at all
                      ((or (null ,rows-gs)
                           (and (listp ,rows-gs) (null ,rows-gs)))
                       (make-bo-knowledge +false+ nil ,source))

                      ;; :C — duplicate PKs in result (requires pk-extractor)
                      ((%list-has-duplicate-pks-p ,rows-gs ,pk-extractor)
                       (make-bo-knowledge +contradiction+ ,rows-gs ,source))

                      ;; :T — one or more clean records
                      (t
                       (make-bo-knowledge +true+ ,rows-gs ,source))))

                ;; :U — CLSQL DB error
                (hhub-database-error (,err-gs)
                  (declare (ignore ,err-gs))
                  (make-bo-knowledge +unknown+ nil ,source))

                (error (,err-gs)
                  (let ((,bt-gs (sb-debug:list-backtrace)))
                    (%log-crud-error "READ-ALL" ,err-gs ,bt-gs)
                    (make-bo-knowledge +unknown+ nil ,source))))))
       ,bk-gs)))





(defun %log-crud-error (operation error-object backtrace)
  "Append a structured DB error to the business-functions log file."
  (ignore-errors
    (with-open-file (stream *hhubbusinessfunctionslogfile*
                            :direction :output
                            :if-exists :append
                            :if-does-not-exist :create)
      (format stream "CRUD-~A Error (~A): ~A~%~A~%"
              operation (mysql-now) error-object backtrace))))



(defmacro with-db-call (db-form &optional (source "DB/Unknown"))
  (let ((results-list-gs (gensym "RESULTS"))
        (payload-gs      (gensym "PAYLOAD"))
        (error-gs        (gensym "ERROR"))
        (backtrace-gs    (gensym "BACKTRACE")))
    `(handler-case
         (let* ((,results-list-gs (multiple-value-list ,db-form))
                (,payload-gs      (car ,results-list-gs)))
           (cond
             ;; C — Contradiction: More than 1 result
             ((> (length ,results-list-gs) 1)
              (make-instance 'bo-knowledge
                             :truth :C
                             :payload ,results-list-gs
                             :provenance ,source))

             ;; F — No result
             ((null ,payload-gs)
              (make-instance 'bo-knowledge
                             :truth :F
                             :payload nil
                             :provenance ,source))

             ;; T — Success
             (t
              (make-instance 'bo-knowledge
                             :truth :T
                             :payload ,payload-gs
                             :provenance ,source))))

       (error (,error-gs)
         (let ((,backtrace-gs (sb-debug:list-backtrace)))
           ;; LOGGING HERE
           (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE*
                                   :direction :output
                                   :if-exists :append
                                   :if-does-not-exist :create)
             (format stream "~A~A"
                     (format nil "Database Error (~A): ~A~%"
                             (mysql-now)
                             ,error-gs)
                     ,backtrace-gs))

           ;; return U
           (make-instance 'bo-knowledge
                          :truth :U
                          :payload nil
                          :provenance ,source))))))


;;;; with-db-call-list
;;;;
;;;; Sibling macro to with-db-call for read-all scenarios.
;;;; The TCUF semantics differ from with-db-call as follows:
;;;;
;;;;  with-db-call       (read-one intent)
;;;;  ─────────────────────────────────────────────────────
;;;;  :T  — exactly one result returned
;;;;  :F  — nil / no result
;;;;  :C  — more than one result (data integrity violation)
;;;;  :U  — any error
;;;;
;;;;  with-db-call-list  (read-all intent)
;;;;  ─────────────────────────────────────────────────────
;;;;  :T  — one or more results returned (list is payload)
;;;;  :F  — empty list / nil (no matching records)
;;;;  :C  — duplicate PKs detected in result (optional pk-extractor)
;;;;  :U  — any error

(defmacro with-db-call-list (db-form
                             &key
                               (source      "DB/List")
                               pk-extractor)
  "Execute DB-FORM expecting a list result and return a BO-KNOWLEDGE instance.

   DB-FORM    — any CLSQL SELECT expression that returns a flat list.
   SOURCE     — provenance string for the bo-knowledge instance.
   PK-EXTRACTOR — optional one-arg function (lambda (row) ...) that
                  returns the primary-key value for each row.  When
                  supplied, the result list is scanned for duplicate
                  PKs; any duplicate promotes truth to :C.

   TCUF semantics:
     :T — non-empty list returned with no duplicate PKs
     :F — nil or empty list (no matching records exist)
     :C — duplicate PKs detected in result list
     :U — any error during execution of DB-FORM"
  (let ((results-gs   (gensym "RESULTS"))
        (keys-gs      (gensym "KEYS"))
        (error-gs     (gensym "ERROR"))
        (backtrace-gs (gensym "BACKTRACE")))
    `(handler-case
         (let ((,results-gs ,db-form))
           (cond
             ;; :F — nil or empty list; no matching records exist
             ((or (null ,results-gs)
                  (and (listp ,results-gs)
                       (null ,results-gs)))
              (make-instance 'bo-knowledge
                             :truth      :F
                             :payload    nil
                             :provenance ,source))

             ;; :C — duplicate PKs detected when pk-extractor provided
             ((and ,pk-extractor
                   (let ((,keys-gs (mapcar ,pk-extractor ,results-gs)))
                     (/= (length ,keys-gs)
                         (length (remove-duplicates ,keys-gs
                                                    :test #'equal)))))
              (make-instance 'bo-knowledge
                             :truth      :C
                             :payload    ,results-gs
                             :provenance ,source))

             ;; :T — one or more clean records
             (t
              (make-instance 'bo-knowledge
                             :truth      :T
                             :payload    ,results-gs
                             :provenance ,source))))

       ;; :U — any error; result set is unknown
       (error (,error-gs)
         (let ((,backtrace-gs (sb-debug:list-backtrace)))
           (with-open-file (stream *hhubbusinessfunctionslogfile*
                                   :direction      :output
                                   :if-exists      :append
                                   :if-does-not-exist :create)
             (format stream "~A~A"
                     (format nil "Database Error (~A): ~A~%"
                             (mysql-now)
                             ,error-gs)
                     ,backtrace-gs))
           (make-instance 'bo-knowledge
                          :truth      :U
                          :payload    nil
                          :provenance ,source))))))


(defun tcuf-value-checker (value)
  "Adapter function that performs the simple, deterministic T/F check."
  (if value (list :T value) (list :F nil)))

(defmacro with-non-null-check (value-form &body body)
  "A specialized version of WITH-BOUNDARY-CHECK for deterministic null checks.
   If the value-form is non-NIL (Status :T), the BODY is executed with the value 
   bound to the variable PAYLOAD.
   If the value-form is NIL (Status :F), the macro returns an explicit :VALUE-MISSING 
   signal immediately."
  (let ((value-sym (gensym "VALUE")))
    `(let ((,value-sym ,value-form))
       (with-boundary-check (tcuf-value-checker ,value-sym)
         (:T (let ((payload ,value-sym))
               ,@body))
         (:F (progn
               (format t "~&[Internal Check] Missing value detected. Aborting sequence.")
               :value-missing)) ; Returns a specific failure signal
         (:U (error "Should not happen in tcuf-value-checker"))
         (:C (error "Should not happen in tcuf-value-checker"))))))



;; --- E-COMMERCE EXAMPLE: Pincode Check ---

(defun get-pincode-api-result (pincode)
  "Simulates the external API call and maps its output to a 4-valued truth value."
  (cond
    ;; Case 1: Ideal Success (90% of the time)
    ((string= pincode "560001")
     (values +true+ "Bangalore" "Bangalore" "Karnataka"))

    ;; Case 2: Definitive Failure (Pincode exists, but is permanently non-serviceable)
    ((string= pincode "000000")
     (values +false+ "N/A" "N/A" "N/A"))

    ;; Case 3: API Service Failure (Your 10% case) - Returns UNKNOWN
    ((string= pincode "999999")
     (values +unknown+ "NOT FOUND" "NOT FOUND" "NOT FOUND"))

    ;; Case 4: Contradiction (Internal data bug)
    ;; Assume local DB lists it as valid, but the external API returns an error status
    ;; that means "invalid" but also provides a city name.
    ((string= pincode "400011")
     ;; In a real system, this would be determined by combining two sources.
     ;; For simulation, we manually return the conflicting state:
     (values +contradiction+ "Mumbai" "Mumbai" "Maharashtra"))
    
    ;; Default to F for any other unknown pincode
    (t (values +false+ "N/A" "N/A" "N/A"))))

(defun evaluate-checkout-readiness (pincode stock-status payment-verified)
  "Evaluates the final checkout decision based on multiple FDE truth values."
  (let* ((pincode-status (nth-value 0 (get-pincode-api-result pincode)))
         (final-status (my-and pincode-status (my-and stock-status payment-verified))))
    (format t "~%--- EVALUATION FOR PINCODE: ~a ---" pincode)
    (format t "~%Pincode Status:   ~a" pincode-status)
    (format t "~%Stock Status:    ~a" stock-status)
    (format t "~%Payment Status:  ~a" payment-verified)
    (format t "~%Combined Status: ~a" final-status)
    
    (case-truth final-status
      (:T (format t "~%-> DECISION: FULL PURCHASE APPROVED. Proceed to payment."))
      
      (:F (format t "~%-> DECISION: BLOCKED. One or more factors were definitely false."))
      
      (:U (format t "~%-> DECISION: SOFT BLOCK. Missing data (API failure). Requires manual review or customer fallback."))
      
      (:C (format t "~%-> DECISION: CRITICAL ERROR. Data contradiction detected. INVESTIGATE IMMEDIATELY.")))))

;; --- RUN EXAMPLES ---

;; T R U T H   T A B L E   T E S T S
(format t "NOT +TRUE+: ~a~%" (my-not +true+)) ; -> F
(format t "NOT +UNKNOWN+: ~a~%" (my-not +unknown+)) ; -> U
(format t "AND +TRUE+ +UNKNOWN+: ~a~%" (my-and +true+ +unknown+)) ; -> U (Less info wins)
(format t "AND +FALSE+ +UNKNOWN+: ~a~%" (my-and +false+ +unknown+)) ; -> F (F is dominant)
(format t "OR +FALSE+ +UNKNOWN+: ~a~%" (my-or +false+ +unknown+)) ; -> U (More info wins)
(format t "OR +TRUE+ +CONTRADICTION+: ~a~%" (my-or +true+ +contradiction+)) ; -> T (T is dominant)

;; C H E C K O U T   S C E N A R I O S
(defconstant +stock-is-good+ +true+)
(defconstant +payment-confirmed+ +true+)

;; Scenario 1: Everything is perfect
(evaluate-checkout-readiness "560001" +stock-is-good+ +payment-confirmed+)

;; Scenario 2: The Pincode API fails (your 10% case)
(evaluate-checkout-readiness "999999" +stock-is-good+ +payment-confirmed+)

;; Scenario 3: Pincode is definitive failure (non-serviceable)
(evaluate-checkout-readiness "000000" +stock-is-good+ +payment-confirmed+)

;; Scenario 4: Contradiction in Pincode check
(evaluate-checkout-readiness "400011" +stock-is-good+ +payment-confirmed+)

;; Scenario 5: Stock is known to be false, Pincode is unknown
(defconstant +stock-is-false+ +false+)
(evaluate-checkout-readiness "999999" +stock-is-false+ +payment-confirmed+)

(format t "~%~%This structure cleanly separates the process of DETERMINING truth (in get-pincode-api-result) from the process of DECIDING based on aggregated truth (in evaluate-checkout-readiness).")


;; Continuation of previous file: four_valued_logic.lisp

;; --- ARCHITECTURAL ENFORCER MACRO ---




;; --- EXAMPLE BOUNDARY FUNCTION (MOCK EXTERNAL CALL) ---

(defun external-inventory-check (product-id)
  "Mocks an inventory microservice call. Must return payload and status."
  (case product-id
    ;; Happy path: Found, Confirmed
    (1001 (list :T 5 "Inventory")) 
    ;; Definitive failure: Item discontinued
    (1002 (list :F 0 "Inventory"))
    ;; Network failure: API timeout, unable to connect
    (1003 (list :U nil "Inventory")) 
    ;; Contradiction: Internal inventory system says 10, warehouse DB says -5
    (1004 (list :C nil "Inventory"))
    ;; Any other
    (otherwise (list :F 0 "Inventory"))))

;; --- USAGE EXAMPLE IN DDD APPLICATION LAYER ---

(defun handle-add-to-cart (user-id product-id quantity)
  "The application service layer function that orchestrates the boundary check."
  (with-boundary-check (external-inventory-check product-id)
    (format T "This is the payload - ~A. This is source - ~A" payload source)
    ;; Required handlers for all four states:
    (:T (lambda () 
          (format nil "SUCCESS: For user ~d Adding ~a units to cart for Product ~a. (Inventory Count: ~a)" 
                  user-id quantity product-id 
                  (nth-value 0 (external-inventory-check product-id)))))
    (:F (lambda () 
          (format nil "FAILURE: Product ~a is permanently discontinued." product-id)))
    (:U (lambda () 
          (format nil "PENDING: Inventory check timed out. Placing order on hold for later review. Customer notified.")))
    (:C (lambda () 
          (format nil "CRITICAL ERROR: Internal inventory data conflict for Product ~a. Blocking transaction and alerting SRE." product-id)))))

;; --- RUN EXAMPLE USAGE ---

(format t "~%--- Running Boundary Checks ---")
(format t "~%Check 1001 (T): ~a" (funcall (handle-add-to-cart 1 1001 1)))
(format t "~%Check 1002 (F): ~a" (funcall (handle-add-to-cart 1 1002 1)))
(format t "~%Check 1003 (U): ~a" (funcall (handle-add-to-cart 1 1003 1)))
(format t "~%Check 1004 (C): ~a" (funcall (handle-add-to-cart 1 1004 1)))

