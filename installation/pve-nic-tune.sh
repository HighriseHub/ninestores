#!/bin/bash
#
# pve-nic-tune.sh
#
# Intel I218-V (e1000e) "Detected Hardware Unit Hang" workaround.
# Apply / revert / status for the offload + EEE settings on a Proxmox host.
#
# Run as root ON THE PROXMOX HOST (pve), never inside a VM.
#
#   ./pve-nic-tune.sh status     # what is set right now + hang count since baseline
#   ./pve-nic-tune.sh apply      # offloads off, EEE off, install + enable unit
#   ./pve-nic-tune.sh revert     # back to stock: offloads on, unit removed
#
# Original stock state of this chip, captured before any change:
#   tcp-segmentation-offload:     on
#   generic-segmentation-offload: on
#   generic-receive-offload:      on
#   (rx-checksumming, tx-checksumming, scatter-gather, highdma: on [fixed] - never touched)
#
# EEE was never captured before it was switched off, so REVERT assumes it was on.
# If you know it was off, run:  EEE_ORIGINAL=off ./pve-nic-tune.sh revert
#
# Override the interface if needed:  IFACE=enp1s0 ./pve-nic-tune.sh status

set -u

IFACE="${IFACE:-enp0s25}"
EEE_ORIGINAL="${EEE_ORIGINAL:-on}"
UNIT=/etc/systemd/system/nic-tune.service
STAMP=/root/.nic-tune-baseline
ETHTOOL=/usr/sbin/ethtool

die() { echo "ERROR: $*" >&2; exit 1; }

preflight() {
  [ "$(id -u)" -eq 0 ]                     || die "must run as root"
  [ -x "$ETHTOOL" ]                        || die "$ETHTOOL not found (apt install ethtool)"
  [ -d "/sys/class/net/$IFACE" ]           || die "interface $IFACE not present (try: ip -br link; then IFACE=... $0 $1)"
  command -v systemctl >/dev/null          || die "systemctl not found - is this really the Proxmox host?"
}

show_state() {
  echo "=== offloads on $IFACE ==="
  "$ETHTOOL" -k "$IFACE" 2>/dev/null \
    | grep -E "^(tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload):"
  echo
  echo "=== EEE on $IFACE ==="
  "$ETHTOOL" --show-eee "$IFACE" 2>/dev/null | grep -E "EEE status" || echo "(EEE not queryable on this chip)"
  echo
  echo "=== systemd unit ==="
  if [ -f "$UNIT" ]; then
    echo "file:    $UNIT (present)"
    echo "enabled: $(systemctl is-enabled nic-tune.service 2>&1)"
    echo "active:  $(systemctl is-active nic-tune.service 2>&1)"
  else
    echo "file:    absent (settings are live-only, will reset on reboot)"
  fi
  echo
  echo "=== e1000e hardware unit hangs ==="
  if [ -f "$STAMP" ]; then
    since=$(cat "$STAMP")
    n=$(journalctl -k --since "$since" -g "Hardware Unit Hang" --no-pager 2>/dev/null | wc -l)
    echo "since $since : $n message(s)"
    if [ "$n" -gt 0 ]; then
      echo "most recent:"
      journalctl -k --since "$since" -g "Hardware Unit Hang" --no-pager 2>/dev/null | tail -3
    fi
  else
    echo "(no baseline recorded - run 'apply' to set one, or: date > $STAMP)"
  fi
}

apply_fix() {
  echo "--- switching offloads off on $IFACE ---"
  "$ETHTOOL" -K "$IFACE" tso off gso off gro off || die "could not change offloads"

  echo "--- switching EEE off ---"
  "$ETHTOOL" --set-eee "$IFACE" eee off 2>/dev/null \
    || echo "note: EEE not settable on this chip - harmless, offloads are the important part"

  echo "--- installing $UNIT ---"
  cat > "$UNIT" <<EOF
[Unit]
Description=Tune $IFACE (e1000e hardware unit hang workaround)
After=sys-subsystem-net-devices-$IFACE.device
Wants=sys-subsystem-net-devices-$IFACE.device

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$ETHTOOL -K $IFACE tso off gso off gro off
ExecStart=$ETHTOOL --set-eee $IFACE eee off

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now nic-tune.service || die "could not enable nic-tune.service"

  date '+%Y-%m-%d %H:%M:%S' > "$STAMP"
  echo
  echo "applied. baseline recorded: $(cat "$STAMP")"
  echo "verify after a reboot with: $0 status"
}

revert_fix() {
  echo "--- removing systemd unit ---"
  systemctl disable --now nic-tune.service >/dev/null 2>&1 || true
  rm -f "$UNIT"
  systemctl daemon-reload

  echo "--- restoring stock offloads (tso/gso/gro on) ---"
  "$ETHTOOL" -K "$IFACE" tso on gso on gro on || die "could not restore offloads"

  echo "--- restoring EEE ($EEE_ORIGINAL) ---"
  "$ETHTOOL" --set-eee "$IFACE" eee "$EEE_ORIGINAL" 2>/dev/null \
    || echo "note: EEE not settable on this chip - nothing to restore"

  rm -f "$STAMP"
  echo
  echo "reverted to stock. verify with: $0 status"
}

case "${1:-status}" in
  status) preflight "status"; show_state ;;
  apply)  preflight "apply";  apply_fix ;;
  revert) preflight "revert"; revert_fix ;;
  *) echo "usage: $0 {status|apply|revert}" >&2; exit 2 ;;
esac
