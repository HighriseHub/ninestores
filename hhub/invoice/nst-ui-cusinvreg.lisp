;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun com-hhub-transaction-customer-invoice-register-page ()
  (with-cust-session-check
    (with-mvc-ui-page "My Invoices"
      #'create-model-for-customer-invoice-register
      #'create-widgets-for-customer-invoice-register
      :role :customer)))

(defun create-model-for-customer-invoice-register ()
  (let* ((company   (get-login-customer-company))
         (customer  (get-login-customer))
         (cust-id   (slot-value customer 'row-id))
         (tenant-id (slot-value company  'row-id))
         (adapter   (make-instance 'CustomerInvoiceRegisterAdapter))
         (presenter (make-instance 'CustomerInvoiceRegisterPresenter))
         (rm        (make-instance 'CustomerInvoiceRegisterRequestModel
                                   :buyer-id  cust-id
                                   :tenant-id tenant-id
                                   :company   company))
         (params    nil))
    ;;(setf params (acons "username" (get-login-user-name) params))
    (setf params (acons "uri" (hunchentoot:request-uri*) params))
    (with-hhub-transaction
        "com-hhub-transaction-customer-invoices-listpage" params
      (handler-case
          (multiple-value-bind (domobjs)
              (ProcessReadAllRequest adapter rm)
	    
	    (let* ((rmlist    (ProcessResponseList adapter domobjs))
                   (vmlist    (CreateAllViewModel presenter rmlist))
                   (htmlview  (make-instance 'CustomerInvoiceRegisterHTMLView))
		   (summary (compute-itc-summary cust-id tenant-id)))
	      (function (lambda ()
                (values vmlist summary htmlview)))))
        (error (c)
          (error 'hhub-business-function-error
                 :errstring (format nil "Invoice register error: ~A" c)))))))

(defun create-widgets-for-customer-invoice-register (modelfunc)
  (multiple-value-bind (vmlist summary htmlview) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
                    (cl-who:with-html-output (*standard-output* nil)
                      (:div :class "row"
                        (:div :class "col-xs-12"
                          (:div :class "panel panel-success"
                            (:div :class "panel-heading"
                              (:h3 :class "panel-title"
                                "Your ITC Summary"))
                            (:div :class "panel-body"
                              (:div :class "row"
                                (:div :class "col-xs-3 text-center"
                                  (:h2 :style "color:green"
                                    (cl-who:str
                                      (format nil "₹~A"
                                        (getf summary :claimable))))
                                  (:small "Claimable"))
                                (:div :class "col-xs-3 text-center"
                                  (:h2 :style "color:orange"
                                    (cl-who:str
                                      (format nil "₹~A"
                                        (getf summary :at-risk))))
                                  (:small "At Risk"))
                                (:div :class "col-xs-3 text-center"
                                  (:h2 :style "color:blue"
                                    (cl-who:str
                                      (format nil "₹~A"
                                        (getf summary :claimed))))
                                  (:small "Claimed"))
                                (:div :class "col-xs-3 text-center"
                                  (:h2 (cl-who:str
                                         (getf summary :invoices)))
                                  (:small "Invoices")))))))))))

          (widget2 (function (lambda ()
                    (cl-who:with-html-output (*standard-output* nil)
                      (:div :class "row"
                        (:div :class "col-xs-12"
                          (:h4 "All Invoices")
                          (:hr)
                          (if vmlist
                              (cl-who:str (display-as-table
                                (list "Invoice No" "Date" "Vendor"
                                      "Amount" "ITC" "GSTR2B" "Payment")
                                vmlist
                                'display-customer-invoice-register-row))
                              (cl-who:htm
                                (:p :class "text-muted"
                                  "No invoices found."))))))))))
      (list widget1 widget2))))

(defun display-customer-invoice-register-row (vm &rest args)
  (declare (ignore args))
  (cl-who:with-html-output (*standard-output* nil)
    (:td (cl-who:str (invoice-number      vm)))
    (:td (cl-who:str (invoice-date        vm)))
    (:td (cl-who:str (vendor-name         vm)))
    (:td :align "right"
         (cl-who:str (format nil "₹~A" (total-amount vm))))
    (:td :align "right"
         (cl-who:str (format nil "₹~A" (or (itc-amount vm) 0))))
    (:td (cl-who:str
           (case (intern (string-upcase
                           (or (gstr2b-match-status vm) "NOT_CHECKED"))
                         :keyword)
             (:matched    "✅ Matched")
             (:mismatched "⚠️ Mismatch")
             (:missing    "❌ Missing")
             (otherwise   "— Pending"))))
    (:td (cl-who:str
           (case (intern (string-upcase
                           (or (payment-status vm) "UNPAID"))
                         :keyword)
             (:paid           "✅ Paid")
             (:partially-paid "⚠️ Partial")
             (:unpaid         "❌ Unpaid")
             (otherwise       (payment-status vm)))))))

;;; Context Flow Dispatcher Routes
(register-outbound-route
  :customer-invoice/readall
  :crud-op      :list
  :description  "B2B buyer inward invoice register with ITC summary"
  :requestmodel-class    'CustomerInvoiceRegisterRequestModel
  :businessobject-class  'CustomerInvoiceEntry
  :adapter-class         'CustomerInvoiceRegisterAdapter
  :presenter-class       'CustomerInvoiceRegisterPresenter
  :view-classes          '((html . CustomerInvoiceRegisterHTMLView)
                           (json . CustomerInvoiceRegisterJSONView))
  :required-roles        '(customer)
  :audit-level           :full
  :tags                  '(buyer itc gstr2b procurement v1))
