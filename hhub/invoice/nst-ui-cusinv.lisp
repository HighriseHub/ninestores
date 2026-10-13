;;; nst-ui-cusinv.lisp — CUSTOMER (INWARD) INVOICE REGISTER — Ring 4 (UI)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; THE GRAMMAR: hhub/core/nst-bl-adhara.lisp (the ferry, the render contract)
;;; THE PLAYBOOK: hhub/nst-adhara-GENERIC-migration-playbook.md (§7 is this file)
;;; MASTER TEMPLATE: warehouse/nst-ui-warehouse.lisp
;;;
;;; WHAT THIS FILE REPLACES: invoice/nst-ui-cusinvreg.lisp — the page entry name is
;;; PRESERVED because hhub/sysuser/dod-ui-sys.lisp:1054 registers the regex
;;; dispatcher ^/hhub/nstcustinvoices against it. The grammar has no view model.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHY THIS LAYER CALLS `enumerate` DIRECTLY INSTEAD OF RIDING THE FERRY
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; The playbook (§7) says call (request->dispatch rm 'enumerate 'nst-cinv ctx) — its
;;; own §6 names why not here: the ferry forwards ONLY entity INITARGS, so :for-buyer
;;; and :itc are dropped and cinv-require-buyer raises instead of widening the query.
;;;
;;; The playbook's own instruction: "call the enumerate verb directly only where the
;;; UI has no other choice, and annotate why in the code." The request model is STILL
;;; the inbound carrier — the payload lives in (params rm) — only the final hop is direct.
;;;
;;; ⚠ THIS IS A TRANSITIONAL SHAPE, NOT A DESIGN CHOICE. When the core-side
;;; forward for query keys lands, this function should be reduced to a
;;; request->dispatch call and nothing else should change.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THE FOUR TILES ARE LINKS (the requested change, confirmed 2026-10-13)
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; Claimable · At Risk · Claimed · Invoices each become an <a> that re-opens this
;;; same page with ?itc=<filter>. No new route, policy row or transaction row is
;;; needed, because the URL is unchanged — only the query string differs.
;;;
;;; THE CARD NEVER FILTERS, ONLY THE TABLE DOES: if the card's own figures followed
;;; the active filter, clicking "Claimable" would leave a card reading "₹0.00 | 0
;;; Invoices" and the numbers would stop meaning anything.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 1 — the page entry
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; ⚠ THE FUNCTION NAME IS LOAD-BEARING AND IS DELIBERATELY UNCHANGED.
;;; hhub/sysuser/dod-ui-sys.lisp:1054 registers the regex dispatcher
;;; ^/hhub/nstcustinvoices against it, so renaming it would break the route silently.

(defun com-hhub-transaction-customer-invoice-register-page ()
  (with-cust-session-check
    (with-mvc-ui-page "My Invoices"
      #'create-model-for-customer-invoice-register
      #'create-widgets-for-customer-invoice-register
      :role :customer)))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 2 — the filter the four tiles switch on
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; These four keywords are the whole vocabulary. 'at-risk' is offered as a tile but
;;; resolves to a sentinel rather than a list — see enumerate's docstring; the tile's
;;; own figure says "Not determined" so the click cannot surprise anyone.

(defparameter *cinv-itc-filters* '(:all :claimable :claimed :at-risk)
  "The filter keywords ?itc= may select.")

(defun cinv-active-itc-filter ()
  "The ?itc= filter for this request, or :all. An unrecognised value resolves to
   :all rather than signalling — not the silent-parameter trap, because the outcome
   is VISIBLE (unfiltered list, All tile highlighted); the API layer differs on purpose."
  (let ((raw (hunchentoot:get-parameter "itc")))
    (cond ((null raw) :all)
          ((member (intern (string-upcase raw) :keyword) *cinv-itc-filters*)
           (intern (string-upcase raw) :keyword))
          (t :all))))

(defun cinv-itc-filter-href (filter)
  "The page URL for FILTER. Relative on purpose, exactly like the nav bar's
   \"nstcustinvoices\" link, so the page works behind the /hhub prefix and from any
   host without hard-coding either."
  (format nil "nstcustinvoices?itc=~(~A~)"
          (string-downcase (symbol-name filter))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 3 — payload → enumerate query arguments
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; The analogue of whs-enumerate-args (nst-bl-whsapi.lisp) and invh-enumerate-args
;;; (nst-bl-invhapi.lisp): where a verb's QUERY arguments — not entity initargs, so
;;; not the ferry's business — are assembled. See the file header for why.
;;;
;;; ⚠ :for-buyer IS NOT READ FROM THE PAYLOAD. It is passed in from the session by
;;; the caller (cinv-buyer-from-session → the logged-in customer): the tenant comes
;;; from ctx and the buyer from the session, and NEITHER may come from a request.

(defun cinv-enumerate-args (payload buyer-id)
  "Query arguments for (enumerate 'nst-cinv ctx …). PAYLOAD is the request model's
   params plist: the filters are read from it, the buyer is not — the argument list
   below IS the contract, so an unnamed payload key cannot reach the verb."
  (list :for-buyer buyer-id
        :itc       (or (getf payload :itc) :all)))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 4 — the model
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; Returns FIVE values. Two of them exist only because a Belnap sentinel is not an
;;; empty list:
;;;
;;;   1 responselist — LIST of NstCinvResponseModel, possibly NIL; 2 summary — card
;;;   object or NIL; 3 sentinel-reason — STRING when the register answered :U/:C, and
;;;   THE PAGE MUST RENDER IT, not an empty table; 4 active-filter; 5 ctx.
;;;
;;; ⚠ THE SUMMARY IS REQUESTED UNFILTERED, ALWAYS. The card reports the buyer's
;;; whole position; the table below it is what the tile narrows. See the header.

(defun cinv-summary-response (summary-entity ctx)
  "The card's outbound boundary object: ferries nst-cinv-itc-summary, NIL otherwise.
   🚨 The inline test it replaces read (if (typep summary-entity 'nst-domain-entity) nil
   (domain->response …)): NIL for the very type it should ferry, and a 500 on at-risk."
  (if (typep summary-entity 'nst-cinv-itc-summary)
      (domain->response summary-entity ctx)
      nil))

(defun create-model-for-customer-invoice-register ()
  (let* ((company   (get-login-customer-company))
         (customer  (get-login-customer))
         (buyer-id  (and customer (slot-value customer 'row-id)))
         (active    (cinv-active-itc-filter))
         (ctx       (make-domain-ctx :actor "CUSTOMER" :tenant company
                                     :channel "ONLINE"
                                     :recipient "CUSTOMER" :source "CUSTOMER"))
         (rm        (make-instance 'NstCinvRequestModel
                                   :params (list :itc active)))
         (rows      (apply #'enumerate 'nst-cinv ctx
                           (cinv-enumerate-args (params rm) buyer-id)))
         ;; ⚠ THIS typep IS CORRECT HERE AND IS *NOT* A PATTERN TO COPY: enumerate
         ;; answers a LIST or a Belnap sentinel, and a list is not an nst-domain-entity —
         ;; wrong for a SINGLE entity; use cinv-invoice-found-p (nst-bl-cusinv.lisp).
         (sentinel  (when (typep rows 'nst-domain-entity) rows))
         (responselist (unless sentinel (domain->response-list rows ctx)))
         ;; The summary is a SEPARATE crossing and deliberately unfiltered. It delegates
         ;; to enumerate internally, so a register that could not be read yields the SAME
         ;; sentinel here — no card to show, and the reason above already says why.
         (summary-entity (unless sentinel (summarize-itc 'nst-cinv ctx :for-buyer buyer-id)))
         ;; ── FERRY THE SUMMARY ONLY WHEN IT IS THE TYPE THE CARD CAN RENDER ─────
         ;;
         ;; 🚨 THE INLINE TEST WAS WRONG IN TWO DIRECTIONS AT ONCE: it returned NIL for
         ;; the very type it should ferry ("—" on every ordinary view), and on ?itc=at-risk
         ;; it handed a NIL to domain->response, which has no NULL method by design.
         (summary   (cinv-summary-response summary-entity ctx))
         (params nil))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (setf params (acons "company" company params))
    (with-hhub-transaction "com-hhub-transaction-customer-invoices-listpage" params
      (function (lambda ()
        (values responselist summary
                (and sentinel (entity-reason sentinel))
                active ctx))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 5 — formatting
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; ⚠ MONEY IS FORMATTED WITH ~,2F, AND THAT IS A FIX, NOT A STYLE PREFERENCE.
;;; The retired row renderer used (format nil "₹~A" (total-amount vm)) on a float slot,
;;; so 2950.00 printed as "₹2950.0". Two decimal places is what a money column is for.

(defun cinv-money (amount)
  "AMOUNT as \"₹1,234.56\"-style-two-decimals text, or \"—\" when it is genuinely
   absent. NIL and 0 are DIFFERENT: 0 is a figure, NIL is a figure we do not have."
  (cond ((null amount) "—")
        (t (handler-case (format nil "₹~,2F" (float amount))
             (error () (format nil "₹~A" amount))))))

(defun cinv-date-str (value)
  "A DATE column → \"YYYY-MM-DD\", NIL → \"—\". Reuses invh-json-date, which
   already handles a CLSQL date, a wall-time integer read back from MySQL, and a
   string, and which the live invoice API exercises on every fetch."
  (or (invh-json-date value) "—"))

(defun cinv-label-from-enum (value &optional (default "—"))
  "An ENUM column → a printable label: \"NOT_CHECKED\" → \"Not checked\". ⚠ NOT
   string-capitalize — that capitalises the first letter of EVERY word, giving \"Not
   Checked\". ⚠ NO VALUE IS INVENTED: an absent column reads as the default."
  (if (null value)
      default
      (let ((s (substitute #\Space #\_ (string-downcase (string value)))))
        (if (plusp (length s))
            (concatenate 'string (string (char-upcase (char s 0))) (subseq s 1))
            s))))

;;; ── THE TWO TILE HELPERS RETURN PLAIN STRINGS, AND THAT IS THE POINT ─────────
;;;
;;; ⚠ THEY ARE PURE ON PURPOSE — THEY DO NOT TOUCH CL-WHO. cl-who's htm / str / fmt /
;;; esc and every tag keyword are a MACROLET inside with-html-output, NOT global macros,
;;; so a helper defined outside that body compiles with a style-warning and then 500s.
;;;
;;; So the tile's TEXT is computed here, where it can also be asserted offline by
;;; a test, and the four <a> elements are written inline inside the
;;; with-html-output body below, where the tag macros are actually in scope.

(defun cinv-tile-figure (summary filter)
  "The figure one tile displays, as TEXT. SUMMARY may be NIL (the register could
   not be read), in which case no tile invents a number."
  (case filter
    (:claimable (if summary (cinv-money (claimable summary)) "—"))
    ;; AT RISK SHOWS WORDS WHEN IT IS UNKNOWN, NOT A ZERO. See the note on the
    ;; nst-cinv-itc-summary at-risk slot: this system cannot determine it, and
    ;; "₹0" would assert that nothing is at risk.
    (:at-risk   (if (and summary (at-risk summary))
                    (cinv-money (at-risk summary))
                    "Not determined"))
    (:claimed   (if summary (cinv-money (claimed summary)) "—"))
    (:all       (if summary (format nil "~A" (invoices summary)) "—"))
    (otherwise  "—")))

;;; ── THE FILTER MENU: the strip ───────────────────────────────────────────────
;;;
;;; The four invoice types are presented as a STRIP MENU, following
;;; invoice-header-actions-menu / invoices-actions-menu (hhub/invoice/nst-ui-ihd.lisp):
;;; a rounded, light-blue bar laid out as a Bootstrap row of equal clickable columns.
;;;
;;; ⚠ THE COLUMN MACROS CARRY THEIR ATTRIBUTES AS BODY FORMS, WHICH LOOKS WRONG AND IS
;;; NOT: the body is spliced into (:div :class "col-3" ,@body), so a keyword/value pair
;;; reads as an attribute (cl-who's own tag syntax) — hence a computed STYLE, not CLASS.
;;;
;;; ⚠ THE COLUMN MACROS EACH OPEN THEIR OWN with-html-output: that is the PRINTING
;;; macro, but nested inside the outer with-html-output-to-string it binds
;;; *standard-output* to the string stream already in force, so the output IS collected.
;;;
;;; ⚠ NO data-bs-toggle="popover" HERE, ALTHOUGH THE INVOICE MENUS SET IT: nothing in
;;; this tree initialises Bootstrap popovers, so the toggle attribute is inert and the
;;; tooltip a user actually sees is the native one from `title`, which is set on every cell.

(defparameter +cinv-strip-style+
  "border-radius: 5px; background-color:#e6f0ff; border-bottom: solid 1px; margin: 5px 0 5px 0; padding: 6px 4px; min-height: 30px; font-size: 1rem;"
  "The strip's own bar: the invoice menus' values, but margin: 15px became 5px 0 (it sits
   inside a panel body) and height: 30px became min-height: 30px — a fixed height clips
   once a caption wraps, and \"Not determined\" is a long value.")

(defun cinv-strip-item-style (active filter)
  "The style of one strip cell's <a>. The ACTIVE filter is emphasised so the
   filter the page is showing is always visible: the strip navigates, the summary
   figures above it never follow the filter (see the file header)."
  (if (eq filter active)
      "display:block; text-decoration:none; padding:2px 4px; border-radius:4px; font-weight:bold; background-color:#cfe2ff; color:#084298;"
      "display:block; text-decoration:none; padding:2px 4px; color:#212529;"))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 6 — render-html
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; render-html is the dṛś धातु: a Tree-2 boundary object into transport text, cardinality
;;; resolved by CLOS dispatch. render-html-list is a PLAIN FUNCTION, not a generic — 'list'
;;; cannot discriminate contents — and the per-element dispatch happens inside render-html.
;;;
;;; ⚠ THE TWO CL-WHO OUTPUT MACROS ARE NOT INTERCHANGEABLE, AND THE DIFFERENCE WAS
;;; MEASURED ON THIS IMAGE (2026-10-13) AFTER IT SILENTLY BROKE THE CARD:
;;;
;;;   (cl-who:with-html-output (*standard-output* nil) …) PRINTS to *standard-output* and
;;;       returns a MEANINGLESS TAIL (e.g. "</div></div>") — the PRINTING idiom, which is
;;;       what display-as-table's row callback must use.
;;;
;;;   (cl-who:with-html-output-to-string (*standard-output* nil) …)
;;;       COLLECTS and RETURNS the markup as a string. This is the RETURNING idiom.
;;;
;;;   And (cl-who:htm …) DISCARDS the value of a nested non-tag form — measured,
;;;   (:div (identity "<b>raw</b>")) renders "<div></div>" — so a function called from
;;;   display-as-table MUST print; it cannot return its cells and hope they are emitted.
;;;
;;; Hence the split below, which is deliberate and is the only combination that
;;; works: the ROW renderer prints (display-as-table calls it in print context),
;;; the CARD returns a string (the widget and render-html consume it as a value).
;;;
;;; SECURITY — MEASURED, AND THE OBVIOUS ASSUMPTION IS WRONG: cl-who:str does NOT escape
;;; (cl-who:escape-string does), so `str` is an OUTPUT primitive, not a sanitiser — a cell
;;; carrying DB free text is only safe if escaped explicitly, as cinv-esc does below.

(defun cinv-esc (value)
  "VALUE for HTML output, ESCAPED, or an em-dash entity when absent: used for the cells
   whose content is DB free text a third party controls — the VENDOR's own name. The full
   stored-XSS finding is a WRITE-side problem in knowledge/markup-safety-CONTEXT.md."
  (if (null value)
      "&#8212;"
      (cl-who:escape-string (string value))))

(defun cinv-vendor-cell-html (rm)
  "The Vendor cell: the supplier's name as a link that opens their details modal (the
   name is escaped — it is supplier-controlled free text). ⚠ THE MODAL IS NOT EMITTED
   HERE: a duplicate DOM id per supplier would make data-bs-target open the FIRST row's."
  (let ((vid (vendor-id rm)))
    (if (null vid)
        ;; No supplier id on the row: no modal to open, so no link either — a
        ;; control that does nothing is worse than plain text.
        (cinv-esc (vendor-name rm))
        (format nil "<a href='#' class='link-primary text-decoration-none' data-bs-toggle='modal' data-bs-target='#~A' title='Show supplier details'><i class='fa-solid fa-store'></i>&nbsp;~A</a>"
                (cinv-vendor-modal-id vid)
                (cinv-esc (vendor-name rm))))))

(defun cinv-invoice-link-html (rm)
  "The invoice NUMBER as a link to its details page, or plain text when the row carries
   no id (a control that does nothing is worse than plain text). Addressed by
   ?id=<the register row's id> — the invoice HEADER's row-id, the line read's :invheadid."
  (let ((rid (row-id rm)))
    (if (null rid)
        (cinv-esc (invoice-number rm))
        (format nil "<a href='nstcustinvoicedetails?id=~A' class='link-primary text-decoration-none fw-semibold' title='Open this invoice'><i class='fa-regular fa-file-lines'></i>&nbsp;~A</a>"
                (cl-who:escape-string (format nil "~A" rid))
                (cinv-esc (invoice-number rm))))))

(defun cinv-vendor-modal-id (vendor-id)
  "The DOM id of the details modal for VENDOR-ID. ONE place builds it, so the
   trigger's data-bs-target and the modal's own id cannot drift apart — a mismatch
   is a link that silently does nothing."
  (format nil "cinvvendor-modal~A" vendor-id))

(defun cinv-vendor-modals-html (responselist)
  "ONE supplier-details modal per DISTINCT supplier on the page, as a STRING. Deduped by
   vendor-id, which fixes both halves of the per-row approach: duplicate DOM ids and one
   vendor lookup per INVOICE. modal.vendor-details PRINTS, and the enclosing collector captures it."
  (let ((seen '()))
    (cl-who:with-html-output-to-string (*standard-output* nil)
      (dolist (r responselist)
        (let ((vid (vendor-id r)))
          (when (and vid (not (member vid seen :test #'eql)))
            (push vid seen)
            (modal-dialog-v2 (cinv-vendor-modal-id vid)
                             (cl-who:str "Supplier details")
                             (modal.vendor-details vid))))))))

(defmethod render-html ((rm NstCinvResponseModel) (ctx domain-ctx))
  "One register row → this method PRINTS the <td> cells and returns NIL. ⚠ IT DOES NOT
   RETURN ITS MARKUP, AND THAT IS FORCED: display-as-table calls it in print context, and
   cl-who:htm discards a nested non-tag form's value — a returning row would print an empty table."
  (declare (ignore ctx))
  (display-customer-invoice-register-row rm))

(defun render-html-list (responses ctx)
  "The register table. Delegates each row to render-html's single-row method."
  (when responses
    (display-as-table (list "Invoice No" "Date" "Vendor"
                            "Amount" "ITC" "GSTR2B" "Payment")
                      responses
                      (lambda (r &rest _)
                        (declare (ignore _))
                        (render-html r ctx)))))

(defun display-customer-invoice-register-row (rm &rest args)
  "Display one register row. ARGS is display-as-table's passthrough and is unused."
  (declare (ignore args))
  (cl-who:with-html-output (*standard-output* nil)
    ;; ── THE INVOICE NUMBER OPENS THE DETAILS PAGE ──────────────────────────
    ;; See SECTION 8. Plain text when the row has no id, so there is no link that
    ;; goes nowhere.
    (:td (cl-who:str (cinv-invoice-link-html rm)))
    (:td (cl-who:str (cinv-date-str (invoice-date rm))))
    ;; ── THE SUPPLIER CELL ──────────────────────────────────────────────────
    ;; The name links to that supplier's details modal, which is NOT emitted here: one modal
    ;; per DISTINCT supplier (cinv-vendor-modals-html), or the DOM id would repeat per invoice.
    (:td (cl-who:str (cinv-vendor-cell-html rm)))
    (:td :align "right" (cl-who:str (cinv-money (total-amount rm))))
    ;; ── THE ITC CELL, AND ITS PROVENANCE ───────────────────────────────────
    ;; itc-amount is the EFFECTIVE figure — the ledger value once a claim is recorded, else
    ;; the invoice's own line taxes — and `title` says which: an invisible origin read ₹0.00.
    (:td :align "right"
         :title (if (itc-recorded rm)
                    "Recorded in the ITC ledger for this invoice."
                    "Computed from this invoice's own line items: CGST + SGST + IGST. No ITC has been recorded against this invoice yet, so nothing in the ledger was available to show.")
         (cl-who:str (cinv-money (itc-amount rm))))
    (:td (cl-who:str
          (let* ((status (string-upcase (or (gstr2b-match-status rm) "NOT_CHECKED")))
                 (icon (cond ((string-equal status "MATCHED") "✅")
                             ((string-equal status "MISMATCHED") "⚠️")
                             ((string-equal status "MISSING") "❌")
                             (t "—"))))
            (format nil "~A ~A" icon (cinv-label-from-enum status)))))
    (:td (cl-who:str
          (let* ((status (string-upcase (or (payment-status rm) "UNPAID")))
                 (icon (cond ((string-equal status "PAID") "✅")
                             ((string-equal status "PARTIALLY_PAID") "⚠️")
                             ((string-equal status "UNPAID") "❌")
                             (t ""))))
            (format nil "~A ~A" icon (cinv-label-from-enum status)))))))

(defmethod render-html ((r NstCinvItcSummaryResponseModel) (ctx domain-ctx))
  "The ITC card with NO strip cell emphasised — the grammar-complete entry point. The page
   renders the card through cinv-itc-summary-html, which knows the active filter; this is
   the same card for a consumer that has only a response model. One implementation, two entries."
  (declare (ignore ctx))
  (cinv-itc-summary-html r :all))

(defun cinv-itc-summary-html (summary active)
  "The \"Your ITC Summary\" card: the heading, then the four invoice types as a STRIP MENU.
   SUMMARY may be NIL (the register could not be read). ⚠ THE FOUR CELLS ARE WRITTEN OUT
   INLINE: a helper outside with-html-output's macrolet would 500, and it RETURNS its markup."
  (cl-who:with-html-output-to-string (*standard-output* nil)
    (:div :class "panel panel-success"
      (:div :class "panel-heading"
        (:h3 :class "panel-title" "Your ITC Summary"))
      (:div :class "panel-body"
        (with-html-div-row :style +cinv-strip-style+
          ;; ── CLAIMABLE ──────────────────────────────────────────────────────
          ;; Credit available and not yet taken. THIS FIGURE WAS FLATLY WRONG: it read ₹0.00
          ;; because ITC_AMOUNT is NULL on every row while live invoices carried ₹585.10 of tax.
          (with-html-div-col-3
            (:a :href  (cinv-itc-filter-href :claimable)
                :style (cinv-strip-item-style active :claimable)
                :title "Show only invoices whose ITC is still claimable"
                (:i :class "fa-solid fa-indian-rupee-sign")
                (cl-who:str " Claimable ")
                (:strong (cl-who:str (cinv-tile-figure summary :claimable)))))
          ;; ── AT RISK ────────────────────────────────────────────────────────
          ;; THE FIGURE IS WORDS, NOT A ZERO: at-risk needs the supplier's GSTR-1 filing
          ;; status and an ingested GSTR-2B, and neither exists. Clicking explains why.
          (with-html-div-col-3
            (:a :href  (cinv-itc-filter-href :at-risk)
                :style (cinv-strip-item-style active :at-risk)
                :title "At risk cannot be determined from the data held; clicking explains why"
                (:i :class "fa-solid fa-triangle-exclamation")
                (cl-who:str " At Risk ")
                (:strong (cl-who:str (cinv-tile-figure summary :at-risk)))))
          ;; ── CLAIMED ────────────────────────────────────────────────────────
          ;; Always ₹0.00 today: nothing writes ITC_CLAIMED. A TRUE zero, unlike
          ;; At Risk — the flag is real and it is FALSE.
          (with-html-div-col-3
            (:a :href  (cinv-itc-filter-href :claimed)
                :style (cinv-strip-item-style active :claimed)
                :title "Show only invoices whose ITC has been claimed"
                (:i :class "fa-solid fa-circle-check")
                (cl-who:str " Claimed ")
                (:strong (cl-who:str (cinv-tile-figure summary :claimed)))))
          ;; ── INVOICES ───────────────────────────────────────────────────────
          ;; The row count, and the way back to the unfiltered register.
          (with-html-div-col-3
            (:a :href  (cinv-itc-filter-href :all)
                :style (cinv-strip-item-style active :all)
                :title "Show every invoice in the register"
                (:i :class "fa-solid fa-list")
                (cl-who:str " Invoices ")
                (:strong (cl-who:str (cinv-tile-figure summary :all)))))))
      ;; The caveat belongs on the card, in the card's own voice, because the strip
      ;; cell above cannot say WHY it does not know.
      (when (or (null summary) (null (at-risk summary)))
        (cl-who:htm
         (:div :class "panel-footer"
           (:small :class "text-muted"
             "At Risk is reported as not determined, not as zero. It needs the supplier's GSTR-1 filing status and the buyer's GSTR-2B, and no such data has been ingested. \"₹0 at risk\" would be a claim this system cannot support.")))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 7 — the widgets
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; The widget contract is with-mvc-ui-page's, unchanged: a model function and a function
;;; of that model returning widget thunks. The model's FIVE values are destructured here
;;; and every one of them is rendered, so nothing the model computes is silently dropped.

(defun create-widgets-for-customer-invoice-register (modelfunc)
  (multiple-value-bind (responselist summary sentinel-reason active ctx)
      (funcall modelfunc)
    (let ((widget1 (function (lambda ()
                     (cl-who:with-html-output (*standard-output* nil)
                       (cl-who:str (cinv-itc-summary-html summary active))))))
          (widget2 (function (lambda ()
                     (cl-who:with-html-output (*standard-output* nil)
                       (:div :class "row"
                         (:div :class "col-xs-12"
                           (:h4 (cl-who:str
                                 (case active
                                   (:claimable "Invoices with claimable ITC")
                                   (:claimed   "Invoices whose ITC has been claimed")
                                   (:at-risk   "Invoices at risk")
                                   (otherwise  "All Invoices"))))
                           (:hr)
                           (cond
                             ;; ── THE VIEW COULD NOT BE PRODUCED ────────────────
                             ;; A warning panel carrying the sentinel's own reason, NOT an empty
                             ;; table: "we could not produce this view" is not "you have no invoices".
                             ;;
                             ;; ⚠ THE LEAD-IN IS NEUTRAL ON PURPOSE: "The register could not be
                             ;; read" is FALSE for the at-risk filter, where the register reads
                             ;; fine and it is one unanswered question — not a zero we do not have.
                             (sentinel-reason
                              (cl-who:htm
                               (:div :class "alert alert-warning"
                                 (:strong "This view is not available. ")
                                 (cl-who:str sentinel-reason))))
                             ;; ── READ, AND GENUINELY EMPTY ────────────────────
                             ((null responselist)
                              (cl-who:htm
                               (:p :class "text-muted"
                                 (cl-who:str
                                  (if (eq active :all)
                                      "No inward invoices have been recorded for this account. This register lists invoices a supplier has issued to your business, so a personal or unregistered purchase will not appear here."
                                      "No invoices match this filter.")))))
                             (t (cl-who:htm
                                 ;; The table, then the supplier modals it links to. Order
                                 ;; matters to nothing visual (a modal is position:fixed) but
                                 ;; the modals must exist for the row links to open anything.
                                 (cl-who:str (render-html-list responselist ctx))
                                 (cl-who:str (cinv-vendor-modals-html responselist))))))))))))
      (list widget1 widget2))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 8 — THE INVOICE DETAILS PAGE  (^/hhub/nstcustinvoicedetails)
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; Reached by clicking the invoice NUMBER in a register row.
;;;
;;; ⚠ THE DOCUMENT IS THE VENDOR'S OWN TEMPLATE, FILLED — NOT A SECOND RENDERING, which
;;; cannot promise "the customer sees what the vendor sees" nor print the statutory fields
;;; this register's VIEW does not publish: build-invoice-template-document fills the vendor's own gstinvoice*.html.
;;;
;;; ONE STEP IS A GUARD AND MUST COME FIRST:
;;;
;;;   1. fetch 'nst-cinv — buyer AND tenant scoped, so the invoice must be in THIS
;;;      customer's own register.
;;;   2. build-invoice-template-document — the vendor's template, filled.
;;;
;;; ⚠ THE ORDER IS THE WHOLE SECURITY ARGUMENT, NOT A STYLE CHOICE: the template builder
;;; reads by (invnum, company) and knows nothing about a buyer, so rendering a
;;; client-supplied invoice number without step 1 would show ANY invoice to ANY customer.

(defun com-hhub-transaction-customer-invoice-details-page ()
  "The page handler. The NAME is what sysuser/dod-ui-sys.lisp registers the
  ^/hhub/nstcustinvoicedetails dispatcher against."
  (with-cust-session-check
    (with-mvc-ui-page "Invoice"
      #'create-model-for-customer-invoice-details
      #'create-widgets-for-customer-invoice-details
      :role :customer)))

(defun cinv-details-request-model ()
  "The inbound carrier for the details page's one address: ?id=<invoice row-id>.
   Built as a real request model so the fetch rides the FERRY rather than calling the
   verb directly — fetch takes no query arguments, so nothing is lost on the way."
  (make-instance 'NstCinvRequestModel
                 :params (list :row-id (hunchentoot:get-parameter "id"))))

(defun create-model-for-customer-invoice-details ()
  "Returns (values document-html error-reason ctx)."
  (let* ((company  (get-login-customer-company))
         (ctx      (make-domain-ctx :actor "CUSTOMER" :tenant company
                                    :channel "ONLINE"
                                    :recipient "CUSTOMER" :source "CUSTOMER"))
         ;; ── STEP 1: THE GUARD ──────────────────────────────────────────────
         (header   (request->dispatch (cinv-details-request-model) 'fetch 'nst-cinv ctx)))
    (cond
      ;; ── SUCCESS ──────────────────────────────────────────────────────────
      ;; ⚠ cinv-invoice-found-p, NOT (typep header 'nst-domain-entity) — that predicate is TRUE
      ;; for a real nst-cinv AND all three sentinels, so a success called entity-reason on it.
      ((cinv-invoice-found-p header)
       (let* ((vendor   (select-vendor-by-id (vendor-id header)))
              (document (when vendor
                          (build-invoice-template-document
                           (invoice-number header) vendor company))))
         (function
          (lambda ()
            (values document
                    (cond ((null vendor)
                           "The supplier this invoice names no longer resolves, so the invoice document cannot be produced.")
                          ((null document)
                           "The invoice document could not be produced for this invoice. It may have been withdrawn since it was issued.")
                          (t nil))
                    ctx)))))
      ;; ── A BELNAP SENTINEL: not this customer's invoice, or not in this company ──
      ;; entity-reason IS defined here, which is exactly what is not true above.
      ((typep header 'nst-domain-entity)
       (function (lambda () (values nil (entity-reason header) ctx))))
      ;; ── NEITHER: fetch answered something we cannot explain ─────────────────
      ;; Guarded rather than falling through to (entity-reason nil), which would be the
      ;; same class of crash as the one above.
      (t
       (function
        (lambda ()
          (values nil "This invoice could not be read." ctx)))))))

(defun create-widgets-for-customer-invoice-details (modelfunc)
  (multiple-value-bind (document error-reason ctx) (funcall modelfunc)
    (declare (ignore ctx))
    (let ((widget1
            (function
             (lambda ()
               (cl-who:with-html-output (*standard-output* nil)
                 (if error-reason
                     (cl-who:htm
                      (:div :class "alert alert-warning"
                        (:strong "This invoice is not available. ")
                        (cl-who:str error-reason)))
                     (cl-who:htm
                      ;; ── THE ONLY CONTROL THE VENDOR'S DOCUMENT DOES NOT CARRY ──
                      ;; The button sits OUTSIDE the template — not ours to add buttons to —
                      ;; because wkhtmltopdf would rewrite a relative href into a live URL in the PDF.
                      (:div :class "text-end mb-2 no-print"
                        (:a :class "btn btn-primary"
                            :href  (format nil "nstcustinvoicedownload?id=~A"
                                           (hunchentoot:get-parameter "id"))
                            :title "Build this invoice as a PDF and open it"
                            (:i :class "fa-solid fa-file-arrow-down")
                            (cl-who:str "&nbsp;Download PDF")))
                      (:hr :style "border-top: 2px dashed gray;")
                      ;; ⚠ cl-who:str DOES NOT ESCAPE (see Section 6), and that is what is
                      ;; wanted here: DOCUMENT is a rendered HTML document, trusted because it
                      ;; comes from our own template and our own escaping inside invoicetemplatefill.
                      (cl-who:str document))))))))
      (list widget1))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 9 — THE PDF DOWNLOAD  (^/hhub/nstcustinvoicedownload)
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; ⚠ THIS IS THE SAME PIPELINE THE VENDOR'S DOWNLOAD AND THE INVOICE EMAIL USE, not a
;;; second renderer: mint the invoice's public page URL with :render t, wget it, run
;;; wkhtmltopdf over it and answer 302 — so the PDF IS the invoice document, not a lookalike.
;;;
;;; ⚠ IT SHELLS OUT AND THE SERVER FETCHES ITSELF, so it is SLOW and it needs *siteurl*
;;; to point at THIS deployment — a property of the pipeline the vendor path and the email
;;; attachment inherit too (see invh-download-pdf-url), but a customer waits on it.

(defun cinv-download-pdf-url (entity ctx)
  "The public URL of ENTITY's print-ready PDF, or a Belnap sentinel. ⚠ ENTITY IS THE
   DOMAIN ENTITY (nst-cinv), NOT ITS RESPONSE MODEL: it reads the inherited tenant-id,
   which the boundary model does not carry — a response model fails on MISSING-SLOT TENANT-ID."
  (declare (ignore ctx))
  (let ((vendor (select-vendor-by-id (vendor-id entity)))
        (company (select-company-by-id (tenant-id entity))))
    (if (or (null vendor) (null company))
        ;; The invoice EXISTS — the caller already fetched it under its own buyer and
        ;; tenant — so "no such invoice" would be a lie, and the pipeline cannot
        ;; proceed either. That is a :U, not a :F.
        (make-instance 'nst-entity-unknown
                       :tenant-id (tenant-id entity)
                       :reason (format nil "The supplier or company this invoice names no longer resolves, so its PDF cannot be produced."))
        (handler-case
            (let* ((invnum (invoice-number entity))
                   ;; :RENDER T — the fetch is the server itself and there is no
                   ;; customer at the other end to answer the public page's password
                   ;; prompt. Without the marker the PDF is a picture of that prompt.
                   (external-url (generate-invoice-ext-url invnum vendor company :render t))
                   (htmlfile (downloadhtmlfile external-url))
                   (pdffile (generatepdf htmlfile invnum)))
              (format nil "~A/img/temp/~A" *siteurl* pdffile))
          ;; ⚠ generate-invoice-ext-url FAILS CLOSED with a plain error when the supplier has
          ;; no SALT to sign a link with — a data problem, not the customer's, and it must not
          ;; surface as a 500 with a backtrace: the page says so and stops.
          (error (c)
            (make-instance 'nst-entity-unknown
                           :tenant-id (tenant-id entity)
                           :reason (format nil "The PDF could not be produced for this invoice: ~A" c)))))))

(defun com-hhub-transaction-customer-invoice-download ()
  "The PDF button's handler. Answers 302 at the generated file, or a message when the
   invoice is not this customer's (or the PDF could not be built)."
  (with-cust-session-check
    (let* ((company (get-login-customer-company))
           (ctx     (make-domain-ctx :actor "CUSTOMER" :tenant company
                                     :channel "ONLINE"
                                     :recipient "CUSTOMER" :source "CUSTOMER"))
           (header  (request->dispatch (cinv-details-request-model) 'fetch 'nst-cinv ctx)))
      (cond
        ;; A sentinel from the buyer-scoped fetch IS the answer: an invoice outside
        ;; this customer's register must not become a download.
        ((not (typep header 'nst-cinv))
         (setf (hunchentoot:return-code*) 404)
         (cl-who:with-html-output-to-string (*standard-output* nil)
           (:div :class "alert alert-warning"
             (:strong "This invoice is not available. ")
             (cl-who:str (cinv-esc (entity-reason header))))))
        (t
         (let ((url (cinv-download-pdf-url header ctx)))
           (if (stringp url)
               ;; hunchentoot:redirect sets Location + status and throws out to
               ;; hunchentoot's catch tag, so nothing after it runs and no body is
               ;; written. Same delivery choice as route-invh-download.
               (hunchentoot:redirect url :code 302)
               (progn (setf (hunchentoot:return-code*) 503)
                      (cl-who:with-html-output-to-string (*standard-output* nil)
                        (:div :class "alert alert-warning"
                          (cl-who:str (cinv-esc (entity-reason url)))))))))))))
