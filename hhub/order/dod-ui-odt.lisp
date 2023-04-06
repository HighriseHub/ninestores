;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defun com-hhub-transaction-cust-edit-order-item ()
  (let ((params nil))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
  (with-hhub-transaction "com-hhub-transaction-cust-edit-order-item" params 
      (let* ((item-id (hunchentoot:parameter "item-id"))
	     (company (get-login-customer-company))
	     (customer (get-login-customer))
	     (prdqty (parse-integer (hunchentoot:parameter "prdqty")))
	     (order-id (hunchentoot:parameter "order-id"))
	     (order (get-order-by-id order-id company))
	     (payment-mode (slot-value order 'payment-mode))
	     (order-item (get-order-item-by-id item-id))
	     (old-prdqty (slot-value order-item 'prd-qty))
	     (diff (- old-prdqty prdqty))
	     (product (get-odt-product order-item))
	     (units-in-stock (slot-value product 'units-in-stock))
	     (newunitsinstock (+ units-in-stock diff))
	     (vendor (odt-vendorobject order-item)))
	(cond ((> prdqty 0) 
	   (progn 
	     (setf (slot-value order-item 'prd-qty) prdqty)
	     (setf (slot-value product 'units-in-stock) newunitsinstock)
					; Check if there is enough balance in the wallet if order was in prepaid mode. 
					; at least one vendor wallet has low balance 
	     (if (equal payment-mode "PRE") ; If payment mode is prepaid only then check the wallet balance. 
		 (if (not (check-wallet-balance (get-order-items-total-for-vendor vendor (list order-item)) (get-cust-wallet-by-vendor customer vendor company)))
		     (hunchentoot:redirect (format nil "/hhub/dodcustlowbalanceorderitems?item-id=~A&prd-qty=~A" item-id prdqty))))
	     (update-order-item order-item)
	     (update-prd-details product)
	     
					; ((equal prdqty 0) (delete-order-items (list item-id) company)))
	     (hunchentoot:redirect (format nil "/hhub/hhubcustmyorderdetails?id=~A" order-id)))))))))


(defun order-item-edit-popup (item-id) 
 (let* ((order-item (get-order-item-by-id item-id))
	(order-id (slot-value order-item 'order-id))
	(product (get-odt-product order-item))
	(prd-id (slot-value product 'row-id))
	(prd-image-path (slot-value product 'prd-image-path))
	(prd-name (slot-value product 'prd-name)))
   (cl-who:with-html-output (*standard-output* nil)
     (:div :align "center" :class "row account-wall" 
	   (:div :class "col-sm-12  col-xs-12 col-md-12 col-lg-12"
		 (:div  :class "row" 
			(:div  :class "col-xs-12" 
			       (:a :href (format nil "dodprddetailsforcust?id=~A" prd-id) 
				   (:img :src  (format nil "~A" prd-image-path) :height "83" :width "100" :alt prd-name " "))))
		 (with-html-form "form-orditemedit" "dodcustorditemedit" 
		   (:div :class "form-group row"  (:label :for "product-id" (cl-who:str (format nil  " ~a" prd-name ))))
			(:input :type "hidden" :name "item-id" :value (format nil "~a" (slot-value order-item 'row-id)))
			(:input :type "hidden" :name "order-id" :value (format nil "~a" order-id ))
			(:div  :class "inputQty row" 
			       (:div :class "col-xs-4"
				     (:a :class "down btn btn-primary" :href "#" (:span :class "glyphicon glyphicon-minus" ""))) 
			       (:div :class "form-group col-xs-4" 
				     (:input :class "form-control input-quantity" :readonly "true" :name "prdqty" :placeholder "Enter a number"  :value (format nil "~a" (slot-value order-item 'prd-qty))   :type "number"))
			(:div :class "col-xs-4"
			      (:a :class "up btn btn-primary" :href "#" (:span :class "glyphicon glyphicon-plus" ""))))
		 (:div :class "form-group" 
		       (:input :type "submit"  :class "btn btn-primary" :value "Save"))))))))
		 




(defun dod-controller-list-order-details ()
    (if (is-dod-session-valid?)
	(let* (( dodorder (get-order-by-id (hunchentoot:parameter "id") (get-login-company)))
		  (header (list  "Order No" "Product" "Product Qty" "Unit Price"  "Total"  "Action"))
		  (odt (get-order-items dodorder) ))
	    (if odt (ui-list-order-details header odt) "No order details"))
	(hunchentoot:redirect "/login")))


(defun ui-list-order-details (header data)
    (cl-who:with-html-output (*standard-output* nil)
	(:h3 "Order Details") 
	(:table :class "table table-striped"  (:thead (:tr
				 (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) header))) (:tbody
				       (mapcar (lambda (odt)
				   (let ((odt-product  (get-odt-product odt)))
				     (cl-who:htm (:tr (:td  :height "12px" (cl-who:str (slot-value odt 'order-id)))
				       (:td  :height "12px" (cl-who:str (slot-value odt-product 'prd-name)))
				       (:td  :height "12px" (cl-who:str (slot-value odt 'prd-qty)))
				       (:td  :height "12px" (cl-who:str (slot-value odt 'unit-price)))
				       (:td :height "12px" (:a :href  (format nil  "/hhub/delorderdetail?id=~A" (slot-value odt 'row-id)) :onclick "return false"  "Delete")
					    (:a :href  (format nil  "/hhub/editorderdetail?id=~A" (slot-value odt 'row-id)) :onclick "return false"  "Edit")
					    ))))) (if (not (typep data 'list)) (list data) data) )))))


(defun ui-list-shopcart (products shopcart)
    :documentation "A function used for rendering the shopping cart data in HTML format."
    (cl-who:with-html-output-to-string (*standard-output* nil)
					; Header section.
	   				; Data section.
	      (:div :class "row-fluid"
		    (mapcar (lambda (product odt)
				    (cl-who:htm (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-4" 
					       (:div :class "product-box" (product-card-shopcart product odt)))))      products shopcart ))))


(defun ui-list-shopcart-readonly (products shopcart)
    :documentation "A function used for rendering the shopping cart data in HTML format."
    (cl-who:with-html-output-to-string (*standard-output* nil)
      (:div :class "row-fluid"
	    (mapcar (lambda (product odt)
		      (cl-who:htm (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-4" 
				 (:div :class "product-box" (product-card-shopcart-readonly product odt)))))  products shopcart ))))



(defun ui-list-shopcart-for-email (products shopcart)
    :documentation "A function used for rendering the shopping cart data in HTML EMAIL format."
  (with-html-table "" (list "Product" "Description" "Qty" "Subtotal") "1"  
    (mapcar (lambda (product odt)
	      (product-card-for-email product odt))  products shopcart )))
    

(defun ui-list-cust-orderdetails  (header data)
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class  "panel panel-default"
	 (:div :class "panel-heading" "Order Items")
	 (:div :class "panel-body"
	       (:table :class "table table-hover"  
		       (:thead (:tr
				(mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) header))) 
		       (:tbody
			(mapcar (lambda (odt)
	(let* ((odt-product  (get-odt-product odt))
	      (item-id (slot-value odt 'row-id))
					;(unit-price (slot-value odt 'unit-price))
	      (ordid (slot-value odt 'order-id))
	      (order (odt-orderobject odt))
	      (payment-mode (slot-value order 'payment-mode))
	      (fulfilled (slot-value odt 'fulfilled))
	      (status (slot-value odt 'status))
	      (prd-qty (slot-value odt 'prd-qty)))
	  (cl-who:htm (:tr  (cond ((and (equal status "PEN") (equal fulfilled "N")) 
			    (cl-who:htm (:td  :height "12px" (cl-who:str (format nil "Pending")))
				 (:td  :height "12px" 
				       (:a  :data-toggle "modal" :data-target (format nil "#orditemedit-modal~A" item-id)  :href "#" (:span :class "glyphicon glyphicon-pencil")) "&nbsp;&nbsp;"
				       (if (not (equal payment-mode "OPY")) (modal-dialog (format nil "orditemedit-modal~A" item-id) "Order Item Edit" (order-item-edit-popup item-id)))
				       (:a :onclick "return CancelConfirm();" :href  (format nil "/hhub/doddelcustorditem?id=~A&ord=~A" (slot-value odt 'row-id) ordid) :onclick "return false" (:span :class "glyphicon glyphicon-remove")))))
			   ((and (equal status "CMP") (equal fulfilled "Y"))  (cl-who:htm (:td  :height "12px" (cl-who:str (format nil "Fulfilled"))))))
		     (:td  :height "12px" (cl-who:str (slot-value odt-product 'prd-name)))
		     (:td  :height "12px" (cl-who:str (format nil  "~d" prd-qty)))
					;(:td  :height "12px" (cl-who:str (format nil  "Rs. ~$" unit-price)))
		     (:td  :height "12px" (cl-who:str (format nil "Rs. ~$" (* (slot-value odt 'unit-price) (slot-value odt 'prd-qty)))))
		     )))) (if (not (typep data 'list)) (list data) data))))))))


(defun display-order-header-for-customer (order-instance)
  (let ((payment-mode (slot-value order-instance 'payment-mode))
	  (shipped-date (slot-value order-instance 'shipped-date)))
    (cl-who:with-html-output (*standard-output* nil)
	(:div :class "jumbotron"
	    (:div :class "row" (:div :class "col-md-4"
				   (:h5 "Order No:") (:h4 (cl-who:str (slot-value order-instance 'row-id)))
				   (:h5 "Payment Mode:") (:h4 (cl-who:str (cond ((equal payment-mode "PRE") "Prepaid Wallet")
								       ((equal payment-mode "COD") "Cash On Demand")))))
				  
				  
		(:div :class "col-md-4"
		      (:h5 "Status: " ) (:h4 (cl-who:str (slot-value order-instance 'status)))
		      (:h5 "Order Date:") (:h4 (cl-who:str (get-date-string (slot-value order-instance 'ord-date))))
		    (:h5 "Requested On:")(:h4 (cl-who:str (get-date-string (slot-value order-instance 'req-date))))
		    (:h5 "Shipped On:")(:h4 (if shipped-date (cl-who:str (get-date-string shipped-date)))))
		
		(:div :class "col-md-4"
		     (:h5 "Comments") (:h4 (cl-who:str (slot-value order-instance 'comments))))
		)))))

(defun display-order-header-for-vendor (order-instance)
  (let* ((customer (get-customer order-instance))
	 (wallet (if customer (get-cust-wallet-by-vendor customer (get-login-vendor) (get-login-vendor-company))))
	 (balance (if wallet (slot-value wallet 'balance) 0))
	 (customer-type (slot-value customer 'cust-type))
	 (payment-mode (slot-value order-instance 'payment-mode))
	 (shipped-date (slot-value order-instance 'shipped-date)))
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-panel "panel panel-default" "Order Header"
	  (with-html-div-row 
	    (with-html-div-col 
	      (:h6 (:span "Customer Order No: ") (cl-who:str (slot-value order-instance 'row-id))))
	    (with-html-div-col
	      (:h6 (:span "Payment Mode: ") (cl-who:str (cond ((equal payment-mode "PRE") "Prepaid Wallet")
							      ((equal payment-mode "COD") "Cash On Demand")))))
	    (with-html-div-col
	      (if (equal payment-mode "PRE") (cl-who:htm (:h6 (:span "Wallet Balance:")  (cl-who:str balance)))))
	    (with-html-div-col
	      (:h6 (:span "Customer: ") (cl-who:str (slot-value customer 'name)))))
	(with-html-div-row
	  (with-html-div-col
	    (if (equal customer-type "STANDARD") (cl-who:htm (:h6 (:span "Address:")  (cl-who:str (slot-value customer 'address))))))
	  (with-html-div-col
	    (:h6 (:span "Phone: ") (cl-who:str (slot-value customer 'phone))))
	  (with-html-div-col
	    (:h6 (:span "Status: " ) (cl-who:str (slot-value order-instance 'status))))
	  (with-html-div-col
	    (:h6 (:span "Order Date: ") (cl-who:str (get-date-string (slot-value order-instance 'ord-date))))))
	(with-html-div-row 
	  (with-html-div-col
	    (:h6 (:span "Requested On:") (cl-who:str (get-date-string (slot-value order-instance 'req-date)))))
	  (with-html-div-col
	    (:h6 (:span "Shipped On:") (if shipped-date (cl-who:str (get-date-string shipped-date))))))
	(with-html-div-row
	  (with-html-div-col
	    (if (equal (slot-value order-instance 'order-fulfilled) "Y")
		(cl-who:htm (:div :class "stampbox rotated" "FULFILLED")))
			      (if (equal customer-type "GUEST") (cl-who:htm (:h6 :style "{word-break: break-all}" (:span "Comments: ")  (cl-who:str (slot-value order-instance 'comments)))))
	    (:h6 (:span "Customer Type:") (cl-who:str (slot-value customer 'cust-type)))))))))

