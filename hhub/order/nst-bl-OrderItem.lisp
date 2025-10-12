;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.
;; DO NOT COMPILE THIS FILE USING CTRL + C CTRL + K (OR CTRL + CK)
;; DO NOT ADD THIS FILE TO COMPILE.LISP FOR MASS COMPILATION. 


(defmethod ProcessCreateRequest ((adapter OrderItemAdapter) (requestmodel OrderItemRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Warehouse object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'OrderItemService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod init ((dbas OrderItemDBService) (bo OrderItem))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'database-table-object-name-here)))
    ;; Set specific fields of the DB object if you need to. 
    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))



(defmethod doCreate ((service OrderItemService) (requestmodel OrderItemRequestModel))
  (let* ((OrderItemdbservice (make-instance 'OrderItemDBService))
	 (company (company requestmodel))
	 (row-id (row-id requestmodel))
	 (order (order requestmodel))
	 (product (product requestmodel))
	 (vendor (vendor requestmodel))
	 (prd-qty (prd-qty requestmodel))
	 (unit-price (unit-price requestmodel))
	 (disc-rate (disc-rate requestmodel))
	 (cgst (cgst requestmodel))
	 (sgst (sgst requestmodel))
	 (igst (igst requestmodel))
	 (addl-tax1-rate (addl-tax1-rate requestmodel))
	 (comments (comments requestmodel))
	 (fulfilled (fulfilled requestmodel))
	 (status (status requestmodel))
	 (deleted-state (deleted-state requestmodel))
	 (domainobj (createOrderItemobject row-id order product vendor prd-qty unit-price disc-rate cgst sgst igst addl-tax1-rate comments fulfilled status deleted-state company)))
         ;; Initialize the DB Service
    (init OrderItemdbservice domainobj)
    (copy-businessobject-to-dbobject OrderItemdbservice)
    (db-save OrderItemdbservice)
    ;; Return the newly created orderitems domain object
    domainobj))


(defun createOrderItemobject (row-id order product vendor prd-qty unit-price disc-rate cgst sgst igst addl-tax1-rate comments fulfilled status deleted-state company)
  (let* ((domainobj  (make-instance 'OrderItem 
				       :row-id row-id
				       :order order
				       :product product
				       :vendor vendor
				       :prd-qty prd-qty
				       :unit-price unit-price
				       :disc-rate disc-rate
				       :cgst cgst
				       :sgst sgst
				       :igst igst
				       :addl-tax1-rate addl-tax1-rate 
				       :comments comments
				       :fulfilled fulfilled
				       :status status
				       :deleted-state deleted-state
				       :vendor vendor
				       :company company)))
    domainobj))

(defmethod Copy-BusinessObject-To-DBObject ((dbas OrderItemDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyOrderItem-domaintodb domainobj dbobj))))

;; source = domain destination = db
(defun copyOrderItem-domaintodb (source destination) 
  (let ((vendor (slot-value source 'vendor))
	(company (slot-value source 'company))
	(product (slot-value source 'product))
	(order (slot-value source 'order)))
    (with-slots (row-id order-id prd-id vendor-id prd-qty unit-price disc-rate cgst sgst igst addl-tax1-rate comments fulfilled status deleted-state tenant-id) destination
      (setf vendor-id (slot-value vendor 'row-id))
      (setf tenant-id (slot-value company 'row-id))
      (setf order-id (slot-value order 'row-id))
      (setf prd-id (slot-value product 'row-id))
      (setf prd-qty (slot-value source 'prd-qty))
      (setf unit-price (slot-value source 'unit-price))
      (setf disc-rate (slot-value source 'disc-rate))
      (setf cgst (slot-value source 'cgst))
      (setf sgst (slot-value source 'sgst))
      (setf igst (slot-value source 'igst))
      (setf addl-tax1-rate (slot-value source 'addl-tax1-rate))
      (setf comments (slot-value source 'comments))
      (setf fulfilled (slot-value source 'fulfilled))
      (setf status (slot-value source 'status))
      (setf deleted-state (slot-value source 'deleted-state))
      destination)))


;; PROCESS UPDATE REQUEST  
(defmethod ProcessUpdateRequest ((adapter OrderItemAdapter) (requestmodel OrderItemRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'OrderItemService))
  ;; call the parent ProcessUpdate
  (call-next-method))

;; PROCESS READ ALL REQUEST.
(defmethod ProcessReadAllRequest ((adapter OrderItemAdapter) (requestmodel OrderItemRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'OrderItemService))
  (call-next-method))

(defmethod doreadall ((service OrderItemService) (requestmodel OrderItemRequestModel))
  (let* ((vendor (vendor requestmodel))
	 (order (order requestmodel))
	 (dbobjlst (get-order-items-for-vendor-by-order-id order vendor)))
    ;; return back a list of domain objects 
    (mapcar (lambda (dbobject)
	      (let ((domainobject (make-instance 'OrderItem)))
		(copyOrderItem-dbtodomain dbobject domainobject))) dbobjlst)))


(defmethod CreateViewModel ((presenter OrderItemPresenter) (responsemodel OrderItemResponseModel))
  (let ((viewmodel (make-instance 'OrderItemViewModel)))
    (with-slots (row-id order product vendor prd-qty unit-price disc-rate cgst sgst igst addl-tax1-rate comments fulfilled status deleted-state company) responsemodel
      (setf (slot-value viewmodel 'vendor) vendor)
      (setf (slot-value viewmodel 'row-id) row-id)
      (setf (slot-value viewmodel 'order) order)
      (setf (slot-value viewmodel 'product) product)
      (setf (slot-value viewmodel 'vendor) vendor)
      (setf (slot-value viewmodel 'prd-qty) prd-qty)
      (setf (slot-value viewmodel 'unit-price) unit-price)
      (setf (slot-value viewmodel 'disc-rate) disc-rate)
      (setf (slot-value viewmodel 'cgst) cgst)
      (setf (slot-value viewmodel 'sgst) sgst)
      (setf (slot-value viewmodel 'igst) igst)
      (setf (slot-value viewmodel 'addl-tax1-rate) addl-tax1-rate)
      (setf (slot-value viewmodel 'comments) comments)
      (setf (slot-value viewmodel 'fulfilled) fulfilled)
      (setf (slot-value viewmodel 'status) status)
      (setf (slot-value viewmodel 'deleted-state) deleted-state)
      (setf (slot-value viewmodel 'company) company)
       viewmodel)))
  

(defmethod ProcessResponse ((adapter OrderItemAdapter) (busobj OrderItem))
  (let ((responsemodel (make-instance 'OrderItemResponseModel)))
    (createresponsemodel adapter busobj responsemodel)))

(defmethod ProcessResponseList ((adapter OrderItemAdapter) OrderItemlist)
  (mapcar (lambda (domainobj)
	    (let ((responsemodel (make-instance 'OrderItemResponseModel)))
	      (createresponsemodel adapter domainobj responsemodel))) OrderItemlist))

(defmethod CreateAllViewModel ((presenter OrderItemPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))


(defmethod CreateResponseModel ((adapter OrderItemAdapter) (source OrderItem) (destination OrderItemResponseModel))
  :description "source = OrderItem destination = OrderItemResponseModel"
  (with-slots (row-id order product vendor prd-qty unit-price disc-rate cgst sgst igst addl-tax1-rate comments fulfilled status deleted-state company) destination  
    (setf row-id (slot-value source 'row-id))
    (setf order (slot-value source 'order))
    (setf product (slot-value source 'product))
    (setf vendor (slot-value source 'vendor))
    (setf prd-qty (slot-value source 'prd-qty))
    (setf unit-price (slot-value source 'unit-price))
    (setf disc-rate (slot-value source 'disc-rate))
    (setf cgst (slot-value source 'cgst))
    (setf sgst (slot-value source 'sgst))
    (setf igst (slot-value source 'igst))
    (setf addl-tax1-rate (slot-value source 'addl-tax1-rate))
    (setf comments (slot-value source 'comments))
    (setf fulfilled (slot-value source 'fulfilled))
    (setf status (slot-value source 'status))
    (setf deleted-state (slot-value source 'deleted-state))
    (setf company (slot-value source 'company))
    destination))



(defmethod doupdate ((service OrderItemService) (requestmodel OrderItemRequestModel))
  (with-slots (row-id order product vendor prd-qty unit-price disc-rate cgst sgst igst addl-tax1-rate comments fulfilled status deleted-state company) requestmodel
    (let* ((OrderItemdbservice (make-instance 'OrderItemDBService))
	   (prd-id (slot-value product 'row-id))
	   (order-id (slot-value order 'row-id))
	   (vendor-id (slot-value vendor 'row-id))
	   (tenant-id (slot-value company 'row-id))
	   (OrderItemdbobj (get-order-items-by-product-id prd-id order-id tenant-id))
	   (domainobj (make-instance 'OrderItem)))
    ;; FIELD UPDATE CODE STARTS HERE 
    (when OrderItemdbobj 
      (setf (slot-value OrderItemdbobj 'vendor-id) vendor-id)
      (setf (slot-value OrderItemdbobj 'prd-qty) prd-qty)
      (setf (slot-value OrderItemdbobj 'unit-price) unit-price)
      (setf (slot-value OrderItemdbobj 'disc-rate) disc-rate)
      (setf (slot-value OrderItemdbobj 'cgst) cgst)
      (setf (slot-value OrderItemdbobj 'sgst) sgst)
      (setf (slot-value OrderItemdbobj 'igst) igst)
      (setf (slot-value OrderItemdbobj 'addl-tax1-rate) addl-tax1-rate)
      (setf (slot-value OrderItemdbobj 'comments) comments)
      (setf (slot-value OrderItemdbobj 'fulfilled) fulfilled)
      (setf (slot-value OrderItemdbobj 'status) status)
      (setf (slot-value OrderItemdbobj 'deleted-state) deleted-state))
       
     ;;  FIELD UPDATE CODE ENDS HERE. 
    
    (setf (slot-value OrderItemdbservice 'dbobject) OrderItemdbobj)
    (setf (slot-value OrderItemdbservice 'businessobject) domainobj)
    
    (setcompany OrderItemdbservice company)
    (db-save OrderItemdbservice)
    ;; Return the newly created UPI domain object
    (copyOrderItem-dbtodomain OrderItemdbobj domainobj))))


;; PROCESS THE READ REQUEST
(defmethod ProcessReadRequest ((adapter OrderItemAdapter) (requestmodel OrderItemRequestModel))
  :description "Adapter service method to read a single OrderItem"
  (setf (slot-value adapter 'businessservice) (find-class 'OrderItemService))
  (call-next-method))

(defmethod doread ((service OrderItemService) (requestmodel OrderItemRequestModel))
  (let* ((row-id (row-id requestmodel))
	 (company (company requestmodel))
	 (order (order requestmodel))
	 (dbOrderItem (get-order-item-by-id row-id))
	 (OrderItemobj (make-instance 'OrderItem)))
    ;; return back a Vpaymentmethod  response model
    (setf (slot-value OrderItemobj 'company) company)
    (setf (slot-value OrderItemobj 'order) order) 
    (copyOrderItem-dbtodomain dbOrderItem OrderItemobj)))


(defun copyOrderItem-dbtodomain (source destination)
  (let* ((dbcomp (select-company-by-id (slot-value source 'tenant-id)))
	 (prd-id (slot-value source 'prd-id))
	 (dbproduct (select-product-by-id prd-id dbcomp))
	 (dborder (get-order-by-id (slot-value source 'order-id) dbcomp))
	 (dbvend (select-vendor-by-id (slot-value source 'vendor-id))))
    (with-slots (row-id order product vendor prd-qty unit-price disc-rate cgst sgst igst addl-tax1-rate comments fulfilled status deleted-state company) destination
      (setf vendor dbvend)
      (setf product dbproduct)
      (setf order dborder)
      (setf company dbcomp)
      (setf row-id (slot-value source 'row-id))
      (setf prd-qty (slot-value source 'prd-qty))
      (setf unit-price (slot-value source 'unit-price))
      (setf disc-rate (slot-value source 'disc-rate))
      (setf cgst (slot-value source 'cgst))
      (setf sgst (slot-value source 'sgst))
      (setf igst (slot-value source 'igst))
      (setf addl-tax1-rate (slot-value source 'addl-tax1-rate))
      (setf comments (slot-value source 'comments))
      (setf fulfilled (slot-value source 'fulfilled))
      (setf status (slot-value source 'status))
      (setf deleted-state (slot-value source 'deleted-state))
      destination)))

