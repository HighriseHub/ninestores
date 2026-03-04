;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun select-all-india-pincodes ()
  (clsql:select 'dod-india-pincodes :caching *dod-database-caching* :flatp t ))


(defun get-all-india-pincodes-ht ()
  "Returns a hash table where each pincode is a unique key, 
   ignoring sub-office distinctions."
  (let ((ht (make-hash-table :test 'eql))
        (all-data (select-all-india-pincodes)))
    (loop for entry in all-data do
         (let ((code (slot-value entry 'pincode)))
           ;; Only set if not already present to keep the 'first' found 
           ;; or just overwrite to keep the 'last'. Business logic remains the same.
           (unless (gethash code ht)
             (setf (gethash code ht) entry))))
    ht))


(defun find-pincode-details-from-ht (pincode)
  (gethash pincode *NST-ALL-INDIA-PINCODES*))

(defun find-pincode-details-from-db (pincode)
  (clsql:select 'dod-india-pincodes 
                :where [= [pincode] pincode]
                :flatp t))
