;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


(defun xxxx-search-html ()
  :description "This will create a html search box widget"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input"
		(:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
		      (with-html-search-form "idsyssearchxxxx" "syssearchxxxx" "idxxxxlivesearch" "xxxxlivesearch" "searchxxxxaction" "onkeyupsearchform1event();" "Search for an xxxx"
			(submitsearchform1event-js "#idxxxxlivesearch" "#xxxxlivesearchresult")))))))

(defun com-hhub-transaction-show-xxxx-page ()
  :description "This is a show list page for all the xxxx entities"
  (with-cust-session-check ;; delete if not needed. 
  (with-vend-session-check ;; delete if not needed. 
  (with-cad-session-check ;; delete if not needed. 
  (with-opr-session-check ;; delete if not needed. 
    (with-mvc-ui-page "xxxx" createmodelforshowxxxx createwidgetsforshowxxxx :role :superadmin :customer :vendor :compadmin)))))) ;; keep only one role, delete reset. 

(defun createmodelforshowxxxx ()
  :description "This is a model function which will create a model to show xxxx entities"
  (let* ((company (get-login-company))
	 (username (get-login-user-name))
	 (presenterobj (make-instance 'xxxxPresenter))
	 (requestmodelobj (make-instance 'xxxxRequestModel
					 :company company))
	 (adapterobj (make-instance 'xxxxAdapter))
	 (objlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj objlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'xxxxHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-xxxx-page" params 
      (function (lambda ()
	(values viewallmodel htmlview username))))))



(defun createwidgetsforupdatexxxx (modelfunc)
:description "This is a widgets function for update xxxx entity"      
  (createwidgetsforgenericredirect modelfunc))






(defmethod RenderListViewHTML ((htmlview xxxxHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for xxxx entities, which will display each xxxx entity in a row"
  (when viewmodellist
    (display-as-table (list "fieldA" "fieldB" "fieldC" "fieldD" "fieldE" "fieldF" "fieldG" "fieldH" "fieldI" "fieldJ" "fieldK" "fieldL" "fieldM" "fieldN" "fieldO" "fieldP" "fieldQ" "fieldR" "fieldS") viewmodellist 'display-xxxx-row)))

(defun createmodelforsearchxxxx ()
  :description "This is a model function for search xxxx entities/entity" 
  (let* ((search-clause (hunchentoot:parameter "xxxxlivesearch"))
	 (company (get-login-company))
	 (presenterobj (make-instance 'xxxxPresenter))
	 (requestmodelobj (make-instance 'xxxxSearchRequestModel
						 :field1 search-clause
						 :company company))
	 (adapterobj (make-instance 'xxxxAdapter))
	 (domainbojlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj domainobjlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'xxxxHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-search-xxxx-action" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))



(defun com-hhub-transaction-search-xxxx-action ()
  :description "This is a MVC function to search action for xxxx entities/entity" 
  (let* ((modelfunc (createmodelforsearchxxxx))
	 (widgets (createwidgetsforsearchxxxx modelfunc)))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (loop for widget in widgets do
	(cl-who:str (funcall widget))))))

(defun createmodelforupdatexxxx ()
  :description "This is a model function for update xxxx entity"
  (let* ((fieldA (hunchentoot:parameter "fieldA"))
	 (fieldB (hunchentoot:parameter "fieldB"))
	 (fieldC (hunchentoot:parameter "fieldC"))
	 (fieldD (hunchentoot:parameter "fieldD"))
	 (fieldE (hunchentoot:parameter "fieldE"))
	 (fieldF (hunchentoot:parameter "fieldF"))
	 (fieldG (hunchentoot:parameter "fieldG"))
	 (fieldH (hunchentoot:parameter "fieldH"))
	 (fieldI (hunchentoot:parameter "fieldI"))
	 (fieldJ (hunchentoot:parameter "fieldJ"))
	 (fieldK (hunchentoot:parameter "fieldK"))
	 (fieldL (hunchentoot:parameter "fieldL"))
	 (fieldM (hunchentoot:parameter "fieldM"))
	 (fieldN (hunchentoot:parameter "fieldN"))
	 (fieldO (hunchentoot:parameter "fieldO"))
	 (fieldP (hunchentoot:parameter "fieldP"))
	 (fieldQ (hunchentoot:parameter "fieldQ"))
	 (fieldR (hunchentoot:parameter "fieldR"))
	 (fieldS (hunchentoot:parameter "fieldS"))
	 (floatfield1 (float (with-input-from-string (in (hunchentoot:parameter "floatfield1"))
		   (read in))))
	 (company (get-login-company)) ;; or get ABAC subject specific login company function. 
	 (requestmodel (make-instance 'xxxxRequestModel
					 :fieldA fieldA
					 :fieldB fieldB
					 :fieldC fieldC
					 :fieldD fieldD
					 :fieldE fieldE
					 :fieldF fieldF
					 :fieldG fieldG
					 :fieldH fieldH
					 :fieldI fieldI
					 :fieldJ fieldJ
					 :fieldK fieldK
					 :fieldL fieldL
					 :fieldM fieldM
					 :fieldN fieldN
					 :fieldO fieldO
					 :fieldP fieldP
					 :fieldQ fieldQ
					 :fieldR fieldR
					 :fieldS fieldS 
					 :company company))
	 (adapterobj (make-instance 'xxxxAdapter))
	 (redirectlocation  "/hhub/xxxx")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-xxxx-action" params 
      (handler-case 
	  (let ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))


(defun createmodelforcreatexxxx ()
  :description "This is a create model function for creating a xxxx entity"
  (let* ((fieldA (hunchentoot:parameter "fieldA"))
	 (fieldB (hunchentoot:parameter "fieldB"))
	 (fieldC (hunchentoot:parameter "fieldC"))
	 (fieldD (hunchentoot:parameter "fieldD"))
	 (fieldE (hunchentoot:parameter "fieldE"))
	 (fieldF (hunchentoot:parameter "fieldF"))
	 (fieldG (hunchentoot:parameter "fieldG"))
	 (fieldH (hunchentoot:parameter "fieldH"))
	 (fieldI (hunchentoot:parameter "fieldI"))
	 (fieldJ (hunchentoot:parameter "fieldJ"))
	 (fieldK (hunchentoot:parameter "fieldK"))
	 (fieldL (hunchentoot:parameter "fieldL"))
	 (fieldM (hunchentoot:parameter "fieldM"))
	 (fieldN (hunchentoot:parameter "fieldN"))
	 (fieldO (hunchentoot:parameter "fieldO"))
	 (fieldP (hunchentoot:parameter "fieldP"))
	 (fieldQ (hunchentoot:parameter "fieldQ"))
	 (fieldR (hunchentoot:parameter "fieldR"))
	 (fieldS (hunchentoot:parameter "fieldS"))
	 (floatfield1 (float (with-input-from-string (in (hunchentoot:parameter "floatfield1"))
		   (read in))))
	 (company (get-login-company)) ;; or get ABAC subject specific login company function. 
	 (requestmodel (make-instance 'xxxxRequestModel
					 :fieldA fieldA
					 :fieldB fieldB
					 :fieldC fieldC
					 :fieldD fieldD
					 :fieldE fieldE
					 :fieldF fieldF
					 :fieldG fieldG
					 :fieldH fieldH
					 :fieldI fieldI
					 :fieldJ fieldJ
					 :fieldK fieldK
					 :fieldL fieldL
					 :fieldM fieldM
					 :fieldN fieldN
					 :fieldO fieldO
					 :fieldP fieldP
					 :fieldQ fieldQ
					 :fieldR fieldR
					 :fieldS fieldS 
					 :company company))
	 (adapterobj (make-instance 'xxxxAdapter))
	 (redirectlocation  "/hhub/xxxx")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-create-xxxx-action" params 
      (handler-case 
	  (let ((domainobj (ProcessCreateRequest adapterobj requestmodel)))
	    ;; Create the GST HSN Code object if not present. 
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))

(defun com-hhub-transaction-create-xxxx-dialog (&optional domainobj)
  :description "This function creates a dialog to create xxxx entity"
  (let* ((fieldA  (if domainobj (slot-value domainobj 'fieldA)))
	 (fieldB  (if domainobj (slot-value domainobj 'fieldB)))
	 (fieldC  (if domainobj (slot-value domainobj 'fieldC)))
	 (fieldD  (if domainobj (slot-value domainobj 'fieldD)))
	 (fieldE  (if domainobj (slot-value domainobj 'fieldE)))
	 (fieldF  (if domainobj (slot-value domainobj 'fieldF)))
	 (fieldG  (if domainobj (slot-value domainobj 'fieldG)))
	 (fieldH  (if domainobj (slot-value domainobj 'fieldH)))
	 (fieldI  (if domainobj (slot-value domainobj 'fieldI)))
	 (fieldJ  (if domainobj (slot-value domainobj 'fieldJ)))
	 (fieldK  (if domainobj (slot-value domainobj 'fieldK)))
	 (fieldL  (if domainobj (slot-value domainobj 'fieldL)))
	 (fieldM  (if domainobj (slot-value domainobj 'fieldM)))
	 (fieldN  (if domainobj (slot-value domainobj 'fieldN)))
	 (fieldO  (if domainobj (slot-value domainobj 'fieldO)))
	 (fieldP  (if domainobj (slot-value domainobj 'fieldP)))
	 (fieldQ  (if domainobj (slot-value domainobj 'fieldQ)))
	 (fieldR  (if domainobj (slot-value domainobj 'fieldR)))
	 (fieldS  (if domainobj (slot-value domainobj 'fieldS))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form (format nil "form-addxxxx~A" fieldA)  (if domainobj "updatexxxxaction" "createxxxxaction")
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "fieldA" :maxlength "20"  :value  fieldA :placeholder "xxxx (max 20 characters) " :type "text" ))
		    (:div :class "form-group"
			  (:label :for "description")
			  (:textarea :class "form-control" :name "description"  :placeholder "Description ( max 500 characters) "  :rows "5" :onkeyup "countChar(this, 500)" (cl-who:str description)))
		    (:div :class "form-group" :id "charcount")
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldB :placeholder "fieldB"  :name "fieldB" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldC :placeholder "fieldC"  :name "fieldC" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldD :placeholder "fieldD"  :name "fieldD" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldE :placeholder "fieldE"  :name "fieldE" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldF :placeholder "fieldF"  :name "fieldF" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldG :placeholder "fieldG"  :name "fieldG" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldH :placeholder "fieldH"  :name "fieldH" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldI :placeholder "fieldI"  :name "fieldI" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldJ :placeholder "fieldJ"  :name "fieldJ" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldK :placeholder "fieldK"  :name "fieldK" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldL :placeholder "fieldL"  :name "fieldL" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldM :placeholder "fieldM"  :name "fieldM" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldN :placeholder "fieldN"  :name "fieldN" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldO :placeholder "fieldO"  :name "fieldO" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldP :placeholder "fieldP"  :name "fieldP" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldQ :placeholder "fieldQ"  :name "fieldQ" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldR :placeholder "fieldR"  :name "fieldR" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value fieldS :placeholder "fieldS"  :name "fieldS" ))
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))





(defun createwidgetsforcreatexxxx (modelfunc)
  :description "This is a create widget function for xxxx entity"
  (createwidgetsforgenericredirect modelfunc))






(defun createwidgetsforshowxxxx (modelfunc)
 :description "This is the view/widget function for show xxxx entities". 
  (multiple-value-bind (viewallmodel htmlview username) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (:div :id "row"
			     (:div :id "col-xs-6" 
				   (:h3 "Welcome " (cl-who:str (format nil "~A" username)))))
		       (xxxx-search-html)
		       (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (:h4 "Showing records for xxxx."))
		       (:div :id "xxxxlivesearchresult" 
			     (:div :class "row"
				   (:div :class"col-xs-6"
					 (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#editxxxx-modal" "Add xxxx")
					 (modal-dialog "editxxxx-modal" "Add/Edit xxxx" (com-hhub-transaction-create-xxxx-dialog)))
				   (:div :class "col-xs-6" :align "right" 
					 (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
			     (:hr)
			     (RenderListViewHTML htmlview viewallmodel))))))
	  (widget3 (function (lambda ()
		     (submitformevent-js "#xxxxlivesearchresult")))))
      (list widget1 widget2 widget3))))


(defun createwidgetsforsearchxxxx (modelfunc)
  :description "This is a widget function for search xxxx entities"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :class "row"
			     (:div :class"col-xs-6"
				   (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#editxxxx-modal" "Add xxxx")
				   (modal-dialog "editxxxx-modal" "Add/Edit xxxx" (com-hhub-transaction-create-xxxx-dialog)))
			     (:div :class "col-xs-6" :align "right" 
				   (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
		       (:hr)
		       (RenderListViewHTML htmlview viewallmodel))))))
      (list widget1))))



 
(defun display-xxxx-row (xxxx)
  :description "This function has HTML row code for xxxx entity row"
  (with-slots (fieldA fieldB fieldC fieldD fieldE fieldF fieldG fieldH fieldI fieldI fieldJ fieldK fieldL fieldM fieldN fieldO fieldP fieldQ fieldR fieldS ) xxxx 
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "10px" (cl-who:str fieldA))
      (:td  :height "10px" (cl-who:str fieldB))
      (:td  :height "10px" (cl-who:str fieldC))
      (:td  :height "10px" (cl-who:str fieldD))
      (:td  :height "10px" (cl-who:str fieldE))
      (:td  :height "10px" (cl-who:str fieldF))
      (:td  :height "10px" (cl-who:str fieldG))
      (:td  :height "10px" (cl-who:str fieldH))
      (:td  :height "10px" (cl-who:str fieldI))
      (:td  :height "10px" (cl-who:str fieldJ))
      (:td  :height "10px" (cl-who:str fieldK))
      (:td  :height "10px" (cl-who:str fieldL))
      (:td  :height "10px" (cl-who:str fieldM))
      (:td  :height "10px" (cl-who:str fieldN))
      (:td  :height "10px" (cl-who:str fieldO))
      (:td  :height "10px" (cl-who:str fieldP))
      (:td  :height "10px" (cl-who:str fieldQ))
      (:td  :height "10px" (cl-who:str fieldR))
      (:td  :height "10px" (cl-who:str fieldS))
      (:td  :height "10px" 
	    (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target (format nil "#editxxxx-modal~A" field1) (:i :class "fa-solid fa-pencil"))
	    (modal-dialog-v2 (format nil "editxxxx-modal~A" field1) (cl-who:str (format nil "Add/Edit xxxx " )) (com-hhub-transaction-create-xxxx-dialog xxxx))
	    (modal-dialog (format nil "editxxxx-modal~A" field1) "Add/Edit xxxx" (com-hhub-transaction-create-xxxx-dialog xxxx))))))


(defun com-hhub-transaction-update-xxxx-action ()
  :description "This is the MVC function to update action for xxxx entity"
  (with-cust-session-check ;; delete if not needed. 
  (with-vend-session-check ;; delete if not needed. 
  (with-cad-session-check ;; delete if not needed. 
  (with-opr-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  createmodelforupdatexxxx createwidgetsforupdatexxxx)))
      (format nil "~A" url)))))))


(defun com-hhub-transaction-create-xxxx-action ()
  :description "This is a MVC function for create xxxx entity"
  (with-cust-session-check ;; delete if not needed. 
  (with-vend-session-check ;; delete if not needed. 
  (with-cad-session-check ;; delete if not needed. 
  (with-opr-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  createmodelforcreatexxxx createwidgetsforcreatexxxx)))
      (format nil "~A" url)))))))








