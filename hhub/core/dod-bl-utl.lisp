;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

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

(defun create-entity-bl-template (entityname fieldnames destfile)
  :description "This function will create a set of business layer functions based on the business object / entity name"
  (let* ((filecontent (hhub-read-file "~/ninestores/hhub/core/hhub-bl-egn.lisp"))
	 (count 65)
	 (fieldname ""))
    (loop for field in fieldnames do
      (setf fieldname (format nil "field~A" (code-char count)))
      (setf filecontent (cl-ppcre:regex-replace-all fieldname filecontent field))
      (incf count))
      (let ((temp-str (cl-ppcre:regex-replace-all "xxxx" filecontent entityname)))
	(with-open-file (stream destfile :if-does-not-exist :create :if-exists :append :direction :output)
	  (print (format stream temp-str))
	  (terpri stream)))))
(defun create-entity-ui-template (entityname fieldnames destfile)
  :description "This function will create a set of business layer functions based on the business object / entity name"
  (let* ((filecontent (hhub-read-file "~/ninestores/hhub/core/hhub-ui-egn.lisp"))
	 (count 65)
	 (fieldname ""))
    (loop for field in fieldnames do
      (setf fieldname (format nil "field~A" (code-char count)))
      (setf filecontent (cl-ppcre:regex-replace-all fieldname filecontent field))
      (incf count))
    (let ((temp-str (cl-ppcre:regex-replace-all "xxxx" filecontent entityname)))
      (with-open-file (stream destfile :if-does-not-exist :create :if-exists :append :direction :output)
	(print (format stream temp-str))
	(terpri stream)))))
(defun create-entity-dal-template (entityname fieldnames destfile)
  :description "This function will create a set of business layer functions based on the business object / entity name"
  (let* ((filecontent (hhub-read-file "~/ninestores/hhub/core/hhub-dal-egn.lisp"))
	 (count 65)
	 (fieldname ""))
    (loop for field in fieldnames do
      (setf fieldname (format nil "field~A" (code-char count)))
      (setf filecontent (cl-ppcre:regex-replace-all fieldname filecontent field))
      (incf count))
      (let ((temp-str (cl-ppcre:regex-replace-all "xxxx" filecontent entityname)))
	(with-open-file (stream destfile :if-does-not-exist :create :if-exists :append :direction :output)
	  (print (format stream temp-str))
	  (terpri stream)))))





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

(defun decrypt (ciphertext key)
  (let ((cipher (get-cipher key))
        (msg (ironclad:integer-to-octets (ironclad:octets-to-integer (ironclad:ascii-string-to-byte-array ciphertext)))))
    (ironclad:decrypt-in-place cipher msg)
    (coerce (mapcar #'code-char (coerce msg 'list)) 'string)))

(defun check-password (plaintext salt ciphertext)
  (if (equal (encrypt plaintext salt) ciphertext) T NIL)) 





;;;; Virtual host related things ;;;; 
  
