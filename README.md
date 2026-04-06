# GoClaw Browser

Docker image: Google Chrome + CDP remote debugging + extension loading + VNC access.

## Quick Start

```bash
docker compose up -d
```

- **CDP:** http://localhost:9222
- **noVNC:** http://localhost:6080
- **VNC:** localhost:5900

## Features

- Chrome DevTools Protocol (CDP) on configurable port
- Load unpacked extensions via volume mount
- Browser-based VNC (noVNC) + traditional VNC client
- Headless mode for CI/automation
- Configurable resolution, ports, and Chrome flags

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CHROME_CDP_PORT` | `9222` | CDP WebSocket port |
| `VNC_PORT` | `5900` | VNC server port |
| `NOVNC_PORT` | `6080` | noVNC web client port |
| `RESOLUTION` | `1920x1080x24` | Xvfb screen geometry |
| `RUN_HEADLESS` | `false` | Skip Xvfb/VNC, run headless |
| `CHROME_FLAGS` | `""` | Extra Chrome flags |
| `CHROME_EXTENSIONS` | `""` | Comma-separated extension paths |
| `VNC_PASSWORD` | `""` | VNC auth (empty = no auth) |

## Extension Loading

1. Mount extension directory:
   ```bash
   docker run -d \
     -v ./my-extension:/opt/chrome/extensions/my-extension \
     -e CHROME_EXTENSIONS=/opt/chrome/extensions/my-extension \
     -p 9222:9222 -p 6080:6080 \
     --shm-size=2g \
     goclaw-browser
   ```

2. Multiple extensions (comma-separated):
   ```bash
   -e CHROME_EXTENSIONS=/opt/chrome/extensions/ext1,/opt/chrome/extensions/ext2
   ```

## CDP Usage Examples

### Puppeteer
```js
const browser = await puppeteer.connect({
  browserWSEndpoint: 'ws://localhost:9222/devtools/browser/<wsEndpoint>'
});
```

### Playwright
```js
const browser = await chromium.connectOverCDP('http://localhost:9222');
```

### Verify
```bash
curl http://localhost:9222/json/version
```

## Headless Mode (CI)

```bash
docker run -d \
  -e RUN_HEADLESS=true \
  -p 9222:9222 \
  --shm-size=2g \
  goclaw-browser
```

## Building from Source

```bash
docker build -t goclaw-browser .
```

## License

MIT
