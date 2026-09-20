# SKILL: Schema migrations — DDL and seed data (Nine Stores / hhub)

**Read this when:** you are adding a migration, or a migration reported success and
the database is unchanged. Two traps up front: migrations are deliberately **not** in
the asd, and `version` is `varchar(50)`.

**Status:** verified against the live tree 2026-09-19.
**Applies to:** any change to the database schema, and any change to *seed data* that
lives in tables rather than in code (ABAC policies and transactions being the main one).
**Framework:** `hhub/core/nst-sch-mig.lisp` — registry, loader, apply loop, helpers.
**Migrations:** `installation/upgrades/*.lisp` — **all** of them, 65 registered across 19 files.

---

**Seeding ABAC policy/transaction rows?** Those are migrations too, and they have one
extra rule this file does not otherwise need: **one migration version per day, applied
once at the day's end.** Applying mid-day freezes the version and orphans every endpoint
added afterwards, because `apply-migrations` never re-runs a recorded version. The recipe
and the reasoning are in `ABAC-policy-transaction-CONTEXT.md` §8 and §13.1.

## 1. When to use this skill

Use it when you need to:

- add or alter a table, column, index or constraint (DDL);
- insert or update seed rows — ABAC policies/transactions, AI tables, GST tables,
  vendor settings, and anything else that is *data the code expects to exist*;
- apply pending migrations to a database, or diagnose why one did not run.

For the ABAC policy/transaction content specifically, see
`ABAC-policy-transaction-CONTEXT.md`. This file covers the *migration machinery* those
seeds ride on.

---

## 2. The model in one picture

```
  *migrations*                       DOD_SCHEMA_MIGRATIONS
  ┌──────────────────────┐           ┌─────────────────────────┐
  │ (version fn "desc")  │           │ version  varchar(50) UNIQUE
  │ (version fn "desc")  │──skip?───►│ applied_at              │
  │ …65 entries…         │  string=  └─────────────────────────┘
  └──────────────────────┘
            │ not applied
            ▼
   (funcall fn)  ──►  DDL and/or seed inserts
            │
            ▼
   INSERT INTO DOD_SCHEMA_MIGRATIONS (version)
```

A migration is a **`(version function "description")` triple** in `*migrations*` plus a
**function** of that name, which lives in `installation/upgrades/`. The database records
only the `version` string; the function is looked up live by symbol.

**The applied-check is `(member version applied :test #'string=)`** where `applied` is the
list of stored `version` values. Everything below follows from that one comparison.

---

## 3. The one table that matters

| column | type | note |
|---|---|---|
| `row_id` | `int` PK auto_increment | unused by the code |
| `version` | **`varchar(50) NOT NULL UNIQUE`** | 🚨 see trap 1 |
| `applied_at` | `timestamp` | audit only |

🚨 **MySQL here runs non-strict: a `version` longer than 50 characters is SILENTLY
TRUNCATED on INSERT.** The stored value then no longer equals the string in `*migrations*`,
so the skip test never matches and the migration re-applies on **every** run.

---

## 4. Where migrations live — and where they do not

**Framework (`hhub/core/nst-sch-mig.lisp`, 386 lines) holds NO migrations.** It contains
only the registry, the loader, the apply loop, and the helpers. If you are adding a
migration, you are editing `installation/upgrades/`, not this file.

**`installation/upgrades/` holds ALL 65 migration functions** across 19 files. They are
**deliberately not referenced by `nstores.asd` or `package/compile.lisp`** — a migration
function is needed exactly once per database, loading 19 files into every image forever to
serve that is a bad trade, and they are history rather than system logic. `apply-migrations`
loads them itself (§6), so this is not left to the caller's memory. The rationale is
recorded on `*upgrade-files-directory*` (`nst-sch-mig.lisp:87`) — do not "helpfully" wire
them into the asd.

File naming follows the domain: `nst-dbu-<domain>.lisp` (`-warehouse`, `-gstupgrades`,
`-orderitem`, `-policy-transaction`, `-prd-ord-schema`, …). A file may hold migrations for
more than one table when they belong to one change.

---

## 5. The two kinds of migration, and the idempotency pattern for each

**Idempotency is mandatory, not optional.** Migrations re-run — after a truncation bug, on
a partially-applied database, or because someone deleted a row from
`DOD_SCHEMA_MIGRATIONS`. Every migration must be safe to run twice.

### DDL — guard with the introspection helpers

```lisp
(defun migrate-2025May-add-product-code ()
  (unless (column-exists-p "DOD_PRD_MASTER" "PRODUCT_CODE")
    (clsql:execute-command "ALTER TABLE DOD_PRD_MASTER ADD COLUMN PRODUCT_CODE VARCHAR(50);"))
  (clsql:execute-command "UPDATE DOD_PRD_MASTER SET product_code = … WHERE product_code IS NULL;")
  (clsql:execute-command "ALTER TABLE DOD_PRD_MASTER MODIFY COLUMN PRODUCT_CODE VARCHAR(50) NOT NULL;"))
```

Available guards (all in `nst-sch-mig.lisp`): `column-exists-p`, `column-type-equals-p`,
`index-exists-p`, `foreign-key-exists-p`, `table-exists-p`. Wrap the DDL in `unless` around
the guard; the bare `MODIFY`/`UPDATE` forms are naturally idempotent and need no guard.

### Seed data — use the insert-or-skip helpers

```lisp
(let ((policy-id (insert-auth-policy "com.hhub.policy.x" "Desc." "com-hhub-policy-x"
                                     :tenant-id tenant-id)))
  (insert-bus-transaction "com.hhub.transaction.x" "/hhub/api/v1/x" "READ"
                          :policy-id policy-id
                          :trans-func "api GET /hhub/api/v1/x"
                          :tenant-id tenant-id))
```

Both helpers check for a live row with the same `NAME` (+ `TENANT_ID`,
`DELETED_STATE='N'`) first and skip if present, returning the existing `ROW_ID`. **Capture
the policy id and pass it explicitly as `:policy-id`** so each transaction links to its own
policy.

🚨 **A soft-deleted row with the same NAME does not count as present**, so the next run
inserts a **duplicate**. If you soft-delete a seeded policy, hard-delete it or the name will
be re-created alongside it.

---

## 6. Recipe — apply pending migrations

```lisp
(apply-migrations "user" "pass")
(refreshiamsettings)        ; ONLY needed when ABAC rows were seeded — see the ABAC skill
```

`apply-migrations` does all of this itself:

1. `(load-upgrade-files *upgrade-files-directory* nil)` — loads every file in
   `installation/upgrades/`, each in its own `handler-case`, and prints
   `upgrade files: 19 loaded`.
2. Connects.
3. **Pre-flight:** filters `*migrations*` to entries whose `version` is not in `applied`,
   checks `fboundp` on each, and **refuses before any database change** if any function is
   missing — naming the file to load. Scoped to *pending* entries only, so an already-applied
   migration whose function is absent is correctly ignored.
4. Runs each pending migration in its own `handler-case`; a failure prints
   `Migration <version> FAILED (continuing with the rest)` and **the loop continues**.
5. Records each success in `DOD_SCHEMA_MIGRATIONS`.

**`apply-migrations` returns `NIL` regardless of outcome** — that is its value, not a
status. Read the printed lines. A clean run shows every pending version applied, or
`already exists - skipping` from the seed helpers.

---

## 7. Recipe — add a new migration

1. **Write the function** in the appropriate `installation/upgrades/nst-dbu-<domain>.lisp`
   (create a file if the domain is new). Name it `migrate-<YYYYMon>-<what-it-does>`,
   e.g. `migrate-2026Sep-insert-vndapi-policy-and-transactions`. Make it idempotent (§5).
2. **Register it** in `*migrations*` (`nst-sch-mig.lisp:12`) as
   `("<DDMMYYYY>-<kebab-description>" migrate-… "One-line description")`.
   🚨 **the version string must be ≤ 50 characters** (trap 1). Note the registry's own date
   prefix is `DDMMYYYY` while the *function* name uses `<YYYYMon>` — that inconsistency is
   the existing convention, not a mistake to fix mid-stream.
3. **No comments inside `*migrations*`** — it is a data list, kept comment-free.
4. Run `(apply-migrations …)`.

---

## 8. Traps, in the order they bite

1. 🚨 **`version` is `varchar(50)`.** A longer string is silently truncated, the skip test
   can never match, and the migration re-runs forever — then dies on
   `Error 1062 / Duplicate entry` at the INSERT. **Always verify `(length version) <= 50`.**
   If you inherit a truncated one, set the registered string to the *stored* value so the
   skip test matches; do **not** lengthen it.
2. 🚨 **One bad migration used to kill the whole run.** `handler-case` wrapped the entire
   `dolist`, so a single failure silently skipped everything registered after it — the
   blocker at position 60 of 65 hid the five seeds at 61-65 and looked like "my migrations
   never run". Now per-migration. **If you see exactly one failure and everything after it
   missing, suspect a whole-loop abort and check this hasn't regressed.**
3. 🚨 **Build SQL with `sql-literal`, never raw `~A`.** The helpers interpolate into
   `… VALUES ('~A', …)`. An apostrophe in a description (`"the tenant's catalog"`) terminates
   the literal and raises `Error 1064`; a caller-supplied value could **inject**. Wrap every
   string that reaches a quote. Avoid apostrophes in seed descriptions as a second line of
   defence.
4. **Migration functions must be loaded before they can be called** — `not fboundp` is the
   `The function … is undefined` error. `apply-migrations` now loads them itself, so this
   only bites if you call a migration function directly or point
   `*upgrade-files-directory*` somewhere wrong.
5. **Two files defining the same function: the one loaded LAST wins.** Load order is
   alphabetical (sorted in `upgrade-lisp-files` for determinism). A real case exists:
   `migrate-2026Aug-insert-warehouse-policy-and-transactions` is defined in both
   `nst-dbu-policy-transaction.lisp` and `nst-dbu-warehouse-policy-transaction.lisp` **with
   different URIs** — the second is correct and happens to win. On a fresh database the
   wrong winner would seed URIs no route matches, and the PEP fails closed. **One function,
   one file.**
6. **`applied` is compared with `string=`,** so version strings are exact-match keys.
   Whitespace or a stray character means "never applied".
7. **Idempotency is required, not optional** — including the soft-deleted-NAME duplicate in
   §5.
8. **ABAC seeds additionally need `(refreshiamsettings)`** — the rows exist but the running
   image cannot see them (see the ABAC skill, traps 9-10).
9. **`installation/upgrades/*.fasl` are build artefacts.** They sit beside the sources and
   appear/disappear with loading; not tracked, not meaningful.

---

## 9. Verification

**Registry sanity** — versions within limits, no missing or duplicated functions:

```bash
cd /home/ubuntu/ninestores && python3 - <<'PY'
import re, glob
src = open('hhub/core/nst-sch-mig.lisp', encoding='utf-8').read()
m = re.search(r'\(defparameter \*migrations\*\s*\'(.*?)\n\s*\)\)', src, re.S)
entries = re.findall(r'\("([^"]+)"\s+(\S+)', m.group(1))
defs = {}
for f in glob.glob('installation/upgrades/*.lisp'):
    for fn in re.findall(r'\(defun\s+([^\s()]+)', open(f, encoding='utf-8', errors='ignore').read()):
        defs.setdefault(fn.lower(), []).append(f)
print("registered:", len(entries))
print("version >50:", [(v, len(v)) for v, f in entries if len(v) > 50] or "none")
print("undefined  :", [f for v, f in entries if not defs.get(f.lower())] or "none")
print("duplicated :", {k: [x.split('/')[-1] for x in v] for k, v in defs.items() if len(v) > 1} or "none")
PY
```

**Does loading the upgrades folder define every registered function?** This is the
end-to-end check, and it needs a stub image because the real one has the whole system
loaded. Build stub `clsql` / `clsql-sys` / `nstores` packages exporting every `clsql:`
symbol the upgrade files use, install a `[`/`]` reader macro, then `load` each file and
`(remove-if #'fboundp *migrations-functions*)`. Expected: **19/19 files, 65/65 defined,
0 missing.**

---

## 10. File map

| Concern | Location |
|---|---|
| `*migrations*` registry | `hhub/core/nst-sch-mig.lisp:12` |
| `get-applied-migrations` | `:83` |
| `*upgrade-files-directory*` (+ the not-in-the-asd rationale) | `:87` |
| `upgrade-lisp-files` / `upgrade-file-defining` | `:98` / `:106` |
| `load-upgrade-files` | `:120` |
| `apply-migrations` (load → pre-flight → loop) | `:153` |
| `sql-literal` (SQL escaping) | `:224` |
| `insert-auth-policy` / `insert-bus-transaction` | `:268` / `:287` |
| `column-exists-p`, `-type-equals-p`, `index-exists-p`, `foreign-key-exists-p`, `table-exists-p` | `:338`, `:349`, `:362`, `:370`, `:379` |
| **All 65 migration functions** | `installation/upgrades/*.lisp` (19 files) |
| DDL migrations for product/order | `installation/upgrades/nst-dbu-prd-ord-schema.lisp` |

---

## 11. Current state (2026-09-19)

- 65 migrations registered; **0 undefined, 0 duplicated-but-divergent except the warehouse
  pair in trap 5**; all version strings ≤ 50.
- 19 files in `installation/upgrades/`; loading them defines **65/65** functions.
- `hhub/core/nst-sch-mig.lisp` is 386 lines and holds **no migrations** — the five DDL
  functions that used to live there were moved to `nst-dbu-prd-ord-schema.lisp`.
- Two framework fixes landed this session: the per-migration `handler-case` (trap 2) and
  `sql-literal` escaping at all six interpolation sites (trap 3).
- Known outstanding: the duplicate warehouse function (trap 5) is still defined twice with
  divergent URIs — the alphabetically-last, correct one wins, so the live database is right.
