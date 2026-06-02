;;; nst-ui-aientfact.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
;; nst-ui-aientfact.lisp
;; UI layer + Context Flow Dispatcher routes for DOD_PROCURE_ENTITY_FACT.
;;
;; UI PHILOSOPHY FOR THIS TABLE:
;;   Facts are primarily written by AI agents, not humans.
;;   The human-facing UI is read-heavy: inspect and audit what agents asserted.
;;   HUMAN_ENTERED write path exists for operator corrections only.
;;   Expose confidence and source-type prominently — agents need interpretability.
(in-package :nstores)

;;; ─── Rendering helpers ───────────────────────────────────────────────────────

(defun %confidence-badge-class (confidence)
  "Map confidence to Bootstrap badge colour for visual cue."
  (cond ((>= confidence 0.9) "badge-success")
        ((>= confidence 0.7) "badge-warning")
        (t                   "badge-danger")))

(defun aientfact-search-html (entity-id)
  "Render search bar scoped to a specific entity-id."
  (cl-who:with-html-output (*standard-output* nil)
    (:div :class "row"
      (:div :id "custom-search-input"
        (:div :class "input-group col-xs-12 col-sm-8 col-md-8"
          (with-html-search-form
            "idaientfactsearch" "aientfactsearch"
            "idaientfactlivesearch" "aientfactlivesearch"
            "searchaientfactaction"
            "onkeyupsearchform1event();"
            "Search fact key namespace (e.g. com.xyz.vendor.identity)")
          (:input :type "hidden" :name "entityid" :value entity-id))))))

(defmethod RenderListViewHTML ((view AIEntityFactHTMLView) vm-list)
  (when vm-list
    (display-as-table
      (list "Fact Key" "Value" "Type" "Source" "Confidence"
            "Valid From" "Valid To" "Asserted By")
      vm-list 'display-aientfact-row)))

(defun display-aientfact-row (vm &rest args)
  (declare (ignore args))
  (with-slots (rowid factkey factval facttype sourcetype
               confidence validfrom validto assertedby) vm
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" (:code (cl-who:str factkey)))
      (:td :height "10px" (cl-who:str factval))
      (:td :height "10px" (:span :class "label label-default" (cl-who:str facttype)))
      (:td :height "10px" (cl-who:str sourcetype))
      (:td :height "10px"
        (:span :class (format nil "badge ~A"
                              (%confidence-badge-class (or confidence 0.0)))
               (cl-who:str (format nil "~,2F" (or confidence 0.0)))))
      (:td :height "10px" (cl-who:str (or validfrom "")))
      (:td :height "10px"
        (if validto
            (cl-who:htm (:span :class "text-muted" (cl-who:str validto)))
            (cl-who:htm (:span :class "text-success" "LIVE"))))
      (:td :height "10px" (cl-who:str (or assertedby "—")))
      (:td :height "10px"
        ;; Only show edit for HUMAN_ENTERED source or superadmin
        (:button :type "button" :class "btn btn-xs btn-primary"
                 :data-toggle "modal"
                 :data-target (format nil "#edit-fact-~A" rowid)
                 (:i :class "fa-solid fa-pencil"))
        (modal-dialog
          (format nil "edit-fact-~A" rowid)
          "Edit / Correct Fact"
          (com-hhub-transaction-create-aientfact-dialog vm))))))

(defun com-hhub-transaction-create-aientfact-dialog (&optional vm)
  "Form for human-entered fact creation or correction."
  (let ((eid   (when vm (slot-value vm 'entityid)))
        (fkey  (when vm (slot-value vm 'factkey)))
        (fval  (when vm (slot-value vm 'factval)))
        (ftype (when vm (slot-value vm 'facttype))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row"
        (:div :class "col-xs-12"
          (with-html-form
            (format nil "form-aientfact~A" (or eid "new"))
            (if vm "updateaientfactaction" "createaientfactaction")
            (:input :type "hidden" :name "entityid" :value eid)
            (:div :class "form-group"
              (:label "Fact Key (namespace path)")
              (:input :class "form-control" :name "factkey"
                      :value fkey :maxlength "200" :type "text"
                      :placeholder "com.xyz.vendor.identity.email"))
            (:div :class "form-group"
              (:label "Fact Value")
              (:textarea :class "form-control" :name "factval"
                         :rows "3" :placeholder "Value"
                         (cl-who:str (or fval ""))))
            (:div :class "form-group"
              (:label "Fact Type")
              (:select :class "form-control" :name "facttype"
                (dolist (ft *aientfact-fact-types*)
                  (cl-who:htm
                    (:option :value ft
                             :selected (when (string= ft (or ftype "string")) "selected")
                             (cl-who:str ft))))))
            (:div :class "form-group"
              (:label "Confidence (0.4 – 1.0)")
              (:input :class "form-control" :name "confidence"
                      :type "number" :min "0.4" :max "1.0" :step "0.01"
                      :value "1.0"))
            (:input :type "hidden" :name "sourcetype" :value "HUMAN_ENTERED")
            (:input :type "hidden" :name "assertedby"
                    :value (get-login-user-name))
            (:div :class "form-group"
              (:button :class "btn btn-primary btn-block"
                       :type "submit" "Submit"))))))))

;;; ─── MVC: Model Creators ─────────────────────────────────────────────────────

(defun create-model-for-showaientfacts (entity-id)
  "Load all current live facts for a given entity-id."
  (let* ((company   (get-login-company))
         (presenter (make-instance 'AIEntityFactPresenter))
         (rm        (make-instance 'AIEntityFactRequestModel
                                   :entityid entity-id :company company))
         (adapter   (make-instance 'AIEntityFactAdapter))
         (objs      (processreadallrequest adapter rm))
         (rms       (processresponselist adapter objs))
         (vms       (CreateAllViewModel presenter rms))
         (view      (make-instance 'AIEntityFactHTMLView))
         (params    nil))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (setf params (acons "username" (get-login-user-name) params))
    (with-hhub-transaction "showaientfacts" params
      (function (lambda () (values vms view entity-id))))))

(defun create-model-for-createaientfact ()
  (let* ((eid        (hunchentoot:parameter "entityid"))
         (fkey       (hunchentoot:parameter "factkey"))
         (fval       (hunchentoot:parameter "factval"))
         (ftype      (hunchentoot:parameter "facttype"))
         (conf       (float (with-input-from-string (s (hunchentoot:parameter "confidence"))
                              (read s))))
         (assertedby (hunchentoot:parameter "assertedby"))
         (company    (get-login-company))
         (rm         (make-instance 'AIEntityFactRequestModel
                                    :entityid   eid
                                    :factkey    fkey
                                    :factval    fval
                                    :facttype   ftype
                                    :sourcetype "HUMAN_ENTERED"
                                    :confidence conf
                                    :assertedby assertedby
                                    :company    company))
         (adapter    (make-instance 'AIEntityFactAdapter))
         (redirect   (format nil "/hhub/aientfacts?entityid=~A" eid))
         (params     nil))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (with-hhub-transaction "createaientfact" params
      (handler-case
        (let ((obj (ProcessCreateRequest adapter rm)))
          (function (lambda () (values redirect obj))))
        (error (c)
          (error 'hhub-business-function-error
                 :errstring (format t "~A" c)))))))

(defun create-model-for-updateaientfact ()
  "Update = expire + insert new. Reads same params as create."
  (let* ((eid        (hunchentoot:parameter "entityid"))
         (fkey       (hunchentoot:parameter "factkey"))
         (fval       (hunchentoot:parameter "factval"))
         (ftype      (hunchentoot:parameter "facttype"))
         (conf       (float (with-input-from-string (s (hunchentoot:parameter "confidence"))
                              (read s))))
         (assertedby (hunchentoot:parameter "assertedby"))
         (company    (get-login-company))
         (rm         (make-instance 'AIEntityFactRequestModel
                                    :entityid   eid
                                    :factkey    fkey
                                    :factval    fval
                                    :facttype   ftype
                                    :sourcetype "HUMAN_ENTERED"
                                    :confidence conf
                                    :assertedby assertedby
                                    :company    company))
         (adapter    (make-instance 'AIEntityFactAdapter))
         (redirect   (format nil "/hhub/aientfacts?entityid=~A" eid))
         (params     nil))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (with-hhub-transaction "updateaientfact" params
      (handler-case
        (let ((obj (ProcessUpdateRequest adapter rm)))
          (function (lambda () (values redirect obj))))
        (error (c)
          (error 'hhub-business-function-error
                 :errstring (format t "~A" c)))))))

;;; ─── MVC: Widget Creators ────────────────────────────────────────────────────

(defun create-widgets-for-showaientfacts (modelfunc)
  (multiple-value-bind (vms view entity-id) (funcall modelfunc)
    (list
      (function (lambda ()
        (cl-who:with-html-output (*standard-output* nil)
          (:h3 (cl-who:str (format nil "Facts: ~A" entity-id)))
          (aientfact-search-html entity-id)
          (:hr))))
      (function (lambda ()
        (cl-who:with-html-output (*standard-output* nil)
          (:div :id "aientfactlivesearchresult"
            (:div :class "row"
              (:div :class "col-xs-6"
                (:button :type "button" :class "btn btn-primary"
                         :data-toggle "modal"
                         :data-target "#add-aientfact-modal"
                         "Add Fact (Human Entry)")
                (modal-dialog "add-aientfact-modal"
                              "Add Fact (HUMAN_ENTERED)"
                              (com-hhub-transaction-create-aientfact-dialog)))
              (:div :class "col-xs-6" :align "right"
                (:span :class "badge" (cl-who:str (length vms)))
                " live facts"))
            (:hr)
            (cl-who:str (RenderListViewHTML view vms)))))))))

;;; ─── HTTP Action Handlers ────────────────────────────────────────────────────

(defun com-hhub-transaction-aientfacts-page ()
  (with-opr-session-check
    (let* ((entity-id (hunchentoot:parameter "entityid"))
           (modelfunc (create-model-for-showaientfacts entity-id)))
      (with-mvc-ui-page "Entity Facts"
        modelfunc
        #'create-widgets-for-showaientfacts
        :role :admin))))

(defun com-hhub-transaction-create-aientfact-action ()
  (with-opr-session-check
    (let ((url (with-mvc-redirect-ui
                 #'create-model-for-createaientfact
                 #'create-widgets-for-genericredirect)))
      (format nil "~A" url))))

(defun com-hhub-transaction-update-aientfact-action ()
  (with-opr-session-check
    (let ((url (with-mvc-redirect-ui
                 #'create-model-for-updateaientfact
                 #'create-widgets-for-genericredirect)))
      (format nil "~A" url))))

;;; ─── Context Flow Dispatcher: 5 Outbound Routes ─────────────────────────────
;;
;; SECURITY NOTES:
;;   :aientfact/create — AI agents and human operators. Requires sourcetype.
;;   :aientfact/delete — Soft-expiry only. Restricted to superadmin + ai-agent.
;;   :aientfact/readall history variant — legal/audit role only.

(register-outbound-route
  :aientfact/create
  :crud-op :create
  :description "Assert a new versioned fact for a Procurement Entity"
  :requestmodel-class   'AIEntityFactRequestModel
  :businessobject-class 'AIEntityFact
  :adapter-class        'AIEntityFactAdapter
  :presenter-class      'AIEntityFactPresenter
  :view-classes         '((json . AIEntityFactJSONView)
                          (html . AIEntityFactHTMLView))
  :required-roles       '(admin superadmin ai-agent)
  :audit-level          :full
  :tags                 '(aientfact eav procurement v1 create immutable))

(register-outbound-route
  :aientfact/read
  :crud-op :read
  :description "Read the current live fact for entity-id + fact-key"
  :requestmodel-class   'AIEntityFactRequestModel
  :businessobject-class 'AIEntityFact
  :adapter-class        'AIEntityFactAdapter
  :presenter-class      'AIEntityFactPresenter
  :view-classes         '((json . AIEntityFactJSONView)
                          (html . AIEntityFactHTMLView))
  :required-roles       '(admin superadmin ai-agent vendor support)
  :audit-level          :minimal
  :tags                 '(aientfact eav procurement v1 read))

(register-outbound-route
  :aientfact/readall
  :crud-op :list
  :description "Read all current live facts for an entity (or full history)"
  :requestmodel-class   'AIEntityFactRequestModel
  :businessobject-class 'AIEntityFact
  :adapter-class        'AIEntityFactAdapter
  :presenter-class      'AIEntityFactPresenter
  :view-classes         '((json . AIEntityFactJSONView)
                          (html . AIEntityFactHTMLView))
  :required-roles       '(admin superadmin ai-agent audit)
  :audit-level          :minimal
  :tags                 '(aientfact eav procurement v1 list audit))

(register-outbound-route
  :aientfact/update
  :crud-op :update
  :description "Expire current fact + insert new version (immutable history)"
  :requestmodel-class   'AIEntityFactRequestModel
  :businessobject-class 'AIEntityFact
  :adapter-class        'AIEntityFactAdapter
  :presenter-class      'AIEntityFactPresenter
  :view-classes         '((json . AIEntityFactJSONView)
                          (html . AIEntityFactHTMLView))
  :required-roles       '(admin superadmin ai-agent)
  :audit-level          :full
  :tags                 '(aientfact eav procurement v1 update versioned))

(register-outbound-route
  :aientfact/delete
  :crud-op :delete
  :description "Soft-expire a live fact (VALID_TO = NOW). Physical delete PROHIBITED."
  :requestmodel-class   'AIEntityFactRequestModel
  :businessobject-class 'AIEntityFact
  :adapter-class        'AIEntityFactAdapter
  :presenter-class      'AIEntityFactPresenter
  :view-classes         '((json . AIEntityFactJSONView))
  :required-roles       '(superadmin)
  :audit-level          :full
  :tags                 '(aientfact eav procurement v1 delete soft-expiry legal))
