import { mysqlTable, varchar, int, timestamp, text, decimal, json, date } from "drizzle-orm/mysql";

// Users table (base user entity)
export const users = mysqlTable("users", {
  id: int("id").autoincrement().primaryKey(),
  email: varchar("email", { length: 255 }).notNull().unique(),
  passwordHash: varchar("password_hash", { length: 255 }),
  name: varchar("name", { length: 255 }),
  role: varchar("role", { length: 50 }).default("tenant"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Owners table (property owners with business info)
export const owners = mysqlTable("owners", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("user_id").references(() => users.id).notNull(),
  companyName: varchar("company_name", { length: 255 }),
  businessRegistration: varchar("business_registration", { length: 100 }),
  taxId: varchar("tax_id", { length: 100 }),
  preferredContactMethod: varchar("preferred_contact_method", { length: 20 }).default("email"),
  notificationPreferences: json("notification_preferences"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Logins table (authentication audit trail)
export const logins = mysqlTable("logins", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("user_id").references(() => users.id).notNull(),
  ipAddress: varchar("ip_address", { length: 45 }),
  userAgent: text("user_agent"),
  loginAt: timestamp("login_at").defaultNow(),
  logoutAt: timestamp("logout_at"),
  sessionId: varchar("session_id", { length: 255 }),
});

// Properties table
export const properties = mysqlTable("properties", {
  id: int("id").autoincrement().primaryKey(),
  title: varchar("title", { length: 255 }).notNull(),
  description: text("description"),
  price: decimal("price", { precision: 12, scale: 2 }).notNull(),
  location: varchar("location", { length: 255 }),
  bedrooms: int("bedrooms").default(0),
  bathrooms: int("bathrooms").default(0),
  area: int("area"),
  type: varchar("type", { length: 50 }).default("rental"),
  status: varchar("status", { length: 50 }).default("available"),
  ownerId: int("owner_id").references(() => users.id).notNull(),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Tenants table
export const tenants = mysqlTable("tenants", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("user_id").references(() => users.id).notNull(),
  propertyId: int("property_id").references(() => properties.id).notNull(),
  leaseStart: date("lease_start"),
  leaseEnd: date("lease_end"),
  rentAmount: decimal("rent_amount", { precision: 10, scale: 2 }).notNull(),
  securityDeposit: decimal("security_deposit", { precision: 10, scale: 2 }).default(0),
  status: varchar("status", { length: 50 }).default("pending"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Payments table
export const payments = mysqlTable("payments", {
  id: int("id").autoincrement().primaryKey(),
  tenantId: int("tenant_id").references(() => tenants.id).notNull(),
  amount: decimal("amount", { precision: 10, scale: 2 }).notNull(),
  paymentDate: timestamp("payment_date").defaultNow(),
  dueDate: date("due_date"),
  status: varchar("status", { length: 50 }).default("pending"),
  paymentMethod: varchar("payment_method", { length: 50 }).default("bank_transfer"),
  referenceNumber: varchar("reference_number", { length: 255 }),
});