;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-ordapi-policy-transaction.lisp
;;;
;;; ABAC policy + transaction seed rows for the ORDER API's BOUND endpoints (S14):
;;; the seven customer paths (hhub/order/nst-bl-ordhapi.lisp, hhub/order/nst-bl-orditmapi.lisp)
;;; and the three vendor paths (hhub/order/nst-bl-vordhapi.lisp).
;;;
;;; 🚨 THESE ROWS ARE CARRIED, NOT ENFORCED — and that is stated here rather than left for a reader
;;; to discover, because a seeded policy row LOOKS like a control. D18 of the orders batch, which is
;;; D13 of the invoice batch before it:
;;;
;;;   * `:required-roles` / `:feature-flags` / `:audit-level` on every `register-action-route` are
;;;     CARRIED and read by NOTHING;
;;;   * `dispatch-action` passes `trans-func-name` as NIL, so nothing ever looks a transaction up;
;;;   * `*action-route-transaction-function*` is a no-op.
;;;
;;; The effective controls on these endpoints today are tenant scoping, channel narrowing and the
;;; fail-closed 401 that `api-authenticate` answers before any route runs — which is exactly the
;;; mitigating control F3 records, where the unhooked authorization is an ACCEPTED RISK stated in
;;; the standards review rather than a defect of this batch. Seeding the rows NOW is what makes the
;;; endpoint set complete on the day the PEP lands: the alternative is a policy table that has to be
;;; reconstructed endpoint by endpoint from a route registry, which is the work this file does once.
;;;
;;; ── WHAT IT SEEDS, AND THE TWO RULES IT FOLLOWS ─────────────────────────────
;;;
;;; ONE PAIR PER BOUND ENDPOINT — ten pairs, one `insert-auth-policy` and one
;;; `insert-bus-transaction` per endpoint (S14 AC b):
;;;
;;;   customer channel, uri "/hhub/api/v1/orders" (the prefix matches the nested item paths too,
;;;   because / is a boundary character):
;;;     GET    /hhub/api/v1/orders                             READ
;;;     POST   /hhub/api/v1/orders                             CREATE
;;;     GET    /hhub/api/v1/orders/{ordnum}                    READ
;;;     PUT    /hhub/api/v1/orders/{ordnum}                    UPDATE
;;;     DELETE /hhub/api/v1/orders/{ordnum}                    DELETE
;;;     PUT    /hhub/api/v1/orders/{ordnum}/items/{item-id}    UPDATE
;;;     DELETE /hhub/api/v1/orders/{ordnum}/items/{item-id}    DELETE
;;;   vendor channel, uri "/hhub/api/v1/vendor/orders":
;;;     GET    /hhub/api/v1/vendor/orders                      READ
;;;     GET    /hhub/api/v1/vendor/orders/{ordnum}             READ
;;;     PUT    /hhub/api/v1/vendor/orders/{ordnum}             UPDATE
;;;
;;; ⚠ THE TWO ROUTES WITH NO SEED, ON PURPOSE: `route-orditm-list` and `route-orditm-fetch` are
;;; registered action routes with NO binding — the spec publishes no line GET, and the lines reach
;;; the wire through the nested detail array. A transaction row describes an ADDRESSABLE path, so
;;; seeding one for a path that does not exist would invent an endpoint the API refuses.
;;;
;;; ⚠ EACH TRANSACTION LINKS TO ITS OWN POLICY, in the same `let` that created it (S14 AC b). The
;;; helper will happily link a transaction to a policy you name instead — so a copy-paste slip here
;;; would silently give two endpoints ONE policy, and a permission granted for one would apply to
;;; the other. One `let` per pair is the structure that makes that unrepresentable.
;;;
;;; ⚠ AND EVERY ROW NAMES ITS OWN `:trans-func`. `insert-bus-transaction` DEFAULTS it to a string
;;; derived from the trans-TYPE alone ("com-hhub-transaction-" + type), so omitting it would give
;;; every READ endpoint in this file the same key — the transactions are told apart by TRANS_FUNC,
;;; and that is the field a future PEP resolves. The convention here is the tree's own:
;;; "api <METHOD> <full path>", with the template's {ordnum}/{item-id} kept literal.
;;;
;;; ── IDEMPOTENCY (S14 AC a) ──────────────────────────────────────────────────
;;;
;;; Both helpers are idempotent ON NAME: `insert-auth-policy` skips when a policy with that NAME
;;; exists in the tenant and returns its ROW_ID (existing or fresh); `insert-bus-transaction` does
;;; the same for the transaction NAME. Re-running this migration therefore inserts nothing and says
;;; so, per row — which is why it is safe to APPLY, and why a partially-applied run can simply be
;;; repeated. (The version is recorded only on success, so a failure mid-file re-runs the whole
;;; function; every row it already wrote is skipped by name.)
;;;
;;; 🚨 WHY EVERY DESCRIPTION BELOW IS ONE SHORT LINE, AND WHY THAT IS NOT LAZINESS:
;;; DOD_AUTH_POLICY.DESCRIPTION is **varchar(100)** and this database runs **STRICT_TRANS_TABLES**
;;; (measured: `SELECT @@sql_mode`). An over-long value is therefore Error 1406 — NOT a silent
;;; truncation, which is what the ABAC skill §4 used to claim and what the first version of this
;;; file assumed (seven of its ten descriptions were 102-165 characters). The failure mode is worse
;;; than a refused migration: `apply-migrations` catches per-migration and CONTINUES while never
;;; recording the version, so an over-long seed leaves a permanently re-running partial insert.
;;; The longest DESCRIPTION actually stored in the live table is 97 characters, so nothing had ever
;;; probed the limit. THE CONSTRAINTS THE SHORT DESCRIPTIONS no longer spell out live here:
;;;
;;;   * a TERMINAL order (CMP / VCN / CCN) refuses both update and delete — it is a finished
;;;     document, and 387 of the 466 live vendor rows are CMP, so this is the ordinary case;
;;;   * DELETE is refused once the order is placed (PEN) or converted to an invoice;
;;;   * the customer's update cannot write the status, the fulfilment flag or the shipped date
;;;     (internal-only), nor the money, the invoice link or the cancellation state;
;;;   * the VENDOR's update can write exactly four fields — fulfilment, shipped date, comments and a
;;;     tracking URL — and neither the money, the customer's addresses, nor the lifecycle;
;;;   * every read is scoped by tenant, and the vendor channel additionally by the session vendor.
;;;
;;; ⚠ AND EACH POLICY_FUNC BELOW NAMES A FUNCTION THAT EXISTS, in hhub/core/dod-ui-pol.lisp
;;; (group "ORDER API"). That is not decoration: a policy row whose POLICY_FUNC points at nothing
;;; DENIES EVERY CALL on the day the PEP starts consulting it — the ABAC skill's traps 2 and 14, and
;;; the defect this file shipped with for an hour. Before adding a row here, add its function there.
;;;
;;; REGISTER IT in the `*migrations*` list in hhub/core/nst-sch-mig.lisp. Unlike the code files of
;;; this batch, an upgrade file is DELIBERATELY NOT in hhub/package/compile.lisp or hhub/nstores.asd:
;;; `load-upgrade-files` compiles and loads it from disk by name, and the compiler never sees it —
;;; so the reader-balance check in aiharness/deepseek/tools/nst-preflight.lisp is the only
;;; structural check it gets, and this file is listed there for exactly that reason.

(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun migrate-2026Oct-ordapi-policy-and-transactions ()
  "Seed a distinct DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for each BOUND order API endpoint.
   One policy per transaction; idempotent on both names. See the file header for why these rows are
   carried rather than enforced (D18) and for the two rules the structure is built to keep."
  (let ((tenant-id 1)
        (order-uri "/hhub/api/v1/orders")
        (vendor-order-uri "/hhub/api/v1/vendor/orders"))

    ;; ── CUSTOMER CHANNEL ─────────────────────────────────────────────────────

    ;; --- LIST : GET /hhub/api/v1/orders ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.orders.list"
                      "List the session customer's orders through the JSON API."
                      "com-hhub-policy-api-orders-list" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.orders.list" order-uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/orders" :tenant-id tenant-id))

    ;; --- CREATE : POST /hhub/api/v1/orders ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.orders.create"
                      "Place an order for the session's customer, with its lines, via the JSON API."
                      "com-hhub-policy-api-orders-create" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.orders.create" order-uri "CREATE"
       :policy-id policy-id
       :trans-func "api POST /hhub/api/v1/orders" :tenant-id tenant-id))

    ;; --- READ : GET /hhub/api/v1/orders/{ordnum} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.orders.read"
                      "Read one order and its lines, addressed by the customer's order number, through the JSON API."
                      "com-hhub-policy-api-orders-read" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.orders.read" order-uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/orders/{ordnum}" :tenant-id tenant-id))

    ;; --- UPDATE : PUT /hhub/api/v1/orders/{ordnum} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.orders.update"
                      "Update one order's content via the JSON API. A terminal order is refused."
                      "com-hhub-policy-api-orders-update" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.orders.update" order-uri "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/orders/{ordnum}" :tenant-id tenant-id))

    ;; --- DELETE : DELETE /hhub/api/v1/orders/{ordnum} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.orders.delete"
                      "Soft-delete a draft order and its lines via the JSON API."
                      "com-hhub-policy-api-orders-delete" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.orders.delete" order-uri "DELETE"
       :policy-id policy-id
       :trans-func "api DELETE /hhub/api/v1/orders/{ordnum}" :tenant-id tenant-id))

    ;; --- ITEM UPDATE : PUT /hhub/api/v1/orders/{ordnum}/items/{item-id} ---
    ;; Its own policy, deliberately: changing one line of an order is a narrower act than rewriting
    ;; the order, and the {ordnum}/{item-id} pair is verified before anything is written, so a policy
    ;; that permitted this could still refuse the header update.
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.orders.item.update"
                      "Update one order line, by order number and line row-id, via the JSON API."
                      "com-hhub-policy-api-orders-item-update" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.orders.item.update" order-uri "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/orders/{ordnum}/items/{item-id}" :tenant-id tenant-id))

    ;; --- ITEM DELETE : DELETE /hhub/api/v1/orders/{ordnum}/items/{item-id} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.orders.item.delete"
                      "Soft-delete one order line, by order number and line row-id, via the JSON API."
                      "com-hhub-policy-api-orders-item-delete" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.orders.item.delete" order-uri "DELETE"
       :policy-id policy-id
       :trans-func "api DELETE /hhub/api/v1/orders/{ordnum}/items/{item-id}" :tenant-id tenant-id))

    ;; ── VENDOR CHANNEL ───────────────────────────────────────────────────────
    ;;
    ;; A separate resource with its own three endpoints, and the rows are separate from the customer
    ;; channel's for the reason the endpoints are: the vendor reads ONE VENDOR's slice, scoped by the
    ;; session vendor, and a policy that permitted the customer's read must not thereby permit it.

    ;; --- VENDOR LIST : GET /hhub/api/v1/vendor/orders ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.orders.list"
                      "List the session vendor's own order rows through the JSON API (vendor and tenant scoped)."
                      "com-hhub-policy-api-vendor-orders-list" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.orders.list" vendor-order-uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/vendor/orders" :tenant-id tenant-id))

    ;; --- VENDOR READ : GET /hhub/api/v1/vendor/orders/{ordnum} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.orders.read"
                      "Read one vendor order slice, by order number, scoped to the session vendor."
                      "com-hhub-policy-api-vendor-orders-read" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.orders.read" vendor-order-uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/vendor/orders/{ordnum}" :tenant-id tenant-id))

    ;; --- VENDOR UPDATE : PUT /hhub/api/v1/vendor/orders/{ordnum} ---
    ;; The vendor's own four fields only (fulfilment, shipped date, comments, a tracking URL): the
    ;; money, the customer's addresses and the lifecycle are refused by the verb's field policy.
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.vendor.orders.update"
                      "Update the session vendor's slice: fulfilment, shipped date, comments, tracking URL."
                      "com-hhub-policy-api-vendor-orders-update" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.vendor.orders.update" vendor-order-uri "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/vendor/orders/{ordnum}" :tenant-id tenant-id))))
