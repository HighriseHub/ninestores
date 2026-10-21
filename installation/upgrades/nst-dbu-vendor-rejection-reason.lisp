;; -*- mode: common-lisp; coding: utf-8 -*-
;;; DOD_VEND_PROFILE.REJECTION_REASON for E4; idempotent.

(in-package :nstores)

(defun migrate-2026Oct-vendor-rejection-reason ()
  "Add the vendor rejection reason column so E4 can say why."
  (add-column-if-absent "DOD_VEND_PROFILE" "REJECTION_REASON" "varchar(500) DEFAULT NULL"))
