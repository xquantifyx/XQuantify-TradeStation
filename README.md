<div align="center">

# 🚀 XQuantify TradeStation

### Professional MetaTrader 5 Docker Deployment Platform

[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![MT5](https://img.shields.io/badge/MetaTrader-5-00A8E1?logo=metatrader&logoColor=white)](https://www.metatrader5.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![noVNC](https://img.shields.io/badge/noVNC-Browser_Access-orange)](https://novnc.com/)
[![Wine](https://img.shields.io/badge/Wine-Compatible-red)](https://www.winehq.org/)

**Browser-based access to MetaTrader 5 trading platform via Docker**
Enterprise-grade containerized MT5 deployment with auto-scaling, monitoring, and multi-broker support

[Quick Start](#-quick-start) • [Features](#-features) • [Documentation](#-documentation) • [Brokers](#-supported-brokers) • [Demo](#-demo)

</div>

---

## 📸 Demo

> Access MetaTrader 5 directly from your web browser - no installation required!

```
┌─────────────────────────────────────────────────────────┐
│  🌐 Browser (http://localhost)                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │  MetaTrader 5 - Full Desktop Experience         │   │
│  │  ┌──────────┬──────────┬──────────┐            │   │
│  │  │  Charts  │  Trading │ Analysis │            │   │
│  │  └──────────┴──────────┴──────────┘            │   │
│  │  [Live trading interface running in browser]   │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

<!-- Add actual screenshots here when available -->
<!-- ![MT5 Browser Access](docs/images/screenshot1.png) -->
<!-- ![Trading Dashboard](docs/images/screenshot2.png) -->

---

## ⚡ Quick Start

### One-Command Installation

```bash
# Interactive setup wizard (recommended)
./install.sh
```

**Or** use Make:

```bash
# Interactive installation
make install

# Fast default setup (no questions asked)
make quick-start
```

That's it! Access MT5 at **http://YOUR_SERVER_IP:8080** 🎉

> **Note:** Don't forget to [configure your firewall](#firewall-configuration) to allow ports 6080 and 8080!

### Installation Time
- ⏱️ **First-time setup:** ~5-10 minutes
- ⏱️ **Subsequent rebuilds:** ~30-60 seconds (cached)

---

## ✨ Features

### 🌐 **Browser-Based Access**
- Access MT5 from any device with a web browser
- No MT5 installation required on client machines
- Full desktop MT5 experience via noVNC
- Supports tablets and mobile devices

### 🏢 **Multi-Broker Support**
- **12+ pre-configured brokers** (XM, IC Markets, FxPro, Pepperstone, Bybit, etc.)
- Custom broker installer support
- Easy broker switching without reinstall
- See [full broker list](#-supported-brokers)

### 📈 **Auto-Scaling & Load Balancing**
- Scale to multiple MT5 instances with one command
- Nginx-based load balancing
- Isolated data directories per instance
- Resource limits and health monitoring

### 🔒 **Enterprise Security**
- SSL/TLS encryption support
- VNC password protection
- IP-based access control
- Firewall configuration
- Secure credential management

### 🛠️ **Easy Management**
- Interactive installation wizard
- One-command operations
- Automated backups and restores
- Comprehensive health monitoring
- Real-time metrics and alerts

### 🐳 **Docker-Powered**
- Containerized deployment
- Wine integration for Linux
- Reproducible builds
- Easy updates and rollbacks
- Cross-platform compatibility

---

## 🚀 Installation

### Prerequisites

- **Docker** (20.10+)
- **Docker Compose** (2.0+)
- **Linux/WSL2** (Ubuntu 20.04+ recommended)
- **2GB RAM** minimum, 4GB+ recommended
- **10GB disk space**

> The installer can automatically install Docker if not present!

### Step-by-Step

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/xquantify-tradestation.git
   cd xquantify-tradestation
   ```

2. **Run the installer:**
   ```bash
   ./install.sh
   ```

3. **Follow the wizard:**
   - Select your broker (or use custom installer)
   - Set VNC password
   - Configure MT5 auto-login (optional)
   - Adjust performance settings
   - Build and deploy

4. **Configure Firewall:**
   ```bash
   sudo ufw allow 6080/tcp
   sudo ufw allow 8080/tcp
   sudo ufw allow 8443/tcp
   ```

5. **Access MT5:**
   - Via nginx HTTPS: `https://YOUR_SERVER_IP:8443` (recommended)
   - Via nginx HTTP: `http://YOUR_SERVER_IP:8080`
   - Direct access: `http://YOUR_SERVER_IP:6080`
   - VNC client: `YOUR_SERVER_IP:5901`

### Installation Methods

| Method | Command | Best For |
|--------|---------|----------|
| **Interactive** | `./install.sh` | First-time users, custom setups |
| **Quick Start** | `make quick-start` | Automation, defaults |
| **Specific Broker** | `make build-xm && make start` | Known broker preference |

---

## 🌍 Supported Brokers

XQuantify TradeStation comes with **12 pre-configured brokers**:

| Broker | Command | Website |
|--------|---------|---------|
| MetaQuotes (Official) | `make build` | [MetaQuotes](https://www.metaquotes.net/) |
| XM Global | `make build-xm` | [XM.com](https://www.xm.com/) |
| IC Markets | `make build-ic` | [ICMarkets.com](https://www.icmarkets.com/) |
| FxPro | `make build-fxpro` | [FxPro.com](https://www.fxpro.com/) |
| Pepperstone | `make build-pepperstone` | [Pepperstone.com](https://www.pepperstone.com/) |
| RoboForex | `make build-roboforex` | [RoboForex.com](https://www.roboforex.com/) |
| Exness | `make build-exness` | [Exness.com](https://www.exness.com/) |
| Bybit | `make build-bybit` | [Bybit.com](https://www.bybit.com/) |
| AvaTrade | See [brokers.json](brokers.json) | [AvaTrade.com](https://www.avatrade.com/) |
| Tickmill | See [brokers.json](brokers.json) | [Tickmill.com](https://www.tickmill.com/) |
| Admirals | See [brokers.json](brokers.json) | [Admirals.com](https://www.admirals.com/) |
| **Custom Broker** | `make build-custom URL=<url>` | Any broker with MT5 |

### Using a Custom Broker

```bash
# Method 1: During installation
./install.sh
# Select option 11) Custom

# Method 2: Using Make
make build-custom URL=https://your-broker.com/mt5setup.exe
make start

# Method 3: Edit .env
BROKER=custom
MT5_INSTALLER_URL=https://your-broker.com/mt5setup.exe
```

📚 **Detailed broker guide:** [BROKERS.md](BROKERS.md)

---

## 🎯 Usage

### Essential Commands

```bash
# Start services
make start

# Stop services
make stop

# View logs
make logs

# Check health
make health

# View all commands
make help
```

### Scaling Operations

```bash
# Scale to 3 instances
make scale N=3

# Check status
make status

# Access instances:
# - Load balanced: http://YOUR_SERVER_IP:8080
# - Instance 1: http://YOUR_SERVER_IP:6080
# - Instance 2: http://YOUR_SERVER_IP:6081
# - Instance 3: http://YOUR_SERVER_IP:6082
```

### Broker Management

```bash
# List available brokers
make list-brokers

# Switch broker (interactive)
./scripts/switch-broker.sh

# Build with specific broker
make build-xm       # XM Global
make build-ic       # IC Markets
make build-fxpro    # FxPro
```

### Maintenance

```bash
# Create backup
make backup

# View and restore backups
make restore

# Update containers
make update

# Uninstall everything
make uninstall
```

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────┐
│                        Users                             │
│     Browser 1    Browser 2    Browser 3    VNC Client   │
└────────┬──────────────┬─────────────┬──────────┬─────────┘
         │              │             │          │
         └──────────────┼─────────────┼──────────┘
                        │             │
                 ┌──────▼─────────────▼────┐
                 │    Nginx Load Balancer  │
                 │    (Port 8080/8443)     │
                 └──────┬─────────────┬────┘
                        │             │
         ┌──────────────┼─────────────┼──────────┐
         │              │             │          │
    ┌────▼────┐    ┌────▼────┐   ┌────▼────┐
    │ MT5-1   │    │ MT5-2   │   │ MT5-3   │
    │ :6080   │    │ :6081   │   │ :6082   │
    └─────────┘    └─────────┘   └─────────┘
    │         │    │         │   │         │
    │ noVNC   │    │ noVNC   │   │ noVNC   │
    │ X11VNC  │    │ X11VNC  │   │ X11VNC  │
    │ Wine    │    │ Wine    │   │ Wine    │
    │ MT5 App │    │ MT5 App │   │ MT5 App │
    └─────────┘    └─────────┘   └─────────┘
         │              │             │
    ┌────▼──────────────▼─────────────▼────┐
    │         Docker Network (mt5-network)  │
    └──────────────────────────────────────┘
```

### Components

- **noVNC**: HTML5 VNC client for browser access
- **X11VNC**: VNC server for remote display
- **Xvfb**: Virtual framebuffer for headless operation
- **Wine**: Windows compatibility layer for Linux
- **MT5**: MetaTrader 5 trading platform
- **Nginx**: Reverse proxy and load balancer
- **Watchtower**: Automatic container updates (optional)

---

## 📋 Configuration

### Environment Variables

Edit `.env` file:

```bash
# Broker Configuration
BROKER=xm                    # Broker key from brokers.json
MT5_INSTALLER_URL=          # Custom installer URL (for BROKER=custom)

# VNC Access
VNC_PASSWORD=mt5password    # Change this!

# MT5 Auto-Login (Optional)
MT5_LOGIN=12345678
MT5_PASSWORD=your_password
MT5_SERVER=YourBroker-Server

# Performance
WINE_CPU_CORES=2
WINE_MEMORY_LIMIT=2g
XVFB_RESOLUTION=1920x1080x24

# Scaling
MAX_INSTANCES=10

# Monitoring
ENABLE_MONITORING=true
CHECK_INTERVAL=30
ALERT_EMAIL=alerts@example.com
WEBHOOK_URL=https://hooks.slack.com/...

# Security
SSL_ENABLED=false
ALLOWED_IPS=127.0.0.1,192.168.0.0/16
```

### SSL Configuration

XQuantify TradeStation supports automatic SSL/HTTPS setup with Let's Encrypt or self-signed certificates.

#### Option 1: Let's Encrypt (Recommended for Production)

Free, trusted SSL certificates with automatic renewal:

```bash
# Setup Let's Encrypt SSL (requires domain name)
make ssl-setup

# Or manually specify domain
./scripts/setup-letsencrypt.sh your-domain.com

# Check certificate status
make ssl-status

# Manually renew certificate (auto-renewal runs twice daily)
make ssl-renew
```

**Requirements:**
- Valid domain name pointing to your server
- Ports 80 and 443 accessible from internet
- Email address for certificate notifications

**Features:**
- Automatic certificate renewal every 12 hours
- 90-day certificate validity
- Zero downtime updates
- Production-grade trusted certificates

#### Option 2: Self-Signed Certificate (Development/Testing)

Quick setup without domain requirements:

```bash
# Generate self-signed certificate
make ssl-self-signed

# Or use the script directly
./scripts/generate-ssl.sh

# Enable SSL in .env
SSL_ENABLED=true

# Restart services
make restart
```

**Note:** Self-signed certificates will show browser security warnings.

#### SSL Configuration in .env

```bash
SSL_ENABLED=true                    # Enable/disable SSL
SSL_DOMAIN=your-domain.com          # Your domain (for Let's Encrypt)
SSL_EMAIL=admin@your-domain.com     # Email for SSL notifications
SSL_CERT_PATH=./nginx/ssl/cert.pem  # Certificate path
SSL_KEY_PATH=./nginx/ssl/privkey.pem # Private key path
```

### Firewall Configuration

**Required Ports:**

| Port | Service | Purpose |
|------|---------|---------|
| `80` | Let's Encrypt | SSL certificate validation (ACME challenge) |
| `443` | Alternative HTTPS | Standard HTTPS port (optional) |
| `6080` | MT5 Main Instance | Direct noVNC access |
| `6081+` | Additional MT5 Instances | Direct access to scaled instances |
| `8080` | Nginx HTTP | Load balancer (changed from 80) |
| `8443` | Nginx HTTPS | SSL load balancer (changed from 443) |
| `9000` | Portainer | Container management UI (dev mode) |

**Note:** Port 80 is required for Let's Encrypt SSL certificate setup and renewal.

**Configure Firewall:**

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 80/tcp    # Required for Let's Encrypt
sudo ufw allow 443/tcp   # Optional: Standard HTTPS
sudo ufw allow 6080/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo ufw allow 9000/tcp  # Optional: Portainer access
sudo ufw reload
sudo ufw status

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=6080/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8443/tcp
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --reload

# Direct iptables
sudo iptables -A INPUT -p tcp --dport 6080 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

**Cloud Provider Firewall:**

If hosting on cloud platforms (AWS, GCP, Azure, DigitalOcean), also configure security groups:

- **AWS EC2:** Security Groups → Inbound Rules → Add TCP 6080, 8080, 8443
- **Google Cloud:** VPC Firewall Rules → Allow TCP 6080, 8080, 8443
- **Azure:** Network Security Groups → Inbound Rules → Add ports
- **DigitalOcean:** Networking → Firewalls → Add inbound rules

**Verify Ports Are Open:**

```bash
# Check if ports are listening
sudo netstat -tulpn | grep -E '6080|8080|8443'

# Or using ss
sudo ss -tulpn | grep -E '6080|8080|8443'

# Test from external machine
curl http://YOUR_SERVER_IP:8080/health
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [QUICKSTART.md](QUICKSTART.md) | Essential commands and workflows |
| [INSTALL.md](INSTALL.md) | Comprehensive installation guide |
| [BROKERS.md](BROKERS.md) | Broker configuration and support |
| [CLAUDE.md](CLAUDE.md) | Development and architecture details |

---

## 🔧 Advanced Usage

### Multi-Instance Trading

Run multiple isolated MT5 instances:

```bash
# Scale to 5 instances
make scale N=5

# Each instance has:
# - Isolated data directory
# - Separate port (6080, 6081, 6082...)
# - Independent MT5 process
# - Load-balanced access
```

### Performance Tuning

```bash
# Edit .env
WINE_CPU_CORES=4              # More CPU for each instance
WINE_MEMORY_LIMIT=4g          # More RAM per instance
XVFB_RESOLUTION=2560x1440x24  # Higher resolution
```

### Monitoring & Alerts

```bash
# Continuous monitoring
make monitor

# View detailed metrics
./scripts/monitor.sh metrics

# Configure alerts in .env
ALERT_EMAIL=your@email.com
WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK
```

### Automated Backups

```bash
# Edit .env
AUTO_BACKUP=true
BACKUP_SCHEDULE="0 2 * * *"  # Daily at 2 AM
BACKUP_RETENTION_DAYS=30

# Manual backup
make backup

# Restore
make restore
```

---

## 🐛 Troubleshooting

### Common Issues

**Services won't start:**
```bash
docker ps               # Check running containers
make logs              # View error logs
make restart           # Try restarting
```

**Can't access MT5 (Connection Refused):**
```bash
# 1. Check if containers are running
docker ps
make status

# 2. Check if ports are listening
sudo netstat -tulpn | grep -E '6080|8080'

# 3. Configure firewall (if not done yet)
sudo ufw allow 6080/tcp
sudo ufw allow 8080/tcp
sudo ufw reload

# 4. Test local connection first
curl http://localhost:6080

# 5. Check cloud provider security groups
# AWS/GCP/Azure: Add inbound rules for ports 6080, 8080

# 6. View container logs
make logs
```

**Need to reset everything:**
```bash
make uninstall         # Remove everything
make install           # Fresh installation
```

### Getting Help

1. Check [INSTALL.md](INSTALL.md) troubleshooting section
2. Review logs: `make logs`
3. Run health check: `make health`
4. Open an [issue](https://github.com/yourusername/xquantify-tradestation/issues)

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Ways to Contribute

- 🐛 Report bugs and issues
- 💡 Suggest new features
- 📝 Improve documentation
- 🔧 Submit pull requests
- ⭐ Star the repository
- 🌍 Add broker configurations

### Development Setup

```bash
# Clone repository
git clone https://github.com/yourusername/xquantify-tradestation.git
cd xquantify-tradestation

# Create feature branch
git checkout -b feature/your-feature

# Make changes and test
make build
make start

# Submit PR
git push origin feature/your-feature
```

### Adding a Broker

1. Add broker configuration to `brokers.json`
2. Test installation with your broker
3. Update documentation
4. Submit pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses

- MetaTrader 5: © MetaQuotes Software Corp.
- Wine: LGPL License
- noVNC: MPL 2.0 License
- Docker: Apache 2.0 License

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/xquantify-tradestation&type=Date)](https://star-history.com/#yourusername/xquantify-tradestation&Date)

---

## 🙏 Acknowledgments

- [MetaQuotes](https://www.metaquotes.net/) for MetaTrader 5
- [Wine Project](https://www.winehq.org/) for Windows compatibility
- [noVNC](https://novnc.com/) for browser VNC client
- [Docker](https://www.docker.com/) for containerization
- All [contributors](https://github.com/yourusername/xquantify-tradestation/graphs/contributors)

---

## 📞 Support

- 📧 **Email:** support@xquantify.com
- 💬 **Issues:** [GitHub Issues](https://github.com/yourusername/xquantify-tradestation/issues)
- 📖 **Documentation:** [Full Docs](docs/)
- 🌐 **Website:** [xquantify.com](https://xquantify.com)

---

## 🗺️ Roadmap

- [x] Docker-based MT5 deployment
- [x] Browser access via noVNC
- [x] Multi-instance scaling
- [x] Multi-broker support (12+ brokers)
- [x] Interactive installer
- [x] Automated backups
- [x] Health monitoring
- [ ] Kubernetes deployment
- [ ] API for programmatic management
- [ ] Trading analytics dashboard
- [ ] Mobile app support
- [ ] Cloud deployment templates (AWS, GCP, Azure)

---

<div align="center">

### 🚀 Ready to start trading?

```bash
./install.sh
```

**Star ⭐ this repo if you find it useful!**

[Report Bug](https://github.com/yourusername/xquantify-tradestation/issues) • [Request Feature](https://github.com/yourusername/xquantify-tradestation/issues) • [Discussions](https://github.com/yourusername/xquantify-tradestation/discussions)

---

Made with ❤️ by the XQuantify Team

**© 2024 XQuantify. All rights reserved.**

</div>
