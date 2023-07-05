;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


(defun save-temp-guest-customer (name address city state zip phone email)
  (let ((temp-customer (make-instance 'DOD-CUST-PROFILE
				      :row-id (get-login-customer-id))))
    (setf (slot-value temp-customer 'name) name)
    (setf (slot-value temp-customer 'address) address)
    (setf (slot-value temp-customer 'city) city)
    (setf (slot-value temp-customer 'state) state)
    (setf (slot-value temp-customer 'zipcode) zip)
    (setf (slot-value temp-customer 'phone) phone)
    (setf (slot-value temp-customer 'email) email)
    (setf (hunchentoot:session-value :temp-guest-customer) temp-customer)))
    
(defun dod-controller-customer-payment-methods-page ()
  (with-cust-session-check
    (let* ((lstshopcart (hunchentoot:session-value :login-shopping-cart))
	   (lstcount (length lstshopcart))
	   (cust-type (get-login-customer-type))
	   (vendor-list (get-shopcart-vendorlist lstshopcart))
	   (singlevendor-p (if (= (length vendor-list) 1) T NIL))
	   (singlevendor (first vendor-list))
	   (vpayapikey-p (if singlevendor-p (when (slot-value singlevendor 'payment-api-key) t)))
	   (vupiid-p (if singlevendor-p (when (slot-value singlevendor 'upi-id) t)))
	   (odts (hunchentoot:session-value :login-shopping-cart))
	   (products (hunchentoot:session-value :login-prd-cache))
	   (odate  (get-date-from-string (hunchentoot:parameter "orddate")))
	   (custname (hunchentoot:parameter "custname"))
	   (shipaddress (hunchentoot:parameter "shipaddress"))
	   (shipzipcode (hunchentoot:parameter "shipzipcode"))
	   (shipcity (hunchentoot:parameter "shipcity"))
	   (shipstate (hunchentoot:parameter "shipstate"))
	   (billaddress (hunchentoot:parameter "billaddress"))
	   (billzipcode (hunchentoot:parameter "billzipcode"))
	   (billcity (hunchentoot:parameter "billcity"))
	   (billstate (hunchentoot:parameter "billstate"))
	   (billsameasshipchecked (hunchentoot:parameter "billsameasshipchecked"))
	   (claimitcchecked (hunchentoot:parameter "claimitcchecked"))
	   (gstnumber (hunchentoot:parameter "gstnumber"))
	   (gstorgname (hunchentoot:parameter "gstorgname"))
	   (reqdate (get-date-from-string (hunchentoot:parameter "reqdate")))
	   (phone  (hunchentoot:parameter "phone"))
	   (email (hunchentoot:parameter "email"))
	   (comments (if phone (format nil "~A, ~A, ~A, ~A, ~A, ~A" phone email shipaddress shipcity shipstate shipzipcode)))
	   (shopcart-total (get-shop-cart-total odts))
	   (customer (get-login-customer))
	   (custcomp (get-login-customer-company))
	   ;;(wallet-balance (slot-value (get-cust-wallet-by-vendor customer (first vendor-list) custcomp) 'balance))
	   (order-cxt (format nil "hhubcustopy~A" (get-universal-time)))
	   (shopcart-products (mapcar (lambda (odt)
					(let ((prd-id (slot-value odt 'prd-id)))
					  (search-prd-in-list prd-id products ))) odts)))
					; (wallet-id (slot-value (get-cust-wallet-by-vendor customer (first vendor-list) custcomp) 'row-id)))
					; Save the email address to send a mail in future if this is a guest customer.
      (setf (hunchentoot:session-value :guest-email-address) email)
      					; Save the customer order parameters. 
      (save-cust-order-params (list odts shopcart-products odate reqdate nil  shipaddress shipzipcode shipcity shipstate billaddress billzipcode billcity billstate billsameasshipchecked claimitcchecked gstnumber gstorgname shopcart-total comments customer custcomp order-cxt phone email custname))
      ;; Save the Guest customer details so that we can use them within the session if required. 
      (when (equal cust-type "GUEST")
	(save-temp-guest-customer custname shipaddress shipcity shipstate shipzipcode phone email))

      (with-standard-customer-page-v2 "Payment Methods Page"
	(with-html-div-row
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(:h5 :class "text-center"  "Choose Payment Method")
		(:a :class "btn btn-primary"  :role "button" :href "/hhub/dodcustindex"  (:i :class "fa-solid fa-house"))))

	(:hr)
	(when (> lstcount 0)
	  (cond ((equal cust-type "STANDARD") (standardcustpaymentmethods vendor-list customer custcomp))
		((equal cust-type "GUEST") (guestcustpaymentmethods singlevendor-p vpayapikey-p vupiid-p phone))))))))
  


(defun standardcustpaymentmethods (vendorlist customer company)
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-div-row
      (:h5 (:u "Prepaid Wallet Balance")))
    (mapcar (lambda (vendor)
	      (let* ((wallet (get-cust-wallet-by-vendor customer vendor company))
		     (wallet-balance (slot-value wallet 'balance))
		     (vendorname (slot-value vendor 'name)))
		(cl-who:htm
		 (with-html-div-row
		   (with-html-div-col
		     (:h6 (cl-who:str (format nil "Vendor - ~A" vendorname))))
		   (with-html-div-col
		     (:span  :style "color:blue" (cl-who:str (format nil "~d" wallet-balance)))))))) vendorlist)
    (:hr)
    (:a :class "btn btn-primary" :role "button" :href (format nil "dodcustshopcartotpstep?context=dodcustshopcartro&paymentmode=PRE") "Checkout")))
	
  
(defun guestcustpaymentmethods (singlevendor-p vpayapi-p vupiid-p phone)
  (cl-who:with-html-output (*standard-output* nil)
    (cond  
      ((and singlevendor-p vpayapi-p)
       (cl-who:htm
	(:div :class "list-group col-sm-6 col-md-6 col-lg-6 col-xs-12"
	      (:a :class "btn btn-primary" :role "button" :href (format nil "dodcustshopcartotpstep?context=dodcustshopcartro&paymentmode=OPY&phone=~A" phone) "Online Payment")
	      (:a :class "list-group-item" :href (format nil "dodcustshopcartotpstep?context=dodcustshopcartro&paymentmode=COD&phone=~A" phone) "Cash On Delivery")
	      (:a :class "list-group-item" :href (format nil "hhubcustupipage?paymentmode=UPI") "UPI Payment"))))
      ;;else
      ;; if it is single vendor and vendor has UPI ID defined
      ((and singlevendor-p vupiid-p)
       (cl-who:htm
	(:div :class "list-group col-sm-6 col-md-6 col-lg-6 col-xs-12"
	      (:a :class "list-group-item" :href (format nil "dodcustshopcartotpstep?context=dodcustshopcartro&paymentmode=cod&phone=~A" phone) "Cash On Delivery")
	      (:a :class "list-group-item" :href (format nil "hhubcustupipage?paymentmode=UPI") "UPI Payment"))))
      ;; if nothing matches.
      (t
       (cl-who:htm
	(:div :class "list-group col-sm-6 col-md-6 col-lg-6 col-xs-12"
	      (:a :class "list-group-item" :href (format nil "dodcustshopcartotpstep?context=dodcustshopcartro&paymentmode=cod&phone=~A" phone) "Cash On Delivery")))))))
  
		      
(defun dod-controller-vendor-upi-notfound ()
  (with-cust-session-check
    (with-standard-customer-page "Vendor UPI ID Not Found"
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:h1 :class "text-center"  "Vendor UPI ID Not Found.") 
		  (:a :class "btn btn-primary"  :role "button" :href "/hhub/dodcustindex"  (:i :class "fa-solid fa-house")))))))



(defun hhub-controller-get-shipping-rate ()
  (let* ((pincode (hunchentoot:parameter "pincode"))
	   (params nil)
	   (addressadapter (make-instance 'Address-Adapter))
	   (presenter (make-instance 'Address-Presenter))
	   (jsonview (make-instance 'JSONView)))
      
      (setf params (acons "pincode" pincode params))
      (render jsonview (createviewmodel presenter (processrequest addressadapter params)))))


(defun hhub-controller-pincode-check ()
  (let* ((pincode (hunchentoot:parameter "pincode"))
	   (params nil)
	   (addressadapter (make-instance 'Address-Adapter))
	   (presenter (make-instance 'Address-Presenter))
	   (jsonview (make-instance 'JSONView)))
      
      (setf params (acons "pincode" pincode params))
      (render jsonview (createviewmodel presenter (processrequest addressadapter params)))))
  
  
(defmethod Render ((view JSONView) (viewmodel AddressViewModel))
  (let* ((templist '())
	 (appendlist '())
	 (mylist '())
	 (locality (slot-value viewmodel 'locality))
	 (city (slot-value viewmodel 'city))
	 (state (slot-value viewmodel 'state)))

    (if (and 
	     (not (null locality))
	     (not (null city))
	     (not (null state)))
      (progn
	(setf templist (acons "locality" (format nil "~A" locality) templist))
	(setf templist (acons "city" (format nil "~A" city) templist))
	(setf templist (acons "state" (format nil "~A" state) templist))
	(setf appendlist (append appendlist (list templist)))
	(setf mylist (acons "result" appendlist mylist))
	(setf mylist (acons "success" 1 mylist))
	(let ((jsondata (json:encode-json-to-string mylist)))
	  (setf (slot-value view 'jsondata) jsondata)
	  ;; return jsondata
	  jsondata))
					;else 
      (progn
	(setf mylist (acons "success" 0 mylist))
 	(let ((jsondata (json:encode-json-to-string mylist)))
	  (setf (slot-value view 'jsondata) jsondata)
	  jsondata)))))



(defun modal.customer-update-details (customer)
  (let* ((name (name customer))
	 (address (address customer))
	 (phone  (phone customer))
	 (email (email customer)))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :id (format nil "form-customerupdate")  :role "form" :method "POST" :action "hhubcustupdateaction" :enctype "multipart/form-data" 
					;(:div :class "account-wall"
			 
		 (:h1 :class "text-center login-title"  "Update Customer Details")
		 (:div :class "form-group"
		       (:input :class "form-control" :name "name" :value name :placeholder "Customer Name" :type "text"))
		 (:div :class "form-group"
		       (:label :for "address")
		       (:textarea :class "form-control" :name "address"  :placeholder "Enter Address ( max 400 characters) "  :rows "5" :onkeyup "countChar(this, 400)" (cl-who:str (format nil "~A" address))))
		 (:div :class "form-group" :id "charcount")
		 (:div :class "form-group"
		       (:input :class "form-control" :name "phone"  :value phone :placeholder "Phone"  :type "text" ))
		 
		 (:div :class "form-group"
		       (:input :class "form-control" :name "email" :value email :placeholder "Email" :type "text"))
		 
		 (:div :class "form-group"
		       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))

(defun dod-controller-customer-update-action ()
  (with-cust-session-check 
    (let* ((customer (get-login-customer))
	   (name (hunchentoot:parameter "name"))
	   (address (hunchentoot:parameter "address"))
	   (phone (hunchentoot:parameter "phone"))
	   (email (hunchentoot:parameter "email")))
      (setf (slot-value customer 'name) name)
      (setf (slot-value customer 'address) address)
      (setf (slot-value customer 'phone) phone)
      (setf (slot-value customer 'email) email)
      (update-customer customer)
      (hunchentoot:redirect "/hhub/dodcustprofile"))))

      
(defun modal.customer-change-pin ()
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form "form-customerchangepin" "hhubcustomerchangepin"  
					;(:div :class "account-wall"
			 (:h1 :class "text-center login-title"  "Change Password")
			 (:div :class "form-group"
			       (:label :for "password" "Password")
			       (:input :class "form-control" :name "password" :value "" :placeholder "Old Password" :type "password" :required T))
			 (:div :class "form-group"
			       (:label :for "newpassword" "New Password")
			       (:input :class "form-control" :id "newpassword" :data-minlength "8" :name "newpassword" :value "" :placeholder "New Password" :type "password" :required T))
			 (:div :class "form-group"
			       (:label :for "confirmpassword" "Confirm New Password")
			       (:input :class "form-control" :name "confirmpassword" :value "" :data-minlength "8" :placeholder "Confirm New Password" :type "password" :required T :data-match "#newpassword"  :data-match-error "Passwords dont match"  ))
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))))



(defun dod-controller-customer-change-pin ()
  (with-cust-session-check 
    (let* ((customer (get-login-customer))
	   (password (hunchentoot:parameter "password"))
	   (newpassword (hunchentoot:parameter "newpassword"))
	   (confirmpassword (hunchentoot:parameter "confirmpassword"))
	   (salt-octet (secure-random:bytes 56 secure-random:*generator*))
	   (salt (flexi-streams:octets-to-string  salt-octet))
	   (encryptedpass (check&encrypt newpassword confirmpassword salt))
	   (present-salt (if customer (slot-value customer 'salt)))
	   (present-pwd (if customer (slot-value customer 'password)))
	   (password-verified (if customer  (check-password password present-salt present-pwd))))
     (cond 
       ((or
	 (not password-verified) 
	 (null encryptedpass)) (dod-response-passwords-do-not-match-error)) 
       ((and password-verified encryptedpass) (progn 
       (setf (slot-value customer 'password) encryptedpass)
       (setf (slot-value customer 'salt) salt) 
       (update-customer customer)
       (hunchentoot:redirect "/hhub/dodcustprofile")))))))

(defun dod-controller-customer-profile ()
  (with-cust-session-check
    (with-standard-customer-page "HighriseHub - Customer Profile"
      (cl-who:with-html-output (*standard-output* nil :prologue t :indent t)
	(:h3 "Welcome " (cl-who:str (format nil "~a" (get-login-cust-name))))
	(:hr)
	(:div :class "list-group col-sm-6 col-md-6 col-lg-6 col-xs-12"
	      (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodcustupdate-modal")  :href "#"  "Contact Info")
	      (modal-dialog (format nil "dodcustupdate-modal") "Update Customer" (modal.customer-update-details (get-login-customer))) 
	      (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodcustchangepin-modal")  :href "#"  "Change Password")
	      (modal-dialog (format nil "dodcustchangepin-modal") "Change Password" (modal.customer-change-pin)) 
	      (:a :class "list-group-item" :href "#" "Settings")
	      (:a :class "list-group-item" :href "https://goo.gl/forms/hI9LIM9ebPSFwOrm1" "Feature Wishlist")
	      (:a :class "list-group-item" :href "https://goo.gl/forms/3iWb2BczvODhQiWW2" "Report Issues"))))))

(defun get-login-customer ()
    :documentation "get the login session for customer"
    (hunchentoot:session-value :login-customer ))

(defun get-login-customer-id ()
  :documentation "get login customer id"
  (hunchentoot:session-value :login-customer-id))


(defun get-login-cust-company ()
    :documentation "get the login customer company."
    ( hunchentoot:session-value :login-customer-company))

(defun is-dod-cust-session-valid? ()
    :documentation "checks whether the current login session is valid or not."
	 (if hunchentoot:*session* T))
					;(if (null (get-login-cust-name)) nil t))

;    (handler-case 
	;expression
;	(if (not (null (get-login-cust-name)))
;	       (if (equal (caar (clsql:query "select 1" :flatp nil :field-names nil :database *dod-db-instance*)) 1) t))	      
        ; handle this condition
   
 ;     (clsql:sql-database-data-error (condition)
;	  (if (equal (clsql:sql-error-error-id condition) 2006 ) (clsql:reconnect :database *dod-db-instance*)))
;      (clsql:sql-fatal-error (errorinst) (if (equal (clsql:sql-error-database-message errorinst) "database is closed.") 
;					     (progn (clsql:stop-sql-recording :type :both)
;					            (clsql:disconnect) 
;						    (crm-db-connect :servername *crm-database-server* :strdb *crm-database-name* :strusr *crm-database-user*  :strpwd *crm-database-password* :strdbtype :mysql))))))
      

(defun get-login-cust-name ()
    :documentation "gets the name of the currently logged in customer"
    (hunchentoot:session-value :login-customer-name))

(defun dod-controller-customer-logout ()
    :documentation "customer logout."
    (let ((company-website (get-login-customer-company-website)))
      (progn 
	(hunchentoot:remove-session hunchentoot:*session*)
	(if (> (length company-website) 0) (hunchentoot:redirect (format nil "http://~A" company-website)) 
	    ;else
	    (hunchentoot:redirect *siteurl*)))))

(defun dod-controller-guest-customer-logout ()
  (unless (hunchentoot:remove-session hunchentoot:*session*)
    (hunchentoot:redirect "/hhub/customer-login.html")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; das-cust-page-with-tiles;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun das-cust-page-with-tiles (displayfunc pagetitle &rest args)
  :documentation "this is a standard higher order function which takes the display function as argument and displays the information"
  (with-cust-session-check
    (with-standard-customer-page (:title pagetitle) 
      (apply displayfunc args))))





(defun dod-controller-cust-wallet-display ()
:documentation "a callback function which displays the wallets for a customer" 
  (let* ((company (hunchentoot:session-value :login-customer-company))
	 (customer (hunchentoot:session-value :login-customer))
	 (header (list "Vendor" "Phone" "Balance" "Recharge"))
	 (wallets (get-cust-wallets customer company)))
    (with-cust-session-check
      (with-standard-customer-page-v2 "HighriseHub - Customer Wallets"
	(cl-who:str (display-as-table header wallets 'cust-wallet-as-row))))))
					;     (cl-who:str (display-as-tiles wallets 'wallet-card))))))


(defun wallet-card (wallet-instance custom-message)
  (let ((customer (get-customer wallet-instance))
	(balance (slot-value wallet-instance 'balance)) 
	  (lowbalancep (if (check-low-wallet-balance wallet-instance) t nil)))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "wallet-box"
	    (:div :class "row"
		  (:div :class "col-sm-6"  (:h3  (cl-who:str (format nil "customer: ~a " (slot-value customer 'name)))))
		  (:div :class "col-sm-6"  (:h3  (cl-who:str (format nil "ph:  ~a " (slot-value customer 'phone))))))
	    (:div :class "row"
		  (if lowbalancep 
		      (cl-who:htm (:div :class "col-sm-6 " (:h4 (:span :class "label label-warning" (cl-who:str (format nil "rs ~$ - low balance. please recharge the  wallet."  balance))))))
					;else
		      (cl-who:htm (:div :class "col-sm-3"  (:h4 (:span :class "label label-info" (cl-who:str (format nil "balance: rs. ~$"  balance))))))))
	    (:div :class "row"
		  (:form :class "cust-wallet-recharge-form" :method "post" :action "dodsearchcustwalletaction"
			 (:input :class "form-control" :name "phone" :type "hidden" :value (cl-who:str (format nil "~a" (slot-value customer 'phone))))
			 (:div :class "col-sm-3" (:div :class "form-group"
						       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "recharge")))))
	    (:div :class "row"
		  (:div :class "col-sm-6"  (:h3  (cl-who:str (format nil " ~a " custom-message)))))))))




(defun cust-wallet-as-row (wallet)
  (let* ((vendor (slot-value wallet 'vendor))
	 (balance (slot-value wallet 'balance))
	 (wallet-id (slot-value wallet 'row-id))
	 (lowbalancep (if (check-low-wallet-balance wallet) t nil)))
    (cl-who:with-html-output (*standard-output* nil)
 	  (:td  :height "10px" (cl-who:str (slot-value vendor  'name)))
	  (:td  :height "10px" (cl-who:str (slot-value vendor  'phone)))
	  
	  (if lowbalancep
	      (cl-who:htm (:td :height "10px" (:h4 (:span :class "label label-danger" (cl-who:str (format nil "Rs. ~$ " balance))))))
					;else
	      (cl-who:htm (:td :height "10px" (cl-who:str (format nil "Rs. ~$ " balance)))))
      (:td :height "10px" 
	   (:a  :class "btn btn-primary" :role "button"  :href (format nil "/hhub/hhubcustwalletrechargepage?amount=1000.00&wallet-id=~A" wallet-id)  "1000"))
					; Recharge 1500 
      (:td :height "10px"
	   (:a  :class "btn btn-primary" :role "button"  :href (format nil "/hhub/hhubcustwalletrechargepage?amount=2000.00&wallet-id=~A" wallet-id) "2000")))))


(defun list-customer-low-wallet-balance (wallets order-items-totals)
  (let ((header (list "Vendor" "Phone" "Balance" "Order Items Total"  "Recharge")))
    (cl-who:with-html-output (*standard-output* nil)
      (:h3 "My Wallets.")      
      (:table :class "table table-striped"  (:thead (:tr
						     (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) header))) 
	      (:tbody
	       (mapcar (lambda (wallet order-item-total)
			 (let* ((vendor (slot-value wallet 'vendor))
				(balance (slot-value wallet 'balance))
				(wallet-id (slot-value wallet 'row-id))
				(pg-mode (slot-value vendor 'payment-gateway-mode))
				(lowbalancep (or (if (check-low-wallet-balance wallet) t nil)
						 (< balance order-item-total))))
			   (cl-who:htm (:tr
					(:td  :height "12px" (cl-who:str (slot-value vendor  'name)))
					(:td  :height "12px" (cl-who:str (slot-value vendor  'phone)))
					
					(if lowbalancep
					    (cl-who:htm (:td :height "12px" (:h4 (:span :class "label label-danger" (cl-who:str (format nil "Rs. ~$ " balance))))))
					;else
					    (cl-who:htm (:td :height "12px" (cl-who:str (format nil "Rs. ~$ " balance)))))
					
					(:td :height "12px" (cl-who:str (format nil "Rs. ~$ " order-item-total)))
					
					(:td :height "12px" 
					     (:a  :class "btn btn-primary" :role "button"  :href (format nil "/hhub/dasmakepaymentrequest?amount=500&wallet-id=~A&order_id=hhub~A&mode=~A" wallet-id (get-universal-time) pg-mode )  "500")
					; Recharge 1500 
					     
					     (:a  :class "btn btn-primary" :role "button"  :href (format nil "/hhub/dasmakepaymentrequest?amount=1000&wallet-id=~A&order_id=hhub~A&mode=~A" wallet-id (get-universal-time) pg-mode )  "1000")
					     (:a  :class "btn btn-primary" :role "button"  :href (format nil "/hhub/dasmakepaymentrequest?amount=1500&wallet-id=~A&order_id=hhub~A&mode=~A" wallet-id (get-universal-time) pg-mode )  "1500")))))) wallets order-items-totals))))))






(defun dod-controller-del-opref ()
    :documentation "delete order preference"
    (with-cust-session-check
	(let ((ordpref-id (parse-integer (hunchentoot:parameter "id")))
		     (cust (hunchentoot:session-value :login-customer))
		 (company (hunchentoot:session-value :login-customer-company)))
	    (delete-opref (get-opref-by-id ordpref-id company))
	    (setf (hunchentoot:session-value :login-cusopf-cache) (get-opreflist-for-customer cust))
	(hunchentoot:redirect "/hhub/dodcustorderprefs"))
					;else
	))




(defun dod-controller-my-orders ()
    :documentation "a callback function which prints orders for a logged in customer in html format."
    (with-cust-session-check
	(with-standard-customer-page (:title "list dod customer orders")   
	  (:ul :class "nav nav-pills" 
	       (:li :role "presentation" :class "active" (:a :href "dodmyorders" (:i :class "fa-solid fa-list")))
	       (:li :role "presentation" :class "active" (:a :href "dodcustorderscal" (:i :class "fa-regular fa-calendar-days")))
	       (:li :role "presentation" :class "active" (:a :href "dodcustindex" "Shop Now")))

	  (let (( dodorders (hunchentoot:session-value :login-cusord-cache))
		     (header (list  "order no" "order date" "request date"  "actions")))
	    (if dodorders (ui-list-customer-orders header dodorders) "no orders")))
	))


(defun dod-controller-cust-order-data-json ()
 (with-cust-session-check
  (let ((templist '())
	(appendlist '())
	(mylist '())
	(dodorders (hunchentoot:session-value :login-cusord-cache)))
	
    (setf (hunchentoot:content-type*) "application/json")
    
    (mapcar (lambda (order) 
	      (let* ((reqdate (slot-value order 'req-date))
		    (fulfilled (slot-value order 'order-fulfilled))
		    (id (slot-value order 'row-id)))
	 (progn 
	   (setf templist (acons "start"  (format nil "~A" (* 1000 (universal-to-unix-time (get-universal-time-from-date reqdate )))) templist))
	   (setf templist (acons "end"  (format nil "~A" (* 1000 (universal-to-unix-time (get-universal-time-from-date reqdate)))) templist))
	   (if (equal fulfilled "Y")
	       (progn (setf templist (acons "title" (format nil "Order ~A (Completed)" id)  templist))
		      (setf templist (acons "class" "event-success" templist)))
	   ;else
	       (progn (setf templist (acons "title" (format nil "Order ~A (Pending)" id)  templist))
		      (setf templist (acons "class" "event-warning" templist))))
	   (setf templist (acons "url" (format nil "/hhub/hhubcustmyorderdetails?id=~A" id )  templist))
	   (setf templist (acons "id" (format nil "~A" id) templist))
	   
	   (setf appendlist (append appendlist (list templist))) 
	   (setf templist nil)))) dodorders)
	  
           
    (setf mylist (acons "result" appendlist  mylist))    
    (setf mylist (acons "success" 1 mylist))
    (json:encode-json-to-string mylist))
  ;else
	))
    

(defun dod-controller-cust-orders-calendar ()
  (with-cust-session-check
    (with-standard-customer-page  "list dod customer orders"   
				 (:link :href "/css/calendar.css" :rel "stylesheet")
				 (:ul :class "nav nav-pills" 
				      (:li :role "presentation" :class "active" (:a :href "dodmyorders" (:span :class "fa-solid fa-list")))
				      (:li :role "presentation" :class "active" (:a :href "dodcustorderscal" (:span :class "fa-regular fa-calendar-days")))
				      (:li :role "presentation" :class "active" (:a :href "dodcustindex" "Shop Now")))
				 (:div :class "container"
				       (:div :class "page-header"
					     (:div :class "pull-right form-inline"
						   (:div :class "btn-group"
							 (:button :class "btn btn-primary" :data-calendar-nav "prev" "<< Prev")
							 (:button :class "btn btn-default" :data-calendar-nav "today" "Today")
							 (:button :class "btn btn-primary" :data-calendar-nav "next" "Next >>"))
						   
						   (:h3)))
				       (:div :class "row"
					     (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
						   (:div :id "calendar")))
				       (:hr))

				 
					;(modal-dialog (format nil "events-modal") "Calendar Modal" )
				 
				 (:script :type "text/javascript" :src "/js/underscore-min.js")
				 (:script :type "text/javascript" :src "/js/calendar.js")
				 (:script :type "text/javascript" :src "/js/app.js"))))

    


(defun dod-controller-my-orders1 ()
    :documentation "a callback function which prints orders for a logged in customer in html format."
    (let (( dodorders (hunchentoot:session-value :login-cusord-cache)))
      (setf (hunchentoot:content-type*) "application/json")
      (json:encode-json-to-string (get-date-string (slot-value (first dodorders) 'req-date)))))
      ;(with-standard-customer-page (:title "list dod customer orders")   
      ;(if dodorders (mapcar (lambda (ord)
			   ;   (json:encode-json-to-string (get-date-string (slot-value ord 'req-date)))) dodorders))))
					;(cl-who:str (format nil "\"~a\"," (get-date-string (slot-value ord 'req-date))))) dodorders)))))



(defun dod-controller-del-order()
    (with-cust-session-check
	    (let* ((order-id (parse-integer (hunchentoot:parameter "id")))
		  (cust (hunchentoot:session-value :login-customer))
		  (company (hunchentoot:session-value :login-customer-company))
		  (dodorder (get-order-by-id order-id company)))

		(delete-order dodorder)
		(setf (hunchentoot:session-value :login-cusord-cache) (get-orders-for-customer cust))
		(hunchentoot:redirect "/hhub/dodmyorders"))
					;else
	))


(defun modal.vendor-details (id) 
(let ((vendor (select-vendor-by-id id)))  
  (vendor-details-card vendor)))



(defun dod-controller-del-cust-ord-item ()
  (with-cust-session-check
      (let* ((order-id (parse-integer (hunchentoot:parameter "ord")))
	     (redirect-url (format nil "/hhub/hhubcustmyorderdetails?id=~a" order-id))
	     (item-id (parse-integer (hunchentoot:parameter "id")))
	     (company (hunchentoot:session-value :login-customer-company))
	     (order (get-order-by-id order-id company)))
     
					; delete the order item. 
	(delete-order-items (list item-id) company)
	
	; get the new order items list and find out the total. update the order with this new amount.
	(let* ((odtlst (get-order-items order))
	       (vendors (get-vendors-by-orderid order-id company))
	       (custordertotal (if odtlst (reduce #'+ (mapcar (lambda (odt) (* (slot-value odt 'prd-qty) (slot-value odt 'unit-price))) odtlst )) 0))) 
	  
	  ; for each vendor, delete vendor-order if the order items total for that vendor is 0. 
	  (mapcar (lambda (vendor) 
		    (let ((vendororder (get-vendor-orders-by-orderid order-id vendor company))
			  (vendorordertotal (get-order-items-total-for-vendor vendor odtlst)))
		      (if (equal vendorordertotal 0)
			  (delete-order vendororder)))) vendors)
	  
	  (setf (slot-value order 'order-amt) (coerce custordertotal 'float))
	  (update-order order)
	  
	  (if (equal custordertotal 0) 
	      (delete-order order))
					;(sleep 1) 
	  (setf (hunchentoot:session-value :login-cusord-cache) (get-orders-for-customer (get-login-customer)))) 
	     
      (hunchentoot:redirect redirect-url))
      ;else
      ))
	    

	    
(defun  customer-my-order-details (order-id)
  (let* ((dodorder (get-order-by-id order-id (get-login-cust-company)))
	 (header (list "Status" "Action" "Name" "Qty"   "Sub-total" ))
	 (odtlst (get-order-items dodorder))
	 (total (reduce #'+ (mapcar (lambda (odt) (* (slot-value odt 'prd-qty) (slot-value odt 'unit-price))) odtlst)))) 
    (cl-who:with-html-output (*standard-output* nil)
      (if odtlst (ui-list-cust-orderdetails header odtlst) "No Order Details")
      (cl-who:htm (:div :class "row" 
		 (:div :class "col-md-12" :align "right" 
		       (:h2 (:span :class "label label-default" (cl-who:str (format nil "Total = Rs ~$" total)))))))
      (display-order-header-for-customer  dodorder))))


(defun modal.customer-my-orderdetails ()
 (with-cust-session-check (cl-who:with-html-output-to-string (*standard-output* nil) 
    (let* ((order-id (parse-integer (hunchentoot:parameter "id"))))
      (customer-my-order-details order-id)))))


(defun hhub-controller-customer-my-orderdetails ()
  (with-cust-session-check (with-standard-customer-page (:title "Customer My Order Details")
	    (let* ((order-id (parse-integer (hunchentoot:parameter "id"))))
	      (customer-my-order-details order-id)))))

									  


(defun dod-controller-search-products ()
(let* ((search-clause (hunchentoot:parameter "livesearch"))
      (products (if (not (equal "" search-clause)) (search-products search-clause (get-login-cust-company))))
      (shoppingcart (hunchentoot:session-value :login-shopping-cart)))
(ui-list-customer-products  products shoppingcart)))




(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defun with-customer-navigation-bar ()
    :documentation "this macro returns the html text for generating a navigation bar using bootstrap."
    (let ((customer-type (get-login-customer-type)))
       (cl-who:with-html-output (*standard-output* nil)
	 (:div :class "navbar navbar-inverse  navbar-static-top"
	     (:div :class "container-fluid"
		   (:div :class "navbar-header"
			 (:button :type "button" :class "navbar-toggle" :data-toggle "collapse" :data-target "#navheadercollapse"
				  (:span :class "icon-bar")
				  (:span :class "icon-bar")
				  (:span :class "icon-bar"))
			 (:a :class "navbar-brand" :href *siteurl* :title "highrisehub" (:img :style "width: 30px; height: 24px;" :src "/img/logo.png" )))
			;; (:a :class "navbar-brand" :onclick "javascript:history.go(-1);"  :href "#"  (:span :class "glyphicon glyphicon-arrow-left")))
		   (:div :class "collapse navbar-collapse" :id "navheadercollapse"
			 (:ul :class "nav navbar-nav navbar-left"
			      (:li :class "active" :align "center" (:a :href "/hhub/dodcustindex" (:i :class "fa-solid fa-house") "&nbsp;Home"))
			      (if (equal customer-type "STANDARD")
				  (cl-who:htm (:li :align "center" (:a :href "dodcustorderprefs" "Subscriptions"))
					      (:li :align "center" (:a :href "dodcustorderscal" "Orders"))
					      (:li :align "center" (:a :href "dodcustwallet" (:i :class "fa-solid fa-wallet") "&nbsp;Wallets" ))))
					;(:li :align "center" (:a :href "#" (print-web-session-timeout)))
			      (:li :align "center" (:a :href "#" (cl-who:str (format nil "~a" (get-login-customer-company-name))))))
			      
			      (:ul :class "nav navbar-nav navbar-right"
				   (if (equal customer-type "STANDARD")
				       (cl-who:htm
					(:li :align "right" (:a :href "#"   (:i :class "fa-regular fa-bell") "&nbsp;" ))
					(:li :align "right" (:a :href "dodcustprofile"   (:i :class "fa-regular fa-user") "&nbsp;" ))))
				   
			      (if (equal customer-type "GUEST")
				  (cl-who:htm
				   (:li :class "dropdown"
					(:a :href "#" :class "dropdown-toggle" :data-toggle "dropdown" :role "button" :aria-haspopup "true" :aria-expanded "false" "My Account" (:span :class "caret" ))
					(:ul :class "dropdown-menu"
					     (:li (:a :href "dodguestcustlogout" "Member Login" ))
					     (:li 
					      (:form :method "POST" :action "custsignup1action" :id "custsignup1form" 
						     (:div :class "form-group"
							   (:input :class "form-control" :name "cname" :type "hidden" :value (cl-who:str (format nil "~A" (get-login-customer-company-name)))))
						     (:div :class "form-group"
							   (:button :class "btn btn-sm btn-primary btn-block" :type "submit" (cl-who:str (format nil "Sign Up" ))))))))))
			      
					;(:li :align "center" (:a :href "/dodcustshopcart" (:span :class "glyphicon glyphicon-shopping-cart") " my cart " (:span :class "badge" (cl-who:str (format nil " ~a " (length (hunchentoot:session-value :login-shopping-cart)))) )))
			      (:li :align "center" (:a :href "dodcustlogout" (:i :class "fa-solid fa-arrow-right-from-bracket")))))))))))
    

(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defun with-customer-navigation-bar-v2 ()
    :documentation "this macro returns the html text for generating a navigation bar using bootstrap."
    (let ((customer-type (get-login-customer-type)))
       (cl-who:with-html-output (*standard-output* nil)
	 (:nav :class "navbar navbar-expand-sm  navbar-dark bg-dark" 
	       (:div :class "container-fluid"
		     (:a :class "navbar-brand" :href *siteurl* (:img :style "width: 30px; height: 24px;" :src "/img/logo.png" ))
		     (:button :class "navbar-toggler" :type "button" :data-bs-toggle "collapse" :data-bs-target "#navbarSupportedContent" :aria-controls "navbarSupportedContent" :aria-expanded "false" :aria-label "Toggle navigation" 
			      (:span :class "navbar-toggler-icon" ))
		     (:div :class "collapse navbar-collapse justify-content-between" :id "navbarSupportedContent"
			   (:ul :class "navbar-nav me-auto mb-2 mb-lg-0" 
				(:li :class "nav-item" 	
				     (:a :class "nav-link active" :aria-current "page" :href "/hhub/dodcustindex" (:i :class "fa-solid fa-house") "&nbsp;Home"))
				(if (equal customer-type "STANDARD")
				    (cl-who:htm (:li :class "nav-item"  (:a :class "nav-link" :href "dodcustorderprefs" "Subscriptions"))
						(:li :class "nav-item"  (:a :class "nav-link" :href "dodcustorderscal" "Orders"))
						(:li :class "nav-item"  (:a :class "nav-link" :href "dodcustwallet" (:i :class "fa-solid fa-wallet")  "&nbsp;Wallets" ))))
				(:li :class "nav-item"  (:a :class "nav-link" :href "#" (cl-who:str (format nil "~a" (get-login-customer-company-name))))))


				(:ul :class "navbar-nav ms-auto"
				     (if (equal customer-type "STANDARD")
					 (cl-who:htm
					  (:li :class "nav-item"  (:a :class "nav-link" :href "#"  (:i :class "fa-regular fa-bell")))
					  (:li :class "nav-item"  (:a :class "nav-link" :href "dodcustprofile"  (:i :class "fa-regular fa-user")))))
				
				(when (equal customer-type "GUEST")
				  (cl-who:htm
				   (:li :class "nav-item dropdown"
					(:a :class "nav-link dropdown-toggle" :href "#" :id "navbarDropdown" :role "button" :data-bs-toggle "dropdown" :aria-expanded="false" "My Account&nbsp;")
					(:ul :class "dropdown-menu" :aria-labelledby "navbarDropdown"
					     (:li (:a :class "dropdown-item" :href "dodguestcustlogout" "Member Login" ))
					     (:li 
					      (:form :method "POST" :action "custsignup1action" :id "custsignup1form" 
						     (:div :class "form-group"
							   (:input :class "form-control" :name "cname" :type "hidden" :value (cl-who:str (format nil "~A" (get-login-customer-company-name)))))
						     (:div :class "form-group"
							   (:button :class "btn btn-sm btn-primary btn-block" :type "submit" (cl-who:str (format nil "Sign Up" ))))))))))
				(:li :class "nav-item" (:a :class "nav-link" :href "dodcustlogout" (:i :class "fa-solid fa-arrow-right-from-bracket")))))))))))






;;deprecated 
(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defun with-guestuser-navigation-bar ()
    :documentation "this macro returns the html text for generating a navigation bar using bootstrap."
    (cl-who:with-html-output (*standard-output* nil)
       (:div :class "navbar navbar-inverse  navbar-static-top"
	     (:div :class "container-fluid"
		   (:div :class "navbar-header"
			 (:button :type "button" :class "navbar-toggle" :data-toggle "collapse" :data-target "#navheadercollapse"
				  (:span :class "icon-bar")
				  (:span :class "icon-bar")
				  (:span :class "icon-bar"))
			 (:a :class "navbar-brand" :href "#" :title "highrisehub" (:img :style "width: 50px; height: 50px;" :src "/img/logo.png" )  ))
		   (:div :class "collapse navbar-collapse" :id "navheadercollapse"
			 (:ul :class "nav navbar-nav navbar-left"
			      (:li :class "active" :align "center" (:a :href "/hhub/dodcustindex" (:i :class "fa-solid fa-house")  "&nbsp;Home"))
			      (:li :align "center" (:a :href "#" (cl-who:str (format nil "Group: ~a" (get-login-customer-company-name))))))
			 (:ul :class "nav navbar-nav navbar-right"
			      (:li :class "dropdown"
				   (:a :href "#" :class "dropdown-toggle" :data-toggle "dropdown" :role "button" :aria-haspopup "true" :aria-expanded "false" "My Account" (:span :class "caret" ))
				   (:ul :class "dropdown-menu"
					(:li (:a :href "customer-login.html"))
					(:li 
					(:form :method "POST" :action "custsignup1action" :id "custsignup1form" 
				     (:div :class "form-group"
					   (:input :class "form-control" :name "cname" :type "hidden" :value (cl-who:str (format nil "~A" (get-login-customer-company-name)))))
				     (:div :class "form-group"
					   (:button :class "btn btn-sm btn-primary btn-block" :type "submit" (cl-who:str (format nil "~A - Sign Up" (get-login-customer-company-name)))))))
					
					(:li :align "center" (:a :href "dodcustlogout" (:i :class "fa-solid fa-arrow-right-from-bracket")  )))))))))))
  
  
  ;;**********************************************************************************
  ;;***************** customer login related functions ******************************

(defun dod-controller-cust-apt-no ()
 (let ((cname (hunchentoot:parameter "cname")))
   (with-standard-customer-page (:title "welcome to das platform - your demand and supply destination.")
     (:form :class "form-custresister" :role "form" :method "post" :action "dodcustregisteraction"
	    (:div :class "row" 
		  (:div :class "col-lg-6 col-md-6 col-sm-6"
			(:div :class "form-group"
			      (:input :class "form-control" :name "address" :placeholder "Apartment No (Required)" :type "text" ))
			(:div :class "form-group"
			      (:input :class "form-control" :name "tenant-name" :value (format nil "~A" cname) :type "text" :readonly T ))))))))

			


(defun dod-controller-cust-register-page ()
  (let* ((cname (hunchentoot:parameter "cname"))
	 (company (select-company-by-name cname))
	 (cmpname (slot-value company 'name))
	 (cmpaddress (slot-value company 'address)))

    ;; Need to logout of all logged in sessions if any
    (if hunchentoot:*session*  (hunchentoot:remove-session hunchentoot:*session*))
    ;; We need a page without a navbar. 
    (with-no-navbar-page "Welcome to HighriseHub Platform- Your Demand And Supply destination."
      	(:form :class "form-custregister" :role "form" :data-toggle "validator"  :method "POST" :action "custsignup1step2"
	   (:div :class "row"
		 (:img :class "profile-img" :src "/img/logo.png" :alt "")
		 (:h1 :class "text-center login-title"  (cl-who:str (format nil "New Registration to ~A Store" cmpname)))
		 (:hr)) 
	   (:div :class "row" 
		 (:div :class "col-lg-6 col-md-6 col-sm-6"
		       (:div :class "form-group"
			     (:input :class "form-control" :name "tenant-name" :value (format nil "~A" cname) :type "text" :readonly T ))
		       (:div :class "form-group" 
			     (:textarea :class "form-control" :name "address"   :rows "2" :readonly T (cl-who:str (format nil "~A" cmpaddress))))
		       
		       (:div  :class "form-group" (:label :for "reg-type" "Register as:" )
				    (customer-vendor-dropdown))
		       
		       (:div :class "form-group"
			     (:input :class "form-control" :name "name" :placeholder "Full Name (Required)" :type "text" :required T ))
		       (:div :class "form-group"
			     (:input :class "form-control" :name "email" :placeholder "Email (Required)" :type "text" :required T )))
		       (:div :class "col-lg-6 col-md-6 col-sm-6"     
		       (:div :class "form-group"
			     (:input :class "form-control" :name "phone" :placeholder "Your Mobile Number (Required)" :type "text" :required T))
		       (:div :class "form-group"
			     (:input :class "form-control" :name "password" :id "inputpass"  :placeholder "Password" :type "password" :required T ))
		       (:div :class "form-group"
			     (:input :class "form-control" :name "confirmpass" :placeholder "Confirm Password" :type "password" :required T :data-match "#inputpass"  :data-match-error "Passwords dont match" ))
		       (:div :class "form-group"
			     (:div :class "g-recaptcha" :data-sitekey *HHUBRECAPTCHAV2KEY* )
			     (:div :class "form-group"
				   (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))
      (hhub-html-page-footer))))

(defun check&encrypt (password confirmpass salt)
  (when 
	 (and (or  password  (length password)) 
	      (or  confirmpass (length confirmpass))
	      (equal password confirmpass))
 
       (encrypt password salt)))


(defun com-hhub-transaction-customer&vendor-create-otpstep ()
  (let* ((reg-type (hunchentoot:parameter "reg-type"))
	 (captcha-resp (hunchentoot:parameter "g-recaptcha-response"))
	 (paramname (list "secret" "response" ) ) 
	 (paramvalue (list *HHUBRECAPTCHAV2SECRET*  captcha-resp))
	 (param-alist (pairlis paramname paramvalue ))
	 (json-response (json:decode-json-from-string  (map 'string 'code-char(drakma:http-request *HHUBRECAPTCHAURL*
												   :method :POST
												   :parameters param-alist  ))))
	 (name (hunchentoot:parameter "name"))
	 (email (hunchentoot:parameter "email"))
	 (groupname (hunchentoot:parameter "tenant-name"))
	 (address (hunchentoot:parameter "address"))
	 (fulladdress (concatenate 'string  groupname ", " address)) 
	 (phone (hunchentoot:parameter "phone"))
	 (password (hunchentoot:parameter "password"))
	 (confirmpass (hunchentoot:parameter "confirmpass"))
	 (salt-octet (secure-random:bytes 56 secure-random:*generator*))
	 (salt (flexi-streams:octets-to-string  salt-octet))
	 (encryptedpass (check&encrypt password confirmpass salt))
	 (tenant-name (hunchentoot:parameter "tenant-name"))
	 (company (select-company-by-name tenant-name))
	 (tenant-id (slot-value company 'row-id))
	 (context "dodcustregisteraction"))
    
    ;; Start a new session 
    (hunchentoot:start-session)
    ;; Keep the session for 5 mins only. 
    (setf hunchentoot:*session-max-time* (* 60 5))
    
    (cond
      ((null encryptedpass) (dod-response-passwords-do-not-match-error))
      ;; Check for duplicate customer
      ((and (equal reg-type "CUS") (duplicate-customerp phone company)) (hunchentoot:redirect "/hhub/duplicate-cust.html"))
      ;; Check whether captcha has been solved 
      ((null (cdr (car json-response))) (dod-response-captcha-error))
     
      ((and encryptedpass (equal reg-type "VEN"))
       (let ((vendor (make-instance 'dod-vend-profile
				    :name name
				    :address fulladdress
				    :email email 
				    :password password 
				    :salt salt
				    :phone phone
				    :city nil 
				    :state nil 
				    :zipcode nil
				    :tenant-id tenant-id
				    :push-notify-subs-flag "N"
				    :deleted-state "N")))
	 (setf (hunchentoot:session-value :newvendorcreate) vendor)))
      ((and encryptedpass (equal reg-type "CUS"))
       (let ((customer (make-instance 'dod-cust-profile
				      :name name
				      :address fulladdress
				      :email email 
				      :password password 
				      :salt salt
				      :birthdate nil 
				      :phone phone
				      :city nil
				      :state nil
				      :zipcode nil
				      :tenant-id tenant-id
				      :cust-type "STANDARD"
				      :active-flag "N"
				      :deleted-state "N")))
	 (setf (hunchentoot:session-value :newcustomercreate) customer))))

    (setf (hunchentoot:session-value :reg-type) reg-type)
    (setf (hunchentoot:session-value :company) company)
    (generateotp&redirect phone context)))



(defun com-hhub-transaction-customer&vendor-create ()
  (let* ((reg-type (hunchentoot:session-value :reg-type))
	 (company (hunchentoot:session-value :company))
	 (customer (hunchentoot:session-value :newcustomercreate))
	 (vendor (hunchentoot:session-value :newvendorcreate))
	 (params nil))
    ;; Let us clear the session we created in previous pages. 
      (hunchentoot:remove-session hunchentoot:*session*)
    ;; Preparing for security policy execution. 
    (setf params (acons "company" company params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-customer&vendor-create" params 
      (cond
      	((equal reg-type "VEN")
	(progn 
					; 1 
	  (clsql:update-records-from-instance vendor)
	  (sleep 1) ; Sleep for 1 second after creating the vendor record.  
	  (let ((name (slot-value vendor 'name))
		(email (slot-value vendor 'email)))
	    (create-vendor-tenant vendor "Y" company)
					; 2
	    (send-registration-email name email))
					;3
	 (with-no-navbar-page "Welcome to HighriseHub platform"
	   (:h3 (cl-who:str(format nil "Your record has been successfully added" )))
	   (:a :href "/hhub/vendor-login.html" "Login now"))))
      
      ((equal reg-type "CUS")  
       (progn 
					; 1 
	 (clsql:update-records-from-instance customer)
					; 2
	 (let ((name (slot-value customer 'name))
	       (email (slot-value customer 'email)))
	   (send-registration-email name email))
					;3
	 (with-no-navbar-page "Welcome to HighriseHub platform"
	   (:h3 (cl-who:str(format nil "Your record has been successfully added" )))
	   (:a :href "/hhub/customer-login.html" "Login now"))))))))
  




(defun dod-response-passwords-do-not-match-error ()
   (with-standard-customer-page (:title "Passwords do not match error.")
    (:h2 "Passwords do not match. Please try again. ")
    	(:a :class "btn btn-primary" :role "button" :onclick "goBack();"  :href "#" (:i :class "fa-solid fa-arrow-left" "Go Back"))))


(defun dod-response-captcha-error ()
  (with-standard-customer-page (:title "Captcha response error from Google")
    (:h2 "Captcha response error from Google. Looks like some unusual activity. Please try again later")))


(defun dod-controller-duplicate-customer ()
     (with-standard-customer-page (:title "Welcome to HighriseHub platform")
	 (:h3 (cl-who:str(format nil "Customer record has already been created" )))
	 (:a :href "cust-register.html" "Register new customer")))
  
    
(defun dod-controller-company-search-action ()
  (let*  ((qrystr (hunchentoot:parameter "livesearch"))
	(company-list (if (not (equal "" qrystr)) (select-companies-by-name qrystr))))
    (ui-list-companies company-list)))




(defun dod-controller-company-search-page ()
  (handler-case
      (progn  (if (equal (caar (clsql:query "select 1" :flatp nil :field-names nil :database *dod-db-instance*)) 1) T)	      
	      (with-standard-customer-page "Welcome to HighriseHub platform" 
		(:div :class "row"
		      (:h2 "Store Search.")
		      (:div :id "custom-search-input"
			    (:div :class "input-group col-xs-12 col-sm-12 col-md-12 col-lg-12"
				  (with-html-search-form "companysearchaction" "Enter Pincode. For ex: 560001")))
		(:div :id "searchresult"))
		(:hr)
		(:div :class "row"
		      (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
			    (:a :class "order-box"  :href "hhubnewcommstorerequest?cmp-type=COMMUNITY"  "Store Not Found? Create New Public Store For Your Pincode - FREE!"))
		      (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6" :style "display: none;"
			    (:a :class "order-box"  :href "pricing"  "New Grocery, Mobile, Apparel, Electronics Store.")))
		
		(:hr)
		(hhub-html-page-footer)))
		      
    (clsql:sql-database-data-error (condition)
      (if (equal (clsql:sql-error-error-id condition) 2006 ) (progn
							       (stop-das) 
							       (start-das)
							       )))))

(defun dod-controller-customer-password-reset-action ()
  (let* ((pwdresettoken (hunchentoot:parameter "token"))
	 (rstpassinst (get-reset-password-instance-by-token pwdresettoken))
	 (user-type (if rstpassinst (slot-value rstpassinst 'user-type)))
	 (password (hunchentoot:parameter "password"))
	 (newpassword (hunchentoot:parameter "newpassword"))
	 (confirmpassword (hunchentoot:parameter "confirmpassword"))
	 (salt-octet (secure-random:bytes 56 secure-random:*generator*))
	 (salt (flexi-streams:octets-to-string  salt-octet))
	 (encryptedpass (check&encrypt newpassword confirmpassword salt))
	 (email (if rstpassinst (slot-value rstpassinst 'email)))
	 (customer (select-customer-by-email email))
	 (present-salt (if customer (slot-value customer 'salt)))
	 (present-pwd (if customer (slot-value customer 'password)))
	 (password-verified (if customer  (check-password password present-salt present-pwd))))
     (cond 
       ((or  (not password-verified)  (null encryptedpass)) (dod-response-passwords-do-not-match-error)) 
       ;Token has expired
       ((and (equal user-type "CUSTOMER")
		 (clsql-sys:duration> (clsql-sys:time-difference (clsql-sys:get-time) (slot-value rstpassinst 'created))  (clsql-sys:make-duration :minute *HHUBPASSRESETTIMEWINDOW*))) (hunchentoot:redirect "/hhub/hhubpassresettokenexpired.html"))
       ((and password-verified encryptedpass) (progn 
       (setf (slot-value customer 'password) encryptedpass)
       (setf (slot-value customer 'salt) salt) 
       (update-customer customer)
       (hunchentoot:redirect "/hhub/customer-login.html"))))))
 


(defun dod-controller-customer-password-reset-page ()
  (let ((token (hunchentoot:parameter "token")))
(with-standard-customer-page (:title "Password Reset") 
(:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
			 (:h1 :class "text-center login-title"  "Change Password")
			 (:div :class "form-group"
			  
			       (:input :class "form-control" :name "token" :value token :type "hidden"))
			 (:div :class "form-group"
			       (:label :for "password" "Password")
			       (:input :class "form-control" :name "password" :value "" :placeholder "Enter OTP from Email Old" :type "password" :required T))
			 (:div :class "form-group"
			       (:label :for "newpassword" "New Password")
			       (:input :class "form-control" :id "newpassword" :data-minlength "8" :name "newpassword" :value "" :placeholder "New Password" :type "password" :required T))
			 (:div :class "form-group"
			       (:label :for "confirmpassword" "Confirm New Password")
			       (:input :class "form-control" :name "confirmpassword" :value "" :data-minlength "8" :placeholder "Confirm New Password" :type "password" :required T :data-match "#newpassword"  :data-match-error "Passwords dont match"  ))
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))


(defun dod-controller-customer-generate-temp-password ()
  (let* ((token (hunchentoot:parameter "token"))
	 (rstpassinst (get-reset-password-instance-by-token token))
	 (user-type (if rstpassinst (slot-value rstpassinst 'user-type)))
	 (url (format nil "~A/hhub/hhubcustpassreset.html?token=~A" *siteurl* token))
	 (email (if rstpassinst (slot-value rstpassinst 'email))))
    
	 (cond 
	   ((and (equal user-type "CUSTOMER")
		 (clsql-sys:duration< (clsql-sys:time-difference (clsql-sys:get-time) (slot-value rstpassinst 'created))  (clsql-sys:make-duration :minute *HHUBPASSRESETTIMEWINDOW*)))
	    (let* ((customer (select-customer-by-email email))
		   (newpassword (reset-customer-password customer)))
					;send mail to the customer with new password 
	      (send-temp-password customer newpassword url)
	      (hunchentoot:redirect "/hhub/hhubpassresetmailsent.html")))	  
	   ((and (equal user-type "CUSTOMER")
		 (clsql-sys:duration> (clsql-sys:time-difference (clsql-sys:get-time) (slot-value rstpassinst 'created))  (clsql-sys:make-duration :minute *HHUBPASSRESETTIMEWINDOW*))) (hunchentoot:redirect "/hhub/hhubpassresettokenexpired.html"))
	   ((equal user-type "VENDOR") ())
	   ((equal user-type "EMPLOYEE") ()))))

			   
(defun dod-controller-customer-reset-password-action-link ()
  (let* ((email (hunchentoot:parameter "email"))
	 (customer (select-customer-by-email email))
	 (token (format nil "~A" (uuid:make-v1-uuid )))
	 (user-type (hunchentoot:parameter "user-type"))
	 (tenant-id (if customer (slot-value customer 'tenant-id)))
	 (captcha-resp (hunchentoot:parameter "g-recaptcha-response"))
	 (url (format nil "~A/hhub/hhubcustgentemppass?token=~A" *siteurl* token))
	 (paramname (list "secret" "response" ) ) 
	 (paramvalue (list *HHUBRECAPTCHAV2SECRET*  captcha-resp))
	 (param-alist (pairlis paramname paramvalue ))
	 (json-response (json:decode-json-from-string  (map 'string 'code-char(drakma:http-request "https://www.google.com/recaptcha/api/siteverify"
												 :method :POST
												 :parameters param-alist)))))
    
    (cond 	 ; Check whether captcha has been solved 
      ((null (cdr (car json-response))) (dod-response-captcha-error))
      ((null customer) (hunchentoot:redirect "/hhub/hhubinvalidemail.html"))
					; if customer is valid then create an entry in the password reset table. 
      ((and (equal user-type "CUSTOMER") customer)
       (progn 
	 (create-reset-password-instance user-type token email  tenant-id)
					; temporarily disable the customer record 
	 (setf (slot-value customer 'active-flag) "N")
	 (update-customer customer) 
					; Send customer an email with password reset link. 
	 (send-password-reset-link customer url)
	 (hunchentoot:redirect "/hhub/hhubpassresetmaillinksent.html"))))))



(defun modal.customer-forgot-password() 
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(:form :id (format nil "form-customerforgotpass") :data-toggle "validator"  :role "form" :method "POST" :action "hhubcustforgotpassactionlink" :enctype "multipart/form-data" 
		      (:h1 :class "text-center login-title"  "Forgot Password")
		      (:div :class "form-group"
			    (:input :class "form-control" :name "email" :value "" :placeholder "Email" :type "email" :required "true")
			    (:input :class "form-control" :name "user-type" :value "CUSTOMER"  :type "hidden" :required "true"))
			    
	 	     (:div :class "form-group"
			(:div :class "g-recaptcha" :data-sitekey *HHUBRECAPTCHAV2KEY* ))
		      (:div :class "form-group"
			    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Reset Password")))))))


(defun dod-controller-customer-loginpage ()
  (handler-case 
      (progn  
	(if (equal (caar (clsql:query "select 1" :flatp nil :field-names nil :database *dod-db-instance*)) 1) T)      
	(if (is-dod-cust-session-valid?)
	    (hunchentoot:redirect "/hhub/dodcustindex")
	    (with-standard-customer-page "Welcome Customer" 
	      (:div :class "row" 
		    (:div :class "col-sm-6 col-md-4 col-md-offset-4"
			   (:div :class "account-wall"
				 (:form :class "form-custsignin" :role "form" :method "POST" :action "dodcustlogin" :data-toggle "validator"
					(:a :href *siteurl* (:img :class "profile-img" :src "/img/logo.png" :alt ""))
				       (:h1 :class "text-center login-title"  "Customer - Login")
				       (:div :class "form-group"
					     (:input :class "form-control" :name "phone" :placeholder "Enter RMN. Ex: 9999999999" :type "number" :required "true" ))
				       (:div :class "form-group"
					     (:input :class "form-control" :name "password" :placeholder "password=Welcome1" :type "password"  :required "true" ))
				       (:div :class "form-group"
					     (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))
				       
				       (:div :class "form-group"
					     (:a :data-toggle "modal" :data-target (format nil "#dascustforgotpass-modal")  :href "#"  "Forgot Password?"))
				       (modal-dialog (format nil "dascustforgotpass-modal") "Forgot Password?" (modal.customer-forgot-password))

				       ))))))  
    (clsql:sql-database-data-error (condition)
      (if (equal (clsql:sql-error-error-id condition) 2013 ) (progn
							       (stop-das) 
							       (start-das)
							       (hunchentoot:redirect "/hhub/customer-login.html"))))))



(defun dod-controller-cust-add-orderpref-page ()
    (with-cust-session-check
	(let* ((prd-id (hunchentoot:parameter "prd-id"))
	  (productlist (hunchentoot:session-value :login-prd-cache))
	  (product (search-prd-in-list (parse-integer prd-id) productlist)))
	(with-standard-customer-page (:title "Welcome to HighriseHub- Add Customer Order preference")
	    (:div :class "row" 
		(:div :class "col-sm-12  col-xs-12 col-md-12 col-lg-12"
		   (:h1 :class "text-center login-title"  "Subscription - Add ")
			(:form :class "form-oprefadd" :role "form" :method "POST" :action "dodcustaddopfaction"
			    (:div :class "form-group row"  (:label :for "product-id" (cl-who:str (format nil  "Product: ~a" (slot-value product 'prd-name))) ))
			         (:input :type "hidden" :name "product-id" :value (format nil "~a" (slot-value product 'row-id)))
				 ; (products-dropdown "product-id"  (hunchentoot:session-value :login-prd-cache)))
			    (:div :class "form-group row" (:label :for "prdqty" "Product Quantity")
				(:input :class "form-control" :name "prdqty" :placeholder "Enter a number" :value "1" :min "1" :max "99"  :type "number"))
			    (:div :class "form-group row" 
			    (:label :class "checkbox-inline"  (:input :type "checkbox" :name "subs-sun"  :value "Sunday" :checked "" "Sunday" ))
			    (:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-mon" :value "Monday" :checked "" "Monday"))
			    (:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-tue" :value "Tuesday" :checked "" "Tuesday")))
			    (:div :class "form-group row" 
			    (:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-wed" :value "Wednesday" :checked "" "Wednesday"))
			    (:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-thu" :value "Thursday" :checked "" "Thursday"))
				(:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-fri" :value "Friday" :checked "" "Friday")))
			    (:div :class "form-group row" 
			    (:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-sat" :value "Saturday" :checked "" "Saturday")))
			    
			    (:div :class "form-group" 
			    (:input :type "submit"  :class "btn btn-primary" :value "Add      "))
			    )))))
	))

(defun product-qty-edit-html (prd-id)
  (let* ((productlist (hunchentoot:session-value :login-prd-cache))
	 (product (search-prd-in-list prd-id  productlist))
	 (prd-image-path (slot-value product 'prd-image-path))
	 (description (slot-value product 'description))
	 (unit-price (slot-value product 'unit-price))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (prd-name (slot-value product 'prd-name))
	 (upbtn (format nil "up_~A" prd-id))
	 (downbtn (format nil "down_~A" prd-id)))
    
  (cl-who:with-html-output (*standard-output* nil)
   (:div :align "center" :class "row" 
	 (:div :class "col-sm-12  col-xs-12 col-md-12 col-lg-12"
	       (:form :class "form-addproduct" :id (format nil "format-addproduct~A" prd-id) :method "POST" :action "dodcustaddtocart" 
		      (:input :type "hidden" :name "prd-id" :value (format nil "~A" prd-id))
		      (:div :class "row"
			    (:div :class "col-xs-12" 	 (:h5 :class "product-name"  (cl-who:str prd-name))))
		      (:div  :class "row" 
			     (:div  :class "col-xs-6" 
			     (:a :href (format nil "dodprddetailsforcust?id=~A" prd-id) 
				 (:img :src  (format nil "~A" prd-image-path) :height "83" :width "100" :alt prd-name " ")))
			     (:div  :class "col-xs-6"  (:h4 (:span :class "label label-info" (cl-who:str (format nil "Rs. ~$ / ~A"  unit-price qty-per-unit))))))
		     
		      (:div :class "row" 
		      (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12" 
			    (:h6 (cl-who:str (if (> (length description) 150)  (subseq description  0 150) description)))))
		
		      
	        (:div  :class "inputQty row" 
	       (:div :class "col-xs-4"
		     (:a :class "down btn btn-primary" :id downbtn :onClick "minusbtnclick(this.id);" :href "#" (:i :class "fa-solid fa-minus"))) 
	       (:div :class "form-group col-xs-4" 
		     (:input :class "form-control input-quantity" :readonly "true"  :name "prdqty" :id (format nil "prdqtyfor_~A" prd-id)  :value "1"  :min "1" :max units-in-stock  :type "number"))
	       (:div :class "col-xs-4"
		     (:a :class "up btn btn-primary" :id upbtn :onClick "plusbtnclick(this.id);" :href "#" (:span :class "fa-solid fa-plus"))))
	 
		(:div :class "form-group" 
		      (:input :type "submit"  :class "btn btn-primary" :value "Add To Cart"))))))))
  
  
(defun product-subscribe-html (prd-id) 
  (let* ((productlist (hunchentoot:session-value :login-prd-cache))
	 (product (search-prd-in-list prd-id  productlist))
	 (prd-image-path (slot-value product 'prd-image-path))
	 (prd-name (slot-value product 'prd-name)))
    
 (cl-who:with-html-output (*standard-output* nil)
   (:div :align "center" :class "row account-wall" 
	 (:div :class "col-sm-12  col-xs-12 col-md-12 col-lg-12"
	       (:div  :class "row" 
		     (:div  :class "col-xs-12" 
			     (:a :href (format nil "dodprddetailsforcust?id=~A" prd-id) 
				 (:img :src  (format nil "~A" prd-image-path) :height "83" :width "100" :alt prd-name " "))))
			(:form :class "form-oprefadd" :role "form" :method "POST" :action "dodcustaddopfaction"
			    (:div :class "form-group row"  (:label :for "product-id" (cl-who:str (format nil  " ~a" (slot-value product 'prd-name))) ))
			         (:input :type "hidden" :name "product-id" :value (format nil "~a" (slot-value product 'row-id)))
				 ; (products-dropdown "product-id"  (hunchentoot:session-value :login-prd-cache)))
				 
				 ;(:div :class "inputQty"
				  ;     (:span :class "up" "up" )
				   ;    (:input :type "text" :maxlength "6" :name "oa_quantity" :class "input-quantity"  :value "1")
				    ;   (:span :class "down" "down"))

				 (:div  :class "inputQty row" 
				 (:div :class "col-xs-4"
				  (:a :class "down btn btn-primary" :href "#" (:i :class "fa-solid fa-minus"))) 
				  (:div :class "form-group col-xs-4" 
				(:input :class "form-control input-quantity" :readonly "true" :name "prdqty" :placeholder "Enter a number"  :value "1" :min "1" :max "99"  :type "number"))
				  (:div :class "col-xs-4"
				  (:a :class "up btn btn-primary" :href "#" (:i :class "fa-solid fa-plus" ""))))
			    (:div :class "form-group row" 
				  (:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-mon" :value "Monday" :checked "" "Monday"))
				  (:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-tue" :value "Tuesday" :checked "" "Tuesday"))
				  (:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-wed" :value "Wednesday" :checked "" "Wednesday")))
			    (:div :class "form-group row" 
				  (:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-thu" :value "Thursday" :checked "" "Thursday"))
				  (:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-fri" :value "Friday" :checked "" "Friday"))
				  (:label :class "checkbox-inline" (:input :type "checkbox" :name "subs-sat" :value "Saturday" :checked "" "Saturday"))
				  (:label :class "checkbox-inline"  (:input :type "checkbox" :name "subs-sun"  :value "Sunday" :checked "" "Sunday" )))
			    
			    (:div :class "form-group" 
			    (:input :type "submit"  :class "btn btn-primary" :value "Subscribe"))
			    ))))))



;;;;;;; Add order page for Standard customer ;;;;;;;;;;;;
;;;;;;; We are going to use INVERSION OF CONTROL and
;;;;;;; let the caller make the decision of deciding
;;;;;;; whether to call the STANDARD customer function
;;;;;;; or GUEST customer function. Also, we have more choices to make
;;;;;;; 1) Online payment page redirection for Standard Customer
;;;;;;; 2) Read only shopping cart for COD orders,
;;;;;;;  which could be for both Standard & Guest customers.

(defun standard-cust-add-order-page (&optional (paymentmode "PRE"))
  (cl-who:with-html-output-to-string  (*standard-output* nil)
	  (:div :class "row" 
		(:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
		      (:h1 :class "text-center login-title"  "Select Order Date ")
		      (:form :class "form-order" :role "form" :method "POST" :action "hhubcustpaymentmethodspage" :data-toggle "validator"
			     (:div  :class "form-group" (:label :for "orddate" "Order Date" )
				    (:input :class "form-control" :name "orddate" :value (cl-who:str (get-date-string (clsql::get-date))) :type "text"  :readonly "true"  ))
			     (:div :class "form-group"  (:label :for "reqdate" "Required On - Click To Change" )
				   (:input :class "form-control" :name "reqdate" :id "required-on" :placeholder  (cl-who:str (format nil "~A. Click to change" (get-date-string (clsql::date+ (clsql::get-date) (clsql::make-duration :day 1))))) :type "text" :value (get-date-string (clsql::date+ (clsql::get-date) (clsql::make-duration :day 1)))))

			     (:div  :class "form-group" :style "display:none;"
				    (:label :for "payment-mode" "Payment Mode" )
				    (std-cust-payment-mode-dropdown paymentmode))
			     (:input :type "submit"  :class "btn btn-primary"  :value "Checkout"))))))



(defun guest-cust-add-order-page (&optional paymentmode)
  (let* ((temp-customer (hunchentoot:session-value :temp-guest-customer))
	 (temp-cust-name (if temp-customer (slot-value temp-customer 'name)))
         (temp-cust-address (if temp-customer (slot-value temp-customer 'address) ""))
	 (temp-cust-city (if temp-customer (slot-value temp-customer 'city)))
	 (temp-cust-state (if temp-customer (slot-value temp-customer 'state)))
	 (temp-cust-zipcode (if temp-customer (slot-value temp-customer 'zipcode)))
	 (temp-cust-phone (if temp-customer (slot-value temp-customer 'phone)))
         (temp-cust-email (if temp-customer  (slot-value temp-customer 'email))))
   
  (cl-who:with-html-output-to-string (*standard-output* nil)
    (:form :class "form-guestcustorder" :role "form" :id "hhubordcustdetails"  :method "POST" :action "hhubcustpaymentmethodspage" :data-toggle "validator"
	   (:div :class "row" 
		 (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
		      (:h1 :class "text-center login-title"  "Billing Details ")
		 
			     (:div  :class "form-group" (:label :for "orddate" "Order Date" )
				    (:input :class "form-control" :name "orddate" :value (cl-who:str (get-date-string (clsql-sys::get-date))) :type "text"  :readonly T  ))
			     (:div :class "form-group"  (:label :for "reqdate" "Required On - Click To Change" )
				   (:input :class "form-control" :name "reqdate" :id "required-on" :placeholder  (cl-who:str (format nil "~A. Click to change" (get-date-string (clsql::date+ (clsql::get-date) (clsql::make-duration :day 1))))) :type "text" :value (get-date-string (clsql-sys:date+ (clsql-sys:get-date) (clsql-sys:make-duration :day 1)))))))
	   (:div :class "row" 
		 (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
		       (:div :class "form-group" (:label :for "custname" "Name" )
			     (:input :class "form-control" :type "text" :class "form-control" :name "custname" :value temp-cust-name :placeholder "Name" :tabindex "1" :required T))))
		      ;; (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
			;;     (:div :class "form-group" (:label :for "lastname" "Lastname" )
			;;	   (:input :class "form-control" :type "text" :class "form-control" :name "shiplastname" :placeholder "Lastname" :tabindex "2" :required T))))
		  
	   (:div :class "row"
		 (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
		       (:div :class "form-group" (:label :for "phone" "Phone" )
			     (:input :class "form-control" :type "text" :class "form-control" :name "phone" :value temp-cust-phone :placeholder "Mobile Phone (9999999999) " :tabindex "3" :maxlength "13"  :required T )))
			      
		 (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
		       (:div :class "form-group" (:label :for "email" "Email" )
			     (:input :class "form-control" :type "email" :class "form-control" :name "email" :value temp-cust-email :placeholder "Email" :data-error "That email address is invalid" :tabindex "4" ))))
	   (:div :class "row"
		 (:hr))
	   ;; Row for Shipping and Billing Address. 
	   (:div :class "row"
		 (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
		       (:div :class "row"
			     (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
				   (:h5 "Shipping Address Details")
				   (:br)))
		       
		       (:div :class "row"
			     (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
				   (:div :class "form-group" (:label :for "shipaddress" "Shipping Address" )
					 (:textarea :class "form-control" :id "shipaddress" :name "shipaddress"  :rows "3" :onkeyup "countChar(this, 400)" :tabindex "5" (cl-who:str (format nil "~A" temp-cust-address))))
				   (:div :id "charcount" :class "form-group")
					
				   
				   (:div :class "form-group" (:label :for "shipzipcode" "Pincode" )
					 (:input :class "form-control" :type "text" :class "form-control" :inputmode "numeric" :maxlength "6" :id "shipzipcode" :name "shipzipcode" :value temp-cust-zipcode :placeholder "Pincode" :tabindex "8"  :oninput "this.value=this.value.replace(/[^0-9]/g,'');"  ))
				   (:div :class "form-group"
					 (:span :id "areaname" :class "label label-info" ""))
				   (:div :class "form-group" (:label :for "city" "City" )
					 (:input :class "form-control" :type "text" :class "form-control" :name "shipcity" :value temp-cust-city :id "shipcity" :placeholder "City" :readonly T :required T))
				   (:div :class "form-group" (:label :for "state" "State" )
					 (:input :class "form-control" :type "text" :class "form-control" :name "shipstate" :value temp-cust-state :id "shipstate"  :placeholder "State"  :readonly T :required T )))))
		 
	   (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6" 
		 (:div :class "row"
		       (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
			     (:h5 "Billing Address Details"))
		       (:div :class "form-check"
			     (:input :type "checkbox" :id "billsameasshipchecked" :name "billsameasshipchecked" :value  "billsameasshipchecked" :onclick "displaybillingaddress();" :tabindex "9"  :checked "true")
			     (:label :class= "form-check-label" :for "billsameasshipchecked" "&nbsp;&nbsp;Same as Shipping Address")))
		 
		 (:div :class "row"  :id "billingaddressrow" :style "display: none;"
		       	     (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
				   (:div :class "form-group" (:label :for "shipaddress" "Billing Address" )
					 (:textarea :class "form-control" :name "billaddress" :id "billaddress" :rows "4"  :tabindex "7"))
				   (:div :class "form-group" (:label :for "zipcode" "Pincode" )
					 (:input :class "form-control" :type "text" :class "form-control" :inputmode "numeric" :maxlength "6" :id "billzipcode" :name "billzipcode" :tabindex "8" :placeholder "Pincode" ))
				   (:div :class "form-group" (:label :for "city" "City" )
					 (:input :class "form-control" :type "text" :class "form-control" :name "billcity" :id "billcity"  :placeholder "City" ))
				   (:div :class "form-group" (:label :for "state" "State" )
					 (:input :class "form-control" :type "text" :class "form-control" :name "billstate" :id "billstate" :placeholder "State" ))))))
	
	   
	   (:div :class "row"
		 (:hr))
	   
	    (:div :class "row" :style "display: none;"
		  (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
			(:h4 "(optional)" ))
		  (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
			(:div :class "form-check"
		       (:input :type "checkbox" :id "claimitcchecked" :name "claimitcchecked" :value  "claimitcchecked" :onclick "displaygstdetails();")
				   (:label :class "form-check-label" :for "claimitcchecked" "&nbsp;&nbsp;GST Invoice"))))
		 
	   (:div :class "row" :id "gstdetailsfororder" :style "display:none;"
		 (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
		 		       (:div :class "form-group" (:label :for "gstnumber" "GST Number" )
			     (:input :class "form-control" :type "text" :class "form-control" :name "gstnumber" :tabindex "9" :placeholder "GST Number" )))
		 (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
		       (:div :class "form-group" (:label :for "gstorgname" "Organization/Firm/Company Name" )
			     (:input :class "form-control" :type "text" :class "form-control" :name "gstorgname" :tabindex "10"  :placeholder "Org/Firm/Company Name" ))))
	   (:div :class "row"
		 (:hr))
	   
	   (:div :class "row" :style "display:none;"
		 (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
		       (:div  :class "form-group" (:label :for "payment-mode" "Payment Mode" )
			      (guest-cust-payment-mode-dropdown paymentmode))))
	   (:div :class "row" :style "display:block;"
		 (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-6"
		       (:div :class "form-check"
			     (:input :type "checkbox" :name "tnccheck" :value  "tncagreed" :tabindex "11" :required T)
			     (:label :class= "form-check-label" :for "tnccheck" "&nbsp;&nbsp;Agree Terms and Conditions&nbsp;&nbsp;")
			     (:a  :href "/hhub/tnc" (:i :class "fa-solid fa-scale-balanced") "&nbsp;Terms"))
		       ;;(:div :class "form-check" 
			 ;;    (:input :type "checkbox" :name "privacycheck" :value "privacyagreed" :tabindex "12" :required T)
			 ;;    (:label :class= "form-check-label" :for "tnccheck" "&nbsp;&nbsp;Agree Privacy Policy&nbsp;&nbsp;")
			 ;;    (:a  :href "https://www.highrisehub.com/tnc.html"  (:i :class "fa fa-eye" :aria-hidden "true") "&nbsp;&nbsp;Privacy"))
		       (:div :class "form-group"
			     (:div :class "g-recaptcha" :required T  :data-sitekey *HHUBRECAPTCHAV2KEY* ))
		       (:input :class "form-control" :name "payment-mode" :value paymentmode :type "hidden")
		       (:input :type "submit"  :class "btn btn-primary" :tabindex "13" :value "Checkout"))))

	   (:div :class "row"
		 (:hr)))))

(defun dod-controller-cust-add-order-page()
  (let ((cust-type (get-login-customer-type))
	(paymentmode (hunchentoot:parameter "paymentmode")))
    (with-cust-session-check
      (with-standard-customer-page  "Add Customer Order"
	(cl-who:str (cust-add-order-page cust-type paymentmode))))))

;;; This function has been separated from the controller function because it is independently testable.

(defun cust-add-order-page(cust-type paymentmode)
  ;; We are using a hash table to store the function references to call them later.
  ;; This is a good practice to avoid IF condition.
  (let ((temp-ht (make-hash-table :test 'equal)))
    (setf (gethash "STANDARD"  temp-ht) (symbol-function 'standard-cust-add-order-page))
    (setf (gethash "GUEST" temp-ht) (symbol-function 'guest-cust-add-order-page))
    (funcall (gethash cust-type temp-ht) paymentmode)))


(defun dod-controller-cust-add-order-detail-page ()
    (with-cust-session-check
	(with-standard-customer-page  "Welcome to HighriseHub- Add Customer Order"
	    (:div :class "row background-image: url(resources/login-background.png);background-color:lightblue;" 
		(:div :class "col-sm-6 col-md-4 col-md-offset-4"
		    (:div :class "orderpref"
			(:h1 :class "text-center login-title"  "Customer - Add order preference")
			(:form :class "form-order" :role "form" :method "POST" :action "dodcustaddorderaction"
			    (:div :class "form-group" (:label :for "orddate" "Order Date" )
				(:input :class "form-control" :name "orddate" :placeholder "DD/MM/YYYY" :type "text"))
			    (:div :class "form-group" (:label :for "reqdate" "Required On" )
				(:input :class "form-control" :name "reqdate" :placeholder "DD/MM/YYYY" :type "text"))
			    (:div :class "form-group" (:label :for "shipaddress" "Required On" )
				(:input :class "form-control" :name "shipaddress" :type "text"))
			    (products-dropdown "product-id" (select-products-by-company (hunchentoot:session-value :login-customer-company ))))
			(:div :class "form-group" (:label :for "prdqty" "Product Quantity")
			    (:input :class "form-control" :name "prdqty" :placeholder "Enter a number" :type "text"))
			(:input :type "submit"  :class "btn btn-primary" :value "Add      ")))))))



(defun dod-controller-cust-add-orderpref-action ()
    (with-cust-session-check
	(let ((product-id (hunchentoot:parameter "product-id"))
		 (login-cust (hunchentoot:session-value :login-customer))
		 (login-cust-comp (hunchentoot:session-value :login-customer-company  ))
		 (prd-qty (parse-integer (hunchentoot:parameter "prdqty")))
		 (subs-mon (hunchentoot:parameter "subs-mon"))
		 (subs-tue (hunchentoot:parameter "subs-tue"))
		 (subs-wed (hunchentoot:parameter "subs-wed"))
		 (subs-thu (hunchentoot:parameter "subs-thu"))
		 (subs-fri (hunchentoot:parameter "subs-fri"))
		 (subs-sat (hunchentoot:parameter "subs-sat"))
		 (subs-sun (hunchentoot:parameter "subs-sun"))		 )
	  
		(if (> prd-qty 0) 
		(create-opref login-cust  (select-product-by-id product-id login-cust-comp )  prd-qty  (list subs-mon subs-tue subs-wed subs-thu subs-fri subs-sat subs-sun)  login-cust-comp))
		(setf (hunchentoot:session-value :login-cusopf-cache) (get-opreflist-for-customer login-cust))
		(hunchentoot:redirect "/hhub/dodcustorderprefs"))
	))

  
;; This is products dropdown
(defun  products-dropdown (dropdown-name products)
  (cl-who:with-html-output (*standard-output* nil)
     (cl-who:htm (:select :class "form-control"  :name dropdown-name  
      (loop for prd in products
	 do (if (equal (slot-value prd 'subscribe-flag) "Y")  (cl-who:htm  (:option :value  (slot-value prd 'row-id) (cl-who:str (slot-value prd 'prd-name))))))))))

  
;; This is payment-mode dropdown
(defun  std-cust-payment-mode-dropdown (paymentmode)
  (cl-who:with-html-output (*standard-output* nil)
    (:select :class "form-control"  :name "payment-mode"
	     (if (equal paymentmode "PRE") 
		 (cl-who:htm (:option :value "PRE" (cl-who:str "Prepaid Wallet")))
		 (cl-who:htm (:option :value "COD" (cl-who:str "Cash On Delivery")))))))


;; This is payment-mode dropdown
(defun  guest-cust-payment-mode-dropdown (paymentmode)
  (cl-who:with-html-output (*standard-output* nil)
    (:select :class "form-control"  :name "payment-mode"
	     (if (equal paymentmode "OPY") 
		 (cl-who:htm (:option :value "OPY" (cl-who:str "Online Payment")))
		 (cl-who:htm (:option :value "COD" (cl-who:str "Cash On Delivery")))))))



;; This is customer/vendor  dropdown
(defun customer-vendor-dropdown ()
  (cl-who:with-html-output (*standard-output* nil)
     (cl-who:htm (:select :class "form-control" :id "reg-type"  :name "reg-type"
		   (:option    :value  "CUS" :selected "true"  (cl-who:str "Customer"))
		   (:option :value "VEN" (cl-who:str "Vendor"))))))



;; This is company/tenant name dropdown
(defun company-dropdown (name list)
  (cl-who:with-html-output (*standard-output* nil)
    (cl-who:htm (:select :class "form-control" :placeholder "Group/Apartment"  :name name 
	(loop for company in list 
	     do ( cl-who:htm (:option :value (slot-value company 'row-id) (cl-who:str (slot-value company 'name)))))))))

(defun dod-controller-low-wallet-balance-for-shopcart ()
  (with-cust-session-check
      (let* ((odts (hunchentoot:session-value :login-shopping-cart))
	     (vendor-list (get-shopcart-vendorlist odts))
	     (company (get-login-customer-company)) 
	     (wallets (mapcar (lambda (vendor) 
				(get-cust-wallet-by-vendor  (get-login-customer) vendor company)) vendor-list))
	     (order-items-totals (mapcar (lambda (vendor)
					   (get-order-items-total-for-vendor vendor odts)) vendor-list)))
	    	
	(with-standard-customer-page (:title "Low Wallet Balance")
	  (:div :class "row" 
		(:div :class "col-sm-12 col-xs-12 col-md-12 col-lg-12"
		      (:h3 (:span :class "label label-danger" "Low Wallet Balance."))))
	  (list-customer-low-wallet-balance   wallets order-items-totals)
	  (:a :class "btn btn-primary" :role "button" :href "dodcustshopcart" (:i :class "fa-solid fa-cart-shopping") "&nbsp;Modify Cart&nbsp;")))))


(defun dod-controller-low-wallet-balance-for-orderitems ()
  (with-cust-session-check
      (let* ((item-id (hunchentoot:parameter "item-id"))
	     (prd-qty (parse-integer (hunchentoot:parameter "prd-qty")))
	     (odts  (list (get-order-item-by-id item-id)))
	     (vendor-list (get-shopcart-vendorlist odts))
	     (company (get-login-customer-company)) 
	     (wallets (mapcar (lambda (vendor) 
				(get-cust-wallet-by-vendor  (get-login-customer) vendor company)) vendor-list))
	     (order-items-totals (mapcar (lambda (vendor)
					   (if prd-qty (setf (slot-value (first odts) 'prd-qty) prd-qty))
					   (get-order-items-total-for-vendor vendor odts)) vendor-list)))
	
	(with-standard-customer-page (:title "Low Wallet Balance")
	(:div :class "row" 
	      (:div :class "col-sm-12 col-xs-12 col-md-12 col-lg-12"
		    (:h3 (:span :class "label label-danger" "Low Wallet Balance."))))
	(list-customer-low-wallet-balance   wallets order-items-totals)))))


(defun dod-controller-cust-login-as-guest ()
  (let ((tenant-id (hunchentoot:parameter "tenant-id")))
    (unless  ( or (null tenant-id) (zerop (length tenant-id)))
      (if (equal (dod-cust-login-as-guest :tenant-id tenant-id) NIL) (hunchentoot:redirect "/hhub/customer-login.html") (hunchentoot:redirect  "/hhub/dodcustindex")))))

(defun dod-controller-cust-login ()
    (let  ( (phone (hunchentoot:parameter "phone"))
	   (password (hunchentoot:parameter "password")))
      (unless (and  ( or (null phone) (zerop (length phone)))
		    (or (null password) (zerop (length password))))
	    (if (equal (dod-cust-login  :phone phone :password password) NIL) (hunchentoot:redirect "/hhub/customer-login.html") (hunchentoot:redirect  "/hhub/dodcustindex")))))

(defun dod-controller-cust-ordersuccess ()
  (with-cust-session-check 
    (let ((cust-type  (slot-value (get-login-customer) 'cust-type)))
      (with-standard-customer-page
	 "Welcome to HighriseHub- Add Customer Order"
	(:div :class "row"
	      (:div :class "col-sm-12" 
		    (:h1 "Your order has been successfully placed")))
	(:div :class "row"
	      (:div :class "col-sm-4"
		    (:a :class "btn btn-primary" :role "button" :href "/hhub/dodcustindex" "Back To Shopping"  )))
	(:div :class "row"
	     (:div :class "col-sm-4" (:hr) ))
	(when (equal cust-type "STANDARD")
	  (cl-who:htm
	   (:div :class "row"
		 (:div :class "col-sm-6 col-xs-6 col-md-6 col-lg-6"
		       (:a :class "btn btn-primary" :role "button" :href (format nil "dodmyorders") " My Orders Page")))))))))
  
  
(defun send-order-email-guest-customer(order-id email temp-customer products shopcart) 
  (let* ((shopcart-total (get-shop-cart-total shopcart))
       	 (order-disp-str (create-order-email-content products shopcart temp-customer order-id shopcart-total)))
    (send-order-mail email (format nil "HighriseHub order ~A" order-id) order-disp-str)))

(defun send-order-sms-guest-customer (order-id phone)
  :documentation "Send an SMS to Guest customer when order is placed.")
;;(send-sms-notification phone "HIGHUB" (format nil "[HIGHRISEHUB] Thank You for placing the order. Your order number is ~A and will be processed soon" order-id)))
;; we are not sending any SMS to standard customer as of now for placing an order. This also will be based on settings on the company. Will need to register a SMS template for this. 

(defun send-order-sms-standard-customer(order-id phone)
  :documentation "Send an SMS to Guest customer when order is placed.")
;; (send-sms-notification phone "HIGHUB" (format nil "[HIGHRISEHUB] Thank You for placing the order. Your order number is ~A and will be processed soon" order-id)))
;; we are not sending any SMS to standard customer as of now for placing an order. This also will be based on settings on the company. Will need to register a SMS template for this. 

(defun send-order-email-standard-customer(order-id email products shopcart)
  :Documentation "We are not sending any email to standard customer Today. We will check his settings and then decide whether to send email or not. Future")

(defun check-all-vendors-wallet-balance(vendor-list wallet-list shopcart)
  :documentation "At least one vendor wallet has low balance, then return nil. Pure function."
  (unless (every #'(lambda (x) (if x T))
		 (mapcar (lambda (vendor wallet)
			   (check-wallet-balance (get-order-items-total-for-vendor vendor shopcart) wallet)) vendor-list wallet-list)) T))


(defun com-hhub-transaction-create-order ()
  (with-cust-session-check
    (let ((params nil))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (setf params (acons "company" (get-login-customer-company)  params))
      
      (with-hhub-transaction "com-hhub-transaction-create-order" params
	(multiple-value-bind (odts products odate reqdate ship-date shipaddress shipzipcode shipcity shipstate billaddress billzipcode billcity billstate billsameasshipchecked claimitcchecked gstnumber gstorgname shopcart-total comments cust custcomp order-cxt phone email custname payment-mode utrnum)
	    (values-list (get-cust-order-params)) 
	 (let* ((temp-ht (make-hash-table :test 'equal))
		(vendor-list (get-shopcart-vendorlist odts))
		(wallet-list (mapcar (lambda (vendor) (get-cust-wallet-by-vendor cust vendor custcomp)) vendor-list))
		(cust-type (slot-value cust 'cust-type))
		(temp-customer (hunchentoot:session-value :temp-guest-customer)))
	   	   
		;; This function call is not pure. Try to make it pure. 
		;; (guest-email (hunchentoot:session-value :guest-email-address)))

	   ;; If the payment mode is PREPAID, then check whether we have enough balance first. If not, then redirect to the low wallet balance. 
	   ;; Redirecting to some other place is not a pure function behavior. Is there a better way to handle this? 
	   (logiamhere (format nil "payment mode is ~A" payment-mode))
	   (setf (gethash "PRE" temp-ht) (symbol-function 'check-all-vendors-wallet-balance))
	   (let ((func (gethash payment-mode temp-ht)))
	     (if func (if (funcall (gethash payment-mode temp-ht) vendor-list wallet-list odts)	 (hunchentoot:redirect "/hhub/dodcustlowbalanceshopcarts"))))
	   ;; If everything gets through, create order. 
	   (let ((order-id (create-order-from-shopcart  odts products odate reqdate ship-date  shipaddress shopcart-total payment-mode comments cust custcomp temp-customer utrnum)))
	     (setf (gethash "GUEST-EMAIL" temp-ht) (symbol-function 'send-order-email-guest-customer))
	     (setf (gethash "GUEST-SMS" temp-ht) (symbol-function 'send-order-sms-guest-customer))
	     (setf (gethash "STANDARD-EMAIL" temp-ht) (symbol-function 'send-order-email-standard-customer))
	     (setf (gethash "STANDARD-SMS" temp-ht) (symbol-function 'send-order-sms-standard-customer))
	     
	       ;; Send order SMS to guest customer if phone is provided. (Phone is required field for Guest customer, hence SMS will always be sent)
	       (when (and (equal cust-type "GUEST") phone) (funcall (gethash (format nil "~A-SMS" cust-type) temp-ht) order-id  phone))
	       ;; Send order email to guest customer if email is provided. 
	       (when (and (equal cust-type "GUEST") (> (length email) 0))  (funcall (gethash (format nil "~A-EMAIL" cust-type) temp-ht) order-id email temp-customer  products odts))
	       ;; If STANDARD customer has email, then send order email 
	       (when (and (equal cust-type "STANDARD") (> (length email) 0)) (funcall (gethash (format nil "~A-EMAIL" cust-type) temp-ht) order-id email products odts))
	       ;; If standard customer has phone, then send SMS 
	       (when (and (equal cust-type "STANDARD") phone) (funcall (gethash (format nil "~A-SMS" cust-type) temp-ht) order-id phone))

	     
	     (reset-cust-order-params)
	     (setf (hunchentoot:session-value :login-cusord-cache) (get-orders-for-customer cust))
	     (setf (hunchentoot:session-value :login-shopping-cart ) nil)
	     (hunchentoot:redirect "/hhub/dodcustordsuccess"))))))))

(defun save-cust-order-params (list) 
  (setf (hunchentoot:session-value :customer-clipboard) list))

(defun get-cust-order-params()
  (hunchentoot:session-value :customer-clipboard))

(defun reset-cust-order-params()
  (setf (hunchentoot:session-value :customer-clipboard) nil))


(defun dod-controller-cust-add-order-otpstep ()
  (with-cust-session-check 
    (let* ((phone  (hunchentoot:parameter "phone"))
	   (context (hunchentoot:parameter "context"))
	   (paymentmode (hunchentoot:parameter "paymentmode"))
	   (cust-type (get-login-customer-type)))

      ;; Redirect to the OTP page only for Guest customer. 
      (if (equal cust-type "GUEST") (generateotp&redirect phone context paymentmode)
	  ;;else for standard customer, redirect to final checkout page. 
	  (hunchentoot:redirect (format nil "/hhub/~A?paymentmode=~A" context paymentmode))))))


      	

(defun dod-controller-cust-show-shopcart-readonly()
  (with-cust-session-check 
    (let* ((orderparams (get-cust-order-params)) 
	   (odts (nth 0 orderparams))
	   (shopcart-products (nth 1 orderparams))
	   (odate (nth 2 orderparams))
	   (reqdate (nth 3 orderparams)) 
	   (shipaddress (nth 5 orderparams))
	   (shipzipcode (nth 6 orderparams))
	   (shipcity (nth 7 orderparams))
	   (shipstate (nth 8 orderparams))
	   (billaddress (nth 9 orderparams))
	   (billzipcode (nth 10 orderparams))
	   (billcity (nth 11 orderparams))
	   (billstate (nth 12 orderparams))
	   (billsameasshipchecked (nth 13 orderparams))
	   (claimitcchecked (nth 14 orderparams))
	   (gstnumber (nth 15 orderparams))
	   (gstorgname (nth 16 orderparams))
	   (shopcart-total (nth 17 orderparams))
	   (payment-mode (hunchentoot:parameter "paymentmode"))
	   (utrnum (hunchentoot:parameter "utrnum"))
	   ;;(comments (nth 20 orderparams))
	   (phone  (nth 23 orderparams))
	   (email (nth 24 orderparams))
	   ;;(custname (nth 26 orderparams))
	   (customer (get-login-customer))
	   (custcomp (get-login-customer-company))
	   (cust-type (cust-type customer))
	   (order-cxt (format nil "hhubcustopy~A" (get-universal-time)))
	   (company-type (slot-value custcomp 'cmp-type))
	   (vendor-list (get-shopcart-vendorlist odts))
	   (wallet-id (slot-value (get-cust-wallet-by-vendor customer (first vendor-list) custcomp) 'row-id)))
      
      (logiamhere (format nil "orderparams length is ~d" (length orderparams)))
      ;; Add the payment mode to the order params. 
      (if payment-mode
	  (setf orderparams (append orderparams (list payment-mode)))
	  ;; else
	  (progn
	    (setf payment-mode "COD")
	    (setf orderparams (append orderparams (list payment-mode)))))
      ;; if payment is made using UPI, then add the utrnum to the order parameters
      (when utrnum
	(setf orderparams (append orderparams (list utrnum))))
      (logiamhere (format nil "now orderparams length is ~d" (length orderparams)))
    ;; Save the order params for further use. 
      (save-cust-order-params orderparams)
  
    (with-standard-customer-page "Shopping cart finalize"
      (:div :class "row"
	    (:div :class "col-xs-12"
		  (cl-who:str (format nil "Order Date: ~A" (get-date-string odate)))))
      (:div :class "row"
	    (:div :class "col-xs-12"
		  (cl-who:str (format nil "Request Date: ~A" (get-date-string reqdate)))))
      (:div :class "row"
	      (:div :class "col-xs-12"
		    (cl-who:str (format nil "Payment Mode: ~A" payment-mode))))
      
      (if (equal cust-type "GUEST") 
	  (cl-who:htm (:div :class "row"
			    (:div :class "col-xs-12"
				  (:h4 (cl-who:str (format nil "Phone: ~A" phone)))))
		    ;;If email is given by the guest customer during shopping
		      (when (> (length email) 0)
			(cl-who:htm (:div :class "row"
					  (:div :class "col-xs-12"
						(cl-who:str (format nil "Email: ~A" email))))))
		      ;; Shipping address
		      (:div :class "row"
			    (:div :class "col-xs-12"
				    (cl-who:str (format nil "Shipping Address: ~A, ~A, ~A, ~A" shipaddress shipcity shipstate shipzipcode))))
		      
		      ;; billing address
		      (when (not billsameasshipchecked)
			(cl-who:htm
			 (:div :class "row"
			       (:div :class "col-xs-12"
				     (cl-who:str (format nil "Billing Address: ~A, ~A, ~A, ~A" billaddress billcity billstate billzipcode))))))
		    
		      
		      ;; GST Number and Organization
		      (when (and claimitcchecked (> (length gstnumber) 0))
			(cl-who:htm
			 (:div :class "row"
			       (:div :class "col-xs-12"
				     (cl-who:str (format nil "GST Number: ~A/" gstnumber))
				     (cl-who:str (format nil "GST Organization: ~A" gstorgname))))))))
      
      (:div :class "row"
	    (:div :class "col-xs-12"
		(:h2 (:span :class "label label-default" (cl-who:str (format nil "Total = Rs ~$" shopcart-total))))))
      (:div :class "row"
	    (:div :class "col-xs-12"
		  (cond
		    ((and (equal payment-mode "OPY") (or (equal company-type "COMMUNITY")
							 (equal company-type "BASIC")
							 (equal company-type "PROFESSIONAL")))
		     (cl-who:str (make-payment-request-html (format nil "~A" shopcart-total)   (format nil "~A" wallet-id) "live" order-cxt)))
		    ((and (equal payment-mode "OPY")
			  (equal company-type "TRIAL"))
		     (cl-who:str (make-payment-request-html (format nil "~A" shopcart-total)   (format nil "~A" wallet-id) "test" order-cxt)))
		    (T (with-html-form "placeorderform" "dodmyorderaddaction"  
			 (:span :class "input-group-btn" (:button :class "btn btn-lg btn-primary" :type "submit" "Place Order" )))))))
      (:hr)
    (:div :class "row"
	  (cl-who:str(ui-list-shopcart-readonly shopcart-products odts)))
      (:hr)))))




			   
; This is a pure function. 
(defun get-order-items-total-for-vendor (vendor order-items) 
 (let ((vendor-id (slot-value vendor 'row-id)))
  (reduce #'+ (remove nil (mapcar (lambda (item) (if (equal vendor-id (slot-value item 'vendor-id)) 
					 (* (slot-value item 'unit-price) (slot-value item 'prd-qty)))) order-items)))))

(defun get-opref-items-total-for-vendor (vendor opref-items) 
 (let ((vendor-id (slot-value vendor 'row-id)))
  (reduce #'+ (remove nil (mapcar (lambda (item) 
				    (let* ((product (get-opf-product item))
				    (vendor (product-vendor product)))
				      (if (equal vendor-id (slot-value vendor 'row-id))
					 (* (slot-value product 'unit-price) (slot-value item 'prd-qty))))) opref-items)))))


(defun filter-order-items-by-vendor (vendor order-items)
  (let ((vendor-id (slot-value vendor 'row-id)))
	(remove nil (mapcar (lambda (item) (if (equal vendor-id (slot-value item 'vendor-id)) item)) order-items))))

(defun filter-opref-items-by-vendor (vendor opref-items)
  (let ((vendor-id (slot-value vendor 'row-id)))
	(remove nil (mapcar (lambda (item) 
			      (let* ((product (get-opf-product item))
				    (vendor (product-vendor product)))
			      (if (equal vendor-id (slot-value vendor 'row-id)) item))) opref-items))))


(defun get-shop-cart-total (odts)
  (let* ((total (reduce #'+  (mapcar (lambda (odt)
	  (* (slot-value odt 'unit-price) (slot-value odt 'prd-qty))) odts))))
    total ))
	
;This is a pure function without any side effects.
(defun get-shopcart-vendorlist (shopcart-items)
(remove-duplicates  (mapcar (lambda (odt) 
	   (select-vendor-by-id (slot-value odt 'vendor-id)))  shopcart-items)
:test #'equal
:key (lambda (vendor) (slot-value vendor 'row-id)))) 

(defun get-opref-vendorlist (opreflist) 
  (remove-duplicates (mapcar (lambda (opref) 
			       (let ((product (get-opf-product opref))) 
				 (product-vendor product))) opreflist) 
		     :test #'equal
		     :key (lambda (vendor) (slot-value vendor 'row-id))))

(defun dod-controller-cust-update-cart ()
    :documentation "update the shopping cart by modifying the product quantity"
    (with-cust-session-check
	(let* ((prd-id (hunchentoot:parameter "prd-id"))
		 (prd-qty (hunchentoot:parameter "nprdqty"))
		 (myshopcart (hunchentoot:session-value :login-shopping-cart))
		 (odt (if myshopcart (search-odt-by-prd-id  (parse-integer prd-id)  myshopcart ))))
	    (progn  ;(remove odt  myshopcart)
		(setf (slot-value odt 'prd-qty) (parse-integer prd-qty))
		;(setf (hunchentoot:session-value :login-shopping-cart) (append (list odt)  myshopcart  ))
		(hunchentoot:redirect "/hhub/dodcustshopcart")))
	))
		 
(defun dod-controller-create-cust-wallet ()
  :documentation "If the customer wallet is not defined, then define it now"
  (let ((vendor (select-vendor-by-id (hunchentoot:parameter "vendor-id"))))
    (if vendor (create-wallet (get-login-customer) vendor (get-login-customer-company)))
    (if vendor (hunchentoot:log-message* :info "Created wallet for vendor ~A" (slot-value vendor 'name)))
    (hunchentoot:redirect (format nil "/hhub/dodcustindex"))))

(defun dod-controller-cust-add-to-cart ()
    :documentation "This function is responsible for adding the product and product quantity to the shopping cart."
    (with-cust-session-check
	(let* ((prd-id (hunchentoot:parameter "prd-id"))
	       (prdqty (parse-integer (hunchentoot:parameter "prdqty")))
	       (productlist (hunchentoot:session-value :login-prd-cache))
		  (myshopcart (hunchentoot:session-value :login-shopping-cart))
		  (product (search-prd-in-list (parse-integer prd-id) productlist))
		  (vendor (product-vendor product))
		  (vendor-id (slot-value vendor 'row-id))
		  (wallet (get-cust-wallet-by-vendor (get-login-customer) vendor (get-login-customer-company)))
		  (odt (create-odtinst-shopcart nil product  prdqty (slot-value product 'unit-price) (hunchentoot:session-value :login-customer-company))))
	  (if (and wallet (> prdqty 0)) 
	      (progn (setf (hunchentoot:session-value :login-shopping-cart) (append myshopcart (list odt)))
		     "success")
	      ;;xb(if (length (hunchentoot:session-value :login-shopping-cart)) (hunchentoot:redirect (format nil "/hhub/dodcustindex"))))
	      ;else if wallet is not defined, create wallet first
	      (hunchentoot:redirect (format nil "/hhub/createcustwallet?vendor-id=~A" vendor-id))))
	))



(defun dod-controller-prd-details-for-guest-customer ()
  (let* ((parambase64 (hunchentoot:parameter "key"))
	 (param-csv (cl-base64:base64-string-to-string (hunchentoot:url-decode parambase64)))
	 (paramslist (first (cl-csv:read-csv param-csv
				  :skip-first-p T
				  :map-fn #'(lambda (row)
					      row))))
	 (tenant-id (nth 0 paramslist))
	 (prd-id (nth 1 paramslist)))
    
    ;; login as guest customer. 
    (dod-cust-login-as-guest :tenant-id tenant-id :session-time-limit 300)
    (let* ((lstshopcart (hunchentoot:session-value :login-shopping-cart))
	   (company (hunchentoot:session-value :login-customer-company)))
      (with-cust-session-check
	(with-standard-customer-page "Product Details"
	  (product-card-with-details-for-customer (select-product-by-id prd-id company) (prdinlist-p prd-id lstshopcart)))))))

    
      
	   

(defun dod-controller-prd-details-for-customer ()
   (with-cust-session-check 
	(with-standard-customer-page "Product Details"
	    (let* ((company (hunchentoot:session-value :login-customer-company))
		   (lstshopcart (hunchentoot:session-value :login-shopping-cart))
		   (product (select-product-by-id (parse-integer (hunchentoot:parameter "id")) company)))
	      (product-card-with-details-for-customer product (prdinlist-p (slot-value product 'row-id)  lstshopcart))))))

(defun dod-controller-cust-index () 
 (with-cust-session-check
   (let* ((lstshopcart (hunchentoot:session-value :login-shopping-cart))
	  (lstcount (length lstshopcart))
	  (lstprodcatg (hunchentoot:session-value :login-prdcatg-cache))
	  (lstproducts (hunchentoot:session-value :login-prd-cache))
	  (prdcount (length lstproducts))
	  (first100products (if (> prdcount 100) (subseq lstproducts 0 100))))
     ;;(sleep 5)
     (with-standard-customer-page "Welcome to HighriseHub - customer"
       
       (:form :id "theForm" :name "theForm" :method "POST" :action "dodsearchproducts" :onSubmit "return false"
	      (:div :class "container" 
		    (:div :class "col-lg-6 col-md-6 col-sm-6" 
			  (:div :class "input-group"
				(:input :type "text" :name "livesearch" :id "livesearch"  :class "form-control" :placeholder "Search products...")
				(:span :class "input-group-btn" (:button :class "btn btn-primary" :type "submit" "Go!" ))))
					; Display the My Cart button. 
		    (:div :class "col-lg-6 col-md-6 col-sm-6" :align "right"
			  (:a :class "btn btn-primary" :role "button" :href "dodcustshopcart"  (:i :class "fa-solid fa-cart-shopping")  (:span :class "badge" (cl-who:str (format nil " ~A " lstcount)))))))
       (:hr)
       (:a :id "floatingcheckoutbutton" :href "dodcustshopcart" :style "font-weight: bold; font-size: 25px !important;"  (:i :class "fa-solid fa-cart-shopping") "&nbsp;&nbsp;Checkout&nbsp;&nbsp;"  (:span :class "badge" (cl-who:str (format nil " ~A " lstcount))))
       (cl-who:str (ui-list-prod-catg lstprodcatg))
       (:hr)
       (if (> prdcount 100)
	   (cl-who:str (ui-list-customer-products first100products lstshopcart))
	   ;;else
	   (cl-who:str (ui-list-customer-products lstproducts lstshopcart)))))))


(defun dod-controller-customer-products-by-category ()
  :documentation "This function lists the customer products by category"
  (with-cust-session-check
    (let* ((catg-id (parse-integer (hunchentoot:parameter "id")))
	   (lstshopcart (hunchentoot:session-value :login-shopping-cart))
	   (lstproducts (hunchentoot:session-value :login-prd-cache))
	   (lstprodbycatg (if lstproducts (filter-products-by-category catg-id lstproducts))))
      (with-standard-customer-page "Products By Category."
	(cl-who:htm
	 (:div :class "row"
	       (:div :class "col-md-12" :align "right"
		     (:a :class "btn btn-primary" :role "button" :href "dodcustshopcart" (:i :class "fa-solid fa-cart-shopping") (:span :class "badge" (cl-who:str (format nil " ~A " (length lstshopcart)))))))
	 (:hr))		       
	(cl-who:str (ui-list-customer-products lstprodbycatg lstshopcart))))))


(defun dod-controller-cust-show-shopcart ()
    :documentation "This is a function to display the shopping cart."
    (with-cust-session-check 
	(let* ((lstshopcart (hunchentoot:session-value :login-shopping-cart))
	       (lstcount (length lstshopcart))
	       (prd-cache (hunchentoot:session-value :login-prd-cache))
	       (total  (get-shop-cart-total lstshopcart))
	       (products (mapcar (lambda (odt)
				   (let ((prd-id (slot-value odt 'prd-id)))
				     (search-prd-in-list prd-id prd-cache ))) lstshopcart)))
	  (if (> lstcount 0)
	      (with-standard-customer-page "My Shopping Cart"
	    				; Need to select the order details instance here instead of product instance. Also, ui-list-shop-cart should be based on order details instances. 
					; This function is responsible for displaying the shopping cart. 

		(:div :class "row"
		      (:div :class "col-xs-6" 
			    (:h4 (cl-who:str (format nil "Shopping Cart (~A Items)" (length products)))))
		      (:div :class "col-sm-6" :align "right"
			    (cl-who:htm  (:a :class "btn btn-primary" :role "button" :href "/hhub/dodcustindex" "Back To Shopping"  ))))
		(:hr)
		
		(:div :class "rowfluid"
		      (:div :class "col-xs-12" 
			    (cl-who:str (ui-list-shopcart products lstshopcart))))
		(:hr)
	  (:div :class "row" 
		(:div :class "col-xs-12" :align "right" 
		      (:h2 (:span :class "label label-default" (cl-who:str (format nil "Total = Rs ~$" total))))))
		(:hr)
		(:div :class "row"
		      (:div :class "col-xs-12" :align "right"
			    (:a :class "btn btn-primary" :role "button" :href (format nil "dodcustorderaddpage") "Checkout"))))
	      ;; else
	      (show-empty-shopping-cart)))))
   

(defun show-empty-shopping-cart ()
  (with-standard-customer-page-v2  "My Shopping Cart"
    (with-html-div-row
      (with-html-div-col 
	(:h4 "0 items in shopping cart") 
	(:a :class "btn btn-primary" :onclick "window.history.back();"  :role "button" :href "#" (:i :class "fa-solid fa-arrow-left"))))))


(defun dod-controller-remove-shopcart-item ()
    :documentation "This is a function to remove an item from shopping cart."
    (with-cust-session-check
      (let ((action (hunchentoot:parameter "action"))
	    (prd-id (parse-integer (hunchentoot:parameter "id")))
	    (myshopcart (hunchentoot:session-value :login-shopping-cart)))
	(progn (if (equal action "remitem" ) (setf (hunchentoot:session-value :login-shopping-cart) (remove (search-odt-by-prd-id  prd-id  myshopcart  ) myshopcart)))
	       (hunchentoot:redirect  "/hhub/dodcustshopcart")))))


(defun dod-cust-login-as-guest (&key tenant-id (session-time-limit 600))
   (handler-case 
	;expression
       (let* ((customer (car (clsql:select 'dod-cust-profile :where [and
			      [= [:phone] "9999999999"]
			      [= [:cust-type] "GUEST"]
			      [= [:tenant-id] tenant-id]
			      [= [:deleted-state] "N"]]
			      :caching nil :flatp t :database *dod-db-instance* )))
	      (customer-id (if customer (slot-value customer 'row-id)))
	      (customer-name (if customer (slot-value customer 'name)))
	      (customer-company (if customer (customer-company customer)))
	      (customer-tenant-id (if customer-company (slot-value customer-company 'row-id)))
	      (customer-company-name (if customer-company (slot-value customer-company 'name)))
	      (customer-company-website (if customer-company (slot-value customer-company 'website)))
	      (customer-type (if customer (slot-value customer 'cust-type)))
	      (login-shopping-cart '()))

	 (when (and customer
		    (null (hunchentoot:session-value :login-customer-name))) ;; customer should not be logged-in in the first place.
	   (progn
	     (hunchentoot:log-message* :info "Login successful for customer  ~A" customer-name)
	     (hunchentoot:start-session)
	     (setf hunchentoot:*session-max-time* session-time-limit)
	     (setf (hunchentoot:session-value :login-customer ) customer)
	     (setf (hunchentoot:session-value :login-customer-name) customer-name)
	     (setf (hunchentoot:session-value :login-customer-id) customer-id)
	     (setf (hunchentoot:session-value :login-customer-type) customer-type)
	     (setf (hunchentoot:session-value :login-customer-tenant-id) customer-tenant-id)
	     (setf (hunchentoot:session-value :login-customer-company-name) customer-company-name)
	     (setf (hunchentoot:session-value :login-customer-company-website) customer-company-website)
	     (setf (hunchentoot:session-value :login-customer-company) customer-company)
	     (setf (hunchentoot:session-value :login-shopping-cart) login-shopping-cart)
	     ;; There is no need for daily order preference, orders since this is a guest user. 
	     ;; (setf (hunchentoot:session-value :login-cusopf-cache) (get-opreflist-for-customer  customer)) 
	     ;; There is no need to set the orders for customer as it is a guest customer. 
	     ;;(setf (hunchentoot:session-value :login-cusord-cache) (get-orders-for-customer customer))
	     (setf (hunchentoot:session-value :login-prd-cache )  (select-products-by-company customer-company))
	     (setf (hunchentoot:session-value :login-prdcatg-cache) (select-prdcatg-by-company customer-company))
	     (unless (equal customer-tenant-id *HHUB-DEMO-TENANT-ID*)
	       (progn
		 (hunchentoot:set-cookie "community-url" :value (format nil "https://www.highrisehub.com/hhub/dascustloginasguest?tenant-id=~A" (get-login-cust-tenant-id)) :expires (+ (get-universal-time) 10000000) :path "/")
		 (hunchentoot:set-cookie "community-name" :value customer-company-name :path "/" :expires (+ (get-universal-time) 10000000)))))))
     
     ;; Handle this condition
     (clsql:sql-database-data-error (condition)
       (if (equal (clsql:sql-error-error-id condition) 2013 )
	   (progn
	     (stop-das) 
	     (start-das)
	     ;; (clsql:reconnect :database *dod-db-instance*)
	     (hunchentoot:redirect "/hhub/customer-login.html"))))))
    

(defun dod-cust-login (&key phone password)
  (handler-case 
					;expression
      
      (let* ((customer (car (clsql:select 'dod-cust-profile :where [and
					  [= [:phone] phone]
					  [= [:cust-type] "STANDARD"]
					  [= [:deleted-state] "N"]]
					  :caching nil :flatp t :database *dod-db-instance* )))
	     (pwd (if customer (slot-value customer 'password)))
	     (salt (if customer (slot-value customer 'salt)))
	     (password-verified (if customer  (check-password password salt pwd)))
	     (customer-id (if customer (slot-value customer 'row-id)))
	     (customer-name (if customer (slot-value customer 'name)))
	     (customer-company (if customer (customer-company customer)))
	     (customer-tenant-id (if customer-company (slot-value customer-company 'row-id)))
	     (customer-company-name (if customer-company (slot-value customer-company 'name)))
	     (customer-company-website (if customer-company (slot-value customer-company 'website)))
	     (customer-type (if customer (slot-value customer 'cust-type)))
	     (login-shopping-cart '()))

      (when (and customer
		 password-verified
		 (null (hunchentoot:session-value :login-customer-name))) ;; customer should not be logged-in in the first place.
	(progn
	  (hunchentoot:log-message* :info "Login successful for customer  ~A" customer-name)
	  (hunchentoot:start-session)
	  (setf hunchentoot:*session-max-time* (* 3600 8))
	  (setf (hunchentoot:session-value :login-customer ) customer)
	  (setf (hunchentoot:session-value :login-customer-name) customer-name)
	  (setf (hunchentoot:session-value :login-customer-id) customer-id)
	  (setf (hunchentoot:session-value :login-customer-type) customer-type)
	  (setf (hunchentoot:session-value :login-customer-tenant-id) customer-tenant-id)
	  (setf (hunchentoot:session-value :login-customer-company-name) customer-company-name)
	  (setf (hunchentoot:session-value :login-customer-company-website) customer-company-website)
	  (setf (hunchentoot:session-value :login-customer-company) customer-company)
	  (setf (hunchentoot:session-value :login-shopping-cart) login-shopping-cart)
	  (setf (hunchentoot:session-value :login-cusopf-cache) (get-opreflist-for-customer  customer)) 
	  (setf (hunchentoot:session-value :login-prd-cache )  (select-products-by-company customer-company))
	  (setf (hunchentoot:session-value :login-prdcatg-cache) (select-prdcatg-by-company customer-company))
	  (setf (hunchentoot:session-value :login-cusord-cache) (get-orders-for-customer customer))
	  (hunchentoot:set-cookie "community-url" :value (format nil "https://www.highrisehub.com/hhub/dascustloginasguest?tenant-id=~A" (get-login-cust-tenant-id)) :expires (+ (get-universal-time) 10000000) :path "/")
	  ))
      )

        ; Handle this condition
   
      (clsql:sql-database-data-error (condition)
	  (if (equal (clsql:sql-error-error-id condition) 2006 ) (progn
								   (stop-das) 
								   (start-das)
;								   (clsql:reconnect :database *dod-db-instance*)
								   (hunchentoot:redirect "/hhub/customer-login.html"))))))
 ;     (clsql:sql-fatal-error (errorinst) (if (equal (clsql:sql-error-database-message errorinst) "Database is closed.") 
;					     (progn (clsql:stop-sql-recording :type :both)
;					            (clsql:disconnect) 
;						    (crm-db-connect :servername *crm-database-server* :strdb *crm-database-name* :strusr *crm-database-user*  :strpwd *crm-database-password* :strdbtype :mysql)
;(hunchentoot:redirect "/hhub/customer-login.html"))))))
      








