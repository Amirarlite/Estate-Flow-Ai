#!/bin/bash

# 🚀 Alibaba Cloud FREE TIER Quick Deploy Script
# This script helps you deploy to ECS Free Tier in under 10 minutes

set -e

echo "🆓 Alibaba Cloud FREE TIER Deployment Helper"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration - UPDATE THESE VALUES
REGION="ap-southeast-1"  # Change to your region (e.g., us-west-1, eu-central-1)
INSTANCE_NAME="estateflow-ecs"
RDS_NAME="estateflow-rds"
ACR_NAME="estateflow-acr"
VPC_NAME="estateflow-vpc"
DOCKER_IMAGE_TAG="latest"

echo -e "${YELLOW}📋 Pre-deployment Checklist:${NC}"
echo "Before running this script, ensure you have:"
echo "  ✓ Alibaba Cloud account created"
echo "  ✓ Free trial activated (https://www.alibabacloud.com/campaign/free-trial)"
echo "  ✓ Identity verification completed"
echo "  ✓ RAM user with ECS, RDS, ACR permissions (or use root account)"
echo "  ✓ SSH key pair created in EC2 console"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

echo ""
echo -e "${GREEN}Step 1: Installing Required Tools${NC}"
echo "-------------------------------------------"

# Check if aliyun CLI is installed
if ! command -v aliyun &> /dev/null; then
    echo "Installing Alibaba Cloud CLI..."
    # For macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install aliyun-cli
    # For Linux
    else
        curl -LO https://aliyuncli.alicdn.com/aliyun-cli-linux-3.0.160-amd64.tgz
        tar -xzf aliyun-cli-linux-3.0.160-amd64.tgz
        sudo mv aliyun /usr/local/bin/
        rm aliyun-cli-linux-3.0.160-amd64.tgz
    fi
    echo -e "${GREEN}✓ Alibaba Cloud CLI installed${NC}"
else
    echo -e "${GREEN}✓ Alibaba Cloud CLI already installed${NC}"
fi

# Configure CLI
echo ""
echo "Configuring Alibaba Cloud CLI..."
echo "You'll need your AccessKey ID and Secret from:"
echo "  Console > User Center > AccessKey Management"
echo ""
aliyun configure

echo ""
echo -e "${GREEN}Step 2: Creating VPC${NC}"
echo "------------------------------------"

# Create VPC
VPC_ID=$(aliyun vpc CreateVpc \
    --RegionId $REGION \
    --VpcName $VPC_NAME \
    --CidrBlock 192.168.0.0/16 \
    --Description "VPC for EstateFlow free tier deployment" \
    --query 'VpcId' \
    --output text)

echo -e "${GREEN}✓ VPC Created: $VPC_ID${NC}"

# Create VSwitch
VSWITCH_ID=$(aliyun vpc CreateVSwitch \
    --RegionId $REGION \
    --VpcId $VPC_ID \
    --ZoneId ${REGION}a \
    --CidrBlock 192.168.1.0/24 \
    --VSwitchName estateflow-vswitch \
    --query 'VSwitchId' \
    --output text)

echo -e "${GREEN}✓ VSwitch Created: $VSWITCH_ID${NC}"

# Create Security Group
SG_ID=$(aliyun ecs CreateSecurityGroup \
    --RegionId $REGION \
    --VpcId $VPC_ID \
    --SecurityGroupName estateflow-sg \
    --Description "Security group for EstateFlow" \
    --query 'SecurityGroupId' \
    --output text)

echo -e "${GREEN}✓ Security Group Created: $SG_ID${NC}"

# Add security group rules
echo "Adding security group rules..."
aliyun ecs AuthorizeSecurityGroup \
    --RegionId $REGION \
    --SecurityGroupId $SG_ID \
    --IpProtocol tcp \
    --PortRange 22/22 \
    --SourceCidrIp 0.0.0.0/0 \
    --Description "SSH access"

aliyun ecs AuthorizeSecurityGroup \
    --RegionId $REGION \
    --SecurityGroupId $SG_ID \
    --IpProtocol tcp \
    --PortRange 3000/3000 \
    --SourceCidrIp 0.0.0.0/0 \
    --Description "App port"

aliyun ecs AuthorizeSecurityGroup \
    --RegionId $REGION \
    --SecurityGroupId $SG_ID \
    --IpProtocol tcp \
    --PortRange 80/80 \
    --SourceCidrIp 0.0.0.0/0 \
    --Description "HTTP"

aliyun ecs AuthorizeSecurityGroup \
    --RegionId $REGION \
    --SecurityGroupId $SG_ID \
    --IpProtocol tcp \
    --PortRange 443/443 \
    --SourceCidrIp 0.0.0.0/0 \
    --Description "HTTPS"

echo -e "${GREEN}✓ Security rules added${NC}"

echo ""
echo -e "${GREEN}Step 3: Creating ECS Instance (Free Tier)${NC}"
echo "------------------------------------------------------"

# Get latest Ubuntu 22.04 image ID
IMAGE_ID=$(aliyun ecs DescribeImages \
    --RegionId $REGION \
    --ImageOwnerAlias system \
    --Filter.1.Key OSName \
    --Filter.1.Value Ubuntu_22_04 \
    --query 'Images.Image[0].ImageId' \
    --output text)

# Create ECS instance (t5/t6 free tier)
INSTANCE_ID=$(aliyun ecs CreateInstance \
    --RegionId $REGION \
    --ImageId $IMAGE_ID \
    --InstanceType ecs.t5-lc1m2.small \
    --SecurityGroupId $SG_ID \
    --VSwitchId $VSWITCH_ID \
    --InstanceName $INSTANCE_NAME \
    --Description "EstateFlow backend - Free Tier" \
    --InternetChargeType PayByTraffic \
    --InternetMaxBandwidthOut 5 \
    --SystemDisk.Category cloud_essd \
    --SystemDisk.Size 40 \
    --QueryPrice true \
    --query 'InstanceId' \
    --output text)

echo -e "${GREEN}✓ ECS Instance Created: $INSTANCE_ID${NC}"

# Allocate public IP
aliyun ecs AllocatePublicIpAddress \
    --InstanceId $INSTANCE_ID \
    --RegionId $REGION

echo -e "${YELLOW}⏳ Waiting for instance to start (this takes 2-3 minutes)...${NC}"
sleep 30

# Start instance
aliyun ecs StartInstance \
    --InstanceId $INSTANCE_ID \
    --RegionId $REGION

echo -e "${GREEN}✓ ECS Instance starting...${NC}"

# Get public IP
PUBLIC_IP=$(aliyun ecs DescribeInstances \
    --RegionId $REGION \
    --InstanceIds "[\"$INSTANCE_ID\"]" \
    --query 'Instances.Instance[0].PublicIpAddress.IpAddress[0]' \
    --output text)

echo -e "${GREEN}✓ Public IP: $PUBLIC_IP${NC}"

echo ""
echo -e "${GREEN}Step 4: Creating RDS MySQL (Free Tier)${NC}"
echo "----------------------------------------------------"

# Create RDS instance
RDS_ID=$(aliyun rds CreateDBInstance \
    --RegionId $REGION \
    --Engine MySQL \
    --EngineVersion 8.0 \
    --DBInstanceClass mysql.n2.micro.1c \
    --DBInstanceStorage 20 \
    --DBInstanceNetType Intranet \
    --DBInstanceType Primary \
    --Category Basic \
    --SecurityIPList 0.0.0.0/0 \
    --PayType Postpaid \
    --Period 1 \
    --UsedTime 1 \
    --DBInstanceName $RDS_NAME \
    --VpcId $VPC_ID \
    --VSwitchId $VSWITCH_ID \
    --query 'DBInstanceId' \
    --output text)

echo -e "${GREEN}✓ RDS Instance Created: $RDS_ID${NC}"

echo -e "${YELLOW}⏳ Waiting for RDS to be ready (this takes 3-5 minutes)...${NC}"
echo "You can continue with next steps while waiting..."

echo ""
echo -e "${GREEN}Step 5: Creating Container Registry (Free)${NC}"
echo "---------------------------------------------------------"

# Create ACR instance (Personal Edition)
aliyun cr CreateInstance \
    --Namespace estateflow \
    --RegionId $REGION

echo -e "${GREEN}✓ Container Registry namespace created${NC}"

echo ""
echo -e "${GREEN}Step 6: Build & Push Docker Image${NC}"
echo "-------------------------------------------------"

echo "Building Docker image..."
docker build -t registry.${REGION}.aliyuncs.com/estateflow/estateflow:${DOCKER_IMAGE_TAG} .

echo "Logging into ACR..."
# You'll need to set your ACR password first
echo "Enter your ACR password (from Console > Container Registry > Access Credentials):"
read -s ACR_PASSWORD
echo ""

docker login --username=<your-alibaba-account> --password=$ACR_PASSWORD registry.${REGION}.aliyuncs.com

echo "Pushing image to ACR..."
docker push registry.${REGION}.aliyuncs.com/estateflow/estateflow:${DOCKER_IMAGE_TAG}

echo -e "${GREEN}✓ Image pushed successfully${NC}"

echo ""
echo -e "${GREEN}✅ DEPLOYMENT SUMMARY${NC}"
echo "========================"
echo ""
echo -e "${GREEN}Resources Created:${NC}"
echo "  • VPC: $VPC_ID"
echo "  • VSwitch: $VSWITCH_ID"
echo "  • Security Group: $SG_ID"
echo "  • ECS Instance: $INSTANCE_ID (Public IP: $PUBLIC_IP)"
echo "  • RDS MySQL: $RDS_ID"
echo "  • ACR Namespace: estateflow"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Wait for RDS to be ready (check in console)"
echo "2. SSH into ECS: ssh root@$PUBLIC_IP"
echo "3. Install Docker on ECS:"
echo "   curl -fsSL https://get.docker.com | bash"
echo "4. Run your container:"
echo "   docker run -d -p 3000:3000 \\
       -e NODE_ENV=production \\
       -e DATABASE_URL=mysql://root:password@<rds-private-ip>:3306/estateflow \\
       -e JWT_SECRET=your-secret \\
       registry.${REGION}.aliyuncs.com/estateflow/estateflow:${DOCKER_IMAGE_TAG}"
echo ""
echo -e "${GREEN}Estimated Cost: \$0/month (Free Tier for 12 months)${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  • Set billing alerts in Console > User Center > Billing Management"
echo "  • Monitor usage daily to stay within free tier limits"
echo "  • Stop ECS when not in use to save resources"
echo ""
echo "🎉 Happy deploying!"
