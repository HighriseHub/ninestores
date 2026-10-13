# PENDING WORK — deferred items, with what is needed to resume each

**Read this when:** you are resuming work a previous session deliberately left unfinished — you need the ONE place that lists what is still OPEN, the exact `file:line` site, and the decision blocking it — or you are about to redo something already DONE.

**Status:** ledger re-checked **2026-10-05** against the live database, the git tree and the running image; findings are dated inline. **Ordered live defects first, then deferred features.** Entries are removed when the work lands, not moved to an archive. §-numbers (§1, §1b, §1c…) are stable — other files cite them by name (`README.md`: *"PENDING WORK §1c"*).

**Applies to:** `hhub/`, `installation/`, `aiharness/deepseek/`, the vendor/customer/sysadmin login paths. **Enter here when resuming anything a previous session left unfinished.**

**The image, measured 2026-10-05:** pid 3010 started **19:12:41**, cache fasls rewritten 19:12–19:13, `hhub/` clean against `HEAD` (`61554cc`) → **the server serves the current source, so every "waiting on an image reload" item below is resolved.** Acceptor probe: `GET /hhub/api/v1/invoices` → **401**.

---

## 1. 🚨 Password hardening — steps 2 and 3 · **LIVE DEFECT, every existing account exposed**

### The defect being fixed
`encrypt` (`core/dod-bl-utl.lisp:825`) is **Blowfish in ECB**, an 8-byte block, and `ironclad:encrypt-message` drops the trailing partial block — so the effective credential was its **first 8 bytes**. **8 call sites** verified it, across vendor, customer and sysadmin logins. Measurements, the argon2id replacement, the traps and the re-verify recipe: **`knowledge/password-storage-CONTEXT.md`**.

### What is DONE (verified in the live image — do not redo)
`core/dod-bl-utl.lisp` ~`:848`–`:1030`: `hash-password (plaintext salt)` (argon2id at the OWASP minimum, stored as **63 chars**), `check-password (plaintext salt ciphertext)` (dual-format, **fails closed**), `password-hash-verify`, `password-hash-needs-upgrade-p`, `constant-time-string=`; round trip, suffix no longer accepted, legacy value still verifies (no lockout), **3.2 s** hash / 3.2 s verify.

### 🚨 What REMAINS — the defect is still live for every existing row
**Nothing writes the new format. Re-measured 2026-10-05: 0 of 15 `DOD_VEND_PROFILE` rows and 0 of 5 `DOD_USERS` rows hold an `argon2id$…` value** — so `Welcome1XXXX` still returns a session (the legacy branch necessarily keeps the truncation).

**Step 2 — the write sites (4 places, ~1 line each)**, still computed with `encrypt`:

| file:line | what |
|---|---|
| `core/dod-bl-utl.lisp:496` | `check&encrypt (password confirmpass salt)` |
| `customer/nst-dal-custusers.lisp:224` | `(hashed-password (encrypt password salt))` |
| `sysuser/dod-bl-usr.lisp:151` | `(encryptedpass (if password … ))` |
| `core/dod-seed-data.lisp:194,207,218,232` | dev seed fixtures (`Welcome$1`) |

→ `(hash-password password salt)`: same two arguments, same slot, same column, no call-site shape change.

**Step 3 — rehash on successful verification (the migration).** Until it lands every row that exists today stays weak. 8 verification sites: `vendor/dod-ui-ven.lisp:1131,:1538,:2449` · `customer/dod-ui-cus.lisp:811,:1741,:3660` · `sysuser/dod-ui-sys.lisp:734` · `sysuser/dod-ui-cad.lisp:379`. Add a `check-password-and-upgrade` helper taking a save-lambda: on success, if `password-hash-needs-upgrade-p` then store `(hash-password plaintext salt)` on that row — no password reset, no locked-out window.

### ⛔ The decision blocking steps 2–3
**3.2 seconds per login** is the honest cost of the OWASP minimum on this CPU, because ironclad's Argon2 is **pure Lisp**, not a native library. Deliberately NOT reduced: a smaller argon2 would be a non-compliant scheme wearing a compliant name.
* **Option A — accept 3.2 s.** Compliant, already implemented, no work beyond steps 2–3. Right choice if login latency is not sensitive.
* **Option B — bcrypt at work factor ≥ 10** (OWASP's third choice). Much faster, BUT **bcrypt requires exactly a 16-byte salt** and every row's `SALT` is 40 chars → a derived salt and a different stored format.
* **Third input, §6.6:** argon2id is not FIPS-approved; PBKDF2 is — decide now or re-migrate every hash.

### Measurements and traps, so they are not rediscovered
→ **`knowledge/password-storage-CONTEXT.md` §4** (ironclad v0.61's API, `block-count`, the `varchar(100)` overflow at 600k PBKDF2 iterations, the octet-vector and `equal` traps). Not restated here.

### Related gaps, deliberately not touched
* **No rate limiting or account lockout on `dodvendlogin`** — OWASP's *Authentication* cheat sheet and NIST SP 800-63B §5.2.2 require it; password *storage* does not substitute (§6.1a.2).
* **`*sitepass*` (`core/dod-ini-sys.lisp:63`, compared at `sysuser/dod-ui-sys.lisp:234`)** — a shared hardcoded site gate using the same `encrypt`; different mechanism, not a user credential.
* **`PAYMENT_API_SALT` / `PAYMENT_API_KEY`** — credentials on the vendor row with their own lifecycle.

### How to re-verify
→ **`knowledge/password-storage-CONTEXT.md` §5** — the pure REPL form (expect `(63 T NIL)`), the `curl` exploit check, and the two `SELECT COUNT(*) … LIKE 'argon2id$%'` counts. `tools/swank-eval.py` was **DELETED 2026-09-26**; never load a file into the live image from outside it (`knowledge/build-and-load-CONTEXT.md` §9).

---

## 1b. ✅ The invoice API 500 — FIXED, COMMITTED AND LIVE (no longer pending)

### The defect
`domain->response` setf'd every slot named by `*invh-mirrored-slots*` / `*invitm-mirrored-slots*`, which include `deleted-state`, while neither `NstInvhResponseModel` nor `NstInvitmResponseModel` declared it — so every authenticated invoice header AND line route answered **500 internal_error** (`the slot …DELETED-STATE is missing`) and nothing behind a session had ever worked.

### What is DONE
Both models in `hhub/invoice/nst-dal-invh.lisp` / `nst-dal-invitm.lisp` now declare `(deleted-state :initarg :deleted-state :accessor deleted-state)` — exactly one slot per side of 53 + 18, checked with isolated `compile-file` (`failure-p=NIL`), then behaviourally by an SBCL that loads `packages.lisp` + `nst-bl-adhara.lisp` + both DAL files and performs domain->response's exact `setf` (53/53, 18/18), kept as `aiharness/deepseek/tools/nst-invoice-mirror-check.lisp` and mutation-tested to exit 1; `render-json` stays off the wire, matching `WarehouseResponseModel`. **Verified LIVE 2026-09-26** (`GET /hhub/api/v1/invoices` 200; suite 62/0 read-only, 81/0 with `--write`) — the mechanism, the error-body taxonomy and the `nst-invh`/`nst-invitm` detail are owned by `invoice-api-handoff-CONTEXT.md` §1b.

**`ae54451` (2026-09-26 23:47) also bound, and the running image carries** the three later files — `vendor/nst-bl-vndapi.lisp` (the spec's id-less `PUT /hhub/api/v1/invoices/settings` as `route-invh-settings-update` → the existing `!settings` verb, so the blob keeps one writer; `:login-vendor` identity, `:row-id` forced from the session, no vendor identity → 401) and `invoice/nst-bl-invhapi.lisp` (`GET /hhub/api/v1/invoices/{id}/download` as `route-invh-download`, **302** to the rendered file; `GET /hhub/api/v1/invoices/{id}/public` as `route-invh-public`, `{"publicUrl": …}` — the spec's "no authentication" describes the LINK, not the endpoint, so no `:public` scope; and `invh-guard-sort-args`, bad `?sort-by`: 500 → 400). Both new endpoints answer **503**, not 404, for a vendor/tenant that no longer resolves. All **41** bindings follow their action-route registration.

**Only remaining action:** `NS_PHONE=9999999990 NS_PASSWORD=Welcome1 ./hhub/test/smoke-invoice-api.sh` (read-only; `--write` for the lifecycle). ⚠ This entry said *"waiting on an image reload"* while the handoff recorded it live — the reload has since happened, so the live record wins. **NOTHING ELSE IS OPEN HERE.**

---

## 1c. 🚨 THE BUILD ORDER THAT BROKE THE COLD BOOT — FIXED, COMMITTED, A RESTART HAS PROVED IT

### The defect
`d6275d0` moved `(:file "core/dod-ini-sys")` from ABOVE to BELOW `hhub-bl-ent` in both build lists, crossing a LOAD-TIME class dependency: `core/dod-ini-sys.lisp` installed `defmethod initBusinessContexts` on `BusinessServer` (a class defined in `core/hhub-bl-ent.lisp`) at load time, so a cold `(ql:quickload :nstores)` — what `startup/load.lisp` runs — aborted with **`There is no class named COM.NSTORES.APP::BUSINESSSERVER.`**, and since `init.lisp`'s `handler-case` swallows it, `(start-das)`/`start-das` never ran and **the app came up with NO ACCEPTOR — the site down**.

### Why it was invisible, and why it mattered
The image then running (pid 1915, started **07:54**, fasls from **00:00**) predated the commit, so it served the OLD, WORKING order and answered requests normally; **the breakage would have appeared for the first time on the next restart, as an outage with no obvious cause**, so any "just restart it" advice given before this was found was dangerous.

### What is DONE
**Move the METHOD, not the file.** 🚨 The first attempt reordered the lists instead — putting `core/hhub-bl-ent` above `core/nst-bl-beltrusys`, whose `with-bo-knowledge-check` macro binds `payload` — and every legacy read then raised *"The variable PAYLOAD is unbound"*; **it was reverted and the build lists are UNCHANGED.** The `defgeneric`/`defmethod` `initBusinessContexts` now live in `core/hhub-bl-ent.lisp`, beside the `BusinessServer`/`BusinessContext` classes they specialize on, and `dod-ini-sys` keeps only the runtime call inside `initBusinessServer`; the order that satisfies all three constraints at once keeps `beltrusys` before `hhub-bl-ent`, and `core/dod-ini-sys` early for its globals. Committed in **`ae54451`**; the constraint table, the reorder's damage and the `select-invoice-header-by-invnum` name collision are owned by `invoice-api-handoff-CONTEXT.md` §1b.

**VERIFIED 2026-10-05 — the acceptance test is a REAL RESTART, and it has happened:** the image running now (started 19:12:41) answers on its acceptor. The offline evidence stands too: `../tools/nst-offline-load.lisp` prints `STAGE: LOADED` (before the fix it reproduced the abort TWICE, from the image's fasls and from a full source compile, so not a stale-fasl artefact), the legacy read returns an `INVOICEHEADER`, and `../tools/nst-verify-invoice-dispatch.lisp` passes 51/0. Watch a restart for **`✅ HHUB Platform successfully started`** and an acceptor on 4244 — which log carries what is §5.

### ⛔ What REMAINS
**A GUARD IS MISSING.** `../tools/nst-binding-order-check` catches registration/binding ordering, a DIFFERENT dependency, and would not have caught this. The general form — *"does a file's load-time `defmethod` name a class defined in a later component?"* — has **no check anywhere in the tree**.

---

## 1e. 🚨 THE LEGACY PUBLIC INVOICE PAGE HAS BEEN 500 SINCE AT LEAST 2026-05-23 · ⚠ OPEN, UNVERIFIED

**PRE-EXISTING, not caused by the invoice-API work** — established by the log, not argument: the identical failure is in `ninestores-messages.log` at **2026-05-23 14:47:01, 14:49:53, 14:59:20**, months earlier, and again on 2026-09-26 during API testing.

```
ERROR SB-PCL::MISSING-SLOT :NAME COM.NSTORES.APP::INVNUM
  … (COM.NSTORES.APP::CREATE-MODEL-FOR-DISPLAYINVOICEPUBLIC)
```

`GET /hhub/displayinvoicepublic?key=<base64 tenant,invnum,vendor>` answered **500 for EVERY invoice** (measured against rows 4, 23, 30 and against the public production host). In `create-model-for-displayinvoicepublic` (`invoice/nst-ui-ihd.lisp`):

```lisp
(invheader (processreadrequest headeradapter hrequestmodel))
(invnum (slot-value invheader 'invnum))          ; ← MISSING-SLOT
```

so the legacy adapter hands back an object with no `invnum` slot — a sentinel or a different class — and the page dereferences it anyway. **The legacy read path needs diagnosing before the page can render.** ⚠ **Partially re-checked 2026-10-05:** a bogus key now answers **200** (the §6.1 gate refuses before any row read), so the 500 is behind the gate; the valid-key path was NOT re-tested. **UNVERIFIED, not fixed — do not close this on the strength of the 200.**

### What it breaks — all of it, together
* the **customer-facing "view invoice" link** · `com-hhub-transaction-invoice-public-pdf`, the legacy public PDF
* **the invoice email's PDF attachment**: `invoice-pdf-attachment` renders via `generate-invoice-ext-url` → `downloadhtmlfile` → the same page, so emailing an invoice gives `hhub-business-function-error` and no mail
* the new **`GET /api/v1/invoices/{id}/download`** — bound and correct, but it renders through this page, so its success path returns 500 with `external command failed … exit status 8: wget … displayinvoicepublic?key=…`

**Fixing this page fixes all four.** The smoke suite encodes the download consequence as its third `KNOWN`, not a FAIL, so this pre-existing cause is not mistaken for a defect in the new route.

---

## 1d. 🚨 A MYSQL TRIGGER OWNS `INVNUM` — and nothing in the tree says so

### The fact
`installation/nstdbtriggers.sql` holds a `before_insert_invoice` trigger on `DOD_INVOICE_HEADER` whose load-bearing line is `set NEW.INVNUM = concat('NST', lpad(next_id,5,'0'), '-', year(now()));`, `next_id` being the table's own `auto_increment` from `information_schema.tables`. **EVERY INSERT OVERWRITES `INVNUM`** — the number is effectively the row-id (`NST00040-2026` for row 40), zero-padded, with the CURRENT year. MEASURED 2026-09-26: a create asking for `ZZMANUAL1` stores `NST00040-2026`, and **CLSQL still reports the value it sent**, so the object in memory and the row on disk disagree.

### 🚨 `hhubuser` CANNOT SEE IT
`SELECT COUNT(*) FROM INFORMATION_SCHEMA.TRIGGERS` returns **0** for `hhubuser`: MySQL hides triggers from users without the TRIGGER privilege, so the schema appears to have none — which is exactly why this looked like the database silently discarding a value. **Do not conclude "there is no trigger" from INFORMATION_SCHEMA as this user**; the evidence is `installation/nstdbtriggers.sql` plus the observed overwrite.

### What this invalidates — check each before trusting it
* **`make`'s placeholder is dead code** — `(format nil "NST000~A" (hhub-random-password 10))` in `nst-bl-invh.lisp` is overwritten on insert, as is any invnum a client sends.
* **`invoice-general-settings`' `invoice-number-format` is not used for creation** — the DDL default is `INV-YYYY-MM-{counter}`; nothing consults it (and `{counter}` has no backing store — §7).
* **`?exists` / duplicate-invnum `:C` reasoning is moot FOR CREATES** — the sequence guarantees uniqueness, so the `make :around` duplicate check can only fire on a re-used number, which the trigger prevents.
* **🚨 CLEANUP BY INVNUM PREFIX IS IMPOSSIBLE** — the smoke suite tagged rows with a `ZZSMOKE…` number and deleted by that prefix; the trigger discards it, so `--write` **leaked every row it created** (twice, before this was found). Suite and `../tools/nst-verify-invoice-dispatch.lisp` now key on a caller-controlled field (ROW-ID from the 201; `CUSTNAME`). Anything else that "cleans up after itself" by invoice number has the same bug.

---

## 2. Invoice settings — phase 2: remove `:invoice-settings` from `!update`

**DONE:** `!settings` pratyaya (`vendor/nst-bl-vnd.lisp`) with its own action route and API binding — `PUT /hhub/api/v1/vendor/profile/{id}/invoice-settings`, verified end to end (`hhub/test/smoke-vendor-invoice-settings-api.sh`: 20 pass / 0 fail / 5 known).

**REMAINS — still open 2026-10-05:** `:invoice-settings` is still a declared initarg accepted by generic `!update`, so `PUT /hhub/api/v1/vendor/profile/{id}` **writes the blob with no validation at all** — measured by the suite (K2): a 4330-char blob replaced by 45 characters of `((…::NO-SUCH-SECTION (:A . 1)))`, 200, no error anywhere. Add `:invoice-settings` to `*vendor-update-forbidden-fields*` (`vendor/nst-bl-vnd.lisp`, `defparameter` at **:522**; on 2026-10-05 it was still `'(:password :salt :payment-api-key :payment-api-salt)`), or guard it equivalently. **Acceptance: K2 flips `KNOWN` → `PASS`.**

---

## 3. `DOD_VENDOR_SETTINGS` — the can of worms, deferred by decision

A per-vendor settings table, reviewed and rejected as premature. **Rows = 0** (re-confirmed 2026-10-05), so every fix is still free — but this expires the moment the table starts being written.

Blocking findings: `SETTING_KEY` carries a **global** `UNIQUE` (one row per key for the whole database, not one per vendor); `SETTING_DEF_ID` and `VENDOR_ID` are nullable/unconstrained with no FK to `DOD_VEND_PROFILE`; `TENANT_ID` and `DELETED_STATE` are nullable where the rest of the schema defaults `'N'`; the definition table has no `UNIQUE(SETTING_KEY)`; and `DOD_VENDOR_SETTINGS_DEFINITION` needs `DEFAULT_VALUE`, `IS_SENSITIVE` and an `UPDATED_BY`/`SOURCE` audit pair before a generic settings surface is safe to publish — a generic table destroys the response model's field-allowlist property that keeps `password`/`salt` off the wire.

Migration mechanics: both 2026Feb versions are **recorded as applied**, so editing `installation/upgrades/nst-dbu-vendorsettings.lisp` does nothing — this needs a **new** registered migration.

---

## 4. `smoke-bulk-products-api.sh` has no write gate

**Still open (re-checked 2026-10-05: no `WRITE=0` default, no `--write`).** Every other `test/smoke-*.sh` defaults to read-only and requires `--write` to mutate; this one POSTs to `/catalog/products/bulk` and DELETEs products unconditionally, so a plain run mutates the live database. Its `BASE` was updated to `http://ninestores.local` with the rest of the family, but it has **not been executed** since.

---

## 5. `dispatch-route2` prints to stdout on EVERY API request

`hhub/core/nst-bl-conflodis2.lisp` **lines 310-311** (re-measured 2026-10-05, unchanged), inside the `let*` body of `dispatch-route2`, guarded by nothing:

```lisp
(format t "~&conflodis2: ~S → action verb ~S~%"
        route-key (route-action-verb route))
```

**Measured 2026-09-26: it is NOT conditional** — every dispatch on every one of the 42 bound endpoints writes a line to the image's `*standard-output*`: the file that would tell you which route ran is a log nobody reads, and a per-request `format` sits in the hot path of every call.

**Which log carries what** (the split §1c's restart watch depends on): under the deployed `detachtty` wrapper stdout goes to `~/log/hunchentoot.detachtty` / `hunchentoot.dribble`, **not** `ninestores-apilogs.log`. The Lisp transcript is `~/log/hunchentoot.dribble` (mode 600, owner `hunchentoot`); `hunchentoot.detachtty` holds only detachtty's own messages.

**REMAINS:** delete the two lines, or put them behind a variable. Deliberately NOT done during the invoice-API session that found it (a core file shared by all 42 bindings, outside that objective, unverifiable live then). **It may also be deliberate development instrumentation** — nothing declares it either way, which is itself the thing to fix.

---

## 6. Compliance gaps — recorded 2026-09-26, to be worked ONE AT A TIME

Each entry: WHAT the standard requires, WHAT was measured, the shape of the fix. ⚠ Standards reasoning from code and measurements taken in that session — **not an audit**: no scanner or checklist ran behind it, and CORS, security headers, TLS config, request-size limits and PII retention in the access logs were NOT inspected.

### 6.1 `/public` — the link's capability is not a secret, and has no expiry
**OWASP API1:2023 (BOLA).** The key WAS `base64("tenant-id,invnum,vendor-id\n<tenant>,<invnum>,<vendor>")` — structured, predictable, unsigned, no expiry, no password: anyone holding one link could decode the format and mint the key for ANY invoice in ANY tenant. **AGREED FIX (2026-09-26):** a password plus a 5-minute expiry, with the two prerequisites in §6.1a. **STATUS 2026-10-05: implemented 2026-09-26, proven offline (116 checks, 0 failures; 74 when written, `../tools/nst-verify-invoice-public-link.lisp`) and LIVE** — the gate's symbols are in the fasls the current image loaded; since 2026-10-03 the password is the **CUSTOMER's** last 4 phone digits, a signed **`:render`** token lets the PDF pipeline through the gate, and the vendor's share icon goes RED on an expired link. **The mechanism, the seven measured traps and the format `base64url(payload).hex(hmac-sha256(payload, vendor.SALT))` are ALL owned by `knowledge/invoice-public-link-CONTEXT.md`** — not restated here. Its symbols: `invoice-ext-key-payload` / `-key-signature` / `-b64-encode`, `invoice-ext-key-parse`, `*invoice-ext-link-lifetime-seconds*` (300), `invoice-ext-four-digits` / `-password-digits`, `invoice-ext-authorise` / `*invoice-ext-max-attempts*` (5) / `*invoice-ext-gate-table*`, and the route-side call sites `create-model-for-displayinvoicepublic` / `create-model-for-invoice-public-pdf-url`. Three defects it caught and fixed, none visible to the compiler: a `string-downcase` that made base64 decode to noise (so EVERY minted link failed verification), a `(when … (:div
…))` that cl-who renders as Lisp (`The function :DIV is undefined`), and a `let` closing
before the form that used its binding (`UNBOUND-VARIABLE` on every valid key).

**⚠ STILL OPEN here, deliberately not bundled in:**
1. **The rendered PDF is STILL a static file** under `/img/temp/`, named from the invoice number and universal time and served unauthenticated — the *route* verifies the key, the *artifact* does not.
2. **`:granted`/`:locked` state is per-process, in memory** — a multi-process Hunchentoot would keep one attempt count per process.
3. **The `/public` API response does not yet report `expiresAt` / `passwordRequired`.**
4. **`dodvendlogin` still has no rate limit** — §6.1a.2's second half, untouched.
5. **Rows 17/18/19 have `SALT` NULL and `PASSWORD` empty** — they cannot log in, can never mint a link, and minting fails closed for them; a pre-existing credential gap in those rows, not a consequence of this work.

#### 6.1a 🚨 TWO PREREQUISITES, WITHOUT WHICH THE FIX IS SECURITY THEATRE
1. **THE TOKEN MUST BE SIGNED, or the expiry is decoration** — an expiry embedded in base64 CSV is forgeable (re-encode a later timestamp); HMAC over the payload with a server secret is what makes "5 minutes" mean anything, and it stops a forged key naming an invoice the holder never had.
2. **THE PASSWORD CHECK MUST BE RATE LIMITED, or 4 digits is not a password** — 10,000 combinations, no throttling today, and the value is a phone number the addressee plausibly knows. (`dodvendlogin` has the same gap: NIST SP 800-63B §5.2.2 / OWASP ASVS 2.2.1.)

### 6.2 `:required-roles` is carried but NOT enforced
**OWASP API5:2023 (BFLA).** `register-action-route` accepts `:required-roles` and `conflodis2 v1` never reads it (the code says so itself) — no function-level authorization: any authenticated vendor in a tenant may call every invoice endpoint. The vendor-settings suite already records the consequence (any vendor of the same tenant may write a sibling's settings blob).

### 6.3 No pagination and no rate limiting
**OWASP API4:2023 · Google AIP-158.** `GET /invoices` is unbounded — measured: no `page-size`/`page-token`/`limit`/`offset` anywhere in the invoice API. A list endpoint with no bound is a resource-consumption vector as well as an AIP deviation.

### 6.4 Client errors answered as 500
**RFC 9110.** `api-status-for-condition` maps every condition it does not name to `500 internal_error`, so a malformed REQUEST reports as a server fault. `?sort-by` was fixed (`invh-guard-sort-args`, now 400); a rejected settings blob is still 500 (the suite's K1). One classifier change fixes the family.

### 6.5 No `Location` header on 201
**RFC 9110 §15.3.2** (a SHOULD). `POST /invoices` returns 201 with the resource in the body and no `Location`. Cheap now, because the invoice has a canonical number-based URL.

### 6.6 FIPS 140 vs the pending password work — DECIDE BEFORE PENDING §1 STEPS 2–3
**argon2id is not FIPS-approved; PBKDF2 is.** If any deployment ever needs FIPS validation, choosing now costs nothing and choosing later means re-migrating every stored hash. ⚠ The recorded trap applies: PBKDF2 at 600k iterations yields a **118-char** value that OVERFLOWS `varchar(100)`, so that path needs a schema change too.

### 6.7 ✅ NOT a gap: a repeat `DELETE` answering 404
Corrected 2026-09-26. The invoice suite's K2 frames this as a defect (asserting 409 "already deleted" is the contract) — **that framing is wrong**: DELETE is idempotent under RFC 9110 and 404 on the second call is acceptable, arguably better than 409. K2 should be reclassified as a design choice when the suite is next edited.

---

## 7. The ORDERS batch — S0b and S0c are APPLIED; S16 in progress

**Read `order-adhara-stories-CONTEXT.md` FIRST** — the design and the story list, its §0 a RESUME-HERE running order. Recorded here only so a fresh session finds it from the ledger; live state of play: `README.md`'s row (**S0–S15 DONE, S16** in progress).

**DONE (do not redo — this cost a full design cycle):** the design is frozen and the rulings closed; all three live tables are measured against their view classes (`DOD_ORDER` 58/58, `DOD_ORDER_ITEMS` 30/32, `DOD_VENDOR_ORDERS` 26 declared vs 60 live). Three design errors were found by measuring instead of assuming, and they are why the story file opens with a warning:
* **`installation/hhubplatform.sql` is NOT the live schema for these tables** — it hides that live `STATUS` is `char(3)` (so the create-script's `DEFAULT 'DRAFT'` is *unstorable*), that `ORDNUM` has **no** unique key, and that `DOD_ORDER` has **no `VENDOR_ID` column at all**.
* **There was no order number in the database at all**: 485/485 orders and 462/462 vendor rows had a NULL `ORDNUM`, so the migration had to *invent* numbers, not backfill them — a copy-from-parent repair is powerless (run by hand it returned `Changed: 0`).
* **`{counter}` has no backing store anywhere in the tree**, and the invoice's own `invoice-number-format` is aspirational because a MySQL trigger overwrites `INVNUM` (§1d).

**S0c — DONE: code verified offline 2026-09-28 (37/0, `../tools/nst-verify-doc-numbering.lisp`) and the migration is APPLIED** (2026-10-05: `DOD_DOC_COUNTER` and `DOD_SYS_SECRET` exist, 17 `ORDER` counters, sequence column `LAST_SEQ`). Two traps from it: the FIRST run failed because the DDL named the sequence column `LAST_VALUE`, which MySQL 8.0 reserves (a window function), so the CREATE died with `Error 1064` — the version is written only after the function returns, so nothing was recorded and the re-run (`("28092026-create-doc-counter")` via `(apply-migrations user pass)`, or the DDL by hand) was clean and idempotent; and `nst-financial-year-label` destructured six values from `clsql-sys:decode-date`, which in this CLSQL returns **four** for a DATE struct, so `make 'nst-invh` without a caller-supplied `:finyear` signalled a TYPE-ERROR — it now computes the year via `nst-date-ymd`. That path was only verified offline and the suite always supplies `:finyear`, so **re-running the invoice suite against the restarted image is the one remaining check.**

**S0b — DONE: `28092026-ordnum-identity` is APPLIED** (2026-10-05: **491** `DOD_ORDER` and **468** `DOD_VENDOR_ORDERS` rows now carry an `ORDNUM`, up from 0; 7 `DOD_CUST_PROFILE` rows carry 7 distinct `DOC_PREFIX` values — `CUST17`, `DEMO`, `GCUST837`, `GUEST`, `KND`, `LGI`, `PAWAN`, exactly the seven the dry run predicted, so no de-duplication was needed). Its preparation is closed: the `mysqldump` of `DOD_ORDER`, `DOD_VENDOR_ORDERS`, `DOD_CUST_PROFILE` (485, 462, 25 rows), the dry-run criterion, the customer-population join in the story file's §9. **R2–R4 were taken as recommended and are now beyond veto** (vetoable only until S0b was APPLIED).

**S0b — PRODUCTION: APPLIED 2026-10-10 17:05:34** (the `DOD_SCHEMA_MIGRATIONS` row exists, and all three keys are live and unique: `uk_ordnum` on `DOD_ORDER`, `uk_cust_doc_prefix`, `uk_vo_order_vendor`). It took **two attempts**, and the first is the dev incident of 2026-10-03 recurring: `(apply-migrations …)` walked steps 1–4 cleanly (no prefix left to allocate, no NULL `ORDNUM` anywhere, 0 vendor rows left) and died in step 5 with `Error 1062 / Duplicate entry 'ORD-DEMOCUS8-2019-20-AJTTH5' for key 'DOD_ORDER.uk_ordnum'` — **the counter handed one `LAST_SEQ` value to two mint calls**, exactly as it did for rows 81/201 in dev. Production's group: rows **698/699**, customer 1 `DemoCus80b`, FY 2019-20, where the series held **54 rows and 53 distinct references** with `LAST_SEQ` 54. The repair is now written down — `knowledge/schema-migrations-CONTEXT.md` trap 11: keep the LOWER `ROW_ID` (minted first, legitimately owns the value), re-mint the higher through `nst-mint-order-number-for-customer`, re-stamp its `DOD_VENDOR_ORDERS.ORDNUM` rows if any (denormalised by design, D20), then re-run. 🚨 **AND THE PAIR WAS NOT A DUPLICATED ORDER**: 698 and 699 differ in `ORDER_AMT` (119.50 vs 400.00) and `SHIPPED_DATE` (three weeks apart), both are `CMP`, fulfilled and prepaid, and neither has items, payments, track rows, reviews or vendor rows — so de-duplicating the *order* was considered and **refused**: the duplicated thing was the NUMBER, never the order. Their `CONTEXT_ID`s are exactly 15.000000 s apart, which reads like a double-submit signature and is not one.

**⛔ OPEN ON PRODUCTION, found by the same probe:** the running image's `*migrations*` held **75** entries against the tree's **77**, so `06102026-freight-product-per-vendor` and `09102026-vendor-order-amount-repair` (the `DOD_VENDOR_ORDERS.ORDER_AMT` repair — order 503, 7006.71 against a true 6832.87) **were never queued**; `(assoc "09102026-vendor-order-amount-repair" *migrations* :test #'string=)` answered `NIL` while both files loaded fine, and the **27** files on disk matched the tree exactly — the disk was current and only the image was stale. **Fix: restart from the current tree (or `(load "…/hhub/core/nst-sch-mig.lisp")` into the live image), then `(apply-migrations "hhubadmin" "<password>")`.** Mechanism and probe in `knowledge/schema-migrations-CONTEXT.md` trap 10.

⚠ **The build-vs-live check is owned by `build-and-load-CONTEXT.md` §7** (`strings <fasl> | grep -ci <symbol>`, then compare **full dates, never times of day**) — moved out of this ledger on 2026-10-05.

The batch instance, which cost a wrong answer on **2026-09-28**: `strings …/hhub/core/dod-bl-utl.fasl | grep -ci nst-doc-prefix-base` answered `0` — the cache predated this batch. Source edits at **2026-09-28 17:03** sat against cache fasls at **2026-09-27 17:36** (24 hours older), where a `%H:%M:%S` listing made both look like the same "17:36, fine"; the process (started 2026-09-28 06:57) predated the edits too. A restart is what puts a new `*migrations*` entry into the image — ASDF recompiles `dod-bl-utl.lisp` and `nst-sch-mig.lisp` — whereas a `(compile-production)` alone would NOT fix the image: it writes fasls beside the sources, not the build the server loads.

**Before that restart the batch's own functions did not exist in the image** — compiling a caller reported "undefined function NST-DOC-PREFIX-BASE" and "NST-ORDER-NUMBER-FOR … wants exactly five", because the migration calls `nst-doc-prefix-*`, `nst-order-number-for` and `*nst-order-number-format*`. Those are style-warnings, **but SBCL sets `failure-p` for warnings too, so SLIME said "Compilation failed"** — the stale image, not a broken migration. Mints fail closed by design in that state (a clear message, never a default key), so a *"cannot read the document-reference key"* error was this item, not a bug.

**Probe the image after any restart** — the `*migrations*` registry comes from the IMAGE while `load-upgrade-files` reads its functions from DISK, so the two disagree silently: `(fboundp 'nst-doc-prefix-base)`, `(fboundp 'nst-next-doc-counter)`, `(boundp '*nst-order-number-format*)`, `(assoc "28092026-ordnum-identity" *migrations* :test #'string=)` — all satisfied by the image running since 2026-10-05 19:12:41. Applying: `(load-upgrade-files *upgrade-files-directory*)` (the file is not in the asd), a dry run `(let ((*nst-ordnum-migration-dry-run* t)) (migrate-2026Sep-ordnum-identity))`, then `(apply-migrations "hhubadmin" "<password>")`.

**⛔ STILL OPEN — one product question, not an engineering one:** `order-number-format` sits in the per-VENDOR `*invoice-settings*` blob, but an order is the CUSTOMER's document and can span vendors, so the mint uses the code default `*nst-order-number-format*` — which makes that settings key **a setting that changes nothing**. Recommendation: remove it (the tree has already deleted one dead settings key); alternatives are a tenant-level settings store, or leaving it as documentation.

**What REMAINS:** every other story, **S0d next** (the prefix on the customer entity and profile page); running order, dependencies and human-side needs are §0 of the story file. S0c was deliberately cross-domain (`invoice/templates/invoicesettings.lisp`, `vendor/nst-bl-vnd.lisp`) and is committed; the T5 guard (the invoice's existing format renders unchanged) is what it had to satisfy.

---

## 8. Two files are COMPILED but never LOADED — found by the preflight's registration check

**The check:** `../tools/nst-preflight.lisp` §3 asserts that every `hhub/**` file a change set adds appears in **both** `package/compile.lisp` and `nstores.asd` — a file in the first only is compiled to a project-local fasl that nothing serves: it looks built and does nothing.

**What it found, 2026-09-28 — both still OPEN, re-confirmed 2026-10-05:**
1. **`invoice/nst-bl-gstr1.lisp` — the whole GSTR-1 collector — is in `compile.lisp` and ABSENT from `nstores.asd`** (`compile.lisp:284` when found, **`:328`** now). The server loads through `(ql:quickload :nstores)`, so it has never had this file, and nothing else references its functions. ⚠ **This is the likely explanation of the note in `gst-gstr-compliance-CONTEXT.md` that the collector "was never run against a session"** — not merely unexercised, not loaded. **Decide and fix:** add it to the asd (if it is meant to be live) or remove it from `compile.lisp` (if not), then confirm with a restart and `(fboundp '<one of its functions>)`.
2. **`order/dod-dal-otk.lisp`** declares `clsql:def-view-class dod-order-track` against `dod_order_track` — **the same table `order/dod-dal-odt.lisp` also maps** (as `dod-order-items-track`). Two classes for one table, and the never-loaded one is `otk` (`nstores.asd:143` loads `odt`; `compile.lisp` lists both). Probably superseded; recorded rather than guessed, because deleting the wrong one breaks the order-track reads that do work.

**Not to be "fixed" blindly:** the two lists differ in 13 places and MOST are legitimate (`test/*` is compile-only by design; `core/nst-sch-mig.lisp`, `dod-sto-zip.lisp` and `stock/dod-dal-stk.lisp` are loaded but never compiled, which ASDF handles on load) — the check is narrow for that reason.

---

## 9. The vendor Settings page — **designed, parked by decision (2026-10-03), no code written**

**The ask:** the six settings items on `dodvendprofile` (`hhub/vendor/dod-ui-ven.lisp:1958–1973`) — My Groups, Contact Information, E-Commerce Shipping Methods, E-Commerce Payment Methods, E-Commerce Payment Gateway, UPI Settings — re-homed into the sidebar's Settings node, with room for **20+ further settings** without the sidebar becoming a wall.

**Where the design lives:** `vendor-settings-CONTEXT.md` — the whole design, the invoice-settings mechanism it is modelled on traced to file:line, the eight traps in that precedent not to inherit, the ten registration/build steps, the four open decisions, the file map. **Enter there to resume; nothing about this item is in this ledger's other sections.**

**DONE (do not redo):** the exile's cause no longer applies to a page — a modal cannot be a sidebar link (not linkable, not bookmarkable; BS5 modal z-index 1055 over an open offcanvas 1045 fights the body scroll lock), and the six items become page content, not modal triggers (four of the six are modals today: `dod-ui-ven.lisp:778, 924, 953, 1041`). `hhubvendorshipmethods` (`:1996–2010`) is the *same* shape one level down (five sub-items, four modals), so the design must be recursive. The route needs no new dispatcher: `/hhub/dodvendprofile` exists (`dod-ui-sys.lisp:1086`) and already receives an unused `?context=` from the sidebar (`:151`) — **zero edits to `dod-ui-sys.lisp`, no new controller, no new save action.** The payment-method flags are already session-cached at login (`dod-ui-ven.lisp:2541–2559`, `:login-vendor-settings-ht`), so no pane needs a DB read. A per-key setter already exists — `nst-save-vendor-invoiceprintsetting` (`hhub/invoice/nst-ui-ihd.lisp:233`), read-modify-write across row and session. And `DOD_VENDOR_SETTINGS` is **not** this page's store (schema from the parked AI decision-registry line `nst-bl-vaisettings`, no Lisp reader or writer, rows = 0 — §3, `nst-bl-vaisettings-CONTEXT.md` §3–5): do not build a generic k/v surface here, it destroys the response-model field-allowlist property that keeps `password`/`salt` off the wire.

**What REMAINS:** all of it — no file in `hhub/` has been touched. Build sequence: §6 of `vendor-settings-CONTEXT.md` (registry → asd + `compile.lisp` → template vars/loader/getter in `dod-ini-sys.lisp:182, 597–608` → template file → model/widget at `dod-ui-ven.lisp:1934/1946` → sidebar node at `:147–151` → the write seam → six redirects at `:908, 944, 1021, 1025, 1037, 1089, 1140`).

**Blocking decisions (owner):** the Shipping Methods sub-settings shape (nested `?context` level vs a sub-accordion inside its pane); whether the filter box searches values or only section labels; blob column vs a dedicated `settings` column; and whether `dodvendprofile?context=` stays canonical or a `/hhub/dodvendsettings` route is introduced once the old hub page is retired.

---

## 10. 🚨 `UPDATED` IS FROZEN BY THE ORDER WRITE — F8's `ETag`/`If-Match` is INERT · found 2026-10-04 (S16)

**Measured through `hhub/test/smoke-order-vendor-api.sh --write`:** a vendor `PUT` changes `COMMENTS`, leaves `ORD_DATE` **byte-identical** (T9 is genuinely defeated — good), and leaves `UPDATED` **unchanged** (`13:06:23 → 13:06:23`).

**Cause.** `dod-vendor-order` declares `(updated :column "UPDATED")` (`hhub/order/nst-dal-vordh.lisp:352`) and `!update` writes with `(clsql:update-records-from-instance …)` (`hhub/order/nst-bl-vordh.lisp:666`), which writes **every storable slot** — so `UPDATED` is assigned EXPLICITLY from the value the read returned, and that beats `ON UPDATE CURRENT_TIMESTAMP`. `dod-order` has the same shape (`hhub/order/nst-dal-Order.lisp:747`, write at `nst-bl-ordh.lisp:325`), so BOTH channels share it. `nst-bl-ordh.lisp:890` claims the opposite — *"cannot touch UPDATED: the mirrored list does not carry it (D19)"* — but the mirrored list drives `domain->response` (the JSON boundary) while the SQL write is driven by the CLSQL class's storable slots; two mechanisms, and only the second reaches the column.

**Consequence — F8 is decorative on the order endpoints.** The vendor channel's `ETag` is built from `UPDATED` (`hhub/order/nst-bl-vordhapi.lisp:213`), so the validator NEVER changes: a genuine concurrent write can never trip the 412 and the last writer wins silently — the defect F8 exists to close. The suite's stale-token 412 proves the COMPARISON works; it cannot prove a detector with nothing to detect. The data is not corrupt (it freezes at a real past value); it is useless as a version.

**Fix shape, verified against the installed CLSQL — ⛔ STILL OPEN, not fixed in S16 by decision.** `clsql:update-records` is exported (`sql/fdml.lisp:204`) and takes `:av-pairs`/`:where`, so the write can NAME its own columns and omit `UPDATED` — `ON UPDATE` then fires again. ⚠ `ord-date` MUST stay in that column set: it is what keeps AC (f)'s byte-identity green, so T9 and F8 pull in opposite directions and only a named column set satisfies both. **Test:** the suite encodes it as `KNOWN` (S16 AC (d)) and flips to `PASS` with a note the day the fix lands.

**⚠ AND THE SAME SUITE DAMAGED THE DATA IT WAS TESTING.** Its first cleanup restored `COMMENTS` with a hand-written `UPDATE … SET COMMENTS=…` that OMITTED `ORD_DATE`, so `ON UPDATE` fired and moved the fixture's `ORD_DATE` to `now()` — twice, before it was noticed: the suite that exists to prove T9 does not fire had fired it. **Measured idiom for ANY hand-written writer:** `SET x=…, ORD_DATE=ORD_DATE` → PRESERVED; omitting it → MOVED (`SET x=x` proves nothing: MySQL skips the auto-update when no column actually changes, so a no-op is not a control). Both fixture rows were restored to `ORD_DATE='2026-10-04 00:00:00'`, their API-created shape, and the round trip re-verified byte-exact.

---

## 11. The order API after S16 — what is pending, in priority order · recorded 2026-10-05

S16 is closed: the create works (its first `201` is proven), the four smoke suites are green, and this
is what they deliberately did NOT close. **One item is already done and is recorded here because it
was dangerous rather than cosmetic:** the customer's `DELETE /orders/{ordnum}` cascaded to the order's
LINES and **not** to its `DOD_VENDOR_ORDERS` rows, so a vendor kept working on — and could ship — an
order its customer had deleted (measured: the vendor's `GET` answered 200 for an order deleted seconds
earlier, and 8 live rows already had a soft-deleted parent). Fixed 2026-10-05 with
`nst-soft-delete-vendor-orders-for-header`, a लोप helper in `nst-bl-vordh.lisp` mirroring the line one,
called by `nst-ordh`'s `delete!` **before** the header write so a half-finished delete leaves the
header live and reachable. Both suites now ASSERT the cascade instead of recording it.

**Two LEGACY-UI bugs found by the requester in the browser (2026-10-06) and fixed the same day**, both
in the customer's item-delete flow and both pre-existing:
* `create-model-for-deletecustorditem` computed the order total with `(slot-value odt 'current-price)`
  — **`current-price` is a PRODUCT column, not a `DOD_ORDER_ITEMS` one**, so deleting an item while
  others remained raised MISSING-SLOT *after* the item was already deleted. The line now uses
  `calculate-order-item-cost` (dod-ui-odt.lisp:148), which reads the ITEM's own unit-price/disc-rate/
  tax columns — and which two functions further down the same file already used.
* Emptying an order deletes it, and the model then redirected to **that order's detail page**, which
  could no longer find it → MISSING-SLOT TENANT-ID on NIL. The redirect now goes to My Orders when the
  order is emptied, `hhub-controller-customer-my-orderdetails` guards a missing/deleted/non-numeric id
  the same way, and `get-order-items` answers NIL for a NIL order instead of signalling (the backstop
  for its other five callers).
* And a THIRD, found the same session in the item-**edit** page: `odt-vendorobject` — a JOIN accessor
  the page calls on an order-item row — had been REMOVED from `dod-order-items` by commit `e4cfa63`,
  which left in its place a slot joining a class that does not exist (`doe-vend-profile`) by the wrong
  key (`order-id`). The page has 500'd since that commit; the dormant slot's accessor was called
  nowhere, so the correct join (`dod-vend-profile`, `home-key vendor-id`) was restored from `4a83f84`
  in its stead. ⚠ A `def-view-class` change: RESTART, never an in-image reload (T6).

| # | what | why it matters | state |
|---|---|---|---|
| **1** | **The transaction seam (O3)** — `POST /orders` writes header → lines → stock → vendor rows with no transaction around them | a failure after the INSERTs leaves a half-built order: **five measured 500s left orders 491, 494-497 and 499** with their lines and vendor rows, and cleanup could not key on a `rowId` that never arrived | ✅ **DONE 2026-10-06** — `route-ordh-create`'s write half is one `clsql:with-transaction` (extracted as `ordh-create-assembly`, with an EXPLICIT `clsql:rollback` because the assembly reports failure by RETURNING sentinels and a normal return would COMMIT), and `delete!`'s three writes likewise (its refusals leave by `return-from`, which aborts automatically) |
| **2** | **A vendor DELIVERY table** — the vendor must read the items it ships and mark fulfilment per item | today a vendor cannot see *what* to ship: the vendor channel has no line endpoints and `nst-orditm`'s `enumerate` filters by order, not vendor | **DECIDED 2026-10-05**: a separate vendor-delivery table, not line fields on `DOD_ORDER_ITEMS` — the standard pattern, and a feature the requester wanted anyway. Design: one row per (vendor order, order item) with quantity, status, shipped date |
| **3** | **`UPDATED` is frozen (F8)** | the vendor ETag never changes, so `If-Match` cannot detect a concurrent write — see §10 | fix shape verified (name the write's columns, omit `UPDATED`, KEEP `ord-date`) |
| **4** | **The customer channel emits NO ETag** | its `If-Match` is unusable: a client cannot obtain a validator, so the 412 machinery is reachable only with an invented token | open |
| **5** | **A LINE has no per-channel field allowlist and no version token** | the header and the vendor row each have both (F5); a customer may assign any declared line initarg, and two editors of one line are last-write-wins | open — a decision, not a test |
| **6** | **F12 / F16 — two contract decisions** | `PUT`-with-merge vs `PATCH`; and whether `POST /orders` should handle OTP + wallet, which the product's own spec text promises | open |
| **7** | **`IS_CONVERTED_TO_INVOICE='Y'` has no fixture** | 0 of 489 rows, so the order→invoice refusal is NOT TESTED (the writable-field half is) | open |

**⚠ ROWS 3-7 ARE PARKED BY DECISION (2026-10-06).** The requester's call: after O3 the API's grammar
and design are considered done, and B (concurrency: §10's F8 plus the customer channel's missing ETag)
and C (the line's absent field allowlist and version token, F12/F16, and the missing invoice fixture)
wait for a later pass rather than blocking the next feature — which is row 2, the vendor DELIVERY
table, starting from its UI. Nothing here is dropped: each row keeps the evidence that found it.
| **8** | **The customer UI's delete path is not covered by the HTTP suites** — and it now cascades (lines + vendor rows) and calls `delete-vendor-order` for a vendor row | the four suites speak HTTP; this is a form POST from **My Orders**. Both changes are verified OFFLINE only (preflight PASS, `STAGE: LOADED`, no new warning) | **needs one browser click on an order that has a vendor row** — and note the permission divergence below |

⚠ **STOCK — RECORDED BECAUSE THE MODEL IN CIRCULATION IS INCOMPLETE.** The recollection was that stock
decrements in `set-order-fulfilled` and at the invoice-finish step. MEASURED 2026-10-05, the three call
sites of `update-stock-inventory` are `order/dod-bl-ord.lisp:537` (**`save-order-items-in-db`, the
LEGACY order-create path**), `order/nst-bl-ordhapi.lisp:1023` (the new API's create assembly — the
reservation the requester endorses) and `invoice/nst-ui-ihd.lisp:1526` (invoice finish). **There is no
call site in `set-order-fulfilled`.** So BOTH creation paths already decrement at creation, and
**whatever the delivery feature does, it must not decrement again** — or one order costs its units
twice. Reservation management (releasing on cancel, reconciling at ship) is DECIDED to be a future
feature, not part of this batch.

⚠ **AND THE TWO DELETE PATHS STILL DIFFER IN PERMISSION, NOT JUST CASCADE.** The API's `delete!`
refuses anything but `DFT` and refuses an order already converted to an invoice; the customer UI's
`dod-controller-del-order` calls the legacy `delete-order` directly and so deletes **any** order — a
`CMP` one, a `VCN` one, an invoiced one. One rule for deletion means pointing that controller at
`nst-ordh`'s `delete!`, which ADDS refusals the UI does not have today, so it is a decision rather
than a tidy-up.

---

## Not a defect, but easy to trip over

* **The smoke-suite base.** `http://hunchentoot.local` answers **404 for every `/hhub/` URI** on this host (nginx on :80 proxies nothing) — all six suites default to `http://ninestores.local`, which behaves identically to `127.0.0.1:4244`. `/hhub/` itself is 404 on every base, so a reachability probe on that path proves only that a socket opened; assert the API's own 401 instead.
* **`sed -i` changes a file's OWNER**, which silently removed the execute bit from two smoke scripts whose modes relied on the GROUP class (`-rw-rwxr-x` owned by `hunchentoot`, readable/executable by `hhubgrp`). Files created by the agent land `-rw------- ubuntu:ubuntu` and must be `chmod 664` + `chgrp hhubgrp` before the `hunchentoot` image can load them.
* **A new `hhub/**` file needs two registrations**, not one: `package/compile.lisp` and `nstores.asd`. A `.fasl` beside the source does NOT reach the app (§8).

## 12. The vendor's *Generate Invoice* — `invoice-from-ord` · recorded 2026-10-06

**Not a new invention: a named समास.** `paninigrammar/document-5-samaas.md` puts `ord→inv` under
"→ TRANSFORM (source entity becomes target entity)" as **`invoice-from-ord`** (तत्पुरुष), and its tool
schema `{ord_id, tenant_id, actor_id}` says the LINES ARE DERIVED, not passed. **विसर्ग संधि** decides
the branch: physical goods are MEDIATED (व्यंजन — Document 4 lists "ord not fulfilled → invoice" as
INVALID for goods, and this schema has no GRN, so `ORDER_FULFILLED` stands in for
`grn-exists-and-accepted?`), a service order (`ORDER_TYPE='SRVC'`) is ELIDED (लोप ३). Payment is NOT
part of the junction — inv→pmt is प्रगृह्य, so prepayment never licenses invoicing before the mediator.

**Step 1 is DONE and verified offline** — `aiharness/deepseek/tools/nst-verify-invoice-from-order.lisp`,
**53 pass / 0 fail / 0 skip** (the delivery charge added 2026-10-06: it is a LINE taxed at the goods' rate,
per `knowledge/gst-gstr-compliance-CONTEXT.md` §10), writing to the real database and then undoing it: the DRAFT, six lines
totalling the vendor row's own `ORDER_AMT`, the order's three link columns, the duplicate 409, the
व्यंजन refusal, लोप ३ on the same order as `SRVC`, 404 for an unknown number. **The browser test needs
the image RESTARTED** (new dispatcher line + new functions). The ABAC pair is NOT a boot seed: it is
`migrate-2026Oct-ordinvoice-policy-and-transaction` in `installation/upgrades/nst-dbu-order-policy-transaction.lisp`,
registered in `*migrations*`, **applied and recorded** (`06102026-vendor-order-invoice-policy` in
`DOD_SCHEMA_MIGRATIONS`, policy row linked to its own transaction, re-run verified as a no-op).

**Five traps were measured, all recorded in `knowledge/ord-to-inv-junction-CONTEXT.md`:** a DB-side
trigger re-derives `INVNUM` from `ROW_ID` (so what `make` returns is not what the table stores, and
`hhubuser` cannot see the trigger); `VNUM` is `varchar(20)` and TRUNCATES a 23-27 character ORDNUM;
the grammar's `ord-id` column is missing from `DOD_INVOICE_HEADER`; `NstInvhResponseModel` is not an
`nst-response-model`, so a route returning one 500s in `domain->response`; and `paninigrammar/` has no
Document 3 although three documents cite it.

## 13. ⚠ The CART's GST state comparison — interstate tax on an intra-state sale · diagnosed 2026-10-06

One `(equal vstate placeofsupply)` on two RAW strings: the customer's **typed state NAME** ("Karnataka")
against the vendor row's `state` column, which holds a **CODE** for vendor 1 ("29") and a **NAME** for
vendors 2-3 — so a Karnataka→Karnataka sale goes interstate. Measured in live data: order 488's line carries
IGST 205.20 with CGST/SGST 0.00. Both channels are affected (the customer cart and the ORDER API's line
writer, which mirrors the legacy call). **Full diagnosis, evidence and the four-part fix with its open
decision: `knowledge/gst-tax-jurisdiction-CONTEXT.md` §2–§3.**

## 14. ⚠ The order-line tax RATES are never stored · measured 2026-10-09

**The vendor page's numbers are fixed** (`/hhub/vorderdetailspage?id=503`): `calculate-order-item-cost` is a
**per-unit** cost and added the whole LINE's tax before every one of its nine callers multiplied by `prd-qty`,
so the vendor's stored `ORDER_AMT` was too high by exactly `(qty-1) x that line's tax` — order 503 read
**7006.71 where the Place Order page said 6832.87** (the excess is 173.84 = 2 x 86.92 on a qty-3 line). The
row's **Unit Price** column printed the line's taxable value, its **Sub-total** printed `totalitemval x qty`,
and the rate columns printed `NIL` because the stored rate is NULL; all three are fixed (Unit Price is now the
NET per-unit price, so the row reconciles). The **9 already-written vendor rows** are repaired — via
`migrate-2026Oct-vendor-order-amount-repair`, registered in `*migrations*`, whose `line_total > 0` guard is
load-bearing (without it the same statement zeroes 371 demo rows it cannot derive from). Full record:
`knowledge/order-line-money-CONTEXT.md`.

**OPEN — the writer drops the tax RATES.** `CGST`/`SGST`/`IGST` are NULL on **every** line of every order
475–503, and on 503 only **2 of 6** lines stored any tax amount at all, although two of the others are
taxable goods. `update-gst-for-order-lineitem` sets those slots, so the break is between the cart's line
objects and `persist-order-items` — this is the evening's work. It is a GSTR-1-grade gap, not a display one:
a rate column that is never populated cannot feed a return, and the display's derived percentage **hides**
that it is missing. Restart the image for the page changes; regenerate
`hhub/core/nst-bl-funloodat.lisp` so `nst-symq` knows the new `nst-order-item-tax-rate`.

## 15. 🟡 US-012 — the order reference on an invoice: **APPLIED**, awaiting a rebuild + live test · 2026-10-12

The first slice of the **E1 Order to Invoice** epic (`order-to-invoice-flow-CONTEXT.md`): the design's D1
line "the order ID is stored on the invoice", which before this did not hold in any readable form —
the only tie was `CONTEXT_ID`, and that is the CART's `uuid:make-v1-uuid`, not the order number anyone
quotes.

**What is written and offline-verified.** Three nullable columns in
`installation/upgrades/nst-dbu-invoice-order-link.lisp`, registered in `*migrations*` as
`12102026-invoice-order-link`: `DOD_INVOICE_HEADER.ORDER_NUMBER varchar(50)` + `.ORDER_ID mediumint`,
`DOD_INVOICE_ITEMS.ORDER_ITEM_ID mediumint`, plus three indexes. Four slots added across
`nst-dal-invh.lisp`, `nst-dal-invitm.lisp`, `nst-bl-invh.lisp`, `nst-bl-invitm.lisp` (mirror lists,
response models, `render-json`), and the junction now writes `:order-number` / `:order-id` /
`:order-item-id`. **Proven offline:** `nst-preflight` PASS, and
`nst-invoice-mirror-check` **55/55 header + 19/19 item** slots with no `MISSING-SLOT` (was 53/18).

**✅ APPLIED 2026-10-12 as `hhubadmin` — and what remains is a rebuild and a live test, not a grant.**
`hhubuser` holds only `SELECT, INSERT, UPDATE, DELETE` on `hhubdb` (`SHOW GRANTS`), so the migration has
to run as a privileged account; it was applied with `(load-upgrade-files)` then
`(apply-migrations "hhubadmin" …)`.

**🚨 THE PRIVILEGE LESSON, because it will bite the next DDL migration.** `hhubadmin` held `ALTER` but
**not `INDEX`** — MySQL separates them — so the run created both header columns and then died on the
first `CREATE INDEX` with **Error 1142 / INDEX command denied**. `apply-migrations` catches
PER-MIGRATION and continues **without recording the version**, so that run ended looking successful with
2 of 6 statements applied and the migration still pending. The grant that fixes it is database-scoped
(`INDEX` cannot be granted per table):

```sql
GRANT INDEX ON hhubdb.* TO 'hhubadmin'@'localhost';
```

The re-run then finished cleanly, and it was harmless **only** because `add-column-if-absent` /
`add-index-if-absent` (in `nst-sch-mig.lisp`) printed `already present - skipping` and completed the rest.
**Both facts belong to every future DDL migration: guard every ADD, and make sure the operator account
holds `ALTER` + `INDEX`.** Full account: the header of `nst-dbu-invoice-order-link.lisp`.

**Verified against the live catalog after the apply:** `DOD_INVOICE_HEADER.ORDER_NUMBER varchar(50) NULL`,
`.ORDER_ID mediumint NULL`, `DOD_INVOICE_ITEMS.ORDER_ITEM_ID mediumint NULL`; `idx_invh_order_number`,
`idx_invh_order_id`, `idx_invitm_order_item` all present and NON_UNIQUE; and
`12102026-invoice-order-link` recorded in `DOD_SCHEMA_MIGRATIONS`.

**⛔ WHAT REMAINS — the image predates the code.** The running process started **18:35** on 2026-10-12;
the invoice sources were edited at **19:30** and compiled at 19:36, so the live HTTP server does not carry
the new slots and the junction cannot write them. **Rebuild and restart** — `(compile-production)` s
incremental **by deletion** (`clean-and-compile` is the only force). Then prove it, because the DDL is the
easy half and the **junction is the thing to test**: create an invoice from a fulfilled order and assert
the header carries the order's `ORDNUM` and row-id, each goods line carries its order-line row-id, the
synthesised delivery line's `ORDER_ITEM_ID` is NULL, and the invoice JSON carries `orderNumber` /
`orderId` / `orderItemId`. Existing rows stay NULL by the no-backfill decision below — that is expected,
not a gap to chase.

### 🚨 THE FIRST LIVE RUN FAILED, AND THE REASON IS A RULE ABOUT EVERY NEW COLUMN (2026-10-12, order 508)

Generate Invoice on **order 508** answered:

```
the slot COM.NSTORES.APP::ORDER-NUMBER is missing from
#<COM.NSTORES.APP::DOD-INVOICE-HEADER>
   from NST-COPY-INVOICE-HEADER-DOMAINTODB → nst-invh `make`
```

**CAUSE: a new column needs FOUR declarations, not three — and the fourth is the CLSQL VIEW CLASS.**
`*invh-mirrored-slots*` drives `(setf (slot-value destination slot) …)`, and the destination is a
**`dod-Invoice-Header`** (`nst-dal-ihd.lisp`), NOT the domain class. The four columns had been added to
the DB (US-012) and to `nst-invh` + `NstInvhResponseModel` (both), but not to the view class — so the
domain object carried the value and the row object had nowhere to put it. The same applies to
`dod-invoice-items.ORDER_ITEM_ID` (`nst-dal-itm.lisp`).

**FIXED:** `dod-Invoice-Header` now declares `order-number`, `order-id`, `invoice-locked`,
`unlocked-by-user-id`, `unlocked-by-vendor-id`, `unlocked-at`; `dod-invoice-items` declares
`order-item-id`. Timestamps use `clsql:wall-time`, matching the class's own `created`/`updated`.

⚠ **AND THE CHECKER THAT SHOULD HAVE CAUGHT IT COULD NOT, WHICH IS THE MORE IMPORTANT HALF.**
`nst-invoice-mirror-check.lisp` compared the mirror list against the **entity and the response model**
only — it never loaded the view class, so it reported **PASS** through this defect. It now loads
`nst-dal-ihd.lisp` and `nst-dal-itm.lisp`, carries the view class as a **sixth** element of every pair, and
reports `MISSING on VIEW (…)`. It also **fails when the view class is not loaded**, rather than passing
silently — a check that skips its own target is how a broken file reads green.

**MUTATION-TESTED BOTH WAYS:** with `order-number` deleted from the view class it prints
`MISSING on VIEW (DOD-INVOICE-HEADER) = (ORDER-NUMBER)` and exits 1; restored, it passes. Current state:
**59/59 header and 19/19 item** slots declared on entity, response AND view class.

⚠ **Why the fix could be made at all, and why the earlier attempt could not:** the view-class slots only
WORK once the DB columns exist, and US-012's migration had been applied (`ORDER_NUMBER`/`ORDER_ID` are
live). The lock columns are NOT live yet, so this fix is correct but **still untestable until
`12102026-invoice-lock` is applied** — applying it is now a prerequisite for Generate Invoice on any
order whose vendor has the lock setting on, not merely a nice-to-have.

* ⚠ **NO BACKFILL, by decision.** The 10 order-linked invoices (ROW_ID 112–141) are recoverable by
  joining `CONTEXT_ID` → `DOD_ORDER.CONTEXT_ID` and deliberately are not: the standalone path's rows are
  not resolvable at all, so a partial backfill would leave two populations that look alike and mean
  different things.
* ⚠ **The PDF half is NOT done** — `nst-ui-ihd.lisp:1290-1291` still has the `%Order Number%`
  substitution commented out, and `gstinvoice2.html:109` still holds the raw token, so a vendor on
  template 10 prints `%Order Number%` to their customer. That is the next slice, and it touches the
  LEGACY renderer shared with the standalone invoice (design D4).
* ⚠ **Also open:** `ORDER_ITEM_ID` is a **`DOD_ORDER_ITEMS.ROW_ID`**, which is sequential and
  enumerable. It is stored as raw attribution, never as an address, which is why that is acceptable here
  and would not be for an order number (F1).

## 16. 🚨 NINE orders are marked invoiced with NO invoice number · measured 2026-10-12

`IS_CONVERTED_TO_INVOICE='Y'` on **9** `DOD_ORDER` rows whose `INVOICE_NUMBER` is **NULL** — while the
junction's own link write sets all three columns or rolls the whole invoice back
(`nst-bl-invhapi.lisp:1361-1373`, whose refusal sentence is "the order would not know it was
invoiced"). The invoices that DID get their numbers written are the recent ones (10 headers match an
order on `CONTEXT_ID`, ROW_ID 112–141), so there are **two link-write populations in the data** and only
one of them is complete.

**What the vendor sees:** `vendor/dod-ui-ven.lisp:3393` renders `INVOICE <num> (DRAFT)` with
`(or invoicenumber "?")` — those nine orders show **`INVOICE ? (DRAFT)`** on the order details page, and
the page also suppresses the *Generate Invoice* button for them, so the vendor can neither see the number
nor re-raise the invoice.

**The fix is not chosen yet — this is a ledger entry, not a diagnosis.** Three shapes, in the order they
should be considered: (a) repair `INVOICE_NUMBER` for those nine from the invoice found by
`CONTEXT_ID`; (b) find why a link write left the flag set without the number (a legacy writer, or a
partial write before the junction's transaction existed) and stop it recurring; (c) make the READ path
stop depending on all three columns — once the invoice carries `ORDER_NUMBER` (§15) the number can be
read from the invoice side instead of the order side. Do NOT fold this into §15's migration: they are
different populations and different causes.

## 17. 🟡 US-013 — the invoice edit lock: the STATE, the GUARD and the VERB exist; the ROUTE and the BUTTON do not · 2026-10-12

Raised by the requester: *"a vendor would not like to modify the invoice if it is originated from an
order… a lock invoice button which will be locked by default if it is originated from an order… we will
note it in a column named invoice unlocked by and time."*

🚨 **THEN REVISED BY THE REQUESTER THE SAME DAY, AND THE REVISION IS THE DESIGN:**

> *"In India … when you order something and the invoice is prepared for that order, generally people add
> more items in the nick of time after the order is placed as well. To accommodate such use cases, I
> thought we should keep the invoice open ended and leave it to the vendor's discretion. In fact, we can
> create a vendor setting about it. So the column in the invoice header stays. Let the custom setting
> decide what the vendor wants to do with it."*

So the rule is **not** "order-originated invoices are locked". It is: **the column stays, a vendor setting
decides the default, and the vendor can still lock or unlock any single invoice by hand.** An earlier
version of this change hardcoded `:invoice-locked "Y"` in the junction and backfilled the 10 order-linked
invoices to `'Y'`; **both were withdrawn** — the second because it applied a choice no vendor had made in
order to make a default look already-true.

**The setting.** `lock-order-derived-invoices-invoice`, shipping under `security-settings` in
`*invoice-settings*` (`hhub/invoice/templates/invoicesettings.lisp`) as `(enabled nil)`. **ABSENT OR NIL
MEANS DO NOT LOCK**, which is the requester's own case: a vendor who adds items after the order must not
pay a per-invoice Unlock on every invoice. Read by `invh-lock-order-derived-invoices-p`
(`nst-bl-invhapi.lisp` §9) through `invh-vendor-registry-value` → `invh-settings-find`.

**Two measurements that shaped the reader, both worth keeping:**
1. **`DOD_VEND_PROFILE.INVOICE_SETTINGS` carries ONLY `INVOICE-PRINT-SETTINGS`** — **0 of 15 vendors** have a
   `security-settings` section in their blob, because the settings page writes only the print section. A
   reader that walked to `security-settings` first would have found the key for **nobody** and the setting
   would have looked wired while being permanently unreadable. `invh-settings-find` therefore searches the
   whole tree recursively, matching keys with hyphens removed (the JSON round-trip spelling).
2. **A nested section shares its parent's key namespace** — the reader returns the SECTION, so the value
   is unwrapped by `invh-settings-boolean`, which understands both a leaf `t`/`nil` and an `(enabled …)`
   sub-section, plus the string `"true"` a JSON round-trip can produce.
3. 🚨 **`(cdr (assoc-style pair))` IS THE WRONG READ FOR THE SHIPPED SHAPE, AND IT FAILS SILENTLY.** A
   shipped entry is a two-element LIST, `(enabled t)`, so a "pair" built as `(key . tail)` has `cdr` =
   **`(t)`** — a LIST holding the value, not the value. Three versions of the reader were written before
   this was found: the first matched only cons-headed keys (missing every shipped default), the second
   returned the greedy tail, and only the third returns the VALUE (`cadr` for `(key value)`, `cdr` for a
   dotted `(key . value)`). ⚠ **The failure is invisible to a truth test** (`(nil)` and `(t)` are both
   non-nil) and my first unit test *passed* because it hand-wrote the JSON shape `((enabled nil))`. The
   test that settles it extracts the definitions from the source and covers all eight shapes — shipped
   `(enabled nil)`/`(enabled t)`, JSON `(:enabled . "true"/"false")`, a plain leaf, an absent key, a
   sibling key, and a deeper nesting. **Reuse that shape of test, not a hand-copied one.**

**What else shipped.** `installation/upgrades/nst-dbu-invoice-lock.lisp`, registered as
`12102026-invoice-lock`: `INVOICE_LOCKED char(1) NOT NULL DEFAULT 'N'`, `UNLOCKED_BY_USER_ID`,
`UNLOCKED_BY_VENDOR_ID`, `UNLOCKED_AT` — **four columns and no data change at all**. Four mirrored slots;
`render-json` publishes `invoiceLocked`, `unlockedByUserId`, `unlockedByVendorId`, `unlockedAt`.
**Proven offline:** `nst-preflight` PASS; `nst-invoice-mirror-check` **59/59** header slots (was 55); the
whole tree loads. The migration calls a READ-ONLY census that reports how many headers resolve to a live
order (**10 of 45**, measured) so the population stays visible without being acted on.

**🚨 NOT APPLIED — CHECK THIS BEFORE THE NEXT RESTART.** Measured 2026-10-12: `DOD_INVOICE_HEADER` has
`ORDER_NUMBER` and `ORDER_ID` (US-012's migration ran) but **NONE of the four lock columns**, and
`DOD_SCHEMA_MIGRATIONS` carries no `12102026-invoice-lock` row. The running image started **18:35** and
still carries the OLD junction, so nothing writes `INVOICE_LOCKED` today — **but the newly compiled fasls
do.** Restarting or reloading the image before applying this migration makes `POST` / Generate-Invoice
build a params plist containing `:invoice-locked`, and `dod-invoice-db` has no such slot, so the
`clsql:update-records-from-instance` INSERT dies with a MISSING-SLOT **and the whole assembly rolls back**
— every Generate Invoice fails, on a database whose version table says the migration is fine. **Apply the
migration first, then restart.** Same two commands, same `ALTER`+`INDEX` grant note as §15.

⚠ **THE SETTING IS NOT YET ON THE SETTINGS PAGE.** `security-settings` is in the shipped defaults but the
page's template renders only the logo and print forms (`com-hhub-transaction-invoice-settings-page`
formats exactly two arguments into `invoicesettings.html`), so this key — like `allow-invoice-deletion` and
`allow-invoice-edit-after-generation` before it — is readable in the blob but has no control. Until that
pane exists, the effective default for every vendor is the shipped `(enabled nil)`, i.e. **open ended**.

**✅ THE GUARD AND THE VERB LANDED 2026-10-12 — the lock is now a control, not a state.**

* **The guard** is in `nst-invh`'s `!update` (`hhub/invoice/nst-bl-invh.lisp`), AFTER the row is read and
  BEFORE anything is written, so it reports on the row that exists and cannot be gone around: the API, the
  UI and any future caller all arrive at this one seam. It **refuses with a contradiction → 409** and
  writes nothing, rather than silently dropping fields — the order side's
  `*ordh-never-writable-fields*` takes the same position for the same reason. Only the LOCK MISSED by the
  guard: `invh-lock-audit-fields-p` is a **negative** list, so a call touching only
  `:invoice-locked`/`:unlocked-by-*`/`:unlocked-at` passes and every other field is refused. A negative
  list is chosen deliberately — a field added to `nst-invh` later is protected by DEFAULT rather than
  being silently left out of a positive allowlist.
* **The verb** is `lock!` on `nst-invh`, one method for both directions (`:locked "Y"` / `"N"`), because a
  lock and an unlock are the same fact written two ways. It writes the four columns **ONE AT A TIME**
  through `update-record-from-slot` — the order side's link-marker shape — so a concurrent write to any
  other column cannot be clobbered by a whole-row write carrying a stale snapshot. The actor is the
  **session vendor** and is never taken from a payload.
* **⚠ `lock!` reads the session ITSELF rather than calling the order layer's `vordh-session-vendor`**:
  that helper does the identical read but lives in `order/nst-bl-vordhapi.lisp`, which the asd loads AFTER
  the invoice section, so using it would make the invoice domain depend backwards on the order domain for
  five lines — and break any image that loaded the invoice half alone. Same read, same fail-closed rule.
* **Verified:** the guard's decisions are unit-tested on **ten cases** (locked + each kind of field,
  locked + no args, the audit quartet alone, the audit quartet mixed with a real field, unlocked, and a
  NULL lock column) — all correct; `nst-preflight` PASS, `nst-invoice-mirror-check` PASS (59/59), and the
  tree loads (`STAGE: LOADED`).

**✅ THE ITEM SIDE IS GUARDED TOO (2026-10-12).** A locked invoice's LINES are its content, so the line
route was the hole the header guard could not close. `invitm-header-lock-guard`
(`hhub/invoice/nst-bl-invitm.lisp`) resolves the parent through the EXISTING
`nst-fetch-visible-invoice-header`, so scope and lock are one query and a line whose parent is another
tenant's or soft-deleted still answers 404 — a lock is never reported as an authorization fault. It gates
**all three** item verbs: `make` (adding a line changes what the document says just as editing one does),
`!update`, and `delete!`.

⚠ **THE GUARD IS ON THE VERB, NOT THE ROUTE, AND THAT IS LOAD-BEARING.** The vendor's own invoice pages
call these verbs **in-process** through the dispatcher (`dispatch-route2`), never over HTTP — a check in
`route-invitm-update` would protect an API caller and leave the UI wide open. The verbs are the seam every
caller crosses, which is why the check lives there and the route needs nothing added to it.

**THE GUARD MAP, as it stands — every write crossing on the invoice and its lines:**

| verb | guarded by | notes |
|---|---|---|
| `nst-invh` `!update` | `invh-locked-p` + `invh-lock-audit-fields-p` | the lock's own columns stay writable; everything else refused |
| `nst-invh` `lock!` | the lock's own verb | the ONE writer of those four columns |
| `nst-invitm` `make` / `!update` / `delete!` | `invitm-header-lock-guard` | all three, so no line operation slips past |
| `nst-invh` `delete!` | ⚠ **NOT guarded** | it is DRAFT-only (`*invh-deletable-statuses*`) and a locked order-derived invoice **IS** a DRAFT, so this is a **real gap**: a locked invoice can still be soft-deleted. One `invh-locked-p` check; **do it next.** |
| `nst-invh` `!settings` | n/a — vendor-scoped | the blob belongs to the vendor, not to one invoice |

**⛔ STILL TO BUILD: the route and the button.** `lock!` is a Tier-1 प्रत्यय with **no action route and no
API binding yet**, so nothing can call it over HTTP — it is reachable only from Lisp (a REPL or a UI
controller). And the vendor page has no *Lock / Unlock* control, so a vendor whose setting turns the lock
on has **no way to release it**. ⚠ The route must NOT accept a `:vendor-id` or any actor from the body,
and must map a contradiction to 409, like every other invoice verb.


**THE LOCK HAS ONE REASON, BY DECISION (2026-10-12).** The requester: *"let's go with order-to-invoice
flow lock and that is the reason. Will extend it later."* So there is **no reason column and no reason
code** — the reason is IMPLIED BY THE DOCUMENT: an invoice carrying `ORDER_NUMBER`/`ORDER_ID` is the one
the junction produced, and that is why it is protected. A multi-reason design (a lock ledger keyed by
reason, with a settings catalogue of reason codes and per-reason release authority) was designed and
**deliberately not built**; it is additive later — a reason column or a ledger beside these columns —
not a rewrite. Recorded so the next session does not re-derive it: the four columns ARE the single-lock
model, and `INVOICE_LOCKED` + `UNLOCKED_AT` + actor is its complete audit.

**Decisions taken, with their reasoning, so they are not re-litigated:** a **stored** flag rather than a
derived "locked iff order-linked and never unlocked", because a derived rule has no way BACK after an
unlock; **per document, not per field**, because a field list would have to decide which columns matter
and would be wrong for some vendor's process — the requester refused to draw that line and said *"leave it
open, the vendor will decide what is right for them"*, which is what the per-document lock plus the
setting delivers; **the default is OFF**, because the requester's own case is the vendor who adds items
after the order; and the column is `INVOICE_LOCKED` because **`LOCKED` is a reserved word in MySQL 8**, so
a column of that name works only behind backticks, which the FORMAT-built migration statements cannot be
trusted with.

**Market note (why this is not a made-up control).** It is the standard accounting pattern: SAP refuses
changes to a **posted** invoice outright (*"Invoice document … cannot be changed"*) and uses period locks
alongside; Concur models the AP equivalent as a hold/exception workflow; Indian GST has no "edit an issued
invoice" instrument at all — the correction is a **credit note**. The recorded "who and when" is what
makes the lock a CONTROL rather than a convenience. ⚠ The one market caveat worth carrying: ERPs do this
*silently* (you invoice from the order and editability is simply not offered), and a quick SMB tool like
Zoho Books expects a draft to be freely editable — so the feature earns its place only while the default
is locked and unlocking stays rare. **All ten order-linked invoices are still DRAFT**, so nothing is
locked that a buyer has already seen; that window closes when invoices start reaching AP systems.

---

## 18. 📋 THE PENDING INVOICE STORIES — the invoice/epic backlog, in one place · 2026-10-12

**Read this when:** you are picking up invoice work and want the open stories rather than the diagnoses
above it. Each row is a story with acceptance criteria and the ID it should be tracked under; the detail
behind each one is in the section named in its last column. **Nothing here is blocked on a design
decision** — every row is unstarted work with a settled shape.

| ID | Title | What it is | Acceptance criteria | Pts | Depends on | Detail |
|---|---|---|---|---|---|---|
| **US-013a** | *Lock / Unlock* route and button | `lock!` (`nst-invh`) has **no action route, no API binding and no control**, so a vendor whose setting turns the lock on has **no way to release it** — the feature can strand them | A vendor can lock and unlock an order-derived invoice from the invoice page; the action records WHO (session vendor) and WHEN; both directions work; a contradiction maps to 409; the actor is never read from the body | 3 | — | §17 |
| **US-013b** | Lock guard on the header `delete!` | `nst-invh`'s `delete!` is DRAFT-only and a locked order-derived invoice **is** a DRAFT, so a locked invoice can still be soft-deleted | `delete!` refuses a locked invoice with a contradiction → 409; an unlocked one still deletes as before | 1 | — | §17, the guard map |
| **US-014** | **The invoice settings *Security* pane — put the lock setting in front of the vendor** | `lock-order-derived-invoices-invoice` is **shipped as a default and unconfigurable**: the settings page renders only the logo and print widgets (2 `~A` slots), and the save action writes `invoice-print-settings` alone. Measured: **0 of 15** vendor blobs carry the key | A *Security* pane on `/hhub/vinvoicesettingspage` with a control for **Lock invoices generated from an order**; saving writes ONLY the `security-settings` section (the existing one-section discipline, which is what stops the blob being wiped); the page reflects the stored value on reload; the other two `security-settings` keys (`allow-invoice-deletion`, `allow-invoice-edit-after-generation`) become visible in the same pane rather than staying unexposed; a backfill migration adds the key to the 15 stored blobs so the stored copy and the shipped default agree instead of relying on the fallback | 5 | a rebuild + restart (the in-image `*invoice-settings*` is what the fallback reads) | §17, and the measurement in the story file |
| **US-015** | Invoice numbering that satisfies Rule 46 | The invoice number is owned by a **MySQL trigger** (`NST<row_id>-<year(now())>`), so there is no per-GSTIN series, no April–March FY reset, and `invoice-number-format` is never consulted. The ORDER side already proves the machinery (`DOD_DOC_COUNTER`, `nst-format-doc-number`) | Unique per GSTIN per FY; ≤16 characters; the series resets each FY; no gaps from system errors; written past the trigger and re-read, as the junction already re-reads the stored row | 5 | — | `order-to-invoice-flow-CONTEXT.md` US-005 |
| **US-011** | E-invoice applicability flag + IRN | No vendor-profile flag exists; `E_INVOICE_REQUIRED` and the `IRN`/`ACK_*` columns are live on `DOD_INVOICE_HEADER` and empty; `generate-irn` is a गण verb name with no implementation | A turnover/applicability declaration on the vendor profile; when applicable and no IRN is recorded the invoice is marked **not valid for ITC** and the buyer is warned; the IRN renders on the tax invoice | 5 | US-015 (the IRN references the number) | `order-to-invoice-flow-CONTEXT.md` US-011 |

**Order to work them:** **US-013a first** — it is the only one that can leave a vendor stuck, and it is the
smallest. Then US-013b (one line). US-014 is the one that makes the lock setting real rather than
theoretical, and it is worth doing before US-015/US-011 because it needs no GST reasoning at all.

⚠ **US-014 HAS A DESIGN TRAP ALREADY MEASURED, so do not re-derive it:** the pane must be a **third** `~A`
slot rendered by `create-model-for-invoicesettingspage`, because the template's only two slots are the logo
block and the print form — and the save action must be its own route (the print action can only ever write
`invoice-print-settings`). Also: **do not read the setting through a fixed path** — `invh-settings-find`
searches the whole blob because the stored sections and their key spellings differ between a shipped
default and a JSON round-trip (hyphens are dropped on the way back).



