;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(defun display-products-carousel (numitems products)
 (let ((prdcount (length products)))
  (cl-who:with-html-output (*standard-output* nil)      
    (:section :class "carousel-container" :id "carousel-container"
	      (:div :class "carousel-wrapper"
		    (:div :class "hhubcarousel"
			  (loop for i from 1 to numitems do 
			    (let* ((k (random prdcount))
				   (prd (nth k products))
				   (prd-id (slot-value prd 'row-id))
				   (image (slot-value prd 'prd-image-path)))
			      (cl-who:htm
			       (:a :href (format nil "/hhub/prddetailsforcust?id=~A" prd-id) :style "display: contents;" (:img :id (format nil "slide~d" i) :src image))))))
		    (:div :class "hhubcarousel-nav"
			  (loop for i from 1 to numitems  do
			    (cl-who:htm
			     (:a :class "carousel-slide" :id (format nil "slidelink~A" i)  :href (format nil "#slide~A" i)))))))
    (:hr))))

(defun display-prdcatg-carousel (numitems categories)
  (let ((catgcount (length categories)))
    (cl-who:with-html-output (*standard-output* nil)      
      (:section :class "carousel-container" :id "carousel-container"
		(:div :class "carousel-wrapper"
		      (:div :class "hhubcarousel"
			    (loop for i from 1 to numitems do 
			      (let* ((k (random catgcount))
				     (catg (nth k categories))
				     (catg-id (slot-value catg 'row-id))
				     (catg-name (slot-value catg 'catg-name)))
				     ;;(image (slot-value catg 'catg-image-path)))
				(cl-who:htm
				 (:a :href (format nil "/hhub/dodproductsbycatg?id=~A" catg-id) :style "display: contents;" (:img :id (format nil "slide~d" i) :src "" :alt catg-name))))))
		      (:div :class "hhubcarousel-nav"
			    (loop for i from 1 to numitems  do
			      (cl-who:htm
			       (:a :class "carousel-slide" :id (format nil "slidelink~A" i)  :href (format nil "#slide~A" i))))))))))
    


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


;; This is a pure function.

(defun display-cust-shipping-costs-widget (shopcart-total shipping-options storepickupenabled vendor freeshipenabled)
  :description "The display-cust-shipping-costs-widget function generates an HTML widget for displaying shipping costs, allowing users to choose between shipping or store pickup. It dynamically updates cost information and visibility based on user interactions"
  (let* ((vaddress (address vendor))
         (vcity (city vendor))
         (vzipcode (zipcode vendor))
         (phone (phone vendor))
         (vshipping-enabled (slot-value vendor 'shipping-enabled))
         (shipping-cost (nth 0 shipping-options))
         (freeshipminorderamt (nth 2 shipping-options)))

    (cl-who:with-html-output (*standard-output* nil)
      (when (and (equal vshipping-enabled "Y") (equal storepickupenabled "Y") (> shipping-cost 0))
        (cl-who:htm
         (:div :class "custom-control custom-switch"
               (:input :type "checkbox" :class "custom-control-input" :id "idstorepickup" :name "storepickup" :value "Y"
                       :onclick (parenscript:ps (togglepickupinstore)) :tabindex "1")
               (:label :class "custom-control-label" :for "idstorepickup" "Pickup In Store"))))
      (with-html-div-row :id "costwithshipping" :class "shipping-cost-section"
        (with-html-div-col-8
          (cond ((and (equal vshipping-enabled "Y") (> shipping-cost 0))
                 (cl-who:htm
                  (:br)
                  (:p :class "cost-item" (cl-who:str (format nil "Cost of Items: ~A ~$" *HTMLRUPEESYMBOL* shopcart-total)))
                  (:p :class "cost-item" (cl-who:str (format nil "Shipping Charges: ~A ~$" *HTMLRUPEESYMBOL* shipping-cost)))
                  (:hr)
                  (:p :id "costwithshipping" :class "total-cost"
                      (:h3 :style "color: green;" 
                           (:span :class "text-bg-success" 
                                    (cl-who:str (format nil "Total: ~A ~$" *HTMLRUPEESYMBOL*  (+ shopcart-total shipping-cost))))))
                  (:p :class "info-message"
                      (if (equal freeshipenabled "Y") (cl-who:str (format nil "Shop for ~A ~$ more and we will ship it FREE!" *HTMLRUPEESYMBOL* (- freeshipminorderamt shopcart-total)))))))
                
                ((and (equal vshipping-enabled "Y") (= shipping-cost 0))
                 (cl-who:htm (:p :class "info-message" (cl-who:str "Shipping: FREE!"))))
                
                ((equal vshipping-enabled "N")
                 (cl-who:htm (:p "Please pick up your items from our store")
                             (:p :class "location-info" 
                                 (cl-who:str (format nil "Address: ~A, ~A, ~A" vaddress vcity vzipcode)))
                             (:p :class "location-info" (cl-who:str (format nil "Phone: ~A" phone))))))))
      
      (with-html-div-row :id "costwithoutshipping" :style "display: none;" :class "shipping-cost-section"
        (with-html-div-col-8
          (:br)
          (:p :class "cost-item" (cl-who:str (format nil "Cost of Items: ~A ~$" *HTMLRUPEESYMBOL* shopcart-total)))
          (:p :class "cost-item" (cl-who:str (format nil "Shipping Charges: ~A ~$" *HTMLRUPEESYMBOL* 0.00)))
          (:hr)
          (:p :id "costwithoutshipping" :class "total-cost"
              (:h3 :style "color: green;" 
                   (:span :class "text-bg-success" 
                          (cl-who:str (format nil "Total: ~A ~$" *HTMLRUPEESYMBOL*  shopcart-total)))))
          (:hr)))
      
      (:script "function togglepickupinstore () {
                      const storepickup = document.getElementById('idstorepickup');
                      if( storepickup.checked ){
                          $('#costwithoutshipping').show();
                          $('#costwithshipping').hide();
                      }else
                      {
                          $('#costwithoutshipping').hide();
                          $('#costwithshipping').show();
                      }
                  }"))))


(defun dod-controller-customer-payment-methods-page ()
  (with-cust-session-check
    (with-mvc-ui-page "Customer Payment Methods" createmodelforcustomerpaymentmethodspage createwidgetsforcustomerpaymentmethodspage :role :customer)))


(defun createwidgetsforcustomerpaymentmethodspage (modelfunc)
  (multiple-value-bind
	(cust-type lstcount vendor-list customer custcomp singlevendor-p vpayapikey-p vupiid-p phone codenabled upienabled payprovidersenabled walletenabled paylaterenabled)
      (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (with-customer-breadcrumb
		       (:li :class "breadcrumb-item" (:a :href "dodcustshopcart" "Cart"))
		       (:li :class "breadcrumb-item" (:a :href "dodcustorderaddpage" "Address"))))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)  
		       (with-html-div-row
			 (with-html-div-col
			    (:h5 :class "text-center"  "Choose Payment Method")))))))
	  (widget3 (function (lambda ()
		     (if (> lstcount 0)
			 (custpaymentmethods
			  (function (lambda ()
			    (values cust-type vendor-list customer custcomp phone singlevendor-p vpayapikey-p vupiid-p codenabled upienabled payprovidersenabled walletenabled paylaterenabled)))))))))
      (list widget1 widget2 widget3))))


(defun createmodelforcustomerpaymentmethodspage ()
  (let* ((lstshopcart (hunchentoot:session-value :login-shopping-cart))
	 (lstcount (length lstshopcart))
	 (cust-type (get-login-customer-type))
	 (vendor-list (get-shopcart-vendorlist lstshopcart))
	 (singlevendor-p (if (= (length vendor-list) 1) T NIL))
	 (singlevendor (first vendor-list))
	 (vendoraddress (slot-value singlevendor 'address))
	 (customer (get-login-customer))
	 (custcomp (get-login-customer-company))
	 ;;(wallet-balance (slot-value (get-cust-wallet-by-vendor customer (first vendor-list) custcomp) 'balance))
	 (storepickup (hunchentoot:parameter "storepickup"))
	 (orderparams-ht (get-cust-order-params)) 
	 (phone (gethash "phone" orderparams-ht))
	 (vpayapikey-p (if singlevendor-p (when (slot-value singlevendor 'payment-api-key) t)))
	 (vupiid-p (if singlevendor-p (when (slot-value singlevendor 'upi-id) t)))
	 (adapter (make-instance 'VPaymentMethodsAdapter))
	 (requestmodel (make-instance 'VPaymentMethodsRequestModel
				      :company custcomp
				      :vendor singlevendor))
	 (vpaymentmethods (processreadrequest adapter requestmodel)))
    
    (when (and storepickup (equal storepickup "Y"))
      (setf (gethash "shipping-cost" orderparams-ht) 0.00)
      (setf (gethash "storepickupenabled" orderparams-ht) "Y")
      (setf (gethash "vendoraddress" orderparams-ht) vendoraddress)
      (save-cust-order-params orderparams-ht)) 
    ;; create a list of all the required data points or create a model and return it. 
    (lambda ()
      (with-slots (codenabled upienabled payprovidersenabled walletenabled paylaterenabled) vpaymentmethods
	(values cust-type lstcount vendor-list customer custcomp singlevendor-p vpayapikey-p vupiid-p phone codenabled upienabled payprovidersenabled walletenabled paylaterenabled)))))



(defun create-prepaid-wallet-widget (customer cust-type vendor-list custcomp walletenabled)
  (lambda ()
    (let ((itembodyhtml
	    (cl-who:with-html-output (*standard-output* nil)
	      (:li :class "list-group-item"  
	      (when (and (equal cust-type "STANDARD") (equal walletenabled "Y"))
		(cl-who:htm
		 (with-html-div-row
		   (with-html-div-col
		     (:h5 (:u "Prepaid Wallet Balance"))))
		 (mapcar (lambda (vendor)
			   (let* ((wallet (get-cust-wallet-by-vendor customer vendor custcomp))
				  (wallet-balance (slot-value wallet 'balance))
				  (vendorname (slot-value vendor 'name)))
			     (cl-who:htm
			      (with-html-div-row
				(with-html-div-col
				  (:h6 (cl-who:str (format nil "Vendor - ~A" vendorname))))
				(with-html-div-col
				  (:span  :style "color:blue" (cl-who:str (format nil "~d" wallet-balance)))))))) vendor-list)
		 
		 (with-html-form "form-standardcustpaymentmode" "dodcustshopcartro"
		   (with-html-input-text-hidden "paymentmode" "PRE")
		   (:input :type "submit"  :class "btn btn-primary" :value "Prepaid Checkout"))))))))
      (values itembodyhtml))))

(defun create-cash-on-delivery-widget (cust-type phone codenabled)
  (lambda ()
    (let ((itembodyhtml 
	    (cl-who:with-html-output (*standard-output* nil)
	      (:li :class "list-group-item"  
	      ;; We need to give a link for GUEST customers and button for standard customers. This is a bad design to be fixed later.
	      (when (and (equal cust-type "GUEST") (equal codenabled "Y"))
		(cl-who:htm
		 (:a :class "btn btn-primary"  :role "button" :href (format nil "dodcustshopcartotpstep?context=dodcustshopcartro&phone=~A" phone) "Cash On Delivery")))
	      (when (and (equal cust-type "STANDARD") (equal codenabled "Y"))
		(cl-who:htm
		 (:div :id "idstdcustcodcontainer" :class "list-group col-sm-6 col-md-6 col-lg-6 col-xs-12"
		       (with-html-form "form-standardcustpaymentmode" "dodcustshopcartotpstep"
			 (with-html-input-text-hidden "paymentmode" "COD")
			 (with-html-input-text-hidden "context" "dodcustshopcartro")
			 (with-html-input-text-hidden "phone" phone)
			 (:input :type "submit"  :class "btn btn-primary" :value "Cash On Delivery")))))))))
      (values itembodyhtml))))
  

(defun create-upi-payment-widget (vupiid-p upienabled)
  (lambda ()
    (let ((itembodyhtml
	    (cl-who:with-html-output (*standard-output* nil)
	      (:li :class "list-group-item"    
		   (when (and vupiid-p (equal upienabled "Y")) 
		     (cl-who:htm
		      (:div :class "list-group col-sm-6 col-md-6 col-lg-6 col-xs-12"
			    (with-html-form "form-standardcustpaymentmode" "hhubcustupipage"
			      (with-html-input-text-hidden "paymentmode" "UPI")
			      (:input :type "submit"  :class "btn btn-primary" :value "UPI Payment")))))))))
      (values itembodyhtml))))
  

(defun create-payment-gateway-widget (singlevendor-p vpayapikey-p payprovidersenabled)
  (lambda ()
    (let ((itembodyhtml
	    (cl-who:with-html-output (*standard-output* nil)
	      (:li :class "list-group-item"  
		   (when (and (equal payprovidersenabled "Y")
			      singlevendor-p vpayapikey-p)
		     (cl-who:htm
		      (:div :class "list-group col-sm-6 col-md-6 col-lg-6 col-xs-12"
			    (with-html-form "form-standardcustpaymentmode" "dodcustshopcartro"
			      (with-html-input-text-hidden "paymentmode" "OPY")
			      (:input :type "submit"  :class "btn btn-primary" :value "Payment Gateway")))))))))
	  (values itembodyhtml))))
  

;; This is not a pure function as it talks to the database.  
(defun custpaymentmethods (vpmsettingsfunc)
  (multiple-value-bind (cust-type vendor-list customer custcomp phone singlevendor-p vpayapikey-p vupiid-p codenabled upienabled payprovidersenabled walletenabled ) (funcall vpmsettingsfunc)
    (let ((widget1 (create-prepaid-wallet-widget customer cust-type vendor-list custcomp walletenabled)) 
	  (widget2 (create-cash-on-delivery-widget cust-type phone codenabled))
	  (widget3 (create-upi-payment-widget vupiid-p upienabled))
	  (widget4 (create-payment-gateway-widget singlevendor-p vpayapikey-p payprovidersenabled)))
      (cl-who:with-html-output (*standard-output*)
        (:ul :class "list-group"
             (mapcar #'funcall (list widget1 widget2 widget3 widget4)))))))



(defun accordion-example1 ()
  (let ((itembodyhtml 
	  (cl-who:with-html-output (*standard-output* nil)
	    (:h2 "Testing Testing")
	    (:strong "This is strong text. This is strong text")))
	(id "idaccordionexample1")
	(buttontext "Strong Text"))
    (values id buttontext itembodyhtml)))

(defun accordion-example2 ()
  (let ((itembodyhtml 
	  (cl-who:with-html-output (*standard-output* nil)
	    (:h2 "Testing Testing")
	    (:strong "This is strong text. This is strong text")))
	(id "idaccordionexample2")
	(buttontext "Strong Text"))
    (values id buttontext itembodyhtml)))

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


;; This is a pure function
(defun modal.customer-update-details (customer)
  (let* ((name (name customer))
	 (address (address customer))
	 (phone  (phone customer))
	 (zipcode (zipcode customer))
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
		       (:input :class "form-control" :name "zipcode"  :value zipcode :placeholder "Pincode"  :type "text" ))
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
	   (zipcode (hunchentoot:parameter "zipcode"))
	   (email (hunchentoot:parameter "email")))
      (setf (slot-value customer 'name) name)
      (setf (slot-value customer 'address) address)
      (setf (slot-value customer 'phone) phone)
      (setf (slot-value customer 'zipcode) zipcode)
      (setf (slot-value customer 'email) email)
      (update-customer customer)
      (hunchentoot:redirect "/hhub/dodcustprofile"))))

      
(defun modal.customer-change-pin ()
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-div-row
      (with-html-div-col
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
	   (salt (createciphersalt))
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

;;;;;;;;;;;;;;;; CUSTOMER PROFILE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun createwidgetsfordisplaycustomerproile (modelfunc)
  (multiple-value-bind (customername customer-instance) (funcall modelfunc)
      (let ((widget1 (function (lambda ()
		       (cl-who:with-html-output (*standard-output* nil)
			 (:h3 "Welcome " (cl-who:str (format nil "~a" customername)))
			 (:hr)
			 (:div :class "list-group col-sm-6 col-md-6 col-lg-6 col-xs-12"
			       (:a :class "list-group-item" :data-bs-toggle "modal" :data-bs-target (format nil "#dodcustupdate-modal")  :href "#"  "Contact Info")
			       (modal-dialog-v2 (format nil "dodcustupdate-modal") "Update Customer" (modal.customer-update-details customer-instance)) 
			       ;; We have OTP based login now, so will not support changing password by customer.
			       ;;(:a :class "list-group-item" :data-bs-toggle "modal" :data-bs-target (format nil "#dodcustchangepin-modal")  :href "#"  "Change Password")
			       ;;(modal-dialog-v2 (format nil "dodcustchangepin-modal") "Change Password" (modal.customer-change-pin)) 
			       ;;(:a :class "list-group-item" :href "#" "Settings")
			       (:a :class "list-group-item" :href *HHUBFEATURESWISHLISTURL*  "Feature Wishlist")
			       (:a :class "list-group-item" :href *HHUBBUGSURL* "Report Issues")))))))
	(list widget1))))

(defun createmodelfordisplaycustomerproile ()
  (function (lambda ()
    (values (get-login-cust-name) (get-login-customer)))))

(defun dod-controller-customer-profile ()
  (with-cust-session-check
    (with-mvc-ui-page "Customer Profile" createmodelfordisplaycustomerproile createwidgetsfordisplaycustomerproile :role :customer)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun get-login-customer ()
    :documentation "get the login session for customer"
    (hunchentoot:session-value :login-customer ))

(defun get-login-customer-id ()
  :documentation "get login customer id"
  (hunchentoot:session-value :login-customer-id))


(defun get-login-cust-company ()
    :documentation "get the login customer company."
    (hunchentoot:session-value :login-customer-company))

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
    (when hunchentoot:*session* (hunchentoot:remove-session hunchentoot:*session*))
    (if (> (length company-website) 0) (hunchentoot:redirect (format nil "http://~A" company-website)) 
	;; else
	(hunchentoot:redirect *siteurl*))))

(defun dod-controller-guest-customer-logout ()
  (when hunchentoot:*session* (hunchentoot:remove-session hunchentoot:*session*))
  (hunchentoot:redirect "/hhub/customer-login.html"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; das-cust-page-with-tiles;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun das-cust-page-with-tiles (displayfunc pagetitle &rest args)
  :documentation "this is a standard higher order function which takes the display function as argument and displays the information"
  (with-cust-session-check
    (with-standard-customer-page (:title pagetitle) 
      (apply displayfunc args))))

(defun dod-controller-cust-wallet-display ()
  :documentation "a callback function which displays the wallets for a customer" 
  (with-cust-session-check
    (with-mvc-ui-page "Customer Wallets" createmodelforcustwalletdisplay createwidgetsforcustwalletdisplay :role :customer)))    
  

(defun createmodelforcustwalletdisplay ()
  (let* ((company (hunchentoot:session-value :login-customer-company))
	 (customer (hunchentoot:session-value :login-customer))
	 (header (list "Vendor" "Phone" "Balance" "Recharge"))
	 (wallets (get-cust-wallets customer company)))
    (function (lambda ()
      (values header wallets)))))
 
(defun createwidgetsforcustwalletdisplay (modelfunc)
  (multiple-value-bind (header wallets) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (cl-who:str (display-as-table header wallets 'cust-wallet-as-row)))))))
      (list widget1))))

;; This is a pure function. 
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
		      (cl-who:htm (:div :class "col-sm-6 " (:h4 (:span :class "label label-warning" (cl-who:str (format nil "~A ~$ - low balance. please recharge the  wallet." *HTMLRUPEESYMBOL* balance))))))
					;else
		      (cl-who:htm (:div :class "col-sm-3"  (:h4 (:span :class "label label-info" (cl-who:str (format nil "balance: ~A. ~$" *HTMLRUPEESYMBOL*  balance))))))))
	    (:div :class "row"
		  (:form :class "cust-wallet-recharge-form" :method "post" :action "dodsearchcustwalletaction"
			 (:input :class "form-control" :name "phone" :type "hidden" :value (cl-who:str (format nil "~a" (slot-value customer 'phone))))
			 (:div :class "col-sm-3" (:div :class "form-group"
						       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "recharge")))))
	    (:div :class "row"
		  (:div :class "col-sm-6"  (:h3  (cl-who:str (format nil " ~a " custom-message)))))))))



;; This is a pure function. 
(defun cust-wallet-as-row (wallet &rest arguments)
  (declare (ignore arguments))
  (let* ((vendor (slot-value wallet 'vendor))
	 (balance (slot-value wallet 'balance))
	 (wallet-id (slot-value wallet 'row-id))
	 (lowbalancep (if (check-low-wallet-balance wallet) t nil)))
    (cl-who:with-html-output (*standard-output* nil)
 	  (:td  :height "10px" (cl-who:str (slot-value vendor  'name)))
	  (:td  :height "10px" (cl-who:str (slot-value vendor  'phone)))
	  
	  (if lowbalancep
	      (cl-who:htm (:td :height "10px" (:h4 (:span :class "label label-danger" (cl-who:str (format nil "~A ~$ " *HTMLRUPEESYMBOL* balance))))))
					;else
	      (cl-who:htm (:td :height "10px" (cl-who:str (format nil "Rs. ~$ " balance)))))
      (:td :height "10px" 
	   (:a  :class "btn btn-primary" :role "button"  :href (format nil "/hhub/hhubcustwalletrechargepage?amount=1000.00&wallet-id=~A" wallet-id)  "1000"))
					; Recharge 1500 
      (:td :height "10px"
	   (:a  :class "btn btn-primary" :role "button"  :href (format nil "/hhub/hhubcustwalletrechargepage?amount=2000.00&wallet-id=~A" wallet-id) "2000")))))

;; This is a pure function. 
(defun list-customer-low-wallet-balance (wallets order-items-totals)
  (let ((header (list "Vendor" "Phone" "Balance" "Order Items Total"  "Recharge")))
    (cl-who:with-html-output (*standard-output* nil)
      (:h3 "My Wallets.")      
      (:table :class "table table-striped"
	      (:thead (:tr
		       (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) header))) 
	      (:tbody
	       (mapcar (lambda (wallet order-item-total)
			 (let* ((vendor (slot-value wallet 'vendor))
				(balance (slot-value wallet 'balance))
				(wallet-id (slot-value wallet 'row-id))
				(lowbalancep (or (if (check-low-wallet-balance wallet) t nil)
						 (< balance order-item-total))))
			   (cl-who:htm (:tr
					(:td  :height "12px" (cl-who:str (slot-value vendor  'name)))
					(:td  :height "12px" (cl-who:str (slot-value vendor  'phone)))
					
					(if lowbalancep
					    (cl-who:htm (:td :height "12px" (:h4 (:span :class "label label-danger" (cl-who:str (format nil "~A ~$ " *HTMLRUPEESYMBOL*  balance))))))
					;else
					    (cl-who:htm (:td :height "12px" (cl-who:str (format nil "~A ~$ " *HTMLRUPEESYMBOL* balance)))))
					
					(:td :height "12px" (cl-who:str (format nil "~A ~$ " *HTMLRUPEESYMBOL* order-item-total)))
					
					(:td :height "10px" 
					     (:a  :class "btn btn-primary" :role "button"  :href (format nil "/hhub/hhubcustwalletrechargepage?amount=1000.00&wallet-id=~A" wallet-id)  "1000"))
					(:td :height "10px" 
					     (:a  :class "btn btn-primary" :role "button"  :href (format nil "/hhub/hhubcustwalletrechargepage?amount=2000.00&wallet-id=~A" wallet-id)  "2000")))))) wallets order-items-totals))))))





(defun createmodelforcustdeleteordersubscription ()
  (let ((ordpref-id (parse-integer (hunchentoot:parameter "id")))
	(cust (hunchentoot:session-value :login-customer))
	(company (hunchentoot:session-value :login-customer-company))
	(redirectlocation "/hhub/dodcustorderprefs"))
    
    (delete-opref (get-opref-by-id ordpref-id company))
    (setf (hunchentoot:session-value :login-cusopf-cache) (get-opreflist-for-customer cust))
    (function (lambda ()
      (values redirectlocation)))))


(defun createwidgetsforcustdeleteordersubscription (modelfunc)
  (multiple-value-bind (redirectlocation) (funcall modelfunc)
    (let ((widget1 (function (lambda () redirectlocation))))
      (list widget1))))

(defun dod-controller-cust-del-orderpref-action ()
    :documentation "delete order preference"
  (with-cust-session-check
    (let ((uri (with-mvc-redirect-ui createmodelforcustdeleteordersubscription createwidgetsforcustdeleteordersubscription)))
      (format nil "~A" uri))))

(defun createmodelforcustorders ()
  (let ((dodorders (hunchentoot:session-value :login-cusord-cache))
	(header (list  "Order #" "Order Date" "Request Date"  "Actions")))
    (function (lambda ()
      (values dodorders header)))))
    
(defun createwidgetsforcustorders (modelfunc)
  (multiple-value-bind (dodorders header) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (:br)
		       (:ul :class "nav nav-pills" 
			    (:li  :class "nav-item" (:a :class "nav-link active" :href "dodmyorders" (:i :class "fa-solid fa-list")))
			    (:li  :class "nav-item" (:a :class "nav-link" :href "dodcustorderscal" (:i :class "fa-regular fa-calendar-days")))
			    (:li  :class "nav-item" (:a :class "nav-link" :href "dodcustindex" "Shop Now")))
		       (:br)))))
	  (widget2 (function (lambda ()
		     (if dodorders (ui-list-customer-orders header dodorders) "No Orders")))))
      (list widget1 widget2))))


(defun dod-controller-my-orders ()
    :documentation "a callback function which prints orders for a logged in customer in html format."
  (with-cust-session-check
    (with-mvc-ui-page "Customer Orders" createmodelforcustorders createwidgetsforcustorders :role :customer)))

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
    (with-standard-customer-page-v2  "list dod customer orders"   
      (:link :href "/css/calendar.css" :rel "stylesheet")
      (:ul :class "nav nav-pills" 
	   (:li :class "nav-item" (:a :class "nav-link" :href "dodmyorders" (:span :class "fa-solid fa-list")))
	   (:li :class "nav-item" (:a :class "nav-link active" :href "dodcustorderscal" (:span :class "fa-regular fa-calendar-days")))
	   (:li :class "nav-item" (:a :class "nav-link" :href "dodcustindex" "Shop Now")))
      (:br)
      (:div :class "container"
	    (:div :class "page-header"
		  (:div :class "form-inline" :style "justify-content: end;"
			(:div :style "padding: 0.5rem" (:h3))
			(:div :class "btn-group" 
			      (:button :class "btn btn-primary" :data-calendar-nav "prev" "<< Prev")
			      (:button :class "btn btn-default" :data-calendar-nav "today" "Today")
			      (:button :class "btn btn-primary" :data-calendar-nav "next" "Next >>"))
			
			))
	    (:div :class "row"
		  (:div :id "calendar")))
      
      ;;(modal-dialog-v2 (format nil "events-modal") "Calendar Modal" )
      
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
	(hunchentoot:redirect "/hhub/dodmyorders"))))

(defun modal.vendor-details (id) 
  (let ((vendor (select-vendor-by-id id)))  
    (vendor-details-card vendor)))


(defun createmodelfordeletecustorditem ()
  (let* ((order-id (parse-integer (hunchentoot:parameter "ord")))
	 (redirectlocation (format nil "/hhub/hhubcustmyorderdetails?id=~a" order-id))
	 (item-id (parse-integer (hunchentoot:parameter "id")))
	 (company (hunchentoot:session-value :login-customer-company))
	 (order (get-order-by-id order-id company)))
    ;; delete the order item. 
    (delete-order-items (list item-id) company)
    ;; get the new order items list and find out the total. update the order with this new amount.
    (let* ((odtlst (get-order-items order))
	   (vendors (get-vendors-by-orderid order-id company))
	   (custordertotal (if odtlst (reduce #'+ (mapcar (lambda (odt) (* (slot-value odt 'prd-qty) (slot-value odt 'current-price))) odtlst )) 0))) 
      ;; for each vendor, delete vendor-order if the order items total for that vendor is 0. 
      (mapcar (lambda (vendor) 
		(let ((vendororder (get-vendor-orders-by-orderid order-id vendor company))
		      (vendorordertotal (get-order-items-total-for-vendor vendor odtlst)))
		  (if (equal vendorordertotal 0)
		      (delete-order vendororder)))) vendors)
      (setf (slot-value order 'order-amt) (coerce custordertotal 'float))
      (update-order order)
      (if (equal custordertotal 0) 
	  (delete-order order))
      ;;(sleep 1) 
      (setf (hunchentoot:session-value :login-cusord-cache) (get-orders-for-customer (get-login-customer)))) 
    (function (lambda ()
      (values redirectlocation)))))

(defun createwidgetsfordeletecustorditem (modelfunc)
  (multiple-value-bind (redirectlocation) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     redirectlocation))))
      (list widget1))))

(defun dod-controller-del-cust-ord-item ()
  (with-cust-session-check
    (let ((uri (with-mvc-redirect-ui createmodelfordeletecustorditem createwidgetsfordeletecustorditem)))
      (format nil "~A" uri))))

(defun  customer-my-order-details (order-id)
  (let* ((dodorder (get-order-by-id order-id (get-login-cust-company)))
	 (header (list "Status" "Action" "Name" "Qty"   "Sub-total" ))
	 (odtlst (get-order-items dodorder))
	 (shipping-cost (slot-value dodorder 'shipping-cost))
	 (order-amt (slot-value dodorder 'order-amt))
	 (total (if shipping-cost (+ order-amt shipping-cost) order-amt)))
    (cl-who:with-html-output (*standard-output* nil)
      (if odtlst (ui-list-cust-orderdetails header odtlst) "No Order Details")
      (with-html-div-row
	(:div :class "col" :align "right"
	      (:p (cl-who:str (format nil "Sub Total = ~A ~$" *HTMLRUPEESYMBOL* order-amt)))))  
      (with-html-div-row
	(with-html-div-col "")
	(when shipping-cost
	  (cl-who:htm
	   (:div :class "col" :align "right"
		 (:p (cl-who:str (format nil "Shipping = ~A ~$" *HTMLRUPEESYMBOL* shipping-cost)))))))
      (:div :class "row" 
	    (:div :class "col-md-12" :align "right" 
		  (:h2 (:span :class "label label-default" (cl-who:str (format nil "Total = ~A ~$" *HTMLRUPEESYMBOL* total))))))
      (display-order-header-for-customer  dodorder))))



(defun createmodelforcustmyorderdetails ()
  (let* ((order-id (parse-integer (hunchentoot:parameter "id")))
	 (dodorder (get-order-by-id order-id (get-login-cust-company)))
	 (header (list "Status" "Action" "Name" "Qty"   "Sub-total" ))
	 (odtlst (get-order-items dodorder))
	 (shipping-cost (slot-value dodorder 'shipping-cost))
	 (order-amt (slot-value dodorder 'order-amt))
	 (storepickupenabled (slot-value dodorder 'storepickupenabled))
	 (total (if shipping-cost (+ order-amt shipping-cost) order-amt)))

    (function (lambda ()
      (values odtlst header order-amt shipping-cost total  dodorder storepickupenabled)))))


(defun createwidgetsforcustmyorderdetails (modelfunc)
  (multiple-value-bind (odtlst header order-amt shipping-cost total dodorder storepickupenabled) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (if odtlst (ui-list-cust-orderdetails header odtlst) "No Order Details")))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-html-div-row
			 (:div :class "col" :align "right"
			       (:p (cl-who:str (format nil "Sub Total = ~A ~$" *HTMLRUPEESYMBOL* order-amt)))))  
		       (with-html-div-row
			 (with-html-div-col "")
			 (when shipping-cost
			   (cl-who:htm
			    (:div :class "col" :align "right"
				  (:p (cl-who:str (format nil "Shipping = ~A ~$" *HTMLRUPEESYMBOL* shipping-cost)))))))
		       (:div :class "row" 
			     (:div :class "col-md-12" :align "right" 
				   (:h2 (:span :class "label label-default" (cl-who:str (format nil "Total = ~A ~$" *HTMLRUPEESYMBOL* total))))))
		       (if (equal storepickupenabled "Y") (cl-who:htm (:div :class "stampbox rotated" (:strong (cl-who:str "Store Pickup")))))))))
	  (widget3 (function (lambda ()
		     (display-order-header-for-customer  dodorder)))))
      (list widget1 widget2 widget3))))

(defun hhub-controller-customer-my-orderdetails ()
  (with-cust-session-check
    (with-mvc-ui-page "Customer My Order Details" createmodelforcustmyorderdetails createwidgetsforcustmyorderdetails :role :customer)))

(defun cretemodelforsearchproducts ()
  (let* ((search-clause (hunchentoot:parameter "prdlivesearch"))
	 (products (if (not (equal "" search-clause)) (search-products search-clause (get-login-cust-company))))
	 (shoppingcart (hunchentoot:session-value :login-shopping-cart)))
    (function (lambda ()
      (values products shoppingcart)))))

(defun createwidgetsforsearchproducts (modelfunc)
  (multiple-value-bind (products shoppingcart) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
		       (:div :id "prdlivesearchresult" 
			     (render-products-list products shoppingcart)))))))
      
      (list widget1))))
		     
(defun dod-controller-search-products ()
  (let* ((modelfunc (cretemodelforsearchproducts))
	 (widgets (createwidgetsforsearchproducts modelfunc)))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (loop for widget in widgets do
	(cl-who:str (funcall widget))))))

(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defun with-customer-navigation-bar ()
    :documentation "this macro returns the html text for generating a navigation bar using bootstrap."
    (let ((customer-type (get-login-customer-type)))
       (cl-who:with-html-output (*standard-output* nil)
	 (:div :class "navbar navbar-inverse  navbar-static-top" :id "hhubcustnavbar"
	     (:div :class "container-fluid"
		   (:div :class "navbar-header"
			 (:button :type "button" :class "navbar-toggle" :data-toggle "collapse" :data-target "#navheadercollapse"
				  (:span :class "icon-bar")
				  (:span :class "icon-bar")
				  (:span :class "icon-bar"))
			 (:a :class "navbar-brand" :href *siteurl* :title "Nine Stores" (:img :style "width: 30px; height: 24px;" :src "/img/logo.png" )))
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
    (let* ((customer-type (get-login-customer-type))
	   (company (get-login-customer-company))
	   (subs-plan (subscription-plan company))
	   (cmp-type (cmp-type company)))
       (cl-who:with-html-output (*standard-output* nil)
	 (:nav :class "navbar navbar-expand-sm  sticky-top navbar-dark bg-dark" :id "hhubcustnavbar"  
	       (:div :class "container-fluid"
		     (:a :class "navbar-brand" :href "/hhub/dodcustindex" (:img :style "width: 30px; height: 24px;" :src "/img/logo.png" ))
		     (:button :class "navbar-toggler" :type "button" :data-bs-toggle "collapse" :data-bs-target "#navbarSupportedContent" :aria-controls "navbarSupportedContent" :aria-expanded "false" :aria-label "Toggle navigation" 
			      (:span :class "navbar-toggler-icon" ))
		     (:div :class "collapse navbar-collapse justify-content-between" :id "navbarSupportedContent"
			   (:ul :class "navbar-nav me-auto mb-2 mb-lg-0" 
				(:li :class "nav-item" 	
				     (:a :class "nav-link active" :aria-current "page" :href "/hhub/dodcustindex" (:i :class "fa-solid fa-house") "&nbsp;Home"))
				(if (and (com-hhub-attribute-company-prdsubs-enabled subs-plan cmp-type) (equal customer-type "STANDARD"))
				    (cl-who:htm (:li :class "nav-item"  (:a :class "nav-link" :href "dodcustorderprefs" "Subscriptions"))))
				(if (equal customer-type "STANDARD")
				    (cl-who:htm (:li :class "nav-item"  (:a :class "nav-link" :href "dodcustorderscal" "Orders"))))
				(if (and (com-hhub-attribute-company-wallets-enabled subs-plan cmp-type) (equal customer-type "STANDARD"))
				    (cl-who:htm (:li :class "nav-item"  (:a :class "nav-link" :href "dodcustwallet" (:i :class "fa-solid fa-wallet")  "&nbsp;Wallets" ))))
				(:li :class "nav-item"  (:a :class "nav-link" :href "#" (cl-who:str (format nil "~a" (get-login-customer-company-name))))))


				(:ul :class "navbar-nav ms-auto"
				     (if (equal customer-type "STANDARD")
					 (cl-who:htm
					  (:li :class "nav-item"  (:a :class "nav-link" :href "#"  (:i :class "fa-regular fa-bell")))
					  (:li :class "nav-item"  (:a :class "nav-link" :href "dodcustprofile"  (:i :class "fa-regular fa-user")))))
				     
				     ;;(:li :class "nav-item"
					;;  (:div :class "form-check form-switch"
					;;	(:input :class "form-check-input" :type "checkbox" :id "darkModeSwitch" :checked "checked")
					;;	(:label :class "form-check-label" :for "darkModeSwitch" "Dark Mode")))

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
			 (:a :class "navbar-brand" :href "#" :title "Nine Stores" (:img :style "width: 50px; height: 50px;" :src "/img/logo.png" )  ))
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
    (with-no-navbar-page-v2 "Welcome to Nine Stores Platform."
      	(:form :class "form-custregister" :role "form" :data-toggle "validator"  :method "POST" :action "custsignup1step2"
	   (:div :class "row"
		 (:img :class "profile-img" :src "/img/logo.png" :alt "")
		 (:h1 :class "text-center login-title"  (cl-who:str (format nil "New Registration to ~A Store" cmpname)))
		 (:hr)) 
	   (with-html-div-row
	     (with-html-div-col-8
	     (:div :class "form-group"
		   (:input :class "form-control" :name "tenant-name" :value (format nil "~A" cname) :type "text" :readonly T ))
	     (:div :class "form-group" 
		   (:textarea :class "form-control" :name "address"   :rows "2" :readonly T (cl-who:str (format nil "~A" cmpaddress))))
	     
	     (:div  :class "form-group" (:label :for "reg-type" "Register as:" )
		    (customer-vendor-dropdown))
	     
	     (:div :class "form-group"
		   (:input :class "form-control" :name "name" :placeholder "Full Name (Required)" :type "text" :required T ))
	     (:div :class "form-group"
		   (:input :class "form-control" :name "email" :placeholder "Email (Required)" :type "text" :required T ))
	     (:div :class "form-group"
		   (:input :class "form-control" :name "phone" :placeholder "Your Mobile Number (Required)" :type "text" :required T))
	     (:div :class "form-group"
		   (:div :class "g-recaptcha" :data-sitekey *HHUBRECAPTCHAV2KEY* )
		   (:div :class "form-group"
			 (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))
      (hhub-html-page-footer))))



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
	 ;; We are not getting initial password from the customer or vendor as we have moved to OTP based authentication.
	 ;; Customer & vendor passwords will still remain part of the system which can be used for impersonation. 
	 ;;(password (hunchentoot:parameter "password"))
	 ;;(confirmpass (hunchentoot:parameter "confirmpass"))
	 ;;(salt (createciphersalt))
	 ;;(encryptedpass (check&encrypt password confirmpass salt))
	 (tenant-name (hunchentoot:parameter "tenant-name"))
	 (company (select-company-by-name tenant-name))
	 (tenant-id (slot-value company 'row-id))
	 (context "dodcustregisteraction"))
    
    ;; Start a new session 
    (hunchentoot:start-session)
    ;; Keep the session for 5 mins only. 
    (setf hunchentoot:*session-max-time* (* 60 5))
    
    (cond
      ;;((null encryptedpass) (dod-response-passwords-do-not-match-error))
      ;; Check for duplicate customer
      ((and (equal reg-type "CUS") (duplicate-customerp phone company)) (hunchentoot:redirect "/hhub/duplicate-cust.html"))
      ;; Check whether captcha has been solved 
      ((null (cdr (car json-response))) (dod-response-captcha-error))
     
      ((equal reg-type "VEN")
       (let ((vendor (make-instance 'dod-vend-profile
				    :name name
				    :address fulladdress
				    :email email 
				    :phone phone
				    :city nil 
				    :state nil 
				    :zipcode nil
				    :approved-flag "N"
				    :active-flag "Y"
				    :approval-status "PENDING"
				    :tenant-id tenant-id
				    :push-notify-subs-flag "N"
				    :deleted-state "N")))
	 (setf (hunchentoot:session-value :newvendorcreate) vendor)))
      ((equal reg-type "CUS")
       (let ((customer (make-instance 'dod-cust-profile
				      :name name
				      :address fulladdress
				      :email email 
				      :birthdate nil 
				      :phone phone
				      :city nil
				      :state nil
				      :zipcode nil
				      :approved-flag "N"
				      :active-flag "Y"
				      :approval-status "PENDING"
				      :tenant-id tenant-id
				      :cust-type "STANDARD"
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
	    (create-free-shipping-method *HHUBFREESHIPMINORDERAMT*  vendor company)
	    ;;3
	    (send-registration-email name email))
				    ;;4
	 (with-no-navbar-page "Welcome to Nine Stores platform"
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
	 (with-no-navbar-page "Welcome to Nine Stores platform"
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
     (with-standard-customer-page (:title "Welcome to Nine Stores platform")
	 (:h3 (cl-who:str(format nil "Customer record has already been created" )))
	 (:a :href "cust-register.html" "Register new customer")))

(defun dod-controller-company-search-action ()
  (let*  ((qrystr (hunchentoot:parameter "accountlivesearch"))
	  (company-list (if (not (equal "" qrystr)) (select-companies-by-name qrystr))))
    (ui-list-companies company-list)))

(defun dod-controller-company-search-page ()
  (handler-case
      (progn  (if (equal (caar (clsql:query "select 1" :flatp nil :field-names nil :database *dod-db-instance*)) 1) T)	      
	      (with-no-navbar-page-v2 "Welcome to Nine Stores platform" 
		(:br)
		(:h2 "Store Search.")
		(:div :id "custom-search-input"
		      (with-html-search-form "idcompanysearch" "companysearch" "idaccountlivesearch" "accountlivesearch"  "companysearchaction" "onkeyupsearchform1event();" "Enter Store Name..."
			(submitsearchform1event-js "#idaccountlivesearch" "#accountlivesearchresult" )))
		(:div :id "accountlivesearchresult")
		(:hr)
		(with-html-div-row
		  (with-html-div-col
		    (:a :class "order-box"  :href "hhubnewcommstorerequest?cmp-type=COMMUNITY"  "Store Not Found? Create New Public Store For Your Pincode - FREE!"))
		  (with-html-div-col :style "display: none;"
		    (:a :class "order-box"  :href "pricing"  "New Grocery, Mobile, Apparel, Electronics Store.")))
		(:hr)
		;; whenever one or more than one search forms are used, remember to call the searchformevent-js function. 
		(hhub-html-page-footer)))
    
    (clsql:sql-database-data-error (condition)
      (when (equal (clsql:sql-error-error-id condition) 2006 )
	(stop-das) 
	(start-das)))))


(defun dod-controller-customer-password-reset-action ()
  (let* ((pwdresettoken (hunchentoot:parameter "token"))
	 (rstpassinst (get-reset-password-instance-by-token pwdresettoken))
	 (user-type (if rstpassinst (slot-value rstpassinst 'user-type)))
	 (password (hunchentoot:parameter "password"))
	 (newpassword (hunchentoot:parameter "newpassword"))
	 (confirmpassword (hunchentoot:parameter "confirmpassword"))
	 (salt (createciphersalt))
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
	    (with-standard-customer-page-v2 "Welcome Customer"
	      (with-html-div-row
		(with-html-div-col-12
		    (with-html-card "/img/logo.png" "" "Customer Login" ""
		      (:form :class "form-custsignin" :role "form" :method "POST" :action "dodcustlogin" :data-toggle "validator"
			     (:div :class "form-group"
				   (:input :class "form-control" :name "phone" :placeholder "Enter RMN. Ex: 9999999999" :type "number" :required "true" ))
			     (:div :class "form-group"
				   (:input :class "form-control" :name "password" :placeholder "password=Welcome1" :type "password"  :required "true" ))
			     (:div :class "form-group"
				   (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Login")))
		      (:a :data-toggle "modal" :data-target (format nil "#dascustforgotpass-modal")  :href "#"  "Forgot Password?")
		      (modal-dialog-v2 (format nil "dascustforgotpass-modal") "Forgot Password?" (modal.customer-forgot-password))
		      (hhub-html-page-footer)))))))
	
    (clsql:sql-database-data-error (condition)
      (if (equal (clsql:sql-error-error-id condition) 2013 ) (progn
							       (stop-das) 
							       (start-das)
							       (hunchentoot:redirect "/hhub/customer-login.html"))))))


(defun dod-controller-customer-otploginpage ()
  (handler-case 
      (progn  
	(if (equal (caar (clsql:query "select 1" :flatp nil :field-names nil :database *dod-db-instance*)) 1) T)      
	(if (is-dod-cust-session-valid?)
	    (hunchentoot:redirect "/hhub/dodcustindex")
	    (with-standard-customer-page-v2 "Welcome Customer" 
	      (with-html-div-row
		(with-html-div-col-12
		  (with-html-card "/img/logo.png" "" "Customer Login" ""
		    (with-html-form  "form-custsignin" "hhubcustloginotpstep" :data-toggle "validator"
		      (:div :class "form-group"
			    (:input :class "form-control" :name "phone" :placeholder "Enter RMN. Ex: 9999999999" :type "number" :required "true" ))
		      (:div :class "form-group"
			    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Get OTP")))
	      (hhub-html-page-footer)))))))
	(clsql:sql-database-data-error (condition)
				       (if (equal (clsql:sql-error-error-id condition) 2013 ) (progn
												(stop-das) 
												(start-das)
												(hunchentoot:redirect "/hhub/customer-login.html"))))))

(defun is-dod-cust-session-valid? ()
  (if hunchentoot:*session* T NIL))

;; This is pure function. 
(defun product-qty-add-html (product product-pricing)
  (let* ((prd-id (slot-value product 'row-id))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (prd-name (slot-value product 'prd-name)))
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-form  (format nil "form-addproduct")  "dodcustaddtocart" 
      (:input :type "hidden" :name "prd-id" :value (format nil "~A" prd-id))
      (:p :class "product-name"  (cl-who:str prd-name))
      (:a :href (format nil "prddetailsforcust?id=~A" prd-id) (render-single-product-image prd-name imageslst images-str "100" "83"))
      (product-price-with-discount-widget product product-pricing)
      ;; Qty increment and decrement control.
      (html-range-control "prdqty" prd-id "1" (max (mod units-in-stock 20) 10) "1" "1")
      (:div :class "form-group" 
	    (:input :type "submit"  :class "btn btn-primary" :value "Add To Cart"))))))

;; This is a pure function. 
(defun product-qty-edit-html (product oitem)
  (let* ((prd-id (slot-value product 'row-id))
	 (prd-image-path (slot-value product 'prd-image-path))
	 (description (slot-value product 'description))
	 (current-price (slot-value product 'current-price))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (prd-name (slot-value product 'prd-name))
	 (itemqty (slot-value oitem 'prd-qty)))
    (cl-who:with-html-output (*standard-output* nil)
      (:form :class "form-editproduct" :id (format nil "format-editproduct~A" prd-id) :method "POST" :action "dodcustupdatecart"
	     (:input :type "hidden" :name "prd-id" :value (format nil "~A" prd-id))
	     (:p :class "product-name"  (cl-who:str prd-name))
	     (:a :href (format nil "prddetailsforcust?id=~A" prd-id) 
		 (:img :src  (format nil "~A" prd-image-path) :height "83" :width "100" :alt prd-name " "))
	     (:p (:span :class "label label-info" (cl-who:str (format nil "Rs. ~$ / ~A"  current-price qty-per-unit))))
	     (:p (cl-who:str (if (> (length description) 150)  (subseq description  0 150) description)))
	     ;; Qty increment and decrement control.
	     (html-range-control "prdqty"  prd-id "1" (max (mod units-in-stock 20) 10) itemqty "1")
	     (:div :class "form-group" 
		   (:input :type "submit"  :class "btn btn-primary" :value "Update"))))))


(defun product-subscribe-html (prd-id) 
  (let* ((productlist (hunchentoot:session-value :login-prd-cache))
	 (product (search-item-in-list 'row-id prd-id  productlist))
	 (prd-image-path (slot-value product 'prd-image-path))
	 (prd-id (slot-value product 'row-id))
	 (prd-name (slot-value product 'prd-name))
	 (upbtn (format nil "up_~A" prd-id))
	 (downbtn (format nil "down_~A" prd-id)))
    
 (cl-who:with-html-output (*standard-output* nil)
   (:div :align "center" :class "row account-wall" 
	 (:div :class "col-sm-12  col-xs-12 col-md-12 col-lg-12"
	       (:div  :class "row" 
		     (:div  :class "col-xs-12" 
			     (:a :href (format nil "prddetailsforcust?id=~A" prd-id) 
				 (:img :src  (format nil "~A" prd-image-path) :height "83" :width "100" :alt prd-name " "))))
			(:form :class "form-oprefadd" :role "form" :method "POST" :action "dodcustaddopfaction"
			    (:div :class "form-group row"  
			          (:input :type "hidden" :id (format nil "product-id~A" prd-id) :name "product-id" :value (format nil "~a" (slot-value product 'row-id))))
				 ; (products-dropdown "product-id"  (hunchentoot:session-value :login-prd-cache)))
				 
				 ;(:div :class "inputQty"
				  ;     (:span :class "up" "up" )
				   ;    (:input :type "text" :maxlength "6" :name "oa_quantity" :class "input-quantity"  :value "1")
				    ;   (:span :class "down" "down"))
				 (:div  :class "inputQty row" 
			     (:div :class "col-xs-4"
				   (:a :class "down btn btn-primary" :id downbtn :onClick "minusbtnclick(this.id);" :href "#" (:i :class "fa-solid fa-minus"))) 
			     (:div :class "form-group col-xs-4" 
				   (:input :class "form-control input-quantity" :readonly "true"  :name "prdqty" :id (format nil "prdqtyfor_~A" prd-id)  :value "1"  :min "1" :max 10  :type "number"))
			     (:div :class "col-xs-4"
				   (:a :class "up btn btn-primary" :id upbtn :onClick "plusbtnclick(this.id);" :href "#" (:span :class "fa-solid fa-plus"))))
				  
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
			    (:input :type "submit"  :class "btn btn-primary" :value "Subscribe"))))))))
			    



;;;;;;; Add order page for Standard customer ;;;;;;;;;;;;
;;;;;;; We are going to use INVERSION OF CONTROL and
;;;;;;; let the caller make the decision of deciding
;;;;;;; whether to call the STANDARD customer function
;;;;;;; or GUEST customer function. Also, we have more choices to make
;;;;;;; 1) Online payment page redirection for Standard Customer
;;;;;;; 2) Read only shopping cart for COD orders,
;;;;;;;  which could be for both Standard & Guest customers.

(defun standard-cust-information-page (customer)
  (let* ((cust-name (if customer (slot-value customer 'name)))
         (cust-address (if customer (slot-value customer 'address) ""))
	 (cust-city (if customer (slot-value customer 'city)))
	 (cust-state (if customer (slot-value customer 'state)))
	 (cust-zipcode (if customer (slot-value customer 'zipcode)))
	 (cust-phone (if customer (slot-value customer 'phone)))
         (cust-email (if customer  (slot-value customer 'email))))
    
    (cl-who:with-html-output-to-string (*standard-output* nil)
      (:form :class "form-standardcustorder" :role "form" :id "hhubordcustdetails"  :method "POST" :action "hhubcustshippingmethodspage" :data-toggle "validator"
	     (cl-who:str (display-orddatereqdate-text-widget))
	     (cl-who:str (display-phone-text-widget cust-phone 1))
	     (cl-who:str (display-name&email-widget cust-name cust-email 2))
	     (with-html-div-row
	       (:hr))
	     (cl-who:str (display-shipping&billing-widget cust-address cust-zipcode cust-city cust-state))
	     (with-html-div-row
	       (:hr))
	     (:input :type "submit"  :class "btn btn-primary" :value "Checkout"))
      (:div :class "row"
	    (:hr)))))

(defun display-orddatereqdate-text-widget ()
  (cl-who:with-html-output-to-string (*standard-output* nil)
    (with-html-div-row
      (with-html-div-col-6 
	(:h1 :class "text-center login-title"  "Personal Details & Address")
	(:div  :class "form-group" (:label :for "orddate" "Order Date" )
	       (:input :class "form-control" :name "orddate" :value (cl-who:str (get-date-string (clsql-sys::get-date))) :type "text"  :readonly T  ))
	(:div :class "form-group"  (:label :for "reqdate" "Preferred Delivery Date - Click To Change" )
	      (:input :class "form-control" :name "reqdate" :id "required-on" :placeholder  (cl-who:str (format nil "~A. Click to change" (get-date-string (clsql::date+ (clsql::get-date) (clsql::make-duration :day 1))))) :type "text" :value (get-date-string (clsql-sys:date+ (clsql-sys:get-date) (clsql-sys:make-duration :day 1)))))))))

(defun display-phone-text-widget (phone tabindex)
  (cl-who:with-html-output-to-string (*standard-output* nil)
    (with-html-div-row
      (with-html-div-col-8
	(:div :class "form-group" (:label :for "phone" "Phone" )
	      (:input :class "form-control" :type "text" :class "form-control" :name "phone" :value phone :placeholder "Mobile Phone (9999999999) " :tabindex tabindex :maxlength "13"  :required T ))))))

(defun display-name&email-widget (name email tabindex)
  (cl-who:with-html-output-to-string (*standard-output* nil)
    (with-html-div-row
      (with-html-div-col-8
	(:div :class "form-group" (:label :for "custname" "Name" )
	      (:input :class "form-control" :type "text" :class "form-control" :name "custname" :value name :placeholder "Name" :tabindex tabindex :required T))))
    (with-html-div-row
      (with-html-div-col-8
	(:div :class "form-group" (:label :for "email" "Email" )
	      (:input :class "form-control" :type "email" :class "form-control" :name "email" :value email :placeholder "Email" :data-error "That email address is invalid" :tabindex (+ tabindex 1)))))))

(defun display-shipping&billing-widget (address zipcode city state )
  (let ((charcountid1 (format nil "idchcount~A" (hhub-random-password 3))))
    (cl-who:with-html-output-to-string (*standard-output* nil)
      ;; Row for Shipping and Billing Address. 
      (with-html-div-row
	(with-html-div-col-6
	  (:p "Shipping"))
	(with-html-div-col-6
	  (:p "Billing")
	  (:div :class "form-check"
		(:input :type "checkbox" :id "billsameasshipchecked" :name "billsameasshipchecked" :value  "billsameasshipchecked" :onclick "displaybillingaddress();" :tabindex "9"  :checked "true")
		(:label :class "form-check-label" :style "font-size: 0.7rem;" :for "billsameasshipchecked" "&nbsp;&nbsp;Same as Shipping Address"))))
      
      (with-html-div-row
	(with-html-div-col-8
	  (:div :class "form-group" (:label :for "shipaddress" "Shipping Address")
		(:textarea :class "form-control" :id "shipaddress" :name "shipaddress"  :rows "3" :onkeyup (format nil "countChar(~A.id, this, 200)" charcountid1)  :tabindex "5" (cl-who:str (format nil "~A" address))))
	  (:div :id charcountid1 :class "form-group")
	  (:div :class "form-group" (:label :for "shipzipcode" "Confirm Pincode." )
		(:input :class "form-control" :type "text" :class "form-control" :inputmode "numeric" :maxlength "6" :id "shipzipcode" :name "shipzipcode" :value zipcode :placeholder "Pincode" :tabindex "8"  :oninput "this.value=this.value.replace(/[^0-9]/g,'');"))
	  (:div :class "form-group"
		(:span :id "areaname" :class "label label-info" ""))
	  (:div :class "form-group" (:label :for "city" "City" )
		(:input :class "form-control" :type "text" :class "form-control" :name "shipcity" :value city :id "shipcity" :placeholder "City" :readonly T :required T))
	  (:div :class "form-group" (:label :for "state" "State" )
		(:input :class "form-control" :type "text" :class "form-control" :name "shipstate" :value state :id "shipstate"  :placeholder "State"  :readonly T :required T ))))
      
      (with-html-div-row :id "billingaddressrow" :style "display: none;" 
	(with-html-div-col-8
	  (:div :class "form-group" (:label :for "shipaddress" "Billing Address" )
		(:textarea :class "form-control" :name "billaddress" :id "billaddress" :rows "3"  :tabindex "7"))
	  (:div :class "form-group" (:label :for "zipcode" "Pincode" )
		(:input :class "form-control" :type "text" :class "form-control" :inputmode "numeric" :maxlength "6" :id "billzipcode" :name "billzipcode" :tabindex "8" :placeholder "Pincode" ))
	  (:div :class "form-group" (:label :for "city" "City" )
		(:input :class "form-control" :type "text" :class "form-control" :name "billcity" :id "billcity"  :placeholder "City" ))
	  (:div :class "form-group" (:label :for "state" "State" )
		(:input :class "form-control" :type "text" :class "form-control" :name "billstate" :id "billstate" :placeholder "State" )))))))

(defun display-gst-widget ()
  (cl-who:with-html-output-to-string (*standard-output* nil) 
    (with-html-div-row 
      (with-html-div-col
	(:h4 "(optional)" ))
      (with-html-div-col
	(:div :class "form-check"
	      (:input :type "checkbox" :id "claimitcchecked" :name "claimitcchecked" :value  "claimitcchecked" :onclick "displaygstdetails();")
	      (:label :class "form-check-label" :for "claimitcchecked" "&nbsp;&nbsp;GST Invoice"))))
    (with-html-div-row :id "gstdetailsfororder"
      (with-html-div-col
	(:div :class "form-group" (:label :for "gstnumber" "GST Number" )
	      (:input :class "form-control" :type "text" :class "form-control" :name "gstnumber" :tabindex "9" :placeholder "GST Number" )))
      (with-html-div-col
	(:div :class "form-group" (:label :for "gstorgname" "Organization/Firm/Company Name" )
	      (:input :class "form-control" :type "text" :class "form-control" :name "gstorgname" :tabindex "10"  :placeholder "Org/Firm/Company Name" ))))))

(defun display-captcha-widget ()
  (cl-who:with-html-output-to-string (*standard-output* nil) 
    (with-html-div-row :style "display:block;"
      (with-html-div-col
	(:div :class "form-group"
	      (:div :class "g-recaptcha" :required T  :data-sitekey *HHUBRECAPTCHAV2KEY* ))))))

(defun display-terms-widget ()
  (cl-who:with-html-output-to-string (*standard-output* nil) 
    (with-html-div-row :style "display:block;"
      (with-html-div-col
	(:div :class "form-check"
	      (:input :type "checkbox" :name "tnccheck" :value  "tncagreed" :tabindex "11" :required T)
	      (:label :class= "form-check-label" :for "tnccheck" "&nbsp;&nbsp;Agree Terms and Conditions&nbsp;&nbsp;")
	      (:a  :href "/hhub/tnc" (:i :class "fa-solid fa-scale-balanced") "&nbsp;Terms"))))))


(defun guest-cust-information-page (temp-customer)
  (let* ((temp-cust-name (if temp-customer (slot-value temp-customer 'name)))
         (temp-cust-address (if temp-customer (slot-value temp-customer 'address) ""))
	 (temp-cust-city (if temp-customer (slot-value temp-customer 'city)))
	 (temp-cust-state (if temp-customer (slot-value temp-customer 'state)))
	 (temp-cust-zipcode (if temp-customer (slot-value temp-customer 'zipcode)))
	 (temp-cust-phone (if temp-customer (slot-value temp-customer 'phone)))
         (temp-cust-email (if temp-customer  (slot-value temp-customer 'email))))
   
  (cl-who:with-html-output-to-string (*standard-output* nil)
    (:form :class "form-guestcustorder" :role "form" :id "hhubordcustdetails"  :method "POST" :action "hhubcustshippingmethodspage" :data-toggle "validator"
	   (with-html-div-row
	     (with-html-div-col-6
	       (:a :role "button" :class "btn btn-lg btn-primary btn-block" :href "dodcustshopcart" "Previous"))
	     (with-html-div-col-6
	       (:input :type "submit"  :class "btn btn-lg btn-primary btn-block" :tabindex "13" :value "Next")))
	   (cl-who:str (display-orddatereqdate-text-widget))
	   (cl-who:str (display-phone-text-widget temp-cust-phone 1))
	   (cl-who:str (display-name&email-widget temp-cust-name temp-cust-email 2))
	   (with-html-div-row
	     (:hr))
	   (cl-who:str (display-shipping&billing-widget temp-cust-address temp-cust-zipcode temp-cust-city temp-cust-state))
	   ;;(cl-who:str (display-captcha-widget))
	   (with-html-div-row
	     (with-html-div-col-6
	       (:a :role "button" :class "btn btn-lg btn-primary btn-block" :href "dodcustshopcart" "Previous"))
	     (with-html-div-col-6
	       (:input :type "submit"  :class "btn btn-lg btn-primary btn-block" :tabindex "13" :value "Next")))))))


(defun dod-controller-cust-add-order-page()
  (let ((cust-type (get-login-customer-type)))
	(with-cust-session-check
	  (with-standard-customer-page-v2  "Add Customer Order"
	    (with-customer-breadcrumb
	      (:li :class "breadcrumb-item" (:a :href "dodcustshopcart" "Cart")))
	    (cl-who:str (cust-information-page cust-type))))))

;;; This function has been separated from the controller function because it is independently testable.

(defun cust-information-page(cust-type)
  ;; We are using a hash table to store the function references to call them later.
  ;; This is a good practice to avoid IF condition.
  (let ((temp-ht (make-hash-table :test 'equal)))
    (setf (gethash "STANDARD"  temp-ht) (list (symbol-function 'standard-cust-information-page) (get-login-customer)))
    (setf (gethash "GUEST" temp-ht) (list (symbol-function 'guest-cust-information-page) (hunchentoot:session-value :temp-guest-customer)))
    (let* ((htentry (gethash cust-type temp-ht))
	   (funcname (nth 0 htentry))
	   (funcparams (nth 1 htentry)))
      (funcall funcname funcparams))))


(defun createmodelforcustaddordersubs ()
  (let ((product-id (hunchentoot:parameter "product-id"))
	(login-cust (hunchentoot:session-value :login-customer))
	(login-cust-comp (hunchentoot:session-value :login-customer-company))
	(prd-qty (parse-integer (hunchentoot:parameter "prdqty")))
	(subs-mon (hunchentoot:parameter "subs-mon"))
	(subs-tue (hunchentoot:parameter "subs-tue"))
	(subs-wed (hunchentoot:parameter "subs-wed"))
	(subs-thu (hunchentoot:parameter "subs-thu"))
	(subs-fri (hunchentoot:parameter "subs-fri"))
	(subs-sat (hunchentoot:parameter "subs-sat"))
	(subs-sun (hunchentoot:parameter "subs-sun"))
	(redirectlocation "/hhub/dodcustorderprefs"))
    (when (> prd-qty 0) 
	(create-opref login-cust  (select-product-by-id product-id login-cust-comp )  prd-qty  (list subs-mon subs-tue subs-wed subs-thu subs-fri subs-sat subs-sun)  login-cust-comp))
    ;;before returning the newly created subscription list, save it in customer session. 
    (setf (hunchentoot:session-value :login-cusopf-cache) (get-opreflist-for-customer login-cust))
    ;; we are returning nothing here.
    (function (lambda ()
      (values redirectlocation)))))

    
(defun createwidgetsforcustaddordersubs (modelfunc)
  (multiple-value-bind (redirectlocation) (funcall modelfunc)
    (let ((widget1 (function (lambda () redirectlocation))))
      (list widget1))))

      
(defun dod-controller-cust-add-orderpref-action ()
  (with-cust-session-check
    ;; create the model and return back the url to redirect to.
    (let ((uri (with-mvc-redirect-ui createmodelforcustaddordersubs createwidgetsforcustaddordersubs)))
     (format nil "~A" uri))))
    

  
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

;;;; LOW WALLET BALANCE FOR SHOPCART ;;;;;
(defun createmodelforlowwalletbalanceforshopcart ()
  (let* ((odts (hunchentoot:session-value :login-shopping-cart))
	 (vendor-list (get-shopcart-vendorlist odts))
	 (company (get-login-customer-company)) 
	 (wallets (mapcar (lambda (vendor) 
			    (get-cust-wallet-by-vendor  (get-login-customer) vendor company)) vendor-list))
	 (order-items-totals (mapcar (lambda (vendor)
				       (get-order-items-total-for-vendor vendor odts)) vendor-list)))
    (function (lambda ()
      (values wallets order-items-totals)))))

(defun createwidgetforlowwalletbalanceforshopcart (modelfunc)
  (multiple-value-bind (wallets order-items-totals) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-html-div-row
			 (with-html-div-col
			   (:div :class "p-3 mb-2 bg-danger text-white" "Low Wallet Balance")))
		       (list-customer-low-wallet-balance   wallets order-items-totals)
		       (:a :class "btn btn-primary" :role "button" :href "dodcustshopcart" (:i :class "fa-solid fa-cart-shopping") "&nbsp;Modify Cart&nbsp;"))
		     (jscript-displayerror "Low Wallet Balance")))))
      (list widget1))))

(defun dod-controller-low-wallet-balance-for-shopcart ()
  (with-cust-session-check
    (with-mvc-ui-page "Low Wallet Balance" createmodelforlowwalletbalanceforshopcart createwidgetforlowwalletbalanceforshopcart :role :customer)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;; LOW WALLET BALANCE FOR ORDER ITEMS ;;;;;;;;;;;;;;;;;;;;;;;;;
(defun createmodelforlowwalletbalancefororderitems ()
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
    (function (lambda ()
      (values wallets order-items-totals)))))

(defun createwidgetsforlowwalletbalancefororderitems (modelfunc)
  (multiple-value-bind (wallets order-items-totals) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (:div :class "row"
                             (:div :class "col-sm-12 col-xs-12 col-md-12 col-lg-12"
				   (:h3 (:span :class "label label-danger" "Low Wallet Balance."))))
		       (list-customer-low-wallet-balance   wallets order-items-totals))))))
      (list widget1))))

(defun dod-controller-low-wallet-balance-for-orderitems ()
  (with-cust-session-check
    (with-mvc-ui-page "Low Wallet Balance" createmodelforlowwalletbalancefororderitems createwidgetsforlowwalletbalancefororderitems :role :customer)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

(defun dod-controller-cust-login-otpstep ()
  (let* ((phone  (hunchentoot:parameter "phone"))
	 (context (format nil "hhubcustloginwithotp?phone=~A" phone)))
      (hunchentoot:start-session)
      ;; Redirect to the OTP page 
      (generateotp&redirect phone context)))

(defun dod-controller-cust-login-with-otp ()
  (let ((phone (hunchentoot:parameter "phone")))
    (unless (or (null phone) (zerop (length phone)))
      (unless (dod-cust-login-with-otp  :phone phone)
	(hunchentoot:redirect "/hhub/customer-login.html"))
      (hunchentoot:redirect  "/hhub/dodcustindex"))))

(defun dod-controller-cust-ordersuccess ()
  (with-cust-session-check 
    (let ((cust-type  (slot-value (get-login-customer) 'cust-type)))
      (with-standard-customer-page-v2
	 "Welcome to Nine Stores - Add Customer Order"
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
  
  
(defun send-order-email-guest-customer(order-id email temp-customer products shopcart shipping-cost) 
  (let* ((shopcart-total (get-shop-cart-total shopcart))
	 (subject (format nil "Nine Stores order ~A" order-id))
	 (order-disp-str (create-order-email-content products shopcart temp-customer order-id shipping-cost shopcart-total)))
    (logiamhere (format nil "subject is ~d" order-id))
    (send-message *NSTSENDORDEREMAILACTOR* (lambda () (values email subject order-disp-str)))))
 ;;(send-order-mail email subject order-disp-str)))
    
  

(defun send-order-sms-guest-customer (order-id phone)
  (declare (ignore order-id phone))
  :documentation "Send an SMS to Guest customer when order is placed.")
  

;;(send-sms-notification phone "HIGHUB" (format nil "[HIGHRISEHUB] Thank You for placing the order. Your order number is ~A and will be processed soon" order-id)))
;; we are not sending any SMS to standard customer as of now for placing an order. This also will be based on settings on the company. Will need to register a SMS template for this. 

(defun send-order-sms-standard-customer(order-id phone)
  (declare (ignore order-id phone))
  :documentation "Send an SMS to Guest customer when order is placed.")

;; (send-sms-notification phone "HIGHUB" (format nil "[HIGHRISEHUB] Thank You for placing the order. Your order number is ~A and will be processed soon" order-id)))
;; we are not sending any SMS to standard customer as of now for placing an order. This also will be based on settings on the company. Will need to register a SMS template for this. 

(defun send-order-email-standard-customer(order-id email products shopcart shipping-cost)
  (declare (ignore order-id email products shopcart shipping-cost))
  :Documentation "We are not sending any email to standard customer Today. We will check his settings and then decide whether to send email or not. Future")

(defun check-all-vendors-wallet-balance(vendor-list wallet-list shopcart)
  :documentation "At least one vendor wallet has low balance, then return nil. Pure function."
  (every #'(lambda (x) (if x T))
	 (mapcar (lambda (vendor wallet)
		   (let ((total (get-order-items-total-for-vendor vendor shopcart)))
		     ;;(logiamhere (format nil "Shopcart total is  ~A. Wallet balance is ~A" total (slot-value wallet 'balance)))
		     (check-wallet-balance total wallet))) vendor-list wallet-list)))



(defun createmodelforcustordercreate ()
  (let* ((params nil)
	 (orderparams-ht (get-cust-order-params))
	 (odts (gethash "shoppingcart" orderparams-ht))
	 (shopcart-products (gethash "shopcartproducts" orderparams-ht))
	 (shipaddress (gethash "shipaddress" orderparams-ht))
	 (shipzipcode (gethash "shipzipcode" orderparams-ht))
	 (shipcity (gethash "shipcity" orderparams-ht))
	 (shipstate (gethash "shipstate" orderparams-ht))
	 (billaddress (gethash "billaddress" orderparams-ht))
	 (billzipcode (gethash "billzipcode" orderparams-ht))
	 (billcity (gethash "billcity" orderparams-ht))
	 (billstate (gethash "billstate" orderparams-ht))
	 (billsameasshipchecked (gethash "billsameasshipchecked" orderparams-ht))
	 (claimitcchecked (gethash "claimitcchecked" orderparams-ht))
	 (gstnumber (gethash "gstnumber" orderparams-ht))
	 (gstorgname (gethash "gstorgname" orderparams-ht))
	 (shopcart-total (gethash "shopcart-total" orderparams-ht))
	 (shipping-cost (gethash "shipping-cost" orderparams-ht))
	 (shipping-info (gethash "shipping-info" orderparams-ht))
	 (phone  (gethash "phone" orderparams-ht))
	 (email (gethash "email" orderparams-ht))
	 (odate (gethash "orddate" orderparams-ht))
	 (reqdate (gethash "reqdate" orderparams-ht))
	 (ship-date (gethash "shipdate" orderparams-ht))
	 (utrnum (gethash "utrnum" orderparams-ht))
	 (payment-mode (gethash "paymentmode" orderparams-ht))
	 (comments (gethash "comments" orderparams-ht))
	 (order-cxt (gethash "order-cxt" orderparams-ht))
	 (storepickupenabled (gethash "storepickupenabled" orderparams-ht))
	 (cust (get-login-customer))
	 (custcomp (get-login-customer-company))
	 (custname (slot-value cust 'name))
	 (lowwalletbalanceflag nil)
	 (redirectlocation "/hhub/dodcustordsuccess"))
    (declare (ignore billaddress billzipcode billcity billstate billsameasshipchecked claimitcchecked gstnumber gstorgname order-cxt shipzipcode shipcity shipstate custname ))
    ;;(logiamhere (format nil "payment mode is ~A" payment-mode))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "company" custcomp  params))
    (with-hhub-transaction "com-hhub-transaction-create-order" params
      (let* ((temp-ht (make-hash-table :test 'equal))
	     (vendor-list (get-shopcart-vendorlist odts))
	     (wallet-list (mapcar (lambda (vendor) (get-cust-wallet-by-vendor cust vendor custcomp)) vendor-list))
	     (cust-type (slot-value cust 'cust-type))
	     (temp-customer (hunchentoot:session-value :temp-guest-customer)))
	
	;; This function call is not pure. Try to make it pure. 
	;; (guest-email (hunchentoot:session-value :guest-email-address)))
	
	;; If the payment mode is PREPAID, then check whether we have enough balance first. If not, then redirect to the low wallet balance. 
	;; Redirecting to some other place is not a pure function behavior. Is there a better way to handle this? 
	;;(logiamhere (format nil "payment mode is ~A" payment-mode))
	(setf (gethash "PRE" temp-ht) (symbol-function 'check-all-vendors-wallet-balance))
	(let ((func (gethash payment-mode temp-ht)))
	  (when func (unless (funcall (gethash payment-mode temp-ht) vendor-list wallet-list odts)
		       (setf redirectlocation "/hhub/dodcustlowbalanceshopcart")
		       (setf lowwalletbalanceflag T))))
	;; If everything gets through, create order. 
	(unless lowwalletbalanceflag
	  (let ((order-id (create-order-from-shopcart  odts shopcart-products odate reqdate ship-date  shipaddress shopcart-total shipping-cost shipping-info  payment-mode comments cust custcomp temp-customer utrnum storepickupenabled)))
	    (setf (gethash "GUEST-EMAIL" temp-ht) (symbol-function 'send-order-email-guest-customer))
	    (setf (gethash "GUEST-SMS" temp-ht) (symbol-function 'send-order-sms-guest-customer))
	    (setf (gethash "STANDARD-EMAIL" temp-ht) (symbol-function 'send-order-email-standard-customer))
	    (setf (gethash "STANDARD-SMS" temp-ht) (symbol-function 'send-order-sms-standard-customer))
	    (logiamhere (format nil "order id is ~d" order-id))
	    ;; Send order SMS to guest customer if phone is provided. (Phone is required field for Guest customer, hence SMS will always be sent)
	    (when (and (equal cust-type "GUEST") phone) (funcall (gethash (format nil "~A-SMS" cust-type) temp-ht) order-id  phone))
	    ;; Send order email to guest customer if email is provided. 
	    (when (and (equal cust-type "GUEST") (> (length email) 0))  (funcall (gethash (format nil "~A-EMAIL" cust-type) temp-ht) order-id email temp-customer  shopcart-products odts shipping-cost))
	    ;; If STANDARD customer has email, then send order email 
	    (when (and (equal cust-type "STANDARD") (> (length email) 0)) (funcall (gethash (format nil "~A-EMAIL" cust-type) temp-ht) order-id email shopcart-products odts shipping-cost))
	    ;; If standard customer has phone, then send SMS 
	    (when (and (equal cust-type "STANDARD") phone) (funcall (gethash (format nil "~A-SMS" cust-type) temp-ht) order-id phone))
	    (reset-cust-order-params)
	    (setf (hunchentoot:session-value :login-cusord-cache) (get-orders-for-customer cust))
	    (setf (hunchentoot:session-value :login-shopping-cart ) nil)))
	(function (lambda ()
	  (values redirectlocation)))))))
	
  

(defun createwidgetsforcustordercreate (modelfunc)
  (multiple-value-bind
   (redirectlocation) (funcall modelfunc)
   (let ((widget1 (function (lambda () redirectlocation))))
     (list widget1))))

(defun com-hhub-transaction-create-order ()
  (with-cust-session-check
    (let ((uri (with-mvc-redirect-ui createmodelforcustordercreate createwidgetsforcustordercreate)))
      (format nil "~A" uri))))

(defun save-cust-order-params (list) 
  (setf (hunchentoot:session-value :customer-clipboard) list))
(defun get-cust-order-params()
  (hunchentoot:session-value :customer-clipboard))
(defun reset-cust-order-params()
  (setf (hunchentoot:session-value :customer-clipboard) nil))

(defun createmodelforcustaddorderotpstep ()
  (let* ((phone  (hunchentoot:parameter "phone"))
	 (context (hunchentoot:parameter "context"))
	 (paymentmode (hunchentoot:parameter "paymentmode"))
	 (cust-type (get-login-customer-type))
	 (redirectlocation (format nil "/hhub/~A&paymentmode=~A" context paymentmode)))
    ;; Redirect to the OTP page only for Guest customer. 
    (if (equal cust-type "GUEST") (generateotp&redirect phone context)
	;;else for standard customer, redirect to final checkout page. 
	(function (lambda ()
	  (values redirectlocation))))))

(defun createwidgetsforcustaddorderotpstep (modelfunc)
  (multiple-value-bind (redirectlocation) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     redirectlocation))))
      (list widget1))))
  
(defun dod-controller-cust-add-order-otpstep ()
  ;; no need to check for customer session as this might be a guest login. 
  (let ((uri (with-mvc-redirect-ui createmodelforcustaddorderotpstep createwidgetsforcustaddorderotpstep)))
    (format nil "~A" uri)))

(defun createmodelforcustshipmethodspage ()
  (let* ((lstshopcart (hunchentoot:session-value :login-shopping-cart))
	 (cust-type (get-login-customer-type))
	 (vendor-list (get-shopcart-vendorlist lstshopcart))
	 (singlevendor (first vendor-list))
	 (products (hunchentoot:session-value :login-prd-cache))
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
	 (phone  (hunchentoot:parameter "phone"))
	 (email (hunchentoot:parameter "email"))
	 (odate  (get-date-from-string (hunchentoot:parameter "orddate")))
	 (reqdate (get-date-from-string (hunchentoot:parameter "reqdate")))
	 (comments (if phone (format nil "~A, ~A, ~A, ~A, ~A, ~A" phone email shipaddress shipcity shipstate shipzipcode)))
	 (shopcart-total (get-shop-cart-total lstshopcart))
	 (customer (get-login-customer))
	 (custcomp (get-login-customer-company))
	 ;;(wallet-balance (slot-value (get-cust-wallet-by-vendor customer (first vendor-list) custcomp) 'balance))
	 (order-cxt (format nil "hhubcustopy~A" (get-universal-time)))
	 (orderparams-ht (make-hash-table :test 'equal))
	 (shopcart-products (mapcar (lambda (odt)
				      (let ((prd-id (slot-value odt 'prd-id)))
					(search-item-in-list 'row-id prd-id products ))) lstshopcart))
	 (vshipping-method (get-shipping-method-for-vendor singlevendor custcomp))
	 (freeshipenabled (slot-value vshipping-method 'freeshipenabled))
	 (storepickupenabled (slot-value vshipping-method 'storepickupenabled))
	 (shiplst (calculate-shipping-cost-for-order vshipping-method shipzipcode shopcart-total lstshopcart shopcart-products singlevendor custcomp))
	 (shipping-cost (nth 0 shiplst))
	 (shipping-options (nth 1 shiplst)))

    (when (equal cust-type "GUEST") (setf (hunchentoot:session-value :guest-email-address) email))
    (setf (gethash "orddate" orderparams-ht) odate)
    (setf (gethash "reqdate" orderparams-ht) reqdate)
    (setf (gethash "shoppingcart" orderparams-ht) lstshopcart)
    (setf (gethash "shopcartproducts" orderparams-ht) shopcart-products)
    (setf (gethash "shipaddress" orderparams-ht) shipaddress)
    (setf (gethash "shipzipcode" orderparams-ht) shipzipcode)
    (setf (gethash "shipcity" orderparams-ht) shipcity)
    (setf (gethash "shipstate" orderparams-ht) shipstate)
    (setf (gethash "billaddress" orderparams-ht) billaddress)
    (setf (gethash "billzipcode" orderparams-ht) billzipcode)
    (setf (gethash "billcity" orderparams-ht) billcity)
    (setf (gethash "billstate" orderparams-ht) billstate)
    (setf (gethash "billsameasshipchecked" orderparams-ht) billsameasshipchecked)
    (setf (gethash "gstnumber" orderparams-ht) gstnumber)
    (setf (gethash "gstorgname" orderparams-ht) gstorgname)
    (setf (gethash "claimitcchecked" orderparams-ht) claimitcchecked)
    (setf (gethash "shopcart-total" orderparams-ht) shopcart-total)
    (setf (gethash "comments" orderparams-ht) comments)
    (setf (gethash "customer" orderparams-ht) customer)
    (setf (gethash "custcomp" orderparams-ht) custcomp)
    (setf (gethash "order-cxt" orderparams-ht) order-cxt)
    (setf (gethash "custname" orderparams-ht) custname)
    (setf (gethash "phone" orderparams-ht) phone)
    (setf (gethash "email" orderparams-ht) email)
    (setf (gethash "shopcartproducts" orderparams-ht) shopcart-products)
    (setf (gethash "shipping-cost" orderparams-ht) shipping-cost)
    (setf (gethash "shipping-info" orderparams-ht) shipping-options)
        
      ;; Save the customer order parameters in a hashtable. 
      (save-cust-order-params orderparams-ht)
      ;; Save the Guest customer details so that we can use them within the session if required. 
      (when (equal cust-type "GUEST")
	(save-temp-guest-customer custname shipaddress shipcity shipstate shipzipcode phone email))
    (function (lambda ()
      (values shopcart-total shiplst storepickupenabled singlevendor freeshipenabled)))))

(defun createwidgetsforcustshipmethodspage (modelfunc)
  (multiple-value-bind (shopcart-total shiplst storepickupenabled singlevendor freeshipenabled)
      (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (with-customer-breadcrumb
		       (:li :class "breadcrumb-item" (:a :href "dodcustshopcart" "Cart"))
		       (:li :class "breadcrumb-item" (:a :href "dodcustorderaddpage" "Address"))))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-html-form "form-custshippingmethod" "hhubcustpaymentmethodspage"
			 (display-cust-shipping-costs-widget shopcart-total shiplst storepickupenabled singlevendor freeshipenabled)
			 (with-html-div-row
			   (with-html-div-col-6
			     (:a :role "button" :class "btn btn-lg btn-primary btn-block" :href "dodcustorderaddpage" "Previous"))
			   (with-html-div-col-6
			     (:input :type "submit" :class "btn btn-lg btn-primary btn-block checkout-button" :tabindex "13" :value "Next")))))))))
	  (list widget1 widget2))))


(defun dod-controller-cust-shipping-methods-page ()
  (with-cust-session-check
    (with-mvc-ui-page "Customer Shipping Methods" createmodelforcustshipmethodspage createwidgetsforcustshipmethodspage :role :customer)))

;; This is a pure function. 
(defun calculate-shipping-cost-for-order (vshipping-method shipzipcode shopcart-total shopping-cart products vendor company)
  (let* ((vshipping-enabled (slot-value vendor 'shipping-enabled))
	 (freeshippingenabled (slot-value vshipping-method 'freeshipenabled))
	 (flatrateshipenabled (slot-value vshipping-method 'flatrateshipenabled))
	 (tablerateshipenabled (slot-value vshipping-method 'tablerateshipenabled))
	 (extshipenabled (slot-value vshipping-method 'extshipenabled))
	 (defaultshipmethod (getdefaultshippingmethod vshipping-method))
	 (freeshipminorderamt (getminorderamt vshipping-method))
	 (vendor-zipcode (slot-value vendor 'zipcode))
	 (total-items (reduce #'+ (mapcar (lambda (item) (slot-value item 'prd-qty)) shopping-cart)))
	 (shipping-options nil)
	 (shipping-cost 0.0)
	 (saleproducts-p  (every #'(lambda (x) (if x T))
				 (mapcar (lambda (product)
					   (let ((prd-type (slot-value product 'prd-type)))
					     (equal prd-type "SALE"))) products))))
    ;; If we have a single service product or number of service products are more than 1 then do not calculate
    ;; shipping cost. Or calculate shipping cost only for SALES products. 
    ;;(logiamhere (format nil "Value of saleproducts-p is ~A" saleproducts-p))
    (when (and (equal vshipping-enabled "Y")
	       (<= shopcart-total freeshipminorderamt)
	       saleproducts-p)
      (when (and flatrateshipenabled (equal defaultshipmethod "FRS"))
	(let ((flatratetype (getflatratetype vshipping-method))
	      (flatrateprice (getflatrateprice vshipping-method)))
	  (cond ((equal flatratetype "ORD") (setf shipping-cost flatrateprice))
		((equal flatratetype "ITM") (setf shipping-cost (* flatrateprice total-items))))))
      (when (and tablerateshipenabled (equal defaultshipmethod "TRS"))
	(let ((total-weight (calculate-cartitems-weight-kgs shopping-cart products)))
	  (setf shipping-cost (get-shipping-rate-from-table shipzipcode total-weight vendor company))))
      (when (and extshipenabled (equal defaultshipmethod "EXS"))
	(setf shipping-options (order-shipping-rate-check shopping-cart products shipzipcode vendor-zipcode))
	(setf shipping-cost (if shipping-options (min-item (mapcar (lambda (elem)
								     (nth 9 elem)) shipping-options))
				;; else
				0.00)))
      (when (and freeshippingenabled 
		 (>= shopcart-total freeshipminorderamt))
	(setf shipping-cost 0.0)))
    (list shipping-cost shipping-options freeshipminorderamt)))
    
    

(defun createmodelforcustshowshopcartreadonly ()
  (let* ((orderparams-ht (get-cust-order-params)) 
	 (odts (gethash "shoppingcart" orderparams-ht))
	 (odate (gethash "orddate" orderparams-ht))
	 (reqdate (gethash "reqdate" orderparams-ht))
	 (shopcart-products (gethash "shopcartproducts" orderparams-ht))
	 (shipaddress (gethash "shipaddress" orderparams-ht))
	 (shipcity (gethash "shipcity" orderparams-ht))
	 (shipstate (gethash "shipstate" orderparams-ht))
	 (shipzipcode (gethash "shipzipcode" orderparams-ht))
	 (billaddress (gethash "billaddress" orderparams-ht))
	 (billzipcode (gethash "billzipcode" orderparams-ht))
	 (billcity (gethash "billcity" orderparams-ht))
	 (billstate (gethash "billstate" orderparams-ht))
	 (billsameasshipchecked (gethash "billsameasshipchecked" orderparams-ht))
	 (claimitcchecked (gethash "claimitcchecked" orderparams-ht))
	 (gstnumber (gethash "gstnumber" orderparams-ht))
	 (gstorgname (gethash "gstorgname" orderparams-ht))
	 (shopcart-total (gethash "shopcart-total" orderparams-ht))
	 (shipping-cost (gethash "shipping-cost" orderparams-ht))
	 (storepickupenabled (gethash "storepickupenabled" orderparams-ht))
	 (vendoraddress (gethash "vendoraddress" orderparams-ht))
	 (payment-mode (hunchentoot:parameter "paymentmode"))
	 (utrnum (hunchentoot:parameter "utrnum"))
	 (phone  (gethash "phone" orderparams-ht))
	 (email (gethash "email" orderparams-ht))
	 (customer (get-login-customer))
	 (custcomp (get-login-customer-company))
	 (order-cxt (format nil "hhubcustopy~A" (get-universal-time)))
	 (company-type (slot-value custcomp 'cmp-type))
	 (vendor-list (get-shopcart-vendorlist odts))
	 (singlevendor (first vendor-list))
	 (vshipping-enabled (slot-value singlevendor 'shipping-enabled))
	 (wallet-id (slot-value (get-cust-wallet-by-vendor customer (first vendor-list) custcomp) 'row-id)))

    ;;(logiamhere (format nil "Payment mode is ~A" payment-mode))

    ;; if payment is made using UPI, then add the utrnum to the order parameters
    (when (and (equal payment-mode "UPI") utrnum)
      (setf (gethash "utrnum" orderparams-ht) utrnum)
      (setf (gethash "paymentmode" orderparams-ht) "UPI"))
    
    (when payment-mode
      (setf (gethash "paymentmode" orderparams-ht) payment-mode))
    
    (unless payment-mode
      (setf payment-mode "COD")
      (setf (gethash "paymentmode" orderparams-ht) "COD"))
    
    ;; Save the order params for further use. 
    (save-cust-order-params orderparams-ht)
    ;; return the variables in a function. 
    (function (lambda ()
      (values odate reqdate payment-mode utrnum phone email shipaddress shipcity shipstate shipzipcode billaddress billcity billstate billzipcode billsameasshipchecked claimitcchecked gstnumber gstorgname shopcart-total shipping-cost company-type order-cxt wallet-id shopcart-products odts storepickupenabled vendoraddress vshipping-enabled)))))

(defun createwidgetsforcustshowshopcartreadonly (modelfunc)
  (multiple-value-bind
	(odate reqdate payment-mode utrnum phone email shipaddress shipcity shipstate shipzipcode billaddress billcity billstate billzipcode billsameasshipchecked claimitcchecked gstnumber gstorgname shopcart-total shipping-cost company-type order-cxt wallet-id shopcart-products odts storepickupenabled vendoraddress vshipping-enabled)
      (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (with-customer-breadcrumb
		       (:li :class "breadcrumb-item" (:a :href "dodcustshopcart" "Cart"))
		       (:li :class "breadcrumb-item" (:a :href "dodcustorderaddpage" "Address"))))))
	 (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-html-div-row
			 (with-html-div-col-6
			   (:div :class "place-order-header"
				 (:p (cl-who:str (format nil "Order Date: ~A" (get-date-string odate))))
				 (:p (cl-who:str (format nil "Request Date: ~A" (get-date-string reqdate))))
				 (:p (cl-who:str (format nil "Payment Mode: ~A" payment-mode)))
				 (:p (when (and (equal payment-mode "UPI") utrnum)
				       (cl-who:str (format nil "UTR Number: ~A" utrnum))))
				 (:p (cl-who:str (format nil "Phone: ~A" phone)))
				 ;;If email is given by the guest customer during shopping
				 (when (> (length email) 0)
				   (cl-who:htm
				    (:p (cl-who:str (format nil "Email: ~A" email)))))
				 ;; Shipping address
				 (:p (cl-who:str (format nil "Shipping Address: ~A ~A ~A ~A" shipaddress shipcity shipstate shipzipcode)))
				 ;; billing address
				 (when (not billsameasshipchecked)
				   (cl-who:htm
				    (:p (cl-who:str (format nil "Billing Address: ~A, ~A, ~A, ~A" billaddress billcity billstate billzipcode)))))
		  		 ;; GST Number and Organization
				 (when (and claimitcchecked (> (length gstnumber) 0))
				   (cl-who:htm
				    (:p (cl-who:str (format nil "GST Number: ~A/~A" gstnumber gstorgname)))))))
			 (with-html-div-col-6
			   (:div :class "place-order-details"
				 (:p (cl-who:str (format nil "Sub-total: ~A ~$" *HTMLRUPEESYMBOL* shopcart-total)))
				 (:p (cl-who:str (format nil "Shipping: ~A ~$" *HTMLRUPEESYMBOL* shipping-cost)))
				 (:hr)
				 (:p (:h2 (:span :class "text-bg-success" (cl-who:str (format nil "Total: ~A ~$" *HTMLRUPEESYMBOL*  (+ shopcart-total shipping-cost))))))
		  		  
				 (cond
				   ((and (equal payment-mode "OPY") (or (equal company-type "COMMUNITY")
									(equal company-type "BASIC")
									(equal company-type "PROFESSIONAL")))
				    (cl-who:str (make-payment-request-html (format nil "~A" shopcart-total)   (format nil "~A" wallet-id) "live" order-cxt email)))
				   ((and (equal payment-mode "OPY")
					 (equal company-type "TRIAL"))
				    (cl-who:str (make-payment-request-html (format nil "~A" shopcart-total)   (format nil "~A" wallet-id) "test" order-cxt email)))
				   (T (with-html-form-having-submit-event "placeorderform" "dodmyorderaddaction"  
					(:span :class "input-group-btn" (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Place Order" ))))))))))))
			  
	  (widget3 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (cl-who:str (ui-list-shopcart-readonly shopcart-products odts))))))
	  (widget4 (function (lambda ()
		     (if (or storepickupenabled (eq vshipping-enabled "N")) (displaystorepickupwidget vendoraddress))))))
      (list widget1 widget2 widget3 widget4))))



(defun dod-controller-cust-show-shopcart-readonly()
  (with-cust-session-check
    (with-mvc-ui-page "Customer Shopping Cart Final" createmodelforcustshowshopcartreadonly createwidgetsforcustshowshopcartreadonly :role :customer)))
			   
; This is a pure function. 
(defun get-order-items-total-for-vendor (vendor order-items) 
  (let ((vendor-id (slot-value vendor 'row-id)))
    (reduce #'+ (remove nil (mapcar (lambda (item)
				      (let ((pricewith-discount (calculate-order-item-cost item))) 
					(if (equal vendor-id (slot-value item 'vendor-id)) 
					    pricewith-discount))) order-items)))))

(defun get-opref-items-total-for-vendor (vendor opref-items) 
 (let ((vendor-id (slot-value vendor 'row-id)))
  (reduce #'+ (remove nil (mapcar (lambda (item) 
				    (let* ((product (get-opf-product item))
					   (vendor (product-vendor product))
					   (pricewith-discount (calculate-order-item-cost item))) 
				      (if (equal vendor-id (slot-value vendor 'row-id))
					  pricewith-discount))) opref-items)))))


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
				       (let* ((pricewith-discount (calculate-order-item-cost odt)) 
					      (prdqty (slot-value odt 'prd-qty)))
					 (* pricewith-discount prdqty))) odts))))
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

(defun createmodelforcustupdatecart ()
  (let* ((prd-id (hunchentoot:parameter "prd-id"))
	 (prd-qty (hunchentoot:parameter "prdqty"))
	 (myshopcart (hunchentoot:session-value :login-shopping-cart))
	 (odt (if myshopcart (search-item-in-list  'prd-id (parse-integer prd-id)  myshopcart )))
	 (redirectlocation "/hhub/dodcustshopcart"))
    (setf (slot-value odt 'prd-qty) (parse-integer prd-qty))
    (function (lambda ()
      (values redirectlocation)))))
 
(defun createwidgetsforcustupdatecart (modelfunc)
  (multiple-value-bind (redirectlocation) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     redirectlocation))))
      (list widget1))))

(defun dod-controller-cust-update-cart ()
    :documentation "update the shopping cart by modifying the product quantity"
  (with-cust-session-check
    (let ((uri (with-mvc-redirect-ui createmodelforcustupdatecart createwidgetsforcustupdatecart)))
      (format nil "~A" uri))))
		 
(defun dod-controller-create-cust-wallet ()
  :documentation "If the customer wallet is not defined, then define it now"
  (let ((vendor (select-vendor-by-id (hunchentoot:parameter "vendor-id"))))
    (if vendor (create-wallet (get-login-customer) vendor (get-login-customer-company)))
    (if vendor (hunchentoot:log-message* :info "Created wallet for vendor ~A" (slot-value vendor 'name)))
    (hunchentoot:redirect (format nil "/hhub/dodcustindex"))))

(defun createmodelforcustaddtocart ()
  (let* ((prd-id (parse-integer (hunchentoot:parameter "prd-id")))
	 (prdqty (parse-integer (hunchentoot:parameter "prdqty")))
	 (productlist (hunchentoot:session-value :login-prd-cache))
	 (myshopcart (hunchentoot:session-value :login-shopping-cart))
	 (product (search-item-in-list 'row-id prd-id productlist))
	 (company (product-company product))
	 (current-price (slot-value product 'current-price))
	 (current-discount (slot-value product 'current-discount))
	 (vendor (product-vendor product))
	 (vendor-id (slot-value vendor 'row-id))
	 (wallet (get-cust-wallet-by-vendor (get-login-customer) vendor company))
	 (odt (create-odtinst-shopcart nil product  prdqty current-price current-discount company))
	 (redirectlocation (format nil "/hhub/hhubcustvendorstore?id=~A" vendor-id)))

    ;;(unless wallet (hunchentoot:redirect (format nil "/hhub/createcustwallet?vendor-id=~A" vendor-id)))
    (unless wallet (setf redirectlocation (format nil "/hhub/createcustwallet?vendor-id=~A" vendor-id)))
    (when (and wallet (> prdqty 0)) 
      (setf (hunchentoot:session-value :login-shopping-cart) (append myshopcart (list odt)))
      (setf (hunchentoot:session-value :login-active-vendor) vendor))
    (function (lambda ()
      (values redirectlocation)))))

(defun createwidgetsforcustaddtocart (modelfunc)
  (multiple-value-bind (redirectlocation) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     redirectlocation))))
      (list widget1))))

(defun dod-controller-cust-add-to-cart ()
  :documentation "This function is responsible for adding the product and product quantity to the shopping cart."
  (with-cust-session-check
    (let ((uri (with-mvc-redirect-ui createmodelforcustaddtocart createwidgetsforcustaddtocart)))
      (format nil "~A" uri))))

(defun createmodelforprddetailsforguestcustomer ()
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
	   (company (hunchentoot:session-value :login-customer-company))
	   (product (select-product-by-id prd-id company))
	   (customer (get-login-customer))
	   (prdinshopcart (prdinlist-p prd-id lstshopcart)))
      (function (lambda ()
	(values product customer prdinshopcart))))))

(defun createwidgetsforprddetailsforguestcustomer (modelfunc)
  (multiple-value-bind (product customer prdinshopcart) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (product-card-with-details-for-customer product customer prdinshopcart)))))
      (list widget1))))


(defun dod-controller-prd-details-for-guest-customer ()
  (with-mvc-ui-page "Product Details" createmodelforprddetailsforguestcustomer createwidgetsforprddetailsforguestcustomer :role :customer))


(defun createmodelforprddetailsforcustomer ()
  (let* ((prd-id (parse-integer (hunchentoot:parameter "id")))
	 (productlist (if (> prd-id 0) (hunchentoot:session-value :login-prd-cache)))
	 (lstshopcart (hunchentoot:session-value :login-shopping-cart))
	 (numitemsincart (Length lstshopcart))
	 (product (if (> prd-id 0) (search-item-in-list 'row-id prd-id productlist)))
	 (prdincart-p (prdinlist-p (slot-value product 'row-id)  lstshopcart))
	 (customer (get-login-customer))
	 (company (product-company product))
	 (description (slot-value product 'description))   
	 (product-sku (slot-value product 'sku))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (product-pricing (select-product-pricing-by-product-id prd-id company))
	 (product-pricing-widget (cl-who:with-html-output-to-string  (*standard-output* nil)
				   (product-price-with-discount-widget product product-pricing)))
	 (prd-name (slot-value product 'prd-name))
	 (product-images-carousel (cl-who:with-html-output-to-string  (*standard-output* nil)
				    (render-multiple-product-images prd-name imageslst images-str)))
	 (product-images-thumbnails (cl-who:with-html-output-to-string  (*standard-output* nil)
				  (render-multiple-product-thumbnails prd-name imageslst images-str)))
	 (proddetailpagetempl (funcall (nst-get-cached-product-template-func :templatenum 1)))	 
	 (qtyperunit-str  (format nil "~A" (slot-value product 'qty-per-unit)))
	 (unit-of-measure (slot-value product 'unit-of-measure))
	 (unitsinstock-str (format nil "~A" (slot-value product 'units-in-stock)))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (addtocart-widget (cl-who:with-html-output-to-string  (*standard-output* nil)
			     (customer-add-to-cart-widget units-in-stock product product-pricing prd-id prdincart-p numitemsincart)))
	 (external-url (slot-value product 'external-url))
	 (subscribe-flag (slot-value product 'subscribe-flag))
	 (cust-type (slot-value customer 'cust-type))
	 (prd-vendor (product-vendor product))
	 (vendor-name (slot-value prd-vendor 'name))
	 (subscription-plan (slot-value company 'subscription-plan))
	 (cmp-type (slot-value company 'cmp-type))
	 (vendor-id (slot-value prd-vendor 'row-id)))
    
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product Name%" proddetailpagetempl prd-name))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Qty-Per-Unit%" proddetailpagetempl qtyperunit-str))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Unit-Of-Measure%" proddetailpagetempl unit-of-measure))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-SKU%" proddetailpagetempl product-sku))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Description%" proddetailpagetempl description))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Units-In-Stock%" proddetailpagetempl unitsinstock-str))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Add-to-Cart-Button%" proddetailpagetempl addtocart-widget))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Pricing-Control%" proddetailpagetempl product-pricing-widget))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Images-Carousel%" proddetailpagetempl product-images-carousel))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Images-Thumbnails%" proddetailpagetempl product-images-thumbnails))
    
    (function (lambda ()
      (values proddetailpagetempl  prd-id  cmp-type subscribe-flag cust-type subscription-plan external-url  vendor-id vendor-name)))))


(defun customer-add-to-cart-widget (units-in-stock product product-pricing prd-id prdincart-p numitemsincart)
  :description "Create the HTML required for Add to Cart button"
  (let ((idsubmitevent (format nil "idprdaddtocart~A~A" prd-id (gensym))))
  (cl-who:with-html-output (*standard-output* nil)   
    (with-catch-submit-event idsubmitevent
      (with-html-div-row
	(if  prdincart-p 
	     (cl-who:htm
	      (with-html-div-col-6 :data-bs-toggle "tooltip" :title "Added to Cart"
		(:a :class "btn btn-sm btn-success" :role "button"  :onclick "return false;" :href (format nil "javascript:void(0);")(:i :class "fa-solid fa-check"))))
	     ;; else 
	     (if (and units-in-stock (> units-in-stock 0))
		   (cl-who:htm
		    (with-html-div-col-6 :data-bs-toggle "tooltip" :title "Add to Cart" 
		      (:button  :data-bs-toggle "modal" :data-bs-target (format nil "#producteditqty-modal~A" prd-id)  :href "#"   :class "add-to-cart-btn" :onclick "addtocartclick(this.id);" :id (format nil "btnaddproduct_~A" prd-id) :name (format nil "btnaddproduct~A" prd-id)  "Add to cart&nbsp; " (:i :class "fa-solid fa-plus"))
		      (modal-dialog-v2 (format nil "producteditqty-modal~A" prd-id) (cl-who:str (format nil "Edit Product Quantity - Available: ~A" units-in-stock)) (product-qty-add-html product product-pricing))))
		   ;; else
		   (cl-who:htm
		    (with-html-div-col-6 :data-bs-toggle "tooltip" :title "Out of Stock" 
		      (:h5 (:span :class "label label-danger" "Out Of Stock"))))))
	;; add a buy now button here
	  (if (> numitemsincart 0)
	      (cl-who:htm
	       (with-html-div-col-6 :style "align: right;" 
		 (:a :class "btn btn-sm btn-primary " :href "dodcustshopcart" :style "font-weight: bold; font-size: 20px !important;" "Go to Cart " (:i :class "fa-solid fa-cart-shopping") (:span :class "position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" (cl-who:str (format nil "~A" numitemsincart))))))))))))
  
  
(defun createwidgetsforprddetailsforcustomer (modelfunc)
  (multiple-value-bind (proddetailpagetempl  prd-id  cmp-type subscribe-flag cust-type subscription-plan external-url  vendor-id vendor-name ) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)        
		       (with-html-div-row :style "border-radius: 5px;background-color:#e6f0ff; border-bottom: solid 1px; margin: 15px; padding: 10px; height: 35px; font-size: 1rem;background-image: linear-gradient(to top, #accbee 0%, #e7f0fd 100%);"
			 (with-html-div-col-2 :data-bs-toggle "tooltip" :title "Back to Shopping"
			   (:a  :href "/hhub/dodcustindex" (:i :class "fa-solid fa-arrow-left")))
			 (with-html-div-col-2 
			   ;; display the subscribe button under certain conditions. 
			   (when (and (equal subscribe-flag "Y")
				      (com-hhub-attribute-company-prdsubs-enabled subscription-plan cmp-type) 
				      (equal cust-type "STANDARD"))
			     (cl-who:htm
			      (:button :data-bs-toggle "modal" :data-bs-target (format nil "#productsubscribe-modal~A" prd-id)  :href "#"   :class "subscription-btn" :id (format nil "btnsubscribe~A" prd-id) :name (format nil "btnsubscribe~A" prd-id) "Subscribe&nbsp;" (:i :class "fa-solid fa-hand-point-up"))
			      (modal-dialog-v2 (format nil "productsubscribe-modal~A" prd-id) "Subscribe Product/Service" (product-subscribe-html prd-id)))))
			 (with-html-div-col-2
			   (when external-url
			     (cl-who:htm
			    (:div  :data-toggle "tooltip" :title "Share Product"
				   (:a :id "idshareexturl" :href "#" (:i :class  "fa-solid fa-arrow-up-from-bracket")))
			    (sharetextorurlonclick "#idshareexturl" (parenscript:lisp external-url)))))

			 (with-html-div-col-2 :data-toggle "tooltip" :title "Contact Seller"  
			   (:a :data-bs-toggle "modal" :data-bs-target (format nil "#vendordetails-modal~A" vendor-id)  :href "#" :name "btnvendormodal"  (cl-who:str vendor-name))
			       (modal-dialog-v2 (format nil "vendordetails-modal~A" vendor-id) (cl-who:str (format nil "Vendor Details")) (modal.vendor-details vendor-id)))

			 (with-html-div-col-3 :data-toggle "tooltip" :title "Visit Store"  
			   (:p (:a :href (format nil "hhubcustvendorstore?id=~A" vendor-id) (:i :class "fa-solid fa-store") (cl-who:str (format nil "&nbsp;~A Store" vendor-name))))))
		       (:hr)))))
	  (widget2  (function (lambda ()
		     (product-card-with-details-for-customer2  proddetailpagetempl )))))
      (list widget1  widget2))))

(defun dod-controller-prd-details-for-customer ()
   (with-cust-session-check 
     (with-mvc-ui-page "Product Details Customer" createmodelforprddetailsforcustomer createwidgetsforprddetailsforcustomer :role :customer)))

(defun dod-controller-customer-search-vendor ()
  (with-cust-session-check
    (let* ((company (get-login-customer-company))
	   (search-clause (hunchentoot:parameter "vendorlivesearch"))
	   (vendorlist (if (not (equal "" search-clause)) (select-vendors-by-name search-clause company))))
      (cl-who:with-html-output (*standard-output* nil)
	;;(logiamhere (format nil "I am in vendor search. Result = ~d vendors" (length vendorlist)))
	(cl-who:str (display-vendors-widget vendorlist))))))


(defun createmodelforcustomerindexpage ()
  (let* ((lstshopcart (hunchentoot:session-value :login-shopping-cart))
	 (lstcount (length lstshopcart))
	 (lstprodcatg (hunchentoot:session-value :login-prdcatg-cache))
	 (catgcount (length lstprodcatg))
	 (selectedcatg (nth (random catgcount) lstprodcatg))
	 (selectedcatgid (slot-value selectedcatg 'row-id))
	 (selectedcatgname (slot-value selectedcatg 'catg-name))
	 (lstproducts (hunchentoot:session-value :login-prd-cache))
	 (company (get-login-customer-company))
	 (lstvendors (select-vendors-for-company company))
	 (activevendor (hunchentoot:session-value :login-active-vendor))
	 (prdcount (length lstproducts))
	 (first100products (if (> prdcount 100) (subseq lstproducts 0 100))))
    (function (lambda ()
      (values lstshopcart lstproducts lstcount lstprodcatg  selectedcatgid selectedcatgname  lstvendors activevendor prdcount first100products)))))
    
	 
(defun createwidgetsforcustomerindexpage (modelfunc)
  (multiple-value-bind
	(lstshopcart lstproducts lstcount lstprodcatg  selectedcatgid selectedcatgname  lstvendors activevendor prdcount first100products)
      (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		     (shopping-cart-widget lstcount "dodcustshopcart"))))
	   (widget2 (function (lambda ()
		      (unless activevendor
			(display-products-carousel 4 (hunchentoot:session-value :login-prd-cache))))))
	   (widget3 (function (lambda ()
		      (unless activevendor
			(cl-who:with-html-output (*standard-output* nil)
			  (:span (:h5 "Top Vendors"))
			  (with-html-search-form "idsearchvendors" "searchvendors" "idvendorlivesearch" "vendorlivesearch" "hhubcustvendorsearch" "onkeyupsearchform1event();" "Vendor Store Search..."
			    (submitsearchform1event-js "#idvendorlivesearch" "#vendorlivesearchresult"))
			  (cl-who:str (display-vendors-widget lstvendors))
			  (:hr)))
		      (when activevendor
			(cl-who:with-html-output (*standard-output* nil)
		       	  (:span (:h5 (cl-who:str (format nil "You are now in ~A Store" (slot-value activevendor 'name)))))
			  (cl-who:str (display-vendors-widget (list activevendor)))
			  (:hr))))))
	   (widget4 (function (lambda ()
		      (ui-list-prod-catg lstprodcatg))))
	   (widget5 (function (lambda ()
		      (display-products-by-category-widget selectedcatgid selectedcatgname))))
	   
	   (widget6 (function (lambda ()
		      (product-search-widget lstcount)
		      (if (> prdcount 100)
			  (cl-who:with-html-output (*standard-output* nil :prologue t :indent t)
			    (cl-who:str (ui-list-customer-products first100products lstshopcart)))
			  ;;else
			  (cl-who:with-html-output (*standard-output* nil :prologue t :indent t)
			    (cl-who:str (ui-list-customer-products lstproducts lstshopcart)))))))
	   (widget7 (function (lambda ()
		      (when activevendor (whatsapp-widget (slot-value activevendor 'phone)))))))
	   (list widget1 widget2 widget3 widget4 widget5 widget6 widget7))))


(defun dod-controller-cust-index ()
  (with-cust-session-check
    (with-mvc-ui-page "Welcome Customer" createmodelforcustomerindexpage createwidgetsforcustomerindexpage :role :customer)))
   
(defun shopping-cart-widget (itemscount target)
  (cl-who:with-html-output (*standard-output* nil) 
    (:a :id "floatingcheckoutbutton" :href target :style "font-weight: bold; font-size: 20px !important;"  (:i :class "fa-solid fa-cart-shopping") (:span :class "position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" (cl-who:str (format nil "~A" itemscount))))))

(defun product-search-widget (itemscount)
  (cl-who:with-html-output (*standard-output* nil) 
    (:br)
    (with-html-div-row
      (with-html-div-col-6
	(with-html-search-form "idsearchproducts" "searchproducts" "idprdlivesearch" "prdlivesearch" "dodsearchproducts" "onkeyupsearchform2event();"  "Search Products..."
	  (submitsearchform2event-js "#idprdlivesearch" "#prdlivesearchresult" )))
      ;; Display the My Cart button.
      (with-html-div-col-6 
	(:a :class "btn btn-lg btn-primary btn-block" :href "dodcustshopcart" :style "font-weight: bold; font-size: 20px !important;" "Buy Now " (:i :class "fa-solid fa-cart-shopping") (:span :class "position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" (cl-who:str (format nil "~A" itemscount))))))))

(defun createmodelforcustprodbycatg()
  (let* ((catg-id (parse-integer (hunchentoot:parameter "id")))
	 (lstshopcart (hunchentoot:session-value :login-shopping-cart))
	 (lstproducts (hunchentoot:session-value :login-prd-cache))
	 (lstprodcatg (hunchentoot:session-value :login-prdcatg-cache))
	 (lstprodbycatg (if lstproducts (filter-products-by-category catg-id lstproducts))))
    (function (lambda()
      (values lstshopcart lstprodcatg lstprodbycatg)))))

(defun createwidgetsforcustprodbycatg (modelfunc)
  (multiple-value-bind (lstshopcart lstprodcatg lstprodbycatg) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (shopping-cart-widget (length lstshopcart) "dodcustshopcart"))))
	  (widget2 (function (lambda ()
		     (product-search-widget (length lstshopcart)))))
	  (widget3 (function (lambda ()
		     (ui-list-prod-catg lstprodcatg))))
	  (widget4 (function (lambda ()
		     (ui-list-customer-products lstprodbycatg lstshopcart)))))
      (list widget1 widget2 widget3 widget4)))) 

(defun dod-controller-customer-products-by-category ()
  :documentation "This function lists the customer products by category"
  (with-cust-session-check
    (with-mvc-ui-page "Products by Category" createmodelforcustprodbycatg createwidgetsforcustprodbycatg :role :customer)))
    	


(defun createmodelforcustprodbyvendor ()
  (let* ((vendor-id (parse-integer (hunchentoot:parameter "id")))
	 (vendor (select-vendor-by-id vendor-id))
	 (vphone (slot-value vendor 'phone))
	 (vname (slot-value vendor 'name))
	 (lstshopcart (hunchentoot:session-value :login-shopping-cart))
	 (lstproducts (hunchentoot:session-value :login-prd-cache))
	 (lstprodcatg (hunchentoot:session-value :login-prdcatg-cache))
	 (lstprodbyvendor (if lstproducts (filter-products-by-vendor vendor-id lstproducts))))
    (function (lambda ()
      (values vphone vname lstshopcart lstprodcatg lstprodbyvendor)))))
  
(defun createwidgetsforcustprodbyvendor (modelfunc)
  (multiple-value-bind (vphone vname lstshopcart lstprodcatg lstprodbyvendor) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:span (:h5 (cl-who:str (format nil "You are now in ~A Store" vname))))))))
	  (widget2 (function (lambda ()
		     (shopping-cart-widget (length lstshopcart) "dodcustshopcart"))))
	  (widget3 (function (lambda ()
		     (product-search-widget (length lstshopcart)))))
	  (widget4 (function (lambda ()
		     (ui-list-prod-catg lstprodcatg))))
	  (widget5 (function (lambda ()
		     (ui-list-customer-products lstprodbyvendor lstshopcart))))
	  (widget6 (function (lambda()
		     (whatsapp-widget vphone))))
	  (widget7 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-html-div-row
			 (with-html-div-col-2 "")
			 (with-html-div-col-8
			   (:a :class "btn btn-lg btn-primary btn-block" :href "dodcustshopcart" :style "font-weight: bold; font-size: 20px !important;" "Buy Now " (:i :class "fa-solid fa-cart-shopping") (:span :class "position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" (cl-who:str (format nil "~A" (length lstshopcart))))))
			   (with-html-div-col-2 "")))))))
	  (list widget1 widget2 widget3 widget4 widget5 widget6 widget7))))

(defun dod-controller-customer-products-by-vendor ()
  :documentation "This function lists the customer products by category"
  (with-cust-session-check
    (with-mvc-ui-page "Products by vendor" createmodelforcustprodbyvendor createwidgetsforcustprodbyvendor :role :customer)))

(defun display-products-by-category-widget (catg-id catg-name)
  :documentation "This function lists the customer products by category"
  (let* ((lstproducts (hunchentoot:session-value :login-prd-cache))
	 (lstshopcart (hunchentoot:session-value :login-shopping-cart))
	 (lstprodbycatg (if lstproducts (filter-products-by-category catg-id lstproducts))))
      (cl-who:with-html-output (*standard-output* nil)
	;;(logiamhere (format nil "display-products-by-category-widget catg-id is ~d. Product count is ~d" catg-id (length lstprodbycatg)))
	(:span (:h5 (cl-who:str (format nil "~A" catg-name))))
	(cl-who:str (ui-list-cust-products-horizontal lstprodbycatg lstshopcart))
	(:hr))))


(defun display-vendors-widget (vendorlist)
  :documentation "This function displays all the vendors for the given customers account"
  (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
    (:div :id "vendorlivesearchresult" :class "prd-vendors-container" :style "width: 100%; display:flex; overflow:auto;"
	  ;;(:div :id "vendorlivesearchresult" 
		(with-html-div-row  :style "padding: 30px 20px; display: flex; align-items:center; justify-content:center; flex-wrap: nowrap;"  
		  (mapcar (lambda (vendor)
			    (cl-who:htm (:div :class "vendor-card" (vendor-card vendor)))) vendorlist)))))

(defun createmodelforcustshowshopcart ()
  (let* ((lstshopcart (hunchentoot:session-value :login-shopping-cart))
	 (lstcount (length lstshopcart))
	 (prd-cache (hunchentoot:session-value :login-prd-cache))
	 (total  (get-shop-cart-total lstshopcart))
	 (products (mapcar (lambda (odt)
			     (let ((prd-id (slot-value odt 'prd-id)))
			       (search-item-in-list 'row-id prd-id prd-cache ))) lstshopcart)))
    (function (lambda ()
      (values lstshopcart lstcount  total products)))))
      
(defun createwidgetsforcustshowshopcart (modelfunc)
  (multiple-value-bind (lstshopcart lstcount  total products) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (with-customer-breadcrumb))))
	  (widget2 (function (lambda ()
		     (when (> lstcount 0)
		       ;; Need to select the order details instance here instead of product instance. Also, ui-list-shop-cart should be based on order details instances. 
		       ;; This function is responsible for displaying the shopping cart. 
		       (cl-who:with-html-output (*standard-output* nil)
			 (with-html-div-row (:br))
			 (with-html-div-row
			   (:div :class "col-6"
				 (:h3 (cl-who:str (format nil "Shopping Cart - ~A Items" (length products))))))
			 (with-html-div-row
			   (:div :class "col-6" 
				 (cl-who:htm  (:a :class "btn btn-primary" :role "button" :href "/hhub/dodcustindex" "Back To Shopping"  ))))
			 (:hr)
			 (with-html-div-row
			   (with-html-div-col-6
				 (:h4 (:span :class "label label-default" (cl-who:str (format nil "Total = ~A ~$" *HTMLRUPEESYMBOL* total)))))
			   (with-html-div-col-6 :style "align: right;" 
			     (:a :class "btn btn-lg btn-primary btn-block" :href "dodcustorderaddpage" :style "font-weight: bold; font-size: 20px !important;" "Checkout " (:i :class "fa-solid fa-cart-shopping") (:span :class "position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" (cl-who:str (format nil "~A" lstcount)))))))))))
	  (widget3 (function (lambda ()
		     (if (> lstcount 0)
			 (cl-who:with-html-output (*standard-output* nil :prologue t :indent t)   
			   (cl-who:str (ui-list-shopcart products lstshopcart)))
			 ;;else
			 (show-empty-shopping-cart)))))
	  (widget4 (function (lambda ()
		     (submitformevent-js "#idcustshoppingcartitems"))))
	  (widget5 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil) 
			(with-html-div-row
			  (with-html-div-col-6
				(cl-who:htm  (:a :class "btn btn-primary" :role "button" :href "/hhub/dodcustindex" "Back To Shopping" )))
			  (with-html-div-col-6 :style "align: right;" 
			     (:a :class "btn btn-lg btn-primary btn-block" :href "dodcustorderaddpage" :style "font-weight: bold; font-size: 20px !important;" "Checkout " (:i :class "fa-solid fa-cart-shopping") (:span :class "position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" (cl-who:str (format nil "~A" lstcount)))))))))))
      (list widget1 widget2 widget3 widget4 widget5))))
	    
(defun dod-controller-cust-show-shopcart ()
    :documentation "This is a function to display the shopping cart."
    (with-cust-session-check 
      (with-mvc-ui-page "Customer Shopcart" createmodelforcustshowshopcart createwidgetsforcustshowshopcart :role :customer)))
     

(defun show-empty-shopping-cart ()
  (cl-who:with-html-output (*standard-output* nil :prologue t :indent t)   
    (with-html-div-row
      (with-html-div-col 
	(:h4 "0 items in shopping cart") 
	(:a :class "btn btn-primary"  :role "button" :href "/hhub/dodcustindex" (:i :class "fa-solid fa-arrow-left"))))))


(defun createmodelforremoveshopcartitem ()
  (let ((action (hunchentoot:parameter "action"))
	(prd-id (parse-integer (hunchentoot:parameter "id")))
	(myshopcart (hunchentoot:session-value :login-shopping-cart))
	(redirectlocation "/hhub/dodcustshopcart"))
    (if (equal action "remitem" ) (setf (hunchentoot:session-value :login-shopping-cart) (remove (search-item-in-list 'prd-id  prd-id  myshopcart  ) myshopcart)))
    (when (= (length (hunchentoot:session-value :login-shopping-cart)) 0)
      (setf (hunchentoot:session-value :login-active-vendor) nil))
    (function (lambda ()
      (values redirectlocation)))))

(defun createwidgetsforremoveshopcartitem (modelfunc)
  (multiple-value-bind (redirectlocation) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     redirectlocation))))
      (list widget1))))

(defun dod-controller-remove-shopcart-item ()
    :documentation "This is a function to remove an item from shopping cart."
    (with-cust-session-check
      (let ((uri (with-mvc-redirect-ui createmodelforremoveshopcartitem createwidgetsforremoveshopcartitem)))
	(format nil "~A" uri))))

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
	      (company-exturl (if customer-company (slot-value customer-company 'external-url)))
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
	     (setf (hunchentoot:session-value :login-prd-cache) (select-products-by-company customer-company))
	     (setf (hunchentoot:session-value :login-prdcatg-cache) (select-prdcatg-by-company customer-company))
	     (unless (equal customer-tenant-id *HHUB-DEMO-TENANT-ID*)
	       (hunchentoot:set-cookie "community-url" :value company-exturl :expires (+ (get-universal-time) 10000000) :path "/")
	       (hunchentoot:set-cookie "community-name" :value customer-company-name :path "/" :expires (+ (get-universal-time) 10000000))))))
     
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
	  (hunchentoot:set-cookie "community-url" :value (format nil "~A/hhub/dascustloginasguest?tenant-id=~A" *siteurl* (get-login-cust-tenant-id)) :expires (+ (get-universal-time) 10000000) :path "/")
	  ))
      )

        ; Handle this condition
   
      (clsql:sql-database-data-error (condition)
	  (if (equal (clsql:sql-error-error-id condition) 2006 ) (progn
								   (stop-das) 
								   (start-das)
								   ;;(clsql:reconnect :database *dod-db-instance*)
								   (hunchentoot:redirect "/hhub/customer-login.html"))))))

(defun dod-cust-login-with-otp (&key phone)
  (handler-case 
					;expression
      (let* ((customer (car (clsql:select 'dod-cust-profile :where [and
					  [= [:phone] phone]
					  [= [:cust-type] "STANDARD"]
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
	  (hunchentoot:set-cookie "community-url" :value (format nil "~A/hhub/dascustloginasguest?tenant-id=~A" *siteurl* (get-login-cust-tenant-id)) :expires (+ (get-universal-time) 10000000) :path "/")
	  1))
    ;; Handle this condition
    (clsql:sql-database-data-error (condition)
      (when (equal (clsql:sql-error-error-id condition) 2006 )
	(stop-das) 
	(start-das)
	(hunchentoot:redirect "/hhub/customer-login.html")))))








 ;     (clsql:sql-fatal-error (errorinst) (if (equal (clsql:sql-error-database-message errorinst) "Database is closed.") 
;					     (progn (clsql:stop-sql-recording :type :both)
;					            (clsql:disconnect) 
;						    (crm-db-connect :servername *crm-database-server* :strdb *crm-database-name* :strusr *crm-database-user*  :strpwd *crm-database-password* :strdbtype :mysql)
;(hunchentoot:redirect "/hhub/customer-login.html"))))))
      








