;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun test-vpayment-methods-DBSave ()
  (let* ((democompany (select-company-by-id 2))
	 (vendor (select-vendor-by-id 1))
	 (requestmodel (make-instance 'VPaymentMethodsRequestModel
				      :vendor vendor
				      :company democompany
				      :codenabled "Y"
				      :upienabled "Y"
				      :payprovidersenabled "Y"
				      :walletenabled "Y"
				      :paylaterenabled "Y")))
    (with-entity-create 'VPaymentMethodsAdapter requestmodel
      entity)))

(defun test-allvpayment-methods-fetch () 
  (let* ((company (select-company-by-id 2))
	 (vendor (select-vendor-by-id 1))
	 (requestmodel (make-instance 'VPaymentMethodsRequestModel)))
    (setf (slot-value requestmodel 'company) company)
    (setf (slot-value requestmodel 'vendor) vendor)
    (with-entity-readall 'VPaymentMethodsAdapter requestmodel
      allentities)))


(defun test-vpayment-methods-fetch (vendor)
  (let* ((company (select-company-by-id 2))
	 (requestmodel (make-instance 'VPaymentMethodsRequestModel)))
    (setf (slot-value requestmodel 'company) company)
    (setf (slot-value requestmodel 'vendor) vendor)
    (with-entity-read 'VPaymentMethodsAdapter requestmodel
      entity)))

(defun test-vpayment-methods-update ()
  (let* ((company (select-company-by-id 2))
	 (vendor (select-vendor-by-id 1)) 
	 (requestmodel (make-instance 'VPaymentMethodsRequestModel)))
    
    (setf (slot-value requestmodel 'company) company)
    (setf (slot-value requestmodel 'vendor) vendor)
    (setf (slot-value requestmodel 'codenabled) "N")

    (with-entity-update 'VPaymentMethodsAdapter requestmodel
      entity)))

	  
