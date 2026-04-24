# Alibaba Cloud Deployment Quick Start Guide

## 🆓 NEW USER? START HERE FOR FREE!

**Your new account includes 12 months FREE TIER!**

### ⭐ Option 1: FREE TIER ECS (RECOMMENDED FOR NEW ACCOUNTS)
**Cost: $0/month for 12 months**

Perfect for testing and development with zero cost!

**What you get FREE:**
- 1x ECS t5/t6 instance (2 vCPU, 2GB RAM)
- 1x RDS MySQL micro (1 vCPU, 1GB)  
- 1x ACR Personal edition (500MB)
- 40GB storage + 1TB transfer

**Quick Deploy:**
```bash
chmod +x deploy-free-tier.sh
./deploy-free-tier.sh
```

📖 **Full Guide:** See `FREE_TIER_DEPLOYMENT.md`

---

## 🏆 BEST FOR PRODUCTION: SAE (Serverless App Engine)

**Alibaba's equivalent to AWS App Runner** - fully managed, auto-scaling!

**Cost:** ~$5-15/month (pay-per-use, scales to zero)

**See `DEPLOY_SAE_BEST_PRACTICE.md` for complete SAE deployment guide!**

---

## All Deployment Options

### Comparison Table

| Feature | FREE TIER ECS | SAE Serverless | ACK Kubernetes |
|---------|--------------|----------------|----------------|
| **Cost** | $0 (12 months) | ~$5-15/month | ~$30-50/month |
| **Setup Time** | 10 minutes | 5 minutes | 30+ minutes |
| **Management** | Manual | Zero | Complex |
| **Auto-scaling** | No | Yes | Yes |
| **Best For** | Testing/Dev | Production | Enterprise |
| **Cold Starts** | N/A | Yes (~2s) | No |

---

## Prerequisites

1. **Alibaba Cloud Account** - Sign up at [alibabacloud.com](https://www.alibabacloud.com)
2. **Free Trial Activated** - Go to https://www.alibabacloud.com/campaign/free-trial
3. **Identity Verification** - Required for free tier
4. **Docker** - Installed locally for building images
5. **SSH Key** - Created in ECS console (for ECS deployment)

## Quick Deployment Options

### ⭐ Option 0: SAE Serverless (BEST - See DEPLOY_SAE_BEST_PRACTICE.md)

```bash
# 1. Build Docker image
docker build -t estate-manager .

# 2. Login to Alibaba Cloud Container Registry (ACR)
docker login --username=<YOUR_ACR_USERNAME> registry.cn-hangzhou.aliyuncs.com

# 3. Tag and push image
docker tag estate-manager registry.cn-hangzhou.aliyuncs.com/<YOUR_NAMESPACE>/estate-manager:latest
docker push registry.cn-hangzhou.aliyuncs.com/<YOUR_NAMESPACE>/estate-manager:latest

# 4. On your ECS instance, pull and run
docker run -d \
  --name estate-manager \
  --restart unless-stopped \
  -p 8080:8080 \
  -e NODE_ENV=production \
  -e DATABASE_URL=mysql://user:pass@rm-xxx.mysql.rds.aliyuncs.com:3306/estate_db \
  -e JWT_SECRET=${JWT_SECRET} \
  registry.cn-hangzhou.aliyuncs.com/<YOUR_NAMESPACE>/estate-manager:latest
```

### Option 2: Terraform Infrastructure Deployment

```bash
cd terraform

# 1. Copy variables file
cp terraform.tfvars.example terraform.tfvars

# 2. Edit terraform.tfvars with your values
# - Add access_key, secret_key, db_password

# 3. Initialize Terraform
terraform init

# 4. Preview changes
terraform plan

# 5. Deploy infrastructure
terraform apply

# 6. Get outputs (SLB IP, RDS connection string, etc.)
terraform output
```

### Option 3: Kubernetes (ACK) Deployment

```bash
# 1. Build and push to ACR (same as Option 1)

# 2. Update k8s files with your ACR image path
# Edit k8s-deployment.yaml: image: registry.cn-hangzhou.aliyuncs.com/YOUR_NAMESPACE/estate-manager:latest

# 3. Apply Kubernetes configurations
kubectl apply -f k8s-configmap.yaml
kubectl apply -f k8s-secret.yaml
kubectl apply -f k8s-deployment.yaml
kubectl apply -f k8s-service.yaml
kubectl apply -f k8s-ingress.yaml

# 4. Verify deployment
kubectl get pods
kubectl get services
kubectl get ingress
```

## Environment Variables Setup

All sensitive data must be set via Alibaba Cloud environment variables:

### For ECS:
In ECS Console → Instance → Environment Variables, or use Docker `-e` flags:

```bash
DATABASE_URL=mysql://user:password@rm-xxx.mysql.rds.aliyuncs.com:3306/estate_db
JWT_SECRET=your_jwt_secret_min_32_chars
ALIBABA_CLOUD_ACCESS_KEY_ID=your_access_key
ALIBABA_CLOUD_ACCESS_KEY_SECRET=your_secret_key
OSS_BUCKET=estate-manager-assets
OSS_REGION=cn-hangzhou
NODE_ENV=production
PORT=8080
```

### For ACK:
Edit `k8s-secret.yaml` with your actual values, then apply:
```bash
kubectl apply -f k8s-secret.yaml
```

## Database Setup

1. Create RDS MySQL instance in Alibaba Cloud Console
2. Set whitelist to allow ECS/ACK security group
3. Create database:
```sql
CREATE DATABASE estate_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```
4. Run migrations from your deployment:
```bash
pnpm run db:push
```

## Storage Setup (OSS)

1. Create OSS bucket in console
2. Configure CORS for mobile app access
3. Set bucket policy for private access
4. Use RAM roles for ECS/ACK to access OSS

## Monitoring

- **CloudMonitor**: CPU, memory, disk metrics
- **Log Service (SLS)**: Application logs
- **ARMS**: Application Real-Time Monitoring Service
- **SLB Health Checks**: `/health` endpoint

## Security Checklist

✅ All secrets in Alibaba Cloud Secrets Manager or environment variables  
✅ RDS whitelist restricted to VPC CIDR only  
✅ Security groups allow only necessary ports (80, 443, 8080)  
✅ OSS bucket set to private with RAM role access  
✅ SSL/TLS enabled via SLB  
✅ WAF enabled for DDoS protection  
✅ Regular backups enabled for RDS  

## Cost Estimation (Monthly - cn-hangzhou Region)

| Resource | Specification | Estimated Cost |
|----------|--------------|----------------|
| ECS | 2 vCPU, 4GB RAM | ~$30-50 |
| RDS MySQL | 2 vCPU, 4GB, 20GB SSD | ~$40-60 |
| SLB | Performance Guaranteed | ~$15-20 |
| OSS | 10GB storage + requests | ~$5-10 |
| NAT Gateway | Small | ~$15-20 |
| **Total** | | **~$105-160/month** |

*Prices vary by region and usage patterns*

## Troubleshooting

### Container won't start
```bash
docker logs estate-manager
# Check environment variables are set correctly
```

### Database connection failed
- Verify RDS whitelist includes your ECS/ACK IP
- Check DATABASE_URL format
- Ensure RDS instance is running

### OSS access denied
- Verify RAM role has OSS permissions
- Check bucket name and region
- Ensure correct endpoint URL

## Next Steps

1. Set up CI/CD pipeline (GitHub Actions, GitLab CI, or Alibaba Cloud Flow)
2. Configure auto-scaling based on traffic
3. Set up alerts in CloudMonitor
4. Enable backup and disaster recovery
5. Configure CDN for static assets

## Support Resources

- [Alibaba Cloud Documentation](https://www.alibabacloud.com/help)
- [Container Service](https://www.alibabacloud.com/product/kubernetes)
- [RDS MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds)
- [Community Forum](https://www.alibabacloud.com/community)
