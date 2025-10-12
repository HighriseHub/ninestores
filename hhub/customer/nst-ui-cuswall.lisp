;; -*- mode: common lisp; coding: utf-8 -*-
(in-package :nstores)


(defun dod-controller-cust-wallet-display ()
  :documentation "a callback function which displays the wallets for a customer" 
  (with-cust-session-check
    (with-mvc-ui-page "Customer Wallets" #'create-model-for-custwalletdisplay #'create-widgets-for-custwalletdisplay :role :customer)))    
  

(defun create-model-for-custwalletdisplay ()
  (let* ((company (hunchentoot:session-value :login-customer-company))
	 (customer (hunchentoot:session-value :login-customer))
	 (header (list "Vendor" "Phone" "Balance" "Recharge"))
	 (wallets (get-cust-wallets customer company)))
    (function (lambda ()
      (values header wallets)))))
 
(defun create-widgets-for-custwalletdisplay (modelfunc)
  (multiple-value-bind (header wallets) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (cl-who:str (display-as-table header wallets 'cust-wallet-as-row)))))))
      (list widget1))))
