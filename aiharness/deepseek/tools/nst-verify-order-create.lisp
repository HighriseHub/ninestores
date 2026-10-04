;;; nst-verify-order-create.lisp — the CREATE's two PURE halves, checked offline:
;;;   1. the nested body-entry reader, against what the JSON decoder ACTUALLY produces;
;;;   2. the three domaintodb copiers, against a create that supplies only SOME fields.
;;;
;;;   cd /home/ubuntu/ninestores
;;;   XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --noinform --non-interactive \
;;;     --load aiharness/deepseek/tools/nst-verify-nested-params.lisp
;;;
;;; Exit 0 = pass. 1 = a check failed. 2 = setup problem.
;;;
;;; ── WHY THIS EXISTS, AND WHAT IT FOUND ──────────────────────────────────────────────────────
;;; 🚨 `POST /orders` HAD NEVER ONCE CREATED AN ORDER, AND THIS IS WHY. ordh-nested-param's list
;;; branch tested `(stringp k)` on the keys of a decoded body entry, and its docstring asserted
;;; "a decoded-JSON alist with string keys". MEASURED 2026-10-04 by running the decoder:
;;;
;;;   (json:decode-json-from-string "{\"items\":[{\"prdId\":1}]}")
;;;     → ((:ITEMS ((:PRD-ID . 1))))          ← keys are KEYWORDS, because cl-json interns each
;;;                                             JSON key as a keyword
;;;
;;; So the predicate matched NOTHING, and every create answered
;;;
;;;   400 {"error":"invalid_request","message":"every line must name a product row-id (prd-id); got NIL"}
;;;
;;; for EVERY spelling a client could send — probed live with prdId, prd-id, prdid, PRDID and
;;; productId, all identical. The refusal is raised in the READ HALF of the D14 assembly, BEFORE
;;; anything is written, so it read as a client mistake rather than as a defect in the API.
;;;
;;; ⚠ THE TOP LEVEL WAS NEVER AFFECTED, which is why it survived a whole batch: api-normalize-body-params
;;; converts the TOP-level object into a plist (handling keywords via api-json-key->param-key), so
;;; ONLY the nested entries ever reach ordh-nested-param in decoded form.
;;;
;;; ⚠ AND THE HYPHEN TRAP SITS ON TOP OF THE SYMBOL ONE, which is why the first fix was not enough.
;;; api-camel->lisp-name is built for camelCase INPUT ("warehouseGstin" → "WAREHOUSE-GSTIN"); handed
;;; an all-caps HYPHENATED name — exactly what (symbol-name :prd-id) is — it inserts a hyphen before
;;; every letter, so "PRD-ID" becomes "P-R-D-I-D". Only the hyphenless form survives that, and the
;;; entry's own key "PRD-ID" is not hyphenless, so comparing raw strings matches nothing. The reader
;;; therefore compares HYPHENLESS forms on BOTH sides. The first version of the fix was caught here
;;; by exactly this file: `qty` passed ("QTY" has no hyphen to lose) while `prd-id` did not.
;;;
;;; ── AND THE SECOND HALF: `slot-value` ON AN UNBOUND SLOT SIGNALS ────────────────────────────
;;; With the reader fixed, the create advanced to the WRITE half and died there with a second 500:
;;;
;;;   The slot COM.NSTORES.APP::SHIPPED-DATE is unbound in the object #<NST-ORDH {…}>
;;;     at NST-COPY-ORDER-HEADER-DOMAINTODB
;;;
;;; after the order number had ALREADY been minted. A create binds only what the caller sent, so
;;; every OPTIONAL field in a mirror list is unbound, and the unguarded `(slot-value source f)` in
;;; the copy loop signals. The same three lines stood in all THREE copiers (header, line, vendor),
;;; so the guard lives in one helper: nst-db-slot-value-from-domain (core/dod-bl-utl.lisp).
;;; ⚠ AND AN INITFORM-BOUND SLOT MUST STILL COPY: the 0.0 money initforms and the "N"/"Y" flags
;;; must survive, or the fix would blank them — which is why the check asserts 0.0 and "N" as well
;;; as NIL.
;;;
;;; ── WHAT IT ASSERTS, AND WHY EACH CASE IS THERE ─────────────────────────────────────────────
;;; 1. the DECODED shape, taken from cl-json itself rather than hand-written;
;;; 2. the same thing THROUGH THE REAL PATH — decode → api-normalize-body-params → ordh-lines-array
;;;    → the entry — which is the composition the route actually performs;
;;; 3-6. every spelling that must KEEP working (string keys, hyphenless keys, the keyword-plist
;;;    "offline/agent" spelling): a fix for one spelling that breaks another is not a fix;
;;; 7-8. the negatives: an absent key is NIL and a NIL entry is NIL — never an error, because a
;;;    malformed line must be REFUSED by the reader's caller, not crash it.
;;;
;;; Then: MUTATE IT BEFORE TRUSTING IT. Change the comparison back to `(stringp k)` and this file
;;; must exit 1 naming the decoded cases; that was verified when it was written.

(defparameter *clsql-dist-dir* #p"/tmp/nst-asdf/clsql-dist/clsql-20221106-git/")

(load "~/quicklisp/setup.lisp")
(push "/home/ubuntu/ninestores/hhub/" asdf:*central-registry*)
(if (probe-file *clsql-dist-dir*)
    (push *clsql-dist-dir* asdf:*central-registry*)
    (progn (format t "~&SETUP PROBLEM: ~A is missing — see nst-offline-load.lisp for the copy.~%"
                   *clsql-dist-dir*)
           (sb-ext:exit :code 2)))

(ql:quickload :swank :silent t)
(ql:quickload '(:uuid :secure-random :drakma :cl-json :cl-who :hunchentoot :clsql :clsql-mysql
                :cl-smtp :parenscript :cl-async :cl-csv :cl-base64 :priority-queue :blackbird
                :cl-yaml) :silent t)
(handler-case (ql:quickload :nstores :silent t)
  (error (c) (format t "~&SETUP PROBLEM — the tree did not load: ~A~%" c) (sb-ext:exit :code 2)))
(format t "~&STAGE: the tree compiled from source and LOADED~%")

;; ⚠ EVERY FORM BELOW IS READ AFTER THIS TOP-LEVEL (in-package …), which is the trap this corpus
;; records three times: the tree has ONE package, and a probe left in CL-USER fails with
;; "the function … is undefined" AFTER a multi-minute load, which reads exactly like a missing defun.
(in-package :nstores)

(let ((pass 0) (fail 0))
  (flet ((chk (label got want)
           (if (equal got want)
               (progn (incf pass) (format t "~&  ok    ~A => ~S~%" label got))
               (progn (incf fail) (format t "~&  FAIL  ~A => ~S, want ~S~%" label got want)))))
    (format t "~&== 1-2. the DECODED shape, and the real decode path~%")
    (let ((entry (json:decode-json-from-string "{\"prdId\":5,\"qty\":2}")))
      (format t "~&  info  cl-json gives: ~S~%" entry)
      (chk "a decoded entry (:PRD-ID)" (ordh-nested-param entry :prd-id) 5)
      (chk "a decoded entry (:QTY)"    (ordh-nested-param entry :qty) 2))
    (let* ((decoded (json:decode-json-from-string "{\"items\":[{\"prdId\":7,\"qty\":3}]}"))
           (params  (api-normalize-body-params decoded))
           (lines   (ordh-lines-array params)))
      (format t "~&  info  params -> ~S~%" params)
      (chk "through decode → normalize → ordh-lines-array" (ordh-nested-param (car lines) :prd-id) 7))

    (format t "~&== 3-6. every spelling that must still work~%")
    (chk "string keys, camelCase"   (ordh-nested-param '(("prdId" . 9)) :prd-id) 9)
    (chk "string keys, hyphenless"  (ordh-nested-param '(("prdid" . 11)) :prd-id) 11)
    (chk "symbol keys, hyphenless"  (ordh-nested-param '((:PRDID . 13)) :prd-id) 13)
    (chk "keyword plist (agent)"    (ordh-nested-param '(:prd-id 17) :prd-id) 17)

    (format t "~&== 7-8. the negatives~%")
    (chk "an absent key is NIL"     (ordh-nested-param '((:QTY . 1)) :prd-id) nil)
    (chk "a NIL entry is NIL"       (ordh-nested-param nil :prd-id) nil)


    (format t "~&== 9-13. the copiers, against a create that supplies ONLY some fields~%")
    ;; Every make below passes the fields a CREATE actually passes — no more — which is exactly what
    ;; made the unguarded read signal. Before the fix, the first one of these raised UNBOUND-SLOT.
    (flet ((copies (label build copier destination probe)
             (handler-case
                 (let ((d (funcall copier (funcall build) (funcall destination))))
                   (funcall probe d)
                   (incf pass) (format t "~&  ok    ~A => no signal~%" label))
                 (error (c) (incf fail) (format t "~&  FAIL  ~A => SIGNALLED: ~A~%" label c)))))
      (copies "nst-ordh -> dod-order, optional fields absent"
              (lambda () (make-instance 'nst-ordh :tenant-id 2 :ordnum "ORD-VERIFY-2026-27-AAAAAA"
                                                  :status "DFT" :context-id "verify" :cust-id 1))
              #'nst-copy-order-header-domaintodb
              (lambda () (make-instance 'dod-order))
              (lambda (d)
                (chk "  … and an ABSENT optional field lands as NIL"
                     (slot-value d 'shipped-date) nil)
                (chk "  … and a class-initformed MONEY field keeps 0.0, not NIL"
                     (slot-value d 'order-amt) 0.0)
                (chk "  … and a SUPPLIED value still copies" (slot-value d 'status) "DFT")))
      (copies "nst-ordh -> dod-order, integer money widened"
              (lambda () (make-instance 'nst-ordh :tenant-id 2 :ordnum "ORD-VERIFY-2026-27-BBBBBB"
                                                  :status "DFT" :order-amt 100))
              #'nst-copy-order-header-domaintodb
              (lambda () (make-instance 'dod-order))
              (lambda (d) (chk "  … integer 100 -> 100.0 (CLSQL validates the declared type)"
                               (slot-value d 'order-amt) 100.0)))
      (copies "nst-orditm -> dod-order-items, optional fields absent"
              (lambda () (make-instance 'nst-orditm :tenant-id 2 :order-id 1 :vendor-id 1 :prd-id 1
                                                    :prd-qty 2))
              #'nst-copy-order-item-domaintodb
              (lambda () (make-instance 'dod-order-items))
              (lambda (d) (chk "  … its description is NIL, not a signal"
                               (slot-value d 'item-description) nil)))
      (copies "nst-vordh -> dod-vendor-order, optional fields absent"
              (lambda () (make-instance 'nst-vordh :tenant-id 2 :order-id 1 :vendor-id 1 :cust-id 1
                                                   :ordnum "ORD-VERIFY-2026-27-CCCCCC" :status "PEN"))
              #'nst-copy-vendor-order-domaintodb
              (lambda () (make-instance 'dod-vendor-order))
              (lambda (d)
                ;; ⚠ ord-date is deliberately NOT read off a fresh entity here: THAT read is the
                ;; very thing that signals. The copier's own no-signal result is the assertion.
                (chk "  … an absent optional field is NIL" (slot-value d 'comments) nil)
                ;; ⚠ THE DESTINATION's slot IS bound (a fresh CLSQL row binds its slots), so the
                ;; question is not slot-boundp — it is that an UNSENT date lands as NIL rather than
                ;; being invented. In the real assembly ord-date IS supplied (S11's
                ;; ordh-vendor-row-initargs passes it); this is the layer's answer when it is not.
                (chk "  … and an unsent date stays NIL rather than being invented"
                     (slot-value d 'ord-date) nil)))))

    (format t "~&== 14-16. EVERY slot of a FRESH entity, read through its accessor~%")
    ;; ⚠ THIS IS THE CLASS-LEVEL CHECK, and it is the one that matters: the create binds only the
    ;; fields the caller sent, so EVERY optional slot must answer rather than signal, or the next
    ;; reader of a fresh entity is a landmine. Two were found this way — the domaintodb copier and
    ;; ordh-vendor-row-initargs (which reads ~45 of them through ACCESSORS, and accessors signal on
    ;; an unbound slot exactly like slot-value). Scanning all slots means a NEW slot added without
    ;; an initform fails here immediately instead of in production.
    (dolist (cls '(nst-ordh nst-orditm nst-vordh))
      (let ((entity (make-instance cls :tenant-id 2))
            (unbound '()))
        (dolist (slot (sb-mop:class-slots (find-class cls)))
          (let ((name (sb-mop:slot-definition-name slot)))
            (handler-case (progn (slot-value entity name) nil)
              (unbound-slot () (push name unbound))
              (error () nil))))
        (if unbound
            (progn (incf fail)
                   (format t "~&  FAIL  ~A has ~D UNBOUND slot(s) on a fresh instance: ~S~%"
                           cls (length unbound) (sort (mapcar #'symbol-name unbound) #'string<)))
            (progn (incf pass)
                   (format t "~&  ok    every slot of a fresh ~A answers (0 unbound of ~D)~%"
                           cls (length (sb-mop:class-slots (find-class cls))))))))

    ;; ⚠ NOT `~:[FAIL (~D problem(s))~;PASS~]`. That form consumes only ONE argument after the
    ;; conditional, so the counts bind to the wrong `~D`s and a passing run printed
    ;; "PASS — 0 check(s), 9 problem(s)" — a report that lies about its own numbers, which this
    ;; corpus has already paid for three times. Both counts are printed explicitly instead.
    (format t "~&~%== nst-verify-order-create: ~A — ~D check(s), ~D problem(s)~%"
            (if (zerop fail) "PASS" "FAIL") (+ pass fail) fail)
    (sb-ext:exit :code (if (zerop fail) 0 1))))
