;;; nst-bl-orditm.lisp — Tier-1 प्रत्यय for the ORDER LINE (nst-orditm)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; S7 of the orders batch. Design: aiharness/deepseek/skills/order-adhara-stories-CONTEXT.md
;;;
;;; The six universal प्रत्यय of core/nst-bl-adhara.lisp, specialized on nst-orditm:
;;;
;;;   make       सृजन          add a line to an OPEN order
;;;   fetch      स्मरण          recall one line by row-id
;;;   enumerate  दर्शन          list a header's lines, or the session tenant's
;;;   !update    !state         assign columns on an existing line
;;;   delete!    लोप            SOFT delete, and only while the order is open
;;;   ?exists    प्रत्यभिज्ञा   does this order already carry this product
;;;
;;; A LINE LIVES INSIDE A DOCUMENT, AND EVERY VERB PROVES THE DOCUMENT EXISTS. No verb here
;;; acts on a line without first selecting the order it belongs to through
;;; nst-fetch-visible-order-header — scoped by the SESSION tenant, never by anything the
;;; caller sent. That is the whole authorization model for this entity: :order-id is a
;;; caller-supplied integer, so a verb that trusted it would expose another tenant's order
;;; lines to anyone who guessed a number (OWASP API1:2023, BOLA). The extra SELECT per verb
;;; is the price and it is not negotiable.
;;;
;;; ⚠ AND THE DATABASE WILL NOT CATCH IT FOR US, WHICH IS MEASURED RATHER THAN ASSUMED.
;;; SHOW INDEX and information_schema.KEY_COLUMN_USAGE on the live DOD_ORDER_ITEMS
;;; (2026-09-28) show: PRIMARY (ROW_ID), TENANT_ID, idx_order, idx_vendor, idx_product,
;;; idx_hsn — no unique key anywhere — and exactly ONE foreign key, TENANT_ID →
;;; DOD_COMPANY.ROW_ID. NOTHING constrains ORDER_ID, VENDOR_ID or PRD_ID. So a line pointing
;;; at an order that does not exist, or at another tenant's order, is a row MySQL stores
;;; happily; the parent proof below is the only thing between a guessed :order-id and another
;;; tenant's lines.
;;;
;;; ⚠ AND NOTHING CASCADES EITHER, FOR THE SAME MEASURED REASON — there is no ON DELETE
;;; CASCADE on this table to fire. The order's delete! therefore calls the लोप helper at the
;;; bottom of this file EXPLICITLY, lines first and header last. S5's delete! docstring said a
;;; cascade existed and did nothing; that sentence was copied from the invoice's comment
;;; instead of measured here, and S7 corrects it.
;;;
;;; THE STATUS RULE, and why it is not simply the header's rule:
;;;
;;;   make / delete!   RESTRUCTURE the document → refused unless the header is OPEN
;;;                    (*order-open-statuses* = DFT and PEN, core/dod-bl-utl.lisp). Adding a
;;;                    line to a completed order changes what was ordered; removing one is what
;;;                    a cancellation is for.
;;;   !update          corrects a VALUE on the line → no status gate HERE, because the terminal
;;;                    gate belongs to the HEADER verb (D8: content may change at any status
;;;                    except terminal) and a line is reachable only through its header. The
;;;                    parent proof still refuses a header this tenant cannot see or that has
;;;                    been soft-deleted, which is the reachability half.
;;;
;;; NOT DONE HERE, ON PURPOSE:
;;;   * NO TOTALS ROLL-UP. Adding, changing or removing a line does NOT touch the header's
;;;     ORDER_AMT/TOTAL_* — D13's deliberate gap, restated: a completed order's total agreeing
;;;     with its lines belongs to `invoice`, and a roll-up here would not close it, because a
;;;     direct header !update can set any total it likes.
;;;   * no line-level route-* verbs and no register-api-route bindings (S12/S13).
;;;   * no check-niyam call — as in nst-whs and nst-invh; नियम-1 is enforced by the
;;;     tenant-scoped SELECTs.
;;;
;;; MUTUAL REFERENCE WITH nst-bl-ordh.lisp: the header's delete! calls
;;; nst-soft-delete-order-items-for-header (the लोप helper at the bottom of this file), and
;;; every verb here calls the header's nst-select-order-header-by-row-id and reads
;;; *order-open-statuses*. Lisp resolves both directions at run time, and BOTH build lists place
;;; nst-bl-ordh before this file, so every header symbol used here is already defined when this
;;; file compiles: the build's single undefined-function style-warning is the header's
;;; reference to the one helper defined below, which is the whole cost of the mutual reference
;;; (story S7 AC (e)).

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;; ───────────────────────────────────────────────────────────────────────────
;;; Policy constants
;;; ───────────────────────────────────────────────────────────────────────────

(defparameter *orditm-sort-whitelist*
  '((:row-id . :row-id)
    (:prd-id . :prd-id)
    (:hsn-code . :hsn-code)
    (:prd-qty . :prd-qty)
    (:taxablevalue . :taxablevalue)
    (:totalitemval . :totalitemval))
  "The ONLY columns enumerate may sort by — the same guard as the header's, for the same
   reason: sort-by is caller-controllable, so a raw column name must never reach ORDER BY.

   Unlike the header's whitelist, the Lisp-side names and the CLSQL slot keywords are the same
   string here, because dod-order-items declares its slots with kebab names of the columns
   (order-id, prd-id, hsn-code) — the header's view class is the one that RENAMES
   (SHIP_ADDRESS is ship-address-short). Written out anyway, so a rename on either side has to
   be typed here rather than silently inheriting a wrong mapping.")

(defparameter *orditm-json-withheld-slots* '(deleted-state)
  "Response-model slots that must NOT leave the system (S6's pattern, applied to the line).
   deleted-state is नियम-2's own predicate rather than domain state, and the header withholds
   exactly the same slot for exactly the same reason. The offline check asserts
   published + withheld = every slot of NstOrditmResponseModel, so a slot added to that class
   later forces a decision instead of silently never leaving the system.")

;;; ───────────────────────────────────────────────────────────────────────────
;;; Small helpers
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-order-item-id-from-value (value)
  "Coerce a caller-supplied id to an integer, or NIL when it cannot be one. Used for :order-id
   and prd-id, which reach a verb as an integer (a JSON number) or as a string (a path param, a
   query string, a JSON string) depending on the transport.

   ⚠ NOT nst-row-id-from-string, WHICH IS STRING-ONLY BY DESIGN: that one answers the ROW-ID
   path parameter, where a non-string is a malformed request rather than a value to interpret.
   Using it here would answer 'not a product row-id' to a perfectly good JSON integer 42 — a
   wrong :F, which is the one answer a Belnap layer must never invent. (The invoice keeps the
   same distinction as invitm-id-from-value; consolidating the two belongs with the row-id
   guard on the ledger.)"
  (cond ((null value) nil)
        ((integerp value) value)
        ((stringp value) (nst-row-id-from-string value))
        (t nil)))

;;; ───────────────────────────────────────────────────────────────────────────
;;; The parent proof — ONE function, so a new verb cannot invent a weaker check
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-fetch-visible-order-header (order-id tenant-id)
  "The document ORDER-ID as THIS TENANT may see it, or the reason there is none. Returns a
   bo-knowledge: :T payload = the header DB object; :F absent, soft-deleted, or another
   tenant's; :U the database did not answer; :C more than one row for a primary key.

   IT DELEGATES TO THE HEADER FILE'S SELECTOR, which already excludes soft-deleted rows with
   the [or [= deleted-state N] [is deleted-state nil]] clause, so 'this order is gone' and
   'this order is not yours' arrive as the same absence fact — correct for authorization (a 404
   either way, and NOT a 403 that would confirm the row exists) and documented rather than left
   to be inferred.

   It deliberately takes no status: the status rules differ per verb, so the caller applies its
   own to the payload. That is the invoice item's shape, kept because it is what stops two
   verbs from disagreeing about what 'open' means."
  (with-db-call (nst-select-order-header-by-row-id order-id tenant-id)
                "nst-orditm/parent-header"))

;;; ───────────────────────────────────────────────────────────────────────────
;;; Query functions — every read is tenant-scoped by construction
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-build-order-item-filter-clauses (tenant-id &key order-id status include-deleted)
  "WHERE clauses for order-line queries, always tenant-scoped.

  ⚠ DELETED_STATE IS char(1) DEFAULT NULL ON THIS TABLE TOO (measured: Null=YES, Default=NULL)
  — the same trap as the header's: BOTH NULL and N occur in the live data, so a bare [= … N]
  hides rows and [= … nil] renders the literal NULL, which is true for no row at all. Hence
  [is … nil], which renders IS NULL."
  (let ((clauses (list [= [:tenant-id] tenant-id])))
    (unless include-deleted
      (push [or [= [:deleted-state] "N"]
                [is [:deleted-state] nil]] clauses))
    (when order-id (push [= [:order-id] order-id] clauses))
    (when status (push [= [:status] (nst-ordh-status-string status)] clauses))
    clauses))

(defun nst-select-order-items-by-filter (tenant-id &key order-id status include-deleted
                                                   (sort-by :row-id) (sort-dir :asc)
                                                   limit offset)
  "Order lines matching the filters, in a STABLE order.

  ⚠ THE SECONDARY ORDER BY ROW-ID IS PART OF PAGINATION, for S4's reason: sorting by prd-id,
  hsn-code or an amount TIES (the same product or HSN on many lines), and an ORDER BY with ties
  has no defined order between pages — an offset reader can then see one line twice and never
  see another. The primary key makes the sequence total, which is what makes :offset safe.
  (The default sort IS row-id asc, so it is total already; the secondary key costs one term.)

  THE PAGE LIMIT REUSES THE HEADER'S (*ordh-page-limit*: default 50, hard cap 200, capped
  rather than refused). F7 is a property of the ENDPOINT, not of the header table: the
  tenant-wide form of this query reads 1180 live lines today and grows with every order, so it
  needs exactly the same bound."
  (multiple-value-bind (sort-col sort-dir)
      (nst-ordh-sort-column sort-by sort-dir *orditm-sort-whitelist*)
    (clsql:select 'dod-order-items
                  :where (apply #'clsql:sql-and
                                (nst-build-order-item-filter-clauses
                                 tenant-id :order-id order-id
                                           :status status
                                           :include-deleted include-deleted))
                  :order-by (list (list sort-col sort-dir) (list :row-id :asc))
                  :limit (nst-ordh-page-limit limit)
                  :offset (or offset 0)
                  :caching *dod-database-caching* :flatp t)))

(defun nst-select-order-items-for-header (order-id tenant-id &key include-deleted)
  "Every line of order ORDER-ID in TENANT-ID, in row-id order (insertion order — the order the
   customer typed them, and the order an order prints).

  INCLUDE-DELETED decides the question, as in the header's selects:
    NIL — the order's LIVE lines (what a read or a re-total must see)
    T   — every line it ever had (what a 'did this order have lines?' audit asks, because a
          soft-deleted line keeps its row)

  Thin delegate, kept as its own name because it is the entry point the header's लोप helper
  reads its work from. Scoped by TENANT-ID as well as ORDER-ID, so a guessed order-id yields an
  empty list rather than another tenant's rows.

  ⚠ IT CARRIES THE PAGE CAP, AND THAT CAP IS A BOUND ON A READ RATHER THAN A CLAIM ABOUT DATA:
  *ordh-page-max-limit* (200) lines. An order with more lines than that would need paging, and
  the लोप helper states the consequence for its own use of this function."
  (nst-select-order-items-by-filter tenant-id :order-id order-id
                                               :include-deleted include-deleted
                                               :limit *ordh-page-max-limit*))

(defun nst-select-order-item-by-row-id (id tenant-id)
  "One LIVE line by primary key, in this tenant. ID is an INTEGER here — the string guard
   belongs to the verbs, which must answer :F for an unparsable id before any query runs, or
   (parse-integer \"abc\") raises, with-db-call catches it as :U, and a malformed request is
   reported as 503.

   ⚠ THE DELETED_STATE CLAUSE IS NOT OPTIONAL and it is the OR form: a soft-deleted line must
   not come back as a live one, or delete! could delete a deleted row and !update could write
   one, while नियम-2 says a Y row is invisible to every verb. (The header's selector shipped
   without this clause once — S5 found it.)"
  (car (clsql:select 'dod-order-items :where
                     [and
                      [= [:tenant-id] tenant-id]
                      [= [:row-id] id]
                      [or [= [:deleted-state] "N"]
                          [is [:deleted-state] nil]]]
                     :caching nil :flatp t)))

(defun nst-select-order-items-by-prd-id (prd-id order-id tenant-id)
  "The live line this order carries for this product, or NIL.

  NOT a uniqueness query, and it must never be read as one: the live DOD_ORDER_ITEMS has NO
  unique key on (ORDER_ID, PRD_ID) — measured, SHOW INDEX returns only PRIMARY, TENANT_ID,
  idx_order, idx_vendor, idx_product and idx_hsn, none of them unique — and the same product on
  two lines is a legitimate order (a different rate, discount, batch or HSN). This answers the
  question a form asks before adding a product ('is this already on the order?'), where :T is a
  WARNING, not a refusal.

  The CAR is honest because the caller only asks WHETHER any such line exists; any surplus IS
  the duplication being asked about."
  (car (clsql:select 'dod-order-items :where
                     [and [= [:order-id] order-id]
                          [= [:prd-id] prd-id]
                          [= [:tenant-id] tenant-id]
                          [or [= [:deleted-state] "N"]
                              [is [:deleted-state] nil]]]
                     :caching nil :flatp t)))

;;; ───────────────────────────────────────────────────────────────────────────
;;; Copy helpers — LIST-DRIVEN, like the header's, for the same reason
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-copy-order-item-dbtodomain (source destination)
  "dod-order-items row -> nst-orditm, for row-id plus every mirrored slot."
  (setf (slot-value destination 'row-id) (slot-value source 'row-id))
  (dolist (f *orditm-mirrored-slots*)
    (setf (slot-value destination f) (slot-value source f)))
  destination)

(defun nst-copy-order-item-domaintodb (source destination)
  "nst-orditm -> dod-order-items row. ROW-ID is skipped (the DB mints it; a fetched row keeps
   it), and the tenant is pinned from the entity, so it can only ever have come from ctx.

   ⚠ THE INTEGER → FLOAT WIDENING IS LOAD-BEARING, and this table is where the invoice batch
   MEASURED the defect it fixes: dod-order-items declares sixteen float columns — unit-price,
   mrp, the four rates, the six amounts, taxablevalue, totalitemval — and CLSQL VALIDATES a
   slot's declared type, so an ordinary JSON integer ({unitPrice: 100}) is refused by the
   client library and reaches the caller as :U/503 'the database call did not answer'. The
   class initforms cover the OMITTED field; this covers the SUPPLIED one, and fixing only one of
   the two leaves most requests failing. nst-coerce-for-db-slot reads the DESTINATION CLASS's
   declared type, so it stays right if a column is retyped — and it lives in
   core/dod-bl-utl.lisp (moved there in S7) because the header's copier needs it too and the
   order files load before the invoice's."
  (dolist (f *orditm-mirrored-slots*)
    (setf (slot-value destination f)
          (nst-coerce-for-db-slot destination f (slot-value source f))))
  (setf (slot-value destination 'tenant-id) (slot-value source 'tenant-id))
  destination)

;;; ───────────────────────────────────────────────────────────────────────────
;;; ?exists — प्रत्यभिज्ञा
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; ⚠ THIS IS NOT AN IDENTITY CHECK, AND make DOES NOT CALL IT. A line has no natural key: the
;;; same product twice on one order is legitimate, the schema carries no UNIQUE constraint on
;;; (ORDER_ID, PRD_ID), and no rule makes the pair unique. So the four states below answer a
;;; QUESTION a form wants to ask, not a law the database enforces — the exact opposite of
;;; nst-ordh's ?exists, whose :T drives the make :around's refusal. Do not copy that shape here.

(defmethod ?exists ((entity-class (eql 'nst-orditm)) (prd-id t) (ctx domain-ctx)
                    &key order-id &allow-other-keys)
  "Does the order ORDER-ID already carry a LIVE line for product PRD-ID? Belnap answer:
     :T  yes — a warning for a form, never a reason to refuse (see above)
     :F  no such line. NOTE: this is the answer whether the order is absent, empty, or simply
         lacks this product, and also when PRD-ID cannot be an integer at all — none of those
         can hold a matching line. A caller MUST NOT read :F as 'the order exists' (use
         nst-fetch-visible-order-header for that).
     :U  the question could NOT be formed, or the database did not answer. Two different causes
         share the state because they share the consequence — we know nothing, so ':F, no
         duplicate' would be a fabrication. The provenance says which.
   &key order-id is REQUIRED for a usable answer: the question is order-relative.
   &allow-other-keys is CLOS congruence with the generic function's lambda list."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (pid (nst-order-item-id-from-value prd-id))
         (rid (nst-order-item-id-from-value order-id)))
    (cond
      ((null rid)
       (make-bo-knowledge
        :truth :U :payload nil
        :provenance "nst-orditm/?exists: no usable :order-id — a line's existence is a question about ONE order, so it cannot be answered without one"))
      ((null pid)
       ;; The product id cannot address a product row, so no line can match it.
       (make-bo-knowledge
        :truth :F :payload nil
        :provenance (format nil "nst-orditm/?exists: ~S is not a product row-id" prd-id)))
      (t
       (with-db-call (nst-select-order-items-by-prd-id pid rid tenant-id)
                     "nst-orditm/?exists (prd-id, order-id, tenant)")))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; make — सृजन
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-order-item-insert (ctx tenant-id order-id args)
  "Build, copy, INSERT, answer in four-valued terms. The last step of a create, extracted so
   the caller reads as a list of steps rather than a staircase — depth is where paren errors
   live (nst-bl-ordh.lisp's header records the two-surplus-closers afternoon that proved it)."
  (let ((entity (apply #'make-instance 'nst-orditm
                       :tenant-id tenant-id :order-id order-id args))
        (dbobj (make-instance 'dod-order-items)))
    (setf (slot-value entity 'deleted-state) "N")
    (nst-copy-order-item-domaintodb entity dbobj)
    (let ((knowledge (with-nst-db-create (:source "nst-orditm/make")
                        (clsql:update-records-from-instance dbobj)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T (bind-generated-row-id entity (bo-knowledge-payload knowledge))
            entity)
        (:F ;; No unique key guards a line, so a :F here is the INSERT itself being refused: a
            ;; NOT NULL column with no default — ORDER_ID, VENDOR_ID, PRD_ID (measured: all
            ;; three NOT NULL) — or the tenant foreign key. The database names the offender and
            ;; that reason is the useful part.
            (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Order line create: the database refused the row (a NOT NULL column such as ORDER_ID/VENDOR_ID/PRD_ID, or the tenant foreign key) — see the provenance"))
        (:U (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Order line create: the database call did not answer, so the row may or may not have been written — this is UNKNOWN, not failed"))
        (:C (error "Unreachable: no :pre-flight form is supplied to with-nst-db-create in nst-orditm/make — a :C means the macro contract changed"))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create"
                          (bo-knowledge-truth knowledge)))))))

(defun nst-order-item-create (ctx tenant-id order-id initargs)
  "The parent proof, the status gate and the insert — flat, each step returning early.

   THE CALLER'S :order-id IS DISCARDED ONCE VERIFIED, and the verified integer is used instead,
   so a string id cannot reach the database as a string and an unverified one cannot reach the
   row. That is the authorization step, and it is why make takes the id twice (once to prove,
   once to stamp)."
  (let ((head (nst-fetch-visible-order-header order-id tenant-id)))
    (unless (eq (bo-knowledge-truth head) :T)
      ;; :F (no such order in this tenant — or its lines are not yours to see) and :U (the
      ;; database did not answer) both arrive here and STAY DISTINCT: the first is a 404, the
      ;; second a 503, and conflating them is the bug the four-valued layer exists to prevent.
      (return-from nst-order-item-create
        (domain-sentinel-from-knowledge
         head ctx
         :reason (format nil "Order line create: order row-id ~A is not a document this tenant can see" order-id))))
    (let* ((header (bo-knowledge-payload head))
           (status (nst-ordh-status-string (slot-value header 'status))))
      (unless (member status *order-open-statuses* :test #'string=)
        (return-from nst-order-item-create
          (make-instance 'nst-entity-contradiction
                         :tenant-id tenant-id
                         :reason (format nil "Order row-id ~A is ~A, which is not an OPEN status (~{~A~^, ~}) — a line may only be added while the order is still being built. A completed, vendor-cancelled or customer-cancelled order is a finished document; its contents move by a new document, not by added lines."
                                         order-id (or status (slot-value header 'status))
                                         *order-open-statuses*))))
      (let ((args (loop for (k v) on initargs by #'cddr
                        unless (eq k :order-id) append (list k v))))
        (nst-order-item-insert ctx tenant-id order-id args)))))

(defmethod make ((entity-class (eql 'nst-orditm)) (ctx domain-ctx) &rest initargs)
  "Add a line to an OPEN order.

  THERE IS NO :around METHOD HERE, unlike nst-ordh's make. The header's :around exists for
  IDEMPOTENCY and because the header MINTS an identity; a line has neither a minted identity nor
  a dangerous repeat — the same product twice is legal (see ?exists), and a repeated POST is a
  data question rather than a request to refuse. The header's :around reads :context-id, which a
  line does not have.

  WHAT IS ENFORCED, in this order, before anything is written:
    1. :order-id must address a row (an integer, or a string that parses to one) — otherwise we
       cannot name a document at all → nst-entity-nil → 404;
    2. that document must be VISIBLE IN THIS TENANT (absent, soft-deleted, or another tenant's
       all answer the same way: nst-entity-nil → 404);
    3. its status must be in *order-open-statuses* → otherwise nst-entity-contradiction → 409.

  Everything else comes from the caller or from the class initforms. The NOT NULL columns with
  no default are refused by the database with the column named — the honest place for that rule,
  as in nst-whs.

  TENANT-ID comes from ctx, always, and is never read from initargs."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (rid (nst-order-item-id-from-value (getf initargs :order-id))))
    (if (null rid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address an order header row (row-ids are integers), so there is no order to add a line to"
                                       (getf initargs :order-id)))
        (nst-order-item-create ctx tenant-id rid initargs))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; fetch — स्मरण
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-order-item-hydrate (ctx tenant-id dbobj)
  "The parent proof plus the hydrate — shared by fetch and !update, so two verbs cannot
   disagree about how a line becomes an entity, or about when its order is invisible.

   A row whose header is soft-deleted or another tenant's must NOT come back as a found line: it
   would be content of a document the caller cannot see, which is exactly the orphan state the
   header's लोप ordering is designed to make unreachable. It is refused explicitly rather than
   assumed impossible, because the header's delete! can fail part-way (see its docstring) and a
   refusal is cheaper than trusting that it never happened."
  (let* ((order-id (slot-value dbobj 'order-id))
         (head (nst-fetch-visible-order-header order-id tenant-id)))
    (if (not (eq (bo-knowledge-truth head) :T))
        (domain-sentinel-from-knowledge
         head ctx
         :reason (format nil "Order line row-id ~A belongs to order row-id ~A, which this tenant cannot see (soft-deleted, or another tenant's) — a line is only reachable through its order"
                         (slot-value dbobj 'row-id) order-id))
        (let ((entity (make-instance 'nst-orditm :tenant-id tenant-id)))
          (nst-copy-order-item-dbtodomain dbobj entity)
          entity))))

(defmethod fetch ((entity-class (eql 'nst-orditm)) (id string) (ctx domain-ctx))
  "Recall one line by row-id, in the session tenant, AND prove its order is still visible.
   Returns a real nst-orditm or a Belnap sentinel — never a bare NIL.

  ANOTHER TENANT'S ROW-ID ANSWERS :F — not :U and not a permission error. Authorization here is
  per-object by construction: the SELECT carries tenant-id, so the row is simply not there. That
  is OWASP API1:2023 (BOLA) answered by the shape of the query rather than by a check somebody
  can forget."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (row-id (nst-row-id-from-string id)))
    (if (null row-id)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address an order line row (row-ids are integers)" id))
        (let ((knowledge (with-db-call (nst-select-order-item-by-row-id row-id tenant-id)
                                       "nst-orditm/fetch (row-id, session tenant)")))
          (if (not (eq (bo-knowledge-truth knowledge) :T))
              ;; :F (no such line here) and :U (the boundary did not answer) stay distinct, with
              ;; per-state wording — a :U is never phrased as 'not found'.
              (domain-sentinel-from-knowledge
               knowledge ctx
               :reason (lambda (truth)
                         (case truth
                           (:F (format nil "Order line row-id ~A not found in this tenant" row-id))
                           (:U (format nil "Order line row-id ~A: the database call did not answer — whether the line exists is unknown" row-id))
                           (:C (format nil "Order line row-id ~A returned more than one row — the primary key is not holding" row-id)))))
              (nst-order-item-hydrate ctx tenant-id (bo-knowledge-payload knowledge)))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; !update — !state प्रत्यय
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-order-item-update-write (ctx tenant-id dbobj args)
  "Hydrate, apply only the supplied fields, write the whole row back, answer in four-valued
   terms. The write is WHOLE-ROW on purpose: the instance was hydrated from the row it writes
   back, so an unlisted column is written with the value it already had, and a concurrent change
   to a column this call did not name is the only thing that could be lost (the header's F8
   If-Match is the answer to that, and it is on the header verb)."
  (let ((entity (make-instance 'nst-orditm :tenant-id tenant-id)))
    (nst-copy-order-item-dbtodomain dbobj entity)      ; hydrate current state
    (apply #'reinitialize-instance entity args)        ; CLOS partial update
    (nst-copy-order-item-domaintodb entity dbobj)
    (let ((knowledge (with-nst-db-update (:source "nst-orditm/!update")
                        (clsql:update-records-from-instance dbobj)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T entity)
        (:F (error "Unreachable: with-nst-db-update without :pre-flight cannot return :F (order line row-id ~A)"
                   (slot-value dbobj 'row-id)))
        (:U (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Order line update: the database call did not answer, so whether the row was written is UNKNOWN — re-read it before deciding."))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-update"
                          (bo-knowledge-truth knowledge)))))))

(defun nst-order-item-update (ctx tenant-id dbobj args)
  "The parent proof, then the write — flat, so the method above stays a list of steps."
  (let ((hydrated (nst-order-item-hydrate ctx tenant-id dbobj)))
    (if (not (typep hydrated 'nst-orditm))
        hydrated
        (let ((clean (loop for (k v) on args by #'cddr
                           unless (eq k :row-id) append (list k v))))
          (nst-order-item-update-write ctx tenant-id dbobj clean)))))

(defmethod !update ((entity-class (eql 'nst-orditm)) (row-id string) (ctx domain-ctx)
                    &rest update-args)
  "Assign columns on an existing line. A PARTIAL update: the row is selected, hydrated, then
   reinitialize-instance applies only the initargs supplied, so an omitted field keeps its
   stored value instead of reverting to its class default.

  NO ORDER-STATUS GATE HERE, and that is the header verb's job rather than an omission: D8
  allows content to change at any status except terminal, and the HEADER's !update is where the
  terminal refusal lives. A line is reachable only through its header, so a caller cannot reach
  a terminal order's line without the header check having been available to them; and the parent
  proof still refuses a header this tenant cannot see or that has been soft-deleted, which is
  the reachability half. (The invoice item's file splits the same way, as 'content vs values'.)

  :ORDER-ID IS REFUSED (nst-entity-contradiction → 409), AND THAT IS S7's AC (d). A line does
  not migrate between orders: moving one changes two orders' contents at once, bypasses both
  headers' status rules, and — because :order-id is caller-supplied — would be the easiest way
  to push rows at another tenant's order. The correct operation is to delete the line and create
  it on the other order, which runs both checks. A caller that means 'this line is already on
  the right order' simply omits the key.

  ⚠ THE ROUTE MUST STRIP IT AFTER VERIFYING THE PAIRING, EXACTLY AS route-invitm-update DOES FOR
  :invheadid — because PUT /orders/{ordnum}/items/{item-id} carries the ORDER in its ADDRESS, so
  a resolver that passes the verified header id into the ferry would otherwise be refused here on
  every legitimate request. The invoice batch MEASURED that failure mode on this same shape: a
  guard that refuses the key the URL names 'refuses every legitimate request — which is exactly
  what happened the first time this was written' (nst-bl-invhapi.lisp:377-383). The route
  verifies the pair and then strips; this verb keeps the guarantee for every caller that bypasses
  the route. S12/S13 own that half, and it is recorded here because the failure is invisible from
  this file."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (row-id-int (nst-row-id-from-string row-id)))
    (cond
      ((null row-id-int)
       (make-instance 'nst-entity-nil
                      :tenant-id tenant-id
                      :reason (format nil "~S does not address an order line row (row-ids are integers)" row-id)))
      ((getf update-args :order-id)
       (make-instance 'nst-entity-contradiction
                      :tenant-id tenant-id
                      :reason "An order line does not move between orders — delete the line and create it on the other order, so both headers' status rules run. Nothing has been written."))
      (t
       (let ((dbobj (nst-select-order-item-by-row-id row-id-int tenant-id)))
         (if (null dbobj)
             (make-instance 'nst-entity-nil
                            :tenant-id tenant-id
                            :reason (format nil "Order line row-id ~A not found in this tenant, or already soft-deleted" row-id))
             (nst-order-item-update ctx tenant-id dbobj update-args)))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; delete! — लोप प्रत्यय (soft, and only while the order is open)
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-order-item-soft-delete (ctx tenant-id row-id dbobj)
  "The parent proof, the status gate and the write — flat, each step returning early."
  (let* ((order-id (slot-value dbobj 'order-id))
         (head (nst-fetch-visible-order-header order-id tenant-id)))
    (unless (eq (bo-knowledge-truth head) :T)
      (return-from nst-order-item-soft-delete
        (domain-sentinel-from-knowledge
         head ctx
         :reason (format nil "Order line delete, row-id ~A: its order row-id ~A is not visible to this tenant — a line is only deleted through its order"
                         row-id order-id))))
    (let* ((header (bo-knowledge-payload head))
           (status (nst-ordh-status-string (slot-value header 'status))))
      (unless (member status *order-open-statuses* :test #'string=)
        (return-from nst-order-item-soft-delete
          (make-instance 'nst-entity-contradiction
                         :tenant-id tenant-id
                         :reason (format nil "Order row-id ~A is ~A, which is not an OPEN status (~{~A~^, ~}) — a line may only be removed while the order is still being built. Nothing has been deleted. A completed order is a finished document; removing its content is what a cancellation is for."
                                         order-id (or status (slot-value header 'status))
                                         *order-open-statuses*)))))
    (let ((knowledge (with-nst-db-delete (:source "nst-orditm/delete!")
                        (setf (slot-value dbobj 'deleted-state) "Y")
                        (clsql:update-record-from-slot dbobj 'deleted-state)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T t)
        (:F (error "Unreachable: with-nst-db-delete without :pre-flight cannot return :F (order line row-id ~A)" row-id))
        (:U (domain-sentinel-from-knowledge
             knowledge ctx
             :reason (format nil "Order line delete, row-id ~A: the database call did not answer — whether the line was soft-deleted is unknown" row-id)))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-delete"
                          (bo-knowledge-truth knowledge)))))))

(defmethod delete! ((entity-class (eql 'nst-orditm)) (row-id string) (ctx domain-ctx))
  "Soft-delete ONE line. Sets its DELETED_STATE='Y'; the row is never removed, and नियम-2 hides
   it from every verb afterwards.

  TWO REFUSALS THAT ARE ABSENCES (:F → 404), both answered rather than raised:
    * the id does not address a row; or
    * no such LIVE line in this tenant — so a REPEAT delete answers 'not found', not 'already
      deleted'. Those are the same fact (there is no live line here), and nst-whs's delete!
      collapses them the same way.

  AND ONE THAT IS NOT:
    * an order status outside *order-open-statuses* → nst-entity-contradiction → 409. The line is
      there and readable; what contradicts the request is that removing content from a completed
      order is what a cancellation is for.

  NOT DONE: the header's totals are not adjusted (D13), and this does NOT go through
  nst-soft-delete-order-items-for-header — that function is the HEADER's लोप (many rows, one
  document), while this is one row of a document the caller named."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (row-id-int (nst-row-id-from-string row-id)))
    (if (null row-id-int)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address an order line row (row-ids are integers)" row-id))
        (let ((dbobj (nst-select-order-item-by-row-id row-id-int tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Order line row-id ~A not found in this tenant, or already soft-deleted" row-id))
              (nst-order-item-soft-delete ctx tenant-id row-id-int dbobj))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; enumerate — दर्शन प्रत्यय
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-order-item-list (ctx tenant-id rid status include-deleted
                                sort-by sort-dir limit offset)
  "The optional parent proof and the filtered read — flat.

  :order-id IS VERIFIED WHEN GIVEN, so a caller who names an order that is absent, soft-deleted
  or another tenant's gets a 404 rather than an empty list. 'That order has no lines' and 'there
  is no such order for you' are different answers, and an empty list would collapse them."
  (when rid
    (let ((head (nst-fetch-visible-order-header rid tenant-id)))
      (unless (eq (bo-knowledge-truth head) :T)
        (return-from nst-order-item-list
          (domain-sentinel-from-knowledge
           head ctx
           :reason (format nil "Order line enumerate: order row-id ~A is not a document this tenant can see" rid))))))
  (let ((knowledge (with-nst-db-read-all
                       (:source "nst-orditm/enumerate"
                        :pk-extractor (lambda (d) (slot-value d 'row-id)))
                     (nst-select-order-items-by-filter
                      tenant-id :order-id rid :status status
                                :include-deleted include-deleted
                                :sort-by sort-by :sort-dir sort-dir
                                :limit limit :offset offset))))
    (case (bo-knowledge-truth knowledge)
      (:T (mapcar (lambda (dbobj)
                    (let ((entity (make-instance 'nst-orditm :tenant-id tenant-id)))
                      (nst-copy-order-item-dbtodomain dbobj entity)
                      entity))
                  (bo-knowledge-payload knowledge)))
      (:F '())
      (:C (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (format nil "Order line enumerate, tenant ~A: the result set contained duplicate primary keys — a data integrity issue; investigate DOD_ORDER_ITEMS directly"
                           tenant-id)))
      (otherwise (domain-sentinel-from-knowledge
                  knowledge ctx
                  :reason (format nil "Order line enumerate, tenant ~A: the database call did not answer — the line list contents are unknown"
                                  tenant-id))))))

(defmethod enumerate ((entity-class (eql 'nst-orditm)) (ctx domain-ctx)
                      &key order-id status include-deleted
                           (sort-by :row-id) (sort-dir :asc) limit offset)
  "List order lines within the session tenant.

  WITH :order-id — the normal use — the ORDER IS VERIFIED FIRST (see nst-order-item-list), so a
  404 is distinguishable from an empty page.

  WITHOUT :order-id — every live line in the tenant, which is what a product-wise or HSN-wise
  summary reads. Deliberately allowed, still tenant-scoped by the clause builder, and PAGINATED
  for F7's reason: 1180 live lines today, and nothing in the schema bounds it tomorrow.

  ANY order status is listable: reading a completed order's lines is normal. The status
  restriction belongs to make/delete!, which restructure the document.

  Returns a LIST normally, or a SENTINEL when the answer is not a list — a caller must inspect
  the result rather than assume one (the ring-4 dispatcher handles both). Zero lines is a
  SUCCESS with an empty list, never a 404.

  ⚠ THE LIST PATH IS RENDERED BY THE SHARED render-json METHOD ON `list` — see the note at the
  end of this file: a `list` method is ELEMENT-AGNOSTIC, so defining a second one with the same
  specializers would replace another entity's, and CLOS would keep whichever was defined last."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (rid (nst-order-item-id-from-value order-id)))
    (if (and order-id (null rid))
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address an order header row (row-ids are integers)" order-id))
        (nst-order-item-list ctx tenant-id rid status include-deleted
                                 sort-by sort-dir limit offset))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; लोप for a whole order's lines — called by the HEADER's delete!
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-soft-delete-order-items-for-header (order-id tenant-id)
  "लोप for the LINES of order ORDER-ID: mark every live line DELETED_STATE='Y'. Returns a
   bo-knowledge:

     :T  payload = the NUMBER OF LINES marked (0 is a legitimate success — an order with no
         lines deletes cleanly)
     :U  the boundary failed part-way. The provenance says how many lines were already marked
         before the failure, and the payload is NIL.

  ⚠ WHY THIS EXISTS AT ALL, MEASURED RATHER THAN ASSUMED: DOD_ORDER_ITEMS has NO foreign key on
  ORDER_ID (the only FK is TENANT_ID → DOD_COMPANY), so there is no ON DELETE CASCADE here to
  fire — and even where such a key exists it fires on a HARD delete, which a soft delete never
  issues. Without this helper, a deleted order keeps its lines live: rows nothing can reach,
  because every path to a line runs through its header.

  This is NOT delete! on one line: it takes no ctx and performs no status check, because its
  single caller is nst-ordh's delete!, which has already proved the order is in a DELETABLE
  status within the session tenant and is deleting that very document. A check here would also
  be answering a DIFFERENT question — the header's deletable list is DFT only (S5's correction),
  while the line verbs use the OPEN pair — so a second check would be a second place for two
  different rules to drift.

  WHY ROW BY ROW, THROUGH THE MACRO, rather than one hand-built `UPDATE … WHERE ORDER_ID = ?`:
  with-nst-db-delete is the sanctioned soft-delete boundary — it writes deleted-state through
  update-record-from-slot ONLY, so a delete can never clobber a concurrent change to another
  column, and it logs the failure to *HHUBBUSINESSFUNCTIONSLOGFILE*. A bulk statement would be
  one round trip and would bypass both properties; an order has a handful of lines, so the round
  trips are not the scarce resource here.

  NOT bo-merge ON FAILURE, DELIBERATELY. bo-merge is the information-order join, in which
  (T,U) = T — merging a success into a failure reports SUCCESS. What a partial failure means here
  is sequencing ('did every line get marked?'), which bo-merge cannot answer. So the first
  non-:T answer is returned as-is, with the progress folded into its provenance where a human can
  read it.

  THE CALLER MUST STOP ON NON-:T AND MUST LEAVE THE HEADER ALONE — see the ordering note in
  nst-bl-ordh.lisp's delete!. Every line is attempted in row-id order, so a re-run of the whole
  delete finishes the job.

  ⚠ THE READ IS BOUNDED AT *ordh-page-max-limit* (200) LINES, VIA
  nst-select-order-items-for-header, AND THAT BOUND IS STATED RATHER THAN INHERITED SILENTLY: an
  order with more than 200 live lines would leave the rest live behind a deleted header, which is
  the exact orphan state this function exists to prevent. The live maximum is far below it today;
  if that changes, this function must page."
  (let ((rows (nst-select-order-items-for-header order-id tenant-id))
        (done 0))
    (dolist (row rows)
      (let ((knowledge (with-nst-db-delete (:source "nst-orditm/soft-delete-for-header")
                          (setf (slot-value row 'deleted-state) "Y")
                          (clsql:update-record-from-slot row 'deleted-state)
                          row)))
        (unless (eq (bo-knowledge-truth knowledge) :T)
          ;; Stop at the first failure and report it — with the tally, because 'how far did it
          ;; get' is the first thing anyone asks of a partial soft delete, and the macro's own
          ;; provenance has no way to know it.
          (return-from nst-soft-delete-order-items-for-header
            (make-bo-knowledge
             :truth (bo-knowledge-truth knowledge)
             :payload nil
             :provenance (format nil "nst-orditm/soft-delete-for-header: ~A of ~A line(s) of order row-id ~A were already marked DELETED_STATE='Y' before the failure at line row-id ~A — ~A"
                                 done (length rows) order-id (slot-value row 'row-id)
                                 (knowledge-provenance-text knowledge)))))
        (incf done)))
    (make-bo-knowledge :truth :T :payload done
                       :provenance (format nil "nst-orditm/soft-delete-for-header: ~A live line(s) of order row-id ~A soft-deleted"
                                           done order-id))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; domain->response / render-json — the reverse ferry and the outbound encoding
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod domain->response ((entity nst-orditm) (ctx domain-ctx))
  "nst-orditm → NstOrditmResponseModel. Mirrors, driven by the same list the copiers use, so the
   response shape cannot drift from the entity. The narrowing decision that matters is which
   fields LEAVE the system, and that allowlist is render-json below."
  (let ((destination (make-instance 'NstOrditmResponseModel)))
    (setf (slot-value destination 'row-id) (row-id entity))
    (dolist (slot *orditm-mirrored-slots*)
      (setf (slot-value destination slot) (slot-value entity slot)))
    destination))

(defmethod render-json ((r NstOrditmResponseModel) (ctx domain-ctx))
  "One order line → a JSON alist. The caller, or the shared list method in nst-bl-invh.lisp,
   applies json:encode-json-to-string.

  SECURITY CONTRACT: this method IS the outbound field allowlist for a line. A slot added to
  NstOrditmResponseModel does NOT auto-leak — it must be named here, or named in
  *orditm-json-withheld-slots*, and the offline check asserts that the two sets add up to every
  slot of the class.

  THREE CONVENTIONS, all measured against the column declarations rather than assumed:
    * IDENTIFIERS leave as JSON strings via response-id-string (NIL → null), so rowId / orderId /
      vendorId / prdId do not mix 47, the string 47 and null for the same kind of value;
    * MONEY AND RATES leave as NUMBERS, never strings — the DB typed them decimal, a client doing
      arithmetic should not have to parse, and a string here would be a shape no client expects
      from this API;
    * the CODES leave as the values the column holds: status is char(3), fulfilled is char(1)
      (Y/N), and ITC_ELIGIBLE is an enum of ELIGIBLE / INELIGIBLE / BLOCKED. None is a JSON
      boolean, and ITC_ELIGIBLE in particular must not be coerced to one: a boolean would have to
      guess which of the two falsehoods a NO meant.
  THERE ARE NO DATE AND NO tinyint(1) COLUMNS ON THIS TABLE (measured, SHOW COLUMNS), so this
  allowlist carries no date formatter and no 0-is-truthy guard — the two guards the header's
  render-json needs are absent here because the columns they exist for are."
  (declare (ignore ctx))
  (list
   (cons "rowId"           (response-id-string (row-id r)))
   ;; parent and parties
   (cons "orderId"         (response-id-string (order-id r)))
   (cons "vendorId"        (response-id-string (vendor-id r)))
   (cons "prdId"           (response-id-string (prd-id r)))
   ;; what was ordered
   (cons "hsnCode"         (hsn-code r))
   (cons "sacCode"         (sac-code r))
   (cons "itemDescription" (item-description r))
   (cons "uqc"             (uqc r))
   ;; quantities and prices
   (cons "unitPrice"       (unit-price r))
   (cons "mrp"             (mrp r))
   (cons "prdQty"          (prd-qty r))
   ;; tax rates
   (cons "cgst"            (cgst r))
   (cons "sgst"            (sgst r))
   (cons "igst"            (igst r))
   (cons "cessRate"        (cess-rate r))
   (cons "discRate"        (disc-rate r))
   (cons "addlTax1Rate"    (addl-tax1-rate r))
   ;; tax and value amounts
   (cons "discountAmount"  (discount-amount r))
   (cons "cgstAmt"         (cgstamt r))
   (cons "sgstAmt"         (sgstamt r))
   (cons "igstAmt"         (igstamt r))
   (cons "cessAmount"      (cess-amount r))
   (cons "taxableValue"    (taxablevalue r))
   (cons "totalItemVal"    (totalitemval r))
   ;; fulfilment and compliance
   (cons "fulfilled"       (fulfilled r))
   (cons "status"          (status r))
   (cons "itcEligible"     (itc-eligible r))
   ;; other state
   (cons "comments"        (comments r))))

;;; ⚠ NO render-json METHOD ON `list` AND NO domain->response-list HERE, ON PURPOSE. Both
;;; already exist once in the tree and both are ELEMENT-AGNOSTIC — (render-json (responses list)
;;; (ctx …)) maps render-json over the elements, and domain->response-list maps domain->response
;;; over them. A second method with the SAME SPECIALIZERS does not coexist with the first: CLOS
;;; keeps the later definition. So a local copy added to 'make this file independent' is how
;;; another entity's rendering gets broken from here — silently, and in a file nobody editing
;;; this one would think to look at. The invoice's item file chose the same; S6's third copy of
;;; the list method in nst-bl-ordh.lisp was REMOVED in S7 for exactly this reason.

;;; End of nst-bl-orditm.lisp
