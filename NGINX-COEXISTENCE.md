# Nginx Coexistence Guide

## Overview

XQuantify TradeStation can coexist with existing system nginx installations. The installer automatically detects and handles nginx conflicts.

---

## 🔍 Automatic Detection

When you run `./install.sh`, it automatically:
1. ✅ Detects if system nginx is running
2. ✅ Checks which ports are in use
3. ✅ Offers three options to handle conflicts
4. ✅ Configures Docker nginx accordingly

---

## 📊 Three Configuration Modes

### Mode 1: Alternative Ports (Recommended) ✅

**Best for:** Most users with existing nginx installations

**How it works:**
- System nginx: Uses ports 80, 443 (for your other projects)
- Docker nginx: Uses ports 8080, 8443 (for MT5)
- Both run independently without conflicts

**Access MT5:**
```
HTTPS: https://YOUR_IP:8443/vnc.html
HTTP:  http://YOUR_IP:8080/vnc.html
```

**Manual setup:**
```bash
# Just install normally - Docker nginx uses 8080/8443 by default
./install.sh
# Select option 1 when prompted
```

---

### Mode 2: Stop System Nginx

**Best for:** Servers dedicated to MT5 only

**How it works:**
- System nginx is stopped and disabled
- Docker nginx uses standard ports 80, 443
- MT5 accessible on standard HTTPS port

**Access MT5:**
```
HTTPS: https://YOUR_IP/vnc.html
HTTP:  http://YOUR_IP/vnc.html
```

**Manual setup:**
```bash
# Stop system nginx
sudo systemctl stop nginx
sudo systemctl disable nginx

# Install MT5
./install.sh
# Select option 2 when prompted
```

---

### Mode 3: System Nginx as Reverse Proxy (Advanced) 🚀

**Best for:** Professional deployments, integration with existing nginx setup

**How it works:**
- System nginx: Runs on ports 80, 443 (handles all incoming traffic)
- Docker nginx: Runs on ports 8080, 8443 (backend)
- System nginx proxies MT5 requests to Docker nginx
- Can integrate with your existing nginx sites

**Access MT5:**
```
HTTPS: https://YOUR_IP/vnc.html (standard port!)
HTTP:  http://YOUR_IP/vnc.html (redirects to HTTPS)
```

**Setup:**
```bash
# Option A: During installation
./install.sh
# Select option 3 when prompted

# Option B: After installation
./scripts/setup-system-nginx-proxy.sh
```

---

## 🔧 Current Configuration Detection

Check what's currently running:

```bash
# Check if system nginx is running
sudo systemctl status nginx

# Check which ports nginx is using
sudo ss -tlnp | grep nginx

# Check all nginx processes
ps aux | grep nginx | grep -v grep
```

Expected output with both running:
```
# System nginx (master process from Aug31)
root   3862  nginx: master process /usr/sbin/nginx

# Docker nginx (newer, from today)
root   1179773  nginx: master process nginx -g daemon off;
```

---

## 📋 Port Allocation

| Service | Port 80 | Port 443 | Port 8080 | Port 8443 |
|---------|---------|----------|-----------|-----------|
| **Mode 1: Alternative Ports** | System nginx | System nginx | Docker nginx | Docker nginx |
| **Mode 2: Docker Only** | Docker nginx | Docker nginx | - | - |
| **Mode 3: Reverse Proxy** | System nginx (proxy) | System nginx (proxy) | Docker nginx (backend) | Docker nginx (backend) |

---

## 🚀 Switching Between Modes

### Switch to Mode 1 (Alternative Ports)

If system nginx is running:
```bash
# Just ensure Docker nginx uses 8080/8443 (default)
docker compose ps
# Should show: 0.0.0.0:8080->80/tcp, 0.0.0.0:8443->443/tcp
```

### Switch to Mode 2 (Docker Only)

```bash
# Stop system nginx
sudo systemctl stop nginx
sudo systemctl disable nginx

# Restart Docker nginx
docker compose restart nginx

# Access via standard ports
# Update docker-compose.yml if needed to use 80/443
```

### Switch to Mode 3 (Reverse Proxy)

```bash
# Setup system nginx proxy
./scripts/setup-system-nginx-proxy.sh

# This creates /etc/nginx/sites-available/xquantify-mt5
# And proxies port 80/443 -> localhost:6080 (Docker MT5)
```

---

## 🔍 Troubleshooting

### Problem: "Connection Failed" with HTTPS

**Check:** Is system nginx blocking Docker nginx?

```bash
# Check what's listening on each port
sudo ss -tlnp | grep -E ":80 |:443 |:6080 |:8080 |:8443 "

# Check nginx processes
ps aux | grep nginx | grep -v grep
```

**Solution:** Use appropriate ports for your mode:
- Mode 1: `https://IP:8443/vnc.html`
- Mode 2: `https://IP/vnc.html`
- Mode 3: `https://IP/vnc.html`

---

### Problem: System nginx won't start after Mode 2

**Solution:** Re-enable system nginx:
```bash
sudo systemctl enable nginx
sudo systemctl start nginx

# If port conflicts occur, stop Docker nginx
docker compose stop nginx
```

---

### Problem: WebSocket not working through system nginx

**Check:** Does system nginx config have WebSocket headers?

```bash
# Check configuration
sudo nginx -T | grep -A 5 "upgrade"

# Should show:
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection $connection_upgrade;
```

**Fix:** Regenerate system nginx config:
```bash
./scripts/setup-system-nginx-proxy.sh
```

---

## 📖 System Nginx Reverse Proxy Details

### Configuration File

Location: `/etc/nginx/sites-available/xquantify-mt5`

### What It Does

```nginx
# Proxies standard ports to Docker MT5
server {
    listen 80;
    listen 443 ssl http2;

    location / {
        proxy_pass http://127.0.0.1:6080;  # Direct to Docker MT5
        proxy_http_version 1.1;

        # WebSocket support (critical for noVNC!)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        # Standard headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # noVNC specific
        proxy_read_timeout 61s;
        proxy_buffering off;
    }
}
```

### Enable/Disable

```bash
# Enable
sudo ln -s /etc/nginx/sites-available/xquantify-mt5 /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Disable
sudo rm /etc/nginx/sites-enabled/xquantify-mt5
sudo systemctl reload nginx
```

---

## 🎯 Best Practices

### For Development
- **Use Mode 1** (alternative ports)
- Easy to switch between projects
- No conflicts with other development servers

### For Production (Single Project)
- **Use Mode 2** (Docker only)
- Simplest configuration
- Standard HTTPS port

### For Production (Multiple Projects)
- **Use Mode 3** (reverse proxy)
- Professional setup
- Can route different paths to different services
- Example: `/mt5` → MT5, `/api` → API server, etc.

---

## 🔧 Manual Configuration

### If You Need Custom Setup

Edit `docker-compose.yml` to change ports:

```yaml
nginx:
  ports:
    - "80:80"      # HTTP
    - "443:443"    # HTTPS
    # or
    - "8080:80"    # HTTP on 8080
    - "8443:443"   # HTTPS on 8443
```

Then:
```bash
docker compose down
docker compose up -d
```

---

## 📞 Quick Reference

```bash
# Check configuration
ps aux | grep nginx | grep -v grep
sudo ss -tlnp | grep nginx
docker compose ps

# Setup reverse proxy
./scripts/setup-system-nginx-proxy.sh

# Test system nginx config
sudo nginx -t

# Reload system nginx
sudo systemctl reload nginx

# Restart Docker nginx
docker compose restart nginx

# View logs
docker compose logs nginx
sudo tail -f /var/log/nginx/error.log
```

---

## ✅ Summary

XQuantify TradeStation is **fully compatible** with existing nginx installations:

1. **Automatic detection** during installation
2. **Three configuration modes** to choose from
3. **Zero conflicts** when properly configured
4. **Easy switching** between modes
5. **Professional integration** via reverse proxy

**The installer handles everything automatically** - just select your preferred mode when prompted!

---

## 🚀 Quick Start Examples

### Example 1: Fresh Server
```bash
./install.sh
# No system nginx detected
# Uses standard Docker setup with 8080/8443
```

### Example 2: Server with System Nginx
```bash
./install.sh
# Detects system nginx
# Prompts for mode selection
# Recommends Mode 1 (alternative ports)
```

### Example 3: Professional Setup
```bash
./install.sh
# Select Mode 3 (reverse proxy)
# Access MT5 via: https://your-domain.com/vnc.html
# Other projects continue working on same nginx
```

---

**Documentation updated for optimal nginx coexistence!** 🎉
