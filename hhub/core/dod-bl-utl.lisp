;;; dod-bl-utl.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)


(defun paise-to-rupees-string (paise)
  (format nil "~,2F" (/ paise 100.0)))

(defun round-to-2-decimal (n)
  "Standard rounding to 2 decimal places."
  (/ (round (* n 100)) 100.0))

(defparameter *uri-boundary-chars* '(#\/ #\? #\# #\;))


(defun uri-prefix-boundary-p (prefix uri)
  (and (uri-prefix-p prefix uri)
       (let ((plen (length prefix)))
         (or (= plen (length uri))
             (not (null
                   (find (aref uri plen)
                         *uri-boundary-chars*)))))))

(defun uri-prefix-p (prefix uri)
  (let ((plen (length prefix)))
    (and (<= plen (length uri))
         (string= prefix uri :end2 plen))))

(defun return-json (data &optional (status 200))
  (setf (hunchentoot:content-type*) "application/json; charset=utf-8")
  (setf (hunchentoot:return-code*) status)
  (hunchentoot:abort-request-handler
   (json:encode-json-to-string data)))


(defun generate-entity-tla (entity-name)
  "Generate a unique 3-letter acronym (TLA) from an entity name like 'order header'."
  (let* ((tokens (remove-if #'(lambda (s) (string= s "")) 
                            (split-sequence:split-sequence #\Space (string-downcase entity-name))))
         (abbr ""))
    (cond
     ((>= (length tokens) 3)
      (setf abbr (concatenate 'string
                              (subseq (nth 0 tokens) 0 3)
                              (subseq (nth 1 tokens) 0 3)
                              (subseq (nth 2 tokens) 0 3))))
     ((= (length tokens) 2)
      (setf abbr (concatenate 'string
                              (subseq (nth 0 tokens) 0 3)
                              (subseq (nth 1 tokens) 0 4))))
     ((= (length tokens) 1)
      (setf abbr (subseq (nth 0 tokens) 0 (min 3 (length (nth 0 tokens))))))
     (t (setf abbr "obj")))
    abbr))

(defun generate-lisp-filename (entity-name layer-name)
  "Generates the Lisp file name like nst-dal-odt.lisp from 'order details' and 'dal'."
  (let ((tla (generate-entity-tla entity-name)))
    (format nil "nst-~A-~A.lisp" (string-downcase layer-name) (string-downcase tla))))

(defun generate-descriptive-filename (entity-name layer)
  (let ((normalized-name (string-downcase (cl-ppcre:regex-replace-all "[ _]" entity-name "-"))))
    (format nil "nst-~A-~A.lisp" layer normalized-name)))


;; Example 1: Creating a branch for a UI feature with an identifier
;; This is for the UI layer, adding a new OTP-based login using HTMX
;; (generate-branch-name
;; :scope "ui"                 ;; Area of the codebase — e.g., "core", "ui", "api", etc.
;; :type "feat"                ;; Type of work — e.g., "feat", "fix", "chore", etc.
;; :id "otp2"                  ;; Optional ticket/issue ID or short code (e.g., JIRA/issue number)
;; :desc "htmx integration")   ;; Description of the work
;; => "ui/feat/otp2-htmx-integration"
;; (generate-branch-name :scope "ui" :type "feat" :id "otp2" :desc "htmx integration")
;; (generate-branch-name :scope "core" :type "fix" :desc "login crash")

(defun generate-branch-name (&key scope type id desc (max-length 50))
  "Generate a validated Git branch name: scope/type/id-desc."
  (let* ((allowed-scopes '("cus" "ven" "cad" "super" "core" "ui" "api" "lisp" "infra" "test" "doc"))
         (allowed-types  '("feat" "fix" "chore" "refactor" "perf" "test" "docs" "hotfix"))
         (scope (string-downcase (string scope)))
         (type (string-downcase (string type)))
         (id (when id (string-downcase (string id))))
         (desc (string-downcase (string desc)))
         (safe-desc (substitute #\- #\Space desc)))

    ;; Validate scope
    (unless (member scope allowed-scopes :test #'string=)
      (error "Invalid scope: ~A. Allowed: ~{~A~^, ~}" scope allowed-scopes))

    ;; Validate type
    (unless (member type allowed-types :test #'string=)
      (error "Invalid type: ~A. Allowed: ~{~A~^, ~}" type allowed-types))

    ;; Generate base name
    (let ((branch-name
            (if id
                (format nil "~A/~A/~A-~A" scope type id safe-desc)
                (format nil "~A/~A/~A" scope type safe-desc))))
      ;; Enforce max length
      (if (> (length branch-name) max-length)
          (error "Branch name too long (~A chars): ~A" (length branch-name) branch-name)
          branch-name))))

(defun generate-sku-anusthup (name desc qty unit)
  (let* ((prefix (lambda (string length)                     ; 1-7
                   (subseq (string-upcase string) 0 length))) ; 8-13
         (code-n (funcall prefix name 4))                    ; 14-18
         (code-d (funcall prefix desc 4))                    ; 19-23
         (random (format nil "~4,'0D" (random 10000))))      ; 24-29
    (format nil "~A-~A-~A~A-~A"                              ; 30-31
            code-n code-d qty unit random)))                 ; 32

(defun generate-sku (product-name description qty-per-unit unit-of-measure)
  "Generate an SKU from product information by taking 2 chars from each word.
  
  Arguments:
  - PRODUCT-NAME: String (e.g., \"Organic Apples\")
  - DESCRIPTION: String or NIL (e.g., \"Red Delicious\")
  - QTY-PER-UNIT: Number (e.g., 1, 100, 2.5)
  - UNIT-OF-MEASURE: String (e.g., \"KG\", \"G\", \"L\")
  
  Returns:
  - A generated SKU string in format NN-DD-QTY-UOM-RANDOM
    Where NN is from product name words, DD from description words
  "
  (flet ((process-words (string max-words)
           (when string
             (let ((words (remove-if #'uiop:emptyp 
                                   (split-sequence:split-sequence #\Space string))))
               (subseq (apply #'concatenate 'string
                             (mapcar (lambda (word) 
                                       (subseq (string-upcase word) 0 (min 2 (length word))))
                                     words))
                       0 (* 2 (min max-words (length words))))))))
    
    (let* ((name-code (process-words product-name 3))  ; Take max 3 words from name
           (desc-code (process-words description 2))   ; Take max 2 words from description
           (random-num (+ 1000 (random 9000))))
      
      (format nil "~A~@[-~A~]-~A~A-~D"
              name-code
              desc-code
              qty-per-unit
              (string-upcase unit-of-measure)
              random-num))))

(defun read-yaml-file (filepath)
  "Read a YAML file and return its parsed content."
  (let ((contents (hhub-read-file filepath)))
    (yaml:parse contents)))

(defun write-yaml-file (filepath data)
  "Write a Lisp data structure to a YAML file."
  (with-open-file (stream filepath :direction :output :if-exists :supersede)
    (yaml:emit data *standard-output*)))

(defun update-invoice-settings (yaml-file output-file)
  "Read, modify, and save YAML settings."
  (let ((data (read-yaml-file yaml-file)))
    ;; Update specific settings
    (setf (gethash "default_currency" (gethash "invoice_general_settings" (gethash "invoice_settings" data))) "INR")
    (setf (gethash "date_format" (gethash "invoice_general_settings" (gethash "invoice_settings" data))) "DD/MM/YYYY")
    ;; Save the updated data
    (write-yaml-file output-file data)))

;; Use the function
;;(update-invoice-settings "config.yaml" "updated_config.yaml")


;;; ---------------------------------------------------------------------------
;;; External commands : run, then CHECK
;;; ---------------------------------------------------------------------------
;; wget and wkhtmltopdf were fired through /bin/sh with their exit status thrown away, so a 404 or a
;; crashed renderer still produced a file name that every caller treated as success -- and a caller
;; turns that name into a URL a customer downloads, or into an email attachment. They now check the
;; exit status AND the artifact, and signal rather than hand back a name for a file that is missing,
;; empty, or not the kind of file it claims to be.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (define-condition hhub-external-command-failed (error)
    ((command
      :initarg :command
      :reader external-command-failed-command)
     (exit-code
      :initarg :exit-code
      :reader external-command-failed-exit-code)
     (reason
      :initarg :reason
      :reader external-command-failed-reason))
    (:documentation "An external command (wget, wkhtmltopdf) failed, or left nothing usable.")
    (:report (lambda (condition stream)
	       (format stream "external command failed (~A)~@[, exit status ~A~]: ~A"
		       (external-command-failed-reason condition)
		       (external-command-failed-exit-code condition)
		       (external-command-failed-command condition))))))

(defun shell-single-quote (string)
  "Wraps STRING so /bin/sh reads all of it as one literal argument. The command lines are built with
FORMAT, so an unquoted URL or path was free to be read as shell syntax instead of as data."
  (with-output-to-string (out)
    (write-char #\' out)
    (loop for c across (or string "")
	  do (if (char= c #\')
		 (write-string "'\\''" out)
		 (write-char c out)))
    (write-char #\' out)))

(defun run-external-command (command &key allow-non-zero-exit)
  "Runs COMMAND through /bin/sh, returns its exit code, and signals
HHUB-EXTERNAL-COMMAND-FAILED unless ALLOW-NON-ZERO-EXIT is set.
The command's own output still goes to the server log, exactly where it already went, so nothing
that used to be visible has been hidden -- the difference is that a failure is no longer silence.
ALLOW-NON-ZERO-EXIT exists for wkhtmltopdf : see GENERATEPDF."
  (let* ((process (sb-ext:run-program "/bin/sh" (list "-c" command)
				      :input nil :output *standard-output* :error *error-output*))
	 (exit-code (sb-ext:process-exit-code process)))
    (unless (or allow-non-zero-exit (eql exit-code 0))
      (error 'hhub-external-command-failed :command command :exit-code exit-code
	     :reason "non-zero exit status"))
    exit-code))

(defun file-starts-with-p (path octets)
  "True when PATH exists and begins with OCTETS : how a generated file is recognised as the kind of
file it was meant to be, rather than merely as something that exists."
  (and (probe-file path)
       (handler-case
	   (with-open-file (stream path :element-type '(unsigned-byte 8))
	     (let ((head (make-array (length octets) :element-type '(unsigned-byte 8))))
	       (and (= (length octets) (read-sequence head stream))
		    (equalp head octets))))
	 (error () nil))))

(defparameter +pdf-magic-bytes+ #(37 80 68 70)
  "The four bytes of %PDF. wkhtmltopdf can exit 0 and still leave a stub behind.")

(defparameter +min-usable-pdf-bytes+ 2000
  "Floor below which a render is a stub rather than an invoice. Measured on this box : a blank
wkhtmltopdf render is ~1.3 KB, a one-line page ~6.8 KB, and a real invoice PDF 77-99 KB. The floor
is set low on purpose : it is here to catch a blank page, not to judge an invoice's size.")

(defun file-size-or-nil (path)
  "The size of PATH in bytes, or NIL when there is no such file."
  (and (probe-file path)
       (with-open-file (stream path :element-type '(unsigned-byte 8))
	 (file-length stream))))

(defun generatepdf (inputhtmlfile outpdffilename)
  "Renders the HTML file INPUTHTMLFILE under the public temp directory to a PDF and returns the bare
file name, not a path. Signals HHUB-EXTERNAL-COMMAND-FAILED when the input HTML is missing or when
no usable PDF appears.

wkhtmltopdf's EXIT CODE IS NOT THE TEST. It exits 1 for a page with a subresource it cannot load
while still rendering a complete PDF, and the invoice page does exactly that on every render : the
template carries an about:blank reference, so the renderer always ends with
\"Exit with code 1 due to network error: ProtocolUnknownError\" and still writes 98 KB of correct
invoice. Gating on that exit code refused to email a PDF that was sitting right there. What the
artifact IS decides instead : the %PDF bytes and a size above the blank-page floor. The renderer's
own complaints are not swallowed -- its stderr goes to the server log, as before."
  (let* ((filename (format nil "~A~A.pdf" outpdffilename (get-universal-time)))
	 (filepath (format nil "~A/temp/~A" *HHUBRESOURCESDIR* filename))
	 (htmlpath (format nil "~A/temp/~A" *HHUBRESOURCESDIR* inputhtmlfile))
	 (pdfcmd (format nil "wkhtmltopdf --disable-javascript ~A ~A"
			 (shell-single-quote htmlpath) (shell-single-quote filepath))))
    (unless (probe-file htmlpath)
      (error 'hhub-external-command-failed :command pdfcmd :exit-code nil
	     :reason (format nil "no such input HTML: ~A" htmlpath)))
    (let ((exit-code (run-external-command pdfcmd :allow-non-zero-exit t)))
      (let ((size (file-size-or-nil filepath)))
	(unless (and size
		     (>= size +min-usable-pdf-bytes+)
		     (file-starts-with-p filepath +pdf-magic-bytes+))
	  (error 'hhub-external-command-failed :command pdfcmd :exit-code exit-code
		 :reason (format nil "no usable PDF (~A, ~A bytes): ~A"
				 (if size "not a PDF or blank" "missing") size filepath)))))
    filename))


(defun downloadhtmlfile (url)
  "Fetches URL into an .html file under the public temp directory and returns the bare file name.
Signals HHUB-EXTERNAL-COMMAND-FAILED when there is no URL to fetch, when wget exits non-zero, or
when it leaves nothing behind."
  (when (or (null url) (string= url ""))
    (error 'hhub-external-command-failed :command "wget" :exit-code nil
	   :reason "no URL to download"))
  (let* ((filename (format nil "download~A.html" (get-universal-time)))
	 (filepath (format nil "~A/temp/~A" *HHUBRESOURCESDIR* filename))
	 (command (format nil "wget -O ~A ~A"
			  (shell-single-quote filepath) (shell-single-quote url))))
    (run-external-command command)
    (let ((size (and (probe-file filepath)
		     (with-open-file (stream filepath :element-type '(unsigned-byte 8))
		       (file-length stream)))))
      (when (or (null size) (zerop size))
	(error 'hhub-external-command-failed :command command :exit-code 0
	       :reason "wget left no HTML behind")))
    filename))

(defun inr-to-words-anusthup (amount crore lakh)
  (multiple-value-bind (rupees paise) (floor amount)  ; 1-7
    (let ((say (lambda (val unit)                     ; 8-12
                 (if (> val 0)                        ; 13-14
                     (format nil "~R ~A " val unit)   ; 15-18
                     ""))))                           ; 19
      (format nil "Rupees ~A~A~A~:[ and ~R paise~;~]" ; 20-26
              (funcall say (floor rupees crore) "crore") ; 27-29
              (funcall say (rem (floor rupees lakh) 100) "lakh") ; 30-31
              (funcall say (rem rupees lakh) "")      ; 32
              (zerop paise) (round (* paise 100))))))

(defun make-inr-mantra (amount)
  (let ((crore 10000000) (lakh 100000))
    (lambda ()
      (inr-to-words-anusthup amount crore lakh))))


(defun convert-number-to-words-INR (number)
  (let* ((ones (make-array '(10) :initial-contents (list ""  "one"  "two"  "three"  "four"  "five"  "six"  "seven"  "eight"  "nine")))
	 (tens (make-array '(10) :initial-contents (list  ""  "ten"  "twenty"  "thirty"  "forty"  "fifty"  "sixty"  "seventy"  "eighty"  "ninety")))
	 (teens (make-array '(10) :initial-contents (list ""  "eleven"  "twelve"  "thirteen"  "fourteen"  "fifteen"  "sixteen"  "seventeen"  "eighteen"  "nineteen"))))
    (labels ((convert-hundreds (number)
	       (cond
		 ((equal number 0) "")
		 ((< number 10) (aref ones number))
		 ((and (> number 10) (< number 20)) (aref teens (- number 10)))
		 ((and (>= number 10) (< number 100))
		  (format nil "~A ~A" (aref tens (floor number 10)) (if (not (equal (mod number 10) 0)) (aref ones (mod number 10)) "")))
		 ((>= number 100)
		  (multiple-value-bind (q r) (floor number 100)
		      (declare (ignore r))
		    (let* ((firstpart (aref ones q))
			   (secondpart (convert-hundreds (mod number 100))))
		      (format nil "~A hundred ~A" firstpart secondpart))))))
	     (convert-thousands (number)
	       (let ((thousand 1000)
		     (lakh 100000))
	       (cond
		 ((< number thousand) (convert-hundreds number))
		 ((< number lakh)
		  (format nil "~A thousand ~A" (convert-hundreds (floor number thousand)) (convert-hundreds (mod number thousand)))))))
	     (convert-lakhs (number)
	       (let ((lakh 100000)
		     (crore 10000000))
	       (cond
		   ((< number lakh) (convert-thousands number))
		   ((< number crore)
		    (format nil "~A lakh ~A" (convert-hundreds (floor number lakh)) (convert-thousands (mod number lakh)))))))
	     (convert-crores (number)
	       (let ((crore 10000000)
		     (hundredcrore 1000000000))
	       (cond
		   ((< number crore) (convert-lakhs number))
		   ((< number hundredcrore)
		    (format nil "~A crores ~A" (convert-hundreds (floor number crore)) (convert-lakhs (mod number crore))))))))

      (let* ((rupees (floor number))
	     (paise (round (* (- number rupees) 100)))
	     (rupees-words (if (equal rupees 0) "zero rupees" (format nil "~A rupees" (convert-crores rupees))))
	     (paise-words (if (> paise 0) (format nil "~A paise" (convert-hundreds paise)))))
	(format nil "~A~A" (string-capitalize rupees-words) (if paise-words (concatenate 'string " and " paise-words) ""))))))

(defun convert-number-to-words-USD (number)
  (declare (ignore number))
  "not implemented" )

(defun create-domain-entity-from-template (entityname fieldnames &key (output-dir "/home/ubuntu/ninestores/hhub/output"))
  "Generates domain code for UI, BL, and DAL by replacing placeholders in templates."
  (let* ((template-paths '((:ui . "/home/ubuntu/ninestores/hhub/core/hhub-ui-egn.lisp")
                           (:bl . "/home/ubuntu/ninestores/hhub/core/hhub-bl-egn.lisp")
                           (:dal . "/home/ubuntu/ninestores/hhub/core/hhub-dal-egn.lisp")))
         (output-files '((:ui . "nst-ui-")
                         (:bl . "nst-bl-")
                         (:dal . "nst-dal-"))))
    
    ;; Iterate over each layer and process its template
    (loop for (layer . template-path) in template-paths
          for (layer2 . prefix) in output-files
          do (let* ((filecontent (hhub-read-file template-path))
                    (outfile (merge-pathnames (format nil "~A~A.lisp" prefix entityname) output-dir)))

               ;; Replace placeholders %0%, %1%, ... with actual field names
               (loop for field in fieldnames
                     for i from 0
                     for placeholder = (format nil "%~d%" i)
                     do (setf filecontent (cl-ppcre:regex-replace-all placeholder filecontent field)))

               ;; Replace 'xxxx' with the entity name
               (setf filecontent (cl-ppcre:regex-replace-all "%entity-name%" filecontent entityname))

               ;; Write the processed content to the output file
               (with-open-file (stream outfile
                                       :if-does-not-exist :create
                                       :if-exists :supersede
                                       :direction :output
                                       :external-format :utf-8)
                 (format stream "~A" filecontent)
                 (terpri stream))))))


(defun hhub-register-network-function (name funcsymbol)
:documentation "This function registers a new business function and adds it to the *HHUBGLOBALBUSINESSFUNCTIONS-HT* Hash Table. It should conform to naming convention com.hhub.businessfunction*"
  (multiple-value-bind (fname) (ppcre:scan "com.hhub.businessfunction.*" name)
    (when fname
      (multiple-value-bind (fsymbol) (ppcre:scan "com-hhub-businessfunction-*" funcsymbol)
	(when fsymbol
	  (setf (gethash name  *HHUBGLOBALBUSINESSFUNCTIONS-HT*) funcsymbol))))))

(defun hhub-init-network-functions ()
  (hhub-register-business-function "com.hhub.nwfunc.bl.getpushnotifysubscriptionforvendor" "com-hhub-businessfunction-bl-getpushnotifysubscriptionforvendor")
;;  (hhub-register-business-function "com.hhub.businessfunction.tempstorage.getpushnotifysubscriptionforvendor" "com-hhub-businessfunction-tempstorage-getpushnotifysubscriptionforvendor")
  (hhub-register-business-function "com.hhub.businessfunction.db.getpushnotifysubscriptionforvendor" "com-hhub-businessfunction-db-getpushnotifysubscriptionforvendor")
  ;; Business functions for Creating Push Notify Subscription for Vendor 
  (hhub-register-business-function "com.hhub.businessfunction.bl.createpushnotifysubscriptionforvendor" "com-hhub-businessfunction-bl-createpushnotifysubscriptionforvendor")
  (hhub-register-business-function "com.hhub.businessfunction.tempstorage.createpushnotifysubscriptionforvendor" "com-hhub-businessfunction-tempstorage-createpushnotifysubscriptionforvendor")
  (hhub-register-business-function "com.hhub.businessfunction.db.createpushnotifysubscriptionforvendor" "com-hhub-businessfunction-db-createpushnotifysubscriptionforvendor"))

(defun hhub-execute-network-function (name input-params)
  :documentation "This is a general business function adapter for HHub. It takes parameters in a association list"
  (handler-case 
      (let ((funcsymbol (gethash name *HHUBGLOBALBUSINESSFUNCTIONS-HT*)))
	(if (null funcsymbol) (error 'hhub-business-function-error :errstring "Business function not registered"))
	(multiple-value-bind (returnvalues exception) (funcall (intern (string-upcase funcsymbol) :hhub) input-params)
	  ;;Return a list of return values and exception as nil. 
	  (list returnvalues exception)))
    (hhub-business-function-error (condition)
      (list nil (format nil "HHUB Business Function error triggered in Function - ~A. Error: ~A" (string-upcase name) (getExceptionStr condition))))
					; If we get any general error we will not throw it to the upper levels. Instead set the exception and log it. 
    (error (c)
      (let ((exceptionstr (format nil  "HHUB General Business Function Error: ~A  ~a~%" (string-upcase name) c)))
	(with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
				:direction :output
				:if-exists :supersede
				:if-does-not-exist :create)
	  (format stream "~A" exceptionstr))
	(list nil (format nil "HHUB General Business Function Error. See logs for more details."))))))


(defun max-item (list)
  (loop for item in list
        maximizing item))

(defun min-item (list)
  (loop for item in list
	minimizing item))


(defun average (list)
  (when (and list (> (length list) 0)) 
    (/ (reduce #'+ list) (length list))))

(defun get-max-of (objlist fieldname)
  (reduce #'max (mapcar (lambda (object)
			(let ((fieldvalue (slot-value object fieldname)))
			  fieldvalue)) objlist)))


(defun get-total-of (objlist fieldname)
  (reduce #'+ (mapcar (lambda (object)
			(let ((fieldvalue (slot-value object fieldname)))
			  (if fieldvalue fieldvalue 0))) objlist)))


(defun createwhatsapplink (phone)
  (format nil "~A~A" *HHUBWHATAPPLINKURLINDIA* phone))

(defun createwhatsapplinkwithmessage (phone message)
  (format nil "~A~A?text=~A" *HHUBWHATAPPLINKURLINDIA* phone (hunchentoot:url-encode message))) 

(defun search-in-hashtable (search-string hashtable)
  :documentation "Search for a string in hashtable. Returns a list of all the values where the key contains the substring" 
  (let ((retlist '()))
    (maphash (lambda (key value)
	       (if (search search-string key) (setf retlist (append retlist (list value))))) hashtable)
  retlist))

(defun hhub-function-memoize (function-symbol)
  (let ((original-function (symbol-function function-symbol))
        (values            (make-hash-table)))
    (setf (symbol-function function-symbol)
          (lambda (arg &rest args)
            (or (gethash arg values)
                (setf (gethash arg values)
                      (apply original-function arg args)))))))
(defun check&encrypt (password confirmpass salt)
  (when 
	 (and (or  password  (length password)) 
	      (or  confirmpass (length confirmpass))
	      (equal password confirmpass))
 
       (encrypt password salt)))


(defun hhub-random-token (length)
  "A URL-, form-, HTML- and JS-SAFE random token of LENGTH characters, drawn from
   [a-z0-9], from the cryptographic generator (SECURE-RANDOM, not *RANDOM-STATE*).

   🚨 USE THIS — NOT HHUB-RANDOM-PASSWORD — FOR ANYTHING THAT IS AN IDENTIFIER. The two are
   not interchangeable, and the difference is a live bug, not a style preference: since
   commit 6cb4c3d (2026-09-13) 'fix the random-password alphabet' widened RANDOM-PASSWORD's
   charset to 89 characters INCLUDING SYMBOLS, deliberately, so that a generated password can
   satisfy an OWASP character-class rule. Every identifier minted from it became a
   time bomb, because it is required to contain at least one special character drawn from
   !@#$%^&*()-_=+[]{};:,.?/ :

     &   truncates a query string — '?k=A&B' arrives as 'A'
     #   turns the rest of the URL into a fragment, never sent to the server
     %   starts a percent-escape, so the value is mis-decoded or rejected
     +   is a SPACE in a form body (application/x-www-form-urlencoded)
     ?   /  .  [  ]  break a CSS or JS selector, and [] appear in a JS index expression

   MEASURED CONSEQUENCE (2026-10-03): the invoice wizard mints its session key as
   'NST000' + RANDOM-PASSWORD 10, passes it through a redirect query string and a hidden form
   field, and looks it up in the session hash — so whenever a hostile character appeared the
   key came back different, GETHASH missed, and the page died with
   'the slot COM.NSTORES.APP::INVOICEHEADER is missing from the object NIL'. Roughly half of
   all new-invoice attempts were affected, and only new invoices: an existing one uses its
   real INVNUM as the key, which is clean.

   ⚠ THIS IS NOT A PASSWORD GENERATOR. 36 characters of alphabet is ample for an identifier
   (36^10 ≈ 3.6e15) but it cannot satisfy a password-complexity rule, by construction.
   Reach for HHUB-RANDOM-PASSWORD when you want a password; reach for this when you want a
   name, a key, a code or a file-name component."
  (let ((alphabet "abcdefghijklmnopqrstuvwxyz0123456789"))
    (let ((n (length alphabet))
          ;; Rejection sampling: 256 is not a multiple of 36, so mapping every byte would
          ;; favour the low letters. Draws at or above the largest multiple are discarded.
          (limit (* 36 (floor 256 36))))
      (with-output-to-string (out)
        (loop repeat length
              do (block draw
                   (loop for b = (aref (secure-random:bytes 1 secure-random:*generator*) 0)
                         do (when (< b limit)
                              (princ (char alphabet (mod b n)) out)
                              (return-from draw)))))))))

(defun hhub-random-password (length)
  "Returns a random password of LENGTH characters.

   Draws from an alphabet that includes lowercase, uppercase, digits and symbols.
   The previous base-36 alphabet could never produce an uppercase letter or a
   symbol, so a generated password could never satisfy an OWASP character-class
   rule. One character from each class is placed first and the result is then
   shuffled, so the minimum complexity is guaranteed and not positionally fixed."
  (let ((lower   "abcdefghijklmnopqrstuvwxyz")
        (upper   "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        (digits  "0123456789")
        (special "!@#$%^&*()-_=+[]{};:,.?/"))
    (let ((all (concatenate 'string lower upper digits special)))
      (labels ((draw (charset n)
                 (let ((size (length charset)))
                   (with-output-to-string (out)
                     (loop repeat n do (princ (char charset (random size)) out))))))
        (let ((chars (coerce (concatenate 'string
                                          (draw lower 1) (draw upper 1)
                                          (draw digits 1) (draw special 1)
                                          (draw all (max 0 (- length 4))))
                             'list)))
          (loop for i from (1- (length chars)) downto 1 do
            (let ((j (random (1+ i))))
              (rotatef (nth i chars) (nth j chars))))
          ;; Exactly LENGTH characters, even when LENGTH < 4.
          (coerce (subseq chars 0 (min length (length chars))) 'string))))))


;;; ═══════════════════════════════════════════════════════════════════════════
;;; LIKE-pattern escaping
;;;
;;; MOVED HERE from warehouse/nst-bl-warehouse.lisp. It was a WAREHOUSE file
;;; exporting a generic SQL-escaping rule, and by the time the vendor layer was
;;; written THREE entity layers called it — warehouse, products AND vendor. Two of
;;; those load BEFORE nst-bl-warehouse.lisp, so each compiled with
;;;
;;;   caught STYLE-WARNING: undefined function: ESCAPE-LIKE-WILDCARDS
;;;
;;; and the warning trained readers to skim past that line — which is how a real
;;; undefined-variable defect survived review in vendor/nst-bl-vnd.lisp on
;;; 2026-09-14. A benign warning sitting next to a fatal one is a hazard in itself.
;;;
;;; core/dod-bl-utl.lisp is at nstores.asd line 62, ahead of products (148), the
;;; vendor block (181+) and warehouse (196), so every caller now sees the real
;;; definition at compile time and the warning is gone for all three.
;;;
;;; It is deliberately NOT a method on any entity: the escaping rule is one rule,
;;; and the `name-like` / `city` filters of every entity share it. A fourth entity
;;; should call this, not copy it.
;;; ═══════════════════════════════════════════════════════════════════════════

(defun nst-row-id-from-string (id)
  "ID as an integer row-id, or NIL when the string cannot address a row at all.

  NIL IS A NOT-FOUND FACT, NOT A MALFORMED REQUEST. /orders/abc asks for something that
  cannot exist, which is :F → 404; treating it as a bad boundary (:U → 503) would tell the
  client the server is broken when the client simply asked for nothing.

  ⚠ THE ONE HOME (decided 2026-09-28). Five copies of this guard already existed —
  vendor-row-id-from-string (vendor/nst-bl-vnd.lisp:460), warehouse-row-id-from-string,
  product-row-id-from-string, invoice-header-row-id-from-string (invoice/nst-bl-invh.lisp),
  invoice-item-row-id-from-string (invoice/nst-bl-invitm.lisp) — and the order verbs are the
  sixth CALL SITE rather than the sixth copy. It lives HERE because dod-bl-utl is build
  position 128 / asd 62: before nst-bl-adhara (149/90) and before every domain file, so
  nothing can load ahead of it. Re-pointing the existing five is a separate change: each sits
  in a different loading-sensitive file and deserves its own build/load proof (PENDING-WORK)."
  (when (stringp id)
    (handler-case (parse-integer id :junk-allowed nil)
      (error () nil))))

(defun escape-like-wildcards (str)
  "Escapes MySQL LIKE metachars so name-like input is treated literally.

   STR may be NIL, in which case NIL is returned. The backslash MUST be escaped
   first — escaping it after % or _ would double-escape the backslashes those two
   insert and corrupt the pattern."
  (when str
    (let ((result str))
      (setf result (cl-ppcre:regex-replace-all "\\\\" result "\\\\\\\\"))
      (setf result (cl-ppcre:regex-replace-all "%" result "\\\\%"))
      (setf result (cl-ppcre:regex-replace-all "_" result "\\\\_"))
      result)))


(defun hhub-read-file (filename)
 :documentation "Reads a file and returns a string"
  (with-open-file (stream filename)
    (let ((contents (make-string (file-length stream))))
      (read-sequence contents stream)
      contents)))

(defun hhub-log-message (str)
  (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE* 
			      :direction :output
			      :if-exists :append
			      :if-does-not-exist :create)
	(format stream "~A" str)))
      
(defun hhub-write-file-for-css-inlining (contents) 
  (with-open-file (stream "/data/www/ninestores.in/public/emailtemplate.html"
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
  (format stream "~A" contents)))


(defun process-file (file move-to)
  (let* ((tempfilewithpath (nth 0 file))
	 (tempfilename (nth 1 file))
	 (final-file-name (format nil "~A-~A" (get-universal-time) tempfilename)))
   ;; Only if the file size is less than 1 mb do the operation. 
   (when (and (probe-file  tempfilewithpath) (with-open-file (s tempfilewithpath) (< (/ (file-length s) 1000000.0) 1)))  
     (rename-file tempfilewithpath (make-pathname :directory move-to  :name final-file-name)))
   final-file-name))




(defun get-ht-val (key hash-table)
    :documentation "If the key is found in the hash table, then return the value. Otherwise it returns nil in two cases. One- the key was present and value was nil. Second - key itself is not present"
  (multiple-value-bind (value present) (gethash key hash-table)
      (if present value )))

(defun get-ht-values (hashtable)
  (loop for v being the hash-value in hashtable
	return (format nil "~A" v)))


(defun parse-date-string (datestr)
  "Read a date string of the form \"DD/MM/YYYY\" and return the 
corresponding universal time."
  (let ((date (parse-integer datestr :start 0 :end 2))
        (month (parse-integer datestr :start 3 :end 5))
        (year (parse-integer datestr :start 6 :end 10)))
    (encode-universal-time 0 0 0 date month year)))

(defun parse-date-string-yyyymmdd (datestr)
  "Read a date string of the form \"YYYY-MM-DD\" and return the 
corresponding universal time."
  (let ((year (parse-integer datestr :start 0 :end 4))
        (month (parse-integer datestr :start 5 :end 7))
        (date (parse-integer datestr :start 8 :end 10)))
    (encode-universal-time 0 0 0 date month year)))



(defun parse-time-string (timestr)
  :documentation "Read a time string of the form \"HH:MM:SS\" and return the corresponding universal time"
 (let ((hour (parse-integer timestr :start 0 :end 2))
       (minute (parse-integer timestr :start 3 :end 5))
       (second (parse-integer timestr :start 6 :end 8)))
   (encode-universal-time second minute hour 1 1 0)))

(defun get-time-string-from-dateobj (dateobj)
"Returns current time  as a string in HH:MM:SS  format"
  (multiple-value-bind (sec min hr day mon yr dow dst-p tz)
      dateobj
    (declare (ignore day mon yr dow dst-p tz))
    (format nil "~2,'0d:~2,'0d:~2,'0d" hr min  sec)))
 
(defun current-time-string ()
  "Returns current time  as a string in HH:MM:SS  format"
  (multiple-value-bind (sec min hr day mon yr dow dst-p tz)
                       (get-decoded-time)
    (declare (ignore day mon yr dow dst-p tz))
      (format nil "~2,'0d:~2,'0d:~2,'0d" hr min  sec)))


(defun get-date-from-string (datestr)
    :documentation  "Read a date string of the form \"DD/MM/YYYY\" and return the corresponding date object."
  (if (not (equal datestr ""))
      (let ((date (parse-integer datestr :start 0 :end 2))
            (month (parse-integer datestr :start 3 :end 5))
            (year (parse-integer datestr :start 6 :end 10)))
	(clsql-sys:make-date :year year :month month :day date :hour 0 :minute 0 :second 0 ))))

(defun get-dateobj-from-string-yyyymmdd (datestr)
    :documentation  "Read a date string of the form \"YYYY-MM-DD\" and return the corresponding date object."
(if (not (equal datestr ""))
    (let ((year (parse-integer datestr :start 0 :end 4))
          (month (parse-integer datestr :start 5 :end 7))
          (date (parse-integer datestr :start 8 :end 10)))
      (clsql-sys:make-date :year year :month month :day date :hour 0 :minute 0 :second 0 ))))

(defun current-date-object ()
  (multiple-value-bind (sec min hr day mon yr dow dst-p tz)
                       (get-decoded-time)
    (declare (ignore sec min hr dow dst-p tz))
    (clsql-sys:make-date :year yr :month mon :day day :hour 0 :minute 0 :second 0)))
    

(defun current-date-string ()
  "Returns current date as a string in YYYY/MM/DD format"
  (multiple-value-bind (sec min hr day mon yr dow dst-p tz)
                       (get-decoded-time)
    (declare (ignore sec min hr dow dst-p tz))
    (format nil "~4,'0d/~2,'0d/~2,'0d" yr mon day)))

(defun current-date-string-yyyymmdd ()
  "Returns current date as a string in YYYY-MM-DD format"
  (multiple-value-bind (sec min hr day mon yr dow dst-p tz)
                       (get-decoded-time)
    (declare (ignore sec min hr dow dst-p tz))
      (format nil "~4,'0d-~2,'0d-~2,'0d" yr mon day)))

(defun current-date-string-ddmmyyyy ()
  "Returns current date as a string in DD-MM-YYYY format"
  (multiple-value-bind (sec min hr day mon yr dow dst-p tz)
                       (get-decoded-time)
    (declare (ignore sec min hr dow dst-p tz))
    (format nil "~2,'0d-~2,'0d-~4,'0d" day mon yr )))

(defun current-year-string ()
"Returns current year as a string in YYYY format"
  (multiple-value-bind (sec min hr day mon yr dow dst-p tz)
                       (get-decoded-time)
    (declare (ignore day mon sec min hr dow dst-p tz))
    (format nil "~4,'0d" yr )))

(defun current-year-string-- ()
"Returns current year as a string in YYYY format"
  (multiple-value-bind (sec min hr day mon yr dow dst-p tz)
                       (get-decoded-time)
    (declare (ignore day mon sec min hr dow dst-p tz))
    (format nil "~4,'0d" (decf yr))))

(defun current-year-string++ ()
"Returns current year as a string in YYYY format"
  (multiple-value-bind (sec min hr day mon yr dow dst-p tz)
                       (get-decoded-time)
    (declare (ignore day mon sec min hr dow dst-p tz))
    (format nil "~4,'0d" (incf yr))))
  

(defun get-date-string (dateobj)
  "Returns current date as a string in DD/MM/YYYY format."
  (multiple-value-bind (yr mon day)
      (clsql-sys:date-ymd dateobj)  (format nil "~2,'0d/~2,'0d/~4,'0d" day mon yr)))


(defun get-datestr-from-obj-yyyymmdd (dateobj)
  "Returns current date as a string in YYYY-MM-DD format."
  (multiple-value-bind (yr mon day)
      (clsql-sys:date-ymd dateobj)   (format nil "~4,'0d-~2,'0d-~2,'0d" yr mon day))) 


(defun mysql-now ()
  (multiple-value-bind
        (second minute hour date month year day-of-week dst-p tz)
      (get-decoded-time)
    (declare (ignore day-of-week dst-p tz))
    ;; ~2,'0d is the designator for a two-digit, zero-padded number
    (format nil "~a-~2,'0d-~2,'0d ~2,'0d:~2,'0d:~2,'0d"
                 year month date hour minute second)))

(defun mysql-now+days (numdays)
  (multiple-value-bind
        (second minute hour date month year day-of-week dst-p tz)
      (clsql-sys:decode-date (clsql-sys:date+ (clsql-sys:get-date) (clsql-sys:make-duration :day numdays)))
     (declare (ignore day-of-week dst-p tz))
    ;; ~2,'0d is the designator for a two-digit, zero-padded number
(format nil "~a-~2,'0d-~2,'0d ~2,'0d:~2,'0d:~2,'0d"
                 year month date hour minute second)))





(defun get-date-string-mysql (dateobj) 
  "Returns current date as a string in DD-MM-YYYY format."
  (multiple-value-bind (yr mon day)
                       (clsql-sys:date-ymd dateobj)  (format nil "~4,'0d-~2,'0d-~2,'0d" yr mon day)))


(defun get-universal-time-from-date (dateobj)
  (multiple-value-bind (day mon year) 
	  (clsql-sys:decode-date dateobj) 
	    (encode-universal-time  0 0 0 day mon year)))



(defvar *unix-epoch-difference*
  (encode-universal-time 0 0 0 1 1 1970 0))

(defun universal-to-unix-time (universal-time)
  (- universal-time *unix-epoch-difference*))

(defun unix-to-universal-time (unix-time)
  (+ unix-time *unix-epoch-difference*))

(defun get-unix-time ()
  (universal-to-unix-time (get-universal-time)))

    


(defun generatehashkey (params-alist salt hashmethod)
  (let* ((msg salt)
	(param-names (mapcar (lambda (param) 
				(car param)) params-alist)))
    (setf param-names (sort param-names  #'string-lessp))
    (loop for item in param-names do 
	 (let ((str (find item params-alist :test #'equal :key #'car)))
	 (setf msg (concatenate 'string msg "|" (cdr str)))))
    (string-upcase (ironclad:byte-array-to-hex-string 
     (ironclad:digest-sequence
      hashmethod
      (ironclad:ascii-string-to-byte-array msg))))))

(defun hashcalculate (params-alist salt hashmethod)
  (let* ((msg salt)
	 (param-names (mapcar (lambda (param) 
				(car param)) params-alist)))
    (setf param-names (sort param-names  #'string-lessp))
    (loop for item in param-names do 
	 (let* ((key (find item params-alist :test #'equal :key #'car))
	       (value (cdr key)))
	   (if (and value (> (length value) 0))
	   (setf msg (concatenate 'string msg "|" (string-trim " " value))))))
    (string-upcase (ironclad:byte-array-to-hex-string 
     (ironclad:digest-sequence
      hashmethod
      (ironclad:ascii-string-to-byte-array msg))))))
  



(defun responsehashcheck (params-alist salt hashmethod)
  (let* ((received-hash (cdr (find "hash" params-alist :test #'equal :key #'car)))
	 (new-params-alist (remove (find "hash" params-alist :test #'equal :key #'car) params-alist))
	 (newhash (hashcalculate new-params-alist salt hashmethod)))
    (equal newhash received-hash)))
    
	

(defun createciphersalt ()
  (let ((salt-octet (secure-random:bytes 28 secure-random:*generator*)))
    (ironclad:byte-array-to-hex-string salt-octet)))

(defun get-cipher (salt)
  (ironclad:make-cipher :blowfish
    :mode :ecb
    :key (ironclad:ascii-string-to-byte-array salt)))

(defun encrypt (plaintext salt)
  (let ((cipher (get-cipher salt))
        (msg (ironclad:ascii-string-to-byte-array plaintext)))
    (ironclad:byte-array-to-hex-string (ironclad:encrypt-message cipher msg))))

(defun create-digest-sha1 (plaintext)
  (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha1 (ironclad:ascii-string-to-byte-array plaintext)))) 

(defun create-digest-md5 (plaintext)
  ;; UTF-8, NOT ASCII: ironclad:ascii-string-to-byte-array signals
  ;; "... is not an ASCII character" on any typographic quote or accented letter.
  ;; Pure-ASCII input yields identical bytes, so existing digests do not move.
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence :md5 (sb-ext:string-to-octets plaintext :external-format :utf-8))))

(defun create-md5-from-list (items)
  "Takes a list of strings, joins them with commas, and returns the MD5 digest."
  (let ((joined (format nil "~{~A~^,~}" items)))
    (create-digest-md5 joined)))

(defun decrypt (ciphertext key)
  (let ((cipher (get-cipher key))
        (msg (ironclad:integer-to-octets (ironclad:octets-to-integer (ironclad:ascii-string-to-byte-array ciphertext)))))
    (ironclad:decrypt-in-place cipher msg)
    (coerce (mapcar #'code-char (coerce msg 'list)) 'string)))

;;; ═══════════════════════════════════════════════════════════════════════════
;;; PASSWORD STORAGE — argon2id, with the legacy Blowfish value still readable
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; WHY THE OLD PAIR WAS REPLACED. encrypt/get-cipher above build BLOWFISH IN
;;; ECB, whose block is 8 bytes, and ironclad:encrypt-message processes WHOLE
;;; BLOCKS ONLY — any trailing partial block is silently DISCARDED. check-password
;;; then compared that one block. Measured 2026-09-25 against a live row: encrypt
;;; of an 8-byte and of a 9-byte plaintext are IDENTICAL, and Welcome1, Welcome12,
;;; Welcome1$ and Welcome1$$ all authenticated, while Welcome (7 bytes) encrypted
;;; to the empty string and could never match at all. So the effective credential
;;; was its first 8 BYTES: everything after that was ignored, any password shorter
;;; than 8 bytes was unusable, and ECB with no IV meant equal 8-byte prefixes
;;; produced equal stored values.
;;;
;;; THE REPLACEMENT IS ARGON2ID AT THE OWASP MINIMUM: memory 19456 KiB (19 MiB),
;;; iterations 2, parallelism 1. Ironclad's argon2 exposes no lanes parameter, so
;;; p is 1 by construction. Ironclad counts memory in 128-byte blocks, which is
;;; what password-hash-block-count converts.
;;;
;;; 🚨 MEASURED COST: ~3.2 SECONDS PER DERIVATION on this host, because ironclad's
;;; Argon2 is pure Lisp rather than a native library. That is the honest price of
;;; the OWASP minimum here and it lands on EVERY login. It is not a reason to go
;;; below the minimum — that would be a non-compliant scheme wearing a compliant
;;; name. If 3.2 s is unacceptable the correct move is bcrypt at work factor >= 10
;;; (OWASP's third choice, also available), NOT a reduced argon2. Tune ONLY in the
;;; parameter list below.
;;;
;;; THE SALT COLUMN IS STILL THE SALT. Every row already carries a unique per-user
;;; salt, so the hash does not embed one — which is what lets check-password keep
;;; its (plaintext salt ciphertext) signature and every caller stay unchanged.
;;;
;;; LEGACY VALUES KEEP WORKING. A legacy stored value is exactly 16 hex
;;; characters; a current one begins "argon2id$". NOTHING ELSE IS ACCEPTED — an
;;; unrecognised format returns NIL instead of falling through to a weaker check,
;;; because a verification path that guesses is worse than one that refuses.
;;; Note the legacy branch is still subject to the 8-byte truncation for the
;;; values already stored; only rehashing escapes it, which is what
;;; password-hash-needs-upgrade-p exists to drive.

(defparameter *password-hash-format* "argon2id"
  "The scheme tag that begins a CURRENT stored value. Bumping it is how a future
   scheme change stays readable: an old value keeps verifying because it carries
   its own tag and its own parameters.")

(defparameter *password-hash-memory-kib* 19456
  "Argon2id memory in KiB. 19456 = 19 MiB, the OWASP minimum. Raising it is the
   cheapest way to buy strength; lowering it is not.")

(defparameter *password-hash-iterations* 2
  "Argon2id time cost. OWASP's minimum is 2.")

(defparameter *password-hash-arity* 1
  "Argon2id parallelism. Recorded in the stored value for the record: ironclad's
   argon2 has no lanes parameter, so this is 1 by construction and cannot be
   raised without changing library.")

(defparameter *password-hash-key-bytes* 32
  "Derived-key length. 32 bytes is the argon2id recommendation and base64s to 44
   characters, which keeps the whole stored value at 63 — inside the varchar(100)
   PASSWORD columns on DOD_VEND_PROFILE and DOD_USERS.")

(defun password-hash-block-count ()
  "The argon2id memory cost in ironclad's units: 128-byte blocks."
  (/ (* *password-hash-memory-kib* 1024) 128))

(defun password-hash-derive (plaintext salt memory-kib iterations key-bytes)
  "PLAINTEXT under SALT -> the raw derived key, at the SUPPLIED parameters."
  (ironclad:derive-key
   (ironclad:make-kdf :argon2id :block-count (/ (* memory-kib 1024) 128))
   (sb-ext:string-to-octets (or plaintext "") :external-format :utf-8)
   (sb-ext:string-to-octets salt :external-format :utf-8)
   iterations key-bytes))

(defun hash-password (plaintext salt)
  "PLAINTEXT under SALT -> the stored value: argon2id$<memory>$<iterations>$<arity>$<b64 key>.

   A DROP-IN REPLACEMENT FOR (encrypt password salt) at every write site: same
   two arguments, same slot, and it fits the same column. The salt is REQUIRED —
   a nil or empty salt would hash under a shared default, which is the one way to
   make per-row salts worthless, so it signals rather than proceeding."
  (when (or (null salt) (not (stringp salt)) (zerop (length salt)))
    (error "hash-password: a non-empty per-user salt is required (got ~S); hashing without one would defeat the per-row salt entirely." salt))
  (format nil "~A$~D$~D$~D$~A"
          *password-hash-format* *password-hash-memory-kib* *password-hash-iterations*
          *password-hash-arity*
          (cl-base64:usb8-array-to-base64-string
           (password-hash-derive plaintext salt *password-hash-memory-kib*
                                 *password-hash-iterations* *password-hash-key-bytes*))))

(defun password-hash-p (stored)
  "True when STORED is a CURRENT-format value — the tag, then four fields."
  (and (stringp stored)
       (> (length stored) 0)
       (let ((tag (concatenate 'string *password-hash-format* "$")))
         (and (>= (length stored) (length tag))
              (string= tag stored :end1 (length tag) :end2 (length tag))))))

(defun password-hash-legacy-p (stored)
  "True when STORED is a LEGACY value: exactly 16 hexadecimal characters, which
   is what one 8-byte Blowfish block prints as. Case-insensitive because the
   writer used byte-array-to-hex-string (lower) and a hand-typed value may not."
  (and (stringp stored)
       (= (length stored) 16)
       (every (lambda (c) (digit-char-p c 16)) stored)))

(defun constant-time-string= (a b)
  "Compare two strings without an early exit on the first difference. A password
   comparison that returns as soon as it knows leaks how much of the answer was
   right; the cost of avoiding that is one full pass over a 44-character string."
  (and (stringp a) (stringp b) (= (length a) (length b))
       (let ((diff 0))
         (dotimes (i (length a) (zerop diff))
           (setf diff (logior diff (logxor (char-code (char a i))
                                           (char-code (char b i)))))))))

(defun password-hash-verify (plaintext salt stored)
  "Verify PLAINTEXT against a CURRENT stored value.

   THE STORED PARAMETERS ARE USED, NOT TODAY'S CONSTANTS. That is the entire
   reason they are embedded: raising *password-hash-memory-kib* must not
   invalidate every existing row, and a value written under the old settings must
   keep verifying until password-hash-needs-upgrade-p gets it rehashed."
  (let ((parts (cl-ppcre:split "\\$" stored)))
    (if (/= (length parts) 5)
        nil
        (destructuring-bind (tag memory iterations arity encoded) parts
          (declare (ignore arity))
          (and (string= tag *password-hash-format*)
               (every #'digit-char-p memory)
               (every #'digit-char-p iterations)
               (handler-case
                   (let ((expected (cl-base64:usb8-array-to-base64-string
                                    (password-hash-derive plaintext salt
                                                          (parse-integer memory)
                                                          (parse-integer iterations)
                                                          *password-hash-key-bytes*))))
                     (constant-time-string= expected encoded))
                 ;; A corrupt or hostile value must be a failed login, never a 500:
                 ;; the database is the wrong place to trust arithmetic on.
                 (error () nil)))))))

(defun password-hash-needs-upgrade-p (stored)
  "True when STORED should be rehashed on the next successful verification: a
   legacy Blowfish row, a value whose scheme tag is no longer current, or a value
   written under DIFFERENT PARAMETERS than the constants below.

   THE PARAMETER CHECK IS THE POINT of embedding them. Raising
   *password-hash-memory-kib* is the recommended way to keep up with hardware, and
   without this comparison every existing row would keep verifying under the old
   cost forever — a silent failure to upgrade that looks like a working system. An
   earlier version of this function tested only the tag and answered NIL for a
   4096/3 value, which is exactly the drift it was written to catch."
  (if (not (password-hash-p stored))
      t
      (let ((parts (cl-ppcre:split "\\$" stored)))
        (if (/= (length parts) 5)
            t
            (destructuring-bind (tag memory iterations arity encoded) parts
              (declare (ignore encoded))
              (or (not (string= tag *password-hash-format*))
                  (not (equal memory (princ-to-string *password-hash-memory-kib*)))
                  (not (equal iterations (princ-to-string *password-hash-iterations*)))
                  (not (equal arity (princ-to-string *password-hash-arity*)))))))))

(defun check-password (plaintext salt ciphertext)
  "Verify PLAINTEXT against CIPHERTEXT under SALT, accepting BOTH stored formats:
   the current argon2id value and the legacy Blowfish one.

   THE FORMAT DECIDES THE CHECK, and an unrecognised format fails closed. There is
   deliberately no fallthrough to the legacy comparison: that would mean any
   malformed or truncated value silently gets verified by the weak path, which is
   how a migration quietly becomes a downgrade."
  (cond
    ((password-hash-p ciphertext) (password-hash-verify plaintext salt ciphertext))
    ((password-hash-legacy-p ciphertext) (equal (encrypt plaintext salt) ciphertext))
    (t nil)))





;;; ═══════════════════════════════════════════════════════════════════════════
;;; DOCUMENT NUMBERING (orders batch, S0c) — the FY rule, the counter, the reference
;;; ═══════════════════════════════════════════════════════════════════════════
;;;
;;; Design: aiharness/deepseek/skills/order-adhara-stories-CONTEXT.md § S0c, and the
;;; F1 decision record in its §10.
;;;
;;; WHY IT LIVES HERE: this file is build position 128 / asd 62 — before
;;; nst-bl-adhara (149/90) and before every domain file — so no caller can load
;;; ahead of these definitions. The order mint, the S8b legacy funnels and the
;;; invoice settings' own aspirational invoice-number-format all need them, and this
;;; section is the single home that stops the April-March rule existing twice.

(defun nst-date-ymd (date)
  "YEAR, MONTH and DAY for a date as it actually reaches this system.

  ⚠ THIS EXISTS BECAUSE decode-date'S CONTRACT DIFFERS BY TYPE, which is measured,
  not assumed (2026-09-28, SBCL + this CLSQL):

    (clsql-sys:decode-date <a clsql-sys:date struct>)  => 4 values
        (day month year day-of-week)          e.g. (1 4 2026 3) for 2026-04-01
    (clsql-sys:decode-date <a wall-time>)              => 6 values
        (second minute hour day month year)
    (clsql-sys:decode-date <a universal-time integer>) => ERRORS

  So a function that destructures six values is correct for a wall-time and WRONG for
  a DATE column — and a DATE column is exactly what the ORM yields here
  (`dod-order`'s `ord-date` and `dod-invoice-header`'s `invdate` are both declared
  `:type clsql:date`). That mismatch is a crash (month comes back NIL), not a wrong
  answer, which is the only reason it was noticed.

  A DATE struct carries ONE slot (MJD), so `date-ymd` is the accessor for it, and it
  is the one used here — returning (year month day), verified against a December date
  so that a year/month/day mix-up cannot pass by luck."
  (cond
    ((typep date 'clsql-sys:date)
     (values-list (multiple-value-list (clsql-sys:date-ymd date))))
    ;; a JSON or URL parameter arrives as a string, and parse-datestring yields a
    ;; clsql:date — the same shape the ORM gives, so it re-enters the branch above
    ((stringp date)
     (values-list (multiple-value-list
                   (clsql-sys:date-ymd (clsql-sys:parse-datestring date)))))
    (t
     (error "cannot read a calendar date from ~S (type ~S). This accepts a CLSQL ~
             date struct (what a DATE column yields through the ORM) or an ISO ~
             string (what a JSON or URL parameter yields) — and nothing else, ~
             MEASURED: in this CLSQL, decode-date answers a DATE struct with 4 ~
             values (day month year day-of-week) and SIGNALS for a wall-time and for ~
             a universal-time integer, so there is no third contract to fall back on."
            date (type-of date)))))

(defun nst-financial-year-label (date)
  "The Indian/GST financial year containing DATE, as FINYEAR's varchar(9):
  a date from 2026-04-01 to 2027-03-31 answers \"2026-2027\".

  MOVED HERE from invoice/nst-bl-invh.lisp, where it was first written: the ORDER
  mint needs the same rule, and this is a LEGAL rule (the Indian April-March year) —
  the worst kind to hold two copies of. Same package and same symbol, so its one
  caller (nst-bl-invh.lisp's make) needed no change at all.

  April-March is the GST default and the only rule the schema documents. A tenant
  whose year starts in another month describes it on nst-vnd's fy-start-month slot,
  which no verb reads yet — when one does, this function is the single place to
  change, and the callers are make and the order mint."
  (multiple-value-bind (year month day)
      (nst-date-ymd date)
    (declare (ignore day))
    (if (>= month 4)
        (format nil "~4,'0d-~4,'0d" year (1+ year))
        (format nil "~4,'0d-~4,'0d" (1- year) year))))

(defun nst-financial-year-short (date)
  "The same financial year in the SHORT form a document number carries: a date from
  2026-04-01 to 2027-03-31 answers \"2026-27\".

  DERIVED from nst-financial-year-label rather than recomputed, so the April-March
  rule keeps exactly one implementation and only its rendering differs — a number
  needs 7 characters where FINYEAR's column is varchar(9)."
  (let ((label (nst-financial-year-label date)))
    (format nil "~A-~A" (subseq label 0 4) (subseq label 7 9))))

(defun nst-financial-year-month (date)
  "The calendar month of DATE as two digits, for the {MM} token the shipped invoice
  template already uses (\"INV-YYYY-MM-{counter}\")."
  (multiple-value-bind (year month day)
      (nst-date-ymd date)
    (declare (ignore year day))
    (format nil "~2,'0D" month)))

(defparameter *nst-doc-ref-alphabet* "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
  "The 32 symbols a document reference is drawn from: digits 2-9 plus A-Z less the
  look-alikes I and O, with 0 and 1 absent alongside them because 0/O and 1/I/L are
  what make a reference unreadable when it is said aloud — and saying it aloud is a
  primary use of this number (the customer quotes it to the vendor over the phone).

  EXACTLY 32 SYMBOLS, ON PURPOSE: a reference is built one byte at a time, taking
  (mod byte 32), so the alphabet must be a power of two or the mapping is biased.
  The acceptance criterion in the story file encodes this exact set:
  ^ORD-[A-Z0-9]{3,8}-[0-9]{4}-[0-9]{2}-[2-9A-HJ-NP-Z]{6}$")

(defun nst-doc-ref-key ()
  "The document-reference key, read from DOD_SYS_SECRET. FAILS CLOSED when absent.

  It is NOT in hhub/core/extkeys.lisp, where this tree keeps its other secrets,
  because THAT FILE IS TRACKED: a key in git would let anyone who can read the
  repository enumerate every reference in the system, which is the whole property the
  permutation exists to provide.

  A missing key is an ERROR, never a default. A fallback value would make every
  reference guessable while the system looked healthy."
  (let ((rows (handler-case
                  (clsql:query
                   "SELECT SECRET_VALUE FROM DOD_SYS_SECRET WHERE SECRET_NAME = 'DOC_REF_KEY'"
                   :flatp t)
                (error (c)
                  (error "cannot read the document-reference key: ~A. If DOD_SYS_SECRET ~
                          does not exist yet, run the 28092026-create-doc-counter ~
                          migration." c)))))
    (or (first rows)
        (error "DOD_SYS_SECRET holds no DOC_REF_KEY row, so no document reference can ~
                be minted. Run the 28092026-create-doc-counter migration (it seeds the ~
                key). Refusing to mint under a default key."))))

(defun nst-doc-sql-token-safe-p (value)
  "True when VALUE can be interpolated into a SQL literal safely: uppercase letters,
  digits and hyphen only.

  EVERY value that reaches the counter statements passes through this, because those
  statements are built as strings — CLSQL has no parameterised form for the
  LAST_INSERT_ID idiom they depend on — so this guard, and not the caller's
  discipline, is what stops a future caller turning a document type into SQL."
  (and (stringp value)
       (plusp (length value))
       (every (lambda (c)
                (or (char<= #\A c #\Z) (char<= #\0 c #\9) (char= c #\-)))
              value)))

(defun nst-next-doc-counter (doc-type scope-kind scope-id finyear &optional tenant-id)
  "The next integer in the series (DOC-TYPE, SCOPE-KIND, SCOPE-ID, FINYEAR), allocated
  atomically. Creates the series row on first use, so no seeding is needed.

  ⚠ THE LAST_INSERT_ID(expr) IDIOM IS LOAD-BEARING, NOT A FLOURISH. The obvious
  version — UPDATE ... SET `LAST_SEQ` = `LAST_SEQ` + 1, then SELECT `LAST_SEQ` — is a
  lost-update race under autocommit: another session can bump the row between the two
  statements, and this caller then reads ITS value and mints a duplicate number.
  MySQL's LAST_INSERT_ID(expr) sets a SESSION-LOCAL value and returns it, so the pair
  below is correct WITHOUT a transaction; INSERT ... ON DUPLICATE KEY makes the first
  statement idempotent and takes the row lock that serialises concurrent callers.

  ⚠ EVERY IDENTIFIER IS BACKTICK-QUOTED AND THE SEQUENCE COLUMN IS `LAST_SEQ` — keep
  both. The column was named LAST_VALUE in the first version and MySQL 8.0 RESERVES
  that word (it is a window function), so the migration's CREATE failed with Error
  1064 until it was renamed; the backticks are what stop the next column added here
  from being stopped by a word the server has since claimed. The DDL lives in
  installation/upgrades/nst-dbu-doc-counter.lisp — KEEP THE TWO IN STEP."
  (dolist (s (list doc-type scope-kind finyear))
    (unless (nst-doc-sql-token-safe-p s)
      (error "~S is not a safe document-numbering token: only A-Z, 0-9 and - are ~
              allowed, because these values are interpolated into SQL." s)))
  (unless (integerp scope-id)
    (error "a counter scope id must be an integer, not ~S." scope-id))
  (when (and tenant-id (not (integerp tenant-id)))
    (error "a counter tenant id must be an integer or NIL, not ~S." tenant-id))
  (clsql:execute-command
   (format nil "INSERT INTO `DOD_DOC_COUNTER` ~
                  (`DOC_TYPE`, `SCOPE_KIND`, `SCOPE_ID`, `TENANT_ID`, `FINYEAR`, `LAST_SEQ`) ~
                VALUES ('~A', '~A', ~D, ~A, '~A', LAST_INSERT_ID(1)) ~
                ON DUPLICATE KEY UPDATE `LAST_SEQ` = LAST_INSERT_ID(`LAST_SEQ` + 1)"
           doc-type scope-kind scope-id
           (if tenant-id (format nil "~D" tenant-id) "NULL")
           finyear))
  (let ((value (first (clsql:query "SELECT LAST_INSERT_ID()" :flatp t))))
    (if (integerp value) value (parse-integer (princ-to-string value)))))

(defun nst-doc-reference (counter &key (tenant-id 0) (scope-kind "CUSTOMER")
                                       (scope-id 0) (doc-type "ORDER") (finyear "")
                                       (length 6) (key nil))
  "COUNTER rendered as a non-sequential, unguessable reference LENGTH characters long.

  KEY overrides the DOD_SYS_SECRET key, and exists so the OFFLINE CHECK can exercise
  the permutation without a database — and so that check never has to redefine
  nst-doc-ref-key, which would clobber the real accessor in any image it was loaded
  into. NIL (the production path) reads the stored key.

  WHY NOT THE COUNTER ITSELF: a sequential suffix tells every vendor how many orders
  the customer placed with ITS COMPETITORS. DOD_ORDER is the customer's document and
  DOD_VENDOR_ORDERS copies its number (D20), so a vendor holding ...-00001 and later
  ...-00005 infers four orders elsewhere — with no request to rate-limit, which is why
  rate limiting was never a fix. See the F1 decision record in the story file's §10.

  DETERMINISTIC: the same (key, tenant, scope, doc-type, finyear, counter) always
  renders the same reference, so a migration's dry run reproduces its real run.

  ⚠ NOT INJECTIVE: an HMAC truncated to LENGTH characters is a random function, so two
  counters CAN collide (birthday bound — at 6 characters, roughly one expected
  collision per million references system-wide). The unique index on ORDNUM catches it
  and the mint retries with the next counter, which is why that retry is not
  decoration. Raising the {ref:N} width in the template removes the risk without a
  code change.

  THE INPUT IS LENGTH-PREFIXED so that two different field splits cannot render the
  same message (\"A|BC\" and \"AB|C\" are one string otherwise), which would make the
  reference depend on the delimiter not occurring inside a field."
  (let ((mac (ironclad:make-hmac
              (ironclad:ascii-string-to-byte-array (or key (nst-doc-ref-key))) :sha256)))
    (dolist (field (list (princ-to-string tenant-id) scope-kind
                         (princ-to-string scope-id) doc-type finyear
                         (princ-to-string counter)))
      (let ((s (princ-to-string field)))
        (ironclad:update-hmac mac
                              (ironclad:ascii-string-to-byte-array
                               (format nil "~D:~A" (length s) s)))))
    (let ((digest (ironclad:hmac-digest mac)))
      (when (> length (length digest))
        (error "a document reference of ~D characters needs ~D digest bytes, but ~
                HMAC-SHA-256 yields ~D." length length (length digest)))
      (let ((out (make-string length)))
        (dotimes (i length out)
          (setf (aref out i)
                (aref *nst-doc-ref-alphabet* (mod (aref digest i) 32))))))))

(defun nst-doc-number-values-lookup (values name)
  "VALUE for token NAME in VALUES, an alist of (name . string), or NIL."
  (cdr (assoc name values :test #'string-equal)))

(defun nst-doc-number-pad (value width)
  "VALUE padded to WIDTH. A DIGIT-ONLY value is zero-padded; any other value must
  ALREADY be exactly that long, and a mismatch is an ERROR rather than a silent pad —
  padding a reference with a character outside its alphabet would produce a number
  that its own validator rejects."
  (cond ((null width) value)
        ((= (length value) width) value)
        ((> (length value) width)
         (error "document-number value ~S is longer than its declared width ~D."
                value width))
        ((every #'digit-char-p value)
         (concatenate 'string (make-string (- width (length value))
                                           :initial-element #\0)
                      value))
        (t (error "document-number value ~S is shorter than its declared width ~D, ~
                   and it is not a number, so it cannot be padded — it must be ~
                   GENERATED at that width." value width))))

(defun nst-format-doc-number (template values)
  "Render TEMPLATE with a SINGLE LEFT-TO-RIGHT PASS, substituting either a braced
  {token} / {token:width} or one of the bare tokens YYYY and MM.

  ONE PASS IS THE POINT: a substituted value is never re-scanned, so a customer prefix
  that happens to contain the letters of a token cannot be expanded a second time
  (a prefix of \"YYYY\" would otherwise corrupt its own number). The bare tokens exist
  because the shipped invoice template already uses them unbraced
  (invoice-number-format is \"INV-YYYY-MM-{counter}\").

  AN UNKNOWN OR MISSING TOKEN IS AN ERROR, never emitted literally and never left
  blank: a document number that silently says {prefix} is worse than a refusal, and it
  is the kind of thing that reaches a customer."
  (let ((out (make-string-output-stream))
        (i 0)
        (n (length template)))
    (flet ((emit (name width)
             (let ((value (nst-doc-number-values-lookup values name)))
               (unless value
                 (error "document-number template ~S names {~A}, for which no value was ~
                         supplied. Known names: ~{~A~^, ~}."
                        template name (mapcar #'car values)))
               (princ (nst-doc-number-pad value width) out))))
      (loop while (< i n) do
        (let ((c (char template i)))
          (cond
            ((char= c #\{)
             (let ((close (position #\} template :start i)))
               (unless close
                 (error "document-number template ~S has an unclosed { at position ~D."
                        template i))
               (let* ((spec (subseq template (1+ i) close))
                      (colon (position #\: spec))
                      (name (if colon (subseq spec 0 colon) spec))
                      (width (when colon (parse-integer (subseq spec (1+ colon))))))
                 (emit name width)
                 (setf i (1+ close)))))
            ((and (<= (+ i 4) n) (string-equal "YYYY" (subseq template i (+ i 4))))
             (emit "YYYY" nil)
             (incf i 4))
            ((and (<= (+ i 2) n) (string-equal "MM" (subseq template i (+ i 2))))
             (emit "MM" nil)
             (incf i 2))
            (t (princ c out)
               (incf i))))))
    (get-output-stream-string out)))

(defun nst-doc-number-token-width (template name &optional default)
  "The width declared for {NAME} — or {NAME:n} — in TEMPLATE; DEFAULT when NAME
  appears without a width, NIL when it does not appear at all.

  The CALLER needs this for {ref:n}: the reference must be GENERATED at that length,
  because padding one afterwards would introduce a symbol outside its alphabet."
  (let ((i 0)
        (n (length template))
        (needle (format nil "{~A" name)))
    ;; ⚠ THE LOOP IS THE LAST FORM, ON PURPOSE. Its (return …) exits the LOOP with the
    ;; value; a trailing form after it would discard that value and the function would
    ;; answer NIL for every template — which is how this was written first, and the
    ;; "token absent → NIL" expectation hid it.
    (loop while (< i n) do
      (if (and (<= (+ i (length needle)) n)
               (string-equal needle (subseq template i (+ i (length needle)))))
          (let* ((spec-start (1+ i))
                 (close (position #\} template :start spec-start)))
            (if (null close)
                (return nil)
                (let* ((spec (subseq template spec-start close))
                       (colon (position #\: spec)))
                  (return (if colon
                              (parse-integer (subseq spec (1+ colon)))
                              default)))))
          (incf i)))))

(defparameter *nst-order-number-format* "ORD-{prefix}-{fy}-{ref:6}"
  "The ORDER number's shape, as a CODE DEFAULT rather than a settings lookup.

  ⚠ WHY NOT THE VENDOR'S SETTINGS BLOB, which is where the sibling
  invoice-number-format lives: an ORDER IS THE CUSTOMER'S DOCUMENT AND CAN SPAN
  SEVERAL VENDORS (one DOD_ORDER, N DOD_VENDOR_ORDERS rows, VENDOR_ID on the items),
  so 'the vendor's order-number format' names nothing determinate — there is no
  single vendor to ask. The key order-number-format does sit in
  *invoice-settings*' invoice-general-settings beside the invoice's own, added by S0c
  as the shared token vocabulary; whether it should STAY there, become a tenant-level
  setting, or be removed as a setting that changes nothing is recorded as an open
  question in the story file rather than silently decided here.

  The shape is still DATA: nst-format-doc-number renders it, {ref:N} reads its width
  from it, and a caller may pass a different template without touching this default.")

(defun nst-doc-prefix-valid-p (value)
  "True when VALUE can be a customer's DOC_PREFIX: 3 to 8 characters, A-Z and 0-9 only.

  ⚠ THE CHARSET IS LOAD-BEARING, NOT COSMETIC. A document number's delimiter is '-',
  so a prefix containing '-' — or digits that mimic the financial year — would make
  the number ambiguous to anything that splits it, which is why no code may ever parse
  a number by splitting it (F14). And it is why the stored column must be VARCHAR(8)
  and never CHAR(8): CHAR pads with SPACES, and the pad would land inside every number
  as 'ORD-XYZCORP -2026-27-…'.

  The 3-character floor is the one R1 fixed: 'XYZ' is recognisable, 'XY' is not."
  (and (stringp value)
       (<= 3 (length value) 8)
       (every (lambda (c) (or (char<= #\A c #\Z) (char<= #\0 c #\9))) value)))

(defun nst-doc-prefix-tokens (name)
  "NAME split into uppercase alphanumeric words. \"A.B. Traders\" -> (\"A\" \"B\" \"TRADERS\")."
  (let ((tokens '())
        (current (make-string-output-stream)))
    (flet ((flush ()
             (let ((s (get-output-stream-string current)))
               (when (plusp (length s)) (push s tokens)))))
      (loop for ch across (or name "")
            do (if (or (char<= #\A ch #\Z) (char<= #\a ch #\z) (char<= #\0 ch #\9))
                   (princ ch current)
                   (flush)))
      (flush))
    (nreverse (mapcar #'string-upcase tokens))))

(defun nst-doc-prefix-base (name &optional (max-length 8))
  "NAME reduced to a prefix BASE of 3 to MAX-LENGTH characters, taking WHOLE WORDS:
  \"XYZ CORP LIMITED\" -> \"XYZCORP\", which is the requester's own worked example and
  the reason this is word-based rather than a slice of the name.

  ⚠ NOT THE FIRST 8 CHARACTERS. That version was written first and the offline check
  caught it: \"XYZ CORP LIMITED\" sliced to 8 gives \"XYZCORPL\" — gibberish to the
  vendor reading the number aloud, where \"XYZCORP\" is the company's own short name.
  The rules, in order:
    * the FIRST word, truncated to MAX-LENGTH if it alone is longer;
    * then each following word, while the total stays within MAX-LENGTH;
    * if the total is still under 3 characters, take just enough characters from the
      NEXT word to reach 3 (so \"A.B. Traders\" -> \"ABT\", not a refusal);
    * NIL when the name holds fewer than 3 alphanumerics at all — a refusal, because a
      2-character prefix is not an identity.

  A DERIVATION, NOT AN ALLOCATION — which is precisely why it collides, and why
  nst-doc-prefix-candidates exists."
  (let ((tokens (nst-doc-prefix-tokens name)))
    (when tokens
      (let ((result "")
            (firstp t))
        (dolist (tok tokens)
          (cond
            (firstp
             (setf result (subseq tok 0 (min max-length (length tok)))
                   firstp nil))
            ((<= (+ (length result) (length tok)) max-length)
             (setf result (concatenate 'string result tok)))
            ((< (length result) 3)
             (setf result (concatenate 'string result
                                       (subseq tok 0 (min (- 3 (length result))
                                                          (length tok)))))
             (return))
            (t (return))))
        (when (>= (length result) 3)
          result)))))

(defun nst-doc-prefix-candidates (name)
  "The base for NAME, then the deterministic de-duplication ladder (R2):

    base            XYZCORP
    6 + 2-digit      XYZCOR01 … XYZCOR99     (base truncated to 6, probe 01..99)
    5 + 3-digit      XYZC001 … XYZC999       (base truncated to 5, probe 001..999)

  ALWAYS INSIDE varchar(8), always recognisable, and ALWAYS THE SAME ORDER — which is
  what makes a re-run reproducible and lets a dry run predict exactly which suffix a
  customer will receive.

  ⚠ DE-DUPLICATED, AND THAT IS NOT PADDING: the two rungs can collide for a base whose
  sixth character is a digit — base \"XYZCO0\" gives \"XYZCO001\" from BOTH the 6+2 and
  the 5+3 rung. The ladder is a HEURISTIC anyway; the UNIQUE index on DOC_PREFIX is the
  guarantee, and a duplicate inside one ladder would waste a rung and confuse the dry
  run's report." 
  (let ((base (nst-doc-prefix-base name)))
    (when base
      (remove-duplicates
       (cons base
             (append (loop for n from 1 to 99
                           collect (format nil "~A~2,'0D" (subseq base 0 (min 6 (length base))) n))
                     (loop for n from 1 to 999
                           collect (format nil "~A~3,'0D" (subseq base 0 (min 5 (length base))) n))))
       :test #'string= :from-end t))))

(defun nst-allocate-doc-prefix (name &optional taken)
  "The first candidate for NAME that is not already in TAKEN — a list of stored prefix
  strings, compared case-insensitively. NIL when the whole ladder is taken, which the
  caller must report as a refusal: inventing a value would defeat the reason the prefix
  exists (it is the document series' identity, not a free-text label)."
  (let ((used (mapcar #'string-upcase taken)))
    (find-if (lambda (candidate) (not (member candidate used :test #'string=)))
             (nst-doc-prefix-candidates name))))

(defun nst-doc-prefix-taken ()
  "Every DOC_PREFIX already stored, so allocation can avoid them.

  `clsql:query … :flatp t` returns a FLAT list of the column's values — one scalar per
  row, NOT a list per row — which is the same convention get-vendors-by-orderid in
  order/dod-bl-ord.lisp relies on when it maps select-vendor-by-id over the result.

  ⚠ IT FAILS LOUDLY BEFORE THE COLUMN EXISTS rather than reporting an empty list: an
  empty list would let allocation hand out a prefix that is already in use on a
  database where the column is simply missing. The ALTER is the migration's first
  step, and this message is what a caller sees if it is not."
  (handler-case
      (clsql:query "SELECT `DOC_PREFIX` FROM `DOD_CUST_PROFILE` WHERE `DOC_PREFIX` IS NOT NULL"
                   :flatp t)
    (error (c)
      (error "cannot read the stored document prefixes: ~A. If DOD_CUST_PROFILE has no ~
              DOC_PREFIX column yet, the ordnum-identity migration has not been applied ~
              (its first step is that ALTER)." c))))

(defun nst-doc-prefix-read (cust-id)
  "The stored DOC_PREFIX for CUST-ID, or NIL when it has none yet."
  (first (clsql:query (format nil "SELECT `DOC_PREFIX` FROM `DOD_CUST_PROFILE` ~
                                    WHERE `ROW_ID` = ~D" cust-id)
                      :flatp t)))

(defun nst-doc-prefix-assign (cust-id name)
  "Allocate a prefix for CUST-ID from NAME and STORE it — the lazy allocation R2 chose
  over touching the six places that create a customer row. Returns the prefix, and
  SIGNALS rather than improvising when NAME yields no usable base or the ladder is
  exhausted.

  The STORE is a plain UPDATE of that one column, so it cannot disturb any other
  customer field. A caller inside a transaction gets atomicity for free; a caller
  outside one accepts that a crash between the UPDATE and the return would leave a
  prefix allocated-but-unused — which costs a rung of the ladder, not a duplicate."
  (let ((base (nst-doc-prefix-base name)))
    (unless base
      (error "customer ~D has no usable document prefix: its name (~S) holds fewer ~
              than 3 alphanumeric characters, so nothing recognisable can be derived. ~
              Set DOC_PREFIX by hand for this customer." cust-id name))
    (let ((chosen (nst-allocate-doc-prefix name (nst-doc-prefix-taken))))
      (unless chosen
        (error "every document prefix candidate for customer ~D (~S) is already taken. ~
                Set DOC_PREFIX by hand for this customer." cust-id base))
      (clsql:execute-command
       (format nil "UPDATE `DOD_CUST_PROFILE` SET `DOC_PREFIX` = '~A' WHERE `ROW_ID` = ~D"
               chosen cust-id))
      chosen)))

(defun nst-order-number-for (template customer-prefix order-date tenant-id cust-id
                                      &key counter key)
  "The next ORDER number for CUST-ID on ORDER-DATE, allocated from the counter and
  rendered through TEMPLATE.

  THE THREE CALLERS GO THROUGH HERE — the ordnum-identity migration, nst-ordh's make and
  the S8b legacy funnels — so the series cannot fork into a second implementation.
  CUSTOMER-PREFIX is the customer's DOC_PREFIX (S0d); the counter is scoped per
  (customer, financial year), and the reference width comes from the template, which is
  what makes {ref:6} versus {ref:8} a data change rather than a code change.

  :COUNTER SUPPLIES the sequence value instead of allocating one, and it exists for the
  DRY RUN: allocating writes to DOD_DOC_COUNTER, so a dry run must not call the
  allocator — and if it assembled the number any other way, the dry run and the real run
  would be different code paths and the review would be worthless. Both paths render
  through this one function.
  :KEY is passed to nst-doc-reference and exists for the offline check, which has no
  database to read the stored key from."
  (let* ((fy (nst-financial-year-short order-date))
         (seq (or counter (nst-next-doc-counter "ORDER" "CUSTOMER" cust-id fy tenant-id)))
         (ref-width (or (nst-doc-number-token-width template "ref") 6))
         (ref (nst-doc-reference seq :tenant-id (or tenant-id 0)
                                 :scope-kind "CUSTOMER" :scope-id cust-id
                                 :doc-type "ORDER" :finyear fy :length ref-width
                                 :key key)))
    (nst-format-doc-number
     template
     (list (cons "PREFIX" (or customer-prefix ""))
           (cons "FY" fy)
           (cons "REF" ref)
           (cons "COUNTER" (princ-to-string seq))
           (cons "YYYY" (subseq (nst-financial-year-label order-date) 0 4))
           (cons "MM" (nst-financial-year-month order-date))))))







;;;; Virtual host related things ;;;; 
  

;;; ───────────────────────────────────────────────────────────────────────────
;;; The DB-slot coercion — INTEGER → float where the CLSQL class admits floats (S7)
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; MOVED HERE FROM invoice/nst-bl-invh.lisp, where the invoice batch wrote it after
;;; MEASURING the defect: CLSQL's view classes declare the money and rate columns (OR NULL
;;; FLOAT) and VALIDATE ON INSERT, so an ordinary JSON integer — {price: 100} — is refused,
;;; and the refusal reaches the client as :U (503) "the database call did not answer". The
;;; invoice batch lost a day to it twice: once for the OMITTED field (fixed by the 0.0
;;; class initforms) and once for the SUPPLIED one (fixed by this coercion).
;;;
;;; WHY IT IS IN CORE AND NOT IN EITHER ENTITY FILE: it is generic (a CLSQL class's declared
;;; slot type, read through the MOP — it knows nothing about invoices or orders), it has two
;;; callers in two different files today, and the ORDER files load BEFORE the invoice's, so
;;; a version living in nst-bl-invh.lisp is unreachable from them. Build position 128 / asd
;;; 62 puts this ahead of every entity file — the same argument as D16's row-id guard.
;;;
;;; The coercion reads the DESTINATION CLASS's declared type rather than a hand-kept list of
;;; money columns: a list would drift from the CLSQL classes the moment one of them changes
;;; type, which is exactly the drift the mirror lists already had to be documented against.

(defun nst-db-slot-type (object slot)
  "The type SLOT declares on OBJECT's class, or NIL if it cannot be read."
  (ignore-errors
    (sb-mop:slot-definition-type
     (find slot (sb-mop:class-slots (class-of object))
           :key #'sb-mop:slot-definition-name))))

(defun nst-db-float-slot-p (type)
  "T when a CLSQL-declared slot TYPE admits floats.

  🚨 IT IS NOT THE BARE SYMBOL. CLSQL declares these slots (OR NULL FLOAT) — measured
  2026-09-26 against dod-Invoice-Header TOTALVALUE — so an (eq type 'float) test is FALSE for
  every one of them, and the coercion below silently became a NO-OP: no error, no warning,
  just an INSERT failing exactly as before. A guard that cannot fire is worse than no guard,
  because it reads as fixed."
  (or (eq type 'float)
      (and (consp type) (member 'float type))))

(defun nst-coerce-for-db-slot (destination slot value)
  "VALUE as DESTINATION's SLOT will accept it. INTEGER → float where the slot admits floats.
  Everything else passes through untouched — a narrow widening, not a general type system:
  a wrong coercion would be worse than a failed INSERT."
  (if (and (nst-db-float-slot-p (nst-db-slot-type destination slot))
           (integerp value))
      (float value)
      value))

;;; ───────────────────────────────────────────────────────────────────────────
;;; GST STATE IDENTITY — one home for "which state is this, and are they the same?"
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; 🚨 WHY THIS EXISTS: the cart compared the customer's TYPED state NAME against the vendor row's `state`
;;; column — which holds a CODE for one vendor and a NAME for others, in the same tenant (vendor 1 "29",
;;; vendors 2-3 "Karnataka"). `(equal "KARNATAKA" "29")` is NIL, so a Karnataka-to-Karnataka sale was taxed
;;; INTER-state: order 488 carries IGST 205.20 with CGST/SGST 0.00. The rule that decides which half of the
;;; tax applies must not depend on how a human spelled it.

(defun nst-gst-state-code-of (state-or-code)
  "The GST state CODE for STATE-OR-CODE: a code passes through; a NAME resolves through
   *NSTGSTSTATECODES-HT* (code to name), tolerating punctuation, spacing and the bracketed suffixes that
   hash carries (ANDHRA PRADESH (NEWLY ADDED) against the pincode table's plain ANDHRA PRADESH); a GSTIN
   yields its first two digits. NIL when none of those answer — a caller must DECIDE, never guess."
  (let ((text (and state-or-code
                   (string-upcase (string-trim " " (string state-or-code))))))
    (when (and text (plusp (length text)))
      (cond
        ;; a code: 1-2 digits, as the GST state codes are
        ((and (<= (length text) 2) (every #'digit-char-p text)) text)
        ;; a GSTIN or a state name that BEGINS with the code, e.g. "29ALSKDKJADS455"
        ((and (> (length text) 2) (every #'digit-char-p (subseq text 0 2))) (subseq text 0 2))
        ((hash-table-p *NSTGSTSTATECODES-HT*)
         (let ((want (nst-gst-state-name-key text)))
           (loop for code being the hash-keys of *NSTGSTSTATECODES-HT*
                   using (hash-value name)
                 when (equal (nst-gst-state-name-key (string name)) want)
                   return code)))
        (t nil)))))

;;; ───────────────────────────────────────────────────────────────────────────
;;; THE DELIVERY CHARGE — one derivation, and one principal-rate rule
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; A delivery charge is part of the taxable value (Section 15(2)(c) CGST: incidental expenses and any
;;; other costs incurred in relation to the supply) and, being ancillary to the goods, a COMPOSITE SUPPLY
;;; taxed at the principal supply's rate (Section 2(30) with Section 8) — never at a flat 18% unless the
;;; transport is a SEPARATE supply. The full position, both readings and the CA questions are
;;; `knowledge/gst-tax-jurisdiction-CONTEXT.md` §1 and §6.

(defun nst-principal-rate-of (line-rates)
  "The (CGST SGST IGST) rates of the highest-taxable entry of LINE-RATES, where each entry is
   (TAXABLE CGST SGST IGST). Section 8 taxes a composite supply as its principal supply, and the
   predominant element is the practical proxy for one. NIL when there is no entry."
  ;; ⚠ THE NIL GUARD IS LOad-BEARING: with :initial-value nil the first call is (fn nil FIRST-ENTRY), and
  ;; (float (first nil)) SIGNALS — measured, it took the invoice's freight path down with %SINGLE-FLOAT NIL.
  (let ((biggest (reduce (lambda (a b)
                           (if (or (null a) (> (float (first b)) (float (first a)))) b a))
                         line-rates :initial-value nil)))
    (when biggest (rest biggest))))

(defun nst-gstin-present-p (gstin)
  "बहुव्रीहि: did the buyer give a GSTIN? That is the B2B line this tree can trust — a registered person
   wants the tax broken out and claims it, a consumer must see the all-in price. ⚠ MEASURED, and why the
   alternatives are not used: only 2 of 26 customers have a GSTIN, while the profile's
   GST_CUSTOMER_TYPE flag says B2B for 24 of 26 (a default, not a fact) and CUST_TYPE is a LOGIN type."
  (and gstin (plusp (length (string-trim " " (string gstin))))))

(defun nst-shipping-tax-split (amount rate-percent &key inclusive)
  "The (values TAXABLE TAX) of a delivery charge of AMOUNT at RATE-PERCENT.

   EXCLUSIVE (the default, and the B2B reading): the vendor's amount is pre-tax — the customer pays
   the charge PLUS the tax, and a registered buyer claims the freight's ITC (₹100 → 100.00 + 18.00).
   INCLUSIVE (the B2C reading): the amount is what the customer pays and the tax sits inside it,
   back-calculated so TAXABLE + TAX = AMOUNT exactly (₹100 → 84.75 + 15.25, never 84.76 + 15.25)."
  (let* ((amt (round-to-2-decimal amount))
         (rate (float rate-percent)))
    (if inclusive
        (let ((taxable (round-to-2-decimal (/ amt (+ 1 (/ rate 100))))))
          (values taxable (round-to-2-decimal (- amt taxable))))
        (values amt (round-to-2-decimal (* amt (/ rate 100)))))))

(defun nst-gst-state-name-key (text)
  "TEXT as a comparable key: upcased, bracketed suffixes dropped, runs of non-alphanumerics collapsed to one
   space, trimmed. So Andhra Pradesh (Newly Added) and ANDHRA PRADESH are one key."
  (let ((out (make-string-output-stream))
        (skip nil)
        (pending-space nil))
    (loop for ch across (string-upcase (string text))
          do (cond
               ((char= ch #\() (setf skip t))
               ((char= ch #\)) (setf skip nil))
               (skip nil)
               ((alphanumericp ch)
                (when pending-space (write-char #\Space out) (setf pending-space nil))
                (write-char ch out))
               (t (setf pending-space t))))
    (string-trim " " (get-output-stream-string out))))

(defun nst-same-gst-state-p (a b)
  "बहुव्रीहि: are A and B the SAME GST state? Resolves both to codes first, so a name and a code for one
   state answer T. NIL when either cannot be resolved — NEVER 'different', which is how the cart silently
   chose IGST: an unknown state is not evidence of another state."
  (let ((ca (nst-gst-state-code-of a))
        (cb (nst-gst-state-code-of b)))
    (and ca cb (equal ca cb))))

(defun nst-db-slot-value-from-domain (source slot)
  "SLOT's value on a DOMAIN entity SOURCE, or NIL when the create never bound it. `slot-value` on an unbound
   slot SIGNALS, and a create binds only what the caller sent — see the tool nst-verify-order-create.lisp."
  (if (slot-boundp source slot) (slot-value source slot)))

;;; ───────────────────────────────────────────────────────────────────────────
;;; The order STATUS vocabulary — one home for a rule the legacy layer and the
;;; adhara verbs must agree about (D17, story S8)
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; WHY THIS IS IN CORE AND NOT IN EITHER ORDER FILE: STATUS is the one column the whole
;;; order feature branches on — the adhara verbs (make, !update, delete!, the line verbs),
;;; the legacy vendor and item reads, and the legacy item VIEW that renders Pending or
;;; Fulfilled — and it is char(3), so a wrong string is not a wrong answer but an empty
;;; result set. Before this, the open set existed as the literal "PEN" in seven legacy
;;; reads while the new API minted "DFT", so an order created through the new API was
;;; INVISIBLE to every legacy list. That is the defect S8 exists to fix, and a rule with
;;; two spellings is how it happened.
;;;
;;; THE VOCABULARY IS THREE CHARACTERS WIDE, MEASURED: STATUS is char(3) on DOD_ORDER,
;;; DOD_ORDER_ITEMS and DOD_VENDOR_ORDERS, so "DRAFT" could not be stored at all. The
;;; five codes below are the live vocabulary.

(defparameter *order-open-statuses* '("DFT" "PEN")
  "The statuses in which an order is still being built: DFT (minted by the new API's make)
   and PEN (what every legacy creation path writes). An OPEN order may receive lines, may be
   edited, and is what 'pending' means in every legacy list.

   ⚠ SHARED, DELIBERATELY: the adhara verbs (nst-bl-ordh.lisp, nst-bl-orditm.lisp) and the
   retrofitted legacy reads all read THIS list. A second copy anywhere would re-open the
   S8 defect, whose shape was exactly that: the new code said DFT, the old code said PEN, and
   neither was wrong on its own.")

(defparameter *order-terminal-statuses* '("CMP" "VCN" "CCN")
  "The statuses in which the order has finished moving: CMP completed, VCN cancelled by the
   vendor, CCN cancelled by the customer. Content may not change and the document may not be
   deleted — what a finished order needs is a new document, not an edit (D8).")

(defun order-open-status-p (status)
  "Is STATUS one of *order-open-statuses*? Accepts a string, a keyword or a symbol, and
   upcases first, because the legacy layer passes strings and the adhara verbs may carry
   keywords. NIL (a NULL column, which char(3) DEFAULT NULL permits) is NOT open — an order
   with no status is not an order anyone may act on."
  (and status
       (member (string-upcase (string status)) *order-open-statuses* :test #'string=)
       t))

(defun order-terminal-status-p (status)
  "Is STATUS one of *order-terminal-statuses*? The same coercion as order-open-status-p, and
   the same rule about NIL: an unknown status is neither open nor terminal, and the callers
   that must not proceed treat 'not open' as the refusal."
  (and status
       (member (string-upcase (string status)) *order-terminal-statuses* :test #'string=)
       t))

;;; ───────────────────────────────────────────────────────────────────────────
;;; The order-number MINT as one call (S8b) — for the callers that hold only an id
;;; ───────────────────────────────────────────────────────────────────────────
;;;
;;; WHY THIS EXISTS BESIDE nst-order-number-for: that function mints from a PREFIX, and obtaining
;;; the prefix needs the CUSTOMER — a name to derive one from on first use (R2's lazy allocation).
;;; The adhara create path holds the customer's ORM row and resolves the name from its slots
;;; (nst-customer-document-name, order/nst-bl-ordh.lisp). The LEGACY funnels hold only a cust-id,
;;; and they load BEFORE the customer and order BL files, so neither that resolver nor the
;;; tenant-scoped customer selector is reachable from them. This function therefore resolves the
;;; name in SQL from the id — and its precedence is the ordnum-identity migration's own COALESCE,
;;; so the backfill and a first order cannot disagree about which name a customer's prefix comes
;;; from. Two spellings of one rule, forced by what the caller holds and named rather than hidden;
;;; if the row-holding form ever becomes reachable from here, one of them should go.

(defun nst-customer-name-for-prefix (cust-id tenant-id)
  "The customer name a DOC_PREFIX is derived from, or NIL when that row is not in TENANT-ID.

   TENANT-SCOPED DELIBERATELY: a prefix derived from another tenant's customer row would write a
   value derived from data this tenant cannot see, and the migration's own query is scoped the same
   way. A NIL answer is not an error — it means the caller must not allocate (see the mint below)."
  (first (clsql:query
          (format nil "SELECT COALESCE(NULLIF(`LEGAL_COMPANY_NAME`, \'\'), ~
                                        NULLIF(`LEGAL_NAME`, \'\'), ~
                                        NULLIF(`COMPANY_NAME`, \'\'), ~
                                        `NAME`) ~
                        FROM `DOD_CUST_PROFILE` ~
                       WHERE `ROW_ID` = ~D AND `TENANT_ID` = ~D"
                  cust-id tenant-id)
          :flatp t)))

(defun nst-mint-order-number-for-customer (cust-id tenant-id ord-date)
  "The next ORDNUM for CUST-ID on ORD-DATE, reading or allocating its DOC_PREFIX first.
   Returns (values NUMBER REFUSAL-REASON) — exactly one of which is non-NIL.

   ⚠ THIS IS THE S8b FIX, AND THE REASON IT RETURNS A REFUSAL RATHER THAN WRITING NULL IS THE WHOLE
   POINT: the two legacy funnels (persist-order and persist-vendor-orders) never wrote ORDNUM at all,
   so every order they created was unaddressable — the number is the ADDRESS the vendor channel and
   the new API both quote. A funnel that cannot mint must therefore FAIL THE CREATE, not proceed with
   a NULL: an order with no address is worse than no order, because it looks like a success.

   The prefix is allocated on FIRST USE, lazily, exactly as the adhara create path does (R2) — the
   alternative was touching the six places that create a customer row. Both the read and the
   allocation are the ones S0d landed; nothing here re-implements them.
   A customer row that cannot be seen, or a name that yields no usable prefix, comes back as a
   refusal string the caller raises on."
  (handler-case
      (let* ((row-name (nst-customer-name-for-prefix cust-id tenant-id))
             (prefix (or (nst-doc-prefix-read cust-id)
                         (and row-name (nst-doc-prefix-assign cust-id row-name)))))
        (cond
          ((null prefix)
           (values nil (format nil "customer ~D has no DOC_PREFIX and none could be allocated~@[ (its name ~S yields no usable base)~]"
                               cust-id row-name)))
          (t
           (values (nst-order-number-for *nst-order-number-format* prefix ord-date tenant-id cust-id)
                   nil))))
    (error (c)
      (values nil (format nil "the order number could not be minted for customer ~D (~A)" cust-id c)))))
