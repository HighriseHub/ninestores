;; -*- mode: common-lisp; coding: utf-8 -*-%
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(defun search-invoice-header-by-invnum (invnum-like company)
  (let* ((tenant-id (slot-value company 'row-id)))
    (clsql:select 'dod-invoice-header :where 
		  [and
		  [= [:tenant-id] tenant-id]
		  [like [:invnum] (format NIL "%~a%"  invnum-like)]]
	       :caching *dod-database-caching* :flatp t)))

(defun select-invoice-header-by-invnum (invnum company)
  (let* ((tenant-id (slot-value company 'row-id)))
    (car (clsql:select 'dod-invoice-header :where
		       [and 
		       [=  [:invnum] invnum]
		       [= [:tenant-id] tenant-id]]
					   :caching *dod-database-caching* :flatp t))))

(defun select-invoice-header-by-context-id (context-id company)
  (let* ((tenant-id (slot-value company 'row-id)))
    (car (clsql:select 'dod-invoice-header :where
		       [and 
		       [=  [:context-id] context-id]
		       [= [:tenant-id] tenant-id]]
					  :caching *dod-database-caching* :flatp t))))

(defun select-all-invoice-headers (company)
  :documentation "This function stores all the currencies in a hashtable. The Key = country, Value = list of currency, code and symbol."
  (let* ((tenant-id (slot-value company 'row-id))
	 (invheaders (clsql:select 'dod-invoice-header :where
				 [= [:tenant-id] tenant-id]
				 :limit 200
				 :caching *dod-database-caching* :flatp t )))
    invheaders))


;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.
;; DO NOT COMPILE THIS FILE USING CTRL + C CTRL + K (OR CTRL + CK)
;; DO NOT ADD THIS FILE TO COMPILE.LISP FOR MASS COMPILATION. 


(defmethod ProcessCreateRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Warehouse object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod init ((dbas InvoiceHeaderDBService) (bo InvoiceHeader))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'dod-invoice-header)))
    ;; Set specific fields of the DB object if you need to. 
    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))



(defmethod doCreate ((service InvoiceHeaderService) (requestmodel InvoiceHeaderRequestModel))
  (let* ((InvoiceHeaderdbservice (make-instance 'InvoiceHeaderDBService))
	 (context-id (context-id requestmodel))
	 (vendor (vendor requestmodel))
	 (company (company requestmodel))
	 (customer (customer requestmodel))
	 (invnum (invnum requestmodel))
	 (invdate (invdate requestmodel))
	 (custaddr (custaddr requestmodel))
	 (custgstin (custgstin requestmodel))
	 (statecode (statecode requestmodel))
	 (billaddr (billaddr requestmodel))
	 (shipaddr (shipaddr requestmodel))
	 (placeofsupply (placeofsupply requestmodel))
	 (revcharge (revcharge requestmodel))
	 (transmode (transmode requestmodel))
	 (vnum (vnum requestmodel))
	 (totalvalue (totalvalue requestmodel))
	 (totalinwords (totalinwords requestmodel))
	 (bankaccnum (bankaccnum requestmodel))
	 (bankifsccode (bankifsccode requestmodel))
	 (tnc (tnc requestmodel))
	 (authsign (authsign requestmodel))
	 (finyear (finyear requestmodel))
	 (domainobj (createInvoiceHeaderobject context-id invnum invdate customer custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear vendor company)))
         ;; Initialize the DB Service
    (init InvoiceHeaderdbservice domainobj)
    (copy-businessobject-to-dbobject InvoiceHeaderdbservice)
    (db-save InvoiceHeaderdbservice)
    ;; Return the newly created warehouse domain object
    domainobj))


(defun createInvoiceHeaderobject (context-id invnum invdate customer custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear vendor company)
  (let* ((domainobj  (make-instance 'InvoiceHeader 
				    :context-id context-id
				    :invnum invnum
				    :invdate invdate
				    :custaddr custaddr
				    :custgstin custgstin
				    :statecode statecode
				    :billaddr billaddr
				    :shipaddr shipaddr
				    :placeofsupply placeofsupply
				    :revcharge revcharge 
				    :transmode transmode
				    :vnum vnum
				    :totalvalue totalvalue
				    :totalinwords totalinwords
				    :bankaccnum bankaccnum
				    :bankifsccode bankifsccode
				    :tnc tnc
				    :authsign authsign
				    :finyear finyear
				    :external-url ""
				    :vendor vendor
				    :customer customer
				    :status "DRAFT"
				    :company company)))
    domainobj))

(defmethod Copy-BusinessObject-To-DBObject ((dbas InvoiceHeaderDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyInvoiceHeader-domaintodb domainobj dbobj))))

;; source = domain destination = db
(defun copyInvoiceHeader-domaintodb (source destination) 
  (let ((vendor (slot-value source 'vendor))
	(customer (slot-value source 'customer))
	(company (slot-value source 'company)))
    (with-slots (context-id invdate custname custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear external-url status deleted-state  custid vendor-id tenant-id) destination
      (setf context-id (slot-value source 'context-id))
      (setf vendor-id (slot-value vendor 'row-id))
      (setf tenant-id (slot-value company 'row-id))
      (setf custid (slot-value customer 'row-id))
      (setf invdate (slot-value source 'invdate))
      (setf custname (slot-value customer 'name))
      (setf custaddr (slot-value source 'custaddr))
      (setf custgstin (slot-value source 'custgstin))
      (setf statecode (slot-value source 'statecode))
      (setf billaddr (slot-value source 'billaddr))
      (setf shipaddr (slot-value source 'shipaddr))
      (setf placeofsupply (slot-value source 'placeofsupply))
      (setf revcharge (slot-value source 'revcharge))
      (setf transmode (slot-value source 'transmode))
      (setf vnum (slot-value source 'vnum))
      (setf totalvalue (slot-value source 'totalvalue))
      (setf totalinwords (slot-value source 'totalinwords))
      (setf bankaccnum (slot-value source 'bankaccnum))
      (setf bankifsccode (slot-value source 'bankifsccode))
      (setf tnc (slot-value source 'tnc))
      (setf authsign (slot-value source 'authsign))
      (setf finyear (slot-value source 'finyear))
      (setf external-url (slot-value source 'external-url))
      (setf status (slot-value source 'status))
      (setf deleted-state "N")
      destination)))


;; PROCESS UPDATE REQUEST  
(defmethod ProcessUpdateRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  ;; call the parent ProcessUpdate
  (logiamhere "I am in processupdaterequest for InvoiceHeaderRequestModel")
  (call-next-method))

(defmethod ProcessUpdateRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderStatusRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  ;; call the parent ProcessUpdate
  (logiamhere "I am in processupdaterequest for InvoiceHeaderStatusRequestModel")
  (call-next-method))

;; PROCESS READ ALL REQUEST.
(defmethod ProcessReadAllRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  (call-next-method))

(defmethod ProcessReadAllRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderSearchRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  (call-next-method))




(defmethod doreadall ((service InvoiceHeaderService) (requestmodel InvoiceHeaderRequestModel))
  (let* ((comp (company requestmodel))
	 (domainobjlst (select-all-invoice-headers comp)))
    ;; return back a list of domain objects 
    (mapcar (lambda (object)
	      (let ((domainobject (make-instance 'InvoiceHeader)))
		(copyInvoiceHeader-dbtodomain object domainobject))) domainobjlst)))

(defmethod doreadall ((service InvoiceHeaderService) (requestmodel InvoiceHeaderSearchRequestModel))
  (let* ((comp (company requestmodel))
	 (invnum (invnum requestmodel))
	 (domainobjlst (search-invoice-header-by-invnum invnum comp)))
    ;; return back a list of domain objects 
    (mapcar (lambda (object)
	      (let ((domainobject (make-instance 'InvoiceHeader)))
		(copyInvoiceHeader-dbtodomain object domainobject))) domainobjlst)))


(defmethod CreateViewModel ((presenter InvoiceHeaderPresenter) (responsemodel InvoiceHeaderResponseModel))
  (let ((viewmodel (make-instance 'InvoiceHeaderViewModel)))
    (with-slots (invnum invdate  custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear status vendor customer company) responsemodel
      (setf (slot-value viewmodel 'vendor) vendor)
      (setf (slot-value viewmodel 'customer) customer)
      (setf (slot-value viewmodel 'invnum) invnum)
      (setf (slot-value viewmodel 'invdate) invdate)
      (setf (slot-value viewmodel 'custaddr) custaddr)
      (setf (slot-value viewmodel 'custgstin) custgstin)
      (setf (slot-value viewmodel 'statecode) statecode)
      (setf (slot-value viewmodel 'billaddr) billaddr)
      (setf (slot-value viewmodel 'shipaddr) shipaddr)
      (setf (slot-value viewmodel 'placeofsupply) placeofsupply)
      (setf (slot-value viewmodel 'revcharge) revcharge)
      (setf (slot-value viewmodel 'transmode) transmode)
      (setf (slot-value viewmodel 'vnum) vnum)
      (setf (slot-value viewmodel 'totalvalue) totalvalue)
      (setf (slot-value viewmodel 'totalinwords) totalinwords)
      (setf (slot-value viewmodel 'bankaccnum) bankaccnum)
      (setf (slot-value viewmodel 'bankifsccode) bankifsccode)
      (setf (slot-value viewmodel 'tnc) tnc)
      (setf (slot-value viewmodel 'authsign) authsign)
      (setf (slot-value viewmodel 'finyear) finyear)
      (setf (slot-value viewmodel 'status) status)
      (setf (slot-value viewmodel 'company) company)
      (setf (slot-value viewmodel 'vendor) vendor)
      viewmodel)))
  

(defmethod ProcessResponse ((adapter InvoiceHeaderAdapter) (busobj InvoiceHeader))
  (let ((responsemodel (make-instance 'InvoiceHeaderResponseModel)))
    (createresponsemodel adapter busobj responsemodel)))

(defmethod ProcessResponseList ((adapter InvoiceHeaderAdapter) InvoiceHeaderlist)
  (mapcar (lambda (domainobj)
	    (let ((responsemodel (make-instance 'InvoiceHeaderResponseModel)))
	      (createresponsemodel adapter domainobj responsemodel))) InvoiceHeaderlist))

(defmethod CreateAllViewModel ((presenter InvoiceHeaderPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))


(defmethod CreateResponseModel ((adapter InvoiceHeaderAdapter) (source InvoiceHeader) (destination InvoiceHeaderResponseModel))
  :description "source = InvoiceHeader destination = InvoiceHeaderResponseModel"
  (with-slots (invnum invdate  custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear status vendor customer company created) destination  
    (setf invnum (slot-value source 'invnum))
    (setf invdate (slot-value source 'invdate))
    (setf custaddr (slot-value source 'custaddr))
    (setf custgstin (slot-value source 'custgstin))
    (setf statecode (slot-value source 'statecode))
    (setf billaddr (slot-value source 'billaddr))
    (setf shipaddr (slot-value source 'shipaddr))
    (setf placeofsupply (slot-value source 'placeofsupply))
    (setf revcharge (slot-value source 'revcharge))
    (setf transmode (slot-value source 'transmode))
    (setf vnum (slot-value source 'vnum))
    (setf totalvalue (slot-value source 'totalvalue))
    (setf totalinwords (slot-value source 'totalinwords))
    (setf bankaccnum (slot-value source 'bankaccnum))
    (setf bankifsccode (slot-value source 'bankifsccode))
    (setf tnc (slot-value source 'tnc))
    (setf authsign (slot-value source 'authsign))
    (setf finyear (slot-value source 'finyear))
    (setf status (slot-value source 'status))
    (setf vendor (slot-value source  'vendor))
    (setf customer (slot-value source 'customer))
    (setf company (slot-value source 'company))
    destination))



(defmethod doupdate ((service InvoiceHeaderService) (requestmodel InvoiceHeaderRequestModel))
  (let* ((InvoiceHeaderdbservice (make-instance 'InvoiceHeaderDBService))
	 (invnum (invnum requestmodel))
	 (invdate (invdate requestmodel))
	 (custaddr (custaddr requestmodel))
	 (custgstin (custgstin requestmodel))
	 (statecode (statecode requestmodel))
	 (billaddr (billaddr requestmodel))
	 (shipaddr (shipaddr requestmodel))
	 (placeofsupply (placeofsupply requestmodel))
	 (revcharge (revcharge requestmodel))
	 (transmode (transmode requestmodel))
	 (vnum (vnum requestmodel))
	 (totalvalue (totalvalue requestmodel))
	 (totalinwords (totalinwords requestmodel))
	 (bankaccnum (bankaccnum requestmodel))
	 (bankifsccode (bankifsccode requestmodel))
	 (tnc (tnc requestmodel))
	 (authsign (authsign requestmodel))
	 (customer (customer requestmodel))
	 (custid (slot-value customer 'row-id))
	 (vendor (vendor requestmodel))
	 (vendor-id (slot-value vendor 'row-id))
	 (comp (company requestmodel))
	 (tenant-id (slot-value comp 'row-id))
	 (finyear (finyear requestmodel))
	 (external-url (external-url requestmodel))
	 (status (status requestmodel))
	 (InvoiceHeaderdbobj (select-invoice-header-by-invnum invnum comp))
	 (domainobj (make-instance 'InvoiceHeader)))
	 
    

    ;; FIELD UPDATE CODE STARTS HERE 
    (when InvoiceHeaderdbobj
      (setf (slot-value InvoiceHeaderdbobj 'invnum) invnum)
      (setf (slot-value InvoiceHeaderdbobj 'invdate) invdate)
      (setf (slot-value InvoiceHeaderdbobj 'custaddr) custaddr)
      (setf (slot-value InvoiceHeaderdbobj 'custgstin) custgstin)
      (setf (slot-value InvoiceHeaderdbobj 'statecode) statecode)
      (setf (slot-value InvoiceHeaderdbobj 'billaddr) billaddr)
      (setf (slot-value InvoiceHeaderdbobj 'shipaddr) shipaddr)
      (setf (slot-value InvoiceHeaderdbobj 'placeofsupply) placeofsupply)
      (setf (slot-value InvoiceHeaderdbobj 'revcharge) revcharge)
      (setf (slot-value InvoiceHeaderdbobj 'transmode) transmode)
      (setf (slot-value InvoiceHeaderdbobj 'vnum) vnum)
      (setf (slot-value InvoiceHeaderdbobj 'totalvalue) totalvalue)
      (setf (slot-value InvoiceHeaderdbobj 'totalinwords) totalinwords)
      (setf (slot-value InvoiceHeaderdbobj 'bankaccnum) bankaccnum)
      (setf (slot-value InvoiceHeaderdbobj 'bankifsccode) bankifsccode)
      (setf (slot-value InvoiceHeaderdbobj 'tnc) tnc)
      (setf (slot-value InvoiceHeaderdbobj 'authsign) authsign)
      (setf (slot-value InvoiceHeaderdbobj 'custid) custid)
      (setf (slot-value InvoiceHeaderdbobj 'vendor-id) vendor-id)
      (setf (slot-value InvoiceHeaderdbobj 'tenant-id) tenant-id)
      (setf (slot-value InvoiceHeaderdbobj 'finyear) finyear)
      (setf (slot-value InvoiceHeaderdbobj 'external-url) external-url)
      (setf (slot-value InvoiceHeaderdbobj 'status) status))
    ;;  FIELD UPDATE CODE ENDS HERE. 
    (setf (slot-value InvoiceHeaderdbservice 'dbobject) InvoiceHeaderdbobj)
    (setf (slot-value InvoiceHeaderdbservice 'businessobject) domainobj)
    
    (setcompany InvoiceHeaderdbservice comp)
    (db-save InvoiceHeaderdbservice)
    ;; Return the newly created Invoice Header domain object
    (copyInvoiceHeader-dbtodomain InvoiceHeaderdbobj domainobj)))


(defmethod doupdate ((service InvoiceHeaderService) (requestmodel InvoiceHeaderStatusRequestModel))
  (let* ((InvoiceHeaderdbservice (make-instance 'InvoiceHeaderDBService))
	 (invnum (invnum requestmodel))
	 (totalvalue (totalvalue requestmodel))
	 (status (status requestmodel))
	 (comp (company requestmodel))	 
	 (InvoiceHeaderdbobj (select-invoice-header-by-invnum invnum comp))
	 (domainobj (make-instance 'InvoiceHeader)))
	 
    ;; FIELD UPDATE CODE STARTS HERE 
    (when InvoiceHeaderdbobj
      (setf (slot-value InvoiceHeaderdbobj 'totalvalue) totalvalue)
      (setf (slot-value InvoiceHeaderdbobj 'status) status))
    ;;  FIELD UPDATE CODE ENDS HERE. 
    (setf (slot-value InvoiceHeaderdbservice 'dbobject) InvoiceHeaderdbobj)
    (setf (slot-value InvoiceHeaderdbservice 'businessobject) domainobj)
    
    (setcompany InvoiceHeaderdbservice comp)
    (db-save InvoiceHeaderdbservice)
    ;; Return the newly created Invoice Header domain object
    (copyInvoiceHeader-dbtodomain InvoiceHeaderdbobj domainobj)))


;; PROCESS THE READ REQUEST
(defmethod ProcessReadRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderRequestModel))
  :description "Adapter service method to read a single InvoiceHeader"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  (call-next-method))

(defmethod ProcessReadRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderContextIDRequestModel))
  :description "Adapter service method to read a single InvoiceHeader"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  (call-next-method))

(defmethod doread ((service InvoiceHeaderService) (requestmodel InvoiceHeaderRequestModel))
  (let* ((comp (company requestmodel))
	 (invnum (invnum requestmodel))
	 (dbInvoiceHeader (select-invoice-header-by-invnum invnum comp))
	 (InvoiceHeaderobj (make-instance 'InvoiceHeader)))
    ;; return back a Invoice Header  object
    (setf (slot-value InvoiceHeaderobj 'company) comp)
    (copyInvoiceHeader-dbtodomain dbInvoiceHeader InvoiceHeaderobj)))

(defmethod doread ((service InvoiceHeaderService) (requestmodel InvoiceHeaderContextIDRequestModel))
  (let* ((comp (company requestmodel))
	 (context-id (context-id requestmodel))
	 (dbInvoiceHeader (select-invoice-header-by-context-id context-id comp))
	 (InvoiceHeaderobj (make-instance 'InvoiceHeader)))
    ;; return back a Invoice Header  object
    (setf (slot-value InvoiceHeaderobj 'company) comp)
    (copyInvoiceHeader-dbtodomain dbInvoiceHeader InvoiceHeaderobj)))


(defun copyInvoiceHeader-dbtodomain (dbsrc domaindest)
  (let* ((comp (select-company-by-id (slot-value dbsrc 'tenant-id)))
	 (vend (select-vendor-by-id (slot-value dbsrc 'vendor-id)))
	 (cust (select-customer-by-id (slot-value dbsrc 'custid) comp)))

    (with-slots (context-id row-id invnum invdate customer  custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear external-url status vendor company) domaindest
      (setf vendor vend)
      (setf customer cust)
      (setf company comp)
      (setf context-id (slot-value dbsrc 'context-id))
      (setf row-id (slot-value dbsrc 'row-id))
      (setf invnum (slot-value dbsrc 'invnum))
      (setf invdate (slot-value dbsrc 'invdate))
      (setf custaddr (slot-value dbsrc 'custaddr))
      (setf custgstin (slot-value dbsrc 'custgstin))
      (setf statecode (slot-value dbsrc 'statecode))
      (setf billaddr (slot-value dbsrc 'billaddr))
      (setf shipaddr (slot-value dbsrc 'shipaddr))
      (setf placeofsupply (slot-value dbsrc 'placeofsupply))
      (setf revcharge (slot-value dbsrc 'revcharge))
      (setf transmode (slot-value dbsrc 'transmode))
      (setf vnum (slot-value dbsrc 'vnum))
      (setf totalvalue (slot-value dbsrc 'totalvalue))
      (setf totalinwords (slot-value dbsrc 'totalinwords))
      (setf bankaccnum (slot-value dbsrc 'bankaccnum))
      (setf bankifsccode (slot-value dbsrc 'bankifsccode))
      (setf tnc (slot-value dbsrc 'tnc))
      (setf authsign (slot-value dbsrc 'authsign))
      (setf finyear (slot-value dbsrc 'finyear))
      (setf external-url (slot-value dbsrc 'external-url))
      (setf status (slot-value dbsrc 'status))
      domaindest)))

