;;; nst-verify-invoice-public-link.lisp --- verify the PUBLIC INVOICE LINK's signature,
;;; expiry and password gate, offline, against the real database.
;;;
;;;   cd /home/ubuntu/ninestores
;;;   # ONE-TIME setup - see nst-offline-load.lisp's header for the four blockers
;;;   # (deps first, swank first, writable clsql dist, fresh cache).
;;;   XDG_CACHE_HOME=/tmp/nst-fresh-cache sbcl --noinform --non-interactive --load <this file>
;;;
;;; Exit 0 = pass. 1 = fail.
;;;
;;; ── WHAT THIS PINS DOWN, AND WHY OFFLINE ────────────────────────────────────
;;; The public link was an UNSIGNED base64 of "tenant,invnum,vendor" with no expiry and
;;; no password: a customer holding one link could mint the key for any invoice in any
;;; tenant, and the expiry the business asked for would have been decorative, since an
;;; attacker can re-encode a later timestamp. Two mechanisms were added on 2026-09-26 and
;;; this file is the evidence for both:
;;;
;;;   1. HMAC-SHA256 over the payload, keyed with the VENDOR'S OWN SALT, plus a
;;;      five-minute expiry carried INSIDE the signed bytes.
;;;   2. A password (the vendor's last four phone digits) with an attempt limit.
;;;
;;; Neither can be tested through HTTP without reloading the live image, which an agent
;;; cannot restart here (sudo is refused). INVOICE-EXT-AUTHORISE therefore takes the
;;; submitted password and the request method as ARGUMENTS rather than reading the live
;;; request, which is what makes the whole gate drivable from this file. That was a design
;;; choice made FOR this test, not discovered afterwards.
;;;
;;; IT WRITES NOTHING: no invoice row is created, changed or deleted. The gate table is
;;; in-memory and this script uses its own token strings, so it cannot collide with a live
;;; customer's state.

(load "~/quicklisp/setup.lisp")
(push "/home/ubuntu/ninestores/hhub/" asdf:*central-registry*)
(push #p"/tmp/nst-asdf/clsql-dist/clsql-20221106-git/" asdf:*central-registry*)
(ql:quickload :swank :silent t)
(dolist (s '(:uuid :secure-random :drakma :cl-json :cl-who :hunchentoot :clsql
             :clsql-mysql :cl-smtp :parenscript :cl-async :cl-csv :cl-base64
             :priority-queue :blackbird :cl-yaml))
  (ignore-errors (ql:quickload s :silent t)))
(ql:quickload :nstores :silent t)
(in-package :nstores)

(defparameter *pass* 0)
(defparameter *fail* 0)

(defun chk (name got want)
  (if (equal got want)
      (progn (incf *pass*) (format t "~&  PASS ~A~%" name))
      (progn (incf *fail*)
             (format t "~&  FAIL ~A~%        got  ~S~%        want ~S~%" name got want))))

(defun chk-true (name thunk)
  "THUNK, not a quoted form: eval() has no lexical environment, so a form naming a
   LET-bound variable reports UNBOUND-VARIABLE and the check silently never runs."
  (handler-case (if (funcall thunk)
                    (progn (incf *pass*) (format t "~&  PASS ~A~%" name))
                    (progn (incf *fail*) (format t "~&  FAIL ~A -> NIL~%" name)))
    (error (c) (incf *fail*) (format t "~&  FAIL ~A -> signalled ~A~%" name c))))

(defun key-of (url)
  "The token out of a minted URL."
  (let ((i (search "key=" url)))
    (and i (subseq url (+ i 4)))))

(crm-db-connect :strdb "hhubdb" :strusr "hhubuser" :strpwd "Welcome$123"
                :servername "127.0.0.1" :strdbtype :mysql)
(format t "~&connected.~%")

(let* ((company (select-company-by-id 2))
       (vendor (select-vendor-by-id 1))
       (invnum "NST00023-2024"))
  (format t "~&=== 0. the pieces are real ===~%")
  (chk-true "company 2 resolves" (lambda () (and company t)))
  (chk-true "vendor 1 resolves" (lambda () (and vendor t)))
  (chk "vendor 1 phone" (and (phone vendor) t) t)
  (chk "invoice-ext-authorise is fbound" (and (fboundp 'invoice-ext-authorise) t) t)
  (chk "the lifetime is five minutes" *invoice-ext-link-lifetime-seconds* 300)
  (chk "the attempt limit is five" *invoice-ext-max-attempts* 5)

  ;; ── 1. MINTING ────────────────────────────────────────────────────────────
  (format t "~&=== 1. a minted link ===~%")
  (let* ((url (generate-invoice-ext-url invnum vendor company))
         (key (key-of url)))
    (chk-true "minting returns a URL" (lambda () (and (stringp url) t)))
    (chk-true "it carries a key" (lambda () (and key (plusp (length key)) t)))
    ;; URL-SAFE, because the link is built by FORMAT with no percent-encoding.
    (chk-true "the key is URL-safe (no + / =)"
              (lambda () (null (find-if (lambda (c) (find c "+/=")) key))))
    (chk "it has exactly one separator dot" (count #\. key) 1)
    (let* ((dot (position #\. key :from-end t))
           (b64 (subseq key 0 dot))
           (sig (subseq key (1+ dot))))
      (chk "the signature is 64 hex chars" (length sig) 64)
      (chk-true "the signature is all hex"
                (lambda () (every (lambda (c) (digit-char-p c 16)) sig)))
      (chk-true "the payload base64-decodes" (lambda () (and (invoice-ext-b64-decode b64) t)))
      (chk-true "the payload still leads with the old header"
                (lambda () (and (search "tenant-id,invnum,vendor-id" (invoice-ext-b64-decode b64)) t))))

    ;; ── 2. A GOOD KEY VERIFIES, AND ROUND-TRIPS ─────────────────────────────
    (format t "~&=== 2. verification ===~%")
    (multiple-value-bind (grant reason) (invoice-ext-key-parse key)
      (chk "a fresh key verifies (reason is nil)" reason nil)
      (chk-true "it yields a grant" (lambda () (and grant t)))
      (chk "the invnum round-trips" (getf grant :invnum) invnum)
      (chk "the vendor round-trips" (and (getf grant :vendor) t) t)
      (chk "the company round-trips" (and (getf grant :company) t) t)
      (chk-true "the expiry is ~5 minutes out"
                (lambda () (let ((d (- (getf grant :expires-at) (get-universal-time))))
                             (and (<= 290 d) (<= d 300))))))

    ;; ── 3. THE FORGERY THIS EXISTS TO STOP ─────────────────────────────────
    ;; THE decisive check. The old key was structured and unsigned, so this payload is
    ;; exactly what an attacker would write by hand: a later expiry, same invoice.
    (format t "~&=== 3. forgery is refused ===~%")
    (let* ((forged-payload (invoice-ext-key-payload invnum vendor company
                                                   (+ (get-universal-time) 86400)))
           (r (subseq key (position #\. key :from-end t))))   ; the real .signature
      (multiple-value-bind (g why)
          (invoice-ext-key-parse (concatenate 'string (invoice-ext-b64-encode forged-payload) r))
        (chk "a re-encoded payload with a later expiry is refused" g nil)
        (chk "and it says why" why "the link is not one this system issued")))

    ;; A flipped character in the signature must fail too (catches a comparison that
    ;; ignores its input, e.g. one that always returns true).
    (let* ((dot (position #\. key :from-end t))
           (sig (subseq key (1+ dot)))
           (bad (concatenate 'string (subseq key 0 (1+ dot))
                             (if (char= (char sig 0) #\a) "b" "a") (subseq sig 1))))
      (multiple-value-bind (g why) (invoice-ext-key-parse bad)
        (chk "a corrupted signature is refused" g nil)
        (chk "with the forgery reason" why "the link is not one this system issued")))

    ;; ANOTHER VENDOR'S SALT MUST NOT SIGN THIS PAYLOAD — the cross-tenant case.
    (let* ((other (select-vendor-by-id 2))
           (payload (invoice-ext-key-payload invnum vendor company (+ (get-universal-time) 300)))
           (wrong-sig (invoice-ext-key-signature payload other)))
      (chk-true "vendor 2 exists to sign with" (lambda () (and other t)))
      (chk-true "the two salts differ"
                (lambda () (not (equal (slot-value vendor 'salt) (slot-value other 'salt)))))
      ;; ⚠ THE DOT IS PART OF THE TEST. Without it the key is malformed, so the refusal
      ;; check passes for entirely the wrong reason and proves nothing about the signature.
      (multiple-value-bind (g why)
          (invoice-ext-key-parse (concatenate 'string (invoice-ext-b64-encode payload)
                                             "." wrong-sig))
        (chk "a token signed with ANOTHER vendor's salt is refused" g nil)
        (chk "with the forgery reason" why "the link is not one this system issued")))

    ;; ── 4. MALFORMED AND ABSENT KEYS ARE ANSWERS, NOT 500s ────────────────
    (format t "~&=== 4. rubbish in, a sentence out ===~%")
    (chk "no key at all" (nth-value 1 (invoice-ext-key-parse nil)) "no link was supplied")
    (chk "an empty key" (nth-value 1 (invoice-ext-key-parse "")) "no link was supplied")
    (chk "no separator dot" (nth-value 1 (invoice-ext-key-parse "abcdef")) "the link is malformed")
    (chk "a trailing dot" (nth-value 1 (invoice-ext-key-parse "abcdef.")) "the link is malformed")
    (chk "undecodable base64"
         (nth-value 1 (invoice-ext-key-parse "!!!!.deadbeef")) "the link is malformed")
    (chk "a payload with too few fields"
         (nth-value 1 (invoice-ext-key-parse
                       (concatenate 'string (invoice-ext-b64-encode "only,three,fields") ".deadbeef")))
         "the link is malformed"))

  ;; ── 5. EXPIRY ─────────────────────────────────────────────────────────────
  (format t "~&=== 5. expiry is enforced and is inside the signature ===~%")
  (let ((*invoice-ext-link-lifetime-seconds* -1))
    (let* ((key (key-of (generate-invoice-ext-url invnum vendor company))))
      (multiple-value-bind (g why) (invoice-ext-key-parse key)
        (chk "an expired key is refused" g nil)
        (chk-true "and the reason mentions expiry"
                  (lambda () (and (search "expired" why) t))))))

  ;; ── 6. THE PASSWORD: NORMALISATION ────────────────────────────────────────
  ;; The vendor's stored phone is the source of truth; the customer may type the whole
  ;; number or just the last four, and both must work.
  (format t "~&=== 6. the password's digits ===~%")
  (chk "the last four of a bare number" (invoice-ext-four-digits "9999999990") "9990")
  (chk "the last four of a full number" (invoice-ext-four-digits "+91 99999 99990") "9990")
  (chk "four digits stay four" (invoice-ext-four-digits "9990") "9990")
  (chk "fewer than four is nothing" (invoice-ext-four-digits "999") nil)
  (chk "nil is nothing" (invoice-ext-four-digits nil) nil)
  (chk "letters only is nothing" (invoice-ext-four-digits "abcd") nil)
  (chk "vendor 1's expected password" (invoice-ext-password-digits vendor) "9990")

  ;; ── 7. THE GATE ───────────────────────────────────────────────────────────
  ;; Keys are per-token; these strings are this script's own, so no live customer's
  ;; state is touched.
  (format t "~&=== 7. the password gate ===~%")
  ;; ⚠ ONE CALL PER SCENARIO. An earlier version of this section wrote
  ;; (nth-value 1 (invoice-ext-authorise …)) and then (nth-value 2 (invoice-ext-authorise …))
  ;; — two calls where the author saw one. Every call spends an attempt, so the counters
  ;; drifted, the fifth-guess check locked four guesses early, and the FAILURE WAS IN THE
  ;; TEST, not the gate. GATE binds the whole multiple-value list from a SINGLE call.
  (flet ((gate (tok expected submitted is-post)
           (multiple-value-list (invoice-ext-authorise tok expected submitted is-post))))
    (let ((*invoice-ext-max-attempts* 5))

      ;; ── a customer who gets it right, and stays right ───────────────────
      (let ((tok "NST-VERIFY-GATE-A"))
        (let ((r (gate tok "9990" nil nil)))
          (chk "a fresh token asks for the password" (nth 0 r) :prompt)
          (chk "and offers all five attempts" (nth 2 r) 5)
          (chk "and shows no error yet" (nth 1 r) nil))
        ;; A GET must NEVER spend an attempt, or an attacker locks the real customer out
        ;; by simply reloading the page.
        (dotimes (i 8) (gate tok "9990" nil nil))
        (chk "eight GETs spend nothing" (nth 2 (gate tok "9990" nil nil)) 5)
        (chk "the right password is accepted" (nth 0 (gate tok "9990" "9990" t)) :granted)
        (chk "once granted it stays granted" (nth 0 (gate tok "9990" nil nil)) :granted)
        ;; A wrong password AFTER success must not revoke: a customer with a second tab
        ;; open would otherwise lose the page they are already reading.
        (chk "a later wrong password does not revoke"
             (nth 0 (gate tok "9990" "1111" t)) :granted))

      ;; ── the limit that makes four digits mean anything ──────────────────
      (let ((tok "NST-VERIFY-GATE-B"))
        (let ((r (gate tok "9990" "1111" t)))
          (chk "a wrong password is refused" (nth 0 r) :prompt)
          (chk "and it says so" (nth 1 r) "that password is not correct")
          (chk "and the first attempt is spent" (nth 2 r) 4))
        ;; Junk must spend an attempt too, or a script sending nonsense never trips the
        ;; limit — and tripping the limit is the entire defence.
        (chk "junk spends an attempt as well" (nth 2 (gate tok "9990" "not-a-number" t)) 3)
        (chk "the third leaves two" (nth 2 (gate tok "9990" "1111" t)) 2)
        (chk "the fourth leaves one" (nth 2 (gate tok "9990" "1111" t)) 1)
        (chk "the fifth locks it" (nth 0 (gate tok "9990" "1111" t)) :locked)
        (chk "and the reason says why"
             (nth 1 (gate tok "9990" "1111" t)) "too many incorrect attempts on this link")
        ;; LOCKED MEANS LOCKED: the correct password must not reopen it, or the limit is
        ;; a delay rather than a limit.
        (chk "the correct password does not reopen a locked token"
             (nth 0 (gate tok "9990" "9990" t)) :locked)
        (chk "and it reports zero attempts left" (nth 2 (gate tok "9990" "9990" t)) 0))

      ;; ── the customer who types the vendor's whole number ────────────────
      (let ((tok "NST-VERIFY-GATE-C"))
        (chk "a full phone number is accepted as the password"
             (nth 0 (gate tok "9990" "+91 99999 99990" t)) :granted))

      ;; ── an empty form field is not a guess ──────────────────────────────
      (let ((tok "NST-VERIFY-GATE-D"))
        (chk "a blank POST still prompts" (nth 0 (gate tok "9990" "" t)) :prompt)
        (chk "and spends no attempt" (nth 2 (gate tok "9990" "" t)) 5)
        (chk "and reports no error" (nth 1 (gate tok "9990" "" t)) nil)
        (chk "a GET with no password also spends nothing"
             (nth 2 (gate tok "9990" nil t)) 5))

      ;; ── the wrong password is never echoed back ─────────────────────────
      (let ((tok "NST-VERIFY-GATE-E"))
        (chk-true "the reason does not contain the guess"
                  (lambda () (null (search "4242"
                                           (or (nth 1 (gate tok "9990" "4242" t)) ""))))))))

  (format t "~&=== 8. the form the customer sees ===~%")
  (let* ((key "TESTKEY.SIG")
         (thunk (invoice-ext-password-prompt-thunk key "that password is not correct" 3))
         ;; ⚠ CL-WHO EMITS SINGLE-QUOTED ATTRIBUTES (`class='x'`), measured in this
         ;; tree. The first version of this section asserted `name="password"` and failed
         ;; against correct code; normalising the quotes tests the MARKUP rather than
         ;; cl-who's quoting convention.
         (html (substitute #\" #\' (funcall thunk))))
    (chk-true "the prompt returns HTML" (lambda () (and (stringp html) (plusp (length html)) t)))
    (chk-true "it posts, rather than putting the password in a URL"
              (lambda () (and (search "method=\"POST\"" html) t)))
    (chk-true "the password field is named `password`"
              (lambda () (and (search "name=\"password\"" html) t)))
    (chk-true "the password field is a password field"
              (lambda () (and (search "type=\"password\"" html) t)))
    (chk-true "it carries the token back in the action"
              (lambda () (and (search (format nil "key=~A" key) html) t)))
    (chk-true "it shows the failure it was given"
              (lambda () (and (search "not correct" html) t)))
    (chk-true "it shows the attempts left"
              (lambda () (and (search "3 attempt" html) t)))
    ;; The prompt must never contain the answer.
    (chk-true "it does NOT reveal the expected digits"
              (lambda () (null (search "9990" html)))))

  (format t "~&~%════════ ~D passed, ~D failed ════════~%" *pass* *fail*)
  (sb-ext:exit :code (if (zerop *fail*) 0 1)))
