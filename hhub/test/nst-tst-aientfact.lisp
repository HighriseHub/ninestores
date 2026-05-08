;; -*- mode: common-lisp; coding: utf-8 -*-
;; nst-tst-aientfact.lisp
;; TDD test stubs for DOD_PROCURE_ENTITY_FACT CRUD + versioning contracts.
(in-package :nstores)

;;; ─── Fixtures ────────────────────────────────────────────────────────────────

(defparameter *tst-fact-entity-id*  "VEND-TEST-001")
(defparameter *tst-fact-key*        "com.test.vendor.identity.email")
(defparameter *tst-fact-val-v1*     "v1@test.com")
(defparameter *tst-fact-val-v2*     "v2-corrected@test.com")

(defun test-aientfact-company ()
  (select-company-by-id 2))

(defun make-test-aientfact-rm (&key
                                 (entityid  *tst-fact-entity-id*)
                                 (factkey   *tst-fact-key*)
                                 (factval   *tst-fact-val-v1*)
                                 (facttype  "string")
                                 (sourcetype "HUMAN_ENTERED")
                                 (confidence 1.0)
                                 (assertedby "test-harness"))
  (make-instance 'AIEntityFactRequestModel
                 :entityid   entityid
                 :factkey    factkey
                 :factval    factval
                 :facttype   facttype
                 :sourcetype sourcetype
                 :confidence confidence
                 :assertedby assertedby
                 :company    (test-aientfact-company)))

;;; ─── Create ──────────────────────────────────────────────────────────────────

(defun test-aientfact-DBSave ()
  "TDD: Create a fact. Verify rowid assigned, VALID_TO is NIL (live)."
  (let* ((rm      (make-test-aientfact-rm))
         (adapter (make-instance 'AIEntityFactAdapter)))
    (handler-case
      (let ((result (ProcessCreateRequest adapter rm)))
        (assert (not (null (rowid result)))
                nil "FAIL: rowid not assigned")
        (assert (null (validto result))
                nil "FAIL: new fact should have VALID_TO = NIL")
        (assert (string= (factval result) *tst-fact-val-v1*)
                nil "FAIL: factval mismatch")
        (format t "PASS: test-aientfact-DBSave rowid=~A~%" (rowid result))
        result)
      (error (c)
        (format t "test-aientfact-DBSave FAILED: ~A~%" c)))))

;;; ─── Read (Belnap :T) ────────────────────────────────────────────────────────

(defun test-aientfact-DBRead ()
  "TDD: Read live fact. Belnap truth must be :T."
  (let* ((rm      (make-test-aientfact-rm))
         (adapter (make-instance 'AIEntityFactAdapter)))
    (handler-case
      (let* ((result    (ProcessReadRequest adapter rm))
             (knowledge (bo-knowledge adapter)))
        (assert (eq (bo-knowledge-truth knowledge) :T)
                nil "FAIL: Belnap truth not :T")
        (assert (null (validto result))
                nil "FAIL: live fact has non-nil VALID_TO")
        (format t "PASS: test-aientfact-DBRead fact=~A~%" (factkey result))
        result)
      (error (c)
        (format t "test-aientfact-DBRead FAILED: ~A~%" c)))))

;;; ─── Read All ────────────────────────────────────────────────────────────────

(defun test-aientfact-DBReadAll ()
  "TDD: ReadAll for entity. Expect at least one live fact."
  (let* ((rm      (make-test-aientfact-rm))
         (adapter (make-instance 'AIEntityFactAdapter)))
    (handler-case
      (let ((results (ProcessReadAllRequest adapter rm)))
        (assert (listp results) nil "FAIL: not a list")
        (assert (> (length results) 0) nil "FAIL: empty fact list")
        ;; All returned rows must be live (VALID_TO = NIL)
        (dolist (r results)
          (assert (null (validto r))
                  nil (format nil "FAIL: expired row in ReadAll result: ~A" (factkey r))))
        (format t "PASS: test-aientfact-DBReadAll count=~A~%" (length results))
        results)
      (error (c)
        (format t "test-aientfact-DBReadAll FAILED: ~A~%" c)))))

;;; ─── Update = Expire + Insert ────────────────────────────────────────────────

(defun test-aientfact-DBUpdate ()
  "TDD: Update fact. Old row gains VALID_TO. New row is live with new value."
  (let* ((rm-v2   (make-test-aientfact-rm :factval *tst-fact-val-v2*))
         (adapter (make-instance 'AIEntityFactAdapter)))
    (handler-case
      (let ((new-fact (ProcessUpdateRequest adapter rm-v2)))
        (assert (string= (factval new-fact) *tst-fact-val-v2*)
                nil "FAIL: new factval mismatch")
        (assert (null (validto new-fact))
                nil "FAIL: new fact row should be live (VALID_TO = NIL)")
        ;; Verify old row is expired
        (let* ((tenant-id (%tenant-id-from-company (test-aientfact-company)))
               (history   (select-fact-history *tst-fact-entity-id*
                                               *tst-fact-key* tenant-id)))
          (assert (= (length history) 2) nil
                  (format nil "FAIL: expected 2 history rows, got ~A" (length history)))
          (let ((expired (find-if (lambda (r)
                                    (not (null (slot-value r 'valid-to)))) history)))
            (assert expired nil "FAIL: no expired row found in history")))
        (format t "PASS: test-aientfact-DBUpdate v2 live, v1 expired~%")
        new-fact)
      (error (c)
        (format t "test-aientfact-DBUpdate FAILED: ~A~%" c)))))

;;; ─── Delete = Soft Expiry Only ───────────────────────────────────────────────

(defun test-aientfact-DBDelete ()
  "TDD: Soft-delete. VALID_TO set. Subsequent read returns Belnap :F."
  (let* ((rm      (make-test-aientfact-rm))
         (adapter (make-instance 'AIEntityFactAdapter)))
    (handler-case
      (progn
        (ProcessDeleteRequest adapter rm)
        ;; Post-delete read must yield :F
        (let* ((adapter2 (make-instance 'AIEntityFactAdapter))
               (rm2      (make-test-aientfact-rm)))
          (ProcessReadRequest adapter2 rm2)
          (let ((knowledge (bo-knowledge adapter2)))
            (assert (eq (bo-knowledge-truth knowledge) :F)
                    nil "FAIL: fact still live after soft-delete")
            (format t "PASS: test-aientfact-DBDelete — Belnap :F confirmed~%"))))
      (error (c)
        (format t "test-aientfact-DBDelete FAILED: ~A~%" c)))))

;;; ─── Validation Guards ───────────────────────────────────────────────────────

(defun test-aientfact-invalid-source-type ()
  "TDD: Invalid SOURCE_TYPE must signal an error — not silently write."
  (let* ((rm (make-test-aientfact-rm :sourcetype "MADE_UP_SOURCE"))
         (adapter (make-instance 'AIEntityFactAdapter)))
    (handler-case
      (progn
        (ProcessCreateRequest adapter rm)
        (format t "FAIL: should have errored on bad source type~%"))
      (error (c)
        (format t "PASS: test-aientfact-invalid-source-type caught: ~A~%" c)))))

(defun test-aientfact-confidence-out-of-range ()
  "TDD: Confidence < 0.4 must be rejected."
  (let* ((rm (make-test-aientfact-rm :confidence 0.1))
         (adapter (make-instance 'AIEntityFactAdapter)))
    (handler-case
      (progn
        (ProcessCreateRequest adapter rm)
        (format t "FAIL: should have rejected confidence 0.1~%"))
      (error (c)
        (format t "PASS: test-aientfact-confidence-out-of-range caught: ~A~%" c)))))

;;; ─── Immutability Verification ───────────────────────────────────────────────

(defun test-aientfact-immutability ()
  "TDD: Verify no physical row is deleted or overwritten. Row count must only grow."
  (let* ((tenant-id (%tenant-id-from-company (test-aientfact-company)))
         (before    (length (select-fact-history
                              *tst-fact-entity-id* *tst-fact-key* tenant-id)))
         (rm        (make-test-aientfact-rm :factval "immutability-test"))
         (adapter   (make-instance 'AIEntityFactAdapter)))
    (ProcessUpdateRequest adapter rm)
    (let ((after (length (select-fact-history
                           *tst-fact-entity-id* *tst-fact-key* tenant-id))))
      (assert (> after before) nil
              "FAIL: row count did not increase — update may have overwritten")
      (format t "PASS: test-aientfact-immutability before=~A after=~A~%"
              before after))))

;;; ─── Multi-tenant Isolation ──────────────────────────────────────────────────

(defun test-aientfact-tenant-isolation ()
  "TDD STUB: Facts from tenant 1 must not be readable by tenant 2."
  (format t "STUB: test-aientfact-tenant-isolation — implement with two tenants~%"))

;;; ─── Dispatcher Route Smoke Test ─────────────────────────────────────────────

(defun test-aientfact-dispatcher-read ()
  "TDD: Smoke test the :aientfact/read dispatcher route end-to-end."
  (handler-case
    (let* ((company (test-aientfact-company))
           (params  (list :entityid *tst-fact-entity-id*
                          :factkey  *tst-fact-key*
                          :company  company))
           (result  (dispatch-route :aientfact/read params
                                    :trans-func-name "test-dispatch-fact-read"
                                    :output-type 'json)))
      (format t "PASS: test-aientfact-dispatcher-read result=~A~%" result)
      result)
    (error (c)
      (format t "test-aientfact-dispatcher-read FAILED: ~A~%" c))))
