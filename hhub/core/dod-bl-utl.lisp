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





;;;; Virtual host related things ;;;; 
  
