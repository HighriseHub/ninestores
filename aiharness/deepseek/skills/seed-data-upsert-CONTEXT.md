# SEED DATA — the ABAC registry goes declarative, with UPSERT (pending work)

**Read this when:** you are about to add another ABAC policy/transaction for a page or endpoint and do not want another `migrate-…` defun plus a `*migrations*` entry for it · a transaction row exists in the live database but on no other machine, so a restored or rebuilt DB answers `Did not find transaction com-hhub-transaction-…` · seeding repeats rows and the old ones are deleted by hand.

**Status:** **OPEN — nothing built.** Measured 2026-10-14 against the live DB, the git tree and the running image. The interim for the page that failed that morning is the one-shot migration `installation/upgrades/nst-dbu-cusinv-policy-transaction.lisp` (registered as `14102026-customer-invoice-list-policy`); **this file is the general fix that should make it the last** such migration.

**Applies to:** `hhub/core/dod-seed-data.lisp`, `hhub/core/dod-bl-pol.lisp`, `hhub/core/nst-sch-mig.lisp`, `installation/upgrades/nst-dbu-*-policy-transaction.lisp`, the boot order in `hhub/core/nst-server-context.lisp`. Mechanism (not the plan) stays in `knowledge/ABAC-policy-transaction-CONTEXT.md` §8 and `knowledge/schema-migrations-CONTEXT.md`.

---

## 1. The problem, measured 2026-10-14

| fact | value |
|---|---|
| live `DOD_AUTH_POLICY` rows | **93** (`DELETED_STATE='N'`) |
| live `DOD_BUS_TRANSACTION` rows | **94** (95 total, 1 soft-deleted) |
| entries in `dod-seed-data.lisp` | **22 policies + 22 transactions** (`policylist:14`, `transactions:39`) — the 2026-05-era set |
| seed migrations in `installation/upgrades/` | **10** `.lisp` files (`nst-dbu-*-policy-transaction.lisp`) carry the rest |

- **The declarative file is DEAD.** `dod-seed-data.lisp` is referenced by neither `hhub/nstores.asd` nor `hhub/package/compile.lisp` (grep, 2026-10-14), so its own two seeding calls — `(seed-auth-policies policylist)` at `:64` and the transactions `mapcar` at `:99` — have not run for a long time. The pre-migration mechanism exists and is switched off; today's mechanism is the migration.
- **Every page has cost a defun + a file + a `*migrations*` line.** The pair for `^/hhub/nstcustinvoices` never even got that: it was hand-inserted 2026-05-18 (rows 49/70), so **one database owns it** and any restore loses the page with a 500 that reads like a permission problem.
- **The seeders are INSERT-ONLY, so a rerun appends.** Live proof: rows **44 and 51 both carry `TRANS_FUNC = com-hhub-transaction-create-warehouse-action`**. Manual deletion of the older row is the current routine — i.e. the cost the user is paying twice (once to add, once to clean).

## 2. Why these rows belong in seed data, not in migrations

The industry split is: **versioned one-shot migrations own schema; reference/master data is a declared set reconciled idempotently** — Flyway repeatable migrations (`R__*.sql`, re-run on checksum change) + `loadData`, Liquibase `loadUpdateData`, Rails `db/seeds.rb`, Django fixtures + `loaddata`, Kubernetes-style reconcilers. A transaction row is a *config* fact keyed by `TRANS_FUNC`: it describes a route, not a table. Two rows for one route are not a schema event, and paying a migration's ceremony for them is what makes the registry drift.

## 3. What to build, in order

1. **One upsert helper, keyed on the right column.** `nst-sch-mig.lisp` already has the insert-if-absent family: `auth-policy-inserted-p:253`, `bus-transaction-inserted-p:263`, `auth-policy-id-by-name:273`, `insert-auth-policy:284`, `insert-bus-transaction:303`, all writing `DELETED_STATE 'N'`. ⚠ **`bus-transaction-inserted-p` matches on `NAME`, but the runtime lookup key is `TRANS_FUNC`** (`dod-bl-bo.lisp:91` builds the hashtable on `trans-func`), so an upsert that reuses it leaves the 44/51 class of duplicate in place. Key on `(TRANS_FUNC, TENANT_ID, DELETED_STATE='N')`.
2. **Fix the semantics, then document them:** insert if absent; otherwise `UPDATE` the declared mutable columns (`URI`, `TRANS_TYPE`, `AUTH_POLICY_ID`, `ACTIVE_FLG`) to the declared values; **never** touch another tenant's row; **never** silently resurrect a soft-deleted one — report it. A `:dry-run t` that prints insert / update / no-op per row is what makes a boot-time seeder safe to run.
3. **Load it at boot, in the right order.** Seed *after* the DB connect (`nst-server-context.lisp:228`) and *before* the derived caches (`:237` `register-global-effect *HHUBGLOBALLYCACHEDLISTSFUNCTIONS*` — `hhub-gen-globally-cached-lists-functions`, `dod-ini-sys.lisp:314`). A seed that runs after the cache has been built is invisible to `with-hhub-transaction` until `(refreshiamsettings)`; that boot-time-cache-only lookup is the whole reason the 2026-10-14 failure presented as "transaction not found" while the row sat in the table. Registering the revived file needs the two usual registrations: the build list in `hhub/package/compile.lisp` **and** `hhub/nstores.asd`.
4. **Enumerate the live rows into the declaration.** The 10 existing seed migrations are the enumeration for the 72 rows the declarative lists lack; fold them in so the declaration becomes the source of truth. Read them, do not re-invent names: `NAME`, `URI`, `TRANS_TYPE`, `TRANS_FUNC` and the policy's `POLICY_FUNC` must stay byte-identical, or the declaration seeds a near-duplicate.
5. **Retire the ABAC seed migrations only after §4 is green** and every environment has applied them. DDL migrations are untouched by this work; they stay.

## 4. Verification to write with it

- Extend `aiharness/deepseek/tools/nst-verify-abac-seed.lisp` — it already parses a seed file **offline** (column widths under `STRICT_TRANS_TABLES`, every `POLICY_FUNC` exists, `TRANS_FUNC` uniqueness, URI-is-a-prefix-of-the-route) — to run **both directions**: every declared row exists live and matches field-for-field, and every live row is declared or explicitly listed as legacy. Today it checks one migration file; the target is the declaration against the DB.
- Keep the boot-time checkable invariant: **no two live rows may share a `TRANS_FUNC`** — that single assertion would have caught rows 44/51.

## 5. Do not

- Do not delete `dod-seed-data.lisp` "because it is not loaded" — it is the mechanism this work revives, and `seed-auth-policies` (`dod-bl-pol.lisp:192`) is still a live helper.
- Do not make the seeder run *before* the DB connect or after the cache build; both orderings produce a green boot and a wrong registry.
- Do not let the declarative list become a second, drifting copy: once it is loaded, a new route's pair is added **there** and nowhere else.
