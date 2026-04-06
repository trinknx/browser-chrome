# Code Standards

## Dockerfile

- Use `debian:bookworm-slim` as base with `--platform=linux/amd64`
- Single-stage build (no multi-stage needed)
- Combine RUN layers to reduce image size (deps + Chrome install + cleanup in one layer)
- Clean apt cache in same RUN layer as install (`rm -rf /var/lib/apt/lists/*`)
- Use COPY for local files, never ADD for remote URLs
- Set ENV for all configurable variables with defaults
- Create `chrome` user (uid/gid 1000) for non-root Chrome process
- EXPOSE all three ports: 9222 (CDP), 5900 (VNC), 6080 (noVNC)

## Shell Scripts

- Use `#!/bin/bash` shebang
- `set -euo pipefail` in all scripts
- Quote all variable expansions (`"${VAR}"`)
- Use meaningful env var names (UPPER_SNAKE_CASE)
- Validate required env vars with defaults via `${VAR:-default}`
- Log startup info with `echo` before launching processes
- Use `exec` for final process to replace shell (proper signal handling)

## Configuration

- All runtime config via environment variables
- Provide sensible defaults in both Dockerfile ENV and entrypoint.sh
- Document all env vars in README and docker-compose example
- Use supervisord for multi-process management
- Supervisord runs as root (`user=root`); Chrome program runs as `user=chrome`
- Headless mode generates a minimal supervisord config at `/tmp/supervisord-headless.conf`

## Security

- Chrome process runs as `chrome` user (uid 1000) via supervisord `user=chrome`
- `--no-sandbox` is always enabled (required in Docker -- user namespaces unavailable)
- Never hardcode secrets
- CDP port internal by default, explicit `-p` mapping needed
- VNC password optional via `VNC_PASSWORD` env var (no auth when empty)
- `--remote-allow-origins=*` enabled for CDP access (tighten in production)

## Docker Runtime

- `--shm-size=2g` required (Chrome crashes without sufficient shared memory)
- Use `restart: unless-stopped` in docker-compose
- Extension directory: mount to `/opt/chrome/extensions`
- User data: `/opt/chrome/user-data` (ephemeral by default)

## File Naming

| File | Purpose |
|------|---------|
| `Dockerfile` | Main image definition |
| `docker-compose.yml` | Compose example with all options |
| `supervisord.conf` | Process management (Xvfb, fluxbox, x11vnc, noVNC, Chrome) |
| `entrypoint.sh` | Container entry point, headless/headful mode selection |
| `chrome-launcher.sh` | Chrome launch with all flags and extensions |
