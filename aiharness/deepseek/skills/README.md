# DeepSeek skills

Reusable working knowledge for the Nine Stores / hhub codebase. Each file is a
**skill**: a self-contained, verified description of how one mechanism works, how to
apply it, and the traps that cost time the first time round.

These live **outside** `hhub/` on purpose — they are context for the agent, not code
shipped with the system. Nothing here is loaded by `nstores.asd`.

## Convention

- **Location:** `aiharness/deepseek/skills/`
- **Naming:** `<topic>-CONTEXT.md` for a cross-cutting mechanism, or
  `<source-file>-CONTEXT.md` when the skill is about one file.
- **Every skill must state:** what it covers, when to use it, the mechanism, a
  step-by-step recipe, the traps, and **the file map with line references** so a
  future session can jump straight to the source.
- **Date every verified claim.** Line numbers and "current state" sections rot. Say
  when it was checked, and prefer "measured on <date>" over "is".
- **Separate what is enforced from what merely exists.** A row in a table, a
  registered route, or a declared slot is not proof the thing runs. If something is
  seeded but not wired, say so explicitly.

## Index

| Skill | Covers | Verified |
|---|---|---|
| [ABAC-policy-transaction-CONTEXT.md](ABAC-policy-transaction-CONTEXT.md) | Seeding `DOD_AUTH_POLICY` + `DOD_BUS_TRANSACTION` and linking them; the `with-hhub-transaction` PEP chain; the `TRANS_FUNC`-is-the-lookup-key trap; tenant-1-only caches; the unwired API seam. | 2026-09-19 |
| [schema-migrations-CONTEXT.md](schema-migrations-CONTEXT.md) | The migration framework: the `*migrations*` registry, DDL vs seed-data idempotency, the `varchar(50)` version trap, `load-upgrade-files` + pre-flight, SQL-literal escaping, and why migrations are deliberately not in the asd. | 2026-09-19 |
| [permissions-CONTEXT.md](permissions-CONTEXT.md) | The two-account/one-group model, **what the agent can and cannot chmod** (§3 — `sudo` is dead, ownership is required), the diagnostics, `installation/fix-permissions.sh`, and the recurring write-path drift. | 2026-09-19 |
| [nst-bl-prdapi-CONTEXT.md](nst-bl-prdapi-CONTEXT.md) | The products/catalog API: decisions (§6), deliberately-unfinished list (§7), sharp edges (§8), verified transcripts (§11–12). | 2026-09-13 — **partly stale, see below** |
| [nst-bl-apidefs2-CONTEXT.md](nst-bl-apidefs2-CONTEXT.md) | The JSON API layer itself: bound endpoints, the Belnap→HTTP status mapping, session/login rules, nginx deployment reality. | 2026-09-12 |
| [nst-bl-vndapi-CONTEXT.md](nst-bl-vndapi-CONTEXT.md) | The vendor-profile migration: verification status (§0), schema facts, the प्रत्यय layer as designed, decisions. | 2026-09-13 |
| [nst-bl-conflodis2-DESIGN.md](nst-bl-conflodis2-DESIGN.md) | **The conflodis2 design authority** — Tier-2/3 route verbs, the ferry signatures, multi-entity assembly and the कारक. Cited by name in the headers of `nst-bl-conflodis2.lisp`, `nst-bl-apidefs2.lisp`, `nst-bl-whsapi.lisp` and `nst-bl-prdapi.lisp`. Note the `-DESIGN.md` suffix: it predates this directory's `-CONTEXT.md` convention and was kept so those citations stay recognisable. | undated |
| [WAREHOUSE-NST-GRAMMAR-CONTEXT.md](WAREHOUSE-NST-GRAMMAR-CONTEXT.md) | **Authoritative architecture reference.** The Paninian grammar: `domain-ctx`, the प्रत्यय verbs, the ferry (लोप), नियम, and `nst-whs` as the first grammar-based entity. The legacy DDD stack is deprecated — do not extend it. | undated |

## Known staleness

Context files are snapshots; the code moves. Where a skill is known to have drifted,
that is recorded here rather than silently corrected, so a reader knows to check.

- **`nst-bl-prdapi-CONTEXT.md` §7.4** lists `update-shipping` and `update-pricing`
  among seven unbound endpoints, and says `update-pricing` has *"no domain entity for
  `DOD_PRODUCT_PRICING` at all"*. Both are now built: shipping is bound as
  `PUT /hhub/api/v1/catalog/products/{id}/shipping`, and pricing has an entity
  (`nst-prd-pricing`), Tier-1 प्रत्यय (`nst-bl-prdpricing.lisp`), and request/response
  models. **Five of the seven remain unbound.**
- **`nst-bl-prdapi-CONTEXT.md` §7.1** says *"EVERYTHING PAST AUTHENTICATION IS UNRUN"*.
  Resolved — `test/smoke-products-api.sh` passes for read **and** write.
- **`nst-bl-prdapi-CONTEXT.md` §7.7** notes the products domain class went into
  `dod-dal-prd.lisp` rather than a `products/nst-dal-prd.lisp` as warehouse did. The
  pricing and category entities follow the same choice, so the divergence is now
  deliberate rather than accidental.
- **File drift:** the prdapi file's §7.8 records that `nst-bl-apidefs2-CONTEXT.md`
  *"does not mention products, the query-param change, or the route-ranking change"*.
  It predates the products work and the addition of `api-query-params`.

## Adding a skill

1. Write the file here, following the convention above.
2. Add a row to the index, with a **verified** date.
3. If the new skill makes an existing one wrong, add a line under **Known staleness**
   rather than editing the older snapshot in place — the snapshot is still evidence of
   what was true then.
4. Cite real line numbers, and re-check them when you touch the file next — a stale
   line reference is worse than none, because it reads as verified.
