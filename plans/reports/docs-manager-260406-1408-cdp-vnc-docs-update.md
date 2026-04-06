# Docs Manager Report: Chrome CDP VNC Docker Image - Docs Update

**Date:** 2026-04-06
**Trigger:** Implementation complete, docs needed sync with actual code

## Changes Made

### `/docs/system-architecture.md` (86 -> 115 lines)
- **Added fluxbox** to architecture diagram and process flow (was missing entirely)
- **Added User Separation table** -- clarifies supervisord/root vs Chrome/chrome user split
- **Added `--no-sandbox` explanation** -- always required in Docker, not just CI
- **Added `--remote-allow-origins=*`** to Chrome flags in process flow (was missing)
- **Added all Chrome flags** to process flow (`--no-first-run`, `--disable-gpu`, `--disable-dev-shm-usage`)
- **Updated env vars table** -- added `DISPLAY` and `HOME`, clarified `VNC_PASSWORD` empty = `-nopw`
- **Added supervisord priority ordering** in process flow (10/15/20/30)
- **Added Docker Requirements section** -- platform, shm-size, base image, Chrome version
- **Removed `/var/log/supervisor/`** from directory structure (logs go to `/dev/fd/1` and `/dev/fd/2`)

### `/docs/project-overview-pdr.md` (43 -> 50 lines)
- **Added status header**: "Implemented (v1.0)", image size, base platform
- **Added "Status" column** to Key Features table -- all marked "Done"
- **Added "Window manager" feature row** (fluxbox)
- **Corrected Technical Constraints**:
  - "Must run as non-root user" -> precise description: supervisord as root, Chrome as chrome user
  - "`--no-sandbox` only in CI" -> always enabled (Docker limitation)
  - Added `--shm-size=2g` requirement
  - Added `--remote-allow-origins=*`
- **Changed Non-Goals**: removed "initially" from ARM64 (confirmed AMD64-only design)

### `/docs/code-standards.md` (40 -> 57 lines)
- **Dockerfile section**: added `--platform=linux/amd64`, uid/gid 1000, EXPOSE all three ports
- **Shell Scripts section**: added `exec` usage rule, `echo` logging rule
- **Configuration section**: added supervisord user split, headless config generation path
- **Security section**: corrected `--no-sandbox` (always, not "avoid when possible"), added `--remote-allow-origins=*`
- **Added Docker Runtime section**: shm-size, restart policy, extension/user-data paths
- **File Naming**: converted to table format with purposes

## Verified Against Code

All doc changes cross-referenced against these implementation files:
- `Dockerfile` -- base image, user creation, ENV vars, EXPOSE, COPY targets
- `supervisord.conf` -- user=root, user=chrome, priorities, environment=, fluxbox program
- `entrypoint.sh` -- env var defaults, headless config generation, mkdir, exec usage
- `chrome-launcher.sh` -- all Chrome flags including `--no-sandbox`, `--remote-allow-origins=*`
- `docker-compose.yml` -- ports, shm_size, env vars, restart policy

## Unresolved Questions

None.
