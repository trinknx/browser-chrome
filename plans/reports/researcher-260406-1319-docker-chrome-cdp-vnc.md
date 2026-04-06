# Research Report: Docker Chrome + CDP + Extensions + VNC

**Date:** 2026-04-06
**Topic:** Best practices for building a Docker image running Chrome with CDP, extension loading, and VNC

---

## 1. Base Image Recommendation

**Ranked Choice: `debian:bookworm-slim`**

| Image | Size | Chrome Support | Verdict |
|-------|------|----------------|---------|
| `debian:bookworm-slim` | ~80MB | Full .deb install, glibc native | **Best** |
| `ubuntu:22.04` | ~77MB | Same as Debian, more bloat | OK but unnecessary |
| `alpine` | ~3MB | Requires chromium (not Chrome), gcompat issues | Avoid for Chrome |

Alpine uses musl libc; Chrome binaries are glibc-linked. The gcompat shim introduces subtle breakage. Debian slim gives native glibc + apt for `.deb` install with minimal overhead.

## 2. Headless vs Headful Mode

**Both are needed. Use env var toggle.**

| Dimension | Headless (`--headless=new`) | Headful + Xvfb |
|-----------|---------------------------|-----------------|
| Extensions | Limited support (no UI-dependent) | **Full support** |
| VNC needed | No | Yes |
| Performance | Faster, lower memory | Higher overhead |
| Use case | Automated scraping/testing | Interactive debugging, extension dev |

Chrome 112+ `--headless=new` uses the full Chrome platform (not the old headless mode). But extensions with popup UI or content scripts depending on rendering still require headful mode. **For extension support, default to headful+Xvfb.**

Key flags:
```
--headless=new          # Headless mode (Chrome 112+)
--no-first-run          # Skip first-run UI
--disable-gpu           # GPU not available in Docker
--no-sandbox            # Required when running as root (security trade-off)
--disable-dev-shm-usage # Avoid /dev/shm size issues in Docker
```

## 3. Chrome Extension Installation

**Ranked approach: `--load-extension` flag (unpacked)**

| Method | Works in Docker | Persistence | Difficulty |
|--------|----------------|-------------|------------|
| `--load-extension=/path` | **Yes** | Volume mount survives restarts | Easy |
| Chrome Web Store install | Requires interactive UI | Tied to user profile | Hard |
| `.crx` file drag-install | Deprecated in Chrome 95+ | Unreliable | Avoid |

For unpacked extensions, mount the extension directory and pass:
```
--load-extension=/opt/chrome/extensions/my-extension
```

Multiple extensions: comma-separated paths:
```
--load-extension=/ext1,/ext2,/ext3
```

**Caveat:** Extensions must load before CDP targets are created. Start Chrome with extensions, then connect CDP. Extensions are NOT available in old headless mode; `--headless=new` has limited support.

Native messaging hosts (if needed): place manifest at `/etc/opt/chrome/native-messaging-hosts/` (system) or `~/.config/google-chrome/NativeMessagingHosts/` (user).

## 4. CDP Configuration

**Recommended flags:**
```
--remote-debugging-port=9222
--remote-debugging-address=0.0.0.0
--remote-allow-origins=*
```

**CDP HTTP Endpoints:**
| Endpoint | Purpose |
|----------|---------|
| `GET /json/version` | Chrome version + WebSocket URL |
| `GET /json/list` | All active targets |
| `GET /json/new?{url}` | Open new tab |
| `GET /json/activate/{targetId}` | Focus tab |
| `GET /json/close/{targetId}` | Close tab |

**WebSocket:** `ws://host:9222/devtools/page/{targetId}` for direct CDP session.

Multiple CDP clients supported since Chrome 63. Use `--remote-allow-origins=*` to avoid CORS issues in containerized setups (or specify exact origins for production).

**Port auto-assign:** `--remote-debugging-port=0` lets Chrome pick a port, written to `DevToolsActivePort` file. Not recommended for containers -- use a fixed port.

## 5. VNC / Xvfb Setup

**Ranked Choice: Xvfb + x11vnc + noVNC**

| Component | Purpose | Alt |
|-----------|---------|-----|
| Xvfb | Virtual framebuffer (virtual display) | Xdummy (same, less common) |
| x11vnc | VNC server sharing the Xvfb display | TigerVNC (heavier) |
| noVNC | Browser-based VNC client (no install needed) | Traditional VNC client |

**Display chain:** `Xvfb :99 -screen 0 1920x1080x24` -> `x11vnc -display :99` -> `noVNC on port 6080`

**noVNC deployment parameters:**
- `autoconnect=true` - skip connect button
- `host`, `port` - VNC server address
- `encrypt` - WSS support
- `password` - VNC auth
- `view_only` - read-only mode
- `resize=scale` - auto-scale to browser window

**Important:** noVNC requires `Cache-Control: no-cache` header for proper serving. Configure in reverse proxy or noVNC's built-in web server.

## 6. Existing Projects (Reference Implementations)

| Project | Stars | Approach | Worth studying |
|---------|-------|----------|---------------|
| SeleniumHQ/docker-selenium | 8k+ | Full Selenium grid, supervisord, fluxbox | **Yes - production patterns** |
| browserless/browserless | 8k+ | Headless Chrome as a service, CDP-first | Yes - CDP patterns |
| selenium/standalone-chrome | Official | Single-container Chrome + VNC | Yes - simplest VNC setup |

**SeleniumHQ patterns adopted:**
- `supervisord` for multi-process management (Chrome, Xvfb, VNC)
- `fluxbox` as lightweight window manager
- Non-root user (`seluser`) for security
- Chrome binary wrapper at `/opt/bin/wrap_chrome_binary` for cleanup
- Chrome for Testing (`CFT`) variant support

## 7. Security Considerations

| Risk | Mitigation |
|------|-----------|
| `--no-sandbox` required as root | Run as non-root user instead |
| CDP exposes full browser control | Bind to `127.0.0.1` or use auth proxy |
| VNC has no encryption | Use noVNC with WSS or SSH tunnel |
| Extensions can be malicious | Validate extension sources, use read-only mounts |
| Container escape via Chrome | Drop capabilities, use `--security-opt seccomp` |

**Recommendation:** Run Chrome as non-root user. If `--no-sandbox` is needed (CI), accept the trade-off but never expose CDP port publicly.

## 8. Dockerfile Pattern (Recommended)

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    wget gnupg2 xvfb x11vnc fluxbox novnc \
    supervisor fonts-liberation libnss3 \
    libxss1 libasound2t64 libgtk-3-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub \
    | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /opt/bin/entrypoint.sh

ENV DISPLAY=:99
ENV CHROME_CDP_PORT=9222
ENV VNC_PORT=5900
ENV NOVNC_PORT=6080
ENV CHROME_FLAGS=""
ENV CHROME_EXTENSIONS=""

EXPOSE ${CHROME_CDP_PORT} ${NOVNC_PORT}

ENTRYPOINT ["/opt/bin/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

## 9. Environment Variable Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `DISPLAY` | `:99` | Xvfb display |
| `CHROME_CDP_PORT` | `9222` | CDP WebSocket port |
| `VNC_PORT` | `5900` | x11vnc port |
| `NOVNC_PORT` | `6080` | noVNC web client port |
| `CHROME_FLAGS` | `""` | Extra Chrome flags |
| `CHROME_EXTENSIONS` | `""` | Comma-separated extension paths |
| `RESOLUTION` | `1920x1080x24` | Xvfb screen geometry |
| `RUN_HEADLESS` | `false` | Toggle headless mode |
| `VNC_PASSWORD` | (none) | VNC auth password |

**Entrypoint logic:** If `RUN_HEADLESS=true`, skip Xvfb/VNC and use `--headless=new`. Otherwise start Xvfb, x11vnc, noVNC via supervisord, then Chrome with `--remote-debugging-port` and `--load-extension` from env vars.

---

## Limitations

- Did not benchmark memory/CPU for headless vs headful+Xvfb (project-specific)
- Did not test Chrome for Testing vs google-chrome-stable compatibility differences
- Did not evaluate ARM64/aarch64 Chrome availability (Intel/AMD64 assumed)
- Extension installation from Chrome Web Store programmatically not covered (OAuth complexity)

## Sources

1. Chrome DevTools Protocol docs - chromedevtools.github.io
2. Chrome headless blog - developer.chrome.com/articles/headless
3. SeleniumHQ docker-selenium Dockerfile (production reference)
4. noVNC deployment docs - novnc.com
5. Chrome native messaging docs - developer.chrome.com
