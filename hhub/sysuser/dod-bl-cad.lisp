; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


(defun generate-product-ext-url (product)
  :description "Generates an external URL for a product, which can be shared with external entities"
  (let* ((tenant-id (slot-value product 'tenant-id))
	 (prd-id (slot-value product 'row-id))
	 (param-csv (format nil "tenant-id,product-id~C~A,~A" #\linefeed tenant-id prd-id))
	 (param-base64 (cl-base64:string-to-base64-string param-csv)))
    (format nil "~A/hhub/hhubprddetailsforguestcust?key=~A" *siteurl* param-base64)))
		    

(defun approve-product (id description company)
  (let ((product (select-product-by-id id company)))
    (if product 
	(progn (setf (slot-value product 'approved-flag) "Y")
	       (setf (slot-value product 'approval-status) "APPROVED")
	       (setf (slot-value product 'description) description)
	       (update-prd-details product)))))

(defun reject-product (id description company)
  (let ((product (select-product-by-id id  company)))
    (if product 
	(progn (setf (slot-value product 'approved-flag) "N")
	       (setf (slot-value product 'approval-status) "REJECTED")
	       (setf (slot-value product 'description) description)
	       (update-prd-details product)))))

