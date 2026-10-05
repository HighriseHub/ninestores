# Password storage — how a credential is hashed here, and why the old one was not a hash

**Read this when:** a login **succeeds with extra characters on the end of the password** · a
password **shorter than 8 characters can never be used at all** · you are choosing between
argon2id / bcrypt / PBKDF2 on this host, or asking why a login takes 3.2 seconds · you are about
to write or verify a stored password, or to compare two derived keys · **you are looking for the
half of the password work that is still open** (that half is `../PENDING-WORK-CONTEXT.md` §1).

**Status:** mechanism verified **2026-09-25** in the live image; re-checked **2026-10-05** (the
repository moved to `61554cc`, `core/dod-bl-utl.lisp` recompiled 2026-10-05 19:12 — the source
anchors below are exact at that commit).

**Applies to:** `hhub/core/dod-bl-utl.lisp`, the vendor/customer/sysadmin login paths, and any
caller of `encrypt`. The **open** work (which sites still use the old call, and the blocking
decision) is the ledger's, not this file's: `../PENDING-WORK-CONTEXT.md` §1.

---

## 1. The defect, measured — `encrypt` is not a password hash

`encrypt` (`core/dod-bl-utl.lisp:825`) is **Blowfish in ECB**, an 8-byte block, and
`ironclad:encrypt-message` processes **whole blocks only** — a trailing partial block is silently
discarded. `check-password` compared that single block. Measured 2026-09-25 against a live row:

* `encrypt` of an 8-byte and of a 9-byte plaintext are **identical**;
* `Welcome1`, `Welcome12`, `Welcome1$`, `Welcome1$$` all authenticated;
* `Welcome` (7 bytes) encrypted to `""` and could never match at all.

So the effective credential was its **first 8 bytes**: any suffix was ignored, a password shorter
than 8 bytes was unusable, and ECB with no IV meant equal 8-byte prefixes produced equal stored
values. **8 call sites** verified this, across vendor, customer and sysadmin logins.

A **16-hex Blowfish value** is what "legacy" means everywhere below.

## 2. The replacement, and what is DONE

`core/dod-bl-utl.lisp`, a new section at ~`:848`–`:1030` (verified in the live image — do not redo):

* `hash-password (plaintext salt)` — **argon2id** at the OWASP minimum (m=19456 KiB, t=2, p=1),
  stored as `argon2id$<memory>$<iterations>$<arity>$<b64 key>` = **63 chars**.
* `check-password (plaintext salt ciphertext)` — **dual format**: current argon2id, or legacy
  16-hex Blowfish, and **fails closed** on anything else with no fallthrough.
* `password-hash-verify` — re-derives using the parameters **embedded in the stored value**, so
  raising the memory cost does not invalidate existing rows.
* `password-hash-needs-upgrade-p` — T for legacy values **and** for values whose embedded
  parameters differ from the current constants.
* `constant-time-string=` — no early exit on the first differing character.

Verified: round trip; **suffix no longer accepted**; vendor 1's real legacy value still verifies
(no lockout); unknown/short/nil/corrupt values all refused; a value written under 4096/3 verifies
and reports as needing upgrade; `dodvendlogin` still issues a session. Measured cost
**3.2 s hash / 3.2 s verify**.

### What it means for the write path

The two arguments and the stored column are unchanged, so a **write site is a one-line swap**:
`(hash-password password salt)` in place of `(encrypt password salt)`. The sites that still hold
the old call, and the eight verification sites that must rehash on success via a
`check-password-and-upgrade` helper (taking a save-lambda), are tabulated in
`../PENDING-WORK-CONTEXT.md` §1 — with its **file:line** sites, because that table is the open
work and belongs to the ledger.

## 3. The cost, and the KDF choice

**3.2 seconds per login** is the honest cost of the OWASP minimum on this CPU, because ironclad's
Argon2 is **pure Lisp**, not a native library. Deliberately NOT reduced: a smaller argon2 would be
a non-compliant scheme wearing a compliant name. The decision this feeds (accept 3.2 s, or bcrypt
≥ 10 with a derived 16-byte salt because every row's `SALT` is 40 chars) is
`../PENDING-WORK-CONTEXT.md` §1 and §6.6 (FIPS: argon2id is not FIPS-approved, PBKDF2 is).

## 4. Measurements and traps — so they are not rediscovered

* `ironclad` v0.61 exposes **`argon2id`** (exported, usable), `scrypt-kdf`, `bcrypt`
  (+`bcrypt-pbkdf`), and the full `pbkdf2-hash-password` / `pbkdf2-check-password` /
  `pbkdf2-hash-password-to-combined-string` triple. **No `bcrypt` hash/verify pair.**
* Argon2id memory is expressed as **`block-count` in 128-byte blocks**: 19 MiB is `155648`. There
  is **no lanes parameter**, so p is 1 by construction.
* PBKDF2-HMAC-SHA256 at OWASP's **600,000** iterations takes **3.9 s** and produces a
  **118-character** string — which **overflows `varchar(100)`** on `DOD_VEND_PROFILE.PASSWORD` and
  `DOD_USERS.PASSWORD`. Argon2id's 63 chars does not.
* 🚨 `ironclad:pbkdf2-hash-password-to-combined-string` needs an **octet vector**, not a string, in
  this version — a string dies with *"not of type (SIMPLE-ARRAY (UNSIGNED-BYTE 8))"*.
* 🚨 **`equal` on two octet vectors is IDENTITY, not content.** Comparing derived keys with `equal`
  reports a false mismatch and makes a deterministic KDF look non-deterministic. Compare
  hex/base64 strings instead.
* `cl-base64` is available (`usb8-array-to-base64-string`); ironclad has no base64.
* `sha256`/`md5` exist but are the wrong tool; do not "fix" this with a fast hash.

## 5. How to re-verify

```bash
# the section is live and the current format round-trips.
# Evaluate this PURE form in the SLIME REPL connected to the image — no file loading:
#     (let ((s "9ef9e56d14bbc1056cdb472409b228ce1e4d1f6f386cf4711f8ec8a5"))
#       (let ((h (hash-password "Welcome1" s)))
#         (list (length h) (check-password "Welcome1" s h) (check-password "Welcome12" s h))))
# expect: (63 T NIL)   <- NIL on the last one is the whole point
# NOTE: tools/swank-eval.py was DELETED on 2026-09-26 — driving the image's Swank from an
# agent parked a worker thread in the debugger and left class definition wedged for the
# life of the process (knowledge/build-and-load-CONTEXT.md §9). A pure form typed into
# the human's own REPL is safe; never load a file into the live image from outside it.

# the defect, still live until steps 2-3 land
curl -sS -o /dev/null -c /tmp/j -X POST http://ninestores.local/hhub/dodvendlogin \
  -d 'phone=9999999990&password=Welcome1XXXX'
curl -sS -o /dev/null -w '%{http_code}\n' -b /tmp/j \
  http://ninestores.local/hhub/api/v1/vendor/profile/1     # 200 == still exploitable
# cheap DB-side confirmation, measured 2026-10-05: until steps 2-3 land the answer to both
# is 0, against 15 vendor rows and 5 user rows —
#   SELECT COUNT(*) FROM DOD_VEND_PROFILE WHERE PASSWORD LIKE 'argon2id$%';
#   SELECT COUNT(*) FROM DOD_USERS        WHERE PASSWORD LIKE 'argon2id$%';
```

## 6. Related gaps that are NOT storage

**Owned by the ledger, deliberately not restated here:** no rate limiting or account lockout on
`dodvendlogin` (OWASP *Authentication* / NIST SP 800-63B §5.2.2); `*sitepass*`
(`core/dod-ini-sys.lisp:63`, compared at `sysuser/dod-ui-sys.lisp:234`) — a shared hardcoded site
gate using the same `encrypt`, not a user credential; and `PAYMENT_API_SALT` / `PAYMENT_API_KEY`,
which have their own lifecycle on the vendor row. All three are listed as open items in
`../PENDING-WORK-CONTEXT.md` §1.
