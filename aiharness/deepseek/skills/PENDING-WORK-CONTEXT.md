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
```

---

## 1b. 🚨 The invoice API 500 — FIXED IN SOURCE, waiting on an image reload

### The defect

Every authenticated invoice header AND line route answered **500 internal_error**:

```
condition: the slot COM.NSTORES.APP::DELETED-STATE is missing from
           #<COM.NSTORES.APP::NSTINVHRESPONSEMODEL>
```

`domain->response` for `nst-invh` / `nst-invitm` drives its setfs from
`*invh-mirrored-slots*` / `*invitm-mirrored-slots*`, both of which name `deleted-state`,
while neither `NstInvhResponseModel` nor `NstInvitmResponseModel` declared the slot. The
load path was proven and the surface was live, so **nothing behind a session had ever
worked** — which is why it survived until a suite exercised the routes.

### What is DONE

`hhub/invoice/nst-dal-invh.lisp` and `nst-dal-invitm.lisp`: both response models now
declare `(deleted-state :initarg :deleted-state :accessor deleted-state)`. Exactly one
slot was missing per side — verified by diffing all 53 + 18 mirrored slots against both
response models. `render-json` was deliberately NOT touched, so it stays off the wire,
matching `WarehouseResponseModel`. The misleading comment in `nst-bl-invh.lisp` that
caused it ("Nothing else needs to change") is corrected.

**Verified offline TWICE, so the reload is the only remaining step and is low-risk:**

1. isolated `compile-file`: `failure-p=NIL` on both files;
2. **behaviourally**: an isolated SBCL loads `packages.lisp` + `nst-bl-adhara.lisp` + both
   DAL files and performs domain->response's exact `setf` over every mirrored slot —
   **53/53 and 18/18 clean, zero MISSING-SLOT**. Persisted as
   `aiharness/deepseek/tools/nst-invoice-mirror-check.lisp`, which reads the lists from
   source and **mutation-tested FAILS (exit 1, naming DELETED-STATE) when the slot is
   removed** — so it is not vacuous.

### ⛔ What REMAINS

**A restart, and it now carries THREE changes.** `startup/load.lisp` runs
`(ql:quickload :nstores)`, so ASDF recompiles the changed files:

1. the two DAL files (the 500 fix above);
2. `vendor/nst-bl-vndapi.lisp` — **the spec's id-less `PUT /hhub/api/v1/invoices/settings`
   is now bound** (`route-invh-settings-update`, §6.7 of
   invoice-api-handoff-CONTEXT.md): the eighth of the twelve invoice endpoints. It
   delegates to the existing `!settings` verb, so the blob keeps ONE writer, and its
   target is the session's vendor identity (`:login-vendor`) with `:row-id` forced from
   the session so the body cannot move the address; a session with no vendor identity is
   refused 401 and writes nothing.
3. `invoice/nst-bl-invhapi.lisp` — **THREE more things land here**, two of them spec
   endpoints (the ninth and tenth of the twelve):
   * `GET /hhub/api/v1/invoices/{id}/download` (`route-invh-download`) answers **302** to
     the rendered file, reusing the legacy public-page + wkhtmltopdf pipeline (the new
     entities mirror `DOD_INVOICE_HEADER`, so no new renderer is needed);
   * `GET /hhub/api/v1/invoices/{id}/public` (`route-invh-public`) returns
     `{"publicUrl": …}` — the **deterministic** shareable link. The spec's "no
     authentication required" describes the LINK, not the endpoint, so this is a
     session-scoped read and NO `:public` auth scope was needed at all;
   * `invh-guard-sort-args`, which turns a bad `?sort-by` from a **500 into the 400 it
     always should have been** (a malformed request was reporting as a crash).
   Both endpoints return 503 — not 404 — when the row names a vendor or tenant that no
   longer resolves.

The four touched source files compile clean in isolation (`failure-p=NIL`, no undefined variables), and
a static walk of the build's own file order confirms all **41** api bindings — including
the new one — follow their action-route registration, so the restart cannot fail at load
time on that rule.

```bash
sudo systemctl restart hunchentoot      # or /etc/init.d/hunchentoot restart
```

**DO NOT load the two files into the live image instead** — class redefinition in-image
is the documented PCL-wedge risk (knowledge/build-and-load-CONTEXT.md §9).

Then: `NS_PHONE=9999999990 NS_PASSWORD=Welcome1 ./hhub/test/smoke-invoice-api.sh`
(read-only; add `--write` for the lifecycle). Every route behind a session is UNRUN
until this happens, so the suite bails at section 1 with this diagnosis.

---

## 1c. 🚨 THE BUILD ORDER BROKE THE COLD BOOT — **FIXED 2026-09-26, NOT YET COMMITTED**

### The defect

A cold `(ql:quickload :nstores)` — which is exactly what a restart runs
(`startup/load.lisp`) — **aborts**:

```
There is no class named COM.NSTORES.APP::BUSINESSSERVER.
```

raised while loading `core/dod-ini-sys.lisp`, which INSTALLS A METHOD ON THAT CLASS at
load time:

```lisp
(defmethod initBusinessContexts ((server BusinessServer) ListContextNames) …)  ; line 694
```

and `BusinessServer` is defined in `core/hhub-bl-ent.lisp`. **`dod-ini-sys` was loading
FIRST.** The consequence is not a warning: `startup/load.lisp` never reaches
`(start-das)`, `init.lisp`'s `handler-case` swallows the error, and **the application
comes up with NO ACCEPTOR — the site is down.**

### Why it was invisible, and why it mattered

Commit **`d6275d0`** (2026-09-26 **09:01:11**, "Symbol DAG: load the table at boot")
**moved `(:file "core/dod-ini-sys")` from ABOVE to BELOW `hhub-bl-ent`** in both build
lists, for its own good reason — `dod-ini-sys` holds the globals every later file reads.
That crossed a load-time class dependency.

🚨 **THE RUNNING IMAGE PREDATES THAT COMMIT** (pid 1915, started **07:54**; its cached
fasls are from **00:00**). So the image is executing the OLD, WORKING order and answers
requests normally — which is precisely why nobody noticed. **The breakage would have
appeared for the first time on the next restart, as an outage with no obvious cause.**
Any "just restart it" advice given before this was found was therefore dangerous.

### What is DONE

🚨 **THE FIRST FIX WAS WRONG AND WAS REVERTED. The build lists are UNCHANGED.**
It REORDERED them — `core/hhub-bl-ent` above `core/dod-ini-sys` — and that reordering put
`hhub-bl-ent` above `core/nst-bl-beltrusys`, whose `with-bo-knowledge-check` MACRO is what
binds `payload` in its expansion. Compiled without the macro, `hhub-bl-ent`'s use became a
function call with `payload` unbound, so **every successful legacy read raised
"The variable PAYLOAD is unbound"** — which broke the vendor UI's invoice pages and the
public invoice page. (The same session had also collided a helper function name with the
legacy `select-invoice-header-by-invnum`; both are written up in
invoice-api-handoff-CONTEXT.md §1b.)

**THE FIX IS IN CODE, NOT ORDER:** the `defgeneric` and `defmethod`
**`initBusinessContexts` were MOVED OUT OF `core/dod-ini-sys.lisp` INTO
`core/hhub-bl-ent.lisp`**, beside the `BusinessServer`/`BusinessContext` classes they
specialize on. `dod-ini-sys` keeps only its runtime CALL, inside `initBusinessServer`.
A defmethod installs its specializer at LOAD time, which is why defining it in
`dod-ini-sys` (component 13) could not work when the class arrives in component 22 —
and moving the METHOD rather than the FILE satisfies that, keeps `beltrusys` before
`hhub-bl-ent` (so the macro expands), and keeps `dod-ini-sys` early for its globals.
`d6275d0`'s intent is preserved.

**VERIFIED 2026-09-26:** `STAGE: LOADED` from `../tools/nst-offline-load.lisp` (the cold
boot), the legacy read returns an `INVOICEHEADER`, and `../tools/nst-verify-invoice-dispatch.lisp`
still passes **51/0**.

**VERIFIED BY THE COLD LOAD ITSELF**, which is the closest thing to a restart available
without one:

* before the fix it aborted with the class error — reproduced TWICE, once from the
  image's fasls and once compiling the whole tree from source (so it is not a stale-fasl
  artefact);
* after the fix the same load prints `STAGE: LOADED` and the whole domain layer becomes
  available. The regression test is `../tools/nst-offline-load.lisp`.

### ⛔ What REMAINS

1. **COMMIT IT.** The fix is in the working tree only. Until it is committed, a checkout
   of `d6275d0` still carries a build that cannot boot.
2. **THE ACCEPTANCE TEST IS A REAL RESTART**, not the offline load: the offline load
   proves the tree compiles and loads in serial order, but only a restart proves
   `init.lisp` → `startup/load.lisp` → `start-das` end to end. Watch for
   `✅ HHUB Platform successfully started` and an acceptor on 4244. The Lisp transcript
   is the `~/log/hunchentoot.dribble` file (mode 600, `hunchentoot`) — NOT
   `hunchentoot.detachtty`, which holds only detachtty's own messages, and NOT
   `ninestores-apilogs.log`.
3. **A GUARD IS MISSING.** `../tools/nst-binding-order-check` catches registration/
   binding ordering, which is a DIFFERENT dependency and would not have caught this. A
   check for "does a file's load-time `defmethod` name a class defined in a later
   component?" would be the general form. Nothing has one.

---

## 1e. 🚨 THE LEGACY PUBLIC INVOICE PAGE HAS BEEN 500 SINCE AT LEAST 2026-05-23

**PRE-EXISTING. Not caused by the invoice-API work** — established by the log, not by
argument: the identical failure appears in `ninestores-messages.log` at **2026-05-23
14:47:01, 14:49:53 and 14:59:20**, months before this session, and again on 2026-09-26
during API testing.

```
ERROR SB-PCL::MISSING-SLOT :NAME COM.NSTORES.APP::INVNUM
  … (COM.NSTORES.APP::CREATE-MODEL-FOR-DISPLAYINVOICEPUBLIC)
```

`GET /hhub/displayinvoicepublic?key=<base64 tenant,invnum,vendor>` answers **500 for EVERY
invoice** — measured against three different rows (4, 23, 30) and against the public
production host. The sequence in `create-model-for-displayinvoicepublic`
(`invoice/nst-ui-ihd.lisp`) is

```lisp
(invheader (processreadrequest headeradapter hrequestmodel))
(invnum (slot-value invheader 'invnum))          ; ← MISSING-SLOT
```

so the legacy adapter is handing back an object with no `invnum` slot — a sentinel or a
different class — and the page dereferences it anyway. The legacy read path needs
diagnosing before the page can render.

### What it breaks — all of it, together

* the **customer-facing "view invoice" link**
* `com-hhub-transaction-invoice-public-pdf`, the legacy public PDF
* **the invoice email's PDF attachment**: `invoice-pdf-attachment` renders via
  `generate-invoice-ext-url` → `downloadhtmlfile` → the same page, so a vendor asking to
  email an invoice gets `hhub-business-function-error` and no mail
* the new **`GET /api/v1/invoices/{id}/download`** — bound and correct, but it renders
  through this page, so its success path returns 500 with
  `external command failed … exit status 8: wget … displayinvoicepublic?key=…`

**Fixing this page fixes all four.** The smoke suite encodes the download consequence as
its third KNOWN rather than a FAIL, precisely so this pre-existing cause is not mistaken
for a defect in the new route.

---

## 1d. 🚨 A MYSQL TRIGGER OWNS `INVNUM` — and nothing in the tree says so

### The fact

`installation/nstdbtriggers.sql`:

```sql
create trigger before_insert_invoice before insert on DOD_INVOICE_HEADER
  for each row
  begin
    declare next_id mediumint;
    select auto_increment from information_schema.tables
      where table_schema='hhubdb' and table_name='DOD_INVOICE_HEADER' into next_id;
    set NEW.INVNUM = concat('NST', lpad(next_id,5,'0'), '-', year(now()));
  end;
```

**EVERY INSERT OVERWRITES `INVNUM`**, using the table's next auto_increment — so the
number is effectively the row-id (`NST00040-2026` for row 40), zero-padded, with the
CURRENT year.

MEASURED 2026-09-26 against the live database: a create asking for `ZZMANUAL1` stores
`NST00040-2026`, and **CLSQL still reports the value it sent**, so the object in memory
and the row on disk disagree.

### 🚨 `hhubuser` CANNOT SEE IT

`SELECT COUNT(*) FROM INFORMATION_SCHEMA.TRIGGERS` returns **0** for `hhubuser`. MySQL
hides triggers from users without the TRIGGER privilege, so the schema appears to have
none — which is exactly why this looked like the database silently discarding a value.
**Do not conclude "there is no trigger" from INFORMATION_SCHEMA as this user.** The
evidence is `installation/nstdbtriggers.sql` plus the observed overwrite.

### What this invalidates — check each before trusting it

* **`make`'s placeholder is dead code.** `(format nil "NST000~A" (hhub-random-password 10))`
  in `nst-bl-invh.lisp` is overwritten on insert. So is any invnum a client sends.
* **`invoice-general-settings`' `invoice-number-format` is not used for creation.** The
  DDL default is `INV-YYYY-MM-{counter}`; nothing consults it.
* **`?exists` / duplicate-invnum `:C` reasoning is moot FOR CREATES** — the sequence
  guarantees uniqueness, so the `make :around` duplicate check can only ever fire on a
  re-used number, which the trigger prevents.
* **🚨 CLEANUP BY INVNUM PREFIX IS IMPOSSIBLE.** The invoice smoke suite tagged its rows
  with a `ZZSMOKE…` number and deleted by that prefix; the trigger discards it, so
  `--write` **leaked every row it created** (it did, twice, before this was found). Both
  the suite and `../tools/nst-verify-invoice-dispatch.lisp` now key on a
  caller-controlled field — the suite on the ROW-ID from the 201 response, the harness on
  `CUSTNAME`. Anything else that "cleans up after itself" by invoice number has the same
  bug.

---

## 2. Invoice settings — phase 2: remove `:invoice-settings` from `!update`

**DONE:** `!settings` pratyaya (`vendor/nst-bl-vnd.lisp`) with its own action route and
API binding — `PUT /hhub/api/v1/vendor/profile/{id}/invoice-settings`, verified end to
end. Smoke suite `hhub/test/smoke-vendor-invoice-settings-api.sh` (20 pass / 0 fail / 5
known).

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

## 5. `dispatch-route2` prints to stdout on EVERY API request

`hhub/core/nst-bl-conflodis2.lisp` **lines 310-311**, inside the `let*` body of
`dispatch-route2` and guarded by nothing:

```lisp
(format t "~&conflodis2: ~S → action verb ~S~%"
        route-key (route-action-verb route))
```

**Measured 2026-09-26: it is NOT conditional.** So every API dispatch on every one of
the 42 bound endpoints writes a line to the image's `*standard-output*` — which under
the deployed `detachtty` wrapper goes to `~/log/hunchentoot.detachtty` /
`hunchentoot.dribble`, not to `ninestores-apilogs.log`, so it is both noise and
easy to miss. Two consequences worth knowing: the file that would tell you which route
ran is a log nobody reads, and a per-request `format` sits in the hot path of every
call.

**REMAINS:** delete the two lines, or put them behind a variable. Deliberately NOT done
during the invoice-API session that found it: it is a core file shared by all 42
bindings, it is outside that session's objective, and it could not have been verified
live (the image was never reloaded). **It is also possible it is deliberate development
instrumentation** — nothing declares it either way, which is itself the thing to fix.

---

## 6. Compliance gaps — recorded 2026-09-26, to be worked ONE AT A TIME

Ordered as agreed. Each entry says WHAT the standard requires, WHAT was measured in this
tree, and the shape of the fix. ⚠ This is standards reasoning from the code and from
measurements taken in this session — **not an audit**: no scanner or checklist ran behind
it, and CORS, security headers, TLS config, request-size limits and PII retention in the
access logs were NOT inspected.

### 6.1 `/public` — the link's capability is not a secret, and has no expiry
**OWASP API1:2023 (BOLA).** The key was
`base64("tenant-id,invnum,vendor-id\n<tenant>,<invnum>,<vendor>")` — structured,
predictable, unsigned, no expiry, no password. Anyone holding one link could decode the
format and mint the key for ANY invoice in ANY tenant.
**AGREED FIX (2026-09-26):** a password (the VENDOR's last 4 phone digits) and a 5-minute
expiry — see §6.1a for the two things that are load-bearing.

> ### ✅ IMPLEMENTED 2026-09-26 — **NOT YET LIVE** (needs an image reload)
> Both prerequisites in §6.1a are now built, and both mechanisms are proven:
> `../tools/nst-verify-invoice-public-link.lisp` runs **74 checks, 0 failures**, offline
> against the real database. Full mechanism + seven measured traps:
> `knowledge/invoice-public-link-CONTEXT.md`.
>
> | What | Where |
> |---|---|
> | `base64url(payload).hex(hmac-sha256(payload, vendor.SALT))`; payload keeps the old CSV shape with the expiry appended | `invoice-ext-key-payload` / `-key-signature` / `-b64-encode` |
> | 5-minute lifetime inside the SIGNED bytes; expired keys say so | `*invoice-ext-link-lifetime-seconds*` (300), `invoice-ext-key-parse` |
> | Both public routes verify before reading a row | `create-model-for-displayinvoicepublic`, `create-model-for-invoice-public-pdf-url` |
> | Password = last 4 phone digits, both sides normalised to the last four digits | `invoice-ext-four-digits`, `-password-digits` |
> | Attempt limit 5, keyed by token, in memory behind a lock | `invoice-ext-authorise`, `*invoice-ext-max-attempts*`, `*invoice-ext-gate-table*` |
>
> **Three real defects were caught by that harness and fixed** — a `string-downcase` that
> made base64 decode to noise (so EVERY minted link failed verification), a `(when … (:div
> …))` that cl-who renders as Lisp (`The function :DIV is undefined`), and a `let` closing
> before the form that used its binding (`UNBOUND-VARIABLE` on every valid key). None was
> visible to the compiler.
>
> **⚠ STILL OPEN in this same area, deliberately not bundled in:**
> 1. **The rendered PDF is STILL a static file** under `/img/temp/`, named from the invoice
>    number and universal time and served unauthenticated. The *route* now verifies the key;
>    the *artifact* does not. Unchanged from the original entry.
> 2. **`:granted`/`:locked` state is per-process, in memory.** Fine for one acceptor; if
>    Hunchentoot is ever run multi-process, each process would keep its own attempt count.
> 3. **The `/public` API response does not yet report `expiresAt` / `passwordRequired`**
>    (part of the §4/§4b endpoint work, not the gate itself).
> 4. **`dodvendlogin` still has no rate limit** — §6.1a.2's second half, untouched.
> 5. **Rows 17/18/19 have `SALT` NULL and `PASSWORD` empty** — they cannot log in, so they
>    can never mint a link, and minting fails closed for them. Harmless today; it is a
>    pre-existing credential gap in those three vendor rows, not a consequence of this work.

#### 6.1a 🚨 TWO PREREQUISITES, WITHOUT WHICH THE FIX IS SECURITY THEATRE
1. **THE TOKEN MUST BE SIGNED, or the expiry is decoration.** An expiry embedded in
   base64 CSV is forgeable — an attacker simply re-encodes a later timestamp. Signed
   (HMAC over the payload with a server secret) is what makes "5 minutes" mean anything.
   It also stops a forged key naming an invoice the holder was never given.
2. **THE PASSWORD CHECK MUST BE RATE LIMITED, or 4 digits is not a password.** 10,000
   combinations, no throttling today, and the value is the vendor's own phone number —
   which the *customer* plausibly already knows. Attempt limiting is not optional here.
   (`dodvendlogin` has the same gap: NIST SP 800-63B §5.2.2 / OWASP ASVS 2.2.1.)

### 6.2 `:required-roles` is carried but NOT enforced
**OWASP API5:2023 (BFLA).** `register-action-route` accepts `:required-roles` and
`conflodis2 v1` never reads it (the code says so itself). So there is no function-level
authorization: any authenticated vendor in a tenant may call every invoice endpoint. The
vendor-settings suite already records the consequence — any vendor of the same tenant may
write a sibling's settings blob.

### 6.3 No pagination and no rate limiting
**OWASP API4:2023 · Google AIP-158.** `GET /invoices` is unbounded — measured: no
`page-size`/`page-token`/`limit`/`offset` anywhere in the invoice API. A list endpoint with
no bound is a resource-consumption vector as well as an AIP deviation.

### 6.4 Client errors answered as 500
**RFC 9110.** `api-status-for-condition` maps every condition it does not name to
`500 internal_error`, so a malformed REQUEST reports as a server fault. `?sort-by` was
fixed this session (400); a rejected settings blob is still 500 (the suite's K1). One
classifier change fixes the family.

### 6.5 No `Location` header on 201
**RFC 9110 §15.3.2** (a SHOULD). `POST /invoices` returns 201 with the resource in the body
and no `Location`. Cheap now, because the invoice has a canonical number-based URL.

### 6.6 FIPS 140 vs the pending password work — DECIDE BEFORE PENDING §1 STEPS 2–3
**argon2id is not FIPS-approved; PBKDF2 is.** If any deployment ever needs FIPS
validation, choosing now costs nothing and choosing later means re-migrating every stored
hash. ⚠ The recorded trap applies: PBKDF2 at 600k iterations yields a **118-char** value
that OVERFLOWS `varchar(100)`, so that path needs a schema change too.

### 6.7 ✅ NOT a gap: a repeat `DELETE` answering 404
Corrected 2026-09-26. The invoice suite's K2 frames this as a defect (it asserts 409
"already deleted" is the correct contract). **That framing is wrong**: DELETE is idempotent
under RFC 9110 and 404 on the second call is acceptable — arguably better than 409. K2
should be reclassified as a design choice when the suite is next edited.

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
