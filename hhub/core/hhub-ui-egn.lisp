;; -*- mode: common-lisp; coding: utf-8 -*
(in-package :hhub)

(defun %entity-name%-search-html ()
  :description "This will create a html search box widget"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input"
		(:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
		      (with-html-search-form "idsyssearch%entity-name%" "syssearch%entity-name%" "id%entity-name%livesearch" "%entity-name%livesearch" "search%entity-name%action" "onkeyupsearchform1event();" "Search for an %entity-name%"
			(submitsearchform1event-js "#id%entity-name%livesearch" "#%entity-name%livesearchresult")))))))

(defun com-hhub-transaction-show-%entity-name%-page ()
  :description "This is a show list page for all the %entity-name% entities"
  (with-cust-session-check ;; delete if not needed. 
  (with-vend-session-check ;; delete if not needed. 
  (with-cad-session-check ;; delete if not needed. 
  (with-opr-session-check ;; delete if not needed. 
    (with-mvc-ui-page "%entity-name%" #'create-model-for-show%entity-name% #'create-widgets-for-show%entity-name% :role :superadmin :customer :vendor :compadmin)))))) ;; keep only one role, delete reset. 

(defun create-model-for-show%entity-name% ()
  :description "This is a model function which will create a model to show %entity-name% entities"
  (let* ((company (get-login-company))
	 (username (get-login-user-name))
	 (presenterobj (make-instance '%entity-name%Presenter))
	 (requestmodelobj (make-instance '%entity-name%RequestModel
					 :company company))
	 (adapterobj (make-instance '%entity-name%Adapter))
	 (objlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj objlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance '%entity-name%HTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-%entity-name%-page" params 
      (function (lambda ()
	(values viewallmodel htmlview username))))))

(defun create-widgets-for-show%entity-name% (modelfunc)
 :description "This is the view/widget function for show %entity-name% entities" 
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-vendor-breadcrumb)
		       (%entity-name%-search-html)
			 (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (:h4 "Showing records for %entity-name%."))
		       (:div :id "%entity-name%livesearchresult" 
			     (:div :class "row"
				   (:div :class"col-xs-6"
					 (:a :href "/hhub/add%entity-name%" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create %entity-name%"))
				   (:div :class "col-xs-6" :align "right" 
					 (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
			     (:hr)
			     (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
	  (widget3 (function (lambda ()
		     (submitformevent-js "#%entity-name%livesearchresult")))))
      (list widget1 widget2 widget3))))

(defun create-widgets-for-update%entity-name% (modelfunc)
:description "This is a widgets function for update %entity-name% entity"      
  (funcall #'create-widgets-for-genericredirect modelfunc))






(defmethod RenderListViewHTML ((htmlview %entity-name%HTMLView) viewmodellist)
  :description "This is a HTML View rendering function for %entity-name% entities, which will display each %entity-name% entity in a row"
  (when viewmodellist
    (display-as-table (list "%0%" "%1%" "%2%" "%3%" "%4%" "%5%" "%6%" "%7%" "%8%" "%9%" "%10%" "%11%" "%12%" "%13%" "%14%" "%15%" "%16%" "%17%" "%18%" "%19%" "%20%" "%21%" "%22%" "%23%" "%24%" "%25%" "%26%" "%27%" "%28%" "%29%" "%30%" "%31%" "%32%" "%33%" "%34%" "%35%" "%36%" "%37%") viewmodellist 'display-%entity-name%-row)))

(defun create-model-for-search%entity-name% ()
  :description "This is a model function for search %entity-name% entities/entity" 
  (let* ((search-clause (hunchentoot:parameter "%entity-name%livesearch"))
	 (company (get-login-company))
	 (presenterobj (make-instance '%entity-name%Presenter))
	 (requestmodelobj (make-instance '%entity-name%SearchRequestModel
						 :field1 search-clause
						 :company company))
	 (adapterobj (make-instance '%entity-name%Adapter))
	 (domainobjlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj domainobjlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance '%entity-name%HTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-search-%entity-name%-action" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))



(defun com-hhub-transaction-search-%entity-name%-action ()
  :description "This is a MVC function to search action for %entity-name% entities/entity" 
  (let* ((modelfunc (funcall #'create-model-for-search%entity-name%))
	 (widgets (funcall #'create-widgets-for-search%entity-name% modelfunc)))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (loop for widget in widgets do
	(cl-who:str (funcall widget))))))

(defun create-model-for-update%entity-name% ()
  :description "This is a model function for update %entity-name% entity"
  (let* ((%0% (hunchentoot:parameter "%0%"))
	 (%1% (hunchentoot:parameter "%1%"))
	 (%2% (hunchentoot:parameter "%2%"))
	 (%3% (hunchentoot:parameter "%3%"))
	 (%4% (hunchentoot:parameter "%4%"))
	 (%5% (hunchentoot:parameter "%5%"))
	 (%6% (hunchentoot:parameter "%6%"))
	 (%7% (hunchentoot:parameter "%7%"))
	 (%8% (hunchentoot:parameter "%8%"))
	 (%9% (hunchentoot:parameter "%9%"))
	 (%10% (hunchentoot:parameter "%10%"))
	 (%11% (hunchentoot:parameter "%11%"))
	 (%12% (hunchentoot:parameter "%12%"))
	 (%13% (hunchentoot:parameter "%13%"))
	 (%14% (hunchentoot:parameter "%14%"))
	 (%15% (hunchentoot:parameter "%15%"))
	 (%16% (hunchentoot:parameter "%16%"))
	 (%17% (hunchentoot:parameter "%17%"))
	 (%18% (hunchentoot:parameter "%18%"))
	 (%19% (hunchentoot:parameter "%19%"))
	 (%20% (hunchentoot:parameter "%20%"))
	 (%21% (hunchentoot:parameter "%21%"))
	 (%22% (hunchentoot:parameter "%22%"))
	 (%23% (hunchentoot:parameter "%23%"))
	 (%24% (hunchentoot:parameter "%24%"))
	 (%25% (hunchentoot:parameter "%25%"))
	 (%26% (hunchentoot:parameter "%26%"))
	 (%27% (hunchentoot:parameter "%27%"))
	 (%28% (hunchentoot:parameter "%28%"))
	 (%29% (hunchentoot:parameter "%29%"))
	 (%30% (hunchentoot:parameter "%30%"))
	 (%31% (hunchentoot:parameter "%31%"))
	 (%32% (hunchentoot:parameter "%32%"))
	 (%33% (hunchentoot:parameter "%33%"))
	 (%34% (hunchentoot:parameter "%34%"))
	 (%35% (hunchentoot:parameter "%35%"))
	 (%36% (hunchentoot:parameter "%36%"))
	 (%37% (hunchentoot:parameter "%37%"))
	 (floatfield1 (float (with-input-from-string (in (hunchentoot:parameter "floatfield1"))
		   (read in))))
	 (company (get-login-company)) ;; or get ABAC subject specific login company function. 
	 (requestmodel (make-instance '%entity-name%RequestModel
					 :%0% %0%
					 :%1% %1%
					 :%2% %2%
					 :%3% %3%
					 :%4% %4%
					 :%5% %5%
					 :%6% %6%
					 :%7% %7%
					 :%8% %8%
					 :%9% %9%
					 :%10% %10%
					 :%11% %11%
					 :%12% %12%
					 :%13% %13%
					 :%14% %14%
					 :%15% %15%
					 :%16% %16%
					 :%17% %17%
					 :%18% %18%
					 :%19% %19%
					 :%20% %20%
					 :%21% %21%
					 :%22% %22%
					 :%23% %23%
					 :%24% %24%
					 :%25% %25%
					 :%26% %26%
					 :%27% %27%
					 :%28% %28%
					 :%29% %29%
					 :%30% %30%
					 :%31% %31%
					 :%32% %32%
					 :%33% %33%
					 :%34% %34%
					 :%35% %35%
					 :%36% %36%
					 :%37% %37%
					 :company company))
	 (adapterobj (make-instance '%entity-name%Adapter))
	 (redirectlocation  "/hhub/%entity-name%")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-%entity-name%-action" params 
      (handler-case 
	  (let ((domainobj (ProcessUpdateRequest adapterobj requestmodel)))
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))


(defun create-model-for-create%entity-name% ()
  :description "This is a create model function for creating a %entity-name% entity"
  (let* ((%0% (hunchentoot:parameter "%0%"))
	 (%1% (hunchentoot:parameter "%1%"))
	 (%2% (hunchentoot:parameter "%2%"))
	 (%3% (hunchentoot:parameter "%3%"))
	 (%4% (hunchentoot:parameter "%4%"))
	 (%5% (hunchentoot:parameter "%5%"))
	 (%6% (hunchentoot:parameter "%6%"))
	 (%7% (hunchentoot:parameter "%7%"))
	 (%8% (hunchentoot:parameter "%8%"))
	 (%9% (hunchentoot:parameter "%9%"))
	 (%10% (hunchentoot:parameter "%10%"))
	 (%11% (hunchentoot:parameter "%11%"))
	 (%12% (hunchentoot:parameter "%12%"))
	 (%13% (hunchentoot:parameter "%13%"))
	 (%14% (hunchentoot:parameter "%14%"))
	 (%15% (hunchentoot:parameter "%15%"))
	 (%16% (hunchentoot:parameter "%16%"))
	 (%17% (hunchentoot:parameter "%17%"))
	 (%18% (hunchentoot:parameter "%18%"))
	 (%19% (hunchentoot:parameter "%19%"))
	 (%20% (hunchentoot:parameter "%20%"))
	 (%21% (hunchentoot:parameter "%21%"))
	 (%22% (hunchentoot:parameter "%22%"))
	 (%23% (hunchentoot:parameter "%23%"))
	 (%24% (hunchentoot:parameter "%24%"))
	 (%25% (hunchentoot:parameter "%25%"))
	 (%26% (hunchentoot:parameter "%26%"))
	 (%27% (hunchentoot:parameter "%27%"))
	 (%28% (hunchentoot:parameter "%28%"))
	 (%29% (hunchentoot:parameter "%29%"))
	 (%30% (hunchentoot:parameter "%30%"))
	 (%31% (hunchentoot:parameter "%31%"))
	 (%32% (hunchentoot:parameter "%32%"))
	 (%33% (hunchentoot:parameter "%33%"))
	 (%34% (hunchentoot:parameter "%34%"))
	 (%35% (hunchentoot:parameter "%35%"))
	 (%36% (hunchentoot:parameter "%36%"))
	 (%37% (hunchentoot:parameter "%37%"))
	 (floatfield1 (float (with-input-from-string (in (hunchentoot:parameter "floatfield1"))
		   (read in))))
	 (company (get-login-company)) ;; or get ABAC subject specific login company function. 
	 (requestmodel (make-instance '%entity-name%RequestModel
					 :%0% %0%
					 :%1% %1%
					 :%2% %2%
					 :%3% %3%
					 :%4% %4%
					 :%5% %5%
					 :%6% %6%
					 :%7% %7%
					 :%8% %8%
					 :%9% %9%
					 :%10% %10%
					 :%11% %11%
					 :%12% %12%
					 :%13% %13%
					 :%14% %14%
					 :%15% %15%
					 :%16% %16%
					 :%17% %17%
					 :%18% %18%
					 :%19% %19%
					 :%20% %20%
					 :%21% %21%
					 :%22% %22%
					 :%23% %23%
					 :%24% %24%
					 :%25% %25%
					 :%26% %26%
					 :%27% %27%
					 :%28% %28%
					 :%29% %29%
					 :%30% %30%
					 :%31% %31%
					 :%32% %32%
					 :%33% %33%
					 :%34% %34%
					 :%35% %35%
					 :%36% %36%
					 :%37% %37%
					 :company company))
	 (adapterobj (make-instance '%entity-name%Adapter))
	 (redirectlocation  "/hhub/%entity-name%")
	 (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-create-%entity-name%-action" params 
      (handler-case 
	  (let ((domainobj (ProcessCreateRequest adapterobj requestmodel)))
	    ;; Create the GST HSN Code object if not present. 
	    (function (lambda ()
	      (values redirectlocation domainobj))))
	(error (c)
	  (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))

(defun com-hhub-transaction-create-%entity-name%-dialog (&optional domainobj)
  :description "This function creates a dialog to create %entity-name% entity"
  (let* ((%0%  (if domainobj (slot-value domainobj '%0%)))
	 (%1%  (if domainobj (slot-value domainobj '%1%)))
	 (%2%  (if domainobj (slot-value domainobj '%2%)))
	 (%3%  (if domainobj (slot-value domainobj '%3%)))
	 (%4%  (if domainobj (slot-value domainobj '%4%)))
	 (%5%  (if domainobj (slot-value domainobj '%5%)))
	 (%6%  (if domainobj (slot-value domainobj '%6%)))
	 (%7%  (if domainobj (slot-value domainobj '%7%)))
	 (%8%  (if domainobj (slot-value domainobj '%8%)))
	 (%9%  (if domainobj (slot-value domainobj '%9%)))
	 (%10%  (if domainobj (slot-value domainobj '%10%)))
	 (%11%  (if domainobj (slot-value domainobj '%11%)))
	 (%12%  (if domainobj (slot-value domainobj '%12%)))
	 (%13%  (if domainobj (slot-value domainobj '%13%)))
	 (%14%  (if domainobj (slot-value domainobj '%14%)))
	 (%15%  (if domainobj (slot-value domainobj '%15%)))
	 (%16%  (if domainobj (slot-value domainobj '%16%)))
	 (%17%  (if domainobj (slot-value domainobj '%17%)))
	 (%18%  (if domainobj (slot-value domainobj '%18%)))
	 (%19%  (if domainobj (slot-value domainobj '%19%)))
	 (%20%  (if domainobj (slot-value domainobj '%20%)))
	 (%21%  (if domainobj (slot-value domainobj '%21%)))
	 (%22%  (if domainobj (slot-value domainobj '%22%)))
	 (%23%  (if domainobj (slot-value domainobj '%23%)))
	 (%24%  (if domainobj (slot-value domainobj '%24%)))
	 (%25%  (if domainobj (slot-value domainobj '%25%)))
	 (%26%  (if domainobj (slot-value domainobj '%26%)))
	 (%27%  (if domainobj (slot-value domainobj '%27%)))
	 (%28%  (if domainobj (slot-value domainobj '%28%)))
	 (%29%  (if domainobj (slot-value domainobj '%29%)))
	 (%30%  (if domainobj (slot-value domainobj '%30%)))
	 (%31%  (if domainobj (slot-value domainobj '%31%)))
	 (%32%  (if domainobj (slot-value domainobj '%32%)))
	 (%33%  (if domainobj (slot-value domainobj '%33%)))
	 (%34%  (if domainobj (slot-value domainobj '%34%)))
	 (%35%  (if domainobj (slot-value domainobj '%35%)))
	 (%36%  (if domainobj (slot-value domainobj '%36%)))
	 (%37%  (if domainobj (slot-value domainobj '%37%))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form (format nil "form-add%entity-name%~A" %0%)  (if domainobj "update%entity-name%action" "create%entity-name%action")
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (:div :class "form-group"
			  (:input :class "form-control" :name "%0%" :maxlength "20"  :value  %0% :placeholder "%entity-name% (max 20 characters) " :type "text" ))
		    (:div :class "form-group"
			  (:label :for "description")
			  (:textarea :class "form-control" :name "description"  :placeholder "Description ( max 500 characters) "  :rows "5" :onkeyup "countChar(this, 500)" (cl-who:str description)))
		    (:div :class "form-group" :id "charcount")
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %1% :placeholder "%1%"  :name "%1%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %2% :placeholder "%2%"  :name "%2%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %3% :placeholder "%3%"  :name "%3%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %4% :placeholder "%4%"  :name "%4%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %5% :placeholder "%5%"  :name "%5%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %6% :placeholder "%6%"  :name "%6%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %7% :placeholder "%7%"  :name "%7%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %8% :placeholder "%8%"  :name "%8%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %9% :placeholder "%9%"  :name "%9%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %10% :placeholder "%10%"  :name "%10%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %11% :placeholder "%11%"  :name "%11%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %12% :placeholder "%12%"  :name "%12%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %13% :placeholder "%13%"  :name "%13%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %14% :placeholder "%14%"  :name "%14%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %15% :placeholder "%15%"  :name "%15%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %16% :placeholder "%16%"  :name "%16%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %17% :placeholder "%17%"  :name "%17%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %18% :placeholder "%18%"  :name "%18%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %18% :placeholder "%18%"  :name "%18%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %19% :placeholder "%19%"  :name "%19%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %20% :placeholder "%20%"  :name "%20%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %21% :placeholder "%21%"  :name "%21%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %22% :placeholder "%22%"  :name "%22%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %23% :placeholder "%23%"  :name "%23%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %24% :placeholder "%24%"  :name "%24%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %25% :placeholder "%25%"  :name "%25%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %26% :placeholder "%26%"  :name "%26%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %27% :placeholder "%27%"  :name "%27%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %28% :placeholder "%28%"  :name "%28%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %29% :placeholder "%29%"  :name "%29%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %30% :placeholder "%30%"  :name "%30%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %31% :placeholder "%31%"  :name "%31%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %32% :placeholder "%32%"  :name "%32%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %31% :placeholder "%33%"  :name "%33%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %34% :placeholder "%34%"  :name "%34%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %35% :placeholder "%35%"  :name "%35%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %36% :placeholder "%36%"  :name "%36%" ))
		    (:div :class "form-group"
			  (:input :class "form-control" :type "text" :value %37% :placeholder "%37%"  :name "%37%" ))
		    
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))





(defun create-widgets-for-create%entity-name% (modelfunc)
  :description "This is a create widget function for %entity-name% entity"
  (funcall #'create-widgets-for-genericredirect modelfunc))




(defun create-widgets-for-search%entity-name% (modelfunc)
  :description "This is a widget function for search %entity-name% entities"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :class "row"
			     (:div :class"col-xs-6"
				   (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target "#edit%entity-name%-modal" "Add %entity-name%")
				   (modal-dialog "edit%entity-name%-modal" "Add/Edit %entity-name%" (com-hhub-transaction-create-%entity-name%-dialog)))
			     (:div :class "col-xs-6" :align "right" 
				   (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
		       (:hr)
		       (RenderListViewHTML htmlview viewallmodel))))))
      (list widget1))))



 
(defun display-%entity-name%-row (%entity-name%)
  :description "This function has HTML row code for %entity-name% entity row"
  (with-slots (%0% %1% %2% %3% %4% %5% %6% %7% %8% %9% %10% %11% %12% %13% %14% %15% %16% %17% %18% %19% %20% %21% %22% %23% %24% %25% %26% %27% %28% %29% %30% %31% %32% %33% %34% %35% %36% %37%) %entity-name% 
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "10px" (cl-who:str %0%))
      (:td  :height "10px" (cl-who:str %1%))
      (:td  :height "10px" (cl-who:str %2%))
      (:td  :height "10px" (cl-who:str %3%))
      (:td  :height "10px" (cl-who:str %4%))
      (:td  :height "10px" (cl-who:str %5%))
      (:td  :height "10px" (cl-who:str %6%))
      (:td  :height "10px" (cl-who:str %7%))
      (:td  :height "10px" (cl-who:str %8%))
      (:td  :height "10px" (cl-who:str %9%))
      (:td  :height "10px" (cl-who:str %10%))
      (:td  :height "10px" (cl-who:str %11%))
      (:td  :height "10px" (cl-who:str %12%))
      (:td  :height "10px" (cl-who:str %13%))
      (:td  :height "10px" (cl-who:str %14%))
      (:td  :height "10px" (cl-who:str %15%))
      (:td  :height "10px" (cl-who:str %16%))
      (:td  :height "10px" (cl-who:str %17%))
      (:td  :height "10px" (cl-who:str %18%))
      (:td  :height "10px" (cl-who:str %19%))
      (:td  :height "10px" (cl-who:str %20%))
      (:td  :height "10px" (cl-who:str %21%))
      (:td  :height "10px" (cl-who:str %22%))
      (:td  :height "10px" (cl-who:str %23%))
      (:td  :height "10px" (cl-who:str %24%))
      (:td  :height "10px" (cl-who:str %25%))
      (:td  :height "10px" (cl-who:str %26%))
      (:td  :height "10px" (cl-who:str %27%))
      (:td  :height "10px" (cl-who:str %28%))
      (:td  :height "10px" (cl-who:str %29%))
      (:td  :height "10px" (cl-who:str %30%))
      (:td  :height "10px" (cl-who:str %31%))
      (:td  :height "10px" (cl-who:str %32%))
      (:td  :height "10px" (cl-who:str %33%))
      (:td  :height "10px" (cl-who:str %34%))
      (:td  :height "10px" (cl-who:str %35%))
      (:td  :height "10px" (cl-who:str %36%))
      (:td  :height "10px" (cl-who:str %37%))
      (:td  :height "10px" 
	    (:button :type "button" :class "btn btn-primary" :data-toggle "modal" :data-target (format nil "#edit%entity-name%-modal~A" %0%) (:i :class "fa-solid fa-pencil"))
	    (modal-dialog-v2 (format nil "edit%entity-name%-modal~A" %0%) (cl-who:str (format nil "Add/Edit %entity-name% " )) (com-hhub-transaction-create-%entity-name%-dialog %entity-name%))
	    (modal-dialog (format nil "edit%entity-name%-modal~A" %0%) "Add/Edit %entity-name%" (com-hhub-transaction-create-%entity-name%-dialog %entity-name%))))))


(defun com-hhub-transaction-update-%entity-name%-action ()
  :description "This is the MVC function to update action for %entity-name% entity"
  (with-cust-session-check ;; delete if not needed. 
  (with-vend-session-check ;; delete if not needed. 
  (with-cad-session-check ;; delete if not needed. 
  (with-opr-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  #'create-model-for-update%entity-name% #'create-widgets-for-update%entity-name%)))
      (format nil "~A" url)))))))


(defun com-hhub-transaction-create-%entity-name%-action ()
  :description "This is a MVC function for create %entity-name% entity"
  (with-cust-session-check ;; delete if not needed. 
  (with-vend-session-check ;; delete if not needed. 
  (with-cad-session-check ;; delete if not needed. 
  (with-opr-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  #'create-model-for-create%entity-name% #'create-widgets-for-create%entity-name%)))
      (format nil "~A" url)))))))








