;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


;; You must set these variables to appropriate values.
(defvar *crm-database-type* :odbc
  "Possible values are :postgresql :postgresql-socket, :mysql,
:oracle, :odbc, :aodbc or :sqlite")
(defvar *crm-database-name* "hhubdb"
  "The name of the database we will work in.")
(defvar *crm-database-user* "hhubuser"
  "The name of the database user we will work as.")
(defvar *crm-database-server* "localhost"
  "The name of the database server if required")
(defvar *crm-database-password* "Welcome$123"
  "The password if required")
(defvar *dod-dbconn-spec* (list *crm-database-server* *crm-database-name* *crm-database-user* *crm-database-password*))


(defvar *HHUB-CUSTOMER-ORDER-CUTOFF-TIME* "23:59:00")
(defvar *HHUB-DEMO-TENANT-ID* 2)

(defvar *HHUB-COMPILE-FILES-LOCATION* "/home/ubuntu/ninestores/bin/hhubcompilelog.txt") 
(defvar *HHUB-EMAIL-CSS-FILE* "/data/www/ninestores.in/public/css")
(defvar *HHUB-EMAIL-CSS-CONTENTS* NIL)
;; Email templates
(defvar *NST-EMAIL-TEMPLATES* NIL)
(defvar *HHUB-EMAIL-TEMPLATES-FOLDER* "/home/ubuntu/ninestores/hhub/email/templates")
(defvar *HHUB-CUST-REG-TEMPLATE-FILE* "cust-reg.html")
(defvar *HHUB-CUST-PASSWORD-RESET-FILE* "cust-pass-reset.html")
(defvar *HHUB-CUST-TEMP-PASSWORD-FILE* "temppass.html")
(defvar *HHUB-NEW-COMPANY-REQUEST* "newcompanyrequest.html")
(defvar *HHUB-CONTACTUS-EMAIL-TEMPLATE* "contactustemplate.html")
(defvar *HHUB-GUEST-CUST-ORDER-TEMPLATE-FILE* "guestcustorder.html")
(defvar *HHUB-TERMSANDCONDITIONS-FILE* "tnc.html")
(defvar *HHUB-PRIVACY-FILE* "privacy.html")
(defvar *HHUB-STATIC-FILES* "/home/ubuntu/ninestores/site/public")

;; This global variable represents the standard output terminal which will be used
;; to display output in multi threaded situations.
(defvar *stdoutstream* *standard-output*)
(defvar *dod-db-instance*)
(defvar *siteurl* "https://www.ninestores.in")
(defvar *sitepass* (encrypt "P@ssword1" "ninestores.in"))
(defvar *current-customer-session* nil) 
(defvar *customer-page-title* nil) 
(defvar *vendor-page-title* nil) 
(defvar *admin-page-title* nil) 
(defvar *ABAC-ATTRIBUTE-NAME-PREFIX* "com.hhub.attribute.")
(defvar *ABAC-POLICY-NAME-PREFIX* "com.hhub.policy.")

(defvar *ABAC-TRANSACTION-NAME-PREFIX* "com.hhub.transaction.")
(defvar *ABAC-ATTRIBUTE-FUNC-PREFIX* "com-hhub-attribute-")
(defvar *ABAC-POLICY-FUNC-PREFIX* "com-hhub-policy-")
(defvar *ABAC-TRANSACTION-FUNC-PREFIX* "com-hhub-transaction-")
(defvar *PAYGATEWAYRETURNURL* "https://www.ninestores.in/hhub/custpaymentsuccess")
(defvar *PAYGATEWAYCANCELURL* "https://www.ninestores.in/hhub/custpaymentcancel")
(defvar *PAYGATEWAYFAILUREURL* "https://www.ninestores.in/hhub/custpaymentfailure")
(defvar *HHUBRESOURCESDIR* "/data/www/public/img")
(defvar *HHUBDEFAULTPRDIMG* "HHubDefaultPrdImg.png")
(defvar *HHUBDEFAULTLOGOIMG* "/img/logo.png")
(defvar *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* NIL)
(defvar *HHUBGLOBALBUSINESSFUNCTIONS-HT* NIL)
(defvar *HHUBBUSINESSFUNCTIONSLOGFILE* "/home/hunchentoot/hhublogs/ninestores-busfunctions.log")

;;; EXPERIMENTING WITH DDD 
(defvar *HHUBENTITYINSTANCES-HT* nil)
(defvar *HHUBENTITY-WEBPUSHNOTIFYVENDOR-HT* NIL)
(defvar *HHUBBUSINESSSESSIONS-HT* NIL) 
(defvar *HHUBBUSINESSLOCATION-VENDOR* NIL)
(defvar *HHUBBUSINESSSERVER* NIL)

(defvar *HHUBGLOBALROLES* NIL) 
(defvar *HHUBFEATURESWISHLISTURL* "https://goo.gl/forms/hI9LIM9ebPSFwOrm1")
(defvar *HHUBBUGSURL* "https://goo.gl/forms/3iWb2BczvODhQiWW2") 
(defvar *HHUBCUSTLOGINPAGEURL* "/hhub/hhubcustloginv2")
(defvar *HHUBVENDLOGINPAGEURL* "/hhub/hhubvendloginv2")
(defvar *HHUBOPRLOGINPAGEURL* "/hhub/opr-login.html")
(defvar *HHUBCADLOGINPAGEURL* "/hhub/cad-login.html")
(defvar *HHUBPASSRESETTIMEWINDOW* 20) ; 20 minutes. Depicts the reset password time window. 
(defvar *HHUBGUESTCUSTOMERPHONE* "9999999999")
(defvar *HHUBSUPERADMINEMAIL* "support@ninestores.in")
(defvar *HHUBSUPPORTEMAIL* "support@ninestores.in")
(defvar *HHUBPENDINGUPIFUNCTIONS-HT* nil)
(defvar *HHUBTRIALCOMPANYEXPIRYDAYS* 90)
(defvar *HHUBOTPTESTING* T)
(defvar *HHUBUSELOCALSTORFORRES* NIL)
(defvar *HHUBWHATAPPLINKURLINDIA* "https://wa.me/91")
(defvar *HHUBWHATSAPPBUTTONIMG* "WhatsAppButtonGreenSmall.png")
(defvar *HTMLRUPEESYMBOL* "&#8377;")
(defvar *HTMLDOLLARSYMBOL* "&#36;")
(defvar *HHUBSHIPPINGZONES* nil)
(defvar *HHUBDEFAULTSHIPRATETABLECSV* "defaultshipratetable.csv")
(defvar *HHUBDEFAULTSHIPZONESCSV*  "defaultshipzonepincodes.csv")
(defvar *HHUBSHIPPINGPARTNERSITE* "https://www.ithinklogistics.com/")
(defvar *HHUBFREESHIPMINORDERAMT* 500.00)
(defvar *HHUBMAXVENDORLOGINS* 2)
(defvar *HHUBMAXUSERLOGINS* 2)
(defvar *HHUBMEMOIZEDFUNCTIONS* nil)
(defvar *HHUBDEFAULTCURRENCY* "INR")
(defvar *HHUBDEFAULTCOUNTRY* "India")
(defvar *NSTGSTSTATECODES-HT* nil)
(defvar *NSTGSTBUSINESSSTATE* "29")

;;; Invoice templates 
(defvar *NSTGSTINVOICETERMS* NIL)
(defvar *NST-INVOICEDRAFT-TEMPLATEFILE* "/home/ubuntu/ninestores/hhub/invoice/templates/invoicedraft.html")
(defvar *NST-INVOICEPAYREMINDER-TEMPLATEFILE* "/home/ubuntu/ninestores/hhub/invoice/templates/invoicepayreminder.html")
(defvar *NST-INVOICEPAYOVERDUEREMINDER-TEMPLATEFILE* "/home/ubuntu/ninestores/hhub/invoice/templates/invoicepayoverduereminder.html")
(defvar *NST-INVOICEPAID-TEMPLATEFILE* "/home/ubuntu/ninestores/hhub/invoice/templates/invoicepaid.html")
(defvar *NST-INVOICESHIPPED-TEMPLATEFILE* "/home/ubuntu/ninestores/hhub/invoice/templates/invoiceshipped.html")
(defvar *NST-INVOICECANCELLED-TEMPLATEFILE* "/home/ubuntu/ninestores/hhub/invoice/templates/invoicecancelled.html")
(defvar *NST-INVOICEREFUNDED-TEMPLATEFILE* "/home/ubuntu/ninestores/hhub/invoice/templates/invoicerefunded.html")
(defvar *NST-INVOICEPAYMENT-TEMPLATEFILE* "/home/ubuntu/ninestores/hhub/invoice/templates/invoicepayment.html")
(defvar *NST-INVOICESETTINGS-HTMLFILE* "/home/ubuntu/ninestores/hhub/invoice/templates/invoicesettings.html")
(defvar *NST-INVOICESETTINGS-YAMLFILE* "/home/ubuntu/ninestores/hhub/invoice/templates/invoicesettings.yaml")
(defvar *NST-GSTINVOICE-TEMPLATEFILE-1* "/home/ubuntu/ninestores/hhub/invoice/templates/gstinvoice1.html")
(defvar *NST-GSTINVOICE-TEMPLATEFILE-2* "/home/ubuntu/ninestores/hhub/invoice/templates/gstinvoice2.html")
(defvar *NST-INVOICE-TEMPLATES* nil)
;; Product templates
(defvar *NST-PRDDETAILSFORCUST-TEMPLATEFILE* "/home/ubuntu/ninestores/hhub/products/templates/prddetailsforcust.html")
(defvar *NST-PRDDETAILSFORVEND-TEMPLATEFILE* "/home/ubuntu/ninestores/hhub/products/templates/prddetailsforvend.html")
(defvar *NST-PRODUCT-TEMPLATES* nil)


;; NINE STORES ACTOR MODEL
(defvar  *NSTSENDORDEREMAILACTOR* NIL)
(defvar *NSTAWSS3FILEUPLOADACTOR* NIL)
(defvar *NSTAWSS3FILEDELETEACTOR* NIL)




(defun set-customer-page-title (name)
  (setf *customer-page-title* (format nil "Welcome to Nine Stores - ~A." name))) 
 
(defun set-vendor-page-title (name)
  (setf *vendor-page-title* (format nil "Welcome to Nine Stores - ~A." name))) 

(defun set-admin-page-title (name)
  (setf *admin-page-title* (format nil "Welcome to Nine Stores - ~A." name))) 


;; Connect to the database (see the CLSQL documentation for vendor
;; specific connection specs).

(defun crm-db-connect (&key strdb strusr strpwd servername strdbtype)
  :documentation "This function is responsibile for connecting to the CRM system. Arguments accepted are 
Database 
Username
Password 
Servername 
Database type: Supported type is ':odbc'"

  (progn 
    (case strdbtype
      ((:mysql :postgresql :postgresql-socket)
       (setf *dod-db-instance* (clsql:connect `(,servername
			,strdb
			,strusr
			,strpwd)
		      :database-type strdbtype)))
      ((:odbc :aodbc :oracle)
       (clsql:connect `(,strdb
			,strusr
			,strpwd)
		      :database-type strdbtype))
      (:sqlite
       (clsql:connect `(,strdb)
		      :database-type strdbtype)))

    (clsql:start-sql-recording)))



(defvar *http-server* nil)
(defvar *ssl-http-server* nil)
(defvar *dod-debug-mode* nil)
(defvar *dod-database-caching* nil)


(defun init-hhubplatform ()
  (cond  ((null *dod-debug-mode*) (setf *dod-database-caching* T))
	 (*dod-debug-mode* (setf *dod-database-caching* nil))
	 (T (setf *dod-database-caching* NIL))))


(defun start-das(&optional (withssl nil) (debug-mode T)  )
  :documentation "Start ninestores server with or without ssl. If withssl is T, then start the hunchentoot server with ssl settings"
  (setf *dod-debug-mode* debug-mode)
  (setf *random-state* (make-random-state t))
  ;; # this initializes the global random state by
  ;;   "some means" (e.g. current time.)
  (setf *http-server* (make-instance 'hunchentoot:easy-acceptor :port 4244 :document-root #p"~/ninestores/"))
  (setf (hunchentoot:acceptor-access-log-destination *http-server*)   #p"~/hhublogs/ninestores-access.log")
  (setf (hunchentoot:acceptor-message-log-destination *http-server*) #p"~/hhublogs/ninestores-messages.log")
  ;;Support double quotes for parenscript. 
  ;;CL-WHO leaves it up to you to escape HTML attributes.
  ;;One way to make sure that quoted strings in inline JavaScript
  ;;work inside HTML attributes is to use double quotes for HTML attributes and single quotes for JavaScript strings. 
  (setq cl-who:*attribute-quote-char* #\")
  (progn
    (init-hhubplatform)
    (if withssl  (init-httpserver-withssl))
    (if withssl  (hunchentoot:start *ssl-http-server*) (hunchentoot:start *http-server*) )
    (crm-db-connect :servername *crm-database-server* :strdb *crm-database-name* :strusr *crm-database-user*  :strpwd *crm-database-password* :strdbtype :mysql)
    (setf *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* (hhub-gen-globally-cached-lists-functions))
    (setf *NST-INVOICE-TEMPLATES* (nst-load-invoice-templates))
    (setf *NST-PRODUCT-TEMPLATES* (nst-load-product-templates))
    (setf *NST-EMAIL-TEMPLATES* (nst-load-email-templates))
    (setf *HHUBGLOBALBUSINESSFUNCTIONS-HT* (make-hash-table :test 'equal))
    (setf *HHUBPENDINGUPIFUNCTIONS-HT* (make-hash-table :test 'equal))
    (setf *HHUBBUSINESSSESSIONS-HT* (make-hash-table)) 
    (hhub-init-business-functions)
    (setf *HHUBBUSINESSSERVER* (initbusinessserver))
    (setf *NSTGSTSTATECODES-HT* (init-gst-statecodes))
    (init-gst-invoice-terms)
    (define-shipping-zones)
    (setf *NSTSENDORDEREMAILACTOR* (make-instance 'nst-actor
						  :name "Send Order Email Actor"
						  :behavior #'send-order-email-behavior
						  :stateful t
						  :initial-state 0))
    (setf *NSTAWSS3FILEUPLOADACTOR* (make-instance 'nst-actor
						  :name "AWS S3 Bucket File Upload Actor"
						  :behavior #'async-upload-files-s3bucket-behavior
						  :stateful t
						  :initial-state (make-hash-table)))
    (start-actor *NSTSENDORDEREMAILACTOR*)
    (start-actor *NSTAWSS3FILEUPLOADACTOR*)))




(defun init-httpserver-withssl ()

;(ssl-accslogdest (hunchentoot:acceptor-access-log-destination *ssl-http-server* ))
;(ssl-msglogdest  (hunchentoot:acceptor-message-log-destination *ssl-http-server*)))

(progn 
  (setf *ssl-http-server* (make-instance 'hunchentoot:easy-ssl-acceptor :port 9443 
							  :document-root #p"~/ninestores/hhub/"
							  :ssl-privatekey-file #p"~/ninestores/privatekey.key"
							  :ssl-certificate-file #p"~/ninestores/certificate.crt" ))
(setf (hunchentoot:acceptor-access-log-destination *ssl-http-server* )  #p"~/hhublogs/ninestores-ssl-access.log")
       (setf  (hunchentoot:acceptor-message-log-destination *ssl-http-server*)   #p"~/hhublogs/ninestores-ssl-messages.log")))



(defun stop-das ()
  (format t "******** Stopping SQL Recording *******~C"  #\linefeed)
  (clsql:stop-sql-recording :type :both)
  (format t "******** DB Disconnect ********~C" #\linefeed)
  (clsql:disconnect)
  (format t "******* Stopping HTTP Server *********~C"  #\linefeed)
  (progn (if *ssl-http-server*  (hunchentoot:stop *ssl-http-server*) (hunchentoot:stop *http-server*))
	 (setf *ssl-http-server* nil) 
	 (setf *http-server* nil)
	 (setf *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* NIL)
	 (setf *NST-INVOICE-TEMPLATES* NIL)
	 (setf *HHUBGLOBALBUSINESSFUNCTIONS-HT* NIL)
	 (setf *HHUBBUSINESSSESSIONS-HT* NIL)
	 (deletebusinessserver)
	 (destroy-actor *NSTSENDORDEREMAILACTOR*)
	 (setf *NSTSENDORDEREMAILACTOR* nil)
	 (destroy-actor *NSTAWSS3FILEUPLOADACTOR*)
	 (setf *NSTAWSS3FILEUPLOADACTOR* nil)))


;;;;*********** Globally Cached lists and their accessor functions *********************************

(defun hhub-gen-globally-cached-lists-functions ()
  :documentation "These functions are list returning functions. The various lists are accessible throughout the application. For example, list of all the authorization policies, attributes, etc."
  (let ((policies (get-system-auth-policies))
	(roles (get-system-roles))
	(transactions (get-system-bus-transactions))
	(busobjects (get-system-bus-objects))
	(abacsubjects (get-system-abac-subjects))
	(abacattributes (get-system-abac-attributes))
	(transactions-ht (get-system-bus-transactions-ht))
	(policies-ht (get-system-auth-policies-ht))
	(companies (get-system-companies))
	(currencies-ht (get-system-currencies-ht))
	(curr-html-symbols-ht (get-currency-html-symbol-map))
	(curr-fa-symbols-ht (get-currency-fontawesome-map))
	(gst-hsn-codes-ht (get-system-gst-hsn-codes))
	(gst-sac-codes-ht (get-all-gst-sac-codes)))

    (list (function (lambda () policies)) ;0
	  (function (lambda () roles)) ;1
	  (function (lambda () transactions)) ;2
	  (function (lambda () busobjects)) ;3
	  (function (lambda () abacsubjects)) ;4
 	  (function (lambda () abacattributes)) ;5
	  (function (lambda () companies)) ;6
	  (function (lambda () transactions-ht)) ;7
	  (function (lambda () policies-ht)) ;8
	  (function (lambda () currencies-ht)) ;9
	  (function (lambda () curr-html-symbols-ht)) ;10
	  (function (lambda () curr-fa-symbols-ht)) ;11
	  (function (lambda () gst-hsn-codes-ht)) ;12
	  (function (lambda () gst-sac-codes-ht))))) ;13	
;;******************************************************************************************

(defun hhub-get-cached-auth-policies()
  :documentation "This function gets a list of all the globally cached policies."
  (let ((policiesfunc (nth 0  *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall policiesfunc)))

(defun hhub-get-cached-roles ()
  :documentation "This function gets a list of all the globally cached roles."
  (let ((rolesfunc (nth 1 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall rolesfunc)))


(defun hhub-get-cached-transactions ()
  :documentation "This function gets a list of all the globally cached transactions."
  (let ((transfunc (nth 2 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall transfunc)))


(defun hhub-get-cached-bus-objects ()
  :documentation "This function gets a list of all the globally cached bus objects for System"
  (let ((busobjfunc (nth 3 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall busobjfunc)))


(defun hhub-get-cached-abac-subjects ()
  :documentation "This function gets a list of all the globally cached ABAC Subjects for System"
  (let ((abacsubjectfunc (nth 4 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall abacsubjectfunc)))


(defun hhub-get-cached-abac-attributes ()
  :documentation "This function gets a list of all the globally cached ABAC Attrributes for the system"
  (let ((abacattributesfunc (nth 5  *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall abacattributesfunc)))


(defun hhub-get-cached-companies ()
  :documentation "This function gets a list of all the globally cached transactions in a Hashtable."
 (let ((companies-func (nth 6 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
   (funcall companies-func)))

(defun hhub-get-cached-transactions-ht ()
  :documentation "This function gets a list of all the globally cached transactions in a Hashtable."
 (let ((transfunc-ht (nth 7 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall transfunc-ht)))

(defun hhub-get-cached-auth-policies-ht ()
  :documentation "This function gets a list of all the globally cached ABAC policies in a hashtable."
  (let ((policiesfunc-ht (nth 8 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall policiesfunc-ht)))

(defun hhub-get-cached-currencies-ht ()
  :documentation "This function gets a list of all the globally cached currencies."
  (let ((currencies-ht (nth 9 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall currencies-ht)))

(defun hhub-get-cached-currency-html-symbols-ht ()
  :documentation "This function gets a list of all the globally cached currencies."
  (let ((currency-html-symbols-ht (nth 10 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall currency-html-symbols-ht)))

(defun hhub-get-cached-currency-fontawesome-symbols-ht ()
  :documentation "This function gets a list of all the globally cached currencies."
  (let ((currency-fa-symbols-ht (nth 11 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall currency-fa-symbols-ht)))

(defun hhub-get-cached-gst-hsn-codes-ht ()
  :documentation "This function gets a hash table which contains gst hsn codes."
  (let ((gst-hsn-codes-func  (nth 12 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall gst-hsn-codes-func)))

(defun hhub-get-cached-gst-sac-codes-ht ()
  :documentation "This function gets a hash table which contains gst hsn codes."
  (let ((gst-sac-codes-func  (nth 13 *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*)))
    (funcall gst-sac-codes-func)))


(defun hhub-init-business-function-registrations ()
  :documentation "This function will be called at system startup time to register all the business functions"
  (hhub-register-business-function "com.hhub.businessfunction.getpushnotifysubscriptionforvendor" "com-hhub-businessfunction-getpushnotifysubscriptionforvendor"))


(defun nst-load-invoice-templates ()
  :documentation "Load the invoice templates at startup"
  (let* ((draftemailhtml (hhub-read-file *NST-INVOICEDRAFT-TEMPLATEFILE*))
	 (invoicepaymenthtml (hhub-read-file *NST-INVOICEPAYMENT-TEMPLATEFILE*))
	 (paymentreminderhtml (hhub-read-file *NST-INVOICEPAYREMINDER-TEMPLATEFILE*))
	 (overduepaymentreminderhtml (hhub-read-file *NST-INVOICEPAYOVERDUEREMINDER-TEMPLATEFILE*))
	 (invoicepaidhtml (hhub-read-file *NST-INVOICEPAID-TEMPLATEFILE*))
	 (invoiceshippedhtml (hhub-read-file *NST-INVOICESHIPPED-TEMPLATEFILE*))
	 (invoicecancelledhtml (hhub-read-file *NST-INVOICECANCELLED-TEMPLATEFILE*))
	 (invoicerefundedhtml (hhub-read-file *NST-INVOICEREFUNDED-TEMPLATEFILE*))
	 (invoicesettingshtml (hhub-read-file *NST-INVOICESETTINGS-HTMLFILE*))
	 (invoicesettingsyaml (hhub-read-file *NST-INVOICESETTINGS-YAMLFILE*))
	 (gstinvoice1html (hhub-read-file *NST-GSTINVOICE-TEMPLATEFILE-1*))
	 (gstinvoice2html (hhub-read-file *NST-GSTINVOICE-TEMPLATEFILE-2*)))
    (function (lambda ()
      (values (function (lambda () draftemailhtml))
	      (function (lambda () invoicepaymenthtml))
	      (function (lambda () paymentreminderhtml))
	      (function (lambda () overduepaymentreminderhtml))
	      (function (lambda () invoicepaidhtml))
	      (function (lambda () invoiceshippedhtml))
	      (function (lambda () invoicecancelledhtml))
	      (function (lambda () invoicerefundedhtml))
	      (function (lambda () gstinvoice1html))
	      (function (lambda () gstinvoice2html))
	      (function (lambda () invoicesettingshtml))
	      (function (lambda () invoicesettingsyaml)))))))


(defun nst-get-cached-invoice-template-func (&key templatenum)
  :documentation "returns the function responsible for invoice email HTML template. Call the returning function to get the HTML."
  (multiple-value-bind (draftemailhtmlfunc invoicepaymenthtmlfunc paymentreminderhtmlfunc overduepaymentreminderhtmlfunc invoicepaidhtmlfunc invoiceshippedhtmlfunc invoicecancelledhtmlfunc invoicerefundedhtmlfunc gstinvoice1htmlfunc gstinvoice2htmlfunc invoicesettingshtmlfunc invoicesettingsyamlfunc) (funcall *NST-INVOICE-TEMPLATES*)
    (case templatenum
      (1 draftemailhtmlfunc)
      (2 paymentreminderhtmlfunc)
      (3 overduepaymentreminderhtmlfunc)
      (4 invoicepaidhtmlfunc)
      (5 invoiceshippedhtmlfunc)
      (6 invoicecancelledhtmlfunc)
      (7 invoicerefundedhtmlfunc)
      (8 invoicepaymenthtmlfunc)
      (9 gstinvoice1htmlfunc)
      (10 gstinvoice2htmlfunc)
      (11 invoicesettingshtmlfunc)
      (12 invoicesettingsyamlfunc))))

;;;;;;;;;;;;;; PRODUCT TEMPLATES ;;;;;;;;;;;;;;;;;;;;;;;;

(defun nst-load-product-templates ()
  :documentation "Load the product templates at startup"
  (let* ((prddetailsforcusthtml  (hhub-read-file *NST-PRDDETAILSFORCUST-TEMPLATEFILE*))
	 (prddetailsforvendhtml  (hhub-read-file *NST-PRDDETAILSFORVEND-TEMPLATEFILE*)))
    (function (lambda ()
      (values
       (function (lambda () prddetailsforcusthtml))
       (function (lambda () prddetailsforvendhtml)))))))

(defun nst-get-cached-product-template-func (&key templatenum)
  :documentation "returns the function responsible for product HTML template. Call the returning function to get the HTML."
  (multiple-value-bind (prddetailsforcusthtmlfunc prddetailsforvendhtmlfunc) (funcall *NST-PRODUCT-TEMPLATES*)
    (case templatenum
      (1 prddetailsforcusthtmlfunc)
      (2 prddetailsforvendhtmlfunc))))


;;;;;;;;;;;;;;;;;;EMAIL TEMPLATES ;;;;;;;;;;;;;;;;;;;;;;;;

(defun nst-load-email-templates ()
  :documentation "Load the product templates at startup"
  (let* ((order-email-template (hhub-read-file (format nil "~A/~A" *HHUB-EMAIL-TEMPLATES-FOLDER* *HHUB-GUEST-CUST-ORDER-TEMPLATE-FILE*))))
    (function (lambda ()
      (values (function (lambda () order-email-template)))))))

(defun nst-get-cached-email-template-func (&key templatenum)
  :documentation "returns the function responsible for product HTML template. Call the returning function to get the HTML."
  (multiple-value-bind (orderemailtempl) (funcall *NST-EMAIL-TEMPLATES*)
    (case templatenum
      (1 orderemailtempl))))








;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; Nine Stores GLOBAL BUSINESS FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun hhub-register-business-function (name funcsymbol)
:documentation "This function registers a new business function and adds it to the *HHUBGLOBALBUSINESSFUNCTIONS-HT* Hash Table. It should conform to naming convention com.hhub.businessfunction*"
  (multiple-value-bind (fname) (ppcre:scan "com.hhub.businessfunction.*" name)
    (when fname
      (multiple-value-bind (fsymbol) (ppcre:scan "com-hhub-businessfunction-*" funcsymbol)
	(when fsymbol
	  (setf (gethash name  *HHUBGLOBALBUSINESSFUNCTIONS-HT*) funcsymbol))))))


(defun hhub-execute-business-function (name params) 
  :documentation "This is a general business function adapter for HHub. It takes parameters in a association list"
(handler-case 
    (let ((funcsymbol (gethash name *HHUBGLOBALBUSINESSFUNCTIONS-HT*)))
      (if (null funcsymbol) (error 'hhub-business-function-error :errstring "Business function not registered"))
      (multiple-value-bind (returnvalues exception) (funcall (intern  (string-upcase funcsymbol) :hhub) params)
	;Return a list of return values and exception as nil. 
	(list returnvalues exception)))
  (hhub-business-function-error (condition)
    (list nil (format nil "HHUB Business Function error triggered in Function - ~A. Error: ~A" (string-upcase name) (getExceptionStr condition))))
  ; If we get any general error we will not throw it to the upper levels. Instead set the exception and log it. 
  (error (c)
    (let ((exceptionstr (format nil  "HHUB General Business Function Error: ~A  ~a~%" (string-upcase name) c)))
      (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
			   :direction :output
			   :if-exists :supersede
			   :if-does-not-exist :create)
	(format stream "~A" exceptionstr))
      (list nil (format nil "HHUB General Business Function Error. See logs for more details."))))))



(defun hhub-init-business-functions ()
  (hhub-register-business-function "com.hhub.businessfunction.bl.getpushnotifysubscriptionforvendor" "com-hhub-businessfunction-bl-getpushnotifysubscriptionforvendor")
;;  (hhub-register-business-function "com.hhub.businessfunction.tempstorage.getpushnotifysubscriptionforvendor" "com-hhub-businessfunction-tempstorage-getpushnotifysubscriptionforvendor")
  (hhub-register-business-function "com.hhub.businessfunction.db.getpushnotifysubscriptionforvendor" "com-hhub-businessfunction-db-getpushnotifysubscriptionforvendor")
  ;; Business functions for Creating Push Notify Subscription for Vendor 
  (hhub-register-business-function "com.hhub.businessfunction.bl.createpushnotifysubscriptionforvendor" "com-hhub-businessfunction-bl-createpushnotifysubscriptionforvendor")
  (hhub-register-business-function "com.hhub.businessfunction.tempstorage.createpushnotifysubscriptionforvendor" "com-hhub-businessfunction-tempstorage-createpushnotifysubscriptionforvendor")
  (hhub-register-business-function "com.hhub.businessfunction.db.createpushnotifysubscriptionforvendor" "com-hhub-businessfunction-db-createpushnotifysubscriptionforvendor"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; NINE STORES GLOBAL BUSINESS FUNCTIONS END ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; EXPERIMENTING WITH DOMAIN DRIVEN DESIGN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric initBusinessContexts (BusinessServer ListContextNames)
  (:documentation "This generic function will initialize the business contexts for the business server"))



(defmethod initBusinessContexts ((server BusinessServer) ListContextNames)
  (let* ((contexts (mapcar (lambda (contextname) 
			     (let ((site (make-instance 'BusinessContext)))
			       (setf (slot-value site 'id)  (format nil "~A" (uuid:make-v1-uuid )))
			       (setf (slot-value site 'name) contextname)
			       site)) ListContextNames)))
    contexts))

    
(defun initBusinessServer ()
  (let ((business-server  (make-instance 'BusinessServer)))
    (setf (slot-value business-server 'ipaddress) "127.0.0.1") ;; Not useful Today. May be on future.
    (setf (slot-value business-server 'name) "NineStores")
    (setf (slot-value business-server 'id)  (format nil "~A" (uuid:make-v1-uuid )))
    (setf (slot-value business-server 'BusinessContexts) (initBusinessContexts business-server (list "vendorsite" "compadminsite")))
    business-server))


(defun deleteBusinessServer ()
  (let ((businesscontexts (slot-value *HHUBBUSINESSSERVER* 'BusinessContexts)))
    (loop for bc in businesscontexts do
      (let ((name (slot-value bc 'name)))
	(deletebusinesscontext *HHUBBUSINESSSERVER* name))) 
    (setf *HHUBBUSINESSSERVER* NIL)
    (sb-ext:gc :full t)))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; EXPERIMENTING WITH DOMAIN DRIVEN DESIGN -- END  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  
