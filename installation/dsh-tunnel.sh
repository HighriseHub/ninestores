#!/bin/bash
#
# dsh-tunnel.sh — on-demand SSH tunnel to the DSH harness on the remote VM.
#
#   ./dsh-tunnel.sh            open the tunnel; ssh backgrounds itself, prompt returns
#   ./dsh-tunnel.sh status     is 3080 forwarded, and by what?
#   ./dsh-tunnel.sh stop       close the tunnel
#
# Then browse http://127.0.0.1:3080 on this machine.
#
# No retry loop, by design: run it when you need it. If the connection drops the
# tunnel closes and you re-run the script, typing the password once per run.
#
# Overrides:  REMOTE=ubuntu@host  LOCAL_PORT=3080  REMOTE_PORT=3080

set -u

REMOTE="${REMOTE:-ubuntu@ninestores.local}"
LOCAL_PORT="${LOCAL_PORT:-3080}"
REMOTE_PORT="${REMOTE_PORT:-3080}"
PATTERN="127.0.0.1:${LOCAL_PORT}:127.0.0.1:${REMOTE_PORT}"

# -f           : authenticate, then fork into the background and hand the prompt
#                back. ssh reads the password BEFORE forking, so you are still
#                prompted normally.
# -N -T        : no shell, no tty — this is a tunnel, nothing else
# ServerAlive* : probe every 30s, give up after 3 misses, so a dead link is noticed
#                in ~90s instead of hanging silently forever
# TCPKeepAlive : also probe at the TCP layer
# ExitOnForwardFailure : fail loudly at startup if the local port cannot be bound
# No BatchMode : you type the password, so ssh must be allowed to prompt
SSH_OPTS=(
  -f
  -N -T
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=3
  -o TCPKeepAlive=yes
  -o ExitOnForwardFailure=yes
  -o ConnectTimeout=10
  -L "127.0.0.1:${LOCAL_PORT}:127.0.0.1:${REMOTE_PORT}"
)

# Checks the local listener, which exists only while the forward is installed.
# Deliberately does NOT connect to the port: that would open a real channel to
# the harness on every check.
forwarded() { lsof -nP -iTCP:"$LOCAL_PORT" -sTCP:LISTEN >/dev/null 2>&1; }

case "${1:-connect}" in
  connect)
    if forwarded; then
      echo "port ${LOCAL_PORT} is already forwarded — nothing to do:"
      lsof -nP -iTCP:"$LOCAL_PORT" -sTCP:LISTEN
      exit 0
    fi
    echo "opening 127.0.0.1:${LOCAL_PORT} -> ${REMOTE}:${REMOTE_PORT}"
    if ssh "${SSH_OPTS[@]}" "$REMOTE"; then
      echo "tunnel up — '${0##*/} stop' to close"
    else
      echo "tunnel failed to open (ssh exit $?)" >&2
      exit 1
    fi
    ;;

  status)
    if forwarded; then
      echo "tunnel: UP"
      lsof -nP -iTCP:"$LOCAL_PORT" -sTCP:LISTEN
    else
      echo "tunnel: DOWN (nothing listening on 127.0.0.1:${LOCAL_PORT})"
      exit 1
    fi
    ;;

  stop)
    if pkill -f "$PATTERN"; then
      echo "tunnel killed"
    else
      echo "no tunnel running"
    fi
    ;;

  *)
    echo "usage: $0 [connect|status|stop]" >&2
    exit 2
    ;;
esac
