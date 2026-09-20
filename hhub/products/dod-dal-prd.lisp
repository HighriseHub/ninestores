;;; dod-dal-prd.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(clsql:def-view-class dod-prd-master ()
  ((row-id
    :db-kind :key
    :db-constraints :primary-key 
    :type integer
    :accessor row-id
    :initarg :row-id)

   (prd-name
    :accessor prd-name
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 70)
    :INITARG :prd-name)

   (description
    :type (string 1024)
    :initarg :description)

   (vendor-id
    :type integer 
    :initarg :vendor-id)
   (vendor
    :ACCESSOR product-vendor
    :initarg :vendor
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-vend-profile
	                  :HOME-KEY vendor-id
                          :FOREIGN-KEY row-id
                          :SET NIL))

   (catg-id
    :type integer
    :initarg :catg-id)
   (category
    :initarg :category
    :accessor product-category
    :db-kind :join
    :db-info (:join-class dod-prd-catg
			  :home-key catg-id 
			  :foreign-key row-id
			  :set nil))

   (qty-per-unit
    :accessor qty-per-unit
    :type float
    :initarg :qty-per-unit)
   (unit-of-measure
    :ACCESSOR unit-of-measure
    :type (string 20)
    :INITARG :unit-of-measure)
   
   (prd-image-path
    :accessor prd-image-path
    :type (string 1024)
    :initarg :prd-image-path)
   
   (current-price
    :accessor current-price
    :type float
    :initarg :current-price)

   (current-discount
    :accessor :current-discount
    :type float
    :initarg :current-discount)
   
   (units-in-stock
    :type integer
    :initarg :units-in-stock)

   (hsn-code
    :type (string 8)
    :initarg :hsn-code)

   (sku
    :type (string 20)
    :initarg :sku)

   (upc
    :type (string 20)
    :initarg :upc)
   (ean
    :type (string 20)
    :initarg :ean)
   (jan
    :type (string 20)
    :initarg :jan)
   (isbn
    :type (string 20)
    :initarg :isbn)
   (serial-no
    :type (string 20)
    :initarg :serial-no)
   
   (external-url
    :type (string 255)
    :initarg :external-url)

   (shipping-length-cms
    :type integer
    :initarg :shipping-length-cms)

   (shipping-width-cms
    :type integer
    :initarg :shipping-width-cms)

   (shipping-height-cms
    :type integer
    :initarg :shipping-height-cms)

   (shipping-weight-kg
    :type float
    :initarg :shipping-weight-kg)
 
   (active-flag
    :type (string 1)
    :void-value "N"
    :initarg :active-flag)


   (deleted-state
    :type (string 1)
    :void-value "N"
       :initarg :deleted-state)

   (subscribe-flag
	  :type (string 1)
	  :void-value "N"
	  :initarg :subscribe-flag)

   (approved-flag 
    :type (string 1) 
    :void-value "N"
    :initarg :approved-flag) 
   (approval-status 
    :type (string 20) 
    :void-value "PENDING"
    :initarg :approval-status)

   (prd-type
    :type (string 4)
    :void-value "SALE"
    :initarg :prd-type)

   (product-code
    :type (string 50) 
    :void-value (format nil "NST-~A" (hhub-random-password 10))
    :initarg :product-code)
   
   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR product-company
    :initarg :company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
              :SET NIL)))
  (:BASE-TABLE dod_prd_master)
  (:keys row-id))


;; PRODUCT PRICING


(clsql:def-view-class dod-product-pricing ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)

   (product-id
    :accessor product-id
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE integer
    :INITARG :product-id)

   (price
    :type float
    :initarg :price)

   (discount
    :type float
    :initarg :discount)
   
   (currency
    :type (string 3)
    :void-value "INR"
    :initarg :currency)

   (start-date
    :accessor start-date
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE clsql:date
    :initarg :start-date)
   (end-date
    :accessor end-date
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE clsql:date
    :initarg :end-date)
      
   (active-flag
    :type (string 1)
    :void-value "N"
    :initarg :active-flag)


   (deleted-state
    :type (string 1)
    :void-value "N"
    :initarg :deleted-state)

   (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR product-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET T)))

   
  (:BASE-TABLE dod_product_pricing))


;;;;;;;;;;;; PRODUCT GST — REMOVED ;;;;;;;;;;;;;;;;;;;;;;;;;
;;; dod-product-gst WAS DELETED HERE (2026-09-19). It was referenced
;;; NOWHERE in this tree (verified by grep across every .lisp file), and it
;;; could not have worked: its (:BASE-TABLE ...) was DOD_PRODUCT_PRICING — a
;;; copy-paste of the pricing class directly above it, which is also why it
;;; carried price / discount / start-date / end-date and the
;;; (:JOIN-CLASS dod-company) company slot. No DOD_PRODUCT_GST table has ever
;;; existed in hhubdb (SHOW TABLES LIKE '%PRODUCT_GST%' returns nothing).
;;; The GST domain has its own classes in products/dod-dal-gst.lisp
;;; (GSTHSNCodes and friends), which is where GST data is actually read.

; Product category

(clsql:def-view-class dod-prd-catg ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)

      (catg-name
    :accessor catg-name
    :DB-CONSTRAINTS :NOT-NULL
    :TYPE (string 70)
    :INITARG :catg-name)

   (lft 
    :accessor get-left
    :type integer 
    :initarg :lft) 
   
   (rgt 
    :accessor get-right
    :type integer 
    :initarg :rgt) 
   

   (active-flag
    :type (string 1)
    :void-value "N"
       :initarg :active-flag)


   (deleted-state
    :type (string 1)
    :void-value "N"
       :initarg :deleted-state)

    (tenant-id
    :type integer
    :initarg :tenant-id)
   (COMPANY
    :ACCESSOR product-company
    :DB-KIND :JOIN
    :DB-INFO (:JOIN-CLASS dod-company
	                  :HOME-KEY tenant-id
                          :FOREIGN-KEY row-id
                          :SET T)))

   
  (:BASE-TABLE dod_prd_catg))





(clsql:def-view-class dod-gst-sac-codes ()
  ((row-id
    :db-kind :key
    :db-constraints :not-null
    :type integer
    :initarg row-id)
   (sac-code
    :accessor sac-code
    :TYPE (string 10))

   (sac-description
    :accessor sac-description
    :TYPE (string 500))

   (sac-code-4digit
    :accessor sac-code-4digit
    :type (string 4))

   (condition-txt
    :accessor condition-txt
    :TYPE (string 500))
   
   (cgst
    :accessor cgst
    :type float
    :initarg :cgst)

   (sgst
    :accessor sgst
    :type float
    :initarg :sgst)

   (igst
    :accessor igst
    :type float
    :initarg :igst)

   (gst-sac-func
    :accessor gst-hsn-func
    :TYPE (string 255)))


  (:BASE-TABLE dod_gst_sac_codes))



;;; ═══════════════════════════════════════════════════════════════════════════
;;; nst-prd — the product DOMAIN ENTITY (adhara Tree 1).
;;;
;;; WHY IT EXISTS: the Tier-1 प्रत्यय in dod-bl-prd.lisp (make / fetch /
;;; enumerate / !update / delete! / ?exists) dispatch on a class symbol and
;;; construct nst-domain-entity instances, so that the नियम checks in
;;; nst-bl-adhara.lisp fire on what they act upon. dod-prd-master is a CLSQL
;;; view-class: it is the DATABASE ROW. It does not inherit the domain root and
;;; carries none of the tenant discipline. This class is the missing कर्म.
;;;
;;; INITFORMS MIRROR THE LIVE SCHEMA, verified by direct query
;;; (SHOW COLUMNS FROM DOD_PRD_MASTER / SHOW INDEX FROM DOD_PRD_MASTER) — NOT
;;; installation/hhubplatform.sql, which is STALE FOR THIS TABLE exactly as
;;; nst-bl-apidefs2-CONTEXT.md records for DOD_WAREHOUSE. That file still shows
;;; UNIT_PRICE, a duplicated QTY_PER_UNIT column and no UNIT_OF_MEASURE; the
;;; live table has CURRENT_PRICE, CURRENT_DISCOUNT, UNIT_OF_MEASURE and a single
;;; qty_per_unit. Do not "correct" the slots below back to that file.
;;;
;;; THE LIVE FACTS THIS CLASS ENCODES:
;;;
;;;   * PRODUCT_CODE (varchar 50, NOT NULL, UNIQUE) is the ONLY unique key on
;;;     the table — the DB actually carries two identical unique indexes,
;;;     PRODUCT_CODE and PRODUCT_CODE_2. It is therefore the entity's identity,
;;;     and ?exists checks it (see dod-bl-prd.lisp). There is NO unique key on
;;;     (PRD_NAME, TENANT_ID) and none on SKU: duplicate product names and
;;;     duplicate SKUs are legal here — unlike DOD_WAREHOUSE's
;;;     uk_gstin_name_tenant, where identity is a tuple. Do not invent a tuple
;;;     check this schema will not back.
;;;
;;;   * PRODUCT_CODE is NOT NULL with NO column default, so the class leaves it
;;;     nil and make generates it ("PRD-" + 10 random chars — the shape
;;;     persist-product already writes). A caller that omits it is then refused
;;;     by the database with the column named, which is the honest place for
;;;     that rule.
;;;     ⚠ dod-prd-master's own :void-value for this column,
;;;     (format nil "NST-~A" (hhub-random-password 10)), is evaluated ONCE at
;;;     class-definition time — so it hands EVERY instance the SAME code, which
;;;     the unique key rejects on the second insert. persist-product computes
;;;     its own code, which is why the bug never surfaced. Never rely on it.
;;;
;;;   * Every other column is nullable with no default → initform nil.
;;;     PRD_TYPE is the single exception: the column default is 'SALE'.
;;;
;;;   * active_flag, approved_flag and approval_status are THREE INDEPENDENT
;;;     COLUMNS, not one status field. The live data sits at active_flag='Y',
;;;     approved_flag='N', approval_status='PENDING': in this system a product
;;;     is listed first and approved later, by CompAdmin. make reproduces
;;;     exactly that, as persist-product does.
;;;
;;;   * QTY_PER_UNIT is varchar(30) in the live table while dod-prd-master
;;;     declares the slot :type float. Treat it as a string; do not assume
;;;     arithmetic on this slot is meaningful.
;;;
;;;   * current_price / current_discount are denormalised ON the master row.
;;;     Tiered prices are a separate table (dod-product-pricing), keyed by
;;;     product-id — a product has both a "current" price and price tiers.
;;;
;;; id / tenant-id / created-at / updated-at / deleted-state are INHERITED from
;;; nst-domain-entity — they are never redeclared here.
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass nst-prd (nst-domain-entity)   ; NOT (business-object nst-domain-entity)
  (;; ROW — bound by bind-generated-row-id after the INSERT, never by a caller.
   (row-id
    :initarg :row-id
    :accessor row-id)
   ;; IDENTITY
   (product-code
    :initarg :product-code
    :accessor product-code
    :initform nil
    :documentation "PRODUCT_CODE — NOT NULL + UNIQUE, no column default.
                    Generated in make; the DB refuses a product without it.
                    This is what ?exists checks.")
   ;; CATALOG DESCRIPTION
   (prd-name
    :initarg :prd-name
    :accessor prd-name
    :initform nil
    :documentation "PRD_NAME — varchar(70), NULLABLE in the live table.
                    (dod-prd-master's :DB-CONSTRAINTS :NOT-NULL for this slot
                    is a Lisp-side claim the DB does not back.)")
   (description
    :initarg :description
    :accessor description
    :initform nil)
   (vendor-id
    :initarg :vendor-id
    :accessor vendor-id
    :initform nil
    :documentation "FK → DOD_VEND_PROFILE.ROW_ID, nullable in the DB")
   (catg-id
    :initarg :catg-id
    :accessor catg-id
    :initform nil
    :documentation "FK → DOD_PRD_CATG.ROW_ID, nullable in the DB")
   (sku
    :initarg :sku
    :accessor sku
    :initform nil
    :documentation "No unique key on SKU in this schema")
   (hsn-code
    :initarg :hsn-code
    :accessor hsn-code
    :initform nil)
   (prd-type
    :initarg :prd-type
    :accessor prd-type
    :initform "SALE"
    :documentation "char(4) — the only column on this table with a real
                    DB default. Values seen: SALE, SERVICE.")
   (unit-of-measure
    :initarg :unit-of-measure
    :accessor unit-of-measure
    :initform nil)
   (qty-per-unit
    :initarg :qty-per-unit
    :accessor qty-per-unit
    :initform nil
    :documentation "varchar(30) live — a string, despite :type float on
                    dod-prd-master")
   (units-in-stock
    :initarg :units-in-stock
    :accessor units-in-stock
    :initform nil)
   (prd-image-path
    :initarg :prd-image-path
    :accessor prd-image-path
    :initform nil)
   (external-url
    :initarg :external-url
    :accessor external-url
    :initform nil)
   ;; TRADE IDENTIFIERS — no uniqueness of any kind in this schema
   (upc
    :initarg :upc
    :accessor upc
    :initform nil)
   (ean
    :initarg :ean
    :accessor ean
    :initform nil)
   (jan
    :initarg :jan
    :accessor jan
    :initform nil)
   (isbn
    :initarg :isbn
    :accessor isbn
    :initform nil)
   (serial-no
    :initarg :serial-no
    :accessor serial-no
    :initform nil)
   ;; PRICING — denormalised on the master row; tiers are dod-product-pricing
   (current-price
    :initarg :current-price
    :accessor current-price
    :initform nil)
   (current-discount
    :initarg :current-discount
    :accessor current-discount
    :initform nil)
   ;; LIFECYCLE — three independent columns
   (active-flag
    :initarg :active-flag
    :accessor active-flag
    :initform nil
    :documentation "char(1) 'Y'/'N'; the DB default is NULL (nullable).
                    make sets 'Y' — a new product is listed.")
   (approved-flag
    :initarg :approved-flag
    :accessor approved-flag
    :initform nil
    :documentation "char(1) 'Y'/'N'. make sets 'N': approval is CompAdmin's,
                    never the creator's.")
   (approval-status
    :initarg :approval-status
    :accessor approval-status
    :initform nil
    :documentation "varchar(20). make sets 'PENDING'.")
   (subscribe-flag
    :initarg :subscribe-flag
    :accessor subscribe-flag
    :initform nil)
   ;; SHIPPING
   (shipping-length-cms
    :initarg :shipping-length-cms
    :accessor shipping-length-cms
    :initform nil)
   (shipping-width-cms
    :initarg :shipping-width-cms
    :accessor shipping-width-cms
    :initform nil)
   (shipping-height-cms
    :initarg :shipping-height-cms
    :accessor shipping-height-cms
    :initform nil)
   (shipping-weight-kg
    :initarg :shipping-weight-kg
    :accessor shipping-weight-kg
    :initform nil)
   ;; TENANT — no initform on purpose: it must fail loudly when a caller
   ;; forgets it, rather than write a NULL tenant. The internal web form passes
   ;; :company explicitly; the JSON API injects the session company through
   ;; :inject-company. NOTE this is the legacy company JOIN slot that sits
   ;; beside the inherited tenant-id — see copyProduct-domaintodb, which derives
   ;; the DB row's TENANT_ID from it, as its warehouse twin does.
   (prd-company
    :initarg :company
    :accessor prd-company))
  (:documentation
   "Product domain entity. कर्म of the catalog प्रत्यय in dod-bl-prd.lisp.
    A product IS one entity, so no aggregate is assembled on the way to the
    database — the way a warehouse is one entity either."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; nst-prd-pricing — the TIER entity (DOD_PRODUCT_PRICING)
;;;
;;; WHY A SECOND ENTITY rather than a slot on nst-prd: current_price /
;;; current_discount are denormalised ON the master row, while these are the
;;; dated price TIERS, keyed by PRODUCT_ID — a product has one current price and
;;; many tiers. Unlike nst-vnd-shp's `zones`, a tier IS addressable on its own:
;;; it has its own row-id, its own date window and its own lifecycle flags, so
;;; it is an entity and not a value struct.
;;;
;;; WHAT THE LIVE TABLE ACTUALLY SAYS, measured 2026-09-19 over all 83 rows —
;;; recorded because the dod-product-pricing view class above disagrees with the
;;; DDL in three places:
;;;
;;;   * PRICE decimal(10,2) NOT NULL with NO column default. Live range 1.00 …
;;;     10000.00, zero rows at 0 or NULL. No initform: a tier without a price is
;;;     not a tier, and the database refuses it anyway.
;;;
;;;   * CURRENCY varchar(3) NULL, DDL default **'USD'** — but all 83 rows hold
;;;     'INR', and the view class claims :void-value "INR". The "INR" below is a
;;;     CLASS CHOICE that contradicts the DDL default; it matches the live data
;;;     and the rest of the platform (get-account-currency), so it is kept — but
;;;     do not read it as the schema's own default.
;;;
;;;   * ACTIVE_FLAG char(1) NULL, DDL default NULL, and the view class claims
;;;     :void-value "N" — while ALL 83 live rows are 'Y' and every reader filters
;;;     on 'Y'. Copying the view class's "N" would write tiers that are invisible
;;;     to pricing lookups while looking present in the table. "Y" is a class
;;;     choice, matching nst-vnd-shp's identical treatment of its active-flag.
;;;
;;;   * START_DATE / END_DATE are nullable `timestamp`, NOT the :type clsql:date
;;;     :NOT-NULL the view class declares — the column type is the truth. Zero
;;;     NULLs and zero reversed windows live, but the DDL allows both, so the
;;;     window rule belongs to the verbs, not to these slots.
;;;
;;;   * PRODUCT_ID is NULLABLE in the DDL (MUL index) despite the view class's
;;;     :NOT-NULL, and there is NO FOREIGN KEY constraint on this table — an
;;;     orphan product-id is accepted by MySQL and must be refused in the domain.
;;;
;;;   * CREATED / UPDATED exist on the table but are NOT mapped by the view
;;;     class, so the inherited created-at / updated-at will not round-trip
;;;     through the copiers. Flagged rather than hidden.
;;;
;;; id / tenant-id / created-at / updated-at / deleted-state are INHERITED from
;;; nst-domain-entity — they are never redeclared here.
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass nst-prd-pricing (nst-domain-entity)  ; NOT (business-object nst-domain-entity)
  (;; ROW — bound by bind-generated-row-id after the INSERT, never by a caller.
   (row-id
    :initarg :row-id
    :accessor row-id)

   ;; ── PARENT ──────────────────────────────────────────────────────────────
   ;; No initform: a tier with no product must fail loudly. This is the column
   ;; the collection law is keyed on, together with the inherited tenant-id.
   ;; FK → DOD_PRD_MASTER.ROW_ID, and the database does NOT enforce it — the
   ;; table declares no FOREIGN KEY — so the domain must refuse a product-id
   ;; that does not resolve within the session tenant.
   (product-id
    :initarg :product-id
    :accessor product-id
    :documentation "FK → DOD_PRD_MASTER.ROW_ID. UNENFORCED by the database, and
                    NULLABLE in the DDL despite :DB-CONSTRAINTS :NOT-NULL on the
                    view class — the columns are the truth.")

   ;; ── MONEY ───────────────────────────────────────────────────────────────
   (price
    :initarg :price
    :accessor price
    :documentation "decimal(10,2) NOT NULL, no column default. The tier price.
                    No initform on purpose: the DB refuses a tier without one.")

   (discount
    :initarg :discount
    :accessor discount
    :initform nil
    :documentation "decimal(5,2) nullable, DDL default 0.00. NIL —— not 0 —— is
                    the honest absence, on nst-vnd's minorderamt reasoning: a
                    discount of 0 is a real statement ('no discount'), while NIL
                    says the column was never filled. All 83 live rows carry a
                    value, so both are readable in practice.")

   (currency
    :initarg :currency
    :accessor currency
    :initform "INR"
    :documentation "varchar(3) nullable. CLASS CHOICE \"INR\" — the DDL default is
                    'USD' and the view class claims \"INR\"; all 83 live rows are
                    'INR'. Neither the class nor the view class reflects the
                    schema's own default.")

   ;; ── THE WINDOW ──────────────────────────────────────────────────────────
   ;; The date window IS the tier's meaning: the same product may carry several
   ;; tiers, and which one applies is decided by today falling inside
   ;; [start-date, end-date]. select-product-pricing-by-startdate already reads
   ;; it that way. No initforms: a window with no start or no end is not a window.
   (start-date
    :initarg :start-date
    :accessor start-date
    :documentation "timestamp, NULLABLE in the DDL — the view class's
                    :DB-CONSTRAINTS :NOT-NULL and :type clsql:date are a Lisp-side
                    claim the column does not back. Inclusive lower bound.")

   (end-date
    :initarg :end-date
    :accessor end-date
    :documentation "timestamp, NULLABLE in the DDL. Inclusive upper bound. The
                    DDL permits end-date < start-date (live data has none), so
                    that rule belongs to the verbs.")

   ;; ── STATUS ──────────────────────────────────────────────────────────────
   (active-flag
    :initarg :active-flag
    :accessor active-flag
    :initform "Y"
    :documentation "char(1), NULLABLE, NO DDL DEFAULT. The \"Y\" here is a CLASS
                    CHOICE, not a schema default — and it deliberately does NOT
                    follow the view class above, whose :void-value is \"N\".
                    All 83 live rows are 'Y' and the readers filter on 'Y', so a
                    tier written as NULL or 'N' would be invisible to pricing
                    while looking present in the table. deleted-state, tenant-id,
                    created-at and updated-at are INHERITED from
                    nst-domain-entity.")

   ;; ── TENANT — no initform on purpose: it must fail loudly when a caller
   ;; forgets it, rather than write a NULL tenant. Prefixed because `company` is
   ;; already an accessor in this package (nst-vnd-shp) and nst-prd already
   ;; solved the same clash with prd-company. NOTE this is the legacy company
   ;; JOIN slot that sits beside the inherited tenant-id.
   (prc-company
    :initarg :company
    :accessor prc-company))
  (:documentation
   "Price-tier domain entity. कर्म of the pricing verbs, and the second table
    behind the product aggregate: nst-prd holds the current price, this holds
    the dated tiers. A tier is addressable on its own row-id, so it is an entity
    — not a value struct like nst-vnd-shp's `zones`."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; nst-prd-catg — the CATEGORY entity (DOD_PRD_CATG)
;;;
;;; WHAT A CATEGORY IS, IN BUSINESS TERMS: the label a vendor files a product
;;; under, so the storefront can group listings ("Groceries", "Apparel"). Every
;;; tenant gets a "root" row it never shows and children beneath it.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; 🚨 LFT / RGT ARE A BROKEN NESTED SET — READ THIS BEFORE USING THEM
;;;
;;; The two columns look like the classic modified-preorder-tree encoding: a node
;;; spans [lft, rgt], its descendants are the rows with lft > node.lft AND
;;; rgt < node.rgt, and the root spans the whole tree. TWO THINGS ARE WRONG, and
;;; both are measured, not inferred (2026-09-19, all 18 live rows):
;;;
;;;   1. THE INTERVALS OVERLAP ACROSS TENANTS. Every tenant's root is written at
;;;      (lft 1, rgt 2) — see add-root-prdcatg, dod-bl-prd.lisp:391-393 — so the
;;;      encoding is NOT tenant-scoped. Tenant 2 spans [1,22] and tenant 5 spans
;;;      [1,2] at the same time, and a subtree query would return BOTH tenants'
;;;      rows.
;;;
;;;   2. THE ROOT DOES NOT CONTAIN ITS OWN TENANT'S ROWS. 11 of the 18 live rows
;;;      sit OUTSIDE their tenant's root interval: tenant 2's root is [1,22] but
;;;      its rows reach rgt 34, and tenant 5's root is the single-row [1,2] while
;;;      it has five children at lft 3 … 11.
;;;
;;; THE CAUSE IS IN THE MAINTENANCE SQL, and it is a cross-tenant write: the
;;; shift statements in add-new-node-prdcatg / add-new-prdcatg-node-as-child
;;; (dod-bl-prd.lisp:400-401, 418-419) read @myRight tenant-scoped but then run
;;;
;;;     UPDATE DOD_PRD_CATG SET rgt = rgt + 2 WHERE rgt > @myRight;
;;;     UPDATE DOD_PRD_CATG SET lft = lft + 2 WHERE lft > @myRight;
;;;
;;; with NO tenant_id filter — so one tenant adding a category RENUMBERS EVERY
;;; OTHER TENANT'S ROWS. delete-prd-catg (dod-bl-prd.lisp:428-438) is worse: its
;;; DELETE ... WHERE lft BETWEEN @myLeft AND @myRight is unscoped too, so it can
;;; delete another tenant's categories outright.
;;;
;;; WHAT THIS ENTITY THEREFORE DOES, AND DOES NOT: the slots exist because the
;;; columns are NOT NULL — a row cannot be inserted without them — but NOTHING in
;;; this domain may treat lft/rgt as a usable tree. In particular there is no
;;; "descendants" or "subtree" verb, and there must not be one until the encoding
;;; is repaired. Every existing category SELECTOR already ignores them
;;; (get-prod-cat, select-prdcatg-by-company, -by-id, -by-name all filter on
;;; tenant/deleted/active/name only), so the rest of the platform is flat-listed
;;; in practice. That is the honest description of the current behaviour.
;;;
;;; A SECOND HAZARD, for anyone adding a create verb: those same functions build
;;; their SQL with (format nil "… VALUES('~A', …)" name) — the category NAME is
;;; INTERPOLATED, not bound. A name containing an apostrophe breaks the statement
;;; and can inject. A create verb must bind or escape it; the existing helpers
;;; cannot be reused as-is.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHAT THE LIVE TABLE SAYS (DOD_PRD_CATG, 18 rows, tenants 2 and 5)
;;;
;;;   CATG_NAME varchar(70) NULLABLE, despite the view class's :DB-CONSTRAINTS
;;;     :NOT-NULL — the column is the truth.
;;;   lft / rgt int NOT NULL with NO DEFAULT — hence the slots below and no
;;;     initform: a category without them cannot be stored at all.
;;;   CREATED timestamp NOT NULL default CURRENT_TIMESTAMP — NOT mapped by the
;;;     dod-prd-catg view class, so the inherited created-at holds the time the
;;;     OBJECT was built, not the row's timestamp. Same defect as
;;;     DOD_PRODUCT_PRICING's CREATED/UPDATED; flagged, not papered over.
;;;   DELETED_STATE / ACTIVE_FLAG char(1) NULLABLE, no DDL default; all 18 live
;;;     rows are 'N' and 'Y' respectively, and every selector filters on exactly
;;;     those two values — so a row written with NULL would be invisible.
;;;   "root" is a REAL ROW, one per tenant, and every selector that faces a
;;;     vendor EXCLUDES it by name ([<> [:catg-name] "root"]). It is not a
;;;     sentinel and it has a row-id like any other.
;;;
;;; id / tenant-id / created-at / updated-at / deleted-state are INHERITED from
;;; nst-domain-entity — they are never redeclared here.
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass nst-prd-catg (nst-domain-entity)   ; NOT (business-object nst-domain-entity)
  (;; ROW — bound by bind-generated-row-id after the INSERT, never by a caller.
   (row-id
    :initarg :row-id
    :accessor row-id)

   ;; ── LABEL ───────────────────────────────────────────────────────────────
   (catg-name
    :initarg :catg-name
    :accessor catg-name
    :initform nil
    :documentation "varchar(70), NULLABLE in the live table (the view class's
                    :DB-CONSTRAINTS :NOT-NULL is a Lisp-side claim the column
                    does not back). The literal \"root\" is reserved: it names the
                    one hidden per-tenant row that every vendor-facing selector
                    filters out. A verb that lets a vendor create a category must
                    refuse that name, or the vendor can hide the real root from
                    the platform and adopt its identity.")

   ;; ── THE TREE ENCODING — see the header. NOT a usable tree.
   (lft
    :initarg :lft
    :accessor lft
    :documentation "int NOT NULL, no column default. Left bound of the nested-set
                    interval. 🚨 THE ENCODING IS BROKEN AND CROSS-TENANT — the
                    intervals overlap between tenants and 11 of 18 live rows fall
                    outside their own tenant's root. Carried because the column is
                    NOT NULL and the copier must round-trip it; NOT to be used for
                    traversal. See the header.")

   (rgt
    :initarg :rgt
    :accessor rgt
    :documentation "int NOT NULL, no column default. Right bound of the same
                    broken interval. Never write it by hand: the maintenance SQL
                    that shifts these columns is itself unscoped and corrupts
                    other tenants. See the header.")

   ;; ── STATUS ──────────────────────────────────────────────────────────────
   (active-flag
    :initarg :active-flag
    :accessor active-flag
    :initform "Y"
    :documentation "char(1), NULLABLE, NO DDL DEFAULT. The \"Y\" here is a CLASS
                    CHOICE matching all 18 live rows and the filter every category
                    selector applies — a row written as NULL would be invisible to
                    the storefront while looking present in the table. Deliberately
                    NOT copied from the view class, whose :void-value is \"N\".")

   ;; ── TENANT — no initform on purpose: it must fail loudly when a caller
   ;; forgets it, rather than write a NULL tenant. The view class's company slot
   ;; carries the SAME accessor (product-company) as dod-prd-master's, which is
   ;; why this one is prefixed — nst-prd solved the identical clash with
   ;; prd-company, and nst-vnd-shp with a bare `company`. NOTE this is the legacy
   ;; company JOIN slot that sits beside the inherited tenant-id.
   (catg-company
    :initarg :company
    :accessor catg-company))
  (:documentation
   "Product-category domain entity. कर्म of whatever category verbs are built on
    it: the label a vendor files a product under.

    ONE ENTITY, ONE TABLE — no aggregate is assembled on the way to the database,
    the way a product is one entity. The parent/child structure lives in the
    root's and the rows' lft/rgt columns, and 🚨 that encoding is BROKEN — see the
    header before writing any verb that reads or writes it."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Boundary models — Tree 2. The entity never crosses into Ring 4 itself;
;;; request->dispatch / domain->response are the only two crossings.
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass ProductRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object (Tree 2) for catalog operations.

    Deliberately SLOTLESS: it carries NO per-field typed slots. All inbound
    data rides in the inherited `params` slot as a transport-shaped plist, and
    the ferry's extract-domain-initargs (nst-bl-adhara.lisp) MOP-filters that
    plist against whatever initargs nst-prd actually declares — one universal
    translator, zero per-entity mapping code, so a new entity needs no change
    there.

    :row-id and the changed fields travel as plist keys in params, e.g.
    (:row-id "42" :prd-name "…"). :tenant-id and the other *reserved-initargs*
    are STRIPPED by extract-domain-initargs and are never accepted from a
    client — the tenant comes from the credential alone (नियम-1)."))

(defclass ProductResponseModel (nst-boundary-object)
  ((row-id
    :initarg :row-id
    :accessor row-id)
   (product-code
    :initarg :product-code
    :accessor product-code)
   (prd-name
    :initarg :prd-name
    :accessor prd-name)
   (description
    :initarg :description
    :accessor description)
   (vendor-id
    :initarg :vendor-id
    :accessor vendor-id)
   (catg-id
    :initarg :catg-id
    :accessor catg-id)
   (sku
    :initarg :sku
    :accessor sku)
   (hsn-code
    :initarg :hsn-code
    :accessor hsn-code)
   (prd-type
    :initarg :prd-type
    :accessor prd-type)
   (unit-of-measure
    :initarg :unit-of-measure
    :accessor unit-of-measure)
   (qty-per-unit
    :initarg :qty-per-unit
    :accessor qty-per-unit)
   (units-in-stock
    :initarg :units-in-stock
    :accessor units-in-stock)
   (prd-image-path
    :initarg :prd-image-path
    :accessor prd-image-path)
   (external-url
    :initarg :external-url
    :accessor external-url)
   (upc
    :initarg :upc
    :accessor upc)
   (ean
    :initarg :ean
    :accessor ean)
   (jan
    :initarg :jan
    :accessor jan)
   (isbn
    :initarg :isbn
    :accessor isbn)
   (serial-no
    :initarg :serial-no
    :accessor serial-no)
   (current-price
    :initarg :current-price
    :accessor current-price)
   (current-discount
    :initarg :current-discount
    :accessor current-discount)
   (active-flag
    :initarg :active-flag
    :accessor active-flag)
   (approved-flag
    :initarg :approved-flag
    :accessor approved-flag)
   (approval-status
    :initarg :approval-status
    :accessor approval-status)
   (subscribe-flag
    :initarg :subscribe-flag
    :accessor subscribe-flag)
   (shipping-length-cms
    :initarg :shipping-length-cms
    :accessor shipping-length-cms)
   (shipping-width-cms
    :initarg :shipping-width-cms
    :accessor shipping-width-cms)
   (shipping-height-cms
    :initarg :shipping-height-cms
    :accessor shipping-height-cms)
   (shipping-weight-kg
    :initarg :shipping-weight-kg
    :accessor shipping-weight-kg))
  (:documentation
   "Outbound boundary object (Tree 2) for catalog operations. Populated by
    domain->response in dod-bl-prd.lisp.

    TENANT_ID AND COMPANY ARE DELIBERATELY ABSENT. The tenant is the session's
    own अधिकरण, never something published back to a client, and the render-json
    method is the allowlist that enforces it (adhara's security contract:
    a field must be added to the render method per format before it can leak)."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Boundary models for nst-prd-pricing — Tree 2
;;;
;;; Both descend from nst-bl-adhara.lisp's boundary tree, NEVER from
;;; nst-domain-entity — that inheritance is what adhara exists to prevent.
;;;
;;; This file is the DATA SHAPE ONLY. domain->response, render-json and the
;;; copiers for these classes live with the प्रत्यय in
;;; products/nst-bl-prdpricing.lisp, exactly as VndShipResponseModel's live in
;;; nst-bl-vndshp.lisp rather than in nst-dal-vndshp.lisp.
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass ProductPricingRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object (Tree 2) for product-pricing operations.

    Deliberately SLOTLESS, like ProductRequestModel, VendorRequestModel,
    VpmRequestModel and VndShipRequestModel: it carries NO per-field typed slots.
    All inbound data rides in the inherited `params` slot as a transport-shaped
    plist, e.g. (:product-id \"42\" :price 199.00 :discount 5.00
    :start-date \"01/04/2026\" :end-date \"30/06/2026\").

    The ferry (request->dispatch / extract-domain-initargs in nst-bl-adhara.lisp)
    reads (params rm) and MOP-filters that plist against whatever initargs
    nst-prd-pricing actually declares — one universal translator, zero per-entity
    mapping code, so a new column needs no change here.

    WHY THAT MATTERS MORE HERE THAN USUALLY: the SAME request model has to serve
    the single update (PUT /catalog/products/{id}/pricing) and the BULK update
    (many rows in one request). A typed mirror would have to describe both shapes,
    and the bulk case carries a LIST of row plists under one key. Slotless means
    the ferry sees ordinary plist values either way, and it is the verbs in
    nst-bl-prdpricing.lisp that interpret their contents.

    :tenant-id, :company and the other *reserved-initargs* are STRIPPED by
    extract-domain-initargs and are never accepted from a client — the tenant
    comes from the credential alone (नियम-1). :product-id is legal here precisely
    because it is the ADDRESS of the कर्म (which product's price this is), not the
    अधिकरण; the verbs re-resolve it against the session tenant, so another
    tenant's product-id yields 404 and never data."))

(defclass ProductBulkUploadResponseModel (nst-response-model)
  ((rows
    :initarg :rows :accessor rows :initform 0)
   (applied
    :initarg :applied :accessor applied :initform 0)
   (created
    :initarg :created :accessor created :initform 0)
   (updated
    :initarg :updated :accessor updated :initform 0)
   (skipped
    :initarg :skipped :accessor skipped :initform 0)
   (problems
    :initarg :problems :accessor problems :initform nil))
  (:documentation
   "The per-row report a bulk products.csv upload answers with.

    🚨 IT DESCENDS FROM nst-response-model, NOT nst-boundary-object, AND THAT IS THE
    WHOLE TRICK. Every other response class in this file mirrors a DOMAIN ENTITY and
    is produced by a domain->response ferry. A bulk report mirrors nothing — there is
    no entity called 'an upload', the verb computes these counts as it goes — so it
    has no ferry and must not have one: action->response (conflodis2) passes an
    nst-response-model straight through, which is exactly right for a value the verb
    produced directly. Had it descended from nst-boundary-object instead, the
    dispatcher would have looked for a domain->response method matching nothing and
    answered 500.

    WHY A REPORT AT ALL, when the legacy controller returns a redirect and says
    nothing: a bulk write that answers only 200 hides which of 100 rows failed. The
    vendor has to be able to act on the result, and 'row 47' is actionable where
    'something went wrong' is not.

    All six slots are always populated — zero is a real answer, not an absent one —
    so a client never has to distinguish 'none failed' from 'the field was omitted'."
   ))

(defclass ProductPricingResponseModel (nst-boundary-object)
  ((row-id
    :initarg :row-id
    :accessor row-id)

   ;; PARENT — published deliberately, see the note below
   (product-id
    :initarg :product-id
    :accessor product-id)

   ;; MONEY
   (price
    :initarg :price
    :accessor price)
   (discount
    :initarg :discount
    :accessor discount)
   (currency
    :initarg :currency
    :accessor currency)

   ;; THE WINDOW — the period the DISCOUNT runs, not a price schedule
   (start-date
    :initarg :start-date
    :accessor start-date)
   (end-date
    :initarg :end-date
    :accessor end-date)

   ;; STATUS
   (active-flag
    :initarg :active-flag
    :accessor active-flag))
  (:documentation
   "Outbound boundary object (Tree 2) for a product's pricing row. Populated by
    domain->response in nst-bl-prdpricing.lisp.

    EIGHT DECLARED slots. 🚨 class-slots WILL REPORT NINE: the ninth is the
    inherited boundary `id` (a UUID from nst-boundary-object,
    nst-bl-adhara.lisp:76). It is NOT a published field and render-json must never
    emit it — the same trap VndShipResponseModel documents.

    `product-id` IS PUBLISHED, and the divergence from VndShipResponseModel
    (which hides its vendor-id) is deliberate rather than an oversight:

      * it is the ADDRESS the client itself supplied — the pricing row is reached
        as /catalog/products/{id}/pricing, so the field is already known to the
        caller and conceals nothing;
      * the BULK response needs it. A per-row report over many products is
        unreadable if the rows cannot say which product each one belongs to, and
        a positional answer would silently mis-attribute rows the moment the
        request order and the result order differ;
      * vendor-id is hidden there because it is the SESSION'S OWN vendor — the
        one id a client never has to be told — whereas a product-id here is one of
        many the caller owns. ProductResponseModel publishes vendorId and catgId
        for the same reason.
      Tenant scoping, not field secrecy, is what keeps another tenant's product
      out of reach (OWASP API1:2023 BOLA): every verb re-resolves product-id
      against the session company.

    DELIBERATELY ABSENT, and these ARE the security boundary:

      tenant-id          the कारक. Injected from the session, never a client
                         field, and never published back.
      prc-company        the tenant OBJECT. A boundary object has no business
                         carrying a domain entity out of Tree 1.
      created-at         database-maintained audit. Not a client field.
      updated-at         🚨 HAS NO ROUND-TRIP: DOD_PRODUCT_PRICING carries real
                         CREATED / UPDATED columns, but the dod-product-pricing
                         view class maps NEITHER — so the entity's inherited slots
                         hold the time the OBJECT was built (mysql-now), not the
                         row's timestamps. Publishing that would publish a value
                         that is not the database's, which is worse than omitting
                         it. Wiring it properly means adding the two slots to the
                         view class first.
      deleted-state      the row is either returned or it is not. A soft-delete
                         is expressed at the boundary as a 404, never as a field
                         on a 200.

    NOT A SLOT, and the reason is worth stating: there is no `windowActive` /
    `discountExpired` field. That is a fact about TODAY, not about the row, and a
    stored boolean would go stale the moment midnight passed. It is DERIVED at
    render time from start-date/end-date by the one predicate the checkout uses
    (prdpricing-window-contains-p, nst-bl-prdpricing.lisp) — the same reasoning
    nst-prd's current-price/current-discount apply to the master row.

    The reverse ferry copies dates as CLSQL date objects; converting them to the
    wire format is render-json's job, not this class's."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Boundary models for nst-prd-catg — Tree 2
;;;
;;; Both descend from nst-bl-adhara.lisp's boundary tree, NEVER from
;;; nst-domain-entity. This file is the DATA SHAPE ONLY; domain->response,
;;; render-json and the copiers belong with the प्रत्यय.
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass ProductCatgRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object (Tree 2) for product-category operations.

    Deliberately SLOTLESS, like every other request model in this tree: all
    inbound data rides in the inherited `params` slot as a transport-shaped plist,
    e.g. (:catg-name \"Groceries\" :row-id \"8\"), and the ferry's
    extract-domain-initargs MOP-filters it against whatever initargs nst-prd-catg
    declares — one universal translator, zero per-entity mapping code.

    🚨 lft / rgt TRAVEL HERE LIKE ANY OTHER INITARG, AND THAT IS NOT AN
    INVITATION TO SUPPLY THEM. nst-prd-catg declares those slots, so the MOP
    filter will pass a client-supplied :lft straight through to the entity. The
    tree encoding is broken and cross-tenant (see the entity's header) and a
    create verb must STRIP both keys, exactly as the pricing verbs strip :row-id —
    an address or an encoding is not a field of the कर्म. Until such a verb
    strips them, a caller can write arbitrary interval bounds.

    :tenant-id, :company and the other *reserved-initargs* are STRIPPED by
    extract-domain-initargs and are never accepted from a client — the tenant
    comes from the credential alone (नियम-1)."))

(defclass ProductCatgResponseModel (nst-boundary-object)
  ((row-id
    :initarg :row-id
    :accessor row-id)

   ;; LABEL
   (catg-name
    :initarg :catg-name
    :accessor catg-name)

   ;; STATUS
   (active-flag
    :initarg :active-flag
    :accessor active-flag))
  (:documentation
   "Outbound boundary object (Tree 2) for a product category. THREE declared
    slots. 🚨 class-slots WILL REPORT FOUR: the fourth is the inherited boundary
    `id` (a UUID from nst-boundary-object, nst-bl-adhara.lisp:76), which is NOT a
    published field and must never be emitted.

    🚨 THIS IS THE SMALLEST RESPONSE MODEL IN THE TREE ON PURPOSE: it is the
    ALLOWLIST, and lft/rgt ARE DELIBERATELY ABSENT. Publishing a nested-set
    interval that is already known to be corrupt and cross-tenant would hand every
    client a field it might reasonably try to navigate by — and a subtree query
    built on those numbers returns other tenants' categories. The encoding has no
    slot to be copied into, so no later edit to render-json can leak it; that is
    the structural failure-closed property the boundary models rely on.

    WHEN lft/rgt BECOME PUBLISHABLE: only after the maintenance SQL in
    dod-bl-prd.lisp:400-401 and :418-419 is tenant-scoped and the existing 18 rows
    are renumbered into a consistent per-tenant forest. Adding the slots before
    then would advertise a coordinate system the data does not honour.

    DELIBERATELY ABSENT for the usual reasons:

      tenant-id     the कारक. Injected from the session; never client-addressable
                    and never published back.
      catg-company  the tenant OBJECT. A boundary object has no business carrying
                    a domain entity out of Tree 1.
      created-at    database-maintained audit — and on THIS table it has no
                    round-trip either: DOD_PRD_CATG.CREATED is NOT mapped by the
                    dod-prd-catg view class, so the inherited slot holds the time
                    the object was built, not the row's timestamp. Wiring it means
                    adding the slot to the view class first.
      updated-at    has NO COLUMN behind it at all on DOD_PRD_CATG.
      deleted-state the row is either returned or it is not. A soft-delete is
                    expressed at the boundary as a 404, never as a field on a 200.

    There is also NO parentId field, and that is a consequence of the same
    defect rather than a preference: the parent is knowable only from the
    interval encoding, so a parentId computed today would sometimes name another
    tenant's category or the wrong node."))


