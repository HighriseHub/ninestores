;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)



(defun set-order-fulfilled ( value vendor order-instance company-instance)
    :documentation "value should be Y or N, followed by order instance and company instance"
  (let* ((vendor-order (get-vendor-order-instance (slot-value order-instance 'row-id) vendor))
	 ;;(order-id (slot-value order-instance 'row-id))
	 (customer (get-customer order-instance)) 
	 (payment-mode (slot-value order-instance 'payment-mode))
	 (wallet (get-cust-wallet-by-vendor customer vendor company-instance))
	 (vendor-order-items (get-order-items-for-vendor-by-order-id  order-instance vendor ))
	 (total   (reduce #'+  (mapcar (lambda (voitem)
					 (* (slot-value voitem 'unit-price) (slot-value voitem 'prd-qty))) vendor-order-items))))
        (if (equal (slot-value (get-company order-instance) 'name) (slot-value  company-instance 'name))
	(progn
	  ;; complete the order items for that particular vendor.  	
	  (mapcar (lambda (voitem)
		    (progn
		      (setf (slot-value voitem 'status) "CMP")
		      (setf (slot-value voitem 'fulfilled) value)
		      (update-order-item voitem)))   vendor-order-items)
	  ;; complete the vendor_order  
	  (if vendor-order 
	      (progn  
		(setf (slot-value vendor-order 'status) "CMP")
		(setf (slot-value vendor-order 'fulfilled) value)
		(setf (slot-value vendor-order 'shipped-date) (clsql-sys:get-date))
		(update-order vendor-order)))
	  ;; Complete the main order only if all other vendor-order-items have been completed. 
	  (if (equal (count-order-items-pending order-instance company-instance) 0 ) 
	      (progn (setf (slot-value order-instance 'order-fulfilled) value)
		     (setf (slot-value order-instance 'shipped-date) (clsql-sys:get-date))
		     (setf (slot-value order-instance 'status ) "CMP")
		     (update-order order-instance)))
	  (dod-reset-order-functions vendor company-instance)
	  ;; Deduct the money from the wallet. 
	  (if (equal payment-mode "PRE") (deduct-wallet-balance total wallet))))))

    
    


(defun get-orders-by-company (company-instance &optional (fulfilled "N"))
  (let ((tenant-id (slot-value company-instance 'row-id)))
      (clsql:select 'dod-order  :where [and [= [:deleted-state] "N"]
	  [= [:tenant-id] tenant-id]
	  [= [:order-fulfilled] fulfilled]]    :caching *dod-debug-mode* :flatp t )))


(defun count-vendor-orders-completed (vendor order company) 
 (let ((tenant-id (slot-value company 'row-id)) 
       (vendor-id (slot-value vendor 'row-id))
       (order-id (slot-value order 'row-id)))
    
    (first (clsql:select [count [*]] :from 'dod-vendor-order :where 
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[= [:status] "CMP"]
		[= [:fulfilled] "Y"]
		[= [:vendor-id] vendor-id]
		[=[:order-id] order-id]]    :caching nil :flatp t ))))


(defun count-vendor-orders-pending (vendor order company) 
 (let ((tenant-id (slot-value company 'row-id)) 
       (vendor-id (slot-value vendor 'row-id))
       (order-id (slot-value order 'row-id)))
    
    (first (clsql:select [count [*]] :from 'dod-vendor-order :where 
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[= [:status] "PEN"]
		[= [:fulfilled] "N"]
		[= [:vendor-id] vendor-id]
		[=[:order-id] order-id]]    :caching nil :flatp t ))))

(defun get-vendor-order-instance (order-id vendor)
  (let ((vendor-id (slot-value vendor  'row-id)))
    (car (clsql:select 'dod-vendor-orders :where
		       [and [= [:vendor-id] vendor-id]
		       [= [:order-id] order-id]] 
		       :caching nil :flatp t))))



(defun get-orderids-for-vendor (vendor-instance  company &optional (fulfilled "N")  (recordsfordays 30))
  (let* ((tenant-id (slot-value company 'row-id))
	 (strfromdate (get-date-string-mysql (clsql-sys:date- (clsql-sys:get-date) (clsql-sys:make-duration :day recordsfordays))))
	 (strtodate (get-date-string-mysql (clsql-sys:date+ (clsql-sys:get-date) (clsql-sys:make-duration :day recordsfordays))))
	 (vendor-id (slot-value vendor-instance 'row-id)))
	 (clsql:select [order-id] :from  'dod-vendor-orders :where
		       [and [= [:tenant-id] tenant-id]
		       [between [:created] strfromdate strtodate ]
		       [= [:vendor-id] vendor-id]
		       [= [:deleted-state] "N"]
		       [= [:fulfilled] fulfilled]]  :order-by '( ([row-id] :desc)) 
		       :caching nil :flatp t)))


(defun get-orders-for-vendor (vendor-instance   rowcount company &optional   (fulfilled "N")  (recordsfordays 30))
  (let* ((tenant-id (slot-value company 'row-id))
	 (strfromdate (get-date-string-mysql (clsql-sys:date- (clsql-sys:get-date) (clsql-sys:make-duration :day recordsfordays))))
	 (strtodate (get-date-string-mysql (clsql-sys:date+ (clsql-sys:get-date) (clsql-sys:make-duration :day recordsfordays))))
	 (vendor-id (slot-value vendor-instance 'row-id)))
	 (clsql:select  'dod-vendor-orders :where
			[and [= [:tenant-id] tenant-id]
			[between [:created] strfromdate strtodate ]
			[= [:vendor-id] vendor-id]
			[= [:deleted-state] "N"]
			[= [:fulfilled] fulfilled]] :limit rowcount :order-by '( ([row-id] :desc)) 
			:caching nil :flatp t)))
    



(defun get-orders-for-vendor-by-shipped-date (vendor-instance shipped-date company &optional (fulfilled "N"))
  (let* ((tenant-id (slot-value company 'row-id))
	 (vendor-id (slot-value vendor-instance 'row-id)))

	   (clsql:select 'dod-vendor-orders :where
	    [and [= [:tenant-id] tenant-id]
		  [= [:vendor-id] vendor-id]
		  [= [:shipped-date] shipped-date]
		  [= [:fulfilled] fulfilled]] 
			  :caching nil :flatp t)))



(defun get-all-orders-for-vendor (vendor-instance &optional (rowcount "NULL"))
  (let* ((tenant-id (slot-value vendor-instance 'tenant-id))
	 (company (car (get-vendor-company vendor-instance)))
	 (vendor-id (slot-value vendor-instance 'row-id))
	 (ordidlist     (clsql:select  [order-id] :from  'dod-vendor-orders :where
	    [and [= [:tenant-id] tenant-id]
		  [= [:vendor-id] vendor-id]] :limit rowcount
		  
			  :caching nil :flatp t)))
    (remove nil (mapcar (lambda (ord-id) 
			  (get-order-by-id ord-id company)) ordidlist))))



(defun get-vendor-order-by-status (order company-instance fulfilled)
 (let ((tenant-id (slot-value company-instance 'row-id))
       (order-id (slot-value order 'row-id)))
  (car (clsql:select 'dod-vendor-orders  :where
		     [and 
		     [= [:order-fulfilled] fulfilled]
		     [= [:tenant-id] tenant-id]
		     [=[:order-id] order-id]]    :caching *dod-debug-mode* :flatp t ))))


(defun get-order-by-status (id company-instance fulfilled)
 (let ((tenant-id (slot-value company-instance 'row-id)))
  (car (clsql:select 'dod-order  :where
		     [and [= [:deleted-state] "N"]
		     [= [:order-fulfilled] fulfilled]
		     [= [:tenant-id] tenant-id]
		     [=[:row-id] id]]    :caching *dod-debug-mode* :flatp t ))))
  




(defun get-order-by-shipped-date (id shipped-date company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
	 (car (clsql:select 'dod-order  :where
		     [and [= [:deleted-state] "N"]
		     [= [:shipped-date] shipped-date]
		     [= [:tenant-id] tenant-id]
		     [=[:row-id] id]]    :caching *dod-debug-mode* :flatp t ))))
  


(defun get-order-by-id (id company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
  (car (clsql:select 'dod-order  :where
		     [and [= [:deleted-state] "N"]
		     [= [:tenant-id] tenant-id]
		     [=[:row-id] id]]    :caching nil :flatp t ))))

(defun get-all-vendor-orders-by-orderid (id company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
	
    (clsql:select 'dod-vendor-orders  :where
	   [and [= [:tenant-id] tenant-id]
	   [=[:deleted-state] "N"]
	   [=[:order-id] id]]    :caching nil :flatp t )))


(defun get-vendor-orders-by-orderid (id vendor company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id))
	(vendor-id (slot-value vendor 'row-id)))
	
    (car (clsql:select 'dod-vendor-orders  :where
	   [and [= [:tenant-id] tenant-id]
	   [=[:deleted-state] "N"]
	   [= [:vendor-id] vendor-id]
	   [=[:order-id] id]]    :caching nil :flatp t ))))


(defun get-vendors-by-orderid (order-id company-instance)
  (let* ((tenant-id (slot-value company-instance 'row-id))
	(vendorids (clsql:select [:vendor-id] :from 'dod-vendor-orders :where
		      [and 
		      [=[:deleted-state] "N"]
		      [=[:order-id] order-id]
		      [= [:tenant-id] tenant-id]] :caching nil :flatp t)))

	(mapcar (lambda (vendor-id) (select-vendor-by-id vendor-id)) vendorids))) 


(defun get-order-by-context-id (context-id company-instance)
 (let ((tenant-id (slot-value company-instance 'row-id)))
  (car (clsql:select 'dod-order  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[=[:context-id] context-id]]    :caching nil :flatp t ))))

(defun setAsSalesOrder (order)
  :documentation "Sets the order type as Sales Order"
  (setf (slot-value order 'order-type) "SALE")
  (update-order order))

(defun setAsServiceOrder (order)
  :documentation "Sets the order type as Service Order"
  (setf (slot-value order 'order-type) "SRVC")
  (update-order order))



(defun get-orders-for-customer (customer &optional (recordsfordays 30))
  (let ((tenant-id (slot-value customer 'tenant-id))
	(strfromdate (get-date-string-mysql (clsql-sys:date- (clsql-sys:get-date) (clsql-sys:make-duration :day recordsfordays))))
	(strtodate (get-date-string-mysql (clsql-sys:date+ (clsql-sys:get-date) (clsql-sys:make-duration :day recordsfordays))))
	(cust-id (slot-value customer 'row-id)))
    (clsql:select 'dod-order  :where
		  [and [= [:deleted-state] "N"]
		  [between [:created] strfromdate strtodate ]
		  [= [:tenant-id] tenant-id]
		  [=[:cust-id] cust-id ]] :order-by '(([row-id] :desc))
		  :caching nil :flatp t )))

(defun get-orders-by-req-date (req-date company-instance)
(let ((tenant-id (slot-value company-instance 'row-id)))
(clsql:select 'dod-order  :where
    [and [= [:deleted-state] "N"]
    [= [:tenant-id] tenant-id]
    [=[:req-date] req-date]]
		:caching nil :flatp t )))


(defun get-latest-order-for-customer (customer)
  (let ((tenant-id (slot-value customer 'tenant-id))
	(cust-id (slot-value customer 'row-id)))
(car (clsql:select 'dod-order  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[=[:cust-id] cust-id ]
		[= [:row-id] (get-max-order-id cust-id tenant-id)]]    :caching nil :flatp t ))))
  
(defun get-max-order-id (customer-id tenant-id)
  (clsql:select [max [row-id]] :from 'dod-order  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[=[:cust-id] customer-id]]    :caching nil :flatp t ))
  



(defun update-order (order-instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance order-instance))



(defun delete-order( order-instance )
  (progn 
    (setf (slot-value order-instance 'deleted-state) "Y")
    (clsql:update-record-from-slot order-instance 'deleted-state)))


(defun cancel-order-by-customer( order-instance )
  (progn 
    (setf (slot-value order-instance 'status) "CCN")
    (clsql:update-record-from-slot order-instance 'status)))


(defun cancel-order-by-vendor( order-instance )
  (progn 
    (setf (slot-value order-instance 'status) "VCN")
    (clsql:update-record-from-slot order-instance 'status)))


(defun delete-vendor-orders ( list) 
    (mapcar (lambda (vo)  (progn
			    (setf (slot-value vo 'deleted-state) "Y")
			    (clsql:update-record-from-slot vo  'deleted-state))) list ))


(defun delete-orders ( orderid-list company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (mapcar (lambda (id)  (let ((dodorder (car (clsql:select 'dod-order :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching nil))))
			  (setf (slot-value dodorder 'deleted-state) "Y")
			  (clsql:update-record-from-slot dodorder  'deleted-state))) orderid-list )))


(defun restore-deleted-orders ( list tenant-id )
(mapcar (lambda (id)  (let ((dodorder (car (clsql:select 'dod-order :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching nil))))
    (setf (slot-value dodorder 'deleted-state) "N")
    (clsql:update-record-from-slot dodorder 'deleted-state))) list ))

  

  
(defun persist-order(modelfunc)
  (multiple-value-bind
	(order-date request-date shipped-date expected-delivery-date shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship storepickupenabled gstnumber gstorgname order-amt shipping-cost total-discount total-tax payment-mode comments context-id customer-id order-type  order-source customer-name tenant-id) (funcall modelfunc)
    (clsql:update-records-from-instance (make-instance 'dod-order
						       :ord-date order-date
						       :req-date request-date
						       :shipped-date shipped-date
						       :expected-delivery-date expected-delivery-date
						       :shipaddr shipaddr
						       :shipzipcode shipzipcode
						       :shipcity shipcity
						       :shipstate shipstate
						       :billaddr billaddr
						       :billzipcode billzipcode
						       :billcity billcity
						       :billstate billstate
						       :billsameasship billsameasship
						       :storepickupenabled storepickupenabled
						       :gstnumber gstnumber
						       :gstorgname gstorgname
						       :order-fulfilled "N"
						       :order-amt order-amt
						       :shipping-cost shipping-cost
						       :total-discount total-discount
						       :total-tax total-tax
						       :payment-mode payment-mode
						       :comments comments
						       :context-id context-id
						       :cust-id customer-id
						       :status "PEN"
						       :deleted-state "N" 
						       :is-converted-to-invoice "N"
						       :is-cancelled "N"
						       :order-type order-type
						       :order-source order-source
						       :customer-name customer-name
						       :tenant-id tenant-id)))) 


(defun create-order (modelfunc)
  (multiple-value-bind
	(order-date request-date shipped-date expected-delivery-date shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship orderpickupinstore gstnumber gstorgname order-amt shipping-cost total-discount total-tax payment-mode comments context-id customer order-type  order-source customer-name company) (funcall modelfunc) 
  (let ((customer-id (slot-value  customer 'row-id) )
	(tenant-id (slot-value company 'row-id)))
    (persist-order (function (lambda ()
		     (values order-date request-date shipped-date expected-delivery-date shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship orderpickupinstore gstnumber gstorgname order-amt shipping-cost total-discount total-tax payment-mode comments context-id customer-id order-type  order-source customer-name tenant-id)))))))


(defun create-order-from-pref (order-pref-list order-date request-date ship-date ship-address order-amt discount shipping-cost orderpickupinstore customer-instance company-instance)
  (let ((uuid (uuid:make-v1-uuid ))
	(tenant-id (slot-value company-instance 'row-id)))
      (progn  (create-order (function (lambda () (values order-date customer-instance request-date ship-date ship-address (print-object uuid nil) order-amt shipping-cost "PRE" nil orderpickupinstore  company-instance))))
	      (let ((order (get-order-by-context-id (print-object uuid nil) company-instance))
		    (vendors (get-opref-vendorlist order-pref-list))
		    (cust-id (slot-value customer-instance 'row-id)))
		(mapcar (lambda (preference)
			  (let* ((prd (get-opf-product preference))
				 (current-price (slot-value prd 'current-price))
				 (prd-qty (slot-value preference 'prd-qty)))
			    (if (prefpresent-p preference (clsql-sys:date-dow request-date)) (create-order-items order prd  prd-qty current-price discount company-instance)))) order-pref-list)
		
					; Create one row per vendor in the vendor_orders table. 
		(mapcar (lambda (vendor) 
			  (let* ((vitems (filter-opref-items-by-vendor vendor order-pref-list))
				 (total (get-opref-items-total-for-vendor vendor vitems))) 
			    
			    (persist-vendor-orders (slot-value order 'row-id) cust-id (slot-value vendor 'row-id) tenant-id order-date request-date ship-date ship-address "PREPAID"  total shipping-cost "Y")))  vendors)
      
		))))


(defun prefpresent-p (preference day)
    (let  ((lst  (list (if (equal (slot-value preference 'sun) "Y") 0 )
	     (if (equal (slot-value preference 'mon) "Y")  1)
		(if (equal (slot-value preference 'tue) "Y") 2)
	     (if (equal (slot-value preference 'wed) "Y") 3)
		(if (equal (slot-value preference 'thu) "Y") 4)
	     (if (equal (slot-value preference 'fri) "Y") 5) 
		(if (equal (slot-value preference 'sat) "Y") 6))))
	(if (member day lst) t nil)))


(defun create-order-email-content (vproducts vitems customer order-id shipping-cost sub-total)
  (with-slots (zipcode address phone email city state name company) customer
    (let* ((currsymbol (get-currency-html-symbol (get-account-currency company)))
	   (headerstr (with-html-table "" (list "Particulars" "Details") "1"
			(:tr (:td (cl-who:str (format nil "Order No")))
			     (:td (cl-who:str (format nil "~A" order-id))))
			(:tr (:td (cl-who:str (format nil "Name")))
			     (:td (cl-who:str (format nil "~A" name)))
			     (:tr (:td (cl-who:str (format nil "Address")))
				  (:td (cl-who:str (format nil "~A, ~A, ~A, ~A" address city zipcode state))))
			     (:tr (:td (cl-who:str (format nil "Phone")))
				  (:td (cl-who:str (format nil "~A" phone))))
			     (:tr (:td (cl-who:str (format nil "Email")))
				  (:td (cl-who:str (format nil "~A" email)))))))
	   (datastr (ui-list-shopcart-for-email vproducts vitems))
	   (footer (cl-who:with-html-output-to-string (*standard-output* nil)
		     (:tr (:td :align "right"
			       (:span  :class "label label-default" (cl-who:str (format nil "Shipping: ~A ~$" currsymbol shipping-cost)))))
		     (:tr (:td :align "right"
			       (:span  :class "label label-default" (cl-who:str (format nil "Sub Total: ~A ~$" currsymbol sub-total)))))
		     (:tr (:td :align "right"
			       (:h2  (:span  :class "label label-default" (cl-who:str (format nil "Total = ~A ~$" currsymbol (+ shipping-cost sub-total))))))))))
      ;;(hhub-log-message  (format nil "~A~A~A" headerstr datastr footer))
      (format nil "~A~A~A" headerstr datastr footer))))

(defun create-order-email-content-for-vendor (vproducts vitems customer order-id shipping-info total)
  (with-slots (zipcode address phone email city state name) customer
    (let* ((headerstr (with-html-table "" (list "Particulars" "Details") "1"
			(:tr (:td (cl-who:str (format nil "Order No")))
			     (:td (cl-who:str (format nil "~A" order-id))))
			(:tr (:td (cl-who:str (format nil "Name")))
			     (:td (cl-who:str (format nil "~A" name)))
			     (:tr (:td (cl-who:str (format nil "Address")))
				  (:td (cl-who:str (format nil "~A, ~A, ~A, ~A" address city zipcode state))))
			     (:tr (:td (cl-who:str (format nil "Phone")))
				  (:td (cl-who:str (format nil "~A" phone))))
			     (:tr (:td (cl-who:str (format nil "Email")))
				  (:td (cl-who:str (format nil "~A" email)))))))
	   (datastr (ui-list-shopcart-for-email vproducts vitems))
	   (footer (cl-who:with-html-output-to-string (*standard-output* nil)
		     (:tr (:td :align "right"
			       (:h2  (:span  :class "label label-default" (cl-who:str (format nil "Total = Rs ~$" total))))))))
	   (shipstr (process-shipping-information-for-email shipping-info)))
      ;;(hhub-log-message  (format nil "~A~A~A" headerstr datastr footer))
      (format nil "~A~A~A~A" headerstr datastr footer shipstr))))

(defun process-shipping-information-for-email (shipping-info)
  (when shipping-info
    (with-html-table "" (list "Provider" "Weight Limit" "Rate" "Zone" "Timeline") "1"  
      (mapcar (lambda (shipinfo)
		(cl-who:htm
		 (:tr
		  (:td (cl-who:str (nth 0 shipinfo)))
		  (:td (cl-who:str (nth 8 shipinfo)))
		  (:td (cl-who:str (nth 9 shipinfo)))
		  (:td (cl-who:str (nth 10 shipinfo)))
		  (:td (cl-who:str (nth 11 shipinfo)))))) shipping-info))))
  


(defun save-order-items-in-db (order order-items products company-instance)
  (mapcar (lambda (odt)
	    (let* ((prd (search-item-in-list 'row-id (slot-value odt 'prd-id) products))
		   (unit-price (slot-value odt 'unit-price))
		   (discount (slot-value odt 'disc-rate))
		   (prd-qty (slot-value odt 'prd-qty)))
	      (create-order-items order prd  prd-qty unit-price discount company-instance)
	      (update-stock-inventory prd prd-qty))) order-items))


(defun update-stock-inventory (product prd-qty)
  :description "A rudimentary stock inventory update function" 
  (let* ((units-in-stock (slot-value product 'units-in-stock))
	(updated-units-in-stock  (if (and units-in-stock (> units-in-stock 0)) (- units-in-stock  prd-qty) 0)))
    (setf (slot-value product 'units-in-stock) updated-units-in-stock)
    (update-prd-details product)))


(defun save-vendor-orders-in-db (order order-date request-date ship-date ship-address payment-mode  orderpickupinstore  order-items products  shipping-info shipping-cost  guest-customer customer-instance company-instance utrnum)
  (let* ((order-id (slot-value order 'row-id))
	 (cust-id (slot-value customer-instance 'row-id))
	 (cust-type (slot-value customer-instance 'cust-type))
	 (vendors (get-shopcart-vendorlist order-items))
	 (tenant-id (slot-value company-instance 'row-id)))
    (mapcar (lambda (vendor) 
	      (let* ((vendor-email (slot-value vendor 'email))
		     (vitems (filter-order-items-by-vendor vendor order-items))
		     (vproducts (mapcar (lambda (odt)
					  (let ((prd-id (slot-value odt 'prd-id)))
					    (search-item-in-list 'row-id prd-id products))) vitems))
		     (total (get-order-items-total-for-vendor vendor vitems))
		     (vendor-id (slot-value vendor 'row-id))
		     (custinst (if (equal cust-type "GUEST") guest-customer customer-instance))
		     (order-disp-str (create-order-email-content vproducts vitems custinst order-id shipping-cost total))
		     (shipstr (process-shipping-information-for-email shipping-info))) 
      		
		(persist-vendor-orders order-id cust-id vendor-id  tenant-id order-date request-date ship-date ship-address payment-mode total shipping-cost orderpickupinstore)
		;; Save the UPI Transaction 
		(when utrnum (save-upi-transaction total utrnum (format nil "#ORD:~A" order-id) custinst vendor company-instance (slot-value custinst 'phone)))
		;;Send a mail to the vendor
		(when vendor-email (send-order-mail vendor-email (format nil "You have received new order ~A" order-id)  (format nil "~A~A" order-disp-str shipstr)))
		;; Send a push notification on the vendor's browser
		(send-webpush-message vendor (format nil "You have received a new order ~A" order-id))))  vendors)))


(defun create-order-from-shopcart (modelfunc)
  (multiple-value-bind
	(order-items shopcart-products shipping-info temp-customer utrnum order-date request-date shipped-date expected-delivery-date shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship orderpickupinstore gstnumber gstorgname order-amt shipping-cost total-discount total-tax payment-mode comments customer order-type  order-source customer-name company) (funcall modelfunc)
    (let ((context-id (uuid:make-v1-uuid)))
      ;; Create an order in the database. 
      (create-order (function (lambda ()
		      (values order-date request-date shipped-date expected-delivery-date shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship orderpickupinstore gstnumber gstorgname order-amt shipping-cost total-discount total-tax payment-mode comments (print-object context-id nil) customer order-type  order-source customer-name company))))
      (let* ((order (get-order-by-context-id (print-object context-id nil) company))
	     (order-id (slot-value order 'row-id)))
	;; Create the order-items and also update the current products in stock. 
	(save-order-items-in-db order order-items shopcart-products company)
	;; Create one row per vendor in the vendor_orders table. Send an order received email to each vendor. 
	(save-vendor-orders-in-db order  order-date request-date shipped-date shipaddr payment-mode  orderpickupinstore  order-items shopcart-products  shipping-info shipping-cost  temp-customer customer company utrnum)
    order-id))))
   
(defun persist-vendor-orders(order-id cust-id vendor-id tenant-id ord-date req-date ship-date ship-address payment-mode order-amt shipping-cost orderpickupinstore)
 (clsql:update-records-from-instance (make-instance 'dod-vendor-orders
					 :order-id order-id
					 :cust-id cust-id
					 :vendor-id vendor-id
					 :status "PEN"
					 :fulfilled "N"
					 :ord-date ord-date 
					 :req-date req-date
					 :shipped-date ship-date
					 :ship-address ship-address
					 :payment-mode payment-mode 
					 :order-amt order-amt
					 :shipping-cost shipping-cost
					 :storepickupenabled orderpickupinstore
					 :deleted-state "N"
					 :tenant-id tenant-id )))



(defun create-daily-orders-for-company (&key company-id odtstr reqstr)
    :documentation "odtstr and reqstr are of the format \"dd/mm/yyyy\" "
    (let* ((orderdate (get-date-from-string odtstr))
	      (requestdate (get-date-from-string reqstr))
	      (dodcompany (select-company-by-id company-id))
	      (customers (select-customers-for-company dodcompany)))
					;Get a list of all the customers belonging to the current company. 
					; For each customer, get the order preference list and pass to the below function.
	      (mapcar (lambda (customer)
			  (let ((custopflist (remove-if-not (lambda (preference)
							      (let  ((lst  (list (if (equal (slot-value preference 'sun) "Y") 0 )
										 (if (equal (slot-value preference 'mon) "Y")  1)
										 (if (equal (slot-value preference 'tue) "Y") 2)
										 (if (equal (slot-value preference 'wed) "Y") 3)
										 (if (equal (slot-value preference 'thu) "Y") 4)
										 (if (equal (slot-value preference 'fri) "Y") 5) 
										 (if (equal (slot-value preference 'sat) "Y") 6))))
								(if (member (clsql-sys:date-dow requestdate) lst) t nil)))
							    (get-opreflist-for-customer customer))))
			    (if custopflist  (create-order-from-pref custopflist orderdate requestdate nil (slot-value customer 'address) 0.0 0.0 0.0 "N" customer dodcompany)) )) customers)))



(defun run-daily-orders-batch (numdays)
  :documentation "datestr is of the format \"dd/mm/yyyy\" "
  (let ((cmplist (get-system-companies)))
    (loop for i from 1 to numdays do (mapcar (lambda (cmp) 
	      (let ((id (slot-value cmp 'row-id)))
		(create-daily-orders-for-company :company-id id :odtstr (get-date-string (clsql-sys:get-date)) :reqstr (get-date-string (clsql-sys:date+ (clsql-sys:get-date) (clsql-sys:make-duration :day i)))))) cmplist)))) 



