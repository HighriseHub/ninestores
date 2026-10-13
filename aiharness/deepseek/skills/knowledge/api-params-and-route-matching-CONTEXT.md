# SKILL: apidefs2 param assembly and route matching

**Read this when:** a query-string filter is silently ignored — `?status=active` arrives
with no `:status` key and every filter is skipped; a request lands on a `{param}` template
instead of the literal path you registered; or a LIST endpoint's result set changed
without the endpoint being touched (both were true of the warehouse the day the products
work landed).

**Status:** both changes were made **2026-09-12/13** during the products work and are
recorded here as of that date; verified by reading the code and by the 2026-09-13 probe
that caught the `template`-vs-`{id}` collision (`products-api-verification-CONTEXT.md`
§11). **Not re-verified since**, and the behaviour of the *running* image is not
established here. Originally `nst-bl-prdapi-CONTEXT.md` §3, moved out on **2026-10-05**
because it is shared-core apidefs2 mechanism, not products API.

**Applies to:** `hhub/core/nst-bl-apidefs2.lisp` — `api-params-for-request`,
`api-query-params`, `find-api-route`, `api-route-param-count`, `register-api-route`. Every
caller of the JSON boundary: the products routes *and* the warehouse LIST endpoint.

---

## 1. `api-query-params` — the query string is now read at all

**Added and wired into `api-params-for-request`.** The API layer previously merged only the
session company, path params and the JSON body — it did **not read the query string at
all**. A filtering endpoint was therefore unreachable over HTTP:
`GET /catalog/products?status=active` arrived with no `:status` key and every filter was
silently ignored.

Precedence is now:

```
company → path → body → query          (query LOWEST)
```

Query is last because the body is the resource representation, and a GET list has no body.
Keys normalise through the same `api-json-key->param-key` as body keys.

**Empty values are passed through, not dropped** — dropping turns "unusable value" into
"no filter" and silently widens the result set (the §9.6 failure mode; that reference
predates the 2026-09-20 split of `nst-bl-prdapi-CONTEXT.md` and no longer resolves there,
so it is kept rather than guessed at).

**Consequence for the warehouse:** its LIST endpoint's query filters (`?city=`,
`?sort-by=`) now actually arrive. That is the intended fix, but it is a **behaviour change
to a live endpoint** and has not been exercised.

## 2. `find-api-route` ranks literal segments over parameters

**New helper `api-route-param-count`.** `find-api-route` used to return the FIRST template
that matched while the registry is scanned newest-first, so `…/{id}` also matched
`…/template` and the winner depended on registration order. Literal segments now rank above
params; **ties keep registry order (newest first)**.

Observed before the fix: `GET …/products/template` answered **401, not 404** — it matched
the `{id}` template, so an endpoint that was deliberately unbound looked bound
(`products-api-verification-CONTEXT.md` §11). After the fix,
`register-api-route` matches `/catalog/products/template` **before**
`/catalog/products/{id}`, which is why `GET /catalog/products/template` is safe even if a
product's id is the literal string `template`.

**Why this file exists rather than a chapter of the products file:** the change is not
products-specific — the warehouse's routes go through the same two functions, and the
pre-existing `nst-bl-apidefs2-CONTEXT.md` predates both (README · *Known staleness*).

---

## 3. Query VALUES are not normalised — three ways a filter silently disappears

Added 2026-10-13 from the customer-invoice API (`invoice/nst-bl-cusinvapi.lisp`). §1 covers
the query string being read **at all**; this section is what happens **after** that, where a
parameter arrives as a key but its VALUE is still the raw string the URL carried.

`api-json-key->param-key` normalises **KEYS** (`?itc=…` → `:ITC`, `?sort-by=…` → `:SORT-BY`).
**Values are not normalised, and not validated** — every coercion is the domain's job.

### 🚨 3.1 `(parse-integer v :junk-allowed t)` DROPS THE FILTER

```lisp
(parse-integer "abc" :junk-allowed t)   ; => NIL, and it does NOT signal
```

If that NIL goes into the filter plist, `build-*-filter-clauses` **omits a clause for a NIL
filter** — so `?vendor-id=abc` returned the **whole unfiltered register**. A client asking for
one supplier's invoices received every supplier's, with no indication its filter had been
discarded. That is the §-1 defect reached from a different direction.

**Use an explicit whole-number parse and refuse the rest** (`cinv-integer-param`): it also
refuses **trailing garbage**, because `"7x"` parses to 7 with `end=1`, which `:junk-allowed`
would have silently accepted as `7`. The guard is `(= parsed-to (length trimmed))`.

### 🚨 3.2 A DOMAIN WHITELIST THAT SIGNALS A **PLAIN ERROR** BECOMES A 500

`validate-*-sort-args` guards the `ORDER BY` and signals a bare `(error "…not in whitelist…")`.
That is **not one of apidefs2's named conditions**, so `api-status-for-condition` answers
**500 internal_error** — and `?sort-by=password`, a malformed REQUEST this API publishes as a
query parameter, is reported to the client as **the server breaking, indistinguishable from a
crash**.

**The route layer must pre-validate as a 400** (`cinv-guard-sort-args`, and the same defect is
recorded as `invh-guard-sort-args` in `invoice/nst-bl-invhapi.lisp`). ⚠ **The domain check
STAYS** — it is not replaced: the guard sees only what the HTTP layer can see, while the
whitelist remains the authority for `:agent`, `:batch` and REPL callers that reach
`enumerate` directly. The guard **reads the same `*…-sort-whitelist*` rather than restating
the columns**, so the two cannot drift. Only a **supplied** bad value is refused; an absent
one is legal and defaults inside `enumerate`.

### 3.3 SAME INPUT, OPPOSITE ANSWERS, ON PURPOSE — `?itc=banana`

* **The web page** resolves an unrecognised value to `:all`, because its own state then
  **shows** that (the All-invoices strip cell is highlighted) — so nothing is swallowed.
* **The API** answers **400**, because a client has no such display: a filter it did not get
  is a filter it believes it applied.

Same input, same principle, **different transport** — the difference is deliberate and
belongs in a comment at both sites (`nst-ui-cusinv.lisp`, `nst-bl-cusinvapi.lisp`).

### 3.4 A FILTER YOU CANNOT EVALUATE IS NOT AN EMPTY LIST — accept it and answer 503

`?itc=at-risk` cannot be computed (it needs the supplier's filing status and an ingested
GSTR-2B; both holding tables are empty). The value is **accepted and passes through**, and
the verb answers `nst-entity-unknown` → **503 with the reason attached**. Refusing it at the
route layer with a 400 would hide the real explanation behind a generic "bad request", and
returning `[]` would assert *"nothing is at risk"* — a claim no data supports.

### 3.5 The status vocabulary has no 403

`api-status-for-condition` maps `api-client-error`→400, `api-not-authenticated`→401,
`api-no-endpoint`→404, else 500. So **"authenticated but not entitled" has no honest status**,
and 404 — *"this does not exist for you"* — is the closest true answer. Adding a 403 branch is
a **core change**, recorded rather than improvised.

### 3.6 Other facts worth carrying

* **An empty list is 200 `[]`, never 404** — `api-status-for-response` treats a list as a
  successful result whatever its length.
* **Path params outrank body and query** (`api-params-for-request`), so a client cannot
  displace the addressed id through the payload.
* **`:inject-company` only for entities with a legacy `COMPANY` slot** (`nst-whs`). `nst-cinv`
  and `nst-invh` have none — their tenant is the inherited `tenant-id`, set by the ferry from
  `domain-ctx`; injecting `:company` pushes an initarg at verbs that do not declare it.
* **A binding must follow its `register-action-route` in load order** — `api-route-bindable-p`
  makes a file that binds before registering **die at load time**. Keep both halves in one file.
* **`required-roles` / `feature-flags` / `audit-level` are CARRIED, NOT ENFORCED** by
  conflodis2 v1, and `*action-route-transaction-function*` defaults to a pass-through — so an
  API route runs **no** `with-hhub-transaction`. UI pages that call it themselves DO ride the
  PEP. (See `ABAC-policy-transaction-CONTEXT.md`.)
* **Sentinel rendering lives in `warehouse/nst-bl-whsapi.lisp` §4** — `domain->response` for
  `nst-entity-nil`/`-unknown`/`-contradiction` and `render-json` for the matching
  `nst-response-*`. Without that file loaded, **every 404/409/503 any domain returns dies at
  the dispatcher's reverse ferry** with `NO-APPLICABLE-METHOD`. Those methods are
  domain-generic, whsapi's own FLAG says they belong in `core/nst-bl-adhara.lisp`, and a second
  method with the same specializers would **replace the warehouse's** — so do not copy them.
