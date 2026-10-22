;;; nst-dbu-customer-approval.lisp — the B2B buyer approval gate (C1–C4), 2026-10.
;;; Backfill is load-bearing: every existing buyer is N/PENDING and would be locked out.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun migrate-2026Oct-customer-approval ()
  "Add REJECTION_REASON and approve every pre-gate STANDARD buyer, so the new login gate strands nobody."
  (add-column-if-absent "DOD_CUST_PROFILE" "REJECTION_REASON" "varchar(500) DEFAULT NULL")
  (clsql:execute-command
   "UPDATE DOD_CUST_PROFILE SET APPROVED_FLAG='Y', APPROVAL_STATUS='APPROVED'
      WHERE CUST_TYPE='STANDARD' AND APPROVAL_STATUS='PENDING'"
   :database *dod-db-instance*))
