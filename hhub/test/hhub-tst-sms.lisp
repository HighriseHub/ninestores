;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

(defun test-otp-send (phone OTP) 
  (send-sms-notification phone "HIGHUB"  (format nil "OTP for Transaction is ~A. Valid for next 5 mins and can be used only once. Do not share OTP with anyone for security reasons. -HighriseHub" OTP)))

