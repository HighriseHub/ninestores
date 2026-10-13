;;; nst-bl-ihd.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-%
(in-package :nstores)
(clsql:file-enable-sql-reader-syntax)

(defun search-invoice-header-by-invnum (invnum-like vendor company)
  (let* ((tenant-id (slot-value company 'row-id))
	 (vendor-id (slot-value vendor 'row-id)))
    (clsql:select 'dod-invoice-header :where 
		  [and
		  [= [:vendor-id] vendor-id]
		  [= [:tenant-id] tenant-id]
		  [like [:invnum] (format NIL "%~a%"  invnum-like)]]
	       :caching *dod-database-caching* :flatp t)))

(defun select-invoice-header-by-invnum (invnum company)
  (let* ((tenant-id (slot-value company 'row-id)))
    (car (clsql:select 'dod-invoice-header :where
		       [and 
		       [=  [:invnum] invnum]
		       [= [:tenant-id] tenant-id]]
					   :caching *dod-database-caching* :flatp t))))

(defun select-invoice-header-by-context-id (context-id company)
  (let* ((tenant-id (slot-value company 'row-id)))
    (car (clsql:select 'dod-invoice-header :where
		       [and 
		       [=  [:context-id] context-id]
		       [= [:tenant-id] tenant-id]]
					  :caching *dod-database-caching* :flatp t))))

(defun select-all-invoice-headers (vendor company)
  :documentation "This function stores all the currencies in a hashtable. The Key = country, Value = list of currency, code and symbol."
  (let* ((tenant-id (slot-value company 'row-id))
	 (vendor-id (slot-value vendor 'row-id))
	 (invheaders (clsql:select 'dod-invoice-header :where
				   [and
				   [= [:vendor-id] vendor-id]
				   [= [:tenant-id] tenant-id]]
				 :limit 200
				 :caching *dod-database-caching* :flatp t )))
    invheaders))


;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.
;; DO NOT COMPILE THIS FILE USING CTRL + C CTRL + K (OR CTRL + CK)
;; DO NOT ADD THIS FILE TO COMPILE.LISP FOR MASS COMPILATION. 


(defun nst-split-on-hyphen (value)
  "VALUE split on #\\-, as a list of strings. Written out rather than pulled from a library because the two
   splitters this tree already uses are `split-sequence:` in core and nothing at all here, and a helper
   this small is cheaper than a new dependency in a LEGACY file."
  (let ((out '()) (start 0))
    (loop for i from 0 below (length value)
          when (char= (char value i) #\-)
            do (push (subseq value start i) out) (setf start (1+ i)))
    (push (subseq value start) out)
    (nreverse out)))

(defun nst-invoice-number-shaped-p (value)
  "T when VALUE already looks like a number OUR series produced — i.e. it starts with the invoice
   prefix and carries the `-<prefix>-<fy>-<serial>` shape, so a create that was handed one keeps it.

   ⚠ THIS IS A HEURISTIC ON PURPOSE, AND IT IS THE SAFE DIRECTION. The legacy create receives the
   wizard's session key in the same slot (`NST000<random-token>`), so the two MUST be told apart:
   mistaking a session key for a number would store the placeholder, and mistaking a number for a
   session key would MINT A SECOND NUMBER for an invoice that already has one — the worse of the two.
   So the test is deliberately narrow: it demands the separators and a financial-year-looking middle
   segment, which `NST000abc123` cannot satisfy."
  (and (stringp value)
       (let* ((parts (nst-split-on-hyphen value))
              ;; ⚠ THE SEGMENT COUNT IS NOT FIXED: the FINANCIAL YEAR ITSELF CONTAINS A HYPHEN, so a
              ;; normal number splits into FIVE parts and an empty prefix into FOUR. Assuming a count
              ;; cost two wrong versions of this function — test the HEAD and the YEAR segment instead.
              (tail (last parts 2)))
         (and (>= (length parts) 3)
              (string-equal (first parts) "INV")
              (every #'digit-char-p (first tail))
              (plusp (length (second tail)))))))

(defun nst-legacy-invoice-number-template (vendor company)
  "The invoice-number template for the LEGACY create path — the vendor's stored
   invoice-general-settings when readable, else the code default.

   Deliberately a small local reader rather than a call into the adhara invoice file: nst-bl-ihd.lisp
   is the LEGACY DDD layer, and importing a helper from the new domain would make the two stacks
   depend on each other in the direction the strangler-fig rule keeps apart (design D4). The one
   thing they must SHARE is the series itself, and that they do — through nst-invoice-number-for
   and DOD_DOC_COUNTER in core, which is the seam that matters."
  (declare (ignore company))
  (let* ((vendor-id (and vendor (ignore-errors (slot-value vendor 'row-id))))
         (tenant-id (and vendor (ignore-errors (slot-value vendor 'tenant-id))))
         (raw (and vendor-id tenant-id
                   (ignore-errors
                     (first (clsql:query (format nil "SELECT `INVOICE_SETTINGS` FROM `DOD_VEND_PROFILE` ~
                                                        WHERE `ROW_ID` = ~D AND `TENANT_ID` = ~D"
                                                 vendor-id tenant-id)
                                         :flatp t)))))
         (settings (if (and raw (stringp raw) (plusp (length raw)))
                       (ignore-errors (read-from-string raw))
                       *invoice-settings*))
         (general (cdr (assoc 'invoice-general-settings settings :test 'equal)))
         (pair (and general
                    (assoc "INVOICENUMBERFORMAT" general
                           :test (lambda (name key)
                                   (and (symbolp key)
                                        (string= name (remove #\- (string-upcase (symbol-name key))))))))))
    ;; ⚠ THE UNWRAP IS SHARED WITH THE ADHARA PATH (nst-document-template-value, core/dod-bl-utl.lisp):
    ;; `(cdr pair)` is a LIST for a shipped default and a STRING for a saved blob, and the list is what
    ;; nst-format-doc-number refuses. Two readers of one series would be two series.
    (nst-document-template-value
     (or (and pair (cdr pair))
         (let* ((defgeneral (cdr (assoc 'invoice-general-settings *invoice-settings* :test 'equal)))
                (defpair (and defgeneral (assoc 'invoice-number-format defgeneral))))
           (and defpair (cdr defpair)))))))

(defmethod ProcessCreateRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderRequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Warehouse object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod init ((dbas InvoiceHeaderDBService) (bo InvoiceHeader))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'dod-invoice-header)))
    ;; Set specific fields of the DB object if you need to. 
    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))



(defmethod doCreate ((service InvoiceHeaderService) (requestmodel InvoiceHeaderRequestModel))
  (let* ((InvoiceHeaderdbservice (make-instance 'InvoiceHeaderDBService))
	 (context-id (context-id requestmodel))
	 (vendor (vendor requestmodel))
	 (company (company requestmodel))
	 (customer (customer requestmodel))
	 (invnum (invnum requestmodel))
	 (invdate (invdate requestmodel))
	 (custaddr (custaddr requestmodel))
	 (custgstin (custgstin requestmodel))
	 (statecode (statecode requestmodel))
	 (billaddr (billaddr requestmodel))
	 (shipaddr (shipaddr requestmodel))
	 (placeofsupply (placeofsupply requestmodel))
	 (revcharge (revcharge requestmodel))
	 (transmode (transmode requestmodel))
	 (vnum (vnum requestmodel))
	 (totalvalue (totalvalue requestmodel))
	 (totalinwords (totalinwords requestmodel))
	 (bankaccnum (bankaccnum requestmodel))
	 (bankifsccode (bankifsccode requestmodel))
	 (tnc (tnc requestmodel))
	 (authsign (authsign requestmodel))
	 (finyear (finyear requestmodel))
	 ;; 🚨 THE LEGACY PATH MUST MINT ITS OWN NUMBER, AND THIS BINDING IS WHAT MAKES DROPPING THE TRIGGER
	 ;; SAFE. What arrives as :invnum is the wizard's SESSION KEY, not a number: the trigger used to
	 ;; replace it, so with it dropped the key itself would be STORED. ⚠ An already-ours number is KEPT,
	 ;; because the update/email actions build this same model to ADDRESS an existing invoice.
	 (invnum (if (and (stringp invnum) (nst-invoice-number-shaped-p invnum))
	             invnum
	             (nst-invoice-number-for (nst-legacy-invoice-number-template vendor company)
	                                     (nst-vendor-doc-prefix-for (and vendor (ignore-errors (slot-value vendor 'row-id)))
	                                                                (and vendor (ignore-errors (slot-value vendor 'name))))
	                                     invdate
	                                     (and company (ignore-errors (slot-value company 'row-id)))
	                                     (and vendor (ignore-errors (slot-value vendor 'row-id))))))
	 (domainobj (createInvoiceHeaderobject context-id invnum invdate customer custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear vendor company)))
    ;; Initialize the DB Service
    (init InvoiceHeaderdbservice domainobj)
    (copy-businessobject-to-dbobject InvoiceHeaderdbservice)
    (let ((bk (with-db-create (InvoiceHeaderdbservice :source "Invoice Header  create"))))
      ;; Transfer knowledge up to the service layer
      (setf (bo-knowledge service) bk)
      (setf domainobj (bo-knowledge-payload bk))
      ;; Return the newly created warehouse domain object
      domainobj)))

(defun createInvoiceHeaderobject (context-id invnum invdate customer custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear vendor company)
  (let* ((domainobj  (make-instance 'InvoiceHeader 
				    :context-id context-id
				    :invnum invnum
				    :invdate invdate
				    :custaddr custaddr
				    :custgstin custgstin
				    :statecode statecode
				    :billaddr billaddr
				    :shipaddr shipaddr
				    :placeofsupply placeofsupply
				    :revcharge revcharge 
				    :transmode transmode
				    :vnum vnum
				    :totalvalue totalvalue
				    :totalinwords totalinwords
				    :bankaccnum bankaccnum
				    :bankifsccode bankifsccode
				    :tnc tnc
				    :authsign authsign
				    :finyear finyear
				    :external-url ""
				    :vendor vendor
				    :customer customer
				    :status "DRAFT"
				    :company company)))
    domainobj))

(defmethod Copy-BusinessObject-To-DBObject ((dbas InvoiceHeaderDBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copyInvoiceHeader-domaintodb domainobj dbobj))))

;; source = domain destination = db
(defun copyInvoiceHeader-domaintodb (source destination) 
  (let ((vendor (slot-value source 'vendor))
	(customer (slot-value source 'customer))
	(company (slot-value source 'company)))
    (with-slots (context-id invdate custname custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear external-url status deleted-state  custid vendor-id tenant-id) destination
      (setf context-id (slot-value source 'context-id))
      (setf vendor-id (slot-value vendor 'row-id))
      (setf tenant-id (slot-value company 'row-id))
      (setf custid (slot-value customer 'row-id))
      (setf invdate (slot-value source 'invdate))
      (setf custname (slot-value customer 'name))
      (setf custaddr (slot-value source 'custaddr))
      (setf custgstin (slot-value source 'custgstin))
      (setf statecode (slot-value source 'statecode))
      (setf billaddr (slot-value source 'billaddr))
      (setf shipaddr (slot-value source 'shipaddr))
      (setf placeofsupply (slot-value source 'placeofsupply))
      (setf revcharge (slot-value source 'revcharge))
      (setf transmode (slot-value source 'transmode))
      (setf vnum (slot-value source 'vnum))
      (setf totalvalue (slot-value source 'totalvalue))
      (setf totalinwords (slot-value source 'totalinwords))
      (setf bankaccnum (slot-value source 'bankaccnum))
      (setf bankifsccode (slot-value source 'bankifsccode))
      (setf tnc (slot-value source 'tnc))
      (setf authsign (slot-value source 'authsign))
      (setf finyear (slot-value source 'finyear))
      (setf external-url (slot-value source 'external-url))
      (setf status (slot-value source 'status))
      (setf deleted-state "N")
      destination)))


;; PROCESS UPDATE REQUEST  
(defmethod ProcessUpdateRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  ;; call the parent ProcessUpdate
  (call-next-method))

(defmethod ProcessUpdateRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderStatusRequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  ;; call the parent ProcessUpdate
  (call-next-method))

;; PROCESS READ ALL REQUEST.
(defmethod ProcessReadAllRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  (call-next-method))

(defmethod ProcessReadAllRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderSearchRequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  (call-next-method))

(defmethod doreadall ((service InvoiceHeaderService) (requestmodel InvoiceHeaderRequestModel))
  (let* ((comp (company requestmodel))
	 (vendor (vendor requestmodel))
	 (domainobjlst (select-all-invoice-headers vendor comp)))
    ;; return back a list of domain objects 
    (mapcar (lambda (object)
	      (let ((domainobject (make-instance 'InvoiceHeader)))
		(copyInvoiceHeader-dbtodomain object domainobject))) domainobjlst)))

(defmethod doreadall ((service InvoiceHeaderService) (requestmodel InvoiceHeaderSearchRequestModel))
  (let* ((comp (company requestmodel))
	 (vendor (vendor requestmodel))
	 (invnum (invnum requestmodel))
	 (domainobjlst (search-invoice-header-by-invnum invnum vendor comp)))
    ;; return back a list of domain objects 
    (mapcar (lambda (object)
	      (let ((domainobject (make-instance 'InvoiceHeader)))
		(copyInvoiceHeader-dbtodomain object domainobject))) domainobjlst)))


(defmethod CreateViewModel ((presenter InvoiceHeaderPresenter) (responsemodel InvoiceHeaderResponseModel))
  (let ((viewmodel (make-instance 'InvoiceHeaderViewModel)))
    (with-slots (invnum invdate  custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear status vendor customer company) responsemodel
      (setf (slot-value viewmodel 'vendor) vendor)
      (setf (slot-value viewmodel 'customer) customer)
      (setf (slot-value viewmodel 'invnum) invnum)
      (setf (slot-value viewmodel 'invdate) invdate)
      (setf (slot-value viewmodel 'custaddr) custaddr)
      (setf (slot-value viewmodel 'custgstin) custgstin)
      (setf (slot-value viewmodel 'statecode) statecode)
      (setf (slot-value viewmodel 'billaddr) billaddr)
      (setf (slot-value viewmodel 'shipaddr) shipaddr)
      (setf (slot-value viewmodel 'placeofsupply) placeofsupply)
      (setf (slot-value viewmodel 'revcharge) revcharge)
      (setf (slot-value viewmodel 'transmode) transmode)
      (setf (slot-value viewmodel 'vnum) vnum)
      (setf (slot-value viewmodel 'totalvalue) totalvalue)
      (setf (slot-value viewmodel 'totalinwords) totalinwords)
      (setf (slot-value viewmodel 'bankaccnum) bankaccnum)
      (setf (slot-value viewmodel 'bankifsccode) bankifsccode)
      (setf (slot-value viewmodel 'tnc) tnc)
      (setf (slot-value viewmodel 'authsign) authsign)
      (setf (slot-value viewmodel 'finyear) finyear)
      (setf (slot-value viewmodel 'status) status)
      (setf (slot-value viewmodel 'company) company)
      (setf (slot-value viewmodel 'vendor) vendor)
      viewmodel)))
  

(defmethod ProcessResponse ((adapter InvoiceHeaderAdapter) (busobj InvoiceHeader))
  (let ((responsemodel (make-instance 'InvoiceHeaderResponseModel)))
    (createresponsemodel adapter busobj responsemodel)))

(defmethod ProcessResponseList ((adapter InvoiceHeaderAdapter) InvoiceHeaderlist)
  (mapcar (lambda (domainobj)
	    (let ((responsemodel (make-instance 'InvoiceHeaderResponseModel)))
	      (createresponsemodel adapter domainobj responsemodel))) InvoiceHeaderlist))

(defmethod CreateAllViewModel ((presenter InvoiceHeaderPresenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))


(defmethod CreateResponseModel ((adapter InvoiceHeaderAdapter) (source InvoiceHeader) (destination InvoiceHeaderResponseModel))
  :description "source = InvoiceHeader destination = InvoiceHeaderResponseModel"
  (with-slots (invnum invdate  custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear status vendor customer company created) destination  
    (setf invnum (slot-value source 'invnum))
    (setf invdate (slot-value source 'invdate))
    (setf custaddr (slot-value source 'custaddr))
    (setf custgstin (slot-value source 'custgstin))
    (setf statecode (slot-value source 'statecode))
    (setf billaddr (slot-value source 'billaddr))
    (setf shipaddr (slot-value source 'shipaddr))
    (setf placeofsupply (slot-value source 'placeofsupply))
    (setf revcharge (slot-value source 'revcharge))
    (setf transmode (slot-value source 'transmode))
    (setf vnum (slot-value source 'vnum))
    (setf totalvalue (slot-value source 'totalvalue))
    (setf totalinwords (slot-value source 'totalinwords))
    (setf bankaccnum (slot-value source 'bankaccnum))
    (setf bankifsccode (slot-value source 'bankifsccode))
    (setf tnc (slot-value source 'tnc))
    (setf authsign (slot-value source 'authsign))
    (setf finyear (slot-value source 'finyear))
    (setf status (slot-value source 'status))
    (setf vendor (slot-value source  'vendor))
    (setf customer (slot-value source 'customer))
    (setf company (slot-value source 'company))
    destination))



(defmethod doupdate ((service InvoiceHeaderService) (requestmodel InvoiceHeaderRequestModel))
  (let* ((InvoiceHeaderdbservice (make-instance 'InvoiceHeaderDBService))
	 (invnum (invnum requestmodel))
	 (invdate (invdate requestmodel))
	 (custaddr (custaddr requestmodel))
	 (custgstin (custgstin requestmodel))
	 (statecode (statecode requestmodel))
	 (billaddr (billaddr requestmodel))
	 (shipaddr (shipaddr requestmodel))
	 (placeofsupply (placeofsupply requestmodel))
	 (revcharge (revcharge requestmodel))
	 (transmode (transmode requestmodel))
	 (vnum (vnum requestmodel))
	 (totalvalue (totalvalue requestmodel))
	 (totalinwords (totalinwords requestmodel))
	 (bankaccnum (bankaccnum requestmodel))
	 (bankifsccode (bankifsccode requestmodel))
	 (tnc (tnc requestmodel))
	 (authsign (authsign requestmodel))
	 (customer (customer requestmodel))
	 (custid (slot-value customer 'row-id))
	 (vendor (vendor requestmodel))
	 (vendor-id (slot-value vendor 'row-id))
	 (comp (company requestmodel))
	 (tenant-id (slot-value comp 'row-id))
	 (finyear (finyear requestmodel))
	 (external-url (external-url requestmodel))
	 (status (status requestmodel))
	 (InvoiceHeaderdbobj (select-invoice-header-by-invnum invnum comp))
	 (domainobj (make-instance 'InvoiceHeader)))
    ;; FIELD UPDATE CODE STARTS HERE 
    (when InvoiceHeaderdbobj
      (setf (slot-value InvoiceHeaderdbobj 'invnum) invnum)
      (setf (slot-value InvoiceHeaderdbobj 'invdate) invdate)
      (setf (slot-value InvoiceHeaderdbobj 'custaddr) custaddr)
      (setf (slot-value InvoiceHeaderdbobj 'custgstin) custgstin)
      (setf (slot-value InvoiceHeaderdbobj 'statecode) statecode)
      (setf (slot-value InvoiceHeaderdbobj 'billaddr) billaddr)
      (setf (slot-value InvoiceHeaderdbobj 'shipaddr) shipaddr)
      (setf (slot-value InvoiceHeaderdbobj 'placeofsupply) placeofsupply)
      (setf (slot-value InvoiceHeaderdbobj 'revcharge) revcharge)
      (setf (slot-value InvoiceHeaderdbobj 'transmode) transmode)
      (setf (slot-value InvoiceHeaderdbobj 'vnum) vnum)
      (setf (slot-value InvoiceHeaderdbobj 'totalvalue) totalvalue)
      (setf (slot-value InvoiceHeaderdbobj 'totalinwords) totalinwords)
      (setf (slot-value InvoiceHeaderdbobj 'bankaccnum) bankaccnum)
      (setf (slot-value InvoiceHeaderdbobj 'bankifsccode) bankifsccode)
      (setf (slot-value InvoiceHeaderdbobj 'tnc) tnc)
      (setf (slot-value InvoiceHeaderdbobj 'authsign) authsign)
      (setf (slot-value InvoiceHeaderdbobj 'custid) custid)
      (setf (slot-value InvoiceHeaderdbobj 'vendor-id) vendor-id)
      (setf (slot-value InvoiceHeaderdbobj 'tenant-id) tenant-id)
      (setf (slot-value InvoiceHeaderdbobj 'finyear) finyear)
      (setf (slot-value InvoiceHeaderdbobj 'external-url) external-url)
      (setf (slot-value InvoiceHeaderdbobj 'updated) (clsql:get-time))
      (setf (slot-value InvoiceHeaderdbobj 'status) status))
    ;;  FIELD UPDATE CODE ENDS HERE. 
    (setf (slot-value InvoiceHeaderdbservice 'dbobject) InvoiceHeaderdbobj)
    (setf (slot-value InvoiceHeaderdbservice 'businessobject) domainobj)
    (setcompany InvoiceHeaderdbservice comp)
    ;; Return the newly created Invoice Header domain object
    (let ((bk (with-db-update (InvoiceHeaderdbservice :source "Invoice Header Update"))))
      ;; Transfer knowledge up to the service layer
      (setf (bo-knowledge service) bk)
      (setf domainobj (bo-knowledge-payload bk))
      ;; Return the newly created warehouse domain object
      domainobj)))

(defmethod doupdate ((service InvoiceHeaderService) (requestmodel InvoiceHeaderStatusRequestModel))
  (let* ((InvoiceHeaderdbservice (make-instance 'InvoiceHeaderDBService))
	 (invnum (invnum requestmodel))
	 (totalvalue (totalvalue requestmodel))
	 (status (status requestmodel))
	 (payment-status (payment-status requestmodel))
	 (comp (company requestmodel))	 
	 (InvoiceHeaderdbobj (select-invoice-header-by-invnum invnum comp))
	 (domainobj (make-instance 'InvoiceHeader)))
	 
    ;; FIELD UPDATE CODE STARTS HERE 
    (when InvoiceHeaderdbobj
      (setf (slot-value InvoiceHeaderdbobj 'totalvalue) totalvalue)
      (setf (slot-value InvoiceHeaderdbobj 'status) status)
      (setf (slot-value InvoiceHeaderdbobj 'payment-status) payment-status)
      (setf (slot-value InvoiceHeaderdbobj 'updated) (clsql:get-time)))
    ;;  FIELD UPDATE CODE ENDS HERE. 
    (setf (slot-value InvoiceHeaderdbservice 'dbobject) InvoiceHeaderdbobj)
    (setf (slot-value InvoiceHeaderdbservice 'businessobject) domainobj)
    (setcompany InvoiceHeaderdbservice comp)
    ;; Return the newly created Invoice Header domain object
    (let ((bk (with-db-update (InvoiceHeaderdbservice :source "Invoice Header update"))))
      ;; Transfer knowledge up to the service layer
      (setf (bo-knowledge service) bk)
      (setf domainobj (bo-knowledge-payload bk))
      ;; Return the newly created warehouse domain object
      domainobj)))


;; PROCESS THE READ REQUEST
(defmethod ProcessReadRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderRequestModel))
  :description "Adapter service method to read a single InvoiceHeader"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  (call-next-method))

(defmethod ProcessReadRequest ((adapter InvoiceHeaderAdapter) (requestmodel InvoiceHeaderContextIDRequestModel))
  :description "Adapter service method to read a single InvoiceHeader"
  (setf (slot-value adapter 'businessservice) (find-class 'InvoiceHeaderService))
  (call-next-method))

(defmethod doread ((service InvoiceHeaderService) (requestmodel InvoiceHeaderRequestModel))
  (let* ((comp (company requestmodel))
	 (invnum (invnum requestmodel))
	 (dbInvoiceHeader-knowledge (with-db-call (select-invoice-header-by-invnum invnum comp)))
	 (InvoiceHeaderobj (make-instance 'InvoiceHeader)))
    ;; return back a Invoice Header  object
    (setf (slot-value InvoiceHeaderobj 'company) comp)
    (setf (bo-knowledge service) dbInvoiceHeader-knowledge)
    (when (eq (bo-knowledge-truth dbInvoiceHeader-knowledge) :T)
      (let ((dbInvoiceHeader (bo-knowledge-payload dbInvoiceHeader-knowledge)))
	(copyInvoiceHeader-dbtodomain dbInvoiceHeader InvoiceHeaderobj)
	;; set the bo knowledget payload as the domain object
        (setf (bo-knowledge-payload dbInvoiceHeader-knowledge) InvoiceHeaderobj) 
	InvoiceHeaderobj))))

(defmethod doread ((service InvoiceHeaderService) (requestmodel InvoiceHeaderContextIDRequestModel))
  (let* ((comp (company requestmodel))
	 (context-id (context-id requestmodel))
	 (dbInvoiceHeader-knowledge (with-db-call (select-invoice-header-by-context-id context-id comp)))
	 (InvoiceHeaderobj (make-instance 'InvoiceHeader)))
    ;; return back a Invoice Header  object
    (setf (slot-value InvoiceHeaderobj 'company) comp)
    (setf (bo-knowledge service) dbInvoiceHeader-knowledge)
    (when (eq (bo-knowledge-truth dbInvoiceHeader-knowledge) :T)
      (let ((dbInvoiceHeader (bo-knowledge-payload dbInvoiceHeader-knowledge)))
	(copyInvoiceHeader-dbtodomain dbInvoiceHeader InvoiceHeaderobj)
	;; set the bo knowledget payload as the domain object
        (setf (bo-knowledge-payload dbInvoiceHeader-knowledge) InvoiceHeaderobj) 
	InvoiceHeaderobj))))


(defmethod Copy-DbObject-To-BusinessObject ((dbas InvoiceHeaderDBService))
  :description "Syncs the dbobject and domain object"
  (let ((dbobj (slot-value dbas 'dbobject))
        (domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value domainobj 'company) (company dbas))
    (setf (slot-value dbas 'businessobject) (copyInvoiceHeader-dbtodomain dbobj domainobj))))

(defun copyInvoiceHeader-dbtodomain (dbsrc domaindest)
  (let* ((comp (select-company-by-id (slot-value dbsrc 'tenant-id)))
	 (vend (select-vendor-by-id (slot-value dbsrc 'vendor-id)))
	 (cust (select-customer-by-id (slot-value dbsrc 'custid) comp)))

    (with-slots (context-id row-id invnum invdate customer  custaddr custgstin statecode billaddr shipaddr placeofsupply revcharge transmode vnum totalvalue totalinwords bankaccnum bankifsccode tnc authsign finyear external-url status vendor company) domaindest
      (setf vendor vend)
      (setf customer cust)
      (setf company comp)
      (setf context-id (slot-value dbsrc 'context-id))
      (setf row-id (slot-value dbsrc 'row-id))
      (setf invnum (slot-value dbsrc 'invnum))
      (setf invdate (slot-value dbsrc 'invdate))
      (setf custaddr (slot-value dbsrc 'custaddr))
      (setf custgstin (slot-value dbsrc 'custgstin))
      (setf statecode (slot-value dbsrc 'statecode))
      (setf billaddr (slot-value dbsrc 'billaddr))
      (setf shipaddr (slot-value dbsrc 'shipaddr))
      (setf placeofsupply (slot-value dbsrc 'placeofsupply))
      (setf revcharge (slot-value dbsrc 'revcharge))
      (setf transmode (slot-value dbsrc 'transmode))
      (setf vnum (slot-value dbsrc 'vnum))
      (setf totalvalue (slot-value dbsrc 'totalvalue))
      (setf totalinwords (slot-value dbsrc 'totalinwords))
      (setf bankaccnum (slot-value dbsrc 'bankaccnum))
      (setf bankifsccode (slot-value dbsrc 'bankifsccode))
      (setf tnc (slot-value dbsrc 'tnc))
      (setf authsign (slot-value dbsrc 'authsign))
      (setf finyear (slot-value dbsrc 'finyear))
      (setf external-url (slot-value dbsrc 'external-url))
      (setf status (slot-value dbsrc 'status))
      domaindest)))

