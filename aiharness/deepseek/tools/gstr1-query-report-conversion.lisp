;;; gstr1-query-report-conversion.lisp
;;;
;;; A Common Lisp port of file_convertion.py from
;;; https://github.com/harshith187/GST/blob/master/file_convertion.py — a small tool
;;; that turns a Tally-style "Query Report" export into a GSTR-1 JSON file.
;;;
;;; WHY THIS PORT IS WORTH KEEPING, GIVEN WE ARE NOT ADOPTING THE TOOL. It is a REAL
;;; GSTR-1 file somebody actually uploaded, so it PINS the field names and the
;;; period/date spellings that hhub/invoice/nst-bl-gstr1.lisp had to derive rather than
;;; invent:
;;;
;;;   { "gstin": …, "fp": "052026", "hash": …, "version": "GST2.2.6",
;;;     "b2b": [ { "ctin": "29ABC…",
;;;                "inv": [ { "inum": "NST00030-2026", "idt": "23-05-2026",
;;;                           "val": 887.0, "pos": "29", "rchrg": "N",
;;;                           "inv_typ": "R",
;;;                           "itms": [ { "num": 1,
;;;                                       "itm_det": { "txval": 752.0, "rt": 18,
;;;                                                    "camt": 67.68, "samt": 67.68,
;;;                                                    "csamt": 0 } } ] } ] } ] }
;;;
;;; CORROBORATED BY THIS SOURCE (it independently agrees with our collector):
;;;   * `fp` is MMYYYY              → gstr1-tax-period
;;;   * `idt` is DD-MM-YYYY         → the date spelling the assembler must emit
;;;   * `rt` is the COMBINED rate   → calc_rate() computes Tax*200/Total, i.e. one
;;;                                    component DOUBLED, so a 9+9 supply is rt 18.
;;;                                    This is exactly why nst-bl-gstr1.lisp derives the
;;;                                    rate from the AMOUNTS and never sums the split
;;;                                    rates.
;;;   * `pos` is the state code ALONE, not "29-Karnataka": the script strips to the
;;;     first two characters on the way in.
;;;
;;; WHAT IT DOES *NOT* PIN — do not mistake a partial file for the schema:
;;;   * it emits ONLY `b2b`. No `b2cs`, `b2cl`, `cdnr`, `hsn`, `doc_issue` or `exp`, so
;;;     it cannot be the model for a complete return;
;;;   * `hash` is the LITERAL STRING "hash". The GST Offline Utility recomputes the
;;;     hash on import, which is presumably why a placeholder passes there — but our
;;;     download goes to a CA and may be read by the portal, so do NOT assume the
;;;     placeholder is accepted beyond the offline tool;
;;;   * `version` is "GST2.2.6", from an offline-tool workbook template
;;;     (GSTR1_Excel_Workbook_Template_V1.5). That token is OLD. It is a LEAD to check,
;;;     not the current requirement.
;;;
;;; ── DELIBERATE DEVIATIONS, each because the original is wrong ───────────────────
;;;
;;;  D1. CSV INPUT INSTEAD OF .XLSX. The original uses openpyxl. This image has no
;;;      Excel reader and cl-csv is already loaded. The original locates every column
;;;      BY HEADER TEXT (get_colunm_index), so that logic is unchanged — export the same
;;;      "Query Report" as CSV and nothing else moves.
;;;  D2. `num` IS THE ITEM INDEX, NOT A CONSTANT. The original writes num['num'] = 1201
;;;      for EVERY item line — a hardcoded constant where GSTN expects items numbered
;;;      from 1 within their invoice.
;;;  D3. `camt`/`samt` ARE COMPUTED, NOT EMPTY STRINGS. The original writes camt: '' and
;;;      samt: '' — empty strings in a numeric field, on a line that also declares
;;;      txval. A return whose tax amounts are blank is not a return; this is the most
;;;      serious defect in the source. They are derived from rt and txval.
;;;  D4. THE ROW SORT USES THE GSTIN, NOT THE CUSTOMER NAME. The original sorts with
;;;      itemgetter(1) — column 2, "Customer Name" — while the grouping loop immediately
;;;      below requires rows sharing a `ctin` to be ADJACENT. Two spellings of one
;;;      customer's name, or two customers sharing a name, silently mis-group invoices
;;;      into the wrong ctin block.
;;;  D5. `<>` BECOMES `/=`. The source is Python 2.
;;;  D6. A ROW WITH NO INVOICE NUMBER IS NOT AN INVOICE, so it is dropped. The source
;;;      copies from row 2 and pastes from row 5, i.e. it treats ROW 2 AS DATA — while
;;;      separately reading the supplier GSTIN out of that same row 2, column 7. Both
;;;      cannot be true of one row unless the GSTIN shares a line with an invoice, and
;;;      when it does not — a metadata row above the data, which is the usual shape of a
;;;      Tally export — the source feeds a blank line into the return. Dropping rows
;;;      whose Invoice cell is empty tolerates either layout and changes no real data.
;;;
;;; Everything else — the header list, the output column positions, the
;;; Place-of-Supply "29-Karnataka" default, the Posting Date → DD-Mon-YYYY transform,
;;; the stale `selected_data` reuse the original relies on, and the HARDCODED input
;;; columns 26/27 for the rate — is ported as it stands, because they define the tool's
;;; behaviour on the files it was written for.
;;;
;;; USAGE (in the running image, where cl-csv and cl-json are loaded):
;;;
;;;   (gstr1-convert:convert-query-report #P"/tmp/query-report.csv")
;;;   (gstr1-convert:convert-query-report #P"/tmp/query-report.csv" :out #P"/tmp/g.json")

(defpackage :gstr1-convert
  (:use :cl)
  (:export #:convert-query-report #:report->rows #:rows->gstr1-json #:sort-rows
           #:*supplier-state* #:*schema-version* #:parse-ddmonyyyy))

(in-package :gstr1-convert)

(defparameter *supplier-state* "29"
  "The supplier's own GST state code, deciding intra- vs inter-state. The original
   hardcodes Karnataka.")

(defparameter *schema-version* "GST2.2.6"
  "The `version` token this port emits, verbatim from the source. OLD — see the header.
   Check against GSTN's current schema before a CA is handed the file.")

(defparameter *query-report-headers*
  '("Customer GSTIN" "Customer Name" "Invoice" "Posting Date" "Grand Total"
    "Place of Supply" "Reverse Charge" "skip" "Invoice Type" "E-Commerce GSTIN"
    "skip_rate" "Net Total")
  "The output column order, copied from the source's `headers` list. THE ORDER IS THE
   CONTRACT: rows->gstr1-json reads the assembled row BY POSITION (0, 2, 3, 4, 5, 6, 8,
   10, 11), so reordering this list silently re-labels the output.

   'skip' and 'skip_rate' are SYNTHETIC output columns. They are NOT looked up in the
   input report — 'skip' consumes a position and is left empty, 'skip_rate' is
   computed. An earlier version of this port looked all twelve up and died on the two
   that cannot exist in a source sheet.")

(defparameter *month-names*
  #("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
  "For the DD-Mon-YYYY spelling strftime('%d-%b-%Y') produces.")

(defparameter *rate-total-column* 26
  "Hardcoded input column for the taxable/total value in calc_rate. A POSITION, not a
   header name — unlike every other column in this tool.")

(defparameter *rate-tax-column* 27
  "Hardcoded input column for the tax value in calc_rate. See above: the input report
   must carry these two columns in these positions or the rate is read from the wrong
   cells, silently.")

;;; ---------------------------------------------------------------------------
;;; Date helpers — the two spellings this format needs
;;; ---------------------------------------------------------------------------

(defun month-index (name)
  "0-11 for a three-letter English month name, case-insensitively, or nil."
  (position name *month-names* :test #'string-equal))

(defun parse-ddmonyyyy (text)
  "\"23-May-2026\" → (values day month year).

   Signals on anything else. A date that silently fails to parse becomes an invoice in
   the wrong period, and `fp` is derived from the FIRST row's date — so one bad cell
   moves the whole return."
  (let* ((trimmed (string-trim '(#\Space #\Tab #\Return #\Newline)
                               (princ-to-string (or text ""))))
         (parts (uiop:split-string trimmed :separator '(#\-))))
    (unless (= (length parts) 3)
      (error "~S is not a DD-Mon-YYYY date." text))
    (destructuring-bind (d m y) parts
      (let ((mon (month-index m)))
        (unless mon
          (error "~S is not a month name in ~S." m text))
        (values (parse-integer d :junk-allowed t)
                (1+ mon)
                (parse-integer y :junk-allowed t))))))

(defun format-ddmonyyyy (day month year)
  (format nil "~2,'0D-~A-~4,'0D" day (aref *month-names* (1- month)) year))

(defun format-ddmmyyyy (day month year)
  "The `idt` spelling: %d-%m-%Y."
  (format nil "~2,'0D-~2,'0D-~4,'0D" day month year))

(defun format-mmyyyy (month year)
  "The `fp` spelling: %m%Y, e.g. 052026."
  (format nil "~2,'0D~4,'0D" month year))

;;; ---------------------------------------------------------------------------
;;; Money and numbers
;;; ---------------------------------------------------------------------------

(defun parse-number (x)
  "CSV gives strings; the source sheet gave numbers. Accept either, and return nil for
   blank, so a missing cell reads as missing rather than as zero."
  (cond ((numberp x) x)
        ((null x) nil)
        (t (let ((s (string-trim " " (princ-to-string x))))
             (when (plusp (length s))
               (or (ignore-errors (read-from-string s))
                   (error "~S is not a number." x)))))))

(defun round-paise (numerator denominator)
  "NUMERATOR/DENOMINATOR rounded to TWO decimals, half away from zero.

   Two decimals, not an integer: the RATE is a whole number (rt 18) while the AMOUNTS
   carry paise (camt 67.68 for 752 at 18%). Rounding the amounts to integers would put
   a return 32 paise out per line.
   CL's `round` rounds to EVEN on a tie, which turns a half-paise into a coin toss on
   a value GSTN sums and compares; hence the explicit half-up."
  (when (and numerator denominator (not (zerop denominator)))
    (let* ((exact (/ (* (rational numerator) 100) (rational denominator)))
           (cents (if (minusp exact)
                      (- (floor (- (+ exact 1/2))))
                      (floor (+ exact 1/2)))))
      (coerce (/ cents 100) 'double-float))))

(defun calc-rate (row)
  "calc_rate: round(Tax * 200 / Total) from the input row's hardcoded columns.

   THE *200 IS THE GIVEAWAY that `rt` is the COMBINED rate: it doubles a single
   component, so a 9+9 supply yields 18 rather than 9. That convention is what
   nst-bl-gstr1.lisp depends on when it derives rt from the amounts.

   🚨 AN UNREADABLE RATE SIGNALS. It does NOT return 0. `rt: 0` in a return means a
   NIL-RATED supply, so defaulting would file a tax-free invoice rather than admit the
   rate was unknown — the same silent-zero class of bug as an ITC dashboard reading 0
   against eligible invoices. The source raises ZeroDivisionError/TypeError here, so
   signalling is also the faithful behaviour; the message just says which cell and why.

   This is not a theoretical guard: the very first fixture run of this port put the
   taxable value one column off, and because the columns are POSITIONS rather than
   header lookups nothing complained — the rate simply came back wrong."
  (let* ((total-cell (nth (1- *rate-total-column*) row))
         (tax-cell (nth (1- *rate-tax-column*) row))
         (total (parse-number total-cell))
         (tax (parse-number tax-cell)))
    (when (or (null total) (zerop total))
      (error "calc-rate: the total/taxable value in column ~D is ~S, so no rate can be computed for this row (invoice ~S). Set *rate-total-column* / *rate-tax-column* if this report puts them elsewhere."
             *rate-total-column* total-cell (row-cell row 3)))
    (when (null tax)
      (error "calc-rate: the tax value in column ~D is ~S, so no rate can be computed for this row (invoice ~S)."
             *rate-tax-column* tax-cell (row-cell row 3)))
    (round (* tax 200) total)))

;;; ---------------------------------------------------------------------------
;;; get_colunm_index / copy_data — the sheet transforms
;;; ---------------------------------------------------------------------------

(defun row-cell (row col)
  "A 1-based cell read, so the column arithmetic below reads like the original."
  (when (and row col (<= 1 col (length row)))
    (nth (1- col) row)))

(defun column-index (header headers)
  "get_colunm_index: the 1-based position of HEADER in the sheet's header row, or nil.
   Lookup is by NAME, which is why D1 (CSV instead of xlsx) changes nothing here."
  (let ((pos (position header headers :test #'string-equal)))
    (and pos (1+ pos))))

(defun copy-column (data col header)
  "copy_data: one input column as a list, with the original's Place-of-Supply default.

   🚨 THE DEFAULT IS '29-Karnataka' WHEN THE CELL IS 29, 0 OR EMPTY — a Karnataka filler
   from the source. It is a worked example, not a rule: send a customer in another state
   and this quietly files them in Karnataka. Ported as it stands, and flagged here so
   nobody discovers it through a notice."
  (mapcar (lambda (row)
            (let ((v (row-cell row col)))
              (if (and (string-equal header "Place of Supply")
                       (or (null v)
                           (member (princ-to-string v) '("29" "0" "") :test #'string=)))
                  "29-Karnataka"
                  v)))
          data))

;;; ---------------------------------------------------------------------------
;;; convert_to_exel
;;; ---------------------------------------------------------------------------

(defun report->rows (input-rows)
  "convert_to_exel: the input report → the assembled rows in *query-report-headers*
   order. Returns (values rows headers).

   THE RATE IS COMPUTED HERE, BEFORE ANY SORTING, and that ordering is load-bearing:
   the source calls convert_to_exel and only then sort_converted_sheet, because the rate
   is looked up from the INPUT row at the same index. Sort first and every rate lands on
   the wrong invoice — which is why calc-rate takes an input row, not an output one."
  (let* ((headers (first input-rows))
         ;; D6: drop rows with no invoice number — a metadata row is not an invoice
         (invoice-col (or (column-index "Invoice" headers)
                          (error "The input report has no Invoice column: ~S" headers)))
         (data (remove-if (lambda (row)
                            (let ((v (row-cell row invoice-col)))
                              (or (null v)
                                  (zerop (length (string-trim " " (princ-to-string v)))))))
                          (rest input-rows)))
         (cols '()))
    (dolist (header *query-report-headers*)
      (cond
        ((string-equal header "skip")
         ;; consumes a column position and holds nothing
         (push (make-list (length data) :initial-element nil) cols))
        ((string-equal header "skip_rate")
         ;; THE RATE COMES FROM THE ROW ITSELF. The source instead recomputes the input
         ;; row number from the output row (`calc_rate(sheet, i-3)`), which works only
         ;; while nothing is filtered and the two row numberings stay three apart. The
         ;; rate columns 26/27 are IN the row, so carrying them with it is the same
         ;; answer with no offset to get wrong — and it survives D6's row drop, which
         ;; would otherwise shift every rate by one.
         (push (mapcar #'calc-rate data) cols))
        (t
         (let ((col (column-index header headers)))
           (unless col
             (error "The input report has no ~S column. Its headers are: ~S"
                    header headers))
           (push (copy-column data col header) cols)))))
    (values (apply #'mapcar #'list (nreverse cols))
            *query-report-headers*)))

;;; ---------------------------------------------------------------------------
;;; sort_converted_sheet — with the sort-key correction (D4)
;;; ---------------------------------------------------------------------------

(defun row-ctin (row) (row-cell row 1))
(defun row-name (row) (row-cell row 2))
(defun row-date (row) (row-cell row 4))
(defun row-kind (row) (row-cell row 9))
(defun row-pos (row) (row-cell row 6))
(defun row-value (row) (row-cell row 5))
(defun row-net (row) (row-cell row 12))
(defun row-rate (row) (row-cell row 11))

(defun sort-rows (rows)
  "sort_converted_sheet, with D4: sorted by the GSTIN column (1), NOT the name (2).

   rows->gstr1-json groups CONSECUTIVE rows sharing a ctin, so ctin adjacency is a
   precondition of correct grouping. The source sorts on the customer NAME, which
   produces that adjacency only when names happen to be unique per GSTIN. A stable sort
   so rows sharing a ctin keep their input order."
  (stable-sort (copy-list rows)
               (lambda (a b)
                 (string< (princ-to-string (or (row-ctin a) ""))
                          (princ-to-string (or (row-ctin b) ""))))))

;;; ---------------------------------------------------------------------------
;;; convert_to_json
;;; ---------------------------------------------------------------------------

(defun row->invoice (row supplier-state)
  "One invoice object: inum, idt, val, pos, rchrg, inv_typ, itms.

   `pos` keeps only the FIRST TWO characters (the source slices [:2]) because the
   assembled column holds '29-Karnataka'. `inv_typ` keeps the first character: the GSTN
   enum is R / SEZ / DE / … and sending the whole label is rejected."
  (multiple-value-bind (d m y) (parse-ddmonyyyy (row-date row))
    (let* ((txval (parse-number (row-net row)))
           (rt (parse-number (row-rate row)))
           (raw-pos (row-pos row))
           (pos (if (stringp raw-pos)
                    (subseq raw-pos 0 (min 2 (length raw-pos)))
                    raw-pos))
           (intra (and pos (string= pos supplier-state)))
           (base (or txval 0))
           (rate (or rt 0))
           ;; D3: the source leaves these blank. Intra-state: half the combined rate on
           ;; each of CGST and SGST. Inter-state: the whole rate on IGST.
           (camt (if intra (round-paise (* base rate) 200) 0.0d0))
           (samt (if intra (round-paise (* base rate) 200) 0.0d0))
           (iamt (if intra 0.0d0 (round-paise (* base rate) 100)))
           (raw-kind (row-kind row)))
      (list (cons "inum" (row-cell row 3))
            (cons "idt" (format-ddmmyyyy d m y))
            (cons "val" (parse-number (row-value row)))
            (cons "pos" pos)
            (cons "rchrg" (row-cell row 7))
            (cons "inv_typ" (if (stringp raw-kind)
                                (subseq raw-kind 0 1)
                                raw-kind))
            (cons "itms"
                  (vector
                   (list (cons "num" 1)          ; D2: indexed, not the constant 1201
                         (cons "itm_det"
                               (list (cons "txval" txval)
                                     (cons "rt" rt)
                                     (cons "iamt" iamt)
                                     (cons "camt" camt)
                                     (cons "samt" samt)
                                     (cons "csamt" 0.0d0))))))))))

(defun rows->gstr1-json (rows gstin &key (supplier-state *supplier-state*))
  "convert_to_json: the assembled rows → the GSTR-1 document as an ORDERED alist.

   Ordered, not a hash table: the source builds an OrderedDict and field order is what a
   human reading the file expects. cl-json encodes an alist in order.

   ARRAYS ARE VECTORS, and that is not a style choice. cl-json treats a LISP LIST whose
   every element is a cons as an ALIST — as an object — so a list of invoice objects is
   read as an object whose keys are those objects. A VECTOR is unambiguously an array.
   This is the single most likely way to produce plausible-looking, wrong JSON here."
  (when (null rows)
    (error "No rows to convert."))
  (multiple-value-bind (d m y) (parse-ddmonyyyy (row-date (first rows)))
    (declare (ignore d))
    (let ((b2b '())
          (remaining rows))
      ;; group CONSECUTIVE rows sharing a ctin — the reason the sort key matters
      (loop while remaining
            for ctin = (row-ctin (first remaining))
            for group = (loop while (and remaining
                                         (string= (princ-to-string (or (row-ctin (first remaining)) ""))
                                                  (princ-to-string (or ctin ""))))
                              collect (pop remaining))
            do (push (list (cons "ctin" ctin)
                           (cons "inv" (coerce (mapcar (lambda (r)
                                                         (row->invoice r supplier-state))
                                                       group)
                                               'vector)))
                     b2b))
      (list (cons "gstin" gstin)
            (cons "fp" (format-mmyyyy m y))
            (cons "hash" "hash")             ; literal, as in the source — see header
            (cons "version" *schema-version*)
            (cons "b2b" (coerce (nreverse b2b) 'vector))))))

;;; ---------------------------------------------------------------------------
;;; Entry point
;;; ---------------------------------------------------------------------------

(defun convert-query-report (input-path &key out gstin (supplier-state *supplier-state*))
  "INPUT-PATH (a Query Report exported as CSV) → the GSTR-1 JSON text. Writes it to OUT
   when given, and always returns the text.

   The GSTIN is read from the source sheet's cell (row 2, column 7) in the original;
   here it is passed in, because that coordinate is a property of one workbook layout
   rather than of the format."
  (let* ((rows (cl-csv:read-csv input-path))
         (gstin (or gstin
                    (row-cell (second rows) 7)
                    (error "Row 2 column 7 of ~A does not hold the GSTIN; pass :GSTIN." input-path)))
         (sorted (sort-rows (report->rows rows)))
         (json (json:encode-json-to-string
                (rows->gstr1-json sorted gstin :supplier-state supplier-state))))
    (when out
      (with-open-file (s out :direction :output :if-exists :supersede
                             :external-format :utf-8)
        (write-string json s)))
    json))
