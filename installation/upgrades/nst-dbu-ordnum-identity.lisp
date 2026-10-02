;;; nst-dbu-ordnum-identity.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; The ORDER identity migration — S0b of the orders batch.
;;; Design: aiharness/deepseek/skills/order-adhara-stories-CONTEXT.md § S0b,
;;; and the F1 decision record in its §10.
;;;
;;; ── WHY THIS EXISTS ──────────────────────────────────────────────────────────
;;; Measured 2026-09-27: 485 of 485 DOD_ORDER rows and 462 of 462 DOD_VENDOR_ORDERS
;;; rows have a NULL ORDNUM. THERE IS NO ORDER NUMBER IN THE DATABASE AT ALL — the
;;; column has never been written by anything, on any path — so this migration does not
;;; BACKFILL a value that exists somewhere; it INVENTS 485 of them. A copy-from-parent
;;; repair cannot do it: running that by hand returned `Rows matched: 462  Changed: 0`,
;;; because it copied NULL into NULL.
;;;
;;; ── THE DRY RUN, AND WHY IT IS THE SAME CODE PATH ────────────────────────────
;;; This writes 485 numbers and freezes 7 customer prefixes. To review it before it
;;; lands:
;;;
;;;   (load-upgrade-files *upgrade-files-directory*)          ; the file is not in the asd
;;;   (let ((*nst-ordnum-migration-dry-run* t))
;;;     (migrate-2026Sep-ordnum-identity))
;;;
;;; The dry run writes NOTHING and prints the prefix table it would store and the
;;; number range it would assign per (customer, financial year). It renders through the
;;; SAME nst-order-number-for the real run uses — the counter value is supplied rather
;;; than allocated — because a dry run that assembled the number differently would be
;;; reviewing different code.
;;;
;;; ── THE FIVE STEPS, IN THIS ORDER ────────────────────────────────────────────
;;;   1. add DOD_CUST_PROFILE.DOC_PREFIX varchar(8)      (NEVER char: it pads a space
;;;                                                      into every number)
;;;   2. allocate + store a prefix for every customer that HAS ORDERS (R2; the other 18
;;;      customers stay NULL and are allocated on first use)
;;;   3. mint ORDNUM for every order that has none, in ROW_ID order
;;;   4. copy the parent's number onto its DOD_VENDOR_ORDERS rows — meaningless before
;;;      step 3 and meaningful immediately after it
;;;   5. add the unique keys, LAST so they validate steps 2–4 rather than being
;;;      decoration: uk_ordnum (ORDNUM), uk_cust_doc_prefix (DOC_PREFIX), and
;;;      uk_vo_order_vendor (ORDER_ID, VENDOR_ID)
;;;
;;; ⚠ NOT TRANSACTIONAL, AND IT DOES NOT NEED TO BE. MySQL commits DDL implicitly, so
;;; the ALTER cannot roll back with the rest; every write below is instead IDEMPOTENT —
;;; only NULL columns are touched — so a failure halfway through (or a second run after
;;; one) leaves the database consistent and a re-run finishes the job. apply-migrations
;;; records the version only AFTER this function returns, so a failed attempt re-runs.
;;;
;;; ⚠ THE COUNTER ADVANCES EVEN IF A LATER STEP FAILS, and that is deliberate: a
;;; document-number series is allowed gaps, and reusing a number that a crashed run may
;;; already have written somewhere would be worse than a gap.
;;;
;;; ⚠ MEASURED AGAINST THE LIVE DATA 2026-09-28 before it was written: 25 customers, 7
;;; of them with orders, and their derived prefixes are GCUST837, DEMO, KND, GUEST,
;;; LGI, CUST17, PAWAN — ALL DISTINCT, so the de-duplication ladder does not fire on
;;; the existing data. The offline check asserts exactly those seven mappings, so the
;;; dry run below can be read against a prediction rather than a hope. 226 of the 485
;;; orders belong to two GUEST rows, whose prefixes are therefore synthetic — accepted,
;;; and recorded in the story file.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defvar *nst-ordnum-migration-dry-run* nil
  "T makes migrate-2026Sep-ordnum-identity REPORT and write nothing.
   Bind it around the call; it is deliberately not a global switch.")

(defun nst-ordnum-identity-int (value)
  "VALUE as an integer, or NIL. A raw query returns MySQL NULL as a non-integer, and a
   counter scope or tenant id must be an integer or NIL — never a truthy stand-in that
   would reach the SQL as something else."
  (if (integerp value) value nil))

(defun nst-ordnum-identity-customers-with-orders ()
  "((ROW-ID . NAME) ...) for every customer that has at least one order and no prefix
   yet, in ROW_ID order — deterministic, so the dry run and the real run agree.

   THE NAME CHAIN IS legal-company-name → legal-name → company-name → name, and the
   precedence earns its keep on the live data: customer 27's NAME is the synthetic
   'G33us22337333444' while its legal name is 'LG Iyengars Bakery', so the legal name is
   the one that yields a recognisable prefix (LGI). LEGAL_NAME and COMPANY_NAME are NULL
   on all seven customers that have orders, which is why the chain still ends at NAME
   for six of them."
  (mapcar (lambda (row) (cons (first row) (second row)))
          (clsql:query
           "SELECT c.`ROW_ID`,
                   COALESCE(NULLIF(c.`LEGAL_COMPANY_NAME`, ''),
                            NULLIF(c.`LEGAL_NAME`, ''),
                            NULLIF(c.`COMPANY_NAME`, ''),
                            c.`NAME`)
              FROM `DOD_CUST_PROFILE` c
             WHERE c.`DOC_PREFIX` IS NULL
               AND EXISTS (SELECT 1 FROM `DOD_ORDER` o WHERE o.`CUST_ID` = c.`ROW_ID`)
             ORDER BY c.`ROW_ID`")))

(defun nst-ordnum-identity-orders-to-mint ()
  "(ROW-ID CUST-ID TENANT-ID ORD-DATE DOC-PREFIX) for every order without a number, in
   ROW_ID order."
  (clsql:query
   "SELECT o.`ROW_ID`, o.`CUST_ID`, o.`TENANT_ID`, o.`ORD_DATE`, c.`DOC_PREFIX`
      FROM `DOD_ORDER` o JOIN `DOD_CUST_PROFILE` c ON c.`ROW_ID` = o.`CUST_ID`
     WHERE o.`ORDNUM` IS NULL
     ORDER BY o.`ROW_ID`"))

(defun nst-ordnum-identity-counters ()
  "A hash of (CUSTOMER-ID . FINYEAR) -> LAST_SEQ already allocated, for the DRY RUN.
   The real run allocates through nst-next-doc-counter instead; this exists so the dry
   run can compute the same values without writing to DOD_DOC_COUNTER."
  (let ((table (make-hash-table :test 'equal)))
    (dolist (row (clsql:query
                  "SELECT `SCOPE_ID`, `FINYEAR`, `LAST_SEQ` FROM `DOD_DOC_COUNTER`
                    WHERE `DOC_TYPE` = 'ORDER' AND `SCOPE_KIND` = 'CUSTOMER'"))
      (setf (gethash (cons (first row) (second row)) table) (third row)))
    table))

(defun migrate-2026Sep-ordnum-identity ()
  "Give every order a number, give every customer-with-orders a document prefix, and
   put the three unique keys in place. Idempotent; see the header for the dry run."
  (let ((dry *nst-ordnum-migration-dry-run*)
        (prefixes 0) (deduped 0) (minted 0) (vendor-rows 0)
        (per-series (make-hash-table :test 'equal))
        (simulated (nst-ordnum-identity-counters)))

    ;; ── 1. the column ────────────────────────────────────────────────────────
    (if (column-exists-p "DOD_CUST_PROFILE" "DOC_PREFIX")
        (format t "~&ordnum-identity: DOD_CUST_PROFILE.DOC_PREFIX already exists.~%")
        (if dry
            (format t "~&ordnum-identity: [dry] would ALTER DOD_CUST_PROFILE ADD DOC_PREFIX varchar(8).~%")
            (progn (clsql:execute-command
                    "ALTER TABLE `DOD_CUST_PROFILE` ADD COLUMN `DOC_PREFIX` VARCHAR(8) DEFAULT NULL")
                   (format t "~&ordnum-identity: added DOD_CUST_PROFILE.DOC_PREFIX varchar(8).~%"))))

    ;; ── 2. the customer prefixes ─────────────────────────────────────────────
    (dolist (cust (nst-ordnum-identity-customers-with-orders))
      (let* ((cust-id (car cust))
             (name (cdr cust))
             (base (nst-doc-prefix-base name))
             (chosen (nst-allocate-doc-prefix name (nst-doc-prefix-taken))))
        (unless base
          (error "customer ~D has no usable document prefix: its name (~S) holds fewer ~
                  than 3 alphanumeric characters. Set DOC_PREFIX by hand for it, then ~
                  re-run: nothing minted so far is lost, because only NULL columns are ~
                  written." cust-id name))
        (unless chosen
          (error "every document prefix candidate for customer ~D (~S) is taken. Set ~
                  DOC_PREFIX by hand for it, then re-run." cust-id base))
        (when (string/= chosen base) (incf deduped))
        (incf prefixes)
        (format t "~&  [~A] customer ~D  ~S  ->  ~A~%" (if dry "dry" "set") cust-id name chosen)
        (unless dry
          (clsql:execute-command
           (format nil "UPDATE `DOD_CUST_PROFILE` SET `DOC_PREFIX` = '~A' WHERE `ROW_ID` = ~D"
                   chosen cust-id)))))

    ;; ── 3. the numbers ───────────────────────────────────────────────────────
    (dolist (row (nst-ordnum-identity-orders-to-mint))
      (destructuring-bind (row-id cust-id tenant-id ord-date prefix) row
        (let* ((tid (nst-ordnum-identity-int tenant-id))
               (fy (nst-financial-year-short ord-date))
               (key (cons cust-id fy))
               ;; the real run allocates; the dry run COUNTS UP from what is stored, so
               ;; the number it prints is the number the real run would write
               (seq (if dry
                        (setf (gethash key simulated) (1+ (or (gethash key simulated) 0)))
                        nil))
               (number (nst-order-number-for *nst-order-number-format* prefix ord-date
                                             tid cust-id
                                             :counter seq)))
          (incf minted)
          (let ((series (gethash key per-series)))
            (if series
                (setf (gethash key per-series) (list (first series) number (1+ (second series))))
                (setf (gethash key per-series) (list number number 1))))
          (unless dry
            (clsql:execute-command
             (format nil "UPDATE `DOD_ORDER` SET `ORDNUM` = '~A' WHERE `ROW_ID` = ~D"
                     number row-id))))))

    ;; ── 4. the vendor rows ───────────────────────────────────────────────────
    (if dry
        (progn
          (setf vendor-rows
                (first (clsql:query "SELECT COUNT(*) FROM `DOD_VENDOR_ORDERS` WHERE `ORDNUM` IS NULL"
                                    :flatp t)))
          (format t "~&  [dry] would copy the parent number onto ~D DOD_VENDOR_ORDERS rows.~%"
                  vendor-rows))
        (progn
          (clsql:execute-command
           "UPDATE `DOD_VENDOR_ORDERS` vo JOIN `DOD_ORDER` o ON o.`ROW_ID` = vo.`ORDER_ID`
               SET vo.`ORDNUM` = o.`ORDNUM`
             WHERE vo.`ORDNUM` IS NULL")
          (setf vendor-rows
                (first (clsql:query "SELECT COUNT(*) FROM `DOD_VENDOR_ORDERS` WHERE `ORDNUM` IS NULL"
                                    :flatp t)))
          (format t "~&ordnum-identity: DOD_VENDOR_ORDERS rows still without a number: ~D~%"
                  vendor-rows)))

    ;; ── 5. the keys, last, so they VALIDATE the steps above ──────────────────
    (flet ((add-index (table index ddl)
             (if (index-exists-p table index)
                 (format t "~&  index ~A on ~A already present.~%" index table)
                 (if dry
                     (format t "~&  [dry] would add ~A on ~A.~%" index table)
                     (progn (clsql:execute-command ddl)
                            (format t "~&  added ~A on ~A.~%" index table))))))
      (add-index "DOD_ORDER" "uk_ordnum"
                 "ALTER TABLE `DOD_ORDER` ADD UNIQUE KEY `uk_ordnum` (`ORDNUM`)")
      (add-index "DOD_CUST_PROFILE" "uk_cust_doc_prefix"
                 "ALTER TABLE `DOD_CUST_PROFILE` ADD UNIQUE KEY `uk_cust_doc_prefix` (`DOC_PREFIX`)")
      ;; NEVER a unique key on DOD_VENDOR_ORDERS.ORDNUM: the number repeats once per
      ;; vendor of a multi-vendor order (D20). The natural key is the PAIR.
      (add-index "DOD_VENDOR_ORDERS" "uk_vo_order_vendor"
                 "ALTER TABLE `DOD_VENDOR_ORDERS` ADD UNIQUE KEY `uk_vo_order_vendor` (`ORDER_ID`, `VENDOR_ID`)"))

    ;; ── the report ───────────────────────────────────────────────────────────
    (format t "~&~%ordnum-identity ~:[APPLIED~;DRY RUN (nothing written)~]: ~
                 ~D prefix(es), ~D de-duplicated, ~D number(s), ~D vendor row(s) left~%"
            dry prefixes deduped minted vendor-rows)
    (let ((keys '()))
      (maphash (lambda (k v) (push (cons k v) keys)) per-series)
      (dolist (entry (sort keys #'string< :key (lambda (e) (format nil "~A" (car e)))))
        (destructuring-bind ((cust-id . fy) (from to count)) entry
          (format t "  customer ~D  ~A  ~D number(s):  ~A … ~A~%" cust-id fy count from to))))
    (unless dry
      (format t "~&ordnum-identity done. Verify: ~
                   SELECT COUNT(*) FROM DOD_ORDER WHERE ORDNUM IS NULL;      -- 0~%~
                 ~&                              ~
                   SELECT COUNT(DISTINCT ORDNUM) FROM DOD_ORDER;             -- 485~%"))))
