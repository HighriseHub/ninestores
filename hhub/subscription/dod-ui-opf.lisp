;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


(defun dod-controller-my-orderprefs ()
 :documentation "a callback function which prints daily order preferences for a logged in customer in html format." 
    (let (( dodorderprefs (hunchentoot:session-value :login-cusopf-cache))
	   (header (list  "Product"  "Day"  "Qty" "Qty Per Unit" "Price"  "Actions")))
      (with-cust-session-check
	(with-standard-customer-page  "Customer Order Subscriptions"
	  (:h3 "My Subscriptions.")      
	  (:a :class "btn btn-primary" :role "button" :href (format nil "dodcustindex") "Shop Now")
	  (cl-who:str (display-as-table header dodorderprefs 'cust-opf-as-row))))))
;; (das-cust-page-with-tiles 'ui-list-cust-orderprefs "customer order preferences" header dodorderprefs)))




(defun cust-opf-as-row (orderpref)
  (let ((opf-id (slot-value orderpref 'row-id))
	(opf-product (get-opf-product orderpref)))
    (cl-who:with-html-output (*standard-output* nil)
      (:td  :height "12px" (cl-who:str (slot-value opf-product  'prd-name)))
	  (:td :height "12px"    (cl-who:str (if (equal (slot-value orderpref 'sun) "Y") "Su, "))
	       (cl-who:str (if (equal (slot-value orderpref 'mon) "Y") "Mo, "))
	       (cl-who:str (if (equal (slot-value orderpref 'tue) "Y")  "Tu, "))
	       (cl-who:str (if (equal (slot-value orderpref 'wed) "Y") "We, "))
	       (cl-who:str (if (equal (slot-value orderpref 'thu) "Y")  "Th, "))
	       (cl-who:str (if (equal (slot-value orderpref 'fri) "Y") "Fr, "))
	       (cl-who:str (if (equal (slot-value orderpref 'sat) "Y")  "Sa ")))
	  (:td  :height "12px" (cl-who:str (slot-value orderpref 'prd-qty)))
	  (:td  :height "12px" (cl-who:str (slot-value opf-product  'qty-per-unit)))
	  (:td  :height "12px" (cl-who:str (format nil "Rs. ~$"  (slot-value opf-product  'unit-price))))     
	  (:td :height "12px" (:a  :onclick "return DeleteConfirm();" :href  (format nil  "delopref?id=~A" opf-id ) (:span :class "glyphicon glyphicon-remove"))))))
  
  

