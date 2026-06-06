import { mysqlTable, varchar, int, timestamp, text, decimal, boolean } from "drizzle-orm/mysql";

// Users table
export const users = mysqlTable("users", {
  id: int("id").autoincrement().primaryKey(),
  email: varchar("email", { length: 255 }).notNull().unique(),
  passwordHash: varchar("password_hash", { length: 255 }),
  name: varchar("name", { length: 255 }),
  role: varchar("role", { length: 50 }).default("user"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
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
  area: int("area"), // in sq ft
  type: varchar("type", { length: 50 }), // "rental", "sale", "commercial"
  status: varchar("status", { length: 50 }).default("available"),
  ownerId: int("owner_id").references(() => users.id),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Tenants table
export const tenants = mysqlTable("tenants", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("user_id").references(() => users.id).notNull(),
  propertyId: int("property_id").references(() => properties.id).notNull(),
  leaseStart: timestamp("lease_start"),
  leaseEnd: timestamp("lease_end"),
  rentAmount: decimal("rent_amount", { precision: 10, scale: 2 }),
  status: varchar("status", { length: 50 }).default("active"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Payments table
export const payments = mysqlTable("payments", {
  id: int("id").autoincrement().primaryKey(),
  tenantId: int("tenant_id").references(() => tenants.id).notNull(),
  amount: decimal("amount", { precision: 10, scale: 2 }).notNull(),
  paymentDate: timestamp("payment_date").defaultNow(),
  status: varchar("status", { length: 50 }).default("paid"),
});