(in-package :cl-user)
(defpackage :com.hhub.app
  (:use :cl)
  (:nicknames :hhub) 
  (:export #:*logged-in-users*
	   #:*dod-db-instance*
	    #:*http-server*))


