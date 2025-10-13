;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun com-hhub-transaction-show-customer-upi-page ()
  (with-cust-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Customer UPI page" #'create-model-for-showcustomerupipage #'create-widgets-for-showcustomerupipage :role :customer )))

(defun create-model-for-showcustomerupipage ()
  (let* ((orderparams-ht (get-cust-order-params))
	 (order-items (gethash "shoppingcart" orderparams-ht))
	 (shopcart-products (gethash "shopcartproducts" orderparams-ht))
	 (context-id "")
	 (vendor-list (get-shopcart-vendorlist order-items))
	 (vendor (first vendor-list))
	 (shipaddr (gethash "shipaddress" orderparams-ht))
	 (shipzipcode (gethash "shipzipcode" orderparams-ht))
	 (shipcity (gethash "shipcity" orderparams-ht))
	 (shipstate (gethash "shipstate" orderparams-ht))
	 (billaddr (gethash "billaddress" orderparams-ht))
	 (billzipcode (gethash "billzipcode" orderparams-ht))
	 (billcity (gethash "billcity" orderparams-ht))
	 (billstate (gethash "billstate" orderparams-ht))
	 (billsameasship (gethash "billsameasshipchecked" orderparams-ht))
	 (gstnumber (gethash "gstnumber" orderparams-ht))
	 (gstorgname (gethash "gstorgname" orderparams-ht))
	 (shipping-cost (gethash "shipping-cost" orderparams-ht))
	 (order-amt (+ shipping-cost (gethash "shopcart-total" orderparams-ht)))
	 (ord-date (gethash "orddate" orderparams-ht))
	 (req-date (gethash "reqdate" orderparams-ht))
	 (shipped-date (gethash "shipdate" orderparams-ht))
	 (expected-delivery-date (gethash "expected-delivery-date" orderparams-ht))
	 (order-type (gethash "order-type" orderparams-ht))
	 (payment-mode (gethash "paymentmode" orderparams-ht))
	 (comments (gethash "comments" orderparams-ht))
	 (storepickupenabled (gethash "orderpickupinstore" orderparams-ht))
	 (customer (get-login-customer))
	 (company (get-login-customer-company))
	 (custname (slot-value customer 'name))
	 (is-cancelled nil)
	 (cancel-reason nil)
	 (external-url "NIL")
	 (is-converted-to-invoice "NO")
	 (ordnum "000")
	 (order-fulfilled " ")
	 (status "DRAFT")
	 
	 ;;(redirectlocation "/hhub/dodcustordsuccess")
	 (order-source (gethash "order-source" orderparams-ht))
	 (total-discount (gethash "total-discount" orderparams-ht))
	 (total-tax (gethash "total-tax" orderparams-ht))
	 (orderheader (createorderobject (function (lambda () (values  ord-date req-date shipped-date expected-delivery-date ordnum shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship storepickupenabled gstnumber gstorgname order-fulfilled order-amt shipping-cost total-discount total-tax payment-mode comments context-id  status is-converted-to-invoice is-cancelled cancel-reason order-type external-url order-source custname customer company)))))
	 (order-cxt (format nil "#ORDER:UPI~A" (get-universal-time)))
	 (qrcodepath (format nil "~A/img~A" *siteurl* (generateqrcodeforvendor vendor "ABC" order-cxt  order-amt)))
	 (upiappurls (generateupiurlsforvendor vendor "ABC" order-cxt order-amt))
	 (ordertemplate (funcall (nst-get-cached-order-template-func :templatenum 1)))  
	 (orderitemshtmlfunc (ordertemplatefillitemrows order-items shopcart-products))
	 (currency (get-account-currency company))
	 (charcountid1 (format nil "idchcount~A" (hhub-random-password 3)))
	 (params nil))

    (setf ordertemplate (funcall (ordertemplatefillforupipage ordertemplate orderheader order-items orderitemshtmlfunc qrcodepath currency vendor)))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    
    
      (function (lambda ()
	(values ordertemplate qrcodepath upiappurls charcountid1 order-amt currency)))))


(defun create-widgets-for-showcustomerupipage (modelfunc)
  (multiple-value-bind (ordertemplate qrcodepath upiappurls charcountid1 order-amt currency) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		     (with-customer-breadcrumb
		       (:li :class "breadcrumb-item" (:a :href "dodcustshopcart" "Cart"))
		       (:li :class "breadcrumb-item" (:a :href "dodcustordershipaddrpage" "Address"))))))
	   (widget2 (function (lambda()
		      (with-html-form-having-submit-event  "customerupipaymentform" "dodmyorderaddaction" 
			(with-html-div-row 
			  (with-html-div-col-10
			    (display-upi-widget order-amt currency qrcodepath upiappurls)))
			(with-html-div-row
			  (with-html-div-col-10
			    ;;(:div :class "col-sm-8" :style "text-align: center;"
			    (:label :for "utrnum" "UTR No")
			    (:input :class "form-control" :name "paymentmode" :value "UPI" :type "hidden")
			    (:input :class "form-control" :name "amount" :value order-amt :type "hidden")
			    (:div :class "input-group mb-3"
				  (:input :class "form-control" :name "utrnum" :value "" :placeholder "12 Digit UTR Number" :type "number" :onkeyup (format nil "countChar(~A.id, this, 12)" charcountid1)  :max "999999999999" :maxlength "12"  :required T)
				  (:div :id charcountid1 :class "input-group-text" :style "font-size: 1.2rem; font-weight: bold; color: purple;"))))
			(with-html-div-row
			   (with-html-div-col-6
			     (:a :role "button" :class "btn btn-lg btn-primary btn-block" :href "hhubcustpaymentmethodspage" "Previous"))
			  (with-html-div-col-6
			    (:input :type "submit" :class "btn btn-lg btn-primary btn-block checkout-button"  :value "Place Order")))))))
	   
	   (widget3 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(cl-who:str ordertemplate))))))
	   (list widget1 widget2 widget3 ))))

(defun ordertemplatefillforupipage (ordertemplate order orderitems orderitemshtmlfunc qrcodepath  currency vendor)
  (function (lambda ()
    (with-slots (name address gstnumber state) vendor
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Vendor Name%" ordertemplate name))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Vendor Address%" ordertemplate address))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Vendor GST Number%" ordertemplate gstnumber))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Place of Supply%" ordertemplate (string-upcase state))))


    (with-slots (values  ord-date req-date shipped-date expected-delivery-date ordnum shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship storepickupenabled gstnumber gstorgname order-fulfilled order-amt shipping-cost total-discount total-tax payment-mode comments context-id  status is-converted-to-invoice is-cancelled cancel-reason order-type external-url order-source custname customer company) order
      ;;(setf ordertemplate (cl-ppcre:regex-replace-all "%Invoice Number%" ordertemplate ordnum))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Order Number%" ordertemplate ordnum))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Order Date%" ordertemplate (get-date-string ord-date)))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Date of Supply%" ordertemplate (get-date-string expected-delivery-date)))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%State Code%" ordertemplate shipstate))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Billed To%" ordertemplate custname))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Shipped To%" ordertemplate custname))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Billed to Address%" ordertemplate billaddr))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Shipped to Address%" ordertemplate shipaddr))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Billed to GSTIN%" ordertemplate ""))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Shipped to GSTIN%" ordertemplate ""))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Billed to State%" ordertemplate billstate))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Shipped to State%" ordertemplate shipstate))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%UPI_IMAGE_URL%" ordertemplate qrcodepath))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Shipping Charges%" ordertemplate (format nil "~A" shipping-cost)))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Total in Words%" ordertemplate (convert-number-to-words-INR order-amt)))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Add Total With GST%" ordertemplate (format nil "~A" (calculate-order-totalaftertax orderitems))))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Total Value before GST/TAX%" ordertemplate (format nil "~A" (calculate-order-totalbeforetax orderitems))))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Total After Tax & Shipping%" ordertemplate (format nil "~A ~A" (get-currency-html-symbol currency) order-amt)))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Tax Amount%" ordertemplate (format nil "~A" (calculate-order-totalgst order orderitems vendor))))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Add CGST%" ordertemplate (format nil "~A" (calculate-order-totalcgst orderitems))))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Add SGST%" ordertemplate (format nil "~A" (calculate-order-totalsgst orderitems))))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Add IGST%" ordertemplate (format nil "~A" (calculate-order-totaligst orderitems))))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Terms and Conditions%" ordertemplate "Terms and Conditions"))
       (setf ordertemplate (cl-ppcre:regex-replace-all "%Authorised Signatory%" ordertemplate "Vendor Name"))
       (setf ordertemplate (cl-ppcre:regex-replace-all "%Financial Year%" ordertemplate "NA"))
       (setf ordertemplate (cl-ppcre:regex-replace-all "%Company Name%" ordertemplate (slot-value company 'name)))
       (setf ordertemplate (cl-ppcre:regex-replace-all "%Bank IFSC Code%" ordertemplate "NA"))
       (setf ordertemplate (cl-ppcre:regex-replace-all "%Bank Account Number%" ordertemplate "NA"))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%GST on Reverse Charge%" ordertemplate "0.00")))
      (setf ordertemplate (cl-ppcre:regex-replace-all "%Order Items Rows%" ordertemplate (funcall orderitemshtmlfunc)))
      ordertemplate)))




(defun ordertemplatefillitemrows (orderitems products)
  (function (lambda ()
    (cl-who:with-html-output-to-string (*standard-output* nil)
	(let ((incr (let ((count 0)) (lambda () (incf count)))))
	  (mapcar (lambda (item product) (cl-who:htm (:tr (:td (cl-who:str (funcall incr))) (display-order-item-row item product))))  orderitems products))))))

(defun display-order-item-row (orderitem product)
  (cl-who:with-html-output (*standard-output* nil)
    (with-slots (prd-qty unit-price disc-rate taxablevalue sgst cgst igst sgstamt cgstamt igstamt totalitemval) orderitem
      (cl-who:htm
       (:td :height "10px" (cl-who:str (slot-value product 'prd-name)))
       (:td :height "10px" (cl-who:str (slot-value product 'hsn-code)))
       (:td :height "10px" (cl-who:str (slot-value product 'unit-of-measure)))
       (:td :height "10px" (cl-who:str prd-qty))
       (:td :height "10px" (cl-who:str unit-price))
       (:td :height "10px" (cl-who:str disc-rate))
       (:td :height "10px" (cl-who:str taxablevalue))
       (:td :height "10px" (cl-who:str cgstamt))
       (:td :height "10px" (cl-who:str sgstamt))
       (:td :height "10px" (cl-who:str igstamt))
       (:td :height "10px" (cl-who:str totalitemval))))))


(defun generateqrcodeforvendor  (vendor retailer-category-code transaction-id amount)
  ;; upiapp values are phonepe, paytmmp, gpay, upi
  (let* ((upi-id (slot-value vendor 'upi-id))
	 (vendor-name (slot-value vendor 'name))
	 (paymentstr (format nil "\'upi://pay?pa=~A&pn=~A&am=~d&tr=~A&cu=INR&mc=~A\'" upi-id vendor-name amount transaction-id retailer-category-code))
	 (filename (format nil "/temp/upiqr~A.png" (get-universal-time)))
	 (filepath (format nil "~A~A" *HHUBRESOURCESDIR* filename))
	 (qrcodecmd (format nil "qrencode -s 5 -l L -v 5 -o ~A ~A" filepath paymentstr)))
	 
    (when upi-id
      (sb-ext:run-program "/bin/sh" (list "-c" qrcodecmd ) :input nil :output *standard-output*)
      filename)))




(defun generateupiurlsforvendor  (vendor retailer-category-code transaction-id amount)
  :description "Generates the UPI payment URLs for a vendor and returns an url list containing one url per app. upiapp values are phonepe, paytmmp, gpay, upi"
  (let* ((paymentapps (list "phonepe" "paytmmp" "gpay" "upi"))
	 (upi-id (slot-value vendor 'upi-id))
	 (vendor-name (slot-value vendor 'name)))
    (when upi-id 
      (mapcar (lambda (upiapp)
		(let ((paymenturl (format nil "~A://pay?pa=~A&pn=~A&am=~d&tr=~A&cu=INR&mc=~A" upiapp upi-id vendor-name amount transaction-id retailer-category-code)))
		  paymenturl)) paymentapps))))


(defun display-upi-widget (amount currency qrcodepath upiappurls)
  (let ((upiappnames (list "Phone Pe" "Pay TM" "Google Pay" "UPI"))
	(utrnumhelplinkimage (format nil "~A/img/~A" *siteurl* *HHUBUTRNUMHELPIMG* )))
    (cl-who:with-html-output (*standard-output* nil)
      (:hr)
      (:h5 (cl-who:str (format nil "Complete Your Payment")))
      (:h4 (cl-who:str (format nil "Total Amount = ~A ~$" (get-currency-html-symbol currency) amount)))
      (:hr)
      (:div :id "withCountDownTimerExpired" 
	    (with-html-div-row 
	      (with-html-div-col :style "text-align: center;"
		(:p "This session will expire in" (:div :id "withCountDownTimer"))))
	    (when (> (length upiappurls) 0)
	      (mapcar
	       (lambda (url appname)
		 (cl-who:htm
		  (with-html-div-row 
		    (with-html-div-col :style "text-align: center;"
		      (:a :href url (cl-who:str appname)))))) upiappurls upiappnames)
	      (with-html-div-row 
		(with-html-div-col :style "text-align: center;"
		  (:img :style "width: 200px; height: 200px;" :src qrcodepath)))))
      (:hr)
      (:h5 "1. Pay Now: Scan the UPI QR or click a link above to pay. You will not be redirected back.")
      (:h5 "2. Confirm Order: After successful payment, locate the 12-digit Reference ID (or UTR) in your payment app. You must paste this ID into the box below and click 'Place Order' to complete your order.")
      (:p
       (:h5 "Having trouble? Click here for a step-by-step guide to finding your Reference ID.")
       (:a :href utrnumhelplinkimage :target "_blank" "Click Here"))
      (:script "window.onload = function() {countdowntimer(0,0,5,0);}"))))


(defun create-model-for-custorderpaymentpage  ()
  (let* ((orderparams-ht (get-cust-order-params)) 
	 (odts (gethash "shoppingcart" orderparams-ht))
	 (shipping-cost (gethash "shipping-cost" orderparams-ht))
	 (totalaftertax (calculate-invoice-totalaftertax odts))
	 (upitotal (+ totalaftertax shipping-cost))
	 (order-cxt (format nil "#ORDER:UPI~A" (get-universal-time)))
	 (vendor-list (get-shopcart-vendorlist odts))
	 (vendor (first vendor-list))
	 (company (get-login-customer-company))
	 (upiurls (generateupiurlsforvendor vendor "ABC" order-cxt upitotal))
	 (qrcodepath (format nil "~A/img~A" *siteurl* (generateqrcodeforvendor vendor "ABC" order-cxt  upitotal)))
	 (currency (get-account-currency company))
	 (charcountid1 (format nil "idchcount~A" (hhub-random-password 3))))
    (function (lambda ()
      (values  upitotal currency qrcodepath upiurls vendor charcountid1)))))


(defun create-widgets-for-custorderpaymentpage (modelfunc)
  (multiple-value-bind
	( upitotal currency qrcodepath upiurls vendor charcountid1)
      (funcall modelfunc) 
    (let ((widget1 (function (lambda ()
		     (with-customer-breadcrumb
		       (:li :class "breadcrumb-item" (:a :href "dodcustshopcart" "Cart"))
		       (:li :class "breadcrumb-item" (:a :href "dodcustordershipaddrpage" "Address"))))))
	  (widget2 (function (lambda ()
		     (with-html-card
			     (:title "UPI Payment"
			      :image-src (format nil "/img/~A" *HHUBUPILOGOIMG*)
			      :image-alt "UPI Payment"
			      :image-style  "width: 150px; height: 150px; background-size: cover; background-repeat: no-repeat; background-position: center;")
	    	       (with-html-div-row-fluid :style "box-shadow: rgba(17, 17, 26, 0.1) 0px 0px 16px;"
			 (display-upi-widget  upitotal currency qrcodepath upiurls))
		       (with-html-form-having-submit-event  "customerupipaymentform" "dodmyorderaddaction" 
			 (:div :class "row mb-3"
			       (:div :class "col-sm-8" :style "text-align: center;"
				     (:label :for "utrnum" "UTR No")
				     (:input :class "form-control" :name "paymentmode" :value "UPI" :type "hidden")
				     (:input :class "form-control" :name "amount" :value upitotal :type "hidden")
				     (:div :class "input-group mb-3"
				     	   (:input :class "form-control" :name "utrnum" :value "" :placeholder "12 Digit UTR Number" :type "number" :onkeyup (format nil "countChar(~A.id, this, 12)" charcountid1)  :max "999999999999" :maxlength "12"  :required T)
					   (:div :id charcountid1 :class "input-group-text" :style "font-size: 1.2rem; font-weight: bold; color: purple;"))))
			 (with-html-div-row
			   (with-html-div-col-6
			     (:a :role "button" :class "btn btn-lg btn-primary btn-block" :href "hhubcustpaymentmethodspage" "Previous"))
			   (with-html-div-col-6
			     (:input :type "submit" :class "btn btn-lg btn-primary btn-block checkout-button"  :value "Place Order")))))))))
	  ;; If Vendor UPI ID is not defined, then redirect to the UPI ID not found page. 
	  (unless (slot-value vendor 'upi-id) (hunchentoot:redirect "/hhub/vendorupinotfound"))
	  (list widget1 widget2 ))))

(defun hhub-controller-upi-customer-order-payment-page ()
  (with-cust-session-check
    (with-mvc-ui-page "Customer UPI Payment Page" #'create-model-for-custorderpaymentpage #'create-widgets-for-custorderpaymentpage :role :customer)))

(defun create-model-for-upirechargewalletpage ()
  (let* ((wallet-id (hunchentoot:parameter "wallet-id"))
	 (amount (hunchentoot:parameter "amount"))
	 (custcomp (get-login-customer-company))
	 (currency (get-account-currency custcomp))
	 (wallet (get-cust-wallet-by-id wallet-id custcomp))
	 (vendor (get-vendor wallet))
	 (transaction-id (format nil "#WAL:~A" (get-universal-time)))
	 (upiurls (generateupiurlsforvendor vendor "ABC" transaction-id amount))
	 (charcountid1 (format nil "idchcount~A" (hhub-random-password 3)))
	 (qrcodepath (format nil "~A/img~A" *siteurl* (generateqrcodeforvendor vendor "ABC" transaction-id amount))))
    (function (lambda ()
      (values amount currency qrcodepath upiurls wallet-id transaction-id charcountid1)))))

(defun create-widgets-for-upirechargewalletpage (modelfunc)
  (multiple-value-bind (amount currency qrcodepath upiurls wallet-id transaction-id charcountid1)
      (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (if qrcodepath
			 (with-html-card
			     (:title "UPI Payment"
			      :image-src "/img/UPI.png"
			      :image-alt "UPI Payment"
			      :image-style "width: 200px; height: 200px;")
	    		   (with-html-div-row-fluid :style "box-shadow: rgba(17, 17, 26, 0.1) 0px 0px 16px;"
			     (display-upi-widget amount currency qrcodepath upiurls)
			     (with-html-form "customerupipaymentform" "hhubcustwalletrechargeaction"
			       (:div :class "row mb-3"
				     (:div :class "col" :style "text-align: center;"
					   (:input :class "form-control" :name "wallet-id" :value wallet-id :type "hidden")
					   (:input :class "form-control" :name "amount" :value amount :type "hidden")
					   (:input :class "form-control" :name "transaction-id" :value transaction-id :type "hidden")
					   (:label :for "utrnum" "UTR No")
					   (:div :class "input-group mb-3"
						 (:input :class "form-control" :name "utrnum" :value "" :placeholder "12 Digit UTR Number" :type "number" :onkeyup (format nil "countChar(~A.id, this, 12)" charcountid1)  :max "999999999999" :maxlength "12"  :required T)
					   (:div :id charcountid1 :class "input-group-text" :style "font-size: 1.2rem; font-weight: bold; color: purple;"))))
			     (:div :class "row mb-3"
				   (:div :class "col" :style "text-align: center;"
					 (:button :class "btn btn-lg btn-primary btn-block" :type "submit" (cl-who:str (format nil "Recharge Wallet for ~A" amount))))))))
			 ;;else
			 (with-html-div-row-fluid :style "box-shadow: rgba(17, 17, 26, 0.1) 0px 0px 16px;"
			   (:h2 (cl-who:str "UPI Details for Vendor Missing"))))))))
      (list widget1))))
  
(defun hhub-controller-upi-recharge-wallet-page ()
  (with-cust-session-check
    (with-mvc-ui-page "Customer Recharge Wallet - UPI Payment Page" #'create-model-for-upirechargewalletpage #'create-widgets-for-upirechargewalletpage :role :customer)))
  
(defun hhub-controller-upi-recharge-wallet-action ()
  (with-cust-session-check
    (let* ((wallet-id (hunchentoot:parameter "wallet-id"))
	   (transaction-id (hunchentoot:parameter "transaction-id"))
	   (amount (with-input-from-string (in (hunchentoot:parameter "amount"))
		     (read in)))
	   (utrnum (hunchentoot:parameter "utrnum"))
	   (custcomp (get-login-customer-company))
	   (wallet (get-cust-wallet-by-id wallet-id custcomp))
	   (vendor (get-vendor wallet))
	   (customer (get-customer wallet))
	   (phone (slot-value customer 'phone))
	   (current-balance (slot-value wallet 'balance))
	   (latest-balance (+ current-balance amount))
	   (requestmodel (make-instance 'UpiPaymentsRequestModel
					:vendor vendor
					:customer customer
					:amount amount
					:phone phone
					:transaction-id transaction-id
					:utrnum utrnum
					:company custcomp))
	   (upipaymentsadapter (make-instance 'UpiPaymentsAdapter)))
      
      (when wallet
	;; We are creating the UPI domain model object. It also saves the UPI payment transaction to DB.
	(ProcessCreateRequest upipaymentsadapter requestmodel)
	  ;; Update the wallet balance in future.
	(hhub-add-pending-upi-task utrnum (function (lambda () (set-wallet-balance latest-balance wallet))))
	(hunchentoot:redirect (format nil "/hhub/dodcustwallet"))))))


(defun hhub-add-pending-upi-task (utrnum pendingfunction)
  (setf (gethash utrnum *HHUBPENDINGUPIFUNCTIONS-HT*) pendingfunction))

(defun hhub-execute-pending-upi-task (utrnum &optional (cancel nil))
  (let ((func (gethash utrnum *HHUBPENDINGUPIFUNCTIONS-HT*)))
    (if (and func (not cancel)) 
	(funcall func))
    (remhash utrnum *HHUBPENDINGUPIFUNCTIONS-HT*)))

(defun save-upi-transaction (amount utrnum transaction-id customer vendor company phone)
  :description "Save the UPI transaction to the DB and return the domain object."
  (let* ((requestmodel (make-instance 'UpiPaymentsRequestModel
					:vendor vendor
					:customer customer
					:amount amount
					:transaction-id transaction-id
					:utrnum utrnum
					:phone phone
					:company company))
	     (upipaymentsadapter (make-instance 'UpiPaymentsAdapter)))
	
      ;; We are creating the UPI domain model object. It also saves the UPI payment transaction to DB.
      (ProcessCreateRequest upipaymentsadapter requestmodel)
      ;; currently we do not have any pending task. 
      (hhub-add-pending-upi-task utrnum (function (lambda () ())))))



(defun vendor-upi-payment-confirm (utrnum vendor company)
  :description "Update the UPI transaction with vendorconfirm and status fields set"
  (with-vend-session-check
    (let* ((requestmodel (make-instance 'UpiPaymentsRequestModel
					:vendor vendor
					:utrnum utrnum
					:paymentconfirm T
					:company company))
	   (upipaymentsadapter (make-instance 'UpiPaymentsAdapter)))
	
      ;; We are creating the UPI domain model object. It also saves the UPI payment transaction to DB.
	(ProcessUpdateRequest upipaymentsadapter requestmodel))))
    
(defun vendor-upi-payment-cancel (utrnum vendor company)
  :description "Update the UPI transaction with vendorconfirm and status fields set"
  (with-vend-session-check
    (let* ((requestmodel (make-instance 'UpiPaymentsRequestModel
					:vendor vendor
					:utrnum utrnum
					:paymentconfirm NIL
					:company company))
	   (upipaymentsadapter (make-instance 'UpiPaymentsAdapter)))
	
      ;; We are creating the UPI domain model object. It also saves the UPI payment transaction to DB.
	(ProcessUpdateRequest upipaymentsadapter requestmodel))))

(defun hhub-controller-vendor-upi-cancel ()
  (with-vend-session-check
    (let* ((utrnum (hunchentoot:parameter "utrnum"))
	   (vendor (get-login-vendor))
	   (company (get-login-vendor-company)))
      (vendor-upi-payment-cancel utrnum vendor company)
      (hhub-execute-pending-upi-task utrnum T)
      (hunchentoot:redirect "/hhub/hhubvendorupitransactions"))))


(defun hhub-controller-vendor-upi-confirm ()
  (with-vend-session-check
    (let* ((utrnum (hunchentoot:parameter "utrnum"))
	   (vendor (get-login-vendor))
	   (company (get-login-vendor-company)))
      (vendor-upi-payment-confirm utrnum vendor company)
      (hhub-execute-pending-upi-task utrnum)
      (hunchentoot:redirect "/hhub/hhubvendorupitransactions"))))

(defun create-model-for-showvendorupitransactions ()
  (let* ((vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (upipaymentspresenter (make-instance 'UpiPaymentsPresenter))
	 (upipaymentrequestmodel (make-instance 'UpiPaymentsRequestModel
						:vendor vendor
						:company company))
	 (upipaymentsadapter (make-instance 'UpiPaymentsAdapter))
	 (upipaymentobjlst (processreadallrequest upipaymentsadapter upipaymentrequestmodel))
	 (upipaymentsresponsemodellist (processresponselist upipaymentsadapter upipaymentobjlst))
	 (viewallmodel (CreateAllViewModel upipaymentspresenter upipaymentsresponsemodellist))
	 (htmlview (make-instance 'UPIPaymentsHTMLView)))
    (function (lambda ()
      (values viewallmodel htmlview)))))

(defun create-widgets-for-showvendorupitransactions (modelfunc)
	   ;; this is the view. 
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (:h4 "Showing records for last 60 Days"))
		       (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
      (list widget1))))


(defun hhub-controller-show-vendor-upi-transactions ()
  (with-vend-session-check
    (with-mvc-ui-page "Vendor UPI Transactions" #'create-model-for-showvendorupitransactions #'create-widgets-for-showvendorupitransactions :role :vendor)))
  
(defmethod RenderListViewHTML ((htmlview UPIPaymentsHTMLView) viewmodellist)
  (unless (= (length viewmodellist) 0)
    (display-as-table (list "Date" "Customer" "Phone" "Amount" "UTR Number" "Status" "Action") viewmodellist 'display-upi-transaction-row)))


(defun display-upi-transaction-row (upiviewmodel &rest arguments)
  (declare (ignore arguments))
  (let* ((vendor (slot-value upiviewmodel 'vendor))
	 (company (slot-value upiviewmodel 'company))
	 (order-id (subseq (slot-value upiviewmodel 'transaction-id) 5))
	 (vorder (if order-id (get-vendor-order-instance order-id vendor))))
	    
    (with-slots (amount vendor customer utrnum status vendorconfirm created phone) upiviewmodel
      (cl-who:with-html-output (*standard-output* nil)
	(:td  :height "10px" (cl-who:str (get-date-string created)))
	(:td  :height "10px" (cl-who:str (slot-value customer  'name)))
	(:td  :height "10px" (cl-who:str (if phone phone))
	(:td  :height "10px" (cl-who:str amount))
	(:td  :height "10px" (cl-who:str utrnum))
	(:td  :height "10px" (cl-who:str status))
	(:td :height "10px"
	     (with-modal-dialog-link
		 (format nil "hhubvendorderdetails~A-modal"  order-id)
	       (function (lambda () (cl-who:with-html-output (*standard-output* nil) (:span :class "label label-info" (format nil "~A" (cl-who:str order-id))))))
	       "Vendor Order Details" (function (lambda () (if vorder (modal.vendor-order-details vorder company)))))
	     (cond ((and (equal vendorconfirm "N") (equal status "CAN"))
	       (cl-who:htm
		(:td :height "10px" (:i :class "fa fa-inr" :aria-hidden "true") "Payment Not Received")))
	      ((equal vendorconfirm "N") 
	       (cl-who:htm
		(:td  :height "10px"
		      (with-modal-dialog-link (format nil "vendorupipaymentconfirm~A" utrnum)
			(function (lambda () (cl-who:with-html-output (*standard-output* nil) (:i :class "fa fa-inr" :aria-hidden "true"))))
			"Confirm UPI Payment"
			(function (lambda () (modal.vendor-upi-payment-confirm upiviewmodel))))))) 
	      ((and (equal vendorconfirm "Y") (equal status "CNF"))
	       (cl-who:htm
		(:td :height "10px" (:i :class "fa fa-inr" :aria-hidden "true") " Received"))))))))))

(defun modal.vendor-upi-payment-confirm (upiviewmodel)
  (with-slots (utrnum status) upiviewmodel
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-div-row 
	(with-html-div-col-10
	  (:h3 (cl-who:str (format nil "UTR Number - ~A." utrnum)))
	  (:form :id (format nil "form-vendorupiconfirm") :data-toggle "validator"  :role "form" :method "POST" :action "hhubvendupipayconfirm" :enctype "multipart/form-data"
		 (:div :class "form-group" :style "display: none"
		       (:input :class "form-control":name "utrnum" :value utrnum :placeholder "UTR Number" :type "text" :readonly T ))
		 (:div :class "form-group"
		       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Payment Received")))))
	(with-html-div-row
	  (with-html-div-col-10
	    (:form :id (format nil "form-vendorupiconfirm") :data-toggle "validator"  :role "form" :method "POST" :action "hhubvendupipaycancel" :enctype "multipart/form-data"
		   (:div :class "form-group" :style "display: none"
			 (:input :class "form-control" :name "utrnum" :value utrnum :placeholder "UTR Number" :type "numeric"   :readonly T ))
		   (:div :class "form-group"
			 (:button :class "btn btn-lg btn-danger btn-block" :type "submit" "Payment Not Received"))))))))


