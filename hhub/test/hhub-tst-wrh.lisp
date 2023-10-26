;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


(defun test-warehouse-DBSave ()
;; (handler-case   
  (let* ((democompany (select-company-by-id 2))
	 (requestmodel (make-instance 'WarehouseRequestModel
				      :w-name  "Test Warehouse"
				      :w-addr1 "Mahalaxmi layout"
				      :w-addr2 "Near Vivekananda Women's college"
				      :w-pin "560096"
				      :w-city "Bengaluru"
				      :w-state "Karnataka"
				      :w-country "IN"
				      :w-manager "Pawan Deshpande"
				      :w-phone "9999339933"
				      :w-alt-phone "9393993222"
				      :w-email "warehouse@example.com"
				      :company democompany))
	    (warehouseadapter (make-instance 'WarehouseAdapter)))
	 
       (ProcessCreateRequest warehouseadapter requestmodel)))
