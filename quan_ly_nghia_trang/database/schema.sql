-- PostgreSQL schema for Sala Garden cemetery management.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), phone VARCHAR(20) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL, full_name VARCHAR(160) NOT NULL, role VARCHAR(30) NOT NULL DEFAULT 'relative'
    CHECK (role IN ('relative','admin','staff','manager')),
  email VARCHAR(255), national_id VARCHAR(32), is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS family_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), owner_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(160) NOT NULL, relationship VARCHAR(100), notes TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS plots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), code VARCHAR(40) NOT NULL UNIQUE, zone VARCHAR(80) NOT NULL,
  row_code VARCHAR(20), plot_number VARCHAR(20), area_sqm NUMERIC(8,2), price NUMERIC(14,2),
  status VARCHAR(24) NOT NULL DEFAULT 'available' CHECK (status IN ('available','reserved','occupied','maintenance')),
  latitude NUMERIC(10,7), longitude NUMERIC(10,7), description TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS memorial_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), plot_id UUID REFERENCES plots(id), family_profile_id UUID REFERENCES family_profiles(id),
  full_name VARCHAR(160) NOT NULL, birth_date DATE, death_date DATE, memorial_name VARCHAR(160), biography TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), contract_code VARCHAR(40) NOT NULL UNIQUE,
  customer_user_id UUID NOT NULL REFERENCES users(id), plot_id UUID NOT NULL REFERENCES plots(id),
  beneficiary_name VARCHAR(160), total_amount NUMERIC(14,2) NOT NULL CHECK(total_amount >= 0),
  status VARCHAR(24) NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','active','completed','cancelled')),
  signed_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS installments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
  due_date DATE NOT NULL, amount NUMERIC(14,2) NOT NULL CHECK(amount >= 0), paid_at TIMESTAMPTZ,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','paid','overdue'))
);
CREATE TABLE IF NOT EXISTS care_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), name VARCHAR(160) NOT NULL, description TEXT,
  price NUMERIC(14,2) NOT NULL DEFAULT 0, active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_care_services_name ON care_services(name);
CREATE TABLE IF NOT EXISTS care_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), order_code VARCHAR(40) NOT NULL UNIQUE,
  customer_user_id UUID NOT NULL REFERENCES users(id), plot_id UUID REFERENCES plots(id),
  service_id UUID REFERENCES care_services(id), assigned_user_id UUID REFERENCES users(id),
  scheduled_at TIMESTAMPTZ, status VARCHAR(24) NOT NULL DEFAULT 'pending'
    CHECK(status IN ('pending','assigned','in_progress','completed','cancelled')),
  notes TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS care_order_proofs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), care_order_id UUID NOT NULL REFERENCES care_orders(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES users(id), image_url TEXT NOT NULL, caption TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), contract_id UUID REFERENCES contracts(id),
  installment_id UUID REFERENCES installments(id), care_order_id UUID REFERENCES care_orders(id),
  amount NUMERIC(14,2) NOT NULL CHECK(amount >= 0), method VARCHAR(40), status VARCHAR(20) NOT NULL DEFAULT 'pending',
  transaction_ref VARCHAR(120), paid_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL, body TEXT, read_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_plots_status_zone ON plots(status, zone);
CREATE INDEX IF NOT EXISTS idx_contracts_customer ON contracts(customer_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_care_orders_customer ON care_orders(customer_user_id, created_at DESC);
