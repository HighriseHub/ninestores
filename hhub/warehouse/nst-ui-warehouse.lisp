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
  "Direct enumerate call — no request->dispatch, no nst-request-model.
   This page has no external input to filter through a boundary
   object; domain-ctx from session is the only input, and enumerate
   is the only verb. request->dispatch stays available for the day
   a filtered/searchable view needs it — not manufactured now on
   spec. enumerate's :U/:C error signaling still uncaught — open item,
   unchanged."
  (let* ((vendor-name (get-login-vendor-name))
	 (company (get-login-vendor-company))
         (ctx (make-domain-ctx :actor "VENDOR" :tenant company :channel "ONLINE" :recipient "VENDOR" :source "VENDOR"))
         (warehouselist (enumerate 'nst-whs ctx))
         (htmlview (make-instance 'nst-whs-list-view))
	 (params nil))
    (logiamhere (format nil "there are ~A warehouses" (length warehouselist)))
    (setf params (acons "uri" (hunchentoot:request-uri*)  params))
    (setf params (acons "company" company params))
    (with-hhub-transaction "com-hhub-transaction-readall-warehouse" params
      (function (lambda () (values warehouselist htmlview vendor-name))))))

(defun create-widgets-for-showwarehouses (modelfunc)
  "Unchanged shape — only the type of what's inside warehouselist
   changed, from WarehouseViewModel to nst-whs entities directly."
  (multiple-value-bind (warehouselist htmlview username) (funcall modelfunc)
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
					 (:a :href (format nil "/hhub/vwarehousedetailspage")   :class "btn btn-primary" "Create Warehouse"))
				   (:div :class "col-xs-6" :align "right"
                                         (:span :class "badge"
						(cl-who:str (format nil "~A" (length warehouselist))))))
                             (:hr)
                             (cl-who:str (RenderListViewHTML htmlview warehouselist))))))))
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
;;; HTML Rendering
;;; ---------------------------------------------------------------------------
(defmethod RenderListViewHTMLold ((htmlview WarehouseHTMLView) viewmodellist)
  "Render warehouse list as HTML table with ownership info"
  (when viewmodellist
    (display-as-table (list "Name" "GSTIN" "City" "State" "Type" "Ownership" 
                           "Manager" "Phone" "Active" "Actions") 
                     viewmodellist 
                     'display-warehouse-row)))


(defmethod RenderListViewHTML ((htmlview nst-whs-list-view) warehouselist)
  (when warehouselist
    (display-as-table (list "Name" "GSTIN" "City" "State" "Type" "Ownership"
                             "Manager" "Phone" "Active" "Actions")
                       warehouselist 'display-warehouse-row)))

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
(defmethod render-html ((responses list) (ctx domain-ctx))
  (when responses
    (display-as-table (list "Name" "GSTIN" "City" "State" "Type" "Ownership"
                             "Manager" "Phone" "Active" "Actions")
                       responses 'display-warehouse-row)))

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
    (:td :height "10px" (cl-who:str (deleted-state whs)))
    (:td :height "10px"
	 (:a :href (format nil "/hhub/vwarehousedetailspage?id=~A" (row-id whs))   :class  "btn btn-primary"  (:i :class "fa-solid fa-pencil")))))


