;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defun hhub-test-order ()
  (let* ((company (select-company-by-id 2))
	 (customer (select-customer-by-id 1 company))
	 (OrderDate (get-date-from-string "09/07/2023"))
	 (RequestDate (get-date-from-string "09/07/2023"))
	 (ShipDate (get-date-from-string "09/07/2023"))
	 (NandiniBlue (select-product-by-id 1 company))
	 (NandiniGreen (select-product-by-id 2 company))
	 (products (select-products-by-company company))
	 (oitem1 (create-odtinst-shopcart nil NandiniBlue 1 (slot-value NandiniBlue 'unit-price) company))
	 (oitem2 (create-odtinst-shopcart nil NandiniGreen 1 (slot-value NandiniGreen 'unit-price) company))
	 (oitem1price (slot-value NandiniBlue 'unit-price))
	 (oitem2price (slot-value NandiniGreen 'unit-price))
	 (shopcart-total (+ oitem1price oitem2price))
	 (odts (list oitem1 oitem2))
	 (shipaddress "A-456, Brigade Metropolis, Mahadevapura, Bangalore")
	 (orderid (create-order-from-shopcart odts products OrderDate RequestDate ShipDate shipaddress  shopcart-total "COD" "" customer company nil nil)))
    orderid))




(defun hhub-test-async-event-loop ()
  (format t "I am running before everybody else")
  
  (as:start-event-loop 
   (lambda ()
     (as:delay
      (lambda () (format t "I am running after 3 seconds")) :time 3)))
      
  (format t "I am completing"))


(defun worker-2 (context p)
  (declare (ignore context))
  :documentation ""
    (print p))

(defun hhub-background-task ()
  (let* ((asynceventsthread
	   (bt:make-thread 
	    (lambda ()
	      (as:with-event-loop (:catch-app-errors t)
		(let* ((result nil)
		       (notifier (as:make-notifier (lambda () (logiamhere (format t "Job finished! ~a~%" result))))))
		  (bt:make-thread 
				  (lambda ()
				    (sleep 30)
				    (setf result 10)
				    (as:trigger-notifier notifier)) :name "Background Task Thread")
		  (logiamhere (format t "I am in the async event loop. Exiting loop"))))) :name "Event loop thread")))
    (logiamhere (format t "I am in the main task. Thread info ~A" asynceventsthread))))
		    




