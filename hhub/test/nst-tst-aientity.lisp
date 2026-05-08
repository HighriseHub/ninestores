;; -*- mode: common-lisp; coding: utf-8 -*-
;; nst-tst-aientity.lisp
;; TDD test stubs for DOD_PROCURE_ENTITY CRUD operations.
;; Run these interactively at the REPL after loading the system.
(in-package :nstores)

;;; ─── Fixtures ────────────────────────────────────────────────────────────────

(defun test-aientity-company ()
  "Returns a company fixture. Adjust tenant ID to match dev DB."
  (select-company-by-id 2))

(defun make-test-aientity-rm (&key (entityid "VEND-TEST-003")
                                    (entitytype "VENDOR"))
  (make-instance 'AIEntityRequestModel
                 :entityid entityid
                 :entitytype entitytype
                 :company (test-aientity-company)))

;;; ─── Create ──────────────────────────────────────────────────────────────────

(defun test-aientity-DBSave ()
  "TDD: Create a new AIEntity. Expect entity returned with matching entityid."
  (let* ((rm      (make-test-aientity-rm))
         (adapter (make-instance 'AIEntityAdapter)))
    (handler-case 
	(with-nst-debugger
	(let ((result (ProcessCreateRequest adapter rm)))
            (assert (string= (entityid result) "VEND-TEST-003")
                    nil "FAIL: entityid mismatch on create")
            (format t "PASS: test-aientity-DBSave ~A~%" (entityid result))
            result))
      (error (c)
        (error 'hhub-business-function-error
               :errstring (format t "test-aientity-DBSave FAILED: ~A" c))))))

;;; ─── Read ────────────────────────────────────────────────────────────────────

(defun test-aientity-DBRead ()
  "TDD: Read back entity by composite PK. Belnap truth must be :T."
  (let* ((rm      (make-test-aientity-rm))
         (adapter (make-instance 'AIEntityAdapter)))
    (handler-case
      (let* ((result    (ProcessReadRequest adapter rm))
             (knowledge (bo-knowledge adapter)))
        (assert (eq (bo-knowledge-truth knowledge) :T)
                nil "FAIL: Belnap truth not :T on read")
        (assert (string= (entityid result) "VEND-TEST-003")
                nil "FAIL: entityid mismatch on read")
        (format t "PASS: test-aientity-DBRead ~A~%" (entityid result))
        result)
      (error (c)
        (format t "test-aientity-DBRead FAILED: ~A~%" c)))))

;;; ─── Read All ────────────────────────────────────────────────────────────────

(defun test-aientity-DBReadAll ()
  "TDD: Fetch all entities for tenant. Expect list with at least 1 item."
  (let* ((rm      (make-test-aientity-rm))
         (adapter (make-instance 'AIEntityAdapter)))
    (handler-case
      (let ((results (ProcessReadAllRequest adapter rm)))
        (assert (listp results) nil "FAIL: result not a list")
        (assert (> (length results) 0) nil "FAIL: empty list returned")
        (format t "PASS: test-aientity-DBReadAll count=~A~%" (length results))
        results)
      (error (c)
        (format t "test-aientity-DBReadAll FAILED: ~A~%" c)))))

;;; ─── Update ──────────────────────────────────────────────────────────────────

(defun test-aientity-DBUpdate ()
  "TDD: Update entitytype to CUSTOMER. Expect updated value returned."
  (let* ((rm      (make-test-aientity-rm :entitytype "CUSTOMER"))
         (adapter (make-instance 'AIEntityAdapter)))
    (handler-case
      (let ((result (ProcessUpdateRequest adapter rm)))
        (assert (string= (entitytype result) "CUSTOMER")
                nil "FAIL: entitytype not updated")
        (format t "PASS: test-aientity-DBUpdate ~A~%" (entitytype result))
        result)
      (error (c)
        (format t "test-aientity-DBUpdate FAILED: ~A~%" c)))))

;;; ─── Delete ──────────────────────────────────────────────────────────────────

(defun test-aientity-DBDelete ()
  "TDD: Hard delete test entity. Subsequent read must return Belnap :F."
  (let* ((rm-del  (make-test-aientity-rm))
         (adapter (make-instance 'AIEntityAdapter)))
    (handler-case
      (progn
        (ProcessDeleteRequest adapter rm-del)
        ;; Verify post-delete read returns :F
        (let* ((rm-read  (make-test-aientity-rm))
               (adapter2 (make-instance 'AIEntityAdapter)))
          (ProcessReadRequest adapter2 rm-read)
          (let ((knowledge (bo-knowledge adapter2)))
            (assert (eq (bo-knowledge-truth knowledge) :F)
                    nil "FAIL: entity still found after delete")
            (format t "PASS: test-aientity-DBDelete — Belnap :F confirmed~%"))))
      (error (c)
        (format t "test-aientity-DBDelete FAILED: ~A~%" c)))))

;;; ─── Multi-Tenant Isolation ──────────────────────────────────────────────────

(defun test-aientity-tenant-isolation ()
  "TDD: Entity created under tenant 1 must NOT be visible under tenant 2."
  ;; Stub — implement when a second test tenant is available in dev DB.
  (format t "STUB: test-aientity-tenant-isolation — implement with two tenants~%"))

;;; ─── Dispatcher Route Smoke Test ─────────────────────────────────────────────

(defun test-aientity-dispatcher-readall ()
  "TDD: Dispatch :aientity/readall via context flow dispatcher."
  (handler-case
    (let* ((company (test-aientity-company))
           (params  (list :company company))
           (result  (dispatch-route :aientity/readall params
                                    :trans-func-name "test-dispatch-readall"
                                    :output-type 'json)))
      (format t "PASS: test-aientity-dispatcher-readall result=~A~%" result)
      result)
    (error (c)
      (format t "test-aientity-dispatcher-readall FAILED: ~A~%" c))))
