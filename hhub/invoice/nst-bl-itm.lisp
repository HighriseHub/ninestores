;; -*- mode: common-lisp; coding: utf-8 -*-%
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)
;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.
;; DO NOT COMPILE THIS FILE USING CTRL + C CTRL + K (OR CTRL + CK)
;; DO NOT ADD THIS FILE TO COMPILE.LISP FOR MASS COMPILATION. 



(defun select-all-invoice-items (invoiceheader company)
  :documentation "This function stores all the currencies in a hashtable. The Key = country, Value = list of currency, code and symbol."
  (let* ((tenant-id (slot-value company 'row-id))
	 (invheadid (slot-value invoiceheader 'row-id)))
    (clsql:select 'dod-invoice-items :where
		  [and
		  [= [:invheadid] invheadid]
		  [= [:tenant-id] tenant-id]]
		    :limit 100
		    :caching *dod-database-caching* :flatp t )))

(defun select-invoice-item-by-product-id (product-id invoiceheader company)
  :documentation "This function stores all the currencies in a hashtable. The Key = country, Value = list of currency, code and symbol."
  (let* ((tenant-id (slot-value company 'row-id))
	 (invheadid (slot-value invoiceheader 'row-id)))
    (clsql:select 'dod-invoice-items :where
		  [and
		  [= [:prd-id] product-id]
		  [= [:invheadid] invheadid]
		  [= [:tenant-id] tenant-id]]
		    :limit 100
		    :caching *dod-database-caching* :flatp t )))


(defmethod ProcessCreateRequest ((adapter InvoiceItemAdapter) (requestmodel InvoiceItemRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Warehouse object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceItemService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod init ((dbas InvoiceItemDBService) (bo InvoiceItem))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'dod-invoice-items)))
    ;; Set specific fields of the DB object if you need to. 
    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))



(defmethod doCreate ((service InvoiceItemService) (requestmodel InvoiceItemRequestModel))
  (let* ((InvoiceItemdbservice (make-instance 'InvoiceItemDBService))
	 (company (company requestmodel))
	 (InvoiceHeader (InvoiceHeader requestmodel))
	 (prd-id (prd-id requestmodel))
	 (prddesc (prddesc requestmodel))
	 (hsncode (hsncode requestmodel))
	 (qty (qty requestmodel))
	 (uom (uom requestmodel))
	 (price (price requestmodel))
	 (discount (discount requestmodel))
	 (taxablevalue (taxablevalue requestmodel))
	 (cgstrate (cgstrate requestmodel))
	 (cgstamt (cgstamt requestmodel))
	 (sgstrate (sgstrate requestmodel))
	 (sgstamt (sgstamt requestmodel))
	 (igstrate (igstrate requestmodel))
	 (igstamt (igstamt requestmodel))
	 (totalitemval (totalitemval requestmodel))
	 (domainobj (createInvoiceItemobject InvoiceHeader prd-id prddesc hsncode qty uom price discount taxablevalue cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval company )))
         ;; Initialize the DB Service
    (init InvoiceItemdbservice domainobj)
    (copy-businessobject-to-dbobject InvoiceItemdbservice)
    (db-save InvoiceItemdbservice)
    ;; Return the newly created warehouse domain object
    domainobj))


(defun createInvoiceItemobject (InvoiceHeader prd-id prddesc hsncode qty uom price discount taxablevalue cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval  company)
  (let* ((domainobj  (make-instance 'InvoiceItem 
				    :InvoiceHeader InvoiceHeader
				    :prd-id prd-id
				    :prddesc prddesc
				    :hsncode hsncode
				    :qty qty
				    :uom uom
				    :price price
				    :discount discount
				    :taxablevalue taxablevalue
				    :cgstrate cgstrate
				    :cgstamt cgstamt 
				    :sgstrate sgstrate
				    :sgstamt sgstamt
				    :igstrate igstrate
				    :igstamt igstamt
				    :totalitemval totalitemval
				    :company company)))
    domainobj))

(defmethod Copy-BusinessObject-To-DBObject ((dbas InvoiceItemDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyInvoiceItem-domaintodb domainobj dbobj))))

;; source = domain destination = db
(defun copyInvoiceItem-domaintodb (source destination) 
  (let ((company (slot-value source 'company))
	(invheader (slot-value source 'InvoiceHeader)))
    (with-slots (invheadid prd-id prddesc hsncode qty uom price discount taxable-value cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval tenant-id) destination
      (setf tenant-id (slot-value company 'row-id))
      (setf invheadid (slot-value invheader 'row-id))
      (setf prd-id (slot-value source 'prd-id))
      (setf prddesc (slot-value source 'prddesc))
      (setf hsncode (slot-value source 'hsncode))
      (setf qty (slot-value source 'qty))
      (setf uom (slot-value source 'uom))
      (setf price (slot-value source 'price))
      (setf discount (slot-value source 'discount))
      (setf taxable-value (slot-value source 'taxablevalue))
      (setf cgstrate (slot-value source 'cgstrate))
      (setf cgstamt (slot-value source 'cgstamt))
      (setf sgstrate (slot-value source 'sgstrate))
      (setf sgstamt (slot-value source 'sgstamt))
      (setf igstrate (slot-value source 'igstrate))
      (setf igstamt (slot-value source 'igstamt))
      (setf totalitemval (slot-value source 'totalitemval))
      destination)))


;; PROCESS UPDATE REQUEST  
(defmethod ProcessUpdateRequest ((adapter InvoiceItemAdapter) (requestmodel InvoiceItemRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceItemService))
  ;; call the parent ProcessUpdate
  (call-next-method))

;; PROCESS READ ALL REQUEST.
(defmethod ProcessReadAllRequest ((adapter InvoiceItemAdapter) (requestmodel InvoiceItemRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceItemService))
  (call-next-method))

(defmethod doreadall ((service InvoiceItemService) (requestmodel InvoiceItemRequestModel))
  (let* ((comp (company requestmodel))
	 (invoiceheader (invoiceheader requestmodel))
	 (domainobjlst (select-all-invoice-items invoiceheader comp)))
    ;; return back a list of domain objects 
    (mapcar (lambda (object)
	      (let ((domainobject (make-instance 'InvoiceItem)))
		(setf (slot-value domainobject 'InvoiceHeader) invoiceheader)
		(copyInvoiceItem-dbtodomain object domainobject))) domainobjlst)))


(defmethod CreateViewModel ((presenter InvoiceItemPresenter) (responsemodel InvoiceItemResponseModel))
  (let ((viewmodel (make-instance 'InvoiceItemViewModel)))
    (with-slots (InvoiceHeader prd-id prddesc hsncode qty uom price discount taxablevalue cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval company) responsemodel
      (setf (slot-value viewmodel 'InvoiceHeader) InvoiceHeader)
      (setf (slot-value viewmodel 'prd-id) prd-id)
      (setf (slot-value viewmodel 'prddesc) prddesc)
      (setf (slot-value viewmodel 'hsncode) hsncode)
      (setf (slot-value viewmodel 'qty) qty)
      (setf (slot-value viewmodel 'uom) uom)
      (setf (slot-value viewmodel 'price) price)
      (setf (slot-value viewmodel 'discount) discount)
      (setf (slot-value viewmodel 'taxablevalue) taxablevalue)
      (setf (slot-value viewmodel 'cgstrate) cgstrate)
      (setf (slot-value viewmodel 'cgstamt) cgstamt)
      (setf (slot-value viewmodel 'sgstrate) sgstrate)
      (setf (slot-value viewmodel 'sgstamt) sgstamt)
      (setf (slot-value viewmodel 'igstrate) igstrate)
      (setf (slot-value viewmodel 'igstamt) igstamt)
      (setf (slot-value viewmodel 'totalitemval) totalitemval)
      (setf (slot-value viewmodel 'company) company)
      viewmodel)))
  

(defmethod ProcessResponse ((adapter InvoiceItemAdapter) (busobj InvoiceItem))
  (let ((responsemodel (make-instance 'InvoiceItemResponseModel)))
    (createresponsemodel adapter busobj responsemodel)))

(defmethod ProcessResponseList ((adapter InvoiceItemAdapter) InvoiceItemlist)
  (mapcar (lambda (domainobj)
	    (let ((responsemodel (make-instance 'InvoiceItemResponseModel)))
	      (createresponsemodel adapter domainobj responsemodel))) InvoiceItemlist))

(defmethod CreateAllViewModel ((presenter InvoiceItemPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))


(defmethod CreateResponseModel ((adapter InvoiceItemAdapter) (source InvoiceItem) (destination InvoiceItemResponseModel))
  :description "source = InvoiceItem destination = InvoiceItemResponseModel"
  (with-slots (InvoiceHeader prd-id prddesc hsncode qty uom price discount taxablevalue cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval company) destination  
    (setf InvoiceHeader (slot-value source 'InvoiceHeader))
    (setf prd-id (slot-value source 'prd-id))
    (setf prddesc (slot-value source 'prddesc))
    (setf hsncode (slot-value source 'hsncode))
    (setf qty (slot-value source 'qty))
    (setf uom (slot-value source 'uom))
    (setf price (slot-value source 'price))
    (setf discount (slot-value source 'discount))
    (setf taxablevalue (slot-value source 'taxablevalue))
    (setf cgstrate (slot-value source 'cgstrate))
    (setf cgstamt (slot-value source 'cgstamt))
    (setf sgstrate (slot-value source 'sgstrate))
    (setf sgstamt (slot-value source 'sgstamt))
    (setf igstrate (slot-value source 'igstrate))
    (setf igstamt (slot-value source 'igstamt))
    (setf totalitemval (slot-value source 'totalitemval))
    (setf company (slot-value source 'company))
    destination))



(defmethod doupdate ((service InvoiceItemService) (requestmodel InvoiceItemRequestModel))
  (let* ((InvoiceItemdbservice (make-instance 'InvoiceItemDBService))
	 (InvoiceHeader (InvoiceHeader requestmodel))
	 (prd-id (prd-id requestmodel))
	 (prddesc (prddesc requestmodel))
	 (hsncode (hsncode requestmodel))
	 (qty (qty requestmodel))
	 (uom (uom requestmodel))
	 (price (price requestmodel))
	 (discount (discount requestmodel))
	 (taxablevalue (taxablevalue requestmodel))
	 (cgstrate (cgstrate requestmodel))
	 (cgstamt (cgstamt requestmodel))
	 (sgstrate (sgstrate requestmodel))
	 (sgstamt (sgstamt requestmodel))
	 (igstrate (igstrate requestmodel))
	 (igstamt (igstrate requestmodel))
	 (totalitemval (totalitemval requestmodel))
	 (comp (company requestmodel))
	 (InvoiceItemdbobj (select-all-invoice-items invoiceheader comp))
	 (domainobj (make-instance 'InvoiceItem)))
    ;; FIELD UPDATE CODE STARTS HERE 
    (when invoiceheader  
      (setf (slot-value InvoiceItemdbobj 'invheadid) (slot-value invoiceheader 'row-id))
      (setf (slot-value InvoiceItemdbobj 'prd-id) prd-id)
      (setf (slot-value InvoiceItemdbobj 'prddesc) prddesc)
      (setf (slot-value InvoiceItemdbobj 'hsncode) hsncode)
      (setf (slot-value InvoiceItemdbobj 'qty) qty)
      (setf (slot-value InvoiceItemdbobj 'uom) uom)
      (setf (slot-value InvoiceItemdbobj 'price) price)
      (setf (slot-value InvoiceItemdbobj 'discount) discount)
      (setf (slot-value InvoiceItemdbobj 'taxablevalue) taxablevalue)
      (setf (slot-value InvoiceItemdbobj 'cgstrate) cgstrate)
      (setf (slot-value InvoiceItemdbobj 'cgstamt) cgstamt)
      (setf (slot-value InvoiceItemdbobj 'sgstrate) sgstrate)
      (setf (slot-value InvoiceItemdbobj 'sgstamt) sgstamt)
      (setf (slot-value InvoiceItemdbobj 'igstrate) igstrate)
      (setf (slot-value InvoiceItemdbobj 'igstamt) igstamt)
      (setf (slot-value InvoiceItemdbobj 'totalitemval) totalitemval)
      (setf (slot-value InvoiceItemdbobj 'tenant-id) (slot-value comp 'row-id)))
        
    ;;  FIELD UPDATE CODE ENDS HERE. 
    
    (setf (slot-value InvoiceItemdbservice 'dbobject) InvoiceItemdbobj)
    (setf (slot-value InvoiceItemdbservice 'businessobject) domainobj)
    
    (setcompany InvoiceItemdbservice comp)
    (db-save InvoiceItemdbservice)
    ;; Return the newly created UPI domain object
    (copyInvoiceItem-dbtodomain InvoiceItemdbobj domainobj)))


;; PROCESS THE READ REQUEST
(defmethod ProcessReadRequest ((adapter InvoiceItemAdapter) (requestmodel InvoiceItemRequestModel))
  :description "Adapter service method to read a single InvoiceItem"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceItemService))
  (call-next-method))

(defmethod doread ((service InvoiceItemService) (requestmodel InvoiceItemRequestModel))
  (let* ((comp (company requestmodel))
	 (invoiceheader (invoiceheader requestmodel))
	 (prd-id (prd-id requestmodel))
	 (dbInvoiceItem (select-invoice-item-by-product-id  prd-id invoiceheader comp))
	 (InvoiceItemobj (make-instance 'InvoiceItem)))
    ;; return back a Vpaymentmethod  response model
    (setf (slot-value InvoiceItemobj 'company) comp)
    (setf (slot-value InvoiceItemobj 'InvoiceHeader) invoiceheader)
    (copyInvoiceItem-dbtodomain dbInvoiceItem InvoiceItemobj)))


(defun copyInvoiceItem-dbtodomain (source destination)
  (let* ((comp (select-company-by-id (slot-value source 'tenant-id))))
    (with-slots (row-id InvoiceHeader prd-id prddesc hsncode qty uom price discount taxablevalue cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval  company) destination
      (setf company comp)
      (setf row-id (slot-value source 'row-id))
      (setf prd-id (slot-value source 'prd-id))
      (setf prddesc (slot-value source 'prddesc))
      (setf hsncode (slot-value source 'hsncode))
      (setf qty (slot-value source 'qty))
      (setf uom (slot-value source 'uom))
      (setf price (slot-value source 'price))
      (setf discount (slot-value source 'discount))
      (setf taxablevalue (slot-value source 'taxable-value))
      (setf cgstrate (slot-value source 'cgstrate))
      (setf cgstamt (slot-value source 'cgstamt))
      (setf sgstrate (slot-value source 'sgstrate))
      (setf sgstamt (slot-value source 'sgstamt))
      (setf igstrate (slot-value source 'igstrate))
      (setf igstamt (slot-value source 'igstamt))
      (setf totalitemval (slot-value source 'totalitemval))
      destination)))

