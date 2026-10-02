;;; nst-verify-doc-numbering.lisp — verify the DOCUMENT NUMBERING family
;;; (S0c of the orders batch) WITHOUT a database, a build or the live image.
;;;
;;;   cd /home/ubuntu/ninestores && mkdir -p .asdf-cache
;;;   XDG_CACHE_HOME=/home/ubuntu/ninestores/.asdf-cache \
;;;     sbcl --noinform --non-interactive \
;;;          --load aiharness/deepseek/tools/nst-verify-doc-numbering.lisp
;;;
;;; Exit code 0 = every property below holds. 1 = at least one FAIL (it names it).
;;;
;;; ── WHAT IT VERIFIES, AND WHY EACH ONE IS NOT OBVIOUS ───────────────────────
;;;
;;; The family lives in hhub/core/dod-bl-utl.lisp and is called by the ORDER mint,
;;; by the S8b legacy funnels, and by the invoice settings' own aspirational
;;; invoice-number-format. Design: aiharness/deepseek/skills/order-adhara-stories-
;;; CONTEXT.md § S0c, and the F1 decision record in its §10.
;;;
;;; 1. THE FY RULE takes a date in the shapes this system hands back — a CLSQL DATE
;;;    struct (what a DATE column yields through the ORM) and an ISO string — and
;;;    April-March is the boundary, checked on BOTH sides of 1 April.
;;;
;;; 2. THE TEMPLATE RENDERER substitutes in ONE LEFT-TO-RIGHT PASS, so a customer
;;;    prefix that spells a token cannot be expanded a second time; and an unknown
;;;    or unclosed token SIGNALS rather than reaching a customer as literal text.
;;;    It also renders the SHIPPED invoice template unchanged — the one regression
;;;    this change could cause in a domain it does not own.
;;;
;;; 3. THE REFERENCE PERMUTATION is deterministic (a migration's dry run must
;;;    reproduce its real run) and non-sequential (F1: a sequential suffix tells
;;;    every vendor how many orders its customer placed with COMPETITORS). Its
;;;    alphabet is asserted to exclude the look-alikes 0/1/I/O that make a number
;;;    unusable when it is read aloud — which is how a vendor receives it.
;;;
;;; 4. THE FAIL-CLOSED KEY. nst-doc-ref-key must ERROR when the key is absent, never
;;;    fall back to a default: a default would make every reference guessable while
;;;    the system looked healthy. With no database reachable, erroring IS the
;;;    observable behaviour, so it is asserted here.
;;;
;;; 5. THE SQL-TOKEN GUARD. The counter statements are built as strings (the
;;;    LAST_INSERT_ID idiom has no parameterised form in CLSQL), so the guard — not
;;;    the caller's discipline — is what keeps a document type out of SQL.
;;;
;;; ── TWO BUGS THIS CHECK FOUND WHEN IT WAS FIRST RUN (both fixed) ────────────
;;; * nst-doc-number-token-width answered NIL for every template: its (return …)
;;;   exited the loop, and a trailing form after the loop discarded the value. The
;;;   "token absent → NIL" expectation hid it, so that case alone would have passed.
;;; * The acceptance criterion's own regex allowed a 3-6 character prefix while R1
;;;   defines varchar(8): 'ORD-XYZCORP-…' (7 characters) was rejected by the test
;;;   that was supposed to approve it. The doc now says {3,8}.
;;;
;;; It does NOT touch the counter table: allocating a counter needs MySQL, and the
;;; LAST_INSERT_ID idiom is verified by the migration's dry run instead. This check
;;; is the offline half; the migration is the online half.

(in-package :cl-user)

(load "/home/ubuntu/quicklisp/setup.lisp")
(dolist (s (list :clsql :hunchentoot :cl-json :cl-csv :cl-yaml :cl-base64
                 :cl-ppcre :ironclad :secure-random))
  (ql:quickload s :silent t))
(load "/home/ubuntu/ninestores/hhub/package/packages.lisp")
;; plain LOAD, not compile-file: this file holds no defmethod/defclass, so nothing
;; in it needs another file's classes at load time
(load "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp")

(in-package :nstores)

(defparameter *checks* 0)
(defparameter *failures* 0)

(defun chk (label got expected)
  (incf *checks*)
  (if (equal got expected)
      (format t "  ok    ~A~%" label)
      (progn (incf *failures*)
             (format t "  FAIL  ~A~%        got      ~S~%        expected ~S~%" label got expected))))

(defun chk-true (label form)
  (incf *checks*)
  (if form
      (format t "  ok    ~A~%" label)
      (progn (incf *failures*) (format t "  FAIL  ~A~%" label))))

(defun chk-signals (label thunk)
  (incf *checks*)
  (handler-case (progn (funcall thunk) (incf *failures*) (format t "  FAIL  ~A (it returned)~%" label))
    (error () (format t "  ok    ~A~%" label))))

(defparameter *test-key* "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  "A FIXED key for the permutation checks. Passed explicitly as :key — NOT installed
   by redefining nst-doc-ref-key, which would clobber the real accessor in any image
   this file was loaded into.")

(format t "~&=== S0c document numbering — offline check ===~%")

;;; ── 1. the FY rule, in the shapes that actually arrive ───────────────────────
(format t "~&FY rule (April-March, both sides of the boundary)~%")
(chk "DATE struct 2026-04-01 -> 2026-2027"
     (nst-financial-year-label (clsql-sys:make-date :year 2026 :month 4 :day 1)) "2026-2027")
(chk "DATE struct 2026-03-31 -> 2025-2026 (previous FY)"
     (nst-financial-year-label (clsql-sys:make-date :year 2026 :month 3 :day 31)) "2025-2026")
(chk "short form 2026-04-01 -> 2026-27"
     (nst-financial-year-short (clsql-sys:make-date :year 2026 :month 4 :day 1)) "2026-27")
(chk "short form 2026-03-31 -> 2025-26"
     (nst-financial-year-short (clsql-sys:make-date :year 2026 :month 3 :day 31)) "2025-26")
(chk "ISO STRING 2026-04-01 -> 2026-27" (nst-financial-year-short "2026-04-01") "2026-27")
(chk "ISO STRING 2026-03-31 -> 2025-26" (nst-financial-year-short "2026-03-31") "2025-26")
(chk "month token 2026-09-28 -> 09"
     (nst-financial-year-month (clsql-sys:make-date :year 2026 :month 9 :day 28)) "09")
(chk-signals "a wall-time SIGNALS (decode-date gives 6 values only for a wall-time,
 but this CLSQL signals on one — so there is no third contract to read)"
             (lambda () (nst-date-ymd (clsql-sys:get-time))))
(chk-signals "a non-date string SIGNALS" (lambda () (nst-date-ymd "not-a-date")))
(chk-signals "an arbitrary object SIGNALS" (lambda () (nst-date-ymd #(1 2 3))))

;;; ── 2. the template renderer ─────────────────────────────────────────────────
(format t "~&token renderer (single pass; unknown tokens refuse)~%")
(let ((values (list (cons "PREFIX" "XYZCORP") (cons "FY" "2026-27") (cons "REF" "7K4M2Q")
                    (cons "COUNTER" "42") (cons "YYYY" "2026") (cons "MM" "09"))))
  (chk "the order template renders"
       (nst-format-doc-number "ORD-{prefix}-{fy}-{ref:6}" values) "ORD-XYZCORP-2026-27-7K4M2Q")
  (chk "THE SHIPPED INVOICE TEMPLATE RENDERS UNCHANGED (no regression in a domain this does not own)"
       (nst-format-doc-number "INV-YYYY-MM-{counter}" values) "INV-2026-09-42")
  (chk "a :width zero-pads a numeric token" (nst-format-doc-number "{counter:5}" values) "00042")
  (chk "a prefix that SPELLS a token is not re-expanded (single pass)"
       (nst-format-doc-number "{prefix}-{fy}" (list (cons "PREFIX" "YYYY") (cons "FY" "2026-27")))
       "YYYY-2026-27")
  (chk-signals "an unknown token SIGNALS rather than reaching a customer as {nope}"
               (lambda () (nst-format-doc-number "{nope}" values)))
  (chk-signals "an unclosed brace SIGNALS" (lambda () (nst-format-doc-number "{prefix" values)))
  (chk-signals "a token with no value SIGNALS" (lambda () (nst-format-doc-number "{prefix}" nil)))
  (chk-signals "a non-numeric value shorter than its width SIGNALS (never padded out of alphabet)"
               (lambda () (nst-format-doc-number "{ref:8}" values))))

(format t "~&ref width is data, not code~%")
(chk "width from {ref:6}" (nst-doc-number-token-width "ORD-{prefix}-{fy}-{ref:6}" "ref") 6)
(chk "width from {ref:8}" (nst-doc-number-token-width "ORD-{prefix}-{fy}-{ref:8}" "ref") 8)
(chk "no width given -> the default" (nst-doc-number-token-width "{ref}" "ref" 6) 6)
(chk "token absent -> NIL" (nst-doc-number-token-width "ORD-{fy}" "ref") nil)

;;; ── 3. the permutation (the F1 mitigation) ───────────────────────────────────
(format t "~&reference permutation (deterministic, non-sequential, sayable)~%")
(let* ((args (list :tenant-id 2 :scope-kind "CUSTOMER" :doc-type "ORDER"
                   :finyear "2026-27" :length 6 :key *test-key*))
       (a (apply #'nst-doc-reference 1 :scope-id 7 args))
       (b (apply #'nst-doc-reference 1 :scope-id 7 args))
       (c (apply #'nst-doc-reference 2 :scope-id 7 args))
       (d (apply #'nst-doc-reference 1 :scope-id 8 args)))
  (chk "length is honoured" (length a) 6)
  (chk "DETERMINISTIC: the same inputs render the same reference (a dry run must reproduce the real run)" a b)
  (chk-true "counter 1 and 2 differ" (not (equal a c)))
  (chk-true "customer 7 and 8 differ (the scope is in the permutation input)" (not (equal a d)))
  (chk-true "every symbol is in the 32-symbol alphabet"
            (every (lambda (ch) (find ch *nst-doc-ref-alphabet*)) a))
  (chk-true "no look-alike 0/1/I/O appears (the number is spoken aloud)"
            (notany (lambda (ch) (find ch "01IO")) a))
  (format t "  info  reference(1)=~A  reference(2)=~A~%" a c)
  (let ((number (nst-format-doc-number
                 "ORD-{prefix}-{fy}-{ref:6}"
                 (list (cons "PREFIX" "XYZCORP") (cons "FY" "2026-27") (cons "REF" a)))))
    (format t "  info  rendered = ~A~%" number)
    (chk-true "matches the acceptance criterion ^ORD-[A-Z0-9]{3,8}-[0-9]{4}-[0-9]{2}-[2-9A-HJ-NP-Z]{6}$"
              (cl-ppcre:scan "\\AORD-[A-Z0-9]{3,8}-[0-9]{4}-[0-9]{2}-[2-9A-HJ-NP-Z]{6}\\z" number))))

;;; ── 4. the key fails closed ──────────────────────────────────────────────────
(format t "~&key handling~%")
(chk-signals "nst-doc-ref-key SIGNALS when the key cannot be read (no default, ever)"
             (lambda () (nst-doc-ref-key)))
(chk-true "a DIFFERENT key renders a different reference (the key is doing work)"
          (not (equal (nst-doc-reference 1 :tenant-id 2 :scope-kind "CUSTOMER" :scope-id 7
                                         :doc-type "ORDER" :finyear "2026-27" :length 6
                                         :key *test-key*)
                      (nst-doc-reference 1 :tenant-id 2 :scope-kind "CUSTOMER" :scope-id 7
                                         :doc-type "ORDER" :finyear "2026-27" :length 6
                                         :key "another-key"))))

;;; ── 5. the SQL-token guard ───────────────────────────────────────────────────
(format t "~&SQL-token guard (the counter statements are built as strings)~%")
(chk-true "ORDER is safe" (nst-doc-sql-token-safe-p "ORDER"))
(chk-true "2026-27 is safe" (nst-doc-sql-token-safe-p "2026-27"))
(chk-true "a quote is REFUSED" (not (nst-doc-sql-token-safe-p "ORD'ER")))
(chk-true "a space is REFUSED" (not (nst-doc-sql-token-safe-p "ORD ER")))
(chk-true "lowercase is REFUSED" (not (nst-doc-sql-token-safe-p "order")))
(chk-true "an empty string is REFUSED" (not (nst-doc-sql-token-safe-p "")))

;;; ── 6. the counter SQL: quoting, and the two hand-written copies in step ────
;;; The DDL lives in the migration and the allocation SQL in nst-next-doc-counter, and
;;; BOTH ARE WRITTEN BY HAND — so they can drift, and a column name the server has
;;; claimed can stop one of them. The first version of the DDL named the sequence
;;; column LAST_VALUE, which MySQL 8.0 RESERVES (it is a window function), and the
;;; migration died on the live database with:
;;;
;;;   Error 1064 … near 'LAST_VALUE    INT NOT NULL DEFAULT 0,
;;;   CREATED       TIMESTAMP NOT NULL DEFAULT' at line 8
;;;
;;; Every identifier is backtick-quoted now, and this section is what keeps it that way
;;; WITHOUT a database — because the next reserved word this server claims must not
;;; take a live migration run to discover.
(defun nst-read-file-string (path)
  (with-open-file (s path :external-format :utf-8)
    (let ((out (make-string (file-length s))))
      (subseq out 0 (read-sequence out s)))))

(defun nst-backticked-names (text)
  "Every `NAME` in TEXT, as a list of strings."
  (let ((names '()) (i 0))
    (loop while (< i (length text)) do
      (if (char= (char text i) #\`)
          (let ((close (position #\` text :start (1+ i))))
            (if close
                (progn (push (subseq text (1+ i) close) names) (setf i (1+ close)))
                (setf i (1+ i))))
          (incf i)))
    (remove-duplicates names :test #'string=)))

(defun nst-unquoted-occurrence-p (text name)
  "True when NAME appears in TEXT somewhere other than inside `backticks`."
  (let ((stripped (cl-ppcre:regex-replace-all (format nil "`~A`" name) text "")))
    (not (null (search name stripped)))))

(format t "~&counter SQL (quoting, and the two copies in step)~%")
(let* ((mig (nst-read-file-string "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-doc-counter.lisp"))
       (utl (nst-read-file-string "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"))
       (ddl (subseq mig (search "CREATE TABLE `DOD_DOC_COUNTER` (" mig)
                    (search ") ENGINE=InnoDB" mig)))
       (ins (subseq utl (search "INSERT INTO `DOD_DOC_COUNTER`" utl)
                    (search "ON DUPLICATE KEY UPDATE" utl)))
       (ddl-cols '("ROW_ID" "DOC_TYPE" "SCOPE_KIND" "SCOPE_ID" "TENANT_ID" "FINYEAR"
                   "LAST_SEQ" "CREATED" "UPDATED"))
       (ins-cols '("DOC_TYPE" "SCOPE_KIND" "SCOPE_ID" "TENANT_ID" "FINYEAR" "LAST_SEQ")))
  (chk-true "the DDL declares every expected column, each backtick-quoted"
            (every (lambda (c) (search (format nil "`~A`" c) ddl)) ddl-cols))
  (chk-true "no DDL column is left UNQUOTED (a reserved word would stop the CREATE)"
            (notany (lambda (c) (nst-unquoted-occurrence-p ddl c)) ddl-cols))
  (chk-true "the allocation SQL names its columns backtick-quoted too"
            (every (lambda (c) (search (format nil "`~A`" c) ins)) ins-cols))
  (chk-true "no allocation column is left UNQUOTED"
            (notany (lambda (c) (nst-unquoted-occurrence-p ins c)) ins-cols))
  (chk-true "NO DRIFT: every backticked name the allocation SQL uses exists in the DDL"
            (every (lambda (n) (member n (nst-backticked-names ddl) :test #'string=))
                   (nst-backticked-names ins)))
  (chk-true "the sequence column is LAST_SEQ in both copies, not the reserved LAST_VALUE"
            (and (search "`LAST_SEQ`" ddl) (search "`LAST_SEQ`" ins))))

;;; ── 7. the customer DOC_PREFIX rule (R1/R2) ──────────────────────────────────
;;; A prefix is the document series' IDENTITY, so it is derived once, de-duplicated,
;;; stored and frozen. The two halves that can be checked without a database are the
;;; validation charset and the de-duplication ladder.
(format t "~&customer DOC_PREFIX (R1 validation, R2 de-duplication)~%")
(chk "a 3-character prefix is valid" (nst-doc-prefix-valid-p "XYZ") t)
(chk "an 8-character prefix is valid" (nst-doc-prefix-valid-p "XYZCORP1") t)
(chk "2 characters is too short" (nst-doc-prefix-valid-p "XY") nil)
(chk "9 characters is too long for varchar(8)" (nst-doc-prefix-valid-p "XYZCORP12") nil)
(chk "lowercase is REFUSED (never silently upcased into a collision)" (nst-doc-prefix-valid-p "xyz") nil)
(chk "a HYPHEN is refused — the number's own delimiter, so it would make the number ambiguous"
     (nst-doc-prefix-valid-p "XYZ-CORP") nil)
(chk "a space is refused — and char(8) would have padded one in anyway"
     (nst-doc-prefix-valid-p "XYZ CORP") nil)
(chk "a non-string is refused" (nst-doc-prefix-valid-p 42) nil)

(chk "base of a legal name takes WHOLE WORDS (the requester's worked example)"
     (nst-doc-prefix-base "XYZ CORP LIMITED") "XYZCORP")
(chk "base is NOT the first 8 characters (that gave XYZCORPL — gibberish said aloud)"
     (nst-doc-prefix-base "XYZ CORP LIMITED") "XYZCORP")
(chk "a word too long for the budget is dropped, not sliced"
     (nst-doc-prefix-base "XYZ Corporation") "XYZ")
(chk "two real spellings that collide — which is why allocation must de-duplicate"
     (nst-doc-prefix-base "XYZ Corp Pvt Ltd") "XYZCORP")
(chk "punctuation splits words; a sub-3 total draws from the next word"
     (nst-doc-prefix-base "A.B. Traders") "ABT")
(chk "a single long word is truncated to 8" (nst-doc-prefix-base "ABCDEFGHIJKL") "ABCDEFGH")
(chk "base truncates to 8" (nst-doc-prefix-base "ABCDEFGHIJKL") "ABCDEFGH")
(chk "base of a name with fewer than 3 alphanumerics is NIL (a refusal, not a guess)"
     (nst-doc-prefix-base "A B") nil)
(chk "base of an empty name is NIL" (nst-doc-prefix-base "") nil)
(chk "base of NIL is NIL" (nst-doc-prefix-base nil) nil)

(let* ((cands (nst-doc-prefix-candidates "XYZ CORP LIMITED"))
       (dense (nst-doc-prefix-candidates "ABC")))
  (chk-true "the ladder starts with the base" (string= (first cands) "XYZCORP"))
  (chk-true "every rung is within varchar(8)"
            (every (lambda (c) (<= (length c) 8)) cands))
  (chk-true "EVERY rung is itself a valid prefix (3-8 chars, A-Z0-9)"
            (every #'nst-doc-prefix-valid-p cands))
  (chk-true "DETERMINISTIC: two calls give the same ladder" (equal cands (nst-doc-prefix-candidates "XYZ CORP LIMITED")))
  (chk-true "NO DUPLICATES inside one ladder (the 6+2 and 5+3 rungs can collide for a base whose 6th character is a digit)"
            (= (length cands) (length (remove-duplicates cands :test #'string=))))
  (chk-true "a base whose 6th character is a digit does not repeat a rung (XYZCO0 -> XYZCO001 twice)"
            (= (length (nst-doc-prefix-candidates "XYZCO0"))
               (length (remove-duplicates (nst-doc-prefix-candidates "XYZCO0") :test #'string=))))
  (chk-true "a short base still yields a full ladder" (> (length dense) 100))
  (chk "allocation skips a taken base" (nst-allocate-doc-prefix "XYZ CORP LIMITED" '("XYZCORP")) "XYZCOR01")
  (chk "allocation skips case-insensitively" (nst-allocate-doc-prefix "XYZ CORP LIMITED" '("xyzcorp")) "XYZCOR01")
  (chk "allocation skips the first two rungs" (nst-allocate-doc-prefix "XYZ CORP LIMITED" '("XYZCORP" "XYZCOR01")) "XYZCOR02")
  (chk "allocation refuses rather than improvising when every rung is taken"
       (nst-allocate-doc-prefix "XYZ CORP LIMITED" cands) nil)
  (chk "allocation of an unusable name is NIL" (nst-allocate-doc-prefix "A B" nil) nil))

;;; ── 8. the LIVE customer names, as a predictor for the migration's dry run ──
;;; These seven (name → prefix) pairs are not invented: they are the customers that
;;; actually have orders, read from DOD_CUST_PROFILE on 2026-09-28 (25 customers, 7 with
;;; orders, 485 orders between them). Asserting them here means the ordnum-identity
;;; migration's dry run can be read AGAINST A PREDICTION instead of a hope — and if the
;;; derivation ever changes, this section says what it would change the live prefixes to.
(format t "~&the seven live customers that have orders (predictions for the dry run)~%")
(dolist (case '(("Gcust837333444" . "GCUST837")                    ; 216 orders, GUEST
                ("Demo Customer Company" . "DEMO")                 ; 206, legal name
                ("K N Deshpande" . "KND")                          ;  49
                ("Guest Customer - Basic Account" . "GUEST")       ;  10, GUEST
                ("LG Iyengars Bakery" . "LGI")                     ;   2, legal name wins
                ("cust17" . "CUST17")                              ;   1
                ("Pawan Deshpande" . "PAWAN")))                    ;   1
  (chk (format nil "~S -> ~A" (car case) (cdr case))
       (nst-doc-prefix-base (car case)) (cdr case)))
(let ((live (mapcar (lambda (c) (nst-doc-prefix-base (car c)))
                    '(("Gcust837333444") ("Demo Customer Company") ("K N Deshpande")
                      ("Guest Customer - Basic Account") ("LG Iyengars Bakery")
                      ("cust17") ("Pawan Deshpande")))))
  (chk-true "all seven live prefixes are DISTINCT — the de-duplication ladder does not fire on existing data"
            (= 7 (length (remove-duplicates live :test #'string=))))
  (chk-true "and every one of them is a valid prefix"
            (every #'nst-doc-prefix-valid-p live))
  (format t "  info  live prefixes = ~{~A~^, ~}~%" live))

;;; ── 9. the DRY RUN renders through the same code as the real run ────────────
;;; The migration's dry run supplies the counter instead of allocating it. If it
;;; assembled the number by any other route, the review would be of different code —
;;; so the two paths must agree, and this is the check that says so.
(format t "~&dry run and real run agree (same assembly, supplied counter)~%")
(let* ((date (clsql-sys:make-date :year 2026 :month 4 :day 1))
       (ref (nst-doc-reference 5 :tenant-id 2 :scope-kind "CUSTOMER" :scope-id 12
                               :doc-type "ORDER" :finyear "2026-27" :length 6
                               :key *test-key*))
       (expected (nst-format-doc-number "ORD-{prefix}-{fy}-{ref:6}"
                                        (list (cons "PREFIX" "GCUST837")
                                              (cons "FY" "2026-27")
                                              (cons "REF" ref)))))
  (chk "nst-order-number-for with a SUPPLIED counter renders what the allocator path renders"
       (nst-order-number-for "ORD-{prefix}-{fy}-{ref:6}" "GCUST837" date 2 12
                             :counter 5 :key *test-key*)
       expected)
  (format t "  info  customer 12, counter 5 -> ~A~%" expected)
  (chk-true "the number matches the acceptance regex (prefix 3-8, FY 4-2, ref 6)"
            (cl-ppcre:scan "\\AORD-[A-Z0-9]{3,8}-[0-9]{4}-[0-9]{2}-[2-9A-HJ-NP-Z]{6}\\z" expected))
  (chk-true "two different counters give two different numbers"
            (not (equal expected
                        (nst-order-number-for "ORD-{prefix}-{fy}-{ref:6}" "GCUST837" date 2 12
                                              :counter 6 :key *test-key*))))
  (chk-true "the {ref:8} WIDTH is data: a wider template yields an 8-character suffix"
            (cl-ppcre:scan "\\AORD-[A-Z0-9]{3,8}-[0-9]{4}-[0-9]{2}-[2-9A-HJ-NP-Z]{8}\\z"
                           (nst-order-number-for "ORD-{prefix}-{fy}-{ref:8}" "GCUST837" date 2 12
                                                 :counter 5 :key *test-key*))))

;;; ── 10. the CUSTOMER field list vs its three classes ────────────────────────
;;; *nst-customer-business-fields* drives THREE consumers: both copy ferries AND
;;; domain->response, which setfs every field in the list onto
;;; nst-customer-response-model. So a field in the list with no slot on that class
;;; signals MISSING-SLOT on every customer response — the exact defect that took the
;;; whole invoice API down (T4 in the story file, and the reason S0d adds doc-prefix to
;;; three classes rather than one). Source-only: no loading, no database, no build.
(defun nst-src-strip-comments (text)
  "TEXT with every ;-to-end-of-line comment removed, honouring string literals and
   backslash escapes.

   THIS IS NOT COSMETIC: a quoted slot LIST may carry comments of its own — the invoice's
   *invh-mirrored-slots* does (\";;; identity of the document\"), and so do the two ORDER
   lists — and a naive symbol scrape reads those words as slot names. Measured: it turned
   54 mirrored slots into 98 and reported 40 phantom mismatches."
  (with-output-to-string (out)
    (let ((in-string nil) (esc nil) (in-comment nil))
      (loop for ch across text do
        (cond
          (in-comment (when (char= ch #\Newline) (setf in-comment nil) (princ ch out)))
          (in-string (princ ch out)
                     (cond (esc (setf esc nil))
                           ((char= ch #\\) (setf esc t))
                           ((char= ch #\") (setf in-string nil))))
          ((char= ch #\") (setf in-string t) (princ ch out))
          ((char= ch #\;) (setf in-comment t))
          (t (princ ch out)))))))

(defun nst-src-symbols-in-quoted-list (text marker)
  "The symbol names of the flat quoted list that follows MARKER.

   The lists this reads are FLAT — no nested parens — so the list ends at the first )
   after the opening quote. COMMENTS ARE STRIPPED FIRST, not after: a paren written in a
   comment ends the list early otherwise, and the ORDER lists document their groups with
   ;; headings — one of which, \"tax RATES (decimal(4,2))\", did exactly that, truncating
   the list to 10 of 27 slots."
  (let* ((clean (nst-src-strip-comments text))
         (m (search marker clean))
         (quote (and m (position #\' clean :start m)))
         (open (and quote (position #\( clean :start quote)))
         (close (and open (position #\) clean :start open))))
    (when (and open close)
      (cl-ppcre:all-matches-as-strings "[a-z][a-z0-9-]+" (subseq clean (1+ open) close)))))

(defun nst-src-class-slot-names (text class-name)
  "The slot names declared directly in (defclass CLASS-NAME ...).

   Bounded by the class's (:documentation, which every class in this file has, so the
   scan never reaches another class's slots. Slots begin with a lowercase letter at the
   start of a line; the pattern cannot match :initarg/:accessor (they start with a
   colon) nor a docstring, and the body of a class holds only slot forms."
  (let* ((m (search (format nil "(defclass ~A " class-name) text))
         (stop (and m (search "(:documentation" text :start2 m)))
         (body (and m (subseq text m (or stop (length text))))))
    (when body
      (remove-duplicates
       ;; \\(+ AND string-trim, NOT a single \\(: a class's FIRST slot is written
       ;; `((row-id`, so a one-paren pattern silently skips it — which is exactly how the
       ;; vendor-orders column scan missed row-id earlier in this session.
       (mapcar (lambda (hit) (string-trim '(#\Space #\Tab #\() hit))
               ;; [ \t]+ AND NOT \s+: in multiline mode \s also matches NEWLINES, so a
               ;; match could begin at the preceding line break and keep a stray paren —
               ;; measured: it reported a slot literally named "(row-id".
               (cl-ppcre:all-matches-as-strings "(?m)^[ \t]+\\(+[a-z][a-z0-9-]*"
                                                (nst-src-strip-comments body)))
       :test #'string=))))

(format t "~&customer field list vs its three classes~%")
(let* ((dal (nst-read-file-string "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp"))
       (bl (nst-read-file-string "/home/ubuntu/ninestores/hhub/customer/nst-bl-Customer.lisp"))
       (fields (nst-src-symbols-in-quoted-list bl "*nst-customer-business-fields*"))
       (domain-slots (nst-src-class-slot-names dal "nst-customer"))
       (response-slots (nst-src-class-slot-names dal "nst-customer-response-model")))
  (format t "  info  ~D business fields, ~D domain slots, ~D response slots~%"
          (length fields) (length domain-slots) (length response-slots))
  (chk-true "the extractors found the lists (a silent empty list would make this section pass vacuously)"
            (and (> (length fields) 60) (> (length domain-slots) 60) (> (length response-slots) 60)))
  (let ((missing-domain (remove-if (lambda (f) (member f domain-slots :test #'string=)) fields))
        (missing-response (remove-if (lambda (f) (member f response-slots :test #'string=)) fields)))
    (chk-true (format nil "every business field is a SLOT on nst-customer (missing: ~{~A~^, ~})" missing-domain)
              (null missing-domain))
    (chk-true (format nil "every business field is a SLOT on nst-customer-response-model — a field in the list with no slot here is MISSING-SLOT on EVERY customer response (missing: ~{~A~^, ~})" missing-response)
              (null missing-response)))
  (chk-true "doc-prefix is in the list AND on both classes (S0d)"
            (and (member "doc-prefix" fields :test #'string=)
                 (member "doc-prefix" domain-slots :test #'string=)
                 (member "doc-prefix" response-slots :test #'string=)))
  (chk-true "doc-prefix is declared on the ORM view class too (else the copiers write nothing)"
            (search "DOC_PREFIX" dal)))

; ── 11. the ORDER mirrored-slot lists vs their two classes ──────────────────
;;; The same T4 trap as the customer section, on the two new entities: the mirror list
;;; drives domain->response, so a listed slot with no slot on the RESPONSE model is
;;; MISSING-SLOT on every response. This section also checks the REVERSE direction, which
;;; no one checks by hand: a domain slot that is NOT in the list is never copied OUT, so
;;; it silently vanishes from every response without any error at all.
(defparameter *nst-inherited-slots* '("id" "tenant-id" "created-at" "updated-at" "deleted-state")
  "Slots every nst-domain-entity carries WITHOUT declaring them. Allowed in a mirror list
   (deleted-state is, deliberately) but absent from a class's own slot forms.")

(format t "~&the ORDER mirror lists vs their two classes~%")
(dolist (case '(("nst-ordh" "NstOrdhResponseModel" "*ordh-mirrored-slots*"
                 "/home/ubuntu/ninestores/hhub/order/nst-dal-ordh.lisp")
                ("nst-orditm" "NstOrditmResponseModel" "*orditm-mirrored-slots*"
                 "/home/ubuntu/ninestores/hhub/order/nst-dal-orditm.lisp")))
  (destructuring-bind (entity resp-model list-var path) case
    (let* ((text (nst-read-file-string path))
           (slots (nst-src-class-slot-names text entity))
           (resp (nst-src-class-slot-names text resp-model))
           (mirror (nst-src-symbols-in-quoted-list text list-var)))
      (format t "  info  ~A: ~D slots, ~D response slots, ~D mirrored~%"
              entity (length slots) (length resp) (length mirror))
      (chk-true (format nil "~A: the extractors found all three (a silent empty list would pass vacuously)" entity)
                (and (> (length slots) 25) (> (length resp) 25) (> (length mirror) 25)))
      (let ((not-a-slot (remove-if (lambda (m) (or (member m slots :test #'string=)
                                                   (member m *nst-inherited-slots* :test #'string=)))
                                   mirror)))
        (chk-true (format nil "~A: every mirrored slot exists on the entity or is inherited (bad: ~{~A~^, ~})" entity not-a-slot)
                  (null not-a-slot)))
      (let ((missing-resp (remove-if (lambda (m) (member m resp :test #'string=)) mirror)))
        (chk-true (format nil "~A: every mirrored slot is on the RESPONSE model — else MISSING-SLOT on EVERY response (missing: ~{~A~^, ~})" entity missing-resp)
                  (null missing-resp)))
      (let ((unmirrored (remove-if (lambda (sl) (or (string= sl "row-id")
                                                    (member sl mirror :test #'string=)))
                                   slots)))
        (chk-true (format nil "~A: every entity slot is mirrored OUT — an unmirrored slot vanishes from every response with no error (unmirrored: ~{~A~^, ~})" entity unmirrored)
                  (null unmirrored)))
      (chk-true (format nil "~A: the response model declares row-id (domain->response sets it explicitly)" entity)
                (member "row-id" resp :test #'string=))
      (chk-true (format nil "~A: row-id is NOT in the mirror list (it is set explicitly, not copied)" entity)
                (not (member "row-id" mirror :test #'string=)))
      (chk-true (format nil "~A: deleted-state is mirrored (the invoice's missing slot was exactly this one)" entity)
                (member "deleted-state" mirror :test #'string=)))))

; ── 12. the ORDER field policy: four lists that must PARTITION the entity ────
;;; S5's !update refuses anything outside the channel's allowlist, so these lists ARE the
;;; field half of the authorization model. Three defects are INVISIBLE without this section,
;;; and each one is a rule failing open or closed with nothing to report it:
;;;
;;;   * a slot in NO list is REFUSED on every channel — a field nobody can edit, discovered
;;;     by a user rather than by us;
;;;   * a slot in TWO lists is decided by whichever member test happens to run first, so the
;;;     rule stops being readable from the lists;
;;;   * a FERRY-reserved key missing from the strip list is the invoice's recorded
;;;     :tenant-id hole reopening for direct callers — the whole reason the verb re-strips.
;;;
;;; It also checks the two status lists against each other: a deletable status that is not an
;;; open one would let a closed order be deleted, which no verb could then explain.

(defun nst-src-status-codes (text marker)
  "The upper-case status codes of the quoted list that follows MARKER, without quotes."
  (let* ((clean (nst-src-strip-comments text))
         (m (search marker clean))
         (open (and m (position #\( clean :start m)))
         (close (and open (position #\) clean :start open))))
    (when (and open close)
      (mapcar (lambda (s) (subseq s 1 (1- (length s))))
              (cl-ppcre:all-matches-as-strings "\"[A-Z0-9]{2,4}\""
                                               (subseq clean (1+ open) close))))))

(defparameter *nst-ordh-policy-lists*
  '("*ordh-caller-writable-fields*" "*ordh-internal-only-fields*"
    "*ordh-never-writable-fields*" "*ordh-update-stripped-initargs*"))

(format t "~&the ORDER field policy vs the entity's slots~%")
(let* ((bl (nst-read-file-string "/home/ubuntu/ninestores/hhub/order/nst-bl-ordh.lisp"))
       (dal (nst-read-file-string "/home/ubuntu/ninestores/hhub/order/nst-dal-ordh.lisp"))
       (slots (nst-src-class-slot-names dal "nst-ordh"))
       (policy (mapcar (lambda (v) (cons v (nst-src-symbols-in-quoted-list bl v)))
                       *nst-ordh-policy-lists*))
       (all (apply #'append (mapcar #'cdr policy)))
       (writable (cdr (assoc "*ordh-caller-writable-fields*" policy :test #'string=)))
       (internal (cdr (assoc "*ordh-internal-only-fields*" policy :test #'string=)))
       (never (cdr (assoc "*ordh-never-writable-fields*" policy :test #'string=)))
       (stripped (cdr (assoc "*ordh-update-stripped-initargs*" policy :test #'string=)))
       (controls (nst-src-symbols-in-quoted-list bl "*ordh-update-control-keys*"))
       ;; read from ADHARA, not transcribed here: if the ferry's reserved list ever grows,
       ;; this check must fail on its own rather than keep agreeing with yesterday's copy
       (resident (nst-src-symbols-in-quoted-list
                  (nst-read-file-string "/home/ubuntu/ninestores/hhub/core/nst-bl-adhara.lisp")
                  "*reserved-initargs*"))
       ;; S8: the OPEN and TERMINAL vocabularies moved to core/dod-bl-utl.lisp and are read
       ;; THERE — reading them from the order BL would now find nothing and quietly make the
       ;; last two checks in this section vacuous.
       (core (nst-read-file-string "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"))
       (terminal (nst-src-status-codes core "*order-terminal-statuses*"))
       (deletable (nst-src-status-codes bl "*ordh-deletable-statuses*"))
       (open (nst-src-status-codes core "*order-open-statuses*")))
  (format t "  info  ~D slots; policy ~D writable / ~D internal-only / ~D never / ~D stripped; ~D control keys; statuses open [~{~A ~}] terminal [~{~A ~}] deletable [~{~A ~}]~%"
          (length slots) (length writable) (length internal) (length never) (length stripped)
          (length controls) open terminal deletable)
  (chk-true "the extractors found all four lists AND the class slots (a silent empty list would make this section pass vacuously)"
            (and (>= (length slots) 50) (>= (length writable) 30)
                 (>= (length internal) 3) (>= (length never) 5) (>= (length stripped) 10)))
  (let ((dupes (loop for x in (remove-duplicates all :test #'string=)
                     when (> (count x all :test #'string=) 1) collect x)))
    (chk-true (format nil "no field appears in TWO policy lists — else the rule depends on member-test order (dupes: ~{~A~^, ~})" dupes)
              (null dupes)))
  (let ((unlisted (remove-if (lambda (s) (member s all :test #'string=)) slots)))
    (chk-true (format nil "every entity slot is in exactly one policy list — an unlisted slot is REFUSED on every channel (unlisted: ~{~A~^, ~})" unlisted)
              (null unlisted)))
  (let ((not-a-slot (remove-if (lambda (x) (or (member x slots :test #'string=)
                                               (member x *nst-inherited-slots* :test #'string=)))
                               all)))
    (chk-true (format nil "every name in a policy list is a real slot or an inherited one — a typo here is silently unwritable or unseen forever (bad: ~{~A~^, ~})" not-a-slot)
              (null not-a-slot)))
  (chk-true (format nil "the reserved list was read from nst-bl-adhara.lisp, not transcribed (~{~A~^, ~})" resident)
            (>= (length resident) 5))
  (let ((unclosed (remove-if (lambda (i) (member i stripped :test #'string=)) resident)))
    (chk-true (format nil "EVERY key *reserved-initargs* holds is re-stripped IN THIS VERB — this is the invoice's direct-call hole closed, not copied a third time (missing: ~{~A~^, ~})" unclosed)
              (null unclosed)))
  (chk-true (format nil "the control keys are NOT slots and NOT in any policy list — reinitialize-instance would reject them as initargs (bad: ~{~A~^, ~})"
                     (remove-if (lambda (c) (not (or (member c slots :test #'string=)
                                                     (member c all :test #'string=))))
                                controls))
            (and (plusp (length controls))
                 (null (remove-if-not (lambda (c) (or (member c slots :test #'string=)
                                                      (member c all :test #'string=)))
                                      controls))))
  (chk-true (format nil "the status extractor found all three lists (open ~D, terminal ~D, deletable ~D)" (length open) (length terminal) (length deletable))
            (and (plusp (length open)) (plusp (length terminal)) (plusp (length deletable))))
  (chk-true "every status code is THREE characters — STATUS is char(3), so a five-character code could not be stored at all"
            (every (lambda (s) (= 3 (length s))) (append open terminal deletable)))
  (chk-true (format nil "nothing is both open and terminal (~{~A~^, ~})" (intersection open terminal :test #'string=))
            (null (intersection open terminal :test #'string=)))
  (let ((bad (remove-if (lambda (s) (member s open :test #'string=)) deletable)))
    (chk-true (format nil "every DELETABLE status is also an OPEN one — else a closed order could be deleted (bad: ~{~A~^, ~})" bad)
              (null bad))))

; ── 13. the ORDER status vocabulary has ONE home, and the legacy layer reads it (S8) ──
;;; The defect S8 exists to fix was not a typo: the new API mints STATUS='DFT' while seven
;;; legacy reads tested the literal 'PEN', so an order created through the new API was
;;; INVISIBLE to every legacy list, count and view. The fix is one vocabulary in core plus a
;;; retrofit of those reads — and the failure mode of the FIX is equally quiet: one read left
;;; behind, or a second copy of the list, reproduces the same invisibility. So this section
;;; asserts the shapes that make the defect impossible, in SOURCE, with no database:
;;;
;;;   * core owns the two sets and the two predicates, and the codes are the three-character
;;;     codes the char(3) column can hold;
;;;   * no entity file defines its own copy of either set (the duplicate is what drifted);
;;;   * NO read anywhere under hhub/ tests STATUS against the literal 'PEN' — the retrofit's
;;;     completion criterion, as a tree-wide count;
;;;   * the CMP equality sites that remain are named and counted, because they are the
;;;     deliberately-untouched COMPLETED reads (CMP + fulfilled Y) and nothing else;
;;;   * the legacy creation paths still WRITE 'PEN' (AC (c): the funnels are not this story).

(defun nst-src-count-of (needle text)
  "How many times NEEDLE occurs in TEXT — a plain substring count. Used for the status
   literals, where 'none left' is the property being asserted."
  (loop with n = (length needle) with start = 0 with c = 0
        for i = (search needle text :start2 start)
        while i do (incf c) (setf start (+ i n))
        finally (return c)))

(defun nst-src-count-in-files (needle paths)
  (loop for path in paths sum (nst-src-count-of needle (nst-read-file-string path))))

(format t "~&the ORDER status vocabulary, and the legacy retrofit~%")
(let* ((core (nst-read-file-string "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"))
       (ord  (nst-read-file-string "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp"))
       (odt  (nst-read-file-string "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp"))
       (ui   (nst-read-file-string "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp"))
       (blh  (nst-read-file-string "/home/ubuntu/ninestores/hhub/order/nst-bl-ordh.lisp"))
       (blm  (nst-read-file-string "/home/ubuntu/ninestores/hhub/order/nst-bl-orditm.lisp"))
       (open (nst-src-status-codes core "*order-open-statuses*"))
       (terminal (nst-src-status-codes core "*order-terminal-statuses*")))
  (format t "  info  open [~{~A ~}] terminal [~{~A ~}]~%" open terminal)
  (chk-true "core/dod-bl-utl.lisp defines BOTH sets and BOTH predicates (S8/D17)"
            (and (search "(defparameter *order-open-statuses*" core)
                 (search "(defparameter *order-terminal-statuses*" core)
                 (search "(defun order-open-status-p" core)
                 (search "(defun order-terminal-status-p" core)))
  (chk-true "the open set is exactly DFT and PEN — the new API's code and the legacy code, which is the whole point"
            (and (member "DFT" open :test #'string=) (member "PEN" open :test #'string=)
                 (= 2 (length open))))
  (chk-true "the two sets are disjoint, and every code is THREE characters (STATUS is char(3))"
            (and (null (intersection open terminal :test #'string=))
                 (every (lambda (x) (= 3 (length x))) (append open terminal))))
  (chk-true "no ENTITY file keeps a private copy of either set — a second copy is exactly how the two drifted apart"
            (and (not (search "(defparameter *ordh-open-statuses*" blh))
                 (not (search "(defparameter *ordh-terminal-statuses*" blh))
                 (not (search "(defparameter *ordh-open-statuses*" blm))
                 (not (search "(defparameter *ordh-terminal-statuses*" blm))))
  (chk-true "the adhara order files GATE on the shared list rather than on a literal"
            (and (search "*order-open-statuses*" blh) (search "*order-terminal-statuses*" blh)
                 (search "*order-open-statuses*" blm)))
  (let ((pen-eq (nst-src-count-in-files "[= [:status] \"PEN\"]"
                                        (list "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
                                              "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp"
                                              "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp"
                                              "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp"))))
    (chk-true (format nil "NO read in the retrofitted files tests STATUS against the literal PEN (found ~D) — one left behind reproduces the S8 defect silently" pen-eq)
              (zerop pen-eq)))
  (let ((in-ord (nst-src-count-of "[in [:status] *order-open-statuses*]" ord))
        (in-odt (nst-src-count-of "[in [:status] *order-open-statuses*]" odt)))
    (chk-true (format nil "the OPEN reads use the shared set: ~D in dod-bl-ord (1 pending count + 3 fulfilled-branch clauses), ~D in dod-bl-odt" in-ord in-odt)
              (and (= 4 in-ord) (= 3 in-odt))))
  (let ((cmp-ord (nst-src-count-of "[= [:status] \"CMP\"]" ord))
        (cmp-odt (nst-src-count-of "[= [:status] \"CMP\"]" odt)))
    (chk-true (format nil "the CMP equality sites that remain are the named COMPLETED reads and the fulfilled branches: ~D + ~D = 6, and no more" cmp-ord cmp-odt)
              (= 6 (+ cmp-ord cmp-odt))))
  (chk-true "the legacy item VIEW gates on order-open-status-p — without it a DFT item renders as neither Pending nor Fulfilled"
            (and (search "order-open-status-p" ui)
                 (zerop (nst-src-count-of "(equal status \"PEN\")" ui))))
  (chk-true "the legacy CREATION paths still write PEN (AC (c): the funnels are S8b's business, not S8's)"
            (and (plusp (nst-src-count-of ":status \"PEN\"" ord))
                 (plusp (nst-src-count-of ":status \"PEN\"" odt)))))

(format t "~&=== ~D checks, ~D failures ===~%" *checks* *failures*)
(format t "S0c OFFLINE: ~A~%" (if (zerop *failures*) "PASS" "FAIL"))
(sb-ext:exit :code (if (zerop *failures*) 0 1))
