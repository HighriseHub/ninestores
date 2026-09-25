;;; nst-lookup-health.lisp
;;;
;;; One-shot health check of the generated symbol DAG, for use inside the image:
;;;
;;;   (load "aiharness/deepseek/tools/nst-lookup-health.lisp")
;;;   (nst-lookup-health)
;;;
;;; It reports how much of the call graph the current function-lookup-table can
;;; actually answer, and which source files the extractor could not read during
;;; the last (generate-lookup-file ...) run — that last part is not recoverable
;;; from the generated file, so it has to be printed from the image.

(in-package :nstores)

(defun nst-lookup-health ()
  "Prints coverage of the generated symbol table and the reader failures recorded
   by the last generation run. Safe to call at any time; changes nothing."
  (let ((table (if (and (boundp '*nst-function-symbols*)
                        (symbol-value '*nst-function-symbols*))
                   (symbol-value '*nst-function-symbols*)
                   (funcall (function-lookup-table)))))
    (labels ((field (e k)
               "Reads K from an entry; tolerates the legacy 6-slot list."
               (when (consp e)
                 (if (consp (first e))
                     (cdr (assoc k e))
                     (nth (case k (:name 0) (:type 1) (:file 2) (:docstring 3)
                                 (:keywords 4) (:meta 5) (t 0))
                          e))))
             (pct (n total) (if (plusp total) (* 100.0 (/ n total)) 0.0)))
      (let ((total (length table))
            (forms (make-hash-table :test #'equal))
            (edges 0) (calls 0) (called 0) (roots 0) (nosrc 0) (noargs 0))
        (dolist (e table)
          (let* ((form (or (field e :form) "?"))
                 (type (or (field e :type) "?"))
                 (cc   (or (field e :calls-count) 0))
                 (uc   (or (field e :used-by-count) 0)))
            (incf (gethash form forms 0))
            (incf edges cc)
            (when (plusp cc) (incf calls))
            (when (plusp uc) (incf called))
            (when (and (plusp cc) (zerop uc)) (incf roots))
            (when (string-equal form type) (incf nosrc))
            (when (or (null (field e :lambda-list))
                      (string= "" (field e :lambda-list)))
              (incf noargs))))
        (format t "~&=== symbol DAG health ===~%")
        (format t "reader version      : ~A~%"
                (if (fboundp 'symbol-source-readtable)
                    "fixed (chunked, clsql-bracket-safe)"
                    "OLD (pre-fix) — reload hhub/core/nst-ui-prosymloo.lisp"))
        (format t "entries             : ~D~%" total)
        (format t "call edges          : ~D~%" edges)
        (format t "symbols with calls  : ~D (~,1F%)~%" calls (pct calls total))
        (format t "symbols called by   : ~D (~,1F%)~%" called (pct called total))
        (format t "entry points        : ~D~%" roots)
        (format t "no defining form    : ~D (form == type: definition not found in the file)~%" nosrc)
        (format t "no signature        : ~D~%" noargs)
        (format t "definitions by form :~%")
        (let ((pairs '()))
          (maphash (lambda (k v) (push (cons k v) pairs)) forms)
          (dolist (p (sort pairs #'> :key #'cdr))
            (format t "  ~6D  ~A~%" (cdr p) (car p))))
        (when (and (boundp '*sym-unreadable-files*)
                   (plusp (hash-table-count *sym-unreadable-files*)))
          (format t "files that could not be read at all: ~D~%"
                  (hash-table-count *sym-unreadable-files*))
          (maphash (lambda (f e) (format t "  ~A~%    ~A~%" (file-namestring f) e))
                   *sym-unreadable-files*))
        (format t "unreadable forms by file (from the last generation):~%")
        (if (and (boundp '*sym-read-errors*)
                 (plusp (hash-table-count *sym-read-errors*)))
            (let ((pairs '()))
              (maphash (lambda (f n) (push (cons n f) pairs)) *sym-read-errors*)
              (dolist (p (sort pairs #'> :key #'car))
                (format t "  ~4D form(s)  ~A~%" (car p) (cdr p))))
            (format t "  none recorded for this run~%"))
        (format t "heaviest subtrees   : ~{~A~^, ~}~%"
                (loop for e in (sort (copy-list table) #'>
                                     :key (lambda (e) (or (field e :cost) 0)))
                      repeat 5
                      collect (format nil "~A(~A)" (field e :name)
                                      (or (field e :cost) 0))))
        nil))))
