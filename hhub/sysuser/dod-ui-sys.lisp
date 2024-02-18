;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(defvar *logged-in-users* nil)
(defvar *current-user-session* nil)

(defun hhub-controller-permission-denied ()
  (let ((message (hunchentoot:parameter "message")))
    (with-no-navbar-page "Permission Denied"
      (with-html-div-row (:h4 "Permission Denied"))
      (html-back-button)
      (jscript-displayerror message))))


(defun dod-controller-OTP-request-page ()
  (let ((phone (hunchentoot:parameter "phone")))
    (with-no-navbar-page-v2  "OTP Page"
      (:br)
      (:div :class "account-wall" :align "center"
      (with-html-card "/img/logo.png" "" "" (cl-who:str (format nil "OTP has been sent to your phone ~A" (concatenate 'string "xxxxx" (subseq phone 6))))
	(with-html-form  "form-hhubotppage" "hhubotpsubmitaction" 
	  ;;(:img :class "profile-img" :src "/img/logo.png" :alt "")
	  (:div :id "withCountDownTimerExpired"
		(with-html-input-text-hidden "phone" phone)
		(with-html-input-password "otp" "" "Enter OTP" nil T "Please enter OTP" "1")
		(:p :id "withCountDownTimer" :style "color: crimson;")
		(:div :class "form-group"
		      (:button :class "submit center-block btn btn-primary btn-block" :type "submit" "Send OTP"))))
	(with-html-form  "form-hhubotpresendpage" "hhubotpregenerateaction"
	  (:div :class "form-group"
		(with-html-input-text-hidden "phone" phone)
		(:button :class "submit center-block btn btn-primary btn-block" :type "submit" (cl-who:str  (format nil "Regenerate OTP for ~A " (concatenate 'string "xxxxx" (subseq phone 6))))))))
	(hhub-html-page-footer)
      (:script "window.onload = function() {countdowntimer(0,0,2,0);}")))))

(defun dod-controller-otp-submit-action ()
  (let ((otp (hunchentoot:parameter "otp"))
	(context (hunchentoot:session-value :sessioncontext))
	(sessionotp (hunchentoot:session-value :genericotp)))
    ;;(hunchentoot:log-message* :info (format nil "context is ~A otp is ~A sessionotp is ~A" context otp sessionotp))
    (if (equal (parse-integer otp) sessionotp)
        (hunchentoot:redirect (format nil "/hhub/~A" context))
	;; else
	(progn
	  ;; before redirecting we need to reset the web session. 
	  (hunchentoot:remove-session hunchentoot:*session*)
	  (hunchentoot:redirect *siteurl*)))))
  

(defun dod-controller-otp-regenerate-action ()
  (let ((phone (hunchentoot:parameter "phone"))
	(context (hunchentoot:session-value :sessioncontext)))
	(generateotp&redirect phone context)))
   

(defun generateotp&redirect (phone context)
:description "This function will generate OTP, save it to the session, send SMS to the phone number with OTP message and then redirect to OTP entering page, also remembering the context where to redirect after entering the OTP successfully."
  (let ((otp (random 99999)))
    ;; Set the otp to the session value 
    (setf (hunchentoot:session-value :genericotp ) otp)
    (setf (hunchentoot:session-value :sessioncontext) context)
    ;; Send SMS to the phone with OTP template text 
    (if *HHUBOTPTESTING*
	(hunchentoot:log-message* :info (format nil "sessionotp is ~A" otp))
	;;else 
	(send-sms-notification phone *HHUBAWSSNSSENDERID* (format nil *HHUBAWSSNSOTPTEMPLATETEXT* otp)))
    ;; redirect to the OTP page 
    (hunchentoot:redirect (format nil "/hhub/otppage?phone=~A" phone))))

(defun com-hhub-transaction-suspend-account ()
  :documentation "This is a controller method which will suspend an Account"
  (with-opr-session-check
    (let ((params nil)
	  (tenant-id (hunchentoot:parameter "tenant-id")))
      (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (with-hhub-transaction "com-hhub-transaction-suspend-account" params 
	(suspendaccount tenant-id))
      (hunchentoot:redirect "/hhub/sadminhome"))))

(defun com-hhub-transaction-restore-account ()
  :documentation "This is a controller method which will suspend an Account"
  (with-opr-session-check
    (let ((params nil)
	  (tenant-id (hunchentoot:parameter "tenant-id")))
      (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (with-hhub-transaction "com-hhub-transaction-restore-account" params 
	(restoreaccount tenant-id))
      (hunchentoot:redirect "/hhub/sadminhome"))))


(defun com-hhub-transaction-system-dashboard ()

)


(defun com-hhub-transaction-sadmin-profile ()
 (with-opr-session-check 
    (with-standard-admin-page (:title "welcome to highrisehub")
       (:h3 "Welcome " (cl-who:str (format nil "~a" (get-login-user-name))))
       (:hr)
       (:div :class "list-group col-sm-6 col-md-6 col-lg-6 col-xs-12"
	     (:a :class "list-group-item" :href "#" "Reset Password")
	     (:a :class "list-group-item" :href *HHUBFEATURESWISHLISTURL* "Feature Wishlist")
	     (:a :class "list-group-item" :href *HHUBBUGSURL* "Report Issues")))))

(defun dod-controller-run-daily-orders-batch ()
 :documentation "This controller function is responsible to run the daily orders batch against all the subscriptions customers have made for a particular group/apartment/tenant" 
  (let ((batchresult (run-daily-orders-batch 7)))
    (json:encode-json-to-string batchresult)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-admin-navigation-bar ()
    :documentation "This macro returns the html text for generating a navigation bar using bootstrap."
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "navbar navbar-default navbar-inverse navbar-static-top"
	     (:div :class "container-fluid"
		   (:div :class "navbar-header"
			 (:button :type "button" :class "navbar-toggle" :data-toggle "collapse" :data-target "#navHeaderCollapse"
				  (:span :class "icon-bar")
				  (:span :class "icon-bar")
				  (:span :class "icon-bar"))
			 (:a :class "navbar-brand" :href "#" :title "HighriseHub" (:img :style "width: 30px; height: 30px;" :src "/img/logo.png" )  ))
		   (:div :class "collapse navbar-collapse" :id "navHeaderCollapse"
			 (:ul :class "nav navbar-nav navbar-left"
			      (:li :class "active" :align "center" (:a :href "/hhub/sadminhome"  (:i :class "fa-solid fa-house")  "&nbsp;Home"))
			      (:li  (:a :href "/hhub/dasabacsecurity" "IAM Security"))
			      (:li :align "center" (:a :href "#" (print-web-session-timeout))))
			 
			 (:ul :class "nav navbar-nav navbar-right"
			      (:li :align "center" (:a :href "hhubsadminprofile"   (:i :class "fa-regular fa-user") "&nbsp;My Profile" )) 
			      (:li :align "center" (:a :href "dodlogout"  (:i :class "fa-solid fa-arrow-right-from-bracket"))))))))))
  
  
(defun dod-controller-dbreset-page () 
  :documentation "No longer used now" 
  (with-standard-admin-page (:title "Restart Higirisehub.com")
    (:div :class "row"
	  (:div :class "col-sm-12 col-md-12 col-lg-12"
		(:form :id "restartsiteform" :method "POST" :action "dbresetaction"
		       (:div :class "form-group"
			     (:input :class "form-control" :name "password" :placeholder "password"  :type "password"))
		       (:div :class "form-group"
			     (:input :type "submit" :name "submit" :class "btn btn-primary" :value "Go...      ")))))))




(defun dod-controller-dbreset-action ()
  :documentation "No longer used now" 
  (let ((pass (hunchentoot:parameter "password")))
    (if (equal (encrypt  pass "highrisehub.com") *sitepass*)
       (progn  (stop-das) 
	      (start-das) 
	      (with-standard-admin-page (:title "Restart Highrisehub.com")
		(:h3 "DB Reset successful"))))))






(defun company-search-html ()
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input"
		(:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
		      (with-html-search-form "idsyssearchtenant" "syssearchtenant" "idaccountlivesearch" "accountlivesearch" "dodsyssearchtenantaction" "Search for an Apartment/Group"))))))

(defun com-hhub-transaction-create-company-dialog (&optional id)
  (let* ((company (if id (select-company-by-id id)))
	 (cmpname (if company (slot-value company 'name)))
	 (cmpaddress (if company(slot-value company 'address)))
	 (cmpcity (if company (slot-value company 'city)))
	 (cmpstate (if company (slot-value company 'state)))
	 (cmpwebsite (if company (slot-value company 'website)))
	 (cmpzipcode (if company (slot-value company 'zipcode)))
	 (cmp-type (if company (slot-value company 'cmp-type)))
	 (subscription-plan (if company (slot-value company 'subscription-plan))))
    
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form "form-addcompany" "createcompanyaction"
		    (if company (cl-who:htm (:input :class "form-control" :type "hidden" :value id :name "id")))
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "cmpname" :maxlength "30"  :value cmpname :placeholder "Name ( max 30 characters) " :type "text" ))
		    (:div :class "form-group"
			  (:label :for "cmpaddress")
			  (:textarea :class "form-control" :name "cmpaddress"  :placeholder "Address ( max 400 characters) "  :rows "5" :onkeyup "countChar(this, 400)" (cl-who:str cmpaddress) ))
		    (:div :class "form-group" :id "charcount")
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value cmpcity :placeholder "City"  :name "cmpcity" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value cmpstate :placeholder "State"  :name "cmpstate" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value "INDIA" :readonly "true"  :name "cmpcountry" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :maxlength "6" :value cmpzipcode :placeholder "Pincode" :name "cmpzipcode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :maxlength "256" :value cmpwebsite :placeholder "Website" :name "cmpwebsite" ))
		    (with-html-div-row
		      (with-html-div-col
			(company-type-dropdown "cmp-type" cmp-type)))
		    
		    (with-html-div-row
		      (with-html-div-col
			(company-subscription-plan-dropdown "subscription-plan" subscription-plan )))
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))

(defun company-subscription-plan-dropdown (name selectedkey)
  (let ((subsplan-ht (make-hash-table)))
    (setf (gethash "TRIAL" subsplan-ht) "TRIAL")
    (setf (gethash "BASIC" subsplan-ht) "BASIC")
    (setf (gethash "PROFESSIONAL" subsplan-ht)  "PROFESSIONAL")
    (with-html-dropdown name subsplan-ht selectedkey)))
    
    

(defun company-type-dropdown (name selectedkey) 
  (let ((cmptype-ht (make-hash-table)))
    (setf (gethash "DEFAULT" cmptype-ht) "DEFAULT")
    (setf (gethash "GROCERY" cmptype-ht) "GROCERY") 
    (setf (gethash "APPAREL" cmptype-ht) "APPAREL")
    (setf (gethash "MOBILE" cmptype-ht) "MOBILE")
    (setf (gethash "FASHION JEWELLERY" cmptype-ht) "FASHION JEWELLERY")
    (setf (gethash "HYPERMARKET" cmptype-ht) "HYPERMARKET")
    (setf (gethash "COMPUTER HARDWARE" cmptype-ht) "COMPUTER HARDWARE")
    (setf (gethash "SPORTS" cmptype-ht) "SPORTS")
    (setf (gethash "FURNITURE" cmptype-ht) "FURNITURE")
    (setf (gethash "COMMUNITY" cmptype-ht) "APARTMENT/COMMUNITY")
    (setf (gethash "STATIONARY" cmptype-ht) "STATIONARY")
    (setf (gethash "PHOTO SHOP" cmptype-ht) "PHOTO SHOP")
    (setf (gethash "FARMERS MARKET" cmptype-ht) "FARMERS MARKET")
    (with-html-dropdown name cmptype-ht selectedkey)))




(defun dod-controller-new-company-request-page ()
  (let ((cmp-type (hunchentoot:parameter "cmp-type")))
    ;; Since we came to the new company request page, we will create new session here
    (with-no-navbar-page  "New Store Request"  
      (with-html-form  "form-hhubnewcompanyemail" "hhubnewstorerequeststep2"
	(:img :class "profile-img" :src "/img/logo.png" :alt "")
	
	(with-html-div-row
	  (with-html-div-col 
	    (:h4 (:span :class "label label-primary" "Store Owner Details"))))
	
	(with-html-div-row
	  (with-html-div-col
	    (with-html-input-text "custname" "Name" "Full Name" nil T "Please fill your full name" "1")))
	    	
	(with-html-div-row
	  (with-html-div-col
	    (with-html-input-text "phone" "Mobile Phone (+91)" "Enter 10 digit phone number" nil T "Please enter phone number" 2))	
	  (with-html-div-col
	    (with-html-input-text "email" "Email" "Email" nil T "Please enter email" 3)))
	
	(with-html-div-row (:hr))
	
	(with-html-div-row
	  (with-html-div-col
	    (:h4 (:span :class "label label-primary" "Store Details"))))
	
	(with-html-div-row
	  (with-html-div-col
	    (with-html-input-text "cmpname" "Store Name" "Store Name" nil T "Please enter company name" 4 :maxlength "40")))
	
	
	(with-html-div-row
	  (with-html-div-col
	    (with-html-input-textarea "cmpaddress" "Address" "Enter Address" T "Enter Address" 5 3))
	  (:div :class "form-group" :id "charcount"))
	
	(:input  :type "hidden" :value cmp-type :name "cmptype")
	
	(with-html-div-row
	  (with-html-div-col
	    (with-html-input-text "cmpzipcode" nil "Pincode" nil T "Enter Pincode" 6 :inputmode "numeric" :oninput "this.value = this.value.replace(/[^0-9]/g,'');")
	    (:span :id "areaname" :class "label label-info")))
	
	(with-html-div-row
	  (with-html-div-col
	    (with-html-input-text "cmpcity" "City" "City" nil T "Enter City" nil :readonly T )))
	
	
	(with-html-div-row
	  (with-html-div-col
	        (with-html-input-text "cmpstate" "State" "State" nil T "Enter State" nil :readonly T )))

	(with-html-div-row
	  (with-html-div-col
	    (:input :class "form-control" :type "text" :value "INDIA" :readonly "true"  :name "cmpcountry" )))
	(with-html-div-row
	  (with-html-div-col
	    (with-html-input-text "website" nil "Website" nil nil nil nil :maxlength "250")))
	

	(with-html-div-row
	  (with-html-div-col
	    (with-html-checkbox "tnccheck" "tncagreed" T  T
	      (:label :class "form-check-label" :for "tnccheck" "&nbsp;&nbsp;Agree Terms and Conditions&nbsp;&nbsp;")
	      (:a  :href "https://www.highrisehub.com/tnc.html"  (:i :class "fa-solid fa-scale-balanced") "&nbsp;Terms"))))

	
	(with-html-div-row
	  (with-html-div-col
	    (:div :class "form-group"
		  (:div :class "g-recaptcha" :data-sitekey *HHUBRECAPTCHAV2KEY* ))))
	
	(with-html-div-row
	  (with-html-div-col
	    (:div :class "form-group"
		  (:button :class "submit center-block btn btn-primary btn-block" :type "submit" "Send Request"))))

	(hhub-html-page-footer)))))



(defun hhub-controller-new-community-store-request-page ()
  (let ((cmp-type (hunchentoot:parameter "cmp-type")))
    ;; Since we came to the new company request page, we will create new session here
    (with-no-navbar-page  "New Store Request"  
      (with-html-form  "form-hhubnewcompanyemail" "hhubnewstorerequeststep2"
	(:img :class "profile-img" :src "/img/logo.png" :alt "")
		    	
	(with-html-div-row
	  (with-html-div-col 
	    (:h4 (:span :class "label label-primary" "Store Requester Details"))))
	
	(with-html-div-row
	  (with-html-div-col
	    (with-html-input-text "custname" "Name" "Full Name" nil T "Please fill your full name" "1")))
	
	(with-html-div-row
	  (with-html-div-col
	    (with-html-input-text "phone" "Mobile Phone (+91)" "Enter 10 digit phone number" nil T "Please enter phone number" 2))	
	  (with-html-div-col
	    (with-html-input-text "email" "Email" "Email" nil T "Please enter email" 3)))
	
	(with-html-div-row (:hr))

	(with-html-div-row
	  (with-html-div-col
	    (:h4 (:span :class "label label-primary" "Store Details"))))
	
	(with-html-input-text-hidden "cmptype" cmp-type) 
	
	(with-html-div-row
	  (with-html-div-col
	    (with-html-input-text "cmpzipcode" nil "Pincode" nil T "Enter Pincode" 6 :inputmode "numeric" :oninput "this.value = this.value.replace(/[^0-9]/g,'');")
	    (:span :id "areaname" :class "label label-info")))
	
	(with-html-div-row
	  (with-html-div-col
	    (with-html-input-text "cmpcity" "City" "City" nil T "Enter City" nil :readonly T )))
	
	
	(with-html-div-row
	  (with-html-div-col
	        (with-html-input-text "cmpstate" "State" "State" nil T "Enter State" nil :readonly T )))

	(with-html-div-row
	  (with-html-div-col
	    (:input :class "form-control" :type "text" :value "INDIA" :readonly "true"  :name "cmpcountry" )))
	
	(with-html-div-row
	  (with-html-div-col
	    (with-html-checkbox "tnccheck" "tncagreed" T  T
	      (:label :class "form-check-label" :for "tnccheck" "&nbsp;&nbsp;Agree Terms and Conditions&nbsp;&nbsp;")
	      (:a  :href (format nil "~A/hhub/tnc" *siteurl*)  (:i :class "fa-solid fa-scale-balanced")  "&nbsp;Terms."))))

	
	(with-html-div-row
	  (with-html-div-col
	    (:div :class "form-group"
		  (:div :class "g-recaptcha" :required T :data-sitekey *HHUBRECAPTCHAV2KEY* ))))
	
	(with-html-div-row
	  (with-html-div-col
	    (:div :class "form-group"
		  (:button :class "submit center-block btn btn-primary btn-block" :type "submit" "Send Request"))))

	(hhub-html-page-footer)))))




(defun com-hhub-transaction-request-new-company (type)
  (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form  "form-hhubnewcompanyemail" "hhubnewcompreqemailaction"
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "cmpname" :maxlength "30"  :value "" :required T  :placeholder "Enter Store Name ( max 30 characters) " :type "text" ))
		    (:div :class "form-group"
			  (:label :for "cmpaddress")
			  (:textarea :class "form-control" :name "cmpaddress"  :placeholder "Enter Address ( max 400 characters) " :required T  :rows "5" :onkeyup "countChar(this, 400)" "" ))
		    (:div :class "form-group" :id "charcount")
		    (:div :class "form-group"
			  (:input :class "form-control" :type "hidden" :value type :name "cmptype" :readonly T))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value "" :placeholder "City"  :required T :name "cmpcity" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value "" :placeholder "State" :required T  :name "cmpstate" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value "INDIA" :readonly "true"  :name "cmpcountry" ))
		    (:div :class "form-group"
			      (:input :class "form-control" :type "text" :maxlength "6" :value "" :placeholder "Pincode" :required T  :name "cmpzipcode" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :maxlength "256" :value "" :placeholder "Website" :name "cmpwebsite" ))
		    (:div :class "form-group checkbox" 
			  (:input :type "checkbox" :name "tnccheck" :value  "tncagreed" :required T "Agree Terms and Conditions.  "))
		    (:a  :href "https://www.highrisehub.com/tnc.html"  (:i :class "fa-solid fa-scale-balanced") "&nbsp;Terms")
		    (:div :class "form-group checkbox" 
			  (:input :type "checkbox" :name "privacycheck" :value "privacyagreed" :required T  "Agree Privacy Policy.  "))
		   
		    (:a  :href "https://www.highrisehub.com/privacy.html"  (:i :class "fa-solid fa-eye") "&nbsp;Privacy Policy. ")
		    (:div :class "form-group"
			  (:div :class "g-recaptcha" :data-sitekey *HHUBRECAPTCHAV2KEY* ))
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))))
    
    
(defun dod-controller-company-search-for-sys-action ()
  (let*  ((qrystr (hunchentoot:parameter "livesearch"))
	  (company-list (if (not (equal "" qrystr)) (select-companies-by-name qrystr))))
    (display-as-tiles company-list 'company-card 'product-box)))

(defun com-hhub-transaction-refresh-iam-settings () 
  (with-opr-session-check 
      (progn 
	(refreshiamsettings)
	(hunchentoot:redirect "/hhub/dasabacsecurity"))))

(defun dod-controller-abac-security ()
  (let ((policies (hhub-get-cached-auth-policies)))
    (with-opr-session-check 
      (with-standard-admin-page "Welcome to Highrisehub"
	(iam-security-page-header)
	(:hr)
	(:div :class "row"
	      (:div :class "col-xs-3" (:h4 "Business Policies"))
	      (:div :class "col-xs-3" 
		    (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#addpolicy-modal" "Add New Policy")))
	(cl-who:str (display-as-table (list  "Name" "Description" "Policy Function" "Action")  policies 'policy-row))
	(modal-dialog "addpolicy-modal" "Add/Edit Policy" (com-hhub-transaction-policy-create-dialog))))))

			


(defun com-hhub-transaction-sadmin-home () 
  (with-opr-session-check
    (let ((params nil))
      (setf params (acons "username" (get-login-user-name) params))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (with-hhub-transaction "com-hhub-transaction-sadmin-home" params 
	(let (( companies (hhub-get-cached-companies)))
	  (with-standard-admin-page  "Welcome to Highrisehub."
	    (:div :id "row"
		  (:div :id "col-xs-6" 
			(:h3 "Welcome " (cl-who:str (format nil "~A" (get-login-user-name))))))
	    (company-search-html)
	    (:div :id "row"
		(:div :id "col-xs-6"
					;  (:a :class "btn btn-primary" :role "button" :href "new-company" :data-toggle "modal" :data-target "#editcompany-modal" (:span :class "glyphicon glyphicon-shopping-plus") " Add New Group  ")
		      (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#editcompany-modal" "Add New Group"))
		(:div :id "col-xs-6" :align "right" 
		      (:span :class "badge" (cl-who:str (format nil "~A" (length companies))))))
	  (:hr)
	    (modal-dialog "editcompany-modal" "Add/Edit Group" (com-hhub-transaction-create-company-dialog))
	    (cl-who:str (display-as-tiles companies 'company-card "tenant-box"))))))))



(defun IAM-security-page-header ()
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :class "col-sm-12"
		(:h4 (:span :class "label label-warning" "Note: Any changes saved will not get reflected unless you click the refresh button."))))
    (:div :class "row"
	  (:div :class "col-xs-2"
		(:a :class "btn btn-primary" :role "button" :href "/hhub/dasabacsecurity"  "Policies"))
	  (:div :class "col-xs-2"
		(:a :class "btn btn-primary" :role "button" :href "/hhub/listattributes"  "Attributes/Tags"))
	  (:div :class "col-xs-2"
		(:a :class "btn btn-primary" :role "button" :href "/hhub/listbusobjects"  "Business Objects"))
	  (:div :class "col-xs-2"
		(:a :class "btn btn-primary" :role "button" :href "/hhub/listabacsubjects"  "Business Personas"))
	  (:div :class "col-xs-2"
		(:a :class "btn btn-primary" :role "button" :href "/hhub/listbustrans"  "Transactions"))
	  (:div :class "col-xs-2"
		(:a :class "btn btn-primary btn-xs" :role "button" :href "/hhub/refreshiamsettings" (:i :class "fa-solid fa-rotate-right"))))
    (:div :class "row" )))

(setq *logged-in-users* (make-hash-table :test 'equal))


(defun dod-controller-list-busobjs () 
:documentation "List all the business objects"
(with-opr-session-check 
  (let ((busobjs (hhub-get-cached-bus-objects)))
    (with-standard-admin-page "Business Objects ..."
			      (IAM-security-page-header)
			      (:div :class "row"
				    (:div :class "col-md-12" (:h4 "Business Objects")))
			      (cl-who:str (display-as-table (list "Name")  busobjs 'busobj-card))
			      (:h4 "Note: To add new business objects to the system, follow these steps.")
			      (:h4 "In the Lisp REPL call the function, (create-bus-object)")))))



(defun dod-controller-list-abac-subjects () 
:documentation "List all the business objects"
(with-opr-session-check 
  (let ((abacsubjects (select-abac-subject-by-company (get-login-company))))
    (with-standard-admin-page "Business Personas ..."
      (IAM-security-page-header)
      (:hr)
      (with-html-div-row
	    (:div :class "col-md-12" (:h4 "Business Personas")))
      (cl-who:str (display-as-table (list "Name")  abacsubjects 'busobj-card))
      (:h4 "Note: To add new Business Persona to the system, follow these steps.")
      (:h4 "In the Lisp REPL call the function, (create-abac-subject)")))))


(defun dod-controller-list-bustrans ()
:documentation "List all the business transactions" 
(with-opr-session-check 
  (let ((bustrans (hhub-get-cached-transactions)))
    (with-standard-admin-page "Business Transactions..."
      (IAM-security-page-header)
      (:hr)
      (with-html-div-row
	(:div :class "col-md-12" 
		  (:div :class "col-md-12" (:h4 "Business Transactions"))))
      (:div :class "col-md-12" 
	    (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#addtransaction-modal" "New Transaction"))
      
      (cl-who:str (display-as-table (list "Name" "URI" "Function" "Action")  bustrans 'bustrans-card))
      (modal-dialog "addtransaction-modal" "Add/Edit Transaction" (new-transaction-html))))))

(defun dod-controller-list-attrs ()
:documentation "This function lists the attributes used in policy making"
 (with-opr-session-check 
   (let ((lstattributes (hhub-get-cached-abac-attributes)))
     (with-standard-admin-page  "attributes ..."
			       (iam-security-page-header)
       (:div :class "row"
	     (:div :class "col-md-12" (:h4 "Attributes"))
	     (:div :class "col-md-12" 
		   (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#addattribute-modal" "Add New Attribute")))
       (:hr)		       
       (cl-who:str (display-as-table (list "Name" "Description" "Function" "Type" )  lstattributes 'attribute-card))
					;  (ui-list-attributes lstattributes)
       (modal-dialog "addattribute-modal" "Add/Edit Attribute" (com-hhub-transaction-create-attribute-dialog))))))

(defun dod-controller-loginpage ()
  (handler-case 
      (progn  (if (equal (caar (clsql:query "select 1" :flatp nil :field-names nil :database *dod-db-instance*)) 1) T)	      
	      (if (is-dod-session-valid?)
		  (hunchentoot:redirect "/hhub/sadminhome")
		  ;else
		  (with-standard-admin-page "Welcome to HighriseHub"
		    (:div :class "row background-image: url(resources/login-background.png);background-color:lightblue;" 
			  (:div :class "col-sm-6 col-md-4 col-md-offset-4"
				(:div :class "account-wall"
				      (:h1 :class "text-center login-title"  "Login to HighriseHub")
				      (:form :class "form-signin" :role "form" :method "POST" :action "sadminlogin"
					     (:div :class "form-group"
						   (:input :class "form-control" :name "company" :placeholder "Company Name"  :type "text"))
					     (:div :class "form-group"
						   (:input :class "form-control" :name "username" :placeholder "User name" :type "text"))
					     (:div :class "form-group"
						   (:input :class "form-control" :name "password"  :placeholder "Password" :type "password"))
					     (:input :type "submit"  :class "btn btn-primary" :value "Login      "))))))))
	      (clsql:sql-database-data-error (condition)
					     (if (equal (clsql:sql-error-error-id condition) 2006 ) (progn
												      (stop-das) 
												      (start-das)
												      (hunchentoot:redirect "/hhub/opr-login.html"))))))





(defun com-hhub-transaction-sadmin-login ()
 (let  ((uname (hunchentoot:parameter "username"))
	(passwd (hunchentoot:parameter "password"))
	(cname (hunchentoot:parameter "company"))
	(params nil))
   
   (setf params (acons "uri" (hunchentoot:request-uri*)  params))
   (setf params (acons "username" uname params))
   (setf params (acons "company" cname params))
   (with-hhub-transaction "com-hhub-transaction-sadmin-login"  params   
      (unless (and
	       ( or (null cname) (zerop (length cname)))
	       ( or (null uname) (zerop (length uname)))
	       ( or (null passwd) (zerop (length passwd))))
      (if (equal (dod-login :company-name cname :username uname :password passwd) NIL) (hunchentoot:redirect "/hhub/opr-login.html") (hunchentoot:redirect  "/hhub/sadminhome"))))))

  
(defun dod-controller-logout ()
  (progn
    (dod-logout (get-login-user-name))
    (when hunchentoot:*session* (hunchentoot:remove-session hunchentoot:*session*))
    (hunchentoot:redirect "/hhub/opr-login.html")))

(defun is-dod-session-valid? ()
 ;(if  (null (get-login-user-name)) NIL T))
 (if hunchentoot:*session* T))
 ; (if (get-login-user-name) T))

(defun dod-login (&key company-name username password)
  (let* ((login-user (car (clsql:select 'dod-users :where [and
					[= [slot-value 'dod-users 'username] username]
					[= [:deleted-state] "N"]]
					:caching nil :flatp t)))
	 (pwd (if login-user (slot-value login-user 'password)))
	 (salt (if login-user (slot-value login-user 'salt)))
	 (password-verified (if login-user  (check-password password salt pwd)))
	 (login-userid (if login-user (slot-value login-user 'row-id)))
	 (login-attribute-cart '())
	 (login-tenant-id (if login-user (slot-value  (users-company login-user) 'row-id)))
	 (login-company (if login-user (slot-value login-user 'company)))
	 (login-company-name (if login-user (slot-value (users-company login-user) 'name))))

    (when (and   
	   password-verified 
	   (equal  login-company-name company-name)
	   login-user 
	   (null (hunchentoot:session-value :login-username))) ;; User should not be logged-in in the first place.
      (progn (add-login-user username  login-user)
	     (setf (hunchentoot:session-value :login-user) login-user)
	     (setf *current-user-session* (hunchentoot:start-session))
	     (setf (hunchentoot:session-value :login-username) username)
	     (setf (hunchentoot:session-value :login-userid) login-userid)
	     (setf (hunchentoot:session-value :login-attribute-cart) login-attribute-cart)
	     (setf (hunchentoot:session-value :login-tenant-id) login-tenant-id)
	     (setf (hunchentoot:session-value :login-company-name) company-name)
	     (setf (hunchentoot:session-value :login-company) login-company)))))  
  


(defun get-tenant-id (company-name)
  ( car ( clsql:select [row-id] :from [dod-company] :where [= [slot-value 'dod-company 'name] company-name]
		       :flatp t)))

(defun get-tenant-name (company-id)
  ( car ( clsql:select [name] :from [dod-company] :where [= [slot-value 'dod-company 'row-id] company-id]
		       :flatp t)))
  

(defun get-login-user-object (username)
  (gethash username *logged-in-users*))


(defun is-user-already-login? (username)
(if (equal (gethash username *logged-in-users*) NIL ) NIL T))


(defun add-login-user(username object)
  (unless (is-user-already-login? username)
	   (setf (gethash username *logged-in-users*) object)))


(defun dod-logout (username)
  (remhash username *logged-in-users*))


(defun dod-controller-new-store-request-step2 ()
(let*  ((custname (hunchentoot:parameter "custname"))
	  (email (hunchentoot:parameter "email"))
	  (phone (hunchentoot:parameter "phone"))
	  (cmpname (hunchentoot:parameter "cmpname"))
	  (cmptype (hunchentoot:parameter "cmptype"))
	  (cmpaddress (hunchentoot:parameter "cmpaddress"))
	  (cmpcity (hunchentoot:parameter "cmpcity"))
	  (cmpstate (hunchentoot:parameter "cmpstate"))
	  (cmpcountry (hunchentoot:parameter "cmpcountry"))
	  (cmpzipcode (hunchentoot:parameter "cmpzipcode"))
	  (tnccheck (hunchentoot:parameter "tnccheck"))
	  (captcha-resp (hunchentoot:parameter "g-recaptcha-response"))
	  (paramname (list "secret" "response" ) ) 
	  (paramvalue (list *HHUBRECAPTCHAV2SECRET*  captcha-resp))
	  (param-alist (pairlis paramname paramvalue ))
	  (json-response (json:decode-json-from-string  (map 'string 'code-char(drakma:http-request "https://www.google.com/recaptcha/api/siteverify"
                       :method :POST
                       :parameters param-alist  ))))
     	  (cmpwebsite (hunchentoot:parameter "cmpwebsite"))
	  (company (make-instance 'dod-company
				  :name cmpname
				  :address cmpaddress
				  :city cmpcity
				  :state cmpstate 
				  :country cmpcountry
				  :zipcode cmpzipcode
				  :website cmpwebsite
				  :cmp-type cmptype
				  :deleted-state "N"
				  :created-by nil
				  :updated-by nil)))
    (unless(and  ( or (null cmpname) (zerop (length cmpname)))
		     ( or (null cmpaddress) (zerop (length cmpaddress)))
		     ( or (null cmpzipcode) (zerop (length cmpzipcode))))
	  (cond 
	    ((null (cdr (car json-response))) (dod-response-captcha-error))
	    ((and company
		  (equal tnccheck "tncagreed"))
	     (let ((context "hhubnewcompreqemailaction"))
	       (hunchentoot:start-session)
	       (setf (hunchentoot:session-value :newstorerequest-company) company)
	       (setf (hunchentoot:session-value :newstorerequest-custname) custname )
	       (setf (hunchentoot:session-value :newstorerequest-phone) phone )
	       (setf (hunchentoot:session-value :newstorerequest-email) email)
	       (generateotp&redirect phone context)))))))
	 

    


(defun dod-controller-new-company-request-email ()
  (let*  ((company (hunchentoot:session-value :newstorerequest-company))
	  (custname (hunchentoot:session-value :newstorerequest-custname))
	  (phone (hunchentoot:session-value :newstorerequest-phone))
	  (email (hunchentoot:session-value :newstorerequest-email)))
	  
    (when company (send-new-company-registration-email company custname phone email))
    ;; When an email is sent, we will clear the session. 
    (hunchentoot:remove-session hunchentoot:*session*)
    (hunchentoot:redirect "/hhub/hhubnewcompreqemailsent")))

	  

(defun 	com-hhub-transaction-create-company ()
  (with-opr-session-check
    (let ((params nil))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (setf params (acons "rolename" (com-hhub-attribute-role-name) params))
      (with-hhub-transaction "com-hhub-transaction-create-company" params  
      (let*  ((id (hunchentoot:parameter "id"))
	      (company (if id (select-company-by-id id)))
	      (cmpname (hunchentoot:parameter "cmpname"))
	      (cmpaddress (hunchentoot:parameter "cmpaddress"))
	      (cmpcity (hunchentoot:parameter "cmpcity"))
	      (cmpstate (hunchentoot:parameter "cmpstate"))
	      (cmpcountry (hunchentoot:parameter "cmpcountry"))
	      (cmpzipcode (hunchentoot:parameter "cmpzipcode"))
	      (cmpwebsite (hunchentoot:parameter "cmpwebsite"))
	      (cmp-type (hunchentoot:parameter "cmp-type"))
	      (subscription-plan (hunchentoot:parameter "subscription-plan"))
	      (loginuser (get-login-userid)))

	(unless(and  ( or (null cmpname) (zerop (length cmpname)))
		     ( or (null cmpaddress) (zerop (length cmpaddress)))
		     ( or (null cmpzipcode) (zerop (length cmpzipcode))))
	  (if company 
	      (progn (setf (slot-value company 'name) cmpname)
		     (setf (slot-value company 'address) cmpaddress)
		     (setf (slot-value company 'city) cmpcity)
		     (setf (slot-value company 'state) cmpstate)
		     (setf (slot-value company 'zipcode) cmpzipcode)
		     (setf (slot-value company 'website) cmpwebsite)
		     (setf (slot-value company 'cmp-type) cmp-type)
		     (setf (slot-value company 'subscription-plan) subscription-plan)
		     (create-guest-customer company)
		     (update-company company))
					;else
	      (progn
		(new-dod-company cmpname cmpaddress cmpcity cmpstate cmpcountry cmpzipcode cmpwebsite cmp-type subscription-plan loginuser loginuser))))
	
	;; once a new company is created, create the Company Administrator
	;; Once a new company is created, we will create a default Vendor with the same name, phone number as the company admin)))
	
	;; once a new company is created, we need to create a new guest customer for that company.
	
	      (hunchentoot:redirect  "/hhub/sadminhome"))))))



(setq hunchentoot:*dispatch-table*
    (list
	;***************** SUPERADMIN/OPERATOR RELATED ********************
     
	(hunchentoot:create-regex-dispatcher "^/hhub/sadminhome" 'com-hhub-transaction-sadmin-home)
	(hunchentoot:create-regex-dispatcher "^/hhub/dasabacsecurity" 'dod-controller-abac-security)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubnewcompanyreqpage" 'dod-controller-new-company-request-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubnewstorerequeststep2" 'dod-controller-new-store-request-step2)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubnewcompreqemailaction" 'dod-controller-new-company-request-email)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubnewcompreqemailsent" 'dod-controller-new-company-registration-email-sent) 
	(hunchentoot:create-regex-dispatcher "^/hhub/createcompanyaction" 'com-hhub-transaction-create-company)
	(hunchentoot:create-regex-dispatcher "^/hhub/opr-login.html" 'dod-controller-loginpage)
	(hunchentoot:create-regex-dispatcher "^/hhub/sadminlogin" 'com-hhub-transaction-sadmin-login)
	(hunchentoot:create-regex-dispatcher "^/hhub/list-customers" 'dod-controller-list-customers)
	(hunchentoot:create-regex-dispatcher "^/hhub/orderdetails" 'dod-controller-list-order-details)
	(hunchentoot:create-regex-dispatcher "^/hhub/list-vendors" 'dod-controller-list-vendors)
	(hunchentoot:create-regex-dispatcher "^/hhub/list-products" 'dod-controller-list-products)
	(hunchentoot:create-regex-dispatcher "^/hhub/user-added" 'dod-controller-user-added)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodlogout" 'dod-controller-logout)
	(hunchentoot:create-regex-dispatcher "^/hhub/delcomp" 'dod-controller-delete-company)
	(hunchentoot:create-regex-dispatcher "^/hhub/journal-entry-added" 'dod-controller-journal-entry-added)
        (hunchentoot:create-regex-dispatcher "^/hhub/account-added" 'dod-controller-account-added)
	(hunchentoot:create-regex-dispatcher "^/hhub/sadmincreateusers" 'com-hhub-transaction-sadmin-create-users-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/list-accounts" 'dod-controller-list-accounts)
	(hunchentoot:create-regex-dispatcher "^/hhub/listattributes" 'dod-controller-list-attrs)
	(hunchentoot:create-regex-dispatcher "^/hhub/dbreset.html" 'dod-controller-dbreset-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/dbresetaction" 'dod-controller-dbreset-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodsyssearchtenantaction" 'dod-controller-company-search-for-sys-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/dasaddattribute" 'com-hhub-transaction-create-attribute)
	(hunchentoot:create-regex-dispatcher "^/hhub/listbusobjects" 'dod-controller-list-busobjs)
	(hunchentoot:create-regex-dispatcher "^/hhub/listabacsubjects" 'dod-controller-list-abac-subjects)
	(hunchentoot:create-regex-dispatcher "^/hhub/listbustrans" 'dod-controller-list-bustrans)
	(hunchentoot:create-regex-dispatcher "^/hhub/dasaddpolicyaction" 'com-hhub-transaction-policy-create)
	(hunchentoot:create-regex-dispatcher "^/hhub/dasaddtransactionaction" 'dod-controller-add-transaction-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/dassearchpolicies" 'dod-controller-policy-search-action )
	(hunchentoot:create-regex-dispatcher "^/hhub/transtopolicylinkpage" 'dod-controller-trans-to-policy-link-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/transtopolicylinkaction" 'dod-controller-trans-to-policy-link-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/dasproductapprovals" 'dod-controller-products-approval-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/dasadduseraction" 'dod-controller-add-user-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubsadminprofile" 'com-hhub-transaction-sadmin-profile)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubdiagnostics" 'com-hhub-transaction-system-dashboard)
	(hunchentoot:create-regex-dispatcher "^/hhub/suspendaccount" 'com-hhub-transaction-suspend-account)
	(hunchentoot:create-regex-dispatcher "^/hhub/restoreaccount" 'com-hhub-transaction-restore-account)
	(hunchentoot:create-regex-dispatcher "^/hhub/refreshiamsettings" 'com-hhub-transaction-refresh-iam-settings)
	(hunchentoot:create-regex-dispatcher "^/hhub/pricing" 'hhub-controller-pricing)
	(hunchentoot:create-regex-dispatcher "^/hhub/contactuspage" 'hhub-controller-contactus-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/aboutuspage" 'hhub-controller-aboutus-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/contactusaction" 'hhub-controller-contactus-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/tnc" 'hhub-controller-tnc-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/privacy" 'hhub-controller-privacy-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/otppage" 'dod-controller-OTP-request-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubotpregenerateaction" 'dod-controller-otp-regenerate-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubotpsubmitaction" 'dod-controller-otp-submit-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/displaystore" 'com-hhub-transaction-display-store)
	(hunchentoot:create-regex-dispatcher "^/hhub/createwhatsapplinkwithmessage" 'hhub-controller-create-whatsapp-link-with-message)
	(hunchentoot:create-regex-dispatcher "^/hhub/permissiondenied" 'hhub-controller-permission-denied)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubnewcommstorerequest" 'hhub-controller-new-community-store-request-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/list-companies" 'dod-controller-list-companies)
	
	;***************** COMPADMIN/COMPANYHELPDESK/COMPANYOPERATOR  RELATED ********************
     
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcadindex" 'com-hhub-transaction-compadmin-home)
	(hunchentoot:create-regex-dispatcher "^/hhub/cad-login.html" 'com-hhub-transaction-cad-login-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcadloginaction" 'com-hhub-transaction-cad-login-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcadlogout" 'com-hhub-transaction-cad-logout) 
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcadprdrejectaction" 'com-hhub-transaction-cad-product-reject-action )
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcadprdapproveaction" 'com-hhub-transaction-cad-product-approve-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubpublishaccountexturl" 'com-hhub-transaction-publish-account-exturl)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcadprofile" 'dod-controller-cad-profile)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcompadminupdateaction" 'com-hhub-transaction-compadmin-updatedetails-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcadlistprodcatg" 'dod-controller-product-categories-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubprodcatgaddaction" 'com-hhub-transaction-prodcatg-add-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubdeleteprodcatg" 'dod-controller-delete-product-category)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendorapprovalpage" 'dod-controller-vendor-approval-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendorapproveaction" 'com-hhub-transaction-vendor-approve-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendorrejectaction" 'com-hhub-transaction-vendor-reject-action)
	
	;************CUSTOMER LOGIN RELATED ********************
	(hunchentoot:create-regex-dispatcher  "^/hhub/customer-login.html" 'dod-controller-customer-loginpage)
	(hunchentoot:create-regex-dispatcher  "^/hhub/dodcustlogin"  'dod-controller-cust-login)
	(hunchentoot:create-regex-dispatcher  "^/hhub/dascustloginasguest"  'dod-controller-cust-login-as-guest)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustindex" 'dod-controller-cust-index)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustlogout" 'dod-controller-customer-logout)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodguestcustlogout" 'dod-controller-guest-customer-logout)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodmyorders" 'dod-controller-my-orders)
	(hunchentoot:create-regex-dispatcher "^/hhub/delorder" 'dod-controller-del-order) ;; not used. 
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustordsuccess" 'dod-controller-cust-ordersuccess)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustorderprefs" 'dod-controller-my-orderprefs)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustmyorderdetails" 'hhub-controller-customer-my-orderdetails)
	;;(hunchentoot:create-regex-dispatcher "^/hhub/dodcustaddorderpref" 'dod-controller-cust-add-orderpref-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustaddopfaction" 'dod-controller-cust-add-orderpref-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustdelopfaction" 'dod-controller-cust-del-orderpref-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustorderaddpage" 'dod-controller-cust-add-order-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustshopcartotpstep" 'dod-controller-cust-add-order-otpstep)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodmyorderaddaction" 'com-hhub-transaction-create-order)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustaddtocart" 'dod-controller-cust-add-to-cart)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustupdatecart" 'dod-controller-cust-update-cart)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustshopcartro" 'dod-controller-cust-show-shopcart-readonly)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustshopcart" 'dod-controller-cust-show-shopcart)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustremshctitem" 'dod-controller-remove-shopcart-item )
	;;(hunchentoot:create-regex-dispatcher "^/hhub/dodcustplaceorder" 'dod-controller-cust-placeorder )
	;;(hunchentoot:create-regex-dispatcher "^/hhub/dodvendordetails" 'dod-controller-vendor-details)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodprddetailsforcust" 'dod-controller-prd-details-for-customer)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubprddetailsforguestcust" 'dod-controller-prd-details-for-guest-customer)
	;;(hunchentoot:create-regex-dispatcher "^/hhub/dodprodsubscribe" 'dod-controller-cust-add-orderpref-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodproductsbycatg" 'dod-controller-customer-products-by-category)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodsearchproducts" 'dod-controller-search-products)
	(hunchentoot:create-regex-dispatcher "^/hhub/doddelcustorditem" 'dod-controller-del-cust-ord-item)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustlowbalanceshopcart" 'dod-controller-low-wallet-balance-for-shopcart)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustlowbalanceorderitems" 'dod-controller-low-wallet-balance-for-orderitems)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustwallet" 'dod-controller-cust-wallet-display)
	(hunchentoot:create-regex-dispatcher "^/hhub/custsignup1action" 'dod-controller-cust-register-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/custsignup1step2" 'com-hhub-transaction-customer&vendor-create-otpstep)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustregisteraction" 'com-hhub-transaction-customer&vendor-create)
	(hunchentoot:create-regex-dispatcher "^/hhub/duplicate-cust.html" 'dod-controller-duplicate-customer)
	(hunchentoot:create-regex-dispatcher "^/hhub/custsignup1.html" 'dod-controller-company-search-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/companysearchaction" 'dod-controller-company-search-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/createcustwallet" 'dod-controller-create-cust-wallet)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustprofile" 'dod-controller-customer-profile)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustorditemedit" 'com-hhub-transaction-cust-edit-order-item )
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustorderscal" 'dod-controller-cust-orders-calendar) 
	(hunchentoot:create-regex-dispatcher "^/hhub/dodcustordersdata" 'dod-controller-cust-order-data-json)
	(hunchentoot:create-regex-dispatcher "^/hhub/dasmakepaymentrequest" 'dod-controller-make-payment-request-html)
	(hunchentoot:create-regex-dispatcher "^/hhub/custpaymentsuccess" 'dod-controller-customer-payment-successful-page )
	(hunchentoot:create-regex-dispatcher "^/hhub/custpaymentfailure" 'dod-controller-customer-payment-failure-page )
	(hunchentoot:create-regex-dispatcher "^/hhub/custpaymentcancel" 'dod-controller-customer-payment-cancel-page )
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustupdateaction" 'dod-controller-customer-update-action )
	(hunchentoot:create-regex-dispatcher "^/hhub/rundailyordersbatch" 'dod-controller-run-daily-orders-batch)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustomerchangepin" 'dod-controller-customer-change-pin)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustforgotpassactionlink" 'dod-controller-customer-reset-password-action-link)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustpassreset.html" 'dod-controller-customer-password-reset-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustgentemppass"   'dod-controller-customer-generate-temp-password) 
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustpassreset"   'dod-controller-customer-password-reset-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubinvalidemail.html"   'dod-controller-invalid-email-error)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubpassresettokenexpired.html"   'dod-controller-password-reset-token-expired )
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubpassresetmailsent.html"   'dod-controller-password-reset-mail-sent )
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubpassresetmaillinksent.html"   'dod-controller-password-reset-mail-link-sent)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustsavepushsubscription"   'hhub-save-customer-push-subscription)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustremovepushsubscription"   'hhub-remove-vendor-push-subscription)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustonlinepayment"   'hhub-cust-online-payment)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubpincodecheck"   'hhub-controller-pincode-check)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustupipage"   'hhub-controller-upi-customer-order-payment-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendorupinotfound"   'dod-controller-vendor-upi-notfound)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustpaymentmethodspage"   'dod-controller-customer-payment-methods-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustwalletrechargepage"   'hhub-controller-upi-recharge-wallet-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustwalletrechargeaction"   'hhub-controller-upi-recharge-wallet-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubsearchmycustomer"   'hhub-controller-search-my-customer-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcarouseltest"   'hhub-controller-carousel-test)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustshippingmethodspage"   'dod-controller-cust-shipping-methods-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustloginotpstep"  'dod-controller-cust-login-otpstep)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustloginwithotp"  'dod-controller-cust-login-with-otp)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustloginv2"  'dod-controller-customer-otploginpage)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustvendorstore"  'dod-controller-customer-products-by-vendor)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubcustvendorsearch"  'dod-controller-customer-search-vendor)
	


;;***************************************************************************************************************************
;; WARNING: Two URIs should not have a common substring. For example hhubcustpassreset and hhubcustpassresetmail.html 
;;          has got hhubcustpassreset as a common string. When a call for hhubcustpassresetmail.html is made, then 
;;          hhubcustpassreset may get invoked. Keep the URIs unique. 
;;***************************************************************************************************************************	
	

;************VENDOR RELATED ********************
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvenddeactivateprod" 'dod-controller-vendor-deactivate-product)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendactivateprod" 'dod-controller-vendor-activate-product)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendcopyprod" 'dod-controller-vendor-copy-product)
	(hunchentoot:create-regex-dispatcher "^/hhub/vendor-login.html" 'dod-controller-vendor-loginpage)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendsearchtenantpage" 'dod-controller-cmpsearch-for-vend-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodrefreshpendingorders" 'dod-controller-refresh-pending-orders)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendrevenue" 'dod-controller-vendor-revenue)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvenddelprod" 'dod-controller-vendor-delete-product)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendsearchtenantaction" 'dod-controller-cmpsearch-for-vend-action )
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendaddtenantaction" 'dod-controller-vend-add-tenant-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendortenants" 'dod-controller-display-vendor-tenants)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendswitchtenant" 'dod-controller-vendor-switch-tenant)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendlogin" 'dod-controller-vend-login)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendloginpage" 'dod-controller-vendor-loginpage)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendindex" 'dod-controller-vend-index)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendlogout" 'dod-controller-vendor-logout)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvenexpexl" 'dod-controller-ven-expexl)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvenproducts" 'dod-controller-vendor-products)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodprddetailsforvendor" 'dod-controller-prd-details-for-vendor)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvenordfulfilled" 'com-hhub-transaction-vendor-order-setfulfilled)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendprofile" 'dod-controller-vend-profile)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendmycustomers" 'dod-controller-vendor-my-customers-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodsearchcustwalletpage" 'dod-controller-vendor-search-cust-wallet-page )
	(hunchentoot:create-regex-dispatcher "^/hhub/dodsearchcustwalletaction" 'dod-controller-vendor-search-cust-wallet-action )
	(hunchentoot:create-regex-dispatcher "^/hhub/dodupdatewalletbalance" 'dod-controller-update-wallet-balance)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendororderdetails" 'dod-controller-vendor-orderdetails)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvenaddprodpage" 'dod-controller-vendor-add-product-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvenbulkaddprodpage" 'dod-controller-vendor-bulk-add-products-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvenaddproductaction" 'com-hhub-transaction-vendor-product-add-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvenuploadproductsimagesaction" 'dod-controller-vendor-upload-products-images-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvenuploadproductscsvfileaction" 'com-hhub-transaction-vendor-bulk-products-add)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvenordcancel" 'dod-controller-vendor-order-cancel)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendupdateaction" 'dod-controller-vendor-update-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendupdatepgsettings" 'dod-controller-vendor-update-payment-gateway-settings-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendchangepin" 'dod-controller-vendor-change-pin)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendforgotpassactionlink" 'dod-controller-vendor-reset-password-action-link)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendpassreset.html" 'dod-controller-vendor-password-reset-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendgentemppass"   'dod-controller-vendor-generate-temp-password) 
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendpassreset"   'dod-controller-vendor-password-reset-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendpushsubscribepage"   'dod-controller-vendor-pushsubscribe-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendsavepushsubscription"   'hhub-controller-save-vendor-push-subscription )
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendremovepushsubscription"   'hhub-remove-vendor-push-subscription )
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendgetpushsubscription"   'hhub-controller-get-vendor-push-subscription )
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendupdateupisettings"   'hhub-controller-save-vendor-upi-settings)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendorupitransactions"   'hhub-controller-show-vendor-upi-transactions)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendupipayconfirm"   'hhub-controller-vendor-upi-confirm)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendupipaycancel"   'hhub-controller-vendor-upi-cancel)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendsearchproduct"   'dod-controller-vendor-search-products)
	(hunchentoot:create-regex-dispatcher "^/hhub/dodvendprodcategories"   'dod-controller-vendor-product-categories-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendaddprodshipinfoaction"  'com-hhub-transaction-vend-prd-shipinfo-add-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendorshipmethods"  'dod-controller-vend-shipping-methods)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendupdatfreeshipmethodaction"  'dod-controller-vendor-update-free-shipping-method-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendshipzoneratetablepage"  'dod-controller-vendor-shipzone-ratetable-page)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvenduploadshipratetableaction"  'dod-controller-vendor-upload-shipping-ratetable-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendupdatedefaultshipmethod"  'dod-controller-vendor-update-default-shipping-method)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendupdatflatrateshipmethodaction"  'dod-controller-vendor-update-flatrate-shipping-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendupdateshippartneraction"  'dod-controller-vendor-update-external-shipping-partner-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendloginotpstep"  'dod-controller-vend-login-otpstep)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendloginwithotp"  'dod-controller-vend-login-with-otp)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendloginv2"  'dod-controller-vendor-otploginpage)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvendprodpricingsaveaction"  'dod-controller-vendor-product-pricing-action)
	(hunchentoot:create-regex-dispatcher "^/hhub/hhubvpmupdateaction"  'dod-controller-vendor-payment-methods-update-action)
	
			
))



