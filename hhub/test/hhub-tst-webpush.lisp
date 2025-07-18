;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun test-vendor-push-notification-DBSave ()
 (handler-case   
  (let* ((vendor (select-vendor-by-id 1))
	 (endpoint "https://fcm.googleapis.com/fcm/send/cOiXZdFN1L8:APA91bG6ihZdVprLygSkCmrG1dYKoLMYPLukqBx1HUt-ibJqRUq8Naa2DiuAh9vIZCU149mhED6Yq6AN2G50ODSplT7GlzkMMs9MU4d-y4E7xyqdDKPXHFVzkLcSYRJdQSWNNexUfns4")
	 (publickey "BL4da60XNvMouIndK7QyVwP9UT3upM+xdkWF+4+HvRChOIcl46Pk23pHstMGigxhOHg/ayeZ/uTnqbocwjiJIcA=")
	 (auth "AXLmPcLxtGxbBdcP4lvT6g==")
	 (browser-name "chrome")
	 (webpushnotifyobj (make-instance 'WebPushNotifyVendor
					  :vendor vendor
					  :endpoint endpoint
					  :publickey publickey
					  :auth auth 
					  :browser-name browser-name 
					  :perm-granted "Y"
					  :expired "N"))
	 (webpushdbservice (make-instance 'WebPushNotifyDBService)))
    
    ;; Initialize the DB Service
    (init webpushdbservice webpushnotifyobj)
    (copy-businessobject-to-dbobject webpushdbservice)
    (db-save webpushdbservice))
   (error (c)
     (let ((exceptionstr (format nil  "HHUB General Business Function Error: ~a~%"  c)))
       (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
			       :direction :output
			       :if-exists :supersede
			       :if-does-not-exist :create)
	 (format stream "~A" exceptionstr))
         c))))

(defun test-vendor-push-notification-fetch ()
  (let* ((vendor (select-vendor-by-id 1))
	 (webpushdbservice (make-instance 'WebPushNotifyDBService))
	 (subscription (db-fetch-Vendor-WebPushNotifySubscriptions webpushdbservice vendor)))
   subscription))

  
 

(defun test-vendor-push-notification-get ()
  (let* ((vendor (select-vendor-by-id 1))
	 (webpushadapter (make-instance 'VendorWebPushNotifyAdapter))
	 (presenter (make-instance 'GetWebPushNotifyVendorPresenter))
	 (requestmodel (make-instance 'RequestGetWebPushNofityVendor))
	 (jsonview (make-instance 'JSONView)))

    (setf (slot-value requestmodel 'vendor) vendor)
    (render jsonview (createviewmodel presenter (processreadrequest  webpushadapter requestmodel)))))
