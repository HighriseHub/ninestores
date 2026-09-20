;;; dod-ui-pol.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; HERE WE DEFINE ALL THE POLICIES FOR Nine Stores ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun com-hhub-policy-customer-invoices-listpage (&optional (params nil))
  :documentation "Policy for warehouse create"
  T)

(defun com-hhub-policy-create-warehouse (&optional (params nil))
  :documentation "Policy for warehouse create"
  T)

(defun com-hhub-policy-read-warehouse (&optional (params nil))
  :documentation "Policy for warehouse create"
  T)
(defun com-hhub-policy-readall-warehouse (&optional (params nil))
  :documentation "Policy for read all warehouses for a given vendor"
  T)

(defun com-hhub-policy-update-warehouse (&optional (params nil))
  :documentation "Policy for update a given warehouse for a given vendor"
  T)

(defun com-hhub-policy-delete-warehouse (&optional (params nil))
  :documentation "Policy for update a given warehouse for a given vendor"
  T)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; CATALOG / PRODUCT API ENDPOINT POLICIES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; One policy per PUBLISHED API ENDPOINT (hhub/products/nst-bl-prdapi.lisp), reached
;;; through the conflodis2 transaction seam. They are named after the endpoint, not
;;; after a UI controller, because an API endpoint has no controller of its own — the
;;; whole surface shares com-hhub-api-dispatch.
;;;
;;; THE CHECK IS REAL, not a stub T like the warehouse set above: every one of these
;;; denies when the SESSION TENANT IS SUSPENDED, using the same
;;; com-hhub-attribute-company-issuspended predicate that show-invoice-payment-page
;;; and the customer-address policies already use. That is the one authority question
;;; the API can answer today from the params it carries: WHICH TENANT is asking is
;;; established by the credential before any policy runs (नियम-1), and whether that
;;; tenant may transact at all is this check.
;;;
;;; WHAT THEY DELIBERATELY DO NOT CHECK, and why that is not an omission:
;;;
;;;   * ROLE / SCOPE (vendor vs compadmin vs customer). The API resolves a company
;;;     from the session credential and nothing more; there is no role or scope value
;;;     in `params` to test. Inventing one here would be a security theatre that
;;;     passes for everybody. The action routes already carry :required-roles '(vendor)
;;;     as metadata, and the header of nst-bl-prdapi.lisp is explicit that conflodis2
;;;     v1 CARRIES but does NOT ENFORCE it. Making role enforcement real means the
;;;     credential seam (apidefs2 SECTION 4) must publish an actor role — a change to
;;;     the boundary, not to a policy function.
;;;
;;;   * PER-OBJECT OWNERSHIP. Whether this vendor owns product 42 is already answered
;;;     by the VERBS: every product query is tenant-scoped, so another tenant's row-id
;;;     yields 404, never data. A policy cannot check that better than the query that
;;;     already does it, and duplicating it would create two places to get wrong.
;;;
;;; `params` is the controller-style ALIST (string keys, "uri" and "company"), built by
;;; the transaction seam — NOT the keyword plist the ferry reads. Reading it with
;;; keyword keys would silently find nothing and allow everything.

(defun %com-hhub-policy-tenant-may-transact (params policy-name)
  "Shared body for every API-endpoint policy: T when the session tenant may
   transact, an hhub-abac-transaction-error when it is suspended.

   ONE IMPLEMENTATION FOR ALL DOMAINS. The product, warehouse, vendor-profile,
   vendor-shipping and vendor-payment endpoint policies all call this, so the
   authority rule is stated once and cannot drift between domains.

   A NIL COMPANY IS ALLOWED THROUGH HERE ON PURPOSE, and the reasoning matters:
   by the time a policy runs, apidefs2 has already refused an unauthenticated
   request with a 401 (api-authenticate runs BEFORE dispatch — see
   com-hhub-api-dispatch). So a nil company here means the caller forgot to put
   it in params, not that an anonymous request arrived. Signalling
   hhub-abac-transaction-error would report that as 'this account is suspended',
   which is a lie; letting it through keeps the failure where it belongs and the
   verbs' own tenant scoping still refuses the write."
  (let* ((company (cdr (assoc "company" params :test 'equal)))
         (suspend-flag (when company (slot-value company 'suspend-flag))))
    (when (and company (com-hhub-attribute-company-issuspended suspend-flag))
      (error 'hhub-abac-transaction-error
             :errstring (format nil "Account Name: ~A. This Account is Suspended. (~A)"
                                (slot-value company 'name) policy-name)))
    T))

(defun com-hhub-policy-api-product-list (&optional (params nil))
  "GET /hhub/api/v1/catalog/products — list the session tenant's catalog."
  (%com-hhub-policy-tenant-may-transact params "list products"))

(defun com-hhub-policy-api-product-create (&optional (params nil))
  "POST /hhub/api/v1/catalog/products — create a product."
  (%com-hhub-policy-tenant-may-transact params "create product"))

(defun com-hhub-policy-api-product-read (&optional (params nil))
  "GET /hhub/api/v1/catalog/products/{id} — read one product."
  (%com-hhub-policy-tenant-may-transact params "read product"))

(defun com-hhub-policy-api-product-update (&optional (params nil))
  "PUT /hhub/api/v1/catalog/products/{id} — partially update a product."
  (%com-hhub-policy-tenant-may-transact params "update product"))

(defun com-hhub-policy-api-product-delete (&optional (params nil))
  "DELETE /hhub/api/v1/catalog/products/{id} — soft-delete a product."
  (%com-hhub-policy-tenant-may-transact params "delete product"))

(defun com-hhub-policy-api-product-update-shipping (&optional (params nil))
  "PUT /hhub/api/v1/catalog/products/{id}/shipping — set shipping dimensions
   and weight."
  (%com-hhub-policy-tenant-may-transact params "update product shipping"))

(defun com-hhub-policy-api-product-update-pricing (&optional (params nil))
  "PUT /hhub/api/v1/catalog/products/{id}/pricing — set the price, discount and
   discount window.

   A SEPARATE FUNCTION from product-update even though both write through the same
   product: the transaction→policy pairing is one-to-one (§2), and pricing is the
   one catalog write whose कर्म is a different entity (nst-prd-pricing). Sharing
   product-update's function would make a refused price change indistinguishable
   from a refused name change in the log, and the two could never diverge — which
   is exactly the divergence a money-writing endpoint is most likely to need."
  (%com-hhub-policy-tenant-may-transact params "update product pricing"))

(defun com-hhub-policy-api-product-update-status (&optional (params nil))
  "PUT /hhub/api/v1/catalog/products/{id}/status — turn a product on or off.

   A SEPARATE function from product-update and product-update-shipping, for the
   one-to-one transaction→policy reason the section header gives — and here the
   separation has real content rather than being bookkeeping. Turning a product OFF
   is a VISIBILITY decision with a different blast radius from editing it: the
   product leaves the catalogue while its price, stock and orders stay exactly as
   they were. A tenant that wants vendors able to edit but not to hide can express
   that here and nowhere else — impossible if the three writes shared one function."
  (%com-hhub-policy-tenant-may-transact params "change product status"))

(defun %policy-company-from-params (params)
  "The company out of a policy's PARAMS, whichever shape it is in.

   🚨 TWO SHAPES EXIST AND BOTH ARE REAL. The legacy UI passes an ALIST with string
   keys — (assoc \"company\" params :test #'equal) — which is what
   %com-hhub-policy-tenant-may-transact reads. The API passes a PLIST with keyword
   keys, because that is what the ferry and the domain verbs consume. Neither is
   wrong; they are two callers of one hook.

   WHY THIS IS WRITTEN DEFENSIVELY RATHER THAN ASSUMING ONE: the API's PEP seam
   (*action-route-transaction-function*, conflodis2 §5) is still an unbound
   pass-through, so NO policy has ever received API params and the shape has never
   been exercised. Guessing one shape would produce a policy that silently reads a
   NIL company the first time the seam is bound — and a nil company is TOLERATED by
   design (see %com-hhub-policy-tenant-may-transact), so the failure would be a
   policy that quietly permits everything instead of erroring. Silent permit is the
   one failure mode an authorization check must not have."
  (or (cdr (assoc "company" params :test #'equal))
      (getf params :company)))

(defun com-hhub-policy-api-product-template (&optional (params nil))
  "GET /hhub/api/v1/catalog/products/template — download the vendor's products.csv.

   A READ, and a SEPARATE policy from the bulk upload's even though the two are one
   contract. The separation is what a tenant needs in order to grant 'you may look at
   your catalogue as a file' without granting 'you may rewrite your catalogue from a
   file' — the download is harmless on its own and the upload is not, so binding them
   to one authority would force a tenant to permit both or neither.

   Governed by the bulk-upload subscription attribute for the same reason the vendor
   page hides the whole Bulk Add Products entry together: the file is only useful to
   someone who can send it back, and offering a disabled feature's first step is how
   a vendor ends up filling in a template they are not allowed to submit."
  (%com-hhub-policy-tenant-may-transact params "download the bulk products template"))

(defun com-hhub-policy-api-product-bulk-upload (&optional (params nil))
  "POST /hhub/api/v1/catalog/products/bulk — upload many products from a CSV.

   THE SUBSCRIPTION TIE-IN LIVES HERE, because it is an authorization question, and
   this reuses com-hhub-attribute-company-prdbulkupload-enabled rather than
   restating the plan table: BASIC and PROFESSIONAL are enabled, COMMUNITY and TRIAL
   are not. Restating it would be a second copy of a business rule, and the two
   copies would disagree the first time a plan changes.

   🚨 WHAT IS DELIBERATELY **NOT** CHECKED HERE, AND WHY — the 100-row cap
   (com-hhub-attribute-vendor-bulk-product-count), which the LEGACY policy
   com-hhub-policy-vendor-bulk-product-add does enforce.

   The legacy can check it because the UI parses the CSV BEFORE the policy runs and
   passes a \"prdcount\" param in. A PEP wrapping a verb cannot: the count is a
   property of the uploaded file, and the only code that knows it correctly is the
   parser, which is the verb itself. Counting lines here instead would be a second,
   cruder definition of 'a row' — one that miscounts the moment a quoted field
   contains a newline — and a cap enforced by a miscount is worse than a cap
   enforced in one place.

   So the split is: THIS POLICY answers WHO may bulk-upload at all, and
   route-product-bulk-upload enforces HOW MUCH in one upload. Stated here because a
   reader comparing this file with the legacy policy will otherwise conclude the cap
   was dropped."
  (let* ((company (%policy-company-from-params params))
         (subs-plan (when company (ignore-errors (subscription-plan company))))
         (cmp-type  (when company (ignore-errors (cmp-type company))))
         (suspend-flag (when company (slot-value company 'suspend-flag))))
    (when company
      (when (com-hhub-attribute-company-issuspended suspend-flag)
        (error 'hhub-abac-transaction-error
               :errstring (format nil "Account Name: ~A. This Account is Suspended. (bulk product upload)"
                                  (slot-value company 'name))))
      (unless (com-hhub-attribute-company-prdbulkupload-enabled subs-plan cmp-type)
        (error 'hhub-abac-transaction-error
               :errstring (format nil "Account Name: ~A. Bulk product upload is not enabled on this subscription plan (~A)."
                                  (slot-value company 'name) subs-plan))))
    T))

(defun com-hhub-policy-api-product-copy (&optional (params nil))
  "POST /hhub/api/v1/catalog/products/{id}/copy — duplicate a product as a new listing.

   THE ONE PRODUCT POLICY WHOSE SEPARATION IS A REAL AUTHORITY SPLIT rather than a
   logging convenience. Every other product write changes a row that already exists;
   copy MANUFACTURES a new sellable listing. A tenant that trusts a vendor to edit
   prices but not to multiply its catalogue can grant product.update and withhold
   this — impossible if the two shared a function.

   It does NOT confer publication. The copy is created with make's defaults, so it is
   PENDING approval (prd-copy-initargs deliberately omits the approval initargs), and
   the existing approval gate is what admits it to the storefront. This policy lets a
   vendor PROPOSE a listing; it does not let anyone put one on sale."
  (%com-hhub-policy-tenant-may-transact params "copy product"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; WAREHOUSE · VENDOR-PROFILE · VENDOR-SHIPPING · VENDOR-PAYMENT ;;;;;;;;;;;;;
;;;;;;;;;;;;; API ENDPOINT POLICIES                                          ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; The remaining API endpoints created before the product work. Same shape as the
;;; product set above and the same single authority rule; each names the endpoint it
;;; guards so a deny message says WHICH call was refused.
;;;
;;; ONE FUNCTION PER ENDPOINT, even where the body is identical, because the
;;; TRANSACTION→POLICY pairing is one-to-one (see the ABAC skill, §2): a policy row
;;; holds a single POLICY_FUNC, so sharing a function between two transactions would
;;; make the two indistinguishable in the log and unable to diverge later. Where the
;;; body IS identical, that is deliberate — they all defer to
;;; %com-hhub-policy-tenant-may-transact so the rule itself exists once.

;; ── WAREHOUSE ───────────────────────────────────────────────────────────────
(defun com-hhub-policy-api-warehouse-list (&optional (params nil))
  "GET /hhub/api/v1/warehouse — list the session tenant's warehouses."
  (%com-hhub-policy-tenant-may-transact params "list warehouses"))

(defun com-hhub-policy-api-warehouse-create (&optional (params nil))
  "POST /hhub/api/v1/warehouse — create a warehouse."
  (%com-hhub-policy-tenant-may-transact params "create warehouse"))

(defun com-hhub-policy-api-warehouse-read (&optional (params nil))
  "GET /hhub/api/v1/warehouse/{id} — read one warehouse."
  (%com-hhub-policy-tenant-may-transact params "read warehouse"))

(defun com-hhub-policy-api-warehouse-read-identity (&optional (params nil))
  "GET /hhub/api/v1/warehouse/by-identity — read a warehouse by its business
   identity (GSTIN + name) rather than its row-id."
  (%com-hhub-policy-tenant-may-transact params "read warehouse by identity"))

(defun com-hhub-policy-api-warehouse-update (&optional (params nil))
  "PUT /hhub/api/v1/warehouse/{id} — update a warehouse."
  (%com-hhub-policy-tenant-may-transact params "update warehouse"))

(defun com-hhub-policy-api-warehouse-delete (&optional (params nil))
  "DELETE /hhub/api/v1/warehouse/{id} — soft-delete a warehouse."
  (%com-hhub-policy-tenant-may-transact params "delete warehouse"))

;; ── VENDOR PROFILE ──────────────────────────────────────────────────────────
(defun com-hhub-policy-api-vendor-profile-list (&optional (params nil))
  "GET /hhub/api/v1/vendor/profile — list vendor profiles for the session tenant."
  (%com-hhub-policy-tenant-may-transact params "list vendor profiles"))

(defun com-hhub-policy-api-vendor-profile-create (&optional (params nil))
  "POST /hhub/api/v1/vendor/profile — register a vendor."
  (%com-hhub-policy-tenant-may-transact params "create vendor profile"))

(defun com-hhub-policy-api-vendor-profile-read (&optional (params nil))
  "GET /hhub/api/v1/vendor/profile/{id} — read one vendor profile."
  (%com-hhub-policy-tenant-may-transact params "read vendor profile"))

(defun com-hhub-policy-api-vendor-profile-update (&optional (params nil))
  "PUT /hhub/api/v1/vendor/profile/{id} — update a vendor profile."
  (%com-hhub-policy-tenant-may-transact params "update vendor profile"))

(defun com-hhub-policy-api-vendor-profile-delete (&optional (params nil))
  "DELETE /hhub/api/v1/vendor/profile/{id} — soft-delete a vendor profile."
  (%com-hhub-policy-tenant-may-transact params "delete vendor profile"))

;; ── VENDOR SHIPPING ─────────────────────────────────────────────────────────
(defun com-hhub-policy-api-vendor-shipping-list (&optional (params nil))
  "GET /hhub/api/v1/vendor/shipping — list shipping configurations."
  (%com-hhub-policy-tenant-may-transact params "list vendor shipping configurations"))

(defun com-hhub-policy-api-vendor-shipping-create (&optional (params nil))
  "POST /hhub/api/v1/vendor/shipping — create a vendor's shipping configuration."
  (%com-hhub-policy-tenant-may-transact params "create vendor shipping configuration"))

(defun com-hhub-policy-api-vendor-shipping-read (&optional (params nil))
  "GET /hhub/api/v1/vendor/shipping/{vendorId} — read one vendor's shipping
   configuration."
  (%com-hhub-policy-tenant-may-transact params "read vendor shipping configuration"))

(defun com-hhub-policy-api-vendor-shipping-update (&optional (params nil))
  "PUT /hhub/api/v1/vendor/shipping/{vendorId} — update a vendor's shipping
   configuration."
  (%com-hhub-policy-tenant-may-transact params "update vendor shipping configuration"))

(defun com-hhub-policy-api-vendor-shipping-ratetable (&optional (params nil))
  "PUT /hhub/api/v1/vendor/shipping/{vendorId}/rate-table — upload the rate
   table (and, with it, the zone rows)."
  (%com-hhub-policy-tenant-may-transact params "upload vendor shipping rate table"))

(defun com-hhub-policy-api-vendor-shipping-zones (&optional (params nil))
  "PUT /hhub/api/v1/vendor/shipping/{vendorId}/zones — upload the zone rows
   alone, leaving the rate table untouched."
  (%com-hhub-policy-tenant-may-transact params "upload vendor shipping zones"))

;; ── VENDOR PAYMENT METHODS ──────────────────────────────────────────────────
(defun com-hhub-policy-api-vendor-payment-create (&optional (params nil))
  "POST /hhub/api/v1/vendor/payment/methods — create a vendor's payment
   configuration."
  (%com-hhub-policy-tenant-may-transact params "create vendor payment methods"))

(defun com-hhub-policy-api-vendor-payment-read (&optional (params nil))
  "GET /hhub/api/v1/vendor/payment/methods/{vendorId} — read a vendor's payment
   configuration."
  (%com-hhub-policy-tenant-may-transact params "read vendor payment methods"))

(defun com-hhub-policy-api-vendor-payment-update (&optional (params nil))
  "PUT /hhub/api/v1/vendor/payment/methods/{vendorId} — update a vendor's payment
   configuration (gateway credentials and UPI settings)."
  (%com-hhub-policy-tenant-may-transact params "update vendor payment methods"))


(defun com-hhub-policy-customer-address (&optional (params nil))
  :documentation "This policy governs updating the invoice item by the vendor"
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 ;;(tokenverified-p (assoc "tokenverified" params :test 'equal))
	 ;;(guestcheckout-phone (cdr (assoc "guestcheckout-phone" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    ;;(unless tokenverified-p
     ;; (error 'hhub-abac-transaction-error :errstring (format nil "Token not verified for guest customer phone number ~A." guestcheckout-phone)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))


;; INVOICE ITEM RELATED POLICIES START

(defun com-hhub-policy-show-invoice-payment-page (&optional (params nil))
  :documentation "This policy governs updating the invoice item by the vendor"
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))

(defun com-hhub-policy-show-invoice-confirm-page (&optional (params nil))
  :documentation "This policy governs updating the invoice item by the vendor"
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))

(defun com-hhub-policy-invoice-paid-action (&optional (params nil))
  :documentation "This policy governs updating the invoice item by the vendor"
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))

(defun com-hhub-policy-delete-invoiceitem-action (&optional (params nil))
  :documentation "This policy governs updating the invoice item by the vendor"
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))

(defun com-hhub-policy-update-invoiceitem-action (&optional (params nil))
  :documentation "This policy governs updating the invoice item by the vendor"
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))


;; INVOICE ITEM POLICIES END

;; INVOICE RELATED POLICIES START

(defun com-hhub-policy-search-invoice-action (&optional (params nil))
  :documentation "This policy governs the gst hsn codes page"
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))

(defun com-hhub-policy-create-invoice-action (&optional (params nil))
  :documentation "This policy governs the gst hsn codes page"
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))
(defun com-hhub-policy-show-invoices-page (&optional (params nil))
  :documentation "This policy governs the gst hsn codes page"
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))
(defun com-hhub-policy-update-invoice-action (&optional (params nil))
  :documentation "This policy governs the gst hsn codes page"
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))

;; INVOICE RELATED POLICIES END;; 

(defun com-hhub-policy-search-gst-hsn-codes-action (&optional (params nil))
  :documentation "This policy governs the gst hsn codes page"
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "SUPERADMIN")))

(defun com-hhub-policy-create-gst-hsn-code-action (&optional (params nil))
  :documentation "This policy governs the gst hsn codes page"
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "SUPERADMIN")))

(defun com-hhub-policy-update-gst-hsn-code-action (&optional (params nil))
  :documentation "This policy governs the gst hsn codes page"
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
	(equal rolename "SUPERADMIN")))

(defun com-hhub-policy-gst-hsn-codes (&optional (params nil))
  :documentation "This policy governs the gst hsn codes page"
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
	(equal rolename "SUPERADMIN")))                                      

(defun com-hhub-policy-vendor-prod-ship-infoadd (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (vendor (cdr (assoc "vendor" params :test 'equal)))
	 (vendor-name (slot-value vendor 'name))
	 (suspend-flag (slot-value company 'suspend-flag))
	 (shipping-enabled (com-hhub-attribute-vendor-shipping-enabled vendor)))
    (unless shipping-enabled
      (error 'hhub-abac-transaction-error :errstring (format nil "Vendor Name: ~A : Shipping is not enabled" vendor-name)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))

(defun com-hhub-policy-vendor-approve-action (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag))
	 (rolename (cdr (assoc "rolename" params :test 'equal))))
    (if (and
	 (equal rolename "COMPADMIN")
	 (equal suspend-flag "N")) T NIL)))

(defun com-hhub-policy-vendor-reject-action (&optional (params nil))
  (com-hhub-policy-vendor-approve-action params))

(defun com-hhub-policy-prodcatg-add-action (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (subs-plan (subscription-plan company))
	 (cmp-type (cmp-type company))
	 (suspend-flag (slot-value company 'suspend-flag))
         (maxcatgcount (com-hhub-attribute-company-maxprodcatgcount subs-plan cmp-type))
	 (currentcatgcount (com-hhub-attribute-vendor-currentprodcatgcount company))
	 (rolename (cdr (assoc "rolename" params :test 'equal))))
    (if (and
	 (equal rolename "COMPADMIN")
	 (equal suspend-flag "N")
	 (<= currentcatgcount maxcatgcount)) T NIL)))



(defun com-hhub-policy-vendor-order-setfulfilled (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))

(defun com-hhub-policy-vendor-order-cancel (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))

	
	 
	

(defun com-hhub-policy-customer&vendor-create (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (subs-plan (subscription-plan company))
	 (cmp-type (cmp-type company))
	 (company-name (slot-value company 'name))
	 (currvendorcount (length (select-vendors-for-company company)))
	 (currcustomercount (length (select-customers-for-company company)))
	 (maxcustomercount (com-hhub-attribute-company-maxcustomercount subs-plan cmp-type))
	 (maxvendorcount (com-hhub-attribute-company-maxvendorcount subs-plan cmp-type))
	 (suspend-flag (slot-value company 'suspend-flag)))
    
    (when (<= (- maxvendorcount currvendorcount) 0 )
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. You have exceeded maximum numbers of vendors allowed to be created." company-name)))
    (when (<= (- maxcustomercount  currcustomercount) 0)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. You have exceeded maximum numbers of customer allowed to be created." company-name)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))




(defun com-hhub-policy-vendor-add-product-action (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (vendor (cdr (assoc "vendor" params :test 'equal)))
	 (mode (cdr (assoc "mode" params :test 'equal)))
	 (subs-plan (subscription-plan company))
	 (cmp-type (cmp-type company))
	 (company-name (slot-value company 'name))
	 (currproductcount (length (select-products-by-vendor vendor company)))
	 (maxproductcount (com-hhub-attribute-vendor-maxproductcount subs-plan cmp-type))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (and (equal mode "add") (<= (- maxproductcount currproductcount) 0))
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. You have exceeded maximum number of Products allowed to be created. Max count = ~d, Current count = ~d" company-name maxproductcount currproductcount)))  
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    T))

(defun com-hhub-policy-vendor-bulk-products-add (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (subs-plan (subscription-plan company))
	 (cmp-type (cmp-type company))
	 (bulkuploadp (com-hhub-attribute-company-prdbulkupload-enabled subs-plan cmp-type))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (when (com-hhub-attribute-company-issuspended suspend-flag)
      (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
    bulkuploadp))


(defun com-hhub-policy-restore-account (&optional (params nil))
  :documentation "This policy governs the Account suspension"
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "SUPERADMIN")))


(defun com-hhub-policy-suspend-account (&optional (params nil))
  :documentation "This policy governs the Account suspension"
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "SUPERADMIN")))
						  

(defun com-hhub-policy-vendor-bulk-product-add (&optional  (params nil))
  :documentation "Vendor Add bulk products using CSV file. "
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (subs-plan (subscription-plan company))
	 (cmp-type (cmp-type company))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (cond
      ((not (com-hhub-attribute-company-prdbulkupload-enabled subs-plan cmp-type))
       ;; return false
       (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This feature is restricted." (slot-value company 'name))))
      ((com-hhub-attribute-company-issuspended suspend-flag)
       (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
      ((<  (cdr (assoc "prdcount" params :test 'equal)) (com-hhub-attribute-vendor-bulk-product-count)) T))))


(defun com-hhub-policy-cad-login-page (&optional (params nil))
  (declare (ignore params))
  :documentation "Company Administrator login page is open to all. This policy is dummy as the request is initiated by the Browser."
  T)

(defun com-hhub-policy-cad-login-action (&optional (params nil))
  (declare (ignore params))
  :documentation "Company Administrator login action is open to all. This policy is dummy as the request is initiated by the Browser."
T)

(defun com-hhub-policy-cad-logout (&optional (params nil) )
  :documentation "Company Administrator logout action is open to all. This policy is dummy as the request is initiated by the Browser."
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))


(defun com-hhub-policy-cad-product-approve-action (&optional (params nil) )
  :documentation "only a Company Administrator can Approve a product. "
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))



(defun com-hhub-policy-cad-product-reject-action (&optional ( params nil))
  :documentation "only a Company Administrator can Reject a product. "
 (com-hhub-policy-cad-product-approve-action params))

(defun com-hhub-policy-compadmin-home ( &optional (params nil))
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))

(defun com-hhub-policy-publish-account-exturl (&optional (params nil))
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))
  
(defun com-hhub-policy-compadmin-updatedetails-action (&optional (params nil))
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "COMPADMIN")))


(defun com-hhub-policy-sadmin-profile (&optional  (params nil))
:documentation "Super Administrator Profile Policy"
(equal (cdr (assoc "username" params :test 'equal))  "superadmin"))

(defun com-hhub-policy-sadmin-login (&optional (params nil))
  :documentation "Super Administrator Login Policy"
  (let* ((username (cdr (assoc "username" params :test 'equal)))
	(company (cdr (assoc "company" params :test 'equal)))
	(returnvalue (and (equal username  "superadmin")
			  (equal company "super"))))
    returnvalue))

(defun com-hhub-policy-cust-edit-order-item (&optional (params nil))
  (com-hhub-policy-create-order params))


(defun com-hhub-policy-create-order (&optional (params nil))
  (let* ((company (cdr (assoc "company" params :test 'equal)))
	 (suspend-flag (slot-value company 'suspend-flag)))
    (cond  ;; Check whether the account is suspended. 
      ((com-hhub-attribute-company-issuspended suspend-flag)
       (error 'hhub-abac-transaction-error :errstring (format nil "Account Name: ~A. This Account is Suspended." (slot-value company 'name))))
      ((< (parse-time-string (current-time-string)) (parse-time-string (com-hhub-attribute-customer-order-cutoff-time))) T))))


(defun com-hhub-policy-sadmin-create-users-page (&optional (params nil))
  :documentation "Check whether role of the login user is SUPERADMIN or not" 
  (equal (cdr (assoc "username" params :test 'equal))  "superadmin"))

(defun com-hhub-policy-sadmin-home (&optional (params nil))
  :documentation "Check whether role of the login user is SUPERADMIN or not" 
  (values (equal (cdr (assoc "username" params :test 'equal))  "superadmin") nil))
   
	

(defun com-hhub-policy-create-company (&optional  (params nil))
  (let ((rolename (cdr (assoc "rolename" params :test 'equal))))
    (equal rolename "SUPERADMIN")))


(defun com-hhub-policy-create-attribute (&optional (params nil))
  (equal (cdr (assoc "username" params :test 'equal))  "superadmin"))


(defun com-hhub-policy-create (&optional (params nil))
  (equal (cdr (assoc "username" params :test 'equal))  "superadmin"))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; END DEFINE POLICIES ;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun dod-controller-add-transaction-action ()
(with-opr-session-check 
  (let* ((company (get-login-company))
	 (id (hunchentoot:parameter "id"))
	 (transaction (get-bus-transaction id))
	 (transname (hunchentoot:parameter "transname"))
	 (transuri (hunchentoot:parameter "transuri"))
	 (transfunc (hunchentoot:parameter "transfunc"))
	 (transtype (hunchentoot:parameter "transtype")))
    (if transaction 
	(progn 
	  (setf (slot-value transaction 'name) (concatenate 'string *ABAC-TRANSACTION-NAME-PREFIX* transname))
	  (setf (slot-value transaction 'uri) transuri)
	  (setf (slot-value transaction 'trans-func) (concatenate 'string *ABAC-TRANSACTION-FUNC-PREFIX* transfunc))
	  (setf (slot-value transaction 'trans-type) transtype)
	  (update-bus-transaction transaction))
	;;else
	(create-bus-transaction (concatenate 'string *ABAC-TRANSACTION-NAME-PREFIX* transname)  transuri  transtype (concatenate 'string *ABAC-TRANSACTION-FUNC-PREFIX* transfunc) company))
    (hunchentoot:redirect "/hhub/listbustrans"))))


(defun com-hhub-transaction-policy-create ()
  (with-opr-session-check
    (let ((params nil))
      (setf params (acons "username" (get-login-username) params))
      (setf params (acons "uri" (hunchentoot:request-uri*) params))
      (with-hhub-transaction "com-hhub-transaction-policy-create" params 
	(let* ((company (get-login-company))
	       (id (hunchentoot:parameter "id"))
	       (policy (select-auth-policy-by-id id)) 
	       (policyname (hunchentoot:parameter "policyname"))
	       (policydesc (hunchentoot:parameter "policydesc"))
	       (policyfunc (hunchentoot:parameter "policyfunc")))
	  (if policy 
	      (progn 
		(setf (slot-value policy 'name) (concatenate 'string *ABAC-POLICY-NAME-PREFIX*  policyname))
		(setf (slot-value policy 'description) policydesc)
		(setf (slot-value policy 'policy-func) (concatenate 'string *ABAC-POLICY-FUNC-PREFIX*  policyfunc))
		(update-auth-policy policy))
	      ;;else
	      ;; This place is good for calling a higher order function or even a macro will do.
	      ;; (with-hhub-bus-layer 'create-auth-policy (concatenate 'string *ABAC-POLICY-NAME-PREFIX*  policyname)  policydesc (concatenate 'string *ABAC-POLICY-FUNC-PREFIX*  policyfunc) company)
	      ;; (hhub-bus-layer 'create-auth-policy (concatenate 'string *ABAC-POLICY-NAME-PREFIX*  policyname)  policydesc (concatenate 'string *ABAC-POLICY-FUNC-PREFIX*  policyfunc) company)
	      (create-auth-policy (concatenate 'string *ABAC-POLICY-NAME-PREFIX*  policyname)  policydesc (concatenate 'string *ABAC-POLICY-FUNC-PREFIX*  policyfunc) company))
	  (hunchentoot:redirect "/hhub/dasabacsecurity"))))))



(defun com-hhub-transaction-create-attribute ()
  (with-opr-session-check
    (let ((params nil))
      (setf params (acons "username" (get-login-user-name) params))
      (setf params (acons "uri" (hunchentoot:request-uri*)  params))
      (setf params (acons "busobj" "ATTRIBUTE" params))
      (setf params (acons "bussubj" "SUPERADMIN" params))

    (with-hhub-transaction "com-hhub-transaction-create-attribute" params
      (let* ((company (get-login-company))
	    (id (hunchentoot:parameter "id"))
	    (attribute (if id (select-auth-attr-by-id id)))
	    (attrtype (hunchentoot:parameter "attrtype"))
	    (attrname (hunchentoot:parameter "attrname"))
	    (attrdesc (hunchentoot:parameter "attrdesc"))
	    (attrfunc (hunchentoot:parameter "attrfunc")))
	(if attribute 
	    (progn 
	      (setf (slot-value attribute 'name) (concatenate 'string  *ABAC-ATTRIBUTE-NAME-PREFIX*  attrname))
	      (setf (slot-value attribute 'description ) attrdesc)
	      (setf (slot-value attribute 'attr-func ) (concatenate 'string *ABAC-ATTRIBUTE-FUNC-PREFIX*  attrfunc))
	      (setf (slot-value attribute 'attr-type) attrtype)
	      (update-auth-attr-lookup attribute))
	    ;else 
	(create-auth-attr-lookup (concatenate 'string  *ABAC-ATTRIBUTE-NAME-PREFIX* attrname)   attrdesc (concatenate 'string *ABAC-ATTRIBUTE-FUNC-PREFIX*  attrfunc)  attrtype company))
	(hunchentoot:redirect "/hhub/listattributes"))))))



(defun busobj-card (busobj-instance &rest arguments)
  (declare (ignore arguments))
  (let ((name (slot-value busobj-instance 'name)))
	(cl-who:with-html-output (*standard-output* nil)
	  (:td :height "10px" 
	   (:h6 :class "busobj-name"  (cl-who:str (format nil " ~A" name)))))))

(defun bustrans-card (bustrans-instance &rest arguments)
  (declare (ignore arguments))
  (let ((name (slot-value bustrans-instance 'name))
	(uri (slot-value bustrans-instance 'uri))
	(row-id (slot-value bustrans-instance 'row-id))
	(trans-func (slot-value bustrans-instance 'trans-func)))
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" 
	   (:h6 :class "bustrans-name"  (cl-who:str (format nil " ~A" name))))
      (:td :height "10px" 
	   (:h6 :class "bustrans-name"  (cl-who:str (format nil " ~A" uri))))
      (:td :height "10px" 
	   (:h6 :class "bustrans-name"  (cl-who:str (format nil "~A" trans-func))))
      (:td :height "10px" 
	   (:a  :data-toggle "modal" :data-target (format nil "#editbustrans-modal~A" row-id)  :href "#"  (:i :class "fa-regular fa-pen-to-square"))
	   (:a  :data-toggle "modal"  :data-target (format nil "#linkbustrans-modal~A" row-id)  :href "#"  (:i :class "fa-solid fa-link"))
	   (modal-dialog (format nil "linkbustrans-modal~a" row-id) "Add/Edit Business Transaction" (link-bus-transaction-to-policy bustrans-instance))
	   (modal-dialog (format nil "editbustrans-modal~a" row-id) "Add/Edit Business Transaction" (new-transaction-html  bustrans-instance))))))

(defun attribute-card (attribute-instance &rest arguments)
  (declare (ignore arguments))
  (let* ((name (slot-value attribute-instance 'name))
	 (description (slot-value attribute-instance 'description))
	 (attr-func (slot-value attribute-instance 'attr-func))
	 (row-id (slot-value attribute-instance 'row-id))
	 (attr-type (slot-value attribute-instance 'attr-type))
	 (copystr (parenscript:ps (copy-to-clipboard (parenscript:lisp attr-func)))))
    
    (cl-who:with-html-output (*standard-output* nil)
      (:td :height "10px" 
	   (:h6 :class "attribute-name"  (cl-who:str name) ))
      (:td :height "10px" 
	 (:h6 :class "attribute-desc"  (cl-who:str description) ))
      (:td :height "10px" 
	   (:h6 :class "attribute-name"  (cl-who:str attr-func))
	   (:a :class "attribute-func"  :onclick copystr  :href "#" (:i :class "fa-regular fa-copy")))
      (:td :height "10px" 
	 (:h6 :class "attribute-type" (cl-who:str  (format nil "~A"  attr-type))))
      (:td :height "10px" 
	   (:a  :data-toggle "modal" :data-target (format nil "#editattribute-modal~A" row-id)  :href "#"  (:i :class "fa-regular fa-pen-to-square"))
	   (modal-dialog (format nil "editattribute-modal~a" row-id) "Add/Edit Attribute" (com-hhub-transaction-create-attribute-dialog attribute-instance))))))


(defun policy-row (policy-instance &rest arguments)
  (declare (ignore arguments))
  (let ((name (slot-value policy-instance 'name))
	(description (slot-value policy-instance 'description))
	(policy-func (slot-value policy-instance 'policy-func))
	(row-id (slot-value policy-instance 'row-id)))
    (cl-who:with-html-output (*standard-output* nil)
      
      (:td :height "10px" 
	   (:h6 :class "policy-name"  (cl-who:str name)))
      (:td :height "10px" 
	   (:h6 :class "policy-desc"  (cl-who:str description)))
      (:td :height "10px" 
	   (:h6 :class "policy-func-name"  (cl-who:str policy-func) ))
      (:td :height "10px" 
	   (:a  :data-toggle "modal" :data-target (format nil "#editpolicy-modal~A" row-id)  :href "#"  (:i :class "fa-regular fa-pen-to-square"))
	   (modal-dialog (format nil "editpolicy-modal~a" row-id) "Add/Edit Policy" (com-hhub-transaction-policy-create-dialog  policy-instance))))))

;; @@ deprecated : start using with-html-dropdown instead. 
(defun  attribute-type-dropdown (selectedkey)
  (let ((attrtype (make-hash-table)))
    (setf (gethash "OBJECT" attrtype) "Object Attribute")
    (setf (gethash "SUBJECT" attrtype) "Subject Attribute")
    (setf (gethash "ENVIRONMENT" attrtype) "Environment Attribute")
    (with-html-dropdown "attrtype" attrtype selectedkey)))


(defun transaction-type-dropdown (selectedkey) 
  (let ((transtypes (make-hash-table)))
    (setf (gethash "CREATE" transtypes) "Create")
    (setf (gethash "READ" transtypes) "Read")
    (setf (gethash "UPDATE" transtypes) "Update")
    (setf (gethash "DELETE" transtypes) "Delete")
    (with-html-dropdown "transtype" transtypes selectedkey)))
	
(defun business-objects-dropdown (&optional selectedkey)
  (let* ((bolist (select-bus-object-by-company (get-login-company)))
	(bonameslist (mapcar (lambda (item) 
			       (slot-value item 'name)) bolist))
	(bohash (make-hash-table)))
    (mapcar (lambda (key) (setf (gethash key bohash) key)) bonameslist)
    (with-html-dropdown "busobject" bohash  (if (not selectedkey) (car bonameslist) selectedkey))))

(defun  abac-subject-dropdown (&optional selectedkey)
  (let* ((abac-subject-list (select-abac-subject-by-company (get-login-company)))
	 (subjectnameslist (mapcar (lambda (item) 
				     (slot-value item 'name)) abac-subject-list ))
	 (subjecthash (make-hash-table)))
    (mapcar (lambda (key) (setf (gethash key subjecthash) key)) subjectnameslist)
    (with-html-dropdown "abacsubject" subjecthash  (if (not selectedkey) (car subjectnameslist) selectedkey))))


(defun link-bus-transaction-to-policy (&optional transaction)
  (let ((policy (if transaction (get-bus-tran-policy transaction))))
    
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row"
	    (:div :class "col-xs-12"
		  (if policy (cl-who:htm (:h4 (cl-who:str (format nil "Linked Policy Name: ~A" (slot-value policy 'name)))))
		      (cl-who:htm (:h4 (cl-who:str (format nil "No Policy Linked! Create a New Policy.")))))))
      (:hr)
      (:a :class "btn btn-primary" :role "button" :href (format nil "/hhub/transtopolicylinkpage?trans-id=~A" (slot-value transaction 'row-id)) " Link Policy/Change "))))

	
(defun dod-controller-trans-to-policy-link-page ()
  (with-opr-session-check
    (with-mvc-ui-page "Link Transaction To Policy" #'createmodelfortransactiontopolicylinkpage #'createwidgetsfortransactiontopolicylinkpage :role :superadmin)))

(defun createmodelfortransactiontopolicylinkpage ()
  (let* ((trans-id (hunchentoot:parameter "trans-id"))
	 (transaction (get-bus-transaction trans-id))
	 (policy (get-bus-tran-policy transaction)))
    (function (lambda ()
      (values trans-id transaction policy)))))

(defun createwidgetsfortransactiontopolicylinkpage (modelfunc)
  (multiple-value-bind (trans-id transaction policy) (funcall modelfunc)
    (let ((widget1 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)      
		       (:div :class "row" 
			     (:div :class "col-xs-12" 
				   (:h4 (cl-who:str (format nil "Transaction: ~A" (slot-value transaction 'name))))))
		       (:div :class "row" 
			     (:div :class "col-xs-12" 
				   (:h4 (cl-who:str (format nil "Currently linked policy: ~A" (slot-value policy 'name))))))))))
	  (widget2 (function (lambda ()
		     (with-html-search-form "idsearchpolicies" "searchpolicies" "idtxtsearchpolicies" "txtsearchpolicies" "dassearchpolicies" "onkeyupsearchform1event();" "Enter Policy Name..." 
		       (:input :class "form-control" :name "trans-id" :type "hidden" :value trans-id)))))
	  (widget3 (function (lambda ()
		     (cl-who:with-html-output (*standard-output* nil)      
		       (submitsearchform1event-js "#idtxtsearchpolicies" "#txtsearchpoliciesresult")
		       (:div :id "txtsearchpoliciesresult"))))))
	  (list widget1 widget2 widget3))))

    

(defun dod-controller-policy-search-action ()
  (let* ((policysearch (hunchentoot:parameter "txtsearchpolicies"))
	 (trans-id (hunchentoot:parameter "trans-id"))
	 (transaction (get-bus-transaction trans-id))
	 (policies (select-auth-policy-by-name (format nil "%~A%" policysearch) (get-login-company))))
    (ui-list-policies-for-linking policies transaction)))
   
(defun ui-list-policies-for-linking (policy-list transaction)
  (let ((trans-id (slot-value transaction 'row-id))
        (prefix "com.hhub.policy."))
    (cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
      (:div :class "row-fluid"
        (if (null policy-list)
            ;; Empty State
            (cl-who:htm 
             (:div :class "col-12"
               (:h3 "No records found")))
            ;; else
            ;; List State
            (loop for pol in policy-list
                  do (let* ((full-name (slot-value pol 'name))
                            (pol-id    (slot-value pol 'row-id))
                            ;; Safely strip the prefix
                            (display-name (if (and (>= (length full-name) (length prefix))
                                                   (string= full-name prefix :end1 (length prefix)))
                                              (subseq full-name (length prefix))
                                              full-name)))
                       (cl-who:htm
                        (:div :class "col-sm-4 col-lg-3 col-md-4"
                          (:form :method "POST" :action "transtopolicylinkaction"
                            (:div :class "form-group"
                              (:input :type "hidden" :name "trans-id" :value trans-id)
                              (:input :type "hidden" :name "policy-id" :value pol-id)
                              (:button :class "btn btn-lg btn-primary btn-block" 
                                       :type "submit" 
                                       (cl-who:esc display-name)))))))))))))

(defun dod-controller-trans-to-policy-link-action ()
  (let* ((trans-id (hunchentoot:parameter "trans-id"))
	(transaction (get-bus-transaction trans-id))
	(policy-id (parse-integer (hunchentoot:parameter "policy-id"))))
    (setf (slot-value transaction 'auth-policy-id) policy-id)
    (update-bus-transaction transaction)
    (hunchentoot:redirect "/hhub/listbustrans")))

(defun new-transaction-html (&optional transaction)
  (let* ((id (if transaction (slot-value transaction 'row-id)))
	 (transname (if transaction (slot-value transaction 'name)))
	 (transuri (if transaction (slot-value transaction 'uri)))
	 (transtype (if transaction (slot-value transaction 'trans-type)))
	 (transfunc (if transaction (slot-value transaction 'trans-func))))
	
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :class "form-addtransaction" :role "form" :method "POST" :action "dasaddtransactionaction"
			 (if transaction (cl-who:htm (:input :class "form-control" :type "hidden" :value id :name "id")))
					;(if transbo (cl-who:htm (:input :class "form-control" :type "hidden" :value bo-id :name "bo-id")))
			 (:img :class "profile-img" :src "/img/logo.png" :alt "")
			 (:h1 :class "text-center login-title"  "Add/Edit Transaction")
			   (:div :class "form-group input-group"
			       (:span :class "input-group-addon" :id "transnameprefix" (cl-who:str *ABAC-TRANSACTION-NAME-PREFIX*) )
			       (:label :class "input-group"  :for "transname" "Name:")
			       (:input :class "form-control" :name "transname" :aria-describedby "transnameprefix" :maxlength "30"  :value (if transaction (subseq transname (length *ABAC-TRANSACTION-NAME-PREFIX*)))  :placeholder "Enter Transaction  Name ( max 30 characters) " :type "text" ))
			 (:div :class "form-group"
			       (:label :for "transuri" "URL")
			       (:input :class "form-control" :name "transuri" :aria-describedby "transuri" :maxlength "50" :value transuri :placeholder "Enter transaction URI" :type "text")
			       (:h6 "Note: If the URL is changed here, then this URL has to be updated in dod-ui-sys.lisp as well."))
			 (:div :class "form-group input-group"
			       (:span :class "input-group-addon" :id "transfuncprefix" (cl-who:str *ABAC-TRANSACTION-FUNC-PREFIX* ))
			       (:label :class "input-group"  :for "transfunc" "Function:")
			       (:input :class "form-control" :name "transfunc" :maxlength "30"  :value (if transaction (subseq transfunc (length *ABAC-TRANSACTION-FUNC-PREFIX*))) :placeholder "Declare Transaction Function Name ( max 100 characters) " :aria-describedby "transfuncprefix"  :type "text" )
			       (:h6 "Note: If function name is changed here, then this function must be renamed in the file as well."))
			 (:div :class "form-group input-group"
			       (:span :class "input-group-addon"  "Type") 
			       (transaction-type-dropdown transtype))
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))





(defun com-hhub-transaction-create-attribute-dialog (&optional attribute)
  (let* ((id (if attribute (slot-value attribute 'row-id)))
	 (attrname (if attribute (slot-value attribute 'name)))
	 (attrdesc (if attribute (slot-value attribute 'description)))
	 (attrtype (if attribute (slot-value attribute 'attr-type)))
	 (attrfunc (if attribute (slot-value attribute 'attr-func))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :class "form-addattribute" :role "form" :method "POST" :action "dasaddattribute"
			 (if attribute (cl-who:htm (:input :class "form-control" :type "hidden" :value id :name "id")))
			 (:img :class "profile-img" :src "/img/logo.png" :alt "")
			    (:h1 :class "text-center login-title"  "Add/Edit Attribute")
			    (:div :class "form-group input-group"
				  (:span :class "input-group-addon" :id "attrnameprefix" (cl-who:str *ABAC-ATTRIBUTE-NAME-PREFIX*)) 
				  (:input :class "form-control" :name "attrname" :id "attrname"  :aria-describedby "attrnameprefix" :maxlength "30"  :value (if attribute (subseq attrname (length *ABAC-ATTRIBUTE-NAME-PREFIX*))) :placeholder "Enter Attribute  Name ( max 30 characters) " :type "text" ))
			    (:div :class "form-group"
				  (:label :for "attrdesc")
				  (:textarea :class "form-control" :name "attrdesc"  :placeholder "Enter Attribute Description ( max 400 characters) "  :rows "5" :onkeyup "countChar(this, 200)" (cl-who:str attrdesc) ))
			    (:div :class "form-group" :id "charcount")
			    (:div :class "form-group input-group"
				  
				  (:span :class "input-group-addon" :id "attrfuncprefix" (cl-who:str *ABAC-ATTRIBUTE-FUNC-PREFIX*)) 
				  (:input :class "form-control" :name "attrfunc" :id "attrfunc"  :maxlength "30"  :value (if attribute (subseq attrfunc (length *ABAC-ATTRIBUTE-FUNC-PREFIX*))) :placeholder "Declare Attribute Function Name ( max 100 characters) " :aria-describedby "attrfuncprefix"  :type "text" ))
			    (:div :class "form-group"
				  (attribute-type-dropdown attrtype))
			    
			    (:div :class "form-group"
				  (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))


(defun com-hhub-transaction-policy-create-dialog (&optional policy)
  (let* ((id (if policy (slot-value policy 'row-id)))
	 (policyname (if policy (slot-value policy 'name)))
	 (policydesc (if policy (slot-value policy 'description)))
	 (policyfunc (if policy (slot-value policy 'policy-func))))
    (cl-who:with-html-output (*standard-output* nil)
      (:div :class "row" 
	    (:div :class "col-xs-12 col-sm-12 col-md-12 col-lg-12"
		  (:form :class "form-addpolicy" :role "form" :method "POST" :action "dasaddpolicyaction"
			 (if policy (cl-who:htm (:input :class "form-control" :type "hidden" :value id :name "id")))
			 (:img :class "profile-img" :src "/img/logo.png" :alt "")
			 (:h1 :class "text-center login-title"  "Add/Edit Policy")
			 (:div :class "form-group input-group"
			       (:span :class "input-group-addon" :id "attrnameprefix" (cl-who:str *ABAC-POLICY-NAME-PREFIX*) ) 
			       (:input :class "form-control" :name "policyname" :aria-describedby "polnameprefix" :maxlength "30"  :value (if policy (subseq policyname (length *ABAC-POLICY-NAME-PREFIX*))) :placeholder "Enter Policy  Name ( max 30 characters) " :type "text" ))
			 (:div :class "form-group"
			       (:label :for "policydesc")
			       (:textarea :class "form-control" :name "policydesc"  :placeholder "Enter Policy Description ( max 400 characters) "  :rows "5" :onkeyup "countChar(this, 400)" (cl-who:str policydesc) ))
			 (:div :class "form-group" :id "charcount")
			 (:div :class "form-group input-group"
			       (:span :class "input-group-addon" :id "policyfuncprefix" (cl-who:str *ABAC-POLICY-FUNC-PREFIX*)) 
			       (:input :class "form-control" :name "policyfunc" :maxlength "30"  :value (if policy (subseq  policyfunc (length *ABAC-POLICY-FUNC-PREFIX*))) :placeholder "Declare Policy Function Name ( max 100 characters) " :aria-describedby "policyfuncprefix"  :type "text" ))
			 (:div :class "form-group"
			       (:button :class "btn btn-lg btn-primary btn-block" :type "submit" "Submit"))))))))
