;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


(defun dod-controller-make-payment-request-html ()
  (let* ((customer (get-login-customer))
	 (company (get-login-customer-company))
	 (amount (hunchentoot:parameter "amount"))
	 (wallet-id (hunchentoot:parameter "wallet-id"))
	 (wallet (if wallet-id (get-cust-wallet-by-id wallet-id company)))
	 (vendor (if wallet (get-vendor wallet)))
	 (order-id (hunchentoot:parameter "order_id"))
	 (description  "This is test description")
	 (mode (hunchentoot:parameter "mode"))
	 (currency "INR")
	 (customer-type (slot-value customer 'cust-type))
	 (customer-name (slot-value customer 'name))
	 (customer-email (slot-value customer 'email))
	 (customer-phone (slot-value customer 'phone))
	 (customer-city (slot-value customer 'city))
	 (payment-api-key (slot-value vendor 'payment-api-key))
	 (payment-api-salt (slot-value vendor 'payment-api-salt))
	 (customer-country "India")
	 (customer-zipcode (slot-value customer 'zipcode))
	 (udf1 wallet-id)
	 (udf2 customer-type)
	 (udf3 "not used" )
	 (udf4 "not used")
	 (udf5 "not used")
	 (show-convenience-fee "Y")
	 (payment-options "cc,nb,w,atm,upi,dp")
	 (return-url (format nil "~A?~A" *PAYGATEWAYRETURNURL* (format nil "~A=~A" (hunchentoot:session-cookie-name *current-customer-session*) (hunchentoot:url-encode (hunchentoot:session-cookie-value hunchentoot:*session*))))) 
	 (return-url-cancel (format nil "~A?~A" *PAYGATEWAYCANCELURL* (format nil "~A=~A" (hunchentoot:session-cookie-name *current-customer-session*) (hunchentoot:url-encode (hunchentoot:session-cookie-value hunchentoot:*session*)))))  
	 (return-url-failure (format nil "~A?~A" *PAYGATEWAYFAILUREURL*  (format nil "~A=~A" (hunchentoot:session-cookie-name *current-customer-session*) (hunchentoot:url-encode (hunchentoot:session-cookie-value hunchentoot:*session*)))))
	 (param-names (list "amount" "api_key" "city" "country" "currency" "description" "email" "mode"  "name" "order_id" "phone" "return_url" "show_convenience_fee" "return_url_cancel" "return_url_failure" "udf1" "udf2" "udf3" "udf4" "udf5"  "zip_code" "payment_options"))
	 (param-values (list amount payment-api-key customer-city customer-country currency description customer-email mode  customer-name order-id  customer-phone return-url show-convenience-fee return-url-cancel return-url-failure udf1 udf2 udf3 udf4 udf5 customer-zipcode payment-options))
	 (params-alist (pairlis param-names param-values))
	 (hash (generatehashkey  params-alist  payment-api-salt  :sha512)))

    
	 
    (setf (hunchentoot:session-value :payment-hash ) hash)
    					;do something
    (with-standard-customer-page  "Payment Request"
      (:form :class "form-makepaymentrequest" :role "form" :method "POST" :action "https://pay.basispay.in/v2/paymentrequest";;https://biz.traknpay.in/v2/paymentrequest"
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:h5 (cl-who:str (format nil "For Vendor: ~A" (slot-value vendor 'name))))
		  (:h5 (cl-who:str (format nil "Amount  ~A. ~A" currency amount))))
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:div :class "form-group" 
			  (:input :class "form-control" :type "hidden" :value amount :name "amount") 
			  (:input :class "form-control" :type "hidden" :value payment-api-key  :name "api_key") 
			  (:input :class "form-control" :type "hidden" :value order-id :name "order_id") 
			  (:input :class "form-control" :type "hidden" :value mode :name "mode") ; Change this to LIVE for real payment request. 
			  (:input :class "form-control" :type "hidden" :value currency :name "currency")
			  (:input :class "form-control" :type "hidden" :value description :name "description")
			  (:input :class "form-control" :type "hidden" :value customer-name :name "name")
			  (:input :class "form-control" :type "hidden" :value customer-email :name "email")
			  (:input :class "form-control" :type "hidden" :value customer-phone :name "phone")
			  (:input :class "form-control" :type "hidden" :value customer-city :name "city")
			  (:input :class "form-control" :type "hidden" :value customer-country :name "country")
			  (:input :class "form-control" :type "hidden" :value hash :name "hash") 
			  (:input :class "form-control" :type "hidden" :value customer-zipcode :name "zip_code")
			  (:input :class "form-control" :type "hidden" :value udf1 :name "udf1")
			  (:input :class "form-control" :type "hidden" :value udf2 :name "udf2")
			  (:input :class "form-control" :type "hidden" :value udf3 :name "udf3")
			  (:input :class "form-control" :type "hidden" :value udf4 :name "udf4")
			  (:input :class "form-control" :type "hidden" :value udf5 :name "udf5")
			  (:input :class "form-control" :type "hidden" :value show-convenience-fee :name "show_convinience_fee")
			  (:input :class "form-control" :type "hidden" :value return-url-failure :name "return_url_failure")
			  (:input :class "form-control" :type "hidden" :value return-url-cancel :name "return_url_cancel")
			  (:input :class "form-control" :type "hidden" :value return-url :name "return_url")
			  (:input :class "form-control" :type "hidden" :value payment-options :name "payment_options")
			  ))) 
      (:div :class "row"
	    (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
		  (:div :class "form-group"
			(:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Confirm"))))))))
	

(defun make-payment-request-html (amount wallet-id mode order-id guestemail)
  (let* ((customer (get-login-customer))
	 (company (get-login-customer-company))
	 (wallet (if wallet-id (get-cust-wallet-by-id wallet-id company)))
	 (vendor (if wallet (get-vendor wallet)))
	 (description  "This is test description")
	 (currency "INR")
	 (customer-type (slot-value customer 'cust-type))
	 (customer-name (slot-value customer 'name))
	 (customer-email (if (equal customer-type "STANDARD") (slot-value customer 'email) guestemail))
	 (customer-phone (slot-value customer 'phone))
	 (customer-city (slot-value customer 'city))
	 (payment-api-key (slot-value vendor 'payment-api-key))
	 (payment-api-salt (slot-value vendor 'payment-api-salt))
	 (customer-country "India")
	 (customer-zipcode (slot-value customer 'zipcode))
	 (udf1 wallet-id)
	 (udf2 customer-type)
	 (udf3 "not used" )
	 (udf4 "not used")
	 (udf5 "not used")
	 (show-convenience-fee "Y")
	 (payment-options "cc,nb,w,atm,upi,dp")
	 (return-url (format nil "~A?~A" *PAYGATEWAYRETURNURL* (format nil "~A=~A" (hunchentoot:session-cookie-name *current-customer-session*) (hunchentoot:url-encode (hunchentoot:session-cookie-value hunchentoot:*session*))))) 
	 (return-url-cancel (format nil "~A?~A" *PAYGATEWAYCANCELURL* (format nil "~A=~A" (hunchentoot:session-cookie-name *current-customer-session*) (hunchentoot:url-encode (hunchentoot:session-cookie-value hunchentoot:*session*)))))  
	 (return-url-failure (format nil "~A?~A" *PAYGATEWAYFAILUREURL*  (format nil "~A=~A" (hunchentoot:session-cookie-name *current-customer-session*) (hunchentoot:url-encode (hunchentoot:session-cookie-value hunchentoot:*session*)))))
	 (param-names (list "amount" "api_key" "city" "country" "currency" "description" "email" "mode"  "name" "order_id" "phone" "return_url" "show_convenience_fee" "return_url_cancel" "return_url_failure" "udf1" "udf2" "udf3" "udf4" "udf5"  "zip_code" "payment_options"))
	 (param-values (list amount payment-api-key customer-city customer-country currency description customer-email mode  customer-name order-id  customer-phone return-url show-convenience-fee return-url-cancel return-url-failure udf1 udf2 udf3 udf4 udf5  customer-zipcode payment-options))
	 (params-alist (pairlis param-names param-values))
	 (hash (generatehashkey  params-alist  payment-api-salt  :sha512)))
	 
	 
    (setf (hunchentoot:session-value :payment-hash ) hash)
    					;do something
    (cl-who:with-html-output-to-string (*standard-output* nil)
      (:form :class "form-makepaymentrequest" :role "form" :method "POST" :action "https://pay.basispay.in/v2/paymentrequest"
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:h5 (cl-who:str (format nil "For Vendor: ~A" (slot-value vendor 'name))))
		  (:h5 (cl-who:str (format nil "Amount  ~A. ~A" currency amount))))
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:div :class "form-group" 
			  (:input :class "form-control" :type "hidden" :value amount :name "amount") 
			  (:input :class "form-control" :type "hidden" :value payment-api-key  :name "api_key") 
			  (:input :class "form-control" :type "hidden" :value order-id :name "order_id") 
			  (:input :class "form-control" :type "hidden" :value mode :name "mode") ; Change this to LIVE for real payment request. 
			  (:input :class "form-control" :type "hidden" :value currency :name "currency")
			  (:input :class "form-control" :type "hidden" :value description :name "description")
			  (:input :class "form-control" :type "hidden" :value customer-name :name "name")
			  (:input :class "form-control" :type "hidden" :value customer-email :name "email")
			  (:input :class "form-control" :type "hidden" :value customer-phone :name "phone")
			  (:input :class "form-control" :type "hidden" :value customer-city :name "city")
			  (:input :class "form-control" :type "hidden" :value customer-country :name "country")
			  (:input :class "form-control" :type "hidden" :value hash :name "hash") 
			  (:input :class "form-control" :type "hidden" :value customer-zipcode :name "zip_code")
			  (:input :class "form-control" :type "hidden" :value udf1 :name "udf1")
			  (:input :class "form-control" :type "hidden" :value udf2 :name "udf2")
			  (:input :class "form-control" :type "hidden" :value udf3 :name "udf3")
			  (:input :class "form-control" :type "hidden" :value udf4 :name "udf4")
			  (:input :class "form-control" :type "hidden" :value udf5 :name "udf5")
			  (:input :class "form-control" :type "hidden" :value show-convenience-fee :name "show_convinience_fee")
			  (:input :class "form-control" :type "hidden" :value return-url-failure :name "return_url_failure")
			  (:input :class "form-control" :type "hidden" :value return-url-cancel :name "return_url_cancel")
			  (:input :class "form-control" :type "hidden" :value payment-options :name "payment_options")
			  (:input :class "form-control" :type "hidden" :value return-url :name "return_url")))) 
      (:div :class "row"
	    (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
		  (:div :class "form-group"
			(:span :class "input-group-btn" (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Place Order" )))))))))
		
	





(defun dod-controller-customer-payment-successful-page ()
  :documentation "This page is called by the Payment Gateway when the payment is successful and the PG redirects to Nine Stores" 
  (let* ((transaction-id (hunchentoot:parameter "transaction_id"))
	 (company (get-login-customer-company))
	 (payment-method (hunchentoot:parameter "payment_method"))
	 (payment-datetime (hunchentoot:parameter "payment_datetime"))
	 (response-code  (hunchentoot:parameter "response_code"))
	 (response-message (hunchentoot:parameter "response_message"))
	 (error-desc (hunchentoot:parameter "error_desc"))
	 (order-id (hunchentoot:parameter "order_id"))
	 (amount (with-input-from-string (in (hunchentoot:parameter "amount")) (read in)))
	 (currency (hunchentoot:parameter "currency"))
	 (description (hunchentoot:parameter "description"))
	 (customer-name (hunchentoot:parameter "name"))
	 (customer-email (hunchentoot:parameter "email"))
	 (customer-phone (hunchentoot:parameter "phone"))
	 (customer-city (hunchentoot:parameter "city"))
	 (customer-state (hunchentoot:parameter "state"))
	 (customer-country (hunchentoot:parameter "country"))
	 (customer-zipcode (hunchentoot:parameter "zip_code"))
	 (udf1 (parse-integer (hunchentoot:parameter "udf1")))
	 (wallet (get-cust-wallet-by-id udf1 company))
	 (vendor (get-vendor wallet))
	 (payment-api-salt (slot-value vendor 'payment-api-salt))
	 (udf2 (hunchentoot:parameter "udf2"))
	 ;; (udf3 (hunchentoot:parameter "udf3"))
	 ;; (udf4 (hunchentoot:parameter "udf4"))
	 ;; (udf5 (hunchentoot:parameter "udf5"))
	 (tdr-amount (hunchentoot:parameter "tdr_amount"))
	 (tax-on-tdr-amount (hunchentoot:parameter "tax_on_tdr_amount"))
	 (amount-orig (hunchentoot:parameter "amount_orig"))
	 (show-convenience-fee (hunchentoot:parameter "show_convenience_fee"))
	 (cardmasked (hunchentoot:parameter "cardmasked"))
	 (received-hash (hunchentoot:parameter "hash"))
	 (postparams (hunchentoot:post-parameters*))
	 (params-alist  (remove (find "hash" postparams :test #'equal :key #'car) postparams))
	 (calculated-hash (hashcalculate   params-alist  payment-api-salt  :sha512))
					; create the pending order if the order_id matches with what we saved in the order params cache.
	 (order-params (funcall 'get-cust-order-params))
	 (order-cxt (nth 22 order-params)))

    (declare (ignore customer-name customer-email customer-phone customer-city customer-state customer-country customer-zipcode tdr-amount tax-on-tdr-amount amount-orig show-convenience-fee cardmasked))
	
   ;;;;;;;;;;;;;;;;;;;;;;;;;;DEBUGGING PURPOSES ;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Print all the post params. 
    ;; Update customer's wallet first
  ; (hunchentoot:log-message* :info  (format nil "params count =  ~A" (length params-alist)))
   ;(loop for (a . b) in params-alist 
;	   do (hunchentoot:log-message* :info  (format nil "param is ~a: ~a" a b)))
 ; (hunchentoot:log-message* :info  (format nil "rec-hash is ~A" received-hash))
 ; (hunchentoot:log-message* :info  (format nil "cal-hash is ~A" calculated-hash ))
  (when (and (equal (parse-integer response-code) 0)
	 (equal received-hash calculated-hash)) ; (responsehashcheck postparams  payment-api-salt :sha512)
  	
    (progn
      (create-payment-trans order-id amount currency description (get-login-customer) vendor payment-method transaction-id (parse-integer response-code) response-message error-desc company) 
      (if (equal udf2 "STANDARD") (update-cust-wallet-balance amount udf1))
      (if (equal order-id order-cxt) (hunchentoot:redirect (format nil "/hhub/dodmyorderaddaction?order_cxt=~A" order-cxt)))
					; Display a success page. 
	 (with-standard-customer-page (:title "Payment Successful" ) 
	      (:div :class "row" 
		    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
			  (:h4 (cl-who:str (format nil "Payment Successful for vendor: ~A" (slot-value vendor 'name))))))
				 
	      (:div :class "row" 
		    (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
			  (:h5 (cl-who:str (format nil "Transaction ID: ~A" transaction-id)))) 
		    (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
			  (:h5 (cl-who:str (format nil "Payment Mode: ~A" payment-method)))))
	      (:div :class "row" 
		    (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
			  (:h5 (cl-who:str (format nil "Response Message: ~A" response-message))))
		    (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
			  (:h5 (cl-who:str (format nil "Payment Date: ~A" payment-datetime)))))
	      (if (equal udf2 "STANDARD") (cl-who:htm (:div :class "row" 
		    (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
			  (:h5 (cl-who:str (format nil "Amount recharged: ~A.~A" currency amount))))
		    (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
			  (:h5 (cl-who:str (format nil "Wallet Balance: ~A" (+ amount (slot-value wallet 'balance))))))))))))))
	

(defun dod-controller-customer-payment-failure-page ()
  (if (is-dod-cust-session-valid?)
      (with-standard-customer-page (:title "Payment Failure! " ) 
	(:div :class "row" 
	      (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		    (:h4 "Payment Failure! Please contact your System Administrator or try after some time."))))
       (hunchentoot:redirect "/hhub/hhubcustloginv2")))



(defun dod-controller-customer-payment-cancel-page ()
  (if (is-dod-cust-session-valid?)
      (with-standard-customer-page (:title "Payment Cancelled! " ) 
	(:div :class "row" 
	      (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		    (:h4 "Payment Cancelled."))))
       (hunchentoot:redirect "/hhub/hhubcustloginv2")))
