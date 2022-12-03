(defun loginandgetorders ()
  (loop for i from 1 to 100 do   
       (let* ((cookie-jar (make-instance 'drakma:cookie-jar)))
       (drakma:http-request "http://highrisehub.com/hhub/dodcustlogin"
                         :method :post
			 :parameters '(("phone" . "9972022281")
					 ("password" . "demo"))
    :cookie-jar cookie-jar)
       (drakma:http-request "http://highrisehub.com/hhub/dodmyorders" 
                         :cookie-jar cookie-jar)
       (sleep 1)
       (drakma:cookie-jar-cookies cookie-jar)

    ; This should be the last call, since we are deleting the cookies by this time. 
   (drakma:http-request "http://highrisehub.com/hhub/dodcustlogout"))))






			 
