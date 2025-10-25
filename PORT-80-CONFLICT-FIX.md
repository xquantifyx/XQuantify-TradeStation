# Port 80 Conflict - Quick Fix Guide

## The Problem

You're seeing this error:
```
failed to bind host port for 0.0.0.0:80:172.17.0.2:80/tcp: address already in use
```

This means **port 80 is already in use** by another service on your server, preventing Let's Encrypt from setting up SSL certificates.

## SOLUTION 1: Use Self-Signed Certificate (Fastest - 30 seconds)

**This is the recommended quick fix.** It doesn't require port 80 and works immediately.

### On Your Server (107.150.25.53):

```bash
# Navigate to your project directory
cd /path/to/XQuantify-TradeStation

# Generate self-signed SSL certificate
./scripts/generate-ssl.sh

# Or non-interactive method:
mkdir -p nginx/ssl
cd nginx/ssl
openssl genrsa -out privkey.pem 4096
openssl req -new -x509 -key privkey.pem -out cert.pem -days 365 \
    -subj "/C=US/ST=State/L=City/O=XQuantify/CN=107.150.25.53" \
    -addext "subjectAltName=IP:107.150.25.53,DNS:localhost"
chmod 644 cert.pem
chmod 600 privkey.pem
cd ../..

# Restart nginx to use the new certificate
docker compose restart nginx
```

### Access Your MT5:

```
https://107.150.25.53:8443/vnc.html
```

**Note:** Your browser will show a security warning. This is normal for self-signed certificates.
- Click "Advanced" → "Proceed to 107.150.25.53"
- The connection is encrypted, just not verified by a CA

---

## SOLUTION 2: Fix Port 80 Conflict (For Let's Encrypt)

If you need Let's Encrypt (trusted certificate, no browser warnings), you must free port 80.

### Step 1: Find What's Using Port 80

```bash
# Run diagnostic script
./scripts/fix-port-conflict.sh

# Or manually check:
sudo netstat -tlnp | grep ":80 "
# or
sudo ss -tlnp | grep ":80 "
# or
sudo lsof -i :80
```

### Step 2: Stop the Conflicting Service

Common culprits and how to stop them:

#### Apache Web Server
```bash
sudo systemctl stop apache2
sudo systemctl disable apache2  # Prevent auto-start
```

#### System Nginx
```bash
sudo systemctl stop nginx
sudo systemctl disable nginx  # Prevent auto-start
```

#### Another Docker Container
```bash
# List containers using port 80
docker ps --format "{{.Names}}: {{.Ports}}" | grep ":80"

# Stop the container
docker stop <container-name>
```

### Step 3: Retry Let's Encrypt Setup

```bash
./scripts/setup-letsencrypt.sh your-domain.com
```

---

## SOLUTION 3: Use Alternative Ports (No Conflicts)

If you can't free port 80 and don't need Let's Encrypt, use alternative ports.

Your current setup already uses alternative ports:
- HTTP: Port 8080 (instead of 80)
- HTTPS: Port 8443 (instead of 443)

This means you can use self-signed certificates without any port conflicts.

```bash
# Generate self-signed certificate
./scripts/generate-ssl.sh

# Access via:
https://107.150.25.53:8443/vnc.html
```

---

## SOLUTION 4: Use Webroot Method (Advanced)

If you must use Let's Encrypt but can't stop the service using port 80, use the webroot method:

### Prerequisites:
- The service on port 80 must serve files from a directory
- You need to configure it to serve `.well-known/acme-challenge/`

### For Apache:
```bash
# Add to your Apache config
<VirtualHost *:80>
    # ... existing config ...

    Alias /.well-known/acme-challenge/ /var/www/certbot/.well-known/acme-challenge/
    <Directory /var/www/certbot/.well-known/acme-challenge/>
        Options None
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>

sudo systemctl reload apache2
```

### Then run Certbot:
```bash
docker run --rm \
    -v "$(pwd)/nginx/certbot/conf:/etc/letsencrypt" \
    -v "$(pwd)/nginx/certbot/www:/var/www/certbot" \
    certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email support@xquantify.com \
    --agree-tos \
    --no-eff-email \
    -d your-domain.com
```

---

## Quick Diagnostic Commands

```bash
# Check what's using port 80
sudo netstat -tlnp | grep ":80 "

# Check if Apache is running
systemctl status apache2

# Check if system nginx is running
systemctl status nginx

# Check Docker containers on port 80
docker ps --format "{{.Names}}: {{.Ports}}" | grep ":80"

# List all listening ports
sudo netstat -tlnp

# Check firewall status
sudo ufw status
```

---

## Recommended Quick Fix (Right Now)

Based on your error, here's what I recommend you do **right now**:

```bash
# 1. Navigate to your project
cd /path/to/XQuantify-TradeStation

# 2. Quick diagnostic
./scripts/fix-port-conflict.sh

# 3. Generate self-signed certificate (fastest solution)
mkdir -p nginx/ssl && cd nginx/ssl
openssl genrsa -out privkey.pem 4096 2>/dev/null
openssl req -new -x509 -key privkey.pem -out cert.pem -days 365 \
    -subj "/C=US/ST=State/L=City/O=XQuantify/CN=107.150.25.53" \
    -addext "subjectAltName=IP:107.150.25.53" 2>/dev/null
chmod 644 cert.pem && chmod 600 privkey.pem
cd ../..

# 4. Restart nginx
docker compose restart nginx

# 5. Access with HTTPS
echo "Access at: https://107.150.25.53:8443/vnc.html"
```

This takes 30 seconds and gives you full HTTPS functionality immediately.

---

## After You Fix It

Once you have HTTPS working, you'll get:

✅ Full clipboard support
✅ All keyboard shortcuts
✅ Fullscreen mode
✅ Better performance
✅ Encrypted connection
✅ All noVNC features

The self-signed certificate works perfectly for this use case. The only difference from Let's Encrypt is a one-time browser warning.

---

## Need Help?

Run the diagnostic tool:
```bash
chmod +x scripts/fix-port-conflict.sh
./scripts/fix-port-conflict.sh
```

Or check the main documentation:
- `QUICK-SSL-SETUP.md` - Complete SSL setup guide
- `CLAUDE.md` - Architecture details
- `INSTALL.md` - Full installation guide
