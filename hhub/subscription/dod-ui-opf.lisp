;; -*- mode: common lisp; coding: utf-8 -*-
(in-package :nstores)

(defun dod-controller-my-orderprefs ()
  (with-cust-session-check
    (with-mvc-ui-page "Customer Order Subscriptions" #'create-model-for-custordersubs #'create-widgets-for-custordersubs :role :customer)))


(defun create-model-for-custordersubs ()
  (let ((dodorderprefs (hunchentoot:session-value :login-cusopf-cache))
	(header (list  "Product"  "Day"  "Qty" "Qty Per Unit" "Actions")))
    (function (lambda ()
      (values dodorderprefs header)))))

(defun create-widgets-for-custordersubs (modelfunc)
  (multiple-value-bind
	(dodorderprefs header)
      (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)  
		       (with-html-div-row
			 (with-html-div-col (:h3 "My Subscriptions."))      
			 (with-html-div-col (:a :class "btn btn-primary" :role "button" :href (format nil "dodcustindex") "Shop Now")))
		       (with-html-div-row :id "idcustsubscriptions"
			 (cl-who:str (display-as-table header dodorderprefs 'cust-opf-as-row)))))))
	  (widget2 (function (lambda ()
		     (submitformevent-js "#idcustsubscriptions")))))
      (list widget1 widget2))))


(defun cust-opf-as-row (orderpref &rest params)
  (declare (ignore params))
  (let* ((opf-id (slot-value orderpref 'row-id))
	 (opf-product (get-opf-product orderpref))
	 (prd-name (slot-value opf-product  'prd-name)))
    (cl-who:with-html-output (*standard-output* nil)
      
      (:td  :height "12px" (cl-who:str prd-name))
      (:td :height "12px"    (cl-who:str (if (equal (slot-value orderpref 'sun) "Y") "Su, "))
	       (cl-who:str (if (equal (slot-value orderpref 'mon) "Y") "Mo, "))
	       (cl-who:str (if (equal (slot-value orderpref 'tue) "Y")  "Tu, "))
	       (cl-who:str (if (equal (slot-value orderpref 'wed) "Y") "We, "))
	       (cl-who:str (if (equal (slot-value orderpref 'thu) "Y")  "Th, "))
	       (cl-who:str (if (equal (slot-value orderpref 'fri) "Y") "Fr, "))
	       (cl-who:str (if (equal (slot-value orderpref 'sat) "Y")  "Sa ")))
      (:td  :height "12px" (cl-who:str (slot-value orderpref 'prd-qty)))      (:td  :height "12px" (cl-who:str (slot-value opf-product  'qty-per-unit)))
      (:td :height "12px"
	   (:a  :data-bs-toggle "modal" :data-bs-target (format nil "#productsubsdelete-modal~A" opf-id) :data-toggle "tooltip" :title "Delete Subscription"  :href "#"  :id (format nil "btndeletesubs_~A" opf-id) :name (format nil "btndeletesubs~A" opf-id) (:i :class "fa-regular fa-trash-can"))
	   (modal-dialog-v2 (format nil "productsubsdelete-modal~A" opf-id) (cl-who:str (format nil "Delete Product Subscription")) (modal.delete-subscription orderpref))))))
	    

(defun modal.delete-subscription (subscription)
  (let* ((id (slot-value subscription 'row-id))
	(opf-product (get-opf-product subscription))
        (prd-name (slot-value opf-product  'prd-name)))
    (cl-who:with-html-output (*standard-output* nil)
      (:span  :height "12px" (cl-who:str prd-name))
      (with-html-form "deletesubscriptionform" "dodcustdelopfaction" 
	(with-html-input-text-hidden "id" id)
	(:input :type "submit" :class "btn btn-lg btn-danger"  :value "Delete")))))
  

