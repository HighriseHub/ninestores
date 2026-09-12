;;; nst-dal-warehouse.lisp — Domain class
(in-package :nstores)

(defclass nst-whs (nst-domain-entity)   ; NOT (business-object nst-domain-entity)
  ;; ═══════════════════════════════════════════════════════════════════════════
  ;; INITFORMS MIRROR THE DDL (installation/upgrades/nst-dbu-warehouse.lisp).
  ;;
  ;; WHY THEY EXIST: without an initform a slot is UNBOUND until a caller
  ;; supplies it, and copyWarehouse-domaintodb reads every field with a plain
  ;; (slot-value source 'x) — so a caller that omits any field aborted with
  ;; UNBOUND-SLOT. The internal web form happens to post all 40 fields; an API
  ;; client sends three. Worse, making the copier tolerant alone would not fix
  ;; it: CLSQL's update-records-from-instance emits EVERY storable slot, so a
  ;; nil would be written as an explicit NULL — bypassing the column DEFAULT and
  ;; failing outright on the NOT NULL ... DEFAULT columns (OWNERSHIP_TYPE,
  ;; OWNER_ENTITY_TYPE, LEGAL_ENTITY_TYPE).
  ;;
  ;; So each default below is the SCHEMA's default, copied deliberately:
  ;;   * "Y"/"N"/0/1  → DELETED_STATE 'N', ACTIVE_FLAG 'Y', IS_PRIMARY_LOCATION
  ;;     '0', EWAY_BILL_ENABLED '1', HSN_WISE_STOCK '0'
  ;;   * enums        → OWNERSHIP_TYPE 'SELLER_OWNED', OWNER_ENTITY_TYPE 'SELLER',
  ;;     LEGAL_ENTITY_TYPE 'SELLER', GSTIN_STATUS 'ACTIVE',
  ;;     REGISTRATION_TYPE 'REGULAR', WAREHOUSE_TYPE 'OWN',
  ;;     WAREHOUSE_PURPOSE 'SALES', VALUATION_METHOD 'FIFO'
  ;;   * OWNER_ENTITY_ID is NOT NULL with NO default, so 0 is the class's own
  ;;     choice — matching what the web form's parse-int-or-0 already sends.
  ;; NIL means "column is nullable": the value may legitimately be absent, and
  ;; the two NOT NULL fields left nil (W_NAME, WAREHOUSE_GSTIN) are refused by
  ;; the database with the column named, which is the honest place for that rule.
  ;;
  ;; row-id and company deliberately keep NO initform: row-id is bound by
  ;; bind-generated-row-id after the INSERT, and company must fail loudly when a
  ;; caller forgets it (the API covers that case with :inject-company).
  ;; ═══════════════════════════════════════════════════════════════════════════
  ((row-id
    :initarg :row-id
    :accessor row-id)
   ;; UNIQUE IDENTIFIERS
   (warehouse-uuid
    :accessor warehouse-uuid
    :initarg :warehouse-uuid
    :initform nil
    :documentation "System UUID for internal/API use — generated in make")
   (warehouse-code
    :accessor warehouse-code
    :initarg :warehouse-code
    :initform nil
    :documentation "Business-friendly code (e.g., WH-EB70DB91) — generated in make")
   ;; BASIC INFO
   (wname
    :initarg :wname
    :accessor wname
    :initform nil
    :documentation "W_NAME — NOT NULL: the database refuses a warehouse without a name")
   (waddr1
    :initarg :waddr1
    :accessor waddr1
    :initform nil)
   (waddr2
    :initarg :waddr2
    :accessor waddr2
    :initform nil)
   (wpin
    :initarg :wpin
    :accessor wpin
    :initform nil)
   (wcity
    :initarg :wcity
    :accessor wcity
    :initform nil)
   (wstate
    :initarg :wstate
    :accessor wstate
    :initform nil)
   (wcountry
    :initarg :wcountry
    :accessor wcountry
    :initform nil)
   (wmanager
    :initarg :wmanager
    :accessor wmanager
    :initform nil)
   (wphone
    :initarg :wphone
    :accessor wphone
    :initform nil)
   (waltphone
    :initarg :waltphone
    :accessor waltphone
    :initform nil)
   (wemail
    :initarg :wemail
    :accessor wemail
    :initform nil)
   
   ;; AUDIT FIELDS
   (activeflag
    :initarg :activeflag
    :accessor activeflag
    :initform "Y"
    :documentation "ACTIVE_FLAG DEFAULT 'Y'")
   
   ;; OWNERSHIP MODEL
   (ownership-type
    :initarg :ownership-type
    :accessor ownership-type
    :initform "SELLER_OWNED"
    :documentation "SELLER_OWNED, BUYER_OWNED, THIRD_PARTY, PLATFORM_OWNED, BONDED, CONTRACT_MFG — DDL default SELLER_OWNED")
   
   (owner-entity-type
    :initarg :owner-entity-type
    :accessor owner-entity-type
    :initform "SELLER"
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS, GOVERNMENT — DDL default SELLER")
   
   (owner-entity-id
    :initarg :owner-entity-id
    :accessor owner-entity-id
    :initform 0
    :documentation "FK to owner entity. NOT NULL with no DDL default, so 0 = unset — the same value the web form's parse-int-or-0 sends")

   (vendor
    :initarg :vendor
    :accessor vendor
    :initform nil
    :documentation "By default the vendor is the owner of this warehouse")
   
   (operator-entity-type
    :initarg :operator-entity-type
    :accessor operator-entity-type
    :initform nil
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS — nullable in the DDL")
   
   (operator-entity-id
    :initarg :operator-entity-id
    :accessor operator-entity-id
    :initform nil
    :documentation "FK to operator entity")
   
   (legal-entity-type
    :initarg :legal-entity-type
    :accessor legal-entity-type
    :initform "SELLER"
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS — DDL default SELLER")
   
   ;; GST COMPLIANCE
   (warehouse-gstin
    :initarg :warehouse-gstin
    :accessor warehouse-gstin
    :initform nil
    :documentation "NOT NULL: part of uk_gstin_name_tenant — the identity ?exists checks")
   (gstin-status
    :initarg :gstin-status
    :accessor gstin-status
    :initform "ACTIVE"
    :documentation "ACTIVE, CANCELLED, SUSPENDED — DDL default ACTIVE")
   (legal-name
    :initarg :legal-name
    :accessor legal-name
    :initform nil)
   (is-primary-location
    :initarg :is-primary-location
    :accessor is-primary-location
    :initform 0
    :documentation "DDL default 0")
   (state-code
    :initarg :state-code
    :accessor state-code
    :initform nil
    :documentation "NOT NULL: GST jurisdiction state code")
   (registration-type
    :initarg :registration-type
    :accessor registration-type
    :initform "REGULAR"
    :documentation "DDL default REGULAR")
   (pan-number
    :initarg :pan-number
    :accessor pan-number
    :initform nil)
   
   ;; WAREHOUSE CLASSIFICATION
   (warehouse-type
    :initarg :warehouse-type
    :accessor warehouse-type
    :initform "OWN"
    :documentation "DDL default OWN")
   (warehouse-purpose
    :initarg :warehouse-purpose
    :accessor warehouse-purpose
    :initform "SALES"
    :documentation "DDL default SALES")
   
   ;; LOGISTICS
   (default-transporter-id
    :initarg :default-transporter-id
    :accessor default-transporter-id
    :initform nil)
   (default-transporter-name
    :initarg :default-transporter-name
    :accessor default-transporter-name
    :initform nil)
   (eway-bill-enabled
    :initarg :eway-bill-enabled
    :accessor eway-bill-enabled
    :initform 1
    :documentation "DDL default 1")
   
   ;; LOCATION
   (latitude
    :initarg :latitude
    :accessor latitude
    :initform nil)
   (longitude
    :initarg :longitude
    :accessor longitude
    :initform nil)
   
   ;; INVENTORY MANAGEMENT
   (valuation-method
    :initarg :valuation-method
    :accessor valuation-method
    :initform "FIFO"
    :documentation "FIFO, LIFO, WEIGHTED_AVG — DDL default FIFO")
   (hsn-wise-stock
    :initarg :hsn-wise-stock
    :accessor hsn-wise-stock
    :initform 0
    :documentation "DDL default 0")
   
   ;; TENANT — no initform on purpose: it must fail loudly if a caller forgets
   ;; it (the API injects the session company; the web form passes it).
   (company
    :initarg :company
    :accessor company))
  
   (:documentation
   "Warehouse domain entity. Single-गण (भण्डारगण). Reference entity —
    no BusinessService in its call path per the earlier architecture
    decision. id/tenant-id/created-at/updated-at/deleted-state are all
    inherited from nst-domain-entity — do not redeclare them here.

    Every DOD_WAREHOUSE field this class declares now carries an initform, one
    per column, matching the schema default (or NIL where the column is
    nullable). That is what lets a partial caller — the JSON API today, any
    future importer — create a row that is identical to what the database would
    have defaulted, instead of aborting in copyWarehouse-domaintodb on the first
    unbound slot. Add new columns here WITH their DDL default, or the class
    drifts from the schema again."))


(defclass WarehouseRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object (Tree 2) for warehouse operations.

    Deliberately SLOTLESS: carries NO per-field typed slots. All inbound
    data rides in the inherited `params` slot as a transport-shaped
    plist. The ferry (request->dispatch / extract-domain-initargs in
    nst-bl-adhara.lisp) reads (params rm) and MOP-filters that plist
    against whatever initargs nst-whs actually declares — one universal
    translator, zero per-entity mapping code.

    row-id and any changed/owned fields travel as plist keys in params,
    e.g. (:row-id 42 :wname \"...\"). :tenant-id and audit keys are
    stripped by extract-domain-initargs and never accepted from a client.

    The domain->response field-by-field copy is the OUTBOUND leg only;
    this inbound leg intentionally has no typed mirror of nst-whs."))

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


;;; ---------------------------------------------------------------------------
;;; Database View Class (ORM Mapping) - COMPLETE with ownership fields
;;; ---------------------------------------------------------------------------
;;; Moved here from dod-dal-wrh.lisp: this is the CLSQL ORM mapping for the
;;; shared dod_warehouse table. It is the persistence schema actually used by
;;; the gana verbs (make/!update/delete!/enumerate in nst-bl-warehouse.lisp all
;;; instantiate real dod-warehouse objects), so it belongs with the new DAL,
;;; not with the retired DDD model.
(clsql:def-view-class dod-warehouse ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg :row-id
    :accessor row-id)
   
   ;; UNIQUE IDENTIFIERS
   (warehouse-uuid
    :accessor warehouse-uuid
    :type (string 36)
    :initarg :warehouse-uuid
    :db-constraints (:not-null :unique))
   
   (warehouse-code
    :accessor warehouse-code
    :type (string 20)
    :initarg :warehouse-code
    :db-constraints (:not-null :unique))
   
   ;; BASIC INFO
   (w-name
    :accessor w-name
    :type (string 100)
    :initarg :w-name)
   (w-addr1
    :accessor w-addr1
    :type (string 100)
    :initarg :w-addr1)
   (w-addr2
    :accessor w-addr2
    :type (string 100)
    :initarg :w-addr2)
   (w-pin
    :accessor w-pin
    :type (string 6)
    :initarg :w-pin)
   (w-city
    :accessor w-city
    :type (string 30)
    :initarg :w-city)
   (w-state
    :accessor w-state
    :type (string 30)
    :initarg :w-state)
   (w-country
    :accessor w-country
    :type (string 30)
    :initarg :w-country)
   (w-manager
    :accessor w-manager
    :type (string 100)
    :initarg :w-manager)
   (w-phone
    :accessor w-phone
    :type (string 16)
    :initarg :w-phone)
   (w-alt-phone
    :accessor w-alt-phone
    :type (string 16)
    :initarg :w-alt-phone)
   (w-email
    :accessor w-email
    :type (string 100)
    :initarg :w-email)
   
   ;; AUDIT FIELDS
   (created
    :accessor created
    :type (string 30)
    :initarg :created
    :db-kind :base)
   (updated
    :accessor updated
    :type (string 30)
    :initarg :updated
    :db-kind :base)
   (deleted-state
    :accessor deleted-state
    :type (string 1)
    :initarg :deleted-state)
   (active-flag
    :accessor active-flag
    :type (string 1)
    :initarg :active-flag)
   
   ;; MULTI-TENANCY
   (tenant-id
    :type integer
    :initarg :tenant-id
    :accessor tenant-id)
   
   ;; OWNERSHIP MODEL (NEW FIELDS)
   (ownership-type
    :accessor ownership-type
    :type (string 30)
    :initarg :ownership-type
    :documentation "SELLER_OWNED, BUYER_OWNED, THIRD_PARTY, PLATFORM_OWNED, BONDED, CONTRACT_MFG")
   
   (owner-entity-type
    :accessor owner-entity-type
    :type (string 30)
    :initarg :owner-entity-type
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS, GOVERNMENT")
   
   (owner-entity-id
    :accessor owner-entity-id
    :type integer
    :initarg :owner-entity-id
    :documentation "FK to owner entity")
   (vendor 
    :accessor vendor
    :db-kind :join
    :db-info (:join-class dod-vend-profile
                          :home-key owner-entity-id
                          :foreign-key row-id
                          :set nil))
   
   
   (operator-entity-type
    :accessor operator-entity-type
    :type (string 30)
    :initarg :operator-entity-type
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS")
   
   (operator-entity-id
    :accessor operator-entity-id
    :type integer
    :initarg :operator-entity-id
    :documentation "FK to operator entity")
   
   (legal-entity-type
    :accessor legal-entity-type
    :type (string 30)
    :initarg :legal-entity-type
    :documentation "SELLER, BUYER, PLATFORM, THIRD_PARTY_LOGISTICS")
   
   ;; GST COMPLIANCE
   (warehouse-gstin
    :accessor warehouse-gstin
    :type (string 15)
    :initarg :warehouse-gstin)
   (gstin-status
    :accessor gstin-status
    :type (string 20)
    :initarg :gstin-status)
   (legal-name
    :accessor legal-name
    :type (string 200)
    :initarg :legal-name)
   (is-primary-location
    :accessor is-primary-location
    :type integer
    :initarg :is-primary-location)
   (state-code
    :accessor state-code
    :type (string 2)
    :initarg :state-code)
   (registration-type
    :accessor registration-type
    :type (string 30)
    :initarg :registration-type)
   (pan-number
    :accessor pan-number
    :type (string 10)
    :initarg :pan-number)
   
   ;; WAREHOUSE CLASSIFICATION
   (warehouse-type
    :accessor warehouse-type
    :type (string 30)
    :initarg :warehouse-type)
   (warehouse-purpose
    :accessor warehouse-purpose
    :type (string 30)
    :initarg :warehouse-purpose)
   
   ;; LOGISTICS
   (default-transporter-id
    :accessor default-transporter-id
    :type (string 15)
    :initarg :default-transporter-id)
   (default-transporter-name
    :accessor default-transporter-name
    :type (string 200)
    :initarg :default-transporter-name)
   (eway-bill-enabled
    :accessor eway-bill-enabled
    :type integer
    :initarg :eway-bill-enabled)
   
   ;; LOCATION
   (latitude
    :accessor latitude
    :type float
    :initarg :latitude)
   (longitude
    :accessor longitude
    :type float
    :initarg :longitude)
   
   ;; INVENTORY MANAGEMENT
   (valuation-method
    :accessor valuation-method
    :type (string 20)
    :initarg :valuation-method)
   (hsn-wise-stock
    :accessor hsn-wise-stock
    :type integer
    :initarg :hsn-wise-stock)
   
   ;; COMPANY JOIN
   (company
    :accessor get-company
    :db-kind :join
    :db-info (:join-class dod-company
                          :home-key tenant-id
                          :foreign-key row-id
                          :set nil)))
  (:base-table dod_warehouse))


