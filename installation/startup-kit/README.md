# startup-kit — bring up a Nine Stores server from a bare Ubuntu box

This is the original build recipe — Zaries' *"Lisp Web Server From Scratch using
Hunchentoot and Nginx"* (2010, updated 2016), which is what highrisehub / Nine
Stores was first stood up from — turned into ordered scripts and the config
templates they write.
SOURCE - https://zaries.wordpress.com/2010/11/09/lisp-web-server-from-scratch-using-hunchentoot-and-nginx/

It is written to be **read as much as run**. Every script says what it is about
to do, why, and what it refuses to do; nothing here guesses on your behalf.

The reasoning, the port map and the traps in prose live in the knowledge file
`aiharness/deepseek/skills/knowledge/server-bootstrap-CONTEXT.md`. Read that first if you are
here because something is broken; read this file if you are building a box.

## What is verified, and what is not

| | |
|---|---|
| **Measured on the live host** (2026-10) | acceptor `127.0.0.1:4244`; static root `/data/www/public`; rewrite into `/hhub/` then `proxy_pass http://hunchentoot`; node servers on 4345 / 4300 / 4301; Swank 4016; shutdown 6200; MySQL 8, `hhubdb` / `hhubuser` / localhost; app user `hunchentoot` in shared group `hhubgrp` alongside `ubuntu`; detachtty + `/etc/init.d/hunchentoot`; `/home/hunchentoot/init.lisp → startup/init.lisp`; `~/log ~/run ~/hhublogs` |
| **From the original article, kept as-is** | detachtty supervision, the telnet-to-6200 stop, the per-vhost URL prefix trick, the `!-f` rewrite, iptables default-deny |
| **Modernised / not yet proven on a fresh box** | `apt`-installed SBCL instead of the 1.1.15 tarball; systemd-shipped `sshd_config.d` drop-in instead of editing `sshd_config`; ufw as the default firewall with raw iptables kept as the alternative; MySQL 8 auth note; Quicklisp from `beta.quicklisp.org` |
| **Deliberately absent** | TLS (add `certbot` once the site answers on :80); AWS SES/SNS credentials and `hhub/core/extkeys.lisp`; DNS; backups; the Proxmox host tuning in `../pve-nic-tune.sh` |

The kit has **not** been run end to end against a bare machine from inside this
repository — this host is already built. Treat the first run as the test, and
`verify.sh` as the arbiter.

## Use it

```bash
cd installation/startup-kit
cp config.env.example config.env
$EDITOR config.env                 # domain, paths, ports, users — all of it
chmod +x *.sh

sudo ./01-harden-host.sh           # locale, updates, admin user, ssh, firewall
sudo ./02-install-packages.sh      # apt: sbcl deps, mysql, nginx, node, pm2, wkhtmltopdf
sudo ./03-install-sbcl.sh          # distro sbcl, or SBCL_TARBALL_URL
sudo ./04-install-app-user.sh      # hunchentoot + hhubgrp + Quicklisp + checkout
sudo ./05-install-hunchentoot-service.sh   # detachtty, startup files, init script
sudo ./06-install-nginx.sh         # static root, vhost, reload
sudo ./07-install-database.sh      # mysql, db, user, schema
sudo ./verify.sh
```

Then start it — node servers first (pm2 keeps them alive), the image last:

```bash
$REPO/startup/nst-start.sh         # pm2 start push/sms/file servers, then
                                   # /etc/init.d/hunchentoot stop|clear|start
sudo ./verify.sh                   # ports and end-to-end should now be PASS
```

### Order, and why it is that order

`01` before everything: all later steps assume a key-only SSH login as a
non-root user. `03` before `04`: the app user's Quicklisp is installed by
running SBCL. `04` before `05`: the startup files live in the checkout and are
owned by the two accounts `04` creates. `06` last of the infrastructure: an
nginx vhost pointing at a port nothing listens on answers 502, which is a
useless thing to debug while the rest is still half-built. `07` is independent
of `05`/`06` and can be done any time before the first start.

### First start beats the kit's word for it

Nothing verifies the application faster than loading it. Inside the live image
(`attachtty` under the app user) or over Swank with
`aiharness/deepseek/tools/swank-eval.py`:

```lisp
(compile-hhub-files)     ; compile the tree
(start-das)              ; start acceptor + actors  — a Lisp call, not a shell command
```

`(setf *HHUBOTPTESTING* NIL)` and `(setf *siteurl* "https://<domain>")` are the
two global switches the README at the repository root calls out before a site is
live.

## The scripts

| file | does | refuses |
|---|---|---|
| `01-harden-host.sh` | locale, updates, admin user, sshd drop-in, ufw | to disable password auth when the admin has no key (`SKIP_SSH=1` skips sshd entirely) |
| `02-install-packages.sh` | every apt package the platform needs | — (skips what is installed) |
| `03-install-sbcl.sh` | distro `sbcl`, or a tarball | a tarball whose name does not match `uname -m` |
| `04-install-app-user.sh` | `hunchentoot`, `hhubgrp`, dirs, Quicklisp, shared-tree permissions | to clone the repo — it configures an existing checkout, it does not guess a remote |
| `05-install-hunchentoot-service.sh` | detachtty, `init.lisp`, `load.lisp`, `start-hunchentoot`, `/etc/init.d/hunchentoot` | to overwrite existing startup files or init script (`FORCE=1` to) |
| `06-install-nginx.sh` | static root, vhost, `nginx -t`, reload | to install a config that fails `nginx -t` |
| `07-install-database.sh` | mysql, database, user, grants, schema | to load seed SQL over a database that already has tables |
| `verify.sh` | read-only checks; exits 1 and names the failure | — (changes nothing, needs no config beyond `config.env`) |

Every script sources `lib.sh` (strict mode, `config.env`, `render`), is safe to
re-run, and is expected to be read before it is trusted.

## Templates

`templates/` holds the files the scripts render with `@TOKEN@` substitution:

- `init.lisp` — Swank first, guarded system load, then block on the shutdown port
- `load.lisp` — Quicklisp dependencies, `(ql:quickload :nstores)`, `(start-das)`
- `start-hunchentoot` — the detachtty invocation (`--userinit` is load-bearing)
- `hunchentoot.initd` — `start` · `stop` (telnet 6200) · `restart` · `status` · `clear`
- `nginx-site.conf.tpl` — upstreams, static rules, the `!-f` rewrite, `/push/ /sms/ /file/`
- `iptables.up.rules` — the raw-iptables alternative to ufw (use one, not both)

## When it goes wrong

| symptom | first move |
|---|---|
| `stop` does nothing | is the `telnet` client installed? then the image died during load — `restart` will not help, use `clear` |
| site down, nginx 502, nothing on 4244 | `tail -100 -f $APP_HOME/log/hunchentoot.dribble` — the SBCL transcript, where load errors appear |
| intermittent `Permission denied` | the group/setgid model: run `../fix-permissions.sh`, see `aiharness/deepseek/skills/knowledge/permissions-CONTEXT.md` |
| compiled but the server runs old code | compiling is not loading — `swank-eval.py` against the live image; `aiharness/deepseek/skills/knowledge/build-and-load-CONTEXT.md` §9 |
| MySQL "Access denied" with the right password | MySQL 8 default auth plugin — recreate the user `IDENTIFIED WITH mysql_native_password` |
| a vhost serves the wrong site | `sites-enabled/default` still present, or a second image holding 6200 |

## Not part of this kit, on purpose

`installation/` already carries the rest of an installation: the seed and
migration SQL, `deploysite.sh` (static assets → `$WWW_ROOT`), `fix-permissions.sh`,
`cronjobs.txt` and `dailyorderscron.txt`, `pve-nic-tune.sh` (Proxmox host),
`dsh-tunnel.sh`. This kit builds a box; those run on it.
