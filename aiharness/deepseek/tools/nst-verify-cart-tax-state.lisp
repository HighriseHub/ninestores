;;; nst-verify-cart-tax-state.lisp — the CART's tax jurisdiction, exercised the way the cart calls it.
;;;
;;;   XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --noinform --non-interactive --load <this file>
;;;
;;; Exit 0 = pass, 1 = a check failed. It WRITES NOTHING: every check is a read plus a computation, so
;;; there is no fixture to clean up (contrast nst-verify-invoice-from-order.lisp).
;;;
;;; WHY THIS EXISTS: `create-model-for-custshipmethodspage` computes the cart's GST through
;;; `update-gst-for-order-lineitem` (order/dod-bl-odt.lisp) with the customer's TYPED state and the vendor
;;; row's `state` column — a NAME against a CODE for vendor 1, so a Karnataka-to-Karnataka sale was taxed
;;; INTER-state (order 488 carries IGST 205.20 with CGST/SGST 0.00). This tool drives that exact call and
;;; reads the columns back, so the rule is checked where it runs rather than where it is documented.
;;;
;;; ⚠ THE PAGE GUARDS ARE A LATER STEP: this verifies the RULE. A mistyped state that resolves to nothing
;;; still falls through to interstate HERE (asserted below, so the gap is visible rather than assumed) —
;;; blocking that at the address page is step 3 of the plan in knowledge/gst-tax-jurisdiction-CONTEXT.md §3.

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

(defun money (x) (and x (float (/ (round (* (float x) 100)) 100))))

;;; ── the cart's own call, nothing more ────────────────────────────────────────

(defun cart-tax (product-id qty typed-state vendor-state)
  "Exactly what create-model-for-custshipmethodspage does: a throwaway dod-order-items line, the product,
   BOTH strings upcased, through update-gst-for-order-lineitem — then read the columns off the line."
  (let* ((company (select-company-by-id 2))
         (product (select-product-by-id product-id company))
         (line (make-instance 'dod-order-items :prd-qty qty)))
    (update-gst-for-order-lineitem line product (string-upcase typed-state) (string-upcase vendor-state))
    (list :taxable (money (slot-value line 'taxablevalue))
          :cgstrate (money (slot-value line 'cgst)) :cgstamt (money (slot-value line 'cgstamt))
          :sgstrate (money (slot-value line 'sgst)) :sgstamt (money (slot-value line 'sgstamt))
          :igstrate (money (slot-value line 'igst)) :igstamt (money (slot-value line 'igstamt))
          :total (money (slot-value line 'totalitemval)))))

(defun tax-sum (t3) (money (+ (getf t3 :cgstamt) (getf t3 :sgstamt) (getf t3 :igstamt))))

(crm-db-connect :strdb "hhubdb" :strusr "hhubuser" :strpwd "Welcome$123"
                :servername "127.0.0.1" :strdbtype :mysql)
(format t "~&connected.~%")
(setf *NSTGSTSTATECODES-HT* (init-gst-statecodes))

;;; ── 1. the canonical comparison ──────────────────────────────────────────────

(format t "~&=== 1. one notion of 'the same state' ===~%")
(chk "a NAME resolves to its code" (nst-gst-state-code-of "Karnataka") "29")
(chk "a CODE passes through" (nst-gst-state-code-of "29") "29")
(chk "a GSTIN yields its state code" (nst-gst-state-code-of "29ALSKDKJADS455") "29")
(chk "🚨 THE BUG CASE: the customer's typed NAME vs the vendor's stored CODE is ONE state"
     (nst-same-gst-state-p "Karnataka" "29") t)
(chk "the same through the cart's own upcasing" (nst-same-gst-state-p "KARNATAKA" "29") t)
(chk "the hash's suffixed spelling matches the plain name"
     (nst-same-gst-state-p "ANDHRA PRADESH (NEWLY ADDED)" "Andhra Pradesh") t)
(chk "punctuation and spacing do not decide tax" (nst-same-gst-state-p "andhra-pradesh" "ANDHRA PRADESH") t)
(chk "two different states are NOT the same" (nst-same-gst-state-p "Karnataka" "Maharashtra") nil)
(chk "an unresolvable state is NEITHER same nor different — never evidence of another state"
     (nst-same-gst-state-p "Karnatak" "29") nil)

;;; ── 2. the amounts the cart computes ─────────────────────────────────────────

(format t "~&=== 2. vendor 1 (\"29\") × the Karnataka customer (\"KARNATAKA\") — order 488's own pair ===~%")
(let ((intra (cart-tax 186 1 "KARNATAKA" "29")))
  (format t "~&     taxable ~A | CGST ~A + SGST ~A | IGST ~A | total ~A~%"
          (getf intra :taxable) (getf intra :cgstamt) (getf intra :sgstamt)
          (getf intra :igstamt) (getf intra :total))
  (chk "taxable value is qty × price − 5% discount (1200 × 0.95)" (getf intra :taxable) 1140.0)
  (chk "the rate is the PRODUCT's (HSN 48061000 → 9 + 9)" (list (getf intra :cgstrate) (getf intra :sgstrate))
       (list 9.0 9.0))
  (chk "CGST is charged" (getf intra :cgstamt) 102.6)
  (chk "SGST is charged" (getf intra :sgstamt) 102.6)
  (chk "🚨 NO IGST — this is an intra-state sale" (getf intra :igstamt) 0.0)
  (chk "and the TOTAL is the same as the IGST version, which is why the bug hid in the totals"
       (getf intra :total) 1345.2)
  (chk "the line adds up: taxable + taxes = total" (money (+ (getf intra :taxable) (tax-sum intra)))
       (getf intra :total)))

(format t "~&=== 3. a genuinely INTER-state sale still goes IGST ===~%")
(let ((inter (cart-tax 186 1 "MAHARASHTRA" "29")))
  (format t "~&     taxable ~A | CGST ~A + SGST ~A | IGST ~A | total ~A~%"
          (getf inter :taxable) (getf inter :cgstamt) (getf inter :sgstamt)
          (getf inter :igstamt) (getf inter :total))
  (chk "no CGST" (getf inter :cgstamt) 0.0)
  (chk "no SGST" (getf inter :sgstamt) 0.0)
  (chk "IGST at the product's 18%" (getf inter :igstamt) 205.2)
  (chk "same total" (getf inter :total) 1345.2))

(format t "~&=== 4. vendors 2-3 (\"Karnataka\") — name against name, the case that always worked ===~%")
(chk "still intra-state" (getf (cart-tax 186 1 "KARNATAKA" "KARNATAKA") :igstamt) 0.0)

(format t "~&=== 5. the RATE follows the product, not the state (HSN 0405 → 2.5 + 2.5) ===~%")
(let ((five (cart-tax 60 2 "KARNATAKA" "29")))
  (format t "~&     taxable ~A | CGST ~A + SGST ~A | IGST ~A~%"
          (getf five :taxable) (getf five :cgstamt) (getf five :sgstamt) (getf five :igstamt))
  (chk "taxable is 2 × 610 − 5%" (getf five :taxable) 1159.0)
  (chk "rates are the product's 2.5 + 2.5" (list (getf five :cgstrate) (getf five :sgstrate)) (list 2.5 2.5))
  (chk "charged intra-state" (getf five :cgstamt) 28.98)
  (chk "and no IGST" (getf five :igstamt) 0.0))

;;; ── 6. what the fix does NOT cover, stated rather than assumed ───────────────

(format t "~&=== 6. a MISTYPED state still falls through to IGST — the page guard is step 3 ===~%")
(let ((typo (cart-tax 186 1 "KARNATKA" "29")))
  (format t "~&     a typo yields IGST ~A (was the silent behaviour for EVERY sale)~%" (getf typo :igstamt))
  (chk "the typo is not treated as Karnataka" (getf typo :igstamt) 205.2)
  (chk-true "and the reason is visible: the name resolves to nothing"
            (lambda () (null (nst-gst-state-code-of "Karnatka")))))

;;; ── 6b. MONEY IS TO THE PAISE, not to the float's whim ───────────────────────

(format t "~&=== 6b. a 4-decimal product is rounded to the paise ===~%")
(let ((four (cart-tax 60 3 "KARNATAKA" "29")))
  (format t "~&     taxable ~A | CGST ~A + SGST ~A | total ~A  (2.5% of 1738.50 = 43.4625 unrounded)~%"
          (getf four :taxable) (getf four :cgstamt) (getf four :sgstamt) (getf four :total))
  (chk "the taxable value itself is 2 decimals" (getf four :taxable) 1738.5)
  (chk "CGST is rounded to the paise" (getf four :cgstamt) 43.46)
  (chk "SGST likewise" (getf four :sgstamt) 43.46)
  (chk "and the total is exact from the rounded parts" (getf four :total) 1825.42)
  (chk "so taxable + taxes = the total to the paise"
       (money (+ (getf four :taxable) (tax-sum four))) (getf four :total)))

(format t "~&=== 6c. every amount is a whole number of PAISE ===~%")
(defun paise-p (v)
  "V is the same as its OWN 2-decimal rounding, within half a paisa. Comparing (× 100) to (round (× 100))
   is a false negative on 307.8: its binary double times 100 is 30779.998, three thousandths low."
  (or (null v)
      (< (abs (- (float v) (/ (round (* (float v) 100.0)) 100.0))) 0.005)))
(let ((odd (cart-tax 186 3 "KARNATAKA" "29")))
  (chk "taxable" (getf odd :taxable) 3420.0)
  (chk "CGST" (getf odd :cgstamt) 307.8)
  (chk "SGST" (getf odd :sgstamt) 307.8)
  (chk "IGST" (getf odd :igstamt) 0.0)
  (chk "total" (getf odd :total) 4035.6)
  (dolist (pair (list (cons "taxable" (getf odd :taxable)) (cons "cgst" (getf odd :cgstamt))
                      (cons "sgst" (getf odd :sgstamt)) (cons "igst" (getf odd :igstamt))
                      (cons "total" (getf odd :total))))
    (format t "~&     ~A = ~S  (× 100 = ~S, round = ~S, paise? ~A)~%"
            (car pair) (cdr pair) (* (float (cdr pair)) 100) (round (* (float (cdr pair)) 100))
            (paise-p (cdr pair))))
  (chk-true "no amount has a third decimal"
            (lambda () (every #'paise-p (list (getf odd :taxable) (getf odd :cgstamt)
                                              (getf odd :sgstamt) (getf odd :igstamt) (getf odd :total))))))

;;; ── 6d. the tree's `fround`, which the cart's TOTAL helpers call and the source never defines ──

(format t "~&=== 6d. the two rounders, and which one is the paise one ===~%")
(format t "~&     fround → ~A, its symbol-package ~A (COMMON-LISP: rounds to WHOLE RUPEES)~%     round-to-2-decimal → ~A (the tree's own, in core/dod-bl-utl.lisp)~%"
        (and (fboundp 'fround) t) (symbol-package 'fround) (and (fboundp 'round-to-2-decimal) t))
(chk "the rounder this step uses is callable" (and (fboundp 'round-to-2-decimal) t) t)
(chk "fround is COMMON-LISP's standard one — whole rupees, which is why 6 call sites were wrong"
     (and (fboundp 'fround) t) t)
(chk "and the two are NOT the same function on money" (round-to-2-decimal 3815.20) 3815.2)
(chk "while the standard fround answers whole rupees" (fround 3815.20) 3815.0)

;;; ── 6e. the cart's TOTAL helpers, which used fround (whole rupees) until this step ──

(format t "~&=== 6e. the totals the cart displays are to the paise too ===~%")
(let* ((company (select-company-by-id 2))
       (product (select-product-by-id 60 company))
       (lines (list (let ((l (make-instance 'dod-order-items :prd-qty 3)))
                      (update-gst-for-order-lineitem l product (string-upcase "KARNATAKA") (string-upcase "29"))
                      l)))
       (before (calculate-invoice-totalbeforetax lines))
       (after (calculate-invoice-totalaftertax lines)))
  (format t "~&     before tax ~A | after tax ~A   (standard (fround 1825.42) would answer ~A)~%"
          before after (fround 1825.42))
  (chk "the taxable total is to the paise" before 1738.5)
  (chk "🚨 the after-tax total is to the paise — NOT rounded to whole rupees" after 1825.42)
  (chk-true "and it is not the whole-rupee answer" (lambda () (/= after 1825.0)))
  (chk "taxable + taxes = the total" (round-to-2-decimal (+ before (- after before))) after))

;;; ── 6f. THE DELIVERY CHARGE — the split, the line, and the cart merge ────────
;;;
;;; The requester's own example: goods ₹1000 at 18%, delivery ₹100. EVERY buyer pays the configured
;;; 100.00 — the tax (15.25) sits inside it — and the buyer's registration changes only the PRESENTATION:
;;; B2B gets a delivery LINE it can claim the tax from, B2C reads one simple charge.

(format t "~&=== 6f. the delivery charge: GROSS for every buyer, tax inside it ===~%")
(multiple-value-bind (taxable tax) (nst-shipping-tax-split 100.00 18 :inclusive nil)
  (format t "~&     the PRE-TAX reading (NOT ours): taxable ~A + tax ~A = ~A for the same configured 100~%"
          taxable tax (round-to-2-decimal (+ taxable tax)))
  (chk "the pre-tax reading would charge 118 for a 100 charge — rejected, see the ledger §11" (round-to-2-decimal (+ taxable tax)) 118.0))
(multiple-value-bind (taxable tax) (nst-shipping-tax-split 100.00 18 :inclusive t)
  (format t "~&     OURS: taxable ~A + tax ~A = ~A (the customer pays the charge)~%" taxable tax (round-to-2-decimal (+ taxable tax)))
  (chk "inclusive: the taxable value is back-calculated" taxable 84.75)
  (chk "inclusive: the tax is the remainder" tax 15.25)
  (chk "inclusive: and the two sum to the charge EXACTLY" (round-to-2-decimal (+ taxable tax)) 100.0))
(chk "the B2B signal is the buyer's GSTIN" (and (nst-gstin-present-p "29ALSKDKJADS455") t) t)
(chk "and a blank one is not" (nst-gstin-present-p "  ") nil)

(format t "~&=== 6g. the delivery LINE, both treatments, on the requester's numbers ===~%")
(let* ((company (select-company-by-id 2))
       (tenant-id (slot-value company 'row-id))
       (product (nst-select-freight-product 1 tenant-id))
       (rates (list 9.0 9.0 0.0)))
  (chk "vendor 1's FREIGHT product is there to bill under" (and product t) t)
  (chk "its product code is the one the migration seeds"
       (and product (slot-value product 'product-code)) "FREIGHT-1")
  (let ((b2b (nst-freight-order-line nil 1 product 100.00 rates t)))
    (chk "B2B: the taxable value is the charge NET of the tax inside it (84.75)" (slot-value b2b 'taxablevalue) 84.75)
    (chk "B2B: CGST 7.63" (slot-value b2b 'cgstamt) 7.63)
    (chk "B2B: SGST 7.62 (the residual, so the halves sum to the tax)" (slot-value b2b 'sgstamt) 7.62)
    (chk "B2B: no IGST" (slot-value b2b 'igstamt) 0.0)
    (chk "🚨 B2B: the line totals the 100.00 the vendor configured — the SAME the consumer pays"
         (slot-value b2b 'totalitemval) 100.0))
  (let ((b2c (nst-freight-order-line nil 1 product 100.00 rates nil)))
    (chk "B2C: taxable 84.75" (slot-value b2c 'taxablevalue) 84.75)
    (chk "B2C: the halves sum to the tax exactly (7.63 + 7.62)"
         (round-to-2-decimal (+ (slot-value b2c 'cgstamt) (slot-value b2c 'sgstamt))) 15.25)
    (chk "B2C: the line still totals the 100.00 the customer pays"
         (slot-value b2c 'totalitemval) 100.0)
    (chk "B2C: and it adds up exactly"
         (round-to-2-decimal (+ (slot-value b2c 'taxablevalue)
                                (slot-value b2c 'cgstamt) (slot-value b2c 'sgstamt)))
         (slot-value b2c 'totalitemval))))

(format t "~&=== 6h. the CART merge: one vendor, one charge, and the column zeroed ===~%")
(let* ((company (select-company-by-id 2))
       (goods (list (let ((l (make-instance 'dod-order-items :prd-qty 1 :vendor-id 1)))
                      (setf (slot-value l 'taxablevalue) 1000.00
                            (slot-value l 'cgst) 9.00 (slot-value l 'cgstamt) 90.00
                            (slot-value l 'sgst) 9.00 (slot-value l 'sgstamt) 90.00
                            (slot-value l 'igst) 18.00 (slot-value l 'igstamt) 0.00
                            (slot-value l 'totalitemval) 1180.00)
                      l))))
  (multiple-value-bind (items products amount tax chargeleft)
      (nst-cart-with-delivery-line goods (list :goods-product) 1180.00 180.00 100.00 "29ALSKDKJADS455" company)
    (format t "~&     goods 1000 + 180 | delivery 100 | B2B total ~A | charge left in the column ~A~%"
            amount chargeleft)
    (chk "the cart gains the delivery line" (length items) 2)
    (chk "with its product alongside, for the stock pairing" (length products) 2)
    (chk "the order total is goods + the delivery charge, the tax inside it" amount 1280.0)
    (chk "the tax total includes the delivery's tax (180 + 15.25)" tax 195.25)
    (chk "🚨 and the SHIPPING_COST column drops to 0 — nothing counts the charge twice" chargeleft 0.0)
    (chk "and the gross the PAGES display is the 100.00 every buyer pays"
         (nth-value 5 (nst-cart-with-delivery-line goods (list :goods-product) 1180.00 180.00 100.00 "29ALSKDKJADS455" company))
         100.0))
  ;; the same cart, B2C: NO delivery line (the requester's "easy understanding"), the charge stays a charge
  (multiple-value-bind (items products amount tax chargeleft)
      (nst-cart-with-delivery-line goods (list :goods-product) 1180.00 180.00 100.00 nil company)
    (declare (ignore products))
    (format t "~&     the same cart, B2C: lines ~A | total ~A | tax ~A | charge still a charge ~A~%"
	    (length items) amount tax chargeleft)
    (chk "B2C gets NO delivery line — the customer reads one simple charge" (length items) 1)
    (chk "the lines' total is untouched, so the cart total is goods + the charge" amount 1180.0)
    (chk "the tax is the goods' own — the delivery's tax is taken on the INVOICE" tax 180.0)
    (chk "and the charge stays a CHARGE in SHIPPING_COST" chargeleft 100.0)
    (chk "so the page's total is lines + charge = 1280.00"
	 (round-to-2-decimal (+ amount chargeleft)) 1280.0)
    (chk "while the DISPLAY value is the 100.00 the customer pays"
         (nth-value 5 (nst-cart-with-delivery-line goods (list :goods-product) 1180.00 180.00 100.00 nil company))
         100.0)
    ;; ⚠ THE MONEY IS THE SAME EITHER WAY — that is the point of the split, and the reason the taxes differ
    ;; 🚨 AND THIS IS THE POINT: B2B AND B2C PAY THE SAME 1280.00 — the buyer's registration changes only
    ;; how the delivery is PRESENTED (a line with its tax for the ITC), never the money.
    (chk "🚨 B2C pays 1280.00, exactly what the B2B buyer pays for the same cart"
	 (round-to-2-decimal (+ amount chargeleft)) 1280.0))
  ;; a multi-vendor cart is deliberately left alone until per-vendor shipping lands
  (multiple-value-bind (items products amount tax chargeleft)
      (nst-cart-with-delivery-line (list (make-instance 'dod-order-items :prd-qty 1 :vendor-id 1)
                                         (make-instance 'dod-order-items :prd-qty 1 :vendor-id 2))
                                   (list :a :b) 500.00 50.00 70.00 "29ALSKDKJADS455" company)
    (declare (ignore products))
    (chk "a MULTI-vendor cart is left as it was (per-vendor shipping is its own step)" (length items) 2)
    (chk "and its charge stays in the column" chargeleft 70.0)
    (chk "so its total is unchanged" amount 500.0)))

;;; ── 7. the before/after on the order that exposed it ─────────────────────────

(format t "~&=== 7. order 488's stored line, as the cart wrote it before this fix ===~%")
(let* ((row (car (clsql:query "SELECT i.TAXABLEVALUE, i.CGSTAMT, i.SGSTAMT, i.IGSTAMT, i.TOTALITEMVAL, o.SHIPSTATE FROM DOD_ORDER_ITEMS i JOIN DOD_ORDER o ON o.ROW_ID=i.ORDER_ID WHERE i.ORDER_ID=488 AND i.PRD_ID=186"))))
  (format t "~&     stored: taxable ~A | CGST ~A + SGST ~A | IGST ~A | total ~A (order shipstate ~S)~%"
          (first row) (second row) (third row) (fourth row) (fifth row) (sixth row))
  (chk "the order carries IGST and no CGST/SGST — the defect this step fixes"
       (list (second row) (third row) (and (fourth row) (plusp (read-from-string (fourth row))))) (list "0.00" "0.00" t)))

(format t "~&~%=== cart tax state: ~A pass, ~A fail ===~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
