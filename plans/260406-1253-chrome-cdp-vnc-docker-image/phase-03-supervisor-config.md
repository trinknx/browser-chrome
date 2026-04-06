# Phase 3: Supervisord Config

## Context Links
- Architecture: `docs/system-architecture.md`

## Overview
- **Priority:** P1
- **Status:** Complete
- Create supervisord.conf to manage Xvfb, x11vnc, noVNC, and Chrome processes.

## Key Insights
- supervisord manages multiple processes in single container
- Process priority (start order): Xvfb → x11vnc → noVNC → Chrome
- Log to stdout/stderr for `docker logs` visibility
- Autorestart on crash for stability

## Requirements
- Xvfb starts first (priority 10)
- x11vnc starts after Xvfb (priority 20)
- noVNC starts after Xvfb (priority 20)
- Chrome starts last (priority 30)
- All processes autorestart
- Logs to /dev/stdout + /dev/stderr

## Related Code Files
- **Create:** `supervisord.conf`

## Implementation Steps

1. `[supervisord]` section: nodaemon=true, user=root, logfile=/dev/null, loglevel=info
2. `[supervisordctl]` section: no config needed (child of supervisord)
3. `[program:xvfb]`:
   - command: `Xvfb :99 -screen 0 ${RESOLUTION}`
   - priority: 10
   - autorestart: true
   - stdout_logfile: /dev/fd/1, stdout_logfile_maxbytes: 0
4. `[program:fluxbox]`:
   - command: `fluxbox -display :99`
   - priority: 15
   - autorestart: true
5. `[program:x11vnc]`:
   - command: build dynamically with port + display + optional password
   - priority: 20
   - Use shell wrapper for password flag: if VNC_PASSWORD set, use `-passwd ${VNC_PASSWORD}`
6. `[program:novnc]`:
   - command: use novnc_proxy or websockify pointing to localhost:${VNC_PORT}
   - priority: 20
   - listen on ${NOVNC_PORT}
7. `[program:chrome]`:
   - command: `/opt/bin/chrome-launcher.sh`
   - priority: 30
   - stopsignal: TERM, stopwaitsecs: 10
   - user: chrome
8. `[program:headless-chrome]` (conditional):
   - Only when RUN_HEADLESS=true
   - command: `/opt/bin/chrome-launcher.sh`
   - user: chrome

**Note:** Conditional programs handled in entrypoint.sh - generate supervisord.conf dynamically or use include with headless-specific override.

**Simplified approach:** Single chrome program. entrypoint.sh generates the supervisord config with only relevant programs based on RUN_HEADLESS.

## Todo List
- [x] Write supervisord.conf template
- [x] Update entrypoint.sh to generate config dynamically (or use sed/envsubst)

## Success Criteria
- All processes start in correct order
- `docker logs` shows all process output
- Chrome accessible via CDP and VNC

## Risk Assessment
- **Xvfb display race:** Use `startsecs=2` to ensure Xvfb ready before x11vnc
- **noVNC websockify:** Verify novnc_proxy path in bookworm package

## Next Steps
- Phase 4 creates docker-compose.yml and README
