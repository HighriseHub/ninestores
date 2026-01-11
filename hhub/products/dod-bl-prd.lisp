;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)




(defun get-all-gst-sac-codes ()
  :documentation "This function stores all the currencies in a hashtable. The Key = country, Value = list of currency, code and symbol."
  (let ((ht (make-hash-table :test 'equal))
	(sac-codes (clsql:select 'dod-gst-sac-codes 
		:caching *dod-database-caching* :flatp t )))
    (loop for saccd in sac-codes do
      (let ((key (slot-value saccd 'sac-code))
	    (value (slot-value saccd 'sac-description)))
	(setf (gethash key ht) value )))
    ; Return  the hash table. 
    ht))


(defun deactivate-product (id company)
  (let ((product (select-product-by-id id company)))
    (setf (slot-value product 'active-flag) "N")
    (update-prd-details product)))

(defun activate-product (id company)
  (let ((product (select-product-by-id id company)))
    (setf (slot-value product 'active-flag) "Y")
    (update-prd-details product)))

(defun get-products-for-approval (tenant-id)
:documentation "This function will be used only by the superadmin user. "
  (clsql:select 'dod-prd-master  :where 
		[and 
		[= [:deleted-state] "N"] 
		[= [:active-flag] "Y"]
		[= [:approved-flag] "N"]
		[= [:tenant-id] tenant-id]
		[= [:approval-status] "PENDING"]]
		:caching *dod-database-caching* :flatp t ))



(defun get-products-for-approval-by-company (tenant-id)
  :documentation "This function will be used by the company administrator"
  (clsql:select 'dod-prd-master  :where 
		[and 
		[= [:deleted-state] "N"] 
		[= [:active-flag] "Y"]
		[= [:tenant-id] tenant-id]
		[= [:approved-flag] "N"]]
		:caching *dod-database-caching* :flatp t ))

(defun get-products (tenant-id)
  (clsql:select 'dod-prd-master  :where 
		[and 
		[= [:deleted-state] "N"] 
		[= [:active-flag] "Y"]
		[= [:approved-flag] "Y"]
		[= [:tenant-id] tenant-id]]    :caching *dod-database-caching* :flatp t ))

(defun select-products-by-company (company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
    (clsql:select 'dod-prd-master  :where
		  [and 
		  [= [:active-flag] "Y"] 
		  [= [:deleted-state] "N"]
		  [= [:approved-flag] "Y"]
		  [= [:tenant-id] tenant-id]] :limit 500 :order-by '(([row-id] :desc)) 
					      :caching *dod-database-caching* :flatp t )))

(defun select-products-by-vendor (vendor company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id))
	(vendor-id (slot-value vendor 'row-id)))
    (clsql:select 'dod-prd-master  :where
		  [and 
		  [= [:deleted-state] "N"]
		  [= [:tenant-id] tenant-id]
		  [=[:vendor-id] vendor-id]]  :limit 200 :order-by '( ([row-id] :desc)) 
					      :caching *dod-database-caching* :flatp t )))

(defun select-active-products-by-vendor (vendor company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id))
	(vendor-id (slot-value vendor 'row-id)))
    (clsql:select 'dod-prd-master  :where
		  [and 
		  [= [:deleted-state] "N"]
		  [= [:tenant-id] tenant-id]
		  [= [:active-flag] "Y"]
		  [= [:approved-flag] "Y"]  
		  [=[:vendor-id] vendor-id]]  :limit 200 :order-by '(([row-id] :desc)) 
					      :caching *dod-database-caching* :flatp t )))


(defun search-item-in-list (key value list)
  (if (equal value (slot-value (car list) key))
      (car list)
      ;;else
      (search-item-in-list key value (cdr list))))

(defun filter-products-by-category (category-id list)
  (remove nil (mapcar (lambda (item)
			(if (equal category-id (slot-value item 'catg-id)) item)) list)))

(defun filter-products-by-vendor (vendor-id list)
  (remove nil (mapcar (lambda (item)
			(if (equal vendor-id (slot-value item 'vendor-id)) item)) list)))


(defun prdinlist-p  (prd-id list)
  (member prd-id (mapcar (lambda (item)
			   (slot-value item 'prd-id)) list) :test #'equal))

(defun iteminlist-p  (key value list)
  (member value (mapcar (lambda (item)
			  (slot-value item key)) list) :test #'equal))


(defun select-product-by-id (id company-instance ) 
  (let ((tenant-id (slot-value company-instance 'row-id)))
 (car (clsql:select 'dod-prd-master  :where
		[and 
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[=[:row-id] id]]    :caching *dod-database-caching* :flatp t ))))

(defun select-product-pricing-by-id (id company-instance ) 
  (let ((tenant-id (slot-value company-instance 'row-id)))
    (car (clsql:select 'dod-product-pricing  :where
		       [and
		       [= [:active-flag] "Y"]
		       [= [:deleted-state] "N"]
		       [= [:tenant-id] tenant-id]
		       [=[:row-id] id]]    :caching *dod-database-caching* :flatp t ))))

(defun select-product-pricing-by-product-id (product-id company-instance ) 
  (let ((tenant-id (slot-value company-instance 'row-id)))
    (car (clsql:select 'dod-product-pricing  :where
		       [and
		       [= [:active-flag] "Y"]
		       [= [:deleted-state] "N"]
		       [= [:product-id] product-id]
		       [= [:tenant-id] tenant-id]]
		        :caching *dod-database-caching* :flatp t ))))

(defun select-product-pricing-by-startdate (product-id start-date company-instance ) 
  (let ((tenant-id (slot-value company-instance 'row-id)))
    (car (clsql:select 'dod-product-pricing  :where
		       [and
		       [= [:active-flag] "Y"]
		       [= [:deleted-state] "N"]
		       [= [:start-date] start-date]
		       [= [:product-id] product-id]
		       [= [:tenant-id] tenant-id]]
		        :caching *dod-database-caching* :flatp t ))))

(defun select-products-by-category (catg-id company-instance )
    (let ((tenant-id (slot-value company-instance 'row-id)))
	(clsql:select 'dod-prd-master :where [and
		 [= [:deleted-state] "N"]
		[= [:active-flag] "Y"] 
		[= [:approved-flag] "Y"]
		[= [:tenant-id] tenant-id]
		[= [:catg-id] catg-id]]
				      :caching *dod-database-caching* :flatp t)))


(defun select-product-by-name (name-like-clause company-instance )
  (let ((tenant-id (slot-value company-instance 'row-id)))
    (car (clsql:select 'dod-prd-master :where [and
		       [= [:deleted-state] "N"]
		       [= [:active-flag] "Y"] 
		       [= [:approved-flag] "Y"]
		       [= [:tenant-id] tenant-id]
		       [like  [:prd-name] name-like-clause]]
				       :caching *dod-database-caching* :flatp t))))


(defun search-products ( search-string company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
    (clsql:select 'dod-prd-master :where [and
		  [= [:deleted-state] "N"]
		  [= [:active-flag] "Y"]
		  [= [:approved-flag] "Y"]
		  [= [:tenant-id] tenant-id] 
		  [like [:prd-name] (format NIL "%~a%" search-string)]]
		  :caching *dod-database-caching* :flatp t)))


(defun update-prd-details (prd-instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance prd-instance))

(defun delete-product( id company-instance)
  (let* ((tenant-id (slot-value company-instance 'row-id))
	 (dodproduct (car (clsql:select 'dod-prd-master :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodproduct 'deleted-state) "Y")
    (clsql:update-record-from-slot dodproduct 'deleted-state)))

(defun delete-product-pricing (id company-instance)
  (let* ((tenant-id (slot-value company-instance 'row-id))
	 (prdpricing (car (clsql:select 'dod-product-pricing :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value prdpricing 'deleted-state) "Y")
    (clsql:update-record-from-slot prdpricing 'deleted-state)))

(defun delete-products ( list company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (mapcar (lambda (id)  (let ((dodproduct (car (clsql:select 'dod-prd-master :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
			  (setf (slot-value dodproduct 'deleted-state) "Y")
			  (clsql:update-record-from-slot dodproduct  'deleted-state))) list )))


(defun restore-deleted-products ( list company-instance )
    (let ((tenant-id (slot-value company-instance 'row-id)))
(mapcar (lambda (id)  (let ((dodproduct (car (clsql:select 'dod-prd-master :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodproduct 'deleted-state) "N")
    (clsql:update-record-from-slot dodproduct 'deleted-state))) list )))

(defun setAsSalesProduct (product)
  :documentation "Sets the Product type as Sales Product"
  (setf (slot-value product 'prd-type) "SALE")
  (update-prd-details product))
  

(defun setAsServiceProduct (product)
  :documentation "Sets the Product type as Service Product"
  (setf (slot-value product 'prd-type) "SRVC")
  (update-prd-details product))

   
(defun persist-product-pricing (product-id price discount currency start-date end-date tenant-id)
  (clsql:update-records-from-instance (make-instance 'dod-product-pricing
						     :product-id product-id
						     :price price
						     :discount discount
						     :currency currency
						     :start-date start-date
						     :end-date end-date
						     :active-flag "Y"
						     :tenant-id tenant-id
						     :deleted-state "N")))

(defun create-product-pricing (product price discount currency start-date end-date company)
  (let ((product-id (slot-value product 'row-id))
	(tenant-id (slot-value company 'row-id)))
    (persist-product-pricing product-id price discount currency start-date end-date tenant-id)))
						     
  
(defun persist-product(prdname description vendor-id catg-id sku hsn-code qtyperunit unitofmeasure units-in-stock img-file-path subscribe-flag prd-type tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-prd-master
				    :prd-name prdname
				    :description description
				    :vendor-id vendor-id
				    :catg-id catg-id
				    :sku sku
				    :hsn-code hsn-code
				    :qty-per-unit qtyperunit
				    :unit-of-measure unitofmeasure
				    :current-price 1.00
				    :current-discount 0.00
				    :units-in-stock units-in-stock
				    :prd-image-path img-file-path
				    :subscribe-flag subscribe-flag
				    :tenant-id tenant-id
				    :active-flag "Y"
				    :approved-flag "N"
				    :approval-status "PENDING"
				    :prd-type prd-type
				    :product-code (format nil "PRD-~A" (hhub-random-password 10))
				    :deleted-state "N")))

(defun create-bulk-products (modelfunc)
  (multiple-value-bind (productsdata) (funcall modelfunc)
    (mapcar (lambda (prddata)
	      (let* ((product (first prddata))
		     (product-pricing (second prddata))
		     (prd-id (slot-value product 'row-id))
		     (company (product-company product))
		     (db-product (select-product-by-id prd-id company))
		     (db-product-pricing (select-product-pricing-by-product-id prd-id company)))
		(if db-product
		    (with-slots (prd-name  qty-per-unit unit-of-measure current-price current-discount units-in-stock subscribe-flag) product
		      (setf (slot-value db-product 'prd-name) prd-name)
		      (setf (slot-value db-product 'qty-per-unit) qty-per-unit)
		      (setf (slot-value db-product 'unit-of-measure) unit-of-measure)
		      (setf (slot-value db-product 'current-price) current-price)
		      (setf (slot-value db-product 'current-discount) current-discount)
		      (setf (slot-value db-product 'units-in-stock) units-in-stock)
		      (setf (slot-value db-product 'subscribe-flag) subscribe-flag)
		      (clsql:update-records-from-instance db-product))
		    ;;else
		    (clsql:update-records-from-instance product))
		;; Will update product pricing only if a product exists. 
		(if (and db-product product-pricing (check-null product-pricing))
		    (with-slots (price discount start-date end-date) product-pricing
		      (setf (slot-value db-product-pricing 'price) price)
		      (setf (slot-value db-product-pricing 'discount) discount)
		      (setf (slot-value db-product-pricing 'start-date) start-date)
		      (setf (slot-value db-product-pricing 'end-date) end-date)
		      (clsql:update-records-from-instance db-product-pricing))))) productsdata)))

(defun create-product (prdname description  vendor-instance category sku hsn-code qty-per-unit unit-of-measure units-in-stock img-file-path subscribe-flag prd-type company-instance)
  (let ((vendor-id (slot-value vendor-instance 'row-id))
	(catg-id (if category (slot-value category 'row-id)))
	(tenant-id (slot-value company-instance 'row-id)))
    (handler-case
	(clsql:with-transaction ()
	  (persist-product prdname description vendor-id catg-id sku hsn-code qty-per-unit unit-of-measure units-in-stock img-file-path subscribe-flag prd-type  tenant-id)
	  (let* ((result (clsql:query "SELECT LAST_INSERT_ID()"))
		 (product-id (car result))
		 (newprd (select-product-by-id product-id company-instance)))
	    (create-product-pricing newprd 1.00 0.00 (get-account-currency company-instance) (clsql:get-date) (clsql:date+ (clsql:get-date) (clsql-sys:make-duration :day 90)) company-instance))) 
      (error (e)
	(format t "Transaction failed: ~A~%" e)))))

;(defun copy-products (src-company dst-company)
;    (let ((prdlist (select-products-by-company src-company)))
;	(mapcar (lambda (prd)
;		    (let ((temp  (setf (product-company prd) dst-company)))
;		    (clsql:update-records-from-instance prd ))) prdlist)))
	     
	      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;PRODUCT CATEGORY RELATED FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



(defun get-prod-cat (tenant-id)
  (clsql:select 'dod-prd-catg  :where 
		[and 
		[= [:deleted-state] "N"] 
		[= [:active-flag] "Y"] 
		[= [:tenant-id] tenant-id]]    :caching nil :flatp t ))

(defun get-root-prd-catg (tenant-id)
  (clsql:select 'dod-prd-catg  :where 
		[and 
		[= [:deleted-state] "N"] 
		[= [:active-flag] "Y"] 
		[= [:tenant-id] tenant-id]
		[= [:catg-name] "root"]]    :caching nil :flatp t ))


(defun select-prdcatg-by-company (company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
    (clsql:select 'dod-prd-catg  :where
		  [and 
		  [= [:deleted-state] "N"]
		  [= [:active-flag] "Y"]
		  [<> [:catg-name] "root"]
		  [= [:tenant-id] tenant-id]]
     :caching nil :flatp t )))


(defun search-prdcatg-in-list (row-id list)
  (if (not (equal row-id (slot-value (car list) 'row-id))) (search-prdcatg-in-list row-id (cdr list))
	(car list)))

(defun prdcatginlist-p  (row-id list)
  (member row-id  (mapcar (lambda (item)
			    (slot-value item 'row-id)) list)))


(defun select-prdcatg-by-id (id company-instance ) 
  (let ((tenant-id (slot-value company-instance 'row-id)))
 (car (clsql:select 'dod-prd-catg  :where
		[and [= [:deleted-state] "N"]
		[= [:active-flag] "Y"] 
		[= [:tenant-id] tenant-id]
		[=[:row-id] id]]    :caching *dod-database-caching* :flatp t ))))



  (defun select-prdcatg-by-name (name-like-clause company-instance )
      (let ((tenant-id (slot-value company-instance 'row-id)))
  (car (clsql:select 'dod-prd-catg :where [and
		[= [:deleted-state] "N"]
		[= [:active-flag] "Y"] 
		[= [:tenant-id] tenant-id]
		[like  [:catg-name] name-like-clause]]
		:caching *dod-database-caching* :flatp t))))

(defun add-root-prdcatg (company-instance)                                                                                                                                                    
  (let ((tenant-id (slot-value company-instance 'row-id)))                                                                                                                                    
    (persist-prdcatg "root" 1 2 tenant-id)))


(defun add-new-node-prdcatg (name company-instance) 
  (let* ((tenant-id (slot-value company-instance 'row-id))
	 (rootprdcatg (get-root-prd-catg tenant-id))
	 (query1 (format nil "SELECT @myRight := rgt FROM DOD_PRD_CATG  WHERE catg_name = 'root' and tenant_id=~A; " tenant-id))
	 (command1 (format nil "UPDATE DOD_PRD_CATG  SET rgt = rgt + 2 WHERE rgt > @myRight;" ))
	 (command2 (format nil "UPDATE DOD_PRD_CATG SET lft = lft + 2 WHERE lft > @myRight; "))
	 (command3 (format nil "INSERT INTO DOD_PRD_CATG (catg_name, lft, rgt, tenant_id, active_flag, deleted_state ) VALUES('~A', @myRight + 1, @myRight + 2, ~A, 'Y', 'N');" name tenant-id)))
    ;; if root prd category is not present, create it first. 
    (unless rootprdcatg
      (add-root-prdcatg company-instance))
    ;; sleep for a second after creating a root prd category because we are going to query for it again. We do not want to fail.
    (sleep 1)
    (clsql:query query1 :field-names nil :flatp t)
    (clsql:execute-command command1 )
    (clsql:execute-command command2 )
    (clsql:execute-command command3 )))
    


(defun add-new-prdcatg-node-as-child (parentname childname  company-instance) 
  (let* ((tenant-id (slot-value company-instance 'row-id))
	 (query (format nil "SELECT @myLeft := lft FROM DOD_PRD_CATG WHERE catg_name = '~A' and tenant_id=~A;" parentname tenant-id))
	 (command2 (format nil "UPDATE DOD_PRD_CATG  SET rgt = rgt + 2 WHERE rgt > @myLeft;"))
	 (command3 (format nil "UPDATE DOD_PRD_CATG  SET lft = lft + 2 WHERE lft > @myLeft;"))
	 (command4 (format nil "INSERT INTO DOD_PRD_CATG (catg_name, lft, rgt, tenant_id, active_flag, deleted_state) VALUES('~A', @myLeft + 1, @myLeft + 2, ~A, 'Y', 'N');" childname tenant-id)))

  (clsql:query query :field-names nil :flatp t)
    (clsql:execute-command command2 )
    (clsql:execute-command command3 )
    (clsql:execute-command command4 )))


(defun delete-prd-catg (id company)
  (let* ((tenant-id (slot-value company 'row-id))
	 (query (format nil "SELECT @myLeft := lft, @myRight := rgt, @myWidth := rgt - lft + 1 FROM DOD_PRD_CATG  WHERE row_id = ~A and tenant_id=~A" id tenant-id))
	 (command1 (format nil "DELETE FROM DOD_PRD_CATG WHERE lft BETWEEN @myLeft AND @myRight;"))
	 (command2 (format nil "UPDATE DOD_PRD_CATG  SET rgt = rgt - @myWidth WHERE rgt > @myRight;"))
	 (command3 (format nil "UPDATE DOD_PRD_CATG  SET lft = lft - @myWidth WHERE lft > @myRight;")))
    
    (clsql:query query :field-names nil :flatp t)
    (clsql:execute-command command1 )
    (clsql:execute-command command2 )
    (clsql:execute-command command3 )))


(defun update-prdcatg (prdcatg-inst); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance prdcatg-inst))

(defun delete-prdcatg( id company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (let ((dodprdcatg (car (clsql:select 'dod-prd-catg :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodprdcatg 'deleted-state) "Y")
    (clsql:update-record-from-slot dodprdcatg 'deleted-state))))



(defun delete-prdcatgs ( list company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (mapcar (lambda (id)  (let ((dodprdcatg (car (clsql:select 'dod-prd-catg :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
			  (setf (slot-value dodprdcatg 'deleted-state) "Y")
			  (clsql:update-record-from-slot dodprdcatg  'deleted-state))) list )))


(defun restore-deleted-prdcatgs ( list company-instance )
    (let ((tenant-id (slot-value company-instance 'row-id)))
(mapcar (lambda (id)  (let ((dodprdcatg (car (clsql:select 'dod-prd-catg :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodprdcatg 'deleted-state) "N")
    (clsql:update-record-from-slot dodprdcatg 'deleted-state))) list )))

   

  
(defun persist-prdcatg(catgname lft rgt tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-prd-catg
				    :catg-name catgname
				    :lft lft
				    :rgt rgt 
				    :tenant-id tenant-id
				    :active-flag "Y"
				    :deleted-state "N")))
 


(defun create-prdcatg (catgname lft rgt  company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
      (persist-prdcatg catgname lft rgt tenant-id)))


