# 🆓 Alibaba Cloud FREE TIER Deployment Guide

## ✅ What's Available for NEW Users (2024)

### Free Trial Benefits (Activate in Console)
New accounts get **12 months free tier** + **$300-$1200 credits** (varies by region/promotion):

1. **ECS Free Tier**: 
   - 1x ecs.t5/t6 burstable instance (2 vCPU, 2GB RAM)
   - 40GB SSD storage
   - 1TB data transfer
   - **Value: ~$50/month FREE**

2. **RDS MySQL Free Tier**:
   - 1x mysql.n2.micro.1c (1 vCPU, 1GB RAM)
   - 20GB storage
   - **Value: ~$30/month FREE**

3. **OSS Free Tier**:
   - 50GB storage
   - 10GB download traffic
   - **Value: ~$10/month FREE**

4. **SAE (Serverless App Engine)**:
   - ⚠️ **NOT in free tier** but pay-per-use (~$0.01/hour when idle)
   - Best for testing, scales to zero

5. **ACR (Container Registry)**:
   - Personal edition FREE (up to 500MB storage)
   - Enough for 2-3 small images

---

## 💰 COST-OPTIMIZED Deployment Strategy

### Option A: **FREE TIER ECS** (Recommended for Testing)
**Cost: $0/month for 12 months**

```bash
# Resources you'll use:
- 1x ECS t5/t6 instance (2 vCPU, 2GB) - FREE
- 1x RDS MySQL micro (1 vCPU, 1GB) - FREE  
- 1x ACR Personal edition - FREE
- Total: $0/month
```

**Pros:**
- Completely free for 12 months
- Full control
- Easy to upgrade later

**Cons:**
- Manual setup (no auto-scaling)
- Limited resources (but enough for dev/testing)

### Option B: **SAE Pay-Per-Use** (Best for Variable Traffic)
**Cost: ~$5-15/month for low traffic**

```bash
# Estimated costs:
- SAE instance (0.5 vCPU, 1GB): $0.015/hour when running
- If app runs 24/7: ~$10/month
- If app scales to zero at night: ~$3-5/month
- RDS MySQL: Use free tier or pay ~$15/month
- Total: $5-25/month
```

**Pros:**
- Auto-scales to zero (save money at night)
- No server management
- Built-in load balancing

**Cons:**
- Not completely free
- Cold starts on first request

### Option C: **Hybrid Approach** (Best Balance)
**Cost: $0-5/month**

```bash
# Setup:
- ECS Free Tier: Run your backend 24/7 (FREE)
- RDS Free Tier: Database (FREE)
- OSS Free Tier: File storage (FREE)
- Only pay for extra bandwidth if >1TB
```

---

## 🚀 Step-by-Step: FREE TIER ECS Deployment

### Step 1: Activate Free Trial
1. Go to [Alibaba Cloud Console](https://home.console.aliyun.com/)
2. Search "Free Trial" or go to: https://www.alibabacloud.com/campaign/free-trial
3. Click "Activate Now"
4. Complete identity verification (required)

### Step 2: Create Free Resources

#### A. Create VPC (Free)
```bash
# In Console: VPC > Create VPC
- Name: estateflow-vpc
- CIDR: 192.168.0.0/16
- Region: Choose closest to you (e.g., ap-southeast-1 for Singapore)
```

#### B. Create ECS (Free Tier)
```bash
# In Console: ECS > Create Instance
- Region: Same as VPC
- Instance Type: ecs.t5/t6-lc1m2.small (2 vCPU, 2GB) ← MUST select this for free tier
- Image: Ubuntu 22.04 or Alibaba Cloud Linux 3
- Storage: 40GB ESSD (free tier limit)
- Network: Select your VPC
- Security Group: Allow ports 22, 80, 443, 3000
- Login: Set SSH key or password
```

#### C. Create RDS MySQL (Free Tier)
```bash
# In Console: RDS > Create Instance
- Engine: MySQL 8.0
- Edition: Basic (not High Availability)
- Instance Type: mysql.n2.micro.1c (1 vCPU, 1GB) ← MUST select this
- Storage: 20GB SSD
- VPC: Same as ECS
- Whitelist: Add ECS private IP
```

#### D. Create ACR (Free)
```bash
# In Console: Container Registry > Create Instance
- Edition: Personal (Free)
- Name: estateflow-acr
- Region: Same as ECS
```

### Step 3: Deploy Your App

#### On ECS Instance:
```bash
# SSH into ECS
ssh root@<ecs-public-ip>

# Install Docker
curl -fsSL https://get.docker.com | bash
systemctl enable docker
systemctl start docker

# Login to ACR
docker login --username=<your-alibaba-account> registry.<region>.aliyuncs.com

# Build & Push Image
cd /workspace
docker build -t registry.<region>.aliyuncs.com/<namespace>/estateflow:latest .
docker push registry.<region>.aliyuncs.com/<namespace>/estateflow:latest

# Run Container
docker run -d \
  --name estateflow \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e DATABASE_URL=mysql://user:pass@<rds-private-ip>:3306/estateflow \
  -e JWT_SECRET=<your-secret> \
  -e OSS_BUCKET=<your-bucket> \
  -e OSS_REGION=<region> \
  -e OSS_ACCESS_KEY_ID=<key> \
  -e OSS_ACCESS_KEY_SECRET=<secret> \
  --restart unless-stopped \
  registry.<region>.aliyuncs.com/<namespace>/estateflow:latest
```

### Step 4: Configure SLB (Optional - Free for first month)
```bash
# In Console: SLB > Create Load Balancer
- Type: Application Load Balancer
- Region: Same as ECS
- Specification: slb.s1.small (free tier eligible)
- Backend: Add your ECS instance on port 3000
- Health Check: /api/health
- Listener: Port 80 → Backend 3000
```

---

## 🔧 Environment Variables Setup

### In ECS Console (Recommended):
1. Go to ECS > Instances
2. Select your instance
3. Click "More" > "Cloud Assistant" > "Set Parameters"
4. Add all environment variables there

### Or use Docker Compose on ECS:
Create `/root/docker-compose.yml`:
```yaml
version: '3.8'
services:
  estateflow:
    image: registry.<region>.aliyuncs.com/<namespace>/estateflow:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=mysql://user:pass@rds-ip:3306/estateflow
      - JWT_SECRET=${JWT_SECRET}
      - OSS_ACCESS_KEY_ID=${OSS_ACCESS_KEY_ID}
      - OSS_ACCESS_KEY_SECRET=${OSS_ACCESS_KEY_SECRET}
      - OSS_BUCKET=${OSS_BUCKET}
      - OSS_REGION=${OSS_REGION}
      - SERVER_URL=http://<slb-ip-or-domain>
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

Deploy:
```bash
docker-compose up -d
```

---

## 📊 Cost Monitoring

### Set Up Billing Alerts:
1. Go to User Center > Billing Management
2. Click "Budget Settings"
3. Create budget: $10/month (or your limit)
4. Set email alerts at 50%, 80%, 100%

### Monitor Usage:
```bash
# In Console: User Center > Bills
# Check daily to ensure you're within free tier limits
```

---

## ⚠️ Important Notes

### Free Tier Limits:
- **ECS**: 1 instance per account (t5/t6 only)
- **RDS**: 1 instance per account (micro only)
- **OSS**: 50GB total storage
- **ACR**: 500MB storage (personal edition)
- **SLB**: First month free, then ~$5/month for smallest

### Avoid Unexpected Charges:
1. ✅ Stop ECS when not testing (don't delete, just "Stop")
2. ✅ Use monitoring to track usage
3. ✅ Delete unused OSS objects
4. ✅ Don't upgrade instance types accidentally
5. ✅ Check bills weekly

### When Ready for Production:
- Upgrade ECS to compute-optimized (c6/c7)
- Upgrade RDS to High Availability edition
- Add SLB for load balancing
- Enable auto-scaling
- Add Redis cache (ApsaraDB for Redis has free tier too!)

---

## 🎯 Recommended Path for You

**Phase 1 (Month 1-3): FREE TIER**
```
ECS t5/t6 (FREE) + RDS micro (FREE) + ACR personal (FREE)
Total: $0/month
Purpose: Development & Testing
```

**Phase 2 (Month 4-6): MINIMAL PAID**
```
ECS t5/t6 (FREE) + RDS micro (FREE) + SLB ($5/month)
Total: ~$5/month
Purpose: Beta testing with real users
```

**Phase 3 (Production): SCALE AS NEEDED**
```
Option A: ECS c6 (2 vCPU, 4GB) + RDS HA + SLB + Auto-scaling
          ~$50-80/month

Option B: SAE (pay-per-use) + RDS HA + SLB
          ~$30-60/month (variable traffic)
```

---

## 🆘 Need Help?

### Alibaba Cloud Support:
- Free tier includes basic support
- Submit tickets in Console > Support > Tickets
- Response time: 24 hours for free tier

### Community Resources:
- Alibaba Cloud Developer Forum: https://develop.aliyun.com/
- GitHub Issues: Report deployment issues
- Documentation: https://www.alibabacloud.com/help

---

## ✅ Quick Checklist

- [ ] Activate Free Trial in console
- [ ] Complete identity verification
- [ ] Create VPC
- [ ] Create ECS (t5/t6 instance)
- [ ] Create RDS (mysql.n2.micro.1c)
- [ ] Create ACR (personal edition)
- [ ] Build & push Docker image
- [ ] Deploy to ECS
- [ ] Set environment variables
- [ ] Test endpoint
- [ ] Set billing alerts
- [ ] Monitor usage daily

**You can run this entire setup for $0 for 12 months!** 🎉
