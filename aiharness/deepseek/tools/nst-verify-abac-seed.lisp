;;; nst-verify-abac-seed.lisp — the OFFLINE checks for an ABAC policy/transaction seed file.
;;;
;;;   cd /home/ubuntu/ninestores
;;;   sbcl --noinform --non-interactive --load aiharness/deepseek/tools/nst-verify-abac-seed.lisp
;;;
;;; Exit 0 = every check passed. 1 = at least one FAIL, named with the row.
;;;
;;; ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
;;;
;;; It is written because the first version of the order API seed shipped with TWO defects that no
;;; existing check could see, and a human reading it found both:
;;;
;;;   * SEVEN of its ten DESCRIPTIONS were 102-165 characters against a `varchar(100)` column, on a
;;;     database running STRICT_TRANS_TABLES. That is Error 1406 — and the failure mode is not a
;;;     refused migration: apply-migrations catches per-migration and CONTINUES while never recording
;;;     the version, so the seed re-runs forever, half-applied. The ABAC skill claimed MySQL
;;;     truncates silently; this database does not.
;;;   * ALL TEN `POLICY_FUNC` values pointed at functions that DO NOT EXIST. Every pre-existing API
;;;     seed names a real function in hhub/core/dod-ui-pol.lisp, and a policy whose function is
;;;     missing DENIES EVERY CALL on the day the PEP starts consulting the rows (the skill's traps 2
;;;     and 14).
;;;
;;; Neither is visible by reading the file casually, both are invisible offline to every other tool
;;; in this directory, and both are cheap to decide mechanically. That is the definition of a check.
;;;
;;; ⚠ IT READS SOURCE AND DOES NOT TOUCH THE DATABASE. The column widths it compares against are
;;; MEASURED values, quoted in *column-widths* with the query that produces them — re-run that query
;;; if a migration ever widens a column.
;;;
;;; ⚠ A STUB clsql package plus a readtable in which `[`/`]` are whitespace, so the file is readable
;;; without loading CLSQL. `ql:quickload :clsql` collides over uffi in this environment.

(let ((*read-eval* nil))
  (unless (find-package :clsql) (make-package :clsql))
  (dolist (name '("FILE-ENABLE-SQL-READER-SYNTAX" "SELECT" "SQL-AND"))
    (export (intern name (find-package :clsql)) (find-package :clsql))))

(defparameter *seed-file* "installation/upgrades/nst-dbu-ordapi-policy-transaction.lisp")
(defparameter *policy-function-file* "hhub/core/dod-ui-pol.lisp")
(defparameter *expected-pairs* 10
  "The ten BOUND order API endpoints: seven customer paths and three vendor paths. The two
   deliberately-unbound item routes (route-orditm-list / -fetch) get no seed, because a transaction
   row describes an ADDRESSABLE path.")

(defparameter *column-widths*
  '(("DOD_AUTH_POLICY.NAME" . 50)
    ("DOD_AUTH_POLICY.DESCRIPTION" . 100)
    ("DOD_AUTH_POLICY.POLICY_FUNC" . 255)
    ("DOD_BUS_TRANSACTION.NAME" . 100)
    ("DOD_BUS_TRANSACTION.URI" . 100)
    ("DOD_BUS_TRANSACTION.TRANS_TYPE" . 15)
    ("DOD_BUS_TRANSACTION.TRANS_FUNC" . 100))
  "MEASURED, not assumed — from
   SELECT column_name, column_type FROM information_schema.columns
    WHERE table_schema='hhubdb' AND table_name IN ('DOD_AUTH_POLICY','DOD_BUS_TRANSACTION');
   ⚠ AND THE DATABASE RUNS STRICT_TRANS_TABLES (SELECT @@sql_mode), so over-long is Error 1406, not
   a silent truncation.")

(defvar *problems* 0)
(defvar *checks* 0)

(defun ok (fmt &rest args)
  (incf *checks*) (format t "   ok    ~A~%" (apply #'format nil fmt args)))

(defun fail (fmt &rest args)
  (incf *problems*) (format t "   FAIL  ~A~%" (apply #'format nil fmt args)))

(defun source-readtable ()
  (let ((rt (copy-readtable nil)))
    (set-syntax-from-char #\[ #\Space rt)
    (set-syntax-from-char #\] #\Space rt)
    rt))

(defun read-all-forms (path)
  (with-open-file (in path :direction :input)
    (let ((*package* (find-package :cl-user))
          (*readtable* (source-readtable))
          (*read-eval* nil))
      (let ((forms '()))
        (loop for form = (handler-case (read in nil :eof)
                           (error (e) (error "~A does not READ: ~A" path e)))
              until (eq form :eof) do (push form forms))
        (nreverse forms)))))

(defun name-is (x name) (and (symbolp x) (string= (symbol-name x) name)))

(defun collect-calls (form head)
  "Every sublist of FORM whose car is the symbol HEAD, in source order."
  (let ((found '()))
    (labels ((walk (x)
               (when (consp x)
                 (when (name-is (car x) head) (push x found))
                 (dolist (sub x) (walk sub)))))
      (walk form))
    (nreverse found)))

(defun positional-args (call)
  "The arguments of CALL before its first keyword — the positional ones, whatever their type.
   ⚠ NOT 'THE LEADING STRINGS': insert-bus-transaction's second argument is the VARIABLE
   `order-uri` (a let binding of the enclosing form), so a scan that stopped at the first non-string
   returned one element where three were expected, and the destructuring-bind below died on it.
   That was this checker's first bug, and it is the reason the values are RESOLVED (see
   resolve-value) rather than assumed to be literals."
  (loop for a in (cdr call) until (keywordp a) collect a))

(defun let-bindings (form)
  "symbol-name -> literal value, for every (let ((a 1) (b \"x\")) …) inside FORM."
  (let ((bindings '()))
    (labels ((walk (x)
               (when (consp x)
                 (when (and (member (and (symbolp (car x)) (symbol-name (car x)))
                                    '("LET" "LET*") :test #'string=)
                            (consp (cdr x)))
                   (dolist (pair (first (cdr x)))
                     (when (and (consp pair) (symbolp (car pair))
                                (or (stringp (second pair)) (integerp (second pair))))
                       (push (cons (symbol-name (car pair)) (second pair)) bindings))))
                 (dolist (sub x) (walk sub)))))
      (walk form))
    bindings))

(defun resolve-value (x bindings)
  "X as a literal: a string/integer as itself, a SYMBOL as its let binding (or NIL if unknown)."
  (cond ((or (stringp x) (integerp x)) x)
        ((symbolp x) (cdr (assoc (symbol-name x) bindings :test #'string=)))
        (t nil)))

(defun keyword-arg (call key)
  "The value of KEY in CALL's plist part, or NIL.
   ⚠ THE PLIST STARTS AFTER THE POSITIONAL ARGUMENTS, not at the head: pairing from the head puts the
   function name opposite the first argument and every keyword one slot out."
  (let ((rest (member-if #'keywordp (cdr call))))
    (loop for (k v) on rest by #'cddr when (eq k key) return v)))

(defun policy-function-exists-p (name)
  "Is there a (defun NAME …) in the policy file? Scanned as TEXT: the question is whether the symbol
   is defined ANYWHERE in that file, and the fdefinition would need the whole tree loaded to ask."
  (with-open-file (in *policy-function-file*)
    (loop for line = (read-line in nil :eof)
          until (eq line :eof)
          thereis (search (format nil "(defun ~A " name) line))))

(defun value-fits-p (label value width)
  "Does VALUE fit its MEASURED column WIDTH? Reports and returns NIL when it does not.
   ⚠ A DOTTED PAIR IS NOT A LIST: the first version built (cons LABEL (cons VALUE WIDTH)) and then
   read it as (label value width), so it compared a string's length against a CONS and died. Three
   arguments, three positions, one helper — the shape that cannot be misread."
  (let ((len (length (if (stringp value) value (princ-to-string value)))))
    (if (> len width)
        (progn
          (fail "~A is ~D chars but the column is ~D: ~S" label len width value)
          nil)
        t)))

;;; ── the checks ──────────────────────────────────────────────────────────────

(format t "~%== nst-verify-abac-seed — ~A~%" *seed-file*)

(let* ((forms (read-all-forms *seed-file*))
       (migration (find-if (lambda (f) (and (consp f) (name-is (car f) "DEFUN"))) forms)))
  (if (null migration)
      (fail "no defun found — the file changed shape, so every check below is vacuous")
      (let* ((bindings (let-bindings migration))
             (policies (collect-calls migration "INSERT-AUTH-POLICY"))
             (transactions (collect-calls migration "INSERT-BUS-TRANSACTION")))
        (ok "found ~D policy call(s) and ~D transaction call(s)" (length policies) (length transactions))

        ;; 1. one pair per bound endpoint, and the pair count is the endpoint count
        (if (= (length policies) (length transactions) *expected-pairs*)
            (ok "one policy per transaction per bound endpoint (~D pairs)" *expected-pairs*)
            (fail "expected ~D pairs; found ~D policies and ~D transactions"
                  *expected-pairs* (length policies) (length transactions)))

        ;; 2. AC (b): each transaction links to ITS OWN policy, structurally
        (let ((linked (count-if (lambda (t-call) (name-is (keyword-arg t-call :policy-id) "POLICY-ID"))
                                transactions)))
          (if (= linked (length transactions))
              (ok "every transaction passes :policy-id policy-id — the binding of its own enclosing let")
              (fail "~D transaction(s) do NOT link to the local policy-id: ~{~A~^, ~}"
                    (- (length transactions) linked)
                    (loop for t-call in transactions
                          unless (name-is (keyword-arg t-call :policy-id) "POLICY-ID")
                            collect (first (positional-args t-call))))))

        ;; 3. every string fits its column (strict mode: over-long is Error 1406)
        (let ((bad 0))
          (dolist (p policies)
            (destructuring-bind (name description policy-func)
                (mapcar (lambda (a) (resolve-value a bindings)) (positional-args p))
              (unless (value-fits-p "policy NAME" name
                                    (cdr (assoc "DOD_AUTH_POLICY.NAME" *column-widths* :test #'string=)))
                (incf bad))
              (unless (value-fits-p "DESCRIPTION" description
                                    (cdr (assoc "DOD_AUTH_POLICY.DESCRIPTION" *column-widths* :test #'string=)))
                (incf bad))
              (unless (value-fits-p "POLICY_FUNC" policy-func
                                    (cdr (assoc "DOD_AUTH_POLICY.POLICY_FUNC" *column-widths* :test #'string=)))
                (incf bad))))
          (dolist (t-call transactions)
            (destructuring-bind (name uri type)
                (mapcar (lambda (a) (resolve-value a bindings)) (positional-args t-call))
              (unless (value-fits-p "transaction NAME" name
                                    (cdr (assoc "DOD_BUS_TRANSACTION.NAME" *column-widths* :test #'string=)))
                (incf bad))
              (unless (value-fits-p "URI" uri
                                    (cdr (assoc "DOD_BUS_TRANSACTION.URI" *column-widths* :test #'string=)))
                (incf bad))
              (unless (value-fits-p "TRANS_TYPE" type
                                    (cdr (assoc "DOD_BUS_TRANSACTION.TRANS_TYPE" *column-widths* :test #'string=)))
                (incf bad))
              (unless (value-fits-p "TRANS_FUNC" (keyword-arg t-call :trans-func)
                                    (cdr (assoc "DOD_BUS_TRANSACTION.TRANS_FUNC" *column-widths* :test #'string=)))
                (incf bad))))
          (when (zerop bad)
            (ok "every string fits its MEASURED column width, under STRICT_TRANS_TABLES")))

        ;; 4. a policy whose function does not exist denies every call once the PEP lands
        (let ((missing (loop for p in policies
                             for func = (third (positional-args p))
                             unless (policy-function-exists-p func) collect func)))
          (if missing
              (fail "POLICY_FUNC points at nothing (~D): ~{~A~^, ~} — add the defun to ~A"
                    (length missing) missing *policy-function-file*)
              (ok "every POLICY_FUNC exists in ~A" *policy-function-file*)))

        ;; 5. TRANS_FUNC is the LOOKUP KEY: unique per endpoint, and the shape apidefs2 builds
        (let ((funcs (mapcar (lambda (t-call) (keyword-arg t-call :trans-func)) transactions)))
          (let ((dups (loop for f in funcs when (> (count f funcs :test #'string=) 1) collect f)))
            (if dups
                (fail "TRANS_FUNC is not unique — transactions cannot be told apart: ~{~A~^, ~}"
                      (remove-duplicates dups :test #'string=))
                (ok "every TRANS_FUNC is unique (~D keys) — it is the lookup key, not NAME" (length funcs))))
          (let ((malformed (remove-if (lambda (f)
                                        (and (stringp f) (> (length f) 4)
                                             (string= "api " f :end2 4)
                                             (member (subseq f 4 (or (position #\Space f :start 4) 4))
                                                     '("GET" "POST" "PUT" "DELETE" "PATCH")
                                                     :test #'string=)))
                                      funcs)))
            (if malformed
                (fail "TRANS_FUNC must read \"api <METHOD> <path>\" as apidefs2 builds it: ~{~A~^, ~}"
                      malformed)
                (ok "every TRANS_FUNC has the \"api <METHOD> <path>\" shape apidefs2 builds"))))

        ;; 6. the URI is the COLLECTION PREFIX while TRANS_FUNC keeps the template
        (let ((bad '()))
          (dolist (t-call transactions)
            (destructuring-bind (name uri type)
                (mapcar (lambda (a) (resolve-value a bindings)) (positional-args t-call))
              (declare (ignore name type))
              (let ((trans-func (keyword-arg t-call :trans-func)))
                (when (and (stringp trans-func) (stringp uri)
                           (not (search uri trans-func)))
                  (push (cons uri trans-func) bad)))))
          (if bad
              (fail "URI is not a prefix of TRANS_FUNC's path (a template URI denies every call): ~{~A~^ ; ~}"
                    (mapcar (lambda (p) (format nil "~A vs ~A" (car p) (cdr p))) bad))
              (ok "every URI is the collection prefix of its TRANS_FUNC path"))))))

(format t "~%== nst-verify-abac-seed: ~:[FAIL~;PASS~] — ~D check(s), ~D problem(s) ==~%"
        (zerop *problems*) *checks* *problems*)
(finish-output)
(sb-ext:exit :code (if (zerop *problems*) 0 1))
