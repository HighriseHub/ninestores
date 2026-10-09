;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-order-policy-transaction.lisp
;;;
;;; Order-domain ABAC policy + transaction seed migrations.
;;;
;;; The reusable insert helpers (auth-policy-inserted-p, bus-transaction-inserted-p,
;;; auth-policy-id-by-name, insert-auth-policy, insert-bus-transaction) live in
;;; hhub/core/nst-sch-mig.lisp. This file only contains the order endpoint seeds
;;; that use them.
;;;
;;; Register this migration in the *migrations* list in nst-sch-mig.lisp and it
;;; will be applied once to every DB that runs (apply-migrations user pass).

(in-package :nstores)

(defun migrate-2026Sep-insert-vendor-order-cancel-policy-and-transaction ()
  "Seed the DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for the vendor
   order-cancel endpoint (login vendor cancels its share and the whole
   customer order, status VCN).

   The :policy-id of the freshly inserted policy is captured explicitly and
   passed to :policy-id on insert-bus-transaction, so each transaction is
   linked to its OWN unique governing policy (never shared).
   Idempotent - safe to rerun."
  (let* ((tenant-id 1)
        (policy-id
          (insert-auth-policy
           "com.hhub.policy.vendor.order.cancel"
           "Vendor cancels an order and sets it to VCN."
           "com-hhub-policy-vendor-order-cancel"
           :tenant-id tenant-id)))
    (insert-bus-transaction
     "com.hhub.transaction.vendor.order.cancel"
     "/hhub/dodvenordcancel"
     "UPDATE"
     :policy-id policy-id
     :trans-func "com-hhub-transaction-vendor-order-cancel"
     :tenant-id tenant-id)))


;;; The vendor's *Generate Invoice* — vendor/dod-ui-ven.lisp → com-hhub-transaction-vendor-order-invoice.
;;; CREATE, not UPDATE: the action brings a NEW DOCUMENT into existence (a DRAFT invoice) and writes
;;; the order's invoice link; TRANS_TYPE is what a future PEP reads. ⚠ POLICY_FUNC must name a
;;; function that EXISTS — com-hhub-policy-vendor-order-invoice in hhub/core/dod-ui-pol.lisp — or the
;;; row denies every call once the PEP lands. DESCRIPTION is one short line because
;;; DOD_AUTH_POLICY.DESCRIPTION is varchar(100) under STRICT_TRANS_TABLES (Error 1406 otherwise).
;;; Whether THIS order may be invoiced (व्यंजन — fulfilment — against लोप ३ for a service order, and
;;; the one-order-one-invoice rule) is the junction's own, in the invoice domain, and is deliberately
;;; not restated as a policy.
(defun migrate-2026Oct-ordinvoice-policy-and-transaction ()
  "Seed the DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for the vendor's Generate Invoice action
   (/hhub/dodvenordinvoice: a DRAFT invoice built from the order's own lines).
   The :policy-id is captured explicitly and passed to :policy-id, so this transaction is linked to
   its OWN policy, never a shared one. Idempotent - safe to rerun."
  (let* ((tenant-id 1)
        (policy-id
          (insert-auth-policy
           "com.hhub.policy.vendor.order.invoice"
           "A vendor generates a DRAFT invoice from an order, on a non-suspended account."
           "com-hhub-policy-vendor-order-invoice"
           :tenant-id tenant-id)))
    (insert-bus-transaction
     "com.hhub.transaction.vendor.order.invoice"
     "/hhub/dodvenordinvoice"
     "CREATE"
     :policy-id policy-id
     :trans-func "com-hhub-transaction-vendor-order-invoice"
     :tenant-id tenant-id)))

