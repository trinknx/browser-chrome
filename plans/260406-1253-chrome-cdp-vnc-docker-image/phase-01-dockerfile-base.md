# Phase 1: Dockerfile & Base Setup

## Context Links
- Research: `plans/reports/researcher-260406-1319-docker-chrome-cdp-vnc.md`
- Architecture: `docs/system-architecture.md`

## Overview
- **Priority:** P1
- **Status:** Complete
- Create Dockerfile with all dependencies installed, non-root user, and directory structure.

## Key Insights
- Combine RUN layers to reduce image size
- Install Chrome via Google's .deb repo
- noVNC from Debian repos (bookworm has it)
- Non-root user avoids `--no-sandbox` requirement

## Requirements
- Install Chrome stable, Xvfb, x11vnc, noVNC, fluxbox, supervisord
- Create non-root `chrome` user with home dir
- Create directory structure: `/opt/chrome/extensions`, `/opt/chrome/user-data`
- Set env vars with defaults
- EXPOSE CDP + noVNC ports

## Related Code Files
- **Create:** `Dockerfile`

## Implementation Steps

1. `FROM debian:bookworm-slim`
2. Install deps in single RUN layer: `wget gnupg2 xvfb x11vnc novnc fluxbox supervisor fonts-liberation libnss3 libxss1 libasound2t64 libgtk-3-0 libgbm1`
3. Add Google Chrome repo + install `google-chrome-stable`
4. Clean apt cache in same layer
5. Create `chrome` user (uid 1000), dirs `/opt/chrome/extensions`, `/opt/chrome/user-data`
6. Set ownership to `chrome` user
7. Copy scripts + configs (created in phases 2-3)
8. Set ENV defaults
9. EXPOSE ports
10. Set USER chrome, ENTRYPOINT, CMD

## Todo List
- [x] Write Dockerfile

## Success Criteria
- `docker build -t goclaw-browser .` succeeds
- Image size < 1.5GB
- Chrome binary at `/usr/bin/google-chrome-stable`

## Risk Assessment
- **Chrome repo key rotation:** Use latest key URL from Google
- **Missing lib deps:** `apt-cache depends google-chrome-stable` to verify

## Next Steps
- Phase 2 creates entrypoint scripts
