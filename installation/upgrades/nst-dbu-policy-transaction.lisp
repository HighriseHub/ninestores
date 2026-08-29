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
;;; Convenience helpers - all of them are idempotent / safe to run twice.
;;; ---------------------------------------------------------------------------

(defun auth-policy-inserted-p (name tenant-id)
  "Non-nil if a live (not soft-deleted) policy with NAME exists."
  (let ((result (clsql:query
                 (format nil
                         "SELECT COUNT(*) FROM DOD_AUTH_POLICY
                          WHERE NAME = '~A' AND TENANT_ID = ~D AND DELETED_STATE = 'N'"
                         name tenant-id)
                 :flatp t)))
    (> (first result) 0)))

(defun bus-transaction-inserted-p (name tenant-id)
  "Non-nil if a live (not soft-deleted) transaction with NAME exists."
  (let ((result (clsql:query
                 (format nil
                         "SELECT COUNT(*) FROM DOD_BUS_TRANSACTION
                          WHERE NAME = '~A' AND TENANT_ID = ~D AND DELETED_STATE = 'N'"
                         name tenant-id)
                 :flatp t)))
    (> (first result) 0)))

(defun auth-policy-id-by-name (name tenant-id)
  "Return the ROW_ID of the LIVE policy named NAME, or NIL."
  (let ((result (clsql:query
                 (format nil
                         "SELECT ROW_ID FROM DOD_AUTH_POLICY
                          WHERE NAME = '~A' AND TENANT_ID = ~D AND DELETED_STATE = 'N'
                          LIMIT 1"
                         name tenant-id)
                 :flatp t)))
    (and result (first result))))

(defun insert-auth-policy (name description policy-func &key (tenant-id 1) (active-flg "Y"))
  "Insert a policy row unless one with NAME already exists.
   Returns the policy ROW_ID (existing or freshly inserted)."
  (if (auth-policy-inserted-p name tenant-id)
      (progn
        (format t "  policy ~A already exists - skipping~%" name)
        (auth-policy-id-by-name name tenant-id))
      (progn
        (clsql:execute-command
         (format nil
                 "INSERT INTO DOD_AUTH_POLICY
                    (NAME, DESCRIPTION, POLICY_FUNC, CREATED_BY, ACTIVE_FLG, DELETED_STATE, TENANT_ID)
                  VALUES
                    ('~A', '~A', '~A', NULL, '~A', 'N', ~D)"
                 name description policy-func active-flg tenant-id))
        (format t "  inserted policy ~A~%" name)
        (auth-policy-id-by-name name tenant-id))))

(defun insert-bus-transaction (transaction-name uri trans-type
                               &key policy-id policy-name policy-description policy-func
                                    (trans-func nil) (abac-subject-id nil)
                                    (tenant-id 1) (active-flg "Y"))
  "Insert a transaction row (and, if its governing policy does not exist yet,
   insert that policy too). Idempotent on transaction NAME.

   Either pass :policy-id (the AUTH_POLICY_ID you already know) or pass
   :policy-name, :policy-description, :policy-func to have the policy created
   implicitly and linked.

  Returns the transaction ROW_ID (existing or freshly inserted)."
  (unless trans-func
    (setf trans-func (concatenate 'string "com-hhub-transaction-" trans-type)))
  (let* ((effective-policy-id
           (if policy-id
               policy-id
               (insert-auth-policy policy-name policy-description policy-func
                                   :tenant-id tenant-id :active-flg active-flg))))
    (unless effective-policy-id
      (error "Could not resolve AUTH_POLICY_ID for transaction ~A. Pass :policy-id or :policy-name." transaction-name))
    (if (bus-transaction-inserted-p transaction-name tenant-id)
        (progn
          (format t "  transaction ~A already exists - skipping~%" transaction-name)
          (let ((res (clsql:query
                      (format nil
                              "SELECT ROW_ID FROM DOD_BUS_TRANSACTION
                               WHERE NAME = '~A' AND TENANT_ID = ~D AND DELETED_STATE = 'N' LIMIT 1"
                              transaction-name tenant-id)
                      :flatp t)))
            (and res (first res))))
        (progn
          (clsql:execute-command
           (format nil
                   "INSERT INTO DOD_BUS_TRANSACTION
                      (NAME, URI, AUTH_POLICY_ID, TRANS_TYPE, CREATED_BY, ACTIVE_FLG, DELETED_STATE, TENANT_ID, TRANS_FUNC, ABAC_SUBJECT_ID)
                    VALUES
                      ('~A', '~A', ~D, '~A', NULL, '~A', 'N', ~D, '~A', ~A)"
                   transaction-name uri effective-policy-id trans-type active-flg tenant-id
                   trans-func (if abac-subject-id (format nil "~D" abac-subject-id) "NULL")))
          (format t "  inserted transaction ~A (~A) linked to policy ~D~%"
                  transaction-name uri effective-policy-id)
          (let ((res (clsql:query
                      (format nil
                              "SELECT ROW_ID FROM DOD_BUS_TRANSACTION
                               WHERE NAME = '~A' AND TENANT_ID = ~D AND DELETED_STATE = 'N' LIMIT 1"
                              transaction-name tenant-id)
                      :flatp t)))
            (and res (first res)))))))

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

