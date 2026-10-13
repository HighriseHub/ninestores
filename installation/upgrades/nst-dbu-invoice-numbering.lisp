;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-invoice-numbering.lisp — give the invoice number a real series, the way the ORDER's was:
;;; DOD_VEND_PROFILE.DOC_PREFIX varchar(8) (the issuing vendor's series identity), a prefix per vendor
;;; from the shared ladder, and the DROP of the `before_insert_invoice` trigger that re-derives INVNUM
;;; as NST<row_id>-<calendar year> on every insert — global, wrong year, and it discarded every mint.
;;; 🚨 THE OPERATOR NEEDS `TRIGGER` (a third privilege after ALTER and INDEX):
;;;   GRANT ALTER, INDEX, TRIGGER ON hhubdb.* TO 'hhubadmin'@'localhost';
;;; A REFUSED DROP still succeeds and is reported: `make` re-reads the stored row and reports what the
;;; row holds, so the reply never lies, though the series stays the trigger's. Get the grant, do not
;;; write the number by hand. Dropping is NOT reversed by this file, and INVNUM is NOT backfilled
;;; (issued documents keep their numbers). Full reasoning: PENDING-WORK-CONTEXT.md §18 (US-015).

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
