;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)


(defun refreshiamsettings ()
  (setf *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* (hhub-gen-globally-cached-lists-functions)))

(defun get-system-currencies-ht ()
  :documentation "This function stores all the currencies in a hashtable. The Key = country, Value = list of currency, code and symbol."
  (let ((ht (make-hash-table :test 'equal))
	(currencies (clsql:select 'dod-currencies    :caching *dod-database-caching* :flatp t )))
    (loop for curr in currencies do
      (let ((key (slot-value curr 'country))
	    (currency (slot-value curr 'currency))
	    (code (slot-value curr 'code))
	    (symbol (slot-value curr 'symbol)))
	   (setf (gethash key ht) (list currency code symbol))))
    ; Return  the hash table. 
    ht))



