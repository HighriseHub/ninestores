;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defun generateqrcodeforvendor  (vendor retailer-category-code transaction-id amount)
  ;; upiapp values are phonepe, paytmmp, gpay, upi
  (let* ((upi-id (slot-value vendor 'upi-id))
	 (vendor-name (slot-value vendor 'name))
	 (paymentstr (format nil "\'upi://pay?pa=~A&pn=~A&am=~d&tr=~A&cu=INR&mc=~A\'" upi-id vendor-name amount transaction-id retailer-category-code))
	 (filename (format nil "/temp/upiqr~A.png" (get-universal-time)))
	 (filepath (format nil "~A/~A" *HHUBRESOURCESDIR* filename))
	 (qrcodecmd (format nil "qrencode -s 5 -l L -v 5 -o ~A ~A" filepath paymentstr)))
	 
    (sb-ext:run-program "/bin/sh" (list "-c" qrcodecmd ) :input nil :output *standard-output*)
    filename))

(defun generateupiurlsforvendor  (vendor retailer-category-code transaction-id amount)
  :description "Generates the UPI payment URLs for a vendor and returns an url list containing one url per app. upiapp values are phonepe, paytmmp, gpay, upi"
  (let* ((paymentapps (list "phonepe" "paytmmp" "gpay" "upi"))
	 (upi-id (slot-value vendor 'upi-id))
	 (vendor-name (slot-value vendor 'name)))
    (when upi-id 
      (mapcar (lambda (upiapp)
		(let ((paymenturl (format nil "~A://pay?pa=~A&pn=~A&am=~d&tr=~A&cu=INR&mc=~A" upiapp upi-id vendor-name amount transaction-id retailer-category-code)))
		  paymenturl)) paymentapps))))
				     

(defun hhub-controller-upipayment-page ()
  (with-cust-session-check
    (let* ((odts (hunchentoot:session-value :login-shopping-cart))
	   (customer (get-login-customer))
	   (cust-name (slot-value customer 'name))
	   (shopcart-total (get-shop-cart-total odts))
	   (custcomp (get-login-customer-company))
	   (cust-type (cust-type customer))
	   (order-cxt (format nil "#HHUBUPI~A" (get-universal-time)))
	   (company-type (slot-value custcomp 'cmp-type))
	   (vendor-list (get-shopcart-vendorlist odts))
	   (vendor (first vendor-list))
	   (upiurls (generateupiurlsforvendor vendor "ABC" order-cxt shopcart-total))
	   (qrcodepath (generateqrcodeforvendor vendor "ABC" order-cxt shopcart-total))
	   (wallet-id (slot-value (get-cust-wallet-by-vendor customer (first vendor-list) custcomp) 'row-id)))
	
    (with-standard-customer-page-v2 "HighriseHub - UPI Payment Page" 
      (:h3 "Complete Your Payment ")
      (:h4 (cl-who:str (format nil "Amount = &#8377 ~d" shopcart-total)))
      (:hr)
      (:div :id "withCountDownTimerExpired" 
	    (with-html-div-row
	      (with-html-div-col
		"This session will expire in" (:p :id "withCountDownTimer")))
	    
	    (when (> (length upiurls) 0)
	      (mapcar (lambda (url appname)
			(cl-who:htm
			 (with-html-div-row
			   (with-html-div-col 
			     (:a :href url (cl-who:str appname)))))) upiurls (list "Phone Pe" "Pay TM" "Google Pay" "UPI"))   
	      (with-html-div-row
		(with-html-div-col
		  (:img :style "width: 200px; height: 200px;" :src (cl-who:str (format nil "/img~A" qrcodepath)))))
	      
	      (with-html-form "utrcodeform" "hhubupipaymentdone"

		(:div :class "row mb-3"
		      (:div :class "col-sm-4"
			    (:label :for "utrnum" "UTR No")
			    (:input :class "form-control" :name "utrnum" :value "" :placeholder "12 Digit UTR Number" :type "number" :max "999999999999" :maxlength "12"  :required T)))
		(:div :class "mb-3"
		      (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))
	    (:script "window.onload = function() {countdowntimer(0,0,5,0);}")))))
  
  
