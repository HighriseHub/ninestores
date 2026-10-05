# SKILL: Bootstrapping a Nine Stores server from scratch

**Read this when:** you are installing, re-imaging or migrating a server; the acceptor
will not start or will not stop; nginx answers `502` with nothing behind it; you need to
know which component owns a port, a path or a permission; you are hardening a new box.

**Source:** Zaries' *"Lisp Web Server From Scratch using Hunchentoot and Nginx"*
(2010, updated 2016) — the recipe highrisehub, and so Nine Stores, was first stood up
from. The prose below is that recipe reconciled with what this host actually runs.

**Status:** the stack, ports, paths and accounts below were **measured on the live host
(2026-10-05)**. The scripted form is `installation/startup-kit/`, which has
**not** yet been run end to end against a bare machine — this host is already built.
Treat the kit's first run as its test, and `installation/startup-kit/verify.sh` as the
arbiter.

**Applies to:** `installation/startup-kit/`, `startup/`, `/etc/init.d/hunchentoot`,
`/etc/nginx/sites-available/<domain>`, and every decision about what listens where.

---

## 1. The stack, and who owns what

```
browser ──► nginx :80 ──┬─► /data/www/public        (static: js css img csv index.html)
                        ├─► /hhub/  ─► 127.0.0.1:4244   Hunchentoot/SBCL  ← the application
                        ├─► /push/  ─► 127.0.0.1:4345   node/pm2  webpush
                        ├─► /sms/   ─► 127.0.0.1:4300   node/pm2  AWS SNS SMS
                        └─► /file/  ─► 127.0.0.1:4301   node/pm2  AWS S3 v3
MySQL :3306 (localhost only)        Swank :4016 (localhost)     shutdown :6200 (localhost)
```

| Fact | Value |
|---|---|
| Hunchentoot acceptor | `127.0.0.1:4244`, behind the `upstream hunchentoot` block |
| Static root | `/data/www/public` — **not** `/var/www/…`, and not the repo's `site/public` |
| URL prefix into Lisp | `/hhub/` — the article's per-vhost prefix trick (`/myhome/`), still in use |
| Rewrite | `if (!-f $request_filename) { rewrite ^/(.*)$ /hhub/$1 last; break; }` then `location /hhub/ { proxy_pass http://hunchentoot; }` |
| App user / group | `hunchentoot`, primary group `hhubgrp`; dev user `ubuntu` is **also** in `hhubgrp` |
| Repo (compiled in place) | `/home/ubuntu/ninestores`, `hhub/` is the ASDF system `nstores` |
| Startup dir | `/home/ubuntu/ninestores/startup/` — `init.lisp`, `load.lisp`, `hunchentoot`, `start-hunchentoot`, `nst-start.sh` |
| Home dirs | `/home/hunchentoot/init.lisp` → symlink to `startup/init.lisp`; `quicklisp` → `/home/ubuntu/quicklisp` |
| App home state | `~/log`, `~/run`, `~/hhublogs` (startup log/dribble/pid, and `cronjob.log`) |
| Service control | SysV script `/etc/init.d/hunchentoot` (`start` · `stop` · `restart` · `status` · `clear`) |
| Process supervisor | **detachtty**, not systemd — `attachtty` reaches the live image |
| DB | MySQL 8, `*crm-database-name* "hhubdb"`, user `hhubuser`, `localhost`, globals in `hhub/core/dod-ini-sys.lisp` |
| Boot order | node servers via `startup/nst-start.sh` (pm2), then `/etc/init.d/hunchentoot stop\|clear\|start` |

**Known drift on the live host:** the acceptor is bound `0.0.0.0:4244` (and the node
servers on `*:4300/4301/4345`) although nginx proxies them over loopback — loopback-only
binding is what the table above intends, and tightening it needs an image restart.

## 2. The recipe, in the order that works

1. **Host + access.** Ubuntu, ≥8 GB RAM (SBCL reserves, and the GC needs headroom).
   Harden before anything else: locale, `apt update && upgrade`, a non-root admin with
   `sudo`, SSH **key** auth, `PermitRootLogin no`, `PasswordAuthentication no`,
   non-default `Port`, `AllowUsers <admin>`. Reload ssh, then prove the key works from a
   **second terminal before closing the first**.
2. **Firewall.** Allow 22 (or your ssh port), 80, 443, icmp; default-deny the rest;
   persist across reboot (ufw, or `/etc/iptables/rules.v4`). Never open 4244/4016/6200/
   3306 — every one of them is bound to `127.0.0.1` on purpose.
3. **Toolchain.** `build-essential`, `libuv1-dev` (cl-async), the MySQL client libs
   (clsql), `wget curl unzip telnet`, `nodejs npm` + `pm2 -g`, `wkhtmltopdf` (invoice
   PDFs), `qrencode`, `mysql-server`, `nginx`.
4. **SBCL.** Distro build, or the binary tarball **matching the architecture**
   (`x86-64` vs `x86`) followed by `sh install.sh`.
5. **App user.** System user `hunchentoot` with a real home and shell, in the shared
   group `hhubgrp`; `~/log ~/run ~/hhublogs` owned by it; the repo shared with it.
6. **Quicklisp.** Install as the dev user, symlink into the app user's home
   (`~hunchentoot/quicklisp → ~ubuntu/quicklisp`). `ql:add-to-init-file` writes
   `~/.sbclrc`, which is what makes the libraries load for the acceptor.
7. **The application.** `load.lisp` quickloads the dependency list, then
   `(ql:quickload :nstores)`, then `(start-das)`; then `(compile-hhub-files)`. `start-das`
   runs **inside the image** — it is not a shell command.
8. **Supervision.** `detachtty` under `/etc/init.d/hunchentoot`, driven by
   `startup/start-hunchentoot`; `init.lisp` starts Swank, loads the system, then blocks on
   the shutdown port.
9. **nginx + vhosts.** `sites-available/<domain>` with the `upstream` blocks, the static
   root, the `!-f` rewrite into `/hhub/`, and one `location` per node server. TLS belongs
   at the edge (`certbot`); the app speaks plain HTTP behind it (its own SSL acceptor
   exists but is unused: `easy-ssl-acceptor :port 9443`).

## 3. The traps

Each of these has cost a session.

- **Port 6200 is the shutdown channel.** `stop` is literally `telnet 127.0.0.1 6200`, and
  *anything* that connects stops the server. The **telnet client must be installed** or
  stop silently does nothing; after a stop, wait ~7s. `init.lisp` also binds 6200 — a
  second image cannot start while the first lives.
- **No acceptor at all ⇒ nginx 502.** Look at `~/log/hunchentoot.dribble` (the SBCL
  transcript), not at nginx: a load error, an unbound slot, a missing class all surface
  there.
- **Half-dead after a failed load.** `stop` cannot signal a process that died during
  load. Use the init script's `clear` (kill the pid from `~/run/hunchentoot.pid`, remove
  `log/hunchentoot.dribble` and `run/*`) before starting again.
- **`define-easy-handler` routes vanish** unless the acceptor is
  `hunchentoot:easy-acceptor` (Hunchentoot ≥1.2.1); a plain `acceptor` silently ignores
  the easy-handler table. That table is also global, which is *why* virtual hosts cannot
  be done inside Hunchentoot and why the `/hhub/` prefix + nginx rewrite exists.
- **Group, not permission bits.** `hhubgrp` on everything, `g+rwX`, **setgid on every
  directory**. Without setgid a root-run `cp` or an editor lands a file as
  `hunchentoot:nogroup` and the other account can no longer write it — an intermittent
  `Permission denied` that looks like an application bug.
  `installation/fix-permissions.sh` is the repair; see `permissions-CONTEXT.md`.
- **SBCL architecture.** The 64-bit tarball on a 32-bit box (or the reverse) installs
  without a single error and then will not run.
- **MySQL 8 auth.** If CLSQL/libmysqlclient refuses the app user, re-create it with
  `IDENTIFIED WITH mysql_native_password` — the 8.0 default plugin is the usual cause.
  Idle connections are dropped after a couple of hours: the app recovers through
  `nst-db-refresh`, not by a restart.
- **Rebuilding is not restarting.** Compiling a file is not loading it; after a successful
  compile the image still runs the old code until it is loaded. Use
  `aiharness/deepseek/tools/swank-eval.py` against the live image, and read
  `build-and-load-CONTEXT.md` §9 first (`-f` vs `-F`, absolute paths, 644).
- **Order of startup.** Node servers first (pm2 keeps them alive), the image last;
  `startup/nst-start.sh` does exactly this and is the one command to prefer.
- **Nothing in front of Hunchentoot is a cache.** nginx serves the static tree and its
  `expires` rules; every dynamic `/hhub/` request reaches Lisp. Put caching and rate
  limits at the edge if a page is ever linked publicly.

## 4. The kit

`installation/startup-kit/` turns the nine steps above into ordered scripts plus the
config templates they render (`init.lisp`, `load.lisp`, `start-hunchentoot`,
`hunchentoot.initd`, nginx vhost, raw-iptables alternative), all parameterised by
`config.env`. Each script states what it will do and refuses to do it twice; several
refuse outright rather than guess (no repo remote, no seed SQL over a populated
database, no mismatched SBCL tarball, no disabling of password auth without a key).

Read `installation/startup-kit/README.md` before running anything: it lists what is
verified from the live host against what is still assumed, and the kit never touches an
existing installation's data without being told to.

## 5. Related

- `permissions-CONTEXT.md` — the two-account/one-group model, and why group and setgid
  rather than mode bits.
- `build-and-load-CONTEXT.md` §7 and §9 — the 502/no-acceptor symptoms and how to load or
  evaluate against the live image.
- `schema-migrations-CONTEXT.md` — what happens to the database after the box is built.
- `installation/` — the rest of an installation: seed and migration SQL,
  `deploysite.sh`, `fix-permissions.sh`, `cronjobs.txt`, `pve-nic-tune.sh`, `dsh-tunnel.sh`.
