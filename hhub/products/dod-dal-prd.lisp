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


;;;;;;;;;;;; PRODUCT GST ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(clsql:def-view-class dod-product-gst ()
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

   (cgstrate
    :initarg :cgstrate
    :type float
    :accessor cgstrate)
   (sgstrate
    :initarg :sgstrate
    :type float
    :accessor sgstrate)
   (igst
    :initarg :igstrate
    :type float
    :accessor igstrate)
   (compcess
    :initarg :compcess
    :accessor compcess)

   
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

;;;;;;;;;;;;; END PRODUCT GST TABLE ;;;;;;;;;;;;;;;;;;;;;;;;;

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


