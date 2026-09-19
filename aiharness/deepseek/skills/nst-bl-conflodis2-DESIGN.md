# nst-bl-conflodis2 — Design Doc

**Title:** The Ring-2/3 Route-Action Dispatcher (Pāṇinian verb dispatch)

**Source grammar:** `procurement/paninigrammarprocurement.md` (Verb-first, कारक, संधि)
**Files it replaces at runtime:** `hhub/core/nst-bl-conflodis.lisp` (legacy Context Flow Dispatcher)
**Files it is based on:** `hhub/core/nst-bl-adhara.lisp` (domain ferry + रेंडर contract)

> Status: **DESIGN — for review.** Code is NOT written yet. Decisions marked `[OPEN]` need
> confirmation before implementation.

---

## 1. Positioning and the Two-Tier Ownership Model

conflodis2 is **not** a CRUD dispatcher and **not** a noun/resource dispatcher. It is the
Ring-2/3 action layer over a verb-first grammar. We deliberately split dispatch into two
owned tiers so that "one verb acts on one कर्म" never forces an entity-limitation onto
multi-entity business actions:

| Tier | Owner | Unit of dispatch | Example |
|------|-------|------------------|---------|
| **Tier 1 — Domain ferry** | `nst-bl-adhara.lisp` (Ring 1) | one धातु verb × **one कर्म** (single entity) | `(request->dispatch rm 'make 'ord ctx)` |
| **Tier 2 — Action** | `nst-bl-conflodis2.lisp` (Ring 2/3) | one **route-action verb** (entity-agnostic) | `(route-order request ctx)` |

**Who owns `request->dispatch`?** The domain ferry. It is the low-level crossing for a
single verb against a single कर्म. It is deliberately *not* conflodis2's public primitive.

**conflodis2 owns the ACTION.** An inbound action like "place an order" is a composite: it
spans several entities (ord + order-items + source budget + vendor). conflodis2 action verbs
assemble these by issuing **several Tier-1 ferries** — one boat per entity crossing — inside a
single transaction. This is why conflodis2 must never carry a single `entity-class` around.

**Reconciliation with the grammar:**
- A single धातु verb has one कर्म (Singular object per क्रिया). Other entities in an action
  are *other कारक* (kartṛ/कर्म/करण/संप्रदान/अपादान/अधिकरण), **not** extra कर्म. `approve`
  acts on *one* approvable object; the approver and route-to are कारक carried in ctx.
- A business flow that spans many entities is either a **संधि chain** (sequence of
  single-कर्म verbs) or a **प्रत्याहार/समास compound verb** whose method fans out to several
  Tier-1 verbs. Invalid sequences are *unrepresentable* — no method exists.

---

## 2. Vocabulary (name disambiguation)

| Term | Meaning | Owned by |
|------|---------|----------|
| **धातु verb** (domain verb) | `make`, `fetch`, `enumerate`, `!update`, `delete!`, `?exists`, `approve`, `issue`, `claim-itc` … dispatched on an entity | proc.GANA packages / adhara |
| **Route-action verb** | the Ring-2/3 orchestrator for one inbound action, `route-<action>` | conflodis2 |
| **request** | slotless inbound carrier; data rides in `(params request)` | conflodis2 |
| **domain-ctx** | कारक passenger struct (`domain-ctx` from adhara) | adhara |
| **kāraka** | six semantic roles | adhara domain-ctx |

**Route-action verbs are marked with a `route-` prefix** so they can never be confused with
pure domain verbs and so the whole dispatcher surface is self-describing:
`route-order`, `route-approve`, `route-claim-itc`, `route-make`, `route-fetch`, `route-list`.

---

## 3. Route-Action Verb Signature (uniform)

```lisp
(route-order  request domain-ctx)   ; → domain object(s) or Belnap sentinel
(route-approve request domain-ctx)
```

- `request` — an `nst-request-model` subclass, **slotless**, carrying the full inbound
  payload in `(params request)` as a plist. Nothing rides in named slots. This is what allows
  *one* action to carry the params for many entities.
- `domain-ctx` — the कारक struct (adhara), whose `tenant` holds the session company object.
- The verb method body **assembles the entities** it needs: for each entity it may dispatch a
  Tier-1 ferry `(request->dispatch sub-request verb entity-class domain-ctx)`. Several boats
  assemble one order.
- Return: domain-layer result(s) — a single entity, a list, or an `nst-entity-*` Belnap
  sentinel. **Never** a boundary/`requestmodel` type crosses out of the action verb.

Example sketch (`route-order`, conceptual — the order aggregate is assembled from several
ferries):

```lisp
(defmethod route-order ((request order-request) (ctx domain-ctx))
  ;; Each (sub-)entity crossing is a Tier-1 ferry.
  (let* ((header (request->dispatch request 'make 'ord ctx))
         (lines  (request->dispatch request 'make 'ord-itm ctx))   ; ∋ containment
         ...))
  (fulfil-order header ...))   ; one action, several boats
```

---

## 4. Dispatcher Responsibilities

conflodis2's *dispatcher* is thin. It never interprets the payload for domain logic — it
resolves the action verb, secures the call, builds कारक, runs the verb in one transaction,
then runs the reverse boundary + render.

```
Inbound action (route-key = a route-* symbol)
  1  find route record by route-key                 [registry]
  2  :before — ABAC/authz (collect attributes)      [PEP]
  3  build slotless request model with :params = raw payload
  4  build domain-ctx कारक from session + payload   (see §6)
  5  with transaction — call (route-<action> request domain-ctx)
  6  :after  — reverse ferry domain->response [ + list ]
  7  render  per output-type (dṛś): render-json / render-html
```

### 4.1 Dispatcher entry (mirrors legacy signature, new semantics)

```lisp
(dispatch-route2 route-key raw-params
                 &key trans-func-name output-type request-uri)
```

### 4.2 Route record (v2) — `crud-op` is REMOVED

`outbound-adapter-route` is not reused. conflodis2 registers an **action-route** record. The
`crud-op` slot is gone; we do not design around CRUD. Tentative fields `[OPEN]`:

```lisp
(defclass action-route ()
  ((action-verb    :reader route-action-verb)   ; symbol 'route-order
   (description    ...)
   (render-contract ...)                        ; output-type(s): json / html
   (required-roles ...)                         ; from legacy route
   (permission-checker ...)
   (feature-flags  ...)
   (tenant-overrides ...)                       ; default: session tenant (नियम-1)
   (audit-level    ...)
   (active         ...)
   (tags / version / metadata ...)))
```

What is intentionally absent: `businessobject-class`, `adapter-class`, `presenter-class`,
`view-classes`, `crud-op`. Entity identity and view wiring are not the dispatcher's concern.

### 4.3 Reverse boundary + render

Same adhara contract as the UI ferry:
- single domain result → `(domain->response entity domain-ctx)`
- list → per-element `domain->response` (or an aggregate list method)
- render by output-type via `render-html` / `render-json` (धातु `dṛś`).

---

## 5. Assembling a Multi-Entity Action

The decisive property: **an action verb is free to call the Tier-1 ferry as many times as it
needs, against as many entity classes as it needs.** `request->dispatch` is *one boat*;
`route-order` may launch several. This directly answers "who owns `request->dispatch`" — the
domain ferry is a reusable crossing that action verbs call, not a single-entity cage around
conflodis2.

संधि validity is enforced structurally: a `route-*` method only exists when the sequence of
Tier-1 verbs it issues is legal. A forbidden hop (`dā → daḥ`) has no composing method.

---

## 6. कारक → domain-ctx Mapping

`domain-ctx` already carries five of the six roles (कर्म is the verb's own first argument):

| कारक | Sanskrit | domain-ctx slot | Source at dispatch |
|------|---------|-----------------|--------------------|
| kartṛ  | कर्ता | `actor`   | session user/agent |
| adhikaraṇa | अधिकरण | `tenant` | session login company (नियम-1) — **never** client params |
| karaṇa | करण | `channel` | `:http` / `:agent` / `:batch` from the inbound carrier |
| sampradāna | संप्रदान | `recipient` | payload when an action is *for* another party (e.g. vendor) |
| apādāna | अपादान | `source`   | payload when an action draws *from* another party (e.g. budget) |
| karma | कर्म | (verb arg) | the primary entity the action acts on |

**नियम-1 (tenant isolation):** tenant always comes from the session login company
(`get-login-vendor-company` → `get-login-customer-company` → `get-login-company`). A
client-supplied `:tenant-id` in params is never trusted.

---

## 7. संधि / Chain Seam (deferred, reserved)

For now conflodis2 dispatches **one** action verb per inbound action; that verb may internally
fan out. A future chain seam (declarative संधि sequences + `प्रगृह्य` async boundaries) is
reserved but NOT built yet, so the dispatcher shape must not preclude it (record carries
`action-verb` only; adding a `sequence` slot later is additive, not a rewrite).

---

## 8. Sample Walkthrough

**`route-order`** (conceptual):
1. Dispatcher resolves `route-order`, runs ABAC, builds slotless request + कारक ctx.
2. Action verb reads params: header fields, line items, vendor, budget cost-centre.
3. For each entity it needs it launches a Tier-1 ferry inside the one transaction:
   - header → `request->dispatch … 'make 'ord …`
   - line items → `request->dispatch … 'make 'ord-itm …` (∋ containment)
   - budget check is a लोप hop (fires automatically).
4. Returns the assembled order domain object; dispatcher reverse-ferries and renders.

---

## 9. What It Replaces / File Layout `[OPEN on load order]`

- New file: `hhub/core/nst-bl-conflodis2.lisp` (dispatcher + `action-route` + route registry +
  `route-*` macro/registration helpers). Action-verb **methods** for a given domain live in
  that domain's own files (so the grammar for an entity is kept with the entity).
- `hhub/core/nst-bl-conflodis.lisp` remains for legacy callers until fully migrated; the two
  must not both be wired into the build for the same route namespace.
- Registration of the dispatcher in `compile.lisp` / `nstores.asd` only after review.

---

## 10. Definition of Done

- [ ] `route-*` action verbs resolve a real inbound action against the Pāṇinian vocabulary
      (no CRUD/`crud-op` anywhere).
- [ ] One action verb can assemble multiple entities via several Tier-1 `request->dispatch`
      calls inside one transaction.
- [ ] कारक are populated correctly; नियम-1 tenant from session, never client params.
- [ ] Response leaves through `domain->response` + `render-html`/`render-json` (no boundary
      type leaks to Ring 1).
- [ ] Invalid संधि sequences are unrepresentable (no composing method), not rejected at runtime.

---

## 11. Open Questions `[OPEN]`

1. Route record final field list (ABAC/roles carry-over vs trim).
2. Whether route-action verbs live in a dedicated conflodis2 package vs. per-domain proc
   packages.
3. Payload → per-ferry sub-request splitting: one full `params` plist reused by every ferry,
   or an action verb builds per-entity sub-requests? (Currently favors: action verb decides.)
4. Load order / coexistence with legacy conflodis during migration.
