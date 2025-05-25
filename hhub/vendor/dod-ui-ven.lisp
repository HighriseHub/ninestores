; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(defun com-hhub-transaction-vendor-upload-product-images-action ()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforvuploadprdimages  createwidgetsforgenericredirect)))

(defun createmodelforvuploadprdimages ()
    (logiamhere (format nil "Files to be uploaded are ~A" (hunchentoot:post-parameters hunchentoot:*request*)))
  (let* ((images (remove "uploadedimagefiles" (hunchentoot:post-parameters hunchentoot:*request*) :test (complement #'equal) :key #'car))
	 (prd-id (parse-integer (hunchentoot:parameter "prd-id")))
	 (productlist (hhub-get-cached-vendor-products))
	 (product (search-item-in-list 'row-id prd-id productlist))
	 (filepaths (mapcar
		     (lambda (image)
		       (let* ((newimageparams (remove "uploadedimagefiles" image :test #'equal ))
			      (newfilename (process-file  newimageparams (format nil "~A" *HHUBRESOURCESDIR*))))
			 newfilename)) images))
	 (vendor (get-login-vendor))
	 (vendor-id (get-login-vendor-id))
	 (company (get-login-vendor-company))
	 (tenant-id (get-login-vendor-tenant-id))
	 (redirecturl (format nil "/hhub/dodprddetailsforvendor?id=~d" prd-id))
	 ;; delete old files from s3 bucket.
	 (deletedfiles (vendor-delete-files-s3bucket "prd" prd-id vendor-id tenant-id))
	 (uploadedfiles (async-upload-files-s3bucket filepaths "prd" prd-id vendor)))
    ;; After the files have been uploaded, we can reference it through the session value
    (logiamhere (format nil "deleted files are ~A" deletedfiles))
    (when (and uploadedfiles (> (length uploadedfiles) 0))
      (setf (slot-value product 'prd-image-path) (write-to-string uploadedfiles :readably t))
      ;; update the database with the new file upload paths.
      (update-prd-details  product))
    (dod-gen-vendor-products-functions vendor company)
    (function (lambda ()
      (values redirecturl)))))
	 
(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defun render-sidebar-offcanvas ()
    (cl-who:with-html-output (*standard-output* nil :prologue t :indent t)
      (:div :class "offcanvas offcanvas-start" :tabindex"-1" :id "offcanvasExample" :aria-labelledby "offcanvasExampleLabel" :style  "  background: rgb(222,228,255);
background: linear-gradient(171deg, rgba(222,228,255,1) 0%, rgba(224,236,255,1) 100%); "
	    (:div :class "offcanvas-header"
		  (:img :src "/img/logo.png" :alt "" :width "32" :height "32" :class "rounded-circle me-2")
		  (:h5 :class "offcanvas-title" :id "offcanvasExampleLabel" "Nine Stores")
		  (:button :type "button" :class "btn-close btn-close" :data-bs-dismiss "offcanvas" :aria-label "Close"))
	    (:div :class "offcanvas-body"
		  (:ul :class "nav nav-tabs flex-column mb-auto"
		       (:li :class "nav-item"
			    (:a :href "dodvendindex?context=home"
				(:i :class "fa-solid fa-house")  "&nbsp;&nbsp;Home"))
		       (:li :class "nav-item"
			    (:a :href "#" :class "nav-link collapsed has-dropdown dropdown-toggle" :data-bs-toggle "collapse"
				:data-bs-target "#productmaster" :aria-expanded "true" :aria-controls "productmaster"
			   (:i :class "fa-solid fa-rectangle-list") " Product Master")
			    (:ul :id "productmaster" :class "nav-dropdown list-unstyled collapse" :data-bs-parent "#offcanvasExample"
				 (:li :class "sidebar-item"
				      (:a :href "/hhub/dodvenproducts" :class "nav-link" "Product List"))
				 (:li :class "sidebar-item"
				      (:a :href "/hhub/dodvendprodcategories" :class "nav-link" "Product Categories"))
				 (:li :class "sidebar-item"
				      (:a :href "/hhub/dodvenaddprodpage" :class "nav-link" "Add New Product"))
				 (:li :class "sidebar-item"
				      (:a :href "/hhub/dodvenbulkaddprodpage" :class "nav-link" "Bulk Add Products"))))
		       (:li :class "nav-item"
			    (:a :href "#" :class "nav-link collapsed has-dropdown dropdown-toggle" :data-bs-toggle "collapse"
				:data-bs-target "#orders" :aria-expanded "true" :aria-controls "orders"
			   (:i :class "fa-solid fa-rectangle-list") " Orders")
			    (:ul :id "orders" :class "nav-dropdown list-unstyled collapse" :data-bs-parent "#offcanvasExample"
				 (:li :class "nav-item"
				      (:a :href "/hhub/dodvendindex?context=pendingorders"  :class "nav-link link-body-emphasis"
					  (:i :class "fa-regular fa-rectangle-list")  " Pending Orders"))
				 (:li :class "nav-item"
				      (:a :href "/hhub/dodvendindex?context=ctxordprd"  :class "nav-link link-body-emphasis"
					  (:i :class "fa-regular fa-rectangle-list")  " Pending Orders By Products"))
				 (:li :class "nav-item"
				      (:a :href "/hhub/dodvendindex?context=completedorders"  :class "nav-link link-body-emphasis"
					  (:i :class "fa-regular fa-rectangle-list")  " Completed Orders"))))
		       (:li :class "nav-item"
			    (:a :href "/hhub/displayinvoices"  :class "nav-link link-body-emphasis"
				(:i :class "fa-regular fa-rectangle-list")  " Sale Invoices"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/hhubvendorupitransactions"  :class "nav-link link-body-emphasis"
				(:i :class "fa-regular fa-rectangle-list")  " UPI Transactions"))
		       (:li :class "nav-item"
			    (:a :href "/hhub/hhubvendmycustomers" :class "nav-link link-body-emphasis"
				(:i :class "fa-regular fa-user") " Customers"))
		       (:li :class "nav-item"
			    (:a :href "#" :class "nav-link collapsed has-dropdown dropdown-toggle" :data-bs-toggle "collapse"
				:data-bs-target "#reports" :aria-expanded "true" :aria-controls "reports"
				(:i :class "fa-solid fa-circle-info") " Reports")
			    (:ul :id "reports" :class "nav-dropdown list-unstyled collapse" :data-bs-parent "#offcanvasExample"
				 (:li :class "sidebar-item"
				      (:a :href "/hhub/dodvendrevenue" :class "nav-link" "Today's Revenue"))))
		       (:li :class "nav-item"
			    (:a :href "#" :class "nav-link collapsed has-dropdown dropdown-toggle" :data-bs-toggle "collapse"
				:data-bs-target "#settings" :aria-expanded "true" :aria-controls "settings"
				(:i :class "fa-solid fa-gear") " Settings")
			    (:ul :id "settings" :class "nav-dropdown list-unstyled collapse" :data-bs-parent "#offcanvasExample"
				 (:li :class "sidebar-item"
				      (:a :href "hhubvendpushsubscribepage" :class "nav-link" "Browser Push Notification"))
				 (:li :class "sidebar-item"
				      (:a :href "/hhub/dodvendprofile?context=home" :class "nav-link" "Vendor Settings"))
				 ))))))
								
		  ;; (:div :class "dropdown"
		  ;; 	(:a :href "#" :class "d-flex align-items-center link-body-emphasis text-decoration-none dropdown-toggle" :data-bs-toggle "dropdown" :aria-expanded "false"
			    
		  ;; 	    (:ul :class "dropdown-menu text-small shadow" :style=""
		  ;; 	    (:li (:a :class "dropdown-item" :href "#" "New project..."))
		  ;; 	    (:li (:a :href "/hhub/dodvendlogout" :class="nav-link"
		  ;; 		     (:i :class "fa-solid fa-arrow-right-from-bracket") (:span "Sign Out"))))))
		  ;; (:div :class "dropdown mt-3"
		  ;; 	 (:button :class "btn btn-secondary dropdown-toggle" :type "button" :data-bs-toggle "dropdown"
		  ;; 		  "Dropdown button")
		  ;; 	 (:ul :class "dropdown-menu"
		  ;; 	      (:li (:a :class "dropdown-item" :href "#" "Action"))
		  ;; 	      (:li (:a :class "dropdown-item" :href "#" "Another action")
		  ;; 		   (:li (:a :class "dropdown-item" :href "#" "Something else here")))))
		  ))


(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defmacro with-vendor-sidebar ()
    `(cl-who:with-html-output (*standard-output* nil :prologue t :indent t)
       ;;<!-- sidebar -->
       ;;<!-- Sidebar -->
       (:nav :id "nstvendorsidebar" :class "collapse d-lg-block sidebar collapse bg-white" :style "width: 280px;"
	     (:a :href "dodvendindex?context=home" :class "d-flex align-items-center mb-3 mb-md-0 me-md-auto link-body-emphasis text-decoration-none"
		 (:span :class "fs-4" "Sidebar"))
	     (:hr)
	     (:ul :class "nav nav-pills flex-column mb-auto"
		  (:li :class "nav-item" (:a :href "dodvendindex?context=home" (:i :class "fa-solid fa-house")  "Home"))
		  (:li :class "nav-item" 
		       (:a :href "/hhub/dodvenproducts" :class "nav-link link-body-emphasis" 
			   (:i :class "fa-regular fa-rectangle-list") "My Products"))
		  (:li :class "nav-item"
		       (:a :href "/hhub/dodvendindex?context=completedorders"  :class "nav-link link-body-emphasis"
			   (:svg :class "bi me-2" :width "16" :height "16" (:use :xlink\:href "#table")) "Completed Orders"))
		  (:li :class "nav-item"
		       (:a :href "/hhub/hhubvendmycustomers" :class "nav-link link-body-emphasis"
			   (:svg :class "bi me-2" :width "16" :height "16" (:use :xlink\:href "#people-circle")) "Customers"))
		  (:li :class "nav-item"
		       (:a :href "/hhub/dodvendprofile" :class "nav-link link-body-emphasis"
			   (:svg :class "bi me-2" :width "16" :height "16" (:use :xlink\:href "#grid")) "Settings"))
		  (:li :class "nav-item"
		       (:a :href "#" :class "nav-link collapsed has-dropdown" :data-bs-toggle "collapse"
			   :data-bs-target "#auth" :aria-expanded "true" :aria-controls "auth"
			   (:class "fa-solid fa-person-military-pointing" (:span "Auth")))
		       (:ul :id "auth" :class "nav-dropdown list-unstyled collapse" :data-bs-parent "#nstvendorsidebar"
			    (:li :class "sidebar-item"
				 (:a :href "#" :class "nav-link" "Login")))))
	     (:div :class "dropdown" 
		   (:a :href "#" :class "d-flex align-items-center link-body-emphasis text-decoration-none dropdown-toggle" :data-bs-toggle "dropdown" :aria-expanded "false"
		       (:img :src "/img/logo.png" :alt "" :width "32" :height "32" :class "rounded-circle me-2" "Profile")
		       (:ul :class "dropdown-menu text-small shadow" :style=""
			    (:li (:a :class "dropdown-item" :href "#" "New project..."))
			    (:li (:a :class "dropdown-item" :href "#" "New project..."))
			    (:li (:a :class "dropdown-item" :href "#" "New project..."))
			    (:li (:a :class "dropdown-item" :href "#" "New project..."))
			    (:li (:a :href "/hhub/dodvendlogout" :class="nav-link"
				     (:i :class "fa-solid fa-arrow-right-from-bracket") (:span "Sign Out"))))))))))

(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defun with-vendor-navigation-bar-v2 ()
    :documentation "this macro returns the html text for generating a navigation bar using bootstrap."
    (cl-who:with-html-output (*standard-output* nil)
	(:nav :class "navbar navbar-expand-sm  sticky-top navbar-dark bg-dark" :id "hhubcustnavbar"  
	      (:div :class "container-fluid"
		    (:a :class "navbar-brand" :href "/hhub/dodvendindex" (:img :style "width: 30px; height: 24px;" :src "/img/logo.png" ))
		    (:button :class "navbar-toggler" :type "button" :data-bs-toggle "collapse" :data-bs-target "#navbarSupportedContent" :aria-controls "navbarSupportedContent" :aria-expanded "false" :aria-label "Toggle navigation" 
			     (:span :class "navbar-toggler-icon" ))
		    (:div :class "collapse navbar-collapse justify-content-between" :id "navbarSupportedContent"
			  (:ul :class "navbar-nav me-auto mb-2 mb-lg-0" 
			       (:li :class "nav-item"
				    (:a :class "btn btn-primary" :data-bs-toggle "offcanvas" :href "#offcanvasExample" :role "button" :aria-controls "offcanvasExample" (:i :class "fa-solid fa-bars")))
			     (:li :class "nav-item" 	
				  (:a :class "nav-link active" :aria-current "page" :href "/hhub/dodvendindex?context=home" (:i :class "fa-solid fa-house") "&nbsp;Home"))
			     ;;(:li :class "nav-item"  (:a :class "nav-link" :href "dodvenproducts" "Products/Services"))
			     ;;(:li :class "nav-item"  (:a :class "nav-link" :href "dodvendindex?context=completedorders"  "Completed Orders"))
			     (:li :class "nav-item"  (:a :class "nav-link" :href "#" (print-vendor-web-session-timeout))))
			  (:ul :class "navbar-nav ms-auto"
			       (:li :class "nav-item"  (:a :class "nav-link" :href "#"  (:i :class "fa-regular fa-bell")))
			       (:li :class "nav-item"  (:a :class "nav-link" :href "dodvendprofile?context=home" (:i :class "fa-regular fa-user")))
			       (:li :class "nav-item" (:a :class "nav-link" :href "dodvendlogout" (:i :class "fa-solid fa-arrow-right-from-bracket"))))))))))
  
(defun createmodelforvendorprodpricingaction ()
  (let* ((vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (prd-price (float (with-input-from-string (in (hunchentoot:parameter "prdprice"))
			     (read in))))
	 (prd-discount (float (with-input-from-string (in (hunchentoot:parameter "prddiscount"))
				(read in))))
	 (start-date (get-date-from-string (hunchentoot:parameter "startdate")))
	 (end-date (get-date-from-string (hunchentoot:parameter "enddate")))
	 (prd-id (parse-integer (hunchentoot:parameter "prdid")))
	 (product (select-product-by-id prd-id company))
	 (currency (get-account-currency company))
	 (prdpricing (select-product-pricing-by-product-id prd-id company))
	 (redirectlocation "/hhub/dodvenproducts"))
    (unless prdpricing
      (create-product-pricing product prd-price prd-discount currency start-date end-date company))
    (when prdpricing
      (setf (slot-value prdpricing 'price) prd-price)
      (setf (slot-value prdpricing 'currency) currency)
      (setf (slot-value prdpricing 'discount) prd-discount)
      (setf (slot-value prdpricing 'start-date) start-date)
      (setf (slot-value prdpricing 'end-date) end-date)
      (update-prd-details prdpricing))
    (when product
      (with-slots (current-price current-discount) product
	(setf current-price prd-price)
	(setf current-discount prd-discount)
	;; Update product table with the price and discount data.
	(update-prd-details product)))
      (dod-reset-vendor-products-functions vendor company)
      (function (lambda ()
	redirectlocation))))

(defun dod-controller-vendor-product-pricing-action ()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforvendorprodpricingaction createwidgetsforgenericredirect)))

(defun vendor-card (vendor)
  (let* ((vname (slot-value vendor 'name))
	 (vid (slot-value vendor 'row-id))
	 (vpicture (slot-value vendor 'picture-path)))
    (cl-who:with-html-output (*standard-output* nil)
      (:img :src vpicture :alt vname :style "align:center; width: 100px; height: 100px; border-radius: 50%;")
      (:h5 vname)
      (:span (:a :href (format nil "hhubcustvendorstore?id=~A" vid) (:i :class "fa-solid fa-store") (cl-who:str (format nil "&nbsp;~A Store" vname)))))))
    

(defun dod-controller-vendor-pushsubscribe-page ()
  (with-vend-session-check
    (with-mvc-ui-page "Webpush Subscription for Vendor" createmodelforvendpushsubscribepage createwidgetsforvendpushsubscribepage :role :vendor)))

(defun createmodelforvendpushsubscribepage ()
  (let ((url *siteurl*))
    (function (lambda ()
      (values url)))))

(defun createwidgetsforvendpushsubscribepage (modelfunc)
  (multiple-value-bind (url) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(:br)
			(with-html-div-row
			  (:h3 "Subscribe to Notifications on your Browser"))
			(with-html-div-row
			  (:p "Note: We send notifications for various events, for example:  when you receive a new order. Push notification will be sent to one browser only.")
			  (:p "If you would like to subscribe to notifications on a different browser, you need to unsubscribe in current browser and subscribe in other browser"))
			(with-html-div-row
			  (with-html-div-col-4
			    (:button :class "btn btn-lg btn-primary btn-block" :id "btnPushNotifications" :name "btnPushNotifications" "Subscribe")))))))
	   (widget2 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-div-row
			  (with-html-div-col-4
			    (:a :href "dodvendindex?context=home" "Home"))
			  (with-html-div-col-4
			    (:a :id "btnPushSubscriptionRemoveFromServer" :href "#" (:i :class "fa-regular fa-trash-can"))))))))
	   (widget3 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(:script :src (format nil "~A/js/pushsubscribe.js" url)))))))
	   
      (list widget1 widget2 widget3))))


	    

(defun modal.upload-product-images  ()
  (cl-who:with-html-output (*standard-output* nil)
    (:form :class "hhub-formprodimagesupload"  :role "form" :method "POST" :action "dodvenuploadproductsimagesaction" :data-bs-toggle "validator" :enctype "multipart/form-data" 
	   (:div :class "row"
		 (:div :class "form-group"
		       (:input :type "file" :multiple "true" :name "uploadedimagefiles"))
		 (:div :class "form-group"
		       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))

(defun dod-controller-vendor-bulk-upload-products-images-action ()
  :documentation "Upload the product images in the form of jpeg, png files which are less than 1 MB in size"
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforbulkvuploadprdimages createwidgetsforgenericredirect)))

(defun createmodelforbulkvuploadprdimages ()
  (let* ((images  (remove "uploadedimagefiles" (hunchentoot:post-parameters hunchentoot:*request*) :test (complement #'equal) :key #'car))
	 (filepaths (mapcar
		     (lambda (image)
		       (let* ((newimageparams (remove "uploadedimagefiles" image :test #'equal ))
			      (newfilename (process-file  newimageparams (format nil "~A" *HHUBRESOURCESDIR*))))
			 newfilename)) images))
	 (vendor (get-login-vendor))
	 (redirecturl "/hhub/dodvenbulkaddprodpage"))
    (logiamhere (format nil "New filepaths are  ~A" filepaths))
    (bt:make-thread
     (lambda ()
       ;; Asynchronously start the upload of images. 
       (async-upload-images-for-bulk-upload filepaths "prd" nil vendor)) :name "Async File Upload Thread")
    (function (lambda ()
      (values redirecturl)))))


(defun async-upload-files-s3bucket-behavior (state messagefunc)
  (multiple-value-bind (product images objectname object-id vendor) (funcall messagefunc) 
    (let* ((vendor-id (slot-value vendor 'row-id))
	  (tenant-id (slot-value vendor 'tenant-id))
	  (uploadedfiles (if (and images (> (length images) 0))
			     (mapcar
			      (lambda (image)
				(if *HHUBUSELOCALSTORFORRES* 
				    (format nil "/img/~A" image)
				    ;;else return the path of the uploaded file in S3 bucket.
				    (vendor-upload-file-s3bucket image objectname object-id vendor-id tenant-id))) images))))
      
      (when (and uploadedfiles (> (length uploadedfiles) 0))
	(setf (slot-value product 'prd-image-path) (write-to-string uploadedfiles :readably t))
	;; update the database with the new file upload paths.
	(update-prd-details  product))
      (incf state))))

(defun async-upload-files-s3bucket (images objectname object-id vendor)
  (let ((vendor-id (slot-value vendor 'row-id))
	(tenant-id (slot-value vendor 'tenant-id)))
    (logiamhere (format nil "images to upload are ~A" images))
    (if (and images (> (length images) 0))
	(mapcar
	 (lambda (image)
	   (if *HHUBUSELOCALSTORFORRES* 
	       (format nil "/img/~A" image)
	       ;;else return the path of the uploaded file in S3 bucket.
	       (vendor-upload-file-s3bucket image objectname object-id vendor-id tenant-id))) images))))

     

(defun async-upload-images-for-bulk-upload (images objectname object-id vendor)
  (let* ((header (list "Product ID" "Product Name " "Description" "Qty Per Unit" "Unit Of Measure" "Unit Price" "Discount" "Discount Start" "Discount End" "Units In Stock" "Subscription Flag" "Image Path (DO NOT MODIFY)" "Image Hash (DO NOT MODIFY)"))
	 (vendor-id (slot-value vendor  'row-id))
	 (tenant-id (slot-value vendor 'tenant-id))
	 (filepaths (mapcar
		     (lambda (image)
		       (if *HHUBUSELOCALSTORFORRES* 
			   (format nil "/img/~A" image)
			   ;;else return the path of the uploaded file in S3 bucket.
			   (vendor-upload-file-s3bucket image objectname object-id vendor-id tenant-id))) images))
	 (image-path-hashes (mapcar
			     (lambda (filepath)
			       (string-upcase (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :MD5 (ironclad:ascii-string-to-byte-array filepath))))) filepaths)))
    (with-open-file (stream (format nil "~A/temp/products-ven-~a.csv" *HHUBRESOURCESDIR* vendor-id)  
			    :direction :output
			    :if-exists :supersede
			    :if-does-not-exist :create)
      (format stream "~A"  (create-products-csv header filepaths image-path-hashes)))))

(defun create-products-csv (header imagepaths image-path-hashes)
  (cl-who:with-html-output-to-string (*standard-output* nil)
      (mapcar (lambda (item) (cl-who:str (format nil "~A," item ))) header)
      (cl-who:str (format nil " ~C~C" #\return #\linefeed))
      (mapcar (lambda (imagepath imagehash)
		(cl-who:str (format nil ",,,,,,,,,,,~A,~A~C~C" imagepath imagehash #\return #\linefeed)))  imagepaths image-path-hashes)))


(defun modal.upload-csv-file ()
  (cl-who:with-html-output (*standard-output* nil)
    (:form :class "hhub-formcsvfileupload"  :role "form" :method "POST" :action "dodvenuploadproductscsvfileaction" :data-bs-toggle "validator" :enctype "multipart/form-data" 
	   (:div :class "row"
	    (:div :class "form-group"
		  (:input :type "file" :name "uploadedcsvfile"))
	    (:div :class "form-group"
		  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))

(defun com-hhub-transaction-vendor-bulk-products-add ()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforvbulkproductsadd createwidgetsforgenericredirect)))

(defun createmodelforvbulkproductsadd ()
  (let* ((csvfileparams (hunchentoot:post-parameter "uploadedcsvfile"))
	 (vendor (get-login-vendor))
	 (vendor-id (get-login-vendor-id))
	 (company (get-login-vendor-company))
	 (tenant-id (get-login-vendor-tenant-id))
	 (params nil)
	 (redirecturl "/hhub/dodvenproducts")
	 (tempfilewithpath (nth 0 csvfileparams))
					;(final-file-name (process-file  csvfileparams (format nil "~A/temp" *HHUBRESOURCESDIR*)))
	 (prdandpriceinfo (cl-csv:read-csv tempfilewithpath ;(pathname (format nil "~A/temp/~A" *HHUBRESOURCESDIR* final-file-name))
				   :skip-first-p T  :map-fn #'(lambda (row)
								(when (equal (nth 12 row) (string-upcase (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :MD5 (ironclad:ascii-string-to-byte-array (nth 11 row))))))
								  (let* ((prd-id (parse-integer (check-null (nth 0 row)) :junk-allowed t))
									 (prd-name (nth 1 row))
									 (prd-desc (nth 2 row))
									 (qty-per-unit (float (with-input-from-string (in (nth 3 row)) (read in))))
									 (unit-of-measure (nth 4 row))
									 (prdinst (make-instance 'dod-prd-master
												:row-id prd-id
												:prd-name prd-name
												:description prd-desc
												:vendor-id vendor-id
												:vendor vendor 
												:qty-per-unit qty-per-unit 
												:unit-of-measure unit-of-measure
												:current-price (float (with-input-from-string (in (nth 5 row)) (read in)))
												:units-in-stock  (parse-integer (nth 9 row))
												:subscribe-flag (nth 10 row)
												:sku (generate-sku prd-name prd-desc qty-per-unit unit-of-measure)
												;;:prd-image-path (nth 8 row)
												:tenant-id tenant-id
												:company company
												:active-flag "Y"
												:approved-flag "N"
												:approval-status "PENDING"
												:deleted-state "N"))
									 (priceinst (if prd-id
											(make-instance 'dod-product-pricing
												       :product-id (nth 0 row)
												       :price (float (with-input-from-string (in (nth 5 row)) (read in)))
												       :discount (float (with-input-from-string (in (nth 6 row)) (read in)))
												       :start-date (get-date-from-string (nth 7 row))
												       :end-date (get-date-from-string (nth 8 row))))))
								    (list prdinst priceinst)))))))
	 
    
    
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "prdcount" (length prdandpriceinfo) params))
    (setf params (acons "company" company params))
    
    (with-hhub-transaction "com-hhub-transaction-vendor-bulk-products-add" params
      (when (> (length prdandpriceinfo) 0)
	(create-bulk-products (function (lambda () prdandpriceinfo)))
	(dod-reset-vendor-products-functions vendor company)))
      (function (lambda ()
	(values redirecturl)))))

  
(defun dod-controller-vendor-bulk-add-products-page ()
:documentation "Here we are going to add products in bulk using CSV file. This page will display options of adding CSV files in two phases. 
Phase1: Temporary Image URLs creation using image files upload.
Phase2: User should copy those URLs in Products.csv and then upload that file."
  (with-vend-session-check
    (with-mvc-ui-page "Bulk Add Products using CSV File" createmodelforvbulkaddproducts createwidgetsforvbulkaddproducts :role :vendor)))

(defun createmodelforvbulkaddproducts ()
  (let ((vendor-id (slot-value (get-login-vendor) 'row-id)))
    (function (lambda ()
      (values vendor-id)))))

(defun createwidgetsforvbulkaddproducts (modelfunc)
  (multiple-value-bind (vendor-id) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:br) (:br)
		       (:br) (:br)
		       (with-html-div-row
			 (with-html-div-col-6
			   (:ul :class "list-group"
				(:li :class "list-group-item" "Step 1: Upload product images,  which will then  be converted to URLs.")
				(:li :class "list-group-item" "Step 2: Download Products.csv Template")
				(:li :class "list-group-item" "Step 3: Fill up other required columns of Products.csv file")
				(:li :class "list-group-item" "Step 4: Upload the Products.csv file")))
	  		 (:div :class "list-group col-xs-12 col-sm-6 col-md-6 col-lg-6" 
			       (:a :class "list-group-item list-group-item-action" :data-bs-toggle "modal" :data-bs-target (format nil "#hhubvendprodimagesupload-modal")  :href "#" " Upload Product Images")
			       ;; This download will be enabled when the file is ready for download. 
			       (if (probe-file (format nil "~A/temp/products-ven-~a.csv" *HHUBRESOURCESDIR* vendor-id))
				   (cl-who:htm (:a :href (format nil "/img/temp/products-ven-~a.csv" vendor-id) :class "list-group-item list-group-item-action" "click here to download Products.csv"))) 
			       (:a :class "list-group-item list-group-item-action"  :data-bs-toggle "modal" :data-bs-target (format nil "#hhubvendprodcsvupload-modal")  :href "#"  " Upload CSV File"))
			 ;; Modal dialog for Uploading  product images
			 (modal-dialog-v2 (format nil "hhubvendprodimagesupload-modal") " Upload Product Images " (modal.upload-product-images))
			 ;; Modal dialog for CSV file upload
			 (modal-dialog-v2 (format nil "hhubvendprodcsvupload-modal") " Upload CSV File " (modal.upload-csv-file))))))))
      (list widget1))))



(defun dod-controller-vendor-bulk-add-products-page2 ()
:documentation "Here we are going to add products in bulk using CSV file. This page will display options of adding CSV files in two phases. 
Phase1: Temporary Image URLs creation using image files upload.
Phase2: User should copy those URLs in Products.csv and then upload that file."
  (with-vend-session-check
    (with-mvc-ui-page "Bulk Add Products using CSV File" createmodelforvbulkaddproducts2 createwidgetsforvbulkaddproducts2 :role :vendor)))

(defun createmodelforvbulkaddproducts2 ()
  (let ((vendor-id (slot-value (get-login-vendor) 'row-id)))
    (function (lambda ()
      (values vendor-id)))))

(defun createwidgetsforvbulkaddproducts2 (modelfunc)
  (multiple-value-bind (vendor-id) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (:br) (:br)
		       (:br) (:br)
		       (with-html-div-row
			 (with-html-div-col-6
			   (:ul :class "list-group"
				(:li :class "list-group-item" "Step 1: Download Products.csv Template")
				(:li :class "list-group-item" "Step 2: Fill up other required columns of Products.csv file")
				(:li :class "list-group-item" "Step 3: Upload the Products.csv file")))
	  		 (:div :class "list-group col-xs-12 col-sm-6 col-md-6 col-lg-6" 
			       (with-catch-submit-event "idgenerateproductcsvtempl"  
				 (with-html-form "generateproductcsvform" "generateproductcsvaction"
				   (with-html-submit-button "Generate & Download Products Template")))

			       ;; This download will be enabled when the file is ready for download. 
			       (if (probe-file (format nil "~A/temp/products-ven-~a.csv" *HHUBRESOURCESDIR* vendor-id))
				   (cl-who:htm (:a :href (format nil "/img/temp/products-ven-~a.csv" vendor-id) :class "list-group-item list-group-item-action" "Click here to download Products.csv"))) 
			       (:a :class "list-group-item list-group-item-action"  :data-bs-toggle "modal" :data-bs-target (format nil "#hhubvendprodcsvupload-modal")  :href "#"  " Upload Products CSV File"))
			 ;; Modal dialog for Uploading  product images
			 (modal-dialog-v2 (format nil "hhubvendprodimagesupload-modal") " Upload Product Images " (modal.upload-product-images))
			 ;; Modal dialog for CSV file upload
			 (modal-dialog-v2 (format nil "hhubvendprodcsvupload-modal") " Upload Products CSV File " (modal.upload-csv-file))))))))
      (list widget1))))




(defun dod-controller-vendor-generate-products-templ ()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforvgenprodcttempl createwidgetsforgenericredirect)))

(defun createmodelforvgenprodcttempl ()
  (let* ((header (list "Product ID" "Product Name " "Qty Per Unit" "Unit Of Measure" "Unit Price" "Discount" "Discount Start" "Discount End" "Units In Stock" "Subscription Flag"))
	 (vendor (get-login-vendor))
	 (vendor-id (slot-value vendor  'row-id))
	 (productlist (hhub-get-cached-vendor-products))
	 (redirecturl "/hhub/venbulkaddprodpage"))
    (with-open-file (stream (format nil "~A/temp/products-ven-~a.csv" *HHUBRESOURCESDIR* vendor-id)  
			    :direction :output
			    :if-exists :supersede
			    :if-does-not-exist :create)
      (format stream "~A"  (create-products-csv2 header productlist)))
    (function (lambda ()
      (values redirecturl)))))

(defun create-products-csv2 (header productlist)
  (cl-who:with-html-output-to-string (*standard-output* nil)
      (mapcar (lambda (item) (cl-who:str (format nil "~A," item ))) header)
      (cl-who:str (format nil " ~C~C" #\return #\linefeed))
    (mapcar (lambda (product)
	      (with-slots (row-id prd-name description qty-per-unit unit-of-measure current-price sku units-in-stock subscribe-flag) product
		(let ((db-product-pricing (select-product-pricing-by-product-id row-id (product-company product))))
		  (with-slots (price discount start-date end-date) db-product-pricing
		    (cl-who:str (format nil "~A,~A,~A,~A,~A,~A,~A,~A,~A,~A~C~C" row-id prd-name  qty-per-unit unit-of-measure price discount (get-date-string start-date) (get-date-string end-date) units-in-stock subscribe-flag  #\return #\linefeed)))))) productlist)))


(defun modal.vendor-update-details ()
  (let* ((vendor (get-login-vendor))
	 (name (name vendor))
	 (address (address vendor))
	 (phone  (phone vendor))
	 (zipcode (zipcode vendor))
	 (email (email vendor))
	 (gstnumber (gstnumber vendor))
	 (picture-path (picture-path vendor)))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" :style "align: center"
	    (:div :class "col-sm-12 col-xs-12 col-md-6 col-lg-6 image-responsive"
		  (:img :src  (format nil "~A" picture-path) :height "300" :width "400" :alt name " ")))
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :id (format nil "form-customerupdate")  :role "form" :method "POST" :action "hhubvendupdateaction" :enctype "multipart/form-data" 
					;(:div :class "account-wall"
		 
			 (:h1 :class "text-center login-title"  "Update Vendor Details")
		      (:div :class "form-group"
			    (:input :class "form-control" :name "name" :value name :placeholder "Customer Name" :type "text"))
		      (:div :class "form-group"
			    (:label :for "address")
			    (:textarea :class "form-control" :name "address"  :placeholder "Enter Address ( max 200 characters) "  :rows "2" :onkeyup "countChar(this, 200)" (cl-who:str (format nil "~A" address))))
		      (:div :class "form-group" :id "charcount")
		      (:div :class "form-group"
			    (:input :class "form-control" :name "zipcode"  :value zipcode :placeholder "Pincode"  :type "text" ))
		      (:div :class "form-group"
			    (:input :class "form-control" :name "phone"  :value phone :placeholder "Phone"  :type "text" ))
		      (:div :class "form-group"
			    (:input :class "form-control" :name "email" :value email :placeholder "Email" :type "text"))
		      (:div :class "form-group"
			    (:input :class "form-control" :name "gstnumber" :value gstnumber :placeholder "GST Number" :type "text"))
		      
		      (:div :class "form-group" (:label :for "prodimage" "Select Picture:")
			    (:input :class "form-control" :name "picturepath" :placeholder "Picture" :type "file" ))
		      
		      (:div :class "form-group"
			    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))))

(defun dod-controller-vendor-update-action ()
  (with-vend-session-check 
    (with-mvc-redirect-ui createmodelforvendorupdateaction createwidgetsforgenericredirect)))

(defun createmodelforvendorupdateaction ()
  (let* ((name (hunchentoot:parameter "name"))
	 (address (hunchentoot:parameter "address"))
	 (phone (hunchentoot:parameter "phone"))
	 (zipcode (hunchentoot:parameter "zipcode"))
	 (gstnumber (hunchentoot:parameter "gstnumber"))
	 (email (hunchentoot:parameter "email"))
	 (vendor (get-login-vendor))
	 (prodimageparams (hunchentoot:post-parameter "picturepath"))
	 (tempfilewithpath (first prodimageparams))
	 (file-name (if tempfilewithpath (process-file prodimageparams *HHUBRESOURCESDIR*)))
	 (redirecturl "/hhub/dodvendprofile"))

    (logiamhere (format nil "picturepath is ~A" (hunchentoot:post-parameters*)))
    (setf (slot-value vendor 'name) name)
    (setf (slot-value vendor 'address) address)
    (setf (slot-value vendor 'phone) phone)
    (setf (slot-value vendor 'zipcode) zipcode)
    (setf (slot-value vendor 'gstnumber) gstnumber)
    (setf (slot-value vendor 'email) email)
    (if tempfilewithpath (setf (slot-value vendor 'picture-path) (format nil "/img/~A"  file-name)))
    (update-vendor-details vendor)
    (function (lambda ()
      (values redirecturl)))))


(defun modal.vendor-update-UPI-payment-settings-page ()
  (let* ((vendor (get-login-vendor))
	 (vendor-upi-id (slot-value vendor 'upi-id)))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	(:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
	  (:form :id (format nil "form-vendorupisettings")  :role "form" :method "POST" :action "hhubvendupdateupisettings" :enctype "multipart/form-data" 
	     (:div :class "form-group"
		   (:label :for "vendor-upi-id" "UPI ID")
		   (:input :class "form-control" :name "vendor-upi-id" :value vendor-upi-id  :placeholder "Vendor UPI ID" :type "text"))
	     (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))))

(defun hhub-controller-save-vendor-upi-settings ()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforvendorupisettings createwidgetsforgenericredirect)))

(defun createmodelforvendorupisettings ()
  (let* ((upi-id (hunchentoot:parameter "vendor-upi-id"))
	 (vendor (get-login-vendor))
	 (redirecturl "/hhub/dodvendprofile"))
    
    (when (> (length upi-id) 0)
      (setf (slot-value vendor 'upi-id) upi-id)
      (update-vendor-details vendor))
    (function (lambda ()
      (values redirecturl)))))

      
(defun modal.vendor-payment-methods-page (vpaymentmethods)
  (when vpaymentmethods
    (let* ((codenabled (slot-value vpaymentmethods 'codenabled))
	   (upienabled (slot-value vpaymentmethods 'upienabled))
	   (walletenabled (slot-value vpaymentmethods 'walletenabled))
	   (payprovidersenabled (slot-value vpaymentmethods 'payprovidersenabled))
	   (paylaterenabled (slot-value vpaymentmethods 'paylaterenabled)))
      (cl-who:with-html-output (*standard-output* nil)
	(:div :class "row" 
	      (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		    (with-html-form "form-vendpaymentmethodsupdate" "hhubvpmupdateaction"
		      (if (equal codenabled "Y")
			  (with-html-custom-checkbox "codenabled" codenabled "Cash On Demand" T )
			  ;;else
			  (with-html-custom-checkbox "codenabled" "N" "Cash On Demand" NIL))
		      
		      (if (equal upienabled "Y")
			  (with-html-custom-checkbox "upienabled" upienabled "UPI" T)
			;;else
			  (with-html-custom-checkbox "upienabled" "N" "UPI" nil))
		      
		      (if (equal walletenabled "Y")
			  (with-html-custom-checkbox "walletenabled" walletenabled "Prepaid Wallet" T)
			;;else
			  (with-html-custom-checkbox "walletenabled" "N" "Prepaid Wallet" NIL))
		      
		      (if (equal payprovidersenabled "Y")
			  (with-html-custom-checkbox "payprovidersenabled" payprovidersenabled "Payment Gateway (Details must be defined!)" T)
			  ;;else
			(with-html-custom-checkbox "payprovidersenabled" "N" "Pay Providers" nil))
		      
		      (if (equal paylaterenabled "Y")
			  (with-html-custom-checkbox "paylaterenabled" paylaterenabled "Pay Later" T)
			  ;;else
			  (with-html-custom-checkbox "paylaterenabled" "N" "Pay Later" nil))
		      (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save Settings")))))))
  ;; If Vendor payment methods are not found then create one
  (unless vpaymentmethods
    (cl-who:with-html-output (*standard-output* nil)                                                                                                                                                              
      (:div :class "row"
            (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"                                                                                                                                                
                  (with-html-form "form-vendpaymentmethodscreate" "hhubvpmupdateaction"                                                                                                                           
     		    (:div :class "form-group"
			  (with-html-input-text-hidden "createvpaymentmethods" "Y")
			  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Create Vendor Payment Methods"))))))))


(defun dod-controller-vendor-payment-methods-update-action ()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforvendpaymentmethodsupdate createwidgetsforgenericredirect)))

(defun createmodelforvendpaymentmethodsupdate ()
  (let* ((codenbld (hunchentoot:parameter "codenabled"))
	 (upienbld (hunchentoot:parameter "upienabled"))
	 (walletenbld (hunchentoot:parameter "walletenabled"))
	 (payprovidersenbld (hunchentoot:parameter "payprovidersenabled"))
	 (paylaterenbld (hunchentoot:parameter "paylaterenabled"))
	 (createvpaymentmethods (hunchentoot:parameter "createvpaymentmethods"))
	 (company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (requestmodel (make-instance 'VPaymentMethodsRequestModel
				      :vendor vendor
				      :company company
				      :codenabled "Y"
				      :upienabled "Y"
				      :payprovidersenabled "Y"
				      :walletenabled "Y"
				      :paylaterenabled "Y"))
	 (redirecturl "/hhub/dodvendprofile"))
    
    (when (equal createvpaymentmethods "Y")
      (with-entity-create 'VPaymentMethodsAdapter requestmodel
	(if entity (hunchentoot:redirect "/hhub/dodvendprofile"))))
    (unless createvpaymentmethods
      ;; we are in update case now.
      (with-slots (codenabled upienabled payprovidersenabled walletenabled paylaterenabled) requestmodel
	(if codenbld (setf codenabled codenbld) (setf codenabled "N"))
	(logiamhere (format nil "value of codenabled is ~A" codenbld))
	(if upienbld (setf upienabled upienbld) (setf upienabled "N")) 
	(if payprovidersenbld (setf payprovidersenabled payprovidersenbld) (setf payprovidersenabled "N"))
	(if walletenbld (setf walletenabled walletenbld) (setf walletenabled "N"))
	(if paylaterenbld (setf paylaterenabled paylaterenbld) (setf paylaterenabled "N"))
	(with-entity-update 'VPaymentMethodsAdapter requestmodel
	  (if entity
	      (function (lambda ()
		(values redirecturl)))))))))

(defun modal.vendor-update-payment-gateway-settings-page ()
  (let* ((vendor (get-login-vendor))
	 (payment-api-key (payment-api-key vendor))
	 (payment-api-salt (payment-api-salt vendor))
	 (pg-mode (slot-value vendor 'payment-gateway-mode)))
       
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-div-row
	(:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
	(:a  :target "_blank"  :data-bs-toggle "tooltip" :title "Create a Merchant account with our payment partner Tyche Payments. Click here."  :href "https://www.tychepayment.com/merchantform.php" (:i :class "fa-solid fa-circle-info"))))
	
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :id (format nil "form-vendorpaymentgatewayupdate")  :role "form" :method "POST" :action "hhubvendupdatepgsettings" :enctype "multipart/form-data" 
					;(:div :class "account-wall"
			 (:div :class "form-group"
			       (:label :for "payment-api-key" "Payment API Key")
			       (:input :class "form-control" :name "payment-api-key" :value payment-api-key :placeholder "Payment API Key" :type "text"))
			 (:div :class "form-group"
			       (:label :for "payment-api-salt" "Payment API Salt")
			       (:input :class "form-control" :name "payment-api-salt"  :value payment-api-salt :placeholder "Payment API Salt"  :type "text" ))
			 (:div :class "form-group"
			       (:label :for "pg-mode" "Payment Gateway Mode"
				       (payment-gateway-mode-options pg-mode)))
			 
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))))



;; @@ deprecated : start using with-html-dropdown instead. 
(defun payment-gateway-mode-options (selectedkey) 
  (let ((pg-mode (make-hash-table)))
    (setf (gethash "test" pg-mode) "test") 
    (setf (gethash "live" pg-mode) "live")
    (with-html-dropdown "pg-mode" pg-mode selectedkey)))


(defun dod-controller-vendor-update-payment-gateway-settings-action ()
  (with-vend-session-check 
    (with-mvc-redirect-ui createmodelforvendupdatepgsettings createwidgetsforgenericredirect)))

(defun createmodelforvendupdatepgsettings ()
  (let* ((payment-api-key (hunchentoot:parameter "payment-api-key"))
	 (payment-api-salt (hunchentoot:parameter "payment-api-salt"))
	 (pg-mode  (hunchentoot:parameter "pg-mode"))
	 (vpushnotifysubs (hunchentoot:parameter "vpushnotifysubs"))
	 (vendor (get-login-vendor))
	 (redirecturl "/hhub/dodvendprofile"))
    (setf (slot-value vendor 'payment-api-key) payment-api-key)
    (setf (slot-value vendor 'payment-api-salt) payment-api-salt)
    (setf (slot-value vendor 'payment-gateway-mode) pg-mode)
    (setf (slot-value vendor 'push-notify-subs-flag) (if (null vpushnotifysubs) "N" vpushnotifysubs))
    (update-vendor-details vendor)
    (function (lambda ()
      (values redirecturl)))))


(defun modal.vendor-change-pin ()
  (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form "form-vendorchangepin" "hhubvendchangepin"  
					;(:div :class "account-wall"
			 (:h1 :class "text-center login-title"  "Change Password")
			 (:div :class "form-group"
			       (:label :for "password" "Password")
			       (:input :class "form-control" :name "password" :value "" :placeholder "Old Password" :type "password" :required T))
			 (:div :class "form-group"
			       (:label :for "newpassword" "New Password")
			       (:input :class "form-control" :id "newpassword" :data-minlength "8" :name "newpassword" :value "" :placeholder "New Password" :type "password" :required T))
			 (:div :class "form-group"
			       (:label :for "confirmpassword" "Confirm New Password")
			       (:input :class "form-control" :name "confirmpassword" :value "" :data-minlength "8" :placeholder "Confirm New Password" :type "password" :required T :data-match "#newpassword"  :data-match-error "Passwords dont match"  ))
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save")))))))




(defun dod-controller-vendor-change-pin ()
  (with-vend-session-check 
    (let* ((password (hunchentoot:parameter "password"))
	   (newpassword (hunchentoot:parameter "newpassword"))
	   (confirmpassword (hunchentoot:parameter "confirmpassword"))
	   (salt (createciphersalt))
	   (encryptedpass (check&encrypt newpassword confirmpassword salt))
	   (vendor (get-login-vendor))
	   (present-salt (if vendor (slot-value vendor 'salt)))
	   (present-pwd (if vendor (slot-value vendor 'password)))
	   (password-verified (if vendor  (check-password password present-salt present-pwd))))
     (cond 
       ((or
	 (not password-verified) 
	 (null encryptedpass)) (dod-response-passwords-do-not-match-error)) 
       ((and password-verified encryptedpass) (progn 
       (setf (slot-value vendor 'password) encryptedpass)
       (setf (slot-value vendor 'salt) salt) 
       (update-vendor-details vendor)
       (hunchentoot:redirect "/hhub/dodvendprofile")))))))



(defun dod-controller-vendor-customer-list ()
  (with-vend-session-check 
    (let* ((wallets (get-cust-wallets-for-vendor (get-login-vendor) (get-login-vendor-company)))
	   (customers (mapcar (lambda (wallet) 
			   (get-customer wallet)) wallets)))
      (with-standard-vendor-page  "Customers list for vendor" 
	(cl-who:str (display-as-table (list "Name" "Mobile" "Email" "Actions") customers 'vendor-customers-card))))))
 

  

(defun dod-controller-vendor-order-cancel ()
 (with-vend-session-check
  (let* ((id (hunchentoot:parameter "id"))
	(order (get-order-by-id id (get-login-vendor-company)))
	(order-id (slot-value order 'row-id)))
    (cancel-order-by-vendor (get-vendor-order-instance order-id (get-login-vendor)))
    (hunchentoot:redirect "/hhub/dodvendindex?context=pendingorders"))))


(defun dod-controller-vendor-revenue ()
(with-vend-session-check
    ;list all the completed orders for Today. 
    (let* ((todaysorders (dod-get-cached-completed-orders-today))
	   (total (if todaysorders (reduce #'+ (mapcar (lambda (ord) (slot-value ord 'order-amt)) todaysorders)))))
    (with-standard-vendor-page "Welcome to DAS Platform- Vendor"
      (:div :class "row"
	    (:div :class "col-xs-12 col-sm-4 col-md-4 col-lg-4" 
		  "Completed orders "
		  (:span :class "badge" (cl-who:str (format nil " ~d " (length todaysorders))))) 
	    (:div :class  "col-xs-12 col-sm-4 col-md-4 col-lg-4"  :align "right" (:h1(:span :class "label label-default" "Todays Revenue")))	  
      (:div :class  "col-xs-12 col-sm-4 col-md-4 col-lg-4"  :align "right" 
	    (:h2 (:span :class "label label-default" (cl-who:str (format nil "Total = Rs ~$" total))))))
      (:hr)
      (cl-who:str (display-as-tiles todaysorders 'vendor-order-card "order-box" ))))))


 
(defun dod-controller-refresh-pending-orders ()
  (with-vend-session-check 
      (progn 
	(dod-reset-order-functions (get-login-vendor) (get-login-vendor-company))
	(hunchentoot:redirect "/hhub/dodvendindex?context=pendingorders"))))

(defun dod-controller-display-vendor-tenants ()
  (if (is-dod-vend-session-valid?)
      (let* ((vendor-company (get-login-vendor-company))
	     (cmplist (hunchentoot:session-value :login-vendor-tenants)))
	   
	(with-standard-vendor-page "Welcome to DAS Platform - Vendor"
	  (:a :class "btn btn-primary" :role "button" :href "dodvendsearchtenantpage" (:i :class "fa-solid fa-users-line") " Add New Group  ")
	  (:hr)
	  (:h5 (cl-who:str (format nil "Currently Logged Into Group - ~A" (slot-value vendor-company 'name))))
	  (:div :class "list-group col-sm-6 col-md-6 col-lg-6"
	 (if cmplist (mapcar (lambda (cmp)
			       (unless (equal (slot-value vendor-company 'name)  (slot-value cmp 'name))
	    (cl-who:htm  (:a :class "list-group-item" :href (format nil "dodvendswitchtenant?id=~A"  (slot-value cmp 'row-id)) (cl-who:str (format nil "Login to ~A " (slot-value cmp 'name))))
		  ))) cmplist)))))
      (hunchentoot:redirect "/hhub/vendor-login.html")))




(defun dod-controller-cmpsearch-for-vend-page ()
  (if (is-dod-vend-session-valid?)
      (with-standard-vendor-page  "Welcome to DAS platform" 
	(:div :class "row"
	      (:h2 "Search Apartment/Group")
	      (:div :id "custom-search-input"
		    (:div :class "input-group col-md-12"
			  (:form :id "theForm" :action "dodvendsearchtenantaction" :OnSubmit "return false;" 
				 (:input :type "text" :class "  search-query form-control" :id "livesearch" :name "livesearch" :placeholder "Search for an Apartment/Group"))
			  (:span :class "input-group-btn" (:button :class "btn btn-danger" :type "button" 
								(:i :class "fa-solid fa-binoculars")))))
	      (:div :id "searchresult" "")))
      (hunchentoot:redirect "/hhub/hhubvendloginv2")))





(defun dod-controller-cmpsearch-for-vend-action ()
  (let*  ((qrystr (hunchentoot:parameter "livesearch"))
	  (matching-tenants-list (if (not (equal "" qrystr)) (select-companies-by-name qrystr)))
	  (existing-tenants-list (append (get-vendor-tenants-as-companies (get-login-vendor)) (list (get-login-vendor-company))))
	  (final-list (set-difference matching-tenants-list existing-tenants-list :test #'equal-companiesp)))
    (ui-list-cmp-for-vend-tenant final-list)))



(defun ui-list-cmp-for-vend-tenant (company-list)
  (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
  ; (standard-customer-page (:title "Welcome to DAS Platform")
    (if company-list 
	(cl-who:htm (:div :class "row-fluid"	  (mapcar (lambda (cmp)
						      (cl-who:htm 
						       (:form :method "POST" :action "dodvendaddtenantaction" :id "dodvendaddtenantform" 
							      (:div :class "col-sm-4 col-lg-3 col-md-4"
								    (:div :class "form-group"
									  (:input :class "form-control" :name "cname" :type "hidden" :value (cl-who:str (format nil "~A" (slot-value cmp 'name)))))
								    
								    (:div :class "form-group"
									  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" (cl-who:str (format nil "~A" (slot-value cmp 'name)))))))))  company-list)))
	;else
	(cl-who:htm (:div :class "col-sm-12 col-md-12 col-lg-12"
	      (:h3 "No records found"))))))

(defun dod-controller-vend-add-tenant-action ()
  (with-vend-session-check
    (let* ((cname (hunchentoot:parameter "cname"))
	   (company (select-company-by-name cname)))
      (create-vendor-tenant (get-login-vendor) "N"  company))))

(defun dod-controller-vendor-add-product-page ()
  (with-vend-session-check 
    (let ((catglist (hhub-get-cached-product-categories))
	  (charcountid1 (format nil "idchcount~A" (hhub-random-password 3))))
      (with-standard-vendor-page "Welcome to DAS Platform- Your Demand And Supply destination."
	(with-html-div-row
	  (with-html-div-col-3 "")
	  (with-html-div-col-6
	    (:form :class "form-vendorprodadd" :role "form" :method "POST" :action "dodvenaddproductaction" :data-bs-toggle "validator" :enctype "multipart/form-data" 
		   (:div :class "account-wall" 
			 (:img :class "profile-img" :src "/img/logo.png" :alt "")
			 (:h1 :class "text-center login-title"  "Add new product")
			 (with-html-custom-checkbox "isserviceproduct" "N" "This is a Service" nil)
			 (:div :class "form-group"
			       (:input :class "form-control" :name "prdname" :placeholder "Enter Product Name ( max 30 characters) " :type "text" ))
			 (:div :class "form-group"
			       (:label :for "description")
			       (:textarea :class "form-control" :name "description" :placeholder "Enter Product Description ( max 1000 characters) "  :rows "5" :onkeyup (format nil "countChar(~A.id, this, 1000)" charcountid1)))
			 (:div :class "form-group" :id charcountid1)
			 (with-html-input-text-hidden "prd-id" "0") ;; we are adding a new product hence prd-id is 0
			 (:div :class "form-group"
			       (:input :class "form-control" :name "prdprice" :placeholder "Price"  :type "text" :min "0.00" :max "10000.00" :step "0.01" ))
			 (:div :class "form-group"
			       (:input :class "form-control" :name "unitsinstock" :placeholder "Units In Stock"  :type "number" :min "1" :max "10000" :step "1" ))
			 (:div :class "form-group"
			       (:input :class "form-control" :name "qtyperunit" :placeholder "Qty Per Unit"  :type "number" :min "1" :max "10000" :step "1" ))
			 (:div :class "form-group"
			       (:label :for "unitofmeasure" "Unit Of Measure")
			       (with-html-dropdown "unitofmeasure" (get-system-UOM-map) "KG"))
			 (:a :data-bs-toggle "modal" :data-bs-target (format nil "#generatesku-modal")  :href "#"  (:i :class "fa-solid fa-wand-magic-sparkles"))
			 (modal-dialog-v2 (format nil "generatesku-modal") "SKU Generator" (modal.generate-sku-dialog))
			 (:div :class "form-group"
			       (:input :class "form-control" :name "sku" :placeholder "SKU" :value "000000" :type "text" ))
			 (:div :class "form-group"
			       (:input :class "form-control" :name "hsncode" :placeholder "HSN Code" :type "text" ))
			 (:div  :class "form-group" (:label :for "prodcatg" "Select Produt Category:" )
				(ui-list-prod-catg-dropdown catglist nil))
			 (:br) 
			 (:div :class "form-group" (:label :for "yesno" "Enable Subscription")
			       (ui-list-yes-no-dropdown "N"))
			 (:div :class "form-group" (:label :for "prodimage" "Select Product Image:")
			       (:input :class "form-control" :name "prodimage" :placeholder "Product Image" :type "file" ))
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))))))


(defun modal.generate-sku-dialog ()
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-form "skuGeneratorForm" nil
      (:div :class "input-group"
	    (with-html-input-text "productName" "Product Name" "Enter Product Name" "" T "Enter Product Name" 1))
      (:div :class "input-group"
	    (with-html-input-text "productDescription" "Product Description" "Enter Product Description" "" T "Enter Product Description" 2))
      (:div :class "input-group"
	    (with-html-input-number "qtyperunit" "Qty Per Unit" "Quantity Per Unit" "" 1 10000 t "Enter a number" 3)) 
      (:div :class "form-group"
	    (:label :for "unitofmeasure" "Unit Of Measure")
	    (with-html-dropdown "unitOfMeasure" (get-system-UOM-map) "KG"))
      (:div :class "input-group"
	    (with-html-input-text-readonly "generatedSku" "Generated SKU" "Generated SKU" "" T "Generated SKU" 3))
      (:button :class "btn btn-outline-secondary mr-1" :type "button" :id "copySkuBtn" (:i :class "fa fa-clipboard") "&nbsp;Copy&nbsp;")
      (:button :class "btn btn-primary" :type "button" :id "generateSkuBtn" "Generate SKU")
      (:script :src (format nil "~A/js/gensku.js" *siteurl*)))))


(defun vendor-upload-file-s3bucket (filename objectname object-id vendor-id tenant-id)
  :description "Sends the filename and other parameters to the node js file server, which will upload the file to s3 bucket and return the url"
  (let* ((uuid (format nil "~A" (uuid:make-v1-uuid)))
	 (vendorid-str (format nil "~A" vendor-id))
	 (tenantid-str (format nil "~A" tenant-id))
	 (objectid-str (format nil "~A" object-id))
	 (type "vendor")
	 (paramnames (list "tenantid" "type" "vendorid" "objectname" "objectid" "uuid" "filename"))
         (paramvalues (list tenantid-str type vendorid-str objectname objectid-str uuid filename))
         (param-alist (pairlis paramnames paramvalues))
         (headers nil)
	 (url (format nil "~A/file/awss3v3/upload" *siteurl*))
         (headers (acons "auth-secret" "ntstores1234" headers)))   
    (drakma:http-request url
			      :method :get
			      :additional-headers headers
			      :parameters param-alist)))
 

(defun vendor-delete-files-s3bucket (objectname object-id vendor-id tenant-id)
  :description "Sends the filename and other parameters to the node js file server, which will delete the file to s3 bucket and return the url"
  (let* ((vendorid-str (format nil "~A" vendor-id))
	 (tenantid-str (format nil "~A" tenant-id))
	 (objectid-str (format nil "~A" object-id))
	 (type "vendor")
	 (paramnames (list "tenantid" "type" "vendorid" "objectname" "objectid"))
         (paramvalues (list tenantid-str type vendorid-str objectname objectid-str))
         (param-alist (pairlis paramnames paramvalues))
         (headers nil)
	 (url (format nil "~A/file/awss3v3/deletefiles" *siteurl*))
         (headers (acons "auth-secret" "ntstores1234" headers)))   
    (drakma:http-request url
			 :method :DELETE 
			 :additional-headers headers
			 :parameters param-alist)))


(defun com-hhub-transaction-vend-prd-shipinfo-add-action ()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforvprodshipinfoaddaction createwidgetsforgenericredirect)))


(defun createmodelforvprodshipinfoaddaction()
  (let* ((vendor (get-login-vendor))
	 (shipping-enabled (slot-value vendor 'shipping-enabled))
	 (id (hunchentoot:parameter "id"))
	 (product (if id (select-product-by-id id (get-login-vendor-company))))
	 (shipping-length-cms (parse-integer (hunchentoot:parameter "shipping-length-cms")))
	 (shipping-width-cms (parse-integer (hunchentoot:parameter "shipping-width-cms")))
	 (shipping-height-cms (parse-integer (hunchentoot:parameter "shipping-height-cms")))
	 (shipping-weight-kg (float (with-input-from-string (in (hunchentoot:parameter "shipping-weight-kg"))
				      (read in))))
	 (redirecturl (format nil "/hhub/dodprddetailsforvendor?id=~A" id))
	 (params nil))
    (setf params (acons "company" (get-login-vendor-company) params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "vendor" (get-login-vendor)  params))
    (with-hhub-transaction "com-hhub-transaction-vend-prd-shipinfo-add-action" params
      (when (and shipping-enabled  product) 
	(setf (slot-value product 'shipping-length-cms) shipping-length-cms)
	(setf (slot-value product 'shipping-width-cms) shipping-width-cms)
	(setf (slot-value product 'shipping-height-cms) shipping-height-cms)
	(setf (slot-value product 'shipping-weight-kg) shipping-weight-kg)
	(update-prd-details product)
	(dod-reset-vendor-products-functions vendor (get-login-vendor-company))))
	(function (lambda ()
	  (values redirecturl)))))


(defun com-hhub-transaction-vendor-product-add-action () 
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforvprodaddaction createwidgetsforgenericredirect)))

(defun createmodelforvprodaddaction ()
  (let* ((prodname (hunchentoot:parameter "prdname"))
	 (prd-id (parse-integer (hunchentoot:parameter "prd-id")))
	 (vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (productlist (if (> prd-id 0) (hhub-get-cached-vendor-products)))
	 (product (if (> prd-id 0) (search-item-in-list 'row-id prd-id productlist)))
	 (description (hunchentoot:parameter "description"))
	 (hsn-code (hunchentoot:parameter "hsn-code"))
	 (sku (hunchentoot:parameter "sku"))
	 (upc (hunchentoot:parameter "upc"))
	 (isserviceproduct (hunchentoot:parameter "isserviceproduct"))
	 (prd-type (if (equal isserviceproduct "Y") "SERV" "SALE")) 
	 (qtyperunit (float (with-input-from-string (in (hunchentoot:parameter "qtyperunit"))
			     (read in))))
	 (unit-of-measure (hunchentoot:parameter "unitofmeasure"))
	 (units-in-stock (parse-integer (hunchentoot:parameter "unitsinstock")))
	 (catg-id (parse-integer (hunchentoot:parameter "prodcatg")))
	 (subscriptionflag (hunchentoot:parameter "yesno"))
	 (external-url (if product (generate-product-ext-url product)))
	 (redirecturl nil)
	 (params nil))
    (if product
	(setf params (acons "mode" "edit" params))
	;;else
	(setf params (acons "mode" "add" params)))
    (setf params (acons "company" company params))
    (setf params (acons "vendor" vendor params))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (with-hhub-transaction "com-hhub-transaction-vendor-product-add-action" params 
      (progn 
	(if product 
	    (progn
	      (setf (slot-value product 'prd-name) prodname)
	      (setf (slot-value product 'description) description)
	      (setf (slot-value product 'catg-id) catg-id)
	      (setf (slot-value product 'qty-per-unit) qtyperunit)
	      (setf (slot-value product 'unit-of-measure) unit-of-measure)
	      (setf (slot-value product 'units-in-stock) units-in-stock)
	      (setf (slot-value product 'subscribe-flag) subscriptionflag)
	      (setf (slot-value product 'external-url) external-url)
	      (setf (slot-value product 'prd-type) prd-type)
	      (setf (slot-value product 'hsn-code) hsn-code)
	      (setf (slot-value product 'sku) sku)
	      (setf (slot-value product 'upc) upc)
	      (update-prd-details product)
	      (setf redirecturl (format nil "/hhub/dodprddetailsforvendor?id=~A" prd-id)))
	    ;;else
	    (progn 
	      (create-product prodname description vendor (select-prdcatg-by-id catg-id company) sku hsn-code qtyperunit unit-of-measure  units-in-stock (format nil "/img/~A" *HHUBDEFAULTPRDIMG*)  subscriptionflag prd-type company)
	      (setf redirecturl "/hhub/dodvenproducts")))
	(dod-reset-vendor-products-functions vendor company)))
    (function (lambda ()
      (values redirecturl)))))

(defun dod-controller-vendor-password-reset-action ()
  (let* ((pwdresettoken (hunchentoot:parameter "token"))
	 (rstpassinst (get-reset-password-instance-by-token pwdresettoken))
	 (user-type (if rstpassinst (slot-value rstpassinst 'user-type)))
	 (password (hunchentoot:parameter "password"))
	 (newpassword (hunchentoot:parameter "newpassword"))
	 (confirmpassword (hunchentoot:parameter "confirmpassword"))
	 (salt (createciphersalt))
	 (encryptedpass (check&encrypt newpassword confirmpassword salt))
	 (email (if rstpassinst (slot-value rstpassinst 'email)))
	 (vendor (select-vendor-by-email email))
	 (present-salt (if vendor (slot-value vendor 'salt)))
	 (present-pwd (if vendor (slot-value vendor 'password)))
	 (password-verified (if vendor  (check-password password present-salt present-pwd))))
     (cond 
       ((or  (not password-verified)  (null encryptedpass)) (dod-response-passwords-do-not-match-error)) 
       ;Token has expired
       ((and (equal user-type "VENDOR")
		 (clsql-sys:duration> (clsql-sys:time-difference (clsql-sys:get-time) (slot-value rstpassinst 'created))  (clsql-sys:make-duration :minute *HHUBPASSRESETTIMEWINDOW*))) (hunchentoot:redirect "/hhub/hhubpassresettokenexpired.html"))
       ((and password-verified encryptedpass) (progn 
       (setf (slot-value vendor 'password) encryptedpass)
       (setf (slot-value vendor 'salt) salt) 
       (update-vendor-details vendor)
       (hunchentoot:redirect "/hhub/vendor-login.html"))))))
 


(defun dod-controller-vendor-password-reset-page ()
  (let ((token (hunchentoot:parameter "token")))
(with-standard-vendor-page (:title "Password Reset") 
(:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form "form-vendorchangepin" "hhubvendpassresetaction"  
					;(:div :class "account-wall"
			 (:h1 :class "text-center login-title"  "Change Password")
			 (:div :class "form-group"
			  
			       (:input :class "form-control" :name "token" :value token :type "hidden"))
			 (:div :class "form-group"
			       (:label :for "password" "Password")
			       (:input :class "form-control" :name "password" :value "" :placeholder "Enter OTP from Email Old" :type "password" :required T))
			 (:div :class "form-group"
			       (:label :for "newpassword" "New Password")
			       (:input :class "form-control" :id "newpassword" :data-minlength "8" :name "newpassword" :value "" :placeholder "New Password" :type "password" :required T))
			 (:div :class "form-group"
			       (:label :for "confirmpassword" "Confirm New Password")
			       (:input :class "form-control" :name "confirmpassword" :value "" :data-minlength "8" :placeholder "Confirm New Password" :type "password" :required T :data-match "#newpassword"  :data-match-error "Passwords dont match"  ))
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))))


(defun dod-controller-vendor-generate-temp-password ()
  (let* ((token (hunchentoot:parameter "token"))
	 (rstpassinst (get-reset-password-instance-by-token token))
	 (user-type (if rstpassinst (slot-value rstpassinst 'user-type)))
	 (url (format nil "~A/hhub/hhubvendpassreset.html?token=~A" *siteurl*  token))
	 (email (if rstpassinst (slot-value rstpassinst 'email))))
    
	 (cond 
	   ((and (equal user-type "VENDOR")
		 (clsql-sys:duration< (clsql-sys:time-difference (clsql-sys:get-time) (slot-value rstpassinst 'created))  (clsql-sys:make-duration :minute *HHUBPASSRESETTIMEWINDOW*)))
	    (let* ((vendor (select-vendor-by-email email))
		   (newpassword (reset-vendor-password vendor)))
					;send mail to the vendor with new password 
	      (send-temp-password vendor newpassword url)
	      (hunchentoot:redirect "/hhub/hhubpassresetmailsent.html")))	  
	   ((and (equal user-type "VENDOR")
		 (clsql-sys:duration> (clsql-sys:time-difference (clsql-sys:get-time) (slot-value rstpassinst 'created))  (clsql-sys:make-duration :minute *HHUBPASSRESETTIMEWINDOW*))) (hunchentoot:redirect "/hhub/hhubpassresettokenexpired.html"))
	   ((equal user-type "CUSTOMER") ())
	   ((equal user-type "EMPLOYEE") ()))))



(defun dod-controller-vendor-reset-password-action-link ()
(let* ((email (hunchentoot:parameter "email"))
       (vendor (select-vendor-by-email email))
       (token (format nil "~A" (uuid:make-v1-uuid )))
       (user-type (hunchentoot:parameter "user-type"))
       (tenant-id (if vendor (slot-value vendor 'tenant-id)))
       (captcha-resp (hunchentoot:parameter "g-recaptcha-response"))
       (paramname (list "secret" "response" ))
       (url (format nil "~A/hhub/hhubvendgentemppass?token=~A" *siteurl*  token))
       (paramvalue (list *HHUBRECAPTCHAv2SECRET*  captcha-resp))
       (param-alist (pairlis paramname paramvalue ))
       (json-response (json:decode-json-from-string  (map 'string 'code-char(drakma:http-request "https://www.google.com/recaptcha/api/siteverify"
												 :method :POST
												 :parameters param-alist  )))))
  
  
  (cond 
	 ; Check whether captcha has been solved 
    ((null (cdr (car json-response))) (dod-response-captcha-error))
    ((null vendor) (hunchentoot:redirect "/hhub/hhubinvalidemail.html"))
    ; if vendor is valid then create an entry in the password reset table. 
    ((and (equal user-type "VENDOR") vendor)
     (progn 
       (create-reset-password-instance user-type token email  tenant-id)
       ; temporarily disable the vendor record 
       (setf (slot-value vendor 'active-flag) "N")
       (update-vendor-details vendor) 
       ; Send vendor an email with password reset link. 
       (send-password-reset-link vendor url)
       (hunchentoot:redirect "/hhub/hhubpassresetmaillinksent.html"))))))





(defun modal.vendor-forgot-password() 
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(:form :id (format nil "form-vendorforgotpass")  :role "form" :method "POST" :action "hhubvendforgotpassactionlink" :enctype "multipart/form-data" 
		      (:h1 :class "text-center login-title"  "Forgot Password")
		      (:div :class "form-group"
			    (:input :class "form-control" :name "email" :value "" :placeholder "Email" :type "text")
			    (:input :class "form-control" :name "user-type" :value "VENDOR"  :type "hidden" :required "true"))
		      (:div :class "form-group"
			(:div :class "g-recaptcha" :data-sitekey *HHUBRECAPTCHAV2KEY* ))
		      (:div :class "form-group"
			    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Reset Password")))))))


    

(defun dod-controller-vendor-loginpage ()
  (handler-case
      (progn  (if (equal (caar (clsql:query "select 1" :flatp nil :field-names nil :database *dod-db-instance*)) 1) T)	      
	      (if (is-dod-vend-session-valid?)
		  (hunchentoot:redirect "/hhub/dodvendindex?context=home")
		  (with-standard-vendor-page-v2 "Welcome to Nine Stores Platform - Vendor Login "
		    (with-html-div-row
		      (with-html-div-col-12
			(with-html-card "/img/logo.png" "" "Vendor - Login to Nine Stores" ""
			  (:form :class "form-vendorsignin" :role "form" :method "POST" :action "dodvendlogin"
				 (:div :class "form-group"
				       (:input :class "form-control" :name "phone" :placeholder "Enter RMN. Ex:9999999990" :type "text" ))
				 (:div :class "form-group"
				       (:input :class "form-control" :name "password" :placeholder "password=Welcome1" :type "password" ))
				 (:div :class "form-group"
				       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Login")))
			  (:div :class "form-group"
				(:a :data-bs-toggle "modal" :data-bs-target (format nil "#dasvendforgotpass-modal") :href "#" "Forgot Password?")
				(modal-dialog-v2 (format nil "dasvendforgotpass-modal") "Forgot Password?" (modal.vendor-forgot-password)))
			  (hhub-html-page-footer)))))))
    (clsql:sql-database-data-error (condition)
      (if (equal (clsql:sql-error-error-id condition) 2013 ) (progn
							       (stop-das) 
							       (start-das)
							       (hunchentoot:redirect "/hhub/vendor-login.html"))))))





(defun dod-controller-vendor-otploginpage ()
  (handler-case 
      (progn  
	(if (equal (caar (clsql:query "select 1" :flatp nil :field-names nil :database *dod-db-instance*)) 1) T)      
	(if (is-dod-vend-session-valid?)
	    (hunchentoot:redirect "/hhub/dodvendindex?context=home")
	    (with-standard-vendor-page-v2  "Welcome to Nine Stores Platform - Vendor Login "
	      (with-html-div-row
		(with-html-div-col-12
		  (with-html-card "/img/logo.png" "" "Vendor - Login to Nine Stores" ""
		    (with-html-form  "form-vendorsignin" "hhubvendloginotpstep"
		      (:div :class "form-group"
			    (:input :class "form-control" :name "phone" :placeholder "Enter RMN. Ex: 9999999999" :type "number" :required "true" ))
		      (:div :class "form-group"
			    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Get OTP")))
		    (hhub-html-page-footer)))))))
    (clsql:sql-database-data-error (condition)
      (if (equal (clsql:sql-error-error-id condition) 2013 ) (progn
							       (stop-das) 
							       (start-das)
							       (hunchentoot:redirect "/hhub/hhubvendloginv2"))))))



(defun dod-controller-vendor-my-customers-page ()
  (with-vend-session-check
    (with-mvc-ui-page "My Customers" createmodelforshowvendorcustomers createwidgetsforshowvendorcustomers :role  :vendor )))

(defun createmodelforshowvendorcustomers ()
  (let* ((vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (wallets (get-cust-wallets-for-vendor vendor company))
	 (mycustomers (remove nil (mapcar (lambda (wallet)
					    (let* ((customer (slot-value wallet 'customer))
						   (cust-type (slot-value customer 'cust-type)))
					      (when (equal cust-type "STANDARD") customer))) wallets))))
    (function (lambda ()
      (values mycustomers)))))

(defun createwidgetsforshowvendorcustomers (modelfunc)
  (multiple-value-bind (mycustomers) (funcall modelfunc)
    (let* ((widget1 (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-search-form "idsearchmycustomer" "searchmycustomer" "idtxtsearchcustomer" "txtsearchcustomer" "hhubsearchmycustomer" "onkeyupsearchform1event();" "Customer Name"
			  (submitsearchform1event-js "#idtxtsearchcustomer" "#vendormycustomerssearchresult" ))
			(:div :id "vendormycustomerssearchresult"  :class "container-fluid"
			      (cl-who:str (display-as-table (list "Name" "Phone" "Address" "Balance" "Actions") mycustomers 'display-my-customers-row))))))))
      (list widget1))))



(defun hhub-controller-search-my-customer-action ()
  (with-vend-session-check
    (let* ((company (get-login-vendor-company))
	   (vendor (get-login-vendor))
	   (name (hunchentoot:parameter "txtsearchcustomer"))
	   (totalcustomers (select-customer-list-by-name (format nil "%~A%" name) company))
	   (customers (remove nil (mapcar (lambda (customer)
					    (if (get-cust-wallet-by-vendor customer vendor company) customer)) totalcustomers))))
      
      (if (> (length customers) 0)
	(cl-who:with-html-output (*standard-output* nil) 
	  (cl-who:str (display-as-table (list "Name" "Phone" "Address" "Balance" "Actions") customers 'display-my-customers-row)))
	;; else
	(cl-who:with-html-output (*standard-output* nil)
	  (:h3 (cl-who:str "No Records Found")))))))
	
       
(defun hhub-controller-vsearchcustbyname-for-invoice-action ()
  (with-vend-session-check
    (let* ((company (get-login-vendor-company))
	   (name (hunchentoot:parameter "txtsearchcustomername"))
	   (customers (select-customer-list-by-name (format nil "%~A%" name) company)))
      (if (> (length customers) 0)
	(cl-who:with-html-output (*standard-output* nil) 
	  (cl-who:str (display-as-table (list "Name" "Phone" "Action") customers 'display-add-customer-to-invoice-row)))
	;; else
	(cl-who:with-html-output (*standard-output* nil)
	  (:h3 (cl-who:str "No Records Found")))))))

(defun hhub-controller-vsearchcustbyphone-for-invoice-action ()
  (with-vend-session-check
    (let* ((company (get-login-vendor-company))
	   (name (hunchentoot:parameter "txtsearchcustomerphone"))
	   (customers (select-customer-list-by-phone (format nil "~A%" name) company)))
      (if (> (length customers) 0)
	(cl-who:with-html-output (*standard-output* nil) 
	  (cl-who:str (display-as-table (list "Name" "Phone" "Action") customers 'display-add-customer-to-invoice-row)))
	;; else
	(cl-who:with-html-output (*standard-output* nil)
	  (:h3 (cl-who:str "No Records Found")))))))



(defun display-my-customers-row (customer &rest arguments)
  (declare (ignore arguments))
  (let* ((vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (currency (get-account-currency company))
	 (cust-id (slot-value customer 'row-id))
	 (cust-phone (slot-value customer 'phone))
	 (cust-name (slot-value customer 'name))
	 (wallet (get-cust-wallet-by-vendor customer  vendor company))
	 (chatonwhatsappurl (createwhatsapplinkwithmessage cust-phone (format nil "Hi ~A" cust-name))))
    (with-slots (name phone address) customer
      (cl-who:with-html-output (*standard-output* nil)
	(:td  :height "10px" (cl-who:str name))
	(:td  :height "10px" (cl-who:str phone))
	(:td  :height "10px" (cl-who:str address))
	(:td  :height "10px" (cl-who:str (slot-value wallet 'balance)))
	(:td  :height "10px"
	      (:a :data-bs-toggle "modal" :data-bs-target (format nil "#vendormycustomerwallet~A" cust-id)  :href "#"  (:i :class (get-currency-fontawesome-symbol currency) :aria-hidden "true"))
	      (modal-dialog-v2 (format nil "vendormycustomerwallet~A" cust-id) "Recharge Wallet" (modal.vendor-my-customer-wallet-recharge wallet phone)))
	      (:td :height "10px" (:a :href chatonwhatsappurl :target "_blank" (:i :class "fa-brands fa-whatsapp fa-xl" :style "color: #39dd30;")))))))
 
(defun modal.vendor-my-customer-wallet-recharge (wallet phone)
  (cl-who:with-html-output (*standard-output* nil)
    (with-html-div-row
      (with-html-div-col
	(:form :class "form-vendor-update-balance" :role "form" :method "POST" :action "dodupdatewalletbalance"
	       (:div :class "form-group"
		     (:input :class "form-control" :name "balance" :placeholder "recharge amount" :type "text" ))
	       (:input :class "form-control" :name "wallet-id" :value (slot-value wallet 'row-id) :type "text" :style "display:none;")
	       (:input :class "form-control" :name "phone" :value phone :type "text" :style "display:none;")
	       (:div :class "form-group"
		     (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save")))))
    (with-html-div-row
      (:h5 "Note: Receive money from customer via cash/UPI and then update the wallet balance here."))))
      
;; Deprecated. 
(defun dod-controller-vendor-search-cust-wallet-page ()
  :Description "Deprecated function"
  (with-vend-session-check 
    (with-standard-vendor-page "Welcome to DAS Platform- Your Demand And Supply destination."
      (:div :class "row" 
	    (:div :class "col-sm-6 col-md-4 col-md-offset-4"
		  (:form :class "form-cust-wallet-search" :role "form" :method "POST" :action "dodsearchcustwalletaction"
			 (:div :class "account-wall"
			       (:div :class "form-group"
				     (:input :class "form-control" :name "phone" :placeholder "Enter Customer Phone Number" :type "number" :size "10" ))
			       
			       (:div :class "form-group"
				     (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save")))))))))
  


;; Deprecated
(defun dod-controller-vendor-search-cust-wallet-action ()
  :description "Deprecated function" 
  (if (is-dod-vend-session-valid?)
  (let* ((phone (hunchentoot:parameter "phone"))
	 (customer (select-customer-by-phone phone (get-login-vendor-company)))
	 (wallet (if customer (get-cust-wallet-by-vendor customer (get-login-vendor) (get-login-vendor-company)))))
 
    (if (null wallet) 
	(with-standard-vendor-page (:title "Welcome to DAS Platform")
	  (:div :class "row" 
		(:div :class "col-sm-6 col-md-4 col-md-offset-4" (:h3 "Wallet does not exist"))))
					;else
	(with-standard-vendor-page (:title "Welcome to DAS Platform")
	  (:div :class "row" 
		(:div :class "col-sm-6 col-md-4 col-md-offset-4" (:h3 (cl-who:str (format nil "Name: ~A" (if customer (slot-value customer 'name)))))))
	  (:div :class "row" 
		(:div :class "col-sm-6 col-md-4 col-md-offset-4" (:h3 (cl-who:str (format nil "Phone: ~A" (if customer (slot-value customer 'phone)))))))
	  (:div :class "row" 
		(:div :class "col-sm-6 col-md-4 col-md-offset-4" (:h3 (cl-who:str (format nil "Address: ~A" (if customer (slot-value customer 'address)))))))
	  
	  (:div :class "row" 
		(:div :class "col-sm-6 col-md-4 col-md-offset-4" (:h3 (cl-who:str (format nil "Balance = Rs.~$" (slot-value wallet 'balance))))))
	  (:div :class "row" 
		(:div :class "col-sm-6 col-md-4 col-md-offset-4"
		      (:form :class "form-vendor-update-balance" :role "form" :method "POST" :action "dodupdatewalletbalance"
			     (:div :class "account-wall"
				   (:div :class "form-group"
					 (:input :class "form-control" :name "balance" :placeholder "recharge amount" :type "text" ))
				   (:input :class "form-control" :name "wallet-id" :value (slot-value wallet 'row-id) :type "hidden")
				   (:input :class "form-control" :name "phone" :value phone :type "hidden")
				   (:div :class "form-group"
			    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save")))))))))
  (hunchentoot:redirect "/hhub/vendor-login.html")))


(defun dod-controller-update-wallet-balance ()
  (with-vend-session-check
    (let* ((amount (parse-integer (hunchentoot:parameter "balance")))
	   (wallet (get-cust-wallet-by-id (hunchentoot:parameter "wallet-id") (get-login-vendor-company)))
	   (current-balance (slot-value wallet 'balance))
	   (latest-balance (+ current-balance amount)))
      (set-wallet-balance latest-balance wallet)
      ;; We need to clear this memoized function and again memoize it.
      ;; (memoize 'get-cust-wallet-by-vendor)
      (hunchentoot:redirect (format nil "/hhub/hhubvendmycustomers")))))
    
   
(defun dod-controller-vend-profile ()
  (with-vend-session-check
    (with-mvc-ui-page "Vendor Profile" createmodelforvendorprofile createwidgetsforvendorprofile :role :vendor)))

(defun createmodelforvendorprofile ()
  (let* ((company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (adapter (make-instance 'VPaymentMethodsAdapter))
	 (requestmodel (make-instance 'VPaymentMethodsRequestModel
				      :company company
				      :vendor vendor))
	 (vpaymentmethods (processreadrequest adapter requestmodel))
	 (vendorname (get-login-vendor-name)))
    (function (lambda ()
      (values vendorname  vpaymentmethods)))))

(defun createwidgetsforvendorprofile (modelfunc)
  (multiple-value-bind (vendorname vpaymentmethods) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (:br)
		       (:h3 "Welcome " (cl-who:str (format nil "~A" vendorname)))
		       (:hr)))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-html-div-row
			 (with-html-div-col-6
			   (with-catch-submit-event "idvendorprofilesubmitevents"  
			     (:a :class "list-group-item list-group-item-action" :href "dodvendortenants" "My Groups")
			     (:a :class "list-group-item list-group-item-action" :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendupdate-modal")  :href "#"  "Contact Information")
			     (modal-dialog-v2 (format nil "dodvendupdate-modal") "Update Vendor" (modal.vendor-update-details)) 
			     ;; Since we are enabling the OTP based login for Vendor, we do not need password. 
			     ;;(:a :class "list-group-item" :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendchangepin-modal")  :href "#"  "Change Password")
			     ;;(modal-dialog-v2 (format nil "dodvendchangepin-modal") "Change Password" (modal.vendor-change-pin))
			     ;; (:a :class "list-group-item" :href "/pushsubscribe.html" "Push Notifications")
			     ;;(:a :class "list-group-item" :href "/hhub/hhubvendpushsubscribepage" "Push Notifications")
			     (:a :class "list-group-item list-group-item-action" :href "hhubvendorshipmethods" "E-Commerce Shipping Methods")
			     (:a :class "list-group-item list-group-item-action" :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendpaymentmethods-modal")  :href "#"  "E-Commerce Payment Methods")
			     (modal-dialog-v2 (format nil "dodvendpaymentmethods-modal") "Payment Methods " (modal.vendor-payment-methods-page vpaymentmethods))
			     (:a :class "list-group-item list-group-item-action" :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendsettings-modal")  :href "#"  "E-Commerce Payment Gateway")
			     (modal-dialog-v2 (format nil "dodvendsettings-modal") "Payment Gateway Settings" (modal.vendor-update-payment-gateway-settings-page))
			     (:a :class "list-group-item list-group-item-action" :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendupisettings-modal") :href "#" "UPI Settings")
			     (modal-dialog-v2 (format nil "dodvendupisettings-modal") "UPI Payment Settings" (modal.vendor-update-UPI-payment-settings-page))))))))))
      (list widget1 widget2))))
  

(defun dod-controller-vend-shipping-methods ()
  (with-vend-session-check
    (with-mvc-ui-page "Vendor Shipping Methods for E-Commerce" createmodelforvendshippingmethods createwidgetsforvendshippingmethods :role :vendor)))

(defun createmodelforvendshippingmethods ()
  (let* ((vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (shippingmethod (get-shipping-method-for-vendor vendor company))
	 (flatrateshipenabled (slot-value shippingmethod 'flatrateshipenabled))
	 (flatratetype (slot-value shippingmethod 'flatratetype))
	 (flatrateprice (slot-value shippingmethod 'flatrateprice))
	 (extshipenabled (slot-value shippingmethod 'extshipenabled))
	 (shippartnerkey (slot-value shippingmethod 'shippartnerkey))
	 (shippartnersecret (slot-value shippingmethod 'shippartnersecret))
	 (minorderamt (when shippingmethod (getminorderamt shippingmethod)))
	 (freeshipenabled (when shippingmethod (slot-value shippingmethod 'freeshipenabled))))
    (function (lambda ()
      (values vendor shippingmethod flatrateshipenabled flatratetype flatrateprice extshipenabled shippartnerkey shippartnersecret minorderamt freeshipenabled )))))

(defun createwidgetsforvendshippingmethods (modelfunc)
  (multiple-value-bind (vendor shippingmethod flatrateshipenabled flatratetype flatrateprice extshipenabled shippartnerkey shippartnersecret minorderamt freeshipenabled) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (:br)
		       (:div :class "list-group col-6"
			     (:a :class "list-group-item list-group-item-action" :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendfreeshipping-modal")  :href "#"  "Free Shipping")
			     (modal-dialog-v2 (format nil "dodvendfreeshipping-modal") "Free Shipping Configuration" (modal.vendor-free-shipping-config freeshipenabled minorderamt))
			     (:a :class "list-group-item list-group-item-action" :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendflatrateshipping-modal")  :href "#"  "Flat Rate Shipping")
			     (modal-dialog-v2 (format nil "dodvendflatrateshipping-modal") "Flat Rate Shipping Configuration" (modal.vendor-flatrate-shipping-config flatrateshipenabled flatratetype flatrateprice))
			     (:a :class "list-group-item list-group-item-action" :href "hhubvendshipzoneratetablepage"  "Zonewise Shipping")
			     (:a :class "list-group-item list-group-item-action" :data-bs-toggle "modal" :data-bs-target (format nil "#dodvendextshipping-modal")  :href "#"  "External Shipping Partners")
			     (modal-dialog-v2 (format nil "dodvendextshipping-modal") "External Shipping Partners Configuration" (modal.vendor-external-shipping-partners-config shippartnerkey shippartnersecret extshipenabled))
			     (:a :class "list-group-item list-group-item-action" :data-bs-toggle "modal" :data-bs-target (format nil "#dodvenddefaultshipmethod-modal")  :href "#"  "Select Default Shipping Method")
			     (modal-dialog-v2 (format nil "dodvenddefaultshipmethod-modal") "Default Shipping Method Configuration" (modal.vendor-default-shipping-method-config shippingmethod vendor)))))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
	     	       (:script "function enableminorderamt() {
    const freeshipenabled = document.getElementById('freeshipenabled');
    if( freeshipenabled.checked ){
	$('#minorderamtctrl').show();
        freeshipenabled.value = \"Y\";
    }else
    {
       $('#minorderamtctrl').hide();
       freeshipenabled.value = \"N\";
    }
}")))))
	  (widget3 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (:script "function enablevendorshipping() {
    const vendorshipenabled = document.getElementById('vendorshipenabled');
    if( vendorshipenabled.checked ){
         vendorshipenabled.value = \"Y\";
	$('#vendorshipenabledctrl').show();
        
    }else
    {
          vendorshipenabled.value = \"N\";
       $('#vendorshipenabledctrl').hide();
      
    }
}")))))
	  (widget4 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (:script "function enablestorepickupmethod(){
       const  enablestorepickup  = document.getElementById('storepickupenabled');
    if( enablestorepickup.checked ){
         enablestorepickup.value = \"Y\";
    }else
    {
         enablestorepickup.value = \"N\";
    }
}"))))))
      (list widget1 widget2 widget3 widget4))))

(defun dod-controller-vendor-shipzone-ratetable-page()
  (with-vend-session-check
    (let* ((vendor (get-login-vendor))
	   (company (get-login-vendor-company))
	   (shippingmethod (get-shipping-method-for-vendor vendor company))
	   (tablerateshipenabled (if shippingmethod (slot-value shippingmethod 'tablerateshipenabled)))
	   (ratetablecsv (if (and tablerateshipenabled shippingmethod) (getratetablecsv shippingmethod) (hhub-read-file (format nil "~A/~A" *HHUBRESOURCESDIR* *HHUBDEFAULTSHIPRATETABLECSV*))))
	   (shipzones (get-ship-zones-for-vendor vendor company))
	   (zipcoderanges (hhub-read-file (format nil "~A/~A" *HHUBRESOURCESDIR* *HHUBDEFAULTSHIPZONESCSV*))))

      (with-standard-vendor-page "Nine Stores - Vendor Zonewise Shipping Method"
	(with-html-form "form-vendorshipratetableupload" "hhubvenduploadshipratetableaction"
	  (:div :class "form-check"
		(if (equal tablerateshipenabled "Y")
			    (cl-who:htm (:input :type "checkbox" :id "tablerateshipenabled" :name "tablerateshipenabled" :value "Y" :onclick (parenscript:ps (enableratetableshipping)) :tabindex "1"  :checked "true"))
			    ;; else
			    (cl-who:htm
			     (:input :type "checkbox" :id "tablerateshipenabled" :name "tablerateshipenabled" :value "N" :onclick (parenscript:ps (enableratetableshipping)) :tabindex "1")))
		(:label :for "tablerageshipenabled" "&nbsp;&nbsp;&nbsp;Enable Zonewise Shipping:"))
	  (:br)
	  (cl-who:htm (:div :id "ratetablecsvuploadctrl"
			      (:div :class "form-group" (:label :for "" "Select Shipping Rate Table CSV:")
				    (:input :class "form-control" :name "ratetablecsv" :placeholder "Rate Table CSV File" :type "file" )
			      (:a :href (format nil "/img/~A"  *HHUBDEFAULTSHIPRATETABLECSV*) (:i :class "fa-solid fa-file-arrow-down fa-beat fa-lg") "&nbsp;&nbsp;Download Sample CSV File"))
			      (:div :class "form-group" (:label :for "" "Select Shipping Zones & Pincodes CSV:")
				    (:input :class "form-control" :name "zonepincodescsv" :placeholder "Shipping Zones & Pincodes CSV File" :type "file" ))
			      (:div (:a :href (format nil "/img/~A"  *HHUBDEFAULTSHIPZONESCSV*) (:i :class "fa-solid fa-file-arrow-down fa-beat fa-lg") "&nbsp;&nbsp;Download Sample CSV File"))))
			(:div :class "form-group"
			      (:button :class "btn btn-primary" :type "submit" "Save")))
	
	
	(:hr)
	(when ratetablecsv
	  (cl-who:str
	   (display-csv-as-html-table ratetablecsv)))
	(:br)
	(unless shipzones
	  (cl-who:str (display-csv-as-html-table zipcoderanges)))
	(:p
	 (:h5 "Note: You can find more information on how Indian Pincode system works "
	      (:a :target "_blank" :href "https://en.wikipedia.org/wiki/Postal_Index_Number" "Click Here")))
	(when shipzones
	  (cl-who:str (display-as-tiles shipzones 'zonezipcodesdisplayfunc "product-card" )))
	 	
	;; Zone 
	(:script "function enableratetableshipping() {
    const tablerateshipenabled = document.getElementById('tablerateshipenabled');
    if( tablerateshipenabled.checked ){
	$('#ratetablecsvuploadctrl').show();
        tablerateshipenabled.value = \"Y\";
    }else
    {
       $('#ratetablecsvuploadctrl').hide();
       tablerateshipenabled.value = \"N\";
    }
}")))))

(defun zonezipcodesdisplayfunc (shipzone)
  (cl-who:with-html-output (*standard-output* nil)
    (:b (:div  :height "10px" (cl-who:str (slot-value shipzone 'zonename))))
    (:div :height "10px"  (cl-who:str (slot-value shipzone 'zipcoderangecsv)))))



(defun dod-controller-vendor-upload-shipping-ratetable-action ()
  (let* ((ratetablecsvfileparams (hunchentoot:post-parameter "ratetablecsv"))
	 (zonepincodescsvfileparams (hunchentoot:post-parameter "zonepincodescsv"))
	 (tablerateshipenabled (hunchentoot:parameter "tablerateshipenabled"))
	 (ratetablecsvcontents (if ratetablecsvfileparams (hhub-read-file (nth 0 ratetablecsvfileparams))))
	 (zonepincodescsvcontents (if zonepincodescsvfileparams (hhub-read-file (nth 0 zonepincodescsvfileparams))))
	 (zonepincodeslst (if zonepincodescsvcontents (cl-csv:read-csv zonepincodescsvcontents :skip-first-p T)))
	 (vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (shippingmethod (get-shipping-method-for-vendor vendor company))
	 (shipzones (get-ship-zones-for-vendor vendor company)))

    ;; save the rate table csv in the shipping method table

    (if ratetablecsvcontents (setf (slot-value shippingmethod 'ratetablecsv) ratetablecsvcontents))
    (setf (slot-value shippingmethod 'tablerateshipenabled) tablerateshipenabled)
    (update-shipping-methods shippingmethod)
    ;; save the ship zones pincodes in the ship zones table
    (unless shipzones
      (mapcar (lambda (zoneinfo)
		(let ((zonename (car zoneinfo))
		      (pincodescsv (format nil "~A" (cdr zoneinfo))))
		  (create-vendor-ship-zone zonename pincodescsv vendor company))) zonepincodeslst))
    (when shipzones
      (mapcar (lambda (shipzone zoneinfo)
		(let ((zonename (car zoneinfo))
		      (pincodescsv (cdr zoneinfo)))
		  (setf (slot-value shipzone 'zipcoderangecsv) (format nil "~A" pincodescsv))
		  (setf (slot-value shipzone 'zonename) zonename)
		  (update-vendor-shipzone shipzone))) shipzones zonepincodeslst))
    (hunchentoot:redirect "/hhub/hhubvendshipzoneratetablepage")))
   

(defun dod-controller-vendor-update-default-shipping-method ()
  (let* ((storepickupenabled (hunchentoot:parameter "storepickupenabled"))
	 (vendorshipenabled (hunchentoot:parameter "vendorshipenabled"))
	 (defaultshippingmethod (hunchentoot:parameter "defaultshippingmethod"))
	 (vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (shippingmethod (get-shipping-method-for-vendor vendor company)))

    (setf (slot-value shippingmethod 'defaultshippingmethod) defaultshippingmethod)
    (if storepickupenabled
	(setf (slot-value shippingmethod 'storepickupenabled) storepickupenabled)
	;;else
	(setf (slot-value shippingmethod 'storepickupenabled) "N"))
    (if vendorshipenabled
	(setf (slot-value vendor 'shipping-enabled) vendorshipenabled)
	;;else
	(setf (slot-value vendor 'shipping-enabled) "N"))
    (when (equal defaultshippingmethod "FSH")
      (setf (slot-value shippingmethod 'freeshipenabled) "Y")
      (setf (slot-value shippingmethod 'flatrateshipenabled) "N")
      (setf (slot-value shippingmethod 'tablerateshipenabled) "N")
      (setf (slot-value shippingmethod 'extshipenabled) "N"))
          
    (when (equal defaultshippingmethod "FRS")
      (setf (slot-value shippingmethod 'flatrateshipenabled) "Y")
      (setf (slot-value shippingmethod 'tablerateshipenabled) "N")
      (setf (slot-value shippingmethod 'extshipenabled) "N"))
    
    (when (equal defaultshippingmethod "TRS")
      (setf (slot-value shippingmethod 'tablerateshipenabled) "Y")
      (setf (slot-value shippingmethod 'flatrateshipenabled) "N")
      (setf (slot-value shippingmethod 'extshipenabled) "N"))
    
    (when (equal defaultshippingmethod "EXS")
      (setf (slot-value shippingmethod 'extshipenabled) "Y")
      (setf (slot-value shippingmethod 'flatrateshipenabled) "N")
      (setf (slot-value shippingmethod 'tablerateshipenabled) "N"))
        
    (update-vendor-details vendor)
    (update-shipping-methods shippingmethod)
    (hunchentoot:redirect "/hhub/hhubvendorshipmethods")))
    


(defun modal.vendor-default-shipping-method-config (shippingmethod vendor)
  (let ((storepickupenabled (slot-value shippingmethod 'storepickupenabled))
	(defaultshippingmethod (slot-value shippingmethod 'defaultshippingmethod))
	(vendorshipenabled (slot-value vendor 'shipping-enabled))
	(shippingmethods-ht (make-hash-table :test 'equal)))
    
    (setf (gethash "FSH" shippingmethods-ht) "FREE Shipping")
    (setf (gethash "FRS" shippingmethods-ht) "Flat Rate Shipping")
    (setf (gethash "TRS" shippingmethods-ht) "Zonewise Shipping")
    (setf (gethash "EXS" shippingmethods-ht) "External Shipping Partners")
    
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(with-html-form "form-vendordefaultshippingmethod" "hhubvendupdatedefaultshipmethod" 
		  (:div :class "form-check"
			(if (equal storepickupenabled "Y")
			    (cl-who:htm
			     (:input :type "checkbox" :id "storepickupenabled" :name "storepickupenabled" :value "Y" :onclick (parenscript:ps (enablestorepickupmethod)) :tabindex "1"  :checked "true"))
			    ;; else
			    (cl-who:htm
			     (:input :type "checkbox" :id "storepickupenabled" :name "storepickupenabled" :value "N" :onclick (parenscript:ps (enablestorepickupmethod)) :tabindex "1" )))
			(:label :class "form-check-label" :for "freeshipenabled" "&nbsp;&nbsp;Enable Store Pickup"))
		  (:div :class "form-check"
			(if (equal vendorshipenabled "Y")
			    (cl-who:htm
			     (:input :type "checkbox" :id "vendorshipenabled" :name "vendorshipenabled" :value "Y" :onclick (parenscript:ps (enablevendorshipping)) :tabindex "2" :checked "true"))
			    ;; else
			    (cl-who:htm
			     (:input :type "checkbox" :id "vendorshipenabled" :name "vendorshipenabled" :value "N" :onclick (parenscript:ps (enablevendorshipping)) :tabindex "2" )))
			(:label :class "form-check-label" :for "vendorshipenabled" "&nbsp;&nbsp;Enable Shipping"))

		  (:br)
		  (:div :id "vendorshipenabledctrl" :class "form-group"
			(:label :class "form-check-label" :for "vendorshipenabled" "&nbsp;&nbsp;Select Default Shipping Method")
			(with-html-dropdown "defaultshippingmethod" shippingmethods-ht defaultshippingmethod))
			
			(:div :class "form-group"
			      (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))))
  


(defun modal.vendor-external-shipping-partners-config (shippartnerkey shippartnersecret extshipenabled)
  (cl-who:with-html-output (*standard-output* nil)                                                                                                                                                                
    (:div :class "row"
          (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(:p (cl-who:str (format nil "We have partnered with ~A for our shipping needs. Please enter your API key and secret here." *HHUBSHIPPINGPARTNERSITE*)))
		
		(with-html-form "form-vendorshippartnerupdate" "hhubvendupdateshippartneraction"

		  (:div :class "form-check"
			(if (equal extshipenabled "Y")
			    (cl-who:htm
			     (:input :type "checkbox" :id "extshipenabled" :name "extshipenabled" :value "Y" :onclick (parenscript:ps (enableextshipmethod)) :tabindex "1"  :checked "true"))
			    ;; else
			    (cl-who:htm
			     (:input :type "checkbox" :id "extshipenabled" :name "extshipenabled" :value "Y" :onclick (parenscript:ps (enableextshipmethod)) :tabindex "1")))
			(:label :class "form-check-label" :for "freeshipenabled" "&nbsp;&nbsp;Enable External Shipping"))
		  
		  (:div :class "form-group"
			(:input :class "form-control" :name "shippartnerkey" :value shippartnerkey :placeholder "Shipping Partner API Key" :type "text"))
		  (:div :class "form-group"                                                                  
			(:input :class "form-control" :name "shippartnersecret" :value shippartnersecret :placeholder "Shipping Partner API Secret" :type "text"))
		  (:div :class "form-group"
			(:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save")))))))

(defun dod-controller-vendor-update-external-shipping-partner-action ()
  (let* ((vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (shippingmethod (get-shipping-method-for-vendor vendor company))
	 (extshipenabled (hunchentoot:parameter "extshipenabled"))
	 (shippartnerkey (hunchentoot:parameter "shippartnerkey"))
	 (shippartnersecret (hunchentoot:parameter "shippartnersecret")))

    (setf (slot-value shippingmethod 'shippartnerkey) shippartnerkey)
    (setf (slot-value shippingmethod 'shippartnersecret) shippartnersecret)
    (setf (slot-value shippingmethod 'extshipenabled) extshipenabled)
    (update-shipping-methods shippingmethod)
    (hunchentoot:redirect "/hhub/hhubvendorshipmethods")))

	 
    


(defun modal.vendor-flatrate-shipping-config (flatrateshipenabled flatratetype flatrateprice)
  (let ((flatratetypedropdown-ht (make-hash-table :test 'equal)))
    (setf (gethash "ORD" flatratetypedropdown-ht) "Entire Order")
    (setf (gethash "ITM" flatratetypedropdown-ht) "Each Order Item")
    
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (with-html-form "form-vendorflatrateshippingmethod" "hhubvendupdatflatrateshipmethodaction" 
		  (:div :class "form-check"
			(if (equal flatrateshipenabled "Y")
			    (cl-who:htm (:input :type "checkbox" :id "flatrateshipenabled" :name "flatrateshipenabled" :value "Y" :onclick (parenscript:ps (enableflatrateshipping)) :tabindex "1"  :checked "true"))
			    ;; else
			    (cl-who:htm (:input :type "checkbox" :id "flatrateshipenabled" :name "flatrateshipenabled" :value "Y" :onclick (parenscript:ps (enableflatrateshipping)) :tabindex "1")))
			(:label :class "form-check-label" :for "flatrateshipenabled" "&nbsp;&nbsp;Enable Flatrate Shipping")
			(:div :id "flatrateshippingctrl" :class "form-group"
			      (:label :for "flatratetype" "Flat Rate Applicable On")
			      (with-html-dropdown "flatratetype" flatratetypedropdown-ht flatratetype)
			      (:label :for "flatrateprice" "Flat Rate Price")
			      (:input :class "form-control" :name "flatrateprice" :value flatrateprice :placeholder "Flat Rate Price" :type "text"))
			(:div :class "form-group"
			      (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save")))))))))


(defun dod-controller-vendor-update-flatrate-shipping-action ()
  (let* ((vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (shippingmethod (get-shipping-method-for-vendor vendor company))
	 (flatrateshipenabled (hunchentoot:parameter "flatrateshipenabled"))
	 (flatratetype (hunchentoot:parameter "flatratetype"))
	 (flatrateprice (float (with-input-from-string (in (hunchentoot:parameter "flatrateprice"))
			(read in))))) 

    ;; save the rate table csv in the shipping method table
    (if flatrateshipenabled
	(setf (slot-value shippingmethod 'flatrateshipenabled) "Y")
	;;else
	(setf (slot-value shippingmethod 'flatrateshipenabled) "N"))
    (setf (slot-value shippingmethod 'flatratetype) flatratetype)
    (setf (slot-value shippingmethod 'flatrateprice) flatrateprice)
    (update-shipping-methods shippingmethod)
    (hunchentoot:redirect "/hhub/hhubvendorshipmethods")))


(defun modal.vendor-free-shipping-config (freeshipenabled minorderamt)
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row" 
	  (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		(:p (:b "Note: Free shipping will be always applicable over and above all other shipping methods when enabled."))
		(with-html-form "form-vendorfreeshippingmethod" "hhubvendupdatfreeshipmethodaction" 
		  (:div :class "form-check"
			(if (equal freeshipenabled "Y")
			    (cl-who:htm (:input :type "checkbox" :id "freeshipenabled" :name "freeshipenabled" :value "Y" :onclick (parenscript:ps (enableminorderamt)) :tabindex "1"  :checked "true"))
			    ;; else
			    (cl-who:htm
			     (:input :type "checkbox" :id "freeshipenabled" :name "freeshipenabled" :value "N" :onclick (parenscript:ps (enableminorderamt)) :tabindex "1")))
			(:label :class "form-check-label" :for "freeshipenabled" "&nbsp;&nbsp;Enable Free Shipping")
			(:div :id "minorderamtctrl" :class "form-group"
			      (:label :for "minorderamt" "Minimum Order Amount For Free Shipping")
			      (:input :class "form-control" :name "minorderamt" :value minorderamt :placeholder "Minimum Order Amount For Free Shipping" :type "text"))
			(:div :class "form-group"
			      (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Save"))))))))

(defun dod-controller-vendor-update-free-shipping-method-action ()
  (with-vend-session-check 
    (let* ((vendor (get-login-vendor))
	   (company (get-login-vendor-company))
	   (shippingmethod (get-shipping-method-for-vendor vendor company))
	   (freeshipenabled (hunchentoot:parameter "freeshipenabled"))
	   (minorderamt (float (with-input-from-string (in (hunchentoot:parameter "minorderamt"))
			(read in)))))  
      (setf (slot-value shippingmethod 'minorderamt) minorderamt)
      (if freeshipenabled 
	  (setf (slot-value shippingmethod 'freeshipenabled) freeshipenabled)
	  ;;else
	  (setf (slot-value shippingmethod 'freeshipenabled) "N"))
      (update-shipping-methods shippingmethod)
      (hunchentoot:redirect "/hhub/hhubvendorshipmethods"))))

    


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro with-vendor-navigation-bar ()
    :documentation "This macro returns the html text for generating a navigation bar using bootstrap."
    `(cl-who:with-html-output (*standard-output* nil)
       (:div :class "navbar  navbar-inverse navbar-static-top"
	     (:div :class "container-fluid"
		   (:div :class "navbar-header"
			 (:button :type "button" :class "navbar-toggle" :data-bs-toggle "collapse" :data-bs-target "#navheadercollapse"
				  (:span :class "icon-bar")
				  (:span :class "icon-bar")
				  (:span :class "icon-bar"))
			 (:a :class "navbar-brand" :href "#" :title "Nine Stores" (:img :style "width: 50px; height: 50px;" :src "/img/logo.png" )))
		   ;;  (:a :class "navbar-brand" :onclick "window.history.back();"  :href "#"  (:span :class "glyphicon glyphicon-arrow-left"))
		   (:div :class "collapse navbar-collapse" :id "navheadercollapse"
			 (:ul :class "nav navbar-nav navbar-left"
			      (:li :class "active" :align "center" (:a :href "dodvendindex?context=home"  (:i :class "fa-solid fa-house-user")  "Home"))
			      (:li :align "center" (:a :href "dodvenproducts"  "My Products"))
			      (:li :align "center" (:a :href "dodvendindex?context=completedorders"  "Completed Orders"))
			      (:li :align "center" (:a :href "#" (print-vendor-web-session-timeout)))
			      (:li :align "center" (:a :href "#" (cl-who:str (format nil "Group: ~A" (get-login-vendor-company-name))))))
			 (:ul :class "nav navbar-nav navbar-right"
			      (:li :align "center" (:a :href "dodvendprofile?context=home"   (:i :class "fa-regular fa-user") "&nbsp;&nbsp;" )) 
				(:li :align "center" (:a :target "_blank" :href "https://goo.gl/forms/XaZdzF30Z6K43gQm2"  (:i :class "fa-regular fa-envelope") "&nbsp;&nbsp;"))
				(:li :align "center" (:a :target "_blank" :href "https://goo.gl/forms/SGizZXYwXDUiTgVY2"  (:i :class "fa-solid fa-bug")))
				(:li :align "center" (:a :href "dodvendlogout"  (:i :class "fa fa-sign-out" :aria-hidden "true") "&nbsp;&nbsp;")))))))))
  
  

(defun dod-controller-vend-login ()
  (let  ((phone (hunchentoot:parameter "phone"))
	 (password (hunchentoot:parameter "password")))
    (unless (and  ( or (null phone) (zerop (length phone)))
		  (or (null password) (zerop (length password))))
      (if (equal (dod-vend-login :phone  phone :password  password) NIL) 
	  (hunchentoot:redirect "/hhub/vendor-login.html")
	  ;else
	  (hunchentoot:redirect "/hhub/dodvendindex?context=home")))))


(defun dod-controller-vend-login-otpstep ()
  (let* ((phone  (hunchentoot:parameter "phone"))
	 (context (format nil "hhubvendloginwithotp?phone=~A" phone)))
      (hunchentoot:start-session)
      ;; Redirect to the OTP page 
      (generateotp&redirect phone context)))

(defun dod-controller-vend-login-with-otp ()
  (let  ((phone (hunchentoot:parameter "phone")))
    (unless ( or (null phone) (zerop (length phone)))
      (unless (dod-vend-login-with-otp :phone phone)
	(hunchentoot:redirect "/hhub/hhubvendloginv2"))
      (hunchentoot:redirect "/hhub/dodvendindex?context=home"))))
      

(defun dod-vend-login-with-otp (&key phone)
  (handler-case
      (let* ((dbvendor (car (clsql:select 'dod-vend-profile :where [and
					  [= [:phone] phone]
					  [= [:approved-flag] "Y"]
					  [= [:approval-status] "APPROVED"]
					  [= [:deleted-state] "N"]]
				   :caching nil :flatp t)))
	     (vendor-company (if dbvendor  (get-vendor-company dbvendor))))
	(when (and  dbvendor
		    (null (hunchentoot:session-value :login-vendor-name))) ;; vendor should not be logged-in in the first place.
	  (set-vendor-session-params  vendor-company dbvendor)))
	;; Lets work on the domain objects here.
	;; (setup-domain-vendor *HHUBBUSINESSSERVER* phone))))
	;;handle the exception. 
    (clsql:sql-database-data-error (condition)
      (if (equal (clsql:sql-error-error-id condition) 2006 ) 
	  (progn
	    (stop-das) 
	    (start-das)
	    (hunchentoot:redirect "/hhub/hhubvendloginv2"))))))
      
(defun dod-vend-login (&key phone password )
  (handler-case
      (let* ((dbvendor (car (clsql:select 'dod-vend-profile :where [and
					  [= [slot-value 'dod-vend-profile 'phone] phone]
					  [= [:approved-flag] "Y"]
					  [= [:approval-status] "APPROVED"]
					  [= [:deleted-state] "N"]]
				   :caching nil :flatp t)))
	     (pwd (if dbvendor (slot-value dbvendor 'password)))
	     (salt (if dbvendor (slot-value dbvendor 'salt)))
	     (password-verified (if dbvendor  (check-password password salt pwd)))
	     (vendor-company (if dbvendor  (get-vendor-company dbvendor))))
					;(log (if password-verified (hunchentoot:log-message* :info (format nil  "phone : ~A password : ~A" phone password)))))
	(when (and dbvendor
		   password-verified
		   (null (hunchentoot:session-value :login-vendor-name))) ;; vendor should not be logged-in in the first place.
	  (set-vendor-session-params  vendor-company dbvendor)))
    ;; handle the exception
    (clsql:sql-database-data-error (condition)
      (if (equal (clsql:sql-error-error-id condition) 2006 ) 
	  (progn
	    (stop-das) 
	    (start-das)
	    (hunchentoot:redirect "/hhub/hhubvendloginv2"))))))

(defun dod-controller-vendor-switch-tenant ()
  (with-vend-session-check
    (let* ((company (select-company-by-id (hunchentoot:parameter "id")))
	   (vendor (get-login-vendor)))
      (progn
	(set-vendor-session-params company vendor)
	(hunchentoot:redirect "/hhub/dodvendindex?context=home")))))




(defun set-vendor-session-params (company  vendor)
  ;; Add the vendor object and the tenant to the Business Session 
  ;;set vendor company related params
  
  (let ((vsessionobj (make-instance 'VendorSessionObject)))
    (setf (slot-value vsessionobj 'vwebsession) (hunchentoot:start-session))
    (setf hunchentoot:*session-max-time* (* 3600 8))
    (setf (hunchentoot:session-value :login-vendor ) vendor)
    (setf (slot-value vsessionobj 'vendor) vendor)
    (setf (hunchentoot:session-value :login-vendor-name) (slot-value vendor 'name))
    (setf (slot-value vsessionobj 'vendor-name) (slot-value vendor 'name))
    (setf (hunchentoot:session-value :login-vendor-id) (slot-value vendor 'row-id))
    (setf (slot-value vsessionobj 'vendor-id) (slot-value vendor 'row-id))
    (setf (hunchentoot:session-value :login-vendor-tenant-id) (slot-value company 'row-id ))
    (setf (slot-value vsessionobj 'vendor-tenant-id) (slot-value company 'row-id))
    (setf (hunchentoot:session-value :login-vendor-company-name) (slot-value company 'name))
    (setf (slot-value vsessionobj 'companyname) (slot-value company 'name))
    (setf (hunchentoot:session-value :login-vendor-company) company)
    (setf (hunchentoot:session-value :login-vendor-currency) (get-account-currency company))
    (setf (hunchentoot:session-value :login-vendor-invoice-settings) (read-from-string (slot-value vendor 'invoice-settings)))
    ;;(setf (hunchentoot:session-value :login-prd-cache )  (select-products-by-company company))
    ;;set vendor related params 
    (if vendor (setf (hunchentoot:session-value :login-vendor-tenants) (get-vendor-tenants-as-companies vendor)))
    (if vendor (setf (hunchentoot:session-value :order-func-list) (dod-gen-order-functions vendor company)))
    (if vendor (setf (hunchentoot:session-value :vendor-order-items-hashtable) (make-hash-table)))
    (if vendor (setf (hunchentoot:session-value :login-vendor-products-functions) (dod-gen-vendor-products-functions vendor company)))
    (if vendor (setf (hunchentoot:session-value :login-vendor-settings-ht) (make-hash-table :test 'equal)))
    (if vendor (setf (hunchentoot:session-value :login-prd-cache )  (remove nil (select-products-by-vendor vendor  company))))
    (if vendor (setf (hunchentoot:session-value :session-invoices-ht) (make-hash-table :test 'equal)))
    (if vendor (setf (hunchentoot:session-value :login-shopping-cart) '()))
    ;; Add vendor settings to the session. 
    (addloginvendorsettings)
    (let* ((bcontext (getBusinessContext *HHUBBUSINESSSERVER* "vendorsite"))
	   (sessionkey (createBusinessSession bcontext vsessionobj)))
      (setf (hunchentoot:session-value :login-vendor-business-session-id) sessionkey)
      (logiamhere (format nil "current web session is ~A" (slot-value vsessionobj 'vwebsession)))
      (logiamhere (format nil "current session key is ~A" sessionkey))
      (enforcevendorsession sessionkey bcontext  *HHUBMAXVENDORLOGINS*)
      (logiamhere (format nil "after enforcing sessions current web session is ~A" (slot-value vsessionobj 'vwebsession)))
      sessionkey)))


(defun get-vendor-invoice-settings ()
  (let ((vinvsettingstr (hunchentoot:session-value :login-vendor-invoice-settings))
	(defaultinvsettings *invoice-settings*))
    (if (and vinvsettingstr (> (length vinvsettingstr) 0)) 
	;; if invoice settings are defined for a vendor, return it. 
	(read-from-string vinvsettingstr)
	;;else return the default invoice settings.
	defaultinvsettings)))


(defun addloginvendorsettings ()
  (let* ((company (get-login-vendor-company))
	 (vendor (get-login-vendor))
	 (adapter (make-instance 'VPaymentMethodsAdapter))
	 (requestmodel (make-instance 'VPaymentMethodsRequestModel
				      :company company
				      :vendor vendor))
	(vpaymentmethods (processreadrequest adapter requestmodel)))
    (when vpaymentmethods 
      (with-slots (codenabled upienabled payprovidersenabled walletenabled paylaterenabled) vpaymentmethods
	(addloginvendorsetting "codenabled" codenabled)
	(addloginvendorsetting "upienabled" upienabled)
	(addloginvendorsetting "payprovidersenabled" payprovidersenabled)
	(addloginvendorsetting "walletenabled" walletenabled)
	(addloginvendorsetting "paylaterenabled" paylaterenabled)))))
  


(defun addloginvendorsetting (key value)
  (setf (gethash key (hunchentoot:session-value :login-vendor-settings-ht)) value))


(defun getloginvendorcount ()
  (let* ((bcontext (getBusinessContext *HHUBBUSINESSSERVER* "vendorsite"))
	 (bsessions-ht (businesssessions-ht bcontext)))
    (hash-table-count bsessions-ht)))

(defun getloginvendorsessionstarttime ()
  (let* ((bcontext (getBusinessContext *HHUBBUSINESSSERVER* "vendorsite"))
	 (sessionkey (hunchentoot:session-value :login-vendor-business-session-id))
	 (bsession (when sessionkey (getbusinesssession bcontext sessionkey)))
	 (start-time (if (and hunchentoot:*session* (eql bsession hunchentoot:*session*)) (start-time bsession) 0)))
    start-time))



(defun resetvendorsessions (sessionkey)
  (let* ((bcontext (getBusinessContext *HHUBBUSINESSSERVER* "vendorsite"))
	 (bsessions-ht (businesssessions-ht bcontext))
	 (bvendorsession (gethash sessionkey bsessions-ht))
	 (vendorwebsession (slot-value bvendorsession 'vwebsession)))
    (if vendorwebsession (hunchentoot:remove-session vendorwebsession))  
    (deleteBusinessSession bcontext sessionkey)))

(defun enforcevendorsession (sessionkey bcontext maxvendorsallowed)
  (let* ((bsessions-ht (businesssessions-ht bcontext))
	 (bvendorsession (gethash sessionkey bsessions-ht))
	 (currentwebsession (slot-value bvendorsession 'vwebsession))
	 (vendor (slot-value bvendorsession 'vendor))
	 (sessionlist '())
	 (keylist '()))
    (maphash (lambda (k v)
	       (let ((prevvendorid (slot-value v 'vendor-id))
		     (prevwebsession (slot-value v 'vwebsession))
		     (loginvendorid (slot-value vendor 'row-id))
		     (vendorname (slot-value vendor 'name)))
		 (when (and
			(not (equal k sessionkey)) ;; There are 2 separate sessions from same user. 
			(= prevvendorid loginvendorid)) ;; Same user is login again.
		   (logiamhere (format nil "Vendor is ~A. key is ~A. Websession is ~A" vendorname k prevwebsession))
		   (setf sessionlist (append sessionlist (list v)))
		   (setf keylist (append keylist (list k)))))) bsessions-ht)
    ;; If there are exactly 1 item in the list that means that user has logged in previouly. 
    (when (>= (length sessionlist) maxvendorsallowed)
      (let* ((sessiontoremove (nth 0 sessionlist))
	     (websession (slot-value sessiontoremove 'vwebsession))
	     (firstkey (nth 0 keylist)))
	(logiamhere (format nil "logging off vendor websession ~A" websession))
	(hunchentoot:remove-session websession)
	(deleteBusinessSession bcontext firstkey)))
    (logiamhere (format nil "After logging off current session is ~A" currentwebsession))))

   
(defun dod-controller-vendor-delete-product () 
 (if (is-dod-vend-session-valid?)
  (let ((id (hunchentoot:parameter "id")))
    (if (= (length (get-pending-order-items-for-vendor-by-product (select-product-by-id id (get-login-vendor-company)) (get-login-vendor))) 0)
	(progn 
	  (delete-product id (get-login-vendor-company))
	  (setf (hunchentoot:session-value :login-vendor-products-functions) (dod-gen-vendor-products-functions (get-login-vendor) (get-login-vendor-company)))))   
    (hunchentoot:redirect "/hhub/dodvenproducts"))
     	(hunchentoot:redirect "/hhub/hhubvendloginv2"))) 

(defun createmodelforprddetailsforvendor ()
  (let* ((prd-id (parse-integer (hunchentoot:parameter "id")))
	 (productlist (if (> prd-id 0) (hhub-get-cached-vendor-products)))
	 (product (if (> prd-id 0) (search-item-in-list 'row-id prd-id productlist)))
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
	 (proddetailpagetempl (funcall (nst-get-cached-product-template-func :templatenum 2)))	 
	 (unit-of-measure (slot-value product 'unit-of-measure))
	 (qtyperunit-str (format nil "~A" (slot-value product 'qty-per-unit)))
	 (unitsinstock-str (format nil "~A" (slot-value product 'units-in-stock))))
	 
	 
    
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product Name%" proddetailpagetempl prd-name))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Unit-Of-Measure%" proddetailpagetempl unit-of-measure))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Qty-Per-Unit%" proddetailpagetempl qtyperunit-str))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-SKU%" proddetailpagetempl product-sku))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Description%" proddetailpagetempl description))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Units-In-Stock%" proddetailpagetempl unitsinstock-str))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Pricing-Control%" proddetailpagetempl product-pricing-widget))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Images-Carousel%" proddetailpagetempl product-images-carousel))
    (setf proddetailpagetempl (cl-ppcre:regex-replace-all "%Product-Images-Thumbnails%" proddetailpagetempl product-images-thumbnails))
    
    (function (lambda ()
      (values proddetailpagetempl  product )))))
  
(defun createwidgetsforprddetailsforvendor (modelfunc)
  (multiple-value-bind (proddetailpagetempl product) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (with-catch-submit-event "idproductdetailsforvendor" 
			 ;; display the product actions menu
			 (vendor-product-actions-menu product))))))
	  (widget2  (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(cl-who:str proddetailpagetempl))))))
      (list widget1  widget2))))

(defun dod-controller-prd-details-for-vendor ()
  (with-cust-session-check 
    (with-mvc-ui-page "Product Details for Vendor" createmodelforprddetailsforvendor  createwidgetsforprddetailsforvendor :role :vendor)))
		
(defun dod-controller-vendor-deactivate-product ()
  (with-vend-session-check 
    (let ((id (parse-integer (hunchentoot:parameter "id"))))
      (deactivate-product id (get-login-vendor-company))
      (setf (hunchentoot:session-value :login-vendor-products-functions) (dod-gen-vendor-products-functions (get-login-vendor) (get-login-vendor-company)))   
      (hunchentoot:redirect "/hhub/dodvenproducts"))))

(defun dod-controller-vendor-activate-product ()
  (with-vend-session-check
    (let ((id (hunchentoot:parameter "id")))
      (activate-product id (get-login-vendor-company))
      (setf (hunchentoot:session-value :login-vendor-products-functions) (dod-gen-vendor-products-functions (get-login-vendor) (get-login-vendor-company)))   
      (hunchentoot:redirect "/hhub/dodvenproducts"))))

(defun dod-controller-vendor-copy-product ()
) 


(defun dod-controller-vendor-search-products ()
  (with-vend-session-check
    (let* ((search-clause (hunchentoot:parameter "txtvendsearchproduct"))
	   (products (if (not (equal "" search-clause)) (search-products search-clause (get-login-vendor-company)))))
      (cl-who:with-html-output-to-string (*standard-output* nil)
	(:div :id "txtvendsearchproductresult" 
	      (cl-who:str (display-as-tiles products  'product-card-for-vendor "vendor-product-card")))))))
  
(defun dod-controller-vendor-product-categories-page ()
  (with-vend-session-check
    (let* ((company (get-login-vendor-company))
	   (categories (select-prdcatg-by-company company))
	   (catgcount (length categories)))
      (with-standard-vendor-page "Product Categories"
	(with-html-div-row :align "right"
	  (:span :class "badge" (cl-who:str (format nil " ~d " catgcount))))
	(:hr)
	(cl-who:str (display-as-table (list "Name") categories 'vendor-product-category-row))
	(:hr)
	(with-html-div-row
	  (:h4 "Note: Contact Administrator to create/delete the Product Categories."))
	;; We will write some javascript to give a success alert here. 
	(jscript-displaysuccess "Note: Contact Administrator to create/delete the Product Categories.")))))


	
(defun vendor-product-category-row (category &rest arguments)
  (declare (ignore arguments))
  (with-slots (row-id catg-name) category 
      (cl-who:with-html-output (*standard-output* nil)
	(:td  :height "10px" (cl-who:str catg-name)))))


(defun dod-controller-vendor-products ()
  (with-vend-session-check
    (with-mvc-ui-page "Vendor Products" createmodelforshowvendorproducts createwidgetsforshowvendorproducts :role :vendor)))

(defun createmodelforshowvendorproducts ()
  (let* ((vendor-products (hhub-get-cached-vendor-products))
	 (vendor-company (get-login-vendor-company))
	 (cmp-type (slot-value vendor-company 'cmp-type))
	 (subscription-plan (slot-value vendor-company 'subscription-plan))
	 (numproducts (length vendor-products))
	 (compbulkupload-p (com-hhub-attribute-company-prdbulkupload-enabled subscription-plan cmp-type)))
    (function (lambda ()
      (values vendor-products numproducts compbulkupload-p)))))
	
(defun createwidgetsforshowvendorproducts (modelfunc)
  (multiple-value-bind (vendor-products   numproducts compbulkupload-p) (funcall modelfunc)
  (let ((widget1 (function (lambda ()
		   (cl-who:with-html-output (*standard-output* nil)    
		     (:br)
		     (with-html-div-row
		       (with-html-div-col-4
			 (with-html-search-form "idvendsearchproduct" "vendsearchproduct" "idtxtvendsearchproduct" "txtvendsearchproduct" "hhubvendsearchproduct" "onkeyupsearchform1event();" "Type few letters of Product Name"
			   (submitsearchform1event-js "#idtxtvendsearchproduct" "#txtvendsearchproductresult")))
		       (with-html-div-col-4 
			 (:span :class "position-absolute top-50 start-50 translate-middle badge rounded-pill bg-danger" (:h5 (cl-who:str (format nil "~A" numproducts)))))
		       (when compbulkupload-p
			 (cl-who:htm
			  (with-html-div-col-4
			    (:a :class "btn btn-primary" :role "button" :href "dodvenbulkaddprodpage" (:i :class "fa-solid fa-cart-shopping") " Bulk Add Products ")))))))))
	(widget2 (function (lambda ()
		   (cl-who:with-html-output (*standard-output* nil)    
		     (:hr)
		     (with-catch-submit-event "txtvendsearchproductresult"
		       (cl-who:str (display-as-tiles vendor-products  'product-card-for-vendor "vendor-product-card"))))))))
    (list widget1 widget2 ))))

(defun dod-gen-vendor-products-functions (vendor company)
  (let ((vendor-products (select-products-by-vendor vendor company))
	(product-categories (select-prdcatg-by-company company))
	(active-vendor-products (select-active-products-by-vendor vendor company))
	(company-products (select-products-by-company company)))
    (list (function (lambda () vendor-products))
	  (function (lambda () product-categories))
	  (function (lambda () active-vendor-products))
	  (function (lambda () company-products)))))

(defun dod-gen-order-functions (vendor company)
(let ((pending-orders (get-orders-for-vendor vendor 500 company ))
      (completed-orders (get-orders-for-vendor vendor 500 company  "Y" ))
      (order-items (get-order-items-for-vendor  vendor  company)) ; Get order items for last 30 days and next 30 days. 
      (completed-orders-today (get-orders-for-vendor-by-shipped-date vendor (get-date-string-mysql (clsql-sys:get-date)) company "Y"))) 

  (list (function (lambda () pending-orders ))
	(function (lambda () completed-orders))
	(function (lambda () order-items))
	(function (lambda () completed-orders-today)))))


(defun dod-reset-vendor-products-functions (vendor company)
  (let ((vendor-products-func-list (dod-gen-vendor-products-functions vendor company)))
    (setf (hunchentoot:session-value :login-vendor-products-functions) vendor-products-func-list)))

(defun dod-reset-order-functions (vendor company)
  (let ((order-func-list (dod-gen-order-functions vendor company)))
    (setf (hunchentoot:session-value :order-func-list) order-func-list)
    (setf (hunchentoot:session-value :vendor-order-items-hashtable) (make-hash-table))))

(defun hhub-get-cached-vendor-products ()
  (let ((vendor-products-func (first (hunchentoot:session-value :login-vendor-products-functions))))
    (funcall vendor-products-func)))

(defun hhub-get-cached-product-categories ()
  (let ((vendor-products-func (second (hunchentoot:session-value :login-vendor-products-functions))))
    (funcall vendor-products-func)))

(defun hhub-get-cached-active-vendor-products ()
  (let ((vendor-products-func (third (hunchentoot:session-value :login-vendor-products-functions))))
    (funcall vendor-products-func)))

(defun hhub-get-cached-company-products ()
  (let ((vendor-products-func (fourth (hunchentoot:session-value :login-vendor-products-functions))))
    (funcall vendor-products-func)))

(defun dod-get-cached-pending-orders()
  (let ((pending-orders-func (nth 0 (hunchentoot:session-value :order-func-list))))
    (funcall pending-orders-func)))


(defun dod-get-cached-completed-orders ()
  (let ((completed-orders-func (nth 1 (hunchentoot:session-value :order-func-list))))
    (funcall completed-orders-func)))

(defun dod-get-cached-completed-orders-today ()
  (let ((completed-orders-func (nth 3 (hunchentoot:session-value :order-func-list))))
    (funcall completed-orders-func)))

(defun dod-get-cached-order-items-by-order-id (order-id order-func-list)
  ;; Add the order item to a hash table. Key - order-id to improve performance.
  ;; Discovered in May 2020
  ;; If the order-items are not found in the hash table, search them and add them to hash table.                                                                               
  (let ((order-items-from-ht (get-ht-val order-id (hunchentoot:session-value :vendor-order-items-hashtable))))
    (if (null order-items-from-ht) 
	(let* ((order-items-func (nth 2 order-func-list))
               (order-items-list (funcall order-items-func))
	       (order-items (remove nil (mapcar (lambda (item)
						  (if (equal (slot-value item 'order-id) order-id) item)) order-items-list))))
	  (when (> (length order-items) 0)
            ;; save in the order items hashtable for faster access next time.
	    (setf (gethash order-id (hunchentoot:session-value :vendor-order-items-hashtable)) order-items)
	    ;; return order items
	    order-items))
	;;otherwise, return the retrieved items list from the hash table.
        order-items-from-ht)))


(defun dod-get-cached-order-items-by-product-id (prd-id order-func-list)
  ;; Add the order item to a hash table. Key - product-id to improve performance.
  ;; Discovered in Nov 2024
  ;; If the order-items are not found in the hash table, search them and add them to hash table.                                                                               
  (let ((order-items-from-ht (get-ht-val prd-id (hunchentoot:session-value :vendor-order-items-hashtable))))
    (if (null order-items-from-ht) 
	(let* ((order-items-func (nth 2 order-func-list))
               (order-items-list (funcall order-items-func))
	       (order-items (delete nil (mapcar (lambda (item)
						  (if (equal (slot-value item 'prd-id) prd-id) item)) order-items-list))))
	  (when (> (length order-items) 0)
            ;; save in the order items hashtable for faster access next time.
	    (setf (gethash prd-id (hunchentoot:session-value :vendor-order-items-hashtable)) order-items)
	      ;; return order items
	      order-items))
	;;otherwise, return the retrieved items list from the hash table.
        order-items-from-ht)))

(defun dod-controller-vend-index () 
  (with-vend-session-check 
    (let ((dodorders (dod-get-cached-pending-orders ))
	  (reqdate (hunchentoot:parameter "reqdate"))
	  (btnexpexl (hunchentoot:parameter "btnexpexl"))
	  (context (hunchentoot:parameter "context")))
      (with-standard-vendor-page "Welcome Vendor"
	(:h3 "Welcome " (cl-who:str (format nil "~A" (get-login-vendor-name))))
	(:hr)
	(with-html-form "form-venorders" "dodvendindex"
	  (with-html-div-row :style "display: none"
	    (:div :class "btn-group" :role "group" :aria-label "..."
		  (:button  :name "btnpendord" :type "submit" :class "btn btn-default active" "Orders" )
		  (:button  :name "btnordcomp" :type "submit" :class "btn btn-default" "Completed Orders")))
					; (:hr)
	  (with-html-div-row :style "display: none"
	    (:div :class "col-sm-12 col-xs-12 col-md-12 col-lg-12" 
		  (:input :type "text" :name "reqdate" :placeholder "yyyy/mm/dd")
		  (:button :class "btn btn-primary" :type "submit" :name "btnordprd" "Get Orders by Products")
		  (:button :class "btn btn-primary" :type "submit" :name "btnordcus" "Get Orders by Customers")
		  (if (and reqdate dodorders)
		      (cl-who:htm (:a :href (format nil "/dodvenexpexl?reqdate=~A" (cl-who:escape-string reqdate)) :class "btn btn-primary" "Export To Excel")))
		  (:button :class "btn btn-primary"  :type "submit" :name "btnprint" :onclick "javascript:window.print();" "Print")))) 
					; (:hr)
	(cond ((equal context "ctxordprd") (ui-list-vendor-orders-by-products dodorders))
	      ((and dodorders btnexpexl) (hunchentoot:redirect (format nil "/hhub/dodvenexpexl?reqdate=~A" reqdate)))
	      ((equal context "ctxordcus") (ui-list-vendor-orders-by-customers dodorders))
	      ((equal context "home")	(cl-who:htm (:div :class "list-group col-xs-6 col-sm-6 col-md-6 col-lg-6" 
							  (:a :class "list-group-item list-group-item-action" :href "dodvendindex?context=pendingorders" " Orders " (:span :class "badge" (cl-who:str (format nil " ~d " (length dodorders)))))
							  (:a :class "list-group-item list-group-item-action" :href "dodvendindex?context=ctxordprd" "Todays Demand")
							  (:a :class "list-group-item list-group-item-action" :href (cl-who:str (format nil "dodvendrevenue"))  "Today's Revenue")
							  (:a :class "list-group-item list-group-item-action" :href (cl-who:str (format nil "displayinvoices"))  "Sale Invoices"))))
							  
	      
	      ((equal context "pendingorders") 
	       (progn (cl-who:htm (cl-who:str "Pending Orders") (:span :class "badge" (cl-who:str (format nil " ~d " (length dodorders))))
				  (:a :class "btn btn-primary btn-xs" :role "button" :href "dodrefreshpendingorders" (:i :class "fa-solid fa-arrows-rotate"))
				  (:a :class "btn btn-primary btn-xs" :role "button" :href "dodvendindex?context=ctxordcus" "Printer Friendly View")
				  (:a :class "btn btn-primary btn-xs" :role "button" :href "dodvenexpexl?type=pendingorders" "Export To Excel")
				  (:hr))
		      (cl-who:str (display-as-tiles dodorders 'vendor-order-card "order-box"))))
	      ((equal context "completedorders") (let* ((vorders (dod-get-cached-completed-orders))
							(lenorders (length vorders)))
						   (progn
						     (cl-who:htm (cl-who:str (format nil "Completed orders"))
								 (:span :class "badge" (cl-who:str (format nil " ~d " lenorders))) 
								 (when (> lenorders 0) (cl-who:htm (:a :class "btn btn-primary btn-xs" :role "button" :href "dodvenexpexl?type=completedorders" "Export To Excel")))
								 (:hr))
						     (cl-who:str(display-as-tiles vorders 'vendor-order-card "order-box"))))))))))
  


(defun com-hhub-transaction-vendor-order-setfulfilled ()
  (with-vend-session-check
    (with-mvc-redirect-ui createmodelforvendorsetorderfulfilled createwidgetsforgenericredirect)))

(defun createmodelforvendorsetorderfulfilled ()
  (let* ((id (hunchentoot:parameter "id"))
	 (company-instance (hunchentoot:session-value :login-vendor-company))
	 (order-instance (get-order-by-id id company-instance))
	 (payment-mode (slot-value order-instance 'payment-mode))
	 (customer (get-customer order-instance)) 
	 (vendor (get-login-vendor))
	 (wallet (get-cust-wallet-by-vendor customer vendor company-instance))
	 (vendor-order-items (get-order-items-for-vendor-by-order-id  order-instance (get-login-vendor) ))
	 (vorderitemstotal (get-order-items-total-for-vendor vendor  vendor-order-items))
	 (redirecturl "/hhub/dodvendindex?context=pendingorders")
	 (params nil))

	 (setf params (acons "uri" (hunchentoot:request-uri*)  params))
	 (setf params (acons "company" company-instance params))
	 (with-hhub-transaction "com-hhub-transaction-vendor-order-setfulfilled"  params   
	   (progn
	     (if (equal payment-mode "PRE")
		 (unless (check-wallet-balance vorderitemstotal wallet)
		   (display-wallet-for-customer wallet "Not enough balance for the transaction.")))
	     ;; We will make all the database changes in the background. 
	     (set-order-fulfilled "Y" vendor  order-instance company-instance)))
    (function (lambda ()
      (values redirecturl)))))

(defun display-wallet-for-customer (wallet-instance custom-message)
  (with-standard-vendor-page (:title "Wallet Display")
    (wallet-card wallet-instance custom-message)))

(defun dod-controller-ven-expexl ()
    (if (is-dod-vend-session-valid?)
	(let ((type (hunchentoot:parameter "type"))
	      (header (list "Product " "Quantity" "Qty per unit" "Unit Price" "Discount%" "Total Amt"))
	      (today (get-date-string (clsql-sys:get-date))))
	      (setf (hunchentoot:content-type*) "text/csv; charset=UTF-8; BOM")
	      (setf (hunchentoot:header-out "Content-Disposition" ) (format nil "inline; filename=Orders_~A.csv" today))
	      (cond ((equal type "pendingorders") (ui-list-orders-for-excel header (dod-get-cached-pending-orders)))
		    ((equal type "completedorders") (ui-list-orders-for-excel header (dod-get-cached-completed-orders)))))
	(hunchentoot:redirect "/hhub/hhubvendloginv2")))



(defun get-login-vendor ()
    :documentation "Get the login session for vendor"
    (hunchentoot:session-value :login-vendor ))
(defun get-login-vendor-id ()
  :documentation "Get the ID of the login vendor"
  (let ((vendor (get-login-vendor)))
    (slot-value vendor 'row-id)))

(defun get-login-vendor-setting (key)
  :documentation "Gets the login vendor settings"
  (gethash key (hunchentoot:session-value :login-vendor-settings-ht)))

(defun get-login-vend-company ()
    :documentation "Get the login vendor company."
    ( hunchentoot:session-value :login-vendor-company))

(defun get-login-vendor-tenant-id () 
  :documentation "Get the login vendor tenant-id"
  (hunchentoot:session-value :login-vendor-tenant-id))

(defun is-dod-vend-session-valid? ()
    :documentation "Checks whether the current login session is valid or not."
    (if  (null (get-login-vendor-name)) NIL T))

(defun get-login-vendor-name ()
    :documentation "Gets the name of the currently logged in vendor"
    (hunchentoot:session-value :login-vendor-name))


(defun dod-controller-vendor-logout ()
    :documentation "Vendor logout."
    (let* ((vc (get-login-vendor-company))
	   (company-website (if vc (slot-value vc 'website))))
      (when hunchentoot:*session* (hunchentoot:remove-session hunchentoot:*session*))
      (deleteBusinessSession (getBusinessContext *HHUBBUSINESSSERVER* "vendorsite") (hunchentoot:session-value :login-vendor-business-session-id)) 
      
      (if (> (length company-website) 0)  (hunchentoot:redirect (format nil "http://~A" company-website)) 
	  ;;else
	  (hunchentoot:redirect *siteurl*))))




(defun vendor-details-card (vendor-instance)
  (let ((vend-name (slot-value vendor-instance 'name))
	(vend-address  (slot-value vendor-instance 'address))
	(phone (slot-value vendor-instance 'phone))
	(picture-path (slot-value vendor-instance 'picture-path)))
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-div-row
	(with-html-div-col 
	  (:h4 (cl-who:str vend-name))))
      (with-html-div-row
	(with-html-div-col
	  (:h5 (cl-who:str vend-address))))
      (with-html-div-row
	(with-html-div-col
	  (:h4  (cl-who:str phone)))
	(with-html-div-col
	  (:a :target "_blank" :href (createwhatsapplink phone) (:img :src (format nil "/img/~A" *HHUBWHATSAPPBUTTONIMG*) :alt "Chat on WhatsApp" " "))))
      (with-html-div-row
        (:div :class "col-sm-12 col-xs-12 col-md-6 col-lg-6 image-responsive"
	      (:img :src  (format nil "~A" picture-path) :height "300" :width "400" :alt vend-name " "))))))
		  


(defun modal.vendor-order-details (vorder-instance company)
  (let* ((customer (if vorder-instance (get-customer vorder-instance)))
	 (wallet (if customer (get-cust-wallet-by-vendor customer (get-login-vendor) company)))
	 (balance (if wallet (slot-value wallet 'balance) 0))
	 (venorderfulfilled (if vorder-instance (slot-value vorder-instance 'fulfilled)))
	 (mainorder (get-order-by-id (slot-value vorder-instance 'order-id) company))
	 (order-id (if mainorder (slot-value mainorder 'row-id)))
	 (payment-mode (if mainorder (slot-value mainorder 'payment-mode)))
	 (header (list "Product" "Product Qty" "Unit Price"  "Sub-total"))
	 (odtlst (if mainorder (dod-get-cached-order-items-by-order-id (slot-value mainorder 'row-id) (hunchentoot:session-value :order-func-list) )) )
	 (order-amt (slot-value vorder-instance 'order-amt))
	 (shipping-cost (slot-value vorder-instance 'shipping-cost))
	 (storepickupenabled (slot-value vorder-instance 'storepickupenabled))
	 (total (if shipping-cost (+ order-amt shipping-cost) order-amt))
	 (lowwalletbalance (< balance total)))
    
    (cl-who:with-html-output (*standard-output* nil)
      (with-html-div-row
	(:div :class "col" :align "right"
	      (when (and shipping-cost (> shipping-cost 0))
                (cl-who:htm
		 (:p (cl-who:str (format nil "Shipping: ~A ~$" *HTMLRUPEESYMBOL* shipping-cost)))
		 (:p (cl-who:str (format nil "Sub Total: ~A ~$" *HTMLRUPEESYMBOL* order-amt)))))))
      (with-html-div-row 
	(:div :class "col-md-12" :align "right" 
	      (if (and lowwalletbalance (equal payment-mode "PRE")) 
		  (cl-who:htm (:h2 (:span :class "label label-danger" (cl-who:str (format nil "Low wallet Balance = Rs ~$" balance))))))
					;else
	      (:h3 (:span :class "label label-success" (cl-who:str (format nil "Total: ~A ~$" *HTMLRUPEESYMBOL* total))))
	      (if (equal venorderfulfilled "Y") 
		  (cl-who:htm (:span :class "label label-info" "FULFILLED"))
		  ;; ELSE
		  ;; Convert the complete button to a submit button and introduce a form here. 
		  (cl-who:htm
		   (with-html-form "form-vendordercomplete" "dodvenordfulfilled"
		     (:input :type "hidden" :name "id" :value order-id)
		     ;; (:a :onclick "return CancelConfirm();" :href (format nil "dodvenordcancel?id=~A" (slot-value order 'row-id) ) (:span :class "btn btn-primary"  "Cancel")) "&nbsp;&nbsp;"
		     (:div :class "form-group"
			   (if mainorder ;; if the order is present only then show the complete button. 
			       (cl-who:htm (:input :type "submit"  :class "btn btn-primary" :value "Complete")))))))))
      (when (and (equal storepickupenabled "Y") (= shipping-cost 0.00))
	(cl-who:htm
	 (:div :align "right" :class "stampbox-big rotated" "Store Pickup")))
      (if odtlst (ui-list-vend-orderdetails header odtlst) "No order details")
      (if mainorder (display-order-header-for-vendor mainorder))
      (with-html-form "form-vendordercancel" "dodvenordcancel" 
	(with-html-input-text-hidden "id" order-id)
	(:div :class "form-group" :style "display:none"
	      (:input :type "submit"  :class "btn btn-primary" :value "Cancel Order"))))))

(defun dod-controller-vendor-orderdetails ()
  (with-vend-session-check
    (with-mvc-ui-page "Vendor Order Details" createmodelforvendororderdetails createwidgetsforvendororderdetails :role :vendor)))

(defun createmodelforvendororderdetails ()
  (let* ((dodvenorder (get-vendor-orders-by-orderid (hunchentoot:parameter "id") (get-login-vendor) (get-login-vendor-company)))
	 (customer (get-customer dodvenorder))
	 (wallet (get-cust-wallet-by-vendor customer (get-login-vendor) (get-login-vendor-company)))
	 (balance (slot-value wallet 'balance))
	 (venorderfulfilled (if dodvenorder (slot-value dodvenorder 'fulfilled)))
	 (order (get-order-by-id (hunchentoot:parameter "id") (get-login-vendor-company)))
	 (order-id (if order (slot-value order 'row-id)))
	 (payment-mode (slot-value order 'payment-mode))
	 (header (list "Product" "Product Qty" "Unit Price"  "Sub-total"))
	 (odtlst (if order (dod-get-cached-order-items-by-order-id (slot-value order 'row-id) (hunchentoot:session-value :order-func-list)  )) )
	 (total (reduce #'+  (mapcar (lambda (odt)
				       (* (slot-value odt 'current-price) (slot-value odt 'prd-qty))) odtlst)))
	 (lowwalletbalance (< balance total)))
    (function (lambda ()
      (values order order-id header odtlst lowwalletbalance payment-mode balance total venorderfulfilled)))))

(defun createwidgetsforvendororderdetails (modelfunc)
  (multiple-value-bind (order order-id header odtlst lowwalletbalance payment-mode balance total venorderfulfilled) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (if order (display-order-header-for-vendor  order))))))
	  (widget2 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (if odtlst (ui-list-vend-orderdetails header odtlst) "No order details")))))
	  (widget3 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil) 
		       (with-html-div-row 
			 (:div :class "col-md-12" :align "right" 
			       (if (and lowwalletbalance (equal payment-mode "PRE")) 
				   (cl-who:htm (:h2 (:span :class "label label-danger" (cl-who:str (format nil "Low wallet Balance = Rs ~$" balance))))))
			       ;; else
			       (:h2 (:span :class "label label-default" (cl-who:str (format nil "Total = Rs ~$" total))))
			       (if (equal venorderfulfilled "Y") 
				   (cl-who:htm (:span :class "label label-info" "FULFILLED"))
				   ;; ELSE
				   ;; Convert the complete button to a submit button and introduce a form here. 
				   (cl-who:htm 
				    ;; (:a :onclick "return CancelConfirm();" :href (format nil "dodvenordcancel?id=~A" (slot-value order 'row-id) ) (:span :class "btn btn-primary"  "Cancel")) "&nbsp;&nbsp;"
				    (:a :href (format nil "dodvenordfulfilled?id=~A" order-id ) (:span :class "btn btn-primary"  "Complete")))))))))))
      (list widget1 widget2 widget3))))




(defun ui-list-vend-orderdetails (header data)
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class  "panel panel-default"
	    (:div :class "panel-heading" "Order Items")
	    (:div :class "panel-body"
		  (:table :class "table table-hover"  
			  (:thead (:tr
				   (mapcar (lambda (item) (cl-who:htm (:th (cl-who:str item)))) header))) 
			  (:tbody
			   (mapcar (lambda (odt)
				     (let* ((odt-product  (get-odt-product odt))
					    (pricewith-discount (calculate-order-item-cost odt))
					    (prd-qty (slot-value odt 'prd-qty)))
				       (cl-who:htm (:tr (:td  :height "12px" (cl-who:str (slot-value odt-product 'prd-name)))
						 (:td  :height "12px" (cl-who:str (format nil  "~d" prd-qty)))
						 (:td  :height "12px" (cl-who:str (format nil  "Rs. ~$" pricewith-discount)))
						 (:td  :height "12px" (cl-who:str (format nil "Rs. ~$" (* pricewith-discount prd-qty))))
						 )))) (if (not (typep data 'list)) (list data) data))))))))
