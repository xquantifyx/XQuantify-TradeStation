# Quick SSL/HTTPS Setup Guide

Your noVNC interface requires HTTPS for full functionality (clipboard, keyboard shortcuts, etc.).

## Current Issue

You're accessing: `http://107.150.25.53:6080/vnc.html` (Direct HTTP, limited features)
You should access: `https://107.150.25.53:8443/vnc.html` (HTTPS via nginx, full features)

## Quick Setup (5 Minutes)

### Step 1: Generate SSL Certificate

On your Linux server (107.150.25.53), run:

```bash
cd /path/to/XQuantify-TradeStation

# Option A: Interactive (prompts for details)
./scripts/generate-ssl.sh

# Option B: Non-interactive with IP address
mkdir -p nginx/ssl
cd nginx/ssl
openssl genrsa -out privkey.pem 4096
openssl req -new -x509 -key privkey.pem -out cert.pem -days 365 \
    -subj "/C=US/ST=State/L=City/O=XQuantify/CN=107.150.25.53" \
    -addext "subjectAltName=IP:107.150.25.53,DNS:localhost"
chmod 644 cert.pem
chmod 600 privkey.pem
cd ../..
```

### Step 2: Verify Certificate Files

```bash
ls -lh nginx/ssl/
# Should show:
# cert.pem
# privkey.pem
```

### Step 3: Restart Services

```bash
# If services are running
docker compose restart nginx

# Or restart everything
docker compose down
docker compose up -d
```

### Step 4: Access via HTTPS

Open in your browser:
```
https://107.150.25.53:8443/vnc.html
```

**Important:** Your browser will show a security warning because it's a self-signed certificate. This is NORMAL and SAFE.

**To bypass the warning:**
1. Click "Advanced" or "Show Details"
2. Click "Proceed to 107.150.25.53 (unsafe)" or "Accept the Risk"
3. The site will load with full HTTPS functionality

## Port Configuration

Your XQuantify TradeStation uses these ports:

| Port | Service | Protocol | Access |
|------|---------|----------|--------|
| 6080 | MT5 Direct | HTTP | `http://IP:6080` (Limited) |
| 5901 | VNC Direct | VNC | VNC clients only |
| 8080 | Nginx HTTP | HTTP | `http://IP:8080` (Redirect) |
| **8443** | **Nginx HTTPS** | **HTTPS** | **`https://IP:8443`** ✅ |

## Recommended Configuration

### Update docker-compose.yml Ports

To use standard ports (80/443 instead of 8080/8443):

```yaml
nginx:
  ports:
    - "80:80"      # HTTP (instead of 8080:80)
    - "443:443"    # HTTPS (instead of 8443:443)
```

Then access via:
```
https://107.150.25.53/vnc.html
```

### Configure HTTP to HTTPS Redirect

Add to `nginx/nginx.conf` HTTP server block:

```nginx
server {
    listen 80;
    server_name _;

    # Redirect all HTTP to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }

    # Keep Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}
```

## Production Setup (Let's Encrypt)

For a production server with a domain name, use Let's Encrypt for trusted certificates:

### Prerequisites
- A domain name pointing to your server (e.g., trading.example.com)
- Port 80 accessible from the internet
- DNS configured

### Setup Commands

```bash
# Update your domain in the script
./scripts/setup-letsencrypt.sh

# Or manually
export DOMAIN="trading.example.com"
export EMAIL="your-email@example.com"

docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  -d $DOMAIN \
  --email $EMAIL \
  --agree-tos \
  --no-eff-email

# Update nginx.conf to use Let's Encrypt certificates
# ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
# ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

docker compose restart nginx
```

## Troubleshooting

### Certificate Not Found Error

```bash
# Check if certificates exist
ls -lh nginx/ssl/

# If missing, generate them
./scripts/generate-ssl.sh
```

### Browser Shows "Connection Not Secure"

This is NORMAL for self-signed certificates. Click "Advanced" → "Proceed".

### Port Already in Use

```bash
# Check what's using the ports
sudo netstat -tlnp | grep -E ':(80|443|8080|8443)'

# Change ports in docker-compose.yml if needed
```

### Certificate Expired

```bash
# Generate new certificate
cd nginx/ssl
rm cert.pem privkey.pem
cd ../..
./scripts/generate-ssl.sh

# Restart nginx
docker compose restart nginx
```

## Security Notes

### Self-Signed Certificates
- ✅ Encryption: Full HTTPS encryption
- ✅ Privacy: Traffic is encrypted
- ⚠️ Trust: Browser warnings (not trusted by default)
- ✅ Use case: Development, internal networks, IP-based access

### Let's Encrypt Certificates
- ✅ Encryption: Full HTTPS encryption
- ✅ Privacy: Traffic is encrypted
- ✅ Trust: Automatically trusted by all browsers
- ✅ Use case: Production, domain-based access

## Quick Reference

```bash
# Generate SSL certificate
make ssl-self-signed
# or
./scripts/generate-ssl.sh

# Setup Let's Encrypt (with domain)
make ssl-setup
# or
./scripts/setup-letsencrypt.sh

# Check SSL status
make ssl-status

# Renew SSL certificate
make ssl-renew

# Restart services
docker compose restart nginx

# View nginx logs
docker compose logs nginx

# Test HTTPS connection
curl -k https://localhost:8443/health
```

## After Setup

Once HTTPS is working, you'll have access to:

✅ Full clipboard support (copy/paste)
✅ All keyboard shortcuts
✅ Fullscreen mode
✅ Better performance
✅ Encrypted connection
✅ All noVNC features

## Next Steps

1. Generate SSL certificate (Step 1 above)
2. Restart nginx (Step 3 above)
3. Access via HTTPS: `https://107.150.25.53:8443/vnc.html`
4. Accept security warning (self-signed certificate)
5. Enjoy full noVNC functionality! 🎉

---

For more information:
- See `INSTALL.md` for full setup documentation
- See `CLAUDE.md` for architecture details
- Use `make help` to see all available commands
