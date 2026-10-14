;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-cusinv-policy-transaction.lisp
;;;
;;; Customer-invoice-register ABAC policy + transaction seed migration.
;;;
;;; The reusable insert helpers (auth-policy-inserted-p, bus-transaction-inserted-p,
;;; auth-policy-id-by-name, insert-auth-policy, insert-bus-transaction) live in
;;; hhub/core/nst-sch-mig.lisp. This file contains only the register-page seed.
;;;
;;; Register this migration in the *migrations* list in nst-sch-mig.lisp and it
;;; will be applied once to every DB that runs (apply-migrations user pass).

;;; ── WHY THIS FILE EXISTS ─────────────────────────────────────────────────────
;;; The pair for ^/hhub/nstcustinvoices was inserted BY HAND on 2026-05-18 (rows 49
;;; and 70, beside commit 5996ef2) and no migration ever seeded it, so the pair lives
;;; on exactly one database. A rebuilt or restored DB silently loses the page:
;;; with-hhub-transaction finds no row and raises
;;;   "Did not find transaction com-hhub-transaction-customer-invoices-listpage."
;;; which is a 500 on the register, not a permission deny — the row's ABSENCE, not a
;;; policy verdict, is what stopped the page on 2026-10-14.
;;;
;;; The values below are the live row's values copied field for field, so a fresh DB
;;; gets the SAME pair instead of a near-duplicate. TRANS_FUNC is the lookup key (the
;;; boot-time cache is a hashtable on it, dod-bl-bo.lisp:91) while NAME is only what
;;; the seed helpers deduplicate on, so both must stay exactly as they are.

(in-package :nstores)

(defun migrate-2026Oct-cusinv-listpage-policy-and-transaction ()
  "Seed the DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for the customer invoice
   register (/hhub/nstcustinvoices -> com-hhub-transaction-customer-invoice-register-page).
   The :policy-id of the freshly inserted policy is captured explicitly and passed to
   :policy-id on insert-bus-transaction, so this transaction is linked to its OWN policy,
   never a shared one. Idempotent - safe to rerun."
  (let* ((tenant-id 1)
         (policy-id
           (insert-auth-policy
            "com.hhub.policy.customer.invoices.listpage"
            "Display a list of invoices for a given customer"
            "com-hhub-policy-customer-invoices-listpage"
            :tenant-id tenant-id)))
    (insert-bus-transaction
     "com.hhub.transaction.customer.invoices.listpage"
     "/hhub/nstcustinvoices"
     "READ"
     :policy-id policy-id
     :trans-func "com-hhub-transaction-customer-invoices-listpage"
     :tenant-id tenant-id)))
