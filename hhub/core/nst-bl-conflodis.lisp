;; -*- mode: common-lisp; coding: utf-8 -*-
;;;; Context Flow Dispatcher 
(in-package :nstores)

;;; ---------------------------------------------------------------------------
;;; Call context - single mutable object passed through pipeline
;;; ---------------------------------------------------------------------------
(defclass call-context ()
  ((route-key    :initarg :route-key    :reader ctx-route-key)
   (http-request :initarg :ctx-http-request)
   (requestmodel-params  :initarg :requestmodel-params  :reader ctx-requestmodel-params)
   (trans-func-name :initarg :trans-func-name :reader ctx-trans-func-name)
   (requestmodel :accessor ctx-requestmodel :initform nil)
   (adapter      :accessor ctx-adapter      :initform nil)
   (domain-object :accessor ctx-domain-object :initform nil)
   (responsemodel :accessor ctx-responsemodel :initform nil)
   (presenter     :accessor ctx-presenter     :initform nil)
   (viewmodel     :accessor ctx-viewmodel     :initform nil)
   (view          :accessor ctx-view          :initform nil)
   (output-type :accessor ctx-output-type :initform nil)
   (bo-knowledge  :accessor ctx-bo-knowledge  :initform nil)
   (company :accessor ctx-company :initform nil)
   (context       :accessor ctx-context       :initform nil)))


;;; ---------------------------------------------------------------------------
;;; Outbound adapter route definition (DDD / Hexagonal naming)
;;; ---------------------------------------------------------------------------

(defclass outbound-adapter-route ()
  (
   ;; ----------------------------------------------
   ;; 1. BASIC IDENTIFICATION
   ;; ----------------------------------------------
   (route-key
     :initarg :route-key
     :accessor route-key
     :documentation "Keyword identifier for the route, e.g. :customer/read")

   (description
     :initarg :description
     :accessor description
     :initform ""
     :documentation "Human-readable description for documentation & dashboards.")
   (businessobject-class 
    :initarg :businessobject-class
    :accessor businessobject-class
    :initform nil
    :documentation "Business object class associated with this route" )
   (requestmodel-class 
    :initarg :requestmodel-class
    :accessor requestmodel-class
    :initform nil
    :documentation "Requestmodel class associated with this route" )
   
   (adapter-class
    :initarg :adapter-class
    :accessor adapter-class
    :initform nil
    :documentation "Adapter class associated with this route")
   (presenter-class
    :initarg :presenter-class
    :accessor presenter-class
    :initform nil
    :documentation "Presenter class associated with this route")
   (view-classes
    :initarg :view-classes
    :accessor view-classes
    :initform nil
    :documentation "View classes associated with this route")
   
    ;; ----------------------------------------------
   ;; 2. FUNCTIONAL METADATA: CRUD / OPERATION TYPE
   ;; ----------------------------------------------
   (crud-op
     :initarg :crud-op
     :accessor crud-op
     :documentation
     "Symbol indicating the domain operation: :create :read :update :delete :list :search :custom.")

   ;; Optional business operation name for non-CRUD actions
   (operation
     :initarg :operation
     :accessor operation
     :initform nil
     :documentation
     "Optional symbolic name for non-CRUD operations (e.g. :approve, :cancel, :rate, :checkout).")

   ;; ----------------------------------------------
   ;; 3. ROUTE STATE / FEATURE FLAGS
   ;; ----------------------------------------------
   (active
     :initarg :active
     :accessor active
     :initform t
     :documentation
     "Boolean flag to activate/deactivate this route without deleting it.")

   (feature-flags
     :initarg :feature-flags
     :accessor feature-flags
     :initform nil
     :documentation
     "List of feature flags controlling conditional behavior (e.g. '(enable-email new-pricing-model)).")

   ;; ----------------------------------------------
   ;; 5. SECURITY / ACCESS CONTROL
   ;; ----------------------------------------------
   (required-roles
     :initarg :required-roles
     :accessor required-roles
     :initform nil
     :documentation
     "List of roles allowed to call this route. Example: '(admin vendor support).")

   (permission-checker
     :initarg :permission-checker
     :accessor permission-checker
     :initform nil
     :documentation
     "Optional function performing advanced ACL:
       (lambda (route ctx user) -> T/NIL).")

   ;; ----------------------------------------------
   ;; 6. MULTI-TENANT ROUTING SUPPORT
   ;; ----------------------------------------------
   (tenant-overrides
     :initarg :tenant-overrides
     :accessor tenant-overrides
     :initform nil
     :documentation
     "Association list: (tenant-id . override-plist)
       Example:
       '((tenantA . (:default-outbound-adapters (json)))
         (tenantB . (:default-outbound-adapters (json kafka email)))
         (tenantC . (:active nil)))")

   ;; ----------------------------------------------
   ;; 7. LIFECYCLE HOOKS (pre/post)
   ;; ----------------------------------------------
   (before-dispatch-hook
     :initarg :before-dispatch-hook
     :accessor before-dispatch-hook
     :initform nil
     :documentation
     "Optional function: (lambda (route ctx) -> maybe mutate ctx).
      Runs BEFORE dispatch.")

   (after-dispatch-hook
     :initarg :after-dispatch-hook
     :accessor after-dispatch-hook
     :initform nil
     :documentation
     "Optional function: (lambda (route ctx domain resp) -> NIL).
      Runs AFTER primary dispatch but before outbound adapters.")

   ;; ----------------------------------------------
   ;; 8. AUDIT / OBSERVABILITY
   ;; ----------------------------------------------
   (audit-level
     :initarg :audit-level
     :accessor audit-level
     :initform :minimal
     :documentation
     "Audit level: :none :minimal :full :debug. Controls logging & monitoring.")
   (tags
     :initarg :tags
     :accessor tags
     :initform nil
     :documentation
     "Arbitrary metadata tags for grouping/searching routes.
      Example: '(customer rest v1 read-only).")
   (version
    :initarg :version
    :accessor version
    :initform nil
    :documentation "Version number")
   (metadata
    :initarg :metadata
    :accessor metadata
    :initform nil
    :documentation "Any meta data we would like to maintain")))



(defparameter *outbound-route-registry* (make-hash-table :test 'equal))



(defun register-outbound-route (route-key &key
					    businessobject-class
					    requestmodel-class
					    adapter-class
					    presenter-class
					    view-classes
					    description
					    crud-op
					    operation
					    (active t)
					    feature-flags
					    required-roles
					    tenant-overrides
					    before-dispatch-hook
					    after-dispatch-hook
					    audit-level
					    tags
					    (version 1)
                                            metadata)
  "Registers an outbound adapter route in *outbound-route-registry*.

Arguments:
  route-key                 - Required keyword (e.g. :customer/read)
  crud-op                   - :create :read :update :delete (optional)
  description               - Optional human description
  active                    - Whether route is active (default T)
  default-outbound-adapters - List of default output formats (e.g. '(json))
  adapter-selector          - Function(route ctx) -> list of output formats
  tags                      - Arbitrary tagging info
  version                   - Version number
  metadata                  - Extensible alist for future fields

Returns:
  The created outbound-adapter-route object."
  (assert route-key () "route-key is required")
  ;; Auto-infer CRUD-op if user didn't specify
  (let ((final-crud-op
          (or crud-op
              (cond
                ((search "/read"   (string-downcase (symbol-name route-key))) :read)
                ((search "/create" (string-downcase (symbol-name route-key))) :create)
                ((search "/update" (string-downcase (symbol-name route-key))) :update)
                ((search "/delete" (string-downcase (symbol-name route-key))) :delete)
                (t :read)))))   ;; sensible default
    (let ((route (make-instance 'outbound-adapter-route
                                :route-key route-key
                                :crud-op final-crud-op
				:requestmodel-class requestmodel-class 
				:businessobject-class businessobject-class
				:adapter-class adapter-class
				:presenter-class presenter-class
				:view-classes view-classes 
				:description description
				:operation operation
				:active active
                                :audit-level audit-level
				:feature-flags feature-flags
				:required-roles required-roles
				:before-dispatch-hook before-dispatch-hook
				:after-dispatch-hook after-dispatch-hook
				:tenant-overrides tenant-overrides
				:tags tags
                                :version version
                                :metadata metadata)))
      ;; store in registry
      (setf (gethash route-key *outbound-route-registry*) route)
      route)))

(defun find-outbound-route (route-key)
  (gethash route-key *outbound-route-registry*))

(defmethod collect-abac-attributes ((route outbound-adapter-route) (ctx call-context))
  (let ((params nil))
    ;; Always include URI
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    ;; Include company if available
    (let ((company (ctx-company ctx)))
      (when company
        (setf params (acons "company" company params))))
    ;; Subject attributes (example)
    (when (ctx-context ctx)
      (setf params (acons "subject-id" (slot-value (ctx-context ctx) 'user-id) params)))
    ;; Resource attributes derived from route
    (setf params (acons "resource" (symbol-name (ctx-route-key ctx)) params))
    ;; Action inferred from CRUD
    (setf params (acons "action" (symbol-name (crud-op route)) params))
    ;; Environment IP
    (setf params (acons "client-ip" (hunchentoot:remote-addr*) params))
    params))

(defgeneric make-adapter (route ctx)
  (:documentation "Create adapter instance for route. Override as needed."))

(defgeneric make-presenter (route ctx)
  (:documentation "Returns a presenter instance for this request."))

(defgeneric make-view (route ctx output-type)
  (:documentation "Returns a view instance for this request."))

(defgeneric make-requestmodel (route ctx)
  (:documentation "Create requestmodel instance for a route from ctx-requestmodel-params."))

(defmethod make-requestmodel ((route outbound-adapter-route) (ctx call-context))
  ;; By default assume requestmodel-params is a plist of initargs
  (let* ((rmclass (requestmodel-class route))
	 (requestmodel-params (ctx-requestmodel-params ctx))
         (name (string-upcase (symbol-name rmclass)))
         (cls  (intern (format nil "~A" name) :nstores)))
    (if (find-class cls nil)
        (apply #'make-instance cls requestmodel-params)
        ;; safe fallback presenter
        (make-instance 'standard-object))))

(defmethod make-presenter ((route outbound-adapter-route) (ctx call-context))
  (let* ((class (presenter-class route))
         (name (string-upcase (symbol-name class)))
         (cls  (intern (format nil "~A" name) :nstores)))
    (if (find-class cls nil)
        (make-instance cls)
        ;; safe fallback presenter
        (make-instance 'standard-object))))

(defmethod make-view ((route outbound-adapter-route)
                      (ctx   call-context)
                      output-type)
  (let* ((truth (bo-knowledge-truth (ctx-bo-knowledge ctx)))
         (view-class
           (case truth
             (:T  (resolve-view-for route output-type))
             (:F  'ViewNIL)
             (:U  'ViewUnknown)
             (:C  'ViewContradiction)
             (otherwise 'ViewUnknown)))       ;; safe fallback
         ;; Convert symbol → class object
         (cls-object (find-class view-class nil)))
    (if cls-object
        (make-instance cls-object)
        (error "Unknown view class: ~A" view-class))))

(defmethod make-adapter ((route outbound-adapter-route) (ctx call-context))
  (let* ((class (adapter-class route))
         (name (string-upcase (symbol-name class)))
         (cls  (intern (format nil "~A" name) :nstores)))
    (if (find-class cls nil)
        (make-instance cls)
        ;; safe fallback presenter
        (make-instance 'standard-object))))

(defun route-op->method-name (route-key)
  "Extract operation from keyword like :customer/read and compute method name."
  (let* ((name (string route-key))             ; ":customer/read"
         (slash-pos (position #\/ name))
         (op (subseq name (1+ slash-pos)))     ; "read"
         (method-name (format nil "process~arequest" op)))
    (intern (string-upcase method-name) :nstores)))

;;; ---------------------------------------------------------------------------
;;; Core dispatch pipeline (CLOS generic with method combinators)
;;; - :before: prepare requestmodel, adapter, service
;;; - primary: invoke application/business flow (adapter -> service -> produce domain object)
;;; - :after: create responsemodel from adapter/service output
;;; - :around: choose outbound adapters (routing) and run them (short-circuiting possible)
;;; ---------------------------------------------------------------------------
(defgeneric dispatch (ctx route output-type)
  (:documentation "Runs pipeline + outbound adapter selection."))

(defmethod dispatch :before ((ctx call-context) (route outbound-adapter-route) output-type)
  (let ((route (find-outbound-route (ctx-route-key ctx))))
    (unless route (error "No outbound route registered for ~a" (ctx-route-key ctx)))
    (format t "dispatch :before called")
    ;; create requestmodel and attach
    (setf (ctx-requestmodel ctx) (make-requestmodel route ctx))
    (setf (ctx-company ctx) (slot-value (ctx-requestmodel ctx) 'company))
    ;; create adapter/service if desired
    (setf (ctx-adapter ctx) (make-adapter route ctx))))

(defmethod dispatch ((ctx call-context) (route outbound-adapter-route) output-type)
  (let ((adapter         (ctx-adapter ctx))
        (rm              (ctx-requestmodel ctx))
        (route-key       (ctx-route-key ctx))
        (trans-func-name (ctx-trans-func-name ctx))
	(params (collect-abac-attributes route ctx)))
    (when (and adapter rm route-key trans-func-name)
      (let* ((method-symbol (route-op->method-name route-key))
             (processxxxxrequestfunc (symbol-function method-symbol)))
	;; ABAC Enforcement Layer (PEP)
        (with-hhub-transaction trans-func-name params
          ;; Business Domain Call
	  (let ((domain (funcall processxxxxrequestfunc adapter rm)))
	    (setf (ctx-domain-object ctx) domain))))
      ;; set the adapter bo-knowledge to the ctx bo-knowledge
      (setf (ctx-bo-knowledge ctx) (bo-knowledge adapter))
      ;; Return the updated context to the around methods
      ctx)))

(defmethod dispatch :after ((ctx call-context) (route outbound-adapter-route) output-type)
  ;; Default after: create responsemodel via adapter if a function exists
  (let ((adapter (ctx-adapter ctx))
        (domain (ctx-domain-object ctx)))
    (when (and adapter domain)
      (let ((resp (processresponse adapter domain)))
        (setf (ctx-responsemodel ctx) resp)))))
 
(defmethod dispatch :around ((ctx call-context) (route outbound-adapter-route) output-type)
  ;; Run the primary + before/after methods first.
  (call-next-method)  ;; result = ctx after primary pipeline
  ;; Now perform OUTBOUND work
  (let* ((presenter   (ctx-presenter ctx))
	 (view        (make-view route ctx output-type)) 
	 (response    (ctx-responsemodel ctx))
         (viewmodel   nil))
    ;; Build viewmodel using presenter (domain-agnostic)
    (when presenter
      (setf viewmodel (createviewmodel presenter response))
      (setf (ctx-viewmodel ctx ) viewmodel))
     ;; Now select proper rendering
    (render view viewmodel)))


;; View resolver from the route
(defun resolve-view-for (route output-type)
  (cdr (assoc output-type (view-classes route) :test 'equal)))



;;; ---------------------------------------------------------------------------
;;; Convenience entry: build ctx and dispatch
;;; ---------------------------------------------------------------------------
(defun make-call-context (route-key requestmodel-params trans-func-name)
  (let* ((route  (find-outbound-route route-key))
         (ctx    (make-instance 'call-context
                                :route-key route-key
                                :requestmodel-params requestmodel-params
                                :trans-func-name trans-func-name)))
    ;; Build RequestModel, Adapter, Service, Presenter, View immediately
    (setf (ctx-requestmodel ctx) (make-requestmodel route ctx))
    (setf (ctx-adapter ctx)      (make-adapter route ctx))
    (setf (ctx-presenter ctx)    (make-presenter route ctx))
    ctx))

(defun dispatch-route (route-key raw-params &key trans-func-name output-type)
  (let* ((ctx (make-call-context route-key raw-params trans-func-name))
	 (route (find-outbound-route route-key))
	 (otype  (or output-type (caar (view-classes route)))))
    (dispatch ctx route otype)))
    
;;; End of nst-bl-conflodis.lisp

(register-outbound-route
  :customer/read
  :crud-op :read
  :description "Reads customer profile by phone"
  :requestmodel-class 'CustomerSearchRequestModel
  :businessobject-class 'Customer
  :adapter-class 'CustomerAdapter
  :presenter-class 'CustomerPresenter
  :view-classes  '((json . CustomerAddressJSONView))
  :tags '(customer api v1)
  :required-roles '(customer support)
  :feature-flags '(new-customer-domain)
  :audit-level :full)
 
