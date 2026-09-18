;;; nst-tst-mult-logic.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.
;;;
;;; Moved out of core/nst-mult-logic.lisp, whose load used to end by running these
;;; checks and printing their output. Because that file is a component of the
;;; nstores system, every (ql:quickload :nstores) printed the whole demo — output
;;; nobody asked for at load time.
;;;
;;; The definitions below are byte-for-byte what the core file carried; only the
;;; runs changed, from top-level forms into functions. Load this file freely: it
;;; prints nothing until you call RUN-MULT-LOGIC-TESTS.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; ─── Demo boundary: a mock pincode service ────────────────────────

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

;; Scenario parameters (they sat among the runs in the core file; collected here with
;; the other definitions, so nothing above the runners has a side effect).
(defconstant +stock-is-good+ +true+)
(defconstant +payment-confirmed+ +true+)
(defconstant +stock-is-false+ +false+)

;;; ─── Demo boundary: a mock inventory service ──────────────────────

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

;;; ─── Checks ───────────────────────────────────────────────────────

(defun test-mult-logic-truth-tables ()
  "Print the truth tables for the operators, each annotated with its expected value."
  ;; T R U T H   T A B L E   T E S T S
  (format t "NOT +TRUE+: ~a~%" (my-not +true+)) ; -> F
  (format t "NOT +UNKNOWN+: ~a~%" (my-not +unknown+)) ; -> U
  (format t "AND +TRUE+ +UNKNOWN+: ~a~%" (my-and +true+ +unknown+)) ; -> U (Less info wins)
  (format t "AND +FALSE+ +UNKNOWN+: ~a~%" (my-and +false+ +unknown+)) ; -> F (F is dominant)
  (format t "OR +FALSE+ +UNKNOWN+: ~a~%" (my-or +false+ +unknown+)) ; -> U (More info wins)
  (format t "OR +TRUE+ +CONTRADICTION+: ~a~%" (my-or +true+ +contradiction+)) ; -> T (T is dominant)
  (values))

(defun test-mult-logic-checkout-scenarios ()
  "Run the five checkout aggregations: one per truth value, then stock-false wins."
  ;; C H E C K O U T   S C E N A R I O S

  ;; Scenario 1: Everything is perfect
  (evaluate-checkout-readiness "560001" +stock-is-good+ +payment-confirmed+)

  ;; Scenario 2: The Pincode API fails (your 10% case)
  (evaluate-checkout-readiness "999999" +stock-is-good+ +payment-confirmed+)

  ;; Scenario 3: Pincode is definitive failure (non-serviceable)
  (evaluate-checkout-readiness "000000" +stock-is-good+ +payment-confirmed+)

  ;; Scenario 4: Contradiction in Pincode check
  (evaluate-checkout-readiness "400011" +stock-is-good+ +payment-confirmed+)

  ;; Scenario 5: Stock is known to be false, Pincode is unknown
  (evaluate-checkout-readiness "999999" +stock-is-false+ +payment-confirmed+)

  (format t "~%~%This structure cleanly separates the process of DETERMINING truth (in get-pincode-api-result) from the process of DECIDING based on aggregated truth (in evaluate-checkout-readiness).")
  (values))

(defun test-mult-logic-boundary-checks ()
  "Run WITH-BOUNDARY-CHECK once per truth value: T, F, U and C."
  ;; --- RUN EXAMPLE USAGE ---
  (format t "~%--- Running Boundary Checks ---")
  (format t "~%Check 1001 (T): ~a" (funcall (handle-add-to-cart 1 1001 1)))
  (format t "~%Check 1002 (F): ~a" (funcall (handle-add-to-cart 1 1002 1)))
  (format t "~%Check 1003 (U): ~a" (funcall (handle-add-to-cart 1 1003 1)))
  (format t "~%Check 1004 (C): ~a" (funcall (handle-add-to-cart 1 1004 1)))
  (values))

(defun run-mult-logic-tests ()
  "Run the whole four-valued-logic harness.
Prints the output core/nst-mult-logic.lisp used to print at load time. Nothing calls
this automatically, so loading this file is silent."
  (test-mult-logic-truth-tables)
  (test-mult-logic-checkout-scenarios)
  (test-mult-logic-boundary-checks)
  (values))
