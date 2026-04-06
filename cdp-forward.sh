#!/bin/bash
set -euo pipefail

PORT="${CHROME_CDP_PORT:-9222}"

# Wait for Chrome to start listening on loopback
for i in $(seq 1 60); do
    if netstat -tlnp 2>/dev/null | grep -qE "127\.0\.0\.1:${PORT}\b"; then
        echo "CDP forward: detected Chrome on IPv4 127.0.0.1:${PORT}"
        exec socat TCP-LISTEN:${PORT},fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:${PORT}
    fi
    if netstat -tlnp 2>/dev/null | grep -qE "::1:${PORT}\b"; then
        echo "CDP forward: detected Chrome on IPv6 ::1:${PORT}"
        exec socat TCP-LISTEN:${PORT},fork,reuseaddr,bind=0.0.0.0 TCP6:[::1]:${PORT}
    fi
    sleep 0.5
done

echo "CDP forward: ERROR - Chrome did not start on port ${PORT} within 30s"
exit 1
