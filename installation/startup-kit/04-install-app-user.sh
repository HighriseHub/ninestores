#!/usr/bin/env bash
#
# 04-install-app-user.sh — the two-account / one-group model that the whole tree
# depends on, plus Quicklisp and the checkout.
#
#   hunchentoot : runs the acceptor, owns ~/log ~/run ~/hhublogs
#   <DEV_USER>  : the human/agent account, owns the checkout
#   both are in <APP_GROUP>, and every directory is setgid so anything either
#   account creates keeps the group. Without setgid you get files reading
#   `hunchentoot:nogroup` and an intermittent Permission denied that looks like
#   an application bug. See aiharness/deepseek/skills/knowledge/permissions-CONTEXT.md
#   and ../fix-permissions.sh (the repair for an existing tree).
#
# SKIP_QUICKLISP=1 if Quicklisp is already installed and only permissions need
# re-applying (this script is safe to re-run).

. "$(dirname "$0")/lib.sh"
require_root

# ── 1. group + users ────────────────────────────────────────────────────────
log "group $APP_GROUP"
getent group "$APP_GROUP" >/dev/null || groupadd "$APP_GROUP"
ok "$(getent group "$APP_GROUP")"

log "app user $APP_USER"
if id "$APP_USER" >/dev/null 2>&1; then
  ok "user exists"
else
  adduser --system --disabled-password --home "$APP_HOME" --shell /bin/bash \
          --ingroup "$APP_GROUP" "$APP_USER"
fi
usermod -aG "$APP_GROUP" "$APP_USER"
for u in "$DEV_USER" "$ADMIN_USER"; do
  id "$u" >/dev/null 2>&1 && usermod -aG "$APP_GROUP" "$u" && ok "$u -> $APP_GROUP"
done

# ── 2. app home: log, run, hhublogs ─────────────────────────────────────────
log "app home state directories"
for d in log run hhublogs resources; do
  install -d -m 2775 -o "$APP_USER" -g "$APP_GROUP" "$APP_HOME/$d"
done
ok "$APP_HOME/{log,run,hhublogs,resources}"

# ── 3. the checkout ─────────────────────────────────────────────────────────
log "checkout at $REPO"
if [ -d "$REPO/.git" ]; then
  ok "repository present — leaving the working tree alone"
else
  warn "$REPO is not a git checkout. Clone it as $DEV_USER, e.g."
  warn "  sudo -u $DEV_USER git clone <remote> $REPO"
  die "stopping here: the kit configures an existing checkout, it does not guess a remote"
fi

log "shared-tree permissions (group + setgid, no surprises later)"
chgrp -R "$APP_GROUP" "$REPO"
chmod -R g+rwX "$REPO"
find "$REPO" -type d -exec chmod g+s {} +
ok "tree is $APP_GROUP, directories setgid"

# ── 4. Quicklisp ────────────────────────────────────────────────────────────
QL_DIR="/home/$DEV_USER/quicklisp"
if [ "${SKIP_QUICKLISP:-0}" = "1" ]; then
  warn "SKIP_QUICKLISP set — not installing"
elif [ -f "$QL_DIR/setup.lisp" ]; then
  ok "Quicklisp present at $QL_DIR"
else
  log "installing Quicklisp as $DEV_USER"
  tmp="$(mktemp -d)"
  curl -sSL -o "$tmp/quicklisp.lisp" https://beta.quicklisp.org/quicklisp.lisp
  chown "$DEV_USER" "$tmp/quicklisp.lisp"
  sudo -u "$DEV_USER" sbcl --non-interactive --load "$tmp/quicklisp.lisp" \
       --eval '(quicklisp-quickstart:install)' \
       --eval '(ql:add-to-init-file)'
  rm -rf "$tmp"
  [ -f "$QL_DIR/setup.lisp" ] || die "Quicklisp install did not produce $QL_DIR/setup.lisp"
  ok "Quicklisp installed (add-to-init-file wrote ~$DEV_USER/.sbclrc)"
fi

# ── 5. let the app user see both Quicklisp and the startup files ────────────
log "symlinks into $APP_HOME"
ln -sfn "$QL_DIR" "$APP_HOME/quicklisp"
ln -sfn "$REPO/startup/init.lisp" "$APP_HOME/init.lisp"
chown -h "$APP_USER:$APP_GROUP" "$APP_HOME/quicklisp" "$APP_HOME/init.lisp"

# ~hunchentoot/.sbclrc is what actually loads Quicklisp for the acceptor
cat > "$APP_HOME/.sbclrc" <<'EOF'
;;; Written by installation/startup-kit/04-install-app-user.sh
#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))
EOF
chown "$APP_USER:$APP_GROUP" "$APP_HOME/.sbclrc"
chmod 644 "$APP_HOME/.sbclrc"
ok "~$APP_USER/.sbclrc loads Quicklisp"

log "done. Next: 05-install-hunchentoot-service.sh"
