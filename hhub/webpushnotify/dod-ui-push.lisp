;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)
  

(defun hhub-controller-get-vendor-push-subscription ()
  (with-vend-session-check
    (let* ((vendor (get-login-vendor))
	   (webpushadapter (make-instance 'VendorWebPushNotifyAdapter))
	   (requestmodel (make-instance 'RequestGetWebPushNofityVendor))
	   (presenter (make-instance 'GetWebPushNotifyVendorPresenter))
	   (jsonview (make-instance 'JSONView)))
      
    (setf (slot-value requestmodel 'vendor) vendor)
    (render jsonview (createviewmodel presenter (processreadrequest webpushadapter requestmodel))))))

(defmethod Render ((view JSONView) (viewmodel GetWebPushNotifyVendorViewModel))
  (let* ((templist '())
	 (appendlist '())
	 (mylist '())
	 (endpoint (slot-value viewmodel 'endpoint)))
	
    (if endpoint
	(progn
	(setf templist (acons "endpoint" (format nil "~A" endpoint) templist))
	(setf appendlist (append appendlist (list templist)))
	(setf mylist (acons "result" appendlist mylist))
	(setf mylist (acons "success" 1 mylist))
	(let ((jsondata (json:encode-json-to-string mylist)))
	  (setf (slot-value view 'jsondata) jsondata)
	  ;; return jsondata
	  jsondata))
					;else 
      (progn
	(setf mylist (acons "success" 0 mylist))
 	(let ((jsondata (json:encode-json-to-string mylist)))
	  (setf (slot-value view 'jsondata) jsondata)
	  jsondata)))))


(defun hhub-save-customer-push-subscription ()
  (let ((endpoint (hunchentoot:parameter "notificationEndPoint"))
	(publicKey (hunchentoot:parameter "publicKey"))
	(auth (hunchentoot:parameter "auth"))
	(params nil))
	
    (setf params (acons "customer" (get-login-customer) params))
    (setf params (acons "endpoint" endpoint params))
    (setf params (acons "publickey" publickey params))
    (setf params (acons "auth" auth params))
    (setf params (acons "browser-name" "chrome" params))
    (setf params (acons "created-by" (select-user-by-id 1 1) params))
    (setf params (acons "tenant-id" (get-login-cust-tenant-id) params))

    (hhub-business-adapter 'create-push-notify-subscription-for-customer params)
    "Subscription Accepted"))


(defun hhub-controller-save-vendor-push-subscription-old ()
  (let ((endpoint (hunchentoot:parameter "notificationEndPoint"))
	(publicKey (hunchentoot:parameter "publicKey"))
	(auth (hunchentoot:parameter "auth"))
	(params nil))
	
    (setf params (acons "endpoint" endpoint params))
    (setf params (acons "publickey" publickey params))
    (setf params (acons "auth" auth params))
    (setf params (acons "browser-name" "chrome" params))
    (setf params (acons "created-by" (select-user-by-id 1 1) params))
    (setf params (acons "data-storage-in" "tempstorage" params))
    (setf params (acons "business-session" (gethash (hunchentoot:session-value :login-vendor-business-session-id) *HHUBBUSINESSSESSIONS-HT*) params))

    (let ((returnlist (hhub-execute-business-function  "com.hhub.businessfunction.bl.createpushnotifysubscriptionforvendor" params)))
      (if (nth 1 returnlist)
      "Subscription Accepted"))))


(defun hhub-controller-save-vendor-push-subscription ()
  (let* ((vendor (get-login-vendor))
	 (endpoint (hunchentoot:parameter "notificationEndPoint"))
	 (publicKey (hunchentoot:parameter "publicKey"))
	 (auth (hunchentoot:parameter "auth"))
	 (requestmodel (make-instance 'RequestCreateWebPushNotifyVendor
				      :vendor vendor 
				      :auth auth
				      :endpoint endpoint
				      :publickey publickey))
	 (webpushadapter (make-instance 'VendorWebPushNotifyAdapter)))
    (processcreaterequest webpushadapter requestmodel)))




(defun hhub-remove-customer-push-subscription ()
  (let ((params nil))
    (setf params (acons "customer" (get-login-customer) params))
    (let* ((subscription-list (hhub-business-adapter 'get-push-notify-subscription-for-customer params)))
      (setf params nil)
      (if subscription-list (setf params (acons "subscription-list" subscription-list params)))
      (hhub-business-adapter 'remove-webpush-subscription params)
    "Customer Subscription Removed")))

(defun hhub-remove-vendor-push-subscription ()
  (let* ((vendor (get-login-vendor))
	 (requestmodel (make-instance 'RequestDeleteWebPushNotifyVendor
				      :vendor vendor))
	 (webpushadapter (make-instance 'VendorWebPushNotifyAdapter)))
    (processdeleterequest webpushadapter requestmodel)))


(defun test-webpush-notification-for-vendor (vendor)
  (let* ((title "Nine Stores")
	 (message (format nil "Welcome to Nine Stores - ~A" (slot-value vendor 'name)))
	 (clickTarget (format nil "~A" *siteurl*))
	 (params nil))
    (setf params (acons "vendor" vendor params))
    (let ((returnlist (hhub-execute-business-function  "com.hhub.businessfunction.bl.getpushnotifysubscriptionforvendor" (setf params (acons "vendor" vendor  params))))) 
      (if (null (nth 1 returnlist))
	  (mapcar (lambda (subscription)
		    (let ((endpoint (slot-value subscription 'endpoint))
			  (publickey (slot-value subscription 'publickey))
			  (auth  (slot-value subscription 'auth)))
		      (send-webpush-notification title message clickTarget endpoint publickey auth))) (nth 0 returnlist))))))



(defun send-webpush-message (person message)
  (let* ((title "Nine Stores")
	 (webpushdbservice (make-instance 'WebPushNotifyDBService))
	 (subscription (if (equal 'DOD-VEND-PROFILE (type-of person)) (db-fetch-Vendor-WebPushNotifySubscriptions webpushdbservice person)))
	 (clickTarget (format nil "~A/hhub/dodvendindex?context=pendingorders" *siteurl*)))
    ;; Send a message only if subscription is present. 
    (if subscription
	(let ((endpoint (slot-value subscription 'endpoint))
	      (publickey (slot-value subscription 'publickey))
	      (auth  (slot-value subscription 'auth)))
	  (send-webpush-notification title message clickTarget endpoint publickey auth)))))





(defun test-webpush-notification-for-customer (customer)
  (let* ((title "Nine Stores")
	 (message (format nil "Welcome to Nine Stores - ~A" (slot-value customer 'name)))
	 (clickTarget (format nil "~A" *siteurl*))
	 (subscriptions (get-push-notify-subscription-for-customer customer)))
    (mapcar (lambda (subscription)
	      (let ((endpoint (slot-value subscription 'endpoint))
		    (publickey (slot-value subscription 'publickey))
		    (auth  (slot-value subscription 'auth)))
		(send-webpush-notification title message clickTarget endpoint publickey auth))) subscriptions)))


					;Experiment with push notification 
(defun send-webpush-notification (title message clickTarget endpoint publicKey auth)
:documentation "Test Webpush Notification" 
  (let* ((paramnames (list "title" "message" "clickTarget" "endpoint" "publicKey" "auth"))
	 (paramvalues (list title message clickTarget endpoint publicKey auth))
	 (param-alist (pairlis paramnames paramvalues))
	 (headers nil) 
	 (headers (acons "auth-secret" "highrisehub1234" headers)))
    ; Execution
    (drakma:http-request (format nil "~A/push/notify/user" *siteurl*)
			 :additional-headers headers
			     :parameters param-alist)))



(defun send-sms-notification (number senderid message)
  (let* ((paramnames (list "number" "senderid" "message"))
	 (paramvalues (list number senderid message))
	 (param-alist (pairlis paramnames paramvalues))
	 (headers nil) 
	 (headers (acons "auth-secret" "highrisehub1234" headers)))
    ; Execution
    (drakma:http-request (format nil "~A/sms/sendsms" *SITEURL*)
			 :additional-headers headers
			     :parameters param-alist)))
  
