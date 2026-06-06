-- EstateFlow AI Database Schema (MySQL)
-- Run this against your AWS RDS MySQL instance

CREATE DATABASE IF NOT EXISTS estate_db;
USE estate_db;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255),
  name VARCHAR(255),
  role VARCHAR(50) DEFAULT 'user',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Properties table
CREATE TABLE IF NOT EXISTS properties (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(12, 2) NOT NULL,
  location VARCHAR(255),
  bedrooms INT DEFAULT 0,
  bathrooms INT DEFAULT 0,
  area INT,
  type VARCHAR(50),
  status VARCHAR(50) DEFAULT 'available',
  owner_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id)
);

-- Tenants table
CREATE TABLE IF NOT EXISTS tenants (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  property_id INT NOT NULL,
  lease_start TIMESTAMP,
  lease_end TIMESTAMP,
  rent_amount DECIMAL(10, 2),
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (property_id) REFERENCES properties(id)
);

-- Payments table
CREATE TABLE IF NOT EXISTS payments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tenant_id INT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(50) DEFAULT 'paid',
  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- Create indexes for performance
CREATE INDEX idx_properties_status ON properties(status);
CREATE INDEX idx_tenants_status ON tenants(status);
CREATE INDEX idx_payments_tenant ON payments(tenant_id);