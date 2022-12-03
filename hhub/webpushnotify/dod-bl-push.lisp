;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(defmethod ProcessDeleteRequest ((adapter VendorWebPushNotifyAdapter) (requestmodel RequestDeleteWebPushNotifyVendor))
  :description "This method is responsible for Deleting a web push notification record for a given vendor"
  ;; Set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'VendorWebPushNotifyService))
  (call-next-method))

(defmethod doDelete ((service VendorWebPushNotifyService) (requestmodel RequestDeleteWebPushNotifyVendor))
  :description "This method is responsible for Deleting a Web push notification subscription for a given vendor"
  (let* ((vendor (vendor requestmodel))
	 (webpushdbservice (make-instance 'WebPushNotifyDBService))
	 (subscription (db-fetch-Vendor-WebPushNotifySubscriptions webpushdbservice vendor)))
    (setf (dbobject webpushdbservice) subscription)
    ;; Delete the record
    (db-delete webpushdbservice)))
    	

(defmethod ProcessCreateRequest ((adapter VendorWebPushNotifyAdapter)  (requestmodel RequestCreateWebPushNotifyVendor))
  :description "This method is responsible for Creating a web push request"
  ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'VendorWebPushNotifyService))                                                                                                                     
  ;; call the parent ProcessCreate
  (call-next-method))

    
(defmethod doCreate ((service VendorWebPushNotifyService) (requestmodel RequestCreateWebPushNotifyVendor))
  (let* ((vendor (slot-value requestmodel 'vendor))
	 (webpushdbservice (make-instance 'WebPushNotifyDBService))
	 (ep (endpoint requestmodel))
	 (auth (auth requestmodel))
	 (pkey (publickey requestmodel))
	 (browser-name "chrome")
	 (webpushnotifyobj (make-instance 'WebPushNotifyVendor
					  :vendor vendor
					  :endpoint ep
					  :publickey pkey
					  :auth auth 
					  :browser-name browser-name 
					  :perm-granted "Y"
					  :expired "N")))
    
    ;; Initialize the DB Service
    (init webpushdbservice webpushnotifyobj)
    (copy-businessobject-to-dbobject webpushdbservice)
    (db-save webpushdbservice)))
  
(defmethod CreateViewModel ((service GetWebPushNotifyVendorPresenter) (responsemodel ResponseGetWebPushNotifyVendor))
  (let ((viewmodel (make-instance 'GetWebPushNotifyVendorViewModel)))
    (with-slots (endpoint) responsemodel
      (setf (slot-value viewmodel 'endpoint) endpoint)
      ;;return the viewmodel
      (setf (slot-value service 'viewmodel) viewmodel)
      viewmodel)))


(defmethod ProcessResponse ((service VendorWebPushNotifyAdapter)  params)
  (let* ((webpushsubscription (cdr (assoc "webpushsubscription" params :test 'equal)))
	 (responsemodel (make-instance 'ResponseGetWebPushNotifyVendor
				       :endpoint "")))
    (if webpushsubscription
	(copywebpushnotification webpushsubscription responsemodel))
    ;; return the responsemodel
    responsemodel))


(defmethod doRead ((service VendorWebPushNotifyService) requestmodel)
  (let* ((vendor (slot-value requestmodel 'vendor))
	 (webpushdbservice (make-instance 'WebPushNotifyDBService))
	 (subscription (db-fetch-Vendor-WebPushNotifySubscriptions webpushdbservice vendor)))
    subscription))


(defmethod ProcessReadRequest ((adapter VendorWebPushNotifyAdapter)  (requestmodel RequestGetWebPushNofityVendor))
  :description "This function is responsible for initializaing the BusinessService and calling its doService method. It then creates an instance of outboundwebservice"
  (setf (slot-value adapter 'businessservice) (find-class 'VendorWebPushNotifyService))
  (setf (slot-value adapter 'requestmodel) requestmodel)
  
  (let ((webpushsubscription (call-next-method))
	(params nil)) 
    (setf params (acons "webpushsubscription" webpushsubscription params))
    (processresponse adapter params)))



(defmethod db-fetch-Vendor-WebPushNotifySubscriptions ((dbas WebPushNotifyDBService) vendor)  
  (let* ((vendor-id (slot-value vendor 'row-id))
	 (company (vendor-company vendor)) 
	 (tenant-id (slot-value company 'row-id))
	 (db-vendorpushsub (car (clsql:select 'dod-webpush-notify :where
					 [and
					 [= [:deleted-state] "N"]
					 [= [:active-flag] "Y"]
					 [= [:vendor-id] vendor-id]
					 [= [:person-type] "VENDOR"]
					 [= [:tenant-id] tenant-id]] :caching *dod-database-caching* :flatp T))))
    db-vendorpushsub))


(defmethod db-fetch-Customer-WebPushNotifySubscriptions ((dbas WebPushNotifyDBService) customer)  
  (let* ((cust-id (slot-value customer 'row-id))
	 (company (customer-company customer)) 
	 (tenant-id (slot-value company 'row-id))
	 (db-customerpushsubs (clsql:select 'dod-webpush-notify :where
					 [and
					 [= [:deleted-state] "N"]
					 [= [:active-flag] "Y"]
					 [= [:cust-id] cust-id]
					 [= [:person-type] "CUSTOMER"]
					 [= [:tenant-id] tenant-id]] :caching *dod-database-caching* :flatp NIL)))
    db-customerpushsubs))


(defmethod db-fetch ((dbas WebPushNotifyDBService) row-id)
  :description  "Fetch the DBObject based on row-id"
  (let* ((tenant-id (slot-value dbas 'tenant-id))
	 (dbobj (clsql:select 'dod-webpush-notify :where
				      [and
				      [= [:deleted-state] "N"]
				      [= [:active-flag] "Y"]
				      [= [:tenant-id] tenant-id]
				      [= [:row-id] row-id]] :caching *dod-database-caching* :flatp t)))
    (setf (slot-value dbas 'dbobject) dbobj)))

(defmethod db-fetch-all ((dbas WebPushNotifyDBService))
  :description "Fetch records by COMPANY"
  (let* ((tenant-id (slot-value dbas 'tenant-id))
	 (dbobjs (clsql:select 'dod-webpush-notify :where
				      [and
				      [= [:deleted-state] "N"]
				      [= [:active-flag] "Y"]
				      [= [:tenant-id] tenant-id]] :caching *dod-database-caching* :flatp t)))
    dbobjs))

(defmethod Copy-BusinessObject-To-DBObject ((dbas WebPushNotifyDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(webpushobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copywebpushnotification webpushobj dbobj))))

 
(defun copywebpushnotification (source destination)
    (with-slots (browser-name endpoint publickey auth perm-granted expired) destination
      (setf browser-name (slot-value source 'browser-name))
      (setf endpoint (slot-value source 'endpoint))
      (setf publickey  (slot-value source 'publickey ))
      (setf auth (slot-value source 'auth))
      (setf perm-granted (slot-value source 'perm-granted))
      (setf expired (slot-value source 'expired))
      destination))


(defmethod Copy-DbObject-To-BusinessObject ((dbas WebPushNotifyDBService))
 (let ((dbobj (slot-value dbas 'dbobject))
	(webpushobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'webpushobj) (copywebpushnotification dbobj webpushobj))))
 

(defmethod init ((dbas WebPushNotifyDBService) (bo WebPushNotifyVendor))
  :description "Set the DB object and domain object"
  (let* ((vendor (vendor bo))
	 (vendor-id (slot-value vendor 'row-id))
	 (webpushnotifyDBobj (make-instance 'dod-webpush-notify
					    :cust-id nil
					    :vendor-id vendor-id
					    :person-type "VENDOR"
					    :active-flag "Y"
					    :expired "N"
					    :deleted-state "N")))
   
    ;; Fetch already existing subscriptions for the vendor if any. 
    (let* ((previoussub (db-fetch-Vendor-WebPushNotifySubscriptions dbas vendor)))
      (unless previoussub
	(setf (slot-value dbas 'dbobject) webpushnotifyDBobj)
	 ;; Set the company context for the web push notification DB service 
	(setcompany dbas (vendor-company vendor))
	(call-next-method))
      (when previoussub
	(error 'hhub-webpush-subscription-exists :errstring (format nil "Web Push Subscription for vendor: ~A, already exists" (name vendor)))))))

    
	  

(defmethod init ((dbas WebPushNotifyDBService) (bo WebPushNotifyCustomer))
  :description "Set the DB object and domain object"
  (let* ((customer (customer bo))
	(cust-id (slot-value customer 'row-id))
	(webpushnotifyDBobj (make-instance 'dod-webpush-notify
					   :vendor-id nil
					   :cust-id cust-id
					   :person-type "CUSTOMER"
					   :active-flag "Y"
					   :deleted-state "N")))

        ;; Fetch already existing subscriptions for the vendor if any. 
    (let* ((previoussub (car (db-fetch-Customer-WebPushNotifySubscriptions dbas customer))))
      (unless previoussub
	(setf (dbobject dbas) webpushnotifyDBobj)
	;; Set the company context for the web push notification DB service 
	(setcompany dbas (customer-company customer))
	(call-next-method))
      (when previoussub
	(error 'hhub-webpush-subscription-exists :errstring (format nil "Web Push Subscription for vendor: ~A, already exists" (name customer)))))))


(defun persist-push-notify-subscription(cust-id vendor-id person-type endpoint publickey auth  browser-name created-by tenant-id)
  (clsql:update-records-from-instance (make-instance 'dod-webpush-notify
							 :cust-id cust-id
							 :vendor-id vendor-id
							 :person-type person-type 
							 :endpoint endpoint
							 :publickey publickey
							 :auth auth 
							 :browser-name browser-name 
							 :perm-granted "Y"
							 :expired "N"
							 :tenant-id tenant-id
							 :active-flag "Y"
							 :created-by created-by
							 :deleted-state "N")))
  



(defun create-push-notify-subscription-for-customer (params)
   (let* ((customer (cdr (assoc "customer" params :test 'equal)))
	 (endpoint (cdr (assoc "endpoint" params :test 'equal)))
	 (publickey (cdr (assoc "publickey" params :test 'equal)))
	 (auth (cdr (assoc "auth" params :test 'equal)))
	 (browser-name (cdr (assoc "browser-name" params :test 'equal)))
	 (created-by (cdr (assoc "created-by" params :test 'equal)))
	 (tenant-id (cdr (assoc "tenant-id" params :test 'equal)))
	 (cust-id (if customer (slot-value customer 'row-id)))
	 (user-id (slot-value created-by 'row-id)))
     ;Here we are going to call the DB layer. We will call the DB Adapter here in future. 
     (persist-push-notify-subscription cust-id nil "CUSTOMER" endpoint publickey auth browser-name user-id tenant-id)))



  

(defun com-hhub-businessfunction-bl-createpushnotifysubscriptionforvendor (params)
  :documentation "Business layer function to create the push notification subscriptions for a given vendor. This function is responsible for creating the push notify subscription for vendor and save it current business session for further requirement within the session."
  (let ((datastoragein (cdr (assoc "data-storage-in" params :test 'equal))))
    (if (equal datastoragein "tempstorage") 
	(let ((returnlist (hhub-execute-business-function "com.hhub.businessfunction.tempstorage.createpushnotifysubscriptionforvendor" params)))
	  (if (null (nth 1 returnlist))
	      (nth 0 returnlist) ; return this value 
	      ;; else if condition is signalled
	      (error 'hhub-business-function-error :errstring "Error during vendor subscription create in temporary storage")))
					;else data is stored in database
	(let ((returnlist (hhub-execute-business-function  "com.hhub.businessfunction.db.createpushnotifysubscriptionforvendor" params)))
	  (if (null (nth 1 returnlist))
	      (nth 0 returnlist) ; return this value
	      ;; else if condition is signalled
	      (error 'hhub-business-function-error :errstring "Error during vendor subscription create in  database."))))))



(defun com-hhub-business-function-db-getpushnotifysubscriptionforvendor  (params)
:documentation "This function will create push notify subscription in a temporary storage." 
  (if params 
      (error 'hhub-business-function-error :errstring "Function not implemented")))


    

(defun delete-subscriptions ( list)
  (mapcar (lambda (object)
		(setf (slot-value object 'deleted-state) "Y")
		(clsql:update-record-from-slot object  'deleted-state)) list ))


(defun remove-webpush-subscription (params)
  (let ((subscription-list (cdr (assoc "subscription-list" params :test 'equal))))
  (delete-subscriptions subscription-list)))

(defun get-push-notify-subscription-for-customer (params)
  (let* ((customer (cdr (assoc "customer" params :test 'equal)))
	 (cust-id (slot-value customer 'row-id))
	 (tenant-id (slot-value customer 'tenant-id)))
    (clsql:select 'dod-webpush-notify :where
		  [and
		  [= [:deleted-state] "N"]
		  [= [:active-flag] "Y"]
		  [= [:cust-id] cust-id]
		  [= [:person-type] "CUSTOMER"]
		  [= [:tenant-id] tenant-id]] :caching *dod-database-caching* :flatp t)))



(defun com-hhub-businessfunction-bl-getpushnotifysubscriptionforvendor (params)
  :documentation "Business layer function to get the push notification subscriptions for a given vendor. This function will act like a proxy and pass on the params to DB layer function."
  (let ((datastoragein (cdr (assoc "data-storage-in" params :test 'equal))))
    (if (equal datastoragein "tempstorage") 
	(let ((returnlist (hhub-execute-business-function "com.hhub.businessfunction.tempstorage.getpushnotifysubscriptionforvendor" params)))
	  (if (null (nth 1 returnlist))
	      (nth 0 returnlist) ; return this value 
	      ;; else if condition is signalled
	      (error 'hhub-business-function-error :errstring "Error during vendor subscription fetch from temporary storage")))
					;else data is stored in database
	(let ((returnlist (hhub-execute-business-function  "com.hhub.businessfunction.db.getpushnotifysubscriptionforvendor" params)))
	  (if (null (nth 1 returnlist))
	      (nth 0 returnlist) ; return this value
	      ;; else if condition is signalled
	      (error 'hhub-business-function-error :errstring "Error during vendor subscription fetch from database."))))))
	  
(defun com-hhub-businessfunction-db-getpushnotifysubscriptionforvendor (params)
  :documentation "This function will fetch the push notify subscription from Database"
  (let* ((vendor (cdr (assoc "vendor" params :test 'equal)))
	 (vendor-id (slot-value vendor  'row-id))
	 (tenant-id (slot-value vendor 'tenant-id))
	 (exceptions nil)
	 (returnvalues  (clsql:select 'dod-webpush-notify :where
				      [and
				      [= [:deleted-state] "N"]
				      [= [:active-flag] "Y"]
				      [= [:vendor-id] vendor-id]
				      [= [:person-type] "VENDOR"]
				      [= [:tenant-id] tenant-id]] :caching *dod-database-caching* :flatp t)))
	(values returnvalues exceptions)))
   

(defun com-hhub-business-function-tempstorage-getpushnotifysubscriptionforvendor  (params)
:documentation "This function will fetch the push notify subscription from a temporary storage." 
  (if params 
      (error 'hhub-business-function-error :errstring "Function not implemented")))



