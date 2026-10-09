;;; nst-verify-invoice-from-order.lisp — exercise invoice-from-ord against the real database,
;;; offline, with no web server and no live image.
;;;
;;;   XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --noinform --non-interactive --load <this file>
;;;
;;; Exit 0 = pass, 1 = a check failed, 2 = setup or fixture problem.
;;; The four things that block a scratch load, and the one-time writable clsql dist, are
;;; nst-verify-invoice-offline.lisp's §"FOUR THINGS THAT BLOCK THIS" — read that first.
;;;
;;; ⚠ IT WRITES AND THEN UNDOES. It invoices a REAL fulfilled order (485 by default), asserts
;;; the rows, then hard-deletes the invoice it made and restores the order's three link columns.
;;; Both fixture orders must be un-invoiced to start, or it refuses with exit 2 rather than
;;; guessing: a second invoice for one order is the very fact this feature exists to prevent.

(load "~/quicklisp/setup.lisp")
(push "/home/ubuntu/ninestores/hhub/" asdf:*central-registry*)
(push #p"/tmp/nst-asdf/clsql-dist/clsql-20221106-git/" asdf:*central-registry*)
(ql:quickload :swank :silent t)
(dolist (s '(:uuid :secure-random :drakma :cl-json :cl-who :hunchentoot :clsql
             :clsql-mysql :cl-smtp :parenscript :cl-async :cl-csv :cl-base64
             :priority-queue :blackbird :cl-yaml))
  (ql:quickload s :silent t))
(ql:quickload :nstores :silent t)
(in-package :nstores)

(defparameter *pass* 0)
(defparameter *fail* 0)
(defparameter *skip* 0)

(defun chk (name got want)
  (if (equal got want)
      (progn (incf *pass*) (format t "~&  PASS ~A~%" name))
      (progn (incf *fail*)
             (format t "~&  FAIL ~A~%        got  ~S~%        want ~S~%" name got want))))

(defun chk-true (name thunk)
  (handler-case (if (funcall thunk)
                    (progn (incf *pass*) (format t "~&  PASS ~A~%" name))
                    (progn (incf *fail*) (format t "~&  FAIL ~A -> NIL~%" name)))
    (error (c) (incf *fail*) (format t "~&  FAIL ~A -> signalled ~A~%" name c))))

(defun skip (name why)
  (incf *skip*) (format t "~&  SKIP ~A — ~A~%" name why))

(defun sql-quote (value)
  "VALUE as a SQL literal; NIL is NULL. Only the quote character needs escaping here."
  (if (null value)
      "NULL"
      (with-output-to-string (s)
        (write-char #\' s)
        (loop for ch across (princ-to-string value)
              do (write-char ch s)
                 (when (char= ch #\') (write-char #\' s)))
        (write-char #\' s))))

(defun sql1 (sql)
  "The FIRST COLUMN of the first row of SQL as a STRING, or NIL when there is no row.
   As a string on purpose: clsql answers COUNT(*) as an INTEGER and a DECIMAL as a string,
   so a check comparing raw values would fail on the type rather than on the fact."
  (let ((row (car (clsql:query sql))))
    (and row (first row) (princ-to-string (first row)))))

(defun exec (sql) (clsql:execute-command sql))

;;; ── the fixture ──────────────────────────────────────────────────────────────

(defparameter *ordnum-happy* "ORD-DEMO-2026-27-3MZ6YN"
  "Order 485: ORDER_FULFILLED 'Y', vendor 1 holds a row, 6 live lines — the व्यंजन path.")

(defparameter *ordnum-unfulfilled* "ORD-GCUST837-2026-27-Q33NZS"
  "Order 493: ORDER_FULFILLED 'N', vendor 1 holds a row with 1 line — the refusal, then लोप ३.")

(defparameter *ordnum-freight* "ORD-GCUST837-2026-27-G98U4T"
  "Order 488: fulfilled, vendor 1 holds a row with 1 line, and the order charges 40.00 delivery —
   the composite-supply case (Section 8): the freight line takes the GOODS' rate, not its SAC's.")

(defun order-row (ordnum)
  "The fixture's row as (ROW_ID ORDER_TYPE ORDER_FULFILLED IS_CONVERTED INVOICE_NUMBER)."
  (car (clsql:query
        (format nil "SELECT ROW_ID, ORDER_TYPE, ORDER_FULFILLED, IS_CONVERTED_TO_INVOICE, INVOICE_NUMBER FROM DOD_ORDER WHERE ORDNUM=~A"
                (sql-quote ordnum)))))

(defun restore-order-link (ordnum row)
  "Put ROW's link columns and ORDER_TYPE back the way the fixture had them."
  (exec (format nil "UPDATE DOD_ORDER SET IS_CONVERTED_TO_INVOICE=~A, INVOICE_NUMBER=NULL, INVOICE_DATE=NULL, ORDER_TYPE=~A WHERE ORDNUM=~A"
                (sql-quote (and (fourth row) (fourth row)))
                (sql-quote (second row))
                (sql-quote ordnum))))

(defun drop-invoice (invnum)
  "Hard-delete an invoice this tool created, lines first (there is no FK to cascade here)."
  (when invnum
    (exec (format nil "DELETE FROM DOD_INVOICE_ITEMS WHERE INVHEADID IN (SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A)"
                  (sql-quote invnum)))
    (exec (format nil "DELETE FROM DOD_INVOICE_HEADER WHERE INVNUM=~A" (sql-quote invnum)))))

(defun call-from-ord (ordnum)
  "The route, in-process, exactly as the vendor's UI controller will call it."
  (dispatch-route2 'route-invh-from-ord (list :ordnum ordnum) :raw t))

;;; ── setup ────────────────────────────────────────────────────────────────────

(crm-db-connect :strdb "hhubdb" :strusr "hhubuser" :strpwd "Welcome$123"
                :servername "127.0.0.1" :strdbtype :mysql)
(format t "~&connected.~%")

;; The server context never ran here, so the two globals the junction reads are set by hand.
(setf *NSTGSTSTATECODES-HT* (init-gst-statecodes))
(setf *action-route-company-override* (select-company-by-id 2))
(setf *invh-from-ord-vendor-override* (select-vendor-by-id 1))

(format t "~&=== 0. setup and the fixture's prior state ===~%")
(chk "the state-code table resolves a NAME to a code" (invh-state-code-of "Karnataka") "29")
  (chk "a CODE passes through untouched" (nst-gst-state-code-of "29") "29")
  (chk "a GSTIN yields its state code" (nst-gst-state-code-of "29ALSKDKJADS455") "29")
  (chk "🚨 THE CART'S BUG CASE: the customer's typed NAME and the vendor's stored CODE are ONE state"
       (nst-same-gst-state-p "Karnataka" "29") t)
  (chk "the same, through the cart's actual casing" (nst-same-gst-state-p "KARNATAKA" "29") t)
  (chk "the hash's suffixed spelling still matches the plain name"
       (nst-same-gst-state-p "ANDHRA PRADESH (NEWLY ADDED)" "Andhra Pradesh") t)
  (chk "punctuation and spacing do not decide tax" (nst-same-gst-state-p "andhra-pradesh" "ANDHRA PRADESH") t)
  (chk "two different states are NOT the same" (nst-same-gst-state-p "Karnataka" "Maharashtra") nil)
  (chk "an unresolvable state is NEITHER same nor different — never evidence of another state"
       (nst-same-gst-state-p "Karnatak" "29") nil)
(chk "the state-code table passes a CODE through" (invh-state-code-of "29") "29")
(chk "the seller's state code is readable on vendor 1" (invh-seller-state-code *invh-from-ord-vendor-override*) "29")
(chk "the override vendor is the one the fixture needs" (slot-value *invh-from-ord-vendor-override* 'row-id) 1)

(let ((happy (order-row *ordnum-happy*))
      (unfulfilled (order-row *ordnum-unfulfilled*))
      (freightfx (order-row *ordnum-freight*)))
  (cond
    ((null happy) (format t "~&SETUP PROBLEM: order ~A is not in DOD_ORDER~%" *ordnum-happy*) (sb-ext:exit :code 2))
    ((equal (fourth happy) "Y") (format t "~&SETUP PROBLEM: order ~A is ALREADY invoiced (~A) — restore it before running this~%" *ordnum-happy* (fifth happy)) (sb-ext:exit :code 2))
    ((null unfulfilled) (format t "~&SETUP PROBLEM: order ~A is not in DOD_ORDER~%" *ordnum-unfulfilled*) (sb-ext:exit :code 2))
    ((null freightfx) (format t "~&SETUP PROBLEM: order ~A is not in DOD_ORDER~%" *ordnum-freight*) (sb-ext:exit :code 2))
    ((equal (fourth freightfx) "Y") (format t "~&SETUP PROBLEM: order ~A is ALREADY invoiced (~A)~%" *ordnum-freight* (fifth freightfx)) (sb-ext:exit :code 2))
    (t
     (chk "the freight fixture is fulfilled" (third freightfx) "Y")
     (chk "the happy-path fixture is fulfilled" (third happy) "Y")
     (chk "the happy-path fixture is SALE (physical)" (second happy) "SALE")
     (chk "the refusal fixture is unfulfilled" (third unfulfilled) "N")
     (let ((invnum nil)
           (freightinvnum nil))
       (unwind-protect
            (progn

              (format t "~&=== 1. THE TRANSFORM — invoice-from-ord on a fulfilled physical order ===~%")
              (let ((resp (call-from-ord *ordnum-happy*)))
                (chk "the route answers an invoice" (type-of resp) 'NstInvhResponseModel)
                (when (typep resp 'NstInvhResponseModel)
                  (setf invnum (invnum resp))
                  (chk-true "it carries a minted number" (lambda () (and invnum (plusp (length invnum)) t)))
                  (chk "it is a DRAFT" (status resp) "DRAFT")
                  (chk "its total is the vendor's own line total" (float (totalvalue resp)) 1986.45)
                  (chk "it names the seller" (vendor-id resp) 1)

                  (format t "~&=== 2. WHAT LANDED IN THE DATABASE ===~%")
                  (chk "the header row exists, DRAFT, this tenant"
                       (sql1 (format nil "SELECT CONCAT(STATUS,'/',TENANT_ID,'/',VENDOR_ID) FROM DOD_INVOICE_HEADER WHERE INVNUM=~A"
                                     (sql-quote invnum)))
                       "DRAFT/2/1")
                  (chk "the seller's state code is on the header"
                       (sql1 (format nil "SELECT STATECODE FROM DOD_INVOICE_HEADER WHERE INVNUM=~A" (sql-quote invnum)))
                       "29")
                  (chk "the place of supply is resolved"
                       (sql1 (format nil "SELECT PLACEOFSUPPLY FROM DOD_INVOICE_HEADER WHERE INVNUM=~A" (sql-quote invnum)))
                       "29")
                  (chk-true "custname is filled in (NOT NULL column)"
                            (lambda () (let ((v (sql1 (format nil "SELECT CUSTNAME FROM DOD_INVOICE_HEADER WHERE INVNUM=~A" (sql-quote invnum)))))
                                         (and (stringp v) (plusp (length v))))))
                  (chk "the number the ORDER carries is the number the TABLE stores — a DB-side trigger re-derives INVNUM, so the verb's minted one is fiction"
                       (sql1 (format nil "SELECT (SELECT INVOICE_NUMBER FROM DOD_ORDER WHERE ORDNUM=~A) = (SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE INVNUM=~A)" (sql-quote *ordnum-happy*) (sql-quote invnum)))
                       "1")
                  (chk "the order's context-id is carried as the correlation (VNUM is varchar(20) and TRUNCATES an ORDNUM)"
                       (sql1 (format nil "SELECT CONTEXT_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A" (sql-quote invnum)))
                       (sql1 (format nil "SELECT CONTEXT_ID FROM DOD_ORDER WHERE ORDNUM=~A" (sql-quote *ordnum-happy*))))
                  (chk "and VNUM was NOT used — a truncated order number is a false reference"
                       (sql1 (format nil "SELECT IFNULL(VNUM,'NULL') FROM DOD_INVOICE_HEADER WHERE INVNUM=~A" (sql-quote invnum)))
                       "NULL")
                  (chk "one line per live order line of this vendor" 
                       (sql1 (format nil "SELECT COUNT(*) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A)" (sql-quote invnum)))
                       "6")
                  (chk "the lines total the vendor row's own ORDER_AMT — the whole point"
                       (sql1 (format nil "SELECT CAST(SUM(TOTALITEMVAL) AS CHAR) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A)" (sql-quote invnum)))
                       (sql1 "SELECT CAST(ORDER_AMT AS CHAR) FROM DOD_VENDOR_ORDERS WHERE ORDER_ID=485 AND VENDOR_ID=1"))
                  (chk "every line carries a UOM and an HSN code (NOT NULL columns)"
                       (sql1 (format nil "SELECT COUNT(*) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A) AND (UOM IS NULL OR HSNCODE IS NULL OR PRDDESC IS NULL)" (sql-quote invnum)))
                       "0")
                  (chk "a line's discount is the order's PERCENT, not an amount"
                       (sql1 (format nil "SELECT CAST(CONCAT(DISCOUNT,'/',PRICE,'/',QTY) AS CHAR) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A) AND PRD_ID=16" (sql-quote invnum)))
                       "5.00/250.00/1")
                  (chk "and its taxable value is qty × price × (1 − disc/100)"
                       (sql1 (format nil "SELECT CAST(TAXABLE_VALUE AS CHAR) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A) AND PRD_ID=16" (sql-quote invnum)))
                       "237.50")

                  (format t "~&=== 3. THE ORDER NOW KNOWS — the three link columns ===~%")
                  (chk "IS_CONVERTED_TO_INVOICE is Y"
                       (sql1 (format nil "SELECT IS_CONVERTED_TO_INVOICE FROM DOD_ORDER WHERE ORDNUM=~A" (sql-quote *ordnum-happy*)))
                       "Y")
                  (chk "INVOICE_NUMBER holds the invoice's number"
                       (sql1 (format nil "SELECT INVOICE_NUMBER FROM DOD_ORDER WHERE ORDNUM=~A" (sql-quote *ordnum-happy*)))
                       invnum)
                  (chk-true "INVOICE_DATE is set"
                            (lambda () (let ((v (sql1 (format nil "SELECT INVOICE_DATE FROM DOD_ORDER WHERE ORDNUM=~A" (sql-quote *ordnum-happy*)))))
                                         (and (stringp v) (plusp (length v))))))

                  (format t "~&=== 4. ONE ORDER, ONE INVOICE — the duplicate is refused ===~%")
                  (let ((again (call-from-ord *ordnum-happy*)))
                    (chk "a second call answers 409" (type-of again) 'nst-response-contradiction))
                  (chk "and no second invoice row exists for that order — one order, one invoice"
                       (sql1 (format nil "SELECT COUNT(*) FROM DOD_INVOICE_HEADER WHERE CONTEXT_ID=(SELECT CONTEXT_ID FROM DOD_ORDER WHERE ORDNUM=~A) AND DELETED_STATE='N'" (sql-quote *ordnum-happy*)))
                       "1")))

              (format t "~&=== 4b. THE DELIVERY CHARGE — composite supply, taxed at the goods' rate ===~%")
              (chk "the fixture order charges delivery (40.00)"
                   (sql1 "SELECT CAST(SHIPPING_COST AS CHAR) FROM DOD_ORDER WHERE ROW_ID=488") "40.00")
              (chk "every vendor has a FREIGHT product to bill it under"
                   (sql1 "SELECT COUNT(*) FROM DOD_PRD_MASTER WHERE PRODUCT_CODE='FREIGHT-1' AND DELETED_STATE<>'Y'") "1")
              (chk "the line's rate rule: the highest-value GOODS line sets it"
                   (invh-principal-rate-triple (list (list :taxable-value 92.15 :cgstrate 0.0 :sgstrate 0.0 :igstrate 0.0)
                                                     (list :taxable-value 1140.0 :cgstrate 9.0 :sgstrate 9.0 :igstrate 0.0)))
                   (list 9.0 9.0 0.0))
              (let ((resp (call-from-ord *ordnum-freight*)))
                (chk "the freight order answers an invoice" (type-of resp) 'NstInvhResponseModel)
                (when (typep resp 'NstInvhResponseModel)
                  (setf freightinvnum (invnum resp))
                  (chk "it has the goods line AND the delivery line"
                       (sql1 (format nil "SELECT COUNT(*) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A)" (sql-quote freightinvnum)))
                       "2")
                  ;; ⚠ A LEGACY CHARGE IS INCLUSIVE: this order collected 40.00 with NO tax on it, so the
                  ;; line's taxable value is 40.00 / 1.18 = 33.90 and the tax is the 6.10 inside it — the
                  ;; invoice then bills exactly what the order charged instead of exceeding it.
                  (chk "the delivery line is the vendor's FREIGHT product, quantity 1, priced NET of the tax inside the legacy charge"
                       (sql1 (format nil "SELECT CAST(CONCAT(PRD_ID,'/',PRDDESC,'/',QTY,'/',PRICE) AS CHAR) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A) AND PRD_ID=189" (sql-quote freightinvnum)))
                       "189/Freight & Shipping charges/1/33.90")
                  (chk "and the line still totals the 40.00 the order actually charged"
                       (sql1 (format nil "SELECT CAST(TOTALITEMVAL AS CHAR) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A) AND PRD_ID=189" (sql-quote freightinvnum)))
                       "40.00")
                  (chk "🚨 SO THE INVOICE TOTAL EQUALS THE ORDER'S OWN TOTAL — lines plus its untaxed delivery charge"
                       (sql1 (format nil "SELECT CAST(h.TOTALVALUE AS CHAR) = CAST(ROUND((SELECT IFNULL(SUM(i.TOTALITEMVAL),0) FROM DOD_ORDER_ITEMS i WHERE i.ORDER_ID=488 AND i.DELETED_STATE='N') + (SELECT SHIPPING_COST FROM DOD_ORDER WHERE ROW_ID=488), 2) AS CHAR) FROM DOD_INVOICE_HEADER h WHERE h.INVNUM=~A" (sql-quote freightinvnum)))
                       "1")
                  (chk "its HSN is the SAC, its discount zero"
                       (sql1 (format nil "SELECT CAST(CONCAT(HSNCODE,'/',DISCOUNT) AS CHAR) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A) AND PRD_ID=189" (sql-quote freightinvnum)))
                       "9965/0.00")
                  (chk "🚨 ITS RATE IS THE GOODS' RATE, not SAC 9965's (which has no rate at all)"
                       (sql1 (format nil "SELECT (SELECT CAST(CONCAT(CGSTRATE,'/',SGSTRATE,'/',IGSTRATE) AS CHAR) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A) AND PRD_ID=189) = (SELECT CAST(CONCAT(CGSTRATE,'/',SGSTRATE,'/',IGSTRATE) AS CHAR) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A) AND PRD_ID<>189 ORDER BY TAXABLE_VALUE DESC LIMIT 1)" (sql-quote freightinvnum) (sql-quote freightinvnum)))
                       "1")
                  (chk "and its tax is the charge at that rate, to the paise"
                       (sql1 (format nil "SELECT (CAST(CGSTAMT AS CHAR) = CAST(ROUND(TAXABLE_VALUE*CGSTRATE/100,2) AS CHAR)) AND (CAST(SGSTAMT AS CHAR) = CAST(ROUND(TAXABLE_VALUE*SGSTRATE/100,2) AS CHAR)) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A) AND PRD_ID=189" (sql-quote freightinvnum)))
                       "1")
                  (chk "the invoice total is the goods PLUS the delivery charge and its tax"
                       (sql1 (format nil "SELECT (CAST(h.TOTALVALUE AS CHAR) = CAST((SELECT SUM(i.TOTALITEMVAL) FROM DOD_INVOICE_ITEMS i WHERE i.INVHEADID=h.ROW_ID) AS CHAR)) FROM DOD_INVOICE_HEADER h WHERE h.INVNUM=~A" (sql-quote freightinvnum)))
                       "1")
                  (chk "so the total is 40.00 above the goods alone"
                       (sql1 (format nil "SELECT CAST(h.TOTALVALUE - (SELECT SUM(i.TOTALITEMVAL) FROM DOD_INVOICE_ITEMS i WHERE i.INVHEADID=h.ROW_ID AND i.PRD_ID<>189) AS CHAR) FROM DOD_INVOICE_HEADER h WHERE h.INVNUM=~A" (sql-quote freightinvnum)))
                       (sql1 (format nil "SELECT CAST(TOTALITEMVAL AS CHAR) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A) AND PRD_ID=189" (sql-quote freightinvnum))))))

              (format t "~&=== 5. व्यंजन संधि — an unfulfilled PHYSICAL order is refused ===~%")
              (let ((resp (call-from-ord *ordnum-unfulfilled*)))
                (chk "the route answers 409" (type-of resp) 'nst-response-contradiction))
              (chk "nothing was written for it"
                   (sql1 (format nil "SELECT IS_CONVERTED_TO_INVOICE FROM DOD_ORDER WHERE ORDNUM=~A" (sql-quote *ordnum-unfulfilled*)))
                   "N")
              (chk-true "the refusal states the plain rule, not a generic error"
                        (lambda () (let ((s (invh-create-from-order
                                             (make-instance 'NstInvhRequestModel
                                                            :params (list :ordnum *ordnum-unfulfilled*))
                                             (make-domain-ctx :tenant (select-company-by-id 2) :channel :agent))))
                                     (and (typep s 'nst-entity-contradiction)
                                          (search "not fulfilled yet" (slot-value s 'reason))))))

              (format t "~&=== 6. लोप ३ — the SAME order as a SERVICE order goes through ===~%")
              (exec (format nil "UPDATE DOD_ORDER SET ORDER_TYPE='SRVC' WHERE ORDNUM=~A" (sql-quote *ordnum-unfulfilled*)))
              (let* ((resp (call-from-ord *ordnum-unfulfilled*))
                     (srvnum (and (typep resp 'NstInvhResponseModel) (invnum resp))))
                (chk "the elided junction answers an invoice" (type-of resp) 'NstInvhResponseModel)
                (when srvnum
                  (chk "it is a DRAFT too" (status resp) "DRAFT")
                  (chk "it has the one line this vendor holds"
                       (sql1 (format nil "SELECT COUNT(*) FROM DOD_INVOICE_ITEMS WHERE INVHEADID=(SELECT ROW_ID FROM DOD_INVOICE_HEADER WHERE INVNUM=~A)" (sql-quote srvnum)))
                       "1")
                  (drop-invoice srvnum)))
              (exec (format nil "UPDATE DOD_ORDER SET ORDER_TYPE='SALE', IS_CONVERTED_TO_INVOICE='N', INVOICE_NUMBER=NULL, INVOICE_DATE=NULL WHERE ORDNUM=~A" (sql-quote *ordnum-unfulfilled*)))
              (chk "the refusal fixture is back to SALE and un-invoiced"
                   (sql1 (format nil "SELECT CONCAT(ORDER_TYPE,'/',IS_CONVERTED_TO_INVOICE) FROM DOD_ORDER WHERE ORDNUM=~A" (sql-quote *ordnum-unfulfilled*)))
                   "SALE/N")

              (format t "~&=== 7. NO SUCH ORDER, and no order number at all ===~%")
              (chk "an unknown number answers 404"
                   (type-of (call-from-ord "ORD-NOPE-2026-27-ZZZZZZ")) 'nst-response-nil)
              (chk-true "an empty :ordnum is a client error, not a create"
                        (lambda () (handler-case (progn (call-from-ord "") nil)
                                     (error () t)))))

         ;; ── the undo, which runs even when a check above blew up ──────────────
         (format t "~&=== 8. UNDO — the invoices are removed and the orders restored ===~%")
         (drop-invoice freightinvnum)
         (restore-order-link *ordnum-freight* freightfx)
         (drop-invoice invnum)
         (restore-order-link *ordnum-happy* happy)
         (chk "no invoice row is left for the fixture order"
              (sql1 (format nil "SELECT COUNT(*) FROM DOD_INVOICE_HEADER WHERE INVNUM=~A" (sql-quote invnum)))
              "0")
         (chk "the happy-path order is un-invoiced again"
              (sql1 (format nil "SELECT CONCAT(IS_CONVERTED_TO_INVOICE,'/',IFNULL(INVOICE_NUMBER,'NULL')) FROM DOD_ORDER WHERE ORDNUM=~A" (sql-quote *ordnum-happy*)))
              "N/NULL")
         (chk "no invoice lines are orphaned"
              (sql1 "SELECT COUNT(*) FROM DOD_INVOICE_ITEMS i LEFT JOIN DOD_INVOICE_HEADER h ON h.ROW_ID=i.INVHEADID WHERE h.ROW_ID IS NULL")
              "0"))))))

(format t "~&~%=== invoice-from-ord: ~A pass, ~A fail, ~A skip ===~%"
        *pass* *fail* *skip*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
