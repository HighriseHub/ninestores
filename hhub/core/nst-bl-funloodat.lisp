;; -*- mode: common-lisp; coding: utf-8 -*-
;; nst-bl-funloodat.lisp came from Function Lookup Data
(in-package :nstores)

(defun function-lookup-table ()
  (function (lambda ()
  '(("COPYORDERITEM-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-OrderItem.lisp" "" "")
    ("PERSIST-VENDOR-SHIP-ZONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("OPERATION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("CALCULATE-INVOICE-TOTALCGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COLLECT-ABAC-ATTRIBUTES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("MODAL.VENDOR-ORDER-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-PRODUCTS-CSV2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("GET-USER-ROLES.USER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "")
    ("DOD-CONTROLLER-CMPSEARCH-FOR-VEND-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-PRDPRICEWITHDISCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("ENFORCEVENDORSESSION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("GET-LOGIN-VENDOR-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-CONTROLLER-COMPANY-SEARCH-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTVEN-SIGNUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("UI-LIST-SHOPCART-FOR-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("CHECK-LOW-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("HHUB-JSON-BODY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-MODEL-FOR-SEARCHCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("LOG-CRITICAL-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Logs a critical error, automatically including the function that initiated the DB call."
     "")
    ("COUNT-VENDOR-ORDERS-PENDING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("MEMOIZEKEYFUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/memoize.lisp" "" "")
    ("PAYMENTCONFIRM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("DOD-CONTROLLER-DBRESET-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDADDTOCARTUSINGBARCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SELECT-ALL-INVOICE-HEADERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "")
    ("CALCULATE-ORDER-TOTALAFTERTAX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("SETEXCEPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Set the Exception for the Database Adapter Service" "")
    ("FORCE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-ROLE-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("CUSTOMER-SUBSCRIPTIONS-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "")
    ("COM-HHUB-TRANSACTION-REQUEST-NEW-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("GET-DATE-STRING-MYSQL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in DD-MM-YYYY format." "")
    ("DOD-CONTROLLER-MY-ORDERS1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("BANNER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("W-COUNTRY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("BO-ADD-PROVENANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return a new bo-knowledge with SOURCE added to provenance (non-destructive)."
     "")
    ("BO-MERGE*" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Merge multiple bo-knowledge objects (fold left using bo-merge)." "")
    ("CREATE-MODEL-FOR-CADUPDATEDETAILSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("UI-LIST-CUST-ORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("DELETE-VENDOR-AVAILABILITY-DAY-INSTANCES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "")
    ("DOD-VENDOR-SHIP-ZONES" "CLASS"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "")
    ("REQUESTMODELVENDORAPPROVAL" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("CUSTOMER-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "")
    ("DOD-CONTROLLER-SEARCH-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-COMPANY-ISSUSPENDED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-SEARCH-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("BUSTRANS-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("ODT-PRD-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("COM-HHUB-POLICY-UPDATE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SHOWINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWINVOICEPAYMENTPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("DOD-CONTROLLER-CUST-ORDERS-CALENDAR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("RESPONSEADDRESS" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "")
    ("CREATE-DIGEST-SHA1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("VENDORPUSHNOTIFICATIONSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("UPIPAYMENTSDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("MODAL.REJECT-VENDOR-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("CREATE-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("DOD-CONTROLLER-CUST-REGISTER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("MERGE-KNOWLEDGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Merges two boundary results of the form (STATUS PAYLOAD)
   according to Belnap knowledge ordering.
   Returns a new (STATUS PAYLOAD) pair."
     "")
    ("GET-OPF-PRODUCT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "")
    ("WITH-STANDARD-VENDOR-PAGE-V3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DELETE-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("GETBUSINESSSESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Get the business session" "")
    ("CREATE-MODEL-FOR-VBULKPRODUCTSADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("ADDBUSINESSOBJECTREPOSITORY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Creates a new BusinessObjectRepository and returns the instance" "")
    ("GET-LOGIN-CUSTOMER-COMPANY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("COMPANY-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("UI-LIST-SHOPCART-READONLY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("URI-PREFIX-BOUNDARY-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("DISPLAYSTOREPICKUPWIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DISPLAY-AS-TILES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CUSTOMER-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("NST-LOAD-EMAIL-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("UPDATE-PRD-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("HHUB-SESSION-VALIDP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "")
    ("USERS-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "")
    ("UI-LIST-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("HHUB-CONTROLLER-CREATE-WHATSAPP-LINK-WITH-MESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("HTML-BACK-BUTTON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("MODAL.PRODUCT-CATEGORY-ADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("LIST-DOD-USERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("GET-SYSTEM-BUS-TRANSACTIONS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("DOD-CONTROLLER-NEW-COMPANY-REQUEST-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SADMIN-HOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("CREATERESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Creates a responsemodel from businessobject" "")
    ("PAYMENT-GATEWAY-MODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("CASE-TRUTH" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "A specialized CASE macro for logic values." "")
    ("JSCRIPT-DISPLAYSUCCESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("READ-YAML-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read a YAML file and return its parsed content." "")
    ("DELETE-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("VM-REASON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("CRM-DB-CONNECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("SELECT-PAYMENT-TRANS-BY-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-bl-pay.lisp" "" "")
    ("ORDERITEMHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("BO-KNOWN-TRUE-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is known true." "")
    ("VENDORWEBPUSHNOFITYPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("DOD-ABAC-SUBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "")
    ("INVOICEITEMADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("COMPANY-TYPE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("DOD-CONTROLLER-ABAC-SECURITY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("FULFILLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("TENANT-OVERRIDES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("GST-HSN-CODES-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("MAKE-LAZY" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "")
    ("GET-SHOP-CART-TOTAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("UPIPAYMENT" "CLASS" "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp"
     "" "")
    ("MIGRATE-2025MAY-ADD-PRODUCT-CODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("CHECK-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("COM-HHUB-POLICY-SHOW-INVOICES-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("PAYMENT-API-SALT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("DISPLAY-CUSTOMER-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SADMIN-CREATE-USERS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("VIEWMODELCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("COM-HHUB-TRANSACTION-RESTORE-ACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("USER-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "")
    ("PRICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("WITH-HTML-SUBMIT-BUTTON" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("IGSTRATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("GET-HT-VAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("DISPLAY-ADD-PRODUCT-TO-INVOICE-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CREATE-WIDGETS-FOR-VENDORORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("HHUB-INIT-BUSINESS-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("COPYCUSTOMER-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-bl-Customer.lisp" "" "")
    ("CREATE-WIDGETS-FOR-UPDATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("DOD-CONTROLLER-CUST-INDEX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("SELECT-VENDOR-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("GET-VENDOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("GET-USER-ROLES.ROLE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "")
    ("CURRENT-DATE-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("UI-LIST-PROD-CATG-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("HHUB-INIT-NETWORK-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("HAS-PERMISSION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("DOREAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "")
    ("SETCOMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "Set the Company" "")
    ("GET-ORDER-ITEM-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("HHUB-GET-CACHED-VENDOR-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-REMOVESHOPCARTITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COM-HHUB-POLICY-CREATE-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("RESTORE-DELETED-BUS-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("CURRENT-YEAR-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current year as a string in YYYY format" "")
    ("BUSINESSOBJECTCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DISCOVERSERVICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "discover a business service based on the service-code" "")
    ("DOD-CONTROLLER-PASSWORD-RESET-TOKEN-EXPIRED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DISPLAY-ADDRESS-CONSENT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CONTROLLER-CUST-SHIPPING-METHODS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PICTURE-PATH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("DOD-CONTROLLER-VEND-INDEX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-PROJECT-SYMBOLS-LOOKUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Model: Prepares the lookup data for the view." "")
    ("GET-COUNTRY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "")
    ("GENERATE-LOOKUP-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Generates the symbol lookup data file by collecting all symbols, merging old keywords, 
   and writing the data in a compiled function format."
     "")
    ("RESTORE-DELETED-ORDERPREFS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SAVE-INVOICE-PRINT-SETTINGS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("RETURN-JSON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("DETERMINE-DEFAULT-SHIPPING-OPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("TOKEN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "")
    ("DISPLAY-GST-HSN-CODE-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("SELECT-INVOICE-ITEM-BY-PRODUCT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "")
    ("MODAL.CUSTOMER-FORGOT-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GENERATE-ACCOUNT-EXT-URL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("VENDOR-UPLOAD-FILE-S3BUCKET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("TOTAL-DISCOUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("CITY" "GENERIC-FUNCTION" "/home/ubuntu/ninestores/hhub/dod-sto-zip.lisp"
     "" "")
    ("DOWNLOADHTMLFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("LAZY-FIND-IF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" "")
    ("INVOICEHEADER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-CUSTOMER-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DELETE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("REQUESTCREATEWEBPUSHNOTIFYVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("COPY-BUSINESSOBJECT-TO-DBOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Syncs the dbobject and the domainobject" "")
    ("DOD-CONTROLLER-VENDOR-SEARCH-CUST-WALLET-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CALCULATE-INVOICE-TOTALGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CUSTOMER-ADD-TO-CART-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("HHUB-BUSINESS-ADAPTER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("WITH-HTML-CHECKBOX" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("WITH-HTML-INPUT-TEXTAREA" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("BILLZIPCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("REQ-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("CUSTGSTIN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("AMOUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("VIEWMODELNIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DOD-CONTROLLER-LOW-WALLET-BALANCE-FOR-ORDERITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("HTMLVIEW" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" ""
     "")
    ("VENDOR-DELETE-FILES-S3BUCKET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("WITH-STANDARD-VENDOR-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GET-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("CREATE-MODEL-FOR-DISPLAYINVOICEPUBLIC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COM-HHUB-BUSINESSFUNCTION-BL-GETPUSHNOTIFYSUBSCRIPTIONFORVENDOR"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp"
     "" "")
    ("WITH-ENTITY-READ" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SEARCHINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("LAZY-CDR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "")
    ("GET-GSTORGNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("DOD-PAYMENT-TRANSACTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-dal-pay.lisp" "" "")
    ("DISPLAY-VENDORS-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-ORDER-ITEMS-TRACK" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CAD-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("SELECT-BUS-TRANS-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("NST-LOAD-ORDER-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("DOD-CONTROLLER-CUST-ADD-ORDER-OTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("HHUB-GET-CACHED-AUTH-POLICIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("COM-HHUB-TRANSACTION-UPDATE-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("ACTIVE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("DELETE-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("GET-SYMBOL-TYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Determines the type of the given symbol S." "")
    ("GET-CURRENCY-FONTAWESOME-MAP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-UPDATE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("INVOICEITEMSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("COM-HHUB-TRANSACTION-EDIT-INVOICE-HEADER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CREATE-ORDER-EMAIL-CONTENT-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("ACCOUNT-CREATED-DAYS-AGO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("BO-KNOWLEDGE-TRUTH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "")
    ("DOD-CUST-PROFILE" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "")
    ("INITBUSINESSSERVER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("COM-HHUB-TRANSACTION-PUBLISH-ACCOUNT-EXTURL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-VENDOR-CURRENTPRODCATGCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("SELECT-PRDCATG-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("VENDOR-UPI-PAYMENT-CANCEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("CURR-SYMBOL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "")
    ("MY-NOT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Implements the logical NOT operator for FDE logic." "")
    ("COPYGSTHSNCODES-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "")
    ("VEDORPASSCODESERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("VENDOR-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("DOD-CONTROLLER-VEND-LOGIN-OTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("VPAYMENTMETHODSADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("ORDER-FULFILLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("MAKE-PRESENTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Returns a presenter instance for this request." "")
    ("DISPLAY-NAME&EMAIL-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SHOWCUSTOMERUPIPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("UPDATEINVOICEITEMSSTOCKINVENTORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("EQUAL-COMPANIESP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-ORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("COPYINVOICEITEM-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "")
    ("CURRENT-TIME-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current time  as a string in HH:MM:SS  format" "")
    ("CREATE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("SELECT-UPI-TRANSACTION-BY-UTRNUM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "")
    ("HASHCALCULATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("BILLCITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("EDIT-INVOICEITEM-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("COM-HHUB-POLICY-CUST-EDIT-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CREATE-WIDGETS-FOR-PRDPRICEWITHDISCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("RENDER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Renders the viewmodel as View" "")
    ("VERIFY-SUPERADMIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "")
    ("MODAL.PRODUCT-REMOVE-FROM-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("DOD-CONTROLLER-TRANS-TO-POLICY-LINK-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CREATE-WIDGETS-FOR-DISPLAYCUSTOMERPROILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("HHUBSENDMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-MODEL-FOR-DISPLAYCUSTOMERPROILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DB-DELETE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Delete the dbobject in the database" "")
    ("CREATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("DELETED-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("CREATE-MODEL-FOR-DELETECUSTORDITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("HHUB-CONTROLLER-PRIVACY-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("HHUB-REGISTER-BUSINESS-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTORDERSUBS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "")
    ("RM-CONFLICTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("SELECT-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("SELECT-PRDCATG-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("RESTORE-DELETED-VENDORS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("SELECT-COMPANY-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("BREAK-END-TIME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("CREATE-MODEL-FOR-OTPSUBMITACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("DOD-CONTROLLER-VEND-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("GET-SYSTEM-UOM-MAP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "")
    ("UPIPAYMENTSVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("NST-LOAD-INVOICE-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("CUSTOMERVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("COM-HHUB-TRANSACTION-DELETE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("DOD-VPAYMENT-METHODS" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("INVOICEHEADERCONTEXTIDREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("NST-LOAD-PRODUCT-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTADDORDERSUBS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CONTROLLER-CUST-ADD-TO-CART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CONTROLLER-NEW-STORE-REQUEST-STEP2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("VENDOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("GET-BILLSAMEASSHIP" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("ORDERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("VENDORAPPROVALSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("DOD-BUS-TRANSACTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "")
    ("PRODUCT-PRICE-WITH-DISCOUNT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("UPDATE-SHIPPING-METHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("GSTHSNCODES" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("BUSINESSOBJECTNIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DISPLAY-PHONE-TEXT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-OTPLOGINPAGEV2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("WAREHOUSEREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("GET-LOGIN-TENANT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("HHUB-CONTROLLER-SEARCH-MY-CUSTOMER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("GET-VOLUMETRIC-WEIGHT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "")
    ("RENDER-UI-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-POLICY-GST-HSN-CODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("PROCESSUPDATEREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Update method" "")
    ("EDITINVOICEWIDGET-SECTION1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("DOD-VENDOR-AVAILABILITY-DAY" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("HHUB-CONTROLLER-PERMISSION-DENIED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("DELETE-VENDORS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("DOD-CONTROLLER-CUST-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PRESENTER-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("HHUB-LOG-MESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("SELECT-BUS-OBJECT-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("GET-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("DISPLAY-PRODUCTS-CAROUSEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("WITH-COMPADMIN-NAVIGATION-BAR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("NEW-TRANSACTION-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("DOD-ORD-PREF" "CLASS"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "")
    ("SELECT-BUS-TRANS-BY-TRANS-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("HHUB-CONTROLLER-VENDOR-UPI-CONFIRM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("GET-VENDOR-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("DOD-INVOICE-HEADER" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("DELETEBUSINESSOBJECTREPOSITORY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Delete the business object repository" "")
    ("DOD-CONTROLLER-ADD-USER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "")
    ("WITH-OPR-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DOD-CONTROLLER-LIST-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("RESOLVE-VIEW-FOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("GET-BUS-OBJECT-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("DISPLAY-PRODUCT-IN-INVOICE-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("DELETEBUSINESSSESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Deletes the business session on a given key" "")
    ("COPYORDERITEM-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-OrderItem.lisp" "" "")
    ("TRANSACTION-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("UNIT-PRICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("DOD-VEND-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("WITH-HTML-DIV-COL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-CUST-ORDER-PAYMENT-MODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("REVCHARGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("CREATE-MODEL-FOR-EDITINVOICEHEADERPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COM-HHUB-POLICY-CUSTOMER-ADDRESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("PERMISSION-CHECKER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDORPROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-SUBSCRIPTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTMYORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PAYLATERENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("CREATE-UI-FOR-CUSTORDERSUBS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "")
    ("CREATE-WIDGETS-FOR-ADDCUSTTOINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("DAS-CUST-PAGE-WITH-TILES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("STATECODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("DISPLAY-INVOICE-ITEM-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("NST-GET-CACHED-ORDER-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("RESTORE-DELETED-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("DOD-CONTROLLER-GUEST-CUSTOMER-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COPYINVOICEHEADER-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "")
    ("GET-DATESTR-FROM-OBJ-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in YYYY-MM-DD format." "")
    ("DOD-RESPONSE-CAPTCHA-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GET-ORDERS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-UPLOAD-SHIPPING-RATETABLE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("COMMUNITYSTORE" "CLASS"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("INVHEADID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("ZONENAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTPRODBYVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("UPDATE-VENDOR-AVAILABILITY-DAY-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "")
    ("STOP-ACTOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("GENERATE-INVOICE-EXT-URL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("DELETE-DOD-USERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("QTY-PER-UNIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-INVOICEHEADER-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("GSTNUMBER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-RESET-PASSWORD-ACTION-LINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("WITH-VENDOR-BREADCRUMB" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-WIDGETS-FOR-PROJECT-SYMBOLS-LOOKUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Widget Factory: Calls the widget with the model data." "")
    ("GENERATE-LISP-FILENAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generates the Lisp file name like nst-dal-odt.lisp from 'order details' and 'dal'."
     "")
    ("GET-ORDERS-FOR-VENDOR-BY-SHIPPED-DATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("PRODUCT-CATEGORY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("GET-PUSH-NOTIFY-SUBSCRIPTION-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "")
    ("VENDOR-UPI-PAYMENT-CONFIRM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("GET-ORDER-BY-CONTEXT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-ORDER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("MAKE-VIEW" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Returns a view instance for this request." "")
    ("NST-API-INTERNAL-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("GET-PAYMENT-TRANS-BY-TRANSACTION-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-bl-pay.lisp" "" "")
    ("BREAK-START-TIME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("DOD-VEND-PROFILE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("COM-HHUB-TRANSACTION-UPDATE-CUSTOMER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("COUNT-ORDER-ITEMS-PENDING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("GET-CUST-WALLETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("IAM-SECURITY-PAGE-HEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("VENDORWEBPUSHNOTIFYADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CREATEINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("ATTR-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "")
    ("DOD-RESET-VENDOR-PRODUCTS-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-PAYMENT-METHODS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COM-HHUB-BUSINESSFUNCTION-BL-CREATEPUSHNOTIFYSUBSCRIPTIONFORVENDOR"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp"
     "" "")
    ("SAVE-CUST-ORDER-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ODTK-UPDATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "")
    ("TAXABLE-VALUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("ROLE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-rol.lisp" "" "")
    ("VENDOR-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDORUPISETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("COM-HHUB-POLICY-CAD-PRODUCT-APPROVE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("DEFINE-SHIPPING-ZONES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "")
    ("COM-HHUB-BUSINESS-FUNCTION-TEMPSTORAGE-GETPUSHNOTIFYSUBSCRIPTIONFORVENDOR"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp"
     "" "")
    ("COM-HHUB-POLICY-SHOW-INVOICE-PAYMENT-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("GETMINORDERAMT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("RESTORE-DELETED-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("REGISTER-OUTBOUND-ROUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Registers an outbound adapter route in *outbound-route-registry*.

Arguments:
  route-key                 - Required keyword (e.g. :customer/read)
  crud-op                   - :create :read :update :delete (optional)
  description               - Optional human description
  active                    - Whether route is active (default T)
  default-outbound-adapters - List of default output formats (e.g. '(json))
  adapter-selector          - Function(route ctx) -> list of output formats
  tags                      - Arbitrary tagging info
  version                   - Version number
  metadata                  - Extensible alist for future fields

Returns:
  The created outbound-adapter-route object."
     "")
    ("VENDORPROFILESERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CUSTOMER&VENDOR-CREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("HHUB-REMOVE-VENDOR-PUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("MAKE-PAYMENT-REQUEST-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-ui-pay.lisp" "" "")
    ("HHUB-WEBPUSH-SUBSCRIPTION-EXISTS" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("GET-SHIP-ZONES-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("DOD-CONTROLLER-DEL-CUST-ORD-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("WITH-CUSTOMER-NAVIGATION-BAR-V2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("RESET-CUST-ORDER-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("WITH-HTML-INPUT-TEXT-HIDDEN" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("HTML-RANGE-CONTROL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GET-PINCODE-DETAILS-ADAPTER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "TCUF Boundary Adapter for Pincode lookup. 
   Contract: Returns (ADDRESS-INSTANCE/NIL TCUF-STATUS)."
     "")
    ("GET-LOGIN-CUSTOMER-TYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("DB-FETCH-CUSTOMER-WEBPUSHNOTIFYSUBSCRIPTIONS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "")
    ("INIT-GST-STATECODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SHOWVENDORCUSTOMERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("SELECT-CUSTOMER-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SEARCH-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("HHUB-CONTROLLER-SAVE-VENDOR-PUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "")
    ("MODAL.VENDOR-PRODUCT-PRICING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("ROLE-UPDATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "")
    ("SELECT-COMPANIES-BY-PINCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("PERSIST-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTMYORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-WIDGETS-FOR-UPDATEORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("CREATE-MODEL-FOR-UPDATEINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SELECT-BUS-TRANS-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("GET-CONTEXT-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("GET-PROJECT-SYMBOLS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Collects ALL defined symbols (internal and external functions, macros, and classes) 
   from the project's packages."
     "")
    ("VENDORPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("ORDERADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CAD-LOGIN-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("CREATE-MODEL-FOR-DISPLAYINVOICEEMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("HHUB-GET-CACHED-CURRENCY-HTML-SYMBOLS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("WITH-CATCH-SUBMIT-EVENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("REQUESTGETWEBPUSHNOFITYVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SADMIN-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("MIN-ITEM" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "")
    ("SEND-CONTACTUS-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("GSTHSNCODESDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("AUTHSIGN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("WALLETENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("ODT-STATUS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("GET-BILLSTATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("WITH-NON-NULL-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "A specialized version of WITH-BOUNDARY-CHECK for deterministic null checks.
   If the value-form is non-NIL (Status :T), the BODY is executed with the value 
   bound to the variable PAYLOAD.
   If the value-form is NIL (Status :F), the macro returns an explicit :VALUE-MISSING 
   signal immediately."
     "")
    ("VENDORWEBPUSHNOTIFYSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("GET-RIGHT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("TRANSACTION-TYPE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("WITH-CUST-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("ROUTE-KEY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("CTX-PRESENTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("CREATE-MODEL-FOR-CADPRODUCTREJECTACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("COM-HHUB-TRANSACTION-UPDATE-ORDER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("RESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("COM-HHUB-POLICY-COMPADMIN-UPDATEDETAILS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("ADD-NEW-NODE-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("MODAL.UPLOAD-CSV-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("HHUB-EMAIL-LOGO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("GETBUSINESSSERVICEMETHOD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("INVOICEHEADERADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("CREATE-WIDGETS-FOR-VENDADDTOCARTFORINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("GET-OPREF-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "")
    ("UI-LIST-VENDOR-ORDERS-BY-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "")
    ("DOD-CONTROLLER-ADD-TRANSACTION-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("GET-SHIP-ADDRESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "")
    ("GUESTCUSTOMER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "")
    ("HSNCODE4DIGIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("DISPLAY-UPI-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("SELECT-VPAYMENT-METHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vpm.lisp" "" "")
    ("GET-LOGIN-USER-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("CREATE-MODEL-FOR-SADMINLOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("SELECT-CUSTOMER-LIST-BY-PHONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("HHUB-GET-CACHED-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("NST-GET-CACHED-INVOICE-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("W-PHONE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SHOWINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CREATE-VENDOR-SHIP-ZONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("FINYEAR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("WITH-BO-KNOWLEDGE-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Enforces clean architecture by requiring explicit handling of all four 
   TCUF states (T, F, U, C) whenever calling an external/unreliable API 
   or boundary function. The API-CALL must return two values: (PAYLOAD STATUS).
   The result payload is made available to all status clauses under the
   variable name 'payload', and the status is available as 'status'."
     "")
    ("GET-VENDOR-ORDER-BY-STATUS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("WITH-CAD-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DISPLAY-SHIPPING&BILLING-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ORDERITEM" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("DISPLAY-SUPERADMIN-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("MODAL.VENDOR-UPI-PAYMENT-CONFIRM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("CHECK-ALL-VENDORS-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("HHUB-GET-CACHED-ABAC-ATTRIBUTES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("RESPONSEGETWEBPUSHNOTIFYVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("GET-VENDOR-ORDERS-FROM-UPI-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "")
    ("DELETE-CUST-PROFILES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("COM-HHUB-POLICY-COMPADMIN-HOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDORSETORDERFULFILLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-BUS-OBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-ADDRESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("MAKE-CALL-CONTEXT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("HHUB-CONTROLLER-ABOUTUS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("INVOICEHEADERHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("HHUB-EXECUTE-NETWORK-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("INVOICEHEADERDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("WITH-HTML-INPUT-TEXT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("W-CITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("UPDATE-VENDOR-SHIPZONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("MAYBE-SAVE-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp"
     "Create a new STANDARD customer only if:
   - Checkbox Save Address? is checked
   - Customer does not already exist
   - Customer not already saved during this checkout session."
     "")
    ("PRODUCT-SEARCH-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DISPLAY-INVOICEHEADER-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("BUSINESSCONTEXT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("WITH-STANDARD-ADMIN-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SADMIN-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("BILLADDR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("CREATEVIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Converts the ResponseModel to ViewModel" "")
    ("ROUTE-OP->METHOD-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Extract operation from keyword like :customer/read and compute method name."
     "")
    ("DOD-CONTROLLER-VEND-LOGIN-WITH-OTP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("RESTORE-DELETED-RESET-PASSWORD-INSTANCES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "")
    ("CREATE-MODEL-FOR-INVOICEPRINTSETTINGSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CREATE-MODEL-FOR-INVOICESETTINGSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CGSTRATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("DOD-CONTROLLER-CUST-DEL-ORDERPREF-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("TAXABLEVALUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("CREATE-MODEL-FOR-VGENPRODCTTEMPL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DISPLAY-ADD-CUSTOMER-TO-INVOICE-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("WITH-ENTITY-CREATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("CREATE-MODEL-FOR-CREATEINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-COMPANY-MAXPRODCATGCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("WAREHOUSESERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("PERSIST-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-REVENUE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-SWITCH-TENANT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("MODAL.VENDOR-UPLOAD-PRODUCT-IMAGES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("SHIPPING-COST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("GSTHSNCODESSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("CANCEL-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("MODAL-DIALOG" "MACRO" "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "" "")
    ("UI-LIST-CUST-PRODUCTS-HORIZONTAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("DELETE-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("WITH-SINGLE-COLUMN-EMAIL" "MACRO"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("LOAD-OLD-DATA-AND-KEYWORDS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Loads existing lookup data (if file exists) and returns a hash table
   mapping symbol names to their preserved keywords (the 5th element)."
     "")
    ("WITH-HTML-INPUT-HIDDEN" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("SEARCH-ODT-BY-ORDER-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("ORDERREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SEARCH-PRODUCT-FOR-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-RESET-PASSWORD-ACTION-LINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DELETE-SUBSCRIPTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "")
    ("DOD-CONTROLLER-LOGINPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("ODT-ORDEROBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("CTX-OUTPUT-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("GET-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("AVAIL-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("SELECT-PRODUCTS-BY-CATEGORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("ASYNC-UPLOAD-IMAGES-FOR-BULK-UPLOAD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-VENDOR-TENANT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("GET-VENDOR-AVAILABILITY-DAY-BY-AVAIL-DATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "")
    ("INIT-HHUBPLATFORM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("DOD-RESET-ORDER-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("INVOICEITEMPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("IS-CONVERTED-TO-INVOICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("BUSINESSSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DB-FETCH-VENDOR-WEBPUSHNOTIFYSUBSCRIPTIONS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp"
     "Gets Web Push Notify subscriptions for a given Vendor" "")
    ("DOD-CONTROLLER-VENDOR-PASSWORD-RESET-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-VENDOR-APPOINTMENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "")
    ("GET-RESET-PASSWORD-INSTANCE-BY-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "")
    ("DELETE-VENDOR-TENANT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("HHUBVENDORTENANTS" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("GET-BILLADDRESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("DOUPDATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "")
    ("CALCULATE-INVOICE-TOTALSGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTVEN-SIGNUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("SELECT-WAREHOUSES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp" "" "")
    ("GET-VENDORS-FOR-APPROVAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GETWEBPUSHNOTIFYVENDORVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("RESTORE-DELETED-VENDOR-APPOINTMENT-INSTANCES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "")
    ("GET-SYMBOL-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Finds the file path where the symbol S is defined using SWANK:FIND-DEFINITIONS-FOR-EMACS.
   Returns the pathname string or an empty string if not found."
     "")
    ("INVOICEITEMS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("EXPIRED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SADMINHOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("WAREHOUSEHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("INVOICEITEMREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("DELETE-OPREFS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "")
    ("CONTEXT-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("DISPLAY-INVOICE-ITEM-ROW-PUBLIC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("RENDERJSON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Takes the viewmodel and converts into JSON" "")
    ("CREATE-ORDER-EMAIL-CONTENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("CURRENT-DATE-STRING-DDMMYYYY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in DD-MM-YYYY format" "")
    ("DOD-CONTROLLER-VENDOR-UPDATE-FREE-SHIPPING-METHOD-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CONTACTUSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("WITH-ENTITY-UPDATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-GENERATE-TEMP-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("SELECT-USER-BY-PHONENUMBER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("UPDATE-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("CREATE-ROLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "")
    ("CTX-BO-KNOWLEDGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SHOW-CUSTOMER-UPI-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("GET-VENDOR-AVAILABILITY-DAYS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "")
    ("DOD-CONTROLLER-LIST-ABAC-SUBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("DELETE-PRODUCT-PRICING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("APPROVE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-cad.lisp" "" "")
    ("WITH-HHUB-TRANSACTION" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-COMPANY-WALLETS-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWVENDORCUSTOMERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-CONTROLLER-RUN-DAILY-ORDERS-BATCH" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CREATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("ADDBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Reads the params and create a new BusinessObject. Return the newly created BusinessObject"
     "")
    ("ORDERPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("BO-MERGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Merge two bo-knowledge instances under Belnap knowledge ordering." "")
    ("CUSTPAYMENTMETHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp"
     "Render the available payment method widgets dynamically using Bootstrap 5.3 accordion.
Only shows sections based on availability flags and customer type."
     "")
    ("CREATED-BY-USER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("CREATE-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CONTACTUSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTUPDATECART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-DEACTIVATE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-VENDOR-BULK-PRODUCT-COUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("CUSTOMER-PROFILE-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATEBUSINESSSESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Creates a business session and returns the newly created session" "")
    ("COM-HHUB-TRANSACTION-SEND-INVOICE-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("DOD-CONTROLLER-PRODUCTS-APPROVAL-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("RESTORE-DELETED-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("ADDLOGINVENDORSETTING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTUPDATECART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ORDERTEMPLATEFILLFORUPIPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("WITH-VENDOR-SIDEBAR" "MACRO"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-UPDATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("UNIVERSAL-TO-UNIX-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("LOOKUP-TABLE-TO-JSON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Converts the Lisp list-of-lists into a JSON string suitable for client-side JavaScript."
     "")
    ("WITH-STANDARD-PAGE-TEMPLATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COUNT-COMPANY-CUSTOMERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("COM-HHUB-TRANSACTION-VENDOR-PRODUCT-ADD-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-USER-ROLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "")
    ("SEND-SMS-NOTIFICATION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "")
    ("DOD-CONTROLLER-PRD-DETAILS-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "")
    ("BANKACCNUM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWGSTHSNCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("GETBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch the Business Object from repository." "")
    ("PROCESSRESPONSE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "This function is responsible for converting the business object into a responsemodel "
     "")
    ("SHARETEXTORURLONCLICK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COLUMN-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("HHUBSENDMAIL-TEST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("FORMAT-PRICING-FEATURES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTADDORDEROTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("UPDATE-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("GENERATEHASHKEY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("ACTOR-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("ACTOR-MAX-QUEUE-SIZE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("CREATE-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("DODELETE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "")
    ("COM-HHUB-TRANSACTION-EDIT-INVOICE-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("RESETVENDORSESSIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("LAZY-NIL" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "")
    ("COM-HHUB-TRANSACTION-SUSPEND-ACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("GET-LOGIN-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("WITH-BOUNDARY-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Enforces clean architecture by requiring explicit handling of all four 
   TCUF states (T, F, U, C) whenever calling an external/unreliable API 
   or boundary function. The API-CALL must return two values: (PAYLOAD STATUS).
   The result payload is made available to all status clauses under the
   variable name 'payload', and the status is available as 'status'."
     "")
    ("GET-LOGIN-VENDOR-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-WAREHOUSE" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("SEND-TEMP-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("SELECT-ALL-GSTHSNCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "")
    ("FOREIGN-KEY-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("COPYVENDOR-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("SELECT-COMPANIES-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("COM-HHUB-POLICY-SADMIN-CREATE-USERS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("COPYORDER-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "")
    ("STD-CUST-PAYMENT-MODE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ADD-NEW-PRDCATG-NODE-AS-CHILD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("SYNCOBJECTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("CGSTAMT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("ORDERITEMSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("DOD-CONTROLLER-CUST-ORDERSUCCESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-PASSWORD-RESET-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COM-HHUB-POLICY-INVOICE-PAID-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("DOD-UPI-PAYMENTS" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("PROCESSRESPONSELIST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "This function is responsible for converting the business objects into a responsemodel list "
     "")
    ("TOTALINWORDS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("PRODUCT-QTY-ADD-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GET-PROJECT-PACKAGES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Returns a list containing the single main package for the :NSTORES system, 
   based on the packages.lisp file."
     "")
    ("CUSTOMERREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("COMP-CESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("WITH-HTML-CUSTOM-CHECKBOX" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("RENDERTILEVIEWHTML" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Renders a list as tiles" "")
    ("IS-USER-ALREADY-LOGIN?" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("WITH-NO-NAVBAR-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTSHOWSHOPCARTREADONLY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COM-HHUB-POLICY-SEARCH-GST-HSN-CODES-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("WITH-HTML-DROPDOWN" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-FREE-SHIPPING-METHOD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("DOD-CONTROLLER-MAKE-PAYMENT-REQUEST-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-ui-pay.lisp" "" "")
    ("CUSTOMER-PRODUCT-DETAIL-MENU-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "")
    ("CALCULATE-INVOICE-TOTALIGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("ROLE-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "")
    ("W-ALT-PHONE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("UOM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("GET-SHIPPED-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-DELETE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-CONTROLLER-NEW-COMPANY-REGISTRATION-EMAIL-SENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("MODAL.GENERATE-SKU-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SEARCHHSNCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-GENERATE-TEMP-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("INVOICEITEMVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("MERGE-PAYLOADS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Merge two payloads intelligently.
   If both are equal, return one.
   If one is NIL, return the other.
   If they differ, return a list of both to mark conflict."
     "")
    ("GET-VENDOR-AVAILABILITY-DAY-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "")
    ("DELETE-PRDCATGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("COM-HHUB-TRANSACTION-VENDOR-ADDTOCART-USING-BARCODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SEND-ORDER-MAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("DISPLAY-WALLET-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATECUSTOMEROBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-bl-Customer.lisp" "" "")
    ("COPYGSTHSNCODES-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "")
    ("GET-OPF-CUSTOMER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "")
    ("FUNCTION-LOOKUP-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/lookup-data.lisp" "" "")
    ("WITH-ENTITY-READALL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("UPIPAYMENTSPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("CREATE-WIDGETS-FOR-INVOICESETTINGSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDORCREATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COM-HHUB-TRANSACTION-PRODCATG-ADD-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("CREATE-MD5-FROM-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Takes a list of strings, joins them with commas, and returns the MD5 digest."
     "")
    ("MODAL.ACCOUNT-EXTERNAL-URL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("NST-GET-CACHED-EMAIL-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("RESTORE-DELETED-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("VPAYMENTMETHODSDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("CREATE-MODEL-FOR-UPDATEINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTOMERPAYMENTMETHODSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GET-LOGIN-VENDOR-COMPANY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("GENERATE-ENTITY-TLA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generate a unique 3-letter acronym (TLA) from an entity name like 'order header'."
     "")
    ("COM-HHUB-POLICY-VENDOR-BULK-PRODUCTS-ADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("SEARCH-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("PHONE-MOBILE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "")
    ("CREATE-MODEL-FOR-ADDPRDTOINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SELECT-UPI-TRANSACTIONS-BY-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "")
    ("GSTORGNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("CREATE-WIDGETS-FOR-TRANSCUSTEDITORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTORDERCREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COM-HHUB-TRANSACTION-INVOICE-SETTINGS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("GET-CURRENCY-HTML-SYMBOL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "")
    ("SELECT-INVOICE-HEADER-BY-INVNUM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "")
    ("PRDDESC" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTPRODBYCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("VIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("ACTOR-PRIORITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("PROCESS-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("UI-LIST-PROD-CATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("COUNT-ORDER-ITEMS-COMPLETED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("CREATE-MODEL-FOR-SEARCHPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ITEMINLIST-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("GETBUSINESSOBJECTREPOSITORY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Get the Business object repository" "")
    ("SUPERADMIN-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "")
    ("HHUB-GET-CACHED-CURRENCIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("HHUB-ADD-PENDING-UPI-TASK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("RESTOREACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ORDERITEMDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("RESPONSEMODELCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("RESTORE-DELETED-ORDER-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("GET-LOGIN-USER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("DISPLAY-ORDERITEM-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("END-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "")
    ("MAKE-REQUESTMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Create requestmodel instance for a route from ctx-requestmodel-params."
     "")
    ("COM-HHUB-POLICY-DELETE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-UPDATE-FLATRATE-SHIPPING-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("PRODUCT-CARD-SHOPCART-READONLY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("COPYORDER-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-PASSWORD-RESET-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-CONTACTUSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("CREATE-WIDGETS-FOR-REMOVESHOPCARTITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("VENDORSESSIONOBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("BUSOBJ-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("WITH-STANDARD-PAGE-TEMPLATE-V3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DISCOUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-ATTRIBUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CALCULATE-ORDER-TOTALIGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "")
    ("RESTORE-DELETED-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-ROLE-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("DOD-GST-SAC-CODES" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("BOREPOSITORIES-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("GET-OPREF-VENDORLIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PERSIST-PUSH-NOTIFY-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "")
    ("CTX-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("GET-RESET-PASSWORD-INSTANCE-BY-TOKEN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "")
    ("COM-HHUB-POLICY-UPDATE-GST-HSN-CODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CREATEGSTHSNCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("SET-ORDER-FULFILLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("GET-OPREFLIST-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "")
    ("CREATE-CASH-ON-DELIVERY-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("SEARCH-PRDCATG-IN-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("CUST-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("GET-SYMBOL-DOC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Retrieves the documentation string for symbol S based on its determined TYPE."
     "")
    ("DOD-ORDER-ITEMS" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("SEND-ORDER-EMAIL-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-LOGINPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("W-ADDR2" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("PRD-IMAGE-PATH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("CREATE-ABAC-SUBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("HHUB-CONTROLLER-SHOW-VENDOR-UPI-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("UPDATE-STOCK-INVENTORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("FILTER-PRODUCTS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("SEND-ORDER-SMS-STANDARD-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("MERGE-KNOWLEDGE*" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SHOWGSTHSNCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SHOWINVOICECONFIRMPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-VENDOR-SHIPPING-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("BO-SAFE-PAYLOAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return payload only when truth is :T; otherwise NIL." "")
    ("DELETE-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("CUSTOMERRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("LAZY-CAR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "")
    ("CREATE-VENDOR-AVAILABILITY-DAY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "")
    ("GST-HSN-FUNC" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("GET-SYSTEM-BUS-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("COM-HHUB-POLICY-VENDOR-REJECT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CREATE-WIDGETS-FOR-ABOUTUSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("GETFLATRATEPRICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("HHUB-CONTROLLER-SAVE-VENDOR-UPI-SETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("JSCRIPT-DISPLAYERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("WITH-STANDARD-CUSTOMER-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("BANKIFSCCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("INDEX-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("HHUB-METHOD-NOT-FOUND" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("GET-DATE-FROM-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("DELETE-DOD-USER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("CREATE-ORDER-FROM-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("PLACEOFSUPPLY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("ACTIVATE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("CUSTOMER-PROFILE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CURRENT-DATE-STRING-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in YYYY-MM-DD format" "")
    ("INVOICEHEADER-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("MYSQL-NOW+DAYS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("NULL-VALUE-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("REJECT-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-cad.lisp" "" "")
    ("NST-SHIPPING-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("GET-UNIT-PRICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("REQUESTPINCODE" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "")
    ("DOD-CONTROLLER-INVALID-EMAIL-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("APPLY-MIGRATIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("RENDER-FREE-SHIPPING-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("INVOICEHEADERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("DBOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("WITH-HTML-FORM-HAVING-SUBMIT-EVENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DELETE-VENDOR-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("COM-HHUB-TRANSACTION-COMPADMIN-HOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("CREATE-MODEL-FOR-SADMINLOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("VPAYMENTMETHODS" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("HHUBSTORE" "CLASS"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("MODAL.ACCOUNT-ADMIN-CHANGE-PIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("ORDERITEMRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("MIGRATE-2025SEP-ORDERITEM-UPGRADE-SGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CREATEINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("ABAC-SUBJECT-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("DESCRIPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("CREATE-MODEL-FOR-TRANSCUSTEDITORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("SEND-NEW-COMPANY-REGISTRATION-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("MODAL.ACCOUNT-ADMIN-UPDATE-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("RENDERJSONALL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Renders a list as JSON" "")
    ("CREATE-MODEL-FOR-VENDADDTOCARTFORINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("MY-AND" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "")
    ("USER-ROLES-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "")
    ("HHUB-CONTROLLER-CUSTOMER-MY-ORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDUPDATEPGSETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("ADDRESSVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "")
    ("REQUIRED-ROLES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-UPDATE-DEFAULT-SHIPPING-METHOD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("GETALLBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch all Business objects from the repository" "")
    ("GET-SYMBOL-FILE-NEW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Finds the file path where the symbol S is defined using SWANK utilities.
   Returns the pathname string or an empty string if not found."
     "")
    ("GETRESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("SEED-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("COM-HHUB-POLICY-CREATE-ATTRIBUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("GETFLATRATETYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("CREATE-MODEL-FOR-CADLOGINACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("GET-LOGIN-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("BIRTHDATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("APPROVED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("BO-KNOWN-FALSE-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is known false." "")
    ("RESPONSEVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("CREATE-ODTINST-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("COM-HHUB-TRANSACTION-POLICY-CREATE-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CREATE-WIDGETS-FOR-UPDATEINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("GETBUSINESSCONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Searches the business context by name" "")
    ("DOD-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("HHUB-CONTROLLER-CONTACTUS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("PERSIST-PRODUCT-PRICING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("ENFORCEUSERSESSION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("BO-KNOWLEDGE->BOUNDARY-RESULT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return a boundary-style list like (TRUTH PAYLOAD SOURCE...)." "")
    ("DOD-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("LEAVE-FLAG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("VENDORS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("GET-LOGIN-USER-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "")
    ("DOD-CONTROLLER-CUST-WALLET-DISPLAY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-cuswall.lisp" "" "")
    ("WEBPUSHNOTIFY" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("WITH-HTML-EMAIL-TEMPLATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWINVOICECONFIRMPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SHIPZIPCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("WITH-VENDOR-NAVIGATION-BAR-V2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-CONTROLLER-OTP-REGENERATE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("SETASSALESORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("DOD-GET-CACHED-COMPLETED-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("UI-LIST-VENDOR-ORDERS-BY-CUSTOMERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "")
    ("ENDPOINT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-SEARCH-CUST-WALLET-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("SEND-MESSAGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("DOD-CONTROLLER-DEL-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("SELECT-ABAC-SUBJECT-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("GETLOGINVENDORSESSIONSTARTTIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("SELECT-MATCHING-HSN-CODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "")
    ("GET-ROOT-PRD-CATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("SELECT-USER-ROLE-BY-USERID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "")
    ("CODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-CUSTOMER-ORDER-CUTOFF-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("DOD-VEND-LOGIN-WITH-OTP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("WITH-DB-CALL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "")
    ("WITH-MODAL-DIALOG-LINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("HHUB-CONTROLLER-TNC-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("CONDITION-TXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("DOD-USERS" "CLASS"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "")
    ("PRODUCT-CARD-FOR-APPROVAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("SET-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("GET-CUST-WALLET-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("EMAIL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("KNOWLEDGE-MEET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Intersection of knowledge (common certainty)." "")
    ("MODAL.VENDOR-UPDATE-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-CONTROLLER-MY-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PREFPRESENT-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("CUSTOMERPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CUST-EDIT-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-VENDOR-STOREPICKUP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("DOREADALL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "")
    ("DELETEBUSINESSSERVER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-COPY-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("SELECT-PRODUCT-PRICING-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("GET-LOGIN-USER-ROLE-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-VENDOR-FREESHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("DELETE-OPREF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "")
    ("COM-HHUB-POLICY-SADMIN-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("INVOICE-EMAIL-OPTIONS-MENU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("STANDARD-CUST-INFORMATION-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("SELECT-VENDORS-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("BUSINESSOBJECTUNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CAD-PRODUCT-REJECT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("SGSTAMT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("HHUB-FUNCTION-MEMOIZE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("COPYWAREHOUSE-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp" "" "")
    ("COM-HHUB-POLICY-SADMIN-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("WEBSITE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("DELETE-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("GET-GSTVALUES-FOR-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "")
    ("DOD-CONTROLLER-CUST-ADD-ORDERPREF-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("SELECT-VENDOR-BY-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("TEST-WEBPUSH-NOTIFICATION-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "")
    ("COM-HHUB-TRANSACTION-INVOICE-PAID-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("BILLSAMEASSHIP" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTSHOWSHOPCARTREADONLY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CALCULATE-INVOICE-TOTALAFTERTAX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("ORDERDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("CREATE-MODEL-FOR-CADPRODUCTAPPROVEACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("PRODUCT-CARD-FOR-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("SELECT-AUTH-ATTR-BY-KEY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("HHUB-EXECUTE-BUSINESS-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("RESPONSEMODELUNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("COM-HHUB-POLICY-SEARCH-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("PRDCATG-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("GET-LOGIN-CUSTOMER-COMPANY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("RENDER-MULTIPLE-PRODUCT-THUMBNAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("DISPLAY-INVOICE-CONFIRM-PAGE-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-COMPANY-MAXCUSTOMERCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("COM-HHUB-POLICY-VENDOR-APPROVE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("ORDER-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("MAKE-UI-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("PUBLICKEY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-VENDOR-FLATRATESHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("GSTHSNCODESHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("GET-SHOPCART-VENDORLIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GET-ORDERIDS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("CREATE-MODEL-FOR-CREATEINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("CREATE-MODEL-FOR-DISPLAYORDHEADERFORCUST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("VENDOR-PRODUCT-CATEGORY-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-GEN-VENDOR-PRODUCTS-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DISPLAY-INVOICE-PAYMENT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("VNUM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("FREQUENCY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "")
    ("GET-PROD-CAT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("GETBUSINESSOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "gets the domain object" "")
    ("DOD-CONTROLLER-CUST-ORDER-SHIPPING-ADDRESS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("RUN-DAILY-ORDERS-BATCH" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("PRODUCT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("GENERATEQRCODEFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("CANCEL-ORDER-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("SUSPEND-FLAG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("SHOW-EMPTY-SHOPPING-CART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("WITH-HTML-ACCORDION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTORDERPAYMENTPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("STOP-DAS" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp"
     "" "")
    ("COM-HHUB-ATTRIBUTE-COMPANY-PRDBULKUPLOAD-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("SUSPENDACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("GET-REQUESTED-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("REMOVE-WEBPUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "")
    ("ODTK-STATUS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "")
    ("WEBPUSHNOTIFYDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("DOD-CONTROLLER-DBRESET-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("RESTORE-DELETED-DOD-USERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SHOWVENDORUPITRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("BO-CONTRADICTORY-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is contradictory." "")
    ("COM-HHUB-POLICY-VENDOR-ORDER-SETFULFILLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("NORMALIZE-MD5-FIELDS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp"
     "Normalize and format all product fields to consistent strings for MD5 calculation."
     "")
    ("GET-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("UI-LIST-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTOMER&VENDOR-CREATE-OTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ORDER-SHIPPING-RATE-CHECK-ZONEWISE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "")
    ("SELECT-BUS-TRANS-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("STOREPICKUPENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("DOD-PRD-MASTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("WITH-HTML-SEARCH-FORM" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("ACTOR-STATE-CLEAN-CALLBACK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SHOW-CUSTOMER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("ORDER-ITEM-EDIT-POPUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("MODAL.VENDOR-EXTERNAL-SHIPPING-PARTNERS-CONFIG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-VPRODSHIPINFOADDACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-AUTH-POLICY" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "")
    ("USER-UPDATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTADDTOCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CTX-DOMAIN-OBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("WEBPUSHNOTIFYCUSTOMER" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("ODTK-REMARKS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "")
    ("BUSINESS-OBJECTS-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWORDERITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("GET-LOGIN-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("REQUESTDELETEWEBPUSHNOTIFYVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("DOD-CONTROLLER-OTP-SUBMIT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("WITH-HTML-DIV-ROW-FLUID" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CADPROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("DISPLAY-ORDER-HEADER-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("CMP-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("LASTNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("INVOICEITEMSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("RESTORE-DELETED-DOD-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("LOGO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("EDITINVOICEWIDGET-SECTION4" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SELECT-AUTH-POLICY-ATTR-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("CREATE-DAILY-ORDERS-FOR-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-LOGINPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("ADDRESS-ADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "")
    ("VPAYMENTMETHODSRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("RENDER-COMPADMIN-SIDEBAR-OFFCANVAS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("PARAMS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("MODAL.APPROVE-VENDOR-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("SELECT-PRDCATG-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-VENDOR-ISSUSPENDED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("GET-BUS-TRAN-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "")
    ("GET-PRODUCTS-FOR-APPROVAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("REJECT-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("GETWEBPUSHNOTIFYVENDORPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("DELETE-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("DOSERVICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Do Service implementation for a Business Service. Takes in the BusinessSession and input params and returns back output params and exceptions if any."
     "")
    ("USERSESSIONOBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DISPLAY-MY-CUSTOMERS-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DB-FETCH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch the DBObject by row-id" "")
    ("BUSINESSSESSION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DISPATCH-ROUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("HHUB-CONTROLLER-UPI-RECHARGE-WALLET-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("COM-HHUB-POLICY-SHOW-INVOICE-CONFIRM-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CREATE-MODEL-FOR-VUPLOADPRDIMAGES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-WIDGETS-FOR-COMPADMINHOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("TRANSFERKNOWLEDGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Transfer BO knowledge from one adapter-layer object to another." "")
    ("ORDERITEMADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("GET-MAX-OPREF-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "")
    ("HHUB-INIT-BUSINESS-FUNCTION-REGISTRATIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("SELECT-PRODUCTS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("MAKE-UI-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "Create a component.
NAME is a keyword identifier.
RENDERER-FN is a function that takes MODELFUNC and returns a list of widgets."
     "")
    ("SELECT-USER-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-VENDOR-EXTERNALSHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-ACTIVATE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("PRINT-VENDOR-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DELETEBUSINESSCONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Deletes a business context" "")
    ("SELECT-VENDORS-FOR-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SHOW-INVOICES-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("ODT-PRODUCT-QTY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("LINK-BUS-TRANSACTION-TO-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("DOD-CONTROLLER-TRANS-TO-POLICY-LINK-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CUSTOMER-SUBSCRIPTIONS-HEADER-TOP-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "")
    ("ALL-CUSTOMERS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "")
    ("SEARCH-IN-HASHTABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("DOD-CONTROLLER-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("GET-UNIX-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("ERROR-MESSAGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("GET-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("SET-USER-SESSION-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("COM-HHUB-TRANSACTION-VENDOR-BULK-PRODUCTS-ADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-GET-CACHED-ORDER-ITEMS-BY-PRODUCT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("PERSIST-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("TABLE-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("COM-HHUB-POLICY-CUSTOMER&VENDOR-CREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("FILTER-ORDER-ITEMS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("VPAYMENTMETHODSVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("EXPECTED-DELIVERY-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("SELECT-COMPANY-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("GET-VENDOR-ORDER-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("UPDATE-GST-FOR-ORDER-LINEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("COM-HHUB-POLICY-CREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("COM-HHUB-POLICY-CAD-LOGIN-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("RESET-USER-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CAD-PRODUCT-APPROVE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("WITH-CUSTOMER-BREADCRUMB" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GENERATEUPIURLSFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("VENDORDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-UPDATEGSTHSNCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("SUBMITFORMEVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GET-TOTAL-OF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("SELECT-VENDOR-BY-PHONE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp"
     "Load Vendor from Database given the phone number" "")
    ("CREATE-DOMAIN-ENTITY-FROM-TEMPLATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generates domain code for UI, BL, and DAL by replacing placeholders in templates."
     "")
    ("DISPLAY-PRODUCT-CARDS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("RENDER-SIDEBAR-OFFCANVAS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("UPDATE-CONFIG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/templates/invoicesettings.lisp"
     "Update a specific KEY in SECTION of config*invoice-settings* to NEW-VALUE."
     "")
    ("PROCESSREADREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Read method" "")
    ("REFRESHIAMSETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "")
    ("REQUESTVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("GET-AUTH-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("ORD-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("CREATE-MODEL-FOR-LOWWALLETBALANCEFORORDERITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PRESENTERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("UNIX-TO-UNIVERSAL-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("SAVE-VENDOR-ORDERS-IN-DB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("MAKE-ADAPTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Create adapter instance for route. Override as needed." "")
    ("MODAL.CUSTOMER-CHANGE-PIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("VPAYMENTMETHODSREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("MAX-ITEM" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "")
    ("UPIPAYMENTSSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("UPDATE-VENDOR-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("WEBPUSHNOTIFYVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-PRODUCTS-BY-CATEGORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("NST-API-TIMEOUT-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("DISPLAY-SAVED-ADDRESSES-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-ADDCUSTTOINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("ORDERHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("GET-VENDORS-BY-ORDERID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("MAKE-OTP-STORE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-otp.lisp" "" "")
    ("TEST-COUNTER-ACTOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp"
     "Test the lifecycle and behavior of the counter actor using standard assert."
     "")
    ("DOD-CONTROLLER-VEND-ADD-TENANT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("START-DAS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("COM-HHUB-TRANSACTION-VENDOR-UPLOAD-PRODUCT-IMAGES-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-GET-CACHED-ORDER-ITEMS-BY-ORDER-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("GET-ORDER-ITEMS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("CUSTOMERS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("COM-HHUB-POLICY-RESTORE-ACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("KNOWLEDGE-JOIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Combines knowledge states from two sources (union of knowledge)." "")
    ("DISPLAY-PRDCATG-CAROUSEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CUSTOMER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("GET-CREATED-BY-USER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("ORDNUM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("UPDATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("DOD-CONTROLLER-LIST-ORDER-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("SELECT-PRODUCT-PRICING-BY-STARTDATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("PERSIST-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("ORDER-TRACK-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "")
    ("UNIT-OF-MEASURE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("WITH-HTML-FORM" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SEARCHINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("VENDOR-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("MODAL.VENDOR-MY-CUSTOMER-WALLET-RECHARGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-PRODUCTS-CSV" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("MODAL.VENDOR-UPDATE-UPI-PAYMENT-SETTINGS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("TAKE-ALL" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "")
    ("CREATECIPHERSALT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("GET-VENDOR-APPOINTMENTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "")
    ("COPY-DBOBJECT-TO-BUSINESSOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Syncs the DBobject to BusinessObject" "")
    ("DOD-CONTROLLER-VENDOR-PASSWORD-RESET-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("TAGS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("PRODUCT-CATEGORY-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("UI-LIST-YES-NO-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("GETPINCODEDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("PERSIST-VENDOR-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("SELECT-ALL-INVOICE-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "")
    ("ACTIVE-FLG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("RESPONSEHASHCHECK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("GET-ABAC-SUBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("EXTERNAL-INVENTORY-CHECK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Mocks an inventory microservice call. Must return payload and status." "")
    ("GET-SHIPPING-METHOD-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("PROCESSREADALLREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Read method" "")
    ("GET-VENDOR-APPOINTMENT-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "")
    ("HHUB-BUSINESS-FUNCTION-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("HHUB-EXECUTE-PENDING-UPI-TASK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("TEXT-EDITOR-CONTROL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GET-ORDER-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("DOD-CONTROLLER-PASSWORD-RESET-MAIL-SENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GET-ABAC-SUBJECT-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("NST-GET-CACHED-CUSTOMER-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTPRODBYCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWVENDORPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("VENDOR-DETAILS-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("SELECT-AUTH-ATTR-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("STATUS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("WITH-HTML-DIV-COL-1" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("HHUB-GET-CACHED-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("COMPANY-EMPLOYEES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("INIT-GST-INVOICE-TERMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "")
    ("CTX-CONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("GET-BUS-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("PRODUCT-CARD-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("ATTR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" ""
     "")
    ("BROWSER-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("DOD-CONTROLLER-CUST-SHOW-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COPYWAREHOUSE-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp" "" "")
    ("HHUB-CONTROLLER-GET-VENDOR-PUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "")
    ("LIST-CUSTOMER-LOW-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTOMERINDEXPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-WIDGETS-FOR-VENDADDTOCARTUSINGBARCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("VENDORVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("COM-HHUB-BUSINESSFUNCTION-DB-GETPUSHNOTIFYSUBSCRIPTIONFORVENDOR"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp"
     "" "")
    ("CUSTOMERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SHOWCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("DOD-COMPANY" "CLASS"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("DB-FETCH-ALL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch records by company" "")
    ("PRODUCT-SUBSCRIBE-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DISPLAY-CUST-SHIPPING-COSTS-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("SESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("GET-PENDING-ORDER-ITEMS-FOR-VENDOR-BY-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SEARCH-ORDERITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("W-ADDR1" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("WITH-HTML-DIV-COL-3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-TRANSACTION-VENDOR-APPROVE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("RENDER-INVOICE-SETTINGS-MENU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("BUSINESSOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("CREATEWHATSAPPLINKWITHMESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("WITH-VEND-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SHOWORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("GET-ZONENAME-FROM-PINCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("RESTORE-DELETED-CUST-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("COM-HHUB-TRANSACTION-ADD-CUSTOMER-TO-INVOICE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("GETEXCEPTIONSTR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("SHIPCITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("SEND-TEST-EMAIL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("COM-HHUB-BUSINESS-FUNCTION-DB-GETPUSHNOTIFYSUBSCRIPTIONFORVENDOR"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp"
     "" "")
    ("ACTOR-THREAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-ORDER-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("COM-HHUB-TRANSACTION-COPY-INVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("DISPLAY-VENDOR-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-WIDGETS-FOR-VENDORPROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-UPDATEORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("UPIPAYMENTSREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("MEMO" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Return a memo-function of fn." "")
    ("WALLET-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DELETE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("DOD-CONTROLLER-LIST-BUSOBJS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("GET-VENDOR-INVOICE-SETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("COM-HHUB-TRANSACTION-GST-HSN-CODES-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("GET-DATE-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in DD/MM/YYYY format." "")
    ("COMPCESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("ACTOR-LOCK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SEARCHPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-WIDGETS-FOR-PRDDETAILSFORCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "")
    ("GENERATE-DESCRIPTIVE-FILENAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("DOD-CONTROLLER-DELETE-PRODUCT-CATEGORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("CREATE-MODEL-FOR-SENDINVOICEEMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SEARCH-ODT-BY-PRD-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("GETREQUESTMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SEARCH-ORDER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("EDITINVOICEWIDGET-SECTION2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CREATE-WIDGETS-FOR-DISPLAYORDERHEADERFORCUST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("HHUB-GET-CACHED-CURRENCY-FONTAWESOME-SYMBOLS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTPRODBYVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("EXTERNAL-URL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("VENDORADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("CALCULATE-ORDER-TOTALSGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "")
    ("UI-LIST-POLICIES-FOR-LINKING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("COM-HHUB-POLICY-VENDOR-PROD-SHIP-INFOADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("SELECT-CUSTOMER-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("CREATE-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("CUSTNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("AUTH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("SAC-CODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("AVERAGE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "")
    ("CTX-RESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("GET-SYSTEM-ROLES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "")
    ("UTRNUM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-UPDATE-EXTERNAL-SHIPPING-PARTNER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("ACTOR-MESSAGE-COUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CREATEORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("PRODUCTS-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("INVOICEITEMHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("REQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("CREATE-WIDGETS-FOR-EDITINVOICEHEADERPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("DOD-CUST-LOGIN-WITH-OTP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-PRODUCT-PRICING-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("SUBMITFILEUPLOADEVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-WIDGETS-FOR-LOWWALLETBALANCEFORORDERITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-RESPONSE-PASSWORDS-DO-NOT-MATCH-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GET-CUST-WALLETS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-SEARCHHSNCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("CHECK&ENCRYPT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("CREATE-WIDGETS-FOR-GENERICREDIRECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("HSN-CODE-4DIGIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("CREATEALLVIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Converts the ResponseModel to ViewModel" "")
    ("WITH-MVC-BINARY-FILE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DOD-VENDOR-TENANTS" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("NST-GENERIC-LOGIN-WITH-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-MODEL-FOR-CREATEGSTHSNCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("CREATE-MODEL-FOR-LOWWALLETBALANCEFORSHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DESTROY-ACTOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("GET-LOGIN-VENDOR-TENANT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("ADD-ROOT-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("GSTHSNCODESADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-ADD-PRODUCT-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-CONTROLLER-DUPLICATE-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GET-ALL-VENDOR-ORDERS-BY-ORDERID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("MODAL-DIALOG-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("PERSIST-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("DOD-CONTROLLER-PROJECT-SYMBOLS-LOOKUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Controller: Renders the symbol lookup page." "")
    ("ACCORDION-EXAMPLE1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("BO-KNOWLEDGE-SUMMARY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SHOW-ORDER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("COM-HHUB-TRANSACTION-UPDATE-ORDERITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("SELECT-AUTH-POLICY-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("GET-OPREF-ITEMS-TOTAL-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PERSIST-PAYMENT-TRANS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-bl-pay.lisp" "" "")
    ("DETERMINE-SHIPPING-HTML-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GSTHSNCODESREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("MODAL.VENDOR-PRODUCT-SHIPPING-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("RENDERLISTVIEWHTML" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "Renders a list view"
     "")
    ("NEW-DOD-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("LOGIAMHERE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-WIDGETS-FOR-UPDATEGSTHSNCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("CREATEINVOICEITEMOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "")
    ("HHUB-CONTROLLER-SAVE-VENDOR-PUSH-SUBSCRIPTION-OLD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "")
    ("MODAL.CUST-DELETE-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("NORMALIZE-BILLING-ADDRESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("WITH-GUESTUSER-NAVIGATION-BAR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CONTROLLER-DELETE-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("CALCULATE-ORDER-ITEM-COST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("PRINT-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DEDUCT-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTWALLETDISPLAY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-cuswall.lisp" "" "")
    ("VPAYMENTMETHODSSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("DOD-ORDER" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("VENDORAPPROVALADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("DISPLAY-AS-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWCUSTOMERUPIPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("WITH-CUSTOMER-NAVIGATION-BAR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-SEARCHORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("WITH-STANDARD-CUSTOMER-PAGE-V3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("EMAIL-ADD-VERIFIED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("PARSE-DATE-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read a date string of the form \"DD/MM/YYYY\" and return the 
corresponding universal time."
     "")
    ("CREATE-WIDGETS-FOR-SHOWVENDORPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("SEND-PASSWORD-RESET-LINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("ACTOR-BEHAVIOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("COPY-HASH-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("RENDER-SINGLE-PRODUCT-IMAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("DOD-CONTROLLER-CUST-ORDER-DATA-JSON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GET-SYSTEM-AUTH-POLICIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("ADAPTERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("CREATE-WIDGETS-FOR-VENDSHIPPINGMETHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("VENDOR-CARD-FOR-APPROVAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("CREATE-MODEL-FOR-INVOICEPAIDACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COM-HHUB-TRANSACTION-POLICY-CREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("GET-VENDOR-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GET-OPREFLIST-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "")
    ("MODAL.HHUB-COOKIE-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("CREATE-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("DOD-CONTROLLER-COMPANY-SEARCH-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DISPLAY-ORDDATEREQDATE-TEXT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDSHIPPINGMETHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("PERSIST-WALLET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("PRODUCT-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("INVDATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("DOD-GST-HSN-CODES" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("PRODUCT-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("MODAL.VENDOR-CHANGE-PIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("ZONEZIPCODESDISPLAYFUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTSHOWSHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DECRYPT" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "")
    ("W-MANAGER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("CUSTOMER-PRODUCT-DETAIL-CONTENT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-SADMINHOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("SAFE-READ-FROM-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Attempts to read a Lisp expression from a string, returning a default value if parsing fails."
     "")
    ("DOD-AUTH-POLICY-ATTR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "")
    ("INVOICEHEADERSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("LAZY-NTH" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "")
    ("CREATE-WIDGETS-FOR-CUSTADDORDERSUBS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("MODAL.VENDOR-PRODUCT-ACCEPT-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("SESSIONINVOICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("GET-LOGIN-CUST-TENANT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("GET-CURRENCY-HTML-SYMBOL-MAP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "")
    ("UPDATE-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("CREATE-ORDER-FROM-PREF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-ORDERITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("SETASSERVICEORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("CUSTOMERADDRESSJSONVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("COPYVENDOR-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-OTPLOGINPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("FIND-OUTBOUND-ROUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("HHUB-CONTROLLER-UPI-CUSTOMER-ORDER-PAYMENT-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("SHIPSTATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("COPYINVOICEITEM-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "")
    ("COM-HHUB-POLICY-VENDOR-BULK-PRODUCT-ADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("UPDATE-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("HHUB-UNKNOWN" "CLASS" "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Base condition for logical database results (non-fatal)." "")
    ("ASYNC-UPLOAD-FILES-S3BUCKET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("GET-VENDOR-TENANTS-AS-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("APPROVED-FLAG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("CODENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("GET-VENDOR-ORDERS-BY-ORDERID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("GSTHSNCODESSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("CREATE-MODEL-FOR-PRDDETAILSFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-PASSWORD-RESET" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "")
    ("COPYVPAYMENTMETHODS-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vpm.lisp" "" "")
    ("GETRATETABLECSV" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("SELECT-INVOICE-HEADER-BY-CONTEXT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "")
    ("DOD-SHIPPING-METHODS" "CLASS"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SHOW-INVOICEITEM-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("SELECT-CUSTOMER-BY-PHONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("TOTALITEMVAL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("COM-HHUB-POLICY-CREATE-GST-HSN-CODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("MODAL.CUSTOMER-UPDATE-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("HHUB-GET-CACHED-TRANSACTIONS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("VENDORCONFIRM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("DISPLAY-TERMS-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-INVOICE-ITEMS" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("USERS-MANAGER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "")
    ("SELECT-PRODUCT-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("GET-VENDOR-TENANTS-LIST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("HANDLE-ADD-TO-CART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "The application service layer function that orchestrates the boundary check."
     "")
    ("WITH-NST-ERROR-HANDLER" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("DISPLAY-CSV-AS-HTML-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("PAYPROVIDERSENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("INIT-HTTPSERVER-WITHSSL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("CHECK-NULL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Safely checks if VALUE is null and signals an error if it is.
   
   Parameters:
   - VALUE: The value to check for null
   - ERROR-MESSAGE: Optional custom error message (default: 'Null value encountered')
   - ERROR-TYPE: Optional error type (default: 'null-value-error)
   
   Returns:
   - The original value if not null
   - Signals an error if value is null
   
   Example usage:
   (check-null some-value \"Expected non-null value for calculation\")"
     "")
    ("CREATE-WIDGETS-FOR-DISPLAYORDERHEADERFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("HHUB-DATABASE-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Base condition for logical database results (non-fatal)." "")
    ("COM-HHUB-TRANSACTION-SHOW-ORDERITEMS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("SELECT-PAYMENT-TRANS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-bl-pay.lisp" "" "")
    ("CREATE-MODEL-FOR-CREATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("UI-LIST-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("PRODUCT-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("GET-LOGIN-CUSTOMER-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("HHUB-CONTROLLER-CONTACTUS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("CTX-VIEW" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("AFTER-DISPATCH-HOOK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("DISPLAY-ORDER-ITEM-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp"
     "Generates a single item row using Bootstrap 5.3 grid divs." "")
    ("DOD-GEN-ORDER-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CUSTOMER-REGISTRATION-HTML-CONTENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-PUSHSUBSCRIBE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("RENDER-MULTIPLE-PRODUCT-IMAGES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-COMPANY-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("CUSTOMER-PRODUCT-DETAIL-PAGE-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "")
    ("COM-HHUB-POLICY-PUBLISH-ACCOUNT-EXTURL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CUST-OPF-AS-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "")
    ("DOD-CONTROLLER-NEW-COMPANY-REQUEST-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-SHIPZONE-RATETABLE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTDELETEORDERSUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COPYINVOICEHEADER-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "")
    ("CREATE-WIDGETS-FOR-VBULKADDPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("GET-BUS-TRAN-POLICY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SHOWINVOICEPAYMENTPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CREATE-MODEL-FOR-DUPLICATE-CUSTOMER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("MYSQL-NOW" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "")
    ("GET-LOGIN-USERID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-APPROVAL-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("CREATE-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("CREATE-WALLET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("HHUB-REMOVE-CUSTOMER-PUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "")
    ("SEND-ORDER-EMAIL-STANDARD-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATEWHATSAPPLINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("HHUB-ABAC-TRANSACTION-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-OTPLOGINPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DELETE-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTORDERPAYMENTPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("UPDATE-VENDOR-APPOINTMENT-INSTANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "")
    ("IS-DOD-CUST-SESSION-VALID?" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GET-SHIPZIPCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("CREATE-UPI-PAYMENT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("BUSINESSSESSIONS-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DISC-RATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("CURRENT-PRICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("CALCULATE-ORDER-TOTALGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "")
    ("RESTORE-DELETED-PRDCATGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("ACTOR-ROLE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-CUST-EDIT-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("WITH-COMPADMIN-BREADCRUMB" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("HTMLDATA" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("GET-UNIVERSAL-TIME-FROM-DATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("COM-HHUB-POLICY-CREATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("SEND-REGISTRATION-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("SGST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("GET-LOGIN-CUSTOMER-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("HHUB-GET-CACHED-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("CREATEWAREHOUSEOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp" "" "")
    ("WITH-KNOWLEDGE-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "")
    ("CREATE-DOD-USER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("HHUB-GET-CACHED-ABAC-SUBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("CREATE-WIDGETS-FOR-DUPLICATE-CUSTOMER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("SELECT-CUSTOMER-FOR-VENDOR-BY-PHONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("DOD-CONTROLLER-CUST-UPDATE-CART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("INVNUM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("DELETE-INVOICEITEM-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("MODAL.VENDOR-DEFAULT-SHIPPING-METHOD-CONFIG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CTX-ADAPTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("DOD-CUST-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("BUSINESSOBJECTREPOSITORY" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DELETE-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("DOD-CONTROLLER-PRODUCT-CATEGORIES-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("DOD-WEBPUSH-NOTIFY" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("GET-SYSTEM-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SEARCH-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("DELETE-AUTH-POLICIE-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("REQUESTMODEL-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("CREATE-BUS-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("MY-OR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Implements the logical OR operator for FDE logic.
   (Based on the join operation of the Truth lattice.)"
     "")
    ("CREATED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("ACTOR-LAST-ACTIVE-AT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("TEST-VENDOR-APPROVAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("GET-ORDER-BY-SHIPPED-DATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("DOD-CUST-WALLET" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "")
    ("SELECT-UPI-TRANSACTIONS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "")
    ("ORDER-AMT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("GET-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("IGST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("CTX-ROUTE-KEY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("CREATE-MODEL-FOR-PRDDETAILSFORCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "")
    ("GET-GSTNUMBER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("CREATE-WIDGETS-FOR-PRDDETAILSFORGUESTCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COM-HHUB-TRANSACTION-VENDOR-ADDTOCART-FOR-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("MEMOIZE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Replace fn-name's global definition with a memoized version." "")
    ("VPRODUCT-QTY-ADD-FOR-INVOICE-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("RESET-PASSWORD-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "")
    ("UPDATE-CUST-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("DISPLAY-CUSTOMER-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("CREATE-PREPAID-WALLET-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CALCULATE-INVOICE-TOTALBEFORETAX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("HHUB-CONTROLLER-NEW-COMMUNITY-STORE-REQUEST-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("PROCESSCREATEREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Create method" "")
    ("GETVIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("GENERATE-BRANCH-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generate a validated Git branch name: scope/type/id-desc." "")
    ("HHUB-GET-CACHED-GST-SAC-CODES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("DOD-VENDOR-ORDERS" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "")
    ("SELECT-HSN-CODE-BY-CODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "")
    ("SELECT-AUTH-POLICY-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("INVOICEITEMRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-CUSTOMER-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("SHOPPING-CART-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DELETE-RESET-PASSWORD-INSTANCES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "")
    ("DOD-CONTROLLER-CAD-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("DISPLAY-ORDER-HEADER-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("WITH-HTML-PANEL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GET-ORDER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-dal-pay.lisp" "" "")
    ("ATTRIBUTE-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("TRIAL-ACCOUNT-DAYS-TO-EXPIRY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("UPDATE-USER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("PROJECT-SYMBOLS-LOOKUP-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Generates the HTML UI for the symbol lookup page." "")
    ("GETBUSINESSSERVICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("ATTRINLIST-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("INVOICEHEADERREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("UPDATE-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("DOD-CONTROLLER-VEND-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CLEAR-MEMOIZE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Clear the hash table from a memo function." "")
    ("CURRENT-YEAR-STRING++" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current year as a string in YYYY format" "")
    ("HHUB-CONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Raised when multiple inconsistent results were found." "")
    ("CURRENCY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "")
    ("COM-HHUB-TRANSACTION-VEND-PRD-SHIPINFO-ADD-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-WIDGETS-FOR-DISPLAYINVOICEPUBLIC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-ATTRIBUTE-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("INVOICEHEADERRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("GET-SHIPPING-RATE-FROM-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("CREATEGSTHSNCODESOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "")
    ("WITH-HTML-DIV-COL-8" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GET-ORDER-ITEMS-FOR-VENDOR-BY-ORDER-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("UI-LIST-CMP-FOR-VEND-TENANT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("ZIPCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("APPT-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vas.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-VENDOR-MAXPRODUCTCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("GET-LOGIN-VEND-TENANT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-BULK-ADD-PRODUCTS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("WAREHOUSEPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("CREATE-WIDGETS-FOR-PRODUCTCATEGORIESPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("WELCOMEMESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("WITH-STANDARD-PAGE-TEMPLATE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("HHUB-CONTROLLER-UPI-RECHARGE-WALLET-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("TAKE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" "")
    ("SET-VENDOR-SESSION-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("WITH-STANDARD-PAGE-TEMPLATE-WITH-SIDEBAR" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-COMPANY-SUBSCRIPTION-PLAN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("RENDER-PRODUCTS-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-CHANGE-PIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("IGSTAMT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("CUSTOMER-SUBSCRIPTIONS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "")
    ("PINCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/dod-sto-zip.lisp" "" "")
    ("SELECT-PRODUCT-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("MIGRATE-2025MAY-ADD-DISCOUNT-COLUMN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("DOD-CONTROLLER-REMOVE-SHOPCART-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ADDRESSSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "")
    ("WITH-HTML-INPUT-TEXT-READONLY" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SEARCHORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTSHIPMETHODSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("LAZY-MAPCAN" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "")
    ("MIGRATE-2025JUN-DOD-ORDER-SCHEMA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("HHUB-GET-CACHED-BUS-OBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("GET-BUS-OBJ-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "")
    ("CATG-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("GET-TENANT-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SYSTEM-DASHBOARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("PHONE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("CUST-INFORMATION-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("BUSINESSCONTEXTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("JSONVIEW" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" ""
     "")
    ("COUNT-VENDOR-ORDERS-COMPLETED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("FIRSTNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("GET-PRODUCTS-FOR-APPROVAL-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("INVOICEITEM" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("ACTOR-STATEFUL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("DELETE-VENDOR-AVAILABILITY-DAY-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "")
    ("GET-CURRENCY-FONTAWESOME-SYMBOL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-PAYMENT-METHODS-UPDATE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("METADATA" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("TNC" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("CREATE-PAYMENT-TRANS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-bl-pay.lisp" "" "")
    ("COLUMN-TYPE-EQUALS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("ORDERITEMREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("CREATE-WIDGETS-FOR-LOWWALLETBALANCEFORSHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("SELECT-ROLE-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "")
    ("DOD-CONTROLLER-CMPSEARCH-FOR-VEND-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("HHUB-GET-CACHED-GST-HSN-CODES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("KILL-THREADS-BY-PREFIX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Kills all threads whose names start with PREFIX." "")
    ("WITH-HTML-TABLE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("WHATSAPP-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("SEND-ORDER-EMAIL-BEHAVIOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "")
    ("COPYCUSTOMER-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-bl-Customer.lisp" "" "")
    ("COM-HHUB-TRANSACTION-VENDOR-ORDER-SETFULFILLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("GET-SYSTEM-ABAC-ATTRIBUTES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("DELETE-BUS-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("DOD-CONTROLLER-CREATE-CUST-WALLET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-WIDGETS-FOR-DISPLAYINVOICEEMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("GET-ORDERS-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("VIEW-CLASSES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("RESET-CUSTOMER-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("ACTOR-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("GET-ORDERS-BY-REQ-DATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("WITH-HTML-CARD" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "A HTML Bootstrap 5.x card generator macro." "")
    ("DOD-CONTROLLER-PRD-DETAILS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DELETE-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("BO-KNOWLEDGE-FROM-BOUNDARY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Convert boundary-result (list or values) into a bo-knowledge instance.
   boundary-result is expected like (TRUTH PAYLOAD &optional SOURCE ...)."
     "")
    ("HHUB-RANDOM-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("VPAYMENTMETHODSPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("TRANSMODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("MAKE-UI-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("SELECT-AUTH-ATTRS-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("UPDATE-USER-ROLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "")
    ("EXCEPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("CALCULATE-ORDER-TOTALCGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "")
    ("CREATE-MODEL-FOR-UPDATEORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("HHUB-CONTROLLER-VSEARCHCUSTBYNAME-FOR-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CUSTOMERDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("COM-HHUB-POLICY-UPDATE-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("DOD-GET-CACHED-COMPLETED-ORDERS-TODAY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-CONTROLLER-LIST-BUSTRANS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SHOW-INVOICE-CONFIRM-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SELECT-ALLVPAYMENT-METHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vpm.lisp" "" "")
    ("QTY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("START-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "")
    ("ADDRESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("INVOICEITEMDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("ENSURE-NOT-NULL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("CUSTOMER-PRODUCT-DETAIL-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "")
    ("GET-PRODUCT-QTY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "")
    ("DOD-CONTROLLER-OTP-REQUEST-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("USER-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "")
    ("JSONDATA" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("CREATE-USER-WITH-ROLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "")
    ("START-ACTOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("GET-SYSTEM-BUS-OBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("DOD-CUST-LOGIN-AS-GUEST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-PRODUCTCATEGORIESPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("CUSTADDR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("HHUB-REGISTER-NETWORK-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("COM-HHUB-POLICY-SUSPEND-ACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("COM-HHUB-TRANSACTION-DISPLAY-STORE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("ADDL-TAX1-RATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("PAYMENT-GATEWAY-MODE-OPTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("PERSIST-ORDERPREF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "")
    ("WRITE-YAML-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Write a Lisp data structure to a YAML file." "")
    ("WITH-HTML-DIV-COL-4" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-ORDERITEM-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTWALLETDISPLAY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-cuswall.lisp" "" "")
    ("COM-HHUB-TRANSACTION-UPDATE-GST-HSN-CODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("CREATE-MODEL-FOR-CUSTOMERPAYMENTMETHODSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("SELECT-CUSTOMER-BY-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("GET-LATEST-ORDER-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("MODAL.VENDOR-FORGOT-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("DOD-USER-ROLES" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "")
    ("VENDOR-PRODUCT-ACTIONS-MENU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("DOD-CONTROLLER-CUST-SHOW-SHOPCART-READONLY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("SAVE-TEMP-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ORDERITEMPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("SUBMITSEARCHFORM2EVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("W-PIN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("ADDLOGINVENDORSETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-WIDGETS-FOR-UPDATEORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("VENDOR-ORDER-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "")
    ("CUSTID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("SAVE-ORDER-ITEMS-IN-DB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("VIEWMODELUNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DELETE-VENDOR-APPOINTMENT-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "")
    ("COUNTER-BEHAVIOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("INITBUSINESSSERVICES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Initialise the Business Services" "")
    ("WAREHOUSEDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("BOUNDARY-RESULT->BO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Wrapper around bo-knowledge-from-boundary that normalizes payload provenance if payload is itself a bo-knowledge or plist."
     "")
    ("COPYUPIPAYMENT-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "")
    ("HHUB-GET-CACHED-PRODUCT-CATEGORIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CURRENT-YEAR-STRING--" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current year as a string in YYYY format" "")
    ("GET-OPF-PRD-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "")
    ("SELECT-VENDOR-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("FIND-NEAREST-ELEMENTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "")
    ("FEATURE-FLAGS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("ODT-VENDOR-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("BO-MERGE-PROVENANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return merged provenance list (deduped)" "")
    ("DELETEBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Deletes the BusinessObject from the BusinessObjectRepository" "")
    ("TOTALVALUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-CUSTOMER-TYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("DELETE-PRD-CATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("SEARCH-INVOICE-HEADER-BY-INVNUM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "")
    ("RM-UNKNOWN-REASON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("COMPANY-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("COM-HHUB-TRANSACTION-REFRESH-IAM-SETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("CALCULATE-SHIPPING-COST-FOR-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("VERSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("GSTHSNCODESRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("CREATE-MODEL-FOR-PRDDETAILSFORGUESTCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ERROR-VALUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "")
    ("BO-KNOWLEDGE-PAYLOAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "")
    ("WITH-HTML-EMAIL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-MODEL-FOR-SEARCHINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("DOD-CONTROLLER-VEN-EXPEXL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("SGSTRATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("BUSINESSOBJECT-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("VIEW" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("FILTER-PRODUCTS-BY-CATEGORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("DELETE-THREADS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-POLICY-CREATE-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("PRD-QTY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("GET-ORDER-ITEMS-BY-PRODUCT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("HSN-DESCRIPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("GET-USERS-FOR-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("CREATE-WIDGETS-FOR-UPDATEINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("DISPLAY-ORDER-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-GENERATE-PRODUCTS-TEMPL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("WITH-STANDARD-VENDOR-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-TRANSACTION-VENDOR-CREATE-CUSTOMER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("STANDARDCUSTOMER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "")
    ("DOD-CONTROLLER-CUST-APT-NO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ACTIVE-FLAG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("MODAL.VENDOR-FLATRATE-SHIPPING-CONFIG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DELETE-CUST-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("DUPLICATE-CUSTOMERP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("DELETE-ALL-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("CREATE-OPREF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "")
    ("CREATEORDERITEMOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-OrderItem.lisp" "" "")
    ("GET-LOGIN-VEND-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("WITH-STANDARD-CUSTOMER-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GET-ORDER-BY-STATUS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SHOW-INVOICE-PAYMENT-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("BEFORE-DISPATCH-HOOK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("WITH-HTML-DIV-COL-10" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("HHUB-CONTROLLER-PRICING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("WEBPUSHNOTIFYREPOSITORY" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("GET-BUS-TRAN-ABAC-SUBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "")
    ("UPDATE-OPREF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "")
    ("WITH-MVC-REDIRECT-UI" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("USERNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "")
    ("PRODUCT-CARD-WITH-DETAILS-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("DISPLAY-PRODUCTS-BY-CATEGORY-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-CADPROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("VENDOR-CREATE-UPDATE-CUSTOMER-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SAC-DESCRIPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("USER-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "")
    ("VIEWUNKNOWN" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "" "")
    ("CUSTOMER-PROFILE-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PERSIST-ABAC-SUBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("COM-HHUB-CONTROLLER-PROJECT-SYMBOLS-LOOKUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Controller: Renders the symbol lookup page." "")
    ("GETDEFAULTSHIPPINGMETHOD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("ADDLOGINUSERSETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "")
    ("PRD-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "")
    ("NST-GET-CACHED-PRODUCT-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("ROW-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("WAREHOUSERESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("DISPLAY-UPI-TRANSACTION-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("RESPONSEMODELNIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-ORDER-CANCEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("FIND-NEAREST-SHIPPING-OPTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "")
    ("DISPATCH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Runs pipeline + outbound adapter selection." "")
    ("HHUB-SAVE-CUSTOMER-PUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "")
    ("APPROVAL-STATUS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("UPDATE-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("DOD-CONTROLLER-REFRESH-PENDING-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-WIDGETS-FOR-UPIRECHARGEWALLETPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("HHUB-CONTROLLER-VENDOR-UPI-CANCEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("TRIAL-ACCOUNT-EXPIRED-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("COPYWEBPUSHNOTIFICATION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "")
    ("GENERATE-SKU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generate an SKU from product information by taking 2 chars from each word.
  
  Arguments:
  - PRODUCT-NAME: String (e.g., \"Organic Apples\")
  - DESCRIPTION: String or NIL (e.g., \"Red Delicious\")
  - QTY-PER-UNIT: Number (e.g., 1, 100, 2.5)
  - UNIT-OF-MEASURE: String (e.g., \"KG\", \"G\", \"L\")
  
  Returns:
  - A generated SKU string in format NN-DD-QTY-UOM-RANDOM
    Where NN is from product name words, DD from description words
  "
     "")
    ("HHUB-CONTROLLER-VSEARCHCUSTBYPHONE-FOR-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("EVALUATE-CHECKOUT-READINESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Evaluates the final checkout decision based on multiple FDE truth values."
     "")
    ("GET-BILLZIPCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("PRODUCT-VENDOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("SETASSERVICEPRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("HHUB-GET-CACHED-ACTIVE-VENDOR-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-PUSH-NOTIFY-SUBSCRIPTION-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "")
    ("CREATE-WIDGETS-FOR-ADDPRDTOINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COM-HHUB-POLICY-CAD-PRODUCT-REJECT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("START-TIME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("BO-KNOWLEDGE-TIMESTAMP" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "")
    ("ACTOR-CONDITION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("GET-LEFT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("CUST-WALLET-AS-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GET-APPLIED-MIGRATIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("CREATE-DIGEST-MD5" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("DOD-CONTROLLER-POLICY-SEARCH-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("URI-PREFIX-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("DOD-CONTROLLER-PRD-DETAILS-FOR-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CALCULATE-CARTITEMS-WEIGHT-KGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("COM-HHUB-TRANSACTION-DOWNLOAD-INVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("RENDERHTML" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Takes the viewmodel and converts into HTML" "")
    ("CTX-REQUESTMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("DOD-CAD-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("PERSIST-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("CREATE-MODEL-FOR-UPIRECHARGEWALLETPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("WITH-NO-NAVBAR-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("WITH-HTML-DIV-COL-2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-MY-CUSTOMERS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("UI-LIST-ORDER-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-UPDATE-PAYMENT-GATEWAY-SETTINGS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("RENDER-UI-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Render a component by invoking its renderer with MODELFUNC.
Returns a list of widget outputs."
     "")
    ("SELECT-ROLE-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "")
    ("SELECT-AUTH-POLICY-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("CREATEINVOICEHEADEROBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CAD-LOGIN-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-VENDOR-TABLERATESHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("SAC-CODE-4DIGIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("BO-UNKNOWN-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is unknown." "")
    ("ENCRYPT" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "")
    ("GET-LOGIN-VENDOR-SETTING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-MODEL-FOR-VPRODADDACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("GET-LOGIN-CUSTOMER-COMPANY-WEBSITE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("INVOICEPRINTSETTINGSWIDGETHTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SETDBOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "Set the DBObject" "")
    ("GET-SHIPCITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("CREATE-MODEL-FOR-DOWNLOADINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("UPDATE-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("DOD-ROLES" "CLASS" "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp"
     "" "")
    ("SELECT-CUSTOMER-LIST-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("UPDATE-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-UPDATE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("IS-DOD-VEND-SESSION-VALID?" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("RENDER-UI-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("POLICY-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("DB-SAVE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Savte the domianobject to the database" "")
    ("GENERATEOTP&REDIRECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("ORDER-SHIPPING-RATE-CHECK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "")
    ("COM-HHUB-TRANSACTION-COMPADMIN-UPDATEDETAILS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("UI-LIST-VEND-ORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DELETE-AUTH-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("WITH-MVC-UI-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("REVENUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("PRDCATGINLIST-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("FORMAT-PRICING-PLANS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("HHUB-CONTROLLER-PINCODE-CHECK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("IPADRESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-PAYMENT-SUCCESSFUL-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-ui-pay.lisp" "" "")
    ("GET-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("GET-LOGIN-USERNAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "")
    ("GET-BILLCITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("INVOICEHEADERSTATUSREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDORUPDATEACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("WITH-ADMIN-NAVIGATION-BAR" "MACRO"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("CREATEBUSINESSCONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Create a business context" "")
    ("COM-HHUB-TRANSACTION-CUSTOMER&VENDOR-CREATE-OTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("IS-DOD-SESSION-VALID?" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("SHIPADDR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-SEARCH-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PERSIST-BUS-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("LAZY" "MACRO" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" "")
    ("HHUB-UNKNOWN-KNOWLEDGE-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Base condition for logical database results (non-fatal)." "")
    ("GET-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COUNT-COMPANY-VENDORS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("SEND-ORDER-SMS-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CONTROLLER-COMPANY-SEARCH-FOR-SYS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-CHANGE-PIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("HHUB-GET-CACHED-COMPANY-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("ORDER-SOURCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("MODAL.DELETE-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "")
    ("PAYMENT-MODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("MODAL.VENDOR-PRODUCT-REJECT-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("PRINT-THREAD-INFO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-WIDGETS-FOR-DELETEINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWVENDORUPITRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("END-TIME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("CANCEL-REASON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("COPYVPAYMENTMETHODS-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vpm.lisp" "" "")
    ("ORDERRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("COPYUPIPAYMENT-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "")
    ("HSN-CODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("MODAL.COM-HHUB-TRANSACTION-SADMIN-CREATE-USERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "")
    ("GET-LOGIN-CUST-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PARSE-TIME-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("INITBUSINESSCONTEXTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp"
     "This generic function will initialize the business contexts for the business server"
     "")
    ("WITH-HTML-DIV-COL-6" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("WITH-HHUB-PEP" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("SUBSCRIPTION-PLAN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("COM-HHUB-TRANSACTION-DISPLAY-INVOICE-PUBLIC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("GET-SYSTEM-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("SAVE-UPI-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("SELECT-WAREHOUSE-BY-MANAGER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp" "" "")
    ("GET-CUSTOMER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("CREATE-MODEL-FOR-COMPADMINHOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("WITH-HTML-COLLAPSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("INVOICE-HEADER-ACTIONS-MENU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CREATE-MODEL-FOR-SHOWINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SEND-WEBPUSH-MESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "")
    ("CUST-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("ORDERTEMPLATEFILLITEMROWS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "")
    ("DOD-CONTROLLER-VENDOR-PRODUCT-CATEGORIES-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATEVPAYMENTMETHODSOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vpm.lisp" "" "")
    ("DOD-CONTROLLER-VEND-SHIPPING-METHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("TOTAL-TAX" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("NST-LOAD-CUSTOMER-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("WITH-HTML-DIV-COL-12" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GET-SHIPSTATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("ADD-LOGIN-USER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("DISPLAY-GST-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PRODUCT-CARD-WITH-DETAILS-FOR-CUSTOMER2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "")
    ("CALCULATE-ORDER-TOTALBEFORETAX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "")
    ("ORDER-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("IS-CANCELLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("GET-HT-VALUES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("WITH-HTML-DIV-ROW" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("PROCESS-SHIPPING-INFORMATION-FOR-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("UPIPAYMENTSADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("ORDER-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("COM-HHUB-POLICY-PRODCATG-ADD-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("SETASSALESPRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("DELETE-VENDOR-APPOINTMENT-INSTANCES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-COMPANY-PRDSUBS-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("UPDATE-INVOICE-SETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read, modify, and save YAML settings." "")
    ("MASK-OTP" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/nst-bl-otp.lisp"
     "" "")
    ("PROCESS-MESSAGES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("CUSTOMERHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("ORDERITEMSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("ORDERSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("DOD-AUTH-ATTR-LOOKUP" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "")
    ("COM-HHUB-TRANSACTION-UPDATE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("PRODUCT-CSV-FILE-DATA-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("WITH-STANDARD-COMPADMIN-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CONVERT-NUMBER-TO-WORDS-USD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("COUNTRY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/dod-sto-zip.lisp" "" "")
    ("DOD-CONTROLLER-UPDATE-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CTX-VIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("PROCESSREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "This function is responsible for initializaing the BusinessService and calling its doService method. It then creates an instance of outboundwebservice"
     "")
    ("W-EMAIL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("MODAL.VENDOR-FREE-SHIPPING-CONFIG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTADDTOCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GET-ODT-PRODUCT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("GET-ORDERS-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("CREATEUPIPAYMENTOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "")
    ("PROCESSDELETEREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Delete method" "")
    ("GET-CUST-WALLET-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("ACTOR-QUEUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-PAYMENT-FAILURE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-ui-pay.lisp" "" "")
    ("ORDERSHIPMENT" "CLASS"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "")
    ("GET-MAX-OF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("RENDER-PICKUP-ONLY-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("UI-LIST-CUSTOMER-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("ADAPTER-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("UPDATE-RESET-PASSWORD-INSTANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "")
    ("CONVERT-NUMBER-TO-WORDS-INR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("MODAL.VENDOR-PRODUCT-EDIT-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("GSTHSNCODESPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("ODTK-ORDER-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "")
    ("COMPANY-UPDATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SHOWORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("GET-ALL-GST-SAC-CODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("TITLE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("INVOICEHEADERPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("HAS-PERMISSION1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("LAZY-CONS" "MACRO" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "")
    ("DISPLAY-CAPTCHA-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("UI-LIST-CUSTOMER-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "")
    ("FILTER-OPREF-ITEMS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("WITH-CATCH-FILE-UPLOAD-EVENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("PERSIST-FREE-SHIPPING-METHOD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "")
    ("INIT-PINCODE" "FUNCTION" "/home/ubuntu/ninestores/hhub/dod-sto-zip.lisp"
     "" "")
    ("SELECT-CUSTOMERS-FOR-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("ACTOR-THREAD-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SEARCHCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("DBADAPTERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("CREATE-MODEL-FOR-SEARCHORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("CANCEL-ORDER-BY-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("CHECK-ZERO-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("COMPANY-SUBSCRIPTION-PLAN-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("WAREHOUSE" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("CUSTOMER-SUBSCRIPTIONS-TABLE-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "")
    ("UPIPAYMENTSHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("OUTBOUND-ADAPTER-ROUTE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("COM-HHUB-TRANSACTION-VENDOR-REJECT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("GENERATE-PRODUCT-EXT-URL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-cad.lisp" "" "")
    ("DOD-CONTROLLER-PASSWORD-RESET-MAIL-LINK-SENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("FIND-CALLER-NAME-FROM-BACKTRACE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Uses string parsing on SBCL's LIST-BACKTRACE to find the 
   symbol name of the function that called the DB adapter."
     "")
    ("BILLSTATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("CREATE-MODEL-FOR-CREATEORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDORORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("MIGRATE-2025AUG-ORDERITEM-UPGRADE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "")
    ("ODT-ORDER-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("VIEWNIL" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" ""
     "")
    ("INVOICEHEADERVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("WITH-STANDARD-ADMIN-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("DOD-PRODUCT-GST" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("PAYMENT-API-KEY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("WITH-VENDOR-NAVIGATION-BAR" "MACRO"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("TEST-WEBPUSH-NOTIFICATION-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "")
    ("DELETE-RESET-PASSWORD-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "")
    ("AUDIT-LEVEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("HHUB-GEN-GLOBALLY-CACHED-LISTS-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("DOD-PRD-CATG" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("DOD-CONTROLLER-CUST-LOGIN-AS-GUEST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PUSH-NOTIFY-SUBS-FLAG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("COMP-CESS-FUNC" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("CREATE-WIDGETS-FOR-VENDORCREATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("CREATE-MODEL-WITHNILDATA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("RESTORE-DELETED-AUTH-POLICY-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("GET-SYSTEM-GST-HSN-CODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "")
    ("W-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("CREATE-WIDGETS-FOR-PRDDETAILSFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-WIDGETS-FOR-DELETECUSTORDITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("INVOICEPRODUCTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "")
    ("CONCAT-ORD-DTL-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "")
    ("DOD-GET-CACHED-PENDING-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-CREATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("CALL-CONTEXT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("SEND-WEBPUSH-NOTIFICATION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "")
    ("HHUB-READ-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("GET-PINCODE-API-RESULT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Simulates the external API call and maps its output to a 4-valued truth value."
     "")
    ("COM-HHUB-POLICY-CAD-LOGIN-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("ASYNC-UPLOAD-FILES-S3BUCKET-BEHAVIOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("DOD-CONTROLLER-LIST-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "")
    ("DELETE-DOD-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("SEARCH-ITEM-IN-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("NST-ACTOR" "CLASS" "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp"
     "Class representing an actor with message queue and behavior." "")
    ("GET-LATEST-OPREF-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTSHOWSHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PRD-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("COM-HHUB-TRANSACTION-SEARCH-CUSTOMER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("INVOICETEMPLATEFILLITEMROWS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("SELECT-DELETED-CUSTOMER-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("GET-ACCOUNT-CURRENCY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("CUSTOMERSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("DISPLAY-COMPADMIN-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-GST-HSN-CODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("CGST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("PASSWORD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("DOD-CONTROLLER-CUSTOMER-PRODUCTS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("MODAL.VENDOR-PAYMENT-METHODS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("GENERATEPDF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("TCUF-VALUE-CHECKER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Adapter function that performs the simple, deterministic T/F check." "")
    ("DOD-CONTROLLER-CUSTOMER-PAYMENT-CANCEL-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-ui-pay.lisp" "" "")
    ("DEFUN-MEMO" "MACRO" "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Define a memoized function." "")
    ("BO-KNOWLEDGE-PROVENANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "")
    ("CUSTOMERADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "")
    ("GET-LOGIN-VENDOR-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "")
    ("GET-SYSTEM-ABAC-SUBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("INVOICEITEM-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("SUBMITSEARCHFORM1EVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("SELECT-PRODUCTS-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("GET-CIPHER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("PERSIST-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("CTX-TRANS-FUNC-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("INVOICES-ACTIONS-MENU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("SHIPPINGRATECHECK" "CLASS"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDORPRODPRICINGACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("COMPANY-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ORDERVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("WITH-STANDARD-COMPADMIN-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-COMPANY-MAXVENDORCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("CREATE-MODEL-FOR-VBULKADDPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("BUSINESSSERVER" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("DISPLAY-SEARCH-RESULTS-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("ODT-VENDOROBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "")
    ("DELETE-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "")
    ("HSNCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("VENDORREPOSITORY" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("GET-CUST-ORDER-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PARSE-DATE-STRING-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read a date string of the form \"YYYY-MM-DD\" and return the 
corresponding universal time."
     "")
    ("HHUB-HTML-PAGE-FOOTER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "")
    ("STATE" "GENERIC-FUNCTION" "/home/ubuntu/ninestores/hhub/dod-sto-zip.lisp"
     "" "")
    ("MAKE-BO-KNOWLEDGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Create a bo-knowledge instance. PROVENANCE may be a single value or a list."
     "")
    ("COM-HHUB-TRANSACTION-SEARCH-GST-HSN-CODES-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("BO-KNOWLEDGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("SELECT-PRODUCT-PRICING-BY-PRODUCT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("ATTRIBUTE-TYPE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("PRODUCT-CARD-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "")
    ("GET-SYSTEM-CURRENCIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "")
    ("MODAL.VENDOR-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CURRNCY" "CLASS"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "")
    ("GET-DATEOBJ-FROM-STRING-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("WAREHOUSEADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("HHUB-GET-CACHED-ROLES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "")
    ("CREATE-MODEL-FOR-DISPLAYORDERHEADERFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "")
    ("VIEWCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("CTX-REQUESTMODEL-PARAMS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("SHIPPED-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "")
    ("GET-ALL-ORDERS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("RESET-VENDOR-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("SELECT-ACTIVE-PRODUCTS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("DELETE-DOD-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "")
    ("DOD-CONTROLLER-CUST-LOGIN-OTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PRODUCT-QTY-EDIT-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-SEARCHINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("DOD-CONTROLLER-CUST-LOGIN-WITH-OTP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("TODAY-LOG-FILE-PATH" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-otp.lisp" "" "")
    ("CREATE-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("WITH-HTML-INPUT-NUMBER" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("INIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Set the domain object of the ResponseModel " "")
    ("CREATE-WIDGETS-FOR-CREATEORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("UPIPAYMENTSRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "")
    ("GUEST-CUST-PAYMENT-MODE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-PRODUCT-PRICING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTOMERINDEXPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-GST-HSN-CODE-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "")
    ("ORDERITEMS-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "")
    ("ACTOR-CREATED-AT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "")
    ("SALT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("INVOICETEMPLATEFILLITEMROWSPUBLIC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("DOD-PRODUCT-PRICING" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "")
    ("LAZY-NULL" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "")
    ("INVOICETEMPLATEFILL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("COM-HHUB-TRANSACTION-ADD-PRODUCT-TO-INVOICE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("GET-TENANT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("DOD-CONTROLLER-DISPLAY-VENDOR-TENANTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("HHUB-WRITE-FILE-FOR-CSS-INLINING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("VPAYMENTMETHODSHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDPUSHSUBSCRIBEPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("COM-HHUB-POLICY-SADMIN-HOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("PERSIST-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("MODAL.VENDOR-UPDATE-PAYMENT-GATEWAY-SETTINGS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTDELETEORDERSUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("DOD-CONTROLLER-LIST-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "")
    ("PERM-GRANTED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "")
    ("HHUB-NO-RESULT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Raised when a DB query returns zero rows." "")
    ("UPI-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("RENDER-STANDARD-SHIPPING-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("PRDINLIST-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("CREATE-MODEL-FOR-CADLOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("COM-HHUB-TRANSACTION-CREATE-CUSTOMER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTSHIPMETHODSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("GET-LOGIN-CUST-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-MODEL-FOR-DELETEINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "")
    ("UPIENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "")
    ("ACCORDION-EXAMPLE2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("UI-LIST-ORDERS-FOR-EXCEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "")
    ("CREATE-WIDGETS-FOR-SEARCHORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("WITH-HTML-INPUT-PASSWORD" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("CREATE-PAYMENT-GATEWAY-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("EMPLOYEES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("SELECT-HSN-CODE-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "")
    ("DOD-CONTROLLER-LOW-WALLET-BALANCE-FOR-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CRUD-OP" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "")
    ("COM-HHUB-POLICY-VENDOR-ADD-PRODUCT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("BUSINESSSERVICES-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("ORDERITEMVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("GET-COMPLETED-ORDER-ITEMS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "")
    ("UPDATE-VENDOR-PAYMENT-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("RESTORE-DELETED-VENDOR-AVAILABILITY-DAY-INSTANCES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "")
    ("SALUTATION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "")
    ("POLICY-ATTR-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "")
    ("CREATE-MODEL-FOR-PUBLISHACCOUNTEXTURL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "")
    ("HHUB-CONTROLLER-GET-SHIPPING-RATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("COM-HHUB-POLICY-CAD-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "")
    ("CREATE-BULK-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("CREATE-MODEL-FOR-VENDPAYMENTMETHODSUPDATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("COMPANY-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "")
    ("GET-MAX-ORDER-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "")
    ("COMMENTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "")
    ("WITH-MVC-UI-COMPONENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "")
    ("GET-VENDOR-TENANTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "")
    ("BUSINESSOBJECTS-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "")
    ("EDITINVOICEWIDGET-SECTION3" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "")
    ("GETLOGINVENDORCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("CREATE-WIDGETS-FOR-CUSTORDERCREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATE-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "")
    ("CREATE-MODEL-FOR-CREATEORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "")
    ("CURRENT-DATE-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in YYYY/MM/DD format" "")
    ("CHECK-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "")
    ("CREATE-RESET-PASSWORD-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "")
    ("ADDRESS-PRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "")
    ("SELECT-CUSTOMERS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "")
    ("COM-HHUB-ATTRIBUTE-COMPANY-CODORDERS-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "")
    ("DOD-VENDOR-APPOINTMENT" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vas.lisp" "" "")
    ("DOCREATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "")
    ("DEACTIVATE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "")
    ("W-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "")
    ("GSTHSNCODESVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "")
    ("SELECT-HSN-CODES-BY-TEXT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "")
    ("CUSTOMER-VENDOR-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("CREATEORDEROBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "")
    ("LAZY-MAPCAR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "")
    ("GET-ORDER-ITEMS-TOTAL-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "")
    ("ORDER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "")
    ("CREATE-WIDGETS-FOR-VENDPUSHSUBSCRIBEPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "")
    ("WRITE-FINAL-LOOKUP-FILE" "FUNCTION" "nst-ui-prosymloo.lisp"
     "Writes the collected and merged symbol data to the file in the specified function format."
     "")))))
