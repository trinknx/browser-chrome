FROM debian:bookworm-slim

ARG TARGETARCH

# Install common deps + browser (Chrome for amd64, Chromium for arm64)
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg2 ca-certificates \
    xvfb x11vnc fluxbox novnc supervisor \
    fonts-liberation libnss3 libxss1 \
    libasound2 libgtk-3-0 libgbm1 \
    && if [ "$TARGETARCH" = "amd64" ]; then \
       wget -q -O /tmp/google-chrome-key.pub \
         https://dl.google.com/linux/linux_signing_key.pub \
       && gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg \
         /tmp/google-chrome-key.pub \
       && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] \
         http://dl.google.com/linux/chrome/deb/ stable main" \
         > /etc/apt/sources.list.d/google-chrome.list \
       && apt-get update && apt-get install -y --no-install-recommends \
         google-chrome-stable \
       && rm -rf /tmp/google-chrome-key.pub; \
       ln -sf /usr/bin/google-chrome-stable /usr/bin/chrome-browser; \
    else \
       apt-get install -y --no-install-recommends chromium; \
       ln -sf /usr/bin/chromium /usr/bin/chrome-browser; \
    fi \
    && rm -rf /var/lib/apt/lists/*

# Create non-root chrome user
RUN groupadd --gid 1000 chrome \
    && useradd --uid 1000 --gid chrome --shell /bin/bash \
       --create-home chrome \
    && mkdir -p /opt/chrome/extensions /opt/chrome/user-data \
    && chown -R chrome:chrome /opt/chrome

# Copy scripts and configs
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /opt/bin/entrypoint.sh
COPY chrome-launcher.sh /opt/bin/chrome-launcher.sh

RUN chmod +x /opt/bin/entrypoint.sh /opt/bin/chrome-launcher.sh

# Environment variables with defaults
ENV DISPLAY=:99
ENV HOME=/home/chrome
ENV CHROME_CDP_PORT=9222
ENV VNC_PORT=5900
ENV NOVNC_PORT=6080
ENV RESOLUTION=1920x1080x24
ENV RUN_HEADLESS=false
ENV CHROME_FLAGS=""
ENV CHROME_EXTENSIONS=""
ENV VNC_PASSWORD=""

EXPOSE 9222 6080 5900

ENTRYPOINT ["/opt/bin/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
