;;; invoicesettings.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defparameter *invoice-settings*
  '((invoice-print-settings
      (default-paper-size "A4")
      (orientation "portrait")
      (font-size 12)
      (margin
        (top "1cm")
        (bottom "1cm")
        (left "1cm")
        (right "1cm"))
      (header
        (enable t)
        (text "Company Name - Invoice")
        (logo-path "/assets/logo.png"))
      (footer
        (enable t)
        (text "Thank you for your business!"))
      (watermark
        (enable nil)
        (text "")))

    (invoice-general-settings
      ;; ── THE INVOICE NUMBER'S SHAPE, NOW THE SAME SHAPE AS THE ORDER'S (2026-10-12) ──────────
      ;; Was "INV-YYYY-MM-{counter}" — a month-stamped number with no issuer identity and no
      ;; financial-year series. It is now <prefix>-<fy>-<counter>, rendered by nst-format-doc-number
      ;; and allocated by nst-invoice-number-for (core/dod-bl-utl.lisp): the VENDOR's DOC_PREFIX
      ;; (DOD_VEND_PROFILE, its own column), the April–March financial year, and a padded counter
      ;; scoped per (vendor, financial year).
      ;;
      ;; 🚨 {counter} IS KEPT, AND THAT IS THE ONE PLACE THIS DOCUMENT DELIBERATELY DIFFERS FROM THE
      ;; ORDER. An ORDER uses {ref:6}, a keyed NON-SEQUENTIAL reference, because a sequential one
      ;; would tell every vendor how many orders its customer placed with its COMPETITORS (the F1
      ;; decision record, order-adhara-stories-CONTEXT.md §10). AN INVOICE IS THE OPPOSITE CASE: GST
      ;; wants a CONSECUTIVE serial for the financial year, and a non-sequential number is exactly
      ;; what a tax invoice must NOT have. So the invoice stays consecutive on purpose — do not
      ;; "harmonise" it with the order's {ref:6} without deciding that trade explicitly, because it
      ;; trades a tax-compliance property for a privacy one that the invoice does not need (a
      ;; vendor's own invoice count is not a competitor's secret).
      ;;
      ;; {ref:N} remains available in the token vocabulary, so a vendor who ever wants opacity on
      ;; invoices can have it as a DATA change to this string.
      ;;
      ;; ⚠ THE COUNTER NOW EXISTS, so {counter} is no longer aspirational: it used to have no backing
      ;; store at all (the "counter that {counter} never had"), and DOD_DOC_COUNTER — added for the
      ;; order series — is that store.
      ;;
      ;; ⚠ AND A MYSQL TRIGGER STILL OVERWRITES INVNUM ON INSERT (PENDING-WORK §1d). The
      ;; application's number is therefore written by an UPDATE immediately after the INSERT, in the
      ;; same transaction; nst-invh's make carries the full note.
      ;; ⚠ {counter:6} CARRIES AN EXPLICIT WIDTH, AND WITHOUT IT THE SERIES DOES NOT SORT. An
      ;; UNBRACED token (bare YYYY / MM) is substituted with width NIL = NO PADDING
      ;; (nst-doc-number-pad's `((null width) value)` branch), so a plain {counter} would render 1,
      ;; 2, … 10 and "…-10" would sort BEFORE "…-2". The width is what makes a text column behave
      ;; like a series, and {ref:N} reads its width from the template for the same reason.
      (invoice-number-format "INV-{prefix}-{fy}-{counter:6}")
      ;; The ORDER number's shape, alongside the invoice's — one vocabulary, two
      ;; document types with OPPOSITE legal requirements.
      ;; The tokens are rendered by nst-format-doc-number (core/dod-bl-utl.lisp).
      (order-number-format "ORD-{prefix}-{fy}-{ref:6}")
      (default-currency "USD")
      (date-format "MM/DD/YYYY")
      (time-zone "America/New_York")
      (enable-terms-and-conditions t)
      (default-terms-and-conditions "All sales are final. No refunds.")
      (enable-discounts t)
      (default-discount-rate 5))

    (invoice-email-settings
      (send-email-after-generation t)
      (email-subject-template "Your Invoice #{invoice_number}")
      (email-body-template
        "Dear {customer_name},\n\nPlease find your invoice attached.\nThank you for your business!")
      (cc-email-addresses ())
      (attach-invoice-as-pdf t))

    (invoice-customer-settings
      (allow-customer-specific-discounts t)
      (customer-default-tax-rate 8.5)
      (notify-customer-before-due-date t)
      (notify-customer-via-whatsapp t)
      (default-due-date "7 days from invoice generation"))

    (invoice-discounts-and-tax-settings
      (default-discount
        (enable t)
        (rate 10)
        (description "Loyalty Discount"))
      (default-tax
        (enable t)
        (tax-rates
          ((name "Sales Tax") (rate 8.5))
          ((name "Service Tax") (rate 12.0)))))

    (invoice-sharing-settings
      (enable-whatsapp-button t)
      (enable-live-links t)
      (live-link-expiration-days 30)
      (qr-code-settings
        (enable t)
        (size "150px"))
      (enable-social-sharing-buttons t))

    (live-invoice-settings
      (allow-live-edits nil)
      (password-protect-links t)
      (enable-live-tracking t)
      (notify-on-link-access t))

    (invoice-pdf-settings
      (optimize-pdf-for-size t)
      (add-password-protection nil)
      (embed-company-logo-in-pdf t)
      (pdf-footer-text "Generated by {company_name} - {date}"))

    (security-settings
      (allow-invoice-deletion nil)
      (allow-invoice-edit-after-generation t)
      ;; ── THE ORDER-DERIVED INVOICE LOCK (story E1/US-013, requester's ruling 2026-10-12) ──────
      ;; Should an invoice generated FROM an order arrive locked against edits?
      ;;
      ;;   enabled nil  (the default) — NO. The invoice stays open ended. This is the requester's own
      ;;                case: "in India … people add more items in the nick of time after the order is
      ;;                placed", so locking by default would charge their ordinary workflow a per-invoice
      ;;                Unlock on every invoice — friction for the vendor the feature exists to help.
      ;;                An absent key means exactly this, which is what every existing vendor's blob says.
      ;;   enabled t    — YES. Every invoice from an order arrives locked; the vendor unlocks the ones
      ;;                they need to touch, and the unlock is recorded (who, when).
      ;;
      ;; ⚠ THE SECTION NAME IS ODD ON PURPOSE AND MUST NOT BE TIDIED. The settings reader matches keys on
      ;; their name with hyphens REMOVED (invoiceprintsettingentry), and a saved blob round-trips through
      ;; JSON as `:LOCKORDERDERIVEDINVOICESINVOICE`. Renaming the section changes the key every existing
      ;; vendor's blob would have to use.
      ;;
      ;; ⚠ NOT YET ON THE SETTINGS PAGE. `security-settings` is in the shipped defaults but the page's
      ;; template renders only the logo and print forms (com-hhub-transaction-invoice-settings-page
      ;; formats exactly two arguments into invoicesettings.html), so this — like allow-invoice-deletion
      ;; and allow-invoice-edit-after-generation before it — is READABLE and EDITABLE IN THE BLOB but has
      ;; no control yet. Wiring the pane is its own change; see PENDING-WORK-CONTEXT.md §17.
      (lock-order-derived-invoices-invoice
        (enabled nil))
      (auto-logout-timer 30)
      (two-factor-authentication t))

    (advanced-settings
      (enable-custom-scripting nil)
      (allow-third-party-integrations t)
      (webhook-urls
        "https://api.example.com/webhook1"
        "https://api.example.com/webhook2")
      (api-keys
        (public-key "abcd1234")
        (private-key "xyz9876")))

    (notification-and-alert-settings
      (enable-push-notifications t)
      (enable-sms-notifications t)
      (sms-template "Invoice {invoice_number} has been created successfully.")
      (email-notification-on-payment t)
      (reminder-email-template
        "Hi {customer_name},\n\nThis is a friendly reminder that your invoice is due on {due_date}.\nThank you for your prompt payment."))))


(defun update-config (config section key new-value)
  "Update a specific KEY in SECTION of config*invoice-settings* to NEW-VALUE."
  (let ((section-list (assoc section config)))
    (when section-list
      (setf (cdr (assoc key section-list)) new-value))))
