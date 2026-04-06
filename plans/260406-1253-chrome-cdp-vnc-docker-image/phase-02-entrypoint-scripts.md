# Phase 2: Entrypoint & Chrome Launcher Scripts

## Context Links
- Architecture: `docs/system-architecture.md`

## Overview
- **Priority:** P1
- **Status:** Complete
- Create entrypoint.sh and chrome-launcher.sh with env var parsing and flag construction.

## Key Insights
- `set -euo pipefail` for robust shell scripts
- Extensions must load before CDP targets are created
- Headless mode skips Xvfb/VNC entirely
- `--remote-debugging-address=0.0.0.0` required for container access

## Requirements
- Parse env vars with sensible defaults
- Construct Chrome flags dynamically
- Support comma-separated extension paths
- Toggle headless vs headful based on `RUN_HEADLESS`

## Related Code Files
- **Create:** `entrypoint.sh`
- **Create:** `chrome-launcher.sh`

## Implementation Steps

### entrypoint.sh
1. Shebang + `set -euo pipefail`
2. Parse env vars:
   - `CHROME_CDP_PORT` (default: 9222)
   - `VNC_PORT` (default: 5900)
   - `NOVNC_PORT` (default: 6080)
   - `RESOLUTION` (default: 1920x1080x24)
   - `RUN_HEADLESS` (default: false)
   - `CHROME_FLAGS` (default: "")
   - `CHROME_EXTENSIONS` (default: "")
   - `VNC_PASSWORD` (default: "")
3. If `RUN_HEADLESS=true`: export `HEADLESS_MODE=true`, skip Xvfb setup
4. If not headless: set DISPLAY, write display num to file
5. Create Chrome user-data dir if missing
6. Exec `supervisord` with config

### chrome-launcher.sh
1. Build Chrome command:
   ```
   google-chrome-stable \
     --remote-debugging-port=${CHROME_CDP_PORT} \
     --remote-debugging-address=0.0.0.0 \
     --remote-allow-origins=* \
     --no-first-run \
     --disable-gpu \
     --disable-dev-shm-usage
   ```
2. If `RUN_HEADLESS=true`: add `--headless=new`
3. If `CHROME_EXTENSIONS` set: add `--load-extension=${CHROME_EXTENSIONS}`
4. Append `CHROME_FLAGS` if set
5. Add `--user-data-dir=/opt/chrome/user-data`
6. Exec chrome with all flags

## Todo List
- [x] Write entrypoint.sh
- [x] Write chrome-launcher.sh

## Success Criteria
- Scripts parse all env vars correctly
- Chrome starts with correct flags
- Headless mode skips display setup

## Risk Assessment
- **Flag escaping:** Keep CHROME_FLAGS simple (space-separated)
- **Extension path validation:** Chrome silently ignores missing extension paths

## Next Steps
- Phase 3 creates supervisord config
