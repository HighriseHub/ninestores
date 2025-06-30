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
		     "core/nst-bl-act.lisp" ;; Actor Model Implementation
		     "core/nst-bl-otp.lisp"
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
		     "order/nst-dal-Order.lisp"
		     ;; Orders Business Layer
		     "order/dod-bl-odt.lisp"
		     "order/dod-bl-ord.lisp"
		     "order/nst-bl-Order.lisp"
		     ;; Orders UI Layer. 
		     "order/dod-ui-ord.lisp"
		     "order/dod-ui-odt.lisp"
		     "order/nst-ui-Order.lisp"


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
		     "products/dod-dal-gst.lisp"
		     "products/dod-bl-gst.lisp"
		     "products/dod-ui-gst.lisp"

		     ;; Sysuser
		     "sysuser/dod-dal-usr.lisp"
		     "sysuser/dod-dal-sys.lisp"
		     "sysuser/dod-bl-usr.lisp"
		     "sysuser/dod-bl-cad.lisp"
		     "sysuser/dod-ui-cad.lisp"
		     "sysuser/dod-ui-sys.lisp"
		     "sysuser/dod-ui-usr.lisp"
		     ;; Payment Gateway
		     "paymentgateway/dod-dal-pay.lisp"
		     "paymentgateway/dod-bl-pay.lisp"
		     "paymentgateway/dod-ui-pay.lisp"
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
		     "vendor/dod-dal-vpm.lisp"
		     "vendor/dod-bl-vpm.lisp"
		     

		     ;; Webpushnotify
		     "webpushnotify/dod-dal-push.lisp"
		     "webpushnotify/dod-bl-push.lisp"
		     "webpushnotify/dod-ui-push.lisp"
		     
		     ;; email
		     "email/templates/registration.lisp"

		     ;; Shipping
		     "shipping/dod-dal-osh.lisp"
		     "shipping/dod-bl-osh.lisp"
		     "shipping/dod-ui-osh.lisp"

		     ;; Warehouse
		     "warehouse/dod-dal-wrh.lisp"
		     "warehouse/dod-bl-wrh.lisp"
		     "warehouse/dod-ui-wrh.lisp"

		     ;; Invoices
		     "invoice/templates/invoicesettings.lisp"
		     "invoice/nst-dal-ihd.lisp"
		     "invoice/nst-bl-ihd.lisp"
		     "invoice/nst-ui-ihd.lisp"
		     "invoice/nst-dal-itm.lisp"
		     "invoice/nst-bl-itm.lisp"
		     "invoice/nst-ui-itm.lisp"
		   
		     ;; UNIT TESTS
		     "test/hhub-tst-upi.lisp"
		     "test/hhub-tst-cus.lisp"
		     "test/hhub-tst-webpush.lisp"
		     "test/hhub-tst-sms.lisp"
		     "test/hhub-tst-wrh.lisp"
		     "test/hhub-tst-vpm.lisp"
		     ;; "core/dod-seed-data.lisp"
		     ;; "core/unit-tests.lisp"
		     ))
	  
	  (path "/home/ubuntu/ninestores/hhub/"))

      (mapcar
       (lambda (file)
	 (let* ((fullpath (concatenate 'string path file))
		(fasl-path (compile-file-pathname fullpath)))
	   
	   (format t "_____________________________________________________________~%")
	   (format t "Processing: ~A~%" fullpath)
	   
	   ;; Delete old .fasl
	   (when (probe-file fasl-path)
	     (format t "Deleting old .fasl: ~A~%" fasl-path)
	     (delete-file fasl-path))
	   
	   ;; Compile the source file
	   (format t "Compiling: ~A~%" fullpath)
	   (compile-file fullpath)
	   
	   ;; Load the compiled file
	   (format t "Loading: ~A~%" fasl-path)
	   (time (load fasl-path))
	   
	   (format t "_____________________________________________________________~%")))
       filelist))))


      
