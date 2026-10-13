;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-invoice-numbering.lisp
;;;
;;; The INVOICE NUMBER gets a real series, built the way the ORDER's was (S0b/S0c):
;;;
;;;   1. DOD_VEND_PROFILE.DOC_PREFIX varchar(8) — the issuing vendor's series identity, the column
;;;      the customer has carried since S0b (DOD_CUST_PROFILE.DOC_PREFIX);
;;;   2. every existing vendor gets one, allocated by the same ladder (8 chars, then 6+2, then 5+3)
;;;      from the same shared pool, because derivations collide and a prefix handed to two issuers
;;;      defeats the point of one;
;;;   3. the `before_insert_invoice` TRIGGER IS DROPPED (see below — this is the load-bearing step).
;;;
;;; WHY A TRIGGER HAS TO GO, AND WHY THAT IS NOT VANDALISM
;;; -----------------------------------------------------
;;; installation/nstdbtriggers.sql holds:
;;;
;;;   create trigger before_insert_invoice before insert on DOD_INVOICE_HEADER for each row
;;;     set NEW.INVNUM = concat('NST', lpad(next_id,5,'0'), '-', year(now()));
;;;
;;; next_id is the table's own AUTO_INCREMENT, so the number is effectively the ROW-ID, zero-padded,
;;; stamped with the CALENDAR year. That is three separate violations of what US-005 asks for: the
;;; series is global rather than per vendor (per GSTIN), it is not an April–March financial year, and
;;; it cannot be consecutive once rows are deleted. And because it fires on EVERY insert, it silently
;;; discards whatever the application minted — `make` returns one number and the row stores another
;;; (MEASURED, PENDING-WORK §1d; the ord→inv junction documented the same trap).
;;;
;;; ⚠ `hhubuser` CANNOT SEE THE TRIGGER AT ALL (INFORMATION_SCHEMA.TRIGGERS is empty without the
;;; TRIGGER privilege), which is why this looked for months like the database eating a value. The
;;; fix cannot be a conditional insert — it has to remove the trigger.
;;;
;;; 🚨 AND THE OPERATOR ACCOUNT NEEDS `TRIGGER` FOR THAT, A THIRD PRIVILEGE AFTER `ALTER` AND `INDEX`:
;;;
;;;   GRANT ALTER, INDEX, TRIGGER ON hhubdb.* TO 'hhubadmin'@'localhost';
;;;
;;; IF THE DROP IS REFUSED the migration still succeeds and reports it, because the fallback is
;;; benign and is already in the code: nst-invh's `make` re-reads the stored row after the INSERT and
;;; reports WHAT THE ROW HOLDS (nst-stored-invoice-number). So a refused drop leaves the old series
;;; working — correct but not per-vendor and not FY-based — and never a lie about the number. Do not
;;; "fix" a refused drop by writing one anyway; get the grant.
;;;
;;; ⚠ DROPPING IT IS NOT REVERSIBLE BY THIS FILE. The trigger's DDL is in installation/nstdbtriggers.sql,
;;; so it can be recreated by hand, but nothing here re-creates it. That is deliberate: an automatic
;;; down-path would be a second place that has to stay in step with the up-path, and the trigger is
;;; exactly the kind of thing this migration exists to be rid of.
;;;
;;; ⚠ NO BACKFILL OF INVNUM. Existing numbers keep the trigger's shape — they are issued documents and
;;; a changed number on an issued invoice is worse than an inconsistent series across the cutover.
;;; The new series begins with the next invoice.
;;;
;;; REGISTER IT in the `*migrations*` list in hhub/core/nst-sch-mig.lisp. The helpers used below
;;; (add-column-if-absent) live in THAT file, not here — load-upgrade-files loads this AFTER it, so a
;;; local copy would silently win over the canonical one.

(in-package :nstores)

(defun nst-invoice-trigger-present-p ()
  "T when the `before_insert_invoice` trigger exists on DOD_INVOICE_HEADER.

   ⚠ ASK THE CATALOG BY NAME, DO NOT COUNT ROWS: `hhubuser` sees INFORMATION_SCHEMA.TRIGGERS as EMPTY
   (no TRIGGER privilege), so a COUNT(*) answers 0 on a database where the trigger is very much alive —
   the exact false negative that let this survive so long. This checks for the NAME in a way that also
   works for a privileged operator, and treats an unreadable catalog as 'assume present' so the DROP
   is attempted rather than skipped."
  (handler-case
      (> (first (clsql:query "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TRIGGERS
                               WHERE TRIGGER_SCHEMA = DATABASE()
                                 AND EVENT_OBJECT_TABLE = 'DOD_INVOICE_HEADER'
                                 AND TRIGGER_NAME = 'before_insert_invoice'"
                             :flatp t))
         0)
    (error () t)))

(defun migrate-2026Oct-invoice-numbering ()
  "Give the invoice number a per-vendor, April–March series: the vendor DOC_PREFIX column, a prefix for
   every existing vendor, and the removal of the trigger that would otherwise overwrite every minted
   number. Idempotent: the column guard is add-column-if-absent, prefix allocation skips vendors that
   already have one, and DROP TRIGGER IF EXISTS is a no-op the second time."
  (when (table-exists-p "DOD_VEND_PROFILE")
    (add-column-if-absent "DOD_VEND_PROFILE" "DOC_PREFIX"
                          "varchar(8) DEFAULT NULL COMMENT 'issuing vendor document-series prefix (A-Z0-9, 3-8 chars); allocated from the vendor name, mirrors DOD_CUST_PROFILE.DOC_PREFIX'"))
  ;; ── ALLOCATE A PREFIX PER VENDOR ────────────────────────────────────────────────────────────────
  ;; The LADDER, not a derivation: two vendors named \"XYZ Corp Ltd\" and \"XYZ Corporation\" both
  ;; derive XYZCORP, and the whole point of the prefix is that it identifies ONE issuer's series.
  ;; nst-vendor-doc-prefix-for stores what it picks, and the shared taken-pool includes the customers'
  ;; prefixes so one token never means two parties.
  (dolist (row (clsql:query "SELECT ROW_ID, NAME FROM DOD_VEND_PROFILE
                              WHERE DELETED_STATE IS NULL OR DELETED_STATE <> 'Y'"))
    (let ((vendor-id (first row)) (name (second row)))
      (handler-case
          (let ((existing (nst-vendor-doc-prefix-read vendor-id)))
            (if existing
                (format t "  vendor ~D keeps DOC_PREFIX ~A~%" vendor-id existing)
                (let ((chosen (nst-vendor-doc-prefix-for vendor-id name)))
                  (format t "  vendor ~D (~A) -> DOC_PREFIX ~A~%"
                          vendor-id (or name "?") (or chosen "NONE (not derivable)")))))
        (error (c)
          ;; A prefix that cannot be allocated is NOT a reason to abort the whole migration: the
          ;; invoice path falls back to an empty {prefix} and still numbers the document. Reported
          ;; loudly because a series with a hole in its identity is worth a human's attention.
          (format t "  ⚠ vendor ~D (~A): no DOC_PREFIX allocated — ~A~%" vendor-id (or name "?") c)))))
  ;; ── DROP THE TRIGGER ────────────────────────────────────────────────────────────────────────────
  (if (nst-invoice-trigger-present-p)
      (handler-case
          (progn
            (clsql:execute-command "DROP TRIGGER IF EXISTS before_insert_invoice")
            (format t "~&  DROPPED trigger before_insert_invoice — the application now owns INVNUM~%"))
        (error (c)
          (format t "~&  ⚠ COULD NOT DROP before_insert_invoice: ~A~%~
                     ~&    The grant needed is:  GRANT ALTER, INDEX, TRIGGER ON hhubdb.* TO '<operator>'@'localhost';~%~
                     ~&    Until then the trigger keeps re-deriving INVNUM on every insert. Nothing is~%~
                     ~&    broken: nst-invh's make re-reads the stored row and reports what it holds, so~%~
                     ~&    the reply never quotes a number the row does not carry. But the series will be~%~
                     ~&    the trigger's (global, calendar-year) rather than per-vendor and April–March.~%"
                  c)))
      (format t "~&  trigger before_insert_invoice not present — nothing to drop~%"))
  ;; ⚠ THE VENDOR-BLOB TEMPLATE UPDATE IS **NOT** HERE, DELIBERATELY. This migration was already
  ;; applied when that step was written, and `apply-migrations` skips a recorded version — so a step
  ;; added here now would never run. It lives in nst-dbu-invoice-number-format.lisp with its own
  ;; version instead.
  (format t "  invoice numbering migration done~%"))
