;;; nst-tst-warehouse.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*- 
;; nst-tst-warehouse.lisp
;; UPDATED Test framework for Warehouse entity CRUD operations (41 fields with ownership)
(in-package :nstores) 
(defparameter *warehouse-id* nil)
;;; ===========================================================================
;;; TRADITIONAL ADAPTER-BASED TESTS (with all 41 fields including ownership)
;;; ===========================================================================

;;; ---------------------------------------------------------------------------
;;; CREATE Test
;;; ---------------------------------------------------------------------------
(defun test-warehouse-DBSave ()
  "Test creating a new warehouse record with full GST compliance and ownership fields"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      ;; Basic fields
				      :warehouse-code "WH-EB70DB91"   
				      :warehouse-uuid (generate-warehouse-uuid)
				      :wname (format nil "Main Distribution Center ~A" (hhub-random-password 5))
                                      :waddr1 "123 Industrial Park Road"
                                      :waddr2 "Building A, Floor 2"
                                      :wpin "400001"
                                      :wcity "Mumbai"
                                      :wstate "Maharashtra"
                                      :wcountry "India"
                                      :wmanager "Rajesh Kumar"
                                      :wphone "+91-22-12345678"
                                      :waltphone "+91-22-87654321"
                                      :wemail "warehouse.main@company.com"
                                      :activeflag "Y"
                                      ;; Ownership fields (NEW)
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :operator-entity-type "SELLER"
                                      :operator-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      ;; GST and Advanced Fields
                                      :warehouse-gstin "27AABCU9603R1ZM"
                                      :gstin-status "ACTIVE"
                                      :legal-name "ABC Industries Private Limited"
                                      :is-primary-location 1
                                      :state-code "27"
                                      :registration-type "REGULAR"
                                      :warehouse-type "OWN"
                                      :warehouse-purpose "SALES"
                                      :default-transporter-id "TRANS001"
                                      :default-transporter-name "Fast Logistics Pvt Ltd"
                                      :eway-bill-enabled 1
                                      :latitude 19.0760
                                      :longitude 72.8777
                                      :valuation-method "FIFO"
                                      :hsn-wise-stock 1
                                      :pan-number "AABCU9603R"
                                      :company company
                                      :vendor vendor)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case
        (let ((result (ProcessCreateRequest warehouseadapter requestmodel)))
          (format t "✓ Created warehouse: ~A (GSTIN: ~A, Owner: ~A)~%" 
		  (slot-value result 'wname)
                  (slot-value result 'warehouse-gstin)
                  (slot-value result 'ownership-type))
	  (setf *warehouse-id* (slot-value result 'row-id))
	  result)
      (error (c)  
        (error 'hhub-business-function-error 
               :errstring (format nil "Got an exception during warehouse create: ~A" c))))))

;;; ---------------------------------------------------------------------------
;;; UPDATE Test
;;; ---------------------------------------------------------------------------
(defun test-warehouse-DBUpdate ()
  "Test updating an existing warehouse record with GST and ownership fields"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      ;; Basic fields
				      :row-id *warehouse-id*
				      :warehouse-uuid (generate-warehouse-uuid)
				      :warehouse-code (generate-warehouse-short-code)
				      :wname (format nil "Main Distribution Center ~A" (hhub-random-password 4))
                                      :waddr1 "456 New Industrial Estate"
                                      :waddr2 "Building B, Floor 3"
                                      :wpin "400002"
                                      :wcity "Mumbai"
                                      :wstate "Maharashtra"
                                      :wcountry "India"
                                      :wmanager "Priya Sharma"
                                      :wphone "+91-22-11112222"
                                      :waltphone "+91-22-33334444"
                                      :wemail "warehouse.updated@company.com"
                                      :activeflag "Y"
                                      ;; Ownership fields - can be changed (e.g., transfer to 3PL)
                                      :ownership-type "THIRD_PARTY"
                                      :owner-entity-type "THIRD_PARTY_LOGISTICS"
                                      :owner-entity-id vendor-id
                                      :operator-entity-type "THIRD_PARTY_LOGISTICS"
                                      :operator-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      ;; Updated GST Fields
                                      :warehouse-gstin "27AABCU9603R1ZM"
                                      :gstin-status "ACTIVE"
                                      :legal-name "ABC Industries Private Limited - Updated"
                                      :is-primary-location 1
                                      :state-code "27"
                                      :registration-type "REGULAR"
                                      :warehouse-type "THIRD_PARTY"
                                      :warehouse-purpose "BOTH"
                                      :default-transporter-id "TRANS002"
                                      :default-transporter-name "Express Cargo Services"
                                      :eway-bill-enabled 1
                                      :latitude 19.0800
                                      :longitude 72.8800
                                      :valuation-method "WEIGHTED_AVG"
                                      :hsn-wise-stock 1
                                      :pan-number "AABCU9603R"
                                      :company company
                                      :vendor vendor)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case 
	(with-nst-debugger
	(let ((result (ProcessUpdateRequest warehouseadapter requestmodel)))
	  (format t "✓ Updated warehouse: ~A (New ownership: ~A)~%" 
                  (slot-value result 'wname)
                  (slot-value result 'ownership-type))
          result))
      (error (c) 
        (error 'hhub-business-function-error 
               :errstring (format nil "Got an exception during warehouse update: ~A" c))))))

;;; ---------------------------------------------------------------------------
;;; READ Test (Single Warehouse)
;;; ---------------------------------------------------------------------------
(defun test-warehouse-DBRead ()
  "Test reading a single warehouse record with all fields including ownership"
  (let* ((company (select-company-by-id 2))
         (warehouse-name "Main Distribution Center")
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      :wname warehouse-name
                                      :row-id *warehouse-id*
                                      :company company)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case
	(with-nst-debugger
        (let* ((warehouse (ProcessReadRequest warehouseadapter requestmodel))
               (knowledge (bo-knowledge warehouseadapter)))
          (case (bo-knowledge-truth knowledge)
            (:T (format t "✓ Successfully read warehouse: ~A~%" 
                       (slot-value warehouse 'wname))
                (format t "  GSTIN: ~A~%" (slot-value warehouse 'warehouse-gstin))
                (format t "  Ownership Type: ~A~%" (slot-value warehouse 'ownership-type))
                (format t "  Owner Entity Type: ~A~%" (slot-value warehouse 'owner-entity-type))
                (format t "  Warehouse Type: ~A~%" (slot-value warehouse 'warehouse-type))
                (format t "  Location: ~A, ~A~%" 
                       (slot-value warehouse 'latitude)
                       (slot-value warehouse 'longitude)))
            (:F (format t "✗ Warehouse not found~%"))
            (:U (format t "✗ Unknown error reading warehouse~%"))
            (:C (format t "✗ Contradiction in warehouse data~%")))
          warehouse))
      (error (c) 
        (error 'hhub-business-function-error 
               :errstring (format nil "Got an exception during warehouse read: ~A" c))))))

;;; ---------------------------------------------------------------------------
;;; READ ALL Test
;;; ---------------------------------------------------------------------------
(defun test-warehouse-DBReadAll ()
  "Test reading all warehouse records for a vendor"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      :company company
                                      :vendor vendor)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case 
        (let ((warehouses (ProcessReadAllRequest warehouseadapter requestmodel)))
          (format t "✓ Successfully read ~A warehouses for vendor~%" (length warehouses))
          (dolist (wh warehouses)
            (format t "  - ~A (~A, owned by: ~A)~%" 
                   (slot-value wh 'wname)
                   (slot-value wh 'warehouse-type)
                   (slot-value wh 'ownership-type)))
          warehouses)
      (error (c) 
        (error 'hhub-business-function-error 
               :errstring (format nil "Got an exception during warehouse read-all: ~A" c))))))

;;; ---------------------------------------------------------------------------
;;; DELETE Test
;;; ---------------------------------------------------------------------------
(defun test-warehouse-DBDelete ()
  "Test soft deleting a warehouse record"
  (let* ((company (select-company-by-id 2))
	 (warehouse-name "Main Distribution Center")
         (requestmodel (make-instance 'WarehouseRequestModel 
				      :row-id *warehouse-id*
				      :wname warehouse-name
                                      :company company)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case 
        (let ((result (ProcessDeleteRequest warehouseadapter requestmodel)))
          (format t "✓ Deleted warehouse: ~A~%" result)
          result)
      (error (c) 
        (error 'hhub-business-function-error 
               :errstring (format nil "Got an exception during warehouse delete: ~A" c))))))

;;; ---------------------------------------------------------------------------
;;; SEARCH Test (by partial name match)
;;; ---------------------------------------------------------------------------
(defun test-warehouse-DBSearch ()
  "Test searching warehouses by partial name"
  (let* ((company (select-company-by-id 2))
         (search-term "Distribution")
         (requestmodel (make-instance 'WarehouseSearchRequestModel 
                                      :wname search-term
                                      :company company)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case 
        (let ((warehouses (ProcessReadAllRequest warehouseadapter requestmodel)))
          (format t "✓ Found ~A warehouses matching '~A'~%" 
                  (length warehouses) search-term)
          warehouses)
      (error (c) 
        (error 'hhub-business-function-error 
               :errstring (format nil "Got an exception during warehouse search: ~A" c))))))

;;; ===========================================================================
;;; CONTEXT FLOW DISPATCHER TESTS (with all 41 fields including ownership)
;;; ===========================================================================

;;; ---------------------------------------------------------------------------
;;; Test Context Flow Dispatcher - CREATE
;;; ---------------------------------------------------------------------------
(defun test-context-warehouse-create ()
  "Test warehouse creation using context flow dispatcher with ownership fields"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (raw-params (list :wname (format nil "Context Flow Warehouse ~A" (hhub-random-password 4))
			   :warehouse-code (generate-warehouse-short-code)
			   :warehouse-uuid (generate-warehouse-uuid)
                          :waddr1 "789 Dispatcher Avenue"
                          :waddr2 "Suite 100"
                          :wpin "400003"
                          :wcity "Pune"
                          :wstate "Maharashtra"
                          :wcountry "India"
                          :wmanager "Context Manager"
                          :wphone "+91-20-99998888"
                          :waltphone "+91-20-77776666"
                          :wemail "context.warehouse@company.com"
                          :activeflag "Y"
                          ;; Ownership fields
                          :ownership-type "SELLER_OWNED"
                          :owner-entity-type "SELLER"
                          :owner-entity-id vendor-id
                          :operator-entity-type "SELLER"
                          :operator-entity-id vendor-id
                          :legal-entity-type "SELLER"
                          ;; GST and Advanced Fields
                          :warehouse-gstin "27DEFGH1234P1ZX"
                          :gstin-status "ACTIVE"
                          :legal-name "Context Flow Logistics Ltd"
                          :is-primary-location 0
                          :state-code "27"
                          :registration-type "REGULAR"
                          :warehouse-type "THIRD_PARTY"
                          :warehouse-purpose "STOCK_TRANSFER"
                          :default-transporter-id "TRANS003"
                          :default-transporter-name "Swift Transport Co"
                          :eway-bill-enabled 1
                          :latitude 18.5204
                          :longitude 73.8567
                          :valuation-method "FIFO"
                          :hsn-wise-stock 0
                          :pan-number "DEFGH1234P"
                          :company company
                          :vendor vendor)))
    (handler-case
	(with-nst-debugger
	(let* ((result (dispatch-route :warehouse/create 
                                       raw-params
                                       :request-uri "/hhub/vcreatewarehouse"
                                       :trans-func-name "com-hhub-transaction-create-warehouse"
                                       :output-type 'json))
	       (warehouseobj (ctx-domain-object result)))
	  (setf *warehouse-id* (slot-value warehouseobj 'row-id))
          (format t "✓ Context dispatcher CREATE returned Warehouse object (ownership included): ~A~%" (ctx-domain-object result))
	  result))
      (error (condition)
        (let ((exceptionstr (format nil "Context dispatcher CREATE failed :~A: ~a~%" 
                                    (mysql-now) condition)))
          (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
                                  :direction :output
                                  :if-exists :append
                                  :if-does-not-exist :create)
            (format stream "~A~A" exceptionstr (sb-debug:list-backtrace)))
          (error 'hhub-abac-transaction-error :errstring exceptionstr))))))

;;; ---------------------------------------------------------------------------
;;; Test Context Flow Dispatcher - READ
;;; ---------------------------------------------------------------------------
(defun test-context-warehouse-read ()
  "Test warehouse read using context flow dispatcher"
  (let* ((company (select-company-by-id 2))
         (raw-params (list :wname "Context Flow Warehouse"
			   :row-id *warehouse-id*
                           :company company)))
    (handler-case
        (let ((result (dispatch-route :warehouse/read 
                                      raw-params
                                      :request-uri "/hhub/vreadwarehouse/"
                                      :trans-func-name "com-hhub-transaction-read-warehouse"
                                      :output-type 'json)))
          (format t "✓ Context dispatcher READ returned (with ownership): ~A~%" result)
          result)
      (error (c)
        (format t "✗ Context dispatcher READ failed: ~A~%" c)))))

;;; ---------------------------------------------------------------------------
;;; Test Context Flow Dispatcher - READALL
;;; ---------------------------------------------------------------------------
(defun test-context-warehouse-readall ()
  "Test warehouse readall using context flow dispatcher with vendor"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (raw-params (list :company company :vendor vendor)))
    (handler-case
	(with-nst-debugger
	(let ((result (dispatch-route :warehouse/readall 
                                      raw-params
                                      :request-uri "/hhub/vreadallwarehouse"
                                      :trans-func-name "com-hhub-transaction-readall-warehouse"
                                      :output-type 'json)))
          (format t "✓ Context dispatcher READALL returned (vendor's warehouses): ~A~%" result)
          result))
      (error (c)
        (format t "✗ Context dispatcher READALL failed: ~A~%" c)))))

;;; ---------------------------------------------------------------------------
;;; Test Context Flow Dispatcher - UPDATE
;;; ---------------------------------------------------------------------------
(defun test-context-warehouse-update ()
  "Test warehouse update using context flow dispatcher with ownership changes"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (raw-params (list
		      :row-id *warehouse-id*
		      :warehouse-code (generate-warehouse-short-code)
		      :warehouse-uuid (generate-warehouse-uuid)
		      :wname "Context Flow Warehouse"
                      :waddr1 "999 Updated Dispatcher Road"
                      :waddr2 "New Floor 5"
                      :wpin "411001"
                      :wcity "Pune"
                      :wstate "Maharashtra"
                      :wcountry "India"
                      :wmanager "Updated Manager"
                      :wphone "+91-20-11112222"
                      :waltphone "+91-20-33334444"
                      :wemail "updated.context@company.com"
                      :activeflag "Y"
                      ;; Changed ownership to BUYER_OWNED (VMI scenario)
                      :ownership-type "BUYER_OWNED"
                      :owner-entity-type "BUYER"
                      :owner-entity-id vendor-id
                      :operator-entity-type "SELLER"
                      :operator-entity-id vendor-id
                      :legal-entity-type "BUYER"
                      ;; Updated GST Fields
                      :warehouse-gstin "27DEFGH1234P1ZX"
                      :gstin-status "ACTIVE"
                      :legal-name "Context Flow Logistics Ltd - Branch"
                      :is-primary-location 0
                      :state-code "27"
                      :registration-type "REGULAR"
                      :warehouse-type "CONSIGNMENT"
                      :warehouse-purpose "BOTH"
                      :default-transporter-id "TRANS004"
                      :default-transporter-name "Ultra Fast Logistics"
                      :eway-bill-enabled 1
                      :latitude 18.5300
                      :longitude 73.8600
                      :valuation-method "LIFO"
                      :hsn-wise-stock 1
                      :pan-number "DEFGH1234P"
                      :company company
                      :vendor vendor)))
    (handler-case
	(with-nst-debugger
	(let ((result (dispatch-route :warehouse/update 
                                      raw-params
				      :request-uri "/hhub/vupdatewarehouse/"
				      :trans-func-name "com-hhub-transaction-update-warehouse"
                                      :output-type 'json)))
          (format t "✓ Context dispatcher UPDATE returned (ownership changed to BUYER_OWNED): ~A~%" result)
          result))
      (error (c)
        (format t "✗ Context dispatcher UPDATE failed: ~A~%" c)))))

;;; ---------------------------------------------------------------------------
;;; Test Context Flow Dispatcher - DELETE
;;; ---------------------------------------------------------------------------
(defun test-context-warehouse-delete ()
  "Test warehouse delete using context flow dispatcher"
  (let* ((company (select-company-by-id 2))
         (raw-params (list :wname "Context Flow Warehouse"
			   :row-id *warehouse-id*
			   :company company)))
    (handler-case
        (let ((result (dispatch-route :warehouse/delete 
                                      raw-params
				      :request-uri "/hhub/vdeletewarehouse/"  
				      :trans-func-name "com-hhub-transaction-delete-warehouse"
                                      :output-type 'json)))
          (format t "✓ Context dispatcher DELETE returned: ~A~%" result)
          result)
      (error (c)
        (format t "✗ Context dispatcher DELETE failed: ~A~%" c)))))

;;; ===========================================================================
;;; ROUTE REGISTRATION TESTS
;;; ===========================================================================

(defun test-warehouse-route-registration ()
  "Test that all warehouse routes are properly registered"
  (format t "~%Testing warehouse route registration...~%")
  (let ((routes '(:warehouse/create 
                  :warehouse/read 
                  :warehouse/readall 
                  :warehouse/update 
                  :warehouse/delete))
        (all-registered t))
    (dolist (route-key routes)
      (let ((route (find-outbound-route route-key)))
        (if route
            (format t "✓ Route ~A is registered~%" route-key)
            (progn
              (format t "✗ Route ~A is NOT registered~%" route-key)
              (setf all-registered nil)))))
    (if all-registered
        (format t "~%✓ All warehouse routes are registered~%")
        (format t "~%✗ Some warehouse routes are missing~%"))
    all-registered))

(defun test-warehouse-route-metadata ()
  "Test that warehouse routes have correct metadata"
  (format t "~%Testing warehouse route metadata...~%")
  (let ((route (find-outbound-route :warehouse/create)))
    (when route
      (format t "Route: ~A~%" (route-key route))
      (format t "  Description: ~A~%" (description route))
      (format t "  CRUD Op: ~A~%" (crud-op route))
      (format t "  Request Model: ~A~%" (requestmodel-class route))
      (format t "  Business Object: ~A~%" (businessobject-class route))
      (format t "  Adapter: ~A~%" (adapter-class route))
      (format t "  Presenter: ~A~%" (presenter-class route))
      (format t "  View Classes: ~A~%" (view-classes route))
      (format t "  Required Roles: ~A~%" (required-roles route))
      (format t "  Tags: ~A~%" (tags route))
      (format t "  Audit Level: ~A~%" (audit-level route))
      (format t "  Feature Flags: ~A~%~%" (feature-flags route)))))

;;; ===========================================================================
;;; VALIDATION TESTS (GST, Advanced Fields, and Ownership)
;;; ===========================================================================

(defun test-warehouse-validation-empty-name ()
  "Test validation for empty warehouse name"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      :wname ""
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      :company company
                                      :vendor vendor)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case 
        (progn
          (ProcessCreateRequest warehouseadapter requestmodel)
          (format t "✗ Validation FAILED - empty name was accepted~%"))
      (error (c)  
        (format t "✓ Validation PASSED - empty name rejected: ~A~%" c)))))

(defun test-warehouse-validation-invalid-ownership ()
  "Test validation for missing required ownership fields"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      :wname "Test Warehouse"
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      ;; Missing owner-entity-id (should fail)
                                      :legal-entity-type "SELLER"
                                      :company company
                                      :vendor vendor)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case 
        (progn
          (ProcessCreateRequest warehouseadapter requestmodel)
          (format t "✗ Validation FAILED - missing owner-entity-id was accepted~%"))
      (error (c)  
        (format t "✓ Validation PASSED - missing owner-entity-id rejected: ~A~%" c)))))

(defun test-warehouse-validation-invalid-pin ()
  "Test validation for invalid PIN code (too long)"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      :wname "Test Warehouse"
                                      :wpin "12345678"  ; Invalid - too long (max 6)
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      :company company
                                      :vendor vendor)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case 
        (progn
          (ProcessCreateRequest warehouseadapter requestmodel)
          (format t "✗ Validation FAILED - invalid PIN was accepted~%"))
      (error (c)  
        (format t "✓ Validation PASSED - invalid PIN rejected: ~A~%" c)))))

(defun test-warehouse-validation-invalid-gstin ()
  "Test validation for invalid GSTIN format"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      :wname "Test Warehouse"
                                      :warehouse-gstin "INVALID_GSTIN_FORMAT"  ; Invalid format
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      :company company
                                      :vendor vendor)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case 
        (progn
          (ProcessCreateRequest warehouseadapter requestmodel)
          (format t "✗ Validation FAILED - invalid GSTIN was accepted~%"))
      (error (c)  
        (format t "✓ Validation PASSED - invalid GSTIN rejected: ~A~%" c)))))

(defun test-warehouse-validation-invalid-state-code ()
  "Test validation for invalid state code (not 2 digits)"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      :wname "Test Warehouse"
                                      :state-code "999"  ; Invalid - should be 2 digits
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      :company company
                                      :vendor vendor)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case 
        (progn
          (ProcessCreateRequest warehouseadapter requestmodel)
          (format t "✗ Validation FAILED - invalid state code was accepted~%"))
      (error (c)  
        (format t "✓ Validation PASSED - invalid state code rejected: ~A~%" c)))))

(defun test-warehouse-validation-invalid-pan ()
  "Test validation for invalid PAN format"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      :wname "Test Warehouse"
                                      :pan-number "INVALIDPAN123"  ; Invalid - too long
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      :company company
                                      :vendor vendor)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case 
        (progn
          (ProcessCreateRequest warehouseadapter requestmodel)
          (format t "✗ Validation FAILED - invalid PAN was accepted~%"))
      (error (c)  
        (format t "✓ Validation PASSED - invalid PAN rejected: ~A~%" c)))))

(defun test-warehouse-validation-gps-coordinates ()
  "Test validation for GPS coordinates range"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      :wname "Test Warehouse"
                                      :latitude 200.0  ; Invalid - out of range
                                      :longitude 200.0 ; Invalid - out of range
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      :company company
                                      :vendor vendor)) 
         (warehouseadapter (make-instance 'WarehouseAdapter))) 
    (handler-case 
        (progn
          (ProcessCreateRequest warehouseadapter requestmodel)
          (format t "✗ Validation FAILED - invalid GPS coordinates were accepted~%"))
      (error (c)  
        (format t "✓ Validation PASSED - invalid GPS coordinates rejected: ~A~%" c)))))

;;; ===========================================================================
;;; GST-SPECIFIC FEATURE TESTS (with ownership)
;;; ===========================================================================

(defun test-warehouse-primary-location ()
  "Test primary warehouse location functionality with ownership"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel1 (make-instance 'WarehouseRequestModel 
                                      ;; Basic fields
				      :warehouse-code "WH-EB70DB91"   
				      :warehouse-uuid (generate-warehouse-uuid)
				      :wname (format nil "Main Distribution Center ~A" (hhub-random-password 5))
                                      :waddr1 "123 Industrial Park Road"
                                      :waddr2 "Building A, Floor 2"
                                      :wpin "400001"
                                      :wcity "Mumbai"
                                      :wstate "Maharashtra"
                                      :wcountry "India"
                                      :wmanager "Rajesh Kumar"
                                      :wphone "+91-22-12345678"
                                      :waltphone "+91-22-87654321"
                                      :wemail "warehouse.main@company.com"
                                      :activeflag "Y"
                                      ;; Ownership fields (NEW)
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :operator-entity-type "SELLER"
                                      :operator-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      ;; GST and Advanced Fields
                                      :warehouse-gstin "27AABCU9603R1ZM"
                                      :gstin-status "ACTIVE"
                                      :legal-name "ABC Industries Private Limited"
                                      :is-primary-location 1
                                      :state-code "27"
                                      :registration-type "REGULAR"
                                      :warehouse-type "OWN"
                                      :warehouse-purpose "SALES"
                                      :default-transporter-id "TRANS001"
                                      :default-transporter-name "Fast Logistics Pvt Ltd"
                                      :eway-bill-enabled 1
                                      :latitude 19.0760
                                      :longitude 72.8777
                                      :valuation-method "FIFO"
                                      :hsn-wise-stock 1
                                      :pan-number "AABCU9603R"
                                      :company company
                                      :vendor vendor))
         (requestmodel2 (make-instance 'WarehouseRequestModel 
                                      ;; Basic fields
				      :warehouse-code "WH-EB70DB91"   
				      :warehouse-uuid (generate-warehouse-uuid)
				      :wname (format nil "Main Distribution Center ~A" (hhub-random-password 5))
                                      :waddr1 "123 Industrial Park Road"
                                      :waddr2 "Building A, Floor 2"
                                      :wpin "400001"
                                      :wcity "Mumbai"
                                      :wstate "Maharashtra"
                                      :wcountry "India"
                                      :wmanager "Rajesh Kumar"
                                      :wphone "+91-22-12345678"
                                      :waltphone "+91-22-87654321"
                                      :wemail "warehouse.main@company.com"
                                      :activeflag "Y"
                                      ;; Ownership fields (NEW)
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :operator-entity-type "SELLER"
                                      :operator-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      ;; GST and Advanced Fields
                                      :warehouse-gstin "27AABCU9603R1ZM"
                                      :gstin-status "ACTIVE"
                                      :legal-name "ABC Industries Private Limited"
                                      :is-primary-location 0
                                      :state-code "27"
                                      :registration-type "REGULAR"
                                      :warehouse-type "OWN"
                                      :warehouse-purpose "SALES"
                                      :default-transporter-id "TRANS001"
                                      :default-transporter-name "Fast Logistics Pvt Ltd"
                                      :eway-bill-enabled 1
                                      :latitude 19.0760
                                      :longitude 72.8777
                                      :valuation-method "FIFO"
                                      :hsn-wise-stock 1
                                      :pan-number "AABCU9603R"
                                      :company company
                                      :vendor vendor))
         (adapter1 (make-instance 'WarehouseAdapter))
         (adapter2 (make-instance 'WarehouseAdapter)))
    (handler-case
        (progn
          (ProcessCreateRequest adapter1 requestmodel1)
          (ProcessCreateRequest adapter2 requestmodel2)
          (format t "✓ Primary location test passed (with ownership)~%"))
      (error (c)
        (format t "✗ Primary location test failed: ~A~%" c)))))

(defun test-warehouse-eway-bill-configuration ()
  "Test e-way bill enabled/disabled functionality"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel  (make-instance 'WarehouseRequestModel 
                                      ;; Basic fields
				      :warehouse-code "WH-EB70DB91"   
				      :warehouse-uuid (generate-warehouse-uuid)
				      :wname (format nil "Main Distribution Center ~A" (hhub-random-password 5))
                                      :waddr1 "123 Industrial Park Road"
                                      :waddr2 "Building A, Floor 2"
                                      :wpin "400001"
                                      :wcity "Mumbai"
                                      :wstate "Maharashtra"
                                      :wcountry "India"
                                      :wmanager "Rajesh Kumar"
                                      :wphone "+91-22-12345678"
                                      :waltphone "+91-22-87654321"
                                      :wemail "warehouse.main@company.com"
                                      :activeflag "Y"
                                      ;; Ownership fields (NEW)
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :operator-entity-type "SELLER"
                                      :operator-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      ;; GST and Advanced Fields
                                      :warehouse-gstin "27AABCU9603R1ZM"
                                      :gstin-status "ACTIVE"
                                      :legal-name "ABC Industries Private Limited"
                                      :is-primary-location 1
                                      :state-code "27"
                                      :registration-type "REGULAR"
                                      :warehouse-type "OWN"
                                      :warehouse-purpose "SALES"
                                      :default-transporter-id "TRANS001"
                                      :default-transporter-name "Fast Logistics Pvt Ltd"
                                      :eway-bill-enabled 1
                                      :latitude 19.0760
                                      :longitude 72.8777
                                      :valuation-method "FIFO"
                                      :hsn-wise-stock 1
                                      :pan-number "AABCU9603R"
                                      :company company
                                      :vendor vendor))
	 (adapter (make-instance 'WarehouseAdapter)))
    (handler-case
        (let ((result (ProcessCreateRequest adapter requestmodel)))
          (if (equal (slot-value result 'eway-bill-enabled) 1)
              (format t "✓ E-Way bill configuration test passed~%")
              (format t "✗ E-Way bill configuration test failed~%")))
      (error (c)
        (format t "✗ E-Way bill test failed: ~A~%" c)))))

(defun test-warehouse-hsn-stock-tracking ()
  "Test HSN-wise stock tracking configuration"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      ;; Basic fields
				      :warehouse-code (generate-warehouse-short-code)
				      :warehouse-uuid (generate-warehouse-uuid)
				      :wname (format nil "Main Distribution Center ~A" (hhub-random-password 5))
                                      :waddr1 "123 Industrial Park Road"
                                      :waddr2 "Building A, Floor 2"
                                      :wpin "400001"
                                      :wcity "Mumbai"
                                      :wstate "Maharashtra"
                                      :wcountry "India"
                                      :wmanager "Rajesh Kumar"
                                      :wphone "+91-22-12345678"
                                      :waltphone "+91-22-87654321"
                                      :wemail "warehouse.main@company.com"
                                      :activeflag "Y"
                                      ;; Ownership fields (NEW)
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :operator-entity-type "SELLER"
                                      :operator-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      ;; GST and Advanced Fields
                                      :warehouse-gstin "27AABCU9603R1ZM"
                                      :gstin-status "ACTIVE"
                                      :legal-name "ABC Industries Private Limited"
                                      :is-primary-location 1
                                      :state-code "27"
                                      :registration-type "REGULAR"
                                      :warehouse-type "OWN"
                                      :warehouse-purpose "SALES"
                                      :default-transporter-id "TRANS001"
                                      :default-transporter-name "Fast Logistics Pvt Ltd"
                                      :eway-bill-enabled 1
                                      :latitude 19.0760
                                      :longitude 72.8777
                                      :valuation-method "WEIGHTED_AVG"
                                      :hsn-wise-stock 1
                                      :pan-number "AABCU9603R"
                                      :company company
                                      :vendor vendor))
         (adapter (make-instance 'WarehouseAdapter)))
    (handler-case
        (let ((result (ProcessCreateRequest adapter requestmodel)))
          (if (and (equal (slot-value result 'hsn-wise-stock) 1)
                   (equal (slot-value result 'valuation-method) "WEIGHTED_AVG"))
              (format t "✓ HSN stock tracking test passed~%")
              (format t "✗ HSN stock tracking test failed~%")))
      (error (c)
        (format t "✗ HSN stock test failed: ~A~%" c)))))

;;; ===========================================================================
;;; OWNERSHIP-SPECIFIC FEATURE TESTS (NEW)
;;; ===========================================================================

(defun test-warehouse-seller-owned ()
  "Test SELLER_OWNED warehouse creation"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      ;; Basic fields
				      :warehouse-code (generate-warehouse-short-code)
				      :warehouse-uuid (generate-warehouse-uuid)
				      :wname (format nil "Main Distribution Center ~A" (hhub-random-password 5))
                                      :waddr1 "123 Industrial Park Road"
                                      :waddr2 "Building A, Floor 2"
                                      :wpin "400001"
                                      :wcity "Mumbai"
                                      :wstate "Maharashtra"
                                      :wcountry "India"
                                      :wmanager "Rajesh Kumar"
                                      :wphone "+91-22-12345678"
                                      :waltphone "+91-22-87654321"
                                      :wemail "warehouse.main@company.com"
                                      :activeflag "Y"
                                      ;; Ownership fields (NEW)
                                      :ownership-type "SELLER_OWNED"
                                      :owner-entity-type "SELLER"
                                      :owner-entity-id vendor-id
                                      :operator-entity-type "SELLER"
                                      :operator-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      ;; GST and Advanced Fields
                                      :warehouse-gstin "27AABCU9603R1ZM"
                                      :gstin-status "ACTIVE"
                                      :legal-name "ABC Industries Private Limited"
                                      :is-primary-location 1
                                      :state-code "27"
                                      :registration-type "REGULAR"
                                      :warehouse-type "OWN"
                                      :warehouse-purpose "SALES"
                                      :default-transporter-id "TRANS001"
                                      :default-transporter-name "Fast Logistics Pvt Ltd"
                                      :eway-bill-enabled 1
                                      :latitude 19.0760
                                      :longitude 72.8777
                                      :valuation-method "WEIGHTED_AVG"
                                      :hsn-wise-stock 1
                                      :pan-number "AABCU9603R"
                                      :company company
                                      :vendor vendor))
         (adapter (make-instance 'WarehouseAdapter)))
    (handler-case
        (let ((result (ProcessCreateRequest adapter requestmodel)))
          (if (equal (slot-value result 'ownership-type) "SELLER_OWNED")
              (format t "✓ SELLER_OWNED warehouse test passed~%")
              (format t "✗ SELLER_OWNED warehouse test failed~%")))
      (error (c)
        (format t "✗ SELLER_OWNED test failed: ~A~%" c)))))

(defun test-warehouse-buyer-owned-vmi ()
  "Test BUYER_OWNED warehouse (VMI scenario)"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      ;; Basic fields
				      :warehouse-code (generate-warehouse-short-code)
				      :warehouse-uuid (generate-warehouse-uuid)
				      :wname (format nil "Main Distribution Center ~A" (hhub-random-password 5))
                                      :waddr1 "123 Industrial Park Road"
                                      :waddr2 "Building A, Floor 2"
                                      :wpin "400001"
                                      :wcity "Mumbai"
                                      :wstate "Maharashtra"
                                      :wcountry "India"
                                      :wmanager "Rajesh Kumar"
                                      :wphone "+91-22-12345678"
                                      :waltphone "+91-22-87654321"
                                      :wemail "warehouse.main@company.com"
                                      :activeflag "Y"
                                      ;; Ownership fields (NEW)
                                      :ownership-type "BUYER_OWNED"
                                      :owner-entity-type "BUYER"
                                      :owner-entity-id vendor-id
                                      :operator-entity-type "SELLER"
                                      :operator-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      ;; GST and Advanced Fields
                                      :warehouse-gstin "27AABCU9603R1ZM"
                                      :gstin-status "ACTIVE"
                                      :legal-name "ABC Industries Private Limited"
                                      :is-primary-location 1
                                      :state-code "27"
                                      :registration-type "REGULAR"
                                      :warehouse-type "CONSIGNMENT"
                                      :warehouse-purpose "SALES"
                                      :default-transporter-id "TRANS001"
                                      :default-transporter-name "Fast Logistics Pvt Ltd"
                                      :eway-bill-enabled 1
                                      :latitude 19.0760
                                      :longitude 72.8777
                                      :valuation-method "WEIGHTED_AVG"
                                      :hsn-wise-stock 1
                                      :pan-number "AABCU9603R"
                                      :company company
                                      :vendor vendor))
         (adapter (make-instance 'WarehouseAdapter)))
    (handler-case
        (let ((result (ProcessCreateRequest adapter requestmodel)))
          (if (and (equal (slot-value result 'ownership-type) "BUYER_OWNED")
                   (equal (slot-value result 'warehouse-type) "CONSIGNMENT"))
              (format t "✓ BUYER_OWNED (VMI) warehouse test passed~%")
              (format t "✗ BUYER_OWNED (VMI) warehouse test failed~%")))
      (error (c)
        (format t "✗ BUYER_OWNED VMI test failed: ~A~%" c)))))

(defun test-warehouse-third-party-3pl ()
  "Test THIRD_PARTY warehouse (3PL scenario)"
  (let* ((company (select-company-by-id 2))
         (vendor (select-vendor-by-id 1))
         (vendor-id (slot-value vendor 'row-id))
         (requestmodel (make-instance 'WarehouseRequestModel 
                                      ;; Basic fields
				      :warehouse-code (generate-warehouse-short-code)
				      :warehouse-uuid (generate-warehouse-uuid)
				      :wname (format nil "Main Distribution Center ~A" (hhub-random-password 5))
                                      :waddr1 "123 Industrial Park Road"
                                      :waddr2 "Building A, Floor 2"
                                      :wpin "400001"
                                      :wcity "Mumbai"
                                      :wstate "Maharashtra"
                                      :wcountry "India"
                                      :wmanager "Rajesh Kumar"
                                      :wphone "+91-22-12345678"
                                      :waltphone "+91-22-87654321"
                                      :wemail "warehouse.main@company.com"
                                      :activeflag "Y"
                                      ;; Ownership fields (NEW)
                                      :ownership-type "THIRD_PARTY"
                                      :owner-entity-type "BUYER"
                                      :owner-entity-id vendor-id
                                      :operator-entity-type "SELLER"
                                      :operator-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      ;; GST and Advanced Fields
                                      :warehouse-gstin "27AABCU9603R1ZM"
                                      :gstin-status "ACTIVE"
                                      :legal-name "ABC Industries Private Limited"
                                      :is-primary-location 1
                                      :state-code "27"
                                      :registration-type "REGULAR"
                                      :warehouse-type "CONSIGNMENT"
                                      :warehouse-purpose "SALES"
                                      :default-transporter-id "TRANS001"
                                      :default-transporter-name "Fast Logistics Pvt Ltd"
                                      :eway-bill-enabled 1
                                      :latitude 19.0760
                                      :longitude 72.8777
                                      :valuation-method "WEIGHTED_AVG"
                                      :hsn-wise-stock 1
                                      :pan-number "AABCU9603R"
                                      :company company
                                      :vendor vendor))
         (adapter (make-instance 'WarehouseAdapter)))
    (handler-case
        (let ((result (ProcessCreateRequest adapter requestmodel)))
          (if (equal (slot-value result 'ownership-type) "THIRD_PARTY")
              (format t "✓ THIRD_PARTY (3PL) warehouse test passed~%")
              (format t "✗ THIRD_PARTY (3PL) warehouse test failed~%")))
      (error (c)
        (format t "✗ THIRD_PARTY 3PL test failed: ~A~%" c)))))

;;; ===========================================================================
;;; PRESENTATION LAYER TESTS (with ownership fields)
;;; ===========================================================================

(defun test-warehouse-response-to-viewmodel ()
  "Test ResponseModel to ViewModel transformation with all 41 fields"
  (let* ((company (select-company-by-id 2))
	 (vendor (select-vendor-by-id 1))
	 (vendor-id (slot-value vendor 'row-id))
         (responsemodel (make-instance 'WarehouseResponseModel 
				       :row-id *warehouse-id*
				       ;; Basic fields
				      :warehouse-code (generate-warehouse-short-code)
				      :warehouse-uuid (generate-warehouse-uuid)
				      :wname (format nil "Main Distribution Center ~A" (hhub-random-password 5))
                                      :waddr1 "123 Industrial Park Road"
                                      :waddr2 "Building A, Floor 2"
                                      :wpin "400001"
                                      :wcity "Mumbai"
                                      :wstate "Maharashtra"
                                      :wcountry "India"
                                      :wmanager "Rajesh Kumar"
                                      :wphone "+91-22-12345678"
                                      :waltphone "+91-22-87654321"
                                      :wemail "warehouse.main@company.com"
                                      :activeflag "Y"
                                      ;; Ownership fields (NEW)
                                      :ownership-type "THIRD_PARTY"
                                      :owner-entity-type "BUYER"
                                      :owner-entity-id vendor-id
                                      :operator-entity-type "SELLER"
                                      :operator-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      ;; GST and Advanced Fields
                                      :warehouse-gstin "27AABCU9603R1ZM"
                                      :gstin-status "ACTIVE"
                                      :legal-name "ABC Industries Private Limited"
                                      :is-primary-location 1
                                      :state-code "27"
                                      :registration-type "REGULAR"
                                      :warehouse-type "CONSIGNMENT"
                                      :warehouse-purpose "SALES"
                                      :default-transporter-id "TRANS001"
                                      :default-transporter-name "Fast Logistics Pvt Ltd"
                                      :eway-bill-enabled 1
                                      :latitude 19.0760
                                      :longitude 72.8777
                                      :valuation-method "WEIGHTED_AVG"
                                      :hsn-wise-stock 1
                                      :pan-number "AABCU9603R"
                                      :company company
                                      :vendor vendor))
         (presenter (make-instance 'WarehousePresenter)))
    (handler-case
        (let ((viewmodel (CreateViewModel presenter responsemodel)))
          (format t "✓ ViewModel created successfully (with ownership)~%")
          (format t "  Name: ~A~%" (slot-value viewmodel 'wname))
          (format t "  Ownership: ~A~%" (slot-value viewmodel 'ownership-type))
          (format t "  Owner Type: ~A~%" (slot-value viewmodel 'owner-entity-type))
          (format t "  GSTIN: ~A~%" (slot-value viewmodel 'warehouse-gstin))
          (format t "  Type: ~A~%" (slot-value viewmodel 'warehouse-type))
          (format t "  Valuation: ~A~%" (slot-value viewmodel 'valuation-method))
          viewmodel)
      (error (c)
        (format t "✗ ViewModel creation failed: ~A~%" c)))))

(defun test-warehouse-json-rendering ()
  "Test JSON rendering of warehouse viewmodel with all 41 fields including ownership"
  (let* ((company (select-company-by-id 2))
	 (vendor (select-vendor-by-id 1))
	 (vendor-id (slot-value vendor 'row-id))
         (viewmodel (make-instance 'WarehouseViewModel
				       :row-id *warehouse-id*
				       ;; Basic fields
				      :warehouse-code (generate-warehouse-short-code)
				      :warehouse-uuid (generate-warehouse-uuid)
				      :wname (format nil "Main Distribution Center ~A" (hhub-random-password 5))
                                      :waddr1 "123 Industrial Park Road"
                                      :waddr2 "Building A, Floor 2"
                                      :wpin "400001"
                                      :wcity "Mumbai"
                                      :wstate "Maharashtra"
                                      :wcountry "India"
                                      :wmanager "Rajesh Kumar"
                                      :wphone "+91-22-12345678"
                                      :waltphone "+91-22-87654321"
                                      :wemail "warehouse.main@company.com"
                                      :activeflag "Y"
                                      ;; Ownership fields (NEW)
                                      :ownership-type "THIRD_PARTY"
                                      :owner-entity-type "BUYER"
                                      :owner-entity-id vendor-id
                                      :operator-entity-type "SELLER"
                                      :operator-entity-id vendor-id
                                      :legal-entity-type "SELLER"
                                      ;; GST and Advanced Fields
                                      :warehouse-gstin "27AABCU9603R1ZM"
                                      :gstin-status "ACTIVE"
                                      :legal-name "ABC Industries Private Limited"
                                      :is-primary-location 1
                                      :state-code "27"
                                      :registration-type "REGULAR"
                                      :warehouse-type "CONSIGNMENT"
                                      :warehouse-purpose "SALES"
                                      :default-transporter-id "TRANS001"
                                      :default-transporter-name "Fast Logistics Pvt Ltd"
                                      :eway-bill-enabled 1
                                      :latitude 19.0760
                                      :longitude 72.8777
                                      :valuation-method "WEIGHTED_AVG"
                                      :hsn-wise-stock 1
                                      :pan-number "AABCU9603R"
                                      :company company
                                      :vendor vendor))
         (jsonview (make-instance 'WarehouseJSONView)))
    (handler-case
        (let ((json-output (RenderJSON jsonview viewmodel)))
          (format t "✓ JSON rendering successful (with ownership fields)~%")
          (format t "  Output length: ~A characters~%" (length json-output))
          json-output)
      (error (c)
        (format t "✗ JSON rendering failed: ~A~%" c)))))

;;; ===========================================================================
;;; COMPREHENSIVE TEST SUITE RUNNER
;;; ===========================================================================

(defun run-all-warehouse-tests ()
  "Run all warehouse test cases in sequence (41 fields with ownership)"
  (format t "~%~%=======================================================~%")
  (format t "   WAREHOUSE ENTITY COMPREHENSIVE TEST SUITE~%")
  (format t "   (Updated with 41 fields including ownership model)~%")
  (format t "=======================================================~%~%")
  
  ;; Part 1: Route Registration Tests
  (format t "~%PART 1: ROUTE REGISTRATION TESTS~%")
  (format t "-------------------------------------------------------~%")
  (test-warehouse-route-registration)
  (test-warehouse-route-metadata)
  
  ;; Part 2: Traditional Adapter Tests
  (format t "~%PART 2: TRADITIONAL ADAPTER-BASED TESTS~%")
  (format t "-------------------------------------------------------~%")
  
  (format t "~%TEST 1: Creating new warehouse (with ownership)...~%")
  (handler-case 
      (progn
        (test-warehouse-DBSave)
        (format t "✓ CREATE test passed~%"))
    (error (c) 
      (format t "✗ CREATE test failed: ~A~%" c)))
  
  (format t "~%TEST 2: Reading all vendor warehouses...~%")
  (handler-case 
      (progn
        (test-warehouse-DBReadAll)
        (format t "✓ READ ALL test passed~%"))
    (error (c) 
      (format t "✗ READ ALL test failed: ~A~%" c)))
  
  (format t "~%TEST 3: Reading single warehouse...~%")
  (handler-case 
      (progn
        (test-warehouse-DBRead)
        (format t "✓ READ test passed~%"))
    (error (c) 
      (format t "✗ READ test failed: ~A~%" c)))
  
  (format t "~%TEST 4: Searching warehouses by name...~%")
  (handler-case 
      (progn
        (test-warehouse-DBSearch)
        (format t "✓ SEARCH test passed~%"))
    (error (c) 
      (format t "✗ SEARCH test failed: ~A~%" c)))
  
  (format t "~%TEST 5: Updating warehouse (with ownership change)...~%")
  (handler-case 
      (progn
        (test-warehouse-DBUpdate)
        (format t "✓ UPDATE test passed~%"))
    (error (c) 
      (format t "✗ UPDATE test failed: ~A~%" c)))
  
  (format t "~%TEST 6: Deleting warehouse...~%")
  (handler-case 
      (progn
        (test-warehouse-DBDelete)
        (format t "✓ DELETE test passed~%"))
    (error (c) 
      (format t "✗ DELETE test failed: ~A~%" c)))
  
  ;; Part 3: Context Flow Dispatcher Tests
  (format t "~%PART 3: CONTEXT FLOW DISPATCHER TESTS~%")
  (format t "-------------------------------------------------------~%")
  
  (format t "~%TEST 7: Context dispatcher CREATE (with ownership)...~%")
  (test-context-warehouse-create)
  
  (format t "~%TEST 8: Context dispatcher READ...~%")
  (test-context-warehouse-read)
  
  (format t "~%TEST 9: Context dispatcher READALL (vendor's warehouses)...~%")
  (test-context-warehouse-readall)
  
  (format t "~%TEST 10: Context dispatcher UPDATE (ownership change)...~%")
  (test-context-warehouse-update)
  
  (format t "~%TEST 11: Context dispatcher DELETE...~%")
  (test-context-warehouse-delete)
  
  ;; Part 4: Validation Tests
  (format t "~%PART 4: VALIDATION TESTS~%")
  (format t "-------------------------------------------------------~%")
  
  (format t "~%TEST 12: Empty name validation...~%")
  (test-warehouse-validation-empty-name)
  
  (format t "~%TEST 13: Invalid ownership validation...~%")
  (test-warehouse-validation-invalid-ownership)
  
  (format t "~%TEST 14: Invalid PIN validation...~%")
  (test-warehouse-validation-invalid-pin)
  
  (format t "~%TEST 15: Invalid GSTIN validation...~%")
  (test-warehouse-validation-invalid-gstin)
  
  (format t "~%TEST 16: Invalid state code validation...~%")
  (test-warehouse-validation-invalid-state-code)
  
  (format t "~%TEST 17: Invalid PAN validation...~%")
  (test-warehouse-validation-invalid-pan)
  
  (format t "~%TEST 18: GPS coordinates validation...~%")
  (test-warehouse-validation-gps-coordinates)
  
  ;; Part 5: GST-Specific Feature Tests
  (format t "~%PART 5: GST-SPECIFIC FEATURE TESTS~%")
  (format t "-------------------------------------------------------~%")
  
  (format t "~%TEST 19: Primary location test...~%")
  (test-warehouse-primary-location)
  
  (format t "~%TEST 20: E-Way bill configuration...~%")
  (test-warehouse-eway-bill-configuration)
  
  (format t "~%TEST 21: HSN-wise stock tracking...~%")
  (test-warehouse-hsn-stock-tracking)
  
  ;; Part 6: Ownership-Specific Tests (NEW)
  (format t "~%PART 6: OWNERSHIP MODEL TESTS~%")
  (format t "-------------------------------------------------------~%")
  
  (format t "~%TEST 22: SELLER_OWNED warehouse...~%")
  (test-warehouse-seller-owned)
  
  (format t "~%TEST 23: BUYER_OWNED warehouse (VMI)...~%")
  (test-warehouse-buyer-owned-vmi)
  
  (format t "~%TEST 24: THIRD_PARTY warehouse (3PL)...~%")
  (test-warehouse-third-party-3pl)
  
  ;; Part 7: Presentation Layer Tests
  (format t "~%PART 7: PRESENTATION LAYER TESTS~%")
  (format t "-------------------------------------------------------~%")
  
  (format t "~%TEST 25: ResponseModel to ViewModel (with ownership)...~%")
  (test-warehouse-response-to-viewmodel)
  
  (format t "~%TEST 26: JSON rendering (with all 41 fields)...~%")
  (test-warehouse-json-rendering)
  
  (format t "~%~%=======================================================~%")
  (format t "   TEST SUITE COMPLETE~%")
  (format t "   Total Tests: 26 (added 3 ownership-specific tests)~%")
  (format t "=======================================================~%~%"))

;;; ===========================================================================
;;; QUICK TEST RUNNERS
;;; ===========================================================================

(defun run-adapter-tests-only ()
  "Run only traditional adapter-based tests"
  (format t "~%Running traditional adapter tests (with ownership)...~%")
  (test-warehouse-DBSave)
  (test-warehouse-DBRead)
  (test-warehouse-DBReadAll)
  (test-warehouse-DBUpdate)
  (test-warehouse-DBDelete))

(defun run-dispatcher-tests-only ()
  "Run only context flow dispatcher tests"
  (format t "~%Running context flow dispatcher tests (with ownership)...~%")
  (test-context-warehouse-create)
  (test-context-warehouse-read)
  (test-context-warehouse-readall)
  (test-context-warehouse-update)
  (test-context-warehouse-delete))

(defun run-validation-tests-only ()
  "Run only validation tests"
  (format t "~%Running validation tests (including ownership)...~%")
  (test-warehouse-validation-empty-name)
  (test-warehouse-validation-invalid-ownership)
  (test-warehouse-validation-invalid-pin)
  (test-warehouse-validation-invalid-gstin)
  (test-warehouse-validation-invalid-state-code)
  (test-warehouse-validation-invalid-pan)
  (test-warehouse-validation-gps-coordinates))

(defun run-gst-feature-tests-only ()
  "Run only GST-specific feature tests"
  (format t "~%Running GST-specific feature tests...~%")
  (test-warehouse-primary-location)
  (test-warehouse-eway-bill-configuration)
  (test-warehouse-hsn-stock-tracking))

(defun run-ownership-tests-only ()
  "Run only ownership model tests (NEW)"
  (format t "~%Running ownership model tests...~%")
  (test-warehouse-seller-owned)
  (test-warehouse-buyer-owned-vmi)
  (test-warehouse-third-party-3pl))

(defun run-presentation-tests-only ()
  "Run only presentation layer tests"
  (format t "~%Running presentation layer tests (with ownership)...~%")
  (test-warehouse-response-to-viewmodel)
  (test-warehouse-json-rendering))

;;; End of nst-tst-warehouse.lisp


