;;; nst-server-context.lisp
;;;
;;; Revertible-effect lifecycle core for ninestores.
;;;
;;; Lineage:
;;;   1. cordis-plugin.txt          — flat FIFO alist of (start . end) pairs; reverse
;;;                                   teardown, but no nesting and no failure safety.
;;;   2. nst-temporal-spatial-framework.lisp — dependency matrix; derived ordering, but
;;;                                   teardown was a second hand-written matrix and the
;;;                                   wave scheduler raced.
;;;   3. this file                  — one registration site per subsystem (startup + its
;;;                                   inverse, adjacent), LIFO teardown derived by
;;;                                   construction, and unwind-protect so a mid-boot
;;;                                   failure still reverts.
;;;
;;; The invariant: every effect registered during a scope is undone when that scope exits,
;;; in exact reverse registration order. Nothing is hand-written twice.
;;;
;;; -*- mode: common-lisp; coding: utf-8 -*-

(in-package :nstores)

;;; ─── The revert stack ─────────────────────────────────────────────
;;;
;;; NOTE: the stack is a plain global and is NOT thread-safe. Registration and unwinding
;;; must happen on one thread — by design: teardown ordering is a global property, so
;;; interleaving two threads' registrations has no defined reverse. Long-lived server
;;; startup is single-threaded (see START-NST-SERVER below).

(defvar *revert-stack* nil
  "Holds a stack of zero-argument disposal closures, most recent first.
Rebound to NIL by WITH-REVERTIBLE-CONTEXT, or left global by START-NST-SERVER.")

(defun revert-stack-depth ()
  "Number of effects currently registered and not yet reverted."
  (length *revert-stack*))

(defun register-effect (startup-fn teardown-fn &key name)
  "Execute STARTUP-FN, and on success push TEARDOWN-FN onto *REVERT-STACK*.
TEARDOWN-FN is registered only after STARTUP-FN returns normally: an effect that never
took hold is never reverted. Returns STARTUP-FN's value.

NAME is optional and used only for the log lines."
  (let ((result (funcall startup-fn)))
    (push (lambda ()
            (when name
              (format t "~&[Disposing] ~A...~%" name))
            (funcall teardown-fn))
          *revert-stack*)
    (when name
      (format t "~&[Started] ~A~%" name))
    result))

(defun unwind-all ()
  "Execute every registered teardown closure in reverse (LIFO) order, emptying the stack.
A teardown that signals an ERROR is reported and skipped; the remaining teardowns still
run, so one bad inverse cannot strand the rest of the stack. Leaves *REVERT-STACK* NIL."
  (format t "~&--- Initiating Revertible Shutdown ---~%")
  (loop while *revert-stack*
        do (let ((disposal (pop *revert-stack*)))
             (handler-case (funcall disposal)
               (error (c)
                 (format t "~&[Error during teardown]: ~A~%" c))))))

(defmacro with-revertible-context (&body body)
  "Execute BODY inside a fresh revertible context stack.
Guarantees that all registered teardowns run in reverse order on normal exit, on a
non-local exit, or on an error raised anywhere in BODY.

The stack is rebound, so nested contexts are properly scoped: an inner context reverts its
own effects before the outer context reverts the effects registered around it — a consumer
set up inside a provider's scope is torn down before the provider goes away.

The scope closes when BODY returns. Use this for bounded work (a request, a migration, a
one-shot setup); for a long-lived server use START-NST-SERVER / STOP-NST-SERVER."
  `(let ((*revert-stack* nil))
     (unwind-protect
          (progn ,@body)
       (unwind-all))))

;;; ─── Example: a subsystem as a start/inverse pair ─────────────────
;;;
;;; The teardown closure captures `db-conn` lexically, so it does not depend on
;;; *DB-INSTANCE* still holding the right value at shutdown time.

(defvar *db-instance* nil
  "The live database handle, or NIL when no connection is open.")

;; ;; The connection protocol is the caller's: bind these to crm-db-connect and
;; ;; clsql:disconnect when this is wired into dod-ini-sys.lisp.

;; (defun start-db-subsystem (connection-string)
;;   "Open a database connection and register its inverse.
;; Setup and cleanup live adjacent — neither can be edited without the other in view."
;;   (register-effect
;;    ;; Startup closure
;;    (lambda ()
;;      (let ((db-conn (connect-to-db connection-string)))
;;        (setf *db-instance* db-conn)))
;;    ;; Teardown closure capturing `db-conn` lexically
;;    (lambda ()
;;      (disconnect-db *db-instance*)
;;      (setf *db-instance* nil))
;;    :name "Database Connection"))

;;; ─── Example: scope-bounded startup (as sketched) ─────────────────
;;;
;;; Demonstrates the ordering: the body's three effects are registered DB → HTTP → Cache,
;;; and the shutdown below them reverts Cache → HTTP → DB.

(defun run-app-server ()
  "Start a toy three-subsystem stack inside a context and revert it on exit."
  (with-revertible-context
    ;; Step 1: Start DB
    (register-effect
     (lambda () (format t "~&Opening DB pool...~%"))
     (lambda () (format t "~&Closing DB pool...~%"))
     :name "Database")

    ;; Step 2: Start App Server
    (register-effect
     (lambda () (format t "~&Binding HTTP port 8080...~%"))
     (lambda () (format t "~&Unbinding HTTP port 8080...~%"))
     :name "HTTP Server")

    ;; Step 3: Start Cache
    (register-effect
     (lambda () (format t "~&Initializing Redis cache...~%"))
     (lambda () (format t "~&Flushing & closing Redis cache...~%"))
     :name "Cache Layer")

    (format t "~&=== Server successfully started and running ===~%")))

;;; ─── Shared registration shapes ───────────────────────────────────

(defmacro register-global-effect (place loader &key name)
  "Register PLACE := (FUNCALL LOADER) as an effect whose inverse is PLACE := NIL.
The common shape for the template tables and the derived caches."
  `(register-effect (lambda () (setf ,place (funcall ,loader)))
                    (lambda () (setf ,place nil))
                    :name ,name))

;;; ─── START-NST-SERVER / STOP-NST-SERVER ───────────────────────────
;;;
;;; The main entry point. START-NST-SERVER is the port of start-das
;;; (dod-ini-sys.lisp:218) onto the revert stack; STOP-NST-SERVER is the port of
;;; stop-das (dod-ini-sys.lisp:295) and is nothing but UNWIND-ALL — the shutdown is
;;; derived from the startup, not written a second time.
;;;
;;; Every call in start-das is one register-effect, and every inverse comes from
;;; stop-das. Where the two had drifted — a global start-das loads and stop-das never
;;; nils — the inverse is supplied here and marked LEAK, so the omission is visible
;;; instead of silent.
;;;
;;; Unlike WITH-REVERTIBLE-CONTEXT, the stack here is global and outlives the call: the
;;; server stays up between START and STOP.

(defvar *server-running-p* nil
  "True between START-NST-SERVER and STOP-NST-SERVER.")

(defun start-nst-server (&optional (withssl nil) (debug-mode t))
  "Start the ninestores server, recording each subsystem's inverse on *REVERT-STACK*.
If any step signals, every step already completed is reverted before the error escapes,
so a failed boot never leaves a half-open pool or a bound port behind.

Process-local settings (*DOD-DEBUG-MODE*, *RANDOM-STATE*) are assigned directly: they
have no inverse and are not effects. Everything that acquires a resource, or binds a
global another subsystem reads, is registered.

Call STOP-NST-SERVER to revert, in reverse registration order."
  (when *server-running-p*
    (error "start-nst-server: server is already running"))
  (setf *revert-stack* nil)
  (unwind-protect
    (progn

      ;; ── not effects: no inverse, nothing to revert to ──
      (setf *dod-debug-mode* debug-mode)
      (setf *random-state* (make-random-state t))

      ;; ── HTTP acceptor and its logs (dod-ini-sys.lisp:224-226) ──
      ;; Building the acceptor and starting it are separate effects, so this inverse only
      ;; disposes the object; the start/stop pair below owns the listening socket.
      (register-effect
       (lambda ()
         (setf *http-server* (make-instance 'hunchentoot:easy-acceptor
                                            :port 4244 :document-root #p"~/ninestores/"))
         (setf (hunchentoot:acceptor-access-log-destination *http-server*)
               #p"~/hhublogs/ninestores-access.log")
         (setf (hunchentoot:acceptor-message-log-destination *http-server*)
               #p"~/hhublogs/ninestores-messages.log"))
       (lambda () (setf *http-server* nil))
       :name "HTTP acceptor")

      ;; ── CL-WHO quoting (dod-ini-sys.lisp:231). Real inverse: restore, not reset. ──
      (let ((previous cl-who:*attribute-quote-char*))
        (register-effect
         (lambda () (setq cl-who:*attribute-quote-char* #\"))
         (lambda () (setq cl-who:*attribute-quote-char* previous))
         :name "CL-WHO attribute quote char"))

      ;; init-hhubplatform (dod-ini-sys.lisp:209) only sets *DOD-DATABASE-CACHING*.
      ;; Real inverse: restore, since the previous value is knowable here.
      (let ((previous *dod-database-caching*))
        (register-effect
         (lambda () (init-hhubplatform))
         (lambda () (setf *dod-database-caching* previous))
         :name "HHUB platform"))

      (when withssl
        (register-effect
         (lambda () (init-httpserver-withssl) (hunchentoot:start *ssl-http-server*))
         (lambda () (hunchentoot:stop *ssl-http-server*) (setf *ssl-http-server* nil))
         :name "SSL acceptor"))

      (when (not withssl)
        (register-effect
         (lambda () (hunchentoot:start *http-server*))
         (lambda () (hunchentoot:stop *http-server*))
         :name "HTTP server (plain)"))

      (register-effect
       (lambda () (hunchentoot:reset-session-secret))
       (lambda () (hunchentoot:reset-session-secret))              ; restoring is not exposed
       :name "Session secret")

      ;; ── the database ──
      (register-effect
       (lambda ()
         (crm-db-connect :servername *crm-database-server* :strdb *crm-database-name*
                         :strusr *crm-database-user* :strpwd *crm-database-password*
                         :strdbtype :mysql))
       (lambda () (clsql:stop-sql-recording :type :both) (clsql:disconnect))
       :name "Database connection")

      ;; ── derived caches and template tables ──
      (register-global-effect *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*
                              #'hhub-gen-globally-cached-lists-functions
                              :name "Globally cached lists")
      (register-global-effect *NST-CORE-TEMPLATES* #'nst-load-core-templates
                              :name "Core templates")
      (register-global-effect *NST-INVOICE-TEMPLATES* #'nst-load-invoice-templates
                              :name "Invoice templates")
      (register-global-effect *NST-PRODUCT-TEMPLATES* #'nst-load-product-templates
                              :name "Product templates")            ; LEAK: never nilled
      (register-global-effect *NST-ORDER-TEMPLATES* #'nst-load-order-templates
                              :name "Order templates")
      (register-global-effect *NST-EMAIL-TEMPLATES* #'nst-load-email-templates
                              :name "Email templates")
      (register-global-effect *NST-CUSTOMER-TEMPLATES* #'nst-load-customer-templates
                              :name "Customer templates")
      (register-global-effect *NST-WAREHOUSE-TEMPLATES* #'nst-load-warehouse-templates
                              :name "Warehouse templates")          ; LEAK: never nilled
      (register-global-effect *NST-VENDOR-TEMPLATES* #'nst-load-vendor-templates
                              :name "Vendor templates")             ; LEAK: never nilled
      (register-global-effect *NST-VENDOR-TABLES-FOR-AGENTIC-AI*
                              #'nst-load-vendor-tables-structure-for-agentic-ai
                              :name "Vendor tables for agentic AI") ; LEAK: never nilled

      ;; ── in-memory tables and function registries ──
      (register-effect
       (lambda ()
         (setf *HHUBGLOBALBUSINESSFUNCTIONS-HT* (make-hash-table :test 'equal))
         (setf *HHUBPENDINGUPIFUNCTIONS-HT* (make-hash-table :test 'equal))
         (setf *HHUBBUSINESSSESSIONS-HT* (make-hash-table))
         (hhub-init-business-functions))
       (lambda ()
         (setf *HHUBGLOBALBUSINESSFUNCTIONS-HT* nil)
         (setf *HHUBPENDINGUPIFUNCTIONS-HT* nil)                 ; LEAK: never nilled
         (setf *HHUBBUSINESSSESSIONS-HT* nil))
       :name "Business function tables")

      (register-effect
       (lambda () (setf *HHUBBUSINESSSERVER* (initbusinessserver)))
       (lambda () (deletebusinessserver) (setf *HHUBBUSINESSSERVER* nil))
       :name "Business server")

      ;; ── derived global data ──
      (register-global-effect *NSTGSTSTATECODES-HT* #'init-gst-statecodes
                              :name "GST state codes")               ; LEAK: never nilled
      (register-global-effect *NSTUOM-HT* #'get-system-UOM-map
                              :name "Units of measure")              ; LEAK: never nilled
      (register-global-effect *NST-ALL-INDIA-PINCODES* #'get-all-india-pincodes-ht
                              :name "All-India pincodes")

      (register-effect
       (lambda () (init-gst-invoice-terms))
       (lambda () (setf *NSTGSTINVOICETERMS* nil))               ; LEAK: never reverted
       :name "GST invoice terms")

      (register-effect
       (lambda () (setf *otp-store* (make-otp-store)))
       (lambda () (when *otp-store* (funcall *otp-store* :clear)) (setf *otp-store* nil))
       :name "OTP store")

      (register-effect
       (lambda () (init-shipping-zones))
       (lambda () (setf *HHUBSHIPPINGZONES* nil))                ; LEAK: never reverted
       :name "Shipping zones")

      ;; These three populate hash tables that already exist (defvar'd alongside their
      ;; init functions), so the inverse is CLRHASH, not NIL.
      (register-effect
       (lambda () (init-warehouse-data))
       (lambda ()
         (dolist (ht (list warehouse-ownershiptype-ht warehouse-ownerentitytype-ht
                           warehouse-operatorentitytype-ht warehouse-legalentitytype-ht
                           warehouse-gstinstatus-ht warehouse-registrationtype-ht
                           warehouse-warehousetype-ht warehouse-warehousepurpose-ht
                           warehouse-valuationmethod-ht))
           (clrhash ht)))
       :name "Warehouse data")

      (register-effect
       (lambda () (init-customer-profile-data))
       (lambda ()
         (dolist (ht (list customer-businesstype-ht customer-customertype-ht
                           customer-gstregistrationtype-ht customer-kycstatus-ht
                           customer-paymentterms-ht))
           (clrhash ht)))
       :name "Customer profile data")

      (register-effect
       (lambda () (init-vendor-profile-data))
       (lambda ()
         (dolist (ht (list vendor-gstregistrationtype-ht vendor-gstfilingfrequency-ht
                           vendor-paymentgatewaymode-ht vendor-approvalstatus-ht))
           (clrhash ht)))
       :name "Vendor profile data")

      ;; ── actors: construction and start are one effect, destruction is its inverse ──
      (register-effect
       (lambda ()
         (setf *NSTSENDORDEREMAILACTOR*
               (make-instance 'nst-actor
                              :name "Send Order Email Actor"
                              :behavior #'send-order-email-behavior
                              :stateful t
                              :state-clean-callback (function (lambda () ()))
                              :initial-state 0))
         (start-actor *NSTSENDORDEREMAILACTOR*))
       (lambda ()
         (when *NSTSENDORDEREMAILACTOR*
           (destroy-actor *NSTSENDORDEREMAILACTOR*)
           (setf *NSTSENDORDEREMAILACTOR* nil)))
       :name "Send Order Email Actor")

      (register-effect
       (lambda ()
         (setf *NSTAWSS3FILEUPLOADACTOR*
               (make-instance 'nst-actor
                              :name "AWS S3 Bucket File Upload Actor"
                              :behavior #'async-upload-files-s3bucket-behavior
                              :stateful t
                              :state-clean-callback nil
                              :initial-state (make-hash-table)))
         (start-actor *NSTAWSS3FILEUPLOADACTOR*))
       (lambda ()
         (when *NSTAWSS3FILEUPLOADACTOR*
           (destroy-actor *NSTAWSS3FILEUPLOADACTOR*)
           (setf *NSTAWSS3FILEUPLOADACTOR* nil)))
       :name "AWS S3 File Upload Actor")

      (format t "~&=== ninestores server started ===~%")
      (setf *server-running-p* t))
    ;; Any error before the server is up reverts the partial boot; success leaves the
    ;; stack intact for STOP-NST-SERVER.
    (unless *server-running-p*
      (format t "~&[startup aborted — reverting partial boot]~%")
      (unwind-all)))
  *server-running-p*)

(defun stop-nst-server ()
  "Revert everything START-NST-SERVER registered, newest first.
This is the whole of stop-das: no hand-written teardown list, no second ordering to
keep in sync. The reverse order is a property of *REVERT-STACK*, not of this function."
  (unless *server-running-p*
    (error "stop-nst-server: server is not running"))
  (unwind-all)
  (setf *server-running-p* nil)
  nil)

;;; Drop-in wiring for dod-ini-sys.lisp, when the port is taken live:
;;;
;;;   (defun start-das (&optional (withssl nil) (debug-mode T))
;;;     (start-nst-server withssl debug-mode))
;;;
;;;   (defun stop-das ()
;;;     (stop-nst-server))
;;;
;;; Note the asymmetry this port exposes: START-DAS started the plain HTTP server only
;;; when WITHDSSL was NIL, but STOP-DAS decided which acceptor to stop by testing
;;; *SSL-HTTP-SERVER* — so a plain-server boot after an SSL boot stopped the SSL
;;; acceptor and leaked the plain one. Registering each start beside its own stop
;;; removes that class of bug.
