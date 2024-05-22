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
	 (orderid (create-order-from-shopcart odts products OrderDate RequestDate ShipDate shipaddress  shopcart-total 0 nil "COD" "" customer company nil nil)))
    orderid))


(defun hhub-test-shipping-rate-check ()
  (let ((ratecheckfunction
	  (lambda ()
	    (let* ((company (select-company-by-id 2))
		   (NandiniBlue (select-product-by-id 1 company))
		   (NandiniGreen (select-product-by-id 2 company))
		   (prodlist (list NandiniBlue NandiniGreen))
		   (oitem1 (create-odtinst-shopcart nil NandiniBlue 2 (slot-value NandiniBlue 'unit-price) company))
		   (oitem2 (create-odtinst-shopcart nil NandiniGreen 2 (slot-value NandiniGreen 'unit-price) company))
		   (odts (list oitem1 oitem2)))
	      (order-shipping-rate-check odts prodlist "560010" "560096")))))
    ratecheckfunction))


(defun hhub-test-shipping-rate-check-zonewise ()
  (let* ((company (select-company-by-id 2))
	 (NandiniBlue (select-product-by-id 1 company))
	 (NandiniGreen (select-product-by-id 2 company))
	 (prodlist (list NandiniBlue NandiniGreen)))
    (order-shipping-rate-check-zonewise prodlist "400092")))


(defun hhub-test-async-event-loop ()
  (format t "I am running before everybody else")
  
  (as:start-event-loop 
   (lambda ()
     (as:delay
      (lambda () (format t "I am running after 3 seconds")) :time 3)))
      
  (format t "I am completing"))


(defun worker-2 (context p)
  (declare (ignore context))

    (print p))

(defun hhub-background-task ()
  (let* ((asynceventsthread
	   (bt:make-thread 
	    (lambda ()
	      (as:with-event-loop (:catch-app-errors t)
		(let* ((result nil)
		       (notifier (as:make-notifier (lambda () (format t "Job finished! ~a~%" result)))))
		  (bt:make-thread 
				  (lambda ()
				    (sleep 30)
				    (setf result 10)
				    (as:trigger-notifier notifier)) :name "Event Loop Thread")
		  (format t "I am in the async event loop. Exiting loop")))) :name "Background Task Thread")))
    (format t "I am in the main task. Thread info ~A" asynceventsthread)))
		    

(defun func1 ()
  "Hello1")

(defun func2 ()
  "world1")

(defun func3 ()
  "Hello2")

(defun func4 ()
  "World2")

(defun mapcomplexfunc ()
  (let ((funclist nil))
    (setf funclist (acons (complex 1 1) "func1" funclist))
    (setf funclist (acons (complex -1 1 ) "func2"  funclist))
    (setf funclist (acons (complex -1 -1) "func3"  funclist))
    (setf funclist (acons (complex 1 -1) "func4"  funclist))
    funclist))

(defvar nextfunc 
  (let* ((funclist (mapcomplexfunc))
	 (complexfactor (complex 0 0.5))
	 (lasttimefunckey (complex 1 1)))

    (lambda ()
     (let ((func (cdr (assoc lasttimefunckey funclist :test '=))))
       (setf lasttimefunckey (* complexfactor lasttimefunckey))
       (funcall (intern (string-upcase func) :hhub))
       ))))

(defvar *counter* (let ((count 0))
                    (lambda () (incf count))))

    

  


