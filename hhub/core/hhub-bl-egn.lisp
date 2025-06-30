;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :hhub)

;; METHODS FOR ENTITY CREATE 
;; This file contains template code which will be used to generate for class methods.
;; DO NOT COMPILE THIS FILE USING CTRL + C CTRL + K (OR CTRL + CK)
;; DO NOT ADD THIS FILE TO COMPILE.LISP FOR MASS COMPILATION. 


(defmethod ProcessCreateRequest ((adapter %entity-name%Adapter) (requestmodel %entity-name%RequestModel))
  :description  "Adapter Service method to call the BusinessService Create method. Returns the created Warehouse object."
    ;; set the business service
  (setf (slot-value adapter 'businessservice) (find-class '%entity-name%Service))
  ;; call the parent ProcessCreate
  (call-next-method))


(defmethod init ((dbas %entity-name%DBService) (bo %entity-name%))
  :description "Set the DB object and domain object"
  (let* ((DBObj  (make-instance 'database-table-object-name-here)))
    ;; Set specific fields of the DB object if you need to. 
    ;; End set specific fields of the DB object. 
    (setf (dbobject dbas) DBObj)
    ;; Set the company context for the UPI payments DB service 
    (setcompany dbas (slot-value bo 'company))
    (call-next-method)))



(defmethod doCreate ((service %entity-name%Service) (requestmodel %entity-name%RequestModel))
  (let* ((%entity-name%dbservice (make-instance '%entity-name%DBService))
	 (vendor (vendor requestmodel))
	 (company (company requestmodel))
	 (customer (customer requestmodel))
	 (%0% (%0% requestmodel))
	 (%1% (%1% requestmodel))
	 (%2% (%2% requestmodel))
	 (%3% (%3% requestmodel))
	 (%4% (%4% requestmodel))
	 (%5% (%5% requestmodel))
	 (%6% (%6% requestmodel))
	 (%7% (%7% requestmodel))
	 (%8% (%8% requestmodel))
	 (%9% (%9% requestmodel))
	 (%10% (%10% requestmodel))
	 (%11% (%11% requestmodel))
	 (%12% (%12% requestmodel))
	 (%13% (%13% requestmodel))
	 (%14% (%14% requestmodel))
	 (%15% (%15% requestmodel))
	 (%16% (%16% requestmodel))
	 (%17% (%17% requestmodel))
	 (%18% (%18% requestmodel))
	 (%19% (%19% requestmodel))
	 (%20% (%20% requestmodel))
	 (%21% (%21% requestmodel))
	 (%22% (%22% requestmodel))
	 (%23% (%23% requestmodel))
	 (%24% (%24% requestmodel))
	 (%25% (%25% requestmodel))
	 (%26% (%26% requestmodel))
	 (%27% (%27% requestmodel))
	 (%28% (%28% requestmodel))
	 (%29% (%29% requestmodel))
	 (%30% (%30% requestmodel))
	 (%31% (%31% requestmodel))
	 (%32% (%32% requestmodel))
	 (%33% (%33% requestmodel))
	 (%34% (%34% requestmodel))
	 (%35% (%35% requestmodel))
	 (%36% (%36% requestmodel))
	 (%37% (%37% requestmodel))
	 (domainobj (create%entity-name%object %0% %1% %2% %3% %4% %5% %6% %7% %8% %9% %10% %11% %12% %13% %14% %15% %16% %17% %18% %19% %20% %21% %22% %23% %24% %25% %26% %27% %28% %29% %30% %31% %32% %33% %34% %35% %36% %37%)))
         ;; Initialize the DB Service
    (init %entity-name%dbservice domainobj)
    (copy-businessobject-to-dbobject %entity-name%dbservice)
    (db-save %entity-name%dbservice)
    ;; Return the newly created warehouse domain object
    domainobj))


(defun create%entity-name%object (%0% %1% %2% %3% %4% %5% %6% %7% %8% %9% %10% %11% %12% %13% %14% %15% %16% %17% %18% %19% %20% %21% %22% %23% %24% %25% %26% %27% %28% %29% %30% %31% %32% %33% %34% %35% %36% %37% vendor customer company)
  (let* ((domainobj  (make-instance '%entity-name% 
				       :%0% %0%
				       :%1% %1%
				       :%2% %2%
				       :%3% %3%
				       :%4% %4%
				       :%5% %5%
				       :%6% %6%
				       :%7% %7%
				       :%8% %8%
				       :%9% %9%
				       :%10% %10% 
				       :%11% %11%
				       :%12% %12%
				       :%13% %13%
				       :%14% %14%
				       :%15% %15%
				       :%16% %16%
				       :%17% %17%
				       :%18% %18%
				       :%19% %19%
				       :%20% %20%
				       :%21% %21%
				       :%22% %22%
				       :%23% %23%
				       :%24% %24%
				       :%25% %25%
				       :%26% %26%
				       :%27% %27%
				       :%28% %28%
				       :%29% %29%
				       :%30% %30%
				       :%31% %31%
				       :%32% %32%
				       :%33% %33%
				       :%34% %34%
				       :%35% %35%
				       :%36% %36%
				       :%37% %37%
				       :deleted-state "N"
				       :active-flag "Y"
				       :vendor vendor
				       :customer customer
				       :company company)))
    domainobj))

(defmethod Copy-BusinessObject-To-DBObject ((dbas %entity-name%DBService))
  :description "Syncs the dbobject and the domainobject"
  (let ((dbobj (slot-value dbas 'dbobject))
	(domainobj (slot-value dbas 'businessobject)))
    (setf (slot-value dbas 'dbobject) (copy%entity-name%-domaintodb domainobj dbobj))))

;; source = domain destination = db
(defun copy%entity-name%-domaintodb (source destination) 
  (let ((vendor (slot-value source 'vendor))
	(customer (slot-value source 'customer))
	(company (slot-value source 'company)))
    (with-slots (%0% %1% %2% %3% %4% %5% %6% %7% %8% %9% %10% %11% %12% %13% %14% %15% %16% %17% %18% %19% %20% %21% %22% %23% %24% %25% %26% %27% %28% %29% %30% %31% %32% %33% %34% %35% %36% %37% customer-id vendor-id tenant-id) destination
      (setf vendor-id (slot-value vendor 'row-id))
      (setf tenant-id (slot-value company 'row-id))
      (setf customer-id (slot-value customer 'row-id))
      (setf %0% (slot-value source '%0%))
      (setf %1% (slot-value source '%1%))
      (setf %2% (slot-value source '%2%))
      (setf %3% (slot-value source '%3%))
      (setf %4% (slot-value source '%4%))
      (setf %5% (slot-value source '%5%))
      (setf %6% (slot-value source '%6%))
      (setf %7% (slot-value source '%7%))
      (setf %8% (slot-value source '%8%))
      (setf %9% (slot-value source '%9%))
      (setf %10% (slot-value source '%10%))
      (setf %11% (slot-value source '%11%))
      (setf %12% (slot-value source '%12%))
      (setf %13% (slot-value source '%13%))
      (setf %14% (slot-value source '%14%))
      (setf %15% (slot-value source '%15%))
      (setf %16% (slot-value source '%16%))
      (setf %17% (slot-value source '%17%))
      (setf %18% (slot-value source '%18%))
      (setf %19% (slot-value source '%19%))
      (setf %20% (slot-value source '%20%))
      (setf %21% (slot-value source '%21%))
      (setf %22% (slot-value source '%22%))
      (setf %23% (slot-value source '%23%))
      (setf %24% (slot-value source '%24%))
      (setf %25% (slot-value source '%25%))
      (setf %26% (slot-value source '%26%))
      (setf %27% (slot-value source '%27%))
      (setf %28% (slot-value source '%28%))
      (setf %29% (slot-value source '%29%))
      (setf %30% (slot-value source '%30%))
      (setf %31% (slot-value source '%31%))
      (setf %32% (slot-value source '%32%))
      (setf %33% (slot-value source '%33%))
      (setf %34% (slot-value source '%34%))
      (setf %35% (slot-value source '%35%))
      (setf %36% (slot-value source '%36%))
      (setf %37% (slot-value source '%37%))
      destination)))


;; PROCESS UPDATE REQUEST  
(defmethod ProcessUpdateRequest ((adapter %entity-name%Adapter) (requestmodel %entity-name%RequestModel))
  :description "Adapter service method to call the BusinessService Update method"
  (setf (slot-value adapter 'businessservice) (find-class '%entity-name%Service))
  ;; call the parent ProcessUpdate
  (call-next-method))

;; PROCESS READ ALL REQUEST.
(defmethod ProcessReadAllRequest ((adapter %entity-name%Adapter) (requestmodel %entity-name%RequestModel))
  :description "Adapter service method to read UPI Payments"
  (setf (slot-value adapter 'businessservice) (find-class '%entity-name%Service))
  (call-next-method))

(defmethod doreadall ((service %entity-name%Service) (requestmodel %entity-name%RequestModel))
  (let* ((vend (vendor requestmodel))
	 (comp (company requestmodel))
	 (cust (customer requestmodel))
	 (domainobjlst (select-multiple-objects-func cust  vend comp)))
    ;; return back a list of domain objects 
    (mapcar (lambda (object)
	      (let ((domainobject (make-instance '%entity-name%)))
		(copy%entity-name%-dbtodomain object domainobject))) domainobjlst)))


(defmethod CreateViewModel ((presenter %entity-name%Presenter) (responsemodel %entity-name%ResponseModel))
  (let ((viewmodel (make-instance '%entity-name%ViewModel)))
    (with-slots (%0% %1% %2% %3% %4% %5% %6% %7% %8% %9% %10% %11% %12% %13% %14% %15% %16% %17% %18% %19% %20% %21% %22% %23% %24% %25% %26% %27% %28% %29% %30% %31% %32% %33% %34% %35% %36% %37% vendor customer company created) responsemodel
      (setf (slot-value viewmodel 'vendor) vendor)
      (setf (slot-value viewmodel 'customer) customer)
      (setf (slot-value viewmodel '%0%) %0%)
      (setf (slot-value viewmodel '%1%) %1%)
      (setf (slot-value viewmodel '%2%) %2%)
      (setf (slot-value viewmodel '%3%) %3%)
      (setf (slot-value viewmodel '%4%) %4%)
      (setf (slot-value viewmodel '%5%) %5%)
      (setf (slot-value viewmodel '%6%) %6%)
      (setf (slot-value viewmodel '%7%) %7%)
      (setf (slot-value viewmodel '%8%) %8%)
      (setf (slot-value viewmodel '%9%) %9%)
      (setf (slot-value viewmodel '%10%) %10%)
      (setf (slot-value viewmodel '%11%) %11%)
      (setf (slot-value viewmodel '%12%) %12%)
      (setf (slot-value viewmodel '%13%) %13%)
      (setf (slot-value viewmodel '%14%) %14%)
      (setf (slot-value viewmodel '%15%) %15%)
      (setf (slot-value viewmodel '%16%) %16%)
      (setf (slot-value viewmodel '%17%) %17%)
      (setf (slot-value viewmodel '%18%) %18%)
      (setf (slot-value viewmodel '%19%) %19%)
      (setf (slot-value viewmodel '%20%) %20%)
      (setf (slot-value viewmodel '%21%) %21%)
      (setf (slot-value viewmodel '%22%) %22%)
      (setf (slot-value viewmodel '%23%) %23%)
      (setf (slot-value viewmodel '%24%) %24%)
      (setf (slot-value viewmodel '%25%) %25%)
      (setf (slot-value viewmodel '%26%) %26%)
      (setf (slot-value viewmodel '%27%) %27%)
      (setf (slot-value viewmodel '%28%) %28%)
      (setf (slot-value viewmodel '%29%) %29%)
      (setf (slot-value viewmodel '%30%) %30%)
      (setf (slot-value viewmodel '%31%) %31%)
      (setf (slot-value viewmodel '%32%) %32%)
      (setf (slot-value viewmodel '%33%) %33%)
      (setf (slot-value viewmodel '%34%) %34%)
      (setf (slot-value viewmodel '%35%) %35%)
      (setf (slot-value viewmodel '%36%) %36%)
      (setf (slot-value viewmodel '%37%) %37%)
      (setf (slot-value viewmodel 'company) company)
      (setf (slot-value viewmodel 'created) created)
      viewmodel))))
  

(defmethod ProcessResponse ((adapter %entity-name%Adapter) (busobj %entity-name%))
  (let ((responsemodel (make-instance '%entity-name%ResponseModel)))
    (createresponsemodel adapter busobj responsemodel)))

(defmethod ProcessResponseList ((adapter %entity-name%Adapter) %entity-name%list)
  (mapcar (lambda (domainobj)
	    (let ((responsemodel (make-instance '%entity-name%ResponseModel)))
	      (createresponsemodel adapter domainobj responsemodel))) %entity-name%list))

(defmethod CreateAllViewModel ((presenter %entity-name%Presenter) responsemodellist)
  (mapcar (lambda (responsemodel)
	    (createviewmodel presenter responsemodel)) responsemodellist))


(defmethod CreateResponseModel ((adapter %entity-name%Adapter) (source %entity-name%) (destination %entity-name%ResponseModel))
  :description "source = %entity-name% destination = %entity-name%ResponseModel"
  (with-slots (%0% %1% %2% %3% %4% %5% %6% %7% %8% %9% %10% %11% %12% %13% %14% %15% %16% %17% %18% %19% %20% %21% %22% %23% %24% %25% %26% %27% %28% %29% %30% %31% %32% %33% %34% %35% %36% %37% vendor customer company created) destination  
    (setf %0% (slot-value source '%0%))
    (setf %1% (slot-value source '%1%))
    (setf %2% (slot-value source '%2%))
    (setf %3% (slot-value source '%3%))
    (setf %4% (slot-value source '%4%))
    (setf %5% (slot-value source '%5%))
    (setf %6% (slot-value source '%6%))
    (setf %7% (slot-value source '%7%))
    (setf %8% (slot-value source '%8%))
    (setf %9% (slot-value source '%9%))
    (setf %10% (slot-value source '%10%))
    (setf %11% (slot-value source '%11%))
    (setf %12% (slot-value source '%12%))
    (setf %13% (slot-value source '%13%))
    (setf %14% (slot-value source '%14%))
    (setf %15% (slot-value source '%15%))
    (setf %16% (slot-value source '%16%))
    (setf %17% (slot-value source '%17%))
    (setf %18% (slot-value source '%18%))
    (setf %19% (slot-value source '%19%))
    (setf %20% (slot-value source '%20%))
    (setf %21% (slot-value source '%21%))
    (setf %22% (slot-value source '%22%))
    (setf %23% (slot-value source '%23%))
    (setf %24% (slot-value source '%24%))
    (setf %25% (slot-value source '%25%))
    (setf %26% (slot-value source '%26%))
    (setf %27% (slot-value source '%27%))
    (setf %28% (slot-value source '%28%))
    (setf %29% (slot-value source '%29%))
    (setf %30% (slot-value source '%30%))
    (setf %31% (slot-value source '%31%))
    (setf %32% (slot-value source '%32%))
    (setf %33% (slot-value source '%33%))
    (setf %34% (slot-value source '%34%))
    (setf %35% (slot-value source '%35%))
    (setf %36% (slot-value source '%36%))
    (setf %37% (slot-value source '%37%))
    (setf (slot-value viewmodel 'vendor) vendor)
    (setf (slot-value viewmodel 'customer) customer)
    (setf company (slot-value source 'company))
    (setf (slot-value viewmodel 'created) created)
    destination))



(defmethod doupdate ((service %entity-name%Service) (requestmodel %entity-name%RequestModel))
  (with-slots (%0% %1% %2% %3% %4% %5% %6% %7% %8% %9% %10% %11% %12% %13% %14% %15% %16% %17% %18% %19% %20% %21% %22% %23% %24% %25% %26% %27% %28% %29% %30% %31% %32% %33% %34% %35% %36% %37% vendor customer company) requestmodel
  (let* ((%entity-name%dbservice (make-instance '%entity-name%DBService))
	 (%entity-name%dbobj (select-dbobject-from-database cust vend comp))
	 (domainobj (make-instance '%entity-name%)))
    ;; FIELD UPDATE CODE STARTS HERE 
    (when %entity-name%dbobj 
      (setf (slot-value %entity-name%dbobj '%0%) %0%)
      (setf (slot-value %entity-name%dbobj '%1%) %1%)
      (setf (slot-value %entity-name%dbobj '%2%) %2%)
      (setf (slot-value %entity-name%dbobj '%3%) %3%)
      (setf (slot-value %entity-name%dbobj '%4%) %4%)
      (setf (slot-value %entity-name%dbobj '%5%) %5%)
      (setf (slot-value %entity-name%dbobj '%6%) %6%)
      (setf (slot-value %entity-name%dbobj '%7%) %7%)
      (setf (slot-value %entity-name%dbobj '%8%) %8%)
      (setf (slot-value %entity-name%dbobj '%9%) %9%)
      (setf (slot-value %entity-name%dbobj '%10%) %10%)
      (setf (slot-value %entity-name%dbobj '%11%) %11%)
      (setf (slot-value %entity-name%dbobj '%12%) %12%)
      (setf (slot-value %entity-name%dbobj '%13%) %13%)
      (setf (slot-value %entity-name%dbobj '%14%) %14%)
      (setf (slot-value %entity-name%dbobj '%15%) %15%)
      (setf (slot-value %entity-name%dbobj '%16%) %16%)
      (setf (slot-value %entity-name%dbobj '%17%) %17%)
      (setf (slot-value %entity-name%dbobj '%18%) %18%)
      (setf (slot-value %entity-name%dbobj '%19%) %19%)
      (setf (slot-value %entity-name%dbobj '%20%) %20%)
      (setf (slot-value %entity-name%dbobj '%21%) %21%)
      (setf (slot-value %entity-name%dbobj '%22%) %22%)
      (setf (slot-value %entity-name%dbobj '%23%) %23%)
      (setf (slot-value %entity-name%dbobj '%24%) %24%)
      (setf (slot-value %entity-name%dbobj '%25%) %25%)
      (setf (slot-value %entity-name%dbobj '%26%) %26%)
      (setf (slot-value %entity-name%dbobj '%27%) %27%)
      (setf (slot-value %entity-name%dbobj '%28%) %28%)
      (setf (slot-value %entity-name%dbobj '%29%) %29%)
      (setf (slot-value %entity-name%dbobj '%30%) %30%)
      (setf (slot-value %entity-name%dbobj '%31%) %31%)
      (setf (slot-value %entity-name%dbobj '%32%) %32%)
      (setf (slot-value %entity-name%dbobj '%33%) %33%)
      (setf (slot-value %entity-name%dbobj '%34%) %34%)
      (setf (slot-value %entity-name%dbobj '%35%) %35%)
      (setf (slot-value %entity-name%dbobj '%36%) %36%)
      (setf (slot-value %entity-name%dbobj '%37%) %37%))
    

    (unless somefield
           (setf (slot-value %entity-name%dbobj '%0%) %0%)
      (setf (slot-value %entity-name%dbobj '%1%) %1%)
      (setf (slot-value %entity-name%dbobj '%2%) %2%)
      (setf (slot-value %entity-name%dbobj '%3%) %3%)
      (setf (slot-value %entity-name%dbobj '%4%) %4%)
      (setf (slot-value %entity-name%dbobj '%5%) %5%)
      (setf (slot-value %entity-name%dbobj '%6%) %6%)
      (setf (slot-value %entity-name%dbobj '%7%) %7%)
      (setf (slot-value %entity-name%dbobj '%8%) %8%)
      (setf (slot-value %entity-name%dbobj '%9%) %9%)
      (setf (slot-value %entity-name%dbobj '%10%) %10%)
      (setf (slot-value %entity-name%dbobj '%11%) %11%)
      (setf (slot-value %entity-name%dbobj '%12%) %12%)
      (setf (slot-value %entity-name%dbobj '%13%) %13%)
      (setf (slot-value %entity-name%dbobj '%14%) %14%)
      (setf (slot-value %entity-name%dbobj '%15%) %15%)
      (setf (slot-value %entity-name%dbobj '%16%) %16%)
      (setf (slot-value %entity-name%dbobj '%17%) %17%)
      (setf (slot-value %entity-name%dbobj '%18%) %18%)
      (setf (slot-value %entity-name%dbobj '%19%) %19%)
      (setf (slot-value %entity-name%dbobj '%20%) %20%)
      (setf (slot-value %entity-name%dbobj '%21%) %21%)
      (setf (slot-value %entity-name%dbobj '%22%) %22%)
      (setf (slot-value %entity-name%dbobj '%23%) %23%)
      (setf (slot-value %entity-name%dbobj '%24%) %24%)
      (setf (slot-value %entity-name%dbobj '%25%) %25%)
      (setf (slot-value %entity-name%dbobj '%26%) %26%)
      (setf (slot-value %entity-name%dbobj '%27%) %27%)
      (setf (slot-value %entity-name%dbobj '%28%) %28%)
      (setf (slot-value %entity-name%dbobj '%29%) %29%)
      (setf (slot-value %entity-name%dbobj '%30%) %30%)
      (setf (slot-value %entity-name%dbobj '%31%) %31%)
      (setf (slot-value %entity-name%dbobj '%32%) %32%)
      (setf (slot-value %entity-name%dbobj '%33%) %33%)
      (setf (slot-value %entity-name%dbobj '%34%) %34%)
      (setf (slot-value %entity-name%dbobj '%35%) %35%)
      (setf (slot-value %entity-name%dbobj '%36%) %36%)
      (setf (slot-value %entity-name%dbobj '%37%) %37%))
 
     ;;  FIELD UPDATE CODE ENDS HERE. 
    
    (setf (slot-value %entity-name%dbservice 'dbobject) %entity-name%dbobj)
    (setf (slot-value %entity-name%dbservice 'businessobject) domainobj)
    
    (setcompany %entity-name%dbservice company)
    (db-save %entity-name%dbservice)
    ;; Return the newly created UPI domain object
    (copy%entity-name%-dbtodomain %entity-name%dbobj domainobj)))


;; PROCESS THE READ REQUEST
(defmethod ProcessReadRequest ((adapter %entity-name%Adapter) (requestmodel %entity-name%RequestModel))
  :description "Adapter service method to read a single %entity-name%"
  (setf (slot-value adapter 'businessservice) (find-class '%entity-name%Service))
  (call-next-method))

(defmethod doread ((service %entity-name%Service) (requestmodel %entity-name%RequestModel))
  (let* ((comp (company requestmodel))
	 (cust (customer requestmodel))
	 (vend (vendor requestmodel))
	 (db%entity-name% (select-%entity-name% vend cust comp))
	 (%entity-name%obj (make-instance '%entity-name%)))
    ;; return back a Vpaymentmethod  response model
    (setf (slot-value %entity-name%obj 'company) comp)
    (copy%entity-name%-dbtodomain db%entity-name% %entity-name%obj)))


(defun copy%entity-name%-dbtodomain (source destination)
  (let* ((comp (select-company-by-id (slot-value source 'tenant-id)))
	 (vend (select-vendor-by-id (slot-value source 'vendor-id)))
	 (cust (select-customer-by-id (slot-value source 'cust-id) comp)))

    (with-slots (%0% %1% %2% %3% %4% %5% %6% %7% %8% %9% %10% %11% %12% %13% %14% %15% %16% %17% %18% %19% %20% %21% %22% %23% %24% %25% %26% %27% %28% %29% %30% %31% %32% %33% %34% %35% %36% %37% vendor customer company) destination
      (setf vendor vend)
      (setf customer cust)
      (setf company comp)
      (setf %0% (slot-value source '%0%))
      (setf %1% (slot-value source '%1%))
      (setf %2% (slot-value source '%2%))
      (setf %3% (slot-value source '%3%))
      (setf %4% (slot-value source '%4%))
      (setf %5% (slot-value source '%5%))
      (setf %6% (slot-value source '%6%))
      (setf %7% (slot-value source '%7%))
      (setf %8% (slot-value source '%8%))
      (setf %9% (slot-value source '%9%))
      (setf %10% (slot-value source '%10%))
      (setf %11% (slot-value source '%11%))
      (setf %12% (slot-value source '%12%))
      (setf %13% (slot-value source '%13%))
      (setf %14% (slot-value source '%14%))
      (setf %15% (slot-value source '%15%))
      (setf %16% (slot-value source '%16%))
      (setf %17% (slot-value source '%17%))
      (setf %18% (slot-value source '%18%))
      (setf %19% (slot-value source '%19%))
      (setf %20% (slot-value source '%20%))
      (setf %21% (slot-value source '%21%))
      (setf %22% (slot-value source '%22%))
      (setf %23% (slot-value source '%23%))
      (setf %24% (slot-value source '%24%))
      (setf %25% (slot-value source '%25%))
      (setf %26% (slot-value source '%26%))
      (setf %27% (slot-value source '%27%))
      (setf %28% (slot-value source '%28%))
      (setf %29% (slot-value source '%29%))
      (setf %30% (slot-value source '%30%))
      (setf %31% (slot-value source '%31%))
      (setf %32% (slot-value source '%32%))
      (setf %33% (slot-value source '%33%))
      (setf %34% (slot-value source '%34%))
      (setf %35% (slot-value source '%35%))
      (setf %36% (slot-value source '%36%))
      (setf %37% (slot-value source '%37%))
       destination)))
