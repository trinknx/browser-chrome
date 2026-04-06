# System Architecture

## Container Architecture

```
┌──────────────────────────────────────────────────────────┐
│                        Container                          │
│                                                           │
│  ┌──────────────┐  ┌────────────┐  ┌──────────────────┐ │
│  │   Xvfb :99   │  │  fluxbox   │  │  Google Chrome   │ │
│  │  1920x1080x24│◄─┤  (window   │◄─┤  --remote-debug  │ │
│  │              │  │  manager)  │  │  --load-ext      │ │
│  └──────┬───────┘  └───────────┘  │  --no-sandbox     │ │
│         │                         └────────┬─────────┘ │
│  ┌──────▼───────┐                          │             │
│  │   x11vnc     │                          │             │
│  │   :5900      │                          │             │
│  └──────┬───────┘                          │             │
│         │                                  │             │
│  ┌──────▼───────┐              ┌───────────▼─────────┐  │
│  │   noVNC      │              │    CDP :9222        │  │
│  │   :6080      │              │    ws://...         │  │
│  └──────────────┘              └─────────────────────┘  │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐ │
│  │   supervisord (PID 1, runs as root)                 │ │
│  │   manages: Xvfb, fluxbox, x11vnc, noVNC, Chrome    │ │
│  │   Chrome process runs as user=chrome (uid 1000)     │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
         │                │              │
     Host:6080       Host:5900      Host:9222
     (noVNC)         (VNC)         (CDP)
```

### User Separation

| Process | User | Why |
|---------|------|-----|
| supervisord | root | Needs to manage processes, own PID 1 |
| Xvfb, fluxbox, x11vnc, noVNC | root | Display/VNC infrastructure |
| Google Chrome | chrome (uid 1000) | Security isolation for browser |

`--no-sandbox` is required for Chrome in Docker even when running as non-root, because Chrome's sandbox requires user namespaces not available in default Docker config.

## Process Flow

```
entrypoint.sh (PID 1 handler)
  ├─ Parse env vars with defaults
  ├─ mkdir -p /opt/chrome/user-data
  ├─ If RUN_HEADLESS=true:
  │   └─ Generate /tmp/supervisord-headless.conf (chrome only)
  │       └─ exec supervisord -c headless.conf
  └─ If RUN_HEADLESS=false (default):
      └─ exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
          ├─ [priority 10] Xvfb :99 -screen 0 $RESOLUTION
          ├─ [priority 15] fluxbox -display :99
          ├─ [priority 20] x11vnc -display :99 -rfbport $VNC_PORT
          ├─ [priority 20] websockify (noVNC proxy to $VNC_PORT)
          └─ [priority 30] chrome-launcher.sh (user=chrome)
              ├─ --remote-debugging-port=$CHROME_CDP_PORT
              ├─ --remote-debugging-address=0.0.0.0
              ├─ --remote-allow-origins=*
              ├─ --no-first-run --disable-gpu --disable-dev-shm-usage
              ├─ --no-sandbox --user-data-dir=/opt/chrome/user-data
              ├─ --headless=new (if RUN_HEADLESS=true)
              ├─ --load-extension=$CHROME_EXTENSIONS (if set)
              └─ $CHROME_FLAGS (extra user flags)
```

## Directory Structure

```
/opt/chrome/
  ├── extensions/       # Mounted extension directories
  └── user-data/        # Chrome user data (volume)
/etc/supervisor/
  └── conf.d/
      └── supervisord.conf
/opt/bin/
  ├── entrypoint.sh     # Container entrypoint, selects headless/headful
  └── chrome-launcher.sh # Chrome launch with all flags
/home/chrome/           # HOME dir for chrome user (set via ENV + supervisord)
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DISPLAY` | `:99` | X11 display (set by Dockerfile ENV) |
| `HOME` | `/home/chrome` | Chrome user home (ENV + supervisord) |
| `CHROME_CDP_PORT` | `9222` | CDP WebSocket port |
| `VNC_PORT` | `5900` | VNC server port |
| `NOVNC_PORT` | `6080` | noVNC web client port |
| `RESOLUTION` | `1920x1080x24` | Xvfb screen geometry |
| `RUN_HEADLESS` | `false` | Skip Xvfb/VNC, run Chrome headless |
| `CHROME_FLAGS` | `""` | Extra Chrome flags appended to launch |
| `CHROME_EXTENSIONS` | `""` | Comma-separated extension paths |
| `VNC_PASSWORD` | `""` | VNC auth (empty = `-nopw`, no auth) |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 9222 | HTTP/WS | CDP remote debugging |
| 5900 | VNC | Traditional VNC access |
| 6080 | HTTP | noVNC browser client |

## Docker Requirements

- `--platform=linux/amd64` (AMD64 only, no ARM64)
- `--shm-size=2g` (Chrome needs shared memory)
- Base image: `debian:bookworm-slim`
- Chrome version: google-chrome-stable (currently 146.x)
