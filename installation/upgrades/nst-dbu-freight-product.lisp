;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-freight-product.lisp
;;;
;;; One 'Freight & Shipping charges' product row per live vendor, so the ord→inv conversion can put the
;;; order's delivery charge on the invoice AS A LINE. Why it has to be a row at all:
;;;
;;;   * DOD_INVOICE_ITEMS.PRD_ID has a live FK to DOD_PRD_MASTER (DOD_INVOICE_ITEMS_ibfk_2);
;;;   * DOD_INVOICE_HEADER has NO shipping column, and every printed invoice total is computed from the
;;;     ITEMS (`calculate-invoice-totalaftertax` etc.), so a header-only freight amount would never print.
;;;
;;; 🚨 THE RATE ON THAT LINE DOES NOT COME FROM THIS ROW. The delivery charge is ancillary to the supply of
;;; goods — a COMPOSITE SUPPLY taxed at the PRINCIPAL supply's rate (Section 2(30) with Section 8 CGST) —
;;; so the conversion takes the rate from the goods lines and ignores the SAC's own. That is also why SAC
;;; 9965 having NO row in DOD_GST_HSN_CODES (measured) is harmless here, and why nobody should "fix" it by
;;; adding a 9965 rate: it would be the wrong rate for the goods it accompanies. The full GST reasoning,
;;; the alternatives and what a CA must confirm are `aiharness/deepseek/skills/knowledge/gst-gstr-compliance-CONTEXT.md` §10.
;;;
;;; The row is PRD_TYPE 'SERV' (the value the tree already uses for services), priced 0.00 because the
;;; charge is set per invoice, and coded FREIGHT-<vendor-id> — PRODUCT_CODE carries a UNIQUE index, so the
;;; code is both the key this migration is idempotent on and the lookup the conversion uses.
;;;
;;; REGISTER IT in the `*migrations*` list in hhub/core/nst-sch-mig.lisp (already done). An upgrade file is
;;; deliberately in NEITHER build list — load-upgrade-files compiles it from disk by name — so the
;;; reader-balance check in aiharness/deepseek/tools/nst-preflight.lisp is its only structural check.

(in-package :nstores)

(defparameter *freight-product-name* "Freight & Shipping charges"
  "The invoice LINE's description: what the customer reads on the printed tax invoice, and what the
   order page already calls it to them. Keep it short — DOD_PRD_MASTER.PRD_NAME is varchar(70).")

(defparameter *freight-product-hsn* "9965"
  "SAC 9965 (goods transport services), shown as the line's HSN. The RATE is not read from it — see the
   file header: a composite supply takes the principal supply's rate.")

(defun migrate-2026Oct-freight-product-per-vendor ()
  "Seed one delivery-charge product per LIVE vendor, idempotent on PRODUCT_CODE = FREIGHT-<vendor-id>.
   Prints a line per vendor, inserted or skipped, so a partial run is visible rather than silent."
  (dolist (row (clsql:query "SELECT ROW_ID, TENANT_ID FROM DOD_VEND_PROFILE WHERE DELETED_STATE IS NULL OR DELETED_STATE <> 'Y'"))
    (let* ((vendor-id (first row))
           (tenant-id (second row))
           (code (format nil "FREIGHT-~D" vendor-id)))
      (if (clsql:query (format nil "SELECT ROW_ID FROM DOD_PRD_MASTER WHERE PRODUCT_CODE = '~A' LIMIT 1"
                               (sql-literal code)))
          (format t "  freight product ~A already exists - skipping~%" code)
          (progn
            (clsql:execute-command
             (format nil "INSERT INTO DOD_PRD_MASTER
                            (PRODUCT_CODE, PRD_NAME, DESCRIPTION, HSN_CODE, QTY_PER_UNIT, UNIT_OF_MEASURE,
                             CURRENT_PRICE, CURRENT_DISCOUNT, PRD_TYPE, APPROVED_FLAG, ACTIVE_FLAG,
                             DELETED_STATE, VENDOR_ID, TENANT_ID)
                          VALUES
                            ('~A', '~A', '~A', '~A', '1.0', 'NOS', 0.00, 0.00, 'SERV', 'Y', 'Y', 'N', ~D, ~D)"
                      (sql-literal code)
                      (sql-literal *freight-product-name*)
                      (sql-literal "Delivery charges on an order; taxed with the goods it accompanies.")
                      (sql-literal *freight-product-hsn*)
                      vendor-id tenant-id))
            (format t "  inserted freight product ~A for vendor ~D (tenant ~D)~%" code vendor-id tenant-id))))))
