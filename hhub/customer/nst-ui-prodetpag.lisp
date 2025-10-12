;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


;; Product details for customer page

(defun customer-product-detail-menu-widget (prd-id cmp-type subscribe-flag cust-type subscription-plan external-url  vendor-id)
  (make-ui-widget
   (lambda ()
     (cl-who:with-html-output (*standard-output* nil)        
       (with-html-div-row :style "border-radius: 5px;background-color:#e6f0ff; border-bottom: solid 1px; margin: 15px; padding: 10px; height: 35px; font-size: 1rem;background-image: linear-gradient(to top, #accbee 0%, #e7f0fd 100%);"
	 (with-html-div-col-2 :data-bs-toggle "tooltip" :title "Back to Shopping"
	   (:a  :href "/hhub/dodcustindex" (:i :class "fa-solid fa-arrow-left")))
	 (with-html-div-col-2 
	   ;; display the subscribe button under certain conditions. 
	   (when (and (equal subscribe-flag "Y")
		      (com-hhub-attribute-company-prdsubs-enabled subscription-plan cmp-type) 
		      (equal cust-type "STANDARD"))
	     (cl-who:htm
	      (:button :data-bs-toggle "modal" :data-bs-target (format nil "#productsubscribe-modal~A" prd-id)  :href "#"   :class "subscription-btn" :id (format nil "btnsubscribe~A" prd-id) :name (format nil "btnsubscribe~A" prd-id) "Subscribe&nbsp;" (:i :class "fa-solid fa-hand-point-up"))
	      (modal-dialog-v2 (format nil "productsubscribe-modal~A" prd-id) "Subscribe Product/Service" (product-subscribe-html prd-id)))))
	 (with-html-div-col-2
	   (when external-url
	     (cl-who:htm
	      (:div  :data-toggle "tooltip" :title "Share Product"
		     (:a :id "idshareexturl" :href "#" (:i :class  "fa-solid fa-arrow-up-from-bracket")))
	      (sharetextorurlonclick "#idshareexturl" (parenscript:lisp external-url)))))
	 (with-html-div-col-2 :data-toggle "tooltip" :title "Contact Seller"  
	   (:a :data-bs-toggle "modal" :data-bs-target (format nil "#vendordetails-modal~A" vendor-id)  :href "#" :name "btnvendormodal"  (:i :class "fa-solid fa-address-card"))
	   (modal-dialog-v2 (format nil "vendordetails-modal~A" vendor-id) (cl-who:str (format nil "Vendor Details")) (modal.vendor-details vendor-id)))
	 (with-html-div-col-3 :data-toggle "tooltip" :title "Visit Store"  
	   (:p (:a :href (format nil "hhubcustvendorstore?id=~A" vendor-id) (:i :class "fa-solid fa-store")))))
       (:hr)))))

(defun customer-product-detail-content-widget (proddetailpagetempl)
  (make-ui-widget 
   (lambda ()
     (product-card-with-details-for-customer2  proddetailpagetempl))))

(defun customer-product-detail-page-component ()
  (make-ui-component :customer-product-detail-page-component
		     (lambda (mf)
		       (multiple-value-bind (proddetailpagetempl prd-id cmp-type subscribe-flag cust-type subscription-plan external-url  vendor-id) (funcall mf)
			 (list (customer-product-detail-menu-widget prd-id cmp-type subscribe-flag cust-type subscription-plan external-url  vendor-id)
			       (customer-product-detail-content-widget proddetailpagetempl))))))

(defun customer-product-detail-page ()
  (make-ui-page :customer
		:customer-product-detail-page
		(customer-product-detail-page-component)))

(defun create-widgets-for-prddetailsforcustomer (modelfunc)
  (render-ui-page (customer-product-detail-page) modelfunc))

(defun dod-controller-prd-details-for-customer ()
   (with-cust-session-check 
     (with-mvc-ui-page "Product Details Customer" #'create-model-for-prddetailsforcustomer #'create-widgets-for-prddetailsforcustomer :role :customer)))
