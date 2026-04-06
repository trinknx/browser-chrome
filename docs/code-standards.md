# Code Standards

## Dockerfile

- Use `debian:bookworm-slim` as base
- Multi-stage builds not needed (single-stage sufficient)
- Combine RUN layers to reduce image size
- Clean apt cache in same RUN layer as install
- Use COPY for local files, never ADD for remote URLs

## Shell Scripts

- Use `#!/bin/bash` shebang
- `set -euo pipefail` in all scripts
- Quote all variable expansions
- Use meaningful env var names (UPPER_SNAKE_CASE)
- Validate required env vars with defaults via `${VAR:-default}`

## Configuration

- All runtime config via environment variables
- Provide sensible defaults
- Document all env vars in README and docker-compose example
- Use supervisord for multi-process management

## Security

- Run as non-root user (`chrome`)
- Avoid `--no-sandbox` when possible
- Never hardcode secrets
- CDP port internal by default, explicit mapping needed

## File Naming

- `Dockerfile` - main image definition
- `docker-compose.yml` - compose example
- `supervisord.conf` - process management config
- `entrypoint.sh` - container entry point
- `chrome-launcher.sh` - Chrome start script
