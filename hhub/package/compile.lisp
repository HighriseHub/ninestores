(in-package :cl-user)
(eval-when (:compile-toplevel :load-toplevel :execute) 
  (defun compile-hhub-files ()
    (let ((filelist (list 

		     "package/packages.lisp"
		     ;; Files must be compiled in this order dal, bl, ui, other. 
		     ;; Core Data Access Layer
		    
		     "core/dod-dal-pas.lisp"
		     "core/dod-dal-pol.lisp"
		     "core/dod-dal-rol.lisp"
		     "core/dod-dal-bo.lisp"

		     ;; Core Business Layer
		     
		     "core/dod-bl-err.lisp"
		     "core/dod-bl-sys.lisp"
		     "core/dod-bl-bo.lisp"
		     "core/dod-bl-rol.lisp"
		     "core/dod-bl-pas.lisp"
		     "core/dod-bl-utl.lisp"
		     "core/dod-bl-pol.lisp"
		     "core/hhub-bl-ent.lisp"
		     "core/hhublazy.lisp"
		     "core/memoize.lisp"
		     "core/dtrace.lisp"
		     "core/extkeys.lisp"
		     ;;"core/xref.lisp"
		     
		     ;; Core UI Layer
		     "core/dod-ui-site.lisp"
		     "core/dod-ui-attr.lisp"
		     "core/dod-ui-utl.lisp"
		     "core/dod-ui-pol.lisp"
		     "core/dod-ui-rol.lisp"
		     "core/dod-ini-sys.lisp"
		     
		     ;; Orders Data Access Layer

		     "order/dod-dal-odt.lisp"
		     "order/dod-dal-otk.lisp"
		     "order/dod-dal-ord.lisp"
		     ;; Orders Business Layer
		     "order/dod-bl-odt.lisp"
		     "order/dod-bl-ord.lisp"
		     ;; Orders UI Layer. 
		     "order/dod-ui-ord.lisp"
		     "order/dod-ui-odt.lisp"


		     ;; Subscription
		     "subscription/dod-dal-opf.lisp"
		     "subscription/dod-bl-opf.lisp"
		     "subscription/dod-ui-opf.lisp"

		     ;; Account
		     "account/dod-dal-cmp.lisp"
		     "account/dod-bl-cmp.lisp"
		     "account/dod-ui-cmp.lisp"

		     ;; Customer
		     "customer/dod-dal-cus.lisp"
		     "customer/dod-bl-cus.lisp"
		     "customer/dod-ui-cus.lisp"

		     ;; Products
		     "products/dod-dal-prd.lisp"
		     "products/dod-bl-prd.lisp"
		     "products/dod-ui-prd.lisp"

		     ;; Sysuser
		     "sysuser/dod-dal-usr.lisp"
		     "sysuser/dod-bl-usr.lisp"
		     "sysuser/dod-ui-cad.lisp"
		     "sysuser/dod-ui-sys.lisp"
		     "sysuser/dod-ui-usr.lisp"

		     ;; Upi
		     "upi/dod-dal-upi.lisp"
		     "upi/dod-bl-upi.lisp"
		     "upi/dod-ui-upi.lisp"

		     ;; Vendor
		     "vendor/dod-dal-vas.lisp"
		     "vendor/dod-dal-vad.lisp"
		     "vendor/dod-dal-ven.lisp"
		     "vendor/dod-bl-vad.lisp"
		     "vendor/dod-bl-ven.lisp"
		     "vendor/dod-bl-vas.lisp"
		     "vendor/dod-ui-vad.lisp"
		     "vendor/dod-ui-ven.lisp"

		     ;; Webpushnotify
		     "webpushnotify/dod-dal-push.lisp"
		     "webpushnotify/dod-bl-push.lisp"
		     "webpushnotify/dod-ui-push.lisp"
		     
		     ;; email
		     "email/templates/registration.lisp"

		     ;; Shipping
		     "shipping/dod-dal-osh.lisp"

		   
		     ;; UNIT TESTS
		     "test/hhub-tst-upi.lisp"
		     "test/hhub-tst-cus.lisp"
		     "test/hhub-tst-webpush.lisp"
		     "test/hhub-tst-sms.lisp"
		     ;; "core/dod-seed-data.lisp"
		     ;; "core/unit-tests.lisp"
		     ))
	  
	  (path "/home/ubuntu/hhubplatform/hhub/"))
      
      (mapcar (lambda (file)
		(format t "_____________________________________________________________~C~C" #\return #\linefeed)
		(format t "~A~C~C" (concatenate 'string path file) #\return #\linefeed)
		(format t "~A" (time (load (concatenate 'string path file) :verbose *load-verbose*  :print T)))
		(format t "_____________________________________________________________~C~C" #\return #\linefeed))
		filelist))))
  
