
;; -*- Mode: LISP; Syntax: COMMON-LISP; Package: CL-USER; Base: 10 -*-
;;; $Header: hhub.asd,v 1.6 2016/06/26 18:31:03 

;;; Copyright (c) 2016-2025, Nine Technologies.  All rights reserved.

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
  :description "Nine Stores  is an online marketplace and e-commerce platform."
  :author "Nine Stores <support@ninestores.in>"
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
  :version "1.1.0"
  
  :components
  ((:file "hhub/package/packages")
   (:file "hhub/package/compile")
   (:file "hhub/package/load")
   (:file "installation/init")
   
   ;; Core
   (:file "hhub/core/dod-bl-err")
   (:file "hhub/core/dod-bl-pas")
   (:file "hhub/core/dod-bl-pol")
   (:file "hhub/core/dod-bl-rol")
   (:file "hhub/core/dod-bl-sys")
   (:file "hhub/core/dod-bl-utl")
   (:file "hhub/core/dod-dal-bo")
   (:file "hhub/core/dod-dal-pas")
   (:file "hhub/core/dod-dal-pol")
   (:file "hhub/core/dod-dal-rol")
   (:file "hhub/core/dod-ini-sys")
   (:file "hhub/core/dod-seed-data")
   (:file "hhub/core/dod-ui-attr")
   (:file "hhub/core/dod-ui-pol")
   (:file "hhub/core/dod-ui-rol")
   (:file "hhub/core/dod-ui-utl")
   (:file "hhub/core/dtrace")
   (:file "hhub/core/extkeys")
   (:file "hhub/core/hhub-bl-ent")
   (:file "hhub/core/hhub-bl-egn")
   (:file "hhub/core/hhub-dal-egn")
   (:file "hhub/core/hhub-ui-egn")
   (:file "hhub/core/hhublazy")
   (:file "hhub/core/memoize")
   (:file "hhub/core/nst-bl-act")
   (:file "hhub/core/nst-bl-otp")
   (:file "hhub/core/nst-sch-mig")
   (:file "hhub/core/tempuigen")
   (:file "hhub/core/unit-tests")
   (:file "hhub/core/xref")
   
   ;; Modules
   (:file "hhub/account/dod-bl-cmp")
   (:file "hhub/account/dod-dal-cmp")
   (:file "hhub/account/dod-ui-cmp")
   
   (:file "hhub/customer/dod-bl-cus")
   (:file "hhub/customer/dod-dal-cus")
   (:file "hhub/customer/dod-ui-cus")
   
   (:file "hhub/email/templates/registration")
   
   (:file "hhub/invoice/nst-bl-ihd")
   (:file "hhub/invoice/nst-bl-itm")
   (:file "hhub/invoice/nst-dal-ihd")
   (:file "hhub/invoice/nst-dal-itm")
   (:file "hhub/invoice/nst-ui-ihd")
   (:file "hhub/invoice/nst-ui-itm")
   (:file "hhub/invoice/templates/invoicesettings")
   
   (:file "hhub/order/dod-bl-odt")
   (:file "hhub/order/dod-bl-ord")
   (:file "hhub/order/dod-dal-odt")
   (:file "hhub/order/dod-dal-ord")
   (:file "hhub/order/dod-ui-odt")
   (:file "hhub/order/dod-ui-ord")
   (:file "hhub/order/nst-bl-Order")
   (:file "hhub/order/nst-bl-OrderItem")
   (:file "hhub/order/nst-dal-Order")
   (:file "hhub/order/nst-dal-OrderItem")
   (:file "hhub/order/nst-ui-Order")
   (:file "hhub/order/nst-ui-OrderItem")
   
   (:file "hhub/paymentgateway/dod-bl-pay")
   (:file "hhub/paymentgateway/dod-dal-pay")
   (:file "hhub/paymentgateway/dod-ui-pay")
   
   (:file "hhub/products/dod-bl-gst")
   (:file "hhub/products/dod-bl-prd")
   (:file "hhub/products/dod-dal-gst")
   (:file "hhub/products/dod-dal-prd")
   (:file "hhub/products/dod-ui-gst")
   (:file "hhub/products/dod-ui-prd")
   
   (:file "hhub/shipping/dod-bl-osh")
   (:file "hhub/shipping/dod-dal-osh")
   (:file "hhub/shipping/dod-ui-osh")
   
   (:file "hhub/stock/dod-dal-stk")
   
   (:file "hhub/subscription/dod-bl-opf")
   (:file "hhub/subscription/dod-dal-opf")
   (:file "hhub/subscription/dod-ui-opf")
   
   (:file "hhub/sysuser/dod-bl-cad")
   (:file "hhub/sysuser/dod-bl-usr")
   (:file "hhub/sysuser/dod-dal-sys")
   (:file "hhub/sysuser/dod-dal-usr")
   (:file "hhub/sysuser/dod-ui-cad")
   (:file "hhub/sysuser/dod-ui-sys")
   (:file "hhub/sysuser/dod-ui-usr")
   
   (:file "hhub/upi/dod-bl-upi")
   (:file "hhub/upi/dod-dal-upi")
   (:file "hhub/upi/dod-ui-upi")
   
   (:file "hhub/vendor/dod-bl-vas")
   (:file "hhub/vendor/dod-bl-vad")
   (:file "hhub/vendor/dod-bl-ven")
   (:file "hhub/vendor/dod-bl-vpm")
   (:file "hhub/vendor/dod-dal-vas")
   (:file "hhub/vendor/dod-dal-vad")
   (:file "hhub/vendor/dod-dal-ven")
   (:file "hhub/vendor/dod-dal-vpm")
   (:file "hhub/vendor/dod-ui-vad")
   (:file "hhub/vendor/dod-ui-ven")
   
   (:file "hhub/warehouse/dod-bl-wrh")
   (:file "hhub/warehouse/dod-dal-wrh")
   (:file "hhub/warehouse/dod-ui-wrh")
   
   (:file "hhub/webpushnotify/dod-bl-push")
   (:file "hhub/webpushnotify/dod-dal-push")
   (:file "hhub/webpushnotify/dod-ui-push")
   
   (:file "hhub/dod-sto-zip")
   
   ;; Tests
   (:file "hhub/test/hhub-tst-act")
   (:file "hhub/test/hhub-tst-che")
   (:file "hhub/test/hhub-tst-cus")
   (:file "hhub/test/hhub-tst-flupload")
   (:file "hhub/test/hhub-tst-gst")
   (:file "hhub/test/hhub-test-inv")
   (:file "hhub/test/hhub-tst-ord")
   (:file "hhub/test/hhub-tst-sms")
   (:file "hhub/test/hhub-tst-upi")
   (:file "hhub/test/hhub-tst-vpm")
   (:file "hhub/test/hhub-tst-webpush")
   (:file "hhub/test/hhub-tst-wrh")
   (:file "hhub/test/dod-test-ord")))


