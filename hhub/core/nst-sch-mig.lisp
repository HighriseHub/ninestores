;;; nst-sch-mig.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defparameter *migrations*
  '(("05082025-add-product-code"  migrate-2025May-add-product-code "Added human readable Product code to DOD_PRD_MASTER table")
    ("09052025-add-price&discount-columns"  migrate-2025May-add-discount-column "Added current price and current discount to DOD_PRD_MASTER table")
    ("16062025-modify-dod_order-table"  migrate-2025Jun-dod-order-schema "Modify dod_order table add many columns, drop columns, add indexes and foreign keys")
    ("22082025-modify-dod_order_items-table"  migrate-2025Aug-OrderItem-upgrade "Modify dod_order_items table add many columns")
    ("02092025-modify-dod_order_items-sgst"  migrate-2025Sep-orderitem-upgrade-sgst "Modify dod_order_items table modify the sgst column to decimal(4,2) and drop taxable_value column")
    ("08022026-create-vendor-settings-definition-table"  migrate-2026Feb-create-vendor-settings-definition-table "Create vendor settings definitions table")
    ("08022026-create-vendor-settings-table"  migrate-2026Feb-create-vendor-settings-table "Create vendor settings table")
    ("26012026-create-organizations-table"  migrate-2026Jan-create-organization-tables "Create organization tables")
    ("26012026-create-contacts and addresses-table"  migrate-2026Jan-create-contacts&addresses-tables "Create contacts and addresses  tables")
    ("27012026-create-gstupgrade-tables"  migrate-2026Jan-create-gstupgrade-tables "Create gst upgrade tables")
    ("27012026-update-customer-table"  migrate-2026Jan-update-customer-table "Update Customer table to support GST changes for B2B support")
    ("30012026-update-customer-wallet-table"  migrate-2026Feb-update-customer-wallet-table "Update Customer wallet table to support vendor management in B2B use cases")
    ("02022026-create-customer-users-table"   migrate-2026Feb-create-customer-users-table "Create customer users table for B2B use cases")
    ("02022026-update-customer-users-table"   migrate-2026Feb-update-customer-users-table "Update customer users table for B2B use cases. Copy data from DOD_CUST_PROFILE table.")
    ("08022026-update-customer-users-table"   migrate-2026Feb-create-event-trace-table "Create event trace table which will help taking decisions using AI.")
    ("11022026-update-customer-wallet-table"   migrate-2026Feb-update-customer-wallet-table "Update the customer wallet table to support advance receipt payments.")
    ("11022026-create-proforma-invoice-table"   migrate-2026Feb-create-proforma-invoices-table "Create proforma invoice table.")
    ("11022026-create-advance-receipt-vouchers-table"   migrate-2026Feb-create-advance-receipt-vouchers-table "Create advance receipt vouchers table.")
    ("11022026-create-invoice-advance-adjustments-table"   migrate-2026Feb-create-invoice-advance-adjustments-table "Create invoice advance adjustments table.")
    ("13022026-create-buyer-vendor-account-table"   migrate-2026Feb-create-buyer-vendor-account-table  "Create buyer vendor relationship table where we capture the advance payments.")
    ("13022026-create-gst-reconciliation-table"   migrate-2026Feb-create-gst-reconciliation-table  "Create gst reconciliation table for the customer.")
    ("13022026-create-invoice-gst-reconciliation-table"   migrate-2026Feb-create-invoice-gst-reconciliation-table   "Create invoice gst reconciliation table for the customer.")
    ("13022026-create-vendor-gstr1-status-table"   migrate-2026Feb-create-vendor-gstr1-status-table   "Create vendor gstr1 status check table for a customer.")
    ("13022026-update-invoice-header-table"   migrate-2026Feb-update-invoice-header-table    "Update invoice header to support GST changes.")
    ("13022026-create-tds-certificates-table"   migrate-2026Feb-create-tds-certificates-table    "Create tds certificates table.")
    ("13022026-modify-payment-transactions-table"   migrate-2026Feb-modify-payment-transaction-table    "Modify the payment transaction table.")
    ("13022026-modify-customer-order-table"   migrate-2026Feb-modify-customer-order-table    "Modify the customer order table.")
    ("13022026-modify-customer-order-items-table"   migrate-2026Feb-modify-customer-order-items-table    "Modify the customer order items table.")
    ("16022026-modify-warehouse-table"   migrate-2026Feb-update-warehouse-table "Modify the warehouse table.")
    ("16022026-create-warehouse-location-table"   migrate-2026Feb-create-warehouse-location-table "Create warehouse location table.")
    ("22022026-create-batch-lot-table"   migrate-2026Feb-create-batch-lot-table "Create batch lot table.")
    ("22022026-create-stock-table"   migrate-2026Feb-create-stock-table "Create stock table.")
    ("22022026-create-stock-movement-table"   migrate-2026Feb-create-stock-movement-table "Create stock movement table.")
    ("22022026-create-stock-reservation-table"   migrate-2026Feb-create-stock-reservation-table "Create stock reservation table.")
    ("22022026-create-stock-count-table"   migrate-2026Feb-create-stock-count-table "Create stock count table.")
    ("22022026-update-vendor-orders-table"   migrate-2026March-modify-vendor-order-table "Update vendor orders table to support more GST fields.")
    ("15032026-create-eway-bill-table"   migrate-2026March-create-eway-bill-table    "Create eway bill table.")
    ("15032026-create-delivery-order-table"   migrate-2026March-create-delivery-order-table    "Create delivery order table.")
    ("15032026-create-delivery-items-table"   migrate-2026March-create-delivery-items-table    "Create delivery items table.")
    ("15032026-create-goods-receipt-note-table"   migrate-2026March-create-goods-receipt-note-table    "Create goods receipt note table.")
    ("15032026-create-goods-receipt-note-items-table"   migrate-2026March-create-goods-receipt-note-items-table    "Create goods receipt note items table.")
    ("15032026-add-constraints-to-delivery-items-and-goo"   migrate-2026March-add-constraints-to-delivery-items-and-goods-receipt    "Add constraints to delivery items and goods receipt.")
    ("22032026-create-procure-ai-entity-table"   migrate-2026March-create-procure-ai-entity-table    "Create AI procurement entity table.")
    ("22032026-create-procure-ai-entity-fact-table"   migrate-2026March-create-procure-ai-entity-fact-table    "Create AI procurement entity fact table.")
    ("22032026-create-procure-ai-commerce-event-table"    migrate-2026March-create-procure-ai-commerce-event-table    "Create procure AI commerce event table.")
    ("22032026-create-procure-ai-commerce-state-table"    migrate-2026March-create-procure-ai-commerce-state-table    "Create procure AI commerce state table.")
    ("22032026-create-procure-ai-signal-table"    migrate-2026March-create-procure-ai-signal-table    "Create procure AI signal table.")
    ("22032026-create-procure-ai-chat-signal-table"    migrate-2026March-create-procure-ai-chat-signal-table    "Create procure AI chat signal table.")
    ("22032026-create-procure-ai-signal-route-table"    migrate-2026March-create-procure-ai-signal-route-table    "Create procure AI signal route table.")
    ("22032026-create-procure-ai-policy-table"    migrate-2026March-create-procure-ai-policy-table    "Create procure AI policy table.")
    ("22032026-create-procure-ai-exception-table"    migrate-2026March-create-procure-ai-exception-table    "Create procure AI exception table.")
    ("22032026-create-procure-ai-skill-table"    migrate-2026March-create-procure-ai-skill-table    "Create procure AI skill table.")
    ("22032026-create-procure-ai-agent-context-table"    migrate-2026March-create-procure-ai-agent-context-table    "Create procure AI agent context table.")
    ("22032026-create-procure-ai-prediction-table"    migrate-2026March-create-procure-ai-prediction-table    "Create procure AI prediction table.")
    ("22032026-create-procure-ai-planned-action-table"    migrate-2026March-create-procure-ai-planned-action-table    "Create procure AI planned action table.")
    ("22032026-create-procure-ai-symentic-index-table"    migrate-2026March-create-procure-ai-symentic-index-table    "Create procure AI symentic index table.")
    ("22032026-insert-seed-data-to-ai-tables"    migrate-2026March-insert-seed-data-to-ai-tables    "Insert seed data to ai tables.")
    ("06052026-create-view-customer-inward-invoices"   migrate-2026May-create-customer-inward-invoices-view    "Create a view which shows customer inward invoices.")
    ("25082026-insert-warehouse-policy-and-transactions"   migrate-2026Aug-insert-warehouse-policy-and-transactions   "Insert DOD_AUTH_POLICY + DOD_BUS_TRANSACTION seed rows for warehouse CRUD endpoints.")
    ("01092026-insert-vendor-order-cancel-policy-and-tra"   migrate-2026Sep-insert-vendor-order-cancel-policy-and-transaction   "Insert DOD_AUTH_POLICY + DOD_BUS_TRANSACTION seed rows for the vendor order-cancel endpoint.")
    ("19092026-insert-product-policy-and-transactions"   migrate-2026Sep-insert-product-api-policy-and-transactions   "Insert DOD_AUTH_POLICY + DOD_BUS_TRANSACTION seed rows for the catalog/product JSON API endpoints.")
    ("19092026-insert-warehouse-api-policies"   migrate-2026Sep-insert-warehouse-api-policy-and-transactions   "Insert ABAC policy + transaction seed rows for the warehouse JSON API endpoints.")
    ("19092026-insert-vndapi-policies"   migrate-2026Sep-insert-vndapi-policy-and-transactions   "Insert ABAC policy + transaction seed rows for the vendor profile JSON API endpoints.")
    ("19092026-insert-vndshpapi-policies"   migrate-2026Sep-insert-vndshpapi-policy-and-transactions   "Insert ABAC policy + transaction seed rows for the vendor shipping JSON API endpoints.")
    ("19092026-insert-vndvpmapi-policies"   migrate-2026Sep-insert-vndvpmapi-policy-and-transactions   "Insert ABAC policy + transaction seed rows for the vendor payment-methods JSON API endpoints.")
    ("20092026-insert-product-pricing-policies"   migrate-2026Sep-insert-product-pricing-policy-and-transaction   "Insert the ABAC policy + transaction seed row for the product PRICING endpoint. A separate version because the 19092026 product migration was already applied and never re-runs; 40 chars, because VERSION is varchar(50).")
    ("20092026-insert-product-status-policy"   migrate-2026Sep-insert-product-status-policy-and-transaction   "Insert the ABAC policy + transaction seed row for the product STATUS endpoint (Turn On / Turn Off). A third version for the same reason as the second: 20092026-insert-product-pricing-policies was already applied, so this cannot join it. 37 chars, because VERSION is varchar(50).")
    ("20092026-insert-product-copy-policy"   migrate-2026Sep-insert-product-copy-policy-and-transaction   "Insert the ABAC policy + transaction seed row for the product COPY endpoint. A fourth version: the status one was applied at 19:17:15 today, so it can no longer be appended to. 35 chars, because VERSION is varchar(50).")
    ("20092026-insert-product-bulk-policies"   migrate-2026Sep-insert-product-bulk-policies-and-transactions   "Insert the ABAC policy + transaction seed rows for the bulk products.csv PAIR (template download + upload). A fifth version, and the clearest argument for the one-migration-per-day cadence in the ABAC skill 13.1: every earlier version was applied before this endpoint existed. 45 chars, because VERSION is varchar(50).")
    ))




(defun get-applied-migrations ()
  (mapcar #'first
          (clsql:query "SELECT version FROM DOD_SCHEMA_MIGRATIONS ORDER BY row_id ASC" :field-names nil)))

(defparameter *upgrade-files-directory* #p"/home/ubuntu/ninestores/installation/upgrades/"
  "Where the one-shot migration files live.

   THESE FILES ARE DELIBERATELY NOT IN nstores.asd. A migration function is needed
   exactly once per database; loading 17 files into every image forever to serve a
   once-per-database event is a bad trade, and they are history rather than system
   logic. 59 of the 65 registered migrations live here and nowhere else — so this
   directory is loaded ON DEMAND, via load-upgrade-files, immediately before
   apply-migrations. Do not \"helpfully\" wire them into the asd; the running image
   does not need them and a stray call to a one-shot migration is not desirable.")

(defun upgrade-lisp-files (&optional (directory *upgrade-files-directory*))
  "Every .lisp file in DIRECTORY, sorted. Sorted so the load order is deterministic
   across runs; the files are independent of one another (each only needs the
   helpers in this file), so the order does not otherwise matter."
  (sort (remove-if-not (lambda (p) (string-equal (pathname-type p) "lisp"))
                       (directory (merge-pathnames "*.lisp" directory)))
        #'string< :key #'namestring))

(defun upgrade-file-defining (function-name &optional (directory *upgrade-files-directory*))
  "Which upgrade file defines FUNCTION-NAME, or NIL. Best-effort text search, called
   only on the pre-flight failure path in apply-migrations — so the I/O is paid only
   when something is already wrong."
  (let ((needle (format nil "(defun ~A" (string-downcase (string function-name)))))
    (loop for f in (upgrade-lisp-files directory)
          when (handler-case
                   (with-open-file (s f :external-format :utf-8)
                     (loop for line = (read-line s nil nil)
                           while line
                           thereis (search needle (string-downcase line))))
                 (error () nil))
            return f)))

(defun load-upgrade-files (&optional (directory *upgrade-files-directory*) (verbose t))
  "Load every migration file in DIRECTORY into the running image.

   CALLED BY apply-migrations ITSELF, so the two cannot get out of step: the
   migration functions live in these files and nowhere else (59 of the 65), and a
   run that starts without them can only report 'function undefined'. Pass
   :VERBOSE NIL for the one-line summary without the per-file chatter.

   Each file is loaded inside its own handler-case, so one unloadable file does not
   stop the rest — the same per-item discipline apply-migrations uses. Returns two
   values: the files loaded, and the (file . condition) pairs that failed.

   *PACKAGE* is restored afterwards because every one of these files does
   (in-package :nstores); CL's LOAD should undo that itself, but the caller's REPL
   package is worth not depending on the implementation for."
  (let ((files (upgrade-lisp-files directory))
        (loaded '()) (failed '())
        (pkg *package*))
    (unwind-protect
         (dolist (f files)
           (handler-case
               (progn (load f)
                      (push f loaded)
                      (when verbose (format t "  loaded ~A~%" (file-namestring f))))
             (error (e)
               (push (cons f e) failed)
               (format *error-output* "  FAILED to load ~A: ~A~%" (file-namestring f) e))))
      (setf *package* pkg))
    (format t "~&upgrade files: ~D loaded~A~%"
            (length loaded)
            (if failed (format nil ", ~D FAILED" (length failed)) ""))
    (values (nreverse loaded) (nreverse failed))))

(defun apply-migrations (username password)
  (unwind-protect
       (progn
         ;; LOAD THE MIGRATION FILES FIRST — the functions live in
         ;; installation/upgrades/ and nowhere else (59 of the 65 registered), and
         ;; they are deliberately NOT in nstores.asd. Doing it here rather than
         ;; relying on the caller means the two cannot get out of step: a run can
         ;; no longer start without the functions it is about to call.
         (load-upgrade-files *upgrade-files-directory* nil)
         (crm-db-connect :servername *crm-database-server*
                         :strdb *crm-database-name*
                         :strusr username
                         :strpwd password
                         :strdbtype :mysql)
         (handler-case
             (let* ((applied (get-applied-migrations))
                    (pending (remove-if (lambda (mig)
                                          (member (first mig) applied :test #'string=))
                                        *migrations*))
                    (unloaded (remove-if (lambda (mig) (fboundp (second mig))) pending)))
               ;; PRE-FLIGHT: refuse BEFORE touching the database. A pending
               ;; migration whose function was never loaded is not a database
               ;; problem — it is a missing (load-upgrade-files) — and discovering
               ;; that mid-run leaves a half-applied schema behind. Scoped to
               ;; PENDING entries only: an already-applied migration is correctly
               ;; skipped and must not demand a file that will never be called.
               (when unloaded
                 (error "REFUSING TO APPLY: ~D pending migration(s) have no function loaded. ~
                         Nothing was written. Run (load-upgrade-files), then retry. Missing:~%~{  ~A~%~}"
                        (length unloaded)
                        (remove-duplicates
                         (mapcar (lambda (mig)
                                   (or (upgrade-file-defining (second mig))
                                       (format nil "no file defines ~A" (second mig))))
                                 unloaded)
                         :test #'equal)))
               (dolist (migration *migrations*)
                 (destructuring-bind (version fn description) migration
                   (unless (member version applied :test #'string=)
                     ;; handler-case is PER-MIGRATION on purpose: one bad entry must
                     ;; not hide the migrations queued behind it, which is exactly
                     ;; what the old whole-loop wrapper did.
                     (handler-case
                         (progn
                           (format t "Applying migration ~A...~%" version)
                           (format t "Description: ~A~%" description)
                           (funcall fn)
                           (sleep 1)
                           (clsql:execute-command
                            (format nil "INSERT INTO DOD_SCHEMA_MIGRATIONS (version) VALUES ('~A');" version))
                           (format t "Migration ~A applied.~%" version))
                       (error (e)
                         (format *error-output*
                                 "~&Migration ~A FAILED (continuing with the rest): ~A~%"
                                 version e)))))))
           (error (e)
             ;; Reached only if the migration LIST itself is unreadable, or the
             ;; connection dropped — a whole-run failure rather than one entry's.
             (format *error-output* "Migration run error: ~A~%" e))))
    (when (clsql:connected-databases)
      (clsql:disconnect))))

;;; ---------------------------------------------------------------------------
;;; ABAC policy + transaction data-migration helpers (idempotent).
;;;
;;; These tables map URIs -> AUTH_POLICY_ID -> POLICY_FUNC, so they are
;;; migrated as *business data* - "insert if the NAME isn't present" - rather
;;; than as schema. Once these helpers are loaded, per-endpoint seed functions
;;; (e.g. migrate-2026Aug-insert-warehouse-policy-and-transactions) call them.
;;; ---------------------------------------------------------------------------

(defun sql-literal (value)
  "VALUE as the BODY of a MySQL string literal: single quotes doubled, backslashes
   escaped. These helpers build their SQL with FORMAT, so an unescaped apostrophe
   (\"the session tenant's catalog\") terminates the literal and raises Error 1064 —
   and a caller-supplied value could inject. Every string that reaches a quote is
   wrapped in this."
  (let ((s (if value (format nil "~A" value) "")))
    (with-output-to-string (out)
      (loop for c across s do
        (cond ((char= c #\') (write-string "''" out))
              ((char= c #\\) (write-string "\\\\" out))
              (t (write-char c out)))))))

(defun auth-policy-inserted-p (name tenant-id)
  "Non-nil if a live (not soft-deleted) policy with NAME exists."
  (let ((result (clsql:query
                 (format nil
                         "SELECT COUNT(*) FROM DOD_AUTH_POLICY
                          WHERE NAME = '~A' AND TENANT_ID = ~D AND DELETED_STATE = 'N'"
                         (sql-literal name) tenant-id)
                 :flatp t)))
    (> (first result) 0)))

(defun bus-transaction-inserted-p (name tenant-id)
  "Non-nil if a live (not soft-deleted) transaction with NAME exists."
  (let ((result (clsql:query
                 (format nil
                         "SELECT COUNT(*) FROM DOD_BUS_TRANSACTION
                          WHERE NAME = '~A' AND TENANT_ID = ~D AND DELETED_STATE = 'N'"
                         (sql-literal name) tenant-id)
                 :flatp t)))
    (> (first result) 0)))

(defun auth-policy-id-by-name (name tenant-id)
  "Return the ROW_ID of the LIVE policy named NAME, or NIL."
  (let ((result (clsql:query
                 (format nil
                         "SELECT ROW_ID FROM DOD_AUTH_POLICY
                          WHERE NAME = '~A' AND TENANT_ID = ~D AND DELETED_STATE = 'N'
                          LIMIT 1"
                         (sql-literal name) tenant-id)
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
                 (sql-literal name) (sql-literal description)
                 (sql-literal policy-func) (sql-literal active-flg) tenant-id))
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
                              (sql-literal transaction-name) tenant-id)
                      :flatp t)))
            (and res (first res))))
        (progn
          (clsql:execute-command
           (format nil
                   "INSERT INTO DOD_BUS_TRANSACTION
                      (NAME, URI, AUTH_POLICY_ID, TRANS_TYPE, CREATED_BY, ACTIVE_FLG, DELETED_STATE, TENANT_ID, TRANS_FUNC, ABAC_SUBJECT_ID)
                    VALUES
                      ('~A', '~A', ~D, '~A', NULL, '~A', 'N', ~D, '~A', ~A)"
                   (sql-literal transaction-name) (sql-literal uri) effective-policy-id
                   (sql-literal trans-type) (sql-literal active-flg) tenant-id
                   (sql-literal trans-func) (if abac-subject-id (format nil "~D" abac-subject-id) "NULL")))
          (format t "  inserted transaction ~A (~A) linked to policy ~D~%"
                  transaction-name uri effective-policy-id)
          (let ((res (clsql:query
                      (format nil
                              "SELECT ROW_ID FROM DOD_BUS_TRANSACTION
                               WHERE NAME = '~A' AND TENANT_ID = ~D AND DELETED_STATE = 'N' LIMIT 1"
                              (sql-literal transaction-name) tenant-id)
                      :flatp t)))
            (and res (first res)))))))

(defun column-exists-p (table column)
  (let* ((sql (format nil
                      "SELECT COUNT(*) FROM information_schema.columns
                       WHERE table_schema = DATABASE()
                         AND table_name = '~A'
                         AND column_name = '~A'"
                      table column))
         (result (clsql:query sql :flatp t)))
    (> (first result) 0)))


(defun column-type-equals-p (table-name column-name expected-type)
  (let* ((query (format nil
                        "SELECT DATA_TYPE, NUMERIC_PRECISION, NUMERIC_SCALE
                         FROM information_schema.columns
                         WHERE table_name = '~A' AND column_name = '~A' AND table_schema = DATABASE();"
                        table-name column-name))
         (result (clsql:query query :flatp t)))
    (when result
      (destructuring-bind (data-type precision scale) result
        (let ((actual (format nil "~A(~A,~A)" (string-upcase data-type) precision scale)))
          (string= actual (string-upcase expected-type)))))))


(defun index-exists-p (table-name index-name)
  (let* ((query (format nil
                        "SELECT 1 FROM information_schema.statistics
                         WHERE table_name = '~A' AND index_name = '~A' AND table_schema = DATABASE();"
                        table-name index-name))
         (result (clsql:query query :flatp t)))
    (not (null result))))

(defun foreign-key-exists-p (table-name fk-name)
  (let* ((query (format nil
                        "SELECT 1 FROM information_schema.table_constraints
                         WHERE table_name = '~A' AND constraint_name = '~A'
                         AND constraint_type = 'FOREIGN KEY' AND table_schema = DATABASE();"
                        table-name fk-name))
         (result (clsql:query query :flatp t)))
    (not (null result))))

(defun table-exists-p (table)
  (let* ((sql (format nil
                      "SELECT COUNT(*) FROM information_schema.tables
                       WHERE table_schema = DATABASE()
                         AND table_name = '~A'"
                      table))
         (result (clsql:query sql :flatp t)))
    (> (first result) 0)))
