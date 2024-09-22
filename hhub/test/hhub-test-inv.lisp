
;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(defun test-invoiceheader-DBSave ()
;; (handler-case   
  (let* ((company (select-company-by-id 2))
	 (customer (select-customer-by-id 1 company))
	 (vendor (select-vendor-by-id 1))
	 (requestmodel (make-instance 'InvoiceHeaderRequestModel
				      :invnum ""
				      :invdate (get-date-from-string "06/09/2024")
				      :custaddr "Mahalaxmi layout, Bangalore"
				      :custgstin ""
				      :statecode "02"
				      :billaddr "Mahalaxmi layout"
				      :shipaddr "Mahalaxmi layout"
				      :placeofsupply "Bangalore"
				      :revcharge "No"
				      :transmode ""
				      :vnum ""
				      :totalvalue 1000.0
				      :totalinwords "One thousand only"
				      :bankaccnum ""
				      :bankifsccode ""
				      :tnc ""
				      :finyear "2024"
				      :authsign "Demo Vendor"
				      :vendor vendor
				      :customer customer
				      :company company))
	 
	 (adapterobj (make-instance 'InvoiceHeaderAdapter)))
    (ProcessCreateRequest adapterobj requestmodel)))
