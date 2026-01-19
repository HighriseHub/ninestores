;; -*- mode: common-lisp; coding: utf-8 -*-%
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)
;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.
;; DO NOT COMPILE THIS FILE USING CTRL + C CTRL + K (OR CTRL + CK)
;; DO NOT ADD THIS FILE TO COMPILE.LISP FOR MASS COMPILATION. 

;; 1. The Key Helper (to ensure consistency across methods)
(defun %get-breakdown-key (item)
  (format nil "~A-~A-~A-~A" 
          (hsncode item) (cgstrate item) (sgstrate item) (igstrate item)))

;; 2. Remove Method
(defmethod remove-item-from-tax-breakdown ((breakdown gst-breakdown) (item InvoiceItem))
  "Reduces totals for the specific HSN/Rate. If totals hit zero, removes the entry."
  (let* ((key (%get-breakdown-key item))
         (entry (gethash key (entries breakdown))))
    (when entry
      ;; Subtract values
      (decf (taxable-value entry) (taxablevalue item))
      (decf (cgst-amount entry)   (cgstamt item))
      (decf (sgst-amount entry)   (sgstamt item))
      (decf (igst-amount entry)   (igstamt item))
      
      ;; Clean up: If taxable value is 0 (or near zero due to float precision), 
      ;; remove the row from the summary
      (when (<= (taxable-value entry) 0.01)
        (remhash key (entries breakdown))))))

;; 3. Update Method
(defmethod update-item-in-tax-breakdown ((breakdown gst-breakdown) (old-item InvoiceItem) (new-item InvoiceItem))
  "Updates the breakdown by removing the old item data and adding the new item data.
   This handles cases where the HSN or Tax Rate might have changed."
  (remove-item-from-tax-breakdown breakdown old-item)
  (add-item-to-tax-breakdown breakdown new-item))

;; 4. Modified Add Method (using the new key helper)
(defmethod add-item-to-tax-breakdown ((breakdown gst-breakdown) (item InvoiceItem))
  (let* ((key (%get-breakdown-key item))
         (entry (gethash key (entries breakdown)
                         (make-instance 'tax-entry 
                                        :hsn-code (hsncode item)
                                        :cgst-rate (cgstrate item)
                                        :sgst-rate (sgstrate item)
                                        :igst-rate (igstrate item)))))
    (incf (taxable-value entry) (taxablevalue item))
    (incf (cgst-amount entry)   (cgstamt item))
    (incf (sgst-amount entry)   (sgstamt item))
    (incf (igst-amount entry)   (igstamt item))
    (setf (gethash key (entries breakdown)) entry)))




(defmethod get-sorted-summary ((breakdown gst-breakdown))
  "Converts hash table to a list sorted by HSN for consistent printing."
  (let ((result nil))
    (maphash (lambda (k v) (declare (ignore k)) (push v result)) 
             (entries breakdown))
    (sort result #'string< :key #'hsn-code)))


(defun select-all-invoice-items (invoiceheader company)
  :documentation "This function stores all the currencies in a hashtable. The Key = country, Value = list of currency, code and symbol."
  (let* ((tenant-id (slot-value company 'row-id))
	 (invheadid (slot-value invoiceheader 'row-id)))
    (clsql:select 'dod-invoice-items :where
		  [and
		  [= [:invheadid] invheadid]
		  [= [:deleted-state] "N"]
		  [= [:tenant-id] tenant-id]]
		    :limit 100
		    :caching *dod-database-caching* :flatp t )))

;; If you specifically want to search by prd-id
(defun find-invoice-item (prd-id items)
  (find prd-id items :key #'prd-id :test #'equal))

(defun select-invoice-item-by-product-id (product-id invoiceheader company)
  :documentation "This function stores all the currencies in a hashtable. The Key = country, Value = list of currency, code and symbol."
  (let* ((tenant-id (slot-value company 'row-id))
	 (invheadid (slot-value invoiceheader 'row-id)))
    (car (clsql:select 'dod-invoice-items :where
		  [and
		  [= [:prd-id] product-id]
		  [= [:invheadid] invheadid]
		  [= [:deleted-state] "N"]
		  [= [:tenant-id] tenant-id]]
		    :limit 100
		    :caching *dod-database-caching* :flatp t ))))




(defmethod ProcessDeleteRequest ((adapter InvoiceItemAdapter) (requestmodel InvoiceItemRequestModel))
  :description "This method is responsible for Deleting a web push notification record for a given vendor"
  ;; Set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceItemService))
  (call-next-method))


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




(defmethod doDelete ((service InvoiceItemService) (requestmodel InvoiceItemRequestModel))
  :description "This method is responsible for Deleting a Web push notification subscription for a given vendor"
  (let* ((company (company requestmodel))
	 (invoiceheader (invoiceheader requestmodel))
	 (prd-id (prd-id requestmodel))
	 (invoiceitem (select-invoice-item-by-product-id prd-id invoiceheader company))
	 (InvoiceItemdbservice (make-instance 'InvoiceItemDBService)))
    (setf (slot-value InvoiceItemdbservice 'company) company)
    (setf (slot-value InvoiceItemdbservice 'dbobject) invoiceitem)
    ;; Delete the record
    (db-delete InvoiceItemdbservice)))

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
				    :status "PENDING"
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
    (with-slots (invheadid prd-id prddesc hsncode qty uom price discount taxable-value cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval status tenant-id) destination
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
      (setf status (slot-value source 'status))
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
    (with-slots (InvoiceHeader prd-id prddesc hsncode qty uom price discount taxablevalue cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval status company) responsemodel
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
      (setf (slot-value viewmodel 'status) status)
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
  (with-slots (InvoiceHeader prd-id prddesc hsncode qty uom price discount taxablevalue cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval status company) destination  
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
    (setf status (slot-value source 'status))
    (setf company (slot-value source 'company))
    destination))



(defmethod doupdate ((service InvoiceItemService) (requestmodel InvoiceItemRequestModel))
  (let* ((InvoiceItemdbservice (make-instance 'InvoiceItemDBService))
	 (InvoiceHeader (InvoiceHeader requestmodel))
	 (prd-id (prd-id requestmodel))
	 (qty (qty requestmodel))
	 (price (price requestmodel))
	 (discount (discount requestmodel))
	 (taxablevalue (taxablevalue requestmodel))
	 (cgstamt (cgstamt requestmodel))
	 (sgstamt (sgstamt requestmodel))
	 (igstamt (igstamt requestmodel))
	 (totalitemval (totalitemval requestmodel))
	 (status (status requestmodel))
	 (comp (company requestmodel))
	 (InvoiceItemdbobj (select-invoice-item-by-product-id prd-id invoiceheader comp))
	 (domainobj (make-instance 'InvoiceItem)))
    ;; FIELD UPDATE CODE STARTS HERE 
    (when invoiceheader  
      (setf (slot-value InvoiceItemdbobj 'qty) qty)
      (setf (slot-value InvoiceItemdbobj 'price) price)
      (setf (slot-value InvoiceItemdbobj 'discount) discount)
      (setf (slot-value InvoiceItemdbobj 'taxable-value) taxablevalue)
      (setf (slot-value InvoiceItemdbobj 'cgstamt) cgstamt)
      (setf (slot-value InvoiceItemdbobj 'sgstamt) sgstamt)
      (setf (slot-value InvoiceItemdbobj 'igstamt) igstamt)
      (setf (slot-value InvoiceItemdbobj 'totalitemval) totalitemval)
      (setf (slot-value InvoiceItemdbobj 'status) status))
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
	 (dbInvoiceItem-knowledge (with-db-call (select-invoice-item-by-product-id  prd-id invoiceheader comp)))
	 (InvoiceItemobj (make-instance 'InvoiceItem)))
    ;; return back a Vpaymentmethod  response model
    (setf (slot-value InvoiceItemobj 'company) comp)
    (setf (slot-value InvoiceItemobj 'InvoiceHeader) invoiceheader)
    (setf (bo-knowledge service) dbInvoiceItem-knowledge)
    (when (eq (bo-knowledge-truth dbInvoiceItem-knowledge) :T)
      (let ((dbInvoiceItem (bo-knowledge-payload dbInvoiceItem-knowledge)))
	(copyInvoiceItem-dbtodomain dbInvoiceItem InvoiceItemobj)))
    InvoiceItemobj))


(defun copyInvoiceItem-dbtodomain (source destination)
  (let* ((comp (select-company-by-id (slot-value source 'tenant-id))))
    (with-slots (row-id InvoiceHeader prd-id prddesc hsncode qty uom price discount taxablevalue cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval status  company) destination
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
      (setf status (slot-value source 'status))
      destination)))

