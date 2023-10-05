;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


(defun get-volumetric-weight (l b h)
  (float (/ (* l b h) 5000)))


(defun define-shipping-zones ()
  (setf *HHUBSHIPPINGZONES* (make-hash-table :test 'equal))
  (setf (gethash "A" *HHUBSHIPPINGZONES*) "Zone A (Within City)")
  (setf (gethash "B" *HHUBSHIPPINGZONES*) "Zone B (Within State/region)")
  (setf (gethash "C" *HHUBSHIPPINGZONES*) "Zone C (Metro to Metro)")
  (setf (gethash "D" *HHUBSHIPPINGZONES*) "Zone D (Rest of India)")
  (setf (gethash "E" *HHUBSHIPPINGZONES*) "Zone E (J & K, North East)")
  (setf (gethash "F" *HHUBSHIPPINGZONES*) "Zone F (Undefined)"))
  


(defun order-shipping-rate-check-zonewise (products from-pincode)
  (let* ((total-length (format nil "~d" (get-total-of products 'shipping-length-cms)))
	 (total-width (format nil "~d" (get-total-of products 'shipping-width-cms)))
	 (total-height (format nil "~d" (get-total-of products 'shipping-height-cms)))
	 (total-weight (format nil "~d" (get-total-of products 'shipping-weight-kg)))
	 (total-price (format nil "~d" (get-total-of products 'unit-price)))
	 (order-type "forward")
	 (payment-method "prepaid")
	 (paramname (list "from_pincode" "shipping_length_cms" "shipping_width_cms" "shipping_height_cms" "shipping_weight_kg" "order_type" "payment_method" "product_mrp" "access_token" "secret_key"))
	 (paramvalue (list from-pincode  total-length total-width total-height total-weight order-type payment-method total-price *HHUBLOGISTICSKEY*   *HHUBLOGISTICSSECRET* ))
	 (param-alist (pairlis paramname paramvalue))
	 (datajson nil))
    
    (setf datajson (acons "data" param-alist datajson))
    (setf datajson (json:encode-json-to-string datajson))
    (map 'string 'code-char (drakma:http-request  *HHUBLOGISTICSRATECHECKZONEWISEURL_PROD*
			 :content-type "application/json"
			 :content datajson
			 :method :POST))))





(defun order-shipping-rate-check (shopping-cart products from-pincode to-pincode)
  (let* ((total-items (reduce #'+ (mapcar (lambda (item) (slot-value item 'prd-qty)) shopping-cart)))
	 (total-weight (calculate-cartitems-weight-kgs shopping-cart products))
	 (final-lwh (expt (* 5000 total-weight) 1/3))
	 (dimension1 (floor (- final-lwh (mod final-lwh 5))))
	 (dimension2 dimension1)
	 (dimension3 (floor (/ (* 5000 total-weight) (* dimension1 dimension2))))
	 (total-price (format nil "~d" (* total-items (get-total-of products 'unit-price))))
	 (order-type "forward")
	 (payment-method "prepaid")
	 (paramname (list "from_pincode" "to_pincode" "shipping_length_cms" "shipping_width_cms" "shipping_height_cms" "shipping_weight_kg" "order_type" "payment_method" "product_mrp" "access_token" "secret_key"))
	 (paramvalue (list from-pincode to-pincode  (format nil "~d" dimension3) (format nil "~d" dimension1) (format nil "~d" dimension2)  total-weight order-type payment-method total-price *HHUBLOGISTICSKEY*   *HHUBLOGISTICSSECRET* ))
	 (param-alist (pairlis paramname paramvalue))
	 (datajson nil))

    (logiamhere (format nil "from ~A to ~A ~C " from-pincode to-pincode #\newline))
    (logiamhere (format nil "Total items - ~d ~C" total-items #\newline))
    (logiamhere (format nil  "Length - ~d ~C" dimension3  #\newline))
    (logiamhere (format nil "width - ~d ~C" dimension1 #\newline))
    (logiamhere (format nil "height - ~d ~C" dimension2 #\newline))
    (logiamhere (format nil "total weight - ~d ~C" total-weight #\newline))
    (logiamhere (format nil "volumetric weight - ~d ~C" (/ (expt final-lwh 3) 5000) #\newline))
       
    (setf datajson (acons "data" param-alist datajson))
    (setf datajson (json:encode-json-to-string datajson))
    (format t "~A" datajson)
    ;; There is a bug in the rate check API, where we are not getting response if the total weight is beyond 5 KG. 
    (unless (> total-weight 5.0)
      (let* ((json-response (json:decode-json-from-string  (map 'string 'code-char (drakma:http-request *HHUBLOGISTICSRATECHECKURL_PROD*
													:content-type "application/json"
													:content datajson
													:method :POST))))
	     (data (cdr (nth 2 json-response)))
	     (zone (cdr (nth 3 json-response)))
	     (exp-delivery-date (cdr (nth 4 json-response)))
	     (shippingoptions (sort (remove nil (mapcar (lambda (logistic-alist)
							  (let ((logistic-name (cdr (nth 0 logistic-alist)))
								(logistic-service-type (cdr (nth 1 logistic-alist)))
								(logistic-id (cdr (nth 2 logistic-alist)))
								(rtocharges (cdr (nth 3 logistic-alist))) 
								(prepaid-p (cdr (nth 4 logistic-alist))) 
								(cod-p (cdr (nth 5 logistic-alist)))  
								(pickup-p (cdr (nth 6 logistic-alist)))   
								(reverse-pickup-p (cdr (nth 7 logistic-alist)))
								(weight-slab (float (with-input-from-string (in (cdr (nth 8 logistic-alist)))
										      (read in))))   
								(rate (cdr (nth 9 logistic-alist))))    
							    (when (<= total-weight weight-slab)
							      (list logistic-name logistic-service-type logistic-id rtocharges prepaid-p cod-p pickup-p reverse-pickup-p weight-slab rate zone exp-delivery-date)))) data)) #'< :key (lambda (elem) (nth 8 elem))))
	     (uniqueshipproviders (remove-duplicates (mapcar (lambda (elem)
							       (nth 0 elem)) shippingoptions) :test #'equal))
             (nearestweightslabs (find-nearest-shipping-options shippingoptions total-weight (length uniqueshipproviders))))
	(logiamhere (format nil "shipping options: ~A" shippingoptions))
	(logiamhere (format nil "nearest weight slabs : ~A" nearestweightslabs))
	(logiamhere (format nil  "unique shipping providers = ~d" (length uniqueshipproviders)))
	nearestweightslabs))))


(defun find-nearest-shipping-options (list x k)
  ;; Create a priority queue to store the K nearest numbers of a list.
  (let ((maxheap (priority-queue:make-pqueue #'>))
	(targetlist nil))
    (loop for elem in list do
      (priority-queue:pqueue-push elem (abs (- x (nth 8 elem))) maxheap)
	(if (> (priority-queue:pqueue-length maxheap) k)
	    (priority-queue:pqueue-pop maxheap)))

    (loop for i from 1 to (priority-queue:pqueue-length maxheap)
	  do
	     (setf targetlist (append targetlist (list (priority-queue:pqueue-front-value maxheap))))
	     (priority-queue:pqueue-pop maxheap))
    (reverse (remove nil targetlist))))


(defun find-nearest-elements (list x k)
  ;; Create a priority queue to store the K nearest numbers of a list.
  (let ((maxheap (priority-queue:make-pqueue #'>))
	(targetlist nil))
    (loop for elem in list do
      (priority-queue:pqueue-push elem (abs (- x elem)) maxheap)
	(if (> (priority-queue:pqueue-length maxheap) k)
	    (priority-queue:pqueue-pop maxheap)))

    (loop for i from 1 to (priority-queue:pqueue-length maxheap)
	  do (setf targetlist (append targetlist (list (priority-queue:pqueue-front-value maxheap)))))
    (remove nil targetlist)))
