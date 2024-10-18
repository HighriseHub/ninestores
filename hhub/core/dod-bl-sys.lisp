;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

(defun refreshiamsettings ()
  (setf *HHUBGLOBALLYCACHEDLISTSFUNCTIONS* (hhub-gen-globally-cached-lists-functions)))

(defun get-system-currencies-ht ()
  :documentation "This function stores all the currencies in a hashtable. The Key = country, Value = list of currency, code and symbol."
  (let ((ht (make-hash-table :test 'equal))
	(currencies (clsql:select 'dod-currency :caching *dod-database-caching* :flatp t )))
    (loop for curr in currencies do
      (let ((key (slot-value curr 'country))
	    (currency (slot-value curr 'currency))
	    (code (slot-value curr 'code))
	    (symbol (slot-value curr 'symbol)))
	   (setf (gethash key ht) (list currency code symbol))))
    ; Return  the hash table. 
    ht))

(defun get-currency-html-symbol (currency)
  (gethash currency (hhub-get-cached-currency-html-symbols-ht)))

(defun get-currency-fontawesome-symbol (currency)
  (gethash currency (hhub-get-cached-currency-fontawesome-symbols-ht)))


(defun init-gst-statecodes ()
  (let ((ht (make-hash-table :test 'equal)))
    (setf (gethash  "1" ht) "JAMMU AND KASHMIR")
    (setf (gethash  "2" ht) "HIMACHAL PRADESH")
    (setf (gethash  "3" ht) "PUNJAB")
    (setf (gethash  "4" ht) "CHANDIGARH")
    (setf (gethash  "5" ht) "UTTARAKHAND")
    (setf (gethash  "6" ht) "HARYANA")
    (setf (gethash  "7" ht) "DELHI")
    (setf (gethash  "8" ht) "RAJASTHAN")
    (setf (gethash  "9" ht) "UTTAR PRADESH")
    (setf (gethash  "10" ht) "BIHAR")
    (setf (gethash  "11" ht) "SIKKIM")
    (setf (gethash  "12" ht) "ARUNACHAL PRADESH")
    (setf (gethash  "13" ht) "NAGALAND")
    (setf (gethash  "14" ht) "MANIPUR")
    (setf (gethash  "15" ht) "MIZORAM")
    (setf (gethash  "16" ht) "TRIPURA")
    (setf (gethash  "17" ht) "MEGHALAYA")
    (setf (gethash  "18" ht) "ASSAM")
    (setf (gethash  "19" ht) "WEST BENGAL")
    (setf (gethash  "20" ht) "JHARKHAND")
    (setf (gethash  "21" ht) "ODISHA")
    (setf (gethash  "22" ht) "CHATTISGARH")
    (setf (gethash  "23" ht) "MADHYA PRADESH")
    (setf (gethash  "24" ht) "GUJARAT")
    (setf (gethash  "26*" ht) "DADRA AND NAGAR HAVELI AND DAMAN AND DIU (NEWLY MERGED UT)")
    (setf (gethash  "27" ht) "MAHARASHTRA")
    (setf (gethash  "28" ht) "ANDHRA PRADESH(BEFORE DIVISION)")
    (setf (gethash  "29" ht) "KARNATAKA")
    (setf (gethash  "30" ht) "GOA")
    (setf (gethash  "31" ht) "LAKSHADWEEP")
    (setf (gethash  "32" ht) "KERALA")
    (setf (gethash  "33" ht) "TAMIL NADU")
    (setf (gethash  "34" ht) "PUDUCHERRY")
    (setf (gethash  "35" ht) "ANDAMAN AND NICOBAR ISLANDS")
    (setf (gethash  "36" ht) "TELANGANA")
    (setf (gethash  "37" ht) "ANDHRA PRADESH (NEWLY ADDED)")
    (setf (gethash  "38" ht) "LADAKH (NEWLY ADDED)")
    (setf (gethash  "97" ht) "OTHER TERRITORY")
    (setf (gethash  "99" ht) "CENTRE JURISDICTION")
    ht))

(defun init-gst-invoice-terms ()
  (setf *NSTGSTINVOICETERMS* "**Standard Invoice Terms:**
Payment is due within [10] days from the invoice date. Late payments may attract interest at [2]% per month. GST will be applied as per Indian tax laws. Ownership of goods remains with the seller until full payment is received. Any disputes regarding the invoice must be raised within [7] days of receipt. Cancellations or returns are subject to prior approval and may incur additional charges. The invoice is governed by Indian law, and the courts of [Bengaluru/Bangalore City] shall have exclusive jurisdiction over any disputes arising from this transaction."))



    
    
