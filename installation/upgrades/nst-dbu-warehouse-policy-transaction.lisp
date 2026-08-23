;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-warehouse-policy-transaction.lisp
;;;
;;; Warehouse-specific ABAC policy + transaction seed migration.
;;;
;;; The reusable insert helpers (auth-policy-inserted-p, bus-transaction-inserted-p,
;;; auth-policy-id-by-name, insert-auth-policy, insert-bus-transaction) live in
;;; hhub/core/nst-sch-mig.lisp. This file only contains the warehouse endpoint
;;; seeds that use them.
;;;
;;; Register this migration in the *migrations* list in nst-sch-mig.lisp and it
;;; will be applied once to every DB that runs (apply-migrations user pass).

(in-package :nstores)

(defun migrate-2026Aug-insert-warehouse-policy-and-transactions ()
  "Seed a distinct DOD_AUTH_POLICY + DOD_BUS_TRANSACTION pair for each
   warehouse CRUD endpoint. One policy per transaction.

   The :policy-id of the freshly inserted policy is captured explicitly and
   passed to :policy-id on insert-bus-transaction, so each transaction is
   linked to its OWN unique governing policy (never shared).
   Idempotent - safe to rerun."
  (let ((tenant-id 1))

    ;; --- READ ALL : one policy + reading-all-warehouses transaction ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.readall.warehouse"
             "Read All Warehouses for a given vendor and a company combination"
             "com-hhub-policy-readall-warehouse"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.readall.warehouse"
       "/hhub/vwarehouses"
       "READ"
       :policy-id policy-id
       :trans-func "com-hhub-transaction-readall-warehouse"
       :tenant-id tenant-id))

    ;; --- CREATE : one policy + create-warehouse transaction ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.create.warehouse"
             "Policy for warehouse create"
             "com-hhub-policy-create-warehouse"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.create.warehouse"
       "/hhub/createwarehouseaction"
       "CREATE"
       :policy-id policy-id
       :trans-func "com-hhub-transaction-create-warehouse-action"
       :tenant-id tenant-id))

    ;; --- READ : one policy + read-warehouse transaction ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.read.warehouse"
             "Policy for reading a single warehouse"
             "com-hhub-policy-read-warehouse"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.read.warehouse"
       "/hhub/readwarehouseaction"
       "READ"
       :policy-id policy-id
       :trans-func "com-hhub-transaction-read-warehouse-action"
       :tenant-id tenant-id))

    ;; --- UPDATE : one policy + update-warehouse transaction ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.update.warehouse"
             "Policy for updating a warehouse"
             "com-hhub-policy-update-warehouse"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.update.warehouse"
       "/hhub/updatewarehouseaction"
       "UPDATE"
       :policy-id policy-id
       :trans-func "com-hhub-transaction-update-warehouse-action"
       :tenant-id tenant-id))

    ;; --- DELETE : one policy + delete-warehouse transaction ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.delete.warehouse"
             "Policy for deleting a warehouse"
             "com-hhub-policy-delete-warehouse"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.delete.warehouse"
       "/hhub/deletewarehouseaction"
       "DELETE"
       :policy-id policy-id
       :trans-func "com-hhub-transaction-delete-warehouse-action"
       :tenant-id tenant-id))

    ;; --- SEARCH : one policy + search-warehouse transaction ---
    (let ((policy-id
            (insert-auth-policy
             "com.hhub.policy.search.warehouse"
             "Policy for searching warehouses"
             "com-hhub-policy-search-warehouse"
             :tenant-id tenant-id)))
      (insert-bus-transaction
       "com.hhub.transaction.search.warehouse"
       "/hhub/searchwarehouseaction"
       "READ"
       :policy-id policy-id
       :trans-func "com-hhub-transaction-search-warehouse-action"
       :tenant-id tenant-id))))
