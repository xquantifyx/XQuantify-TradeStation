#!/bin/bash

# XQuantify TradeStation - Container startup script
set -e

echo "Starting XQuantify TradeStation container..."

# Create necessary directories
mkdir -p /home/mt5user/.vnc /home/mt5user/logs /home/mt5user/mt5data

# Set VNC password for x11vnc
if [ -n "$VNC_PASSWORD" ]; then
    echo "Setting VNC password..."
    x11vnc -storepasswd "$VNC_PASSWORD" /home/mt5user/.vnc/passwd
    chmod 600 /home/mt5user/.vnc/passwd
    chown mt5user:mt5user /home/mt5user/.vnc/passwd
fi

# Set proper ownership
chown -R mt5user:mt5user /home/mt5user/

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf