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


(defun display-upi-widget (amount qrcodepath upiappurls)
  (let ((upiappnames (list "Phone Pe" "Pay TM" "Google Pay" "UPI")))   
    (cl-who:with-html-output (*standard-output* nil)
      (:hr)
      (:h5 (cl-who:str (format nil "Complete Your Payment")))
      (:h4 (cl-who:str (format nil "Amount = &#8377 ~d" amount)))
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
		  (:img :style "width: 200px; height: 200px;" :src (cl-who:str (format nil "/img~A" qrcodepath)))))))
      (:hr)
      (:h5 "NOTE: Please scan the UPI QR code or click on any of the UPI payment app links given above. After making payment, you will not be redirected back to this app. After UPI payment, enter the 12 digit UTR number and click Submit to place the order.")
      (:script "window.onload = function() {countdowntimer(0,0,5,0);}"))))

				

(defun hhub-controller-upi-customer-order-payment-page ()
  (with-cust-session-check
    (let* ((odts (hunchentoot:session-value :login-shopping-cart))
	   (shopcart-total (get-shop-cart-total odts))
	   (order-cxt (format nil "#ORDER:UPI~A" (get-universal-time)))
	   (vendor-list (get-shopcart-vendorlist odts))
	   (vendor (first vendor-list))
	   (upiurls (generateupiurlsforvendor vendor "ABC" order-cxt shopcart-total))
	   (qrcodepath (generateqrcodeforvendor vendor "ABC" order-cxt shopcart-total)))

      ;; If Vendor UPI ID is not defined, then redirect to the UPI ID not found page. 
      (unless (slot-value vendor 'upi-id) (hunchentoot:redirect "/hhub/vendorupinotfound"))
      (with-standard-customer-page-v2 "HighriseHub - UPI Payment Page"
	(with-customer-breadcrumb
	  (:li :class "breadcrumb-item" (:a :href "dodcustshopcart" "Cart"))
	  (:li :class "breadcrumb-item" (:a :href "dodcustorderaddpage" "Address")))
	
	(with-html-div-row-fluid :style "box-shadow: rgba(17, 17, 26, 0.1) 0px 0px 16px;"
	  (display-upi-widget shopcart-total qrcodepath upiurls)
	  (with-html-form "customerupipaymentform" "dodcustshopcartro" 
	    (:div :class "row mb-3"
		  (:div :class "col-sm-4" :style "text-align: center;"
			(:label :for "utrnum" "UTR No")
			(:input :class "form-control" :name "paymentmode" :value "UPI" :type "hidden")
			(:input :class "form-control" :name "amount" :value shopcart-total :type "hidden")
			(:input :class "form-control" :name "utrnum" :value "" :placeholder "12 Digit UTR Number" :type "number" :onkeyup "countChar(this, 12)" :max "999999999999" :maxlength "12"  :required T)))
	    (:div :id "charcount" :class "form-group")
	    (:div :class "row mb-3"
		  (:div :class "col-sm-4" :style "text-align: center;"
			(:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))))))
  
  
(defun hhub-controller-upi-recharge-wallet-page ()
  (with-cust-session-check
    (let* ((wallet-id (hunchentoot:parameter "wallet-id"))
	   (amount (hunchentoot:parameter "amount"))
	   (custcomp (get-login-customer-company))
	   (wallet (get-cust-wallet-by-id wallet-id custcomp))
	   (vendor (get-vendor wallet))
	   (transaction-id (format nil "#WAL:~A" (get-universal-time)))
	   (upiurls (generateupiurlsforvendor vendor "ABC" transaction-id amount))
	   (qrcodepath (generateqrcodeforvendor vendor "ABC" transaction-id amount)))
	 	   
      (with-standard-customer-page-v2 "HighriseHub - UPI Payment Page"
	(if qrcodepath 
	    (with-html-div-row-fluid :style "box-shadow: rgba(17, 17, 26, 0.1) 0px 0px 16px;"
	      (display-upi-widget amount qrcodepath upiurls)
	      (with-html-form "customerupipaymentform" "hhubcustwalletrechargeaction"
		(:div :class "row mb-3"
		      (:div :class "col-sm-4" :style "text-align: center;"
			    (:input :class "form-control" :name "wallet-id" :value wallet-id :type "hidden")
			    (:input :class "form-control" :name "amount" :value amount :type "hidden")
			    (:input :class "form-control" :name "transaction-id" :value transaction-id :type "hidden")
			    (:label :for "utrnum" "UTR No")
			    (:input :class "form-control" :name "utrnum" :value "" :placeholder "12 Digit UTR Number" :type "number" :max "999999999999" :maxlength "12"  :required T)))
		(:div :class "row mb-3"
		      (:div :class "col-sm-4" :style "text-align: center;"
			    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))
	    ;;else
	    (with-html-div-row-fluid :style "box-shadow: rgba(17, 17, 26, 0.1) 0px 0px 16px;"
	      (:h2 (cl-who:str "UPI Details for Vendor Missing"))))))))
  
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


(defun hhub-controller-show-vendor-upi-transactions ()
  (with-vend-session-check
    (let* ((vend (get-login-vendor))
	   (company (get-login-vendor-company))
	   (upipaymentspresenter (make-instance 'UpiPaymentsPresenter))
	   (upipaymentrequestmodel (make-instance 'UpiPaymentsRequestModel
						  :vendor vend
						  :company company))
	   (upipaymentsadapter (make-instance 'UpiPaymentsAdapter))
	   (upipaymentobjlst (processreadallrequest upipaymentsadapter upipaymentrequestmodel))
	   (upipaymentsresponsemodellist (processresponselist upipaymentsadapter upipaymentobjlst))
	   (viewallmodel (CreateAllViewModel upipaymentspresenter upipaymentsresponsemodellist))
	   (htmlview (make-instance 'UPIPaymentsHTMLView)))
      (with-standard-vendor-page "Vendor UPI Transactions"
	(with-html-div-row
	  (:h4 "Showing records for last 60 Days"))
	  (cl-who:str (RenderListViewHTML htmlview viewallmodel))))))

(defmethod RenderListViewHTML ((htmlview UPIPaymentsHTMLView) viewmodellist)
  (unless (= (length viewmodellist) 0)
    (display-as-table (list "Date" "Customer" "Phone" "Amount" "UTR Number" "Status" "Action") viewmodellist 'display-upi-transaction-row)))


(defun display-upi-transaction-row (upiviewmodel)
  (let* ((vendor (slot-value upiviewmodel 'vendor))
	 (company (slot-value upiviewmodel 'company))
	 (order-id (subseq (slot-value upiviewmodel 'transaction-id) 5))
	 (vorder (if order-id (get-vendor-order-instance order-id vendor))))
	    
    (with-slots (amount vendor customer utrnum status vendorconfirm created phone) upiviewmodel
      (cl-who:with-html-output (*standard-output* nil)
	(:td  :height "10px" (cl-who:str (get-date-string created)))
	(:td  :height "10px" (cl-who:str (slot-value customer  'name)))
	(:td  :height "10px" (cl-who:str (if phone phone)))
	(:td  :height "10px" (cl-who:str amount))
	(:td  :height "10px" (cl-who:str utrnum))
	(:td  :height "10px" (cl-who:str status))
	(:td :height "10px"
	     (:a :data-toggle "modal" :data-target (format nil "#hhubvendorderdetails~A-modal"  order-id)  :href "#"  (:span :class "label label-info" (format nil "~A" (cl-who:str order-id))))
	     (modal-dialog (format nil "hhubvendorderdetails~A-modal" order-id) "Vendor Order Details" (if vorder (modal.vendor-order-details vorder company))))
    	(cond ((and (equal vendorconfirm "N") (equal status "CAN"))
	       (cl-who:htm
		(:td :height "10px" (:i :class "fa fa-inr" :aria-hidden "true") "Payment Not Received")))
	      ((equal vendorconfirm "N") 
	       (cl-who:htm
		(:td  :height "10px" 
		      (:a :data-toggle "modal" :data-target (format nil "#vendorupipaymentconfirm~A" utrnum)  :href "#"  (:i :class "fa fa-inr" :aria-hidden "true"))
		      (modal-dialog (format nil "vendorupipaymentconfirm~A" utrnum) "Confirm UPI Payment" (modal.vendor-upi-payment-confirm upiviewmodel)))))
	      ((and (equal vendorconfirm "Y") (equal status "CNF"))
	       (cl-who:htm
		(:td :height "10px" (:i :class "fa fa-inr" :aria-hidden "true") " Received"))))))))


(defun modal.vendor-upi-payment-confirm (upiviewmodel)
  (with-slots (utrnum status) upiviewmodel
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-div-row 
	(:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
	      (:h3 (cl-who:str (format nil "UTR Number - ~A." utrnum)))
	      (:form :id (format nil "form-vendorupiconfirm") :data-toggle "validator"  :role "form" :method "POST" :action "hhubvendupipayconfirm" :enctype "multipart/form-data"
		     (:div :class "form-group" :style "display: none"
			    (:input :class "form-control" :name "utrnum" :value utrnum :placeholder "UTR Number" :type "text" :readonly T ))
		     (:div :class "form-group"
			   (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Payment Received")))))
	(with-html-div-row
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(:form :id (format nil "form-vendorupiconfirm") :data-toggle "validator"  :role "form" :method "POST" :action "hhubvendupipaycancel" :enctype "multipart/form-data"
		       (:div :class "form-group" :style "display: none"
			     (:input :class "form-control" :name "utrnum" :value utrnum :placeholder "UTR Number" :type "numeric"   :readonly T ))
		       (:div :class "form-group"
			     (:button :class "btn btn-lg btn-danger btn-block" :type "submit" "Payment Not Received"))))))))


