;;; nst-bl-cusinv.lisp — CUSTOMER (INWARD) INVOICE REGISTER — गण verbs (Tier 1)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; THE GRAMMAR: hhub/core/nst-bl-adhara.lisp (verbs, the ferry, नियम)
;;; THE PLAYBOOK: hhub/nst-adhara-GENERIC-migration-playbook.md (§6 is this file)
;;; MASTER TEMPLATE: warehouse/nst-bl-warehouse.lisp
;;;
;;; WHAT THIS FILE REPLACES: invoice/nst-bl-cusinvreg.lisp — the retired DDD stack
;;; (AdapterService + PresenterService + HTML/JSONView). The grammar has no view
;;; model: a domain entity crosses OUT through domain->response and is rendered from it.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THREE STRUCTURAL DECISIONS, EACH OF WHICH IS ENFORCED RATHER THAN DOCUMENTED
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; 1. THE BUYER ARGUMENT IS `:for-buyer`, NOT `:buyer-id` — A SECURITY PROPERTY OF THE NAME:
;;;    the ferry forwards every payload key the entity class declares as an initarg, and nst-cinv
;;;    DOES declare `:buyer-id`, so that key would hand a client another customer's register — whereas no slot declares `:for-buyer`, so the ferry physically cannot deliver one.
;;;
;;; 2. THE SUMMARY IS A REDUCTION OVER `enumerate`, NOT A SECOND AGGREGATE QUERY:
;;;    summarize-itc folds the SAME entities the table shows, so card and list cannot disagree —
;;;    the old separate aggregate is how the card reported ₹0.00 on four invoices that carried tax.
;;;
;;; 3. `:itc :at-risk` RETURNS A SENTINEL, NOT AN EMPTY LIST: deciding it needs
;;;    DOD_VENDOR_GSTR1_STATUS and DOD_BUYER_VENDOR_ACCOUNT, and BOTH HOLD 0 ROWS, so an empty list
;;;    would assert "you have no at-risk invoices"; nst-entity-unknown (:U → 503) is the word for "I could not find out".
;;;
;;; ⚠ LOAD ORDER — FACTS, NOT PREFERENCES; all three must load first:
;;;   * invoice/nst-dal-cusinv.lisp (domain classes, response models, view class);
;;;   * invoice/nst-bl-invh.lisp (invh-json-flag/date/timestamp) and invoice/nst-bl-invitm.lisp (build-invitm-filter-clauses).

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 0 — the धातु this domain adds, registered in its own गण
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; करगण (proc.tax) already owns this domain's verb family — claim-itc,
;;; reverse-itc, offset-itc, reconcile-2b, verify-gstin, classify-hsn — so the
;;; ITC summary belongs there and not in a new गण.
;;;
;;; define-gana-verbs is ADDITIVE: it sets one more hash entry in
;;; *verb->gana-package* and leaves existing registrations alone, so nothing in core
;;; has to be edited to add a verb.

(define-gana-verbs :proc.tax summarize-itc)

(defgeneric summarize-itc (entity-class ctx &key for-buyer)
  (:documentation
   "दर्शन-सङ्क्षेप — the ITC position over the whole register, as one domain fact: a NEW धातु,
    deliberately NOT folded into enumerate (`which invoices?` vs `what do they add up to?`), because
    a separate hand-written SQL aggregate is how the card and the table drifted apart. :for-buyer comes from the SESSION (header rule 1), and because this delegates to enumerate an :U propagates rather than flattening into a summary of zeroes."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 1 — the session seam: who is this register FOR?
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; नियम-1 says the tenant comes from the session; the BUYER does too, but domain-ctx has no
;;; slot for it (the buyer is the party the register belongs to, not the कर्म), so it travels
;;; as an explicit argument resolved by the CALLER — never from params.
;;;
;;; This helper names the session key in exactly one place. It is NOT called by the verbs
;;; themselves: a verb that read the session could not be exercised outside Hunchentoot,
;;; and the grammar's ctx exists to keep that dependency out of the island.

(defun cinv-buyer-from-session ()
  "The DOD_CUST_PROFILE.ROW_ID of the logged-in CUSTOMER, or NIL outside a customer session.
   ⚠ :login-customer IS THE OBJECT, not :login-customer-id — that second session value is populated
   on some login paths and not others, so this reads the object and takes its row-id, which cannot be silently 0."
  (let ((cust (conflodis2-session-value :login-customer)))
    (when cust
      (handler-case (slot-value cust 'row-id)
        (error () nil)))))

(defun cinv-require-buyer (for-buyer)
  "FOR-BUYER, or a loud error naming why the register cannot be scoped.
   FAILS CLOSED: an unscoped register would mean `every customer in the tenant`, so a missing
   buyer must never degrade to a wider query — it must stop."
  (or for-buyer
      (error "nst-cinv: :for-buyer was not supplied — the register is scoped to ONE ~
              customer, and without it the query would return every customer's. Resolve ~
              it with cinv-buyer-from-session in the session layer, never from params.")))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 2 — the sort whitelist
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; Only the view's real columns. ⚠ itc-derived IS DELIBERATELY ABSENT: it is computed in
;;; Lisp from a second query, so no ORDER BY could name it, and offering it would produce
;;; either an SQL error or a silently unsorted page.

(defparameter *cinv-sort-whitelist*
  '((:invoice-date      . :invoice-date)
    (:invoice-number    . :invoice-number)
    (:total-amount      . :total-amount)
    (:vendor-name       . :vendor-name)
    (:balance-due       . :balance-due)
    (:payment-status    . :payment-status))
  "Sort keys `enumerate` accepts → the view column each one names. Never accept a
   raw column name from outside this list.")

(defun validate-cinv-sort-args (sort-by sort-dir)
  (let ((col (cdr (assoc sort-by *cinv-sort-whitelist*))))
    (unless col
      (error "nst-cinv enumerate: sort-by ~A not in whitelist ~A" sort-by *cinv-sort-whitelist*))
    (unless (member sort-dir '(:asc :desc))
      (error "nst-cinv enumerate: sort-dir must be :asc or :desc, got ~A" sort-dir))
    (values col sort-dir)))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 3 — the WHERE clauses
;;; ═══════════════════════════════════════════════════════════════════════════

(defparameter +cinv-at-risk-reason+
  "At-risk invoices cannot be determined yet. Whether input tax credit is at risk depends on the supplier having filed their return and on that supply appearing in your GSTR-2B, and no such filing information has been received. Nothing recorded against an individual invoice answers the question, so an empty list here would wrongly read as \"no invoices are at risk\"."
  "THE CLIENT-VISIBLE WORDING, DELIBERATELY HIGH-LEVEL: it reaches a customer as the page's
   warning panel and as the 503 reason in an API body, so it names no table, column or internal
   class — only the statutory facts the answer would need. Read by enumerate (which answers with the nst-entity-unknown sentinel) and by build-cinv-filter-clauses (which refuses the predicate outright), so the refusal and the answer cannot drift apart.")

(defparameter +cinv-at-risk-dev-note+
  "DEVELOPER NOTE (never shown to a client): deciding this needs DOD_VENDOR_GSTR1_STATUS and DOD_BUYER_VENDOR_ACCOUNT, which both hold 0 rows, plus an ingested GSTR-2B in DOD_GST_RECONCILIATION; no invoice-level column records it either."
  "Where the data would come from — a table-level pointer for a programmer, kept strictly
   separate from the client-facing sentence above. Read only by the developer-facing error in
   build-cinv-filter-clauses; no sentinel reason and no render path may include it.")

(defun build-cinv-filter-clauses (for-buyer tenant-id &key itc vendor-id
                                                          payment-status gstr2b-match-status
                                                          invoice-status gst-period
                                                          invoice-number-like
                                                          from-date to-date)
  "गण: Anusthup. Assembles WHERE clauses for register queries.
   ⚠ TWO FIXED PREDICATES, BOTH LOAD-BEARING: the view publishes cp.ROW_ID AS BUYER_ID but
   ih.TENANT_ID AS TENANT_ID — two different tables — so filtering on only one of them would either show another customer's invoices (buyer dropped) or, on a header whose tenant differs from the buyer's, half-match a row. Both are always applied; neither is a keyword."
  (let ((clauses (list [= [:buyer-id]  for-buyer]
                       [= [:tenant-id] tenant-id])))
    (case itc
      ((nil :all))                                  ; no clause
      (:claimable (push [and [= [:itc-eligible] 1]
                              [= [:itc-claimed] 0]] clauses))
      (:claimed   (push [= [:itc-claimed] 1] clauses))
      (:at-risk
       ;; REFUSED, NOT RESOLVED TO EMPTY: returning '() would be read by every client as "no
       ;; invoices are at risk" — the exact class of confident-zero lie this migration removes.
       ;; Defence-in-depth half only: `enumerate` answers the sentinel BEFORE reaching this builder, so a direct SQL caller is the only thing that can get here.
       (error "nst-cinv: the :at-risk filter cannot be evaluated. ~A ~A"
              +cinv-at-risk-reason+ +cinv-at-risk-dev-note+))
      (otherwise
       (error "nst-cinv: unknown :itc filter ~S — expected one of :claimable, :claimed, :at-risk, :all" itc)))
    (when vendor-id            (push [= [:vendor-id] vendor-id] clauses))
    (when payment-status       (push [= [:payment-status] (string-upcase (string payment-status))] clauses))
    (when gstr2b-match-status  (push [= [:gstr2b-match-status] (string-upcase (string gstr2b-match-status))] clauses))
    (when invoice-status       (push [= [:invoice-status] (string-upcase (string invoice-status))] clauses))
    (when gst-period           (push [= [:gst-period] gst-period] clauses))
    (when from-date            (push [>= [:invoice-date] from-date] clauses))
    (when to-date              (push [<= [:invoice-date] to-date] clauses))
    (when (and invoice-number-like (plusp (length (string-trim " " invoice-number-like))))
      ;; escape-like-wildcards lives in core/dod-bl-utl.lisp — one escaping rule
      ;; for the whole tree, so an invoice number containing % or _ is matched
      ;; literally instead of as a pattern.
      (push [like [:invoice-number]
                  (format nil "%~A%" (escape-like-wildcards invoice-number-like))]
            clauses))
    clauses))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 4 — the two SELECTs
;;; ═══════════════════════════════════════════════════════════════════════════

(defun select-cinvs-by-filter (for-buyer tenant-id
                               &key itc vendor-id payment-status gstr2b-match-status
                                    invoice-status gst-period invoice-number-like
                                    from-date to-date
                                    (sort-by :invoice-date) (sort-dir :desc))
  "The register rows themselves — the view's own columns, nothing derived.
   NEWEST FIRST BY DEFAULT (`:invoice-date :desc`): the retired implementation ordered ascending,
   which put a 2024 invoice above a 2026 one. ⚠ NO DERIVED ITC here — an aggregate added to a row-wise SELECT would multiply the rows or force a GROUP BY that would hide columns, so select-cinv-derived-itc fetches the per-invoice total once, separately, and it is merged in Lisp."
  (multiple-value-bind (sort-col sort-dir) (validate-cinv-sort-args sort-by sort-dir)
    (clsql:select 'dod-v-customer-invoice-register
                  :where (apply #'clsql:sql-and
                                (build-cinv-filter-clauses
                                 for-buyer tenant-id
                                 :itc itc :vendor-id vendor-id
                                 :payment-status payment-status
                                 :gstr2b-match-status gstr2b-match-status
                                 :invoice-status invoice-status
                                 :gst-period gst-period
                                 :invoice-number-like invoice-number-like
                                 :from-date from-date :to-date to-date))
                  :order-by (list (list sort-col sort-dir))
                  :caching *dod-database-caching* :flatp t)))

(defun select-cinv-derived-itc (tenant-id invoice-ids)
  "INVOICE-ID → the input tax credit its own LINE ITEMS carry, as a hash-table.
   ⚠ DERIVED, NOT READ: DOD_INVOICE_HEADER has no tax-total columns (querying one is ERROR 1054) and ITC_AMOUNT is NULL on every row, so an invoice's tax exists only on its lines and the register must derive rather than read.
   ⚠ A SEPARATE QUERY, NOT A JOIN: joining DOD_INVOICE_ITEMS to the register multiplies each invoice by its line count, so COUNT(*) and SUM(TOTAL_AMOUNT) over that join are inflated; soft-deleted lines are excluded by the REUSED build-invitm-filter-clauses rule (DELETED_STATE is char(1) DEFAULT NULL, so the live test is = 'N' OR IS NULL), and there is NO CESS because the schema has no cess columns."
  (let ((map (make-hash-table :test 'eql)))
    (when invoice-ids
      (dolist (itm (clsql:select 'dod-invoice-items
                                 :where (apply #'clsql:sql-and
                                               (cons [in [:invheadid] invoice-ids]
                                                     (build-invitm-filter-clauses tenant-id)))
                                 :caching *dod-database-caching* :flatp t))
        (incf (gethash (invheadid itm) map 0)
              (+ (or (cgstamt itm) 0.0)
                 (or (sgstamt itm) 0.0)
                 (or (igstamt itm) 0.0)))))
    map))

(defun select-cinv-by-id (invoice-id tenant-id for-buyer)
  "One register row, or NIL. Scoped by tenant AND buyer — see the two fixed predicates in
   build-cinv-filter-clauses: a customer in the same tenant must not be able to read another
   customer's inward invoice by guessing a row-id, and the view publishes buyer-id precisely so that this is expressible."
  (car (clsql:select 'dod-v-customer-invoice-register
                     :where [and [= [:invoice-id] invoice-id]
                                 [= [:tenant-id]  tenant-id]
                                 [= [:buyer-id]   for-buyer]]
                     :caching nil :flatp t)))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 5 — hydration: view row (+ derived tax) → nst-cinv
;;; ═══════════════════════════════════════════════════════════════════════════

(defun copy-dod-v-customer-invoice-register-dbtodomain (source destination &key derived-itc)
  "Fill DESTINATION (an nst-cinv) from SOURCE (a dod-v-customer-invoice-register row) and the
   optional DERIVED-ITC. FIELD-COMPLETE AND SYMMETRIC BY CONSTRUCTION: every slot declared on
   nst-cinv appears here, so a slot added without a line stays UNBOUND, which is why the class's own documentation points back at this function. ⚠ ITC_AMOUNT IS READ INTO itc-recorded, NOT into itc-amount: the column is NULL everywhere, so copying it to itc-amount would report ₹0.00 again and nothing would look wrong — the two separate slots are what make `the ledger is empty` visible instead of silent."
  (with-slots (row-id
               invoice-number invoice-date financial-year gst-period
               vendor-id vendor-name vendor-trade-name vendor-gstin
               vendor-gst-type vendor-filing-frequency
               buyer-id buyer-name buyer-gstin buyer-gst-type
               total-amount balance-due advance-adjusted payment-allocated
               itc-eligible itc-recorded itc-claimed itc-claim-month
               itc-derived itc-amount
               in-gstr2b gstr2b-match-status gstr2b-verified-date
               e-invoice-required irn irn-date ack-number
               reverse-charge rcm-paid rcm-paid-date
               payment-status uploaded-to-gstn gstn-upload-date
               place-of-supply state-code invoice-status) destination
    ;; ── THE VIEW'S KEY ──────────────────────────────────────────────────────
    (setf row-id                     (slot-value source 'invoice-id))
    ;; ── IDENTITY ────────────────────────────────────────────────────────────
    (setf invoice-number             (slot-value source 'invoice-number))
    (setf invoice-date               (slot-value source 'invoice-date))
    (setf financial-year             (slot-value source 'financial-year))
    (setf gst-period                 (slot-value source 'gst-period))
    ;; ── VENDOR ──────────────────────────────────────────────────────────────
    (setf vendor-id                  (slot-value source 'vendor-id))
    (setf vendor-name                (slot-value source 'vendor-name))
    (setf vendor-trade-name          (slot-value source 'vendor-trade-name))
    (setf vendor-gstin               (slot-value source 'vendor-gstin))
    (setf vendor-gst-type            (slot-value source 'vendor-gst-type))
    (setf vendor-filing-frequency    (slot-value source 'vendor-filing-frequency))
    ;; ── BUYER ───────────────────────────────────────────────────────────────
    (setf buyer-id                   (slot-value source 'buyer-id))
    (setf buyer-name                 (slot-value source 'buyer-name))
    (setf buyer-gstin                (slot-value source 'buyer-gstin))
    (setf buyer-gst-type             (slot-value source 'buyer-gst-type))
    ;; ── MONEY ───────────────────────────────────────────────────────────────
    (setf total-amount               (slot-value source 'total-amount))
    (setf balance-due                (slot-value source 'balance-due))
    (setf advance-adjusted           (slot-value source 'advance-adjusted))
    (setf payment-allocated          (slot-value source 'payment-allocated))
    ;; ── ITC, IN DEPENDENCY ORDER ────────────────────────────────────────────
    (setf itc-eligible               (slot-value source 'itc-eligible))
    (setf itc-claimed                (slot-value source 'itc-claimed))
    (setf itc-claim-month            (slot-value source 'itc-claim-month))
    (setf itc-recorded               (slot-value source 'itc-amount))
    (setf itc-derived                (or derived-itc 0))
    (setf itc-amount                 (or itc-recorded itc-derived))
    ;; ── GSTR-2B ─────────────────────────────────────────────────────────────
    (setf in-gstr2b                  (slot-value source 'in-gstr2b))
    (setf gstr2b-match-status        (slot-value source 'gstr2b-match-status))
    (setf gstr2b-verified-date       (slot-value source 'gstr2b-verified-date))
    ;; ── E-INVOICE ───────────────────────────────────────────────────────────
    (setf e-invoice-required         (slot-value source 'e-invoice-required))
    (setf irn                       (slot-value source 'irn))
    (setf irn-date                   (slot-value source 'irn-date))
    (setf ack-number                 (slot-value source 'ack-number))
    ;; ── RCM ─────────────────────────────────────────────────────────────────
    (setf reverse-charge             (slot-value source 'reverse-charge))
    (setf rcm-paid                   (slot-value source 'rcm-paid))
    (setf rcm-paid-date              (slot-value source 'rcm-paid-date))
    ;; ── PAYMENT AND STATUS ──────────────────────────────────────────────────
    (setf payment-status             (slot-value source 'payment-status))
    (setf uploaded-to-gstn           (slot-value source 'uploaded-to-gstn))
    (setf gstn-upload-date           (slot-value source 'gstn-upload-date))
    ;; ── PLACE OF SUPPLY ─────────────────────────────────────────────────────
    (setf place-of-supply            (slot-value source 'place-of-supply))
    (setf state-code                 (slot-value source 'state-code))
    (setf invoice-status             (slot-value source 'invoice-status)))
  destination)

(defun make-cinv-from-dbobj (dbobj tenant-id derived-map)
  "One view row → one nst-cinv, with its derived ITC pulled from DERIVED-MAP (or 0 when the
   invoice has no live lines). TENANT-ID COMES FROM ctx, NOT FROM THE ROW: the row's own tenant-id
   agrees for every row the verbs select, but नियम-1 is about where the value is ALLOWED to come from, so the session's is authoritative."
  (let ((entity (make-instance 'nst-cinv :tenant-id tenant-id)))
    (copy-dod-v-customer-invoice-register-dbtodomain
     dbobj entity
     :derived-itc (gethash (slot-value dbobj 'invoice-id) derived-map 0))
    entity))

(defun make-cinv-entity-list (dbobjs tenant-id)
  "A list of view rows → a list of nst-cinv, with ONE derived-ITC query for the
   whole page rather than one per row."
  (let ((derived-map (select-cinv-derived-itc
                      tenant-id
                      (mapcar (lambda (d) (slot-value d 'invoice-id)) dbobjs))))
    (mapcar (lambda (d) (make-cinv-from-dbobj d tenant-id derived-map)) dbobjs)))

(defun cinv-hydrate-dbobj (dbobj tenant-id)
  "ONE view row → ONE nst-cinv — named, and separate from make-cinv-entity-list, so that a verb
   returning a SINGLE entity has a hydrator that returns a single entity; a hydrator's arity and
   return shape are invisible to a test of the copy helper it wraps, which is exactly how this got through. 🚨 THIS EXISTS BECAUSE fetch USED THE LIST BUILDER AND IT RETURNED A LIST OF ONE: the details page's (vendor-id header) signalled NO-APPLICABLE-METHOD, and the API's GET /customer/invoices/{id} gave a client asking for ONE OBJECT a JSON ARRAY of one — a 200 with the wrong body shape and nothing to notice it by."
  (let ((derived-map (select-cinv-derived-itc
                      tenant-id
                      (list (slot-value dbobj 'invoice-id)))))
    (make-cinv-from-dbobj dbobj tenant-id derived-map)))


;;; ── THE SUCCESS TEST, AS A NAME, BECAUSE THE OBVIOUS ONE IS ALWAYS TRUE ──────
;;;
;;; 🚨 (typep X 'nst-domain-entity) IS THE WRONG TEST FOR "DID A VERB SUCCEED", AND IT
;;; HAS NOW BEEN WRITTEN BY MISTAKE TWICE — once guarding the ITC summary, once the
;;; details page — both times producing a fault no compiler could see, only at run time.
;;;
;;;   * nst-entity-nil / nst-entity-unknown / nst-entity-contradiction ALL subclass
;;;     nst-domain-entity — and so does nst-cinv — so the predicate is TRUE for success AND
;;;     for every failure, and distinguishes nothing at all.
;;;
;;; The two mistakes had OPPOSITE symptoms, which is why one fix did not cover the other: the
;;; summary check was inverted (success took the failure branch; the card rendered em-dashes),
;;; while the details check called (entity-reason <a real entity>) — a generic function defined ONLY on the three sentinel classes, hence NO-APPLICABLE-METHOD.
;;;
;;; So the test lives here, beside the verbs that answer it, and is named for the
;;; question rather than for the type.

(defun cinv-invoice-found-p (value)
  "True ONLY for a real nst-cinv — never for a Belnap sentinel, never for a list. Use this, not
   (typep value 'nst-domain-entity), wherever `did the read succeed` is what is being asked:
   entity-reason is defined on the sentinels alone, so handing it a real entity signals."
  (typep value 'nst-cinv))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 6 — fetch (स्मरण)
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; ⚠ fetch CANNOT TAKE `:for-buyer` — its signature is fixed by the ferry as
;;; (fetch entity-class id ctx) and the ferry leg passes only (rm-row-id rm) — so the buyer is
;;; resolved here, from the session, via cinv-buyer-from-session: one place, one thing to audit.
;;;
;;; WHY THE BUYER IS REQUIRED AT ALL: a tenant is a COMPANY, and several customers
;;; live inside one. Tenant-scoping alone would let a customer read a stranger's
;;; inward invoice by guessing a row-id — the row-id is a small sequential integer.

(defun cinv-row-id-from-string (id)
  "ID as an integer, or NIL when it does not address a row. Row-ids are integers;
   anything else is a :F fact ('that is not an invoice address'), not a crash."
  (when (stringp id)
    (handler-case (parse-integer id :junk-allowed nil)
      (error () nil))))

(defmethod fetch ((entity-class (eql 'nst-cinv)) (id string) (ctx domain-ctx))
  (let* ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
         (for-buyer (cinv-buyer-from-session))
         (invoice-id (cinv-row-id-from-string id)))
    (cond
      ((null for-buyer)
       (make-instance 'nst-entity-nil :tenant-id tenant-id
                      :reason "No customer is logged in, so there is no register to read an invoice from."))
      ((null invoice-id)
       (make-instance 'nst-entity-nil :tenant-id tenant-id
                      :reason (format nil "~S does not address an invoice (row-ids are integers)" id)))
      (t
       (let ((knowledge (with-db-call (select-cinv-by-id invoice-id tenant-id for-buyer)
                                      "nst-cinv/fetch (INVOICE_ID, session tenant, session buyer)")))
         (domain-result-from-knowledge
          knowledge ctx
          :hydrate (lambda (dbobj)
                     ;; ⚠ ONE ROW IN, ONE ENTITY OUT — see cinv-hydrate-dbobj: this read
                     ;; (make-cinv-entity-list (list dbobj) …) and answered a one-element LIST,
                     ;; which broke the details page and silently gave the API's /{id} endpoint an array of one.
                     (cinv-hydrate-dbobj dbobj tenant-id))
          :reason (lambda (truth)
                    (case truth
                      ;; ⚠ CLIENT-VISIBLE: no table, column or internal class name.
                      (:F (format nil "Inward invoice ~A is not in this customer's register. It may belong to another customer or another company, or the supplier may have withdrawn it." invoice-id))
                      (:U (format nil "Inward invoice ~A: this could not be looked up just now — whether it exists is unknown." invoice-id))
                      (:C (format nil "Inward invoice ~A came back more than once, which should not be possible. This is a data problem on our side and needs investigating." invoice-id))))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 7 — enumerate (दर्शन)
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; ⚠ THE `:at-risk` FILTER IS ANSWERED HERE, NOT PASSED DOWN: no column records it (see
;;; build-cinv-filter-clauses), so asking for it gets a nst-entity-unknown → 503 whose reason
;;; is the shared +cinv-at-risk-reason+ — the register says it could not be narrowed instead of returning an empty list that reads as "you have no at-risk invoices".
;;;
;;; ⚠ AND THE DERIVED-ITC FAILURE IS NOT ALLOWED TO BECOME A LIST OF ZEROES: if the second
;;; (line-items) query fails, every invoice would silently hydrate with itc-derived 0 — the
;;; original defect in new clothes. Only that one call is wrapped, so cinv-require-buyer's buyer guard still RAISES, as a programming error should.

(defmethod enumerate ((entity-class (eql 'nst-cinv)) (ctx domain-ctx)
                      &key for-buyer itc vendor-id payment-status gstr2b-match-status
                           invoice-status gst-period invoice-number-like
                           from-date to-date
                           (sort-by :invoice-date) (sort-dir :desc))
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    (if (eq itc :at-risk)
        (make-instance 'nst-entity-unknown :tenant-id tenant-id
                       :reason (format nil "~A" +cinv-at-risk-reason+))
        (let* ((buyer (cinv-require-buyer for-buyer))
               (knowledge (with-nst-db-read-all
                              (:source "nst-cinv/enumerate"
                               :pk-extractor (lambda (d) (slot-value d 'invoice-id)))
                            (select-cinvs-by-filter
                             buyer tenant-id
                             :itc itc :vendor-id vendor-id
                             :payment-status payment-status
                             :gstr2b-match-status gstr2b-match-status
                             :invoice-status invoice-status
                             :gst-period gst-period
                             :invoice-number-like invoice-number-like
                             :from-date from-date :to-date to-date
                             :sort-by sort-by :sort-dir sort-dir))))
          (case (bo-knowledge-truth knowledge)
            (:T (handler-case
                    ;; The SECOND crossing — the per-invoice line totals.
                    (make-cinv-entity-list (bo-knowledge-payload knowledge) tenant-id)
                  (error (c)
                    (make-instance 'nst-entity-unknown :tenant-id tenant-id
                                   :reason (format nil "The register's invoices were read, but their line items could not be: ~A. Every input-tax-credit figure would have been reported as 0.00, so the register is reported as unknown instead." c)))))
            (:F '())
            (:U (domain-sentinel-from-knowledge
                 knowledge ctx
                 :reason (format nil "The register could not be listed just now (buyer ~A in company ~A): the lookup did not answer, so its contents are unknown." buyer tenant-id)))
            (:C (domain-sentinel-from-knowledge
                 knowledge ctx
                 ;; ⚠ CLIENT-VISIBLE: no table name. The table to inspect is named in the provenance this
                 ;; sentinel already carries (bo-knowledge's own :source, "nst-cinv/enumerate"), appended by
                 ;; knowledge-reason-for — the developer-facing half.
                 :reason (format nil "The register came back with the same invoice more than once, which should not be possible (buyer ~A in company ~A). This is a data problem on our side and needs investigating." buyer tenant-id)))
            (otherwise (error "Unrecognized bo-knowledge-truth ~A" (bo-knowledge-truth knowledge))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 8 — summarize-itc (दर्शन-सङ्क्षेप)
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; THE CARD IS A FOLD OVER THE TABLE. Every figure below is computed from the same
;;; entities `enumerate` returns, so "the card says ₹0.00 while the rows show tax"
;;; is no longer a possible state of this system.

(defmethod summarize-itc ((entity-class (eql 'nst-cinv)) (ctx domain-ctx) &key for-buyer)
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id)))
    ;; ⚠ `apply`, MATCHING whsapi AND invhapi — for a reason beyond style: adhara declares
    ;; (defgeneric enumerate (entity-class ctx &key)) with NO keys named, so the compiler cannot
    ;; confirm :for-buyer and warns ":FOR-BUYER is not a known argument keyword" at every direct call.
    (let ((rows (apply #'enumerate 'nst-cinv ctx (list :for-buyer for-buyer))))
      (cond
        ;; A Belnap sentinel is NOT an empty register. Propagate it: a summary of
        ;; a collection we could not read is unknown, and reporting zeroes would
        ;; be the same confident-zero lie in a new place.
        ((typep rows 'nst-domain-entity) rows)
        (t
         (make-instance 'nst-cinv-itc-summary
            :tenant-id tenant-id
            :invoices  (length rows)
            :claimable (reduce (lambda (acc r)
                                 (+ acc (if (and (eql 1 (itc-eligible r))
                                                 (eql 0 (itc-claimed r)))
                                            (or (itc-derived r) 0)
                                            0)))
                               rows :initial-value 0)
            :claimed   (reduce (lambda (acc r)
                                 (+ acc (if (eql 1 (itc-claimed r))
                                            (or (itc-derived r) 0)
                                            0)))
                               rows :initial-value 0)
            :purchases (reduce (lambda (acc r) (+ acc (or (total-amount r) 0)))
                               rows :initial-value 0)
            ;; ── AT RISK: NIL, AND IT MEANS "NOT DETERMINED" ────────────────────
            ;; The retired implementation reported the integer 0 and the page rendered "₹0 At Risk" — a
            ;; confident claim that nothing is at risk, which nothing in this database supports (it needs the vendor's GSTR-1 filing status and a GSTR-2B, and every table holding either is empty). NIL keeps the distinction; the renderers must word it, not print it as money.
            :at-risk   nil)))))) 


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 9 — the reverse ferry (domain->response)
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; entity is the ONLY dispatching argument that may be an nst-domain-entity.
;;; Returns an nst-response-model — never the entity itself. The entity does not
;;; cross into Ring 4.
;;;
;;; EVERY slot declared on nst-cinv is copied. This method is the seam where a narrower
;;; outbound allowlist WOULD be introduced, and it is deliberately wide here: the register is
;;; the buyer's own data. The two fields that need care are documented on the class rather than dropped, because hiding a disagreeing column is not the same as resolving it.

(defmethod domain->response ((entity nst-cinv) (ctx domain-ctx))
  (let ((destination (make-instance 'NstCinvResponseModel)))
    (setf (row-id destination)                (row-id entity))
    ;; IDENTITY
    (setf (invoice-number destination)        (invoice-number entity))
    (setf (invoice-date destination)          (invoice-date entity))
    (setf (financial-year destination)        (financial-year entity))
    (setf (gst-period destination)            (gst-period entity))
    ;; VENDOR
    (setf (vendor-id destination)             (vendor-id entity))
    (setf (vendor-name destination)           (vendor-name entity))
    (setf (vendor-trade-name destination)     (vendor-trade-name entity))
    (setf (vendor-gstin destination)          (vendor-gstin entity))
    (setf (vendor-gst-type destination)       (vendor-gst-type entity))
    (setf (vendor-filing-frequency destination) (vendor-filing-frequency entity))
    ;; BUYER
    (setf (buyer-id destination)              (buyer-id entity))
    (setf (buyer-name destination)            (buyer-name entity))
    (setf (buyer-gstin destination)           (buyer-gstin entity))
    (setf (buyer-gst-type destination)        (buyer-gst-type entity))
    ;; MONEY
    (setf (total-amount destination)          (total-amount entity))
    (setf (balance-due destination)           (balance-due entity))
    (setf (advance-adjusted destination)      (advance-adjusted entity))
    (setf (payment-allocated destination)     (payment-allocated entity))
    ;; ITC — all three, so a reader can always tell the ledger from the arithmetic
    (setf (itc-eligible destination)          (itc-eligible entity))
    (setf (itc-recorded destination)          (itc-recorded entity))
    (setf (itc-derived destination)           (itc-derived entity))
    (setf (itc-amount destination)            (itc-amount entity))
    (setf (itc-claimed destination)           (itc-claimed entity))
    (setf (itc-claim-month destination)       (itc-claim-month entity))
    ;; GSTR-2B
    (setf (in-gstr2b destination)             (in-gstr2b entity))
    (setf (gstr2b-match-status destination)   (gstr2b-match-status entity))
    (setf (gstr2b-verified-date destination)  (gstr2b-verified-date entity))
    ;; E-INVOICE
    (setf (e-invoice-required destination)    (e-invoice-required entity))
    (setf (irn destination)                   (irn entity))
    (setf (irn-date destination)              (irn-date entity))
    (setf (ack-number destination)            (ack-number entity))
    ;; RCM
    (setf (reverse-charge destination)        (reverse-charge entity))
    (setf (rcm-paid destination)              (rcm-paid entity))
    (setf (rcm-paid-date destination)         (rcm-paid-date entity))
    ;; PAYMENT AND STATUS
    (setf (payment-status destination)        (payment-status entity))
    (setf (uploaded-to-gstn destination)      (uploaded-to-gstn entity))
    (setf (gstn-upload-date destination)      (gstn-upload-date entity))
    ;; PLACE OF SUPPLY
    (setf (place-of-supply destination)       (place-of-supply entity))
    (setf (state-code destination)            (state-code entity))
    (setf (invoice-status destination)        (invoice-status entity))
    destination))

(defmethod domain->response ((entity nst-cinv-itc-summary) (ctx domain-ctx))
  "The summary crosses as its own boundary shape — it is a different FACT, not an
   invoice with missing fields, so it does not reuse NstCinvResponseModel."
  (let ((destination (make-instance 'NstCinvItcSummaryResponseModel)))
    (setf (invoices destination)  (invoices entity))
    (setf (claimable destination) (claimable entity))
    (setf (claimed destination)   (claimed entity))
    (setf (at-risk destination)   (at-risk entity))
    (setf (purchases destination) (purchases entity))
    destination))

(defun domain->response-list (entities ctx)
  "Each element through domain->response. Plain function, not a generic — the per-element
   dispatch already happens inside domain->response, so wrapping mapcar in a defmethod is
   ceremony. BELNAP NOTE: this is a pure structural transform and does NOT inspect each element's truth; route on sentinels BEFORE calling it."
  (mapcar (lambda (dom) (domain->response dom ctx)) entities))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 10 — render-json
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; Multiple dispatch on the response argument: a single response model, or a LIST
;;; of them. No if/else over types.
;;;
;;; SECURITY CONTRACT: each method is an explicit field allowlist. A slot added to
;;; NstCinvResponseModel does NOT auto-leak; it must be added here.
;;;
;;; render-html lives in nst-ui-cusinv.lisp, not here — it reuses display-as-table
;;; and the row renderer, both cl-who with HTML escaping. No render-html method is
;;; defined in this Tier-1 file, matching the warehouse.
;;;
;;; ID CONVENTION: identifiers cross as JSON strings (response-id-string), so a
;;; client never has to know that rowId is an int while invoice-number is a string.
;;; DATES cross as YYYY-MM-DD and timestamps as YYYY-MM-DD HH:MM:SS.
;;;
;;; ⚠ THE THREE ITC FIELDS ARE ALL PUBLISHED, under names that say which is which:
;;;   itcRecorded (the ledger column, null on every row today) / itcDerived (computed from the
;;;   invoice's own lines) / itcAmount (the effective figure displayed). Collapsing them to one key would recreate the ambiguity that let the page show ₹0.00 without anything looking broken.

(defmethod render-json ((r NstCinvResponseModel) (ctx domain-ctx))
  (list
   (cons "rowId"                  (response-id-string (row-id r)))
   ;; identity of the document
   (cons "invoiceNumber"          (invoice-number r))
   (cons "invoiceDate"            (invh-json-date (invoice-date r)))
   (cons "financialYear"          (financial-year r))
   (cons "gstPeriod"              (gst-period r))
   ;; the supplier
   (cons "vendorId"               (response-id-string (vendor-id r)))
   (cons "vendorName"             (vendor-name r))
   (cons "vendorTradeName"        (vendor-trade-name r))
   (cons "vendorGstin"            (vendor-gstin r))
   (cons "vendorGstType"          (vendor-gst-type r))
   (cons "vendorFilingFrequency"  (vendor-filing-frequency r))
   ;; the buyer (the session's own party — published so the page can print the
   ;; document as it was addressed, not as the session happens to be named)
   (cons "buyerId"                (response-id-string (buyer-id r)))
   (cons "buyerName"              (buyer-name r))
   (cons "buyerGstin"             (buyer-gstin r))
   (cons "buyerGstType"           (buyer-gst-type r))
   ;; money
   (cons "totalAmount"            (total-amount r))
   (cons "balanceDue"             (balance-due r))
   (cons "advanceAdjusted"        (advance-adjusted r))
   (cons "paymentAllocated"       (payment-allocated r))
   ;; ITC
   (cons "itcEligible"            (invh-json-flag (itc-eligible r)))
   (cons "itcClaimed"             (invh-json-flag (itc-claimed r)))
   (cons "itcClaimMonth"          (itc-claim-month r))
   (cons "itcRecorded"            (itc-recorded r))
   (cons "itcDerived"             (itc-derived r))
   (cons "itcAmount"              (itc-amount r))
   ;; GSTR-2B
   (cons "inGstr2b"               (invh-json-flag (in-gstr2b r)))
   (cons "gstr2bMatchStatus"      (gstr2b-match-status r))
   (cons "gstr2bVerifiedDate"     (invh-json-date (gstr2b-verified-date r)))
   ;; e-invoice
   (cons "eInvoiceRequired"       (invh-json-flag (e-invoice-required r)))
   (cons "irn"                    (irn r))
   (cons "irnDate"                (invh-json-timestamp (irn-date r)))
   (cons "ackNumber"              (ack-number r))
   ;; reverse charge
   (cons "reverseCharge"          (reverse-charge r))
   (cons "rcmPaid"                (invh-json-flag (rcm-paid r)))
   (cons "rcmPaidDate"            (invh-json-date (rcm-paid-date r)))
   ;; payment and status
   (cons "paymentStatus"          (payment-status r))
   (cons "uploadedToGstn"         (invh-json-flag (uploaded-to-gstn r)))
   (cons "gstnUploadDate"         (invh-json-timestamp (gstn-upload-date r)))
   ;; place of supply
   (cons "placeOfSupply"          (place-of-supply r))
   (cons "stateCode"              (state-code r))
   (cons "invoiceStatus"          (invoice-status r))))

(defmethod render-json ((responses list) (ctx domain-ctx))
  "Many register rows → a JSON array text.
   ⚠ THE EMPTY CASE IS ENCODED EXPLICITLY, BECAUSE THE OBVIOUS FORM IS WRONG AND ITS WRONGNESS IS INVISIBLE: the one-liner passes NIL to cl-json, and (json:encode-json-to-string nil) returns the text \"null\", NOT \"[]\" (measured on this image), so a register with no invoices, or any filter that matches nothing, sends a JSON null where every client is written to expect an array, and a browser doing `for (const x of resp)` on null throws.
   A zero-length vector encodes as [] (also measured), so the empty case goes through one and this file does not inherit the bug. ⚠ The same defect is live in the warehouse and invoice-header list methods; fixing them is a separate change and is deliberately not folded into this one."
  (json:encode-json-to-string
   (if responses
       (mapcar (lambda (r) (render-json r ctx)) responses)
       (make-array 0 :element-type t :adjustable t :fill-pointer 0))))

(defmethod render-json ((r NstCinvItcSummaryResponseModel) (ctx domain-ctx))
  "The ITC card → a JSON object.
   ⚠ atRisk IS null AND THAT IS THE PAYLOAD, NOT A MISSING FIELD: it means `not determined`, and
   atRiskReason carries the sentence that says why, so a client that wants to render money MUST test for null first — printing it as ₹0 is the original defect. atRiskReason is a plain string and atRisk a plain null, no booleans on purpose: this JSON layer cannot emit `false`, so a flag would silently become another indistinguishable null. ⚠ atRiskReason READS +cinv-at-risk-reason+ rather than a second hand-written sentence — an earlier copy named two internal tables in a field a client displays to a customer."
  (list
   (cons "invoices"  (invoices r))
   (cons "claimable" (claimable r))
   (cons "claimed"   (claimed r))
   (cons "atRisk"    (at-risk r))
   (cons "atRiskReason"
         (if (at-risk r)
             nil
             +cinv-at-risk-reason+))
   (cons "purchases" (purchases r))))
