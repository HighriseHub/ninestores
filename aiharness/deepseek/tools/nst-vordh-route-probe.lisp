;;; nst-vordh-route-probe.lisp — WHAT THE LIVE ROUTE TABLE RESOLVES FOR THE VENDOR PATHS (S11).
;;;
;;;   cd /home/ubuntu/ninestores
;;;   # ONE-TIME setup, shared with nst-offline-load.lisp (see its header):
;;;   #   mkdir -p /tmp/nst-asdf/clsql-dist
;;;   #   cp -rp /home/ubuntu/quicklisp/dists/quicklisp/software/clsql-20221106-git \
;;;   #          /tmp/nst-asdf/clsql-dist/ && chmod -R u+w /tmp/nst-asdf/clsql-dist
;;;   XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --noinform --non-interactive \
;;;     --load aiharness/deepseek/tools/nst-vordh-route-probe.lisp
;;;
;;; Exit 0 = every expectation held. 1 = at least one FAIL, named.
;;;
;;; ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
;;;
;;;  * S13 (c) HAS BEEN OPEN SINCE THE CUSTOMER CHANNEL SHIPPED: '/vendor/orders and /orders do not
;;;    shadow each other — confirm find-api-route's fewest-parameters-first ranking resolves both'.
;;;    It could not be tested because the vendor paths did not exist. They do now, and the question
;;;    is answerable WITHOUT a session, a login or a database write: it is a pure lookup in the
;;;    route table the tree builds as it loads.
;;;
;;;  * A BINDING THAT IS PRESENT IN THE SOURCE IS NOT A BINDING THAT RESOLVES. nst-binding-order-check
;;;    proves the ORDER of the two forms in the file, from source; this proves the RESULT — that the
;;;    table the loaded image actually holds answers each path with the route intended, and that the
;;;    parameterised segment carries the value through. The two checks fail differently on purpose:
;;;    that one catches a file that would refuse to load, this one catches a path that resolves to
;;;    somebody else's route.
;;;
;;; ⚠ IT NEEDS NO SESSION AND WRITES NOTHING. find-api-route is a read of *api-route-registry*; the
;;;    tree is loaded but no acceptor is started and start-das is NOT called, so nothing binds a port
;;;    and no session secret is reset (which would log every live user out — see
;;;    knowledge/build-and-load-CONTEXT.md §7).

(defparameter *clsql-dist-dir* #p"/tmp/nst-asdf/clsql-dist/clsql-20221106-git/")

(load "~/quicklisp/setup.lisp")
(push "/home/ubuntu/ninestores/hhub/" asdf:*central-registry*)
(when (probe-file *clsql-dist-dir*)
  (push *clsql-dist-dir* asdf:*central-registry*))

;; swank first: the tree READS the swank package at compile time, and a missing package reports as a
;; READ error in a file that is perfectly fine.
(ql:quickload :swank :silent t)
(ql:quickload '(:uuid :secure-random :drakma :cl-json :cl-who :hunchentoot
                :clsql :clsql-mysql :cl-smtp :parenscript :cl-async :cl-csv
                :cl-base64 :priority-queue :blackbird :cl-yaml) :silent t)

(format t "~&== loading :nstores (no acceptor, nothing written)~%")
(ql:quickload :nstores :silent t)
(format t "== loaded~%")

;;; ⚠ EVERYTHING BELOW IS IN THE TREE'S OWN PACKAGE. find-api-route and api-route-key are symbols of
;;; :NSTORES — the tree has ONE package — so a probe left in CL-USER dies with
;;; "The function COMMON-LISP-USER::FIND-API-ROUTE is undefined" AFTER the whole tree has loaded,
;;; which reads like a missing binding rather than a missing in-package. That is how this file's
;;; first version failed, and the error is recorded here because it is a two-minute trap.
(in-package :nstores)

(defvar *problems* 0)
(defvar *checks* 0)

(defun ok (fmt &rest args)
  (incf *checks*)
  (format t "   ok    ~A~%" (apply #'format nil fmt args)))

(defun fail (fmt &rest args)
  (incf *problems*)
  (format t "   FAIL  ~A~%" (apply #'format nil fmt args)))

;;; ── the probe ───────────────────────────────────────────────────────────────

(defun route-key-of (method path)
  "The route key find-api-route resolves for METHOD+PATH, or NIL."
  (let ((route (find-api-route method path)))
    (and route (api-route-key route))))

(defun expect-route (method path expected)
  "Assert that METHOD+PATH resolves to EXPECTED. A NIL EXPECTED asserts that NOTHING matches, which
   is the negative control: a probe that cannot fail proves nothing."
  (let ((got (route-key-of method path)))
    (if (eql got expected)
        (ok "~A ~A → ~A" (string-upcase (string method)) path (or got "no route"))
        (fail "~A ~A → ~A, expected ~A" (string-upcase (string method)) path
              (or got "no route") (or expected "no route")))))

(defun expect-path-param (method path name expected-value)
  "Assert the parameterised segment reached the params alist — the half of a binding that a source
   scan cannot see and a shadowed path would silently lose. find-api-route returns the route and the
   RESOLVED path-param alist as two values."
  (multiple-value-bind (route params)
      (find-api-route method path)
    (declare (ignorable route))
    (let ((got (cdr (assoc name params :test #'string-equal))))
      (if (equal got expected-value)
          (ok "~A ~A carries ~A=~S" (string-upcase (string method)) path name got)
          (fail "~A ~A did not carry ~A=~S (got ~S)" (string-upcase (string method)) path
                name expected-value got)))))

(defparameter *sample-ordnum* "ORD-DEMO-2023-24-XNEBWE"
  "A real number from the live table (one of the 486 minted on 2026-10-03). Any concrete segment would
   do — the probe never touches the database — but a real one keeps the transcript honest.")

(format t "~%== the VENDOR paths (S11)~%")
(expect-route :get "/hhub/api/v1/vendor/orders" 'route-vordh-list)
(expect-route :get (format nil "/hhub/api/v1/vendor/orders/~A" *sample-ordnum*) 'route-vordh-detail)
(expect-route :put (format nil "/hhub/api/v1/vendor/orders/~A" *sample-ordnum*) 'route-vordh-update)

(format t "~%== the CUSTOMER paths must NOT be shadowed by them (S13 c)~%")
(expect-route :get "/hhub/api/v1/orders" 'route-ordh-list)
(expect-route :post "/hhub/api/v1/orders" 'route-ordh-create)
(expect-route :get (format nil "/hhub/api/v1/orders/~A" *sample-ordnum*) 'route-ordh-detail)
(expect-route :put (format nil "/hhub/api/v1/orders/~A" *sample-ordnum*) 'route-ordh-update)
(expect-route :get (format nil "/hhub/api/v1/orders/~A/items/12" *sample-ordnum*) nil)

(format t "~%== the parameterised segment reaches the handler~%")
(expect-path-param :get (format nil "/hhub/api/v1/vendor/orders/~A" *sample-ordnum*)
                   "ordnum" *sample-ordnum*)
(expect-path-param :get (format nil "/hhub/api/v1/orders/~A" *sample-ordnum*)
                   "ordnum" *sample-ordnum*)

(format t "~%== negative control — a path nobody bound must resolve to nothing~%")
(expect-route :get "/hhub/api/v1/vendor/orders/nope/deeper" nil)
(expect-route :delete (format nil "/hhub/api/v1/vendor/orders/~A" *sample-ordnum*) nil)

(format t "~%== nst-vordh-route-probe: ~:[FAIL~;PASS~] — ~D check(s), ~D problem(s) ==~%"
        (zerop *problems*) *checks* *problems*)
(finish-output)
(sb-ext:exit :code (if (zerop *problems*) 0 1))
