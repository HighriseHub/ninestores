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

(defun product-card-with-details-for-customer2 (proddetailpagetempl)
  (cl-who:with-html-output (*standard-output* nil)
    (cl-who:str proddetailpagetempl)))

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


(defun create-model-for-prddetailsforcustomer ()
  (let* ((prd-id (parse-integer (hunchentoot:parameter "id")))
	 (productlist (if (> prd-id 0) (hunchentoot:session-value :login-prd-cache)))
	 (lstshopcart (hunchentoot:session-value :login-shopping-cart))
	 (numitemsincart (Length lstshopcart))
	 (product (if (> prd-id 0) (search-item-in-list 'row-id prd-id productlist)))
	 (prdincart-p (prdinlist-p (slot-value product 'row-id)  lstshopcart))
	 (customer (get-login-customer))
	 (company (product-company product))
	 (description (slot-value product 'description))   
	 (product-sku (slot-value product 'sku))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (product-pricing (select-product-pricing-by-product-id prd-id company))
	 (product-pricing-widget (cl-who:with-html-output-to-string  (*standard-output* nil)
				   (product-price-with-discount-widget product product-pricing)))
	 (prd-name (slot-value product 'prd-name))
	 (product-images-carousel (cl-who:with-html-output-to-string  (*standard-output* nil)
				    (render-multiple-product-images prd-name imageslst images-str)))
	 (product-images-thumbnails (cl-who:with-html-output-to-string  (*standard-output* nil)
				  (render-multiple-product-thumbnails prd-name imageslst images-str)))
	 (proddetailpagetempl (funcall (nst-get-cached-product-template-func :templatenum 1)))	 
	 (qtyperunit-str  (format nil "~A" (slot-value product 'qty-per-unit)))
	 (unit-of-measure (slot-value product 'unit-of-measure))
	 (unitsinstock-str (format nil "~A" (slot-value product 'units-in-stock)))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (addtocart-widget (cl-who:with-html-output-to-string  (*standard-output* nil)
			     (customer-add-to-cart-widget units-in-stock product product-pricing prd-id prdincart-p numitemsincart)))
	 (external-url (slot-value product 'external-url))
	 (subscribe-flag (slot-value product 'subscribe-flag))
	 (cust-type (slot-value customer 'cust-type))
	 (prd-vendor (product-vendor product))
	 (subscription-plan (slot-value company 'subscription-plan))
	 (cmp-type (slot-value company 'cmp-type))
	 (vendor-id (slot-value prd-vendor 'row-id)))
    
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product Name%" proddetailpagetempl prd-name))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Qty-Per-Unit%" proddetailpagetempl qtyperunit-str))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Unit-Of-Measure%" proddetailpagetempl unit-of-measure))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-SKU%" proddetailpagetempl product-sku))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Description%" proddetailpagetempl description))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Units-In-Stock%" proddetailpagetempl unitsinstock-str))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Add-to-Cart-Button%" proddetailpagetempl addtocart-widget))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Pricing-Control%" proddetailpagetempl product-pricing-widget))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Images-Carousel%" proddetailpagetempl product-images-carousel))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Images-Thumbnails%" proddetailpagetempl product-images-thumbnails))
    
    (function (lambda ()
      (values proddetailpagetempl  prd-id  cmp-type subscribe-flag cust-type subscription-plan external-url  vendor-id)))))

(defun dod-controller-prd-details-for-customer ()
   (with-cust-session-check 
     (with-mvc-ui-page "Product Details Customer" #'create-model-for-prddetailsforcustomer #'create-widgets-for-prddetailsforcustomer :role :customer)))
