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

