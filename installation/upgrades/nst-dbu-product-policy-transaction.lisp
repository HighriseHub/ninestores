;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-product-policy-transaction.lisp
;;;
;;; Product/catalog-domain ABAC policy + transaction seed migrations.
;;;
;;; The reusable insert helpers (auth-policy-inserted-p, bus-transaction-inserted-p,
;;; auth-policy-id-by-name, insert-auth-policy, insert-bus-transaction) live in
;;; hhub/core/nst-sch-mig.lisp. This file only contains the product endpoint seeds
;;; that use them.
;;;
;;; Register this migration in the *migrations* list in nst-sch-mig.lisp and it
;;; will be applied once to every DB that runs (apply-migrations user pass).
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHY THESE ROWS LOOK DIFFERENT FROM THE WAREHOUSE ONES
;;;
;;; The warehouse file (nst-dbu-warehouse-policy-transaction.lisp) seeds UI routes:
;;; URI "/hhub/vwarehouses", TRANS_FUNC "com-hhub-transaction-create-warehouse-action"
;;; — i.e. the name of the CONTROLLER, because with-hhub-transaction is called by
;;; that controller and looks the transaction up by TRANS_FUNC.
;;;
;;; AN API ENDPOINT HAS NO CONTROLLER. The whole surface shares one handler,
;;; com-hhub-api-dispatch, so there is no function name to key on. What the API does
;;; have is the string apidefs2 already builds for exactly this purpose
;;; (nst-bl-apidefs2.lisp, api-run-route):
;;;
;;;     :trans-func-name (format nil "api ~A ~A" (api-route-method route)
;;;                                              (api-route-path route))
;;;
;;; so TRANS_FUNC below is that literal string — "api PUT /hhub/api/v1/catalog/products/{id}"
;;; — and it is the key the seam looks up. Nothing had to be invented, and nothing
;;; in apidefs2 needs changing to make the lookup find these rows.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THE URI IS A PREFIX GUARD, NOT AN ADDRESS
;;;
;;; with-hhub-transaction verifies the DB URI against the request URI using
;;; uri-prefix-boundary-p (core/dod-bl-utl.lisp:22), which is LITERAL PREFIX
;;; matching with / ? # ; as boundary characters. A stored URI of
;;; "/hhub/api/v1/catalog/products" therefore matches a request for
;;; "/hhub/api/v1/catalog/products/42" — the next character is "/", a boundary.
;;;
;;; THAT IS WHY EVERY ROW HERE STORES THE COLLECTION PREFIX and none stores the
;;; "{id}" template: "{id}" is a template, not a string a request URI ever
;;; contains, so a stored URI of "/hhub/api/v1/catalog/products/{id}/shipping"
;;; would never match "/hhub/api/v1/catalog/products/42/shipping" and every
;;; shipping call would fail closed with a URI-mismatch deny. The row is
;;; identified by its TRANS_FUNC (unique per endpoint); the URI only proves the
;;; request is aimed at the resource the transaction claims to guard.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; 🚨 WHAT THIS MIGRATION DOES **NOT** ACHIEVE
;;;
;;; Adding these rows does not, on its own, enforce anything on the API path.
;;; nst-bl-conflodis2.lisp SECTION 5 defines the seam
;;; (*action-route-transaction-function* / call-with-action-transaction) as a stub
;;; that runs the verb UNWRAPPED, and it is never rebound anywhere in the tree;
;;; dispatch-route2 additionally accepts :trans-func-name and drops it, and
;;; dispatch-action passes a literal NIL into the seam. Until that seam is bound
;;; to a function that runs the thunk inside with-hhub-transaction — building the
;;; "uri" and "company" params these policies read — these rows are inert for the
;;; API. They are currently LIVE for the UI path, which calls the macro directly.
;;;
;;; They are seeded anyway, and deliberately: the policy/transaction pairs are
;;; business data whose shape does not depend on when the seam lands, seeding them
;;; now keeps the API and UI naming conventions in one place, and doing it later
;;; would mean re-deriving every name from the route table.

(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun migrate-2026Sep-insert-product-api-policy-and-transactions ()
  "Seed a distinct DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for each published
   catalog/product API endpoint. One policy per transaction.

   The :policy-id of the freshly inserted policy is captured explicitly and
   passed to :policy-id on insert-bus-transaction, so each transaction is
   linked to its OWN unique governing policy (never shared) — the same rule the
   warehouse and order migrations follow.
   Idempotent - safe to rerun."
  (let ((tenant-id 1))

    ;; --- LIST : GET /hhub/api/v1/catalog/products ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.product.list"
             "List the catalog of the session tenant through the JSON API."
             "com-hhub-policy-api-product-list"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.product.list"
       "/hhub/api/v1/catalog/products"
       "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/catalog/products"
       :tenant-id tenant-id))

    ;; --- CREATE : POST /hhub/api/v1/catalog/products ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.product.create"
             "Create a product for the session tenant through the JSON API."
             "com-hhub-policy-api-product-create"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.product.create"
       "/hhub/api/v1/catalog/products"
       "CREATE"
       :policy-id policy-id
       :trans-func "api POST /hhub/api/v1/catalog/products"
       :tenant-id tenant-id))

    ;; --- READ : GET /hhub/api/v1/catalog/products/{id} ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.product.read"
             "Read one product by row-id through the JSON API."
             "com-hhub-policy-api-product-read"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.product.read"
       "/hhub/api/v1/catalog/products"
       "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/catalog/products/{id}"
       :tenant-id tenant-id))

    ;; --- UPDATE : PUT /hhub/api/v1/catalog/products/{id} ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.product.update"
             "Partially update a product by row-id through the JSON API."
             "com-hhub-policy-api-product-update"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.product.update"
       "/hhub/api/v1/catalog/products"
       "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/catalog/products/{id}"
       :tenant-id tenant-id))

    ;; --- DELETE : DELETE /hhub/api/v1/catalog/products/{id} ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.product.delete"
             "Soft-delete a product by row-id through the JSON API."
             "com-hhub-policy-api-product-delete"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.product.delete"
       "/hhub/api/v1/catalog/products"
       "DELETE"
       :policy-id policy-id
       :trans-func "api DELETE /hhub/api/v1/catalog/products/{id}"
       :tenant-id tenant-id))

    ;; --- SHIPPING : PUT /hhub/api/v1/catalog/products/{id}/shipping ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.product.update.shipping"
             "Set the shipping dimensions and weight of a product through the JSON API."
             "com-hhub-policy-api-product-update-shipping"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.product.update.shipping"
       "/hhub/api/v1/catalog/products"
       "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/catalog/products/{id}/shipping"
       :tenant-id tenant-id))))
