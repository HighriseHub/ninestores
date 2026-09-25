# Handoff — invoice feature and actor model (session of 2026-09-23/24) · CONTEXT

**Read this when:** starting a new session on the invoice templates, the invoice settings
page/logo, the actor model, or the vendor `INVOICE_SETTINGS` column. It is the state of play,
not a mechanism reference — the mechanisms are in the `knowledge/` tier.

## What shipped (all committed)

| commit | what |
|---|---|
| `e06957f` | Invoice: vendor template picker, logo/header/footer, 4-Eye review bar |
| `144fdc2` | Actor model: non-blocking mailbox, FIFO, retries, supervision, ask/reply |
| `870dbbc` | Actor model KB article + the `ninestores-actor-model` skill |
| `457dbcc` | Vendor invoice settings: backfill migration, dead defaults alist removed |

Not mine, same window: `68bd4d2` (invoice PDF by email + public page), `96d3164`
(fix-permissions.sh).

## State of the running system

* The **migration has been applied**: `23092026-backfill-vendor-invoice-settings` is recorded
  in `DOD_SCHEMA_MIGRATIONS` (2026-09-24 21:47:48). All 15 vendors now hold
  `INVOICE-PRINT-SETTINGS`; 0 NULL, 0 `'undefined'`. Rows are 4,101–4,330 chars.
* The **deployed `site/public/js/dod.js` matches the repo copy** — the settings dialog's
  `FormData` upload path is live. (The repo copy is the source; `cp` it to
  `/data/www/public/js/` after editing, then hard-reload.)
* `installation/upgrades/` is **not** in `package/compile.lisp` by design;
  `apply-migrations` loads it itself. Re-run with `(apply-migrations "user" "pass")`.

## Where the durable knowledge lives

* Actor model → `knowledge/nst-bl-act-CONTEXT.md` + the `ninestores-actor-model` skill.
* Migrations → `knowledge/schema-migrations-CONTEXT.md` (version is `varchar(50)`; one bad
  migration used to abort the whole run).
* The actor suite: `sbcl --non-interactive --load hhub/test/hhub-tst-act.lisp` → PASS/FAIL
  with the harness's own `bt`/`uuid` shims; it redefines nothing inside the app image.

## Open items (offered, not done)

1. **Harden the readers against a bad column**: `nst-vendor-invoicesettings`
   (`invoice/nst-ui-ihd.lisp`) accepts any non-empty string, and a NULL comes back through
   the DAL as `"undefined"`, which `read-from-string` turns into the symbol `UNDEFINED` — the
   next `assoc` is then a type error. One `listp` guard removes the class. *(The migration
   fixed the data; this fixes the code path.)*
2. `dod-dal-ven.lisp` declares the slot `:type (string 4000)` while the column is `text` and
   rows already exceed 4,000 chars — app writes go through that declared type.
3. `*NSTAWSS3FILEDELETEACTOR*` (`core/dod-ini-sys.lisp`) is a dangling defvar: declared, never
   constructed. Implement or delete.
4. The node fileserver stores uploads with **no extension and no `ContentType`** (all objects
   `binary/octet-stream`). A generic extension→MIME map would fix it for every type; owner was
   undecided.
5. Production needs a **restart** to pick up the actor framework and the invoice changes.

## Two facts that cost time here

* `*HHUBFILESERVERURL*` must point at the file server on the **same host** as the Lisp image
  (dev: `http://127.0.0.1:4301`). Uploads silently failed while it pointed at the public
  domain — the remote fileserver cannot read this box's `/data/www/public/img`.
* Email sends now go through actors (`send-email-async`). A request no longer waits on SMTP;
  failures retry once and then land in `actor-dead-letters`, and `(actors-status-report)` is
  the first thing to read.
