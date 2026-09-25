;;; nst-bl-invitm.lisp — Tier-1 प्रत्यय for an invoice LINE (nst-invitm)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;; ═══════════════════════════════════════════════════════════════════════════
;;; The six universal प्रत्यय of nst-bl-adhara.lisp, specialized on nst-invitm:
;;;
;;;   make       सृजन          add a line to a DRAFT invoice
;;;   fetch      स्मरण          recall one line by row-id
;;;   enumerate  दर्शन          list one header's lines, or the whole tenant's
;;;   !update    !state         assign columns on an existing line
;;;   delete!    लोप            SOFT delete, and only while the header is a DRAFT
;;;   ?exists    प्रत्यभिज्ञा   does this header already carry this product
;;;
;;; A LINE LIVES INSIDE A DOCUMENT, AND EVERY VERB PROVES THE DOCUMENT EXISTS.
;;; No verb here acts on a line without first selecting the header it belongs to
;;; through select-invoice-header-by-row-id — scoped by the SESSION tenant, never
;;; by anything the caller sent. That is the whole authorization model for this
;;; entity: invheadid is a caller-supplied integer, so a verb that trusted it
;;; would expose another tenant's invoice lines to anyone who guessed one number
;;; (OWASP API1:2023, BOLA). The extra SELECT per verb is the price and it is not
;;; negotiable.
;;;
;;; THE STATUS RULE, and why it is not the header's rule:
;;;
;;;   make / delete!   RESTRUCTURE the document → refused unless the header is in
;;;                    *invitm-open-header-statuses* (DRAFT). Adding a line to an
;;;                    issued invoice changes what was taxed; removing one is what
;;;                    a credit note is for. [LEGAL]
;;;   !update          corrects a VALUE on the document → allowed at any status,
;;;                    which is what *invoice-settings*' security-settings says
;;;                    (allow-invoice-edit-after-generation t) and what nst-invh's
;;;                    own !update already does. Correcting a rate is not
;;;                    restructuring the invoice.
;;;
;;; So the split is content vs. values, not DRAFT vs. everything. If that reading
;;; of allow-invoice-edit-after-generation is wrong, this paragraph and the
;;; *invitm-open-header-statuses* checks are the only places to change.
;;;
;;; NOT DONE HERE, ON PURPOSE:
;;;   * NO TOTALS ROLL-UP. Adding, changing or removing a line does NOT touch the
;;;     header's TOTALVALUE — the same gap nst-bl-invh.lisp documents. [LEGAL: the
;;;     rule that matters is that an ISSUED invoice's total agrees with its lines;
;;;     that belongs to `issue`, which does not exist yet, and a roll-up written
;;;     here would not close it anyway, because a direct header !update can set any
;;;     total it likes.]
;;;   * no item-level route-* verbs and no register-api-route bindings.
;;;   * no check-niyam call — as in nst-whs and nst-invh; नियम-1 is enforced by the
;;;     tenant-scoped SELECTs.
;;;
;;; MUTUAL REFERENCE WITH nst-bl-invh.lisp: the header's delete! calls
;;; nst-soft-delete-invoice-items-for-header (the लोप helper at the bottom of this
;;; file), and every verb here calls the header's select-invoice-header-by-row-id —
;;; plus invh-status-string and *invitm-open-header-statuses*' sibling list. Lisp
;;; resolves both directions at run time, and nstores.asd lists nst-bl-invh FIRST, so
;;; every header symbol this file uses is already defined when this file compiles:
;;; the build's single undefined-function style-warning is nst-bl-invh's reference to
;;; the one item symbol, defined immediately after it. That single warning is
;;; expected, and it is the whole cost of the mutual reference.
;;; ═══════════════════════════════════════════════════════════════════════════

(defparameter *invitm-sort-whitelist*
  '((:row-id . :row-id) (:prd-id . :prd-id) (:hsncode . :hsncode) (:qty . :qty)
    (:taxable-value . :taxable-value) (:totalitemval . :totalitemval))
  "The ONLY columns enumerate may sort by — the same guard as the header's, for
  the same reason: sort-by is caller-controllable (eventually from a query string),
  so a raw column name must never reach ORDER BY.

  Default order is row-id and is deliberately NOT required to appear here as a
  special case — row-id is insertion order, which is the order the vendor typed the
  lines and the order an invoice prints. No amount or code sorts equivalently.")

(defparameter *invitm-open-header-statuses* '("DRAFT")
  "Header statuses in which the DOCUMENT MAY BE RESTRUCTURED — i.e. in which a line
  may be added (make) or removed (delete!).

  Deliberately a SEPARATE list from nst-invh's *invh-deletable-statuses*, even
  though both currently hold only DRAFT: that one answers 'may this document be
  soft-deleted?', this one answers 'may this document's content change?'. GST law
  can move one without the other, and sharing one list would silently tie the two
  rules together.")

(defparameter *invitm-mirrored-slots*
  '(;; parent
    invheadid
    ;; what is being sold
    prd-id prddesc hsncode
    ;; quantity and price
    qty uom price discount
    ;; tax breakdown
    taxable-value cgstrate cgstamt sgstrate sgstamt igstrate igstamt totalitemval
    ;; line state
    status deleted-state)
  "Slots that exist on BOTH nst-invitm and dod-invoice-items under the same name —
  the same list-driven mirror as *invh-mirrored-slots*, for the same reason:
  nst-invitm was given the DOD class's own slot names, so the only information the
  copiers carry is WHICH COLUMNS EXIST, and a list states that once instead of
  twice.

  Deliberately excludes row-id (bound only after the INSERT) and tenant-id (a
  नियम-1 value, set from domain-ctx, never a plain mirror).

  ⚠ There is NO cess slot to mirror: DOD_INVOICE_ITEMS has CGST/SGST/IGST only.
  That is a schema gap recorded in nst-dal-invitm.lisp, not an omission here.")

;;; ───────────────────────────────────────────────────────────────────────────
;;; Small helpers
;;; ───────────────────────────────────────────────────────────────────────────

(defun invoice-item-row-id-from-string (id)
  "Row-ids arrive as STRINGS: apidefs2 passes path params through unchanged and
  every id crosses the API boundary as a JSON string. Returns the integer row-id,
  or NIL when the string cannot address a row at all — a NIL the callers read as an
  absence fact (:F → 404), never as a boundary failure (:U → 503).

  THE FOURTH COPY of this guard (nst-whs, products and nst-invh each have one). The
  nst-invh copy says three copies is where the promotion is due, and that is right —
  but the promotion edits core/nst-bl-adhara.lisp, which every file depends on, and
  it does not belong inside an invoice-lines change. Queued as its own change."
  (when (stringp id)
    (handler-case (parse-integer id :junk-allowed nil)
      (error () nil))))

(defun invitm-id-from-value (value)
  "Coerce a caller-supplied id to an integer, or NIL when it cannot be one. Used
  for invheadid and prd-id, which reach a verb as an integer (a JSON number) or as a
  string (a path param, a query string, a JSON string) depending on the transport."
  (cond ((null value) nil)
        ((integerp value) value)
        ((stringp value) (invoice-item-row-id-from-string value))
        (t nil)))

;;; ───────────────────────────────────────────────────────────────────────────
;;; QUERY FUNCTIONS — every read is tenant-scoped by construction
;;; ───────────────────────────────────────────────────────────────────────────

(defun validate-invitm-sort-args (sort-by sort-dir)
  (let ((col (cdr (assoc sort-by *invitm-sort-whitelist*))))
    (unless col
      (error "enumerate: sort-by ~A not in whitelist ~A" sort-by *invitm-sort-whitelist*))
    (unless (member sort-dir '(:asc :desc))
      (error "enumerate: sort-dir must be :asc or :desc, got ~A" sort-dir))
    (values col sort-dir)))

(defun build-invitm-filter-clauses (tenant-id &key invheadid status include-deleted)
  "गण: Anusthup. Assembles WHERE clauses for invoice-line queries.

  ⚠ DOD_INVOICE_ITEMS.DELETED_STATE IS `char(1) DEFAULT NULL`, exactly like the
  header's and unlike DOD_WAREHOUSE's 'N', and dod-invoice-items declares
  :void-value \"N\" — so legacy rows hold SQL NULL. The 'not deleted' test is
  therefore an OR, and it cannot be written [= … nil]: CLSQL renders a NIL
  sub-expression as the literal NULL, and `DELETED_STATE = NULL` is true for no row
  at all. See build-invh-filter-clauses in nst-bl-invh.lisp for the full note.

  INCLUDE-DELETED is a keyword here, where the header's builder hard-codes the live
  clause. Not an inconsistency for its own sake: a line is the unit an audit asks
  about ('what was on this invoice before it was edited?'), so enumerate needs the
  every-row form, while the header's enumerate never does."
  (let ((clauses (list [= [:tenant-id] tenant-id])))
    (unless include-deleted
      (push [or [= [:deleted-state] "N"]
                [is [:deleted-state] nil]] clauses))
    (when invheadid (push [= [:invheadid] invheadid] clauses))
    (when status (push [= [:status] (invh-status-string status)] clauses))
    clauses))

(defun select-invoice-items-by-filter (tenant-id &key invheadid status include-deleted
                                                  (sort-by :row-id) (sort-dir :asc))
  "Lines for TENANT-ID, optionally narrowed to one header and/or one status. Returns
  a LIST — a header legitimately has zero, one or many lines, so an empty list is a
  result, not an absence."
  (multiple-value-bind (sort-col sort-dir) (validate-invitm-sort-args sort-by sort-dir)
    (clsql:select 'dod-invoice-items
                  :where (apply #'clsql:sql-and
                                (build-invitm-filter-clauses
                                 tenant-id :invheadid invheadid
                                           :status status
                                           :include-deleted include-deleted))
                  :order-by (list (list sort-col sort-dir))
                  :caching *dod-database-caching* :flatp t)))

(defun select-invoice-items-for-header (invheadid tenant-id &key include-deleted)
  "Every line of header INVHEADID in TENANT-ID, ordered by row-id (insertion order —
  the order the vendor typed them, and the order an invoice must print).

  INCLUDE-DELETED decides the question, as in the header's own selects:
    NIL — the header's LIVE lines (what a read or a re-total must see)
    T   — every line it ever had (what a 'did this invoice have lines?' audit asks,
          because a soft-deleted line keeps its row)

  Thin delegate to select-invoice-items-by-filter, kept as its own name because it
  is the entry point the header's लोप helper reads its work from. Scoped by
  TENANT-ID as well as INVHEADID, so a guessed invheadid yields an empty list rather
  than another tenant's data."
  (select-invoice-items-by-filter tenant-id :invheadid invheadid
                                             :include-deleted include-deleted))

(defun select-invoice-item-by-row-id (id tenant-id)
  "One live line by primary key, in this tenant. ID is an INTEGER here — the string
  guard belongs to the verbs, which must answer :F for an unparsable id before any
  query runs, or (parse-integer \"abc\") raises, with-db-call catches it as :U, and a
  malformed request is reported as 503."
  (car (clsql:select 'dod-invoice-items :where
                     [and
                      [= [:tenant-id] tenant-id]
                      [= [:row-id] id]
                      [or [= [:deleted-state] "N"]
                          [is [:deleted-state] nil]]]
                     :caching *dod-database-caching* :flatp t)))

(defun select-invoice-items-by-prd-id (prd-id invheadid tenant-id)
  "The live line this header carries for this product, or NIL.

  NOT a uniqueness query, and it must never be read as one: nothing in the schema
  makes (INVHEADID, PRD_ID) unique, and the same product on two lines is a
  legitimate invoice — a different rate, discount, batch or HSN. This answers the
  question the legacy UI asks before adding a product (select-invoice-item-by-
  product-id, nst-bl-itm.lisp) — 'is this already on the invoice?' — where :T is a
  WARNING, not a refusal.

  The CAR is honest because the caller only asks whether any such line exists; any
  surplus IS the duplication the caller was asking about."
  (car (clsql:select 'dod-invoice-items :where
                     [and [= [:invheadid] invheadid]
                          [= [:prd-id] prd-id]
                          [= [:tenant-id] tenant-id]
                          [or [= [:deleted-state] "N"]
                              [is [:deleted-state] nil]]]
                     :caching *dod-database-caching* :flatp t)))

(defun nst-fetch-visible-invoice-header (invheadid tenant-id)
  "The document INVHEADID as THIS TENANT may see it, or the reason there is none.
  Returns a bo-knowledge: :T payload = the header DB object; :F absent,
  soft-deleted, or another tenant's; :U the database did not answer.

  ONE function for every verb's parent check, so a new verb cannot accidentally
  invent a weaker one. It deliberately takes no status: the status rules differ per
  verb (see the content-vs-values split in this file's header), so the caller applies
  its own to the payload."
  (with-db-call (select-invoice-header-by-row-id invheadid tenant-id)
                "nst-invitm/parent-header"))

;;; ───────────────────────────────────────────────────────────────────────────
;;; DOMAIN <-> DB COPY HELPERS
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-copy-invoice-item-domaintodb (source destination)
  "nst-invitm → dod-invoice-items."
  (dolist (slot *invitm-mirrored-slots*)
    (setf (slot-value destination slot) (slot-value source slot)))
  (setf (slot-value destination 'tenant-id) (tenant-id source))
  destination)

(defun nst-copy-invoice-item-dbtodomain (source destination)
  "dod-invoice-items → nst-invitm."
  (setf (slot-value destination 'row-id) (slot-value source 'row-id))
  (setf (slot-value destination 'tenant-id) (slot-value source 'tenant-id))
  (dolist (slot *invitm-mirrored-slots*)
    (setf (slot-value destination slot) (slot-value source slot)))
  destination)

;;; ───────────────────────────────────────────────────────────────────────────
;;; ?exists — प्रत्यभिज्ञा
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; ⚠ THIS IS NOT AN IDENTITY CHECK, AND make DOES NOT CALL IT. A line has no
;;; natural key: the same product twice on one invoice is legitimate, the schema
;;; carries no UNIQUE constraint on (INVHEADID, PRD_ID), and no rule of GST makes
;;; the pair unique. So the four states below answer a QUESTION a form wants to ask
;;; ("is this already on the invoice?"), not a law the database enforces — the exact
;;; opposite of nst-whs's ?exists, whose :T drives a make :around refusal. Do not
;;; copy that :around here.

(defmethod ?exists ((entity-class (eql 'nst-invitm)) (prd-id t) (ctx domain-ctx)
                    &key invheadid &allow-other-keys)
  "Does the invoice header INVHEADID already carry a LIVE line for product PRD-ID?
  Belnap answer:
     :T  yes — a warning for a form, never a reason to refuse (see above)
     :F  no such line. NOTE: this is the answer whether the header is absent, empty,
         or simply lacks this product, and also when PRD-ID cannot be an integer at
         all — none of those can hold a matching line. A caller MUST NOT read :F as
         'the header exists' (use nst-fetch-visible-invoice-header for that).
     :U  the question could NOT be formed, or the database did not answer. Two
         different causes share the state because they share the consequence — we
         know nothing, so ':F, no duplicate' would be a fabrication. The provenance
         says which.
   &key invheadid is REQUIRED for a usable answer: the question is header-relative.
   &allow-other-keys is CLOS congruence with the generic function's lambda list."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (pid (invitm-id-from-value prd-id))
         (rid (invitm-id-from-value invheadid)))
    (cond
      ((null rid)
       (make-bo-knowledge
        :truth :U :payload nil
        :provenance "nst-invitm/?exists: no usable :invheadid — a line's existence is a question about ONE invoice, so it cannot be answered without one"))
      ((null pid)
       ;; The product id cannot address a product row, so no line can match it.
       (make-bo-knowledge
        :truth :F :payload nil
        :provenance (format nil "nst-invitm/?exists: ~S is not a product row-id" prd-id)))
      (t
       (with-db-call (select-invoice-items-by-prd-id pid rid tenant-id)
                     "nst-invitm/?exists (prd-id, invheadid, tenant)")))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; make — सृजन
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod make ((entity-class (eql 'nst-invitm)) (ctx domain-ctx) &rest initargs)
  "Add a line to a DRAFT invoice.

  THERE IS NO :around METHOD HERE, unlike nst-whs's make. The :around exists there
  because GSTIN+name+tenant IS a uniqueness the database enforces, so a pre-check
  predicts the INSERT's outcome. Here ?exists answers something else entirely (see
  its note) and a duplicate product line is legal, so a refusal built on it would
  reject valid invoices.

  WHAT IS ENFORCED, in this order, before anything is written:
    1. invheadid must parse to an integer — otherwise we cannot address a document;
    2. that document must be VISIBLE IN THIS TENANT (absent, soft-deleted or another
       tenant's all answer the same way: nst-entity-nil → 404). This is the
       authorization step, and it is why the caller's own :invheadid is discarded
       once verified rather than trusted;
    3. its status must be in *invitm-open-header-statuses* — adding content to an
       issued invoice is a new document, not an edit → nst-entity-contradiction → 409.

  Everything else comes from the caller or from the class initforms. The NOT NULL
  columns with no default (prd-id, prddesc, hsncode, uom) are refused by the database
  with the column named — the honest place for that rule, exactly as in nst-whs. A
  JSON number arrives as an integer, so no coercion is done here; a string sent for
  qty/price is a transport bug the DB will name.

  TENANT-ID comes from ctx, always, and is never read from initargs."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (rid (invitm-id-from-value (getf initargs :invheadid))))
    (if (null rid)
        (make-instance 'nst-entity-nil :tenant-id tenant-id
                       :reason (format nil "~S does not address an invoice header row (row-ids are integers), so there is no document to add a line to"
                                       (getf initargs :invheadid)))
        (let ((head (nst-fetch-visible-invoice-header rid tenant-id)))
          (case (bo-knowledge-truth head)
            (:T
             (let ((header (bo-knowledge-payload head)))
               (if (not (member (invh-status-string (status header)) *invitm-open-header-statuses*
                                :test #'string-equal))
                   (make-instance 'nst-entity-contradiction
                                  :tenant-id tenant-id
                                  :reason (format nil "Invoice header row-id ~A is ~A, not DRAFT — a line may only be added while the document is still being built. [LEGAL: an issued invoice's content is amended by a credit note, not by adding lines]"
                                                  rid (status header)))
                   ;; VERIFIED. The caller's :invheadid is dropped and the verified
                   ;; rid used instead, so a string id cannot reach the DB and an
                   ;; unverified one cannot reach the row.
                   (let* ((clean (loop for (key value) on initargs by #'cddr
                                       unless (eq key :invheadid) append (list key value)))
                          (entity (apply #'make-instance 'nst-invitm
                                         :tenant-id tenant-id :invheadid rid clean))
                          (dbobj (make-instance 'dod-invoice-items)))
                     (setf (deleted-state entity) "N")
                     (nst-copy-invoice-item-domaintodb entity dbobj)
                     (let ((knowledge (with-nst-db-create (:source "nst-invitm/make")
                                         (clsql:update-records-from-instance dbobj)
                                         dbobj)))
                       (case (bo-knowledge-truth knowledge)
                         (:T (bind-generated-row-id entity (bo-knowledge-payload knowledge))
                             entity)
                         (:F ;; No unique key guards a line, so a :F here is the
                             ;; INSERT itself being refused: a NOT NULL column
                             ;; (PRDDESC, HSNCODE, UOM, PRD_ID) or the header/product
                             ;; foreign key. The database names the offender, and
                             ;; that reason is the useful part.
                             (domain-sentinel-from-knowledge
                              knowledge ctx
                              :reason (format nil "Invoice line create on header row-id ~A: the database refused the row (a NOT NULL column, or the header/product foreign key) — see the provenance"
                                              rid)))
                         (:U ;; The boundary did not answer: we do NOT know whether
                             ;; the line was written. → 503, never 404, never a
                             ;; successful create.
                             (domain-sentinel-from-knowledge
                              knowledge ctx
                              :reason (format nil "Invoice line create on header row-id ~A: the database call did not answer — the row may or may not have been written, so this is unknown, not failed"
                                              rid)))
                         (:C (error "Unreachable: no :pre-flight form supplied to with-nst-db-create in nst-invitm/make — a :C here means the macro contract changed without this method being updated"))
                         (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create"
                                           (bo-knowledge-truth knowledge)))))))))
            (otherwise
             ;; :F (no such document in this tenant) and :U (the database did not
             ;; answer) both arrive here and stay distinct — the first is a 404 and
             ;; the second a 503, and conflating them is the bug the four-valued
             ;; layer exists to prevent.
             (domain-sentinel-from-knowledge
              head ctx
              :reason (format nil "Invoice line create: header row-id ~A is not a document this tenant can see" rid))))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; fetch — स्मरण
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod fetch ((entity-class (eql 'nst-invitm)) (id string) (ctx domain-ctx))
  "Recall one line by row-id, in the session tenant, AND prove its document is still
  visible. Returns a real nst-invitm or a Belnap sentinel.

  The parent check is the point. A line is reachable only through its invoice, so a
  row whose header is soft-deleted or another tenant's must NOT come back as a
  found line: it would be content of a document the caller cannot see, which is
  precisely the orphan state the header's लोप ordering is designed to make
  unreachable. Here it is refused explicitly rather than assumed impossible — the
  header's delete! can fail part-way (see its note), and a refusal is cheaper than
  trusting that it never happened."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (row-id (invoice-item-row-id-from-string id)))
    (if (null row-id)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address an invoice line row (row-ids are integers)" id))
        (let ((knowledge (with-db-call (select-invoice-item-by-row-id row-id tenant-id)
                                       "nst-invitm/fetch (row-id, session tenant)")))
          (if (not (eq (bo-knowledge-truth knowledge) :T))
              ;; :F (no such line here) and :U (the boundary did not answer) stay
              ;; distinct, with per-state wording.
              (domain-sentinel-from-knowledge
               knowledge ctx
               :reason (lambda (truth)
                         (case truth
                           (:F (format nil "Invoice line row-id ~A not found in this tenant" row-id))
                           (:U (format nil "Invoice line row-id ~A: the database call did not answer — whether the line exists is unknown" row-id))
                           (:C (format nil "Invoice line row-id ~A returned more than one row — the primary key is not holding" row-id)))))
              (let* ((dbobj (bo-knowledge-payload knowledge))
                     (head-id (slot-value dbobj 'invheadid))
                     (head (nst-fetch-visible-invoice-header head-id tenant-id)))
                (if (not (eq (bo-knowledge-truth head) :T))
                    (domain-sentinel-from-knowledge
                     head ctx
                     :reason (format nil "Invoice line row-id ~A belongs to header row-id ~A, which this tenant cannot see (deleted, or another tenant's) — a line is only reachable through its document"
                                     row-id head-id))
                    (let ((entity (make-instance 'nst-invitm :tenant-id tenant-id)))
                      (nst-copy-invoice-item-dbtodomain dbobj entity)
                      entity))))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; !update — !state प्रत्यय
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod !update ((entity-class (eql 'nst-invitm)) (row-id string) (ctx domain-ctx)
                    &rest update-args)
  "Assign columns on an existing line. A PARTIAL update: the row is selected,
  hydrated, then reinitialize-instance applies only the initargs supplied, so an
  omitted field keeps its stored value instead of reverting to its class default.

  ALLOWED AT ANY HEADER STATUS — see the content-vs-values split in this file's
  header. Correcting a rate, a description or an HSN on an issued invoice is an
  edit; the settings permit edits after generation, so refusing here would invent a
  policy the configuration states the other way.

  :INVHEADID IS REFUSED (nst-entity-contradiction → 409). A line does not migrate
  between documents: moving one changes two invoices' contents at once, bypasses
  both headers' status rules, and — because invheadid is caller-supplied — would be
  the easiest way to push rows at another tenant's invoice. The correct operation is
  to delete the line and create it on the other document, which runs both checks.
  A caller that means 'this line is already on the right invoice' simply omits the key."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (row-id-int (invoice-item-row-id-from-string row-id)))
    (cond
      ((null row-id-int)
       (make-instance 'nst-entity-nil :tenant-id tenant-id
                      :reason (format nil "~S does not address an invoice line row (row-ids are integers)" row-id)))
      ((getf update-args :invheadid)
       (make-instance 'nst-entity-contradiction
                      :tenant-id tenant-id
                      :reason "An invoice line does not move between documents — delete the line and create it on the other invoice, so both headers' status rules run. [LEGAL: reassignment would change two documents' taxable content at once]"))
      (t
       (let ((dbobj (select-invoice-item-by-row-id row-id-int tenant-id)))
         (if (null dbobj)
             (make-instance 'nst-entity-nil :tenant-id tenant-id
                            :reason (format nil "Invoice line row-id ~A not found in this tenant (or already deleted)" row-id))
             (let* ((head-id (slot-value dbobj 'invheadid))
                    (head (nst-fetch-visible-invoice-header head-id tenant-id)))
               (if (not (eq (bo-knowledge-truth head) :T))
                   (domain-sentinel-from-knowledge
                    head ctx
                    :reason (format nil "Invoice line update, row-id ~A: its header row-id ~A is not visible to this tenant — a line is only editable through its document"
                                    row-id head-id))
                   (let ((entity (make-instance 'nst-invitm :tenant-id tenant-id)))
                     (nst-copy-invoice-item-dbtodomain dbobj entity)   ; hydrate current state
                     (apply #'reinitialize-instance entity update-args)
                     (nst-copy-invoice-item-domaintodb entity dbobj)
                     (let ((knowledge (with-nst-db-update (:source "nst-invitm/!update")
                                         (clsql:update-records-from-instance dbobj)
                                         dbobj)))
                       (case (bo-knowledge-truth knowledge)
                         (:T entity)
                         (:U (domain-sentinel-from-knowledge
                              knowledge ctx
                              :reason (format nil "Invoice line update, row-id ~A: the database call did not answer — the row's current state is unknown" row-id)))
                         (:F (error "Unreachable: with-nst-db-update without :pre-flight cannot return :F (invoice line row-id ~A)" row-id))
                         (otherwise (error "Unrecognized bo-knowledge-truth ~A" (bo-knowledge-truth knowledge))))))))))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; delete! — लोप प्रत्यय (soft, and only while the header is a DRAFT)
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod delete! ((entity-class (eql 'nst-invitm)) (row-id string) (ctx domain-ctx))
  "Soft-delete ONE line. Sets its DELETED_STATE='Y'; the row is never removed, and
  नियम-2 hides it from every verb afterwards.

  TWO REFUSALS THAT ARE ABSENCES (:F → 404), both answered rather than raised:
    * the id does not address a row; or
    * no such LIVE line in this tenant — note that a REPEAT delete therefore answers
      'not found', not 'already deleted'. Those are the same fact (there is no live
      line here) and nst-whs's delete! collapses them the same way; the header's
      separate 'already deleted' branch is unreachable for the same reason, since
      its own select excludes soft-deleted rows.

  AND ONE THAT IS NOT:
    * a header status outside *invitm-open-header-statuses* → nst-entity-contradiction
      → 409. The line is there and readable; what contradicts is the request, because
      removing content from an issued invoice is what a credit note is for. [LEGAL]

  NOT DONE: the header's TOTALVALUE is not adjusted, and this does NOT go through
  nst-soft-delete-invoice-items-for-header — that function is the header's own लोप
  (many rows, one document), while this is one row of a document the caller named."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (row-id-int (invoice-item-row-id-from-string row-id)))
    (if (null row-id-int)
        (make-instance 'nst-entity-nil :tenant-id tenant-id
                       :reason (format nil "~S does not address an invoice line row (row-ids are integers)" row-id))
        (let ((dbobj (select-invoice-item-by-row-id row-id-int tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil :tenant-id tenant-id
                             :reason (format nil "Invoice line row-id ~A not found in this tenant" row-id))
              (let* ((head-id (slot-value dbobj 'invheadid))
                     (head (nst-fetch-visible-invoice-header head-id tenant-id)))
                (if (not (eq (bo-knowledge-truth head) :T))
                    (domain-sentinel-from-knowledge
                     head ctx
                     :reason (format nil "Invoice line delete, row-id ~A: its header row-id ~A is not visible to this tenant — a line is only deleted through its document"
                                     row-id head-id))
                    (let ((header (bo-knowledge-payload head)))
                      (if (not (member (invh-status-string (status header)) *invitm-open-header-statuses*
                                       :test #'string-equal))
                          (make-instance 'nst-entity-contradiction
                                         :tenant-id tenant-id
                                         :reason (format nil "Invoice header row-id ~A is ~A, not DRAFT — a line may only be removed while the document is still being built. [LEGAL: an issued invoice's content is amended by a credit note]"
                                                         head-id (status header)))
                          (let ((knowledge (with-nst-db-delete (:source "nst-invitm/delete!")
                                              (setf (slot-value dbobj 'deleted-state) "Y")
                                              (clsql:update-record-from-slot dbobj 'deleted-state)
                                              dbobj)))
                            (case (bo-knowledge-truth knowledge)
                              (:T t)
                              (:U (domain-sentinel-from-knowledge
                                   knowledge ctx
                                   :reason (format nil "Invoice line delete, row-id ~A: the database call did not answer — whether the line was soft-deleted is unknown" row-id)))
                              (:F (error "Unreachable: with-nst-db-delete without :pre-flight cannot return :F (invoice line row-id ~A)" row-id))
                              (otherwise (error "Unrecognized bo-knowledge-truth ~A" (bo-knowledge-truth knowledge))))))))))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; enumerate — दर्शन प्रत्यय
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod enumerate ((entity-class (eql 'nst-invitm)) (ctx domain-ctx)
                      &key invheadid status include-deleted
                           (sort-by :row-id) (sort-dir :asc))
  "List invoice lines within the session tenant.

  WITH :invheadid — the normal use — the document is VERIFIED FIRST, so a caller who
  names an invoice that is absent, soft-deleted or another tenant's gets nst-entity-nil
  (404) rather than an empty list. An empty list would be a lie of the exact kind the
  four-valued layer exists to prevent: 'that invoice has no lines' and 'there is no
  such invoice for you' are different answers.

  WITHOUT :invheadid — every live line in the tenant, which is what a rate-wise or
  HSN-wise summary across invoices reads. Deliberately allowed, and still
  tenant-scoped by the clause builder, so it cannot leak.

  ANY header status is listable: reading an issued invoice's lines is normal. The
  status restriction belongs to make/delete!, which restructure the document.

  Returns a LIST normally, or a sentinel when the answer is not a list — a caller must
  inspect the result rather than assume one (the ring-4 dispatcher handles both).
  Zero lines is a SUCCESS with an empty list, not a 404."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (rid (invitm-id-from-value invheadid)))
    (if (and invheadid (null rid))
        (make-instance 'nst-entity-nil :tenant-id tenant-id
                       :reason (format nil "~S does not address an invoice header row (row-ids are integers)" invheadid))
        (let ((head (if rid (nst-fetch-visible-invoice-header rid tenant-id) :no-parent-given)))
          (if (and rid (not (eq (bo-knowledge-truth head) :T)))
              (domain-sentinel-from-knowledge
               head ctx
               :reason (format nil "Invoice line enumerate: header row-id ~A is not a document this tenant can see" rid))
              (let ((knowledge (with-nst-db-read-all
                                   (:source "nst-invitm/enumerate"
                                    :pk-extractor (lambda (d) (slot-value d 'row-id)))
                                 (select-invoice-items-by-filter
                                  tenant-id :invheadid rid :status status
                                            :include-deleted include-deleted
                                            :sort-by sort-by :sort-dir sort-dir))))
                (case (bo-knowledge-truth knowledge)
                  (:T (mapcar (lambda (dbobj)
                                (let ((entity (make-instance 'nst-invitm :tenant-id tenant-id)))
                                  (nst-copy-invoice-item-dbtodomain dbobj entity)
                                  entity))
                              (bo-knowledge-payload knowledge)))
                  (:F '())
                  (:U (domain-sentinel-from-knowledge
                       knowledge ctx
                       :reason (format nil "Invoice line enumerate, tenant ~A: the database call did not answer — the line list contents are unknown"
                                       tenant-id)))
                  (:C (domain-sentinel-from-knowledge
                       knowledge ctx
                       :reason (format nil "Invoice line enumerate, tenant ~A: the result set contained duplicate primary keys — data integrity issue, investigate DOD_INVOICE_ITEMS directly"
                                       tenant-id)))
                  (otherwise (error "Unrecognized bo-knowledge-truth ~A" (bo-knowledge-truth knowledge))))))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; लोप for a whole document's lines — called by the HEADER's delete!
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-soft-delete-invoice-items-for-header (invheadid tenant-id)
  "लोप for the LINES of header INVHEADID: mark every live line DELETED_STATE='Y'.
  Returns a bo-knowledge:

    :T  payload = the NUMBER OF LINES marked (0 is a legitimate success — a draft
        with no lines deletes cleanly)
    :U  the boundary failed part-way. The provenance says how many lines were already
        marked before the failure, and the payload is NIL.

  This is NOT delete! on one line: it takes no ctx and performs no status check,
  because its single caller is nst-invh's delete!, which has already proved the
  header is a DRAFT within the session tenant and is deleting that very document.
  A second status check here would be a second place for the two rules to drift.

  WHY ROW BY ROW, THROUGH THE MACRO, rather than one hand-built
  `UPDATE … WHERE INVHEADID = ?`: with-nst-db-delete is the sanctioned soft-delete
  boundary — it writes deleted-state through update-record-from-slot ONLY, so a
  delete can never clobber a concurrent change to another column, and it logs the
  failure to *HHUBBUSINESSFUNCTIONSLOGFILE*. A bulk statement would be one round trip
  and would bypass both properties; a DRAFT has a handful of lines, so the round trips
  are not the scarce resource here.

  NOT bo-merge ON FAILURE, DELIBERATELY. bo-merge is the INFORMATION-order join, in
  which (T,U) = T — merging a success into a failure reports SUCCESS. What a partial
  failure means here is sequencing ('did every line get marked?'), which bo-merge
  cannot answer (nst-bl-beltrusys.lisp's bo-conjoin section states the same trap). So
  the first non-:T answer is returned as-is, with the progress folded into its
  provenance where a human can read it.

  THE CALLER MUST STOP ON NON-:T and must leave the header alone — see delete!'s
  ordering note in nst-bl-invh.lisp. Every line is attempted in row-id order, so a
  re-run of the whole delete finishes the job."
  (let ((rows (select-invoice-items-for-header invheadid tenant-id))
        (done 0))
    (dolist (row rows)
      (let ((knowledge (with-nst-db-delete (:source "nst-invitm/soft-delete-for-header")
                          (setf (slot-value row 'deleted-state) "Y")
                          (clsql:update-record-from-slot row 'deleted-state)
                          row)))
        (unless (eq (bo-knowledge-truth knowledge) :T)
          ;; Stop at the first failure and report it — with the tally, because 'how
          ;; far did it get' is the first thing anyone asks of a partial soft delete,
          ;; and the macro's own provenance has no way to know it.
          (return-from nst-soft-delete-invoice-items-for-header
            (make-bo-knowledge
             :truth (bo-knowledge-truth knowledge)
             :payload nil
             :provenance (format nil "nst-invitm/soft-delete-for-header: ~A of ~A line(s) of header row-id ~A were already marked DELETED_STATE='Y' before the failure at line row-id ~A — ~A"
                                 done (length rows) invheadid (slot-value row 'row-id)
                                 (knowledge-provenance-text knowledge)))))
        (incf done)))
    (make-bo-knowledge :truth :T :payload done
                       :provenance (format nil "nst-invitm/soft-delete-for-header: ~A live line(s) of header row-id ~A soft-deleted"
                                           done invheadid))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; domain->response / render-json — the reverse ferry and the outbound encoding
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod domain->response ((entity nst-invitm) (ctx domain-ctx))
  "nst-invitm → NstInvitmResponseModel. Mirrors, driven by the same list the copiers
  use, so the response shape cannot drift from the entity. The narrowing decision that
  matters is which fields LEAVE the system, and that allowlist is render-json below."
  (let ((destination (make-instance 'NstInvitmResponseModel)))
    (setf (slot-value destination 'row-id) (row-id entity))
    (dolist (slot *invitm-mirrored-slots*)
      (setf (slot-value destination slot) (slot-value entity slot)))
    destination))

;;; ⚠ NO render-json METHOD ON `list` IS DEFINED HERE, ON PURPOSE. nst-bl-invh.lisp
;;; already defines (render-json (responses list) (ctx domain-ctx)), and it is
;;; ELEMENT-AGNOSTIC: it maps render-json over the list, so it already encodes a list
;;; of NstInvitmResponseModel correctly. A second method with the identical specializer
;;; would REPLACE it (CLOS: same specializers, later definition wins), silently breaking
;;; the header's list rendering to fix a problem this file does not have. The same
;;; applies to domain->response-list, which is likewise element-agnostic and lives
;;; there.

(defmethod render-json ((r NstInvitmResponseModel) (ctx domain-ctx))
  "One invoice line → a JSON alist (the caller, or the shared list method in
  nst-bl-invh.lisp, applies json:encode-json-to-string).

  SECURITY CONTRACT: this method IS the outbound field allowlist for a line. A slot
  added to NstInvitmResponseModel does NOT auto-leak — it must be named here.

  Identifiers leave as JSON STRINGS via response-id-string (nil → null), so rowId /
  invHeadId / prdId do not mix \"47\", 42 and null for the same kind of value.
  The money and rate columns leave as NUMBERS, not strings: a client doing arithmetic
  should not have to parse, and the DB typed them decimal to begin with."
  (list
   (cons "rowId"          (response-id-string (row-id r)))
   (cons "invHeadId"      (response-id-string (invheadid r)))
   ;; what is being sold
   (cons "prdId"          (response-id-string (prd-id r)))
   (cons "prdDesc"        (prddesc r))
   (cons "hsnCode"        (hsncode r))
   ;; quantity and price
   (cons "qty"            (qty r))
   (cons "uom"            (uom r))
   (cons "price"          (price r))
   (cons "discount"       (discount r))
   ;; tax breakdown
   (cons "taxableValue"   (taxable-value r))
   (cons "cgstRate"       (cgstrate r))
   (cons "cgstAmt"        (cgstamt r))
   (cons "sgstRate"       (sgstrate r))
   (cons "sgstAmt"        (sgstamt r))
   (cons "igstRate"       (igstrate r))
   (cons "igstAmt"        (igstamt r))
   (cons "totalItemVal"   (totalitemval r))
   ;; line state
   (cons "status"         (status r))))
