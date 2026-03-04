;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)



(defparameter *ollama-url* "http://192.168.0.100:11434/api/generate")
(defparameter *ollama-model* "qwen2.5:3b")
(defvar *dod-vend-profile-table* "/home/ubuntu/ninestores/hhub/vendor/templates/dod-vend-profile.txt")
(defvar *dod-invoice-header-table* "/home/ubuntu/ninestores/hhub/vendor/templates/dod-invoice-header.txt")
(defvar *dod-invoice-items-table* "/home/ubuntu/ninestores/hhub/vendor/templates/dod-invoice-items.txt")


(defun ollama-generate (prompt &key system)
  (let* ((payload
           (json:encode-json-to-string
            `((:model . ,*ollama-model*)
              (:prompt . ,prompt)
              (:system . ,system)
              (:stream . nil))))
	 (raw-response
           (drakma:http-request
            *ollama-url*
            :method :POST
	    :content payload
            :content-type "application/json"))
         (json-response
           ;;(json:decode-json-from-string
            (parse-ollama-ndjson (map 'string #'code-char raw-response))))
    json-response))


(defun parse-ollama-ndjson (string)
  (let ((out ""))
    (dolist (line (split-sequence:split-sequence #\Newline string))
      (when (> (length line) 0)
        (let* ((obj (json:decode-json-from-string line))
              (chunk (cdr (assoc :RESPONSE obj))))
            (setf out (concatenate 'string out chunk)))))
    out))



  


(defparameter *sql-schema-rules*
  "Rules:
- Use only tables and columns from the schema
- Do not invent tables or columns
- Do not explain the query
- Vendors are identified by VENDOR_ID
- Soft deletes use DELETED_STATE = 'N'
- ACTIVE_FLAG = 'Y' means active
- Monetary fields are DECIMAL
- Never select PASSWORD, SALT, API keys
- Default tenant isolation: TENANT_ID = :tenant_id
- Return only SQL
If the request cannot be answered using the schema,
return:
ERROR: CANNOT_GENERATE_SQL")

(defun nl-to-sql (natural-language)
  (let ((sql-schema (format nil "~A ~A ~A "
	  (funcall (nst-get-cached-vendor-tables-structure-for-agentic-ai :templatenum 1))
	  (funcall (nst-get-cached-vendor-tables-structure-for-agentic-ai :templatenum 2))
	  (funcall (nst-get-cached-vendor-tables-structure-for-agentic-ai :templatenum 3)))))
    (ollama-generate
     (format nil
             "Database Schema:
~A
~A 
User Request:
~A"
           sql-schema *sql-schema-rules* natural-language)
   :system
   "You are a MySQL query generator. Return a complete SQL query.
The query must end with a semicolon.")))

(defun ollama-lisp-help (code)
  (ollama-generate
   code
   :system
   "You are a senior Common Lisp developer.
Explain idiomatic Lisp usage, macros, closures,
and functional design. Be precise and concise."))

(defun unsafe-sql-p (sql)
  (or (search "DROP" sql :test #'char-equal)
      (search "TRUNCATE" sql :test #'char-equal)
      (search "ALTER" sql :test #'char-equal)
      (search "DELETE" sql :test #'char-equal)))

(defun safe-nl-to-sql (input)
  (let ((sql (nl-to-sql input)))
    (if (unsafe-sql-p sql)
        (error "Unsafe SQL generated: ~A" sql)
        sql)))


