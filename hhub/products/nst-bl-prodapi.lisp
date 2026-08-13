;;; nst-bl-prodapi.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/create (POST /api/v1/catalog/products)
;;; Description: Add a new product listing with description, category, pricing, and initial shipping info.
;;; Approval: Submitted for CompAdmin approval.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/create
  :crud-op :create
  :description "Add a new product listing with description, category, pricing, and initial shipping info. Submitted for CompAdmin approval."
  :requestmodel-class 'ProductCreateRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/bulk-create (POST /api/v1/catalog/products/bulk)
;;; Description: Upload multiple products at once via CSV file.
;;; Returns: A per-row success and error report.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/bulk-create
  :crud-op :create
  :description "Upload multiple products at once via CSV file. Returns a per-row success and error report."
  :requestmodel-class 'ProductBulkCreateRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductBulkJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/template (GET /api/v1/catalog/products/template)
;;; Description: Download the standard CSV template for bulk product upload with all required and optional column headers.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/template
  :crud-op :read
  :description "Download the standard CSV template for bulk product upload with all required and optional column headers."
  :requestmodel-class 'ProductTemplateRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductTemplateJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :minimal)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/list (GET /api/v1/catalog/products)
;;; Description: Search and list the vendor catalog.
;;; Filters: category, status (active | inactive | pending), keyword, price range.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/list
  :crud-op :readall
  :description "Search and list the vendor catalog. Filters: category, status (active | inactive | pending), keyword, price range."
  :requestmodel-class 'ProductSearchRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductListJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/read (GET /api/v1/catalog/products/{id})
;;; Description: Retrieve full product details: description, pricing tiers, images, category, shipping eligibility, and approval status.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/read
  :crud-op :read
  :description "Retrieve full product details: description, pricing tiers, images, category, shipping eligibility, and approval status."
  :requestmodel-class 'ProductReadRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductDetailJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/update (PUT /api/v1/catalog/products/{id})
;;; Description: Update product description, category assignment, or shipping info.
;;; Side Effect: Re-triggers approval if major fields change.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/update
  :crud-op :update
  :description "Update product description, category assignment, or shipping info. Re-triggers approval if major fields change."
  :requestmodel-class 'ProductUpdateRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/delete (DELETE /api/v1/catalog/products/{id})
;;; Description: Permanently delete a product listing. Only permitted for draft or inactive products.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/delete
  :crud-op :delete
  :description "Permanently delete a product listing. Only permitted for draft or inactive products."
  :requestmodel-class 'ProductDeleteRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductDeleteJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/upload-images (POST /api/v1/catalog/products/{id}/images)
;;; Description: Upload one or more product images. Accepts multipart form data, up to 5 images per request.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/upload-images
  :crud-op :create
  :description "Upload one or more product images. Accepts multipart form data, up to 5 images per request."
  :requestmodel-class 'ProductUploadImagesRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/update-status (PUT /api/v1/catalog/products/{id}/status)
;;; Description: Activate or deactivate a product listing without re-triggering approval.
;;; Statuses: active | inactive
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/update-status
  :crud-op :update
  :description "Activate or deactivate a product listing without re-triggering approval. Accepts status: active | inactive."
  :requestmodel-class 'ProductUpdateStatusRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductStatusJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/copy (POST /api/v1/catalog/products/{id}/copy)
;;; Description: Duplicate an existing product listing as a new draft for creating similar product variations.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/copy
  :crud-op :create
  :description "Duplicate an existing product listing as a new draft for creating similar product variations."
  :requestmodel-class 'ProductCopyRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/update-pricing (PUT /api/v1/catalog/products/{id}/pricing)
;;; Description: Update product pricing tiers, bulk discounts, and the linked GST HSN code.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/update-pricing
  :crud-op :update
  :description "Update product pricing tiers, bulk discounts, and the linked GST HSN code."
  :requestmodel-class 'ProductUpdatePricingRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductPricingJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :full)

;;; ---------------------------------------------------------------------------
;;; Outbound Route: :products/update-shipping (POST /api/v1/catalog/products/{id}/shipping)
;;; Description: Add or update shipping configuration for a specific product: weight, dimensions, and delivery restrictions.
;;; ---------------------------------------------------------------------------
(register-outbound-route
  :products/update-shipping
  :crud-op :update
  :description "Add or update shipping configuration for a specific product: weight, dimensions, and delivery restrictions."
  :requestmodel-class 'ProductUpdateShippingRequestModel
  :businessobject-class 'Product
  :adapter-class 'ProductAdapter
  :presenter-class 'ProductPresenter
  :view-classes '((json . ProductShippingJSONView))
  :tags '(products catalog api v1)
  :required-roles '(vendor)
  :feature-flags '(new-product-domain)
  :audit-level :full)
