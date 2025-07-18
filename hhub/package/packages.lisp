(in-package :cl-user)
(defpackage :com.nstores.app
  (:use :cl)
  (:nicknames :nstores) 
  (:export #:*logged-in-users*
	   #:*dod-db-instance*
	    #:*http-server*))


