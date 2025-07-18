;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun gst-hsn-codes-search-html ()
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input"
		(:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
		      (with-html-search-form "idsyssearchhsncodes" "syssearchhsncodes" "idhsncodeslivesearch" "hsncodeslivesearch" "searchhsncodesaction" "onkeyupsearchform1event();" "Search for an GST HSN codes"
			(submitsearchform1event-js "#idhsncodeslivesearch" "#hsncodeslivesearchresult")))))))


(defun com-hhub-transaction-gst-hsn-codes-page ()
  (with-opr-session-check
    (with-mvc-ui-page "GST HSN Codes" #'create-model-for-showgsthsncodes #'create-widgets-for-showgsthsncodes :role :superadmin)))

(defun create-model-for-showgsthsncodes ()
  (let* ((company (get-login-company))
	 (username (get-login-user-name))
	 (gsthsncodespresenter (make-instance 'GSTHSNCodesPresenter))
	 (gsthsncodesrequestmodel (make-instance 'GSTHSNCodesRequestModel
						 :company company))
	 (gsthsncodesadapter (make-instance 'GSTHSNCodesAdapter))
	 (gsthsncodesobjlst (processreadallrequest gsthsncodesadapter gsthsncodesrequestmodel))
	 (gsthsncodesresponsemodellist (processresponselist gsthsncodesadapter gsthsncodesobjlst))
	 (viewallmodel (CreateAllViewModel gsthsncodespresenter gsthsncodesresponsemodellist))
	 (htmlview (make-instance 'GSTHSNCodesHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-gst-hsn-codes-page" params 
      (function (lambda ()
	(values viewallmodel htmlview username))))))

(defun create-widgets-for-showgsthsncodes (modelfunc)
  ;; this is the view. 
  (multiple-value-bind (viewallmodel htmlview username) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (:div :id "row"
			     (:div :id "col-xs-6" 
				   (:h3 "Welcome " (cl-who:str (format nil "~A" username)))))
		       (gst-hsn-codes-search-html)
		       (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (:h4 "Showing records for GST HSN Codes."))
		       (:div :id "hsncodeslivesearchresult" 
			     (:div :class "row"
				   (:div :class"col-xs-6"
					 (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#edithsncode-modal" "Add GST HSN Code")
					 (modal-dialog "edithsncode-modal" "Add/Edit GST HSN CODE" (com-hhub-transaction-create-gst-hsn-code-dialog)))
				   (:div :class "col-xs-6" :align "right" 
					 (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
			     (:hr)
			     (cl-who:str (RenderListViewHTML htmlview viewallmodel))))))))
      (list widget1 widget2))))


(defun create-widgets-for-searchhsncodes (modelfunc)
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :class "row"
			     (:div :class"col-xs-6"
				   (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#edithsncode-modal" "Add GST HSN Code")
				   (modal-dialog "edithsncode-modal" "Add/Edit GST HSN CODE" (com-hhub-transaction-create-gst-hsn-code-dialog)))
			     (:div :class "col-xs-6" :align "right" 
				   (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
		       (:hr)
		       (RenderListViewHTML htmlview viewallmodel))))))
      (list widget1))))


(defmethod RenderListViewHTML ((htmlview GSTHSNCodesHTMLView) viewmodellist)
  (when viewmodellist
    (display-as-table (list "HSN Code" "4 Digit Code" "Description" "SGST" "CGST" "IGST" "Compensation Cess") viewmodellist 'display-gst-hsn-code-row)))

(defun create-model-for-searchhsncodes ()
  (let* ((search-clause (hunchentoot:parameter "hsncodeslivesearch"))
	 (company (get-login-company))
	 (gsthsncodespresenter (make-instance 'GSTHSNCodesPresenter))
	 (gsthsncodesrequestmodel (make-instance 'GSTHSNCodesSearchRequestModel
						 :hsncode search-clause
						 :company company))
	 (gsthsncodesadapter (make-instance 'GSTHSNCodesAdapter))
	 (gsthsncodesobjlst (processreadallrequest gsthsncodesadapter gsthsncodesrequestmodel))
	 (gsthsncodesresponsemodellist (processresponselist gsthsncodesadapter gsthsncodesobjlst))
	 (viewallmodel (CreateAllViewModel gsthsncodespresenter gsthsncodesresponsemodellist))
	 (htmlview (make-instance 'GSTHSNCodesHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-search-gst-hsn-codes-action" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))



(defun com-hhub-transaction-search-gst-hsn-codes-action ()
  (let* ((modelfunc (funcall #'create-model-for-searchhsncodes))
	 (widgets (funcall #'create-widgets-for-searchhsncodes modelfunc)))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (logiamhere (format nil "length of search widgets is ~d" (length widgets)))
      (loop for widget in widgets do
	(cl-who:str (funcall widget))))))


(defun com-hhub-transaction-update-gst-hsn-code-action ()
  (with-opr-session-check
    (let ((url (with-mvc-redirect-ui  #'create-model-for-updategsthsncode #'create-widgets-for-updategsthsncode)))
      (format nil "~A" url))))

(defun create-widgets-for-updategsthsncode (modelfunc)
  (funcall #'create-widgets-for-genericredirect modelfunc))


(defun create-model-for-updategsthsncode ()
  (let* ((code (hunchentoot:parameter "hsncode"))
	 (code4digit (hunchentoot:parameter "hsncode4digit"))
	 (description (hunchentoot:parameter "description"))
	 (sgst-tax (float (with-input-from-string (in (hunchentoot:parameter "sgst"))
		   (read in))))
	 (cgst-tax (float (with-input-from-string (in (hunchentoot:parameter "cgst"))
		   (read in))))
	 (igst-tax (float (with-input-from-string (in (hunchentoot:parameter "igst"))
		   (read in))))
	 (comp-cess-tax (float (with-input-from-string (in (hunchentoot:parameter "compcess"))
		   (read in))))
	 (company (get-login-company))
	 (requestmodel (make-instance 'GSTHSNCodesRequestModel
					 :hsncode code
					 :hsncode4digit code4digit
					 :description description
					 :sgst sgst-tax
					 :cgst cgst-tax
					 :igst igst-tax
					 :compcess comp-cess-tax
					 :company company))
	 (gsthsncodeadapter (make-instance 'GSTHSNCodesAdapter))
	 (redirectlocation  "/hhub/gsthsncodes")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-gst-hsn-code-action" params 
      (handler-case 
	  (let ((gsthsncodeobj (ProcessUpdateRequest gsthsncodeadapter requestmodel)))
	    (function (lambda ()
	      (values redirectlocation gsthsncodeobj))))
	(error (c)
	       (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))



(defun com-hhub-transaction-create-gst-hsn-code-action ()
  (with-opr-session-check
    (let ((url (with-mvc-redirect-ui  #'create-model-for-creategsthsncode #'create-widgets-for-creategsthsncode)))
      (format nil "~A" url))))




(defun create-model-for-creategsthsncode ()
  (let* ((code (hunchentoot:parameter "hsncode"))
	 (code4digit (hunchentoot:parameter "hsncode4digit"))
	 (description (hunchentoot:parameter "description"))
	 (sgst-tax (float (with-input-from-string (in (hunchentoot:parameter "sgst"))
		   (read in))))
	 (cgst-tax (float (with-input-from-string (in (hunchentoot:parameter "cgst"))
		   (read in))))
	 (igst-tax (float (with-input-from-string (in (hunchentoot:parameter "igst"))
		   (read in))))
	 (comp-cess-tax (float (with-input-from-string (in (hunchentoot:parameter "compcess"))
		   (read in))))
	 (company (get-login-company))
	 (requestmodel (make-instance 'GSTHSNCodesRequestModel
					 :hsncode code
					 :hsncode4digit code4digit
					 :description description
					 :sgst sgst-tax
					 :cgst cgst-tax
					 :igst igst-tax
					 :compcess comp-cess-tax
					 :company company))
	 (gsthsncodeadapter (make-instance 'GSTHSNCodesAdapter))
	 (redirectlocation  "/hhub/gsthsncodes")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-create-gst-hsn-code-action" params 
      (handler-case 
	  (let ((gsthsncodeobj (ProcessCreateRequest gsthsncodeadapter requestmodel)))
	    ;; Create the GST HSN Code object if not present. 
	    (function (lambda ()
	      (values redirectlocation gsthsncodeobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))



(defun create-widgets-for-creategsthsncode (modelfunc)
  (funcall #'create-widgets-for-genericredirect modelfunc))

 
(defun display-gst-hsn-code-row (gst-hsn-code &rest arguments)
  (declare (ignore arguments))
  (with-slots (hsncode hsncode4digit description sgst cgst igst compcess) gst-hsn-code 
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "10px" (cl-who:str hsncode))
      (:td  :height "10px" (cl-who:str hsncode4digit))
      (:td  :height "10px" (cl-who:str description))
      (:td  :height "10px" (cl-who:str sgst))
      (:td  :height "10px" (cl-who:str cgst))
      (:td  :height "10px" (cl-who:str igst))
      (:td  :height "10px" (cl-who:str compcess))
      (:td  :height "10px" 
	    (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target (format nil "#edithsncode-modal~A" hsncode) (:i :class "fa-solid fa-pencil"))
	    (modal-dialog (format nil "edithsncode-modal~A" hsncode) "Add/Edit GST HSN CODE" (com-hhub-transaction-create-gst-hsn-code-dialog gst-hsn-code))))))



(defun com-hhub-transaction-create-gst-hsn-code-dialog (&optional hsncodeobj)
  (let* ((code  (if hsncodeobj (slot-value hsncodeobj 'hsncode)))
	 (code-4digit  (if hsncodeobj (slot-value hsncodeobj 'hsncode4digit)))
	 (description  (if hsncodeobj (slot-value hsncodeobj 'description)))
	 (cgst  (if hsncodeobj (slot-value hsncodeobj 'cgst)))
	 (sgst  (if hsncodeobj (slot-value hsncodeobj 'sgst)))
	 (igst  (if hsncodeobj (slot-value hsncodeobj 'igst)))
	 (comp-cess  (if hsncodeobj (slot-value hsncodeobj 'compcess))))
	    
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form (format nil "form-addhsncode~A" code)  (if hsncodeobj "updatehsncodeaction" "createhsncodeaction")
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "hsncode" :maxlength "8"  :value  code :placeholder "HSN Code  ( max 6 characters) " :type "text" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :name "hsncode4digit" :maxlength "4"  :value (cl-who:str code-4digit) :placeholder "HSN Code  ( max 4 characters) " :type "text" ))
		    (:div :class "form-group"
			  (:label :for "description")
			  (:textarea :class "form-control" :name "description"  :placeholder "Description ( max 500 characters) "  :rows "5" :onkeyup "countChar(this, 500)" (cl-who:str description)))
		    (:div :class "form-group" :id "charcount")
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value sgst :placeholder "SGST"  :name "sgst" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value cgst :placeholder "CGST"  :name "cgst" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value igst :placeholder "IGST"  :name "igst" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value comp-cess :placeholder "Compensation Cess"  :name "compcess" ))
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))
