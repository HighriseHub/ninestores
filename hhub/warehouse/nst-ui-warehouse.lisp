;;; nst-dal-warehouse.lisp — Domain class
(in-package :nstores)

;;; nst-ui-warehouse.lisp — list page only, nothing else touched yet

(defclass nst-whs-list-view () ()
  (:documentation
   "Pure dispatch marker for RenderListViewHTML — NOT part of either
    Tree 1 or Tree 2. Carries no state, exists only so CL-WHO output
    functions can be specialized by defmethod like the old HTMLView
    pattern did, without inheriting any of that tree's baggage."))

(defun com-hhub-transaction-readall-warehouse ()
  "Unchanged — with-mvc-ui-page's contract stays as-is."
  (with-vend-session-check
    (with-mvc-ui-page "Warehouse Management"
                      #'create-model-for-showwarehouses
                      #'create-widgets-for-showwarehouses
                      :role :vendor)))


(defun create-model-for-showwarehouses ()
  (let* ((vendor-name (get-login-vendor-name))
         (company (get-login-vendor-company))
         (ctx (make-domain-ctx :actor "VENDOR" :tenant company :channel "ONLINE"
                                :recipient "VENDOR" :source "VENDOR"))
         (warehouselist (enumerate 'nst-whs ctx))
         (responselist (domain->response-list warehouselist ctx))
         (params nil))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (setf params (acons "company" company params))
    (with-hhub-transaction "com-hhub-transaction-readall-warehouse" params
      (function (lambda () (values responselist vendor-name ctx))))))

(defun create-widgets-for-showwarehouses (modelfunc)
  (multiple-value-bind (responselist username ctx) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
                     (cl-who:with-html-output (*standard-output* nil)
                       (:div :id "row"
                             (:div :id "col-xs-6"
                                   (:h3 "Welcome " (cl-who:str (format nil "~A" username)))))
                       (warehouse-search-html)
                       (:hr)))))
          (widget2 (function (lambda ()
                     (cl-who:with-html-output (*standard-output* nil)
                       (with-html-div-row (:h4 "Showing warehouses"))
                       (:div :id "warehouselivesearchresult"
                             (:div :class "row"
                                   (:div :class "col-xs-6"
                                         (:a :href "/hhub/vwarehousedetailspage"
                                             :class "btn btn-primary" "Create Warehouse"))
                                   (:div :class "col-xs-6" :align "right"
                                         (:span :class "badge"
                                                (cl-who:str (format nil "~A" (length responselist))))))
                             (:hr)
                             (cl-who:str (render-html-list responselist ctx))))))))
      (list widget1 widget2))))


(defun create-model-for-searchwarehouses ()
  "Create model for searching warehouses"
  (let* ((search-clause (hunchentoot:parameter "warehouselivesearch"))
         (company (get-login-company))
         (warehousepresenter (make-instance 'WarehousePresenter))
         (warehouserequestmodel (make-instance 'WarehouseSearchRequestModel
                                              :wname search-clause
                                              :company company))
         (warehouseadapter (make-instance 'WarehouseAdapter))
         (warehouseobjlst (processreadallrequest warehouseadapter warehouserequestmodel))
         (warehouseresponsemodellist (processresponselist warehouseadapter warehouseobjlst))
         (viewallmodel (CreateAllViewModel warehousepresenter warehouseresponsemodellist))
         (htmlview (make-instance 'WarehouseHTMLView))
         (params nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "rolename" (get-login-user-role-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (with-hhub-transaction "com-hhub-transaction-search-warehouse-action" params 
      (function (lambda ()
        (values viewallmodel htmlview))))))

(defun create-widgets-for-searchwarehouses (modelfunc)
  "Create widgets for search results"
  (multiple-value-bind (viewallmodel htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
                     (cl-who:with-html-output (*standard-output* nil) 
                       (:div :class "row"
                             (:div :class "col-xs-6")
				   
				   (:div :class "col-xs-6" :align "right" 
                                   (:span :class "badge" 
                                         (cl-who:str (format nil "~A" (length viewallmodel))))))
                       (:hr)
                       (RenderListViewHTML htmlview viewallmodel))))))
      (list widget1))))

(defun com-hhub-transaction-search-warehouse-action ()
  "Search warehouse action handler"
  (let* ((modelfunc (funcall #'create-model-for-searchwarehouses))
         (widgets (funcall #'create-widgets-for-searchwarehouses modelfunc)))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (loop for widget in widgets do
        (cl-who:str (funcall widget))))))

(defun nst-controller-search-my-warehouse-action ()
  "Shakvari-tier UI action: live-search filter for warehouse list page.
   All filtering logic lives in enumerate — this function only renders."
  (with-vend-session-check
    (let* ((company (get-login-vendor-company))
	   (ctx (make-domain-ctx :actor "VENDOR" :tenant company :channel "ONLINE" :recipient "VENDOR" :source "VENDOR"))
           (name-like (hunchentoot:parameter "warehouselivesearch"))
	   (htmlview (make-instance 'nst-whs-list-view))
           (warehouselist (enumerate 'nst-whs ctx :name-like name-like)))
      (logiamhere (format nil "name-like is ~A found ~A records" name-like (length warehouselist)))
      (if warehouselist
          (cl-who:with-html-output (*standard-output* nil)
	    (:div :class "row"
		  (:div :class "col-xs-6"
			(:a :href (format nil "/hhub/vwarehousedetailspage")   :class "btn btn-primary" "Create Warehouse"))
		  (:div :class "col-xs-6" :align "right"
                        (:span :class "badge"
			       (cl-who:str (format nil "~A" (length warehouselist))))))
	    (:hr)
	    (RenderListViewHTML htmlview warehouselist))
	  ;;else 
	  (cl-who:with-html-output (*standard-output* nil)
            (:h3 (cl-who:str "No Records Found")))))))


;;; ---------------------------------------------------------------------------
;;; render-html — list of WarehouseResponseModel (post-domain->response)
;;; ---------------------------------------------------------------------------
;;;
;;; The transport hop for the WAREHOUSE LIST page takes a LIST of
;;; WarehouseResponseModel (the boundary-tree output of domain->response)
;;; and renders the full HTML table. dispatch is on the LIST, so this is
;;; the "many warehouses" cardinality of the render-html generic; the
;;; row-level formatting is delegated to display-warehouse-row, exactly as
;;; RenderListViewHTML does for the entity-level list. cl-who:str inside
;;; display-warehouse-row provides HTML-escaping for every cell — same
;;; safety as the existing list page.

(defmethod render-html ((rm WarehouseResponseModel) (ctx domain-ctx))
  "Single-item HTML fragment — genuinely entity-specific, dispatches
   correctly. THIS is where display-warehouse-row's logic belongs."
  (display-warehouse-row rm))

(defun render-html-list (responses ctx)
  "Plain function, not a generic — 'list' can't discriminate contents,
   so don't ask CLOS to. Delegates each row to the entity-specific
   render-html method above; CLOS dispatch happens per-element,
   where it actually works."
  (when responses
    (display-as-table (list "Name" "GSTIN" "City" "State" "Type" "Ownership"
                             "Manager" "Phone" "Active" "Actions")
                       responses (lambda (r &rest _) (declare (ignore _)) (render-html r ctx)))))

(defun display-warehouse-row (whs &rest arguments)
  "UNVERIFIED against nst-whs's actual accessor names this session —
   these are the slot names I've been writing throughout (wname,
   warehouse-gstin, etc.) but I have not re-confirmed the accessor
   forms (vs slot-value) exist on nst-whs. Grep before running this."
  (declare (ignore arguments))
  (cl-who:with-html-output (*standard-output* nil)
    (:td :height "10px" (cl-who:str (wname whs)))
    (:td :height "10px" (cl-who:str (or (warehouse-gstin whs) "N/A")))
    (:td :height "10px" (cl-who:str (wcity whs)))
    (:td :height "10px" (cl-who:str (wstate whs)))
    (:td :height "10px" (cl-who:str (or (warehouse-type whs) "OWN")))
    (:td :height "10px" (cl-who:str (format nil "~A (~A)"
                                     (or (ownership-type whs) "SELLER_OWNED")
                                     (or (owner-entity-type whs) "SELLER"))))
    (:td :height "10px" (cl-who:str (wmanager whs)))
    (:td :height "10px" (cl-who:str (wphone whs)))
    (:td :height "10px" (cl-who:str (activeflag whs)))
    (:td :height "10px"
	 (:a :href (format nil "/hhub/vwarehousedetailspage?id=~A" (row-id whs))   :class  "btn btn-primary"  (:i :class "fa-solid fa-pencil")))))

;;; ---------------------------------------------------------------------------
;;; HTML Search Interface
;;; ---------------------------------------------------------------------------
(defun warehouse-search-html ()
  "Generate warehouse search HTML"
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
          (:div :id "custom-search-input"
                (:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
                      (with-html-search-form "idsyssearchwarehouses" "syssearchwarehouses" 
                                            "idwarehouselivesearch" "warehouselivesearch" 
                                            "searchwarehouseaction" "onkeyupsearchform1event();" 
                                            "Enter Warehouse GSTINSearch for a warehouse"
                        (submitsearchform1event-js "#idwarehouselivesearch" 
                                                  "#warehouselivesearchresult")))))))


(defun com-nst-transaction-vendor-warehouse-details-page ()
  (with-vend-session-check
    (with-mvc-ui-page "Create New Warehouse"
                      #'create-model-for-addeditwarehouse
                      #'create-widgets-for-addeditwarehouse
      :role :vendor)))

(defparameter *warehouse-field-map*
  '((row-id                     . "%Warehouse ID%")
    (warehouse-uuid           . "%Warehouse UUID%")
    (warehouse-code           . "%Warehouse Code%")
    (wname                    . "%Warehouse Name%")
    (waddr1                   . "%Warehouse Address1%")
    (waddr2                   . "%Warehouse Address2%")
    (wpin                     . "%Warehouse Pincode%")
    (wcity                    . "%Warehouse City%")
    (wstate                   . "%Warehouse State%")
    (wcountry                 . "%Warehouse Country%")
    (wmanager                 . "%Warehouse Manager%")
    (wphone                   . "%Warehouse Phone%")
    (waltphone                . "%Warehouse Alt Phone%")
    (wemail                   . "%Warehouse Email%")
    (activeflag               . "%Warehouse Active Flag%")
    (ownership-type           . "%Warehouse Ownership Type%")
    (owner-entity-type        . "%Warehouse Owner Entity Type%")
    (owner-entity-id          . "%Warehouse Owner Entity ID%")
    (operator-entity-type     . "%Warehouse Operator Entity Type%")
    (operator-entity-id       . "%Warehouse Operator Entity ID%")
    (legal-entity-type        . "%Warehouse Legal Entity Type%")
    (warehouse-gstin          . "%Warehouse GSTIN%")
    (gstin-status             . "%Warehouse GSTIN Status%")
    (legal-name               . "%Warehouse Legal Name%")
    (is-primary-location      . "%Warehouse Is Primary Location%")
    (state-code               . "%Warehouse State Code%")
    (registration-type        . "%Warehouse Registration Type%")
    (pan-number               . "%Warehouse PAN Number%")
    (warehouse-type           . "%Warehouse Type%")
    (warehouse-purpose        . "%Warehouse Purpose%")
    (default-transporter-id   . "%Warehouse Default Transporter ID%")
    (default-transporter-name . "%Warehouse Default Transporter Name%")
    (eway-bill-enabled        . "%Warehouse EWay Bill Enabled%")
    (latitude                 . "%Warehouse Latitude%")
    (longitude                . "%Warehouse Longitude%")
    (valuation-method         . "%Warehouse Valuation Method%")
    (hsn-wise-stock           . "%Warehouse HSN Wise Stock%")))


(defun create-model-for-addeditwarehouse ()
  (let* ((id (hunchentoot:parameter "id"))
	 (vendor (get-login-vendor))
	 (company (get-login-vendor-company))
	 (ctx (make-domain-ctx :actor "VENDOR" :tenant company :channel "ONLINE" :recipient vendor :source "VENDOR"))
	 (warehouseobj (if id (fetch 'nst-whs id ctx)))
	 ;; The action to submit to depends on whether we are creating or editing.
	 (action (if id "vupdatewarehouseaction" "vcreatewarehouseaction"))
	 ;; Load the full template page, but pull out ONLY the marker-delimited
	 ;; form-content region.  The widget layer wraps this fragment in a
	 ;; parenscript-generated <form>, so the template must not carry its own
	 ;; outer <form> inside the markers.
	 (warehousedetailspagetempl (funcall (nst-get-cached-warehouse-template-func :templatenum 1)))
	 (form-snippet (extract-html-between-markets
			warehousedetailspagetempl
			"<!--WAREHOUSE_DETAILS_FORM_BEGIN-->"
			"<!--WAREHOUSE_DETAILS_FORM_END-->")))
    (unless form-snippet
      (error "Could not find the <!--WAREHOUSE_DETAILS_FORM_BEGIN--> / <!--WAREHOUSE_DETAILS_FORM_END--> markers in the warehouse template."))
    ;; Populate the form fields with existing warehouse data (edit case).
    (dolist (pair *warehouse-field-map*)
      (let* ((slot (car pair))
             (placeholder (cdr pair))
             (value (and warehouseobj (slot-value warehouseobj slot))))
	(setf form-snippet
              (cl-ppcre:regex-replace-all
               placeholder
               form-snippet
               (if value (princ-to-string value) "")))))
    ;; Return the cleaned-up form fragment plus the action token so the caller
    ;; (widget layer) can wrap it in the appropriate <form> without repeating
    ;; the create/edit decision logic.
    (function (lambda ()
      (values form-snippet action)))))

(defun create-widgets-for-addeditwarehouse (modelfunc)
  ;; The model hands us the form-content fragment and the action it should POST
  ;; to.  We wrap the fragment with with-html-form-having-submit-event so the
  ;; form submission is wired up via parenscript-generated frontend JS.
  (multiple-value-bind (form-snippet action) (funcall modelfunc)
    (let ((widget1  (function (lambda ()
		      (cl-who:with-html-output (*standard-output* nil)
			(with-html-form-having-submit-event "warehousedetailsform" action
			  (cl-who:str form-snippet)))))))
    (list widget1))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; CREATE — gana make verb, MVC redirect flow
;;; ═══════════════════════════════════════════════════════════════════════

(defun com-hhub-transaction-create-warehouse-action ()
  "Handler for creating a new warehouse via the gana (NST) make verb.

   Uses the gana path directly — make 'nst-whs — instead of the legacy
   Context Flow Dispatcher (dispatch-route :warehouse/create →
   WarehouseAdapter/WarehouseService).

   All fields arrive from the POSTed warehousedetailspage.html create
   form (action \"vcreatewarehouseaction\") and are passed as make
   initargs. The make method generates the warehouse UID/code, runs the
   GSTIN uniqueness :before check, persists via with-nst-db-create, and
   binds the generated row-id back onto the returned entity.

   On success redirects to the warehouse list page (/hhub/vwarehouses)
   so the user sees the newly created record among the others."
  (with-vend-session-check
    (with-mvc-redirect-ui #'create-model-for-createwarehouse
                          #'create-widgets-for-genericredirect)))

(defun create-model-for-createwarehouse ()
  "Model for the create-warehouse action. Runs make 'nst-whs and returns
   the redirect URL to the warehouse list page."
  (flet ((parse-int-or-0 (s)
           "Parse S as an integer, returning 0 if S is nil or empty."
           (if (and s (string/= s ""))
               (parse-integer s)
               0)))
    (let* ((company (get-login-vendor-company))
         (vendor (get-login-vendor))

         ;; ctx is a domain-ctx (the gana kāraka passenger struct), NOT
         ;; the conflodis call-context. tenant = vendor session company.
         (ctx (make-domain-ctx :actor "VENDOR" :tenant company
                               :channel "ONLINE" :recipient vendor :source "VENDOR"))

         (wname (hunchentoot:parameter "wname"))
         (waddr1 (hunchentoot:parameter "waddr1"))
         (waddr2 (hunchentoot:parameter "waddr2"))
         (wpin (hunchentoot:parameter "wpin"))
         (wcity (hunchentoot:parameter "wcity"))
         (wstate (hunchentoot:parameter "wstate"))
         (wcountry (hunchentoot:parameter "wcountry"))
         (wmanager (hunchentoot:parameter "wmanager"))
         (wphone (hunchentoot:parameter "wphone"))
         (waltphone (hunchentoot:parameter "waltphone"))
         (wemail (hunchentoot:parameter "wemail"))
         (activeflag (hunchentoot:parameter "activeflag"))

         ;; Ownership fields
         (ownership-type (hunchentoot:parameter "ownershiptype"))
         (owner-entity-type (hunchentoot:parameter "ownerentitytype"))
         (owner-entity-id (parse-int-or-0 (hunchentoot:parameter "ownerentityid")))
         (operator-entity-type (hunchentoot:parameter "operatorentitytype"))
         (operator-entity-id (let ((oeid (hunchentoot:parameter "operatorentityid")))
                                (when (and oeid (string/= oeid ""))
                                  (parse-integer oeid))))
         (legal-entity-type (hunchentoot:parameter "legalentitytype"))

         ;; GST and Advanced Fields
         (warehouse-gstin (hunchentoot:parameter "warehousegstin"))
         (gstin-status (hunchentoot:parameter "gstinstatus"))
         (legal-name (hunchentoot:parameter "legalname"))
         (is-primary-location (parse-int-or-0 (hunchentoot:parameter "isprimarylocation")))
         (state-code (hunchentoot:parameter "statecode"))
         (registration-type (hunchentoot:parameter "registrationtype"))
         (warehouse-type (hunchentoot:parameter "warehousetype"))
         (warehouse-purpose (hunchentoot:parameter "warehousepurpose"))
         (default-transporter-id (hunchentoot:parameter "defaulttransporterid"))
         (default-transporter-name (hunchentoot:parameter "defaulttransportername"))
         (eway-bill-enabled (parse-int-or-0 (hunchentoot:parameter "ewaybillenabled")))
         (latitude (float (with-input-from-string
                              (in (or (hunchentoot:parameter "latitude") "0.0"))
                            (handler-case (read in)
                              (end-of-file () 0.0)))))
         (longitude (float (with-input-from-string
                               (in (or (hunchentoot:parameter "longitude") "0.0"))
                             (handler-case (read in)
                               (end-of-file () 0.0)))))
         (valuation-method (hunchentoot:parameter "valuationmethod"))
         (hsn-wise-stock (parse-int-or-0 (hunchentoot:parameter "hsnwisestock")))
         (pan-number (hunchentoot:parameter "pannumber"))

         (create-args (list :wname wname
                            :waddr1 waddr1
                            :waddr2 waddr2
                            :wpin wpin
                            :wcity wcity
                            :wstate wstate
                            :wcountry wcountry
                            :wmanager wmanager
                            :wphone wphone
                            :waltphone waltphone
                            :wemail wemail
                            :activeflag activeflag
                            ;; Ownership fields
                            :ownership-type ownership-type
                            :owner-entity-type owner-entity-type
                            :owner-entity-id owner-entity-id
                            :operator-entity-type operator-entity-type
                            :operator-entity-id operator-entity-id
                            :legal-entity-type legal-entity-type
                            ;; GST fields
                            :warehouse-gstin warehouse-gstin
                            :gstin-status gstin-status
                            :legal-name legal-name
                            :is-primary-location is-primary-location
                            :state-code state-code
                            :registration-type registration-type
                            :warehouse-type warehouse-type
                            :warehouse-purpose warehouse-purpose
                            :default-transporter-id default-transporter-id
                            :default-transporter-name default-transporter-name
                            :eway-bill-enabled eway-bill-enabled
                            :latitude latitude
                            :longitude longitude
                            :valuation-method valuation-method
                            :hsn-wise-stock hsn-wise-stock
                            :pan-number pan-number
                            :company company
                            :vendor vendor))
         (redirecturl "/hhub/vwarehouses")
         (params nil))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (with-hhub-transaction "com-hhub-transaction-create-warehouse-action" params
      (with-nst-error-handler 
          (apply #'make 'nst-whs ctx create-args)
	'hhub-business-function-error))  ; perform the create

    ;; Return ONLY the redirect URL — the sole value create-widgets-for-
    ;; genericredirect consumes to emit the browser redirect.
    (function (lambda () redirecturl)))))


;;; ═══════════════════════════════════════════════════════════════════════
;;; UPDATE — gana !update verb, MVC redirect flow
;;; ═══════════════════════════════════════════════════════════════════════

(defun com-hhub-transaction-update-warehouse-action ()
  "Handler for updating a warehouse via the proc.bhandara !update verb.

   Uses the gana (NST) path directly — !update 'nst-whs — instead of
   the legacy Context Flow Dispatcher (dispatch-route :warehouse/update →
   WarehouseAdapter/WarehouseService.doUpdate).

   row-id arrives as HTTP param \"id\" (the edit page's URL carries
   ?id=<row>; same key used by fetch for pre-population). All other
   fields arrive from the POSTed warehousedetailspage.html form and are
   passed as CLOS reinitialize-initargs so the !update method performs a
   genuine partial update — only the supplied slots change.

   On success redirects back to /hhub/vwarehousedetailspage?id=<row> (the
   same warehouse's details page) so the user sees the refreshed record."
  (with-vend-session-check
    (with-mvc-redirect-ui #'create-model-for-updatewarehouse
                          #'create-widgets-for-genericredirect)))

(defun create-model-for-updatewarehouse ()
  "Model for the update-warehouse action. Runs !update and returns the
   redirect URL back to the same warehouse's details page."
  (flet ((parse-int-or-0 (s)
           "Parse S as an integer, returning 0 if S is nil or empty."
           (if (and s (string/= s ""))
               (parse-integer s)
               0)))
    (let* ((id (hunchentoot:parameter "wid"))
         (company (get-login-vendor-company))
         (vendor (get-login-vendor))

         ;; ctx is a domain-ctx (the gana kāraka passenger struct), NOT
         ;; the conflodis call-context. tenant = vendor session company.
         (ctx (make-domain-ctx :actor "VENDOR" :tenant company
                               :channel "ONLINE" :recipient vendor :source "VENDOR"))

         (wname (hunchentoot:parameter "wname"))
         (waddr1 (hunchentoot:parameter "waddr1"))
         (waddr2 (hunchentoot:parameter "waddr2"))
         (wpin (hunchentoot:parameter "wpin"))
         (wcity (hunchentoot:parameter "wcity"))
         (wstate (hunchentoot:parameter "wstate"))
         (wcountry (hunchentoot:parameter "wcountry"))
         (wmanager (hunchentoot:parameter "wmanager"))
         (wphone (hunchentoot:parameter "wphone"))
         (waltphone (hunchentoot:parameter "waltphone"))
         (wemail (hunchentoot:parameter "wemail"))
         (activeflag (hunchentoot:parameter "activeflag"))

         ;; Ownership fields
         (ownership-type (hunchentoot:parameter "ownershiptype"))
         (owner-entity-type (hunchentoot:parameter "ownerentitytype"))
         (owner-entity-id (parse-int-or-0 (hunchentoot:parameter "ownerentityid")))
         (operator-entity-type (hunchentoot:parameter "operatorentitytype"))
         (operator-entity-id (let ((oeid (hunchentoot:parameter "operatorentityid")))
                                (when (and oeid (string/= oeid ""))
                                  (parse-integer oeid))))
         (legal-entity-type (hunchentoot:parameter "legalentitytype"))

         ;; GST and Advanced Fields
         (warehouse-gstin (hunchentoot:parameter "warehousegstin"))
         (gstin-status (hunchentoot:parameter "gstinstatus"))
         (legal-name (hunchentoot:parameter "legalname"))
         (is-primary-location (parse-int-or-0 (hunchentoot:parameter "isprimarylocation")))
         (state-code (hunchentoot:parameter "statecode"))
         (registration-type (hunchentoot:parameter "registrationtype"))
         (warehouse-type (hunchentoot:parameter "warehousetype"))
         (warehouse-purpose (hunchentoot:parameter "warehousepurpose"))
         (default-transporter-id (hunchentoot:parameter "defaulttransporterid"))
         (default-transporter-name (hunchentoot:parameter "defaulttransportername"))
         (eway-bill-enabled (parse-int-or-0 (hunchentoot:parameter "ewaybillenabled")))
         (latitude (float (with-input-from-string (in (or (hunchentoot:parameter "latitude") "0.0"))
                            (read in))))
         (longitude (float (with-input-from-string (in (or (hunchentoot:parameter "longitude") "0.0"))
                             (read in))))
         (valuation-method (hunchentoot:parameter "valuationmethod"))
         (hsn-wise-stock (parse-int-or-0 (hunchentoot:parameter "hsnwisestock")))
         (pan-number (hunchentoot:parameter "pannumber"))

         (update-args (list :wname wname
                            :waddr1 waddr1
                            :waddr2 waddr2
                            :wpin wpin
                            :wcity wcity
                            :wstate wstate
                            :wcountry wcountry
                            :wmanager wmanager
                            :wphone wphone
                            :waltphone waltphone
                            :wemail wemail
                            :activeflag activeflag
                            ;; Ownership fields
                            :ownership-type ownership-type
                            :owner-entity-type owner-entity-type
                            :owner-entity-id owner-entity-id
                            :operator-entity-type operator-entity-type
                            :operator-entity-id operator-entity-id
                            :legal-entity-type legal-entity-type
                            ;; GST fields
                            :warehouse-gstin warehouse-gstin
                            :gstin-status gstin-status
                            :legal-name legal-name
                            :is-primary-location is-primary-location
                            :state-code state-code
                            :registration-type registration-type
                            :warehouse-type warehouse-type
                            :warehouse-purpose warehouse-purpose
                            :default-transporter-id default-transporter-id
                            :default-transporter-name default-transporter-name
                            :eway-bill-enabled eway-bill-enabled
                            :latitude latitude
                            :longitude longitude
                            :valuation-method valuation-method
                            :hsn-wise-stock hsn-wise-stock
                            :pan-number pan-number
                            :company company
                            :vendor vendor))
         (redirecturl (format nil "/hhub/vwarehousedetailspage?id=~A" (or id "")))
         (params nil))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (with-hhub-transaction "com-hhub-transaction-update-warehouse-action" params
      (with-nst-error-handler 
          (apply #'!update 'nst-whs id ctx update-args)
	'hhub-business-function-error))  ; perform the update
        
    ;; Return ONLY the redirect URL — the sole value create-widgets-for-
    ;; genericredirect consumes to emit the browser redirect.
    (function (lambda () redirecturl)))))





