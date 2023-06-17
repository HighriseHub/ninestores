(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; HERE WE DEFINE ALL THE POLICIES FOR HIGHRISEHUB ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun com-hhub-policy-prodcatg-add-action (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag))
         (subscription-plan (slot-value company 'subscription-plan))
	 (maxcatgcount (com-hhub-attribute-company-maxprodcatgcount subscription-plan))
	 (currentcatgcount (com-hhub-attribute-vendor-currentprodcatgcount company))
	 (rolename (cdr (assoc "rolename" params :test 'equal))))
    (if (and
	 (equal rolename "COMPADMIN")
	 (equal suspend-flag "N")
	 (<= currentcatgcount maxcatgcount)) T NIL)))



(defun com-hhub-policy-vendor-order-setfulfilled (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (cond
        ((com-hhub-attribute-company-issuspended suspend-flag)
	   (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
	  (() T))))

	
	 
	

(defun com-hhub-policy-customer&vendor-create (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (company-name (slot-value company 'name))
	 (currvendorcount (length (select-vendors-for-company company)))
	 (currcustomercount (length (select-customers-for-company company)))
	 (maxcustomercount (com-hhub-attribute-company-maxcustomercount (subscription-plan company)))
	 (maxvendorcount (com-hhub-attribute-company-maxvendorcount (subscription-plan company)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    
    (when (<= (- maxvendorcount currvendorcount) 0 )
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. You have exceeded maximum numbers of vendors allowed to be created." company-name)))
    (when (<= (- maxcustomercount  currcustomercount) 0)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. You have exceeded maximum numbers of customer allowed to be created." company-name)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))))




(defun com-hhub-policy-vendor-add-product-action (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (company-name (slot-value company 'name))
	 (currproductcount (length (select-products-by-company company)))
	 (subscription-plan (slot-value company 'subscription-plan))
	 (maxproductcount (com-hhub-attribute-company-maxproductcount subscription-plan))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (<= (- maxproductcount currproductcount) 0)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. You have exceeded maximum number of Products allowed to be created." company-name)))  
    (when (com-hhub-attribute-company-issuspended suspend-flag)
	(error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))))

(defun com-hhub-policy-vendor-bulk-products-add (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (subscription-plan (slot-value company 'subscription-plan))
	 (bulkuploadp (com-hhub-attribute-company-prdbulkupload-enabled subscription-plan))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    bulkuploadp))


(defun com-hhub-policy-restore-account (&optional (params nil))
  :documentation "This policy governs the Account suspension"
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "SUPERADMIN")))


(defun com-hhub-policy-suspend-account (&optional (params nil))
  :documentation "This policy governs the Account suspension"
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "SUPERADMIN")))
						  

(defun com-hhub-policy-vendor-bulk-product-add (&optional  (params nil))
  :documentation "Vendor Add bulk products using CSV file. "
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag))
	 (subscription-plan (slot-value company 'subscription-plan)))
    (cond
      ((not (com-hhub-attribute-company-prdbulkupload-enabled subscription-plan))  
       ;; return false
       (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This feature is restricted." (slot-value company 'name))))
      ((com-hhub-attribute-company-issuspended suspend-flag)
       (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
      ((<  (cdr (assoc "prdcount" params :test 'equal)) (com-hhub-attribute-vendor-bulk-product-count)) T))))


(defun com-hhub-policy-cad-login-page (&optional (params nil))
:documentation "Company Administrator login page is open to all. This policy is dummy as the request is initiated by the Browser."
(let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))


(defun com-hhub-policy-cad-login-action (&optional (params nil))
  :documentation "Company Administrator login action is open to all. This policy is dummy as the request is initiated by the Browser."
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))

(defun com-hhub-policy-cad-logout (&optional (params nil) )
  :documentation "Company Administrator logout action is open to all. This policy is dummy as the request is initiated by the Browser."
(let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))


(defun com-hhub-policy-cad-product-approve-action (&optional (params nil) )
  :documentation "only a Company Administrator can Approve a product. "
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))



(defun com-hhub-policy-cad-product-reject-action (&optional ( params nil))
  :documentation "only a Company Administrator can Reject a product. "
 (com-hhub-policy-cad-product-approve-action params))

(defun com-hhub-policy-compadmin-home ( &optional (params nil))
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))

(defun com-hhub-policy-publish-account-exturl (&optional (params nil))
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))
  
(defun com-hhub-policy-compadmin-updatedetails-action (&optional (params nil))
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))


(defun com-hhub-policy-sadmin-profile (&optional  (params nil))
:documentation "Super Administrator Profile Policy"
(equal (cdr (assoc "username" params :test 'equal))  "superadmin"))

(defun com-hhub-policy-sadmin-login (&optional (params nil))
  :documentation "Super Administrator Login Policy"
  (equal (cdr (assoc "username" params :test 'equal))  "superadmin"))

(defun com-hhub-policy-cust-edit-order-item (&optional (params nil))
  (com-hhub-policy-create-order params))


(defun com-hhub-policy-create-order (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (cond  ;; Check whether the account is suspended. 
      ((com-hhub-attribute-company-issuspended suspend-flag)
       (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
      ((< (parse-time-string (current-time-string)) (parse-time-string (com-hhub-attribute-customer-order-cutoff-time))) T))))


(defun com-hhub-policy-sadmin-create-users-page (&optional (params nil))
  :documentation "Check whether role of the login user is SUPERADMIN or not" 
  (equal (cdr (assoc "username" params :test 'equal))  "superadmin"))

(defun com-hhub-policy-sadmin-home (&optional (params nil))
  :documentation "Check whether role of the login user is SUPERADMIN or not" 
  (values (equal (cdr (assoc "username" params :test 'equal))  "superadmin") nil))
   
	

(defun com-hhub-policy-create-company (&optional  (params nil))
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "SUPERADMIN")))


(defun com-hhub-policy-create-attribute (&optional (params nil))
  (equal (cdr (assoc "username" params :test 'equal))  "superadmin"))


(defun com-hhub-policy-create (&optional (params nil))
  (equal (cdr (assoc "username" params :test 'equal))  "superadmin"))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; END DEFINE POLICIES ;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun dod-controller-add-transaction-action ()
(with-opr-session-check 
  (let* ((company (get-login-company))
	 (id (hunchentoot:parameter "id"))
	 (transaction (get-bus-transaction id))
	 (transname (hunchentoot:parameter "transname"))
	 (transuri (hunchentoot:parameter "transuri"))
	 (transfunc (hunchentoot:parameter "transfunc"))
	 (transtype (hunchentoot:parameter "transtype")))
    (if transaction 
	(progn 
	  (setf (slot-value transaction 'name) (concatenate 'string *ABAC-TRANSACTION-NAME-PREFIX* transname))
	  (setf (slot-value transaction 'uri) transuri)
	  (setf (slot-value transaction 'trans-func) (concatenate 'string *ABAC-TRANSACTION-FUNC-PREFIX* transfunc))
	  (setf (slot-value transaction 'trans-type) transtype)
	  (update-bus-transaction transaction))
					;else
	(create-bus-transaction (concatenate 'string *ABAC-TRANSACTION-NAME-PREFIX* transname)  transuri  transtype (concatenate 'string *ABAC-TRANSACTION-FUNC-PREFIX* transfunc) company))
    (hunchentoot:redirect "/hhub/listbustrans"))))


(defun com-hhub-transaction-policy-create ()
  (with-opr-session-check
    (let ((params nil))
      (setf params (acons "username" (get-login-user-name) params))
      (setf params (acons "uri" (hunchentoot:request-uri*) params))
      (with-hhub-transaction "com-hhub-transaction-policy-create" params 
    (let* ((company (get-login-company))
	   (id (hunchentoot:parameter "id"))
	   (policy (select-auth-policy-by-id id)) 
	   (policyname (hunchentoot:parameter "policyname"))
	   (policydesc (hunchentoot:parameter "policydesc"))
	   (policyfunc (hunchentoot:parameter "policyfunc")))
      (if policy 
	  (progn 
	    (setf (slot-value policy 'name) (concatenate 'string *ABAC-POLICY-NAME-PREFIX*  policyname))
	    (setf (slot-value policy 'description) policydesc)
	    (setf (slot-value policy 'policy-func) (concatenate 'string *ABAC-POLICY-FUNC-PREFIX*  policyfunc))
	    (update-auth-policy policy))
	  ;else
					; This place is good for calling a higher order function or even a macro will do.
	  ; (with-hhub-bus-layer 'create-auth-policy (concatenate 'string *ABAC-POLICY-NAME-PREFIX*  policyname)  policydesc (concatenate 'string *ABAC-POLICY-FUNC-PREFIX*  policyfunc) company)
	   ; (hhub-bus-layer 'create-auth-policy (concatenate 'string *ABAC-POLICY-NAME-PREFIX*  policyname)  policydesc (concatenate 'string *ABAC-POLICY-FUNC-PREFIX*  policyfunc) company)
	  (create-auth-policy (concatenate 'string *ABAC-POLICY-NAME-PREFIX*  policyname)  policydesc (concatenate 'string *ABAC-POLICY-FUNC-PREFIX*  policyfunc) company))
      (hunchentoot:redirect "/hhub/dasabacsecurity"))))))



(defun com-hhub-transaction-create-attribute ()
  (with-opr-session-check
    (let ((params nil))
      (setf params (acons "username" (get-login-user-name) params))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (setf params (acons "busobj" "ATTRIBUTE" params))
      (setf params (acons "bussubj" "SUPERADMIN" params))

    (with-hhub-transaction "com-hhub-transaction-create-attribute" params
      (let* ((company (get-login-company))
	    (id (hunchentoot:parameter "id"))
	    (attribute (if id (select-auth-attr-by-id id)))
	    (attrtype (hunchentoot:parameter "attrtype"))
	    (attrname (hunchentoot:parameter "attrname"))
	    (attrdesc (hunchentoot:parameter "attrdesc"))
	    (attrfunc (hunchentoot:parameter "attrfunc")))
	(if attribute 
	    (progn 
	      (setf (slot-value attribute 'name) (concatenate 'string  *ABAC-ATTRIBUTE-NAME-PREFIX*  attrname))
	      (setf (slot-value attribute 'description ) attrdesc)
	      (setf (slot-value attribute 'attr-func ) (concatenate 'string *ABAC-ATTRIBUTE-FUNC-PREFIX*  attrfunc))
	      (setf (slot-value attribute 'attr-type) attrtype)
	      (update-auth-attr-lookup attribute))
	    ;else 
	(create-auth-attr-lookup (concatenate 'string  *ABAC-ATTRIBUTE-NAME-PREFIX* attrname)   attrdesc (concatenate 'string *ABAC-ATTRIBUTE-FUNC-PREFIX*  attrfunc)  attrtype company))
	(hunchentoot:redirect "/hhub/listattributes"))))))



(defun busobj-card (busobj-instance)
  (let ((name (slot-value busobj-instance 'name)))
	(cl-who:with-html-output (*standard-output* nil)
	  (:td :height "10px" 
	   (:h6 :class "busobj-name"  (cl-who:str (format nil " ~A" name)))))))

(defun bustrans-card (bustrans-instance)
  (let ((name (slot-value bustrans-instance 'name))
	(uri (slot-value bustrans-instance 'uri))
	(row-id (slot-value bustrans-instance 'row-id))
	(trans-func (slot-value bustrans-instance 'trans-func)))
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" 
	   (:h6 :class "bustrans-name"  (cl-who:str (format nil " ~A" name))))
      (:td :height "10px" 
	   (:h6 :class "bustrans-name"  (cl-who:str (format nil " ~A" uri))))
      (:td :height "10px" 
	   (:h6 :class "bustrans-name"  (cl-who:str (format nil "~A" trans-func))))
      (:td :height "10px" 
	   (:a  :data-toggle "modal" :data-target (format nil "#editbustrans-modal~A" row-id)  :href "#"  (:span :class "glyphicon glyphicon-pencil"))
	   (:a  :data-toggle "modal"  :data-target (format nil "#linkbustrans-modal~A" row-id)  :href "#"  (:span :class "glyphicon glyphicon-link"))
	   (modal-dialog (format nil "linkbustrans-modal~a" row-id) "Add/Edit Business Transaction" (link-bus-transaction-to-policy bustrans-instance))
	   (modal-dialog (format nil "editbustrans-modal~a" row-id) "Add/Edit Business Transaction" (new-transaction-html  bustrans-instance))))))

(defun attribute-card (attribute-instance)
  (let* ((name (slot-value attribute-instance 'name))
	 (description (slot-value attribute-instance 'description))
	 (attr-func (slot-value attribute-instance 'attr-func))
	 (row-id (slot-value attribute-instance 'row-id))
	 (attr-type (slot-value attribute-instance 'attr-type))
	 (copystr (parenscript:ps (copy-to-clipboard (parenscript:lisp attr-func)))))
    
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" 
	   (:h6 :class "attribute-name"  (cl-who:str name) ))
      (:td :height "10px" 
	 (:h6 :class "attribute-desc"  (cl-who:str description) ))
      (:td :height "10px" 
	   (:h6 :class "attribute-name"  (cl-who:str attr-func))
	   (:a :class "attribute-func"  :onclick copystr  :href "#" (:span :class "glyphicon glyphicon-copy")))
      (:td :height "10px" 
	 (:h6 :class "attribute-type" (cl-who:str  (format nil "~A"  attr-type))))
      (:td :height "10px" 
	   (:a  :data-toggle "modal" :data-target (format nil "#editattribute-modal~A" row-id)  :href "#"  (:span :class "glyphicon glyphicon-pencil"))
	   (modal-dialog (format nil "editattribute-modal~a" row-id) "Add/Edit Attribute" (com-hhub-transaction-create-attribute-dialog attribute-instance))))))


(defun policy-row (policy-instance)
  (let ((name (slot-value policy-instance 'name))
	(description (slot-value policy-instance 'description))
	(policy-func (slot-value policy-instance 'policy-func))
	(row-id (slot-value policy-instance 'row-id)))
    (cl-who:with-html-output (*standard-output* nil)
      
      (:td :height "10px" 
	   (:h6 :class "policy-name"  (cl-who:str name)))
      (:td :height "10px" 
	   (:h6 :class "policy-desc"  (cl-who:str description)))
      (:td :height "10px" 
	   (:h6 :class "policy-func-name"  (cl-who:str policy-func) ))
      (:td :height "10px" 
	   (:a  :data-toggle "modal" :data-target (format nil "#editpolicy-modal~A" row-id)  :href "#"  (:span :class "glyphicon glyphicon-pencil"))
	   (modal-dialog (format nil "editpolicy-modal~a" row-id) "Add/Edit Policy" (com-hhub-transaction-policy-create-dialog  policy-instance))))))

;; @@ deprecated : start using with-html-dropdown instead. 
(defun  attribute-type-dropdown (selectedkey)
  (let ((attrtype (make-hash-table)))
    (setf (gethash "OBJECT" attrtype) "Object Attribute")
    (setf (gethash "SUBJECT" attrtype) "Subject Attribute")
    (setf (gethash "ENVIRONMENT" attrtype) "Environment Attribute")
    (with-html-dropdown "attrtype" attrtype selectedkey)))


(defun transaction-type-dropdown (selectedkey) 
  (let ((transtypes (make-hash-table)))
    (setf (gethash "CREATE" transtypes) "Create")
    (setf (gethash "READ" transtypes) "Read")
    (setf (gethash "UPDATE" transtypes) "Update")
    (setf (gethash "DELETE" transtypes) "Delete")
    (with-html-dropdown "transtype" transtypes selectedkey)))
	
(defun business-objects-dropdown (&optional selectedkey)
  (let* ((bolist (select-bus-object-by-company (get-login-company)))
	(bonameslist (mapcar (lambda (item) 
			       (slot-value item 'name)) bolist))
	(bohash (make-hash-table)))
    (mapcar (lambda (key) (setf (gethash key bohash) key)) bonameslist)
    (with-html-dropdown "busobject" bohash  (if (not selectedkey) (car bonameslist) selectedkey))))

(defun  abac-subject-dropdown (&optional selectedkey)
  (let* ((abac-subject-list (select-abac-subject-by-company (get-login-company)))
	 (subjectnameslist (mapcar (lambda (item) 
				     (slot-value item 'name)) abac-subject-list ))
	 (subjecthash (make-hash-table)))
    (mapcar (lambda (key) (setf (gethash key subjecthash) key)) subjectnameslist)
    (with-html-dropdown "abacsubject" subjecthash  (if (not selectedkey) (car subjectnameslist) selectedkey))))


(defun link-bus-transaction-to-policy (&optional transaction)
  (let ((policy (if transaction (get-bus-tran-policy transaction))))
    
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row"
	    (:div :class "col-xs-12"
		  (if policy (cl-who:htm (:h4 (cl-who:str (format nil "Linked Policy Name: ~A" (slot-value policy 'name)))))
		      (cl-who:htm (:h4 (cl-who:str (format nil "No Policy Linked! Create a New Policy.")))))))
      (:hr)
      (:a :class "btn btn-primary" :role "button" :href (format nil "/hhub/transtopolicylinkpage?trans-id=~A" (slot-value transaction 'row-id)) " Link Policy/Change "))))

	

(defun dod-controller-trans-to-policy-link-page ()
  (let* ((trans-id (hunchentoot:parameter "trans-id"))
	 (transaction (get-bus-transaction trans-id))
	 (policy (get-bus-tran-policy transaction)))
  (with-standard-admin-page (:title "Link Transaction To Policy")  
    (:div :class "row" 
	  (:div :class "col-xs-12" 
		(:h4 (cl-who:str (format nil "Transaction:   ~A" (slot-value transaction 'name))))))
    (:div :class "row" 
	  (:div :class "col-xs-12" 
		(:h4 (cl-who:str (format nil "Currently linked policy:   ~A" (slot-value policy 'name))))))

    (with-html-search-form "dassearchpolicies" "Enter Policy Name..." 
      (:input :class "form-control" :name "trans-id" :type "hidden" :value trans-id))
    (:div :id "searchresult"))))

    

(defun dod-controller-policy-search-action ()
 (let* ((policysearch (hunchentoot:parameter "livesearch"))
	(trans-id (hunchentoot:parameter "trans-id"))
	(transaction (get-bus-transaction trans-id))
       (policies (select-auth-policy-by-name (format nil "%~A%" policysearch) (get-login-company))))
 (ui-list-policies-for-linking policies transaction)))
   


(defun ui-list-policies-for-linking (policy-list transaction)
  (let ((trans-id (slot-value transaction 'row-id)))

 (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
  (if policy-list 
      (cl-who:htm (:div :class "row-fluid"	  
	    (mapcar (lambda (pol)
		      (cl-who:htm (:form :method "POST" :action "transtopolicylinkaction" :id "transtopolicylinkform"  
			   (:div :class "col-sm-4 col-lg-3 col-md-4"
			    (:div :class "form-group"
			     (:input :class "form-control" :name "trans-id" :type "hidden" :value trans-id ))
			    (:div :class "form-group"
			     (:input :class "form-control" :name "policy-id" :type "hidden" :value (slot-value pol 'row-id) ))
			    
			    (:div :class "form-group"
				  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" (cl-who:str (format nil "~A" (slot-value pol 'name)))))))))  policy-list)))
					;else
      (cl-who:htm (:div :class "col-sm-12 col-md-12 col-lg-12"
		 (:h3 "No records found")))))))

(defun dod-controller-trans-to-policy-link-action ()
  (let* ((trans-id (hunchentoot:parameter "trans-id"))
	(transaction (get-bus-transaction trans-id))
	(policy-id (parse-integer (hunchentoot:parameter "policy-id"))))
    (setf (slot-value transaction 'auth-policy-id) policy-id)
    (update-bus-transaction transaction)
    (hunchentoot:redirect "/hhub/listbustrans")))

(defun new-transaction-html (&optional transaction)
  (let* ((id (if transaction (slot-value transaction 'row-id)))
	 (transname (if transaction (slot-value transaction 'name)))
	 (transuri (if transaction (slot-value transaction 'uri)))
	 (transtype (if transaction (slot-value transaction 'trans-type)))
	 (transfunc (if transaction (slot-value transaction 'trans-func))))
	
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :class "form-addtransaction" :role "form" :method "POST" :action "dasaddtransactionaction"
			 (if transaction (cl-who:htm (:input :class "form-control" :type "hidden" :value id :name "id")))
					;(if transbo (cl-who:htm (:input :class "form-control" :type "hidden" :value bo-id :name "bo-id")))
			 (:img :class "profile-img" :src "/img/logo.png" :alt "")
			 (:h1 :class "text-center login-title"  "Add/Edit Transaction")
			   (:div :class "form-group input-group"
			       (:span :class "input-group-addon" :id "transnameprefix" (cl-who:str *ABAC-TRANSACTION-NAME-PREFIX*) )
			       (:label :class "input-group"  :for "transname" "Name:")
			       (:input :class "form-control" :name "transname" :aria-describedby "transnameprefix" :maxlength "30"  :value (if transaction (subseq transname (length *ABAC-TRANSACTION-NAME-PREFIX*)))  :placeholder "Enter Transaction  Name ( max 30 characters) " :type "text" ))
			 (:div :class "form-group"
			       (:label :for "transuri" "URL")
			       (:input :class "form-control" :name "transuri" :aria-describedby "transuri" :maxlength "50" :value transuri :placeholder "Enter transaction URI" :type "text")
			       (:h6 "Note: If the URL is changed here, then this URL has to be updated in dod-ui-sys.lisp as well."))
			 (:div :class "form-group input-group"
			       (:span :class "input-group-addon" :id "transfuncprefix" (cl-who:str *ABAC-TRANSACTION-FUNC-PREFIX* ))
			       (:label :class "input-group"  :for "transfunc" "Function:")
			       (:input :class "form-control" :name "transfunc" :maxlength "30"  :value (if transaction (subseq transfunc (length *ABAC-TRANSACTION-FUNC-PREFIX*))) :placeholder "Declare Transaction Function Name ( max 100 characters) " :aria-describedby "transfuncprefix"  :type "text" )
			       (:h6 "Note: If function name is changed here, then this function must be renamed in the file as well."))
			 (:div :class "form-group input-group"
			       (:span :class "input-group-addon"  "Type") 
			       (transaction-type-dropdown transtype))
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))





(defun com-hhub-transaction-create-attribute-dialog (&optional attribute)
  (let* ((id (if attribute (slot-value attribute 'row-id)))
	 (attrname (if attribute (slot-value attribute 'name)))
	 (attrdesc (if attribute (slot-value attribute 'description)))
	 (attrtype (if attribute (slot-value attribute 'attr-type)))
	 (attrfunc (if attribute (slot-value attribute 'attr-func))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :class "form-addattribute" :role "form" :method "POST" :action "dasaddattribute"
			 (if attribute (cl-who:htm (:input :class "form-control" :type "hidden" :value id :name "id")))
			 (:img :class "profile-img" :src "/img/logo.png" :alt "")
			    (:h1 :class "text-center login-title"  "Add/Edit Attribute")
			    (:div :class "form-group input-group"
				  (:span :class "input-group-addon" :id "attrnameprefix" (cl-who:str *ABAC-ATTRIBUTE-NAME-PREFIX*)) 
				  (:input :class "form-control" :name "attrname" :id "attrname"  :aria-describedby "attrnameprefix" :maxlength "30"  :value (if attribute (subseq attrname (length *ABAC-ATTRIBUTE-NAME-PREFIX*))) :placeholder "Enter Attribute  Name ( max 30 characters) " :type "text" ))
			    (:div :class "form-group"
				  (:label :for "attrdesc")
				  (:textarea :class "form-control" :name "attrdesc"  :placeholder "Enter Attribute Description ( max 400 characters) "  :rows "5" :onkeyup "countChar(this, 200)" (cl-who:str attrdesc) ))
			    (:div :class "form-group" :id "charcount")
			    (:div :class "form-group input-group"
				  
				  (:span :class "input-group-addon" :id "attrfuncprefix" (cl-who:str *ABAC-ATTRIBUTE-FUNC-PREFIX*)) 
				  (:input :class "form-control" :name "attrfunc" :id "attrfunc"  :maxlength "30"  :value (if attribute (subseq attrfunc (length *ABAC-ATTRIBUTE-FUNC-PREFIX*))) :placeholder "Declare Attribute Function Name ( max 100 characters) " :aria-describedby "attrfuncprefix"  :type "text" ))
			    (:div :class "form-group"
				  (attribute-type-dropdown attrtype))
			    
			    (:div :class "form-group"
				  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))


(defun com-hhub-transaction-policy-create-dialog (&optional policy)
  (let* ((id (if policy (slot-value policy 'row-id)))
	 (policyname (if policy (slot-value policy 'name)))
	 (policydesc (if policy (slot-value policy 'description)))
	 (policyfunc (if policy (slot-value policy 'policy-func))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :class "form-addpolicy" :role "form" :method "POST" :action "dasaddpolicyaction"
			 (if policy (cl-who:htm (:input :class "form-control" :type "hidden" :value id :name "id")))
			 (:img :class "profile-img" :src "/img/logo.png" :alt "")
			 (:h1 :class "text-center login-title"  "Add/Edit Policy")
			 (:div :class "form-group input-group"
			       (:span :class "input-group-addon" :id "attrnameprefix" (cl-who:str *ABAC-POLICY-NAME-PREFIX*) ) 
			       (:input :class "form-control" :name "policyname" :aria-describedby "polnameprefix" :maxlength "30"  :value (if policy (subseq policyname (length *ABAC-POLICY-NAME-PREFIX*))) :placeholder "Enter Policy  Name ( max 30 characters) " :type "text" ))
			 (:div :class "form-group"
			       (:label :for "policydesc")
			       (:textarea :class "form-control" :name "policydesc"  :placeholder "Enter Policy Description ( max 400 characters) "  :rows "5" :onkeyup "countChar(this, 400)" (cl-who:str policydesc) ))
			 (:div :class "form-group" :id "charcount")
			 (:div :class "form-group input-group"
			       (:span :class "input-group-addon" :id "policyfuncprefix" (cl-who:str *ABAC-POLICY-FUNC-PREFIX*)) 
			       (:input :class "form-control" :name "policyfunc" :maxlength "30"  :value (if policy (subseq  policyfunc (length *ABAC-POLICY-FUNC-PREFIX*))) :placeholder "Declare Policy Function Name ( max 100 characters) " :aria-describedby "policyfuncprefix"  :type "text" ))
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))
