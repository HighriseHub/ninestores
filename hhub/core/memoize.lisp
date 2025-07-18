;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;;; -*- Mode: Lisp; Syntax: Common-Lisp -*-
;;;; Code from Paradigms of AI Programming
;;;; Copyright (c) 1991 Peter Norvig
;;; ==============================

;;;; The Memoization facility:

(defmacro defun-memo (fn args &body body)
  "Define a memoized function."
  `(memoize (defun ,fn ,args . ,body)))

(defun memo (fn &key (key #'first) (test #'eql) name)
  "Return a memo-function of fn."
  (let ((table (make-hash-table :test test))
	(alist nil)
	(count 0))
    (setf (get name :memo) table)
    #'(lambda (&rest args)
	(let* ((k (funcall key args))
	       (j (cdr (assoc k alist :test #'eql))))
	  (format t "~A" args)
	  (setf count (incf count))
	  (multiple-value-bind (val found-p)
              (gethash j table)
            (if found-p
		val
		;;else
		(progn
		  (setf alist (acons k count alist))
		  (setf (gethash count table) (apply fn args)))))))))
	
(defun memoizekeyfunc (args)
  (let ((item (first args))
	(alist (second args)))
    (cdr (assoc item alist :test 'equal))))


(defun memoize (fn-name &key (key #'first) (test #'eql))
  "Replace fn-name's global definition with a memoized version."
  (clear-memoize fn-name)
  (remove fn-name *HHUBMEMOIZEDFUNCTIONS*)
  (setf (symbol-function fn-name)
        (memo (symbol-function fn-name)
              :name fn-name :key key :test test))
  (setf *HHUBMEMOIZEDFUNCTIONS* (append (list fn-name) *HHUBMEMOIZEDFUNCTIONS*)))

(defun clear-memoize (fn-name)
  "Clear the hash table from a memo function."
  (let ((table (get fn-name 'memo)))
    (when table (clrhash table))
    (delete fn-name *HHUBMEMOIZEDFUNCTIONS* :test 'equal)))


