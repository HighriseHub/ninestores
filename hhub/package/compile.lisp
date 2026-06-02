;;; compile.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

(in-package :cl-user)

;;;; Enhanced Nine Stores Compilation System with Production Hardening
;;;; Features: Logging, Error Tracking, Compile Modes, Clean Target, Summary Reports

  ;;; Configuration
  (defparameter *hhub-root* "/home/ubuntu/ninestores/hhub/"
    "Root directory for Nine Stores project")
  
  (defparameter *hhub-log-dir* (concatenate 'string *hhub-root* "logs/")
    "Directory for compilation logs")
  
  (defparameter *compilation-mode* :production
    "Current compilation mode: :debug or :production")
  
  ;;; Compilation Statistics
  (defstruct compilation-stats
    (start-time 0)
    (end-time 0)
    (total-files 0)
    (compiled 0)
    (skipped 0)
    (failed 0)
    (warnings 0)
    (notes 0)
    (style-warnings 0)
    (failed-files nil)
    (warning-details nil))
  
  ;;; Optimization Settings
  (defun get-optimization-settings (mode)
    "Return optimization settings based on compilation mode"
    (ecase mode
      (:debug
       '(optimize (speed 0) (safety 3) (debug 3) (space 0)))
      (:production
       '(optimize (speed 3) (safety 1) (debug 1) (space 0)))))
  
  ;;; Logging Utilities
  (defun ensure-log-directory ()
    "Ensure log directory exists"
    (ensure-directories-exist *hhub-log-dir*))
  
  (defun get-log-filepath ()
    "Generate timestamped log file path"
    (ensure-log-directory)
    (multiple-value-bind (sec min hour date month year)
        (get-decoded-time)
      (format nil "~Acompilation-~4,'0D~2,'0D~2,'0D-~2,'0D~2,'0D~2,'0D.log"
              *hhub-log-dir* year month date hour min sec)))
  
  (defvar *log-stream* nil
    "Current log file stream")
  
  (defun log-message (level message &rest args)
    "Log message to both console and log file"
    (let ((formatted-msg (apply #'format nil message args))
          (timestamp (multiple-value-bind (sec min hour date month year)
                         (get-decoded-time)
                       (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
                               year month date hour min sec))))
      (let ((log-line (format nil "[~A] [~A] ~A" timestamp level formatted-msg)))
        ;; Print to console
        (format t "~A~%" log-line)
        ;; Write to log file
        (when *log-stream*
          (format *log-stream* "~A~%" log-line)
          (force-output *log-stream*)))))
  
  ;;; Warning and Note Capture
  (defvar *captured-warnings* nil
    "List to capture compilation warnings and notes")
  
  (defun compiler-note-handler (condition)
    "Custom handler to capture compiler notes (optimization hints)"
    (let ((note-text (format nil "~A" condition)))
      (push (list :note note-text) *captured-warnings*)
      (log-message "NOTE" "~A" note-text))
    ;; Don't muffle - let it continue normally
    nil)
  
  (defun style-warning-handler (condition)
    "Custom handler to capture style warnings"
    (let ((warning-text (format nil "~A" condition)))
      (push (list :style-warning warning-text) *captured-warnings*)
      (log-message "STYLE-WARNING" "~A" warning-text))
    ;; Don't muffle - let SLIME/interactive compilation see it
    nil)
  
  (defun warning-handler (condition)
    "Custom handler to capture regular warnings"
    (let ((warning-text (format nil "~A" condition)))
      (push (list :warning warning-text) *captured-warnings*)
      (log-message "WARNING" "~A" warning-text))
    ;; Don't muffle - let SLIME/interactive compilation see it
    nil)
  
  ;;; File List Definition
  (defun get-hhub-file-list ()
    "Return the ordered list of files to compile"
    (list 
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
     "core/hhublazy.lisp"
     "core/memoize.lisp"
     "core/dtrace.lisp"
     "core/extkeys.lisp"
     "core/nst-bl-act.lisp" ;; Actor Model Implementation
     "core/nst-bl-otp.lisp"
     "core/nst-mult-logic.lisp"
     "core/nst-bl-beltrusys.lisp" ;; Belnap 4 valued truth system; Syatvad in Jainism. 
     "core/nst-bl-conflodis.lisp" ;; Context Flow Dispatcher.
     "core/hhub-bl-ent.lisp"
     "core/nst-bl-funloodat.lisp" ;; Function lookup data. 
     "core/nst-ui-prosymloo.lisp" ;; Project symbol lookup. 
     "core/nst-bl-ollama.lisp" ;; Ollama LLM and its associated models to generate response. 
     "core/nst-dal-pincodes.lisp" 
     "core/nst-bl-pincodes.lisp" ;; All India pincodes
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
     "order/nst-dal-OrderItem.lisp"
     
     ;; Orders Business Layer
     "order/dod-bl-odt.lisp"
     "order/dod-bl-ord.lisp"
     "order/nst-bl-Order.lisp"
     "order/nst-bl-OrderItem.lisp"
     
     ;; Orders UI Layer. 
     "order/dod-ui-ord.lisp"
     "order/dod-ui-odt.lisp"
     "order/nst-ui-Order.lisp"
     "order/nst-ui-OrderItem.lisp"
     
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
     "customer/nst-dal-Customer.lisp"
     "customer/dod-bl-cus.lisp"
     "customer/nst-bl-Customer.lisp"
     "customer/dod-ui-cus.lisp"
     "customer/nst-ui-Customer.lisp"
     "customer/nst-ui-cuswall.lisp"
     "customer/nst-ui-prodetpag.lisp"
     
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
     "invoice/nst-dal-cusinvreg.lisp"
     "invoice/nst-bl-cusinvreg.lisp"
     "invoice/nst-ui-cusinvreg.lisp"
     
     
     ;; UNIT TESTS
     "test/hhub-tst-upi.lisp"
     "test/hhub-tst-cus.lisp"
     "test/hhub-tst-webpush.lisp"
     "test/hhub-tst-sms.lisp"
     "test/hhub-tst-wrh.lisp"
     "test/hhub-tst-vpm.lisp"))
  
  ;;; Core Compilation Functions
  (defun compile-single-file (file stats &optional optimize-code)
    "Compile a single file with error and warning handling"
    (let* ((fullpath (concatenate 'string *hhub-root* file))
           (fasl-path (compile-file-pathname fullpath))
           (*captured-warnings* nil))
      
      (log-message "INFO" "Processing: ~A" file)
      
      ;; Delete old .fasl
      (when (probe-file fasl-path)
        (log-message "DEBUG" "Deleting old .fasl: ~A" fasl-path)
        (delete-file fasl-path))
      
      ;; Compile with error handling and warning capture
      (handler-case
          (handler-bind ((warning #'warning-handler)
                         #+sbcl (sb-ext:compiler-note #'compiler-note-handler)
                         #+sbcl (style-warning #'style-warning-handler))
            (let ((start-time (get-internal-real-time)))
              
              (log-message "INFO" "Compiling: ~A" fullpath)
              
              ;; Only apply optimization if explicitly requested
              ;; Note: proclaim is global, so this affects the session
              ;; Use with caution in interactive environments
              (when optimize-code
                (proclaim (get-optimization-settings *compilation-mode*)))
              
              (compile-file fullpath)
              
              (let ((compile-time (/ (- (get-internal-real-time) start-time)
                                    internal-time-units-per-second)))
                (log-message "INFO" "Compiled in ~,2F seconds" compile-time))
              
              ;; Load the compiled file
              (log-message "INFO" "Loading: ~A" fasl-path)
              (load fasl-path)
              
              (incf (compilation-stats-compiled stats))
              
              ;; Track warnings and notes by type
              (when *captured-warnings*
                (let ((note-count 0)
                      (style-warning-count 0)
                      (warning-count 0))
                  (dolist (msg *captured-warnings*)
                    (case (first msg)
                      (:note (incf note-count))
                      (:style-warning (incf style-warning-count))
                      (:warning (incf warning-count))))
                  (incf (compilation-stats-notes stats) note-count)
                  (incf (compilation-stats-style-warnings stats) style-warning-count)
                  (incf (compilation-stats-warnings stats) warning-count)
                  (push (cons file *captured-warnings*) 
                        (compilation-stats-warning-details stats))))))
        
        (error (e)
          (incf (compilation-stats-failed stats))
          (push file (compilation-stats-failed-files stats))
          (log-message "ERROR" "COMPILATION FAILED for ~A: ~A" file e)
          nil))))
  
  ;;; Main Compilation Function
  (defun compile-hhub-files (&key (mode :production) (clean nil) (optimize-code nil))
    "Compile all Nine Stores files with comprehensive logging and error tracking
     
     Arguments:
       :mode - :debug or :production (default :production)
       :clean - if T, clean all FASL files before compiling
       :optimize-code - if T, apply optimization settings (default nil to preserve SLIME compatibility)"
    
    (setf *compilation-mode* mode)
    (let* ((log-file (get-log-filepath))
           (stats (make-compilation-stats
                   :start-time (get-internal-real-time)
                   :total-files (length (get-hhub-file-list)))))
      
      (unwind-protect
           (progn
             ;; Open log file
             (setf *log-stream* (open log-file 
                                     :direction :output
                                     :if-exists :supersede
                                     :if-does-not-exist :create))
             
             (log-message "INFO" "========================================")
             (log-message "INFO" "Nine Stores Compilation Started")
             (log-message "INFO" "Mode: ~A" mode)
             (when optimize-code
               (log-message "WARNING" "Custom optimization enabled - affects entire Lisp session")
               (log-message "INFO" "Optimization: ~A" (get-optimization-settings mode)))
             (log-message "INFO" "Log File: ~A" log-file)
             (log-message "INFO" "========================================")
             
             ;; Clean if requested
             (when clean
               (log-message "INFO" "Cleaning FASL files...")
               (clean-hhub-fasl-files))
             
             ;; Compile all files
             (dolist (file (get-hhub-file-list))
               (compile-single-file file stats optimize-code))
             
             (setf (compilation-stats-end-time stats) (get-internal-real-time))
             
             ;; Print summary
             (print-compilation-summary stats log-file))
        
        ;; Cleanup: close log file
        (when *log-stream*
          (close *log-stream*)
          (setf *log-stream* nil)))
      
      stats))
  
  ;;; Summary Report
  (defun print-compilation-summary (stats log-file)
    "Print comprehensive compilation summary"
    (let* ((duration (/ (- (compilation-stats-end-time stats)
                          (compilation-stats-start-time stats))
                       internal-time-units-per-second))
           (success-rate (* 100 (/ (compilation-stats-compiled stats)
                                  (float (compilation-stats-total-files stats))))))
      
      (log-message "INFO" "========================================")
      (log-message "INFO" "COMPILATION SUMMARY")
      (log-message "INFO" "========================================")
      (log-message "INFO" "Total Files:       ~D" (compilation-stats-total-files stats))
      (log-message "INFO" "Compiled:          ~D" (compilation-stats-compiled stats))
      (log-message "INFO" "Failed:            ~D" (compilation-stats-failed stats))
      (log-message "INFO" "Warnings:          ~D" (compilation-stats-warnings stats))
      (log-message "INFO" "Style Warnings:    ~D" (compilation-stats-style-warnings stats))
      (log-message "INFO" "Compiler Notes:    ~D" (compilation-stats-notes stats))
      (log-message "INFO" "Duration:          ~,2F seconds" duration)
      (log-message "INFO" "Success Rate:      ~,1F%" success-rate)
      (log-message "INFO" "========================================")
      
      ;; List failed files
      (when (compilation-stats-failed-files stats)
        (log-message "ERROR" "FAILED FILES:")
        (dolist (file (reverse (compilation-stats-failed-files stats)))
          (log-message "ERROR" "  - ~A" file)))
      
      ;; Summary of warnings
      (when (compilation-stats-warning-details stats)
        (log-message "INFO" "")
        (log-message "INFO" "FILES WITH ISSUES: ~D" 
                    (length (compilation-stats-warning-details stats)))
        (dolist (item (reverse (compilation-stats-warning-details stats)))
          (let ((file (car item))
                (messages (cdr item))
                (note-count 0)
                (style-count 0)
                (warn-count 0))
            (dolist (msg messages)
              (case (first msg)
                (:note (incf note-count))
                (:style-warning (incf style-count))
                (:warning (incf warn-count))))
            (log-message "INFO" "  ~A" file)
            (when (> warn-count 0)
              (log-message "INFO" "    - ~D warning~:P" warn-count))
            (when (> style-count 0)
              (log-message "INFO" "    - ~D style warning~:P" style-count))
            (when (> note-count 0)
              (log-message "INFO" "    - ~D compiler note~:P" note-count)))))
      
      (log-message "INFO" "")
      (log-message "INFO" "Full log available at: ~A" log-file)
      (log-message "INFO" "========================================")))
  
  ;;; Clean Target
  (defun clean-hhub-fasl-files ()
    "Delete all compiled FASL files"
    (let ((deleted-count 0)
          (failed-count 0))
      
      (log-message "INFO" "Starting FASL cleanup...")
      
      (dolist (file (get-hhub-file-list))
        (let* ((fullpath (concatenate 'string *hhub-root* file))
               (fasl-path (compile-file-pathname fullpath)))
          
          (when (probe-file fasl-path)
            (handler-case
                (progn
                  (delete-file fasl-path)
                  (incf deleted-count)
                  (log-message "DEBUG" "Deleted: ~A" fasl-path))
              (error (e)
                (incf failed-count)
                (log-message "ERROR" "Failed to delete ~A: ~A" fasl-path e))))))
      
      (log-message "INFO" "Cleanup complete: ~D deleted, ~D failed" 
                  deleted-count failed-count)
      (values deleted-count failed-count)))
  
  ;;; Convenience Functions
  (defun compile-debug (&optional (optimize nil))
    "Compile in debug mode with full safety checks
     Set optimize to T to apply debug optimization settings"
    (compile-hhub-files :mode :debug :optimize-code optimize))
  
  (defun compile-production (&optional (optimize nil))
    "Compile in production mode
     Set optimize to T to apply production optimization settings"
    (compile-hhub-files :mode :production :optimize-code optimize))
  
  (defun clean-and-compile (&key (mode :production) (optimize nil))
    "Clean all FASL files and recompile everything"
    (compile-hhub-files :mode mode :clean t :optimize-code optimize))
  
;;;; Usage Examples:
;;;;
;;;; RECOMMENDED - Safe for SLIME (no optimization changes):
;;;;   (compile-production)
;;;;   (compile-debug)
;;;;   (clean-and-compile)
;;;;
;;;; FOR BATCH BUILDS ONLY - Not in SLIME (pollutes session):
;;;;   (compile-production t)
;;;;   (compile-hhub-files :mode :production :optimize-code t)
;;;;
;;;;   Why? Because proclaim is GLOBAL in Common Lisp and cannot
;;;;   be undone. It will affect all subsequent compilations in
;;;;   your SLIME session.
;;;;

;;;; BEST PRACTICE:
;;;; - Use (compile-production) in SLIME for development
;;;; - Use batch script with :optimize-code t for deployment builds
;;;; - Never use :optimize-code t in interactive SLIME sessions


  
