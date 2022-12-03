;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defclass pincode ()
  ((pincode)
   (city)
   (state)
   (country)))

(defun init-pincodes ()
  (let ((pincode nil)
	(city nil)
	(state nil )
	(country nil) 
	(pincode-inst (make-instance 'pincode)))
     
    (setf (slot-value pincode-inst 'pincode) pincode)
    (setf (slot-value pincode-inst 'city) city)
    (setf (slot-value pincode-inst 'state) state)
    (setf (slot-value pincode-inst 'country) country)))

(defun getpincodedetails (pincode)
  (let* ((templist 
	 (param-name (list "api-key" "format" "offset" "limit" "filters[pincode]"))
	 (param-values (list "579b464db66ec23bdd0000018e71c67835264f884d15916532e43a9b" "json" "0" "1" (format nil "~A" pincode)))
	 (param-alist (pairlis param-name param-values ))
	 (json-response (json:decode-json-from-string  (map 'string 'code-char (drakma:http-request "https://api.data.gov.in/resource/5c2f62fe-5afa-4119-a499-fec9d604d5bd"
												    :method :GET
												    :parameters param-alist  ))))
	 (area (cdr (assoc :OFFICENAME (nth 1 (nth 25 json-response)) :test 'equal)))
	 (city (cdr (assoc :DISTRICT (nth 1 (nth 25 json-response)) :test 'equal)))
	 (state (cdr (assoc :STATENAME (nth 1 (nth 25 json-response)) :test 'equal))))
    ;; Send the Area, City and State values back. 
    (values area city state)))


	

  
