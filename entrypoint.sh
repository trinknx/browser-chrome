#!/bin/bash
set -euo pipefail

# Parse env vars with defaults
export CHROME_CDP_PORT="${CHROME_CDP_PORT:-9222}"
export VNC_PORT="${VNC_PORT:-5900}"
export NOVNC_PORT="${NOVNC_PORT:-6080}"
export RESOLUTION="${RESOLUTION:-1920x1080x24}"
export RUN_HEADLESS="${RUN_HEADLESS:-false}"
export CHROME_FLAGS="${CHROME_FLAGS:-}"
export CHROME_EXTENSIONS="${CHROME_EXTENSIONS:-}"
export VNC_PASSWORD="${VNC_PASSWORD:-}"

echo "=== GoClaw Browser ==="
echo "CDP Port: ${CHROME_CDP_PORT}"
echo "Headless: ${RUN_HEADLESS}"

# Create user-data dir if missing
mkdir -p /opt/chrome/user-data

if [ "${RUN_HEADLESS}" = "true" ]; then
    echo "Mode: headless (skipping Xvfb/VNC)"
    # Generate headless supervisord config (only chrome program)
    cat > /tmp/supervisord-headless.conf <<EOF
[supervisord]
nodaemon=true
logfile=/dev/null
loglevel=info

[program:chrome]
command=/opt/bin/chrome-launcher.sh
priority=10
autorestart=true
stopsignal=TERM
stopwaitsecs=10
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
user=chrome
environment=HOME="/home/chrome"

[program:cdp-forward]
command=/opt/bin/cdp-forward.sh
priority=15
autorestart=true
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF
    exec supervisord -c /tmp/supervisord-headless.conf
else
    echo "Mode: headful (Xvfb + VNC)"
    export DISPLAY=":99"
    exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
fi
