;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defun hhub-test-order ()
  (let* ((company (select-company-by-id 2))
	 (vendor (select-vendor-by-id 1))
	 (customer (select-customer-by-id 1 company))
	 (order-date (current-date-object))
	 (request-date (current-date-object))
	 (shipped-date nil)
	 (expected-delivery-date (clsql::date+ (clsql::get-date) (clsql::make-duration :day 2)))
	 (NandiniBlue (select-product-by-id 1 company))
	 (NandiniGreen (select-product-by-id 2 company))
	 (shopcart-products (list NandiniBlue NandiniGreen))
	 (oitem1 (create-odtinst-shopcart nil NandiniBlue 1 (slot-value NandiniBlue 'current-price) (slot-value NandiniBlue 'current-discount) company))
	 (oitem2 (create-odtinst-shopcart nil NandiniGreen 1 (slot-value NandiniGreen 'current-price) (slot-value NandiniGreen 'current-discount) company))
	 (oitem1price (slot-value NandiniBlue 'current-price))
	 (oitem2price (slot-value NandiniGreen 'current-price))
	 (oitem1discount (slot-value NandiniBlue 'current-discount))
	 (oitem2discount (slot-value NandiniGreen 'current-discount))
	 (order-items (list oitem1 oitem2))
	 (shipaddr "A-456, Brigade Metropolis, Mahadevapura, Bangalore 560066")
	 (shipzipcode "560066")
	 (shipcity "Mahadevapura, Bangalore")
	 (shipstate "Karnataka")
	 (billaddr shipaddr)
	 (billzipcode shipzipcode)
	 (billcity shipcity)
	 (billstate shipstate)
	 (billsameasship "Y")
	 (storepickupenabled "N")
	 (gstnumber "")
	 (gstorgname "")
	 (order-amt (+ oitem1price oitem2price))
	 (total-discount (+ oitem1discount oitem2discount))
	 (total-tax 0.00)
	 (payment-mode "PRE")
	 (comments "This order is created")
	 (order-type "SALE")
	 (order-source "WEB")
	 (customer-name (slot-value customer 'name))
	 (vshipping-method (get-shipping-method-for-vendor vendor company))
	 (shiplst (calculate-shipping-cost-for-order vshipping-method shipzipcode order-amt order-items shopcart-products vendor company))
	 (shipping-cost (nth 0 shiplst))
	 ;;(shipping-info (nth 1 shiplst))
	 ;;(utrnum "829349823423")
	 (requestmodel (make-instance 'orderRequestModel
				      :ord-date order-date
				      :req-date request-date
				      :shipped-date shipped-date
				      :expected-delivery-date expected-delivery-date
				      :ordnum ""
				      :shipaddr shipaddr
				      :shipzipcode shipzipcode
				      :shipcity shipcity
				      :shipstate shipstate
				      :billaddr billaddr
				      :billzipcode billzipcode
				      :billcity billcity
				      :billstate billstate
				      :billsameasship billsameasship
				      :storepickupenabled storepickupenabled
				      :gstnumber gstnumber
				      :gstorgname gstorgname
				      :order-fulfilled "N"
				      :order-amt order-amt
				      :shipping-cost shipping-cost
				      :total-discount total-discount
				      :total-tax total-tax
				      :payment-mode payment-mode
				      :comments comments
				      :context-id (format nil "~A" (uuid:make-v1-uuid))
				      :status "PEN"
				      :order-type order-type
				      :order-source order-source
				      :is-converted-to-invoice "N"
				      :is-cancelled "N"
				      :cancel-reason "NOT APPLICABLE"
				      :deleted-state "N"
				      :external-url (format nil "https://~A/" *siteurl*)
				      :custname customer-name
				      :customer customer
				      :company company)))
    (with-entity-create 'orderAdapter requestmodel
      entity)))

(defun hhub-test-shipping-rate-check ()
  (let ((ratecheckfunction
	  (lambda ()
	    (let* ((company (select-company-by-id 2))
		   (NandiniBlue (select-product-by-id 1 company))
		   (NandiniGreen (select-product-by-id 2 company))
		   (prodlist (list NandiniBlue NandiniGreen))
		   (oitem1 (create-odtinst-shopcart nil NandiniBlue 2 (slot-value NandiniBlue 'current-price) 0  company))
		   (oitem2 (create-odtinst-shopcart nil NandiniGreen 2 (slot-value NandiniGreen 'current-price) 0 company))
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

(defvar *notifier-ht* (make-hash-table :test 'equal))
(defvar *events-ht* (make-hash-table :test 'equal))
(defvar *idlers-ht* (make-hash-table :test 'equal))

(defun hhub-background-task-with-events ()
  (let ((asynceventloopthread (sb-thread:make-thread
			       (lambda ()
				 (as:with-event-loop (:catch-app-errors t)
				   (setf (gethash "eventkey1" *events-ht*) (as:make-event #'event-worker))
				   (setf (gethash "eventkey2" *events-ht*) (as:make-event #'event-worker))
				   (setf (gethash "eventkey3" *events-ht*) (as:make-event #'event-worker))
				   )) :name "Async event loop thread having events")))

    (format *stdoutstream* "I have created an async event loop thread ~A ~C~C" asynceventloopthread #\return #\linefeed)
    asynceventloopthread))

(defun process-event (num)
  (let ((ekey (format nil "eventkey~d" num)))
    (as:add-event (gethash ekey *events-ht*)  :timeout 2 :activate t))) 


(defun event-worker ()
  (format *stdoutstream* "Inside event and sending mail now  ~C~C"   #\return #\linefeed)
  (hhubsendmail "uflgxh+a335lpgfhjudo@sharklasers.com" (format nil "Test subject ~A " (gensym)) "Test 123") 
  (sleep 10)
  (format *stdoutstream* "Inside event and send mail done  ~C~C"   #\return #\linefeed))


(defun hhub-background-task-with-notifier ()
  (let ((backgroundtask (sb-thread:make-thread
			   (lambda ()
			     (as:with-event-loop (:catch-app-errors t)
			       (let* ((result nil))
				 (setf (gethash "notifierkey1" *notifier-ht*) (as:make-notifier (lambda () (format t "Job finished! ~a~%" result))))
				 (setf (gethash "notifierkey2" *notifier-ht*) (as:make-notifier (lambda () (format t "Job finished! ~a~%" result))))
				 (setf (gethash "notifierkey3" *notifier-ht*) (as:make-notifier (lambda () (format t "Job finished! ~a~%" result))))
				 (setf (gethash "notifierkey4" *notifier-ht*) (as:make-notifier (lambda () (format t "Job finished! ~a~%" result))))
				 (setf (gethash "notifierkey5" *notifier-ht*) (as:make-notifier (lambda () (format t "Job finished! ~a~%" result))))
				 (setf (gethash "notifierkey6" *notifier-ht*) (as:make-notifier (lambda () (format t "Job finished! ~a~%" result))))
				 (format *stdoutstream* "I am in the async event loop. Exiting loop")))) :name "Event Loop Thread")))
    backgroundtask))

(defun process-notifier-task (num)
  (let ((nkey (format nil "notifierkey~d" num)))
    (background-task num (gethash nkey *notifier-ht*))
  (format *stdoutstream* "Background task for notifier -  ~A will be triggered now" nkey)))
    
(defun background-task (num notifier)
  (sb-thread:make-thread 
     (lambda ()
  	  (loop for i from 1 to  20 do 
	    (sleep 1)
	    (format *stdoutstream* "For thread number ~d I am running ~d iteration  ~C~C" num i  #\return #\linefeed))
       (as:trigger-notifier notifier)
       ) :name (format nil "Background Task/ Thread -~d" num)))

(defun hhub-background-task-with-async-delay ()
  (as:with-event-loop (:catch-app-errors t)
    (let* ((result nil))
      (as:delay
       (lambda ()
	 (setf result 10)
	 (format T "Timer Fired. Exiting. Result is ~A ~%" result)) :time 3))))
 


(defun hhub-background-task-with-idlers ()
  (let ((asynceventloopthread (sb-thread:make-thread
			       (lambda ()
				 (as:with-event-loop (:catch-app-errors t)
				   (setf (gethash "idlerkey1" *idlers-ht*) (as:idle #'event-worker))
				   )) :name "Async event loop thread having idlers")))

    (format *stdoutstream* "I have created an async event loop thread ~A ~C~C" asynceventloopthread #\return #\linefeed)
    asynceventloopthread))
  

(defun idler-worker ()
  (hhubsendmail "uflgxh+a335lpgfhjudo@sharklasers.com" (format nil "Test subject ~A " (gensym)) "Test 123") 
  (sleep 10)
  (format *stdoutstream* "Idler has done its job of sending email ~C~C" #\return #\linefeed))



;;;;;;;;;;;;;;;;;;;;;;; CL-ASYNC PROMISES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun promise-task ()
  (bb:with-promise (resolve reject)
    (handler-case
	(resolve (lambda () (format *stdoutstream* "I am resolving")))
      (t (e) (reject e)))))
      


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;NST EVENT LOOP ARCHITECTURE;;;;;;;;;;;;;;;;;;;;;;;;;

;;; will work on it someday.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




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

    

  


