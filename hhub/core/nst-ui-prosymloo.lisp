;;; nst-ui-prosymloo.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
;; nst-bl-prosymloo.lisp came from Project Symbol Lookup
(in-package :nstores)

;; *meta-registry* populated at load time by (meta ...) forms
(defvar *meta-registry* (make-hash-table :test #'equal))

;; Query-API cache (see the QUERY API section): rebuilt automatically whenever
;; the generated table object changes, so a regeneration needs no manual reset.
(defvar *funcinfo-index* nil
  "NAME -> entry, the index behind the funcinfo-* query API.")
(defvar *funcinfo-index-source* nil
  "The table object *FUNCINFO-INDEX* was built from.")

(defmacro meta (name alist)
  "Alist is passed already quoted by the caller.
   Stored directly — no transformation needed."
  `(setf (gethash ,(symbol-name name) *meta-registry*)
         (list :name ,(symbol-name name)
               :meta ,alist)))         ; no ' here — caller already quoted it

         ; :meta key + quoted plist = no evaluation

(defun get-project-symbols (system-name)
  "Collects ALL defined symbols (internal and external functions, macros, and classes) 
   from the project's packages."
  (let ((symbols '())
        ;; Now we rely on the hardcoded package name from packages.lisp
        (project-packages (list (find-package :com.nstores.app)))) 
    (unless (first project-packages)
      (error "Project package :COM.NSTORES.APP not found. Ensure the system is loaded."))
    (dolist (pkg project-packages)
      (do-symbols (s pkg)
        ;; Check 1: Is the symbol defined as a function, macro, or class?
        (when (or (fboundp s) (find-class s nil))
          ;; Check 2: Does the symbol belong to this package? 
          ;; This is the critical filter to exclude symbols from dependencies (like :CL or :ASDF)
          (when (eq (symbol-package s) pkg) 
            (push s symbols)))))
    (remove-duplicates symbols)))

(defun get-project-packages (system-name)
  "Returns a list containing the single main package for the :NSTORES system, 
   based on the packages.lisp file."
  (declare (ignore system-name)) ; Ignore the system-name argument as the package is hardcoded
  (let ((pkg (find-package :com.nstores.app)))
    (if pkg
        (list pkg)
        (error "The main project package :COM.NSTORES.APP is not defined or loaded!"))))

;;; ============================================================================
;;; ENTRY ACCESS — one accessor for the generator, the query API and nst-bl-ollama
;;; ============================================================================

(defun entry-field (entry key &optional default)
  "Reads KEY from a lookup ENTRY.
   Understands the current alist entries and the legacy
   (NAME TYPE FILE DOC KEYWORDS META) lists, so an older generated file still
   loads and can still be queried."
  (when (consp entry)
    (if (consp (first entry))
        (let ((hit (assoc key entry)))
          (if hit (cdr hit) default))
        (let ((pos (case key
                     (:name 0) (:type 1) (:file 2) (:docstring 3) (:keywords 4) (:meta 5)
                     (t nil))))
          (if (and pos (< pos (length entry))) (nth pos entry) default)))))

(defun entry-file-line (entry)
  "FILE:LINE for an entry, falling back to the file alone when the line is unknown."
  (let ((file (entry-field entry :file))
        (line (entry-field entry :line)))
    (if (and (stringp file) (plusp (length file)) line)
        (format nil "~A:~A" file line)
        (or (and (stringp file) file) ""))))

(defun short-file-name (path)
  "Basename of PATH, or \"\" when there is none."
  (if (and (stringp path) (plusp (length path)))
      (or (file-namestring path) path)
      ""))

;;; ============================================================================
;;; SOURCE ACCESS — the DAG is derived from the source, once per file
;;; ============================================================================

(defvar *sym-source-cache* (make-hash-table :test #'equal)
  "FILE -> top-level forms, cached so every source file is read at most once.")

(defvar *sym-source-text* (make-hash-table :test #'equal)
  "FILE -> the file's text, so one read serves both the form scan and the line index.")

(defvar *sym-read-errors* (make-hash-table :test #'equal)
  "FILE -> number of forms that could not be read, for the post-run report.")

(defvar *sym-unreadable-files* (make-hash-table :test #'equal)
  "FILE -> condition string, for files that could not be opened or parsed at all.")

(defvar *lookup-quiet* t
  "When true — the default — generating the lookup file prints nothing at all, not
   even a warning about a source file it could not read. Nothing is lost: skipped
   forms land in *SYM-READ-ERRORS*, unopenable files in *SYM-UNREADABLE-FILES*, and
   report-lookup-generation or nst-lookup-health prints both on demand. Bind it to
   NIL to watch the scan live.")

(defun lookup-warn (control &rest args)
  "WARN unless *LOOKUP-QUIET*, so a regeneration can be completely silent."
  (unless *lookup-quiet* (apply #'warn control args)))

(defun symbol-source-readtable ()
  "Readtable used to scan source files: standard syntax, with CLSQL's SQL
   bracket syntax read as whitespace. Files that call
   (clsql:file-enable-sql-reader-syntax) are otherwise unreadable — `[:phone]`
   is read as a package marker for a package named \"[\" — and a file that cannot
   be read contributes no call edges at all. Brackets become whitespace rather
   than parentheses so an unbalanced bracket can never swallow the rest of a
   file: the SQL sub-forms flatten, and the project calls inside them survive."
  (let ((rt (copy-readtable nil)))
    (set-syntax-from-char #\[ #\Space rt)
    (set-syntax-from-char #\] #\Space rt)
    rt))

(defun top-level-form-strings (text)
  "Splits TEXT into top-level form strings.
   Each form is read independently, so one unreadable form can no longer
   desynchronise the reader and swallow the rest of the file — that failure mode
   cost whole files their call edges. Comments, \"strings\", #\\c character
   literals and #| block comments |# are skipped while counting parentheses."
  (let ((chunks '())
        (n (length text))
        (i 0)
        (start nil)
        (depth 0))
    (labels ((skip-string (j)
               (incf j)
               (loop while (< j n)
                     do (let ((c (char text j)))
                          (cond ((char= c #\\) (incf j 2))
                                ((char= c #\") (incf j) (return))
                                (t (incf j)))))
               j)
             (skip-block-comment (j)
               (incf j 2)
               (let ((lvl 1))
                 (loop while (and (< j n) (plusp lvl))
                       do (cond ((and (< (1+ j) n)
                                      (char= (char text j) #\#) (char= (char text (1+ j)) #\|))
                                 (incf lvl) (incf j 2))
                                ((and (< (1+ j) n)
                                      (char= (char text j) #\|) (char= (char text (1+ j)) #\#))
                                 (decf lvl) (incf j 2))
                                (t (incf j))))
                 j)))
      (loop while (< i n)
            do (let ((c (char text i)))
                 (cond
                   ((char= c #\;)                                  ; line comment
                    (loop while (and (< i n) (not (char= (char text i) #\Newline)))
                          do (incf i)))
                   ((char= c #\") (setf i (skip-string i)))
                   ((and (char= c #\#) (< (1+ i) n) (char= (char text (1+ i)) #\|))
                    (setf i (skip-block-comment i)))
                   ((and (char= c #\#) (< (1+ i) n) (char= (char text (1+ i)) #\\))
                    (incf i 3))                                    ; #\( would miscount
                   ((char= c #\() (when (zerop depth) (setf start i)) (incf depth) (incf i))
                   ((char= c #\))
                    (decf depth)
                    (when (and start (zerop depth))
                      (push (subseq text start (1+ i)) chunks)
                      (setf start nil))
                    (when (minusp depth) (setf depth 0))           ; stray )
                    (incf i))
                   (t (incf i))))))
    (nreverse chunks)))

(defun read-source-text (file)
  "The text of FILE, cached per run: the form scan and the line index share one read."
  (or (gethash file *sym-source-text*)
      (setf (gethash file *sym-source-text*)
            (with-open-file (s file :external-format :utf-8)
              (let ((out (make-string-output-stream)))
                (loop for line = (read-line s nil nil)
                      while line
                      do (write-string line out) (write-char #\Newline out))
                (get-output-stream-string out))))))

(defun read-project-file-forms (file)
  "Reads FILE (cached) and returns its top-level forms, or NIL when unreadable.
   Reading is deliberately independent of the running image: *READ-EVAL* is off
   and SYMBOL-SOURCE-READTABLE is used, and the text is split into top-level forms
   so an unreadable form is skipped on its own. (IN-PACKAGE ...) forms are honoured."
  (multiple-value-bind (cached presentp) (gethash file *sym-source-cache*)
    (if presentp
        cached
        (setf (gethash file *sym-source-cache*)
              (handler-case
                  (let ((text (read-source-text file))
                        (*read-eval* nil)
                        (*readtable* (symbol-source-readtable))
                        (*package* (or (find-package :nstores) *package*))
                        (forms '())
                        (errors 0)
                        (reported nil))
                    (dolist (chunk (top-level-form-strings text))
                      (let ((form nil) (ok t))
                        (handler-case (setf form (read-from-string chunk nil :skip))
                          (error (e)
                            (setf ok nil)
                            (incf errors)
                            (unless reported
                              (setf reported t)
                              (lookup-warn "Call graph: skipping unreadable form in ~A (~A)."
                                           file e))))
                        (when ok
                          (when (and (consp form) (eq (first form) 'cl:in-package))
                            (let ((pkg (find-package (second form))))
                              (when pkg (setf *package* pkg))))
                          (push form forms))))
                    (when (plusp errors)
                      (setf (gethash file *sym-read-errors*) errors))
                    (nreverse forms))
                (error (e)
                  (setf (gethash file *sym-unreadable-files*) (format nil "~A" e))
                  (lookup-warn "Call graph: cannot read ~A (~A)." file e)
                  nil))))))

;;; ============================================================================
;;; DEFINITION LOCATION — which form defines a symbol, and what does it call
;;; ============================================================================

(defun definition-candidate-p (form)
  "True when FORM looks like a top-level definition form
   (DEFUN, DEFMACRO, DEFMETHOD, DEFGENERIC, DEFCLASS, DEFINE-TOOL, ...)."
  (and (proper-list-p form)
       (symbolp (first form))
       (let ((n (symbol-name (first form))))
         (and (>= (length n) 3) (string= "DEF" n :end1 3 :end2 3)))))

(defun definition-name-string (x)
  "X is a symbol or (SETF symbol): the name it defines, or NIL."
  (cond ((and (symbolp x) x) (symbol-name x))
        ((and (consp x) (eq (first x) 'setf) (symbolp (second x))) (symbol-name (second x)))
        (t nil)))

(defun struct-name-string (form)
  "The name a DEFSTRUCT / DEFINE-CONDITION defines. Its name may be wrapped in
   the (NAME options) list, which DEFINITION-NAME-STRING deliberately ignores."
  (let ((op (and (consp form) (symbolp (first form)) (symbol-name (first form)))))
    (when (and op (member op '("DEFSTRUCT" "DEFINE-CONDITION") :test #'string=))
      (let ((x (second form)))
        (cond ((symbolp x) (symbol-name x))
              ((and (consp x) (symbolp (first x))) (symbol-name (first x)))
              (t nil))))))

(defun definition-names (form)
  "Every name a definition FORM could define: the first three positions that can
   hold one (covering DEFMETHOD qualifiers and (SETF x)) plus a wrapped struct name."
  (let ((names (remove nil (list (definition-name-string (second form))
                                 (definition-name-string (third form))
                                 (definition-name-string (fourth form)))))
        (sn (struct-name-string form)))
    (if sn (cons sn names) names)))

(defun definition-of-p (form name)
  "True when FORM defines NAME. The name may sit in any of the first three
   positions, which covers DEFMETHOD qualifiers and (SETF x) definitions."
  (and (definition-candidate-p form)
       (member name (definition-names form) :test #'string=)))

(defun arglist-operator-p (op)
  "False for definition forms whose second list is not a lambda list."
  (not (member (symbol-name op)
               '("DEFCLASS" "DEF-VIEW-CLASS" "DEFSTRUCT" "DEFINE-CONDITION"
                 "DEFINE-METHOD-COMBINATION" "DEFPACKAGE")
               :test #'string=)))

(defun definition-parts (form)
  "For a definition FORM returns (values OPERATOR LAMBDA-LIST BODY-FORMS).
   Qualifier keywords between a DEFMETHOD name and its lambda list are skipped."
  (let* ((op (first form))
         (after-name (rest (rest form))))
    (loop while (and after-name (not (listp (first after-name))))
          do (pop after-name))
    (values op
            (when (arglist-operator-p op) (first after-name))
            (rest after-name))))

(defun proper-list-p (x)
  "True for a proper list (NIL included). A dotted list such as the loop
   destructuring form (NAME . PREFIXES) is not one, and walking it would signal."
  (loop for tail = x then (cdr tail)
        do (cond ((null tail) (return t))
                 ((not (consp tail)) (return nil)))))

(defun lambda-list-form-p (form)
  "Heuristic: FORM declares parameters (&KEY / &OPTIONAL / ...) and is therefore
   not a call, which keeps unknown defining macros from polluting the graph."
  (and (proper-list-p form)
       (some (lambda (e)
               (and (symbolp e)
                    (plusp (length (symbol-name e)))
                    (char= (char (symbol-name e) 0) #\&)))
             form)))

(defun collect-called-symbols (forms)
  "Every symbol of FORMS that appears in operator or function position.
   QUOTE contents, lambda lists and local binding variables are not reported."
  (let ((acc '()))
    (labels ((note (s)
               (when (and (symbolp s) s (not (keywordp s)) (not (eq s t)))
                 (pushnew s acc)))
             (walk-body (forms)
               (when (proper-list-p forms)
                 (dolist (f forms) (walk f))))
             (walk-bindings (bindings)
               (dolist (b bindings)
                 (when (and (consp b) (proper-list-p (rest b)))
                   (walk-body (rest b)))))
             (walk (form)
               (cond
                 ((not (consp form)) nil)
                 ;; Dotted data, e.g. the (NAME . PREFIXES) destructuring form of
                 ;; LOOP: its car is not a call, and REST would signal.
                 ((not (proper-list-p form)) nil)
                 ((member (first form) '(quote cl:quote) :test #'eq) nil)
                 ((member (first form) '(function cl:function) :test #'eq)
                  (let ((f (second form)))
                    (if (and (symbolp f) f) (note f) (walk f))))
                 ((member (first form) '(lambda cl:lambda) :test #'eq)
                  (walk-body (cdddr form)))
                 ((member (first form) '(let let*) :test #'eq)
                  (walk-bindings (second form))
                  (walk-body (cddr form)))
                 ((member (first form) '(flet labels macrolet) :test #'eq)
                  (dolist (def (second form)) (walk-body (cdddr def)))
                  (walk-body (cddr form)))
                 ((member (first form) '(dolist dotimes) :test #'eq)
                  (let ((spec (second form)))
                    (when (and (consp spec) (rest spec)) (walk (second spec))))
                  (walk-body (cddr form)))
                 ((member (first form) '(destructuring-bind multiple-value-bind) :test #'eq)
                  (when (third form) (walk (third form)))
                  (walk-body (cdddr form)))
                 ((member (first form) '(case ccase ecase typecase etypecase ctypecase)
                          :test #'eq)
                  (when (second form) (walk (second form)))
                  (dolist (clause (cddr form))
                    (when (consp clause) (walk-body (rest clause)))))
                 ;; A nested definition (or a DEFMETHOD's specialised lambda list
                 ;; such as ((obj invoice)), which carries no & marker): drop the
                 ;; lambda list, keep the body.
                 ((and (definition-candidate-p form) (consp (third form)))
                  (walk-body (nth-value 2 (definition-parts form))))
                 (t (note (first form))
                    (dolist (sub (rest form))
                      (unless (lambda-list-form-p sub) (walk sub)))))))
      (walk-body forms))
    (nreverse acc)))

(defun collect-definition-forms (form by-name)
  "Every definition form inside FORM, including ones nested in a wrapper such as
   (eval-when ...), (progn ...) or (when ...) — those are common in this tree and
   a top-level-only scan misses every definition inside them. Recursion stops at a
   form that defines a known project symbol, so a definition's own body is not
   re-scanned and unknown macros are still walked through."
  (cond ((not (proper-list-p form)) nil)
        ((and (definition-candidate-p form)
              (some (lambda (n) (gethash n by-name)) (definition-names form)))
         (list form))
        (t (loop for sub in form append (collect-definition-forms sub by-name)))))

(defun accessor-symbol (value)
  "VALUE is an accessor name or (SETF name): the symbol it names, else NIL."
  (cond ((and (symbolp value) value) value)
        ((and (consp value) (eq (first value) 'setf) (symbolp (second value)))
         (second value))
        (t nil)))

(defun accessor-definitions (form by-name)
  "Slot accessors generated by a DEFCLASS / DEFSTRUCT / DEFINE-CONDITION FORM:
   a list of (NAME . :READER-or-:WRITER). They are defined implicitly, so without
   this they look like symbols with no source form and no signature."
  (let ((op (and (consp form) (symbolp (first form)) (symbol-name (first form))))
        (out '()))
    (when (slot-bearing-operator-p op)
      (dolist (slot (slot-list-of form))
        (when (proper-list-p slot)
          ;; A slot spec is (name . plist) for DEFCLASS but (name default . plist)
          ;; for DEFSTRUCT, so look for the key anywhere after the name.
          (loop for tail on slot
                for key = (first tail)
                when (and (symbolp key)
                          ;; SYMBOL-NAME of :ACCESSOR is "ACCESSOR" — no colon
                          (member (symbol-name key) '("ACCESSOR" "READER" "WRITER")
                                  :test #'string=))
                  do (let ((acc (accessor-symbol (second tail))))
                       (when (and acc (gethash (symbol-name acc) by-name))
                         (pushnew (cons (symbol-name acc)
                                        (if (string= (symbol-name key) "WRITER")
                                            :writer
                                            :reader))
                                  out :test #'equal)))))))
    out))

(defun slot-bearing-operator-p (op)
  "True for definition forms whose body is a list of slot specifiers.
   DEF-VIEW-CLASS is CLSQL's DEFCLASS and takes the same shape.
   OP may be the operator symbol or its already-extracted name string."
  (let ((name (cond ((symbolp op) (symbol-name op))
                    ((stringp op) op)
                    (t nil))))
    (and name (member name '("DEFCLASS" "DEF-VIEW-CLASS" "DEFSTRUCT"
                             "DEFINE-CONDITION")
                      :test #'string=))))

(defun slot-list-of (form)
  "(defclass name (supers) (slot-spec*)) puts the slot list fourth; DEFSTRUCT
   and DEFINE-CONDITION take their slots as the tail."
  (let ((op (and (consp form) (symbolp (first form)) (symbol-name (first form)))))
    (if (and op (member op '("DEFCLASS" "DEF-VIEW-CLASS") :test #'string=))
        (fourth form)
        (cddr form))))

(defun slot-initforms (form)
  "The :INITFORM values of a slot-bearing FORM.
   A class does not call its slot names — but it does call whatever an initform
   evaluates, and those are the only real outgoing edges it has."
  (let ((slots (slot-list-of form))
        (out '()))
    (dolist (slot slots)
      (when (proper-list-p slot)
        (loop for tail on slot
              when (and (symbolp (first tail))
                        (string-equal (symbol-name (first tail)) "INITFORM"))
                do (push (second tail) out))))
    out))

(defun build-definition-index (by-name)
  "BY-NAME: NAME -> record (each record carries :FILE). Scans every distinct
   source file once and returns NAME -> (:operator O :lambda-list LL :BODY BODY).
   Definitions nested in wrappers and class/struct slot accessors are included."
  (let ((index (make-hash-table :test #'equal))
        (files '()))
    (maphash (lambda (name rec)
               (declare (ignore name))
               (let ((f (getf rec :file)))
                 (when (and (stringp f) (plusp (length f)))
                   (pushnew f files :test #'equal))))
             by-name)
    (dolist (file files)
      (dolist (top (read-project-file-forms file))
        (dolist (form (collect-definition-forms top by-name))
          (dolist (nm (definition-names form))
            (when (and (gethash nm by-name) (not (gethash nm index)))
              (multiple-value-bind (op ll body) (definition-parts form)
                (setf (gethash nm index)
                      (list :operator op
                            :lambda-list (if (arglist-operator-p op) ll :none)
                            ;; a class's slot names are not calls; its initforms are
                            :body (if (slot-bearing-operator-p op)
                                      (slot-initforms form)
                                      body))))))
          ;; slot accessors: DEFCLASS/DEFSTRUCT define them implicitly
          (dolist (acc (accessor-definitions form by-name))
            (let ((an (car acc)))
              (when (and (gethash an by-name) (not (gethash an index)))
                (setf (gethash an index)
                      (list :operator (first form)
                            :lambda-list (if (eq (cdr acc) :writer)
                                             '(new-value object)
                                             '(object))
                            :body nil))))))))
    index))

(defun extract-calls (name def universe)
  "Project symbols that NAME calls, taken from its definition DEF and filtered
   to what this project really defines as callable (classes are not calls)."
  (let ((body (getf def :body))
        (out '()))
    (when body
      (dolist (s (collect-called-symbols body))
        (let ((sn (symbol-name s)))
          (when (and (not (string= sn name))
                     (member (gethash sn universe)
                             '("FUNCTION" "MACRO" "GENERIC-FUNCTION") :test #'string=))
            (pushnew sn out :test #'string=)))))
    (sort out #'string<)))

(defun arglist-string (ll)
  "Prints a lambda list as the signature string stored in the lookup table.
   NIL is the empty lambda list — a real signature for a zero-argument function —
   and prints as (). The keyword :NONE means the operator has no lambda list at all
   (DEFCLASS, DEFSTRUCT, ...) and yields NIL so the caller can fall back."
  (cond ((null ll) "()")            ; a zero-argument definition, not a missing one
        ((consp ll) (let ((*package* (or (find-package :nstores) *package*))
                          (*print-case* :downcase)
                          (*print-length* nil)
                          (*print-level* nil))
                      (format nil "~S" ll)))
        (t nil)))

(defun introspected-arglist (symbol)
  "Fallback signature straight from the image, for symbols whose source form was
   not found (macro-generated or loaded from elsewhere). Tolerates an
   implementation without SB-INTROSPECT."
  (let* ((pkg (find-package :sb-introspect))
         (fn (and pkg (find-symbol "FUNCTION-LAMBDA-LIST" pkg))))
    (when (and fn (fboundp fn) symbol (fboundp symbol))
      (handler-case (arglist-string (funcall fn symbol)) (error () nil)))))

;;; ============================================================================
;;; GRAPH METRICS — depth, cost (reachable callees), impact (reachable callers)
;;; ============================================================================

(defun compute-graph-metrics (records)
  "Fills :DEPTH (longest call chain below), :COST (distinct symbols reachable
   downwards — the reading budget for this function) and :IMPACT (distinct
   symbols that reach it upwards — the blast radius of a change) on every RECORD."
  (let ((by-name (make-hash-table :test #'equal))
        (depth (make-hash-table :test #'equal)))
    (dolist (r records) (setf (gethash (getf r :name) by-name) r))
    (labels ((longest (name seen)
               (or (gethash name depth)
                   (let ((r (gethash name by-name)))
                     (if (or (null r) (gethash name seen))
                         0
                         (progn
                           (setf (gethash name seen) t)
                           (let ((best 0))
                             (dolist (c (getf r :calls))
                               (setf best (max best (1+ (longest c seen)))))
                             (remhash name seen)
                             (setf (gethash name depth) best)))))))
             (reachable-set (names direction)
               (let ((seen (make-hash-table :test #'equal))
                     (stack (copy-list names)))
                 (loop while stack
                       do (let* ((n (pop stack))
                                 (r (gethash n by-name)))
                            (when (and r (not (gethash n seen)))
                              (setf (gethash n seen) t)
                              (dolist (c (if (eq direction :down)
                                             (getf r :calls)
                                             (getf r :used-by)))
                                (push c stack)))))
                 (let ((out '()))
                   (maphash (lambda (k v) (declare (ignore v)) (push k out)) seen)
                   out))))
      (dolist (r records)
        (let ((name (getf r :name)))
          (setf (getf r :depth) (longest name (make-hash-table :test #'equal))
                (getf r :cost) (length (remove name (reachable-set (getf r :calls) :down)
                                               :test #'string=))
                (getf r :impact) (length (remove name (reachable-set (getf r :used-by) :up)
                                                 :test #'string=))))))
    records))

;;; ============================================================================
;;; ENTRY SHAPE — one alist per symbol
;;; ============================================================================

(defun build-symbol-entry (record)
  "The public shape of a symbol: a name-sorted alist that json:encode-json
   renders as the documented JSON object (see the skill file)."
  (let ((entry '()))
    (flet ((add (k v) (push (cons k v) entry)))
      (add :name (getf record :name))
      (add :type (getf record :type))
      (add :form (getf record :form))
      (add :package (getf record :package))
      (add :file (getf record :file))
      (add :line (getf record :line))
      (add :lambda-list (getf record :lambda-list))
      (add :docstring (or (getf record :doc) ""))
      (add :keywords (or (getf record :keywords) ""))
      (when (getf record :meta) (add :meta (getf record :meta)))
      (add :calls (getf record :calls))
      (add :used-by (getf record :used-by))
      (add :calls-count (length (getf record :calls)))
      (add :used-by-count (length (getf record :used-by)))
      (add :depth (getf record :depth))
      (add :cost (getf record :cost))
      (add :impact (getf record :impact)))
    (nreverse entry)))

;; --- Helper 1: Loading Old Keywords ---

(defun load-old-data-and-keywords (output-file)
  "Carries the human-curated slots over from the previous generation.
   Returns NAME -> (:KEYWORDS string :META alist); the derived graph slots are
   always recomputed from source, never inherited."
  (let ((old-data-ht (make-hash-table :test 'equal)))
    (when (probe-file output-file)
      (handler-case
          (progn
            (load output-file :verbose nil)
            (dolist (entry (funcall (function-lookup-table)))
              (let ((name (entry-field entry :name)))
                (when (and name (stringp name))
                  (setf (gethash name old-data-ht)
                        (list :keywords (or (entry-field entry :keywords) "")
                              :meta (entry-field entry :meta)))))))
        (error (e)
          (lookup-warn "Error loading existing lookup data from ~A: ~A. Slots not preserved."
                       output-file e))))
    old-data-ht))



;; --- Helper 2: Writing the Final File (rich DAG, one alist per symbol) ---
(defun write-final-lookup-file (output-file entries)
  "Writes the generated data file. ENTRIES arrives name-sorted so a regeneration
   only diffs where the graph really changed."
  (with-open-file (s output-file
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
    (format s ";;; nst-bl-funloodat.lisp --- GENERATED FILE, do not edit by hand.~%")
    (format s ";;; Rebuild: (generate-lookup-file \"nstores\" \"hhub/core/nst-bl-funloodat.lisp\")~%")
    (format s ";;; Query:   (funcinfo \"symbol-name\"), (funcinfo-calls ...), (funcinfo-callers ...),~%")
    (format s ";;;          (funcinfo-search \"invoice\"), (funcinfo-impact ...), (funcinfo-report ...)~%")
    (format s ";;; Slot order: :name :type :form :package :file :line :lambda-list :docstring~%")
    (format s ";;;             :keywords :meta :calls :used-by :calls-count :used-by-count :depth :cost :impact~%~%")
    (format s "(in-package :nstores)~%~%")
    (format s "(defun function-lookup-table () (function (lambda () ~%  '(")
    (dolist (entry entries)
      (format s "~%    ~S" entry))
    (format s "))))~%"))
  (length entries))



;; --- Main Function: Orchestrator ---
(defun generate-lookup-file (system-name output-file)
  "Regenerates OUTPUT-FILE as a rich symbol DAG: every symbol the project defines,
   with its signature, file, docstring, curated :keywords/:meta, the symbols it
   calls, the symbols that call it, and the derived :depth/:cost/:impact metrics.

   Prints nothing and returns T — the file is the result. For the coverage numbers
   call (report-lookup-generation) or the loaded check in
   aiharness/deepseek/tools/nst-lookup-health.lisp.

   Completely silent, warnings included: skipped forms and unopenable files are
   recorded instead (see *LOOKUP-QUIET*, *SYM-READ-ERRORS*,
   *SYM-UNREADABLE-FILES*, and REPORT-LOOKUP-GENERATION)."
  (let* ((symbols   (get-project-symbols system-name))
         (old-data  (load-old-data-and-keywords output-file))
         (by-name   (make-hash-table :test #'equal))
         (universe  (make-hash-table :test #'equal))
         (records   '()))
    ;; Always re-read the sources: regeneration after an edit must not reuse the
    ;; forms cached by an earlier run in the same image.
    (clrhash *sym-source-cache*)
    (clrhash *sym-source-text*)
    (clrhash *sym-line-starts*)
    (clrhash *sym-line-byte-starts*)
    (clrhash *sym-read-errors*)
    (clrhash *sym-unreadable-files*)
    ;; 1. One record per project symbol, with the curated slots carried over.
    ;;    Every key is seeded here on purpose: (setf (getf rec key) val) only
    ;;    mutates the shared record in place when the key already exists.
    (dolist (s symbols)
      (let* ((name (symbol-name s))
             (type (get-symbol-type s))
             (old  (gethash name old-data))
             (reg  (gethash name *meta-registry*))
             (loc  (multiple-value-list (get-symbol-location s)))  ; (FILE LINE)
             (rec  (list :name name
                         :symbol s
                         :type type
                         :form type
                         :package (package-name (symbol-package s))
                         :file (or (first loc) "")   ; SWANK -> real file path
                         :line (second loc)
                         :doc (get-symbol-doc s type)
                         :lambda-list ""
                         :keywords (or (getf old :keywords) "")
                         :meta (or (when reg (getf reg :meta)) (getf old :meta))
                         :calls nil
                         :used-by nil
                         :depth nil
                         :cost nil
                         :impact nil)))
        (setf (gethash name by-name) rec
              (gethash name universe) type)
        (push rec records)))
    ;; 2. Signatures and outgoing calls, harvested from the source.
    (let ((index (build-definition-index by-name)))
      (maphash
       (lambda (name rec)
         (let* ((def  (gethash name index))
                (sym  (getf rec :symbol))
                (ll   (or (arglist-string (getf def :lambda-list))
                          (introspected-arglist (or sym (find-symbol name :nstores)))
                          "")))
           (setf (getf rec :form) (if def (symbol-name (getf def :operator)) (getf rec :type))
                 (getf rec :lambda-list) ll
                 (getf rec :calls) (extract-calls name def universe))))
       by-name))
    ;; 3. Invert the edges into :used-by, then measure the DAG.
    (maphash
     (lambda (name rec)
       (dolist (callee (getf rec :calls))
         (let ((crec (gethash callee by-name)))
           (when crec (pushnew name (getf crec :used-by) :test #'string=)))))
     by-name)
    (maphash (lambda (name rec)
               (declare (ignore name))
               (setf (getf rec :calls) (sort (getf rec :calls) #'string<)
                     (getf rec :used-by) (sort (getf rec :used-by) #'string<)))
             by-name)
    (compute-graph-metrics records)
    ;; 4. Publish, then refresh the in-image table so the REPL needs no reload.
    (let ((entries (mapcar #'build-symbol-entry
                           (sort records #'string<
                                 :key (lambda (r) (getf r :name))))))
      (write-final-lookup-file output-file entries)
      (when (boundp '*nst-function-symbols*)
        (setf (symbol-value '*nst-function-symbols*) entries))
      (setf *funcinfo-index* nil *funcinfo-index-source* nil)
      t)))

(defun report-lookup-generation (&optional entries)
  "Prints the coverage report for the generated table: meta coverage, how much of
   the DAG is wired, and any source file that could not be read. ENTRY defaults to
   the table in the image. Returns NIL; generate-lookup-file itself stays silent."
  (let ((entries (or entries (funcinfo-table))))
    (report-meta-coverage entries)
    (report-call-coverage entries)
    (report-read-errors)
    nil))




(defun report-meta-coverage (entries)
  "Prints meta coverage. The list of functions without metadata is capped: it runs
   to hundreds of names, and a wall of console output is not a report."
  (let* ((total    (length entries))
         (missing  (remove-if (lambda (e) (entry-field e :meta)) entries))
         (covered  (- total (length missing))))
    (format t "~&Meta coverage: ~A/~A functions have metadata (~A missing).~%"
            covered total (length missing))
    (when missing
      (format t "~&Functions missing meta declarations (first 15):~%")
      (dolist (e (subseq missing 0 (min 15 (length missing))))
        (format t "  ~A~%" (entry-field e :name)))
      (when (> (length missing) 15)
        (format t "  ... +~D more~%" (- (length missing) 15))))))

(defun report-call-coverage (entries)
  "Prints how much of the DAG is actually wired, so a silent extraction failure
   cannot masquerade as 'nothing calls anything'."
  (let* ((total  (length entries))
         (out    (count-if (lambda (e) (plusp (or (entry-field e :calls-count) 0))) entries))
         (in     (count-if (lambda (e) (plusp (or (entry-field e :used-by-count) 0))) entries))
         (roots  (count-if (lambda (e) (and (entry-field e :calls)
                                            (zerop (or (entry-field e :used-by-count) 0))))
                           entries)))
    (format t "~&Call graph: ~A/~A symbols call something, ~A/~A are called by something, ~A entry point(s).~%"
            out total in total roots)))

(defun report-read-errors ()
  "Names the source files whose forms could not all be read, and the files that
   could not be opened at all. Every symbol defined in them loses its call edges,
   which is why the generator records this instead of only warning about it."
  (when (plusp (hash-table-count *sym-unreadable-files*))
    (format t "~&Call graph: ~D file(s) could not be read at all:~%"
            (hash-table-count *sym-unreadable-files*))
    (maphash (lambda (f e) (format t "  ~A~%    ~A~%" f e)) *sym-unreadable-files*))
  (if (zerop (hash-table-count *sym-read-errors*))
      (format t "~&Call graph: every source file was read in full.~%")
      (let ((pairs '()))
        (maphash (lambda (f n) (push (cons n f) pairs)) *sym-read-errors*)
        (format t "~&Call graph: ~D file(s) had unreadable forms — symbols from them have no calls:~%"
                (length pairs))
        (dolist (p (sort pairs #'> :key #'car))
          (format t "  ~3D form(s)  ~A~%" (car p) (cdr p))))))



(defun get-symbol-type (s)
  "Determines the type of the given symbol S."
  (cond
    ;; 1. Functions and Macros
    ((fboundp s)
     (cond
       ((macro-function s) "MACRO")
       ((typep (fdefinition s) 'generic-function) "GENERIC-FUNCTION")
       (t "FUNCTION")))
    
    ;; 2. Classes
    ((find-class s nil) "CLASS")
    
    ;; 3. Constants and Variables (less useful for lookup, but complete)
    ((boundp s)
     (cond
       ((constantp s) "CONSTANT")
       (t "VARIABLE")))
    
    (t "UNKNOWN")))

(defun get-symbol-doc (s type)
  "Retrieves the documentation string for symbol S based on its determined TYPE."
  (let ((doc-type 
          (cond 
            ((string-equal type "FUNCTION") 'function)
            ((string-equal type "GENERIC-FUNCTION") 'function)
            ((string-equal type "MACRO") 'function)
            ((string-equal type "CLASS") 'type)
            ((string-equal type "CONSTANT") 'variable)
            ((string-equal type "VARIABLE") 'variable)
            (t nil))))
    
    (if doc-type
        ;; DOCUMENTATION returns NIL if no docstring exists
        (or (documentation s doc-type) "") 
        "")))

;; You MUST define or import a function similar to this:
;; This is a conceptual function as the real implementation depends on your CL flavor.


(defvar *sym-line-starts* (make-hash-table :test #'equal)
  "FILE -> vector of 0-based character offsets where each line starts.")

(defun source-text (file)
  "The full text of FILE, cached: the scan reads a file once and both the forms and
   the line index are derived from the same string."
  (or (gethash file *sym-source-text*)
      (handler-case
          (setf (gethash file *sym-source-text*) (read-source-text file))
        (error () nil))))

(defvar *sym-line-byte-starts* (make-hash-table :test #'equal)
  "FILE -> vector of byte offsets where each line starts (UTF-8 aware).")

(defun utf8-byte-length (char)
  "Bytes CHAR occupies in UTF-8."
  (let ((code (char-code char)))
    (cond ((< code #x80) 1)
          ((< code #x800) 2)
          ((< code #x10000) 3)
          (t 4))))

(defun line-index (file)
  "Builds, once per FILE, the line-start offsets in BOTH units:
   (values CHARACTER-STARTS BYTE-STARTS). The scan needs both because SWANK's
   :POSITION is a 1-based BYTE offset for UTF-8 sources — reading it as a character
   offset drifts by one line per non-ASCII character before the definition, which
   silently cost ~18% of the table its line number."
  (let ((char-starts (gethash file *sym-line-starts*))
        (byte-starts (gethash file *sym-line-byte-starts*)))
    (unless (and char-starts byte-starts)
      (let ((text (source-text file)))
        (if (null text)
            (setf char-starts #() byte-starts #())
            (let ((chars (make-array 1 :adjustable t :fill-pointer 1 :initial-element 0))
                  (bytes (make-array 1 :adjustable t :fill-pointer 1 :initial-element 0))
                  (byte 0))
              (loop for i from 0 below (length text)
                    for ch = (char text i)
                    do (incf byte (utf8-byte-length ch))
                       (when (char= ch #\Newline)
                         (vector-push-extend (1+ i) chars)
                         (vector-push-extend byte bytes)))
              (setf char-starts (coerce chars 'simple-vector)
                    byte-starts (coerce bytes 'simple-vector)))))
      (setf (gethash file *sym-line-starts*) char-starts
            (gethash file *sym-line-byte-starts*) byte-starts))
    (values char-starts byte-starts)))

(defun line-starts (file)
  "Vector of character line-start offsets for FILE."
  (values (line-index file)))

(defun line-for-position (starts position)
  "1-based line whose start is the last one at or before POSITION-1."
  (when (plusp (length starts))
    (let ((lo 0) (hi (1- (length starts))))
      (loop while (< lo hi)
            do (let ((mid (ceiling (+ lo hi) 2)))
                 (if (<= (aref starts mid) (1- position))
                     (setf lo mid)
                     (setf hi (1- mid)))))
      (1+ lo))))

(defun position-line (file position &optional (units :characters))
  "1-based line number of the 1-based POSITION in FILE, or NIL.
   UNITS is :CHARACTERS or :BYTES; SWANK uses bytes, so callers try both and keep
   whichever answer actually names the symbol."
  (when (and file position (integerp position) (plusp position))
    (multiple-value-bind (char-starts byte-starts) (line-index file)
      (line-for-position (if (eq units :bytes) byte-starts char-starts) position))))

(defun line-mentions-p (file line name)
  "True when LINE of FILE mentions NAME. A mis-decoded :POSITION would land on an
   unrelated line, so a line number is only published when it names the symbol."
  (let* ((text (source-text file))
         (starts (line-starts file))
         (i (1- line)))
    (when (and text (<= 0 i) (< i (length starts)))
      (let* ((start (aref starts i))
             (end (or (position #\Newline text :start start) (length text)))
             (text-line (subseq text start end))
             (needle (string-downcase name)))
        (not (null (search needle (string-downcase text-line))))))))

(defun location-part (location-plist key)
  "Reads KEY from a SWANK location.
   SWANK's location is a list-struct — (:location (:file \"path\") (:position n)
   (:snippet \"...\")) — so each part carries its own key, and a part may hold
   several (:location (:file \"p\" :position n)) is read too. Reading the key from
   each part is what makes both shapes work; assuming a flat plist silently lost
   the line number."
  (loop for part in (rest location-plist)
        when (and (consp part) (getf part key))
          return (getf part key)))

(defun location-file-line (location-plist name)
  "Returns (values FILE LINE) for a SWANK location. LINE is NIL when the location
   carries no position or when the line it points at does not mention NAME."
  (let ((file-path (location-part location-plist :file))
        (position (location-part location-plist :position)))
    (flet ((mentioning (units)
             (let ((line (position-line file-path position units)))
               (when (and line (line-mentions-p file-path line (string-downcase name)))
                 line))))
      ;; SWANK's offset is a byte offset, so that interpretation is tried first; the
      ;; character one stays as a fallback for another backend or a format change.
      (values file-path (or (mentioning :bytes) (mentioning :characters))))))

(defun get-symbol-location (s)
  "Finds where the symbol S is defined, using SWANK:FIND-DEFINITIONS-FOR-EMACS.
   Returns (values FILE LINE); LINE is NIL when SWANK gave no position or when the
   line it points at does not mention the symbol."
  (handler-case
      (let* ((swank-package (find-package :swank))
             (find-defs-symbol (when swank-package
                                 (find-symbol (string '#:find-definitions-for-emacs) swank-package)))
             (symbol-name (string-downcase (symbol-name s))))
        (cond
          ;; SWANK loaded and answering: result is ((NAME-STRING LOCATION-PLIST ...) ...)
          ((and swank-package find-defs-symbol (fboundp find-defs-symbol))
           (let ((def-list (funcall find-defs-symbol symbol-name)))
             (if (and (listp def-list) (first def-list))
                 (let* ((first-definition (first def-list))
                        (location-plist (second first-definition)))
                   ;; (:LOCATION (:FILE "/path" :POSITION n :SNIPPET "..."))
                   (if (and location-plist (listp location-plist)
                            (eq (first location-plist) :location))
                       (location-file-line location-plist (symbol-name s))
                       (values "" nil)))
                 (values "" nil))))
          ;; No SWANK: the call graph still works, only the file is unknown
          (t
           (lookup-warn "SWANK:FIND-DEFINITIONS-FOR-EMACS is not available. Source file location not found for ~A." s)
           (values "" nil))))
    (error (e)
      (lookup-warn "Error finding source for ~A: ~A" s e)
      (values "" nil))))

(defun get-symbol-file (s)
  "The file where S is defined, or \"\" when unknown."
  (values (get-symbol-location s)))

;;; ============================================================================
;;; QUERY API — cheap answers about the generated symbol DAG
;;; ============================================================================

(defun funcinfo-table ()
  "The generated symbol table: the *NST-FUNCTION-SYMBOLS* global when it is bound
   (nst-bl-ollama.lisp binds it), otherwise straight from the data file."
  (let ((bound (and (boundp '*nst-function-symbols*)
                    (symbol-value '*nst-function-symbols*))))
    (or bound (funcall (function-lookup-table)))))

(defun funcinfo-refresh ()
  "Re-reads the generated table into *NST-FUNCTION-SYMBOLS* and drops the query
   index. generate-lookup-file already does this; call it by hand after editing
   the data file."
  (let ((table (funcall (function-lookup-table))))
    (when (boundp '*nst-function-symbols*)
      (setf (symbol-value '*nst-function-symbols*) table))
    (setf *funcinfo-index* nil *funcinfo-index-source* nil)
    table))

(defun funcinfo-key (name)
  "Normalises NAME (string or symbol, package qualifier optional) to the
   upper-case key used by the index."
  (let* ((s (string name))
         (colon (position #\: s :from-end t)))
    (string-upcase (subseq s (if colon (1+ colon) 0)))))

(defun funcinfo-index ()
  "NAME -> entry; rebuilt automatically whenever the table object changes."
  (let ((table (funcinfo-table)))
    (unless (eq *funcinfo-index-source* table)
      (let ((ht (make-hash-table :test #'equal)))
        (dolist (e table)
          (let ((n (entry-field e :name)))
            (when (and n (stringp n)) (setf (gethash n ht) e))))
        (setf *funcinfo-index* ht
              *funcinfo-index-source* table)))
    *funcinfo-index*))

(defun funcinfo-resolve (x)
  "X is a symbol name (string/symbol) or an entry already: return the entry."
  (if (and (consp x) (consp (first x)))
      x
      (funcinfo x)))

(defun funcinfo (name &optional field)
  "The entry for NAME (case-insensitive, package qualifier optional): the whole
   alist, or FIELD's value — (funcinfo \"format-invoice\" :calls)."
  (let ((entry (gethash (funcinfo-key name) (funcinfo-index))))
    (if (or (null entry) (null field))
        entry
        (entry-field entry field))))

(defun funcinfo-calls (x)
  "Symbols X calls directly."
  (entry-field (funcinfo-resolve x) :calls))

(defun funcinfo-callers (x)
  "Symbols that call X directly."
  (entry-field (funcinfo-resolve x) :used-by))

(defun funcinfo-arglist (x)
  "Signature of X."
  (entry-field (funcinfo-resolve x) :lambda-list))

(defun funcinfo-file (x)
  "Source file of X."
  (entry-field (funcinfo-resolve x) :file))

(defun funcinfo-search (query &key (limit 25) full)
  "Case-insensitive substring search over name, docstring and keywords.
   Returns brief alists (name/type/file/calls-count/used-by-count), or the full
   entries when FULL is true."
  (let ((q (string-upcase query))
        (hits '()))
    (dolist (e (funcinfo-table))
      (let ((name (or (entry-field e :name) ""))
            (doc  (or (entry-field e :docstring) ""))
            (kw   (or (entry-field e :keywords) "")))
        (when (or (search q name)
                  (search q (string-upcase doc))
                  (search q (string-upcase kw)))
          (push e hits))))
    ;; NRVERSE is destructive: bind it first, or (length hits) would measure the
    ;; one-cons tail the stale variable still points at, capping every query to 1.
    (let* ((all (nreverse hits))
           (hits (subseq all 0 (min limit (length all)))))
      (if full
          hits
          (mapcar (lambda (e)
                    (list (cons :name (entry-field e :name))
                          (cons :type (entry-field e :type))
                          (cons :file (short-file-name (entry-field e :file)))
                          (cons :calls-count (entry-field e :calls-count))
                          (cons :used-by-count (entry-field e :used-by-count))))
                  hits)))))

(defun funcinfo-bfs (start direction &key depth)
  "Walks the call graph from START, following :CALLS (DIRECTION :DOWN) or
   :USED-BY (:UP). Returns (values NAMES PAIRS), nearest first, PAIRS being
   (NAME . LEVEL)."
  (let ((seen (make-hash-table :test #'equal))
        (queue (list (cons start 0)))
        (names '())
        (levels '()))
    (setf (gethash start seen) t)
    (loop while queue
          do (let* ((item (pop queue))
                    (n (car item))
                    (l (cdr item)))
               (unless (and depth (>= l depth))
                 (dolist (c (entry-field (funcinfo n)
                                         (if (eq direction :down) :calls :used-by)))
                   (unless (gethash c seen)
                     (setf (gethash c seen) t)
                     (push c names)
                     (push (cons c (1+ l)) levels)
                     (setf queue (append queue (list (cons c (1+ l))))))))))
    (values (nreverse names) (nreverse levels))))

(defun funcinfo-subtree (name &key depth)
  "Everything NAME reaches through calls — the reading budget for understanding
   it, nearest first."
  (funcinfo-bfs (funcinfo-key name) :down :depth depth))

(defun funcinfo-impact (name &key depth)
  "Everything that reaches NAME through calls — who a change here can break."
  (funcinfo-bfs (funcinfo-key name) :up :depth depth))

(defun funcinfo-path (from to)
  "Shortest call path FROM -> TO as a list of names, or NIL when unreachable."
  (let ((start (funcinfo-key from))
        (goal  (funcinfo-key to))
        (parent (make-hash-table :test #'equal))
        (seen   (make-hash-table :test #'equal))
        (queue  (list (funcinfo-key from))))
    (setf (gethash start seen) t)
    (block search
      (loop while queue
            do (let ((n (pop queue)))
                 (when (string= n goal)
                   (let ((path '()))
                     (loop for c = n then (gethash c parent)
                           while c
                           do (push c path)
                              (unless (gethash c parent) (return)))
                     (return-from search path)))
                 (dolist (c (entry-field (funcinfo n) :calls))
                   (unless (gethash c seen)
                     (setf (gethash c seen) t
                           (gethash c parent) n)
                     (setf queue (append queue (list c)))))))
      nil)))

(defun first-line (text)
  "TEXT up to its first newline."
  (let ((nl (and (stringp text) (position #\Newline text))))
    (if nl (subseq text 0 nl) text)))

(defun names-briefly (names &optional (max 15))
  "NAMES as a comma-separated string, truncated after MAX entries."
  (if (<= (length names) max)
      (format nil "~{~A~^, ~}" names)
      (format nil "~{~A~^, ~} ... +~D more"
              (subseq names 0 max) (- (length names) max))))

(defun funcinfo-report (name)
  "Prints a compact agent-readable summary of NAME and returns its entry.
   The cheapest way to understand a function: signature, file, what it calls,
   who calls it, and the DAG metrics."
  (let ((e (funcinfo name)))
    (if (null e)
        (format t "~&No such symbol: ~A~%" name)
        (progn
          (format t "~&~A  [~A~@[ / ~A~]]~%"
                  (entry-field e :name) (entry-field e :type) (entry-field e :form))
          (format t "  file      : ~A~%" (entry-file-line e))
          (format t "  signature : ~A~%" (or (entry-field e :lambda-list) ""))
          (format t "  package   : ~A~%" (entry-field e :package))
          (let ((doc (entry-field e :docstring)))
            (when (and doc (plusp (length doc)))
              (format t "  docstring : ~A~%" (first-line doc))))
          (format t "  calls (~A)    : ~A~%"
                  (or (entry-field e :calls-count) 0)
                  (names-briefly (entry-field e :calls)))
          (format t "  used by (~A)  : ~A~%"
                  (or (entry-field e :used-by-count) 0)
                  (names-briefly (entry-field e :used-by)))
          (format t "  dag       : depth ~A, cost ~A, impact ~A~%"
                  (entry-field e :depth) (entry-field e :cost) (entry-field e :impact))))
    e))

(defun funcinfo-stats ()
  "Prints the shape of the DAG (totals, types, entry points, heaviest subtrees)
   and returns a small alist."
  (let* ((table (funcinfo-table))
         (total (length table))
         (types (make-hash-table :test #'equal))
         (entry-points '()))
    (dolist (e table)
      (let ((ty (or (entry-field e :type) "?")))
        (setf (gethash ty types) (1+ (or (gethash ty types) 0))))
      (when (and (plusp (or (entry-field e :calls-count) 0))
                 (zerop (or (entry-field e :used-by-count) 0)))
        (push (entry-field e :name) entry-points)))
    (let ((heaviest (sort (copy-list table) #'>
                          :key (lambda (e) (or (entry-field e :cost) 0)))))
      (format t "~&Symbol table: ~A symbols.~%" total)
      (maphash (lambda (k v) (format t "  ~A: ~A~%" k v)) types)
      (format t "  entry points (call others, nobody calls them): ~A~%"
              (names-briefly (sort entry-points #'string<) 20))
      (format t "  heaviest subtrees by cost: ~{~A~^, ~}~%"
              (loop for e in (subseq heaviest 0 (min 10 (length heaviest)))
                    collect (format nil "~A(~A)" (entry-field e :name)
                                    (or (entry-field e :cost) 0))))
      (list (cons :total total)
            (cons :entry-points (length entry-points))))))

(defun create-widgets-for-project-symbols-lookup-page (modelfunc)
  "Widget Factory: Calls the widget with the model data."
  (multiple-value-bind (jsondata) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)
		       (:h2 "Lisp Project Symbol Lookup")
		       (:div :class "form-group"
			     (:label :for "symbol-input" "Search Symbol Name:")
			     (:input :type "text" :id "symbol-input" :class "form-control" :placeholder "Start typing a symbol name...")
			     (:small :class "form-text text-muted" "e.g., customer-profile, dod-bl, nst-dal"))
		       (:div :class "mt-4"
			     (:h4 "Search Results")
			     (:div :id "result-count" :class "text-muted" "Showing 0 results.")
			     (:div :id "results-output" 
				   (:table :class "table table-striped table-sm"
					   (:thead
					    (:tr
					     (:th "Name")
					     (:th "Type")
					     (:th "File Location")
					     (:th "Signature")
					     (:th "Calls")
					     (:th "Used by")))
					   (:tbody :id "results-tbody"))))))))
	  (widget2 (function (lambda ()
		   (cl-who:with-html-output (*standard-output* nil) 
		     ;; --- JavaScript for Client-Side Filtering ---
		     (:script
      (cl-who:str
        (format nil "
          const rows = ~A;
          // The generated table is one object per symbol; this keeps a
          // positional view so the renderer below stays readable.
          const lookupData = rows.map(r => [r.name, r.type, r.file, r.docstring,
                                           r.keywords, r.meta || {}, r.lambda_list || '',
                                           r.calls || [], r.used_by || [],
                                           r.depth, r.cost, r.impact, r.line]);
          const tableBody = document.getElementById('results-tbody');
          const searchInput = document.getElementById('symbol-input');
          const resultCount = document.getElementById('result-count');

          function escapeHtml(text) {
              const map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '\"': '&quot;', \"'\": '&#039;' };
              return text.replace(/[&<>\"']/g, (m) => map[m]);
          }


function renderRow(entry) {
  const name      = escapeHtml(entry[0]);
  const type      = escapeHtml(entry[1]);
  const file      = escapeHtml(entry[2]);
  const docstring = escapeHtml(entry[3] || '');
  const keywords  = escapeHtml(entry[4]);
  const meta      = entry[5] || {};     // already a proper JS object
  const arglist   = escapeHtml(entry[6] || '');
  const callList  = entry[7] || [];
  const usedList  = entry[8] || [];
  const depth     = entry[9];
  const cost      = entry[10];
  const impact    = entry[11];

  const line = entry[12];
  const fileLabel = file ? file.split('/').pop() + (line ? ':' + line : '') : '';
  const fileLink = file
    ? `<a href=\"#\" title=\"${file}${line ? ':' + line : ''}\">${fileLabel}</a>`
    : 'N/A';

  const chips = (list, cls) => list.slice(0, 8).map(n =>
      `<span class=\"badge ${cls} border text-dark\">${escapeHtml(n)}</span>`).join(' ')
    + (list.length > 8 ? ` <span class=\"text-muted\">+${list.length - 8} more</span>` : '');

  const metaHtml = `
    <tr class=\"meta-row\">
      <td colspan=\"6\" style=\"padding:4px 8px; background:#f8f9fa; font-size:0.85em;\">
        ${meta.domain   ? `<span class=\"badge bg-primary\">${meta.domain}</span> ` : ''}
        ${meta.category ? `<span class=\"badge bg-secondary\">${meta.category}</span> ` : ''}
        ${meta.cost     ? `<span class=\"badge bg-info text-dark\">cost: ${meta.cost}</span> ` : ''}
        <span class=\"badge ${meta.pure === true ? 'bg-success' : 'bg-warning text-dark'}\">
          ${meta.pure === true ? 'pure' : 'side-effects'}
        </span>
        <span class=\"badge bg-dark\">depth ${depth} / cost ${cost} / impact ${impact}</span>
        ${meta.tags && Array.isArray(meta.tags)
          ? meta.tags.map(t => `<span class=\"badge bg-light text-dark border\">${t}</span>`).join(' ')
          : ''}
        ${arglist ? `<div class=\"mt-1\"><code>${arglist}</code></div>` : ''}
        ${callList.length ? `<div class=\"mt-1\">calls: ${chips(callList, 'bg-light')}</div>` : ''}
        ${usedList.length ? `<div class=\"mt-1\">used by: ${chips(usedList, 'bg-light')}</div>` : ''}
        ${meta.description
          ? `<div class=\"text-muted mt-1\">${escapeHtml(meta.description)}</div>`
          : (docstring ? `<div class=\"text-muted mt-1\">${docstring}</div>` : '')}
      </td>
    </tr>`;

  return `
    <tr>
      <td><strong>${name}</strong></td>
      <td><span class=\"badge bg-secondary\">${type}</span></td>
      <td>${fileLink}</td>
      <td><code>${arglist || '&mdash;'}</code></td>
      <td>${callList.length}</td>
      <td>${usedList.length}</td>
    </tr>
    ${metaHtml}`;
    }
          function filterSymbols() {
              const query = searchInput.value.toUpperCase();
              let resultsHtml = '';
              let count = 0;

              for (const entry of lookupData) {
                  const name = entry[0];
                  const keywords = entry[4]; // Keywords are the 5th element (index 4)
                  
                  // Check 1: Ignore empty query.
                  if (query.length > 0) {
                      
                      const nameMatch = name.toUpperCase().includes(query);
                      const keywordMatch = keywords.toUpperCase().includes(query);

                      // Check 2: Match if the query is anywhere in the Name OR the Keywords
                      if (nameMatch || keywordMatch) { 
                          resultsHtml += renderRow(entry);
                          count++;
                      }
                  }
              }

              tableBody.innerHTML = resultsHtml;
              resultCount.textContent = `Showing ${count} results.`;
          }

          searchInput.addEventListener('input', filterSymbols);
          filterSymbols(); // Initial call to show empty table/count
        " jsondata))))))))
    (list widget1 widget2))))

(defun funcinfo-json-key (name)
  "Lisp symbol name -> JSON key, so a field reads as lambda_list / used_by,
   matching the field names documented in the skill file."
  (string-downcase (substitute #\_ #\- name)))

;; You can define these in the same package as your other UI functions (e.g., :com.nstores.app)
(defun create-model-for-project-symbols-lookup-page ()
  "Model: the whole generated symbol DAG as JSON — one object per symbol, with
   its signature, calls, callers and the depth/cost/impact metrics."
  (let ((json:*lisp-identifier-name-to-json* #'funcinfo-json-key)
        (jsondata (json:encode-json-to-string (funcinfo-table))))
    (function (lambda ()
      (values jsondata)))))

(defun com-hhub-controller-project-symbols-lookup-page ()
  "Controller: Renders the symbol lookup page."
  (with-mvc-ui-page  "Symbol Lookup" #'create-model-for-project-symbols-lookup-page #'create-widgets-for-project-symbols-lookup-page :role :superadmin))
