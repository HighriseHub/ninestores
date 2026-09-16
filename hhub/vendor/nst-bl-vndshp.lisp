;;; nst-bl-vndshp.lisp — Tier-1 प्रत्यय for nst-vnd-shp (vendor shipping config)
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; 🚨 NOT YET COMPILED, NOT YET RUN. Wired into nstores.asd and
;;; package/compile.lisp. Per this project's standing rule — with its two
;;; recorded proofs, a copier that compiled with ten warnings and would have
;;; failed on the first fetch, and a helper named `safe` that executes arbitrary
;;; code — compile-time success is NOT evidence. Call the प्रत्यय before trusting
;;; any of this.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; WHAT THIS ENTITY IS, IN BUSINESS TERMS
;;;
;;; A vendor says two things about shipping:
;;;
;;;   1. WHICH ZONES IT WILL SHIP TO. A zone is a named set of Indian pincode
;;;      PREFIXES — not pincodes. "ZONE-A = 56,57,58,59" means Karnataka, because
;;;      every pincode beginning 56–59 is in Karnataka in the Postal Index Number
;;;      system. The prefixes come from the India Post directory
;;;      (DOD_INDIA_PINCODES, 19,586 live rows), and the prefix→region table the
;;;      vendor thinks in is *VNDSHP-PIN-PREFIX-REGIONS* below.
;;;
;;;   2. WHAT EACH ZONE COSTS, BY WEIGHT. A CSV price matrix whose COLUMN HEADERS
;;;      ARE ZONE NAMES:
;;;
;;;          MIN,MAX,ZONE-A,ZONE-B,ZONE-C,ZONE-D,ZONE-E
;;;          0.5,1,40,80,150,170,0
;;;          1,2,80,120,200,220,0
;;;
;;; So "zonewise shipping" is ONE configuration expressed in TWO tables, which is
;;; why nst-vnd-shp is ONE entity over both: the matrix header can only be checked
;;; against the zone rows, and the two are meaningless apart.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; THE PLUMBING THIS FILE MUST RESPECT — read off the live code, not assumed
;;;
;;; UPLOAD (legacy UI, vendor/dod-ui-ven.lisp:1971-2065):
;;;   * the page shows the vendor's stored RATETABLECSV if tablerateshipenabled is
;;;     "Y", and otherwise the platform master file
;;;     ($HHUBRESOURCESDIR/defaultshipratetable.csv, = /data/www/public/img/…,
;;;     whose repo copy is site/public/csv/defaultshipratetable.csv);
;;;   * the vendor may download that sample, edit it, and upload BOTH files;
;;;   * the controller writes RATETABLECSV verbatim into DOD_SHIPPING_METHODS and
;;;     one DOD_VENDOR_SHIP_ZONES row per CSV line, where the line's FIRST cell is
;;;     the zone name and the REST are prefixes, stored as
;;;         (format nil "~A" (cdr zoneinfo))   →   "(56 57 58 59)"
;;;     a PRINTED LISP LIST. That is why ZIPCODERANGECSV is read back with
;;;     read-from-string at the checkout, and why this file's parser reproduces
;;;     that exact printed form — see VNDSHP-ZONES-TO-STORAGE-STRING.
;;;
;;; CHECKOUT (customer/dod-ui-cus.lisp:2874-2950, shipping/dod-bl-osh.lisp:11-173):
;;;   * method selection is `(and (equal <flag> "Y") (equal defaultshippingmethod
;;;     "<CODE>"))` — BOTH, or no paid shipping is charged at all;
;;;   * the zone is resolved by matching the customer's pincode against each zone's
;;;     prefixes as the regex "^<prefix>", taking the FIRST zone that matches;
;;;   * the price is then the matrix cell for that zone name in the row whose
;;;     MIN/MAX band contains the cart weight;
;;;   * weights below 0.5 kg signal nst-shipping-error before any of that.
;;;
;;; FIVE WAYS THE LIVE PIPELINE BREAKS, all of which this file refuses at write
;;; time instead of letting the checkout pay for them. Each is recorded at the
;;; function that owns it, and together they are the reason this entity has more
;;; law in it than a settings table usually would:
;;;
;;;   L1  the matrix is malformed — an empty price cell throws inside `float` at
;;;       the checkout (live row 6 of DOD_SHIPPING_METHODS has three of them).
;;;   L2  the matrix headers and the zone rows disagree — the zone resolves, the
;;;       matrix has no such column, the `cond` falls through to NIL and the cart
;;;       is charged nothing, silently.
;;;   L3  no weight band covers the cart — get-shipping-rate-from-table returns
;;;       NIL, and the caller does `(> shipping-cost 0.0)` on it: a TYPE ERROR at
;;;       the checkout, not a fallback price.
;;;   L4  two zones claim the same prefix. The live master file already does this:
;;;       ZONE-B and ZONE-C both claim 30. The rows come back with NO ORDER BY, so
;;;       which rate applies is decided by the query planner.
;;;   L5  the default method and its enable flag disagree — no paid shipping at
;;;       all, i.e. free delivery, which is the expensive direction to be wrong in.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; 🚨 BLOCKER 1 TOUCHES THIS FILE DIRECTLY
;;;
;;; shipping/dod-bl-osh.lisp:74-80 reads the seven RATETABLECSV cells with
;;; read-from-string and the DEFAULT *read-eval* of T, so a CSV cell containing
;;; `#.(...)` EXECUTES when a customer checks out. Seven calls, still open
;;; (STATUS.md BLOCKER 1). This file WRITES that column — see the header of
;;; nst-dal-vndshp.lisp. Everything this file parses binds *read-eval* to NIL
;;; first AND validates the token against a digits-only pattern, so the reader is
;;; never handed attacker-chosen syntax here. That is a guard on OUR path only; it
;;; does not repair the checkout's.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; FIVE VERBS, AND ONE DELIBERATE ABSENCE
;;;
;;;   ?exists   (प्रत्यभिज्ञा) — implemented because `make` REQUIRES it (adhara's
;;;                              make contract). Supporting law, not an endpoint.
;;;   make      (सृजन)     — create the vendor's shipping configuration, once.
;;;   fetch     (स्मरण)    — recall it, zones included.
;;;   !update   (!state)   — change the configuration and/or replace the zones.
;;;   enumerate (दर्शन)    — the tenant's shipping configurations.
;;;
;;;   delete!   — ABSENT ON PURPOSE. "This vendor does not ship" is expressed IN
;;;               BAND: active_flag "N", or defaultshippingmethod nil so no method
;;;               is selected. A soft-deleted row would occupy the singleton slot
;;;               while नियम-2 makes it invisible to every verb, so the vendor
;;;               could never configure shipping again. Leaving delete! undefined
;;;               makes that state unreachable through this surface; it remains
;;;               reachable out of band (the legacy UI, raw SQL), which is a data
;;;               anomaly ?exists reports as :C and make refuses with 409.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; 🚨 THE SINGLETON IS A DOMAIN LAW, NOT A SCHEMA FACT
;;;
;;; DOD_SHIPPING_METHODS has only a PRIMARY KEY on ROW_ID plus plain NON-UNIQUE
;;; indexes. Nothing stops a second row for the same vendor, and the legacy reader
;;; takes the FIRST row with NO ORDER BY (dod-bl-osh.lisp:11-19) — so a duplicate
;;; would not raise, it would silently change the price the next customer is
;;; charged, and WHICH price would depend on the planner. ?exists and make's
;;; :around are the only guard. The shipping twin is worse than the payment twin,
;;; whose legacy reader at least orders by ROW_ID DESC.
;;;
;;; ═══════════════════════════════════════════════════════════════════════════
;;; KNOWN GAPS, recorded rather than hidden
;;;
;;; 1. NO TRANSACTION. A write touches one config row and N zone rows and this
;;;    tree has no transaction macro — `clsql:with-transaction` is never used
;;;    anywhere in it, so introducing one here would be an unverified dependency
;;;    on the connection's autocommit state. The writes are therefore ORDERED for
;;;    the least harmful partial state: for !update the ZONES land first and the
;;;    matrix last, so an interrupted write leaves the matrix pointing at zones
;;;    that already exist rather than at zones that do not. A proper transaction
;;;    belongs here and is the first thing to add after the verbs have been run.
;;;
;;; 2. THE 4xx TAXONOMY GAP (CONTEXT §7.2) applies to every law below: they signal
;;;    a condition, which currently reaches the API as a 500 where 400 is right.
;;;    Same wart as the profile's required-field guard and the vpm twin's
;;;    vpm-field-rejected.
;;;
;;; 3. NO vendor-id FROM THE SESSION. Every verb reads vendor-id from its argument
;;;    — the intra-tenant BOLA that domain-ctx's `actor` slot exists to close
;;;    (CONTEXT §12.3 decision 3). Recorded, not mistaken for a decision.
;;;
;;; 4. shipping_enabled LIVES ON THE VENDOR ROW. The legacy controller writes it
;;;    (dod-ui-ven.lisp:2082) alongside the shipping config, and the checkout
;;;    requires it before ANY paid shipping is considered. This file does NOT
;;;    write another entity's row: saving a shipping configuration and enabling
;;;    shipping on the vendor are two writes, and the route layer owns pairing
;;;    them.
;;; ═══════════════════════════════════════════════════════════════════════════

(in-package :nstores)

(clsql:file-enable-sql-reader-syntax)


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 1 — The condition
;;; ═══════════════════════════════════════════════════════════════════════════

(define-condition vndshp-field-rejected (error)
  ((field :initarg :field :reader vndshp-field-rejected-field)
   (why   :initarg :why   :reader vndshp-field-rejected-why))
  (:report (lambda (condition stream)
             (format stream "nst-vnd-shp: field ~A was rejected — ~A. This is a malformed request, not an unknown outcome; it must not be reported as 503."
                     (vndshp-field-rejected-field condition)
                     (vndshp-field-rejected-why condition))))
  (:documentation
   "Raised when a caller supplies something this entity cannot accept, for any of
    five distinct reasons — the :WHY string names which:

      1. a REQUIRED field is absent            (make: :vendor-id)
      2. a NON-EDITABLE field was supplied     (!update: :vendor-id, the parent)
      3. the shipping method and its enable flag disagree          (L5)
      4. the rate table is malformed, or the stored column caps are exceeded (L1)
      5. the rate table and the zone rows disagree, or two zones claim the same
         pincode prefix                                          (L2, L3, L4)

    WHY A NEW CONDITION RATHER THAN vendor-required-field-missing. That one is
    nst-vnd's, its report string says so, and its name asserts 'missing' — false
    for four of the five reasons above. Reusing it would put a vendor-profile word
    on a shipping failure. Same reasoning as vpm-field-rejected, and the same
    4xx-taxonomy wart applies (file header, gap 2)."))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 2 — The shipping-method vocabulary, and the pincode prefix table
;;;
;;; The four method codes are not invented here: they are the live
;;; defaultshippingmethod values (dod-ui-ven.lisp:2085-2121) and the checkout's
;;; own cond keys (dod-ui-cus.lisp:2905-2930).
;;; ═══════════════════════════════════════════════════════════════════════════

(defparameter *vndshp-method->enable-slot*
  '(("FSH" . freeshipenabled)     ; Free Shipping
    ("FRS" . flatrateshipenabled) ; Flat Rate Shipping
    ("TRS" . tablerateshipenabled); Zonewise Shipping  ← the one `zones` belongs to
    ("EXS" . extshipenabled))     ; External Shipping Partners
  "defaultshippingmethod code → the column that must be \"Y\" for it to be live.

   THE COUPLING IS THE CHECKOUT'S, NOT A PREFERENCE. Method selection is
   `(and (equal <flag> \"Y\") (equal defaultshippingmethod \"<code>\"))`, so a
   default method whose flag is off selects NOTHING and the cart is charged 0.00 —
   free delivery, silently. L5 refuses that combination at write time.

   STOREPICKUPENABLED IS DELIBERATELY ABSENT. It is the fifth flag on the row but
   it is NOT a value of defaultshippingmethod: pickup is an option offered
   alongside a method, not a method, which is why the checkout pushes it as a
   separate shipping option before evaluating any of the four above.")

(defun vndshp-method-code (value)
  "Normalises a caller's method value to the 3-character code the column holds.
   Accepts a string in any case, or a keyword (:TRS). Returns NIL for NIL, and
   signals for anything else — a filter or a default method that cannot be read is
   refused rather than dropped, because silently ignoring a caller's constraint is
   how a filter comes to mean the opposite of itself (nst-bl-apidefs2-CONTEXT
   §9.6)."
  (cond ((null value) nil)
        ((keywordp value) (vndshp-method-code (symbol-name value)))
        ((symbolp value)  (vndshp-method-code (symbol-name value)))
        ((stringp value)
         (let ((code (string-upcase (string-trim " " value))))
           (if (assoc code *vndshp-method->enable-slot* :test #'string=)
               code
               (error 'vndshp-field-rejected
                      :field :defaultshippingmethod
                      :why (format nil "~S is not a shipping method code — expected one of ~A (free, flat rate, zonewise, external partner)"
                                   value (mapcar #'car *vndshp-method->enable-slot*))))))
        (t (error 'vndshp-field-rejected
                  :field :defaultshippingmethod
                  :why (format nil "~S cannot be read as a shipping method code" value)))))

(defparameter *vndshp-pin-prefix-regions*
  '(("11" "11" "DL" "Delhi")
    ("12" "13" "HR" "Haryana")
    ("14" "15" "PB" "Punjab")
    ("16" "16" "CH" "Chandigarh")
    ("17" "17" "HP" "Himachal Pradesh")
    ("18" "19" "JK, LA" "Jammu and Kashmir, Ladakh")
    ("20" "28" "UP, UK" "Uttar Pradesh, Uttarakhand")
    ("30" "34" "RJ" "Rajasthan")
    ("36" "39" "GJ" "Gujarat")
    ("396" "396" "DD" "Dadra and Nagar Haveli and Daman and Diu")
    ("40" "44" "MH" "Maharashtra")
    ("403" "403" "GA" "Goa")
    ("45" "48" "MP" "Madhya Pradesh")
    ("49" "49" "CG" "Chhattisgarh")
    ("50" "50" "TG" "Telangana")
    ("51" "53" "AP" "Andhra Pradesh")
    ("56" "59" "KA" "Karnataka")
    ("60" "66" "TN" "Tamil Nadu")
    ("605" "605" "PY" "Puducherry")
    ("67" "69" "KL" "Kerala")
    ("682" "682" "LD" "Lakshadweep")
    ("70" "74" "WB" "West Bengal")
    ("737" "737" "SK" "Sikkim")
    ("744" "744" "AN" "Andaman and Nicobar Islands")
    ("75" "77" "OD" "Odisha")
    ("78" "78" "AS" "Assam")
    ("790" "792" "AR" "Arunachal Pradesh")
    ("793" "794" "ML" "Meghalaya")
    ("795" "795" "MN" "Manipur")
    ("796" "796" "MZ" "Mizoram")
    ("797" "798" "NL" "Nagaland")
    ("799" "799" "TR" "Tripura")
    ("80" "85" "BR, JH" "Bihar, Jharkhand")
    ("90" "99" "APS" "Army Postal Service"))
  "The Postal Index Number prefix → region table, as (FIRST LAST CODE REGION).

   ORDER IS LOAD-BEARING: the three-digit exceptions are listed BEFORE the
   two-digit ranges they carve out of, and lookup takes the first range that
   contains the prefix, so 396 resolves to Dadra/Daman rather than to Gujarat's
   36–39, 403 to Goa rather than Maharashtra's 40–44, 605 to Puducherry rather
   than Tamil Nadu's 60–66, 682 to Lakshadweep rather than Kerala's 67–69, 737 to
   Sikkim rather than West Bengal's 70–74, and 744 to the Andamans rather than
   West Bengal.

   THIS IS REFERENCE DATA FOR REPORTING AND SANITY-CHECKING, NOT A VALIDATOR. It
   is not used to refuse a write: the prefixes a vendor actually ships to come out
   of the India Post directory (DOD_INDIA_PINCODES), and the live master file
   already carries the sentinel prefix 0 — used by ZONE-E as a catch-all that
   matches no real pincode — which no region table would accept. Refusing on this
   table would break a convention the live data depends on. It is published
   instead, so a client can show a vendor 'ZONE-A covers Karnataka'.")

(defun vndshp-digit-prefix (digits)
  "The leading digits of a prefix, as an integer, longest-first search key.
   Returns a list of candidate keys: (\"605\") → (605 60 6), so a lookup can try
   the exact 3-digit exception before the 2-digit range."
  (loop for len from (length digits) downto 1
        collect (parse-integer digits :end len)))

(defun vndshp-regions-for-prefix (prefix)
  "The region entries a pincode PREFIX falls in, as a list of (CODE . REGION).

   Usually one. A ONE- OR TWO-DIGIT prefix can be ambiguous — \"3\" spans
   Rajasthan, Gujarat and Dadra/Daman — and the honest answer is all of them,
   because the prefix alone does not decide. An exact 3-digit prefix resolves by
   the exception rows first.

   Purely descriptive: used to annotate a zone on the wire and to let a client
   explain a zone to the vendor. Never used to refuse a write — see
   *VNDSHP-PIN-PREFIX-REGIONS*."
  (when (and (stringp prefix)
             (plusp (length prefix))
             (every #'digit-char-p prefix))
    (let ((keys (vndshp-digit-prefix prefix)))
      (loop for (first last code region) in *vndshp-pin-prefix-regions*
            for lo = (parse-integer first)
            for hi = (parse-integer last)
            ;; An entry applies when ANY candidate key of the prefix lies inside
            ;; its range — but only the SHORTEST applicable entry per key, which
            ;; the ordered table already guarantees for the 3-digit exceptions.
            when (some (lambda (k) (<= lo k hi)) keys)
              collect (cons code region)))))

(defun vndshp-zones-region-codes (prefixes)
  "The distinct region codes covered by a list of prefixes, order preserved."
  (remove-duplicates
   (loop for p in prefixes
         append (mapcar #'car (vndshp-regions-for-prefix p)))
   :from-end t))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 3 — The two CSV formats, and the storage form of a zone
;;;
;;; Both parsers read what the legacy upload path reads, with the same
;;; cl-csv:read-csv call, so a file that worked in the UI works here.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun vndshp-trim (text)
  "Whitespace, on both ends, including the CR a CSV written on Windows carries.
   Every cell comparison in this file goes through it: a trailing \\r in \"ZONE-E\\r\"
   would otherwise make a rate-table header and a zone row that name the same zone
   compare unequal, and the mismatch would be reported as a vendor error rather
   than as the encoding artefact it is.

   THE NON-BREAKING SPACE IS BUILT WITH CODE-CHAR, not written as #\\Nbsp: SBCL
   does not recognise that character name — it is a READER error, so the whole FILE
   fails to load, not just this call. (Found by reading the file with the reader
   before compiling it; a paren-balance check would not have seen it.) It is in the
   list because a prefix list pasted out of a spreadsheet or a web page is the way
   a zone file actually arrives, and NBSP is what such a paste carries."
  (if (stringp text)
      (string-trim (list #\Space #\Tab #\Return #\Newline (code-char 160)) text)
      text))

(defparameter *vndshp-numeric-cell-pattern* "^[+-]?[0-9]+(\\.[0-9]+)?$"
  "The ONLY shape a rate-table cell may have before the Lisp reader is allowed
   near it.

   WHY A REGEX IN FRONT OF THE READER, given the file is the vendor's own upload.
   Because `#.(…)` in a CSV cell is executed by the checkout's seven unguarded
   read-from-string calls (BLOCKER 1), and this parser is the gate that decides
   what a rate table may contain. Two independent guards are applied: the token
   must match this pattern, AND *read-eval* is bound to NIL around the read. Either
   alone would do; both together mean a future relaxation of one is caught by the
   other.")

(defun vndshp-numeric-cell (token &key (field :ratetablecsv) (where "rate table"))
  "TOKEN as a number, or a refusal naming the cell. NIL and the empty string are
   refused rather than read as 0 — an empty cell in the live row 6 of
   DOD_SHIPPING_METHODS is exactly the defect that throws inside `float` at the
   checkout (L1)."
  (let ((cell (vndshp-trim token)))
    (when (or (null cell) (zerop (length cell)))
      (error 'vndshp-field-rejected
             :field field
             :why (format nil "an empty cell in the ~A. A stored empty price cannot be charged: the checkout calls float on it and throws, so the whole vendor's zonewise shipping stops working. Give the cell a number, or give the zone a rate of 0." where)))
    (unless (cl-ppcre:scan *vndshp-numeric-cell-pattern* cell)
      (error 'vndshp-field-rejected
             :field field
             :why (format nil "~S in the ~A is not a number. Only digits with an optional decimal point are accepted — the same guard that keeps a Lisp reader form out of a column the checkout reads back." cell where)))
    (let ((*read-eval* nil))
      (read-from-string cell))))

(defun vndshp-parse-rate-table (csv)
  "Parses the MIN,MAX,ZONE-…,ZONE-… matrix.

   Returns (VALUES ZONE-NAMES BANDS) where ZONE-NAMES is the header minus its two
   leading columns, and BANDS is a list of (MIN MAX . (ZONE . PRICE)…).

   Refuses, with the reason, on: an empty table; a header that does not begin
   MIN,MAX; fewer than one zone column; a non-numeric or empty cell; MIN >= MAX;
   bands that are out of order; and gaps between consecutive bands.

   THE GAP CHECK IS NOT PEDANTRY. get-shipping-rate-from-table returns NIL when no
   band contains the cart weight, and its caller immediately computes
   `(> shipping-cost 0.0)` on that NIL — a TYPE ERROR on the checkout page, not a
   fallback price (L3). Contiguous bands from the first MIN are the only shape that
   cannot produce it, so that is the shape accepted."
  (let* ((rows (and csv (plusp (length (vndshp-trim csv)))
                    (cl-csv:read-csv csv)))
         (header (mapcar #'vndshp-trim (first rows)))
         (body (rest rows)))
    (unless header
      (error 'vndshp-field-rejected :field :ratetablecsv
             :why "the rate table is empty — a MIN,MAX header row and at least one weight band are required"))
    (unless (and (>= (length header) 3)
                 (string-equal (first header) "MIN")
                 (string-equal (second header) "MAX"))
      (error 'vndshp-field-rejected :field :ratetablecsv
             :why (format nil "the rate table's first row must begin MIN,MAX and then one column per zone — got ~S" (first rows))))
    (let ((zone-names (cddr header)))
      (when (some (lambda (z) (zerop (length z))) zone-names)
        (error 'vndshp-field-rejected :field :ratetablecsv
               :why (format nil "the rate table header has an unnamed zone column — every column after MIN,MAX must be a zone name. Got ~S" header)))
      (unless body
        (error 'vndshp-field-rejected :field :ratetablecsv
               :why "the rate table has a header but no weight bands"))
      (let ((bands '()) (previous-max nil))
        (loop for row in body
              for rownum from 2
              do (let* ((min (vndshp-numeric-cell (first row) :where (format nil "rate table row ~D" rownum)))
                        (max (vndshp-numeric-cell (second row) :where (format nil "rate table row ~D" rownum))))
                   (unless (< min max)
                     (error 'vndshp-field-rejected :field :ratetablecsv
                            :why (format nil "rate table row ~D has MIN ~A not less than MAX ~A" rownum min max)))
                   (when (and previous-max (/= (float min) (float previous-max)))
                     (error 'vndshp-field-rejected :field :ratetablecsv
                            :why (format nil "rate table row ~D starts at ~A but the previous band ended at ~A. A weight falling in that gap makes the checkout throw instead of charging, so the bands must be contiguous."
                                         rownum min previous-max)))
                   (setf previous-max max)
                   (push (cons min (cons max
                                         (loop for zone in zone-names
                                               for cell in (cddr row)
                                               collect (cons zone
                                                             (vndshp-numeric-cell
                                                              cell
                                                              :where (format nil "rate table row ~D, zone ~A" rownum zone))))))
                         bands)))
        (setf bands (nreverse bands))
        (let ((lowest (first (first bands))))
          (when (> (float lowest) 0.5)
            (error 'vndshp-field-rejected :field :ratetablecsv
                   :why (format nil "the lightest band starts at ~A kg, but the checkout refuses any cart under 0.5 kg before it ever looks at the table. The first band must start at 0.5 or below." lowest))))
        (values zone-names bands)))))

(defun vndshp-parse-zone-csv (csv)
  "Parses a ZONE,PINCODES… file into a list of (ZONENAME . PREFIX-LIST).

   The first cell of each line is the zone name and every remaining cell is a
   pincode PREFIX — the shape the legacy upload writes and the default master file
   ships (site/public/csv/defaultshipzonepincodes.csv):

       ZONE,PINCODES
       ZONE-A,56,57,58,59
       ZONE-B,30,31,… 682

   ROBUSTER THAN THE LEGACY PATH IN ONE RESPECT, recorded because it is a
   divergence: the legacy reader passes :skip-first-p T unconditionally, dropping
   whatever the first line was. This parser skips the first line only when it
   looks like a header (its first cell case-insensitively equals \"ZONE\"), so a
   file that omits the header is not silently short one zone."
  (let* ((rows (and csv (plusp (length (vndshp-trim csv)))
                    (cl-csv:read-csv csv)))
         (data (if (and (first rows)
                        (string-equal (vndshp-trim (first (first rows))) "ZONE"))
                   (rest rows)
                   rows)))
    (unless data
      (error 'vndshp-field-rejected :field :zones
             :why "the zone file is empty — one line per zone, each ZONENAME followed by its pincode prefixes, is required"))
    (loop for line in data
          for rownum from 1
          for name = (vndshp-trim (or (first line) ""))
          when (zerop (length name))
            do (error 'vndshp-field-rejected :field :zones
                      :why (format nil "zone line ~D has no zone name" rownum))
          collect (cons name
                        (let ((prefixes (remove-if (lambda (p) (zerop (length p)))
                                                   (mapcar #'vndshp-trim (rest line)))))
                          ;; 🚨 A ZONE WITH NO PREFIXES IS ALLOWED, AND THAT IS A
                          ;; CORRECTION RATHER THAN AN OVERSIGHT. This refused it —
                          ;; "a zone that covers nothing can never be charged" — and
                          ;; the refusal was wrong twice over:
                          ;;   * the PLATFORM ALREADY STORES IT. Live vendor 19 has
                          ;;     ZONE-E = `()`, and the master zone file on this host
                          ;;     (defaultshipzonepincodes.csv, /data/www/public/img)
                          ;;     ships `ZONE-E,` with nothing after it. A vendor who
                          ;;     fetched that configuration and PUT it back would be
                          ;;     refused by the very API that published it.
                          ;;   * an EMPTY PREFIX LIST is not the same as NO ZONES. The
                          ;;     configuration still has a ZONE-E row, and the vendor's
                          ;;     rate table still prices it (the live master table has
                          ;;     a ZONE-E column). The matrix↔zone law is what keeps
                          ;;     the pair coherent; whether a zone's prefix list is
                          ;;     populated yet is the vendor's business.
                          ;; The data-losing case — a payload with NO ZONES AT ALL — is
                          ;; still refused, one layer up, by vndshp-zone-args.
                          prefixes)))))

(defun vndshp-split-prefixes (text)
  "A prefix list given inline (\"56,57,58,59\" or \"56 57 58 59\") as a list of
   strings. Commas and whitespace both separate; an already-parsed Lisp list, as
   read back from ZIPCODERANGECSV, is returned normalised."
  (cond ((null text) nil)
        ((listp text) (mapcar (lambda (p) (string-trim " " (princ-to-string p))) text))
        ((stringp text)
         (let ((trimmed (string-trim " " text)))
           ;; The stored form is a PRINTED LISP LIST — "(56 57 58 59)" — so the
           ;; read-back path hands this function the string of a list, not a CSV.
           ;; It is parsed with the same two guards as everywhere else.
           (if (and (plusp (length trimmed)) (char= (char trimmed 0) #\())
               (let ((*read-eval* nil))
                 (let ((parsed (handler-case (read-from-string trimmed)
                                 (error () nil))))
                   (if (listp parsed)
                       (mapcar (lambda (p) (string-trim " " (princ-to-string p))) parsed)
                       (error 'vndshp-field-rejected :field :zones
                              :why (format nil "~S looks like a stored prefix list but does not read back as one" text)))))
               (remove-if (lambda (p) (zerop (length p)))
                          (cl-ppcre:split "[,\\s]+" trimmed)))))
        (t (error 'vndshp-field-rejected :field :zones
                  :why (format nil "~S cannot be read as a list of pincode prefixes" text)))))

(defun vndshp-zones-to-storage-string (prefixes)
  "A prefix list in THE EXACT FORM THE LEGACY WRITER PRODUCES, so a row written
   here is read by the legacy checkout unchanged:

       (format nil \"~A\" '(\"56\" \"57\"))   →   \"(56 57)\"

   🚨 THE FORMAT IS A CONTRACT, NOT A PREFERENCE. shipping/dod-bl-osh.lisp reads
   this column with read-from-string, and dod-ui-ven.lisp wrote it with ~A on the
   list of cells cl-csv handed back. Change the printer here — to JSON, to CSV, to
   a \"~S\" — and every stored zone still reads, but every zone written AFTER the
   change does not, and the failure appears at a customer's checkout, not here."
  (format nil "~A" (mapcar #'princ-to-string prefixes)))

(defun vndshp-zones-from-storage-string (stored)
  "The stored ZIPCODERANGECSV back as a list of prefix strings.

   BINDS *read-eval* TO NIL. This is the guard commit 5ba1f70 added to the
   checkout's copy of this read and it is mandatory here too: the column is
   vendor-writable text, and the default reader evaluates `#.`."
  (when (and (stringp stored) (plusp (length (string-trim " " stored))))
    (let ((*read-eval* nil))
      (let ((parsed (handler-case (read-from-string stored)
                      (error () nil))))
        (cond ((null parsed) nil)
              ((listp parsed) (mapcar (lambda (p) (string-trim " " (princ-to-string p))) parsed))
              ;; A bare token — "56" without parentheses — is not the writer's
              ;; format but is unambiguous, and reading it as one prefix is
              ;; strictly better than dropping a zone the checkout still matches.
              (t (list (princ-to-string parsed))))))))

(defun vndshp-prefix-string-p (prefix)
  "True when PREFIX can be stored in ZIPCODERANGECSV AND used by the checkout.

   🚨 IT IS NOT A DIGITS-ONLY RULE, AND THAT IS A CORRECTION. This was written as
   \"1 to 6 digits\" from the Indian PIN system — and the PLATFORM'S OWN LIVE DATA
   REJECTS IT. DOD_VENDOR_SHIP_ZONES holds regex fragments, not digit prefixes:
   vendor 19's ZONE-A is `(577* 560001 560002 …)`, and the CONTEXT §12.2 warning
   said so in 2026-09-14: the stored tokens are regex fragments, each used as
   (format nil \"^~A\" token) by get-zonename-from-pincode. A digits-only law would
   refuse a vendor RE-UPLOADING the zones they already have.

   So the rule is the one the MECHANISM actually imposes, which is narrower and
   more honest than a guess about pincodes: the token must survive
     * the STORAGE round-trip — ZIPCODERANGECSV is a PRINTED LISP LIST
       ((format nil \"~A\" tokens)) read back with read-from-string, so a token
       containing whitespace, a parenthesis or a quote would come back as a
       different list; and
     * the REGEX construction — \"^~A\" with a token that is empty would match
       everything and silently claim every pincode in the country.
   Everything else is the vendor's business, including `577*` and the sentinel
   `0` the live ZONE-E rows carry."
  (and (stringp prefix)
       (plusp (length prefix))
       (not (find-if (lambda (c) (find c " \t\r\n()\"'`,;")) prefix))))

(defun vndshp-parse-zones-initarg (value)
  "A caller's :ZONES value, normalised into a list of ship-zone structs.

   FOUR ACCEPTED SHAPES, because the vendor's real upload is a file and the API's
   real caller is a JSON body, and forcing one into the other's shape would put
   the translation in the client:

     1. THE WHOLE ZONE CSV as a string  — \"ZONE,PINCODES\\nZONE-A,56,57…\" —
        exactly the file the legacy page accepts;
     2. a PLIST per zone  ((:zonename \"ZONE-A\" :pincodes \"56,57,58,59\") …) —
        the JSON object apidefs2 hands over, whose keys it has already normalised
        to :ZONE-NAME / :PINCODES;
     3. a LIST or dotted CONS per zone  ((\"ZONE-A\" \"56\" \"57\") …) or
        ((\"ZONE-A\" . \"56,57\") …) — the cl-csv row shape and the short form;
     4. a list of ship-zone structs, already normalised.

   Returns a LIST OF SHIP-ZONE STRUCTS whose ZIPCODERANGECSV is the STORAGE
   string — what the column will hold — never the caller's spelling."
  (let ((pairs
         (cond
           ((null value) '())
           ((ship-zone-p value)
            (list (cons (ship-zone-zonename value) (ship-zone-zipcoderangecsv value))))
           ((stringp value)
            ;; A whole CSV file, or a single inline prefix list? The legacy upload
            ;; always sends a file, and a file's first line is a zone name followed
            ;; by prefixes — so a string with two or more CSV rows is a file.
            (let ((rows (cl-csv:read-csv value)))
              (if (and rows (> (length rows) 1))
                  (vndshp-parse-zone-csv value)
                  (error 'vndshp-field-rejected :field :zones
                         :why "a single string was supplied as :zones — send the whole zone CSV file (ZONE,PINCODES then one line per zone), or a list of (:zonename … :pincodes …) entries"))))
           ((listp value)
            (loop for entry in value
                  collect (cond
                            ((ship-zone-p entry)
                             (cons (ship-zone-zonename entry) (ship-zone-zipcoderangecsv entry)))
                            ;; 🚨 TWO SHAPES ARRIVE AS A CONS, AND THEY MUST BE TOLD
                            ;; APART BY THE KEY, not by convenience. This was written as
                            ;; one branch that read (car entry) as the name and
                            ;; (getf (cdr entry) :pincodes) as the prefixes, and that
                            ;; branch was wrong for BOTH shapes a real client sends:
                            ;;   * the JSON/transport PLIST — (:zonename "ZONE-A"
                            ;;     :pincodes "56,57") — put :ZONENAME into the name slot,
                            ;;     so the zone was stored as literally "ZONENAME";
                            ;;   * a dotted CONS with a STRING cdr — ("ZONE-A" .
                            ;;     "56,57") — made (getf "56,57" :pincodes) a TYPE
                            ;;     ERROR, because getf was handed a string.
                            ;; Only the cl-csv ROW form ("ZONE-A" "56" "57") worked,
                            ;; by accident, through the (cdr entry) fallback. Found by
                            ;; writing the smoke suite against the documented contract —
                            ;; the structural checks this file passed could not see it.
                            ((consp entry)
                             (cond
                               ;; 🚨 ALIST — WHAT A NESTED JSON OBJECT ACTUALLY
                               ;; ARRIVES AS, and the shape this branch was missing.
                               ;; apidefs2 turns the TOP-LEVEL JSON object into a
                               ;; plist (nst-bl-apidefs2.lisp:287) but leaves NESTED
                               ;; objects as the DECODED ALIST, so a client posting
                               ;;   [{"zoneName":"ZONE-A","pincodes":"11,12"}]
                               ;; hands over  ((:ZONE-NAME . "ZONE-A") (:PINCODES . "11,12")).
                               ;; Without this branch the entry fell through to the
                               ;; cons/row case below and was stored as a zone NAMED
                               ;; "(ZONE-NAME . ZONE-A)" with the alist as its prefix
                               ;; list — which L2 then refused, so the create answered
                               ;; 500 and nothing was written. Found by the smoke
                               ;; suite's --write run, with the frame in
                               ;; ninestores-apilogs.log naming the garbage verbatim.
                               ((and (consp (car entry)) (keywordp (caar entry)))
                                (cons (vndshp-trim (or (cdr (assoc :zone-name entry))
                                                       (cdr (assoc :zonename entry))
                                                       (cdr (assoc :name entry))
                                                       ""))
                                      (or (cdr (assoc :pincodes entry))
                                          (cdr (assoc :zipcoderangecsv entry))
                                          (cdr (assoc :zipcoderange-csv entry))
                                          (cdr (assoc :zone-pincodes entry))
                                          (cdr (assoc :pincode-prefixes entry)))))
                               ;; PLIST — the same keys, from a caller that is not
                               ;; apidefs2 (a REPL call, or an adapter that does not
                               ;; alist-ify). Keys may be :ZONENAME or :ZONE-NAME,
                               ;; because "zoneName" normalises to the latter.
                               ((keywordp (car entry))
                                (cons (vndshp-trim (or (getf entry :zonename)
                                                       (getf entry :zone-name)
                                                       (getf entry :name)
                                                       ""))
                                      (or (getf entry :pincodes)
                                          (getf entry :zipcoderangecsv)
                                          (getf entry :zipcoderange-csv)
                                          (getf entry :zone-pincodes)
                                          (getf entry :pincode-prefixes))))
                               ;; CONS or CSV ROW — ("ZONE-A" . "56,57") or
                               ;; ("ZONE-A" "56" "57"). The cdr may be a STRING, so it is
                               ;; only asked for a keyword when it is a list.
                               (t
                                (cons (vndshp-trim (princ-to-string (car entry)))
                                      (let ((rest (cdr entry)))
                                        (if (and (consp rest) (keywordp (car rest)))
                                            (or (getf rest :pincodes)
                                                (getf rest :zipcoderangecsv)
                                                (getf rest :zone-pincodes))
                                            rest))))))
                            (t (error 'vndshp-field-rejected :field :zones
                                      :why (format nil "~S is not a zone entry — expected (:zonename \"ZONE-A\" :pincodes \"56,57\") or (\"ZONE-A\" . \"56,57\")" entry))))))
           (t (error 'vndshp-field-rejected :field :zones
                     :why (format nil "~S cannot be read as a zone list" value))))))
    (loop for (name . prefixes) in pairs
          for clean = (vndshp-trim (princ-to-string name))
          for prefix-list = (vndshp-split-prefixes prefixes)
          do (when (zerop (length clean))
               (error 'vndshp-field-rejected :field :zones :why "a zone entry has no zone name"))
          collect (make-ship-zone nil clean (vndshp-zones-to-storage-string prefix-list)))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 4 — Copiers
;;;
;;; The view-classes are the LEGACY ones in shipping/dod-dal-osh.lisp, the same
;;; choice nst-vnd made with dod-vend-profile and nst-vnd-vpm with
;;; dod-vpayment-methods: they are on the live checkout path, and editing working
;;; code is not what this file is for.
;;;
;;; TWO DEFECTS IN THOSE CLASSES ARE INHERITED RATHER THAN FIXED, recorded so a
;;; reader does not go looking for the bug here:
;;;   * BOTH classes declare a join slot with accessor ODT-VENDOROBJECT, so the
;;;     second definition merges a method into the first's generic function. The
;;;     copiers never touch it (:db-kind :join, :set nil — read-only);
;;;   * BOTH declare their COMPANY join with accessor PRODUCT-COMPANY, a name
;;;     borrowed from the products layer. Also untouched here, for the same reason.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun vndshp-float-or-nil (value)
  "VALUE as a FLOAT, or NIL.

   🚨 NOT COSMETIC — WITHOUT THIS, A WHOLE-DECIMAL PRICE JSON CANNOT BE SENT.
   dod-shipping-methods declares MINORDERAMT and FLATRATEPRICE as `:type float`,
   and CLSQL enforces it on the way out:

     NST-DB-UPDATE-ERROR (unexpected): Invalid value 99 in slot FLATRATEPRICE,
     not of type FLOAT.               ← ninestores-busfunctions.log, 2026-09-16

   A client PUT `{\"flatrateprice\": 99}` — an ORDINARY JSON number, and JSON has
   no integer/float distinction to make it wrong — and the write raised inside
   with-nst-db-update, whose catch-all turned it into :U. The client was told
   **503, 'the database call did not answer'**, for a price of ninety-nine.

   The coercion belongs HERE, in the copier, because this is the one place that
   knows the DESTINATION's declared types: the domain entity deliberately puts no
   numeric type on those slots (a money field is a number, however it is spelled).

   The live legacy writer never hit this because it always passes a float —
   `(float (read …))` in dod-controller-vendor-update-flatrate-shipping-action.
   An API has no such luxury: it is handed whatever JSON carried."
  (when value (float value)))

(defun copyVndShp-domaintodb (source destination)
  "nst-vnd-shp → dod-shipping-methods. THE CONFIG ROW ONLY — see the note on
   zones at the end.

   TENANT_ID comes from the company OBJECT and DELETED_STATE is forced to \"N\",
   both mirroring copyVendor-domaintodb decisions 1-2: the tenant is never a field
   a caller sets, and a row written here is by definition not deleted.

   ACTIVE_FLAG IS CARRIED, not forced. It is the column the legacy readers filter
   on, so a vendor that wants to stop shipping sets it to \"N\" through !update and
   must be able to — forcing \"Y\" here would make deactivation impossible."
  (let ((company (slot-value source 'company)))
    (with-slots (name freeshipenabled flatrateshipenabled tablerateshipenabled
                 extshipenabled storepickupenabled minorderamt flatratetype
                 flatrateprice ratetablecsv defaultshippingmethod
                 shippartnerkey shippartnersecret vendor-id active-flag
                 deleted-state tenant-id)
        destination
      (setf name                  (slot-value source 'shp-name))
      (setf freeshipenabled       (slot-value source 'freeshipenabled))
      (setf flatrateshipenabled   (slot-value source 'flatrateshipenabled))
      (setf tablerateshipenabled  (slot-value source 'tablerateshipenabled))
      (setf extshipenabled        (slot-value source 'extshipenabled))
      (setf storepickupenabled    (slot-value source 'storepickupenabled))
      (setf minorderamt           (vndshp-float-or-nil (slot-value source 'minorderamt)))
      (setf flatratetype          (slot-value source 'flatratetype))
      (setf flatrateprice         (vndshp-float-or-nil (slot-value source 'flatrateprice)))
      (setf ratetablecsv          (slot-value source 'ratetablecsv))
      (setf defaultshippingmethod (slot-value source 'defaultshippingmethod))
      ;; THE SECRETS CROSS HERE, because the INSERT needs them and this is the
      ;; only outbound leg in the file. They are kept off the wire by the RESPONSE
      ;; MODEL, not by hiding them from the domain.
      (setf shippartnerkey        (slot-value source 'shippartnerkey))
      (setf shippartnersecret     (slot-value source 'shippartnersecret))
      (setf vendor-id             (slot-value source 'vendor-id))
      (setf active-flag           (slot-value source 'active-flag))
      ;; INVARIANTS — not copied from the source. See the docstring.
      (setf deleted-state "N")
      (setf tenant-id (slot-value company 'row-id))
      ;; 🚨 THE `zones` SLOT IS NOT WRITTEN HERE, AND MUST NOT BE. There is no
      ;; zones column on DOD_SHIPPING_METHODS: the zone rows live in their own
      ;; table and are written one at a time by vndshp-write-zones, against the
      ;; row-id this INSERT produces. A :db-kind :list slot added here to "make
      ;; the copier symmetric" would write a column that does not exist.
      destination)))

(defun copyVndShp-dbtodomain (source destination)
  "dod-shipping-methods → nst-vnd-shp. The inbound direction.

   VENDOR-ID, TENANT-ID, COMPANY AND THE ZONES ARE NOT COPIED:
     * the caller sets vendor-id, because it is the argument that selected this
       row, and copying it from the row would let a stale row re-point the entity
       at a different vendor;
     * tenant-id and company are attached from domain-ctx, for the reason nst-vnd
       gives: the tenant is a कारक, not a field;
     * the zones are a second table and the caller hydrates them separately, so
       that one function can decide whether to read live rows (fetch) or all rows
       (the write path that must revive a soft-deleted zone name).

   DELETED_STATE IS NOT COPIED EITHER: the entity's inherited slot carries \"N\",
   every selector here filters deleted rows, and copying a \"Y\" in would make
   नियम-2 refuse the very write the caller is about to make."
  (with-slots (shp-name freeshipenabled flatrateshipenabled tablerateshipenabled
               extshipenabled storepickupenabled minorderamt flatratetype
               flatrateprice ratetablecsv defaultshippingmethod
               shippartnerkey shippartnersecret active-flag)
      destination
    (setf shp-name              (slot-value source 'name))
    (setf freeshipenabled       (slot-value source 'freeshipenabled))
    (setf flatrateshipenabled   (slot-value source 'flatrateshipenabled))
    (setf tablerateshipenabled  (slot-value source 'tablerateshipenabled))
    (setf extshipenabled        (slot-value source 'extshipenabled))
    (setf storepickupenabled    (slot-value source 'storepickupenabled))
    (setf minorderamt           (slot-value source 'minorderamt))
    (setf flatratetype          (slot-value source 'flatratetype))
    (setf flatrateprice         (slot-value source 'flatrateprice))
    (setf ratetablecsv          (slot-value source 'ratetablecsv))
    (setf defaultshippingmethod (slot-value source 'defaultshippingmethod))
    (setf shippartnerkey        (slot-value source 'shippartnerkey))
    (setf shippartnersecret     (slot-value source 'shippartnersecret))
    (setf active-flag           (slot-value source 'active-flag))
    destination))

(defun copyShipZone-dbtodomain (source)
  "One dod-vendor-ship-zones row → one ship-zone VALUE STRUCT.

   VENDOR-ID, TENANT-ID AND DELETED_STATE ARE DELIBERATELY NOT CARRIED: the parent
   is the entity the zone list hangs off, the tenant is the entity's कारक, and a
   row that reaches here has been selected as live — carrying a flag that is always
   the same value would be a field with one legal value.

   ROW-ID IS CARRIED, and that is load-bearing on the WRITE path: re-saving a zone
   whose name already exists updates that row in place, and an entity hydrated
   without the row-id could only INSERT a second row with the same zone name."
  (make-ship-zone (slot-value source 'row-id)
                  (slot-value source 'zonename)
                  (slot-value source 'zipcoderangecsv)))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 5 — Selectors, hydration, and the zone writes
;;; ═══════════════════════════════════════════════════════════════════════════

(defun vndshp-vendor-id-from-string (value)
  "The INTEGER vendor-id, or NIL when VALUE cannot address a vendor at all.
   Vendor-ids arrive as strings across the API and as integers from internal
   callers; anything else is NIL, which callers turn into a :F 'cannot address a
   row' answer rather than a 500. Same rule as vpm-vendor-id-from-string."
  (cond ((integerp value) value)
        ((stringp value)
         (handler-case (parse-integer value :junk-allowed nil)
           (error () nil)))
        (t nil)))

(defun select-shipping-method-by-vendor-in-tenant (vendor-id tenant-id &key include-deleted)
  "The singleton lookup, keyed on (VENDOR_ID, TENANT_ID).

   🚨 ORDER BY ROW_ID ASC, which the legacy reader does NOT have
   (get-shipping-method-for-vendor, dod-bl-osh.lisp:11-19, ends in a bare
   `(car (clsql:select …))`). Read this as a TIE-BREAKER THAT THIS FILE ADDS,
   not as a fix to the checkout: the checkout still calls the legacy selector and
   still gets whichever row the planner returns first. What the ordering buys is
   that THIS entity always agrees with itself about which row it is editing, so a
   duplicate cannot make fetch and !update disagree. The real fix is that ?exists
   and make prevent the duplicate at all.

   :INCLUDE-DELETED T is what makes the soft-deleted case DETECTABLE — a row the
   domain considers gone still occupies the singleton slot, because DELETED_STATE
   is in no key. That is the :C in ?exists.

   Returns ONE ROW OR NIL: the CAR is taken here, not by the caller, because
   with-db-call hands its payload straight to ?exists, which reads a SLOT off it."
  (car (if include-deleted
           (clsql:select 'dod-shipping-methods
                         :where [and [= [:vendor-id] vendor-id]
                                     [= [:tenant-id] tenant-id]]
                         :order-by '(([row-id] :asc))
                         :caching *dod-database-caching* :flatp t)
           (clsql:select 'dod-shipping-methods
                         :where [and [= [:deleted-state] "N"]
                                     [= [:active-flag] "Y"]
                                     [= [:vendor-id] vendor-id]
                                     [= [:tenant-id] tenant-id]]
                         :order-by '(([row-id] :asc))
                         :caching *dod-database-caching* :flatp t))))

(defun select-ship-zone-rows-for-vendors (vendor-ids tenant-id &key include-deleted)
  "Every zone row of EVERY listed vendor, in one query.

   WHY BATCHED RATHER THAN PER-VENDOR. enumerate returns configurations, and a
   per-row zone query would be N+1 round trips for a page of N vendors. One
   `[in …]` query, grouped in Lisp afterwards, keeps the list endpoint at two
   queries regardless of page size.

   ACTIVE_FLAG='Y' IS REQUIRED unless :INCLUDE-DELETED — the live readers require
   both (dod-bl-osh.lisp:110-115), so a row this entity hydrates is a row the
   checkout can see. With :INCLUDE-DELETED the row is returned whatever its state,
   which is what the WRITE path needs: a zone name that was soft-deleted and is
   now being re-supplied must be REVIVED rather than duplicated.

   ORDER BY ROW_ID — the checkout takes the FIRST zone whose prefix matches the
   customer's pincode and there is no ORDER BY in the legacy selector either, so
   ordering cannot fix an overlap; it only makes this entity's own answer stable.
   The overlap itself is refused at write time (L4)."
  (when vendor-ids
    (if include-deleted
        (clsql:select 'dod-vendor-ship-zones
                      :where [and [in [:vendor-id] vendor-ids]
                                  [= [:tenant-id] tenant-id]]
                      :order-by '(([row-id] :asc))
                      :caching *dod-database-caching* :flatp t)
        (clsql:select 'dod-vendor-ship-zones
                      :where [and [= [:deleted-state] "N"]
                                  [= [:active-flag] "Y"]
                                  [in [:vendor-id] vendor-ids]
                                  [= [:tenant-id] tenant-id]]
                      :order-by '(([row-id] :asc))
                      :caching *dod-database-caching* :flatp t))))

(defun vndshp-zone-rows (vendor-ids tenant-id &key include-deleted)
  "select-ship-zone-rows-for-vendors behind the Belnap boundary, returning a
   bo-knowledge WHOSE PAYLOAD IS ALWAYS A LIST.

   with-db-call maps an empty result to :F with a NIL payload, and here an empty
   zone list is an ordinary fact — most shipping methods have no zones at all. So
   :F is rewritten to :T with '(), and only a real :U survives as unknown. The
   distinction matters: a vendor with no zones is not a database failure."
  (let ((knowledge (with-db-call (select-ship-zone-rows-for-vendors
                                  vendor-ids tenant-id :include-deleted include-deleted)
                                 "nst-vnd-shp zones (vendor-ids, tenant)")))
    (if (eq (bo-knowledge-truth knowledge) :F)
        (make-instance 'bo-knowledge :truth :t :payload '()
                       :provenance "nst-vnd-shp zones: no zone rows for these vendors — an empty collection, not a failure")
        knowledge)))

(defun vndshp-zones-by-vendor (rows)
  "The flat zone-row list grouped by VENDOR_ID, as an alist of
   (VENDOR-ID . SHIP-ZONE-STRUCTS). Used by enumerate so one query can fill every
   configuration on the page."
  (let ((table (make-hash-table :test 'eql)))
    (dolist (row rows)
      (push (copyShipZone-dbtodomain row)
            (gethash (slot-value row 'vendor-id) table)))
    (loop for k being the hash-keys of table using (hash-value v)
          collect (cons k (nreverse v)))))

(defun vndshp-hydrate (dbobj zones vendor-id company)
  "dod-shipping-methods (+ its zone rows) → a fully-attached nst-vnd-shp.

   The four things the copier deliberately does NOT set are set HERE, in one
   place, so fetch, !update and enumerate cannot disagree about them: row-id (the
   row's own primary key), vendor-id (the parent link), tenant-id (from the
   company object's row-id) and company itself.

   🚨 ROW-ID IS LOAD-BEARING. copyVndShp-dbtodomain copies only the business
   columns, and domain->response reads row-id on the way out — omitting it makes a
   fetch of an EXISTING row raise UNBOUND-SLOT inside domain->response and answer
   500 while a fetch of an ABSENT row is a clean 404. That is exactly the failure
   the payment twin shipped with (nst-bl-vndvpm.lisp, vpm-hydrate), reproduced
   from its warning rather than from its bug."
  (let ((entity (make-instance 'nst-vnd-shp
                               :vendor-id vendor-id
                               :tenant-id (slot-value company 'row-id))))
    (setf (row-id entity) (slot-value dbobj 'row-id))
    (setf (company entity) company)
    (copyVndShp-dbtodomain dbobj entity)
    (setf (zones entity) (mapcar #'copyShipZone-dbtodomain zones))
    entity))

(defun vndshp-write-zones (vendor-id tenant-id zones existing-rows)
  "Upsert ZONES into DOD_VENDOR_SHIP_ZONES and soft-delete the rows that are no
   longer named.

   Returns (VALUES ROWS-WRITTEN FAILURE), where FAILURE is the bo-knowledge of the
   first write that did not report success, or NIL when every write succeeded.

   WHY THE FAILURE IS RETURNED RATHER THAN SIGNALLED, and why it is not swallowed
   either. The config row may already have been written by the caller, so the
   honest outcome of a zone failure is not 'nothing happened' — an error would be
   wrong, and silence would be worse: make would return a configuration that looks
   created while its zones are missing, which is precisely the state the checkout
   prices at 0.00. The caller turns this into a contradiction sentinel naming what
   was and was not written.

   UPSERT BY ZONENAME, AND THE MATCH IS CASE-SENSITIVE. The checkout picks the
   price with `(cond ((equal zonename \"ZONE-A\") …))` — string equality in a
   `cond` — so \"zone-a\" in the zone table and \"ZONE-A\" in the matrix header are
   two different zones, one of which is unpriceable. Case-sensitivity here is the
   checkout's rule, not a choice.

   REVIVAL RATHER THAN DUPLICATION. The match is made against rows in ANY state
   (the caller passes the :include-deleted rows), so re-supplying a previously
   removed zone name updates its old row back to live instead of inserting a
   second row with the same name — which nothing in the schema forbids, and which
   would leave two rows whose prefixes the checkout matches in planner order.

   REMOVAL IS A SOFT DELETE, never a physical one: नियम-2's semantics hold
   throughout this tree, and both legacy readers filter deleted rows out, so the
   effect at the checkout is the intended one — the zone stops matching.

   🚨 ORDERING, NOT A TRANSACTION. There is no transaction macro in this tree (file
   header, gap 1), so a failure midway leaves some zones written. Callers order
   this call BEFORE the config row (see !update) so an interrupted write leaves a
   matrix whose columns still have zone rows, rather than zone rows no matrix
   prices."
  (let ((written 0)
        (failure nil)
        (wanted (mapcar (lambda (z) (ship-zone-zonename z)) zones)))
    (dolist (zone zones)
      (let* ((name (ship-zone-zonename zone))
             (row (find name existing-rows
                        :key (lambda (r) (slot-value r 'zonename))
                        :test #'string=)))
        (let ((knowledge
               (if row
                   (progn
                     (setf (slot-value row 'zipcoderangecsv) (ship-zone-zipcoderangecsv zone))
                     (setf (slot-value row 'active-flag) "Y")
                     (setf (slot-value row 'deleted-state) "N")
                     (setf (ship-zone-row-id zone) (slot-value row 'row-id))
                     (with-nst-db-update (:source "nst-vnd-shp/zone-upsert")
                       (clsql:update-records-from-instance row)
                       row))
                   (let ((new (make-instance 'dod-vendor-ship-zones
                                             :vendor-id vendor-id
                                             :tenant-id tenant-id
                                             :zonename name
                                             :zipcoderangecsv (ship-zone-zipcoderangecsv zone)
                                             :active-flag "Y"
                                             :deleted-state "N")))
                     (prog1 (with-nst-db-create (:source "nst-vnd-shp/zone-insert")
                              (clsql:update-records-from-instance new)
                              new)
                       ;; Read the generated key back whatever the truth was: a
                       ;; failure leaves it NIL, which the struct carries honestly.
                       (when (slot-value new 'row-id)
                         (setf (ship-zone-row-id zone) (slot-value new 'row-id))))))))
          (unless (eq (bo-knowledge-truth knowledge) :t)
            (unless failure (setf failure knowledge)))))
      (incf written))
    ;; Rows whose name is no longer supplied are retired, not deleted.
    (dolist (row existing-rows)
      (unless (member (slot-value row 'zonename) wanted :test #'string=)
        ;; `equal` rather than `string=`: the view-class maps a NULL to :void-value
        ;; "N", but a row written outside this tree could still hand back NIL, and a
        ;; type error here would abort a write that has nothing to do with it.
        (unless (equal (slot-value row 'deleted-state) "Y")
          (setf (slot-value row 'deleted-state) "Y")
          (let ((knowledge (with-nst-db-delete (:source "nst-vnd-shp/zone-retire")
                             (clsql:update-record-from-slot row 'deleted-state)
                             row)))
            (unless (eq (bo-knowledge-truth knowledge) :t)
              (unless failure (setf failure knowledge)))))))
    (values written failure)))

(defun vndshp-apply-flag-defaults (entity)
  "Every method flag the caller left NIL becomes \"N\".

   The DDL default for all five is NULL, and the legacy view-class declares no
   :void-value for them, so a NULL reads back as NIL and every legacy reader treats
   that as OFF. \"N\" is that same meaning written down — see DECISION 1 of
   nst-dal-vndshp.lisp. Only NIL is replaced; \"N\" is a value, not an absence, and
   survives untouched."
  (dolist (slot '(freeshipenabled flatrateshipenabled tablerateshipenabled
                  extshipenabled storepickupenabled))
    (unless (slot-value entity slot)
      (setf (slot-value entity slot) "N")))
  (unless (slot-value entity 'active-flag)
    (setf (slot-value entity 'active-flag) "Y"))
  ;; flatratetype is the ONE column here with a real DDL default.
  (unless (slot-value entity 'flatratetype)
    (setf (slot-value entity 'flatratetype) "ORD"))
  entity)


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 6 — THE LAWS
;;;
;;; Five checks that run on every write, all of them derived from what the live
;;; checkout does with these two columns rather than from taste. They are gathered
;;; here, and called from one function per write path, so make and !update cannot
;;; drift apart on what a valid configuration is — the failure mode where the
;;; create path is strict and the edit path is not is exactly how the live table
;;; acquired its overlapping zones.
;; ═══════════════════════════════════════════════════════════════════════════

(defun vndshp-enabled-methods (entity)
  "The method codes whose enable flag is \"Y\" on ENTITY."
  (loop for (code . slot) in *vndshp-method->enable-slot*
        when (equal (string-upcase (or (slot-value entity slot) "N")) "Y")
          collect code))

(defun vndshp-check-default-method (entity)
  "L5 — the default method and its enable flag must agree.

   A configuration with NO default method is legal and stays legal: row 5 of the
   live table has none. What is refused is the contradictory pair, because the
   checkout asks for BOTH and a half-set pair silently charges nothing:

     default = TRS but tablerateshipenabled = N   →  free delivery, silently
     tablerateshipenabled = Y but default = FRS   →  the table is never consulted

   The second is only REPORTED as a mismatch when the vendor asked for the table
   to be the default; a vendor may legitimately keep a table on file while
   defaulting to flat rate. So the law is one-directional: every code that IS the
   default must have its flag on. The reverse — a flag on with another default — is
   not refused, because the checkout already ignores it."
  (let ((code (vndshp-method-code (slot-value entity 'defaultshippingmethod))))
    (when code
      (let ((slot (cdr (assoc code *vndshp-method->enable-slot* :test #'string=))))
        (unless (equal (string-upcase (or (slot-value entity slot) "N")) "Y")
          (error 'vndshp-field-rejected
                 :field :defaultshippingmethod
                 :why (format nil "the default shipping method is ~A but ~A is not \"Y\". The checkout selects a method only when BOTH the code matches AND its flag is on, so this configuration charges the customer NOTHING at all — free delivery by accident. Enable the method you default to, or choose a method you have enabled."
                              code slot)))))
    ;; The code is normalised only when present; storing it upper-cased keeps the
    ;; column comparable with the checkout's (equal …) tests.
    (when code (setf (slot-value entity 'defaultshippingmethod) code))
    entity))

(defun vndshp-check-zone-prefixes (zones)
  "L4 — no two zones may claim the same pincode prefix, and every prefix must be
   digits.

   THE OVERLAP IS NOT HYPOTHETICAL. The live master file
   (site/public/csv/defaultshipzonepincodes.csv) already claims prefix 30 in BOTH
   ZONE-B and ZONE-C, and both vendors that carry zones carry that file's copy.
   get-zonename-from-pincode takes the FIRST zone whose regex matches and the rows
   come back unordered, so for a Rajasthan pincode starting 30 the rate charged
   today depends on which row the planner happened to return. This law stops the
   API from writing more of it.

   A whole 6-digit pincode that CONTAINS a shorter prefix is not flagged: \"560001\"
   and \"56\" do not collide as strings, and the checkout's regex makes the longer
   one win by being tested in row order — which is the ambiguity this law cannot
   reach and the reason the check is documented as a partial one."
  (let ((seen (make-hash-table :test 'equal)))
    (dolist (zone zones)
      (let ((name (ship-zone-zonename zone)))
        (dolist (prefix (vndshp-zones-from-storage-string (ship-zone-zipcoderangecsv zone)))
          (unless (vndshp-prefix-string-p prefix)
            (error 'vndshp-field-rejected
                   :field :zones
                   :why (format nil "zone ~A claims ~S as a pincode prefix. A prefix is 1 to 6 digits — the leading digits of a PIN, like 56 for Karnataka-wide or 560001 for one office. Anything else is never matched by the checkout's match on \"^~A\"."
                                name prefix prefix)))
          (let ((other (gethash prefix seen)))
            (when (and other (not (string= other name)))
              (error 'vndshp-field-rejected
                     :field :zones
                     :why (format nil "prefix ~A is claimed by both ~A and ~A. The checkout takes the first zone whose prefix matches the customer's pincode, and the zone rows come back with no ORDER BY — so which rate applies would depend on the query planner. Give each prefix to exactly one zone. (The platform's own default zone file has this defect for prefix 30, between ZONE-B and ZONE-C; it is fixed by the vendor editing and re-uploading the file.)"
                                  prefix other name)))
          (setf (gethash prefix seen) name)))))
  zones))

(defun vndshp-check-zone-columns (zone-names zones)
  "L2 — the matrix header and the zone rows must name the SAME zones.

   Checked in BOTH directions, because both directions lose money:
     * a column with no zone row  — the matrix prices a zone no pincode can reach;
     * a zone row with no column  — the zone resolves, the header has no such
       column, the `cond` at dod-bl-osh.lisp:82-86 falls through to NIL, that row
       is removed from the list, and the cart is charged NOTHING, with no error
       anywhere in the log.
   The second is the silent one and the reason this check is not optional."
  (let* ((stored (mapcar #'ship-zone-zonename zones))
         (missing-row (remove-if (lambda (z) (member z stored :test #'string=)) zone-names))
         (missing-col (remove-if (lambda (z) (member z zone-names :test #'string=)) stored)))
    (when missing-row
      (error 'vndshp-field-rejected
             :field :ratetablecsv
             :why (format nil "the rate table has column(s) ~{~A~^, ~} that no zone row covers. The goods would be priced for a zone that no pincode can resolve to, so a customer in it is charged 0 while the vendor believes the zone is priced."
                          missing-row)))
    (when missing-col
      (error 'vndshp-field-rejected
             :field :zones
             :why (format nil "zone(s) ~{~A~^, ~} have no column in the rate table. A pincode in such a zone resolves to that zone, the price lookup finds no column, and the CART IS CHARGED NOTHING — silently, because the checkout's cond falls through to NIL. Every zone must have a column, or the zone must be removed."
                          missing-col))))
  zone-names)

(defun vndshp-check-column-caps (entity)
  "L1 (the second half) — the two varchar caps, checked before the INSERT.

   RATETABLECSV is varchar(500) and ZIPCODERANGECSV varchar(1024), and the server
   runs STRICT_TRANS_TABLES, so exceeding either is an outright INSERT failure.
   Left to the database it surfaces inside with-nst-db-create, whose catch-all
   turns any error into :U → 503 — telling the client 'unknown, try again' for a
   request that can never succeed. A ten-band, five-zone matrix is ~300 characters,
   so the cap is reachable by a vendor adding zones, which is exactly the vendor
   this message is written for."
  (let ((table (slot-value entity 'ratetablecsv)))
    (when (and table (> (length table) 500))
      (error 'vndshp-field-rejected
             :field :ratetablecsv
             :why (format nil "the rate table is ~D characters; the column holds 500. Trim the weight bands or the number of zones — a larger table cannot be stored at all."
                          (length table)))))
  (dolist (zone (slot-value entity 'zones))
    (let ((stored (ship-zone-zipcoderangecsv zone)))
      (when (and stored (> (length stored) 1024))
        (error 'vndshp-field-rejected
               :field :zones
               :why (format nil "zone ~A's prefix list is ~D characters; the column holds 1024. Split the zone, or list the region's two-digit prefixes rather than every office code."
                            (ship-zone-zonename zone) (length stored))))))
  entity)

(defun vndshp-default-file (filename)
  "The text of one of the platform's master shipping files, or NIL.

   (*HHUBRESOURCESDIR* is /data/www/public/img, where both live on this host; the
   repo copy of each is in site/public/csv/.) READ FROM THE FILE, NOT EMBEDDED
   HERE, and a missing file returns NIL rather than a fallback: an embedded copy of
   the rate table would be a SECOND source of truth for the numbers customers are
   charged, and the two would drift the first time someone edited one of them. A
   vendor created on a host without the file therefore gets a configuration with no
   zonewise data — which the laws report as exactly what it is, rather than
   inventing prices."
  (handler-case (hhub-read-file (format nil "~A/~A" *HHUBRESOURCESDIR* filename))
    (error () nil)))

(defun vndshp-seed-defaults (entity)
  "Fill a NEW configuration's rate table and zones from the platform master files
   when the caller supplied neither.

   WHY make SEEDS AND !update DOES NOT. A vendor that has just enabled shipping
   and has not yet uploaded anything is exactly the state the legacy page shows the
   master file in — it displays defaultshipzonepincodes.csv whenever the vendor has
   no zones of its own. Seeding makes a new configuration WORKING rather than
   empty; an edit never invents data the caller did not send.

   A caller that supplies either half supplies BOTH: seeding is all-or-nothing, so
   the seeded zone rows can never be paired with a caller's matrix and refused by
   L2 for a reason nobody chose. A caller that supplied one half and not the other
   is left exactly as it asked, and the laws report the gap if it matters.

   🚨 THE PLATFORM'S OWN MASTER FILES ARE CHECKED BEFORE THEY ARE ADOPTED, AND THIS
   IS NOT DEFENSIVENESS — IT IS A MEASURED DEFECT FIX. Adopting them blindly made
   EVERY payload-less create answer 500, because on this host the two master files
   do not satisfy the laws this entity enforces:

     /data/www/public/img/defaultshipratetable.csv
       MIN,MAX,ZONE-A,ZONE-B,ZONE-C,ZONE-D,ZONE-E      ← 7 columns
       0.5,1,50,70,,100                               ← 6 cells: ZONE-C is EMPTY
       … 15 more rows, all short by one cell and all with the empty ZONE-C
       → L1 refuses it (an empty price cell makes the checkout call float(\"\") and
         THROW), and the row is short of the header besides.

     /data/www/public/img/defaultshipzonepincodes.csv
       ZONE, PINCODES        ← note the SPACE after the comma
       ZONE-A,577*,560001,…  ← a REGEX FRAGMENT, not a digit prefix
       ZONE-E,               ← no prefixes at all

   Those files are the LIVE pilot data (the repo copy under site/public/csv is the
   older, digit-prefix version), and they are reachable, so the failure was not
   hypothetical: `POST {\"vendorId\": 2}` seeded, the law fired, and the client got
   a 500 for a request that sent nothing wrong. The seed is a CONVENIENCE — the
   platform offering a starting point — so it must not be able to fail the create
   that triggered it. A pair that does not pass the laws is therefore NOT adopted:
   the configuration is created EMPTY and the reason is written to the business log.
   An empty configuration is a legal state (no method enabled, nothing priced);
   a seeded one that the laws reject is not a state at all.

   WHAT THIS DOES NOT DO is weaken a law to make the data fit. The empty ZONE-C
   cell is a real defect in the master file with a real consequence at checkout,
   and it stays refused — by the laws, when a VENDOR sends it, and by this guard,
   silently-but-logged, when the PLATFORM offers it."
  (when (and (not (slot-value entity 'zones))
             (not (slot-value entity 'ratetablecsv)))
    (let ((zone-file (vndshp-default-file *HHUBDEFAULTSHIPZONESCSV*))
          (rate-file (vndshp-default-file *HHUBDEFAULTSHIPRATETABLECSV*)))
      (when (and zone-file rate-file)
        (let* ((zones (handler-case (vndshp-parse-zones-initarg zone-file)
                        (error () nil)))
               (why
                 (cond
                   ((null zones) "the zone file did not parse into any zone")
                   (t (handler-case
                          (progn
                            (multiple-value-bind (names bands)
                                (vndshp-parse-rate-table rate-file)
                              (declare (ignore bands))
                              ;; The two laws the seeded pair must satisfy. The
                              ;; remaining laws (the default-method coupling, the
                              ;; column caps) are checked by vndshp-validate-config
                              ;; on the merged entity a moment later.
                              (vndshp-check-zone-columns names zones)
                              (vndshp-check-zone-prefixes zones))
                            nil)
                        (vndshp-field-rejected (c)
                          (vndshp-field-rejected-why c)))))))
          (if why
              (hhub-log-message
               (format nil "nst-vnd-shp/make: the platform master shipping files were NOT seeded — ~A. The configuration is created EMPTY; the vendor must supply a rate table and zones. Files: ~A/~A and ~A/~A~%"
                       why *HHUBRESOURCESDIR* *HHUBDEFAULTSHIPRATETABLECSV*
                       *HHUBRESOURCESDIR* *HHUBDEFAULTSHIPZONESCSV*))
              (progn
                (setf (slot-value entity 'zones) zones)
                (setf (slot-value entity 'ratetablecsv) rate-file)))))))
  entity)

(defun vndshp-validate-config (entity)
  "Run every law against the configuration as it will be STORED, and normalise
   what it can. Called by make and by !update AFTER the entity is complete and
   BEFORE anything is written, so a refusal costs no rows.

   The zonewise checks are conditional on tablerateshipenabled being \"Y\" — a
   vendor shipping flat-rate has no business being asked for a matrix. The
   default-method check is unconditional, because a bad default costs money under
   every method."

  (vndshp-apply-flag-defaults entity)
  (vndshp-check-default-method entity)
  (vndshp-check-column-caps entity)
  (when (string= (string-upcase (or (slot-value entity 'tablerateshipenabled) "N")) "Y")
    (let ((table (slot-value entity 'ratetablecsv))
          (zones (slot-value entity 'zones)))
      (unless table
        (error 'vndshp-field-rejected
               :field :ratetablecsv
               :why "zonewise shipping is enabled but there is no rate table. Zonewise shipping has no price at all without the MIN,MAX,zone matrix — enable zonewise only once the table is supplied."))
      (unless zones
        (error 'vndshp-field-rejected
               :field :zones
               :why "zonewise shipping is enabled but no zones are defined. With no zone rows every pincode resolves to no zone, the checkout charges 0.00, and nothing reports it — supply the zones, or turn zonewise shipping off."))
      (multiple-value-bind (zone-names bands) (vndshp-parse-rate-table table)
        (declare (ignore bands))
        (vndshp-check-zone-columns zone-names zones)))
    (vndshp-check-zone-prefixes (slot-value entity 'zones)))
  entity)


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 7 — ?exists (प्रत्यभिज्ञा)
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod ?exists ((entity-class (eql 'nst-vnd-shp)) (vendor-id string) (ctx domain-ctx)
                    &key &allow-other-keys)
  "Does this vendor already have a shipping configuration IN THIS TENANT?

   The lookup value is the VENDOR-ID, because (VENDOR_ID, TENANT_ID) is what must
   be unique here — not a row-id, and not any column of this table. Like the
   payment twin, this is a DOMAIN law with no index behind it.

   A Belnap answer, because the honest answer is not yes/no:
     :F  free — nothing occupies the slot, so creation may proceed
     :T  a LIVE row exists (a plain fact of existence) → make must refuse
     :C  a SOFT-DELETED row occupies the slot. DELETED_STATE is in no key, so the
         row still holds it while नियम-2 makes it invisible to every verb — 'the
         configuration exists' and 'this vendor has no configuration' are both true
         at once. Unreachable through THIS surface (there is no delete!), but
         reachable through the legacy UI and raw SQL, so it is answered rather than
         assumed away.
     :U  the database could not be consulted — which is NOT 'probably free'.

   THE TENANT COMES FROM ctx, NEVER FROM A KEYWORD. &key &allow-other-keys is
   CLOS congruence with adhara's generic function; the other half of this identity
   is the TENANT, and accepting it from a caller would let a client probe another
   tenant's vendors. The keyword is accepted and IGNORED, deliberately."
  (declare (ignore entity-class))
  (let ((tenant-id (slot-value (domain-ctx-tenant ctx) 'row-id))
        (vid (vndshp-vendor-id-from-string vendor-id)))
    (if (null vid)
        (make-bo-knowledge
         :truth :f
         :payload nil
         :provenance (format nil "nst-vnd-shp/?exists: ~S does not address a vendor (vendor-ids are integers)" vendor-id))
        (let ((knowledge (with-db-call
                             (select-shipping-method-by-vendor-in-tenant vid tenant-id
                                                                          :include-deleted t)
                           "nst-vnd-shp/?exists (vendor-id, tenant, deleted rows included)")))
          (cond
            ((not (eq (bo-knowledge-truth knowledge) :t)) knowledge)
            ((string= (slot-value (bo-knowledge-payload knowledge) 'deleted-state) "Y")
             (bo-merge knowledge
                       (make-bo-knowledge
                        :truth :f
                        :payload nil
                        :provenance "नियम-2: DELETED_STATE='Y' rows are invisible to every verb")))
            (t knowledge))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 8 — make (सृजन)
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod make :around ((entity-class (eql 'nst-vnd-shp)) (ctx domain-ctx) &rest initargs)
  "TWO pre-flight laws, and the ORDER between them is the design.

   An :around rather than a :before for the reason the products, warehouse and
   payment twins all record: a :before cannot return a value, so raising was its
   only way to refuse, and every refusal reached the boundary as a 500 —
   indistinguishable from a crash and from 'not found'. An :around can return, so
   both laws answer in the domain's own four values.

   1. REFERENTIAL — the parent vendor must exist in this tenant. Neither table
      declares a FOREIGN KEY, so MySQL accepts an orphan VENDOR_ID; the constraint
      the schema is missing is applied here. It reuses `fetch 'nst-vnd`, so the
      profile's tenant scoping and BOLA refusal come for free rather than being
      reimplemented. A missing parent PROPAGATES the sentinel it returned — 404,
      not 409: the singleton question is moot and 'this vendor does not exist' is
      the accurate report.

   2. SINGLETON — only a CONFIRMED-FREE slot passes:
        ?exists :F → proceed
        ?exists :T → a live configuration exists       → contradiction → 409
        ?exists :C → a soft-deleted row holds the slot → contradiction → 409
        ?exists :U → could not check                   → unknown       → 503

      :C is refused rather than silently adopted. Adoption is more tempting here
      than for the payment twin — a shipping configuration is a setting, not an
      identity — but adopting it would erase the evidence that a live vendor's
      shipping was deleted out of band, and there is no delete! on this entity, so
      :C can only mean an anomaly. A human should see it.

   Skips both when no :vendor-id was supplied, because the primary method reports
   that case with the field named instead."
  (let ((vendor-id (getf initargs :vendor-id)))
    (if (null vendor-id)
        (call-next-method)
        (let* ((company (domain-ctx-tenant ctx))
               (vid (vndshp-vendor-id-from-string vendor-id)))
          (if (null vid)
              (make-instance 'nst-entity-nil
                             :tenant-id (slot-value company 'row-id)
                             :reason (format nil "~S does not address a vendor (vendor-ids are integers), so no shipping configuration can be created for it" vendor-id))
              (let ((parent (fetch 'nst-vnd (princ-to-string vid) ctx)))
                (if (not (typep parent 'nst-vnd))
                    parent
                    (let ((check (?exists 'nst-vnd-shp (princ-to-string vid) ctx)))
                      (case (bo-knowledge-truth check)
                        (:f (call-next-method))     ; confirmed free — proceed
                        (:t (make-instance 'nst-entity-contradiction
                                           :tenant-id (slot-value company 'row-id)
                                           :reason (format nil "Vendor ~A already has a shipping configuration in this tenant. It is a singleton setting: one row per vendor for its lifetime, created once, then edited. Edit the existing configuration instead — and note that a second row would not raise anywhere: the legacy checkout takes the FIRST row with no ORDER BY, so the price charged would depend on the query planner." vid)))
                        (otherwise
                         (domain-sentinel-from-knowledge
                          check ctx
                          :reason (lambda (truth)
                                    (case truth
                                      (:c (format nil "Vendor ~A has a SOFT-DELETED shipping configuration in this tenant. It holds the singleton slot (DELETED_STATE is in no key) while नियम-2 makes it invisible to every verb. This surface has no delete!, so the row was deleted out of band — a human must decide whether to restore it or remove it." vid))
                                      (otherwise (format nil "Vendor ~A: the singleton check did not come back free" vid)))))))))))))))

(defmethod make ((entity-class (eql 'nst-vnd-shp)) (ctx domain-ctx) &rest initargs)
  "सृजन प्रत्यय — create the vendor's shipping configuration, ONCE.

   कारक: the tenant comes from ctx alone (नियम-1), passed as the INTEGER row-id,
   because check-niyam compares (tenant-id entity) against
   (slot-value (domain-ctx-tenant ctx) 'row-id) and only two integers can be equal.
   The company OBJECT is needed for a different job: it is what
   copyVndShp-domaintodb turns into the written TENANT_ID.

   THE company SLOT IS SET UNCONDITIONALLY FROM ctx. extract-domain-initargs does
   NOT strip :company, so a caller that supplied one would otherwise have its value
   survive into the copier, which derives TENANT_ID from that slot — a tenant
   escape. Re-set AFTER make-instance, never before.

   :vendor-id IS THE ONLY REQUIRED FIELD, by domain law rather than by the schema:
   the column is nullable, but a shipping configuration belonging to no vendor
   means nothing, and (vendor-id, tenant) is the entire identity.

   ⚠ THE LEFTMOST-INITARG RULE is relied on, as the payment twin documents: a
   keyword supplied twice takes the FIRST value under SBCL, so :vendor-id and
   :tenant-id are passed BEFORE the caller's initargs and win over anything a
   caller sends.

   WRITE ORDER: the config row first, then the zones — a new configuration has no
   row-id until the INSERT returns, and vndshp-write-zones writes against
   VENDOR_ID, so either order works mechanically; config-first is chosen so a
   partial failure leaves a configuration with no zones rather than zones attached
   to nothing. !update orders them the other way round, for the reason given there."
  (declare (ignore entity-class))
  (let ((vendor-id (getf initargs :vendor-id)))
    (when (null vendor-id)
      (error 'vndshp-field-rejected
             :field :vendor-id
             :why "vendor-id is the entity's identity — one shipping configuration per (vendor-id, tenant). The column is nullable, but a configuration that belongs to no vendor means nothing."))
    (let* ((company (domain-ctx-tenant ctx))
           (tenant-id (slot-value company 'row-id))
           (vid (vndshp-vendor-id-from-string vendor-id)))
      (unless vid
        (error 'vndshp-field-rejected
               :field :vendor-id
               :why (format nil "~S does not address a vendor (vendor-ids are integers)" vendor-id)))
      ;; THE ZONES ARRIVE IN ONE OF FOUR SHAPES and are normalised before the
      ;; entity is built, so the class only ever holds structs.
      (let* ((zones-arg (getf initargs :zones))
             (entity (apply #'make-instance 'nst-vnd-shp
                            :vendor-id vid
                            :tenant-id tenant-id
                            :zones (vndshp-parse-zones-initarg zones-arg)
                            (loop for (k v) on initargs by #'cddr
                                  unless (eq k :zones) append (list k v))))
             (dbobj (make-instance 'dod-shipping-methods)))
        (setf (company entity) company)
        ;; A configuration with neither half supplied starts from the platform's
        ;; master files, which is the state the legacy page shows a new vendor.
        (vndshp-seed-defaults entity)
        (vndshp-validate-config entity)
        (copyVndShp-domaintodb entity dbobj)
        (let ((knowledge (with-nst-db-create (:source "nst-vnd-shp/make")
                            (clsql:update-records-from-instance dbobj)
                            dbobj)))
          (case (bo-knowledge-truth knowledge)
            (:t (bind-generated-row-id entity (bo-knowledge-payload knowledge))
                ;; The zone rows come second — see the write-order note above.
                (multiple-value-bind (rows-written zone-failure)
                    (vndshp-write-zones vid tenant-id (zones entity) nil)
                  (declare (ignore rows-written))
                  (if zone-failure
                      ;; The CONFIG ROW IS WRITTEN and the zones are not. Neither
                      ;; 'created' nor 'failed' is true, and the difference is
                      ;; exactly what a retry needs to know: a configuration whose
                      ;; zones are missing prices every cart at 0.00.
                      (make-instance 'nst-entity-contradiction
                                     :tenant-id tenant-id
                                     :reason (format nil "Vendor ~A: the shipping configuration row WAS created, but its ZONE ROWS WERE NOT (~A). The two tables are one configuration, so the vendor now has a configuration that cannot price a zonewise cart — the checkout would charge 0.00 for every pincode. Re-send the zones through !update; do not create the configuration again, the singleton is already taken. Zone write provenance: ~A"
                                                      vid (bo-knowledge-truth zone-failure)
                                                      (bo-knowledge-provenance zone-failure)))
                      entity)))            (:f (make-instance 'nst-entity-contradiction
                               :tenant-id tenant-id
                               :reason (format nil "Vendor ~A: the INSERT was rejected at the database. This table declares no unique key and no FOREIGN KEY, so a rejection here means the schema changed under this verb — the :around singleton check is no longer sufficient. Investigate DOD_SHIPPING_METHODS." vid)))
            (:u (domain-sentinel-from-knowledge
                 knowledge ctx
                 :reason (format nil "Vendor ~A shipping create: the database call did not answer — the row may or may not have been written, so this is unknown, not failed" vid)))
            (:c (error "Unreachable: no :pre-flight form was supplied to with-nst-db-create in this call — a :C here means the macro contract changed without this method being updated"))
            (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-create"
                              (bo-knowledge-truth knowledge)))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 9 — fetch (स्मरण)
;;; ═══════════════════════════════════════════════════════════════════════════

(defmethod fetch ((entity-class (eql 'nst-vnd-shp)) (id string) (ctx domain-ctx))
  "स्मरण प्रत्यय — recall the vendor's shipping configuration, zones included.

   🚨 ID IS THE VENDOR-ID, NOT A ROW-ID. Forced, not chosen: with one row per
   vendor and no addressable collection, a client has no way to LEARN a row-id, so
   the parent is the only usable address — and it is the honest one, since
   (vendor-id, tenant) IS this entity's identity. The payment twin departs from
   the tree's fetch convention for exactly this reason.

   Returns a real nst-vnd-shp or a Belnap sentinel — never a bare CL nil. A vendor
   with no configuration gets nst-entity-nil → 404, which is the correct REST
   answer: absent until created.

   TWO SELECTS, and the second is allowed to be empty: a vendor whose shipping is
   flat-rate or free has no zone rows, and that is a valid configuration rather
   than an incomplete one."
  (declare (ignore entity-class))
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (vid (vndshp-vendor-id-from-string id)))
    (if (null vid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a vendor (vendor-ids are integers)" id))
        (let ((knowledge (with-db-call
                             (select-shipping-method-by-vendor-in-tenant vid tenant-id)
                           "nst-vnd-shp/fetch (vendor-id, session tenant)")))
          (domain-result-from-knowledge
           knowledge ctx
           :hydrate (lambda (dbobj)
                      (let ((zone-knowledge (vndshp-zone-rows (list vid) tenant-id)))
                        ;; A zone read that did not answer must NOT be reported as
                        ;; 'this vendor has no zones' — that would price the cart at
                        ;; nothing. :U propagates as unknown.
                        (if (eq (bo-knowledge-truth zone-knowledge) :u)
                            (domain-sentinel-from-knowledge
                             zone-knowledge ctx
                             :reason (format nil "Vendor ~A shipping: the configuration row was read but the ZONE ROWS were not — whether this vendor has zones is unknown, and a configuration answered without them would look unpriceable. Retry." vid))
                            (vndshp-hydrate dbobj (bo-knowledge-payload zone-knowledge) vid company))))
           :reason (lambda (truth)
                     (case truth
                       (:f (format nil "Vendor ~A has no shipping configuration in this tenant (none created, or the row was deleted out of band)" vid))
                       (:u (format nil "Vendor ~A shipping: the database call did not answer — whether a configuration exists is unknown" vid))
                       (:c (format nil "Vendor ~A returned more than one shipping-configuration row — the singleton law is violated, which no key prevents, and the legacy checkout would silently use whichever row the planner returned first. Investigate DOD_SHIPPING_METHODS directly." vid)))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 10 — !update (!state)
;;; ═══════════════════════════════════════════════════════════════════════════

(defparameter *vndshp-update-forbidden-fields*
  '(:vendor-id)
  "Initargs !update REFUSES. ONE field, and it is not a secret.

   WHY :vendor-id IS REFUSED RATHER THAN STRIPPED. It is the PARENT LINK — half of
   this entity's identity. Letting a generic field update rewrite it re-points a
   vendor's shipping configuration at a DIFFERENT VENDOR inside the same tenant,
   which is precisely the intra-tenant BOLA that tenant scoping cannot see. That is
   not a configuration edit, it is a move, and it would need its own verb with its
   own authorization.

   NOTE THE CONTRAST WITH nst-vnd, whose forbidden list is credential columns. The
   secrets HERE (shippartnerkey, shippartnersecret) are deliberately EDITABLE:
   they are vendor-configurable partner credentials, the vendor's own settings page
   writes them today (dod-ui-ven.lisp:2154-2160), and refusing to rotate them
   through the API would leave a vendor unable to replace a leaked key. They are
   kept off the WIRE by VndShipResponseModel, which is a different boundary and the
   right one. So this list protects STRUCTURE; the response model protects
   CONFIDENTIALITY.")

(defmethod !update ((entity-class (eql 'nst-vnd-shp)) (vendor-id string) (ctx domain-ctx)
                    &rest update-args)
  "!state प्रत्यय — partial update of one vendor's shipping configuration, and
   optionally a REPLACEMENT of its zone list.

   ADDRESSED BY VENDOR-ID, not row-id, for the same reason fetch is: the client has
   no way to learn a row-id. The generic function calls this argument row-id; the
   name is positional, and the address this entity has is its parent.

   Only the initargs actually supplied change (CLOS reinitialize-instance), so an
   omitted flag keeps its stored value: the entity is hydrated from the row BEFORE
   the new values are applied, and the whole instance is written back.

   :ZONES IS A REPLACEMENT, NOT A MERGE, when supplied: the list given becomes the
   vendor's zones, names that disappeared are retired (soft-deleted) and names that
   reappear are revived. That is the honest reading of the vendor's action — they
   edited a CSV and re-uploaded it, and the file IS the whole zone set. A merge
   would make removal impossible to express.

   OMITTING :ZONES LEAVES THE ZONES ALONE. `(:zones nil)` is NOT the same thing: it
   is an explicit empty list, and it is REFUSED while zonewise shipping is enabled,
   because that combination is a configuration the checkout cannot price (L2).

   THE WRITE ORDER IS THE REVERSE OF make's, deliberately. The zone rows are
   written FIRST and the config row LAST, so an interrupted write (there is no
   transaction — file header, gap 1) leaves a matrix whose columns still have zone
   rows, rather than zone rows that no stored matrix prices. Of the two partial
   states, only the second is silently wrong at the checkout."
  (declare (ignore entity-class))
  ;; CHECK 1 — the parent link, by PRESENCE rather than by value: sending the field
  ;; at all is the mistake, so `(getf args field)` would be the wrong test (it lets
  ;; an explicit nil through, which is how the profile twin's list behaves).
  (dolist (field *vndshp-update-forbidden-fields*)
    (when (member field update-args :test #'eq)
      (error 'vndshp-field-rejected
             :field field
             :why "this is the parent link and half of this entity's identity — re-pointing a shipping configuration at another vendor is not a configuration edit. Address the vendor whose configuration you mean instead.")))
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (vid (vndshp-vendor-id-from-string vendor-id)))
    (if (null vid)
        (make-instance 'nst-entity-nil
                       :tenant-id tenant-id
                       :reason (format nil "~S does not address a vendor (vendor-ids are integers)" vendor-id))
        (let ((dbobj (select-shipping-method-by-vendor-in-tenant vid tenant-id)))
          (if (null dbobj)
              (make-instance 'nst-entity-nil
                             :tenant-id tenant-id
                             :reason (format nil "Vendor ~A has no shipping configuration in this tenant — there is no row to update. Create it first." vid))
              ;; THE WRITE PATH NEEDS THE ROWS IN ANY STATE, so that re-supplying a
              ;; retired zone name revives its row instead of duplicating it.
              (let* ((row-knowledge (vndshp-zone-rows (list vid) tenant-id :include-deleted t)))
                (if (eq (bo-knowledge-truth row-knowledge) :u)
                    (domain-sentinel-from-knowledge
                     row-knowledge ctx
                     :reason (format nil "Vendor ~A shipping update: the ZONE ROWS could not be read, so whether the replacement would duplicate or revive them is unknown. Nothing was written — retry." vid))
                    (let* ((all-rows (bo-knowledge-payload row-knowledge))
                           (live-rows (remove-if (lambda (r) (string= (slot-value r 'deleted-state) "Y"))
                                                 all-rows))
                           (zones-supplied (member :zones update-args :test #'eq))
                           (entity (vndshp-hydrate dbobj live-rows vid company)))
                      ;; Apply the caller's fields. :row-id is stripped — it is the
                      ;; ADDRESS of the कर्म, not a field of it; :zones is stripped
                      ;; because it is not an entity slot to reinitialize but a
                      ;; collection to replace, handled below.
                      (let ((args (copy-list update-args)))
                        (remf args :row-id)
                        (remf args :zones)
                        (apply #'reinitialize-instance entity args))
                      ;; Same कारक rule as make: a caller-supplied :company must not
                      ;; move an EXISTING row to another tenant. Re-set AFTER the
                      ;; reinitialize so the session company always wins.
                      (setf (company entity) company)
                      (when zones-supplied
                        (setf (zones entity)
                              (vndshp-parse-zones-initarg (getf update-args :zones))))
                      ;; THE LAWS RUN ON THE MERGED CONFIGURATION, before anything
                      ;; is written — so a caller that changes only the rate table
                      ;; is still checked against the zones already stored.
                      (vndshp-validate-config entity)
                      ;; ZONES FIRST, CONFIG SECOND — see the docstring.
                      (let ((zone-failure nil))
                        (when zones-supplied
                          (multiple-value-bind (rows-written failure)
                              (vndshp-write-zones vid tenant-id (zones entity) all-rows)
                            (declare (ignore rows-written))
                            (setf zone-failure failure)))
                        (when zone-failure
                          ;; STOP BEFORE THE CONFIG ROW. Writing it now would leave
                          ;; the matrix claiming zones the config row was about to
                          ;; describe, and the caller's own matrix may be the very
                          ;; thing that failed to land. Nothing else is written, so
                          ;; the stored state is still the last consistent one.
                          (return-from !update
                            (make-instance 'nst-entity-contradiction
                                           :tenant-id tenant-id
                                           :reason (format nil "Vendor ~A shipping update: the ZONE ROWS did not all write (~A), so the configuration row was left UNTOUCHED rather than half-applied — a matrix referencing zones that were not stored is the one state the checkout prices at 0.00. Some zone rows may already have changed: re-send the same :zones to converge. Zone write provenance: ~A"
                                                            vid (bo-knowledge-truth zone-failure)
                                                            (bo-knowledge-provenance zone-failure)))))
                        (copyVndShp-domaintodb entity dbobj)
                        (let ((knowledge (with-nst-db-update (:source "nst-vnd-shp/!update")
                                            (clsql:update-records-from-instance dbobj)
                                            dbobj)))
                          (case (bo-knowledge-truth knowledge)
                            (:t entity)
                            (:u ;; The write did not complete and the row's state is
                                ;; unknown → 503, not a 500 and NOT 404: the row
                                ;; exists, we simply cannot report what happened to it.
                                (domain-sentinel-from-knowledge
                                 knowledge ctx
                                 :reason (format nil "Vendor ~A shipping update: the database call did not answer — the configuration's current state is unknown (and if zones were supplied, they may already have been written, since the zones land before this row)" vid)))
                            (:f (error "Unreachable: with-nst-db-update without :pre-flight cannot return :F (vendor ~A)" vid))
                            (otherwise (error "Unrecognized bo-knowledge-truth ~A from with-nst-db-update"
                                              (bo-knowledge-truth knowledge))))))))))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 11 — enumerate (दर्शन)
;;;
;;; WHAT THIS LISTS, AND WHY THAT IS THE RIGHT THING. The configuration is a
;;; singleton per vendor, so "list them" can only mean one of two useful things:
;;; the zones of one vendor, or THE CONFIGURATIONS OF THE TENANT. The first is
;;; already `fetch` — the zones ride inside the entity — so this is the second:
;;; every vendor's shipping configuration in the session tenant, filtered. That is
;;; the report an operator needs ("which vendors ship zonewise", "who has zonewise
;;; enabled but no rate table"), and it is the shape nst-vnd's own enumerate has.
;;;
;;; नियम-1 applies to the SCOPE filter (WHERE TENANT_ID = ctx.tenant); a per-row
;;; check would be redundant once the query itself is tenant-scoped, as adhara's
;;; enumerate docstring says.
;;;
;;; ZONES ARE FETCHED WITH ONE EXTRA QUERY, not one per row — see
;;; select-ship-zone-rows-for-vendors.
;; ═══════════════════════════════════════════════════════════════════════════

(defparameter *vndshp-sort-whitelist*
  '((:row-id                 . :row-id)
    (:vendor-id              . :vendor-id)
    (:default-shipping-method . :defaultshippingmethod))
  "The ONLY columns enumerate may sort by. sort-by is caller-controllable — it
   arrives from a query string over HTTP — and this whitelist is what stands
   between that and arbitrary ORDER BY construction. Extend deliberately, one line
   at a time; never accept a raw column name from outside this list.

   NOTE THE NAME. *vnd-sort-whitelist* and *whs-sort-whitelist* already exist and
   validate-sort-args reads the WAREHOUSE's directly; reusing either name would
   silently redefine another entity's sort validation, which is the collision the
   vendor CONTEXT §5 records.")

(defun validate-vndshp-sort-args (sort-by sort-dir)
  "Resolves (sort-by, sort-dir) against *vndshp-sort-whitelist*, or signals."
  (let ((col (cdr (assoc sort-by *vndshp-sort-whitelist*))))
    (unless col
      (error 'vndshp-field-rejected
             :field :sort-by
             :why (format nil "~S is not a sortable column — expected one of ~A"
                          sort-by (mapcar #'car *vndshp-sort-whitelist*))))
    (unless (member sort-dir '(:asc :desc))
      (error 'vndshp-field-rejected
             :field :sort-dir
             :why (format nil "sort-dir must be :asc or :desc, got ~A" sort-dir)))
    (values col sort-dir)))

(defun vndshp-method-filter-clause (method)
  "The WHERE clause for 'this method is enabled'. An UNKNOWN keyword signals
   rather than being dropped: silently ignoring a filter the caller asked for is how
   '?is-primary-location=0' came to mean the opposite of itself in the warehouse API
   (nst-bl-apidefs2-CONTEXT §9.6)."
  (case method
    (:free     [= [:freeshipenabled] "Y"])
    (:flat     [= [:flatrateshipenabled] "Y"])
    (:table    [= [:tablerateshipenabled] "Y"])
    (:external [= [:extshipenabled] "Y"])
    (:pickup   [= [:storepickupenabled] "Y"])
    (otherwise (error 'vndshp-field-rejected
                      :field :method
                      :why (format nil "unknown method ~S — expected one of :free :flat :table :external :pickup"
                                   method)))))

(defun vndshp-status-clause (status)
  "Maps a status keyword to its WHERE clause, read off the data rather than the old
   spec. All six live rows are active_flag='Y' and deleted_state='N', so :inactive
   matches nothing today — implemented anyway, because deactivation is a real
   workflow and a filter that silently cannot match is worse than one that returns
   an empty page."
  (case status
    (:active   [= [:active-flag] "Y"])
    (:inactive [= [:active-flag] "N"])
    (otherwise (error 'vndshp-field-rejected
                      :field :status
                      :why (format nil "unknown status ~S — expected :active or :inactive. There is no :suspended and no :pending here: DOD_SHIPPING_METHODS carries no suspend and no approval column, unlike DOD_VEND_PROFILE."
                                   status)))))

(defun vndshp-status-arg (value)
  "Query strings arrive as STRINGS, keywords come from internal callers. Returns a
   keyword, or NIL for 'no filter'."
  (cond ((null value) nil)
        ((keywordp value) value)
        ((symbolp value) (intern (string-upcase (symbol-name value)) :keyword))
        ((stringp value) (intern (string-upcase value) :keyword))
        (t (error 'vndshp-field-rejected :field :status
                  :why (format nil "~S cannot be read as a status" value)))))

(defun build-vndshp-filter-clauses (tenant-id &key vendor-id default-method method status)
  "Assembles the WHERE clauses for a shipping-configuration list.
   DELETED_STATE = 'N' is FIXED, not a keyword: नियम-2 makes a deleted row invisible
   to every verb, so a verb that could opt out of this clause could read back what
   it just deleted."
  (let ((clauses (list [= [:tenant-id] tenant-id]
                       [= [:deleted-state] "N"])))
    (when vendor-id
      (let ((vid (vndshp-vendor-id-from-string vendor-id)))
        (if vid
            (push [= [:vendor-id] vid] clauses)
            (error 'vndshp-field-rejected :field :vendor-id
                   :why (format nil "~S does not address a vendor (vendor-ids are integers)" vendor-id)))))
    (when default-method
      ;; The code is normalised through the same reader the writer uses, so
      ;; '?default-shipping-method=trs' and :TRS mean the same row set.
      (push [= [:defaultshippingmethod] (vndshp-method-code default-method)] clauses))
    (when method (push (vndshp-method-filter-clause method) clauses))
    (when status (push (vndshp-status-clause status) clauses))
    clauses))

(defun select-vndshp-by-filter (tenant-id &key vendor-id default-method method status
                                              (sort-by :row-id) (sort-dir :desc)
                                              limit offset)
  "One filtered shipping-configuration SELECT. sort-by/sort-dir are validated, never
   interpolated."
  (multiple-value-bind (sort-col sort-dir) (validate-vndshp-sort-args sort-by sort-dir)
    ;; MySQL requires a LIMIT for OFFSET to mean anything; refusing loudly beats
    ;; returning page 1 forever.
    (when (and offset (null limit))
      (error 'vndshp-field-rejected :field :offset
             :why (format nil ":offset ~A was given without :limit — MySQL cannot express an offset on its own" offset)))
    (apply #'clsql:select 'dod-shipping-methods
                          :where (apply #'clsql:sql-and
                                        (build-vndshp-filter-clauses
                                         tenant-id :vendor-id vendor-id
                                                   :default-method default-method
                                                   :method method
                                                   :status status))
                          :order-by (list (list sort-col sort-dir))
                          :caching *dod-database-caching* :flatp t
                          (append (when limit  (list :limit limit))
                                  (when offset (list :offset offset))))))

(defmethod enumerate ((entity-class (eql 'nst-vnd-shp)) (ctx domain-ctx)
                      &key vendor-id default-method method status
                           (sort-by :row-id) (sort-dir :desc) limit offset)
  "दर्शन प्रत्यय — the session tenant's shipping configurations, filtered.

   Returns a LIST of nst-vnd-shp, or the EMPTY LIST when nothing matches. An empty
   list is a successful empty result, not a not-found fact: apidefs2 renders it as
   200 [] and reserves 404 for a sentinel.

   A vendor that has never configured shipping simply does not appear. This lists
   CONFIGURATIONS, not vendors — finding the vendors with no configuration is a
   question about DOD_VEND_PROFILE and belongs to that entity's surface."
  (declare (ignore entity-class))
  (let* ((company (domain-ctx-tenant ctx))
         (tenant-id (slot-value company 'row-id))
         (knowledge (with-nst-db-read-all
                        (:source "nst-vnd-shp/enumerate"
                         :pk-extractor (lambda (d) (slot-value d 'row-id)))
                      (select-vndshp-by-filter
                       tenant-id
                       :vendor-id vendor-id :default-method default-method
                       :method method :status (vndshp-status-arg status)
                       :sort-by sort-by :sort-dir sort-dir
                       :limit limit :offset offset))))
    (case (bo-knowledge-truth knowledge)
      (:t (let* ((rows (bo-knowledge-payload knowledge))
                 (ids (mapcar (lambda (d) (slot-value d 'vendor-id)) rows))
                 (zone-knowledge (vndshp-zone-rows ids tenant-id)))
            ;; Same reasoning as fetch: a zone read that failed must not be reported
            ;; as 'these vendors have no zones'.
            (if (eq (bo-knowledge-truth zone-knowledge) :u)
                (domain-sentinel-from-knowledge
                 zone-knowledge ctx
                 :reason (format nil "Shipping enumerate, tenant ~A: the configurations were read but the ZONE ROWS were not — every row would appear to have no zones, which is a configuration the checkout cannot price. Nothing is reported rather than something wrong." tenant-id))
                (let ((by-vendor (vndshp-zones-by-vendor (bo-knowledge-payload zone-knowledge))))
                  (mapcar (lambda (dbobj)
                            (let* ((vid (slot-value dbobj 'vendor-id))
                                   (zones (cdr (assoc vid by-vendor))))
                              (vndshp-hydrate dbobj zones vid company)))
                          rows)))))
      (:f '())                                  ; empty list — a success, not 404
      (:u ;; The list could not be read → 503. NOTE the type change: enumerate
          ;; normally returns a LIST, so a caller must inspect the result rather than
          ;; assume one. That is the price of not claiming an empty list when we
          ;; could not read it.
          (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (format nil "Shipping enumerate, tenant ~A: the database call did not answer — the configuration list contents are unknown" tenant-id)))
      (:c ;; Duplicate PKs in the result set — data integrity, a human must look.
          (domain-sentinel-from-knowledge
           knowledge ctx
           :reason (format nil "Shipping enumerate, tenant ~A: the result set contained duplicate primary keys — data integrity issue, investigate DOD_SHIPPING_METHODS directly" tenant-id)))
      (otherwise (error "Unrecognized bo-knowledge-truth ~A from nst-vnd-shp/enumerate"
                        (bo-knowledge-truth knowledge))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; SECTION 12 — The reverse ferry — domain->response + render-json
;;;
;;; ONLY THREE METHODS ARE DEFINED HERE, deliberately. The rest of this surface is
;;; already ENTITY-GENERIC in this tree, and redefining ANY of it would silently
;;; replace the warehouse's, products' and vendor profile's versions — same generic
;;; function, same specializer:
;;;
;;;   * domain->response on nst-entity-nil / -unknown / -contradiction specializes
;;;     on the SENTINEL classes, so a shipping fetch miss already ferries to
;;;     nst-response-nil → 404 with no shipping-specific code;
;;;   * domain->response on (eql t) — the delete! ack — is unreachable here because
;;;     this entity HAS no delete!;
;;;   * render-json on LIST, and domain->response-list, are thin mapcars over the
;;;     per-element methods, so they already cover VndShipResponseModel;
;;;   * render-json on the three sentinel response models.
;; ═══════════════════════════════════════════════════════════════════════════

(defmethod domain->response ((entity nst-vnd-shp) (ctx domain-ctx))
  "Reverse ferry (adhara §4): nst-vnd-shp → VndShipResponseModel.

   entity is the ONLY dispatching argument that may be an nst-domain-entity, and
   the entity itself never crosses into Ring 4 — only the boundary object does.

   THIS CLASS IS A SECURITY BOUNDARY, and the exclusion is structural:
   shippartnerkey and shippartnersecret have NO SLOT on VndShipResponseModel, so
   they cannot reach a client even by a later edit to render-json. vendor-id,
   tenant-id, company, created-at, updated-at and deleted-state are withheld for
   the reasons recorded on the class itself.

   The ZONES cross as SHIP-ZONE STRUCTS — value objects, not entities — and
   render-json converts each to an alist. A second boundary zone class would be a
   second place the zone field list is written down, and the two would drift the
   first time a column is added."
  (declare (ignore ctx))
  (let ((destination (make-instance 'VndShipResponseModel)))
    (setf (row-id destination)              (row-id entity))
    (setf (shp-name destination)            (shp-name entity))
    (setf (freeshipenabled destination)     (freeshipenabled entity))
    (setf (flatrateshipenabled destination) (flatrateshipenabled entity))
    (setf (tablerateshipenabled destination)(tablerateshipenabled entity))
    (setf (extshipenabled destination)      (extshipenabled entity))
    (setf (storepickupenabled destination)  (storepickupenabled entity))
    (setf (minorderamt destination)         (minorderamt entity))
    (setf (flatratetype destination)        (flatratetype entity))
    (setf (flatrateprice destination)       (flatrateprice entity))
    (setf (ratetablecsv destination)        (ratetablecsv entity))
    (setf (defaultshippingmethod destination) (defaultshippingmethod entity))
    (setf (zones destination)               (zones entity))
    (setf (active-flag destination)         (active-flag entity))
    destination))

(defun vndshp-zone->json-alist (zone)
  "One ship-zone struct as an alist for the wire.

   PUBLISHES THE PREFIXES PARSED, not the stored string. The column holds \"(56 57
   58 59)\" — a printed Lisp list, a storage format that exists for the checkout's
   convenience — and a JSON client should never be handed that. What it gets is the
   list, plus the REGION CODES those prefixes fall in, which is the only thing that
   makes \"ZONE-A\" mean anything to a reader.

   THE PARSE HERE BINDS *read-eval* NIL, through vndshp-zones-from-storage-string,
   because the value being read is vendor-written text out of a column that the
   checkout reads unguarded (BLOCKER 1)."
  (let ((prefixes (vndshp-zones-from-storage-string (ship-zone-zipcoderangecsv zone))))
    (list (cons "rowId"           (response-id-string (ship-zone-row-id zone)))
          (cons "zoneName"        (ship-zone-zonename zone))
          (cons "pincodePrefixes" prefixes)
          (cons "regionCodes"     (vndshp-zones-region-codes prefixes)))))

(defmethod render-json ((r VndShipResponseModel) (ctx domain-ctx))
  "Single shipping configuration → JSON ALIST.

   The contract is split in this tree on purpose: a per-ENTITY method returns a
   Lisp structure, while the per-LIST and sentinel methods return already-encoded
   text, and the dispatcher's render hop normalises the two.

   THE ALIST IS THE FIELD ALLOWLIST and the LAST gate in front of the transport. It
   publishes nothing VndShipResponseModel does not declare — and that class declares
   no shippartnerkey, shippartnersecret, vendor-id, tenant-id, company, created-at,
   updated-at or deleted-state.

   FLAG CONVENTION: every flag publishes as a BOOLEAN through vnd-flag->boolean, and
   the keys are named for what they MEAN rather than for the column — the same
   convention as the profile and payment twins, and the same divergence from
   warehouse, which publishes activeFlag as the raw string \"Y\"/\"N\".

   THE KEYS ARE THE MODERN SHIPPING WORDS, not the table's, because the table's are
   not words: \"freeShipEnabled\" would be a column name with a capital letter, and
   `tableRate` means nothing to a client that has not read this file. `zoneWise` is
   what the vendor's own page calls it.

   A NULL FLAG HERE PUBLISHES AS FALSE, and unlike the payment twin that is
   correct: these columns carry no :void-value in the view-class, so a stored NULL
   really is a NIL, and every legacy reader treats it as off. The false answer
   matches what the checkout does — which is why nst-dal-vndshp.lisp writes \"N\"
   explicitly rather than relying on it."
  (declare (ignore ctx))
  (list
   ;; IDENTITY
   (cons "rowId"                  (response-id-string (row-id r)))
   (cons "name"                   (shp-name r))
   ;; METHOD ENABLES
   (cons "freeShippingEnabled"    (vnd-flag->boolean (freeshipenabled r)))
   (cons "flatRateEnabled"        (vnd-flag->boolean (flatrateshipenabled r)))
   (cons "zoneWiseEnabled"        (vnd-flag->boolean (tablerateshipenabled r)))
   (cons "externalPartnerEnabled" (vnd-flag->boolean (extshipenabled r)))
   (cons "storePickupEnabled"     (vnd-flag->boolean (storepickupenabled r)))
   ;; MONEY + DEFAULT
   (cons "minOrderAmount"         (minorderamt r))
   (cons "flatRateType"           (flatratetype r))
   (cons "flatRatePrice"          (flatrateprice r))
   (cons "defaultShippingMethod"  (defaultshippingmethod r))
   (cons "rateTableCsv"           (ratetablecsv r))
   ;; THE COLLECTION — zips as described above; each element is an alist.
   (cons "zones"                  (mapcar #'vndshp-zone->json-alist (zones r)))
   ;; STATUS
   (cons "active"                 (vnd-flag->boolean (active-flag r)))))
