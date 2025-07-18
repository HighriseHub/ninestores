;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun loginandgetorders ()
  (loop for i from 1 to 100 do   
       (let* ((cookie-jar (make-instance 'drakma:cookie-jar)))
       (drakma:http-request (format nil "~A/hhub/dodcustlogin" *siteurl*) 
                         :method :post
			 :parameters '(("phone" . "9972022281")
					 ("password" . "demo"))
    :cookie-jar cookie-jar)
       (drakma:http-request (format nil "~A/hhub/dodmyorders" *siteurl*)
                         :cookie-jar cookie-jar)
       (sleep 1)
       (drakma:cookie-jar-cookies cookie-jar)

    ; This should be the last call, since we are deleting the cookies by this time. 
   (drakma:http-request (format nil "~A/hhub/dodcustlogout" *siteurl*)))))






			 
