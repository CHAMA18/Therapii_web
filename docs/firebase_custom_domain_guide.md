# Adding a Custom Domain to Firebase Hosting

> A step-by-step guide to connect your own domain (e.g., `yourapp.com`) to your Firebase-hosted application.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Access Firebase Hosting](#step-1-access-firebase-hosting)
3. [Step 2: Add Your Custom Domain](#step-2-add-your-custom-domain)
4. [Step 3: Verify Domain Ownership](#step-3-verify-domain-ownership)
5. [Step 4: Configure DNS Records](#step-4-configure-dns-records)
6. [Step 5: Wait for SSL Provisioning](#step-5-wait-for-ssl-provisioning)
7. [Common DNS Provider Instructions](#common-dns-provider-instructions)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

---

## Prerequisites

Before you begin, ensure you have:

- ✅ A Firebase project with Hosting enabled
- ✅ Your app deployed to Firebase Hosting at least once
- ✅ A registered domain name (e.g., from GoDaddy, Namecheap, Google Domains, Cloudflare, etc.)
- ✅ Access to your domain registrar's DNS settings
- ✅ Owner or Editor permissions on the Firebase project

---

## Step 1: Access Firebase Hosting

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. In the left sidebar, click **Hosting** under the "Build" section
4. You'll see your default Firebase domain (e.g., `your-project.web.app`)

---

## Step 2: Add Your Custom Domain

1. On the Hosting page, click the **"Add custom domain"** button
2. Enter your domain name in one of these formats:
   - **Root domain:** `yourdomain.com`
   - **Subdomain:** `app.yourdomain.com` or `www.yourdomain.com`
3. Click **Continue**

### 💡 Tip: Add Both Root and WWW

It's recommended to add both `yourdomain.com` and `www.yourdomain.com`:
- Add the root domain first
- When adding `www`, Firebase will offer to redirect it to your root domain (or vice versa)

---

## Step 3: Verify Domain Ownership

Firebase needs to verify that you own the domain. You have two verification options:

### Option A: TXT Record Verification (Recommended)

1. Firebase will provide a **TXT record** with a unique verification code
2. Copy this TXT record value
3. Go to your domain registrar's DNS settings
4. Add a new **TXT record**:
   - **Host/Name:** `@` (or leave blank for root domain)
   - **Value:** The verification code from Firebase
   - **TTL:** 3600 (or default)
5. Return to Firebase and click **Verify**

### Option B: Existing Website Verification

If you already have a website at that domain:
1. Download the verification file Firebase provides
2. Upload it to your current web server's root directory
3. Click **Verify** in Firebase

> ⏱️ **Note:** DNS changes can take anywhere from a few minutes to 48 hours to propagate. Most changes complete within 1-2 hours.

---

## Step 4: Configure DNS Records

After verification, Firebase will provide DNS records to point your domain to Firebase Hosting.

### For Root Domains (yourdomain.com)

Add **A records** pointing to Firebase's IP addresses:

| Type | Host/Name | Value |
|------|-----------|-------|
| A | @ | `151.101.1.195` |
| A | @ | `151.101.65.195` |

> **Note:** Firebase may provide different IP addresses. Always use the IPs shown in your Firebase Console.

### For Subdomains (app.yourdomain.com)

Add a **CNAME record**:

| Type | Host/Name | Value |
|------|-----------|-------|
| CNAME | app | `your-project.web.app` |

### For WWW Subdomain

If you want `www.yourdomain.com`:

| Type | Host/Name | Value |
|------|-----------|-------|
| CNAME | www | `your-project.web.app` |

---

## Step 5: Wait for SSL Provisioning

After configuring DNS records:

1. Return to Firebase Console → Hosting
2. You'll see your domain with status: **"Pending"** or **"Needs setup"**
3. Firebase will automatically:
   - Detect your DNS configuration
   - Provision a free SSL certificate (via Let's Encrypt)
   - Mark your domain as **"Connected"**

### SSL Provisioning Timeline

| Status | Meaning | Typical Duration |
|--------|---------|------------------|
| 🟡 Needs setup | DNS not yet detected | — |
| 🟡 Pending | DNS detected, SSL provisioning | 15 min - 24 hours |
| 🟢 Connected | Fully configured and live | — |

> ⏱️ **Patience Required:** SSL provisioning usually completes within 15-30 minutes but can take up to 24 hours in some cases.

---

## Common DNS Provider Instructions

### GoDaddy

1. Log in to [GoDaddy](https://www.godaddy.com/)
2. Go to **My Products** → **Domains** → Select your domain
3. Click **DNS** or **Manage DNS**
4. Click **Add** to add new records
5. Select record type (A, CNAME, or TXT)
6. Enter the values from Firebase
7. Save changes

### Namecheap

1. Log in to [Namecheap](https://www.namecheap.com/)
2. Go to **Domain List** → Click **Manage** next to your domain
3. Click **Advanced DNS** tab
4. Click **Add New Record**
5. Select record type and enter Firebase values
6. Save changes

### Cloudflare

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Select your domain
3. Go to **DNS** → **Records**
4. Click **Add record**
5. Enter the record type and values
6. **Important:** Set proxy status to **DNS only** (gray cloud) for A records
7. Save

> ⚠️ **Cloudflare Users:** Disable Cloudflare's proxy (orange cloud) for your A records pointing to Firebase. Use "DNS only" mode to allow Firebase's SSL certificate to work properly.

### Google Domains

1. Go to [Google Domains](https://domains.google.com/)
2. Select your domain
3. Click **DNS** in the left menu
4. Scroll to **Custom records**
5. Click **Manage custom records**
6. Add the required records
7. Save

### AWS Route 53

1. Open [Route 53 Console](https://console.aws.amazon.com/route53/)
2. Go to **Hosted zones** → Select your domain
3. Click **Create record**
4. Choose **Simple routing**
5. Enter record name and values
6. Create records

---

## Troubleshooting

### Domain Stuck on "Pending"

**Possible causes and solutions:**

1. **DNS not propagated yet**
   - Use [DNS Checker](https://dnschecker.org/) to verify your records
   - Wait up to 48 hours for full propagation

2. **Incorrect DNS values**
   - Double-check you've entered the exact values from Firebase
   - Ensure no trailing periods or spaces

3. **Conflicting records**
   - Remove any existing A or AAAA records for the same host
   - Remove conflicting CNAME records

4. **Cloudflare proxy enabled**
   - Switch to "DNS only" (gray cloud) for A records

### SSL Certificate Issues

**"Certificate provisioning in progress"**
- This is normal; wait 15-60 minutes
- If it persists beyond 24 hours, check DNS configuration

**"Certificate error"**
- Verify DNS records are correct
- Ensure no CDN or proxy is intercepting traffic
- Try removing and re-adding the domain

### Domain Shows "Needs Setup"

- Firebase hasn't detected your DNS changes yet
- Verify records are correctly configured
- Allow more time for DNS propagation

### ERR_SSL_VERSION_OR_CIPHER_MISMATCH

- SSL certificate not yet provisioned
- Wait for Firebase to complete SSL setup
- Clear browser cache and try again

---

## Best Practices

### 1. Set Up Both WWW and Non-WWW

- Add both `yourdomain.com` and `www.yourdomain.com`
- Configure one to redirect to the other for consistency
- Firebase offers this option during setup

### 2. Use Meaningful Subdomains

For multiple environments:
- `app.yourdomain.com` → Production
- `staging.yourdomain.com` → Staging
- `beta.yourdomain.com` → Beta testing

### 3. Monitor SSL Expiration

- Firebase auto-renews SSL certificates
- Ensure DNS records remain correctly configured
- Check Hosting dashboard periodically

### 4. Keep DNS TTL Low During Setup

- Set TTL to 300 (5 minutes) during initial setup
- Increase to 3600+ (1 hour) after everything works
- Lower TTL = faster propagation of changes

### 5. Document Your Configuration

Keep a record of:
- DNS records you've added
- Original DNS settings (before changes)
- Firebase project details

---

## Quick Reference Card

### DNS Records Summary

| Domain Type | Record Type | Host | Value |
|-------------|-------------|------|-------|
| Root | TXT | @ | (Verification code) |
| Root | A | @ | Firebase IP #1 |
| Root | A | @ | Firebase IP #2 |
| Subdomain | CNAME | subdomain | project.web.app |
| WWW | CNAME | www | project.web.app |

### Useful Tools

- **DNS Propagation Check:** [dnschecker.org](https://dnschecker.org/)
- **DNS Lookup:** [mxtoolbox.com](https://mxtoolbox.com/DNSLookup.aspx)
- **SSL Test:** [ssllabs.com/ssltest](https://www.ssllabs.com/ssltest/)
- **Firebase Status:** [status.firebase.google.com](https://status.firebase.google.com/)

---

## Need Help?

- **Firebase Documentation:** [firebase.google.com/docs/hosting/custom-domain](https://firebase.google.com/docs/hosting/custom-domain)
- **Firebase Support:** [firebase.google.com/support](https://firebase.google.com/support)
- **Stack Overflow:** Tag questions with `firebase-hosting`

---

*Last updated: 2025*
