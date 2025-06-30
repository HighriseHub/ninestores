;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
;;(clsql:file-enable-sql-reader-syntax)


(defun dod-controller-list-orders ()
(if (is-dod-session-valid?)
   (let (( dodorders (get-orders-by-company  (get-login-company)))
	 (header (list  "Order No" "Order Date" "Customer" "Request Date"  "Ship Date" "Ship Address" "Action")))
     (if dodorders (ui-list-orders header dodorders) "No orders"))
     (hunchentoot:redirect "login")))


(defun ui-list-orders (header data)
  (cl-who:with-html-output (*standard-output* nil)
      (:a :class "btn btn-primary" :role "button" :href (format nil "/dodcustindex") "Shop Now")
    (:h3 "Orders")
    (:table :class "table table-striped"
     (:thead
      (:tr
       (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) header)))
     (:tbody
      (mapcar
       (lambda (order)
	 (let ((ord-customer  (get-customer order)))
	   (cl-who:htm
	    (:tr
	     (:td  :height "12px" (cl-who:str (slot-value order 'row-id)))
	     (:td  :height "12px" (cl-who:str (slot-value order 'ord-date)))
	     (:td  :height "12px" (cl-who:str (slot-value ord-customer 'name)))
	     (:td  :height "12px" (cl-who:str (slot-value order 'req-date)))
	     (:td  :height "12px" (cl-who:str (slot-value order 'shipped-date)))
	     (:td  :height "12px" (cl-who:str (slot-value order 'ship-address)))
	     (:td :height "12px" (:a :class "btn btn-primary" :role "button" :href  (format nil  "delorder?id=~A" (slot-value order 'row-id)) "Cancel Order")
		  (:a  :class "btn btn-primary" :role "button" :href  (format nil  "orderdetails?id=~A" (slot-value order 'row-id)) "Details"))
	     )))) (if (not (typep data 'list)) (list data) data))))))



(defun ui-list-orders-for-excel (header ordlist)
  (cl-who:with-html-output-to-string (*standard-output* nil)
      (mapcar (lambda (item) (cl-who:str (format nil "~A," item ))) header)
      (cl-who:str (format nil " ~C~C" #\return #\linefeed))
      (mapcar (lambda (vord )
		(let* ((odtlst (dod-get-cached-order-items-by-order-id (slot-value vord 'order-id) (hunchentoot:session-value :order-func-list)  ))
		       (total   (reduce #'+  (mapcar (lambda (odt)
						       (calculate-order-item-cost odt)) odtlst)))
		       (customer (get-customer vord)))
		  (if (> (length odtlst) 0) 
		      (progn  
			(cl-who:str (format nil "Order: ~A Customer: ~A. ~A." (slot-value vord 'order-id)  (slot-value customer 'name) (slot-value customer 'address) )) 
			(if (equal (slot-value vord 'fulfilled) "Y") 
			    (cl-who:str (format nil "Order status - Fulfilled ~C~C" #\return #\linefeed )) 
			    ;else
			    (cl-who:str (format nil "Order status - Pending ~C~C" #\return #\linefeed)))
			(mapcar (lambda (odt)
				  (let* ((prd (get-odt-product odt))
					 (subtotal (calculate-order-item-cost odt))
					 (prd-name (slot-value prd 'prd-name))
					 (prd-qty (slot-value odt 'prd-qty))
					 (qty-per-unit (slot-value prd 'qty-per-unit))
					 (disc-rate (slot-value odt 'disc-rate))
					 (unit-price (slot-value odt 'unit-price)))
				    (cl-who:str (format nil "~a,~a,~a,Rs. ~$,~$,Rs. ~$,~C~C" prd-name prd-qty qty-per-unit unit-price disc-rate subtotal  #\return #\linefeed)))) odtlst)
			(cl-who:str (format nil ",,,,Total, Rs. ~$~C~C" total #\return #\linefeed)))))) ordlist)))


;; This function takes more time, please make it more efficient in future. 
(defun ui-list-vendor-orders-by-products (ordlist)
    (let*  ((vendor (get-login-vendor))
	    (tenant-id (get-login-vendor-tenant-id))
	    (company (get-login-vendor-company))
	    (currsymbol (get-currency-html-symbol (get-account-currency company)))
	    (products  (hunchentoot:session-value :login-prd-cache))
	    (odtlst (mapcar (lambda (prd)
			      (let ((prd-id (slot-value prd 'row-id)))
				(delete nil (mapcar (lambda (ord)
						      (let ((order-id (slot-value ord 'order-id)))
							(get-order-items-by-product-id  prd-id  order-id tenant-id)))  ordlist) :test #'equal)))
			    products)))

	 (cl-who:with-html-output (*standard-output* nil)	       
	   (mapcar (lambda (prd odtlstbyprd)
		     (let ((quantity (reduce #'+ (mapcar (lambda (odt)
							   (if odt (slot-value odt 'prd-qty)))   odtlstbyprd)))
			   (subtotal (reduce #'+ (mapcar (lambda (odt)
							   (if odt (* (slot-value odt 'unit-price) (slot-value odt 'prd-qty))  )) odtlstbyprd)))
			   (orders (remove-duplicates (mapcar (lambda (odt)
								(let* ((order-id (slot-value odt 'order-id)))
								       (get-vendor-order-instance order-id vendor))) odtlstbyprd))))
		       (if (>  subtotal 0)  
			   (cl-who:htm  (:div :class "thumbnail row"
					      (with-html-div-col-2
						(cl-who:str (slot-value prd 'prd-name)))
					      (with-html-div-col-2
						(cl-who:str (slot-value prd 'qty-per-unit)))
					      (with-html-div-col-2
					   	(:h5 (cl-who:str (format nil "~A ~$ " currsymbol ( slot-value prd 'current-price)))))
					      (with-html-div-col-2
					  	(:span :class "badge" (cl-who:str quantity)))
					      (with-html-div-col-2
						(:h4 (:span :class "label label-default" (cl-who:str (format nil "~A ~$" currsymbol subtotal))))))
					
					(:div :class "row"
					      (mapcar (lambda (order)
						  (let ((order-id (slot-value order 'row-id)))
						    (cl-who:htm
						     (with-html-div-col-2
						       (:a :data-bs-toggle "modal" :data-bs-target (format nil "#hhubvendorderdetails~A-modal"  order-id)  :href "#"  (:span :class "label label-info" (format nil "~A" (cl-who:str order-id))))
						       (modal-dialog-v2 (format nil "hhubvendorderdetails~A-modal" order-id) "Vendor Order Details" (modal.vendor-order-details order company)))))) orders))
					(:hr))))) products odtlst))))



(defun ui-list-vendor-orders-by-customers (ordlist)
 (cl-who:with-html-output (*standard-output* nil)	       
   (:a :class "btn btn-primary btn-xs" :role "button" :onclick "window.print();" :href "#" "Print&nbsp;&nbsp;"(:i :class "fa-solid fa-print"))
   ;; For every vendor order
   (mapcar (lambda (vord)
	     (let*  ((order-id (slot-value vord 'order-id))
		     (odtlst (dod-get-cached-order-items-by-order-id order-id (hunchentoot:session-value :order-func-list)))
		     (total   (reduce #'+  (mapcar (lambda (odt)
						     (calculate-order-item-cost odt)) odtlst)))
		     (storepickupenabled (if (equal (slot-value vord 'storepickupenabled) "Y") T NIL))
		     (customer (get-customer vord))
		     (cust-order (get-order vord))
		     (cust-name (slot-value customer 'name))
		     (cust-phone (slot-value customer 'phone))
		     (company (get-company customer))
		     (currsymbol (get-currency-html-symbol (get-account-currency company)))
		     (ship-address (slot-value vord 'ship-address))
		     (order-comments (slot-value cust-order 'comments)))

	       ;(if (>  (length odtlst) 0) 
		   (progn 
		     (if (equal (slot-value customer 'cust-type) "GUEST")
			 (cl-who:htm (:div :class "row"
			    (:div :class "col-sm-12 col-xs-12 col-md-4 col-lg-2"
			     (:h5 (cl-who:str (format nil "Order: ~A ~A. " order-id order-comments))))))
			 ;else
		     (cl-who:htm (:div :class "row"
			    (:div :class "col-sm-12 col-xs-12 col-md-4 col-lg-2"
			     (:h5 (cl-who:str (format nil "Order: ~A ~A. ~A. ~A. " order-id cust-name cust-phone ship-address)))))))
		     (when storepickupenabled
			 (cl-who:htm (:div :class "row"
					   (:div :class "col-sm-12"
						 (:h4 (:span :class "label label-default" (cl-who:str (format nil "THIS IS STORE PICKUP ORDER. NO SHIPPING."))))))))
		     (mapcar (lambda (odt)
			       (let* ((prd (get-odt-product odt))
				      (prd-name (slot-value prd 'prd-name))
				      (current-price (slot-value prd 'current-price))
				      (prd-qty (slot-value odt 'prd-qty))
				      (qty-per-unit (slot-value prd 'qty-per-unit)))
				 (cl-who:htm 
				  (with-html-div-row :style "border: solid 0.5px;"
				    (with-html-div-col
				      (cl-who:str (format nil "~A | ~A | ~A | ~A " prd-name prd-qty qty-per-unit current-price))
				      (:h5 (cl-who:str (format nil "~A ~$ " currsymbol (slot-value odt 'unit-price))))))))) odtlst)
					; Display the total for an order
			  
		     (cl-who:htm (:div :class "row"
				       (:div :class "col-sm-12" 
					     (:h4 (:span :class "label label-default" (cl-who:str (format nil "Total ~$" total)))))))
		     
		     ))) ordlist)))


    

(defun ui-list-customer-orders (header data)
  (cl-who:with-html-output (*standard-output* nil)
    (:h3 "Orders")
    (:table :class "table table-striped table-hover"
	    (:thead (:tr
		     (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) header)))
	      (:tbody
	       (mapcar (lambda (order)
			 (cl-who:htm (:tr (:td  :height "12px" (cl-who:str (slot-value order 'row-id)))
				   (:td  :height "12px" (cl-who:str (get-date-string (slot-value order 'ord-date))))
				   (:td  :height "12px" (cl-who:str (get-date-string (slot-value order 'req-date))))
				   (if (equal (slot-value order 'order-fulfilled) "Y")
				       (cl-who:htm  (:td :height "12px"
						  (:a :href  (format nil  "hhubcustmyorderdetails?id=~A" (slot-value order 'row-id)) (:span :class "label label-primary" "Details" ))  "&nbsp;&nbsp;" (:span :class "label label-info" "FULFILLED")))
					; ELSE
				       (cl-who:htm  (:td :height "12px" (:a :href  (format nil  "hhubcustmyorderdetails?id=~A" (slot-value order 'row-id)) (:span :class "label label-primary" "Details" ))))
				       )))) (if (not (typep data 'list)) (list data) data) )))))




(defun concat-ord-dtl-name (order-instance)
  (let ((odt ( get-order-items order-instance)))
    (mapcar (lambda (odt-ins)
	      (concatenate 'string (slot-value (get-odt-product odt-ins) 'prd-name) ",")) odt)))

; This is a pure function. 
(defun vendor-order-card (vorder-instance)
  (let* ((customer (get-customer vorder-instance))
	 (company (get-company vorder-instance))
	 (order-id (slot-value vorder-instance 'order-id))
	 (name (if customer (slot-value customer 'name)))
	 (storepickupenabled (if (equal (slot-value vorder-instance 'storepickupenabled) "Y") T NIL))
	 (address (if customer (slot-value customer 'address))))
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-div-row
	    (with-html-div-col-8  (cl-who:str name)))
      (with-html-div-row
	    (with-html-div-col-8 (cl-who:str (if (> (length address) 20)  (subseq (slot-value customer 'address) 0 20) address))))
      (with-html-div-row
	    (with-html-div-col-8
		  (:a :data-bs-toggle "modal" :data-bs-target (format nil "#hhubvendorderdetails~A-modal"  order-id)  :href "#"  (:span :class "label label-info" (format nil "~A" (cl-who:str order-id))))
		  (modal-dialog-v2 (format nil "hhubvendorderdetails~A-modal" order-id) "Vendor Order Details" (modal.vendor-order-details vorder-instance company))
		  (if storepickupenabled
		      (cl-who:htm (:a :data-toggle "tooltip" :title "Store Pickup" :href "#" (:i :class "fa-solid fa-person-walking-luggage")))))))))
      


