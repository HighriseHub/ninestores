;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


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

(defclass BusinessObjectNIL (BusinessObject)
  ((reason :initform "Not Found")))
(defclass BusinessObjectUnknown (BusinessObject)
  ((reason :initform "Unknown Error")))
(defclass BusinessObjectContradiction (BusinessObject)
  ((reason :initform "Conflicting Data")))

(defclass RequestModel (BusinessObject)
  ((params
    :accessor params
    :initarg :params)))

(defclass ResponseModel (BusinessObject)
  ((params
    :accessor params
    :initarg :params)))

(defclass ResponseModelNIL (ResponseModel)
  ((reason :initform "Not Found")))
(defclass ResponseModelUnknown (ResponseModel)
  ((reason  :initarg :reason :accessor rm-unknown-reason)))
(defclass ResponseModelContradiction (ResponseModel)
  ((conflicts :initarg :conflicts :accessor rm-conflicts)))

(defclass ViewModel (BusinessObject)
  ((reason :initarg :reason :accessor vm-reason)))

(defclass ViewModelNIL (ViewModel)
  ())
(defclass ViewModelUnknown (ViewModel)
  ())
(defclass ViewModelContradiction (ViewModel)
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
	 :initarg :code)
   (bo-knowledge
     :initarg :bo-knowledge
     :accessor bo-knowledge
     :initform (make-instance 'bo-knowledge)
     :documentation "Belnap knowledge for this adapter instance")))


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
   (bo-knowledge
     :initarg :bo-knowledge
     :accessor bo-knowledge
     :initform (make-instance 'bo-knowledge)
     :documentation "Belnap knowledge for this adapter instance")
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

(defclass ViewNIL (View) ())

(defclass ViewUnknown (View) ())

(defclass ViewContradiction (View) ())


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
(defgeneric TransferKnowledge (source target)
  (:documentation "Transfer BO knowledge from one adapter-layer object to another."))





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
    (funcall (intern (string-upcase method) :nstores) bserviceinstance requestmodel)))


(defmethod ProcessReadRequest ((service AdapterService) (requestmodel RequestModel))
  (let* ((bservicename (getbusinessservice service))
         (bserviceinstance (make-instance bservicename))
         (method "doread")
	 (knowledge nil)
	 (domain-object (funcall (intern (string-upcase method) :nstores)
                                 bserviceinstance requestmodel)))
    ;; Transfer the bo-knowledge from business service to adapter. 
    (transferknowledge bserviceinstance service)
    (setf knowledge (bo-knowledge service))
    (when (eq (bo-knowledge-truth knowledge) :F)
      (setf domain-object (make-instance 'BusinessObjectNIL)))
    (when (eq (bo-knowledge-truth knowledge) :U)
      (setf domain-object (make-instance 'BusinessObjectUnknown)))
    (when (eq (bo-knowledge-truth knowledge) :C)
      (setf domain-object (make-instance 'BusinessObjectContradiction)))
    domain-object))

(defmethod ProcessReadAllRequest ((service AdapterService) (requestmodel RequestModel))
  :description "This method acts as a gateway for all incoming READ requests to Nine Stores Business layer"
  (let* ((bservicename (getbusinessservice service))
	 (bserviceinstance (make-instance bservicename))
	 (method "doreadall")
	 (domain-objects (funcall (intern (string-upcase method) :nstores) bserviceinstance requestmodel)))
    (transferknowledge bserviceinstance service)
    domain-objects))


(defmethod ProcessCreateRequest ((service AdapterService) (requestmodel RequestModel)) 
  :description "This method acts as a gateway for all incoming CREATE requests to Nine Stores Business layer"
  (let*  ((bservicename (getbusinessservice service))
	  (bserviceinstance (make-instance bservicename))
	  (method "docreate")
	  (domain-object (funcall (intern (string-upcase method) :nstores) bserviceinstance requestmodel)))
    (transferknowledge bserviceinstance service)
    domain-object))
  

(defmethod ProcessDeleteRequest ((service AdapterService) (requestmodel RequestModel)) 
  :description "This method acts as a gateway for all incoming DELETE requests to Nine Stores Business layer"
  (let* ((bservicename (getbusinessservice service))
	 (bserviceinstance (make-instance bservicename))
	 (method "dodelete"))
    ;; Call the docreate method on the BusinessService.
    (funcall (intern (string-upcase method) :nstores) bserviceinstance requestmodel)))
  

(defmethod ProcessUpdateRequest ((service AdapterService) (requestmodel RequestModel))
  :description "This method acts as a gateway for all the incoming UPDATE requests to Nine Stores Business Layer."
  (let* ((bservicename (getbusinessservice service))
	 (bserviceinstance (make-instance bservicename))
	 (method "doupdate")
	 (domain-object (funcall (intern (string-upcase method) :nstores) bserviceinstance requestmodel)))

    (transferknowledge bserviceinstance service)
    domain-object))

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

(defmethod TransferKnowledge ((source t) (target t))
  ;; Only proceed if BOTH objects have a :knowledge slot
  (when (and (slot-exists-p source 'bo-knowledge)
             (slot-exists-p target  'bo-knowledge))
    (setf (bo-knowledge target) (bo-knowledge source)))
  target)

(defmethod ProcessResponse ((adapter AdapterService) (busobj BusinessObjectNIL))
  (let ((responsemodel (make-instance 'ResponseModelNIL)))
    (setf responsemodel (createresponsemodel adapter busobj responsemodel))
    responsemodel))

(defmethod CreateResponseModel ((adapter AdapterService) (source BusinessObjectNIL) (destination ResponseModelNIL))
  (with-slots (reason) destination  
    (setf reason (slot-value source 'reason))
    destination))

(defmethod CreateViewModel ((presenter PresenterService) (responsemodel ResponseModelNIL))
  (let ((viewmodel (make-instance 'ViewModelNIL)))
    (with-slots (reason) viewmodel
      (setf reason (slot-value responsemodel 'reason))
    viewmodel)))

(defmethod render ((view ViewNIL) (vm ViewModelNIL))
  (let* ((payload (list (cons "data" "NIL")))
         (jsondata (json:encode-json-to-string
                    `(("success" . 0)
                      ("failure" . 1)
                      ("truth"   . "NIL")
                      ("payload" . ,payload)))))
    jsondata))


(defmethod ProcessResponse ((adapter AdapterService) (busobj BusinessObjectUnknown))
  (let ((responsemodel (make-instance 'ResponseModelUnknown)))
    (setf responsemodel (createresponsemodel adapter busobj responsemodel))
    responsemodel))

(defmethod CreateResponseModel ((adapter AdapterService) (source BusinessObjectUnknown) (destination ResponseModelUnknown))
  (with-slots (reason) destination  
    (setf reason (slot-value source 'reason))
    destination))

(defmethod CreateViewModel ((presenter PresenterService) (responsemodel ResponseModelUnknown))
  (let ((viewmodel (make-instance 'ViewModelUnknown)))
    viewmodel))

(defmethod render ((view ViewUnknown) (vm ViewModelUnknown))
  (let* ((payload (list (cons "data" "Unknown Error")))
         (jsondata (json:encode-json-to-string
                    `(("success" . 0)
                      ("failure" . 1)
                      ("truth"   . "Unknown Error")
                      ("payload" . ,payload)))))
    jsondata))


(defmethod ProcessResponse ((adapter AdapterService) (busobj BusinessObjectContradiction))
  (let ((responsemodel (make-instance 'ResponseModelContradiction)))
    (setf responsemodel (createresponsemodel adapter busobj responsemodel))
    responsemodel))

(defmethod CreateResponseModel ((adapter AdapterService) (source BusinessObjectContradiction) (destination ResponseModelContradiction))
  (with-slots (reason) destination  
    (setf reason (slot-value source 'reason))
    destination))

(defmethod CreateViewModel ((presenter PresenterService) (responsemodel ResponseModelContradiction))
  (let ((viewmodel (make-instance 'ViewModelContradiction)))
    viewmodel))

(defmethod render ((view ViewContradiction) (vm ViewModelContradiction))
  (let* ((payload (list (cons "data" "Contradiction in data")))
         (jsondata (json:encode-json-to-string
                    `(("success" . 0)
                      ("failure" . 1)
                      ("truth"   . "Contradiction in data")
                      ("payload" . ,payload)))))
    jsondata))
