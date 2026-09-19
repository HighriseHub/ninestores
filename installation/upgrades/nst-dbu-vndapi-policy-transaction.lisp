;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-vndapi-policy-transaction.lisp
;;;
;;; ABAC policy + transaction seeds for the VENDOR PROFILE JSON API endpoints
;;; (hhub/vendor/nst-bl-vndapi.lisp).
;;;
;;; API-path sibling of the UI-route seeds; see
;;; nst-dbu-warehouse-api-policy-transaction.lisp for the full explanation of why
;;; the two exist side by side, and
;;; aiharness/deepseek/skills/ABAC-policy-transaction-CONTEXT.md for the traps.
;;;
;;; Register in the *migrations* list in nst-sch-mig.lisp. Idempotent.

(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun migrate-2026Sep-insert-vndapi-policy-and-transactions ()
  "Seed a distinct DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for each vendor
   profile JSON API endpoint. One policy per transaction."
  (let ((tenant-id 1)
        (uri "/hhub/api/v1/vendor/profile"))

    ;; --- LIST : GET /hhub/api/v1/vendor/profile ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.profile.list"
                      "List vendor profiles for the session tenant through the JSON API."
                      "com-hhub-policy-api-vendor-profile-list" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.profile.list" uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/vendor/profile" :tenant-id tenant-id))

    ;; --- CREATE : POST /hhub/api/v1/vendor/profile ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.profile.create"
                      "Register a vendor for the session tenant through the JSON API."
                      "com-hhub-policy-api-vendor-profile-create" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.profile.create" uri "CREATE"
       :policy-id policy-id
       :trans-func "api POST /hhub/api/v1/vendor/profile" :tenant-id tenant-id))

    ;; --- READ : GET /hhub/api/v1/vendor/profile/{id} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.profile.read"
                      "Read one vendor profile by row-id through the JSON API."
                      "com-hhub-policy-api-vendor-profile-read" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.profile.read" uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/vendor/profile/{id}" :tenant-id tenant-id))

    ;; --- UPDATE : PUT /hhub/api/v1/vendor/profile/{id} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.profile.update"
                      "Update a vendor profile by row-id through the JSON API."
                      "com-hhub-policy-api-vendor-profile-update" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.profile.update" uri "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/vendor/profile/{id}" :tenant-id tenant-id))

    ;; --- DELETE : DELETE /hhub/api/v1/vendor/profile/{id} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.profile.delete"
                      "Soft-delete a vendor profile by row-id through the JSON API."
                      "com-hhub-policy-api-vendor-profile-delete" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.profile.delete" uri "DELETE"
       :policy-id policy-id
       :trans-func "api DELETE /hhub/api/v1/vendor/profile/{id}" :tenant-id tenant-id))))
