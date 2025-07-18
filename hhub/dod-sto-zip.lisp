;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defclass pincode ()
  ((pincode
    :accessor pincode
    :initarg pincode)
   (city
    :accessor city
    :initarg city)
   (state
    :accessor state
    :initarg state)
   (country
    :accessor country
    :initarg country)))

(defun init-pincode ()
  (let ((pincode-inst (make-instance 'pincode
				     :pincode nil
				     :city nil
				     :state nil
				     :country nil)))
    pincode-inst))
     
    


	

  
