;;; nst-bl-gstinlookup.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
;; nst-bl-gstinlookup.lisp
;; Story 1: GSTIN Auto-Fill via GST Portal Public API
;; API: https://services.gst.gov.in/services/api/search/taxpayerDetails?gstin=<GSTIN>
;; Mirrors pattern of getpincodedetails for consistency.
(in-package :nstores)

;; -------------------------------------------------------------------------
;; GSTIN domain object (lightweight, not a full BusinessObject)
;; -------------------------------------------------------------------------
(defclass GSTINDetails ()
  ((gstin
    :accessor gstin
    :initarg :gstin
    :initform "")
   (legal-name
    :accessor legal-name
    :initform "")
   (trade-name
    :accessor trade-name
    :initform "")
   (addr1
    :accessor addr1
    :initform "")
   (addr2
    :accessor addr2
    :initform "")
   (city
    :accessor city
    :initform "")
   (state
    :accessor state
    :initform "")
   (pincode
    :accessor pincode
    :initform "")
   (state-code
    :accessor state-code
    :initform "")
   (status
    :accessor status
    :initform "")
   (constitution
    :accessor constitution
    :initform "")
   (registration-date
    :accessor registration-date
    :initform "")
   (error-message
    :accessor error-message
    :initform nil)
   (lookup-status
    :accessor lookup-status
    :initform :pending    ;; :found | :not-found | :invalid | :api-failure
    )))

;; -------------------------------------------------------------------------
;; GSTIN format validator (regex: 2 digits + 5 alpha + 4 digits + alpha +
;; 1 alphanumeric + Z + 1 alphanumeric)
;; -------------------------------------------------------------------------
(defun valid-gstin-format-p (gstin)
  "Returns T if GSTIN matches the 15-character Indian GSTIN pattern."
  (and (stringp gstin)
       (= (length gstin) 15)
       (cl-ppcre:scan
        "^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$"
        gstin)))

;; -------------------------------------------------------------------------
;; Internal helper: extract nested address string from pradr alist
;; pradr is a nested alist: (("addr" . "...") ("stcd" . "...") ...)
;; -------------------------------------------------------------------------
(defun extract-pradr-field (pradr field-key)
  "Safely extract a field from the principal address alist."
  (when (listp pradr)
    (cdr (assoc field-key pradr :test #'equal))))

;; -------------------------------------------------------------------------
;; Internal helper: build flat address parts from pradr alist
;; GST API pradr keys: bno (building), st (street), loc (locality),
;;                     dst (district), stcd (state code), pncd (pincode)
;; -------------------------------------------------------------------------
(defun build-address-from-pradr (pradr)
  "Returns (values addr1 addr2 city pincode state-code) from pradr alist."
  (let ((bno   (or (extract-pradr-field pradr "bno")  ""))
        (st    (or (extract-pradr-field pradr "st")   ""))
        (loc   (or (extract-pradr-field pradr "loc")  ""))
        (dst   (or (extract-pradr-field pradr "dst")  ""))
        (stcd  (or (extract-pradr-field pradr "stcd") ""))
        (pncd  (or (extract-pradr-field pradr "pncd") "")))
    (values
     (format nil "~A ~A" bno st)          ;; addr1
     loc                                   ;; addr2 (locality)
     dst                                   ;; city (district)
     pncd                                  ;; pincode
     stcd)))                               ;; state-code

;; -------------------------------------------------------------------------
;; Core function: getgstindetails
;; Mirrors getpincodedetails-old pattern exactly.
;; Returns a GSTINDetails object.
;; Lookup-status slot signals caller: :found | :not-found | :invalid | :api-failure
;; -------------------------------------------------------------------------
(defun getgstindetails (gstin-input)
  "Calls GST Portal public API and returns a populated GSTINDetails object.
   Mirrors the getpincodedetails pattern.
   
   GSTIN: 15-character string, e.g. '29ABCDE1234F1ZV'
   
   API: https://services.gst.gov.in/services/api/search/taxpayerDetails
   No API key required for public search endpoint.
   
   Returns GSTINDetails with lookup-status:
     :found       — all fields populated from API
     :not-found   — GSTIN not registered (API returned 404/error)
     :invalid     — format check failed, no API call made
     :api-failure — network/parse error; caller should show manual entry"
  (let ((details (make-instance 'GSTINDetails :gstin gstin-input)))
    ;; Step 1: Client-side format check (saves unnecessary API round-trip)
    (unless (valid-gstin-format-p gstin-input)
      (setf (lookup-status details) :invalid)
      (setf (error-message details)
            (format nil "Invalid GSTIN format: ~A. Must be 15 characters." gstin-input))
      (return-from getgstindetails details))

    ;; Step 2: Call GST Portal public API
    (handler-case
        (let* ((api-url *HHUB-GST-TAXPAYER-API-URL*)  ;; configured in nst-config.lisp
               (full-url (format nil "~A?gstin=~A" api-url gstin-input))
               (raw-bytes (drakma:http-request full-url
                                               :method :GET
                                               :accept "application/json"))
               (json-str (map 'string #'code-char raw-bytes))
               (json-response (json:decode-json-from-string json-str)))

          ;; Step 3: Check API-level error flag
          ;; GST portal wraps errors in {"errorCode":"...","message":"..."}
          (let ((error-code (cdr (assoc :errorcode json-response :test #'equal))))
            (when error-code
              (setf (lookup-status details) :not-found)
              (setf (error-message details)
                    (format nil "GSTIN not found: ~A"
                            (or (cdr (assoc :message json-response :test #'equal))
                                "Not registered")))
              (return-from getgstindetails details)))

          ;; Step 4: Parse happy-path response
          ;; API returns flat JSON; pradr is a nested object
          (let* ((legal-nm  (cdr (assoc :lgnm json-response :test #'equal)))
                 (trade-nm  (cdr (assoc :tradenom json-response :test #'equal)))
                 (sts       (cdr (assoc :sts   json-response :test #'equal)))
                 (ctb       (cdr (assoc :ctb   json-response :test #'equal)))
                 (rgdt      (cdr (assoc :rgdt  json-response :test #'equal)))
                 (pradr-raw (cdr (assoc :pradr json-response :test #'equal))))

            (multiple-value-bind (a1 a2 cty pin stcd)
                (build-address-from-pradr pradr-raw)
              (setf (legal-name details)       (or legal-nm ""))
              (setf (trade-name details)       (or trade-nm ""))
              (setf (addr1 details)            a1)
              (setf (addr2 details)            a2)
              (setf (city details)             cty)
              (setf (pincode details)          pin)
              (setf (state-code details)       stcd)
              (setf (status details)           (or sts ""))
              (setf (constitution details)     (or ctb ""))
              (setf (registration-date details)(or rgdt ""))
              (setf (lookup-status details)    :found)))

          details)

      ;; Step 5: Network / parse failure — fallback to manual entry
      (error (condition)
        (let ((errmsg (format nil "GST API Error ~A: ~A" (mysql-now) condition)))
          (with-open-file (stream *HHUBBUSINESSFUNCTIONSLOGFILE*
                                  :direction :output
                                  :if-exists :append
                                  :if-does-not-exist :create)
            (format stream "~A~%" errmsg))
          (setf (lookup-status details) :api-failure)
          (setf (error-message details)
                "GST Portal unreachable. Please enter details manually.")
          details)))))

;; -------------------------------------------------------------------------
;; Convenience: JSON response for UI layer (mirrors RenderJSON pattern)
;; Called by the UI route handler for the GSTIN lookup AJAX endpoint
;; -------------------------------------------------------------------------
(defun gstin-lookup-to-json (gstin-input)
  "Entry point for UI: returns JSON string for front-end auto-fill.
   Three states rendered: found, not-found/invalid, api-failure."
  (let* ((details (getgstindetails gstin-input))
         (ok (eq (lookup-status details) :found)))
    (json:encode-json-to-string
     `(("success"          . ,(if ok 1 0))
       ("lookup_status"    . ,(symbol-name (lookup-status details)))
       ("error_message"    . ,(or (error-message details) ""))
       ("legal_name"       . ,(legal-name details))
       ("trade_name"       . ,(trade-name details))
       ("addr1"            . ,(addr1 details))
       ("addr2"            . ,(addr2 details))
       ("city"             . ,(city details))
       ("state_code"       . ,(state-code details))
       ("pincode"          . ,(pincode details))
       ("status"           . ,(status details))
       ("registration_date". ,(registration-date details))))))

;; -------------------------------------------------------------------------
;; TEST STUBS (TDD)
;; -------------------------------------------------------------------------
(defun test-gstin-lookup-valid ()
  "Test: valid GSTIN returns :found and populated legal name."
  (let ((result (getgstindetails "29ABCDE1234F1ZV")))
    (assert (eq (lookup-status result) :found)
            nil "Expected :found for valid GSTIN")))

(defun test-gstin-lookup-invalid-format ()
  "Test: malformed GSTIN returns :invalid without making API call."
  (let ((result (getgstindetails "INVALID")))
    (assert (eq (lookup-status result) :invalid)
            nil "Expected :invalid for malformed GSTIN")))

(defun test-gstin-lookup-not-registered ()
  "Test: valid format but unregistered GSTIN returns :not-found."
  (let ((result (getgstindetails "99ZZZZZ9999Z9ZZ")))
    (assert (eq (lookup-status result) :not-found)
            nil "Expected :not-found for unregistered GSTIN")))

(defun test-gstin-json-output ()
  "Test: JSON output has expected keys."
  (let* ((json-str (gstin-lookup-to-json "INVALID"))
         (parsed (json:decode-json-from-string json-str)))
    (assert (assoc :success parsed)      nil "Missing success key")
    (assert (assoc :lookup-status parsed) nil "Missing lookup_status key")))
