# SKILL: File permissions on the shared hhub tree

**Status:** verified 2026-09-19 against `/home/ubuntu/ninestores`.
**Applies to:** every file operation on the repository — creating, editing, or fixing
permissions — and to the skills directory itself.
**Fix tool:** `installation/fix-permissions.sh` (must run as root).

This is written mainly for the **agent**, because the failure mode is not "the command
failed" but "the command silently did nothing useful, and the problem comes back next
session". Read §3 before touching permissions.

---

## 1. When to use this skill

- After creating or editing files, to check they landed with the right mode and group.
- When a `Permission denied` appears that makes no sense — usually the agent could read a
  file but not write it, or vice versa.
- When `hunchentoot` cannot write a `.fasl`, a compilation log, or a log file.
- Before telling the user "you need to run these chmods" — to get the command right the
  first time.

---

## 2. The model in one picture

```
   TWO ACCOUNTS, ONE GROUP                       OWNERSHIP ON DISK
   ┌────────────────────────────┐
   │ ubuntu       gid 1000      │                owner  hunchentoot   ← almost everything
   │   + hhubgrp  1002 ✔        │                group  hhubgrp      ← 1002, the shared group
   │ hunchentoot  gid 65534     │                mode   664 files / 775 dirs
   │   (nogroup!) + hhubgrp ✔   │                       + setgid on dirs
   └────────────────────────────┘
```

- **Sharing happens through the group `hhubgrp` (gid 1002).** Both accounts are members, so
  the group bits — not the owner — are what let each of them write the other's files.
- **`hunchentoot`'s *primary* group is `nogroup` (65534)**, not `hhubgrp`. This matters: any
  file created by a process whose primary group is `nogroup` lands outside the shared group
  unless the **setgid** bit on the containing directory forces `hhubgrp`.
- **`ubuntu`'s primary group is `ubuntu` (1000)** — same consequence in the other direction.
- **Almost everything is owned by `hunchentoot`**, including files the agent creates, because
  the tree gets chowned periodically.
- **Every directory carries setgid** (`drwxrwsr-x`), which is the thing that stops the group
  drifting again.

A file is correctly shared when it is **`664` (or the tree's usual mode), group `hhubgrp`,
and its containing directory is group-writable** — the owner is almost irrelevant.

---

## 3. 🚨 What the agent can and cannot do — the part that matters

| Operation | On a file the agent **owns** | On a file owned by **hunchentoot** |
|---|---|---|
| read | ✅ | ✅ if group-readable (`664`), ❌ if `600` |
| write | ✅ | ✅ **only** if group-writable (`g+w`) |
| `chmod` | ✅ | ❌ **EPERM — not the owner** |
| `chgrp` to `hhubgrp` | ✅ (a member) | ❌ EPERM |
| `chown` | ❌ | ❌ |
| `sudo` / become root | ❌ **`no_new_privs` is set — sudo can never run** |

Three consequences to internalise:

1. **`sudo` is permanently unavailable, not merely unconfigured.** Running it prints
   `The "no new privileges" flag is set, which prevents sudo from running as root.`
   Do not retry it, do not ask to escalate it, and do not design a fix that depends on it.
   (An escalation request was made and rejected once — that rejection is final for that
   command.)
2. **Writing to a directory does NOT let you chmod a file inside it.** `chmod` needs
   ownership or `CAP_FOWNER`; the containing directory's write bit is irrelevant. This is the
   trap that wasted the most time: the file was clearly writable, and the mode was clearly
   wrong, and there was no way to fix it in place.
3. **So: fix permissions on files you create *while you still own them*.** The moment the
   tree is chowned to `hunchentoot`, the agent can no longer correct them and the user has to.

**Standing rule after creating or editing any file:**

```bash
chgrp hhubgrp <file> && chmod 664 <file>      # only works while the agent owns it
```

The agent's own write path lands files at **`600` or `644` with the creator's primary
group**, not the tree's `664 hhubgrp`. Left alone, that is exactly the drift that made four
skills unreadable and blocked three separate pieces of work.

---

## 4. Diagnostics

**Is the tree healthy?** All four should be zero:

```bash
cd /home/ubuntu/ninestores
find . -type d ! -perm -g+rwx | wc -l        # dirs missing group rwx
find . -type f ! -perm -g+rw  | wc -l        # files missing group rw
find . ! -group hhubgrp       | wc -l        # entries outside the shared group
find . -type d ! -perm -g+s   | wc -l        # dirs without setgid
```

`! -perm -g+w` reads as *"does not have **all** of the group-read and group-write bits"* —
the leading `-` is what makes it an all-bits test rather than an exact-match. It is the right
predicate for "can the other account write this".

**Is one file usable by both accounts?**

```bash
ls -l <file>          # want: -rw-rw-r-- … hhubgrp
test -w <file> && echo writable
```

**Did setgid actually take effect?** Create a file and look at its group:

```bash
touch hhub/products/.sgtest && ls -l hhub/products/.sgtest && rm -f hhub/products/.sgtest
# group must be hhubgrp, NOT nogroup or ubuntu
```

---

## 5. The fix

```bash
sudo bash installation/fix-permissions.sh
```

The script takes the tree and group as optional arguments, refuses to run as non-root, and
does four things:

1. `chgrp -R hhubgrp` everything — so both accounts share via the group;
2. **`chmod -R g+rwX`** — group read+write everywhere, and execute **only** where it is
   meaningful: the capital `X` grants execute to directories and to files that already have
   an execute bit, and to nothing else. Plain `g+x` on 2800+ files would be wrong, and plain
   `g+rw` would leave directories un-enterable;
3. `chmod g+s` on every directory — so future files inherit `hhubgrp` automatically, which is
   what stops this recurring *for that reason*;
4. **verifies and exits non-zero**, printing the exact paths still wrong.

It is idempotent — safe to re-run any time, and worth re-running after a batch of agent
edits. Equivalent one-liners if the script is unavailable:

```bash
sudo chmod -R g+rwX /home/ubuntu/ninestores
sudo find /home/ubuntu/ninestores -type d -exec chmod g+s {} +
```

Both include `.git`, deliberately: it is part of the shared tree.

---

## 6. Traps

1. 🚨 **The agent cannot chmod anything it does not own** (§3). Fix modes at creation time.
2. 🚨 **`sudo` is dead** (`no_new_privs`). Any plan requiring root is a plan requiring the
   user, so say so rather than attempting it.
3. 🚨 **A multi-line command with trailing backslashes pastes badly.** A
   `chmod g+rw file1 \` + continuation applied only to **`file1`**; the other eight files and
   all four directories were silently untouched, and the verification output looked like the
   command had never run. **Use single-line `find … -exec` or the script.** This cost a full
   round-trip.
4. **Directory write ≠ permission to chmod its contents** (§3, point 2).
5. **`hunchentoot`'s primary group is `nogroup`**, so without setgid any file it creates lands
   outside `hhubgrp` — a real case exists at `/home/hunchentoot/hhublogs` (`hunchentoot:nogroup`),
   which is outside the repository and the agent can do nothing about.
6. **`g+rw` on a directory makes it un-enterable** — you need `g+x` too, which is why `X` in
   `g+rwX` matters.
7. **`600` is not "more secure", it is broken here.** A `600 hunchentoot:hhubgrp` file is
   unreadable by `ubuntu` — including by the agent, and including the agent's own skill files.
8. **`-perm -g+w` (all-bits) vs `-perm g+w` (exact match)** — the latter will miss files that
   have extra bits and report a false all-clear.
9. **Files outside the tree** may be `hunchentoot:root` or similar and are not covered by any
   of this. Check before assuming the repo rules apply.
10. **The `.fasl` and `compilation-*.log` outputs need directory `w+x`, not file `x`.**
    SBCL/ASDF writes `.fasl` beside the source and compilation logs into `hhub/logs/`; that
    needs write and execute on the **directory**. File execute bits are irrelevant to it —
    which is why the scripts that genuinely need `x` (`startup/hunchentoot`, `nst-start.sh`)
    are the only files that should have it.

---

## 7. The skills directory

`aiharness/deepseek/skills/` holds this project's skills; `README.md` there is the index and
states the convention.

After adding or editing a skill file, fix its permissions (§3) — a skill the agent cannot
read is worthless, and this has already happened once to four files at a time. Verified state:

```
-rw-rw-r-- hunchentoot:hhubgrp  ABAC-policy-transaction-CONTEXT.md
-rw-rw-r-- hunchentoot:hhubgrp  nst-bl-apidefs2-CONTEXT.md
-rw-rw-r-- hunchentoot:hhubgrp  nst-bl-prdapi-CONTEXT.md
-rw-rw-r-- hunchentoot:hhubgrp  nst-bl-vndapi-CONTEXT.md
-rw-rw-r-- ubuntu:hhubgrp       README.md
-rw-rw-r-- ubuntu:hhubgrp       schema-migrations-CONTEXT.md
-rw-rw-r-- hunchentoot:hhubgrp  WAREHOUSE-NST-GRAMMAR-CONTEXT.md
drwxrwsr-x hunchentoot:hhubgrp  .          ← setgid, so new files inherit hhubgrp
```

---

## 8. File map

| Concern | Location |
|---|---|
| The fix script | `installation/fix-permissions.sh` |
| Shared group | `hhubgrp`, gid 1002 (`getent group hhubgrp`) |
| Skill directory + convention | `aiharness/deepseek/skills/README.md` |
| The tree | `/home/ubuntu/ninestores` (its root dir is `777 ubuntu:hhubgrp`) |
| Compilation logs (needs dir `w+x`) | `hhub/logs/` |
| Out of scope, not fixable by the agent | `/home/hunchentoot/hhublogs`, `/home/hunchentoot/.cache/common-lisp` |

---

## 9. Current state (2026-09-19)

All four diagnostics at **zero**: 0 dirs missing `g+rwx`, 0 of 2836 files missing `g+rw`,
0 entries outside `hhubgrp`, 0 of 341 directories without setgid. The tree is healthy and
setgid means new files inherit the group automatically.

The residual risk is **the agent's own write path**, which lands `600`/`644` with the
creator's primary group — corrected by hand this session for two skill files. Re-run
`sudo bash installation/fix-permissions.sh` after any batch of agent edits, and treat a
sudden `Permission denied` on a file that was fine last session as this drift rather than
something exotic.
