-- Receipt API Database Schema
-- This is automatically applied by the application on startup
-- File provided for reference only

CREATE TABLE IF NOT EXISTS receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    purchase_date DATE NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    tax DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    "user" VARCHAR(255) NOT NULL,
    receipt_image_path TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index for fast user queries
CREATE INDEX IF NOT EXISTS idx_receipts_user ON receipts("user");

-- Index for fast date range queries
CREATE INDEX IF NOT EXISTS idx_receipts_purchase_date ON receipts(purchase_date);

-- Optional: Unique constraint on user + purchase_date + store (if you want one receipt per store per day per user)
-- CREATE UNIQUE INDEX IF NOT EXISTS idx_receipts_unique_per_user_per_day 
-- ON receipts("user", purchase_date, store_name);
