;;; hhub-tst-flupload.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun test-file-delete-s3bucket (object-id objectname)
  (let* ((vendor (select-vendor-by-id 1))
	(company (select-company-by-id 2))
	(vendor-id (slot-value vendor 'row-id))
	(tenant-id (slot-value company 'row-id)))
    (vendor-delete-files-s3bucket objectname object-id vendor-id tenant-id)))

