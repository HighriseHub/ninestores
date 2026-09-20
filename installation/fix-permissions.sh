#!/usr/bin/env bash
#
# fix-permissions.sh — make the ninestores tree fully shared between the
# `hunchentoot` (acceptor) and `ubuntu` (development) accounts.
#
# ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
# Both accounts are members of the group `hhubgrp`, and every file in the tree
# has been expected to be `hunchentoot:hhubgrp` since the start. In practice the
# mode bits drift, because:
#
#   * editors, the agent's write path, and `cp`/`mv` land files at 600 or 644
#     (owner-only or group-read-only) instead of the tree's usual 664;
#   * the directories carry NO setgid bit, so any file created by a process whose
#     primary group is not `hhubgrp` inherits the wrong group entirely — this is
#     how /home/hunchentoot/hhublogs ended up as `hunchentoot:nogroup`;
#   * the fix has to be run as root, because chmod requires ownership and these
#     files are owned by `hunchentoot`.
#
# The symptom is a silent, intermittent `Permission denied` — either account
# unable to write a file it just read, or hunchentoot unable to lay down the
# .fasl / compilation logs beside the sources it compiles.
#
# ── WHAT IT DOES ────────────────────────────────────────────────────────────
#   1. group `hhubgrp` on everything (so both accounts share via the group);
#   2. `g+rwX` on everything — read+write for the group, and execute ONLY where
#      it is meaningful (directories, and files that are already executable).
#      The capital X is the whole point: `g+x` on every file would be wrong, and
#      plain `g+rw` would leave a directory un-enterable;
#   3. setgid on every directory, so anything created later inherits `hhubgrp`
#      automatically and this never has to be run for that reason again.
#
# FASL CREATION, specifically: SBCL/ASDF writes .fasl files into the SOURCE
# directory and compilation logs into hhub/logs/. That needs write AND execute on
# the DIRECTORY, not execute on the .lisp file. Step 2 gives both.
#
# ── WHAT IT REPORTS, AND WHY THAT MATTERS ───────────────────────────────────
# Every step runs with chmod/chgrp's `-c` flag, which prints an entry ONLY when it
# actually changed something, and the output is captured, counted and shown under
# the step that produced it. You therefore get a list of exactly which entries
# this run modified and how, per step.
#
# The reason this is worth the few extra lines: the script is IDEMPOTENT and
# usually has nothing to do, so "no changes" is the normal, healthy answer — and
# without a report there was no way to tell a clean run from a no-op that silently
# failed to reach the files. It also turns the output into a record of the drift
# itself: seeing `mode changed from 0600 to 0664` on twenty files tells you a tool
# wrote them, WHERE it wrote them, and therefore which tool to fix. The summary at
# the end repeats the count so a run can be judged from its last line alone.
#
# ── USAGE ───────────────────────────────────────────────────────────────────
#   sudo bash installation/fix-permissions.sh
#   sudo bash installation/fix-permissions.sh /some/other/tree mygroup
#
# Idempotent — safe to re-run at any time, and worth re-running after a batch of
# edits by a tool that does not preserve mode bits. Run it twice: the second run
# reporting nothing is the proof that the first one finished the job.

set -uo pipefail

TREE="${1:-/home/ubuntu/ninestores}"
GROUP="${2:-hhubgrp}"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: must run as root (chmod requires ownership; the files are owned by hunchentoot)." >&2
  echo "       sudo bash $0" >&2
  exit 1
fi

if [ ! -d "$TREE" ]; then
  echo "ERROR: no such tree: $TREE" >&2
  exit 1
fi

if ! getent group "$GROUP" >/dev/null; then
  echo "ERROR: no such group: $GROUP" >&2
  exit 1
fi

CHANGES_DIR="$(mktemp -d)" || exit 1
trap 'rm -rf "$CHANGES_DIR"' EXIT
TOTAL=0

# report STEP LABEL FILE — count the recorded changes and show them indented.
report() {
  local step="$1" label="$2" file="$3" n
  n="$(wc -l < "$file" | tr -d ' ')"
  TOTAL=$((TOTAL + n))
  if [ "$n" -eq 0 ]; then
    printf '  [%s] %-28s no changes\n' "$step" "$label"
  else
    printf '  [%s] %-28s %s change(s)\n' "$step" "$label" "$n"
    sed 's/^/        /' "$file"
  fi
}

echo "tree  : $TREE"
echo "group : $GROUP"
echo
echo "Only entries this run actually MODIFIED are listed below; an untouched tree"
echo "reports 'no changes' at every step, which is the expected healthy result."
echo

echo "[1/4] setting group $GROUP ..."
chgrp -R -c "$GROUP" "$TREE" > "$CHANGES_DIR/chgrp" 2>&1
report 1 "group" "$CHANGES_DIR/chgrp"

echo "[2/4] g+rwX on files and directories ..."
# g+rwX: add group read+write everywhere, and group execute only on directories
# and on files that already have an execute bit. Excludes nothing — .git is part
# of the shared tree and benefits from the same treatment.
chmod -R -c g+rwX "$TREE" > "$CHANGES_DIR/chmod" 2>&1
report 2 "g+rwX" "$CHANGES_DIR/chmod"

echo "[3/4] setgid on directories (so future files inherit $GROUP) ..."
# -prune on .git is deliberately NOT used here: the repo's own metadata should
# inherit the group too.
find "$TREE" -type d -exec chmod -c g+s {} + > "$CHANGES_DIR/setgid" 2>&1
report 3 "setgid on directories" "$CHANGES_DIR/setgid"

echo "[4/4] verifying ..."
fail=0

missing_dir_rwx="$(find "$TREE" -type d ! -perm -g+rwx -print)"
if [ -n "$missing_dir_rwx" ]; then
  echo "  DIRS still missing g+rwx:"; echo "$missing_dir_rwx" | sed 's/^/    /'; fail=1
fi

missing_file_rw="$(find "$TREE" -type f ! -perm -g+rw -print)"
if [ -n "$missing_file_rw" ]; then
  echo "  FILES still missing g+rw:"; echo "$missing_file_rw" | sed 's/^/    /'; fail=1
fi

wrong_group="$(find "$TREE" ! -group "$GROUP" -print)"
if [ -n "$wrong_group" ]; then
  echo "  ENTRIES not in group $GROUP:"; echo "$wrong_group" | sed 's/^/    /'; fail=1
fi

nosetgid="$(find "$TREE" -type d ! -perm -g+s -print)"
if [ -n "$nosetgid" ]; then
  echo "  DIRS without setgid:"; echo "$nosetgid" | sed 's/^/    /'; fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "  verification: every entry is $GROUP with g+rwX, and every directory is setgid."
else
  echo "  verification: INCOMPLETE — see the lists above." >&2
fi

echo
echo "─────────────────────────────────────────────"
if [ "$TOTAL" -eq 0 ]; then
  echo "changed 0 entries — the tree was already correct, this run was a no-op."
else
  echo "changed $TOTAL entr$([ "$TOTAL" -eq 1 ] && echo y || echo ies) in total (listed per step above)."
fi

if [ "$fail" -ne 0 ]; then
  echo "RESULT: INCOMPLETE" >&2
  exit 1
fi
echo "RESULT: OK"
