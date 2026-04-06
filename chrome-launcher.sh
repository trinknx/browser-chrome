#!/bin/bash
set -euo pipefail

echo "Starting Chrome..."

ARGS=(
    --remote-debugging-port="${CHROME_CDP_PORT}"
    --remote-debugging-address=127.0.0.1
    --remote-allow-origins=*
    --no-first-run
    --disable-gpu
    --disable-dev-shm-usage
    --no-sandbox
    --user-data-dir=/opt/chrome/user-data
)

# Headless mode
if [ "${RUN_HEADLESS}" = "true" ]; then
    ARGS+=(--headless=new)
fi

# Extension loading
if [ -n "${CHROME_EXTENSIONS}" ]; then
    # --disable-extensions-except bypasses developer mode requirement
    ARGS+=(--disable-extensions-except="${CHROME_EXTENSIONS}")
    ARGS+=(--load-extension="${CHROME_EXTENSIONS}")
    echo "Loading extensions: ${CHROME_EXTENSIONS}"
fi

echo "Chrome args: ${ARGS[*]}"
exec chrome-browser "${ARGS[@]}" ${CHROME_FLAGS:-}
