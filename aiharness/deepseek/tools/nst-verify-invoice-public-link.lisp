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
;;;   2. A password (four digits of a phone number) with an attempt limit — THE CUSTOMER's
;;;      phone since 2026-10-03, the VENDOR's before that.
;;;
;;; AND TWO THINGS ADDED SINCE, both in here because neither is reachable over HTTP from an
;;; agent: the SERVER-SIDE RENDER token that lets the PDF pipeline through the gate (§9),
;;; and the resolution of "which customer is this invoice's", which the password needs now
;;; that it is the customer's number (§6).
;;;
;;; ⚠ WHAT THIS FILE DOES NOT COVER: the page model itself (it needs a live HTTP request for
;;; hunchentoot:parameter), so the wiring from "customer resolved" to "gate asked" is pinned
;;; in §6b by reading the source, and the four PDF call sites are pinned by review only.
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

  ;; ── 6. THE PASSWORD: NORMALISATION, AND WHOSE NUMBER IT IS ────────────────
  ;; The stored phone is the source of truth; the customer may type the whole number or
  ;; just the last four, and both must work.
  (format t "~&=== 6. the password's digits ===~%")
  (chk "the last four of a bare number" (invoice-ext-four-digits "9999999990") "9990")
  (chk "the last four of a full number" (invoice-ext-four-digits "+91 99999 99990") "9990")
  (chk "four digits stay four" (invoice-ext-four-digits "9990") "9990")
  (chk "fewer than four is nothing" (invoice-ext-four-digits "999") nil)
  (chk "nil is nothing" (invoice-ext-four-digits nil) nil)
  (chk "letters only is nothing" (invoice-ext-four-digits "abcd") nil)
  ;; 🚨 THE PASSWORD IS THE CUSTOMER'S, NOT THE VENDOR'S (changed 2026-10-03). The vendor's
  ;; own number is printed on every invoice it issues, so it protected the invoice from
  ;; everyone EXCEPT the person who should be reading it. This section pins the source: the
  ;; gate resolves the invoice's customer and takes THAT row's phone.
  (let* ((cust (invoice-ext-customer-of-invoice invnum company))
	 (custdigits (invoice-ext-password-digits cust))
	 (vendordigits (invoice-ext-password-digits vendor)))
    (chk-true "the invoice's own customer resolves" (lambda () (and cust t)))
    (chk "the customer the gate resolves IS the header's own custid"
         (slot-value cust 'row-id)
         (slot-value (select-invoice-header-by-invnum invnum company) 'custid))
    (chk "the expected password is the last four of the CUSTOMER's phone"
         custdigits (invoice-ext-four-digits (slot-value cust 'phone)))
    (chk-true "…and it is four digits, so the gate has something to compare"
              (lambda () (and custdigits (= 4 (length custdigits)) t)))
    (format t "~&  (customer ~A -> ~A · vendor ~A -> ~A)~%"
            (slot-value cust 'name) custdigits (slot-value vendor 'name) vendordigits)
    ;; And the gate really does compare against the CUSTOMER's value: the vendor's own
    ;; digits are not accepted for a customer whose phone ends differently.
    (when (and custdigits vendordigits (not (equal custdigits vendordigits)))
      (let ((tok "NST-VERIFY-WHOSE-NUMBER-1"))
        (chk "the VENDOR's own digits are refused by the customer's gate"
             (nth-value 0 (invoice-ext-authorise tok custdigits vendordigits t)) :prompt)
        (chk "…and the customer's are then accepted"
             (nth-value 0 (invoice-ext-authorise tok custdigits custdigits t)) :granted))))

  (format t "~&=== 6b. the gate reads the customer, in the source as well ===~%")
  ;; ⚠ THESE TWO ARE SOURCE CHECKS, NOT BEHAVIOURAL ONES, AND THAT IS DELIBERATE: handing
  ;; INVOICE-EXT-PASSWORD-DIGITS a VENDOR object still ANSWERS (with the vendor's digits)
  ;; rather than erroring, so a revert to the wrong party is silent wherever the two numbers
  ;; happen to end alike. The positive half makes the negative half non-vacuous.
  (let ((src (with-open-file (s "/home/ubuntu/ninestores/hhub/invoice/nst-ui-ihd.lisp")
	       (let ((str (make-string (file-length s))))
		 (subseq str 0 (read-sequence str s))))))
    (chk-true "the page's gate resolves the INVOICE's customer"
              (lambda () (and (search "(invoice-ext-customer-of-invoice" src) t)))
    (chk "…and never hands the password check the vendor"
         (and (search "(invoice-ext-password-digits (getf grant :vendor))" src) nil)
         nil))

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
              (lambda () (null (search "9990" html))))
    ;; 🚨 AND IT MUST NAME THE RIGHT PARTY (changed 2026-10-03). A prompt that asks for the
    ;; VENDOR's number makes the customer type digits that cannot match — which spends one
    ;; of five attempts and can lock them out of their own invoice.
    (chk-true "it asks for the number the invoice was BILLED TO, not the vendor's"
              (lambda () (and (search "billed to" html)
                              (null (search "vendor's registered phone" html))
                              t))))

  ;; ── 9. THE RENDER TOKEN: THE PDF PIPELINE MUST NOT MEET THE PASSWORD WALL ──
  ;; The PDF pipeline renders an invoice by FETCHING ITS OWN PUBLIC PAGE (ext-url →
  ;; downloadhtmlfile → wkhtmltopdf). wget has no browser session and nobody to type a
  ;; password, so once the page acquired its gate the fetch came back with the PROMPT and
  ;; every PDF in the system became a picture of a four-digit form — the emailed
  ;; attachment, the vendor's Download button and the API's /download. The fix is a fifth
  ;; SIGNED field marking a server-side render token, and this section is its evidence.
  (format t "~&=== 9. the server-side render token ===~%")
  (let* ((plain-key (key-of (generate-invoice-ext-url invnum vendor company)))
	 (render-key (key-of (generate-invoice-ext-url invnum vendor company :render t))))
    (let ((plain (nth-value 0 (invoice-ext-key-parse plain-key))))
      (chk "a customer's link still parses" (and plain t) t)
      (chk "…and it is NOT a render token" (getf plain :render) nil)
      (chk "…and it is still a real key to the right invoice" (getf plain :invnum) invnum))
    (let ((tok (nth-value 0 (invoice-ext-key-parse render-key))))
      (chk "a render link parses" (and tok t) t)
      (chk "…and it IS a render token" (getf tok :render) t)
      (chk "…naming the same invoice" (getf tok :invnum) invnum))
    ;; THE MARKER IS INSIDE THE SIGNATURE, which is the whole reason it is safe: a customer
    ;; cannot add it to their own link, and cannot strip it off one of ours.
    (let* ((expires (+ (get-universal-time) 300))
	   (plain-payload (invoice-ext-key-payload invnum vendor company expires))
	   (render-payload (invoice-ext-key-payload invnum vendor company expires t)))
      ;; Read POSITIONALLY, the way the verifier reads it, rather than by searching the
      ;; text: a `(search …)` here would pass on a marker that landed in the wrong field.
      (chk "the marker is the payload's FIFTH field"
           (nth 4 (first (cl-csv:read-csv render-payload :skip-first-p t :map-fn #'identity)))
           invoice-ext-render-marker)
      (chk "a plain payload has no fifth field"
           (nth 4 (first (cl-csv:read-csv plain-payload :skip-first-p t :map-fn #'identity)))
           nil)
      (chk "ADDING the marker to a signed payload is refused"
           (nth-value 1 (invoice-ext-key-parse
                         (format nil "~A.~A"
                                 (invoice-ext-b64-encode
                                  (format nil "~A,~A" plain-payload invoice-ext-render-marker))
                                 (invoice-ext-key-signature plain-payload vendor))))
           "the link is not one this system issued")
      (chk "STRIPPING the marker off a signed payload is refused"
           (nth-value 1 (invoice-ext-key-parse
                         (format nil "~A.~A"
                                 (invoice-ext-b64-encode
                                  (subseq render-payload 0 (1- (length render-payload))))
                                 (invoice-ext-key-signature render-payload vendor))))
           "the link is not one this system issued"))
    ;; THE DECISION ITSELF, driven directly: this is the seam the page uses.
    (let ((token "NST-VERIFY-RENDER-1"))
      (chk "a render token is GRANTED with no password at all"
           (nth-value 0 (invoice-ext-authorise-grant (list :render t) token "9990" nil nil))
           :granted)
      (chk "…and it spends no attempt"
           (nth-value 2 (invoice-ext-authorise-grant (list :render t) token "9990" nil nil)) 5)
      (chk "…and a wrong password is not even consulted"
           (nth-value 0 (invoice-ext-authorise-grant (list :render t) token "9990" "1111" t))
           :granted)
      (chk "the SAME token without the marker still asks for the password"
           (nth-value 0 (invoice-ext-authorise-grant (list :render nil) token "9990" nil nil))
           :prompt)
      (chk "…and a plain NIL grant asks too, rather than being granted by accident"
           (nth-value 0 (invoice-ext-authorise-grant nil token "9990" nil nil)) :prompt)))

  ;; ── 10. THE VENDOR'S SHARE ICON: DOES IT KNOW BEFORE THE CUSTOMER DOES? ─────
  ;; The bug this section exists for: EXTERNAL_URL is a STORED link and a link lives five
  ;; minutes, so the vendor copies a dead one, sends it, and the CUSTOMER is the one who
  ;; finds out. The fix is a red icon plus a title that names the NEXT button, so the vendor
  ;; knows before sharing and can re-issue it by saving the invoice.
  (format t "~&=== 10. the vendor's share icon knows before the customer does ===~%")
  (let* ((freshkey (generate-invoice-ext-url invnum vendor company))
         (fresh freshkey)
         (dot (position #\. fresh :from-end t))
         (forged (concatenate 'string (subseq fresh 0 (1+ dot)) "deadbeef"))
         ;; THE VENDOR'S COMMONEST CASE, and the one the report was about: a link that is
         ;; simply OLD. A saved link is at least five minutes old the moment anyone looks at
         ;; it, so this — not :unusable — is what the icon usually shows.
         (expiredurl (let ((*invoice-ext-link-lifetime-seconds* -1))
                       (generate-invoice-ext-url invnum vendor company)))
         ;; The LEGACY format, built here rather than read from a row: unsigned
         ;; base64("tenant,invnum,vendor") with no expiry field. Measured 2026-10-03, the only
         ;; two non-empty EXTERNAL_URL values in tenant 2 are exactly this shape — and a live
         ;; row is the WRONG fixture, because the vendor re-saving it (which is the fix flow)
         ;; would turn the fixture valid and the check would rot into a false PASS.
         (legacy (format nil "~A/hhub/displayinvoicepublic?key=~A"
                         *siteurl*
                         (invoice-ext-b64-encode
                          (format nil "tenant-id,invnum,vendor-id~C~A,~A,~A"
                                  #\linefeed (slot-value company 'row-id) invnum
                                  (slot-value vendor 'row-id))))))
    (chk "a just-minted link reads :valid" (invoice-ext-url-status fresh) :valid)
    (chk "…and is still :valid a second before it dies"
         (invoice-ext-url-status fresh (+ (get-universal-time)
                                          (1- *invoice-ext-link-lifetime-seconds*)))
         :valid)
    (chk "…and :expired a second after"
         (invoice-ext-url-status fresh (+ (get-universal-time)
                                          (1+ *invoice-ext-link-lifetime-seconds*)))
         :expired)
    (chk "a link minted already-past its expiry reads :expired"
         (invoice-ext-url-status expiredurl) :expired)
    (chk "an empty column is :unusable" (invoice-ext-url-status "") :unusable)
    (chk "nil is :unusable" (invoice-ext-url-status nil) :unusable)
    (chk "a URL with no key at all is :unusable"
         (invoice-ext-url-status (format nil "~A/hhub/displayinvoicepublic" *siteurl*)) :unusable)
    (chk "a key with no signature is :unusable"
         (invoice-ext-url-status (format nil "~A/hhub/displayinvoicepublic?key=abcdef" *siteurl*))
         :unusable)
    ;; :UNUSABLE IS NOT A COSMETIC THIRD STATE — it is the legacy links, and the customer
    ;; would be refused. Tying the two together is the point.
    (chk "a legacy unsigned link reads :unusable" (invoice-ext-url-status legacy) :unusable)
    (chk "…and the CUSTOMER's verifier refuses it too"
         (nth-value 1 (invoice-ext-key-parse (invoice-ext-key-of-url legacy)))
         "the link is malformed")
    ;; ⚠ AND THIS FUNCTION IS NOT A GATE. A corrupted signature still carries a live expiry,
    ;; so the icon says :valid while the customer would be refused — which is exactly why the
    ;; page's authorisation stays INVOICE-EXT-KEY-PARSE and not this.
    (chk "a link with a junk signature still reads :valid…"
         (invoice-ext-url-status forged) :valid)
    (chk "…and the GATE refuses it (display is not authorisation)"
         (nth-value 1 (invoice-ext-key-parse (invoice-ext-key-of-url forged)))
         "the link is not one this system issued")
    ;; ── AND THE ICON IS RENDERED, NOT GREPPED ──────────────────────────────
    ;; The actions menu writes to *standard-output*, so the harness can capture the real
    ;; markup and assert the CLASS — a source-text check could not tell a wired colour from a
    ;; dead binding.
    (let ((cust (invoice-ext-customer-of-invoice invnum company)))
      (flet ((menu (url)
               (handler-case
                   (let ((*standard-output* (make-string-output-stream)))
                     (invoice-header-actions-menu url "DRAFT" "NST-VERIFY-SESSION" cust)
                     (get-output-stream-string *standard-output*))
                 (error (c) (format nil "RENDER-FAILED: ~A" c)))))
        (let ((okhtml (menu fresh))
              (oldhtml (menu expiredurl))
              (badhtml (menu legacy)))
          (chk-true "the actions menu renders offline"
                    (lambda () (and (search "fa-solid fa-link" okhtml) t)))
          (chk-true "a VALID link is NOT red"
                    (lambda () (null (search "text-danger" okhtml))))
          (chk-true "an EXPIRED link IS red"
                    (lambda () (and (search "fa-solid fa-link text-danger" oldhtml) t)))
          (chk-true "…and says EXPIRED, naming the control that fixes it"
                    (lambda () (and (search "EXPIRED" oldhtml) (search "press NEXT" oldhtml) t)))
          (chk-true "an UNUSABLE link IS red"
                    (lambda () (and (search "fa-solid fa-link text-danger" badhtml) t)))
          (chk-true "…and its title says what to do (press NEXT)"
                    (lambda () (and (search "press NEXT" badhtml) t)))
          (chk-true "…and a valid link's title is still the plain one"
                    (lambda () (and (search "Share LIVE Invoice Link" okhtml) t)))))))

  (format t "~&~%════════ ~D passed, ~D failed ════════~%" *pass* *fail*)
  (sb-ext:exit :code (if (zerop *fail*) 0 1)))
