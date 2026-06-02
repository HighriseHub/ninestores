;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun select-invoices-for-buyer (buyer-id tenant-id)
  "Fetch inward invoice register rows for a B2B buyer via CLSQL ORM."
  (clsql:select 'dod-v-customer-invoice-register
    :where   [and [= [:buyer-id]  buyer-id]
                  [= [:tenant-id] tenant-id]]
    :order-by [:invoice-date]
    :flatp    t
    :caching  nil))


(defun compute-itc-summary (buyer-id tenant-id)
  "Aggregate ITC position for the buyer ITC dashboard card."
  (let* ((sql "SELECT COUNT(*),
               COALESCE(SUM(CASE WHEN ITC_ELIGIBLE=1 AND ITC_CLAIMED=0
                           THEN ITC_AMOUNT ELSE 0 END),0),
               COALESCE(SUM(CASE WHEN ITC_CLAIMED=1
                           THEN ITC_AMOUNT ELSE 0 END),0),
               COALESCE(SUM(TOTAL_AMOUNT),0)
               FROM DOD_V_CUSTOMER_INVOICE_REGISTER
               WHERE BUYER_ID=~A AND TENANT_ID=~A")
         (row (car (clsql:query (format nil sql buyer-id tenant-id)
                                :field-names nil))))
    (list :invoices  (nth 0 row)
          :claimable (nth 1 row)
          :claimed   (nth 2 row)
          :purchases (nth 3 row)
          :at-risk   0)))

(defmethod doReadAll ((svc CustomerInvoiceRegisterService)
                      (rm  CustomerInvoiceRegisterRequestModel))
  "Read all inward invoices and ITC summary for a B2B buyer."
  (let* ((bid     (buyer-id rm))
         (tid     (tenant-id rm))
         (rows    (select-invoices-for-buyer bid tid))
         ;;(summary (compute-itc-summary bid tid))
         (domobjs (mapcar (lambda (r)
                            (make-invoice-domain-object r)) rows)))
    (setf (bo-knowledge svc) (make-bo-knowledge :truth :T :payload domobjs :provenance "service" :timestamp (get-universal-time)))
    domobjs))




(defun make-invoice-domain-object (row)
  "Construct CustomerInvoiceEntry from a dod-v-customer-invoice-register instance."
  (make-instance 'CustomerInvoiceEntry
    :invoice-id          (invoice-id          row)
    :invoice-number      (invoice-number      row)
    :invoice-date        (invoice-date        row)
    :vendor-name         (vendor-name         row)
    :vendor-gstin        (vendor-gstin        row)
    :total-amount        (total-amount        row)
    :itc-amount          (itc-amount          row)
    :itc-eligible        (itc-eligible        row)
    :itc-claimed         (itc-claimed         row)
    :gstr2b-match-status (gstr2b-match-status row)
    :payment-status      (payment-status      row)
    :gst-period          (gst-period          row)))

(defmethod ProcessReadAllRequest ((adapter CustomerInvoiceRegisterAdapter)
                                   (rm      CustomerInvoiceRegisterRequestModel))
  "Route to CustomerInvoiceRegisterService for buyer inward invoice fetch."
  (setf (slot-value adapter 'businessservice)
        (find-class 'CustomerInvoiceRegisterService))
  (call-next-method))

(defmethod ProcessResponse ((adapter CustomerInvoiceRegisterAdapter)
                             (busobj  CustomerInvoiceEntry))
  "Map domain object to response model."
  (let ((rm (make-instance 'CustomerInvoiceEntryResponseModel)))
    (createresponsemodel adapter busobj rm)))

(defmethod ProcessResponseList ((adapter CustomerInvoiceRegisterAdapter) lst)
  "Map list of domain objects to response model list."
  (mapcar (lambda (obj)
            (let ((rm (make-instance 'CustomerInvoiceEntryResponseModel)))
              (createresponsemodel adapter obj rm))) lst))

(defmethod CreateResponseModel ((adapter CustomerInvoiceRegisterAdapter)
                                 (src     CustomerInvoiceEntry)
                                 (dst     CustomerInvoiceEntryResponseModel))
  (with-slots (invoice-number invoice-date vendor-name vendor-gstin
               total-amount itc-amount gstr2b-match-status payment-status) dst
    (setf invoice-number      (invoice-number src)
          invoice-date        (invoice-date src)
          vendor-name         (vendor-name src)
          vendor-gstin        (vendor-gstin src)
          total-amount        (total-amount src)
          itc-amount          (itc-amount src)
          gstr2b-match-status (gstr2b-match-status src)
          payment-status      (payment-status src))
    dst))

(defmethod CreateViewModel ((presenter CustomerInvoiceRegisterPresenter)
                             (rm        CustomerInvoiceEntryResponseModel))
  (let ((vm (make-instance 'CustomerInvoiceEntryViewModel)))
    (with-slots (invoice-number invoice-date vendor-name vendor-gstin
                 total-amount itc-amount gstr2b-match-status payment-status) vm
      (setf invoice-number      (invoice-number rm)
            invoice-date        (invoice-date rm)
            vendor-name         (vendor-name rm)
            vendor-gstin        (vendor-gstin rm)
            total-amount        (total-amount rm)
            itc-amount          (itc-amount rm)
            gstr2b-match-status (gstr2b-match-status rm)
            payment-status      (payment-status rm))
      vm)))

(defmethod CreateAllViewModel ((presenter CustomerInvoiceRegisterPresenter) rmlist)
  (mapcar (lambda (rm) (createviewmodel presenter rm)) rmlist))
