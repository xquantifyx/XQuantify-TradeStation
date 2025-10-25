# XQuantify TradeStation - Installation Guide

## Quick Installation (Recommended)

### One-Command Install

The easiest way to get started with XQuantify TradeStation:

```bash
./install.sh
```

Or use Make:

```bash
make install
```

The interactive wizard will guide you through:
- ✅ Docker installation check
- ✅ Broker selection (12 pre-configured brokers)
- ✅ VNC password setup
- ✅ MT5 auto-login configuration
- ✅ Performance settings
- ✅ Automatic build and deployment

**Installation time:** ~5-10 minutes on first run

---

## Super Quick Start (No Interaction)

For automation or default setup:

```bash
make quick-start
```

This will:
- Use default MetaQuotes MT5
- Set VNC password to `mt5password`
- Build and start immediately
- Access at `http://localhost`

---

## Broker-Specific Installation

### Supported Brokers

XQuantify TradeStation supports these brokers out of the box:

| Broker | Make Command | Key |
|--------|-------------|-----|
| MetaQuotes (Official) | `make build` | `metaquotes` |
| XM Global | `make build-xm` | `xm` |
| IC Markets | `make build-ic` | `ic_markets` |
| FxPro | `make build-fxpro` | `fxpro` |
| Pepperstone | `make build-pepperstone` | `pepperstone` |
| RoboForex | `make build-roboforex` | `roboforex` |
| Exness | `make build-exness` | `exness` |
| AvaTrade | - | `avatrade` |
| Tickmill | - | `tickmill` |
| Admirals | - | `admirals` |

### Quick Build with Specific Broker

```bash
# Example: Build with XM Global
make build-xm
make start

# Example: Build with IC Markets
make build-ic
make start
```

### List All Available Brokers

```bash
make list-brokers
```

---

## Custom Broker Installation

If your broker is not listed, you can use a custom MT5 installer:

### Method 1: Using Make

```bash
make build-custom URL=https://your-broker.com/mt5setup.exe
make start
```

### Method 2: Using Environment Variables

Edit `.env` file:

```bash
BROKER=custom
MT5_INSTALLER_URL=https://your-broker.com/mt5setup.exe
```

Then build:

```bash
make build
make start
```

### Method 3: During Interactive Install

Run `./install.sh` and select option **11) Custom** when choosing a broker.

---

## Prerequisites

### Automatic Installation

The install script can automatically install Docker if not present on Ubuntu/Debian systems.

### Manual Prerequisites

If you prefer manual setup:

1. **Docker** (20.10+)
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```

2. **Docker Compose** (2.0+)
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

---

## Configuration

### VNC Password

Set in `.env` file:

```bash
VNC_PASSWORD=your_secure_password
```

### MT5 Auto-Login

For automatic login to your MT5 account:

```bash
MT5_LOGIN=12345678
MT5_PASSWORD=your_mt5_password
MT5_SERVER=YourBroker-Server
```

### Performance Tuning

Adjust resources per instance:

```bash
WINE_CPU_CORES=2          # CPU cores per instance
WINE_MEMORY_LIMIT=2g      # RAM per instance
XVFB_RESOLUTION=1920x1080x24  # Display resolution
```

---

## Post-Installation

### Access Your MT5 Platform

After installation completes:

- **Primary URL:** http://localhost (via load balancer)
- **Direct Access:** http://localhost:6080
- **VNC Direct:** Connect with VNC client to `localhost:5901`

### Verify Installation

```bash
# Check service status
make status

# View logs
make logs

# Run health check
make health
```

### Common Commands

```bash
make start          # Start services
make stop           # Stop services
make restart        # Restart services
make scale N=3      # Scale to 3 instances
make logs           # View logs
make health         # Health check
make backup         # Create backup
```

---

## Scaling

### Scale to Multiple Instances

```bash
# Scale to 3 instances
make scale N=3

# Scale to 5 instances
make scale N=5
```

Each instance gets:
- Isolated data directory
- Dedicated ports (auto-incremented)
- Load-balanced access via nginx

### Access Individual Instances

- Instance 1: http://localhost:6080
- Instance 2: http://localhost:6081
- Instance 3: http://localhost:6082
- Load Balanced: http://localhost

---

## Optimization Features

### Build Optimizations

The Dockerfile has been optimized for:

✅ **Layer Caching:** Wine initialization cached for faster rebuilds
✅ **Minimal Layers:** Consolidated RUN commands reduce image size
✅ **Pinned Versions:** Reproducible builds with version-locked dependencies
✅ **No Install Recommends:** Smaller image size

**First build:** ~5-10 minutes
**Rebuild (cached):** ~30-60 seconds

### Runtime Optimizations

- Pre-initialized Wine prefix
- Optimized Xvfb settings
- Efficient supervisor process management
- Health checks for auto-recovery

---

## Troubleshooting

### Installation Fails

```bash
# Check Docker is running
docker info

# Check Docker Compose
docker-compose version

# View detailed build logs
docker-compose build --progress=plain
```

### Can't Access MT5

```bash
# Check if containers are running
docker ps

# Check logs
make logs

# Restart services
make restart
```

### Custom Broker Installer Not Working

Ensure the URL is:
- ✅ Direct download link (not a landing page)
- ✅ Accessible without authentication
- ✅ Points to `.exe` file
- ✅ Uses HTTPS protocol

**Test download:**
```bash
wget -O test.exe "YOUR_INSTALLER_URL"
```

### Permission Errors

```bash
# Fix script permissions
chmod +x install.sh scripts/*.sh start.sh

# Fix directory permissions
sudo chown -R $USER:$USER data/ logs/ backups/
```

---

## Advanced Installation

### Build Without Starting

```bash
./install.sh
# Choose "n" when asked to start services
```

### Use Existing Configuration

If you already have a `.env` file:

```bash
# It will be backed up automatically
# New settings will be merged
./install.sh
```

### Offline Installation

1. Pre-download MT5 installer
2. Place in `./mt5/mt5setup.exe`
3. Comment out wget line in Dockerfile
4. Run: `make build`

### Multiple Deployments

Run separate instances:

```bash
# Clone repository to different directories
git clone <repo> tradestation-xm
cd tradestation-xm
# Edit .env to use different BROKER
make install

git clone <repo> tradestation-ic
cd tradestation-ic
# Edit .env to use different BROKER
make install
```

---

## Getting Help

### View All Commands

```bash
make help
```

### Check Installation

```bash
# Verify all components
./install.sh --check  # (if implemented)

# Or manually
docker --version
docker-compose --version
docker info
```

### Join Community

- GitHub Issues: [Report bugs or request features](https://github.com/xquantify/tradestation/issues)
- Documentation: See README.md for detailed architecture

---

## Security Notes

### Production Deployment

For production use:

1. **Change VNC password** from default
2. **Enable SSL:**
   ```bash
   make security-setup
   # Edit .env: SSL_ENABLED=true
   ```
3. **Configure firewall:**
   ```bash
   # Edit .env
   ALLOWED_IPS=your.ip.address/32
   ```
4. **Use strong MT5 passwords**
5. **Regular backups:**
   ```bash
   make backup
   ```

### Updates

Keep system updated:

```bash
# Update all containers
make update

# Rebuild with latest base image
make build
make restart
```

---

## Uninstalling XQuantify TradeStation

### Complete Uninstall

To completely remove XQuantify TradeStation from your system:

```bash
make uninstall
```

Or run the uninstall script directly:

```bash
./uninstall.sh
```

### What Gets Removed

The uninstall process will:

✅ Stop all running containers
✅ Remove all XQuantify containers (including scaled instances)
✅ Remove Docker images
✅ Remove Docker networks
✅ Remove Docker volumes
✅ Clean up Docker system

### Interactive Data Preservation

During uninstall, you'll be asked whether to keep:

- **MT5 data files** - Your trading data, history, templates (default: keep)
- **Log files** - Application logs (default: remove)
- **Backups** - All backup files (default: keep)
- **Configuration** - .env and other config files (default: keep)

### Quick Uninstall Examples

**Complete removal (remove everything):**
```bash
# During uninstall, answer 'n' to all preservation prompts
./uninstall.sh
```

**Keep important data:**
```bash
# During uninstall, answer 'y' to keep data and backups
./uninstall.sh
```

### Manual Cleanup

If you prefer manual cleanup:

```bash
# Stop services
make stop

# Remove containers
docker-compose down -v

# Remove images
docker rmi $(docker images --filter "label=com.xquantify.project=tradestation" -q)

# Remove data (optional)
rm -rf data/ logs/ backups/
```

### After Uninstall

The uninstall script preserves your configuration by default, so you can reinstall easily:

```bash
# Reinstall with preserved configuration
./install.sh
```

If you kept your `.env` file, it will use your previous broker and settings.

---

## Next Steps

After installation:

1. ✅ Access MT5 at http://localhost
2. ✅ Login with your broker credentials
3. ✅ Configure trading settings
4. ✅ Set up monitoring: `make monitor`
5. ✅ Configure backups: Edit `.env` AUTO_BACKUP settings
6. ✅ Scale if needed: `make scale N=<number>`

**Happy Trading!** 📈
