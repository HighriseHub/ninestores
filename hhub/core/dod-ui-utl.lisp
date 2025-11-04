;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)


;; A simple UI framework within MVC which have these 3 things
;; 1) Page - a page is html page containing one or more components
;; 2) Component - a component is a logical UI entity containing more than one widgets.
;; 3) Widgets - A widget is a leaf node in the page and component hierarchy. The widget contains the
;; actual HTML, CSS and JAVASCRIPT. 

;; Widget is a function that when called renders HTML/JS/CSS
(defun make-ui-widget (render-fn)
  ;; returns a widget structure containing closure
  (list :type :widget :render render-fn))

(defun render-ui-widget (widget)
  ;; return closure, not immediate execution
  (getf widget :render))

;; Component is a collection of widgets or nested components
(defun make-ui-component (name renderer-fn)
  "Create a component.
NAME is a keyword identifier.
RENDERER-FN is a function that takes MODELFUNC and returns a list of widgets."
  (list :type :component :name name :renderer renderer-fn))

(defun render-ui-component (component modelfunc)
  "Render a component by invoking its renderer with MODELFUNC.
Returns a list of widget outputs."
  (let* ((renderer (getf component :renderer))
         (widgets (funcall renderer modelfunc)))
    (mapcar #'render-ui-widget widgets)))

;; Page is a collection of components
(defun make-ui-page (persona name &rest components)
  (list :type :page :persona persona :name name :components components))

(defun render-ui-page (page modelfunc)
  (mapcan (lambda (component)
	    (render-ui-component component modelfunc)) (getf page :components)))


;;;;;;;;;;;;;;;;;;;; Simple UI Framework ends here ;;;;;;;;;;;;;;;;;;;;

(defun nst-generic-login-with-password (persona formaction redirectonfailure)
  (handler-case 
      (progn  
	(if (equal (caar (clsql:query "select 1" :flatp nil :field-names nil :database *dod-db-instance*)) 1) T)      
	(if (is-dod-session-valid?)
	    (hunchentoot:redirect redirectonfailure))
	(with-no-navbar-page-v2 (format nil "Welcome ~A" persona)
	  (with-html-div-row
	    (with-html-div-col-12
	      (with-html-card
		  (:title "Login"
		   :image-src "/img/logo.png"
		   :image-alt (format nil "~A Login" persona)
		   :image-style "width: 200px; height: 200px;")
		(:form :class "form-custsignin" :role "form" :method "POST" :action formaction :data-toggle "validator"
		       (:div :class "form-group"
			     (:input :class "form-control" :name "phone" :placeholder "Enter RMN. Ex: 9999999999" :type "number" :required "true"))
		       (:div :class "form-group"
			     (:input :class "form-control" :name "password" :placeholder "password=Welcome1" :type "password"  :required "true"))
		       (:div :class "form-group"
			     (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Login")))
		(:a :data-toggle "modal" :data-target (format nil "#dascustforgotpass-modal")  :href "#"  "Forgot Password?")
		(modal-dialog (format nil "dascustforgotpass-modal") "Forgot Password?" (modal.customer-forgot-password))
		(hhub-html-page-footer))))))
    (clsql:sql-database-data-error (condition)
      (if (equal (clsql:sql-error-error-id condition) 2013 ) (progn
							       (stop-das) 
							       (start-das)
							       (hunchentoot:redirect "/hhub/hhubcustloginv2"))))))


(defun safe-read-from-string (string &optional default-value)
  "Attempts to read a Lisp expression from a string, returning a default value if parsing fails."
  (handler-case
      (let ((trimmed-string (string-trim '(#\space) string)))
        (if (string= trimmed-string "") ; Check for empty string
            default-value
            (read-from-string trimmed-string)))
    (error () ; Catch any error during read-from-string
      default-value)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun displaystorepickupwidget (address)
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-card
	  (:title "Pickup In Store"
	   :image-src "/img/PickupInStore.jpg" 
	   :image-alt "Pickup In Store"
	   :image-style "width: 100px; height: 100px;")
	(:p (:strong "NOTE: This order needs to be picked up from store."))
	(:p (:span (cl-who:str (format nil "&nbsp;Store Address:~A" address ))))
	(:div :class "ribbon" "Pickup In Store")))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun with-html-collapse (collapseid listcollapseitemsfuncs) 
    (cl-who:with-html-output (*standard-output* nil)
      (:div :id collapseid :class "collapse" 
	    (loop for collapse-item-func  in listcollapseitemsfuncs do 
	      (multiple-value-bind (id buttontext itembodyhtml) (funcall collapse-item-func) 
		(cl-who:htm
		 (:div :class "card card-body" :id id  (format nil "~A" itembodyhtml)))))))))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun with-html-accordion (accordionid listaccordionitemsfuncs) 
    (cl-who:with-html-output (*standard-output* nil)
      (:div :id accordionid :class "accordion" 
	    (loop for accordion-item-func  in listaccordionitemsfuncs do 
	      (multiple-value-bind (id buttontext itembodyhtml) (funcall accordion-item-func) 
		(cl-who:htm
		 (:div :class "accordion-item"
		       (:h2 :class "accordion-header"
			    (:button :class "accordion-button" :data-bs-toggle "collapse" :data-bs-target (format nil "#~A" id) :aria-expanded "true" :aria-controls (format nil "~A" id) :type "button" "test button" ))
		       (:div  :class "accordion-collapse collapse" :id id :data-bs-parent (format nil "#~A" accordionid)
			      (:div :class "accordion-body"
				    (:strong "This is test")))))))))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun with-modal-dialog-link (name linkhtmlfunc dialogheadertext modalfunc)
    (cl-who:with-html-output (*standard-output* nil)
      (:a :data-bs-toggle "modal" :data-bs-target (format nil "#~A-modal" name)  :href "#" (funcall linkhtmlfunc))
      (modal-dialog-v2 (format nil "~A-modal" name) dialogheadertext (funcall modalfunc)))))


(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-form-having-submit-event ( form-name form-action  &body body) 
    :documentation "Arguments: form-action - the form's action, body - any additional hidden form input elements. This macro supports validator.js. Use this macro when you have individual form which needs submit event."  
    `(cl-who:with-html-output (*standard-output* nil) 
       (:form :class ,form-name :id (format nil "id~A" ,form-name) :name ,form-name  :method "POST" :action ,form-action :data-toggle "validator" :role "form" :enctype "multipart/form-data" 
	      ,@body)
       (submitformevent-js (format nil "#id~A" ,form-name)))))


(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-catch-submit-event (id  &body body)
    :documentation "Arguments: NIL. This macro is used where there are many forms having submit events in a page and we want to catch them all when the event is propogated to the div level."    
      `(cl-who:with-html-output (*standard-output* nil) 
	 (:div :id ,id
	       ,@body)
	 (submitformevent-js (format nil "#~A" ,id)))))
	  

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun submitformevent-js (id-bind-element)
    (cl-who:with-html-output (*standard-output* nil)
      (:script :type "text/javascript"
	       (cl-who:str
		(parenscript:ps
		 (parenscript:chain ($ "document") 
				    (ready (lambda ()
					     (let ((element  (parenscript:chain document (query-selector (parenscript:lisp id-bind-element))))))
					     (if (not (null element))
						 (parenscript:chain element (add-event-listener "submit" (lambda (e)
													   (parenscript:chain e (prevent-default))
													   (let ((target-form (parenscript:@ e target)))
													     ;; if formname is fileuploadform then return as we are having a
													     ;; different event function to handle this. 
													     (if (= (parenscript:chain target-form name) 'file-upload-form) return)
													     (submitformandredirect target-form)))))))))))))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-catch-file-upload-event (id  &body body)
    :documentation "Arguments: NIL. This macro is used where there are many forms having submit events in a page and we want to catch them all when the event is propogated to the div level."    
      `(cl-who:with-html-output (*standard-output* nil) 
	 (:div :id ,id
	       ,@body)
	 (submitfileuploadevent-js (format nil "#~A" ,id)))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun submitfileuploadevent-js (id-bind-element)
    (cl-who:with-html-output (*standard-output* nil)
      (:script :type "text/javascript"
	       (cl-who:str
		(parenscript:ps
		 (parenscript:chain ($ "document") 
				    (ready (lambda ()
					     (let ((element  (parenscript:chain document (query-selector (parenscript:lisp id-bind-element))))))
					     (if (not (null element))
						 (parenscript:chain element (add-event-listener "submit" (lambda (e)
													   ;; We stop event propagation here as there is another submit event on top of this. 
													   (parenscript:chain e (stop-propagation))
													   (submitfileuploadevent e))))))))))))))



(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun sharetextorurlonclick (id-bind-element data)
    (cl-who:with-html-output (*standard-output* nil)
      (:script :type "text/javascript"
	       (cl-who:str
		(parenscript:ps
		  (parenscript:chain ($ "document") 
				     (ready (lambda ()
					      (let ((element  (parenscript:chain document (query-selector (parenscript:lisp id-bind-element))))))
					      (if (not (null element))
						  (parenscript:chain element (add-event-listener "click" (lambda (e)
													   (parenscript:chain e (prevent-default))
													   (parenscript:try 
													    (parenscript:chain navigator (share (parenscript:create title "URL" url (parenscript:lisp data))))
													   (parenscript:chain console (log "Data was shared successfully"))
													   (:catch (err)
													     (parenscript:chain console (log "Share failed: use HTTPS only: " (parenscript:chain err message)))
													     (copy-to-clipboard (parenscript:lisp data))
													     )))))))))))))))


				    
		
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun submitsearchform1event-js (id-bind-element searchresultid)  
    (cl-who:with-html-output (*standard-output* nil)
      (:script :type "text/javascript"
	       (cl-who:str
		(parenscript:ps
		  (defun onkeyupsearchform1event ()
		    (searchformevent (parenscript:lisp id-bind-element) (parenscript:lisp searchresultid)))))))))
		  

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun submitsearchform2event-js (id-bind-element searchresultid)  
    (cl-who:with-html-output (*standard-output* nil)
      (:script :type "text/javascript"
	       (cl-who:str
		(parenscript:ps
		  (defun onkeyupsearchform2event ()
		    (searchformevent (parenscript:lisp id-bind-element) (parenscript:lisp searchresultid)))))))))



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

(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-vendor-breadcrumb (&body body)
    :description "Takes link attributes like HREF and Link name as pair and processes it to display the breadcrumb"
    `(cl-who:with-html-output (*standard-output* nil)
       (:nav :aria-label "breadcrumb"
	     (:ol :class "breadcrumb"
		  (:li :class "breadcrumb-item no-print" (:a :href "/hhub/dodvendindex?context=home" "Home"))
		  ,@body)))))

(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-compadmin-breadcrumb (&body body)
    :description "Takes link attributes like HREF and Link name as pair and processes it to display the breadcrumb"
    `(cl-who:with-html-output (*standard-output* nil)
       (:nav :aria-label "breadcrumb"
	     (:ol :class "breadcrumb"
		  (:li :class "breadcrumb-item no-print" (:a :href "/hhub/hhubcadindex" "Home"))
		  ,@body)))))


(defun whatsapp-widget (phone)
  :description "This function returns the HTML required for the floating whatsapp button"
  (cl-who:with-html-output (*standard-output* nil) 
    (:a :id "floatingwhatsappbutton" :target "_blank"  :href (format nil "createwhatsapplinkwithmessage?phone=~A&message=Hi" phone) :style "font-weight: bold; font-size: 30px !important;"  (:i :class "fa-brands fa-whatsapp"))))

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
		     (:a :class "btn btn-primary"  :role "button" :href "https://www.ninestores.in"  (:i :class "fa-solid fa-house"))
		     (hhub-html-page-footer))))))

(defun dod-controller-password-reset-mail-link-sent ()
  (with-standard-customer-page  "Password reset mail" 
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Password Reset Link Sent To Your Email.")
		  (:a :class "btn btn-primary"  :role "button" :href (format nil "~A" *siteurl*)  (:i :class "fa-solid fa-house")))))))


(defun dod-controller-password-reset-mail-sent ()
(with-standard-customer-page  "Password reset mail"
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Password Reset Email Sent.")
		  (:a :class "btn btn-primary"  :role "button" :href (format nil "~A" *siteurl*)  (:i :class "fa-solid fa-house")))))))
  

(defun dod-controller-invalid-email-error ()
  (with-standard-customer-page  "Invalid email error"
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Invalid Customer Email.")
		  (:a :class "btn btn-primary"  :role "button" :href (format nil "~A" *siteurl*)  (:i :class "fa-solid fa-house")))))))



(defun dod-controller-password-reset-token-expired ()
  (with-standard-customer-page "Password reset token expired"
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-customerchangepin" "hhubcustpassreset"  
					;(:div :class "account-wall"
		  (:h1 :class "text-center login-title"  "Your password reset time window has expired. Please try again." )
		  (:a :class "btn btn-primary"  :role "button" :href (format nil "~A" *siteurl*)  (:i :class "fa-solid fa-house")))))))





(defun hhubsendmail (to subject body &optional (from *HHUBSMTPSENDER*) attachments-list)
  (let ((username *HHUBSMTPUSERNAME*) 
	(password  *HHUBSMTPPASSWORD*))  
    
    (cl-smtp:send-email *HHUBSMTPSERVER*
			from to 
			subject "Nine Stores Email."
			:authentication (list :login username password) 
			:ssl
			:tls
			:html-message body
			:display-name "Nine Stores"
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
	 (:img :class "profile-img" :src (format nil "~A/img/logo.png" *siteurl*) :alt "Welcome to Nine Stores")
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
		(:meta :name "author" :content "Nine Stores")
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
		;;(:script :src "/js/spin.min.js")
		(:script :src "/js/nine-spinner.js")
		(:script :src "https://www.google.com/recaptcha/api.js")
		(:script :src "https://cdnjs.cloudflare.com/ajax/libs/1000hz-bootstrap-validator/0.11.9/validator.min.js"))
		;; header completes here.
	        (:body
		 (:div :class "container-fluid" :id "dod-main-container" :style "background: url(../img/pexels-lumn-295771.jpg) no-repeat center center; background-size: cover;" 
		       (:a :id "scrollup" "" )
		       (:div :id "hhub-error" :class "hhub-error-alert" :style "display:none;" )
		       (:div :id "hhub-success" :class "hhub-success-alert" :style "display:none;")
		       (:div :id "busy-indicator")
		       ;;(:script :src "/js/hhubbusy.js")
		       (if hunchentoot:*session* (,nav-func)) 
		       (:div :class "container-fluid" :style "background-color: white; min-height: calc(100vh - 50px);" :role "main" 
			     (:div :class "sidebar-nav" 
				   (:div :class "container-fluid" :id "hhubmaincontent"  ,@body))))
		 (:script :src "/js/bootstrap.js")
		 (:script :src "/js/dod.js"))))))


(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-standard-page-template-v2 (title nav-func  &body body)
    `(cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
       (:html  :xmlns "http://www.w3.org/1999/xhtml" 
	       :xml\:lang "en" 
	       :lang "en" :data-bs-theme "light"
	       (:head
		(:meta :http-equiv "content-type" 
		       :content    "text/html;charset=utf-8")
		(:meta :name "viewport" :content "width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=no")
		(:meta :name "theme-color" :content "#5382EE")
		(:meta :names "description" :content "A marketplace app.")
		(:meta :name "author" :content "Nine Stores")
		(:link :rel "icon" :href "/favicon.ico")
		(:title ,title )
		;; Link to the app manifest for PWA. 
		(:link :rel "manifest" :href "/manifest.json")
		;; Bootstrap CSS
		;;(:link :href "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" :rel "stylesheet")
		;;(:link :href "/css/bs5.3/css/bootstrap.min.css" :rel "stylesheet" )
		(:link :href "/css/bootstrap5.3.css" :rel "stylesheet" )
		(:link :href "/css/style.css" :rel "stylesheet")
		(:link :href "https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.13.2/themes/cupertino/jquery-ui.min.css" :rel "stylesheet")
		(:link :href "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" :rel "stylesheet")
		(:link :href "https://fonts.googleapis.com/css?family=Merriweather:400,900,900i" :rel "stylesheet")
		;; js files related to bootstrap and jquery. Jquery must come first. 
		(:script :src "https://code.jquery.com/jquery-3.5.1.min.js" :integrity "sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" :crossorigin "anonymous")
		(:script :src "https://ajax.googleapis.com/ajax/libs/jqueryui/1.13.2/jquery-ui.min.js" :integrity "sha256-lSjKY0/srUM9BE3dPm+c4fBo1dky2v27Gdjm2uoZaL0=" :crossorigin "anonymous")
		;;(:script :src "/js/spin.min.js")
		(:script :src "/js/nine-spinner.js")
		;;(:script :src "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js")
		(:script :src "/js/bs5.3/js/bootstrap.bundle.min.js")
		(:script :src "https://www.google.com/recaptcha/api.js")
		(:script :src "https://cdnjs.cloudflare.com/ajax/libs/1000hz-bootstrap-validator/0.11.8/validator.min.js"))
	       ;; header completes here.
	       (:body 
		(:div :id "dod-main-container"
		      :class "min-h-screen bg-gradient-to-br from-[#0f172a] via-[#1e293b] to-[#3b82f6] d-flex flex-column"
		      :style "position: relative;"
		     ;; :style "background: url(../img/pexels-lumn-295771.jpg) no-repeat center center; background-size: cover;" 
		      (:a :id "scrollup" "" )
		      (:div :id "hhub-error" :class "hhub-error-alert" :style "display:none;" )
		      (:div :id "hhub-success" :class "hhub-success-alert" :style "display:none;")
		      (:div :id "busy-indicator")
		      ;;(:script :src "/js/hhubbusy.js")
		      (if hunchentoot:*session* (,nav-func))
		      (:div :class "container py-4 bg-light rounded shadow-sm flex-grow-1"
			    ;;:style "background-color: rgba(255, 255, 255, 0.05);backdrop-filter: blur(4px);min-height: calc(100vh - 100px);"
		      ,@body)
		 (:script :src "/js/dod.js")))))))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-page-template-v3 (title nav-func &body body)
    `(cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
       (:html :lang "en"
              (:head
               (:meta :charset "UTF-8")
	       (:meta :name "viewport" :content "width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=no")
               (:title ,title)
               (:link :rel "icon" :href "/favicon.ico")
	       ;; Link to the app manifest for PWA. 
	       (:link :rel "manifest" :href "/manifest.json")
               ;; ✅ Tailwind CSS (CDN)
               (:script :src "https://cdn.tailwindcss.com")
	       (:link :href "https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.13.2/themes/cupertino/jquery-ui.min.css" :rel "stylesheet")
	       (:link :href "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" :rel "stylesheet")
	       (:link :href "https://fonts.googleapis.com/css?family=Merriweather:400,900,900i" :rel "stylesheet")
	

	       ;; ✅ jQuery (safe fallback for production)
	       (:script :src "https://code.jquery.com/jquery-3.5.1.min.js" :integrity "sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" :crossorigin "anonymous")
	       (:script :src "https://ajax.googleapis.com/ajax/libs/jqueryui/1.13.2/jquery-ui.min.js" :integrity "sha256-lSjKY0/srUM9BE3dPm+c4fBo1dky2v27Gdjm2uoZaL0=" :crossorigin "anonymous")
	
	       ;; ✅ Project-wide JS
	       (:script :src "https://www.google.com/recaptcha/api.js")
	       (:script :src "/js/nine-spinner.js")
               ;; Fonts & icons
               (:link :href "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" :rel "stylesheet")
               (:link :href "https://fonts.googleapis.com/css?family=Inter:400,500,600&display=swap" :rel "stylesheet"))
              (:body :class "min-h-screen bg-gradient-to-br from-[#0f172a] via-[#1e293b] to-[#3b82f6] flex flex-col items-center justify-center"
                     ;;(:div :id "dod-main-container" 
                     ;; Error/success/busy indicators retained for future transition
                     (:div :id "hhub-error" :class "hidden bg-red-500 text-white text-center p-2 rounded shadow")
                     (:div :id "hhub-success" :class "hidden bg-green-500 text-white text-center p-2 rounded shadow")
                     (:div :id "busy-indicator")
                     ;; Navigation if session active
                     (if hunchentoot:*session* (,nav-func))
                     ;; Main page content
                     ;;(:main :id "hhubmaincontent" ;;:class "flex-1 container mx-auto p-4"
                     ,@body
		     (:script :src "/js/dod.js"))))))

(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-standard-page-template-with-sidebar (title nav-func sidebar-func  &body body)
    `(cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
       (:html  :xmlns "http://www.w3.org/1999/xhtml" 
	       :xml\:lang "en" 
	       :lang "en" :data-bs-theme "light"
	       
	       (:head
		(:meta :http-equiv "content-type" 
		       :content    "text/html;charset=utf-8")
		(:meta :name "viewport" :content "width=device-width,user-scalable=no")
		(:meta :name "theme-color" :content "#5382EE")
		(:meta :names "description" :content "A marketplace app.")
		(:meta :name "author" :content "Nine Stores")
		(:link :rel "icon" :href "/favicon.ico")
		(:title ,title )
					; Link to the app manifest for PWA. 
		(:link :rel "manifest" :href "/manifest.json")
		;; Bootstrap CSS
		
		(:link :href "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" :rel "stylesheet")
		;;(:link :href "/css/bs5.3/css/bootstrap.min.css" :rel "stylesheet" )

		(:link :href "/css/bootstrap5.3.css" :rel "stylesheet" )
		(:link :href "/css/style.css" :rel "stylesheet")
		(:link :href "https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.13.2/themes/cupertino/jquery-ui.min.css" :rel "stylesheet")
		(:link :href "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" :rel "stylesheet")
		(:link :href "https://fonts.googleapis.com/css?family=Merriweather:400,900,900i" :rel "stylesheet")
		;; js files related to bootstrap and jquery. Jquery must come first. 
		(:script :src "https://code.jquery.com/jquery-3.5.1.min.js" :integrity "sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" :crossorigin "anonymous")
		(:script :src "https://ajax.googleapis.com/ajax/libs/jqueryui/1.13.2/jquery-ui.min.js" :integrity "sha256-lSjKY0/srUM9BE3dPm+c4fBo1dky2v27Gdjm2uoZaL0=" :crossorigin "anonymous")
		;;(:script :src "/js/spin.min.js")
		(:script :src "/js/nine-spinner.js")
		(:script :src "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js")
		;;(:script :src "/js/bs5.3/js/bootstrap.bundle.min.js")
		(:script :src "https://www.google.com/recaptcha/api.js")
		(:script :src "https://cdnjs.cloudflare.com/ajax/libs/1000hz-bootstrap-validator/0.11.8/validator.min.js")
		) ;; header completes here.
	       (:body
		(:div :class "container-fluid" :id "dod-main-container" :style "background: url(../img/pexels-lumn-295771.jpg) no-repeat center center; background-size: cover;" 
		       (:a :id "scrollup" "" )
		       (:div :id "hhub-error" :class "hhub-error-alert" :style "display:none;" )
		       (:div :id "hhub-success" :class "hhub-success-alert" :style "display:none;" )
		       (:div :id "busy-indicator")
		       ;;(:script :src "/js/hhubbusy.js")
		       ;;
					;(if (is-dod-cust-session-valid?) (with-customer-navigation-bar))
		       (when hunchentoot:*session*
			   (,nav-func)
			   (,sidebar-func))
		       (:div :class "container-fluid" :style "background-color: white; min-height: calc(100vh - 50px);" :role "main" 
			     ,@body))
		       ;; rangeslider
		       ;; bootstrap core javascript
		       (:script :src "/js/dod.js"))))))




(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-standard-customer-page-v2 (title &body body)
    `(with-standard-page-template-v2  ,title with-customer-navigation-bar-v2 ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-standard-customer-page-v3 (title &body body)
    `(with-standard-page-template-v3  ,title with-customer-navigation-bar-v2 ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-vendor-page-v2 ( title &body body)
    `(with-standard-page-template-v2  ,title with-vendor-navigation-bar-v2  ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-vendor-page-v3 ( title &body body)
    `(with-standard-page-template-v3  ,title with-vendor-navigation-bar-v2  ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-admin-page-v2 (title &body body)
    `(with-standard-page-template-v2 ,title with-admin-navigation-bar-v2   ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-compadmin-page-v2 (title &body body)
    `(with-standard-page-template-with-sidebar  ,title with-compadmin-navigation-bar render-compadmin-sidebar-offcanvas  ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-no-navbar-page-v2 (title &body body)
    `(with-standard-page-template-v2 ,title (lambda () ()) ,@body)))


(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-standard-customer-page (title &body body)
    `(with-standard-page-template  ,title with-customer-navigation-bar ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-vendor-page ( title  &body body)
    `(with-standard-page-template-with-sidebar  ,title with-vendor-navigation-bar-v2 render-sidebar-offcanvas  ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-admin-page ( title &body body)
    `(with-standard-page-template ,title with-admin-navigation-bar   ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-standard-compadmin-page (title &body body)
    `(with-standard-page-template  ,title with-compadmin-navigation-bar  ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-no-navbar-page (title &body body)
    `(with-standard-page-template ,title (lambda () ()) ,@body)))

(defun kill-threads-by-prefix (prefix)
  "Kills all threads whose names start with PREFIX."
  (dolist (thread (bt:all-threads))
    (let ((name (bt:thread-name thread)))
      (when (and name (search prefix name))
        (format t "Killing thread: ~A~%" name)
        (bt:destroy-thread thread)))))

(defun print-thread-info ()
:description "This function prints information about all threads" 
      (let* ((curr-thread sb-thread:*current-thread*)
             (curr-thread-name (sb-thread:thread-name curr-thread))
             (all-threads (sb-thread:list-all-threads))
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
    (let ((weseti (get-vendor-web-session-timeout)))
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
    :documentation "This is the Policy Enforcement Point for Nine Stores" 
    `(let* ((transaction (get-ht-val ,name (hhub-get-cached-transactions-ht)))
	    (uri (cdr (assoc "uri" params :test 'equal)))
	    (returnlist (has-permission transaction ,params))
	    (returnvalue (nth 0 returnlist))
	    (exceptionstr (nth 1 returnlist))
	    (redirecturl (format nil "/hhub/permissiondenied?message=~A" (hunchentoot:url-encode "Permission Denied"))))
       (unless transaction
	 (error 'hhub-abac-transaction-error :errstring (format nil "Did not find the transaction by name ~A. Create a new transaction and a related policy." ,name)))
       
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
	       (function (lambda ()
		 (values redirecturl)))))))))




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
    (let ((id (format nil "id~A" name)))
    `(cl-who:with-html-output (*standard-output* nil)
       (:select :class "form-control" :id ,id :name ,name 
		(maphash (lambda (key value) 
			   (if (equal key  ,selectedkey) 
			       (cl-who:htm (:option :selected "true" :value key (cl-who:str value)))
					;else
		     (cl-who:htm (:option :value key (cl-who:str value))))) ,kvhash))))))
  


(defun display-as-table (header listdata rowdisplayfunc &rest arguments) 
:documentation "This is a generic function which will display items in list as a html table. You need to pass the html table header and  list data, and a display function which will display data. It also supports search functionality by including the searchresult div. To implement the search functionality refer to livesearch examples. For tiles sizing refer to style.css. " 
  (let ((incr (let ((count 0)) (lambda () (incf count)))))
    (cl-who:with-html-output-to-string (*standard-output* nil)
      ;; searchresult div will be used to store the search result. 
      (:div :id "searchresult"  :class "container-fluid" 
	    (:table :class "table table-sm  table-striped  table-hover"
		    (:thead (:tr
			     (:th "Sr. No")
			     (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) header))) 
		    (:tbody :class "table-group-divider"
		     (mapcar (lambda (item)
			       (cl-who:htm (:tr (:td (cl-who:str (funcall incr))) (funcall rowdisplayfunc item arguments))))  listdata)))))))


;; Can this function be converted into a macro?
(defun display-as-tiles (listdata displayfunc tile-css-class) 
:documentation "This is a generic function which will display items in list as tiles. You need to pass the list data, and a display function which will display 
individual tiles. It also supports search functionality by including the searchresult div. To implement the search functionality refer to livesearch examples. For tiles sizingrefer to style.css. " 
  (cl-who:with-html-output-to-string (*standard-output* nil)
    ; searchresult div will be used to store the search result. 
    (:div :class "all-products"
	  (mapcar (lambda (item)
		    (cl-who:htm
		     (:div :class tile-css-class (funcall displayfunc item))))  listdata))))

;; This macro will be used for the MVC pattern on the UI display of pages. We need
;; to pass the model generating and view generating functions and specify for which persona this request is for.
;; currently we support customer and vendor roles.

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-mvc-ui-page (pagetitle createmodelfunc createwidgetsfunc &key role)
    `(let* ((modelfunc (funcall ,createmodelfunc))
	    (widgets (funcall ,createwidgetsfunc modelfunc)))
       (case ,role
	 (:customer (display-customer-page-with-widgets ,pagetitle widgets))
	 (:vendor (display-vendor-page-with-widgets ,pagetitle widgets))
	 (:compadmin (display-compadmin-page-with-widgets ,pagetitle widgets))
	 (:superadmin (display-superadmin-page-with-widgets ,pagetitle widgets))))))


(defun create-model-withnildata ()
  (function (lambda ()
    (values nil))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-mvc-binary-file (createmodelfunc createwidgetsfunc)
    `(let* ((modelfunc (funcall ,createmodelfunc))
	    (widgets (funcall ,createwidgetsfunc modelfunc)))
       (loop for widget in widgets do 
	 (funcall widget)))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-mvc-redirect-ui (createmodelfunc createwidgetsfunc)
    `(let* ((modelfunc (funcall ,createmodelfunc))
	    (widgets (funcall ,createwidgetsfunc modelfunc)))
       (funcall (nth 0 widgets)))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defun create-widgets-for-genericredirect (modelfunc)
    (multiple-value-bind (redirectlocation) (funcall modelfunc)
      (let ((widget1 (function (lambda ()
		       redirectlocation))))
	(list widget1)))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-mvc-ui-component (createwidgetsfunc createmodelfunc &rest modelargs)
    `(let* ((modelfunc (funcall ,createmodelfunc ,@modelargs))
	    (widgets (funcall ,createwidgetsfunc modelfunc)))
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

(defun display-compadmin-page-with-widgets (pagetitle widgets)
  (with-standard-compadmin-page-v2 pagetitle
    (loop for widget in widgets do 
      (funcall widget))))

(defun display-superadmin-page-with-widgets (pagetitle widgets)
  (with-standard-admin-page pagetitle
    (loop for widget in widgets do 
      (funcall widget))))

(defun display-search-results-with-widgets (widgets)
  (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (loop for widget in widgets do
	(funcall widget))))

(defun html-back-button ()
  :documentation "HTML Back button"
  (cl-who:with-html-output-to-string (*standard-output* nil ) 
     (with-html-div-row
       (with-html-div-col 
	 (:a :class "btn btn-primary" :onclick "window.history.back();"  :role "button" :href "#" (:i :class "fa-solid fa-left-long"))))))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro  with-html-search-form (form-id form-name txtctrlid txtctrlname  search-form-action onkeyupfunc  search-placeholder &body body)
    :documentation "Arguments: search-form-action - the form's action, search-placeholder - placeholder for search text box, body - any additional hidden form input elements"
    `(cl-who:with-html-output (*standard-output* nil ) 
       (with-html-div-row
	 (with-html-div-col-10
	 (:form :id ,form-id  :name ,form-name :method "POST" :action ,search-form-action :onSubmit "return false"
		(:div :class "input-group" :style "border: 1px solid black; margin-top: 10px;margin-bottom: 10px; margin-right: 20px; margin-left: 15px;"
		      (:input :type "text" :name ,txtctrlname  :id ,txtctrlid  :class "form-control" :placeholder ,search-placeholder   :onkeyup ,onkeyupfunc)
		      (:span :class "input-group-btn" (:button :class "btn btn-primary" :type "submit" (:i :class "fa-solid fa-magnifying-glass") "&nbsp;Go!" )))
		,@body))))))

  

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun WelcomeMessage (username)
    (cl-who:with-html-output (*standard-output* nil) 
      (with-html-div-row
	(with-html-div-col
	  (:h3 "Welcome " (cl-who:str (format nil "~A" username))))))))


(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-form (form-name form-action  &body body) 
    :documentation "Arguments: form-action - the form's action, body - any additional hidden form input elements. This macro supports validator.js. To have submit form event for this form create it outside the macro."  
    `(let ((formid (format nil "id~A~A" ,form-name (hhub-random-password 3))))
       (cl-who:with-html-output (*standard-output* nil) 
	 (:form :class ,form-name :id formid :name ,form-name  :method "POST" :action ,form-action :data-toggle "validator" :role "form" :enctype "multipart/form-data" 
		,@body)))))



(defmacro with-html-card ((&key title image-src image-alt (image-style "") (image-classes '("rounded-circle" "mx-auto" "d-block" "mt-3")) (card-classes '("card")) (body-classes '("card-body" "text-center"))) &body cardbody)
  "A HTML Bootstrap 5.x card generator macro."
  (let ((image-classes-str (if (listp image-classes) (format nil "~{~A~^ ~}" image-classes) image-classes))
        (card-classes-str (if (listp card-classes) (format nil "~{~A~^ ~}" card-classes) card-classes))
        (body-classes-str (if (listp body-classes) (format nil "~{~A~^ ~}" body-classes) body-classes)))
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class ,card-classes-str
             ,(when image-src
                `(:img :src ,image-src
                       :class ,image-classes-str
                       :alt ,image-alt
                       :style ,image-style))
             (:div :class ,body-classes-str
                   (:h3 :class "card-title" ,title)
                   (:p :class "card-text" ,@cardbody))))))

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
  (defmacro with-html-div-col-12 ( &body body) 
    :documentation "A HTML Div element having class as 'col' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "col-12"
	     ,@body))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-div-col-10 ( &body body) 
    :documentation "A HTML Div element having class as 'col' and also having column sizing" 
    `(cl-who:with-html-output (*standard-output* nil) 
       (:div :class "col-10"
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
  (defmacro with-html-input-number (name label placeholder  value min max brequired validation-error-msg tabindex &body other-attributes)
    (let ((textid (format nil "id~A" name)))
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-group"
	     (:label :for ,textid ,label)
	     (:input :class "form-control"  :type "number" :id ,textid :name ,name :placeholder ,placeholder :min ,min :max ,max :required ,brequired :value ,value :tabindex ,tabindex :data-error  ,validation-error-msg ,@other-attributes)
	     (:div :class "help-block with-errors"))))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-input-text (name label placeholder  value brequired validation-error-msg tabindex &body other-attributes)
    (let ((textid (format nil "id~A" name)))
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-group"
	     (:label :for ,textid ,label)
	     (:input :class "form-control"  :type "text" :id ,textid :name ,name :placeholder ,placeholder :required ,brequired :value ,value :tabindex ,tabindex :data-error  ,validation-error-msg ,@other-attributes)
	     (:div :class "help-block with-errors"))))))


(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-input-text-readonly (name label placeholder  value brequired validation-error-msg tabindex &body other-attributes)
    (let ((textid (format nil "id~A" name)))
      `(cl-who:with-html-output (*standard-output* nil)
	 (:div :class "form-group"
	       (:label :for ,name ,label)
	       (:input :class "form-control"  :type "text" :id ,textid :name ,name :placeholder ,placeholder :required ,brequired :value ,value :readonly "true" :tabindex ,tabindex :data-error  ,validation-error-msg ,@other-attributes)
	       (:div :class "help-block with-errors"))))))


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
  (defmacro with-html-input-textarea (name value label placeholder brequired validation-error-msg tabindex rows &body other-attributes)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-group"
	     (:label :for ,name ,label)
	     (:textarea :class "form-control" :name ,name :id (format nil "id~A" ,name) :value ,value :placeholder ,placeholder  :tabindex ,tabindex :required ,brequired  :rows ,rows :data-error ,validation-error-msg :onkeyup "countChar(this, 400)" ,@other-attributes )
	     (:div :class "help-block with-errors")))))



(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-checkbox (name value bchecked  &optional (brequired nil) &body body)
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "form-check"
	     (:input  :type "checkbox" :name ,name :checked ,bchecked :required ,brequired :value ,value)
	     ,@body))))

(eval-when (:compile-toplevel :load-toplevel :execute)     
  (defmacro with-html-custom-checkbox (name value placeholder bchecked &body body)
    (let ((id (format nil "id~A" name)))
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "custom-control custom-switch"
	     (if ,bchecked
		 (cl-who:htm 
		  (:input  :type "checkbox" :class "custom-control-input" :id ,id :name ,name :checked "true" :value ,value :onclick (parenscript:ps (togglecheckboxvalueyn (parenscript:lisp ,id)))))
		 ;;else
		 (cl-who:htm 
		  (:input  :type "checkbox" :class "custom-control-input" :id ,id :name ,name :value ,value :onclick (parenscript:ps (togglecheckboxvalueyn (parenscript:lisp ,id))))))
		(:label :class "custom-control-label" :for ,id  ,placeholder)
		,@body)))))

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

(defmacro defdb-adapter (name lambda-list &body body)
  "Defines a Read Database Adapter function that executes a single CLSQL query 
   and automatically maps the result to one of the four TCUF states, logging 
   critical failures (:U and :C)."
  (let ((results-sym (gensym "RESULTS"))
        (db-error-sym (gensym "DB-ERROR"))
        (caller-sym (gensym "CALLER")))
    `(defun ,name ,lambda-list
       "TCUF Boundary Adapter for database reads. Returns (PAYLOAD/NIL TCUF-STATUS)."
       (handler-case
           (let ((,results-sym ,@body)) 
             (cond
               ;; T: Exactly one result found.
               ((= (length ,results-sym) 1)
                (values (car ,results-sym) +true+))
               ;; F: Zero results found. (Handled gracefully by caller)
               ((= (length ,results-sym) 0)
                (values nil +false+))
               ;; C: More than one result found. (Critical Log required here)
               (t
                (log-critical-error +contradiction+
                                    (format nil "Data Contradiction in ~A: Expected 1, found ~A results." 
                                            ',name (length ,results-sym))
                                    ,results-sym)
                (values ,results-sym +contradiction+))))
         ;; U: Catch any Lisp/database error. (Critical Log required here)
         (error (,db-error-sym)
           (log-critical-error +unknown+
                               (format nil "DB UNKNOWN Error in ~A: ~A" ',name ,db-error-sym)
                               ,db-error-sym)
           (values nil +unknown+))))))

