;;; dod-bl-odt.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)



(defun get-order-items (order-instance)
:documentation "Returns the list of order details instances given order-instance as input"
  ;; ⚠ A NIL ORDER ANSWERS NIL, NOT A MISSING-SLOT ERROR: "the order is not there" used to reach
  ;; the customer's page as a 500 (MEASURED 2026-10-06). No order means no items.
  (when (null order-instance) (return-from get-order-items nil))
  (let ((tenant-id (slot-value order-instance 'tenant-id))
	(order-id (slot-value order-instance 'row-id)))
 (clsql:select 'dod-order-items  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[=[:order-id] order-id]]    :caching nil :flatp t )))


(defun get-order-item-by-id  (item-id )
:documentation "Returns the order item by id "
(first (clsql:select 'dod-order-items  :where
		[and [= [:deleted-state] "N"]
		[=[:row-id] item-id]]    :caching nil :flatp t )))




(defun delete-all-order-items (order-instance company)
  (let ((order-items (get-order-items order-instance)))
    (if order-items (delete-order-items  order-items company))))


(defun count-order-items-completed (order-instance company) 
  :documentation "Checks whether all the order items are in completed status for a given order" 
(let ((tenant-id (slot-value company 'row-id))
      (order-id (slot-value order-instance 'row-id)))
  (first (clsql:select [count [*]] :from 'dod-order-items :where 
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		;; LEFT ALONE ON PURPOSE (S8): COMPLETED is the pair (CMP, fulfilled Y) — a cancelled order is
		;; terminal and NOT completed, so no set in core holds it; the offline check allows this literal.
		[= [:status] "CMP"]
		[= [:fulfilled] "Y"]
		[=[:order-id] order-id]]    :caching nil :flatp t ))))


(defun count-order-items-pending (order-instance company) 
  :documentation "Checks whether all the order items are in completed status for a given order" 
(let ((tenant-id (slot-value company 'row-id))
      (order-id (slot-value order-instance 'row-id)))
  (first (clsql:select [count [*]] :from 'dod-order-items :where 
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		;; S8/D17: the OPEN set, not the literal PEN — an order created through the new
		;; API carries DFT, and a bare equality would hide every one of its items.
		[in [:status] *order-open-statuses*]
		[= [:fulfilled] "N"]
		[=[:order-id] order-id]]    :caching nil :flatp t ))))



(defun get-pending-order-items-for-vendor-by-product (product-instance vendor-instance )
(let* ((tenant-id (slot-value vendor-instance 'tenant-id))
       (product-id (slot-value product-instance 'row-id))
       (vendor-id (slot-value vendor-instance 'row-id)))
  	
 (clsql:select 'dod-order-items  :where
		[and [= [:deleted-state] "N"]
		     [= [:tenant-id] tenant-id]
		     [= [:vendor-id] vendor-id]
		     ;; S8/D17: the OPEN set (see count-order-items-pending).
		     [in [:status] *order-open-statuses*]
		     [= [:fulfilled] "N"]
		     [=[:prd-id] product-id]]    :caching nil :flatp t )))

  
(defun get-order-items-for-vendor-by-order-id (order-instance vendor-instance)
    (let* ((tenant-id (slot-value order-instance 'tenant-id))
	     (vendor-id (slot-value vendor-instance 'row-id))
	      (order-id (slot-value order-instance 'row-id)))
	
 (clsql:select 'dod-order-items  :where
		[and [= [:deleted-state] "N"]
		     [= [:tenant-id] tenant-id]
		     [= [:vendor-id] vendor-id]
		     [=[:order-id] order-id]]    :caching nil :flatp t )))


(defun get-completed-order-items-for-vendor (vendor-instance rowcount company)
    (let* ((tenant-id (slot-value company 'row-id))
	     (vendor-id (slot-value vendor-instance 'row-id)))
 (clsql:select 'dod-order-items  :where
	       [and [= [:deleted-state] "N"]
	       ;; LEFT ALONE ON PURPOSE (S8): the completed pair, as above.
	       [= [:status] "CMP"]
	       [= [:fulfilled] "Y"]
	       [in [:order-id] (get-orderids-for-vendor vendor-instance company "Y")]
	       [= [:tenant-id] tenant-id]
	       [= [:vendor-id] vendor-id]] :order-by :order-id  :limit rowcount
	       :caching nil :flatp t )))


(defun get-order-items-for-vendor (vendor-instance  company &optional  (recordsfordays 30))
  (let* ((tenant-id (slot-value company 'row-id))
	 (strfromdate (get-date-string-mysql (clsql-sys:date- (clsql-sys::get-date) (clsql-sys:make-duration :day recordsfordays))))
	 (strtodate (get-date-string-mysql (clsql-sys:date+ (clsql-sys::get-date) (clsql-sys:make-duration :day recordsfordays))))
	 (vendor-id (slot-value vendor-instance 'row-id)))
 (clsql:select 'dod-order-items  :where
	       [and [= [:deleted-state] "N"]
	       [between [:created] strfromdate strtodate]
	       ;; S8/D17: the OPEN set (see count-order-items-pending).
	       [in [:status] *order-open-statuses*]
	       [= [:fulfilled] "N"]
	       ;; [in [:order-id] (get-orderids-for-vendor vendor-instance company fulfilled recordsfordays)]
	       [= [:tenant-id] tenant-id]
	       [= [:vendor-id] vendor-id]] :order-by :order-id
	       :caching nil :flatp t )))



(defun get-order-items-by-product-id (prd-id order-id tenant-id)
 (car (clsql:select 'dod-order-items  :where
		[and [= [:deleted-state] "N"]
     [= [:tenant-id] tenant-id]
     [= [:prd-id] prd-id]
		[=[:order-id] order-id]]    :caching nil :flatp t )))
    

(defun update-order-item (odt-instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance odt-instance))

(defun cancel-order-items (list company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
    (mapcar (lambda (id)  (let ((dodorder (car (clsql:select 'dod-order-items :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching nil))))
			  (setf (slot-value dodorder 'status) "CCN") ; CCN = CANCELLED BY CUSTOMER
			  (clsql:update-record-from-slot dodorder  'status))) list )))

(defun delete-order-items (list company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (mapcar (lambda (id)  (let ((dodorder (car (clsql:select 'dod-order-items :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching nil))))
			  (setf (slot-value dodorder 'deleted-state) "Y")
			  (clsql:update-record-from-slot dodorder  'deleted-state))) list )))


(defun restore-deleted-order-details ( list company-instance )
    (let ((tenant-id (slot-value company-instance 'row-id)))
(mapcar (lambda (id)  (let ((dodorder (car (clsql:select 'dod-order-items :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching nil))))
    (setf (slot-value dodorder 'deleted-state) "N")
    (clsql:update-record-from-slot dodorder 'deleted-state))) list )))

  

  
(defun persist-order-items(order-id product-id vendor-id unit-price discount product-qty sgst sgstamt cgst cgstamt igst igstamt taxablevalue totalitemval tenant-id )
  (clsql:update-records-from-instance (make-instance 'dod-order-items
						    :order-id order-id
						    :prd-id product-id
						    :vendor-id vendor-id
						    :unit-price unit-price
						    :disc-rate discount
						    :sgst sgst
						    :sgstamt sgstamt
						    :cgst cgst
						    :cgstamt cgstamt
						    :igst igst
						    :igstamt igstamt
						    :taxablevalue taxablevalue
						    :totalitemval totalitemval
						    :status "PEN"
						    :fulfilled "N"
						    :prd-qty product-qty
						    :tenant-id tenant-id
						    :deleted-state "N")))





 ;This is a clean function with no side effect.
(defun create-order-items (order product  product-qty unit-price discount sgst sgstamt cgst cgstamt igst igstamt taxablevalue totalitemval company-instance)
  (let ((order-id (slot-value order 'row-id))
	(product-id (slot-value product 'row-id))
	(vendor-id (slot-value (product-vendor product) 'row-id))
	(tenant-id (slot-value company-instance 'row-id)))
    (persist-order-items order-id product-id vendor-id unit-price discount product-qty sgst sgstamt cgst cgstamt igst igstamt taxablevalue totalitemval tenant-id)))



;;; ───────────────────────────────────────────────────────────────────────────
;;; THE DELIVERY CHARGE AS A LINE — one per vendor, from the vendor's FREIGHT product
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; Why the charge lives in a LINE rather than in the order's SHIPPING_COST column: the invoice prints
;;; its totals from its ITEMS (`calculate-invoice-totalaftertax`) and the invoice header has no shipping
;;; column, so a charge that is not a line can neither print nor reconcile. With it as a line, the
;;; order→invoice flow COPIES the lines and adds nothing. GST position: gst-tax-jurisdiction §1, §6.

(defun nst-select-freight-product (vendor-id tenant-id)
  "The vendor's own delivery-charge product (PRODUCT_CODE FREIGHT-<vendor-id>), or NIL. One row per
   vendor, seeded by `installation/upgrades/nst-dbu-freight-product.lisp` — DOD_ORDER_ITEMS.PRD_ID has
   a live FK to the product master, so a delivery line needs a real product row to attach to."
  (let ((vid (ignore-errors (parse-integer (princ-to-string vendor-id))))
        (tid (ignore-errors (parse-integer (princ-to-string tenant-id)))))
    (when (and vid tid)
      (car (clsql:select 'dod-prd-master
                         :where (format nil "VENDOR_ID=~D AND TENANT_ID=~D AND PRODUCT_CODE='FREIGHT-~D' AND (DELETED_STATE IS NULL OR DELETED_STATE<>'Y')"
                                         vid tid vid)
                         :caching nil :flatp t)))))

(defun nst-order-has-freight-line-p (order-id vendor-id tenant-id)
  "Does this order already carry a delivery line for VENDOR-ID? The invoice's fallback asks this before
   adding one, so an order can never be invoiced with TWO delivery charges."
  (let ((product (nst-select-freight-product vendor-id tenant-id))
        (oid (ignore-errors (parse-integer (princ-to-string order-id)))))
    (and product oid
         (plusp (length (clsql:select 'dod-order-items
                                      :where (format nil "ORDER_ID=~D AND PRD_ID=~D AND (DELETED_STATE IS NULL OR DELETED_STATE<>'Y')"
                                                      oid (slot-value product 'row-id))
                                      :caching nil :flatp t))))))

(defun nst-cart-with-delivery-line (order-items products amount tax charge gstnumber company)
  "The cart WITH its delivery charge as a taxed line, as (values ITEMS PRODUCTS AMOUNT TAX CHARGE-LEFT).

   The charge moves out of the SHIPPING_COST column into the line, so nothing counts it twice — not the
   vendor's page, not the invoice (which would otherwise add its own; see the fallback in nst-bl-invhapi).
   ⚠ MULTI-VENDOR CARTS ARE LEFT ALONE, deliberately: one charge cannot be attributed to several vendors,
   and per-vendor shipping is its own step (gst-tax-jurisdiction §3). Same for a cart with no charge and
   for one with no FREIGHT product to bill under."
  (let* ((tenant-id (slot-value company 'row-id))
         (vendor-ids (remove-duplicates
                      (remove nil (mapcar (lambda (i) (slot-value i 'vendor-id)) order-items))))
         (vendor-id (and (= (length vendor-ids) 1) (first vendor-ids)))
         (product (and vendor-id (nst-select-freight-product vendor-id tenant-id)))
         (vendor-lines (remove-if-not (lambda (i) (equal (slot-value i 'vendor-id) vendor-id)) order-items))
         (rates (and product
                     (nst-principal-rate-of
                      (mapcar (lambda (i) (list (or (slot-value i 'taxablevalue) 0)
                                                (or (slot-value i 'cgst) 0)
                                                (or (slot-value i 'sgst) 0)
                                                (or (slot-value i 'igst) 0)))
                              vendor-lines)))))
    ;; 🚨 A DELIVERY LINE ONLY FOR A REGISTERED BUYER (B2B), who needs the freight's taxable value and tax
    ;; broken out to claim the ITC. A CONSUMER keeps the simple view the requester asked for: the charge
    ;; stays a charge on the page and in SHIPPING_COST, and the tax inside it is accounted on the INVOICE
    ;; (whose fallback adds an inclusive delivery line). ⚠ THE MONEY IS THE SAME EITHER WAY.
    (let ((b2b-p (nst-gstin-present-p gstnumber)))
    (if (not (and b2b-p product rates (plusp (float (or charge 0)))))
        (values order-items products amount tax charge (round-to-2-decimal (or charge 0)))
        (let ((line (nst-freight-order-line nil vendor-id product charge rates b2b-p)))
          (if (null line)
              (values order-items products amount tax charge 0.00)
              (values (append order-items (list line))
                      (append products (list product))
                      (round-to-2-decimal (+ (float (or amount 0)) (slot-value line 'totalitemval)))
                      (round-to-2-decimal (+ (float (or tax 0))
                                             (slot-value line 'cgstamt) (slot-value line 'sgstamt)
                                             (slot-value line 'igstamt)))
                      0.00
                      (slot-value line 'totalitemval))))))))

(defun nst-freight-order-line (order-id vendor-id product charge rates b2b-p)
  "A dod-order-items line for a delivery charge of CHARGE, taxed at RATES (the principal goods' rate —
   composite supply, Section 8): quantity 1, no discount, priced at the TAXABLE value the split gives.
   :B2B-P (the order carries the buyer's GSTIN) is EXCLUSIVE — the charge is pre-tax and the customer
   pays the tax on top; otherwise INCLUSIVE — the charge is what the customer pays, tax inside it."
  ;; ⚠ THE DECLARE BELONGS HERE, as the defun's first body form: a DECLARE is only a declaration in a
  ;; declaration context, so inside the WHEN below it is read as a call to the function DECLARE (a
  ;; confusing error that reads like a paren mistake), and `locally` around it makes SBCL complain that
  ;; the IGNORE comes from an outer scope.
  (declare (ignore b2b-p))
  (when (and product rates)
    ;; THE MONEY COMES FROM NST-LINE-MONEY (core/dod-bl-utl.lisp) — the one place that rounds, shared with
    ;; the invoice paths — with the state pair left out because the RATES already answer it (a CGST/SGST pair
    ;; is intra-state). :INCLUSIVE is what keeps the halves derived from the tax, the second taking the
    ;; residual, so taxable + taxes = the charge the customer pays exactly.
    ;; 🚨 THE VENDOR'S AMOUNT IS GROSS, FOR EVERY BUYER — measured: the shipping tables carry NO tax column
    ;; and the cart has always charged the configured amount as it stands, so "100" means "the customer pays
    ;; 100" and the tax is INSIDE it (84.75 + 15.25). Reading it as pre-tax for B2B would silently raise the
    ;; delivery price by 18% for registered buyers — the same configured amount giving two different totals,
    ;; which is what the requester caught. B2B and B2C pay the SAME; the only difference is that a registered
    ;; buyer sees the freight as a LINE and can claim its tax.
    (multiple-value-bind (taxable cgstrate sgstrate igstrate cgstamt sgstamt igstamt totalitemval)
        (nst-line-money 1 charge 0.00 rates nil nil :inclusive t)
      (make-instance 'dod-order-items
                     :order-id order-id
                     :vendor-id vendor-id
                     :prd-id (slot-value product 'row-id)
                     :prd-qty 1
                     :unit-price taxable
                     :disc-rate 0.00
                     :taxablevalue taxable
                     :sgst sgstrate :sgstamt sgstamt
                     :cgst cgstrate :cgstamt cgstamt
                     :igst igstrate :igstamt igstamt
                     :totalitemval totalitemval
                     :fulfilled "N"
                     :status "PEN"
                     :deleted-state "N"))))

(defun update-gst-for-order-lineitem (lineitem product placeofsupply vstate)
  (let* ((product-qty (slot-value lineitem 'prd-qty))
	 (current-price (slot-value product 'current-price))
	 (current-discount (slot-value product 'current-discount))
	 (gstvalues (get-gstvalues-for-product product)))
    ;; 🚨 THE ARITHMETIC IS NOT HERE ANY MORE. MONEY IS TO THE PAISE, and one rounded figure disagreed with
    ;; the invoice's when each layer rounded its own way: 3799.05 × 9% = 341.9145 is what the cart displayed
    ;; while the decimal(15,2) COLUMN quietly rounded it. Every channel now comes through NST-LINE-MONEY
    ;; (core/dod-bl-utl.lisp) — ONE rounder, ONE state rule (NST-SAME-GST-STATE-P, code-aware: the cart
    ;; passes a typed state NAME and the vendor row may hold a CODE ("29"), so `equal` made a Karnataka →
    ;; Karnataka sale INTER-state — order 488: IGST 205.20 with CGST/SGST 0.00).
    ;; ⚠ THE BOUND NAMES MUST NOT COLLIDE WITH THE SLOTS: `with-slots` binds the slot names as symbol
    ;; macros, so a variable called TAXABLEVALUE would be shadowed by the slot itself and the SETF below
    ;; would write the slot to its own value.
    (multiple-value-bind (taxable rate-cgst rate-sgst rate-igst amt-cgst amt-sgst amt-igst total)
        (nst-line-money product-qty current-price current-discount gstvalues placeofsupply vstate)
      (with-slots (taxablevalue sgst cgst igst sgstamt cgstamt igstamt totalitemval) lineitem
        (setf taxablevalue taxable)
        (setf sgst rate-sgst)
        (setf cgst rate-cgst)
        (setf igst rate-igst)
        (setf sgstamt amt-sgst)
        (setf cgstamt amt-cgst)
        (setf igstamt amt-igst)
        (setf totalitemval total)
        lineitem))))

 ;This is a clean function with no side effect.
(defun create-odtinst-shopcart (order product product-qty unit-price discount-rate company-instance)
  (let* ((product-id (slot-value product 'row-id))
	 (vendor (product-vendor product))
	 (vendor-id (slot-value vendor 'row-id))
	 (tenant-id (slot-value company-instance 'row-id))
	 (order-id (if order (slot-value order 'row-id) nil)))
    (make-instance 'dod-order-items
		   :order-id order-id
		   :vendor-id vendor-id
		   :prd-id product-id
		   :unit-price unit-price
		   :disc-rate discount-rate
		   :prd-qty product-qty
		   :cgst 0.00
		   :cgstamt 0.00
		   :sgst 0.00
		   :sgstamt 0.00
		   :igst 0.00
		   :igstamt 0.00
		   :taxable-value 0.00
		   :totalitemval 0.00
		   :tenant-id tenant-id
		   :deleted-state "N")))

(defun search-odt-by-prd-id (prd-id list)
    (if (not (equal prd-id (slot-value (car list) 'prd-id))) (search-odt-by-prd-id prd-id (cdr list))
    (car list)))


(defun search-odt-by-order-id (order-id list)
   (if (not (equal order-id (slot-value (car list) 'order-id))) (search-odt-by-order-id  order-id (cdr list))
    (car list)))
