;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

(defun test-gsthsncode-DBSave ()
;; (handler-case   
     (let* ((company (select-company-by-id 1))
	    (requestmodel (make-instance 'GSTHSNCodesRequestModel
					 :hsncode "0405"
					 :hsncode4digit "0405"
					 :description "Butter  and  other  fats  (i.e.  ghee,  butter  oil,etc.)   and   oils   derived   from   milk;   dairy spreads"
					 :sgst 6.0
					 :cgst 6.0
					 :igst 12.0
					 :compcess 0.0
					 :company company))
	    (gsthsncodeadapter (make-instance 'GSTHSNCodesAdapter)))

       (handler-case 
	   (ProcessCreateRequest gsthsncodeadapter requestmodel)
	 (error (c)
	   (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c))))))


(defun test-gsthsncode-DBUpdate ()
;; (handler-case   
     (let* ((company (select-company-by-id 1))
	    (requestmodel (make-instance 'GSTHSNCodesRequestModel
					 :hsncode "0405"
					 :hsncode4digit "0405"
					 :description "Butter  and  other  fats  (i.e.  ghee,  butter  oil,etc.)   and   oils   derived   from   milk;   dairy spreads"
					 :sgst 6.0
					 :cgst 6.0
					 :igst 12.0
					 :compcess 0.0
					 :company company))
	    (gsthsncodeadapter (make-instance 'GSTHSNCodesAdapter)))

       (handler-case 
	   (ProcessUpdateRequest gsthsncodeadapter requestmodel)
	 (error (c)
	   (error 'hhub-business-function-error :errstring (format t "got an exception ~A" c))))))
