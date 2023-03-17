;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(defun approve-product (id description company)
  (let ((product (select-product-by-id id company)))
    (if product 
	(progn (setf (slot-value product 'approved-flag) "Y")
	       (setf (slot-value product 'approval-status) "APPROVED")
	       (setf (slot-value product 'description) description)
	       (update-prd-details product)))))

(defun reject-product (id description company)
  (let ((product (select-product-by-id id  company)))
    (if product 
	(progn (setf (slot-value product 'approved-flag) "N")
	       (setf (slot-value product 'approval-status) "REJECTED")
	       (setf (slot-value product 'description) description)
	       (update-prd-details product)))))

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
		[= [:tenant-id] tenant-id]]
     :caching *dod-database-caching* :flatp t )))

(defun select-products-by-vendor (vendor company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id))
	     (vendor-id (slot-value vendor 'row-id)))
 (clsql:select 'dod-prd-master  :where
		[and 
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[=[:vendor-id] vendor-id]]
		:caching *dod-database-caching* :flatp t )))




(defun search-prd-in-list (row-id list)
    (if (not (equal row-id (slot-value (car list) 'row-id))) (search-prd-in-list row-id (cdr list))
    (car list)))


(defun prdinlist-p  (prd-id list)
(member prd-id  (mapcar (lambda (item)
		(slot-value item 'prd-id)) list)))


(defun select-product-by-id (id company-instance ) 
  (let ((tenant-id (slot-value company-instance 'row-id)))
 (car (clsql:select 'dod-prd-master  :where
		[and 
		[= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[=[:row-id] id]]    :caching *dod-database-caching* :flatp t ))))




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
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (let ((dodproduct (car (clsql:select 'dod-prd-master :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodproduct 'deleted-state) "Y")
    (clsql:update-record-from-slot dodproduct 'deleted-state))))



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

   

  
(defun persist-product(prdname description vendor-id catg-id qtyperunit unitprice units-in-stock img-file-path subscribe-flag tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-prd-master
				    :prd-name prdname
				    :description description
				    :vendor-id vendor-id
				    :catg-id catg-id
				    :qty-per-unit qtyperunit
				    :unit-price unitprice
				    :units-in-stock units-in-stock
				    :prd-image-path img-file-path
				    :subscribe-flag subscribe-flag
				    :tenant-id tenant-id
				    :active-flag "Y"
				    :approved-flag "N"
				    :approval-status "PENDING"
				    :prd-type "SALE"
				    :deleted-state "N")))

(defun create-bulk-products (products)
  (mapcar (lambda (product)
	    (clsql:update-records-from-instance  product)) products))

(defun create-product (prdname description  vendor-instance category qty-per-unit unit-price units-in-stock img-file-path subscribe-flag company-instance)
  (let ((vendor-id (slot-value vendor-instance 'row-id))
	(catg-id (if category (slot-value category 'row-id)))
	(tenant-id (slot-value company-instance 'row-id)))
      (persist-product prdname description vendor-id catg-id qty-per-unit unit-price units-in-stock img-file-path subscribe-flag  tenant-id)))

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


(defun add-new-node-prdcatg (name company-instance) 
  (let* ((tenant-id (slot-value company-instance 'row-id))
	 (query (format nil 
		       "LOCK TABLE DOD_PRD_CATG  WRITE;SELECT @myRight := rgt FROM DOD_PRD_CATG  WHERE catg_name = 'root';UPDATE DOD_PRD_CATG  SET rgt = rgt + 2 WHERE rgt > @myRight;UPDATE DOD_PRD_CATG SET lft = lft + 2 WHERE lft > @myRight;INSERT INTO DOD_PRD_CATG (catg_name, lft, rgt, tenant_id, active_flag, deleted_state ) VALUES('~A', @myRight + 1, @myRight + 2, ~A, 'Y', 'N');UNLOCK TABLES;" name tenant-id)))
    (print query) 
    (clsql:query query :field-names nil :flatp t)))


(defun add-new-prdcatg-node-as-child (parentname childname  company-instance) 
  (let* ((tenant-id (slot-value company-instance 'row-id))
	 (query (format nil 
		       "LOCK TABLE DOD_PRD_CATG  WRITE;
SELECT @myLeft := lft FROM DOD_PRD_CATG WHERE catg_name = '~A'; 
UPDATE DOD_PRD_CATG  SET rgt = rgt + 2 WHERE rgt > @myLeft;
UPDATE DOD_PRD_CATG  SET lft = lft + 2 WHERE lft > @myLeft;
INSERT INTO DOD_PRD_CATG (catg_name, lft, rgt, tenant_id, active_flag, deleted_state) VALUES('~A', @myLeft + 1, @myLeft + 2, ~A, 'Y', 'N');
UNLOCK TABLES;" parentname childname tenant-id)))
    (clsql:query query :field-names nil :flatp t)))



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


