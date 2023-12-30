;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

;;;;;;;;;;; CUSTOMER ORDER EDIT ;;;;;;;;;;;;;;;;;
(defun createmodelfortranscusteditorderitem ()
  (let ((params nil))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "company" (get-login-customer-company) params))
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
	     (vendor (odt-vendorobject order-item))
	     (redirectlocation (format nil "/hhub/hhubcustmyorderdetails?id=~A" order-id)))
	(when (> prdqty 0) 
	  (setf (slot-value order-item 'prd-qty) prdqty)
	  (setf (slot-value product 'units-in-stock) newunitsinstock)
	  ;; Check if there is enough balance in the wallet if order was in prepaid mode. 
	  ;; at least one vendor wallet has low balance 
	  (if (equal payment-mode "PRE") ; If payment mode is prepaid only then check the wallet balance. 
	      (if (not (check-wallet-balance (get-order-items-total-for-vendor vendor (list order-item)) (get-cust-wallet-by-vendor customer vendor company)))
		  (setf redirectlocation (format nil "/hhub/dodcustlowbalanceorderitems?item-id=~A&prd-qty=~A" item-id prdqty)))))
	(update-order-item order-item)
	(update-prd-details product)
	(function (lambda ()
	  (values redirectlocation)))))))

(defun createwidgetsfortranscusteditorderitem (modelfunc)
  (multiple-value-bind (redirectlocation) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     redirectlocation))))
      (list widget1))))

(defun com-hhub-transaction-cust-edit-order-item ()
  (with-cust-session-check
    (let ((uri (with-mvc-redirect-ui createmodelfortranscusteditorderitem createwidgetsfortranscusteditorderitem)))
      (format nil "~A" uri))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun order-item-edit-popup (item-id) 
  (let* ((order-item (get-order-item-by-id item-id))
	 (itemqty (slot-value order-item 'prd-qty))
	 (order-id (slot-value order-item 'order-id))
	 (product (get-odt-product order-item))
	 (prd-id (slot-value product 'row-id))
	 (units-in-stock (slot-value product 'units-in-stock))
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
		    (with-html-input-text-hidden "item-id"  item-id )
		    (with-html-input-text-hidden "order-id"  order-id)
		    ;; Qty increment and decrement control.
		    (if (> units-in-stock 1)
			(html-range-control "prdqty"  prd-id "1" (max (mod units-in-stock 20) 10) itemqty "1"))
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
					    ))))) (if (not (typep data 'list)) (list data) data))))))


(defun ui-list-shopcart (products shopcart)
    :documentation "A function used for rendering the shopping cart data in HTML format."
    (cl-who:with-html-output-to-string (*standard-output* nil)
      (:div :id "idcustshoppingcartitems" :class "all-products-row"
	    (mapcar (lambda (product odt)
		      (cl-who:htm (:div :class "product-card-row" (product-card-shopcart product odt))))  products shopcart))))


(defun ui-list-shopcart-readonly (products shopcart)
    :documentation "A function used for rendering the shopping cart data in HTML format."
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "all-products-row"
	    (mapcar (lambda (product odt)
		      (cl-who:htm (:div :class "product-card-row" (product-card-shopcart-readonly product odt))))  products shopcart))
      (:hr)))



(defun ui-list-shopcart-for-email (products shopcart)
    :documentation "A function used for rendering the shopping cart data in HTML EMAIL format."
  (with-html-table "" (list "Product" "Description" "Qty" "Subtotal") "1"  
    (mapcar (lambda (product odt)
	      (product-card-for-email product odt))  products shopcart )))


(defun calculate-order-item-cost (order-item)
  :description "calculates the order item cost with respect to the unit price, discount, and tax rates if applicable"
  (let* ((discount (slot-value order-item 'disc-rate)) 
	 (unit-price (slot-value order-item 'unit-price))
	 (pricewith-discount (if discount
				 (- unit-price (/ (* unit-price discount) 100))
				 ;;else
				 unit-price)))
    pricewith-discount))


(defun ui-list-cust-orderdetails  (header data)
  (cl-who:with-html-output (*standard-output* nil)
    (:div :id "idlistcustorderitems"  :class  "panel panel-default"
	  (:div :class "panel-heading" "Order Items")
	  (:div :class "panel-body"
		(:table :class "table table-hover"  
			(:thead (:tr
				 (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) header))) 
			(:tbody
			 (mapcar (lambda (odt)
				   (let* ((odt-product  (get-odt-product odt))
					  (prd-id (slot-value odt-product 'row-id))
					  (prd-name (slot-value odt-product 'prd-name))
					  (item-id (slot-value odt 'row-id))
					  (ordid (slot-value odt 'order-id))
					  (order (odt-orderobject odt))
					  (payment-mode (slot-value order 'payment-mode))
					  (fulfilled (slot-value odt 'fulfilled))
					  (status (slot-value odt 'status))
					  (prd-qty (slot-value odt 'prd-qty))
					  (pricewith-discount (calculate-order-item-cost odt)))
				     (cl-who:htm (:tr  (cond ((and (equal status "PEN") (equal fulfilled "N")) 
							      (cl-who:htm (:td  :height "12px" (cl-who:str (format nil "Pending")))
									  (:td  :height "12px" 
										(:a  :data-bs-toggle "modal" :data-bs-target (format nil "#orditemedit-modal~A" prd-id) :data-toggle "tooltip" :title "Edit"  :href "#" :onclick "orderitemeditclick(this.id);" :id (format nil "btneditorderitem_~A" prd-id) :name (format nil "btneditorderitem~A" prd-id)  (:i :class "fa-regular fa-pen-to-square"))
										 "&nbsp;&nbsp;"
										(if (not (equal payment-mode "OPY")) (modal-dialog-v2 (format nil "orditemedit-modal~A" prd-id) "Order Item Edit"  (order-item-edit-popup item-id)))
										(:a  :data-bs-toggle "modal" :data-bs-target (format nil "#custdeleteorderitem-modal~A" item-id) :data-toggle "tooltip" :title "Delete Order Item"  :href "#"  :id (format nil "btndeleteorditem_~A" item-id) :name (format nil "btndeleteorditem~A" item-id) (:i :class "fa-regular fa-trash-can"))
										(modal-dialog-v2 (format nil "custdeleteorderitem-modal~A" item-id) (cl-who:str (format nil "Delete Order Item")) (modal.cust-delete-order-item odt ordid)))))
							     
							     ((and (equal status "CMP") (equal fulfilled "Y"))
							      (cl-who:htm
							       (:td  :height "12px" (cl-who:str (format nil "Fulfilled")))
							       (:td  :height "12px" (cl-who:str (format nil ""))))))
						       (:td  :height "12px" (cl-who:str prd-name))
						       (:td  :height "12px" (cl-who:str prd-qty))
					;(:td  :height "12px" (cl-who:str (format nil  "Rs. ~$" unit-price)))
						       (:td  :height "12px" (cl-who:str (format nil "Rs. ~$" (* pricewith-discount prd-qty))))
						       )))) (if (not (typep data 'list)) (list data) data))))))
    (:script "$(document).ready(function(){
    const listcustorderitemselem = document.querySelector(\"#idlistcustorderitems\");
    if(null != listcustorderitemselem){
	listcustorderitemselem.addEventListener('submit', (e) => {
	    e.preventDefault();
	    let targetform = e.target;
	    submitformandredirect(targetform);
	    console.log(\"A customer order items edit  form got submitted\");
	});
    }
});")))

(defun modal.cust-delete-order-item (item order-id)
  (let* ((id (slot-value item 'row-id))
	 (item-product (get-odt-product item))
         (prd-name (slot-value item-product 'prd-name)))
    (cl-who:with-html-output (*standard-output* nil)
      (:span  :height "12px" (cl-who:str prd-name))
      (with-html-form "deletecustorderitem" "doddelcustorditem" 
	(with-html-input-text-hidden "id" id)
	(with-html-input-text-hidden "ord" order-id)
	(:input :type "submit" :class "btn btn-lg btn-danger"  :value "Delete")))))

(defun createmodelfordisplayordheaderforcust (order-instance)
  (let* ((payment-mode (slot-value order-instance 'payment-mode))
	 (orderid (slot-value order-instance 'row-id))
	 (payment-mode (cond ((equal payment-mode "PRE") "Prepaid Wallet")
			     ((equal payment-mode "COD") "Cash On Demand")))
	 (orderstatus (slot-value order-instance 'status))
	 (orderdate (get-date-string (slot-value order-instance 'ord-date)))
	 (reqdate (get-date-string (slot-value order-instance 'req-date)))
	 (shipped-date (slot-value order-instance 'shipped-date))
	 (comments (slot-value order-instance 'comments)))
    (function (lambda ()
      (values orderid payment-mode orderstatus orderdate reqdate shipped-date comments)))))

(defun createwidgetsfordisplayorderheaderforcust (modelfunc)
  (multiple-value-bind (orderid payment-mode orderstatus orderdate reqdate shipped-date comments) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (:div :class "jumbotron"
			     (:div :class "row"
				   (:div :class "col-4"
					 (:span (:p (cl-who:str (format nil "Order No: ~A" orderid))))
					 (:span (:p (cl-who:str (format nil "Payment Mode: ~A" payment-mode)))))
				   (:div :class "col-4"
					 (:span (:p (cl-who:str (format nil "Status: ~A" orderstatus)))) 
					 (:span (:p (cl-who:str (format nil "Order Date: ~A" orderdate))))
					 (:span (:p (cl-who:str (format nil "Requested on: ~A" reqdate))))
					 (:span (:p (cl-who:str (format nil "Shipped on: ~A" (if shipped-date (get-date-string shipped-date)))))))
				   (:div :class "col-md-4"
					 (:span (:p (cl-who:str (format nil "Comments: ~A" comments))))))))))))
      (list widget1))))


(defun display-order-header-for-customer (order-instance)
  (with-mvc-ui-component createwidgetsfordisplayorderheaderforcust createmodelfordisplayordheaderforcust order-instance))



(defun createmodelfordisplayorderheaderforvendor (order-instance)
  (let* ((customer (get-customer order-instance))
	 (wallet (if customer (get-cust-wallet-by-vendor customer (get-login-vendor) (get-login-vendor-company))))
	 (balance (if wallet (slot-value wallet 'balance) 0))
	 (payment-mode (slot-value order-instance 'payment-mode))
	 (ship-address (slot-value order-instance 'ship-address))
	 (customer-phone (slot-value customer 'phone))
	 (orderid (slot-value order-instance 'row-id))
	 (orderstatus (slot-value order-instance 'status))
	 (cust-type (slot-value customer 'cust-type))
	 (comments (slot-value order-instance 'comments))
	 (order-fulfilled (slot-value order-instance 'order-fulfilled))
	 (orderdate (get-date-string (slot-value order-instance 'ord-date)))
	 (reqdate (get-date-string (slot-value order-instance 'req-date)))
	 (shipped-date (slot-value order-instance 'shipped-date)))
    (function (lambda ()
      (values orderid payment-mode balance customer-phone ship-address cust-type orderstatus reqdate shipped-date orderdate comments order-fulfilled)))))

(defun createwidgetsfordisplayorderheaderforvendor (modelfunc)
  (multiple-value-bind (orderid payment-mode balance customer-phone ship-address cust-type orderstatus reqdate shipped-date orderdate comments order-fulfilled) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-html-panel "panel panel-default" "Order Header"
			 (with-html-div-row 
			   (with-html-div-col 
			     (:h6 (:span "Customer Order No: ") (cl-who:str orderid)))
			   (with-html-div-col
			     (:h6 (:span "Payment Mode: ") (cl-who:str (cond ((equal payment-mode "PRE") "Prepaid Wallet")
									     ((equal payment-mode "COD") "Cash On Demand")))))
			   (with-html-div-col
			     (if (equal payment-mode "PRE") (cl-who:htm (:h6 (:span "Wallet Balance:")  (cl-who:str balance)))))
			   (with-html-div-col
			     (:h6 (:span "Customer: ") (cl-who:str customer-phone))))
			 (with-html-div-row
			   (with-html-div-col
			     (if (equal cust-type "STANDARD") (cl-who:htm (:i (:span "Ship To Address: ")  (cl-who:str ship-address)))))
			   (with-html-div-col
			     (:h6 (:span "Phone: ") (cl-who:str customer-phone)))
			   (with-html-div-col
			     (:h6 (:span "Status: " ) (cl-who:str orderstatus)))
			   (with-html-div-col
			     (:h6 (:span "Order Date: ") (cl-who:str orderdate))))
			 (with-html-div-row 
			   (with-html-div-col
			     (:h6 (:span "Requested On:") (cl-who:str reqdate)))
			   (with-html-div-col
			     (:h6 (:span "Shipped On:") (if shipped-date (cl-who:str (get-date-string shipped-date))))))
			 (with-html-div-row
			   (with-html-div-col
			     (if (equal order-fulfilled "Y")
				 (cl-who:htm (:div :class "stampbox rotated" "FULFILLED")))
			     (if (equal cust-type "GUEST") (cl-who:htm (:h6 :style "{word-break: break-all}" (:span "Comments: ")  (cl-who:str comments))))
			     (:h6 (:span "Customer Type:") (cl-who:str cust-type))))))))))
      (list widget1))))

(defun display-order-header-for-vendor (order-instance)
  (with-mvc-ui-component createwidgetsfordisplayorderheaderforvendor createmodelfordisplayorderheaderforvendor order-instance))


