(push "~/ninestores/hhub/" asdf:*central-registry*)
(in-package :cl-user)
(ql:quickload '(:uuid :secure-random :drakma :cl-json :cl-who :hunchentoot :clsql :clsql-mysql :cl-smtp :parenscript :cl-async :cl-csv :cl-base64 :priority-queue))
(load "~/ninestores/hhub/package/compile.lisp")
(compile-hhub-files)
(in-package :hhub)
(start-das) 

