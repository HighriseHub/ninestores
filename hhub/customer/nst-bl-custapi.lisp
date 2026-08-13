;;; nst-bl-custapi.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :customer/create
;;; Description: Register and onboard a new customer profile.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :customer/create
  :crud-op :create
  :description "Register and onboard a new customer profile."
  :requestmodel-class 'CustomerRequestModel
  :businessobject-class 'Customer
  :adapter-class 'CustomerAdapter
  :presenter-class 'CustomerPresenter
  :view-classes '((json . CustomerAddressJSONView))
  :tags '(customer api v1)
  :required-roles '(customer support)
  :feature-flags '(new-customer-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :customer/read
;;; Description: Reads customer profile by phone number or unique identifier.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :customer/read
  :crud-op :read
  :description "Reads customer profile by phone"
  :requestmodel-class 'CustomerSearchRequestModel
  :businessobject-class 'Customer
  :adapter-class 'CustomerAdapter
  :presenter-class 'CustomerPresenter
  :view-classes '((json . CustomerAddressJSONView))
  :tags '(customer api v1)
  :required-roles '(customer support)
  :feature-flags '(new-customer-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :customer/update
;;; Description: Update customer profile details like address and contact information.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :customer/update
  :crud-op :update
  :description "Update customer profile details like address and contact information."
  :requestmodel-class 'CustomerRequestModel
  :businessobject-class 'Customer
  :adapter-class 'CustomerAdapter
  :presenter-class 'CustomerPresenter
  :view-classes '((json . CustomerAddressJSONView))
  :tags '(customer api v1)
  :required-roles '(customer support)
  :feature-flags '(new-customer-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :customer/list
;;; Description: Retrieve and list all registered customer profiles.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :customer/list
  :crud-op :readall
  :description "Retrieve and list all registered customer profiles."
  :requestmodel-class 'CustomerRequestModel
  :businessobject-class 'Customer
  :adapter-class 'CustomerAdapter
  :presenter-class 'CustomerPresenter
  :view-classes '((json . CustomerAddressJSONView))
  :tags '(customer api v1)
  :required-roles '(support admin)
  :feature-flags '(new-customer-domain)
  :audit-level :full)
