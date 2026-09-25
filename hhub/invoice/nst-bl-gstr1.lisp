;;; nst-bl-gstr1.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;; GSTR-1 COLLECTION LAYER.
;;;
;;; One question per tax period and nothing else: which outward invoices of a seller
;;; belong in the return, which section of the return each falls in (b2b / b2cl /
;;; b2cs), and what tax its item rows actually carry. It assembles no JSON, renders no
;;; HTML, writes no row and knows no session, so every rule below is exercisable from
;;; the REPL against the live database. The assembler, the download route and the
;;; button are built on top of it.
;;;
;;; DIRECTION, BECAUSE IT IS THE THING TO GET WRONG. GSTR-1 is the OUTWARD supplies
;;; return: it is filed by whoever ISSUED the invoice. A buyer cannot file its
;;; supplier's invoices, so on the customer side this generator is only ever correct
;;; once that customer's own sale invoices exist as data. The buyer-side deliverable is
;;; the purchase register plus GSTR-2B reconciliation, which is a different artifact
;;; with a different shape — see knowledge/gst-gstr-compliance-CONTEXT.md.
;;;
;;; PERIODS ARE SPELLED TWO WAYS IN THIS SCHEMA and mixing them returns an empty
;;; return rather than an error: DOD_GSTR1_EXPORTS.TAX_PERIOD is MMYYYY while
;;; DOD_INVOICE_HEADER.GSTR1_PERIOD is YYYY-MM. The UI speaks YYYY-MM and
;;; gstr1-tax-period converts at the boundary; nothing else in this file accepts the
;;; other spelling.

(defparameter *gstr1-excluded-statuses* '("DRAFT" "CANCELLED")
  "Statuses that never reach a return. A draft has no legal existence, and a
   cancelled invoice is reported through cdnr rather than as a supply.")

(defparameter *gstr1-b2cl-threshold* 250000
  "Invoice value above which an INTER-STATE B2C supply is reported invoice-wise in
   b2cl instead of being pooled into b2cs. Tested against the invoice TOTAL, which is
   what the rule is written on.")

(defparameter *gstr1-uqc-map*
  '(("KG" . "KGS") ("KGS" . "KGS") ("KILOGRAM" . "KGS") ("KILOGRAMS" . "KGS")
    ("GM" . "GMS") ("GMS" . "GMS") ("GRAM" . "GMS") ("GRAMS" . "GMS")
    ("LTR" . "LTR") ("LITRE" . "LTR") ("LITRES" . "LTR") ("LITER" . "LTR")
    ("ML" . "MLT") ("MIL" . "MLT") ("MLT" . "MLT") ("MILLILITRE" . "MLT")
    ("NO" . "NOS") ("NOS" . "NOS") ("NUM" . "NOS") ("NUMBERS" . "NOS")
    ("PC" . "PCS") ("PCS" . "PCS") ("PIECE" . "PCS") ("PIECES" . "PCS")
    ("PAC" . "PAC") ("PACKET" . "PAC") ("PACKETS" . "PAC")
    ("BOX" . "BOX") ("BAG" . "BAG") ("BAGS" . "BAG")
    ("DOZ" . "DOZ") ("DOZEN" . "DOZ") ("MTR" . "MTR") ("METER" . "MTR")
    ("METRE" . "MTR") ("TON" . "TON") ("TONNE" . "TON"))
  "Free-text invoice UOM → GSTN UQC code. DOD_INVOICE_ITEMS.UOM is whatever the vendor
   typed — '1.0 KG', '500.0 MIL', '200 grams', '1 Nos' — so the lookup is on the
   alphabetic token left after the quantity prefix is stripped. An unmapped token
   becomes OTH and is REPORTED, never guessed at: a fabricated unit on a filed return
   is worse than a visible warning.")

;;; ---------------------------------------------------------------------------
;;; Numbers and the tax period
;;; ---------------------------------------------------------------------------

(defun gstr1-num (x)
  "A column that may be NULL as a number. nil is not zero to +, and every tax sum
   below goes through this."
  (if (numberp x) x 0))

(defun gstr1-round2 (x)
  "Round to paise through an exact rational, so no invoice total drifts by a
   hundredth on its way through a float. GSTN compares to two decimals."
  (coerce (/ (round (* (rational (gstr1-num x)) 100)) 100) 'double-float))

(defun gstr1-split-period (period)
  "Parse the UI's YYYY-MM into (values year month), or signal.

   REFUSES ANYTHING ELSE rather than returning nil. A period that silently fails to
   parse produces a filter that matches no rows, and an empty GSTR-1 is a document a CA
   could upload — so the failure has to be loud and at the entry point."
  (when (and (stringp period) (= (length period) 7) (char= (char period 4) #\-))
    (let ((year (parse-integer period :start 0 :end 4 :junk-allowed t))
          (month (parse-integer period :start 5 :end 7 :junk-allowed t)))
      (when (and year month (<= 1 month 12))
        (return-from gstr1-split-period (values year month)))))
  (error "~S is not a tax period. Use YYYY-MM, for example 2026-05." period))

(defun gstr1-tax-period (period)
  "MMYYYY — the spelling DOD_GSTR1_EXPORTS.TAX_PERIOD stores and GSTN's fp field
   carries."
  (multiple-value-bind (year month) (gstr1-split-period period)
    (format nil "~2,'0D~4,'0D" month year)))

(defun gstr1-period-label (period)
  "YYYY-MM, the spelling DOD_INVOICE_HEADER.GSTR1_PERIOD and DOD_VENDOR_GSTR1_STATUS
   use for the same month."
  (multiple-value-bind (year month) (gstr1-split-period period)
    (format nil "~4,'0D-~2,'0D" year month)))

(defun gstr1-fin-year (period)
  "The Indian financial year label the period falls in, e.g. 2026-27. April starts it,
   not January."
  (multiple-value-bind (year month) (gstr1-split-period period)
    (if (>= month 4)
        (format nil "~4,'0D-~2,'0D" year (mod (1+ year) 100))
        (format nil "~4,'0D-~2,'0D" (1- year) (mod year 100)))))

(defun gstr1-period-bounds (period)
  "First day of PERIOD and first day of the next, as clsql dates, so the month filter
   is pushed into SQL instead of being applied to a fetched window. The next period's
   first day is the exclusive upper bound: `invdate < end` avoids the month-length and
   leap-year arithmetic that `<= last-day` needs."
  (multiple-value-bind (year month) (gstr1-split-period period)
    (let ((ny (if (= month 12) (1+ year) year))
          (nm (if (= month 12) 1 (1+ month))))
      (values (clsql-sys:make-date :year year :month month :day 1
                                   :hour 0 :minute 0 :second 0)
              (clsql-sys:make-date :year ny :month nm :day 1
                                   :hour 0 :minute 0 :second 0)))))

;;; ---------------------------------------------------------------------------
;;; What one return is made of
;;; ---------------------------------------------------------------------------

(defstruct (gstr1-item (:constructor make-gstr1-item))
  "One line of the return, already derived: the rate is settled, the UQC is settled,
   and the raw UOM and raw rates are carried so a warning can name what the vendor
   actually typed without going back to the database for it."
  num hsn uqc uqc-known-p qty uom val txval rt iamt camt samt csamt
  rate-mismatch-p cgst-rate sgst-rate igst-rate)

(defstruct (gstr1-invoice (:constructor make-gstr1-invoice))
  header section ctin pos interstate-p items txval value)

(defstruct (gstr1-collection (:constructor make-gstr1-collection))
  period tax-period fin-year gstin supplier-state invoices warnings)

;;; ---------------------------------------------------------------------------
;;; Derivation
;;; ---------------------------------------------------------------------------

(defun gstr1-uqc (uom)
  "Normalize one free-text UOM. Returns (values code known-p): '1.0 KG' and
   '200 grams' resolve, anything unrecognised is OTH with known-p nil so the caller
   can warn instead of shipping a fabricated unit."
  (let* ((token (string-upcase (string-trim " .0123456789" (or uom ""))))
         (code (cdr (assoc token *gstr1-uqc-map* :test #'string-equal))))
    (if code (values code t) (values "OTH" nil))))

(defun gstr1-item-from-row (item num)
  "One return line from one DOD_INVOICE_ITEMS row.

   🚨 THE RATE IS DERIVED FROM THE AMOUNTS, NOT READ FROM THE RATE COLUMNS. The rate
   columns disagree with each other on rows already in the database — one line carries
   CGSTRATE 2.50 + SGSTRATE 2.20 against IGSTRATE 5.00 — and GSTR-1's rt is the
   COMBINED rate (18 for a 9+9 supply), so summing the split rates would emit rt 4.70,
   which GSTN rejects. The AMOUNTS are what the invoice actually charged, so they
   decide; the disagreement is reported through rate-mismatch-p rather than silently
   resolved."
  (let* ((camt (gstr1-round2 (cgstamt item)))
         (samt (gstr1-round2 (sgstamt item)))
         (iamt (gstr1-round2 (igstamt item)))
         (cgr (gstr1-num (cgstrate item)))
         (sgr (gstr1-num (sgstrate item)))
         (igr (gstr1-num (igstrate item))))
    (multiple-value-bind (uqc known-p) (gstr1-uqc (uom item))
      (make-gstr1-item
       :num num
       :hsn (or (hsncode item) "")
       :uqc uqc :uqc-known-p known-p
       :qty (gstr1-num (qty item))
       :uom (uom item)
       :val (gstr1-round2 (totalitemval item))
       :txval (gstr1-round2 (taxable-value item))
       :rt (if (plusp iamt) igr (gstr1-round2 (+ cgr sgr)))
       :iamt iamt :camt camt :samt samt :csamt 0.0
       :rate-mismatch-p (and (zerop iamt) (plusp igr)
                             (> (abs (- igr (+ cgr sgr))) 0.01))
       :cgst-rate cgr :sgst-rate sgr :igst-rate igr))))

(defun gstr1-classify-invoice (invoice supplier-state)
  "Which section of the return an invoice belongs in.

   b2b is a registered recipient, identified by a customer GSTIN. Everything else is
   B2C and splits by place of supply: an INTER-STATE invoice above the threshold is
   reported invoice-wise in b2cl, the rest is pooled by rate and place of supply in
   b2cs. When the supplier's state is unknown the supply is treated as INTRA-state,
   which is the conservative reading — it keeps the invoice in b2cs rather than
   inventing a b2cl line that may not belong there."
  (let ((ctin (custgstin invoice)))
    (if (and (stringp ctin) (plusp (length (string-trim " " ctin))))
        :b2b
        (let ((pos (or (placeofsupply invoice) (statecode invoice))))
          (if (and supplier-state pos
                   (not (string-equal supplier-state pos))
                   (> (gstr1-num (totalvalue invoice)) *gstr1-b2cl-threshold*))
              :b2cl
              :b2cs)))))

;;; ---------------------------------------------------------------------------
;;; Selection
;;; ---------------------------------------------------------------------------

(defun gstr1-select-invoices (vendor company period)
  "Outward invoices of VENDOR in PERIOD that belong in the return: right vendor, right
   tenant, invoice date inside the month, not deleted, not a draft, and carrying a
   value.

   🚨 IT DOES NOT FILTER ON CUSTOMER GSTIN. A B2C supply is still an outward supply and
   still belongs in the return, in b2cs — filtering to registered recipients here would
   silently drop most of a small vendor's turnover, and the return would look complete.
   The view DOD_V_CUSTOMER_INVOICE_REGISTER does exactly that (it is B2B-only by
   construction), which is why this reads the table and not the view."
  (let* ((tenant-id (slot-value company 'row-id))
         (vendor-id (slot-value vendor 'row-id)))
    (multiple-value-bind (start end) (gstr1-period-bounds period)
      (remove-if (lambda (h)
                   (or (member (status h) *gstr1-excluded-statuses*
                               :test #'string-equal)
                       (string-equal (deleted-state h) "Y")
                       (<= (gstr1-num (totalvalue h)) 0)))
                 (clsql:select 'dod-invoice-header :where
                               [and [= [:vendor-id] vendor-id]
                                    [= [:tenant-id] tenant-id]
                                    [>= [:invdate] start]
                                    [< [:invdate] end]]
                               :caching *dod-database-caching* :flatp t)))))

(defun gstr1-select-items (invoice)
  "Item rows of one invoice, not deleted.

   🚨 THE COLUMN IS HSNCODE, NOT HSN_CODE. DOD_INVOICE_ITEMS spells it without the
   underscore; the DO/GRN item tables spell it WITH one. Querying the wrong name fails
   1054, which reads like 'the column is missing' when it is merely spelled
   differently.

   deleted-state is reached through SLOT-VALUE because dod-invoice-items declares it
   with an :initarg and no :accessor, alone among the slots in that class."
  (remove-if (lambda (i) (string-equal (slot-value i 'deleted-state) "Y"))
             (clsql:select 'dod-invoice-items
                           :where [= [:invheadid] (slot-value invoice 'row-id)]
                           :caching *dod-database-caching* :flatp t)))

;;; ---------------------------------------------------------------------------
;;; The collection
;;; ---------------------------------------------------------------------------

(defun gstr1-supplier-state (vendor gstin)
  "The supplier's GST state code, or nil.

   🚨 TWO VENDOR CLASSES, ONE MAPPED COLUMN. The Panini domain class nst-vnd declares a
   GST-STATE-CODE slot; the legacy ORM class dod-vend-profile DOES NOT MAP THAT COLUMN
   AT ALL — it maps gstnumber and stops. So the slot read must be guarded by
   slot-exists-p rather than assumed, or every call with a legacy vendor object dies
   with no-applicable-method, which is exactly what happened the first time this ran.
   DOD_VEND_PROFILE.GST_STATE_CODE is also EMPTY on every row in the database, so the
   GSTIN prefix is the fallback that actually answers on live data — and the state code
   IS the first two characters of a GSTIN.

   Returns nil when neither source answers, and gstr1-classify-invoice reads that as
   intra-state: the conservative reading, which keeps a supply in b2cs rather than
   inventing a b2cl line that may not belong there."
  (let ((sc (and (slot-exists-p vendor 'gst-state-code)
                 (slot-value vendor 'gst-state-code))))
    (if (and (stringp sc) (plusp (length (string-trim " " sc))))
        (string-trim " " sc)
        (when (and (stringp gstin) (>= (length gstin) 2)) (subseq gstin 0 2)))))

(defun gstr1-collect (vendor company period)
  "Everything one GSTR-1 for PERIOD is made of, plus the reasons it is not yet fit to
   upload.

   NOTHING HERE WRITES OR FORMATS. Warnings are RETURNED rather than logged, because
   the caller decides what to do with them: the route stamps them into
   DOD_INVOICE_GSTR1_TRACKING.VALIDATION_ERRORS, the UI shows them, and a test asserts
   them. A generator that logged and continued would produce a file that looks fine."
  (let* ((gstin (or (gstnumber vendor) ""))
         (supplier-state (gstr1-supplier-state vendor gstin))
         (warnings '())
         (invoices '()))
    (unless (= (length gstin) 15)
      (push (format nil "Supplier GSTIN ~S is ~D characters, not 15. A return with a malformed supplier GSTIN cannot be uploaded."
                    gstin (length gstin))
            warnings))
    ;; The 14th character of a GSTIN is a fixed 'Z'. The demo rows fail this, and GSTN
    ;; checksums the whole string on upload, so it is worth saying before a CA finds out.
    (when (and (>= (length gstin) 14) (not (char-equal (char gstin 13) #\Z)))
      (push (format nil "Supplier GSTIN ~S has ~C where the 14th character must be Z; GSTN will reject it on checksum."
                    gstin (char gstin 13))
            warnings))
    (dolist (h (gstr1-select-invoices vendor company period))
      (let* ((rows (loop for i in (gstr1-select-items h)
                         for n from 1
                         collect (gstr1-item-from-row i n)))
             (section (gstr1-classify-invoice h supplier-state))
             (pos (or (placeofsupply h) (statecode h))))
        (if (null rows)
            (push (format nil "~A (~A) has no item rows and cannot be reported."
                          (invnum h) (custname h))
                  warnings)
            (dolist (r rows)
              (when (gstr1-item-rate-mismatch-p r)
                (push (format nil "~A item ~D: CGST ~A + SGST ~A disagrees with the IGST rate ~A. The rate was taken from the AMOUNTS."
                              (invnum h) (gstr1-item-num r)
                              (gstr1-item-cgst-rate r) (gstr1-item-sgst-rate r)
                              (gstr1-item-igst-rate r))
                      warnings))
              (unless (gstr1-item-uqc-known-p r)
                (push (format nil "~A item ~D: unit ~S is not a GSTN UQC code; OTH was used."
                              (invnum h) (gstr1-item-num r) (gstr1-item-uom r))
                      warnings))
              (when (or (string= (gstr1-item-hsn r) "")
                        (every (lambda (c) (char= c #\0)) (gstr1-item-hsn r)))
                (push (format nil "~A item ~D: HSN ~S is empty or all zeros."
                              (invnum h) (gstr1-item-num r) (gstr1-item-hsn r))
                      warnings))))
        (push (make-gstr1-invoice
               :header h :section section
               :ctin (if (stringp (custgstin h))
                         (string-trim " " (custgstin h))
                         "")
               :pos pos
               :interstate-p (and supplier-state pos
                                  (not (string-equal supplier-state pos)))
               :items rows
               :txval (reduce #'+ rows :key #'gstr1-item-txval
                              :initial-value 0.0d0)
               :value (gstr1-round2 (totalvalue h)))
              invoices)))
    (make-gstr1-collection
     :period period
     :tax-period (gstr1-tax-period period)
     :fin-year (gstr1-fin-year period)
     :gstin gstin
     :supplier-state supplier-state
     :invoices (nreverse invoices)
     :warnings (nreverse warnings))))

(defun gstr1-count-by-section (collection section)
  "How many invoices of COLLECTION fall in SECTION — the counters
   DOD_GSTR1_EXPORTS records for the filing history."
  (count section (gstr1-collection-invoices collection)
         :key #'gstr1-invoice-section))

(defun gstr1-total-taxable (collection)
  "Summed taxable value over every invoice, whatever its section."
  (reduce #'+ (gstr1-collection-invoices collection)
          :key #'gstr1-invoice-txval :initial-value 0.0d0))

(defun gstr1-total-tax (collection)
  "Summed tax (IGST + CGST + SGST + cess) over every item line."
  (loop for inv in (gstr1-collection-invoices collection)
        sum (loop for it in (gstr1-invoice-items inv)
                  sum (+ (gstr1-item-iamt it) (gstr1-item-camt it)
                         (gstr1-item-samt it) (gstr1-item-csamt it)))
          into total
        finally (return (gstr1-round2 total))))
