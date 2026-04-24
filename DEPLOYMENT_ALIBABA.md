# Alibaba Cloud Deployment Guide for Estate Manager App

## Overview
This guide covers deployment to Alibaba Cloud using Container Service for Kubernetes (ACK) or Elastic Compute Service (ECS) with Container Registry (ACR).

## Prerequisites
- Alibaba Cloud account
- Alibaba Cloud CLI installed (`aliyun`)
- Docker installed locally
- kubectl configured (for ACK deployment)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Alibaba Cloud VPC                         │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   SLB/ALB    │───▶│   ACK/ECS    │───▶│   ACR        │  │
│  │ (Load Balancer)│  │ (Containers) │    │ (Registry)   │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                   │                               │
│         │            ┌──────┴──────┐                       │
│         │            │  RDS MySQL  │                       │
│         │            │ (Database)  │                       │
│         │            └─────────────┘                       │
│         │                                                  │
│  ┌──────┴──────┐                                          │
│  │   OSS       │                                          │
│  │ (Storage)   │                                          │
│  └─────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
```

## Environment Variables (Alibaba Cloud Configuration)

All sensitive data should be stored in Alibaba Cloud environment variables:

### For ECS with Container Service:
```bash
# In ECS Instance or Container Service Console
export DATABASE_URL=mysql://user:password@rm-xxx.mysql.rds.aliyuncs.com:3306/estate_db
export JWT_SECRET=${your_jwt_secret_from_secrets_manager}
export APP_ENV=production
export PORT=8080
export ALIBABA_CLOUD_ACCESS_KEY_ID=${access_key}
export ALIBABA_CLOUD_ACCESS_KEY_SECRET=${secret_key}
export OSS_BUCKET=estate-manager-assets
export OSS_REGION=cn-hangzhou
export OSS_ENDPOINT=oss-cn-hangzhou.aliyuncs.com
```

### For ACK (Kubernetes):
Use Kubernetes Secrets and ConfigMaps (see k8s-deployment.yaml)

## Deployment Steps

### Option 1: Deploy to Alibaba Cloud Container Registry (ACR) + ACK

#### Step 1: Build and Push to ACR
```bash
# Login to Alibaba Cloud
aliyun login --AccessKeyId=<YOUR_ACCESS_KEY> --AccessKeySecret=<YOUR_SECRET_KEY>

# Login to ACR
docker login --username=<YOUR_ACR_USERNAME> registry.cn-hangzhou.aliyuncs.com

# Build image
docker build -t registry.cn-hangzhou.aliyuncs.com/<YOUR_NAMESPACE>/estate-manager:latest .

# Push to ACR
docker push registry.cn-hangzhou.aliyuncs.com/<YOUR_NAMESPACE>/estate-manager:latest
```

#### Step 2: Deploy to ACK
```bash
# Apply Kubernetes configurations
kubectl apply -f k8s-configmap.yaml
kubectl apply -f k8s-secret.yaml
kubectl apply -f k8s-deployment.yaml
kubectl apply -f k8s-service.yaml
kubectl apply -f k8s-ingress.yaml
```

### Option 2: Deploy to ECS with Docker

#### Step 1: Setup ECS Instance
1. Create ECS instance (Ubuntu 22.04 or Alibaba Cloud Linux 3)
2. Install Docker:
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

#### Step 2: Pull and Run Container
```bash
# Login to ACR
docker login --username=<YOUR_ACR_USERNAME> registry.cn-hangzhou.aliyuncs.com

# Pull image
docker pull registry.cn-hangzhou.aliyuncs.com/<YOUR_NAMESPACE>/estate-manager:latest

# Run container with environment variables from Alibaba Cloud
docker run -d \
  --name estate-manager \
  --restart unless-stopped \
  -p 8080:8080 \
  -e NODE_ENV=production \
  -e DATABASE_URL=${DATABASE_URL} \
  -e JWT_SECRET=${JWT_SECRET} \
  -e ALIBABA_CLOUD_ACCESS_KEY_ID=${ALIBABA_CLOUD_ACCESS_KEY_ID} \
  -e ALIBABA_CLOUD_ACCESS_KEY_SECRET=${ALIBABA_CLOUD_ACCESS_KEY_SECRET} \
  -e OSS_BUCKET=${OSS_BUCKET} \
  -e OSS_REGION=${OSS_REGION} \
  registry.cn-hangzhou.aliyuncs.com/<YOUR_NAMESPACE>/estate-manager:latest
```

### Option 3: Deploy to Serverless App Engine (SAE)

1. Package application:
```bash
docker build -t estate-manager .
docker save estate-manager > estate-manager.tar
```

2. Upload to OSS and deploy via SAE console or CLI:
```bash
aliyun sae CreateApplication \
  --AppName estate-manager \
  --ImageTag registry.cn-hangzhou.aliyuncs.com/<YOUR_NAMESPACE>/estate-manager:latest \
  --Cpu 2000 \
  --Memory 4096 \
  --MinReplicas 2 \
  --MaxReplicas 5 \
  --Env "[{\"key\":\"NODE_ENV\",\"value\":\"production\"},{\"key\":\"DATABASE_URL\",\"value\":\"${DATABASE_URL}\"}]"
```

## Database Setup (ApsaraDB RDS for MySQL)

1. Create RDS instance in Alibaba Cloud Console
2. Configure whitelist for ECS/ACK security group
3. Create database and user:
```sql
CREATE DATABASE estate_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'estate_user'@'%' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON estate_db.* TO 'estate_user'@'%';
FLUSH PRIVILEGES;
```

4. Run migrations:
```bash
# From your deployment environment
pnpm run db:push
```

## Storage Setup (OSS - Object Storage Service)

1. Create OSS bucket in Alibaba Cloud Console
2. Configure CORS for mobile app access
3. Set up lifecycle rules for cost optimization

## Monitoring & Logging

### Enable Alibaba Cloud Monitor
- CPU, Memory, Disk metrics
- Custom metrics via CloudMonitor API

### Enable Log Service (SLS)
```yaml
# In k8s-deployment.yaml
volumeMounts:
  - name: log-volume
    mountPath: /var/log/app
volumes:
  - name: log-volume
    emptyDir: {}
```

### Application Health Check Endpoint
The Dockerfile includes a health check at `/health` endpoint for SLB health monitoring.

## Security Best Practices

1. **Use RAM Roles**: Assign RAM roles to ECS/ACK instead of hardcoded credentials
2. **Secrets Manager**: Store sensitive data in Alibaba Cloud Secrets Manager
3. **VPC Isolation**: Deploy all resources in private VPC subnets
4. **Security Groups**: Restrict inbound traffic to necessary ports only
5. **SSL/TLS**: Use Alibaba Cloud SSL certificates for HTTPS
6. **WAF**: Enable Web Application Firewall for DDoS protection

## Cost Optimization

1. Use preemptible instances for non-critical workloads
2. Enable auto-scaling based on traffic patterns
3. Use OSS lifecycle policies to archive old data
4. Monitor resource usage with Cost Center

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Deploy to Alibaba Cloud
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to ACR
        uses: docker/login-action@v2
        with:
          registry: registry.cn-hangzhou.aliyuncs.com
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}
      
      - name: Build and Push
        run: |
          docker build -t registry.cn-hangzhou.aliyuncs.com/${{ secrets.ACR_NAMESPACE }}/estate-manager:${{ github.sha }} .
          docker push registry.cn-hangzhou.aliyuncs.com/${{ secrets.ACR_NAMESPACE }}/estate-manager:${{ github.sha }}
      
      - name: Deploy to ACK
        uses: azure/k8s-deploy@v4
        with:
          manifests: |
            k8s-deployment.yaml
          images: |
            registry.cn-hangzhou.aliyuncs.com/${{ secrets.ACR_NAMESPACE }}/estate-manager:${{ github.sha }}
```

## Troubleshooting

### Common Issues

1. **Container fails to start**
   - Check environment variables are properly set
   - Verify database connectivity
   - Review logs: `docker logs estate-manager`

2. **Database connection errors**
   - Ensure RDS whitelist includes ECS/ACK IP
   - Verify DATABASE_URL format
   - Check RDS instance status

3. **OSS access denied**
   - Verify RAM role permissions
   - Check OSS bucket policy
   - Ensure correct region endpoint

## Support Resources

- [Alibaba Cloud Documentation](https://www.alibabacloud.com/help)
- [Container Service for Kubernetes](https://www.alibabacloud.com/product/kubernetes)
- [Container Registry](https://www.alibabacloud.com/product/container-registry)
- [RDS MySQL](https://www.alibabacloud.com/product/apsaradb-for-rds)
- [Object Storage Service](https://www.alibabacloud.com/product/object-storage-service)
