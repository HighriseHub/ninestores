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
