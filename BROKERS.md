# Broker Support Guide

## Supported Brokers

XQuantify TradeStation supports 12 pre-configured brokers plus custom broker installations.

---

## Pre-Configured Brokers

### MetaQuotes (Official)
- **Key:** `metaquotes`
- **Build Command:** `make build` (default)
- **Description:** Official MetaTrader 5 from MetaQuotes
- **Best For:** Testing, development, or accessing MQL5 community

### XM Global
- **Key:** `xm`
- **Build Command:** `make build-xm`
- **Description:** Popular international forex broker
- **Features:** Low spreads, good execution
- **Website:** https://www.xm.com

### IC Markets
- **Key:** `ic_markets`
- **Build Command:** `make build-ic`
- **Description:** Australian broker, excellent for scalping
- **Features:** Raw spreads, fast execution
- **Website:** https://www.icmarkets.com

### FxPro
- **Key:** `fxpro`
- **Build Command:** `make build-fxpro`
- **Description:** UK-based broker, well-regulated
- **Features:** Multiple account types, good support
- **Website:** https://www.fxpro.com

### Pepperstone
- **Key:** `pepperstone`
- **Build Command:** `make build-pepperstone`
- **Description:** Australian broker, competitive pricing
- **Features:** Low latency, tight spreads
- **Website:** https://www.pepperstone.com

### RoboForex
- **Key:** `roboforex`
- **Build Command:** `make build-roboforex`
- **Description:** International broker with many account types
- **Features:** Flexible leverage, copy trading
- **Website:** https://www.roboforex.com

### Exness
- **Key:** `exness`
- **Build Command:** `make build-exness`
- **Description:** Fast-growing international broker
- **Features:** High leverage, instant withdrawals
- **Website:** https://www.exness.com

### Bybit
- **Key:** `bybit`
- **Build Command:** `make build-bybit`
- **Description:** Leading cryptocurrency derivatives exchange
- **Features:** Crypto & derivatives trading, spot trading, high leverage
- **Website:** https://www.bybit.com
- **Note:** Verify MT5 availability - Bybit primarily offers proprietary trading platform

### AvaTrade
- **Key:** `avatrade`
- **Build Command:** Build via `.env` configuration
- **Description:** Irish regulated broker
- **Features:** Regulated in multiple jurisdictions
- **Website:** https://www.avatrade.com

### Tickmill
- **Key:** `tickmill`
- **Build Command:** Build via `.env` configuration
- **Description:** UK-based broker
- **Features:** Low commissions, good execution
- **Website:** https://www.tickmill.com

### Admirals
- **Key:** `admirals`
- **Build Command:** Build via `.env` configuration
- **Description:** European broker (formerly Admiral Markets)
- **Features:** MetaTrader Supreme Edition
- **Website:** https://www.admirals.com

---

## Using Pre-Configured Brokers

### Method 1: Interactive Install
```bash
./install.sh
# Select broker from list (1-12)
```

### Method 2: Make Commands
```bash
make build-xm
make start
```

### Method 3: Environment Variable
Edit `.env`:
```bash
BROKER=xm
```
Then:
```bash
make build
make start
```

---

## Custom Broker Installation

If your broker is not pre-configured, you can add it manually.

### Finding Your Broker's MT5 Installer

Most brokers provide MT5 installers on their website:

1. Visit your broker's website
2. Look for "Platforms" or "Download MT5" section
3. Right-click on "Download MT5" → "Copy link address"
4. Use this URL in the configuration

**Common URL patterns:**
- `https://download.mql5.com/cdn/web/[broker-name]/mt5/[broker]5setup.exe`
- `https://download.[broker].com/mt5setup.exe`
- `https://www.[broker].com/platforms/mt5/installer.exe`

### Method 1: Using Install Script
```bash
./install.sh
# Select option 12) Custom
# Paste your broker's installer URL
```

### Method 2: Using Make Command
```bash
make build-custom URL=https://your-broker.com/mt5setup.exe
make start
```

### Method 3: Using Environment Variables
Edit `.env`:
```bash
BROKER=custom
MT5_INSTALLER_URL=https://your-broker.com/mt5setup.exe
```

Then build:
```bash
make build
make start
```

---

## Adding a New Broker Profile

To add a permanent profile for your broker:

1. Edit `brokers.json`
2. Add your broker entry:

```json
{
  "brokers": {
    "your_broker": {
      "name": "Your Broker Name",
      "installer_url": "https://your-broker.com/mt5setup.exe",
      "description": "Description of your broker",
      "auto_login_support": true
    }
  }
}
```

3. Edit `.env`:
```bash
BROKER=your_broker
```

4. Build and start:
```bash
make build
make start
```

---

## Broker-Specific Notes

### XM Global
- Supports multiple server options (XM-Real, XM-Demo)
- Auto-login works well
- Good for multi-instance scaling

### IC Markets
- Has separate servers for different regions
- Excellent for automated trading
- Low latency VPS recommended

### FxPro
- Multiple account types may use different servers
- Check your server name in your account email

### Pepperstone
- Edge servers for different regions
- Raw spread accounts vs Standard accounts

### RoboForex
- Multiple server groups (ProCent, ECN, Prime, etc.)
- Ensure you use correct server name

---

## Common Issues

### Installer Download Fails

**Problem:** Wget fails to download MT5 installer

**Solutions:**
1. Verify URL is direct download link
2. Check if URL requires authentication
3. Try downloading manually first:
   ```bash
   wget -O test.exe "YOUR_URL"
   ```
4. Use curl instead:
   ```dockerfile
   # In Dockerfile, replace wget with:
   curl -L -o /home/mt5user/mt5/mt5setup.exe "URL"
   ```

### Wrong MT5 Version Installed

**Problem:** Broker's MT5 looks different than expected

**Cause:** Some brokers customize MT5 heavily

**Solution:** This is normal. Each broker's MT5 may have:
- Different branding
- Custom indicators pre-installed
- Broker-specific features

### Can't Login After Install

**Problem:** MT5 starts but can't login

**Possible Causes:**
1. Wrong server name (check your broker's documentation)
2. Wrong account credentials
3. Server requires specific MT5 version
4. Account not activated yet

**Solutions:**
- Verify `MT5_SERVER` value in `.env`
- Check account number and password
- Contact broker support for correct server name

### Multiple Accounts from Same Broker

**Setup multiple instances:**

```bash
# Instance 1
make scale N=2

# Configure each instance differently
# Edit docker-compose.yml to pass different credentials
```

---

## Server Names by Broker

Common server name patterns:

| Broker | Demo Server | Live Server |
|--------|------------|-------------|
| XM | XMGlobal-Demo | XMGlobal-Real 1, XMGlobal-Real 2 |
| IC Markets | ICMarketsSC-Demo | ICMarketsSC-Live01 |
| FxPro | FxPro-Demo | FxPro-Live |
| Pepperstone | Pepperstone-Demo | Pepperstone-Live |
| RoboForex | RoboForex-Demo | RoboForex-Pro |

**Note:** Server names change frequently. Check your broker's documentation or account email for exact server name.

---

## Verification

### Test Broker Installation

After building with your broker:

```bash
# Start services
make start

# Check logs for successful MT5 installation
make logs

# Access MT5
# Open http://localhost

# Verify broker branding appears
# Check MT5 shows correct broker name in title
```

### Successful Installation Signs

✅ MT5 window opens in browser
✅ Correct broker logo/branding visible
✅ Can see login screen
✅ Server list shows your broker's servers

---

## Getting Help

### Broker Not Working

1. Check broker's official MT5 download page
2. Verify installer URL is accessible:
   ```bash
   curl -I "YOUR_INSTALLER_URL"
   ```
3. Try building with official MetaQuotes first:
   ```bash
   make build
   ```
4. Contact broker support for MT5 installer link

### Request Broker Addition

If you'd like a broker added to pre-configured list:

1. Open GitHub issue
2. Provide:
   - Broker name
   - Official MT5 installer URL
   - Any special configuration notes

---

## Best Practices

### Choosing a Broker

Consider:
- ✅ Regulation and safety
- ✅ Spreads and commissions
- ✅ Server location (latency)
- ✅ MT5 support quality
- ✅ VPS compatibility

### Multiple Brokers

Run multiple brokers simultaneously:

```bash
# Clone repo for each broker
git clone <repo> tradestation-xm
cd tradestation-xm
# Edit .env: BROKER=xm
make install

cd ..
git clone <repo> tradestation-ic
cd tradestation-ic
# Edit .env: BROKER=ic_markets
make install
```

Each deployment is isolated and independent.

---

## Contributing

Have a broker configuration to share?

1. Fork repository
2. Add broker to `brokers.json`
3. Test installation
4. Submit pull request

---

**Happy Trading!** 📊
