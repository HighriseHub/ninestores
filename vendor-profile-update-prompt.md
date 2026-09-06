# Task: Build the tabbed "Update Vendor Profile" page (mirror of the customer profile work)

Implement a tabbed vendor-profile edit page exactly the way the customer profile
page was done. The customer implementation is the reference and lives at the end of
`hhub/customer/dod-ui-cus.lisp` (from the `customer-businesstype-ht` section to
`create-widgets-for-customer-profile-page`). Read it first and mirror its structure,
naming, and comments. Do not modify the customer code.

## Files you will touch

- `hhub/vendor/dod-ui-ven.lisp` — new hash tables, field map, page functions (append at end).
- `hhub/vendor/templates/vendorprofile.html` — NEW tabbed HTML template.
- `hhub/core/dod-ini-sys.lisp` — template loader + startup wiring.
- `hhub/sysuser/dod-ui-sys.lisp` — route registration (only if needed, see Step 5).
- `hhub/vendor/dod-bl-ven.lisp` or the vendor UI file — extend the update action handler (Step 5).

Domain facts: vendor class is `dod-vend-profile` in `hhub/vendor/dod-dal-ven.lisp` (line 188).
Session helpers `get-login-vendor`, `get-login-vendor-id`, `get-login-vendor-company`,
`get-login-vendor-tenant-id` and the `with-vend-session-check` macro exist in
`hhub/vendor/dod-ui-ven.lisp` / `hhub/core/dod-ui-utl.lisp`. Persistence helper:
`update-vendor-details` (`hhub/vendor/dod-bl-ven.lisp` line 283). UI macros to reuse:
`with-mvc-ui-page` (role `:vendor`), `with-html-dropdown`, `with-html-form-having-submit-event`,
`extract-html-between-markets`.

## Step 1 — Dropdown hash tables (append to `dod-ui-ven.lisp`)

One `defvar <name>-ht (make-hash-table :test 'equal)` + one `(defun init-<name>-ht () ...)`
per dropdown, exactly like `customer-businesstype-ht` / `init-customer-businesstype-ht`.
Create these dropdowns (guess the enum keys yourself, anchored on the `:void-value`
defaults in `dod-dal-ven.lisp` and the value sets already used in
`nst-ui-warehouse.lisp` / `dod-ui-cus.lisp`):

1. `vendor-gstregistrationtype-ht` / `init-vendor-gstregistrationtype-ht` — slot `gst-registration-type` (void "REGULAR"). Reuse the customer set (REGULAR, COMPOSITION, SEZ, CASUAL, ISD, UNREGISTERED).
2. `vendor-gstfilingfrequency-ht` / `init-vendor-gstfilingfrequency-ht` — slot `gst-filing-frequency` (void "MONTHLY"). e.g. MONTHLY, QUARTERLY, ANNUAL.
3. `vendor-paymentgatewaymode-ht` / `init-vendor-paymentgatewaymode-ht` — slot `payment-gateway-mode`. e.g. TEST, LIVE.
4. `vendor-approvalstatus-ht` / `init-vendor-approvalstatus-ht` — slot `approval-status` (void "PENDING"). e.g. PENDING, APPROVED, REJECTED, SUSPENDED.

Add an aggregator `(defun init-vendor-profile-data () ...)` calling all four inits,
mirroring `init-customer-profile-data`.

## Step 2 — `*vendor-profile-field-map*` (append to `dod-ui-ven.lisp`)

A `defparameter` alist of `(slot . "%Vendor ...% placeholder")` covering EVERY slot of
`dod-vend-profile`: row-id, name, address, phone, email, firstname, lastname,
salutation, title, birthdate, city, state, country, zipcode, gstnumber, picture-path,
password, salt, payment-gateway-mode, payment-api-key, payment-api-salt, active-flag,
suspend-flag, upi-id, approved-flag, approval-status, approved-by,
push-notify-subs-flag, email-add-verified, shipping-enabled, deleted-state,
invoice-settings, legal-name, trade-name, pan-number, gst-state-code,
gst-registration-type, gst-filing-frequency, fy-start-month, tenant-id, and the
`company` join. Use `%Vendor Type%`-style placeholders; slots absent from the template
are harmless no-ops but keep the map complete.

## Step 3 — Tabbed template `hhub/vendor/templates/vendorprofile.html` (NEW)

Copy the structure of `hhub/customer/templates/customerprofile.html`: Bootstrap 5.3.3
CDN, `nav-tabs` (Basic Info, Company & GST, Financial Terms, Bank Details), one
`tab-pane` per tab, form inputs whose `name` attributes match the slot names, and the
exact same two marker comments around the form content:
`<!--VENDOR_PROFILE_FORM_BEGIN-->` / `<!--VENDOR_PROFILE_FORM_END-->` (the customer
model extracts between these markers). Use `%Vendor ...%` placeholders for values and
`%Vendor ...%` placeholders for the four dropdowns above; hidden input `cid` for
`%Vendor ID%`; a submit button inside the markers. Keep styling minimal (the page
shell already loads Bootstrap).

## Step 4 — Page functions (append to `dod-ui-ven.lisp`)

- `(defun com-nst-transaction-vendor-profile-page () ...)` — `with-vend-session-check`
  wrapping `(with-mvc-ui-page "Update vendor profile" #'create-model-for-vendor-profile-page
  #'create-widgets-for-vendor-profile-page :role :vendor)`.
- `create-model-for-vendor-profile-page` — mirror `create-model-for-customer-profile-page`:
  subject is `(get-login-vendor)`; load the template via a new
  `(nst-get-cached-vendor-template-func :templatenum 1)`; extract the marker fragment;
  `dolist` over `*vendor-profile-field-map*`; the four dropdown placeholders get
  `with-html-dropdown` output (names `gstregistrationtype`, `gstfilingfrequency`,
  `paymentgatewaymode`, `approvalstatus`), everything else `regex-replace-all` with
  `princ-to-string` (or "" when nil); return `(values form-snippet action)`.
- `create-widgets-for-vendor-profile-page` — mirror `create-widgets-for-customer-profile-page`:
  wrap the fragment in `with-html-form-having-submit-event "vendorprofileform" action`.

## Step 5 — Wiring and update action

- `hhub/core/dod-ini-sys.lisp`: add `(defvar *NST-VENDOR-PROFILE-TEMPLATEFILE*
  "/home/ubuntu/ninestores/hhub/vendor/templates/vendorprofile.html")`; add
  `nst-load-vendor-templates` / `nst-get-cached-vendor-template-func` mirroring the
  customer ones (a single template, `templatenum 1`); call the loader in the init
  sequence; add `(init-vendor-profile-data)` right after `(init-customer-profile-data)`.
- Update action: the form POSTs to `action`. Reuse an existing registered vendor update
  action if one exists (grep the `create-regex-dispatcher` list in
  `hhub/sysuser/dod-ui-sys.lisp`); otherwise register a new one and add a handler that
  reads every posted parameter, `setf`s the matching `dod-vend-profile` slots on
  `(get-login-vendor)`, calls `update-vendor-details`, and redirects to
  `/hhub/dodvendprofile`.
- Route: point the existing `/hhub/dodvendprofile` dispatcher (currently
  `dod-controller-vend-profile`) at `com-nst-transaction-vendor-profile-page`, or
  register a new route — pick whichever keeps the old page reachable during testing.

## Verification checklist

1. Paren balance on both edited lisp files; no duplicate definitions
   (`grep -rn "vendor-profile-field-map\|com-nst-transaction-vendor-profile-page"`).
2. The 4 dropdown placeholders in the template are exactly the 4 handled in the model.
3. Model: every placeholder in the template has a matching entry in the field map.
4. With a logged-in vendor, GET the route: tabs render, dropdowns show stored values
   selected, inputs pre-populated; POST persists and redirects.
