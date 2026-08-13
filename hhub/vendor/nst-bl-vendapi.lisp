;;; nst-bl-vendapi.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :vendors/pending/list (GET /api/v1/admin/vendors/pending)
;;; Description: List all vendor account registrations awaiting approval for this tenant company.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :vendors/pending/list
  :crud-op :readall
  :description "List all vendor account registrations awaiting approval for this tenant company."
  :requestmodel-class 'RequestModelVendorApproval
  :businessobject-class 'Vendor
  :adapter-class 'VendorApprovalAdapter
  :presenter-class 'VendorPresenter
  :view-classes '((json . JSONView))
  :tags '(vendors admin api v1)
  :required-roles '(admin support)
  :feature-flags '(new-vendor-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :vendors/approve (PUT /api/v1/admin/vendors/{id}/approve)
;;; Description: Approve a vendor account, granting them access to sell in the tenant marketplace.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :vendors/approve
  :crud-op :update
  :description "Approve a vendor account, granting them access to sell in the tenant marketplace."
  :requestmodel-class 'RequestModelVendorApproval
  :businessobject-class 'Vendor
  :adapter-class 'VendorApprovalAdapter
  :presenter-class 'VendorPresenter
  :view-classes '((json . JSONView))
  :tags '(vendors admin api v1)
  :required-roles '(admin support)
  :feature-flags '(new-vendor-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :vendors/reject (PUT /api/v1/admin/vendors/{id}/reject)
;;; Description: Reject a vendor registration with reason. Sends rejection notification to vendor email.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :vendors/reject
  :crud-op :update
  :description "Reject a vendor registration with reason. Sends a rejection notification to the vendor email."
  :requestmodel-class 'RequestModelVendorApproval
  :businessobject-class 'Vendor
  :adapter-class 'VendorApprovalAdapter
  :presenter-class 'VendorPresenter
  :view-classes '((json . JSONView))
  :tags '(vendors admin api v1)
  :required-roles '(admin support)
  :feature-flags '(new-vendor-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :vendor/login (POST /api/v1/auth/vendor/login)
;;; Description: Authenticate a vendor via PIN or OTP. On success, returns the list of associated tenants.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :vendor/login
  :crud-op :create
  :description "Authenticate a vendor via PIN or OTP. On success, returns the list of associated tenants for context selection."
  :requestmodel-class 'RequestVendor
  :businessobject-class 'Vendor
  :adapter-class 'VendorAdapter
  :presenter-class 'VendorPresenter
  :view-classes '((json . JSONView))
  :tags '(vendor auth api v1)
  :required-roles '(all)
  :feature-flags '(new-vendor-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :vendor/tenant/switch (PUT /api/v1/auth/vendor/tenant)
;;; Description: Switch the active tenant context for a multi-tenant vendor session without re-authentication.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :vendor/tenant/switch
  :crud-op :update
  :description "Switch the active tenant context for a multi-tenant vendor session without requiring re-authentication."
  :requestmodel-class 'RequestVendor
  :businessobject-class 'Vendor
  :adapter-class 'VendorAdapter
  :presenter-class 'VendorPresenter
  :view-classes '((json . JSONView))
  :tags '(vendor auth api v1)
  :required-roles '(vendor)
  :feature-flags '(new-vendor-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :vendor/logout (POST /api/v1/auth/vendor/logout)
;;; Description: Invalidate the current vendor session.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :vendor/logout
  :crud-op :create
  :description "Invalidate the current vendor session."
  :requestmodel-class 'RequestVendor
  :businessobject-class 'Vendor
  :adapter-class 'VendorAdapter
  :presenter-class 'VendorPresenter
  :view-classes '((json . JSONView))
  :tags '(vendor auth api v1)
  :required-roles '(vendor)
  :feature-flags '(new-vendor-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :vendor/payment/gateway/update (PUT /api/v1/vendor/payment/gateway)
;;; Description: Update vendor payment gateway API credentials and integration configuration.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :vendor/payment/gateway/update
  :crud-op :update
  :description "Update vendor payment gateway API credentials and integration configuration (API key, secret, webhook URL)."
  :requestmodel-class 'VPaymentMethodsRequestModel
  :businessobject-class 'VPaymentMethods
  :adapter-class 'VPaymentMethodsAdapter
  :presenter-class 'VPaymentMethodsPresenter
  :view-classes '((json . JSONView))
  :tags '(vendor payment api v1)
  :required-roles '(vendor)
  :feature-flags '(new-vendor-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :vendor/payment/upi/update (PUT /api/v1/vendor/payment/upi)
;;; Description: Save or update the vendor UPI ID and display settings used in customer-facing payment flow.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :vendor/payment/upi/update
  :crud-op :update
  :description "Save or update the vendor UPI ID and display settings used in the customer-facing payment flow."
  :requestmodel-class 'VPaymentMethodsRequestModel
  :businessobject-class 'VPaymentMethods
  :adapter-class 'VPaymentMethodsAdapter
  :presenter-class 'VPaymentMethodsPresenter
  :view-classes '((json . JSONView))
  :tags '(vendor payment api v1)
  :required-roles '(vendor)
  :feature-flags '(new-vendor-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :vendor/payment/upi-transactions/list (GET /api/v1/vendor/payment/upi-transactions)
;;; Description: List all UPI payment transactions for this vendor with status, amount, and UTR reference details.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :vendor/payment/upi-transactions/list
  :crud-op :readall
  :description "List all UPI payment transactions for this vendor with status, amount, and UTR reference details."
  :requestmodel-class 'VPaymentMethodsRequestModel
  :businessobject-class 'VPaymentMethods
  :adapter-class 'VPaymentMethodsAdapter
  :presenter-class 'VPaymentMethodsPresenter
  :view-classes '((json . JSONView))
  :tags '(vendor payment api v1)
  :required-roles '(vendor)
  :feature-flags '(new-vendor-domain)
  :audit-level :full)
