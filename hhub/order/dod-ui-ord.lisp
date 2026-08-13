;;; dod-ui-ord.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
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
				  (let* ((prd (slot-value odt 'product))
					 (subtotal (calculate-order-item-cost odt))
					 (prd-name (slot-value prd 'prd-name))
					 (prd-qty (slot-value odt 'prd-qty))
					 (qty-per-unit (slot-value prd 'qty-per-unit))
					 (disc-rate (slot-value odt 'disc-rate))
					 (unit-price (slot-value odt 'unit-price)))
				    (cl-who:str (format nil "~a,~a,~a,Rs. ~$,~$,Rs. ~$,~C~C" prd-name prd-qty qty-per-unit unit-price disc-rate subtotal  #\return #\linefeed)))) odtlst)
			(cl-who:str (format nil ",,,,Total, Rs. ~$~C~C" total #\return #\linefeed)))))) ordlist)))


;; Controller for the vendor "orders by products" (demand today) view.
(defun ui-list-vendor-orders-by-products ()
  (with-vend-session-check
    (with-mvc-ui-component #'create-widgets-for-vendor-demand  #'create-model-for-vendor-demand)))

;; ---------------------------------------------------------------------------
;; Model: build the aggregated demand (by product) for the pending orders.
;; ---------------------------------------------------------------------------
(defun create-model-for-vendor-demand ()
  "Collects the aggregated demand data for the vendor's pending orders and
   returns a closure that, when funcalled, yields (values agg-with-demand company
   currsymbol vendor-name)."
  (let* ((company (get-login-vendor-company))
	 (currsymbol (get-currency-html-symbol (get-account-currency company)))
	 (ordlist (dod-get-cached-pending-orders))
	 (products (remove nil (hunchentoot:session-value :login-prd-cache)))
	 ;; Hash of the pending orders currently in view, keyed by order-id.
	 ;; Used below instead of the per-order `get-vendor-order-instance` DB call.
	 (order-ht (let ((ht (make-hash-table)))
		     (dolist (ord ordlist ht)
		       (when ord
			 (setf (gethash (slot-value ord 'order-id) ht) ord)))))
	 ;; Set of order-ids currently in view, for fast membership testing.
	 (wanted-ids (let ((hs (make-hash-table)))
		       (dolist (ord ordlist)
			 (when ord (setf (gethash (slot-value ord 'order-id) hs) t)))
		       hs))
	 ;; All pending order-items for the vendor (already cached in the session by
	 ;; `dod-gen-order-functions`). A single pass groups them by product id.
	 (all-items (remove nil (funcall (nth 2 (hunchentoot:session-value :order-func-list)))))
	 (items-by-prd (let ((ht (make-hash-table)))
			 (dolist (item all-items ht)
			   (when (and item (gethash (slot-value item 'order-id) wanted-ids))
			     (push item (gethash (slot-value item 'prd-id) ht))))))
	 ;; Single pass per product: totals + distinct orders.
	 (aggregated (mapcar (lambda (prd)
			       (let* ((prd-id (slot-value prd 'row-id))
				      (items (reverse (gethash prd-id items-by-prd)))
				      (quantity (reduce #'+ items :key (lambda (it) (slot-value it 'prd-qty)) :initial-value 0))
				      (subtotal (reduce #'+ items :key (lambda (it)
									 (* (slot-value it 'unit-price) (slot-value it 'prd-qty)))
									:initial-value 0))
				      (orders (delete-duplicates (mapcar (lambda (it)
									   (gethash (slot-value it 'order-id) order-ht))
									 items))))
				 (list prd quantity subtotal orders)))
			     products))
	 ;; Only keep products that actually have demand today.
	 (agg-with-demand (remove-if (lambda (a) (<= (nth 2 a) 0)) aggregated)))
    (function (lambda () (values agg-with-demand company currsymbol)))))


;; ---------------------------------------------------------------------------
;; View: build the widgets that get rendered on the page.
;; ---------------------------------------------------------------------------
(defun create-widgets-for-vendor-demand (modelfunc)
  "Takes the model closure, retrieves the aggregated demand data and returns a
   list of widget functions to be rendered in order."
  (multiple-value-bind (agg-with-demand company currsymbol) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
                     (cl-who:with-html-output (*standard-output* nil)
                       (with-html-div-row (:h4 "Product Demand Today"))
                       (:div :class "d-flex align-items-center justify-content-between mb-3"
                             (:span :class "badge bg-primary"
                                    (cl-who:str (format nil "Demanding products: ~A" (length agg-with-demand)))))))))
          (widget2 (function (lambda ()
                     (cl-who:with-html-output (*standard-output* nil)
                       (if agg-with-demand
			   (cl-who:str
			    (display-vendor-demand-table agg-with-demand company currsymbol))
			   (cl-who:htm
			    (:div :class "text-center py-5 text-muted"
				  (:i :class "fa-solid fa-chart-line fa-3x mb-3")
				  (:p :class "mb-0" "No product demand right now.")))))))))
      (list widget1 widget2))))


;; ---------------------------------------------------------------------------
;; View: table rendering via display-as-table + external row function.
;; ---------------------------------------------------------------------------
(defun display-vendor-demand-table (agg-with-demand company currsymbol)
  "Renders the aggregated demand data as an HTML table."
  (declare (ignore company))
  (display-as-table (list "Product" "Qty/Unit" "Unit Price" "Demand Qty" "Demand Value"
                          "Orders")
                    agg-with-demand
                    'display-vendor-demand-row
                    currsymbol))


(defun display-vendor-demand-row (row &rest arguments)
  "Row renderer for the product demand table. Each ROW is
   (prd quantity subtotal orders); the currency symbol is passed
   through ARGUMENTS."
  (let* ((prd (nth 0 row))
	 (quantity (nth 1 row))
	 (subtotal (nth 2 row))
	 (orders (nth 3 row))
	 (currsymbol (if arguments (car arguments) "")))
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" (cl-who:str (slot-value prd 'prd-name)))
      (:td :height "10px" (cl-who:str (slot-value prd 'qty-per-unit)))
      (:td :height "10px" (cl-who:str (format nil "~A ~$" currsymbol (slot-value prd 'current-price))))
      (:td :height "10px" (cl-who:str quantity))
      (:td :height "10px" (cl-who:str (format nil "~A ~$" currsymbol subtotal)))
      (:td :height "10px"
	   (mapcar (lambda (order)
		     (when order
		       (let ((order-id (slot-value order 'row-id)))
			 (cl-who:htm
			  (:span :class "badge"
				 (:a :data-bs-toggle "modal" :data-bs-target (format nil "#hhubvendorderdetails~A-modal" order-id) :href "#"
				     (:span :class "label label-info" (cl-who:str order-id))))
			  (modal-dialog-v2 (format nil "hhubvendorderdetails~A-modal" order-id)
					   "Vendor Order Details"
					   (modal.vendor-order-details order (get-login-vendor-company)))))))
		   orders)))))

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
		     (company (customer-company customer))
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
			       (let* ((prd (slot-value odt 'product))
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
	      (concatenate 'string (slot-value (slot-value odt-ins 'product) 'prd-name) ",")) odt)))

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
      


