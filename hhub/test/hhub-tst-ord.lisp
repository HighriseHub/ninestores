;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defun hhub-test-order ()
  (let* ((company (select-company-by-id 2))
	 (customer (select-customer-by-id 1 company))
	 (OrderDate (get-date-from-string "23/03/2023"))
	 (RequestDate (get-date-from-string "23/03/2023"))
	 (ShipDate (get-date-from-string "23/03/2023"))
	 (NandiniBlue (select-product-by-id 1 company))
	 (NandiniGreen (select-product-by-id 2 company))
	 (products (select-products-by-company company))
	 (oitem1 (create-odtinst-shopcart nil NandiniBlue 1 (slot-value NandiniBlue 'unit-price) company))
	 (oitem2 (create-odtinst-shopcart nil NandiniGreen 1 (slot-value NandiniGreen 'unit-price) company))
	 (oitem1price (slot-value NandiniBlue 'unit-price))
	 (oitem2price (slot-value NandiniGreen 'unit-price))
	 (shopcart-total (+ oitem1price oitem2price))
	 (odts (list oitem1 oitem2))
	 (shipaddress "A-456, Brigade Metropolis, Mahadevapura, Bangalore"))
    
    (create-order-from-shopcart odts products OrderDate RequestDate ShipDate shipaddress  shopcart-total "UPI" "" customer company nil)))

