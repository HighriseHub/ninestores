;;; registration.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)



(defmacro with-html-email-template ((&key title) &body body)
  `(cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
    (:html :xmlns "http://www.w3.org/1999/xhtml"
     (:head
    (:meta :content "text/html; charset=UTF-8" :http-equiv "Content-Type")
    (:meta :content "telephone=no" :name "format-detection" )
    (:meta :content "width=device-width, initial-scale=1.0" :name "viewport")
    
    (:title ,title)
    (:link :href "https://fonts.googleapis.com/css?family=catamaran" :rel "stylesheet")
    
    (:style :type "text/css" ,*HHUB-EMAIL-CSS-CONTENTS*))
    (:body :style "margin:0; padding:0; background-color: #eeeeee;" :bgcolor "#eeeeee" 

	   (:table :width "100%" :cellpadding "0" :cellspacing "0" :border "1" :bgcolor "#eeeeee"
      (:div :class "Gmail" :style "height: 1px !important; margin-top: -1px !important; max-width: 600px !important; min-width: 600px !important; width: 600px !important;")
      (:div :style "display: none; max-height: 0px; overflow: hidden;"
        "Paste your preview text here***")
      (:div :style "display: none; max-height: 0px; overflow: hidden;" 
        "&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;")

      (:tr
        (:td :width "100%" :valign "top" :align "center" :class "padding-container" :style "padding: 18px 0px 0px 0px!important; mso-padding-alt: 18px 0px 0px 0px;"
          (:table :width "600" :cellpadding "0" :cellspacing "0" :border "1" :align "center" :class "wrapper" :bgcolor "#eeeeee"
            (:tr
              (:td :align "center" :bgcolor "#eeeeee"
                (:a :href "http://paulgoddarddesign.com/emails/material-design" :target "_blank" :style "font-size: 12px; line-height: 14px; font-weight: 500; font-family: 'Roboto Mono', monospace; color: #212121; text-decoration: underline;padding: 0px; border: 1px solid #eeeeee; display: inline-block;" "View Online"))))))
,@body)))))


(defun hhub-email-logo ()
(cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
  (:tr
    (:td :width "100%" :valign "top" :align "center" :class "padding-container" :style "padding: 18px 0px 18px 0px!important; mso-padding-alt: 18px 0px 18px 0px;" 
	 (:table :width "600" :cellpadding "0" :cellspacing "0" :border "1" :align "center" :class "wrapper"
		 (:tr
		  (:td :align "center"
		       (:table :cellpadding "0" :cellspacing "0" :border "1" 
                  (:tr
                    (:td :width "100%" :valign "top" :align "center" 
                      (:table :width "600" :cellpadding "0" :cellspacing "0" :border "1" :align "center" :class "wrapper" :bgcolor "#eeeeee" 
                        (:tr 
                          (:td :align "center" 
                            (:table :width "600" :cellpadding "0" :cellspacing "0" :border "1" :class "container" :align "center" 
                              ; START HEADER IMAGE -- 
                              (:tr 
                                (:td :align "center" :class "hund" :width "600" 
     				     (:img :src (format nil "~A/img/logo.png" *siteurl*)  :width "300" :alt "Logo" :border "1" :style "max-width: 300px; display:block; " 
                                )))))))))))))))))

(defmacro with-single-column-email ((&key title) &body body)
 `(with-html-email-template (:title ,title)
  ;;;;;;;;;;;;;Put the logo here ;;;;;;;;;;;;;
   (cl-who:str (hhub-email-logo))
   (:tr
   (:td :width "100%" :valign "top" :align "center" :class "padding-container" :style "padding-top: 0px!important; padding-bottom: 18px!important; mso-padding-alt: 0px 0px 18px 0px;" 
	(:table :width "600" :cellpadding "0" :cellspacing "0" :border "1" :align "center" :class "wrapper" 
		(:tr
		 (:td 
		  (:table :cellpadding "0" :cellspacing "0" :border "1" 
			  (:tr
			   (:td :style ":border-radius: 3px; :border-bottom: 2px solid #d4d4d4;" :class "card-1" :width "100%" :valign "top" :align "center" 
				(:table :style ":border-radius: 3px;" :width "600" :cellpadding "0" :cellspacing "0" :border "1" :align "center" :class "wrapper" :bgcolor "#ffffff" 
					(:tr
					 (:td :align "center" 
					       (cl-who:str ,@body))))))))))))))

(defun customer-registration-html-content (customer verify-url)
  :documentation "You can insert any html table content here. It will be merged with the html display template on the upward journey" 
  (let* ((cust-name (slot-value customer 'name)))
	;(id (slot-value customer 'row-id)))
    (cl-who:with-html-output-to-string
	(*standard-output* nil :prologue t :indent t)
      (:table :width "600" :cellpadding "0" :cellspacing "0" :border "1" :class "container" 
	      (:tr 
	       (:td :class "td-padding" :align "left" (cl-who:str (format nil "Welcome ~A!" cust-name)))
	       (:tr
		(:td :class "td-padding" :align "left" :style "font-family: 'Roboto Mono', monospace; color: #212121!important; font-size: 24px; line-height: 30px; padding-top: 18px; padding-left: 18px!important; padding-right: 18px!important; padding-bottom: 0px!important; mso-line-height-rule: exactly; mso-padding-alt: 18px 18px 0px 13px;" 
		     "Thank you for registering. We appreciate your memebership. "))
	       
	       (:tr
		(:td :class "td-padding" :align "left" :style "font-family: 'Roboto Mono', monospace; color: #212121!important; font-size: 16px; line-height: 24px; padding-top: 18px; padding-left: 18px!important; padding-right: 18px!important; padding-bottom: 0px!important; mso-line-height-rule: exactly; mso-padding-alt: 18px 18px 0px 18px;" 
		     "Please click on the verification link below. "))
	       (:tr
		(:td :align "left" :style "padding: 18px 18px 18px 18px; mso-alt-padding: 18px 18px 18px 18px!important;" 
		     (:table :width "100%" :border "1" :cellspacing "0" :cellpadding "0" 
			     (:tr
			      (:td 
			       (:table :border "1" :cellspacing "0" :cellpadding "0" 
				       (:tr
					(:td :align "left" :style ":border-radius: 3px;" :bgcolor "#17bef7" 
					     (:a :class "button raised" :href verify-url :target "_blank" :style "font-size: 14px; line-height: 14px; font-weight: 500; font-family: Helvetica, Arial, sans-serif; color: #ffffff; text-decoration: none; :border-radius: 3px; padding: 10px 25px; :border: 1px solid #17bef7; display: inline-block;" "Activate Your Account") )))))))))))))

(defmethod send-test-email (customer)
  (let* ((reg-templ-str (hhub-read-file (format nil "~A/~A" *HHUB-EMAIL-TEMPLATES-FOLDER* *HHUB-CUST-REG-TEMPLATE-FILE*)))
	(cust-reg-email (format nil reg-templ-str (slot-value customer 'name)))) 
  (hhubsendmail "<<enter email to send>>" "Welcome to Nine Stores" cust-reg-email)))



(defun send-password-reset-link (object url) 
  :documentation "Here object is either CUSTOMER, VENDOR OR EMPLOYEE"
  (let* ((password-reset-str (hhub-read-file (format nil "~A/~A" *HHUB-EMAIL-TEMPLATES-FOLDER* *HHUB-CUST-PASSWORD-RESET-FILE* )))
	 (email (slot-value object 'email))
	 (password-reset-email (format nil password-reset-str url url)))
  (send-email-async email  "Your Password Reset Link" password-reset-email)))

(defun send-temp-password  (object temp-pass url)
  (let* ((temp-password-str (hhub-read-file (format nil "~A/~A" *HHUB-EMAIL-TEMPLATES-FOLDER* *HHUB-CUST-TEMP-PASSWORD-FILE* )))
	 (email (slot-value object 'email))
	 (temp-password-email (format nil temp-password-str temp-pass url ))) 
  (send-email-async email  "Your Password Has Been Reset" temp-password-email)))


(defun send-new-company-registration-email  (object custname phone email )
  (let* ((temp-str (hhub-read-file (format nil "~A/~A" *HHUB-EMAIL-TEMPLATES-FOLDER* *HHUB-NEW-COMPANY-REQUEST*)))
	 (cmpname (slot-value object 'name))
	 (cmpaddress (slot-value object 'address))
	 (cmpcity (slot-value object 'city))
	 (cmpstate (slot-value object 'state))
	 (cmpzipcode (slot-value object 'zipcode))
	 (cmpcountry (slot-value object 'country))
	 (cmpwebsite (slot-value object 'website))
	 (cmptype (slot-value object 'cmp-type))
	 (temp-str-email (format nil temp-str custname phone email cmpname cmpaddress cmpcity cmpstate cmpzipcode cmpcountry cmpwebsite cmptype )))
  (send-email-async *HHUBSUPPORTEMAIL*  "Nine Stores - New company registration request" temp-str-email)))

(defun send-contactus-email (firstname lastname businessname email subject message)
  :documentation "Send the email with data filled from the contact us form"
(let* ((temp-str (hhub-read-file (format nil "~A/~A" *HHUB-EMAIL-TEMPLATES-FOLDER*  *HHUB-CONTACTUS-EMAIL-TEMPLATE* )))
      (temp-str-email (format nil temp-str firstname lastname businessname email message)))
  (send-email-async *HHUBSUPPORTEMAIL* subject temp-str-email)))

  
(defun send-registration-email (name email)
  (let* ((reg-templ-str (hhub-read-file (format nil "~A/~A" *HHUB-EMAIL-TEMPLATES-FOLDER* *HHUB-CUST-REG-TEMPLATE-FILE*)))
	 (cust-reg-email (format nil reg-templ-str name)))
    (send-email-async email "Welcome to Nine Stores" cust-reg-email)))

;; ── %Token% filling for email templates — the invoicetemplatefill pattern, adapted ──────────
;; One ordered cl-ppcre pass per token, NIL rendered as "". A NIL passed to cl-ppcre AS the
;; replacement gets CALLED (nil-safe-template-substitution-CONTEXT.md), so the value is guarded here.
(defun hhub-fill-email-template (template replacements)
  :documentation "Replace every (\"%Token%\" . VALUE) in TEMPLATE, in list order, the way invoicetemplatefill fills an invoice template. VALUE may be any printable or NIL."
  (dolist (pair replacements template)
    (let ((value (cdr pair)))
      (setf template (cl-ppcre:regex-replace-all (car pair) template
						 (if value (princ-to-string value) ""))))))

(defun send-vendor-registered-email (vendor company)
  :documentation "Vendor onboarding E1: the row is committed, the company administrator holds the approval, and the vendor cannot sign in yet. A mail failure must never roll back the registration."
  (let ((to (slot-value vendor 'email))
	(cmpname (slot-value company 'name)))
    (when to
      (let* ((templ-str (hhub-read-file (format nil "~A/~A" *HHUB-EMAIL-TEMPLATES-FOLDER* *HHUB-VENDOR-REGISTERED-TEMPLATE-FILE*)))
	     (body (hhub-fill-email-template templ-str
					     (list (cons "%CompanyName%" cmpname)
						   (cons "%VendorName%" (slot-value vendor 'name))
						   (cons "%VendorPhone%" (slot-value vendor 'phone))
						   (cons "%VendorEmail%" to)
						   (cons "%SupportEmail%" *HHUBSUPPORTEMAIL*)))))
	(hhub-log-message (format nil "~&[vendor-onboarding] E1 -> ~A (vendor ~A, tenant ~A)~%"
				  to (slot-value vendor 'name) (slot-value company 'row-id)))
	(send-email-async to (format nil "Registration received - ~A on Nine Stores" cmpname) body nil :persona :vendor)))))

(defun send-vendor-admin-pending-email (vendor company)
  :documentation "Vendor onboarding E2: tell each COMPANY ADMINISTRATOR that a vendor is waiting on them. The vendor cannot sign in until one of them approves, and nothing else in the system asks them to."
  (let* ((tenant-id (slot-value company 'row-id))
	 (cmpname (slot-value company 'name))
	 (vname (slot-value vendor 'name))
	 (vemail (slot-value vendor 'email))
	 (gst (and (slot-boundp vendor 'gstnumber) (slot-value vendor 'gstnumber)))
	 (pending (ignore-errors (length (get-vendors-for-approval tenant-id))))
	 (recipients (select-compadmin-emails-for-tenant tenant-id)))
    (hhub-log-message (format nil "~&[vendor-onboarding] E2 -> ~A (admin of tenant ~A ~A, vendor ~A)~%"
			      recipients tenant-id cmpname vname))
    (when recipients
      (let ((templ-str (hhub-read-file (format nil "~A/~A" *HHUB-EMAIL-TEMPLATES-FOLDER* *HHUB-VENDOR-ADMIN-PENDING-TEMPLATE-FILE*))))
	(dolist (admin-email recipients)
	  (let ((body (hhub-fill-email-template templ-str
						(list (cons "%VendorName%" vname)
						      (cons "%CompanyName%" cmpname)
						      (cons "%VendorPhone%" (slot-value vendor 'phone))
						      (cons "%VendorEmail%" vemail)
						      (cons "%GSTINLine%" (if gst (format nil "GSTIN: ~A" gst) "GSTIN: not provided"))
						      (cons "%QueueUrl%" (format nil "~A/hhub/hhubvendorapprovalpage" *siteurl*))
						      (cons "%PendingCount%" pending)
						      (cons "%SupportEmail%" *HHUBSUPPORTEMAIL*)))))
	    (send-email-async admin-email
			      (format nil "Approval needed - ~A registered as a vendor" vname)
			      body nil :persona :admin)))))))

(defun send-vendor-approved-email (vendor company)
  :documentation "Vendor onboarding E3: the approval is committed; tell the vendor they are live and give them the three jobs. A mail failure must never roll back the approval."
  (handler-case
      (let ((to (slot-value vendor 'email))
	    (cmpname (and company (slot-value company 'name))))
	(when (and to cmpname)
	  (let* ((templ-str (hhub-read-file (format nil "~A/~A" *HHUB-EMAIL-TEMPLATES-FOLDER* *HHUB-VENDOR-APPROVED-TEMPLATE-FILE*)))
		 (body (hhub-fill-email-template templ-str
						 (list (cons "%CompanyName%" cmpname)
						       (cons "%VendorName%" (slot-value vendor 'name))
						       (cons "%VendorPhone%" (slot-value vendor 'phone))
						       (cons "%ApprovedDate%" (current-date-string-ddmmyyyy))
						       (cons "%LoginUrl%" (format nil "~A/hhub/hhubvendloginv2" *siteurl*))
						       (cons "%SupportEmail%" *HHUBSUPPORTEMAIL*)))))
	    (hhub-log-message (format nil "~&[vendor-onboarding] E3 -> ~A (vendor ~A, tenant ~A)~%"
				      to (slot-value vendor 'name) (slot-value company 'row-id)))
	    (send-email-async to (format nil "Approved - you can sign in to ~A" cmpname) body nil :persona :vendor))))
    (error (c)
      (hhub-log-message (format nil "~&[vendor-onboarding] E3 FAILED for vendor ~A: ~A~%"
				(ignore-errors (slot-value vendor 'name)) c))
      nil)))

(defun send-order-mail (email subject  order-disp-str)
  :documentation "Renders the guest order email and hands it to the shared email actor, so the calling request does not wait for SMTP."
  (let* ((order-templ-str (hhub-read-file (format nil "~A/~A" *HHUB-EMAIL-TEMPLATES-FOLDER* *HHUB-GUEST-CUST-ORDER-TEMPLATE-FILE*)))
	 (cust-order-email (format nil order-templ-str order-disp-str)))
    (send-email-async email subject cust-order-email)))


(defun send-order-email-behavior (state messagefunc)
  (multiple-value-bind (email subject  order-disp-str) (funcall messagefunc) 
    (let* ((order-email-templ (funcall  (nst-get-cached-email-template-func :templatenum 1)))
	   (cust-order-email (format nil order-email-templ order-disp-str)))
      (hhubsendmail email subject cust-order-email)
      (incf state))))


(defun send-generic-email-behavior (state messagefunc)
  :documentation "Actor behaviour that sends an already rendered email : the message returns (values to subject body)."
  (multiple-value-bind (to subject body attachments) (funcall messagefunc)
    (hhubsendmail to subject body *HHUBSMTPSENDER* attachments)
    (incf state)))


(defun send-email-async (to subject body &optional attachments &key persona)
  :documentation "Queues an email on the dedicated PERSONA actor (:vendor, later :customer/:admin), falling back to the shared generic actor and then to an inline send, instead of blocking the calling request thread on the SMTP round trip. Returns T when the actor accepted the message. A send that fails is retried by the actor and then dead lettered, so a mail outage shows up in the log instead of in the caller's stack. ATTACHMENTS is a cl-smtp attachment list (pathnames, pathname strings or cl-smtp:make-attachment objects); it is read from disk when the actor performs the send, so the file must still exist then. The persona actors are built and disposed in nst-server-context.lisp; see vendoronboarding-ACTORS.md."
  (let ((actor (or (cdr (assoc persona *NST-EMAIL-ACTORS*))
		   *NSTGENERICEMAILACTOR*)))
    (if actor
	(send-message actor (lambda () (values to subject body attachments)))
	;;else the actor is not up (early startup, tests) : send it inline rather than lose it
	(progn (hhubsendmail to subject body *HHUBSMTPSENDER* attachments) t))))



