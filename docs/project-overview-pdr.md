# GoClaw Browser - Product Development Requirements

**Status:** Implemented (v1.0)
**Image size:** ~1.68GB
**Base:** debian:bookworm-slim / linux/amd64

## Overview

Docker image providing Google Chrome with CDP remote debugging, arbitrary extension loading, and VNC access via virtual framebuffer.

## Goals

1. **CDP Remote Debugging** - Customizable WebSocket port for Chrome DevTools Protocol
2. **Extension Support** - Load any unpacked Chrome extension via volume mount
3. **VNC Access** - Visual access to browser via Xvfb + noVNC (browser-based) or traditional VNC client
4. **Configurable** - All settings via environment variables

## Non-Goals

- Selenium/WebDriver integration
- Multi-browser support
- Chrome Web Store programmatic installation
- ARM64 support (AMD64 only)

## Target Users

- Developers debugging browser extensions
- QA teams running automated tests with visual feedback
- CDP/Puppeteer/Playwright users needing remote Chrome

## Key Features

| Feature | Description | Status |
|---------|-------------|--------|
| Custom CDP port | Configurable via `CHROME_CDP_PORT` env var | Done |
| Extension loading | Mount unpacked extensions, auto-load via `--load-extension` | Done |
| VNC viewer | noVNC on configurable port, traditional VNC client support | Done |
| Headless toggle | `RUN_HEADLESS=true` skips Xvfb/VNC for CI | Done |
| Resolution control | `RESOLUTION` env var for Xvfb geometry | Done |
| VNC password | Optional auth via `VNC_PASSWORD` | Done |
| Window manager | fluxbox for proper window management in VNC | Done |

## Technical Constraints

- supervisord runs as root (PID 1, process management); Chrome process runs as `chrome` user (uid 1000) via supervisord `user=chrome` directive
- `--no-sandbox` is always enabled -- required for Chrome in Docker even as non-root (user namespaces unavailable in default Docker runtime)
- `--shm-size=2g` required when running container (Chrome shared memory needs)
- CDP port should not be exposed publicly without auth
- Container is stateless -- all data via volumes
- `--remote-allow-origins=*` enabled for cross-origin CDP access
