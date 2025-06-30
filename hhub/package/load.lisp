(push "/home/ubuntu/ninestores/hhub/" asdf:*central-registry*)
(in-package :cl-user)

(ql:quickload '(:uuid :secure-random :drakma :cl-json :cl-who :hunchentoot
               :clsql :clsql-mysql :cl-smtp :parenscript :cl-async :cl-csv
               :cl-base64 :priority-queue :blackbird :cl-yaml))

(ql:quickload :hhub)

(in-package :hhub)
(start-das)

(format t "✅ HHUB Platform successfully started at ~A~%" (mysql-now))
