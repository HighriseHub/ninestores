;;; nst-vordh-mirror-check.lisp — the VENDOR channel's offline shape check (S9/S15).
;;;
;;;   cd /home/ubuntu/ninestores
;;;   mysql -u hhubuser -p'…' hhubdb -N -e "SELECT column_name FROM information_schema.columns \
;;;     WHERE table_schema='hhubdb' AND table_name='DOD_VENDOR_ORDERS' ORDER BY ordinal_position;" \
;;;     > /tmp/vordh-live-cols.txt
;;;   sbcl --noinform --non-interactive --load aiharness/deepseek/tools/nst-vordh-mirror-check.lisp
;;;
;;; Exit 0 = every check passed. 1 = at least one FAIL, named with the slot or the column.
;;;
;;; ── WHAT IT CHECKS, AND WHY EACH ONE IS HERE ────────────────────────────────
;;;
;;;  A. THE CLASS COVERS THE LIVE TABLE — all 60 columns of DOD_VENDOR_ORDERS, none missing,
;;;     none phantom (S9 AC a/b). The legacy dod-vendor-orders class covered 26 of 60 and
;;;     nothing noticed for months, because nothing compared the class to the database.
;;;
;;;  B/C. THE MIRROR LIST, THE ENTITY AND THE RESPONSE MODEL AGREE. This is the check that
;;;     matters most: *vordh-mirrored-slots* drives domain->response, which setfs EVERY listed
;;;     slot onto NstVordhResponseModel. One entry with no slot there is not a cosmetic defect —
;;;     it signals MISSING-SLOT on every response, which is exactly how the whole invoice API
;;;     answered 500 for weeks while every offline check passed. The list is source-visible, so
;;;     this needs no image and no database.
;;;
;;;  E. NO DUPLICATE SLOT OR COLUMN. A duplicated :column silently shadows; CLSQL takes the last.
;;;
;;; ⚠ IT READS THE SOURCE FORMS, IT DOES NOT LOAD THEM (no image, no ASDF, no database). The
;;; packages CLSQL and NSTORES are stubbed so the reader can read qualified symbols; nothing is
;;; evaluated, and *READ-EVAL* is NIL throughout. That also means this file CANNOT be fooled by
;;; a stale fasl — the failure mode that made an earlier "successful" migration apply nothing.

;;; ⚠ NO DEPENDENCY IS LOADED, AND THE TWO THINGS THAT MAKES POSSIBLE ARE BOTH DELIBERATE:
;;;
;;;  * a STUB clsql package, so `clsql:select` and `clsql:date` can be READ. The symbols need to
;;;    exist, not to mean anything, because nothing here is evaluated;
;;;  * a READTABLE in which `[` and `]` are whitespace, so the tree's SQL literals are readable
;;;    without CLSQL's reader syntax. Neutralising the brackets costs this tool nothing — it
;;;    inspects the shapes of a defclass, four defparameters and one defmethod body, none of which
;;;    contains SQL — and it keeps the tool free of a dependency that cannot always be loaded
;;;    (ql:quickload of :clsql collides in this environment over uffi).
;;;
;;; ⚠ THE ALTERNATIVE, ATTEMPTED FIRST, WAS TO STUB ONLY THE PACKAGE AND LEAVE THE BRACKETS ALONE.
;;; The reader then answers "Package [ does not exist" for `[:row-id]` and the tool reports a
;;; HEALTHY SOURCE FILE as unreadable — the same lesson nst-preflight.lisp:55-71 records: a
;;; missing dependency is indistinguishable from a broken file. True reader BALANCE on the real
;;; files is the preflight's job, with the real clsql loaded; this tool must not pretend to do it.

(let ((*read-eval* nil))
  (dolist (pkg '(:clsql :nstores))
    (unless (find-package pkg) (make-package pkg)))
  (dolist (name '("DEF-VIEW-CLASS" "DATE" "WALL-TIME" "DATE-TIME" "DURATION" "VIEW-CLASS"
                  "FILE-ENABLE-SQL-READER-SYNTAX" "SELECT" "SQL-AND" "SQL-OR"
                  "UPDATE-RECORDS-FROM-INSTANCE" "UPDATE-RECORD-FROM-SLOT"))
    (export (intern name (find-package :clsql)) (find-package :clsql))))

(defun nst-source-readtable ()
  "A copy of the standard readtable in which the SQL brackets are whitespace."
  (let ((rt (copy-readtable nil)))
    (set-syntax-from-char #\[ #\Space rt)
    (set-syntax-from-char #\] #\Space rt)
    rt))

(defparameter *source* "hhub/order/nst-dal-vordh.lisp"
  "The vendor island: class, entity, request model, response model, mirrored-slot list.")

(defparameter *schema-file* "/tmp/vordh-live-cols.txt"
  "One live column name per line, in ordinal order; produced by the mysql command in this file's
   header. A MISSING FILE IS A FAIL, never a skipped check: a check whose input silently vanished
   is the vacuous pass that this batch's preflight §4 exists to catch.")

(defparameter *entity-class* "NST-VORDH")
(defparameter *response-class* "NSTVORDHRESPONSEMODEL")
(defparameter *view-class* "DOD-VENDOR-ORDER")
(defparameter *mirror-list* "*VORDH-MIRRORED-SLOTS*")

(defvar *problems* 0)
(defvar *checks* 0)

(defun fail (fmt &rest args)
  (incf *problems*)
  (format t "   FAIL  ~A~%" (apply #'format nil fmt args)))

(defun ok (fmt &rest args)
  (incf *checks*)
  (format t "   ok    ~A~%" (apply #'format nil fmt args)))

;;; ── reading the source, without evaluating it ──────────────────────────────

(defun read-all-forms (path)
  (with-open-file (in path :direction :input)
    (let ((*package* (find-package :cl-user))
          (*readtable* (nst-source-readtable))
          (*read-eval* nil))
      (let ((forms '()))
        (loop for form = (handler-case (read in nil :eof)
                           (error (e) (error "~A does not READ: ~A" path e)))
              until (eq form :eof)
              do (push form forms))
        (nreverse forms)))))

(defun form-head (form)
  "The symbol-name of a form's head, package-independent."
  (and (consp form) (symbolp (car form)) (symbol-name (car form))))

(defun name-is (x name)
  (and (symbolp x) (string= (symbol-name x) name)))

(defun find-form (forms head name)
  "The form whose head is HEAD and whose second element is the symbol named NAME."
  (find-if (lambda (f)
             (and (string= (form-head f) head)
                  (> (length f) 1)
                  (name-is (elt f 1) name)))
           forms))

(defun class-slot-names (defclass-form)
  "Slot names of a defclass form: the car of each slot spec. Docstrings and class options are
   skipped because they are strings and keyword-led lists, never a (name . plist) slot spec."
  (let ((slots (elt defclass-form 3)))
    (loop for spec in slots
          when (and (consp spec) (symbolp (car spec)))
            collect (symbol-name (car spec)))))

(defun quoted-symbols (defparameter-form)
  "The symbol names inside a (defparameter name '(a b c) \"doc\") form."
  (let ((value (elt defparameter-form 2)))
    (when (and (consp value) (eq (car value) 'quote))
      (setf value (second value)))
    (loop for x in value when (symbolp x) collect (symbol-name x))))

(defun view-class-columns (defview-form)
  "The :column \"NAME\" strings of a CLSQL view class form."
  (let ((slots (elt defview-form 3)))
    (let ((cols '()))
      (dolist (spec slots)
        (when (and (consp spec) (symbolp (car spec)))
          (loop for (k v) on (cdr spec) by #'cddr
                when (and (symbolp k) (string= (symbol-name k) "COLUMN") (stringp v))
                  do (push v cols))))
      (nreverse cols))))

;;; ── the checks, each its own function: no deep nesting to mis-count ────────

(defun check-present (label form)
  (if form
      (ok "found ~A in the source" label)
      (fail "~A is MISSING from ~A — the file changed shape, so every check below is vacuous"
            label (or *current-source* *source*))))

(defun check-duplicates (label list)
  (let ((counts (make-hash-table :test 'equal)))
    (dolist (x list) (incf (gethash x counts 0)))
    (let ((dup (loop for k being the hash-keys of counts using (hash-value v)
                     when (> v 1) collect k)))
      (if dup
          (fail "duplicate ~A: ~{~A~^, ~}" label dup)
          (ok "no duplicate ~A (~D declared)" label (length list))))))

(defun check-columns (cols)
  (if (not (probe-file *schema-file*))
      (fail "the schema file ~A does not exist — run the mysql command in this file's header; a \
skipped check is not a pass" *schema-file*)
      (let ((live (with-open-file (in *schema-file*)
                    (loop for line = (read-line in nil :eof)
                          until (eq line :eof)
                          for trimmed = (string-trim '(#\Space #\Tab #\Return) line)
                          when (plusp (length trimmed)) collect trimmed))))
        (let ((missing (set-difference live cols :test #'string=))
              (phantom (set-difference cols live :test #'string=)))
          (when missing
            (fail "the class is MISSING ~D live column(s): ~{~A~^, ~}" (length missing) missing))
          (when phantom
            (fail "the class declares ~D PHANTOM column(s): ~{~A~^, ~}" (length phantom) phantom))
          (when (and (null missing) (null phantom))
            (ok "the class covers the live table exactly — ~D/~D columns, none missing, none phantom"
                (length cols) (length live)))))))

(defun check-mirror (slots mirs)
  (let ((want (append (remove "ROW-ID" slots :test #'string=) '("DELETED-STATE"))))
    (let ((miss (set-difference want mirs :test #'string=))
          (extra (set-difference mirs want :test #'string=)))
      (when miss
        (fail "in the entity but NOT mirrored (never reaches a client): ~{~A~^, ~}" miss))
      (when extra
        (fail "mirrored but NOT an entity slot (MISSING-SLOT on every response): ~{~A~^, ~}" extra))
      (when (and (null miss) (null extra))
        (ok "the mirror list is exactly the entity's business slots + deleted-state (~D entries)"
            (length mirs))))))

(defun check-response (rslots mirs)
  (let ((want (cons "ROW-ID" mirs)))
    (let ((miss (set-difference want rslots :test #'string=))
          (extra (set-difference rslots want :test #'string=)))
      (when miss
        (fail "domain->response would SETF these onto a slot that does not exist: ~{~A~^, ~}" miss))
      (when extra
        (fail "declared on the response model but never mirrored (dead slot): ~{~A~^, ~}" extra))
      (when (and (null miss) (null extra))
        (ok "the response model is the mirror list + row-id (~D slots)" (length rslots))))))

;;; ── main ───────────────────────────────────────────────────────────────────

(format t "~%== nst-vordh-mirror-check — ~A~%" *source*)

(let ((forms (read-all-forms *source*)))
  (let ((view (find-form forms "DEF-VIEW-CLASS" *view-class*))
        (entity (find-form forms "DEFCLASS" *entity-class*))
        (resp (find-form forms "DEFCLASS" *response-class*))
        (mirror (find-form forms "DEFPARAMETER" *mirror-list*)))
    (check-present "the view class" view)
    (check-present "the entity" entity)
    (check-present "the response model" resp)
    (check-present "the mirror list" mirror)
    (when (and view entity resp mirror)
      (let ((cols (view-class-columns view))
            (slots (class-slot-names entity))
            (rslots (class-slot-names resp))
            (mirs (quoted-symbols mirror)))
        (check-duplicates "column" cols)
        (check-duplicates "entity slot" slots)
        (check-duplicates "response slot" rslots)
        (check-duplicates "mirror entry" mirs)
        (check-columns cols)
        (check-mirror slots mirs)
        (check-response rslots mirs)))))

;;; ── 2. the BL half: the JSON allowlist and the field policy (S10) ──────────

(defparameter *bl-source* "hhub/order/nst-bl-vordh.lisp"
  "The vendor channel's business layer (S10). Checked here for the two invariants that only exist
   once the verbs do: the render-json allowlist and the field-policy partition.")

(defvar *current-source* nil
  "The file a check is currently reading, so a FAIL names the file it actually looked at. The
   first version of the BL block printed *source* (the DAL) and sent the reader to the wrong
   file — a small lie, and this tool exists because small lies about measurements are expensive.")

(defun find-render-json (forms class-name)
  "The (defmethod render-json ((r CLASS-NAME) (ctx domain-ctx)) …) form, or NIL.
   ⚠ THE SPECIALIZER IS TWO LEVELS DOWN: elt 2 is the LIST of specializer lists, so the class is
   (second (first (elt f 2))) — not (second (elt f 2)), which is the ctx specializer."
  (find-if (lambda (f)
             (and (string= (form-head f) "DEFMETHOD")
                  (> (length f) 2)
                  (name-is (elt f 1) "RENDER-JSON")
                  (consp (elt f 2))
                  (consp (first (elt f 2)))
                  (name-is (second (first (elt f 2))) class-name)))
           forms))

(defun accessors-in-value-form (form)
  "The slot accessors called anywhere inside a render-json VALUE form: (ord-date r) inside
   (nst-vordh-json-timestamp-date (ord-date r)), (cust-id r) inside (response-id-string (cust-id r)),
   or a bare (status r). Returns their names.

   ⚠ LOOKING ONLY AT THE IMMEDIATE SECOND ELEMENT IS THE BUG THIS FUNCTION EXISTS TO FIX: the
   first version required (cons \"k\" (accessor r)) exactly, so every field WRAPPED for formatting
   — all the dates, all the flags, all the identifiers, which is most of them — was reported as
   'mirrored but never sent'. A checked-by-machine claim is only as good as the machine's reading,
   and that failure mode looks exactly like a real defect in the code under test."
  (let ((found '()))
    (labels ((walk (x)
               (when (consp x)
                 (when (and (symbolp (car x))
                            (consp (cdr x))
                            (null (cddr x))
                            (name-is (second x) "R"))
                   (push (symbol-name (car x)) found))
                 (dolist (sub x) (walk sub)))))
      (walk form))
    (nreverse found)))

(defun render-json-published-slots (method-form)
  "The slot names render-json PUBLISHES, read off its (cons \"key\" <value>) pairs. The body IS
   the allowlist, so this is how it can be seen without running it — and an entry added to the
   mirror list but not here is a field that silently never reaches a client."
  (let ((found '()))
    (labels ((walk (x)
               (when (consp x)
                 (when (and (string= (form-head x) "CONS")
                            (> (length x) 2)
                            (stringp (elt x 1)))
                   (dolist (name (accessors-in-value-form (elt x 2)))
                     (push name found)))
                 (dolist (sub x) (walk sub)))))
      (walk method-form))
    (remove-duplicates (nreverse found) :test #'string=)))

(defun defparameter-symbols (forms name)
  (let ((form (find-form forms "DEFPARAMETER" name)))
    (when form (quoted-symbols form))))

(defun check-json-allowlist (published withheld mirror)
  "published + withheld == the RESPONSE MODEL's slots, exactly — which is the mirror list PLUS
   row-id, because domain->response sets row-id explicitly rather than walking the list for it.
   The header's rule: a slot added to the response model does NOT auto-leak, and a slot that is
   neither published nor withheld is a field that quietly stopped being sent.

   ⚠ COMPARING AGAINST THE MIRROR LIST ALONE IS WRONG AND WAS THE FIRST VERSION'S BUG: it reported
   ROW-ID as 'a slot that does not exist'. The universe is the boundary class, and the boundary
   class has one slot the list does not."
  (let ((universe (cons "ROW-ID" mirror)))
    (let ((overlap (intersection published withheld :test #'string=))
          (missing (set-difference universe (append published withheld) :test #'string=))
          (extra (set-difference (append published withheld) universe :test #'string=)))
      (when overlap
        (fail "published AND withheld at once (the sums cannot add up): ~{~A~^, ~}" overlap))
      (when missing
        (fail "carried by the response model but NEITHER published NOR withheld (silently never sent): ~{~A~^, ~}" missing))
      (when extra
        (fail "published/withheld but NOT carried by the response model (a key with no slot behind it): ~{~A~^, ~}" extra))
      (when (and (null overlap) (null missing) (null extra))
        (ok "the JSON allowlist is complete: ~D published + ~D withheld = ~D carried by the response model"
            (length published) (length withheld) (length universe))))))

(defun check-policy-partition (entity-slots lists control-keys)
  "Every entity slot sits in EXACTLY ONE policy list. LISTS is an alist of (label . symbols).
   An allowlist whose default is ALLOW is not an allowlist, so a slot that fell outside every list
   would be a field whose writability nobody decided.

   ⚠ CONTROL-KEYS ARE IN THE PARTITION BUT ARE NOT SUPPOSED TO BE SLOTS: they are transport
   preconditions and SCOPE (:if-match, :vendor-id), consumed before the policy and never assigned.
   The first version of this check called :if-match 'a typo that would refuse nothing'; the real
   invariant is the opposite one — a control key that IS a slot would be assignable, which is what
   the header's own note forbids. Both are asserted below."
  (let* ((inherited '("ID" "TENANT-ID" "CREATED-AT" "UPDATED-AT" "DELETED-STATE"))
         (universe (append entity-slots inherited control-keys))
         (all (apply #'append (mapcar #'cdr lists)))
         (dup (loop for k in all
                    when (> (count k all :test #'string=) 1) collect k))
         (unplaced (set-difference universe all :test #'string=))
         (stray (set-difference all universe :test #'string=))
         (slots-named-like-control (intersection entity-slots control-keys :test #'string=)))
    (when dup
      (fail "in MORE THAN ONE policy list (the partition is not a partition): ~{~A~^, ~}"
            (remove-duplicates dup :test #'string=)))
    (when unplaced
      (fail "in the entity but in NO policy list (writability undecided): ~{~A~^, ~}" unplaced))
    (when stray
      (fail "in a policy list but NOT a slot or a known control key (a typo): ~{~A~^, ~}" stray))
    (when slots-named-like-control
      (fail "a CONTROL KEY is also an entity slot (it would be assignable): ~{~A~^, ~}"
            slots-named-like-control))
    (when (and (null dup) (null unplaced) (null stray) (null slots-named-like-control))
      (ok "the field policy partitions the entity: ~{~D + ~}~D keys, every slot in exactly one list, no control key is a slot"
          (mapcar (lambda (cell) (length (cdr cell))) (butlast lists))
          (length (cdr (car (last lists))))))))

(let ((dal-forms (read-all-forms *source*)))
  (let ((mirror-form (find-form dal-forms "DEFPARAMETER" *mirror-list*))
        (entity-form (find-form dal-forms "DEFCLASS" *entity-class*))
        (bl-forms (read-all-forms *bl-source*)))
    (format t "~%== nst-vordh-mirror-check — BL: ~A~%" *bl-source*)
    (let ((*current-source* *bl-source*)
          (method (find-render-json bl-forms *response-class*)))
      (check-present "the render-json method" method)
      (check-present "the BL's withheld list" (find-form bl-forms "DEFPARAMETER" "*VORDH-JSON-WITHHELD-SLOTS*"))
      (check-present "the policy lists" (find-form bl-forms "DEFPARAMETER" "*VORDH-CALLER-WRITABLE-FIELDS*"))
      (when (and method mirror-form entity-form)
        (let ((published (render-json-published-slots method))
              (withheld (defparameter-symbols bl-forms "*VORDH-JSON-WITHHELD-SLOTS*"))
              (mirror (quoted-symbols mirror-form))
              (slots (class-slot-names entity-form)))
          (check-json-allowlist published withheld mirror)
          (check-policy-partition
           slots
           (list (cons "stripped" (defparameter-symbols bl-forms "*VORDH-UPDATE-STRIPPED-INITARGS*"))
                 (cons "control"  (defparameter-symbols bl-forms "*VORDH-UPDATE-CONTROL-KEYS*"))
                 (cons "caller"   (defparameter-symbols bl-forms "*VORDH-CALLER-WRITABLE-FIELDS*"))
                 (cons "internal" (defparameter-symbols bl-forms "*VORDH-INTERNAL-ONLY-FIELDS*"))
                 (cons "never"    (defparameter-symbols bl-forms "*VORDH-NEVER-WRITABLE-FIELDS*")))
           (defparameter-symbols bl-forms "*VORDH-UPDATE-CONTROL-KEYS*")))))))

(format t "~%== nst-vordh-mirror-check: ~:[FAIL~;PASS~] — ~D check(s), ~D problem(s) ==~%"
        (zerop *problems*) *checks* *problems*)
(finish-output)
(sb-ext:exit :code (if (zerop *problems*) 0 1))
