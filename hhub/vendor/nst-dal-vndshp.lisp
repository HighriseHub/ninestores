;;; nst-dal-vndshp.lisp — Vendor shipping domain class + boundary models
;;; (nst-vnd-shp)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; 🚨 NOT YET COMPILED, NOT YET RUN. Wired into nstores.asd and
;;; package/compile.lisp above nst-bl-vndshp. Per the standing rule of this
;;; project — with its two recorded proofs, a copier that compiled with ten
;;; warnings and would have failed on the first fetch, and a helper named `safe`
;;; that executes arbitrary code — compile-time success is NOT evidence. Call the
;;; प्रत्यय before trusting any of this.
;;;
;;; WHY A NEW FILE, AND NOT shipping/dod-dal-osh.lisp. That file is LIVE LEGACY,
;;; not dead weight: shipping/dod-bl-osh.lisp reads both of its view-classes on
;;; the CUSTOMER CHECKOUT path (get-shipping-method-for-vendor,
;;; get-ship-zones-for-vendor → dod-ui-cus.lisp get-shipping-rate), and
;;; vendor/dod-ui-ven.lisp writes them from the vendor's shipping-settings page.
;;; It already holds a legacy CLSQL view-class per table plus a BusinessObject
;;; subclass (ShippingRateCheck, OrderShipment) on the same package. Adding the
;;; new architecture there would give ONE TABLE two entity implementations and
;;; two more boundary models in one file — the divergence nst-dal-vnd.lisp:7-10
;;; records as the reason products/ is the cautionary example. This file holds
;;; ONLY the new architecture and leaves the legacy chain untouched and working.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; nst-vnd-shp — the vendor shipping domain entity
;;;
;;; ONE ENTITY, TWO TABLES. This is the design decision this file exists to
;;; state, so it is stated first:
;;;
;;;   DOD_SHIPPING_METHODS    the vendor's shipping CONFIGURATION. 0-or-1 row per
;;;                           vendor. This is the MAIN table: the entity's
;;;                           identity, its lifecycle and its address are all the
;;;                           config row's.
;;;   DOD_VENDOR_SHIP_ZONES   the vendor's ZONES — a COLLECTION, 0..N rows, but
;;;                           only meaningful for ONE shipping method
;;;                           (defaultshippingmethod = "TRS", zonewise shipping,
;;;                           tablerateshipenabled = "Y").
;;;
;;; They are NOT two entities, and the reason is not convenience. A zone row has
;;; no life of its own: it is not addressable by a client, it is never read
;;; alone, and its only meaning is as a COLUMN of the RATETABLECSV price matrix
;;; that lives on the methods row (see THE ZONEWISE LINK below). Splitting them
;;; would create a second entity whose every verb would have to re-derive the
;;; first one's identity, and would let a caller create a zone for a vendor that
;;; has no shipping configuration at all — a state the checkout cannot read.
;;; So the zones ride INSIDE this entity as a collection slot, `zones`, holding
;;; VALUE objects (`ship-zone` structs below), not domain entities.
;;;
;;; Same shape as nst-vnd-vpm (vendor/nst-dal-vndvpm.lisp): a CHILD entity, so
;;; its identity is (VENDOR-ID, TENANT) — the parent link is part of the key —
;;; and it is a 0-or-1 SINGLETON per vendor.
;;;
;;; THE SINGLETON IS A DOMAIN LAW, NOT A SCHEMA FACT. DOD_SHIPPING_METHODS has
;;; only a PRIMARY KEY on ROW_ID plus plain NON-UNIQUE indexes on TENANT_ID and
;;; VENDOR_ID (verified by SHOW COLUMNS + SHOW INDEX, 2026-09-16). MySQL will
;;; accept six shipping rows for one vendor without complaint, and the live
;;; reader takes the FIRST row with NO ORDER BY at all
;;; (get-shipping-method-for-vendor, shipping/dod-bl-osh.lisp:11-19, ends in
;;; `(car (clsql:select …))`). A duplicate would not raise — it would silently
;;; change the price the next customer is charged, and which price depends on
;;; the planner. ?exists and make's :around are the only things standing between
;;; a vendor and that. NOTE this is WORSE than the vpm twin, whose reader at
;;; least orders by ROW_ID DESC; here there is no tie-breaker to inherit.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THE ZONEWISE LINK — the most valuable law this surface can add
;;;
;;; RATETABLECSV is a CSV price matrix whose COLUMN HEADERS ARE ZONE NAMES:
;;;
;;;   MIN,MAX,ZONE-A,ZONE-B,ZONE-C,ZONE-D,ZONE-E
;;;   0.5,1,40,80,150,170,0
;;;
;;; and the price actually charged is picked by matching the customer's pincode
;;; against DOD_VENDOR_SHIP_ZONES.ZIPCODERANGECSV to learn a ZONENAME, then
;;; indexing the matrix by that name
;;; (get-shipping-rate-from-table + get-zonename-from-pincode,
;;; shipping/dod-bl-osh.lisp:65-88 and :118-142).
;;;
;;; NOTHING IN THE SCHEMA LINKS THE TWO. Renaming or deleting a zone row leaves
;;; the matrix pointing at a column that no longer exists, and the checkout then
;;; charges 0.00 or the wrong band with no error anywhere — the `cond` at
;;; dod-bl-osh.lisp:82-86 simply falls through to NIL. This file does not
;;; enforce that link (the verbs do); it exists to say where it belongs and why
;;; the two tables are one entity.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; INITFORMS MIRROR THE LIVE TABLE (verified by SHOW COLUMNS FROM
;;; DOD_SHIPPING_METHODS and DOD_VENDOR_SHIP_ZONES, 2026-09-16, MySQL 8.0.46,
;;; sql_mode includes STRICT_TRANS_TABLES). NOT installation/hhubplatform.sql,
;;; and NOT shipping/dod-dal-osh.lisp's view-classes — which declare roles the
;;; live table does not (see DECISIONS).
;;;
;;; NIL means "column is nullable": the value may legitimately be absent.
;;; row-id and vendor-id keep NO initform on purpose — row-id is bound by
;;; bind-generated-row-id after the INSERT, and vendor-id must fail loudly when
;;; a caller forgets the parent, because a shipping row with no vendor is
;;; meaningless. Same rule as nst-vnd's `company` and nst-vnd-vpm's `vendor-id`.
;;;
;;; DECISIONS — each a deliberate divergence, recorded so it is not re-derived:
;;;
;;; 1. EVERY METHOD FLAG DEFAULTS TO "N" — a CLASS CHOICE, not a schema default.
;;;    The DDL default for all five is NULL. The legacy view-class declares NO
;;;    :void-value for them either, so a stored NULL reads back as CL NIL, and
;;;    every legacy reader treats that as OFF (`(when freeshipenabled …)`,
;;;    dod-bl-osh.lisp:48-61, :91-94). "N" is therefore the SAME MEANING made
;;;    explicit: it writes a value rather than an absence, so the column can be
;;;    read by a plain SQL grep, and it cannot become the vpm twin's trap — a
;;;    NULL that a later :void-value turns back into "Y" and silently enables.
;;;    A brand-new configuration enables NOTHING until the vendor chooses; the
;;;    legacy path's free-shipping row is created by a different, explicit call
;;;    (persist-free-shipping-method, dod-bl-osh.lisp:22-38), not by this class.
;;;
;;; 2. defaultshippingmethod KEEPS NIL. It is the one column here that is
;;;    genuinely NULL on live data — row 5 of 6 has no default method chosen —
;;;    and "no method chosen yet" is a real state of a freshly created config,
;;;    not an absence to paper over. The vocabulary is FSH (free) | FRS (flat
;;;    rate) | TRS (zonewise) | EXS (external partner), read off
;;;    dod-ui-ven.lisp:2085-2121.
;;;
;;; 3. FLATRATETYPE KEEPS THE DDL DEFAULT "ORD" — the ONLY real column default
;;;    among the flags here ('ORD' per SHOW COLUMNS; all six live rows hold
;;;    'ORD'). ORD charges FLATRATEPRICE once per ORDER, ITM once per LINE ITEM
;;;    (dod-ui-cus.lisp:2922). A caller that omits it gets ORD, which is what the
;;;    entire live table holds.
;;;
;;; 4. NAME IS PREFIXED shp-name. DOD_SHIPPING_METHODS.NAME is varchar(70),
;;;    NULLABLE, and NULL on ALL SIX live rows — but the plain name `name` is
;;;    already an accessor in the shared :nstores package (dod-shipping-methods
;;;    itself declares `:accessor name`, dod-dal-osh.lisp:87). Per the rule
;;;    nst-bl-vndapi-CONTEXT §6.12 records, the slot is prefixed where the plain
;;;    name would collide, and left plain where it would not (minorderamt,
;;;    flatratetype, flatrateprice, ratetablecsv, shippartnerkey, the five flags).
;;;    `active-flag`
;;;    stays PLAIN, as it does on nst-vnd and nst-vnd-vpm, because it is the same
;;;    column with the same meaning everywhere in this tree.
;;;
;;; 5. CREATED HAS NO SLOT on either table — it is served by the INHERITED
;;;    created-at and the database maintains it. NEITHER TABLE HAS AN UPDATED
;;;    COLUMN AT ALL, so the inherited updated-at has no column behind it: it is
;;;    a domain-layer timestamp only and a copier must NOT try to write it. Same
;;;    trap nst-dal-vndvpm.lisp DECISION 4 records.
;;;
;;; 6. shippartnerkey AND shippartnersecret ARE SECRETS. They exist on the class
;;;    because the vendor's shipping-settings form writes them
;;;    (dod-ui-ven.lisp:2154-2160) and the INSERT needs them, and they are
;;;    ABSENT from VndShipResponseModel below — the same structural exclusion
;;;    VendorResponseModel uses for its four credentials.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; 🚨 RATETABLECSV IS A DESERIALISATION HAZARD, AND THIS ENTITY WRITES IT
;;;
;;; RATETABLECSV is read back with `read-from-string` at SEVEN sites
;;; (shipping/dod-bl-osh.lisp:74-80) with the default `*read-eval*` of T, so a
;;; CSV cell containing `#.(...)` EXECUTES in this image on the next customer
;;; checkout. The zone column's twin was fixed in commit 5ba1f70; THE RATE
;;; TABLE'S IS STILL OPEN (STATUS.md BLOCKER 1). That is why STATUS.md says to
;;; fix the sweep BEFORE building shipping, and it is still true: the `make` and
;;; `!update` verbs in nst-bl-vndshp.lisp write the column this bug reads. This
;;; class stores the string faithfully and validates nothing about its syntax;
;;; the reader, not the writer, is where the fix belongs.
;;; ═══════════════════════════════════════════════════════════════════════════

(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════════
;;; ship-zone — the VALUE object carried in the entity's `zones` slot
;;;
;;; A STRUCT, NOT AN nst-domain-entity, and that is load-bearing. A zone is not
;;; an entity: it has no verbs of its own, is never addressed by a client, and
;;; is never read except together with the configuration it belongs to. Making it
;;; a second entity would put a second row-identity and a second ?exists on a
;;; table the checkout never queries alone.
;;;
;;; It is also not the CLSQL view-class dod-vendor-ship-zones: the domain layer
;;; does not carry view objects, and the copiers translate between them.
;;;
;;; THE CONC-NAME IS NOT COSMETIC. `zonename` and `created` are already ACCESSOR
;;; GENERIC FUNCTIONS in this package (the view-classes declare them,
;;; dod-dal-osh.lisp:189 and :212), so a defstruct accessor of the same name
;;; would either collide or — worse, since clsql accessors are generic functions
;;; and structure accessors are not — replace a live accessor with an ordinary
;;; function and break the legacy readers on the checkout path. Every accessor
;;; here is therefore prefixed: ship-zone-zonename, ship-zone-zipcoderangecsv,
;;; ship-zone-row-id, ship-zone-active-flag.
;;;
;;; :ROW-ID IS CARRIED BECAUSE AN EXISTING ZONE MUST BE ADDRESSABLE FOR A
;;; RE-WRITE. The zone is created once and then edited in place by
;;; update-vendor-shipzone; an entity hydrated without the row-id could only be
;;; re-INSERTED, which would violate the singleton-per-name law this API adds.
;;;
;;; :ACTIVE-FLAG IS NOT CARRIED. DOD_VENDOR_SHIP_ZONES.ACTIVE_FLAG is nullable
;;; with NO column default and the view-class maps a NULL to :void-value "Y", so
;;; the only rows this entity ever hydrates are the ones the readers already
;;; filter to active_flag='Y' + deleted_state='N' — carrying a flag that is
;;; always "Y" by construction would be a field with one legal value. Zones are
;;; removed by deleting the row or by removing the zone from this collection,
;;; never by a flag edit.
;;; ═══════════════════════════════════════════════════════════════════════════

(defstruct (ship-zone
            (:conc-name ship-zone-)
            (:constructor make-ship-zone (row-id zonename zipcoderangecsv)))
  (row-id nil)
  (zonename nil)
  (zipcoderangecsv nil))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; nst-vnd-shp
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass nst-vnd-shp (nst-domain-entity)   ; NOT (business-object nst-domain-entity)
  (;; ROW — bound by bind-generated-row-id after the INSERT, never by a caller.
   (row-id
    :initarg :row-id
    :accessor row-id)

   ;; ── PARENT ──────────────────────────────────────────────────────────────
   ;; No initform: a child row with no parent must fail loudly. This is the
   ;; column the singleton law is keyed on, together with the inherited tenant-id.
   ;; It is a FK to DOD_VEND_PROFILE.ROW_ID and the database does NOT enforce the
   ;; reference — DOD_SHIPPING_METHODS declares no FOREIGN KEY constraint — so an
   ;; orphan vendor-id is accepted by MySQL and must be refused in the domain.
   (vendor-id
    :initarg :vendor-id
    :accessor vendor-id
    :documentation "FK → DOD_VEND_PROFILE.ROW_ID. UNENFORCED by the database —
                    no FOREIGN KEY constraint exists on either table, so the
                    domain must refuse a vendor-id that does not resolve within
                    the session tenant.")

   ;; ── LABEL ───────────────────────────────────────────────────────────────
   (shp-name
    :initarg :shp-name
    :accessor shp-name
    :initform nil
    :documentation "NAME varchar(70), nullable, and NULL on ALL SIX live rows —
                    a label column the UI never filled in. Prefixed because the
                    plain `name` is already an accessor in this package
                    (DECISION 4).")

   ;; ── METHOD ENABLES ──────────────────────────────────────────────────────
   ;; The five flags are the shipping methods a vendor may offer; the default
   ;; one is selected separately by defaultshippingmethod below. Each initform is
   ;; a CLASS CHOICE — the DDL default for all five is NULL (DECISION 1).
   (freeshipenabled
    :initarg :freeshipenabled
    :accessor freeshipenabled
    :initform "N"
    :documentation "FREE shipping. char(1) nullable, DDL default NULL, class
                    choice \"N\" (DECISION 1). Read with its threshold:
                    MINORDERAMT is charged only when this is on
                    (getminorderamt, dod-bl-osh.lisp:91-94). All six live rows
                    have it 'Y'.")

   (flatrateshipenabled
    :initarg :flatrateshipenabled
    :accessor flatrateshipenabled
    :initform "N"
    :documentation "Flat-rate shipping. class choice \"N\" (DECISION 1). Row 4
                    of the live table is 'Y'; rows 2 and 3 are 'N'; row 5 is
                    NULL, which the readers treat as off.")

   (tablerateshipenabled
    :initarg :tablerateshipenabled
    :accessor tablerateshipenabled
    :initform "N"
    :documentation "ZONEWISE shipping — the method the `zones` slot belongs to.
                    class choice \"N\" (DECISION 1). When this is \"Y\" the
                    RATETABLECSV matrix is read and the customer's pincode is
                    matched against the zone rows (dod-bl-osh.lisp:65-88).")

   (extshipenabled
    :initarg :extshipenabled
    :accessor extshipenabled
    :initform "N"
    :documentation "External shipping partner. class choice \"N\" (DECISION 1).
                    Gates the partner credentials below, which are SECRETS.")

   (storepickupenabled
    :initarg :storepickupenabled
    :accessor storepickupenabled
    :initform "N"
    :documentation "Store pickup. class choice \"N\" (DECISION 1). The one flag
                    here that is orthogonal to the four methods: it is not a
                    value of defaultshippingmethod.")

   ;; ── MONEY ───────────────────────────────────────────────────────────────
   (minorderamt
    :initarg :minorderamt
    :accessor minorderamt
    :initform nil
    :documentation "decimal(7,2), nullable. The FREE-shipping threshold: read
                    only when freeshipenabled is on. NIL —— not 0 —— is the
                    honest absence, matching nst-vnd's invoice-settings
                    reasoning: a threshold of 0 would mean free shipping for
                    every order, which the column never intended.")

   (flatratetype
    :initarg :flatratetype
    :accessor flatratetype
    :initform "ORD"
    :documentation "char(3), DDL default 'ORD' — the only real column default
                    among these flags (DECISION 3). Values: ORD (once per ORDER)
                    | ITM (once per LINE ITEM). All six live rows hold 'ORD'.")

   (flatrateprice
    :initarg :flatrateprice
    :accessor flatrateprice
    :initform nil
    :documentation "decimal(7,2), nullable. Read only when flatrateshipenabled is
                    on (getflatrateprice, dod-bl-osh.lisp:53-56).")

   (ratetablecsv
    :initarg :ratetablecsv
    :accessor ratetablecsv
    :initform nil
    :documentation "varchar(500), nullable — the zonewise price matrix, a CSV
                    whose COLUMN HEADERS ARE ZONE NAMES (see THE ZONEWISE LINK
                    above and the READ-EVAL WARNING in the file header). Read
                    only when tablerateshipenabled is on. Stored here as the raw
                    string; the domain does not parse it.")

   ;; ── DEFAULT METHOD ──────────────────────────────────────────────────────
   (defaultshippingmethod
    :initarg :defaultshippingmethod
    :accessor defaultshippingmethod
    :initform nil
    :documentation "char(3), nullable, and NULL on 1 of the 6 live rows — NIL is
                    kept (DECISION 2). Vocabulary: FSH (free) | FRS (flat rate)
                    | TRS (zonewise) | EXS (external partner), read off
                    dod-ui-ven.lisp:2085-2121. The legacy controller sets this
                    flag AND the matching enable flag together, so the two are
                    meant to agree; that invariant belongs to the verbs, not to
                    this slot.")

   ;; ── EXTERNAL PARTNER — SECRETS ──────────────────────────────────────────
   ;; On the entity because the INSERT needs them and the vendor's own settings
   ;; form writes them; ABSENT from VndShipResponseModel below.
   (shippartnerkey
    :initarg :shippartnerkey
    :accessor shippartnerkey
    :initform nil
    :documentation "varchar(50), nullable; a SECRET — excluded from
                    VndShipResponseModel. Live value on row 2 only.")

   (shippartnersecret
    :initarg :shippartnersecret
    :accessor shippartnersecret
    :initform nil
    :documentation "varchar(50), nullable; a SECRET — excluded from
                    VndShipResponseModel. Live value on row 2 only.")

   ;; ── STATUS ──────────────────────────────────────────────────────────────
   (active-flag
    :initarg :active-flag
    :accessor active-flag
    :initform "Y"
    :documentation "char(1), NULLABLE WITH NO DDL DEFAULT. The \"Y\" here is a
                    CLASS CHOICE, not a schema default. It matches ALL SIX live
                    rows and it is what every reader filters on —
                    get-shipping-method-for-vendor and get-ship-zones-for-vendor
                    both require deleted_state='N' AND active_flag='Y'
                    (dod-bl-osh.lisp:14-19, :110-115) — so a new row written
                    with NULL would be INVISIBLE to the checkout while looking
                    perfectly present in the table. deleted-state, tenant-id,
                    created-at and updated-at are INHERITED from
                    nst-domain-entity (DECISION 5).")

   ;; ── THE COLLECTION — the second table ───────────────────────────────────
   (zones
    :initarg :zones
    :accessor zones
    :initform nil
    :documentation "A LIST of ship-zone VALUE STRUCTS — the DOD_VENDOR_SHIP_ZONES
                    rows belonging to this vendor, translated by the copiers.
                    NIL and the empty list both mean 'this vendor has no zones',
                    which is the correct state for every shipping method except
                    zonewise shipping.

                    WHY A SLOT AND NOT A SECOND ENTITY: see ONE ENTITY, TWO
                    TABLES in the file header. The zones are not addressable
                    on their own and have no meaning without this configuration.

                    WHY NIL IS A LEGAL VALUE HERE, unlike the CLSQL list-valued
                    :db-kind :list slots elsewhere in this tree: this slot is
                    NEVER written by a copier as a column. DOD_SHIPPING_METHODS
                    has no zones column; the zone rows are written one by one
                    against DOD_VENDOR_SHIP_ZONES, and the verbs own that. A
                    copier that tried to write this slot through would be
                    inventing a column.")

   ;; ── TENANT — no initform on purpose: it must fail loudly if a caller
   ;; forgets it (the API injects the session company; the web form passes it).
   (company
    :initarg :company
    :accessor company
    :documentation "The company OBJECT; TENANT_ID on both tables is its row-id.
                    Same shape and same reasoning as nst-vnd's company slot
                    (nst-bl-vnd.lisp decision 1) and nst-vnd-vpm's: the object is
                    what a copier reads row-id from, and what the ferry must not
                    be allowed to override from a request body."))

  (:documentation
   "Vendor shipping configuration — and, for zonewise shipping, the zones it
    prices against. ONE entity over TWO tables: DOD_SHIPPING_METHODS (the main
    row, holding this entity's identity and lifecycle) and DOD_VENDOR_SHIP_ZONES
    (the `zones` collection).

    A CHILD entity: identity is (VENDOR-ID, TENANT), and it is a 0-or-1
    SINGLETON per vendor. THE SINGLETON IS A DOMAIN LAW — no unique key enforces
    it and the live reader has no ORDER BY, so a duplicate silently changes the
    shipping price. See the file header.

    TWO SECRETS LIVE HERE — shippartnerkey and shippartnersecret — and they are
    the reason the response model below is a security boundary rather than a
    convenience: render-json publishes every slot of VndShipResponseModel, so a
    field with no slot cannot reach the wire.

    Live data (2026-09-16): 6 rows in DOD_SHIPPING_METHODS, held by vendors 1, 3
    (tenant 2) and 17, 18 (tenant 5); 20 rows in DOD_VENDOR_SHIP_ZONES across
    vendors 1, 17, 3 and 18. NOT every vendor has both — vendor 18 has zones and
    a method row whose flags are mostly NULL, and the readers' active_flag='Y'
    filter is what decides which of these the checkout ever sees.

    THE CLASS DEFAULT FOR EACH COLUMN IS THE DDL DEFAULT WHERE ONE EXISTS, and a
    documented CLASS CHOICE where the column is nullable with no default. Add a
    new column here WITH its DDL default, or this class drifts from the schema —
    which is what happened to the two view-classes this file deliberately does
    not extend."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; Boundary models
;;;
;;; Both descend from nst-bl-adhara.lisp's boundary tree, NEVER from
;;; nst-domain-entity — that inheritance is what adhara exists to prevent.
;;; ═══════════════════════════════════════════════════════════════════════════

(defclass VndShipRequestModel (nst-request-model)
  ()
  (:documentation
   "Inbound boundary object for vendor shipping operations.

    Deliberately SLOTLESS, exactly like VendorRequestModel and VpmRequestModel:
    it carries NO per-field typed slots. All inbound data rides in the inherited
    `params` slot as a transport-shaped plist, e.g.
    (:vendor-id 1 :tablerateshipenabled \"Y\" :zones ((:zonename \"ZONE-A\"
    :zipcoderangecsv \"(56 57 58 59)\"))).

    The ferry (request->dispatch / extract-domain-initargs in nst-bl-adhara.lisp)
    reads (params rm) and MOP-filters that plist against whatever initargs
    nst-vnd-shp actually declares — one universal translator, zero per-entity
    mapping code. :zones travels as an ORDINARY plist value on that key, so the
    zones need no special case in the ferry: it is one initarg like any other,
    and it is the verbs in nst-bl-vndshp.lisp that interpret its contents.

    Registered as the :request-class of every shipping action route, so it must
    stay slotless: a typed mirror here would be a SECOND place the field list is
    written down, and the two would drift the first time a column is added.

    :tenant-id and audit keys are stripped by extract-domain-initargs and never
    accepted from a client."))

(defclass VndShipResponseModel (nst-boundary-object)
  ((row-id
    :initarg :row-id
    :accessor row-id)

   ;; LABEL
   (shp-name
    :initarg :shp-name
    :accessor shp-name)

   ;; METHOD ENABLES
   (freeshipenabled
    :initarg :freeshipenabled
    :accessor freeshipenabled)
   (flatrateshipenabled
    :initarg :flatrateshipenabled
    :accessor flatrateshipenabled)
   (tablerateshipenabled
    :initarg :tablerateshipenabled
    :accessor tablerateshipenabled)
   (extshipenabled
    :initarg :extshipenabled
    :accessor extshipenabled)
   (storepickupenabled
    :initarg :storepickupenabled
    :accessor storepickupenabled)

   ;; MONEY
   (minorderamt
    :initarg :minorderamt
    :accessor minorderamt)
   (flatratetype
    :initarg :flatratetype
    :accessor flatratetype)
   (flatrateprice
    :initarg :flatrateprice
    :accessor flatrateprice)
   (ratetablecsv
    :initarg :ratetablecsv
    :accessor ratetablecsv)

   ;; DEFAULT METHOD
   (defaultshippingmethod
    :initarg :defaultshippingmethod
    :accessor defaultshippingmethod)

   ;; THE COLLECTION
   (zones
    :initarg :zones
    :accessor zones)

   ;; STATUS
   (active-flag
    :initarg :active-flag
    :accessor active-flag))

  (:documentation
   "Outbound boundary object for the vendor shipping configuration.
    FOURTEEN DECLARED slots, of which one — `zones` — is the nested collection.

    🚨 class-slots WILL REPORT FIFTEEN. The fifteenth is the inherited boundary
    `id` (a UUID from nst-boundary-object, nst-bl-adhara.lisp:76). It is NOT a
    published field and render-json must never emit it — the same shape as
    VendorResponseModel and VpmResponseModel. Counting :initarg forms is the
    reliable way to count declared slots: a naive \"^   (name\" grep undercounts,
    because `id` and `((row-id` sit on DOUBLE-PAREN lines
    (nst-bl-vndapi-CONTEXT.md §10 step 0).

    🚨 `zones` HOLDS ship-zone VALUE STRUCTS, NOT a second boundary class. A
    struct is a VALUE, not a domain entity, so no entity crosses the boundary —
    and a mirrored boundary zone class would be a second place the zone field
    list is written down, drifting the first time a column is added, which is the
    same objection the slotless request model above answers. render-json converts
    each struct to an alist; nothing else may serialise them.

    render-json publishes EVERY DECLARED slot of a response model, so the field
    list is the security boundary and the exclusion is STRUCTURAL — a field not
    declared here has no slot for domain->response to copy into, and therefore
    cannot reach the wire by accident. That is why there is no reflective default
    method: a missing render-json method signals no-applicable-method, which
    FAILS CLOSED; a reflective default would publish whatever was added next,
    which fails OPEN.

    DELIBERATELY ABSENT, and this one IS a security boundary:

      shippartnerkey     ┐ the external shipping partner's credentials. They
      shippartnersecret  ┘ gate extshipenabled and are worth exactly what a
                           payment key is worth: whoever holds them can book
                           shipments on this vendor's account. They have no slot
                           to be copied into, so no later edit to render-json can
                           leak them.
      vendor-id          the parent link. Publishing it would invite a client to
                         believe it can address another vendor's configuration,
                         which is the intra-tenant BOLA the actor slot
                         (CONTEXT §12.3 decision 3) exists to close, and it is
                         the field !update REFUSES for exactly that reason.
      tenant-id          the कारक. Automatically injected from the session; never
                         a client field, and never client-addressable.
      company            the tenant OBJECT. A boundary object has no business
                         carrying a domain entity out of Tree 1.
      created-at         database-maintained audit. Not a client field.
      updated-at         has NO COLUMN behind it on EITHER table (DECISION 5),
                         so publishing it would publish a value that goes
                         nowhere.
      deleted-state      the row is either returned or it is not. A soft-delete
                         is expressed at the boundary as a 404, never as a field
                         on a 200.

    domain->response, render-json and the copiers for this class live with the
    प्रत्यय in nst-bl-vndshp.lisp, NOT here — this file is the data shape only."))
