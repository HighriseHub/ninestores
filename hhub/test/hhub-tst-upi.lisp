;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defun test-upipayments-DBSave ()
;; (handler-case   
     (let* ((vendor (select-vendor-by-id 1))
	    (democompany (select-company-by-id 2))
	    (customer (select-customer-by-id 1 democompany))
	    (amount 100.00)
	    (requestmodel (make-instance 'UpiPaymentsRequestModel
					 :vendor vendor
					 :customer customer
					 :amount amount
					 :transaction-id "PW93993"
					 :utrnum "383838448432"
					 :company democompany))
	    (upipaymentsadapter (make-instance 'UpiPaymentsAdapter)))
	 
       (ProcessCreateRequest upipaymentsadapter requestmodel)))
       
  ;; (error (c)
   ;;  (let ((exceptionstr (format nil  "HHUB General Business Function Error: ~a~%"  c)))
  ;;     (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
;;			       :direction :output
;;			       :if-exists :supersede
;;			       :if-does-not-exist :create)
;;	 (format stream "~A" exceptionstr))
  ;     ;; return the exception.
  ;;     c))))

(defun test-vendor-upipayments-fetch () 
  (let* ((vendor (select-vendor-by-id 1))
	 (upipaymentsDBService (make-instance 'UpiPaymentsDBService))
	 (upipaymentsrecords (db-fetch-Vendor-upirecords upipaymentsDBService vendor)))
   upipaymentsrecords))

  
 

(defun test-vendor-upipayments-get ()
  (let* ((vendor (select-vendor-by-id 1))
	 (params nil)
	 (webpushadapter (make-instance 'VendorWebPushNotifyAdapter))
	 (presenter (make-instance 'GetWebPushNotifyVendorPresenter))
	 (jsonview (make-instance 'JSONView)))
    
    (setf params (acons "vendor" vendor params))
    (render jsonview (createviewmodel presenter (processrequest webpushadapter params)))))

