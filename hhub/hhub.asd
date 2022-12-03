
;; -*- Mode: LISP; Syntax: COMMON-LISP; Package: CL-USER; Base: 10 -*-
;;; $Header: hhub.asd,v 1.6 2018/06/26 18:31:03 

;;; Copyright (c) 2018-2022, Nine Technologies.  All rights reserved.

;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions
;;; are met:

;;;   * Redistributions of source code must retain the above copyright
;;;     notice, this list of conditions and the following disclaimer.

;;;   * Redistributions in binary form must reproduce the above
;;;     copyright notice, this list of conditions and the following
;;;     disclaimer in the documentation and/or other materials
;;;     provided with the distribution.

;;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR 'AS IS' AND ANY EXPRESSED
;;; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
;;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(asdf:defsystem #:hhub
  :serial t
  :description "HighriseHub is an online marketplace for a group of people living in an apartment/colony/area/city. It can be extended to more than one apartment in a city or vendors can register their own areas as supply areas. Backend is MYSQL database and it is a web application. It is supported on all the mobile screens like iOS, Android."
  :author "Pawankumar Deshpande <pawan.deshpande@gmail.com>"
  :license "THIS SOFTWARE IS PROVIDED BY THE AUTHOR 'AS IS' AND ANY EXPRESSED
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS"
    :version "1.0.0"

  :components ((:file "packages")
	       
	       	; Util 
	       (:file "dod-bl-utl" :depends-on ("packages"))
	       (:file "dod-ui-utl" :depends-on ("packages"))
	       (:file "dod-bl-err" :depends-on ("packages"))
	       (:file "hhub-bl-ent" :depends-on ("packages"))
	       (:file "email/templates/registration" :depends-on ("packages"))
	  
	       ; Initial System
	       (:file "dod-ini-sys" :depends-on ("packages"))
				
	       ; System
		  (:file "dod-ui-sys" :depends-on ("packages") )
	       ; User
	       (:file "dod-ui-usr" :depends-on ("packages") )
	       (:file "dod-bl-usr" :depends-on ("packages") )
	       (:file "dod-dal-usr" :depends-on ("packages"))
	        ; Product 
	       (:file "dod-dal-prd" :depends-on ("packages"))
	       (:file "dod-bl-prd" :depends-on ("packages"))
	       (:file "dod-ui-prd" :depends-on ("packages"))
	       ; Order 
	       (:file "dod-bl-ord" :depends-on ("packages"))
	       (:file "dod-ui-ord" :depends-on ("packages"))
	       (:file "dod-dal-ord" :depends-on ("packages"))
	       ; Order Detail
	       (:file "dod-bl-odt" :depends-on ("packages"))
	       (:file "dod-ui-odt" :depends-on ("packages"))
	       (:file "dod-dal-odt"  :depends-on ("packages"))
	       ; Company 
	       (:file "dod-dal-cmp" :depends-on ("packages"))
	       (:file "dod-bl-cmp" :depends-on ("packages"))
	       (:file "dod-ui-cmp" :depends-on ("packages"))
	       ; Order preferences
	       (:file "dod-ui-opf" :depends-on ("packages"))
	       (:file "dod-dal-opf" :depends-on ("packages"))
	       (:file "dod-bl-opf" :depends-on ("packages"))
	       ; Order tracking
	       ; Policies
	       (:file "dod-dal-pol" :depends-on ("packages"))
	       (:file "dod-bl-pol" :depends-on ("packages"))
	       (:file "dod-ui-pol" :depends-on ("packages"))
	      
	       ; Business objects and Business Transactions
	       (:file "dod-dal-bo" :depends-on ("packages"))
	       (:file "dod-bl-bo" :depends-on ("packages"))
	    
	      ; Role
	       (:file "dod-ui-rol" :depends-on ("packages"))
	       (:file "dod-bl-rol" :depends-on ("packages"))
	       (:file "dod-dal-rol" :depends-on ("packages"))
					; Vendor
	       (:file "dod-ui-ven" :depends-on ("packages"))
	       (:file "dod-bl-ven" :depends-on ("packages"))
	       (:file "dod-dal-ven" :depends-on ("packages"))
	      
	       ; Customer 
	       (:file "dod-ui-cus":depends-on ("packages") )
	       (:file "dod-bl-cus" :depends-on ("packages") )
	       (:file "dod-dal-cus" :depends-on ("packages"))
	      
	       ; Payment Transactions 
	       (:file "dod-ui-pay" :depends-on ("packages"))
	       (:file "dod-bl-pay" :depends-on ("packages"))
	       (:file "dod-dal-pay" :depends-on ("packages"))
	       
	       ;Password reset
	       (:file "dod-dal-pas" :depends-on ("packages"))
	       (:file "dod-bl-pas" :depends-on ("packages"))
	       
	         ; Vendor Availability Day 
	       (:file "dod-dal-vad" :depends-on ("packages"))
	       (:file "dod-bl-vad" :depends-on ("packages"))

					; Vendor appointment
	       (:file "dod-dal-vas" :depends-on ("packages"))
	       (:file "dod-bl-vas" :depends-on ("packages"))

					; Web Push Notifications 
	       (:file "dod-ui-push" :depends-on ("packages"))
	       (:file "dod-bl-push" :depends-on ("packages"))
	       (:file "dod-dal-push" :depends-on ("packages"))

	       
	       ))

