;;; nst-bl-invapi.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/create (POST /api/v1/invoices)
;;; Description: Create a new invoice for a customer. Optionally links to an existing order.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/create
  :crud-op :create
  :description "Create a new invoice for a customer. Optionally links to an existing order for auto-population of line items."
  :requestmodel-class 'InvoiceHeaderRequestModel
  :businessobject-class 'InvoiceHeader
  :adapter-class 'InvoiceHeaderAdapter
  :presenter-class 'InvoiceHeaderPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices api v1)
  :required-roles '(vendor)
  :feature-flags '(new-invoice-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/list (GET /api/v1/invoices)
;;; Description: Search and list invoices by customer, date range, or status.
;;; Statuses: paid | unpaid | overdue
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/list
  :crud-op :readall
  :description "Search and list invoices by customer, date range, or status: paid | unpaid | overdue."
  :requestmodel-class 'InvoiceHeaderSearchRequestModel
  :businessobject-class 'InvoiceHeader
  :adapter-class 'InvoiceHeaderAdapter
  :presenter-class 'InvoiceHeaderPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices api v1)
  :required-roles '(vendor)
  :feature-flags '(new-invoice-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/read (GET /api/v1/invoices/{id})
;;; Description: Get full invoice header, line items, GST breakdown, payment status, and customer details.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/read
  :crud-op :read
  :description "Get full invoice: header, line items, GST breakdown, payment status, and assigned customer details."
  :requestmodel-class 'InvoiceHeaderSearchRequestModel
  :businessobject-class 'InvoiceHeader
  :adapter-class 'InvoiceHeaderAdapter
  :presenter-class 'InvoiceHeaderPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices api v1)
  :required-roles '(vendor)
  :feature-flags '(new-invoice-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/update (PUT /api/v1/invoices/{id})
;;; Description: Update invoice header (issue date, due date, internal notes, customer).
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/update
  :crud-op :update
  :description "Update invoice header: issue date, due date, internal notes, or customer assignment."
  :requestmodel-class 'InvoiceHeaderRequestModel
  :businessobject-class 'InvoiceHeader
  :adapter-class 'InvoiceHeaderAdapter
  :presenter-class 'InvoiceHeaderPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices api v1)
  :required-roles '(vendor)
  :feature-flags '(new-invoice-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/items/create (POST /api/v1/invoices/{id}/items)
;;; Description: Add a product line item to the invoice via catalog product ID or barcode.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/items/create
  :crud-op :create
  :description "Add a product line item to the invoice. Accepts a catalog product ID or a barcode scan value."
  :requestmodel-class 'InvoiceItemRequestModel
  :businessobject-class 'InvoiceItem
  :adapter-class 'InvoiceItemAdapter
  :presenter-class 'InvoiceItemPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices items api v1)
  :required-roles '(vendor)
  :feature-flags '(new-invoice-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/items/update (PUT /api/v1/invoices/{id}/items/{item-id})
;;; Description: Update a specific line item: quantity, unit price, or discount percentage.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/items/update
  :crud-op :update
  :description "Update a specific line item: quantity, unit price, or discount percentage."
  :requestmodel-class 'InvoiceItemRequestModel
  :businessobject-class 'InvoiceItem
  :adapter-class 'InvoiceItemAdapter
  :presenter-class 'InvoiceItemPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices items api v1)
  :required-roles '(vendor)
  :feature-flags '(new-invoice-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/items/delete (DELETE /api/v1/invoices/{id}/items/{item-id})
;;; Description: Remove a specific line item from the invoice.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/items/delete
  :crud-op :delete
  :description "Remove a specific line item from the invoice."
  :requestmodel-class 'InvoiceItemRequestModel
  :businessobject-class 'InvoiceItem
  :adapter-class 'InvoiceItemAdapter
  :presenter-class 'InvoiceItemPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices items api v1)
  :required-roles '(vendor)
  :feature-flags '(new-invoice-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/payment/create (POST /api/v1/invoices/{id}/payment)
;;; Description: Record a payment against the invoice.
;;; Payment Methods: cash | UPI | wallet | card | bank-transfer
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/payment/create
  :crud-op :create
  :description "Record a payment against the invoice. Accepts method: cash | UPI | wallet | card | bank-transfer."
  :requestmodel-class 'InvoiceHeaderRequestModel
  :businessobject-class 'InvoiceHeader
  :adapter-class 'InvoiceHeaderAdapter
  :presenter-class 'InvoiceHeaderPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices payments api v1)
  :required-roles '(vendor)
  :feature-flags '(new-invoice-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/send (POST /api/v1/invoices/{id}/send)
;;; Description: Email the invoice to the customer using vendor configured mail settings.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/send
  :crud-op :create
  :description "Email the invoice to the assigned customer using the vendor configured mail settings."
  :requestmodel-class 'InvoiceHeaderRequestModel
  :businessobject-class 'InvoiceHeader
  :adapter-class 'InvoiceHeaderAdapter
  :presenter-class 'InvoiceHeaderPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices api v1)
  :required-roles '(vendor)
  :feature-flags '(new-invoice-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/download (GET /api/v1/invoices/{id}/download)
;;; Description: Generate and return a print-ready PDF of the invoice with GST details and branding.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/download
  :crud-op :read
  :description "Generate and return a print-ready PDF of the invoice with GST details and vendor branding."
  :requestmodel-class 'InvoiceHeaderRequestModel
  :businessobject-class 'InvoiceHeader
  :adapter-class 'InvoiceHeaderAdapter
  :presenter-class 'InvoiceHeaderPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices api v1)
  :required-roles '(vendor)
  :feature-flags '(new-invoice-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/public (GET /api/v1/invoices/{id}/public)
;;; Description: Publicly accessible invoice view URL for sharing. No auth required.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/public
  :crud-op :read
  :description "Publicly accessible invoice view URL for sharing with customers directly. No authentication required."
  :requestmodel-class 'InvoiceHeaderRequestModel
  :businessobject-class 'InvoiceHeader
  :adapter-class 'InvoiceHeaderAdapter
  :presenter-class 'InvoiceHeaderPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices api v1 public)
  :required-roles '()
  :feature-flags '(new-invoice-domain)
  :audit-level :minimal)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :invoices/settings/update (PUT /api/v1/invoices/settings)
;;; Description: Update invoice print settings: logo, headers, footers, GSTIN, signature.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :invoices/settings/update
  :crud-op :update
  :description "Update invoice print settings: business logo, header text, footer content, GSTIN, and digital signature."
  :requestmodel-class 'CustomerInvoiceRegisterRequestModel
  :businessobject-class 'InvoiceHeader
  :adapter-class 'InvoiceHeaderAdapter
  :presenter-class 'InvoiceHeaderPresenter
  :view-classes '((json . JSONView))
  :tags '(invoices settings api v1)
  :required-roles '(vendor)
  :feature-flags '(new-invoice-domain)
  :audit-level :full)
