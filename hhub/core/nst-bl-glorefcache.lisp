;;; nst-bl-glorefcache.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

(defpackage :cl-global-cache
  (:use :cl)
  (:export #:global-cache
           #:get-entry
           #:set-entry
           #:invalidate
           #:persist
           #:restore
           #:defcached
	   #:with-global-cache
           #:*default-cache*))

(in-package :cl-global-cache)

;; --- Data Structure ---
(defstruct cache-entry
  value
  expiry-time)

;; --- Class Definition ---
(defclass global-cache ()
  ((data
    :initform (make-hash-table :test 'equal)
    :accessor cache-data
    :documentation "The internal MUMPS-like hash table.")
   (lock
    :initform (bt:make-lock "Global-Cache-Lock")
    :accessor cache-lock
    :documentation "Thread-safety lock for this specific cache instance.")
   (name
    :initarg :name
    :initform "Default Cache"
    :accessor cache-name))
  (:documentation "A persistent, thread-safe, hierarchical cache instance."))

;; --- Generics ---
(defgeneric get-entry (cache key)
  (:documentation "Retrieve a value from the specific cache instance."))

(defgeneric set-entry (cache key value &key ttl)
  (:documentation "Store a value in the specific cache instance."))

(defgeneric invalidate (cache prefix)
  (:documentation "Remove entries matching the S-expression prefix."))

(defgeneric persist (cache filename)
  (:documentation "Save the cache instance to disk."))

(defgeneric restore (cache filename)
  (:documentation "Load cache data from disk into the instance."))

(defgeneric execute-cache (cache func-name args &key ttl prefix-args)
  (:documentation "The central dispatch for the caching dimension pipeline."))

(defmethod execute-cache (cache func-name args &key &allow-other-keys)
  "The Primary Method: Raw execution of the underlying logic."
  (apply func-name args))


(defmethod execute-cache :around (cache func-name args &key (prefix-args 1) ttl &allow-other-keys)
  "The Around Method: Handles the cache lookup/populate logic."
  (let* ((invalidation-prefix (subseq args 0 (min prefix-args (length args))))
         (complex-args (subseq args (min prefix-args (length args)) (length args)))
         (digest (hash-lisp-object complex-args))
         (key (append (list 'func-name) invalidation-prefix (list digest))))
    (multiple-value-bind (val hit-p) (get-entry cache key)
      (if hit-p
          val ;; Cache Hit: Return immediately
          (let ((result (call-next-method))) ;; Cache Miss: Run Before -> Primary -> After
            (set-entry cache key result :ttl ttl) ;; Store result
            result)))))

(defmethod execute-cache :before (cache func-name args &key &allow-other-keys)
  "Dimension: Logging and Audit."
  (format t "~&[LOG] Requesting ~A with args ~A" func-name args))

(defmethod execute-cache :after (cache func-name args &key &allow-other-keys)
  "Dimension: Metrics. (Only runs on cache miss)"
  (format t "~&[LOG] Cache miss happened for  ~A with args ~A" func-name args))
  ;;(track-metric cache :miss func-name))
;; --- Methods Implementation ---


(defmethod get-entry ((self global-cache) key)
  (bt:with-lock-held ((cache-lock self))
    (let ((entry (gethash key (cache-data self))))
      (when entry
        (if (and (cache-entry-expiry-time entry)
                 (> (get-universal-time) (cache-entry-expiry-time entry)))
            (progn
              (remhash key (cache-data self))
              (values nil nil))
            (values (cache-entry-value entry) t))))))

(defmethod set-entry ((self global-cache) key value &key (ttl 300))
  (let ((expiry (if ttl (+ (get-universal-time) ttl) nil)))
    (bt:with-lock-held ((cache-lock self))
      (setf (gethash key (cache-data self))
            (make-cache-entry :value value :expiry-time expiry))))
  value)

(defun invalidate-prefix (cache search-prefix)
  "Safely clears all entries starting with search-prefix."
  (let ((keys-to-remove '())
        (len (length search-prefix)))
    (bt:with-lock-held ((cache-lock cache))
      ;; 1. Collect keys first (Avoids modifying table during iteration)
      (maphash (lambda (k _) 
                 (declare (ignore _)) ;; Explicitly tell the compiler we don't need 'v'
                 (when (and (listp k)
                            (>= (length k) len)
                            (equal search-prefix (subseq k 0 len)))
                   (push k keys-to-remove)))
               (cache-data cache))
      
      ;; 2. Perform the deletions
      (dolist (k keys-to-remove)
        (remhash k (cache-data cache))))
    (length keys-to-remove))) ;; Return count of invalidated items


(defmethod persist ((self global-cache) filename)
  (bt:with-lock-held ((cache-lock self))
    (with-open-file (stream filename
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (let ((data (cache-data self)))
        (format t "~&Persisting ~A: ~D entries to ~A..." 
                (cache-name self) (hash-table-count data) filename)
        (princ data stream)))))

(defmethod restore ((self global-cache) filename)
  (if (probe-file filename)
      (bt:with-lock-held ((cache-lock self))
        (with-open-file (stream filename :direction :input)
          (setf (cache-data self) (read stream))
          (format t "~&Restored ~A from ~A." (cache-name self) filename)))
      (warn "Restoration failed: File ~A not found." filename)))

;; --- Utilities (Static Functions) ---

(defun hash-lisp-object (object)
  "Serializes a Lisp object and returns a truncated SHA1 hex string."
  (let* ((string-rep (prin1-to-string object))
         (octets (babel:string-to-octets string-rep :encoding :utf-8))
         (digest (ironclad:digest-sequence :sha1 octets)))
    ;; We use a 10-character subseq for brevity in the key, 
    ;; but you can use the full (ironclad:byte-array-to-hex-string digest)
    (subseq (ironclad:byte-array-to-hex-string digest) 0 12)))

(defun build-hybrid-key (func-name args prefix-count)
  "Constructs a hierarchical key: (FUNC-NAME PREFIX-1 ... PREFIX-N HASH)
   - FUNC-NAME: The symbol of the function.
   - PREFIX-COUNT: How many arguments to keep in plain text.
   - ARGS: The full list of arguments passed to the function."
  (let* ((total-arg-count (length args))
         (actual-prefix-count (min prefix-count total-arg-count))
         ;; 1. Extract the readable part (The 'Global' nodes)
         (prefix (subseq args 0 actual-prefix-count))
         ;; 2. Extract the complex part (The 'Sub-nodes' to be hashed)
         (complex (subseq args actual-prefix-count))
         ;; 3. Generate fingerprint for complex arguments
         (digest (if complex 
                     (hash-lisp-object complex)
                     "static")))
    ;; Return the S-Expression key
    (append (list func-name) prefix (list digest))))


(defun key-starts-with-p (full-key prefix)
  (and (>= (length full-key) (length prefix))
       (equal prefix (subseq full-key 0 (length prefix)))))

;; --- Global Default Instance ---
(defvar *default-cache* (make-instance 'global-cache :name "Global Shared Cache"))


(defmacro with-global-cache (form &key (cache '*default-cache*) (ttl 300) (prefix-args 1))
  "Contemporary wrapper that dispatches to the CLOS execution pipeline."
  (let ((func-name (car form))
        (args (cdr form)))
    `(execute-cache ,cache ',func-name (list ,@args) 
                    :ttl ,ttl 
                    :prefix-args ,prefix-args)))

(defmacro defcached (name args &body body &key (ttl 300) (prefix-args 1) (cache '*default-cache*))
  "CLOS-aware defcached. Defaults to *default-cache* but can target any cache instance."
  (let ((key-vars (mapcar (lambda (arg) (if (listp arg) (car arg) arg)) args))
        (cache-key (gensym "CACHE-KEY"))
        (hit-p (gensym "HIT-P"))
        (result (gensym "RESULT"))
        (digest (gensym "DIGEST"))
        (all-args (gensym "ALL-ARGS")))
    `(defun ,name ,args
       (let* ((,all-args (list ,@key-vars))
              (invalidation-prefix (subseq ,all-args 0 (min ,prefix-args (length ,all-args))))
              (complex-args (subseq ,all-args (min ,prefix-args (length ,all-args)) (length ,all-args)))
              (,digest (hash-lisp-object complex-args))
              (,cache-key (append (list ',name) invalidation-prefix (list ,digest))))
         (multiple-value-bind (,result ,hit-p) (get-entry ,cache ,cache-key)
           (if ,hit-p
               ,result
               (let ((function-result (progn ,@body)))
                 (set-entry ,cache ,cache-key function-result :ttl ,ttl)
                 function-result)))))))



;;implementation of a order cache for customer

(defparameter *order-cache* (make-instance 'global-cache :name "Order cache"))

			     
