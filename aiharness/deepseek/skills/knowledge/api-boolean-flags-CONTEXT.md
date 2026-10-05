# SKILL: api-boolean-flags — the JSON layer cannot emit `false`

**Read this when:** a flag field in an API response comes back `null` instead of `false` —
`"active":null` after a successful turn-off; a client's `x.active === false` never matches
although the database row clearly says `'N'`; or you are about to publish a boolean from an
`-flag->boolean` helper anywhere in the tree.

**Status:** found **2026-09-20** by the products status endpoint's read-back assertion;
diagnosed the same day and **the fixes below were verified — the defect is NOT YET FIXED**.
Originally `nst-bl-prdapi-CONTEXT.md` §8b; moved to this file on **2026-10-05**, section
number preserved, content unchanged.

**Applies to:** `hhub/products/dod-bl-prd.lisp` (`prd-flag->boolean`),
`hhub/core/nst-bl-conflodis2.lisp` (`conflodis2-json-text`), and **every** response that
publishes a lifecycle flag — products, vendor profile, vendor shipping, vendor payment.

---

## 8b. 🚨 FOUND 2026-09-20 — the products API cannot emit `false`

**Status: diagnosed and fixed options verified; NOT YET FIXED.** Found by the
`test/smoke-products-api.sh` §6d read-back assertion added for the status endpoint — the
assertion was correct and the code is wrong, so the test stays.

**Symptom.** `PUT …/status {"status":"inactive"}` returns 200, the database really does
hold `ACTIVE_FLAG='N'` (verified by SQL on row 126), and the product GET then reports
`"active":null, "approved":null, "subscribed":null`.

**Cause, in two steps.** `prd-flag->boolean` (`dod-bl-prd.lisp:1490`) ends in
`(string-equal value "Y")`, so it returns **`T` or `NIL`** — Lisp truth values, not
`T`/`NIL`-as-true/false. And `conflodis2-json-text` encodes with
`json:encode-json-to-string` under cl-json's **guessing encoder**, which maps `t` → `true`
and `nil` → `null` — **not** `false`. So `"N"` and an unset flag both publish `null`, and
**JSON `false` is unreachable from an alist value with that encoder.** cl-json's
`(:true)`/`(:false)` markers are for its *explicit* encoder only; passing `'(:false)` in an
alist makes the guessing encoder emit an ARRAY (`[["active","false"]]`), which was verified
rather than assumed.

**Blast radius — this is not products-only.** `vnd-flag->boolean` (`nst-bl-vnd.lisp:930`)
deliberately delegates to `prd-flag->boolean`, so the vendor profile, vendor shipping and
vendor payment responses have the same defect. Anywhere the API promises a boolean flag, a
client gets `true` or `null`.

**Why it went unnoticed.** Every existing assertion tested a flag that was ON, or did not
test the value at all. `"active":null` is falsy in JavaScript, so a client doing
`if (p.active)` behaves correctly by accident — but `p.active === false` does not, and **a
client cannot distinguish "off" from "never set"**, which is the distinction this whole
design is built on.

**The two verified fixes:**

| fix | effect |
|---|---|
| **A marker object.** `(defclass json-false () ())` + `(defmethod json:encode-json ((x json-false) &optional stream) (write-string "false" stream))`, then have `prd-flag->boolean` return it for false. | Verified: `{"active":false,"approved":true}`. Keeps the boolean contract; one small class, and every flag-returning response in the tree inherits the fix. |
| **Publish the raw `"Y"`/`"N"` strings**, as warehouse already does (`nst-bl-prdapi-CONTEXT.md` §5 records that divergence as deliberate). | No encoder problem at all, but it reverses a documented decision and gives up `if (p.active)`. |

Either way the change is **wire-visible for every product and vendor response**, so it is
a deliberate decision rather than a cleanup.
