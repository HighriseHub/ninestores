;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)


;;;; Belnap Four-Valued Logic (FDE) Implementation for E-commerce Decision Making

;; 1. Define the Four Truth Values
(defconstant +true+         :T     "Truth Only (P is true, not false)")
(defconstant +false+        :F     "False Only (P is false, not true)")
(defconstant +unknown+      :U     "Unknown (Missing information, API failure)")
(defconstant +contradiction+ :C     "Contradiction (Conflicting information)")

;; Helper macro for concisely checking for the four values
(defmacro case-truth (truth &body clauses)
  "A specialized CASE macro for logic values."
  `(case ,truth
     ((+true+ :T) ,@(cdr (assoc :T clauses)))
     ((+false+ :F) ,@(cdr (assoc :F clauses)))
     ((+unknown+ :U) ,@(cdr (assoc :U clauses)))
     ((+contradiction+ :C) ,@(cdr (assoc :C clauses)))
     (otherwise (error "Invalid truth value: ~a" ,truth))))

;; --- LOGIC OPERATORS ---

;; 2. NOT Operator (my-not)
;; Truth Table: T -> F, F -> T, U -> U, C -> C
(defun my-not (p)
  "Implements the logical NOT operator for FDE logic."
  (case-truth p
    (:T +false+)
    (:F +true+)
    (:U +unknown+)
    (:C +contradiction+)))

;; 3. AND Operator (my-and)
;; Defined by the intersection of information states (less information wins)
(defun my-and (p q)
  (cond
    ((or (eq p +false+) (eq q +false+)) +false+)
    ((eq p +true+) q)
    ((eq q +true+) p)
    ((and (eq p +unknown+) (eq q +unknown+)) +unknown+)
    ((and (eq p +contradiction+) (eq q +contradiction+)) +contradiction+)
    ((or (and (eq p +unknown+) (eq q +contradiction+))
         (and (eq p +contradiction+) (eq q +unknown+)))
     +false+)
    (t (error "Unhandled AND case: ~a, ~a" p q))))

;; 4. OR Operator (my-or)
;; Defined by the union of information states (more information wins)
(defun my-or (p q)
  "Implements the logical OR operator for FDE logic.
   (Based on the join operation of the Truth lattice.)"
  (cond
    ;; If either P or Q is T, the result is T (T is dominant)
    ((or (eq p +true+) (eq q +true+)) +true+)
    ;; If one is F, the result is the other one (F is identity)
    ((eq p +false+) q)
    ((eq q +false+) p)
    ;; Remaining cases: U, C, (U OR U), (C OR C), (U OR C)
      ((and (eq p +unknown+) (eq q +unknown+)) +unknown+)
      ((and (eq p +contradiction+) (eq q +contradiction+)) +contradiction+)
      ;; If one is U and the other is C, FDE treats this as True (T)
      ;; because C contains True information.
      ((or (and (eq p +unknown+) (eq q +contradiction+))
           (and (eq p +contradiction+) (eq q +unknown+))) +true+)
      (t (error "Unhandled OR case: ~a, ~a" p q))))

(defun knowledge-meet (p q)
  "Intersection of knowledge (common certainty)."
  (cond
    ((or (eq p +unknown+) (eq q +unknown+)) +unknown+)
    ((or (eq p +true+) (eq q +true+)) +true+)
    ((or (eq p +false+) (eq q +false+)) +false+)
    ((or (eq p +contradiction+) (eq q +contradiction+)) +contradiction+)
    (t +unknown+)))

(defun knowledge-join (a b)
  "Combines knowledge states from two sources (union of knowledge)."
  (cond
    ;; If either is contradiction, the result stays contradiction.
    ((or (eq a +contradiction+) (eq b +contradiction+)) +contradiction+)
    ;; Contradiction arises if one says true and the other false.
    ((and (eq a +true+) (eq b +false+)) +contradiction+)
    ((and (eq a +false+) (eq b +true+)) +contradiction+)
    ;; Otherwise, prefer the more informative one.
    ;; If either is known (T or F), pick that.
    ((eq a +true+) +true+)
    ((eq b +true+) +true+)
    ((eq a +false+) +false+)
    ((eq b +false+) +false+)
    ;; If both are unknown, stays unknown.
    ((and (eq a +unknown+) (eq b +unknown+)) +unknown+)
    ;; Default fallback.
    (t +unknown+)))

(defmacro with-knowledge-check (api-call &body knowledge-clauses)
  `(multiple-value-bind (payload status) ,api-call
     (let ((knowledge status))
       (case-truth knowledge
         (:U ,@(cdr (assoc :U knowledge-clauses)))
         (:T ,@(cdr (assoc :T knowledge-clauses)))
         (:F ,@(cdr (assoc :F knowledge-clauses)))
         (:C ,@(cdr (assoc :C knowledge-clauses)))
         (otherwise (error "Invalid knowledge value: ~a" knowledge))))))


(defun merge-payloads (p1 p2)
  "Merge two payloads intelligently.
   If both are equal, return one.
   If one is NIL, return the other.
   If they differ, return a list of both to mark conflict."
  (cond
    ((equal p1 p2) p1)
    ((null p1) p2)
    ((null p2) p1)
    (t (list :conflict p1 p2))))

(defun merge-knowledge (result1 result2)
  "Merges two boundary results of the form (STATUS PAYLOAD)
   according to Belnap knowledge ordering.
   Returns a new (STATUS PAYLOAD) pair."
  (destructuring-bind (status1 payload1) result1
    (destructuring-bind (status2 payload2) result2
      (let* ((merged-status (knowledge-join status1 status2))
             (merged-payload (merge-payloads payload1 payload2)))
        ;; If payloads conflict, escalate status to :C
        (when (and (listp merged-payload)
                   (eq (car merged-payload) :conflict))
          (setf merged-status +contradiction+))
        (list merged-status merged-payload)))))

(defun merge-knowledge* (&rest results)
  (reduce #'merge-knowledge results))


(defmacro with-boundary-check (api-call &body status-clauses)
  "Enforces clean architecture by requiring explicit handling of all four 
   TCUF states (T, F, U, C) whenever calling an external/unreliable API 
   or boundary function. The API-CALL must return two values: (PAYLOAD STATUS).
   The result payload is made available to all status clauses under the
   variable name 'payload', and the status is available as 'status'."
  (let ((payload-sym (gensym "PAYLOAD"))
        (status-sym (gensym "STATUS"))
	(source-sym (gensym "SOURCE")))
    ;; 1. Use multiple-value-bind to unpack the two return values (data and status)
    ;; We use GENSYMs here to prevent name clashes with other variables, 
    ;; but the subsequent LET makes them available to the user clauses.
    `(destructuring-bind (,status-sym ,payload-sym ,source-sym) ,api-call
       ;; 2. Make the unpacked values available to the user's clauses
       (let ((payload ,payload-sym)  ;; User can access this as 'payload'
             (status ,status-sym) ;; User can access this as 'status'
	     (source ,source-sym))  ;; User can access this as 'source' 
         ;; 3. Enforce the required status handling using the pre-defined case-truth
         (case-truth status
           ;; We manually map the :KEY to the user-supplied body:
           (:T ,@(cdr (assoc :T status-clauses)))
           (:F ,@(cdr (assoc :F status-clauses)))
           (:U ,@(cdr (assoc :U status-clauses)))
           (:C ,@(cdr (assoc :C status-clauses)))
           (otherwise (error "Boundary function returned invalid status: ~a" status)))))))


(defmacro with-db-call (db-form &optional (source "DB/Unknown"))
  (let ((results-list-gs (gensym "RESULTS"))
        (payload-gs      (gensym "PAYLOAD"))
        (error-gs        (gensym "ERROR"))
        (backtrace-gs    (gensym "BACKTRACE")))
    `(handler-case
         (let* ((,results-list-gs (multiple-value-list ,db-form))
                (,payload-gs      (car ,results-list-gs)))
           (cond
             ;; C — Contradiction: More than 1 result
             ((> (length ,results-list-gs) 1)
              (make-instance 'bo-knowledge
                             :truth :C
                             :payload ,results-list-gs
                             :provenance ,source))

             ;; F — No result
             ((null ,payload-gs)
              (make-instance 'bo-knowledge
                             :truth :F
                             :payload nil
                             :provenance ,source))

             ;; T — Success
             (t
              (make-instance 'bo-knowledge
                             :truth :T
                             :payload ,payload-gs
                             :provenance ,source))))

       (error (,error-gs)
         (let ((,backtrace-gs (sb-debug:list-backtrace)))
           ;; LOGGING HERE
           (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE*
                                   :direction :output
                                   :if-exists :append
                                   :if-does-not-exist :create)
             (format stream "~A~A"
                     (format nil "Database Error (~A): ~A~%"
                             (mysql-now)
                             ,error-gs)
                     ,backtrace-gs))

           ;; return U
           (make-instance 'bo-knowledge
                          :truth :U
                          :payload nil
                          :provenance ,source))))))

(defun tcuf-value-checker (value)
  "Adapter function that performs the simple, deterministic T/F check."
  (if value (list :T value) (list :F nil)))

(defmacro with-non-null-check (value-form &body body)
  "A specialized version of WITH-BOUNDARY-CHECK for deterministic null checks.
   If the value-form is non-NIL (Status :T), the BODY is executed with the value 
   bound to the variable PAYLOAD.
   If the value-form is NIL (Status :F), the macro returns an explicit :VALUE-MISSING 
   signal immediately."
  (let ((value-sym (gensym "VALUE")))
    `(let ((,value-sym ,value-form))
       (with-boundary-check (tcuf-value-checker ,value-sym)
         (:T (let ((payload ,value-sym))
               ,@body))
         (:F (progn
               (format t "~&[Internal Check] Missing value detected. Aborting sequence.")
               :value-missing)) ; Returns a specific failure signal
         (:U (error "Should not happen in tcuf-value-checker"))
         (:C (error "Should not happen in tcuf-value-checker"))))))



;; --- E-COMMERCE EXAMPLE: Pincode Check ---

(defun get-pincode-api-result (pincode)
  "Simulates the external API call and maps its output to a 4-valued truth value."
  (cond
    ;; Case 1: Ideal Success (90% of the time)
    ((string= pincode "560001")
     (values +true+ "Bangalore" "Bangalore" "Karnataka"))

    ;; Case 2: Definitive Failure (Pincode exists, but is permanently non-serviceable)
    ((string= pincode "000000")
     (values +false+ "N/A" "N/A" "N/A"))

    ;; Case 3: API Service Failure (Your 10% case) - Returns UNKNOWN
    ((string= pincode "999999")
     (values +unknown+ "NOT FOUND" "NOT FOUND" "NOT FOUND"))

    ;; Case 4: Contradiction (Internal data bug)
    ;; Assume local DB lists it as valid, but the external API returns an error status
    ;; that means "invalid" but also provides a city name.
    ((string= pincode "400011")
     ;; In a real system, this would be determined by combining two sources.
     ;; For simulation, we manually return the conflicting state:
     (values +contradiction+ "Mumbai" "Mumbai" "Maharashtra"))
    
    ;; Default to F for any other unknown pincode
    (t (values +false+ "N/A" "N/A" "N/A"))))

(defun evaluate-checkout-readiness (pincode stock-status payment-verified)
  "Evaluates the final checkout decision based on multiple FDE truth values."
  (let* ((pincode-status (nth-value 0 (get-pincode-api-result pincode)))
         (final-status (my-and pincode-status (my-and stock-status payment-verified))))
    (format t "~%--- EVALUATION FOR PINCODE: ~a ---" pincode)
    (format t "~%Pincode Status:   ~a" pincode-status)
    (format t "~%Stock Status:    ~a" stock-status)
    (format t "~%Payment Status:  ~a" payment-verified)
    (format t "~%Combined Status: ~a" final-status)
    
    (case-truth final-status
      (:T (format t "~%-> DECISION: FULL PURCHASE APPROVED. Proceed to payment."))
      
      (:F (format t "~%-> DECISION: BLOCKED. One or more factors were definitely false."))
      
      (:U (format t "~%-> DECISION: SOFT BLOCK. Missing data (API failure). Requires manual review or customer fallback."))
      
      (:C (format t "~%-> DECISION: CRITICAL ERROR. Data contradiction detected. INVESTIGATE IMMEDIATELY.")))))

;; --- RUN EXAMPLES ---

;; T R U T H   T A B L E   T E S T S
(format t "NOT +TRUE+: ~a~%" (my-not +true+)) ; -> F
(format t "NOT +UNKNOWN+: ~a~%" (my-not +unknown+)) ; -> U
(format t "AND +TRUE+ +UNKNOWN+: ~a~%" (my-and +true+ +unknown+)) ; -> U (Less info wins)
(format t "AND +FALSE+ +UNKNOWN+: ~a~%" (my-and +false+ +unknown+)) ; -> F (F is dominant)
(format t "OR +FALSE+ +UNKNOWN+: ~a~%" (my-or +false+ +unknown+)) ; -> U (More info wins)
(format t "OR +TRUE+ +CONTRADICTION+: ~a~%" (my-or +true+ +contradiction+)) ; -> T (T is dominant)

;; C H E C K O U T   S C E N A R I O S
(defconstant +stock-is-good+ +true+)
(defconstant +payment-confirmed+ +true+)

;; Scenario 1: Everything is perfect
(evaluate-checkout-readiness "560001" +stock-is-good+ +payment-confirmed+)

;; Scenario 2: The Pincode API fails (your 10% case)
(evaluate-checkout-readiness "999999" +stock-is-good+ +payment-confirmed+)

;; Scenario 3: Pincode is definitive failure (non-serviceable)
(evaluate-checkout-readiness "000000" +stock-is-good+ +payment-confirmed+)

;; Scenario 4: Contradiction in Pincode check
(evaluate-checkout-readiness "400011" +stock-is-good+ +payment-confirmed+)

;; Scenario 5: Stock is known to be false, Pincode is unknown
(defconstant +stock-is-false+ +false+)
(evaluate-checkout-readiness "999999" +stock-is-false+ +payment-confirmed+)

(format t "~%~%This structure cleanly separates the process of DETERMINING truth (in get-pincode-api-result) from the process of DECIDING based on aggregated truth (in evaluate-checkout-readiness).")


;; Continuation of previous file: four_valued_logic.lisp

;; --- ARCHITECTURAL ENFORCER MACRO ---




;; --- EXAMPLE BOUNDARY FUNCTION (MOCK EXTERNAL CALL) ---

(defun external-inventory-check (product-id)
  "Mocks an inventory microservice call. Must return payload and status."
  (case product-id
    ;; Happy path: Found, Confirmed
    (1001 (list :T 5 "Inventory")) 
    ;; Definitive failure: Item discontinued
    (1002 (list :F 0 "Inventory"))
    ;; Network failure: API timeout, unable to connect
    (1003 (list :U nil "Inventory")) 
    ;; Contradiction: Internal inventory system says 10, warehouse DB says -5
    (1004 (list :C nil "Inventory"))
    ;; Any other
    (otherwise (list :F 0 "Inventory"))))

;; --- USAGE EXAMPLE IN DDD APPLICATION LAYER ---

(defun handle-add-to-cart (user-id product-id quantity)
  "The application service layer function that orchestrates the boundary check."
  (with-boundary-check (external-inventory-check product-id)
    (format T "This is the payload - ~A. This is source - ~A" payload source)
    ;; Required handlers for all four states:
    (:T (lambda () 
          (format nil "SUCCESS: For user ~d Adding ~a units to cart for Product ~a. (Inventory Count: ~a)" 
                  user-id quantity product-id 
                  (nth-value 0 (external-inventory-check product-id)))))
    (:F (lambda () 
          (format nil "FAILURE: Product ~a is permanently discontinued." product-id)))
    (:U (lambda () 
          (format nil "PENDING: Inventory check timed out. Placing order on hold for later review. Customer notified.")))
    (:C (lambda () 
          (format nil "CRITICAL ERROR: Internal inventory data conflict for Product ~a. Blocking transaction and alerting SRE." product-id)))))

;; --- RUN EXAMPLE USAGE ---

(format t "~%--- Running Boundary Checks ---")
(format t "~%Check 1001 (T): ~a" (funcall (handle-add-to-cart 1 1001 1)))
(format t "~%Check 1002 (F): ~a" (funcall (handle-add-to-cart 1 1002 1)))
(format t "~%Check 1003 (U): ~a" (funcall (handle-add-to-cart 1 1003 1)))
(format t "~%Check 1004 (C): ~a" (funcall (handle-add-to-cart 1 1004 1)))

