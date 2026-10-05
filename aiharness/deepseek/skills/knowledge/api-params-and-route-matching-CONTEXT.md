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
