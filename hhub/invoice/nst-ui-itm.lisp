  ;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


(defun InvoiceItem-search-html ()
  :description "This will create a html search box widget"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
	  (:div :id "custom-search-input"
		(:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
		      (with-html-search-form "idsyssearchInvoiceItem" "syssearchInvoiceItem" "idInvoiceItemlivesearch" "InvoiceItemlivesearch" "searchInvoiceItemaction" "onkeyupsearchform1event();" "Search for an InvoiceItem"
			(submitsearchform1event-js "#idInvoiceItemlivesearch" "#InvoiceItemlivesearchresult")))))))

(defun com-hhub-transaction-show-InvoiceItem-page ()
  :description "This is a show list page for all the InvoiceItem entities"
  (with-vend-session-check ;; delete if not needed. 
    (with-mvc-ui-page "InvoiceItem" createmodelforshowInvoiceItem createwidgetsforshowInvoiceItem :role :vendor))) ;; keep only one role, delete reset. 

(defun createmodelforshowInvoiceItem ()
  :description "This is a model function which will create a model to show InvoiceItem entities"
  (let* ((company (get-login-company))
	 (username (get-login-user-name))
	 (presenterobj (make-instance 'InvoiceItemPresenter))
	 (requestmodelobj (make-instance 'InvoiceItemRequestModel
					 :company company))
	 (adapterobj (make-instance 'InvoiceItemAdapter))
	 (objlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj objlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'InvoiceItemHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-InvoiceItem-page" params 
      (function (lambda ()
	(values viewallmodel htmlview username))))))

(defun createwidgetsforshowInvoiceItem (modelfunc)
 :description "This is the view/widget function for show InvoiceItem entities" 
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-vendor-breadcrumb)
		       (InvoiceItem-search-html)
			 (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row
			 (:h4 "Showing records for InvoiceItem."))
		       (:div :id "InvoiceItemlivesearchresult" 
			     (:div :class "row"
				   (:div :class"col-xs-6"
					 (:a :href "/hhub/addcusttoinvoice" (:i :class "fa-solid fa-plus") "&nbsp;&nbsp;Create Invoice"))
				   (:div :class "col-xs-6" :align "right" 
					 (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
			     (:hr)
			     (cl-who:str (RenderListViewHTML htmlview viewallmodel)))))))
	  (widget3 (function (lambda ()
		     (submitformevent-js "#InvoiceItemlivesearchresult")))))
      (list widget1 widget2 widget3))))


(defun createwidgetsforupdateInvoiceItem (modelfunc)
:description "This is a widgets function for update InvoiceItem entity"      
  (createwidgetsforgenericredirect modelfunc))

(defmethod RenderListViewHTML ((htmlview InvoiceItemHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for InvoiceItem entities, which will display each InvoiceItem entity in a row"
  (when viewmodellist
    (display-as-table (list "InvoiceHeader" "prdid" "prddesc" "hsncode" "qty" "uom" "price" "discount" "taxablevalue" "cgstrate" "cgstamt" "sgstrate" "sgstamt" "igstrate" "igstamt" "totalitemval" "company" "fieldR" "fieldS") viewmodellist 'display-InvoiceItem-row)))

(defun createmodelforsearchInvoiceItem ()
  :description "This is a model function for search InvoiceItem entities/entity" 
  (let* ((search-clause (hunchentoot:parameter "InvoiceItemlivesearch"))
	 (company (get-login-company))
	 (presenterobj (make-instance 'InvoiceItemPresenter))
	 (requestmodelobj (make-instance 'InvoiceItemSearchRequestModel
						 :field1 search-clause
						 :company company))
	 (adapterobj (make-instance 'InvoiceItemAdapter))
	 (domainobjlst (processreadallrequest adapterobj requestmodelobj))
	 (responsemodellist (processresponselist adapterobj domainobjlst))
	 (viewallmodel (CreateAllViewModel presenterobj responsemodellist))
	 (htmlview (make-instance 'InvoiceItemHTMLView))
	 (params nil))

    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-search-InvoiceItem-action" params 
      (function (lambda ()
	(values viewallmodel htmlview))))))



(defun com-hhub-transaction-search-InvoiceItem-action ()
  :description "This is a MVC function to search action for InvoiceItem entities/entity" 
  (let* ((modelfunc (createmodelforsearchInvoiceItem))
	 (widgets (createwidgetsforsearchInvoiceItem modelfunc)))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (loop for widget in widgets do
	(cl-who:str (funcall widget))))))

(defun createmodelforupdateInvoiceItem ()
  :description "This is a model function for update InvoiceItem entity"
  (let* ((company (get-login-vendor-company))
	 (prd-id (parse-integer (hunchentoot:parameter "prd-id")))
	 (prdqty (parse-integer (hunchentoot:parameter "qty")))
	 (productlist (hhub-get-cached-vendor-products))
	 (product (search-item-in-list 'row-id prd-id productlist))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (price (float (with-input-from-string (in (hunchentoot:parameter "price"))
		   (read in))))
	 (discount (float (with-input-from-string (in (hunchentoot:parameter "discount"))
			    (read in))))
	 (taxablevalue (- (* prdqty price) (if discount (/ (* prdqty price discount) 100) 0.00)))
	 (hsncode (slot-value product 'hsn-code))
	 (gstvalues (get-gstvalues-for-product product))
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
	 (requestmodel (make-instance 'InvoiceItemRequestModel
					 :InvoiceHeader sessioninvheader
					 :prd-id prd-id
					 :qty prdqty
					 :price price
					 :hsncode hsncode
					 :discount discount
					 :taxablevalue taxablevalue
					 :cgstamt cgstamt
					 :sgstamt sgstamt
					 :igstamt igstamt
					 :totalitemval totalitemval
					 :status "CONFIRMED"
					 :company company))
	 (adapterobj (make-instance 'InvoiceItemAdapter))
	 (redirectlocation  (format nil "/hhub/vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey))
	 (params nil))
    (setf params (acons "company" company params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-update-invoiceitem-action" params 
     ;; (handler-case 
	  (let ((domainobj (if (> prdqty 0 ) (ProcessUpdateRequest adapterobj requestmodel))))
	    (function (lambda ()
	      (values redirectlocation domainobj)))))))
	;;(error (c)
	 ;;(error 'hhub-business-function-error :errstring (format t "got an exception ~A" c)))))))


(defun createmodelforcreateInvoiceItem ()
  :description "This is a create model function for creating a InvoiceItem entity"
  )

(defun edit-invoiceitem-dialog (domainobj sessioninvkey)
  :description "This function creates a dialog to create InvoiceItem entity"
  (let* ((prdid  (if domainobj (slot-value domainobj 'prd-id)))
	 (prddesc  (if domainobj (slot-value domainobj 'prddesc)))
	 (qty  (if domainobj (slot-value domainobj 'qty)))
	 (price  (if domainobj (slot-value domainobj 'price)))
	 (discount  (if domainobj (slot-value domainobj 'discount)))
	 (row-id (if domainobj (slot-value domainobj 'row-id)))
	 (form-name (format nil "form-editInvoiceItem~A" row-id))
	 (logopath (format nil "~A/img/logo.png" *siteurl*)))
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-div-row
	(with-html-div-col-12
	  (with-html-form form-name (if domainobj "updateInvoiceItemaction" "createInvoiceItemaction")
	    (:img :class "profile-img" :src logopath :alt "Logo")
	    (with-html-input-text-hidden "prd-id" prdid)
	    (with-html-input-text-hidden "row-id" row-id)
	    (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
	    (with-html-input-text-readonly "prddesc" "Product Description" "Product Description"  prddesc nil nil 0)
	    (with-html-input-number "qty" "Quantity" "Quantity" qty 1 100 T "Enter/Update Quantity" 1)
	    (with-html-input-text "price" "Price" "Price" price T "Enter/Update Price" 2)
	    (with-html-input-text "discount" "Discount%" "Discount%" discount T "Enter/Update Discount" 3)
	    (:div :class "form-group"
		  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))))


(defun delete-invoiceitem-dialog (domainobj sessioninvkey)
  :description "This function creates a dialog to create InvoiceItem entity"
  (let* ((prddesc  (if domainobj (slot-value domainobj 'prddesc)))
	 (qty  (if domainobj (slot-value domainobj 'qty)))
	 (row-id (if domainobj (slot-value domainobj 'row-id)))
	 (prdid  (if domainobj (slot-value domainobj 'prd-id))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form (format nil "form-addInvoiceItem~A" row-id) "deleteinvoiceitemaction"
		    (:img :class "profile-img" :src "/img/logo.png" :alt "")
		    (with-html-input-text-hidden "prd-id" prdid)
		    (with-html-input-text-hidden "row-id" row-id)
		    (with-html-input-text-hidden "sessioninvkey" sessioninvkey)
		    (with-html-input-text-readonly "prddesc" "Description" "Description" prddesc NIL "" 1)
		    (with-html-input-text-readonly "qty" "Quantity" "Quantity" qty NIL "" 2)
		    (:div :class "form-group"
			  (:button :class "btn btn-lg btn-danger btn-block" :type "submit" "DELETE INVOICE ITEM!"))))))))




(defun createwidgetsforcreateInvoiceItem (modelfunc)
  :description "This is a create widget function for InvoiceItem entity"
  (createwidgetsforgenericredirect modelfunc))




(defun createwidgetsforsearchInvoiceItem (modelfunc)
  :description "This is a widget function for search InvoiceItem entities"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:div :class "row"
			     (:div :class"col-xs-6"
				   (:button :type "button" :class "btn btn-primary" :data-bs-toggle "modal" :data-bs-target "#editInvoiceItem-modal" "Add InvoiceItem")
				   (modal-dialog-v2 "editInvoiceItem-modal" "Add/Edit InvoiceItem" (com-hhub-transaction-create-InvoiceItem-dialog)))
			     (:div :class "col-xs-6" :align "right" 
				   (:span :class "badge" (cl-who:str (format nil "~A" (length viewallmodel))))))
		       (:hr)
		       (RenderListViewHTML htmlview viewallmodel))))))
      (list widget1))))


(defmethod RenderListViewHTML ((htmlview InvoiceItemHTMLView) viewmodellist)
  :description "This is a HTML View rendering function for InvoiceHeader entities, which will display each InvoiceHeader entity in a row"
  (when viewmodellist
    (display-as-table (list "Product" "HSN Code" "UOM" "Qty" "Rate" "Amount" "Less:Discount" "Taxable Value" "CGST" "SGST" "IGST" "Total") viewmodellist 'display-InvoiceItem-row)))


(defun display-invoice-item-row (invitem invoicepaid-p sessioninvkey)
  (cl-who:with-html-output (*standard-output* nil)
    (with-slots (prd-id prddesc hsncode qty uom price discount  taxablevalue  cgstamt  sgstamt  igstamt totalitemval) invitem
      (cl-who:htm
       (:td :height "10px" (cl-who:str prddesc))
       (:td :height "10px" (cl-who:str hsncode))
       (:td :height "10px" (cl-who:str uom))
       (:td :height "10px" (cl-who:str qty))
       (:td :height "10px" (cl-who:str price))
       (:td :height "10px" (cl-who:str discount))
       (:td :height "10px" (cl-who:str taxablevalue))
       (:td :height "10px" (cl-who:str cgstamt))
       (:td :height "10px" (cl-who:str sgstamt))
       (:td :height "10px" (cl-who:str igstamt))
       (:td :height "10px" (cl-who:str totalitemval))
       (unless invoicepaid-p
	 (cl-who:htm
	  (:td :height "10px"
	       (:a :class "no-print" :data-bs-toggle "modal" :data-bs-target (format nil "#editInvoiceItem-modal~A" prd-id) (:i :class "fa-solid fa-pencil") "&nbsp;&nbsp;")
	       (modal-dialog-v2 (format nil "editInvoiceItem-modal~A" prd-id) "Add/Edit InvoiceItem" (edit-invoiceitem-dialog invitem sessioninvkey))
	       (:a :class "no-print" :data-bs-toggle "modal" :data-bs-target (format nil "#deleteInvoiceItem-modal~A" prd-id) (:i :class "fa-solid fa-trash-can"))
	       (modal-dialog-v2 (format nil "deleteInvoiceItem-modal~A" prd-id) "Delete InvoiceItem" (delete-invoiceitem-dialog invitem sessioninvkey)))))))))

(defun display-invoice-item-row-public (invitem)
  (cl-who:with-html-output (*standard-output* nil)
    (with-slots (prd-id prddesc hsncode qty uom price discount  taxablevalue  cgstamt  sgstamt  igstamt totalitemval) invitem
      (cl-who:htm
       (:td :height "10px" (cl-who:str prddesc))
       (:td :height "10px" (cl-who:str hsncode))
       (:td :height "10px" (cl-who:str uom))
       (:td :height "10px" (cl-who:str qty))
       (:td :height "10px" (cl-who:str price))
       (:td :height "10px" (cl-who:str discount))
       (:td :height "10px" (cl-who:str taxablevalue))
       (:td :height "10px" (cl-who:str cgstamt))
       (:td :height "10px" (cl-who:str sgstamt))
       (:td :height "10px" (cl-who:str igstamt))
       (:td :height "10px" (cl-who:str totalitemval))))))


(defun invoicetemplatefillitemrows (sessioninvitems invoicepaid-p sessioninvkey)
  (function (lambda ()
    (cl-who:with-html-output-to-string (*standard-output* nil)
	(let ((incr (let ((count 0)) (lambda () (incf count)))))
	  (mapcar (lambda (item) (cl-who:htm (:tr (:td (cl-who:str (funcall incr))) (display-invoice-item-row item invoicepaid-p sessioninvkey))))  sessioninvitems))))))

(defun invoicetemplatefillitemrowspublic (sessioninvitems)
  (function (lambda ()
    (cl-who:with-html-output-to-string (*standard-output* nil)
	(let ((incr (let ((count 0)) (lambda () (incf count)))))
	  (mapcar (lambda (item) (cl-who:htm (:tr (:td (cl-who:str (funcall incr))) (display-invoice-item-row-public item))))  sessioninvitems))))))


(defun com-hhub-transaction-update-invoiceitem-action ()
  :description "This is the MVC function to update action for InvoiceItem entity"
  (with-vend-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  createmodelforupdateInvoiceItem createwidgetsforupdateInvoiceItem)))
      (format nil "~A" url))))


(defun com-hhub-transaction-create-InvoiceItem-action ()
  :description "This is a MVC function for create InvoiceItem entity"
  (with-vend-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  createmodelforcreateInvoiceItem createwidgetsforcreateInvoiceItem)))
      (format nil "~A" url))))



;;;;;;;;;;;;;;;;;;;;;;;;;DELETE INVOICE ITEM ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun com-hhub-transaction-delete-invoiceitem-action ()
  :description "This is a MVC function for delete InvoiceItem entity"
  (with-vend-session-check ;; delete if not needed. 
    (let ((url (with-mvc-redirect-ui  createmodelfordeleteinvoiceitem createwidgetsfordeleteinvoiceitem)))
      (format nil "~A" url))))

(defun createmodelfordeleteinvoiceitem ()
  (let* ((company (get-login-vendor-company))
	 (prd-id (parse-integer (hunchentoot:parameter "prd-id")))
	 (productlist (hhub-get-cached-vendor-products))
	 (product (search-item-in-list 'row-id prd-id productlist))
	 (sessioninvkey (hunchentoot:parameter "sessioninvkey"))
	 (sessioninvoices-ht (hunchentoot:session-value :session-invoices-ht))
	 (sessioninvoice (gethash sessioninvkey sessioninvoices-ht))
	 (sessioninvheader (slot-value sessioninvoice 'InvoiceHeader))
	 (sessioninvitems (slot-value sessioninvoice 'InvoiceItems))
	 (sessioninvproducts (slot-value sessioninvoice 'InvoiceProducts))
	 (requestmodel (make-instance 'InvoiceItemRequestModel
					 :InvoiceHeader sessioninvheader
					 :prd-id prd-id
					 :company company))
	 (adapterobj (make-instance 'InvoiceItemAdapter))
	 (redirectlocation  (format nil "/hhub/vshowinvoiceconfirmpage?sessioninvkey=~A" sessioninvkey))
	 (params nil))
    (setf params (acons "company" company params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-delete-invoiceitem-action" params 
      ;;(handler-case
      ;;(handler-case 
	  (let ((domainobj (ProcessDeleteRequest adapterobj requestmodel)))
	    (setf (slot-value sessioninvoice 'InvoiceItems) (delete domainobj sessioninvitems))
	    (setf (slot-value sessioninvoice 'invoiceproducts) (delete product sessioninvproducts))
	    (setf (gethash sessioninvkey sessioninvoices-ht) sessioninvoice)
     	    (function (lambda ()
	      (values redirectlocation domainobj)))))))
	;;(error (c)
	;; (error 'hhub-business-function-error :errstring (format t "~A:got an exception ~A" (mysql-now)  c)))))))
  

(defun createwidgetsfordeleteinvoiceitem (modelfunc)
  (createwidgetsforgenericredirect modelfunc))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
