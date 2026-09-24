;;; nst-dbu-invoicesettings.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
;;;
;;; Backfill DOD_VEND_PROFILE.INVOICE_SETTINGS — the TEXT column that holds a vendor's
;;; invoice settings as a *printed alist* (see the invoice-settings slot in
;;; vendor/dod-dal-ven.lisp).
;;;
;;; WHY THIS IS NEEDED. The column is only ever written when a vendor saves the invoice
;;; settings page, so every vendor that predates that page has nothing in it: 10 rows are
;;; NULL and 4 hold clsql's void value "undefined" (the DAL declares :void-value
;;; "undefined", so a NULL comes back as that string). Anything that treats the column as
;;; "a saved alist" fails on those rows — read-from-string of "undefined" yields the symbol
;;; UNDEFINED, and the next (assoc 'invoice-print-settings …) is a type error.
;;;
;;; WHERE THE SEED COMES FROM. The shipped defaults, *invoice-settings* in
;;; invoice/templates/invoicesettings.lisp, which is loaded in every image (it is in
;;; package/compile.lisp): the seed is that alist with its print section replaced by the
;;; keyword shape a settings save writes — the shape the settings form and the invoice
;;; renderers read, and the shape the one populated row (vendor 1) has. Taking the rest
;;; from *invoice-settings* means a section added to the shipped defaults later is carried
;;; into the backfill automatically.
;;;
;;; The print section itself is *not* copied from the shipped alist, because two of its
;;; literals are not usable as they stand: orientation "portrait" does not match the
;;; settings form's Portrait/Landscape options, and the logo path /assets/logo.png does not
;;; exist on the deployed site. The values below are the working ones — template 13 (the
;;; system default GST template), A4, Portrait, 12, 1cm margins, header and footer enabled
;;; with the shipped texts, the site logo at /img/logo.png, watermark disabled.
;;;
;;; IDEMPOTENT. Only rows whose value is NULL, empty or "undefined" are touched, and the
;;; WHERE clause repeats that test, so a second run updates nothing.

(in-package :nstores)

(defparameter *nst-invoicesettings-print-defaults*
  '((:defaultinvoicetemplatenum . "13")
    (:defaultpapersize . "A4")
    (:orientation . "Portrait")
    (:fontsize . "12")
    (:margin (:top . "1cm") (:bottom . "1cm") (:left . "1cm") (:right . "1cm"))
    (:header (:enable . t)
	     (:text . "Company Name - Invoice")
	     (:logopath . "/img/logo.png"))
    (:footer (:enable . t)
	     (:text . "Thank you for your business!"))
    (:watermark (:enable . nil)
		(:text . "")))
  "The invoice print settings a vendor is seeded with, in the keyword shape a settings save writes.")

(defun nst-invoicesettings-seed ()
  :documentation "The settings a vendor is seeded with : the shipped *invoice-settings* with its print section replaced by *nst-invoicesettings-print-defaults*. A fresh copy is returned every call, so neither the global default nor a caller can affect another run. When the shipped defaults are not loaded (this file is also usable on its own) the print settings alone are seeded."
  (let ((shipped (and (boundp '*invoice-settings*)
		      (listp *invoice-settings*)
		      (copy-tree *invoice-settings*))))
    (if shipped
	(progn
	  (let ((printsection (assoc 'invoice-print-settings shipped :test #'equal)))
	    (if printsection
		(setf (cdr printsection) (copy-tree *nst-invoicesettings-print-defaults*))
		;; else the shipped alist carries no print section
		(push (cons 'invoice-print-settings
			    (copy-tree *nst-invoicesettings-print-defaults*))
		      shipped)))
	  shipped)
	;; else the shipped defaults are not in this image : seed the print settings alone
	(list (cons 'invoice-print-settings (copy-tree *nst-invoicesettings-print-defaults*))))))

(defun nst-invoicesettings-seed-string ()
  :documentation "The seed as the printed alist stored in INVOICE_SETTINGS : readable back with read-from-string, which is how the application reads the column. The symbols are printed fully qualified by binding *package* to :keyword, so the string means the same thing whatever package reads it. That matters : the settings page looks the top-level sections up with (assoc 'invoice-print-settings … :test #'equal), and a bare symbol read in another package would intern as a different symbol and never match. It is also what a settings save from the application writes, so a migrated row and a saved row have the same shape."
  (let ((*package* (find-package :keyword)))   ;; force COM.NSTORES.APP:: style qualification
    (write-to-string (nst-invoicesettings-seed) :readably t)))

(defun nst-vendors-missing-invoicesettings ()
  :documentation "ROW_IDs of the vendors whose INVOICE_SETTINGS holds no settings : NULL, empty, or clsql's void value for a NULL column."
  (mapcar #'first
	  (clsql:query "SELECT ROW_ID FROM DOD_VEND_PROFILE
                        WHERE INVOICE_SETTINGS IS NULL
                           OR INVOICE_SETTINGS = ''
                           OR INVOICE_SETTINGS = 'undefined'
                        ORDER BY ROW_ID"
		       :database *dod-db-instance*)))

(defun migrate-2026Sep-backfill-vendor-invoice-settings ()
  :documentation "Give every vendor that has no invoice settings the default ones. Idempotent : the WHERE clause refuses to overwrite a row that already holds a value, so re-running updates nothing."
  (if (not (column-exists-p "DOD_VEND_PROFILE" "INVOICE_SETTINGS"))
      (format t "~&DOD_VEND_PROFILE.INVOICE_SETTINGS does not exist, nothing to backfill.~%")
      ;; else
      (let ((seed (sql-literal (nst-invoicesettings-seed-string)))
	    (missing (nst-vendors-missing-invoicesettings)))
	(format t "~&INVOICE_SETTINGS backfill : ~D vendor(s) without settings : ~{~A~^, ~}~%"
		(length missing) missing)
	(dolist (vendor-id missing)
	  (clsql:execute-command
	   (format nil "UPDATE DOD_VEND_PROFILE
                           SET INVOICE_SETTINGS = '~A'
                         WHERE ROW_ID = '~A'
                           AND (INVOICE_SETTINGS IS NULL
                                OR INVOICE_SETTINGS = ''
                                OR INVOICE_SETTINGS = 'undefined')"
		   seed vendor-id)
	   :database *dod-db-instance*))
	(let ((remaining (nst-vendors-missing-invoicesettings)))
	  (format t "~&INVOICE_SETTINGS backfill : ~D row(s) updated, ~D still without settings.~%"
		  (- (length missing) (length remaining)) (length remaining))))))
