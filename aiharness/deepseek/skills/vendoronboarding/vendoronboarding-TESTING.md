# vendoronboarding — TESTING: prove the two mails, then reset the data

**Read this when:** you are verifying E1/E2 end to end, a vendor mail did not arrive or arrived at
the **wrong address**, an approval page 500s, or you need to delete the test vendors you just
created (and hit `ERROR 1217 Cannot delete or update a parent row`).

> **Status: verified by use 2026-10-17/18.** Every command below was run in this session; the
> "expected" column is what was actually observed, except where marked **open**.

---

## 1. The ladder — cheapest gate first, each one catches a different class

**T0 — build gate (throws nothing at the server).** The tree's own driver in a throwaway SBCL;
`Failed: 0` is the pass. A `STAGE: SETUP PROBLEM` mentioning `clsql-dist` is a setup fault, not the
tree — run the `cp` it prints.

```bash
cd /home/ubuntu/ninestores
XDG_CACHE_HOME=$PWD/.asdf-cache sbcl --noinform --non-interactive \
  --load aiharness/deepseek/tools/nst-compile-production.lisp
```

**T1 — restart and count the actors.** `register-effect`s only run at boot, so a file load is not
enough:

```bash
sudo systemctl restart hunchentoot && curl -sI http://127.0.0.1:4244/ | head -1
```
```lisp
(actors-status-report)   ; want 5: Send Order Email, Send Email, Vendor Email, Company Admin Email, S3
```
🚨 Testing before the restart silently exercises the **previous** image: you will get the old
`cust-reg.html` and no admin mail, and conclude the code is wrong.

**T2 — dry run: template + routing, no DB row, no real mail.** Swaps `hhubsendmail` for a printer
inside `unwind-protect` so the live image is left exactly as found:

```lisp
(let ((real (symbol-function 'hhubsendmail)))
  (unwind-protect
       (progn
         (setf (symbol-function 'hhubsendmail)
               (lambda (to subject body &optional (from *HHUBSMTPSENDER*) atts)
                 (declare (ignore from atts))
                 (format t "~&=== DRY ===~&TO: ~A~&SUBJECT: ~A~&~%~A~%" to subject body) t))
         (send-vendor-admin-pending-email (select-vendor-by-id 24) (select-company-by-id 5))
         (sleep 2))
    (setf (symbol-function 'hhubsendmail) real)))
```
Expect the recipient printed **once per admin address**, the vendor's address only inside
`Email: …`, and no `%Token%` or `NIL` in the body.

**T3 — the create path with no captcha and no OTP** (the browser form is behind Google reCAPTCHA,
so it cannot be scripted). This is the `VEN` branch verbatim:

```lisp
(let* ((company (select-company-by-id 5))
       (vendor (make-instance 'dod-vend-profile
                              :name "ZZ Test Vendor" :address "Test Mills, Mumbai"
                              :email "you@yourmailbox.com" :phone "9000000009"
                              :username "" :password ""
                              :approved-flag "N" :active-flag "Y" :approval-status "PENDING"
                              :tenant-id 5 :push-notify-subs-flag "N" :deleted-state "N"
                              :invoice-settings (nst-invoicesettings-seed-string))))
  (clsql:update-records-from-instance vendor)
  (create-vendor-tenant vendor "Y" company)
  (create-free-shipping-method *HHUBFREESHIPMINORDERAMT* vendor company)
  (send-vendor-registered-email vendor company)
  (send-vendor-admin-pending-email vendor company)
  (slot-value vendor 'row-id))
```

**T4 — the full browser journey.** `/hhub/custsignup1.html` → pick a store card → `reg-type`
Vendor → **a phone not used in that store yet** → reCAPTCHA → the page redirects to
`/hhub/otppage?session=XXXXXXXX&phone=…`. The SMS goes to the phone, so for testing read the code
from the store instead (no config change, no `*HHUBOTPTESTING*`):

```lisp
(funcall *otp-store* :get-otp :session-id "XXXXXXXX")      ; 6 digits
(funcall *otp-store* :get-context :session-id "XXXXXXXX")  ; "dodcustregisteraction"
```
TTL is **120 s** (`*otp-default-ttl*`), the session is 5 minutes; miss it and re-submit the form.

**T5 — the pass/fail checks.**

| # | check | expected |
|---|---|---|
| 1 | vendor's inbox | E1 `Registration received - <store> on Nine Stores` |
| 2 | admin's inbox | E2 `Approval needed - <vendor> registered as a vendor` — **confirmed 2026-10-19** with the admin address in its own Guerrilla session |
| 3 | `[vendor-onboarding]` log lines | one `E1 -> <vendor>` and one `E2 -> (<admin emails>)` |
| 4 | `(actors-status-report)` | Vendor Email Actor +1, **Company Admin Email Actor +1**, generic `Send Email Actor` unchanged |
| 5 | `DOD_VEND_PROFILE` | `APPROVED_FLAG='N'`, `APPROVAL_STATUS='PENDING'`, and **`INVOICE_SETTINGS` seeded** — 2,600–2,800 chars, head `((INVOICE-PRINT-SETTINGS (:DEFAULTINVOICETEMPLATENUM . "13")`. A 9-byte `undefined` here is B8 |
| 6 | `DOD_VENDOR_TENANTS` | one row, `DEFAULT_FLAG='Y'` |
| 7 | vendor login | still refused (the gate needs `Y` **and** `APPROVED`) |
| 7b | vendor login **after** approval | reaches `/hhub/dodvendindex?context=home`; a 500 with `UNBOUND-SLOT TRUTH` is B7 and is fixed |
| 8 | approval page | the vendor's tile appears; approving flips the row to `Y/APPROVED` |

**T6 — reset.** See §3.

## 2. Diagnostics — which measurement answers which symptom

**Nothing recorded who was notified.** Only *failures* were logged until 2026-10-18, when both
senders gained an audit line (this is why a mis-recipient could not be explained from the box):

```bash
sudo tail -40 /home/hunchentoot/hhublogs/ninestores-busfunctions.log | grep vendor-onboarding
# [vendor-onboarding] E1 -> zfmz7f+…@guerrillamail.org (vendor Ravi Shastry, tenant 5)
# [vendor-onboarding] E2 -> (zflyzs+…@sharklasers.com) (admin of tenant 5 Basic Account, vendor Ravi Shastry)
```

| symptom | measure this first |
|---|---|
| no admin mail at all | `(select-compadmin-emails-for-tenant 5)` — NIL means the tenant has no `COMPADMIN` address, and the sender then sends nothing (by design) |
| mail missing although the log says it was addressed | `(length (actor-dead-letters (cdr (assoc :admin *NST-EMAIL-ACTORS*))))`, and grep the log for `actor Company Admin Email Actor : giving up … dead lettered`. The relay is **AWS SES**: in sandbox mode it refuses unverified recipients, and that refusal is invisible here |
| mail at the **wrong inbox** | the message's **`To:` header**, not the list view. Then the timeline: `DOD_USERS.UPDATED` (when the admin address last changed) against `DOD_VEND_PROFILE.CREATED` (when the vendor registered). Both mails landing in one window is otherwise a mail-client artefact — `guerrillamail.org` and `sharklasers.com` are the same disposable service, and their addresses carry a `+tag` |
| the whole registration 500s | rebuild the message in isolation with the T2/T3 forms before touching the web flow |
| **the first login 500s with `The slot …TRUTH is unbound`** | `select count(*) from DOD_VPAYMENT_METHODS where VENDOR_ID=<id>` — **0 is the normal state right after registration**, and it used to be fatal (`addloginvendorsettings` → `VPaymentMethodsService.doread` → unbound Belnap default). Fixed 2026-10-19; see `../knowledge/belnap-four-states-CONTEXT.md` §17 |

**CLOSED BY OBSERVATION 2026-10-19 — E1 and E2 do reach their own inboxes.** Re-run with the
vendor's address and the tenant's `COMPADMIN` address in **two separate Guerrilla sessions** (two
browsers): E1 landed in the vendor's inbox and E2 in the admin's, as designed. Treat that as the
working configuration for testing.

**Still unexplained, deliberately recorded:** the 2026-10-18 run in which *both* mails appeared in
the vendor's window (`zfmz7f+…@guerrillamail.org`) while `DOD_USERS.ROW_ID 6` held
`zflyzs+…@sharklasers.com`. The app side was proven correct (the helper's SQL, the sender's `to`,
no CC/BCC anywhere, `hhubsendmail` passing `to` straight through) — so this was **not** reproduced
as an application fault. If it ever recurs, the first measurement is still the message's **`To:`
header**, not the app: read that before touching code.

## 3. Deleting test vendors — the FK order

`DOD_VEND_PROFILE` has **16 child tables with ON DELETE NO ACTION** (`DOD_SHIPPING_METHODS` is the
one registration always creates, which is why the naive delete answers `ERROR 1217`), one child with
`ON DELETE SET NULL` (`DOD_ORG_RELATIONS`), and **7 tables that carry `VENDOR_ID` with no FK at
all** — those orphan silently, so the sweep must name them.

Pre-flight — what will actually be affected, for any vendor id:

```sql
select concat('select ''',table_name,''', count(*) from ',table_name,' where VENDOR_ID=@v;')
from information_schema.columns
where table_schema='hhubdb' and column_name='VENDOR_ID';
```

Then, children before parent, one transaction (this is the exact sweep used on 2026-10-18):

```sql
set @v := 22, @t := 5;
start transaction;
  delete from DOD_BUYER_VENDOR_ACCOUNT where VENDOR_ID=@v;
  delete from DOD_CUST_WALLET          where VENDOR_ID=@v;
  delete from DOD_GSTR1_EXPORTS        where VENDOR_ID=@v;
  delete from DOD_INVOICE_GSTR1_TRACKING where VENDOR_ID=@v;
  delete from DOD_PAYMENT_TRANSACTION  where VENDOR_ID=@v;
  delete from DOD_TDS_CERTIFICATES     where VENDOR_ID=@v;
  delete from DOD_VENDOR_APPOINTMENT   where VENDOR_ID=@v;
  delete from DOD_VENDOR_AVAILABILITY_DAY where VENDOR_ID=@v;
  delete from DOD_VENDOR_GSTR1_STATUS  where VENDOR_ID=@v;
  delete from DOD_VENDOR_SHIP_ZONES    where VENDOR_ID=@v;
  delete from DOD_VPAYMENT_METHODS     where VENDOR_ID=@v;
  delete from DOD_VPAYMENT_PROVIDERS   where VENDOR_ID=@v;
  delete from DOD_WEBPUSH_NOTIFY       where VENDOR_ID=@v;
  delete from DOD_INVOICE_HEADER       where VENDOR_ID=@v;   -- ⚠ has its own children
  delete from DOD_PRD_MASTER           where VENDOR_ID=@v;
  delete from DOD_SHIPPING_METHODS     where VENDOR_ID=@v;
  delete from DOD_VENDOR_SETTINGS      where VENDOR_ID=@v;   -- no FK, orphans otherwise
  delete from DOD_VENDOR_TENANTS       where VENDOR_ID=@v and TENANT_ID=@t;
  delete from DOD_ORDER_ITEMS          where VENDOR_ID=@v;
  delete from DOD_VENDOR_ORDERS        where VENDOR_ID=@v;
  delete from DOD_UPI_PAYMENTS         where VENDOR_ID=@v;
  delete from DOD_PROFORMA_INVOICES    where vendor_id=@v;
  delete from DOD_ADVANCE_RECEIPT_VOUCHERS where vendor_id=@v;
  delete from DOD_VEND_PROFILE         where ROW_ID=@v and TENANT_ID=@t;
commit;
```

Verify, and check nothing was orphaned:

```sql
select count(*) from DOD_VENDOR_TENANTS  where VENDOR_ID not in (select ROW_ID from DOD_VEND_PROFILE);
select count(*) from DOD_SHIPPING_METHODS where VENDOR_ID not in (select ROW_ID from DOD_VEND_PROFILE);
```

Two rules that come with it:
- **A real vendor is never hard-deleted.** Vendor 17 carries 48 `DOD_VENDOR_ORDERS`, 5 products and
  2 invoices; those tables have no FK, so a delete orphans GST history. Retire it with
  `DELETED_STATE='Y', ACTIVE_FLAG='N'` — which keeps the phone reserved, deliberately.
- **The phone is freed by the delete.** `UC_Vendor (PHONE, TENANT_ID)` is unique and the `VEN`
  branch has no duplicate pre-check (blocker B5), so a re-registration on a still-existing phone is
  a 500, not a message.

## 4. Known leftovers you will trip over

- **`Copy-DBObject-To-BusinessObject` stores the hydrated object in the `dbobject` slot**
  (`vendor/dod-bl-ven.lisp:66-69`) — a pre-existing typo, inert on the approve path because nothing
  reads it afterwards. Fix before something does.
- **A `Y/PENDING` row is invisible to the queue and refused by the login gate** (live example:
  vendor 17). The repair is the existing **Approve** action — `doupdate` sets both columns — once
  the queue query is widened to include that state (`vendoronboarding-FLOWS.md` §3, item B).
