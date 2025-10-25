# XQuantify TradeStation - Quick Start Guide

## ⚡ Super Quick Start (2 Commands)

```bash
# 1. Run the installer (automatically sets up SSL, checks dependencies, etc.)
chmod +x install.sh && ./install.sh

# 2. Access your MT5 platform
# HTTPS (recommended): https://YOUR_SERVER_IP:8443/vnc.html
# HTTP: http://YOUR_SERVER_IP:8080/vnc.html
```

That's it! The installer handles everything automatically:
- ✅ Checks and installs dependencies (Docker, Docker Compose, OpenSSL)
- ✅ Generates SSL certificates automatically
- ✅ Detects port conflicts
- ✅ Builds and starts all services
- ✅ Provides access URLs

---

## 🚀 Installation Options

### Option 1: Interactive Setup (Recommended for first-time users)
```bash
./install.sh
```
**Features:**
- Guides you through broker selection
- Automatic SSL certificate generation (self-signed or Let's Encrypt)
- Port conflict detection and resolution
- Dependency checking and installation
- Configuration wizard

**What you'll be asked:**
1. Broker selection (MetaQuotes, XM, IC Markets, etc.)
2. VNC password
3. SSL/HTTPS setup (automatic self-signed recommended)
4. Optional: MT5 auto-login credentials

### Option 2: Manual SSL Setup (If install.sh already ran without SSL)
```bash
# Generate self-signed SSL certificate
mkdir -p nginx/ssl && cd nginx/ssl
openssl genrsa -out privkey.pem 4096
openssl req -new -x509 -key privkey.pem -out cert.pem -days 365 \
    -subj "/C=US/ST=State/L=City/O=XQuantify/CN=$(curl -s ifconfig.me)" \
    -addext "subjectAltName=IP:$(curl -s ifconfig.me)"
chmod 644 cert.pem && chmod 600 privkey.pem
cd ../..

# Restart nginx
docker compose restart nginx
```

### Option 3: Specific Broker Build
```bash
# Using docker compose directly
docker compose build --build-arg BROKER=xm
docker compose up -d
```

---

## 🌐 Access Your MT5 Platform

After installation, the installer will show you the exact URLs. Typically:

### HTTPS Access (Recommended - Full Features)
```
https://YOUR_SERVER_IP:8443/vnc.html
```
✅ Full clipboard support
✅ All keyboard shortcuts
✅ Fullscreen mode
✅ Encrypted connection

**Note:** Browser will show security warning for self-signed certificates. Click "Advanced" → "Proceed" to continue.

### HTTP Access (Limited Features)
```
http://YOUR_SERVER_IP:8080/vnc.html
```
⚠️ Limited clipboard functionality
⚠️ Some shortcuts may not work

### Direct Access (Bypass nginx)
```
http://YOUR_SERVER_IP:6080/vnc.html
```

### VNC Client Access
```
vnc://YOUR_SERVER_IP:5901
```

**Default VNC Password:** `mt5password` (or what you set during install)

---

## 📋 Essential Commands

### Using Docker Compose (Always works)
```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Restart services
docker compose restart

# Check status
docker compose ps

# View logs
docker compose logs -f nginx          # Nginx logs
docker compose logs -f mt5-instance   # MT5 logs

# Restart specific service
docker compose restart nginx
```

### Using Make (If installed)
```bash
# Install make first (optional)
apt install make -y

# Then use shortcuts
make start       # Start MT5 platform
make stop        # Stop all services
make restart     # Restart services
make status      # Check status
make logs        # View logs
make scale N=3   # Scale to 3 instances
make help        # Show all commands
```

### SSL Management
```bash
# Generate/regenerate SSL certificate
./scripts/generate-ssl.sh

# Check SSL certificate status
openssl x509 -in nginx/ssl/cert.pem -noout -dates

# Setup Let's Encrypt (requires domain)
./scripts/setup-letsencrypt.sh your-domain.com
```

---

## 🔧 Configuration

Edit `.env` file:

```bash
# Choose your broker
BROKER=xm  # or: ic_markets, fxpro, pepperstone, etc.

# VNC password
VNC_PASSWORD=your_password

# MT5 auto-login (optional)
MT5_LOGIN=12345678
MT5_PASSWORD=your_mt5_password
MT5_SERVER=YourBroker-Server
```

Then rebuild:
```bash
make build
make start
```

---

## 📊 Scaling

Scale to multiple instances:

```bash
make scale N=3  # Run 3 MT5 instances
```

Access:
- Load balanced: http://localhost
- Instance 1: http://localhost:6080
- Instance 2: http://localhost:6081
- Instance 3: http://localhost:6082

---

## 🔍 Monitoring

```bash
make health      # Quick health check
make monitor     # Continuous monitoring
```

---

## 💾 Backup & Restore

```bash
make backup      # Create backup
make restore     # View & restore backups
```

---

## 🗑️ Uninstall

Complete removal (one command):

```bash
make uninstall
```

This will:
- Stop and remove all containers
- Remove Docker images and networks
- Ask what data to keep (backups, configs, etc.)
- Clean up Docker system

Or use the script directly:
```bash
./uninstall.sh
```

---

## 🆘 Troubleshooting

### "HTTPS is required for full functionality"
This means you need SSL certificates. Run:
```bash
# Quick fix (self-signed certificate)
mkdir -p nginx/ssl && cd nginx/ssl
openssl genrsa -out privkey.pem 4096
openssl req -new -x509 -key privkey.pem -out cert.pem -days 365 \
    -subj "/C=US/ST=State/L=City/O=XQuantify/CN=$(curl -s ifconfig.me)" \
    -addext "subjectAltName=IP:$(curl -s ifconfig.me)"
chmod 644 cert.pem && chmod 600 privkey.pem
cd ../..
docker compose restart nginx

# Then access via HTTPS
# https://YOUR_IP:8443/vnc.html
```

### "Port 80 already in use" Error
Port 80 is being used by another service (often system nginx). Options:
```bash
# Option 1: Use alternative ports (recommended)
# Docker nginx uses 8080/8443 by default - no conflicts!
# Access via: https://YOUR_IP:8443/vnc.html

# Option 2: Setup system nginx as reverse proxy
./scripts/setup-system-nginx-proxy.sh
# Access via: https://YOUR_IP/vnc.html (standard ports!)

# Option 3: Find what's using port 80
sudo ss -tlnp | grep ":80 "
./scripts/fix-port-conflict.sh

# Option 4: Stop the conflicting service
sudo systemctl stop apache2  # If Apache
sudo systemctl stop nginx    # If system nginx
```

**Note:** The installer automatically detects nginx conflicts and offers solutions.
See `NGINX-COEXISTENCE.md` for detailed nginx coexistence guide.

### Services won't start
```bash
# Check container status
docker compose ps

# View error logs
docker compose logs nginx
docker compose logs mt5-instance

# Restart services
docker compose restart
```

### Can't access MT5 web interface
```bash
# Check if nginx is running
docker compose ps nginx

# Check nginx logs
docker compose logs nginx

# Test connection
curl -I http://localhost:8080
curl -Ik https://localhost:8443  # For HTTPS

# Restart nginx
docker compose restart nginx
```

### "make: command not found"
Use `docker compose` commands instead:
```bash
docker compose ps          # Instead of: make status
docker compose up -d       # Instead of: make start
docker compose down        # Instead of: make stop
docker compose logs -f     # Instead of: make logs
```

Or install make:
```bash
apt install make -y
```

### Reset everything
```bash
docker compose down -v     # Stop and remove everything
rm -rf data/* logs/*       # Clean data (careful!)
./install.sh               # Fresh install
```

---

## 📚 More Help

- Full documentation: See `INSTALL.md`
- All commands: `make help`
- Broker list: `make list-brokers`
- Architecture: See `README.md` or `CLAUDE.md`

---

## 🎯 Common Workflows

### First-Time Setup
```bash
./install.sh          # Interactive setup
# Access at http://localhost
# Login with your MT5 credentials
```

### Daily Use
```bash
make start            # Start trading
make logs             # Check activity
make stop             # End session
```

### Production Deployment
```bash
./install.sh          # Choose your broker
# Edit .env: Set strong VNC_PASSWORD
make security-setup   # Generate SSL certs
make start
make backup           # Create first backup
```

### Switching Brokers
```bash
make stop
# Edit .env: Change BROKER value
make build
make start
```

### Custom Broker
```bash
# Edit .env
BROKER=custom
MT5_INSTALLER_URL=https://your-broker.com/mt5setup.exe

make build
make start
```

---

**Ready to trade!** 📈

For detailed guides, see `INSTALL.md`.
