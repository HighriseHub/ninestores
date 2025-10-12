;; -*- mode: common-lisp; coding: utf-8 -*-%
(in-package :nstores)

;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.
;; DO NOT COMPILE THIS FILE USING CTRL + C CTRL + K (OR CTRL + CK)
;; DO NOT ADD THIS FILE TO COMPILE.LISP FOR MASS COMPILATION. 


(defmethod ProcessCreateRequest ((adapter orderAdapter) (requestmodel orderRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Warehouse object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'orderService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod init ((dbas orderDBService) (bo order))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'dod-order)))
    ;; Set specific fields of the DB object if you need to. 
    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))



(defmethod doCreate ((service orderService) (requestmodel orderRequestModel))
  (let* ((orderdbservice (make-instance 'orderDBService))
	 (customer (customer requestmodel))
	 (ord-date (ord-date requestmodel))
	 (req-date (req-date requestmodel))
	 (shipped-date (shipped-date requestmodel))
	 (expected-delivery-date (expected-delivery-date requestmodel))
	 (ordnum (ordnum requestmodel))
	 (shipaddr (shipaddr requestmodel))
	 (shipzipcode (shipzipcode requestmodel))
	 (shipcity (shipcity requestmodel))
	 (shipstate (shipstate requestmodel))
	 (billaddr (billaddr requestmodel))
	 (billzipcode (billzipcode requestmodel))
	 (billcity (billcity requestmodel))
	 (billstate (billstate requestmodel))
	 (billsameasship (billsameasship requestmodel))
	 (storepickupenabled (storepickupenabled requestmodel))
	 (gstnumber (gstnumber requestmodel))
	 (gstorgname (gstorgname requestmodel))
	 (order-fulfilled (order-fulfilled requestmodel))
	 (order-amt (order-amt requestmodel))
	 (shipping-cost (shipping-cost requestmodel))
	 (total-discount (total-discount requestmodel))
	 (total-tax (total-tax requestmodel))
	 (payment-mode (payment-mode requestmodel))
	 (comments (comments requestmodel))
	 (context-id (context-id requestmodel))
	 (status (status requestmodel))
	 (is-converted-to-invoice (is-converted-to-invoice requestmodel))
	 (is-cancelled (is-cancelled requestmodel))
	 (cancel-reason (cancel-reason requestmodel))
	 (order-type (order-type requestmodel))
	 (external-url (external-url requestmodel))
	 (order-source (order-source requestmodel))
	 (custname (custname requestmodel))
	 (company (company requestmodel))
	 (domainobj (createorderobject (function (lambda () (values  ord-date req-date shipped-date expected-delivery-date ordnum shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship storepickupenabled gstnumber gstorgname order-fulfilled order-amt shipping-cost total-discount total-tax payment-mode comments context-id  status is-converted-to-invoice is-cancelled cancel-reason order-type external-url order-source custname customer company))))))
         ;; Initialize the DB Service
    (init orderdbservice domainobj)
    (copy-businessobject-to-dbobject orderdbservice)
    (db-save orderdbservice)
    ;; Return the newly created warehouse domain object
    domainobj))


(defun createorderobject (modelfunc)
  (multiple-value-bind (ord-date req-date shipped-date expected-delivery-date ordnum shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship storepickupenabled gstnumber gstorgname order-fulfilled order-amt shipping-cost total-discount total-tax payment-mode comments context-id  status  is-converted-to-invoice is-cancelled cancel-reason order-type external-url order-source custname customer company) (funcall modelfunc)
  (let* ((domainobj  (make-instance 'order 
				    :ord-date ord-date
				    :req-date req-date
				    :shipped-date shipped-date
				    :expected-delivery-date expected-delivery-date
				    :ordnum ordnum
				    :shipaddr shipaddr
				    :shipzipcode shipzipcode
				    :shipcity shipcity
				    :shipstate shipstate
				    :billaddr billaddr 
				    :billzipcode billzipcode
				    :billcity billcity
				    :billstate billstate
				    :billsameasship billsameasship
				    :storepickupenabled storepickupenabled
				    :gstnumber gstnumber
				    :gstorgname gstorgname
				    :order-fulfilled order-fulfilled
				    :order-amt order-amt
				    :shipping-cost shipping-cost
				    :total-discount total-discount
				    :total-tax total-tax
				    :payment-mode payment-mode
				    :comments comments
				    :context-id context-id
				    :customer customer
				    :status status
				    :is-converted-to-invoice is-converted-to-invoice
				    :is-cancelled is-cancelled
				    :cancel-reason cancel-reason
				    :order-type order-type
				    :external-url external-url
				    :order-source order-source
				    :custname custname
				    :company company
				    :deleted-state "N"
				    :company company)))
    domainobj)))

(defmethod Copy-BusinessObject-To-DBObject ((dbas orderDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyorder-domaintodb domainobj dbobj))))

;; source = domain destination = db
(defun copyorder-domaintodb (source destination) 
  (let ((company (slot-value source 'company)))
    (with-slots (ord-date req-date shipped-date expected-delivery-date ordnum shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship storepickupenabled gstnumber gstorgname order-fulfilled order-amt shipping-cost total-discount total-tax payment-mode comments context-id customer status  is-converted-to-invoice is-cancelled cancel-reason order-type external-url order-source custname cust-id  tenant-id) destination
      (setf ord-date (slot-value source 'ord-date))
      (setf req-date (slot-value source 'req-date))
      (setf shipped-date (slot-value source 'shipped-date))
      (setf expected-delivery-date (slot-value source 'expected-delivery-date))
      (setf ordnum (slot-value source 'ordnum))
      (setf shipaddr (slot-value source 'shipaddr))
      (setf shipzipcode (slot-value source 'shipzipcode))
      (setf shipcity (slot-value source 'shipcity))
      (setf shipstate (slot-value source 'shipstate))
      (setf billaddr (slot-value source 'billaddr))
      (setf billzipcode (slot-value source 'billzipcode))
      (setf billcity (slot-value source 'billcity))
      (setf billstate (slot-value source 'billstate))
      (setf billsameasship (slot-value source 'billsameasship))
      (setf storepickupenabled (slot-value source 'storepickupenabled))
      (setf gstnumber (slot-value source 'gstnumber))
      (setf gstorgname (slot-value source 'gstorgname))
      (setf order-fulfilled (slot-value source 'order-fulfilled))
      (setf order-amt (slot-value source 'order-amt))
      (setf shipping-cost (slot-value source 'shipping-cost))
      (setf total-discount (slot-value source 'total-discount))
      (setf total-tax (slot-value source 'total-tax))
      (setf payment-mode (slot-value source 'payment-mode))
      (setf comments (slot-value source 'comments))
      (setf context-id (slot-value source 'context-id))
      (setf customer (slot-value source 'customer))
      (setf status (slot-value source 'status))
      (setf is-converted-to-invoice (slot-value source 'is-converted-to-invoice))
      (setf is-cancelled (slot-value source 'is-cancelled))
      (setf cancel-reason (slot-value source 'cancel-reason))
      (setf order-type (slot-value source 'order-type))
      (setf external-url (slot-value source 'external-url))
      (setf order-source (slot-value source 'order-source))
      (setf custname (slot-value source 'custname))
      (setf tenant-id (slot-value company 'row-id))
      (setf cust-id (slot-value customer 'row-id))
      destination)))


;; PROCESS UPDATE REQUEST  
(defmethod ProcessUpdateRequest ((adapter orderAdapter) (requestmodel orderRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'orderService))
  ;; call the parent ProcessUpdate
  (call-next-method))

;; PROCESS READ ALL REQUEST.
(defmethod ProcessReadAllRequest ((adapter orderAdapter) (requestmodel orderRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'orderService))
  (call-next-method))

(defmethod doreadall ((service orderService) (requestmodel orderRequestModel))
  (let* ((cust (customer requestmodel))
	 (domainobjlst (get-orders-for-customer cust)))
    ;; return back a list of domain objects 
    (mapcar (lambda (object)
	      (let ((domainobject (make-instance 'order)))
		(copyorder-dbtodomain object domainobject))) domainobjlst)))


(defmethod CreateViewModel ((presenter orderPresenter) (responsemodel orderResponseModel))
  (let ((viewmodel (make-instance 'orderViewModel)))
    (with-slots (row-id ord-date req-date shipped-date expected-delivery-date ordnum shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship storepickupenabled gstnumber gstorgname order-fulfilled order-amt shipping-cost total-discount total-tax payment-mode comments context-id  status deleted-state is-converted-to-invoice is-cancelled cancel-reason order-type external-url order-source custname  vendor customer company created) responsemodel
      (setf (slot-value viewmodel 'vendor) vendor)
      (setf (slot-value viewmodel 'customer) customer)
      (setf (slot-value viewmodel 'row-id) row-id)
      (setf (slot-value viewmodel 'ord-date) ord-date)
      (setf (slot-value viewmodel 'req-date) req-date)
      (setf (slot-value viewmodel 'shipped-date) shipped-date)
      (setf (slot-value viewmodel 'expected-delivery-date) expected-delivery-date)
      (setf (slot-value viewmodel 'ordnum) ordnum)
      (setf (slot-value viewmodel 'shipaddr) shipaddr)
      (setf (slot-value viewmodel 'shipzipcode) shipzipcode)
      (setf (slot-value viewmodel 'shipcity) shipcity)
      (setf (slot-value viewmodel 'shipstate) shipstate)
      (setf (slot-value viewmodel 'billaddr) billaddr)
      (setf (slot-value viewmodel 'billzipcode) billzipcode)
      (setf (slot-value viewmodel 'billcity) billcity)
      (setf (slot-value viewmodel 'billstate) billstate)
      (setf (slot-value viewmodel 'billsameasship) billsameasship)
      (setf (slot-value viewmodel 'storepickupenabled) storepickupenabled)
      (setf (slot-value viewmodel 'gstnumber) gstnumber)
      (setf (slot-value viewmodel 'gstorgname) gstorgname)
      (setf (slot-value viewmodel 'order-fulfilled) order-fulfilled)
      (setf (slot-value viewmodel 'order-amt) order-amt)
      (setf (slot-value viewmodel 'shipping-cost) shipping-cost)
      (setf (slot-value viewmodel 'total-discount) total-discount)
      (setf (slot-value viewmodel 'total-tax) total-tax)
      (setf (slot-value viewmodel 'payment-mode) payment-mode)
      (setf (slot-value viewmodel 'comments) comments)
      (setf (slot-value viewmodel 'context-id) context-id)
      (setf (slot-value viewmodel 'customer) customer)
      (setf (slot-value viewmodel 'status) status)
      (setf (slot-value viewmodel 'deleted-state) deleted-state)
      (setf (slot-value viewmodel 'is-converted-to-invoice) is-converted-to-invoice)
      (setf (slot-value viewmodel 'is-cancelled) is-cancelled)
      (setf (slot-value viewmodel 'cancel-reason) cancel-reason)
      (setf (slot-value viewmodel 'order-type) order-type)
      (setf (slot-value viewmodel 'external-url) external-url)
      (setf (slot-value viewmodel 'order-source) order-source)
      (setf (slot-value viewmodel 'custname) custname)
      (setf (slot-value viewmodel 'company) company)
      (setf (slot-value viewmodel 'created) created)
      viewmodel)))
  

(defmethod ProcessResponse ((adapter orderAdapter) (busobj order))
  (let ((responsemodel (make-instance 'orderResponseModel)))
    (createresponsemodel adapter busobj responsemodel)))

(defmethod ProcessResponseList ((adapter orderAdapter) orderlist)
  (mapcar (lambda (domainobj)
	    (let ((responsemodel (make-instance 'orderResponseModel)))
	      (createresponsemodel adapter domainobj responsemodel))) orderlist))

(defmethod CreateAllViewModel ((presenter orderPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))


(defmethod CreateResponseModel ((adapter orderAdapter) (source order) (destination orderResponseModel))
  :description "source = order destination = orderResponseModel"
  (with-slots (row-id ord-date req-date shipped-date expected-delivery-date ordnum shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship storepickupenabled gstnumber gstorgname order-fulfilled order-amt shipping-cost total-discount total-tax payment-mode comments context-id  status deleted-state is-converted-to-invoice is-cancelled cancel-reason order-type external-url order-source custname  vendor customer company created) destination  
    (setf row-id (slot-value source 'row-id))
    (setf ord-date (slot-value source 'ord-date))
    (setf req-date (slot-value source 'req-date))
    (setf shipped-date (slot-value source 'shipped-date))
    (setf expected-delivery-date (slot-value source 'expected-delivery-date))
    (setf ordnum (slot-value source 'ordnum))
    (setf shipaddr (slot-value source 'shipaddr))
    (setf shipzipcode (slot-value source 'shipzipcode))
    (setf shipcity (slot-value source 'shipcity))
    (setf shipstate (slot-value source 'shipstate))
    (setf billaddr (slot-value source 'billaddr))
    (setf billzipcode (slot-value source 'billzipcode))
    (setf billcity (slot-value source 'billcity))
    (setf billstate (slot-value source 'billstate))
    (setf billsameasship (slot-value source 'billsameasship))
    (setf storepickupenabled (slot-value source 'storepickupenabled))
    (setf gstnumber (slot-value source 'gstnumber))
    (setf gstorgname (slot-value source 'gstorgname))
    (setf order-fulfilled (slot-value source 'order-fulfilled))
    (setf order-amt (slot-value source 'order-amt))
    (setf shipping-cost (slot-value source 'shipping-cost))
    (setf total-discount (slot-value source 'total-discount))
    (setf total-tax (slot-value source 'total-tax))
    (setf payment-mode (slot-value source 'payment-mode))
    (setf comments (slot-value source 'comments))
    (setf context-id (slot-value source 'context-id))
    (setf customer (slot-value source 'customer))
    (setf status (slot-value source 'status))
    (setf deleted-state (slot-value source 'deleted-state))
    (setf is-converted-to-invoice (slot-value source 'is-converted-to-invoice))
    (setf is-cancelled (slot-value source 'is-cancelled))
    (setf cancel-reason (slot-value source 'cancel-reason))
    (setf order-type (slot-value source 'order-type))
    (setf external-url (slot-value source 'external-url))
    (setf order-source (slot-value source 'order-source))
    (setf custname (slot-value source 'custname))
    (setf company (slot-value source 'company))
    destination))



(defmethod doupdate ((service orderService) (requestmodel orderRequestModel))
  (with-slots (row-id ord-date req-date shipped-date expected-delivery-date ordnum shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship storepickupenabled gstnumber gstorgname order-fulfilled order-amt shipping-cost total-discount total-tax payment-mode comments context-id  status deleted-state is-converted-to-invoice is-cancelled cancel-reason order-type external-url order-source custname  vendor customer company created) requestmodel
    (let* ((orderdbservice (make-instance 'orderDBService))
	   (orderdbobj (get-order-by-context-id context-id company))
	   (domainobj (make-instance 'order)))
    ;; FIELD UPDATE CODE STARTS HERE 
      (when orderdbobj
	(setf (slot-value orderdbobj 'row-id) row-id)
	(setf (slot-value orderdbobj 'ord-date) ord-date)
	(setf (slot-value orderdbobj 'req-date) req-date)
	(setf (slot-value orderdbobj 'shipped-date) shipped-date)
	(setf (slot-value orderdbobj 'expected-delivery-date) expected-delivery-date)
	(setf (slot-value orderdbobj 'ordnum) ordnum)
	(setf (slot-value orderdbobj 'shipaddr) shipaddr)
	(setf (slot-value orderdbobj 'shipzipcode) shipzipcode)
	(setf (slot-value orderdbobj 'shipcity) shipcity)
	(setf (slot-value orderdbobj 'shipstate) shipstate)
	(setf (slot-value orderdbobj 'billaddr) billaddr)
	(setf (slot-value orderdbobj 'billzipcode) billzipcode)
	(setf (slot-value orderdbobj 'billcity) billcity)
	(setf (slot-value orderdbobj 'billstate) billstate)
	(setf (slot-value orderdbobj 'billsameasship) billsameasship)
	(setf (slot-value orderdbobj 'storepickupenabled) storepickupenabled)
	(setf (slot-value orderdbobj 'gstnumber) gstnumber)
	(setf (slot-value orderdbobj 'gstorgname) gstorgname)
	(setf (slot-value orderdbobj 'order-fulfilled) order-fulfilled)
	(setf (slot-value orderdbobj 'order-amt) order-amt)
	(setf (slot-value orderdbobj 'shipping-cost) shipping-cost)
	(setf (slot-value orderdbobj 'total-discount) total-discount)
	(setf (slot-value orderdbobj 'total-tax) total-tax)
	(setf (slot-value orderdbobj 'payment-mode) payment-mode)
	(setf (slot-value orderdbobj 'comments) comments)
	;;(setf (slot-value orderdbobj 'context-id) \"SOMEVALUE\")
	(setf (slot-value orderdbobj 'customer) customer)
	(setf (slot-value orderdbobj 'status) status)
	(setf (slot-value orderdbobj 'deleted-state) deleted-state)
	(setf (slot-value orderdbobj 'is-converted-to-invoice) is-converted-to-invoice)
	(setf (slot-value orderdbobj 'is-cancelled) is-cancelled)
	(setf (slot-value orderdbobj 'cancel-reason) cancel-reason)
	(setf (slot-value orderdbobj 'order-type) order-type)
	(setf (slot-value orderdbobj 'external-url) external-url)
	(setf (slot-value orderdbobj 'order-source) order-source)
	(setf (slot-value orderdbobj 'custname) custname)
	(setf (slot-value orderdbobj 'company) company))
      ;;  FIELD UPDATE CODE ENDS HERE. 
    
    (setf (slot-value orderdbservice 'dbobject) orderdbobj)
    (setf (slot-value orderdbservice 'businessobject) domainobj)
    
    (setcompany orderdbservice company)
    (db-save orderdbservice)
    ;; Return the newly created UPI domain object
    (copyorder-dbtodomain orderdbobj domainobj))))


;; PROCESS THE READ REQUEST
(defmethod ProcessReadRequest ((adapter orderAdapter) (requestmodel orderRequestModel))
  :description "Adapter service method to read a single order"
  (setf (slot-value adapter 'businessservice) (find-class 'orderService))
  (call-next-method))

(defmethod doread ((service orderService) (requestmodel orderRequestModel))
  (let* ((company (company requestmodel))
	 (context-id (context-id requestmodel))
	 (dborder (get-order-by-context-id context-id company))
	 (orderobj (make-instance 'order)))
    ;; return back a Vpaymentmethod  response model
    (setf (slot-value orderobj 'company) company)
    (copyorder-dbtodomain dborder orderobj)))


(defun copyorder-dbtodomain (source destination)
  (let* ((comp (select-company-by-id (slot-value source 'tenant-id)))
	 (cust (select-customer-by-id (slot-value source 'cust-id) comp)))
    (with-slots (row-id ord-date req-date shipped-date expected-delivery-date ordnum shipaddr shipzipcode shipcity shipstate billaddr billzipcode billcity billstate billsameasship storepickupenabled gstnumber gstorgname order-fulfilled order-amt shipping-cost total-discount total-tax payment-mode comments context-id  status deleted-state is-converted-to-invoice is-cancelled cancel-reason order-type external-url order-source custname vendor customer company) destination
      (setf customer cust)
      (setf company comp)
      (setf row-id (slot-value source 'row-id))
      (setf ord-date (slot-value source 'ord-date))
      (setf req-date (slot-value source 'req-date))
      (setf shipped-date (slot-value source 'shipped-date))
      (setf expected-delivery-date (slot-value source 'expected-delivery-date))
      (setf ordnum (slot-value source 'ordnum))
      (setf shipaddr (slot-value source 'shipaddr))
      (setf shipzipcode (slot-value source 'shipzipcode))
      (setf shipcity (slot-value source 'shipcity))
      (setf shipstate (slot-value source 'shipstate))
      (setf billaddr (slot-value source 'billaddr))
      (setf billzipcode (slot-value source 'billzipcode))
      (setf billcity (slot-value source 'billcity))
      (setf billstate (slot-value source 'billstate))
      (setf billsameasship (slot-value source 'billsameasship))
      (setf storepickupenabled (slot-value source 'storepickupenabled))
      (setf gstnumber (slot-value source 'gstnumber))
      (setf gstorgname (slot-value source 'gstorgname))
      (setf order-fulfilled (slot-value source 'order-fulfilled))
      (setf order-amt (slot-value source 'order-amt))
      (setf shipping-cost (slot-value source 'shipping-cost))
      (setf total-discount (slot-value source 'total-discount))
      (setf total-tax (slot-value source 'total-tax))
      (setf payment-mode (slot-value source 'payment-mode))
      (setf comments (slot-value source 'comments))
      (setf context-id (slot-value source 'context-id))
      (setf customer (slot-value source 'customer))
      (setf status (slot-value source 'status))
      (setf deleted-state (slot-value source 'deleted-state))
      (setf is-converted-to-invoice (slot-value source 'is-converted-to-invoice))
      (setf is-cancelled (slot-value source 'is-cancelled))
      (setf cancel-reason (slot-value source 'cancel-reason))
      (setf order-type (slot-value source 'order-type))
      (setf external-url (slot-value source 'external-url))
      (setf order-source (slot-value source 'order-source))
      (setf custname (slot-value source 'custname))
      (setf company (slot-value source 'company))
      destination)))
 
(defun calculate-order-totalgst (order orderitems vendor)
  (let ((placeofsupply (slot-value vendor 'state))
	(statecode (slot-value order 'shipstate)))
    (if (equal placeofsupply statecode)
	(+ (calculate-order-totalcgst orderitems) (calculate-order-totalsgst orderitems))
	;;else
	(calculate-order-totaligst orderitems))))

(defun calculate-order-totalcgst (orderitems)
  (reduce #'+ (mapcar (lambda (item) (slot-value item 'cgstamt)) orderitems)))

(defun calculate-order-totalsgst (orderitems)
  (reduce #'+ (mapcar (lambda (item) (slot-value item 'sgstamt)) orderitems)))

(defun calculate-order-totaligst (orderitems)
  (reduce #'+ (mapcar (lambda (item) (slot-value item 'igstamt)) orderitems)))


(defun calculate-order-totalbeforetax (orderitems)
  (fround (reduce #'+ (mapcar (lambda (item) (slot-value item 'taxablevalue)) orderitems))))

(defun calculate-order-totalaftertax (orderitems)
  (fround (reduce #'+ (mapcar (lambda (item)
				(let* ((cgstamt (slot-value item 'cgstamt))
				       (sgstamt (slot-value item 'sgstamt))
				       (igstamt (slot-value item 'igstamt))
				       (taxablevalue (slot-value item 'taxablevalue)))
				  (+ taxablevalue sgstamt cgstamt igstamt))) orderitems))))

