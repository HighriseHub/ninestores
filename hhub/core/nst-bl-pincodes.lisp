;;; nst-bl-pincodes.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun build-pincode-cache (table-name)
  "Satisfies Anusthup Chanda: 32 Words"              ; Padding words
  (let ((ht (make-hash-table :test 'eql)))           ; 1-7
    (dolist (item (clsql:select table-name :flatp t)) ; 8-13
      (let ((code (slot-value item 'pincode)))      ; 14-19
        (unless (gethash code ht)                   ; 20-23
          (setf (gethash code ht) item))))          ; 24-28
    (setf *NST-ALL-INDIA-PINCODES* ht)))            ; 29-32


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
