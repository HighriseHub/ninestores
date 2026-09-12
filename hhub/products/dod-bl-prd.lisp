;;; dod-bl-prd.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

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
  (find value list 
        :test #'equal 
        :key (lambda (item) (slot-value item key))))



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


;;; ═══════════════════════════════════════════════════════════════════════════
;;; copyProduct-domaintodb / copyProduct-dbtodomain
;;;
;;; The two legs of the लोप crossing between the domain entity (nst-prd,
;;; products/dod-dal-prd.lisp) and the CLSQL view-class (dod-prd-master). Same
;;; shape as copyWarehouse-* in nst-bl-warehouse.lisp — source is read with
;;; slot-value, destination is written through with-slots — with three
;;; product-specific decisions worth stating out loud:
;;;
;;;   1. TENANT COMES FROM THE `company` SLOT, the company OBJECT, not from the
;;;      entity's inherited tenant-id. Reason: DOD_PRD_MASTER.TENANT_ID is an FK
;;;      to DOD_COMPANY.ROW_ID, and nst-prd's :company initarg is exactly the
;;;      legacy slot the internal web form already passes and the JSON API
;;;      injects (:inject-company). Reading the object means a missing company
;;;      signals instead of silently writing a NULL tenant.
;;;
;;;   2. deleted-state IS FORCED TO "N" on the inbound leg. An INSERT is by
;;;      definition not a deletion, and DELETED_STATE is nullable with no column
;;;      default — so leaving it to the entity would write NULL, and every later
;;;      [= [:deleted-state] "N"] read would miss the row.
;;;
;;;   3. product-code IS NOT GENERATED HERE. make generates it before calling
;;;      this copier: PRODUCT_CODE is NOT NULL + UNIQUE with no column default,
;;;      and a copier cannot invent an identity.
;;;
;;; row-id is deliberately NOT written on the inbound leg — it is AUTO_INCREMENT
;;; and is bound onto the entity afterwards by bind-generated-row-id.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun copyProduct-domaintodb (source destination)
  "nst-prd → dod-prd-master. See the header above for decisions 1–3."
  ;; NOTE the slot name: the DOMAIN class calls it prd-company (its :initarg is
  ;; :company — that is the name the web form posts and the API injects). Reading
  ;; 'company here would signal unbound-slot on every insert.
  (let ((company (slot-value source 'prd-company)))
    (with-slots (prd-name description vendor-id catg-id qty-per-unit
                 unit-of-measure prd-image-path current-price current-discount
                 units-in-stock hsn-code sku upc ean jan isbn serial-no
                 external-url shipping-length-cms shipping-width-cms
                 shipping-height-cms shipping-weight-kg
                 active-flag deleted-state subscribe-flag approved-flag
                 approval-status prd-type product-code tenant-id)
        destination
      ;; CATALOG DESCRIPTION
      (setf prd-name          (slot-value source 'prd-name))
      (setf description       (slot-value source 'description))
      (setf vendor-id         (slot-value source 'vendor-id))
      (setf catg-id           (slot-value source 'catg-id))
      (setf sku               (slot-value source 'sku))
      (setf hsn-code          (slot-value source 'hsn-code))
      (setf prd-type          (slot-value source 'prd-type))
      (setf unit-of-measure   (slot-value source 'unit-of-measure))
      (setf qty-per-unit      (slot-value source 'qty-per-unit))
      (setf units-in-stock    (slot-value source 'units-in-stock))
      (setf prd-image-path    (slot-value source 'prd-image-path))
      (setf external-url      (slot-value source 'external-url))
      ;; TRADE IDENTIFIERS
      (setf upc               (slot-value source 'upc))
      (setf ean               (slot-value source 'ean))
      (setf jan               (slot-value source 'jan))
      (setf isbn              (slot-value source 'isbn))
      (setf serial-no         (slot-value source 'serial-no))
      ;; PRICING (current values; tiers are dod-product-pricing)
      (setf current-price     (slot-value source 'current-price))
      (setf current-discount  (slot-value source 'current-discount))
      ;; SHIPPING
      (setf shipping-length-cms (slot-value source 'shipping-length-cms))
      (setf shipping-width-cms  (slot-value source 'shipping-width-cms))
      (setf shipping-height-cms (slot-value source 'shipping-height-cms))
      (setf shipping-weight-kg  (slot-value source 'shipping-weight-kg))
      ;; LIFECYCLE — three independent columns
      (setf active-flag       (slot-value source 'active-flag))
      (setf approved-flag     (slot-value source 'approved-flag))
      (setf approval-status   (slot-value source 'approval-status))
      (setf subscribe-flag    (slot-value source 'subscribe-flag))
      ;; IDENTITY — supplied by make, never invented here
      (setf product-code      (slot-value source 'product-code))
      ;; INVARIANTS
      (setf deleted-state     "N")                        ; see decision 2
      (setf tenant-id         (slot-value company 'row-id)) ; see decision 1
      destination)))

(defun copyProduct-dbtodomain (source destination)
  "dod-prd-master → nst-prd. The inbound direction of the crossing.

   Row-id and every business field are copied. TENANT_ID AND COMPANY ARE NOT:
   the caller constructs the nst-prd with :tenant-id from the domain-ctx (so
   that नियम-1 has something to check) and re-attaches the company object
   itself when a later write needs it — exactly as fetch does for nst-whs."
  (with-slots (row-id prd-name description vendor-id catg-id qty-per-unit
               unit-of-measure prd-image-path current-price current-discount
               units-in-stock hsn-code sku upc ean jan isbn serial-no
               external-url shipping-length-cms shipping-width-cms
               shipping-height-cms shipping-weight-kg
               active-flag subscribe-flag approved-flag approval-status
               prd-type product-code)
      destination
    (setf row-id            (slot-value source 'row-id))
    ;; CATALOG DESCRIPTION
    (setf prd-name          (slot-value source 'prd-name))
    (setf description       (slot-value source 'description))
    (setf vendor-id         (slot-value source 'vendor-id))
    (setf catg-id           (slot-value source 'catg-id))
    (setf sku               (slot-value source 'sku))
    (setf hsn-code          (slot-value source 'hsn-code))
    (setf prd-type          (slot-value source 'prd-type))
    (setf unit-of-measure   (slot-value source 'unit-of-measure))
    (setf qty-per-unit      (slot-value source 'qty-per-unit))
    (setf units-in-stock    (slot-value source 'units-in-stock))
    (setf prd-image-path    (slot-value source 'prd-image-path))
    (setf external-url      (slot-value source 'external-url))
    ;; TRADE IDENTIFIERS
    (setf upc               (slot-value source 'upc))
    (setf ean               (slot-value source 'ean))
    (setf jan               (slot-value source 'jan))
    (setf isbn              (slot-value source 'isbn))
    (setf serial-no         (slot-value source 'serial-no))
    ;; PRICING
    (setf current-price     (slot-value source 'current-price))
    (setf current-discount  (slot-value source 'current-discount))
    ;; SHIPPING
    (setf shipping-length-cms (slot-value source 'shipping-length-cms))
    (setf shipping-width-cms  (slot-value source 'shipping-width-cms))
    (setf shipping-height-cms (slot-value source 'shipping-height-cms))
    (setf shipping-weight-kg  (slot-value source 'shipping-weight-kg))
    ;; LIFECYCLE
    (setf active-flag       (slot-value source 'active-flag))
    (setf approved-flag     (slot-value source 'approved-flag))
    (setf approval-status   (slot-value source 'approval-status))
    (setf subscribe-flag    (slot-value source 'subscribe-flag))
    ;; IDENTITY
    (setf product-code      (slot-value source 'product-code))
    destination))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Tier-1 प्रत्यय for nst-prd — ?exists (प्रत्यभिज्ञा) and make (सृजन)
;;;
;;; Shapes follow nst-whs in nst-bl-warehouse.lisp, the verified reference. Every
;;; product-specific difference below is a consequence of the DOD_PRD_MASTER
;;; schema, and each one is stated where it bites.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun generate-product-code ()
  "PRODUCT_CODE generator: \"PRD-\" + 10 random characters — the exact shape
   persist-product already writes and that the live rows carry (PRD-MPJ165U1Q7).

   Deliberately a FUNCTION and not the class's :void-value on product-code: a
   :void-value expression is evaluated ONCE, when the class is defined, so it
   would hand every product the SAME code and the unique key would reject the
   second insert. See the note on nst-prd in dod-dal-prd.lisp."
  (format nil "PRD-~A" (hhub-random-password 10)))

(defun select-product-by-code (product-code &key include-deleted)
  "Lookup by PRODUCT_CODE — the only identity the database enforces on
   DOD_PRD_MASTER (UNIQUE NOT NULL; the table even carries that key twice, as
   PRODUCT_CODE and PRODUCT_CODE_2).

   DELIBERATELY NOT TENANT-SCOPED. The unique index is GLOBAL, so a code held by
   another tenant's product still occupies it and an INSERT carrying that code
   is refused no matter which tenant is asking. A tenant-scoped pre-check would
   therefore answer 'free' in exactly the case where the write is about to
   fail — the pre-check would predict the wrong thing. Mirroring the key is the
   honest option, and the price accepted is that ?exists confirms *that* a code
   is taken without saying by whom: the caller learns nothing about the other
   tenant's row beyond the collision itself.

   :INCLUDE-DELETED T returns the row whatever its DELETED_STATE, which is what
   makes the soft-delete contradiction detectable — see ?exists."
  (if include-deleted
      (clsql:select 'dod-prd-master
                    :where [= [:product-code] product-code]
                    :caching *dod-database-caching* :flatp t)
      ;; The `:deleted-state "N"` reading relies on the view-class's
      ;; :void-value "N", which is how this schema's nullable char(1) flags are
      ;; mapped (NULL ↔ "N") — the same convention every other selector here
      ;; already uses.
      (clsql:select 'dod-prd-master
                    :where [and [= [:deleted-state] "N"]
                                [= [:product-code] product-code]]
                    :caching *dod-database-caching* :flatp t)))

(defmethod ?exists ((entity-class (eql 'nst-prd)) (product-code string)
                    (ctx domain-ctx) &key &allow-other-keys)
  "Is the product identity PRODUCT_CODE already taken?

   A Belnap answer, because the honest answer is not yes/no:
     :F  free — nothing holds the code and creation may proceed
     :T  a LIVE product holds it (a plain fact of existence)
     :C  a SOFT-DELETED row holds it. DOD_PRD_MASTER still carries the row and
         the unique index on PRODUCT_CODE includes no DELETED_STATE, while
         नियम-2 makes DELETED_STATE='Y' rows invisible to every verb — so 'the
         code is taken' and 'no product is there' are both true at once. Callers
         must escalate to a human; reading this as free would only move the
         failure to the unique key, with a misleading message.
     :U  the database could not be consulted — which is NOT 'probably free'.

   &key &allow-other-keys is required for CLOS congruence with the generic
   function declared in nst-bl-adhara.lisp, even though the product identity is
   a single column needing no extra lookup value (nst-whs needs WNAME, because
   its key is the tuple (GSTIN, name, tenant))."
  (let ((knowledge (with-db-call
                       (select-product-by-code product-code :include-deleted t)
                     "nst-prd/?exists (product-code, deleted rows included)")))
    (cond
      ;; Free, unknown, or the (impossible under a unique key) multi-row :C —
      ;; pass through whatever the database reported.
      ((not (eq (bo-knowledge-truth knowledge) :T)) knowledge)
      ;; dod-prd-master declares NO accessor for deleted-state, so read the slot
      ;; rather than reusing the domain entity's accessor of the same name.
      ((string= (slot-value (bo-knowledge-payload knowledge) 'deleted-state) "Y")
       ;; Identity held by a row the domain considers gone: :T (it is there) ⊔
       ;; :F (no product there) = :C, the provenance recording which two rules
       ;; collided.
       (bo-merge knowledge
                 (make-bo-knowledge
                  :truth :F
                  :payload nil
                  :provenance "नियम-2: DELETED_STATE='Y' rows are invisible to every verb")))
      (t knowledge))))

(defmethod make :before ((entity-class (eql 'nst-prd)) (ctx domain-ctx) &rest initargs)
  "Refuse BEFORE the INSERT is attempted. Only a CONFIRMED-FREE identity passes:
   :U is not 'probably free', and :C is a question for a human.

   Skips silently when no :product-code was supplied, because make generates one
   in that case and a freshly generated code cannot pre-exist."
  (let ((code (getf initargs :product-code)))
    (when code
      (let* ((check (?exists 'nst-prd code ctx))
             (truth (bo-knowledge-truth check)))
        (case truth
          (:F nil)                                  ; confirmed free — proceed
          (:T (error "PRODUCT_CODE ~A: a LIVE product already holds this code. Refusing to create." code))
          (:C (error "PRODUCT_CODE ~A: the code is held by a SOFT-DELETED product. The row is still in DOD_PRD_MASTER and the unique index on PRODUCT_CODE includes no DELETED_STATE, while नियम-2 makes it invisible to every verb. Human decision needed: undelete that product, or create this one under a different code. Refusing to create." code))
          (otherwise
           (error "PRODUCT_CODE ~A: uniqueness check returned ~A, not confirmed-available (:F). Refusing to create." code truth)))))))

(defmethod make ((entity-class (eql 'nst-prd)) (ctx domain-ctx) &rest initargs)
  "सृजन प्रत्यय — create one product.

   कारक: the tenant comes from ctx alone (नियम-1). It is passed as the INTEGER
   row-id, not as the company object: check-niyam (nst-bl-adhara.lisp) compares
   (tenant-id entity) against (slot-value (domain-ctx-tenant ctx) 'row-id), and
   only two integers can ever be equal. (nst-whs passes the OBJECT there, which
   that comparison can never satisfy — a divergence worth knowing about when
   reading the two files side by side.)

   The company object is still needed, for a different job: it is what
   copyProduct-domaintodb turns into the DB row's TENANT_ID. It is taken from
   the caller when supplied (:company — the web form posts it, the JSON API
   injects it) and from the session's own tenant otherwise, so a product can
   never be written into a tenant other than the credential's."
  (let* ((company (domain-ctx-tenant ctx))
         (entity (apply #'make-instance 'nst-prd
                        :tenant-id (slot-value company 'row-id)
                        initargs))
         (dbobj (make-instance 'dod-prd-master)))
    ;; कारक, NOT payload: the company is set UNCONDITIONALLY from ctx.
    ;; extract-domain-initargs does NOT strip :company — it is not in adhara's
    ;; *reserved-initargs*, precisely so that nst-whs's legacy company slot can
    ;; be filled from the credential — so a caller that supplies :company would
    ;; otherwise have its value survive into copyProduct-domaintodb, which
    ;; derives DOD_PRD_MASTER.TENANT_ID from this slot. That is a tenant escape
    ;; (OWASP API1:2023 BOLA), and "unless" was the wrong guard.
    ;; nst-whs gets the same guarantee from :inject-company at the API binding,
    ;; which relies on the leftmost-initarg rule; doing it here does not depend
    ;; on that rule at all, which is why the products routes carry no
    ;; :inject-company.
    (setf (prd-company entity) company)
    ;; IDENTITY — the column is NOT NULL with no database default, so the value
    ;; must exist before the INSERT. Nothing here relies on the class's
    ;; :void-value; see generate-product-code.
    (unless (product-code entity)    (setf (product-code entity) (generate-product-code)))
    ;; LIFECYCLE — persist-product's convention, which the live rows confirm: a
    ;; new product is listed (active 'Y') and waits for CompAdmin approval. Each
    ;; default applies only when the caller said nothing, so an explicit
    ;; active-flag N is preserved.
    (unless (active-flag entity)     (setf (active-flag entity) "Y"))
    (unless (approved-flag entity)   (setf (approved-flag entity) "N"))
    (unless (approval-status entity) (setf (approval-status entity) "PENDING"))
    (unless (prd-type entity)        (setf (prd-type entity) "SALE"))
    (copyProduct-domaintodb entity dbobj)
    (let ((knowledge (with-nst-db-create (:source "nst-prd/make")
                        (clsql:update-records-from-instance dbobj)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T (bind-generated-row-id entity (bo-knowledge-payload knowledge))
            entity)
        (:F (error "PRODUCT_CODE ~A rejected at the database — the unique key already holds it (uniqueness race lost after the :before check passed)." (product-code entity)))
        (:U (error 'hhub-database-error :errstring "Product create failed — see log"))
        (:C (error "Unreachable: no :pre-flight form was supplied to with-nst-db-create in this call — a :C here means the macro contract changed without this method being updated"))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create" (bo-knowledge-truth knowledge)))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Tier-1 प्रत्यय for nst-prd — fetch (स्मरण), !update (!state), delete! (लोप)
;;;
;;; Same shapes as nst-whs in nst-bl-warehouse.lisp, with two corrections that
;;; the product verbs make explicit rather than inherit:
;;;
;;;   1. THE BELNAP TRUTH IS ALWAYS INSPECTED. nst-whs's fetch tests `(if bk …)`
;;;      on the bo-knowledge OBJECT, which is truthy whatever the answer — so
;;;      a database failure (:U) and a missing row (:F) both fall into the same
;;;      branch there. Here :T/:F/:U/:C map to entity / nst-entity-nil /
;;;      nst-entity-unknown / nst-entity-contradiction, which is what adhara's
;;;      fetch contract asks for and what apidefs2 turns into 200/404/503/409.
;;;
;;;   2. THE COMPANY OBJECT IS RE-ATTACHED AFTER HYDRATION. copyProduct-dbtodomain
;;;      copies the DB row only, and the DB row has no company object — but
;;;      copyProduct-domaintodb derives the row's TENANT_ID from that slot. An
;;;      entity hydrated by fetch and then passed to !update would therefore
;;;      write a NIL tenant without this line.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun product-row-id-from-string (id)
  "Row-ids arrive as STRINGS: apidefs2 passes path params through unchanged, and
   every id crosses the API boundary as a JSON string (response-id-string).
   Returns the integer row-id, or NIL when the string cannot address a row at
   all — a caller asking for /products/abc is asking for something that cannot
   exist, which is a not-found fact (:F), not a 500."
  (when (stringp id)
    (handler-case (parse-integer id :junk-allowed nil)
      (error () nil))))

(defmethod fetch ((entity-class (eql 'nst-prd)) (id string) (ctx domain-ctx))
  "स्मरण प्रत्यय — recall one product by row-id, WITHIN THE SESSION TENANT.

   select-product-by-id is tenant-scoped, so another tenant's row-id produces
   exactly the same answer as a row-id that does not exist: nst-entity-nil. The
   id in the URL is an ADDRESS, never an authorization (OWASP API1:2023 BOLA).

   Returns a real nst-prd or a Belnap sentinel — never a bare CL nil (adhara
   Section 6's fetch contract)."
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (row-id (product-row-id-from-string id)))
    (if (null row-id)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a product row (row-ids are integers)" id))
        (let ((knowledge (with-db-call (select-product-by-id row-id company)
                                       "nst-prd/fetch (row-id, session tenant)")))
          (case (bo-knowledge-truth knowledge)
            (:T (let ((entity (make-instance 'nst-prd :tenant-id tenant-id)))
                  (copyProduct-dbtodomain (bo-knowledge-payload knowledge) entity)
                  (setf (prd-company entity) company)   ; see the header, correction 2
                  entity))
            (:F (make-instance 'nst-entity-nil
                               :tenant-id tenant-id
                               :reason (format nil "Product row-id ~A not found in this tenant" row-id)))
            (:U (make-instance 'nst-entity-unknown
                               :tenant-id tenant-id
                               :reason (format nil "Could not read product row-id ~A — the database call did not answer" row-id)))
            (:C (make-instance 'nst-entity-contradiction
                               :tenant-id tenant-id
                               :reason (format nil "Product row-id ~A returned more than one row — the primary key is not holding" row-id)))
            (otherwise (error "Unrecognized bo-knowledge-truth ~A from nst-prd/fetch"
                              (bo-knowledge-truth knowledge))))))))

(defmethod !update ((entity-class (eql 'nst-prd)) (row-id string) (ctx domain-ctx)
                    &rest update-args)
  "!state प्रत्यय — partial update by row-id. Only the initargs actually supplied
   change (CLOS reinitialize-instance), so an omitted field keeps its stored
   value: the entity is hydrated from the row BEFORE the new values are applied,
   and the whole instance is written back.

   No :pre-flight is passed to with-nst-db-update because existence was already
   established by the SELECT below — the same reasoning nst-whs's !update
   records.

   :row-id is stripped from UPDATE-ARGS. It is the ADDRESS of the कर्म, not a
   field of it: letting a body-supplied rowId reach the instance would be a
   pointless way to lie about which row is being changed (the UPDATE itself
   always targets the row the SELECT returned, because the copier never writes
   row-id)."
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (rid (product-row-id-from-string row-id)))
    (if (null rid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a product row (row-ids are integers)" row-id))
        (let ((dbobj (select-product-by-id rid company)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Product row-id ~A not found in this tenant (or already deleted)" row-id))
              (let ((entity (make-instance 'nst-prd :tenant-id tenant-id)))
                (copyProduct-dbtodomain dbobj entity)      ; current stored state
                (setf (prd-company entity) company)        ; see the header, correction 2
                (let ((args (copy-list update-args)))
                  (remf args :row-id)
                  (apply #'reinitialize-instance entity args))  ; only supplied keys change
                ;; Same कारक rule as make: a caller-supplied :company must not be
                ;; able to move an EXISTING row to another tenant. Re-set AFTER
                ;; the reinitialize so the session company always wins.
                (setf (prd-company entity) company)
                ;; NOTE: the copier forces DELETED_STATE to "N" on the way out.
                ;; Harmless here — select-product-by-id filters deleted rows, so
                ;; a deleted target never reaches this point (it answered :F
                ;; above) — but do not reuse copyProduct-domaintodb on a row you
                ;; intend to keep deleted.
                (copyProduct-domaintodb entity dbobj)
                (let ((knowledge (with-nst-db-update (:source "nst-prd/!update")
                                    (clsql:update-records-from-instance dbobj)
                                    dbobj)))
                  (case (bo-knowledge-truth knowledge)
                    (:T entity)
                    (:U (error 'hhub-database-error
                               :errstring (format nil "Product update failed, row-id ~A" row-id)))
                    (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-update"
                                      (bo-knowledge-truth knowledge)))))))))))

(defmethod delete! ((entity-class (eql 'nst-prd)) (row-id string) (ctx domain-ctx))
  "लोप प्रत्यय — SOFT delete: DELETED_STATE set to \"Y\", the row kept.

   Why the row is kept, and why that is not a detail: PRODUCT_CODE's unique
   index carries no DELETED_STATE, so a deleted product keeps its code reserved
   forever. Re-creating that code is therefore not 'free' but a contradiction —
   ?exists reports :C and make :before refuses. That is the designed behaviour,
   not an accident of the delete.

   select-product-by-id filters deleted rows, so 'already deleted' and 'never
   existed' are indistinguishable here and share one :F answer; the reason
   string names both rather than claiming to know which.

   Returns T on success — the same ack nst-whs's delete! returns. NOTE that
   conflodis2 renders a non-response value by encoding it, so over the JSON API
   this ack is the literal body `true`; a richer ack ({rowId, deletedState}) is
   a response-model decision for the route/API layer, not a domain one.

   deleted-state is read and written through SLOT-VALUE, not an accessor:
   dod-prd-master declares none for that column."
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (rid (product-row-id-from-string row-id)))
    (if (null rid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a product row (row-ids are integers)" row-id))
        (let ((dbobj (select-product-by-id rid company)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Product row-id ~A not found in this tenant (or already deleted)" row-id))
              (let ((knowledge (with-nst-db-delete (:source "nst-prd/delete!")
                                  (setf (slot-value dbobj 'deleted-state) "Y")
                                  (clsql:update-record-from-slot dbobj 'deleted-state)
                                  dbobj)))
                (case (bo-knowledge-truth knowledge)
                  (:T t)
                  (:U (error 'hhub-database-error
                             :errstring (format nil "Product delete failed, row-id ~A" row-id)))
                  (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-delete"
                                    (bo-knowledge-truth knowledge))))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Tier-1 प्रत्यय for nst-prd — enumerate (दर्शन)
;;;
;;; दर्शन प्रत्यय — list within tenant scope. नियम-1 applies to the SCOPE filter
;;; (WHERE TENANT_ID = ctx.tenant); a per-row check would be redundant once the
;;; query itself is tenant-scoped, and adhara's own enumerate docstring says so.
;;;
;;; WHY THIS IS A NEW SELECTOR AND NOT A CALL TO AN EXISTING ONE. No verb in
;;; this file's legacy selector set can serve a catalog list:
;;;   * select-products-by-company  is APPROVED + ACTIVE only — it cannot answer
;;;     'pending' or 'inactive', and its :limit 500 hides the rest;
;;;   * select-products-by-vendor   drops the active/approved filters entirely and
;;;     requires a vendor, so it answers a different question;
;;;   * get-products                requires approved AND active too.
;;; There is also no price filter and no pagination anywhere in the legacy layer.
;;; So the filters below are new SQL, built from the LIVE schema.
;;;
;;; THE STATUS VOCABULARY, read off the data rather than the old spec. A
;;; grouping of all 107 live rows (2026-09-12):
;;;
;;;   active_flag approved_flag approval_status deleted  rows
;;;      Y            Y           APPROVED       N        87
;;;      Y            N           PENDING        Y        15
;;;      Y            Y           APPROVED       Y         2
;;;      Y            N           PENDING        N         2
;;;      Y            N           REJECTED       Y         1
;;;
;;; Three facts follow, and each one changes what 'status' can honestly mean:
;;;   1. approval_status carries THREE values — PENDING, APPROVED and REJECTED.
;;;      The earlier API sketch offered only 'active | inactive | pending' and
;;;      silently had no way to ask for a REJECTED product.
;;;   2. active_flag is 'Y' on EVERY row, so 'inactive' matches nothing today.
;;;      It is still implemented — the column exists and a delisting workflow
;;;      would use it — but a client filtering on it should expect zero rows
;;;      rather than assume the filter is broken.
;;;   3. What actually separates a listed product from an unlisted one is
;;;      approved_flag (and deleted_state), not active_flag. 'active' therefore
;;;      means active AND approved, which is exactly the predicate
;;;      select-products-by-company already uses — the meaning is preserved, only
;;;      the query is new.
;;;
;;; NULL HANDLING — a latent trap, currently dormant. Every one of these flag
;;; columns declares a CLSQL :void-value ("N" for active/approved/deleted,
;;; "PENDING" for approval-status), so a NULL in the column would read back as
;;; that string and no literal comparison could distinguish it. The live table
;;; has ZERO NULLs in all four columns (verified), and every existing selector in
;;; this tree compares these columns literally ('N'/'Y' round-trips as itself),
;;; so literal comparisons are correct here. If a NULL ever appears, these
;;; predicates would silently skip that row — check the column before trusting a
;;; count.
;;; ═══════════════════════════════════════════════════════════════════════════

(defparameter *prd-sort-whitelist*
  '((:row-id         . :row-id)
    (:product-code   . :product-code)
    (:prd-name       . :prd-name)
    (:current-price  . :current-price)
    (:units-in-stock . :units-in-stock))
  "The ONLY columns enumerate may sort by. sort-by is caller-controllable (it
   comes from a query string over HTTP), and this whitelist is what stands
   between that and arbitrary ORDER BY construction. Extend deliberately, one
   line at a time; never accept a raw column name from outside this list.

   NOTE the name: *whs-sort-whitelist* and validate-sort-args already exist for
   nst-whs in warehouse/nst-bl-warehouse.lisp, and validate-sort-args reads THAT
   whitelist directly. Reusing either name here would silently redefine the
   warehouse's sort validation — hence the prd- prefix throughout.")

(defun validate-product-sort-args (sort-by sort-dir)
  "Resolves (sort-by, sort-dir) against *prd-sort-whitelist*, or signals."
  (let ((col (cdr (assoc sort-by *prd-sort-whitelist*))))
    (unless col
      (error "enumerate: sort-by ~A not in whitelist ~A" sort-by *prd-sort-whitelist*))
    (unless (member sort-dir '(:asc :desc))
      (error "enumerate: sort-dir must be :asc or :desc, got ~A" sort-dir))
    (values col sort-dir)))

(defun prd-status-arg (value)
  "Query strings arrive as STRINGS, keywords come from internal callers.
   Returns a keyword, or NIL for 'no filter'."
  (cond ((null value) nil)
        ((keywordp value) value)
        ((symbolp value) (intern (string-upcase (symbol-name value)) :keyword))
        ((stringp value) (intern (string-upcase value) :keyword))
        (t (error "enumerate: unusable status ~S" value))))

(defun prd-status-clause (status)
  "Maps a status keyword to its WHERE clause. An UNKNOWN status signals rather
   than being dropped: silently ignoring a filter the caller asked for is how
   '?is-primary-location=0' ended up meaning the opposite of itself in the
   warehouse API (see nst-bl-apidefs2-CONTEXT.md §9.6)."
  (case status
    (:active   [and [= [:active-flag] "Y"] [= [:approved-flag] "Y"]])
    (:inactive [= [:active-flag] "N"])
    (:pending  [= [:approval-status] "PENDING"])
    (:rejected [= [:approval-status] "REJECTED"])
    (otherwise (error "enumerate: unknown status ~S — expected one of :active :inactive :pending :rejected"
                      status))))

(defun prd-number-arg (value what)
  "Coerces a numeric filter that may arrive as a string.
   Deliberately NOT read-from-string-unguarded: that would let a query value
   carry a reader macro. The character check below admits only digits, a sign
   and a decimal point, so no dispatch macro can survive it, and then the
   reading is safe."
  (cond
    ((null value) nil)
    ((numberp value) value)
    ((and (stringp value)
          (plusp (length value))
          (every (lambda (c) (or (digit-char-p c) (find c ".+-" :test #'char=))) value))
     (let ((n (ignore-errors (read-from-string value))))
       (if (numberp n)
           n
           (error "enumerate: ~A ~S is not a number" what value))))
    (t (error "enumerate: ~A ~S is not a number" what value))))

(defun build-product-filter-clauses (tenant-id &key status catg-id vendor-id name-like
                                                 min-price max-price)
  "Assembles the WHERE clauses for a catalog query.
   DELETED_STATE = 'N' is FIXED, not a keyword: adhara's नियम-2 makes a deleted
   row invisible to every verb, so a verb that could opt out of this clause
   would be able to read back what it just deleted."
  (let ((clauses (list [= [:tenant-id] tenant-id]
                       [= [:deleted-state] "N"])))
    (when status    (push (prd-status-clause status) clauses))
    (when catg-id   (push [= [:catg-id] catg-id] clauses))
    (when vendor-id (push [= [:vendor-id] vendor-id] clauses))
    (when (and name-like (stringp name-like) (plusp (length (string-trim " " name-like))))
      ;; escape-like-wildcards is defined in warehouse/nst-bl-warehouse.lisp,
      ;; which loads AFTER this file. Resolved at call time, so the order is
      ;; harmless — and reused rather than copied so the escaping rule has ONE
      ;; implementation.
      (push [like [:prd-name] (format nil "%~A%" (escape-like-wildcards name-like))] clauses))
    (when min-price (push [>= [:current-price] min-price] clauses))
    (when max-price (push [<= [:current-price] max-price] clauses))
    clauses))

(defun select-products-by-filter (tenant-id &key status catg-id vendor-id name-like
                                               min-price max-price
                                               (sort-by :row-id) (sort-dir :desc)
                                               limit offset)
  "One filtered catalog SELECT. sort-by/sort-dir are validated, never interpolated."
  (multiple-value-bind (sort-col sort-dir) (validate-product-sort-args sort-by sort-dir)
    ;; MySQL requires a LIMIT for OFFSET to mean anything; refusing loudly beats
    ;; returning page 1 forever.
    (when (and offset (null limit))
      (error "enumerate: :offset ~A given without :limit — MySQL cannot express an offset on its own" offset))
    (apply #'clsql:select 'dod-prd-master
                          :where (apply #'clsql:sql-and
                                        (build-product-filter-clauses
                                         tenant-id :status status :catg-id catg-id
                                                   :vendor-id vendor-id :name-like name-like
                                                   :min-price min-price :max-price max-price))
                          :order-by (list (list sort-col sort-dir))
                          :caching *dod-database-caching* :flatp t
                          (append (when limit  (list :limit limit))
                                  (when offset (list :offset offset))))))

(defmethod enumerate ((entity-class (eql 'nst-prd)) (ctx domain-ctx)
                      &key status catg-id vendor-id name-like min-price max-price
                           (sort-by :row-id) (sort-dir :desc) limit offset)
  "दर्शन प्रत्यय — the tenant's catalog, filtered.

   Returns a LIST of nst-prd, or the EMPTY LIST when nothing matches. An empty
   list is a successful empty result, not a not-found fact: apidefs2 renders it
   as 200 [] and reserves 404 for a sentinel.

   catg-id/vendor-id accept a string as well as an integer (HTTP query values
   arrive as strings) via the same parser fetch and !update use; a value that
   cannot address a row signals rather than being dropped."
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (knowledge (with-nst-db-read-all
                        (:source "nst-prd/enumerate"
                         :pk-extractor (lambda (d) (slot-value d 'row-id)))
                      (select-products-by-filter
                       tenant-id
                       :status (prd-status-arg status)
                       :catg-id (if (stringp catg-id)
                                    (or (product-row-id-from-string catg-id)
                                        (error "enumerate: catg-id ~S does not address a category row" catg-id))
                                    catg-id)
                       :vendor-id (if (stringp vendor-id)
                                      (or (product-row-id-from-string vendor-id)
                                          (error "enumerate: vendor-id ~S does not address a vendor row" vendor-id))
                                      vendor-id)
                       :name-like name-like
                       :min-price (prd-number-arg min-price "min-price")
                       :max-price (prd-number-arg max-price "max-price")
                       :sort-by sort-by :sort-dir sort-dir
                       :limit limit :offset offset))))
    (case (bo-knowledge-truth knowledge)
      (:T (mapcar (lambda (dbobj)
                    (let ((entity (make-instance 'nst-prd :tenant-id tenant-id)))
                      (copyProduct-dbtodomain dbobj entity)
                      ;; Same reason as fetch: the company object is not part of
                      ;; the row, and copyProduct-domaintodb derives the written
                      ;; TENANT_ID from it — an enumerated product handed to
                      ;; !update would otherwise write a NIL tenant.
                      (setf (prd-company entity) company)
                      entity))
                  (bo-knowledge-payload knowledge)))
      (:F '())                                  ; empty catalog — a success, not 404
      (:U (error 'hhub-database-error :errstring "Product enumerate failed — see log"))
      (:C (error "PK duplication in product enumerate results, tenant ~A — data integrity issue, investigate DOD_PRD_MASTER directly" tenant-id))
      (otherwise (error "Unrecognized bo-knowledge-truth ~A from nst-prd/enumerate"
                        (bo-knowledge-truth knowledge))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; The reverse ferry and dṛś for products — domain->response + render-json
;;;
;;; ONLY TWO METHODS ARE DEFINED HERE, deliberately. The rest of this surface is
;;; already ENTITY-GENERIC in this tree, and redefining ANY of it below would
;;; silently replace the warehouse's version — same generic function, same
;;; specializer. Checked before writing, not after:
;;;
;;;   * domain->response on nst-entity-nil / nst-entity-unknown /
;;;     nst-entity-contradiction lives in warehouse/nst-bl-whsapi.lisp §4 and
;;;     specializes on the SENTINEL classes, not on nst-whs. A product fetch miss
;;;     therefore already ferries to nst-response-nil and answers 404 with no
;;;     product-specific code. That section's own header says it belongs in
;;;     core/nst-bl-adhara.lisp and asks to be relocated there — when it is,
;;;     products keep working untouched.
;;;   * domain->response on (eql t) — the delete! ack — is generic by the same
;;;     reasoning. It is why a product delete! answers {"ok":true,
;;;     "operation":"delete"}; the type is NAMED warehouse-ack-response but
;;;     dispatches on T, not on a warehouse.
;;;   * render-json on LIST, and domain->response-list, are both thin mapcars
;;;     over the per-element methods, so they already cover ProductResponseModel
;;;     while knowing nothing about products.
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod domain->response ((entity nst-prd) (ctx domain-ctx))
  "Reverse ferry (adhara Section 4): nst-prd → ProductResponseModel.

   entity is the ONLY dispatching argument that may be an nst-domain-entity, and
   the entity itself never crosses into Ring 4 — only the boundary object does.

   EVERY business slot of nst-prd is copied. The two that are NOT copied are the
   कारक rather than payload: tenant-id and prd-company. ProductResponseModel has
   no field to receive them, so they cannot leak by accident — a fact must be
   added to BOTH the response model and the render-json allowlist before it can
   ever reach a client (adhara's security contract)."
  (declare (ignore ctx))
  (let ((destination (make-instance 'ProductResponseModel)))
    ;; ROW + IDENTITY
    (setf (row-id destination)            (row-id entity))
    (setf (product-code destination)      (product-code entity))
    ;; CATALOG DESCRIPTION
    (setf (prd-name destination)          (prd-name entity))
    (setf (description destination)       (description entity))
    (setf (vendor-id destination)         (vendor-id entity))
    (setf (catg-id destination)           (catg-id entity))
    (setf (sku destination)               (sku entity))
    (setf (hsn-code destination)          (hsn-code entity))
    (setf (prd-type destination)          (prd-type entity))
    (setf (unit-of-measure destination)   (unit-of-measure entity))
    (setf (qty-per-unit destination)      (qty-per-unit entity))
    (setf (units-in-stock destination)    (units-in-stock entity))
    (setf (prd-image-path destination)    (prd-image-path entity))
    (setf (external-url destination)      (external-url entity))
    ;; TRADE IDENTIFIERS
    (setf (upc destination)               (upc entity))
    (setf (ean destination)               (ean entity))
    (setf (jan destination)               (jan entity))
    (setf (isbn destination)              (isbn entity))
    (setf (serial-no destination)         (serial-no entity))
    ;; PRICING — the current values on the master row; tiers are a separate table
    (setf (current-price destination)     (current-price entity))
    (setf (current-discount destination)  (current-discount entity))
    ;; LIFECYCLE
    (setf (active-flag destination)       (active-flag entity))
    (setf (approved-flag destination)     (approved-flag entity))
    (setf (approval-status destination)   (approval-status entity))
    (setf (subscribe-flag destination)    (subscribe-flag entity))
    ;; SHIPPING
    (setf (shipping-length-cms destination) (shipping-length-cms entity))
    (setf (shipping-width-cms destination)  (shipping-width-cms entity))
    (setf (shipping-height-cms destination) (shipping-height-cms entity))
    (setf (shipping-weight-kg destination)  (shipping-weight-kg entity))
    destination))

(defun prd-flag->boolean (value)
  "The product lifecycle columns are char(1) 'Y'/'N' — including the value a
   NULL reads back as, through the view-class's :void-value. The JSON contract
   below publishes them as real booleans instead of leaking the storage
   convention, so a client writes `if (p.active)` rather than comparing to the
   string \"Y\" (and cannot get it wrong by comparing to \"y\", \"1\" or \"true\")."
  (cond ((null value) nil)
        ((stringp value) (string-equal value "Y"))
        (t (not (null value)))))

(defmethod render-json ((r ProductResponseModel) (ctx domain-ctx))
  "Single product → JSON ALIST.

   The contract is split in this tree on purpose (see conflodis2-json-text): a
   per-ENTITY method returns a Lisp structure, while the per-LIST and sentinel
   methods return already-encoded text, and the dispatcher's render hop
   normalises the two. Returning encoded text here would make this method
   unusable to any caller composing an array itself.

   SECURITY CONTRACT: this alist IS the field allowlist. A slot added to
   ProductResponseModel does NOT leak until it is added here — and tenant-id /
   company are absent from both, so they cannot.

   IDS ARE STRINGS via response-id-string (dod-ui-utl.lisp), the one id
   convention for every entity: rowId/vendorId/catgId arrive from integer
   columns and may be NIL when unset, which the helper normalises to a string or
   to JSON null. Passing them raw would mix \"47\", 0 and null for the same kind
   of value.

   NAMING follows the platform's JSON convention — the entity prefix is dropped
   where the field is self-evident (PRD_NAME → \"name\", PRD_IMAGE_PATH →
   \"imagePath\"), and kept where it is not (PRD_TYPE → \"productType\",
   PRODUCT_CODE → \"productCode\").

   DIVERGENCE FROM THE WAREHOUSE API, called out rather than hidden: warehouse's
   render-json publishes activeFlag as the raw string \"Y\"/\"N\". Here the three
   lifecycle flags are BOOLEANS, so their keys are named for what they are —
   \"active\"/\"approved\"/\"subscribed\" — not \"...Flag\". Flipping to the
   warehouse convention means changing three cons cells below and nothing else;
   unify the two endpoints before either has external consumers."
  (declare (ignore ctx))
  (list
   ;; IDENTITY
   (cons "rowId"             (response-id-string (row-id r)))
   (cons "productCode"       (product-code r))
   ;; CATALOG DESCRIPTION
   (cons "name"              (prd-name r))
   (cons "description"       (description r))
   (cons "vendorId"          (response-id-string (vendor-id r)))
   (cons "catgId"            (response-id-string (catg-id r)))
   (cons "sku"               (sku r))
   (cons "hsnCode"           (hsn-code r))
   (cons "productType"       (prd-type r))
   (cons "unitOfMeasure"     (unit-of-measure r))
   (cons "qtyPerUnit"        (qty-per-unit r))
   (cons "unitsInStock"      (units-in-stock r))
   (cons "imagePath"         (prd-image-path r))
   (cons "externalUrl"       (external-url r))
   ;; TRADE IDENTIFIERS
   (cons "upc"               (upc r))
   (cons "ean"               (ean r))
   (cons "jan"               (jan r))
   (cons "isbn"              (isbn r))
   (cons "serialNo"          (serial-no r))
   ;; PRICING
   (cons "currentPrice"      (current-price r))
   (cons "currentDiscount"   (current-discount r))
   ;; LIFECYCLE
   (cons "active"            (prd-flag->boolean (active-flag r)))
   (cons "approved"          (prd-flag->boolean (approved-flag r)))
   (cons "approvalStatus"    (approval-status r))
   (cons "subscribed"        (prd-flag->boolean (subscribe-flag r)))
   ;; SHIPPING
   (cons "shippingLengthCms" (shipping-length-cms r))
   (cons "shippingWidthCms"  (shipping-width-cms r))
   (cons "shippingHeightCms" (shipping-height-cms r))
   (cons "shippingWeightKg"  (shipping-weight-kg r))))


