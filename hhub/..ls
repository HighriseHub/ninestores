(push "~/dairyondemand/" asdf:*central-registry*)
(ql:quickload :uuid)

(ql:quickload '(:cl-who :hunchentoot :clsql :clsql-mysql ))
(ql:quickload :dairyondemand :verbose T)


(in-package :dairyondemand)
