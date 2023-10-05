; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)




(defun dod-controller-vendor-pushsubscribe-page ()
  (with-vend-session-check
    (with-standard-vendor-page "Push Subscription for Vendor"
      (:div :class "row"
	    (:h3 "Subscribe to Notifications on your Browser"))
      (:div :class "row"
	    (:p "Note: We send notifications for various events, for example:  when you receive a new order. Push notification will be sent to one browser only. If you would like to subscribe to notifications on a different browser, you need to unsubscribe in current browser and subscribe in other browser"))
      (:div :class "row"
	    (:div :class "col-md-4" 
		  (:button :class "btn btn-lg btn-primary btn-block" :id "btnPushNotifications" :name "btnPushNotifications" "Subscribe")))
      
      (:div :class "row" 
	    (:div :class "col-md-4"
		  (:a :href "dodvendindex?context=home" "Home")))
	
      (:script :src "https://www.highrisehub.com/js/pushsubscribe.js"))))


	    

(defun modal.upload-product-images  ()
  (cl-who:with-html-output (*standard-output* nil)
    (:form :class "hhub-formprodimagesupload"  :role "form" :method "POST" :action "dodvenuploadproductsimagesaction" :data-toggle "validator" :enctype "multipart/form-data" 
	   (:div :class "row"
		 (:div :class "form-group"
		       (:input :type "file" :multiple "true" :name "uploadedimagefiles"))
		 (:div :class "form-group"
		       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))

(defun dod-controller-vendor-upload-products-images-action ()
  :documentation "Upload the product images in the form of jpeg, png files which are less than 1 MB in size"
(with-vend-session-check
  (let* ((images  (remove "uploadedimagefiles" (hunchentoot:post-parameters hunchentoot:*request*) :test (complement #'equal) :key #'car)))
    ;; Asynchronously start the upload of images. 
    (bt:make-thread
     (lambda ()
       (async-upload-images images)))
    (hunchentoot:redirect "/hhub/dodvenbulkaddprodpage"))))



(defun async-upload-images (images)
  (let* ((header (list "Product Name " "Description" "Qty Per Unit" "Unit Price" "Units In Stock" "Subscription Flag" "Image Path (DO NOT MODIFY)" "Image Hash (DO NOT MODIFY)"))
	 (vendor-id (slot-value (get-login-vendor) 'row-id))
	 (filepaths (mapcar
		     (lambda (image)
		       (let* ((newimageparams (remove "uploadedimagefiles" image :test #'equal ))
			      (tempfilewithpath (nth 0 newimageparams))
			      (filename (process-file  newimageparams (format nil "~A" *HHUBRESOURCESDIR*))))
			 (if *HHUBUSELOCALSTORFORRES* 
			     (if tempfilewithpath (format nil "/img/~A" filename))
			     ;;else return the path of the uploaded file in S3 bucket.
			     (vendor-upload-file-s3bucket filename)))) images))
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
		(cl-who:str (format nil ",,,,,,~a,~a~C~C" imagepath imagehash #\return #\linefeed)))  imagepaths image-path-hashes)))


(defun modal.upload-csv-file ()
  (cl-who:with-html-output (*standard-output* nil)
    (:form :class "hhub-formcsvfileupload"  :role "form" :method "POST" :action "dodvenuploadproductscsvfileaction" :data-toggle "validator" :enctype "multipart/form-data" 
	   (:div :class "row"
	    (:div :class "form-group"
		  (:input :type "file" :name "uploadedcsvfile"))
	    (:div :class "form-group"
		  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))

(defun com-hhub-transaction-vendor-bulk-products-add ()
  (let* ((csvfileparams (hunchentoot:post-parameter "uploadedcsvfile"))
	 (params nil)
	 (tempfilewithpath (nth 0 csvfileparams))
					;(final-file-name (process-file  csvfileparams (format nil "~A/temp" *HHUBRESOURCESDIR*)))
	 (prdlist (cl-csv:read-csv tempfilewithpath ;(pathname (format nil "~A/temp/~A" *HHUBRESOURCESDIR* final-file-name))
				   :skip-first-p T  :map-fn #'(lambda (row)
								(when (equal (nth 7 row) (string-upcase (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :MD5 (ironclad:ascii-string-to-byte-array (nth 6 row))))))
								  (make-instance 'dod-prd-master
										 :prd-name (nth 0 row)
										 :description (nth 1 row)
										 :vendor-id (slot-value (get-login-vendor) 'row-id)
										 :catg-id nil
										 :qty-per-unit (nth 2 row)
										 :unit-price (float (with-input-from-string (in (nth 3 row)) (read in)))
										 :units-in-stock  (parse-integer (nth 4 row))
										 :subscribe-flag (nth 5 row)
										 :prd-image-path (nth 6 row)
										 :tenant-id (get-login-vendor-tenant-id)
										 :active-flag "Y"
										 :approved-flag "N"
										 :approval-status "PENDING"
										 :deleted-state "N"))))))
    
    
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "prdcount" (length prdlist) params))
    (setf params (acons "company" (get-login-vendor-company) params))
    (hunchentoot:log-message* :info "Prd name = ~A" (slot-value (nth 1 prdlist) 'prd-name))
    (with-hhub-transaction "com-hhub-transaction-vendor-bulk-products-add" params
      (when (> (length prdlist) 0) (create-bulk-products prdlist)))
    (dod-reset-vendor-products-functions (get-login-vendor) (get-login-vendor-company))
    (hunchentoot:redirect "/hhub/dodvenproducts")))



  
(defun dod-controller-vendor-bulk-add-products-page ()
:documentation "Here we are going to add products in bulk using CSV file. This page will display options of adding CSV files in two phases. 
Phase1: Temporary Image URLs creation using image files upload.
Phase2: User should copy those URLs in Products.csv and then upload that file."
(let ((vendor-id (slot-value (get-login-vendor) 'row-id)))
 (with-vend-session-check
  (with-standard-vendor-page "Bulk Add Products using CSV File"
    (:div :class "row"
	  (:div :class "col-xs-12 col-sm-6 col-md-6 col-lg-6"
		(:ul :class "list-group"
		     (:li :class "list-group-item" "Step 1: Upload product images,  which will then  be converted to URLs.")
		     (:li :class "list-group-item" "Step 2: Download Products.csv Template")
		     (:li :class "list-group-item" "Step 3: Fill up other required columns of Products.csv file")
		     (:li :class "list-group-item" "Step 4: Upload the Products.csv file")))
	  
	  (:div :class "list-group col-xs-12 col-sm-6 col-md-6 col-lg-6" 
		(:a :class "list-group-item list-group-item-action" :data-toggle "modal" :data-target (format nil "#hhubvendprodimagesupload-modal")  :href "#" " Upload Product Images")
		;; This download will be enabled when the file is ready for download. 
		(if (probe-file (format nil "~A/temp/products-ven-~a.csv" *HHUBRESOURCESDIR* vendor-id))
		    (cl-who:htm (:a :href (format nil "/img/temp/products-ven-~a.csv" vendor-id) :class "list-group-item list-group-item-action" "click here to download Products.csv"))) 
		(:a :class "list-group-item list-group-item-action"  :data-toggle "modal" :data-target (format nil "#hhubvendprodcsvupload-modal")  :href "#"  " Upload CSV File"))
	  ;; Modal dialog for Uploading  product images
	  (modal-dialog (format nil "hhubvendprodimagesupload-modal") " Upload Product Images " (modal.upload-product-images))
	  ;; Modal dialog for CSV file upload
	  (modal-dialog (format nil "hhubvendprodcsvupload-modal") " Upload CSV File " (modal.upload-csv-file)))))))




(defun modal.vendor-update-details ()
  (let* ((vendor (get-login-vendor))
	 (name (name vendor))
	 (address (address vendor))
	 (phone  (phone vendor))
	 (zipcode (zipcode vendor))
	 (email (email vendor))
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
		      
		      (:div :class "form-group" (:label :for "prodimage" "Select Picture:")
			    (:input :class "form-control" :name "picturepath" :placeholder "Picture" :type "file" ))
		      
		      (:div :class "form-group"
			    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))

(defun dod-controller-vendor-update-action ()
  (with-vend-session-check 
    (let* ((name (hunchentoot:parameter "name"))
	   (address (hunchentoot:parameter "address"))
	   (phone (hunchentoot:parameter "phone"))
	   (zipcode (hunchentoot:parameter "zipcode"))
	   (email (hunchentoot:parameter "email"))
	   (vendor (get-login-vendor))
	   (prodimageparams (hunchentoot:post-parameter "picturepath"))
	   (tempfilewithpath (first prodimageparams))
	   (file-name (if tempfilewithpath (process-file prodimageparams *HHUBRESOURCESDIR*))))
      
      (setf (slot-value vendor 'name) name)
      (setf (slot-value vendor 'address) address)
      (setf (slot-value vendor 'phone) phone)
      (setf (slot-value vendor 'zipcode) zipcode)
      (setf (slot-value vendor 'email) email)
      (if tempfilewithpath (setf (slot-value vendor 'picture-path) (format nil "/img/~A"  file-name)))
      (update-vendor-details vendor)
      (hunchentoot:redirect "/hhub/dodvendprofile"))))


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
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))

(defun hhub-controller-save-vendor-upi-settings ()
  (with-vend-session-check
    (let* ((upi-id (hunchentoot:parameter "vendor-upi-id"))
	   (vendor (get-login-vendor)))

      (when (> (length upi-id) 0)
	(setf (slot-value vendor 'upi-id) upi-id)
	(update-vendor-details vendor))
      ;; Redirect to the Vendor profile page after saving the UPI ID. 
      (hunchentoot:redirect "/hhub/dodvendprofile"))))

      


(defun modal.vendor-update-payment-gateway-settings-page ()
  (let* ((vendor (get-login-vendor))
	 (payment-api-key (payment-api-key vendor))
	 (payment-api-salt (payment-api-salt vendor))
	 (pg-mode (slot-value vendor 'payment-gateway-mode)))
       
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :id (format nil "form-customerupdate")  :role "form" :method "POST" :action "hhubvendupdatepgsettings" :enctype "multipart/form-data" 
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
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))



;; @@ deprecated : start using with-html-dropdown instead. 
(defun payment-gateway-mode-options (selectedkey) 
  (let ((pg-mode (make-hash-table)))
    (setf (gethash "test" pg-mode) "test") 
    (setf (gethash "live" pg-mode) "live")
    (with-html-dropdown "pg-mode" pg-mode selectedkey)))


(defun dod-controller-vendor-update-payment-gateway-settings-action ()
  (with-vend-session-check 
    (let* ((payment-api-key (hunchentoot:parameter "payment-api-key"))
	   (payment-api-salt (hunchentoot:parameter "payment-api-salt"))
	   (pg-mode  (hunchentoot:parameter "pg-mode"))
	   (vpushnotifysubs (hunchentoot:parameter "vpushnotifysubs"))
	   (vendor (get-login-vendor)))
      (setf (slot-value vendor 'payment-api-key) payment-api-key)
      (setf (slot-value vendor 'payment-api-salt) payment-api-salt)
      (setf (slot-value vendor 'payment-gateway-mode) pg-mode)
      (setf (slot-value vendor 'push-notify-subs-flag) (if (null vpushnotifysubs) "N" vpushnotifysubs))
      (update-vendor-details vendor)
      (hunchentoot:redirect "/hhub/dodvendprofile"))))


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
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))))




(defun dod-controller-vendor-change-pin ()
  (with-vend-session-check 
    (let* ((password (hunchentoot:parameter "password"))
	   (newpassword (hunchentoot:parameter "newpassword"))
	   (confirmpassword (hunchentoot:parameter "confirmpassword"))
	   (salt-octet (secure-random:bytes 56 secure-random:*generator*))
	   (salt (flexi-streams:octets-to-string  salt-octet))
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
	  (:a :class "btn btn-primary" :role "button" :href "dodvendsearchtenantpage" (:span :class "glyphicon glyphicon-shopping-cart") " Add New Group  ")
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
			  (:span :class "input-group-btn" (:<button :class "btn btn-danger" :type "button" 
								(:span :class " glyphicon glyphicon-search")))))
	      (:div :id "searchresult" "")))
      (hunchentoot:redirect "/hhub/vendor-login.html")))





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
  (if (is-dod-vend-session-valid?)
      (let* ((cname (hunchentoot:parameter "cname"))
	     (company (select-company-by-name cname)))
	
	(create-vendor-tenant (get-login-vendor) "N"  company)
	(hunchentoot:redirect "/hhub/dodvendortenants"))
      ;else
      (hunchentoot:redirect "/hhub/vendor-login.html")))







(defun dod-controller-vendor-add-product-page ()
(with-vend-session-check 
  (let ((catglist (hhub-get-cached-product-categories)))
    (with-standard-vendor-page (:title "Welcome to DAS Platform- Your Demand And Supply destination.")
      (:div :class "row" 
	    (:div :class "col-sm-6 col-md-4 col-md-offset-4"
		  (:form :class "form-vendorprodadd" :role "form" :method "POST" :action "dodvenaddproductaction" :data-toggle "validator" :enctype "multipart/form-data" 
			 (:div :class "account-wall"
			       (:img :class "profile-img" :src "/img/logo.png" :alt "")
			       (:h1 :class "text-center login-title"  "Add new product")
			       (:div :class "form-group"
				     (:input :class "form-control" :name "prdname" :placeholder "Enter Product Name ( max 30 characters) " :type "text" ))
			       
			       (:div :class "form-group"
				     (:label :for "description")
				     (:textarea :class "form-control" :name "description" :placeholder "Enter Product Description ( max 1000 characters) "  :rows "5" :onkeyup "countChar(this, 1000)"  ))
			       (:div :class "form-group" :id "charcount")
			       (:div :class "form-group"
				     (:input :class "form-control" :name "prdprice" :placeholder "Price"  :type "text" :min "0.00" :max "10000.00" :step "0.01" ))
			       (:div :class "form-group"
						   (:input :class "form-control" :name "unitsinstock" :placeholder "Units In Stock"  :type "number" :min "1" :max "10000" :step "1" ))
			       (:div :class "form-group"
				     (:input :class "form-control" :name "qtyperunit" :placeholder "Quantity per unit. Ex - KG, Grams, Nos" :type "text" ))
			       (:div  :class "form-group" (:label :for "prodcatg" "Select Produt Category:" )
				      (ui-list-prod-catg-dropdown catglist nil))
			       (:br) 
			       (:div :class "form-group" (:label :for "yesno" "Product/Service Subscription")
				     (ui-list-yes-no-dropdown "N"))
			       (:div :class "form-group" (:label :for "prodimage" "Select Product Image:")
				     (:input :class "form-control" :name "prodimage" :placeholder "Product Image" :type "file" ))
			       (:div :class "form-group"
				     (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))))



(defun vendor-upload-file-s3bucket (filename) 
  (let* ((tenantid (format nil "~A" (get-login-vendor-tenant-id)))
         (vendorid (format nil "~A" (slot-value (get-login-vendor) 'row-id)))
         (uuid (format nil "~A" (uuid:make-v1-uuid)))
         (paramnames (list "filename" "tenantid" "vendorid" "uuid"))
         (paramvalues (list filename tenantid vendorid uuid))
         (param-alist (pairlis paramnames paramvalues))
         (headers nil)
         (headers (acons "auth-secret" "highrisehub1234" headers)))   
    ;;(logiamhere (format nil "Filename is ~A" filename))
    ;; Execution
    
    (drakma:http-request (format nil "~A/file/upload" *siteurl*)
			 :additional-headers headers
			 :parameters param-alist)))

(defun com-hhub-transaction-vend-prd-shipinfo-add-action ()
  (with-vend-session-check
    (let* ((vendor (get-login-vendor))
	   (shipping-enabled (slot-value vendor 'shipping-enabled))
	   (id (hunchentoot:parameter "id"))
	   (product (if id (select-product-by-id id (get-login-vendor-company))))
	   (shipping-length-cms (parse-integer (hunchentoot:parameter "shipping-length-cms")))
	   (shipping-width-cms (parse-integer (hunchentoot:parameter "shipping-width-cms")))
	   (shipping-height-cms (parse-integer (hunchentoot:parameter "shipping-height-cms")))
	   (shipping-weight-kg (float (with-input-from-string (in (hunchentoot:parameter "shipping-weight-kg"))
			(read in))))
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
	  (dod-reset-vendor-products-functions vendor (get-login-vendor-company))
	  (hunchentoot:redirect "/hhub/dodvenproducts"))))))
  


(defun com-hhub-transaction-vendor-product-add-action () 
  (with-vend-session-check
    (let* ((prodname (hunchentoot:parameter "prdname"))
	   (id (hunchentoot:parameter "id"))
	   (product (if id (select-product-by-id id (get-login-vendor-company))))
	   (description (hunchentoot:parameter "description"))
	   (prodprice (float (with-input-from-string (in (hunchentoot:parameter "prdprice"))
			(read in))))
	   (qtyperunit (hunchentoot:parameter "qtyperunit"))
	   (units-in-stock (parse-integer (hunchentoot:parameter "unitsinstock")))
	   (catg-id (parse-integer (hunchentoot:parameter "prodcatg")))
	   (subscriptionflag (hunchentoot:parameter "yesno"))
	   (prodimageparams (hunchentoot:post-parameter "prodimage"))
					;(destructuring-bind (path file-name content-type) prodimageparams))
	   (tempfilewithpath (first prodimageparams))
	   (file-name (format nil "~A" (second prodimageparams)))
	   (external-url (if product (generate-product-ext-url product)))
	   (params nil))

      (setf params (acons "company" (get-login-vendor-company) params))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
	   
      (with-hhub-transaction "com-hhub-transaction-vendor-product-add-action" params 
	(progn 
	  (if tempfilewithpath 
	      (progn 
		(probe-file tempfilewithpath)
		(rename-file tempfilewithpath (make-pathname :directory *HHUBRESOURCESDIR*  :name file-name))))
	  (if product 
	      (progn
		(setf (slot-value product 'prd-name) prodname)
		(setf (slot-value product 'description) description)
		(setf (slot-value product 'unit-price) prodprice)
		(setf (slot-value product 'catg-id) catg-id)
		(setf (slot-value product 'qty-per-unit) qtyperunit)
		(setf (slot-value product 'units-in-stock) units-in-stock)
		(setf (slot-value product 'subscribe-flag) subscriptionflag)
		(setf (slot-value product 'external-url) external-url)
		;; Save the image in AWS S3 bucket if we are in production.
		(if *HHUBUSELOCALSTORFORRES* 
		    (if tempfilewithpath (setf (slot-value product 'prd-image-path) (format nil "/img/~A"  file-name)))
		    ;;else
		    (let ((s3filelocation (vendor-upload-file-s3bucket (format nil "~A" file-name))))
		      (if tempfilewithpath (setf (slot-value product 'prd-image-path) s3filelocation))))
		 	       
		(update-prd-details product))
					;else
	      (create-product prodname description (get-login-vendor) (select-prdcatg-by-id catg-id (get-login-vendor-company)) qtyperunit prodprice units-in-stock (if tempfilewithpath (format nil "/img/~A" file-name) (format nil "/img/~A"   *HHUBDEFAULTPRDIMG*))  subscriptionflag  (get-login-vendor-company)))
	  (dod-reset-vendor-products-functions (get-login-vendor) (get-login-vendor-company))
	  (hunchentoot:redirect "/hhub/dodvenproducts"))))))
  





(defun dod-controller-vendor-password-reset-action ()
  (let* ((pwdresettoken (hunchentoot:parameter "token"))
	 (rstpassinst (get-reset-password-instance-by-token pwdresettoken))
	 (user-type (if rstpassinst (slot-value rstpassinst 'user-type)))
	 (password (hunchentoot:parameter "password"))
	 (newpassword (hunchentoot:parameter "newpassword"))
	 (confirmpassword (hunchentoot:parameter "confirmpassword"))
	 (salt-octet (secure-random:bytes 56 secure-random:*generator*))
	 (salt (flexi-streams:octets-to-string  salt-octet))
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
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))


(defun dod-controller-vendor-generate-temp-password ()
  (let* ((token (hunchentoot:parameter "token"))
	 (rstpassinst (get-reset-password-instance-by-token token))
	 (user-type (if rstpassinst (slot-value rstpassinst 'user-type)))
	 (url (format nil "https://www.highrisehub.com/hhub/hhubvendpassreset.html?token=~A" token))
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
       (url (format nil "https://www.highrisehub.com/hhub/hhubvendgentemppass?token=~A" token))
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
		  (with-standard-vendor-page  "Welcome to HighriseHub Platform - Vendor Login "
		    (:div :class "row" 
			  (:div :class "col-sm-6 col-md-4 col-md-offset-4"
				(:div :class "account-wall"
				      (:form :class "form-vendorsignin" :role "form" :method "POST" :action "dodvendlogin"
					     (:a :href *siteurl*  (:img :class "profile-img" :src "/img/logo.png" :alt ""))
					     (:h1 :class "text-center login-title"  "Vendor - Login to HighriseHub")
					     (:div :class "form-group"
						   (:input :class "form-control" :name "phone" :placeholder "Enter RMN. Ex:9999999990" :type "text" ))
					     (:div :class "form-group"
						   (:input :class "form-control" :name "password" :placeholder "password=Welcome1" :type "password" ))
					     (:div :class "form-group"
						   (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))
				      (:div :class "form-group"
					    (:a :data-toggle "modal" :data-target (format nil "#dasvendforgotpass-modal") :href "#" "Forgot Password" )))))
		    (modal-dialog (format nil "dasvendforgotpass-modal") "Forgot Password?" (modal.vendor-forgot-password)))))
    (clsql:sql-database-data-error (condition)
      (if (equal (clsql:sql-error-error-id condition) 2013 ) (progn
							       (stop-das) 
							       (start-das)
							       (hunchentoot:redirect "/hhub/vendor-login.html"))))))


(defun dod-controller-vendor-my-customers-page ()
  (with-vend-session-check
    (let* ((vendor (get-login-vendor))
	   (company (get-login-vendor-company))
	   (wallets (get-cust-wallets-for-vendor vendor company))
	   (mycustomers (remove nil (mapcar (lambda (wallet)
				  (let* ((customer (slot-value wallet 'customer))
					 (cust-type (slot-value customer 'cust-type)))
				    (when (equal cust-type "STANDARD") customer))) wallets))))
      (with-standard-vendor-page "My Customers"
	(with-html-search-form "hhubsearchmycustomer" "Customer Name")
	(:div :id "searchresult"  :class "container"
	      (cl-who:str (display-as-table (list "Name" "Phone" "Address" "Balance" "Actions") mycustomers 'display-my-customers-row)))))))


(defun hhub-controller-search-my-customer-action ()
  (with-vend-session-check
    (let* ((company (get-login-vendor-company))
	   (vendor (get-login-vendor))
	   (name (hunchentoot:parameter "livesearch"))
	   (totalcustomers (select-customer-list-by-name (format nil "%~A%" name) company))
	   (customers (remove nil (mapcar (lambda (customer)
					    (if (get-cust-wallet-by-vendor customer vendor company) customer)) totalcustomers))))
      
      (if (> (length customers) 0)
	(cl-who:with-html-output (*standard-output* nil) 
	  (cl-who:str (display-as-table (list "Name" "Phone" "Address" "Balance" "Actions") customers 'display-my-customers-row)))
	;; else
	(cl-who:with-html-output (*standard-output* nil)
	  (:h3 (cl-who:str "No Records Found")))))))
	
       

(defun display-my-customers-row (customer)
  (let* ((vendor (get-login-vendor))
	 (company (get-login-vendor-company))
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
	      (:a :data-toggle "modal" :data-target (format nil "#vendormycustomerwallet~A" cust-id)  :href "#"  (:i :class "fa fa-inr" :aria-hidden "true"))
	      (modal-dialog (format nil "vendormycustomerwallet~A" cust-id) "Recharge Wallet" (modal.vendor-my-customer-wallet-recharge wallet phone)))
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
		     (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))
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
				     (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))))))
  


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
			    (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))))))
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
    (with-standard-vendor-page "HighriseHub - Vendor Profile"
       (:h3 "Welcome " (cl-who:str (format nil "~A" (get-login-vendor-name))))
       (:hr)
      (:div :class "list-group col-sm-6 col-md-6 col-lg-6"
	    (:a :class "list-group-item" :href "hhubvendmycustomers" "My Customers")
	    (:a :class "list-group-item" :href "dodvendortenants" "My Groups")
	    (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodvendupdate-modal")  :href "#"  "Contact Information")
	    (modal-dialog (format nil "dodvendupdate-modal") "Update Vendor" (modal.vendor-update-details)) 
		    
	    (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodvendchangepin-modal")  :href "#"  "Change Password")
	    (modal-dialog (format nil "dodvendchangepin-modal") "Change Password" (modal.vendor-change-pin))
	    ;; (:a :class "list-group-item" :href "/pushsubscribe.html" "Push Notifications")
	    (:a :class "list-group-item" :href "/hhub/hhubvendpushsubscribepage" "Push Notifications")
	    (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodvendsettings-modal")  :href "#"  "Payment Gateway")
	    (modal-dialog (format nil "dodvendsettings-modal") "Payment Gateway Settings" (modal.vendor-update-payment-gateway-settings-page))
	    (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodvendupisettings-modal") :href "#" "UPI Settings")
	    (modal-dialog (format nil "dodvendupisettings-modal") "UPI Payment Settings" (modal.vendor-update-UPI-payment-settings-page))
	    (:a :class "list-group-item" :href "hhubvendorupitransactions" "UPI Transactions")
	    (:a :class "list-group-item" :href "hhubvendorshipmethods" "Shipping Methods")))))

(defun dod-controller-vend-shipping-methods ()
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
    (with-vend-session-check
      (with-standard-vendor-page "HighriseHub - Vendor Shipping Methods"
	(:div :class "list-group col-sm-6 col-md-6 col-lg-6"
	      (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodvendfreeshipping-modal")  :href "#"  "Free Shipping")
	      (modal-dialog (format nil "dodvendfreeshipping-modal") "Free Shipping Configuration" (modal.vendor-free-shipping-config freeshipenabled minorderamt))
	      (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodvendflatrateshipping-modal")  :href "#"  "Flat Rate Shipping")
	      (modal-dialog (format nil "dodvendflatrateshipping-modal") "Flat Rate Shipping Configuration" (modal.vendor-flatrate-shipping-config flatrateshipenabled flatratetype flatrateprice))
	      (:a :class "list-group-item" :href "hhubvendshipzoneratetablepage"  "Zonewise Shipping")
	      (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodvendextshipping-modal")  :href "#"  "External Shipping Partners")
	      (modal-dialog (format nil "dodvendextshipping-modal") "External Shipping Partners Configuration" (modal.vendor-external-shipping-partners-config shippartnerkey shippartnersecret extshipenabled))
	      (:a :class "list-group-item" :data-toggle "modal" :data-target (format nil "#dodvenddefaultshipmethod-modal")  :href "#"  "Select Default Shipping Method")
	      (modal-dialog (format nil "dodvenddefaultshipmethod-modal") "Default Shipping Method Configuration" (modal.vendor-default-shipping-method-config shippingmethod vendor)))
	     
	      
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
}")
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
}")
	(:script "function enablestorepickupmethod(){
       const  enablestorepickup  = document.getElementById('storepickupenabled');
    if( enablestorepickup.checked ){
         enablestorepickup.value = \"Y\";
    }else
    {
         enablestorepickup.value = \"N\";
    }
}")))))

(defun dod-controller-vendor-shipzone-ratetable-page()
  (with-vend-session-check
    (let* ((vendor (get-login-vendor))
	   (company (get-login-vendor-company))
	   (shippingmethod (get-shipping-method-for-vendor vendor company))
	   (tablerateshipenabled (if shippingmethod (slot-value shippingmethod 'tablerateshipenabled)))
	   (ratetablecsv (if (and tablerateshipenabled shippingmethod) (getratetablecsv shippingmethod) (hhub-read-file (format nil "~A/~A" *HHUBRESOURCESDIR* *HHUBDEFAULTSHIPRATETABLECSV*))))
	   (shipzones (get-ship-zones-for-vendor vendor company))
	   (zipcoderanges (hhub-read-file (format nil "~A/~A" *HHUBRESOURCESDIR* *HHUBDEFAULTSHIPZONESCSV*))))

      (with-standard-vendor-page "HighriseHub - Vendor Zonewise Shipping Method"
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
			      (:button :class "btn btn-primary" :type "submit" "Submit")))
	
	
	(:hr)
	(when ratetablecsv
	  (cl-who:str
	   (display-csv-as-html-table ratetablecsv)))
	(:br)
	(unless shipzones
	  (cl-who:str (display-csv-as-html-table zipcoderanges)))
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
			      (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))
  


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
			(:label :class "form-check-label" :for "freeshipenabled" "&nbsp;&nbsp;Enable Store Pickup"))
		  
		  (:div :class "form-group"
			(:input :class "form-control" :name "shippartnerkey" :value shippartnerkey :placeholder "Shipping Partner API Key" :type "text"))
		  (:div :class "form-group"                                                                  
			(:input :class "form-control" :name "shippartnersecret" :value shippartnersecret :placeholder "Shipping Partner API Secret" :type "text"))
		  (:div :class "form-group"
			(:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))))

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
			      (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit")))))))))


(defun dod-controller-vendor-update-flatrate-shpping-action ()
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
			      (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))

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
			 (:button :type "button" :class "navbar-toggle" :data-toggle "collapse" :data-target "#navheadercollapse"
				  (:span :class "icon-bar")
				  (:span :class "icon-bar")
				  (:span :class "icon-bar"))
			 (:a :class "navbar-brand" :href "#" :title "highrisehub" (:img :style "width: 50px; height: 50px;" :src "/img/logo.png" )))
		   ;;  (:a :class "navbar-brand" :onclick "window.history.back();"  :href "#"  (:span :class "glyphicon glyphicon-arrow-left"))
		   (:div :class "collapse navbar-collapse" :id "navheadercollapse"
			 (:ul :class "nav navbar-nav navbar-left"
			      (:li :class "active" :align "center" (:a :href "dodvendindex?context=home"  (:span :class "glyphicon glyphicon-home")  "Home"))
			      (:li :align "center" (:a :href "dodvenproducts"  "My Products"))
			      (:li :align "center" (:a :href "dodvendindex?context=completedorders"  "Completed Orders"))
			      (:li :align "center" (:a :href "#" (print-web-session-timeout)))
			      (:li :align "center" (:a :href "#" (cl-who:str (format nil "Group: ~A" (get-login-vendor-company-name))))))
			 (:ul :class "nav navbar-nav navbar-right"
			      (:li :align "center" (:a :href "dodvendprofile?context=home"   (:span :class "glyphicon glyphicon-user") "&nbsp;&nbsp;" )) 
				(:li :align "center" (:a :target "_blank" :href "https://goo.gl/forms/XaZdzF30Z6K43gQm2"  (:span :class "glyphicon glyphicon-envelope") "&nbsp;&nbsp;"))
				(:li :align "center" (:a :target "_blank" :href "https://goo.gl/forms/SGizZXYwXDUiTgVY2"  "Bug" ))
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


;(defun setup-domain-vendor (domain phone)
;  (let ((vendor-repo (make-instance 'VendorRepository)))
 ;   (loadVendorByPhone vendor-repo phone)
  ;  (let* ((vendor (getVendor vendor-repo phone))
;	   (vendorctx (getBusinessContext domain "vendorsite"))
;	   (company (getVendorCompany vendor))))))

      
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
	     (vendor-company (if dbvendor  (vendor-company dbvendor))))
					;(log (if password-verified (hunchentoot:log-message* :info (format nil  "phone : ~A password : ~A" phone password)))))
	(when (and  dbvendor
		    password-verified
		    (null (hunchentoot:session-value :login-vendor-name))) ;; vendor should not be logged-in in the first place.
	  (progn
	    (hunchentoot:start-session)
	    (setf hunchentoot:*session-max-time* (* 3600 8))
	    (if dbvendor (setf (hunchentoot:session-value :login-vendor ) dbvendor))
	    (if dbvendor (setf (hunchentoot:session-value :login-vendor-name) (slot-value dbvendor 'name)))
	    (if dbvendor (setf (hunchentoot:session-value :login-vendor-id) (slot-value dbvendor 'row-id)))
	    (set-vendor-session-params  vendor-company dbvendor))))
	    ;; Lets work on the domain objects here.
	   ;; (setup-domain-vendor *HHUBBUSINESSDOMAIN* phone))))

					;handle the exception. 
    (clsql:sql-database-data-error (condition)
      (if (equal (clsql:sql-error-error-id condition) 2006 ) 
	  (progn
	    (stop-das) 
	    (start-das)
	    (hunchentoot:redirect "/hhub/vendor-login.html"))))))

(defun dod-controller-vendor-switch-tenant ()
  (with-vend-session-check
    (let* ((company (select-company-by-id (hunchentoot:parameter "id")))
	   (vendor (get-login-vendor)))
      (progn
	(set-vendor-session-params company vendor)
	(hunchentoot:redirect "/hhub/dodvendindex?context=home")))))




(defun set-vendor-session-params ( company  vendor)
  ;; Add the vendor object and the tenant to the Business Session 
       					;set vendor company related params 
  (setf (hunchentoot:session-value :login-vendor-tenant-id) (slot-value company 'row-id ))
  (setf (hunchentoot:session-value :login-vendor-company-name) (slot-value company 'name))
  (setf (hunchentoot:session-value :login-vendor-company) company)
					;(setf (hunchentoot:session-value :login-prd-cache )  (select-products-by-company company))
					;set vendor related params 
  (if vendor (setf (hunchentoot:session-value :login-vendor-tenants) (get-vendor-tenants-as-companies vendor)))
  (if vendor (setf (hunchentoot:session-value :order-func-list) (dod-gen-order-functions vendor company)))
  (if vendor (setf (hunchentoot:session-value :vendor-order-items-hashtable) (make-hash-table)))
  (if vendor (setf (hunchentoot:session-value :login-vendor-products-functions) (dod-gen-vendor-products-functions vendor company))))


   
(defun dod-controller-vendor-delete-product () 
 (if (is-dod-vend-session-valid?)
  (let ((id (hunchentoot:parameter "id")))
    (if (= (length (get-pending-order-items-for-vendor-by-product (select-product-by-id id (get-login-vendor-company)) (get-login-vendor))) 0)
	(progn 
	  (delete-product id (get-login-vendor-company))
	  (setf (hunchentoot:session-value :login-vendor-products-functions) (dod-gen-vendor-products-functions (get-login-vendor) (get-login-vendor-company)))))   
    (hunchentoot:redirect "/hhub/dodvenproducts"))
     	(hunchentoot:redirect "/hhub/vendor-login.html"))) 

(defun dod-controller-prd-details-for-vendor ()
    (if (is-dod-vend-session-valid?)
	(with-standard-vendor-page "Product Details"
	    (let* ((company (hunchentoot:session-value :login-vendor-company))
		   (product (select-product-by-id (parse-integer (hunchentoot:parameter "id")) company)))
		(product-card-with-details-for-vendor product)))
	(hunchentoot:redirect "/hhub/vendor-login.html")))


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
  (let* ((search-clause (hunchentoot:parameter "livesearch"))
	 (products (if (not (equal "" search-clause)) (search-products search-clause (get-login-vendor-company)))))
    (cl-who:with-html-output-to-string (*standard-output* nil)
      (:div :id "searchresult" 
	    (cl-who:str (display-as-tiles products  'product-card-for-vendor "vendor-product-box"))))))

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


	
(defun vendor-product-category-row (category)
  (with-slots (row-id catg-name) category 
      (cl-who:with-html-output (*standard-output* nil)
	(:td  :height "10px" (cl-who:str catg-name)))))

(defun dod-controller-vendor-products ()
  (with-vend-session-check 
    (let* ((vendor-products (hhub-get-cached-vendor-products))
	   (vendor-company (get-login-vendor-company))
	   (subscription-plan (slot-value vendor-company 'subscription-plan)))
	
      (with-standard-vendor-page "Welcome to HighriseHub  - Vendor"
	(with-html-search-form "hhubvendsearchproduct" "Product Name")
	  
	(:div :class "row" 
	      (:div :class "col-xs-3 col-sm-3 col-md-3 col-lg-3" 
		    (:a :class "btn btn-primary" :role "button" :href "dodvenaddprodpage" (:span :class "glyphicon glyphicon-shopping-cart") " Add New Product  "))
	      (when (com-hhub-attribute-company-prdbulkupload-enabled subscription-plan)
		(cl-who:htm   (:div :class "col-xs-3 col-sm-3 col-md-3 col-lg-3" 
				    (:a :class "btn btn-primary" :role "button" :href "dodvenbulkaddprodpage" (:span :class "glyphicon glyphicon-shopping-cart") " Bulk Add Products "))))
	      (:div :class "col-xs-3 col-sm-3 col-md-3 col-lg-3" :align "right"
		        (:a :class "btn btn-primary" :role "button" :href "dodvendprodcategories" (:span :class "glyphicon glyphicon-shopping-cart") " Product Categories "))
	      (:div :class "col-xs-3 col-sm-3 col-md-3 col-lg-3" :align "right" 
		    (:span :class "badge" (cl-who:str (format nil " ~d " (length vendor-products)))))) 
	(:hr)
	(:div :id "searchresult" 
	      (cl-who:str (display-as-tiles vendor-products  'product-card-for-vendor "vendor-product-card")))))))



(defun dod-gen-vendor-products-functions (vendor company)
  (let ((vendor-products (select-products-by-vendor vendor company))
	(product-categories (select-prdcatg-by-company company)))
    (list (function (lambda () vendor-products))
	  (function (lambda () product-categories)))))

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
    (setf (hunchentoot:session-value :order-func-list) order-func-list)))


(defun hhub-get-cached-vendor-products ()
  (let ((vendor-products-func (first (hunchentoot:session-value :login-vendor-products-functions))))
    (funcall vendor-products-func)))

(defun hhub-get-cached-product-categories ()
  (let ((vendor-products-func (second (hunchentoot:session-value :login-vendor-products-functions))))
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


(defun dod-controller-vend-index () 
  (with-vend-session-check 
    (let ((dodorders (dod-get-cached-pending-orders ))
	  (reqdate (hunchentoot:parameter "reqdate"))
	  (btnexpexl (hunchentoot:parameter "btnexpexl"))
	  (context (hunchentoot:parameter "context")))
      (with-standard-vendor-page "Welcome Vendor"
	  (:h3 "Welcome " (cl-who:str (format nil "~A" (get-login-vendor-name))))
	  (:hr)
	  (:form :class "form-venorders" :method "POST" :action "dodvendindex"
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
						    (:button :class "btn btn-primary"  :type "submit" :name "btnprint" :onclick "javascript:window.print();" "Print") 
						    )))
					; (:hr)
	  (cond ((equal context "ctxordprd") (ui-list-vendor-orders-by-products dodorders))
		((and dodorders btnexpexl) (hunchentoot:redirect (format nil "/hhub/dodvenexpexl?reqdate=~A" reqdate)))
		((equal context "ctxordcus") (ui-list-vendor-orders-by-customers dodorders))
		((equal context "home")	(cl-who:htm (:div :class "list-group col-xs-6 col-sm-6 col-md-6 col-lg-6" 
							  (:a :class "list-group-item" :href "dodvendindex?context=pendingorders" " Orders " (:span :class "badge" (cl-who:str (format nil " ~d " (length dodorders)))))
							  (:a :class "list-group-item" :href "dodvendindex?context=ctxordprd" "Todays Demand")
							  (:a :class "list-group-item" :href (cl-who:str (format nil "dodvendrevenue"))  "Today's Revenue"))))  
		
				       ((equal context "pendingorders") 
					(progn (cl-who:htm (cl-who:str "Pending Orders") (:span :class "badge" (cl-who:str (format nil " ~d " (length dodorders))))
							   (:a :class "btn btn-primary btn-xs" :role "button" :href "dodrefreshpendingorders" (:span :class "glyphicon glyphicon-refresh"))
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
	(let* ((id (hunchentoot:parameter "id"))
	       (company-instance (hunchentoot:session-value :login-vendor-company))
	       (order-instance (get-order-by-id id company-instance))
	       (payment-mode (slot-value order-instance 'payment-mode))
	       (customer (get-customer order-instance)) 
	       (vendor (get-login-vendor))
	       (wallet (get-cust-wallet-by-vendor customer vendor company-instance))
	       (vendor-order-items (get-order-items-for-vendor-by-order-id  order-instance (get-login-vendor) ))
	       (vorderitemstotal (get-order-items-total-for-vendor vendor  vendor-order-items))
	       (params nil))

	 (setf params (acons "uri" (hunchentoot:request-uri*)  params))
	 (setf params (acons "company" company-instance params))
	 (with-hhub-transaction "com-hhub-transaction-vendor-order-setfulfilled"  params   
	   (progn (if (equal payment-mode "PRE")
		      (unless (check-wallet-balance vorderitemstotal wallet)
			(display-wallet-for-customer wallet "Not enough balance for the transaction.")))
		  ;; We will make all the database changes in the background. 
		  (set-order-fulfilled "Y" vendor  order-instance company-instance)
		  (hunchentoot:redirect "/hhub/dodvendindex?context=pendingorders"))))))

(defun display-wallet-for-customer (wallet-instance custom-message)
  (with-standard-vendor-page (:title "Wallet Display")
    (wallet-card wallet-instance custom-message)))

(defun dod-controller-ven-expexl ()
    (if (is-dod-vend-session-valid?)
	(let ((type (hunchentoot:parameter "type"))
	      (header (list "Product " "Quantity" "Qty per unit" "Unit Price" ""))
	      (today (get-date-string (clsql-sys:get-date))))
	      (setf (hunchentoot:content-type*) "application/vnd.ms-excel")
	      (setf (hunchentoot:header-out "Content-Disposition" ) (format nil "inline; filename=Orders_~A.csv" today))
	      (cond ((equal type "pendingorders") (ui-list-orders-for-excel header (dod-get-cached-pending-orders)))
		    ((equal type "completedorders") (ui-list-orders-for-excel header (dod-get-cached-completed-orders)))))
	(hunchentoot:redirect "/hhub/vendor-login.html")))



(defun get-login-vendor ()
    :documentation "Get the login session for vendor"
    (hunchentoot:session-value :login-vendor ))


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
      ;;(deleteHHUBBusinessSession (hunchentoot:session-value :login-vendor-business-session-id)) 
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
	 (payment-mode (if mainorder (slot-value mainorder 'payment-mode)))
	 (header (list "Product" "Product Qty" "Unit Price"  "Sub-total"))
	 (odtlst (if mainorder (dod-get-cached-order-items-by-order-id (slot-value mainorder 'row-id) (hunchentoot:session-value :order-func-list) )) )
	 (order-amt (slot-value vorder-instance 'order-amt))
	 (shipping-cost (slot-value vorder-instance 'shipping-cost))
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
					;ELSE
					; Convert the complete button to a submit button and introduce a form here. 
			 (cl-who:htm (with-html-form "form-vendordercomplete" "dodvenordfulfilled"
				(:input :type "hidden" :name "id" :value (slot-value mainorder 'row-id))
					; (:a :onclick "return CancelConfirm();" :href (format nil "dodvenordcancel?id=~A" (slot-value order 'row-id) ) (:span :class "btn btn-primary"  "Cancel")) "&nbsp;&nbsp;"  
				(:div :class "form-group" 
				      (:input :type "submit"  :class "btn btn-primary" :value "Complete")))))))

	  (if odtlst (ui-list-vend-orderdetails header odtlst) "No order details")
	  (if mainorder (display-order-header-for-vendor mainorder))

	  (with-html-form "form-vendordercancel" "dodvenordcancel" 
	    (with-html-input-text-hidden "id" (slot-value mainorder 'row-id))
	    (:div :class "form-group" :style "display:none"
		  (:input :type "submit"  :class "btn btn-primary" :value "Cancel Order"))))))

(defun dod-controller-vendor-orderdetails ()
 (if (is-dod-vend-session-valid?)
     (with-standard-vendor-page (:title "List Vendor Order Details")   
       (let* (( dodvenorder  (get-vendor-orders-by-orderid (hunchentoot:parameter "id") (get-login-vendor) (get-login-vendor-company)))
	      (customer (get-customer dodvenorder))
	      (wallet (get-cust-wallet-by-vendor customer (get-login-vendor) (get-login-vendor-company)))
	      (balance (slot-value wallet 'balance))
	      (venorderfulfilled (if dodvenorder (slot-value dodvenorder 'fulfilled)))
	      (order (get-order-by-id (hunchentoot:parameter "id") (get-login-vendor-company)))
	      (payment-mode (slot-value order 'payment-mode))
	      (header (list "Product" "Product Qty" "Unit Price"  "Sub-total"))
	      (odtlst (if order (dod-get-cached-order-items-by-order-id (slot-value order 'row-id) (hunchentoot:session-value :order-func-list)  )) )
	      (total   (reduce #'+  (mapcar (lambda (odt)
					      (* (slot-value odt 'unit-price) (slot-value odt 'prd-qty))) odtlst)))
	      (lowwalletbalance (< balance total)))
	 (if order (display-order-header-for-vendor  order)) 
	 (if odtlst (ui-list-vend-orderdetails header odtlst) "No order details")
	 (cl-who:htm(with-html-div-row 
		   (:div :class "col-md-12" :align "right" 
			 (if (and lowwalletbalance (equal payment-mode "PRE")) 
			     (cl-who:htm (:h2 (:span :class "label label-danger" (cl-who:str (format nil "Low wallet Balance = Rs ~$" balance))))))
			     ;else
			     (:h2 (:span :class "label label-default" (cl-who:str (format nil "Total = Rs ~$" total))))
			 (if (equal venorderfulfilled "Y") 
			     (cl-who:htm (:span :class "label label-info" "FULFILLED"))
					;ELSE
			    ; Convert the complete button to a submit button and introduce a form here. 
			     (cl-who:htm 
			     ; (:a :onclick "return CancelConfirm();" :href (format nil "dodvenordcancel?id=~A" (slot-value order 'row-id) ) (:span :class "btn btn-primary"  "Cancel")) "&nbsp;&nbsp;"  
			       (:a :href (format nil "dodvenordfulfilled?id=~A" (slot-value order 'row-id) ) (:span :class "btn btn-primary"  "Complete")))))))))
					;ELSE		   						   
	(hunchentoot:redirect "/hhub/vendor-login.html")))



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
				     (let ((odt-product  (get-odt-product odt))
					   (unit-price (slot-value odt 'unit-price))
					   (prd-qty (slot-value odt 'prd-qty)))
				       (cl-who:htm (:tr (:td  :height "12px" (cl-who:str (slot-value odt-product 'prd-name)))
						 (:td  :height "12px" (cl-who:str (format nil  "~d" prd-qty)))
						 (:td  :height "12px" (cl-who:str (format nil  "Rs. ~$" unit-price)))
						 (:td  :height "12px" (cl-who:str (format nil "Rs. ~$" (* (slot-value odt 'unit-price) (slot-value odt 'prd-qty)))))
						 )))) (if (not (typep data 'list)) (list data) data))))))))
