---
title: "Chrome CDP VNC Docker Image"
description: "Docker image with Chrome + CDP remote debugging + extension loading + VNC access"
status: complete
priority: P1
effort: 3h
tags: [infra, docker, chrome, cdp]
blockedBy: []
blocks: []
created: 2026-04-06
---

# Chrome CDP VNC Docker Image

## Overview

Build `goclaw-browser` Docker image: Chrome + CDP remote debugging on custom port + arbitrary extension loading + VNC via Xvfb/noVNC. All config via env vars.

## Phases

| Phase | Name | Status | Progress |
|-------|------|--------|----------|
| 1 | [Dockerfile & Base Setup](./phase-01-dockerfile-base.md) | Complete | 100% |
| 2 | [Entrypoint & Chrome Launcher](./phase-02-entrypoint-scripts.md) | Complete | 100% |
| 3 | [Supervisor Config](./phase-03-supervisor-config.md) | Complete | 100% |
| 4 | [Docker Compose & README](./phase-04-compose-and-readme.md) | Complete | 100% |
| 5 | [Build & Test](./phase-05-build-test.md) | Complete | 100% |

## Key Decisions

- **Base:** `debian:bookworm-slim` (glibc native, apt .deb install)
- **Process mgmt:** supervisord (proven in SeleniumHQ docker-selenium)
- **VNC stack:** Xvfb + x11vnc + noVNC
- **Security:** Non-root user `chrome`, no `--no-sandbox` by default
- **Extension loading:** `--load-extension` with comma-separated paths

## Dependencies

- Google Chrome stable (.deb)
- Xvfb, x11vnc, noVNC, fluxbox, supervisord
- Research report: `plans/reports/researcher-260406-1319-docker-chrome-cdp-vnc.md`
