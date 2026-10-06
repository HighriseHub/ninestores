;;; nst-bl-vordh.lisp — the VENDOR ORDER's six प्रत्यय (S10)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; Design: aiharness/deepseek/skills/vendor-orders-adhara-CONTEXT.md (S9-S11, decisions V1-V10).
;;; The customer channel is order/nst-bl-ordh.lisp and the stories file; this file deliberately
;;; does NOT restate it. Where it borrows the header's machinery it says so.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHAT THIS FILE IS, AND THE FOUR THINGS THAT DIFFER FROM THE CUSTOMER CHANNEL
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; The six universal प्रत्यय over nst-vordh — ONE ROW PER (ORDER, VENDOR) of
;;; DOD_VENDOR_ORDERS. Belnap discipline as everywhere: every verb answers a real entity or an
;;; nst-entity-* sentinel, the tenant comes only from domain-ctx (नियम-1), and :U is never
;;; phrased as "not found".
;;;
;;; 1. THE ADDRESS IS THE ORDNUM, NOT A ROW-ID (V10). D3's vendor surface is
;;;    GET/PUT /vendor/orders/{ordnum}, and (ORDNUM, VENDOR_ID) is this row's natural key: the
;;;    customer's document number is denormalised into every vendor row (D20), and
;;;    uk_vo_order_vendor makes (ORDER_ID, VENDOR_ID) unique. Measured 2026-10-04: 466 rows,
;;;    460 distinct ORDNUMs — an order spanning two vendors legitimately shares ONE number, so
;;;    a fetch scoped by vendor alone resolves to at most one row, and an unscoped one would not.
;;;
;;;    ⚠ AC (e) IS THEREFORE STRUCTURAL, NOT A BRANCH. A row whose ORDNUM IS NULL can never
;;;    satisfy `[= [:ordnum] ordnum]`, so it is unreachable and the answer is :F → 404. There is
;;;    deliberately NO `OR ORDNUM IS NULL` fallback: 462 of the 462 pre-migration rows were NULL,
;;;    and a "best effort" address would have handed every vendor the same stranger's order.
;;;
;;; 2. THE SCOPE IS THREE-PART (V3): VENDOR_ID **and** TENANT_ID **and** DELETED_STATE in every
;;;    read. The vendor axis is new — a tenant-correct read can still be the WRONG VENDOR.
;;;    ⚠ WHERE THAT FILTER CAN LIVE IS FIXED BY THE GRAMMAR, and the split is stated rather than
;;;    glossed: the generics are `(fetch entity-class id ctx)` and `(delete! entity-class row-id
;;;    ctx)` — three fixed arguments, no &key — so a vendor-id CANNOT be passed to them. It is
;;;    therefore given where the generic permits it (`enumerate` and `?exists` take &key, and
;;;    `!update`'s &rest carries it), and for `fetch`/`delete!` the narrowing belongs to the ROUTE
;;;    layer, exactly as `ordh-header-from-url` narrows the customer channel today. S11 owns that
;;;    half; the residual risk (a direct caller of `fetch` that skips the route gets tenant scope
;;;    only) is real, stated, and the same one the customer channel already carries.
;;;
;;; 3. 🚨 ORD_DATE IS A `timestamp ... ON UPDATE CURRENT_TIMESTAMP` HERE — T9, and it is
;;;    VENDOR-ONLY (DOD_ORDER.ORD_DATE is a `date`). ANY update that omits it rewrites it to
;;;    now(), silently. AC (f) is the assertion that makes the corruption visible, and it is
;;;    satisfied BY CONSTRUCTION rather than by a statement: ord-date IS in
;;;    *vordh-mirrored-slots*, the copier walks that list, and the write is whole-row
;;;    (clsql:update-records-from-instance) — so the value that was READ is written BACK, and an
;;;    explicit assignment beats the auto-update. That only works because the class declares the
;;;    column `(string 30)` (V5): reading it as clsql:date would DROP THE TIME OF DAY and the
;;;    round trip would move the row to midnight while looking correct.
;;;
;;; 4. THE VENDOR IS AN EXTERNAL PARTY, SO THE FIELD POLICY IS NARROWER THAN THE CUSTOMER'S (V8).
;;;    The policy lists PARTITION the entity's slots EXACTLY, and the arithmetic is stated so the
;;;    offline check can hold it to account rather than trusting it:
;;;
;;;      13 stripped + 1 consumed-control + 4 caller-writable + 28 internal-only
;;;         + 16 never-writable          = 62 keys
;;;      = the 56 slots of nst-vordh (row-id + 55 business) + the 5 inherited reserved keys
;;;        + the 1 control key that is deliberately NOT a slot (:if-match).
;;;
;;;    A slot added to nst-vordh must be placed in one of the four, because an allowlist whose
;;;    default is ALLOW is not an allowlist.
;;;
;;; ── WHAT THIS FILE DELIBERATELY REUSES FROM THE CUSTOMER SIDE, AND WHY NOTHING IS COPIED ──
;;; nst-ordh-sort-column (its whitelist is already a parameter — S7 made it one for the line
;;; entity), nst-ordh-page-limit, nst-ordh-status-string, nst-ordh-internal-channel-p,
;;; nst-ordh-consume-control-key, nst-ordh-version-token, nst-ordh-if-match-value,
;;; nst-order-header-if-match-refusal (it reads the `updated` slot and this class has one),
;;; nst-ordh-json-flag, nst-ordh-json-date, response-id-string, and the shared
;;; *order-open-statuses*/*order-terminal-statuses* of core/dod-bl-utl.lisp. Two implementations
;;; of "what :asc means" or "which statuses are terminal" is how the two channels would come to
;;; disagree; there is one.

;;; ───────────────────────────────────────────────────────────────────────────
;;; Sorting, paging, and what may leave as JSON
;;; ───────────────────────────────────────────────────────────────────────────

(defparameter *vordh-sort-whitelist*
  '((:row-id . :row-id)
    (:ordnum . :ordnum)
    (:ord-date . :ord-date)
    (:expected-delivery-date . :expected-delivery-date)
    (:status . :status)
    (:order-amt . :order-amt)
    (:cust-name . :cust-name)
    (:created . :created))
  "The ONLY columns the vendor channel may sort by. sort-by arrives from an HTTP query string,
   so this list is what stands between that and arbitrary ORDER BY construction. Values are the
   CLSQL slot keywords of dod-vendor-order. Same columns as the header's list on purpose: a
   vendor's worklist and a customer's order list are read the same way, and two orderings of the
   same document would be a surprise rather than a feature.")

(defparameter *vordh-json-withheld-slots* '(deleted-state)
  "Slots the response model CARRIES and render-json does NOT publish. Documentary for the offline
   check, like the header's: the sums (mirrored = published + withheld) are asserted there, so a
   slot cannot quietly stop being sent. deleted-state is withheld on every channel in this
   batch — a vendor deciding its own row is invisible is not a vendor decision.")

;;; ───────────────────────────────────────────────────────────────────────────
;;; The field policy (V8) — four lists that PARTITION the entity's slots
;;; ───────────────────────────────────────────────────────────────────────────

(defparameter *vordh-update-stripped-initargs*
  '(:id :tenant-id :created-at :updated-at :deleted-state   ; the five the FERRY reserves
    :row-id                                                 ; the address
    :ordnum                                                 ; the customer's document number (D20)
    :context-id                                             ; the create's idempotency key
    :order-id :cust-id :vendor-id                           ; THE SCOPE AND THE PARTIES
    :created-by-user-id :approved-by-user-id)               ; session-derived audit
  "Keys !update drops silently, and this list is where AC (d) actually lives.

   ⚠ :vendor-id IS BOTH STRIPPED HERE AND READ AS SCOPE IN THE VERB, AND BOTH ARE NECESSARY. It
   is a real SLOT (the vendor axis), unlike :if-match which is a transport precondition and cannot
   be a slot at all — so it cannot live in *vordh-update-control-keys*, whose invariant is that
   none of its members is a slot (an offline check asserts exactly that). The verb therefore reads
   it off the RAW args, verifies it against the row, and then this strip makes it unassignable.
   Reading it first and stripping it after is the same order the header uses for :if-match, and
   for the same reason: a scope key that reached the field policy would be refused as an
   escalation, which would refuse every legitimate vendor update (the S12 defect).

   ⚠ THESE ARE STRIPPED, NOT REFUSED, AND THAT IS THE HEADER'S RULE FOR THE SAME REASON: :ordnum
   is the request's own ADDRESS on the routes D3 defines, and the parties and scope are what a
   session is narrowed BY — refusing either would refuse EVERY legitimate request. Stripping a key
   a caller may never assign satisfies AC (d) either way (the value cannot be set) and the reply
   returns the row's ACTUAL state, so an attempt is visible in the answer instead of believed.

   ⚠ THE FIVE RESERVED KEYS ARE THE POINT: *reserved-initargs* is applied by the FERRY
   (extract-domain-initargs), so a DIRECT call — a REPL, an :agent, a batch job — reaches this
   verb with whatever it likes. This guard closes that hole for every channel at once, because it
   runs in the verb." )

(defparameter *vordh-caller-writable-fields*
  '(:order-fulfilled          ; the vendor's own delivery fact
    :shipped-date
    :comments                 ; free text
    :external-url)            ; a tracking link the vendor owns
  "THE POSITIVE ALLOWLIST FOR AN EXTERNAL PARTY (V8), and it is deliberately four fields.

   WHAT IS NOT HERE IS THE DECISION, and each omission has a reason rather than an oversight:
     * MONEY — :order-amt, the five TOTAL_* columns, :shipping-cost, :tds-amount — is what the
       customer owes. A vendor that could rewrite it would be grading its own invoice; the figure
       is computed by the assembly from the vendor's own line totals and is not the vendor's to
       restate (F5, OWASP API3 mass assignment).
     * THE ADDRESSES ARE THE CUSTOMER'S, not the vendor's: the customer stated where the goods go
       and where they are billed. A vendor editing them edits the customer's instruction.
     * :status, :is-cancelled, :cancel-reason are LIFECYCLE, and a lifecycle moves through its own
       verb, never through a field assignment. D3 puts /fulfill and /cancel out of scope, so no
       channel in this batch writes them here — the vendor states the FACTS (:order-fulfilled,
       :shipped-date) and the transition is a later verb's business.
     * :is-converted-to-invoice/:invoice-number/:invoice-date are written by the invoice verb;
       :cust-name is denormalised from the customer row.

   ⚠ IF THIS IS TOO NARROW IT CAN BE WIDENED DELIBERATELY, ONE LINE AT A TIME, which is the whole
   point of enumerating positively: an omitted field is REFUSED (a bug the suite can see) instead
   of silently writable (a hole nobody notices).")

(defparameter *vordh-never-writable-fields*
  '(:cust-name                                               ; a copy of the customer's name
    :order-amt :total-taxable-value :total-cgst :total-sgst :total-igst :total-cess
    :total-tax :total-discount :shipping-cost :tds-amount    ; money, on every channel
    :is-converted-to-invoice :invoice-number :invoice-date   ; the order -> invoice link
    :is-cancelled :cancel-reason)                            ; cancellation is a verb
  "Fields NO channel may write through !update, internal ones included. Enforcement is by
   OMISSION from the two writable lists — this list exists so the partition is complete and the
   offline check can add the four up against the entity's slots, and so the refusal message can
   name the category a caller stumbled into rather than only the key.")

(defparameter *vordh-internal-only-fields*
  '(:ord-date :req-date :expected-delivery-date
    :order-type :order-source :status
    :ship-address-short :ship-addr-full :ship-city :ship-state :ship-zipcode
    :bill-address-short :bill-addr-full :bill-city :bill-state :bill-zipcode
    :country :bill-same-as-ship :storepickupenabled
    :gst-number :gst-org-name :place-of-supply :place-of-supply-code :supply-type
    :reverse-charge-applicable :eway-bill-required :tds-applicable
    :payment-mode)
  "Fields only an INTERNAL channel may write (:ui :agent :batch :scheduler). The schedule, the
   addresses, the tax identity and the place of supply are the customer's statements, stamped
   into this row by the D14 assembly; ops may correct them, a vendor session may not.

   ⚠ :ord-date IS HERE RATHER THAN IN THE VENDOR'S FOUR, and that is AC (f)'s own consequence
   read one step further: ORD_DATE auto-updates on ANY write and is the value the whole trap is
   about, so the one party who must never move it is the external one. The vendor cannot write
   the field that the database would silently move on its behalf.")

(defparameter *vordh-update-control-keys* '(:if-match)
  "Keys the verb CONSUMES and never assigns: transport preconditions, not entity state. They
   cannot be slots (reinitialize-instance would reject them), so the offline check asserts that
   none of them is a slot of nst-vordh.

   ⚠ :vendor-id IS NOT HERE, ALTHOUGH THE VERB CONSUMES IT THE SAME WAY. It is a real slot (the
   vendor axis), and this list's defining property is that its members are NOT slots — putting it
   here would either weaken that invariant to nothing or have the checker report a slot that
   legitimately exists. It lives in *vordh-update-stripped-initargs* instead, and the verb reads
   it off the raw args BEFORE the strip. Two keys, two mechanisms, chosen by what the key IS
   rather than by how it is used.

   ⚠ THEY CANNOT RIDE THE FERRY. request->dispatch hands !update
   (extract-domain-initargs rm entity-class), which forwards only keys the DOMAIN CLASS declares —
   so :if-match reaches this method only when the ROUTE calls the verb itself, and a route that
   forgets it loses the precondition silently.")

;;; ── the policy, as functions: one rule per question, each shallow enough to read ──

(defun nst-vordh-strip-identity-initargs (args)
  "ARGS without *vordh-update-stripped-initargs*. Pure: it returns a new plist, so the caller can
   still quote the original in a message. Not shared with the header's version, which reads the
   header's own list — two entities, two lists, and a shared function reading whichever list was
   in scope is how the pair would come to disagree."
  (loop for (k v) on args by #'cddr
        unless (member k *vordh-update-stripped-initargs*) append (list k v)))

(defun nst-vordh-writable-fields (channel)
  "The fields a caller on CHANNEL may write: the vendor's four, plus the internal-only set when
   the channel is inside the trust boundary. The membership test is the header's own
   nst-ordh-internal-channel-p, reused rather than restated: it reads ONE list of internal
   channels and fails closed for NIL and for anything unrecognised."
  (if (nst-ordh-internal-channel-p channel)
      (append *vordh-caller-writable-fields* *vordh-internal-only-fields*)
      *vordh-caller-writable-fields*))

(defun nst-vendor-order-field-refusal (args tenant-id channel)
  "NIL when every key in ARGS may be written on CHANNEL; otherwise the contradiction naming ALL
   the offending keys at once, with the category each one falls into.

   ALL OF THEM, not the first: a client that sent three fields it may not write should learn about
   three. Called AFTER the strip, so the identity and scope keys are already gone — and a key that
   is not a field of this entity at all lands here too, which is where it should land, because
   reinitialize-instance would otherwise RAISE on it and a raise reaches the boundary as a 500."
  (let* ((writable (nst-vordh-writable-fields channel))
         (bad (loop for (k v) on args by #'cddr
                    unless (member k writable) collect k)))
    (when bad
      (let ((never (intersection bad *vordh-never-writable-fields*))
            (internal (intersection bad *vordh-internal-only-fields*)))
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason (format nil "Vendor order update refused, and NOTHING has been written: the ~A channel may not write ~{~S~^, ~}.~@[ Not on any channel: ~{~S~^, ~} — the money, the order-to-invoice link and the cancellation state belong to their own verbs.~]~@[ Internal-only: ~{~S~^, ~} — the schedule, the addresses and the tax identity are the customer's statements, stamped by the create.~] Writable on this channel: ~{~S~^, ~}."
                                       (or channel :external)
                                       bad never internal writable))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; The selectors — every one of them scoped, and the scope is in the SQL
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; ⚠ DELETED_STATE IS `char(1) NOT NULL DEFAULT 'N'` ON THIS TABLE (measured), so the OR-pair
;;; the header needs for its nullable column is not needed here: [= [:deleted-state] "N"] is
;;; total. The pair is nonetheless spread over BOTH forms below, so a future migration that makes
;;; the column nullable cannot silently hide rows through one selector and not the other.

(defun nst-select-vendor-order-by-row-id (row-id tenant-id &key vendor-id include-deleted)
  "The live vendor order with ROW-ID in TENANT-ID, optionally narrowed to VENDOR-ID. Returns the
   row or NIL; a row of another tenant, another vendor, or a soft-deleted one is simply absent.
   ROW-ID is a unique key, not authorisation — the tenant and vendor predicates are the
   authorisation (the header's own rule, restated for a table with one more axis)."
  (car (clsql:select 'dod-vendor-order
                     :where (apply #'clsql:sql-and
                                   (remove nil
                                           (list [= [:row-id] row-id]
                                                 [= [:tenant-id] tenant-id]
                                                 (when vendor-id [= [:vendor-id] vendor-id])
                                                 (unless include-deleted
                                                   [= [:deleted-state] "N"]))))
                     :caching nil :flatp t)))

(defun nst-select-vendor-order-rows-by-ordnum (ordnum tenant-id &key vendor-id include-deleted)
  "EVERY row holding ORDNUM in TENANT-ID (optionally one vendor) — a LIST deliberately, because a
   caller must be able to see MORE THAN ONE. Unlike DOD_ORDER, more than one is NORMAL here: the
   number is the customer's, shared by every vendor row of that order (measured: 466 rows, 460
   distinct ORDNUMs). With VENDOR-ID supplied — which is the vendor channel's only address — the
   list is 0 or 1, and that is what makes AC (e) decidable.

   A row whose ORDNUM IS NULL cannot satisfy [= [:ordnum] ordnum] and is therefore unreachable
   here. That is AC (e) enforced by the address itself rather than by a branch that could be
   removed by accident."
  (clsql:select 'dod-vendor-order
                :where (apply #'clsql:sql-and
                              (remove nil
                                      (list [= [:ordnum] ordnum]
                                            [= [:tenant-id] tenant-id]
                                            (when vendor-id [= [:vendor-id] vendor-id])
                                            (unless include-deleted
                                              [= [:deleted-state] "N"]))))
                :caching nil :flatp t))

(defun nst-vendor-order-visible-row-p (row)
  "A row is visible when it is not soft-deleted. Mirrors nst-order-header-row-visible-p, and is
   the Lisp half of the SQL predicate above: used where a list was read WITHOUT the predicate so
   that a soft-deleted holder is still countable (see ?exists, where the difference between free
   and held is the whole answer)."
  (let ((state (slot-value row 'deleted-state)))
    (or (null state) (string= "N" state))))

(defun nst-build-vendor-order-filter-clauses (tenant-id vendor-id
                                              &key status ordnum-like cust-id from-date to-date
                                                   include-deleted)
  "The WHERE fragments of enumerate, IN ORDER: the scope first (tenant, vendor, live), then the
   caller's filters. Scope is not a filter — it is the boundary of the query — so it is written
   first and cannot be displaced by anything the caller sends."
  (let ((clauses (list [= [:tenant-id] tenant-id]
                       [= [:vendor-id] vendor-id])))
    (if include-deleted
        (push [or [= [:deleted-state] "N"] [is [:deleted-state] nil]] clauses)
        (push [= [:deleted-state] "N"] clauses))
    (when status
      (push [= [:status] (nst-ordh-status-string status)] clauses))
    (when cust-id
      (push [= [:cust-id] cust-id] clauses))
    (when ordnum-like
      ;; A prefix search, and the argument is the caller's text with the wildcard appended HERE:
      ;; a caller that could supply its own % would turn a prefix search into a scan of the table.
      (push [like [:ordnum] (concatenate 'string ordnum-like "%")] clauses))
    (when from-date
      (push [>= [:ord-date] from-date] clauses))
    (when to-date
      (push [<= [:ord-date] to-date] clauses))
    (nreverse clauses)))

(defun nst-select-vendor-orders-by-filter (tenant-id vendor-id
                                           &key status ordnum-like cust-id from-date to-date
                                                include-deleted
                                                (sort-by :ord-date) (sort-dir :desc)
                                                limit offset)
  "The vendor's worklist. sorting and the page bound are validated by the SHARED header helpers —
   nst-ordh-sort-column (whose whitelist is a parameter) and nst-ordh-page-limit — so the vendor
   channel cannot invent a second meaning for :asc or a second page cap."
  (multiple-value-bind (sort-col sort-dir) (nst-ordh-sort-column sort-by sort-dir *vordh-sort-whitelist*)
    (clsql:select 'dod-vendor-order
                  :where (apply #'clsql:sql-and
                                (nst-build-vendor-order-filter-clauses
                                 tenant-id vendor-id
                                 :status status :ordnum-like ordnum-like :cust-id cust-id
                                 :from-date from-date :to-date to-date
                                 :include-deleted include-deleted))
                  ;; row-id is the tie-breaker, not decoration: ord-date has SECOND resolution
                  ;; and a page boundary over equal values would repeat or skip rows.
                  :order-by (list (list sort-col sort-dir) (list :row-id :desc))
                  :limit (nst-ordh-page-limit limit)
                  :offset (or offset 0)
                  :caching *dod-database-caching*
                  :flatp t)))

;;; ───────────────────────────────────────────────────────────────────────────
;;; The copy ferries — LIST-DRIVEN, so they cannot be field-incomplete
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-copy-vendor-order-dbtodomain (source destination)
  "dod-vendor-order row -> nst-vordh, for row-id plus every mirrored slot."
  (setf (slot-value destination 'row-id) (slot-value source 'row-id))
  (dolist (f *vordh-mirrored-slots*)
    (setf (slot-value destination f) (slot-value source f)))
  destination)

(defun nst-copy-vendor-order-domaintodb (source destination)
  "nst-vordh -> dod-vendor-order row. ROW-ID is skipped (the DB mints it; a fetched row keeps it)
   and the tenant is pinned from the entity, so it can only ever have come from ctx.

   ⚠ ORD_DATE CROSSES HERE, AND THAT IS AC (f). Because the list carries it and the write is
   whole-row, the value read from the row is written back with it — which is what defeats
   ON UPDATE CURRENT_TIMESTAMP (T9). If ord-date were NOT in the list the column would auto-update
   on every vendor update, silently, and no offline check would see it: only the byte-identity
   assertion in S16 can.

   THE INTEGER -> FLOAT WIDENING IS LOAD-BEARING, not decoration: this class declares the money
   columns `float` and CLSQL VALIDATES a slot's declared type on INSERT/UPDATE, so an ordinary
   JSON integer ({orderAmt: 100}) would be refused by the client library and reach the caller as
   :U/503 'the database call did not answer' — a rupee order failing for looking whole. The 0.0
   class initforms cover the OMITTED field; nst-coerce-for-db-slot covers the SUPPLIED one, and
   fixing only one of the two leaves most requests failing."
  (dolist (f *vordh-mirrored-slots*)
  ;; ⚠ GUARDED: an optional field is UNBOUND on a fresh entity and `slot-value` SIGNALS on it.
  ;; See nst-db-slot-value-from-domain (core/dod-bl-utl.lisp).
    (setf (slot-value destination f)
          (nst-coerce-for-db-slot destination f
                                  (nst-db-slot-value-from-domain source f))))
  (setf (slot-value destination 'tenant-id) (slot-value source 'tenant-id))
  destination)

;;; ───────────────────────────────────────────────────────────────────────────
;;; ?exists — प्रत्यभिज्ञा: does THIS VENDOR already hold a row for ORDNUM?
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod ?exists ((entity-class (eql 'nst-vordh)) (ordnum string) (ctx domain-ctx)
                    &key vendor-id &allow-other-keys)
  "Is ORDNUM already this vendor's row, in the calling tenant? A BELNAP answer, because the
   honest one is not yes/no:

     :F  free — this vendor holds no row for that number, so a create may proceed
     :T  a LIVE row holds it (a fact of existence)
     :C  a SOFT-DELETED row holds it. Two of our own rules disagree: the row is present and
         occupies uk_vo_order_vendor, while नियम-2 makes DELETED_STATE='Y' rows invisible to every
         verb — so no row is there. It must NEVER be read as free: the INSERT would fail on the
         unique key. MORE THAN ONE live row is :C for the same reason it is in the header.
     :U  the database could not be consulted. NOT :F — creating on an unconfirmed identity is
         exactly how a duplicate gets written.

   ⚠ THE VENDOR IS A KEY HERE, NOT A FILTER, and that is the difference from the header's version:
   the header answers 'is the number taken in this tenant', which is the customer's identity
   question; this answers 'is the number taken BY THIS VENDOR', because (ORDNUM, VENDOR_ID) is the
   address and another vendor holding the same number is the normal case, not a collision.

   ⚠ WITHOUT :vendor-id THE ANSWER IS ABOUT THE TENANT, and it is therefore NOT a green light to
   insert: the caller that means to write must supply the vendor (the idempotency :around on
   `make` and the D14 assembly both do)."
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (handler-case
        (let ((rows (nst-select-vendor-order-rows-by-ordnum ordnum tenant-id
                                                            :vendor-id vendor-id
                                                            :include-deleted t)))
          (cond
            ((null rows)
             (make-bo-knowledge :truth :F :payload nil
                                :provenance "nst-vordh/?exists: no row holds this number for this vendor"))
            ((> (length rows) 1)
             (make-bo-knowledge :truth :C :payload rows
                                :provenance (format nil "nst-vordh/?exists: ~D rows hold this number for this vendor — uk_vo_order_vendor should make that impossible, so two sources disagree" (length rows))))
            ((every #'nst-vendor-order-visible-row-p rows)
             (make-bo-knowledge :truth :T :payload (car rows)
                                :provenance "nst-vordh/?exists: a live row holds this number for this vendor"))
            (t
             (make-bo-knowledge :truth :C :payload rows
                                :provenance "nst-vordh/?exists: the only holder is SOFT-DELETED, so no verb can see it while uk_vo_order_vendor still refuses a second insert"))))
      (error (c)
        (make-bo-knowledge :truth :U :payload nil
                           :provenance (format nil "nst-vordh/?exists: the database could not be consulted: ~A" c))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; make — सृष्टि: ONE ROW PER DISTINCT VENDOR, carrying the customer's ORDNUM (D20)
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; 🚨 THIS IS THE PROMOTION OF THE INTERIM WRITER, AND THE FILE IT LEAVES BEHIND IS THE POINT.
;;; Until this प्रत्यय existed, D14's assembly wrote the row with ordh-vendor-order-insert
;;; (order/nst-bl-ordhapi.lisp), a function whose own header says it is a debt with a name and
;;; that "this function then DELETES, it does not get called" once S9-S11 lands. The interim
;;; writer used the LEGACY 26-column class because it needed a class that day; this one uses
;;; nst-vordh's own 60-column class, which is what makes the columns the legacy never wrote —
;;; the four billing fields, the ship city/state/zipcode, the tax pair — writable at all.
;;;
;;; ⚠ WHAT THE INTERIM WRITER DID THAT THIS ONE MUST KEEP DOING: the row carries the minted
;;; ORDNUM (D20), the header's own dates, ONE vendor's line total in ORDER_AMT (not the order
;;; total), and the TENANT-ID of the session — never a vendor of another tenant (the legacy
;;; select-vendor-by-id has no tenant predicate at all; this one resolves the vendor through
;;; select-vendor-by-id-in-tenant, so the BOLA shape is not inherited).

(defparameter *vordh-forced-create-values*
  '((status . "PEN")
    (order-fulfilled . "N")
    (deleted-state . "N"))
  "Values a create FORCES regardless of what the caller sent, applied to the row immediately
   before the INSERT. PEN is the status every legacy creation path writes (DFT is the new API's
   header status, chosen by the header's own make) — a vendor row is not a document, it is one
   vendor's slice of one, and no channel in this batch moves it out of PEN except the fulfilment
   verb that does not exist yet. `fulfilled` and `deleted-state` are the column DEFAULTS written
   explicitly, so a row created here is indistinguishable from one the legacy wrote.")

(defun nst-vendor-order-insert (entity ctx)
  "ENTITY -> one row. Returns the entity with its row-id bound, or a sentinel.

   ⚠ TENANT-ID IS NOT A PARAMETER HERE, AND THAT IS DELIBERATE RATHER THAN AN OMISSION. The tenant
   travels on the ENTITY: nst-vendor-order-create builds it with
   (make-instance 'nst-vordh :tenant-id tenant-id …) from the ctx, and
   nst-copy-vendor-order-domaintodb PINS it from the entity — so there is exactly ONE source for it,
   which is नियम-1's rule ('the tenant can only ever come from domain-ctx').

   A second copy as an argument is a SECOND ANSWER to 'whose row is this', and the failure it hides
   is the quiet one: a caller whose tenant disagreed with the entity's would write a row whose
   TENANT_ID contradicts the very entity it was built from, and nothing in the path would complain.
   (The parameter was here and unused — SBCL reports that as a style warning — and REMOVING it is the
   fix rather than (declare (ignore tenant-id)), because the warning was pointing at a redundant
   carrier, not at noise. The sibling loop ordh-create-vendor-rows keeps tenant-id in ITS signature
   for a different reason: it is the assembly's own argument, and it says (declare (ignorable …))
   because the tenant reaches make through the ctx.)"
  (let ((row (make-instance 'dod-vendor-order)))
    (nst-copy-vendor-order-domaintodb entity row)
    (dolist (pair *vordh-forced-create-values*)
      (setf (slot-value row (car pair)) (cdr pair)))
    (let ((knowledge (with-nst-db-create (:source "nst-vordh/make")
                        (clsql:update-records-from-instance row)
                        row)))
      (case (bo-knowledge-truth knowledge)
        ;; ⚠ RETURN `entity`, NOT bind-generated-row-id's id STRING: the D14 assembly answers a bare id as
        ;; "469" and render-json, which has no method for a string, 500s after every write has landed.
        (:T (bind-generated-row-id entity (bo-knowledge-payload knowledge))
            entity)
        (:F ;; The INSERT itself was refused: a NOT NULL column, the composite unique key
            ;; uk_vo_order_vendor (one row per order+vendor), or the tenant foreign key.
            (domain-sentinel-from-knowledge
             knowledge ctx
             :reason (format nil "Vendor order create: the database refused the row for vendor ~A on order ~A. A row for that (order, vendor) pair may already exist, a NOT NULL column (ORDER_ID/CUST_ID/VENDOR_ID/ORD_DATE/REQ_DATE) may be missing, or the tenant may be wrong — see the provenance. NOTHING was written."
                             (vendor-id entity) (order-id entity))))
        (:U (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Vendor order create: the database call did not answer, so whether the row was written is UNKNOWN — this is not 'it failed'. Check whether the row exists before retrying: the unique key on (ORDER_ID, VENDOR_ID) makes the retry's outcome depend on whether the first attempt landed."))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create"
                          (bo-knowledge-truth knowledge)))))))

(defun nst-vendor-order-create (ctx tenant-id initargs)
  "The create as a SEQUENCE OF STEPS that each return early with a refusal, FLAT ON PURPOSE.
   Every refusal happens before any write, so a refused create has written nothing."
  ;; 1. the four keys without which there is no row to key on. The assembly supplies all four;
  ;;    a direct caller that omits one gets a contradiction rather than a row with a NULL party.
  (let ((order-id (getf initargs :order-id))
        (cust-id (getf initargs :cust-id))
        (vendor-id (getf initargs :vendor-id))
        (ordnum (getf initargs :ordnum)))
    (when (or (null order-id) (null cust-id) (null vendor-id))
      (return-from nst-vendor-order-create
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason "Vendor order create refused, and NOTHING has been written: :order-id, :cust-id and :vendor-id are all NOT NULL columns of DOD_VENDOR_ORDERS, and a row missing one of them cannot be addressed by the vendor channel or reached by the customer's order. These come from the assembly, which read them from the order being placed — a create that has to invent them is not the assembly.")))
    ;; 2. the ORDNUM must be the CUSTOMER'S, supplied by the header's create (D20). It is never
    ;;    minted here: two numbers for one order is the defect D20 exists to prevent.
    (when (or (null ordnum) (not (stringp ordnum)) (zerop (length ordnum)))
      (return-from nst-vendor-order-create
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason "Vendor order create refused, and NOTHING has been written: :ordnum is the CUSTOMER's document number, minted by the order header's own create and denormalised into every vendor row (D20). This verb does not mint one — a second number for one order is exactly what the vendor channel must not be able to produce.")))
    ;; 3. the vendor must be a LIVE VENDOR OF THIS TENANT (V3). The legacy writer's lookup has no
    ;;    tenant predicate at all; resolving here means a vendor row cannot name a stranger.
    (let ((knowledge (with-db-call (select-vendor-by-id-in-tenant vendor-id tenant-id)
                                   "nst-vordh/make (vendor-id, session tenant)")))
      (unless (eq (bo-knowledge-truth knowledge) :T)
        (return-from nst-vendor-order-create
          (if (eq (bo-knowledge-truth knowledge) :U)
              (domain-sentinel-from-knowledge
               knowledge ctx
               :reason (format nil "Vendor order create: the vendor behind row-id ~A could not be looked up — the database call did not answer, so whether this vendor exists in this tenant is UNKNOWN. NOTHING has been written." vendor-id))
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Vendor order create refused, and NOTHING has been written: vendor row-id ~A is not a live vendor of this tenant, so this row would have no seller to bill, no state to tax against, and nobody who could ever read it. That is the product's own data being inconsistent (nothing constrains PRODUCT.VENDOR_ID), and it is NOT this verb's to guess." vendor-id))))))
    ;; 4. build, force, insert
    ;; 4. build, force, insert. The tenant goes ON THE ENTITY here and nowhere else — see the note in
    ;;    nst-vendor-order-insert on why it is not also an argument.
    (let ((entity (apply #'make-instance 'nst-vordh :tenant-id tenant-id initargs)))
      (nst-vendor-order-insert entity ctx))))

(defmethod make :around ((entity-class (eql 'nst-vordh)) (ctx domain-ctx) &rest initargs)
  "IDEMPOTENCY: a create naming an (order-id, vendor-id) that already has a row returns THAT row
   instead of attempting a second one. This is what an :around is for — it can RETURN, where a
   :before could only raise, and a raise reaches the boundary as a 500.

   A retried assembly is not hypothetical: POST /orders writes one vendor row per distinct vendor
   and NOTHING in this batch is transactional (D14), so a client that times out and retries would
   otherwise meet uk_vo_order_vendor as a raw INSERT failure — turning a successful order into a
   500 on the second attempt, after the header and its lines were already written.

   ⚠ THE KEY IS THE TABLE'S OWN UNIQUE KEY, not a caller-supplied context: (ORDER_ID, VENDOR_ID)
   is exactly what uk_vo_order_vendor constrains, so the check and the constraint cannot drift."
  (let ((order-id (getf initargs :order-id))
        (vendor-id (getf initargs :vendor-id)))
    (if (or (null order-id) (null vendor-id))
        (call-next-method)
        (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
               (row (car (clsql:select 'dod-vendor-order
                                       :where [and [= [:order-id] order-id]
                                                   [= [:vendor-id] vendor-id]
                                                   [= [:tenant-id] tenant-id]]
                                       :caching nil :flatp t))))
          (if (null row)
              (call-next-method)
              (let ((entity (make-instance 'nst-vordh :tenant-id tenant-id)))
                (nst-copy-vendor-order-dbtodomain row entity)
                entity))))))

(defmethod make ((entity-class (eql 'nst-vordh)) (ctx domain-ctx) &rest initargs)
  "Create one vendor row in the SESSION tenant, carrying the caller's ORDNUM. See the file header
   for why the refusal is an :around and why the number is never minted here."
  (nst-vendor-order-create ctx (slot-value (domain-ctx-tenant ctx) 'row-id) initargs))

;;; ───────────────────────────────────────────────────────────────────────────
;;; fetch — अनुविद्या: by ROW-ID, scoped. The route resolves {ordnum}.
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod fetch ((entity-class (eql 'nst-vordh)) (id string) (ctx domain-ctx))
  "One vendor order by ROW-ID, in the session tenant and not soft-deleted.

   ⚠ THE ADDRESS ON THE WIRE IS THE ORDNUM, NOT THIS ROW-ID, and the translation belongs to the
   route (S11), not here. The grammar's generic is (fetch entity-class id ctx) — three arguments
   with no &key — so a VENDOR cannot be passed to this method at all; the vendor narrowing for
   this path is the route's, done by resolving (ordnum, session vendor) to a row-id through
   nst-select-vendor-order-rows-by-ordnum, which is the only function that can enforce the second
   axis on that path.

   ⚠ AN UNPARSABLE OR ABSENT ID IS :F, NEVER AN ERROR: a client that composes a URL by hand
   should get a 404, not a 500 naming a Lisp type."
  (let ((row-id (nst-row-id-from-string id))
        (tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (if (null row-id)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "No vendor order with the id ~S is addressable from this session: it is not a row-id. On this channel the address is the customer's ORDNUM, which the route resolves to a row-id before calling this verb." id))
        (let ((knowledge (with-db-call (nst-select-vendor-order-by-row-id row-id tenant-id)
                                       "nst-vordh/fetch (row-id, session tenant)")))
          (case (bo-knowledge-truth knowledge)
            (:T (let ((entity (make-instance 'nst-vordh :tenant-id tenant-id)))
                  (nst-copy-vendor-order-dbtodomain (bo-knowledge-payload knowledge) entity)))
            (:F (make-instance 'nst-entity-nil
                               :tenant-id tenant-id
                               :reason "No live vendor order with that id is addressable from this session. Whether the row-id is wrong, held by another tenant or another vendor, soft-deleted, or belongs to an order whose ORDNUM is NULL is deliberately not distinguished — a 403 here would confirm that somebody else's row exists."))
            (otherwise (domain-sentinel-from-knowledge
                        knowledge ctx
                        :reason "Vendor order fetch: the database did not answer, so whether this row exists is UNKNOWN. This is not 'not found'.")))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; enumerate — गणना: the vendor's own worklist (AC c)
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod enumerate ((entity-class (eql 'nst-vordh)) (ctx domain-ctx)
                      &key vendor-id status ordnum-like cust-id from-date to-date include-deleted
                        (sort-by :ord-date) (sort-dir :desc) limit offset)
  "The vendor's worklist: ONLY this vendor's rows in this tenant, newest first by ORD_DATE.

   ⚠ AC (c) IS ENFORCED HERE, IN THE BL, AND THAT IS DELIBERATE. :vendor-id is REQUIRED for a
   meaningful answer, and its absence is a REFUSAL rather than an unfiltered list: an enumerate
   without it is not 'all vendors', it is the cross-vendor read F2 warned about, and every caller
   in this batch has the value (the route reads it from the session). Failing closed here means
   no future caller can obtain the cross-vendor list by simply forgetting an argument.

   An empty page is a LEGAL answer and comes back as '() — a 200 with [] — never a 404: the
   vendor's list is a view, not a document, and 'you have no orders yet' is not 'no such thing'."
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (if (null vendor-id)
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason "Vendor order list refused: enumerate on this channel is scoped to ONE vendor, and :vendor-id was not supplied. This is not an empty list and not a list of every vendor's orders — a cross-vendor read in one tenant is exactly what the vendor channel must not be able to perform (V3). The route reads the vendor from the session and passes it here.")
        (let ((knowledge (with-nst-db-read-all (:source "nst-vordh/enumerate"
                                                :pk-extractor (lambda (d) (slot-value d 'row-id)))
                            (nst-select-vendor-orders-by-filter
                             tenant-id vendor-id
                             :status status :ordnum-like ordnum-like :cust-id cust-id
                             :from-date from-date :to-date to-date
                             :include-deleted include-deleted
                             :sort-by sort-by :sort-dir sort-dir
                             :limit limit :offset offset))))
          (case (bo-knowledge-truth knowledge)
            (:T (mapcar (lambda (row)
                          (let ((entity (make-instance 'nst-vordh :tenant-id tenant-id)))
                            (nst-copy-vendor-order-dbtodomain row entity)))
                        (bo-knowledge-payload knowledge)))
            (:F '())
            (otherwise (domain-sentinel-from-knowledge
                        knowledge ctx
                        :reason "Vendor order list: the database did not answer, so this page is UNKNOWN — not empty. An empty list would tell the vendor it has no orders, which is a different and dangerous claim.")))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; !update — !state प्रत्यय: AC (d) scope is immovable, AC (g) terminal is frozen,
;;; AC (f) ORD_DATE is byte-identical
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-vendor-order-update-write (ctx tenant-id dbobj args)
  "Hydrate, apply only the supplied fields, write every mirrored slot back, answer in
   four-valued terms. Extracted so the caller reads as a list of steps rather than a staircase —
   depth is where paren errors live.

   ⚠ THE WRITE IS WHOLE-ROW, DELIBERATELY, AND HERE THAT IS AC (f)'s MECHANISM. clsql's
   update-records-from-instance writes every column of the instance; the instance was hydrated
   FROM the row it writes back, and ord-date is in *vordh-mirrored-slots* — so ORD_DATE is
   re-assigned with the value it already holds and MySQL's ON UPDATE CURRENT_TIMESTAMP does not
   fire (an explicit assignment beats the auto-update; omission does not). UPDATED is likewise
   not in the list, so it keeps its own ON UPDATE and advances — which is the other half of
   AC (f)."
  (let ((entity (make-instance 'nst-vordh :tenant-id tenant-id)))
    (nst-copy-vendor-order-dbtodomain dbobj entity)     ; hydrate current state
    (apply #'reinitialize-instance entity args)         ; CLOS partial update
    (nst-copy-vendor-order-domaintodb entity dbobj)
    (let ((knowledge (with-nst-db-update (:source "nst-vordh/!update")
                        (clsql:update-records-from-instance dbobj)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T entity)
        (:F ;; Unreachable: no :pre-flight was supplied, so with-nst-db-update cannot produce :F.
            (error "Unreachable: with-nst-db-update without :pre-flight cannot return :F (vendor order row-id ~A)"
                   (slot-value dbobj 'row-id)))
        (:U (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Vendor order update: the database call did not answer, so whether the row was written is UNKNOWN — this is not 'it failed'. The row may hold either the old or the new values; re-read it before deciding. NOTE for THIS table: a re-read cannot tell you whether ORD_DATE moved, because an unanswered write may have fired the column's ON UPDATE — compare it against the value the caller held."))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-update"
                          (bo-knowledge-truth knowledge)))))))

(defun nst-vendor-order-update (ctx tenant-id channel dbobj update-args)
  "The update as a SEQUENCE OF STEPS that each return early with a refusal, FLAT ON PURPOSE.
   Every refusal happens before any write, so a refused update has written nothing."
  ;; 1. the status gate (AC g): a terminal slice is a finished document
  (let ((status (nst-ordh-status-string (slot-value dbobj 'status))))
    (when (member status *order-terminal-statuses* :test #'string=)
      (return-from nst-vendor-order-update
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason (format nil "Vendor order update refused: this vendor's slice of the order is ~A, which is terminal, so its content is frozen. Nothing has been written. Measured on the live table: 387 of 466 vendor rows are CMP and 4 are VCN, so this is the ordinary case, not a corner — a completed or cancelled slice is a finished record, and the way to change what it says is a new document, not an edit to this one."
                                       (or status (slot-value dbobj 'status)))))))
  ;; 2. the control keys come out FIRST — :if-match and :vendor-id are not entity state, and the
  ;;    field policy below must never see them (the S12 defect: policy-first refused :if-match as
  ;;    an escalation, and would refuse a scope key the same way).
  (multiple-value-bind (expected args) (nst-ordh-consume-control-key update-args :if-match)
    (multiple-value-bind (scope-vendor args) (nst-ordh-consume-control-key args :vendor-id)
      ;; 3. the scope, when the caller supplied one. A route passes the session's vendor here, so
      ;;    AC (d)'s 'cannot move a row to another vendor' is enforced at the verb as well as at
      ;;    the address — belt and braces, because a direct caller skips the route.
      (when (and scope-vendor (not (eql scope-vendor (slot-value dbobj 'vendor-id))))
        (return-from nst-vendor-order-update
          (make-instance 'nst-entity-nil
                         :tenant-id tenant-id
                         :reason "No live vendor order with that number is addressable from this session. The row exists, but it belongs to another vendor: this is a vendor route and a vendor order row belongs to the session's vendor (V3). Whether the number is wrong, held by another tenant, or another vendor's slice is deliberately not distinguished — a 403 here would confirm that another vendor's row exists.")))
      (let ((args (nst-vordh-strip-identity-initargs args)))
        ;; 4. what this channel may write
        (let ((refusal (nst-vendor-order-field-refusal args tenant-id channel)))
          (when refusal (return-from nst-vendor-order-update refusal)))
        ;; 5. the version precondition, if the route supplied one
        (let ((refusal (nst-order-header-if-match-refusal dbobj expected tenant-id)))
          (when refusal (return-from nst-vendor-order-update refusal)))
        ;; 6. hydrate, apply, write, answer
        (nst-vendor-order-update-write ctx tenant-id dbobj args)))))

(defmethod !update ((entity-class (eql 'nst-vordh)) (row-id string) (ctx domain-ctx)
                    &rest update-args)
  "Assign fields on an existing vendor order. A PARTIAL update: the row is selected and hydrated,
   then reinitialize-instance applies only the initargs actually supplied, so an omitted field
   keeps its stored value instead of being reset to its class default.

   THE ORDER OF THE FIVE QUESTIONS: is there such a row (absence first — a 404 is about the
   ADDRESS, and a caller that named a row which is not there should not be lectured about field
   policy); is the caller's vendor this row's vendor (a fact about SCOPE); is it terminal (a fact
   about the ROW); may this channel write these fields (a fact about the REQUEST); does the
   caller's validator match (a fact about TIMING). A refusal at any step writes nothing.

   ⚠ THE FRESH VALIDATOR IS NOT RETURNED, and that is the header's decision copied rather than
   re-litigated: UPDATED is DB-managed and the instance in hand holds the PRE-write value, so a
   token read from it would be STALE. The route re-reads when it wants to emit a new ETag."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (channel (domain-ctx-channel ctx))
         (rid (nst-row-id-from-string row-id)))
    (if (null rid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "No vendor order with the id ~S is updatable from this session: it is not a row-id. On this channel the address is the customer's ORDNUM, which the route resolves to a row-id before calling this verb." row-id))
        (let ((dbobj (nst-select-vendor-order-by-row-id rid tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason "No live vendor order with that id is updatable from this session. Whether the row-id is wrong, held by another tenant or another vendor, soft-deleted, or belongs to an order whose ORDNUM is NULL is deliberately not distinguished.")
              (nst-vendor-order-update ctx tenant-id channel dbobj update-args))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; ───────────────────────────────────────────────────────────────────────────
;;; लोप for a whole order's VENDOR ROWS — called by the HEADER's delete!
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-select-vendor-orders-for-header (order-id tenant-id)
  "Every LIVE vendor row of ORDER-ID in TENANT-ID, in row-id order. TENANT-ID is a predicate as well
   as ORDER-ID, so a guessed order-id yields an empty list rather than another tenant's rows."
  (clsql:select 'dod-vendor-order
                :where (apply #'clsql:sql-and
                              (remove nil (list [= [:order-id] order-id]
                                                [= [:tenant-id] tenant-id]
                                                [= [:deleted-state] "N"])))
                :order-by (list (list :row-id :asc))
                :caching nil :flatp t))

(defun nst-soft-delete-vendor-orders-for-header (order-id tenant-id)
  "लोप for the VENDOR ROWS of order ORDER-ID: mark every live row DELETED_STATE='Y'; :T carries the number of rows
   marked (0 is a success), a non-:T carries the tally in its provenance. Why it exists, measured 2026-10-05: the
   header's delete! cascaded to its LINES only, so a VENDOR kept working on an order its customer had deleted, and
   no FK can do it (DOD_VENDOR_ORDERS has no FK on ORDER_ID; a cascade fires on a HARD delete, never a soft one)."
  (let ((rows (nst-select-vendor-orders-for-header order-id tenant-id))
        (done 0))
    (dolist (row rows)
      (let ((knowledge (with-nst-db-delete (:source "nst-vordh/soft-delete-for-header")
                          (setf (slot-value row 'deleted-state) "Y")
                          (clsql:update-record-from-slot row 'deleted-state)
                          row)))
        (unless (eq (bo-knowledge-truth knowledge) :T)
          (return-from nst-soft-delete-vendor-orders-for-header
            (make-bo-knowledge
             :truth (bo-knowledge-truth knowledge)
             :payload nil
             :provenance (format nil "nst-vordh/soft-delete-for-header: ~A of ~A vendor row(s) of order row-id ~A were already marked DELETED_STATE='Y' before the failure at vendor row-id ~A — ~A"
                                 done (length rows) order-id (slot-value row 'row-id)
                                 (knowledge-provenance-text knowledge)))))
        (incf done)))
    (make-bo-knowledge :truth :T :payload done
                       :provenance (format nil "nst-vordh/soft-delete-for-header: ~A live vendor row(s) of order row-id ~A soft-deleted"
                                           done order-id))))

;;; delete! — अपगम: INTERNAL ONLY (V9), and it exists for the grammar's sake
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; ⚠ D3 BINDS NO DELETE ROUTE ON THE VENDOR CHANNEL, AND THAT IS THE INTENT, NOT AN OMISSION.
;;; The six प्रत्यय are universal — an entity that lacks one cannot be driven by the generic
;;; machinery — but a vendor erasing its own slice of a placed order would delete the row the
;;; CUSTOMER's order is accounted for by (ORDER_AMT per vendor is what the customer's totals are
;;; built from). So the verb exists, refuses every external channel, and serves the internal ones
;;; that need a cleanup path. A vendor that stops supplying an order CANCELS it (VCN) — a
;;; cancellation keeps the history the row exists to keep.

(defparameter *vordh-deletable-statuses* '("PEN")
  "Only an UNFINISHED slice may be soft-deleted. The header's equivalent list is '(\"DFT\") with a
   comment that adopting D8's reading would make it DFT and PEN; for a vendor row the analogue of
   an unstarted document is PEN, because DFT is never written here (see
   *vordh-forced-create-values*) — a list naming a status this table cannot hold would be a guard
   that can never fire, which is worse than no guard because it reads like one.")

(defun nst-vendor-order-soft-delete (ctx tenant-id channel dbobj)
  "Soft-delete ONE vendor row: DELETED_STATE 'Y', a single-column write (never the whole row, so
   the ORD_DATE auto-update cannot fire on a delete — there is nothing to re-assign because
   nothing else is written). Every refusal happens before the write."
  (let ((status (nst-ordh-status-string (slot-value dbobj 'status))))
    ;; 1. external parties may not delete another party's accounting row (V9)
    (unless (nst-ordh-internal-channel-p channel)
      (return-from nst-vendor-order-soft-delete
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason (format nil "Vendor order delete refused, and NOTHING has been deleted: the ~A channel is outside the trust boundary, and a vendor row is one vendor's slice of a CUSTOMER's order — the customer's own records are built from these amounts. A vendor that stops supplying an order cancels it, and /cancel is out of this batch's scope. Nothing on this channel is bound to a delete route (D3)."
                                       (or channel :external)))))
    ;; 2. an issued invoice is the record now
    (when (string= "Y" (or (slot-value dbobj 'is-converted-to-invoice) ""))
      (return-from nst-vendor-order-soft-delete
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason (format nil "Vendor order delete refused: this slice has been converted to invoice ~A, so the invoice is the record now and the row has to keep standing behind it. Nothing has been deleted. [LEGAL: the line the invoice batch draws at an issued invoice — an issued document is cancelled or credit-noted, never made never-to-have-existed.]"
                                       (slot-value dbobj 'invoice-number)))))
    ;; 3. only an unfinished slice
    (unless (member status *vordh-deletable-statuses* :test #'string=)
      (return-from nst-vendor-order-soft-delete
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason (format nil "Vendor order delete refused: this slice is ~A, and only ~{~A~^ or ~} may be deleted. Nothing has been deleted. A terminal slice has finished, and deleting it would hide a record the customer's order and possibly an invoice point at."
                                       (or status (slot-value dbobj 'status))
                                       *vordh-deletable-statuses*))))
    ;; 4. the write
    (let ((knowledge (with-nst-db-delete (:source "nst-vordh/delete!")
                        (setf (slot-value dbobj 'deleted-state) "Y")
                        (clsql:update-record-from-slot dbobj 'deleted-state)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T t)
        (:U (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Vendor order delete: the database call did not answer, so whether the row was marked deleted is UNKNOWN — this is not 'it failed'. Re-read it before telling anybody it is gone."))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-delete"
                          (bo-knowledge-truth knowledge)))))))

(defmethod delete! ((entity-class (eql 'nst-vordh)) (row-id string) (ctx domain-ctx))
  "Soft-delete one vendor row. Answers T on success — the ack shape the shared route layer ferries.
   The channel guard is INSIDE nst-vendor-order-soft-delete and is the first thing it asks: this
   verb is reachable by a direct caller (a REPL, a batch job) that never passes a route, so the
   external refusal cannot live in the route."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (channel (domain-ctx-channel ctx))
         (rid (nst-row-id-from-string row-id)))
    (if (null rid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "No vendor order with the id ~S is deletable from this session: it is not a row-id." row-id))
        (let ((dbobj (nst-select-vendor-order-by-row-id rid tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason "No live vendor order with that id is deletable from this session. A row that is already soft-deleted is absent here for the same reason it is absent everywhere: नियम-2 makes DELETED_STATE='Y' invisible to every verb.")
              (nst-vendor-order-soft-delete ctx tenant-id channel dbobj))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; domain->response — nst-vordh → NstVordhResponseModel (the reverse ferry)
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; THIS HOP MIRRORS: every declared slot crosses, driven by the same *vordh-mirrored-slots* the
;;; two copy ferries use, so the response shape cannot drift from the entity. The decision that
;;; matters is which fields LEAVE THE SYSTEM, and that allowlist is render-json below, where it
;;; belongs. It is list-driven, which is the shape that took the invoice API down — a slot in the
;;; list but missing from the boundary class signals MISSING-SLOT on EVERY response, and
;;; compile-file cannot see it. tools/nst-vordh-mirror-check.lisp performs this exact setf for
;;; every slot, offline.

(defmethod domain->response ((entity nst-vordh) (ctx domain-ctx))
  (let ((destination (make-instance 'NstVordhResponseModel)))
    (setf (slot-value destination 'row-id) (row-id entity))
    (dolist (slot *vordh-mirrored-slots*)
      (setf (slot-value destination slot) (slot-value entity slot)))
    destination))

;;; ───────────────────────────────────────────────────────────────────────────
;;; render-json — NstVordhResponseModel. THIS METHOD IS the outbound field allowlist.
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; SECURITY CONTRACT: a slot added to NstVordhResponseModel does NOT auto-leak — it must be named
;;; here, and if it is meant to stay inside it must be named in *vordh-json-withheld-slots* so the
;;; sums still add up (mirrored = published + withheld). Three conventions, taken from the header
;;; because they were measured there rather than guessed:
;;;
;;;   * IDENTIFIERS leave as JSON strings via response-id-string (NIL → null), because row-id /
;;;     order-id / cust-id / vendor-id are integers in the row and the wire would otherwise mix
;;;     47, "47" and null for the same kind of value;
;;;   * DATE columns leave as YYYY-MM-DD — and for THIS entity ord-date/req-date/shipped-date are
;;;     (string 30) over `timestamp` columns (V5), so they are truncated to their date part rather
;;;     than reformatted: the first ten characters, which is exact for the format MySQL returns.
;;;     expected-delivery-date and invoice-date are real `date` columns and go through the shared
;;;     date renderer;
;;;   * tinyint(1) columns leave through nst-ordh-json-flag, and char(1) Y/N flags leave as the
;;;     CODES THE COLUMN STORES. Two conventions, stated, because applying the boolean guard to a
;;;     Y/N column would report N as true.
;;;
;;; ⚠ THE VENDOR SEES THE CUSTOMER'S NUMBER (D20) AND THE CUSTOMER'S NAME, BY DESIGN. F1 was
;;; resolved on this point: a vendor holding …-00001 and later …-00005 can infer orders with
;;; competitors, which is a commercial-confidentiality question that was decided deliberately, not
;;; an oversight. Removing the field here would break the vendor's only way to quote the order the
;;; customer telephones about.

(defun nst-vordh-json-timestamp-date (value)
  "A (string 30) timestamp value as YYYY-MM-DD, or NIL. VALUE is what MySQL returned for the
   column, so the date part is its first ten characters; anything shorter is returned as it is
   rather than guessed at, and NIL stays NIL (a NULL SHIPPED_DATE is 'not shipped yet', which is
   not the same fact as a date)."
  (cond ((null value) nil)
        ((stringp value) (subseq value 0 (min 10 (length value))))
        (t (nst-ordh-json-date value))))

(defmethod render-json ((r NstVordhResponseModel) (ctx domain-ctx))
  "One vendor order → a JSON alist. The list method in the shared route layer applies
   json:encode-json-to-string."
  (declare (ignore ctx))
  (list
   (cons "rowId"                   (response-id-string (row-id r)))
   ;; the document this slice belongs to — the customer's number, denormalised (D20)
   (cons "ordnum"                  (ordnum r))
   (cons "contextId"               (context-id r))
   ;; the slice's own key: which order, which customer, which vendor
   (cons "orderId"                 (response-id-string (order-id r)))
   (cons "custId"                  (response-id-string (cust-id r)))
   (cons "custName"                (cust-name r))
   (cons "vendorId"                (response-id-string (vendor-id r)))
   ;; dates
   (cons "ordDate"                 (nst-vordh-json-timestamp-date (ord-date r)))
   (cons "reqDate"                 (nst-vordh-json-timestamp-date (req-date r)))
   (cons "shippedDate"             (nst-vordh-json-timestamp-date (shipped-date r)))
   (cons "expectedDeliveryDate"    (nst-ordh-json-date (expected-delivery-date r)))
   (cons "orderType"               (order-type r))
   (cons "orderSource"             (order-source r))
   ;; document state — char(3)/char(1) CODES, not booleans
   (cons "status"                  (status r))
   (cons "orderFulfilled"          (order-fulfilled r))
   (cons "isConvertedToInvoice"    (is-converted-to-invoice r))
   (cons "isCancelled"             (is-cancelled r))
   (cons "invoiceNumber"           (invoice-number r))
   (cons "invoiceDate"             (nst-ordh-json-date (invoice-date r)))
   (cons "cancelReason"            (cancel-reason r))
   ;; who touched it
   (cons "createdByUserId"         (response-id-string (created-by-user-id r)))
   (cons "approvedByUserId"        (response-id-string (approved-by-user-id r)))
   ;; where it goes, and where it is billed
   (cons "shipAddressShort"        (ship-address-short r))
   (cons "shipAddrFull"            (ship-addr-full r))
   (cons "shipCity"                (ship-city r))
   (cons "shipState"               (ship-state r))
   (cons "shipZipcode"             (ship-zipcode r))
   (cons "billAddressShort"        (bill-address-short r))
   (cons "billAddrFull"            (bill-addr-full r))
   (cons "billCity"                (bill-city r))
   (cons "billState"               (bill-state r))
   (cons "billZipcode"             (bill-zipcode r))
   (cons "country"                 (country r))
   (cons "billSameAsShip"          (bill-same-as-ship r))
   (cons "storePickupEnabled"      (storepickupenabled r))
   ;; tax identity and place of supply — the vendor IS the place of supply
   (cons "gstNumber"               (gst-number r))
   (cons "gstOrgName"              (gst-org-name r))
   (cons "placeOfSupply"           (place-of-supply r))
   (cons "placeOfSupplyCode"       (place-of-supply-code r))
   (cons "supplyType"              (supply-type r))
   (cons "reverseChargeApplicable" (nst-ordh-json-flag (reverse-charge-applicable r)))
   (cons "ewayBillRequired"        (nst-ordh-json-flag (eway-bill-required r)))
   (cons "tdsApplicable"           (nst-ordh-json-flag (tds-applicable r)))
   (cons "tdsAmount"               (tds-amount r))
   ;; money — THIS VENDOR's slice, never the order total
   (cons "orderAmt"                (order-amt r))
   (cons "totalTaxableValue"       (total-taxable-value r))
   (cons "totalCgst"               (total-cgst r))
   (cons "totalSgst"               (total-sgst r))
   (cons "totalIgst"               (total-igst r))
   (cons "totalCess"               (total-cess r))
   (cons "totalTax"                (total-tax r))
   (cons "totalDiscount"           (total-discount r))
   (cons "shippingCost"            (shipping-cost r))
   ;; free text and presentation
   (cons "comments"                (comments r))
   (cons "externalUrl"             (external-url r))
   (cons "paymentMode"             (payment-mode r))))
