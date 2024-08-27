;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)
(clsql:file-enable-sql-reader-syntax)

;; CREATE SECURITY RELATED DATA

;; Create the Authorization Policies
(defparameter policylist
  (list 
   (list "com.hhub.policy.create.company" "Only Superadmin role can create company....." "com-hhub-policy-create-company")
   (list "com.hhub.policy.create.attribute" "A policy for attribute creation....." "com-hhub-policy-create-attribute" )
   (list "com.hhub.policy.create" "Policy Create" "com-hhub-policy-create" )
   (list "com.hhub.policy.create.order" "Policy for order create by customer" "com-hhub-policy-create-order" )
   (list "com.hhub.policy.cust.edit.order.item" "Policy for customer order edit scenario." "com-hhub-policy-cust-edit-order-item" )
   (list "com.hhub.policy.sadmin.home" "Super admin home page after login" "com-hhub-policy-sadmin-home" ) 
   (list "com.hhub.policy.sadmin.login" "Super admin login policy" "com-hhub-policy-sadmin-login" ) 
   (list "com.hhub.policy.sadmin.create.users.page" "Policy for the Super admin user to edit a user. " "com-hhub-policy-sadmin-create-users-page" ) 
   (list "com.hhub.policy.sadmin.profile" "This is a policy for the Superadmin profile page. " "com-hhub-policy-sadmin-profile" ) 
   (list "com.hhub.policy.compadmin.home" "This is a policy for the Company Admin home page entry" "com-hhub-policy-compadmin-home" )
   (list "com.hhub.policy.cad.login.page" "Company Administrator Login Page. " "com-hhub-policy-cad-login-page" ) 
   (list "com.hhub.policy.cad.login.action" "Company Administrator login action. This is a dummy policy as the request is initiated by browser" "com-hhub-policy-cad-login-action" ) 
   (list "com.hhub.policy.cad.logout" "Company administrator logout policy. " "com-hhub-policy-cad-logout" ) 
   (list "com.hhub.policy.cad.product.approve.action" "This is a governing policy for company administrator to accept the product. " "com-hhub-policy-cad-product-approve-action" ) 
   (list "com.hhub.policy.cad.product.reject.action" "Company Administrator can reject a product. " "com-hhub-policy-cad-product-reject-action" ) 
   (list "com.hhub.policy.vendor.add.product.action" "Policy to execute when a vendor is adding a new product" "com-hhub-policy-vendor-add-product-action" ) 
   (list "com.hhub.policy.vendor.bulk.products.add" "Policy to execute when a vendor is adding products in bulk" "com-hhub-policy-vendor-bulk-products-add")
   (list "com.hhub.policy.account.suspend" "Policy to suspend an account" "com-hhub-policy-account-suspend")
   (list "com.hhub.policy.account.restore" "Policy to Restore an account" "com-hhub-policy-account-restore")
   (list "com.hhub.policy.customer&vendor.create" "Policy to be executed when a new vendor is created. " "com-hhub-policy-customer&vendor-create" ) 
   (list "com.hhub.policy.vendor.order.setfulfilled" "Vendor updates the order and sets it to fulfilled. " "com-hhub-policy-vendor-order-setfulfilled" ) 
   (list "com.hhub.policy.abac.security.page" "Policy to display the ABAC Security page. In this page  we will display policies  transactions " "com-hhub-policy-abac-security-page" )))

(defparameter transactions
  (list
   (list "com.hhub.transaction.create.company" "/hhub/createcompanyaction" "CREATE"  "com-hhub-transaction-create-company")
   (list "com.hhub.transaction.create.attribute" "/hhub/dasaddattribute" "CREATE"  "com-hhub-transaction-create-attribute" )
   (list "com.hhub.transaction.policy.create" "/hhub/dasaddpolicyaction" "CREATE" "com-hhub-transaction-policy-create" )
   (list "com.hhub.transaction.create.order" "/hhub/dodmyorderaddaction"  "CREATE"  "com-hhub-transaction-create-order" )
   (list "com.hhub.transaction.cust.edit.order.item" "/hhub/dodcustorditemedit"  "UPDATE"  "com-hhub-transaction-cust-edit-order-item" )
   (list "com.hhub.transaction.sadmin.home" "/hhub/sadminhome"  "READ"  "com-hhub-transaction-sadmin-home" )
   (list "com.hhub.transaction.sadmin.login" "/hhub/sadminlogin"  "READ"  "com-hhub-transaction-sadmin-login" )
   (list "com.hhub.transaction.sadmin.create.users.page" "/hhub/sadmincreateusers"  "READ"  "com-hhub-transaction-sadmin-create-users-page" )
   (list "com.hhub.transaction.sadmin.profile" "/hhub/hhubsadminprofile"  "READ"  "com-hhub-transaction-sadmin-profile" )
   (list "com.hhub.transaction.compadmin.home" "/hhub/hhubcadindex"  "READ"  "com-hhub-transaction-compadmin-home" )
   (list "com.hhub.transaction.cad.login.page" "/hhub/cad-login.html"  "READ"  "com-hhub-transaction-cad-login-page" )
   (list "com.hhub.transaction.cad.login.action" "/hhub/hhubcadloginaction"  "READ"  "com-hhub-transaction-cad-login-action" )
   (list "com.hhub.transaction.cad.logout" "/hhub/hhubcadlogout"  "READ"  "com-hhub-transaction-cad-logout" )
   (list "com.hhub.transaction.cad.product.approve.action" "/hhub/hhubcadprdapproveaction"  "UPDATE"  "com-hhub-transaction-cad-product-approve-action" )
   (list "com.hhub.transaction.cad.product.reject.action" "/hhub/hhubcadprdrejectaction"  "UPDATE"  "com-hhub-transaction-cad-product-reject-action" )
   (list "com.hhub.transaction.vendor.bulk.products.add" "/hhub/dodvenuploadproductscsvfileaction"  "CREATE"  "com-hhub-transaction-vendor-bulk-products-add" )
   (list "com.hhub.transaction.suspendaccount" "/hhub/suspendaccount"  "UPDATE"  "com-hhub-transaction-suspend-account" )
   (list "com.hhub.transaction.restore.account" "/hhub/restoreaccount"  "UPDATE"  "com-hhub-transaction-restore-account" )
   (list "com.hhub.transaction.vendor.product.add.action" "/hhub/dodvenaddproductaction"  "CREATE"  "com-hhub-transaction-vendor-product-add-action" )
   (list "com.hhub.transaction.customer&vendor.create" "/hhub/dodcustregisteraction"  "CREATE"  "com-hhub-transaction-customer&vendor-create" )
   (list "com.hhub.transaction.vendor.order.setfulfilled" "/hhub/dodvenordfulfilled"  "UPDATE"  "com-hhub-transaction-vendor-order-setfulfilled" )
   (list "com.hhub.transaction.abac.security.page" "/hhub/dasabacsecurity"  "READ"  "com-hhub-transaction-abac-security-page" )))

(seed-auth-policies policylist)
;; Create the Roles
(defparameter rolelist
  (list
   (list "SUPERADMIN" "SUPERADMIN ROLE IS THE SUPREME ROLE IN ROLE HIERARCHY") 
   (list "OPERATOR" "Operator is the helpdesk. He can be assigned maintenance tasks on behalf of customers, vendor of any company.") 
   (list "COMPADMIN" "Company/Account Administrator is the helpdesk for a particular company/tenant/group. He can do maintenance tasks on behalf of customers, vendors for a given company")))
(mapcar (lambda (role)
	  (let ((name (nth 0 role))
		(description (nth 1 role)))
	    (create-role name description))) rolelist)

;; Create the ABAC Subjects
(defparameter abacsubjects
  (list
   (list "COM.HHUB.ABAC.SUBJECT.CUSTOMER" "DOD-CUST-PROFILE")
   (list "COM.HHUB.ABAC.SUBJECT.VENDOR" "DOD-VEND-PROFILE")
   (list "COM.HHUB.ABAC.SUBJECT.SUPERADMIN" "DOD-USERS")
   (list "COM.HHUB.ABAC.SUBJECT.COMPANYADMIN" "DOD-USERS")
   (list "COM.HHUB.ABAC.SUBJECT.SUPPORTUSER" "DOD-USERS")))

(mapcar (lambda (persona)
	  (let ((name (nth 0 persona))
		(hhub-type (nth 1 persona)))
	    (create-abac-subject name hhub-type))) abacsubjects)



(defparameter supercompany (select-company-by-id 1))

(mapcar (lambda (transaction)
	  (let ((name (nth 0 transaction))
		(uri (nth 1 transaction))
		(trans-type (nth 2 transaction))
		(trans-func (nth 3 transaction)))
	    (create-bus-transaction name uri trans-type trans-func supercompany))) transactions)


(defparameter busobjects
  (list
   (list "COM.HHUB.ABAC.BUSOBJECT.ATTRIBUTE"  "DOD-AUTH-ATTR-LOOKUP")
   (list "COM.HHUB.ABAC.BUSOBJET.AUTHPOLICYATTRIBUTES" "DOD-AUTH-POLICY-ATTR")
   (list "COM.HHUB.ABAC.BUSOBJECT.POLICY"  "DOD-AUTH-POLICY")
   (list "COM.HHUB.ABAC.BUSOBJECT.COMPANY"  "DOD-COMPANY")
   (list "COM.HHUB.ABAC.BUSOBJECT.VENDORORDERS"  "DOD-VENDOR-ORDERS")
   (list "COM.HHUB.ABAC.BUSOBJECT.ORDER" "DOD-ORDER")
   (list "COM.HHUB.ABAC.BUSOBJECT.USERS" "DOD-USERS")
   (list "COM.HHUB.ABAC.BUSOBJECT.CUSTOMERWALLET"  "DOD-CUST-WALLET")
   (list "COM.HHUB.ABAC.BUSOBJECT.PRODUCTMASTER"  "DOD-PRD-MASTER")
   (list "COM.HHUB.ABAC.BUSOBJECT.SYSTEM"  "DOD-USERS")
   (list "COM.HHUB.ABAC.BUSOBJET.PAYMENTTRANSACTION"  "DOD-PAYMENT-TRANSACTION")
   (list "COM.HHUB.ABAC.BUSOBJECT.PASSWORDRESET"  "DOD-PASSWORD-RESET")
   (list "COM.HHUB.ABAC.BUSOBJET.VENDORAVAILABILITYDAY"  "DOD-VENDOR-AVAILABILITY-DAY")
   (list "COM.HHUB.ABAC.BUSOBJET.VENDORAPPOINTMENT"  "DOD-VENDOR-APPOINTMENT")
   (list "COM.HHUB.ABAC.BUSOBJET.VENDORTENANTS"  "DOD-VENDOR-TENANTS")
   (list "COM.HHUB.ABAC.BUSOBJET.ROLES"  "DOD-ROLES")
   (list "COM.HHUB.ABAC.BUSOBJET.ORDERITEMS"  "DOD-ORDER-ITEMS")
   (list "COM.HHUB.ABAC.BUSOBJET.ORDERITEMSTRACK"  "DOD-ORDER-ITEMS-TRACK")
   (list "COM.HHUB.ABAC.BUSOBJET.ORDERSUBSCRIPTION"  "DOD-ORD-PREF")
   (list "COM.HHUB.ABAC.BUSOBJECT.PRODUCTCATEGORY"  "DOD-PRD-CATG")))

(mapcar (lambda (busobj)
	  (let ((name (nth 0 busobj))
		(hhub-type (nth 1 busobj)))
	    (create-bus-object name hhub-type supercompany))) busobjects)



(defparameter abacattributes
  (list
   (list "com.hhub.attribute.role.name" "Role name is described. The attribute function will get the role name of the currently logged in user" "com-hhub-attribute-role-name" "OBJECT")
   (list "com.hhub.attribute.login.vendor.name" "Return the Vendor\"s name in the current login context for Vendor website." "com-hhub-attribute-login-vendor-name" "SUBJECT" )
   (list "com.hhub.attribute.login.cust.name" "Get the name of customer in current login context of the customer website." "com-hhub-attribute-login-cust-name" "SUBJECT" )
   (list "com.hhub.attribute.login.user.name" "User who has logged into the System admin website. " "com-hhub-attribute-login-user-name"  "SUBJECT" )
   (list "com.hhub.attribute.login.user.role" "Role of the user who is logged into the system admin site. " "com-hhub-attribute-login-user-role"  "SUBJECT" )
   (list "com.hhub.attribute.customer.order.cutoff.time" "Time deadline before which the customer has to order something. " "com-hhub-attribute-customer-order-cutoff-time"  "ENVIRONMENT" )
   (list "com.hhub.attribute.role.instance" "Get the logged in users\" role instance. " "com-hhub-attribute-role-instance"  "OBJECT" )
   (list "com.hhub.attribute.customer.type" "Type of the customer. There are STANDARD  GUEST customers. " "com-hhub-attribute-customer-type"  "SUBJECT" )
   (list "com.hhub.attribute.vendor.issuspended" "Check whether vendor is suspended" "com-hhub-attribute-vendor-issuspended"  "SUBJECT" )
   (list "com.hhub.attribute.vendor.issuspended" "Check whether Vendor is Suspended" "com-hhub-attribute-vendor-issuspended"  "SUBJECT" )
   (list "com.hhub.attribute.vendor.issuspended" "Check whether Vendor is Suspended" "com-hhub-attribute-vendor-issuspended"  "SUBJECT" )
   (list "com.hhub.attribute.company.issuspended" "Checks whether a Company/Account is suspended" "com-hhub-attribute-company-issuspended"  "OBJECT" )
   (list "com.hhub.attribute.company.maxvendorcount" "Maximum Number of Vendors allowed\r\nHHUBTEST = 1\r\nBASIC = 5\r\nPROFESSIONAL = 10" "com-hhub-attribute-company-maxvendorcount"  "OBJECT" )
   (list "com.hhub.attribute.company.maxproductcount" "Max product count \r\nHHUBTEST = 100\r\nBASIC = 1000\r\nPROFESSIONAL = 3000" "com-hhub-attribute-company-maxproductcount"  "OBJECT" )
   (list "com.hhub.attribute.company.prdbulkupload.enabled" "Whether products bulk upload for a company is enabled or not. " "com-hhub-attribute-company-prdbulkupload-enabled"  "OBJECT" )
   (list "com.hhub.attribute.account.trial.maxvendors" "This attribute defines the number of vendors allowed for a given company/account type" "com-hhub-attribute-account-trial-maxvendors"  "OBJECT" )
   (list "com.hhub.attribute.company.maxcustomercount" "Max customer count for a given company. " "com-hhub-attribute-company-maxcustomercount"  "OBJECT" )
   (list "com.hhub.attribute.company.prdsubs.enabled" "Product subscriptions enabled for a company. Based on type of company. TRIAL = N  BASIC = ENABLED" "com-hhub-attribute-company-prdsubs-enabled" "OBJECT" )
   (list "com.hhub.attribute.company.prdsubs.enabled" "Product subscriptions enabled for a company. Based on type of company. TRIAL = N  BASIC = ENABLED" "com-hhub-attribute-company-prdsubs-enabled" "OBJECT" )
   (list "com.hhub.attribute.company.wallets.enabled" "Wallets enabled for company type. TRIAL = N  BASIC = N  PROFESSIONAL = Y" "com-hhub-attribute-company-wallets-enabled" "OBJECT" )
   (list "com.hhub.attribute.company.codorders.enabled" "Cash on demand orders enabled for company type. TRIAL = N  BASIC = N  PROFESSIONAL = Y" "com-hhub-attribute-company-codorders-enabled" "OBJECT" )
   (list "com.hhub.attribute.company.subscription.plan" "TRIAL  BASIC  STANDARD" "com-hhub-attribute-company-subscription-plan" "OBJECT" )))

(mapcar (lambda (obj)
	  (let ((name (nth 0 obj))
		(description (nth 1 obj))
		(attr-func (nth 2 obj))
		(attr-type (nth 3 obj)))
	    (create-auth-attr-lookup name description attr-func attr-type supercompany))) abacattributes)


;; Delete all the companies except the super company.
(delete-dod-companies (get-system-companies))


(new-dod-company "Demo Company" "Whitefield main road, Whitefield" "Bangalore" "Karnataka" "India" "560066" NIL "DEFAULT" "TRIAL"-1 -1)
;;**********Get the company***********
(defparameter dod-company (select-company-by-name "Demo%"))

;;;;;;;;;;;;;;;;;;; CREATE SOME PRODUCT CATEGORIES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defparameter *product-categories* nil)
(setf *product-categories* (list "root" 1 8  dod-company))
(apply #'create-prdcatg *product-categories*)

(setf *product-categories* nil)
(setf *product-categories* (list "Milk & Dairy Products" 2 3   dod-company))
(apply #'create-prdcatg *product-categories*)

(setf *product-categories* nil) 
(setf *product-categories* (list "Other items" 4 5 dod-company))
(apply #'create-prdcatg *product-categories*)


(setf *product-categories* nil) 
(setf *product-categories* (list "Newspapers & Magazines" 6 7  dod-company))
(apply #'create-prdcatg *product-categories*)


(defparameter salt (flexi-streams:octets-to-string  (secure-random:bytes 56 secure-random:*generator*)))
(defparameter password (encrypt "Welcome$1" salt))      

(create-dod-user "Super Admin" "superadmin" password salt "support@ninestores.in" "9999988888" 1)

;******Create the customer ******
(defparameter *customer-params* nil)
;******Create a customer for demo company, with fixed phone number *******
(setf *customer-params* (list  "Demo Customer"   "GA Bangalore 560066" "9999999999" "abc@example.com" nil password salt   "Bangalore" "Karnataka" "560066"  dod-company))
;Create the customer now.
(apply #'create-customer *customer-params*)

(loop for i from 1 to 10 do 
     (let* ((salt (flexi-streams:octets-to-string  (secure-random:bytes 56 secure-random:*generator*)))
	   (password (encrypt "Welcome$1" salt))
	   (*customer-params* (list (format nil "cust~a" (random 200)) "GA Bangalore 560066" (format nil "99999~a" (random 99999)) (format nil "abc~A@example.com" (random 200))  nil password salt  "Bangalore" "Karnataka" "560066"  dod-company)))
       
       ;create the customer now.
       (apply #'create-customer *customer-params*)))

;Get the customer which we have created in the above steps. 
(defparameter Testcustomer1 (select-customer-by-name (car *customer-params*) dod-company))

;******Create the demo vendor ******
(defparameter salt (flexi-streams:octets-to-string  (secure-random:bytes 56 secure-random:*generator*)))
(defparameter password (encrypt "Welcome$1" salt))      
(defparameter *demo-vendor-params* nil)
;******Create a vendor for demo company, with fixed phone number *******
(setf *demo-vendor-params* (list  "Demo Vendor"   "GA Bangalore 560066" "9999999990" "vendor1@example.com"  password salt   "Bangalore" "Karnataka" "560066"  dod-company))
;Create the customer now.
(apply #'create-vendor *demo-vendor-params*)

; For the demo vendor create a row in the DOD_VENDOR_TENANTS table 
(create-vendor-tenant (select-vendor-by-name "Demo Vendor" dod-company) "Y" dod-company)

; **** Create other vendors *****
(defparameter *vendor-params* nil)
(loop for i from 1 to 10 do 
  (let* ((salt (flexi-streams:octets-to-string  (secure-random:bytes 56 secure-random:*generator*)))
	 (password (encrypt "Welcome$1" salt))
	 (vendor-name (format nil "Vendor~a" (random 200)))
	 (*vendor-params* (list vendor-name  "GA Bangalore 560066" (format nil "98456~a" (random 99999))  (format nil "vendor~A@abc.com" (random 200))  password salt "Bangalore" "Karnataka" "560066" dod-company )))
    ;;Create the vendor now.
    (apply #'create-vendor *vendor-params*)
    (sleep 1)
    (create-vendor-tenant (select-vendor-by-name vendor-name dod-company) "Y" dod-company)))

;Get the vendor which we have created in the above steps. 
(defparameter Rajesh (select-vendor-by-name "Demo Vendor"  dod-company))
(defparameter Suresh (select-vendor-by-id 2))

(defparameter MilkCatg (select-prdcatg-by-name "%Milk & Dairy Products%" dod-company))
(defparameter NewspapersCatg (select-prdcatg-by-name "%Newspaper%" dod-company))
(defparameter OtherCatg (select-prdcatg-by-name "%Other items%" dod-company))


(defparameter NandiniBlue (list (format nil "Nandini Homogenised milk (Blue packet)") "Nandini Homogenized milk contains 3% fat. Available in 250ml, 500ml, 1 ltr and 6 ltr packs."  Rajesh MilkCatg "500 ml" 18.50 100 "resources/nandini-blue.png" "Y" dod-company))
(apply #'create-product NandiniBlue)
(defparameter NandiniPurple (list (format nil "Nandini Sumrudhi (Purple packet)") "Nandini samrudhi milk contains 6% fat. Available in 500ml, 1 ltr and 6 ltr packs."  Rajesh MilkCatg "500 ml" 18.50 100 "resources/nandini-purple.png" "Y" dod-company))
(apply #'create-product NandiniPurple) 
(defparameter NandiniSTM (list (format nil "Nandini Special Toned Milk") "Nandini special toned milk contains 4% fat and is available in 250ml, 500ml and 1 ltr packs."  Rajesh MilkCatg "500 ml" 18.50 200 "resources/nandini-STM.png" "Y"  dod-company))
(apply #'create-product NandiniSTM) 
(defparameter NandiniYellow (list (format nil "Nandini Double Toned Milk (Yellow packet)") "Nandini double toned milk contains 1.5% fat. Available in 250ml, 500ml and 1 ltr packs." Rajesh MilkCatg  "500 ml" 46.00 200 "resources/nandini-yellow.png" "Y"  dod-company))
(apply #'create-product NandiniYellow)
 
(defparameter TOI (list (format nil "Times Of India") ""  Suresh  NewspapersCatg  "1 Nos" 5.00 300 "resources/timesofindia.png" "Y"  dod-company))
(apply #'create-product TOI)

(defparameter DeccanHerald (list (format nil "Deccan Herald") "" Suresh  NewspapersCatg  "1 Nos" 5.00 300 "resources/deccanherald.png" "Y"  dod-company))
(apply #'create-product DeccanHerald)

(defparameter TheHindu (list (format nil "The Hindu") " " Suresh  NewspapersCatg  "1 Nos" 5.00 300 "resources/thehindu.png" "Y"  dod-company))
(apply #'create-product TheHindu)

(defparameter IndianExpress (list (format nil "Indian Express") " " Suresh  NewspapersCatg  "1 Nos" 5.00 300 "resources/indianexpress.png" "Y"  dod-company))
(apply #'create-product IndianExpress)

(defparameter VijayKarnataka (list (format nil "Vijay Karnataka") " "  Suresh  NewspapersCatg  "1 Nos" 5.00 300  "resources/vijaykarnataka.png" "Y"  dod-company))
(apply #'create-product VijayKarnataka)

(defparameter PrajaVani (list (format nil "Praja Vani") " " Suresh  NewspapersCatg  "1 Nos" 5.00 300 "resources/prajavani.png" "Y"  dod-company))
(apply #'create-product PrajaVani)


(defparameter *product-params* nil)
(defparameter *unitprice* nil) 
(loop for i from 1 to 10 do 
  (setf *unitprice* (random 500.00)) 
  (setf *product-params* (list (format nil "Test Product ~a" (random 200)) "Test Description "  Rajesh OtherCatg "1 KG" *unitprice* 240  "resources/test-product.png" nil dod-company))
  ;; Create the customer now.
  (apply #'create-product *product-params*))

;;;; Create two wallets for the customer demo
(defparameter *demo-customer* (select-customer-by-name "Demo%Customer" dod-company)) 
(defparameter *demo-cust-wallet1* (list *demo-customer* Rajesh dod-company))
(defparameter *demo-cust-wallet2* (list *demo-customer* Suresh dod-company))

(apply #'create-wallet *demo-cust-wallet1*)
(apply #'create-wallet *demo-cust-wallet2*)

(defparameter *cust-wallet1* (get-cust-wallet-by-vendor *demo-customer* Rajesh dod-company))
(defparameter *cust-wallet2* (get-cust-wallet-by-vendor *demo-customer* Suresh dod-company))
(set-wallet-balance 1000.00 *cust-wallet1*) 
(set-wallet-balance 1000.00 *cust-wallet2*)

 


