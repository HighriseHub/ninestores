(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


(defun ui-list-prod-catg-dropdown (catglist selectedvalue)
  (cl-who:with-html-output (*standard-output* nil)
    (cl-who:htm (:select :class "form-control" :name "prodcatg" 
      (loop for catg in catglist
	    do (if (and selectedvalue (equal (slot-value catg 'row-id) (slot-value selectedvalue 'row-id)))
		    (cl-who:htm  (:option :selected "true"  :value  (slot-value catg 'row-id) (cl-who:str (slot-value catg 'catg-name))))
		    ;;else
		    (cl-who:htm  (:option :value  (slot-value catg 'row-id) (cl-who:str (slot-value catg 'catg-name))))))))))

(defun ui-list-yes-no-dropdown (value) 
  (cl-who:with-html-output (*standard-output* nil) 
    (:select :class "form-control" :name "yesno"
	     (if (equal value "N") (cl-who:htm (:option :value "N" "NO" :selected)
					       (:option :value "Y" "YES"))
		 (cl-who:htm (:option :value "Y" "YES" :selected)
			     (:option :value "N" "NO"))))))
	   
(defun ui-list-prod-catg (catglist)
  (cl-who:with-html-output (*standard-output* nil)
    (:span (:h5 "Product Categories"))
    (:div :class "prd-catg-container" :style "width: 100%; display:flex; overflow:auto;"
	  (with-html-div-row :style "padding: 30px 20px; display: flex; align-items:center; justify-content:center; flex-wrap: nowrap;"  
	    (mapcar (lambda (prdcatg)
		      (cl-who:htm
		       (:div :class "prd-catg-card" (prdcatg-card prdcatg ))))
		    catglist)))
    (:hr)))


(defun ui-list-customer-products (data lstshopcart)
  (cl-who:with-html-output (*standard-output* nil)
    (:div :id "prdlivesearchresult" 
	  (cl-who:str (render-products-list data lstshopcart)))))

(defun render-products-list (data lstshopcart)
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "all-products" 
	  (display-product-cards data lstshopcart))))

     

(defun ui-list-cust-products-horizontal (data lstshopcart)
  (cl-who:with-html-output (*standard-output* nil)
    (:div :id "idprd-catg-container" :class "prd-catg-container" :style "width: 100%; display:flex; overflow:auto;"
	  (with-html-div-row :style "padding: 30px 20px; display: flex; align-items:center; justify-content:center; flex-wrap: nowrap;"  
	    (display-product-cards data lstshopcart)))))


(defun display-product-cards (data lstshopcart)
  (cl-who:with-html-output (*standard-output* nil)
    (mapcar (lambda (product)
	      (let* ((vendor-id (slot-value (product-vendor product) 'row-id))
		     (active-vendor (hunchentoot:session-value :login-active-vendor))
		     (active-vendor-id (when active-vendor (slot-value active-vendor 'row-id))))
		(when (or (null active-vendor) (equal vendor-id active-vendor-id))
		  (cl-who:htm
		   (:div :class "product-card" (product-card product  (prdinlist-p (slot-value product 'row-id)  lstshopcart))))))) data )))

(defun product-card-shopcart (product-instance odt-instance)
    (let* ((prd-name (slot-value product-instance 'prd-name))
	   (qty-per-unit (slot-value product-instance 'qty-per-unit))
	   (prdqty (slot-value odt-instance 'prd-qty))
	   (units-in-stock (slot-value product-instance 'units-in-stock))
	   (images-str (slot-value product-instance 'prd-image-path))
	   (imageslst (safe-read-from-string images-str))
	   (prd-id (slot-value product-instance 'row-id))
	   (pricewith-discount (calculate-order-item-cost odt-instance))
	   (subtotal (* prdqty pricewith-discount)))
      (cl-who:with-html-output (*standard-output* nil)
	(:span (cl-who:str (format nil "~A" prdqty)))
	(:span (:p (:a :href (format nil "prddetailsforcust?id=~A" prd-id) (render-single-product-image prd-name imageslst images-str "70" "50"))))
	(:span (cl-who:str (format nil "~A: ~A/~A" prd-name pricewith-discount qty-per-unit)))
	;;(:div (:p  (cl-who:str (format nil "  ~A. Fulfilled By: ~A" qty-per-unit (name prd-vendor)))))
	(:div
	 (:span (:p (:span :class "label label-success" (cl-who:str (format nil "~A ~$" *HTMLRUPEESYMBOL* subtotal)))))
	 (:span 
	  (:a  :data-bs-toggle "modal" :data-bs-target (format nil "#producteditqty-modal~A" prd-id) :data-toggle "tooltip" :title "Modify"  :href "#" :onclick "addtocartclick(this.id);" :id (format nil "btnaddproduct_~A" prd-id) :name (format nil "btnaddproduct~A" prd-id) (:i :style "width: 15px; height: 15px; font-size: 20px;" :class "fa-regular fa-pen-to-square") "&nbsp;&nbsp;")
	  (modal-dialog-v2 (format nil "producteditqty-modal~A" prd-id) (cl-who:str (format nil "Edit Product Quantity - Available: ~A" units-in-stock)) (product-qty-edit-html product-instance odt-instance)))

	 (:span 
	  (:a  :data-bs-toggle "modal" :data-bs-target (format nil "#productremoveshopcart-modal~A" prd-id) :data-toggle "tooltip" :title "Remove From Shopcart"  :href "#" :id (format nil "btnremoveproduct_~A" prd-id) :name (format nil "btnremoveproduct~A" prd-id) (:i :style "width: 15px; height: 15px; font-size: 20px;" :class "fa-solid fa-trash-can") "&nbsp;&nbsp;")
	  (modal-dialog-v2 (format nil "productremoveshopcart-modal~A" prd-id) (cl-who:str (format nil "Remove Product From Shopcart"))  (modal.product-remove-from-shopcart product-instance)))))))

(defun modal.product-remove-from-shopcart (product)
  (let* ((id (slot-value product 'row-id))
	(prd-name (slot-value product 'prd-name))
	(images-str (slot-value product 'prd-image-path))
	(imageslst (safe-read-from-string images-str)))
    (cl-who:with-html-output (*standard-output* nil)
      (:span (:p (:a :href "#" (render-single-product-image prd-name imageslst images-str "50" "70"))))
      (with-html-form "removeproductfromshopcart" "dodcustremshctitem" 
	(with-html-input-text-hidden "id" id)
	(with-html-input-text-hidden "action" "remitem")
	(:input :type "submit" :class "btn btn-lg btn-danger"  :value "Remove")))))
  

(defun product-card-for-email (product-instance odt-instance)
  (let* ((prd-name (slot-value product-instance 'prd-name))
	 (qty-per-unit (slot-value product-instance 'qty-per-unit))
	 (prdqty (slot-value odt-instance 'prd-qty))
	 (images-str (slot-value product-instance 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (subtotal (calculate-order-item-cost odt-instance)) 
	 (prd-vendor (product-vendor product-instance)))
    (cl-who:with-html-output (*standard-output* nil)
      (:tr 
       (:td (render-single-product-image prd-name imageslst images-str "50" "50"))
					;Product name and other details
       (:td
	(:h5 :class "product-name"  (cl-who:str prd-name))
	(:p   (cl-who:str (format nil "  ~A. Fulfilled By: ~A" qty-per-unit (name prd-vendor)))))
       (:td
	(:h5 :class "product-name" (cl-who:str prdqty)))
       (:td
	(:h3 (:span :class "label label-default" (cl-who:str (format nil "~$" subtotal)))))))))






(defun product-card-shopcart-readonly (product-instance odt-instance)
  (let* ((prd-name (slot-value product-instance 'prd-name))
	 (qty-per-unit (slot-value product-instance 'qty-per-unit))
	 (prdqty (slot-value odt-instance 'prd-qty))
	 (images-str (slot-value product-instance 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (subtotal (calculate-order-item-cost odt-instance))) 
    (cl-who:with-html-output (*standard-output* nil)
       (:a :href "#" (render-single-product-image prd-name imageslst images-str "83" "100"))
       (:p  (cl-who:str (format nil "~A-~A" prd-name qty-per-unit)))
       (:p  (cl-who:str (format nil "~A" prdqty )))
       (:div :class "txt-bg-success p3" (cl-who:str (format nil "~A ~$"  *HTMLRUPEESYMBOL* subtotal))))))



(defun prdcatg-card (prdcatg-instance)
    (let ((catg-name (slot-value prdcatg-instance 'catg-name))
	  (row-id (slot-value prdcatg-instance 'row-id)))
	(cl-who:with-html-output (*standard-output* nil)
	  (:a :href (format nil "dodproductsbycatg?id=~A" row-id) (cl-who:str catg-name)))))


(defun modal.vendor-product-edit-html (product mode) 
  (let* ((description (slot-value product 'description))
	 (subscribe-flag (slot-value product 'subscribe-flag))
	 (qty-per-unit (slot-value product 'qty-per-unit))
	 (unit-of-measure (slot-value product 'unit-of-measure))
	 (units-in-stock (slot-value product 'units-in-stock))
	 (prd-id (slot-value product 'row-id))
	 (catg-id (slot-value product 'catg-id))
	 (prd-name (slot-value product 'prd-name))
	 (prd-type (slot-value product 'prd-type))
	 (hsncode (slot-value product 'hsn-code))
	 (sku (slot-value product 'sku))
	 (upc (slot-value product 'upc))
	 (catglist (hhub-get-cached-product-categories))
	 (idtextarea (format nil "~Atextarea~A" (gensym "hhub") prd-id))
	 (idisserviceproduct (format nil "idserviceproduct~A~A" (gensym "hhub") prd-id))
	 (prdcategory (when catg-id (search-prdcatg-in-list catg-id catglist)))
	 (charcountid1 (format nil "idchcount~A" (hhub-random-password 3))))
 (cl-who:with-html-output (*standard-output* nil)
   (with-html-div-row 
     (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
	   (with-html-form (format nil "form-vendorprod~A" mode) "dodvenaddproductaction" 
	     (if (and product (equal mode "EDIT"))
		 (cl-who:htm (:input :class "form-control" :type "hidden" :value prd-id :name "prd-id"))
		 ;; else
		 (cl-who:htm (:input :class "form-control" :type "hidden" :value 0 :name "prd-id")))
	     (:div :class "form-group"
		   (:label :for idisserviceproduct "This is a Service&nbsp;")
		   (if (equal prd-type "SERV")
		       (cl-who:htm
			(:input :type "checkbox" :id idisserviceproduct :name "isserviceproduct" :checked "true" :value "Y"  :onclick (parenscript:ps (togglecheckboxvalueyn (parenscript:lisp idisserviceproduct)))))
		       ;;else
		       (cl-who:htm 
			(:input :type "checkbox" :id idisserviceproduct :name "isserviceproduct" :value "N"  :onclick (parenscript:ps (togglecheckboxvalueyn (parenscript:lisp idisserviceproduct))))))
		   (:input :class "form-control" :name "prdname" :value prd-name :placeholder "Enter Product Name ( max 30 characters) " :type "text" ))
	     (:div  :class "form-group"
		    (:label :for "description" "Description")
		    (text-editor-control idtextarea  description))
	     (:textarea :style "display: block;" :id idtextarea :class "form-control" :name "description"  :placeholder "Enter Product Description ( max 2000 characters) "  :rows "5" :onkeyup (format nil "countChar(~A.id, this, 2000)" charcountid1) (cl-who:str (format nil "~A" description)))
	     (:div :class "form-group" :id charcountid1 )
	     (:div :class "form-group"
		   (with-html-input-text "hsn-code" "HSN/SAC Code" "HSN/SAC Code" hsncode T "Enter HSN/SAC Code" 4))
	     (:div :class "form-group"
		   (with-html-input-text "sku" "SKU" "SKU" sku nil "Enter SKU" 5))
	     (:div :class "form-group"
		   (with-html-input-text "upc" "UPC Barcode" "UPC Barcode" upc nil "Enter UPC Barcode" 6))
	     (:div :class "form-group"
		   (:label :for "qtyperunit" "Qty Per Unit")
		   (:input :class "form-control" :name "qtyperunit"  :value qty-per-unit :type  "number" :min 1 :max 10000  ))
	     (:div :class "form-group"
		   (:label :for "unitofmeasure" "Unit Of Measure")
		   (with-html-dropdown "unitofmeasure" (get-system-UOM-map) unit-of-measure))
	     (:div  :class "form-group" (:label :for "prodcatg" "Select Produt Category:" )
		    (ui-list-prod-catg-dropdown catglist prdcategory))
	     (:div :class "form-group"
		   (:input :class "form-control" :name "unitsinstock" :placeholder "Units In Stock"  :value units-in-stock  :type "number" :min "1" :max "10000" :step "1"  ))
	     
	     (:br) 
	     (:div :class "form-group" (:label :for "yesno" "Enable Subscription")
		   (if (equal subscribe-flag "Y") (ui-list-yes-no-dropdown "Y")
		       (ui-list-yes-no-dropdown "N")))
	     (:div :class "form-group"
		   (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))))
;; We need to write all the details of the file upload logic here.
;; Need to support upload of 5 files
(defun modal.vendor-upload-product-images (product) 
  (let* ((prd-id (slot-value product 'row-id)))
    (cl-who:with-html-output (*standard-output* nil)
      (with-catch-file-upload-event "fileUploadForm"
	(with-html-div-row 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12" 
		(with-html-form "fileUploadForm" "vuploadprdimagesaction" 
		  (if product (cl-who:htm (:input :class "form-control" :type "hidden" :id "prd-id" :value prd-id :name "prd-id")))
		  (:div :class "form-group" :id "fileuploadprogress")
		  (:div :class "form-group" (:label :for "prdimage1" "Select Upto 5 Product Images:")
			(:input :id "idprdimgfileupldctrl" :class "form-control"  :name "uploadedimagefiles" :placeholder "Product Image" :onchange "validateFileSize(event);" :type "file" :multiple t ))
		  (:div :class "form-group"
			(:button :id "btnprdimageuploadreset"  :class "btn btn-lg btn-primary btn-block" :onclick "resetFileUpload(event);" :type "button" "Reset")
			(:button :id "btnprdimageupload"  :class "btn btn-lg btn-primary btn-block"  :type "submit" "Upload"))
		  ;; Image previews
		  (:div 
		   (:img :src "" :id "img_url_1" :alt "Preview 1" :style "width:100px; height:100px; display:none")
		   (:img :src "" :id "img_url_2" :alt "Preview 2" :style "width:100px; height:100px; display:none")
		   (:img :src "" :id "img_url_3" :alt "Preview 3" :style "width:100px; height:100px; display:none")
		   (:img :src "" :id "img_url_4" :alt "Preview 4" :style "width:100px; height:100px; display:none") 
		   (:img :src "" :id "img_url_5" :alt "Preview 5" :style "width:100px; height:100px; display:none")))))))))


(defun modal.vendor-product-shipping-html (product mode)
  (let* ((prd-id (slot-value product 'row-id))
	 (prd-name (slot-value product 'prd-name))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (shipping-length-cms (slot-value product 'shipping-length-cms))
	 (shipping-width-cms (slot-value product 'shipping-width-cms))
	 (shipping-height-cms (slot-value product 'shipping-height-cms))
	 (shipping-weight-kg (slot-value product 'shipping-weight-kg)))
    (cl-who:with-html-output (*standard-output* nil)
   (with-html-div-row 
     (with-html-div-col-12
       (with-html-form (format nil "form-vendorprodship~A" mode) "hhubvendaddprodshipinfoaction" 
	 (if (and product (equal mode "EDIT"))
	     (cl-who:htm (with-html-input-text-hidden "id" prd-id)))
	 (:h1 :class "text-center login-title"  "Shipping Information")
	 (:div :align "center"  :class "form-group" 
	       (render-single-product-image prd-name imageslst images-str "100" "83"))
	 (:div :class "form-group"
	       (with-html-input-text "shipping-length-cms" "Shipping Length" "Enter Product length in CM" shipping-length-cms T "Enter Shipping Length in CM" 1))
	 (:div :class "form-group"
	       (with-html-input-text "shipping-width-cms" "Shipping Width" "Enter Product width in CM" shipping-width-cms T "Enter Shipping Width in CM" 2))
	 (:div :class "form-group"
	       (with-html-input-text "shipping-height-cms" "Shipping Height" "Enter Product height in CM" shipping-height-cms T "Enter Shipping Height in CM" 3))
	 (:div :class "form-group"
	       (with-html-input-text "shipping-weight-kg" "Shipping Weight" "Enter Product weight in KG" shipping-weight-kg T "Enter Shipping Weight in KG" 1))
	 (:div :class "form-group"
	       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))))




		    

(defun modal.vendor-product-reject-html (prd-id tenant-id)
  (let* ((company (select-company-by-id tenant-id))
	 (product (select-product-by-id prd-id company))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (description (slot-value product 'description))
	 (prd-name (slot-value product 'prd-name))
	 (prd-id (slot-value product 'row-id)))
 (cl-who:with-html-output (*standard-output* nil)
   (with-html-div-row 
     (with-html-div-col-12
       (:form :id (format nil "form-vendorprod")  :role "form" :method "POST" :action "hhubcadprdrejectaction" :enctype "multipart/form-data" 
					;(:div :class "account-wall"
	      (:input :class "form-control" :type "hidden" :value prd-id :name "id")
	      (:div :align "center"  :class "form-group"
		    (render-single-product-image prd-name imageslst images-str "100" "83"))
	      
	      (:h1 :class "text-center login-title"  "Reject Product")
	      (:div :class "form-group"
		    (:input :class "form-control" :name "prdname" :value prd-name :placeholder "Enter Product Name ( max 30 characters) " :type "text" :readonly "true" ))
	      (:div :class "form-group"
		    (:label :for "description" "Enter Rejection Reason")
		    (:textarea :class "form-control" :name "description"  :placeholder "Enter Reject Reason "  :rows "5" :onkeyup "countChar(this, 1000)" (cl-who:str (format nil "~A" description))))
	      (:div :class "form-group" :id "charcount")
	      (:div :class "form-group"
		    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Reject"))))))))


(defun modal.vendor-product-accept-html (prd-id tenant-id)
  (let* ((company (select-company-by-id tenant-id))
	 (product (select-product-by-id prd-id company))
	 (images-str (slot-value product 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (description (slot-value product 'description))
	 (prd-name (slot-value product 'prd-name))
	 (prd-id (slot-value product 'row-id)))
 (cl-who:with-html-output (*standard-output* nil)
   (with-html-div-row
     (with-html-div-col-12
       (:form :id (format nil "form-vendorprod")  :role "form" :method "POST" :action "hhubcadprdapproveaction" :enctype "multipart/form-data" 
					;(:div :class "account-wall"
	      (:input :class "form-control" :type "hidden" :value prd-id :name "id")
	      (:div :align "center"  :class "form-group"
		    (render-single-product-image prd-name imageslst images-str "100" "83"))
	      (:h1 :class "text-center login-title"  "Accept Product")
	      (:div :class "form-group"
		    (:input :class "form-control" :name "prdname" :value prd-name :placeholder "Enter Product Name ( max 30 characters) " :type "text" :readonly "true" ))
	      (:div :class "form-group"
		    (:label :for "description")
		    (:textarea :class "form-control" :name "description"  :placeholder "Description "  :rows "5" :onkeyup "countChar(this, 1000)" (cl-who:str (format nil "~A" description))))
	      (:div :class "form-group" :id "charcount")
	      (:div :class "form-group"
		    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Approve"))))))))


(defun modal.vendor-product-pricing (product product-pricing)
  (let* ((prd-id (slot-value product 'row-id))
	(images-str (slot-value product 'prd-image-path))
	(imageslst (safe-read-from-string images-str))
	(prd-name (slot-value product 'prd-name))
	(current-price (slot-value product 'current-price))
	(pricing-id (if product-pricing (slot-value product-pricing 'row-id)))
	(price (if product-pricing (slot-value product-pricing 'price)))
	(discount (if product-pricing (slot-value product-pricing 'discount)))
	(start-date (if product-pricing (get-date-string (slot-value product-pricing 'start-date))))
	(end-date (if product-pricing (get-date-string (slot-value product-pricing 'end-date))))
	(vendprodpricingform-id (format nil "vendprodpricingform~A" (gensym)))
	(idpricingstartdate (format nil "idpricingstartdate~A" (gensym)))
	(idpricingenddate (format nil "idpricingenddate~A" (gensym)))
	(startdateplaceholder (format nil "~A. Click to change" (get-date-string (clsql-sys::get-date))))
	(enddateplaceholder (format nil "~A. Click to change" (get-date-string (clsql::date+ (clsql::get-date) (clsql::make-duration :day 180))))))
			    
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-div-row
        (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"                                                                                                                                                     
	      (with-html-form vendprodpricingform-id "hhubvendprodpricingsaveaction"
		(:input :class "form-control" :type "hidden" :value prd-id :name "prdid")
		(:input :class "form-control" :type "hidden" :value pricing-id :name "pricingid")
		(:div :align "center"  :class "form-group"
		      (render-single-product-image prd-name imageslst images-str "100" "83"))
		(:div :class "form-group"
		      (:label :for "prdprice" "Price" )
		      (:input :class "form-control" :name "prdprice"  :value (if product-pricing (format nil "~$" price) (format nil "~$" current-price))  :type "number" :step "0.05" :min "0.00" :max "10000.00" :step "0.10"  ))
		(:div :class "form-group"
		      (:label :for "prddiscount" "Discount % - Enter a number" )
		      (:input :class "form-control" :name "prddiscount"  :value (format nil "~$" discount)  :type "number" :step "0.05" :min "0.00" :max "10000.00" :step "0.10"  ))
		(:div :class "form-group"  (:label :for "startdate" "Start Date - Click To Change" )
		      (:input :class "form-control" :name "startdate" :id idpricingstartdate :placeholder  (cl-who:str startdateplaceholder)  :type "text" :value (if start-date start-date (get-date-string (clsql-sys::get-date)))))
		(:div :class "form-group"  (:label :for "enddate" "End Date - Click To Change" )
		      (:input :class "form-control" :name "enddate" :id idpricingenddate :placeholder  (cl-who:str enddateplaceholder)  :type "text" :value (if end-date end-date (get-date-string (clsql-sys:date+ (clsql-sys:get-date) (clsql-sys:make-duration :day 180))))))
				 
		(:div :class "form-group"
		      (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))
	(:script (cl-who:str (format nil "$(document).ready(
        function() {    
        $('#~A').datepicker({dateFormat: 'dd/mm/yy', minDate: 0} ).attr('readonly', 'true'); 
        $('#~A' ).datepicker({dateFormat: 'dd/mm/yy', minDate: 1} ).attr('readonly', 'true');    
         }
);" idpricingstartdate idpricingenddate)))))))
		

(defun vendor-product-actions-menu (product-instance)
  (let* ((prd-id (slot-value product-instance 'row-id))
	 (active-flag (slot-value product-instance 'active-flag))
	 (external-url (slot-value product-instance 'external-url))
	 (shipping-weight-kg (slot-value product-instance 'shipping-weight-kg))
	 (company (product-company product-instance))
	 (currency (get-account-currency company))
	 (product-pricing (select-product-pricing-by-product-id prd-id company)))
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-div-row :style "border-radius: 5px;background-color:#e6f0ff; border-bottom: solid 1px; margin: 15px; padding: 10px; height: 35px; font-size: 1rem;background-image: linear-gradient(to top, #accbee 0%, #e7f0fd 100%);"
	(if (equal active-flag "Y")
	    (cl-who:htm
	     (with-html-div-col-1 :data-bs-toggle "tooltip" :title "Turn Off" 
	       (:a   :href (format nil "dodvenddeactivateprod?id=~A" prd-id) (:i :class "fa-solid fa-power-off"))))
					;else
	    (cl-who:htm
	     (with-html-div-col-1 :data-bs-toggle "tooltip" :title "Turn On" 
	       (:a :href (format nil "dodvendactivateprod?id=~A" prd-id) (:i :class "fa-solid fa-power-off")))))
	(with-html-div-col-1 :data-bs-toggle "tooltip" :title "Copy" 
	  (:a :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendcopyprod-modal~A" prd-id)  :href "#"  (:i :class "fa-regular fa-clone"))
	  (modal-dialog-v2 (format nil "dodvendcopyprod-modal~A" prd-id) "Copy Product" (modal.vendor-product-edit-html  product-instance "COPY")))
	
	(with-html-div-col-1  :data-bs-toggle "tooltip" :title "Edit" 
	  (:a :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendeditprod-modal~A" prd-id)  :href "#"  (:i :class "fa-solid fa-pencil"))
	  (modal-dialog-v2 (format nil "dodvendeditprod-modal~A" prd-id) "Edit Product" (modal.vendor-product-edit-html product-instance  "EDIT"))) 
	(with-html-div-col-1  :data-bs-toggle "tooltip" :title "SKU Generator" 
	(:a :data-bs-toggle "modal" :data-bs-target (format nil "#generatesku-modal")  :href "#"  (:i :class "fa-solid fa-wand-magic-sparkles"))
	  (modal-dialog-v2 (format nil "generatesku-modal") "SKU Generator" (modal.generate-sku-dialog)))
	(with-html-div-col-1  :data-bs-toggle "tooltip" :title "Upload Product Images" 
	  (:a :data-bs-toggle "modal" :data-bs-target (format nil "#dodvenduploadprodimages-modal~A" prd-id)  :href "#"  (:i :class "fa-solid fa-upload"))
	  (modal-dialog-v2 (format nil "dodvenduploadprodimages-modal~A" prd-id) "Upload Product Images" (modal.vendor-upload-product-images product-instance)))
	(unless external-url
	  (cl-who:htm 
	   (with-html-div-col-1 :data-bs-toggle "tooltip" :title "Information: Edit & Save to enable sharing" 
	     (:a :href "#" (:i :class  "fa-solid fa-share-nodes")))))
	(when external-url
	  (cl-who:htm
	   (with-html-div-col-1  :data-bs-toggle "tooltip" :title "Copy External URL" 
	     (:a :href "#" :OnClick (parenscript:ps (copy-to-clipboard (parenscript:lisp external-url))) (:i :class  "fa-solid fa-share-nodes")))))
	
	    (with-html-div-col-1  :data-bs-toggle "tooltip" :title "Shipping" 
	      (if (and shipping-weight-kg (> shipping-weight-kg 0)) 
		  (cl-who:htm
		   (:a :data-bs-toggle "modal" :data-bs-target (format nil "#dodprodshipping-modal~A" prd-id)  :href "#"  (:i :class "fa-solid fa-truck")))
		  ;;else
		  (cl-who:htm
		   (:a :style "color:red;" :data-bs-toggle "modal" :data-bs-target (format nil "#dodprodshipping-modal~A" prd-id)  :href "#"  (:i :class "fa-solid fa-truck"))))
	      (modal-dialog-v2 (format nil "dodprodshipping-modal~A" prd-id) "Shipping" (modal.vendor-product-shipping-html product-instance "EDIT")))
	(with-html-div-col-1  :data-bs-toggle "tooltip" :title "Discounts" 
		(if product-pricing 
		    (cl-who:htm
		     (:a :data-bs-toggle "modal" :data-bs-target (format nil "#dodprodpricing-modal~A" prd-id)  :href "#"  (:i :class (get-currency-fontawesome-symbol currency)))
		     (modal-dialog-v2 (format nil "dodprodpricing-modal~A" prd-id) "Pricing" (modal.vendor-product-pricing product-instance product-pricing)))
		    ;; else
		    (cl-who:htm
		     (:a :style "color:red;" :data-bs-toggle "modal" :data-bs-target (format nil "#dodprodpricing-modal~A" prd-id)  :href "#"  (:i :class (get-currency-fontawesome-symbol currency)))
		     (modal-dialog-v2 (format nil "dodprodpricing-modal~A" prd-id) "Pricing" (modal.vendor-product-pricing product-instance product-pricing)))))
	(with-html-div-col-1 "&nbsp;")
	(with-html-div-col-1 "&nbsp;")
	(with-html-div-col-2 :align "right" :data-bs-toggle "tooltip" :title "Delete" 
	  (:a :onclick "return DeleteConfirm();"  :href (format nil "dodvenddelprod?id=~A" prd-id) (:i :class "fa-solid fa-trash-can")))))))


(defun product-card-for-vendor (product-instance)
  (let* ((prd-name (slot-value product-instance 'prd-name))
	 (units-in-stock (slot-value product-instance 'units-in-stock))
	 (description (slot-value product-instance 'description))
	 (images-str (slot-value product-instance 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (prd-id (slot-value product-instance 'row-id))
	 (active-flag (slot-value product-instance 'active-flag))
	 (approved-flag (slot-value product-instance 'approved-flag))
	 (approval-status (slot-value product-instance 'approval-status))
	 (subscribe-flag (slot-value product-instance 'subscribe-flag))
	 (company (product-company product-instance))
	 (product-pricing (select-product-pricing-by-product-id prd-id company)))
      (cl-who:with-html-output (*standard-output* nil)
	(with-html-div-row :style "border-radius: 5px;background-color:#e6f0ff; border-bottom: solid 1px; margin: -2px;background-image: linear-gradient(to top, #accbee 0%, #e7f0fd 100%); "
	    (if (equal active-flag "Y")
		(cl-who:htm
		 (with-html-div-col-1 :data-bs-toggle "tooltip" :title "Turn Off" 
		   (:a   :href (format nil "dodvenddeactivateprod?id=~A" prd-id) (:i :class "fa-solid fa-power-off"))))
		;;else
		(cl-who:htm
		 (with-html-div-col-1 :data-bs-toggle "tooltip" :title "Turn On" 
		   (:a :href (format nil "dodvendactivateprod?id=~A" prd-id) (:i :class "fa-solid fa-power-off")))))
	  (with-html-div-col-8 "&nbsp;")
	  (with-html-div-col-1 "&nbsp;")
	  (with-html-div-col-1 :align "right" :data-bs-toggle "tooltip" :title "Product Details"
	  (:a :href (format nil "dodprddetailsforvendor?id=~A" prd-id) (:i :class "fa-solid fa-chevron-right"))))
	(with-html-div-row
	  (if (<= units-in-stock 0) 
	      (cl-who:htm (:div :class "stampbox rotated" "NO STOCK" ))
					;else
	      (cl-who:htm (with-html-div-col (:h5 (:span :class "badge badge-pill badge-light" (cl-who:str (format nil "In stock ~A  units"  units-in-stock ))))))))
		      
	(with-html-div-row
	  (with-html-div-col-6 
	    (render-single-product-image prd-name imageslst images-str "100" "83"))
	  (with-html-div-col-6 (product-price-with-discount-widget product-instance product-pricing)))
	(with-html-div-row
	  (with-html-div-col-6
		(:p (:h5 :class "product-name" (cl-who:str (if (> (length prd-name) 30)  (subseq prd-name  0 30) prd-name)))))
	  (with-html-div-col-6
		(if (equal subscribe-flag "Y") (cl-who:htm (:p (:h5 (:span :class "label label-default" "Can be Subscribed")))))))
	(with-html-div-row 
	  (with-html-div-col-12 
		(:h6 (cl-who:str (if (> (length description) 90)  (subseq description  0 90) description)))))
	(if (equal active-flag "N") 
	    (cl-who:htm (:div :class "stampbox rotated" "INACTIVE" )))
	(if (equal approved-flag "N")
	    (cl-who:htm (:div :class "stampbox rotated" (cl-who:str (format nil "~A" approval-status))))))))


(defun product-card-for-approval (product-instance &rest arguments)
  (declare (ignore arguments))
    (let* ((prd-name (slot-value product-instance 'prd-name))
	   (current-price (slot-value product-instance 'current-price))
	   (images-str (slot-value product-instance 'prd-image-path))
	   (imageslst (safe-read-from-string images-str))
	   (prd-id (slot-value product-instance 'row-id))
	   ;;(active-flag (slot-value product-instance 'active-flag))
	   (approved-flag (slot-value product-instance 'approved-flag))
	   (tenant-id (slot-value product-instance 'tenant-id))
	   (company (select-company-by-id tenant-id))
	   (company-name (slot-value company 'name))
	   (approval-status (slot-value product-instance 'approval-status))
	   (subscribe-flag (slot-value product-instance 'subscribe-flag)))
	    
	(cl-who:with-html-output (*standard-output* nil)
	  (:div :style "background-color:#E2DBCD; border-bottom: solid 1px; margin-bottom: 3px;" :class "row"
		(:div :class "col-12" (:h5 (cl-who:str (format nil "~A" company-name)))))
	  (with-html-div-row
	    (with-html-div-col-6
	      (render-single-product-image prd-name imageslst images-str "100" "83"))
	    (with-html-div-col-4
	      (:h3 (:span :class "label label-default" (cl-who:str (format nil "Rs. ~$"  current-price))))))
	  
	  (with-html-div-row
	    (:div :class "col-xs-6"
		  (:h5 :class "product-name" (cl-who:str (if (> (length prd-name) 30)  (subseq prd-name  0 30) prd-name))))
	    (:div :class "col-xs-6"
		  (if (equal subscribe-flag "Y") (cl-who:htm (:div :class "col-xs-6"  (:h5 (:span :class "label label-default" "Can be Subscribed")))))))
	  (if (equal approved-flag "N")
	      (cl-who:htm (:div :class "stampbox rotated" (cl-who:str (format nil "~A" approval-status)))))
	  
	  (with-html-div-row
	    (:div :class "col-xs-6"
		  (:button :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendrejectprod-modal~A" prd-id)  :href "#"  (:i :class "fa-solid fa-ban") " Reject")
		  (modal-dialog-v2 (format nil "dodvendrejectprod-modal~A" prd-id) "Reject Product" (modal.vendor-product-reject-html  prd-id tenant-id)))
	    (:div :class "col-xs-6"
		  (:button :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendacceptprod-modal~A" prd-id)  :href "#"  (:i :class "fa-regular fa-thumbs-up") " Approve")
		  (modal-dialog-v2 (format nil "dodvendacceptprod-modal~A" prd-id) "Approve Product" (modal.vendor-product-accept-html  prd-id tenant-id)))))))



(defun createmodelforprdpricewithdiscount (product product-pricing)
  (let* ((qty-per-unit (slot-value product 'qty-per-unit))
	 (unit-of-measure (slot-value product 'unit-of-measure))
	 (current-price (slot-value product 'current-price))
	 (current-discount (slot-value product 'current-discount))
	 (today-date (clsql:get-date))
	 (start-date (if product-pricing (slot-value product-pricing 'start-date)))
	 (end-date (if product-pricing (slot-value product-pricing 'end-date)))
	 (discountexpired-p (if product-pricing (not (and (clsql:date>= today-date start-date) (clsql:date<= today-date end-date)))))
	 (currency (if product-pricing (slot-value product-pricing 'currency) *HHUBDEFAULTCURRENCY*))
	 (pricewith-discount (if product (- current-price (/ (* current-price current-discount) 100)))))
    (function (lambda ()
      (values discountexpired-p current-price current-discount (get-currency-html-symbol currency)  qty-per-unit unit-of-measure  pricewith-discount)))))
    
(defun createwidgetsforprdpricewithdiscount (modelfunc)
  (multiple-value-bind ( discountexpired-p current-price current-discount cur-html-sym  qty-per-unit unit-of-measure  pricewith-discount) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output  (*standard-output* nil)
		       (unless discountexpired-p
			 (cl-who:htm
			  (:p :class "new-price" (:strong (cl-who:str (format nil "~A ~$ / ~A ~A" cur-html-sym  pricewith-discount qty-per-unit unit-of-measure))))
			  (:p :class "old-price" (:i (:del (cl-who:str (format nil "~A ~$ / ~A" cur-html-sym  current-price qty-per-unit)))))
			  (:p :class "new-price" (cl-who:str (format nil "~$% off" current-discount)))))
		       (when discountexpired-p
			 (cl-who:htm
			  (:p :class "new-price" (:strong "Price discounts are expired."))
			  (:p :class "new-price" (cl-who:str (format nil "~A ~$ / ~A ~A" cur-html-sym  current-price qty-per-unit unit-of-measure))))))))))
      (list widget1))))

(defun product-price-with-discount-widget (product product-pricing)
  (with-mvc-ui-component createwidgetsforprdpricewithdiscount createmodelforprdpricewithdiscount product product-pricing))
    
(defun product-card (product-instance prdincart-p)
  (let* ((prd-name (slot-value product-instance 'prd-name))
	 (images-str (slot-value product-instance 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (units-in-stock (slot-value product-instance 'units-in-stock))
	 (prd-id (slot-value product-instance 'row-id))
	 (subscribe-flag (slot-value product-instance 'subscribe-flag))
	 (customer-type (get-login-customer-type))
	 (company (product-company product-instance))
	 (subscription-plan (slot-value company 'subscription-plan))
	 (cmp-type (slot-value company 'cmp-type))
	 (product-pricing (select-product-pricing-by-product-id prd-id company)))
      (cl-who:with-html-output (*standard-output* nil)
	(:a :href (format nil "prddetailsforcust?id=~A" prd-id) (render-single-product-image prd-name imageslst images-str "100" "83"))
	(:div :class "product-details"
	      (product-price-with-discount-widget product-instance product-pricing)
	      (:p :class "product-title" (:a :href (format nil "prddetailsforcust?id=~A" prd-id) (cl-who:str prd-name)))
	      ;; Display the subscribe button only for standard customers.
	      ;; Customers of APARTMENT/COMMUNITY do not have this feature. 
	      (when (and
		     (com-hhub-attribute-company-prdsubs-enabled subscription-plan cmp-type) 
		     (equal subscribe-flag "Y") 
		     (equal customer-type "STANDARD"))
		(cl-who:htm
		 (:button :data-bs-toggle "modal" :data-bs-target (format nil "#productsubscribe-modal~A" prd-id)  :href "#"   :class "btn btn-sm btn-primary" :id (format nil "btnsubscribe~A" prd-id) :name (format nil "btnsubscribe~A" prd-id)  (:i :class "fa-solid fa-hand-point-up") "&nbsp;Subscribe")
		 (modal-dialog-v2 (format nil "productsubscribe-modal~A" prd-id) "Subscribe Product/Service" (product-subscribe-html prd-id))))
	      (if  prdincart-p 
		   (cl-who:htm (:a :class "btn btn-sm btn-success" :role "button"  :onclick "return false;" :href (format nil "javascript:void(0);")(:i :class "fa-solid fa-check")))
		   ;; else 
		   (if (and units-in-stock (> units-in-stock 0))
		       (cl-who:htm (:button  :data-bs-toggle "modal" :data-bs-target (format nil "#producteditqty-modal~A" prd-id)  :href "#"   :class "add-to-cart-btn" :onclick "addtocartclick(this.id);" :id (format nil "btnaddproduct_~A" prd-id) :name (format nil "btnaddproduct~A" prd-id)  "Add&nbsp; " (:i :class "fa-solid fa-plus"))
				   (modal-dialog-v2 (format nil "producteditqty-modal~A" prd-id) (cl-who:str (format nil "Edit Product Quantity - Available: ~A" units-in-stock)) (product-qty-add-html product-instance product-pricing)))
		       ;; else
		       (cl-who:htm
			(:div :class "col-6" 
			      (:h5 (:span :class "label label-danger" "Out Of Stock"))))))))))
  
(defun product-card-with-details-for-customer (product-instance customer  prdincart-p)
  (let* ((prd-name (slot-value product-instance 'prd-name))
	 (qty-per-unit (slot-value product-instance 'qty-per-unit))
	 (units-in-stock (slot-value product-instance 'units-in-stock))
	 (description (slot-value product-instance 'description))
	 (external-url (slot-value product-instance 'external-url))
	 (images-str (slot-value product-instance 'prd-image-path))
	 (imageslst (safe-read-from-string images-str))
	 (prd-id (slot-value product-instance 'row-id))
	 (subscribe-flag (slot-value product-instance 'subscribe-flag))
	 (cust-type (slot-value customer 'cust-type))
	 (prd-vendor (product-vendor product-instance))
	 (vendor-name (slot-value prd-vendor 'name))
	 (company (product-company product-instance))
	 (product-pricing (select-product-pricing-by-product-id prd-id company))
	 (subscription-plan (slot-value company 'subscription-plan))
	 (cmp-type (slot-value company 'cmp-type))
	 (vendor-id (slot-value prd-vendor 'row-id)))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :id "idsingle-product-card" :class "single-product-card"
	    (render-multiple-product-images prd-name imageslst images-str )
	    (:div :class "product-details"
		  (with-html-div-row
	      	    (with-html-div-col-12
		      (:p :class "product-title"
			  (:span (cl-who:str prd-name) "&nbsp;" (:strong (cl-who:str qty-per-unit))))))
		  (:p (:a :data-bs-toggle "modal" :data-bs-target (format nil "#vendordetails-modal~A" vendor-id)  :href "#"   :class "btn btn-sm btn-primary" :onclick "addtocartclick(this.id);" :name "btnvendormodal" (cl-who:str vendor-name)))  
		  (modal-dialog-v2 (format nil "vendordetails-modal~A" vendor-id) (cl-who:str (format nil "Vendor Details")) (modal.vendor-details vendor-id))
		  (:p (:a :href (format nil "hhubcustvendorstore?id=~A" vendor-id) (:i :class "fa-solid fa-store") (cl-who:str (format nil "&nbsp;~A Store" vendor-name))))
		  (:hr)
		  
		  (product-price-with-discount-widget product-instance product-pricing)
		  (:hr)
		  (:p (cl-who:str description))
		  
		  (with-html-div-row
		    (with-html-div-col-4
		      (if  prdincart-p 
			   (cl-who:htm (:a :class "btn btn-sm btn-success" :role "button"  :onclick "return false;" :href (format nil "javascript:void(0);")(:i :class "fa-solid fa-check")))
			   ;; else 
			   (if (and units-in-stock (> units-in-stock 0))
			       (cl-who:htm
				(:button  :data-bs-toggle "modal" :data-bs-target (format nil "#producteditqty-modal~A" prd-id)  :href "#"   :class "add-to-cart-btn" :onclick "addtocartclick(this.id);" :id (format nil "btnaddproduct_~A" prd-id) :name (format nil "btnaddproduct~A" prd-id)  "Add to cart&nbsp; " (:i :class "fa-solid fa-plus"))
				(modal-dialog-v2 (format nil "producteditqty-modal~A" prd-id) (cl-who:str (format nil "Edit Product Quantity - Available: ~A" units-in-stock)) (product-qty-add-html product-instance product-pricing)))
			   ;; else
			   (cl-who:htm (:div :class "col-6" 
					     (:h5 (:span :class "label label-danger" "Out Of Stock")))))))
		    (with-html-div-col-4
		      ;; display the subscribe button under certain conditions. 
		      (when (and (equal subscribe-flag "Y")
				 (com-hhub-attribute-company-prdsubs-enabled subscription-plan cmp-type) 
				 (equal cust-type "STANDARD"))
			(cl-who:htm
			 (:button :data-bs-toggle "modal" :data-bs-target (format nil "#productsubscribe-modal~A" prd-id)  :href "#"   :class "subscription-btn" :id (format nil "btnsubscribe~A" prd-id) :name (format nil "btnsubscribe~A" prd-id) "Subscribe&nbsp;" (:i :class "fa-solid fa-hand-point-up"))
			 (modal-dialog-v2 (format nil "productsubscribe-modal~A" prd-id) "Subscribe Product/Service" (product-subscribe-html prd-id)))))
		    (with-html-div-col-4
		      (when external-url
			(cl-who:htm
			 (:div  :data-toggle "tooltip" :title "Copy External URL"
				(:a :id "idshareexturl" :href "#" (:i :class  "fa-solid fa-arrow-up-from-bracket")))
			 (sharetextorurlonclick "#idshareexturl" (parenscript:lisp external-url)))))))))))

(defun product-card-with-details-for-customer2 (proddetailpagetempl)
  (cl-who:with-html-output (*standard-output* nil)
    (cl-who:str proddetailpagetempl)))
    
(defun render-multiple-product-images (prd-name imageslst images-str)
  :description "Sometimes we store the product image as a list of strings when we want multiple images. other times we store them as a string for backward compatibility reasons"
  ;; if we have images stored as a list 
  (cl-who:with-html-output (*standard-output* nil) 
    (if (and imageslst  (listp imageslst))
    	(cl-who:htm 
	 (:img :src (format nil "~A" (first imageslst))  :alt prd-name  :class "img-fluid rounded mb-3 product-detail-image" :id "mainImage"))
	;; if we are not storing the images as a list, then display a single image. 
	(when (stringp images-str)
	  (cl-who:htm 
	   (:img :src  (format nil "~A" images-str) :class "img-fluid rounded mb-3 product-detail-image" :alt prd-name " "))))))

(defun render-multiple-product-thumbnails (prd-name imageslst images-str)
  :description "Sometimes we store the product image as a list of strings when we want multiple images. other times we store them as a string for backward compatibility reasons"
  ;; if we have images stored as a list 
  (cl-who:with-html-output (*standard-output* nil) 
    (:div :class "d-flex justify-content-between"
	  (if (and imageslst (listp imageslst))
	      (loop for img in imageslst do
		(cl-who:htm
		 (:img :src  (format nil "~A" img)  :alt prd-name :class "thumbnail rounded" :onclick "changeImage(event, this.src);")))
	      ;; if we are not storing the images as a list, then display a single image. 
	      (when (stringp images-str)
		(cl-who:htm 
		 (:img :src  (format nil "~A" images-str)  :alt prd-name :class "thumbnail rounded" :onclick "changeImage(event, this.src);")))))))

(defun render-single-product-image (prd-name imageslst images-str widthstr heightstr)
  :description "Sometimes we store the product image as a list of strings when we want multiple images. other times we store them as a string for backward compatibility reasons"
  ;; if we have images stored as a list 
  (cl-who:with-html-output (*standard-output* nil) 
    (if (and imageslst  (listp imageslst))
	(cl-who:htm 
	 (:img :src (format nil "~A" (first imageslst))  :height heightstr :width widthstr  :class "img-fluid rounded mb-3 product-detail-image" :alt prd-name " "))
	;; if we are not storing the images as a list, then display a single image. 
	(when (stringp images-str)
	  (cl-who:htm 
	   (:img :src  (format nil "~A" images-str) :height heightstr  :width widthstr  :class "img-fluid rounded mb-3 product-detail-image" :alt prd-name " "))))))
