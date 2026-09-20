# Vendor API — `render-json` stays in adhara (SETTLED) · CONTEXT

**Split out of `nst-bl-vndapi-CONTEXT.md` on 2026-09-20** for the 400-line budget.
Section number preserved from the parent. **Content is unchanged.**

**Covers:** the settled decision that `render-json` lives in `core/nst-bl-adhara.lisp`
and is NOT re-hosted elsewhere — with the four arguments for it (§11.1–11.3), and the
real defect underneath, the SPLIT CONTRACT, which is a separate and smaller task (§11.4).

**Read this when:** you are tempted to move, fork or replace `render-json`; or you are
chasing the split-contract defect and want to know it was already diagnosed.

⚠ The heading says *Do not re-litigate this.* It was argued through on 2026-09-14 and the
reasoning is recorded here so it does not have to be re-derived.

## 11. SETTLED — `render-json` stays in adhara. Do not re-litigate this.

Asked on 2026-09-14: *given that apidefs2 is the JSON API layer and already emits JSON,
is `render-json` in adhara still needed?* The answer is **yes, keep it**, and the
reasoning is recorded here because the question is a good one and will occur again.

### 11.1 It is on every request path, and apidefs2 could not replace it

```
api-run-route (apidefs2:575)
 └─ api-render-json (:415)
     └─ conflodis2-render  (:225)
         ├─ render-json            ← its only 2 call sites, both here (:238, :245)
         └─ conflodis2-json-text → json:encode-json-to-string (:214)
 └─ api-write-json (:423)          ← content-type, status code, abort
```

apidefs2 DELEGATES to `render-json`; it does not supersede it. And it could not:
apidefs2's only encoder call is `api-error-json` (:432), which encodes a hand-built
alist. **There is no cl-json encoder for any response model anywhere in the tree** —
`json:encode-json-to-string` has nothing to walk for a `VendorResponseModel`.
Something must convert the object to an alist first, and that is `render-json`.

Three things live there that apidefs2 structurally cannot know:

1. **The field allowlist** — the security boundary. For vendor it is what keeps
   `password`, `salt`, `payment-api-key` and `payment-api-salt` off the wire.
2. **Wire naming** — `vnd-name` → `"name"`, `rowId`, camelCase throughout.
3. **Type conversion** — Y/N → boolean (`vnd-flag->boolean`), integer id → JSON
   string (`response-id-string`).

These are DOMAIN decisions — which fields exist, what a flag means, how an id crosses
a boundary. Put them in apidefs2 and the API layer starts holding business rules, which
is the invariant the whole architecture exists to prevent.

### 11.2 There is no "crisscross" — the dependency is already inverted

Checked 2026-09-14, because the claim was worth testing rather than accepting:

* **adhara names no entity in code.** Every occurrence of `nst-whs`/`nst-prd`/`nst-vnd`
  is a comment or docstring, except one line inside
  `test-niyam-fires-on-domain-entity-not-boundary` (a test constructing an `nst-whs`).
* **apidefs2 names no entity in code.** Its mentions (lines 82, 83, 354) are all
  comments.

```
adhara          defgeneric render-json  ← pure contract, names nothing
   ↑
vendor/warehouse/products   defmethod  ← the domain-specific decisions
   ↑
conflodis2      calls render-json
   ↑
apidefs2        calls conflodis2-render
```

Dependencies point inward; adhara depends on nothing. Textbook dependency inversion,
already implemented.

### 11.3 The "core render-json + a derived one" alternative is already what exists

That is `defgeneric` (the core seam) + `defmethod` (the derived specialisation). No
base class, no override machinery — CLOS multiple dispatch does the split for free.

**And the obvious "core" implementation is a trap.** A default method on
`nst-boundary-object` that reflects all slots would publish `password`, `salt`,
`payment-api-key` and `payment-api-salt` for vendor the moment someone forgets to
write a method. Today a missing method signals `no-applicable-method` — **it fails
closed.** A reflective default would fail **open**. The objection to that alternative
is safety, not complexity.

### 11.4 The real defect is the SPLIT CONTRACT — a separate, smaller task

`render-json` does two incompatible jobs depending on which method you are in:

| Returns a **Lisp alist** (3) | Returns already-encoded **JSON text** (7) |
|---|---|
| `WarehouseResponseModel`, `ProductResponseModel`, `VendorResponseModel` | `nst-customer-response-model`, `warehouse-ack-response`, `nst-response-nil` / `-unknown` / `-contradiction`, `render-json ((responses list))`, `ping-response` |

`ping-response` returns a hardcoded JSON string literal. Consequences:

* `conflodis2-json-text` must sniff the value's TYPE to guess its meaning —
  `(if (stringp rendered) rendered (json:encode-json-to-string rendered))`. A string
  means "already JSON" in one method and would mean "a JSON string value" in another.
* Encoding is duplicated across **five** sites: `conflodis2:214`, `whsapi:310`,
  `whsapi:337`, `Customer:669`, `apidefs2:432`.
* Nothing validates that the text-returning methods emit well-formed JSON.

**The fix, when someone takes it on:** make `render-json` ALWAYS return a Lisp
structure, and let apidefs2/conflodis2 own 100% of encoding. Then
`conflodis2-json-text` loses its branch, there is one encoder instead of five, and
`render-json` has a single job — *which fields, which names, which types*. The name
becomes slightly wrong at that point; that is a rename, not a redesign.

**Scope warning.** This is a SHARED-CORE change: ~7 methods across warehouse, products,
customer and the ping route. Do not fold it into the vendor work. Both smoke suites
must be re-run afterwards.

**`render-html` is a different case and stays regardless.** There is no apidefs2 HTML
layer; the UI is its consumer, and it carries the same split-contract smell for the
same reason.

**Either way the generic function stays.** Deleting it would silently break ten
methods rather than removing them.

---
