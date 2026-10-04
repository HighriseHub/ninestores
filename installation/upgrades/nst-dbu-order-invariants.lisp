;;; nst-dbu-order-invariants.lisp — make two ORDER invariants STRUCTURAL (2026-10)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; TWO INVARIANTS THE ORDERS BATCH DEFERRED TO A MIGRATION, IN ITS OWN WORDS:
;;;
;;;   1. DELETED_STATE IS NULLABLE WITH NO DEFAULT on DOD_ORDER, DOD_ORDER_ITEMS and
;;;      DOD_VENDOR_ORDERS — `char(1) NULL DEFAULT NULL`, measured 2026-10-03. Every read in the
;;;      tree therefore carries an OR clause (`[or [= deleted-state "N"] [is deleted-state nil]]`)
;;;      because BOTH NULL and "N" could mean live, and a bare `[= … "N"]` hides rows. The batch
;;;      recorded the fix twice (nst-bl-ordh.lisp's filter builder and the copy ferries): "Fixing
;;;      the column's default to 'N' would collapse this to one clause; that is a migration, not a
;;;      verb." This is that migration: NOT NULL DEFAULT 'N' makes the third state unrepresentable,
;;;      and the OR clauses become redundant (simplifying them is a separate code change).
;;;
;;;   2. DOD_ORDER.CONTEXT_ID — the IDEMPOTENCY KEY — HAS NO UNIQUE INDEX. Two concurrent first
;;;      attempts carrying the same key can both find nothing and both insert, which is the residual
;;;      race S3's make :around records: "closing it needs a unique key, which is a migration rather
;;;      than a verb." The :around keeps answering a REPEAT with the existing order; the index is
;;;      what makes a genuinely concurrent duplicate impossible instead of merely unlikely.
;;;
;;; MEASURED BEFORE WRITING IT (2026-10-03, live database) — both steps are pure tightening, with
;;; NO data repair needed, which is why there is no backfill here:
;;;
;;;   DELETED_STATE NULLs:  DOD_ORDER 0 of 486,  DOD_ORDER_ITEMS 0 of 1259,  DOD_VENDOR_ORDERS 0 of 463
;;;   (values are exactly "N" or "Y", nothing else, on all three tables)
;;;   CONTEXT_ID: 0 NULL of 486 rows, 486 DISTINCT — so the unique index builds today.
;;;
;;; ⚠ THE LIVE DATA IS CLEAN, BUT A WRITER THAT PASSES NULL EXPLICITLY WILL NOW FAIL LOUDLY rather
;;; than store a third state. Three writers touch these columns today (persist-order, the shopcart
;;; item writer, and the adhara verbs) and all three set "N" — the noise is the point, and the
;;; alternative is the silent NULL that made every read carry an OR clause.
;;;
;;; ⚠ THE UNIQUE INDEX PERMITS MANY NULLs (MySQL), so a future row written without a key is still
;;; legal — an order with no idempotency key is not a duplicate, it is a row that opted out of the
;;; guarantee. The API always stamps one (:context-id from the body or the Idempotency-Key header).
;;;
;;; DRY RUN: bind *nst-order-invariants-dry-run* to T and call the function. It writes nothing and
;;; prints every statement it would run, plus the pre-flight counts — which is how this file is
;;; reviewed before it touches production.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defvar *nst-order-invariants-dry-run* nil
  "T = print what would change and write nothing. Bind it around a call:
     (let ((*nst-order-invariants-dry-run* t)) (migrate-2026Oct-order-invariants))")

(defparameter *nst-order-invariants-deleted-state-tables*
  '("DOD_ORDER" "DOD_ORDER_ITEMS" "DOD_VENDOR_ORDERS")
  "The three tables whose DELETED_STATE is being tightened. Listed rather than discovered: a table
   added to this set later should be a deliberate edit here, not a side effect of a wildcard.")

(defun nst-order-invariants-null-deleted-states ()
  "A list of (TABLE . COUNT) for DELETED_STATE IS NULL — the pre-flight. Any non-zero count means the
   NOT NULL step would rewrite data rather than tighten a constraint, and the operator must decide."
  (loop for table in *nst-order-invariants-deleted-state-tables*
        collect (cons table
                      (first (clsql:query (format nil "SELECT COUNT(*) FROM `~A` WHERE `DELETED_STATE` IS NULL" table)
                                          :flatp t)))))

(defun nst-order-invariants-duplicate-context-ids ()
  "The CONTEXT_ID values that appear more than once, as a list of (VALUE . COUNT). A non-empty answer
   means the unique index cannot be built, and it names the rows to resolve — which is exactly how the
   ORDNUM duplicate was found and fixed before uk_ordnum was added (the keys go last, so they VALIDATE
   the data)."
  (clsql:query "SELECT `CONTEXT_ID`, COUNT(*) FROM `DOD_ORDER`
                 GROUP BY `CONTEXT_ID` HAVING COUNT(*) > 1" :flatp t))

(defun nst-order-invariants-exec (statement &optional (what statement))
  "Run STATEMENT, or print it in a dry run. One place, so no step can forget the switch."
  (if *nst-order-invariants-dry-run*
      (format t "~&  [dry] would run: ~A~%" statement)
      (progn (clsql:execute-command statement)
             (format t "~&  ok  ~A~%" what))))

(defun migrate-2026Oct-order-invariants ()
  "Make DELETED_STATE NOT NULL DEFAULT 'N' on the three order tables, and add a unique index on
   DOD_ORDER.CONTEXT_ID. Idempotent: MODIFY to the definition a column already has is a no-op the
   engine accepts (and the skill's §5 rule is that bare MODIFY forms need no guard), while the index
   is wrapped in index-exists-p. The pre-flight REFUSES before touching anything if the data is not
   already in the state the constraints describe — a raw Error 1452/1062 from the engine names a
   constraint, not the rows an operator has to fix."
  (let ((dry *nst-order-invariants-dry-run*)
        (nulls (nst-order-invariants-null-deleted-states)))
    (format t "~&order-invariants ~:[APPLYING~;DRY RUN (nothing written)~]~%" dry)
    ;; ── pre-flight, before ANY change ────────────────────────────────────────
    (format t "~&  pre-flight: DELETED_STATE NULLs ~S~%" nulls)
    (let ((dirty (remove-if (lambda (cell) (zerop (cdr cell))) nulls)))
      (when dirty
        (error "order-invariants refused: ~{~A~^, ~} still hold NULL DELETED_STATE. The NOT NULL step ~
                would have to decide what those rows mean, which is a data decision rather than a ~
                constraint change. Resolve them (they are almost certainly live rows: 'N') and re-run."
               (mapcar #'car dirty))))
    (let ((dupes (nst-order-invariants-duplicate-context-ids)))
      (format t "~&  pre-flight: duplicate CONTEXT_IDs ~S~%" dupes)
      (when dupes
        (error "order-invariants refused: ~D CONTEXT_ID value(s) repeat in DOD_ORDER (~S). The ~
                idempotency key must be unique before it can be enforced; re-mint the later row's ~
                key (the same repair uk_ordnum needed) and re-run."
               (length dupes) dupes)))
    ;; ── 1. DELETED_STATE becomes a two-state column ──────────────────────────
    (dolist (table *nst-order-invariants-deleted-state-tables*)
      (nst-order-invariants-exec
       (format nil "ALTER TABLE `~A` MODIFY COLUMN `DELETED_STATE` CHAR(1) NOT NULL DEFAULT 'N'"
               table)
       (format nil "~A.DELETED_STATE is NOT NULL DEFAULT 'N' (the third state is now unrepresentable)"
               table)))
    ;; ── 2. the idempotency key gets its unique index ─────────────────────────
    (if (index-exists-p "DOD_ORDER" "uk_order_context_id")
        (format t "~&  index uk_order_context_id on DOD_ORDER already present.~%")
        (nst-order-invariants-exec
         "ALTER TABLE `DOD_ORDER` ADD UNIQUE KEY `uk_order_context_id` (`CONTEXT_ID`)"
         "uk_order_context_id on DOD_ORDER (a concurrent duplicate create is now impossible, not merely unlikely)"))
    ;; ── the report ───────────────────────────────────────────────────────────
    ;; ⚠ PASS THE ARGUMENT. The first version of this line omitted it and answered
    ;; 'error in FORMAT: No more arguments' AFTER every statement had run — the same shape as the
    ;; summary bug in nst-dbu-ordnum-identity.lisp: the report is the last thing the function does, so
    ;; its failure looks like a failed migration while the work has completed. A dry run is what caught
    ;; both, before a real run could leave an operator reading a lie.
    (format t "~&~%order-invariants ~:[APPLIED~;DRY RUN~]. Verify:~%~
                 ~&  SELECT TABLE_NAME, IS_NULLABLE, COLUMN_DEFAULT FROM information_schema.COLUMNS ~
                 WHERE TABLE_SCHEMA = DATABASE() AND COLUMN_NAME = 'DELETED_STATE' ~
                 AND TABLE_NAME IN ('DOD_ORDER','DOD_ORDER_ITEMS','DOD_VENDOR_ORDERS');   -- NO / N~%~
                 ~&  SELECT COUNT(*) FROM DOD_ORDER WHERE DELETED_STATE NOT IN ('N','Y');  -- 0~%~
                 ~&  SHOW INDEX FROM DOD_ORDER WHERE Key_name = 'uk_order_context_id';     -- present~%~
                 ~&  -- and the reads may now drop their OR clause: [= deleted-state N] is exact~%"
            dry)
    t))
