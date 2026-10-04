;;; nst-preflight.lisp — the OFFLINE checks to run BEFORE claiming a story done.
;;;
;;;   cd /home/ubuntu/ninestores && mkdir -p .asdf-cache
;;;   XDG_CACHE_HOME=/home/ubuntu/ninestores/.asdf-cache \
;;;     sbcl --noinform --non-interactive --load aiharness/deepseek/tools/nst-preflight.lisp
;;;
;;; Exit code 0 = every check passed. 1 = at least one FAIL, named with its file and line.
;;;
;;; ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
;;; The orders batch found its bugs one at a time. Classified afterwards, most were
;;; knowable in advance; they were found late only because nothing ran the known failure
;;; modes over the story's own files before it was called done. Each check below is one of
;;; those failures made mechanical:
;;;
;;;   delimiter balance   an unbalanced file. nst-dbu-ordnum-identity.lisp ran one paren
;;;                       short; a hand-placed fix then closed a FLET early, and the
;;;                       compiler reported a LOCAL function as an undefined GLOBAL one.
;;;
;;;   SQL quoting         MySQL 8.0 RESERVES LAST_VALUE (a window function), so a CREATE
;;;                       TABLE failed on the LIVE database with Error 1064 AFTER every
;;;                       offline check had passed. Quoting every identifier makes the
;;;                       whole class impossible; this check enforces the quoting.
;;;
;;;   non-vacuity         a check that finds nothing because it looked in the wrong place.
;;;                       Every check here asserts it FOUND its inputs.
;;;
;;; ── THE LESSON THIS FILE PAID FOR ───────────────────────────────────────────
;;; The first version hand-wrote its own scanner and was WRONG three ways: it read comment
;;; text as symbol names, a paren inside a comment truncated a list, and — the one that
;;; mattered — the character literal `#\;` on line 19 of dod-bl-utl.lisp made a
;;; `;`-starts-a-comment rule swallow the rest of that line, so a PERFECTLY BALANCED file
;;; was reported two parens short.
;;;
;;; SO THIS FILE NO LONGER SCANS ANYTHING BY HAND. The Lisp READER already implements
;;; comments, #| block comments |#, strings, escapes and #\c character literals exactly.
;;; Balance is therefore "does the reader reach EOF", which cannot disagree with the
;;; compiler because it IS the reader the compiler uses.
;;;
;;; The general rule, worth more than either check: WHEN A CHECKER DISAGREES WITH THE
;;; SYSTEM, SUSPECT THE CHECKER — and prefer the substrate's own parser to a
;;; reimplementation of it. A checker that cries wolf costs as much as one that misses,
;;; because it teaches you to ignore it.
;;;
;;; ── WHAT THIS CANNOT DO ─────────────────────────────────────────────────────
;;; Three classes need the DATABASE and the agent has no credentials: the live schema is
;;; not the create-script (that mistake produced three wrong decisions), a column's Lisp
;;; type is not its declared type (decode-date answers a DATE struct with FOUR values and
;;; a wall-time with six), and the DATA decides feasibility (485 of 485 ORDNUMs were NULL).
;;; Those print at the end as the queries a human runs BEFORE a story is APPLIED.

(in-package :cl-user)

(load "/home/ubuntu/quicklisp/setup.lisp")
;; ⚠ THE PACKAGE SET IS THE HARNESS'S, NOT THE CHECK'S, and a missing one looks exactly
;; like a broken file: `Package HUNCHENTOOT does not exist` while reading dod-bl-utl.lisp is
;; the reader complaining that the harness did not load the app's dependencies. This is the
;; same list startup/load.lisp quickloads (minus clsql-mysql, which cannot load for a
;; non-owner), and the same lesson recorded in build-and-load-CONTEXT.md §6.
(dolist (s (list :cl-ppcre :clsql :hunchentoot :cl-json :cl-csv :cl-who :cl-base64
                 :ironclad :secure-random :drakma :cl-yaml
                 ;; S8: :uuid was MISSING, and the gap only showed when the LEGACY order files
                 ;; joined this list — they stamp CONTEXT_ID with (uuid:make-v1-uuid), so the
                 ;; reader answered "Package UUID does not exist" and the whole file was
                 ;; reported as unreadable. A dependency missing from the harness is
                 ;; indistinguishable from a broken source file; that is the lesson this list's
                 ;; own comment states, and it caught its own list this time.
                 :uuid))
  (ql:quickload s :silent t))
;; the tree's files carry [ … ] SQL literals, so CLSQL's reader syntax must be on BEFORE
;; they can be read at all — otherwise every invoice file looks like a reader error
(eval '(clsql:file-enable-sql-reader-syntax))

(defpackage :nst-preflight (:use :cl))
(in-package :nst-preflight)

(defparameter *repo* "/home/ubuntu/ninestores/")

(defparameter *files*
  '(;; the checkers themselves: a check that does not look at its own file cannot find its
    ;; own mistakes — which is how the first version shipped with three false positives
    "aiharness/deepseek/tools/nst-preflight.lisp"
    "aiharness/deepseek/tools/nst-verify-doc-numbering.lisp"
    ;; added in S6, AFTER it had already cost an hour of paren archaeology: a new checker
    ;; must be in this list the moment it exists, because §1's reader check is what catches
    ;; an unbalanced tool — and a tool that will not load cannot run its own self-check.
    "aiharness/deepseek/tools/nst-order-mirror-check.lisp"
    ;; the story's change set
    "hhub/core/dod-bl-utl.lisp"
    "hhub/core/nst-sch-mig.lisp"
    "hhub/invoice/nst-bl-invh.lisp"
    "hhub/invoice/templates/invoicesettings.lisp"
    "hhub/customer/nst-dal-Customer.lisp"
    "hhub/customer/nst-bl-Customer.lisp"
    ;; S8 retouched these three legacy files (the status vocabulary), so they join the change
    ;; set: an edit to a 600-line legacy file is exactly where an unbalanced paren hides.
    "hhub/order/dod-bl-ord.lisp"
    "hhub/order/dod-bl-odt.lisp"
    "hhub/order/dod-ui-odt.lisp"
    "hhub/order/nst-dal-ordh.lisp"
    "hhub/order/nst-dal-orditm.lisp"
    "hhub/order/nst-bl-ordh.lisp"
    "hhub/order/nst-bl-orditm.lisp"
    ;; S12/S13: the order's Tier-2 routes, the assembler, and the two files that carry the bindings.
    ;; A binding written in the wrong position inside its own file aborts the LOAD (not the compile),
    ;; which is why nst-binding-order-check exists beside this list; these two are here so the reader
    ;; balance check covers them, since a route file is exactly where a deep nesting would hide one.
    "hhub/order/nst-bl-ordhapi.lisp"
    "hhub/order/nst-bl-orditmapi.lisp"
    ;; S8b retouched the identity migration (two bugs its own dry run found), so it joins the
    ;; change set: it is an upgrade file, deliberately NOT in either build list, which means
    ;; the compiler never sees it — this reader check is the only structural check it gets.
    "installation/upgrades/nst-dbu-ordnum-identity.lisp"
    "installation/upgrades/nst-dbu-order-invariants.lisp"
    ;; D20: the one legacy class touched — the ORDNUM slot added to dod-vendor-orders so the assembly
    ;; can stamp the minted number into every vendor row.
    "hhub/order/dod-dal-ord.lisp"
    "hhub/package/compile.lisp"
    "hhub/nstores.asd"
    "installation/upgrades/nst-dbu-doc-counter.lisp"
    "installation/upgrades/nst-dbu-ordnum-identity.lisp")
  "The files of the CURRENT story's change set. Add each story's files as it lands: a check
   that does not look at a file cannot find anything in it.")

(defparameter *reserved-mysql-80*
  '("LAST_VALUE" "FIRST_VALUE" "NTH_VALUE" "RANK" "DENSE_RANK" "ROW_NUMBER" "CUME_DIST"
    "NTILE" "PERCENT_RANK" "LAG" "LEAD" "OVER" "WINDOW" "GROUPS" "ROWS" "RECURSIVE"
    "LATERAL" "SYSTEM" "EMPTY" "EXCEPT" "JSON_TABLE" "FUNCTION" "OF")
  "MySQL 8.0 keywords a hand-written statement cannot use bare. Curated, not exhaustive:
   these are the ones a schema author would plausibly reach for. LAST_VALUE is first
   because it is the one that already cost a live migration.")

(defun read-file (path)
  "The whole file as a string. Read LINE BY LINE rather than by (file-length): that returns
   BYTES while the stream yields CHARACTERS, so a file with any multibyte character (this
   tree is full of them) would be mis-sized — truncated or padded — and the reader check
   would then report a file as unbalanced for the wrong reason. (The same latent bug exists
   in ../tools/nst-verify-doc-numbering.lisp, which has not yet bitten because its files
   happen to be read whole.)"
  (with-open-file (s (merge-pathnames path *repo*) :external-format :utf-8)
    (with-output-to-string (out)
      (loop for line = (read-line s nil :eof)
            until (eq line :eof)
            do (write-string line out) (write-char #\Newline out)))))

(defun line-of (text pos)
  (1+ (count #\Newline text :end (min pos (length text)))))

;;; ── 1. delimiter balance, decided by the reader ─────────────────────────────

(defun check-reader-balance ()
  "Each file must READ to EOF. Delegates the whole question to the Lisp reader, which
   implements comments, block comments, strings, escapes and character literals exactly —
   and is the same reader the compiler uses, so it cannot disagree with it.

   ⚠ TEXT AND START ARE BOUND OUTSIDE THE HANDLER-CASE ON PURPOSE. A handler-case clause
   is NOT inside the protected body's lexical scope: the first version bound START inside
   it and reported the failing line from the handler, so instead of a diagnosis the file
   crashed with an unbound variable — found only by MUTATION-TESTING this check against an
   actually-unbalanced file, which is the only way a failure path is ever exercised."
  (format t "~&== 1. delimiter balance — does the Lisp READER reach EOF~%")
  (let ((bad 0))
    (dolist (f *files*)
      (let ((text nil) (start 0) (count 0))
        (handler-case
            (progn
              (setf text (read-file f))
              (let ((stream (make-string-input-stream text))
                    (*read-eval* nil)
                    (*package* (find-package :cl-user)))
                (loop for form = (progn (setf start (file-position stream))
                                        (read stream nil :eof))
                      until (eq form :eof)
                      do (incf count)))
              (if (zerop count)
                  (progn (incf bad)
                         (format t "   FAIL  ~A: the reader found NO top-level form — wrong path?~%" f))
                  (format t "   ok    ~A (~D top-level forms)~%" f count)))
          (end-of-file ()
            (incf bad)
            (format t "   FAIL  ~A: EOF INSIDE a form. The innermost unclosed form begins at line ~D —~%         that is where a closing delimiter is missing. (The compiler says the same~%         thing as 'end of file … in form starting at line N'.)~%"
                    f (line-of text start)))
          (error (c)
            (incf bad)
            (format t "   FAIL  ~A: the reader refused the file: ~A~%" f c)))))
    (values bad)))

;;; ── 2. SQL identifier quoting ───────────────────────────────────────────────

(defun sql-statements (text)
  "The double-quoted strings in TEXT that ARE SQL statements.

   ⚠ TWO FAILED HEURISTICS ARE RECORDED HERE. The first matched any string CONTAINING a SQL
   verb, and reported LAST_VALUE inside a prose paragraph and FUNCTION inside another. The
   second anchored on the first word — `(?i)^\\s*CREATE` — and then matched the ENGLISH word:
   a docstring beginning \"Create an order in the SESSION tenant …\" was scanned as SQL and
   reported the word OF as an unquoted identifier. Both were the same mistake: a checker that
   cries wolf.

   So the test is now NARROW and CASE-SENSITIVE: a real statement opens with a two-word
   construct that prose does not. Anything written lowercase would be missed — accepted
   deliberately, because house style is uppercase SQL and a trustworthy check beats a broad
   one. (A missed statement is a gap this note names; a false positive is a habit of ignoring
   the check.)"
  (remove-if-not
   (lambda (sql)
     (cl-ppcre:scan "^(CREATE (TABLE|UNIQUE|INDEX|VIEW|TRIGGER)|ALTER TABLE|DROP TABLE|INSERT INTO|DELETE FROM|SELECT \\S|UPDATE `)"
                    (string-left-trim '(#\Space #\Tab #\Newline #\Return) sql)))
   (mapcar (lambda (s) (subseq s 1 (1- (length s))))
           (cl-ppcre:all-matches-as-strings "\"(?:[^\"\\\\]|\\\\.)*\"" text))))

(defun check-sql-quoting ()
  (format t "~&== 2. SQL identifier quoting — a bare reserved word stops the statement on the LIVE database~%")
  (let ((bad 0) (statements 0))
    (dolist (f *files*)
      (handler-case
          (dolist (quoted (sql-statements (read-file f)))
            (let ((sql quoted))
              (incf statements)
              (let* ((stripped (cl-ppcre:regex-replace-all "`[^`]*`" sql ""))
                     (hits (remove-if-not (lambda (w)
                                            (cl-ppcre:scan (format nil "\\b~A\\b" w) stripped))
                                          *reserved-mysql-80*)))
                (when hits
                  (incf bad)
                  (format t "   FAIL  ~A: a statement uses ~{~A~^, ~} unquoted. Quote EVERY identifier:~%         ~A~%"
                          f hits (subseq sql 0 (min 88 (length sql))))))))
        (error (c) (incf bad) (format t "   FAIL  ~A: could not read: ~A~%" f c))))
    (cond
      ((plusp bad)
       (format t "   --    ~D statement(s) scanned~%" statements))
      ((zerop statements)
       (incf bad)
       (format t "   FAIL  ZERO SQL statements found across ~D files — this check is passing~%~
                  ~&         VACUOUSLY. Every migration in the set has at least one CREATE.~%"
               (length *files*)))
      (t (format t "   ok    ~D SQL statement(s) scanned, none uses a bare reserved word~%" statements)))
    (values bad)))

;;; ── 3. build registration: a new hhub/** file needs BOTH lists ──────────────

(defparameter *hhub-new-files*
  '("order/nst-dal-ordh.lisp" "order/nst-dal-orditm.lisp" "order/nst-bl-ordh.lisp"
    ;; S12/S13's two new files: check 3 asserts each is in compile.lisp AND nstores.asd, which is the
    ;; check that catches "compiled to a project-local fasl nobody serves".
    "order/nst-bl-ordhapi.lisp" "order/nst-bl-orditmapi.lisp")
  "The hhub/** files this BATCH has added. Each needs TWO registrations — package/compile.lisp
   (what compile-production compiles) and nstores.asd (what the SERVER actually loads) — and
   until this section existed, nothing checked the second one. A file in the first list only is
   compiled to a project-local fasl nobody serves: it looks built and does nothing.")

(defun source-path-list (path pattern &optional (skip 0))
  "Every PATH (matched by PATTERN) named in the file at PATH, with the first SKIP characters of
   each match dropped, to strip a wrapper such as the asd file-entry prefix.

   NO QUOTE CHARACTERS IN A DOCSTRING, and this file has now broken that rule twice: an
   unescaped double quote ENDS the string and the words after it become code. The reader
   reports it plainly, but this tool cannot report it about ITSELF — a tool that will not
   LOAD never reaches its own checks, which is exactly what happened to the first version
   of this section. The self-check protects the files this tool READS; for the tool
   itself, run the compile in the header recipe."
  (remove-duplicates
   (mapcar (lambda (hit) (subseq hit skip))
           (cl-ppcre:all-matches-as-strings pattern (read-file path)))
   :test #'string=))

(defun check-build-registration ()
  (format t "~&== 3. build registration — a new hhub/** file needs BOTH lists~%")
  (let* ((compiled (source-path-list "hhub/package/compile.lisp" "[A-Za-z0-9/_-]+\\.lisp"))
         (loaded (mapcar (lambda (p) (concatenate 'string p ".lisp"))
                         (source-path-list "hhub/nstores.asd" "\\(:file \"[A-Za-z0-9/_-]+"
                                           (length "(:file \""))))
         (bad 0))
    (dolist (f *hhub-new-files*)
      (let ((in-compile (and (member f compiled :test #'string=) t))
            (in-asd (and (member f loaded :test #'string=) t)))
        (if (and in-compile in-asd)
            (format t "   ok    ~A is in compile.lisp AND nstores.asd~%" f)
            (progn
              (incf bad)
              (format t "   FAIL  ~A — compile.lisp: ~:[MISSING~;present~], nstores.asd: ~:[MISSING~;present~].~%~
                         ~&         A file missing from the asd is compiled and NEVER LOADED.~%"
                      f in-compile in-asd)))))
    ;; INFORMATION, not a failure: the two lists differ legitimately (test/* files are
    ;; compile-only), and where they differ otherwise the reason is worth seeing.
    (let ((compiled-only (set-difference compiled loaded :test #'string=))
          (loaded-only (set-difference loaded compiled :test #'string=)))
      (format t "   note  ~D compiled-but-not-loaded (test/* excluded below), ~D loaded-but-not-compiled~%"
              (length compiled-only) (length loaded-only))
      (dolist (f (remove-if (lambda (x) (and (> (length x) 5) (string= "test/" x :end2 5))) compiled-only))
        (format t "         compiled, never loaded: ~A~%" f))
      (dolist (f loaded-only)
        (format t "         loaded, never compiled: ~A~%" f)))
    (values bad)))

;;; ── 4. the checks found their inputs ────────────────────────────────────────

(defun check-non-vacuity ()
  (format t "~&== 4. every check found its inputs — a silent empty result is a FAIL, not a pass~%")
  (let ((bad 0))
    (if (< (length *files*) 3)
        (progn (incf bad)
               (format t "   FAIL  the file list is nearly empty — nothing is being checked~%"))
        (format t "   ok    ~D file(s) in the change set~%" (length *files*)))
    (dolist (f *files*)
      (handler-case
          (let ((text (read-file f)))
            ;; AN EMPTY FILE IS A FAIL; a SHORT one is only a note. The first version failed
            ;; anything under 4 lines, which is wrong for a legitimately small file — and a
            ;; check that cries wolf teaches you to ignore it.
            (cond ((zerop (length text))
                   (incf bad)
                   (format t "   FAIL  ~A: the file is EMPTY — the wrong path?~%" f))
                  ((< (count #\Newline text) 4)
                   (format t "   note  ~A is only ~D line(s) — short, but read~%"
                           f (1+ (count #\Newline text))))))
        (error (c) (incf bad) (format t "   FAIL  ~A: could not read: ~A~%" f c))))
    (when (zerop bad) (format t "   ok    every file readable and non-trivial~%"))
    (values bad)))

;;; ── 4. what only the database can answer ────────────────────────────────────

(defun print-db-steps ()
  (format t "~&== 5. NOT CHECKABLE HERE — run these BEFORE the story is APPLIED~%")
  (format t "~
  (a) THE LIVE SCHEMA of every table the story touches. The create-script in this repo is~%~
      NOT the live schema: believing it produced three wrong decisions in this batch~%~
      (STATUS is char(3) so DRAFT is unstorable; ORDNUM has NO unique key; DOD_ORDER has~%~
      no VENDOR_ID column at all).~%~
        SHOW CREATE TABLE <t>;   SHOW COLUMNS FROM <t>;   SHOW INDEX FROM <t>;~%~
  (b) THE SHAPE of every column whose value Lisp code consumes. A declared type is not~%~
      what the reader RETURNS: clsql:decode-date answers a DATE struct with FOUR values~%~
      (day month year dow), a wall-time with SIX, and SIGNALS on a raw integer. Probe the~%~
      reader, not the DDL.~%~
  (c) THE DATA, before a migration is applied. 485 of 485 rows had a NULL ORDNUM, so the~%~
      repair was to INVENT 485 numbers, not copy them — and the copy attempt returned~%~
      'Changed: 0' because it was copying NULL into NULL.~%~
        SELECT COUNT(*) FROM <t> WHERE <col> IS NULL;~%~
        SELECT <col>, COUNT(*) FROM <t> GROUP BY <col> HAVING COUNT(*) > 1;~%~
  (d) THE OTHER TOOL — aiharness/deepseek/tools/nst-verify-doc-numbering.lisp — owns the~%~
      mirror-list/class checks, the counter SQL's quoting, and the mutation-tested~%~
      document-numbering checks. Run it too; this file does not duplicate it.~%~
  (e) IS THE IMAGE CURRENT? before any REPL or migration step. A stale image reports~%~
      today's functions as undefined and yesterday's defun as the live one, and a stale~%~
      ASDF cache does the same silently. CONTENT beats timestamps — an earlier version of~%~
      this note compared times of DAY and called a 24-hour-old cache current:~%~
        strings /home/hunchentoot/.cache/common-lisp/sbcl-2.6.8-linux-x64/home/ubuntu/ninestores/hhub/core/dod-bl-utl.fasl | grep -c <symbol-you-just-added>~%"))

;;; ── run ─────────────────────────────────────────────────────────────────────

(format t "~&=== nst preflight — ~D file(s) in the current change set ===~%" (length *files*))
(let ((bad (+ (check-reader-balance) (check-sql-quoting)
              (check-build-registration) (check-non-vacuity))))
  (print-db-steps)
  (format t "~&=== preflight: ~:[FAIL~;PASS~] (~D problem(s)) ===~%" (zerop bad) bad)
  (format t "~&This is the OFFLINE half only. (a)-(e) need a database, an image or a human —~%~
             ~&and they are where this batch's most expensive mistakes were made.~%")
  (sb-ext:exit :code (if (zerop bad) 0 1)))
