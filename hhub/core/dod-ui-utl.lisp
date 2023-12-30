;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun text-editor-control (idtextarea value)
    (let ((editorid (format nil "~AEditor" (gensym "hhub")))
	  (editorparentid (format nil "~AEditor" (gensym "hhub"))))
	 
      (cl-who:with-html-output (*standard-output* nil)
	(:div :id editorparentid 
	      (with-html-div-row
		(with-html-div-col-8
		  (:div :id editorid :contenteditable "true" :role "textbox" :style "display: none;text-align: left; margin-top: 10px; border: 1px solid gray; padding: 10px; border-radius: 5px;"
			(cl-who:str value))))
	      (with-html-div-row
		(with-html-div-col-6
		  (:a :id "btnpreview"  :href "" :data-toggle "tooltip" :title "HTML Preview" (:i :class "fa-regular fa-eye")"&nbsp;")
		  (:a :id "btncode"  :href "" :data-toggle "tooltip" :title "HTML Code"  (:i :class "fa-solid fa-code")"&nbsp;"))))
	(:script (cl-who:str (format nil "$(document).ready(function() {
    const editorparentelem  = document.querySelector('#~A');
    if (null != editorparentelem){
	editorparentelem.addEventListener('click', (e) => {
	    e.preventDefault();
            const btnclicked = e.target.parentElement.id;
            if (btnclicked == 'btncode'){
            document.getElementById('~A').value = document.getElementById('~A').innerHTML;
            document.getElementById('~A').style.display = 'block';
            document.getElementById('~A').style.display = 'none'; 
            }
            if (btnclicked == 'btnpreview'){
            document.getElementById('~A').innerHTML = document.getElementById('~A').value;
            document.getElementById('~A').style.display = 'block';
            document.getElementById('~A').style.display = 'none';
            }
            
	});
    }
});" editorparentid idtextarea editorid idtextarea editorid editorid idtextarea editorid idtextarea )))))))



(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun display-csv-as-html-table (csvstringwithheader)
    (let* ((data (cl-csv:read-csv csvstringwithheader))
	   (header (car data))
	   (csvrows (cdr data)))
      (cl-who:with-html-output (*standard-output* nil)
	(with-html-table (format nil "~Acsvtable" (gensym)) header "1"
	  (loop for row in csvrows do
	    (cl-who:htm (:tr
			 (loop for column in row do
			   (cl-who:htm
			    (:td  (cl-who:str column))))))))))))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun html-range-control (name id min max value step)
    (cl-who:with-html-output (*standard-output* nil)
     (:div :class "hhub-range-body"
	   (:div :class "hhub-range-wrap"
		 (:div :class "hhub-range-value" :id (format nil "rangeV_~A" id))
		 (:input :id (format nil "range_~A" id) :name name :type "range" :min min :max max :value value :step step))))))


(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-customer-breadcrumb (&body body)
    :description "Takes link attributes like HREF and Link name as pair and processes it to display the breadcrumb"
    `(cl-who:with-html-output (*standard-output* nil)
       (:nav :aria-label "breadcrumb"
	     (:ol :class "breadcrumb"
		  (:li :class "breadcrumb-item" (:a :href "/hhub/dodcustindex" "Home"))
		  ,@body)))))


(defun whatsapp-widget (phone)
  :description "This function returns the HTML required for the floating whatsapp button"
  (cl-who:with-html-output (*standard-output* nil) 
    (:a :id "floatingwhatsappbutton" :target "_blank"  :href (format nil "createwhatsapplinkwithmessage?phone=~A&message=Hi" phone) :style "font-weight: bold; font-size: 30px !important;"  (:i :class "fa-brands fa-whatsapp" :style "color: #39dd30;"))))

(defun hhub-controller-create-whatsapp-link-with-message ()
  (let* ((phone (hunchentoot:parameter "phone"))
	 (message (hunchentoot:parameter "message"))
	 (url (createwhatsapplinkwithmessage phone message)))
    (hunchentoot:redirect url)))    

(defun jscript-displaysuccess (message)
  (cl-who:with-html-output (*standard-output* nil)
    (:script :type "text/javascript"
	     (cl-who:str
	      (format nil "window.onload = function(){ ~A };" (parenscript:ps (display-success (parenscript:lisp "#hhub-success") (parenscript:lisp message) (parenscript:lisp 3000))))))))    


(defun jscript-displayerror (message)
  (cl-who:with-html-output (*standard-output* nil)
    (:script :type "text/javascript"
	     (cl-who:str
	      (format nil "window.onload = function(){ ~A };" (parenscript:ps (display-error (parenscript:lisp "#hhub-error") (parenscript:lisp message) (parenscript:lisp 3000))))))))    


(defun logIamhere (where)
  (when *dod-debug-mode*
    (hunchentoot:log-message* :info (format nil "~A" where))))

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
		     (:a :class "btn btn-primary"  :role "button" :href "https://www.highrisehub.com"  (:i :class "fa-solid fa-house"))
		     (hhub-html-page-footer))))))

(defun dod-controller-password-reset-mail-link-sent ()
  (with-standard-customer-page  "Password reset mail" 
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Password Reset Link Sent To Your Email.")
		  (:a :class "btn btn-primary"  :role "button" :href "https://www.highrisehub.com"  (:i :class "fa-solid fa-house")))))))


(defun dod-controller-password-reset-mail-sent ()
(with-standard-customer-page  "Password reset mail"
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Password Reset Email Sent.")
		  (:a :class "btn btn-primary"  :role "button" :href "https://www.highrisehub.com"  (:i :class "fa-solid fa-house")))))))
  

(defun dod-controller-invalid-email-error ()
  (with-standard-customer-page  "Invalid email error"
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Invalid Customer Email.")
		  (:a :class "btn btn-primary"  :role "button" :href "https://www.highrisehub.com"  (:i :class "fa-solid fa-house")))))))



(defun dod-controller-password-reset-token-expired ()
  (with-standard-customer-page "Password reset token expired"
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Your password reset time window has expired. Please try again." )
		  (:a :class "btn btn-primary"  :role "button" :href "https://www.highrisehub.com"  (:i :class "fa-solid fa-house")))))))





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



(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-html-email ( &body body)
    `(cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
       (:html 
	(:body
	 (:img :class "profile-img" :src "https://highrisehub.com/img/logo.png" :alt "Welcome to Highrisehub.com")
	 (:p
	  ,@body))))))
  
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
		;; Link to the app manifest for PWA. 
		(:link :rel "manifest" :href "/manifest.json")
		(:link :href "/css/style.css" :rel "stylesheet")
		;; Bootstrap CSS
		(:link :href "/css/bootstrap.css" :rel "stylesheet")
		(:link :href "/css/bootstrap-theme.min.css" :rel "stylesheet")
		
		(:link :href "https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.13.2/themes/cupertino/jquery-ui.min.css" :rel "stylesheet")
		(:link :href "https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.13.2/themes/cupertino/theme.min.css" :rel "stylesheet")
		(:link :href "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" :rel "stylesheet")
		(:link :href "https://fonts.googleapis.com/css?family=Merriweather:400,900,900i" :rel "stylesheet")
		(:link :href "/css/theme.css" :rel "stylesheet")
		;; js files related to bootstrap and jquery. Jquery must come first.
		(:script :src "https://ajax.googleapis.com/ajax/libs/jquery/3.7.0/jquery.min.js" :integrity "sha256-2Pmvv0kuTBOenSvLm6bvfBSSHrUJ+3A7x6P5Ebd07/g=" :crossorigin "anonymous")
		(:script :src "https://ajax.googleapis.com/ajax/libs/jqueryui/1.13.2/jquery-ui.min.js" :integrity "sha256-lSjKY0/srUM9BE3dPm+c4fBo1dky2v27Gdjm2uoZaL0=" :crossorigin "anonymous")
		(:script :src "/js/spin.min.js")
		(:script :src "https://www.google.com/recaptcha/api.js")
		(:script :src "https://cdnjs.cloudflare.com/ajax/libs/1000hz-bootstrap-validator/0.11.9/validator.min.js"))
		;; header completes here.
	        (:body
		 (:div :id "dod-main-container" :style "background: url(../img/pexels-jess-bailey-designs-965119.jpg) no-repeat center center; background-size: cover;" 
		       (:a :id "scrollup" "" )
		       (:div :id "hhub-error" :class "hhub-error-alert" :style "display:none;" )
		       (:div :id "hhub-success" :class "hhub-success-alert" :style "display:none;"
			     (:span :class "closebtn" :onclick "this.parentElement.style.display='none';" "&times;" )
			     (:strong "Success:&nbsp;") "Y")
		       (:div :id "busy-indicator")
		       (:script :src "/js/hhubbusy.js")
		       (if hunchentoot:*session* (,nav-func)) 
					;(if (is-dod-cust-session-valid?) (with-customer-navigation-bar))
		       (:div :class "container theme-showcase" :style "background-color: white; min-height: calc(100vh - 100px);" :role "main" 
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
		(:link :href "/css/bootstrap5.3.css" :rel "stylesheet" )

		(:link :href "/css/style.css" :rel "stylesheet")
		(:link :href "https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.13.2/themes/cupertino/jquery-ui.min.css" :rel "stylesheet")
		(:link :href "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" :rel "stylesheet")
		(:link :href "https://fonts.googleapis.com/css?family=Merriweather:400,900,900i" :rel "stylesheet")
		;; js files related to bootstrap and jquery. Jquery must come first. 
		(:script :src "https://code.jquery.com/jquery-3.5.1.min.js" :integrity "sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" :crossorigin "anonymous")
		(:script :src "https://ajax.googleapis.com/ajax/libs/jqueryui/1.13.2/jquery-ui.min.js" :integrity "sha256-lSjKY0/srUM9BE3dPm+c4fBo1dky2v27Gdjm2uoZaL0=" :crossorigin "anonymous")
		(:script :src "/js/spin.min.js")
		(:script :src "/js/bs5.3/js/bootstrap.bundle.min.js")
		(:script :src "https://www.google.com/recaptcha/api.js")
		(:script :src "https://cdnjs.cloudflare.com/ajax/libs/1000hz-bootstrap-validator/0.11.8/validator.min.js")
		) ;; header completes here.
	        (:body
		 (:div :id "dod-main-container"  :style "background: url(../img/pexels-jess-bailey-designs-965119.jpg) no-repeat center center; background-size: cover;" 
		       (:a :id "scrollup" "" )
		       (:div :id "hhub-error" :class "hhub-error-alert" :style "display:none;" )
		       (:div :id "hhub-success" :class "hhub-success-alert" :style "display:none;" )
		       (:div :id "busy-indicator")
		       (:script :src "/js/hhubbusy.js")
		       (if hunchentoot:*session* (,nav-func)) 
					;(if (is-dod-cust-session-valid?) (with-customer-navigation-bar))
		       (:div :class "container" :role "main" :style "background-color: white; min-height: calc(100vh - 100px);" 
			     (:div :class "sidebar-nav" 
				   (:div :id "hhubmaincontent"  ,@body))))
		 ;; rangeslider
		      ;; bootstrap core javascript
		 
		 (:script :src "/js/dod.js"))))))


(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-standard-customer-page-v2 (title &body body)
    `(with-standard-page-template-v2  ,title with-customer-navigation-bar-v2 ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-vendor-page-v2 ( title &body body)
    `(with-standard-page-template-v2  ,title with-vendor-navigation-bar-v2  ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-admin-page-v2 ( title &body body)
    `(with-standard-page-template-v2 ,title with-admin-navigation-bar-v2   ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-compadmin-page-v2 (title &body body)
    `(with-standard-page-template-v2  ,title with-compadmin-navigation-bar-v2  ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-no-navbar-page-v2 (title &body body)
    `(with-standard-page-template-v2 ,title (lambda () ()) ,@body)))






(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-standard-customer-page (title &body body)
    `(with-standard-page-template  ,title with-customer-navigation-bar ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-vendor-page ( title  &body body)
    `(with-standard-page-template  ,title with-vendor-navigation-bar ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-admin-page ( title &body body)
    `(with-standard-page-template ,title with-admin-navigation-bar   ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-compadmin-page (title &body body)
    `(with-standard-page-template  ,title with-compadmin-navigation-bar  ,@body)))

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

(defun print-vendor-web-session-timeout ()
  (with-vend-session-check 
    (let ((weseti ( get-vendor-web-session-timeout)))
      (if weseti (format t "~2,'0d:~2,'0d"
			 (nth 0  weseti)(nth 1 weseti))))))


(defun get-web-session-timeout ()
  (multiple-value-bind
	  (seconds minute hour)
	(decode-universal-time (+ (get-universal-time) (hunchentoot:session-max-time hunchentoot:*session*)))
      ;;(logiamhere (format nil "Session max time is ~A" (hunchentoot:session-max-time hunchentoot:*session*)))
      (list hour minute seconds)))

(defun get-vendor-web-session-timeout ()
    (multiple-value-bind
	(seconds minute hour)
	(decode-universal-time (+ (getloginvendorsessionstarttime) (hunchentoot:session-max-time hunchentoot:*session*)))
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
	    (returnvalue (nth 0 returnlist))
	    (exceptionstr (nth 1 returnlist)))
       
       (logiamhere (format nil "In the transaction ~A" (slot-value transaction 'name)))
       (logiamhere (format nil "URI -  ~A" uri))
       (logiamhere (format nil "URI in DB  -  ~A" (slot-value transaction 'uri)))
       ;; check for returnvalue to be T and the uri to match 
       (if (and returnvalue (>= (search (slot-value transaction 'uri) uri) 0))
	   ,@body
	   ;;else
	   (progn 
	     (logiamhere (format nil "Permission denied for transaction ~A. Error: ~A " (slot-value transaction 'trans-func) exceptionstr))
	     ;;(setf (hunchentoot:return-code hunchentoot:*reply*) 500)
	     (unless returnvalue 
	       (hunchentoot:redirect (format nil "/hhub/permissiondenied?message=~A" (hunchentoot:url-encode "Permission Denied")))))))))




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
	    (:table :class "table table-sm  table-striped  table-hover"
		    (:thead (:tr
			     (:th "No")
			     (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) header))) 
		    (:tbody :class "table-group-divider"
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

;; This macro will be used for the MVC pattern on the UI display of pages. We need
;; to pass the model generating and view generating functions and specify for which persona this request is for.
;; currently we support customer and vendor roles.
(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-mvc-ui-page (pagetitle createmodelfunc createwidgetsfunc &key role)
    `(let* ((modelfunc (,createmodelfunc))
	    (widgets (,createwidgetsfunc modelfunc)))
       (case ,role
	 (:customer (display-customer-page-with-widgets ,pagetitle widgets))
	 (:vendor (display-vendor-page-with-widgets ,pagetitle widgets))))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-mvc-redirect-ui (createmodelfunc createwidgetsfunc)
    `(let* ((modelfunc (,createmodelfunc))
	    (widgets (,createwidgetsfunc modelfunc)))
       (funcall (nth 0 widgets)))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-mvc-ui-component (createwidgetsfunc createmodelfunc &rest modelargs)
    `(let* ((modelfunc (,createmodelfunc ,@modelargs))
	    (widgets (,createwidgetsfunc modelfunc)))
       (loop for widget in widgets do 
	 (funcall widget)))))
 


;; This function simply displays each widget containing the html, css, javascript code in the linear order.
(defun display-customer-page-with-widgets (pagetitle widgets)
  (with-standard-customer-page-v2 pagetitle
    (loop for widget in widgets do 
      (funcall widget))))

(defun display-vendor-page-with-widgets (pagetitle widgets)
  (with-standard-vendor-page pagetitle
    (loop for widget in widgets do 
      (funcall widget))))





(defun html-back-button ()
  :documentation "HTML Back button"
  `(cl-who:with-html-output-to-string (*standard-output* nil ) 
     (with-html-div-row
       (with-html-div-col 
	 (:a :class "btn btn-primary" :onclick "window.history.back();"  :role "button" :href "#" (:i :class "bi bi-arrow-left"))))))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro  with-html-search-form (form-id form-name txtctrlid txtctrlname  search-form-action search-placeholder &body body)
    :documentation "Arguments: search-form-action - the form's action, search-placeholder - placeholder for search text box, body - any additional hidden form input elements"
    `(cl-who:with-html-output (*standard-output* nil ) 
       (let* ((jsfuncname (gensym ,txtctrlname))
	      (jsfunc (parenscript:ps ((parenscript:lisp jsfuncname) event))))
	 (with-html-div-col-8
	   (:form :id ,form-id  :name ,form-name :method "POST" :action ,search-form-action :onSubmit "return false"
		  (:div :class "input-group"
			(:input :type "text" :name ,txtctrlname  :id ,txtctrlid  :class "form-control" :placeholder ,search-placeholder :onkeyup jsfunc)
			(:span :class "input-group-btn" (:button :class "btn btn-primary" :type "submit" (:i :class "fa-solid fa-magnifying-glass") "&nbsp;Go!" )))
	   ,@body))
	   (let ((jsfuncbody (format nil "function ~A {
    let theForm = event.target.form; 
    let element = document.querySelector('#~A');    
     if (element.value.length == 3 ||
         element.value.length == 5 ||
         element.value.length == 8 ||
         element.value.length == 13 ||
         element.value.length == 21){
          searchformsubmit(theForm,'#~Aresult');
        }
        return false;
     }" (string-right-trim ";" jsfunc) ,txtctrlid ,txtctrlname)))
	     (cl-who:htm
	      (:script (cl-who:str jsfuncbody))))))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun WelcomeMessage (username)
    (cl-who:with-html-output (*standard-output* nil) 
      (with-html-div-row
	(with-html-div-col
	  (:h3 "Welcome " (cl-who:str (format nil "~A" username))))))))


(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-form ( form-name form-action  &body body) 
    :documentation "Arguments: form-action - the form's action, body - any additional hidden form input elements. This macro supports validator.js"  
    `(cl-who:with-html-output (*standard-output* nil) 
       (:form :class ,form-name :id ,form-name :name ,form-name  :method "POST" :action ,form-action :data-toggle "validator" :role "form" :enctype "multipart/form-data" 
	      ,@body))))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-html-card (cardimage cardimagealt cardtitle cardtext  &body body)
    :documentation "A HTML bootstrap 5.x card"
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "card" 
	     (:img :src ,cardimage  :class "card-img-top" :alt ,cardimagealt :style "width: 100px; height: 100px; border-radius: 50%;")
	     (:div :class "card-body"
		   (:h5 :class "card-title" ,cardtitle)
		   (:p :class "card-text" ,cardtext)
		   ,@body)))))


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
  (defmacro with-html-div-col-8 ( &body body) 
    :documentation "A HTML Div element having class as 'col' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "col-8"
	     ,@body))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-div-col-6 ( &body body) 
    :documentation "A HTML Div element having class as 'col' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "col-6"
	     ,@body))))
(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-div-col-4 ( &body body) 
    :documentation "A HTML Div element having class as 'col' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "col-4"
	     ,@body))))
(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-div-col-3 ( &body body) 
    :documentation "A HTML Div element having class as 'col' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "col-3"
	     ,@body))))
(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-div-col-2 ( &body body) 
    :documentation "A HTML Div element having class as 'col' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "col-2"
	     ,@body))))
(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-div-col-1 ( &body body) 
    :documentation "A HTML Div element having class as 'col' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "col-1"
	     ,@body))))
(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-div-col ( &body body) 
    :documentation "A HTML Div element having class as 'col' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "col-xs-12 col-sm-12 col-md-4 col-lg-3"
	     ,@body))))







(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-submit-button (titletext &body other-attributes)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-group"
	     (:button :class "btn btn-lg btn-primary" :type "submit" ,@other-attributes ,titletext)))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-input-text (name label placeholder  value brequired validation-error-msg tabindex &body other-attributes)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-group"
	     (:label :for ,name ,label)
	     (:input :class "form-control"  :type "text" :id ,name :name ,name :placeholder ,placeholder :required ,brequired :value ,value :tabindex ,tabindex :data-error  ,validation-error-msg ,@other-attributes)
	     (:div :class "help-block with-errors")))))


(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-input-text-readonly (name label placeholder  value brequired validation-error-msg tabindex &body other-attributes)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-group"
	     (:label :for ,name ,label)
	     (:input :class "form-control"  :type "text" :id ,name :name ,name :placeholder ,placeholder :required ,brequired :value ,value :readonly "true" :tabindex ,tabindex :data-error  ,validation-error-msg ,@other-attributes)
	     (:div :class "help-block with-errors")))))


(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-input-text-hidden (name value  &body other-attributes)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-group" :style "display: none;"
	     (:input :class "form-control"  :type "text" :id ,name :name ,name :value ,value ,@other-attributes)))))


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


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro modal-dialog-v2 (id title &rest body )
    :documentation "This macro returns the html text for generating a modal dialog using bootstrap."
    `(let ((arialabelledby (format nil "~ALabel" ,id)))
       (cl-who:with-html-output (*standard-output* nil)
	 (:div :class "modal fade" :id ,id :tabindex "-1" :aria-labelledby arialabelledby :aria-hidden "true" 
	       (:div :class "modal-dialog"
		     (:div :class "modal-content" 
			   (:div :class "modal-header" 
				 (:h5 :class "modal-title" ,title)
				 (:button :class "btn-close" :type "button" :data-bs-dismiss "modal" :aria-label "Close"
					  (:span :aria-hidden "true" "&times;")))
			   (:div :class "modal-body" ,@body)
			   (:div :class "modal-footer"
				 (:button :type "button" :class "btn btn-secondary" :data-bs-dismiss "modal" "Close")))))))))






