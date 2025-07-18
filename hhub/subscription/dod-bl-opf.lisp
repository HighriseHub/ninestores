;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)




(defun get-opreflist-by-company (company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
(clsql:select 'dod-ord-pref  :where [and [= [:deleted-state] "N"] [= [:tenant-id] tenant-id]]    :caching *dod-database-caching* :flatp t )))


(defun get-opref-by-id (id company-instance)
  (let ((tenant-id (slot-value company-instance 'row-id)))
  (car (clsql:select 'dod-ord-pref  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[=[:row-id] id]]    :caching *dod-database-caching* :flatp t ))))

(defun get-opreflist-for-customer (customer &optional (pdbcaching nil))
  (let ((tenant-id (slot-value customer 'tenant-id))
	(cust-id (slot-value customer 'row-id)))
    (clsql:select 'dod-ord-pref  :where
		  [and [= [:deleted-state] "N"]
		  [= [:tenant-id] tenant-id]
		  [=[:cust-id] cust-id ]]
				 :caching pdbcaching :flatp t )))
    




(defun get-latest-opref-for-customer (customer)
  (let ((tenant-id (slot-value customer 'tenant-id))
	(cust-id (slot-value customer 'row-id)))
(car (clsql:select 'dod-ord-pref  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[=[:cust-id] cust-id ]
		[= [:row-id] (get-max-opref-id cust-id tenant-id)]]    :caching *dod-database-caching* :flatp t ))))
  
(defun get-max-opref-id (customer-id tenant-id)
 (clsql:select [max [row-id]] :from 'dod-opref  :where
		[and [= [:deleted-state] "N"]
		[= [:tenant-id] tenant-id]
		[=[:cust-id] customer-id]]    :caching *dod-database-caching* :flatp t ))
  



(defun update-opref (opref-instance); This function has side effect of modifying the database record.
  (clsql:update-records-from-instance opref-instance))



(defun delete-opref( opref-instance )
  (let ((tenant-id (slot-value opref-instance 'tenant-id))
	(id (slot-value opref-instance 'row-id)))
  (let ((dodorderpref (car (clsql:select 'dod-ord-pref :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodorderpref 'deleted-state) "Y")
    (clsql:update-record-from-slot dodorderpref 'deleted-state))))



(defun delete-oprefs ( list company-instance)
    (let ((tenant-id (slot-value company-instance 'row-id)))
  (mapcar (lambda (id)  (let ((dodorderpref (car (clsql:select 'dod-ord-pref :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
			  (setf (slot-value dodorderpref 'deleted-state) "Y")
			  (clsql:update-record-from-slot dodorderpref  'deleted-state))) list )))


(defun restore-deleted-orderprefs ( list tenant-id )
(mapcar (lambda (id)  (let ((dodorderpref (car (clsql:select 'dod-ord-pref :where [and [= [:row-id] id] [= [:tenant-id] tenant-id]] :flatp t :caching *dod-database-caching*))))
    (setf (slot-value dodorderpref 'deleted-state) "N")
    (clsql:update-record-from-slot dodorderpref 'deleted-state))) list ))

  

  
(defun persist-orderpref( customer-id product-id prd-qty mon tue wed thu fri sat sun tenant-id )
 (clsql:update-records-from-instance (make-instance 'dod-ord-pref
						    :cust-id customer-id
						    :prd-id product-id
					 :prd-qty prd-qty
					 :sun (if sun "Y" "N")
					 :mon (if mon "Y" "N")
					 :tue  (if tue "Y" "N")
					 :wed  (if wed "Y" "N")
					 :thu  (if thu "Y" "N")
					 :fri  (if fri "Y" "N")
					 :sat  (if sat "Y" "N") 
						    :tenant-id tenant-id
						    :deleted-state "N"))
  (sleep 1))



(defun create-opref (customer product prd-qty wdlist company-instance)
  (let ((customer-id (slot-value  customer 'row-id) )
	(tenant-id (slot-value company-instance 'row-id))
	(product-id (slot-value product 'row-id)))
    (persist-orderpref customer-id product-id prd-qty (nth 0 wdlist) (nth 1 wdlist) (nth 2 wdlist) (nth 3 wdlist) (nth 4 wdlist) (nth 5 wdlist) (nth 6 wdlist)  tenant-id )))



