; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defparameter *otp-cleanup-interval* 60)     ; seconds between TTL cleanup
(defparameter *otp-default-ttl* 120)         ; 2 minutes
(defparameter *log-dump-interval* 3600)       ; every 1 hour

(defun today-log-file-path (&optional (base "~hunchentoot/hhublogs"))
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time (get-universal-time))
    (declare (ignore sec min hour))
    (format nil "~A/otp-log-~4,'0D-~2,'0D-~2,'0D.txt" base year month day)))

(defun mask-otp (otp)
  (if (and (stringp otp) (> (length otp) 2))
      (concatenate 'string (make-string (- (length otp) 2) :initial-element #\*) (subseq otp (- (length otp) 2)))
      otp))

(defun make-otp-store ()
  (let ((otp-table (make-hash-table :test 'equal))
        (log-entries '())
        (lock (bt:make-lock)))

    ;; Background cleanup thread
    (bt:make-thread
     (lambda ()
       (loop
         (sleep *otp-cleanup-interval*)
         (bt:with-lock-held (lock)
           (maphash
            (lambda (key value)
              (let ((timestamp (getf value :timestamp))
                    (ttl (getf value :ttl)))
                (when (> (- (get-universal-time) timestamp) ttl)
                  (remhash key otp-table))))
            otp-table))))
     :name "otp-cleanup-thread")

    ;; Background log dumper thread
    (bt:make-thread
     (lambda ()
       (loop
         (sleep *log-dump-interval*)
         (bt:with-lock-held (lock)
           (let ((log-file (today-log-file-path)))
             (with-open-file (out log-file :direction :output
                                           :if-exists :append
                                           :if-does-not-exist :create)
               (when (> (length log-entries) 0)
		 (dolist (entry (reverse log-entries))
                   (format out "~A~%" entry))))
             (setf log-entries '())))))
     :name "otp-log-dump-thread")

    ;; Store interface function
    (lambda (action &key persona purpose phone otp context ip ttl log-dir)
      (let ((key (format nil "~A:~A:~A" persona purpose phone)))
        (bt:with-lock-held (lock)
          (ecase action
            (:set
             (setf (gethash key otp-table)
                   (list :otp otp
                         :context context
                         :timestamp (get-universal-time)
                         :ttl (or ttl *otp-default-ttl*)))

             ;; Push masked log
             (push (list :time (mysql-now)
                         :phone phone
                         :otp (mask-otp (format nil "~A" otp))
                         :ip ip
                         :persona persona
                         :purpose purpose)
                   log-entries))

            (:get
             (gethash key otp-table))
            (:get-otp
             (getf (gethash key otp-table) :otp))
            (:get-context
             (getf (gethash key otp-table) :context))
            (:delete
             (remhash key otp-table))
            (:clear
             (clrhash otp-table)
             (setf log-entries '()))
            (:log-dump
             (let ((log-file (today-log-file-path (or log-dir "~hunchentoot/hhublogs"))))
               (with-open-file (out log-file :direction :output
                                             :if-exists :append
                                             :if-does-not-exist :create)
                 (dolist (entry (reverse log-entries))
                   (format out "~A~%" entry)))
               (setf log-entries '())))))))))
