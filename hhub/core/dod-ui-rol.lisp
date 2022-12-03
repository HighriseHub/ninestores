;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defun role-dropdown (controlname &optional selectedkey)
  (let* ((rolelist (hhub-get-cached-roles))
	 (rolenameslist (mapcar (lambda (item) 
				  (slot-value item 'name)) rolelist))
	 (roleshash (make-hash-table)))
    (mapcar (lambda (key) (setf (gethash key roleshash) key)) rolenameslist)
    (with-html-dropdown controlname roleshash  (if (not selectedkey) (car rolenameslist) selectedkey))))
