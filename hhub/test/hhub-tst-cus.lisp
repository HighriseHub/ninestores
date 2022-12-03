;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)


(defun test-pincode-check (pincode)
  (let* ((params nil)
	 (addressadapter (make-instance 'Address-Adapter))
	 (presenter (make-instance 'Address-Presenter))
	 (jsonview (make-instance 'JSONView)))
    
    (setf params (acons "pincode" pincode params))
    (render jsonview (createviewmodel presenter (processrequest addressadapter params)))))
