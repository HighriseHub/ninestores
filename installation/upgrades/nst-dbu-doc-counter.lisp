;;; nst-dbu-doc-counter.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; The document-number allocation store — S0c of the orders batch.
;;; Design: aiharness/deepseek/skills/order-adhara-stories-CONTEXT.md § S0c.
;;;
;;; TWO tables, for two different reasons.
;;;
;;;   DOD_DOC_COUNTER — {counter} in a number-format template has never had a backing
;;;     store anywhere in this tree. The invoice number is minted by a MySQL trigger
;;;     instead (installation/nstdbtriggers.sql:4-9), which is exactly why
;;;     invoice-general-settings' invoice-number-format is aspirational and
;;;     nst-dal-invh.lisp:85 says the number "SHOULD follow" a format nothing reads.
;;;     A counter row makes allocation atomic and lets the shape stay DATA.
;;;
;;;   DOD_SYS_SECRET — the key an ORDER reference is permuted under ({ref:N} in
;;;     nst-doc-reference). It must NOT join the other secrets in
;;;     hhub/core/extkeys.lisp, because THAT FILE IS TRACKED: a key in git would let
;;;     anyone who can read the repository enumerate every reference in the system,
;;;     which is the one property the permutation exists to provide.
;;;
;;; ⚠ THE UNIQUE KEY IS (DOC_TYPE, SCOPE_KIND, SCOPE_ID, FINYEAR), AND EVERY ONE OF
;;; THOSE COLUMNS IS NOT NULL ON PURPOSE. A NULLable column in a unique key is not
;;; enforced by MySQL — NULLs compare as DISTINCT — so a NULL scope id would let one
;;; series fork into two counter rows and mint duplicate document numbers. SCOPE_KIND
;;; is what keeps the index airtight while still leaving room for a second scope:
;;; orders allocate as ('CUSTOMER', cust-id), a future vendor-issued invoice series
;;; would allocate as ('VENDOR', vendor-id), and neither needs a schema change to
;;; gain it. (That NULL-in-a-unique-key trap is recorded as F15 in the story file.)
;;;
;;; ⚠ EVERY IDENTIFIER BELOW IS BACKTICK-QUOTED, AND THAT IS NOT DECORATION. The
;;; first version of this file named the sequence column LAST_VALUE, and MySQL 8.0
;;; RESERVES that word — it is a window function (LAST_VALUE() OVER …) — so the
;;; CREATE failed on the live database with:
;;;
;;;   Error 1064 … near 'LAST_VALUE    INT NOT NULL DEFAULT 0,
;;;   CREATED       TIMESTAMP NOT NULL DEFAULT' at line 8
;;;
;;; The column is `LAST_SEQ` now, and quoting every identifier means the next column
;;; added here cannot be stopped by a word the server has since claimed. This table's
;;; SQL is also written by hand in nst-next-doc-counter (core/dod-bl-utl.lisp), which
;;; quotes its identifiers for the same reason — KEEP THE TWO IN STEP.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun migrate-2026Sep-create-doc-counter ()
  "Create DOD_DOC_COUNTER and DOD_SYS_SECRET, and seed the document-reference key.

   Idempotent: the two CREATEs are guarded by table-exists-p, and the key is only
   generated when the row is absent — so a second run writes nothing and reports
   0 for both counts. A FAILED run records nothing in DOD_SCHEMA_MIGRATIONS (the
   version is written only after the function returns), so a corrected re-run is
   clean."
  (flet ((create-table-if-not-exists (table-name ddl)
           (unless (table-exists-p table-name)
             (clsql:execute-command ddl))))

    ;; 1. the counter
    (create-table-if-not-exists
     "DOD_DOC_COUNTER"
     "CREATE TABLE `DOD_DOC_COUNTER` (
  `ROW_ID`        MEDIUMINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `DOC_TYPE`      VARCHAR(20) NOT NULL,
  `SCOPE_KIND`    VARCHAR(10) NOT NULL,
  `SCOPE_ID`      MEDIUMINT NOT NULL,
  `TENANT_ID`     MEDIUMINT DEFAULT NULL,
  `FINYEAR`       VARCHAR(9) NOT NULL,
  `LAST_SEQ`      INT NOT NULL DEFAULT 0,
  `CREATED`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UPDATED`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_doc_counter` (`DOC_TYPE`, `SCOPE_KIND`, `SCOPE_ID`, `FINYEAR`),
  KEY `idx_doc_counter_tenant` (`TENANT_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")

    ;; 2. the secret store
    (create-table-if-not-exists
     "DOD_SYS_SECRET"
     "CREATE TABLE `DOD_SYS_SECRET` (
  `SECRET_NAME`   VARCHAR(64) NOT NULL PRIMARY KEY,
  `SECRET_VALUE`  VARCHAR(255) NOT NULL,
  `CREATED`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ROTATED`       TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4")

    ;; 3. the document-reference key — generated with createciphersalt (28 random
    ;;    bytes via secure-random), never derived from anything, never in source.
    (if (plusp (first (clsql:query
                       "SELECT COUNT(*) FROM `DOD_SYS_SECRET` WHERE `SECRET_NAME` = 'DOC_REF_KEY'"
                       :flatp t)))
        (format t "~&DOD_SYS_SECRET: DOC_REF_KEY already present, left untouched.~%")
        (progn
          (clsql:execute-command
           (format nil "INSERT INTO `DOD_SYS_SECRET` (`SECRET_NAME`, `SECRET_VALUE`) ~
                          VALUES ('DOC_REF_KEY', '~A')"
                   (createciphersalt)))
          (format t "~&DOD_SYS_SECRET: generated the DOC_REF_KEY document-reference key.~%")))

    ;; report, so the run says what it did rather than only that it finished
    (format t "~&doc-counter: DOD_DOC_COUNTER rows = ~D, DOD_SYS_SECRET rows = ~D~%"
            (first (clsql:query "SELECT COUNT(*) FROM `DOD_DOC_COUNTER`" :flatp t))
            (first (clsql:query "SELECT COUNT(*) FROM `DOD_SYS_SECRET`" :flatp t)))))
