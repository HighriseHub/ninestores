;;; nst-bl-prdpricing.lisp — Tier-1 प्रत्यय for nst-prd-pricing
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; 🚨 NOT YET COMPILED, NOT YET RUN. Per this project's standing rule — with its
;;; two recorded proofs, a copier that compiled with ten warnings and would have
;;; failed on the first fetch, and a helper named `safe` that executes arbitrary
;;; code — compile-time success is NOT evidence. Call the प्रत्यय before trusting
;;; any of this.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHAT THIS ENTITY IS, IN BUSINESS TERMS
;;;
;;; A vendor says two things about a product's price:
;;;
;;;   1. WHAT IT COSTS — PRICE, decimal(10,2), NOT NULL, no column default.
;;;
;;;   2. WHAT IS OFF IT, AND FOR HOW LONG — DISCOUNT (a PERCENTAGE, see below)
;;;      together with the window DiscountStart … DiscountEnd during which that
;;;      discount runs. OUTSIDE THE WINDOW THE DISCOUNT IS EXPIRED, not zero:
;;;      the checkout already reads it that way —
;;;
;;;        (discountexpired-p (if product-pricing
;;;                              (not (and (clsql:date>= today-date start-date)
;;;                                        (clsql:date<= today-date end-date)))))
;;;        — vendor/dod-ui-ven.lisp:560
;;;
;;;      So THE WINDOW IS THE DISCOUNT'S VALIDITY PERIOD, NOT A TIER SCHEDULE.
;;;      This reading is what makes the rest of the design fall out; see THE
;;;      SINGLETON LAW below.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THREE FACTS ABOUT THE LIVE DATA (measured 2026-09-19, all 83 rows)
;;;
;;;   1. ONE ROW PER PRODUCT. 83 rows across 83 DISTINCT PRODUCT_IDs — ZERO
;;;      products carry more than one pricing row. DOD_PRODUCT_PRICING is shaped
;;;      like a schedule, but nothing in this platform has ever written a second
;;;      row for a product: create-product writes exactly one (with a 90-day
;;;      window, dod-bl-prd.lisp:318) and the CSV round-trip updates that row.
;;;
;;;   2. DISCOUNT IS A PERCENTAGE. All 83 rows sit in 0.00 … 10.00 on a
;;;      decimal(5,2) column, against prices of 1.00 … 10000.00. It is evaluated
;;;      as a percentage off, NOT a rupee amount — so its honest domain is 0–100
;;;      and the VALUE must never be compared against PRICE.
;;;
;;;   3. NO FOREIGN KEY EXISTS on PRODUCT_ID (and the column is NULLABLE, despite
;;;      the view class's :DB-CONSTRAINTS :NOT-NULL). MySQL accepts an orphan
;;;      pricing row happily; only this file can refuse one. There are no orphans
;;;      today, which is luck, not enforcement.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THE SINGLETON LAW — (PRODUCT-ID, TENANT-ID) IS THIS ENTITY'S IDENTITY
;;;
;;; nst-prd-pricing is a SINGLETON PER PRODUCT, exactly as nst-vnd-shp is a
;;; singleton per vendor, and the reasoning is the same one recorded there:
;;;
;;;   * the parent is the only usable ADDRESS. A client has no way to LEARN a
;;;     tier row-id — there is no addressable collection in the UI, the CSV
;;;     template keys on ProductID, and the published API path is
;;;     /catalog/products/{id}/pricing. So fetch/!update/delete! take the
;;;     PRODUCT row-id, NOT a pricing row-id. THE ROW-ID IS STILL ON THE ENTITY
;;;     (it is the primary key and the copier needs it) — it is simply never the
;;;     address a caller supplies.
;;;
;;;   * THE DATE WINDOW CANNOT DISAMBIGUATE TWO ROWS. If a product carried two
;;;     pricing rows there would be no rule for which price a cart pays, and no
;;;     column that decides it: select-product-pricing-by-product-id takes the
;;;     CAR, so a second row would be silently ignored rather than honoured.
;;;     A second row is therefore not "more data", it is a coin flip.
;;;
;;;   * THE MASTER ROW HOLDS EXACTLY ONE PRICE. DOD_PRD_MASTER.CURRENT_PRICE is
;;;     a single decimal — the platform's own aggregate cannot represent two
;;;     active prices for one product. See THE DENORMALISATION LAW below.
;;;
;;; So make carries an :around singleton check and refuses a second live row.
;;; If price SCHEDULING is ever wanted, it is a new feature with its own
;;; disambiguation rule — it is not this entity loosened.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THE DENORMALISATION LAW — the master row is a CACHE, this row is the TRUTH
;;;
;;; The price is stored TWICE: here, and on DOD_PRD_MASTER as
;;; CURRENT_PRICE / CURRENT_DISCOUNT. That duplication is deliberate — the
;;; product master carries it FOR CART-CALCULATION EFFICIENCY, so the catalogue
;;; list, the min-price/max-price filter, the whitelisted :current-price sort and
;;; the cart total do not each have to join this table.
;;;
;;; THE CONSEQUENCE, stated honestly: THE CACHE IS ALREADY WRONG IN PLACE.
;;; Measured 2026-09-19, master vs this table —
;;;
;;;     agree on price AND discount   68
;;;     DISAGREE on both              15
;;;     live products with NO pricing row at all  11
;;;
;;; It drifted because two writers disagree about it: the CSV round-trip writes
;;; BOTH rows (create-bulk-products, dod-bl-prd.lisp:292-306), while
;;; create-product writes the real price HERE and 1.00 to the master
;;; (dod-bl-prd.lisp:265, 318).
;;;
;;; THE DECISION TAKEN HERE: THIS TABLE IS THE SOURCE OF TRUTH; the master columns
;;; are a cache that must be maintained. ONE function writes that cache —
;;; prdpricing-sync-product-cache (SECTION 3b) — and it is called by BOTH entity
;;; pratyayas that change a price (make, !update), so no caller can change the
;;; price here and leave the product row behind. set-product-pricing adds the
;;; create-or-update decision and wraps the pair in ONE transaction.
;;;
;;; HONEST ABOUT THE COST: syncing inside make/!update means those verbs write
;;; two rows, so they are no longer strictly single-कर्म (Guardrail 2). The
;;; justification is that the product row's price is not a second opinion — it is
;;; a CACHE OF THIS ROW — so keeping it in step is part of what changing the price
;;; MEANS. See SECTION 3b for why the alternative (sync only at the aggregate
;;; verb) was rejected: a route binding PUT /products/{id}/pricing straight to
;;; !update would have re-created the very drift this feature exists to end.
;;;
;;; Load order: AFTER core/nst-bl-adhara.lisp, core/nst-bl-conflodis2.lisp,
;;; products/dod-dal-prd.lisp (the class), products/dod-bl-prd.lisp (nst-prd's own
;;; pratyayas, which the master-cache sync reuses).
;;; ═══════════════════════════════════════════════════════════════════════════

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 1 — The two legs of the लोप crossing
;;;
;;; nst-prd-pricing ↔ dod-product-pricing. Same shape as
;;; copyProduct-domaintodb / copyProduct-dbtodomain in dod-bl-prd.lisp, and it
;;; inherits that pair's two load-bearing decisions:
;;;
;;;   1. TENANT COMES FROM THE `prc-company` SLOT — the company OBJECT — not from
;;;      the entity's inherited tenant-id. DOD_PRODUCT_PRICING.TENANT_ID is an FK
;;;      to DOD_COMPANY.ROW_ID, and reading the object means a missing company
;;;      SIGNALS instead of silently writing a NULL tenant.
;;;
;;;   2. deleted-state IS FORCED TO "N" on the inbound leg. An INSERT is by
;;;      definition not a deletion, and the column is nullable with no default, so
;;;      leaving it to the entity would write NULL — and every later
;;;      [= [:deleted-state] "N"] read would then miss the row. (The view class's
;;;      :void-value "N" maps NULL back to "N" on the way OUT, which is exactly
;;;      why a NULL written on the way IN is invisible rather than obviously
;;;      broken.)
;;;
;;; row-id is deliberately NOT written on the inbound leg — it is AUTO_INCREMENT
;;; and is bound onto the entity afterwards by bind-generated-row-id.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun copyPrdPricing-domaintodb (source destination)
  "nst-prd-pricing → dod-product-pricing. See the header for decisions 1–2."
  ;; NOTE the slot name: the DOMAIN class calls it prc-company. Reading 'company
  ;; here would signal unbound-slot on every insert.
  (let ((company (slot-value source 'prc-company)))
    (with-slots (product-id price discount currency start-date end-date
                 active-flag deleted-state tenant-id)
        destination
      (setf product-id     (slot-value source 'product-id))
      (setf price          (slot-value source 'price))
      (setf discount       (slot-value source 'discount))
      (setf currency       (slot-value source 'currency))
      (setf start-date     (slot-value source 'start-date))
      (setf end-date       (slot-value source 'end-date))
      (setf active-flag    (slot-value source 'active-flag))
      ;; INVARIANTS — see the header
      (setf deleted-state  "N")                             ; decision 2
      (setf tenant-id      (slot-value company 'row-id))    ; decision 1
      destination)))

(defun copyPrdPricing-dbtodomain (source destination)
  "dod-product-pricing → nst-prd-pricing. The inbound direction of the crossing.

   Row-id and every business field are copied. TENANT_ID AND COMPANY ARE NOT: the
   caller constructs the nst-prd-pricing with :tenant-id from the domain-ctx (so
   that नियम-1 has something to check) and re-attaches the company object itself
   when a later write needs it — the same rule copyProduct-dbtodomain follows."
  (with-slots (row-id product-id price discount currency start-date end-date
               active-flag)
      destination
    (setf row-id      (slot-value source 'row-id))
    (setf product-id  (slot-value source 'product-id))
    (setf price       (slot-value source 'price))
    (setf discount    (slot-value source 'discount))
    (setf currency    (slot-value source 'currency))
    (setf start-date  (slot-value source 'start-date))
    (setf end-date    (slot-value source 'end-date))
    (setf active-flag (slot-value source 'active-flag))
    destination))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The laws the DATABASE DOES NOT ENFORCE
;;;
;;; Every function here exists because MySQL refuses nothing: no FOREIGN KEY, no
;;; CHECK constraint, no unique key on PRODUCT_ID, no NOT NULL on the window or
;;; the currency. Each one SIGNALS rather than quietly coercing — silently
;;; "fixing" a value the caller supplied is how a filter ends up meaning the
;;; opposite of itself (the recorded ?is-primary-location=0 incident).
;;; ═══════════════════════════════════════════════════════════════════════════

(define-condition prdpricing-validation-error (error)
  ((message :initarg :message :reader prdpricing-validation-error-message))
  (:report (lambda (c s)
             (format s "Product pricing validation: ~A"
                     (prdpricing-validation-error-message c))))
  (:documentation
   "A MALFORMED pricing value — the caller's mistake, not a system failure.

    A dedicated condition rather than a plain error, mirroring
    prd-shipping-validation-error (dod-bl-prd.lisp:644) for the same reason: the
    API boundary must be able to turn EXACTLY this into a 400 without catching
    every other error and mislabelling a genuine bug as a client error.

    That distinction is load-bearing here rather than theoretical. If the route
    caught plain ERROR, then 'price is negative' (the caller's fault, a 400) would
    be indistinguishable from a lost database connection (a 503) or from the
    'Unrecognized bo-knowledge-truth' guards below (a real bug, a 500) — and all
    three would reach the client as a bad request, hiding the two that need a human.

    Signalled by the SECTION 2 validators only. The :U/:F/:C knowledge guards
    deliberately still raise plain ERRORs: those are never the caller's fault."))

(defun prdpricing-validation-error (format-string &rest args)
  "Signal a malformed-value condition with a formatted message.
   The condition and this constructor share a name, following api-client-error
   in core/nst-bl-apidefs2.lisp:259."
  (error 'prdpricing-validation-error
         :message (apply #'format nil format-string args)))

(defun prdpricing-number-arg (value what)
  "Coerce a price/discount that may arrive as a JSON or query STRING, or signal.
   Rejects anything that is not a non-negative real — including a bare
   read-from-string of arbitrary text."
  (cond
    ((null value) nil)
    ((numberp value) value)
    ((and (stringp value)
          (plusp (length value))
          (every (lambda (c) (or (digit-char-p c) (find c ".+-" :test #'char=))) value))
     (let ((n (ignore-errors (read-from-string value))))
       (if (numberp n)
           n
           (prdpricing-validation-error "nst-prd-pricing: ~A ~S is not a number" what value))))
    (t (prdpricing-validation-error "nst-prd-pricing: ~A ~S is not a number" what value))))

(defun prdpricing-validate-price (price)
  "PRICE is decimal(10,2) NOT NULL with NO column default, and the column is
   unsigned in practice — the live range is 1.00 … 10000.00 with zero rows at 0.
   A price of 0 is refused rather than stored: this platform sells goods, and a
   zero price is far more likely to be a failed upload than a giveaway. If free
   products are ever wanted, that is a deliberate product decision with an
   explicit representation — not the accidental meaning of a missing value."
  (let ((p (prdpricing-number-arg price "price")))
    (cond ((null p) (prdpricing-validation-error "nst-prd-pricing: price is required — PRICE is NOT NULL with no column default"))
          ((not (realp p)) (prdpricing-validation-error "nst-prd-pricing: price ~S is not a real number" price))
          ((minusp p) (prdpricing-validation-error "nst-prd-pricing: price ~A is negative" p))
          ((zerop p) (prdpricing-validation-error "nst-prd-pricing: price must be greater than 0 (got ~A)" p))
          (t (coerce p 'double-float)))))

(defun prdpricing-validate-discount (discount)
  "DISCOUNT IS A PERCENTAGE — all 83 live rows sit in 0.00 … 10.00, on a
   decimal(5,2) column, against prices three orders of magnitude larger. So the
   range check is 0–100, and 100 is admitted only because the column could hold
   it, not because this platform has ever seen it.

   NIL PASSES THROUGH AS NIL and means 'no discount stated', which the copier
   writes as NULL. That is not the same statement as 0.00 ('no discount'), and
   the column's own default is 0.00 — so an omitted discount and an explicit zero
   are distinguishable here even though they behave alike at the till."
  (if (null discount)
      nil
      (let ((d (prdpricing-number-arg discount "discount")))
        (cond ((not (realp d)) (prdpricing-validation-error "nst-prd-pricing: discount ~S is not a real number" discount))
              ((minusp d) (prdpricing-validation-error "nst-prd-pricing: discount ~A is negative" d))
              ((> d 100) (prdpricing-validation-error "nst-prd-pricing: discount ~A exceeds 100 — DISCOUNT is a PERCENTAGE (live rows are 0–10), not a rupee amount" d))
              (t (coerce d 'double-float))))))

(defun prdpricing-validate-window (start-date end-date)
  "The window must be ordered: END-DATE may not precede START-DATE. The DDL
   permits the reversal (both columns are nullable timestamps) and the live table
   has no reversed rows, so this is a law with no field evidence behind it —
   stated anyway, because a reversed window makes discountexpired-p true on every
   day, which silently means 'never discounted' rather than erroring.

   Accepts clsql date objects, or DD/MM/YYYY strings via get-date-from-string —
   the format the CSV template publishes (get-date-string) and therefore the one
   a CSV-fed caller will hand us. NIL is refused: a window with no start or no
   end is not a window, and the discount-expiry test above would signal on it."
  (labels ((->date (v what)
             (cond ((null v) (prdpricing-validation-error "nst-prd-pricing: ~A is required" what))
                   ((stringp v)
                    (let ((s (string-trim " " v)))
                      (if (zerop (length s))
                          (prdpricing-validation-error "nst-prd-pricing: ~A is an empty string" what)
                          (get-date-from-string s))))
                   (t v))))
    (let ((s (->date start-date "start-date"))
          (e (->date end-date "end-date")))
      (when (clsql:date< e s)
        (prdpricing-validation-error "nst-prd-pricing: end-date precedes start-date — the discount window would be empty on every day"))
      (values s e))))

(defun prdpricing-window-contains-p (start-date end-date &optional (today (clsql:get-date)))
  "Is TODAY inside [START-DATE, END-DATE]? The predicate discountexpired-p is
   built from, promoted here so the verb and the UI cannot drift apart."
  (and (clsql:date>= today start-date)
       (clsql:date<= today end-date)))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 3 — Selectors
;;;
;;; The legacy selectors in dod-bl-prd.lisp (select-product-pricing-by-id /
;;; -by-product-id / -by-startdate) all filter active_flag='Y' AND
;;; deleted_state='N' AND tenant_id, and all take the CAR. They are kept and
;;; reused for READS. Two things they cannot do, which is why new selectors
;;; appear below:
;;;
;;;   * they cannot answer 'how many live pricing rows does this product have' —
;;;     the CAR hides it, and the singleton :around check needs the plural;
;;;   * they cannot list a tenant's pricing rows for a bulk/template read.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun select-prd-pricing-rows-for-product (product-id tenant-id)
  "ALL live pricing rows for PRODUCT-ID in TENANT-ID, as a list — the plural the
   singleton check needs. Returns the empty list, never nil-as-unknown: this is a
   plain SELECT whose failure raises, unlike the Belnap-wrapped verb calls."
  (clsql:select 'dod-product-pricing
                :where [and [= [:active-flag] "Y"]
                            [= [:deleted-state] "N"]
                            [= [:product-id] product-id]
                            [= [:tenant-id] tenant-id]]
                :caching *dod-database-caching* :flatp t))

(defun select-prd-pricing-row-for-product (product-id tenant-id)
  "THE live pricing row for PRODUCT-ID, or NIL. Singular by the singleton law:
   the CAR is taken here for the same reason the legacy selector takes it — the
   law makes a second row impossible, so a CAR cannot lose one."
  (car (select-prd-pricing-rows-for-product product-id tenant-id)))

(defun select-prd-pricing-by-row-id (row-id tenant-id)
  "One pricing row by its OWN row-id, tenant-scoped. NOT the address any pratyaya
   accepts — used by the reverse ferry and by diagnostics, where an already-known
   row-id is in hand."
  (car (clsql:select 'dod-product-pricing
                     :where [and [= [:active-flag] "Y"]
                                 [= [:deleted-state] "N"]
                                 [= [:tenant-id] tenant-id]
                                 [= [:row-id] row-id]]
                     :caching *dod-database-caching* :flatp t)))

(defun select-prd-pricing-by-filter (tenant-id &key product-id
                                                  (sort-by :row-id) (sort-dir :desc)
                                                  limit offset)
  "The tenant's pricing rows for a list/bulk read.

   NO WINDOW FILTER HERE, deliberately. The date window is a comparison against
   TODAY, and CLSQL would have to express MySQL's CURDATE() inside the WHERE
   clause — which puts the clock in two places (this query and
   prdpricing-window-contains-p) and lets them disagree. The window is therefore
   applied in Lisp by the caller, from the ONE predicate the checkout's
   discountexpired-p is built on.

   sort-by is NOT caller-controllable here and no value is interpolated: the
   column comes from a whitelist of two, the sort the template needs (row-id) and
   the one a bulk report reads back by."
  (when (and offset (null limit))
    (error "nst-prd-pricing: :offset given without :limit — MySQL cannot express an offset on its own"))
  (let* ((col (case sort-by
                (:row-id     :row-id)
                (:product-id :product-id)
                (otherwise (error "nst-prd-pricing: sort-by ~A is not :row-id or :product-id" sort-by))))
         (dir (case sort-dir
                (:asc :asc) (:desc :desc)
                (otherwise (error "nst-prd-pricing: sort-dir must be :asc or :desc, got ~A" sort-dir))))
         (clauses (list [= [:active-flag] "Y"]
                        [= [:deleted-state] "N"]
                        [= [:tenant-id] tenant-id])))
    (when product-id (push [= [:product-id] product-id] clauses))
    (apply #'clsql:select 'dod-product-pricing
                          :where (apply #'clsql:sql-and clauses)
                          :order-by (list (list col dir))
                          :caching *dod-database-caching* :flatp t
                          (append (when limit  (list :limit limit))
                                  (when offset (list :offset offset))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 3b — THE MASTER-CACHE SYNC (the one writer of CURRENT_PRICE)
;;;
;;; THE LEGACY BEHAVIOUR THIS REPRODUCES. The vendor's pricing form posts to
;;; /hhub/hhubvendprodpricingsaveaction → dod-controller-vendor-product-pricing-action
;;; → create-model-for-vendorprodpricingaction (vendor/dod-ui-ven.lisp:340-370),
;;; which does THREE things, in this order:
;;;
;;;     1. prdpricing absent  → (create-product-pricing …)          [create]
;;;     2. prdpricing present → set price/currency/discount/start/end
;;;                             + (update-prd-details prdpricing)    [update]
;;;     3. product present    → set CURRENT-PRICE / CURRENT-DISCOUNT
;;;                             + (update-prd-details product)       [THE SYNC]
;;;
;;; update-prd-details is nothing but clsql:update-records-from-instance
;;; (dod-bl-prd.lisp:197), so step 3 is the product row's own update — which is
;;; exactly what !update on nst-prd does, and why this helper calls THAT rather
;;; than writing DOD_PRD_MASTER directly. A second writer is what let the two
;;; rows disagree in the first place.
;;;
;;; WHERE THIS SITS, AND WHY IT MOVED. The sync used to live only in
;;; set-product-pricing, on the Guardrail-2 argument that a प्रत्यय must act on
;;; ONE कर्म. That argument is real but it lost: the vendor's requirement is
;;; that the product row's CURRENT_PRICE is ALWAYS updated, and a rule enforced
;;; one call away from the verb that changes the price is a rule a future caller
;;; can miss — the route layer binding PUT /products/{id}/pricing straight to
;;; !update would have silently re-created the 15-row drift this feature exists
;;; to end. So the sync is called from BOTH entity pratyayas that change a price
;;; (make, !update), through this single function, and NO caller can bypass it.
;;;
;;; THE COST, stated plainly: !update on nst-prd-pricing now writes two rows, so
;;; it is no longer a pure single-कर्म verb. The justification is that the price
;;; on the product row is not a second opinion — it is a CACHE OF THIS ROW (see
;;; THE DENORMALISATION LAW in the header), so keeping it in step is part of what
;;; it MEANS to change the price, rather than a separate act.
;;;
;;; ATOMICITY. This helper does NOT open a transaction. It reports honestly —
;;; T, or a Belnap sentinel — and the atomicity guarantee belongs to whichever
;;; caller wraps the pair: set-product-pricing does, which is why it is the
;;; documented entry point. Calling the entity pratyaya DIRECTLY is therefore
;;; NOT atomic: the pricing row can land while the cache write fails, leaving the
;;; catalogue advertising the old price. That is a real, documented difference
;;; between the two entry points, not an oversight.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun prdpricing-sync-product-cache (ctx product-id price discount)
  "Mirror PRICE/DISCOUNT onto the product row's cached CURRENT_PRICE /
   CURRENT_DISCOUNT, so the catalogue filter, the whitelisted :current-price sort
   and the cart see what this pricing row says.

   Returns T, or a Belnap sentinel when the product row did not take the values.
   Never raises for a database failure — the caller decides what to do with the
   answer, which is what lets set-product-pricing roll the whole thing back."
  (let ((cache (!update 'nst-prd (princ-to-string product-id) ctx
                        :current-price    price
                        :current-discount discount)))
    (cond
      ;; NOTE what nst-prd/!update returns on success: THE ENTITY, not T.
      ((typep cache 'nst-prd) t)
      ;; A sentinel from the product verb is already the honest answer — pass it
      ;; through rather than re-wrapping, so the reason the product verb gave
      ;; (not found, unknown, contradiction) survives to the boundary.
      ((typep cache '(or nst-entity-nil nst-entity-unknown nst-entity-contradiction))
       cache)
      (t (make-instance 'nst-entity-unknown
                        :tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)
                        :reason (format nil "Product ~A: the pricing row was written but nst-prd/!update returned ~S instead of an entity — the product row's cached price is not known to be updated." product-id cache))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 4 — make (सृजन) — create THE pricing row for a product
;;;
;;; Two refusals happen BEFORE any INSERT, and both are Belnap answers rather
;;; than raised errors, so the boundary can render them as HTTP instead of 500:
;;;
;;;   * the PARENT PRODUCT must exist in the SESSION TENANT. No FOREIGN KEY backs
;;;     PRODUCT_ID (and it is nullable), so MySQL would accept a price attached
;;;     to a product that does not exist, or to another tenant's product.
;;;
;;;   * the SINGLETON must be free. A second live row for one product is a coin
;;;     flip, not more data — see THE SINGLETON LAW.
;;;
;;; The :around shape is copied from nst-vnd-shp's make, which learned it the
;;; hard way: a :before method cannot return a value, so raising was its only way
;;; to refuse, and every refusal reached the boundary as a 500 — indistinguishable
;;; from a crash.
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod make :around ((entity-class (eql 'nst-prd-pricing)) (ctx domain-ctx) &rest initargs)
  "Refuse before the INSERT when the product is absent from this tenant, or when
   the product already carries a pricing row.

   The parent check is deliberately TENANT-SCOPED: select-product-by-id filters
   on the session tenant, so another tenant's product row-id produces the same
   answer as a product that does not exist — 404, never a peek across tenants
   (OWASP API1:2023 BOLA)."
  (let* ((company   (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (pid-raw   (getf initargs :product-id))
         (pid       (if (stringp pid-raw)
                        (product-row-id-from-string pid-raw)
                        pid-raw)))
    (cond
      ((null pid)
       (make-instance 'nst-entity-contradiction
                      :tenant-id tenant-id
                      :reason "nst-prd-pricing: a price must be attached to a product, and no usable :product-id was supplied (row-ids are integers)."))
      ((null (select-product-by-id pid company))
       (make-instance 'nst-entity-nil
                      :tenant-id tenant-id
                      :reason (format nil "Product row-id ~A not found in this tenant — a price cannot be attached to a product that is not here. (DOD_PRODUCT_PRICING declares no FOREIGN KEY, so the database would have accepted it.)" pid)))
      (t
       (let ((existing (select-prd-pricing-rows-for-product pid tenant-id)))
         (if existing
             ;; THE SINGLETON LAW. Reported as a contradiction, not as :T: the
             ;; caller asked for a state that cannot coexist with the row already
             ;; there, and the honest fix is !update (or delete! first) — a plain
             ;; 'already exists' would invite a retry that can never succeed.
             (make-instance 'nst-entity-contradiction
                            :tenant-id tenant-id
                            :reason (format nil "Product row-id ~A already carries a live pricing row (pricing row-id ~A). One product has ONE price: send the change through !update, or delete! the existing row first. A second row would be silently ignored by every reader that takes the CAR."
                                            pid (slot-value (car existing) 'row-id)))
             (call-next-method)))))))

(defmethod make ((entity-class (eql 'nst-prd-pricing)) (ctx domain-ctx) &rest initargs)
  "सृजन प्रत्यय — create the pricing row for a product.

   कारक: the tenant comes from ctx alone (नियम-1), passed as the INTEGER row-id,
   because check-niyam compares two integers. The company OBJECT is still needed
   for a different job — copyPrdPricing-domaintodb turns it into the row's
   TENANT_ID — and it is set UNCONDITIONALLY from ctx (never from initargs), so a
   caller-supplied :company cannot write the price into another tenant."

  (let* ((company   (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (pid-raw   (getf initargs :product-id))
         (pid       (if (stringp pid-raw) (product-row-id-from-string pid-raw) pid-raw))
         ;; strip :company and :product-id out of the argument list: :company is
         ;; the कारक (set below, from ctx), and :product-id has already been
         ;; validated and normalised to an integer.
         (clean     (let ((args (copy-list initargs)))
                      (remf args :company)
                      (remf args :product-id)
                      args))
         (entity    (apply #'make-instance 'nst-prd-pricing
                           :tenant-id tenant-id
                           :product-id pid
                           clean))
         (dbobj     (make-instance 'dod-product-pricing)))
    (setf (prc-company entity) company)
    ;; ── LAWS, applied only when the caller said nothing, so an explicit value
    ;;    is preserved. Each SIGNALS on an unusable value rather than coercing.
    (setf (price entity) (prdpricing-validate-price (price entity)))
    (setf (discount entity) (prdpricing-validate-discount (discount entity)))
    (multiple-value-bind (s e) (prdpricing-validate-window (start-date entity) (end-date entity))
      (setf (start-date entity) s)
      (setf (end-date entity) e))
    ;; CURRENCY is a string(3). The live rows are all 'INR'; the column's own
    ;; default is 'USD'. The account's currency is the honest default, and the
    ;; literal is only a fallback for a caller whose context cannot supply one.
    (unless (currency entity)
      (setf (currency entity) (or (ignore-errors (get-account-currency company)) "INR")))
    ;; A new row is live: the readers filter active_flag='Y', so NULL here would
    ;; be a row that exists and prices nothing.
    (unless (active-flag entity) (setf (active-flag entity) "Y"))
    (copyPrdPricing-domaintodb entity dbobj)
    (let ((knowledge (with-nst-db-create (:source "nst-prd-pricing/make")
                        (clsql:update-records-from-instance dbobj)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T (bind-generated-row-id entity (bo-knowledge-payload knowledge))
            ;; THE MASTER-CACHE SYNC — see SECTION 3b. Part of creating a price,
            ;; not a follow-up to it: a product whose pricing row exists while its
            ;; cached CURRENT_PRICE still reads 1.00 is precisely the drift this
            ;; feature exists to end.
            (let ((sync (prdpricing-sync-product-cache ctx pid (price entity) (discount entity))))
              (if (eq sync t) entity sync)))
        (:F ;; This table declares NO unique key, so a rejection here means the
            ;; schema changed under this verb — the :around singleton check is no
            ;; longer sufficient. Do not fold this into the singleton message.
            (make-instance 'nst-entity-contradiction
                           :tenant-id tenant-id
                           :reason "nst-prd-pricing: the INSERT was rejected at the database, and DOD_PRODUCT_PRICING declares no unique key — so a rejection here means the schema changed under this verb. Investigate the table; the :around singleton check is no longer sufficient."))
        (:U (domain-sentinel-from-knowledge
             knowledge ctx
             :reason (format nil "Pricing create for product ~A: the database call did not answer — the row may or may not have been written, so this is unknown, not failed" pid)))
        (:C (error "Unreachable: no :pre-flight form was supplied to with-nst-db-create in this call"))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create"
                          (bo-knowledge-truth knowledge)))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 5 — fetch (स्मरण) — recall by PRODUCT-ID
;;;
;;; 🚨 ID IS THE PRODUCT-ID, NOT A PRICING ROW-ID. Forced, not chosen — the same
;;; departure nst-vnd-shp's fetch records. With one row per product and no
;;; addressable collection, a client has no way to LEARN a pricing row-id, so the
;;; parent is the only usable address — and it is the honest one, since
;;; (product-id, tenant) IS this entity's identity. The row-id is still published
;;; in the response; it is simply never the input.
;;;
;;; A product WITH NO PRICING ROW gets nst-entity-nil → 404, which is the correct
;;; REST answer and NOT an error: 11 live products are in exactly that state, and
;;; the caller's next move (create one, or read the master's cache) differs from
;;; 'the product does not exist'.
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod fetch ((entity-class (eql 'nst-prd-pricing)) (id string) (ctx domain-ctx))
  "स्मरण प्रत्यय — the pricing row of the product addressed by ID, in the session
   tenant. Returns a real nst-prd-pricing or a Belnap sentinel, never bare nil."
  (let* ((company   (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (pid       (product-row-id-from-string id)))
    (if (null pid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a product row (row-ids are integers)" id))
        ;; Confirm the product first, so 'no such product' and 'product with no
        ;; price' are distinguishable answers rather than one 404.
        (if (null (select-product-by-id pid company))
            (make-instance 'nst-entity-nil
                           :tenant-id tenant-id
                           :reason (format nil "Product row-id ~A not found in this tenant" pid))
            (let ((knowledge (with-db-call (select-prd-pricing-row-for-product pid tenant-id)
                                           "nst-prd-pricing/fetch (product-id, session tenant)")))
              (domain-result-from-knowledge
               knowledge ctx
               :hydrate (lambda (dbobj)
                          (let ((entity (make-instance 'nst-prd-pricing :tenant-id tenant-id)))
                            (copyPrdPricing-dbtodomain dbobj entity)
                            ;; The company object is not part of the row, and the
                            ;; outbound copier derives the written TENANT_ID from
                            ;; it — without this line a fetched entity handed to
                            ;; !update writes a NIL tenant.
                            (setf (prc-company entity) company)
                            entity))
               :reason (lambda (truth)
                         (case truth
                           (:F (format nil "Product row-id ~A carries no live pricing row" pid))
                           (:U (format nil "Product row-id ~A pricing: the database call did not answer — whether a row exists is unknown" pid))
                           (:C (format nil "Product row-id ~A returned more than one pricing row — the SINGLETON LAW is violated; every reader that takes the CAR is now a coin flip" pid))))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 6 — !update (!state) — THE VENDOR'S VERB
;;;
;;; This is the single-update case: a vendor changes a product's price, its
;;; discount, or the window the discount runs in. Addressed by PRODUCT-ID.
;;;
;;; PARTIAL BY CONSTRUCTION: the row is hydrated first, then only the supplied
;;; keys are reinitialized onto it, then the whole instance is written back — so
;;; an omitted field keeps its stored value. That is what makes 'change just the
;;; discount end date' a legal request.
;;;
;;; :product-id IS STRIPPED from the update args. It is the ADDRESS of the कर्म,
;;; not a field of it: letting a body-supplied product-id re-point the row would
;;; move one product's price onto another product. :row-id is stripped for the
;;; same reason — the UPDATE always targets the row the SELECT returned, because
;;; the copier never writes row-id.
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod !update ((entity-class (eql 'nst-prd-pricing)) (id string) (ctx domain-ctx)
                    &rest update-args)
  "!state प्रत्यय — partially update the pricing row of the product addressed by ID."
  (let* ((company   (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (pid       (product-row-id-from-string id)))
    (if (null pid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a product row (row-ids are integers)" id))
        (let ((dbobj (select-prd-pricing-row-for-product pid tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Product row-id ~A carries no live pricing row to update" pid))
              (let ((entity (make-instance 'nst-prd-pricing :tenant-id tenant-id)))
                (copyPrdPricing-dbtodomain dbobj entity)      ; current stored state
                (setf (prc-company entity) company)
                (let ((args (copy-list update-args)))
                  (remf args :product-id)
                  (remf args :row-id)
                  (apply #'reinitialize-instance entity args))  ; only supplied keys change
                ;; Same कारक rule as make: a caller-supplied :company must not be
                ;; able to move an EXISTING row to another tenant. Re-set AFTER
                ;; the reinitialize so the session company always wins.
                (setf (prc-company entity) company)
                ;; ── LAWS on the RESULTING row, not on the arguments. Validating
                ;;    the arguments alone would miss a change that only becomes
                ;;    illegal in combination with what is already stored — e.g.
                ;;    moving start-date past a stored end-date.
                (setf (price entity) (prdpricing-validate-price (price entity)))
                (setf (discount entity) (prdpricing-validate-discount (discount entity)))
                (multiple-value-bind (s e) (prdpricing-validate-window (start-date entity) (end-date entity))
                  (setf (start-date entity) s)
                  (setf (end-date entity) e))
                ;; NOTE: the copier forces DELETED_STATE to "N" on the way out.
                ;; Harmless here — the selector filters deleted rows, so a deleted
                ;; target never reaches this point — but do not reuse
                ;; copyPrdPricing-domaintodb on a row you intend to keep deleted.
                (copyPrdPricing-domaintodb entity dbobj)
                (let ((knowledge (with-nst-db-update (:source "nst-prd-pricing/!update")
                                    (clsql:update-records-from-instance dbobj)
                                    dbobj)))
                  (case (bo-knowledge-truth knowledge)
                    (:T ;; THE MASTER-CACHE SYNC — see SECTION 3b. This is the
                        ;; vendor's actual requirement: 'update the product's
                        ;; price and its discount window' must leave the PRODUCT
                        ;; ROW's CURRENT_PRICE / CURRENT_DISCOUNT correct too,
                        ;; because that is what the catalogue filter, the
                        ;; :current-price sort and the cart read
                        ;; (dod-ui-ven.lisp:362-367 in the legacy controller).
                        (let ((sync (prdpricing-sync-product-cache
                                     ctx pid (price entity) (discount entity))))
                          (if (eq sync t) entity sync)))
                    (:U (domain-sentinel-from-knowledge
                         knowledge ctx
                         :reason (format nil "Pricing update, product row-id ~A: the database call did not answer — the row's current state is unknown" pid)))
                    (:F (error "Unreachable: with-nst-db-update without :pre-flight cannot return :F (product row-id ~A)" pid))
                    (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-update"
                                      (bo-knowledge-truth knowledge)))))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 7 — delete! (लोप) — soft delete the pricing row
;;;
;;; DELETED_STATE → "Y", the row kept. Why kept: the row is the only record of
;;; what a product used to cost, and the platform's soft-delete convention
;;; (नियम-2) makes it invisible to every verb from then on without destroying it.
;;;
;;; CONSEQUENCE, stated because it is surprising: deleting a product's pricing row
;;; leaves the product resolvable and the MASTER CACHE untouched. The product keeps
;;; advertising its last cached price in the catalogue while the pricing row that
;;; justified it is gone. That is acceptable only because the cache is a cache; if
;;; the caller wants the product to stop selling, that is a product delete!, not a
;;; pricing delete!.
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod delete! ((entity-class (eql 'nst-prd-pricing)) (id string) (ctx domain-ctx))
  "लोप प्रत्यय — soft-delete the pricing row of the product addressed by ID.
   Returns T on success (the ack nst-prd's delete! also returns)."
  (let* ((company   (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (pid       (product-row-id-from-string id)))
    (if (null pid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a product row (row-ids are integers)" id))
        (let ((dbobj (select-prd-pricing-row-for-product pid tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Product row-id ~A carries no live pricing row (or it was already deleted)" pid))
              (let ((knowledge (with-nst-db-delete (:source "nst-prd-pricing/delete!")
                                  (setf (slot-value dbobj 'deleted-state) "Y")
                                  (clsql:update-record-from-slot dbobj 'deleted-state)
                                  dbobj)))
                (case (bo-knowledge-truth knowledge)
                  (:T t)
                  (:U (domain-sentinel-from-knowledge
                       knowledge ctx
                       :reason (format nil "Pricing delete, product row-id ~A: the database call did not answer — whether the row was soft-deleted is unknown" pid)))
                  (:F (error "Unreachable: with-nst-db-delete without :pre-flight cannot return :F (product row-id ~A)" pid))
                  (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-delete"
                                    (bo-knowledge-truth knowledge))))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 8 — enumerate (दर्शन) — the tenant's pricing rows
;;;
;;; Scope filter, not a per-row check: नियम-1 applies to WHERE TENANT_ID = ctx.tenant,
;;; which is exactly what select-prd-pricing-by-filter builds.
;;;
;;; WHY THIS EXISTS even though the entity is a singleton per product: the BULK
;;; and TEMPLATE flows need 'every price this vendor is responsible for' in one
;;; read, and a per-product fetch loop over 107 products is 107 round trips to
;;; answer a question SQL answers once.
;;;
;;; Returns a LIST, or the EMPTY LIST when nothing matches — an empty list is a
;;; successful empty result (200 []), not a not-found fact. Only :U and :C come
;;; back as sentinels, on the same reasoning nst-prd's enumerate records.
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod enumerate ((entity-class (eql 'nst-prd-pricing)) (ctx domain-ctx)
                      &key product-id include-expired (sort-by :row-id) (sort-dir :desc)
                           limit offset)
  "दर्शन प्रत्यय — the session tenant's pricing rows, optionally for one product.

   :INCLUDE-EXPIRED N (the default) keeps only rows whose window contains TODAY —
   the rows actually pricing something right now. T returns every live row, which
   is what a template download needs: a vendor editing the CSV must SEE an expired
   discount in order to fix it, and a list that hid the row would make the product
   look as though it had no price at all.

   ⚠ THE WINDOW TEST RUNS IN LISP, AFTER THE SQL PAGE — so :include-expired N
   together with :limit/:offset can return a SHORT page: rows dropped by the
   window test are not replaced from the next SQL page, and a caller paging
   through the result may therefore see fewer rows than exist. The bulk and
   template readers — the reason this verb exists — read every row unpaged and are
   unaffected. If paged window-filtered listing is ever needed, the filter has to
   move into SQL as CURDATE() BETWEEN START_DATE AND END_DATE, in one place."
  (let* ((company   (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (pid       (cond ((null product-id) nil)
                          ((stringp product-id)
                           (or (product-row-id-from-string product-id)
                               (error "nst-prd-pricing/enumerate: product-id ~S does not address a product row" product-id)))
                          (t product-id)))
         (knowledge (with-nst-db-read-all
                        (:source "nst-prd-pricing/enumerate"
                         :pk-extractor (lambda (d) (slot-value d 'row-id)))
                      (select-prd-pricing-by-filter
                       tenant-id
                       :product-id pid
                       :sort-by sort-by :sort-dir sort-dir
                       :limit limit :offset offset))))
    (case (bo-knowledge-truth knowledge)
      (:T (let ((entities
                  (mapcar (lambda (dbobj)
                            (let ((entity (make-instance 'nst-prd-pricing :tenant-id tenant-id)))
                              (copyPrdPricing-dbtodomain dbobj entity)
                              (setf (prc-company entity) company)
                              entity))
                          (bo-knowledge-payload knowledge))))
            (if include-expired
                entities
                (remove-if-not (lambda (e)
                                 (prdpricing-window-contains-p (start-date e) (end-date e)))
                               entities))))
      (:F '())                                    ; nothing matches — a success
      (:U (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (format nil "Pricing enumerate, tenant ~A: the database call did not answer — the contents are unknown" tenant-id)))
      (:C (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (format nil "Pricing enumerate, tenant ~A: the result set contained duplicate primary keys — data integrity issue, investigate DOD_PRODUCT_PRICING directly" tenant-id)))
      (otherwise (error "Unrecognized bo-knowledge-truth ~A from nst-prd-pricing/enumerate"
                        (bo-knowledge-truth knowledge))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 9 — set-product-pricing (THE AGGREGATE VERB)
;;;
;;; THE VENDOR'S ACTUAL REQUEST, in one verb: 'set this product's price and
;;; discount window'. It is an UPSERT addressed by PRODUCT-ID —
;;;
;;;     product has no pricing row  →  make
;;;     product has one             →  !update
;;;
;;; — which is exactly what create-product already does at creation
;;; (dod-bl-prd.lisp:318) and what the CSV round-trip does per row
;;; (create-bulk-products, dod-bl-prd.lisp:299-306). Promoting it here gives the
;;; API, the CSV path and any REPL caller ONE implementation instead of three.
;;;
;;; WHY THE UPSERT IS NOT INSIDE !update: !update must act on ONE कर्म. If it
;;; silently created a row when none existed, then 'update the price' would
;;; sometimes INSERT, and the caller could not tell which happened. The decision
;;; to create belongs to the verb that knows the business intent — this one.
;;;
;;; WHAT THE SYNTAX OF 'HERE' MEANS NOW: the sync is NOT done by this verb — the
;;; entity pratyayas do it (SECTION 3b), so that no caller can bypass it. What
;;; this verb owns is the ATOMICITY of the pair, and the create-or-update
;;; decision.
;;;
;;; THE TRANSACTION. The pricing write and its master-cache sync happen inside
;;; ONE clsql:with-transaction, and a failure on EITHER forces a rollback via a
;;; non-local exit out of the block. That matters because with-nst-db-* macros
;;; CATCH database errors and return Belnap knowledge instead of raising — so
;;; without the explicit return-from, a failed cache write would leave the
;;; pricing row committed and the cache stale, which is precisely the 15-row
;;; drift this feature exists to stop. This verb is therefore the entry point to
;;; prefer; calling make/!update directly is legal but NOT atomic (SECTION 3b).
;;; ═══════════════════════════════════════════════════════════════════════════

(defun set-product-pricing (ctx product-id &key price discount start-date end-date currency)
  "Upsert the pricing row of PRODUCT-ID in the session tenant, and refresh the
   product master's cached CURRENT_PRICE / CURRENT_DISCOUNT to match.

   Returns the nst-prd-pricing entity on success, or a Belnap sentinel — never a
   bare nil. On any failure BOTH rows are rolled back, so the caller never sees a
   price that the catalogue is not also advertising.

   ── WHAT A MISSING KEY MEANS, and it means TWO DIFFERENT THINGS by path.
   This is the one place that distinction is made, so it is stated once, here.

   ON THE UPDATE PATH (a pricing row already exists) a missing key means LEAVE IT
   ALONE. Only the supplied keys are applied, so {discount: 7} changes the
   discount and nothing else.

   🚨 THAT IS NOT WHAT THIS FUNCTION USED TO DO. It passed all five keys to
   !update unconditionally, so an omitted :price arrived as NIL, reinitialize-
   instance set the slot to NIL, and prdpricing-validate-price refused the row for
   having no price at all — a partial update could not be expressed AT ALL, and an omitted
   :discount was written as NULL rather than left alone. The create path beside it
   had filtered with (when …) since it was written; only the update path did not.

   ON THE CREATE PATH (no pricing row yet) a missing key means TAKE THE HOUSE
   DEFAULT, because there is no stored value to preserve and PRICE is NOT NULL
   with no column default — refusing the call would be the only alternative, and a
   caller who said nothing about price has not thereby said something wrong:

     :price      1.00 — one unit of the account currency. The value
                 persist-product (dod-bl-prd.lisp:265) and nst-prd/make
                 (dod-bl-prd.lisp:945) already use, so the two rows still agree.
     :discount   0.00 — 'no discount', the column's own DDL default. Note this is
                 NOT the same statement as a stored NULL ('never stated'); on
                 create there is nothing to be ambiguous about.
     :start-date today          \\ the same 90-day window create-product writes
     :end-date   today + 90 days /  (dod-bl-prd.lisp:985), kept rather than
                 invented so a new row is dated the way every existing row was.
     :currency   the account's currency, applied by make itself (SECTION 4).

   NIL IS NEVER HANDED TO A VALIDATOR on either path, which is the point: a NIL
   that reaches prdpricing-validate-price or -validate-window is a 'required'
   error, and neither path has a reason to produce one."
  (let* ((company   (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (pid       (if (stringp product-id)
                        (product-row-id-from-string product-id)
                        product-id)))
    (if (null pid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a product row (row-ids are integers)" product-id))
        (block set-pricing
          (clsql:with-transaction ()
            (let* (;; THE ONE ARG LIST, built the same way for both paths: a key
                   ;; the caller did not state is simply absent. This is what makes
                   ;; the update path partial and keeps NIL away from the laws.
                   (supplied (append (when price      (list :price price))
                                     (when discount   (list :discount discount))
                                     (when start-date (list :start-date start-date))
                                     (when end-date   (list :end-date end-date))
                                     (when currency   (list :currency currency))))
                   (existing (select-prd-pricing-row-for-product pid tenant-id))
                   (outcome
                     (if existing
                         ;; ── UPDATE PATH — addressed by product-id, so the
                         ;;    entity verbs keep addressing what callers can name.
                         ;;    ONLY :supplied crosses; no defaults are applied,
                         ;;    because applying one here would RESET a stored
                         ;;    price to 1.00 every time a caller touched only the
                         ;;    discount.
                         (apply #'!update 'nst-prd-pricing (princ-to-string pid) ctx supplied)
                         ;; ── CREATE PATH — the defaults above fill only the keys
                         ;;    the caller left unstated.
                         (apply #'make 'nst-prd-pricing ctx
                                :product-id pid
                                (append supplied
                                        (unless price
                                          (list :price 1.00))
                                        (unless discount
                                          (list :discount 0.00))
                                        (unless start-date
                                          (list :start-date (clsql:get-date)))
                                        (unless end-date
                                          (list :end-date
                                                (clsql:date+ (clsql:get-date)
                                                             (clsql-sys:make-duration :day 90)))))))))
              ;; A non-entity here means EITHER the pricing write failed OR its
              ;; master-cache sync did — make/!update return the sync's own
              ;; sentinel when the product row did not take the values (see
              ;; SECTION 3b). Both cases leave the transaction WITHOUT
              ;; committing, so the caller never sees a price that the product
              ;; row is not also advertising. That is the whole point of wrapping
              ;; the pair here: the entity verbs report honestly but cannot roll
              ;; back on their own.
              (unless (typep outcome 'nst-prd-pricing)
                (return-from set-pricing outcome))
              outcome))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 10 — The reverse ferry — domain->response + render-json
;;;
;;; The boundary classes (ProductPricingRequestModel / ProductPricingResponseModel)
;;; are DECLARED in dod-dal-prd.lisp:984-1046, and their docstrings say these two
;;; methods "live with the प्रत्यय in products/nst-bl-prdpricing.lisp"
;;; (dod-dal-prd.lisp:1049 and :978-981). Until this section existed they lived
;;; NOWHERE: class-slots reported the slots, the verbs below returned
;;; nst-prd-pricing entities, and action->response (conflodis2 §4) reached
;;; domain->response with NO APPLICABLE METHOD — a 500 on every pricing route, at
;;; the last hop, AFTER the database had already been written.
;;;
;;; ONLY TWO METHODS ARE DEFINED HERE, deliberately — the same rule
;;; dod-bl-prd.lisp:1419-1437 records for products. The rest of the surface is
;;; already ENTITY-GENERIC in this tree, and redefining ANY of it here would
;;; silently replace the warehouse's version (same generic function, same
;;; specializer):
;;;
;;;   * domain->response on nst-entity-nil / -unknown / -contradiction lives in
;;;     warehouse/nst-bl-whsapi.lisp §4 and specializes on the SENTINEL classes,
;;;     not on nst-whs. A pricing miss therefore already ferries to
;;;     nst-response-nil and answers 404 with no pricing-specific code.
;;;   * domain->response on (eql t) — the delete! ack — is generic by the same
;;;     reasoning.
;;;   * render-json on LIST, and domain->response-list, are thin mapcars over the
;;;     per-element methods, so they already cover ProductPricingResponseModel.
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod domain->response ((entity nst-prd-pricing) (ctx domain-ctx))
  "Reverse ferry (adhara §4): nst-prd-pricing → ProductPricingResponseModel.

   entity is the ONLY dispatching argument that may be an nst-domain-entity, and
   the entity itself never crosses into Ring 4 — only the boundary object does.

   EVERY declared slot is copied, and the two that are NOT copied are the कारक
   rather than payload: tenant-id and prc-company. ProductPricingResponseModel has
   no field to receive them, so they cannot leak by accident — a fact must be
   added to BOTH the response model and the render-json allowlist before it can
   ever reach a client (adhara's security contract).

   ROW-ID IS CARRIED ACROSS even though the entity verbs ADDRESS a pricing row by
   its PRODUCT-id. Publishing an address is not accepting one: the row-id goes out
   and is never read back in (see dod-dal-prd.lisp:1056-1072 on why product-id is
   published and tenant-id is not)."
  (declare (ignore ctx))
  (let ((destination (make-instance 'ProductPricingResponseModel)))
    (setf (row-id destination)      (row-id entity))
    (setf (product-id destination)  (product-id entity))
    (setf (price destination)       (price entity))
    (setf (discount destination)    (discount entity))
    (setf (currency destination)    (currency entity))
    (setf (start-date destination)  (start-date entity))
    (setf (end-date destination)    (end-date entity))
    (setf (active-flag destination) (active-flag entity))
    destination))

(defun prdpricing-date->string (date)
  "A CLSQL date → \"DD/MM/YYYY\", or NIL when the column is empty.

   DD/MM/YYYY is not an arbitrary choice, and the round trip is the reason: it is
   what get-date-string publishes (dod-bl-utl.lisp:603) and what
   get-date-from-string parses (dod-bl-utl.lisp:537), which is exactly the format
   prdpricing-validate-window accepts INBOUND (SECTION 2). Publishing ISO-8601 or
   a universal time instead would hand the client a value it could not PUT back —
   a read whose result is rejected by the write of the same field.

   NIL IS NOT ZERO-PADDED INTO SOMETHING. Both window columns are nullable, and an
   absent date crosses as JSON null rather than as a fabricated epoch."
  (when date (get-date-string date)))

(defun prdpricing-response-discount-expired-p (r)
  "Is R's discount window over as of TODAY?

   DERIVED AT RENDER TIME, NEVER STORED — the contract stated on
   ProductPricingResponseModel (dod-dal-prd.lisp:1090-1099): the answer is a fact
   about the current date, not about the row, and a stored boolean would go stale
   the moment midnight passed. That is why there is no slot for it on the model
   and why the render-json allowlist below computes it rather than reading it.

   It is computed by the ONE predicate the checkout already uses
   (prdpricing-window-contains-p, promoted in SECTION 2), so the API and the till
   cannot drift apart — the same argument that promoted it out of the UI.

   A ROW WITH NO WINDOW IS 'EXPIRED', which is the answer the legacy checkout
   gives: discountexpired-p is (not (and (date>= today start) (date<= today end))),
   and a missing bound makes that AND nil. Answering false here would tell a client
   that a discount is live on a row with no dates to justify it."
  (let ((start (start-date r))
        (end   (end-date r)))
    (not (and start end (prdpricing-window-contains-p start end)))))

(defmethod render-json ((r ProductPricingResponseModel) (ctx domain-ctx))
  "One pricing row → JSON ALIST.

   The contract is split in this tree on purpose (conflodis2-json-text): a
   per-ENTITY method returns a Lisp structure while the per-LIST and sentinel
   methods return already-encoded text, and the dispatcher's render hop normalises
   the two. Returning encoded text here would make this method unusable to a
   caller composing an array itself.

   SECURITY CONTRACT: this alist IS the field allowlist and the last gate before
   the transport. It publishes NOTHING ProductPricingResponseModel does not
   declare — and that class declares no tenant-id, prc-company, created-at or
   deleted-state. The inherited boundary `id` is likewise NOT emitted, exactly as
   the class docstring demands (dod-dal-prd.lisp:1051-1054).

   IDS ARE STRINGS via response-id-string (dod-ui-utl.lisp), the one id convention
   for every entity: rowId/productId come from integer columns and may be NIL when
   unset, which the helper normalises to a string or to JSON null. Passing them
   raw would mix \"47\", 0 and null for the same kind of value.

   \"active\" RATHER THAN \"activeFlag\", and a BOOLEAN rather than the stored
   \"Y\"/\"N\": this endpoint sits under the products API and follows its
   convention (dod-bl-prd.lisp:1524-1529), not the warehouse's. The divergence is
   recorded there; unifying the two is a decision for whoever adds the first
   external consumer, not a change to smuggle in here.

   \"discountExpired\" IS PUBLISHED WITHOUT A SLOT, and that is the model's own
   instruction rather than a leak: see prdpricing-response-discount-expired-p. It
   is in the allowlist because it is DERIVED from two fields that are already in
   it, so it discloses nothing the caller does not already receive.

   A NIL discount crosses as JSON null, which is NOT the same statement as 0.00 —
   see prdpricing-validate-discount. The column's own default is 0.00, so null
   means 'never stated' while 0.00 means 'no discount'."
  (declare (ignore ctx))
  (list
   ;; IDENTITY — the address out, never an address in
   (cons "rowId"           (response-id-string (row-id r)))
   (cons "productId"       (response-id-string (product-id r)))
   ;; MONEY
   (cons "price"           (price r))
   (cons "discount"        (discount r))
   (cons "currency"        (currency r))
   ;; THE WINDOW — the period the DISCOUNT runs, not a price schedule
   (cons "startDate"       (prdpricing-date->string (start-date r)))
   (cons "endDate"         (prdpricing-date->string (end-date r)))
   ;; STATUS
   (cons "active"          (prd-flag->boolean (active-flag r)))
   (cons "discountExpired" (prdpricing-response-discount-expired-p r))))
