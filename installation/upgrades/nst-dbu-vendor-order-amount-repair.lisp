;; -*- mode: common-lisp; coding: utf-8 -*-
;;; nst-dbu-vendor-order-amount-repair.lisp
;;;
;;; DOD_VENDOR_ORDERS.ORDER_AMT was over-stated on any order holding a line of qty > 1 that carried tax:
;;; calculate-order-item-cost returned a PER-UNIT price with the whole LINE's tax already added, and
;;; save-vendor-orders-in-db multiplied that by PRD_QTY a second time — inflating the vendor's amount by
;;; (qty-1) x that line's tax. Order 503 is the measured case: 7006.71 stored against a true 6832.87, the
;;; excess 173.84 being exactly 2 x 86.92 on a three-quantity line.
;;;
;;; The ORDER header was always right (it sums TOTALITEMVAL over its lines), which is why the customer's
;;; Place Order page and the vendor's order page disagreed on the same order.
;;;
;;; Re-derived from DOD_ORDER_ITEMS rather than by re-running the old formula: the vendor's live lines'
;;; TOTALITEMVAL is the same figure the fixed calculate-order-item-cost now produces. Lines of qty 1 and
;;; untaxed lines were already right and do not move.
;;;
;;; 🚨 THE `line_total > 0` GUARD IS LOAD-BEARING. The pre-2026 demo orders DO have live item rows, but
;;; those rows still carry TOTALITEMVAL 0.00 (the column was added later and never backfilled), so their
;;; "line total" is 0 — and without this guard the repair would read that as "the vendor's amount should be
;;; 0" and ZERO 371 demo rows. A row with no line totals has nothing to re-derive from and must be left
;;; alone: an un-derivable row is not a row that should be zero.
;;;
;;; REGISTER IT in the `*migrations*` list in hhub/core/nst-sch-mig.lisp (already done). An upgrade file is
;;; deliberately in NEITHER build list — load-upgrade-files compiles it from disk by name — so the
;;; reader-balance check in aiharness/deepseek/tools/nst-preflight.lisp is its only structural check.

(in-package :nstores)

(defun migrate-2026Oct-vendor-order-amount-repair ()
  "Set DOD_VENDOR_ORDERS.ORDER_AMT to the vendor's own live line totals where the old per-unit x qty
   formula over-stated it. Idempotent: it reads only the rows that still disagree and prints each change,
   so a partial run is visible rather than silent. One UPDATE per row, keyed on ROW_ID."
  (let ((rows (clsql:query
               (concatenate 'string
                 "SELECT vo.ROW_ID, vo.ORDER_ID, vo.VENDOR_ID, vo.ORDER_AMT, x.line_total "
                 "FROM DOD_VENDOR_ORDERS vo JOIN "
                 "  (SELECT ORDER_ID, VENDOR_ID, ROUND(SUM(TOTALITEMVAL),2) AS line_total "
                 "     FROM DOD_ORDER_ITEMS WHERE DELETED_STATE='N' GROUP BY ORDER_ID, VENDOR_ID) x "
                 "  ON x.ORDER_ID = vo.ORDER_ID AND x.VENDOR_ID = vo.VENDOR_ID "
                 "WHERE vo.DELETED_STATE='N' AND x.line_total > 0 "
                 "  AND ABS(vo.ORDER_AMT - x.line_total) > 0.009"))))
    (if (null rows)
        (format t "  every vendor order amount already equals its own line totals - nothing to repair~%")
        (dolist (row rows)
          (destructuring-bind (row-id order-id vendor-id old-amt line-total) row
            (clsql:execute-command
             (format nil "UPDATE DOD_VENDOR_ORDERS SET ORDER_AMT = ~A WHERE ROW_ID = ~D" line-total row-id))
            (format t "  vendor order ~D (order ~D, vendor ~D): ~A -> ~A~%"
                    row-id order-id vendor-id old-amt line-total)))))
  (values))
