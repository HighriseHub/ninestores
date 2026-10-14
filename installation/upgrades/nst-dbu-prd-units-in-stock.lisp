;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-prd-units-in-stock.lisp
;;;
;;; DOD_PRD_MASTER.UNITS_IN_STOCK is `smallint NULL DEFAULT NULL`, so a product row INSERTed without that
;;; column holds NULL — and NIL then reaches every arithmetic reader of the slot:
;;;
;;;   * `(<= units-in-stock 0)` in product-card-for-vendor signalled `The value NIL is not of type REAL`
;;;     and took the whole vendor product list down (measured 2026-10-13, hunchentoot worker 4367);
;;;   * `(mod units-in-stock 20)` in the customer product page, `(+ units-in-stock diff)` in the order
;;;     page and `(> units-in-stock 0)` in the invoice pages are the same trap, not different bugs.
;;;
;;; THE MEASURED SOURCE was migrate-2026Oct-freight-product-per-vendor: its INSERT column list OMITTED
;;; UNITS_IN_STOCK, so the 20 'Freight & Shipping charges' rows it seeded (vendors 1-19) came out NULL,
;;; ACTIVE_FLAG 'Y' and APPROVED_FLAG 'Y' — straight into the vendor's own product list. That migration
;;; is now corrected to write the column, but it is ALREADY APPLIED in this database
;;; (DOD_SCHEMA_MIGRATIONS row 112, applied_at 2026-10-06 23:45:23), and apply-migrations skips every
;;; version already recorded — so editing it repairs future installs ONLY and can never repair these rows.
;;; That is why this file exists as a separate NEW version: it is the only replayable half.
;;;
;;; 1 IS THE CHOSEN VALUE for the freight row (the user's decision, 2026-10-13): a service line is not
;;; stocked, but the column must carry a number, and 1 is what makes every one of the readers above
;;; behave — 0 would additionally stamp "NO STOCK" on the vendor card.
;;;
;;; 🚨 THIS IS A DATA REPAIR, NOT A SCHEMA CHANGE. It does not alter the column's nullability or default;
;;; a row inserted with the column omitted will still hold NULL afterwards. The remaining writer that can
;;; do that is the products.csv INSERT path (hhub/vendor/dod-ui-ven.lisp, `:units-in-stock
;;; (prd-csv-read-integer ...)` answers NIL for a blank UnitsInStock cell, where the UPDATE path correctly
;;; reads blank as "no change"). Guard that cell too, or this repair comes back.
;;;
;;; REGISTER IT in the `*migrations*` list in hhub/core/nst-sch-mig.lisp (already done). An upgrade file is
;;; deliberately in NEITHER build list — load-upgrade-files compiles it from disk by name — so the
;;; reader-balance check in aiharness/deepseek/tools/nst-preflight.lisp is its only structural check.

(in-package :nstores)

(defparameter *prd-units-in-stock-repair-value* 1
  "The stock value a NULL UNITS_IN_STOCK is repaired to, and the value the freight product is held at.
   A constant rather than two literals so the two statements below cannot drift apart.")

(defun migrate-2026Oct-prd-units-in-stock ()
  "Repair DOD_PRD_MASTER.UNITS_IN_STOCK so NO product row holds NULL, and re-assert the per-vendor freight
   product's stock. Two statements, both idempotent: run it again on a repaired database and it matches
   nothing and says so. Prints every row it moves, so a partial run is visible rather than silent."
  (let ((nulls (clsql:query
                "SELECT ROW_ID, PRODUCT_CODE, PRD_NAME, VENDOR_ID, TENANT_ID
                   FROM DOD_PRD_MASTER WHERE UNITS_IN_STOCK IS NULL ORDER BY ROW_ID")))
    (if (null nulls)
        (format t "  no product row holds a NULL units-in-stock - nothing to repair~%")
        (progn
          (dolist (row nulls)
            (destructuring-bind (row-id product-code prd-name vendor-id tenant-id) row
              (declare (ignore vendor-id tenant-id))
              (format t "  product ~D (~A, ~A): NULL -> ~D~%"
                      row-id (or product-code "no code") prd-name *prd-units-in-stock-repair-value*)))
          (clsql:execute-command
           (format nil "UPDATE DOD_PRD_MASTER SET UNITS_IN_STOCK = ~D WHERE UNITS_IN_STOCK IS NULL"
                   *prd-units-in-stock-repair-value*))
          (format t "  repaired ~D row(s) with a NULL units-in-stock~%" (length nulls)))))
  ;; The freight row again, by its own key: NULL is already covered above, but a freight row that came
  ;; out 0 (or anything else) must also read as the value this repair standardises on, or the two writers
  ;; of that row - this file and migrate-2026Oct-freight-product-per-vendor - would disagree.
  (let ((freight (clsql:query
                  (format nil "SELECT ROW_ID, PRODUCT_CODE, VENDOR_ID, UNITS_IN_STOCK
                                 FROM DOD_PRD_MASTER
                                WHERE PRODUCT_CODE LIKE 'FREIGHT-%' AND UNITS_IN_STOCK <> ~D
                                ORDER BY ROW_ID"
                          *prd-units-in-stock-repair-value*))))
    (if (null freight)
        (format t "  every FREIGHT-% product already reads ~D~%" *prd-units-in-stock-repair-value*)
        (dolist (row freight)
          (destructuring-bind (row-id product-code vendor-id units) row
            (clsql:execute-command
             (format nil "UPDATE DOD_PRD_MASTER SET UNITS_IN_STOCK = ~D WHERE ROW_ID = ~D"
                     *prd-units-in-stock-repair-value* row-id))
            (format t "  freight product ~D (~A, vendor ~D): ~A -> ~D~%"
                    row-id product-code vendor-id units *prd-units-in-stock-repair-value*)))))
  (values))
