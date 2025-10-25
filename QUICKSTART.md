# XQuantify TradeStation - Quick Start Guide

## 🚀 Installation (Choose One)

### Option 1: Interactive Setup (Recommended)
```bash
./install.sh
```
Guides you through broker selection, configuration, and deployment.

### Option 2: One-Command Default Setup
```bash
make quick-start
```
Installs with defaults, ready in minutes.

### Option 3: Specific Broker
```bash
make build-xm && make start    # XM Global
make build-ic && make start    # IC Markets
make build-fxpro && make start # FxPro
```

---

## 🌐 Access MT5

After installation:
- **Web Browser:** http://localhost
- **Direct Access:** http://localhost:6080
- **VNC Client:** localhost:5901

Default VNC password: `mt5password`

---

## 📋 Essential Commands

```bash
make start       # Start MT5 platform
make stop        # Stop all services
make restart     # Restart services
make status      # Check status
make logs        # View logs
make scale N=3   # Scale to 3 instances
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

### Services won't start
```bash
docker ps              # Check running containers
make logs             # View error logs
make restart          # Try restarting
```

### Can't access MT5
```bash
make status           # Check if running
curl localhost:6080   # Test connection
make health           # Run health check
```

### Reset everything
```bash
make stop
make clean
make quick-start
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
