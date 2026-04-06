# Phase 5: Build & Test

## Context Links
- All previous phases

## Overview
- **Priority:** P1
- **Status:** Complete
- Build Docker image and validate all features work.

## Requirements
- Image builds without errors
- Chrome starts with CDP on custom port
- Extensions load when mounted
- VNC/noVNC accessible
- Headless mode works

## Implementation Steps

1. Build image: `docker build -t goclaw-browser .`
2. Test CDP access:
   ```bash
   docker run -d --name test -p 9222:9222 goclaw-browser
   curl http://localhost:9222/json/version  # Should return Chrome version JSON
   ```
3. Test noVNC access:
   ```bash
   curl -s http://localhost:6080/vnc.html | head -5  # Should return noVNC page
   ```
4. Test extension loading:
   ```bash
   docker run -d --name test-ext \
     -v ./test-extension:/opt/chrome/extensions/test-ext \
     -e CHROME_EXTENSIONS=/opt/chrome/extensions/test-ext \
     -p 9223:9222 goclaw-browser
   # Check chrome://extensions via CDP
   ```
5. Test headless mode:
   ```bash
   docker run -d --name test-headless \
     -e RUN_HEADLESS=true \
     -p 9224:9222 goclaw-browser
   curl http://localhost:9224/json/version
   ```
6. Test custom CDP port:
   ```bash
   docker run -d --name test-port \
     -e CHROME_CDP_PORT=9333 \
     -p 9333:9333 goclaw-browser
   curl http://localhost:9333/json/version
   ```
7. Cleanup: `docker rm -f test test-ext test-headless test-port`

## Todo List
- [x] Build image
- [x] Test CDP endpoint
- [x] Test noVNC endpoint
- [x] Test extension loading
- [x] Test headless mode
- [x] Test custom port

## Success Criteria
- All 6 test scenarios pass
- No errors in `docker logs`
- Image size < 1.5GB

## Risk Assessment
- **Docker not available:** Skip build if Docker daemon not running
- **Network issues:** Chrome startup may take 3-5s, add sleep before curl
