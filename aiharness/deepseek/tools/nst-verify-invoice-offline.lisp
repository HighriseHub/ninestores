;;; nst-verify-invoice-offline.lisp --- verify the invoice API's DOMAIN and BOUNDARY
;;; layers against the real database, with no HTTP and no reload.
;;;
;;;   cd /home/ubuntu/ninestores
;;;   # ONE-TIME setup (see below), then:
;;;   XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --noinform --non-interactive --load <this file>
;;;
;;; Exit 0 = pass. 1 = fail. 2 = setup problem.
;;;
;;; ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
;;; The invoice API had never been exercised behind a session, and the only way the
;;; tree's documentation allowed was a restart of the live image — which an agent
;;; cannot do here (sudo is refused: "no new privileges"). This harness reaches the
;;; real domain layer WITHOUT one: every प्रत्यय, the ferries, domain->response and
;;; render-json, connected to the real MySQL, driven through the actual route
;;; functions. It is how the 500 fix was proven end-to-end and how the settings
;;; route's fail-closed branch was reached — a branch the smoke suite states it
;;; cannot cover.
;;;
;;; ── THE FOUR THINGS THAT BLOCK THIS, ALL MEASURED 2026-09-26 ────────────────
;;;
;;; 1. hhub/nstores.asd HAS NO :depends-on. startup/load.lisp quickloads the 16
;;;    dependencies first; without that step the build dies inside core/dod-dal-bo.lisp
;;;    with "Package CLSQL does not exist", which reads like a broken source file.
;;;
;;; 2. init.lisp quickloads SWANK before anything else, and the tree READS the swank
;;;    package while compiling (core/nst-bl-ollama.lisp:914 is the first). Skipping it
;;;    gives "READ error during COMPILE-FILE: Package SWANK does not exist" — the
;;;    documented trap: a missing package is indistinguishable from a syntax mistake.
;;;
;;; 3. clsql-mysql declares its C component with output-files IN THE SOURCE DIRECTORY,
;;;    and .../quicklisp/.../clsql-20221106-git/db-mysql is drwxr-xr-x hunchentoot —
;;;    unwritable by this user. It fails as an opaque "OPERATION-ERROR while invoking
;;;    #<COMPILE-OP> on … clsql_mysql" that never mentions permissions. FIX: copy that
;;;    one dist directory somewhere writable and push it onto asdf:*central-registry*
;;;    ahead of quicklisp's, so ASDF finds the prebuilt clsql_mysql64.so fresh:
;;;
;;;      mkdir -p /tmp/nst-asdf/clsql-dist
;;;      cp -rp /home/ubuntu/quicklisp/dists/quicklisp/software/clsql-20221106-git \
;;;             /tmp/nst-asdf/clsql-dist/
;;;      chmod -R u+w /tmp/nst-asdf/clsql-dist
;;;
;;; 4. 🚨 THE BUILD ORDER ITSELF (fixed 2026-09-26, see hhub/nstores.asd line ~63).
;;;    dod-ini-sys installs (defmethod initBusinessContexts ((server BusinessServer) …))
;;;    at LOAD time, and BusinessServer is defined in hhub-bl-ent. Commit d6275d0 moved
;;;    dod-ini-sys ABOVE hhub-bl-ent, so a cold load aborted with
;;;       There is no class named COM.NSTORES.APP::BUSINESSSERVER
;;;    leaving startup/load.lisp's (start-das) unreached — the app would come up with
;;;    NO ACCEPTOR. The fix moves hhub-bl-ent above dod-ini-sys in BOTH hand-maintained
;;;    lists. THIS TOOL IS THE REGRESSION TEST FOR IT: before the fix it aborted here.
;;;
;;; ── AND READ THIS BEFORE CHANGING THE TOOL ─────────────────────────────────
;;; `cp -r` of the live image's ASDF cache does NOT work: copying gives every fasl a
;;; fresh mtime, ASDF then treats them all as up to date and loads STALE FASLS, and the
;;; failure looks like a source bug. Compile from source into a fresh XDG_CACHE_HOME.
;;; Also: a DIAGNOSTIC that reads symbols after (in-package …) inside a handler-case
;;; will report everything as NIL, because the reader read those forms in the ORIGINAL
;;; package — use fully-qualified names, or put (in-package …) at top level.

;;; Verify the invoice API's DOMAIN and BOUNDARY layers against the real database,
;;; with no web server, no HTTP and no live image.
;;;
;;; This is the check the smoke suite cannot make until the image is reloaded, and it
;;; exercises the EXACT call that used to answer 500 — domain->response over a fetched
;;; nst-invh — plus every refusal the suite asserts.
;;;
;;; IT WRITES NOTHING. Every mutating route below is aimed at input the domain REFUSES
;;; before it writes (an absent row, a non-DRAFT header, a bad sort key, no session).

(load "~/quicklisp/setup.lisp")
(push "/home/ubuntu/ninestores/hhub/" asdf:*central-registry*)
(push #p"/tmp/nst-asdf/clsql-dist/clsql-20221106-git/" asdf:*central-registry*)
(ql:quickload :swank :silent t)
(dolist (s '(:uuid :secure-random :drakma :cl-json :cl-who :hunchentoot :clsql
             :clsql-mysql :cl-smtp :parenscript :cl-async :cl-csv :cl-base64
             :priority-queue :blackbird :cl-yaml))
  (ql:quickload s :silent t))
(ql:quickload :nstores :silent t)
(in-package :nstores)

(defparameter *pass* 0)
(defparameter *fail* 0)

(defun chk (name got want)
  (if (equal got want)
      (progn (incf *pass*) (format t "~&  PASS ~A~%" name))
      (progn (incf *fail*)
             (format t "~&  FAIL ~A~%        got  ~S~%        want ~S~%" name got want))))

(defun chk-true (name thunk)
  "THUNK, not a quoted form: eval() has no lexical environment, so a form naming a
   LET-bound variable reports UNBOUND-VARIABLE and the check silently never runs."
  (handler-case (if (funcall thunk)
                    (progn (incf *pass*) (format t "~&  PASS ~A~%" name))
                    (progn (incf *fail*) (format t "~&  FAIL ~A -> NIL~%" name)))
    (error (c) (incf *fail*) (format t "~&  FAIL ~A -> signalled ~A~%" name c))))

;; Signals CONDITION-CLASS-NAME (checked by name, so this needs no import).
(defun chk-signals (name thunk class-name)
  (handler-case (let ((v (funcall thunk)))
                  (incf *fail*)
                  (format t "~&  FAIL ~A -> returned ~S, expected it to signal ~A~%"
                          name v class-name))
    (error (c)
      (if (string= (string-upcase (type-of c)) (string-upcase class-name))
          (progn (incf *pass*) (format t "~&  PASS ~A (signalled ~A)~%" name (type-of c)))
          (progn (incf *fail*)
                 (format t "~&  FAIL ~A -> signalled ~A, expected ~A~%"
                         name (type-of c) class-name))))))

(crm-db-connect :strdb "hhubdb" :strusr "hhubuser" :strpwd "Welcome$123"
                :servername "127.0.0.1" :strdbtype :mysql)
(format t "~&connected.~%")

(let* ((company (select-company-by-id 2))
       (ctx (make-domain-ctx :tenant company :channel :agent)))
  (format t "~&=== 0. the layer is real ===~%")
  (chk "company 2 resolves" (and company t) t)
  (chk "nst-invh class exists" (and (find-class 'nst-invh nil) t) t)
  (chk "NstInvhResponseModel exists" (and (find-class 'NstInvhResponseModel nil) t) t)
  (chk "invh-public-url-response exists" (and (find-class 'invh-public-url-response nil) t) t)
  (chk "invh-detail-response exists" (and (find-class 'invh-detail-response nil) t) t)

  (format t "~&=== 1. THE 500 FIX — fetch, then domain->response (the call that failed) ===~%")
  (let ((h (fetch 'nst-invh "23" ctx)))
    (chk "fetch 23 -> an nst-invh" (type-of h) 'nst-invh)
    (when (typep h 'nst-invh)
      (chk-true "its invnum is the one the column holds" (lambda () (and (invnum h) t)))
      (chk "its status" (status h) "DRAFT")
      (let ((r (domain->response h ctx)))          ; ← used to signal MISSING-SLOT
        (chk "domain->response -> a response model" (type-of r) 'NstInvhResponseModel)
        (let ((alist (render-json r ctx)))
          (chk-true "render-json returns an alist" (lambda () (consp alist)))
          (chk "rowId is present" (assoc "rowId" alist :test #'equal) '("rowId" . "23"))
          (chk-true "deletedState is NOT published"
                    (lambda () (null (assoc "deletedState" alist :test #'equal))))
          (let ((json (json:encode-json-to-string alist)))
            (chk-true "it encodes to JSON" (lambda () (and (search "{\"rowId\"" json) t))))))))

  (format t "~&=== 2. the aggregate read — the ROUTE, not a hand-built call ===~%")
  (let* ((req (make-instance 'NstInvhRequestModel :params (list :row-id "23")))
         (resp (route-invh-detail req ctx)))
    (chk "route-invh-detail -> invh-detail-response" (type-of resp) 'invh-detail-response)
    (when (typep resp 'invh-detail-response)
      (let* ((alist (render-json resp ctx))
             (lines (cdr (assoc "lines" alist :test #'equal))))
        (chk-true "the body carries header fields" (lambda () (assoc "invnum" alist :test #'equal)))
        (chk "invoice 23 has its 4 lines" (length lines) 4)
        (chk-true "each line rendered" (lambda () (every #'consp lines)))))
    (let* ((req2 (make-instance 'NstInvhRequestModel :params (list :row-id "99999")))
           (resp2 (route-invh-detail req2 ctx)))
      (chk "detail of an absent invoice -> nst-entity-nil (:F)" (type-of resp2) 'nst-entity-nil))
    (let* ((req3 (make-instance 'NstInvhRequestModel :params (list :row-id "21")))
           (resp3 (route-invh-detail req3 ctx)))
      (chk "detail of ANOTHER TENANT's invoice -> nst-entity-nil (BOLA)" (type-of resp3) 'nst-entity-nil)))

  (format t "~&=== 3. the list, and the sort guard ===~%")
  (let* ((req (make-instance 'NstInvhRequestModel :params (list :status "DRAFT")))
         (rows (route-invh-list req ctx)))
    (chk-true "list :status DRAFT -> a list" (lambda () (listp rows)))
    (chk "the 4 DRAFT invoices" (length rows) 4))
  (let* ((req (make-instance 'NstInvhRequestModel :params (list :status "NO_SUCH_STATUS")))
         (rows (route-invh-list req ctx)))
    (chk "an unknown status is a filter, not an error → ()" rows '()))
  (chk-signals "?sort-by=password is refused by the ROUTE guard"
               (lambda ()
                 (route-invh-list (make-instance 'NstInvhRequestModel
                                                 :params (list :sort-by "password" :sort-dir "asc"))
                                  ctx))
               'api-client-error)
  (chk-signals "?sort-dir=sideways is refused"
               (lambda ()
                 (route-invh-list (make-instance 'NstInvhRequestModel
                                                 :params (list :sort-by "invdate" :sort-dir "sideways"))
                                  ctx))
               'api-client-error)

  (format t "~&=== 4. the public view link ===~%")
  (let* ((req (make-instance 'NstInvhRequestModel :params (list :row-id "23")))
         (resp (route-invh-public req ctx)))
    (chk "route-invh-public -> invh-public-url-response" (type-of resp) 'invh-public-url-response)
    (when (typep resp 'invh-public-url-response)
      (let* ((alist (render-json resp ctx))
             (url (cdr (assoc "publicUrl" alist :test #'equal))))
        (chk-true "the link is the PUBLIC view route"
                  (lambda () (and (search "/hhub/displayinvoicepublic?key=" url) t)))
        (chk-true "the link is absolute" (lambda () (and (search "http" url) t)))
        (format t "~&        ~A~%" url)))
    (let* ((req2 (make-instance 'NstInvhRequestModel :params (list :row-id "21")))
           (resp2 (route-invh-public req2 ctx)))
      (chk "public view of another tenant's invoice -> :F" (type-of resp2) 'nst-entity-nil)))

  (format t "~&=== 5. download: the guard runs BEFORE any rendering ===~%")
  (let* ((req (make-instance 'NstInvhRequestModel :params (list :row-id "99999")))
         (resp (route-invh-download req ctx)))
    (chk "download of an absent invoice -> :F, and wkhtmltopdf never runs"
         (type-of resp) 'nst-entity-nil))

  (format t "~&=== 6. settings: the FAIL-CLOSED path the suite cannot reach ===~%")
  (chk-signals "no session vendor → api-not-authenticated (401), nothing written"
               (lambda ()
                 (route-invh-settings-update
                  (make-instance 'VendorRequestModel :params (list :invoice-print-settings nil))
                  ctx))
               'api-not-authenticated)

  (format t "~&=== 7. a line on a NON-DRAFT invoice → contradiction (409) ===~%")
  (let* ((req (make-instance 'NstInvitmRequestModel
                             :params (list :invheadid "35" :prd-id 1 :prddesc "x"
                                           :hsncode "0405" :uom "NOS")))
         (resp (route-invitm-create req ctx)))
    (chk "line create on invoice 35 (PENDINGPAYMENT) -> nst-entity-contradiction"
         (type-of resp) 'nst-entity-contradiction))
  (let* ((req (make-instance 'NstInvitmRequestModel
                             :params (list :invheadid "99999" :prd-id 1 :prddesc "x"
                                           :hsncode "0405" :uom "NOS")))
         (resp (route-invitm-create req ctx)))
    (chk "line create on an absent invoice -> nst-entity-nil" (type-of resp) 'nst-entity-nil))

  (format t "~&~%─────────────────────────────────────────────~%")
  (format t "passed ~D   failed ~D~%" *pass* *fail*)
  (sb-ext:exit :code (if (zerop *fail*) 0 1)))
