;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


;;;;;;;;;;;;;;;;;;;;; SHOW THE INVOICE FINAL PAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun com-hhub-transaction-show-invoice-confirm-page ()
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Show Invoice Confirm Page" createmodelforshowinvoiceconfirmpage createwidgetsforshowinvoiceconfirmpage :role :vendor )))

(defun createmodelforshowinvoiceconfirmpage ()
  (let* ((company (get-login-vendor-company))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (context-id (slot-value sessioninvheader 'context-id)) 
	 (hrequestmodel (make-instance 'InvoiceHeaderContextIDRequestModel
				      :context-id context-id
				      :company company))
	 (headeradapter (make-instance 'InvoiceHeaderAdapter))
	 (invheader (processreadrequest headeradapter hrequestmodel))
	 (irequestmodel (make-instance 'InvoiceItemRequestModel
				       :company company
				       :invoiceheader invheader))
	 (itemsadapter (make-instance 'InvoiceItemAdapter))
	 (sessioninvitems (processreadallrequest itemsadapter irequestmodel)))

    (setf (slot-value sessioninvoice 'InvoiceItems) sessioninvitems)
    (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
    (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)	   
    (function (lambda ()
      (values sessioninvkey  invheader sessioninvitems)))))

(defun createwidgetsforshowinvoiceconfirmpage (modelfunc)
  (multiple-value-bind (sessioninvkey  sessioninvheader sessioninvitems) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (with-vendor-breadcrumb
			(:li :class "breadcrumb-item" (:a :href "displayinvoices" "Invoices"))
			(:li :class "breadcrumb-item" (:a :href "addcusttoinvoice" "Select Customer"))
			(:li :class "breadcrumb-item" (:a :href (format nil "vproductsforinvoicepage?sessioninvkey=~A" sessioninvkey) "Select Products"))))))
	   (widget2 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(:a :class "btn btn-primary btn-xs" :role "button" :onclick "window.print();" :href "#" "Print&nbsp;&nbsp;"(:i :class "fa-solid fa-print"))))))
	   (widget3 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(:div :id "idinvoiceitemsupdateevent"
			      (cl-who:str (display-invoice-confirm-page-widget  sessioninvheader sessioninvitems sessioninvkey)))))))
	   (widget4 (function (lambda ()
		      (submitformevent-js "#idinvoiceitemsupdateevent")))))
      
      (list widget1 widget2 widget3 widget4))))



	

(defun calculate-invoice-totalbeforetax (invoiceitems)
  (reduce #'+ (mapcar (lambda (item) (slot-value item 'taxablevalue)) invoiceitems)))

(defun calculate-invoice-totalaftertax (invoiceitems)
  (reduce #'+ (mapcar (lambda (item)
			(let* ((price (slot-value item 'price))
			      (qty (slot-value item 'qty))
			      (discountrate (slot-value item 'discount))
			      (discountvalue (if discountrate (/ (* price discountrate) 100) 0.00))
			      (cgstamt (slot-value item 'cgstamt))
			      (sgstamt (slot-value item 'sgstamt))
			      (igstamt (slot-value item 'igstamt))
			      (taxablevalue (- (* qty price) discountvalue)))
			  (fround (+ taxablevalue sgstamt cgstamt igstamt)))) invoiceitems)))


(defun calculate-invoice-totalcgst (invoiceitems)
  (reduce #'+ (mapcar (lambda (item) (slot-value item 'cgstamt)) invoiceitems)))

(defun calculate-invoice-totalsgst (invoiceitems)
  (reduce #'+ (mapcar (lambda (item) (slot-value item 'sgstamt)) invoiceitems)))

(defun calculate-invoice-totaligst (invoiceitems)
  (reduce #'+ (mapcar (lambda (item) (slot-value item 'igstamt)) invoiceitems)))

(defun calculate-invoice-totalgst (invoiceheader invoiceitems)
  (let ((placeofsupply (slot-value invoiceheader 'placeofsupply))
	(statecode (slot-value invoiceheader 'statecode)))
    (when (equal placeofsupply statecode)
      (+ (calculate-invoice-totalcgst invoiceitems) (calculate-invoice-totalsgst invoiceitems)))
    (unless (equal placeofsupply statecode)
      (calculate-invoice-totaligst invoiceitems))))

 
(defun display-invoice-confirm-page-widget (invoiceheader invoiceitems sessioninvkey)
  (logiamhere (format nil "inv number - ~A" (slot-value invoiceheader 'invnum)))
  (with-slots (row-id invnum invdate customer  custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear vendor company) invoiceheader
    (cl-who:with-html-output (*standard-output* nil)
      (:table :style "width: 100%; border-collapse: collapse; th, td {border: 1px solid black;} th, td {padding: 8px; text-align: left;}"
	      (:thead
	       (:tr 
		(:th :colspan "2" "INVOICE")
		(:th :colspan "3" "Original For Recipient")
		(:th :colspan "3" "Duplicate for Supplier")
		(:th :colspan "3" "Triplicate for Supplier")))
	      (:tbody
	       (:tr
		(:td :colspan "5" "Transportation Mode :")
		(:td :colspan "2" "Vehicle Number :")
		(:td :colspan "2" "Invoice No. :")
		(:td :colspan "2" (cl-who:str invnum)))
	       (:tr
		(:td :colspan "5" "Invoice Date :")
		(:td :colspan "2" "Date of Supply :")
		(:td :colspan "2" "Place of Supply :")
		(:td :colspan "2" "State Code:")
		(:td :colspan "2" (cl-who:str (gethash statecode *NSTGSTSTATECODES-HT*))))
	       (:tr
		(:th :colspan "5" "Details of Receiver / Billed to:")
		(:th :colspan "5" "Details of Consignee / Shipped to:"))
	       (:tr
		(:td :colspan "2" "Name :")
		(:td :colspan "3" (cl-who:str (slot-value customer 'name)))
		(:td :colspan "2" "Name :")
		(:td :colspan "3" (cl-who:str (slot-value customer 'name))))
	       (:tr
		(:td :colspan "2" "Address :")
		(:td :colspan "3" (cl-who:str (slot-value customer 'address)))
		(:td :colspan "2" "Address :")
		(:td :colspan "3" (cl-who:str (slot-value customer 'address))))
	       (:tr
		(:td :colspan "2" "GSTIN :")
		(:td :colspan "3")
		(:td :colspan "2" "GSTIN :")
		(:td :colspan="3"))
	       (:tr
		(:td :colspan "2" "State :")
		(:td :colspan "3" (cl-who:str (gethash statecode *NSTGSTSTATECODES-HT*)))
		(:td :colspan "2" "State :")
		(:td :colspan "3" (cl-who:str (gethash statecode *NSTGSTSTATECODES-HT*))))
	       (:tr 
		(:td :colspan "2" "State Code :")
		(:td :colspan "3")
		(:td :colspan "2" "State Code :")
		(:td :colspan "3"))
	       (:tr
		(:th "Sr. No")
		(mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) (list "Name of Product/Service" "HSN/SAC" "Qty Per Unit" "Qty" "Rate"  "Less: Discount%" "Taxable Value" "CGST" "SGST" "IGST" "Total")))
	       (let ((incr (let ((count 0)) (lambda () (incf count)))))
		 (mapcar (lambda (item)
			   (cl-who:htm (:tr (:td (cl-who:str (funcall incr))) (funcall 'display-invoice-item-row item sessioninvkey))))  invoiceitems))
	       ;;<!-- Repeat <tr> as needed for more items -->
	       (:tr
		(:td :colspan "3" "Total :")
		(:td :colspan "3" (cl-who:str (calculate-invoice-totalaftertax invoiceitems)))
		(:td :colspan "7"))
	       (:tr
		(:td :colspan "3" "Total Invoice Amount in Words:")
		(:td :colspan "3" (cl-who:str (convert-number-to-words-INR (calculate-invoice-totalaftertax invoiceitems))))
		(:td :colspan "7"))
	       
	       (:tr
		(:td :colspan "7" "Bank Details :")
		(:td :colspan "3" "Total Amount Before Tax :")
		(:td :colspan "3" (cl-who:str (calculate-invoice-totalbeforetax invoiceitems))))
	       
	       (:tr
		(:td :colspan "2" "Bank Account Number :")
		(:td :colspan "5")
		(:td :colspan "6" "Add : CGST :")
		(:td :colspan "6" (cl-who:str (calculate-invoice-totalcgst invoiceitems))))
	       
	       (:tr
		(:td :colspan "2" "Bank Branch IFSC :")
		(:td :colspan "5")
		(:td :colspan "6" "Add : SGST :")
		(:td :colspan "6" (cl-who:str (calculate-invoice-totalsgst invoiceitems))))
	       (:tr
		(:td :colspan "7" "Terms and Conditions :")
		(:td :colspan "6" "Add : IGST :")
		(:td :colspan "6" (cl-who:str (calculate-invoice-totaligst invoiceitems))))
	       (:tr
		(:td :colspan "7")
		(:td :colspan "6" "Tax Amount : GST :")
		(:td :colspan "6" (cl-who:str (calculate-invoice-totalgst invoiceheader invoiceitems))))
	       (:tr
		(:td :colspan "7")
		(:td :colspan "6" "Total Amount After Tax :")
		(:td :colspan "6" (cl-who:str (calculate-invoice-totalaftertax invoiceitems))))
	       (:tr
		(:td :colspan "7")
		(:td :colspan "6" "GST Payable on Reverse Charge :"))
	       (:tr
		(:td :colspan "7")
		(:td :colspan "6" "Certified that the particulars given above are true and correct."))
	       (:tr
		(:td :colspan "7")
		(:td :colspan "6" "For, [Company Name]"))
	       (:tr
		(:td :colspan "7")
		(:td :colspan "6" "(Authorized Signatory)")))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;; ADD PRODUCT TO CART TO CREATE AN INVOICE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun com-hhub-transaction-add-product-to-invoice-page ()
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Add Product To Invoice" createmodelforaddprdtoinvoice createwidgetsforaddprdtoinvoice :role :vendor )))

(defun createmodelforaddprdtoinvoice ()
  (let* ((sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))
	 (products (hunchentoot:session-value :login-prd-cache))) 
    (function (lambda ()
      (values products sessioninvitems  sessioninvkey)))))

(defun createwidgetsforaddprdtoinvoice (modelfunc)
  (multiple-value-bind (products sessioninvitems sessioninvkey) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-vendor-breadcrumb
			  (:li :class "breadcrumb-item" (:a :href "displayinvoices" "Invoices"))
			  (:li :class "breadcrumb-item" (:a :href "addcusttoinvoice" "Select Customer")))
			(with-html-div-row
			  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
				(:span "Create Invoice - Step 3: ")
				(:h2 "Select Products")))))))
	   (widget2 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-div-row
			  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"    
				(with-html-search-form "idsearchproduct" "searchproduct" "idtxtsearchproduct" "txtsearchproduct" "vsearchproductforinvoice" "onkeyupsearchform1event();" "Product Name"
				  (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
				  (submitsearchform1event-js "#idtxtsearchproduct" "#vendorproductsearchforinvoiceresult" )))
			  (:div :align "right" :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
				(:a :href (format nil "/hhub/vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) 
				    (:img :src  "/img/checkoutimage.png"  :height "100" :width "350" :alt "checkout"))))
			(:div :id "vendorproductsearchforinvoiceresult"  :class "container"
			      (cl-who:str (display-as-table (list "" "Name" "Qty Per Unit" "Price" "" "Discount" "Action") products  'display-add-product-to-invoice-row sessioninvkey sessioninvitems)))))))
	   (widget3 (function (lambda ()
		      (submitformevent-js "#vendorproductsearchforinvoiceresult")))))
      (list widget1 widget2 widget3))))
	   
(defun display-add-product-to-invoice-row (product &rest arguments)
  (let* ((sessioninvkey (first (first arguments)))
	 (sessioninvitems (second (first arguments)))
	 (prdincart-p (prdinlist-p (slot-value product 'row-id) sessioninvitems))
	 (prd-id (slot-value product 'row-id))
	 (prdname (slot-value product 'prd-name))
	 (prd-name (subseq prdname 0 (min 20 (length prdname))))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (prd-image-path (slot-value product 'prd-image-path))
	 (company (get-login-vendor-company))
	 (price (slot-value product 'unit-price))
	 (ppricing (select-product-pricing-by-product-id prd-id company))
	 (pprice (if ppricing (slot-value ppricing 'price)))
	 (pdiscount (if ppricing (slot-value ppricing 'discount)))
	 (pcurr (if ppricing (slot-value ppricing 'currency))))
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" (:img :style "width: 50px; height: 50px;" :src prd-image-path))
      (:td  :height "10px" (cl-who:str prd-name))
      (:td  :height "10px" (cl-who:str qty-per-unit))
      (:td  :height "10px" (cl-who:str (if ppricing pprice price)))
      (:td  :height "10px" (cl-who:str pcurr))
      (:td  :height "10px" (cl-who:str (if pdiscount pdiscount "NIL")))
      (:td  :height "10px"
	    (if  prdincart-p
		 (cl-who:htm (:a :class "btn btn-sm btn-success" :role "button"  :onclick "return false;" :href (format nil "javascript:void(0);")(:i :class "fa-solid fa-check")))
		 ;; else 
		 (if (and units-in-stock (> units-in-stock 0))
		     (cl-who:htm
		      (:div :class "form-group"
			    (:button :onclick "addtocartclick(this.id);" :id (format nil "btnaddproduct_~A" prd-id) :name (format nil "btnaddproduct~A" prd-id) :type "button" :class "add-to-cart-btn" :data-toggle "modal" :data-target (format nil "#producteditqty-modal~A" prd-id) (:i :class "fa-solid fa-cart-shopping") "&nbsp;Add To Cart")
			    (modal-dialog (format nil "producteditqty-modal~A" prd-id) (cl-who:str (format nil "Edit Product Quantity - Available: ~A" units-in-stock)) (vproduct-qty-add-for-invoice-html product ppricing sessioninvkey))))			
		     ;; else
		     (cl-who:htm
		      (:div :class "col-6" 
			    (:h5 (:span :class "label label-danger" "Out Of Stock"))))))))))


(defun vproduct-qty-add-for-invoice-html (product product-pricing sessioninvkey)
  (let* ((prd-id (slot-value product 'row-id))
	 (prd-image-path (slot-value product 'prd-image-path))
	 (description (slot-value product 'description))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (prd-name (slot-value product 'prd-name))
	 (hsn-code (slot-value product 'hsn-code)))
	
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-form  (format nil "form-addproduct~A" prd-id)  "vaddtocartforinvoice" 
      (with-html-input-text-hidden "prd-id" prd-id)
      (:p :class "product-name"  (cl-who:str prd-name))
      (:p :class "product-hsn-code" "HSN Code: " (cl-who:str hsn-code))
      (:a :href (format nil "dodprddetailsforcust?id=~A" prd-id) 
	  (:img :src  (format nil "~A" prd-image-path) :height "83" :width "100" :alt prd-name " "))
      (product-price-with-discount-widget product product-pricing)
      (:p (cl-who:str (if (> (length description) 150)  (subseq description  0 150) description)))
      ;; Qty increment and decrement control.
      (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
      (html-range-control "prdqty" prd-id "1" (max (mod units-in-stock 20) 10) "1" "1")
      (:div :class "form-group" 
	    (:input :type "submit"  :class "btn btn-primary" :value "Add To Cart"))))))

(defun com-hhub-transaction-search-product-for-invoice-action ()
  (with-vend-session-check
    (let* ((company (get-login-vendor-company))
	   (name (hunchentoot:parameter "txtsearchproduct"))
	   (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	   (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	   (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	   (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))
	   (products (search-products (format nil "%~A%" name) company)))
      (if (> (length products) 0)
	  (cl-who:with-html-output (*standard-output* nil)
	    (cl-who:str (display-as-table (list "" "Name"  "Qty Per Unit" "Price" "" "Discount" "Action") products  'display-add-product-to-invoice-row sessioninvkey sessioninvitems)))
	  ;; else
	  (cl-who:with-html-output (*standard-output* nil)
	    (:h3 (cl-who:str "No Records Found")))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ADD TO CART BY VENDOR FOR INVOICE GENERATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun createmodelforvendaddtocartforinvoice ()
  (let* ((company (get-login-vendor-company))
	 (prd-id (parse-integer (hunchentoot:parameter "prd-id")))
	 (prdqty (parse-integer (hunchentoot:parameter "prdqty")))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (myshopcart (hunchentoot:session-value :login-shopping-cart))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))
	 (context-id (slot-value sessioninvheader 'context-id))
	 (customer (slot-value sessioninvoice 'customer))
	 (productlist (hunchentoot:session-value :login-prd-cache))
	 (product (search-prd-in-list prd-id productlist))
	 (gstvalues (get-gstvalues-for-product product))
	 (unit-price (slot-value product 'unit-price))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (pname (slot-value product 'prd-name))
	 (prd-name (subseq pname 0 (min 30 (length pname))))
	 (hsncode (slot-value product 'hsn-code))
	 (product-pricing (select-product-pricing-by-product-id prd-id company))
	 (prd-discount (if product-pricing (slot-value product-pricing 'discount) nil))
	 (taxablevalue (- (* prdqty unit-price) (if prd-discount (/ (* prdqty  unit-price prd-discount) 100) 0.00)))
	 (placeofsupply (slot-value sessioninvheader 'placeofsupply))
	 (statecode (slot-value sessioninvheader 'statecode))
	 (intrastate (if (equal statecode placeofsupply) T NIL))
	 (interstate (if (equal statecode placeofsupply) NIL T)) 
		 (vendor (product-vendor product))
	 (wallet (get-cust-wallet-by-vendor customer vendor company))
	 (ihdadapter (make-instance 'InvoiceHeaderAdapter))
	 (ihdrequestmodel (make-instance 'InvoiceHeaderContextIDRequestModel
					 :context-id context-id
					 :company company))
	 (invheader (ProcessReadRequest ihdadapter ihdrequestmodel))
	 (redirectlocation (format nil "/hhub/vproductsforinvoicepage?sessioninvkey=~A" sessioninvkey))
	 (invitmrequestmodel (make-instance 'InvoiceItemRequestModel
					 :InvoiceHeader invheader
					 :prd-id prd-id
					 :prddesc prd-name
					 :hsncode hsncode
					 :qty prdqty
					 :uom qty-per-unit
					 :price unit-price
					 :discount prd-discount
					 :taxablevalue taxablevalue
					 :cgstrate cgstrate
					 :cgstamt cgstamt
					 :sgstrate sgstrate
					 :sgstamt sgstamt
					 :igstrate igstrate
					 :igstamt igstamt
					 :company company
					 :totalitemval totalitemval))
	 (invitmadapter (make-instance 'InvoiceItemAdapter))
	 (InvoiceItem (ProcessCreateRequest invitmadapter invitmrequestmodel)))


    (unless wallet (create-wallet customer vendor company))
    (when (and wallet (> prdqty 0) sessioninvoice)
      (setf (slot-value sessioninvoice 'InvoiceItems) (append sessioninvitems (list invoiceitem)))
      (setf (hunchentoot:session-value :login-shopping-cart) (append myshopcart (list invoiceitem)))
      (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
      (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)
      (function (lambda ()
	(values redirectlocation))))))

(defun createwidgetsforvendaddtocartforinvoice (modelfunc)
  (multiple-value-bind (redirectlocation) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     redirectlocation))))
      (list widget1)))) 

(defun com-hhub-transaction-vendor-addtocart-for-invoice-action ()
  :documentation "This function is responsible for adding the product and product quantity to the shopping cart."
  (with-cust-session-check
    (let ((uri (with-mvc-redirect-ui createmodelforvendaddtocartforinvoice createwidgetsforvendaddtocartforinvoice)))
      (format nil "~A" uri))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





(defun com-hhub-transaction-add-customer-to-invoice-page ()
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Add Customer To Invoice" createmodelforaddcusttoinvoice createwidgetsforaddcusttoinvoice :role  :vendor )))

(defun createmodelforaddcusttoinvoice()
  (let* ((company (get-login-vendor-company))
	 (guestcustomer (select-guest-customer company))
	 (guestcustid (slot-value guestcustomer 'row-id))
	 (mycustomers (select-customers-for-company company)))
    (logiamhere (format nil "Guest customer id is ~A" guestcustid))
    (function (lambda ()
      (values mycustomers guestcustid)))))

(defun createwidgetsforaddcusttoinvoice (modelfunc)
  (multiple-value-bind (mycustomers guestcustid) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-vendor-breadcrumb
			  (:li :class "breadcrumb-item" (:a :href "displayinvoices" "Invoices")))
			(with-html-div-row
			  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
				(:span "Create Invoice - Step 1: ")
				(:h2 "Select Customer (Optional)"))
			  (:div :class "col-xs-3 col-sm-3 col-md-3 col-lg-3"
				(:button :type "button" :class "btn btn-lg btn-primary btn-block" :data-toggle "modal" :data-target (format nil "#vendorcreatecustomer-modal") (:i :class "fa-solid fa-user") "&nbsp;Add Customer")
				(modal-dialog (format nil "vendorcreatecustomer-modal")  "Create Customer" (vendor-create-update-customer-dialog nil)))
			  (:div :class "col-xs-3 col-sm-3 col-md-3 col-lg-3 form-group"
				(with-html-form (format nil "invoicecreateforcust~A" guestcustid) "editinvoicepage"
				  (with-html-input-text-hidden "mode" "create")
				  (with-html-input-text-hidden "custid" guestcustid)
				  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "NEXT"))))))))
	   (widget2 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-div-row
			  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"    
				(with-html-search-form "idsearchmycustomerbyname" "searchmycustomer" "idtxtsearchcustomername" "txtsearchcustomername" "vsearchcustbyname" "onkeyupsearchform1event();" "Customer Name"
				  (submitsearchform1event-js "#idtxtsearchcustomername" "#vendormycustomerssearchresult" )))
			  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"    
				(with-html-search-form "idsearchmycustomerbyphone" "searchmycustomer" "idtxtsearchcustomerphone" "txtsearchcustomerphone" "vsearchcustbyphone" "onkeyupsearchform2event();" "Customer Phone"
				  (submitsearchform2event-js "#idtxtsearchcustomerphone" "#vendormycustomerssearchresult" ))))
			(:div :id "vendormycustomerssearchresult"  :class "container"
			      (cl-who:str (display-as-table (list "Name" "Phone" "Action") mycustomers 'display-add-customer-to-invoice-row))))))))
      (list widget1 widget2))))

(defun display-add-customer-to-invoice-row (customer &rest arguments)
  (declare (ignore arguments))
  (let* ((cust-id (slot-value customer 'row-id))
	 (cust-phone (slot-value customer 'phone))
	 (cust-name (slot-value customer 'name)))
    (with-slots (name phone address) customer
      (cl-who:with-html-output (*standard-output* nil)
	(:td  :height "10px" (cl-who:str cust-name))
	(:td  :height "10px" (cl-who:str cust-phone))
	(:td  :height "10px"
	      (with-html-form (format nil "invoicecreateforcust~A" cust-id) "editinvoicepage"
		(with-html-input-text-hidden "mode" "create")
		(with-html-input-text-hidden "custid" cust-id)
		(:div :class "form-group"
			  (:button :class "btn btn-sm btn-info" :type "submit" (:i :class "fa-solid fa-user-plus" :aria-hidden "true") "&nbsp;Create Invoice&nbsp;"))))))))
	  ;;    (:a :href (format nil "/hhub/editinvoicepage?mode=create&custid=~A" cust-id) :alt "Select Customer" (:i :class "fa-solid fa-user-plus" :aria-hidden "true")))))))

	 


(defun InvoiceHeader-search-html ()
  :description "This will create a html search box widget"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input"
		(:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
		      (with-html-search-form "idsyssearchInvoiceHeader" "syssearchInvoiceHeader" "idInvoiceHeaderlivesearch" "InvoiceHeaderlivesearch" "searchinvoicesaction" "onkeyupsearchform1event();" "Search for an Invoice"
			(submitsearchform1event-js "#idInvoiceHeaderlivesearch" "#InvoiceHeaderlivesearchresult")))))))

(defun com-hhub-transaction-show-invoices-page ()
  :description "This is a show list page for all the InvoiceHeader entities"
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "InvoiceHeader" createmodelforshowInvoiceHeader createwidgetsforshowInvoiceHeader :role  :vendor )))

(defun createmodelforshowInvoiceHeader ()
  :description "This is a model function which will create a model to show InvoiceHeader entities"
  (let* ((company (get-login-vendor-company))
	 (presenterobj (make-instance 'InvoiceHeaderPresenter))
	 (requestmodelobj (make-instance 'InvoiceHeaderRequestModel
					 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (objlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj objlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'InvoiceHeaderHTMLView))
	 (params nil))

    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-show-invoices-page" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))

(defun createwidgetsforshowInvoiceHeader (modelfunc)
 :description "This is the view/widget function for show InvoiceHeader entities" 
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-vendor-breadcrumb)
		       (InvoiceHeader-search-html)
			 (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (:h4 "Showing records for InvoiceHeader."))
		       (:div :id "InvoiceHeaderlivesearchresult" 
			     (:div :class "row"
				   (:div :class"col-xs-6"
					 (:a :href "/hhub/addcusttoinvoice" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create Invoice"))
				   (:div :class "col-xs-6" :align "right" 
					 (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
			     (:hr)
			     (cl-who:str (RenderListViewHTML htmlview viewallmodel))))))))
      (list widget1 widget2))))

(defun createwidgetsforupdateInvoiceHeader (modelfunc)
:description "This is a widgets function for update InvoiceHeader entity"      
  (createwidgetsforgenericredirect modelfunc))


(defmethod RenderListViewHTML ((htmlview InvoiceHeaderHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for InvoiceHeader entities, which will display each InvoiceHeader entity in a row"
  (when viewmodellist
    (display-as-table (list "Invoice Number" "Date" "Customer Name" "Total Value") viewmodellist 'display-InvoiceHeader-row)))

(defun createmodelforsearchInvoiceHeader ()
  :description "This is a model function for search InvoiceHeader entities/entity" 
  (let* ((search-clause (hunchentoot:parameter "InvoiceHeaderlivesearch"))
	 (company (get-login-vendor-company))
	 (presenterobj (make-instance 'InvoiceHeaderPresenter))
	 (requestmodelobj (make-instance 'InvoiceHeaderSearchRequestModel
						 :invnum search-clause
						 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (domainobjlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj domainobjlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'InvoiceHeaderHTMLView))
	 (params nil))

    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-search-invoice-action" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))

(defun createwidgetsforsearchInvoiceHeader (modelfunc)
  :description "This is a widget function for search InvoiceHeader entities"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :class "row"
			     (:div :class"col-xs-6"
				   (:a :href "/hhub/addcusttoinvoice" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create Invoice"))
			     (:div :class "col-xs-6" :align "right" 
				   (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
		       (:hr)
		       (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
      (list widget1))))

(defun com-hhub-transaction-search-invoice-action ()
  :description "This is a MVC function to search action for InvoiceHeader entities/entity" 
  (let* ((modelfunc (createmodelforsearchInvoiceHeader))
	 (widgets (createwidgetsforsearchInvoiceHeader modelfunc)))
    (display-search-results-with-widgets widgets)))

(defun createmodelforupdateInvoiceHeader ()
  :description "This is a model function for update InvoiceHeader entity"
  (let* ((invnum (hunchentoot:parameter "invnum"))
	 (invdate (get-date-from-string (hunchentoot:parameter "invdate")))
	 (custid (hunchentoot:parameter "custid"))
	 (custname (hunchentoot:parameter "custname"))
	 (custaddr (hunchentoot:parameter "custaddr"))
	 (custgstin (hunchentoot:parameter "custgstin"))
	 (statecode (hunchentoot:parameter "statecode"))
	 (billaddr (hunchentoot:parameter "billaddr"))
	 (shipaddr (hunchentoot:parameter "shipaddr"))
	 (placeofsupply (hunchentoot:parameter "placeofsupply"))
	 (revcharge (hunchentoot:parameter "revcharge"))
	 (transmode (hunchentoot:parameter "transmode"))
	 (vnum (hunchentoot:parameter "vnum"))
	 (totalvalue (float (with-input-from-string (in (hunchentoot:parameter "totalvalue"))
		     (read in))))
	 (totalinwords (hunchentoot:parameter "totalinwords"))
	 (bankaccnum (hunchentoot:parameter "bankaccnum"))
	 (bankifsccode (hunchentoot:parameter "bankifsccode"))
	 (tnc (hunchentoot:parameter "tnc"))
	 (authsign (hunchentoot:parameter "authsign"))
	 (finyear (hunchentoot:parameter "finyear"))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (company (get-login-vendor-company)) ;; or get ABAC subject specific login company function. 
	 (customer (select-customer-by-id custid company))
	 (vendor (get-login-vendor))
	 (requestmodel (make-instance 'InvoiceHeaderRequestModel
					 :invnum invnum
					 :invdate invdate
					 :customer customer
					 :custid custid
					 :custname custname
					 :custaddr custaddr
					 :custgstin custgstin
					 :statecode statecode
					 :billaddr billaddr
					 :shipaddr shipaddr
					 :placeofsupply placeofsupply
					 :revcharge revcharge
					 :transmode transmode
					 :vnum vnum
					 :totalvalue totalvalue
					 :totalinwords totalinwords
					 :bankaccnum bankaccnum
					 :bankifsccode bankifsccode
					 :tnc tnc
					 :authsign authsign
					 :finyear finyear
					 :vendor vendor
					 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (redirectlocation  (format nil "/hhub/vproductsforinvoicepage?sessioninvkey=~A" invnum))
	 (params nil))
    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-invoice-action" params 
      (handler-case 
	  (let ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
	    (when sessioninvoice
	      (setf (slot-value sessioninvoice 'invoiceheader) domainobj)
	      (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
	      (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht))	   
	    (function (lambda ()
	      (values redirectlocation domainobj))))

	(error (c)
	  (let ((exceptionstr (format nil  "Business Error:~A: ~a~%" (mysql-now) (getexceptionstr c))))
	    (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				    :direction :output
				    :if-exists :append
				    :if-does-not-exist :create)
	      (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
	    ;; return the exception.
	    (error 'hhub-business-function-error :errstring exceptionstr)))))))


		 

(defun com-hhub-transaction-create-invoice-action()
  :description "This is a MVC function for create InvoiceHeader entity"
  (with-vend-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  createmodelforcreateInvoiceHeader createwidgetsforcreateInvoiceHeader)))
      (format nil "~A" url))))

(defun createwidgetsforcreateInvoiceHeader (modelfunc)
  :description "This is a create widget function for InvoiceHeader entity"
  (createwidgetsforgenericredirect modelfunc))

(defun createmodelforcreateInvoiceHeader ()
  :description "This is a create model function for creating a InvoiceHeader entity"
  (let* ((invdate (get-date-from-string (hunchentoot:parameter "invdate")))
	 (company (get-login-vendor-company))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (context-id (hunchentoot:parameter "context-id"))
	 (custid (hunchentoot:parameter "custid"))
	 (customer (select-customer-by-id custid company))
	 (custaddr (hunchentoot:parameter "custaddr"))
	 (custgstin (hunchentoot:parameter "custgstin"))
	 (statecode (hunchentoot:parameter "statecode"))
	 (billaddr (hunchentoot:parameter "billaddr"))
	 (shipaddr (hunchentoot:parameter "shipaddr"))
	 (placeofsupply (hunchentoot:parameter "placeofsupply"))
	 (revcharge (hunchentoot:parameter "revcharge"))
	 (transmode (hunchentoot:parameter "transmode"))
	 (vnum (hunchentoot:parameter "vnum"))
	 (totalvalue (float (with-input-from-string (in (hunchentoot:parameter "totalvalue"))
		     (read in))))
	 (totalinwords (hunchentoot:parameter "totalinwords"))
	 (bankaccnum (hunchentoot:parameter "bankaccnum"))
	 (bankifsccode (hunchentoot:parameter "bankifsccode"))
	 (tnc (hunchentoot:parameter "tnc"))
	 (authsign (hunchentoot:parameter "authsign"))
	 (finyear (hunchentoot:parameter "finyear"))
	 (company (get-login-vendor-company)) ;; or get ABAC subject specific login company function.
	 (vendor (get-login-vendor))
	 (vname (get-login-vendor-name))
	 (requestmodel (make-instance 'InvoiceHeaderRequestModel
				      :context-id context-id
				      :invnum sessioninvkey
				      :invdate invdate
				      :customer customer
				      :vendor vendor
				      :custaddr custaddr
				      :custgstin custgstin
				      :statecode statecode
				      :billaddr billaddr
				      :shipaddr shipaddr
				      :placeofsupply placeofsupply
				      :revcharge revcharge
				      :transmode transmode
				      :vnum vnum
				      :totalvalue totalvalue
				      :totalinwords totalinwords
				      :bankaccnum bankaccnum
				      :bankifsccode bankifsccode
				      :tnc tnc
				      :authsign (if authsign authsign vname)
				      :finyear finyear
				      :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (redirectlocation  (format nil "/hhub/vproductsforinvoicepage?sessioninvkey=~A"  sessioninvkey))
	 (params nil))
    (setf params (acons "company" company params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-create-invoice-action" params 
      (handler-case 
	  (let* ((domainobj (ProcessCreateRequest adapterobj requestmodel))
	    	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
		 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht)))

	    (logiamhere (format nil "~A" sessioninvoices-ht))
	    (logiamhere (format nil "~A" sessioninvoice))
	    (logiamhere (format nil "session invoice customer is ~A" (slot-value (slot-value sessioninvoice 'customer) 'name)))
	;; set the InvoiceHeader context for the invoice being created and add to the session invoice. 
	    (when sessioninvoice
	      (setf (slot-value sessioninvoice 'invoiceheader) domainobj)
	      (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
	      (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht))
	    
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	(error (c)
	  (let ((exceptionstr (format nil  "Business Error:~A: ~a~%" (mysql-now) (getExceptionStr c))))
	    (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				    :direction :output
				    :if-exists :append
				    :if-does-not-exist :create)
	      (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
	    ;; return the exception.
	    (error 'hhub-business-function-error :errstring exceptionstr)))))))





(defun com-hhub-transaction-create-InvoiceHeader-dialog (&optional domainobj)
  :description "This function creates a dialog to create InvoiceHeader entity"
  (let* ((invnum  (if domainobj (slot-value domainobj 'invnum)))
	 (invdate  (if domainobj (get-date-string (slot-value domainobj 'invdate))))
	 (custaddr  (if domainobj (slot-value domainobj 'custaddr)))
	 (custgstin  (if domainobj (slot-value domainobj 'custgstin)))
	 (statecode  (if domainobj (slot-value domainobj 'statecode)))
	 (billaddr  (if domainobj (slot-value domainobj 'billaddr)))
	 (shipaddr  (if domainobj (slot-value domainobj 'shipaddr)))
	 (placeofsupply  (if domainobj (slot-value domainobj 'placeofsupply)))
	 (revcharge  (if domainobj (slot-value domainobj 'revcharge)))
	 (transmode  (if domainobj (slot-value domainobj 'transmode)))
	 (vnum  (if domainobj (slot-value domainobj 'vnum)))
	 (totalvalue  (if domainobj (slot-value domainobj 'totalvalue)))
	 (totalinwords  (if domainobj (slot-value domainobj 'totalinwords)))
	 (bankaccnum  (if domainobj (slot-value domainobj 'bankaccnum)))
	 (bankifsccode  (if domainobj (slot-value domainobj 'bankifsccode)))
	 (tnc  (if domainobj (slot-value domainobj 'tnc)))
	 (authsign  (if domainobj (slot-value domainobj 'authsign))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form (format nil "form-addInvoiceHeader~A" invnum)  (if domainobj "updateinvoiceaction" "createinvoiceaction")
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "invnum" :maxlength "20"  :value  invnum :placeholder "Invoice Number (max 20 characters) " :type "text" :readonly t))
		    
		    (:div :class "form-group" :id "charcount")
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value invdate :placeholder "invdate"  :name "invdate" ))
		    
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value custaddr :placeholder "custaddr"  :name "custaddr" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value custgstin :placeholder "custgstin"  :name "custgstin" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value statecode :placeholder "statecode"  :name "statecode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value billaddr :placeholder "billaddr"  :name "billaddr" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value shipaddr :placeholder "shipaddr"  :name "shipaddr" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value placeofsupply :placeholder "placeofsupply"  :name "placeofsupply" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value revcharge :placeholder "revcharge"  :name "revcharge" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value transmode :placeholder "transmode"  :name "transmode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value vnum :placeholder "vnum"  :name "vnum" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value totalvalue :placeholder "totalvalue"  :name "totalvalue" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value totalinwords :placeholder "totalinwords"  :name "totalinwords" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value bankaccnum :placeholder "bankaccnum"  :name "bankaccnum" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value bankifsccode :placeholder "bankifsccode"  :name "bankifsccode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value tnc :placeholder "tnc"  :name "tnc" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value authsign :placeholder "authsign"  :name "authsign" ))
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))


(defun vendor-create-update-customer-dialog (&optional customer)
  :description "This function creates a dialog to create InvoiceHeader entity"
  (let* ((firstname (when customer (slot-value customer 'firstname)))
	 (lastname (when customer (slot-value customer 'lastname)))
	 (phone (when customer (slot-value customer 'phone )))
	 (email (when customer (slot-value customer 'email)))
	 (address (when customer (slot-value customer 'address))))
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-form-having-submit-event (format nil "form-vendorcreatecustomer")  "vendorcreatecustomer"
	(with-html-input-text "firstname" "First Name" "First Name" firstname  nil "Enter First Name" 1)
	(with-html-input-text "lastname" "Last Name" "Last Name" lastname  nil "Enter Last Name" 2)
	(with-html-input-text "phone" "Phone" "Phone" phone nil "Enter Phone Number" 3)
	(with-html-input-text "email" "Email" "Email" email nil "Enter Email" 4)
	(with-html-input-textarea "address" address  "Address" "Address" nil "Enter Address" 6 3)
	(:div :class "form-group"
	      (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))
		    

(defun com-hhub-transaction-vendor-create-customer-action ()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforvendorcreatecustomer createwidgetsforvendorcreatecustomer)))

(defun createmodelforvendorcreatecustomer ()
  (let* ((fname (hunchentoot:parameter "firstname"))
	 (lname (hunchentoot:parameter "lastname"))
	 (cphone (hunchentoot:parameter "phone"))
	 (cemail (hunchentoot:parameter "email"))
	 (caddress (hunchentoot:parameter "address"))
	 (cname (format nil "~A ~A" fname lname))
	 (company (get-login-vendor-company))
	 (customer (select-customer-by-phone cphone company))
	 (password (hhub-random-password 8))
	 (salt (createciphersalt))
	 (encryptedpass (check&encrypt password password salt))
	 (redirectlocation "/hhub/addcusttoinvoice"))

    ;; Create customer scenario
    (unless customer (create-customer cname caddress cphone cemail nil encryptedpass salt nil nil nil company))
    
    (when customer 
      (with-slots (firstname lastname name email phone address) customer
	(setf firstname fname)
	(setf lastname lname)
	(setf name cname)
	(setf email cemail)
	(setf phone cphone)
	(setf address caddress))
      (clsql:update-records-from-instance customer))
    (function (lambda ()
      redirectlocation))))
      
(defun createwidgetsforvendorcreatecustomer (modelfunc)
  :description "This is a widgets function for create/update customer by vendor"      
  (createwidgetsforgenericredirect modelfunc))
  
(defun display-InvoiceHeader-row (viewmodel &rest arguments)
  (declare (ignore arguments ))
  (with-slots (invnum invdate customer totalvalue) viewmodel
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "10px" (cl-who:str  invnum))
      (:td  :height "10px" (cl-who:str (get-date-string invdate)))
      (:td  :height "10px" (cl-who:str (slot-value customer 'name)))
      (:td  :height "10px" (cl-who:str totalvalue))
      (:td  :height "10px" (:a :href (format nil "/hhub/editinvoicepage?invnum=~A" invnum) :alt "Edit Invoice" (:i :class "fa-solid fa-pencil"))))))

	


(defun com-hhub-transaction-update-invoice-action()
  :description "This is the MVC function to update action for InvoiceHeader entity"
  (with-vend-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  createmodelforupdateInvoiceHeader createwidgetsforupdateInvoiceHeader)))
      (format nil "~A" url))))


(defun com-hhub-transaction-edit-invoice-header-page()
  :description "This is the MVC function to show invoice header page"
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Edit Invoice" createmodelforeditinvoiceheaderpage createwidgetsforeditinvoiceheaderpage :role :vendor)))



(defun createmodelforeditinvoiceheaderpage ()
  (let* ((company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (custid (hunchentoot:parameter "custid"))
	 (inum (hunchentoot:parameter "invnum"))
	 (mode (hunchentoot:parameter "mode"))
	 (finyear (current-year-string))
	 (adapter (make-instance 'InvoiceHeaderAdapter))
	 (customer (if custid (select-customer-by-id custid company)))
	 (busobj (make-instance 'InvoiceHeader
				:context-id (format nil "~A" (uuid:make-v1-uuid))
				:company company
				:vendor vendor
				:customer customer
				:finyear finyear
				:placeofsupply *NSTGSTBUSINESSSTATE*
				:statecode *NSTGSTBUSINESSSTATE*
				:tnc *NSTGSTINVOICETERMS*
				:authsign (get-login-vendor-name)
				:revcharge "No"))
	 (requestmodel (make-instance 'InvoiceHeaderRequestModel
				      :invnum inum
				      :company company))
	 (invoiceobj (if inum (ProcessReadRequest adapter requestmodel) busobj))
	 ;; When we are creating a new invoice, we would like to save it in the session with context of
	 ;; customer, invoice header and invoice items. Here we start with adding the customer context. 
	 (sessioninvkey (if inum inum (format nil "NST000~A" (hhub-random-password 10))))
	 (newsessioninvoice (make-instance 'SessionInvoice))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht)))
	   ;; set the customer context for the invoice being created and add to the session invoice. 
    (setf (slot-value newsessioninvoice 'customer) (customer invoiceobj))
    (setf (slot-value newsessioninvoice 'InvoiceItems) '())
    (setf (slot-value newsessioninvoice 'InvoiceHeader) invoiceobj)
    (setf (gethash sessioninvkey sessioninvoices-ht) newsessioninvoice)
    (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)
  (with-slots (context-id invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear customer ) invoiceobj
    (function (lambda()
      (values context-id invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear customer  mode sessioninvkey))))))


(defun createwidgetsforeditinvoiceheaderpage (modelfunc)
  (multiple-value-bind (context-id invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear customer  mode sessioninvkey) (funcall modelfunc)
    (let* ((widget1 (editinvoicewidget-section1 sessioninvkey context-id invnum invdate  custgstin statecode finyear customer))
	   (widget2 (editinvoicewidget-section2 custaddr billaddr shipaddr))
	   (widget3 (editinvoicewidget-section3 placeofsupply revcharge transmode vnum totalvalue totalinwords))
	   (widget4 (editinvoicewidget-section4 bankaccnum bankifsccode tnc authsign))
	   (widget5 (function (lambda ()
		     (submitformevent-js "#idupdateinvoiceaction"))))
	   (widget6 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-vendor-breadcrumb
			  (:li :class "breadcrumb-item" (:a :href "displayinvoices" "Invoices"))
			  (:li :class "breadcrumb-item" (:a :href "addcusttoinvoice" "Select Customer")))
			(:span "Create Invoice - Step 2: ")
			(:span (cl-who:str sessioninvkey))
			(:h2 "Fill Invoice Details For")
			(:div :id "idupdateinvoiceaction" 
			      (with-html-form (format nil "form-addInvoiceHeader~A" invnum) (if (equal mode "create") "createinvoiceaction" "updateinvoiceaction")
				(with-html-div-row
				  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
					(funcall widget1))
				  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
					(funcall widget2)))
				(with-html-div-row
				  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
					(funcall widget3))
				  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
					      (funcall widget4)))
				(funcall widget5))))))))
      (list widget6))))


(defun editinvoicewidget-section1 (sessioninvkey context-id invnum invdate  custgstin statecode finyear customer)
  (function (lambda ()
    (let ((charcountid1 (format nil "idchcount~A" (hhub-random-password 3)))
	  (finyear-ht (make-hash-table :test 'equal)))
      (setf (gethash (current-year-string--) finyear-ht) (current-year-string--))
      (setf (gethash (current-year-string) finyear-ht) (current-year-string))
      (setf (gethash (current-year-string++) finyear-ht) (current-year-string++))
      (unless statecode (setf statecode *NSTGSTBUSINESSSTATE*))

      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	      (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
	      (with-html-input-text-hidden "context-id" context-id)
	      (with-html-input-text-hidden "custid" (cl-who:str (slot-value customer 'row-id)))
	      (with-html-input-text-hidden "custname" (cl-who:str (slot-value customer 'name)))
	      (:h3 (:span (cl-who:str (slot-value customer 'name))))
	      (:h3 (:span (cl-who:str (slot-value customer 'phone)))))
	(:div :class "form-group"
	    (:label :for "finyear" "Financial Year")
	    (with-html-dropdown "finyear" finyear-ht finyear))
	(:div :class "form-group"
	      (:label :for "invnum" "Invoice Number")
	      (:input :class "form-control" :name "invnum" :maxlength "20"  :value  invnum :placeholder "Invoice Number (max 20 characters) " :type "text" :readonly t))
	(:div :class "form-group"
	      (:label :for "invdate" "Invoice Date")
	      (:input :class "form-control" :type "text" :value (get-date-string invdate) :placeholder "invdate"  :name "invdate" ))
	(:div :class "form-group"
	      (:label :for "custgstin" "Customer GST Number")
	      (:input :class "form-control" :type "text" :value custgstin :onkeyup (format nil "countChar(~A.id, this, 15)" charcountid1) :placeholder "Customer GST Number"  :name "custgstin" )
	      (:div :class "form-group" :id charcountid1))
	(:div :class "form-group"
	      (:label :for "statecode" "Select State")
	      (with-html-dropdown "statecode" *NSTGSTSTATECODES-HT* statecode)))))))


(defun editinvoicewidget-section2 (custaddr billaddr shipaddr)
  (function (lambda ()
    (let ((charcountid1 (format nil "idchcount~A" (hhub-random-password 3)))
	  (charcountid2 (format nil "idchcount~A" (hhub-random-password 3)))
	  (charcountid3 (format nil "idchcount~A" (hhub-random-password 3))))
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "NEXT"))
	(:div :class "form-group"
	      (:label :for "custaddr" "Customer Address")
	      (:textarea :class "form-control" :name "custaddr"  :placeholder "Enter Address ( max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 200)" charcountid1) (cl-who:str (format nil "~A" custaddr)))
	      (:div :class "form-group" :id charcountid1))
	(:div :class "form-group"
	      (:label :for "billaddr" "Billing Address")
	      (:textarea :class "form-control" :name "billaddr"  :placeholder "Enter Billing Address ( max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 200)" charcountid2) (cl-who:str (format nil "~A" billaddr)))
	      (:div :class "form-group" :id charcountid2 ))
	(:div :class "form-group"
	      (:label :for "shipaddr" "Shipping Address")
	      (:textarea :class "form-control" :name "shipaddr"  :placeholder "Enter Shipping Address ( max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 200)" charcountid3) (cl-who:str (format nil "~A" shipaddr)))
	      (:div :class "form-group" :id charcountid3)))))))
  

(defun editinvoicewidget-section3 ( placeofsupply revcharge transmode vnum totalvalue totalinwords)
  (function (lambda ()
    (let ((revcharge-ht (make-hash-table :test 'equal))
	  (transmode-ht (make-hash-table :test 'equal))
	  (placeofsupply-ht (make-hash-table :test 'equal)))
      
      (setf (gethash "Yes" revcharge-ht) "Yes") 
      (setf (gethash "No" revcharge-ht) "No")
      (setf (gethash "NA" transmode-ht) "Not Applicable")
      (setf (gethash "Road" transmode-ht) "Road")
      (setf (gethash "Rail" transmode-ht) "Rail")
      (setf (gethash "Air" transmode-ht) "Air")
      (setf (gethash "Ship/Waterways" transmode-ht) "Ship/Waterways")
      (setf (gethash "INTRASTATE" placeofsupply-ht) "Intra-State (CGST + SGST)")
      (setf (gethash "INTERSTATE"  placeofsupply-ht) "Inter-State (IGST)")
      
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	      (:label :for "placeofsupply" "Place Of Supply")
	      (with-html-dropdown "placeofsupply" *NSTGSTSTATECODES-HT* placeofsupply))
	;;(with-html-dropdown "placeofsupply" placeofsupply-ht placeofsupply))
	(:div :class "form-group"
	      (:label :for "revcharge" "Reverse Charge")
	      (with-html-dropdown "revcharge" revcharge-ht revcharge))
	(:div :class "form-group"
	      (:label :for "transmode" "Transport Mode")
	      (with-html-dropdown "transmode" transmode-ht transmode))
	(:div :class "form-group"
	      (:label :for "vnum" "Vehicle Number")
	      (:input :class "form-control" :type "text" :value vnum :placeholder "Vehicle Number"  :name "vnum" ))
	(:div :class "form-group" :style "display:none;"
	      (:label :for "totalvalue" "Total Value")
	      (:input :class "form-control" :type "text" :value totalvalue :placeholder "Total Value"  :name "totalvalue" ))
	(:div :class "form-group" :style "display:none;"
	      (:label :for "totalinwords" "Total In Words")
	      (:input :class "form-control" :type "text" :value totalinwords :placeholder "Total In Words"  :name "totalinwords" )))))))

(defun editinvoicewidget-section4 (bankaccnum bankifsccode tnc authsign)
  (function (lambda ()
    (let ((charcountid1 (format nil "idchcount~A" (hhub-random-password 3))))
      (cl-who:with-html-output (*standard-output* nil)
	
	(:div :class "form-group"
	      (:label :for "bankaccnum" "Bank Account Number")
	      (:input :class "form-control" :type "text" :value bankaccnum :placeholder "bankaccnum"  :name "bankaccnum" ))
	(:div :class "form-group"
	      (:label :for "bankifsccode" "Bank IFSC Code")
	      (:input :class "form-control" :type "text" :value bankifsccode :placeholder "bankifsccode"  :name "bankifsccode" ))
	(:div :class "form-group"
	      (:label :for "tnc" "Invoice Terms")
	      (:textarea :class "form-control" :name "tnc"  :placeholder "Enter Invoice Terms (Max 200 characters) "  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 1000)" charcountid1) (cl-who:str (format nil "~A" tnc)))
	      (:div :class "form-group" :id charcountid1 ))
        (:div :class "form-group"
	    (:label :for "invnum" "Authorised Signatory")
	    (:input :class "form-control" :type "text" :value authsign :placeholder "authsign"  :name "authsign" ))
      
	(:div :class "form-group"
	    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "NEXT")))))))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
