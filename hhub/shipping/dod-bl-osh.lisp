;;; dod-bl-osh.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
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
  (let ((shpmethod (car (clsql:select 'dod-shipping-methods  :where
				      [and
				      [= [:deleted-state] "N"]
				      [= [:active-flag] "Y"]
				      [= [:tenant-id] tenant-id]
				      [= [:vendor-id] vendor-id]] :caching *dod-debug-mode* :flatp T ))))
    ;; if we do not have a shipping method defined for a vendor, then create one.
    ;; making sure we only have one shipping method defined per vendor.
    (unless shpmethod 		   
      (clsql:update-records-from-instance (make-instance 'dod-shipping-methods
							 :minorderamt minordamt
							 :vendor-id vendor-id
							 :tenant-id tenant-id
							 :freeshipenabled "Y"
							 :active-flag "Y"
							 :deleted-state "N")))))



(defun create-free-shipping-method (minordamt vendor company)
   (let ((tenant-id (slot-value company 'row-id))
	 (vendor-id (slot-value vendor 'row-id)))
     (persist-free-shipping-method minordamt vendor-id tenant-id)))


;;; ── the delivery-charge PRODUCT every vendor needs ────────────────────────────────────────────
;;; The charge prints as a LINE and a line needs a product row (FK on PRD_ID): same row the backfill migration seeds, whose literals are duplicated because it must also run standalone.
(defparameter *freight-product-name* "Freight & Shipping charges"
  "The invoice line's description. DOD_PRD_MASTER.PRD_NAME is varchar(70) - keep it short.")

(defparameter *freight-product-hsn* "9965"
  "SAC 9965 (goods transport services) shown as the line's HSN. 🚨 THE RATE IS NOT READ FROM IT: the delivery charge is a composite supply taxed at the principal goods line's rate, see gst-tax-jurisdiction-CONTEXT.md §1.")

(defparameter *freight-product-description*
  "Delivery charges on an order; taxed with the goods it accompanies.")

(defun create-freight-product-for-vendor (vendor company)
  :documentation "Seed the vendor's delivery-charge product (PRODUCT_CODE FREIGHT-<vendor-id>), idempotent on that code. Without it `nst-select-freight-product` finds nothing and `nst-cart-with-delivery-line` silently drops the delivery line - a new vendor's orders then arrive with no shipping charge to invoice. Auto-approved: it is a system row, not a vendor listing."
  (let* ((vendor-id (slot-value vendor 'row-id))
	 (tenant-id (slot-value company 'row-id))
	 (code (format nil "FREIGHT-~D" vendor-id)))
    (if (clsql:query (format nil "SELECT ROW_ID FROM DOD_PRD_MASTER WHERE PRODUCT_CODE = '~A' LIMIT 1"
			     (sql-literal code)))
	nil
	(progn
	  (clsql:execute-command
	   (format nil "INSERT INTO DOD_PRD_MASTER
                          (PRODUCT_CODE, PRD_NAME, DESCRIPTION, HSN_CODE, QTY_PER_UNIT, UNIT_OF_MEASURE,
                           CURRENT_PRICE, CURRENT_DISCOUNT, PRD_TYPE, APPROVED_FLAG, ACTIVE_FLAG,
                           UNITS_IN_STOCK, DELETED_STATE, VENDOR_ID, TENANT_ID)
                        VALUES
                          ('~A', '~A', '~A', '~A', '1.0', 'NOS', 0.00, 0.00, 'SERV', 'Y', 'Y', 1, 'N', ~D, ~D)"
			(sql-literal code)
			(sql-literal *freight-product-name*)
			(sql-literal *freight-product-description*)
			(sql-literal *freight-product-hsn*)
			vendor-id tenant-id))
	  t))))


(defun getratetablecsv (shippingmethod)
  (let ((tablerateshipenabled (slot-value shippingmethod 'tablerateshipenabled))
	(ratetablecsv (slot-value shippingmethod 'ratetablecsv)))
    (when tablerateshipenabled ratetablecsv)))

(defun getflatrateprice (shippingmethod)
  (let ((flatrateshipenabled (slot-value shippingmethod 'flatrateshipenabled))
	(flatrateprice (slot-value shippingmethod 'flatrateprice)))
    (when flatrateshipenabled flatrateprice)))

(defun getflatratetype (shippingmethod)
  (let ((flatrateshipenabled (slot-value shippingmethod 'flatrateshipenabled))
	(flatratetype (slot-value shippingmethod 'flatratetype)))
    (when flatrateshipenabled flatratetype)))



(defun get-shipping-rate-from-table (pincode weight vendor company)
  (let* ((zonename (get-zonename-from-pincode pincode vendor company))
	 (ratetablecsv (getratetablecsv (get-shipping-method-for-vendor vendor company)))
	 (ratetablecontent (if ratetablecsv (cl-csv:read-csv ratetablecsv :skip-first-p T))))
    (with-nst-error-handler
	(if (< weight 0.5)
	    (error "Items weight in shopping cart is less than 0.5KG.")) 'nst-shipping-error)
    (if zonename
	(car (remove nil (mapcar (lambda (raterow)
				   (let ((minkg (float (read-from-string (nth 0 raterow))))
					 (maxkg (float (read-from-string (nth 1 raterow))))
					 (zone-a (float (read-from-string (nth 2 raterow))))
					 (zone-b (float (read-from-string (nth 3 raterow))))
					 (zone-c (float (read-from-string (nth 4 raterow))))
					 (zone-d (float (read-from-string (nth 5 raterow))))
					 (zone-e (float (read-from-string (nth 6 raterow)))))
				     (when (and (>= weight minkg) (<= weight maxkg))
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
			       ;; SECURITY: *read-eval* MUST stay nil here. ZIPCODERANGECSV is
			       ;; a varchar(1024) written by the vendor shipping-zone form
			       ;; (dod-ui-ven.lisp, create-vendor-ship-zone) and read back on a
			       ;; CUSTOMER checkout (dod-ui-cus.lisp, get-shipping-rate). The
			       ;; default reader EVALUATES #. — so without this binding a vendor
			       ;; could store "#.(...)" in a zone and have it executed in this
			       ;; image the next time any customer entered a pincode. The ollama
			       ;; tooling guards this; the shipping path did not.
			       ;; The reader stays because the stored values are Lisp lists of
			       ;; REGEX FRAGMENTS, not just digit prefixes: live rows contain
			       ;; "(577* 560001 ...)", "(0)", "()" and an embedded newline, and
			       ;; each token is used as (format nil "^~A" token). A naive
			       ;; splitter would change matching. Replacing the reader with a
			       ;; real tokeniser is a follow-up that needs a test over all 20
			       ;; live rows.
			       (let ((zipcodes (let ((*read-eval* nil))
						 (read-from-string (slot-value shipzone 'zipcoderangecsv)))))
				 (when zipcodes
				   (car (remove nil (mapcar (lambda (zipcode)
							      (when (> (cl-ppcre:count-matches (format nil "^~A" zipcode) pincode) 0)
								;;(format T "~A:~A~C" zipcode pincode #\newline)
								(slot-value shipzone 'zonename))) zipcodes)))))) shipzones)))))
  

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
