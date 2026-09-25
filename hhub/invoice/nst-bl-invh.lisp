;;; nst-bl-invh.lisp — Tier-1 प्रत्यय for the invoice header (nst-invh)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;; ═══════════════════════════════════════════════════════════════════════════
;;; The six universal प्रत्यय of nst-bl-adhara.lisp, specialized on nst-invh:
;;;
;;;   make       सृजन          make a DRAFT header row
;;;   fetch      स्मरण          recall one header by row-id
;;;   enumerate  दर्शन          list headers in tenant scope
;;;   !update    !state         assign typed columns on an existing header
;;;   delete!    लोप            SOFT delete, and ONLY while still a DRAFT
;;;   ?exists    प्रत्यभिज्ञा   is this INVNUM already used in this tenant
;;;
;;; plus the reverse ferry (domain->response / domain->response-list) and the
;;; outbound encoding (render-json). render-html is NOT here — it belongs in a
;;; nst-ui-* file, as it does for nst-whs.
;;;
;;; SHAPE COPIED FROM nst-bl-warehouse.lisp DELIBERATELY, INCLUDING THE THINGS
;;; THAT LOOK LIKE BOILERPLATE. Four states in, four states out: every verb
;;; returns either a real nst-invh or a Belnap sentinel from nst-bl-adhara.lisp,
;;; and :U is never phrased as "not found". The reason this matters — and the
;;; concrete bug it prevents — is documented at length in
;;; aiharness/deepseek/skills/knowledge/nst-bl-apidefs2-CONTEXT.md §8.
;;;
;;; NOT DONE HERE, ON PURPOSE:
;;;   * no item प्रत्यय, no line-items slot, no totals roll-up. TOTALVALUE is
;;;     whatever the caller supplied and is NOT derived from DOD_INVOICE_ITEMS.
;;;     [LEGAL: issue must not release an invoice whose total disagrees with
;;;     its lines — that check does not exist yet and must exist before issue.]
;;;   * no issue / approve / generate-irn / claim-itc verb. This file makes the
;;;     header addressable; the गण verbs come next.
;;;   * no route-* action verbs and no register-api-route bindings.
;;;   * no check-niyam call. nst-whs does not call it either — नियम-1 is
;;;     enforced structurally here by scoping every SELECT to the session
;;;     tenant, which is the property the rule exists to provide.
;;; ═══════════════════════════════════════════════════════════════════════════

(defparameter *invh-sort-whitelist*
  '((:invnum . :invnum) (:invdate . :invdate) (:status . :status)
    (:totalvalue . :totalvalue) (:custname . :custname) (:created . :created))
  "The ONLY columns enumerate may sort by. sort-by is caller-controllable —
  eventually from an HTTP query string — so this list is what stands between
  that and arbitrary ORDER BY construction. The keys are Lisp-side names; the
  values are the CLSQL slot keywords of dod-invoice-header. Extend deliberately,
  one line at a time.")

(defparameter *invh-deletable-statuses* '("DRAFT")
  "Statuses in which लोप (soft delete) is allowed. [LEGAL: an ISSUED invoice is
  never deleted — GST law wants a cancellation/credit note, and the invoice
  number must stay consumed. FINAL/PAID/CANCELLED therefore refuse delete! with
  a contradiction rather than pretending the row never existed. This mirrors
  *invoice-settings*' security-settings (allow-invoice-deletion nil).]")

;;; ───────────────────────────────────────────────────────────────────────────
;;; Small helpers
;;; ───────────────────────────────────────────────────────────────────────────

(defun nst-financial-year-label (date)
  "The Indian/GST financial year containing DATE, as FINYEAR's varchar(9):
  a date from 2026-04-01 to 2027-03-31 answers \"2026-2027\".

  April–March is the GST default and the only rule the schema documents. A
  tenant whose year starts in another month describes it on nst-vnd's
  fy-start-month slot, which no verb reads yet — when one does, this function is
  the single place to change, and the caller is make."
  (multiple-value-bind (second minute hour day month year)
      (clsql-sys:decode-date date)
    (declare (ignore second minute hour day))
    (if (>= month 4)
        (format nil "~4,'0d-~4,'0d" year (1+ year))
        (format nil "~4,'0d-~4,'0d" (1- year) year))))

(defun invoice-header-row-id-from-string (id)
  "Row-ids arrive as STRINGS: apidefs2 passes path params through unchanged and
  every id crosses the API boundary as a JSON string. Returns the integer
  row-id, or NIL when the string cannot address a row at all — /invoice/abc asks
  for something that cannot exist, which is a not-found fact (:F → 404), not a
  malformed-boundary failure (:U → 503).

  Third copy of this guard (nst-whs has warehouse-row-id-from-string, products
  has product-row-id-from-string). Three copies is the point at which the
  promotion promised in the nst-whs note is due; doing it here would edit a
  loading-order-sensitive shared file as a side effect of an invoice change, so
  it waits for its own commit."
  (when (stringp id)
    (handler-case (parse-integer id :junk-allowed nil)
      (error () nil))))

(defun invh-status-string (status)
  "Normalises a caller-supplied status to the string the column stores.
  Accepts a keyword (:draft) or a string (\"draft\") — (string :draft) is
  \"DRAFT\" already, so both land on the same value. Returns NIL for NIL, which
  the callers read as 'no status filter'."
  (when status (string-upcase (string status))))

(defun invh-json-flag (value)
  "tinyint(1) BOOLEAN column → JSON boolean. 0 and NIL are false; anything else
  is true. Written as a guard rather than (if value t nil) because 0 is TRUTHY
  in Lisp — the naive form reports FALSE columns as true, which is how 'ITC not
  claimed' becomes 'ITC claimed' in a client."
  (and value (not (eql value 0))))

(defun invh-json-timestamp (value)
  "A TIMESTAMP column → \"YYYY-MM-DD HH:MM:SS\", NIL → NIL, a string passes
  through unchanged. Used ONLY for the timestamp columns; the DATE columns go
  through get-datestr-from-obj-yyyymmdd so a client parsing them gets a date and
  not a midnight timestamp.

  The handler-case is deliberate: clsql's decode-date is defined for the DATE
  struct, while a wall-time slot read back from MySQL can arrive as the raw
  universal-time integer. Rather than guess which, this formats what it can and
  falls back to the printed representation — a slightly ugly string in one field
  is better than a 500 on every invoice fetch."
  (cond ((null value) nil)
        ((stringp value) value)
        (t (handler-case
               (multiple-value-bind (second minute hour day month year)
                   (clsql-sys:decode-date value)
                 (format nil "~4,'0d-~2,'0d-~2,'0d ~2,'0d:~2,'0d:~2,'0d"
                         year month day hour minute second))
             (error () (princ-to-string value))))))

(defun invh-json-date (value)
  "A DATE column → \"YYYY-MM-DD\", NIL → NIL, a string passes through."
  (cond ((null value) nil)
        ((stringp value) value)
        (t (handler-case (get-datestr-from-obj-yyyymmdd value)
             (error () (princ-to-string value))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; ?exists — प्रत्यभिज्ञा
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; ⚠ THE IDENTITY IS NOT UNIQUE IN THE SCHEMA. DOD_INVOICE_HEADER has a plain
;;; KEY on INVNUM, no UNIQUE constraint, so nothing below is enforced by the
;;; database and the TOCTOU race CANNOT be closed by the engine here. The check
;;; is therefore a business fact, not a guarantee: it makes the common case
;;; answerable and lets make refuse before the INSERT, while a genuine
;;; concurrent duplicate can still land. [LEGAL: GST requires the invoice number
;;; to be unique within a financial year per GSTIN — enforcing that properly
;;; needs UNIQUE (INVNUM, TENANT_ID, FINYEAR), which is a migration, not a verb.]
;;;
;;; The soft-delete question is the same one nst-whs answers, and it is answered
;;; the same way: a DELETED_STATE='Y' row still holds the number, so the number
;;; is TAKEN even though नियम-2 makes that row invisible to every verb. Two of
;;; our own rules disagree → :C, never a plain 'free'.

(defmethod ?exists ((entity-class (eql 'nst-invh)) (invnum string) (ctx domain-ctx)
                    &key &allow-other-keys)
  "Is the invoice number INVNUM already used in this tenant? Belnap answer:
     :F  free — no row (live or soft-deleted) carries it in this tenant
     :T  a LIVE header carries it
     :C  a SOFT-DELETED header carries it: present in the table, invisible to
         every verb under नियम-2 — escalate (409), never read as free
     :U  the database could not be consulted — must NOT be treated as :F

  &key &allow-other-keys exists purely for CLOS congruence with the generic
  function's lambda list (nst-bl-adhara.lisp §?exists); the method reads no
  keyword, and accepting unknown keys is what keeps a query string carrying
  extra parameters from signalling in the middle of a create."
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (let ((knowledge (with-db-call
                         (select-invoice-header-by-invnum invnum tenant-id
                                                          :include-deleted t)
                       "nst-invh/?exists (invnum, tenant)")))
      (cond
        ((not (eq (bo-knowledge-truth knowledge) :T)) knowledge)
        ((string= (or (deleted-state (bo-knowledge-payload knowledge)) "N") "Y")
         (bo-merge knowledge
                   (make-bo-knowledge
                    :truth :F
                    :payload nil
                    :provenance "नियम-2: DELETED_STATE='Y' rows are invisible to every verb")))
        (t knowledge)))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; make — सृजन
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod make :around ((entity-class (eql 'nst-invh)) (ctx domain-ctx)
                         &rest initargs)
  "REFUSE BEFORE THE INSERT, in four-valued terms. An :around (not :before)
  method is required because a :before method's value is discarded, so it could
  only raise — and a raise reaches the boundary as a 500, indistinguishable from
  a crash. The mapping, verbatim from nst-whs:

    ?exists :F → confirmed free → call-next-method
    ?exists :T → a LIVE header holds the number → contradiction → 409
    ?exists :C → a SOFT-DELETED row holds it → contradiction → 409
    ?exists :U → the check did not answer → unknown → 503. :U is NOT 'probably
                 free': minting a number on an unconfirmed identity is exactly
                 how a duplicate invoice number gets issued."
  (let ((invnum (getf initargs :invnum)))
    (if (null invnum)
        (call-next-method)               ; no identity supplied — nothing to check
        (let ((check (?exists 'nst-invh invnum ctx)))
          (case (bo-knowledge-truth check)
            (:F (call-next-method))
            (:T (make-instance 'nst-entity-contradiction
                               :tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)
                               :reason (format nil "Invoice number ~A is already used by a LIVE invoice in this tenant — issuing another contradicts existing state, so it is neither done nor impossible. [LEGAL: invoice numbers must be unique per financial year]"
                                               invnum)))
            (otherwise
             ;; :C and :U land here; domain-sentinel-from-knowledge builds the
             ;; matching sentinel and carries the provenance, which is where
             ;; नियम-2's explanation of the soft-deleted identity holder lives.
             (domain-sentinel-from-knowledge
              check ctx
              :reason (format nil "Invoice number ~A: the uniqueness check did not come back free — see the provenance"
                              invnum))))))))

(defmethod make ((entity-class (eql 'nst-invh)) (ctx domain-ctx) &rest initargs)
  "Create a DRAFT invoice header.

  THREE FIELDS ARE DERIVED rather than demanded, because a verb can legitimately
  know them and a NOT NULL column with no default would otherwise turn a
  reasonable create into a database error:

    invnum   — the caller's value wins. With none, this mints the same
               placeholder the legacy UI uses, (format nil \"NST000~A\"
               (hhub-random-password 10)), so the row is addressable at once and
               the vendor edits it later. It is NOT the settings-driven
               sequential number (\"INV-YYYY-MM-{counter}\",
               invoice-general-settings) — that needs a counter and a decision
               about what happens on rollback, and is not invented here.
    invdate  — today, when the caller supplies none. A CLSQL date object; a
               caller passing the raw HTTP string will be refused by the DB
               rather than silently stored.
    finyear  — derived from invdate via nst-financial-year-label.

  Every other value comes from the caller or from the class initforms, which
  mirror the DDL. The NOT NULL text columns left NIL by the class (custname,
  statecode, placeofsupply, totalinwords) are refused by the database with the
  column named — the honest place for that rule, exactly as in nst-whs."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (entity (apply #'make-instance 'nst-invh :tenant-id tenant-id initargs))
         (dbobj (make-instance 'dod-invoice-header)))
    (unless (invnum entity)
      (setf (invnum entity) (format nil "NST000~A" (hhub-random-password 10))))
    (unless (invdate entity)
      (setf (invdate entity) (clsql-sys:get-date)))
    (unless (finyear entity)
      (setf (finyear entity) (nst-financial-year-label (invdate entity))))
    (unless (status entity)
      (setf (status entity) "DRAFT"))
    (setf (deleted-state entity) "N")
    (nst-copy-invoice-header-domaintodb entity dbobj)
    (let ((knowledge (with-nst-db-create (:source "nst-invh/make")
                        (clsql:update-records-from-instance dbobj)
                        dbobj)))
      (case (bo-knowledge-truth knowledge)
        (:T (bind-generated-row-id entity (bo-knowledge-payload knowledge))
            entity)
        (:F ;; No unique key guards INVNUM, so a :F here means the INSERT itself
            ;; was refused — a NOT NULL column, or the tenant FK. The database
            ;; names the offender; that reason is the useful part, so it is
            ;; carried out rather than flattened into "create failed".
            (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Invoice header create: the database refused the row (a NOT NULL column, or the tenant/customer/vendor foreign key) — see the provenance"))
        (:U ;; The boundary did not answer: we do NOT know whether the row was
            ;; written. → 503, never 404 and never a successful create.
            (domain-sentinel-from-knowledge
             knowledge ctx
             :reason "Invoice header create: the database call did not answer — the row may or may not have been written, so this is unknown, not failed"))
        (:C ;; Unreachable without a :pre-flight form, which this call does not
            ;; supply. A :C here means the macro contract moved under us.
            (error "Unreachable: no :pre-flight form supplied to with-nst-db-create \
                    in nst-invh/make — a :C here means the macro contract changed \
                    without this method being updated"))
        (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create"
                          (bo-knowledge-truth knowledge)))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; fetch — स्मरण
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod fetch ((entity-class (eql 'nst-invh)) (id string) (ctx domain-ctx))
  "Recall one header by row-id, in the session tenant. Returns a real nst-invh
  or a Belnap sentinel — never a bare CL NIL, so every caller has a four-valued
  object back (nst-bl-adhara.lisp §fetch):

    :T → the entity                → 200
    :F → nst-entity-nil            → 404  'there is no such invoice'
    :U → nst-entity-unknown        → 503  'I could not find out' — NOT 404
    :C → nst-entity-contradiction  → 409

  Invariance note: another tenant's row-id answers :F, not :U and not a
  permission error. Authorization here is per-object by construction — the
  SELECT carries tenant-id, so the row is simply not there. That is OWASP
  API1:2023 (BOLA) answered by the query shape rather than by a check that can
  be forgotten."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (row-id (invoice-header-row-id-from-string id)))
    (if (null row-id)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address an invoice header row (row-ids are integers)" id))
        (let ((knowledge (with-db-call (select-invoice-header-by-row-id row-id tenant-id)
                                       "nst-invh/fetch (row-id, session tenant)")))
          (domain-result-from-knowledge
           knowledge ctx
           :hydrate (lambda (dbobj)
                      (let ((entity (make-instance 'nst-invh :tenant-id tenant-id)))
                        (nst-copy-invoice-header-dbtodomain dbobj entity)
                        entity))
           ;; Per-state wording, so a :U is never phrased as "not found".
           :reason (lambda (truth)
                     (case truth
                       (:F (format nil "Invoice header row-id ~A not found in this tenant" row-id))
                       (:U (format nil "Invoice header row-id ~A: the database call did not answer — whether the invoice exists is unknown" row-id))
                       (:C (format nil "Invoice header row-id ~A returned more than one row — the primary key is not holding" row-id)))))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; !update — !state प्रत्यय
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod !update ((entity-class (eql 'nst-invh)) (row-id string) (ctx domain-ctx)
                    &rest update-args)
  "Assign columns on an existing header. A PARTIAL update: the row is selected,
  hydrated into an nst-invh, then reinitialize-instance applies only the
  initargs actually supplied, so an omitted field keeps its stored value instead
  of being reset to its class default.

  NOT BLOCKED once the invoice is FINAL. That is deliberate and matches
  *invoice-settings*' security-settings (allow-invoice-edit-after-generation t):
  the configuration says edits after generation are permitted, so refusing here
  would be this file inventing a policy the settings already state the other
  way. delete! is where the legal line is drawn, not here.

  ⚠ INV_DATE IS A CLSQL DATE OBJECT, NOT A STRING. update-args reach here from
  the ferry unchanged, so a caller posting \"24/09/2026\" hands this method a
  string, which reinitialize-instance accepts and CLSQL then refuses on write.
  The route or UI layer must normalise with get-date-from-string first — the
  same contract nst-whs's !update has for row-id, one level stricter."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (rid (invoice-header-row-id-from-string row-id)))
    (if (null rid)
        (make-instance 'nst-entity-nil :tenant-id tenant-id
                       :reason (format nil "~S does not address an invoice header row (row-ids are integers)" row-id))
        (let ((dbobj (select-invoice-header-by-row-id rid tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil :tenant-id tenant-id
                             :reason (format nil "Invoice header row-id ~A not found in this tenant (or already deleted)" row-id))
              (let ((entity (make-instance 'nst-invh :tenant-id tenant-id)))
                (nst-copy-invoice-header-dbtodomain dbobj entity)   ; hydrate current state
                (apply #'reinitialize-instance entity update-args)  ; CLOS partial update
                (nst-copy-invoice-header-domaintodb entity dbobj)
                (let ((knowledge (with-nst-db-update (:source "nst-invh/!update")
                                    (clsql:update-records-from-instance dbobj)
                                    dbobj)))
                  (case (bo-knowledge-truth knowledge)
                    (:T entity)
                    (:U ;; The write did not complete and the row's state is
                        ;; unknown → 503: the invoice exists, we just cannot say
                        ;; what happened to it. NOT a 404 and NOT a 500.
                        (domain-sentinel-from-knowledge
                         knowledge ctx
                         :reason (format nil "Invoice header update, row-id ~A: the database call did not answer — the row's current state is unknown" row-id)))
                    (:F ;; Unreachable: with-nst-db-update was called without
                        ;; :pre-flight, so :F cannot be produced (the SELECT above
                        ;; already confirmed the row).
                        (error "Unreachable: with-nst-db-update without :pre-flight cannot return :F (invoice header row-id ~A)" row-id))
                    (otherwise (error "Unrecognized bo-knowledge-truth ~A" (bo-knowledge-truth knowledge)))))))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; delete! — लोप प्रत्यय (soft, and only while DRAFT)
;;; ───────────────────────────────────────────────────────────────────────────

(defmethod delete! ((entity-class (eql 'nst-invh)) (row-id string) (ctx domain-ctx))
  "Soft-delete a DRAFT header. Sets DELETED_STATE='Y'; nothing is ever removed
  from the table — नियम-2 blocks further verbs on the result and physical
  removal is not this project's concern.

  TWO REFUSALS BEFORE THE WRITE, both answering :F (an absence fact) rather
  than raising:

    * no such row in this tenant, or already soft-deleted → nst-entity-nil → 404

  AND ONE REFUSAL THAT IS NOT AN ABSENCE:

    * a status not in *invh-deletable-statuses* → nst-entity-contradiction → 409.
      The invoice IS there and IS legitimately readable; what contradicts is the
      request, because an issued invoice's number is consumed and its document is
      a legal record. [LEGAL: cancel or credit-note an issued invoice; do not
      make it never have existed.]

  THE LINES GO WITH THE HEADER. DOD_INVOICE_ITEMS_ibfk_3 is ON DELETE CASCADE,
  which does NOTHING here — it fires on a hard DELETE, and a soft delete never
  issues one — so before this was written a deleted header left its lines live.
  delete! now runs लोप on the live lines first, through
  nst-soft-delete-invoice-items-for-header (nst-bl-invitm.lisp), and only then
  on the header itself.

  THE ORDER IS THE DESIGN, not an accident, and there is no transaction around
  the two writes (this layer has no transaction idiom — with-hhub-transaction is
  the ABAC policy point, not a DB transaction):

    lines → header   a half-finished delete leaves the header LIVE and therefore
                     reachable by row-id, and re-running the verb finishes the job
    header → lines   a half-finished delete would leave a deleted header with
                     LIVE lines behind it — and nothing can reach those lines,
                     because every path to a line runs through its header. They
                     would be invisible rows that still count as live.

  So: if the line write does not fully succeed, the header is left UNTOUCHED and
  the sentinel's reason says so; if the header write then fails, the reason
  reports how many lines were already marked, because that tally is the only
  record of what the call actually did.

  NOT CHECKED, AND KNOWN: whether the lines' own STATUS (PENDING/FINAL) should
  restrict this. Every live line is marked, whatever its status — a DRAFT
  header's lines have no independent life, and no verb can produce a FINAL line
  yet since there are no item प्रत्यय. Revisit when they land."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (rid (invoice-header-row-id-from-string row-id)))
    (cond
      ((null rid)
       (make-instance 'nst-entity-nil :tenant-id tenant-id
                      :reason (format nil "~S does not address an invoice header row (row-ids are integers)" row-id)))
      (t
       (let ((dbobj (select-invoice-header-by-row-id rid tenant-id)))
         (cond
           ((null dbobj)
            (make-instance 'nst-entity-nil :tenant-id tenant-id
                           :reason (format nil "Invoice header row-id ~A not found" row-id)))
           ((string-equal (or (deleted-state dbobj) "N") "Y")
            (make-instance 'nst-entity-nil :tenant-id tenant-id
                           :reason (format nil "Invoice header row-id ~A already deleted" row-id)))
           ((not (member (invh-status-string (status dbobj)) *invh-deletable-statuses*
                         :test #'string-equal))
            (make-instance 'nst-entity-contradiction
                           :tenant-id tenant-id
                           :reason (format nil "Invoice header row-id ~A is ~A, not DRAFT — an issued invoice is cancelled or credit-noted, never deleted. [LEGAL: the invoice number stays consumed]"
                                           row-id (status dbobj))))
           (t
            ;; Lines first, header last — see the docstring for why the order is
            ;; the design and not an accident.
            (let ((lines (nst-soft-delete-invoice-items-for-header rid tenant-id)))
              (if (not (eq (bo-knowledge-truth lines) :T))
                  ;; The lines did not all get marked. THE HEADER IS UNTOUCHED —
                  ;; said explicitly, because the reader of a 503 must not conclude
                  ;; the invoice is gone, and the caller can simply re-run.
                  (domain-sentinel-from-knowledge
                   lines ctx
                   :reason (format nil "Invoice header delete, row-id ~A: the LINE soft-delete did not complete, so the header was left UNTOUCHED and is still live — re-run the delete once the database answers"
                                   row-id))
                  (let* ((marked (bo-knowledge-payload lines))
                         (knowledge (with-nst-db-delete (:source "nst-invh/delete!")
                                     (setf (deleted-state dbobj) "Y")
                                     (clsql:update-record-from-slot dbobj 'deleted-state)
                                     dbobj)))
                    (case (bo-knowledge-truth knowledge)
                      (:T t)
                      (:U ;; The lines are 'Y' and the header's state is unknown.
                          ;; Report the tally with the ignorance: it is the only
                          ;; record of how far this call got.
                          (domain-sentinel-from-knowledge
                           knowledge ctx
                           :reason (format nil "Invoice header delete, row-id ~A: ~A line(s) were already soft-deleted, but the header write did not answer — whether the header itself was soft-deleted is unknown"
                                           row-id marked)))
                      (:F ;; Unreachable: with-nst-db-delete was called without
                          ;; :pre-flight.
                          (error "Unreachable: with-nst-db-delete without :pre-flight cannot return :F (invoice header row-id ~A)" row-id))
                      (otherwise (error "Unrecognized bo-knowledge-truth ~A" (bo-knowledge-truth knowledge))))))))))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; enumerate — दर्शन प्रत्यय
;;; ───────────────────────────────────────────────────────────────────────────

(defun validate-invh-sort-args (sort-by sort-dir)
  (let ((col (cdr (assoc sort-by *invh-sort-whitelist*))))
    (unless col
      (error "enumerate: sort-by ~A not in whitelist ~A" sort-by *invh-sort-whitelist*))
    (unless (member sort-dir '(:asc :desc))
      (error "enumerate: sort-dir must be :asc or :desc, got ~A" sort-dir))
    (values col sort-dir)))

(defun build-invh-filter-clauses (tenant-id &key status custid vendor-id invnum-like
                                                from-date to-date)
  "गण: Anusthup. Assembles WHERE clauses for invoice-header queries.

  ⚠ THE DELETED_STATE CLAUSE IS AN OR, AND IT HAS TO BE. DOD_INVOICE_HEADER's
  column is `char(1) DEFAULT NULL`, unlike DOD_WAREHOUSE's `DEFAULT 'N'`, and
  dod-invoice-header's CLSQL class declares :void-value \"N\" — so CLSQL omits
  the column on INSERT and every legacy row holds SQL NULL, not 'N'. A plain
  [= [:deleted-state] \"N\"] would therefore hide every invoice in the system.

  It also cannot be written [= [:deleted-state] nil]: CLSQL renders a NIL
  sub-expression as the literal NULL, and `DELETED_STATE = NULL` is true for no
  row at all — silently the same bug. Hence [is ... nil], which renders
  IS NULL.

  Fixing the column's default to 'N' would let this collapse back to the
  warehouse's single clause; that is a migration, not a verb."
  (let ((clauses (list [= [:tenant-id] tenant-id]
                       [or [= [:deleted-state] "N"]
                           [is [:deleted-state] nil]])))
    (when status (push [= [:status] (invh-status-string status)] clauses))
    (when custid (push [= [:custid] custid] clauses))
    (when vendor-id (push [= [:vendor-id] vendor-id] clauses))
    (when from-date (push [>= [:invdate] from-date] clauses))
    (when to-date (push [<= [:invdate] to-date] clauses))
    (when (and invnum-like (plusp (length (string-trim " " invnum-like))))
      (push [like [:invnum] (format nil "%~A%" (escape-like-wildcards invnum-like))] clauses))
    clauses))

(defun select-invoice-headers-by-filter (tenant-id &key status custid vendor-id
                                                        invnum-like from-date to-date
                                                        (sort-by :invdate) (sort-dir :desc))
  (multiple-value-bind (sort-col sort-dir) (validate-invh-sort-args sort-by sort-dir)
    (clsql:select 'dod-invoice-header
                  :where (apply #'clsql:sql-and
                                (build-invh-filter-clauses
                                 tenant-id :status status :custid custid
                                           :vendor-id vendor-id
                                           :invnum-like invnum-like
                                           :from-date from-date :to-date to-date))
                  :order-by (list (list sort-col sort-dir))
                  :caching *dod-database-caching* :flatp t)))

(defmethod enumerate ((entity-class (eql 'nst-invh)) (ctx domain-ctx)
                      &key status custid vendor-id invnum-like from-date to-date
                           (sort-by :invdate) (sort-dir :desc))
  "List invoice headers within the session tenant.

  Default order is newest first (:invdate :desc) — an invoice list is read from
  the top, and the warehouse default (:w-name :asc) is an alphabetical catalogue
  concern that does not transfer.

  Returns a LIST normally, or a sentinel when the answer is not a list — a
  caller must inspect the result rather than assume one (the ring-4 dispatcher
  handles both: action->response sends a non-list through domain->response).
  An empty result is a SUCCESS with zero rows → 200 '[]', not 404."
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (knowledge (with-nst-db-read-all
                        (:source "nst-invh/enumerate"
                         :pk-extractor (lambda (d) (slot-value d 'row-id)))
                      (select-invoice-headers-by-filter tenant-id
                                                        :status status :custid custid
                                                        :vendor-id vendor-id
                                                        :invnum-like invnum-like
                                                        :from-date from-date :to-date to-date
                                                        :sort-by sort-by :sort-dir sort-dir))))
    (case (bo-knowledge-truth knowledge)
      (:T (mapcar (lambda (dbobj)
                    (let ((entity (make-instance 'nst-invh :tenant-id tenant-id)))
                      (nst-copy-invoice-header-dbtodomain dbobj entity)
                      entity))
                  (bo-knowledge-payload knowledge)))
      (:F '())
      (:U (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (format nil "Invoice enumerate, tenant ~A: the database call did not answer — the invoice list contents are unknown" tenant-id)))
      (:C (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (format nil "Invoice enumerate, tenant ~A: the result set contained duplicate primary keys — data integrity issue, investigate DOD_INVOICE_HEADER directly" tenant-id)))
      (otherwise (error "Unrecognized bo-knowledge-truth ~A" (bo-knowledge-truth knowledge))))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; QUERY FUNCTIONS — every read is tenant-scoped by construction
;;; ───────────────────────────────────────────────────────────────────────────

(defun select-invoice-header-by-row-id (id tenant-id)
  "One header by primary key, in this tenant, not soft-deleted. ID is an
  INTEGER here — the string guard belongs to the verbs, which have to answer :F
  for an unparsable id before any query runs."
  (car (clsql:select 'dod-invoice-header :where
                     [and
                      [= [:tenant-id] tenant-id]
                      [= [:row-id] id]
                      [or [= [:deleted-state] "N"]
                          [is [:deleted-state] nil]]]
                     :caching *dod-database-caching* :flatp t)))

(defun select-invoice-header-by-invnum (invnum tenant-id &key include-deleted)
  "The row holding this invoice NUMBER in this tenant.

  INCLUDE-DELETED decides which question is asked:
    NIL — 'is there an invoice with this number?' (live rows, what verbs see)
    T   — 'is this number still consumed?' (what ?exists must ask, because a
          soft-deleted row keeps its number: nothing in the schema reuses it)

  No unique key backs this, so this CAN return more than one row; the CAR keeps
  the callers honest (they ask a yes/no question) and the surplus is itself a
  finding — see the ?exists note."
  (car (clsql:select 'dod-invoice-header
                     :where (if include-deleted
                                [and [= [:invnum] invnum]
                                     [= [:tenant-id] tenant-id]]
                                [and [= [:invnum] invnum]
                                     [= [:tenant-id] tenant-id]
                                     [or [= [:deleted-state] "N"]
                                         [is [:deleted-state] nil]]])
                     :caching *dod-database-caching* :flatp t)))

;;; ───────────────────────────────────────────────────────────────────────────
;;; DOMAIN <-> DB COPY HELPERS
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; WHY THIS IS A SLOT LIST AND NOT 55 HAND-WRITTEN (setf ...) PAIRS, when
;;; copyWarehouse-* is written out longhand: there is NO MAPPING to express here.
;;; nst-invh was given the DOD class's own slot names on purpose, so the two
;;; sides are mirrors and the only information the copier carries is the LIST OF
;;; COLUMNS THAT EXIST. A list states that once; 110 setf lines state it twice
;;; and can disagree with each other. warehouse's longhand is not a style to
;;; copy — it exists because W_NAME ↔ wname really does differ per field.
;;;
;;; ADD A NEW COLUMN HERE, in this one list. Nothing else needs to change for
;;; the column to survive a create, a fetch and an update.

(defparameter *invh-mirrored-slots*
  '(;; identity of the document
    invnum invdate finyear context-id
    ;; parties
    vendor-id custid custname custaddr custgstin user-id
    ;; addresses and place of supply
    billaddr shipaddr placeofsupply statecode
    ;; transport
    revcharge transmode vnum
    ;; money and presentation
    totalvalue totalinwords bankaccnum bankifsccode tnc authsign
    ;; document state
    status deleted-state external-url
    ;; e-invoicing
    e-invoice-required irn irn-date ack-number ack-date qr-code-path
    ;; GSTR-1 / GSTR-2B
    uploaded-to-gstn gstn-upload-date gstr1-period in-gstr2b
    gstr2b-match-status gstr2b-verified-date
    ;; ITC
    itc-eligible itc-claimed itc-claim-month itc-amount
    ;; payment reconciliation
    advance-adjusted payment-allocated total-allocated total-tds-deducted
    balance-due advance-gst-reversed payment-status
    ;; reverse charge lifecycle
    rcm-paid rcm-paid-date
    ;; view tracking
    last-viewed-by-user-id last-viewed-at)
  "Slots that exist on BOTH nst-invh and dod-invoice-header under the same name.
  Deliberately excludes:
    row-id     — bound only after the INSERT (bind-generated-row-id); copying it
                 in the domain→DB direction would write a value the row does not
                 have yet, and the DB→domain direction copies it explicitly.
    tenant-id  — set from domain-ctx on the domain side and from the entity on
                 the DB side; it is a नियम-1 value, not client data, so it is
                 never a plain mirror.
    created / updated — DB-side columns the CLSQL class already defaults; the
                 domain has created-at / updated-at instead (two concerns, see
                 nst-dal-invh.lisp).")

(defun nst-copy-invoice-header-domaintodb (source destination)
  "nst-invh → dod-invoice-header."
  (dolist (slot *invh-mirrored-slots*)
    (setf (slot-value destination slot) (slot-value source slot)))
  (setf (slot-value destination 'tenant-id) (tenant-id source))
  destination)

(defun nst-copy-invoice-header-dbtodomain (source destination)
  "dod-invoice-header → nst-invh."
  (setf (slot-value destination 'row-id) (slot-value source 'row-id))
  (setf (slot-value destination 'tenant-id) (slot-value source 'tenant-id))
  (dolist (slot *invh-mirrored-slots*)
    (setf (slot-value destination slot) (slot-value source slot)))
  destination)

;;; ───────────────────────────────────────────────────────────────────────────
;;; domain->response — nst-invh → NstInvhResponseModel (the reverse ferry)
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; This hop MIRRORS — every declared slot crosses, driven by the same list the
;;; copiers use, so the response shape cannot drift from the entity. The
;;; narrowing decision that actually matters is which fields LEAVE the system,
;;; and that allowlist is render-json below, per format, where it belongs.

(defmethod domain->response ((entity nst-invh) (ctx domain-ctx))
  (let ((destination (make-instance 'NstInvhResponseModel)))
    (setf (slot-value destination 'row-id) (row-id entity))
    (dolist (slot *invh-mirrored-slots*)
      (setf (slot-value destination slot) (slot-value entity slot)))
    destination))

(defun domain->response-list (entities ctx)
  "Carries each nst-invh through domain->response, returning a list of
  NstInvhResponseModel objects. A plain function, not a generic: the per-element
  dispatch already happens inside domain->response, and wrapping mapcar in a
  method on 'list' would be false ceremony. BELNAP NOTE: a pure structural
  transform — it does NOT inspect each element's truth. Filter sentinels BEFORE
  calling this."
  (mapcar (lambda (dom) (domain->response dom ctx)) entities))

;;; ───────────────────────────────────────────────────────────────────────────
;;; render-json — NstInvhResponseModel, and lists of it
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; SECURITY CONTRACT: this method IS the outbound field allowlist. A slot added
;;; to NstInvhResponseModel does NOT auto-leak — it must be named here, per
;;; format. Two conventions, both from the warehouse API and neither optional:
;;;
;;;   * every identifier leaves as a JSON STRING via response-id-string (nil →
;;;     null). rowId already arrives as a string from the DB while custid /
;;;     vendor-id / user-id are integers, so without normalisation one response
;;;     would mix "47", 42 and null for the same kind of value.
;;;   * date columns leave as YYYY-MM-DD and timestamp columns as
;;;     YYYY-MM-DD HH:MM:SS — see the two helpers at the top of this file.
;;;
;;; The NOT NULL money columns are always present; the nullable ones can be
;;; null and are not defaulted to 0 here, because 'no advance was adjusted' and
;;; 'nothing reconciled this invoice yet' are different facts from 'zero'.

(defmethod render-json ((r NstInvhResponseModel) (ctx domain-ctx))
  "One invoice header → a JSON alist (the caller, or the list method below,
  applies json:encode-json-to-string)."
  (list
   (cons "rowId"                  (response-id-string (row-id r)))
   ;; identity of the document
   (cons "invnum"                 (invnum r))
   (cons "invdate"                (invh-json-date (invdate r)))
   (cons "finyear"                (finyear r))
   (cons "contextId"              (context-id r))
   ;; parties
   (cons "vendorId"               (response-id-string (vendor-id r)))
   (cons "custId"                 (response-id-string (custid r)))
   (cons "custName"               (custname r))
   (cons "custAddr"               (custaddr r))
   (cons "custGstin"              (custgstin r))
   (cons "userId"                 (response-id-string (user-id r)))
   ;; addresses and place of supply
   (cons "billAddr"               (billaddr r))
   (cons "shipAddr"               (shipaddr r))
   (cons "placeOfSupply"          (placeofsupply r))
   (cons "stateCode"              (statecode r))
   ;; transport
   (cons "revCharge"              (revcharge r))
   (cons "transMode"              (transmode r))
   (cons "vnum"                   (vnum r))
   ;; money and presentation
   (cons "totalValue"             (totalvalue r))
   (cons "totalInWords"           (totalinwords r))
   (cons "bankAccNum"             (bankaccnum r))
   (cons "bankIfscCode"           (bankifsccode r))
   (cons "tnc"                    (tnc r))
   (cons "authSign"               (authsign r))
   ;; document state
   (cons "status"                 (status r))
   (cons "externalUrl"            (external-url r))
   ;; e-invoicing
   (cons "eInvoiceRequired"       (invh-json-flag (e-invoice-required r)))
   (cons "irn"                    (irn r))
   (cons "irnDate"                (invh-json-timestamp (irn-date r)))
   (cons "ackNumber"              (ack-number r))
   (cons "ackDate"                (invh-json-timestamp (ack-date r)))
   (cons "qrCodePath"             (qr-code-path r))
   ;; GSTR-1 / GSTR-2B
   (cons "uploadedToGstn"         (invh-json-flag (uploaded-to-gstn r)))
   (cons "gstnUploadDate"         (invh-json-timestamp (gstn-upload-date r)))
   (cons "gstr1Period"            (gstr1-period r))
   (cons "inGstr2b"               (invh-json-flag (in-gstr2b r)))
   (cons "gstr2bMatchStatus"      (gstr2b-match-status r))
   (cons "gstr2bVerifiedDate"     (invh-json-date (gstr2b-verified-date r)))
   ;; ITC
   (cons "itcEligible"            (invh-json-flag (itc-eligible r)))
   (cons "itcClaimed"             (invh-json-flag (itc-claimed r)))
   (cons "itcClaimMonth"          (itc-claim-month r))
   (cons "itcAmount"              (itc-amount r))
   ;; payment reconciliation
   (cons "advanceAdjusted"        (advance-adjusted r))
   (cons "paymentAllocated"       (payment-allocated r))
   (cons "totalAllocated"         (total-allocated r))
   (cons "totalTdsDeducted"       (total-tds-deducted r))
   (cons "balanceDue"             (balance-due r))
   (cons "advanceGstReversed"     (advance-gst-reversed r))
   (cons "paymentStatus"          (payment-status r))
   ;; reverse charge lifecycle
   (cons "rcmPaid"                (invh-json-flag (rcm-paid r)))
   (cons "rcmPaidDate"            (invh-json-date (rcm-paid-date r)))
   ;; view tracking
   (cons "lastViewedByUserId"     (response-id-string (last-viewed-by-user-id r)))
   (cons "lastViewedAt"           (invh-json-timestamp (last-viewed-at r)))))

(defmethod render-json ((responses list) (ctx domain-ctx))
  "Many invoice headers → a JSON array text. An empty list encodes as [] —
  which is what a caller who listed and found nothing should see, and is
  deliberately NOT a 404."
  (json:encode-json-to-string
   (mapcar (lambda (r) (render-json r ctx)) responses)))
