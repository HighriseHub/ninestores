#!/usr/bin/env bash
#
# 03-install-sbcl.sh — the Lisp itself.
#
# Two routes, distro first:
#   * apt's sbcl — Ubuntu 24.04 ships 2.3.x, which is fine and is what this host
#     effectively runs.
#   * a binary tarball, when SBCL_TARBALL_URL is set in config.env. THE URL MUST
#     MATCH THE ARCHITECTURE: installing the x86-64 tarball on a 32-bit box (or
#     the reverse) installs without a single error and then will not run. That
#     mistake has been made here before; the check below is the answer to it.

. "$(dirname "$0")/lib.sh"
require_root

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  TARBALL_ARCH="x86-64" ;;
  i686|i386) TARBALL_ARCH="x86" ;;
  aarch64) TARBALL_ARCH="arm64" ;;
  *) die "unsupported architecture: $ARCH" ;;
esac
log "architecture $ARCH (tarball flavour: $TARBALL_ARCH)"

if [ -z "${SBCL_TARBALL_URL:-}" ]; then
  log "installing the distro sbcl"
  apt_ensure sbcl
else
  case "$SBCL_TARBALL_URL" in
    *"$TARBALL_ARCH"*) ok "tarball name matches $TARBALL_ARCH" ;;
    *) die "SBCL_TARBALL_URL does not contain '$TARBALL_ARCH' — refusing to install a mismatched build" ;;
  esac

  log "building sbcl from $SBCL_TARBALL_URL"
  apt_ensure build-essential
  work="$(mktemp -d)"
  wget -q -O "$work/sbcl.tar.bz2" "$SBCL_TARBALL_URL"
  tar -xjf "$work/sbcl.tar.bz2" -C "$work"
  src="$(find "$work" -maxdepth 1 -type d -name 'sbcl-*' | head -1)"
  [ -n "$src" ] || die "no sbcl-* directory in the tarball"
  ( cd "$src" && sh install.sh )
  rm -rf "$work"
fi

log "verification"
have sbcl || die "sbcl not on PATH after install"
sbcl --version
# a bare sbcl must survive a trivial eval: this is where a wrong-arch build dies
sbcl --non-interactive --eval '(princ (+ 1 1))' --quit | grep -q 2 \
  || die "sbcl installed but cannot evaluate — wrong architecture build?"
ok "sbcl runs"

log "done. Next: 04-install-app-user.sh"
