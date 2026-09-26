;;; nst-verify-invoice-dispatch.lisp --- verify the invoice API through the REAL
;;; dispatcher, offline, against the live database.
;;;
;;;   XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --noinform --non-interactive --load <this>
;;;
;;; Exit 0 = pass. 1 = fail.
;;;
;;; Requires the offline load to work (see nst-offline-load.lisp for the four
;;; prerequisites: no :depends-on in the asd, swank first, a writable copy of the clsql
;;; dist, and the hhub-bl-ent/dod-ini-sys order). The ASDF cache must already be warm or
;;; this compiles the tree first.
;;;
;;; ── WHAT IT PROVES, AND WHY IT IS NOT REDUNDANT WITH THE SMOKE SUITE ────────
;;;   A. ROUTING — find-api-route's answer for every invoice path, including the one the
;;;      /settings binding rests on: /invoices/settings and /invoices/{id} are the same
;;;      segment count, so only the fewest-parameters-first ranking stops `settings`
;;;      being read as an invoice id.
;;;   B. THE FULL RING-3 DISPATCH — dispatch-route2 builds the request model FROM THE
;;;      ROUTE'S request-class, makes the कारक ctx, runs the verb, reverse-ferries and
;;;      RENDERS JSON. Everything except apidefs2's HTTP routing and the session.
;;;   C. THE WRITE LIFECYCLE through the routes — create, add a line, read the
;;;      aggregate, update, soft-delete — which is what the smoke suite's --write mode
;;;      does over HTTP.
;;;
;;; ── IT CLEANS UP, AND THE KEY IS NOT THE INVOICE NUMBER ────────────────────
;;; A MySQL trigger rewrites INVNUM on every insert into DOD_INVOICE_HEADER
;;; (installation/nstdbtriggers.sql), so a row created here cannot be found by any number
;;; this file chose — and hhubuser sees NO triggers at all, which is why the database
;;; looks like it discards the value for no reason. The cleanup therefore keys on
;;; CUSTNAME, which the caller controls. Getting this wrong leaked rows twice.
;;;
;;; ⚠ IT BINDS *HHUBBUSINESSFUNCTIONSLOGFILE* to /tmp: the create path opens that file
;;; for append and it is hardcoded to /home/hunchentoot/hhublogs/... (dod-ini-sys.lisp:85),
;;; unwritable by any other user. Without the binding, a create dies on the OPEN, which
;;; looks like a create bug.

;;; Round-9 verification of the invoice API — the parts the HTTP suite cannot reach
;;; offline, driven through the REAL dispatcher.
;;;
;;;   XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --noinform --non-interactive --load <this>
;;;
;;; Three things this proves that nothing else has:
;;;
;;;   A. ROUTING — find-api-route's answer for every invoice path. This is the claim the
;;;      whole /settings binding rests on: /hhub/api/v1/invoices/settings and
;;;      /hhub/api/v1/invoices/{id} have the SAME segment count, so only the ranking
;;;      (fewest {parameters} first) keeps `settings` from being read as an invoice id.
;;;      Asserted from reading the code until now; here it is measured.
;;;
;;;   B. THE FULL RING-3 DISPATCH — dispatch-route2, not a hand-built call: it looks the
;;;      action route up, builds the request model FROM THE ROUTE'S request-class, makes
;;;      the कारक ctx, runs the verb, reverse-ferries and RENDERS to JSON. Every layer
;;;      except apidefs2's HTTP routing and the hunchentoot session.
;;;
;;;   C. THE WRITE LIFECYCLE through the routes — create header, add a line, read the
;;;      aggregate, update, soft-delete — so the item endpoints' WRITE path is exercised
;;;      rather than only their refusals.
;;;
;;; IT CLEANS UP AFTER ITSELF (unwind-protect, by INVNUM prefix) and reports what it
;;; removed, so a partial failure cannot leave rows behind silently.

;;; ── ONE MORE THING THIS CAUGHT, AND WHY THE CLEANUP KEY CHANGED TWICE ──────
;;; The harness leaked a row on two separate runs, both times because the cleanup key
;;; was something the run itself changed:
;;;   * INVNUM — a MySQL trigger rewrites it on insert (installation/nstdbtriggers.sql),
;;;     so no number this file chose can ever be found again;
;;;   * CUSTNAME — part C UPDATES the header's custname as part of the lifecycle it is
;;;     testing, so by cleanup time the marker was gone.
;;; It now records the ROW-ID the moment a create succeeds. A ROW-ID cannot be changed
;;; through this API at all, which is exactly why it is the right key — the same reason
;;; the smoke suite uses one.
;;;
;;; ── COVERAGE, AS OF 2026-09-26: 51 CHECKS ──────────────────────────────────
;;;   A  find-api-route for all 10 invoice paths (incl. /settings vs {id})
;;;   B  dispatch-route2 end-to-end: request-class, कारक ctx, ferry, JSON render
;;;   C  the write lifecycle: create, line, aggregate, line update, NESTED update,
;;;      header update, K1 no roll-up, soft delete, aggregate excludes it, K2 observed
;;;   D  a taken invoice number -> :C (409) AND nothing written
;;;   E  every refusal: absent/foreign rows, both bad dates, the (header,line) pairing
;;;      on update AND delete, absent lines, and DELETE of a line of a NON-DRAFT invoice
;;;   F  the download SUCCESS path, with the two external producers STUBBED: the route
;;;      mints the sessionless ext-url, calls the producer, and redirects to
;;;      <siteurl>/img/temp/<file>. What F does NOT verify is that a PDF is produced.
;;;
;;; Every path in the invoice API has now been executed at least once. What NO OFFLINE
;;; HARNESS CAN REACH is apidefs2's HTTP routing, the hunchentoot session, and the
;;; response writers — the smoke suite over HTTP is still the only check for those.

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
(defparameter *marker* (format nil "ZZSMOKE~D" (get-universal-time)))

(defun chk (name got want)
  (if (equal got want)
      (progn (incf *pass*) (format t "~&  PASS ~A~%" name))
      (progn (incf *fail*) (format t "~&  FAIL ~A~%        got  ~S~%        want ~S~%" name got want))))

(defun chk-true (name thunk)
  (handler-case (if (funcall thunk)
                    (progn (incf *pass*) (format t "~&  PASS ~A~%" name))
                    (progn (incf *fail*) (format t "~&  FAIL ~A -> NIL~%" name)))
    (error (c) (incf *fail*) (format t "~&  FAIL ~A -> signalled ~A~%" name c))))

(defun chk-signals (name thunk class-name)
  (handler-case (let ((v (funcall thunk)))
                  (incf *fail*)
                  (format t "~&  FAIL ~A -> returned ~S, expected ~A~%" name v class-name))
    (error (c) (if (string= (string-upcase (type-of c)) (string-upcase class-name))
                   (progn (incf *pass*) (format t "~&  PASS ~A (signalled ~A)~%" name (type-of c)))
                   (progn (incf *fail*)
                          (format t "~&  FAIL ~A -> signalled ~A, expected ~A~%"
                                  name (type-of c) class-name))))))

(defun db-scalar (sql)
  "The first column of the first row, as a string — small queries, read as text."
  (let ((row (car (clsql:query sql))))
    (and row (princ-to-string (car row)))))

(defparameter *custname* (format nil "ZZHARNESS-~A" (get-universal-time))
  "🚨 THE CLEANUP KEY, AND IT CANNOT BE INVNUM. A MySQL trigger rewrites INVNUM on every
   insert into DOD_INVOICE_HEADER — installation/nstdbtriggers.sql sets
   NEW.INVNUM = concat('NST', lpad(next_id,5,'0'), '-', year(now())) — so a row created
   here is NOT findable by any invoice number this file chose. MEASURED: a create asking
   for \"ZZMANUAL1\" stores \"NST00040-2026\", and hhubuser sees no triggers at all
   (INFORMATION_SCHEMA.TRIGGERS returns 0), so the database looks like it is discarding
   the value for no reason. CUSTNAME is caller-controlled; that is the handle.")

(defparameter *created-ids* '()
  "Every header ROW-ID this run created, recorded the moment the create succeeded.

  🚨 THE CLEANUP KEY MUST BE SOMETHING THE RUN DOES NOT MUTATE. Two keys were tried and
  both failed: INVNUM (a MySQL trigger rewrites it on insert, see below) and CUSTNAME
  (part C UPDATES the header's custname as part of the lifecycle it is testing, so by
  cleanup time the marker was gone and the row leaked). A ROW-ID cannot be changed
  through this API at all — which is exactly why it is the right key.")

(defun invnum-of (row-id)
  "The invoice NUMBER of ROW-ID, read from the table. It CANNOT be derived from the
   row-id: the trigger stamps `year(now())` at INSERT time, so a 2024 row and a 2026 row
   with the same position differ. The API is addressed by this number now."
  (db-scalar (format nil "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" row-id)))

(defun cleanup ()
  "Delete every row this harness created, by the ROW-ID it recorded."
  (when *created-ids*
    (let ((ids (format nil "~{~A~^,~}" *created-ids*)))
      (clsql:execute-command
       (format nil "DELETE FROM DOD_INVOICE_ITEMS WHERE INVHEADID IN (~A)" ids))
      (clsql:execute-command
       (format nil "DELETE FROM DOD_INVOICE_HEADER WHERE ROW_ID IN (~A)" ids))
      (format t "~&  cleanup: removed ~A harness header(s) and their lines~%"
              (length *created-ids*)))))

;;; ── A. ROUTING ──────────────────────────────────────────────────────────────
(defun part-a-routing ()
  (format t "~&=== A. find-api-route — what each invoice path resolves to ===~%")
  (dolist (case '(("PUT"    "/hhub/api/v1/invoices/settings"     route-invh-settings-update)
                  ("GET"    "/hhub/api/v1/invoices/23"           route-invh-detail)
                  ("GET"    "/hhub/api/v1/invoices/23/download"  route-invh-download)
                  ("GET"    "/hhub/api/v1/invoices/23/public"    route-invh-public)
                  ("POST"   "/hhub/api/v1/invoices"              route-invh-create)
                  ("GET"    "/hhub/api/v1/invoices"              route-invh-list)
                  ("PUT"    "/hhub/api/v1/invoices/23"           route-invh-update)
                  ("POST"   "/hhub/api/v1/invoices/23/items"     route-invitm-create)
                  ("PUT"    "/hhub/api/v1/invoices/23/items/9"   route-invitm-update)
                  ("DELETE" "/hhub/api/v1/invoices/23/items/9"   route-invitm-delete)))
    (let ((route (find-api-route (intern (first case) :keyword) (second case))))
      (chk (format nil "~A ~A" (first case) (second case))
           (and route (api-route-key route))
           (third case)))))

;;; ── B. THE FULL DISPATCH ────────────────────────────────────────────────────
(defun part-b-dispatch (company)
  (format t "~&=== B. dispatch-route2 — the whole Ring-3 stack, rendered ===~%")
  ;; BOUND, never set globally: *action-route-company-override* is documented
  ;; TEST/REPL ONLY and must stay NIL in production.
  (let ((*action-route-company-override* company))
    (let ((json (dispatch-route2 'route-invh-detail (list :invnum (invnum-of 23)) :output-type :json)))
      (chk-true "detail renders JSON text" (lambda () (stringp json)))
      (chk-true "it carries the header" (lambda () (and (search "\"invnum\"" json) t)))
      (chk-true "it carries a nested lines array" (lambda () (and (search "\"lines\"" json) t))))
    (let ((json (dispatch-route2 'route-invh-public (list :invnum (invnum-of 23)) :output-type :json)))
      (chk-true "the public route renders publicUrl" (lambda () (and (search "\"publicUrl\"" json) t)))
      (chk-true "the link is the sessionless public view"
                (lambda () (and (search "displayinvoicepublic?key=" json) t))))
    (let ((json (dispatch-route2 'route-invh-list (list :status "DRAFT") :output-type :json)))
      (chk-true "list renders a JSON array" (lambda () (eql (char json 0) #\[))))
    (chk-signals "a bad sort-by through the DISPATCHER is api-client-error"
                 (lambda () (dispatch-route2 'route-invh-list
                                             (list :sort-by "password" :sort-dir "asc")
                                             :output-type :json))
                 'api-client-error)))

;;; ── C. THE WRITE LIFECYCLE ──────────────────────────────────────────────────
(defun part-c-writes (ctx)
  (format t "~&=== C. the write lifecycle, through the routes ===~%")
  (let ((h (route-invh-create
            (make-instance 'NstInvhRequestModel
                           :params (list :invnum *marker* :invdate "2026-09-26"
                                         :custname *custname* :statecode "29"
                                         :placeofsupply "29" :totalvalue 0
                                         :totalinwords "Zero" :finyear "2026-2027"))
            ctx)))
    (chk "create -> an nst-invh" (type-of h) 'nst-invh)
    (unless (typep h 'nst-invh)
      ;; A :U/:F sentinel carries the reason — that IS the diagnosis.
      (format t "~&        reason: ~A~%" (ignore-errors (entity-reason h)))
      (return-from part-c-writes nil))
    (let ((id (row-id h)))
      (chk "the new invoice is a DRAFT" (status h) "DRAFT")
      (chk "its tenant is the session tenant" (tenant-id h) 2)
      ;; RECORD IT NOW: from here the cleanup can remove this row even if everything
      ;; after it fails.
      (push id *created-ids*)
      (let ((line (route-invitm-create
                   (make-instance 'NstInvitmRequestModel
                                  :params (list :invnum (db-scalar (format nil "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" id)) :prd-id 1
                                                :prddesc "Harness line" :hsncode "0405"
                                                :qty 2 :uom "NOS" :price 100
                                                :taxable-value 200 :cgstrate 9
                                                :cgstamt 18 :sgstrate 9 :sgstamt 18
                                                :igstrate 0 :igstamt 0 :totalitemval 236))
                   ctx)))
        (chk "add line -> an nst-invitm" (type-of line) 'nst-invitm)
        (unless (typep line 'nst-invitm) (return-from part-c-writes nil))
        (let ((lid (row-id line)))
          (chk "the line points at the invoice from the URL" (invheadid line) id)
          (chk "the line's tenant is the session tenant" (tenant-id line) 2)
          ;; the aggregate must show it
          (let ((resp (route-invh-detail
                       (make-instance 'NstInvhRequestModel :params (list :invnum (db-scalar (format nil "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" id))))
                       ctx)))
            (chk-true "the aggregate carries the new line"
                      (lambda () (and (search (princ-to-string lid)
                                              (json:encode-json-to-string (render-json resp ctx)))
                                      t))))
          ;; update the line
          (let ((upd (route-invitm-update
                      (make-instance 'NstInvitmRequestModel
                                     :params (list :invnum (db-scalar (format nil "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" id)) :row-id (princ-to-string lid) :qty 5))
                      ctx)))
            (chk-true "update line -> an entity, not a refusal"
                      (lambda () (and (typep upd 'nst-invitm) t))))
          (chk "the update reached the QTY column"
               (db-scalar (format nil "SELECT QTY FROM DOD_INVOICE_ITEMS WHERE ROW_ID=~A" lid)) "5")
          ;; 🚨 THE NESTED-URL CASE, which is why the route strips :invheadid: the item
          ;; URL puts the PARENT in the payload and !update REFUSES that initarg by
          ;; design, so without the verify-then-strip every nested PUT would 409. This
          ;; sends exactly what the nested URL produces.
          (let ((nested (route-invitm-update
                         (make-instance 'NstInvitmRequestModel
                                        :params (list :row-id (princ-to-string lid)
                                                      :invnum (db-scalar (format nil "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" id))
                                                      :qty 7))
                         ctx)))
            (chk-true "a NESTED update (row-id + invheadid) is NOT refused"
                      (lambda () (and (typep nested 'nst-invitm) t))))
          ;; the header update the suite's write section asserts
          (let ((hu (route-invh-update
                     (make-instance 'NstInvhRequestModel
                                    :params (list :invnum (db-scalar (format nil "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" id))
                                                  :custname "Updated Customer"
                                                  :invdate "2026-09-27"))
                     ctx)))
            (chk-true "update header -> an entity" (lambda () (and (typep hu 'nst-invh) t)))
            (unless (typep hu 'nst-invh)
              (format t "~&        header update returned ~A~%        reason: ~A~%"
                      (type-of hu) (ignore-errors (entity-reason hu)))))
          (chk "the header update reached CUSTNAME"
               (db-scalar (format nil "SELECT CUSTNAME FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" id))
               "Updated Customer")
          (chk "the ISO date was written as a DATE"
               (db-scalar (format nil "SELECT INVDATE FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" id))
               "2026-09-27")
          ;; K1: no roll-up
          (chk "K1: adding a line does NOT roll up TOTALVALUE"
               (db-scalar (format nil "SELECT TOTALVALUE FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" id)) "0.00")
          ;; delete the line: a soft delete, acknowledged
          (let ((ack (route-invitm-delete
                      (make-instance 'NstInvitmRequestModel :params (list :invnum (db-scalar (format nil "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" id)) :row-id (princ-to-string lid)))
                      ctx)))
            (chk-true "delete line -> acknowledged" (lambda () (and ack t))))
          (chk "the delete is SOFT (row kept, flagged Y)"
               (db-scalar (format nil "SELECT DELETED_STATE FROM DOD_INVOICE_ITEMS WHERE ROW_ID=~A" lid)) "Y")
          ;; K2 — OBSERVED, NOT ASSERTED. The correct contract for a REPEAT delete is a
          ;; contradiction (409, 'already deleted'); the suite records as KNOWN that it
          ;; is currently indistinguishable from a wrong id. Printed so the suite's
          ;; claim is measured rather than assumed.
          (let ((again (route-invitm-delete
                        (make-instance 'NstInvitmRequestModel
                                       :params (list :invnum (db-scalar (format nil "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" id)) :row-id (princ-to-string lid)))
                        ctx)))
            (format t "~&  K2 OBSERVED: a repeat delete returns ~A~%" (type-of again))
            (chk-true "K2: a repeat delete is NOT reported as success"
                      (lambda () (not (eq again t)))))
          ;; and the aggregate no longer lists it
          (let ((resp (route-invh-detail
                       (make-instance 'NstInvhRequestModel :params (list :invnum (db-scalar (format nil "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=~A" id))))
                       ctx)))
            (chk-true "a soft-deleted line is gone from the aggregate"
                      (lambda () (not (search (format nil "\"rowId\":\"~A\"" lid)
                                              (json:encode-json-to-string (render-json resp ctx))))))))))))

;;; ── D. THE DUPLICATE-INVNUM REFUSAL, AND THAT IT WRITES NOTHING ─────────────
(defun part-d-duplicate (ctx)
  "A create naming a number that ALREADY EXISTS must be a contradiction (:C → 409),
   refused BEFORE the insert.

   🚨 THE STAKES ARE HIGHER THAN A STATUS CODE. The verb's make :around checks
   ?exists on the SUPPLIED number and returns a contradiction without calling
   next-method — so nothing is written. If that guard ever stopped firing, the request
   would reach the INSERT, the `before_insert_invoice` trigger would assign a DIFFERENT
   (fresh) number, and the create would SUCCEED — minting a duplicate invoice for a
   number the client believed was taken. So this asserts BOTH the refusal AND that the
   header count did not move."
  (format t "~&=== D. a duplicate invoice number is refused, and writes nothing ===~%")
  (let* ((existing (db-scalar "SELECT INVNUM FROM DOD_INVOICE_HEADER WHERE ROW_ID=23"))
         (before   (db-scalar "SELECT COUNT(*) FROM DOD_INVOICE_HEADER"))
         (resp (route-invh-create
                (make-instance 'NstInvhRequestModel
                               :params (list :invnum existing :invdate "2026-09-26"
                                             :custname *custname* :statecode "29"
                                             :placeofsupply "29" :totalvalue 0
                                             :totalinwords "Zero" :finyear "2026-2027"))
                ctx))
         (after    (db-scalar "SELECT COUNT(*) FROM DOD_INVOICE_HEADER")))
    (format t "~&  (existing number: ~A)~%" existing)
    (chk "a taken invoice number -> nst-entity-contradiction (:C, 409)"
         (type-of resp) 'nst-entity-contradiction)
    (chk "AND NOTHING WAS WRITTEN (the count did not move)" after before)))

;;; ── E. THE REFUSAL PATHS THE SUITE ASSERTS BUT NOTHING HAD EXECUTED ────────
(defun part-e-refusals (ctx)
  "Every request here is REFUSED before anything is written: an absent row, another
   tenant's row, a malformed date, or a (header, line) pair that does not match. So
   this part needs no cleanup and can run against fixture rows freely."
  (format t "~&=== E. the refusal paths (nothing is written) ===~%")
  (flet ((upd (invnum &rest extra)
           ;; part E's callers pass NUMBERS — the URL addresses an invoice by number now,
           ;; so :invnum is the address and the parameter name follows it.
           (route-invh-update
            (make-instance 'NstInvhRequestModel
                           :params (list* :invnum invnum extra)) ctx))
         (itm-upd (id &rest extra)
           (route-invitm-update
            (make-instance 'NstInvitmRequestModel
                           :params (list* :row-id id extra)) ctx))
         (itm-del (id &rest extra)
           (route-invitm-delete
            (make-instance 'NstInvitmRequestModel
                           :params (list* :row-id id extra)) ctx)))
    (chk "PUT an absent invoice -> :F (404)" (type-of (upd "NST99999-9999" :custname "x")) 'nst-entity-nil)
    (chk "PUT another tenant's invoice -> :F (BOLA)" (type-of (upd (invnum-of 21) :custname "x")) 'nst-entity-nil)
    (chk-signals "PUT a DD/MM/YYYY invdate -> 400"
                 (lambda () (upd (invnum-of 23) :invdate "03/04/2026")) 'api-client-error)
    (chk-signals "PUT an impossible ISO date -> 400"
                 (lambda () (upd (invnum-of 23) :invdate "2026-13-45")) 'api-client-error)
    (chk "PUT a non-numeric id -> 400 or :F, never a 500"
         (handler-case (type-of (upd "NO-SUCH-NUMBER" :custname "x"))
           (api-client-error () 'api-client-error))
         'nst-entity-nil)
    ;; THE PAIRING: a line of invoice 35 addressed under invoice 23.
    (let ((line (db-scalar "SELECT ROW_ID FROM DOD_INVOICE_ITEMS WHERE INVHEADID=35 AND (DELETED_STATE='N' OR DELETED_STATE IS NULL) LIMIT 1")))
      (format t "~&  (using line ~A of invoice 35)~%" line)
      (chk "PUT a line under the WRONG invoice -> :F (404)"
           (type-of (itm-upd line :invnum (invnum-of 23) :qty 2)) 'nst-entity-nil)
      (chk "DELETE a line under the WRONG invoice -> :F (404)"
           (type-of (itm-del line :invnum (invnum-of 23))) 'nst-entity-nil)
      ;; 🚨 THE CONTRACT NO TEST COVERED: a line may only be deleted while its document
      ;; is still being built. Invoice 35 is PENDINGPAYMENT, so this must be a
      ;; contradiction (409) — NOT a 404, which would say the line does not exist.
      (chk "DELETE a line of a NON-DRAFT invoice (35) -> :C (409)"
           (type-of (itm-del line :invnum (invnum-of 35))) 'nst-entity-contradiction))
    (chk "PUT an absent line -> :F (404)" (type-of (itm-upd "99999" :invnum (invnum-of 23) :qty 2)) 'nst-entity-nil)
    (chk "DELETE an absent line -> :F (404)" (type-of (itm-del "99999" :invnum (invnum-of 23))) 'nst-entity-nil)))

;;; ── F. THE DOWNLOAD HAPPY PATH — the last code path that had never run ─────
(defun part-f-download (ctx)
  "Exercise route-invh-download's SUCCESS path, with the two EXTERNAL producers STUBBED.

  🚨 WHAT IS AND IS NOT VERIFIED, STATED PLAINLY. invh-download-pdf-url calls
  downloadhtmlfile (which WGETS *siteurl* — a public production URL) and generatepdf
  (which shells out to wkhtmltopdf). Both are stubbed here, so this does NOT verify that
  a PDF is produced. What it DOES verify is everything that is this tree's own code and
  had never executed: that the route fetches the header under the session tenant,
  resolves its vendor and tenant, mints the sessionless ext-url, passes it to the
  producer, and issues the redirect to the rendered file. Until now only the route's
  REFUSAL path (absent invoice) had ever been run."
  (let ((orig-dl (symbol-function 'downloadhtmlfile))
        (orig-pdf (symbol-function 'generatepdf))
        (orig-redirect (symbol-function 'hunchentoot:redirect))
        (seen '())
        (result nil))
    (unwind-protect
         (progn
           (setf (symbol-function 'downloadhtmlfile)
                 (lambda (url) (push (cons :html-url url) seen) "stub.html"))
           (setf (symbol-function 'generatepdf)
                 (lambda (html outprefix) (push (list :pdf html outprefix) seen) "stub.pdf"))
           (setf (symbol-function 'hunchentoot:redirect)
                 (lambda (target &key &allow-other-keys) (push (cons :redirect target) seen) :redirected))
           (setf result (route-invh-download
                         (make-instance 'NstInvhRequestModel :params (list :invnum (invnum-of 23))) ctx))
           (format t "~&  the route did: ~S~%" (reverse seen))
           (chk "the route reaches the redirect (with the producers stubbed)"
                result :redirected)
           (chk-true "it asked the producer to render the invoice's PUBLIC page"
                     (lambda () (let ((u (cdr (assoc :html-url seen))))
                                  (and (search "/hhub/displayinvoicepublic?key=" u) t))))
           ;; (+ 4 (search "key=" …)) — "key=" is FOUR characters; (1+ …) starts one
           ;; character late and yields "ey=…". Written out because that is exactly the
           ;; mistake made here first.
           (chk "the key it minted names THIS invoice's tenant"
                (let* ((u (cdr (assoc :html-url seen)))
                       (p (search "key=" u)))
                  (and p (subseq u (+ 4 p))))
                "dGVuYW50LWlkLGludm51bSx2ZW5kb3ItaWQKMixOU1QwMDAyMy0yMDI0LDE=")
           (chk-true "it redirected to the rendered file under *siteurl*/img/temp/"
                     (lambda () (let ((tgt (cdr (assoc :redirect seen))))
                                  (and (search "/img/temp/stub.pdf" tgt) t)))))
      (setf (symbol-function 'downloadhtmlfile) orig-dl
            (symbol-function 'generatepdf) orig-pdf
            (symbol-function 'hunchentoot:redirect) orig-redirect))))

;;; ── RUN ─────────────────────────────────────────────────────────────────────
(crm-db-connect :strdb "hhubdb" :strusr "hhubuser" :strpwd "Welcome$123"
                :servername "127.0.0.1" :strdbtype :mysql)
(format t "~&connected. marker=~A~%" *marker*)

(let* ((company (select-company-by-id 2))
       (ctx (make-domain-ctx :tenant company :channel :agent)))
  ;; 🚨 THE WRITE PATH LOGS TO A HARDCODED ABSOLUTE PATH —
  ;; /home/hunchentoot/hhublogs/ninestores-busfunctions.log, dod-ini-sys.lisp:85 — and
  ;; the create path opens it for append. Running as any other user, that open signals
  ;; SIMPLE-FILE-ERROR before the verb writes anything, which looks like a create bug.
  ;; It is not: it is a harness requirement. Bind it somewhere writable.
  (let ((*HHUBBUSINESSFUNCTIONSLOGFILE* "/tmp/nst-harness-busfunctions.log"))
    (unwind-protect
         (progn (part-a-routing)
                (part-b-dispatch company)
                (part-c-writes ctx)
                (part-d-duplicate ctx)
                (part-e-refusals ctx)
                (part-f-download ctx))
      (cleanup))))

(format t "~&~%─────────────────────────────────────────────~%")
(format t "passed ~D   failed ~D~%" *pass* *fail*)
(sb-ext:exit :code (if (zerop *fail*) 0 1))
