;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(defun get-shipping-method-for-vendor (vendor company)
  (let ((tenant-id (slot-value company 'row-id))
	(vendor-id (slot-value vendor 'row-id)))
    (car (clsql:select 'dod-shipping-methods  :where
		       [and
		       [= [:deleted-state] "N"]
		       [= [:active-flag] "Y"]
		       [= [:tenant-id] tenant-id]
		       [= [:vendor-id] vendor-id]] :caching *dod-debug-mode* :flatp T ))))
  

(defun persist-free-shipping-method (minordamt vendor-id tenant-id)
  (clsql:update-records-from-instance (make-instance 'dod-shipping-methods
					 :minorderamt minordamt
					 :vendor-id vendor-id
					 :tenant-id tenant-id
					 :freeshipenabled "Y"
					 :active-flag "Y"
					 :deleted-state "N")))



(defun create-free-shipping-method (minordamt vendor company)
   (let ((tenant-id (slot-value company 'row-id))
	 (vendor-id (slot-value vendor 'row-id)))
     (persist-free-shipping-method minordamt vendor-id tenant-id)))


(defun getratetablecsv (shippingmethod)
  (let ((tablerateshipenabled (slot-value shippingmethod 'tablerateshipenabled))
	(ratetablecsv (slot-value shippingmethod 'ratetablecsv)))
    (when tablerateshipenabled ratetablecsv)))



(defun get-shipping-rate-from-table (pincode weight vendor company)
  (let* ((zonename (get-zonename-from-pincode pincode vendor company))
	 (ratetablecsv (getratetablecsv (get-shipping-method-for-vendor vendor company)))
	 (ratetablecontent (if ratetablecsv (cl-csv:read-csv ratetablecsv :skip-first-p T))))
    (if zonename
	(car (remove nil (mapcar (lambda (raterow)
				   (let ((minkg (float (read-from-string (nth 0 raterow))))
					 (maxkg (float (read-from-string (nth 1 raterow))))
					 (zone-a (float (read-from-string (nth 2 raterow))))
					 (zone-b (float (read-from-string (nth 3 raterow))))
					 (zone-c (float (read-from-string (nth 3 raterow))))
					 (zone-d (float (read-from-string (nth 3 raterow))))
					 (zone-e (float (read-from-string (nth 3 raterow)))))
				     (when (and (> weight minkg) (< weight maxkg))
				       (cond ((equal zonename "ZONE-A") zone-a)
					     ((equal zonename "ZONE-B") zone-b)
					     ((equal zonename "ZONE-C") zone-c)
					     ((equal zonename "ZONE-D") zone-d)
					     ((equal zonename "ZONE-E") zone-e))))) ratetablecontent)))
	;;else
	0.00)))
		    

(defun getminorderamt (freeshippingmethod)
  (let ((freeshipenabled (slot-value freeshippingmethod 'freeshipenabled))
	(minorderamt (slot-value freeshippingmethod 'minorderamt)))
    (when freeshipenabled minorderamt)))

(defun getdefaultshippingmethod (shippingmethod)
  (let ((defaultshippingmethod (slot-value shippingmethod 'defaultshippingmethod)))
defaultshippingmethod))


(defun update-shipping-methods (shippingmethod); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance shippingmethod))


;; shipzone for a vendor

(defun get-ship-zones-for-vendor (vendor company)
  (let ((tenant-id (slot-value company 'row-id))
	(vendor-id (slot-value vendor 'row-id)))
    (clsql:select 'dod-vendor-ship-zones  :where
		  [and
		  [= [:deleted-state] "N"]
		  [= [:active-flag] "Y"]
		  [= [:tenant-id] tenant-id]
		  [= [:vendor-id] vendor-id]] :caching *dod-debug-mode* :flatp T )))


(defun get-zonename-from-pincode (pincode vendor company)
  (let* ((shipzones (get-ship-zones-for-vendor vendor company)))
    (car (remove nil (mapcar (lambda (shipzone)
			  (let ((zipcodes (read-from-string (slot-value shipzone 'zipcoderangecsv))))
			    (car (remove nil (mapcar (lambda (zipcode)
						  (when (> (cl-ppcre:count-matches (format nil "^~A" zipcode) pincode) 0)
						    ;;(format T "~A:~A~C" zipcode pincode #\newline)
						    (slot-value shipzone 'zonename))) zipcodes))))) shipzones)))))
	 

(defun persist-vendor-ship-zone (zonename zipcoderangecsv vendor-id tenant-id)
  (clsql:update-records-from-instance (make-instance 'dod-vendor-ship-zones
					 	     :vendor-id vendor-id
						     :tenant-id tenant-id
						     :zonename zonename
						     :zipcoderangecsv zipcoderangecsv
						     :active-flag "Y"
						     :deleted-state "N")))



(defun create-vendor-ship-zone (zonename zipcoderangecsv vendor company)
   (let ((tenant-id (slot-value company 'row-id))
	 (vendor-id (slot-value vendor 'row-id)))
     (persist-vendor-ship-zone zonename zipcoderangecsv vendor-id tenant-id)))




(defun update-vendor-shipzone (shipzone); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance shipzone))



(defun calculate-cartitems-weight-kgs (shopping-cart products)
  (let* ((total-items (reduce #'+ (mapcar (lambda (item) (slot-value item 'prd-qty)) shopping-cart)))
	 (unique-prd-count (length products))
	 (total-weight (/ (* total-items (get-total-of products 'shipping-weight-kg)) unique-prd-count)))
    total-weight))
