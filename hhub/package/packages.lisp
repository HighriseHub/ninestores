;;; packages.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

(in-package :cl-user)
(defpackage :com.nstores.app
  (:use :cl)
  (:nicknames :nstores) 
  (:export #:*logged-in-users*
	   #:*dod-db-instance*
	    #:*http-server*))


