# PENDING WORK — deferred items, with what is needed to resume each

**Read this when:** picking up work a previous session deliberately left unfinished.
Each entry records what is **DONE** (so it is not redone), what **REMAINS**, the exact
file:line sites, and — where it applies — the decision that is blocking it.

**Ordered live defects first, then deferred features.** Entries are removed when the
work lands, not moved to an archive.

---

## 1. 🚨 Password hardening — steps 2 and 3 · **LIVE DEFECT, every existing account exposed**

### The defect being fixed

`encrypt` (`core/dod-bl-utl.lisp:825`) is **Blowfish in ECB**, an 8-byte block, and
`ironclad:encrypt-message` processes **whole blocks only** — a trailing partial block is
silently discarded. `check-password` compared that single block. Measured 2026-09-25
against a live row:

* `encrypt` of an 8-byte and of a 9-byte plaintext are **identical**;
* `Welcome1`, `Welcome12`, `Welcome1$`, `Welcome1$$` all authenticated;
* `Welcome` (7 bytes) encrypted to `""` and could never match at all.

So the effective credential was its **first 8 bytes**: any suffix was ignored, a
password shorter than 8 bytes was unusable, and ECB with no IV meant equal 8-byte
prefixes produced equal stored values. **8 call sites** verified this, across vendor,
customer and sysadmin logins.

### What is DONE (verified in the live image — do not redo)

`core/dod-bl-utl.lisp`, a new section at ~`:848`–`:1030`:

* `hash-password (plaintext salt)` — **argon2id** at the OWASP minimum (m=19456 KiB,
  t=2, p=1), stored as `argon2id$<memory>$<iterations>$<arity>$<b64 key>` = **63 chars**.
* `check-password (plaintext salt ciphertext)` — **dual format**: current argon2id, or
  legacy 16-hex Blowfish, and **fails closed** on anything else with no fallthrough.
* `password-hash-verify` — re-derives using the parameters **embedded in the stored
  value**, so raising the memory cost does not invalidate existing rows.
* `password-hash-needs-upgrade-p` — T for legacy values **and** for values whose
  embedded parameters differ from the current constants.
* `constant-time-string=` — no early exit on the first differing character.

Verified: round trip; **suffix no longer accepted**; vendor 1's real legacy value still
verifies (no lockout); unknown/short/nil/corrupt values all refused; a value written
under 4096/3 verifies and reports as needing upgrade; `dodvendlogin` still issues a
session. Measured cost **3.2 s hash / 3.2 s verify**.

### 🚨 What REMAINS — the defect is still live for every existing row

**Nothing writes the new format yet.** Confirmed live after the change: logging in with
`Welcome1XXXX` still returns an authenticated session, because vendor 1's stored value
is legacy and the legacy branch necessarily keeps the truncation.

**Step 2 — the write sites (4 places, ~1 line each).** A stored value is still computed
with `encrypt`:

| file:line | what |
|---|---|
| `core/dod-bl-utl.lisp:496` | `check&encrypt (password confirmpass salt)` |
| `customer/nst-dal-custusers.lisp:224` | `(hashed-password (encrypt password salt))` |
| `sysuser/dod-bl-usr.lisp:151` | `(encryptedpass (if password … ))` |
| `core/dod-seed-data.lisp:194,207,218,232` | dev seed fixtures (`Welcome$1`) |

Swap to `(hash-password password salt)`. Same two arguments, same slot, fits the same
column — no call-site shape changes.

**Step 3 — rehash on successful verification (the migration).** Until this lands, every
row that exists today stays weak. 8 verification sites:

`vendor/dod-ui-ven.lisp:1131,:1538,:2449` · `customer/dod-ui-cus.lisp:811,:1741,:3660`
· `sysuser/dod-ui-sys.lisp:734` · `sysuser/dod-ui-cad.lisp:379`

Add a `check-password-and-upgrade` helper taking a save-lambda, so each site becomes a
one-line change: on success, if `password-hash-needs-upgrade-p` then store
`(hash-password plaintext salt)` on that row. No password reset, no locked-out window.

### ⛔ The decision blocking steps 2–3

**3.2 seconds per login** is the honest cost of the OWASP minimum on this CPU, because
ironclad's Argon2 is **pure Lisp**, not a native library. Deliberately NOT reduced: a
smaller argon2 would be a non-compliant scheme wearing a compliant name.

* **Option A — accept 3.2 s.** Compliant, already implemented, no further work beyond
  steps 2–3. Right choice if login latency is not sensitive.
* **Option B — bcrypt at work factor ≥ 10** (OWASP's third choice, also available).
  Much faster, BUT **bcrypt requires exactly a 16-byte salt** and every row's `SALT` is
  40 chars, so it needs a derived salt and a different stored format. Only worth it if
  3.2 s is unacceptable.

### Measurements and traps, so they are not rediscovered

* `ironclad` v0.61 exposes **`argon2id`** (exported, usable), `scrypt-kdf`, `bcrypt`
  (+`bcrypt-pbkdf`), and the full `pbkdf2-hash-password` / `pbkdf2-check-password` /
  `pbkdf2-hash-password-to-combined-string` triple. **No `bcrypt` hash/verify pair.**
* Argon2id memory is expressed as **`block-count` in 128-byte blocks**: 19 MiB is
  `155648`. There is **no lanes parameter**, so p is 1 by construction.
* PBKDF2-HMAC-SHA256 at OWASP's **600,000** iterations takes **3.9 s** and produces a
  **118-character** string — which **overflows `varchar(100)`** on
  `DOD_VEND_PROFILE.PASSWORD` and `DOD_USERS.PASSWORD`. Argon2id's 63 chars does not.
* 🚨 `ironclad:pbkdf2-hash-password-to-combined-string` needs an **octet vector**, not a
  string, in this version — a string dies with *"not of type (SIMPLE-ARRAY (UNSIGNED-BYTE 8))"*.
* 🚨 **`equal` on two octet vectors is IDENTITY, not content.** Comparing derived keys
  with `equal` reports a false mismatch and makes a deterministic KDF look
  non-deterministic. Compare hex/base64 strings instead.
* `cl-base64` is available (`usb8-array-to-base64-string`); ironclad has no base64.
* `sha256`/`md5` exist but are the wrong tool; do not "fix" this with a fast hash.

### Related gaps, deliberately not touched

* **No rate limiting or account lockout on `dodvendlogin`.** OWASP's *Authentication*
  cheat sheet requires it; password *storage* is a separate concern and does not
  substitute for it.
* **`*sitepass*` (`core/dod-ini-sys.lisp:63`, compared at `sysuser/dod-ui-sys.lisp:234`)**
  is a shared hardcoded site gate using the same `encrypt`. Different mechanism, not a
  user credential — left alone on purpose.
* **`PAYMENT_API_SALT` / `PAYMENT_API_KEY`** are credentials on the vendor row with
  their own lifecycle; out of scope here.

### How to re-verify

```bash
# the section is live and the current format round-trips
python3 aiharness/deepseek/tools/swank-eval.py \
  '(let ((s "9ef9e56d14bbc1056cdb472409b228ce1e4d1f6f386cf4711f8ec8a5"))
     (let ((h (hash-password "Welcome1" s)))
       (list (length h) (check-password "Welcome1" s h) (check-password "Welcome12" s h))))'
# expect: (63 T NIL)   <- NIL on the last one is the whole point

# the defect, still live until steps 2-3 land
curl -sS -o /dev/null -c /tmp/j -X POST http://ninestores.local/hhub/dodvendlogin \
  -d 'phone=9999999990&password=Welcome1XXXX'
curl -sS -o /dev/null -w '%{http_code}\n' -b /tmp/j \
  http://ninestores.local/hhub/api/v1/vendor/profile/1     # 200 == still exploitable
```

---

## 2. Invoice settings — phase 2: remove `:invoice-settings` from `!update`

**DONE:** `!settings` pratyaya (`vendor/nst-bl-vnd.lisp`) with its own action route and
API binding — `PUT /hhub/api/v1/vendor/profile/{id}/invoice-settings`, verified end to
end. Smoke suite `test/smoke-vendor-invoice-settings-api.sh` (20 pass / 0 fail / 5 known).

**REMAINS:** `:invoice-settings` is still a declared initarg accepted by generic
`!update`, so `PUT /hhub/api/v1/vendor/profile/{id}` **writes the blob with no
validation at all**. Measured by the smoke suite (its K2): a 4330-char blob replaced by
45 characters of `((…::NO-SUCH-SECTION (:A . 1)))` with a 200 and no error anywhere.

Add `:invoice-settings` to `*vendor-update-forbidden-fields*` (`vendor/nst-bl-vnd.lisp`)
or guard it equivalently; the settings endpoint then becomes the only door. K2 in the
smoke suite flips from `KNOWN` to `PASS` when it lands — that is the acceptance check.

---

## 3. `DOD_VENDOR_SETTINGS` — the can of worms, deferred by decision

A per-vendor settings table, reviewed and rejected as premature. **Rows = 0**, so every
fix below is still free — but this expires the moment the table starts being written.

Blocking findings from the review: `SETTING_KEY` carries a **global** `UNIQUE` (making
the table hold one row per key for the whole database rather than one per vendor);
`SETTING_DEF_ID` and `VENDOR_ID` are nullable/unconstrained with no FK to
`DOD_VEND_PROFILE`; `TENANT_ID` and `DELETED_STATE` are nullable where the rest of the
schema defaults `'N'`; the definition table has no `UNIQUE(SETTING_KEY)`; and
`DOD_VENDOR_SETTINGS_DEFINITION` needs `DEFAULT_VALUE`, `IS_SENSITIVE` and an
`UPDATED_BY`/`SOURCE` audit pair before a generic settings surface is safe to publish
(a generic table destroys the response model's field-allowlist property that keeps
`password`/`salt` off the wire).

Migration mechanics: both 2026Feb versions are **recorded as applied**, so editing
`installation/upgrades/nst-dbu-vendorsettings.lisp` does nothing — this needs a **new**
registered migration.

---

## 4. `smoke-bulk-products-api.sh` has no write gate

Every other suite in `test/smoke-*.sh` defaults to read-only and requires `--write` to
mutate. This one has **no `WRITE=0` default and no `--write` flag**, and it POSTs to
`/catalog/products/bulk` and DELETEs products unconditionally — a plain run mutates the
live database. Its `BASE` was updated to `http://ninestores.local` with the rest of the
family, but it has **not been executed** since.

---

## Not a defect, but easy to trip over

* **The smoke-suite base.** `http://hunchentoot.local` answers **404 for every `/hhub/`
  URI** on this host (nginx on :80 proxies nothing) — all six suites now default to
  `http://ninestores.local`, which behaves identically to `127.0.0.1:4244`. `/hhub/`
  itself is 404 on every base, so a reachability probe on that path proves only that a
  socket opened; assert the API's own 401 instead.
* **`sed -i` changes a file's OWNER**, which silently removed the execute bit from two
  smoke scripts whose modes relied on the GROUP class (`-rw-rwxr-x` owned by
  `hunchentoot`, readable/executable by `hhubgrp`). Files created by the agent land
  `-rw------- ubuntu:ubuntu` and must be `chmod 664` + `chgrp hhubgrp` before the
  `hunchentoot` image can load them.
* **A new `hhub/**` file needs two registrations**, not one: `package/compile.lisp` and
  `nstores.asd`. A `.fasl` beside the source does NOT reach the app.
