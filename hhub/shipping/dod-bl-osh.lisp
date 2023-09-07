;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(defun get-free-shipping-method-for-vendor (vendor company)
  (let ((tenant-id (slot-value company 'row-id))
	(vendor-id (slot-value vendor 'row-id)))
    (car (clsql:select 'dod-shipping-methods  :where
		       [and
		       [= [:deleted-state] "N"]
		       [= [:active-flag] "Y"]
		       [= [:tenant-id] tenant-id]
		       [= [:vendor-id] vendor-id]] :caching *dod-debug-mode* :flatp T ))))
  




(defun persist-free-shipping-method (minordamt vendor-id tenant-id)
  (clsql:update-records-from-instance (make-instance 'dod-shipping-methods
					 :minorderamt minordamt
					 :vendor-id vendor-id
					 :tenant-id tenant-id
					 :freeshipenabled "Y"
					 :active-flag "Y"
					 :deleted-state "N")))



(defun create-free-shipping-method (minordamt vendor company)
   (let ((tenant-id (slot-value company 'row-id))
	 (vendor-id (slot-value vendor 'row-id)))
     (persist-free-shipping-method minordamt vendor-id tenant-id)))



(defun getminorderamt (freeshippingmethod)
  (let ((freeshipenabled (slot-value freeshippingmethod 'freeshipenabled))
	(minorderamt (slot-value freeshippingmethod 'minorderamt)))
    (when freeshipenabled minorderamt)))


(defun update-shipping-methods (shippingmethod); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance shippingmethod))
