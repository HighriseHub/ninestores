;;; nst-dal-warehouse.lisp — Domain class
(in-package :nstores)

(defclass nst-whs (nst-domain-entity)   ; NOT (business-object nst-domain-entity)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   ;; UNIQUE IDENTIFIERS
   (warehouse-uuid
    :accessor warehouse-uuid
    :initarg :warehouse-uuid
    :documentation "System UUID for internal/API use")
   (warehouse-code
    :accessor warehouse-code
    :initarg :warehouse-code
    :documentation "Business-friendly code (e.g., MH-MUM-WH-001)")
   ;; BASIC INFO
   (wname
    :initarg :wname
    :accessor wname)
   (waddr1
    :initarg :waddr1
    :accessor waddr1)
   (waddr2
    :initarg :waddr2
    :accessor waddr2)
   (wpin
    :initarg :wpin
    :accessor wpin)
   (wcity
    :initarg :wcity
    :accessor wcity)
   (wstate
    :initarg :wstate
    :accessor wstate)
   (wcountry
    :initarg :wcountry
    :accessor wcountry)
   (wmanager
    :initarg :wmanager
    :accessor wmanager)
   (wphone
    :initarg :wphone
    :accessor wphone)
   (waltphone
    :initarg :waltphone
    :accessor waltphone)
   (wemail
    :initarg :wemail
    :accessor wemail)
   
   ;; AUDIT FIELDS
   (activeflag
    :initarg :activeflag
    :accessor activeflag)
   
   ;; OWNERSHIP MODEL
   (ownership-type
    :initarg :ownership-type
    :accessor ownership-type
    :documentation "SELLER_OWNED, BUYER_OWNED, THIRD_PARTY, PLATFORM_OWNED, BONDED, CONTRACT_MFG")
   
   (owner-entity-type
    :initarg :owner-entity-type
    :accessor owner-entity-type
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS, GOVERNMENT")
   
   (owner-entity-id
    :initarg :owner-entity-id
    :accessor owner-entity-id
    :documentation "FK to owner entity")

   (vendor
    :initarg :vendor
    :accessor vendor
    :documentation "By default the vendor is the owner of this warehouse")
   
   (operator-entity-type
    :initarg :operator-entity-type
    :accessor operator-entity-type
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS")
   
   (operator-entity-id
    :initarg :operator-entity-id
    :accessor operator-entity-id
    :documentation "FK to operator entity")
   
   (legal-entity-type
    :initarg :legal-entity-type
    :accessor legal-entity-type
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS")
   
   ;; GST COMPLIANCE
   (warehouse-gstin
    :initarg :warehouse-gstin
    :accessor warehouse-gstin)
   (gstin-status
    :initarg :gstin-status
    :accessor gstin-status)
   (legal-name
    :initarg :legal-name
    :accessor legal-name)
   (is-primary-location
    :initarg :is-primary-location
    :accessor is-primary-location)
   (state-code
    :initarg :state-code
    :accessor state-code)
   (registration-type
    :initarg :registration-type
    :accessor registration-type)
   (pan-number
    :initarg :pan-number
    :accessor pan-number)
   
   ;; WAREHOUSE CLASSIFICATION
   (warehouse-type
    :initarg :warehouse-type
    :accessor warehouse-type)
   (warehouse-purpose
    :initarg :warehouse-purpose
    :accessor warehouse-purpose)
   
   ;; LOGISTICS
   (default-transporter-id
    :initarg :default-transporter-id
    :accessor default-transporter-id)
   (default-transporter-name
    :initarg :default-transporter-name
    :accessor default-transporter-name)
   (eway-bill-enabled
    :initarg :eway-bill-enabled
    :accessor eway-bill-enabled)
   
   ;; LOCATION
   (latitude
    :initarg :latitude
    :accessor latitude)
   (longitude
    :initarg :longitude
    :accessor longitude)
   
   ;; INVENTORY MANAGEMENT
   (valuation-method
    :initarg :valuation-method
    :accessor valuation-method)
   (hsn-wise-stock
    :initarg :hsn-wise-stock
    :accessor hsn-wise-stock)
   
   ;; TENANT
   (company
    :initarg :company
    :accessor company))
  
   (:documentation
   "Warehouse domain entity. Single-गण (भण्डारगण). Reference entity —
    no BusinessService in its call path per the earlier architecture
    decision. id/tenant-id/created-at/updated-at/deleted-state are all
    inherited from nst-domain-entity — do not redeclare them here.

    Remaining DOD_WAREHOUSE columns (registration-type, purpose,
    default-transporter, lat/long, valuation-method, hsn-wise-stock,
    pan-number, addr1/addr2) deliberately NOT added yet — add one at
    a time, per column, when a real verb needs it."))


(defclass WarehouseResponseModel (nst-boundary-object)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   ;; UNIQUE IDENTIFIERS
   (warehouse-uuid
    :accessor warehouse-uuid
    :initarg :warehouse-uuid
    :documentation "System UUID for internal/API use")
   (warehouse-code
    :accessor warehouse-code
    :initarg :warehouse-code
    :documentation "Business-friendly code (e.g., MH-MUM-WH-001)")
   ;; BASIC INFO
   (wname
    :initarg :wname
    :accessor wname)
   (waddr1
    :initarg :waddr1
    :accessor waddr1)
   (waddr2
    :initarg :waddr2
    :accessor waddr2)
   (wpin
    :initarg :wpin
    :accessor wpin)
   (wcity
    :initarg :wcity
    :accessor wcity)
   (wstate
    :initarg :wstate
    :accessor wstate)
   (wcountry
    :initarg :wcountry
    :accessor wcountry)
   (wmanager
    :initarg :wmanager
    :accessor wmanager)
   (wphone
    :initarg :wphone
    :accessor wphone)
   (waltphone
    :initarg :waltphone
    :accessor waltphone)
   (wemail
    :initarg :wemail
    :accessor wemail)
   
   ;; AUDIT FIELDS
   (activeflag
    :initarg :activeflag
    :accessor activeflag)
   
   ;; OWNERSHIP MODEL
   (ownership-type
    :initarg :ownership-type
    :accessor ownership-type
    :documentation "SELLER_OWNED, BUYER_OWNED, THIRD_PARTY, PLATFORM_OWNED, BONDED, CONTRACT_MFG")
   
   (owner-entity-type
    :initarg :owner-entity-type
    :accessor owner-entity-type
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS, GOVERNMENT")
   
   (owner-entity-id
    :initarg :owner-entity-id
    :accessor owner-entity-id
    :documentation "FK to owner entity")

   (vendor
    :initarg :vendor
    :accessor vendor
    :documentation "By default the vendor is the owner of this warehouse")
   
   (operator-entity-type
    :initarg :operator-entity-type
    :accessor operator-entity-type
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS")
   
   (operator-entity-id
    :initarg :operator-entity-id
    :accessor operator-entity-id
    :documentation "FK to operator entity")
   
   (legal-entity-type
    :initarg :legal-entity-type
    :accessor legal-entity-type
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS")
   
   ;; GST COMPLIANCE
   (warehouse-gstin
    :initarg :warehouse-gstin
    :accessor warehouse-gstin)
   (gstin-status
    :initarg :gstin-status
    :accessor gstin-status)
   (legal-name
    :initarg :legal-name
    :accessor legal-name)
   (is-primary-location
    :initarg :is-primary-location
    :accessor is-primary-location)
   (state-code
    :initarg :state-code
    :accessor state-code)
   (registration-type
    :initarg :registration-type
    :accessor registration-type)
   (pan-number
    :initarg :pan-number
    :accessor pan-number)
   
   ;; WAREHOUSE CLASSIFICATION
   (warehouse-type
    :initarg :warehouse-type
    :accessor warehouse-type)
   (warehouse-purpose
    :initarg :warehouse-purpose
    :accessor warehouse-purpose)
   
   ;; LOGISTICS
   (default-transporter-id
    :initarg :default-transporter-id
    :accessor default-transporter-id)
   (default-transporter-name
    :initarg :default-transporter-name
    :accessor default-transporter-name)
   (eway-bill-enabled
    :initarg :eway-bill-enabled
    :accessor eway-bill-enabled)
   
   ;; LOCATION
   (latitude
    :initarg :latitude
    :accessor latitude)
   (longitude
    :initarg :longitude
    :accessor longitude)
   
   ;; INVENTORY MANAGEMENT
   (valuation-method
    :initarg :valuation-method
    :accessor valuation-method)
   (hsn-wise-stock
    :initarg :hsn-wise-stock
    :accessor hsn-wise-stock)
   
   ;; TENANT
   (company
    :initarg :company
    :accessor company))
  
  (:documentation
   "Boundary response model for warehouses. Adapter/HTTP outbound shape.
    Contains all nst-whs fields; dies at the layer boundary."))


