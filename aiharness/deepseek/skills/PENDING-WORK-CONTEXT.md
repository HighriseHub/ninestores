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

| # | what | why it matters | state |
|---|---|---|---|
| **1** | **The transaction seam (O3)** — `POST /orders` writes header → lines → stock → vendor rows with no transaction around them | a failure after the INSERTs leaves a half-built order: **five measured 500s left orders 491, 494-497 and 499** with their lines and vendor rows, and cleanup could not key on a `rowId` that never arrived | **AGREED 2026-10-05** — wrap header + items + vendor rows in one transaction. ⚠ `delete!` now writes THREE tables too (lines → vendor rows → header) and belongs in the same change |
| **2** | **A vendor DELIVERY table** — the vendor must read the items it ships and mark fulfilment per item | today a vendor cannot see *what* to ship: the vendor channel has no line endpoints and `nst-orditm`'s `enumerate` filters by order, not vendor | **DECIDED 2026-10-05**: a separate vendor-delivery table, not line fields on `DOD_ORDER_ITEMS` — the standard pattern, and a feature the requester wanted anyway. Design: one row per (vendor order, order item) with quantity, status, shipped date |
| **3** | **`UPDATED` is frozen (F8)** | the vendor ETag never changes, so `If-Match` cannot detect a concurrent write — see §10 | fix shape verified (name the write's columns, omit `UPDATED`, KEEP `ord-date`) |
| **4** | **The customer channel emits NO ETag** | its `If-Match` is unusable: a client cannot obtain a validator, so the 412 machinery is reachable only with an invented token | open |
| **5** | **A LINE has no per-channel field allowlist and no version token** | the header and the vendor row each have both (F5); a customer may assign any declared line initarg, and two editors of one line are last-write-wins | open — a decision, not a test |
| **6** | **F12 / F16 — two contract decisions** | `PUT`-with-merge vs `PATCH`; and whether `POST /orders` should handle OTP + wallet, which the product's own spec text promises | open |
| **7** | **`IS_CONVERTED_TO_INVOICE='Y'` has no fixture** | 0 of 489 rows, so the order→invoice refusal is NOT TESTED (the writable-field half is) | open |
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
