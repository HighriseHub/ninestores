;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-invoice-order-link.lisp
;;;
;;; The ord→inv junction's ORDER REFERENCE, in columns of its own:
;;;
;;;   DOD_INVOICE_HEADER  ORDER_NUMBER, ORDER_ID
;;;   DOD_INVOICE_ITEMS   ORDER_ITEM_ID
;;;
;;; WHY ITS OWN COLUMNS AND NOT WHAT IS ALREADY THERE. Before this migration an invoice's only tie to
;;; its order was CONTEXT_ID, and CONTEXT_ID is NOT the order reference: ord→inv copies the ORDER's
;;; context-id, which the legacy cart minted as (uuid:make-v1-uuid) (order/dod-bl-ord.lisp) — the
;;; browsing session that placed the order, an opaque UUID that prints as nothing and that nobody can
;;; quote on the phone. Two read paths need the reference itself:
;;;
;;;   * the printed tax invoice (design US-008 — the buyer's AP team will not pay without it);
;;;   * a search/lookup by the number the vendor and the customer both say out loud.
;;;
;;; And VNUM could NOT hold it: that column is varchar(20) while the MEASURED maximum ORDNUM is 27
;;; characters (497 orders, MAX(CHAR_LENGTH(ORDNUM)) = 27, measured 2026-10-12), which is the
;;; truncation the junction's own comment records.
;;;
;;; ALL THREE COLUMNS ARE NULLABLE, AND THAT IS THE DESIGN, NOT A COMPROMISE. The standalone
;;; POS-style invoice path is deliberately never broken (design D4) and has no order at all, so
;;; "no order" must be expressible. Every reader therefore treats NIL as 'not order-linked':
;;;
;;;   * header NULL  — a standalone invoice;
;;;   * item NULL    — a standalone invoice's line, OR the junction's SYNTHESISED delivery line,
;;;                    which is derived from the order's SHIPPING_COST when the order predates the
;;;                    cart's delivery line, so no order LINE represents it (nst-bl-invhapi.lisp §9).
;;;
;;; NO FOREIGN KEY ON ORDER_ID OR ORDER_ITEM_ID, DELIBERATELY: DOD_ORDER_ITEMS has no unique key for
;;; an FK to reference besides its primary key, and — the reason that actually matters — the invoice is
;;; the legal document and the order is not. An FK would let a later order row or cascade affect an
;;; issued invoice. Both columns are ATTRIBUTION: a hint for the three-way match and for returns, never
;;; a key the document is resolved from.
;;;
;;; NO BACKFILL — a decision, not an omission. Rows written before this migration keep NULL. The
;;; order-linked invoices among them (10 rows, ROW_ID 112-141, all DRAFT) COULD be recovered by joining
;;; CONTEXT_ID to DOD_ORDER.CONTEXT_ID, and deliberately are not: the standalone path's rows are not
;;; resolvable at all, so a partial backfill would leave two populations that look alike and mean
;;; different things. The junction writes both columns from here on.
;;;
;;; ⚠ A PRE-EXISTING DEFECT THIS MIGRATION DOES NOT TOUCH (measured 2026-10-12): NINE orders carry
;;; IS_CONVERTED_TO_INVOICE='Y' with a NULL INVOICE_NUMBER, so the vendor page renders
;;; "INVOICE ? (DRAFT)" (vendor/dod-ui-ven.lisp). That is the order-side link's own gap, ledgered
;;; separately — do not fix it here, and do not read this migration's NULLs as its cause.
;;;
;;; 🚨 WHO CAN APPLY IT: `hhubuser` — the account the IMAGE connects as — holds only
;;; SELECT/INSERT/UPDATE/DELETE on hhubdb (measured 2026-10-12; `SHOW GRANTS`), so ALTER TABLE is NOT
;;; available to it. That is the same reason `hhubuser` cannot see INFORMATION_SCHEMA.TRIGGERS
;;; (PENDING-WORK §1d). `apply-migrations` therefore has to be run by a privileged account; nothing
;;; here can be applied by the app user, and this migration must not be reported as applied until it
;;; returns column by column.
;;;
;;; 🚨 AND THE PRIVILEGED ACCOUNT NEEDS **`INDEX`**, NOT JUST `ALTER` — MEASURED THE HARD WAY ON THIS
;;; VERY MIGRATION (2026-10-12). `hhubadmin` held `ALTER` but not `INDEX`, so the columns were created
;;; and the FIRST `CREATE INDEX` died with
;;;
;;;   Error 1142 / INDEX command denied to user 'hhubadmin'@'localhost' for table 'DOD_INVOICE_HEADER'
;;;
;;; MySQL treats the two as SEPARATE privileges, and `INDEX` cannot be granted at table scope. What
;;; happened next is the lesson, not the error: `apply-migrations` catches PER-MIGRATION and CONTINUES
;;; **without recording the version**, so the run ended "successfully" with two of four statements
;;; applied and the migration still pending. The fix, and it is the whole fix:
;;;
;;;   GRANT INDEX ON hhubdb.* TO 'hhubadmin'@'localhost';   -- or: GRANT ALTER, INDEX ON hhubdb.* TO …
;;;
;;; then re-run — and the re-run is HARMLESS ONLY BECAUSE of `add-column-if-absent`/`add-index-if-absent`,
;;; which printed "already present - skipping" for the two columns and finished the other four
;;; statements. Without those guards the second attempt would have died on Error 1060 and the migration
;;; would have been unapplicable without manual DDL. **Any future DDL migration needs the same two
;;; guards**, and any account that runs one needs `ALTER` + `INDEX`.
;;;
;;; HOW TO RUN IT — both commands from the repo root, in the image:
;;;
;;;   (load-upgrade-files)                            ; compiles installation/upgrades/*.lisp
;;;   (apply-migrations "<priv-user>" "<priv-pw>")    ; every unapplied entry in *migrations*
;;;
;;; ✅ APPLIED 2026-10-12 as `hhubadmin`. Verified afterwards against the live catalog: all three
;;; columns present and NULL-able, all three indexes present and NON_UNIQUE, and the version recorded in
;;; DOD_SCHEMA_MIGRATIONS. The image still has to be REBUILT AND RESTARTED before the junction writes
;;; anything into them — the running process predates the source change.
;;;
;;; It is registered in `*migrations*` (hhub/core/nst-sch-mig.lisp) under version
;;; "12102026-invoice-order-link" — an unregistered upgrade function NEVER RUNS, and `apply-migrations`
;;; refuses before touching the database when a pending entry has no function loaded
;;; (`upgrade-file-defining` finds this file by name).
;;;
;;; 🚨 THE HELPERS ARE **NOT** DEFINED HERE. `add-column-if-absent` / `add-index-if-absent` live in
;;; hhub/core/nst-sch-mig.lisp beside `table-exists-p`, and that placement is load-bearing: this file
;;; is loaded by `load-upgrade-files` AFTER `nst-sch-mig.lisp`, so a local copy here would SILENTLY WIN
;;; over the canonical one — the exact trap that made the first ABAC seed's own helper copies shadow
;;; the real `insert-auth-policy`.
;;;
;;; The CLSQL view classes (dod-Invoice-Header in nst-dal-ihd.lisp, dod-invoice-items in
;;; nst-dal-itm.lisp) declare EVERY live column, so a new column needs no view-class change — but the
;;; new domain slots DO need their mirror lists, their response models and their render-json entries,
;;; or every authenticated invoice route answers 500 with
;;;   the slot COM.NSTORES.APP::ORDER-NUMBER is missing from #<NSTORES::NSTINVHRESPONSEMODEL>
;;; (the defect recorded in nst-bl-invh.lisp above *invh-mirrored-slots*). Those four edits landed with
;;; this migration; `aiharness/deepseek/tools/nst-invoice-mirror-check.lisp` proves them — 55/55 header
;;; and 19/19 item slots, 2026-10-12.

(in-package :nstores)

(defun migrate-2026Oct-invoice-order-link ()
  "The order reference on an invoice: two columns on the header, one on the line. Idempotent, additive,
   and safe on a live table — every column is NULL-able with no default, so the 45 existing headers and
   their 274 lines are untouched and the legacy POS-style create keeps working unchanged.

   ORDER_NUMBER varchar(50) matches ORDNUM's own declaration (varchar(50); the measured maximum length
   in use is 27); ORDER_ID and ORDER_ITEM_ID are mediumint to match the ROW_IDs they name. The two
   indexes serve the two lookups this story exists for: 'which invoice did this order raise?' and
   'which invoice line came from this order line?'

   The ADD is INSTANT in MySQL 8 for a nullable column; the CREATE INDEX is not. On these table sizes
   (45 headers, 274 lines) that is immaterial, and saying so is the point — the question was considered
   for the table it is on, not assumed away."
  (when (table-exists-p "DOD_INVOICE_HEADER")
    (add-column-if-absent "DOD_INVOICE_HEADER" "ORDER_NUMBER"
                          "varchar(50) DEFAULT NULL COMMENT 'ORDNUM of the order this invoice bills; NULL on a standalone POS-style invoice'")
    (add-column-if-absent "DOD_INVOICE_HEADER" "ORDER_ID"
                          "mediumint DEFAULT NULL COMMENT 'DOD_ORDER.ROW_ID - the row behind ORDER_NUMBER; attribution, deliberately no FK'")
    (add-index-if-absent "DOD_INVOICE_HEADER" "idx_invh_order_number" "ORDER_NUMBER")
    (add-index-if-absent "DOD_INVOICE_HEADER" "idx_invh_order_id" "ORDER_ID"))
  (when (table-exists-p "DOD_INVOICE_ITEMS")
    (add-column-if-absent "DOD_INVOICE_ITEMS" "ORDER_ITEM_ID"
                          "mediumint DEFAULT NULL COMMENT 'DOD_ORDER_ITEMS.ROW_ID this line transcribes; NULL on a standalone invoice or the synthesised delivery line'")
    (add-index-if-absent "DOD_INVOICE_ITEMS" "idx_invitm_order_item" "ORDER_ITEM_ID"))
  (format t "  invoice order-link columns done~%"))
