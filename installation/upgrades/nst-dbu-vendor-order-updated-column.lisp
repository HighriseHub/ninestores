;;; nst-dbu-vendor-order-updated-column.lisp — restore DOD_VENDOR_ORDERS.UPDATED (2026-10)
;;; UPDATED exists only in the install-time dump, so older databases carry 59 of the class's 60 columns.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun migrate-2026Oct-vendor-order-updated-column ()
  "Idempotent: add-column-if-absent skips where UPDATED already exists (dev, fresh installs)."
  (add-column-if-absent "DOD_VENDOR_ORDERS" "UPDATED"
                        "timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `CREATED`"))
