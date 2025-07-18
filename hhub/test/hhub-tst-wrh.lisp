;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun test-warehouse-DBSave (managername phone)
  (let* ((democompany (select-company-by-id 2))
	 (requestmodel (make-instance 'WarehouseRequestModel
				      :w-name  "Test Warehouse"
				      :w-addr1 "Mahalaxmi layout"
				      :w-addr2 "Near Vivekananda Women's college"
				      :w-pin "560096"
				      :w-city "Bengaluru"
				      :w-state "Karnataka"
				      :w-country "IN"
				      :w-manager managername
				      :w-phone phone
				      :w-alt-phone "9393993222"
				      :w-email "warehouse@example.com"
				      :company democompany)))
    (with-entity-create 'WarehouseAdapter requestmodel)))


(defun test-warehouses-fetch () 
  (let* ((company (select-company-by-id 2))
	 (requestmodel (make-instance 'WarehouseRequestModel)))
    (setf (slot-value requestmodel 'company) company)
    (with-entity-readall 'WarehouseAdapter requestmodel)))

(defun test-warehouse-fetch () 
  (let* ((company (select-company-by-id 2))
	 (requestmodel (make-instance 'WarehouseRequestModel)))

    (setf (slot-value requestmodel 'company) company)
    (setf (slot-value requestmodel 'w-phone) "9999339933")
    (with-entity-readall 'WarehouseAdapter requestmodel
    (with-entity-read 'WarehouseAdapter requestmodel))))
    




