;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-warehouse-api-policy-transaction.lisp
;;;
;;; ABAC policy + transaction seeds for the WAREHOUSE JSON API endpoints.
;;;
;;; Sibling of nst-dbu-warehouse-policy-transaction.lisp, which seeds the same
;;; domain's UI ROUTES (/hhub/vwarehouses, /hhub/vcreatewarehouseaction, …).
;;; The two files coexist because a UI route and an API endpoint are DIFFERENT
;;; transactions with different TRANS_FUNC keys — the UI keys on the controller
;;; function name, the API on the string apidefs2 builds ("api GET /hhub/api/v1/…").
;;;
;;; The reusable insert helpers live in hhub/core/nst-sch-mig.lisp; the policy
;;; functions live in hhub/core/dod-ui-pol.lisp. See the ABAC skill at
;;; aiharness/deepseek/skills/knowledge/ABAC-policy-transaction-CONTEXT.md for the traps —
;;; in particular: TRANS_FUNC is the lookup key (not NAME), tenant-id must be 1,
;;; the cache needs refreshiamsettings after seeding, and URI must be the
;;; COLLECTION PREFIX because {id} is a template that never matches a real path.
;;;
;;; Register this migration in the *migrations* list in nst-sch-mig.lisp.
;;; Idempotent — safe to rerun.

(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun migrate-2026Sep-insert-warehouse-api-policy-and-transactions ()
  "Seed a distinct DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for each warehouse
   JSON API endpoint. One policy per transaction; the policy id is captured and
   passed to :policy-id so each transaction is linked to its OWN policy."
  (let ((tenant-id 1)
        ;; Every warehouse API path begins with this prefix; the PEP's
        ;; uri-prefix-boundary-p treats / as a boundary, so one prefix covers the
        ;; collection, the {id} forms and /by-identity.
        (uri "/hhub/api/v1/warehouse"))

    ;; --- LIST : GET /hhub/api/v1/warehouse ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.warehouse.list"
                      "List the warehouses of the session tenant through the JSON API."
                      "com-hhub-policy-api-warehouse-list" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.warehouse.list" uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/warehouse" :tenant-id tenant-id))

    ;; --- CREATE : POST /hhub/api/v1/warehouse ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.warehouse.create"
                      "Create a warehouse for the session tenant through the JSON API."
                      "com-hhub-policy-api-warehouse-create" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.warehouse.create" uri "CREATE"
       :policy-id policy-id
       :trans-func "api POST /hhub/api/v1/warehouse" :tenant-id tenant-id))

    ;; --- READ : GET /hhub/api/v1/warehouse/{id} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.warehouse.read"
                      "Read one warehouse by row-id through the JSON API."
                      "com-hhub-policy-api-warehouse-read" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.warehouse.read" uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/warehouse/{id}" :tenant-id tenant-id))

    ;; --- READ BY IDENTITY : GET /hhub/api/v1/warehouse/by-identity ---
    ;; Its own transaction, NOT a share with the row-id read above: the two are
    ;; reached by different URLs and a policy must be able to refuse one without
    ;; the other (an identity read exposes a row by GSTIN+name, which is a
    ;; different disclosure from fetching a row-id the caller already holds).
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.warehouse.read.identity"
                      "Read a warehouse by GSTIN and name through the JSON API."
                      "com-hhub-policy-api-warehouse-read-identity" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.warehouse.read.identity" uri "READ"
       :policy-id policy-id
       :trans-func "api GET /hhub/api/v1/warehouse/by-identity" :tenant-id tenant-id))

    ;; --- UPDATE : PUT /hhub/api/v1/warehouse/{id} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.warehouse.update"
                      "Update a warehouse by row-id through the JSON API."
                      "com-hhub-policy-api-warehouse-update" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.warehouse.update" uri "UPDATE"
       :policy-id policy-id
       :trans-func "api PUT /hhub/api/v1/warehouse/{id}" :tenant-id tenant-id))

    ;; --- DELETE : DELETE /hhub/api/v1/warehouse/{id} ---
    (let ((policy-id (insert-auth-policy
                      "com.hhub.policy.api.warehouse.delete"
                      "Soft-delete a warehouse by row-id through the JSON API."
                      "com-hhub-policy-api-warehouse-delete" :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.api.warehouse.delete" uri "DELETE"
       :policy-id policy-id
       :trans-func "api DELETE /hhub/api/v1/warehouse/{id}" :tenant-id tenant-id))))
