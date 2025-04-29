;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


;; Level 1 
;; A business server is the highest level of business abstraction on the hardware
;; level as it is tied to a single IP address 

(defclass BusinessServer () 
  ((id :reader id
       :initform (format nil "~A" (uuid:make-v1-uuid)))
   (name
    :accessor name
    :initform "default"
    :initarg :name )
   (ipaddress
    :accessor ipadress
    :initform "127.0.0.1"
    :initarg :ipaddress)
   (borepositories-ht
    :accessor borepositories-ht
    :initform (make-hash-table :test 'equal)
    :initarg :borepositories-ht)
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
;; A business session comes after the business context. Sessions are on an organization level or company level.  
(defclass BusinessSession ()
  ((id :accessor id
       :initform (format nil "~A" (uuid:make-v1-uuid))
       :initarg :id)
   (start-time
    :accessor start-time
    :initform (get-universal-time))))

(defclass VendorSessionObject (BusinessSession)
  ((vendor)
   (vendor-id)
   (vendor-tenant-id)
   (vendor-name)
   (company)
   (companyname)
   (vendortenants)
   (vorderfunclist)
   (vorderitems)
   (vproductfunclist)
   (vwebsession)))

(defclass UserSessionObject (BusinessSession)
  ((user)
   (user-id)
   (user-tenant-id)
   (user-name)
   (company)
   (companyname)
   (uorderfunclist)
   (uorderitems)
   (uproductfunclist)
   (uwebsession)))
   
  

;; Level 2
;; Under a business server there will  be several business object repositories. Under each
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

;; Level 3
;; Each business object will have an ID and several of its own fields/properties/slots. 
(defclass BusinessObject ()  ;; This is the domain model entity in DDD
  ((id :accessor id
       :initform (format nil "~A" (uuid:make-v1-uuid))
       :initarg :id)
   (ipaddress
    :accessor ipadress
    :initform "127.0.0.1"
    :initarg :ipaddress)))



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



;; DB Adapter service

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


;;; Generic functions for DBAdapterService
(defgeneric init (DBAdapterService BusinessObject)
  (:documentation "Set the domain object of the DBAdapterService"))
(defgeneric init (ResponseModel BusinessObject)
  (:documentation "Set the domain object of the ResponseModel "))

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



;;;; Generic functions for AdapterService
(defgeneric ProcessRequest (AdapterService params)
  (:documentation "This function is responsible for initializaing the BusinessService and calling its doService method. It then creates an instance of outboundwebservice"))
(defgeneric ProcessResponse (AdapterService params)
  (:documentation "This function is responsible for converting the repository into the out parameters"))
(defgeneric ProcessResponse (AdapterService BusinessObject)
  (:documentation "This function is responsible for converting the business object into a responsemodel "))
(defgeneric ProcessResponseList (AdapterService list)
  (:documentation "This function is responsible for converting the business objects into a responsemodel list "))

(defgeneric CreateResponseModel (AdapterService BusinessObject ResponseModel)
  (:documentation "Creates a responsemodel from businessobject"))

(defgeneric ProcessCreateRequest (AdapterService RequestModel)
  (:documentation "Adapter Service method to call the BusinessService Create method"))
(defgeneric ProcessReadRequest (AdapterService RequestModel)
  (:documentation "Adapter Service method to call the BusinessService Read method"))
(defgeneric ProcessReadAllRequest (AdapterService RequestModel)
  (:documentation "Adapter Service method to call the BusinessService Read method"))
(defgeneric ProcessUpdateRequest (AdapterService RequestModel) 
  (:documentation "Adapter Service method to call the BusinessService Update method"))
(defgeneric ProcessDeleteRequest (AdapterService RequestModel) 
  (:documentation "Adapter Service method to call the BusinessService Delete method"))






;;;;;; Generic functions for PresenterService
(defgeneric CreateViewModel (PresenterService ResponseModel)
  (:documentation "Converts the ResponseModel to ViewModel"))
(defgeneric CreateAllViewModel (PresenterService list)
  (:documentation "Converts the ResponseModel to ViewModel"))
(defgeneric Render (View ViewModel)
  (:documentation "Renders the viewmodel as View"))
(defgeneric RenderListViewHTML (HTMLView list)
  (:documentation "Renders a list view"))
(defgeneric RenderTileViewHTML (HTMLView list)
  (:documentation "Renders a list as tiles"))
(defgeneric RenderJSONAll (JSONView list)
  (:documentation "Renders a list as JSON"))


;;;; Generic functions for the View
(defgeneric RenderJSON (JSONView Viewmodel)
  (:documentation "Takes the viewmodel and converts into JSON"))
(defgeneric RenderHTML (HTMLView Viewmodel)
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
(defgeneric createBusinessSession (BusinessContext sessionobject)
  (:documentation "Creates a business session and returns the newly created session"))
(defgeneric deleteBusinessSession (BusinessContext key)
  (:documentation "Deletes the business session on a given key"))
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
(defgeneric doRead (BusinessService RequestModel)
  (:documentation "DoCreate service implementation for a Business Service"))
(defgeneric doReadall (BusinessService RequestModel)
  (:documentation "DoCreate service implementation for a Business Service"))
(defgeneric doUpdate (BusinessService RequestModel)
  (:documentation "DoCreate service implementation for a Business Service"))
(defgeneric doDelete (BusinessService RequestModel)
  (:documentation "DoCreate service implementation for a Business Service"))


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

(defmethod createBusinessSession ((bc BusinessContext) sessionobject)
  :description  "Creates a business session and returns the newly created session"
  (let ((sessions-ht (businesssessions-ht bc)))
    (setf (gethash (id sessionobject) sessions-ht) sessionobject) 
    (id sessionobject)))
    
(defmethod deleteBusinessSession ((bctx BusinessContext) key)
  :description "Deletes the business session"
  (let ((bs-ht (businesssessions-ht bctx)))
    (remhash key bs-ht)
    ;;(logiamhere (format nil "removing key ~A Size of business sessions hashtable is ~A" key (hash-table-size bs-ht)))
    ))

(defmethod  getBusinessSession ((bctx BusinessContext) key)
  :description "Get the business session"
  (let ((sessions-ht (businesssessions-ht bctx)))
    (gethash key sessions-ht)))


;;; Method implementations for Business Session
(defmethod addBusinessObjectRepository ((bs BusinessSession) repository)
  :description "Creates a new BusinessObjectRepository and returns the instance"
  (let ((repos-ht (businessobjectrepos-ht bs)))
    (setf (gethash (id repository) repos-ht) repository)))
 
  
(defmethod  deleteBusinessObjectRepository ((bs BusinessSession) key)
  :description "Delete the business object repository"
  (let ((bs-ht (businessobjectrepos-ht bs)))
    (remhash key bs-ht)))
  
(defmethod getBusinessObjectRepository ((bs BusinessSession) key)
  :description "Get the Business object repository"
  (let ((repos-ht (businessobjectrepos-ht bs)))
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
	       (if key value)) hash-table)))

   
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
  (setf (businessobject dbas) bo)
  (setf (slot-value (dbobject dbas) 'deleted-state) "N"))

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
      (when (company dbas) 
	;; when saving to database from another thread, there should be no logging messages. 
	;;(hunchentoot:log-message* :info (format nil "Company is ~A" (slot-value (slot-value dbas 'company) 'name)))
	;;(hunchentoot:log-message* :info (format nil "DB obj amount is ~A" (slot-value (slot-value dbas 'dbobject) 'amount)))
	;;(logiamhere  "I am going to db save now")
	(clsql:update-records-from-instance (dbobject dbas)))

    (error (condition)
	  (let ((exceptionstr (format nil  "Database Error:~A: ~a~%" (mysql-now) condition)))
	    (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				    :direction :output
				    :if-exists :append
				    :if-does-not-exist :create)
	      (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
	    ;; return the exception.
	    (error 'hhub-database-error :errstring exceptionstr)))))
 


(defmethod db-fetch ((dbas DBAdapterService) row-id)
  :description  "Fetch the DBObject based on row-id"
   (format nil "Will be implemented by the derivied class objects"))

(defmethod db-fetch-all (DBAdapterService)
  :description "Fetch records by COMPANY"
  (format nil "Will be implemented by the derivied class objects"))

(defmethod db-delete ((dbas DBAdapterService))
  :description "Will be implementd by the derived class objects"
  (handler-case
      (when (company dbas) 
	(let ((dbobject (slot-value dbas 'dbobject)))
	  (setf (slot-value dbobject 'deleted-state) "Y")
	  (clsql:update-record-from-slot dbobject 'deleted-state)))
    (error (condition)
      (let ((exceptionstr (format nil  "Database Error:~A: ~a~%" (mysql-now) condition)))
	(with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				:direction :output
				:if-exists :append
				:if-does-not-exist :create)
	  (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
	;; return the exception.
	(error 'hhub-database-error :errstring exceptionstr)))))
  

(defmethod syncobjects ((dbas DBAdapterService))
  :description "Will be implementd by the derived class objects"
  (format nil "Will be implemented by the derivied class objects"))


(defmethod getbusinessobject ((dbas DBAdapterService))
 :description "Return the businessobject"
 (businessobject dbas))

;; Method implementation for AdapterService 
(defmethod  ProcessRequest ((service AdapterService) params)
  :description "This method acts as a gateway for all incoming requests to Nine Stores Business layer"
  (let* ((bservicename (getbusinessservice service))
	 (bserviceinstance (make-instance bservicename))
	 (method "doservice")
	 (requestmodel (getrequestmodel service)))
    ;; Call the doservice method on the BusinessService.
    (funcall (intern (string-upcase method) :hhub) bserviceinstance requestmodel)))


(defmethod ProcessReadRequest ((service AdapterService) (requestmodel RequestModel))
  :description "This method acts as a gateway for all incoming READ requests to Nine Stores Business layer"
  (let* ((bservicename (getbusinessservice service))
	 (bserviceinstance (make-instance bservicename))
	 (method "doread")) 
    ;; Call the doread method on the BusinessService.
    (funcall (intern (string-upcase method) :hhub) bserviceinstance requestmodel)))

(defmethod ProcessReadAllRequest ((service AdapterService) (requestmodel RequestModel))
  :description "This method acts as a gateway for all incoming READ requests to Nine Stores Business layer"
  (let* ((bservicename (getbusinessservice service))
	 (bserviceinstance (make-instance bservicename))
	 (method "doreadall")) 
    ;; Call the doread method on the BusinessService.
    (funcall (intern (string-upcase method) :hhub) bserviceinstance requestmodel)))


(defmethod ProcessCreateRequest ((service AdapterService) (requestmodel RequestModel)) 
  :description "This method acts as a gateway for all incoming CREATE requests to Nine Stores Business layer"
  (let*  ((bservicename (getbusinessservice service))
	  (bserviceinstance (make-instance bservicename))
	  (method "docreate"))
    ;; Call the docreate method on the BusinessService.
    (funcall (intern (string-upcase method) :hhub) bserviceinstance requestmodel)))
  

(defmethod ProcessDeleteRequest ((service AdapterService) (requestmodel RequestModel)) 
  :description "This method acts as a gateway for all incoming DELETE requests to Nine Stores Business layer"
  (let* ((bservicename (getbusinessservice service))
	 (bserviceinstance (make-instance bservicename))
	 (method "dodelete"))
    ;; Call the docreate method on the BusinessService.
    (funcall (intern (string-upcase method) :hhub) bserviceinstance requestmodel)))
  

(defmethod ProcessUpdateRequest ((service AdapterService) (requestmodel RequestModel))
  :description "This method acts as a gateway for all the incoming UPDATE requests to Nine Stores Business Layer."
  (let* ((bservicename (getbusinessservice service))
	 (bserviceinstance (make-instance bservicename))
	 (method "doupdate"))
    ;; Call the doupdate method on the BusinessService.
    (funcall (intern (string-upcase method) :hhub) bserviceinstance requestmodel)))
  



(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-entity-create (adaptername requestmodel &body body)
    :description "Creates a business entity when provided with a adapter name and requestmodel"
    `(let* ((adapter (make-instance ,adaptername))
	    (entity (ProcessCreateRequest adapter ,requestmodel)))
       ;; create the entity in the Database and return back the business object. 
       ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-entity-readall (adaptername requestmodel &body body)
    `(let* ((adapter (make-instance ,adaptername))
	    (allentities (ProcessReadallRequest adapter ,requestmodel)))
      ;; Read the entity from the database and return back a list of business objects
       ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-entity-read (adaptername requestmodel &body body)
    `(let* ((adapter (make-instance ,adaptername))
	    (entity (ProcessReadRequest adapter ,requestmodel)))
       ;; Read the entity from the database adn return back a single business object.
       ,@body)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-entity-update (adaptername requestmodel &body body)
    `(let* ((adapter (make-instance ,adaptername))
	    (entity (ProcessUpdateRequest adapter ,requestmodel)))
       ;; Read the entity from the database adn return back a single business object.
       ,@body)))

