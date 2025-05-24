;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defun render-invoice-settings-menu ()
    (cl-who:with-html-output (*standard-output* nil :prologue t :indent t)
      (:div :class "offcanvas offcanvas-end" :tabindex"-1" :id "idInvoiceSettingsOffCanvas" :aria-labelledby "idInvoiceSettingsOffCanvasLabel" :style  "background: rgb(222,228,255);
background: linear-gradient(171deg, rgba(222,228,255,1) 0%, rgba(224,236,255,1) 100%); "
	    (:div :class "offcanvas-header"
		  (:img :src "/img/logo.png" :alt "" :width "32" :height "32" :class "rounded-circle me-2")
		  (:h5 :class "offcanvas-title" :id "idInvoiceSettingsOffCanvasLabel" "Invoice Settings")
		  (:button :type "button" :class "btn-close btn-close" :data-bs-dismiss "offcanvas" :aria-label "Close"))
	    (:div :class "offcanvas-body"
		  (:ul :class "nav nav-tabs flex-column mb-auto"
		       (:li :class "nav-item"
			    (:a :href "displayinvoices"
				(:i :class "fa-solid fa-house")  "&nbsp;&nbsp;Invoices"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear")  " General Invoice Settings"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear")  " Design & Branding"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear")  " Payment & Sharing"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear")  " Notifications & Alerts"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear")  " Advanced Settings"))
		       
		       (:li :class "nav-item"
			    (:a :href "/hhub/hhubvendorupitransactions"  :class "nav-link link-body-e mphasis"
				(:i :class "fa-solid fa-gear")  " Customer Management"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/hhubvendmycustomers" :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear") " Reporting & Analytics"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-solid fa-gear") " Security"))))))))


(defun com-hhub-transaction-invoice-settings-page ()
  (with-vend-session-check
    (with-mvc-ui-page "Invoice Settings Page" createmodelforinvoicesettingspage createwidgetsforinvoicesettingspage :role :vendor)))

(defun createmodelforinvoicesettingspage ()
  (let* ((vinvsettings (hunchentoot:session-value :login-vendor-invoice-settings))
	 (printsettings (cdr (assoc 'invoice-print-settings vinvsettings :test 'equal)))
	 (vinvsettingshtml (funcall (nst-get-cached-invoice-template-func :templatenum 11)))
	 (idinvsettings (format nil "idvinvsettings~A" (gensym))))

    (setf vinvsettingshtml (format nil vinvsettingshtml (invoiceprintsettingswidgethtml printsettings )))
    (function (lambda ()
      (values idinvsettings vinvsettingshtml)))))

(defun createwidgetsforinvoicesettingspage (modelfunc)
  (multiple-value-bind (idinvsettings vinvsettingshtml) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-catch-submit-event idinvsettings
			 (cl-who:str vinvsettingshtml)))))))
      (list widget1))))



(defun invoiceprintsettingswidgethtml (printsettings)
  (let ((papersize-ht (make-hash-table :test 'equal))
	(orientation-ht (make-hash-table :test 'equal))
	(papersize (cdr (assoc :DEFAULTPAPERSIZE printsettings :test 'equal)))
	(orientation (cdr (assoc :ORIENTATION printsettings :test 'equal)))
	(fontsize (cdr (assoc :FONTSIZE printsettings :test 'equal)))
	(margintop (cdr (assoc :TOP (cdr (assoc :MARGIN printsettings :test 'equal)))))
	(marginbottom (cdr (assoc :BOTTOM (cdr (assoc :MARGIN printsettings :test 'equal)))))
	(marginleft (cdr (assoc :LEFT (cdr (assoc :MARGIN printsettings :test 'equal)))))
	(marginright (cdr (assoc :RIGHT (cdr (assoc :MARGIN printsettings :test 'equal)))))
	(headerenable (cdr (assoc :ENABLE (cdr (assoc :HEADER printsettings :test 'equal)))))
	(headertext (cdr (assoc :TEXT (cdr (assoc :HEADER printsettings :test 'equal)))))
	(headerlogopath (cdr (assoc :LOGO-PATH (cdr (assoc :HEADER printsettings :test 'equal)))))
	(footerenable (cdr (assoc :ENABLE (cdr (assoc :FOOTER printsettings :test 'equal)))))
	(footertext (cdr (assoc :TEXT (cdr (assoc :FOOTER printsettings :test 'equal)))))
	(watermarkenable (cdr (assoc :ENABLE (cdr (assoc :WATERMARK printsettings :test 'equal)))))
	(watermarktext (cdr (assoc :TEXT (cdr (assoc :WATERMARK printsettings :test 'equal))))))
	
    
    (setf (gethash "A4" papersize-ht) "A4")
    (setf (gethash "Letter" papersize-ht) "Letter")
    (setf (gethash "Legal" papersize-ht) "Legal")
    (setf (gethash "Portrait" orientation-ht) "Portrait")
    (setf (gethash "Landscape" orientation-ht) "Landscape")
    
    (cl-who:with-html-output-to-string (*standard-output* nil)
      ;;<!-- Default Paper Size -->
      (:div :class "mb-3"
	    (:label :for "defaultpapersize" :class "form-label" "Default Paper Size")
	    (with-html-dropdown "defaultpapersize" papersize-ht papersize))

      ;; orientation
          (:div :class "mb-3"
		(:label :for "orientation" :class "form-label" "Orientation")
		(with-html-dropdown "orientation" orientation-ht orientation))
      ;; Fontsize
      (:div :class "mb-3"
	    (:label :for "fontsize" :class "form-label" "Font Size")
	    (:input :type "number" :class "form-control" :id "fontsize" :value fontsize))

      ;; Margins
      
      (:div :class "mb-3"
	    (:label :class "form-label" "Margins (in cm)")
	    (:div :class "row g-2"
		  (:div :class "col" 
			(:label :for "margintop" :class "form-label" "Top")
			(:input :type "text" :class "form-control" :id "margintop" :value margintop))
		  (:div :class "col" 
			(:label :for "marginbottom" :class "form-label" "Bottom")
			(:input :type "text" :class "form-control" :id "marginbottom" :value marginbottom))
		  (:div :class "col" 
			(:label :for "marginleft" :class "form-label" "Left")
			(:input :type "text" :class "form-control" :id "marginleft" :value marginleft))
		  (:div :class "col" 
			(:label :for "marginright" :class "form-label" "Right")
			(:input :type "text" :class "form-control" :id "marginright" :value marginright))))
      ;; Header
      (:div :class "mb-3"
	    (:label :class "form-label" "Header")
      	    (:div :class "form-check form-switch"
		  (if headerenable
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "headerenable" :checked  T))
		      ;;else
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "headerenable")))
		       
		  (:label :class "form-check-label" :for "headerenable" "Enable Header"))
	    (:div :class "mt-2"
		  (:label :for "headertext" :class "form-label" "Header Text")
		  (:input :type "text" :class "form-control" :id "headertext" :value headertext))
	    (:div :class "mt-2"
		  (:label :for "headerlogopath" :class "form-label" "Logo Path")
		  (:input :type "file" :class "form-control" :name "headerlogopath" :id "headerlogopath" :value headerlogopath)))
      ;; Footer
      (:div :class "mb-3"
	    (:label :class "form-label" "Footer")
      	    (:div :class "form-check form-switch"
		  (if footerenable
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "footerenable" :checked  T))
		      ;;else
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "footerenable")))
		  (:div :class "mt-2"
		  (:label :for "footertext" :class "form-label" "Footer Text")
		  (:input :type "text" :class "form-control" :id "footertext" :value footertext))))
      ;; Watermark
      (:div :class "mb-3"
	    (:label :class "form-label" "Watermark")
      	    (:div :class "form-check form-switch"
		  (if watermarkenable
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "watermarkenable" :checked  T))
		      ;;else
		      (cl-who:htm
		       (:input :class "form-check-input" :type "checkbox" :id "watermarkenable")))
		  (:div :class "mt-2"
		  (:label :for "watermarktext" :class "form-label" "Watermark Text")
		  (:input :type "text" :class "form-control" :id "watermarktext" :value watermarktext))))
      )))

(defun com-hhub-transaction-save-invoice-print-settings-action ()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforinvoiceprintsettingsaction createwidgetsforgenericredirect)))

(defun createmodelforinvoiceprintsettingsaction ()
  (let* ((vendor (get-login-vendor))
	 (vendor-id (get-login-vendor-id))
	 (tenant-id (get-login-vendor-tenant-id))
	 (printsettings (hunchentoot:parameter "vinvprintsettings"))
	 (json-response (with-input-from-string (stream printsettings) (cl-json:decode-json stream)))
	 (vinvsettings *invoice-settings*)
	 (imageparams (hunchentoot:post-parameter "headerlogopath"))
	 (tempfilewithpath (first imageparams))
	 (file-name (if tempfilewithpath (process-file imageparams *HHUBRESOURCESDIR*)))
	 (redirecturl "/hhub/vinvoicesettingspage"))
    (logiamhere (format nil "headerlogopath is ~A" tempfilewithpath))
    (if tempfilewithpath 
	(let ((s3filelocation (vendor-upload-file-s3bucket file-name "CFG" "logo123" vendor-id tenant-id )))
	  (setf (cdr (assoc :LOGO-PATH (cdr (assoc :HEADER json-response :test 'equal)))) s3filelocation)))
    (setf (cdr (assoc 'invoice-print-settings vinvsettings)) json-response)
    (setf (slot-value vendor 'invoice-settings) (write-to-string vinvsettings :readably t))
    (setf (hunchentoot:session-value :login-vendor-invoice-settings) vinvsettings)
    (update-vendor-details vendor)
    (function (lambda ()
      (values redirecturl)))))





(defun com-hhub-transaction-copy-invoice ()
  )

(defun com-hhub-transaction-download-invoice()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelfordownloadinvoice createwidgetsforgenericredirect)))

(defun createmodelfordownloadinvoice ()
  (let* ((sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (invnum (slot-value sessioninvheader 'invnum))
	 (external-url (slot-value sessioninvheader 'external-url))
	 (htmlfile (download-html-file external-url))
	 (pdffileurl (format nil "~A/img/temp/~A" *siteurl* (generate-pdf htmlfile invnum))))
    (function (lambda ()
      (values pdffileurl)))))



(defun com-hhub-transaction-send-invoice-email ()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforsendinvoiceemail createwidgetsforgenericredirect)))

(defun createmodelforsendinvoiceemail ()
  (let* ((sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (to (hunchentoot:parameter "invoiceto"))
	 (subject (hunchentoot:parameter "draftinvoicesubject"))
	 (emailbody (hunchentoot:parameter "draftinvoiceemailbody"))
	 (redirecturl (format nil "/hhub/editinvoicepage?invnum=~A" sessioninvkey)))
    (sb-thread:make-thread
     (lambda ()
       (hhubsendmail to subject emailbody)) :name "Invoice Email Thread")
    (function (lambda ()
      (values redirecturl)))))

(defun com-hhub-transaction-edit-invoice-email ()
  (with-vend-session-check
    (with-mvc-ui-page "Invoice Email" createmodelfordisplayinvoiceemail createwidgetsfordisplayinvoiceemail :role :vendor)))

(defun createmodelfordisplayinvoiceemail ()
  (let* ((templatenum (parse-integer (hunchentoot:parameter "templatenum")))
	 (invoicetemplate (funcall (nst-get-cached-invoice-template-func :templatenum templatenum)))
	 (company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (address (slot-value vendor 'address))
	 (phone (slot-value vendor 'phone))
	 (email (slot-value vendor 'email))
	 (vendorname (slot-value vendor 'name))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))   
	 (sessioninvcustomer (slot-value sessioninvoice 'Customer))
	 (invnum (slot-value sessioninvheader 'invnum))
	 (invdate (get-date-string (slot-value sessioninvheader 'invdate)))
	 (external-url (slot-value sessioninvheader 'external-url))
	 (companyname (slot-value company 'name))
	 (customername (slot-value sessioninvcustomer 'name))
	 (totalvaluewithgst (format nil "~d" (calculate-invoice-totalaftertax sessioninvitems)))
	 (totalvaluewithoutgst (format nil "~d" (calculate-invoice-totalbeforetax sessioninvitems)))
	 (to (slot-value sessioninvcustomer 'email))
	 (idtextarea (format nil "~Atextarea" (gensym "hhub")))
	 (charcountid1 (format nil "idchcount~A" (hhub-random-password 3)))
	 (subject "Test Invoice")
	 (logo-url (format nil "~A~A" *siteurl* *HHUBDEFAULTLOGOIMG*))
	 (contact-information (format nil "~A~C~C, ~A~C~C, ~A~C~C" address #\return #\linefeed phone #\return #\linefeed email #\return #\linefeed)))


    (case templatenum
      (1 (setf subject (format nil "Proforma/Draft Invoice for Your Review ~A" invnum)))
      (2 (setf subject (format nil "Payment Reminder for Your Invoice ~A" invnum)))
      (3 (setf subject (format nil "Overdue Payment Reminder for Your Invoice ~A" invnum)))
      (4 (setf subject (format nil "Thank You for Payment of Invoice ~A" invnum)))
      (5 (setf subject (format nil "Invoice ~A has been Shipped" invnum)))
      (6 (setf subject (format nil "Invoice ~A has been Cancelled!" invnum)))
      (7 (setf subject (format nil "Invoice ~A has been Refunded!" invnum))))
      
    
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Number%" invoicetemplate invnum))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Date%" invoicetemplate invdate))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Company Name%" invoicetemplate companyname))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Customer Name%" invoicetemplate customername))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total Amount without GST%" invoicetemplate totalvaluewithoutgst))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total Amount with GST%" invoicetemplate totalvaluewithgst))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Your Name%" invoicetemplate vendorname))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%INVOICE_LINK%" invoicetemplate external-url))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%LOGO_URL%" invoicetemplate logo-url))
    (setf invoicetemplate (cl-ppcre:regex-replace-all "%Contact Information%" invoicetemplate contact-information))
    
    (function (lambda ()
      (values invoicetemplate to subject idtextarea charcountid1 sessioninvkey)))))

(defun createwidgetsfordisplayinvoiceemail (modelfunc)
  (multiple-value-bind (draftemailtext to subject idtextarea charcountid1 sessioninvkey) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (with-html-div-col-8 :align "center"
			   (:br)
			   (:h2 (cl-who:str subject))))
		       (with-html-div-row
			 (with-html-div-col-2 "")
			 (with-html-div-col-8
			   (:img :class "profile-img" :src "/img/logo.png" :alt "")
			   (with-html-form-having-submit-event "nstdraftinvoiceemailform" "invoicemailaction"
			     (with-html-input-text-hidden "sessioninvkey" sessioninvkey) 
			     (:div :class "panel panel-default"
				   (:div :class "panel-heading" "From: support@ninestores.in"
					 (:div :class "panel-body"
					       ;;Panel content
					       (:div :class "form-group"
						     (:input :class "form-control" :name "invoiceto" :maxlength "90"  :value to :placeholder "Business Email Address " :type "email" :data-error "Invalid Email Address" :required T ))
					       (:div :class "form-group"
						     (:input :class "form-control" :name "draftinvoicesubject" :maxlength "100"  :value subject :placeholder "Subject " :type "text" :required T  ))
					       (:div  :class "form-group"
						      (:label :for idtextarea "Enter Email Text")
						      (text-editor-control idtextarea draftemailtext))
					       (:div :class "form-floating"
						     (:textarea :class "form-control" :placeholder "Enter email text" :id idtextarea :name "draftinvoiceemailbody"  :style "height: 200px" :onkeyup (format nil "countChar(~A.id, this, 5000)" charcountid1) (cl-who:str (format nil "~A" draftemailtext))))
					       (:div :class "form-group" :id charcountid1 )
					       (:div :class "form-group"
						     (:label "By clicking submit, you consent to allow Nine Stores to store and process the personal information submitted above to provide you the content requested. We will not share your information with other companies."))
					       (:div :class "form-group"
						     (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Send"))))))))
		       (:div  :class "hhub-footer" (hhub-html-page-footer)))))))
    (list widget1))))

(defun generate-invoice-ext-url (invnum vendor company)
  :description "Generates an external URL for a product, which can be shared with external entities"
  (let* ((tenant-id (slot-value company 'row-id))
	 (vendor-id (slot-value vendor 'row-id))
	 (param-csv (format nil "tenant-id,invnum,vendor-id~C~A,~A,~A" #\linefeed tenant-id invnum vendor-id))
	 (param-base64 (cl-base64:string-to-base64-string param-csv)))
    (format nil "~A/hhub/displayinvoicepublic?key=~A" *siteurl* param-base64)))


(defun createmodelfordisplayinvoicepublic ()
  (let* ((invoicetemplate (funcall (nst-get-cached-invoice-template-func :templatenum 9)))  
    	 (parambase64 (hunchentoot:parameter "key"))
	 (param-csv (cl-base64:base64-string-to-string (hunchentoot:url-decode parambase64)))
	 (paramslist (first (cl-csv:read-csv param-csv
					     :skip-first-p T
					     :map-fn #'(lambda (row)
							 row))))
	 (tenant-id (nth 0 paramslist))
	 (invnum (nth 1 paramslist))
	 (vendor-id (nth 2 paramslist))
	 (vendor (select-vendor-by-id vendor-id))
	 (company (select-company-by-id tenant-id))
	 (hrequestmodel (make-instance 'InvoiceHeaderRequestModel
				      :invnum invnum
				      :company company))
	 (headeradapter (make-instance 'InvoiceHeaderAdapter))
	 (invheader (processreadrequest headeradapter hrequestmodel))
         (invnum (slot-value invheader 'invnum))
	 (irequestmodel (make-instance 'InvoiceItemRequestModel
				       :company company
				       :invoiceheader invheader))
	 (itemsadapter (make-instance 'InvoiceItemAdapter))
	 (sessioninvitems (processreadallrequest itemsadapter irequestmodel))
	 (invoiceitemshtmlfunc (invoicetemplatefillitemrowspublic sessioninvitems))
	 (totalvalue (calculate-invoice-totalaftertax sessioninvitems))
	 (currency (get-account-currency company))
	 (qrcodepath (format nil "~A/img~A" *siteurl* (generateqrcodeforvendor vendor "ABC" invnum totalvalue))))

    (setf invoicetemplate (funcall (invoicetemplatefill invoicetemplate invheader sessioninvitems invoiceitemshtmlfunc qrcodepath currency vendor)))
    (function (lambda ()
      (values  invoicetemplate)))))

(defun createwidgetsfordisplayinvoicepublic (modelfunc)
  (multiple-value-bind ( invoicetemplate) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(:hr :style "border-top: 2px dashed gray;")
			(cl-who:str invoicetemplate))))))
      (list widget1))))

(defun invoicetemplatefill (invoicetemplate invheader invoiceitems invoiceitemshtmlfunc  qrcodepath currency vendor) 
  (function (lambda ()
    (with-slots (name address gstnumber) vendor
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Vendor Name%" invoicetemplate name))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Vendor Address%" invoicetemplate address))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Vendor GST%" invoicetemplate gstnumber)))

    (with-slots (row-id invnum invdate customer  custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear status vendor company) invheader
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Number%" invoicetemplate invnum))
      ;;(setf invoicetemplate (cl-ppcre:regex-replace-all "%Order Number%" invoicetemplate ordernum))
      ;;(setf invoicetemplate (cl-ppcre:regex-replace-all "%Order Date%" invoicetemplate orderdate))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Date%" invoicetemplate (get-date-string invdate)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Status%" invoicetemplate status))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Date of Supply%" invoicetemplate ""))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%State Code%" invoicetemplate (gethash statecode *NSTGSTSTATECODES-HT*)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Place of Supply%" invoicetemplate (gethash placeofsupply *NSTGSTSTATECODES-HT*)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Reverse Charge%" invoicetemplate revcharge))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Vehicle Number%" invoicetemplate vnum))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Transportation Mode%" invoicetemplate transmode))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Billed To%" invoicetemplate (slot-value customer 'name)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Shipped To%" invoicetemplate (slot-value customer 'name)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Billed to Address%" invoicetemplate billaddr))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Shipped to Address%" invoicetemplate shipaddr))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Billed to GSTIN%" invoicetemplate custgstin))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Shipped to GSTIN%" invoicetemplate custgstin))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Billed to State%" invoicetemplate (gethash statecode *NSTGSTSTATECODES-HT*)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Shipped to State%" invoicetemplate (gethash statecode *NSTGSTSTATECODES-HT*)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%UPI_IMAGE_URL%" invoicetemplate qrcodepath))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total in Words%" invoicetemplate (convert-number-to-words-INR (calculate-invoice-totalaftertax invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total Value%" invoicetemplate (format nil "~A" (calculate-invoice-totalaftertax invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total Value before GST/TAX%" invoicetemplate (format nil "~A" (calculate-invoice-totalbeforetax invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Total After Tax%" invoicetemplate (format nil "~A ~A" (get-currency-html-symbol currency) (calculate-invoice-totalaftertax invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Tax Amount%" invoicetemplate (format nil "~A" (calculate-invoice-totalgst invheader invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Add CGST%" invoicetemplate (format nil "~A" (calculate-invoice-totalcgst invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Add SGST%" invoicetemplate (format nil "~A" (calculate-invoice-totalsgst invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Add IGST%" invoicetemplate (format nil "~A" (calculate-invoice-totaligst invoiceitems))))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Terms and Conditions%" invoicetemplate tnc))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Authorised Signatory%" invoicetemplate authsign))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Financial Year%" invoicetemplate finyear))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Company Name%" invoicetemplate (slot-value company 'name)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Bank IFSC Code%" invoicetemplate bankifsccode))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Bank Account Number%" invoicetemplate bankaccnum))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%GST on Reverse Charge%" invoicetemplate revcharge)))
      (setf invoicetemplate (cl-ppcre:regex-replace-all "%Invoice Items Rows%" invoicetemplate (funcall invoiceitemshtmlfunc)))
      invoicetemplate)))
      

(defun com-hhub-transaction-display-invoice-public ()
    (with-mvc-ui-page "Display Invoice Public" createmodelfordisplayinvoicepublic createwidgetsfordisplayinvoicepublic :role :vendor))

;;;;;;;;;;;;;;;;;;;;;;;; INVOICE EMAIL OPTIONS MENU ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun invoice-email-options-menu (status sessioninvkey)
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "dropdown"  
	      (:button :id "idinvoiceemailmenu" :class "btn  dropdown-toggle" :type "button" :data-bs-toggle "dropdown" :aria-expanded "false"
		       (:i :class "fa-regular fa-envelope"))
	      (:ul :class "dropdown-menu" :aria-labelledby "idinvoiceemailmenu" 
		   (:li (:h6 :class "dropdown-header" "Send Invoice Email Options"))
		   (if (equal status "DRAFT")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=1" sessioninvkey) (:i :class "fa-regular fa-pen-to-square") "&nbsp;Draft/Proforma Invoice")))
		       ;;else
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-regular fa-pen-to-square") "&nbsp;Draft/Proforma Invoice"))))
		   (:li (:hr :class "dropdown-divider"))
		   (if (equal status "PENDINGPAYMENT")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=2" sessioninvkey) (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Payment Reminder"))
			(:li 
		    (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=3" sessioninvkey) (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Overdue Payment Reminder")))
		       ;;else
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Payment Reminder")
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Overdue Payment Reminder"))))
		   (if (equal status "PAID")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=4" sessioninvkey) (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Paid Invoice")))
		       ;;else
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-indian-rupee-sign") "&nbsp;Paid Invoice"))))
		   (:li (:hr :class "dropdown-divider"))
		   (if (equal status "SHIPPED")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=5" sessioninvkey) (:i :class "fa-solid fa-truck-fast") "&nbsp;Shipped Invoice")))
		       ;;else
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-truck-fast") "&nbsp;Shipped Invoice"))))
		   
		   (if (equal status "CANCELLED")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=6" sessioninvkey) (:i :class "fa-solid fa-xmark") "&nbsp;Cancelled Invoice")))
		       ;;else
		       (cl-who:htm
			(:li
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-xmark") "&nbsp;Cancelled Invoice"))))
		   (if (equal status "REFUNDED")
		       (cl-who:htm
			(:li 
			 (:a :class "dropdown-item" :href (format nil "/hhub/displayinvoiceemail?sessioninvkey=~A&templatenum=7" sessioninvkey) (:i :class "fa-solid fa-arrow-rotate-left") "&nbsp;Returned/Refunded Invoice")))
		       ;;else
		       (cl-who:htm
			(:li
			 (:a :class "dropdown-item disabled" :href "#" :aria-disabled "true" (:i :class "fa-solid fa-arrow-rotate-left") "&nbsp;Returned/Refunded Invoice"))))
		   ))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;; INVOICE ACTION MENU ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun invoice-header-actions-menu (external-url status sessioninvkey customer)
  (let ((phone (slot-value customer 'phone)))
    (cl-who:with-html-output (*standard-output* nil)
    (with-html-div-row :style "border-radius: 5px;background-color:#e6f0ff; border-bottom: solid 1px; margin: 15px; padding: 5px; height: 30px; font-size: 1rem;"
      (with-html-div-col-1 :data-bs-toggle "popover" :title "Print Invoice"
	(:a :href (format nil "vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) :onclick (format nil "window.open(this.href).print(); return false;") (:i :class "fa-solid fa-print")))
      (with-html-div-col-1
	(invoice-email-options-menu status sessioninvkey))
      (with-html-div-col-1 :data-bs-toggle "popover" :title "Duplicate Invoice"
	(:a :href "#"  (:i :class "fa-regular fa-clone")))
      (with-html-div-col-1 :data-bs-toggle "popover" :title "Download Invoice PDF"
	(with-html-form-having-submit-event "invoicedownloadform" "downloadinvoice"
	  (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
	  (:button :class "btn" :type "submit" :id "iddownloadinvoicebtn" (:i :class "fa-regular fa-file-pdf"))))
      (if external-url
	  (cl-who:htm
	   (with-html-div-col-1  :data-bs-toggle "popover" :title "Share LIVE Invoice Link" 
	     (:a :href "#" :OnClick (parenscript:ps (copy-to-clipboard (parenscript:lisp external-url))) (:i :class  "fa-solid fa-link"))))
	  ;;else
	  (cl-who:htm
	   (with-html-div-col-1 "&nbsp;")))
      
      (with-html-div-col-1 :data-bs-toggle "popover" :title "Customer WhatsApp" 
	(:a :target "_blank" :style "font-weight: bold; font-size: 1.2rem !important;"  :href (format nil "createwhatsapplinkwithmessage?phone=~A&message=Hi" phone)  (:i :class "fa-brands fa-whatsapp")))
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-2 :align "right" :data-bs-toggle "popover" :title "DELETE INVOICE!" 
	(:a :onclick "return DeleteConfirm();"  :href "#" (:i :class "fa-solid fa-trash-can")))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ALL INVOICES ACTION MENU ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun invoices-actions-menu (sessioninvkey)
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-div-row :style "border-radius: 5px;background-color:#e6f0ff; border-bottom: solid 1px; margin: 15px; padding: 5px; height: 30px; font-size: 1rem;"
      (with-html-div-col-1 :data-bs-toggle "popover" :title "Print Invoice"
	(:a :href (format nil "vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) :onclick (format nil "window.open(this.href).print(); return false;") (:i :class "fa-solid fa-print")))
      (with-html-div-col-1 :data-bs-toggle "popover" :title "GSTR1 JSON"
	(:a :href (format nil "vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) :onclick (format nil "window.open(this.href).print(); return false;") (:img :src  "/img/json-file-icon.png"  :height "22" :width "22" :alt "checkout")))
      
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-1 "&nbsp;")
      (with-html-div-col-2 :align "right" :data-bs-toggle "popover" :title "Settings"
	(:a :href (format nil "vinvoicesettingspage?sessioninvkey=~A" sessioninvkey) (:i :class "fa-solid fa-gear"))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;; INVOICE PAID ACTION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun com-hhub-transaction-invoice-paid-action ()
  (with-vend-session-check ;; delete if not needed. 
    (let ((uri (with-mvc-redirect-ui createmodelforinvoicepaidaction createwidgetsforgenericredirect)))
      (format nil "~A" uri))))

(defun createmodelforinvoicepaidaction ()
  (let* ((company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (status (hunchentoot:parameter "status"))
	 (productlist (hhub-get-cached-vendor-products))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (invoiceitems (slot-value sessioninvoice 'InvoiceItems))
	 (totalvalue (calculate-invoice-totalaftertax invoiceitems))
	 (invnum (slot-value sessioninvheader 'invnum))
	 (requestmodel (make-instance 'InvoiceHeaderStatusRequestModel
					 :invnum invnum
					 :status status
					 :totalvalue totalvalue
					 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (redirectlocation  (format nil "/hhub/displayinvoices"))
	 (params nil))
    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-invoice-paid-action" params
      (handler-case 
	  (let ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
	    (when sessioninvoice
	      (setf (slot-value sessioninvoice 'invoiceheader) domainobj)
	      (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
	      (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)
	      (updateinvoiceitemsstockinventory productlist invoiceitems vendor company))
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

(defun updateinvoiceitemsstockinventory (products invoiceitems vendor company)
  (mapcar (lambda (item)
	    (let* ((prd-id (slot-value item 'prd-id))
		   (qty (slot-value item 'qty))
		   (prd (search-item-in-list 'row-id prd-id products)))
	      (if prd (update-stock-inventory prd qty)))) invoiceitems)
  ;; reset the vendor order functions
  (dod-reset-vendor-products-functions vendor company))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;; SHOW THE INVOICE PAYMENT PAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun com-hhub-transaction-show-invoice-payment-page ()
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Invoice Payment Page" createmodelforshowinvoicepaymentpage createwidgetsforshowinvoicepaymentpage :role :vendor )))

(defun createmodelforshowinvoicepaymentpage ()
  (let* ((company (get-login-vendor-company))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (status (hunchentoot:parameter "status"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (invoiceheader (slot-value sessioninvoice 'invoiceheader))
	 (invnum (slot-value invoiceheader 'invnum))
	 (invoiceitems (slot-value sessioninvoice 'InvoiceItems))
	 (totalvalue (calculate-invoice-totalaftertax invoiceitems))
	 (requestmodel (make-instance 'InvoiceHeaderStatusRequestModel
					 :invnum invnum
					 :status status
					 :totalvalue totalvalue
					 :company company))
	 (headeradapter (make-instance 'InvoiceHeaderAdapter))
	 (params nil))
    
    (setf params (acons "company" company params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-show-invoice-payment-page" params
      (handler-case 
      (let ((domainobj (ProcessUpdateRequest headeradapter requestmodel)))
	(when sessioninvoice
	  (setf (slot-value sessioninvoice 'invoiceheader) domainobj)
	  (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
	  (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht))	   
	(function (lambda ()
	  (values sessioninvkey totalvalue invnum))))
	(error (c)
	  (let ((exceptionstr (format nil  "Business Error:~A: ~a~%" (mysql-now) (getexceptionstr c))))
	    (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				    :direction :output
				    :if-exists :append
				    :if-does-not-exist :create)
	      (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
	    ;; return the exception.
	    (error 'hhub-business-function-error :errstring exceptionstr)))))))

(defun createwidgetsforshowinvoicepaymentpage (modelfunc)
  (multiple-value-bind (sessioninvkey totalvalue invnum) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (with-vendor-breadcrumb
			(:li :class "breadcrumb-item no-print" (:a :href "displayinvoices" "Invoices"))
			(:li :class "breadcrumb-item no-print" (:a :href (format nil "editinvoicepage?invnum=~A" invnum) "Edit Invoice"))
			(:li :class "breadcrumb-item no-print" (:a :href (format nil "vproductsforinvoicepage?sessioninvkey=~A" sessioninvkey) "Select Products"))
			(:li :class "breadcrumb-item no-print" (:a :href (format nil "vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) "Confirm Invoice"))))))
	   (widget2 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-div-row
			  (with-html-div-col-4
			    (:h5 :class "no-print" "Invoice Payment - Step 5:")
			    (:a :class "btn btn-primary btn-lg" :role "button" :href (format nil "vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) :onclick (format nil "window.open(this.href).print(); return false;")   "Print&nbsp;&nbsp;"(:i :class "fa-solid fa-print")))
			  (with-html-div-col-4
			    (:a :role "button" :class "btn btn-lg btn-primary btn-block no-print" :href (format nil "vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) "Previous"))
			  (with-html-div-col-4
			    (with-html-form-having-submit-event "form-invoicepaidaction"  "vinvoicepaidaction" 
			      (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
			      (with-html-input-text-hidden "status" "PAID")
			      (:button :class "btn btn-lg btn-primary btn-block no-print" :type "submit" "FINISH"))))))))
      (widget3 (function (lambda ()
		 (cl-who:with-html-output (*standard-output* nil)
		   (display-invoice-payment-widget totalvalue))))))
      (list widget1 widget2 widget3))))

(defun display-invoice-payment-widget ( amountdue)
  (let ((filecontent (funcall (nst-get-cached-invoice-template-func :templatenum 8))))
    (setf filecontent (format nil filecontent amountdue amountdue))
    (cl-who:with-html-output (*standard-output* nil)
      (cl-who:str filecontent))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;; SHOW THE INVOICE FINAL PAGE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun com-hhub-transaction-show-invoice-confirm-page ()
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Invoice Confirm Page" createmodelforshowinvoiceconfirmpage createwidgetsforshowinvoiceconfirmpage :role :vendor )))

(defun createmodelforshowinvoiceconfirmpage ()
  (let* ((company (get-login-vendor-company))
	 (vendor (get-login-vendor))
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
         (invnum (slot-value invheader 'invnum))
	 (status (slot-value invheader 'status))
	 (irequestmodel (make-instance 'InvoiceItemRequestModel
				       :company company
				       :invoiceheader invheader))
	 (itemsadapter (make-instance 'InvoiceItemAdapter))
	 (sessioninvitems (processreadallrequest itemsadapter irequestmodel))
	 (totalvalue (calculate-invoice-totalaftertax sessioninvitems))
	 (qrcodepath (format nil "~A/img~A" *siteurl* (generateqrcodeforvendor vendor "ABC" invnum totalvalue)))
	 (invoicetemplate (funcall (nst-get-cached-invoice-template-func :templatenum 10)))  
	 (invoiceitemshtmlfunc (invoicetemplatefillitemrows sessioninvitems (if (equal status "PAID") T NIL) sessioninvkey))
	 (currency (get-account-currency company))
	 (params nil))

    (setf invoicetemplate (funcall (invoicetemplatefill invoicetemplate invheader sessioninvitems invoiceitemshtmlfunc qrcodepath currency vendor)))
    (setf (slot-value sessioninvoice 'InvoiceItems) sessioninvitems)
    (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
    (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)	   
    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    
    (with-hhub-transaction "com-hhub-transaction-show-invoice-confirm-page" params 
      (function (lambda ()
	(values sessioninvkey invnum  invoicetemplate))))))


(defun createwidgetsforshowinvoiceconfirmpage (modelfunc)
  (multiple-value-bind (sessioninvkey  invnum  invoicetemplate) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (with-vendor-breadcrumb
			(:li :class "breadcrumb-item no-print" (:a :href "displayinvoices" "Invoices"))
			(:li :class "breadcrumb-item no-print" (:a :href (format nil "editinvoicepage?invnum=~A" sessioninvkey) "Edit Invoice"))
			(:li :class "breadcrumb-item no-print" (:a :href (format nil "vproductsforinvoicepage?sessioninvkey=~A" sessioninvkey) "Select Products"))))))
	   (widget2 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-div-row
			  (with-html-div-col-4 "")
			  (with-html-div-col-4
			    (:a :role "button" :class "btn btn-lg btn-primary btn-block no-print" :href (format nil "vproductsforinvoicepage?sessioninvkey=~A" sessioninvkey) "Previous"))
			  (with-html-div-col-4
			    (with-html-form  (format nil "form-invoicepaymentpage")  "vinvoicepaymentpage" 
			      (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
			      (with-html-input-text-hidden "invnum" invnum)
			      (with-html-input-text-hidden "status" "PENDINGPAYMENT")
			      (:button :class "btn btn-lg btn-primary btn-block no-print" :type "submit" "NEXT"))))
			(:br)))))
	   (widget3 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-catch-submit-event "idinvoiceconfirmpage2"
			  (cl-who:str invoicetemplate)))))))
	   (list widget1 widget2 widget3))))
	

(defun calculate-invoice-totalbeforetax (invoiceitems)
  (fround (reduce #'+ (mapcar (lambda (item) (slot-value item 'taxablevalue)) invoiceitems))))

(defun calculate-invoice-totalaftertax (invoiceitems)
  (fround (reduce #'+ (mapcar (lambda (item)
				(let* ((cgstamt (slot-value item 'cgstamt))
				       (sgstamt (slot-value item 'sgstamt))
				       (igstamt (slot-value item 'igstamt))
				       (taxablevalue (slot-value item 'taxablevalue)))
				  (+ taxablevalue sgstamt cgstamt igstamt))) invoiceitems))))


(defun calculate-invoice-totalcgst (invoiceitems)
  (reduce #'+ (mapcar (lambda (item) (slot-value item 'cgstamt)) invoiceitems)))

(defun calculate-invoice-totalsgst (invoiceitems)
  (reduce #'+ (mapcar (lambda (item) (slot-value item 'sgstamt)) invoiceitems)))

(defun calculate-invoice-totaligst (invoiceitems)
  (reduce #'+ (mapcar (lambda (item) (slot-value item 'igstamt)) invoiceitems)))

(defun calculate-invoice-totalgst (invoiceheader invoiceitems)
  (let ((placeofsupply (slot-value invoiceheader 'placeofsupply))
	(statecode (slot-value invoiceheader 'statecode)))
    (if (equal placeofsupply statecode)
	(+ (calculate-invoice-totalcgst invoiceitems) (calculate-invoice-totalsgst invoiceitems))
	;;else
	(calculate-invoice-totaligst invoiceitems))))

(defun display-invoice-confirm-page-widget (invoiceheader invoiceitems qrcodepath sessioninvkey)
  (with-slots (row-id invnum invdate customer  custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear status vendor company) invoiceheader
    (cl-who:with-html-output (*standard-output* nil)
      (:style "table {width: 100%; border-collapse: collapse;} table.center {margin-left: auto; margin-right: auto;} table, th, td {border: 0.5px dashed grey;} th, td { padding: 1px; text-align: left;} td img{ display: block; margin-left: auto; margin-right: auto; } ")
      (:table 
       (:thead
	(:tr 
	 (:th :colspan "2" "TAX INVOICE")
	 (:th :colspan "3" "Original For Recipient")
	 (:th :colspan "3" "Duplicate for Supplier")
	 (:th :colspan "3" "Triplicate for Supplier")))
	   (:tbody
	    (:tr
	     (:td :colspan "2" "Invoice No. :")
	     (:td :colspan "2" (cl-who:str invnum))
	     (:td :colspan "2" "Status: ")
	     (:td :colspan "2" (cl-who:str status))
	     (if (not (equal transmode "NA"))
		 (cl-who:htm 
		  (:td :colspan "2" "Transportation Mode:")
		  (:td :colspan "1" (cl-who:str transmode))
		  (:td :colspan "2" "Vehicle Number :")
		  (:td :colspan "1" (cl-who:str vnum)))))
	    (:tr
	     (:td :colspan "2" "Invoice Date:")
	     (:td :colspan "2" (cl-who:str (get-date-string invdate)))
	     (:td :colspan "2" "Date of Supply :")
	     (:td :colspan "2" "Place of Supply :")
	     (:td :colspan "2" (cl-who:str (gethash placeofsupply *NSTGSTSTATECODES-HT*)))
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
	     (:td :colspan "3" (cl-who:str billaddr))
	     (:td :colspan "2" "Address :")
	     (:td :colspan "3" (cl-who:str shipaddr)))
	    (:tr
	     (:td :colspan "2" "GSTIN :")
	     (:td :colspan "3" (cl-who:str custgstin))
	     (:td :colspan "2" "GSTIN :")
	     (:td :colspan "3" (cl-who:str custgstin)))
	    (:tr
	     (:td :colspan "2" "State :")
	     (:td :colspan "3" (cl-who:str (gethash statecode *NSTGSTSTATECODES-HT*)))
	     (:td :colspan "2" "State :")
	     (:td :colspan "3" (cl-who:str (gethash statecode *NSTGSTSTATECODES-HT*))))
	    (:tr
	     (:th "Sr. No")
	     (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) (list "Name of Product/Service" "HSN/SAC" "Qty Per Unit" "Qty" "Rate"  "Less: Discount%" "Taxable Value" "CGST" "SGST" "IGST" "Total" "Action")))
	    (let ((incr (let ((count 0)) (lambda () (incf count)))))
	      (mapcar (lambda (item)
			(cl-who:htm (:tr (:td (cl-who:str (funcall incr))) (display-invoice-item-row item (if (equal status "PAID") T NIL) sessioninvkey))))  invoiceitems))
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
	     (:td :colspan "3" "Bank Account Number:")
	     (:td :colspan "4" (cl-who:str bankaccnum))
	     (:td :colspan "3" "Add : CGST :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totalcgst invoiceitems))))
	    (:tr
	     (:td :colspan "2" "Bank Branch IFSC :")
	     (:td :colspan "5" (cl-who:str bankifsccode))
	     (:td :colspan "3" "Add : SGST :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totalsgst invoiceitems))))
	    (:tr
	     (:td :rowspan "6" :colspan "7" (:img :style "width: 150px; height: 150px;" :src qrcodepath (:span "Pay By UPI")))
	     (:td :colspan "3" "Add : IGST :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totaligst invoiceitems))))
	    (:tr
	     (:td :colspan "3" "Tax Amount : GST :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totalgst invoiceheader invoiceitems))))
	    (:tr
	     (:td :colspan "3" "Total Amount After Tax :")
	     (:td :colspan "3" (cl-who:str (calculate-invoice-totalaftertax invoiceitems))))
	    (:tr
	     (:td :colspan "3" "GST Payable on Reverse Charge :")
	     (:td :colspan "3" (cl-who:str revcharge)))
	    (:tr
	     (:td :colspan "4" "Certified that the particulars given above are true and correct.")
	     (:td :colspan "2" "(Authorized Signatory)"))
	    (:tr
	     (:td :colspan "6" "For, [Company Name]"))
	    (:tr
	     (:td :colspan "13" "Terms and Conditions :"))
	    (:tr
	     (:td :colspan "13" (cl-who:str tnc))))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;; ADD PRODUCT TO CART TO CREATE AN INVOICE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun com-hhub-transaction-add-product-to-invoice-page ()
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "Add Product To Invoice" createmodelforaddprdtoinvoice createwidgetsforaddprdtoinvoice :role :vendor )))

(defun createmodelforaddprdtoinvoice ()
  (let* ((sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (invnum (slot-value sessioninvheader 'invnum))
	 (headerstatus (slot-value sessioninvheader 'status))
	 (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))
	 (sessioninvproducts (slot-value sessioninvoice 'invoiceproducts))
	 (products (hhub-get-cached-active-vendor-products)))
    (function (lambda ()
      (values products sessioninvitems sessioninvproducts  headerstatus sessioninvkey invnum)))))

(defun createwidgetsforaddprdtoinvoice (modelfunc)
  (multiple-value-bind (products sessioninvitems sessioninvproducts headerstatus sessioninvkey invnum) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-vendor-breadcrumb
			  (:li :class "breadcrumb-item" (:a :href "displayinvoices" "Invoices"))
			  (:li :class "breadcrumb-item" (:a :href (format nil "editinvoicepage?invnum=~A" invnum) "Edit Invoice")))
			(with-html-div-row
			  (:div :class "col-xs-6 col-sm-6 col-md-6 col-lg-6"
				(:span "Create Invoice - Step 3:")))))))
	   (widget2 (function (lambda ()
		      (if (or (equal headerstatus "PAID")
			      (equal headerstatus "SHIPPED")
			      (equal headerstatus "CANCELLED")
			      (equal headerstatus "REFUNDED"))
			  (cl-who:with-html-output (*standard-output* nil)
			    (:h2 (cl-who:str (format nil "INVOICE IS ~A" headerstatus))))
			    ;;else
			  (cl-who:with-html-output (*standard-output* nil)
			    (with-html-div-row
			      (with-html-div-col-4 
				(with-html-search-form "idsearchproduct" "searchproduct" "idtxtsearchproduct" "txtsearchproduct" "vsearchproductforinvoice" "onkeyupsearchform1event();" "Product Name"
				  (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
				  (submitsearchform1event-js "#idtxtsearchproduct" "#vendorproductsearchforinvoiceresult" )))
			      (with-html-div-col-4
				(with-html-form-having-submit-event  "barcodescanform" "vaddtocartusingbarcode"
				  ;; here we would like to auto focus on the barcode textbox to input the next barcode upon page reload.
				  (with-html-input-text "barcodeinput" "Product Barcode/UPC/EAN" "Enter Barcode/UPC/EAN" "" NIL "" 1 :autofocus "autofocus")
				  (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
				  (:input :type "submit" :style "display: none;")))
			      (with-html-div-col-4
				    (:a :href (format nil "/hhub/vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey) 
					(:img :src  "/img/checkoutimage.png"  :height "100" :width "350" :alt "checkout"))))
			    (:h2 "Cart Items")
			    (cl-who:str (display-as-table (list "" "Name" "Qty Per Unit" "Price" "" "Discount" "In Cart") sessioninvproducts  'display-product-in-invoice-row sessioninvkey sessioninvitems))
			    (:h2 "Products")
			    (:div :id "vendorproductsearchforinvoiceresult"  :class "container-fluid"
				  (cl-who:str (display-as-table (list "" "Name" "Qty Per Unit" "Price" "" "Discount" "Action") products  'display-add-product-to-invoice-row sessioninvkey sessioninvitems))))))))
	   (widget3 (function (lambda ()
		      (submitformevent-js "#vendorproductsearchforinvoiceresult")))))
      (list widget1 widget2 widget3))))
	   
(defun display-add-product-to-invoice-row (product &rest arguments)
  (let* ((sessioninvkey (first (first arguments)))
	 (sessioninvitems (second (first arguments)))
	 (prd-id (slot-value product 'row-id))
	 ;;(qtyincart 0)
	 (prdincart-p (prdinlist-p prd-id sessioninvitems))
	 (prdname (slot-value product 'prd-name))
	 (prd-name (subseq prdname 0 (min 20 (length prdname))))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (company (get-login-vendor-company))
	 (current-price (slot-value product 'current-price))
	 (current-discount (slot-value product 'current-discount))
	 (ppricing (select-product-pricing-by-product-id prd-id company))
	 (pcurr (if ppricing (slot-value ppricing 'currency))))
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" (render-single-product-image prd-name imageslst images-str "50" "50"))
      (:td  :height "10px" (cl-who:str prd-name))
      (:td  :height "10px" (cl-who:str qty-per-unit))
      (:td  :height "10px" (cl-who:str current-price))
      (:td  :height "10px" (cl-who:str pcurr))
      (:td  :height "10px" (cl-who:str (if current-discount current-discount "NIL")))
      (:td  :height "10px"
	    (if  prdincart-p
		 (cl-who:htm (:a :class "btn btn-sm btn-success" :role "button"  :onclick "return false;" :href (format nil "javascript:void(0);")(:i :class "fa-solid fa-check")))
		 ;; else 
		 (if (and units-in-stock (> units-in-stock 0))
		     (cl-who:htm
		      (:div :class "form-group"
			    (:button :onclick "addtocartclick(this.id);" :id (format nil "btnaddproduct_~A" prd-id) :name (format nil "btnaddproduct~A" prd-id) :type "button" :class "add-to-cart-btn" :data-bs-toggle "modal" :data-bs-target (format nil "#producteditqty-modal~A" prd-id) (:i :class "fa-solid fa-cart-shopping") "&nbsp;Add To Cart")
			    (modal-dialog-v2 (format nil "producteditqty-modal~A" prd-id) (cl-who:str (format nil "Edit Product Quantity - Available: ~A" units-in-stock)) (vproduct-qty-add-for-invoice-html product ppricing sessioninvkey))))			
		     ;; else
		     (cl-who:htm
		      (:div :class "col-6" 
			    (:h5 (:span :class "label label-danger" "Out Of Stock"))))))))))

(defun display-product-in-invoice-row (product &rest arguments)
  (let* ((sessioninvkey (first (first arguments)))
	 (sessioninvitems (second (first arguments)))
	 (prd-id (slot-value product 'row-id))
	 ;;(qtyincart 0)
	 (prdincart-p (prdinlist-p prd-id sessioninvitems))
	 (itemincart (if prdincart-p (search-item-in-list 'prd-id prd-id sessioninvitems) nil))
	 (qtyincart (if itemincart (slot-value itemincart 'qty)))
	 (prdname (slot-value product 'prd-name))
	 (prd-name (subseq prdname 0 (min 20 (length prdname))))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (company (get-login-vendor-company))
	 (price (slot-value product 'current-price))
	 (ppricing (select-product-pricing-by-product-id prd-id company))
	 (pprice (if ppricing (slot-value ppricing 'price)))
	 (pdiscount (if ppricing (slot-value ppricing 'discount)))
	 (pcurr (if ppricing (slot-value ppricing 'currency))))
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" (render-single-product-image prd-name imageslst images-str "30" "30"))
      (:td  :height "10px" (cl-who:str prd-name))
      (:td  :height "10px" (cl-who:str qty-per-unit))
      (:td  :height "10px" (cl-who:str (if ppricing pprice price)))
      (:td  :height "10px" (cl-who:str pcurr))
      (:td  :height "10px" (cl-who:str (if pdiscount pdiscount "NIL")))
      (:td  :height "10px"
	    (if  prdincart-p
		 (cl-who:htm  (:h4 (:span :class "badge rounded-pill bg-info" (cl-who:str (format nil "~A" qtyincart)))))
		 ;; else 
		 (if (and units-in-stock (> units-in-stock 0))
		     (cl-who:htm
		      (:div :class "form-group"
			    (:button :onclick "addtocartclick(this.id);" :id (format nil "btnaddproduct_~A" prd-id) :name (format nil "btnaddproduct~A" prd-id) :type "button" :class "add-to-cart-btn" :data-bs-toggle "modal" :data-bs-target (format nil "#producteditqty-modal~A" prd-id) (:i :class "fa-solid fa-cart-shopping") "&nbsp;Add To Cart")
			    (modal-dialog-v2 (format nil "producteditqty-modal~A" prd-id) (cl-who:str (format nil "Edit Product Quantity - Available: ~A" units-in-stock)) (vproduct-qty-add-for-invoice-html product ppricing sessioninvkey))))			
		     ;; else
		     (cl-who:htm
		      (:div :class "col-6" 
			    (:h5 (:span :class "label label-danger" "Out Of Stock"))))))))))


(defun vproduct-qty-add-for-invoice-html (product product-pricing sessioninvkey)
  (let* ((prd-id (slot-value product 'row-id))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (prd-name (slot-value product 'prd-name))
	 (hsn-code (slot-value product 'hsn-code)))
	
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-form  (format nil "form-addproduct~A" prd-id)  "vaddtocartforinvoice" 
      (with-html-input-text-hidden "prd-id" prd-id)
      (:p :class "product-name"  (cl-who:str prd-name))
      (:p :class "product-hsn-code" "HSN Code: " (cl-who:str hsn-code))
      (:a :href (format nil "prddetailsforcust?id=~A" prd-id) 
	  (render-single-product-image prd-name imageslst images-str "100" "83"))      
      (product-price-with-discount-widget product product-pricing)
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
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))
	 (sessioninvproducts (slot-value sessioninvoice 'invoiceproducts))
	 (context-id (slot-value sessioninvheader 'context-id))
	 (customer (slot-value sessioninvoice 'customer))
	 (productlist (hhub-get-cached-vendor-products))
	 (product (search-item-in-list 'row-id prd-id productlist))
	 (gstvalues (get-gstvalues-for-product product))
	 (current-price (slot-value product 'current-price))
	 (current-discount (slot-value product 'current-discount))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (unit-of-measure (slot-value product 'unit-of-measure))
	 (pname (slot-value product 'prd-name))
	 (prd-name (subseq pname 0 (min 30 (length pname))))
	 (hsncode (slot-value product 'hsn-code))
	 (taxablevalue (- (* prdqty current-price) (if current-discount (/ (* prdqty  current-price current-discount) 100) 0.00)))
	 (placeofsupply (slot-value sessioninvheader 'placeofsupply))
	 (statecode (slot-value sessioninvheader 'statecode))
	 (intrastate (if (equal statecode placeofsupply) T NIL))
	 (interstate (if (equal statecode placeofsupply) NIL T)) 
	 (cgstrate (if gstvalues (first gstvalues) 0.00)) 
	 (cgstamt (if intrastate (/ ( * taxablevalue cgstrate) 100) 0.00))
	 (sgstrate (if gstvalues (second gstvalues) 0.00))
	 (sgstamt (if intrastate (/ (* sgstrate taxablevalue) 100) 0.00))
	 (igstrate (if gstvalues (third gstvalues) 0.00)) 
	 (igstamt (if interstate (/ (* igstrate taxablevalue) 100) 0.00))
	 (totalitemval (+ taxablevalue (if intrastate (+ cgstamt sgstamt) igstamt)))
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
					 :uom (format nil "~A ~A" qty-per-unit unit-of-measure)
					 :price current-price
					 :discount current-discount
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
      (setf (slot-value sessioninvoice 'invoiceproducts) (append sessioninvproducts (list product)))
      ;;(setf (hhub-get-cached-vendor-products) (remove product productlist))
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
  (with-vend-session-check
    (let ((uri (with-mvc-redirect-ui createmodelforvendaddtocartforinvoice createwidgetsforvendaddtocartforinvoice)))
      (format nil "~A" uri))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ADD TO CART USING BARCODE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun createmodelforvendaddtocartusingbarcode ()
  (let* ((company (get-login-vendor-company))
	 (barcode (hunchentoot:parameter "barcodeinput"))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))
	 (sessioninvproducts (slot-value sessioninvoice 'invoiceproducts))
	 (context-id (slot-value sessioninvheader 'context-id))
	 (customer (slot-value sessioninvoice 'customer))
	 (productlist (hhub-get-cached-vendor-products))
	 (product (search-item-in-list 'upc barcode productlist))
	 (prd-id (slot-value product 'row-id))
	 (itemincart (if (iteminlist-p 'prd-id prd-id sessioninvitems) (search-item-in-list 'prd-id prd-id sessioninvitems)))
	 (newqty (if itemincart (+ (slot-value itemincart 'qty) 1) 1))
	 (gstvalues (get-gstvalues-for-product product))
	 (current-price (slot-value product 'current-price))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (pname (slot-value product 'prd-name))
	 (prd-name (subseq pname 0 (min 30 (length pname))))
	 (hsncode (slot-value product 'hsn-code))
	 (product-pricing (select-product-pricing-by-product-id prd-id company))
	 (prd-discount (if product-pricing (slot-value product-pricing 'discount) nil))
	 (taxablevalue (- (* newqty current-price) (if prd-discount (/ (* newqty current-price prd-discount) 100) 0.00)))
	 (placeofsupply (slot-value sessioninvheader 'placeofsupply))
	 (statecode (slot-value sessioninvheader 'statecode))
	 (intrastate (if (equal statecode placeofsupply) T NIL))
	 (interstate (if (equal statecode placeofsupply) NIL T)) 
	 (cgstrate (if gstvalues (first gstvalues) 0.00)) 
	 (cgstamt (if intrastate (/ ( * taxablevalue cgstrate) 100) 0.00))
	 (sgstrate (if gstvalues (second gstvalues) 0.00))
	 (sgstamt (if intrastate (/ (* sgstrate taxablevalue) 100) 0.00))
	 (igstrate (if gstvalues (third gstvalues) 0.00)) 
	 (igstamt (if interstate (/ (* igstrate taxablevalue) 100) 0.00))
	 (totalitemval (+ taxablevalue (if intrastate (+ cgstamt sgstamt) igstamt)))
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
					 :qty newqty
					 :uom qty-per-unit
					 :price current-price
					 :discount prd-discount
					 :taxablevalue taxablevalue
					 :cgstrate cgstrate
					 :cgstamt cgstamt
					 :sgstrate sgstrate
					 :sgstamt sgstamt
					 :igstrate igstrate
					 :igstamt igstamt
					 :company company
					 :totalitemval totalitemval
					 :status "PENDING"))
	 (invitmadapter (make-instance 'InvoiceItemAdapter))
	 (InvoiceItem (if itemincart (ProcessUpdateRequest invitmadapter invitmrequestmodel) (ProcessCreateRequest invitmadapter invitmrequestmodel))))
		    
    (unless wallet (create-wallet customer vendor company))
    (when (and wallet sessioninvoice)
      (when  itemincart
	;; if updated an item using barcode then, we need to replace the current item
	(setf sessioninvitems (remove itemincart sessioninvitems))
	(setf sessioninvproducts (remove product sessioninvproducts)))
	;;(setf (hunchentoot:session-value :login-prd-cache) (remove product productlist)))
      ;; if created an item using barcode use this 
      (setf (slot-value sessioninvoice 'InvoiceItems) (append sessioninvitems (list invoiceitem)))
      (setf (slot-value sessioninvoice 'invoiceproducts) (append sessioninvproducts (list product)))
      (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
      (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)
      (function (lambda ()
	(values redirectlocation))))))

(defun createwidgetsforvendaddtocartusingbarcode (modelfunc)
 (createwidgetsforgenericredirect modelfunc))


(defun com-hhub-transaction-vendor-addtocart-using-barcode-action ()
  :documentation "This function is responsible for adding the product and product quantity to the shopping cart."
  (with-cust-session-check
    (let ((uri (with-mvc-redirect-ui createmodelforvendaddtocartusingbarcode createwidgetsforvendaddtocartusingbarcode)))
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
				(:button :type "button" :class "btn btn-lg btn-primary btn-block" :data-bs-toggle "modal" :data-bs-target (format nil "#vendorcreatecustomer-modal") (:i :class "fa-solid fa-user") "&nbsp;Add Customer")
				(modal-dialog-v2 (format nil "vendorcreatecustomer-modal")  "Create Customer" (vendor-create-update-customer-dialog nil)))
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
			(:div :id "vendormycustomerssearchresult"  :class "container-fluid"
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
	  (:div :id "custom-search-input" :class "col-3"
		(with-html-search-form "idsyssearchInvoiceHeader" "syssearchInvoiceHeader" "idInvoiceHeaderlivesearch" "InvoiceHeaderlivesearch" "searchinvoicesaction" "onkeyupsearchform1event();" "Search By Invoice Number. Type 3 letters..."
		  (submitsearchform1event-js "#idInvoiceHeaderlivesearch" "#InvoiceHeaderlivesearchresult"))))))

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
		     (invoices-actions-menu  nil))))
	  (widget3 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :id "InvoiceHeaderlivesearchresult" 
			     (with-html-div-row
			       (with-html-div-col-3
				 (:a :href "/hhub/addcusttoinvoice" :role "button" :class "btn btn-lg btn-primary btn-block" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create Invoice"))
			       (with-html-div-col-6 "")
			       (with-html-div-col-3 :align "right"
				 (:span :class "badge bg-info" (:h5 (cl-who:str (format nil "~A" (length viewallmodel)))))))
			     (:hr)
			     (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
	  (widget4 (function (lambda ()
		     (render-invoice-settings-menu)))))
      (list widget1 widget2 widget3 widget4))))

(defun createwidgetsforupdateInvoiceHeader (modelfunc)
:description "This is a widgets function for update InvoiceHeader entity"      
  (createwidgetsforgenericredirect modelfunc))


(defmethod RenderListViewHTML ((htmlview InvoiceHeaderHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for InvoiceHeader entities, which will display each InvoiceHeader entity in a row"
  (when viewmodellist
    (display-as-table (list "Invoice Number" "Date" "Customer Name" "Status" "Total Value" "Action") viewmodellist 'display-InvoiceHeader-row)))

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
		       (with-html-div-row
			 (with-html-div-col-3
			   (:a :href "/hhub/addcusttoinvoice" :role "button" :class "btn btn-lg btn-primary btn-block" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create Invoice"))
			 (with-html-div-col-6 "")
			 (with-html-div-col-3 :align "right"
			   (:span :class "badge bg-info" (:h5 (cl-who:str (format nil "~A" (length viewallmodel)))))))
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
	 (status (hunchentoot:parameter "status"))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (company (get-login-vendor-company)) ;; or get ABAC subject specific login company function. 
	 (customer (select-customer-by-id custid company))
	 (vendor (get-login-vendor))
	 (external-url (generate-invoice-ext-url invnum vendor company)) 
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
					 :external-url external-url
					 :status status
					 :vendor vendor
					 :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (redirectlocation  (format nil "/hhub/vproductsforinvoicepage?sessioninvkey=~A" invnum))
	 (params nil))
    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-invoice-action" params 
      (handler-case 
	  (let* ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
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
				      :external-url ""
				      :company company))
	 (adapterobj (make-instance 'InvoiceHeaderAdapter))
	 (hrequestmodel (make-instance 'InvoiceHeaderContextIDRequestModel
				      :context-id context-id
				      :company company))
	 (redirectlocation  (format nil "/hhub/vproductsforinvoicepage?sessioninvkey=~A"  sessioninvkey))
	 (params nil))
    (setf params (acons "company" company params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-create-invoice-action" params 
      (handler-case 
	  (let* ((createdobj (ProcessCreateRequest adapterobj requestmodel))
		 ;; as soon as we create a invoice header object, we would like to read it as well
		 ;; this will pull in the row-id from database and also the invoice number. 
		 (domainobj (ProcessReadRequest adapterobj hrequestmodel))
		 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
		 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht)))
	    ;;  (logiamhere (format nil "~A" sessioninvoices-ht))
	    ;; (logiamhere (format nil "~A" sessioninvoice))
	    ;;  (logiamhere (format nil "session invoice customer is ~A" (slot-value (slot-value sessioninvoice 'customer) 'name)))
	    ;; set the InvoiceHeader context for the invoice being created and add to the session invoice. 
	    (when (and createdobj sessioninvoice)
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
      (with-html-form-having-submit-event "form-vendorcreatecustomer"  "vendorcreatecustomer"
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
  (with-slots (invnum invdate customer status totalvalue) viewmodel
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "10px" (cl-who:str  invnum))
      (:td  :height "10px" (cl-who:str (get-date-string invdate)))
      (:td  :height "10px" (cl-who:str (slot-value customer 'name)))
      (:td  :height "10px" (cl-who:str status))
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
	 (itmadapter (make-instance 'InvoiceItemAdapter))
	 (customer (if custid (select-customer-by-id custid company)))
	 (custaddress (if customer (slot-value customer 'address)))
	 (busobj (make-instance 'InvoiceHeader
				:context-id (format nil "~A" (uuid:make-v1-uuid))
				:company company
				:vendor vendor
				:customer customer
				:custaddr custaddress 
				:finyear finyear
				:external-url ""
				:status "DRAFT"
				:placeofsupply *NSTGSTBUSINESSSTATE*
				:statecode *NSTGSTBUSINESSSTATE*
				:tnc *NSTGSTINVOICETERMS*
				:authsign (get-login-vendor-name)
				:revcharge "No"))
	 (requestmodel (make-instance 'InvoiceHeaderRequestModel
				      :invnum inum
				      :company company))
	 (invoiceobj (if inum (ProcessReadRequest adapter requestmodel) busobj))
	 (invitemreqmodel (make-instance 'InvoiceItemRequestModel
					 :invoiceheader invoiceobj
					 :company company))
	 (invitems (if inum (ProcessReadAllRequest itmadapter invitemreqmodel) '()))  
	 
	 ;; When we are creating a new invoice, we would like to save it in the session with context of
	 ;; customer, invoice header and invoice items. Here we start with adding the customer context. 
	 (sessioninvkey (if inum inum (format nil "NST000~A" (hhub-random-password 10))))
	 (newsessioninvoice (make-instance 'SessionInvoice))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht)))

    ;;(logiamhere (format nil "status of invoice header is ~A" (slot-value invoiceobj 'status)))
	   ;; set the customer context for the invoice being created and add to the session invoice. 
    (setf (slot-value newsessioninvoice 'customer) (customer invoiceobj))
    (setf (slot-value newsessioninvoice 'InvoiceItems) invitems)
    (setf (slot-value newsessioninvoice 'invoiceproducts) '())
    (setf (slot-value newsessioninvoice 'InvoiceHeader) invoiceobj)
    (setf (gethash sessioninvkey sessioninvoices-ht) newsessioninvoice)
    (setf (hunchentoot:session-value :session-invoices-ht) sessioninvoices-ht)
  (with-slots (context-id invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear external-url status customer ) invoiceobj
    (function (lambda()
      (values context-id invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear external-url status customer  mode sessioninvkey))))))


(defun createwidgetsforeditinvoiceheaderpage (modelfunc)
  (multiple-value-bind (context-id invnum invdate custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear external-url status customer  mode sessioninvkey) (funcall modelfunc)
    (let* ((widget1 (editinvoicewidget-section1 sessioninvkey context-id invnum invdate  custgstin finyear status customer))
	   (widget2 (editinvoicewidget-section2 custaddr billaddr shipaddr))
	   (widget3 (editinvoicewidget-section3 statecode placeofsupply revcharge transmode vnum totalvalue totalinwords))
	   (widget4 (editinvoicewidget-section4 bankaccnum bankifsccode tnc authsign))
	   (widget5 (function (lambda ()
		      (invoice-header-actions-menu external-url status sessioninvkey customer))))  
	   (widget5 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-vendor-breadcrumb
			  (:li :class "breadcrumb-item" (:a :href "displayinvoices" "Invoices"))
			  (:li :class "breadcrumb-item" (:a :href "addcusttoinvoice" "Select Customer")))
			(funcall widget5)
			(:span "Create Invoice - Step 2: ")
			(:span (cl-who:str sessioninvkey))
			(:h2 "Fill Invoice Details For")
			(with-html-form-having-submit-event "form-updateinvoiceheader"  (if (equal mode "create") "createinvoiceaction" "updateinvoiceaction")
			  (with-html-div-row
			    (with-html-div-col-3
			      (funcall widget1))
			    (with-html-div-col-3
			      (funcall widget2))
			    (with-html-div-col-3
			      (funcall widget3))
			    (with-html-div-col-3
			      (funcall widget4)))))))))
      (list widget5))))


(defun editinvoicewidget-section1 (sessioninvkey context-id invnum invdate  custgstin finyear status customer)
  (function (lambda ()
    (let ((charcountid1 (format nil "idchcount~A" (hhub-random-password 3)))
	  (idinvoicedate (format nil "idinvoicedate~A" (gensym)))
	  (finyear-ht (make-hash-table :test 'equal))
	  (status-ht (make-hash-table :test 'equal)))
      
      (setf (gethash (current-year-string--) finyear-ht) (current-year-string--))
      (setf (gethash (current-year-string) finyear-ht) (current-year-string))
      (setf (gethash (current-year-string++) finyear-ht) (current-year-string++))
      (setf (gethash "DRAFT" status-ht) "DRAFT")
      (setf (gethash "PENDINGPAYMENT" status-ht) "PENDINGPAYMENT")
      (setf (gethash "PAID" status-ht) "PAID")
      (setf (gethash "SHIPPED" status-ht) "SHIPPED")
      (setf (gethash "CANCELLED" status-ht) "CANCELLED")
      (setf (gethash "REFUNDED" status-ht) "REFUNDED")
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
	      (:label :for "status" "Status")
	      (with-html-dropdown "status" status-ht status))
	(:div :class "form-group"
	      (:label :for "invnum" "Invoice Number")
	      (:input :class "form-control" :name "invnum" :maxlength "20"  :value  invnum :placeholder "Invoice Number (max 20 characters) " :type "text" :readonly t))
	(:div :class "form-group"
	      (:label :for idinvoicedate "Invoice Date - Click To Change" )
	      (:input :class "form-control" :name "invdate" :id idinvoicedate :placeholder  "Invoice Date"  :type "text" :value (get-date-string invdate)))
	
	(:div :class "form-group"
	      (:label :for "idcustgstin" "Customer GST Number")
	      (:input :id "idcustgstin" :class "form-control" :type "text" :value custgstin :onkeyup (format nil "countChar(~A.id, this, 15)" charcountid1) :placeholder "Customer GST Number"  :name "custgstin" )
	      (:div :class "form-group" :id charcountid1))
	(:script (cl-who:str (format nil "$(document).ready(
        function() {    
        $('#~A').datepicker({dateFormat: 'dd/mm/yy', minDate: 0} ).attr('readonly', 'true'); 
        }
);" idinvoicedate))))))))

(defun editinvoicewidget-section2 (custaddr billaddr shipaddr)
  (function (lambda ()
    (let ((charcountid1 (format nil "idchcount~A" (hhub-random-password 3)))
	  (charcountid2 (format nil "idchcount~A" (hhub-random-password 3)))
	  (charcountid3 (format nil "idchcount~A" (hhub-random-password 3))))
      (cl-who:with-html-output (*standard-output* nil)
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
  

(defun editinvoicewidget-section3 (statecode placeofsupply revcharge transmode vnum totalvalue totalinwords)
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

      (unless statecode (setf statecode *NSTGSTBUSINESSSTATE*))
      
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "form-group"
	      (:label :for "statecode" "Select State")
	      (with-html-dropdown "statecode" *NSTGSTSTATECODES-HT* statecode))
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
	    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "NEXT"))
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
	    (:input :class "form-control" :type "text" :value authsign :placeholder "authsign"  :name "authsign" )))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
