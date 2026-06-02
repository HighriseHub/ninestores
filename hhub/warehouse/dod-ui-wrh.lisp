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
                                            "Search for a warehouse"
                        (submitsearchform1event-js "#idwarehouselivesearch" 
                                                  "#warehouselivesearchresult")))))))

;;; ---------------------------------------------------------------------------
;;; Main Warehouse Page
;;; ---------------------------------------------------------------------------
(defun com-hhub-transaction-warehouse-page ()
  "Main warehouse management page"
  (with-opr-session-check
    (with-mvc-ui-page "Warehouse Management" 
                      #'create-model-for-showwarehouses 
                      #'create-widgets-for-showwarehouses 
                      :role :admin)))

(defun create-model-for-showwarehouses ()
  "Create model for showing all warehouses"
  (let* ((company (get-login-company))
         (username (get-login-user-name))
         (vendor (get-login-vendor))
         (warehousepresenter (make-instance 'WarehousePresenter))
         (warehouserequestmodel (make-instance 'WarehouseRequestModel
                                              :company company
                                              :vendor vendor))
         (warehouseadapter (make-instance 'WarehouseAdapter))
         (warehouseobjlst (processreadallrequest warehouseadapter warehouserequestmodel))
         (warehouseresponsemodellist (processresponselist warehouseadapter warehouseobjlst))
         (viewallmodel (CreateAllViewModel warehousepresenter warehouseresponsemodellist))
         (htmlview (make-instance 'WarehouseHTMLView))
         (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (with-hhub-transaction "com-hhub-transaction-warehouse-page" params 
      (function (lambda ()
        (values viewallmodel htmlview username))))))

(defun create-widgets-for-showwarehouses (modelfunc)
  "Create widgets for warehouse page"
  (multiple-value-bind (viewallmodel htmlview username) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
                     (cl-who:with-html-output (*standard-output* nil)
                       (:div :id "row"
                             (:div :id "col-xs-6" 
                                   (:h3 "Welcome " (cl-who:str (format nil "~A" username)))))
                       (warehouse-search-html)
                       (:hr)))))
          (widget2 (function (lambda ()
                     (cl-who:with-html-output (*standard-output* nil) 
                       (with-html-div-row
                         (:h4 "Showing warehouses"))
                       (:div :id "warehouselivesearchresult" 
                             (:div :class "row"
                                   (:div :class "col-xs-6"
                                         (:button :type "button" :class "btn btn-primary" 
                                                 :data-toggle "modal" 
                                                 :data-target "#editwarehouse-modal" 
                                                 "Add Warehouse")
                                         (modal-dialog "editwarehouse-modal" 
                                                      "Add/Edit Warehouse" 
                                                      (com-hhub-transaction-create-warehouse-dialog)))
                                   (:div :class "col-xs-6" :align "right" 
                                         (:span :class "badge" 
                                               (cl-who:str (format nil "~A" (length viewallmodel))))))
                             (:hr)
                             (cl-who:str (RenderListViewHTML htmlview viewallmodel))))))))
      (list widget1 widget2))))

;;; ---------------------------------------------------------------------------
;;; Search Functionality
;;; ---------------------------------------------------------------------------
(defun create-model-for-searchwarehouses ()
  "Create model for searching warehouses"
  (let* ((search-clause (hunchentoot:parameter "warehouselivesearch"))
         (company (get-login-company))
         (warehousepresenter (make-instance 'WarehousePresenter))
         (warehouserequestmodel (make-instance 'WarehouseSearchRequestModel
                                              :wname search-clause
                                              :company company))
         (warehouseadapter (make-instance 'WarehouseAdapter))
         (warehouseobjlst (processreadallrequest warehouseadapter warehouserequestmodel))
         (warehouseresponsemodellist (processresponselist warehouseadapter warehouseobjlst))
         (viewallmodel (CreateAllViewModel warehousepresenter warehouseresponsemodellist))
         (htmlview (make-instance 'WarehouseHTMLView))
         (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (with-hhub-transaction "com-hhub-transaction-search-warehouse-action" params 
      (function (lambda ()
        (values viewallmodel htmlview))))))

(defun create-widgets-for-searchwarehouses (modelfunc)
  "Create widgets for search results"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
                     (cl-who:with-html-output (*standard-output* nil) 
                       (:div :class "row"
                             (:div :class "col-xs-6"
                                   (:button :type "button" :class "btn btn-primary" 
                                           :data-toggle "modal" 
                                           :data-target "#editwarehouse-modal" 
                                           "Add Warehouse")
                                   (modal-dialog "editwarehouse-modal" 
                                                "Add/Edit Warehouse" 
                                                (com-hhub-transaction-create-warehouse-dialog)))
                             (:div :class "col-xs-6" :align "right" 
                                   (:span :class "badge" 
                                         (cl-who:str (format nil "~A" (length viewallmodel))))))
                       (:hr)
                       (RenderListViewHTML htmlview viewallmodel))))))
      (list widget1))))

(defun com-hhub-transaction-search-warehouse-action ()
  "Search warehouse action handler"
  (let* ((modelfunc (funcall #'create-model-for-searchwarehouses))
         (widgets (funcall #'create-widgets-for-searchwarehouses modelfunc)))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (loop for widget in widgets do
        (cl-who:str (funcall widget))))))

;;; ---------------------------------------------------------------------------
;;; HTML Rendering
;;; ---------------------------------------------------------------------------
(defmethod RenderListViewHTML ((htmlview WarehouseHTMLView) viewmodellist)
  "Render warehouse list as HTML table with ownership info"
  (when viewmodellist
    (display-as-table (list "Name" "GSTIN" "City" "State" "Type" "Ownership" 
                           "Manager" "Phone" "Active" "Actions") 
                     viewmodellist 
                     'display-warehouse-row)))

(defun display-warehouse-row (warehouse &rest arguments)
  "Display a single warehouse row with ownership information"
  (declare (ignore arguments))
  (with-slots (wname warehouse-gstin wcity wstate warehouse-type 
               ownership-type owner-entity-type
               wmanager wphone activeflag) warehouse 
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" (cl-who:str wname))
      (:td :height "10px" (cl-who:str (or warehouse-gstin "N/A")))
      (:td :height "10px" (cl-who:str wcity))
      (:td :height "10px" (cl-who:str wstate))
      (:td :height "10px" (cl-who:str (or warehouse-type "OWN")))
      (:td :height "10px" (cl-who:str (format nil "~A (~A)" 
                                             (or ownership-type "SELLER_OWNED")
                                             (or owner-entity-type "SELLER"))))
      (:td :height "10px" (cl-who:str wmanager))
      (:td :height "10px" (cl-who:str wphone))
      (:td :height "10px" (cl-who:str activeflag))
      (:td :height "10px" 
           (:button :type "button" :class "btn btn-primary btn-sm" 
                   :data-toggle "modal" 
                   :data-target (format nil "#editwarehouse-modal~A" wname) 
                   (:i :class "fa-solid fa-pencil"))
           (modal-dialog (format nil "editwarehouse-modal~A" wname) 
                        "Edit Warehouse" 
                        (com-hhub-transaction-create-warehouse-dialog warehouse))))))

;;; ---------------------------------------------------------------------------
;;; Warehouse Dialog (with all 41 fields organized in 5 tabs including Ownership)
;;; ---------------------------------------------------------------------------
(defun com-hhub-transaction-create-warehouse-dialog (&optional warehouseobj)
  "Create/Edit warehouse dialog with tabbed interface for all 41 fields"
  (let* ((wname (if warehouseobj (slot-value warehouseobj 'wname)))
         (waddr1 (if warehouseobj (slot-value warehouseobj 'waddr1)))
         (waddr2 (if warehouseobj (slot-value warehouseobj 'waddr2)))
         (wpin (if warehouseobj (slot-value warehouseobj 'wpin)))
         (wcity (if warehouseobj (slot-value warehouseobj 'wcity)))
         (wstate (if warehouseobj (slot-value warehouseobj 'wstate)))
         (wcountry (if warehouseobj (slot-value warehouseobj 'wcountry)))
         (wmanager (if warehouseobj (slot-value warehouseobj 'wmanager)))
         (wphone (if warehouseobj (slot-value warehouseobj 'wphone)))
         (waltphone (if warehouseobj (slot-value warehouseobj 'waltphone)))
         (wemail (if warehouseobj (slot-value warehouseobj 'wemail)))
         (activeflag (if warehouseobj (slot-value warehouseobj 'activeflag)))
         
         ;; Ownership fields (NEW)
         (ownership-type (if warehouseobj (slot-value warehouseobj 'ownership-type)))
         (owner-entity-type (if warehouseobj (slot-value warehouseobj 'owner-entity-type)))
         (owner-entity-id (if warehouseobj (slot-value warehouseobj 'owner-entity-id)))
         (operator-entity-type (if warehouseobj (slot-value warehouseobj 'operator-entity-type)))
         (operator-entity-id (if warehouseobj (slot-value warehouseobj 'operator-entity-id)))
         (legal-entity-type (if warehouseobj (slot-value warehouseobj 'legal-entity-type)))
         
         ;; GST and Advanced Fields
         (warehouse-gstin (if warehouseobj (slot-value warehouseobj 'warehouse-gstin)))
         (gstin-status (if warehouseobj (slot-value warehouseobj 'gstin-status)))
         (legal-name (if warehouseobj (slot-value warehouseobj 'legal-name)))
         (is-primary-location (if warehouseobj (slot-value warehouseobj 'is-primary-location)))
         (state-code (if warehouseobj (slot-value warehouseobj 'state-code)))
         (registration-type (if warehouseobj (slot-value warehouseobj 'registration-type)))
         (warehouse-type (if warehouseobj (slot-value warehouseobj 'warehouse-type)))
         (warehouse-purpose (if warehouseobj (slot-value warehouseobj 'warehouse-purpose)))
         (default-transporter-id (if warehouseobj (slot-value warehouseobj 'default-transporter-id)))
         (default-transporter-name (if warehouseobj (slot-value warehouseobj 'default-transporter-name)))
         (eway-bill-enabled (if warehouseobj (slot-value warehouseobj 'eway-bill-enabled)))
         (latitude (if warehouseobj (slot-value warehouseobj 'latitude)))
         (longitude (if warehouseobj (slot-value warehouseobj 'longitude)))
         (valuation-method (if warehouseobj (slot-value warehouseobj 'valuation-method)))
         (hsn-wise-stock (if warehouseobj (slot-value warehouseobj 'hsn-wise-stock)))
         (pan-number (if warehouseobj (slot-value warehouseobj 'pan-number))))
    
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
            (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
                  (with-html-form (format nil "form-addwarehouse~A" wname)  
                                 (if warehouseobj "updatewarehouseaction" "createwarehouseaction")
                    (:img :class "profile-img" :src "/img/logo.png" :alt "")
                    
                    ;; TAB Navigation (5 tabs now - added Ownership)
                    (:ul :class "nav nav-tabs" :role "tablist"
                         (:li :role "presentation" :class "active"
                              (:a :href "#basic" :aria-controls "basic" :role "tab" :data-toggle "tab" "Basic Info"))
                         (:li :role "presentation"
                              (:a :href "#ownership" :aria-controls "ownership" :role "tab" :data-toggle "tab" 
                                  (:span :class "label label-primary" "NEW") " Ownership"))
                         (:li :role "presentation"
                              (:a :href "#gst" :aria-controls "gst" :role "tab" :data-toggle "tab" "GST Details"))
                         (:li :role "presentation"
                              (:a :href "#logistics" :aria-controls "logistics" :role "tab" :data-toggle "tab" "Logistics"))
                         (:li :role "presentation"
                              (:a :href "#location" :aria-controls "location" :role "tab" :data-toggle "tab" "Location")))
                    
                    ;; TAB Content
                    (:div :class "tab-content"
                          
                          ;; BASIC INFO TAB
                          (:div :role "tabpanel" :class "tab-pane active" :id "basic"
                                (:br)
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "wname" :maxlength "100" 
                                             :value wname :placeholder "Warehouse Name *" :type "text" :required "required"))
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "waddr1" :maxlength "100" 
                                             :value waddr1 :placeholder "Address Line 1" :type "text"))
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "waddr2" :maxlength "100" 
                                             :value waddr2 :placeholder "Address Line 2" :type "text"))
                                (:div :class "row"
                                      (:div :class "col-xs-6"
                                            (:div :class "form-group"
                                                  (:input :class "form-control" :name "wpin" :maxlength "6" 
                                                         :value wpin :placeholder "PIN Code" :type "text")))
                                      (:div :class "col-xs-6"
                                            (:div :class "form-group"
                                                  (:input :class "form-control" :name "wcity" :maxlength "30" 
                                                         :value wcity :placeholder "City" :type "text"))))
                                (:div :class "row"
                                      (:div :class "col-xs-6"
                                            (:div :class "form-group"
                                                  (:input :class "form-control" :name "wstate" :maxlength "30" 
                                                         :value wstate :placeholder "State" :type "text")))
                                      (:div :class "col-xs-6"
                                            (:div :class "form-group"
                                                  (:input :class "form-control" :name "wcountry" :maxlength "30" 
                                                         :value wcountry :placeholder "Country" :type "text"))))
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "wmanager" :maxlength "100" 
                                             :value wmanager :placeholder "Manager Name" :type "text"))
                                (:div :class "row"
                                      (:div :class "col-xs-6"
                                            (:div :class "form-group"
                                                  (:input :class "form-control" :name "wphone" :maxlength "16" 
                                                         :value wphone :placeholder "Phone" :type "text")))
                                      (:div :class "col-xs-6"
                                            (:div :class "form-group"
                                                  (:input :class "form-control" :name "waltphone" :maxlength "16" 
                                                         :value waltphone :placeholder "Alternate Phone" :type "text"))))
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "wemail" :maxlength "100" 
                                             :value wemail :placeholder "Email" :type "email"))
                                (:div :class "form-group"
                                      (:label "Active: ")
                                      (:input :type "radio" :name "activeflag" :value "Y" 
                                             :checked (equal activeflag "Y")) " Yes "
                                      (:input :type "radio" :name "activeflag" :value "N" 
                                             :checked (equal activeflag "N")) " No"))
                          
                          ;; OWNERSHIP TAB (NEW)
                          (:div :role "tabpanel" :class "tab-pane" :id "ownership"
                                (:br)
                                (:div :class "alert alert-info" :role "alert"
                                      (:i :class "fa fa-info-circle") " Define who owns, operates, and is legally registered for this warehouse.")
                                
                                (:div :class "form-group"
                                      (:label "Ownership Type *")
                                      (:select :class "form-control" :name "ownershiptype" :required "required"
                                               (:option :value "SELLER_OWNED" :selected (equal ownership-type "SELLER_OWNED") "Seller Owned")
                                               (:option :value "BUYER_OWNED" :selected (equal ownership-type "BUYER_OWNED") "Buyer Owned (VMI)")
                                               (:option :value "THIRD_PARTY" :selected (equal ownership-type "THIRD_PARTY") "Third Party (3PL)")
                                               (:option :value "PLATFORM_OWNED" :selected (equal ownership-type "PLATFORM_OWNED") "Platform Owned")
                                               (:option :value "BONDED" :selected (equal ownership-type "BONDED") "Bonded Warehouse")
                                               (:option :value "CONTRACT_MFG" :selected (equal ownership-type "CONTRACT_MFG") "Contract Manufacturing")))
                                
                                (:div :class "form-group"
                                      (:label "Owner Entity Type *")
                                      (:select :class "form-control" :name "ownerentitytype" :required "required"
                                               (:option :value "SELLER" :selected (equal owner-entity-type "SELLER") "Seller/Vendor")
                                               (:option :value "BUYER" :selected (equal owner-entity-type "BUYER") "Buyer/Customer")
                                               (:option :value "PLATFORM" :selected (equal owner-entity-type "PLATFORM") "Platform")
                                               (:option :value "THIRD_PARTY_LOGISTICS" :selected (equal owner-entity-type "THIRD_PARTY_LOGISTICS") "3PL Provider")
                                               (:option :value "GOVERNMENT" :selected (equal owner-entity-type "GOVERNMENT") "Government")))
                                
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "ownerentityid" :type "number" 
                                             :value owner-entity-id :placeholder "Owner Entity ID *" :required "required"))
                                
                                (:hr)
                                (:div :class "form-group"
                                      (:label "Operator Entity Type " (:small "(if different from owner)"))
                                      (:select :class "form-control" :name "operatorentitytype"
                                               (:option :value "" :selected (null operator-entity-type) "-- Same as Owner --")
                                               (:option :value "SELLER" :selected (equal operator-entity-type "SELLER") "Seller/Vendor")
                                               (:option :value "BUYER" :selected (equal operator-entity-type "BUYER") "Buyer/Customer")
                                               (:option :value "PLATFORM" :selected (equal operator-entity-type "PLATFORM") "Platform")
                                               (:option :value "THIRD_PARTY_LOGISTICS" :selected (equal operator-entity-type "THIRD_PARTY_LOGISTICS") "3PL Provider")))
                                
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "operatorentityid" :type "number" 
                                             :value operator-entity-id :placeholder "Operator Entity ID (optional)"))
                                
                                (:hr)
                                (:div :class "form-group"
                                      (:label "Legal Entity Type (GST Registered) *")
                                      (:select :class "form-control" :name "legalentitytype" :required "required"
                                               (:option :value "SELLER" :selected (equal legal-entity-type "SELLER") "Seller/Vendor")
                                               (:option :value "BUYER" :selected (equal legal-entity-type "BUYER") "Buyer/Customer")
                                               (:option :value "PLATFORM" :selected (equal legal-entity-type "PLATFORM") "Platform")
                                               (:option :value "THIRD_PARTY_LOGISTICS" :selected (equal legal-entity-type "THIRD_PARTY_LOGISTICS") "3PL Provider")))
                                
                                (:div :class "panel panel-info"
                                      (:div :class "panel-heading" "Common Scenarios")
                                      (:div :class "panel-body"
                                            (:ul
                                             (:li (:strong "Traditional:") " Owner=Seller, Operator=Seller, Legal=Seller")
                                             (:li (:strong "VMI:") " Owner=Buyer, Operator=Seller, Legal=Buyer")
                                             (:li (:strong "3PL:") " Owner=3PL, Operator=3PL, Legal=3PL")))))
                          
                          ;; GST DETAILS TAB
                          (:div :role "tabpanel" :class "tab-pane" :id "gst"
                                (:br)
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "warehousegstin" :maxlength "15" 
                                             :value warehouse-gstin :placeholder "Warehouse GSTIN *" :type "text" :required "required"))
                                (:div :class "form-group"
                                      (:label "GSTIN Status")
                                      (:select :class "form-control" :name "gstinstatus"
                                               (:option :value "ACTIVE" :selected (equal gstin-status "ACTIVE") "Active")
                                               (:option :value "CANCELLED" :selected (equal gstin-status "CANCELLED") "Cancelled")
                                               (:option :value "SUSPENDED" :selected (equal gstin-status "SUSPENDED") "Suspended")))
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "legalname" :maxlength "200" 
                                             :value legal-name :placeholder "Legal Name" :type "text"))
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "pannumber" :maxlength "10" 
                                             :value pan-number :placeholder "PAN Number" :type "text"))
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "statecode" :maxlength "2" 
                                             :value state-code :placeholder "State Code (2 digits) *" :type "text" :required "required"))
                                (:div :class "form-group"
                                      (:label "Registration Type")
                                      (:select :class "form-control" :name "registrationtype"
                                               (:option :value "REGULAR" :selected (equal registration-type "REGULAR") "Regular")
                                               (:option :value "COMPOSITION" :selected (equal registration-type "COMPOSITION") "Composition")
                                               (:option :value "SEZ" :selected (equal registration-type "SEZ") "SEZ")
                                               (:option :value "EXPORT_WAREHOUSE" :selected (equal registration-type "EXPORT_WAREHOUSE") "Export Warehouse")
                                               (:option :value "UNREGISTERED" :selected (equal registration-type "UNREGISTERED") "Unregistered")))
                                (:div :class "form-group"
                                      (:label "Primary Location: ")
                                      (:input :type "checkbox" :name "isprimarylocation" :value "1" 
                                             :checked (equal is-primary-location 1)) " Mark as primary warehouse"))
                          
                          ;; LOGISTICS TAB
                          (:div :role "tabpanel" :class "tab-pane" :id "logistics"
                                (:br)
                                (:div :class "form-group"
                                      (:label "Warehouse Type")
                                      (:select :class "form-control" :name "warehousetype"
                                               (:option :value "OWN" :selected (equal warehouse-type "OWN") "Own")
                                               (:option :value "THIRD_PARTY" :selected (equal warehouse-type "THIRD_PARTY") "Third Party")
                                               (:option :value "CONSIGNMENT" :selected (equal warehouse-type "CONSIGNMENT") "Consignment")
                                               (:option :value "BRANCH" :selected (equal warehouse-type "BRANCH") "Branch")
                                               (:option :value "GODOWN" :selected (equal warehouse-type "GODOWN") "Godown")))
                                (:div :class "form-group"
                                      (:label "Warehouse Purpose")
                                      (:select :class "form-control" :name "warehousepurpose"
                                               (:option :value "SALES" :selected (equal warehouse-purpose "SALES") "Sales")
                                               (:option :value "STOCK_TRANSFER" :selected (equal warehouse-purpose "STOCK_TRANSFER") "Stock Transfer")
                                               (:option :value "MANUFACTURING" :selected (equal warehouse-purpose "MANUFACTURING") "Manufacturing")
                                               (:option :value "BOTH" :selected (equal warehouse-purpose "BOTH") "Both")))
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "defaulttransporterid" :maxlength "15" 
                                             :value default-transporter-id :placeholder "Default Transporter ID" :type "text"))
                                (:div :class "form-group"
                                      (:input :class "form-control" :name "defaulttransportername" :maxlength "200" 
                                             :value default-transporter-name :placeholder "Default Transporter Name" :type "text"))
                                (:div :class "form-group"
                                      (:label "E-Way Bill Enabled: ")
                                      (:input :type "checkbox" :name "ewaybillenabled" :value "1" 
                                             :checked (equal eway-bill-enabled 1)) " Enable E-Way Bill")
                                (:div :class "form-group"
                                      (:label "Valuation Method")
                                      (:select :class "form-control" :name "valuationmethod"
                                               (:option :value "FIFO" :selected (equal valuation-method "FIFO") "FIFO")
                                               (:option :value "LIFO" :selected (equal valuation-method "LIFO") "LIFO")
                                               (:option :value "WEIGHTED_AVG" :selected (equal valuation-method "WEIGHTED_AVG") "Weighted Average")))
                                (:div :class "form-group"
                                      (:label "HSN-wise Stock: ")
                                      (:input :type "checkbox" :name "hsnwisestock" :value "1" 
                                             :checked (equal hsn-wise-stock 1)) " Maintain HSN-wise stock"))
                          
                          ;; LOCATION TAB
                          (:div :role "tabpanel" :class "tab-pane" :id "location"
                                (:br)
                                (:div :class "form-group"
                                      (:label "Latitude")
                                      (:input :class "form-control" :name "latitude" :step "0.00000001" 
                                             :value latitude :placeholder "Latitude (e.g., 19.0760)" :type "number"))
                                (:div :class "form-group"
                                      (:label "Longitude")
                                      (:input :class "form-control" :name "longitude" :step "0.00000001" 
                                             :value longitude :placeholder "Longitude (e.g., 72.8777)" :type "number"))
                                (:div :class "alert alert-info" :role "alert"
                                      (:i :class "fa fa-info-circle") " Location coordinates help in tracking and logistics optimization.")))
                    
                    ;; Submit Button
                    (:div :class "form-group"
                          (:button :class "btn btn-lg btn-primary btn-block" 
                                  :type "submit" "Submit"))))))))


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


