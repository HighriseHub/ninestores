;;; hhub-tst-sms.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun test-otp-send (phone transaction-name OTP)
  (send-sms-notification phone "NTSTOR"  (format nil "Your OTP for ~A is ~A. Do not share this OTP with anyone. Valid for 5 minutes. -Nine Technologies" transaction-name OTP)))

