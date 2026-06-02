;;; nst-bl-vaisettings.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;;; ----------------------------
;;;; Vendor setting registry
;;;; ----------------------------

(defparameter *vendor-setting-registry*
  '((:key nst.vendor.invoicesetting.send-invoice-email-after-paid
     :domain :invoice
     :data-type :boolean
     :description "Send invoice email immediately after payment"
     :keywords ("send" "email" "invoice" "paid"))

    (:key nst.vendor.invoicesetting.attach-pdf-to-invoice-email
     :domain :invoice
     :data-type :boolean
     :description "Attach invoice PDF to email"
     :keywords ("attach" "pdf" "invoice" "email"))))


;;;; ----------------------------
;;;; Intent CLOS class
;;;; ----------------------------

(defclass intent ()
  ((actor       :initarg :actor       :accessor intent-actor)
   (domain      :initarg :domain      :accessor intent-domain)
   (operation   :initarg :operation   :accessor intent-operation)
   (description :initarg :description :accessor intent-description)
   (raw-text    :initarg :raw-text    :accessor intent-raw-text)
   (trace       :initarg :trace       :accessor intent-trace)))


(defun make-intent (&key actor domain operation description raw-text trace)
  (make-instance 'intent
                 :actor actor
                 :domain domain
                 :operation operation
                 :description description
                 :raw-text raw-text
                 :trace trace))


(defparameter prompt-for-llm "You are an intent extraction engine for a Common Lisp system.

Your task:
- Convert user text into a structured intent object.
- Do NOT infer system-specific identifiers.
- Do NOT guess setting keys.
- Do NOT execute actions.
- Preserve the user's words faithfully.

Return output ONLY as a Common Lisp property list.

Schema (MANDATORY):
(:actor <number>
 :domain <keyword>
 :operation <keyword>
 :description <string>
 :raw-text <string>
 :trace ((:origin . <keyword>)
         (:session . <string>)))

Rules:
- :actor is always a number.
- :domain must be a single keyword.
- :operation must be one keyword.
- :description is a short normalized summary.
- :raw-text is %user-input%.
- If uncertain, choose the most likely domain but NEVER invent new fields.
- No explanations.
- No markdown.")


(defun build-llm-prompt (text user-input)
  (setf text (cl-ppcre:regex-replace-all "%user-input%" text user-input))
  text)
 
;;;; ----------------------------
;;;; Naive LLM stub
;;;; Replace later with real LLM
;;;; ----------------------------

(defun llm->intent (text)
  (let* ((prompt (build-llm-prompt prompt-for-llm text))
         (response (ollama-generate prompt))
         (plist (read-from-string response)))
    (apply #'make-intent plist)))


;;;; ----------------------------
;;;; Scoring & resolution
;;;; ----------------------------

(defun tokenize (text)
  (mapcar #'string-downcase
          (split-sequence:split-sequence #\Space text)))

(defun score-setting (intent setting)
  (let* ((intent-tokens (tokenize (intent-description intent)))
         (keywords (getf setting :keywords))
         (matches (count-if (lambda (k)
                              (member k intent-tokens :test #'string=))
                            keywords)))
    (/ (float matches) (max 1 (length keywords)))))




(defun resolve-setting (intent)
  (let ((candidates
          (mapcar (lambda (s)
                    (list :key (getf s :key)
                          :score (score-setting intent s)
                          :data-type (getf s :data-type)))
                  *vendor-setting-registry*)))
    (sort candidates #'> :key (lambda (c) (getf c :score)))))


(defun select-setting (candidates)
  (let ((top (first candidates)))
    (cond
      ((>= (getf top :score) 0.9)
       top)
      ((>= (getf top :score) 0.7)
       (list :needs-confirmation candidates))
      (t
       (list :ambiguous candidates)))))


;;;; ----------------------------
;;;; Execution layer
;;;; ----------------------------

(defun execute-setting (&key vendor-id setting-key value data-type context-id trace)
  ;; type validation
  (unless (typep value
                 (ecase data-type
                   (:boolean 'boolean)
                   (:number 'number)
                   (:string 'string)
                   (:json 'list)))
    (error "Invalid value type"))

  ;; placeholder for real persistence
  (format t "~%[EXECUTE] vendor=~A key=~A value=~A context=~A trace=~A~%"
          vendor-id setting-key value context-id trace)

  t)


(defun build-execution-context (intent resolved-setting value)
  (execute-setting
   :vendor-id (intent-actor intent)
   :setting-key (getf resolved-setting :key)
   :value value
   :data-type (getf resolved-setting :data-type)
   :context-id (cdr (assoc :session (intent-trace intent)))
   :trace (intent-trace intent)))


;;;; ----------------------------
;;;; Orchestration
;;;; ----------------------------

(defun run-intent (text)
  (let* ((intent (llm->intent text))
         (candidates (resolve-setting intent))
         (decision (select-setting candidates)))
    (cond
      ((eq (first decision) :needs-confirmation)
       decision)
      ((eq (first decision) :ambiguous)
       decision)
      (t
       (build-execution-context intent decision t)))))


;;;; ----------------------------
;;;; Example
;;;; ----------------------------

;; (run-intent  "set vendor invoice setting send email after invoice payment is done")
