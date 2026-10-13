;;; nst-invoice-mirror-check.lisp — verify that the INVOICE mirror lists and the
;;; invoice BOUNDARY models agree, WITHOUT a build, a database or the live image.
;;;
;;;   cd /home/ubuntu/ninestores && mkdir -p .asdf-cache
;;;   XDG_CACHE_HOME=/home/ubuntu/ninestores/.asdf-cache \
;;;     sbcl --noinform --non-interactive \
;;;          --load aiharness/deepseek/tools/nst-invoice-mirror-check.lisp
;;;
;;; Exit code 0 = every mirrored slot is declared on both sides and every setf
;;; succeeds. 1 = drift. Read the FAIL block; it names the slot.
;;;
;;; ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
;;; *invh-mirrored-slots* / *invitm-mirrored-slots* drive THREE consumers:
;;;
;;;   1. nst-copy-invoice-*-domaintodb   (domain → DB)
;;;   2. nst-copy-invoice-*-dbtodomain   (DB → domain)
;;;   3. domain->response                (domain → BOUNDARY model)
;;;
;;; The first two are why the list exists, and adding a column to it is safe for
;;; them. The third setfs EVERY slot in the list onto NstInvhResponseModel /
;;; NstInvitmResponseModel — so a slot named in the list but not DECLARED on the
;;; boundary model signals MISSING-SLOT, and every route for that entity answers
;;; 500. `deleted-state` sat in exactly that hole and took the whole invoice API
;;; down: seven bound endpoints, all 500, from the day the files were written.
;;;
;;; NOTHING ELSE CATCHES IT. `compile-file` does not evaluate the setf, so the
;;; isolated compile-check in knowledge/build-and-load-CONTEXT.md §6 passes; a
;;; name-level audit ("is every bound route registered?") passes; the load path
;;; succeeds; and `GET /hhub/api/v1/invoices` without a session answers 401,
;;; which looks like health. Only a real response — or this — exercises the setf.
;;;
;;; This is the ONLY place in the tree where the pattern applies: nst-whs's
;;; domain->response is longhand (one setf per field), so warehouse cannot drift
;;; this way. If another entity adopts the list-driven form, add it to *PAIRS*.
;;;
;;; ── HOW IT READS THE LISTS ──────────────────────────────────────────────────
;;; The lists are read from the SOURCE with the Lisp reader, not copied here — a
;;; copy would be one more thing to forget to update, which is the whole disease.
;;; That needs clsql's `[= …]` reader syntax enabled for the whole file, because
;;; the .lisp sources are full of it (build-and-load-CONTEXT.md §8).

(load "~/quicklisp/setup.lisp")
(dolist (s (list :uuid :clsql :hunchentoot :cl-json :cl-csv)) (ql:quickload s :silent t))

;; `in-package`-neutral: read the sources in the package they were written for.
(load "hhub/package/packages.lisp")
(clsql:file-enable-sql-reader-syntax)
(load "hhub/core/nst-bl-adhara.lisp")
(load "hhub/invoice/nst-dal-invh.lisp")
(load "hhub/invoice/nst-dal-invitm.lisp")
;; 🚨 THE CLSQL VIEW CLASSES ARE LOADED TOO, AND THAT IS THE WHOLE POINT OF THE THIRD SIDE
;; BELOW. nst-copy-invoice-header-domaintodb drives (setf (slot-value destination slot) …)
;; over the mirror list, and `destination` is a dod-Invoice-Header / dod-invoice-items — NOT
;; the domain class. A mirrored column absent from the view class is a MISSING-SLOT that
;; aborts the INSERT. MEASURED on order 508's Generate Invoice (2026-10-12):
;;   the slot COM.NSTORES.APP::ORDER-NUMBER is missing from
;;   #<COM.NSTORES.APP::DOD-INVOICE-HEADER>
;; This checker reported PASS through that whole defect, because it only ever compared the
;; mirror list against the DOMAIN and RESPONSE classes. Both files are legacy DDD sources
;; but they define the classes the new copiers write, and they read cleanly here.
(load "hhub/invoice/nst-dal-ihd.lisp")
(load "hhub/invoice/nst-dal-itm.lisp")

(in-package :nstores)

(defparameter *pairs*
  '(("hhub/invoice/nst-bl-invh.lisp"   "*INVH-MIRRORED-SLOTS*"
     nst-invh  NstInvhResponseModel   "HEADER  nst-invh  -> NstInvhResponseModel"
     dod-Invoice-Header)
    ("hhub/invoice/nst-bl-invitm.lisp" "*INVITM-MIRRORED-SLOTS*"
     nst-invitm NstInvitmResponseModel "ITEM    nst-invitm -> NstInvitmResponseModel"
     dod-invoice-items))
  "The (source-file, defparameter-name, entity-class, response-class, label, VIEW-class)
   pairs this check knows about. All four of the invoice ones follow the list-driven form;
   nothing else in the tree does.

   ⚠ THE SIXTH ELEMENT IS THE CLSQL VIEW CLASS THE COPYERS WRITE, and it was missing until
   2026-10-12 — which is why a MISSING-SLOT on `dod-Invoice-Header` reached production. The
   mirror list drives THREE consumers (the two copiers AND domain->response); this check
   covered only the domain/response pair, never the object the copiers actually write.")

(defun read-mirrored-slots (path name)
  "The slot list from PATH's (defparameter NAME '…) — read, never copied.
   Scans top-level forms with the reader so the file's own quoting and clsql
   syntax are honoured."
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
  "NOTE: sb-mop:finalize-inheritance returns NO VALUES in SBCL — calling
   class-slots on its result passes NIL and signals no-applicable-method. The
   class object must be kept and passed. (This cost a cycle while writing this.)"
  (let ((c (find-class class-name)))
    (sb-mop:finalize-inheritance c)
    (mapcar #'sb-mop:slot-definition-name (sb-mop:class-slots c))))

(defun check-pair (path name entity-class response-class label view-class)
  "→ number of problems found. The VIEW-CLASS side is the one that catches the defect that
   reached order 508: a mirrored column the DOMAIN carries but the CLSQL row class does not."
  (let ((slots (read-mirrored-slots path name)))
    (if (null slots)
        (progn (format t "~&== ~A ==~%  FAIL: ~A not found in ~A~%" label name path) 1)
        (let ((entity-slots   (class-slot-names entity-class))
              (view-slots     (when (find-class view-class nil) (class-slot-names view-class)))
              ;; The ENTITY is not instantiated on purpose: its slot initforms
              ;; reach mysql-now and other core functions this file does not load,
              ;; so make-instance would signal undefined-function. Its own slots
              ;; are read off the class instead, which is the mirror property that
              ;; actually matters. The RESPONSE model IS instantiated, because the
              ;; operation under test is a setf on it.
              (response (make-instance response-class :row-id "1"))
              (missing-on-response '()) (missing-on-entity '()) (missing-on-view '())
              (failed '()) (ok 0))
          (dolist (slot slots)
            (if (slot-exists-p response slot)
                (handler-case (progn (setf (slot-value response slot) :probe) (incf ok))
                  (error (c) (push (list slot (princ-to-string c)) failed)))
                (push slot missing-on-response))
            (unless (member slot entity-slots) (push slot missing-on-entity))
            ;; ⚠ A MISSING VIEW CLASS IS ITSELF A FAILURE, not a skip: silently passing
            ;; when the class was not loaded is how a check reports a healthy file green.
            (when (and view-slots (not (member slot view-slots)))
              (push slot missing-on-view)))
          (when (null view-slots)
            (format t "~&  ⚠ ~A NOT LOADED/not found — the copier target was NOT checked~%" view-class))
          (format t "~&== ~A ==~%  mirrored list       = ~D slots~%  setf on response    = ~D OK~%  MISSING on RESPONSE = ~S~%  MISSING on ENTITY   = ~S~%  MISSING on VIEW (~A) = ~S~%  other errors        = ~S~%"
                  label (length slots) ok
                  (reverse missing-on-response) (reverse missing-on-entity)
                  view-class (reverse missing-on-view) (reverse failed))
          (+ (length missing-on-response) (length missing-on-entity)
             (length missing-on-view) (length failed) (if view-slots 0 1))))))

(let ((problems 0))
  (format t "~&invoice mirror check — no image, no database, no build~%")
  (dolist (p *pairs*)
    (incf problems (apply #'check-pair p)))
  (format t "~&~%VERDICT: ~A~%"
          (if (zerop problems)
              "PASS - every mirrored slot is declared on BOTH the entity and the response model, and every setf succeeds. domain->response cannot signal MISSING-SLOT."
              (format nil "FAIL - ~D problem(s). A slot in the list is missing from the class named above; every route for that entity will answer 500 until it is declared." problems)))
  (sb-ext:exit :code (if (zerop problems) 0 1)))
