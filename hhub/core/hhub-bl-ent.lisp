;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


;; Level 1 
;; A business server is the highest level of business abstraction on the hardware
;; level as it is tied to a single IP address 

(defclass BusinessServer () 
  ((id :accessor id
       :initform (format nil "~A" (uuid:make-v1-uuid))
       :initarg :id)
   (name
    :accessor name
    :initform "default"
    :initarg :name )
   (ipaddress
    :accessor ipadress
    :initform "127.0.0.1"
    :initarg :ipaddress)
   (businessservices-ht
    :accessor businessservices-ht
    :initform (make-hash-table :test 'equal)
    :initarg :businessservices)
   (BusinessContexts
    :accessor businesscontexts
    :initform '()
    :initarg :BusinessContexts)))

;; Level 2
;; A business context comes after Business server. Inside a business server, there will be multiple
;; business contexts. Under each logical business context, several business sessions will
;; exist. 
(defclass BusinessContext ()
  ((id :accessor id
       :initform (format nil "~A" (uuid:make-v1-uuid))
       :initarg :id)
   (name :accessor name
	 :initarg :name)
   (BusinessSessions-ht :accessor businesssessions-ht
		     :initform (make-hash-table :test 'equal)
		     :initarg :businesssessions-ht)))


;; Level 3
;; A business session comes after the business context. 
(defclass BusinessSession ()
  ((id :accessor id
       :initform (format nil "~A" (uuid:make-v1-uuid))
       :initarg :id)
   (start-time
    :accessor start-time
    :initform (get-universal-time))
   (end-time)
   (active-flag)
   (company)))



;; Level 4
;; Under a business context there will be several business object repositories. Under each
;; business object repository, there will be several business objects. 
(defclass BusinessObjectRepository () ;; Equivalent of a business objects repository
  ((id :accessor id
       :initform (format nil "~A" (uuid:make-v1-uuid))
       :initarg :id)
   (name :accessor name
	 :initarg :name)
   (BusinessObjects
    :accessor businessobjects-ht
    :initform (make-hash-table :test 'equal)
    :initarg :businessobjects-ht)))

;; Level 5
;; Each business object will have an ID and several of its own fields/properties/slots. 
(defclass BusinessObject ()  ;; This is the domain model entity in DDD
  ((id :accessor id
       :initform (format nil "~A" (uuid:make-v1-uuid))
       :initarg :id)))



(defclass RequestModel (BusinessObject)
  ((params
    :accessor params
    :initarg :params)))

(defclass ResponseModel (BusinessObject)
  ((params
    :accessor params
    :initarg :params)))

(defclass ViewModel (BusinessObject)
  ())

(defclass BusinessService ()
  ((id :accessor id
       :initform (format nil "~A" (uuid:make-v1-uuid))
       :initarg :id)
   (name :accessor name
	 :initarg :name)
   (company
    :accessor company
    :initarg :company
    :allocation :class)
   (code :accessor code
	 :initarg :code)))


(defclass AdapterService ()
  ((session
    :initarg :session
    :accessor session)
   (businessservice
    :initarg :businesservice
    :reader getbusinessservice)
   (businessservicemethod
    :initarg :businessservicemethod
    :reader getbusinessservicemethod)
  (requestmodel
   :initarg :requestmodel
   :reader getrequestmodel)
  (responsemodel
   :initarg :responsemodel
   :accessor responsemodel)
  (exception
   :accessor exception)))


(defclass PresenterService ()
  ((responsemodel
    :initarg :responsemodel
    :reader getresponsemodel)
   (viewmodel
    :initarg :viewmodel
    :reader getviewmodel)))


(defclass View ()
  ((viewmodel
    :initarg :viewmodel
    :accessor viewmodel)))

(defclass JSONView (View)
   ((jsondata 
     :accessor jsondata)))
(defclass HTMLView (View)
   ((htmldata 
     :accessor htmldata)))

(defclass DBAdapterService ()
  ((businessobject
   :accessor businessobject
   :initarg :businessobject)
   (dbobject
   :accessor dbobject
   :initarg :dbobject)
   (company
    :accessor company
    :initarg :company)
   (exception
    :accessor exception)))



;;;; Generic functions for AdapterService
(defgeneric ProcessRequest (AdapterService params)
  (:documentation "This function is responsible for initializaing the BusinessService and calling its doService method. It then creates an instance of outboundwebservice"))
(defgeneric ProcessResponse (AdapterService params)
  (:documentation "This function is responsible for converting the repository into the out parameters"))


(defgeneric ProcessCreateRequest (AdapterService RequestModel)
  (:documentation "Adapter Service method to call the BusinessService Create method"))
(defgeneric ProcessReadRequest (AdapterService RequestModel)
  (:documentation "Adapter Service method to call the BusinessService Read method"))
(defgeneric ProcessUpdateReqeust (AdapterService RequestModel) 
  (:documentation "Adapter Service method to call the BusinessService Update method"))
(defgeneric ProcessDeleteRequest (AdapterService RequestModel) 
  (:documentation "Adapter Service method to call the BusinessService Delete method"))






;;;;;; Generic functions for PresenterService
(defgeneric CreateViewModel (PresenterService ResponseModel)
  (:documentation "Converts the ResponseModel to ViewModel"))
(defgeneric Render (View ViewModel)
  (:documentation "Renders the viewmodel as View"))



;;;; Generic functions for the View
(defgeneric RenderJSON (View Viewmodel)
  (:documentation "Takes the viewmodel and converts into JSON"))
(defgeneric RenderHTML (View Viewmodel)
  (:documentation "Takes the viewmodel and converts into HTML"))


;;;;;Generic functions for Business Server ;;;;;;;;;
(defgeneric createBusinessContext (BusinessServer name)
  (:documentation "Create a business context"))
(defgeneric deleteBusinessContext (BusinessServer name)
  ( :documentation "Deletes a business context"))
(defgeneric getBusinessContext (BusinessServer name)
  (:documentation "Searches the business context by name"))

(defgeneric initBusinessServices (BusinessServer)
  (:documentation "Initialise the Business Services"))


;;;;; Generic functions for Business Context
(defgeneric createBusinessSession (BusinessContext)
  (:documentation "Creates a business session and returns the newly created session"))
(defgeneric deleteBusinessSession (BusinessContext key)
  (:documentation "Deletes the business session"))
(defgeneric getBusinessSession (BusinessContext key)
  (:documentation "Get the business session"))

;;;; Generic functions for Business Object Repository
(defgeneric addBusinessObjectRepository (BusinessSession repository)
  (:documentation "Creates a new BusinessObjectRepository and returns the instance"))
(defgeneric deleteBusinessObjectRepository (BusinessSession key)
  (:documentation "Delete the business object repository"))
(defgeneric getBusinessObjectRepository (BusinessSession key)
  (:documentation "Get the Business object repository"))

;; Generic functions for Business objects 
;;;; All CRUD operations are part of this. ;;;;;;;;;;;;;;


(defgeneric addBO (BusinessObjectRepository businessobject keyname)
  (:documentation "Reads the params and create a new BusinessObject. Return the newly created BusinessObject"))
(defgeneric getBO (BusinessObjectRepository key)
  (:documentation "Fetch the Business Object from repository."))
(defgeneric getAllBO (BusinessObjectRepository)
  (:documentation "Fetch all Business objects from the repository"))
(defgeneric deleteBO (BusinessObjectRepository key)
  (:documentation "Deletes the BusinessObject from the BusinessObjectRepository"))



;; Generic functions for Business Services
(defgeneric discoverservice (BusinessServer service-code)
  (:documentation "discover a business service based on the service-code"))
(defgeneric doService (BusinessService RequestModel)
  (:documentation "Do Service implementation for a Business Service. Takes in the BusinessSession and input params and returns back output params and exceptions if any."))
(defgeneric doCreate (BusinessService RequestModel)
  (:documentation "DoCreate service implementation for a Business Service"))


;;; Generic functions for DBAdapterService
(defgeneric init (DBAdapterService BusinessObject)
  (:documentation "Set the domain object of the DBAdapterService"))
(defgeneric setCompany (DBAdapterService company)
  (:documentation "Set the Company"))
(defgeneric setException (DBAdapterService Exception)
  (:documentation "Set the Exception for the Database Adapter Service"))
(defgeneric setDBObject (DBAdapterService dbobject)
  (:documentation "Set the DBObject"))
(defgeneric db-save (DBAdapterService)
  (:documentation "Savte the domianobject to the database"))
(defgeneric db-fetch (DBAdapterService row-id)
  (:documentation "Fetch the DBObject by row-id"))
(defgeneric db-fetch-all (DBAdapterService)
  (:documentation "Fetch records by company"))
(defgeneric db-delete (DBAdapterService)
  (:documentation "Delete the dbobject in the database"))
(defgeneric Copy-BusinessObject-To-DBObject (DBAdapterService)
  (:documentation "Syncs the dbobject and the domainobject"))
(defgeneric Copy-DbObject-To-BusinessObject (DBAdapterService)
  (:documentation "Syncs the DBobject to BusinessObject"))

(defgeneric getbusinessobject (DBAdapterService)
  (:documentation "gets the domain object"))


;;; Method implementation for Business Server 


(defmethod initBusinessServices ((bs BusinessServer))
  :description "Initialize business services"
  (let ((vpr (make-instance 'VendorProfileService))
	(vpnsr (make-instance 'VendorPushnotificationService))
	(bservices-ht (businessservices-ht bs)))
    (setf (gethash "HSRV10001" bservices-ht) vpr)
    (setf (gethash "HSRV10002" bservices-ht) vpnsr)
    "Initialized Business Services"))


(defmethod getBusinessContext ((server BusinessServer) name) 
  (let ((contexts (slot-value server 'BusinessContexts)))
    (find-if #'(lambda (ctx)
		 (equal name (slot-value ctx 'name))) contexts))) 	  

(defmethod createBusinessContext ((bs BusinessServer) name)
  :description "Creates a BusinessContext"
  (let ((ctx (make-instance 'BusinessContext))
	(list-ctx (slot-value bs 'BusinessContexts)))
    (setf (slot-value ctx 'name) name)
    ;; Add the newly created Business Context to the list of Business Contexts
    (setf (slot-value bs 'BusinessContexts) (append list-ctx (list ctx)))
    ;; return the newly created Business Context
    ctx))

(defmethod deleteBusinessContext ((bs BusinessServer) name)
  :description "Deletes a business context"
  (let ((bc (getBusinessContext bs name))
	(bc-list (businesscontexts bs)))
    (setf (slot-value bs 'businesscontexts) (remove bc bc-list))))

;;;;; Method implementations for Business Context

(defmethod createBusinessSession ((bc BusinessContext))
  :description  "Creates a business session and returns the newly created session"
  (let ((newsession (make-instance 'BusinessSession))
	(sessions-ht (businesssessions-ht bc)))
    (setf (gethash (id newsession) sessions-ht) newsession) 
    (format nil "~A" (id newsession))))
    
(defmethod deleteBusinessSession ((bctx BusinessContext) key)
  :description "Deletes the business session"
  (let ((bs-ht (businesssessions-ht bctx)))
    (remhash key bs-ht)))

(defmethod  getBusinessSession ((bctx BusinessContext) key)
  :description "Get the business session"
  (let ((sessions-ht (businesssessions-ht bctx)))
    (gethash key sessions-ht)))


;;; Method implementations for Business Session
(defmethod addBusinessObjectRepository ((bs BusinessSession) repository)
  :description "Creates a new BusinessObjectRepository and returns the instance"
  (let ((repos-ht (borepositories-ht bs)))
    (setf (gethash (id repository) repos-ht) repository)))
 
  
(defmethod  deleteBusinessObjectRepository ((bs BusinessSession) key)
  :description "Delete the business object repository"
  (let ((bs-ht (borepositories-ht bs)))
    (remhash key bs-ht)))
  
(defmethod getBusinessObjectRepository ((bs BusinessSession) key)
  :description "Get the Business object repository"
  (let ((repos-ht (borepositories-ht bs)))
    (gethash key repos-ht)))


;;;;; Method implementations for BusinessObject


(defmethod addBo ((bor BusinessObjectRepository) (busobj BusinessObject) keyname)
  (let ((bo-ht (slot-value bor 'businessobjects))
	(key (slot-value busobj (quote keyname))))
    (setf (gethash key  bo-ht) busobj)))

(defmethod getBO ((bor BusinessObjectRepository) key)
  :description "Get BO implementation"
  (let ((repo-ht (businessobjects-ht bor)))
    (gethash key repo-ht)))

(defmethod getAllBO ((bor BusinessObjectRepository))
  :description "Get all the Businessobjects"
  (let ((hash-table (slot-value bor 'BusinessObjects)))
    (maphash (lambda (key value)
	       value) hash-table)))

   
(defmethod deleteBO ((bor BusinessObjectRepository) key)
  :description "Removes the Business object form repository"
  (let ((repo-ht (businessobjects-ht bor)))
    (remhash key repo-ht)))

  
;;; Method implementation for Business Services

(defmethod discoverService ((server BusinessServer) service-code)
  (let ((bs-ht (slot-value server 'businessservices-ht)))
    (gethash service-code bs-ht)))


(defmethod doService ((bs BusinessService) params)
  :description "Will be implementd by the derived class objects")


;;; Method implementation for DBAdapterService

(defmethod init ((dbas DBAdapterService) (bo BusinessObject))
  :description "Set the domain object"
  (setf (businessobject dbas) bo))

(defmethod setcompany ((dbas DBAdapterService) company)
  (let ((dbobj (slot-value dbas 'dbobject))
	(row-id (slot-value company 'row-id)))
    ;; Set the company for the DBAdapterService
    (setf (slot-value dbas 'company) company)
    ;; Set the Tenant ID of the DB object
    (setf (slot-value dbobj 'tenant-id) row-id)))

(defmethod setException ((dbas DBAdapterService) (ex Condition))
  :description "Set the exception for the Database Adapter Service"
  (setf (slot-value dbas 'exception) ex))

(defmethod  db-save ((dbas DBAdapterService))
  :description "Save the dbobject to the database"
  ;; if the company is set for Database Adapter, only then we Save. 
  (handler-case 
      (if (company dbas) 
	  (clsql:update-records-from-instance (dbobject dbas)))
    
    (error (c)
      (let ((exceptionstr (format nil  "HHUB General Business Function Error: ~a~%"  c)))
	(with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				:direction :output
				:if-exists :supersede
				:if-does-not-exist :create)
	  (format stream "~A" exceptionstr))
	(setexception dbas c)
	;; return the exception.
	c))))



(defmethod db-fetch ((dbas DBAdapterService) row-id)
  :description  "Fetch the DBObject based on row-id"
   (format nil "Will be implemented by the derivied class objects"))

(defmethod db-fetch-all (DBAdapterService)
  :description "Fetch records by COMPANY"
  (format nil "Will be implemented by the derivied class objects"))

(defmethod db-delete ((dbas DBAdapterService))
  :description "Will be implementd by the derived class objects"
  (handler-case
      (let ((dbobject (slot-value dbas 'dbobject)))
	(setf (slot-value dbobject 'deleted-state) "Y")
	(clsql:update-record-from-slot dbobject 'deleted-state))
    (error (c)
      (let ((exceptionstr (format nil  "HHUB General Business Function Error: ~a~%"  c)))
	(with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				:direction :output
				:if-exists :supersede
				:if-does-not-exist :create)
	  (format stream "~A" exceptionstr))
	(setexception dbas c)
	;; return the exception.
	c))))
  

(defmethod syncobjects ((dbas DBAdapterService))
  :description "Will be implementd by the derived class objects"
  (format nil "Will be implemented by the derivied class objects"))


(defmethod getbusinessobject ((dbas DBAdapterService))
 :description "Return the businessobject"
 (businessobject dbas))

;; Method implementation for AdapterService 
(defmethod  ProcessRequest ((service AdapterService) params)
  :description "This method acts as a gateway for all incoming requests to HighriseHub Business layer"
  (let* ((bservicename (getbusinessservice service))
	 (bserviceinstance (make-instance bservicename))
	 (method "doservice")
	 (requestmodel (getrequestmodel service)))
    ;; Call the doservice method on the BusinessService.
    (funcall (intern (string-upcase method) :hhub) bserviceinstance requestmodel)))


(defmethod ProcessReadRequest ((service AdapterService) (requestmodel RequestModel))
  :description "This method acts as a gateway for all incoming READ requests to HighriseHub Business layer"
  (let* ((bservicename (getbusinessservice service))
	 (bserviceinstance (make-instance bservicename))
	 (method "doread")) 
    ;; Call the doread method on the BusinessService.
    (funcall (intern (string-upcase method) :hhub) bserviceinstance requestmodel)))

(defmethod ProcessCreateRequest ((service AdapterService) (requestmodel RequestModel)) 
  :description "This method acts as a gateway for all incoming CREATE requests to HighriseHub Business layer"
  (let*  ((bservicename (getbusinessservice service))
	  (bserviceinstance (make-instance bservicename))
	  (method "docreate"))
    ;; Call the docreate method on the BusinessService.
    (funcall (intern (string-upcase method) :hhub) bserviceinstance requestmodel)))
  

(defmethod ProcessDeleteRequest ((service AdapterService) (requestmodel RequestModel)) 
  :description "This method acts as a gateway for all incoming DELETE requests to HighriseHub Business layer"
  (let* ((bservicename (getbusinessservice service))
	 (bserviceinstance (make-instance bservicename))
	 (method "dodelete"))
    ;; Call the docreate method on the BusinessService.
    (funcall (intern (string-upcase method) :hhub) bserviceinstance requestmodel)))
  
