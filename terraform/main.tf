# Terraform Configuration for Alibaba Cloud Deployment
# Estate Manager Application Infrastructure

terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.240.0"
    }
  }
}

provider "alicloud" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# Variables
variable "region" {
  description = "Alibaba Cloud region"
  type        = string
  default     = "cn-hangzhou"
}

variable "access_key" {
  description = "Alibaba Cloud Access Key ID"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Alibaba Cloud Access Key Secret"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "estate-manager"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "172.16.0.0/16"
}

variable "db_password" {
  description = "RDS MySQL master password"
  type        = string
  sensitive   = true
}

# VPC
resource "alicloud_vpc" "main" {
  vpc_name   = "${var.project_name}-vpc"
  cidr_block = var.vpc_cidr
}

# VSwitch (Subnet)
resource "alicloud_vswitch" "main" {
  vpc_id            = alicloud_vpc.main.id
  cidr_block        = "172.16.0.0/24"
  zone_id           = "${var.region}b"
  vswitch_name      = "${var.project_name}-vswitch"
  description       = "Main vSwitch for ${var.project_name}"
}

# Security Group
resource "alicloud_security_group" "main" {
  name        = "${var.project_name}-sg"
  vpc_id      = alicloud_vpc.main.id
  description = "Security group for ${var.project_name}"
}

# Security Group Rules
resource "alicloud_security_group_rule" "http" {
  security_group_id = alicloud_security_group.main.id
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  cidr_ip           = "0.0.0.0/0"
  priority          = 1
  description       = "Allow HTTP traffic"
  nic_type          = "intranet"
}

resource "alicloud_security_group_rule" "https" {
  security_group_id = alicloud_security_group.main.id
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  cidr_ip           = "0.0.0.0/0"
  priority          = 1
  description       = "Allow HTTPS traffic"
  nic_type          = "intranet"
}

resource "alicloud_security_group_rule" "app_port" {
  security_group_id = alicloud_security_group.main.id
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "8080/8080"
  cidr_ip           = "0.0.0.0/0"
  priority          = 1
  description       = "Allow application port"
  nic_type          = "intranet"
}

# NAT Gateway for private subnet internet access
resource "alicloud_nat_gateway" "main" {
  vpc_id = alicloud_vpc.main.id
  name   = "${var.project_name}-nat"
}

# SNAT Entry
resource "alicloud_snat_entry" "main" {
  snat_table_id = alicloud_nat_gateway.main.snat_table_ids[0]
  vswitch_id    = alicloud_vswitch.main.id
  snat_ip       = alicloud_nat_gateway.main.snat_ips[0].ip_address
}

# ACR Container Registry Enterprise Edition
resource "alicloud_cr_ee_instance" "main" {
  name               = "${var.project_name}-acr"
  payment_type       = "Subscription"
  period             = 1
  renew_status       = "ManualRenewal"
  cr_type            = "ENTERPRISE"
  public_network     = true
  default_domain     = "${var.project_name}.registry.cn-${var.region}.aliyuncs.com"
  storage_size       = 50
  network_type       = "VPC"
  vpc_id             = alicloud_vpc.main.id
  vswitch_id         = alicloud_vswitch.main.id
}

# ACR Repository
resource "alicloud_cr_repository" "app" {
  instance_id = alicloud_cr_ee_instance.main.id
  name        = "estate-manager"
  summary     = "Estate Manager Application Container Image"
  repo_type   = "PRIVATE"
}

# RDS MySQL Instance
resource "alicloud_db_instance" "main" {
  engine                   = "MySQL"
  engine_version           = "8.0"
  instance_type            = "mysql.n2.medium.2c"
  instance_storage         = 20
  instance_charge_type     = "Postpaid"
  instance_name            = "${var.project_name}-db"
  vswitch_id               = alicloud_vswitch.main.id
  security_ips             = [alicloud_vswitch.main.cidr_block]
  monitored_period         = 60
  monitored_period_frequency = 1
  auto_renew               = false
  backup_time              = "02:00Z-03:00Z"
  backup_retention_period  = 7
  preferred_backup_period  = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  db_instance_net_type     = "Intranet"
  pay_type                 = "Postpaid"
  connection_mode          = "Standard"
  category                 = "highavail"
  zone_id                  = "${var.region}b"
  master_user_password     = var.db_password
  master_username          = "estate_admin"
}

# RDS Database
resource "alicloud_db_database" "main" {
  instance_id = alicloud_db_instance.main.id
  name        = "estate_db"
  description = "Estate Manager Database"
  character_set = "utf8mb4"
}

# OSS Bucket for Assets
resource "alicloud_oss_bucket" "assets" {
  bucket        = "${var.project_name}-assets-${random_id.bucket_suffix.hex}"
  storage_class = "Standard"
  acl           = "private"
  
  lifecycle_rule {
    id      = "archive-old-files"
    enabled = true
    prefix  = "uploads/"
    
    expiration {
      days = 365
    }
    
    transition {
      days          = 90
      storage_class = "IA"
    }
  }
  
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Server Load Balancer (SLB)
resource "alicloud_slb" "main" {
  load_balancer_name   = "${var.project_name}-slb"
  vswitch_id          = alicloud_vswitch.main.id
  address_type        = "internet"
  load_balancer_spec  = "slb.s1.small"
  payment_type        = "PayAsYouGo"
  internet_charge_type = "PayByTraffic"
  bandwidth           = 10
}

# SLB Listener - HTTP
resource "alicloud_slb_listener" "http" {
  load_balancer_id    = alicloud_slb.main.id
  backend_port        = 8080
  frontend_port       = 80
  protocol            = "http"
  bandwidth           = 10
  scheduler           = "wrr"
  health_check        = "on"
  health_check_uri    = "/health"
  health_check_connect_port = 8080
  healthy_threshold   = 3
  unhealthy_threshold = 3
  health_check_timeout = 5
  health_check_interval = 5
}

# SLB Listener - HTTPS
resource "alicloud_slb_listener" "https" {
  load_balancer_id    = alicloud_slb.main.id
  backend_port        = 8080
  frontend_port       = 443
  protocol            = "https"
  bandwidth           = 10
  scheduler           = "wrr"
  server_certificate_id = alicloud_slb_server_certificate.main.id
  health_check        = "on"
  health_check_uri    = "/health"
  healthy_threshold   = 3
  unhealthy_threshold = 3
  health_check_timeout = 5
  health_check_interval = 5
}

# SSL Certificate
resource "alicloud_slb_server_certificate" "main" {
  load_balancer_id    = alicloud_slb.main.id
  server_certificate_name = "${var.project_name}-cert"
  # Upload your certificate content or use Alibaba Cloud SSL Service
  # server_certificate = file("path/to/cert.pem")
  # private_key        = file("path/to/key.pem")
}

# ACK Kubernetes Cluster (Optional - for container orchestration)
resource "alicloud_cs_kubernetes" "main" {
  count                 = var.enable_ack ? 1 : 0
  name                  = "${var.project_name}-ack"
  cluster_spec          = "ack.pro.small"
  version               = "1.28.3-aliyun.1"
  new_nat_gateway       = false
  worker_vswitch_ids    = [alicloud_vswitch.main.id]
  pod_cidr              = "172.20.0.0/16"
  service_cidr          = "172.21.0.0/20"
  load_balancer_spec    = "slb.s2.small"
  is_enterprise_security_group = true
  
  worker_config {
    instance_type          = "ecs.c6.large"
    system_disk_category   = "cloud_efficiency"
    system_disk_size       = 40
    worker_number          = 2
    worker_instance_types  = ["ecs.c6.large", "ecs.c6.xlarge"]
  }
}

# Outputs
output "vpc_id" {
  value = alicloud_vpc.main.id
}

output "vswitch_id" {
  value = alicloud_vswitch.main.id
}

output "acr_endpoint" {
  value = alicloud_cr_ee_instance.main.default_domain
}

output "rds_connection_string" {
  value     = alicloud_db_instance.main.connection_string
  sensitive = true
}

output "oss_bucket_name" {
  value = alicloud_oss_bucket.assets.bucket
}

output "slb_public_ip" {
  value = alicloud_slb.main.address
}

output "ack_cluster_id" {
  value = var.enable_ack ? alicloud_cs_kubernetes.main[0].id : null
}

# Conditional variable
variable "enable_ack" {
  description = "Enable ACK Kubernetes cluster deployment"
  type        = bool
  default     = false
}
