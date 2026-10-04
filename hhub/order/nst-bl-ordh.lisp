;;; nst-bl-ordh.lisp — Tier-1 प्रत्यय for the ORDER HEADER (nst-ordh)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; S3 of the orders batch. Design: aiharness/deepseek/skills/order-adhara-stories-CONTEXT.md
;;;
;;; WHAT THIS FILE CARRIES, and what it deliberately does not:
;;;   ?exists   प्रत्यभिज्ञा   is this ORDNUM already used, in this tenant
;;;   make      सृजन          a new order: mint its number, allocate the prefix it needs
;;;   plus the two copy ferries and the select helpers the verbs share.
;;;   fetch / enumerate / !update / delete! are S4 and S5; the reverse ferry is S6.
;;;
;;; FOUR STATES IN, FOUR STATES OUT. Every verb returns either a real nst-ordh or a Belnap
;;; sentinel from nst-bl-adhara.lisp, and :U is never phrased as "not found". nst-whs,
;;; nst-invh and nst-customer already share this discipline; the reasoning is in
;;; knowledge/nst-bl-apidefs2-CONTEXT.md §8.
;;;
;;; ⚠ THE REFUSAL IS A make :around, NOT A :before — COPIED FROM nst-whs, WHICH RECORDS
;;; WHY: "A :before method cannot return a value (its result is discarded), so raising was
;;; the only way it could refuse — and every refusal then reached the boundary as a 500,
;;; indistinguishable from a crash." An :around CAN return, so a refusal arrives as the
;;; domain's own answer. (The story file's S3 section still said ":before" when this was
;;; written; the warehouse's comment is the correction, and this file follows it.)
;;;
;;; ⚠ THE NUMBER IS MINTED HERE, NOT SUPPLIED — so the uniqueness guard is not "is the
;;; caller's identity taken"; a caller may not supply one at all. Instead:
;;;   * `make :around` spends its return-a-value power on IDEMPOTENCY: a repeat of the same
;;;     :context-id returns the order that already exists (§10 F6). A retried request must
;;;     not place a second order, and the table already carries CONTEXT_ID from the legacy
;;;     funnels.
;;;   * the mint pre-checks its own output with ?exists and retries a bounded number of
;;;     times; the UNIQUE index on ORDNUM is still the real guard.
;;;
;;; ⚠ THE STEPS ARE FLAT AND RETURN EARLY, ON PURPOSE. The first version of this verb nested
;;; ten levels deep and ended two parentheses wrong — and DEPTH IS WHERE PAREN ERRORS LIVE.
;;; `make` is now a thin method delegating to nst-order-header-create, whose body is a
;;; sequence of `(unless ok (return-from … refusal))` steps at ONE level. The preflight's
;;; reader check is what found the difference.
;;;
;;; THE PREFIX COMES FROM THE CUSTOMER. make resolves the customer IN THE SESSION TENANT
;;; first — a guessed :cust-id must not place an order for someone else (OWASP API1/BOLA) —
;;; then reads its DOC_PREFIX, allocating one on first use (R2). A customer that cannot be
;;; seen is :F → 404; a customer whose name yields no usable prefix is refused with a
;;; contradiction rather than given a meaningless one.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;; ───────────────────────────────────────────────────────────────────────────
;;; Select helpers. Every one is TENANT-SCOPED: ROW_ID and ORDNUM are unique keys, not
;;; authorisation, and a lookup that dropped the tenant predicate is the BOLA shape this
;;; tree keeps refusing. (ORDNUM IS globally unique, which makes it an unambiguous ADDRESS;
;;; it does not make a tenant-less QUERY legitimate.)
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-order-header-row-visible-p (row)
  "True when ROW is not soft-deleted.

   ⚠ DELETED_STATE is char(1) DEFAULT NULL on this table (unlike DOD_WAREHOUSE's 'N'), so
   BOTH NULL and \"N\" occur in the live data and a bare (= \"N\") test hides rows. The CLSQL
   class declares :void-value \"N\", which is why most reads come back as \"N\" — but a row
   written by a path that left it NULL reads as NULL, and this predicate is the one place
   that is decided."
  (not (equal (or (slot-value row 'deleted-state) "N") "Y")))

(defun nst-select-order-header-by-row-id (row-id tenant-id)
  "The live order header with ROW-ID in TENANT-ID, or NIL.

   ⚠ THE DELETED_STATE CLAUSE WAS MISSING UNTIL S5, AND ITS ABSENCE CONTRADICTED THIS VERY
   DOCSTRING. The invoice's equivalent selector has carried the OR-clause from the start;
   this one was written without it, so a SOFT-DELETED order came back as a live row — which
   would have let fetch serve it and, worse, let !update and delete! WRITE it, while नियम-2
   says a Y row is invisible to every verb. Found by S5, because both new verbs read through
   here and a delete that can delete a deleted row is not a delete.

   THE OR IS THE POINT (the same trap the filter builder documents): DELETED_STATE is
   char(1) DEFAULT NULL on this table, so BOTH NULL and N are live, and a bare [= N] would
   hide every order whose row was written by a path that left it NULL. [is … nil] renders
   IS NULL; [= … nil] would render the literal NULL, which is true for no row at all."
  (car (clsql:select 'dod-order
                     :where [and [= [:row-id] row-id]
                                 [= [:tenant-id] tenant-id]
                                 [or [= [:deleted-state] "N"]
                                     [is [:deleted-state] nil]]]
                     :caching nil :flatp t)))

(defun nst-select-order-header-rows-by-ordnum (ordnum tenant-id &key include-deleted)
  "EVERY row holding ORDNUM in TENANT-ID — a LIST deliberately, because the caller must be
   able to see MORE THAN ONE. Under the unique index that cannot happen for a live row; it
   CAN happen for a soft-deleted one, and a check returning only (car rows) could not tell
   'free' from 'held by a row you cannot see'. With INCLUDE-DELETED false the list holds the
   visible holders only."
  (remove-if-not (lambda (row) (or include-deleted (nst-order-header-row-visible-p row)))
                 (clsql:select 'dod-order
                               :where [and [= [:ordnum] ordnum]
                                           [= [:tenant-id] tenant-id]]
                               :caching nil :flatp t)))

(defun nst-select-order-header-by-context-id (context-id tenant-id)
  "The live order carrying CONTEXT-ID in TENANT-ID, or NIL — the IDEMPOTENCY KEY's lookup.
   CONTEXT_ID has no unique key, so this is a business fact rather than a guarantee: make's
   :around treats the first match as the answer, and two concurrent FIRST attempts can both
   see none. That residual race is recorded in the story file (§10 F6); closing it needs a
   unique key, which is a migration rather than a verb."
  (car (remove-if-not #'nst-order-header-row-visible-p
                      (clsql:select 'dod-order
                                    :where [and [= [:context-id] context-id]
                                                [= [:tenant-id] tenant-id]]
                                    :caching nil :flatp t))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; The copy ferries.
;;;
;;; LIST-DRIVEN, not one setf per field: both walk *ordh-mirrored-slots*, so they cannot be
;;; field-INCOMPLETE — a column missing from the list is missing in both directions at once
;;; and the offline check names it, rather than being silently dropped from one of them.
;;; (The invoice's longhand copiers are how `deleted-state` came to sit in a list that its
;;; response model did not implement; the list-driven shape makes that unrepresentable.)
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-copy-order-header-dbtodomain (source destination)
  "dod-order row -> nst-ordh, for row-id plus every mirrored slot."
  (setf (slot-value destination 'row-id) (slot-value source 'row-id))
  (dolist (f *ordh-mirrored-slots*)
    (setf (slot-value destination f) (slot-value source f)))
  destination)

(defun nst-copy-order-header-domaintodb (source destination)
  "nst-ordh -> dod-order row. ROW-ID is skipped (the DB mints it; a fetched row keeps it),
   and the tenant is pinned from the entity, so it can only ever have come from ctx.

   ⚠ THE INTEGER → FLOAT WIDENING IS NOT DECORATION, AND S3/S5 SHIPPED WITHOUT IT (fixed in
   S7, found by reading the invoice's own copier). dod-order declares the money and rate
   columns `float` — order-amt, tds-amount, the five TOTAL_* columns, shipping-cost — and
   CLSQL VALIDATES a slot's declared type on INSERT/UPDATE. So an ordinary JSON integer
   ({orderAmt: 100}) would be refused by the client library, and the refusal would reach the
   caller as :U/503 'the database call did not answer' — a 100-rupee order failing for
   looking like a whole number. The invoice batch MEASURED exactly this and lost a day to it
   twice (nst-bl-invh.lisp), which is why the helper now lives in core/dod-bl-utl.lisp where
   BOTH batches can reach it. The 0.0 class initforms cover the OMITTED field; this covers
   the SUPPLIED one, and fixing only one of the two leaves most requests failing."
  (dolist (f *ordh-mirrored-slots*)
  ;; ⚠ GUARDED: an optional field is UNBOUND on a fresh entity and `slot-value` SIGNALS on it.
  ;; See nst-db-slot-value-from-domain (core/dod-bl-utl.lisp).
    (setf (slot-value destination f)
          (nst-coerce-for-db-slot destination f
                                  (nst-db-slot-value-from-domain source f))))
  (setf (slot-value destination 'tenant-id) (slot-value source 'tenant-id))
  destination)

;;; ───────────────────────────────────────────────────────────────────────────
;;; ?exists — प्रत्यभिज्ञा
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod ?exists ((entity-class (eql 'nst-ordh)) (ordnum string) (ctx domain-ctx)
                    &key &allow-other-keys)
  "Is ORDNUM already used, in the calling tenant? A BELNAP answer, because the honest one is
   not yes/no:

     :F  free — nothing in this tenant holds it, so a create may proceed
     :T  a LIVE order holds it (a fact of existence)
     :C  a SOFT-DELETED order holds it. Two of our own rules disagree: the row is present
         and occupies uk_ordnum, while नियम-2 makes DELETED_STATE='Y' rows invisible to every
         verb — so no order is there. It must NEVER be read as free: the INSERT would fail on
         the unique key.
     :U  the database could not be consulted. NOT :F — creating on an unconfirmed identity is
         exactly how a duplicate gets written.

   &key &allow-other-keys satisfies CLOS congruence with the ?exists generic function
   (nst-whs declares &key WNAME); this method needs no keywords of its own."
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (handler-case
        (let ((rows (nst-select-order-header-rows-by-ordnum ordnum tenant-id
                                                            :include-deleted t)))
          (cond
            ((null rows)
             (make-bo-knowledge :truth :F :payload nil
                                :provenance "no row in this tenant holds this ORDNUM"))
            ((null (cdr rows))
             (let ((row (car rows)))
               (if (nst-order-header-row-visible-p row)
                   (make-bo-knowledge :truth :T :payload row
                                      :provenance "a live order holds this ORDNUM")
                   (make-bo-knowledge
                    :truth :C :payload row
                    :provenance "the ORDNUM is held by a SOFT-DELETED order: the row is present and occupies uk_ordnum, while नियम-2 makes DELETED_STATE='Y' rows invisible to every verb"))))
            (t
             (make-bo-knowledge
              :truth :C :payload rows
              :provenance (format nil "~D rows in this tenant hold this ORDNUM, so 'taken' and 'free' are both wrong"
                                  (length rows))))))
      (error (c)
        (make-bo-knowledge :truth :U :payload nil
                           :provenance (format nil "the ORDNUM check could not consult the database (~A)" c))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; create — the pieces, each shallow enough to read
;;; ───────────────────────────────────────────────────────────────────────────

;;; ⚠ THE OPEN AND TERMINAL STATUS LISTS USED TO BE DEFINED HERE (S3 and S5). THEY MOVED TO
;;; core/dod-bl-utl.lisp IN S8, as *order-open-statuses* / *order-terminal-statuses* with
;;; order-open-status-p / order-terminal-status-p beside them (D17). The reason is the S8
;;; defect rather than tidiness: the legacy layer held the literal "PEN" in seven reads while
;;; make mints "DFT", so a new order was invisible to every legacy list — and a rule with a
;;; copy per layer is exactly how that happens. The legacy retrofit and these verbs now read
;;; the SAME list, and the offline check asserts this file defines no second one.
;;;
;;; *ordh-deletable-statuses* STAYS HERE, because it answers a different question (may this
;;; DOCUMENT be deleted?) — see its own note below.

(defparameter *ordh-forced-create-values*
  '(("N" . is-converted-to-invoice) ("N" . is-cancelled) ("N" . order-fulfilled))
  "Values a CREATE forces regardless of what the caller sent: a new order has not been
   converted to an invoice, is not cancelled and is not fulfilled. Letting a client assert
   otherwise through the create payload is field-level mass assignment (OWASP API3/BOPLA),
   and these three drive billing and fulfilment.")

(defparameter *ordh-create-stripped-initargs*
  '(:id :tenant-id :created-at :updated-at :deleted-state     ; reserved — the ferry strips these too
    :ordnum :created-by-user-id :approved-by-user-id          ; minted / session-derived, never client
    :invoice-number :invoice-date)                            ; the order -> invoice link, set by that verb
  "Keys dropped from a create payload. The five reserved ones are stripped by the ferry as
   well; doing it here too closes the DIRECT-call hole (a REPL or :agent caller reaches make
   without passing the ferry) — the same one-line guard the invoice batch recorded as
   missing. :ordnum is stripped because make MINTS it; the audit ids because they come from
   the session, not from the request.")

(defun nst-actor-user-row-id (ctx)
  "The acting user's row-id from CTX, or NIL. BEST EFFORT and deliberately narrow: the actor
   is a session value that is either a user OBJECT or a role NAME, so this stamps the column
   only when it is an object carrying a row-id. It NEVER reads the request payload — an audit
   column a client can set is not an audit column.

   ⚠ IT IS THEREFORE USUALLY NIL TODAY: conflodis2's कार्ता comes from :login-user /
   :login-user-role-name, and a CUSTOMER session sets neither, so CREATED_BY_USER_ID stays
   NULL for API-created orders until the route layer plumbs the customer-user id (§10 F11)."
  (let ((actor (domain-ctx-actor ctx)))
    (when (and actor (not (stringp actor)))
      (ignore-errors (slot-value actor 'row-id)))))

(defun nst-customer-document-name (customer)
  "The name a document prefix is derived from, in the SAME precedence the ordnum-identity
   migration resolves in SQL: legal-company-name → legal-name → company-name → name.

   ⚠ THE RULE IS STATED IN TWO PLACES, one per language, because the migration resolves it
   in a COALESCE over rows it has not materialised while this resolves it on one ORM row.
   They must agree. The live data shows why it matters: customer 27's NAME is the synthetic
   G33us22337333444 while its legal name is 'LG Iyengars Bakery' — the one that yields a
   recognisable prefix."
  (or (slot-value customer 'legal-company-name)
      (slot-value customer 'legal-name)
      (slot-value customer 'company-name)
      (slot-value customer 'name)))

(defun nst-order-header-prepare-args (initargs)
  "Strip what a client may not set, and supply the two dates.

   ORD_DATE and REQ_DATE are NOT NULL with no DDL default, so a create without ORD_DATE is
   not a request the database can answer; defaulting to today mirrors nst-invh's make, which
   does the same for INVDATE. REQ_DATE follows the order date rather than 'now' so a
   back-dated order does not ask for delivery before it was placed.

   Returns the plist plus the normalised status: (values args status)."
  (let ((args (loop for (k v) on initargs by #'cddr
                    unless (member k *ordh-create-stripped-initargs*) append (list k v))))
    (unless (getf args :ord-date)
      (setf args (append args (list :ord-date (clsql-sys:get-date)))))
    (unless (getf args :req-date)
      (setf args (append args (list :req-date (getf args :ord-date)))))
    (values args (string-upcase (string (or (getf args :status) "DFT"))))))

(defun nst-mint-order-number (ctx prefix ord-date tenant-id cust-id)
  "The next order number for CUST-ID, or a refusal. Returns (values NUMBER REFUSAL), exactly
   one of which is non-NIL.

   THE PRE-CHECK IS NOT THE GUARD. The counter is atomic and scoped per (customer, financial
   year), so two mints never return the same counter; what can still collide is the reference
   itself, which is an HMAC truncated to {ref:N} characters and therefore a random function:
   a birthday collision, or a rotated DOD_SYS_SECRET which can map two counters onto one
   string. The UNIQUE index on ORDNUM is what actually prevents a duplicate; this loop is
   what keeps a collision from becoming a 5xx, and five attempts is far beyond the one-in-a-
   million rate the 6-character width implies."
  ;; ⚠ IGNORABLE, NOT IGNORE. dotimes expands to (SETQ ATTEMPT (1+ ATTEMPT)) and tests
  ;; (>= ATTEMPT 5), so SBCL ASSIGNS and READS the variable it is told to ignore —
  ;; (declare (ignore attempt)) earns THREE style warnings here ("being set even though it
  ;; was declared to be ignored", plus "reading an ignored variable" twice). `ignorable`
  ;; states the same intent without contradicting the expansion.
  (dotimes (attempt 5)
    (declare (ignorable attempt))
    (let* ((candidate (nst-order-number-for *nst-order-number-format* prefix ord-date
                                            tenant-id cust-id))
           (check (?exists 'nst-ordh candidate ctx)))
      (case (bo-knowledge-truth check)
        (:F (return-from nst-mint-order-number (values candidate nil)))
        (:T nil)                                ; collided — mint again
        (:C (return-from nst-mint-order-number
              (values nil
                      (make-instance 'nst-entity-contradiction
                                     :tenant-id tenant-id
                                     :reason (format nil "Order create: the minted number ~A is held by a soft-deleted order. Refusing rather than reusing a consumed number." candidate)))))
        (otherwise (return-from nst-mint-order-number
                     (values nil
                             (domain-sentinel-from-knowledge
                              check ctx
                              :reason "Order create: the minted number could not be confirmed free")))))))
  (values nil
          (make-instance 'nst-entity-contradiction
                         :tenant-id tenant-id
                         :reason "Order create: five minted references collided with existing orders. That is a birthday collision or a rotated reference key — check DOD_SYS_SECRET and the {ref:N} width.")))

(defun nst-order-header-insert (ctx tenant-id args ordnum)
  "Copy, INSERT, and answer in four-valued terms. The last step of a create, extracted so
   the ordering above it reads as a list of steps rather than a staircase."
  (let ((entity (apply #'make-instance 'nst-ordh
                       :tenant-id tenant-id :ordnum ordnum
                       (loop for (k v) on args by #'cddr
                             unless (eq k :ordnum) append (list k v))))
        (dbobj (make-instance 'dod-order)))
    (dolist (pair *ordh-forced-create-values*)
      (setf (slot-value entity (cdr pair)) (car pair)))
    (let ((actor-id (nst-actor-user-row-id ctx)))
      (when actor-id (setf (created-by-user-id entity) actor-id)))
    (nst-copy-order-header-domaintodb entity dbobj)
    (let ((knowledge (with-nst-db-create (:source "nst-ordh/make")
                        (clsql:update-records-from-instance dbobj)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T (bind-generated-row-id entity (bo-knowledge-payload knowledge))
            entity)
        (:F ;; The INSERT itself was refused: a NOT NULL column, a foreign key, or the unique
            ;; ORDNUM index. The database names the offender and that reason is the useful
            ;; part, so it is carried out rather than flattened into "create failed".
            (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Order create: the database refused the row (a NOT NULL column such as ORD_DATE/REQ_DATE/CUST_ID, a foreign key, or the unique ORDNUM index) — see the provenance"))
        (:U (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Order create: the database call did not answer, so the row may or may not have been written — this is UNKNOWN, not failed"))
        (:C (make-instance 'nst-entity-contradiction
                           :tenant-id tenant-id
                           :reason "Order create: the write reported a contradiction (no :pre-flight form is supplied to with-nst-db-create here, so :C means the macro contract changed)"))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create"
                          (bo-knowledge-truth knowledge)))))))

(defun nst-order-header-create (ctx tenant-id initargs)
  "The create, as a SEQUENCE OF STEPS that each return early with a refusal.

   FLAT ON PURPOSE — see the file header. Every `unless … (return-from …)` below is one step
   at one level, so this reads top to bottom and has no staircase to miscount."
  (multiple-value-bind (args status) (nst-order-header-prepare-args initargs)
    ;; 1. the status: DFT unless an OPEN status was supplied
    (unless (member status *order-open-statuses* :test #'string=)
      (return-from nst-order-header-create
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason (format nil "~S is not a status a new order may have: a create mints DFT, and only the OPEN statuses ~{~A~^, ~} may be supplied. The column is three characters wide, so DRAFT could not be stored either."
                                       status *order-open-statuses*))))
    (setf args (list* :status status
                      (loop for (k v) on args by #'cddr unless (eq k :status) append (list k v))))
    ;; 2. the customer, IN THIS TENANT
    (let* ((cust-id (getf args :cust-id))
           (customer (and (integerp cust-id)
                          (nst-select-customer-by-id cust-id tenant-id))))
      (unless customer
        (return-from nst-order-header-create
          (make-instance 'nst-entity-nil
                         :tenant-id tenant-id
                         :reason (format nil "Order create: customer row-id ~S does not exist in this tenant, so no order can be placed for it" cust-id))))
      ;; 3. the prefix — the customer's identity for every document it owns
      (let ((prefix (or (nst-doc-prefix-read cust-id)
                        (handler-case
                            (nst-doc-prefix-assign cust-id (nst-customer-document-name customer))
                          (error (c)
                            (return-from nst-order-header-create
                              (make-instance 'nst-entity-contradiction
                                             :tenant-id tenant-id
                                             :reason (format nil "Order create: customer ~D has no usable DOC_PREFIX and none can be derived (~A). Set DOC_PREFIX on the customer, then retry." cust-id c))))))))
        (unless prefix
          (return-from nst-order-header-create
            (make-instance 'nst-entity-contradiction
                           :tenant-id tenant-id
                           :reason (format nil "Order create: customer ~D has no DOC_PREFIX and none could be allocated." cust-id))))
        ;; 4. the number
        (multiple-value-bind (ordnum refusal)
            (nst-mint-order-number ctx prefix (getf args :ord-date) tenant-id cust-id)
          (if refusal
              refusal
              ;; 5. copy, insert, answer
              (nst-order-header-insert ctx tenant-id args ordnum)))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; make — the verb. Thin: the idempotency :around above it, the steps below it.
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod make :around ((entity-class (eql 'nst-ordh)) (ctx domain-ctx)
                         &rest initargs)
  "IDEMPOTENCY (§10 F6): a create carrying a :context-id that already names an order in this
   tenant returns THAT order instead of creating a second one. This is what an :around is for
   — it can RETURN, where a :before could only raise.

   A retried POST is not hypothetical: a client that times out and retries, or a proxy that
   replays, would otherwise place the order twice — and with it a second set of vendor rows
   and a second number, because nothing in this batch is transactional (D14). The legacy
   funnels already stamp CONTEXT_ID with (uuid:make-v1-uuid), so the key existed in the data
   model and only needed honouring."
  (let ((context-id (getf initargs :context-id)))
    (if (null context-id)
        (call-next-method)
        (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
               (existing (nst-select-order-header-by-context-id context-id tenant-id)))
          (if (null existing)
              (call-next-method)
              (let ((entity (make-instance 'nst-ordh :tenant-id tenant-id)))
                (nst-copy-order-header-dbtodomain existing entity)
                entity))))))

(defmethod make ((entity-class (eql 'nst-ordh)) (ctx domain-ctx) &rest initargs)
  "Create an order in the SESSION tenant with a minted ORDNUM. See the file header for the
   order of operations and for why the refusal is an :around rather than a :before."
  (nst-order-header-create ctx (slot-value (domain-ctx-tenant ctx) 'row-id) initargs))

;;; ───────────────────────────────────────────────────────────────────────────
;;; S4 — fetch and enumerate
;;; ───────────────────────────────────────────────────────────────────────────

(defparameter *ordh-sort-whitelist*
  '((:row-id . :row-id)
    (:ordnum . :ordnum)
    (:ord-date . :ord-date)
    (:expected-delivery-date . :expected-delivery-date)
    (:status . :status)
    (:order-amt . :order-amt)
    (:cust-name . :cust-name)
    (:created . :created))
  "The ONLY columns enumerate may sort by. sort-by is caller-controllable — it arrives from an
   HTTP query string — so this list is what stands between that and arbitrary ORDER BY
   construction. Keys are Lisp-side names; values are the CLSQL slot keywords of `dod-order`,
   which are NOT the column names (SHIP_ADDRESS is ship-address-short, CUSTNAME is cust-name).
   Extend deliberately, one line at a time.")

(defparameter *ordh-page-default-limit* 50
  "Rows per page when the caller does not say. A list endpoint with no cap is an unbounded
   read: 485 orders today, and nothing in the schema bounds it tomorrow (§10 F7).")

(defparameter *ordh-page-max-limit* 200
  "The hard cap. A larger :limit is CAPPED rather than refused — returning fewer rows than
   asked for is a legal answer (AIP-158), while an error would make a client's over-large page
   request look like a malformed one.")

(defun nst-ordh-sort-column (sort-by sort-dir &optional (whitelist *ordh-sort-whitelist*))
  "Validate a caller-supplied sort and return the CLSQL column keyword and direction.

   ⚠ IT SIGNALS, AND THE ROUTE LAYER IS WHAT MAKES THAT A 400. A plain `error` here reaches
   the API as a 500 — 'the server broke' — for a client that simply mistyped a query
   parameter the API itself publishes. That is exactly the defect the invoice batch measured
   and fixed in its ROUTE layer (invh-guard-sort-args), reading the same whitelist rather than
   restating the columns. This domain check stays as the backstop for the channels that never
   pass a route: :agent, :batch, a REPL caller. The 400 belongs to S12/S13.

   ⚠ THE WHITELIST IS A PARAMETER, ADDED IN S7, AND IT IS STILL ONE IMPLEMENTATION. The line
   entity needs the same validation against a different column set (nst-orditm's own list), so
   the choice was a parameter or a second copy of this function; a second copy is how the two
   would come to disagree about what :asc means, and the error message would then name the
   wrong list. The default keeps every S4 call site unchanged, and the message names the
   whitelist it actually checked."
  (let ((col (cdr (assoc sort-by whitelist))))
    (unless col
      (error "sort-by ~S is not in the whitelist ~S"
             sort-by (mapcar #'car whitelist)))
    (unless (member sort-dir '(:asc :desc))
      (error "sort-dir must be :asc or :desc, got ~S" sort-dir))
    (values col sort-dir)))

(defun nst-ordh-page-limit (limit)
  "LIMIT as a usable page size: the default when NIL, capped at *ordh-page-max-limit*, and a
   signal for anything that is not a positive integer (a malformed request rather than a large
   one)."
  (cond ((null limit) *ordh-page-default-limit*)
        ((not (and (integerp limit) (plusp limit)))
         (error "nst-ordh/enumerate: limit must be a positive integer, got ~S" limit))
        ((> limit *ordh-page-max-limit*) *ordh-page-max-limit*)
        (t limit)))

(defun nst-ordh-status-string (status)
  "A caller-supplied status as the three-character string the column stores, or NIL for NIL
   (read as 'no status filter'). Both :dft and \"dft\" land on DFT."
  (when status (string-upcase (string status))))

(defun nst-build-order-header-filter-clauses (tenant-id &key cust-id status ordnum-like
                                                       from-date to-date include-deleted)
  "WHERE clauses for order-header queries, always tenant-scoped.

  ⚠ THE DELETED_STATE CLAUSE IS AN OR, AND IT HAS TO BE: the column is `char(1) DEFAULT NULL`
  on this table, so BOTH NULL and N occur in the live data. A plain [= … N] would hide
  every order whose row was written by a path that left it NULL, and [= … nil] is worse — it
  renders the literal NULL, and DELETED_STATE = NULL is true for no row at all. Hence
  [is … nil], which renders IS NULL. (Fixing the column's default to 'N' would collapse this
  to one clause; that is a migration, not a verb.)

  :cust-id IS A SCOPE, and the route layer takes it from the SESSION, never from the payload —
  a client that could name another customer here would read that customer's orders (OWASP
  API1/BOLA). This builder cannot enforce that; it can only not pretend otherwise."
  (let ((clauses (list [= [:tenant-id] tenant-id])))
    (unless include-deleted
      (push [or [= [:deleted-state] "N"]
                [is [:deleted-state] nil]] clauses))
    (when cust-id (push [= [:cust-id] cust-id] clauses))
    (when (nst-ordh-status-string status)
      (push [= [:status] (nst-ordh-status-string status)] clauses))
    (when (and ordnum-like (plusp (length (string-trim " " ordnum-like))))
      (push [like [:ordnum] (format nil "%~A%" (escape-like-wildcards ordnum-like))] clauses))
    (when from-date (push [>= [:ord-date] from-date] clauses))
    (when to-date (push [<= [:ord-date] to-date] clauses))
    clauses))

(defun nst-select-order-headers-by-filter (tenant-id &key cust-id status ordnum-like
                                                     from-date to-date include-deleted
                                                     (sort-by :ord-date) (sort-dir :desc)
                                                     limit offset)
  "Order headers matching the filters, in a STABLE order.

  ⚠ A SECONDARY ORDER BY ROW-ID IS PART OF PAGINATION, not decoration. ORD_DATE is a DATE, so
  orders placed on one day TIE — and an ORDER BY with ties has no defined order between
  pages, so an offset-based reader can see one order twice and never see another. The
  secondary key makes the sequence total, which is what makes :offset safe."
  (multiple-value-bind (sort-col sort-dir) (nst-ordh-sort-column sort-by sort-dir)
    (clsql:select 'dod-order
                  :where (apply #'clsql:sql-and
                                (nst-build-order-header-filter-clauses
                                 tenant-id :cust-id cust-id :status status
                                           :ordnum-like ordnum-like
                                           :from-date from-date :to-date to-date
                                           :include-deleted include-deleted))
                  :order-by (list (list sort-col sort-dir) (list :row-id :desc))
                  :limit (nst-ordh-page-limit limit)
                  :offset (or offset 0)
                  :caching *dod-database-caching* :flatp t)))

(defun nst-select-order-header-by-ordnum (ordnum tenant-id)
  "The LIVE order header holding ORDNUM in TENANT-ID, or NIL — the single-row lookup the ROUTE
   layer uses to turn the URL's number into a row-id (the verbs stay row-id-keyed, exactly as
   the invoice's do, because CLOS dispatches on TYPE and an ORDNUM and a ROW_ID are both
   strings). Soft-deleted holders are excluded here; ?exists is the checker that must see
   them, and it is a different function on purpose."
  (car (nst-select-order-header-rows-by-ordnum ordnum tenant-id)))

;;; ───────────────────────────────────────────────────────────────────────────
;;; fetch — स्मरण
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod fetch ((entity-class (eql 'nst-ordh)) (id string) (ctx domain-ctx))
  "Recall one order header by ROW-ID, in the session tenant. Always four-valued:

     :T → the entity                → 200
     :F → nst-entity-nil            → 404  'there is no such order'
     :U → nst-entity-unknown        → 503  'I could not find out' — NOT 404
     :C → nst-entity-contradiction  → 409

  ANOTHER TENANT'S ROW-ID ANSWERS :F — not :U and not a permission error. Authorization here
  is per-object by construction: the SELECT carries tenant-id, so the row is simply not there.
  That is OWASP API1:2023 (BOLA) answered by the shape of the query rather than by a check
  somebody can forget."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (row-id (nst-row-id-from-string id)))
    (if (null row-id)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address an order header row (row-ids are integers)" id))
        (let ((knowledge (with-db-call (nst-select-order-header-by-row-id row-id tenant-id)
                                       "nst-ordh/fetch (row-id, session tenant)")))
          (case (bo-knowledge-truth knowledge)
            (:T (let ((entity (make-instance 'nst-ordh :tenant-id tenant-id)))
                  (nst-copy-order-header-dbtodomain (bo-knowledge-payload knowledge) entity)
                  entity))
            (:F (make-instance 'nst-entity-nil
                               :tenant-id tenant-id
                               :reason (format nil "no live order header with row-id ~D in tenant ~D" row-id tenant-id)))
            (otherwise (domain-sentinel-from-knowledge
                        knowledge ctx
                        :reason (format nil "Order fetch, row-id ~D tenant ~D: the lookup did not answer" row-id tenant-id))))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; enumerate — दर्शन
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod enumerate ((entity-class (eql 'nst-ordh)) (ctx domain-ctx)
                      &key cust-id status ordnum-like from-date to-date include-deleted
                           (sort-by :ord-date) (sort-dir :desc) limit offset)
  "List order headers within the session tenant.

  DEFAULT ORDER IS NEWEST FIRST (:ord-date :desc) — an order list is read from the top, the
  same choice the invoice list makes and the opposite of the warehouse's alphabetical
  catalogue default.

  Returns a LIST normally, or a SENTINEL when the answer is not a list — a caller must inspect
  the result rather than assume one (the ring-4 dispatcher handles both: action->response sends
  a non-list through domain->response). An empty result is a SUCCESS with zero rows → 200 [],
  never 404.

  THE FILTERS ARE QUERY ARGUMENTS, NOT ENTITY INITARGS — which is why this verb takes them
  directly and why the ferry cannot carry them: extract-domain-initargs forwards only keys the
  DOMAIN CLASS declares, so :ordnum-like/:from-date/:limit would be silently dropped. The
  route layer builds them, exactly as nst-bl-invitmapi's invitm-enumerate-args does."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (knowledge (with-nst-db-read-all
                        (:source "nst-ordh/enumerate"
                         :pk-extractor (lambda (d) (slot-value d 'row-id)))
                      (nst-select-order-headers-by-filter
                       tenant-id :cust-id cust-id :status status
                                 :ordnum-like ordnum-like
                                 :from-date from-date :to-date to-date
                                 :include-deleted include-deleted
                                 :sort-by sort-by :sort-dir sort-dir
                                 :limit limit :offset offset))))
    (case (bo-knowledge-truth knowledge)
      (:T (mapcar (lambda (dbobj)
                    (let ((entity (make-instance 'nst-ordh :tenant-id tenant-id)))
                      (nst-copy-order-header-dbtodomain dbobj entity)
                      entity))
                  (bo-knowledge-payload knowledge)))
      (:F '())
      (otherwise (domain-sentinel-from-knowledge
                  knowledge ctx
                  :reason (format nil "Order enumerate, tenant ~A: the database call did not answer — the order list contents are unknown" tenant-id))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; S5 — !update and delete!
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; TWO MEASURED RULES GOVERN EVERYTHING BELOW.
;;;
;;; 1. A REFUSAL IS A RETURNED SENTINEL, NEVER A SIGNAL. nst-whs's measurement is quoted at
;;;    the top of this file: a refusal that RAISES reaches the boundary as a 500, which is
;;;    indistinguishable from a crash. Every refusal here is an nst-entity-* the route
;;;    layer can classify.
;;;
;;; 2. THE ADDRESS IS ALSO A PARAM, so the identity keys are STRIPPED and only keys that can
;;;    have come from a BODY alone are REFUSED. api-params-for-request merges the path
;;;    parameters and the JSON body into ONE plist, so PUT /orders/{ordnum} arrives carrying
;;;    :ordnum — and the invoice batch MEASURED what a guard that refuses such a key does:
;;;    it refuses every legitimate request, which is exactly what happened the first time
;;;    that guard was written (invoice/nst-bl-invhapi.lisp:377-383).

;;; ⚠ *order-terminal-statuses* USED TO BE DEFINED HERE TOO (S5). It moved with the open list —
;;; see the note above *order-open-statuses*. What stays here is only the DELETABLE question,
;;; which is genuinely this verb's own:

(defparameter *ordh-deletable-statuses* '("DFT")
  "The statuses from which a header may be SOFT-deleted. A SEPARATE LIST from the shared
   *order-open-statuses*: may-this-be-deleted and may-its-content-change are different
   questions, and the invoice batch keeps them apart too. The offline check asserts this list
   is a SUBSET of the shared open one — a deletable status that was not open would let a
   finished order be deleted, which no verb could then explain.

   ⚠ IT IS NARROWER THAN THE OPEN PAIR, AND THAT IS A CORRECTION TO THE STORY FILE, NOT A
   TYPO. D8 said delete is open-only and O4 said an open order may be deleted, while S5's
   own acceptance criterion says delete on PEN REFUSES and on DFT SUCCEEDS. The AC is what
   the smoke suite tests, and it is also the safer reading: a PEN row is a PLACED order —
   the legacy placement path writes one DOD_VENDOR_ORDERS row per vendor (D20), so
   soft-deleting it would leave vendor rows behind that nothing can reach, and all 485
   existing orders are PEN. A placed order is CANCELLED (VCN), not deleted; that is the
   [LEGAL] line the invoice draws at an issued invoice.

   ⚠ TO ADOPT D8's READING INSTEAD, THIS ONE LIST BECOMES DFT AND PEN.")

(defparameter *ordh-update-stripped-initargs*
  '(:id :tenant-id :created-at :updated-at :deleted-state    ; the five the FERRY reserves
    :row-id                                                  ; the address
    :ordnum :context-id                                      ; minted (D4) / the create's key
    :cust-id                                                 ; D5 scope — from the session
    :created-by-user-id :approved-by-user-id)                ; session-derived audit
  "Keys !update drops silently. THE FIVE RESERVED ONES ARE THE POINT: *reserved-initargs*
   is applied by the FERRY (extract-domain-initargs), so a DIRECT call — a REPL, an :agent,
   a batch job — reaches this method with whatever it likes. The invoice batch recorded that
   hole and asked for a one-line verb guard; this is that guard, and it closes the hole for
   every channel at once because it runs in the verb.

   WHY THESE ARE STRIPPED AND NOT REFUSED: rule 2 in the section header. :row-id and :ordnum
   are part of the request's own ADDRESS on the routes D3 defines, and :cust-id is the scope
   the route narrows from the session, so refusing them would refuse every legitimate
   request. Stripping a key a caller may never assign satisfies the rule either way — the
   value cannot be set — and the reply returns the row's ACTUAL state, so an attempt is
   visible in the answer instead of silently believed.

   ⚠ IT IS DELIBERATELY NOT THE SAME LIST AS *ordh-create-stripped-initargs*, which is a
   subset plus the two order-to-invoice keys. Create NEEDS :cust-id (it resolves the
   customer) and :context-id (it stores the idempotency key), and it STRIPS the invoice link
   rather than refusing it, so a client that posts a whole representation back is not
   punished. Two verbs, two contracts, stated rather than shared by accident.")

(defparameter *ordh-never-writable-fields*
  '(:is-converted-to-invoice :invoice-number :invoice-date    ; the order -> invoice link
    :is-cancelled :cancel-reason                              ; cancellation is a verb
    :cust-name)                                               ; a copy of the customer's name
  "Fields NO channel may write through !update (F5, OWASP API3 mass assignment). The first
   three are written by the invoice verb that converts the order; the next two by whatever
   cancels it; the last is denormalised from the customer row, and a client that could
   rewrite it would make the order lie about who placed it.

   THESE ARE REFUSED, NOT STRIPPED, AND THAT IS THE DIFFERENCE FROM THE LIST ABOVE: none of
   them can appear in a request's address or scope, so a refusal can never hit a legitimate
   request — and a refusal is what makes an attempted escalation VISIBLE. Stripping here
   would leave a client believing it had set the order-to-invoice link.")

(defparameter *ordh-internal-only-fields* '(:status :order-fulfilled :shipped-date)
  "Fields only an INTERNAL channel may write. This is the per-channel half of F5, and the
   customer-facing half is what matters: an external caller must not reach the fulfilment
   and status transitions through a field assignment instead of through their own verbs
   (D3 puts /fulfill and /cancel out of scope, so no channel in this batch writes them
   through a verb — an internal one may still do it here).")

(defparameter *ordh-internal-channels* '(:ui :agent :batch :scheduler)
  "The channels that are INSIDE the trust boundary: the in-tree staff pages (:ui) and the
   automation that runs as the product itself. :http is the external API and is NOT here.
   ⚠ AN UNKNOWN OR NIL CHANNEL IS TREATED AS EXTERNAL — fail closed. A nil channel is not
   hypothetical: customer/dod-ui-cus.lisp builds ctx with :actor and :tenant and no channel
   at all, and that path IS the customer. (The legacy UI passes the STRING ONLINE, which is
   likewise not internal.)")

(defparameter *ordh-caller-writable-fields*
  '(;; the schedule, as the customer states it
    :ord-date :req-date :expected-delivery-date
    :order-type :order-source
    ;; where it goes, and where it is billed
    :ship-address-short :ship-addr-full :ship-city :ship-state :ship-zipcode
    :bill-address-short :bill-addr-full :bill-city :bill-state :bill-zipcode
    :country :bill-same-as-ship :storepickupenabled
    ;; tax identity and place of supply
    :gst-number :gst-org-name :place-of-supply :place-of-supply-code :supply-type
    :reverse-charge-applicable :eway-bill-required :tds-applicable :tds-amount
    ;; money (D13: no roll-up, so these are writable here by decision, not by oversight)
    :order-amt :total-taxable-value :total-cgst :total-sgst :total-igst :total-cess
    :total-tax :total-discount :shipping-cost
    ;; free text and presentation
    :comments :external-url :payment-mode)
  "THE POSITIVE ALLOWLIST (F5). Every field above is writable on every channel; the union
   with *ordh-internal-only-fields* is what an internal channel may write.

   IT IS ENUMERATED POSITIVELY ON PURPOSE. An allowlist whose default is ALLOW is not an
   allowlist: the omission of a field nobody thought about would then be a hole. Here an
   omitted field is REFUSED, which is a bug the suite can see rather than a write nobody
   notices. The offline check asserts that these four lists PARTITION the entity's slots, so
   a slot added to nst-ordh later cannot silently fall outside the policy.

   ⚠ :ord-date IS WRITABLE, AND THE CONSEQUENCE IS STATED RATHER THAN HIDDEN: the minted
   ORDNUM embeds the financial year of the ORD_DATE it was minted from (D6), and this verb
   does not re-mint. A number is DATA, not a derived value, so an order whose date is
   corrected keeps the number it already has — the same reason the invoice batch treats a
   consumed number as consumed.")

(defparameter *ordh-update-control-keys* '(:if-match)
  "Keys the verb CONSUMES and never assigns: transport preconditions, not entity state.
   They cannot be slots (reinitialize-instance would reject them), so the offline check
   asserts that none of them is a slot of nst-ordh.

   ⚠ THEY CANNOT RIDE THE FERRY. request->dispatch hands !update
   (extract-domain-initargs rm entity-class), which forwards only keys the DOMAIN CLASS
   declares — so :if-match reaches this method only when the ROUTE calls the verb itself,
   and a route that forgets it loses the precondition silently. S12/S13 own that half; it is
   recorded here because the failure is invisible from this file.")

;;; ───────────────────────────────────────────────────────────────────────────
;;; The policy, as functions — one rule per question, each shallow enough to read
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-ordh-internal-channel-p (channel)
  "True when CHANNEL is one of *ordh-internal-channels*. NIL and anything unrecognised are
   EXTERNAL: a membership test with a fail-closed default rather than a test for :http, so a
   channel invented tomorrow is internal only if somebody says so."
  (and channel
       (member (intern (string-upcase (string channel)) :keyword)
               *ordh-internal-channels*
               :test #'eq)
       t))

(defun nst-ordh-writable-fields (channel)
  "The fields a caller on CHANNEL may write: the positive list, plus the internal-only three
   when the channel is inside the trust boundary."
  (if (nst-ordh-internal-channel-p channel)
      (append *ordh-caller-writable-fields* *ordh-internal-only-fields*)
      *ordh-caller-writable-fields*))

(defun nst-ordh-strip-identity-initargs (args)
  "ARGS without *ordh-update-stripped-initargs*. Pure: it returns a new plist, so the caller
   can still quote the original in a message."
  (loop for (k v) on args by #'cddr
        unless (member k *ordh-update-stripped-initargs*) append (list k v)))

(defun nst-order-header-field-refusal (args tenant-id channel)
  "NIL when every key in ARGS may be written on CHANNEL; otherwise the contradiction naming
   ALL the offending keys at once.

   ALL OF THEM, not the first: a client that sent three fields it may not write should learn
   about three, and a message reporting them one call at a time would take three round trips
   to converge. Called AFTER the strip, so the identity keys are already gone — and a key
   that is not a field of this entity at all lands here too, which is where it should land,
   because reinitialize-instance would otherwise RAISE on it and a raise is a 500."
  (let* ((writable (nst-ordh-writable-fields channel))
         (bad (loop for (k v) on args by #'cddr
                    unless (member k writable) collect k)))
    (when bad
      (make-instance 'nst-entity-contradiction
                     :tenant-id tenant-id
                     :reason (format nil "Order update refused, and NOTHING has been written: the ~A channel may not write ~{~S~^, ~}. The order-to-invoice link, the cancellation state and the denormalised customer name belong to their own verbs; the status, the fulfilment flag and the shipped date are internal-only (channels ~{~A~^, ~}). Writable on this channel: ~{~S~^, ~}."
                                     (or channel :external)
                                     bad
                                     *ordh-internal-channels*
                                     writable)))))

(defun nst-ordh-consume-control-key (args key)
  "Remove KEY from ARGS and return (values VALUE REMAINING). A control key is consumed
   whether or not it has a value, so a NIL validator means absent rather than unmatched — an
   empty If-Match is not a claim about the version."
  (values (getf args key)
          (loop for (k v) on args by #'cddr unless (eq k key) append (list k v))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; F8 — the version token: ETag on read, If-Match on write (RFC 9110 / AIP-154)
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-ordh-version-token (value)
  "A TIMESTAMP column as YYYY-MM-DD HH:MM:SS, NIL for NIL, and a string unchanged.

  ⚠ THE TYPE IS MEASURED, NOT ASSUMED, and it is the reason for the handler-case: dod-order
  declares UPDATED as (string 30), so most reads arrive as a string — but a timestamp read
  back through this CLSQL can also arrive as a raw universal-time integer, which
  clsql-sys:decode-date SIGNALS on. Formatting what can be formatted and falling back to the
  printed representation is the contract the invoice's invh-json-timestamp already carries
  for the same column shape; a slightly ugly token beats a 500 on every write.
  (Consolidating the two into core/dod-bl-utl.lisp is on the ledger: this file loads BEFORE
  invoice/nst-bl-invh.lisp, so it cannot call that one.)"
  (cond ((null value) nil)
        ((stringp value) value)
        (t (handler-case
               (multiple-value-bind (second minute hour day month year)
                   (clsql-sys:decode-date value)
                 (format nil "~4,'0d-~2,'0d-~2,'0d ~2,'0d:~2,'0d:~2,'0d"
                         year month day hour minute second))
             (error () (princ-to-string value))))))

(defun nst-ordh-if-match-value (raw)
  "The validator inside a caller-supplied If-Match value. The surrounding quotes and the
   weak prefix W/ are RFC 9110 SYNTAX, not part of the version: an ETag is emitted weak and
   quoted, and a verb that compared the header text byte-for-byte would reject every
   validator the same API had just handed out. NIL for NIL."
  (when raw
    (let* ((s (string-trim '(#\Space #\Tab #\Newline #\Return) (string raw)))
           (s (if (and (> (length s) 1) (string-equal "W/" s :end2 2)) (subseq s 2) s))
           (s (string-trim '(#\Space #\Tab) s)))
      (if (and (> (length s) 1)
               (char= (char s 0) #\")
               (char= (char s (1- (length s))) #\"))
          (subseq s 1 (1- (length s)))
          s))))

(defun nst-order-header-if-match-refusal (dbobj expected tenant-id)
  "NIL when EXPECTED is absent or matches the row's UPDATED; otherwise a contradiction.

   A 412 IS NOT A 409, and the route layer owns the difference: both are this domain's
   vocabulary for UNDERSTOOD AND REFUSED, and F13 records that the shared classifier has no
   409 case yet, so S13 has to map them deliberately rather than let a sentinel become
   whichever number the classifier happens to hold. What the DOMAIN can state is the fact:
   the row changed after the caller read it, and re-applying a change on top of a version
   nobody has seen is how one writer's work disappears.

   COMPARED AS STRINGS, and the token is never parsed: it is an opaque validator. Comparing
   the caller's text with the row's formatted text is the whole contract — no date arithmetic
   here and no timezone to get wrong."
  (when expected
    (let* ((current (nst-ordh-version-token (slot-value dbobj 'updated)))
           (given (nst-ordh-if-match-value expected)))
      (unless (and current given (string= current given))
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason (format nil "Order update refused before anything was written: the caller's If-Match validator ~S does not match this order's current version ~S, so the order changed after the caller read it. Re-read the order and re-apply the change. [RFC 9110: 412 Precondition Failed — the route layer maps this sentinel, and 412 is not 409.]"
                                       given current))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; !update — !state प्रत्यय
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-order-header-update-write (ctx tenant-id dbobj args)
  "Hydrate, apply only the supplied fields, write every mirrored slot back, answer in
   four-valued terms. The last step of an update, extracted so the caller reads as a list of
   steps rather than a staircase — depth is where paren errors live (file header).

   THE WRITE IS WHOLE-ROW, DELIBERATELY. clsql:update-records-from-instance writes every
   column of the instance, and the instance was hydrated from the row it writes back — so
   this IS F8's last-write-wins, and If-Match is what makes that safe instead of silent.
   It also cannot touch UPDATED: the mirrored list does not carry it (D19), so the column
   keeps its ON UPDATE CURRENT_TIMESTAMP behaviour."
  (let ((entity (make-instance 'nst-ordh :tenant-id tenant-id)))
    (nst-copy-order-header-dbtodomain dbobj entity)     ; hydrate current state
    (apply #'reinitialize-instance entity args)         ; CLOS partial update
    (nst-copy-order-header-domaintodb entity dbobj)
    (let ((knowledge (with-nst-db-update (:source "nst-ordh/!update")
                        (clsql:update-records-from-instance dbobj)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T entity)
        (:F ;; Unreachable: no :pre-flight was supplied, so with-nst-db-update cannot
            ;; produce :F — the SELECT above already confirmed a live row in this tenant.
            (error "Unreachable: with-nst-db-update without :pre-flight cannot return :F (order header row-id ~A)"
                   (slot-value dbobj 'row-id)))
        (:U (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Order update: the database call did not answer, so whether the row was written is UNKNOWN — this is not 'it failed'. The row may hold either the old or the new values; re-read it before deciding."))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-update"
                          (bo-knowledge-truth knowledge)))))))

(defun nst-order-header-update (ctx tenant-id channel dbobj update-args)
  "The update as a SEQUENCE OF STEPS that each return early with a refusal, FLAT ON PURPOSE
   (file header). Every refusal happens before any write, so a refused update has written
   nothing — the property S5's acceptance criterion proves by re-reading the row.

   ⚠ THE CONTROL KEYS ARE CONSUMED BEFORE THE FIELD POLICY, AND THAT ORDER IS A FIX (S12).
   Written the other way round — policy first, control key second — `:if-match` reached
   `nst-order-header-field-refusal` as an ordinary key, was refused as an escalation, and so
   EVERY If-Match update answered 409 with 'the :http channel may not write :IF-MATCH'. The
   precondition was therefore unusable through the verb no matter what the route did. Found by
   reading the S12 route against this function, not by running it, and the S12 route had already
   worked around it by asking nst-order-header-if-match-refusal itself; with this fix the verb
   is also correct for the DIRECT callers (a REPL, an :agent, a batch job) that never pass a
   route, which is the whole reason the control keys exist as a concept."
  ;; 1. the status gate (D8): content may move at any status except the terminal triple
  (let ((status (nst-ordh-status-string (slot-value dbobj 'status))))
    (when (member status *order-terminal-statuses* :test #'string=)
      (return-from nst-order-header-update
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason (format nil "Order update refused: this order is ~A, which is terminal, so its content is frozen. Nothing has been written. A completed, vendor-cancelled or customer-cancelled order is a finished document — the way to change what it says is a new document, not an edit to this one."
                                       (or status (slot-value dbobj 'status)))))))
  ;; 2. the transport preconditions come out FIRST — see the docstring: they are not entity
  ;;    state and the field policy below must never see them
  (multiple-value-bind (expected args) (nst-ordh-consume-control-key update-args :if-match)
    ;; 3. what this channel may write — the identity keys stripped first, so a stripped key is
    ;;    never reported as an escalation
    (let ((args (nst-ordh-strip-identity-initargs args)))
      (let ((refusal (nst-order-header-field-refusal args tenant-id channel)))
        (when refusal (return-from nst-order-header-update refusal)))
      ;; 4. the version precondition, if the route supplied one
      (let ((refusal (nst-order-header-if-match-refusal dbobj expected tenant-id)))
        (when refusal (return-from nst-order-header-update refusal)))
      ;; 5. hydrate, apply, write, answer
      (nst-order-header-update-write ctx tenant-id dbobj args))))

(defmethod !update ((entity-class (eql 'nst-ordh)) (row-id string) (ctx domain-ctx)
                    &rest update-args)
  "Assign fields on an existing order. A PARTIAL update: the row is selected and hydrated,
   then reinitialize-instance applies only the initargs actually supplied, so an omitted
   field keeps its stored value instead of being reset to its class default.

   THE ORDER OF THE FOUR QUESTIONS, and why it is this one: is there such a row (absence
   first — a 404 is about the ADDRESS, and a caller that named a row which is not there
   should not be lectured about field policy); is it terminal (a fact about the ROW, and the
   most specific answer available); may this channel write these fields (a fact about the
   REQUEST); does the caller's validator match (a fact about TIMING). A refusal at any step
   writes nothing.

   NOT BLOCKED ONCE CONVERTED TO AN INVOICE, and that is a decision copied from the invoice
   verb rather than invented: the invoice's own !update is deliberately NOT blocked after
   generation, because *invoice-settings* states allow-invoice-edit-after-generation the
   other way, and a domain verb that refused would be inventing a policy the configuration
   already answers. O4's conversion bar is about DELETION — where the document stops
   existing — not about content. (A converted order is normally terminal anyway, which step 1
   answers.)

   THE FRESH VALIDATOR IS NOT RETURNED, and that is stated rather than approximated: UPDATED
   is DB-managed and the CLSQL instance in hand still holds the PRE-write value, so a token
   read from it would be STALE. The route layer re-reads when it wants to emit a new ETag on
   the response — RFC 9110 permits omitting it — because a stale ETag here would make every
   later If-Match fail, which is worse than no ETag at all."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (channel (domain-ctx-channel ctx))
         (rid (nst-row-id-from-string row-id)))
    (if (null rid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address an order header row (row-ids are integers)" row-id))
        (let ((dbobj (nst-select-order-header-by-row-id rid tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Order update, row-id ~A: no LIVE order header with that row-id in this tenant — it does not exist, or it has been soft-deleted, and either way there is nothing here to update" row-id))
              (nst-order-header-update ctx tenant-id channel dbobj update-args))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; delete! — लोप प्रत्यय (soft, and only from DFT)
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-order-header-soft-delete (ctx tenant-id dbobj)
  "The two refusals and the writes, flat. Every refusal returns a sentinel, and each write is
   ONE COLUMN — with-nst-db-delete writes only deleted-state, so a delete cannot clobber a
   concurrent change to any other column. That is why the delete macro is right here and
   !update's whole-row write is not.

   ⚠ THE LINES GO WITH THE HEADER, LINES FIRST, AND THAT ORDER IS THE DESIGN (S7). It is the
   invoice batch's measured conclusion, and the reason it applies here is measured too:
   DOD_ORDER_ITEMS has NO foreign key on ORDER_ID at all (the only FK is TENANT_ID →
   DOD_COMPANY) — so there is no ON DELETE CASCADE to fire, and even where one exists it fires on
   a HARD delete, which a soft delete never issues.

     lines → header   a half-finished delete leaves the header LIVE and therefore reachable by
                      row-id, and re-running the verb finishes the job
     header → lines   a half-finished delete would leave a deleted header with LIVE lines behind
                      it — and nothing can reach those lines, because every path to a line runs
                      through its header. Invisible rows that still count as live.

   There is no transaction around the two writes and this layer has no transaction idiom
   (with-hhub-transaction is the ABAC policy point, not a DB transaction), so if the line write
   does not fully succeed the header is left UNTOUCHED and the sentinel's reason says so; if the
   header write then fails, the reason reports how many lines were already marked, because that
   tally is the only record of what the call actually did."
  ;; 1. O4 — once the order has been converted, the invoice is the record
  (when (string-equal (or (slot-value dbobj 'is-converted-to-invoice) "N") "Y")
    (return-from nst-order-header-soft-delete
      (make-instance 'nst-entity-contradiction
                     :tenant-id tenant-id
                     :reason (format nil "Order delete refused: this order has been converted to invoice ~A, so the invoice is the record now and the order has to keep standing behind it. Nothing has been deleted. [LEGAL: the line the invoice batch draws at an issued invoice — an issued document is cancelled or credit-noted, never made never-to-have-existed.]"
                                     (or (slot-value dbobj 'invoice-number) :unknown)))))
  ;; 2. the status gate — a second list, for a second question
  (let ((status (nst-ordh-status-string (slot-value dbobj 'status))))
    (unless (member status *ordh-deletable-statuses* :test #'string=)
      (return-from nst-order-header-soft-delete
        (make-instance 'nst-entity-contradiction
                       :tenant-id tenant-id
                       :reason (format nil "Order delete refused: this order is ~A, and only ~{~A~^ or ~} may be deleted. Nothing has been deleted. A PLACED order is cancelled — a cancellation keeps the history the vendor rows already refer to — and a terminal one has finished, so deleting it would hide a document other records point at."
                                       (or status (slot-value dbobj 'status))
                                       *ordh-deletable-statuses*)))))
  ;; 3. the LINES first, then the header — see the docstring for why the order is the design
  (let ((lines (nst-soft-delete-order-items-for-header (slot-value dbobj 'row-id) tenant-id)))
    (unless (eq (bo-knowledge-truth lines) :T)
      ;; The lines did not all get marked. THE HEADER IS UNTOUCHED — said explicitly, because
      ;; the reader of a 503 must not conclude the order is gone, and the caller can simply
      ;; re-run. The helper's provenance carries the tally.
      (return-from nst-order-header-soft-delete
        (domain-sentinel-from-knowledge
         lines ctx
         :reason (format nil "Order delete, row-id ~A: the LINE soft-delete did not complete, so the header was left UNTOUCHED and is still live — re-run the delete once the database answers"
                         (slot-value dbobj 'row-id)))))
    (let* ((marked (bo-knowledge-payload lines))
           (knowledge (with-nst-db-delete (:source "nst-ordh/delete!")
                       (setf (slot-value dbobj 'deleted-state) "Y")
                       (clsql:update-record-from-slot dbobj 'deleted-state)
                       dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T t)
        (:F ;; Unreachable without :pre-flight — the SELECT above confirmed a live row.
            (error "Unreachable: with-nst-db-delete without :pre-flight cannot return :F (order header row-id ~A)"
                   (slot-value dbobj 'row-id)))
        (:U ;; The lines are Y and the header's state is unknown. Report the tally WITH the
            ;; ignorance: it is the only record of how far this call got.
            (domain-sentinel-from-knowledge
             knowledge ctx
             :reason (format nil "Order delete, row-id ~A: ~A line(s) were already soft-deleted, but the header write did not answer — whether the order itself was soft-deleted is UNKNOWN. Re-read it rather than assuming either answer."
                             (slot-value dbobj 'row-id) marked)))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-delete"
                          (bo-knowledge-truth knowledge)))))))

(defmethod delete! ((entity-class (eql 'nst-ordh)) (row-id string) (ctx domain-ctx))
  "Soft-delete an order header: DELETED_STATE becomes Y, and nothing is ever removed from
   the table — नियम-2 blocks every later verb on the result, and physical removal is not this
   project's concern.

   RETURNS T, not the entity: the row is gone from every verb's sight, so handing back a
   live-looking entity would invite the caller to read fields that no longer answer. That is
   the invoice's own choice for this verb, and the four-valued refusals are unchanged — a
   delete that cannot happen is a sentinel, never a bare NIL.

   THE ORDER'S LINES GO WITH IT, LINES FIRST, AND THE REASON IS MEASURED RATHER THAN COPIED
   (S7 closed the gap S5 had left open, and corrected what S5 said about it): DOD_ORDER_ITEMS
   has NO foreign key on ORDER_ID — the only FK on that table is TENANT_ID → DOD_COMPANY — so
   there is no ON DELETE CASCADE to fire here, and even where such a key exists it fires on a
   HARD delete, which a soft delete never issues. The invoice's comment says CASCADE; believing
   it instead of measuring this table is how S5 came to describe a cascade that does not exist.
   The लोप helper (nst-soft-delete-order-items-for-header, in nst-bl-orditm.lisp) marks every
   live line first, and the header is left UNTOUCHED if that does not fully succeed.

   A row that is ALREADY soft-deleted answers the same 404 as a row that never existed,
   because the selector cannot see it: नियम-2 makes those one fact for every verb."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (rid (nst-row-id-from-string row-id)))
    (if (null rid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address an order header row (row-ids are integers)" row-id))
        (let ((dbobj (nst-select-order-header-by-row-id rid tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Order delete, row-id ~A: no LIVE order header with that row-id in this tenant — it does not exist, or it has already been soft-deleted" row-id))
              (nst-order-header-soft-delete ctx tenant-id dbobj))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; S6 — the reverse ferry, and the outbound JSON allowlist
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; THREE THINGS ARE ALREADY SHARED, AND REDEFINING THEM HERE WOULD BE A FOURTH COPY OF A
;;; RULE THAT ALREADY HAS A HOME:
;;;
;;;   * the DOMAIN-SENTINEL ferry (nst-entity-nil / -unknown / -contradiction →
;;;     nst-response-nil / -unknown / -contradiction) is in warehouse/nst-bl-whsapi.lisp:280
;;;     and dispatches on TYPE, so every entity inherits it — including this one. That file's
;;;     own comment says it belongs in adhara and should move on the next adhara pass.
;;;   * the sentinel RENDERING (render-json/render-html per response sentinel) is there too
;;;     (whsapi:320-333), which is why a 404/503/409 body for an order route needs nothing
;;;     from this file.
;;;   * the delete! ACK path: delete! returns a bare T, and whsapi:299 ferries (eql t) into a
;;;     warehouse-ack-response. The SHAPE is the one every entity's delete! ack already uses;
;;;     only the NAME is warehouse's, and renaming a shared boundary class is a shared-file
;;;     change, not this story's. Recorded so the wart is not mistaken for a bug.

(defparameter *ordh-json-withheld-slots* '(deleted-state)
  "Response-model slots that must NOT leave the system, NAMED SO THE CHECK CAN ADD UP.

   ⚠ THE POINT IS THE COMPLETENESS ASSERTION, WHICH THE INVOICE'S render-json DOES NOT HAVE.
   An outbound allowlist is written field by field, so a slot added to the response model
   simply never leaves — the same class of failure as the missing-slot 500 that took the
   invoice API down, in the other direction and just as quiet. Stating the withheld set makes
   the sentence publish + withhold = every slot, and the offline check asserts it: a new slot
   now forces a DECISION (publish it, or name it here) instead of a silence.

   deleted-state is withheld because it is नियम-2's own predicate rather than domain state: a
   client that could see it could reason about rows this API will never return, and the
   invoice withholds exactly this slot for exactly this reason.")

(defun nst-ordh-json-flag (value)
  "tinyint(1) BOOLEAN column → a real JSON boolean. 0 and NIL are FALSE; anything else is true.

   ⚠ IT IS A GUARD, NOT (if value t nil), BECAUSE 0 IS TRUTHY IN LISP: the naive form reports
   a FALSE column as true, which is how 'reverse charge does not apply' becomes 'applies' in
   a client. Same defect the invoice's invh-json-flag documents, same three columns here
   (reverse-charge-applicable / eway-bill-required / tds-applicable).

   ⚠ AND IT MUST NOT BE USED ON char(1) FLAGS. This schema stores some flags as the STRINGS
   Y and N, and (and value (not (eql value 0))) answers T for the string N — the same lie one
   type over. Those columns leave as the CODES THE COLUMN STORES (see render-json below), so a
   client reads N rather than believing a boolean this file invented for it.

   ⚠ CONSOLIDATION IS ON THE LEDGER, with invh-json-flag and nst-ordh-version-token: three
   spellings of one rule, in three files, the order one unable to call the invoice's because
   this file loads FIRST (position 179 against the invoice's 300).")

(defun nst-ordh-json-date (value)
  "A DATE column → YYYY-MM-DD, NIL → NIL, a string passes through unchanged.

   get-datestr-from-obj-yyyymmdd is the DATE reader and it lives in core/dod-bl-utl.lisp:740 —
   early enough to be callable from here. The handler-case is the invoice's, for the invoice's
   reason: it formats what it can and falls back to the printed representation, because a
   column that arrives in a shape the reader does not expect should degrade one field rather
   than 500 the whole response."
  (cond ((null value) nil)
        ((stringp value) value)
        (t (handler-case (get-datestr-from-obj-yyyymmdd value)
             (error () (princ-to-string value))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; domain->response — nst-ordh → NstOrdhResponseModel (the reverse ferry)
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; THIS HOP MIRRORS: every declared slot crosses, driven by the same *ordh-mirrored-slots*
;;; the two copy ferries use, so the response shape cannot drift from the entity. The decision
;;; that actually matters is which fields LEAVE THE SYSTEM, and that allowlist is render-json
;;; below, per format, where it belongs.
;;;
;;; IT IS LIST-DRIVEN, WHICH IS THE SHAPE THAT TOOK THE INVOICE API DOWN — and the reason a
;;; check exists rather than a promise: a slot in the list but missing from the boundary class
;;; signals MISSING-SLOT on EVERY response, and compile-file does not evaluate the setf, so no
;;; compiler, no load and no route audit can see it. aiharness/deepseek/tools/
;;; nst-order-mirror-check.lisp performs this exact setf for every slot, offline.

(defmethod domain->response ((entity nst-ordh) (ctx domain-ctx))
  (let ((destination (make-instance 'NstOrdhResponseModel)))
    (setf (slot-value destination 'row-id) (row-id entity))
    (dolist (slot *ordh-mirrored-slots*)
      (setf (slot-value destination slot) (slot-value entity slot)))
    destination))

(defun domain->response-list (entities ctx)
  "Carries each nst-ordh through domain->response, returning a list of NstOrdhResponseModel
   objects. A plain function, not a generic: the per-element dispatch already happens inside
   domain->response, and wrapping mapcar in a method on list would be false ceremony.
   BELNAP NOTE: a pure structural transform — it does NOT inspect each element's truth, so
   filter sentinels BEFORE calling it."
  (mapcar (lambda (dom) (domain->response dom ctx)) entities))

;;; ───────────────────────────────────────────────────────────────────────────
;;; render-json — NstOrdhResponseModel, and lists of it
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; SECURITY CONTRACT: this method IS the outbound field allowlist. A slot added to
;;; NstOrdhResponseModel does NOT auto-leak — it must be named here, per format, and if it is
;;; meant to stay inside it must be named in *ordh-json-withheld-slots* so the sums still add
;;; up. Three conventions, all measured from the column declarations rather than guessed:
;;;
;;;   * IDENTIFIERS leave as JSON strings via response-id-string (NIL → null), because
;;;     row-id / cust-id / created-by-user-id / approved-by-user-id are integers in the row
;;;     and the wire would otherwise mix 47, "47" and null for the same kind of value;
;;;   * DATE columns leave as YYYY-MM-DD — NOT as a midnight timestamp, so a client parsing
;;;     them gets a date;
;;;   * tinyint(1) columns leave through nst-ordh-json-flag, and char(1) Y/N flags leave as
;;;     the CODES THE COLUMN STORES. Two conventions, stated, because applying the boolean
;;;     guard to a Y/N column would report N as true.
;;;
;;; NOT NULL money columns are always present; nullable ones may be null and are NOT
;;; defaulted to 0, because 'nothing was shipped yet' and 'zero shipping cost' are different
;;; facts — the same distinction the invoice draws.

(defmethod render-json ((r NstOrdhResponseModel) (ctx domain-ctx))
  "One order header → a JSON alist. The caller, or the list method below, applies
   json:encode-json-to-string."
  (declare (ignore ctx))
  (list
   (cons "rowId"                   (response-id-string (row-id r)))
   ;; identity of the document
   (cons "ordnum"                  (ordnum r))
   (cons "contextId"               (context-id r))
   ;; dates — the schedule as the customer states it
   (cons "ordDate"                 (nst-ordh-json-date (ord-date r)))
   (cons "reqDate"                 (nst-ordh-json-date (req-date r)))
   (cons "shippedDate"             (nst-ordh-json-date (shipped-date r)))
   (cons "expectedDeliveryDate"    (nst-ordh-json-date (expected-delivery-date r)))
   (cons "orderType"               (order-type r))
   (cons "orderSource"             (order-source r))
   ;; document state. status and the two order-lifecycle flags are char(3)/char(1) CODES,
   ;; not booleans: Y and N are what the column holds and what a client compares against.
   (cons "status"                  (status r))
   (cons "orderFulfilled"          (order-fulfilled r))
   (cons "isConvertedToInvoice"    (is-converted-to-invoice r))
   (cons "isCancelled"             (is-cancelled r))
   (cons "invoiceNumber"           (invoice-number r))
   (cons "invoiceDate"             (nst-ordh-json-date (invoice-date r)))
   (cons "cancelReason"            (cancel-reason r))
   ;; parties
   (cons "custId"                  (response-id-string (cust-id r)))
   (cons "custName"                (cust-name r))
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
   ;; tax identity and place of supply
   (cons "gstNumber"               (gst-number r))
   (cons "gstOrgName"              (gst-org-name r))
   (cons "placeOfSupply"           (place-of-supply r))
   (cons "placeOfSupplyCode"       (place-of-supply-code r))
   (cons "supplyType"              (supply-type r))
   ;; the three tinyint(1) flags — the ones the guard exists for
   (cons "reverseChargeApplicable" (nst-ordh-json-flag (reverse-charge-applicable r)))
   (cons "ewayBillRequired"        (nst-ordh-json-flag (eway-bill-required r)))
   (cons "tdsApplicable"           (nst-ordh-json-flag (tds-applicable r)))
   (cons "tdsAmount"               (tds-amount r))
   ;; money
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

;;; ⚠ NO render-json METHOD ON `list` IS DEFINED HERE — S6 DEFINED ONE AND S7 REMOVED IT,
;;; because the invoice's item file states the reason this file had not yet read
;;; (nst-bl-invitm.lisp:705-712): the method on `list` is ELEMENT-AGNOSTIC — it maps
;;; render-json over the elements — so the one already in the tree encodes a list of
;;; NstOrdhResponseModel correctly, and a second method with the SAME SPECIALIZERS does not
;;; coexist with it: CLOS keeps the later definition. S6's copy had an identical body, so
;;; nothing broke; that is luck rather than design, and the failure it invites is silent —
;;; fixing this file's list rendering by replacing the warehouse's or the invoice's.
;;; The dependency is real and is recorded rather than hidden: enumerate's list path renders
;;; through a method defined in warehouse/nst-bl-whsapi.lisp (or nst-bl-invh.lisp; the bodies
;;; are identical), both of which are in the same build, so it is defined by the time any
;;; verb can run. Consolidating the two into core remains on the ledger.

;;; End of nst-bl-ordh.lisp
