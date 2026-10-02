;;; nst-order-mirror-check.lisp — verify the ORDER mirror lists, and the order JSON
;;; allowlist, WITHOUT a build, a database or the live image.
;;;
;;;   cd /home/ubuntu/ninestores && mkdir -p .asdf-cache
;;;   XDG_CACHE_HOME=/home/ubuntu/ninestores/.asdf-cache \
;;;     sbcl --noinform --non-interactive \
;;;          --load aiharness/deepseek/tools/nst-order-mirror-check.lisp
;;;
;;; Exit 0 = every mirrored slot is declared on both sides, every setf succeeds, and the
;;; render allowlist accounts for every response-model slot. 1 = drift. Read the FAIL block;
;;; it names the slot.
;;;
;;; ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
;;; *ordh-mirrored-slots* / *orditm-mirrored-slots* drive THREE consumers:
;;;
;;;   1. nst-copy-order-*-domaintodb   (domain → DB)
;;;   2. nst-copy-order-*-dbtodomain   (DB → domain)
;;;   3. domain->response              (domain → BOUNDARY model)
;;;
;;; The third setfs EVERY slot in the list onto NstOrdhResponseModel /
;;; NstOrditmResponseModel — so a slot named in the list but not DECLARED on the boundary
;;; model signals MISSING-SLOT, and every route for that entity answers 500. That is not
;;; hypothetical: `deleted-state` sat in exactly that hole on the invoice side and took seven
;;; bound endpoints down from the day they were written. NOTHING ELSE CATCHES IT —
;;; compile-file does not evaluate the setf, the load path succeeds, and an unauthenticated
;;; GET answers 401, which looks like health.
;;;
;;; ── AND THE OTHER DIRECTION, WHICH NOTHING ELSE CHECKS AT ALL ───────────────
;;; §2 reads the render-json method's own alist and asserts:
;;;
;;;   published + withheld = every response-model slot
;;;
;;; An outbound allowlist written field by field SILENTLY DROPS a slot added later: it never
;;; leaves the system, no error is raised anywhere, and the response is merely quietly
;;; incomplete. Naming the withheld set (the BL file's *ordh-json-withheld-slots*) turns that
;;; silence into a failed sum, so a new slot forces a decision instead of a shrug. §2 also
;;; checks the JSON keys are unique — a duplicated key silently loses one field in most
;;; encoders — and that no withheld slot is published.
;;;
;;; ── HOW IT READS THE LISTS ──────────────────────────────────────────────────
;;; From the SOURCE with the Lisp reader, never copied here: a copy would be one more thing to
;;; forget to update, which is the whole disease. That needs clsql's [= …] reader syntax
;;; enabled for the whole file, because the BL source is full of it.

(load "~/quicklisp/setup.lisp")
(dolist (s (list :uuid :clsql :hunchentoot :cl-json :cl-csv)) (ql:quickload s :silent t))

;; `in-package`-neutral: read the sources in the package they were written for.
(load "hhub/package/packages.lisp")
(clsql:file-enable-sql-reader-syntax)
(load "hhub/core/nst-bl-adhara.lisp")
(load "hhub/order/nst-dal-ordh.lisp")
(load "hhub/order/nst-dal-orditm.lisp")

(in-package :nstores)

(defparameter *bl-path* "hhub/order/nst-bl-ordh.lisp")

(defparameter *itm-path* "hhub/order/nst-bl-orditm.lisp"
  "The LINE entity's BL file. Its render allowlist is checked by the same code as the
   header's — S7 gave the line its own withheld set, so §2 has one implementation and two
   callers rather than a header-only check that a second entity could silently fall outside
   of.")

(defparameter *pairs*
  '(("hhub/order/nst-dal-ordh.lisp"   "*ORDH-MIRRORED-SLOTS*"
     nst-ordh  NstOrdhResponseModel   "HEADER nst-ordh  -> NstOrdhResponseModel")
    ("hhub/order/nst-dal-orditm.lisp" "*ORDITM-MIRRORED-SLOTS*"
     nst-orditm NstOrditmResponseModel "ITEM   nst-orditm -> NstOrditmResponseModel"))
  "The (source-file, defparameter-name, entity-class, response-class, label) pairs this
   check knows about. Both order entities follow the list-driven form. NOTE the lists live in
   the DAL files, not the BL — a deliberate deviation from the invoice's layout, so the list
   and the two classes it must match are edited in one file (story file, S1+ S2).")

(defun read-mirrored-slots (path name)
  "The slot list from PATH's (defparameter NAME '…) — read, never copied. Scans top-level
   forms with the reader so the file's own quoting and clsql syntax are honoured. The lists
   this reads are flat quoted lists of slot names (and the withheld set is a third such list),
   so the third element IS the list."
  (let ((wanted (string-upcase name)))
    (with-open-file (in path :external-format :utf-8)
      (loop for form = (handler-case (read in nil :eof)
                         (error (c)
                           (format t "~&  READ ERROR in ~A: ~A~%" path c)
                           :eof))
            until (eq form :eof)
            when (and (consp form)
                      (eq (first form) 'defparameter)
                      (string= (string (second form)) wanted))
              return (let ((value (third form)))
                       (if (and (consp value) (eq (first value) 'quote))
                           (second value)
                           value))
            finally (return nil)))))

(defun class-slot-names (class-name)
  "NOTE: sb-mop:finalize-inheritance returns NO VALUES in SBCL — calling class-slots on its
   result passes NIL and signals no-applicable-method. The class object must be kept and
   passed. (This cost a cycle while the invoice tool was written.)"
  (let ((c (find-class class-name)))
    (sb-mop:finalize-inheritance c)
    (mapcar #'sb-mop:slot-definition-name (sb-mop:class-slots c))))

;;; ── 1. the mirror lists vs the entity and the boundary model ────────────────

(defun check-pair-counted (path name entity-class response-class label)
  "→ number of problems, computed rather than announced."
  (let ((slots (read-mirrored-slots path name))
        (bad 0))
    (if (null slots)
        (progn (format t "~&== ~A ==~%  FAIL: ~A not found in ~A~%" label name path) 1)
        (let ((entity-slots (class-slot-names entity-class))
              (response (make-instance response-class :row-id "1"))
              (missing-on-response '()) (missing-on-entity '()) (failed '()) (ok 0))
          (dolist (slot slots)
            (if (slot-exists-p response slot)
                (handler-case (progn (setf (slot-value response slot) :probe) (incf ok))
                  (error (c) (push (list slot (princ-to-string c)) failed)))
                (push slot missing-on-response))
            (unless (member slot entity-slots) (push slot missing-on-entity)))
          (format t "~&== ~A ==~%  mirrored list       = ~D slots~%  setf on response    = ~D OK~%  MISSING on RESPONSE = ~S~%  MISSING on ENTITY   = ~S~%  other errors        = ~S~%"
                  label (length slots) ok
                  (reverse missing-on-response) (reverse missing-on-entity) (reverse failed))
          (when (or (null entity-slots) (zerop ok))
            (format t "~&  FAIL  ~A: the probes found nothing to check (entity slots ~D, successful setfs ~D) — this section would pass VACUOUSLY~%"
                    label (length entity-slots) ok)
            (incf bad))
          (when missing-on-response
            (format t "~&  FAIL  ~A: mirrored slot(s) NOT DECLARED on the response model: ~S — every route for this entity answers 500~%"
                    label (reverse missing-on-response))
            (incf bad))
          (when missing-on-entity
            (format t "~&  FAIL  ~A: mirrored slot(s) not on the entity class: ~S — the copiers would signal~%"
                    label (reverse missing-on-entity))
            (incf bad))
          (when failed
            (format t "~&  FAIL  ~A: setf raised on ~S~%" label (reverse failed))
            (incf bad))
          bad))))

;;; ── 2. the outbound allowlist: published + withheld = every response slot ───

(defun walk-symbols (form)
  "Every symbol mentioned in FORM, at any depth. Strings and numbers are not symbols."
  (let ((acc '()))
    ;; NOT named GO: GO is a CL special operator, and SBCL rejects it as a local function
    ;; name with 'Special form is an illegal function name' — measured, not guessed.
    (labels ((walk (f)
               (cond ((symbolp f) (pushnew f acc))
                     ((consp f) (walk (car f)) (walk (cdr f)))
                     (t nil))))
      (walk form))
    acc))

(defun render-entries (path response-class)
  "The (KEY . SYMBOLS) pairs of the (defmethod render-json ((r RESPONSE-CLASS) …)) form in
   PATH, read from source. NIL when the method is not there — which is itself reported."
  (let ((want (string response-class)))
    (with-open-file (in path :external-format :utf-8)
      (loop for form = (handler-case (read in nil :eof)
                         (error (c) (format t "~&  READ ERROR in ~A: ~A~%" path c) :eof))
            until (eq form :eof)
            when (and (consp form)
                      (eq (first form) 'defmethod)
                      (eq (second form) 'render-json)
                      (let ((ll (third form)))
                        (and (consp ll) (consp (first ll))
                             (string= (string (second (first ll))) want))))
              return (let ((entries '()))
                       (labels ((scan (f)
                                  (when (consp f)
                                    (if (and (eq (car f) 'cons) (stringp (cadr f)))
                                        (push (cons (cadr f) (walk-symbols (caddr f))) entries)
                                        (progn (scan (car f)) (scan (cdr f)))))))
                         (scan form))
                       (nreverse entries))
            finally (return nil)))))

(defparameter *boundary-inherited-slots* '(id params)
  "Slots NstOrdhResponseModel inherits from the BOUNDARY tree rather than declaring:
   nst-boundary-object's synthetic `id` (a uuid, NOT the row's row-id) and
   nst-response-model's `params` (the transport bag, which for a sentinel carries the error
   reason). Neither is domain state, neither is ever published, and BOTH would otherwise be
   reported as unaccounted fields on every run — the check found exactly that on its first
   run, which is why it is named here rather than filtered silently.")

(defun check-json-allowlist (path response-class withheld-list-name)
  "→ number of problems. Asserts the render allowlist is COMPLETE against the response
   model's own slots, and that its keys are unique. WITHHELD-LIST-NAME is read from PATH,
   not passed in, so the check cannot be handed a stale copy of the file's own decision."
  (format t "~&== JSON allowlist: ~A (~A) ==~%" response-class withheld-list-name)
  (let* ((withheld (read-mirrored-slots path withheld-list-name))
         (slots (remove-if (lambda (s) (member s *boundary-inherited-slots*))
                           (class-slot-names response-class)))
         (entries (render-entries path response-class))
         (bad 0))
    (when (null entries)
      (format t "~&  FAIL  no render-json method for ~A found in ~A~%" response-class path)
      (return-from check-json-allowlist 1))
    (let* ((keys (mapcar #'car entries))
           (published (remove-duplicates
                       (loop for (k . syms) in entries
                             append (remove-if-not (lambda (s) (member s slots)) syms))))
           (dupes (loop for k in (remove-duplicates keys :test #'string=)
                        when (> (count k keys :test #'string=) 1) collect k))
           (absent (remove-if (lambda (s) (member s published)) slots))
           (unaccounted (remove-if (lambda (s) (member s withheld)) absent))
           (leaked (intersection published withheld)))
      (format t "~&  info  response slots = ~D, render entries = ~D keys, published = ~D slots, withheld = ~D~%"
              (length slots) (length keys) (length published) (length withheld))
      (when (or (null slots) (< (length keys) 10))
        (format t "~&  FAIL  the extractor found almost nothing (slots ~D, keys ~D) — this section would pass VACUOUSLY~%"
                (length slots) (length keys))
        (incf bad))
      (when dupes
        (format t "~&  FAIL  duplicate JSON key(s) ~S — most encoders keep one and silently drop the other field~%" dupes)
        (incf bad))
      (when unaccounted
        (format t "~&  FAIL  response slot(s) NEITHER PUBLISHED NOR WITHHELD: ~S — a field that silently never leaves the system. Publish it in render-json, or name it in ~A ON PURPOSE~%"
                unaccounted withheld-list-name)
        (incf bad))
      (when leaked
        (format t "~&  FAIL  slot(s) named as WITHHELD yet published: ~S~%" leaked)
        (incf bad))
      (when (> (length published) (length slots))
        (format t "~&  FAIL  more published slots than the class declares — the extractor is matching foreign symbols~%")
        (incf bad))
      bad)))

(let ((problems 0))
  (format t "~&order mirror check — no image, no database, no build~%")
  (dolist (p *pairs*)
    (incf problems (apply #'check-pair-counted p)))
  (dolist (case (list (list *bl-path*  'NstOrdhResponseModel  "*ORDH-JSON-WITHHELD-SLOTS*")
                      (list *itm-path* 'NstOrditmResponseModel "*ORDITM-JSON-WITHHELD-SLOTS*")))
    (incf problems (apply #'check-json-allowlist case)))
  (format t "~&~%VERDICT: ~A~%"
          (if (zerop problems)
              "PASS - every mirrored slot is declared on BOTH the entity and the response model, every setf succeeds, and published + withheld = every response-model slot."
              (format nil "FAIL - ~D problem(s), named above. Either a slot in a mirror list is missing from a class (every route for that entity answers 500), or a response-model slot is neither published nor withheld (it silently never leaves the system)." problems)))
  (sb-ext:exit :code (if (zerop problems) 0 1)))
