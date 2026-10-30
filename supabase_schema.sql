-- ========================================================
-- DAPOY WALLET - SUPABASE DATABASE SCHEMA
-- Jalankan script SQL ini di Supabase SQL Editor:
-- https://supabase.com/dashboard/project/vwfriffzafrklnwkqfns/sql
-- ========================================================

-- 1. Tabel Bulan Anggaran (Months)
CREATE TABLE IF NOT EXISTS public.budget_months (
    id TEXT PRIMARY KEY,               -- Contoh: '0926', '1026', '1126'
    display_name TEXT NOT NULL,         -- Contoh: 'September 2026'
    title TEXT NOT NULL,                -- Contoh: 'LAPORAN BULAN OKTOBER 2026'
    month_number INT NOT NULL,          -- 1 - 12
    year_number INT NOT NULL,           -- e.g. 2026
    bank_balance NUMERIC DEFAULT 0,     -- Saldo Bank
    discrepancy NUMERIC DEFAULT 0,      -- Selisih
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabel Sumber Pemasukan (Income Sources)
CREATE TABLE IF NOT EXISTS public.income_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    month_id TEXT NOT NULL REFERENCES public.budget_months(id) ON DELETE CASCADE,
    source TEXT NOT NULL,              -- Contoh: 'ABI', 'MAMA', 'LAPTOP'
    amount NUMERIC NOT NULL DEFAULT 0,  -- Nominal pemasukan
    row_number INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Tabel Pos Anggaran (Budget Items)
CREATE TABLE IF NOT EXISTS public.budget_items (
    id TEXT PRIMARY KEY,               -- Contoh: '1026_b_5'
    month_id TEXT NOT NULL REFERENCES public.budget_months(id) ON DELETE CASCADE,
    name TEXT NOT NULL,                -- Contoh: 'PDAM PPS', 'BELANJA'
    category TEXT NOT NULL,            -- 'Wajib', 'Keluarga', 'Anak', 'Transportasi', 'Rumah', 'Tabungan', 'Lain-lain'
    budget NUMERIC NOT NULL DEFAULT 0, -- Anggaran direncanakan
    actual NUMERIC NOT NULL DEFAULT 0, -- Realisasi / output
    remaining NUMERIC NOT NULL DEFAULT 0, -- Sisa anggaran
    row_number INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Tabel Transaksi Harian (Daily Expenses)
CREATE TABLE IF NOT EXISTS public.daily_expenses (
    id TEXT PRIMARY KEY,               -- e.g. '1026_tx_38'
    month_id TEXT NOT NULL REFERENCES public.budget_months(id) ON DELETE CASCADE,
    date TEXT NOT NULL,                -- Contoh: '25 Agustus'
    entry_number INT NOT NULL DEFAULT 1,
    description TEXT NOT NULL,         -- Contoh: 'BBM motor', 'Belanja sayur'
    amount NUMERIC NOT NULL DEFAULT 0, -- Nominal transaksi
    linked_budget_item TEXT,           -- Nama pos anggaran terkait
    row_number INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Aktifkan Row Level Security (RLS) namun izinkan full access untuk anon key (publik/keluarga)
ALTER TABLE public.budget_months ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.income_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on budget_months" ON public.budget_months FOR SELECT USING (true);
CREATE POLICY "Allow public write access on budget_months" ON public.budget_months FOR ALL USING (true);

CREATE POLICY "Allow public read access on income_sources" ON public.income_sources FOR SELECT USING (true);
CREATE POLICY "Allow public write access on income_sources" ON public.income_sources FOR ALL USING (true);

CREATE POLICY "Allow public read access on budget_items" ON public.budget_items FOR SELECT USING (true);
CREATE POLICY "Allow public write access on budget_items" ON public.budget_items FOR ALL USING (true);

CREATE POLICY "Allow public read access on daily_expenses" ON public.daily_expenses FOR SELECT USING (true);
CREATE POLICY "Allow public write access on daily_expenses" ON public.daily_expenses FOR ALL USING (true);

