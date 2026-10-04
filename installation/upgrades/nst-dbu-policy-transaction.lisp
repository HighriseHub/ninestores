;;-*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-policy-transaction.lisp
;;;
;;; Idempotent DDL/DML helpers for the ABAC policy + transaction tables.
;;;
;;; These two tables are business-data (they map URIs -> AUTH_POLICY_ID ->
;;; POLICY_FUNC), so they are migrated just like schema, but with
;;; "insert if the NAME isn't present" semantics instead of DROP/CREATE.
;;;
;;; Usage:
;;;   (apply-migrations user pass)  -- runs every *migrations* entry once
;;;
;;; Or, standalone:
;;;   (apply-auth-policy-transaction-migrations user pass)
;;;
;;; Rule for adding a NEW policy + transaction pair (e.g. when you ship a
;;; new warehouse endpoint): append a new migration function to
;;; **INSTALLATION/UPGRADES/NST-DBU-POLICY-TRANSACTION.LISP**, register it in
;;; the *migrations* list in hhub/core/nst-sch-mig.lisp, and it will be
;;; applied once to every DB that runs apply-migrations.

(in-package :nstores)

;;; ---------------------------------------------------------------------------
;;; 🚨 THE HELPER DEFINITIONS THAT USED TO SIT HERE ARE DELETED (2026-10-04), AND THIS
;;; COMMENT IS THE REASON — they were a SECOND COPY of helpers that already live in
;;; hhub/core/nst-sch-mig.lisp: auth-policy-inserted-p, bus-transaction-inserted-p,
;;; auth-policy-id-by-name, insert-auth-policy, insert-bus-transaction.
;;;
;;; WHY DELETING THEM FIXES A LIVE BUG rather than merely tidying: apply-migrations calls
;;; load-upgrade-files FIRST, so this file is loaded AFTER core/nst-sch-mig.lisp — which means
;;; its older copies OVERWROTE the canonical ones for the rest of the run. The canonical
;;; insert-auth-policy escapes every string through sql-literal (single quotes doubled); these
;;; copies did not, so an apostrophe in a DESCRIPTION terminated the SQL literal and the seed
;;; died with Error 1064 — measured on 2026-10-04 on the order API seed, whose first
;;; description reads "the session customer's orders". The escaping was in the image the whole
;;; time and was never called: ONE HELPER, ONE DEFINITION.
;;;
;;; The helpers are always available when this file runs: they are defined at asd load time by
;;; core/nst-sch-mig.lisp, which is also the file that defines apply-migrations and
;;; load-upgrade-files. Nothing here needs to define them again.
;;; ---------------------------------------------------------------------------

;;; ---------------------------------------------------------------------------
;;; Standalone runner - applies ALL policy/transaction migrations registered
;;; below. Useful when you don't want to run the whole schema migration set.
;;; ---------------------------------------------------------------------------

(defparameter *nst-policy-transaction-migrations*
  '(
    ("25082026-insert-warehouse-policy-and-transactions"
     migrate-2026Aug-insert-warehouse-policy-and-transactions
     "Insert DOD_AUTH_POLICY + DOD_BUS_TRANSACTION seed rows for warehouse CRUD endpoints.")
    ;; Add more policy/transaction migrations here.
    ))

(defun apply-auth-policy-transaction-migrations (username password)
  "Run only the policy/transaction seed migrations against the current CRM DB."
  (unwind-protect
       (progn
         (crm-db-connect :servername *crm-database-server*
                         :strdb *crm-database-name*
                         :strusr username
                         :strpwd password
                         :strdbtype :mysql)
         (handler-case
             (let ((applied (get-applied-migrations)))
               (dolist (migration *nst-policy-transaction-migrations*)
                 (destructuring-bind (version fn description) migration
                   (unless (member version applied :test #'string=)
                     (format t "Applying policy/transaction migration ~A...~%" version)
                     (format t "Description: ~A~%" description)
                     (funcall fn)
                     (sleep 1)
                     (clsql:execute-command
                      (format nil "INSERT INTO DOD_SCHEMA_MIGRATIONS (version) VALUES ('~A');" version))
                     (format t "Policy/transaction migration ~A applied.~%" version)))))
           (error (e)
             (format *error-output* "Migration error: ~A~%" e))))
    (when (clsql:connected-databases)
      (clsql:disconnect))))

;;; ---------------------------------------------------------------------------
;;; Example migration - the warehouse read-all pair you showed earlier.
;;; ---------------------------------------------------------------------------

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

