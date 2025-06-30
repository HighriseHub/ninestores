;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)



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


(defun generatepdf (inputhtmlfile outpdffilename)
  (let* ((filename (format nil "~A~A.pdf" outpdffilename (get-universal-time)))
	 (filepath (format nil "~A/temp/~A" *HHUBRESOURCESDIR* filename))
	 (htmlpath (format nil "~A/temp/~A" *HHUBRESOURCESDIR* inputhtmlfile))
	 (pdfcmd (format nil "wkhtmltopdf --disable-javascript ~A ~A" htmlpath filepath)))
    (sb-ext:run-program "/bin/sh" (list "-c" pdfcmd) :input nil :output *standard-output*)
    filename))


(defun downloadhtmlfile (url)
  (let* ((filename (format nil "download~A.html" (get-universal-time)))
	 (filepath (format nil "~A/temp/~A" *HHUBRESOURCESDIR* filename))
	 (command (format nil "wget -O ~A ~A" filepath url)))
    (sb-ext:run-program "/bin/sh" (list "-c" command) :input nil :output *standard-output*)
    filename))




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
  (with-output-to-string (stream)
    (let ((*print-base* 36))
      (loop repeat length do (princ (random 36) stream)))))       


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
  (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :md5 (ironclad:ascii-string-to-byte-array plaintext))))

(defun create-md5-from-list (items)
  "Takes a list of strings, joins them with commas, and returns the MD5 digest."
  (let ((joined (format nil "~{~A~^,~}" items)))
    (create-digest-md5 joined)))

(defun decrypt (ciphertext key)
  (let ((cipher (get-cipher key))
        (msg (ironclad:integer-to-octets (ironclad:octets-to-integer (ironclad:ascii-string-to-byte-array ciphertext)))))
    (ironclad:decrypt-in-place cipher msg)
    (coerce (mapcar #'code-char (coerce msg 'list)) 'string)))

(defun check-password (plaintext salt ciphertext)
  (if (equal (encrypt plaintext salt) ciphertext) T NIL)) 





;;;; Virtual host related things ;;;; 
  
