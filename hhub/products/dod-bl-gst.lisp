;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun select-hsn-codes-by-text (hsn-desc-like)
  (clsql:select 'dod-gst-hsn-codes :where 
		[and
		[= [:tenant-id] 1]
		[like [:hsn-description] (format NIL "%~a%"  hsn-desc-like)]]
		:caching *dod-database-caching* :flatp t))

(defun select-hsn-code-by-id (id)
(car (clsql:select 'dod-gst-hsn-codes :where 
		   [and 
		   [=  [:row-id] id]
		   [= [:tenant-id] 1]]
		     		      :caching *dod-database-caching* :flatp t)))

(defun select-matching-hsn-codes (hsn-code-like)
(clsql:select 'dod-gst-hsn-codes :where
	      [and 
	      [like  [:hsn-code] (format NIL "~a%"  hsn-code-like)]
	      [= [:tenant-id] 1]]
	      :limit 200
	      :caching *dod-database-caching* :flatp t))

(defun select-hsn-code-by-code (hsn-code )
(car (clsql:select 'dod-gst-hsn-codes :where
		   [and 
		   [=  [:hsn-code] hsn-code]
		   [= [:tenant-id] 1]]
				      :caching *dod-database-caching* :flatp t)))


(defun select-all-GSTHSNCodes ()
:documentation "This function stores all the currencies in a hashtable. The Key = country, Value = list of currency, code and symbol."
(clsql:select 'dod-gst-hsn-codes :where
	      [= [:tenant-id] 1]
				 :limit 200
				 :caching *dod-database-caching* :flatp t ))


(defun get-system-gst-hsn-codes ()
  (select-all-GSTHSNCodes))


(defun get-gstvalues-for-product (product)
  (let* ((hsncode (slot-value product 'hsn-code))
	 (adapter (make-instance 'GSTHSNCodesAdapter))
	 (requestmodel (make-instance 'GSTHSNCodesRequestModel
				      :hsncode hsncode
				      :company (product-company product)))
	 (gsthsncodeobj (processreadrequest adapter requestmodel))
	 (gstknowledge (bo-knowledge adapter)))
    (with-bo-knowledge-check gstknowledge
      (:T (list cgst sgst igst compcess))
      (:F (list 0.0 0.0 0.0 0.0))
      (:U (error 'hhub-unknown :errstring (format nil "Unknown error while fetching GST values for HSN code ~A." hsncode)))
      (:C (error 'hhub-contradiction :errstring (format nil "Contradiction while fetching GST values for HSN code ~A." hsncode))))))

;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.


(defmethod ProcessCreateRequest ((adapter GSTHSNCodesAdapter) (requestmodel GSTHSNCodesRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created GSTHSNCodes  object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'GSTHSNCodesService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod init ((dbas GSTHSNCodesDBService) (bo GSTHSNCodes))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'dod-gst-hsn-codes)))
    ;; Set specific fields of the DB object if you need to. 
    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the HSN codes  DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))


(defmethod doreadall ((service GSTHSNCodesService) (requestmodel GSTHSNCodesRequestModel))
  (let* ((comp (company requestmodel))
	 (readalllst (select-all-GSTHSNCodes)))
    ;; return back a list of GST HSN Codes response model
    (mapcar (lambda (object)
	      (let ((domainobj (make-instance 'GSTHSNCodes)))
		(setf (slot-value domainobj 'company) comp)
		(copyGSTHSNCodes-dbtodomain object domainobj))) readalllst)))

(defmethod doreadall ((service GSTHSNCodesService) (requestmodel GSTHSNCodesSearchRequestModel))
  (let* ((comp (company requestmodel))
	 (hsn-code-like (hsncode requestmodel))
	 (readalllst (select-matching-hsn-codes hsn-code-like)))
    ;; return back a list of GST HSN Codes response model
    (mapcar (lambda (dbobject)
	      (let ((domainobj (make-instance 'GSTHSNCodes)))
		(setf (slot-value domainobj 'company) comp)
		(copyGSTHSNCodes-dbtodomain dbobject domainobj))) readalllst)))

(defmethod doCreate ((service GSTHSNCodesService) (requestmodel GSTHSNCodesRequestModel))
  (let* ((GSTHSNCodesdbservice (make-instance 'GSTHSNCodesDBService))
	 (hsncode (hsncode requestmodel))
	 (hsncode4digit (hsncode4digit requestmodel))
	 (description (description requestmodel))
	 (cgst (cgst requestmodel))
	 (sgst (sgst requestmodel))
	 (igst (igst requestmodel))
	 (compcess (compcess requestmodel))
	 (comp (company requestmodel))
	 (domainobj (createGSTHSNCodesobject hsncode hsncode4digit description cgst sgst igst compcess comp)))
         ;; Initialize the DB Service
    (init GSTHSNCodesdbservice domainobj)
    (copy-businessobject-to-dbobject GSTHSNCodesdbservice)
    (db-save GSTHSNCodesdbservice)
    ;; Return the newly created warehouse domain object
    domainobj))


(defun createGSTHSNCodesobject (hsncode hsncode4digit hsndescription cgst sgst igst compcess company)
  (let* ((domainobj  (make-instance 'GSTHSNCodes 
				       :hsncode hsncode
				       :hsncode4digit hsncode4digit
				       :description hsndescription
				       :cgst cgst
				       :sgst sgst
				       :igst igst
				       :compcess compcess
				       :company company)))
				 
    domainobj))

(defmethod Copy-BusinessObject-To-DBObject ((dbas GSTHSNCodesDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyGSTHSNCodes-domaintodb domainobj dbobj))))

;; source = domain destination = db
(defun copyGSTHSNCodes-domaintodb (source destination)
  (let ((company (slot-value source 'company)))
    (with-slots (hsn-code hsn-code-4digit hsn-description cgst sgst igst comp-cess tenant-id) destination
      (setf hsn-code (slot-value source 'hsncode))
      (setf hsn-code-4digit (slot-value source 'hsncode4digit))
      (setf hsn-description (slot-value source 'description))
      (setf cgst (slot-value source 'cgst))
      (setf sgst (slot-value source 'sgst))
      (setf igst (slot-value source 'igst))
      (setf comp-cess (slot-value source 'compcess))
      (setf tenant-id (slot-value company 'row-id))
      destination)))


;; PROCESS UPDATE REQUEST  
(defmethod ProcessUpdateRequest ((adapter GSTHSNCodesAdapter) (requestmodel GSTHSNCodesRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'GSTHSNCodesService))
  ;; call the parent ProcessUpdate
  (call-next-method))

;; PROCESS READ ALL REQUEST.
(defmethod ProcessReadAllRequest ((adapter GSTHSNCodesAdapter) (requestmodel GSTHSNCodesRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'GSTHSNCodesService))
  (call-next-method))

(defmethod ProcessReadAllRequest ((adapter GSTHSNCodesAdapter) (requestmodel GSTHSNCodesSearchRequestModel))
  :description "Adapter service method to search HSN Codes"
  (setf (slot-value adapter 'businessservice) (find-class 'GSTHSNCodesService))
  (call-next-method))



(defmethod CreateViewModel ((presenter GSTHSNCodesPresenter) (responsemodel GSTHSNCodesResponseModel))
  (let ((viewmodel (make-instance 'GSTHSNCodesViewModel)))
    (with-slots (hsncode hsncode4digit description cgst sgst igst compcess company) responsemodel
      (setf (slot-value viewmodel 'hsncode) hsncode)
      (setf (slot-value viewmodel 'hsncode4digit) hsncode4digit)
      (setf (slot-value viewmodel 'description) description)
      (setf (slot-value viewmodel 'cgst) cgst)
      (setf (slot-value viewmodel 'sgst) sgst)
      (setf (slot-value viewmodel 'igst) igst)
      (setf (slot-value viewmodel 'compcess) compcess)
      (setf (slot-value viewmodel 'company) company))
    viewmodel))
  

(defmethod ProcessResponse ((adapter GSTHSNCodesAdapter) (busobj GSTHSNCodes))
  (let ((responsemodel (make-instance 'GSTHSNCodesResponseModel)))
    (createresponsemodel adapter busobj responsemodel)))

(defmethod ProcessResponseList ((adapter GSTHSNCodesAdapter) GSTHSNCodeslist)
  (mapcar (lambda (domainobj)
	    (let ((responsemodel (make-instance 'GSTHSNCodesResponseModel)))
	      (createresponsemodel adapter domainobj responsemodel))) GSTHSNCodeslist))

(defmethod CreateAllViewModel ((presenter GSTHSNCodesPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))


(defmethod CreateResponseModel ((adapter GSTHSNCodesAdapter) (source GSTHSNCodes) (destination GSTHSNCodesResponseModel))
  :description "source = GSTHSNCodes destination = GSTHSNCodesResponseModel"
  (with-slots (hsncode hsncode4digit description sgst cgst igst compcess company) destination  
    (setf hsncode (slot-value source 'hsncode))
    (setf hsncode4digit (slot-value source 'hsncode4digit))
    (setf description (slot-value source 'description))
    (setf sgst  (slot-value source 'sgst))
    (setf cgst (slot-value source 'cgst))
    (setf igst (slot-value source 'igst))
    (setf compcess (slot-value source 'compcess))
    (setf company (slot-value source 'company))
    destination))

(defmethod doupdate ((service GSTHSNCodesService) (requestmodel GSTHSNCodesRequestModel))
  (let* ((GSTHSNCodesdbservice (make-instance 'GSTHSNCodesDBService))
	 (hsncode (hsncode requestmodel))
	 (hsncode4digit (hsncode4digit requestmodel))
	 (description (description requestmodel))
	 (cgst (cgst requestmodel))
	 (sgst (sgst requestmodel))
	 (igst (igst requestmodel))
	 (compcess (compcess requestmodel))
	 (comp (company requestmodel))
	 (GSTHSNCodesdbobj (select-hsn-code-by-code hsncode))
	 (domainobj (make-instance 'GSTHSNCodes)))
    ;; FIELD UPDATE CODE STARTS HERE 
    (when GSTHSNCodesdbobj
      (setf (slot-value GSTHSNCodesdbobj 'hsn-code) hsncode)
      (setf (slot-value GSTHSNCodesdbobj 'hsn-code-4digit) hsncode4digit)
      (setf (slot-value GSTHSNCodesdbobj 'hsn-description) description)
      (setf (slot-value GSTHSNCodesdbobj 'cgst) cgst)
      (setf (slot-value GSTHSNCodesdbobj 'sgst) sgst)
      (setf (slot-value GSTHSNCodesdbobj 'igst) igst)
      (setf (slot-value GSTHSNCodesdbobj 'comp-cess) compcess)
      (setf (slot-value GSTHSNCodesdbobj 'company) comp))
 
    ;;  FIELD UPDATE CODE ENDS HERE. 
    
    (setf (slot-value GSTHSNCodesdbservice 'dbobject) GSTHSNCodesdbobj)
    (setf (slot-value GSTHSNCodesdbservice 'businessobject) domainobj)
    
    (setcompany GSTHSNCodesdbservice comp)
    (db-save GSTHSNCodesdbservice)
    ;; Return the newly created UPI domain object
    (copyGSTHSNCodes-dbtodomain GSTHSNCodesdbobj domainobj)))


;; PROCESS THE READ REQUEST
(defmethod ProcessReadRequest ((adapter GSTHSNCodesAdapter) (requestmodel GSTHSNCodesRequestModel))
  :description "Adapter service method to read a single GSTHSNCodes"
  (setf (slot-value adapter 'businessservice) (find-class 'GSTHSNCodesService))
  (call-next-method))

(defmethod doread ((service GSTHSNCodesService) (requestmodel GSTHSNCodesRequestModel))
  (let* ((comp (company requestmodel))
	 (code (hsncode requestmodel))
	 (dbGSTHSNCode-knowledge (with-db-call (select-hsn-code-by-code code)))
	 (GSTHSNCodesobj (make-instance 'GSTHSNCodes)))

    (setf (bo-knowledge service) dbGSTHSNCode-knowledge)
    ;; return back a Vpaymentmethod  response model
    (setf (slot-value GSTHSNCodesobj 'company) comp)
    (when (eq (bo-knowledge-truth dbGSTHSNCode-knowledge) :T)
      (let ((dbGSTHSNCode (bo-knowledge-payload dbGSTHSNCode-knowledge)))
	(copyGSTHSNCodes-dbtodomain dbGSTHSNCode GSTHSNCodesobj)))
    GSTHSNCodesobj))

(defun copyGSTHSNCodes-dbtodomain (source destination)
  (with-slots (row-id hsncode hsncode4digit description sgst cgst igst compcess company) destination
    (setf row-id (slot-value source 'row-id))
    (setf hsncode (slot-value source 'hsn-code))
    (setf hsncode4digit  (slot-value source 'hsn-code-4digit))
    (setf description (slot-value source 'hsn-description))
    (setf sgst (slot-value source 'sgst))
    (setf cgst (slot-value source 'cgst))
    (setf igst (slot-value source 'igst))
    (setf compcess (slot-value source 'comp-cess))
    destination))
