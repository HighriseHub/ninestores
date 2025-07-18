;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)



;;;;;;;;;;;;;;;;;;;;; business logic for dod-bus-object ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun get-payment-trans-by-transaction-id (trans-id company)
  (let ((tenant-id (slot-value company 'row-id)))
    (car (clsql:select 'dod-payment-transaction  :where 
		       [and [= [:deleted-state] "N"] 
		       [= [:tenant-id] tenant-id]
		       [= [:transaction-id] trans-id]]    :caching *dod-database-caching* :flatp t ))))


(defun select-payment-trans-by-customer (customer company)
  (let ((customer-id (slot-value customer 'row-id))
	(tenant-id (slot-value company 'row-id)))
    (clsql:select 'dod-payment-transaction  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[= [:customer-id] customer-id]] :limit 20
		:caching *dod-database-caching* :flatp t )))
  

(defun select-payment-trans-by-vendor (customer vendor company)
  (let ((customer-id (slot-value customer 'row-id))
	(vendor-id (slot-value vendor 'row-id))
	(tenant-id (slot-value company 'row-id)))
    (clsql:select 'dod-payment-transaction  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[= [:vendor-id] vendor-id]
		[= [:customer-id] customer-id]] :limit 20
		:caching *dod-database-caching* :flatp t )))
  




(defun persist-payment-trans(order-id amt currency description customer-id vendor-id payment-mode transaction-id response-code response-message error-desc tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-payment-transaction
						    :order-id order-id
						    :amt amt
						    :currency currency 
						    :description description 
						    :customer-id customer-id 
						    :vendor-id vendor-id 
						    :payment-mode payment-mode
						    :transaction-id transaction-id
						    :response-code response-code
						    :response-message response-message
						    :error-desc error-desc
						    :deleted-state "N"
						    :tenant-id tenant-id)))
						    
 


(defun create-payment-trans (order-id amt currency description customer vendor payment-mode transaction-id response-code response-message error-desc company)
  (let ((tenant-id (slot-value company 'row-id))
	(customer-id (slot-value customer 'row-id))
	(vendor-id (slot-value vendor 'row-id)))
    	      (persist-payment-trans order-id amt currency description customer-id vendor-id payment-mode transaction-id response-code response-message error-desc tenant-id)))


