;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)



(defun hhub-business-adapter (function params)
  :documentation "This is a database adapter for HHUb. It takes parameters in a association list."
  (if (listp params)
      (funcall function params)))


(defun hhub-json-body ()
  (json:decode-json-from-string
    (hunchentoot:raw-post-data :force-text t)))

(defun attr (object field)
  (cdr (assoc field object)))



    
(defun dod-controller-new-company-registration-email-sent ()
  (with-standard-customer-page  "New Company Registration Request"
    (:div :class "row" 
	     (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		   (with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		     (:h1 :class "text-center login-title"  "New Store details have been sent. You will be contacted soon. ")
		     (:a :class "btn btn-primary"  :role "button" :href "https://www.highrisehub.com"  (:span :class "glyphicon glyphicon-home"))
		     (hhub-html-page-footer))))))
  


(defun dod-controller-password-reset-mail-link-sent ()
  (with-standard-customer-page  "Password reset mail" 
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Password Reset Link Sent To Your Email.")
		  (:a :class "btn btn-primary"  :role "button" :href "https://www.highrisehub.com"  (:span :class "glyphicon glyphicon-home")))))))


(defun dod-controller-password-reset-mail-sent ()
(with-standard-customer-page  "Password reset mail"
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Password Reset Email Sent.")
		  (:a :class "btn btn-primary"  :role "button" :href "https://www.highrisehub.com"  (:span :class "glyphicon glyphicon-home")))))))
  

(defun dod-controller-invalid-email-error ()
  (with-standard-customer-page  "Invalid email error"
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Invalid Customer Email.")
		  (:a :class "btn btn-primary"  :role "button" :href "https://www.highrisehub.com"  (:span :class "glyphicon glyphicon-home")))))))



(defun dod-controller-password-reset-token-expired ()
  (with-standard-customer-page "Password reset token expired"
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Your password reset time window has expired. Please try again." )
		  (:a :class "btn btn-primary"  :role "button" :href "https://www.highrisehub.com"  (:span :class "glyphicon glyphicon-home")))))))





(defun hhubsendmail (to subject body &optional (from *HHUBSMTPSENDER*) attachments-list)
  (let ((username *HHUBSMTPUSERNAME*) 
	(password  *HHUBSMTPPASSWORD*))  
    
    (cl-smtp:send-email *HHUBSMTPSERVER*
			from to 
			subject "HighriseHub Email."
			:authentication (list :login username password) 
			:ssl
			:tls
			:html-message body
			:display-name "HighriseHub"
			:attachments attachments-list)))



(defun hhubsendmail-test (to subject body &optional attachments-list)
  (let ((username *HHUBSMTPUSERNAME*) 
	(password  *HHUBSMTPPASSWORD*)) 
    (cl-smtp:send-email *HHUBSMTPSERVER*
			*HHUBSMTPTESTSENDER* to 
			subject "Ok, the HTML version of this email is totally impressive. Just trust me on this." 
			:authentication (list :login username password) 
			:ssl
			:tls
			:html-message body
			:display-name subject
			:attachments attachments-list)))




(defmacro with-html-email ( &body body)
 `(cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
    (:html 
     (:body
       (:img :class "profile-img" :src "https://highrisehub.com/img/logo.png" :alt "Welcome to Highrisehub.com")
       (:p
	,@body)))))




(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-standard-page-template (title nav-func  &body body)
    `(cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
       (:html  :xmlns "http://www.w3.org/1999/xhtml"
	       :xml\:lang "en" 
	       :lang "en"
	       (:head 
		(:meta :http-equiv "content-type" 
		       :content    "text/html;charset=utf-8")
		(:meta :name "viewport" :content "width=device-width,user-scalable=no")
		(:meta :name "theme-color" :content "#5382EE")
		(:meta :names "description" :content "A marketplace app.")
		(:meta :name "author" :content "HighriseHub")
		(:link :rel "icon" :href "/favicon.ico")
		(:title ,title )
					; Link to the app manifest for PWA. 
		(:link :rel "manifest" :href "/manifest.json")
		(:link :href "/css/style.css" :rel "stylesheet")
		;; Bootstrap CSS
		(:link :href "/css/bootstrap.css" :rel "stylesheet")
		(:link :href "/css/bootstrap-theme.min.css" :rel "stylesheet")
		(:link :href "https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css" :rel "stylesheet")
		(:link :href "https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css" :rel "stylesheet")
		(:link :href "https://fonts.googleapis.com/css?family=Merriweather:400,900,900i" :rel "stylesheet")
		(:link :href "/css/theme.css" :rel "stylesheet")


				;; js files related to bootstrap and jquery. Jquery must come first. 
		(:script :src "https://code.jquery.com/jquery-3.5.1.min.js" :integrity "sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" :crossorigin "anonymous")
		(:script :src "https://code.jquery.com/ui/1.12.1/jquery-ui.min.js" :integrity "sha256-VazP97ZCwtekAsvgPBSUwPFKdrwD3unUfSGVYrahUqU=" :crossorigin "anonymous")
		(:script :src "/js/spin.min.js")
		(:script :src "https://www.google.com/recaptcha/api.js")
		(:script :src "https://cdnjs.cloudflare.com/ajax/libs/1000hz-bootstrap-validator/0.11.8/validator.min.js")
		) ;; header completes here.
	        (:body
		 (:div :id "dod-main-container"
		       (:a :id "scrollup" "" )
		       (:div :id "hhub-error" :class "hhub-error-alert" :style "display:none;" )
		       (:div :id "hhub-success" :class "hhub-success-alert" :style "display:none;" )
		       (:div :id "busy-indicator")
		       (:script :src "/js/hhubbusy.js")
		       (if hunchentoot:*session* (,nav-func)) 
					;(if (is-dod-cust-session-valid?) (with-customer-navigation-bar))
		       (:div :class "container theme-showcase" :role "main" 
			     (:div :class "sidebar-nav" 
				   (:div :id "hhubmaincontent"  ,@body))))
		 ;; rangeslider
		      ;; bootstrap core javascript
		 (:script :src "/js/bootstrap.js")
		 (:script :src "/js/dod.js"))))))


(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-standard-page-template-v2 (title nav-func  &body body)
    `(cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
       (:html  :xmlns "http://www.w3.org/1999/xhtml"
	       :xml\:lang "en" 
	       :lang "en"
	       (:head
		(:meta :http-equiv "content-type" 
		       :content    "text/html;charset=utf-8")
		(:meta :name "viewport" :content "width=device-width,user-scalable=no")
		(:meta :name "theme-color" :content "#5382EE")
		(:meta :names "description" :content "A marketplace app.")
		(:meta :name "author" :content "HighriseHub")
		(:link :rel "icon" :href "/favicon.ico")
		(:title ,title )
					; Link to the app manifest for PWA. 
		(:link :rel "manifest" :href "/manifest.json")
		;; Bootstrap CSS
		(:link :href "https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" :rel "stylesheet" :integrity "sha384-EVSTQN3/azprG1Anm3QDgpJLIm9Nao0Yz1ztcQTwFspd3yD65VohhpuuCOmLASjC" :crossorigin "anonymous")

		(:link :href "/css/style.css" :rel "stylesheet")
		
		(:link :href "https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css" :rel "stylesheet")
		(:link :rel "stylesheet" :href "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.8.3/font/bootstrap-icons.css")
		(:link :href "https://fonts.googleapis.com/css?family=Merriweather:400,900,900i" :rel "stylesheet")
		


				;; js files related to bootstrap and jquery. Jquery must come first. 
		(:script :src "https://code.jquery.com/jquery-3.5.1.min.js" :integrity "sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" :crossorigin "anonymous")
		(:script :src "https://code.jquery.com/ui/1.12.1/jquery-ui.min.js" :integrity "sha256-VazP97ZCwtekAsvgPBSUwPFKdrwD3unUfSGVYrahUqU=" :crossorigin "anonymous")
		(:script :src "/js/spin.min.js")
		(:script :src "https://www.google.com/recaptcha/api.js")
		(:script :src "https://cdnjs.cloudflare.com/ajax/libs/1000hz-bootstrap-validator/0.11.8/validator.min.js")
		) ;; header completes here.
	        (:body
		 (:div :id "dod-main-container"
		       (:a :id "scrollup" "" )
		       (:div :id "hhub-error" :class "hhub-error-alert" :style "display:none;" )
		       (:div :id "hhub-success" :class "hhub-success-alert" :style "display:none;" )
		       (:div :id "busy-indicator")
		       (:script :src "/js/hhubbusy.js")
		       (if hunchentoot:*session* (,nav-func)) 
					;(if (is-dod-cust-session-valid?) (with-customer-navigation-bar))
		       (:div :class "container theme-showcase" :role "main" 
			     (:div :class "sidebar-nav" 
				   (:div :id "hhubmaincontent"  ,@body))))
		 ;; rangeslider
		      ;; bootstrap core javascript
		 (:script :src "https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js" :integrity "sha384-MrcW6ZMFYlzcLA8Nl+NtUVF0sA7MsXsP1UyJoMp4YLEuNSfAP+JcXn/tWtIaxVXM" :crossorigin="anonymous")
		 (:script :src "/js/dod.js"))))))


(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-standard-customer-page-v2 (title &body body)
    `(with-standard-page-template-v2  ,title  with-customer-navigation-bar-v2 ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-vendor-page-v2 ( title &body body)
    `(with-standard-page-template-v2  ,title with-vendor-navigation-bar-v2  ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-admin-page-v2 ( title &body body)
    `(with-standard-page-template-v2 ,title   with-admin-navigation-bar-v2   ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-compadmin-page-v2 (title &body body)
    `(with-standard-page-template-v2  ,title  with-compadmin-navigation-bar-v2  ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-no-navbar-page-v2 (title &body body)
    `(with-standard-page-template-v2 ,title (lambda () ()) ,@body)))






(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-standard-customer-page (title &body body)
    `(with-standard-page-template  ,title  with-customer-navigation-bar ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-vendor-page ( title &body body)
    `(with-standard-page-template  ,title with-vendor-navigation-bar  ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-admin-page ( title &body body)
    `(with-standard-page-template ,title   with-admin-navigation-bar   ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-compadmin-page (title &body body)
    `(with-standard-page-template  ,title  with-compadmin-navigation-bar  ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-no-navbar-page (title &body body)
    `(with-standard-page-template ,title (lambda () ()) ,@body)))


(defun print-thread-info ()
:description "This function prints information about all threads" 
      (let* ((curr-thread (bt:current-thread))
             (curr-thread-name (bt:thread-name curr-thread))
             (all-threads (bt:all-threads))
	     (tc (length all-threads)))
        (format t "Current thread: ~a~%~%" curr-thread)
        (format t "Current thread name: ~a~%~%" curr-thread-name)
        (format t "All threads:~% ~{~a~%~}~%" all-threads)
	(format t "Threads count: ~a" tc)) 
      nil)

(defun delete-threads (count)
  :description "This function will kill x number of threads"
  (let* ((all-threads (bt:all-threads)))
    (loop for item in all-threads for i from 1 to count do
      (if (and (not (eql item (bt:current-thread)))
	       (bt:thread-alive-p item)) 
	  (progn
	    (format t "Deleting thread: ~a~%~%" item)
	    (bt:interrupt-thread  item (lambda () (abort))))))))


(defun print-web-session-timeout ()
    (let ((weseti ( get-web-session-timeout)))
	(if weseti (format t "~2,'0d:~2,'0d"
		       (nth 0  weseti)(nth 1 weseti)))))


(defun get-web-session-timeout ()
    (multiple-value-bind
	(seconds minute hour)
	(decode-universal-time (+ (get-universal-time) hunchentoot:*session-max-time*))
	(list hour minute seconds)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-cust-session-check (&body body)
    `(if hunchentoot:*session* ,@body 
					;else 
	 (hunchentoot:redirect *HHUBCUSTLOGINPAGEURL*))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-vend-session-check (&body body)
    `(if hunchentoot:*session* ,@body 
					;else 
	 (hunchentoot:redirect *HHUBVENDLOGINPAGEURL*))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-opr-session-check (&body body)
    `(if (and (verify-superadmin)  hunchentoot:*session*) ,@body 
					;else 
	 (hunchentoot:redirect *HHUBOPRLOGINPAGEURL*))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-cad-session-check (&body body)
    `(if hunchentoot:*session* ,@body 
					;else 
	 (hunchentoot:redirect *HHUBCADLOGINPAGEURL*))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-hhub-transaction (name &optional params  &body body)
    :documentation "This is the Policy Enforcement Point for HighriseHub" 
    `(let* ((transaction (get-ht-val ,name (hhub-get-cached-transactions-ht)))
	    (uri (cdr (assoc "uri" params :test 'equal)))
	    (returnlist (has-permission transaction ,params))
	    (errorstring (nth 1 returnlist)))

	    (hunchentoot:log-message* :info "In the transaction ~A" (slot-value transaction 'name))
	    (hunchentoot:log-message* :info "URI -  ~A" uri)
	    (hunchentoot:log-message* :info "URI in DB  -  ~A" (slot-value transaction 'uri))
	    (if (and (null errorstring) ; check for any exeptions from business function. If there are no exceptions, then we will go ahead with the data processing.  
		     (>= (search  (slot-value transaction 'uri) uri) 0))
		,@body
					;else
		(progn 
		  (hunchentoot:log-message* :info "Permission denied for transaction ~A. Error: ~A " (slot-value transaction 'name) errorstring)
		  (setf (hunchentoot:return-code hunchentoot:*reply*) 500)
		  (format nil "Permission Denied: ~A" errorstring))))))


; Policy Enforcement Point for HHUB
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-hhub-pep (name subject resource action env &body body)
    `(let* ((transaction (select-bus-trans-by-trans-func ,name))
	    (policy-id (slot-value transaction 'auth-policy-id)))
       (if (has-permission1 policy-id ,subject ,resource ,action ,env) 
	   ,@body
					;else 
	   "Permission Denied"))))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-html-dropdown (name kvhash selectedkey)
    `(cl-who:with-html-output (*standard-output* nil)
       (:select :class "form-control" :name ,name 
		(maphash (lambda (key value) 
			   (if (equal key  ,selectedkey) 
			       (cl-who:htm (:option :selected "true" :value key (cl-who:str value)))
					;else
		     (cl-who:htm (:option :value key (cl-who:str value))))) ,kvhash)))))
  


(defun display-as-table (header listdata rowdisplayfunc) 
:documentation "This is a generic function which will display items in list as a html table. You need to pass the html table header and  list data, and a display function which will display data. It also supports search functionality by including the searchresult div. To implement the search functionality refer to livesearch examples. For tiles sizing refer to style.css. " 
  (let ((incr (let ((count 0)) (lambda () (incf count)))))
    (cl-who:with-html-output-to-string (*standard-output* nil)

      ;; searchresult div will be used to store the search result. 
      (:div :id "searchresult"  :class "container" 
	    (:table :class "table  table-striped  table-hover"
		    (:thead (:tr
			     (:th "No")
			     (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) header))) 
		    (:tbody
		     (mapcar (lambda (item)
			       (cl-who:htm (:tr (:td (cl-who:str (funcall incr))) (funcall rowdisplayfunc item))))  listdata)))))))


;; Can this function be converted into a macro?
(defun display-as-tiles (listdata displayfunc tile-css-class) 
:documentation "This is a generic function which will display items in list as tiles. You need to pass the list data, and a display function which will display 
individual tiles. It also supports search functionality by including the searchresult div. To implement the search functionality refer to livesearch examples. For tiles sizingrefer to style.css. " 
  (cl-who:with-html-output-to-string (*standard-output* nil)
    ; searchresult div will be used to store the search result. 
    (:div :id "searchresult"  :class "container" 
	  (:div :class "row-fluid"
		(mapcar (lambda (item)
			  (cl-who:htm (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-4" 
					    (:div :class tile-css-class (funcall displayfunc item)))))  listdata)))))



(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro  with-html-search-form (search-form-action search-placeholder &body body) 
    :documentation "Arguments: search-form-action - the form's action, search-placeholder - placeholder for search text box, body - any additional hidden form input elements"  
    `(cl-who:with-html-output (*standard-output* nil ) 
       	 (:form :id "theForm" :name "theForm" :method "POST" :action ,search-form-action :onSubmit "return false"
		(with-html-div-row
		  (:div :class "col-xs-8 col-sm-8 col-md-8 col-lg-8 form-group" 
			(:input :type "text" :name "livesearch" :id "livesearch"  :class "form-control search-query" :placeholder ,search-placeholder))
		  (:div :class "col-xs-4 col-sm-4 col-md-4 col-lg-4 form-group" 
			(:span :class "input-group-btn" (:button :class "btn btn-primary" :type "submit" (:span :class " glyphicon glyphicon-search") " Go!" ))))
       ,@body))))



(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-form ( form-name form-action  &body body) 
    :documentation "Arguments: form-action - the form's action, body - any additional hidden form input elements. This macro supports validator.js"  
    `(cl-who:with-html-output (*standard-output* nil) 
       (:form :class ,form-name :id ,form-name :name ,form-name  :method "POST" :action ,form-action :data-toggle "validator" 
	      ,@body))))


(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-div-row ( &body body) 
    :documentation "A HTML Div element having class as 'row' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "row"
	     ,@body))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-div-row-fluid ( &body body) 
    :documentation "A HTML Div element having class as 'row' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "row-fluid"
	     ,@body))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-div-col ( &body body) 
    :documentation "A HTML Div element having class as 'col' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "col-xs-12 col-sm-12 col-md-6 col-lg-4"
	     ,@body))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-input-text (name label placeholder  value brequired validation-error-msg tabindex &body other-attributes)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-group"
	     (:label :for ,name ,label)
	     (:input :class "form-control"  :type "text" :id ,name :name ,name :placeholder ,placeholder :required ,brequired :value ,value :tabindex ,tabindex :data-error  ,validation-error-msg ,@other-attributes)
	     (:div :class "help-block with-errors")))))


(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-input-hidden (name value &body other-attributes)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-group"
	     (:input :class "form-control"  :type "hidden" :id ,name :name ,name :value ,value ,@other-attributes)))))
	    

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-input-password (name label placeholder  value brequired validation-error-msg tabindex &body other-attributes)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-group"
	     (:label :for ,name ,label)
	     (:input :class "form-control"  :type "password" :id ,name :name ,name :placeholder ,placeholder :required ,brequired :value ,value :tabindex ,tabindex :data-error  ,validation-error-msg ,@other-attributes)
	     (:div :class "help-block with-errors")))))



(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-input-textarea (name label placeholder brequired validation-error-msg tabindex rows &body other-attributes)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-group"
	     (:label :for ,name ,label)
	     (:textarea :class "form-control" :name ,name :id ,name :placeholder ,placeholder  :tabindex ,tabindex :required ,brequired  :rows ,rows :data-error ,validation-error-msg :onkeyup "countChar(this, 400)" ,@other-attributes )
	     (:div :class "help-block with-errors")))))



(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-checkbox (name value bchecked  &optional (brequired nil) &body body)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-check"
	     (:input  :type "checkbox" :name ,name :checked ,bchecked :required ,brequired :value ,value)
	     ,@body))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-panel (panel-class panel-header-text &body body)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class ,panel-class
	     (:div :class "panel-heading" ,panel-header-text)
	     (:div :class "panel-body" ,@body)))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-table (table-class headercolumns border &body body)
    `(cl-who:with-html-output-to-string (*standard-output* nil)
		   (:table :class ,table-class :width "100%" :border ,border :align "center" :cellpadding "0" :cellspacing "0" :style "padding: 0; margin: 0;"
			   (:tr
			    (mapcar (lambda (headercolumn)
				      (cl-who:htm (:th (cl-who:str headercolumn)))) ,headercolumns)) ,@body))))
  

(defun copy-hash-table (hash-table)
  (let ((ht (make-hash-table 
             :test (hash-table-test hash-table)
	     :rehash-size (hash-table-rehash-size hash-table)
             :rehash-threshold (hash-table-rehash-threshold hash-table)
             :size (hash-table-size hash-table))))
    (loop for key being each hash-key of hash-table
       using (hash-value value)
       do (setf (gethash key ht) value)
       finally (return ht))))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro modal-dialog (id title &rest body )
    :documentation "This macro returns the html text for generating a modal dialog using bootstrap."
    `(let ((arialabelledby (format nil "~ALabel" ,id)))
       (cl-who:with-html-output (*standard-output* nil)
	 (:div :class "modal fade" :id ,id :tabindex "-1" :aria-labelledby arialabelledby  :aria-hidden "true"
	       (:div :class "modal-dialog"
		     (:div :class "modal-content" 
			   (:div :class "modal-header" 
				 (:h5 :class "modal-title" ,title)
				 (:button :type "button" :class "close" :data-dismiss "modal" :aria-label "Close"
					   (:span :aria-hidden "true" "&times;")))
				 
			   (:div :class "modal-body" ,@body)
			   (:div :class "modal-footer"
				 (:button :type "button" :class "btn btn-secondary" :data-dismiss "modal" "Close")))))))))






