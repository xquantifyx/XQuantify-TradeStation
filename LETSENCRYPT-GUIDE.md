# Let's Encrypt SSL Certificate Guide

## Overview

This guide covers setting up **FREE trusted SSL certificates** from Let's Encrypt for your XQuantify TradeStation deployment. Let's Encrypt provides industry-standard SSL/TLS certificates that are trusted by all major browsers - **no security warnings!**

---

## Why Let's Encrypt?

### Benefits

✅ **FREE** - No cost, ever
✅ **Trusted** - Recognized by all browsers (Chrome, Firefox, Safari, Edge)
✅ **No warnings** - Users see the green padlock, not security warnings
✅ **Auto-renews** - Certificates renew automatically every 90 days
✅ **Easy setup** - Automated process via our installer
✅ **Professional** - Industry-standard encryption (same as paid certificates)

### vs Self-Signed Certificates

| Feature | Let's Encrypt | Self-Signed |
|---------|---------------|-------------|
| Browser Trust | ✅ Trusted | ❌ Warning shown |
| Cost | 🆓 FREE | 🆓 FREE |
| Setup | Domain required | Works with IP |
| Renewal | Auto (90 days) | Manual (1 year) |
| User Experience | Professional | Developer/Testing |
| Production Ready | ✅ Yes | ⚠️ Testing only |

---

## Requirements

Before setting up Let's Encrypt, ensure you have:

### 1. Domain Name
- A registered domain (e.g., `mt5.yourdomain.com`)
- Can be a subdomain (recommended for organization)
- Examples: `trading.mycompany.com`, `mt5.mysite.net`

### 2. DNS Configuration
Your domain must point to your server's public IP:
```bash
# Check your server's public IP
curl ifconfig.me

# Your DNS should have an A record:
# mt5.yourdomain.com → 107.150.25.53 (your server IP)
```

**Verify DNS is working:**
```bash
# Should return your server's IP
dig +short mt5.yourdomain.com
nslookup mt5.yourdomain.com
```

### 3. Port 80 Access
Let's Encrypt needs port 80 open for domain validation (ACME challenge):
```bash
# Check if port 80 is accessible
sudo ss -tlnp | grep :80

# If something is using port 80:
# - Option 1: Use our nginx coexistence feature (automatic)
# - Option 2: Temporarily stop the service
# - Option 3: Use DNS challenge (advanced)
```

---

## Installation Methods

### Method 1: During Fresh Install (Recommended)

When running `./install.sh` for the first time:

```bash
chmod +x install.sh && ./install.sh

# When prompted for SSL option:
# Select option (1-3) [default: 1]: 1
#
# Enter your domain name: mt5.yourdomain.com
# Enter email for SSL notifications: admin@yourdomain.com
```

**The installer will:**
1. Verify domain DNS points to your server
2. Check port 80 availability
3. Request certificate from Let's Encrypt
4. Configure nginx automatically
5. Set up auto-renewal (checks twice daily)

---

### Method 2: Add to Existing Installation

If you already have XQuantify TradeStation running with self-signed certificate:

```bash
cd ~/XQuantify-TradeStation

# Run the Let's Encrypt setup script
./scripts/setup-letsencrypt.sh mt5.yourdomain.com

# Follow the prompts:
# Enter email for SSL notifications: admin@yourdomain.com
```

The script will:
- Stop containers temporarily
- Request certificate from Let's Encrypt
- Update nginx configuration
- Restart services
- Display new access URL

---

### Method 3: Manual Setup (Advanced)

For complete control over the process:

```bash
cd ~/XQuantify-TradeStation

# 1. Ensure containers are running
docker compose up -d

# 2. Request certificate via certbot container
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email admin@yourdomain.com \
  --agree-tos \
  --no-eff-email \
  -d mt5.yourdomain.com

# 3. Certificates will be in: nginx/certbot/conf/live/mt5.yourdomain.com/

# 4. Update nginx configuration to use new certificates
# Edit docker-compose.yml or nginx/nginx.conf

# 5. Restart nginx
docker compose restart nginx
```

---

## Post-Installation

### Access Your MT5 Platform

Once Let's Encrypt is configured:

```
✅ HTTPS (Trusted): https://mt5.yourdomain.com:8443/vnc.html
   (No browser warnings - green padlock!)

📱 Mobile-friendly: https://mt5.yourdomain.com:8443/vnc.html
   (Works on phones/tablets)
```

### Verify Certificate

Check that your certificate is working:

```bash
# Check certificate details
openssl s_client -connect mt5.yourdomain.com:8443 -servername mt5.yourdomain.com

# Or visit in browser and click the padlock icon
# Should show: "Certificate (Valid)"
# Issued by: Let's Encrypt
```

### Auto-Renewal

Certificates automatically renew via certbot container:
- **Checks:** Twice daily (random times)
- **Renews:** When certificate has < 30 days remaining
- **Restarts:** nginx automatically after renewal

**Check renewal status:**
```bash
# View certbot logs
docker compose logs certbot

# Test renewal process (dry run)
docker compose run --rm certbot renew --dry-run

# Force renewal (if needed)
docker compose run --rm certbot renew --force-renewal
```

---

## Troubleshooting

### Error: Port 80 Already in Use

**Symptom:**
```
Error: Cannot bind to port 80
Another service is using this port
```

**Solution 1: Use Nginx Coexistence (Automatic)**
```bash
# The installer automatically detects this and offers solutions
# Choose: "Setup system nginx as reverse proxy"
```

**Solution 2: Temporarily Stop Conflicting Service**
```bash
# Find what's using port 80
sudo ss -tlnp | grep :80

# Stop it temporarily (example: Apache)
sudo systemctl stop apache2

# Run Let's Encrypt setup
./scripts/setup-letsencrypt.sh mt5.yourdomain.com

# Restart the service
sudo systemctl start apache2
```

**Solution 3: DNS Challenge (No port 80 needed)**
```bash
docker compose run --rm certbot certonly \
  --manual \
  --preferred-challenges dns \
  -d mt5.yourdomain.com

# Follow instructions to add TXT record to DNS
# Verify at: https://dnschecker.org/
```

---

### Error: Domain Not Resolving

**Symptom:**
```
Failed to verify domain ownership
DNS record not found
```

**Diagnosis:**
```bash
# Check DNS resolution
dig +short mt5.yourdomain.com

# Should return your server's public IP
curl ifconfig.me
```

**Solution:**
1. Log into your domain registrar (GoDaddy, Namecheap, etc.)
2. Add/Update A record:
   ```
   Host: mt5
   Type: A
   Value: YOUR_SERVER_IP
   TTL: 300 (5 minutes)
   ```
3. Wait 5-15 minutes for DNS propagation
4. Verify: `dig +short mt5.yourdomain.com`
5. Retry Let's Encrypt setup

---

### Error: Rate Limit Exceeded

**Symptom:**
```
too many failed authorizations recently
```

**Cause:** Let's Encrypt has rate limits:
- 5 failed validations per hour
- 50 certificates per domain per week

**Solution:**
```bash
# Wait 1 hour before retrying

# Or use staging server for testing (doesn't count toward limits)
docker compose run --rm certbot certonly \
  --staging \
  --webroot \
  --webroot-path=/var/www/certbot \
  -d mt5.yourdomain.com

# Once successful, remove --staging for production certificate
```

---

### Certificate Expiring Soon

**Symptom:**
```
Certificate expires in X days
```

**Check Auto-Renewal:**
```bash
# Check certbot container is running
docker compose ps | grep certbot

# View renewal logs
docker compose logs certbot | grep -i renew

# Test renewal
docker compose run --rm certbot renew --dry-run
```

**Manual Renewal:**
```bash
# Force renewal now
docker compose run --rm certbot renew --force-renewal

# Restart nginx to use new certificate
docker compose restart nginx
```

---

## Multiple Domains

To secure multiple domains with one installation:

```bash
# During installation or via script
./scripts/setup-letsencrypt.sh \
  mt5.domain1.com \
  mt5.domain2.com \
  trading.domain3.com

# Or via certbot directly
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email admin@domain.com \
  --agree-tos \
  -d mt5.domain1.com \
  -d mt5.domain2.com \
  -d trading.domain3.com
```

---

## Wildcard Certificates

For covering all subdomains (*.yourdomain.com):

```bash
# Requires DNS challenge (cannot use webroot)
docker compose run --rm certbot certonly \
  --manual \
  --preferred-challenges dns \
  -d *.yourdomain.com

# You'll need to add TXT records to your DNS:
# _acme-challenge.yourdomain.com TXT "validation-string"
```

---

## Migration from Self-Signed

If you're currently using self-signed certificates:

```bash
cd ~/XQuantify-TradeStation

# 1. Run Let's Encrypt setup
./scripts/setup-letsencrypt.sh mt5.yourdomain.com

# 2. Old self-signed certs are backed up automatically to:
#    nginx/ssl/cert.pem.backup
#    nginx/ssl/privkey.pem.backup

# 3. Update your bookmarks/links to use domain instead of IP:
#    Old: https://107.150.25.53:8443/vnc.html
#    New: https://mt5.yourdomain.com:8443/vnc.html

# 4. Access new URL - no browser warning!
```

---

## Advanced Configuration

### Custom Renewal Schedule

Default renewal checks twice daily. To customize:

```yaml
# docker-compose.yml
certbot:
  image: certbot/certbot:latest
  command: >
    sh -c "while :; do
      certbot renew --deploy-hook 'nginx -s reload';
      sleep 12h;  # Change to 24h for daily, 168h for weekly
    done"
```

### Nginx Configuration

Let's Encrypt certificates are automatically configured. To view/modify:

```bash
# View nginx SSL configuration
docker exec xquantify-tradestation-nginx cat /etc/nginx/nginx.conf | grep -A 20 "ssl_certificate"

# Custom SSL settings (edit nginx/nginx.conf)
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers HIGH:!aNULL:!MD5;
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
```

---

## Security Best Practices

1. **Keep email updated** - Renewal notifications are critical
2. **Monitor expiration** - Check certificates monthly
3. **Test renewals** - Run dry-run quarterly
4. **Backup certificates** - Stored in `nginx/certbot/conf/`
5. **Use strong ciphers** - Default config is secure
6. **Enable HSTS** - Already configured in nginx
7. **Regular updates** - Keep certbot container updated

---

## Cost Comparison

| Provider | Cost/Year | Auto-Renew | Browser Trust | Setup |
|----------|-----------|------------|---------------|-------|
| **Let's Encrypt** | 🆓 **FREE** | ✅ Yes | ✅ Yes | ✅ Automated |
| Paid SSL (Basic) | $50-100 | ⚠️ Manual | ✅ Yes | ⚠️ Manual |
| Paid SSL (Wildcard) | $100-300 | ⚠️ Manual | ✅ Yes | ⚠️ Manual |
| Self-Signed | 🆓 FREE | ❌ No | ❌ No | ⚠️ Manual |

**Let's Encrypt saves you $50-300 per year while providing the same security!**

---

## Quick Reference Commands

```bash
# Initial setup
./scripts/setup-letsencrypt.sh mt5.yourdomain.com

# Check certificate
openssl s_client -connect mt5.yourdomain.com:8443

# View certificate details
docker compose run --rm certbot certificates

# Test renewal (dry run)
docker compose run --rm certbot renew --dry-run

# Force renewal
docker compose run --rm certbot renew --force-renewal

# View logs
docker compose logs certbot

# Restart nginx after changes
docker compose restart nginx

# Check DNS
dig +short mt5.yourdomain.com

# Check ports
sudo ss -tlnp | grep -E ':(80|443|8080|8443)'
```

---

## Support

**Issues?**
- Check logs: `docker compose logs certbot`
- Verify DNS: `dig mt5.yourdomain.com`
- Test ports: `sudo ss -tlnp | grep :80`
- Review: [Let's Encrypt Status](https://letsencrypt.status.io/)

**Resources:**
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Certbot Documentation](https://certbot.eff.org/docs/)
- [Rate Limits](https://letsencrypt.org/docs/rate-limits/)

---

## Summary

Let's Encrypt provides **professional, trusted SSL certificates for FREE** with:
- ✅ No browser security warnings
- ✅ Automatic renewal every 90 days
- ✅ Industry-standard encryption
- ✅ Perfect for production deployments
- ✅ Saves $50-300/year vs paid certificates

**Recommended for all production deployments of XQuantify TradeStation!**
