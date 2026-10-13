;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-invoice-lock.lisp
;;;
;;; The vendor's EDIT LOCK on an invoice — story E1/US-013, raised 2026-10-12:
;;;
;;;   "a vendor would not like to modify the invoice if it is originated from an order … a lock invoice
;;;    button which will be locked by default if it is originated from an order … we will note it in a
;;;    column named invoice unlocked by and time."
;;;
;;;   DOD_INVOICE_HEADER  INVOICE_LOCKED, UNLOCKED_BY_USER_ID, UNLOCKED_BY_VENDOR_ID, UNLOCKED_AT
;;;
;;; WHY THE COLUMN IS `INVOICE_LOCKED` AND NOT `LOCKED`: LOCKED is a RESERVED WORD in MySQL 8. A column
;;; called LOCKED works only because every DML statement quotes it with backticks, and these migration
;;; helpers build their statements with FORMAT — where a backtick is one more thing to get wrong for no
;;; benefit. Measured: `SELECT … WHERE LOCKED IS NULL` is Error 1064 before the column even exists.
;;;
;;; WHY THE DEFAULT IS 'N' AND NOT 'Y'. 'Y' is what an ORDER-ORIGINATED invoice gets, but that default
;;; belongs to the JUNCTION, not to the column: `invh-assemble-from-order` writes :invoice-locked "Y"
;;; because it is the only caller that knows an order is behind the document
;;; (nst-bl-invhapi.lisp §9). A column default of 'Y' would lock every STANDALONE POS-style invoice at
;;; creation — and that path is deliberately never broken (design D4), so a change that silently starts
;;; locking its documents would be a regression dressed as a default.
;;;
;;; WHY A STORED FLAG AND NOT A DERIVED ONE. A derived rule ("locked iff ORDER_ID is set and UNLOCKED_AT
;;; is NULL") needs no state column and cannot drift — but it has no way BACK: once unlocked, the
;;; invoice is unlocked forever, and a vendor who fixed a mistake could not put the protection back
;;; without erasing the audit row. The requirement is for BOTH directions, each recorded, so the state
;;; has to be storable. INVOICE_LOCKED is that state; UNLOCKED_AT is when it last changed; and
;;; UNLOCKED_AT alone does not tell you the current state, which is why the two are separate columns
;;; rather than one.
;;;
;;; 🚨 NO ROW IS LOCKED BY THIS MIGRATION, AND THAT IS THE REQUESTER'S RULING (2026-10-12), REVISED:
;;;
;;;   "In India … when you order something and the invoice is prepared for that order, generally people add
;;;    more items in the nick of time after the order is placed as well. To accommodate such use cases, I
;;;    thought we should keep the invoice open ended and leave it to the vendor's discretion. In fact, we
;;;    can create a vendor setting about it. So the column in the invoice header stays. Let the custom
;;;    setting decide what the vendor wants to do with it."
;;;
;;; So: the COLUMN stays, the SETTING decides, and the JUNCTION applies it
;;; (`invh-lock-order-derived-invoices-p`, nst-bl-invhapi.lisp §9). This migration creates four columns and
;;; writes to none of them.
;;;
;;; ⚠ AN EARLIER VERSION OF THIS FILE MARKED THE 10 ORDER-LINKED INVOICES 'Y'. That was WITHDRAWN, not
;;; merely softened, and the reason is worth keeping: those 10 rows belong to vendors whose setting either
;;; does not exist or says `enabled nil`, so locking them would APPLY A CHOICE NO VENDOR MADE in order to
;;; make a default look already-true. A protective default that arrives as a data change is exactly the
;;; kind of thing that is hard to notice and hard to undo. Every existing invoice therefore stays 'N' —
;;; open ended, like the requester's own case — and the setting governs from the next invoice onward.
;;;
;;; (The join that would have done it was measured and is sound: 10 of 45 headers resolve to a live order
;;; via CONTEXT_ID → DOD_ORDER.CONTEXT_ID, the other 35 being standalone POS-style invoices. It is left in
;;; the report function below, read-only, so the next session can still see the shape of the population
;;; without acting on it.)
;;;
;;; NOT ENFORCED YET, ON PURPOSE AND RECORDED. This migration creates the STATE and the AUDIT TRAIL; no
;;; write guard consults INVOICE_LOCKED yet, so `!update` on a locked invoice still succeeds. The lock
;;; is honest about that (see the slot's documentation in nst-dal-invh.lisp) rather than presenting a
;;; button as a control. The enforcement slice is US-003's unfinished half — "frozen from the order"
;;; where the frozen values can actually be rewritten through PUT /invoices/{id}/items/{item-id} — and
;;; it belongs in nst-invh / nst-invitm's `!update`, refusing rather than stripping, the way
;;; *ordh-never-writable-fields* refuses on the order side. Ledgered: PENDING-WORK-CONTEXT.md §17.
;;;
;;; REGISTER IT in the `*migrations*` list in hhub/core/nst-sch-mig.lisp. The helpers used below
;;; (`add-column-if-absent`) live THERE and not in this file — an upgrade file is loaded by
;;; `load-upgrade-files` AFTER nst-sch-mig.lisp, so a local copy would silently win over the canonical
;;; one (the trap that made the first ABAC seed shadow `insert-auth-policy`).
;;;
;;; 🚨 THE OPERATOR ACCOUNT NEEDS `ALTER` **AND** `INDEX` (and here, `UPDATE`). Measured on the previous
;;; migration: `hhubadmin` held ALTER but not INDEX, and the failure surfaced only after half the file had
;;; run, because `apply-migrations` catches PER-MIGRATION and continues without recording the version.
;;; `add-column-if-absent` makes the retry a no-op instead of Error 1060. This file creates NO index.

(in-package :nstores)

(defun migrate-2026Oct-invoice-lock ()
  "The vendor's edit lock on an invoice: the STATE and the AUDIT TRAIL, and no data change at all.

   All four columns are additive; only INVOICE_LOCKED is NOT NULL, and its DEFAULT is 'N' — so the 45
   existing headers keep working untouched, every one of them reading 'open ended', which is the
   requester's ruling. Idempotent by construction: only `add-column-if-absent` is called, and it is a
   no-op on a second run (MySQL 8 has no ADD COLUMN IF NOT EXISTS, so an unguarded re-run would be Error
   1060 and — because apply-migrations catches per-migration and continues — would leave the version
   unrecorded and this file re-running forever).

   WHICH DEFAULT A NEW INVOICE GETS IS NOT DECIDED HERE. It is the vendor's setting, read by
   `invh-lock-order-derived-invoices-p` in the junction (nst-bl-invhapi.lisp §9): an invoice derived from
   an order is locked at birth only when that vendor asked for it."
  (when (table-exists-p "DOD_INVOICE_HEADER")
    (add-column-if-absent "DOD_INVOICE_HEADER" "INVOICE_LOCKED"
                          "char(1) NOT NULL DEFAULT 'N' COMMENT 'Y = changes to this invoice are not authorised by the vendor. Set at birth by the junction ONLY if the vendor setting asks for it; never by a client.'")
    (add-column-if-absent "DOD_INVOICE_HEADER" "UNLOCKED_BY_USER_ID"
                          "mediumint DEFAULT NULL COMMENT 'DOD_USERS row that last unlocked or re-locked; usually NULL because a vendor session sets no :login-user'")
    (add-column-if-absent "DOD_INVOICE_HEADER" "UNLOCKED_BY_VENDOR_ID"
                          "mediumint DEFAULT NULL COMMENT 'DOD_VEND_PROFILE row that last unlocked or re-locked; taken from the session, never a payload'")
    (add-column-if-absent "DOD_INVOICE_HEADER" "UNLOCKED_AT"
                          "timestamp NULL DEFAULT NULL COMMENT 'when the lock last changed; NULL = never touched. Read INVOICE_LOCKED for the state itself'"))
  (migrate-2026Oct-invoice-lock-report)
  (format t "  invoice lock columns done (no row locked - the vendor setting decides)~%"))

(defun migrate-2026Oct-invoice-lock-report ()
  "NOT a migration — a READ-ONLY census, called by the migration so the run's log shows the population
   rather than only the DDL. It exists because the withdrawn backfill's question is still worth being able
   to answer by eye: how many invoices came from an order, and how many are locked.

   ⚠ THIS MUST STAY READ-ONLY. It is called from inside a migration, so a write here would be a write
   nobody declared — and the whole point of the requester's ruling is that no existing invoice's lock
   state is changed by this file.
   ⚠ `=` NOT `<=>`, so a NULL CONTEXT_ID cannot match a NULL order's CONTEXT_ID — the NULL-safe operator
   would report every context-less invoice as order-derived."
  (let ((order-derived (first (first (clsql:query "SELECT COUNT(*) FROM DOD_INVOICE_HEADER h
                                                    WHERE h.CONTEXT_ID IS NOT NULL
                                                      AND EXISTS (SELECT 1 FROM DOD_ORDER o
                                                                   WHERE o.CONTEXT_ID = h.CONTEXT_ID
                                                                     AND o.TENANT_ID  = h.TENANT_ID
                                                                     AND o.DELETED_STATE = 'N')")))))
    (format t "  ~D invoice header(s), ~D of them resolving to a live order~%"
            (first (first (clsql:query "SELECT COUNT(*) FROM DOD_INVOICE_HEADER")))
            order-derived))
  (dolist (row (clsql:query "SELECT INVOICE_LOCKED, COUNT(*) FROM DOD_INVOICE_HEADER GROUP BY INVOICE_LOCKED"))
    (format t "  INVOICE_LOCKED ~A : ~D invoice(s)~%" (first row) (second row))))
