;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-invoice-number-format.lisp — point every vendor's STORED invoice-number template at the new
;;; series, because a stored setting beats the shipped default and every blob still holds the old shape.
;;; Separate from nst-dbu-invoice-numbering.lisp ON PURPOSE: that version is already applied and
;;; `apply-migrations` skips recorded versions, so a step added to it would look shipped and never run.
;;; The blob is PARSED and re-printed (never REPLACE()d, which could hit a matching footer string), the
;;; write goes through `sql-literal` (apostrophes, Error 1064), and an unparseable blob is left alone.
;;; Full reasoning: aiharness/deepseek/skills/PENDING-WORK-CONTEXT.md §18 (US-015).

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
