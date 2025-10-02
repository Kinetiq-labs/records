-- Supabase Database Schema for Records App
-- Run this SQL in your Supabase SQL Editor to create the tables

-- Enable Row Level Security
ALTER DATABASE postgres SET row_security = on;

-- Create tables with UUID primary keys and tenant isolation

-- 1. Business Years Table
CREATE TABLE business_years (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    year_id TEXT UNIQUE NOT NULL,
    tenant_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    year_number INTEGER NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT false,
    total_entries INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    sync_status INTEGER DEFAULT 0
);

-- 2. Business Months Table
CREATE TABLE business_months (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    month_id TEXT UNIQUE NOT NULL,
    year_id TEXT NOT NULL,
    tenant_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    month_number INTEGER NOT NULL,
    month_name TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    total_entries INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    sync_status INTEGER DEFAULT 0
);

-- 3. Business Days Table
CREATE TABLE business_days (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    day_id TEXT UNIQUE NOT NULL,
    month_id TEXT NOT NULL,
    tenant_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    day_date TIMESTAMPTZ NOT NULL,
    day_name TEXT NOT NULL,
    total_entries INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    sync_status INTEGER DEFAULT 0
);

-- 4. Customers Table
CREATE TABLE customers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT UNIQUE NOT NULL,
    tenant_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    notes TEXT,
    discount_percent REAL,
    previous_arrears REAL DEFAULT 0,
    received REAL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- 5. Khata Entries Table (Main transaction records)
CREATE TABLE khata_entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    entry_id TEXT UNIQUE NOT NULL,
    day_id TEXT NOT NULL,
    tenant_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    entry_index INTEGER NOT NULL,
    entry_date TIMESTAMPTZ NOT NULL,
    entry_time TEXT,
    status TEXT,
    customer_name TEXT,

    -- Input fields
    name TEXT NOT NULL,
    weight REAL,
    detail TEXT,
    number INTEGER NOT NULL,
    return_weight_1 INTEGER,
    return_weight_1_display TEXT,
    first_weight INTEGER,
    silver INTEGER,
    silver_sold REAL,
    silver_amount REAL,
    silver_paid INTEGER DEFAULT 0,
    return_weight_2 INTEGER,
    nalki INTEGER,
    discount_percent REAL,

    -- Calculated fields
    tehlil REAL,
    earned_amount REAL,
    wajan REAL,
    rakam REAL,
    beej REAL,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    sync_status INTEGER DEFAULT 0
);

-- 6. Sync Metadata Table (for tracking sync state)
CREATE TABLE sync_metadata (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    table_name TEXT NOT NULL,
    tenant_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    last_sync_at TIMESTAMPTZ NOT NULL,
    sync_direction TEXT NOT NULL, -- 'upload', 'download', 'both'
    record_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(table_name, tenant_id, user_id)
);

-- Create indexes for better performance
CREATE INDEX idx_business_years_tenant_user ON business_years (tenant_id, user_id);
CREATE INDEX idx_business_years_active ON business_years (is_active);

CREATE INDEX idx_business_months_tenant_user ON business_months (tenant_id, user_id);
CREATE INDEX idx_business_months_year ON business_months (year_id);

CREATE INDEX idx_business_days_tenant_user ON business_days (tenant_id, user_id);
CREATE INDEX idx_business_days_month ON business_days (month_id);
CREATE INDEX idx_business_days_date ON business_days (day_date);

CREATE INDEX idx_customers_tenant_user ON customers (tenant_id, user_id);
CREATE INDEX idx_customers_name ON customers (name);
CREATE INDEX idx_customers_active ON customers (is_active);

CREATE INDEX idx_khata_entries_tenant_user ON khata_entries (tenant_id, user_id);
CREATE INDEX idx_khata_entries_day ON khata_entries (day_id);
CREATE INDEX idx_khata_entries_date ON khata_entries (entry_date);
CREATE INDEX idx_khata_entries_customer ON khata_entries (customer_name);
CREATE INDEX idx_khata_entries_entry_id ON khata_entries (entry_id);

CREATE INDEX idx_sync_metadata_tenant_user ON sync_metadata (tenant_id, user_id);
CREATE INDEX idx_sync_metadata_table ON sync_metadata (table_name);

-- Create Row Level Security (RLS) policies

-- Business Years RLS
ALTER TABLE business_years ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access their own business years" ON business_years
    FOR ALL USING (auth.uid() = user_id);

-- Business Months RLS
ALTER TABLE business_months ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access their own business months" ON business_months
    FOR ALL USING (auth.uid() = user_id);

-- Business Days RLS
ALTER TABLE business_days ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access their own business days" ON business_days
    FOR ALL USING (auth.uid() = user_id);

-- Customers RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access their own customers" ON customers
    FOR ALL USING (auth.uid() = user_id);

-- Khata Entries RLS
ALTER TABLE khata_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access their own khata entries" ON khata_entries
    FOR ALL USING (auth.uid() = user_id);

-- Sync Metadata RLS
ALTER TABLE sync_metadata ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access their own sync metadata" ON sync_metadata
    FOR ALL USING (auth.uid() = user_id);

-- Create functions for automatic updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_business_years_updated_at BEFORE UPDATE
    ON business_years FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_business_months_updated_at BEFORE UPDATE
    ON business_months FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_business_days_updated_at BEFORE UPDATE
    ON business_days FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE
    ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_khata_entries_updated_at BEFORE UPDATE
    ON khata_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sync_metadata_updated_at BEFORE UPDATE
    ON sync_metadata FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create a function to get user statistics
CREATE OR REPLACE FUNCTION get_user_statistics(user_uuid UUID, tenant_id_param TEXT)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_customers', (SELECT COUNT(*) FROM customers WHERE user_id = user_uuid AND tenant_id = tenant_id_param AND is_active = true),
        'total_entries', (SELECT COUNT(*) FROM khata_entries WHERE user_id = user_uuid AND tenant_id = tenant_id_param),
        'total_years', (SELECT COUNT(*) FROM business_years WHERE user_id = user_uuid AND tenant_id = tenant_id_param),
        'active_year', (SELECT year_number FROM business_years WHERE user_id = user_uuid AND tenant_id = tenant_id_param AND is_active = true LIMIT 1),
        'last_entry_date', (SELECT MAX(entry_date) FROM khata_entries WHERE user_id = user_uuid AND tenant_id = tenant_id_param),
        'last_sync_date', (SELECT MAX(updated_at) FROM sync_metadata WHERE user_id = user_uuid AND tenant_id = tenant_id_param)
    ) INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;