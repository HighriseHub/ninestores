;; -*- mode: common-lisp; coding: utf-8 -*-
;; nst-ui-aientity.lisp
;; UI layer + Context Flow Dispatcher routes for DOD_PROCURE_ENTITY.
;; ENTITY_TYPE allowed values must be governed — arbitrary strings here
;; risk breaking downstream AI agents that key off ENTITY_TYPE.
(in-package :nstores)

;;; ─── HTML Helpers ────────────────────────────────────────────────────────────

(defun aientity-search-html ()
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
      (:div :id "custom-search-input"
        (:div :class "input-group col-xs-12 col-sm-6 col-md-6 col-lg-6"
          (with-html-search-form
            "idaientitysearch" "aientitysearch"
            "idaientitylivesearch" "aientitylivesearch"
            "searchaientityaction"
            "onkeyupsearchform1event();"
            "Search by Entity Type"))))))

(defmethod RenderListViewHTML ((view AIEntityHTMLView) vm-list)
  (when vm-list
    (display-as-table
      (list "Entity ID" "Entity Type" "Created")
      vm-list 'display-aientity-row)))

(defun display-aientity-row (vm &rest args)
  (declare (ignore args))
  (with-slots (entityid entitytype created) vm
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" (cl-who:str entityid))
      (:td :height "10px" (cl-who:str entitytype))
      (:td :height "10px" (cl-who:str created))
      (:td :height "10px"
        (:button :type "button" :class "btn btn-sm btn-primary"
                 :data-toggle "modal"
                 :data-target (format nil "#edit-aientity-~A" entityid)
                 (:i :class "fa-solid fa-pencil"))
        (modal-dialog
          (format nil "edit-aientity-~A" entityid)
          "Edit AI Entity"
          (com-hhub-transaction-create-aientity-dialog vm))))))

(defun com-hhub-transaction-create-aientity-dialog (&optional vm)
  (let ((eid  (when vm (slot-value vm 'entityid)))
        (etype (when vm (slot-value vm 'entitytype))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row"
        (:div :class "col-xs-12"
          (with-html-form
            (format nil "form-aientity~A" eid)
            (if vm "updateaientityaction" "createaientityaction")
            (:div :class "form-group"
              (:input :class "form-control" :name "entityid"
                      :value eid :placeholder "Entity ID (e.g. VEND-001)"
                      :maxlength "100" :type "text"))
            (:div :class "form-group"
              ;; LEGAL NOTE: Restrict entitytype to a governed enum in production.
              (:select :class "form-control" :name "entitytype"
                (:option :value "VENDOR"   "VENDOR")
                (:option :value "CUSTOMER" "CUSTOMER")
                (:option :value "PRODUCT"  "PRODUCT")
                (:option :value "ORDER"    "ORDER")))
            (:div :class "form-group"
              (:button :class "btn btn-primary btn-block"
                       :type "submit" "Submit"))))))))

;;; ─── MVC: Model Creators ─────────────────────────────────────────────────────

(defun create-model-for-showaientities ()
  (let* ((company   (get-login-company))
         (presenter (make-instance 'AIEntityPresenter))
         (rm        (make-instance 'AIEntityRequestModel :company company))
         (adapter   (make-instance 'AIEntityAdapter))
         (objs      (processreadallrequest adapter rm))
         (rms       (processresponselist adapter objs))
         (vms       (CreateAllViewModel presenter rms))
         (view      (make-instance 'AIEntityHTMLView))
         (params    nil))
    (setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (with-hhub-transaction "showaientities" params
      (function (lambda () (values vms view))))))

(defun create-model-for-createaientity ()
  (let* ((eid     (hunchentoot:parameter "entityid"))
         (etype   (hunchentoot:parameter "entitytype"))
         (company (get-login-company))
         (rm      (make-instance 'AIEntityRequestModel
                                 :entityid eid :entitytype etype
                                 :company company))
         (adapter (make-instance 'AIEntityAdapter))
         (redirect "/hhub/aientities")
         (params nil))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (with-hhub-transaction "createaientity" params
      (handler-case
        (let ((obj (ProcessCreateRequest adapter rm)))
          (function (lambda () (values redirect obj))))
        (error (c)
          (error 'hhub-business-function-error
                 :errstring (format t "~A" c)))))))

(defun create-model-for-updateaientity ()
  (let* ((eid     (hunchentoot:parameter "entityid"))
         (etype   (hunchentoot:parameter "entitytype"))
         (company (get-login-company))
         (rm      (make-instance 'AIEntityRequestModel
                                 :entityid eid :entitytype etype
                                 :company company))
         (adapter (make-instance 'AIEntityAdapter))
         (redirect "/hhub/aientities")
         (params nil))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (with-hhub-transaction "updateaientity" params
      (handler-case
        (let ((obj (ProcessUpdateRequest adapter rm)))
          (function (lambda () (values redirect obj))))
        (error (c)
          (error 'hhub-business-function-error
                 :errstring (format t "~A" c)))))))

;;; ─── MVC: Widget Creators ────────────────────────────────────────────────────

(defun create-widgets-for-showaientities (modelfunc)
  (multiple-value-bind (vms view) (funcall modelfunc)
    (list
      (function (lambda ()
        (cl-who:with-html-output (*standard-output* nil)
          (:h3 "AI Procurement Entities")
          (aientity-search-html)
          (:hr))))
      (function (lambda ()
        (cl-who:with-html-output (*standard-output* nil)
          (:div :id "aientitylivesearchresult"
            (:div :class "row"
              (:div :class "col-xs-6"
                (:button :type "button" :class "btn btn-primary"
                         :data-toggle "modal" :data-target "#add-aientity-modal"
                         "Add Entity")
                (modal-dialog "add-aientity-modal" "Add AI Entity"
                              (com-hhub-transaction-create-aientity-dialog)))
              (:div :class "col-xs-6" :align "right"
                (:span :class "badge"
                       (cl-who:str (length vms)))))
            (:hr)
            (cl-who:str (RenderListViewHTML view vms)))))))))

;;; ─── HTTP Action Handlers ────────────────────────────────────────────────────

(defun com-hhub-transaction-aientities-page ()
  (with-opr-session-check
    (with-mvc-ui-page "AI Entities"
      #'create-model-for-showaientities
      #'create-widgets-for-showaientities
      :role :superadmin)))

(defun com-hhub-transaction-create-aientity-action ()
  (with-opr-session-check
    (let ((url (with-mvc-redirect-ui
                 #'create-model-for-createaientity
                 #'create-widgets-for-genericredirect)))
      (format nil "~A" url))))

(defun com-hhub-transaction-update-aientity-action ()
  (with-opr-session-check
    (let ((url (with-mvc-redirect-ui
                 #'create-model-for-updateaientity
                 #'create-widgets-for-genericredirect)))
      (format nil "~A" url))))

;;; ─── Context Flow Dispatcher: 5 Outbound Routes ─────────────────────────────
;; LEGAL NOTE: :warehouse/delete is restricted to :superadmin.
;; Deleting an entity orphans all ENTITY_FACT rows — cascade policy required.

(register-outbound-route
  :aientity/create
  :crud-op :create
  :description "Create a new Procurement Entity anchor record"
  :requestmodel-class   'AIEntityRequestModel
  :businessobject-class 'AIEntity
  :adapter-class        'AIEntityAdapter
  :presenter-class      'AIEntityPresenter
  :view-classes         '((json . AIEntityJSONView) (html . AIEntityHTMLView))
  :required-roles       '(admin superadmin)
  :audit-level          :full
  :tags                 '(aientity procurement v1 create))

(register-outbound-route
  :aientity/read
  :crud-op :read
  :description "Read a single Procurement Entity by entity-id"
  :requestmodel-class   'AIEntityRequestModel
  :businessobject-class 'AIEntity
  :adapter-class        'AIEntityAdapter
  :presenter-class      'AIEntityPresenter
  :view-classes         '((json . AIEntityJSONView) (html . AIEntityHTMLView))
  :required-roles       '(admin superadmin vendor support)
  :audit-level          :minimal
  :tags                 '(aientity procurement v1 read))

(register-outbound-route
  :aientity/readall
  :crud-op :list
  :description "Read all Procurement Entities for a tenant"
  :requestmodel-class   'AIEntityRequestModel
  :businessobject-class 'AIEntity
  :adapter-class        'AIEntityAdapter
  :presenter-class      'AIEntityPresenter
  :view-classes         '((json . AIEntityJSONView) (html . AIEntityHTMLView))
  :required-roles       '(admin superadmin)
  :audit-level          :minimal
  :tags                 '(aientity procurement v1 list))

(register-outbound-route
  :aientity/update
  :crud-op :update
  :description "Update entity-type of an existing Procurement Entity"
  :requestmodel-class   'AIEntityRequestModel
  :businessobject-class 'AIEntity
  :adapter-class        'AIEntityAdapter
  :presenter-class      'AIEntityPresenter
  :view-classes         '((json . AIEntityJSONView) (html . AIEntityHTMLView))
  :required-roles       '(admin superadmin)
  :audit-level          :full
  :tags                 '(aientity procurement v1 update))

(register-outbound-route
  :aientity/delete
  :crud-op :delete
  :description "Hard delete a Procurement Entity — MUST cascade ENTITY_FACT first"
  :requestmodel-class   'AIEntityRequestModel
  :businessobject-class 'AIEntity
  :adapter-class        'AIEntityAdapter
  :presenter-class      'AIEntityPresenter
  :view-classes         '((json . AIEntityJSONView))
  :required-roles       '(superadmin)
  :audit-level          :full
  :tags                 '(aientity procurement v1 delete destructive))
