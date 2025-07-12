
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

  ((:file "package/packages")
   (:file "package/compile")
   ;; Core (some are utilities, no strict DAL/BL/UI structure)
   (:file "core/dod-dal-bo")
   (:file "core/dod-dal-pas")
   (:file "core/dod-dal-pol")
   (:file "core/dod-dal-rol")
   (:file "core/dod-bl-bo")
   (:file "core/dod-bl-err")
   (:file "core/dod-bl-pas")
   (:file "core/dod-bl-pol")
   (:file "core/dod-bl-rol")
   (:file "core/dod-bl-sys")
   (:file "core/dod-bl-utl")
   (:file "core/dod-ui-attr")
   (:file "core/dod-ui-pol")
   (:file "core/dod-ui-rol")
   (:file "core/dod-ui-utl")
   (:file "core/dtrace")
   (:file "core/extkeys")
   (:file "core/hhub-bl-ent")
   (:file "core/hhublazy")
   (:file "core/memoize")
   (:file "core/nst-bl-act")
   (:file "core/nst-bl-otp")
   (:file "core/nst-sch-mig")
   (:file "core/dod-ini-sys")
   (:file "core/dod-ui-site")
 ;; Account
   (:file "account/dod-dal-cmp")
   (:file "account/dod-bl-cmp")
   (:file "account/dod-ui-cmp")
   
   ;; Customer
   (:file "customer/dod-dal-cus")
   (:file "customer/dod-bl-cus")
   (:file "customer/dod-ui-cus")
   
   ;; Email
   (:file "email/templates/registration")

   ;; Invoice
   (:file "invoice/nst-dal-ihd")
   (:file "invoice/nst-dal-itm")
   (:file "invoice/nst-bl-ihd")
   (:file "invoice/nst-bl-itm")
   (:file "invoice/nst-ui-ihd")
   (:file "invoice/nst-ui-itm")
   (:file "invoice/templates/invoicesettings")
   
   ;; Order
   (:file "order/dod-dal-odt")
   (:file "order/dod-dal-ord")
   (:file "order/nst-dal-Order")
   (:file "order/nst-dal-OrderItem")
   (:file "order/dod-bl-odt")
   (:file "order/dod-bl-ord")
   (:file "order/nst-bl-Order")
   (:file "order/nst-bl-OrderItem")
   (:file "order/dod-ui-odt")
   (:file "order/dod-ui-ord")
   (:file "order/nst-ui-Order")
   (:file "order/nst-ui-OrderItem")

 ;; Payment Gateway
   (:file "paymentgateway/dod-dal-pay")
   (:file "paymentgateway/dod-bl-pay")
   (:file "paymentgateway/dod-ui-pay")
   
   ;; Products
   (:file "products/dod-dal-gst")
   (:file "products/dod-dal-prd")
   (:file "products/dod-bl-gst")
   (:file "products/dod-bl-prd")
   (:file "products/dod-ui-gst")
   (:file "products/dod-ui-prd")
   
   ;; Shipping
   (:file "shipping/dod-dal-osh")
   (:file "shipping/dod-bl-osh")
   (:file "shipping/dod-ui-osh")
   
   ;; Stock
   (:file "stock/dod-dal-stk")
   
   ;; Subscription
   (:file "subscription/dod-dal-opf")
   (:file "subscription/dod-bl-opf")
   (:file "subscription/dod-ui-opf")
   
 ;; Sysuser
   (:file "sysuser/dod-dal-sys")
   (:file "sysuser/dod-dal-usr")
   (:file "sysuser/dod-bl-cad")
   (:file "sysuser/dod-bl-usr")
   (:file "sysuser/dod-ui-cad")
   (:file "sysuser/dod-ui-sys")
   (:file "sysuser/dod-ui-usr")
   
   ;; UPI
   (:file "upi/dod-dal-upi")
   (:file "upi/dod-bl-upi")
   (:file "upi/dod-ui-upi")
   
   ;; Vendor
   (:file "vendor/dod-dal-vas")
   (:file "vendor/dod-dal-vad")
   (:file "vendor/dod-dal-ven")
   (:file "vendor/dod-dal-vpm")
   (:file "vendor/dod-bl-vas")
   (:file "vendor/dod-bl-vad")
   (:file "vendor/dod-bl-ven")
   (:file "vendor/dod-bl-vpm")
   (:file "vendor/dod-ui-vad")
   (:file "vendor/dod-ui-ven")
   
   ;; Warehouse
   (:file "warehouse/dod-dal-wrh")
   (:file "warehouse/dod-bl-wrh")
   (:file "warehouse/dod-ui-wrh")
   
   ;; Web Push Notification
   (:file "webpushnotify/dod-dal-push")
   (:file "webpushnotify/dod-bl-push")
   (:file "webpushnotify/dod-ui-push")
   
   ;; Misc
   (:file "dod-sto-zip")))

