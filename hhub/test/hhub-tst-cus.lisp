;;; hhub-tst-cus.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


(defun test-pincode-check (pincode)
  (let* ((params nil)
	 (addressadapter (make-instance 'Address-Adapter))
	 (presenter (make-instance 'Address-Presenter))
	 (jsonview (make-instance 'JSONView)))
    
    (setf params (acons "pincode" pincode params))
    (render jsonview (createviewmodel presenter (processrequest addressadapter params)))))
