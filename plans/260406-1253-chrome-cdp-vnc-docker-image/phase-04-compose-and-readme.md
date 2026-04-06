# Phase 4: Docker Compose & README

## Context Links
- Project overview: `docs/project-overview-pdr.md`

## Overview
- **Priority:** P2
- **Status:** Complete
- Create docker-compose.yml with example configs and comprehensive README.

## Related Code Files
- **Create:** `docker-compose.yml`
- **Create:** `README.md`

## Implementation Steps

### docker-compose.yml
1. Service `goclaw-browser`:
   - `build: .`
   - `image: goclaw-browser:latest`
   - Ports: `9222:9222` (CDP), `6080:6080` (noVNC), `5900:5900` (VNC)
   - Volumes: `./extensions:/opt/chrome/extensions` for extension loading
   - Env vars with defaults
   - `shm_size: 2gb` (Chrome needs large /dev/shm)
   - `restart: unless-stopped`
2. Add example profiles:
   - Default (headful + VNC)
   - Headless (CI mode)

### README.md
1. Project description + features
2. Quick start: `docker compose up -d`
3. Access URLs: CDP `http://localhost:9222`, noVNC `http://localhost:6080`
4. Environment variables table (all vars with defaults)
5. Extension loading guide (mount + CHROME_EXTENSIONS var)
6. CDP usage examples (Puppeteer, Playwright)
7. Headless mode section
8. Building from source
9. License

## Todo List
- [x] Write docker-compose.yml
- [x] Write README.md

## Success Criteria
- `docker compose up` starts container
- noVNC accessible at localhost:6080
- CDP endpoint returns version info at localhost:9222/json/version

## Next Steps
- Phase 5 builds and tests the image
