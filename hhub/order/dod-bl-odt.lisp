;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)



(defun get-order-items (order-instance)
:documentation "Returns the list of order details instances given order-instance as input"
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
		[= [:status] "PEN"]
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
		     [= [:status] "PEN"]
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
	       [= [:status] "PEN"]
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



(defun update-gst-for-order-lineitem (lineitem product placeofsupply vstate)
  (let* ((product-qty (slot-value lineitem 'prd-qty))
	 (current-price (slot-value product 'current-price))
	 (current-discount (slot-value product 'current-discount))
	 (gstvalues (get-gstvalues-for-product product))
	 (cgstrate (if gstvalues (first gstvalues) 0.00)) 
	 (sgstrate (if gstvalues (second gstvalues) 0.00))
	 (igstrate (if gstvalues (third gstvalues) 0.00)) 
	 (txvalue (- (* product-qty current-price) (if current-discount (/ (* product-qty  current-price current-discount) 100) 0.00)))
	 (intrastate (if (equal vstate placeofsupply) T NIL))
	 (interstate (if (equal vstate placeofsupply) NIL T)) 
	 (cgstamount (if intrastate (/ ( * txvalue cgstrate) 100) 0.00))
	 (sgstamount (if intrastate (/ (* sgstrate txvalue) 100) 0.00))
	 (igstamount (if interstate (/ (* igstrate txvalue) 100) 0.00))
	 (totalitemvalue (+ txvalue (if intrastate (+ cgstamount sgstamount) igstamount))))
    (with-slots (taxablevalue sgst cgst igst sgstamt cgstamt igstamt totalitemval) lineitem
      (setf taxablevalue txvalue)
      (setf sgst sgstrate)
      (setf cgst cgstrate)
      (setf igst igstrate)
      (setf sgstamt sgstamount)
      (setf cgstamt cgstamount)
      (setf igstamt igstamount)
      (setf totalitemval totalitemvalue)
      lineitem)))

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
