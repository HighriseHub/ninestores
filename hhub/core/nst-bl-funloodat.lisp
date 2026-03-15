(defun function-lookup-table () (function (lambda () 
  '(
    ("COPYORDERITEM-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-OrderItem.lisp" "" "" NIL)
    ("OPERATION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("PRESENTER-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("CALCULATE-INVOICE-TOTALCGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" ""
     ((:DESCRIPTION
       . "Calculates total CGST amount for an invoice by summing CGST across all line items")
      (:DOMAIN . :INVOICE) (:CATEGORY . :CALCULATION)
      (:TAGS :TAX :CGST :INVOICE :TOTALS)
      (:INPUTS
       ((:NAME . INVOICEITEMS) (:TYPE . LIST) (:REQUIRED . T)
        (:SOURCE . :PARAMETER)))
      (:OUTPUTS
       ((:NAME . TOTAL-CGST) (:TYPE . DECIMAL) (:BINDS-AS . :CGST-AMOUNT)))
      (:READS :INVOICE-LINE-ITEMS) (:WRITES) (:THROWS) (:PURE) (:COST . :LOW)))
    ("COLLECT-ABAC-ATTRIBUTES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("MODAL.VENDOR-ORDER-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("IS-B2B-CUSTOMER-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Check if customer is B2B (has GSTIN)" "" NIL)
    ("DOD-CONTROLLER-CMPSEARCH-FOR-VEND-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-PRDPRICEWITHDISCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("WITH-HTML-TABLE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ENFORCEVENDORSESSION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-LOGIN-VENDOR-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-ALL-GST-SAC-CODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("SGST-AMOUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTVEN-SIGNUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("UI-LIST-SHOPCART-FOR-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("CHECK-LOW-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("HHUB-JSON-BODY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("REQUESTMODELVENDORAPPROVAL" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("LOG-CRITICAL-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Logs a critical error, automatically including the function that initiated the DB call."
     "" NIL)
    ("COUNT-VENDOR-ORDERS-PENDING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("PAYMENTCONFIRM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("DOD-CONTROLLER-DBRESET-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDADDTOCARTUSINGBARCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SELECT-ALL-INVOICE-HEADERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "" NIL)
    ("CALCULATE-ORDER-TOTALAFTERTAX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("FORCE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" ""
     NIL)
    ("COM-HHUB-ATTRIBUTE-ROLE-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("CUSTOMER-SUBSCRIPTIONS-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-REQUEST-NEW-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("GET-DATE-STRING-MYSQL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in DD-MM-YYYY format." "" NIL)
    ("DOD-CONTROLLER-MY-ORDERS1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("BANNER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("W-COUNTRY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("BO-MERGE*" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Merge multiple bo-knowledge objects (fold left using bo-merge)." "" NIL)
    ("GET-VENDOR-AVAILABILITY-DAY-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CADUPDATEDETAILSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("UI-LIST-CUST-ORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("DELETE-VENDOR-AVAILABILITY-DAY-INSTANCES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "" NIL)
    ("DOD-VENDOR-SHIP-ZONES" "CLASS"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "" NIL)
    ("BO-KNOWLEDGE-FROM-BOUNDARY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Convert boundary-result (list or values) into a bo-knowledge instance.
   boundary-result is expected like (TRUTH PAYLOAD &optional SOURCE ...)."
     "" NIL)
    ("CUSTOMER-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "" NIL)
    ("SHIPADDR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("DOD-CONTROLLER-SEARCH-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PRODUCT-VENDOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("BUSTRANS-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-UPDATE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWINVOICEPAYMENTPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("MIGRATE-UOM-TO-UQC-FOR-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp"
     "Migrate product's unit_of_measure to GST-compliant UQC.
   Keeps original UOM for display, adds UQC for GST compliance."
     "" NIL)
    ("DOD-CONTROLLER-CUST-ORDERS-CALENDAR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("RESPONSEADDRESS" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("CREATE-DIGEST-SHA1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("UPIPAYMENTSDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("MODAL.REJECT-VENDOR-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("CREATE-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-REGISTER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("MERGE-KNOWLEDGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Merges two boundary results of the form (STATUS PAYLOAD)
   according to Belnap knowledge ordering.
   Returns a new (STATUS PAYLOAD) pair."
     "" NIL)
    ("MIGRATE-2026JAN-CREATE-GSTUPGRADE-TABLES" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "Create GST upgrade GSTR1 export table." "" NIL)
    ("GETBUSINESSSESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Get the business session" "" NIL)
    ("SEND-TEMP-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("ADDBUSINESSOBJECTREPOSITORY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Creates a new BusinessObjectRepository and returns the instance" "" NIL)
    ("GET-LOGIN-CUSTOMER-COMPANY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("COMPANY-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("UI-LIST-SHOPCART-READONLY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("COMPCESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("URI-PREFIX-BOUNDARY-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DISPLAYSTOREPICKUPWIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DISPLAY-AS-TILES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-B2B-CUSTOMERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Get all B2B customers (with GSTIN)" "" NIL)
    ("CUSTOMER-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("NST-LOAD-EMAIL-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("UPDATE-PRD-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("HHUB-SESSION-VALIDP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "" NIL)
    ("GET-BUS-TRAN-POLICY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-CREATE-WHATSAPP-LINK-WITH-MESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HTML-BACK-BUTTON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HSN-WISE-STOCK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("LIST-DOD-USERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("GET-SYSTEM-BUS-TRANSACTIONS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("GET-UNIX-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CREATERESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Creates a responsemodel from businessobject" "" NIL)
    ("CASE-TRUTH" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "A specialized CASE macro for logic values." "" NIL)
    ("JSCRIPT-DISPLAYSUCCESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("READ-YAML-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read a YAML file and return its parsed content." "" NIL)
    ("REJECT-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-cad.lisp" "" "" NIL)
    ("CREATE-PRODUCTS-CSV2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DELETE-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("VM-REASON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CRM-DB-CONNECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("SELECT-PAYMENT-TRANS-BY-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-bl-pay.lisp" "" "" NIL)
    ("ORDERITEMHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("BO-KNOWN-TRUE-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is known true." "" NIL)
    ("HHUBVENDORTENANTS" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("VENDORWEBPUSHNOFITYPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("SELECT-INVOICE-HEADER-BY-CONTEXT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "" NIL)
    ("CALCULATE-SHIPPING-COST-FOR-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ORDER-ITEM-EDIT-POPUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("INVOICEITEMADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("COMPANY-TYPE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-ABAC-SECURITY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("FULFILLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("GST-HSN-CODES-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("MAKE-LAZY" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "" NIL)
    ("WITH-HTML-EMAIL-TEMPLATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("GET-SHOP-CART-TOTAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("UPIPAYMENT" "CLASS" "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp"
     "" "" NIL)
    ("MIGRATE-2025MAY-ADD-PRODUCT-CODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("WAREHOUSE-PURPOSE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CHECK-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("WITH-NON-NULL-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "A specialized version of WITH-BOUNDARY-CHECK for deterministic null checks.
   If the value-form is non-NIL (Status :T), the BODY is executed with the value 
   bound to the variable PAYLOAD.
   If the value-form is NIL (Status :F), the macro returns an explicit :VALUE-MISSING 
   signal immediately."
     "" NIL)
    ("COM-HHUB-POLICY-SHOW-INVOICES-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("PAYMENT-API-SALT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("DISPLAY-CUSTOMER-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SADMIN-CREATE-USERS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("VIEWMODELCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-RESTORE-ACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("USER-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "" NIL)
    ("PRICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("WITH-HTML-SUBMIT-BUTTON" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("IGSTRATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("GET-HT-VAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DISPLAY-ADD-PRODUCT-TO-INVOICE-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-VENDORORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("HHUB-INIT-BUSINESS-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("COPYCUSTOMER-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-bl-Customer.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-INDEX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("UPIPAYMENTSHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("GET-VENDOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("GET-USER-ROLES.ROLE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("CURRENT-DATE-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("UI-LIST-PROD-CATG-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("HHUB-INIT-NETWORK-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("ADDBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Reads the params and create a new BusinessObject. Return the newly created BusinessObject"
     "" NIL)
    ("HAS-PERMISSION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("DOREAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "" NIL)
    ("SETCOMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "Set the Company" ""
     NIL)
    ("TOTALITEMVAL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("MEMOIZEKEYFUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/memoize.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-VENDOR-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-REMOVESHOPCARTITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CREATE-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("RESTORE-DELETED-BUS-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("BUSINESSOBJECTCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("DISCOVERSERVICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "discover a business service based on the service-code" "" NIL)
    ("DOD-CONTROLLER-PASSWORD-RESET-TOKEN-EXPIRED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("REJECT-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("DISPLAY-ADDRESS-CONSENT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-SHIPPING-METHODS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PICTURE-PATH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VEND-INDEX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-COUNTRY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("GENERATE-LOOKUP-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp" "" "" NIL)
    ("RESTORE-DELETED-ORDERPREFS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SAVE-INVOICE-PRINT-SETTINGS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("RETURN-JSON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("REPORT-META-COVERAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Prints a simple coverage report after generation." "" NIL)
    ("TOKEN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "" NIL)
    ("DISPLAY-GST-HSN-CODE-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("FIND-PINCODE-DETAILS-FROM-DB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-pincodes.lisp" "" "" NIL)
    ("MODAL.CUSTOMER-FORGOT-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PAYMENT-MODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-READ-WAREHOUSE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Handler for reading a single warehouse using context flow dispatcher" ""
     NIL)
    ("DOD-CUST-LOGIN-AS-GUEST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("VENDOR-UPLOAD-FILE-S3BUCKET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("TOTAL-DISCOUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("CITY" "GENERIC-FUNCTION" "/home/ubuntu/ninestores/hhub/dod-sto-zip.lisp"
     "" "" NIL)
    ("DOWNLOADHTMLFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("LAZY-FIND-IF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" "" NIL)
    ("INVOICEHEADER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-CUSTOMER-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GENERATE-GST-TAX-BREAKDOWN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp"
     "Generate the invoice tax breakdown object based on the invoice header and invoice items"
     "" NIL)
    ("DELETE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("REQUESTCREATEWEBPUSHNOTIFYVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("COPY-BUSINESSOBJECT-TO-DBOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Syncs the dbobject and the domainobject" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-SEARCH-CUST-WALLET-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CALCULATE-INVOICE-TOTALGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" ""
     ((:DESCRIPTION
       . "Calculates total GST amount for an invoice by summing GST across all line items")
      (:DOMAIN . :INVOICE) (:CATEGORY . :CALCULATION)
      (:TAGS :TAX :GST :INVOICE :TOTALS)
      (:INPUTS
       ((:NAME . INVOICEITEMS) (:TYPE . LIST) (:REQUIRED . T)
        (:SOURCE . :PARAMETER)))
      (:OUTPUTS
       ((:NAME . TOTAL-GST) (:TYPE . DECIMAL) (:BINDS-AS . :GST-AMOUNT)))
      (:READS :INVOICEITEMS) (:WRITES) (:THROWS) (:PURE) (:COST . :LOW)))
    ("CUSTOMER-ADD-TO-CART-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("HHUB-BUSINESS-ADAPTER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("BO-KNOWLEDGE-SUMMARY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "" NIL)
    ("WITH-HTML-CHECKBOX" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-TEXTAREA" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ZONEZIPCODESDISPLAYFUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("BILLZIPCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("FIND-CUSTOMER-BY-PAN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Find customer by PAN" "" NIL)
    ("CREATE-B2C-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Create a new B2C customer" "" NIL)
    ("REQ-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("CUSTGSTIN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("AMOUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("VIEWMODELNIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("WEBPUSHNOTIFYCUSTOMER" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("DOD-CONTROLLER-LOW-WALLET-BALANCE-FOR-ORDERITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("HTMLVIEW" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" ""
     "" NIL)
    ("VENDOR-DELETE-FILES-S3BUCKET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("VENDOR-CREATE-UPDATE-CUSTOMER-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("WITH-STANDARD-VENDOR-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("MODAL.APPROVE-VENDOR-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("CREATEMODELFORTRANSACTIONTOPOLICYLINKPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GET-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-DISPLAYINVOICEPUBLIC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("CREATECUSTOMEROBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-bl-Customer.lisp" "" "" NIL)
    ("WITH-ENTITY-READ" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SEARCHINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("SELECT-ALL-GSTHSNCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "" NIL)
    ("DOD-PAYMENT-TRANSACTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-dal-pay.lisp" "" "" NIL)
    ("DISPLAY-VENDORS-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-ORDER-ITEMS-TRACK" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CAD-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("SELECT-BUS-TRANS-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("BUSINESSOBJECTNIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("NST-LOAD-ORDER-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-ADD-ORDER-OTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-AUTH-POLICIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-UPDATE-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("ACTIVE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("DELETE-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("GET-SYMBOL-TYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Determines the type of the given symbol S." "" NIL)
    ("GET-CURRENCY-FONTAWESOME-MAP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-UPDATE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("INVOICEITEMSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-EDIT-INVOICE-HEADER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("GST-BREAKDOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp"
     "A container that groups taxes by HSN and Rate." "" NIL)
    ("VEDORPASSCODESERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("W-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("ACCOUNT-CREATED-DAYS-AGO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("BO-KNOWLEDGE-TRUTH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "" NIL)
    ("CURRENT-YEAR-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current year as a string in YYYY format" "" NIL)
    ("LEGAL-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("INITBUSINESSSERVER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-PUBLISH-ACCOUNT-EXTURL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-CURRENTPRODCATGCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("SELECT-PRDCATG-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("VENDOR-UPI-PAYMENT-CANCEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("CURR-SYMBOL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "" NIL)
    ("%DETECT-DUPLICATE-PKS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Return T if PK-EXTRACTOR applied to ROWS yields any duplicate values." ""
     NIL)
    ("MY-NOT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Implements the logical NOT operator for FDE logic." "" NIL)
    ("CREATE-MODEL-FOR-PRDDETAILSFORGUESTCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COPYGSTHSNCODES-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "" NIL)
    ("GET-LOGIN-CUSTOMER-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("SETEXCEPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Set the Exception for the Database Adapter Service" "" NIL)
    ("DOD-CONTROLLER-VEND-LOGIN-OTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CALL-CONTEXT-READALL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("VPAYMENTMETHODSADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("ORDER-FULFILLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("MAKE-PRESENTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Returns a presenter instance for this request." "" NIL)
    ("DISPLAY-NAME&EMAIL-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWCUSTOMERUPIPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("UPDATEINVOICEITEMSSTOCKINVENTORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("EQUAL-COMPANIESP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-ORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COPYINVOICEITEM-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "" NIL)
    ("PRINT-THREAD-INFO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CURRENT-TIME-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current time  as a string in HH:MM:SS  format" "" NIL)
    ("CREATE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("HASHCALCULATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("BILLCITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("EDIT-INVOICEITEM-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CUST-EDIT-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("ACTOR-LAST-ACTIVE-AT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("RENDER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Renders the viewmodel as View" "" NIL)
    ("VERIFY-SUPERADMIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "" NIL)
    ("MODAL.PRODUCT-REMOVE-FROM-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("DOD-CONTROLLER-TRANS-TO-POLICY-LINK-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-DISPLAYCUSTOMERPROILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("HHUBSENDMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DB-DELETE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Delete the dbobject in the database" "" NIL)
    ("CREATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("DELETED-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("UNSAFE-SQL-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-DELETECUSTORDITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-PRIVACY-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("SELECT-VENDOR-WAREHOUSES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select all warehouses owned by a vendor" "" NIL)
    ("CREATE-MODEL-FOR-CUSTORDERSUBS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "" NIL)
    ("RM-CONFLICTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("SELECT-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("SELECT-PRDCATG-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("DOD-VEND-PROFILE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("RESTORE-DELETED-VENDORS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("ORDER-AMT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("BREAK-END-TIME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("SEND-NEW-COMPANY-REGISTRATION-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("UPIPAYMENTSVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VEND-SHIPPING-METHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("PERSIST-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-DELETE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("ATTRINLIST-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("DOD-VPAYMENT-METHODS" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("INVOICEHEADERCONTEXTIDREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("NST-LOAD-PRODUCT-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTADDORDERSUBS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-ADD-TO-CART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-NEW-STORE-REQUEST-STEP2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("VENDOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("GET-BILLSAMEASSHIP" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("ORDERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("VENDORAPPROVALSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("DOD-BUS-TRANSACTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("PRODUCT-PRICE-WITH-DISCOUNT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("BEFORE-DISPATCH-HOOK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GSTHSNCODES" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-PRDPRICEWITHDISCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("DISPLAY-PHONE-TEXT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-OTPLOGINPAGEV2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("WAREHOUSEREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("GET-LOGIN-TENANT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-SEARCH-MY-CUSTOMER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-VOLUMETRIC-WEIGHT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "" NIL)
    ("RENDER-UI-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("IS-GST-COMPLIANT-UQC-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp"
     "Check if code is a pure GST UQC (not an alias)." "" NIL)
    ("COM-HHUB-POLICY-GST-HSN-CODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("PROCESSUPDATEREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Update method" "" NIL)
    ("EDITINVOICEWIDGET-SECTION1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DOD-VENDOR-AVAILABILITY-DAY" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-PERMISSION-DENIED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-INVALID-EMAIL-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DELETE-VENDORS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("IGST-RATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("HHUB-LOG-MESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("SELECT-BUS-OBJECT-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("GET-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("DISPLAY-PRODUCTS-CAROUSEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("WITH-COMPADMIN-NAVIGATION-BAR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("CALL-CONTEXT-CREATE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("NEW-TRANSACTION-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DOD-ORD-PREF" "CLASS"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "" NIL)
    ("PERSIST-VENDOR-SHIP-ZONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("WITH-NO-NAVBAR-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-VENDOR-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("GET-SYSTEM-BUS-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("DELETEBUSINESSOBJECTREPOSITORY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Delete the business object repository" "" NIL)
    ("DOD-CONTROLLER-ADD-USER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "" NIL)
    ("WITH-OPR-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DOD-CONTROLLER-LIST-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("WITH-HTML-FORM" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-BUS-OBJECT-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("OWNER-ENTITY-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("DISPLAY-PRODUCT-IN-INVOICE-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DELETEBUSINESSSESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Deletes the business session on a given key" "" NIL)
    ("COPYORDERITEM-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-OrderItem.lisp" "" "" NIL)
    ("TRANSACTION-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("UNIT-PRICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("DOD-VEND-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("MIGRATE-2026MARCH-CREATE-GOODS-RECEIPT-NOTE-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "" "" NIL)
    ("REVCHARGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-EDITINVOICEHEADERPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CUSTOMER-ADDRESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("PERMISSION-CHECKER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDORPROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-SUBSCRIPTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTMYORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PAYLATERENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("CREATE-UI-FOR-CUSTORDERSUBS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-WAREHOUSE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Handler for creating a new warehouse using context flow dispatcher with ownership"
     "" NIL)
    ("HHUB-CONTROLLER-GET-SHIPPING-RATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("STATECODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("DISPLAY-INVOICE-ITEM-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("NST-GET-CACHED-ORDER-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("RESTORE-DELETED-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("GET-ACTIVE-WAREHOUSES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Get all active warehouses for a tenant" "" NIL)
    ("COPYINVOICEHEADER-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "" NIL)
    ("GET-DATESTR-FROM-OBJ-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in YYYY-MM-DD format." "" NIL)
    ("DOD-RESPONSE-CAPTCHA-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GET-ORDERS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-UPDATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-UPLOAD-SHIPPING-RATETABLE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COMMUNITYSTORE" "CLASS"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("INVHEADID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("ZONENAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTPRODBYVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("UPDATE-VENDOR-AVAILABILITY-DAY-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "" NIL)
    ("STOP-ACTOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("GENERATE-INVOICE-EXT-URL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DOD-CONTROLLER-MAKE-PAYMENT-REQUEST-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-ui-pay.lisp" "" "" NIL)
    ("DELETE-DOD-USERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("QTY-PER-UNIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-INVOICEHEADER-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("GSTNUMBER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-RESET-PASSWORD-ACTION-LINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("WITH-VENDOR-BREADCRUMB" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GENERATE-LISP-FILENAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generates the Lisp file name like nst-dal-odt.lisp from 'order details' and 'dal'."
     "" NIL)
    ("GET-ORDERS-FOR-VENDOR-BY-SHIPPED-DATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("SELECT-PRODUCT-PRICING-BY-PRODUCT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("PRODUCT-CATEGORY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("GET-PUSH-NOTIFY-SUBSCRIPTION-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "" NIL)
    ("VENDOR-UPI-PAYMENT-CONFIRM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("CTX-REQUEST-URI" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-ORDER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("MAKE-VIEW" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Returns a view instance for this request." "" NIL)
    ("NST-API-INTERNAL-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("GET-PAYMENT-TRANS-BY-TRANSACTION-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-bl-pay.lisp" "" "" NIL)
    ("BREAK-START-TIME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-UPDATE-WAREHOUSE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Handler for updating a warehouse using context flow dispatcher with ownership"
     "" NIL)
    ("COM-HHUB-TRANSACTION-UPDATE-CUSTOMER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("COUNT-ORDER-ITEMS-PENDING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("GET-CUST-WALLETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("IAM-SECURITY-PAGE-HEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("VENDORWEBPUSHNOTIFYADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("SELECT-INVOICE-ITEM-BY-PRODUCT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CREATEINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("ATTR-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "" NIL)
    ("DOD-RESET-VENDOR-PRODUCTS-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-PAYMENT-METHODS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COM-HHUB-BUSINESSFUNCTION-BL-CREATEPUSHNOTIFYSUBSCRIPTIONFORVENDOR"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp"
     "" "" NIL)
    ("PUBLICKEY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("SAVE-CUST-ORDER-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ODTK-UPDATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "" NIL)
    ("VENDOR-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-CUST-EDIT-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDORUPISETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("SELECT-COMPANY-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CAD-PRODUCT-APPROVE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-BUSINESS-FUNCTION-TEMPSTORAGE-GETPUSHNOTIFYSUBSCRIPTIONFORVENDOR"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp"
     "" "" NIL)
    ("COM-HHUB-POLICY-SHOW-INVOICE-PAYMENT-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GETMINORDERAMT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("RESTORE-DELETED-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("DISPLAY-WAREHOUSE-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Display a single warehouse row with ownership information" "" NIL)
    ("VENDORPROFILESERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-UPDATE-GST-HSN-CODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GET-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("HHUB-REMOVE-VENDOR-PUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("OWNER-ENTITY-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("MAKE-PAYMENT-REQUEST-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-ui-pay.lisp" "" "" NIL)
    ("HHUB-WEBPUSH-SUBSCRIPTION-EXISTS" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("DOD-CONTROLLER-DEL-CUST-ORD-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("WITH-CUSTOMER-NAVIGATION-BAR-V2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("RESET-CUST-ORDER-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-TEXT-HIDDEN" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HTML-RANGE-CONTROL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-PINCODE-DETAILS-ADAPTER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "TCUF Boundary Adapter for Pincode lookup. 
   Contract: Returns (ADDRESS-INSTANCE/NIL TCUF-STATUS)."
     "" NIL)
    ("GET-LOGIN-CUSTOMER-TYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("META" "MACRO" "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Alist is passed already quoted by the caller.
   Stored directly — no transformation needed."
     "" NIL)
    ("DB-FETCH-CUSTOMER-WEBPUSHNOTIFYSUBSCRIPTIONS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "" NIL)
    ("INIT-GST-STATECODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWVENDORCUSTOMERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("SELECT-CUSTOMER-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SEARCH-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-SAVE-VENDOR-PUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "" NIL)
    ("VENDOR-PRODUCT-CATEGORY-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("MODAL.VENDOR-PRODUCT-PRICING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("ROLE-UPDATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("SELECT-COMPANIES-BY-PINCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTMYORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-UPDATEINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTORDERCREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GET-PROJECT-SYMBOLS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Collects ALL defined symbols (internal and external functions, macros, and classes) 
   from the project's packages."
     "" NIL)
    ("VENDORPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("STOREPICKUPENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("ORDERADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CAD-LOGIN-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-DISPLAYINVOICEEMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-CURRENCY-HTML-SYMBOLS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("WITH-CATCH-SUBMIT-EVENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WADDR1" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("REQUESTGETWEBPUSHNOFITYVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SADMIN-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("MIN-ITEM" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("SEND-CONTACTUS-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-VENDSHIPPINGMETHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("PRD-IMAGE-PATH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("GSTHSNCODESDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("NST-LOAD-INVOICE-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("AUTHSIGN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("WALLETENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("ODT-STATUS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("GET-BILLSTATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("CALL-CONTEXT-READ" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("TENANT-OVERRIDES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GET-RIGHT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("TRANSACTION-TYPE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("WITH-CUST-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ROUTE-KEY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("CTX-PRESENTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CADPRODUCTREJECTACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-UPDATE-ORDER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("WITH-NST-ERROR-BOUNDARY" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("RESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-COMPADMIN-UPDATEDETAILS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DOD-GET-CACHED-COMPLETED-ORDERS-TODAY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("MODAL.UPLOAD-CSV-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("HHUB-EMAIL-LOGO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("GETBUSINESSSERVICEMETHOD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("INVOICEHEADERADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("GET-OPREF-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "" NIL)
    ("UI-LIST-VENDOR-ORDERS-BY-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "" NIL)
    ("GENERATE-INVOICE-ITEMS-ROWS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp"
     "Extracts the row sub-template and repeats it for every item." "" NIL)
    ("DOD-CONTROLLER-ADD-TRANSACTION-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GET-SHIP-ADDRESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("GUESTCUSTOMER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("HSNCODE4DIGIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("DISPLAY-UPI-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("SELECT-VPAYMENT-METHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vpm.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-ADD-PRODUCT-TO-INVOICE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("GET-LOGIN-USER-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SADMINLOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("SELECT-CUSTOMER-LIST-BY-PHONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("NST-GET-CACHED-INVOICE-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("W-PHONE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("CREATE-VENDOR-SHIP-ZONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("FINYEAR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("WITH-BO-KNOWLEDGE-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Enforces clean architecture by requiring explicit handling of all four 
   TCUF states (T, F, U, C) whenever calling an external/unreliable API 
   or boundary function. The API-CALL must return two values: (PAYLOAD STATUS).
   The result payload is made available to all status clauses under the
   variable name 'payload', and the status is available as 'status'."
     "" NIL)
    ("GET-VENDOR-ORDER-BY-STATUS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("WITH-CAD-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DISPLAY-SHIPPING&BILLING-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ORDERITEM" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("DISPLAY-SUPERADMIN-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-ABAC-ATTRIBUTES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("SELECT-ALL-WAREHOUSES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select all warehouses for a tenant" "" NIL)
    ("GET-VENDOR-ORDERS-FROM-UPI-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DELETE-CUST-PROFILES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-COMPADMIN-HOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDORSETORDERFULFILLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("UI-LIST-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("DOD-BUS-OBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-ADDRESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("UPIPAYMENTSPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-ABOUTUS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("INVOICEHEADERHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("FIND-CUSTOMER-BY-COMPANY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Find customer by company name" "" NIL)
    ("INVOICEHEADERDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-TEXT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VEND-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("RESPONSEGETWEBPUSHNOTIFYVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
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
     "" NIL)
    ("EXTRACT-PAN-FROM-GSTIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Extract PAN number from GSTIN (characters 3-12)" "" NIL)
    ("MAYBE-SAVE-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp"
     "Create a new STANDARD customer only if:
   - Checkbox Save Address? is checked
   - Customer does not already exist
   - Customer not already saved during this checkout session."
     "" NIL)
    ("PRODUCT-SEARCH-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DISPLAY-INVOICEHEADER-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("BUSINESSCONTEXT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("WITH-STANDARD-ADMIN-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SADMIN-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("BILLADDR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("CREATEVIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Converts the ResponseModel to ViewModel" "" NIL)
    ("ROUTE-OP->METHOD-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Extract operation from keyword like :customer/read and compute method name."
     "" NIL)
    ("RESTORE-DELETED-RESET-PASSWORD-INSTANCES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-INVOICEPRINTSETTINGSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("CONSTRAINT-MESSAGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-INVOICESETTINGSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("CGSTRATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-DEL-ORDERPREF-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("TAXABLEVALUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VGENPRODCTTEMPL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("SELECT-WAREHOUSES-BY-CITY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select warehouses by city" "" NIL)
    ("DISPLAY-ADD-CUSTOMER-TO-INVOICE-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("RENDERLISTVIEWHTML" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "Renders a list view"
     "" NIL)
    ("DOD-CONTROLLER-VENDOR-SEARCH-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CREATEINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DEFAULT-TRANSPORTER-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("DOD-INDIA-PINCODES" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-dal-pincodes.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-MAXPRODCATGCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("WAREHOUSESERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("PERSIST-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-REVENUE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-SWITCH-TENANT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("MODAL.VENDOR-UPLOAD-PRODUCT-IMAGES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("SHIPPING-COST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("GSTHSNCODESSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("DOD-CONTROLLER-NEW-COMPANY-REQUEST-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("CANCEL-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("MODAL-DIALOG" "MACRO" "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "" "" NIL)
    ("UI-LIST-CUST-PRODUCTS-HORIZONTAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("DELETE-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("WITH-SINGLE-COLUMN-EMAIL" "MACRO"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("LOAD-OLD-DATA-AND-KEYWORDS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Loads existing lookup data and returns a hash table mapping symbol 
   names to (keywords . meta-plist) — preserving both old slots."
     "" NIL)
    ("WITH-HTML-INPUT-HIDDEN" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("SEARCH-ODT-BY-ORDER-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("ORDERREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SEARCH-PRODUCT-FOR-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DISPLAY-ORDERITEM-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("DELETE-SUBSCRIPTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "" NIL)
    ("GET-ORDER-ITEM-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("CTX-OUTPUT-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("CREATEWIDGETSFORTRANSACTIONTOPOLICYLINKPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("NST-LOAD-VENDOR-TABLES-STRUCTURE-FOR-AGENTIC-AI" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("SELECT-PRODUCTS-BY-CATEGORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("ASYNC-UPLOAD-IMAGES-FOR-BULK-UPLOAD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-VENDOR-TENANT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("GET-VENDOR-AVAILABILITY-DAY-BY-AVAIL-DATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "" NIL)
    ("INVOICEITEMPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWVENDORCUSTOMERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("IS-CONVERTED-TO-INVOICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("BUSINESSSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("DB-FETCH-VENDOR-WEBPUSHNOTIFYSUBSCRIPTIONS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp"
     "Gets Web Push Notify subscriptions for a given Vendor" "" NIL)
    ("DOD-CONTROLLER-VENDOR-PASSWORD-RESET-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-VENDOR-APPOINTMENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "" NIL)
    ("GET-RESET-PASSWORD-INSTANCE-BY-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("DELETE-VENDOR-TENANT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("DOD-CUST-PROFILE" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("GET-BILLADDRESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("DOUPDATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "" NIL)
    ("CALCULATE-INVOICE-TOTALSGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" ""
     ((:DESCRIPTION
       . "Calculates total SGST amount for an invoice by summing SGST across all line items")
      (:DOMAIN . :INVOICE) (:CATEGORY . :CALCULATION)
      (:TAGS :TAX :SGST :INVOICE :TOTALS)
      (:INPUTS
       ((:NAME . INVOICEITEMS) (:TYPE . LIST) (:REQUIRED . T)
        (:SOURCE . :PARAMETER)))
      (:OUTPUTS
       ((:NAME . TOTAL-SGST) (:TYPE . DECIMAL) (:BINDS-AS . :SGST-AMOUNT)))
      (:READS :INVOICEITEMS) (:WRITES) (:THROWS) (:PURE) (:COST . :LOW)))
    ("CREATE-WIDGETS-FOR-CUSTVEN-SIGNUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VBULKPRODUCTSADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GETWEBPUSHNOTIFYVENDORVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("MODAL.VENDOR-PRODUCT-SHIPPING-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("GET-SYMBOL-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Finds the file path where the symbol S is defined using SWANK:FIND-DEFINITIONS-FOR-EMACS.
   Returns the pathname string or an empty string if not found."
     "" NIL)
    ("INVOICEITEMS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("EXPIRED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("MERGE-KNOWLEDGE*" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-SAVE-VENDOR-UPI-SETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("PAN-NUMBER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CREATE-ORDER-EMAIL-CONTENT-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("INVOICEITEMREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("DELETE-OPREFS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "" NIL)
    ("CONTEXT-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("DISPLAY-INVOICE-ITEM-ROW-PUBLIC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("RENDERJSON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Takes the viewmodel and converts into JSON" "" NIL)
    ("CREATE-ORDER-EMAIL-CONTENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("COPYCUSTOMER-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-bl-Customer.lisp" "" "" NIL)
    ("WAREHOUSESEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CURRENT-DATE-STRING-DDMMYYYY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in DD-MM-YYYY format" "" NIL)
    ("PRODUCT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-UPDATE-FREE-SHIPPING-METHOD-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CONTACTUSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("WITH-ENTITY-UPDATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("UPDATE-ITEM-IN-TAX-BREAKDOWN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp"
     "Adjusts the breakdown when an item is modified." "" NIL)
    ("DOD-CONTROLLER-LIST-ABAC-SUBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-GENERATE-TEMP-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("UPDATE-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("WADDR2" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CREATE-ROLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("CTX-BO-KNOWLEDGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SHOW-CUSTOMER-UPI-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("GET-VENDOR-AVAILABILITY-DAYS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "" NIL)
    ("DELETE-PRODUCT-PRICING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("APPROVE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-cad.lisp" "" "" NIL)
    ("WITH-HHUB-TRANSACTION" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-WALLETS-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("UI-LIST-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("DOD-CONTROLLER-RUN-DAILY-ORDERS-BATCH" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CREATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("ORDERPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("CUSTPAYMENTMETHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp"
     "Render the available payment method widgets dynamically using Bootstrap 5.3 accordion.
Only shows sections based on availability flags and customer type."
     "" NIL)
    ("ADDRESS-ADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("CREATE-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CONTACTUSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTUPDATECART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DETERMINE-DEFAULT-SHIPPING-OPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-BULK-PRODUCT-COUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("CUSTOMER-PROFILE-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATEBUSINESSSESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Creates a business session and returns the newly created session" "" NIL)
    ("COM-HHUB-TRANSACTION-SEND-INVOICE-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DOD-CONTROLLER-PRODUCTS-APPROVAL-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("RESTORE-DELETED-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("ADDLOGINVENDORSETTING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTUPDATECART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("WITH-VENDOR-SIDEBAR" "MACRO"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("UNIVERSAL-TO-UNIX-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("WITH-STANDARD-PAGE-TEMPLATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COUNT-COMPANY-CUSTOMERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-VENDOR-PRODUCT-ADD-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-USER-ROLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-UPDATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("DOD-CONTROLLER-PRD-DETAILS-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "" NIL)
    ("BANKACCNUM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWGSTHSNCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("GETBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch the Business Object from repository." "" NIL)
    ("NL-TO-SQL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("PROCESSRESPONSE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "This function is responsible for converting the business object into a responsemodel "
     "" NIL)
    ("SHARETEXTORURLONCLICK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COLUMN-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("HHUBSENDMAIL-TEST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("OLLAMA-LISP-HELP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("FORMAT-PRICING-FEATURES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTADDORDEROTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("UPDATE-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("GENERATEHASHKEY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("WITH-HHUB-PEP" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ACTOR-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("ACTOR-MAX-QUEUE-SIZE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("CREATE-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("DODELETE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "" NIL)
    ("COM-HHUB-TRANSACTION-EDIT-INVOICE-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SELECT-MATCHING-WAREHOUSES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select warehouses matching partial name" "" NIL)
    ("COPYUPIPAYMENT-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SUSPEND-ACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("GET-LOGIN-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("WITH-BOUNDARY-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Enforces clean architecture by requiring explicit handling of all four 
   TCUF states (T, F, U, C) whenever calling an external/unreliable API 
   or boundary function. The API-CALL must return two values: (PAYLOAD STATUS).
   The result payload is made available to all status clauses under the
   variable name 'payload', and the status is available as 'status'."
     "" NIL)
    ("GET-LOGIN-VENDOR-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-WAREHOUSE" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CGST-AMOUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("SELECT-ALL-INDIA-PINCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-pincodes.lisp" "" "" NIL)
    ("REMOVE-ITEM-FROM-TAX-BREAKDOWN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp"
     "Subtracts an InvoiceItem's values from the breakdown summary." "" NIL)
    ("FOREIGN-KEY-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("COPYVENDOR-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("SELECT-COMPANIES-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SADMIN-CREATE-USERS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GET-ITEM-PRODUCT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VDISPLAY-WEBREPL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COPYORDER-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "" NIL)
    ("STD-CUST-PAYMENT-MODE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("SYNCOBJECTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CGSTAMT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("ORDERITEMSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("OPERATOR-ENTITY-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("MAKE-REQUESTMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Create requestmodel instance for a route from ctx-requestmodel-params."
     "" NIL)
    ("DOD-CONTROLLER-CUST-ORDERSUCCESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-ABAC-SUBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-PASSWORD-RESET-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-INVOICE-PAID-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-DISPLAYCUSTOMERPROILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PROCESSRESPONSELIST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "This function is responsible for converting the business objects into a responsemodel list "
     "" NIL)
    ("DOD-RESET-ORDER-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("TOTALINWORDS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("GENERATE-PRODUCT-EXT-URL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-cad.lisp" "" "" NIL)
    ("PRODUCT-QTY-ADD-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("UPIPAYMENTSSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("CUSTOMERREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("COMP-CESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("WITH-HTML-CUSTOM-CHECKBOX" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("RENDERTILEVIEWHTML" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Renders a list as tiles" "" NIL)
    ("IS-USER-ALREADY-LOGIN?" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTSHOWSHOPCARTREADONLY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SEARCH-GST-HSN-CODES-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("WITH-HTML-DROPDOWN" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-FREE-SHIPPING-METHOD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("EWAY-BILL-ENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("AFTER-DISPATCH-HOOK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("CUSTOMER-PRODUCT-DETAIL-MENU-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "" NIL)
    ("CALCULATE-INVOICE-TOTALIGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" ""
     ((:DESCRIPTION
       . "Calculates total IGST amount for an invoice by summing IGST across all line items")
      (:DOMAIN . :INVOICE) (:CATEGORY . :CALCULATION)
      (:TAGS :TAX :IGST :INVOICE :TOTALS)
      (:INPUTS
       ((:NAME . INVOICEITEMS) (:TYPE . LIST) (:REQUIRED . T)
        (:SOURCE . :PARAMETER)))
      (:OUTPUTS
       ((:NAME . TOTAL-IGST) (:TYPE . DECIMAL) (:BINDS-AS . :IGST-AMOUNT)))
      (:READS :INVOICEITEMS) (:WRITES) (:THROWS) (:PURE) (:COST . :LOW)))
    ("ROLE-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("W-ALT-PHONE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("UOM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("GET-SHIPPED-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("WITH-DB-READ-ONE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "SELECT-one boundary macro for CLSQL via DBAdapterService.db-fetch.

   Calls (db-fetch DBAS ROW-ID), inspects the returned list length,
   and returns a BO-KNOWLEDGE instance."
     "" NIL)
    ("LEGAL-ENTITY-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("DOD-CONTROLLER-NEW-COMPANY-REGISTRATION-EMAIL-SENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("MODAL.GENERATE-SKU-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SEARCHHSNCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-GENERATE-TEMP-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("INVOICEITEMVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("MERGE-PAYLOADS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Merge two payloads intelligently.
   If both are equal, return one.
   If one is NIL, return the other.
   If they differ, return a list of both to mark conflict."
     "" NIL)
    ("CREATE-MODEL-FOR-DUPLICATE-CUSTOMER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("TODAY-LOG-FILE-PATH" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-otp.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-VENDOR-ADDTOCART-USING-BARCODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SEND-ORDER-MAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("DISPLAY-WALLET-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-ALL-INDIA-PINCODES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-pincodes.lisp"
     "Returns a hash table where each pincode is a unique key, 
   ignoring sub-office distinctions."
     "" NIL)
    ("ACTIVEFLAG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("COPYGSTHSNCODES-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "" NIL)
    ("WAREHOUSEHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("GET-OPF-CUSTOMER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "" NIL)
    ("FUNCTION-LOOKUP-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-funloodat.lisp" "" "" NIL)
    ("RESTORE-DELETED-VENDOR-APPOINTMENT-INSTANCES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "" NIL)
    ("WITH-ENTITY-READALL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-INVOICESETTINGSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDORCREATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("MIGRATE-2026MARCH-ADD-CONSTRAINTS-TO-DELIVERY-ITEMS-AND-GOODS-RECEIPT"
     "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "" "" NIL)
    ("NST-LOAD-CORE-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-COMPANY-SEARCH-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MD5-FROM-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Takes a list of strings, joins them with commas, and returns the MD5 digest."
     "" NIL)
    ("GET-SHIP-ZONES-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("MODAL.ACCOUNT-EXTERNAL-URL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("NST-GET-CACHED-EMAIL-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("MEMOIZE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Replace fn-name's global definition with a memoized version." "" NIL)
    ("CALCULATE-INVOICE-TOTALBEFORETAX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("RESTORE-DELETED-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("VPAYMENTMETHODSDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-DELETE-WAREHOUSE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Handler for deleting a warehouse using context flow dispatcher" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTOMERPAYMENTMETHODSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GETLOGINVENDORCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-LOGIN-VENDOR-COMPANY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("GENERATE-ENTITY-TLA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generate a unique 3-letter acronym (TLA) from an entity name like 'order header'."
     "" NIL)
    ("COM-HHUB-POLICY-VENDOR-BULK-PRODUCTS-ADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DOD-RESPONSE-PASSWORDS-DO-NOT-MATCH-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PHONE-MOBILE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-ADDPRDTOINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SELECT-UPI-TRANSACTIONS-BY-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "" NIL)
    ("GSTORGNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-TRANSCUSTEDITORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("CREATE-USER-WITH-ROLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-INVOICE-SETTINGS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("GET-CURRENCY-HTML-SYMBOL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "" NIL)
    ("SELECT-INVOICE-HEADER-BY-INVNUM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "" NIL)
    ("PRDDESC" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTPRODBYCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("VIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("ACTOR-PRIORITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("PROCESS-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("UI-LIST-PROD-CATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("COUNT-ORDER-ITEMS-COMPLETED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("CREATE-UPI-PAYMENT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("MAKE-CALL-CONTEXT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Create a call context with optional request metadata.
   If request metadata is not provided, attempts to get from Hunchentoot or uses defaults."
     "" NIL)
    ("ITEMINLIST-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("VENDORPUSHNOTIFICATIONSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("GETBUSINESSOBJECTREPOSITORY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Get the Business object repository" "" NIL)
    ("SUPERADMIN-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "" NIL)
    ("SELECT-VENDOR-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("CREATE-BUS-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-CURRENCIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("TRIAL-ACCOUNT-DAYS-TO-EXPIRY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("WAREHOUSE-UUID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("APPT-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vas.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-RESET-PASSWORD-ACTION-LINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("HHUB-ADD-PENDING-UPI-TASK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("RESTOREACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ORDERITEMDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("RESTORE-DELETED-DOD-USERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("RESPONSEMODELCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("GET-LOGIN-USER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("DOD-PRD-MASTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("END-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "" NIL)
    ("MIGRATE-2026FEB-MODIFY-CUSTOMER-ORDER-ITEMS-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-orderitem.lisp" ""
     "" NIL)
    ("COM-HHUB-POLICY-DELETE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-UPDATE-FLATRATE-SHIPPING-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("PRODUCT-CARD-SHOPCART-READONLY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("COPYORDER-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-PASSWORD-RESET-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CONTACTUSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("WAREHOUSEVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-PROJECT-SYMBOLS-LOOKUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Model: Prepares the lookup data for the view.
   Now includes the 6th meta-plist slot serialized as JSON."
     "" NIL)
    ("CREATE-WIDGETS-FOR-REMOVESHOPCARTITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("VENDORSESSIONOBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("SHIPPED-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("DISCOUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-ATTRIBUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GET-USER-ROLES.USER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("CALCULATE-ORDER-TOTALIGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "" NIL)
    ("RESTORE-DELETED-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-ROLE-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("BOREPOSITORIES-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("DOD-CONTROLLER-LOGINPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("DB-NOT-FOUND" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Optionally signal from a DB adapter when a required record is
    definitively absent.  Treated as :F in read/update/delete macros."
     "" NIL)
    ("PERSIST-PUSH-NOTIFY-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "" NIL)
    ("CTX-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GET-RESET-PASSWORD-INSTANCE-BY-TOKEN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("SETASSERVICEORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CREATEGSTHSNCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("SET-ORDER-FULFILLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("GET-OPREFLIST-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "" NIL)
    ("CREATE-CASH-ON-DELIVERY-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("SEARCH-PRDCATG-IN-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("CUST-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("WITH-STANDARD-COMPADMIN-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-SYMBOL-DOC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Retrieves the documentation string for symbol S based on its determined TYPE."
     "" NIL)
    ("DOD-ORDER-ITEMS" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("SEND-ORDER-EMAIL-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("HHUB-EXECUTE-NETWORK-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-LOGINPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("W-ADDR2" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CREATE-ABAC-SUBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-SHOW-VENDOR-UPI-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("UPDATE-STOCK-INVENTORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("FILTER-PRODUCTS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("SEND-ORDER-SMS-STANDARD-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWGSTHSNCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWINVOICECONFIRMPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-SHIPPING-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("BO-SAFE-PAYLOAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return payload only when truth is :T; otherwise NIL." "" NIL)
    ("DELETE-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("CUSTOMERRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("LAZY-CAR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("MIGRATE-2026FEB-CREATE-INVOICE-GST-RECONCILIATION-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "Create customer vendor table to track the money transfer from customer to vendor."
     "" NIL)
    ("CREATE-VENDOR-AVAILABILITY-DAY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "" NIL)
    ("GST-HSN-FUNC" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("DOD-GST-SAC-CODES" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-VENDOR-REJECT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-ABOUTUSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("GETFLATRATEPRICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("JSCRIPT-DISPLAYERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WITH-STANDARD-CUSTOMER-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("BANKIFSCCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("INDEX-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("HHUB-METHOD-NOT-FOUND" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("DELETE-DOD-USER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("CREATE-ORDER-FROM-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("PLACEOFSUPPLY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("TENANT-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("DISPLAY-CAPTCHA-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CUSTOMER-PROFILE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CURRENT-DATE-STRING-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in YYYY-MM-DD format" "" NIL)
    ("DOD-VENDOR-TENANTS" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("INVOICEHEADER-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("MYSQL-NOW+DAYS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("NULL-VALUE-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("BUSINESS-OBJECTS-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("NST-SHIPPING-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("DELETE-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("REQUESTPINCODE" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-PUBLISHACCOUNTEXTURL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("APPLY-MIGRATIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("RENDER-FREE-SHIPPING-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("USERS-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "" NIL)
    ("DBOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("PRODUCT-CATEGORY-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("WITH-HTML-FORM-HAVING-SUBMIT-EVENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DELETE-VENDOR-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-COMPADMIN-HOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SADMINLOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("VPAYMENTMETHODS" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("HHUBSTORE" "CLASS"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("MODAL.ACCOUNT-ADMIN-CHANGE-PIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("MIGRATE-2025SEP-ORDERITEM-UPGRADE-SGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CREATEINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("ABAC-SUBJECT-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DESCRIPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-TRANSCUSTEDITORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-READALL-WAREHOUSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("MODAL.ACCOUNT-ADMIN-UPDATE-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("RENDERJSONALL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Renders a list as JSON" "" NIL)
    ("CREATE-MODEL-FOR-VENDADDTOCARTFORINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-DELETE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("USER-ROLES-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-CUSTOMER-MY-ORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ADDRESSVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("W-CITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("REQUIRED-ROLES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GETALLBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch all Business objects from the repository" "" NIL)
    ("GETRESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("SEED-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("FIND-NEAREST-ELEMENTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CREATE-ATTRIBUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GET-DATE-FROM-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("GETFLATRATETYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CADLOGINACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("GET-LOGIN-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("BIRTHDATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("APPROVED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("BO-KNOWN-FALSE-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is known false." "" NIL)
    ("CREATE-WIDGETS-FOR-UPDATEORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("RESPONSEVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("CREATE-ODTINST-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-POLICY-CREATE-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-COPY-INVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-UPDATEINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("GETBUSINESSCONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Searches the business context by name" "" NIL)
    ("DOD-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-CONTACTUS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("PERSIST-PRODUCT-PRICING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("ENFORCEUSERSESSION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("GET-PENDING-ORDER-ITEMS-FOR-VENDOR-BY-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("BO-KNOWLEDGE->BOUNDARY-RESULT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return a boundary-style list like (TRUTH PAYLOAD SOURCE...)." "" NIL)
    ("DOD-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("LEAVE-FLAG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("VALIDATE-GSTIN-FORMAT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Validate GSTIN format (15 chars, specific pattern)" "" NIL)
    ("VENDORS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("GET-LOGIN-USER-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "" NIL)
    ("WMANAGER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-WALLET-DISPLAY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-cuswall.lisp" "" "" NIL)
    ("WEBPUSHNOTIFY" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("WITH-NST-DEBUGGER" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Debugger-centric NST execution boundary.
     - Development  : drop into debugger (full SLIME stack)
     - Staging      : log full stacktrace + re-signal
     - Production   : log sanitized + signal business condition"
     "" NIL)
    ("LAZY-NULL" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWINVOICECONFIRMPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SHIPZIPCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("WITH-VENDOR-NAVIGATION-BAR-V2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-OTP-REGENERATE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("SETASSALESORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("MODAL-DIALOG-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("UI-LIST-VENDOR-ORDERS-BY-CUSTOMERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "" NIL)
    ("ENDPOINT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-SEARCH-CUST-WALLET-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("SEND-MESSAGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("DOD-CONTROLLER-DEL-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("SELECT-ABAC-SUBJECT-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("GETLOGINVENDORSESSIONSTARTTIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("SELECT-MATCHING-HSN-CODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "" NIL)
    ("GET-ROOT-PRD-CATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("SELECT-USER-ROLE-BY-USERID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("CODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-CUSTOMER-ORDER-CUTOFF-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("DOD-GET-CACHED-ORDER-ITEMS-BY-PRODUCT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-VEND-LOGIN-WITH-OTP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("SELECT-AUTH-ATTR-BY-KEY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("WITH-DB-CALL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "" NIL)
    ("WITH-MODAL-DIALOG-LINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-TNC-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("CONDITION-TXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("DOD-USERS" "CLASS"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "" NIL)
    ("PRODUCT-CARD-FOR-APPROVAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("GET-CUST-WALLET-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("EMAIL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("MODAL.VENDOR-UPDATE-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-MY-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PREFPRESENT-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("CUSTOMERPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CUST-EDIT-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-STOREPICKUP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("DOD-INVOICE-HEADER" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("DOREADALL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "" NIL)
    ("DELETEBUSINESSSERVER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-COPY-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("ADDLOGINUSERSETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("PROCESS-SHIPPING-INFORMATION-FOR-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("GET-LOGIN-USER-ROLE-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-FREESHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("DELETE-OPREF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SADMIN-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("INVOICE-EMAIL-OPTIONS-MENU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SELECT-VENDORS-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("MODAL.VENDOR-UPI-PAYMENT-CONFIRM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("RESETVENDORSESSIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("BUSINESSOBJECTUNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CAD-PRODUCT-REJECT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("SGSTAMT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("HHUB-FUNCTION-MEMOIZE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("COPYWAREHOUSE-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Copy warehouse domain object to database object with ownership fields" ""
     NIL)
    ("COM-HHUB-POLICY-SADMIN-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("WEBSITE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("DEFAULT-TRANSPORTER-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("GET-GSTVALUES-FOR-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-ADD-ORDERPREF-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("SELECT-VENDOR-BY-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("TEST-WEBPUSH-NOTIFICATION-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-INVOICE-PAID-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("BILLSAMEASSHIP" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("CREATE-WALLET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTSHOWSHOPCARTREADONLY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CALCULATE-INVOICE-TOTALAFTERTAX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DISPLAY-MY-CUSTOMERS-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("ORDERDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CADPRODUCTAPPROVEACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("HHUB-EXECUTE-BUSINESS-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("RESPONSEMODELUNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SEARCH-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SEARCHORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("PRDCATG-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("GET-LOGIN-CUSTOMER-COMPANY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("RENDER-MULTIPLE-PRODUCT-THUMBNAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("DISPLAY-INVOICE-CONFIRM-PAGE-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-MAXCUSTOMERCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-VENDOR-APPROVE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("ORDER-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("MAKE-UI-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-FLATRATESHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("GSTHSNCODESHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("GET-SHOPCART-VENDORLIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GET-ORDERIDS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("ROLE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-rol.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CREATEINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-DISPLAYORDHEADERFORCUST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-UPDATEINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("START-DAS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("DOD-GEN-VENDOR-PRODUCTS-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-LOGIN-VEND-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DISPLAY-INVOICE-PAYMENT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("VNUM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("PARSE-DATE-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read a date string of the form \"DD/MM/YYYY\" and return the 
corresponding universal time."
     "" NIL)
    ("WITH-NO-NAVBAR-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-WAREHOUSE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Main warehouse management page" "" NIL)
    ("DOD-CONTROLLER-VENDOR-BULK-ADD-PRODUCTS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("FREQUENCY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "" NIL)
    ("GET-PROD-CAT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("GETBUSINESSOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "gets the domain object" "" NIL)
    ("DOD-CONTROLLER-CUST-ORDER-SHIPPING-ADDRESS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GET-AUTH-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("KNOWLEDGE-MEET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Intersection of knowledge (common certainty)." "" NIL)
    ("SUSPEND-FLAG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("SHOW-EMPTY-SHOPPING-CART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTORDERPAYMENTPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("STOP-DAS" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp"
     "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-PRDBULKUPLOAD-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("SUSPENDACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SHOW-INVOICEITEM-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VUPLOADPRDIMAGES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("ODTK-STATUS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "" NIL)
    ("WEBPUSHNOTIFYDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("DOD-CONTROLLER-DBRESET-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWVENDORUPITRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("BO-CONTRADICTORY-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is contradictory." "" NIL)
    ("COM-HHUB-POLICY-VENDOR-ORDER-SETFULFILLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("PRODUCT-CARD-FOR-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("GET-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("UI-LIST-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "" NIL)
    ("SGST-RATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
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
     "" NIL)
    ("CREATE-MODEL-FOR-CUSTOMER&VENDOR-CREATE-OTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ORDER-SHIPPING-RATE-CHECK-ZONEWISE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "" NIL)
    ("SELECT-BUS-TRANS-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("WITH-HTML-SEARCH-FORM" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ACTOR-STATE-CLEAN-CALLBACK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("MODAL.VENDOR-EXTERNAL-SHIPPING-PARTNERS-CONFIG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VPRODSHIPINFOADDACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-AUTH-POLICY" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "" NIL)
    ("USER-UPDATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "" NIL)
    ("REMOVE-INVOICE-ITEM-MARKERS-FROM-TEMPLATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("WALTPHONE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTADDTOCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-UPI-PAYMENTS" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("CTX-DOMAIN-OBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("ODTK-REMARKS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWORDERITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("GET-LOGIN-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("REQUESTDELETEWEBPUSHNOTIFYVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("DOD-CONTROLLER-OTP-SUBMIT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("GET-SYSTEM-UOM-MAP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp"
     "Returns hash table mapping UOM codes to (description gst-uqc).
   Supports both international UOMs and GST-compliant UQC codes.
   
   Usage:
   (gethash \"PCS\" ht) → (\"Piece\" \"NOS\")
   (gethash \"LTR\" ht) → (\"Litres\" \"LTR\")
   
   First element: User-friendly description
   Second element: GST UQC code for GSTR-1 compliance"
     "" NIL)
    ("CREATE-WIDGETS-FOR-PRODUCTCATEGORIESPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("WITH-HTML-DIV-ROW-FLUID" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CADPROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-PRODUCTS-BY-CATEGORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DISPLAY-ORDER-HEADER-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("CMP-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("LASTNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("INVOICEITEMSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("RESTORE-DELETED-DOD-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("WITH-STANDARD-PAGE-TEMPLATE-V3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("LOGO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("GET-ORDERS-BY-REQ-DATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("EDITINVOICEWIDGET-SECTION4" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SELECT-AUTH-POLICY-ATTR-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("CREATE-DAILY-ORDERS-FOR-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-LOGINPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("VPAYMENTMETHODSRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("RENDER-COMPADMIN-SIDEBAR-OFFCANVAS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("PARAMS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("WITH-HTML-ACCORDION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GENERATE-WAREHOUSE-UUID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Generate UUID for warehouse" "" NIL)
    ("SELECT-PRDCATG-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("SELECT-WAREHOUSE-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select warehouse by row-id" "" NIL)
    ("GET-BUS-TRAN-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("GET-PRODUCTS-FOR-APPROVAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("PERSIST-WALLET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("GETWEBPUSHNOTIFYVENDORPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("DELETE-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("DOSERVICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Do Service implementation for a Business Service. Takes in the BusinessSession and input params and returns back output params and exceptions if any."
     "" NIL)
    ("USERSESSIONOBJECT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("ORDERITEMVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("RENDER-TAX-SUMMARY-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp"
     "Generates the HTML table for the GST breakdown with a Grand Total row."
     "" NIL)
    ("BUSINESSSESSION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("DISPATCH-ROUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Dispatch a route with optional request metadata for ABAC/auditing.
   
   Parameters:
     route-key       - Route identifier (e.g., :warehouse/create)
     raw-params      - Request model parameters
     trans-func-name - Transaction function name for auditing
     output-type     - Output format (json, html, etc.)
     request-uri     - Optional request URI (auto-detected from Hunchentoot if nil)"
     "" NIL)
    ("HHUB-CONTROLLER-UPI-RECHARGE-WALLET-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SHOW-INVOICE-CONFIRM-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-COMPADMINHOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("TRANSFERKNOWLEDGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Transfer BO knowledge from one adapter-layer object to another." "" NIL)
    ("GET-MAX-OPREF-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "" NIL)
    ("HHUB-INIT-BUSINESS-FUNCTION-REGISTRATIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("SELECT-PRODUCTS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("%GET-BREAKDOWN-KEY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "" NIL)
    ("END-TIME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("MAKE-UI-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "Create a component.
NAME is a keyword identifier.
RENDERER-FN is a function that takes MODELFUNC and returns a list of widgets."
     "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-OTPLOGINPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-EXTERNALSHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-ACTIVATE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("PRINT-VENDOR-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DELETEBUSINESSCONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Deletes a business context" "" NIL)
    ("SELECT-VENDORS-FOR-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("DELETE-PRDCATGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("HHUB-UNKNOWN" "CLASS" "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Base condition for logical database results (non-fatal)." "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("LINK-BUS-TRANSACTION-TO-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DOD-CONTROLLER-TRANS-TO-POLICY-LINK-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CUSTOMER-SUBSCRIPTIONS-HEADER-TOP-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "" NIL)
    ("SEARCH-IN-HASHTABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DOD-CONTROLLER-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("ERROR-MESSAGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("GET-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("SET-USER-SESSION-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-VENDOR-BULK-PRODUCTS-ADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-CODORDERS-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("UPDATE-USER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("PERSIST-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-OTPSUBMITACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("MIGRATE-2026MARCH-CREATE-GOODS-RECEIPT-NOTE-ITEMS-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "" "" NIL)
    ("TABLE-EXISTS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CUSTOMER&VENDOR-CREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("FILTER-ORDER-ITEMS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("VPAYMENTMETHODSVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("EXPECTED-DELIVERY-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("SELECT-COMPANY-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("GET-VENDOR-ORDER-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CAD-LOGIN-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("RESET-USER-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CAD-PRODUCT-APPROVE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("GET-OPREF-VENDORLIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("WITH-CUSTOMER-BREADCRUMB" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GENERATEUPIURLSFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("USER-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "" NIL)
    ("VENDORDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-UPDATEGSTHSNCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("SUBMITFORMEVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-TOTAL-OF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("SELECT-VENDOR-BY-PHONE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp"
     "Load Vendor from Database given the phone number" "" NIL)
    ("CREATE-DOMAIN-ENTITY-FROM-TEMPLATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generates domain code for UI, BL, and DAL by replacing placeholders in templates."
     "" NIL)
    ("DISPLAY-PRODUCT-CARDS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("RENDER-SIDEBAR-OFFCANVAS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("UPDATE-CONFIG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/templates/invoicesettings.lisp"
     "Update a specific KEY in SECTION of config*invoice-settings* to NEW-VALUE."
     "" NIL)
    ("GETREQUESTMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CUSTOMERADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("REFRESHIAMSETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "" NIL)
    ("REQUESTVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("ORD-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-LOWWALLETBALANCEFORORDERITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PRESENTERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("UNIX-TO-UNIVERSAL-TIME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-READALL-WAREHOUSE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Handler for reading all warehouses using context flow dispatcher" "" NIL)
    ("GET-VENDOR-APPOINTMENTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "" NIL)
    ("SAVE-VENDOR-ORDERS-IN-DB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("MODAL.CUSTOMER-CHANGE-PIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("VPAYMENTMETHODSREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("MAX-ITEM" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("DOD-CONTROLLER-VEND-LOGIN-WITH-OTP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("UPDATE-VENDOR-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("SAFE-NL-TO-SQL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("NST-API-TIMEOUT-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("DISPLAY-SAVED-ADDRESSES-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-ADDCUSTTOINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("ORDERHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("GET-VENDORS-BY-ORDERID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("MAKE-OTP-STORE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-otp.lisp" "" "" NIL)
    ("TEST-COUNTER-ACTOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp"
     "Test the lifecycle and behavior of the counter actor using standard assert."
     "" NIL)
    ("DOD-CONTROLLER-VEND-ADD-TENANT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-VENDOR-UPLOAD-PRODUCT-IMAGES-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-GET-CACHED-ORDER-ITEMS-BY-ORDER-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-ORDER-ITEMS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("CUSTOMERS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWWAREHOUSES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Create model for showing all warehouses" "" NIL)
    ("COM-HHUB-POLICY-RESTORE-ACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("KNOWLEDGE-JOIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Combines knowledge states from two sources (union of knowledge)." "" NIL)
    ("DISPLAY-PRDCATG-CAROUSEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CUSTOMER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("MY-AND" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "" NIL)
    ("IGST-AMOUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("UPDATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("DOD-GST-HSN-CODES" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("DOD-CONTROLLER-LIST-ORDER-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("WCITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("SELECT-PRODUCT-PRICING-BY-STARTDATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("SELECT-CUSTOMERS-FOR-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("SELECT-WAREHOUSES-BY-OWNERSHIP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select warehouses by ownership criteria" "" NIL)
    ("MIGRATE-2026FEB-UPDATE-INVOICE-HEADER-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "" "" NIL)
    ("PERSIST-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("ORDER-TRACK-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "" NIL)
    ("UNIT-OF-MEASURE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SEARCHINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("VENDOR-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("MODAL.VENDOR-MY-CUSTOMER-WALLET-RECHARGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-PRODUCTS-CSV" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("MODAL.VENDOR-UPDATE-UPI-PAYMENT-SETTINGS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("TAKE-ALL" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COPY-DBOBJECT-TO-BUSINESSOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Syncs the DBobject to BusinessObject" "" NIL)
    ("DOD-CONTROLLER-VENDOR-PASSWORD-RESET-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("TAGS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("UI-LIST-YES-NO-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("GETPINCODEDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("PERSIST-VENDOR-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("SELECT-ALL-INVOICE-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "" NIL)
    ("ACTIVE-FLG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("RESPONSEHASHCHECK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("GET-ABAC-SUBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("GET-STATE-NAME-FROM-CODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("EXTERNAL-INVENTORY-CHECK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Mocks an inventory microservice call. Must return payload and status." ""
     NIL)
    ("GET-SHIPPING-METHOD-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("PROCESSREADALLREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Read method" "" NIL)
    ("GET-VENDOR-APPOINTMENT-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "" NIL)
    ("HHUB-BUSINESS-FUNCTION-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("HHUB-EXECUTE-PENDING-UPI-TASK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("BO-MERGE-PROVENANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return merged provenance list (deduped)" "" NIL)
    ("GET-ORDER-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("ACTOR-CONDITION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("DOD-CONTROLLER-PASSWORD-RESET-MAIL-SENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-OPF-PRODUCT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "" NIL)
    ("GET-ABAC-SUBJECT-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("NST-GET-CACHED-CUSTOMER-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTPRODBYCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWVENDORPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("INVOICEHEADERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("VENDOR-DETAILS-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("WITH-GUESTUSER-NAVIGATION-BAR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("STATUS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-1" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("COMPANY-EMPLOYEES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("UPDATE-KYC-STATUS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Update KYC status for a customer" "" NIL)
    ("FIND-CUSTOMER-BY-GSTIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Find customer by GSTIN" "" NIL)
    ("INIT-GST-INVOICE-TERMS" "FUNCTION" "dod-bl-sys.lisp" "" "" NIL)
    ("CTX-CONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GET-BUS-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("PRODUCT-CARD-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("DOD-VENDOR-APPOINTMENT" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vas.lisp" "" "" NIL)
    ("ATTR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" ""
     "" NIL)
    ("DOD-CONTROLLER-LIST-BUSTRANS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("BROWSER-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-SHOW-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COPYWAREHOUSE-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Copy database object to warehouse domain object with ownership fields" ""
     NIL)
    ("HHUB-CONTROLLER-GET-VENDOR-PUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "" NIL)
    ("LIST-CUSTOMER-LOW-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTOMERINDEXPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-VENDADDTOCARTUSINGBARCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("VENDORVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-COMPANY-SEARCH-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COM-HHUB-BUSINESSFUNCTION-DB-GETPUSHNOTIFYSUBSCRIPTIONFORVENDOR"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp"
     "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("DOD-COMPANY" "CLASS"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("DB-FETCH-ALL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch records by company" "" NIL)
    ("PRODUCT-SUBSCRIBE-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DISPLAY-CUST-SHIPPING-COSTS-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("SESSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CRUD-OP" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("WITH-DB-DELETE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "SOFT-DELETE boundary macro for CLSQL via DBAdapterService.db-delete.

   db-delete (inherited from DBAdapterService) sets DELETED_STATE to
   'Y' on the dbobject and calls clsql:update-record-from-slot.
   No hard DELETE is ever issued against the database.

   Caller responsibilities BEFORE this macro:
     1. (setcompany dbas company)   ; set tenant context
     2. Ensure dbobject is loaded   ; db-delete needs a populated dbobject

   PRE-FLIGHT (strongly recommended) — a CLSQL SELECT expression that
   returns a list of LIVE rows (DELETED_STATE = 'N') matching the delete
   target.  Drives :F and :C detection.

   ALLOW-IDEMPOTENT (default NIL) — when T, a pre-flight returning 0
   live rows is promoted to :T with payload :already-absent.  Use for
   cleanup jobs and token-expiry flows where you only assert 'this
   record must not be live', not 'I must be the one who deleted it'.

   Returns a BO-KNOWLEDGE instance.  Use WITH-BO-KNOWLEDGE-CHECK to
   branch on the result.  BODY is unused and reserved for future use."
     "" NIL)
    ("W-ADDR1" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-DEACTIVATE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-VENDOR-APPROVE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("BUSINESSOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CREATEWHATSAPPLINKWITHMESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("WITH-VEND-SESSION-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("GET-ZONENAME-FROM-PINCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("RESTORE-DELETED-CUST-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-ADD-CUSTOMER-TO-INVOICE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VEND-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GETEXCEPTIONSTR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("SHIPCITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SADMIN-HOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("SEND-TEST-EMAIL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("COM-HHUB-BUSINESS-FUNCTION-DB-GETPUSHNOTIFYSUBSCRIPTIONFORVENDOR"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp"
     "" "" NIL)
    ("ACTOR-THREAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-ORDER-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("WITH-DB-CREATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "INSERT boundary macro for CLSQL via DBAdapterService.db-save.

   Returns a BO-KNOWLEDGE instance.  Status-clauses (:T ...) (:F ...) 
   (:U ...) (:C ...) are optional; if omitted the bo-knowledge is 
   returned and you can branch with WITH-BO-KNOWLEDGE-CHECK."
     "" NIL)
    ("DISPLAY-VENDOR-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-VENDORPROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("ADD-ITEM-TO-TAX-BREAKDOWN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp"
     "Processes an InvoiceItem and aggregates it into the breakdown summary."
     "" NIL)
    ("UPIPAYMENTSREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("MEMO" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Return a memo-function of fn." "" NIL)
    ("WALLET-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DELETE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("DOD-CONTROLLER-LIST-BUSOBJS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-GST-HSN-CODES-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("FIND-INVOICE-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "" NIL)
    ("GET-DATE-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in DD/MM/YYYY format." "" NIL)
    ("ACTOR-LOCK" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SEARCHPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-PRDDETAILSFORCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "" NIL)
    ("GENERATE-DESCRIPTIVE-FILENAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DOD-CONTROLLER-DELETE-PRODUCT-CATEGORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SENDINVOICEEMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SEARCH-ODT-BY-PRD-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SEARCH-ORDER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-DISPLAYORDERHEADERFORCUST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-CURRENCY-FONTAWESOME-SYMBOLS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTPRODBYVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("EXTERNAL-URL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("VENDORADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("CUST-PROFILE-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("MODAL.COM-HHUB-TRANSACTION-SADMIN-CREATE-USERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "" NIL)
    ("CALCULATE-ORDER-TOTALSGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWWAREHOUSES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Create widgets for warehouse page" "" NIL)
    ("UI-LIST-POLICIES-FOR-LINKING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-VENDOR-PROD-SHIP-INFOADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("SELECT-CUSTOMER-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("CREATE-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("CUSTNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("IS-PRIMARY-LOCATION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("AUTH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("SAC-CODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("AVERAGE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("CTX-RESPONSEMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GET-SYSTEM-ROLES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("UTRNUM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("DELETE-VENDOR-APPOINTMENT-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "" NIL)
    ("RENDERLIST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-UPDATE-EXTERNAL-SHIPPING-PARTNER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CREATEORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("PRODUCTS-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("INVOICEITEMHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-EDITINVOICEHEADERPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DOD-CUST-LOGIN-WITH-OTP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-PRODUCT-PRICING-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("INIT-SHIPPING-ZONES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "" NIL)
    ("SUBMITFILEUPLOADEVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("VENDOR-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-LOWWALLETBALANCEFORORDERITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CHECK-ALL-VENDORS-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("SELECT-UPI-TRANSACTION-BY-UTRNUM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "" NIL)
    ("GET-CUST-WALLETS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SEARCHHSNCODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("CHECK&ENCRYPT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-GENERICREDIRECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDUPDATEPGSETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-SORTED-TAX-SUMMARY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp"
     "Returns the tax entries as a list sorted by HSN code." "" NIL)
    ("GENERATE-INVOICE-ITEMS-ROWS-PUBLIC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp"
     "Extracts the row sub-template and repeats it for every item." "" NIL)
    ("HSN-CODE-4DIGIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("CREATEALLVIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Converts the ResponseModel to ViewModel" "" NIL)
    ("WITH-MVC-BINARY-FILE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-ORDER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-dal-pay.lisp" "" "" NIL)
    ("NST-GENERIC-LOGIN-WITH-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CREATEGSTHSNCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-LOWWALLETBALANCEFORSHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GENERATEQRCODEFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("DESTROY-ACTOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-DISPLAYORDERHEADERFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("ADD-ROOT-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("SELECT-BUS-TRANS-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("GSTHSNCODESADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-ADD-PRODUCT-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-DUPLICATE-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GET-ALL-VENDOR-ORDERS-BY-ORDERID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("PERSIST-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SADMINHOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SHOW-INVOICES-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("ACCORDION-EXAMPLE1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PAISE-TO-RUPEES-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("RESTORE-DELETED-AUTH-POLICY-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-UPDATE-ORDERITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("SELECT-AUTH-POLICY-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("GET-OPREF-ITEMS-TOTAL-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PERSIST-PAYMENT-TRANS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-bl-pay.lisp" "" "" NIL)
    ("GSTHSNCODESREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("NEW-DOD-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("LOGIAMHERE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-UPDATEGSTHSNCODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("ORDERTEMPLATEFILL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATEINVOICEITEMOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-SAVE-VENDOR-PUSH-SUBSCRIPTION-OLD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "" NIL)
    ("MIGRATE-2026FEB-CREATE-GST-RECONCILIATION-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "Create customer vendor table to track the money transfer from customer to vendor."
     "" NIL)
    ("GET-B2C-CUSTOMERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Get all B2C customers (no GSTIN or INDIVIDUAL type)" "" NIL)
    ("NORMALIZE-BILLING-ADDRESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("SEARCH-ITEM-IN-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("DOD-CONTROLLER-DELETE-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("OPERATOR-ENTITY-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CALCULATE-ORDER-ITEM-COST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("PRINT-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DEDUCT-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTWALLETDISPLAY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-cuswall.lisp" "" "" NIL)
    ("VPAYMENTMETHODSSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("DOD-ORDER" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("VENDORAPPROVALADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("DISPLAY-AS-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWCUSTOMERUPIPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("PERSIST-ORDERPREF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "" NIL)
    ("CALL-CONTEXT-UPDATE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("LAZY-MAPCAN" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "" NIL)
    ("DB-FETCH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Fetch the DBObject by row-id" "" NIL)
    ("RENDER-INVOICE-SETTINGS-MENU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("WITH-STANDARD-CUSTOMER-PAGE-V3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DOD-CONTROLLER-COMPANY-SEARCH-FOR-SYS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("EMAIL-ADD-VERIFIED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWVENDORPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CGST-RATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("SEND-PASSWORD-RESET-LINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("ACTOR-BEHAVIOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-VENDOR-DISPLAY-WEBREPL-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COPY-HASH-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("RENDER-SINGLE-PRODUCT-IMAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-ORDER-DATA-JSON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-UPDATEORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("ADAPTERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("INIT-HHUBPLATFORM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("VENDOR-CARD-FOR-APPROVAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-INVOICEPAIDACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-POLICY-CREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GET-VENDOR-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-OPREFLIST-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "" NIL)
    ("MODAL.HHUB-COOKIE-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("DISPLAY-ORDDATEREQDATE-TEXT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDSHIPPINGMETHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("WAREHOUSE-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Generate warehouse search HTML" "" NIL)
    ("PRODUCT-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("INVDATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("PRODUCT-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "" NIL)
    ("MODAL.VENDOR-CHANGE-PIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTSHOWSHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DECRYPT" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("SELECT-PRODUCT-PRICING-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("CUSTOMER-PRODUCT-DETAIL-CONTENT-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SADMINHOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("SAFE-READ-FROM-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Attempts to read a Lisp expression from a string, returning a default value if parsing fails."
     "" NIL)
    ("DOD-AUTH-POLICY-ATTR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SEARCHCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("LAZY-NTH" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTADDORDERSUBS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("MODAL.VENDOR-PRODUCT-ACCEPT-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("SESSIONINVOICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("WEMAIL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("GET-LOGIN-CUST-TENANT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("GET-CURRENCY-HTML-SYMBOL-MAP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "" NIL)
    ("UPDATE-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("CREATE-ORDER-FROM-PREF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("GET-SYSTEM-AUTH-POLICIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-ORDERITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("CUSTOMERADDRESSJSONVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("COPYVENDOR-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("SELECT-PRIMARY-WAREHOUSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select primary warehouse location" "" NIL)
    ("FIND-OUTBOUND-ROUTE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-UPI-CUSTOMER-ORDER-PAYMENT-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("SHIPSTATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("PROCESSREADREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Read method" "" NIL)
    ("COPYINVOICEITEM-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-VENDOR-BULK-PRODUCT-ADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("UPDATE-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("HHUB-REGISTER-BUSINESS-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("ASYNC-UPLOAD-FILES-S3BUCKET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-VENDOR-TENANTS-AS-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("APPROVED-FLAG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("CODENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SEARCHPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GSTHSNCODESSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-PRDDETAILSFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-PRODCATG-ADD-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("DOD-PASSWORD-RESET" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "" NIL)
    ("LATITUDE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("FIND-PINCODE-DETAILS-FROM-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-pincodes.lisp" "" "" NIL)
    ("GETRATETABLECSV" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("DOD-SHIPPING-METHODS" "CLASS"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "" NIL)
    ("TAXABLE-VALUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("SELECT-CUSTOMER-BY-PHONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CREATE-GST-HSN-CODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("MODAL.CUSTOMER-UPDATE-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-TRANSACTIONS-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("VENDORCONFIRM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("DISPLAY-TERMS-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-INVOICE-ITEMS" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("USERS-MANAGER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "" NIL)
    ("SELECT-PRODUCT-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("TEXT-EDITOR-CONTROL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-VENDOR-TENANTS-LIST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("HANDLE-ADD-TO-CART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "The application service layer function that orchestrates the boundary check."
     "" NIL)
    ("WITH-NST-ERROR-HANDLER" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("DISPLAY-CSV-AS-HTML-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DOD-CONTROLLER-GUEST-CUSTOMER-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PAYPROVIDERSENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("INIT-HTTPSERVER-WITHSSL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("SELECT-WAREHOUSE-BY-UUID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select warehouse by UUID" "" NIL)
    ("EXTRACT-STATE-CODE-FROM-GSTIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Extract state code from GSTIN (first 2 characters)" "" NIL)
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
     "" NIL)
    ("CREATE-WIDGETS-FOR-DISPLAYORDERHEADERFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("HHUB-DATABASE-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Base condition for logical database results (non-fatal)." "" NIL)
    ("COM-HHUB-TRANSACTION-SHOW-ORDERITEMS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("SELECT-PAYMENT-TRANS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-bl-pay.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CREATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("PRODUCT-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("GET-WEB-SESSION-TIMEOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-CONTACTUS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("CTX-VIEW" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("DISPLAY-ORDER-ITEM-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp"
     "Generates a single item row using Bootstrap 5.3 grid divs." "" NIL)
    ("GET-USERS-FOR-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("DOD-GEN-ORDER-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("STATE-CODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("OLLAMA-GENERATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("CUSTOMER-REGISTRATION-HTML-CONTENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-PUSHSUBSCRIBE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("RENDER-MULTIPLE-PRODUCT-IMAGES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("WNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-COMPANY-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("CUSTOMER-PRODUCT-DETAIL-PAGE-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-PUBLISH-ACCOUNT-EXTURL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CUST-OPF-AS-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "" NIL)
    ("EXAMPLE-USAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "" NIL)
    ("VENDORWEBPUSHNOTIFYSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("DOD-CONTROLLER-NEW-COMPANY-REQUEST-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-SHIPZONE-RATETABLE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTDELETEORDERSUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COPYINVOICEHEADER-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-VBULKADDPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWINVOICEPAYMENTPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("MYSQL-NOW" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("GET-LOGIN-USERID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-APPROVAL-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("CREATE-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("HHUB-REMOVE-CUSTOMER-PUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "" NIL)
    ("SEND-ORDER-EMAIL-STANDARD-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("RUN-DAILY-ORDERS-BATCH" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("HHUB-ABAC-TRANSACTION-ERROR" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("SEND-SMS-NOTIFICATION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-OTPLOGINPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DELETE-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTORDERPAYMENTPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("UPDATE-VENDOR-APPOINTMENT-INSTANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "" NIL)
    ("IS-DOD-CUST-SESSION-VALID?" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GET-SHIPZIPCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("BUSINESSSESSIONS-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CURRENT-PRICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("CALCULATE-ORDER-TOTALGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "" NIL)
    ("RESTORE-DELETED-PRDCATGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("MY-OR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Implements the logical OR operator for FDE logic.
   (Based on the join operation of the Truth lattice.)"
     "" NIL)
    ("ACTOR-ROLE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("WITH-COMPADMIN-BREADCRUMB" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HTMLDATA" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("GET-UNIVERSAL-TIME-FROM-DATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CREATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("SEND-REGISTRATION-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("SGST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("ORDERITEMRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("GET-LOGIN-CUSTOMER-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("CREATEWAREHOUSEOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Create a warehouse domain object with ownership fields" "" NIL)
    ("CREATE-DOD-USER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-DUPLICATE-CUSTOMER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("SELECT-CUSTOMER-FOR-VENDOR-BY-PHONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-UPDATE-CART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("INVNUM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("DELETE-INVOICEITEM-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-DELETE-WAREHOUSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("MODAL.VENDOR-DEFAULT-SHIPPING-METHOD-CONFIG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CTX-ADAPTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("DOD-CUST-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("BUSINESSOBJECTREPOSITORY" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("DELETE-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("DOD-WEBPUSH-NOTIFY" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("GET-SYSTEM-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("RESET-CUSTOMER-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SEARCH-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("DELETE-AUTH-POLICIE-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("REQUESTMODEL-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SEARCH-WAREHOUSE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Search warehouse action handler" "" NIL)
    ("CREATED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("ADD-NEW-NODE-PRDCATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("TEST-VENDOR-APPROVAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("GET-ORDER-BY-SHIPPED-DATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("DOD-CUST-WALLET" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("SELECT-UPI-TRANSACTIONS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "" NIL)
    ("MIGRATE-2026FEB-CREATE-VENDOR-GSTR1-STATUS-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "Create vendor gstr1 status table for a customer to verify whether the vendor has filed gstr1."
     "" NIL)
    ("LONGITUDE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("IGST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("CTX-ROUTE-KEY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("UPDATE-AUTH-POLICY-ATTR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-PRDDETAILSFORCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-PRDDETAILSFORGUESTCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-VENDOR-ADDTOCART-FOR-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("VPRODUCT-QTY-ADD-FOR-INVOICE-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("RESET-PASSWORD-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pas.lisp" "" "" NIL)
    ("UPDATE-CUST-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("UPDATE-CUSTOMER-METRICS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Update customer's order metrics after a new order" "" NIL)
    ("CREATE-PREPAID-WALLET-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SEARCHCUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("PROCESSCREATEREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Create method" "" NIL)
    ("GETVIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("GENERATE-BRANCH-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Generate a validated Git branch name: scope/type/id-desc." "" NIL)
    ("HHUB-GET-CACHED-GST-SAC-CODES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("DOD-VENDOR-ORDERS" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("SELECT-HSN-CODE-BY-CODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "" NIL)
    ("GET-ORDER-BY-CONTEXT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-CUSTOMER-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("SHOPPING-CART-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DELETE-RESET-PASSWORD-INSTANCES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CAD-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("DISPLAY-ORDER-HEADER-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("WITH-HTML-PANEL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("ATTRIBUTE-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("GETBUSINESSSERVICE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("GET-VENDOR-INVOICE-SETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("INVOICEHEADERREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("UPDATE-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("CLEAR-MEMOIZE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Clear the hash table from a memo function." "" NIL)
    ("CURRENT-YEAR-STRING++" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current year as a string in YYYY format" "" NIL)
    ("GET-ALL-GST-UQC-CODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp"
     "Get list of pure GST UQC codes only (not aliases)." "" NIL)
    ("HHUB-CONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Raised when multiple inconsistent results were found." "" NIL)
    ("CREATEMODELFORVENDORADDNEWPRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATED-BY-USER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("CURRENCY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-VEND-PRD-SHIPINFO-ADD-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-DISPLAYINVOICEPUBLIC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-ATTRIBUTE-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("INVOICEHEADERRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("DISPLAY-CUSTOMER-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("GET-SHIPPING-RATE-FROM-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("CREATEGSTHSNCODESOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-8" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GSTIN-STATUS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("GET-ORDER-ITEMS-FOR-VENDOR-BY-ORDER-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("UI-LIST-CMP-FOR-VEND-TENANT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SEARCHWAREHOUSES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Create widgets for search results" "" NIL)
    ("ZIPCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-MAXPRODUCTCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("SELECT-WAREHOUSE-BY-GSTIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select warehouse by GSTIN" "" NIL)
    ("GET-SORTED-SUMMARY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-itm.lisp" "" "" NIL)
    ("GET-LOGIN-VEND-TENANT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTOMERPAYMENTMETHODSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("WAREHOUSEPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("WELCOMEMESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WITH-STANDARD-PAGE-TEMPLATE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-UPI-RECHARGE-WALLET-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("TAKE" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" ""
     NIL)
    ("SET-VENDOR-SESSION-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("WITH-STANDARD-PAGE-TEMPLATE-WITH-SIDEBAR" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-SUBSCRIPTION-PLAN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-VENDOR-UPI-CONFIRM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("RENDER-PRODUCTS-LIST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-CHANGE-PIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("IGSTAMT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("CUSTOMER-SUBSCRIPTIONS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "" NIL)
    ("PINCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/dod-sto-zip.lisp" "" "" NIL)
    ("MODAL.CUST-DELETE-ORDER-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("SELECT-PRODUCT-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("MIGRATE-2025MAY-ADD-DISCOUNT-COLUMN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("DOD-CONTROLLER-REMOVE-SHOPCART-ITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ADDRESSSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-TEXT-READONLY" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SEARCHORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTSHIPMETHODSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("MIGRATE-2025JUN-DOD-ORDER-SCHEMA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-BUS-OBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("GET-BUS-OBJ-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("CATG-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("GET-TENANT-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SYSTEM-DASHBOARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("PHONE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("CUST-INFORMATION-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("BUSINESSCONTEXTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("JSONVIEW" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" ""
     "" NIL)
    ("COUNT-VENDOR-ORDERS-COMPLETED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("FIRSTNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("GET-PRODUCTS-FOR-APPROVAL-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("INVOICEITEM" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("ACTOR-STATEFUL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("MIGRATE-2026MARCH-MODIFY-VENDOR-ORDER-TABLE" "FUNCTION"
     "nst-dbu-orderitem.lisp" "" "" NIL)
    ("DELETE-VENDOR-AVAILABILITY-DAY-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "" NIL)
    ("GET-CURRENCY-FONTAWESOME-SYMBOL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-PAYMENT-METHODS-UPDATE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("ENTRIES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("METADATA" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("TNC" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("WPIN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-ISSUSPENDED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("COLUMN-TYPE-EQUALS-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("GET-GST-UQC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp"
     "Get GST-compliant UQC code for any UOM code." "" NIL)
    ("CREATE-WIDGETS-FOR-LOWWALLETBALANCEFORSHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CUST-PROFILE-KYC-VERIFIER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("SELECT-ROLE-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CMPSEARCH-FOR-VEND-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-GST-HSN-CODES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("KILL-THREADS-BY-PREFIX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Kills all threads whose names start with PREFIX." "" NIL)
    ("WHATSAPP-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("SEND-ORDER-EMAIL-BEHAVIOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/email/templates/registration.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-VENDOR-ORDER-SETFULFILLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-VIEWMODEL-FROM-RESPONSE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Polymorphic viewmodel creation - only for READ operations" "" NIL)
    ("CUST-PROFILE-USERS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("GET-SYSTEM-ABAC-ATTRIBUTES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("DELETE-BUS-TRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CREATE-CUST-WALLET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("NORMALIZE-MD5-FIELDS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp"
     "Normalize and format all product fields to consistent strings for MD5 calculation."
     "" NIL)
    ("CREATE-WIDGETS-FOR-DISPLAYINVOICEEMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("GET-ORDERS-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("VIEW-CLASSES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("ACTOR-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("GET-PROJECT-PACKAGES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Returns a list containing the single main package for the :NSTORES system, 
   based on the packages.lisp file."
     "" NIL)
    ("DOD-CONTROLLER-VENDOR-ORDER-CANCEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CUSTOMERVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("DOD-CONTROLLER-PRD-DETAILS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("WITH-DB-CALL-LIST" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Execute DB-FORM expecting a list result and return a BO-KNOWLEDGE instance.

   DB-FORM    — any CLSQL SELECT expression that returns a flat list.
   SOURCE     — provenance string for the bo-knowledge instance.
   PK-EXTRACTOR — optional one-arg function (lambda (row) ...) that
                  returns the primary-key value for each row.  When
                  supplied, the result list is scanned for duplicate
                  PKs; any duplicate promotes truth to :C.

   TCUF semantics:
     :T — non-empty list returned with no duplicate PKs
     :F — nil or empty list (no matching records exist)
     :C — duplicate PKs detected in result list
     :U — any error during execution of DB-FORM"
     "" NIL)
    ("CONVERT-NUMBER-TO-WORDS-INR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("WSTATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CUST-PROFILE-ORDERS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("MIGRATE-2026MARCH-CREATE-DELIVERY-ITEMS-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "" "" NIL)
    ("VPAYMENTMETHODSPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("TRANSMODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("REMOVE-WEBPUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "" NIL)
    ("MAKE-UI-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("SELECT-AUTH-ATTRS-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("WAREHOUSEADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("UPDATE-SHIPPING-METHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("GET-VENDOR-ORDERS-BY-ORDERID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("EXCEPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CALCULATE-ORDER-TOTALCGST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-UPDATEORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("SELECT-USER-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("CUSTOMERDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-UPDATE-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-ISSUSPENDED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SHOW-INVOICE-CONFIRM-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SELECT-ALLVPAYMENT-METHODS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vpm.lisp" "" "" NIL)
    ("QTY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("START-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "" NIL)
    ("CALL-CONTEXT-DELETE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("ADDRESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("INVOICEITEMDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("ENSURE-NOT-NULL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("MIGRATE-2026FEB-CREATE-BUYER-VENDOR-ACCOUNT-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "Create customer vendor table to track the money transfer from customer to vendor."
     "" NIL)
    ("CUSTOMER-PRODUCT-DETAIL-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "" NIL)
    ("GET-PRODUCT-QTY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SHOW-ORDER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("USER-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "" NIL)
    ("JSONDATA" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("START-ACTOR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("GET-SYSTEM-BUS-OBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("MIGRATE-2026FEB-MODIFY-CUSTOMER-ORDER-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-orderitem.lisp" ""
     "" NIL)
    ("CREATE-MODEL-FOR-PRODUCTCATEGORIESPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("CUSTADDR" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("HHUB-REGISTER-NETWORK-FUNCTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SUSPEND-ACCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-DISPLAY-STORE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("ADDL-TAX1-RATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("PAYMENT-GATEWAY-MODE-OPTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("NST-GET-CACHED-CORE-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("WRITE-YAML-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Write a Lisp data structure to a YAML file." "" NIL)
    ("WITH-HTML-DIV-COL-4" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-ORDERITEM-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CUSTWALLETDISPLAY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-cuswall.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-UPDATE-GST-HSN-CODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("SELECT-CUSTOMER-BY-EMAIL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("GET-LATEST-ORDER-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("MODAL.VENDOR-FORGOT-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("DOD-USER-ROLES" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp" "" "" NIL)
    ("VENDOR-PRODUCT-ACTIONS-MENU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-SHOW-SHOPCART-READONLY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CUSTOMERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("SAVE-TEMP-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ORDERITEMPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("SUBMITSEARCHFORM2EVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("W-PIN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("ADDLOGINVENDORSETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("VENDOR-ORDER-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "" NIL)
    ("CUSTID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("SAVE-ORDER-ITEMS-IN-DB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("VIEWMODELUNKNOWN" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("RESTORE-DELETED-ORDER-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("COMPANY-UPDATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("COUNTER-BEHAVIOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("INITBUSINESSSERVICES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Initialise the Business Services" "" NIL)
    ("CREATECIPHERSALT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("WAREHOUSEDBSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("BOUNDARY-RESULT->BO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Wrapper around bo-knowledge-from-boundary that normalizes payload provenance if payload is itself a bo-knowledge or plist."
     "" NIL)
    ("MODAL.PRODUCT-CATEGORY-ADD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("COPYUPIPAYMENT-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-PRODUCT-CATEGORIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CURRENT-YEAR-STRING--" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current year as a string in YYYY format" "" NIL)
    ("GET-OPF-PRD-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-dal-opf.lisp" "" "" NIL)
    ("SELECT-VENDOR-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("BO-MERGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Merge two bo-knowledge instances under Belnap knowledge ordering." "" NIL)
    ("FEATURE-FLAGS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GET-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("DELETEBO" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Deletes the BusinessObject from the BusinessObjectRepository" "" NIL)
    ("CREATE-MODEL-FOR-SEARCHWAREHOUSES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Create model for searching warehouses" "" NIL)
    ("TOTALVALUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-CUSTOMER-TYPE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("DELETE-PRD-CATG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("DELETE-VENDOR-APPOINTMENT-INSTANCES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vas.lisp" "" "" NIL)
    ("SEARCH-INVOICE-HEADER-BY-INVNUM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "" NIL)
    ("RM-UNKNOWN-REASON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COMPANY-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("ORDERITEMREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-REFRESH-IAM-SETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("VERSION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GSTHSNCODESRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("ERROR-VALUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp" "" "" NIL)
    ("BO-KNOWLEDGE-PAYLOAD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "" NIL)
    ("WAREHOUSERESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("WITH-HTML-EMAIL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SEARCHINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VEN-EXPEXL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("SGSTRATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("WITH-HTML-CARD" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "A HTML Bootstrap 5.x card generator macro." "" NIL)
    ("VIEW" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" ""
     NIL)
    ("FILTER-PRODUCTS-BY-CATEGORY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("REQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-VENDPUSHSUBSCRIBEPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DELETE-THREADS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GETPINCODEDETAILS-OLD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("COM-HHUB-BUSINESSFUNCTION-BL-GETPUSHNOTIFYSUBSCRIPTIONFORVENDOR"
     "FUNCTION" "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp"
     "" "" NIL)
    ("COM-HHUB-POLICY-CREATE-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("PRD-QTY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("SELECT-WAREHOUSE-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select warehouse by name" "" NIL)
    ("GET-ORDER-ITEMS-BY-PRODUCT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("HSN-DESCRIPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("SELECT-AUTH-ATTR-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("DISPLAY-ORDER-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-GENERATE-PRODUCTS-TEMPL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("WITH-STANDARD-VENDOR-PAGE-V2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-VENDOR-CREATE-CUSTOMER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("STANDARDCUSTOMER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-APT-NO" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ACTIVE-FLAG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("MODAL.VENDOR-FLATRATE-SHIPPING-CONFIG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DELETE-CUST-PROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("DUPLICATE-CUSTOMERP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("DELETE-ALL-ORDER-ITEMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("CREATE-OPREF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "" NIL)
    ("WITH-KNOWLEDGE-CHECK" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp" "" "" NIL)
    ("CREATEORDERITEMOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-OrderItem.lisp" "" "" NIL)
    ("ORDNUM" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("WITH-STANDARD-CUSTOMER-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-VDISPLAY-WEBREPL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-ORDER-BY-STATUS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("W-MANAGER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SHOW-INVOICE-PAYMENT-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-10" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-PRICING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("WEBPUSHNOTIFYREPOSITORY" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("GET-BUS-TRAN-ABAC-SUBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-bo.lisp" "" "" NIL)
    ("UPDATE-OPREF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "" NIL)
    ("DETERMINE-SHIPPING-HTML-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("WITH-MVC-REDIRECT-UI" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("USERNAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-usr.lisp" "" "" NIL)
    ("PRODUCT-CARD-WITH-DETAILS-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("DISPLAY-PRODUCTS-BY-CATEGORY-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CADPROFILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("BO-ADD-PROVENANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return a new bo-knowledge with SOURCE added to provenance (non-destructive)."
     "" NIL)
    ("SAC-DESCRIPTION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("WITH-STANDARD-VENDOR-PAGE-V3" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("VIEWUNKNOWN" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "" "" NIL)
    ("CUSTOMER-PROFILE-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PERSIST-ABAC-SUBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("CREATE-PAYMENT-TRANS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-bl-pay.lisp" "" "" NIL)
    ("COM-HHUB-CONTROLLER-PROJECT-SYMBOLS-LOOKUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Controller: Renders the symbol lookup page." "" NIL)
    ("GETDEFAULTSHIPPINGMETHOD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-DELETECUSTORDITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PRD-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("NST-GET-CACHED-PRODUCT-TEMPLATE-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("ROW-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("DISPLAY-UPI-TRANSACTION-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("RESPONSEMODELNIL" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("ORDER-SOURCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("FIND-NEAREST-SHIPPING-OPTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "" NIL)
    ("DISPATCH" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Runs pipeline + outbound adapter selection." "" NIL)
    ("UPDATE-USER-ROLE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("APPROVAL-STATUS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("STANDARD-CUST-INFORMATION-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("%LOG-CRUD-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Append a structured DB error to the business-functions log file." "" NIL)
    ("DOD-CONTROLLER-REFRESH-PENDING-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-UPIRECHARGEWALLETPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-VENDOR-UPI-CANCEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("CUSTOMERHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("TRIAL-ACCOUNT-EXPIRED-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("UPDATE-GST-FOR-ORDER-LINEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("COPYWEBPUSHNOTIFICATION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "" NIL)
    ("WAREHOUSE-CODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-VSEARCHCUSTBYPHONE-FOR-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("EVALUATE-CHECKOUT-READINESS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Evaluates the final checkout decision based on multiple FDE truth values."
     "" NIL)
    ("GET-BILLZIPCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("EDITINVOICEWIDGET-SECTION2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SETASSERVICEPRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("AVAIL-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-ACTIVE-VENDOR-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-PUSH-NOTIFY-SUBSCRIPTION-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-bl-push.lisp" "" "" NIL)
    ("UPDATED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-ADDPRDTOINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("ROUND-TO-2-DECIMAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Standard rounding to 2 decimal places." "" NIL)
    ("START-TIME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("BO-KNOWLEDGE-TIMESTAMP" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "" NIL)
    ("GET-LEFT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("CUST-WALLET-AS-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GET-APPLIED-MIGRATIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("CREATE-RESPONSE-FROM-DOMAIN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Polymorphic response creation" "" NIL)
    ("CREATE-DIGEST-MD5" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("DOD-CONTROLLER-POLICY-SEARCH-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("URI-PREFIX-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CUST-PROFILE-WALLETS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-PRD-DETAILS-FOR-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CALCULATE-CARTITEMS-WEIGHT-KGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-DOWNLOAD-INVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DB-CONSTRAINT-VIOLATION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Signal this (or a subclass) from your DB adapter when a constraint
    violation occurs (duplicate key, NOT NULL, FK violation, check
    constraint, etc.).  with-db-create will map this to :F."
     "" NIL)
    ("RENDERHTML" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Takes the viewmodel and converts into HTML" "" NIL)
    ("CTX-REQUESTMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("%LOG-DB-ERROR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Append a DB error to the business-functions log file." "" NIL)
    ("DOD-CAD-LOGIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("SELECT-USER-BY-PHONENUMBER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-bl-usr.lisp" "" "" NIL)
    ("PERSIST-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("HHUB-SAVE-CUSTOMER-PUSH-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-UPIRECHARGEWALLETPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-2" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-MY-CUSTOMERS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("UI-LIST-ORDER-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-odt.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-UPDATE-PAYMENT-GATEWAY-SETTINGS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("RENDER-UI-COMPONENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp"
     "Render a component by invoking its renderer with MODELFUNC.
Returns a list of widget outputs."
     "" NIL)
    ("SELECT-ROLE-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-rol.lisp" "" "" NIL)
    ("SELECT-AUTH-POLICY-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("CREATEINVOICEHEADEROBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-bl-ihd.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CAD-LOGIN-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-VENDOR-TABLERATESHIP-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("SAC-CODE-4DIGIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("CREATE-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("BO-UNKNOWN-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Return T if bo-knowledge is unknown." "" NIL)
    ("ENCRYPT" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "" "" NIL)
    ("GET-LOGIN-VENDOR-SETTING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VPRODADDACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-LOGIN-CUSTOMER-COMPANY-WEBSITE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("INVOICEPRINTSETTINGSWIDGETHTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("UPDATE-VENDOR-SHIPZONE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("IS-B2C-CUSTOMER-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Check if customer is B2C (no GSTIN)" "" NIL)
    ("CREATE-MODEL-FOR-DOWNLOADINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("UPDATE-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("DOD-ROLES" "CLASS" "/home/ubuntu/ninestores/hhub/core/dod-dal-rol.lisp"
     "" "" NIL)
    ("BUSINESSOBJECT-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("LAZY-CDR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("DISC-RATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("UPDATE-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-UPDATE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ACTOR-MESSAGE-COUNT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("IS-DOD-VEND-SESSION-VALID?" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-WAREHOUSE-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-ui-wrh.lisp"
     "Create/Edit warehouse dialog with tabbed interface for all 41 fields" ""
     NIL)
    ("WPHONE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("RENDER-UI-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("POLICY-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("DB-SAVE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Savte the domianobject to the database" "" NIL)
    ("GENERATEOTP&REDIRECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("ORDER-SHIPPING-RATE-CHECK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-ui-osh.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-COMPADMIN-UPDATEDETAILS-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("GET-CREATED-BY-USER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("DELETE-AUTH-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("WITH-MVC-UI-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("REVENUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("PRDCATGINLIST-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("FORMAT-PRICING-PLANS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-PINCODE-CHECK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("IPADRESS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-PAYMENT-SUCCESSFUL-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-ui-pay.lisp" "" "" NIL)
    ("GET-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("GET-LOGIN-USERNAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-usr.lisp" "" "" NIL)
    ("DEFUN-MEMO" "MACRO" "/home/ubuntu/ninestores/hhub/core/memoize.lisp"
     "Define a memoized function." "" NIL)
    ("GET-BILLCITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("INVOICEHEADERSTATUSREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDORUPDATEACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("WITH-ADMIN-NAVIGATION-BAR" "MACRO"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("GET-SHIPCITY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("CREATEBUSINESSCONTEXT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Create a business context" "" NIL)
    ("COM-HHUB-TRANSACTION-CUSTOMER&VENDOR-CREATE-OTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("IS-DOD-SESSION-VALID?" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("DAS-CUST-PAGE-WITH-TILES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-SEARCH-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PERSIST-BUS-OBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("LAZY" "MACRO" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" "" "" NIL)
    ("GET-REQUESTED-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("COUNT-COMPANY-VENDORS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("SEND-ORDER-SMS-GUEST-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-CHANGE-PIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-COMPANY-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("WITH-CUSTOMER-NAVIGATION-BAR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("MODAL.DELETE-SUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "" NIL)
    ("DOD-PRD-CATG" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("UI-LIST-VEND-ORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("MODAL.VENDOR-PRODUCT-REJECT-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("GET-CUSTOMER-DISPLAY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Get appropriate display name based on customer type" "" NIL)
    ("CREATE-MODEL-FOR-SHOWVENDORUPITRANSACTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-UPDATE-WAREHOUSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CANCEL-REASON" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("COPYVPAYMENTMETHODS-DOMAINTODB" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vpm.lisp" "" "" NIL)
    ("ORDERRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("UPI-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("TITLE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("HSN-CODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("INVOICEITEMRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("GET-LOGIN-CUST-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PARSE-TIME-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("INITBUSINESSCONTEXTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp"
     "This generic function will initialize the business contexts for the business server"
     "" NIL)
    ("WITH-HTML-DIV-COL-6" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("SUBSCRIPTION-PLAN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-DISPLAY-INVOICE-PUBLIC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("GET-SYSTEM-AUTH-POLICIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("DOD-GET-CACHED-COMPLETED-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("SAVE-UPI-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-ui-upi.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-NEW-COMMUNITY-STORE-REQUEST-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("VPAYMENTMETHODSHTMLVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("GET-UOM-DESCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp"
     "Get user-friendly description for a UOM code." "" NIL)
    ("COM-HHUB-POLICY-CREATE-WAREHOUSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-COMPADMINHOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("WITH-HTML-COLLAPSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("MIGRATE-2026JAN-UPDATE-CUSTOMER-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "Update the customer table to support a B2B organization" "" NIL)
    ("INVOICE-HEADER-ACTIONS-MENU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SHOWINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SEND-WEBPUSH-MESSAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "" NIL)
    ("CUST-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("ORDERTEMPLATEFILLITEMROWS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-PRODUCT-CATEGORIES-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-VENDORS-FOR-APPROVAL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("TOTAL-TAX" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("NST-LOAD-CUSTOMER-TEMPLATES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("WITH-HTML-DIV-COL-12" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-SHIPSTATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("ADD-LOGIN-USER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("SELECT-CUSTOMER-LIST-BY-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("LAZY-NIL" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("DISPLAY-GST-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PRODUCT-CARD-WITH-DETAILS-FOR-CUSTOMER2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-prodetpag.lisp" "" "" NIL)
    ("CALCULATE-ORDER-TOTALBEFORETAX" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDPAYMENTMETHODSUPDATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("INTERSTATE-P" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp" "" "" NIL)
    ("MIGRATE-2026FEB-CREATE-EWAY-BILL-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "Create vendor gstr1 status table for a customer to verify whether the vendor has filed gstr1."
     "" NIL)
    ("CREATEVPAYMENTMETHODSOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vpm.lisp" "" "" NIL)
    ("ORDER-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("IS-CANCELLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("GET-HT-VALUES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("WITH-HTML-DIV-ROW" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("UPIPAYMENTSADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("ORDER-DATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-ord.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-PRODCATG-ADD-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("SETASSALESPRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("GENERATE-UQC-MIGRATION-SQL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp"
     "Generate SQL to populate UQC field from unit_of_measure." "" NIL)
    ("WITH-DB-UPDATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "UPDATE boundary macro for CLSQL via DBAdapterService.db-save.

   Caller responsibilities BEFORE this macro:
     1. (init dbas updated-bo)                     ; attach updated BO
     2. (setcompany dbas company)                  ; set tenant context
     3. (copy-businessobject-to-dbobject dbas)     ; flush new values to DB row

   PRE-FLIGHT (strongly recommended) — a CLSQL SELECT expression that
   returns a list of rows matching the update target.  Drives :F and :C
   detection.  Without it, :F cannot be produced because CLSQL does not
   return rows-affected from db-save.

   Returns a BO-KNOWLEDGE instance.  Use WITH-BO-KNOWLEDGE-CHECK to
   branch on the result.  BODY is unused and reserved for future use."
     "" NIL)
    ("MAKE-ADAPTER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp"
     "Create adapter instance for route. Override as needed." "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-PRDSUBS-ENABLED" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("UPDATE-INVOICE-SETTINGS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read, modify, and save YAML settings." "" NIL)
    ("MASK-OTP" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/nst-bl-otp.lisp"
     "" "" NIL)
    ("PROCESS-MESSAGES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("GENERATE-ACCOUNT-EXT-URL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("ORDERITEMSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-READ-WAREHOUSE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("ORDERSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("DOD-AUTH-ATTR-LOOKUP" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-UPDATE-INVOICEITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("WCOUNTRY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("PRODUCT-CSV-FILE-DATA-ROW" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("MIGRATE-2026MARCH-CREATE-DELIVERY-ORDER-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "" "" NIL)
    ("SELECT-AUTH-POLICY-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("CONVERT-NUMBER-TO-WORDS-USD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("WITH-ENTITY-CREATE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("COUNTRY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/dod-sto-zip.lisp" "" "" NIL)
    ("DOD-CONTROLLER-UPDATE-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CTX-VIEWMODEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("PROCESSREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "This function is responsible for initializaing the BusinessService and calling its doService method. It then creates an instance of outboundwebservice"
     "" NIL)
    ("PARSE-OLLAMA-NDJSON" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-ollama.lisp" "" "" NIL)
    ("W-EMAIL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("TAX-ENTRY" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-itm.lisp"
     "Represents a single row in the HSN summary table." "" NIL)
    ("MODAL.VENDOR-FREE-SHIPPING-CONFIG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("UI-LIST-CUSTOMER-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTADDTOCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DELETE-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("SELECT-WAREHOUSE-BY-CODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select warehouse by business code" "" NIL)
    ("GET-ORDERS-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("CREATEUPIPAYMENTOBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/upi/dod-bl-upi.lisp" "" "" NIL)
    ("PROCESSDELETEREQUEST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Adapter Service method to call the BusinessService Delete method" "" NIL)
    ("GET-CUST-WALLET-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("ACTOR-QUEUE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-PAYMENT-FAILURE-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-ui-pay.lisp" "" "" NIL)
    ("ORDERSHIPMENT" "CLASS"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "" NIL)
    ("GET-MAX-OF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-PROJECT-SYMBOLS-LOOKUP-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Widget Factory: Calls the widget with the model data." "" NIL)
    ("ADAPTER-CLASS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("UPDATE-RESET-PASSWORD-INSTANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("MODAL.VENDOR-PRODUCT-EDIT-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("PAYMENT-GATEWAY-MODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("GSTHSNCODESPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("ODTK-ORDER-ID" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-dal-odt.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SHOWORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CAD-PRODUCT-REJECT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("HHUB-CONTROLLER-VSEARCHCUSTBYNAME-FOR-INVOICE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SEARCH-ORDERITEM-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("INVOICEHEADERPRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("HAS-PERMISSION1" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("LAZY-CONS" "MACRO" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp" ""
     "" NIL)
    ("UI-LIST-CUSTOMER-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "" NIL)
    ("FILTER-OPREF-ITEMS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("WITH-CATCH-FILE-UPLOAD-EVENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("PERSIST-FREE-SHIPPING-METHOD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-bl-osh.lisp" "" "" NIL)
    ("INIT-PINCODE" "FUNCTION" "/home/ubuntu/ninestores/hhub/dod-sto-zip.lisp"
     "" "" NIL)
    ("CREATE-WIDGETS-FOR-ADDCUSTTOINVOICE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("ACTOR-THREAD-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("DBADAPTERSERVICE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CREATEWHATSAPPLINK" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SEARCHORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("CANCEL-ORDER-BY-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("CHECK-ZERO-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("COMPANY-SUBSCRIPTION-PLAN-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("WAREHOUSE" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CUSTOMER-SUBSCRIPTIONS-TABLE-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-ui-opf.lisp" "" "" NIL)
    ("DOD-CONTROLLER-VENDOR-UPDATE-DEFAULT-SHIPPING-METHOD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("OUTBOUND-ADAPTER-ROUTE" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-VENDOR-REJECT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("DOD-CONTROLLER-PASSWORD-RESET-MAIL-LINK-SENT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GENERATE-WAREHOUSE-SHORT-CODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Generate short alphanumeric code: WH-XXXXXXXX" "" NIL)
    ("OWNERSHIP-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("FIND-CALLER-NAME-FROM-BACKTRACE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Uses string parsing on SBCL's LIST-BACKTRACE to find the 
   symbol name of the function that called the DB adapter."
     "" NIL)
    ("BILLSTATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CREATEORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDORORDERDETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("MIGRATE-2025AUG-ORDERITEM-UPGRADE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-sch-mig.lisp" "" "" NIL)
    ("VIEWNIL" "CLASS" "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" ""
     "" NIL)
    ("INVOICEHEADERVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("WITH-STANDARD-ADMIN-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("DOD-PRODUCT-GST" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("PAYMENT-API-KEY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("WITH-VENDOR-NAVIGATION-BAR" "MACRO"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("TEST-WEBPUSH-NOTIFICATION-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "" NIL)
    ("DELETE-RESET-PASSWORD-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("AUDIT-LEVEL" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("HHUB-GEN-GLOBALLY-CACHED-LISTS-FUNCTIONS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("DELETE-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-LOGIN-AS-GUEST" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("RESOLVE-VIEW-FOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("PUSH-NOTIFY-SUBS-FLAG" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("COMP-CESS-FUNC" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-VENDORCREATECUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("CREATE-MODEL-WITHNILDATA" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("SELECT-BUS-TRANS-BY-TRANS-FUNC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("W-STATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("VALUATION-METHOD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-PRDDETAILSFORVENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("ADD-NEW-PRDCATG-NODE-AS-CHILD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("SETDBOBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "Set the DBObject" ""
     NIL)
    ("INVOICEPRODUCTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("CONCAT-ORD-DTL-NAME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "" NIL)
    ("DOD-GET-CACHED-PENDING-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-CREATE-ORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("CALL-CONTEXT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("SEND-WEBPUSH-NOTIFICATION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-ui-push.lisp" "" "" NIL)
    ("HHUB-READ-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("GET-PINCODE-API-RESULT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Simulates the external API call and maps its output to a 4-valued truth value."
     "" NIL)
    ("COM-HHUB-POLICY-CAD-LOGIN-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("ASYNC-UPLOAD-FILES-S3BUCKET-BEHAVIOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-LIST-ORDERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "" NIL)
    ("DELETE-DOD-COMPANIES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("NST-ACTOR" "CLASS" "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp"
     "Class representing an actor with message queue and behavior." "" NIL)
    ("GET-LATEST-OPREF-FOR-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/subscription/dod-bl-opf.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTSHOWSHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PRD-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("WAREHOUSE-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-SEARCH-CUSTOMER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("INVOICETEMPLATEFILLITEMROWS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("SELECT-DELETED-CUSTOMER-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("GET-ACCOUNT-CURRENCY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("CUSTOMERSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/nst-dal-Customer.lisp" "" "" NIL)
    ("DISPLAY-COMPADMIN-PAGE-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("WAREHOUSEJSONVIEW" "CLASS"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("VENDORREPOSITORY" "CLASS"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-GST-HSN-CODE-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-UPDATEORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("CGST" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("HHUB-RANDOM-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("PASSWORD" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-PRODUCTS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("MODAL.VENDOR-PAYMENT-METHODS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GENERATEPDF" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("TCUF-VALUE-CHECKER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "Adapter function that performs the simple, deterministic T/F check." ""
     NIL)
    ("REGISTRATION-TYPE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUSTOMER-PAYMENT-CANCEL-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/paymentgateway/dod-ui-pay.lisp" "" "" NIL)
    ("ORDERITEMADAPTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("BO-KNOWLEDGE-PROVENANCE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp" "" "" NIL)
    ("GET-LOGIN-VENDOR-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-ui-cmp.lisp" "" "" NIL)
    ("GET-SYSTEM-ABAC-SUBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("INVOICEITEM-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("SUBMITSEARCHFORM1EVENT-JS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("SELECT-PRODUCTS-BY-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("GET-CIPHER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("PERSIST-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("WITH-DB-READ-ALL" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/nst-mult-logic.lisp"
     "SELECT-many boundary macro for CLSQL via DBAdapterService.db-fetch-all.

   PK-EXTRACTOR (optional) — a one-arg function (lambda (bo) ...) that
   returns the primary-key value for a row in the result list.  When
   supplied, the list is scanned for duplicates; any duplicate promotes
   status to :C.

   Returns a BO-KNOWLEDGE instance.  Payload on :T is the list returned
   by db-fetch-all (typically a list of CLSQL view-class instances)."
     "" NIL)
    ("CTX-TRANS-FUNC-NAME" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("SET-WALLET-BALANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("INVOICES-ACTIONS-MENU" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("SHIPPINGRATECHECK" "CLASS"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDORPRODPRICINGACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COMPANY-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ORDERVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-Order.lisp" "" "" NIL)
    ("WITH-STANDARD-COMPADMIN-PAGE" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-COMPANY-MAXVENDORCOUNT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VBULKADDPRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("BUSINESSSERVER" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("DISPLAY-SEARCH-RESULTS-WITH-WIDGETS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("NST-GET-CACHED-VENDOR-TABLES-STRUCTURE-FOR-AGENTIC-AI" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("GET-TOP-CUSTOMERS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Get top customers by spend or order count" "" NIL)
    ("MIGRATE-2026MARCH-CREATE-EWAY-BILL-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "Create vendor gstr1 status table for a customer to verify whether the vendor has filed gstr1."
     "" NIL)
    ("ODT-VENDOROBJECT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/shipping/dod-dal-osh.lisp" "" "" NIL)
    ("DELETE-BUS-TRANSACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-bo.lisp" "" "" NIL)
    ("INVOICEHEADERSEARCHREQUESTMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("GET-CUST-ORDER-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("MIGRATE-2026FEB-MODIFY-PAYMENT-TRANSACTION-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "" "" NIL)
    ("AUTO-POPULATE-FROM-GSTIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Auto-populate PAN and state from GSTIN if not set" "" NIL)
    ("PARSE-DATE-STRING-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Read a date string of the form \"YYYY-MM-DD\" and return the 
corresponding universal time."
     "" NIL)
    ("HHUB-HTML-PAGE-FOOTER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-site.lisp" "" "" NIL)
    ("STATE" "GENERIC-FUNCTION" "/home/ubuntu/ninestores/hhub/dod-sto-zip.lisp"
     "" "" NIL)
    ("MAKE-BO-KNOWLEDGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-beltrusys.lisp"
     "Create a bo-knowledge instance. PROVENANCE may be a single value or a list."
     "" NIL)
    ("COM-HHUB-TRANSACTION-SEARCH-GST-HSN-CODES-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("BO-KNOWLEDGE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("RENDER-PICKUP-ONLY-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ATTRIBUTE-TYPE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("PRODUCT-CARD-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-prd.lisp" "" "" NIL)
    ("GET-SYSTEM-CURRENCIES-HT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-sys.lisp" "" "" NIL)
    ("SELECT-WAREHOUSES-BY-STATE-CODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-bl-wrh.lisp"
     "Select warehouses by state code" "" NIL)
    ("MODAL.VENDOR-DETAILS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-CURRNCY" "CLASS"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-dal-sys.lisp" "" "" NIL)
    ("GET-DATEOBJ-FROM-STRING-YYYYMMDD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("SEARCH-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("CREATEWIDGETSFORVENDORADDNEWPRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("GET-CUSTOMER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-ROLES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("BUSOBJ-CARD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CANCEL-ORDER-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("ACTIVATE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("VIEWCONTRADICTION" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("CTX-REQUESTMODEL-PARAMS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-conflodis.lisp" "" "" NIL)
    ("GET-ALL-ORDERS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("RESET-VENDOR-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("SELECT-ACTIVE-PRODUCTS-BY-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("DELETE-DOD-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-bl-cmp.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-LOGIN-OTPSTEP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PRODUCT-QTY-EDIT-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-SEARCHINVOICEHEADER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("DOD-CONTROLLER-CUST-LOGIN-WITH-OTP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-NUMBER" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-B2B-CUSTOMER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp"
     "Create a new B2B customer" "" NIL)
    ("INIT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "Set the domain object of the ResponseModel " "" NIL)
    ("CREATE-WIDGETS-FOR-CREATEORDERITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("UPIPAYMENTSRESPONSEMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/upi/dod-dal-upi.lisp" "" "" NIL)
    ("GUEST-CUST-PAYMENT-MODE-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-PRODUCT-PRICING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTOMERINDEXPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-GST-HSN-CODE-DIALOG" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-ui-gst.lisp" "" "" NIL)
    ("ORDERITEMS-SEARCH-HTML" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-OrderItem.lisp" "" "" NIL)
    ("ACTOR-CREATED-AT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-bl-act.lisp" "" "" NIL)
    ("INVOICETAXBREAKDOWN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-dal-ihd.lisp" "" "" NIL)
    ("SALT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("INVOICETEMPLATEFILLITEMROWSPUBLIC" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("DOD-CONTROLLER-OTP-REQUEST-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("DOD-PRODUCT-PRICING" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-prd.lisp" "" "" NIL)
    ("INVOICETEMPLATEFILL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("GET-TENANT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("DOD-CONTROLLER-DISPLAY-VENDOR-TENANTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("HHUB-WRITE-FILE-FOR-CSS-INLINING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("COM-HHUB-ATTRIBUTE-CUST-ORDER-PAYMENT-MODE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-attr.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-VENDPUSHSUBSCRIBEPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-SADMIN-HOME" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("PERSIST-AUTH-POLICY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CUSTOMER&VENDOR-CREATE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("MODAL.VENDOR-UPDATE-PAYMENT-GATEWAY-SETTINGS-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTDELETEORDERSUBSCRIPTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("DOD-CONTROLLER-LIST-ATTRS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-sys.lisp" "" "" NIL)
    ("PERM-GRANTED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("HHUB-NO-RESULT" "CLASS"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-err.lisp"
     "Raised when a DB query returns zero rows." "" NIL)
    ("COM-HHUB-TRANSACTION-SHOW-CUSTOMER-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("HSNCODE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("RENDER-STANDARD-SHIPPING-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("PRDINLIST-P" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CADLOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("COM-HHUB-TRANSACTION-CREATE-CUSTOMER-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/nst-ui-Customer.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-CUSTSHIPMETHODSPAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("GET-LOGIN-CUST-COMPANY" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-DELETEINVOICEITEM" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-itm.lisp" "" "" NIL)
    ("UPIENABLED" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vpm.lisp" "" "" NIL)
    ("ACCORDION-EXAMPLE2" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("UI-LIST-ORDERS-FOR-EXCEL" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-ui-ord.lisp" "" "" NIL)
    ("CREATE-WIDGETS-FOR-SEARCHORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("WITH-HTML-INPUT-PASSWORD" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("CREATE-PAYMENT-GATEWAY-WIDGET" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("MIGRATE-2026FEB-CREATE-TDS-CERTIFICATES-TABLE" "FUNCTION"
     "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-gstupgrades.lisp"
     "Create vendor gstr1 status table for a customer to verify whether the vendor has filed gstr1."
     "" NIL)
    ("EMPLOYEES" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("WEBPUSHNOTIFYVENDOR" "CLASS"
     "/home/ubuntu/ninestores/hhub/webpushnotify/dod-dal-push.lisp" "" "" NIL)
    ("SELECT-HSN-CODE-BY-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "" NIL)
    ("DOD-CONTROLLER-LOW-WALLET-BALANCE-FOR-SHOPCART" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-VENDOR-ADD-PRODUCT-ACTION" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("WAREHOUSE-GSTIN" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/warehouse/dod-dal-wrh.lisp" "" "" NIL)
    ("BUSINESSSERVICES-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("GET-COMPLETED-ORDER-ITEMS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-odt.lisp" "" "" NIL)
    ("UPDATE-VENDOR-PAYMENT-PARAMS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("RESTORE-DELETED-VENDOR-AVAILABILITY-DAY-INSTANCES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vad.lisp" "" "" NIL)
    ("SALUTATION" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-ven.lisp" "" "" NIL)
    ("POLICY-ATTR-COMPANY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-dal-pol.lisp" "" "" NIL)
    ("COM-HHUB-POLICY-CAD-LOGOUT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-pol.lisp" "" "" NIL)
    ("CREATE-BULK-PRODUCTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("GET-SYSTEM-GST-HSN-CODES" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "" NIL)
    ("COMPANY-CREATED-BY" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/account/dod-dal-cmp.lisp" "" "" NIL)
    ("DOD-CONTROLLER-PRODUCT-CATEGORIES-PAGE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/sysuser/dod-ui-cad.lisp" "" "" NIL)
    ("GET-MAX-ORDER-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/dod-bl-ord.lisp" "" "" NIL)
    ("COMMENTS" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-dal-vad.lisp" "" "" NIL)
    ("WITH-MVC-UI-COMPONENT" "MACRO"
     "/home/ubuntu/ninestores/hhub/core/dod-ui-utl.lisp" "" "" NIL)
    ("GET-VENDOR-TENANTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-ven.lisp" "" "" NIL)
    ("BUSINESSOBJECTS-HT" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp" "" "" NIL)
    ("EDITINVOICEWIDGET-SECTION3" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp" "" "" NIL)
    ("GET-LOGIN-VENDOR-TENANT-ID" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-ui-ven.lisp" "" "" NIL)
    ("CREATE-AUTH-ATTR-LOOKUP" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pol.lisp" "" "" NIL)
    ("CREATE-MODEL-FOR-CREATEORDER" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-ui-Order.lisp" "" "" NIL)
    ("CURRENT-DATE-STRING" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp"
     "Returns current date as a string in YYYY/MM/DD format" "" NIL)
    ("CHECK-PASSWORD" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-utl.lisp" "" "" NIL)
    ("CREATE-RESET-PASSWORD-INSTANCE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-bl-pas.lisp" "" "" NIL)
    ("ADDRESS-PRESENTER" "CLASS"
     "/home/ubuntu/ninestores/hhub/customer/dod-dal-cus.lisp" "" "" NIL)
    ("SELECT-CUSTOMERS-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-bl-cus.lisp" "" "" NIL)
    ("COPYVPAYMENTMETHODS-DBTODOMAIN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/vendor/dod-bl-vpm.lisp" "" "" NIL)
    ("DOCREATE" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/hhub-bl-ent.lisp"
     "DoCreate service implementation for a Business Service" "" NIL)
    ("DEACTIVATE-PRODUCT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-prd.lisp" "" "" NIL)
    ("HHUB-GET-CACHED-ABAC-SUBJECTS" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/dod-ini-sys.lisp" "" "" NIL)
    ("GSTHSNCODESVIEWMODEL" "CLASS"
     "/home/ubuntu/ninestores/hhub/products/dod-dal-gst.lisp" "" "" NIL)
    ("SELECT-HSN-CODES-BY-TEXT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/products/dod-bl-gst.lisp" "" "" NIL)
    ("CUSTOMER-VENDOR-DROPDOWN" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("CREATEORDEROBJECT" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-bl-Order.lisp" "" "" NIL)
    ("LAZY-MAPCAR" "FUNCTION" "/home/ubuntu/ninestores/hhub/core/hhublazy.lisp"
     "" "" NIL)
    ("GET-ORDER-ITEMS-TOTAL-FOR-VENDOR" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/customer/dod-ui-cus.lisp" "" "" NIL)
    ("ORDER" "GENERIC-FUNCTION"
     "/home/ubuntu/ninestores/hhub/order/nst-dal-OrderItem.lisp" "" "" NIL)
    ("WRITE-FINAL-LOOKUP-FILE" "FUNCTION"
     "/home/ubuntu/ninestores/hhub/core/nst-ui-prosymloo.lisp"
     "Writes collected and merged symbol data.
   Entry format: (NAME TYPE FILE DOC KEYWORDS META-PLIST)"
     "" NIL)))))
