;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-vndvpmapi-policy-transaction.lisp
;;;
;;; ABAC policy + transaction seeds for the VENDOR PAYMENT METHODS JSON API
;;; endpoints (hhub/vendor/nst-bl-vndvpmapi.lisp).
;;;
;;; See nst-dbu-warehouse-api-policy-transaction.lisp for why API-path seeds are
;;; separate from the UI-route seeds, and
;;; aiharness/deepseek/skills/knowledge/ABAC-policy-transaction-CONTEXT.md for the traps.
;;;
;;; ⚠ THESE THREE ENDPOINTS CARRY SECRETS. The entity behind them holds the
;;; vendor's payment-gateway API key and salt, and VpmResponseModel deliberately
;;; has no slot for either, so they cannot be published. What that means FOR THESE
;;; POLICIES: the authority question is not only 'may this tenant transact' but
;;; 'should a write to gateway credentials be permitted at all from this channel'.
;;; The policy functions currently answer only the first (the same suspended-tenant
;;; rule as every other endpoint), because the API credential seam does not yet
;;; publish an actor role to decide the second. That is a known gap, not an
;;; oversight — recorded here so the next person does not read these three rows as
;;; stronger protection than they are.
;;;
;;; Register in the *migrations* list in nst-sch-mig.lisp. Idempotent.

(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun migrate-2026Sep-insert-vndvpmapi-policy-and-transactions ()
  "Seed a distinct DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for each vendor
   payment-methods JSON API endpoint. One policy per transaction."
  (let ((tenant-id 1)
        (uri "/hhub/api/v1/vendor/payment/methods"))

    ;; --- CREATE : POST /hhub/api/v1/vendor/payment/methods ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.payment.create"
                      "Create a vendor payment configuration through the JSON API."
                      "com-hhub-policy-api-vendor-payment-create" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.payment.create" uri "CREATE"
       :policy-id policy-id
       :trans-func "api POST /hhub/api/v1/vendor/payment/methods" :tenant-id tenant-id))

    ;; --- READ : GET /hhub/api/v1/vendor/payment/methods/{vendorId} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.payment.read"
                      "Read a vendor payment configuration through the JSON API."
                      "com-hhub-policy-api-vendor-payment-read" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.payment.read" uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/vendor/payment/methods/{vendorId}" :tenant-id tenant-id))

    ;; --- UPDATE : PUT /hhub/api/v1/vendor/payment/methods/{vendorId} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.payment.update"
                      "Update a vendor payment configuration through the JSON API."
                      "com-hhub-policy-api-vendor-payment-update" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.payment.update" uri "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/vendor/payment/methods/{vendorId}" :tenant-id tenant-id))))
