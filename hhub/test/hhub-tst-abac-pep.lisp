;;; hhub-tst-abac-pep.lisp
;;;
;;; Verification harness for the ABAC PEP condition hierarchy and the
;;; with-hhub-transaction URI-verification behavior.
;;;
;;; House style: like the other hhub-tst-*.lisp files this runs in the
;;; :nstores package inside a loaded nstores image. It defines no packages
;;; and re-defines no Hunchentoot function: the deny path is exercised
;;; against the REAL hunchentoot:redirect / abort-request-handler
;;; primitives inside a minimal but real request/reply context.
;;;
;;; Standalone from a bare SBCL (sbcl --script ...), the bootstrap below
;;; loads the repository's own package/packages.lisp and Hunchentoot via
;;; Quicklisp, so the file is self-verifiable. Inside a loaded nstores
;;; image the bootstrap is a no-op.

;; ── Bootstrap: use the real packages, define nothing new ─────────────────────
;; NOTE: these forms run BEFORE (in-package :nstores), so no helper symbol
;; may cross the package boundary — the hhub/ directory is computed inline.

(when (null (find-package :nstores))
  (load (merge-pathnames
         "package/packages.lisp"
         (let ((lt (or *load-truename* *load-pathname*)))
           (if (and lt (search "/hhub/test/" (namestring lt)))
               (directory-namestring (merge-pathnames "../" (directory-namestring lt)))
               "/home/ubuntu/ninestores/hhub/")))))

(when (null (find-package :hunchentoot))
  (load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))

(when (null (find-package :hunchentoot))
  (ql:quickload :hunchentoot))

(in-package :nstores)

(defun nstores-hhub-dir ()
  "Repository hhub/ root — derived from this file's location when loaded
   from the checkout, with an absolute fallback for ad-hoc runs."
  (let ((lt (or *load-truename* *load-pathname*)))
    (if (and lt (search "/hhub/test/" (namestring lt)))
        (directory-namestring (merge-pathnames "../" (directory-namestring lt)))
        "/home/ubuntu/ninestores/hhub/")))

;; ── Transport test-doubles ───────────────────────────────────────────────────
;; The PEP is exercised against a deterministic, DB-free environment. The
;; transactions hash table is always reached through the app's real
;; hhub-get-cached-transactions-ht (already defined by the app); the tests
;; populate and clear the table it returns. get-ht-val, uri-prefix-boundary-p
;; and hhub-get-cached-transactions-ht are left as the real app functions when
;; present — the guarded definitions below exist only so the file can also
;; run standalone from a bare SBCL. logiamhere is only defined if the app did
;; not already provide it.

(defclass transaction-stub ()
  ((uri :initarg :uri :initform nil :accessor transaction-uri)
   (trans-func :initarg :trans-func :initform nil :accessor transaction-trans-func)))

(defvar *policy-result* t)         ; what has-permission returns (Belnap T / NIL)

(unless (fboundp 'get-ht-val)
  (defun get-ht-val (key hash-table)
    (gethash key hash-table)))

(unless (fboundp 'hhub-get-cached-transactions-ht)
  ;; Standalone fallback only: the app's function serves the globally cached
  ;; transactions hash table; here we close over a stable test-only table so
  ;; (hhub-get-cached-transactions-ht) is callable without the app loaded.
  (let ((test-transactions-ht (make-hash-table :test 'equal)))
    (setf (symbol-function 'hhub-get-cached-transactions-ht)
          (lambda () test-transactions-ht))))

(defparameter *uri-boundary-chars* '(#\/ #\? #\# #\;))

(unless (fboundp 'uri-prefix-boundary-p)
  (defun uri-prefix-boundary-p (prefix uri)
    (and (let ((plen (length prefix)))
           (and (<= plen (length uri))
                (string= prefix uri :end2 plen)))
         (let ((plen (length prefix)))
           (or (= plen (length uri))
               (not (null (find (aref uri plen) *uri-boundary-chars*))))))))

(defun has-permission (transaction &optional params)
  (declare (ignore transaction params))
  (if *policy-result* (list t nil) (list nil "Policy declined.")))

(unless (fboundp 'logiamhere)
  (defmacro logiamhere (msg)
    `(format t "    [logiamhere] ~A~%" ,msg)))

;; Gensym detection (gensym-p is Alexandria, not standard CL)
(defun gensym-p (s)
  (and (symbolp s) (null (symbol-package s))))

;; ── Load the REAL condition hierarchy from the repository ────────────────────
(load (merge-pathnames "core/dod-bl-err.lisp" (nstores-hhub-dir)))

;; ── Extract and eval the REAL macro from core/dod-ui-utl.lisp ────────────────
(defun extract-balanced-form (string start)
  "Return the substring of STRING spanning the balanced form that opens at START."
  (let ((depth 0)
        (i start)
        (in-string nil)
        (in-comment nil)
        (n (length string)))
    (loop while (< i n) do
      (let ((ch (char string i)))
        (cond (in-comment (when (char= ch #\Newline) (setf in-comment nil)))
              (in-string  (when (char= ch #\") (setf in-string nil)))
              ((char= ch #\;) (setf in-comment t))
              ((char= ch #\") (setf in-string t))
              ((char= ch #\() (incf depth))
              ((char= ch #\)) (decf depth))))
      (when (< depth 0)
        (error "Unbalanced form in macro source (depth < 0 at ~A)" i))
      (when (and (zerop depth) (> i start))
        ;; NB: RETURN exits only the LOOP block; RETURN-FROM exits the defun,
        ;; otherwise the error form after the loop fires unconditionally.
        (return-from extract-balanced-form (subseq string start (1+ i))))
      (incf i))
    (error "Unbalanced form in macro source (EOF at ~A)" i)))

(let ((macro-text
        (with-open-file (s (merge-pathnames "core/dod-ui-utl.lisp"
                                            (nstores-hhub-dir)))
          (let ((contents (make-string (file-length s))))
            (read-sequence contents s)
            contents))))
  (let ((start (search "(defmacro with-hhub-transaction" macro-text)))
    (assert start () "with-hhub-transaction not found in dod-ui-utl.lisp")
    (let ((form (extract-balanced-form macro-text start)))
      (format t "~%Extracted macro form (~D chars) from core/dod-ui-utl.lisp~%" (length form))
      (eval (read-from-string form)))))

;; ── Test helpers ─────────────────────────────────────────────────────────────
(defvar *pass-count* 0)
(defvar *fail-count* 0)

(defun reset! ()
  (setf *policy-result* t)
  (clrhash (hhub-get-cached-transactions-ht)))

(defun check (label condition)
  (if condition
      (progn (incf *pass-count*)
             (format t "  [PASS] ~A~%" label))
      (progn (incf *fail-count*)
             (format t "  [FAIL] ~A~%" label))))

(defun run-request (thunk)
  "Run THUNK inside a minimal but REAL Hunchentoot request/reply context.
   The PEP deny path calls hunchentoot:redirect, which sets the Location
   header on *reply* and then aborts by throwing 'handler-done; we catch
   that tag here. Returns (values result reply completed-p)."
  (let ((acceptor (make-instance 'hunchentoot:acceptor)))
    (let ((hunchentoot:*acceptor* acceptor))
      ;; *acceptor* must be bound before the REQUEST instance is created:
      ;; hunchentoot's initialize-instance :after runs session-verify.
      (let ((request (make-instance 'hunchentoot:request
                                    :headers-in '((:host . "test.local"))
                                    :uri "/hhub/warehouse"))
            (reply (make-instance 'hunchentoot:reply))
            (completed-p nil)
            (result nil))
        (let ((hunchentoot:*request* request)
              (hunchentoot:*reply* reply))
          (setf result (catch 'hunchentoot::handler-done
                         ;; PROG1: the catch must return the THUNK's value,
                         ;; not the completed-p flag set after it.
                         (prog1 (funcall thunk)
                           (setf completed-p t)))))
        (values result reply completed-p)))))

(defun expect-deny (label reply completed-p &optional (expected-msg-substring nil))
  "The deny path must have redirected (Location + HTTP 302) AND aborted
   (the handler-done throw was caught, so the thunk never completed)."
  (let ((location (and reply (hunchentoot:header-out :location reply))))
    (check (format nil "~A → redirect fired (Location set)" label)
           (and location (search "/hhub/permissiondenied" location)))
    (check (format nil "~A → abort fired (handler-done thrown)" label)
           (null completed-p))
    (check (format nil "~A → HTTP 302" label)
           (and reply (eql (hunchentoot:return-code* reply) 302)))
    (when expected-msg-substring
      (check (format nil "~A → deny message mentions '~A'" label expected-msg-substring)
             (and location (search expected-msg-substring location))))))

;; ── The suite ─────────────────────────────────────────────────────────────────
(defun run-abac-pep-tests ()
  "Run the full ABAC PEP verification suite from the REPL.
   Returns T when every check passed."
  (setf *pass-count* 0 *fail-count* 0)
  ;; ── 1. Happy path: uri matches + permission granted → body runs ────────────
  (format t "~%TEST 1: grant path~%")
(reset!)
(setf (gethash "com-hhub-transaction-readall-warehouse" (hhub-get-cached-transactions-ht))
      (make-instance 'transaction-stub
                     :uri "/hhub/vwarehousedetailspage"
                     :trans-func "com-hhub-transaction-readall-warehouse"))
(multiple-value-bind (result reply completed-p)
    (run-request (lambda ()
                   (with-hhub-transaction "com-hhub-transaction-readall-warehouse"
                       (list (cons "uri" "/hhub/vwarehousedetailspage"))
                     :body-ran)))
  (check "body evaluated, primary value" (eq result :body-ran))
  (check "grant path completed normally" completed-p)
  (check "grant path did not redirect"
         (null (hunchentoot:header-out :location reply))))
(check "multiple values preserved"
       (= 42 (nth-value 1
              (with-hhub-transaction "com-hhub-transaction-readall-warehouse"
                  (list (cons "uri" "/hhub/vwarehousedetailspage"))
                (values :body-ran 42)))))

;; ── 2. DB uri empty (config defect) → hhub-abac-uri-missing-error → deny ────
(format t "~%TEST 2: missing DB uri → deny~%")
(reset!)
(setf (gethash "tx-no-uri" (hhub-get-cached-transactions-ht))
      (make-instance 'transaction-stub :uri nil :trans-func "tx-no-uri"))
(multiple-value-bind (result reply completed-p)
    (run-request (lambda ()
                   (with-hhub-transaction "tx-no-uri"
                       (list (cons "uri" "/hhub/page"))
                     :should-not-run)))
  (declare (ignore result))
  (expect-deny "missing-uri" reply completed-p "Permission%20Denied"))

;; ── 3. Request carries no uri (caller defect) → hhub-abac-uri-absent-error ──
(format t "~%TEST 3: absent request uri → deny~%")
(reset!)
(setf (gethash "tx-uri" (hhub-get-cached-transactions-ht))
      (make-instance 'transaction-stub :uri "/hhub/page" :trans-func "tx-uri"))
(multiple-value-bind (result reply completed-p)
    (run-request (lambda ()
                   (with-hhub-transaction "tx-uri" nil
                     :should-not-run)))
  (declare (ignore result))
  (expect-deny "absent-uri" reply completed-p))

;; ── 4. URI mismatch → hhub-abac-uri-mismatch-error raised → deny ────────────
;; NOTE: the PEP's internal handler-case deliberately intercepts the raised
;; condition BEFORE any outer observer, so the deny is deterministic and cannot
;; be converted into a grant or a 500 by enclosing handlers. External code
;; observes the failure via the deny redirect + the macro's log line.
(format t "~%TEST 4: uri mismatch → deny (fail-closed, deterministic)~%")
(reset!)
(setf (gethash "tx-uri" (hhub-get-cached-transactions-ht))
      (make-instance 'transaction-stub :uri "/hhub/orders" :trans-func "tx-uri"))
(let ((observed nil))
  ;; An enclosing observer (e.g. a dispatcher-level audit hook) must NOT be
  ;; able to swallow the condition and change the deny outcome.
  (run-request
   (lambda ()
     (handler-bind ((hhub-abac-uri-error
                     (lambda (c)
                       (declare (ignore c))
                       (setf observed :intercepted))))
       (handler-case
           (with-hhub-transaction "tx-uri"
               (list (cons "uri" "/hhub/invoices"))
             :should-not-run)
         (error (c) (declare (ignore c)) nil)))))
  (check "outer observer did not swallow the condition" (null observed)))
(multiple-value-bind (result reply completed-p)
    (run-request (lambda ()
                   (with-hhub-transaction "tx-uri"
                       (list (cons "uri" "/hhub/invoices"))
                     :should-not-run)))
  (declare (ignore result))
  (expect-deny "mismatch" reply completed-p "Permission%20Denied"))

;; ── 5. Unknown transaction → hhub-abac-transaction-error propagates ─────────
(format t "~%TEST 5: unknown transaction propagates (config error)~%")
(reset!)
(handler-case
    (progn
      (with-hhub-transaction "com-hhub-transaction-does-not-exist"
          (list (cons "uri" "/hhub/x"))
        :should-not-run)
      (check "unknown transaction raised" nil))
  (hhub-abac-transaction-error (c)
    (check "hhub-abac-transaction-error raised"
           (search "Did not find transaction" (getExceptionStr c))))
  (error (c)
    (check "unexpected condition type"
           (typep c 'hhub-abac-transaction-error))))

;; ── 6. Permission denied (policy) → deny, no URI condition ───────────────────
(format t "~%TEST 6: policy deny → redirect, no condition raised~%")
(reset!)
(setf *policy-result* nil)
(setf (gethash "tx-uri" (hhub-get-cached-transactions-ht))
      (make-instance 'transaction-stub :uri "/hhub/page" :trans-func "tx-uri"))
(let ((observed nil))
  (handler-bind ((hhub-abac-uri-error
                  (lambda (c) (setf observed (type-of c)))))
    (run-request (lambda ()
                   (handler-case
                       (with-hhub-transaction "tx-uri"
                           (list (cons "uri" "/hhub/page"))
                         :should-not-run)
                     (error (c) (declare (ignore c)) nil)))))
  (check "no URI condition on policy deny" (null observed)))
(multiple-value-bind (result reply completed-p)
    (run-request (lambda ()
                   (with-hhub-transaction "tx-uri"
                       (list (cons "uri" "/hhub/page"))
                     :should-not-run)))
  (declare (ignore result))
  (expect-deny "policy-deny" reply completed-p "Policy%20declined."))

;; ── 7. Condition :report + slot accessors ────────────────────────────────────
(format t "~%TEST 7: :report output + slot accessors~%")
(let ((c (make-condition 'hhub-abac-uri-mismatch-error
                         :errstring "tx-mismatch"
                         :db-uri "/hhub/a"
                         :request-uri "/hhub/b")))
  (format t "    report: ~A~%" c)
  (check "report includes both uris"
         (and (search "/hhub/a" (format nil "~A" c))
              (search "/hhub/b" (format nil "~A" c))))
  (check "abac-db-uri accessor" (equal (abac-db-uri c) "/hhub/a"))
  (check "abac-request-uri accessor" (equal (abac-request-uri c) "/hhub/b"))
  (check "condition is an error" (typep c 'error))
  (check "condition is in hierarchy" (typep c 'hhub-abac-error))
  (check "transaction-error is in hierarchy"
         (typep (make-condition 'hhub-abac-transaction-error
                                :errstring "x")
                'hhub-abac-error))
  (check "uri-missing is in uri family"
         (typep (make-condition 'hhub-abac-uri-missing-error
                                :errstring "x" :db-uri nil :request-uri nil)
                'hhub-abac-uri-error))
  (check "uri-absent is in uri family"
         (typep (make-condition 'hhub-abac-uri-absent-error
                                :errstring "x" :db-uri nil :request-uri nil)
                'hhub-abac-uri-error)))

;; ── 8. Macro hygiene: internal bindings are gensyms ──────────────────────────
(format t "~%TEST 8: expansion hygiene~%")
(let* ((expansion (macroexpand-1
                   '(with-hhub-transaction "tx"
                       (list (cons "uri" "/hhub/x"))
                     (format t "body~%"))))
       (let*-bindings (when (and (consp expansion)
                                 (eq (first expansion) 'let*))
                        (second expansion)))
       (binding-names (mapcar #'first let*-bindings)))
  (check "expansion is a let*" (consp let*-bindings))
  (check "all 8 internal bindings are gensyms"
         (and (= 8 (length binding-names))
              (every #'gensym-p binding-names)))
  (check "no interned capture symbols leak into expansion"
         (loop for name in binding-names
               never (find-symbol (symbol-name name) :nstores))))

  ;; ── Summary ────────────────────────────────────────────────────────────────
  (format t "~%~%==== ABAC PEP harness: ~D passed, ~D failed ====~%"
          *pass-count* *fail-count*)
  (zerop *fail-count*))

;; ── Entry points ─────────────────────────────────────────────────────────────
;; Loading this file runs the suite once. From the REPL you can then call
;; (run-abac-pep-tests) to re-run without reloading.
;; The sb-ext:exit below only fires when stdin is non-interactive (script/CI),
;; so a failed suite never kills a REPL session.
(eval-when (:load-toplevel :execute)
  (run-abac-pep-tests)
  (when (and (plusp *fail-count*)
             (not (interactive-stream-p *standard-input*)))
    (sb-ext:exit :code 1)))
