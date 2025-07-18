(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)
					;**********Get the company***********
(defparameter dod-company (select-company-by-name "demo"))


					;******Create the customer ******
(defparameter *birthdate* (make-date :year 2016 :month 5 :day 29))
(defparameter *customer-params* nil)
(setf *customer-params* (list (format nil "Test Customer ~a" (random 200)) "GA Bangalore 560066" (format nil "98456~a" (random 99999)) "test@test.com" *birthdate* "P@ssword" "salt" "Bangalore" "Karnataka" "560066"  dod-company))
;Create the customer now.
(apply #'create-customer *customer-params*)
;Get the customer which we have created in the above steps. 
(defparameter Testcustomer1 (select-customer-by-name (car *customer-params*) dod-company))

; **** Create the vendor *****
(defparameter *vendor-params* nil)
(setf *vendor-params* (list (format nil "Test Vendor ~a" (random 20)) "GA Bangalore 560066" (format nil "98456~a" (random 99999)) "testvendor@test.com" "P@ssword" "salt"  "Bangalore"  "Karnataka" "560066" dod-company))
;Create the vendor now.
(apply #'create-vendor *vendor-params*)
;Get the vendor which we have created in the above steps. 
(defparameter Testvendor1(select-vendor-by-name (car *vendor-params*) dod-company))

;******* Create new order ********
(defparameter OrderDate (make-date :year 2016 :month 5 :day 29))
(defparameter RequestDate (make-date :year 2016 :month 5 :day 29))
(defparameter ShipDate (make-date :year 2016 :month 5 :day 29))
(defparameter NandiniBlue (select-product-by-name "%Nandini Blue" dod-company))
(defparameter NandiniGreen (select-product-by-name "%Nandini-Green" dod-company))
(create-order OrderDate Testcustomer1 RequestDate ShipDate "GA Bangalore" nil nil "PRE" "Test CommentS" dod-company  )
(defparameter TestOrder1 (get-latest-order-for-customer Testcustomer1 ))
;;****** Create order details ********
(create-order-items TestOrder1 NandiniBlue 1 15.00 dod-company)
(create-order-items TestOrder1 NandiniGreen 1 20.00 dod-company)

(defparameter Customer1-orders (get-orders-for-customer  Testcustomer1))
;Create test data for Tenant 3

					;Delete a customer
(delete-customer Testcustomer1)
(restore-deleted-Customer Testcustomer1)
					;Get the number of customers;
(defparameter *num-customers* nil)
(defparameter *list-customers* nil)
(setf *list-customers*  (list-cust-profiles dod-company))
(defparameter num-customers (length (list-cust-profiles dod-company)))

(defparameter dod-company (select-company-by-name "Gopalan Atlantis"))
(defparameter Rajesh (Select-vendor-by-name "%Rajesh" dod-company))
(defparameter NandiniPurple (list (format nil "Nandini Sumrudhi (Purple packet)") Rajesh "500 ml" 18.50 "/resources/nandini-purple.png" dod-company))
(defparameter NandiniSTM (list (format nil "Nandini Special Toned Milk") Rajesh "500 ml" 18.50 "/resources/nandini-stm.png" dod-company))
(defparameter NandiniYellow (list (format nil "Nandini Double Toned Milk (Yellow packet)") Rajesh "500 ml" 46.00 "/resources/nandini-yellow.png" dod-company))
; (apply #'create-product NandiniPurple)


(defparameter *product-params* nil)
(setf *product-params* (list (format nil "Test Product ~a" (random 200)) TestVendor1 "1 Litre" 20.00 "/resources/test-product.png" nil dod-company))
;Create the customer now.
(apply #'create-product *product-params*)
;Get the customer which we have created in the above steps. 
(defparameter Testproduct (select-product-by-name (car *product-params*) dod-company ))

;*************************************************************************
;********************** create order preferences  ****************************

(create-opref Testcustomer1 NandiniBlue 1 dod-company)
(create-opref Testcustomer1 NandiniGreen 1 dod-company)

(defparameter opflist (get-opreflist-for-customer Testcustomer1))
(create-order-from-pref opflist orderdate requestdate shipdate "Gopalan Atlantis Bangalore" Testcustomer1  dod-company)


;*************************************************************************
;********************** create a new product ****************************

(defun prepare-test-customer ()
  (let* ((dod-company (select-company-by-name "Gopalan Atlantis"))
					;******Create the customer ******
	 (customer-params (list (format nil "Test Customer ~a" (random 200)) "GA Bangalore 560066" (format nil "98456~a" (random 99999)) dod-company))
	 (Testcustomer1 nil))

    (defun test-create-customer ()
      (progn (apply #'create-customer customer-params)
	     (setf Testcustomer1 (select-customer-by-name (car customer-params) dod-company)))
      (defun test-delete-customer () (apply #'delete-customer (list TestCustomer1))))))



(defun prepare-test-orders (customer-id company-name)
  (let* ((dod-company (select-company-by-name company-name))
	 (customer (select-customer-by-id customer-id dod-company))
	 (order (get-orders-for-customer customer)))
	 

    (defun test-order-details ()
     (let ((order-details (get-order-items order)))
       order-details))))
		



(defparameter Testvendor1(select-vendor-by-name "%Rajesh" dod-company))
(defparameter *product-params* nil)
(setf *product-params* (list "Nandini Ghee"  TestVendor1 "500 Grams" 200.00 nil dod-company))
;Create the customer now.
;(apply #'create-product *product-params*)
;Get the customer which we have created in the above steps. 
(defparameter Testproduct (select-product-by-name (car *product-params*) dod-company ))
(defparameter OrderDate (make-date :year 2016 :month 8 :day 17))
(defparameter RequestDate (make-date :year 2016 :month 8 :day 17))

 



