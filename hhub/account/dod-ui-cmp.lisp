;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defun com-hhub-transaction-display-store ()
  (let* ((parambase64 (hunchentoot:parameter "key"))
	 (param-csv (cl-base64:base64-string-to-string (hunchentoot:url-decode parambase64)))
	 (paramslist (first (cl-csv:read-csv param-csv
					     :skip-first-p T
					     :map-fn #'(lambda (row)
							 row))))
	 (tenant-id (nth 0 paramslist)))
    (unless  ( or (null tenant-id) (zerop (length tenant-id)))
      (if (equal (dod-cust-login-as-guest :tenant-id tenant-id :session-time-limit 300) NIL) (hunchentoot:redirect "/hhub/customer-login.html") (hunchentoot:redirect  "/hhub/dodcustindex")))))


(defun dod-controller-delete-company ()
  (with-opr-session-check 
    (let ((id (hunchentoot:parameter "id")) )
      (delete-dod-company id)
      (hunchentoot:redirect "/list-companies"))))


(defun company-card (instance)
    (let ((comp-name (slot-value instance 'name))
	  (address  (slot-value instance 'address))
	  (city (slot-value instance 'city))
	  (state (slot-value instance 'state)) 
	  (country (slot-value instance 'country))
	  (zipcode (slot-value instance 'zipcode))
	  (suspended (slot-value instance 'suspend-flag))
	  (subscription-plan (slot-value instance 'subscription-plan))
	  (row-id (slot-value instance 'row-id))
	  (accountageindays (account-created-days-ago instance))
	  (trialaccexpirydays (trial-account-days-to-expiry instance)))
	(cl-who:with-html-output (*standard-output* nil)
	  (:div :class "row"
		(:div :class "col-xs-8" 
		      (:h3 (cl-who:str (if (> (length comp-name) 20)  (subseq comp-name 0 20) comp-name))))
		(:div :class "col-xs-1" :align "right" 
		      (:a  :data-toggle "modal" :data-target (format nil "#editcompany-modal~A" row-id)  :href "#"  (:i :class "fa-regular fa-pen-to-square"))
				(modal-dialog (format nil "editcompany-modal~a" row-id) "Add/Edit Group" (com-hhub-transaction-create-company-dialog row-id)))
		(:div :class "col-xs-2 dropdown" 
		      (:button :class "btn btn-primary dropdown-toggle" :type "button" :id "dropdownMenu1" :data-toggle "dropdown" :aria-haspopup "true" :aria-expanded "false" (:span :class "glyphicon glyphicon-option-vertical"))
		      (:ul :class "dropdown-menu" :aria-labelledby "dropdownMenu1"
			   (:li (:a :href (format nil "/hhub/sadmincreateusers?tenant-id=~a" row-id) "Manage Users"))
			   (if (equal suspended "Y")
			       (cl-who:htm 
				(:li (:a :href (format nil "/hhub/restoreaccount?tenant-id=~a" row-id) "Restore Account")))
			       ;else
			       (cl-who:htm 
				(:li (:a :href (format nil "/hhub/suspendaccount?tenant-id=~a" row-id) "Suspend Account"))))
			   (:li :role "separator" :class "divider" )
			   (:li (:a :href "#" "Delete")))))
		 
	  (:div :class "row"
		(:div :class "col-xs-12"  (cl-who:str (if (> (length address) 20)  (subseq address 0 20) address))))
	  (:div :class "row"
		(:div :class "col-xs-12" (cl-who:str city)))
	  (:div :class "row"
		(:div :class "col-xs-6" (cl-who:str state))
		(:div :class "col-xs-6" (cl-who:str country)))
	  (:div :class "row"
		(:div :class "col-xs-6" (cl-who:str zipcode)))
	  (if (equal suspended "Y")
	      (cl-who:htm (:div :class "stampbox rotated" "SUSPENDED")))
	  (with-html-div-row
	    (with-html-div-col
	      (:h5 (cl-who:str (format nil "No of Customers: ~A " (count-company-customers instance)))))
	    (with-html-div-col
	      (:h5 (cl-who:str (format nil  "No of Vendors: ~A " (count-company-vendors instance ))))))
	  (with-html-div-row
	    (with-html-div-col
	      (:h5 (cl-who:str (format nil  "Subscription Plan: ~A " subscription-plan)))))
	  (with-html-div-row
	    (with-html-div-col
	      (:h5 (cl-who:str (format nil "Account Age in Days: ~A" accountageindays))))
	  (when (equal subscription-plan "TRIAL")
	    (if (> trialaccexpirydays 0)
		(cl-who:htm
		 (with-html-div-col
		   (:h5 (cl-who:str (format nil "Days to Expiry: ~A" trialaccexpirydays )))))
		;;else
		(cl-who:htm (:div :class "stampbox rotated" "EXPIRED"))))))))


(defun dod-controller-list-companies ()
(with-opr-session-check
   (let (( companies (get-system-companies)))
    (with-standard-admin-page (:title "List companies")
      (ui-list-companies companies)))))

(defun ui-list-companies (company-list)
 (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
  (if company-list 
      (cl-who:htm
       (mapcar (lambda (cmp)
		 (let ((external-url (slot-value cmp 'external-url))
		       (cname (slot-value cmp 'name)))
		   (cl-who:htm
		    (with-html-div-col-4
		      (with-html-card nil "" cname ""
			(with-html-form "custsignup1form" "custsignup1action" 
			  (:div :class "form-group"
				(:input :type "hidden" :name  "cname" :value (cl-who:str (format nil "~A" cname))))
			  (:div :class "form-group"
				(:button :class "btn btn-sm btn-primary btn-block" :type "submit" (cl-who:str (format nil "~A - Sign Up" cname)))))
			(:a :target "_blank" :href (format nil "dascustloginasguest?tenant-id=~A" (slot-value cmp 'row-id)) (:i :class "fa-solid fa-shopping-cart") " Shop Now")
			(when external-url
			  (cl-who:htm (:div :class "col-xs-2" :align "right" :data-toggle "tooltip" :title "Copy External URL" 
					    (:a :href "#" :OnClick (parenscript:ps (copy-to-clipboard (parenscript:lisp external-url))) (:i :class  "fa-solid fa-share-nodes")))))))))) company-list))
					;else
      (cl-who:htm (with-html-div-col
		    (:h3 "Record Not Found."))))))
  
(defun get-login-user ()
  (hunchentoot:session-value :login-user))

(defun get-login-tenant-id ()
  (hunchentoot:session-value :login-tenant-id))

(defun get-login-cust-tenant-id ()
  (hunchentoot:session-value :login-customer-tenant-id))


(defun get-login-company ()
  ( hunchentoot:session-value :login-company))


(defun get-login-customer-company ()
  ( hunchentoot:session-value :login-customer-company))

(defun get-login-customer-company-name ()
    ( hunchentoot:session-value :login-customer-company-name))

(defun get-login-customer-company-id ()
  (let ((company (hunchentoot:session-value :login-customer-company)))
    (slot-value company 'row-id)))

(defun get-login-customer-type ()
    ( hunchentoot:session-value :login-customer-type))

(defun get-login-customer-company-website ()
    ( hunchentoot:session-value :login-customer-company-website))


(defun get-login-vendor-company ()
(hunchentoot:session-value :login-vendor-company))  

(defun get-login-vendor-company-name ()
 (hunchentoot:session-value :login-vendor-company-name))  
	
(defun get-login-vend-tenant-id ()
  (hunchentoot:session-value :login-vendor-tenant-id))

