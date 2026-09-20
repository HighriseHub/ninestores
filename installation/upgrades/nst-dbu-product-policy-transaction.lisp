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


;;; ═══════════════════════════════════════════════════════════════════════════
;;; PRICING — a SECOND migration, deliberately, not another block above
;;;
;;; migrate-2026Sep-insert-product-api-policy-and-transactions was APPLIED AND
;;; RECORDED on 2026-09-19, and apply-migrations never re-runs a version it has
;;; already recorded. Appending a pricing block to it would be a silent no-op:
;;; the row would exist in the source and never in the database — the worst of
;;; both, because the file would read as covered.
;;;
;;; The pricing route was bound on 2026-09-20, after that migration was written,
;;; so it gets its own version. The insert helpers are idempotent, which is what
;;; makes a second migration over the same two tables safe.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun migrate-2026Sep-insert-product-pricing-policy-and-transaction ()
  "Seed the DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for the product PRICING
   endpoint — the one catalog endpoint whose कर्म is an ENTITY OF ITS OWN
   (nst-prd-pricing) rather than a field group on the product row.

   WHAT BREAKS WITHOUT IT. with-hhub-transaction looks a transaction up by
   TRANS_FUNC, and the value it looks up is the literal string apidefs2 builds in
   api-run-route — (format nil \"api ~A ~A\" method path) — so the row key here is
   \"api PUT /hhub/api/v1/catalog/products/{id}/pricing\". The seam that performs
   that lookup (*action-route-transaction-function*, nst-bl-conflodis2.lisp:258-265)
   is a pass-through stub today, so NO api row enforces anything yet. But the day
   it is bound, every sibling endpoint resolves its row and pricing would fail
   closed on a missing one — a 403 on a working endpoint, for a reason that lives
   in the database rather than the code.

   THE URI IS THE COLLECTION PREFIX, not the full template, for the reason the
   header of this file gives: it is a literal prefix guard, and a stored
   \".../products/{id}/pricing\" would never match a request URI containing /42/.
   The TRANS_FUNC is what identifies the endpoint.
   Idempotent - safe to rerun."
  (let ((tenant-id 1))

    ;; --- PRICING : PUT /hhub/api/v1/catalog/products/{id}/pricing ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.product.update.pricing"
             "Set the price, discount and discount window of a product through the JSON API."
             "com-hhub-policy-api-product-update-pricing"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.product.update.pricing"
       "/hhub/api/v1/catalog/products"
       "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/catalog/products/{id}/pricing"
       :tenant-id tenant-id))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; STATUS — the THIRD migration, for the same reason as the second
;;;
;;; Both earlier versions are applied and recorded, and apply-migrations never
;;; re-runs a recorded version. The status endpoint was bound on 2026-09-20,
;;; after BOTH of them (19092026 and 20092026-…-pricing-policies), so it needs
;;; its own. Appending a block above would be the silent no-op this file's
;;; pricing section already warns about.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun migrate-2026Sep-insert-product-status-policy-and-transaction ()
  "Seed the DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for the product STATUS
   endpoint — Turn On / Turn Off, a constrained !update on `active_flag`.

   This is the endpoint whose TRANS_FUNC string must be checked most carefully of
   the three product sub-resources, because its address is the longest and the one
   a hurried edit is most likely to get wrong: the row is keyed on the literal
   \"api PUT /hhub/api/v1/catalog/products/{id}/status\" (48 chars), and
   with-hhub-transaction will fail closed on a mismatch rather than complain. The
   §10 verification snippet in ABAC-policy-transaction-CONTEXT.md exists for
   exactly this and reports EXACT or MISMATCH.

   NOTE WHAT STATUS IS NOT: it is not a delist. `inactive` writes active_flag='N'
   and nothing else, exactly as deactivate-product did (dod-bl-prd.lisp:27). The
   policy therefore guards a VISIBILITY toggle, not an approval decision — if
   delisting ever needs its own authority, that is a separate transaction and a
   separate policy, not a broader meaning for this one.

   THE URI IS THE COLLECTION PREFIX, per this file's header: it is a literal
   prefix guard, so a stored \".../{id}/status\" would never match a request URI
   containing /42/. TRANS_FUNC is what identifies the endpoint.
   Idempotent - safe to rerun."
  (let ((tenant-id 1))

    ;; --- STATUS : PUT /hhub/api/v1/catalog/products/{id}/status ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.product.update.status"
             "Turn a product on or off (its active flag) through the JSON API."
             "com-hhub-policy-api-product-update-status"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.product.update.status"
       "/hhub/api/v1/catalog/products"
       "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/catalog/products/{id}/status"
       :tenant-id tenant-id))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; COPY — the FOURTH migration, and why it could not join the third
;;;
;;; migrate-2026Sep-insert-product-status-policy-and-transaction was APPLIED AND
;;; RECORDED at 2026-09-20 19:17:15 (DOD_SCHEMA_MIGRATIONS row 102). Appending a
;;; COPY block to it would therefore be a SILENT NO-OP: the rows would exist in
;;; this file and never in the database, and the file would read as covered.
;;;
;;; That is the whole reason this file has four migrations for one domain rather
;;; than one. It is not bookkeeping — apply-migrations is version-keyed, and the
;;; version is the unit of "has this already happened".
;;; ═══════════════════════════════════════════════════════════════════════════

(defun migrate-2026Sep-insert-product-copy-policy-and-transaction ()
  "Seed the DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for product COPY.

   THIS IS THE PRODUCT POLICY MOST WORTH HAVING ITS OWN, and the reason is not
   bookkeeping. Copy is the only catalog write that CREATES ANOTHER ROW rather than
   changing one, and the row it creates is a new sellable listing. A tenant that
   trusts a vendor to edit prices but not to manufacture listings can grant
   product.update and withhold product.copy — an authority split that is impossible
   if the two share a policy function.

   WHAT IT DOES NOT DO: copying does NOT inherit approval (prd-copy-initargs omits
   the approval initargs so make's defaults apply, leaving the copy PENDING). So this
   policy does not let anyone publish; it lets them PROPOSE. The approval gate the
   catalog already has is what admits the new listing to the storefront.

   THE URI IS THE COLLECTION PREFIX, per this file's header — a literal prefix guard,
   so a stored \".../{id}/copy\" would never match a request URI containing /42/.
   TRANS_FUNC is what identifies the endpoint, and it is checked by the §10 snippet
   in ABAC-policy-transaction-CONTEXT.md rather than by eye.
   Idempotent - safe to rerun."
  (let ((tenant-id 1))

    ;; --- COPY : POST /hhub/api/v1/catalog/products/{id}/copy ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.product.copy"
             "Duplicate a product as a new listing through the JSON API."
             "com-hhub-policy-api-product-copy"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.product.copy"
       "/hhub/api/v1/catalog/products"
       "CREATE"
       :policy-id policy-id
       :trans-func "api POST /hhub/api/v1/catalog/products/{id}/copy"
       :tenant-id tenant-id))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; THE BULK PAIR — the FIFTH migration
;;;
;;; Same rule as the fourth, and this is now the third time in one day it has
;;; applied: the version is the unit of "has this already happened", and every
;;; earlier version was applied before this endpoint existed. The copy migration
;;; (20092026-insert-product-copy-policy) was recorded too, so appending here would
;;; be the silent no-op this file keeps warning about.
;;;
;;; It is also the clearest illustration of why the one-migration-per-day cadence
;;; exists: five versions for one domain in one day is what happens when each
;;; endpoint is applied as it lands rather than batched to the day's end.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun migrate-2026Sep-insert-product-bulk-policies-and-transactions ()
  "Seed the DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pairs for the bulk products.csv
   PAIR — the template download and the upload that consumes it.

   BOTH, IN ONE MIGRATION, because they are one round trip and neither is usable
   alone: the template emits exactly the file the upload parses, down to the MD5
   digest in column 10. They still get SEPARATE policies (one READ, one CREATE) so a
   tenant can grant the download without the upload — but one migration, which is
   also the one-migration-per-day cadence doing its job: this version has not been
   applied yet, so the second endpoint could still join it.

   THE POLICY FUNCTION IS A NEW ONE, and it deliberately does NOT reuse
   com-hhub-policy-vendor-bulk-product-add even though that is the legacy endpoint's
   policy and covers the same feature. Two reasons, both concrete:

     * that function reads its params as an ALIST with string keys and looks up a
       \\"prdcount\\" the UI computed before calling it; the API hands a policy a PLIST
       from the ferry and has no pre-parsed count. It would read a NIL company and
       RETURN T — an authorization check that silently permits, which is the worst
       possible failure for one.

     * the TRANSACTION→POLICY pairing is one-to-one by design (see the ABAC skill
       §2). Two endpoints — the vendor page and the API — with different transports
       and different row-count sources should not share one governing policy, because
       they can then never diverge in what they permit.

   TRANS_TYPE is CREATE: the upload writes rows, and a bulk update of existing
   products is still a create-or-replace from the caller's point of view.

   THE URI IS THE COLLECTION PREFIX, per this file's header. Note the address has no
   {id} — the upload is a collection-level write, which is why it is
   /catalog/products/bulk and not /catalog/products/{id}/anything.
   Idempotent - safe to rerun."
  (let ((tenant-id 1))

    ;; --- BULK UPLOAD : POST /hhub/api/v1/catalog/products/bulk ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.product.bulk.upload"
             "Upload many products from a products.csv through the JSON API."
             "com-hhub-policy-api-product-bulk-upload"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.product.bulk.upload"
       "/hhub/api/v1/catalog/products"
       "CREATE"
       :policy-id policy-id
       :trans-func "api POST /hhub/api/v1/catalog/products/bulk"
       :tenant-id tenant-id)))

    ;; --- TEMPLATE : GET /hhub/api/v1/catalog/products/template ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.api.product.template"
             "Download the catalogue as a products.csv template through the JSON API."
             "com-hhub-policy-api-product-template"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.product.template"
       "/hhub/api/v1/catalog/products"
       "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/catalog/products/template"
       :tenant-id tenant-id)))
