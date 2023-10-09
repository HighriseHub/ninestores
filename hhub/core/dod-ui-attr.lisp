;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(defun com-hhub-attribute-customer-type ()
(get-login-customer-type))

(defun com-hhub-attribute-order ()
  "Order")

(defun com-hhub-attribute-create-order ()
"com.hhub.transaction.create.order")

; This is an Action attribute functin for customer order edit. 
(defun com-hhub-attribute-cust-edit-order-item ()
"com.hhub.transaction.cust.edit.order.item")

(defun com-hhub-attribute-customer-order-cutoff-time ()
  *HHUB-CUSTOMER-ORDER-CUTOFF-TIME*)

(defun com-hhub-attribute-cust-order-payment-mode (order-id)
 (let ((order (get-order-by-id order-id (get-login-cust-company))))
   (slot-value order 'payment-mode)))



(defun com-hhub-attribute-role-instance ()
  (let* ((user-id (get-login-userid))
	 (tenant-id (get-login-tenant-id))
	 (userrole-instance (select-user-role-by-userid user-id tenant-id))
	 (role-id (slot-value userrole-instance 'role-id)))
    (select-role-by-id role-id)))
    

(defun com-hhub-attribute-role-name ()
:documentation "Role name is described. The attribute function will get the role name of the currently logged in user"
(let ((role (com-hhub-attribute-role-instance)))
       (slot-value role 'name)))


(defun com-hhub-attribute-vendor-bulk-product-count ()
  100)

(defun com-hhub-attribute-vendor-issuspended (vendor)
  (equal (slot-value vendor 'suspend-flag) "Y"))


(defun com-hhub-attribute-company-issuspended (suspend-flag)
  (equal suspend-flag "Y"))


(defun com-hhub-attribute-company-maxvendorcount (subscription-plan)
  (cond ((equal subscription-plan "BASIC") 5)
	((equal subscription-plan "PROFESSIONAL") 10)
	((equal subscription-plan "TRIAL") 1)))

(defun com-hhub-attribute-company-maxproductcount (subscription-plan)
  (cond ((equal subscription-plan "BASIC") 1000)
	  ((equal subscription-plan "PROFESSIONAL") 3000)
	  ((equal subscription-plan "TRIAL") 100)))


(defun com-hhub-attribute-company-prdbulkupload-enabled (subscription-plan)
  (cond ((equal subscription-plan "BASIC") T)
	((equal subscription-plan "PROFESSIONAL") T)
	((equal subscription-plan "TRIAL") NIL)))


(defun com-hhub-attribute-company-prdsubs-enabled (subscription-plan)
  (cond ((equal subscription-plan "BASIC") T)
	((equal subscription-plan "PROFESSIONAL") T)
	((equal subscription-plan "TRIAL") NIL)))


(defun com-hhub-attribute-company-wallets-enabled (subscription-plan)
  (cond ((equal subscription-plan "BASIC") NIL)
	((equal subscription-plan "PROFESSIONAL") T)
	((equal subscription-plan "TRIAL") NIL)))

  
(defun com-hhub-attribute-company-codorders-enabled (subscription-plan)
  (cond ((equal subscription-plan "BASIC") NIL)
	((equal subscription-plan "PROFESSIONAL") T)
	((equal subscription-plan "TRIAL") NIL)))


(defun com-hhub-attribute-company-maxcustomercount (subscription-plan)
  (cond ((equal subscription-plan "BASIC") 500)
	((equal subscription-plan "PROFESSIONAL") 1000)
	((equal subscription-plan "TRIAL") 50)))

  
(defun com-hhub-attribute-company-subscription-plan (company)
  (slot-value company 'subscription-plan))

(defun com-hhub-attribute-company-maxprodcatgcount  (subscription-plan)
  (cond ((equal subscription-plan "BASIC") 20)
	((equal subscription-plan "PROFESSIONAL") 30)
	((equal subscription-plan "TRIAL") 10)))

(defun com-hhub-attribute-vendor-currentprodcatgcount (company)
  (length (select-prdcatg-by-company company)))

(defun com-hhub-attribute-vendor-shipping-enabled (vendor)
  (let ((shipping-enabled (slot-value vendor 'shipping-enabled)))
    (if (equal shipping-enabled "Y") T NIL)))

(defun com-hhub-attribute-vendor-freeship-enabled (vendor company)
  (let* ((shipping-method (get-shipping-method-for-vendor vendor company))
	(freeshipenabled (slot-value shipping-method 'freeshipenabled)))
    (if (equal freeshipenabled "Y") T NIL)))


(defun com-hhub-attribute-vendor-flatrateship-enabled (vendor company)
  (let* ((shipping-method (get-shipping-method-for-vendor vendor company))
	 (flatrateshipenabled (slot-value shipping-method 'flatrateshipenabled)))
    (if (equal flatrateshipenabled "Y") T NIL)))

(defun com-hhub-attribute-vendor-tablerateship-enabled (vendor company)
  (let* ((shipping-method (get-shipping-method-for-vendor vendor company))
	 (tablerateshipenabled (slot-value shipping-method 'tablerateshipenabled)))
    (if (equal tablerateshipenabled "Y") T NIL)))

(defun com-hhub-attribute-vendor-externalship-enabled (vendor company)
  (let* ((shipping-method (get-shipping-method-for-vendor vendor company))
	 (extshipenabled (slot-value shipping-method 'extshipenabled)))
    (if (equal extshipenabled "Y") T NIL)))

