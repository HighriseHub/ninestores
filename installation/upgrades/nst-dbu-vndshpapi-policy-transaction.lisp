;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-vndshpapi-policy-transaction.lisp
;;;
;;; ABAC policy + transaction seeds for the VENDOR SHIPPING JSON API endpoints
;;; (hhub/vendor/nst-bl-vndshpapi.lisp).
;;;
;;; See nst-dbu-warehouse-api-policy-transaction.lisp for why API-path seeds are
;;; separate from the UI-route seeds, and
;;; aiharness/deepseek/skills/ABAC-policy-transaction-CONTEXT.md for the traps.
;;;
;;; NOTE the URI is the same prefix for all six endpoints even though they span
;;; three distinct resources (the configuration, its rate table and its zones):
;;; "/hhub/api/v1/vendor/shipping" prefix-matches "/…/shipping/{vendorId}/zones"
;;; because / is a boundary character. The transactions are told apart by
;;; TRANS_FUNC, which is unique per endpoint.
;;;
;;; Register in the *migrations* list in nst-sch-mig.lisp. Idempotent.

(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun migrate-2026Sep-insert-vndshpapi-policy-and-transactions ()
  "Seed a distinct DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for each vendor
   shipping JSON API endpoint. One policy per transaction."
  (let ((tenant-id 1)
        (uri "/hhub/api/v1/vendor/shipping"))

    ;; --- LIST : GET /hhub/api/v1/vendor/shipping ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.shipping.list"
                      "List vendor shipping configurations through the JSON API."
                      "com-hhub-policy-api-vendor-shipping-list" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.shipping.list" uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/vendor/shipping" :tenant-id tenant-id))

    ;; --- CREATE : POST /hhub/api/v1/vendor/shipping ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.shipping.create"
                      "Create a vendor shipping configuration through the JSON API."
                      "com-hhub-policy-api-vendor-shipping-create" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.shipping.create" uri "CREATE"
       :policy-id policy-id
       :trans-func "api POST /hhub/api/v1/vendor/shipping" :tenant-id tenant-id))

    ;; --- READ : GET /hhub/api/v1/vendor/shipping/{vendorId} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.shipping.read"
                      "Read the shipping configuration of a vendor through the JSON API."
                      "com-hhub-policy-api-vendor-shipping-read" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.shipping.read" uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/vendor/shipping/{vendorId}" :tenant-id tenant-id))

    ;; --- UPDATE : PUT /hhub/api/v1/vendor/shipping/{vendorId} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.shipping.update"
                      "Update the shipping configuration of a vendor through the JSON API."
                      "com-hhub-policy-api-vendor-shipping-update" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.shipping.update" uri "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/vendor/shipping/{vendorId}" :tenant-id tenant-id))

    ;; --- UPLOAD RATE TABLE : PUT …/{vendorId}/rate-table ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.shipping.ratetable"
                      "Upload a vendor shipping rate table and its zones via the JSON API."
                      "com-hhub-policy-api-vendor-shipping-ratetable" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.shipping.ratetable" uri "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/vendor/shipping/{vendorId}/rate-table" :tenant-id tenant-id))

    ;; --- UPLOAD ZONES : PUT …/{vendorId}/zones ---
    ;; Its own transaction, deliberately. The UI cannot express a zones-only
    ;; change (its upload form submits both files), so this endpoint is ADDITIVE
    ;; to the UI surface (nst-bl-vndshpapi.lisp header). Giving it its own
    ;; transaction lets a policy permit the narrow change while refusing the
    ;; broader one.
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.shipping.zones"
                      "Upload a vendor shipping zone rows alone through the JSON API."
                      "com-hhub-policy-api-vendor-shipping-zones" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.shipping.zones" uri "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/vendor/shipping/{vendorId}/zones" :tenant-id tenant-id))))
