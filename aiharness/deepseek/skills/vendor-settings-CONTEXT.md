# vendor-settings — the vendor Settings page: registry, template and panes

**Read this when:** you are adding, moving or re-homing a **vendor setting** — an entry
in the sidebar's Settings node, an item on the vendor profile page (`dodvendprofile`),
a settings page built from a template, or a section that today opens a modal — **or you
are about to copy `invoicesettings.html` / `invoicesettings.lisp` as your pattern.**

> **Title:** Vendor Settings — one page, one registry, template-owned panes.
> **Status: DESIGN — PARKED by the owner 2026-10-03, to be revisited later. No code
> written, and no file in `hhub/` touched.** Resume from `PENDING-WORK-CONTEXT.md` §9,
> which carries the state of play; the build sequence is §6 below. Decisions marked
> `[OPEN]` need confirmation before implementation. Every mechanism claim below was
> verified by reading the source on **2026-10-03**; every line reference was checked
> that day.

---

## 1. The problem this design answers

`dodvendprofile` (`hhub/vendor/dod-ui-ven.lisp:1930–1974`) is the vendor settings hub
today: a `list-group` of six items, **four of which are modals** —

| item | today | target |
|---|---|---|
| My Groups | link `dodvendortenants` (`:1959`) | as-is |
| Contact Information | modal `#dodvendupdate-modal` → `modal.vendor-update-details` (`:778`) | pane |
| E-Commerce Shipping Methods | link `hhubvendorshipmethods` (`:1967`) | as-is, then section page |
| E-Commerce Payment Methods | modal → `modal.vendor-payment-methods-page` (`:953`) | pane |
| E-Commerce Payment Gateway | modal → `modal.vendor-update-payment-gateway-settings-page` (`:1041`) | pane |
| UPI Settings | modal → `modal.vendor-update-UPI-payment-settings-page` (`:924`) | pane |

They were moved out of the sidebar originally because **a modal cannot be a sidebar
link**: `data-bs-toggle="modal"` is not linkable, not bookmarkable, and stacking a
BS5 modal (z-index 1055) over an open offcanvas (1045) fights over the body scroll lock.
That constraint does not apply to a *page*, so the reason for the exile disappears if the
settings become page content.

`hhubvendorshipmethods` (`:1996–2010`) is **the same shape one level down** — five
sub-items, four of them modals (Free Shipping, Flat Rate Shipping, External Shipping
Partners, Select Default Shipping Method; Zonewise Shipping is a real page at `:2052`).
So this is not a one-off: it is tier 2 of an unbounded tree, and the design has to be
recursive-by-construction rather than hand-built per level.

Target: **20+ further settings** must be addable without the sidebar becoming a wall.

---

## 2. The precedent, fully traced — invoice settings

The invoice settings page is the one existing template-driven settings page. Everything
below is verified.

| Piece | Where |
|---|---|
| **The tree + defaults are a Lisp parameter** | `*invoice-settings*`, `hhub/invoice/templates/invoicesettings.lisp:10` — alist of `(section (key value) …)`, 11 sections |
| Loaded as part of the system | `hhub/nstores.asd:140`, `hhub/package/compile.lisp:306` |
| Its YAML mirror (same tree, snake_case keys) | `hhub/invoice/templates/invoicesettings.yaml` |
| The HTML template | `hhub/invoice/templates/invoicesettings.html` — BS5 accordion `#settingsAccordion`, one `accordion-item` per section, `data-bs-parent="#settingsAccordion"` |
| Template file paths | `dod-ini-sys.lisp:144–145` |
| Read once at boot | `nst-load-invoice-templates`, `dod-ini-sys.lisp:465–499` (`:475` html, `:476` yaml) |
| Fetched by number | `nst-get-cached-invoice-template-func :templatenum 14` — `dod-ini-sys.lisp:502`, `:519` |
| Cached global, reloadable without restart | `register-global-effect *NST-INVOICE-TEMPLATES*`, `nst-server-context.lisp:136`, `:242` |
| Route | `/hhub/vinvoicesettingspage` → `com-hhub-transaction-invoice-settings-page`, `dod-ui-sys.lisp:1155` |
| Controller / model / widget | `nst-ui-ihd.lisp:112` / `:116` / `:129` |
| Injection into the template | **positional** `(format nil html logo-form print-form)`, `nst-ui-ihd.lisp:123` |
| Save action | `vsaveinvprintsettings` → `com-hhub-transaction-save-invoice-print-settings-action`, `dod-ui-sys.lisp:1156`, `nst-ui-ihd.lisp:436` |
| Payload | hidden `vinvprintsettings` input carrying JSON built by the page's `saveSettings()`, decoded by `cl-json:decode-json`, `nst-ui-ihd.lisp:444–452` |
| **Persistence** | one vendor row column `invoice-settings`, holding `(write-to-string settings :readably t)` — `nst-ui-ihd.lisp:245`; column declared at `dod-dal-ven.lisp:360`, `nst-dal-vnd.lisp:296/472` |
| Read back | `read-from-string` at login `dod-ui-ven.lisp:2508`; `get-vendor-invoice-settings` `:2531–2538`; `nst-vendor-invoicesettings` `nst-ui-ihd.lisp:209` |
| Session mirror | `:login-vendor-invoice-settings`, written at `:246` and login `dod-ui-ven.lisp:2508` |
| **Single-key setter already exists** | `nst-save-vendor-invoiceprintsetting (sectionname keyname value)`, `nst-ui-ihd.lisp:233` — read-modify-write of one key across row + session |
| Backfill migration | `nst-sch-mig.lisp:80` |
| Public API exposes it | `nst-bl-vndapi.lisp:524` — `PUT /api/v1/invoices/settings` |

**Two facts that matter more than the rest:**

- **The payment-method flags are already session-cached.** `addloginvendorsettings`
  (`dod-ui-ven.lisp:2541`) runs the `VPaymentMethodsAdapter` read **once at login** and
  parks `codenabled/upienabled/payprovidersenabled/walletenabled/paylaterenabled` in
  `:login-vendor-settings-ht` (`:2558`). A pane — and the sidebar — can read those flags
  with **zero DB cost**. The "sidebar must not query the DB" objection to the Payment
  Methods entry therefore does not hold.
- **The per-key setter already exists** (`nst-ui-ihd.lisp:233`). Granular saving is not
  new machinery; it is a call.

---

## 3. What the precedent gets right — copy these

1. **The tree and its defaults live in a Common Lisp parameter**, in the `templates/`
   folder beside the HTML (`invoicesettings.lisp:10`), not scattered across the page,
   the form and the action.
2. **The HTML lives in a file, cached as a function**, so layout iterates without a
   recompile, and the page keeps the normal MVC shape (`model → inject → widget`).
3. **Accordion is the right navigation primitive for settings on this app**: mobile-first,
   no navigation JS, BS5 supplies `aria-expanded`/`aria-controls` and full-width ≥44px
   touch targets, and only one panel is open so the page stays short.
4. **A YAML sibling holds the same tree as data** — the beginnings of a registry.

---

## 4. Traps in the precedent — do NOT inherit

All verified in the files; each is cheap to avoid and expensive to discover later.

1. **Positional `~A` placeholders.** `(format nil html a b)` (`nst-ui-ihd.lisp:123`) is
   fine for two injections and invisible coupling at twenty: reorder one argument and
   panes silently swap. The better mechanism **already exists in the tree**:
   marker-delimited fragments (`extract-html-between-markets`, `dod-ui-ven.lisp:3482`)
   plus **named `%Token%`** placeholders substituted from a field map with
   `cl-ppcre:regex-replace-all` (`:3490–3533`, map at `:3451`).
2. **Template ids and JS ids have already drifted.** `invoicesettings.html` uses
   kebab-case ids (`send-email-after-draft`); `saveSettings()` reads run-together ids
   (`sendemailafterdraft`); `settingsFieldValue` returns `""` for a missing element, so
   the page persists **empty strings instead of failing loudly**. Fix by construction:
   the field `name`, the `%Token%` and the storage key are **the same string**.
3. **Whole-blob saves force per-field preservation hacks.** Because the page posts the
   entire object, `create-model-for-invoiceprintsettingsaction` needs special-case code to
   stop a logo the page did not render from being wiped (`nst-ui-ihd.lisp:464–474`). At
   20+ settings that becomes one hack per off-screen field. Save per key.
4. **`(key value)` list vs `(key . value)` cons duality.** `update-config`
   (`invoicesettings.lisp:122`) sets `(cdr entry)`, turning `(default-paper-size "A4")`
   into `(default-paper-size . "A4")` — so defaults are lists and saved values are conses,
   which is exactly why `invoiceprintsettingentry`/`invoiceprintsettingvalue`
   (`nst-ui-ihd.lisp:139–153`) need their unwrapping logic. Pick one representation for
   vendor settings and never mix.
5. **Dead code from the inline script.** `saveEmailSettings()` assigns
   `sendemailaftergeneration` five times (four discarded); the General and Email Save
   buttons both call `saveSettings()` (the print one), so those two blocks never save.
   A big inline script in a template rots silently.
6. **Anything outside the template markers is discarded.** In `vendorprofile.html` the
   `.form-card` CSS sits in `<head>` (`:19–31`) while only the
   `<!--VENDOR_PROFILE_FORM_BEGIN--> … _END-->` fragment (`:42`) is injected — so that
   CSS is dead. A settings template must keep **all** styling inside the marked fragment
   or use global CSS.
7. **`read-from-string` on stored data.** Interoperable today only because the writer is
   `write-to-string :readably t` of JSON-decoded values. When generalising, bind
   `*read-eval* nil` so a hand-edited row cannot execute anything.
8. Vestigial BS3-era `data-toggle="validator"` and `alert()`-on-save in
   `invoicesettings.html`.

---

## 5. Design

### 5.1 One registry, in Lisp, as a parameter

`hhub/vendor/templates/vendorsettings.lisp` — new file, a sibling of
`invoicesettings.lisp`, registered in the asd + compile list like it
(`hhub/nstores.asd:140`, `hhub/package/compile.lisp:306`). Richer than
`*invoice-settings*` because the sidebar needs labels too:

```lisp
(defparameter *vendor-settings*
  '((:group "Account" "fa-regular fa-user"
     (:contact  "Contact Information"        :pane "contact"  :action "hhubvendupdateaction")
     (:groups   "My Groups"                  :href "/hhub/dodvendortenants")
     (:push     "Browser Push Notifications" :href "/hhub/hhubvendpushsubscribepage"))
    (:group "E-Commerce" "fa-solid fa-cart-shopping"
     (:shipping   "Shipping Methods" :href "/hhub/hhubvendorshipmethods")
     (:paymethods "Payment Methods"  :pane "paymethods" :action "hhubvpmupdateaction")
     (:paygateway "Payment Gateway"  :pane "paygateway" :action "hhubvendupdatepgsettings"))
    (:group "Payments" "fa-regular fa-credit-card"
     (:upi    "UPI Settings"     :pane "upi"  :action "hhubvendupdateupisettings")
     (:upitxn "UPI Transactions" :href "/hhub/hhubvendorupitransactions"))))
```

Each row is either `:href` (a page that already exists — nothing to build) or `:pane`
(a section rendered inline) plus the `:action` its form posts to. **One list drives both
the sidebar and the page**, so they cannot drift. Adding a setting later is one row and
one pane.

### 5.2 One route — and it already exists

`/hhub/dodvendprofile` → `dod-controller-vend-profile` (`dod-ui-ven.lisp:1930`,
dispatcher `dod-ui-sys.lisp:1086`) already exists, and the sidebar already calls it with
an unused `?context=` parameter (`:151`). Section selection rides that slot:
`/hhub/dodvendprofile?context=payments/upi`.

**Therefore: no new route, no new controller, no new save action, and zero edits to
`dod-ui-sys.lisp`.** One model function, one widget function, N pane renderers.

### 5.3 The template holds chrome and panes, never the structure

`hhub/vendor/templates/vendorsettings.html`, registered as vendor **templatenum 2**
(needs: a defvar beside `*NST-VENDOR-PROFILE-PAGE*` at `dod-ini-sys.lisp:182`; the loader
at `:597–602`; a `case` branch at `:608`).

```html
<!--VENDORSETTINGS_BEGIN-->
<div class="d-flex align-items-center gap-2 mb-3">
  <h4 class="mb-0">Settings</h4>
  <input id="vsFilter" class="form-control form-control-sm ms-auto" style="max-width:16rem"
         placeholder="Filter settings" onkeyup="vsFilterSections(this.value)">
</div>
<div class="accordion accordion-flush" id="vsAccordion"><!-- %Settings Sections% --></div>

<!--VS_PANE:contact-->
  <input class="form-control" name="vs.contact.name"  id="vs.contact.name"  value="%Vendor Name%">
  <input class="form-control" name="vs.contact.phone" id="vs.contact.phone" value="%Vendor Phone%">
<!--VS_PANE_END:contact-->
<!--VENDORSETTINGS_END-->
```

Rules that make it hold at 20+ sections:

- **`name` = `%Token%` = storage key.** `vs.contact.name` is one string in three places
  derived from one place, so the `invoicesettings.html` id-drift bug cannot recur.
- **One `<form>` per pane**, posting to that section's existing `:action`. **No save
  JavaScript at all** — the whole of `saveSettings()`/`vinvprintsettings` disappears.
- **Accordion item = section**, with group divider rows between clusters. One click to
  any setting, no nesting traps, and it mirrors the registry.
- **Group dividers stay visible** when panels are collapsed, so the page still has a map.
- Only two scripts are needed: the filter, and on `shown.bs.collapse`
  `scrollIntoView({block:"start"})` + focus the header (`tabindex="-1"`).

Generated per section, server-side:

```html
<div class="accordion-item" id="vs-contact" data-vs-key="contact">
  <h2 class="accordion-header" id="vs-contact-h">
    <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse"
            data-bs-target="#vs-contact-p" aria-expanded="false" aria-controls="vs-contact-p">
      Contact Information</button>
  </h2>
  <div id="vs-contact-p" class="accordion-collapse collapse" data-bs-parent="#vsAccordion"
       aria-labelledby="vs-contact-h"><div class="accordion-body"><!-- pane --></div></div>
</div>
```

### 5.4 Deep linking is server-side, not JS

The section in `?context=<group>/<section>` is rendered with `show` and
`aria-expanded="true"`, so the URL is authoritative: refresh keeps the section, the back
button works, the sidebar can open a named section, and the accordion JS only handles
subsequent switching. `id="vs-<key>"` on each item also makes `#anchor` targets work.
Without this, an accordion settings page is unshareable and loses its place on reload —
the single biggest UX complaint about the pattern.

### 5.5 Sidebar

`render-sidebar-body`'s Settings node (`dod-ui-ven.lisp:147–151`) is generated from
`*vendor-settings*`: the three groups become the nested accordion (a new
`render-sidebar-group` helper beside `render-sidebar-dropdown` at `:78`), each leaf a
deep link. **Trap:** `render-sidebar-dropdown` hardcodes
`:data-bs-parent "#offcanvasExample"` (`:91`); a nested inner `<ul>` must carry a
*different* parent (e.g. `#settings`) or opening one subgroup collapses the whole
Settings section.

### 5.6 Storage and save granularity

- **Storage: reuse the existing `invoice-settings` column** (decided 2026-10-03). It
  already stores an alist of arbitrary sections — it holds `security-settings`,
  `advanced-settings` and `notification-and-alert-settings` today — so general vendor
  sections need no migration. The naming is a known wart; a dedicated `settings` column
  is a scripted migration in `nst-sch-mig.lisp` if desired later.
- **`DOD_VENDOR_SETTINGS` is NOT a store for this design — do not route through it.**
  ⚠️ **Corrected 2026-10-03.** The two tables (`DOD_VENDOR_SETTINGS` and
  `DOD_VENDOR_SETTINGS_DEFINITION`) belong to a **different, stalled line of work** — the
  **AI decision registry** (`hhub/vendor/nst-bl-vaisettings.lisp`, key form
  `nst.vendor.invoicesetting.*`) — which was started, reviewed, and **parked as premature
  by the owner's decision**. They are **pure schema with no reader and no writer**: no Lisp
  in the tree reads or writes either table (the only mention outside the DDL file is a
  docstring at `hhub/vendor/nst-dal-vnd.lisp:313`), and both Feb-2026 migration versions
  are already recorded as applied, so editing them does nothing. See
  `nst-bl-vaisettings-CONTEXT.md` §3 (two tables designed to hold system #2, holding
  nothing), §4, §5, and `PENDING-WORK-CONTEXT.md` §3.
  **Consequences for this design:** do not assume "the settings are in the DB" — they are
  not; and do not adopt a generic k/v surface as the target, because a generic surface
  destroys the response-model field-allowlist property that keeps `password`/`salt` off the
  wire. Storage for the vendor settings page is the `invoice-settings` blob above, through
  a single swappable write seam, with a dedicated column as the fallback if the blob stops
  fitting. If that AI registry line is ever revived it needs its own migration and its own
  decision — it is **not** a dependency of this page.
- **Save per key**, via a generalised `nst-save-vendor-setting` shaped exactly like
  `nst-save-vendor-invoiceprintsetting` (`nst-ui-ihd.lisp:233`): read-modify-write of the
  one key across the row and the session slot, `*read-eval* nil` on the read.
- **One representation only** — `(key . value)` conses; never mix in `(key value)` lists
  (§4.4).
- **Each action's redirect must echo the section back.** Six actions currently redirect to
  bare `/hhub/dodvendprofile` (`dod-ui-ven.lisp:908, 944, 1021, 1025, 1037, 1089, 1140`),
  which would dump the vendor at the top of the page after every save.
- **Forms post absolute paths** (`/hhub/...`). The existing fragments use relative actions
  (`"hhubvpmupdateaction"`, `"hhubvendupdateupisettings"`), which work only because every
  host page sits at `/hhub/…` depth.

### 5.7 Depth model for the whole tree

- **Tier 1 — sidebar:** domains only (Account, E-Commerce, Payments). Roughly constant.
- **Tier 2 — settings page section:** an accordion item, one URL
  (`?context=<key>`), one registry row.
- **Tier 3 — a section with sub-settings** (e.g. Shipping Methods and its five children,
  `:2002–2010`): the section's pane becomes a *nested* section page with the same
  registry shape (`?context=ecommerce/shipping` → its own children), or its children
  become their own accordion items in a sub-accordion whose inner `data-bs-parent` is the
  outer panel.
- **Rule:** a modal may only ever be a leaf, and a leaf must have a URL. Ship Methods'
  four modals are converted the same way — their content functions
  (`modal.vendor-free-shipping-config` etc.) are already complete forms.

### 5.8 Scaling past ~40 sections

Accordion of sections + group dividers + filter box carries a long way. Beyond roughly 40
sections, move to a two-pane layout — left `nav flex-column nav-pills` menu, right single
pane — where the menu stays visible while editing. Same registry, same panes, different
shell, so the switch is a template change, not a rewrite. A responsive hybrid
(accordion `<lg`, two-pane `≥lg`) is possible from one markup set but doubles
maintenance; only do it when the count justifies it.

---

## 6. Registration / build steps when this is implemented

| Step | File | Change |
|---|---|---|
| 1 | `hhub/vendor/templates/vendorsettings.lisp` | new — `*vendor-settings*` |
| 2 | `hhub/nstores.asd` (after `:140`) + `hhub/package/compile.lisp` (after `:306`) | register the new `.lisp` |
| 3 | `dod-ini-sys.lisp:182` | `(defvar *NST-VENDOR-SETTINGS-PAGE* "…/hhub/vendor/templates/vendorsettings.html")` |
| 4 | `dod-ini-sys.lisp:597–602` | read it in `nst-load-vendor-templates`, return it |
| 5 | `dod-ini-sys.lisp:604–608` | `(case templatenum (1 vendorprofilepage) (2 vendorsettingspage))` |
| 6 | `hhub/vendor/templates/vendorsettings.html` | new — chrome + `%Settings Sections%` + pane marker blocks |
| 7 | `hhub/vendor/dod-ui-ven.lisp:1934/1946` | extend the model + widget: resolve `?context=`, generate the accordion, extract + substitute panes |
| 8 | `hhub/vendor/dod-ui-ven.lisp:147–151` (+ helper near `:78`) | sidebar Settings node generated from the registry |
| 9 | `nst-ui-ihd.lisp` sibling (or vendor file) | generalised `nst-save-vendor-setting` |
| 10 | `dod-ui-ven.lisp:908, 944, 1021, 1025, 1037, 1089, 1140` | redirects echo the section back |

Reloading a template needs no image restart — re-run the loader
(`register-global-effect`, `nst-server-context.lisp:136/:254`) or restart the server.

---

## 7. Open decisions

1. **`[OPEN]` Shipping Methods' own sub-settings shape** — nested `?context` level, or a
   sub-accordion inside its pane (§5.7).
2. **`[OPEN]` Whether `findability` needs search over *values*** (not just section
   labels) — a bigger feature; the filter box only filters headers.
3. **`[OPEN]` Dedicated `settings` column** vs the reused `invoice-settings` column —
   naming cleanliness vs a migration. This is a *staging* question only, and the two
   candidates are the blob column and a dedicated column; `DOD_VENDOR_SETTINGS` is **not**
   in the running (§5.6 — it belongs to the parked AI registry line).
4. **`[OPEN]` Whether `dodvendprofile?context=` stays the canonical URL** or a new
   `/hhub/dodvendsettings` is introduced once the old hub page is retired. Reusing the
   existing route means zero dispatcher edits now; a new route reads better later.

---

## 8. File map

| Concern | File:line |
|---|---|
| Sidebar offcanvas / body / Settings node | `hhub/vendor/dod-ui-ven.lisp:153 / :112 / :147–151` |
| Sidebar item + dropdown helpers | `hhub/vendor/dod-ui-ven.lisp:69 / :78` |
| Vendor settings hub page (controller/model/widget) | `hhub/vendor/dod-ui-ven.lisp:1930 / :1934 / :1946` |
| The six hub items | `hhub/vendor/dod-ui-ven.lisp:1958–1973` |
| Modal fragments to become panes | `hhub/vendor/dod-ui-ven.lisp:778, 924, 953, 1041` |
| Shipping section + its five children | `hhub/vendor/dod-ui-ven.lisp:1977–2010`, Zonewise page `:2052` |
| Payment-flag session cache (login) | `hhub/vendor/dod-ui-ven.lisp:2508, 2541–2559` |
| Page template with sidebar (nav + sidebar render) | `hhub/core/dod-ui-utl.lisp:702`, `:746–748`; vendor wrapper `:793` |
| `with-mvc-ui-page` | `hhub/core/dod-ui-utl.lisp:1132` |
| Vendor breadcrumbs (keyed on **path**, not query) | `hhub/core/dod-ui-utl.lisp:1179`, `:1191`, `:1197` |
| `modal-dialog-v2` | `hhub/core/dod-ui-utl.lisp:1476` |
| Template vars / loaders / numbered getters | `hhub/core/dod-ini-sys.lisp:144–145`, `:182–183`, `:465–499`, `:502–520`, `:597–608` |
| Template cache registration | `hhub/core/nst-server-context.lisp:136`, `:242`, `:254` |
| `*invoice-settings*` + `update-config` | `hhub/invoice/templates/invoicesettings.lisp:10`, `:122` |
| Invoice settings page / model / widget | `hhub/invoice/nst-ui-ihd.lisp:112 / :116 / :129` |
| Settings alist readers (cons/list duality) | `hhub/invoice/nst-ui-ihd.lisp:139–164` |
| Vendor settings read / single-key write | `hhub/invoice/nst-ui-ihd.lisp:209`, `:233–248` |
| Invoice settings save action + logo hack | `hhub/invoice/nst-ui-ihd.lisp:436–480` |
| Vendor row `invoice-settings` slot | `hhub/vendor/dod-dal-ven.lisp:360`, `hhub/vendor/nst-dal-vnd.lisp:296/472` |
| `DOD_VENDOR_SETTINGS` — **not** this design's store | parked AI-registry schema, no reader/writer: `installation/upgrades/nst-dbu-vendorsettings.lisp`, `hhub/vendor/templates/dod-vendor-settings.txt`, mention at `nst-dal-vnd.lisp:313`; see `nst-bl-vaisettings-CONTEXT.md` §3–5 and `PENDING-WORK-CONTEXT.md` §3 |
| Dispatchers (vendor profile, groups, shipping, push, invoice settings) | `hhub/sysuser/dod-ui-sys.lisp:1086, 1076, 1117, 1106, 1155` |
| Marker extract + `%Token%` field-map pattern | `hhub/vendor/dod-ui-ven.lisp:3482`, `:3451`, `:3490–3533` |
| Migration framework | `aiharness/deepseek/skills/knowledge/schema-migrations-CONTEXT.md` |

---

## 9. Durable content to fold into `knowledge/` when this ships

The invoice-settings mechanism (§2) and the traps (§4) are **not** feature-specific —
they are how settings pages work in this codebase and belong in a
`knowledge/settings-pages-CONTEXT.md` once the vendor settings page is built. Until then
they live here with the design they serve.
