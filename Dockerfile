FROM ubuntu:22.04

# Build arguments for broker configuration
ARG BROKER=metaquotes
ARG MT5_INSTALLER_URL=""

# Metadata labels
LABEL maintainer="XQuantify <support@xquantify.com>"
LABEL com.xquantify.project="tradestation"
LABEL com.xquantify.component="mt5-instance"
LABEL com.xquantify.version="1.0.0"
LABEL description="XQuantify TradeStation - Professional MetaTrader 5 deployment platform"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    VNC_PORT=5901 \
    NOVNC_PORT=6080 \
    WINE_PREFIX=/home/mt5user/.wine \
    WINEARCH=win64

# Install system dependencies in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    xvfb \
    x11vnc \
    fluxbox \
    supervisor \
    nodejs \
    npm \
    git \
    unzip \
    jq \
    cabextract \
    && rm -rf /var/lib/apt/lists/*

# Install Wine (optimized with single layer)
RUN dpkg --add-architecture i386 \
    && mkdir -pm755 /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
    && wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends winehq-stable winetricks \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC (pinned to specific version for caching)
RUN git clone --depth 1 --branch v1.4.0 https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone --depth 1 https://github.com/novnc/websockify /opt/novnc/utils/websockify \
    && chmod +x /opt/novnc/utils/novnc_proxy

# Create user for MT5
RUN useradd -m -s /bin/bash mt5user \
    && usermod -aG sudo mt5user \
    && echo "mt5user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to mt5user
USER mt5user
WORKDIR /home/mt5user

# Initialize Wine prefix (this takes time, so it's cached)
# Run with Xvfb to avoid display errors during build
RUN export DISPLAY=:99 \
    && Xvfb :99 -screen 0 1024x768x16 & \
    XVFB_PID=$! \
    && sleep 2 \
    && wine wineboot --init \
    && winetricks -q corefonts vcrun2019 \
    && wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "mscoree" /d "disabled" /f \
    && wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "mshtml" /d "disabled" /f \
    && kill $XVFB_PID || true

# Create directories
RUN mkdir -p /home/mt5user/mt5 /home/mt5user/logs /home/mt5user/.vnc

# Copy broker configuration first (for caching)
COPY --chown=mt5user:mt5user brokers.json /home/mt5user/brokers.json

# Download MetaTrader 5 installer based on broker selection or custom URL
RUN if [ -n "$MT5_INSTALLER_URL" ]; then \
        echo "Using custom MT5 installer URL: $MT5_INSTALLER_URL"; \
        wget -O /home/mt5user/mt5/mt5setup.exe "$MT5_INSTALLER_URL"; \
    else \
        echo "Using broker profile: $BROKER"; \
        INSTALLER_URL=$(jq -r ".brokers.${BROKER}.installer_url" /home/mt5user/brokers.json); \
        if [ -z "$INSTALLER_URL" ] || [ "$INSTALLER_URL" = "null" ]; then \
            echo "Invalid broker, using MetaQuotes default"; \
            INSTALLER_URL="https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"; \
        fi; \
        echo "Downloading from: $INSTALLER_URL"; \
        wget -O /home/mt5user/mt5/mt5setup.exe "$INSTALLER_URL"; \
    fi

# Copy configuration files
COPY --chown=mt5user:mt5user configs/ /home/mt5user/configs/
COPY --chown=mt5user:mt5user scripts/ /home/mt5user/scripts/

# Switch back to root to copy supervisor config
USER root
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose ports
EXPOSE 5901 6080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:6080/ || exit 1

# Start services
CMD ["/start.sh"]