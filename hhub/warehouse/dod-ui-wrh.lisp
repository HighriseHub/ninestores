;;; dod-ui-wrh.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
;; nst-ui-warehouse.lisp
;; UI Layer for Warehouse entity with Context Flow Dispatcher (UPDATED - 41 fields with ownership)
(in-package :nstores)

;;; ===========================================================================
;;; CONTEXT FLOW DISPATCHER - OUTBOUND ROUTE REGISTRATIONS
;;; ===========================================================================

;;; ---------------------------------------------------------------------------
;;; Route 1: CREATE Warehouse
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :warehouse/create
  :crud-op :create
  :description "Creates a new warehouse record with full GST compliance and ownership model"
  :requestmodel-class 'WarehouseRequestModel
  :businessobject-class 'Warehouse
  :adapter-class 'WarehouseAdapter
  :presenter-class 'WarehousePresenter
  :view-classes '((json . WarehouseJSONView)
                  (html . WarehouseHTMLView))
  :tags '(warehouse api v1 create gst-compliant ownership-aware)
  :required-roles '(admin warehouse-manager)
  :feature-flags '(warehouse-management gst-compliance ownership-model)
  :audit-level :full
  :version 1
  :metadata '((entity . warehouse)
              (operation . create)
              (gst-enabled . t)
              (ownership-enabled . t)))

;;; ---------------------------------------------------------------------------
;;; Route 2: READ Warehouse (Single)
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :warehouse/read
  :crud-op :read
  :description "Reads a single warehouse by name with GST details and ownership information"
  :requestmodel-class 'WarehouseRequestModel
  :businessobject-class 'Warehouse
  :adapter-class 'WarehouseAdapter
  :presenter-class 'WarehousePresenter
  :view-classes '((json . WarehouseJSONView)
                  (html . WarehouseHTMLView))
  :tags '(warehouse api v1 read gst-compliant ownership-aware)
  :required-roles '(admin warehouse-manager staff)
  :feature-flags '(warehouse-management)
  :audit-level :minimal
  :version 1
  :metadata '((entity . warehouse)
              (operation . read)))

;;; ---------------------------------------------------------------------------
;;; Route 3: READ ALL Warehouses
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :warehouse/readall
  :crud-op :readall
  :description "Reads all warehouses for a company with GST and ownership information"
  :requestmodel-class 'WarehouseRequestModel
  :businessobject-class 'Warehouse
  :adapter-class 'WarehouseAdapter
  :presenter-class 'WarehousePresenter
  :view-classes '((json . WarehouseJSONView)
                  (html . WarehouseHTMLView))
  :tags '(warehouse api v1 list gst-compliant ownership-aware)
  :required-roles '(admin warehouse-manager staff)
  :feature-flags '(warehouse-management)
  :audit-level :minimal
  :version 1
  :metadata '((entity . warehouse)
              (operation . list)))

;;; ---------------------------------------------------------------------------
;;; Route 4: UPDATE Warehouse
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :warehouse/update
  :crud-op :update
  :description "Updates an existing warehouse record including GST details and ownership"
  :requestmodel-class 'WarehouseRequestModel
  :businessobject-class 'Warehouse
  :adapter-class 'WarehouseAdapter
  :presenter-class 'WarehousePresenter
  :view-classes '((json . WarehouseJSONView)
                  (html . WarehouseHTMLView))
  :tags '(warehouse api v1 update gst-compliant ownership-aware)
  :required-roles '(admin warehouse-manager)
  :feature-flags '(warehouse-management gst-compliance ownership-model)
  :audit-level :full
  :version 1
  :metadata '((entity . warehouse)
              (operation . update)
              (gst-enabled . t)
              (ownership-enabled . t)))

;;; ---------------------------------------------------------------------------
;;; Route 5: DELETE Warehouse
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :warehouse/delete
  :crud-op :delete
  :description "Soft deletes a warehouse record"
  :requestmodel-class 'WarehouseRequestModel
  :businessobject-class 'Warehouse
  :adapter-class 'WarehouseAdapter
  :presenter-class 'WarehousePresenter
  :view-classes '((json . WarehouseJSONView)
                  (html . WarehouseHTMLView))
  :tags '(warehouse api v1 delete)
  :required-roles '(admin)
  :feature-flags '(warehouse-management)
  :audit-level :full
  :version 1
  :metadata '((entity . warehouse)
              (operation . delete)))

;;; ===========================================================================
;;; CONTEXT FLOW DISPATCHER - ACTION HANDLERS (with ownership fields)
;;; ===========================================================================

;;; ---------------------------------------------------------------------------
;;; CREATE Action Handler
;;; ---------------------------------------------------------------------------
(defun com-hhub-transaction-create-warehouse-action ()
  "Handler for creating a new warehouse using context flow dispatcher with ownership"
  (with-opr-session-check
    (let* ((wname (hunchentoot:parameter "wname"))
           (waddr1 (hunchentoot:parameter "waddr1"))
           (waddr2 (hunchentoot:parameter "waddr2"))
           (wpin (hunchentoot:parameter "wpin"))
           (wcity (hunchentoot:parameter "wcity"))
           (wstate (hunchentoot:parameter "wstate"))
           (wcountry (hunchentoot:parameter "wcountry"))
           (wmanager (hunchentoot:parameter "wmanager"))
           (wphone (hunchentoot:parameter "wphone"))
           (waltphone (hunchentoot:parameter "waltphone"))
           (wemail (hunchentoot:parameter "wemail"))
           (activeflag (hunchentoot:parameter "activeflag"))
           
           ;; Ownership fields (NEW)
           (ownership-type (hunchentoot:parameter "ownershiptype"))
           (owner-entity-type (hunchentoot:parameter "ownerentitytype"))
           (owner-entity-id (parse-integer (or (hunchentoot:parameter "ownerentityid") "0")))
           (operator-entity-type (hunchentoot:parameter "operatorentitytype"))
           (operator-entity-id (when (hunchentoot:parameter "operatorentityid")
                                 (parse-integer (hunchentoot:parameter "operatorentityid"))))
           (legal-entity-type (hunchentoot:parameter "legalentitytype"))
           
           ;; GST and Advanced Fields
           (warehouse-gstin (hunchentoot:parameter "warehousegstin"))
           (gstin-status (hunchentoot:parameter "gstinstatus"))
           (legal-name (hunchentoot:parameter "legalname"))
           (is-primary-location (parse-integer (or (hunchentoot:parameter "isprimarylocation") "0")))
           (state-code (hunchentoot:parameter "statecode"))
           (registration-type (hunchentoot:parameter "registrationtype"))
           (warehouse-type (hunchentoot:parameter "warehousetype"))
           (warehouse-purpose (hunchentoot:parameter "warehousepurpose"))
           (default-transporter-id (hunchentoot:parameter "defaulttransporterid"))
           (default-transporter-name (hunchentoot:parameter "defaulttransportername"))
           (eway-bill-enabled (parse-integer (or (hunchentoot:parameter "ewaybillenabled") "1")))
           (latitude (float (with-input-from-string (in (or (hunchentoot:parameter "latitude") "0.0"))
                              (read in))))
           (longitude (float (with-input-from-string (in (or (hunchentoot:parameter "longitude") "0.0"))
                               (read in))))
           (valuation-method (hunchentoot:parameter "valuationmethod"))
           (hsn-wise-stock (parse-integer (or (hunchentoot:parameter "hsnwisestock") "0")))
           (pan-number (hunchentoot:parameter "pannumber"))
           (company (get-login-company))
           (vendor (get-login-vendor))
           (raw-params (list :wname wname
                            :waddr1 waddr1
                            :waddr2 waddr2
                            :wpin wpin
                            :wcity wcity
                            :wstate wstate
                            :wcountry wcountry
                            :wmanager wmanager
                            :wphone wphone
                            :waltphone waltphone
                            :wemail wemail
                            :activeflag activeflag
                            ;; Ownership fields
                            :ownership-type ownership-type
                            :owner-entity-type owner-entity-type
                            :owner-entity-id owner-entity-id
                            :operator-entity-type operator-entity-type
                            :operator-entity-id operator-entity-id
                            :legal-entity-type legal-entity-type
                            ;; GST fields
                            :warehouse-gstin warehouse-gstin
                            :gstin-status gstin-status
                            :legal-name legal-name
                            :is-primary-location is-primary-location
                            :state-code state-code
                            :registration-type registration-type
                            :warehouse-type warehouse-type
                            :warehouse-purpose warehouse-purpose
                            :default-transporter-id default-transporter-id
                            :default-transporter-name default-transporter-name
                            :eway-bill-enabled eway-bill-enabled
                            :latitude latitude
                            :longitude longitude
                            :valuation-method valuation-method
                            :hsn-wise-stock hsn-wise-stock
                            :pan-number pan-number
                            :company company
                            :vendor vendor)))
      (dispatch-route :warehouse/create 
                      raw-params
                      :trans-func-name "com-hhub-transaction-create-warehouse-action"
                      :output-type 'json))))

;;; ---------------------------------------------------------------------------
;;; READ Action Handler
;;; ---------------------------------------------------------------------------
(defun com-hhub-transaction-read-warehouse-action ()
  "Handler for reading a single warehouse using context flow dispatcher"
  (with-opr-session-check
    (let* ((wname (hunchentoot:parameter "wname"))
           (company (get-login-company))
           (raw-params (list :wname wname
                            :company company)))
      (dispatch-route :warehouse/read 
                      raw-params
                      :trans-func-name "com-hhub-transaction-read-warehouse-action"
                      :output-type 'json))))

;;; ---------------------------------------------------------------------------
;;; READ ALL Action Handler
;;; ---------------------------------------------------------------------------
(defun com-hhub-transaction-readall-warehouse-action ()
  "Handler for reading all warehouses using context flow dispatcher"
  (with-opr-session-check
    (let* ((company (get-login-company))
           (vendor (get-login-vendor))
           (raw-params (list :company company
                            :vendor vendor)))
      (dispatch-route :warehouse/readall 
                      raw-params
                      :trans-func-name "com-hhub-transaction-readall-warehouse-action"
                      :output-type 'json))))

;;; ---------------------------------------------------------------------------
;;; UPDATE Action Handler
;;; ---------------------------------------------------------------------------
(defun com-hhub-transaction-update-warehouse-action ()
  "Handler for updating a warehouse using context flow dispatcher with ownership"
  (with-opr-session-check
    (let* ((wname (hunchentoot:parameter "wname"))
           (waddr1 (hunchentoot:parameter "waddr1"))
           (waddr2 (hunchentoot:parameter "waddr2"))
           (wpin (hunchentoot:parameter "wpin"))
           (wcity (hunchentoot:parameter "wcity"))
           (wstate (hunchentoot:parameter "wstate"))
           (wcountry (hunchentoot:parameter "wcountry"))
           (wmanager (hunchentoot:parameter "wmanager"))
           (wphone (hunchentoot:parameter "wphone"))
           (waltphone (hunchentoot:parameter "waltphone"))
           (wemail (hunchentoot:parameter "wemail"))
           (activeflag (hunchentoot:parameter "activeflag"))
           
           ;; Ownership fields (NEW)
           (ownership-type (hunchentoot:parameter "ownershiptype"))
           (owner-entity-type (hunchentoot:parameter "ownerentitytype"))
           (owner-entity-id (parse-integer (or (hunchentoot:parameter "ownerentityid") "0")))
           (operator-entity-type (hunchentoot:parameter "operatorentitytype"))
           (operator-entity-id (when (hunchentoot:parameter "operatorentityid")
                                 (parse-integer (hunchentoot:parameter "operatorentityid"))))
           (legal-entity-type (hunchentoot:parameter "legalentitytype"))
           
           ;; GST and Advanced Fields
           (warehouse-gstin (hunchentoot:parameter "warehousegstin"))
           (gstin-status (hunchentoot:parameter "gstinstatus"))
           (legal-name (hunchentoot:parameter "legalname"))
           (is-primary-location (parse-integer (or (hunchentoot:parameter "isprimarylocation") "0")))
           (state-code (hunchentoot:parameter "statecode"))
           (registration-type (hunchentoot:parameter "registrationtype"))
           (warehouse-type (hunchentoot:parameter "warehousetype"))
           (warehouse-purpose (hunchentoot:parameter "warehousepurpose"))
           (default-transporter-id (hunchentoot:parameter "defaulttransporterid"))
           (default-transporter-name (hunchentoot:parameter "defaulttransportername"))
           (eway-bill-enabled (parse-integer (or (hunchentoot:parameter "ewaybillenabled") "1")))
           (latitude (float (with-input-from-string (in (or (hunchentoot:parameter "latitude") "0.0"))
                              (read in))))
           (longitude (float (with-input-from-string (in (or (hunchentoot:parameter "longitude") "0.0"))
                               (read in))))
           (valuation-method (hunchentoot:parameter "valuationmethod"))
           (hsn-wise-stock (parse-integer (or (hunchentoot:parameter "hsnwisestock") "0")))
           (pan-number (hunchentoot:parameter "pannumber"))
           (company (get-login-company))
           (vendor (get-login-vendor))
           (raw-params (list :wname wname
                            :waddr1 waddr1
                            :waddr2 waddr2
                            :wpin wpin
                            :wcity wcity
                            :wstate wstate
                            :wcountry wcountry
                            :wmanager wmanager
                            :wphone wphone
                            :waltphone waltphone
                            :wemail wemail
                            :activeflag activeflag
                            ;; Ownership fields
                            :ownership-type ownership-type
                            :owner-entity-type owner-entity-type
                            :owner-entity-id owner-entity-id
                            :operator-entity-type operator-entity-type
                            :operator-entity-id operator-entity-id
                            :legal-entity-type legal-entity-type
                            ;; GST fields
                            :warehouse-gstin warehouse-gstin
                            :gstin-status gstin-status
                            :legal-name legal-name
                            :is-primary-location is-primary-location
                            :state-code state-code
                            :registration-type registration-type
                            :warehouse-type warehouse-type
                            :warehouse-purpose warehouse-purpose
                            :default-transporter-id default-transporter-id
                            :default-transporter-name default-transporter-name
                            :eway-bill-enabled eway-bill-enabled
                            :latitude latitude
                            :longitude longitude
                            :valuation-method valuation-method
                            :hsn-wise-stock hsn-wise-stock
                            :pan-number pan-number
                            :company company
                            :vendor vendor)))
      (dispatch-route :warehouse/update 
                      raw-params
                      :trans-func-name "com-hhub-transaction-update-warehouse-action"
                      :output-type 'json))))

;;; ---------------------------------------------------------------------------
;;; DELETE Action Handler
;;; ---------------------------------------------------------------------------
(defun com-hhub-transaction-delete-warehouse-action ()
  "Handler for deleting a warehouse using context flow dispatcher"
  (with-opr-session-check
    (let* ((wname (hunchentoot:parameter "wname"))
           (company (get-login-company))
           (raw-params (list :wname wname
                            :company company)))
      (dispatch-route :warehouse/delete 
                      raw-params
                      :trans-func-name "com-hhub-transaction-delete-warehouse-action"
                      :output-type 'json))))

;;; ===========================================================================
;;; TRADITIONAL UI FUNCTIONS (Legacy Support)
;;; ===========================================================================

;;; ---------------------------------------------------------------------------
;;; HTML Search Interface
;;; ---------------------------------------------------------------------------
(defun warehouse-search-html ()
  "Generate warehouse search HTML"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
          (:div :id "custom-search-input"
                (:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
                      (with-html-search-form "idsyssearchwarehouses" "syssearchwarehouses" 
                                            "idwarehouselivesearch" "warehouselivesearch" 
                                            "searchwarehouseaction" "onkeyupsearchform1event();" 
                                            "Enter Warehouse GSTINSearch for a warehouse"
                        (submitsearchform1event-js "#idwarehouselivesearch" 
                                                  "#warehouselivesearchresult")))))))

;;; ---------------------------------------------------------------------------
;;; Main Warehouse Page
;;; ---------------------------------------------------------------------------






;;; ---------------------------------------------------------------------------
;;; Search Functionality
;;; ---------------------------------------------------------------------------


;;; ---------------------------------------------------------------------------
;;; Warehouse Dialog (with all 41 fields organized in 5 tabs including Ownership)
;;; ---------------------------------------------------------------------------
(defun com-nst-transaction-vendor-warehouse-details-page ()
  (with-vend-session-check
    (with-mvc-ui-page "Create New Warehouse"
                      #'create-model-for-addeditwarehouse
                      #'create-widgets-for-addeditwarehouse
      :role :vendor)))

(defparameter *warehouse-field-map*
  '((warehouse-uuid           . "%Warehouse UUID%")
    (warehouse-code           . "%Warehouse Code%")
    (wname                    . "%Warehouse Name%")
    (waddr1                   . "%Warehouse Address1%")
    (waddr2                   . "%Warehouse Address2%")
    (wpin                     . "%Warehouse Pincode%")
    (wcity                    . "%Warehouse City%")
    (wstate                   . "%Warehouse State%")
    (wcountry                 . "%Warehouse Country%")
    (wmanager                 . "%Warehouse Manager%")
    (wphone                   . "%Warehouse Phone%")
    (waltphone                . "%Warehouse Alt Phone%")
    (wemail                   . "%Warehouse Email%")
    (activeflag               . "%Warehouse Active Flag%")
    (ownership-type           . "%Warehouse Ownership Type%")
    (owner-entity-type        . "%Warehouse Owner Entity Type%")
    (owner-entity-id          . "%Warehouse Owner Entity ID%")
    (operator-entity-type     . "%Warehouse Operator Entity Type%")
    (operator-entity-id       . "%Warehouse Operator Entity ID%")
    (legal-entity-type        . "%Warehouse Legal Entity Type%")
    (warehouse-gstin          . "%Warehouse GSTIN%")
    (gstin-status             . "%Warehouse GSTIN Status%")
    (legal-name               . "%Warehouse Legal Name%")
    (is-primary-location      . "%Warehouse Is Primary Location%")
    (state-code               . "%Warehouse State Code%")
    (registration-type        . "%Warehouse Registration Type%")
    (pan-number               . "%Warehouse PAN Number%")
    (warehouse-type           . "%Warehouse Type%")
    (warehouse-purpose        . "%Warehouse Purpose%")
    (default-transporter-id   . "%Warehouse Default Transporter ID%")
    (default-transporter-name . "%Warehouse Default Transporter Name%")
    (eway-bill-enabled        . "%Warehouse EWay Bill Enabled%")
    (latitude                 . "%Warehouse Latitude%")
    (longitude                . "%Warehouse Longitude%")
    (valuation-method         . "%Warehouse Valuation Method%")
    (hsn-wise-stock           . "%Warehouse HSN Wise Stock%")))


(defun create-model-for-addeditwarehouse ()
  (let* ((id (hunchentoot:parameter "id"))
	 (vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (ctx (make-domain-ctx :actor "VENDOR" :tenant company :channel "ONLINE" :recipient vendor :source "VENDOR"))
	 (warehouseobj (if id (fetch 'nst-whs id ctx)))
	 (warehousedetailspagetempl (funcall (nst-get-cached-warehouse-template-func :templatenum 1))))
    ;; For create/edit handling:
    (dolist (pair *warehouse-field-map*)
      (let* ((slot (car pair))
             (placeholder (cdr pair))
             (value (and warehouseobj (slot-value warehouseobj slot))))
	(setf warehousedetailspagetempl 
              (cl-ppcre:regex-replace-all 
               placeholder 
               warehousedetailspagetempl 
               (if value (princ-to-string value) "")))))
    
    (function (lambda ()
      (values  warehousedetailspagetempl)))))

(defun create-widgets-for-addeditwarehouse (modelfunc)
  (multiple-value-bind ( warehousedetailspagetempl) (funcall modelfunc)
    (let ((widget1  (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(cl-who:str warehousedetailspagetempl))))))
    (list widget1))))


;;; ---------------------------------------------------------------------------
;;; JSON Rendering for Warehouse (with all 41 fields including ownership)
;;; ---------------------------------------------------------------------------

(defmethod Render ((view WarehouseJSONView) (viewmodel WarehouseViewModel))
  :description "Render warehouse view model as JSON with ownership fields"
  (let* ((templist '())
         (appendlist '())
         (mylist '())
         ;; Extract all warehouse fields
         (row-id (slot-value viewmodel 'row-id))
         (warehouse-uuid (slot-value viewmodel 'warehouse-uuid))
         (warehouse-code (slot-value viewmodel 'warehouse-code))
         (wname (slot-value viewmodel 'wname))
         (waddr1 (slot-value viewmodel 'waddr1))
         (waddr2 (slot-value viewmodel 'waddr2))
         (wpin (slot-value viewmodel 'wpin))
         (wcity (slot-value viewmodel 'wcity))
         (wstate (slot-value viewmodel 'wstate))
         (wcountry (slot-value viewmodel 'wcountry))
         (wmanager (slot-value viewmodel 'wmanager))
         (wphone (slot-value viewmodel 'wphone))
         (waltphone (slot-value viewmodel 'waltphone))
         (wemail (slot-value viewmodel 'wemail))
         (activeflag (slot-value viewmodel 'activeflag))
         
         ;; Ownership fields (NEW)
         (ownership-type (slot-value viewmodel 'ownership-type))
         (owner-entity-type (slot-value viewmodel 'owner-entity-type))
         (owner-entity-id (slot-value viewmodel 'owner-entity-id))
         (operator-entity-type (slot-value viewmodel 'operator-entity-type))
         (operator-entity-id (slot-value viewmodel 'operator-entity-id))
         (legal-entity-type (slot-value viewmodel 'legal-entity-type))
         
         ;; GST and Advanced Fields
         (warehouse-gstin (slot-value viewmodel 'warehouse-gstin))
         (gstin-status (slot-value viewmodel 'gstin-status))
         (legal-name (slot-value viewmodel 'legal-name))
         (is-primary-location (slot-value viewmodel 'is-primary-location))
         (state-code (slot-value viewmodel 'state-code))
         (registration-type (slot-value viewmodel 'registration-type))
         (warehouse-type (slot-value viewmodel 'warehouse-type))
         (warehouse-purpose (slot-value viewmodel 'warehouse-purpose))
         (default-transporter-id (slot-value viewmodel 'default-transporter-id))
         (default-transporter-name (slot-value viewmodel 'default-transporter-name))
         (eway-bill-enabled (slot-value viewmodel 'eway-bill-enabled))
         (latitude (slot-value viewmodel 'latitude))
         (longitude (slot-value viewmodel 'longitude))
         (valuation-method (slot-value viewmodel 'valuation-method))
         (hsn-wise-stock (slot-value viewmodel 'hsn-wise-stock))
         (pan-number (slot-value viewmodel 'pan-number)))
    
    ;; If minimum required fields exist
    (if (and warehouse-code wname)
        (progn
          ;; Build warehouse data structure with ALL 41 fields
          ;; Identifiers
          (setf templist (acons "rowId" row-id templist))
          (setf templist (acons "warehouseUuid" 
                                (format nil "~A" (or warehouse-uuid "")) 
                                templist))
          (setf templist (acons "warehouseCode" 
                                (format nil "~A" (or warehouse-code "")) 
                                templist))
          
          ;; Basic Info
          (setf templist (acons "name" (format nil "~A" (or wname "")) templist))
          (setf templist (acons "address1" (format nil "~A" (or waddr1 "")) templist))
          (setf templist (acons "address2" (format nil "~A" (or waddr2 "")) templist))
          (setf templist (acons "pin" (format nil "~A" (or wpin "")) templist))
          (setf templist (acons "city" (format nil "~A" (or wcity "")) templist))
          (setf templist (acons "state" (format nil "~A" (or wstate "")) templist))
          (setf templist (acons "country" (format nil "~A" (or wcountry "")) templist))
          
          ;; Contact Info
          (setf templist (acons "manager" (format nil "~A" (or wmanager "")) templist))
          (setf templist (acons "phone" (format nil "~A" (or wphone "")) templist))
          (setf templist (acons "altPhone" (format nil "~A" (or waltphone "")) templist))
          (setf templist (acons "email" (format nil "~A" (or wemail "")) templist))
          (setf templist (acons "activeFlag" (format nil "~A" (or activeflag "")) templist))
          
          ;; Ownership fields (NEW)
          (setf templist (acons "ownershipType" 
                                (format nil "~A" (or ownership-type "SELLER_OWNED")) 
                                templist))
          (setf templist (acons "ownerEntityType" 
                                (format nil "~A" (or owner-entity-type "SELLER")) 
                                templist))
          (setf templist (acons "ownerEntityId" 
                                (or owner-entity-id 0) 
                                templist))
          (setf templist (acons "operatorEntityType" 
                                (format nil "~A" (or operator-entity-type "")) 
                                templist))
          (setf templist (acons "operatorEntityId" 
                                (or operator-entity-id 0) 
                                templist))
          (setf templist (acons "legalEntityType" 
                                (format nil "~A" (or legal-entity-type "SELLER")) 
                                templist))
          
          ;; GST Details
          (setf templist (acons "warehouseGstin" 
                                (format nil "~A" (or warehouse-gstin "")) 
                                templist))
          (setf templist (acons "gstinStatus" 
                                (format nil "~A" (or gstin-status "")) 
                                templist))
          (setf templist (acons "legalName" 
                                (format nil "~A" (or legal-name "")) 
                                templist))
          (setf templist (acons "isPrimaryLocation" 
                                (if (and is-primary-location (= is-primary-location 1)) 
                                    1 
                                    0) 
                                templist))
          (setf templist (acons "stateCode" 
                                (format nil "~A" (or state-code "")) 
                                templist))
          (setf templist (acons "registrationType" 
                                (format nil "~A" (or registration-type "")) 
                                templist))
          (setf templist (acons "panNumber" 
                                (format nil "~A" (or pan-number "")) 
                                templist))
          
          ;; Logistics Info
          (setf templist (acons "warehouseType" 
                                (format nil "~A" (or warehouse-type "")) 
                                templist))
          (setf templist (acons "warehousePurpose" 
                                (format nil "~A" (or warehouse-purpose "")) 
                                templist))
          (setf templist (acons "defaultTransporterId" 
                                (format nil "~A" (or default-transporter-id "")) 
                                templist))
          (setf templist (acons "defaultTransporterName" 
                                (format nil "~A" (or default-transporter-name "")) 
                                templist))
          (setf templist (acons "ewayBillEnabled" 
                                (if (and eway-bill-enabled (= eway-bill-enabled 1)) 
                                    1 
                                    0) 
                                templist))
          (setf templist (acons "valuationMethod" 
                                (format nil "~A" (or valuation-method "")) 
                                templist))
          (setf templist (acons "hsnWiseStock" 
                                (if (and hsn-wise-stock (= hsn-wise-stock 1)) 
                                    1 
                                    0) 
                                templist))
          
          ;; Location Coordinates
          (setf templist (acons "latitude" 
                                (if latitude latitude 0.0) 
                                templist))
          (setf templist (acons "longitude" 
                                (if longitude longitude 0.0) 
                                templist))
          
          ;; Build response structure
          (push templist appendlist)
          
          ;; API format
          (setf mylist (acons "warehouses" appendlist mylist))
          (setf mylist (acons "success" 1 mylist)))
        
        ;; Else: failure response
        (progn
          (setf mylist (acons "warehouses" '() mylist))
          (setf mylist (acons "success" 0 mylist))
          (setf mylist (acons "error" "Missing required warehouse fields" mylist))))
    
    ;; Encode JSON
    (let ((jsondata (json:encode-json-to-string mylist)))
      (setf (slot-value view 'jsondata) jsondata)
      jsondata)))


;;; ---------------------------------------------------------------------------
;;; Render method for list of warehouses (with ownership fields)
;;; ---------------------------------------------------------------------------

(defmethod RenderList ((view WarehouseJSONView) (viewmodellist list))
  :description "Render list of warehouse view models as JSON with ownership"
  (let ((appendlist '())
        (mylist '()))
    
    ;; Process each warehouse
    (dolist (viewmodel viewmodellist)
      (let ((templist '())
            ;; Extract fields (compact for list view)
            (row-id (slot-value viewmodel 'row-id))
            (warehouse-uuid (slot-value viewmodel 'warehouse-uuid))
            (warehouse-code (slot-value viewmodel 'warehouse-code))
            (wname (slot-value viewmodel 'wname))
            (wcity (slot-value viewmodel 'wcity))
            (wstate (slot-value viewmodel 'wstate))
            (wphone (slot-value viewmodel 'wphone))
            ;; Ownership fields
            (ownership-type (slot-value viewmodel 'ownership-type))
            (owner-entity-type (slot-value viewmodel 'owner-entity-type))
            (owner-entity-id (slot-value viewmodel 'owner-entity-id))
            ;; GST fields
            (warehouse-gstin (slot-value viewmodel 'warehouse-gstin))
            (warehouse-type (slot-value viewmodel 'warehouse-type))
            (is-primary-location (slot-value viewmodel 'is-primary-location))
            (activeflag (slot-value viewmodel 'activeflag)))
        
        ;; Build compact warehouse object
        (setf templist (acons "rowId" row-id templist))
        (setf templist (acons "warehouseUuid" 
                              (format nil "~A" (or warehouse-uuid "")) 
                              templist))
        (setf templist (acons "warehouseCode" 
                              (format nil "~A" (or warehouse-code "")) 
                              templist))
        (setf templist (acons "name" (format nil "~A" (or wname "")) templist))
        (setf templist (acons "city" (format nil "~A" (or wcity "")) templist))
        (setf templist (acons "state" (format nil "~A" (or wstate "")) templist))
        (setf templist (acons "phone" (format nil "~A" (or wphone "")) templist))
        
        ;; Ownership info (NEW)
        (setf templist (acons "ownershipType" 
                              (format nil "~A" (or ownership-type "SELLER_OWNED")) 
                              templist))
        (setf templist (acons "ownerEntityType" 
                              (format nil "~A" (or owner-entity-type "SELLER")) 
                              templist))
        (setf templist (acons "ownerEntityId" 
                              (or owner-entity-id 0) 
                              templist))
        
        ;; GST info
        (setf templist (acons "warehouseGstin" 
                              (format nil "~A" (or warehouse-gstin "")) 
                              templist))
        (setf templist (acons "warehouseType" 
                              (format nil "~A" (or warehouse-type "")) 
                              templist))
        (setf templist (acons "isPrimaryLocation" 
                              (if (and is-primary-location (= is-primary-location 1)) 
                                  1 
                                  0) 
                              templist))
        (setf templist (acons "activeFlag" 
                              (format nil "~A" (or activeflag "")) 
                              templist))
        
        ;; Add to list
        (push templist appendlist)))
    
    ;; Reverse to maintain order
    (setf appendlist (reverse appendlist))
    
    ;; Build response
    (setf mylist (acons "warehouses" appendlist mylist))
    (setf mylist (acons "count" (length viewmodellist) mylist))
    (setf mylist (acons "success" 1 mylist))
    
    ;; Encode JSON
    (let ((jsondata (json:encode-json-to-string mylist)))
      (setf (slot-value view 'jsondata) jsondata)
      jsondata)))

;;; End of nst-ui-warehouse.lisp


