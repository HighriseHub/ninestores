;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-invoice-number-format.lisp
;;;
;;; Point every vendor's STORED invoice-number template at the new invoice series.
;;;
;;; 🚨 WHY THIS IS A SEPARATE MIGRATION RATHER THAN PART OF nst-dbu-invoice-numbering.lisp: that file
;;; was ALREADY APPLIED (version 13102026-invoice-numbering is in DOD_SCHEMA_MIGRATIONS), and
;;; `apply-migrations` removes every entry whose version is recorded — so editing an applied migration
;;; does NOTHING. A step added to it after the fact would look shipped and never run. This file carries
;;; its own version instead.
;;;
;;; WHY THE STEP IS NEEDED AT ALL, given the shipped default is already the new shape:
;;;
;;;   A VENDOR'S STORED SETTING WINS OVER THE SHIPPED DEFAULT. The shipped
;;;   `invoice-number-format` is now INV-{prefix}-{fy}-{counter:6}, but every existing vendor blob was
;;;   written with the OLD shape "INV-YYYY-MM-{counter}" — no issuer, no financial year. Fixing only the
;;;   code therefore leaves a vendor reading INV-2026-10-518: longer, but still without their prefix and
;;;   still not an April–March series. MEASURED on order 510's Generate Invoice (2026-10-13) — the old
;;;   stored template is what nst-format-doc-number received.
;;;
;;; ⚠ AND IT EDITS THE BLOB BY PARSING IT, NOT BY SQL PATTERN-MATCHING. The settings column holds a
;;; printed Lisp alist; a REPLACE() on a substring could hit a matching string anywhere in it (a footer,
;;; a terms block), so the alist is read, the one key is set, and the whole thing is re-printed. The
;;; write goes through `sql-literal`, because a settings blob contains apostrophes and an unescaped one
;;; ends the SQL literal (Error 1064 — the trap the ABAC seed paid for).
;;;
;;; ⚠ A BLOB THAT WILL NOT PARSE IS LEFT ALONE and reported. It predates this migration, the reader
;;; falls back safely, and rewriting a blob we could not parse is how a vendor silently loses settings
;;; they did set.
;;;
;;; IDEMPOTENT: a vendor already on the new template is reported and skipped, so a re-run changes
;;; nothing. REGISTER IT in `*migrations*` (hhub/core/nst-sch-mig.lisp) — an unregistered upgrade
;;; function never runs.

(in-package :nstores)

(defun migrate-2026Oct-invoice-number-format ()
  "Set `invoice-number-format` to the new series shape in every vendor's stored invoice settings.
   Touches ONE key per blob and leaves every other setting byte-identical."
  (let ((new-template "INV-{prefix}-{fy}-{counter:6}")
        (changed 0) (already 0) (absent 0) (skipped 0))
    (dolist (row (clsql:query "SELECT ROW_ID, INVOICE_SETTINGS FROM DOD_VEND_PROFILE
                                WHERE INVOICE_SETTINGS IS NOT NULL"))
      (let ((vendor-id (first row)) (raw (second row)))
        (if (not (and raw (stringp raw) (plusp (length raw))))
            (incf skipped)
            (handler-case
                (let* ((settings (read-from-string raw))
                       (general (cdr (assoc 'invoice-general-settings settings :test 'equal)))
                       (pair (and general (assoc 'invoice-number-format general))))
                  (cond
                    ((null pair)
                     ;; No stored key: the shipped default already applies, so nothing is stored and
                     ;; nothing is invented. This is the correct outcome for a vendor who never set it.
                     (incf absent)
                     (format t "  vendor ~D: no stored invoice-number-format - shipped default applies~%"
                             vendor-id))
                    ((equal (nst-document-template-value (cdr pair) nil) new-template)
                     (incf already)
                     (format t "  vendor ~D: already on the new template~%" vendor-id))
                    (t
                     (let ((was (nst-document-template-value (cdr pair) "?")))
                       ;; `(list new-template)` restores the SHIPPED two-element shape (key value) — what
                       ;; the reader is built for, and what a JSON round-trip turns back into a dotted
                       ;; pair. It is NOT the same as setting the cdr to the bare string, which would
                       ;; make this blob read differently from a shipped default.
                       (setf (cdr pair) (list new-template))
                       (clsql:execute-command
                        (format nil "UPDATE `DOD_VEND_PROFILE` SET `INVOICE_SETTINGS` = '~A' WHERE `ROW_ID` = ~D"
                                (sql-literal (prin1-to-string settings)) vendor-id))
                       (incf changed)
                       (format t "  vendor ~D: invoice-number-format ~A -> ~A~%" vendor-id was new-template)))))
              (error (c)
                (incf skipped)
                (format t "  ⚠ vendor ~D: stored settings unreadable (~A) - left untouched~%" vendor-id c))))))
    (format t "  invoice-number-format migration: ~D changed, ~D already new, ~D absent, ~D skipped~%"
            changed already absent skipped)))
