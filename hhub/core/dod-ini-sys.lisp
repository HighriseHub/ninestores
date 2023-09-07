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


(defvar *HHUB-CUSTOMER-ORDER-CUTOFF-TIME* "23:00:00")
(defvar *HHUB-DEMO-TENANT-ID* 2)

(defvar *HHUB-COMPILE-FILES-LOCATION* "/home/ubuntu/hhubplatform/bin/hhubcompilelog.txt") 
(defvar *HHUB-EMAIL-CSS-FILE* "/data/www/highrisehub.com/public/css")
(defvar *HHUB-EMAIL-CSS-CONTENTS* NIL)
(defvar *HHUB-EMAIL-TEMPLATES-FOLDER* "/home/ubuntu/hhubplatform/hhub/email/templates")
(defvar *HHUB-CUST-REG-TEMPLATE-FILE* "cust-reg.html")
(defvar *HHUB-CUST-PASSWORD-RESET-FILE* "cust-pass-reset.html")
(defvar *HHUB-CUST-TEMP-PASSWORD-FILE* "temppass.html")
(defvar *HHUB-NEW-COMPANY-REQUEST* "newcompanyrequest.html")
(defvar *HHUB-CONTACTUS-EMAIL-TEMPLATE* "contactustemplate.html")
(defvar *HHUB-GUEST-CUST-ORDER-TEMPLATE-FILE* "guestcustorder.html")
(defvar *HHUB-TERMSANDCONDITIONS-FILE* "tnc.html")
(defvar *HHUB-PRIVACY-FILE* "privacy.html")
(defvar *HHUB-STATIC-FILES* "/home/ubuntu/hhubplatform/site/public")

(defvar *dod-db-instance*)
(defvar *siteurl* "https://www.highrisehub.com")
(defvar *sitepass* (encrypt "P@ssword1" "highrisehub.com"))
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
(defvar *PAYGATEWAYRETURNURL* "https://www.highrisehub.com/hhub/custpaymentsuccess")
(defvar *PAYGATEWAYCANCELURL* "https://www.highrisehub.com/hhub/custpaymentcancel")
(defvar *PAYGATEWAYFAILUREURL* "https://www.highrisehub.com/hhub/custpaymentfailure")
(defvar *HHUBRESOURCESDIR* "/data/www/public/img")
(defvar *HHUBDEFAULTPRDIMG* "HHubDefaultPrdImg.png")
(defvar *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* NIL)
(defvar *HHUBGLOBALBUSINESSFUNCTIONS-HT* NIL)
(defvar *HHUBBUSINESSFUNCTIONSLOGFILE* "/home/hunchentoot/hhublogs/highrisehub-busfunctions.log")

;;; EXPERIMENTING WITH DDD 
(defvar *HHUBENTITYINSTANCES-HT* nil)
(defvar *HHUBENTITY-WEBPUSHNOTIFYVENDOR-HT* NIL)
(defvar *HHUBBUSINESSSESSIONS-HT* NIL) 
(defvar *HHUBBUSINESSLOCATION-VENDOR* NIL)
(defvar *HHUBBUSINESSSERVER* NIL)
(defvar *HHUBBUSINESSDOMAIN* NIL) 

(defvar *HHUBGLOBALROLES* NIL) 
(defvar *HHUBFEATURESWISHLISTURL* "https://goo.gl/forms/hI9LIM9ebPSFwOrm1")
(defvar *HHUBBUGSURL* "https://goo.gl/forms/3iWb2BczvODhQiWW2") 
(defvar *HHUBCUSTLOGINPAGEURL* "/hhub/customer-login.html")
(defvar *HHUBVENDLOGINPAGEURL* "/hhub/vendor-login.html")
(defvar *HHUBOPRLOGINPAGEURL* "/hhub/opr-login.html")
(defvar *HHUBCADLOGINPAGEURL* "/hhub/cad-login.html")
(defvar *HHUBPASSRESETTIMEWINDOW* 20) ; 20 minutes. Depicts the reset password time window. 
(defvar *HHUBGUESTCUSTOMERPHONE* "9999999999")
(defvar *HHUBSUPERADMINEMAIL* "support@highrisehub.com")
(defvar *HHUBSUPPORTEMAIL* "support@highrisehub.com")
(defvar *HHUBPENDINGUPIFUNCTIONS-HT* nil)
(defvar *HHUBTRIALCOMPANYEXPIRYDAYS* 90)
(defvar *HHUBOTPTESTING* T)
(defvar *HHUBUSELOCALSTORFORRES* NIL)
(defvar *HHUBWHATAPPLINKURLINDIA* "https://wa.me/91")
(defvar *HHUBWHATSAPPBUTTONIMG* "WhatsAppButtonGreenSmall.png")
(defvar *HTMLRUPEESYMBOL* "&#8377;")
(defvar *HHUBSHIPPINGZONES* nil)


(defun set-customer-page-title (name)
  (setf *customer-page-title* (format nil "Welcome to HighriseHub - ~A." name))) 
 
(defun set-vendor-page-title (name)
  (setf *vendor-page-title* (format nil "Welcome to HighriseHub - ~A." name))) 

(defun set-admin-page-title (name)
  (setf *admin-page-title* (format nil "Welcome to HighriseHub - ~A." name))) 


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
  :documentation "Start hhubplatform server with or without ssl. If withssl is T, then start 
the hunchentoot server with ssl settings"
  
  (setf *dod-debug-mode* debug-mode)
  (setf *http-server* (make-instance 'hunchentoot:easy-acceptor :port 4244 :document-root #p"~/hhubplatform/"))
  (setf (hunchentoot:acceptor-access-log-destination *http-server*)   #p"~/hhublogs/highrisehub-access.log")
  (setf (hunchentoot:acceptor-message-log-destination *http-server*) #p"~/hhublogs/highrisehub-messages.log")
  ;;Support double quotes for parenscript. 
  ;;CL-WHO leaves it up to you to escape HTML attributes.
  ;;One way to make sure that quoted strings in inline JavaScript
  ;;work inside HTML attributes is to use double quotes for HTML attributes and single quotes for JavaScript strings. 
  (setq cl-who:*attribute-quote-char* #\")
(progn (init-hhubplatform)
       (if withssl  (init-httpserver-withssl))
       (if withssl  (hunchentoot:start *ssl-http-server*) (hunchentoot:start *http-server*) )
       (crm-db-connect :servername *crm-database-server* :strdb *crm-database-name* :strusr *crm-database-user*  :strpwd *crm-database-password* :strdbtype :mysql)
       (setf *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* (hhub-gen-globally-cached-lists-functions))
       (setf *HHUB-CUSTOMER-ORDER-CUTOFF-TIME* "23:00:00")
       (setf *HHUBGLOBALBUSINESSFUNCTIONS-HT* (make-hash-table :test 'equal))
       (setf *HHUBPENDINGUPIFUNCTIONS-HT* (make-hash-table :test 'equal))
       ;(setf *HHUBENTITYINSTANCES-HT* (make-hash-table))
       ;(setf *HHUBENTITY-WEBPUSHNOTIFYVENDOR-HT* (make-hash-table))
       (setf *HHUBBUSINESSSESSIONS-HT* (make-hash-table)) 
       (hhub-init-business-functions)
       (setf *HHUBBUSINESSDOMAIN* (initbusinessdomain))
       (define-shipping-zones)))



(defun init-httpserver-withssl ()

;(ssl-accslogdest (hunchentoot:acceptor-access-log-destination *ssl-http-server* ))
;(ssl-msglogdest  (hunchentoot:acceptor-message-log-destination *ssl-http-server*)))

(progn 
  (setf *ssl-http-server* (make-instance 'hunchentoot:easy-ssl-acceptor :port 9443 
							  :document-root #p"~/hhubplatform/hhub/"
							  :ssl-privatekey-file #p"~/hhubplatform/privatekey.key"
							  :ssl-certificate-file #p"~/hhubplatform/certificate.crt" ))
(setf (hunchentoot:acceptor-access-log-destination *ssl-http-server* )  #p"~/hhublogs/highrisehub-ssl-access.log")
       (setf  (hunchentoot:acceptor-message-log-destination *ssl-http-server*)   #p"~/hhublogs/highrisehub-ssl-messages.log")))



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
(setf *HHUBGLOBALBUSINESSFUNCTIONS-HT* NIL)
;(setf *HHUBENTITY-WEBPUSHNOTIFYVENDOR-HT* NIL)
(setf *HHUBBUSINESSSESSIONS-HT* NIL)
(setf *HHUBBUSINESSDOMAIN* NIL)))

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
	(companies (get-system-companies)))
    (list (function (lambda () policies)) ;0
	  (function (lambda () roles)) ;1
	  (function (lambda () transactions)) ;2
	  (function (lambda () busobjects)) ;3
	  (function (lambda () abacsubjects)) ;4
 	  (function (lambda () abacattributes)) ;5
	  (function (lambda () companies)) ;6
	  (function (lambda () transactions-ht)) ;7
	  (function (lambda () policies-ht))))) ;8


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


(defun hhub-init-business-function-registrations ()
  :documentation "This function will be called at system startup time to register all the business functions"
  (hhub-register-business-function "com.hhub.businessfunction.getpushnotifysubscriptionforvendor" "com-hhub-businessfunction-getpushnotifysubscriptionforvendor"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; HIGHRISEHUB GLOBAL BUSINESS FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun hhub-register-business-function (name funcsymbol)
:documentation "This function registers a new business function and adds it to the *HHUBGLOBALBUSINESSFUNCTIONS-HT* Hash Table."
  (multiple-value-bind (ret1) (ppcre:scan "com.hhub.businessfunction.*" name)
    (unless (null ret1)
      (multiple-value-bind (ret1) (ppcre:scan "com-hhub-businessfunction-*" funcsymbol)
	(unless (null ret1)
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
;;;;;;;;;;;;;;;;;;;; HIGHRISEHUB GLOBAL BUSINESS FUNCTIONS END ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

    
(defun initBusinessDomain ()
  (let ((business-server  (make-instance 'BusinessServer)))
    (setf (slot-value business-server 'ipaddress) "127.0.0.1") ;; Not useful Today. May be on future.
    (setf (slot-value business-server 'name) "HighriseHub")
    (setf (slot-value business-server 'id)  (format nil "~A" (uuid:make-v1-uuid )))
    (setf (slot-value business-server 'BusinessContexts) (initBusinessContexts business-server (list "vendorsite")))
    business-server))


(defun deleteBusinessDomain ()
  (setf *HHUBBUSINESSSERVER* NIL)
  (sb-ext:gc :full t))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; EXPERIMENTING WITH DOMAIN DRIVEN DESIGN -- END  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  
