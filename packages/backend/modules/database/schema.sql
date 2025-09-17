-- Funding Rates Database Schema
-- Optimized for periodic log storage and querying

-- Exchange reference table
CREATE TABLE exchanges (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Symbol reference table
CREATE TABLE symbols (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    symbol TEXT UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Log collection metadata
CREATE TABLE log_collections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT UNIQUE NOT NULL,
    collected_at DATETIME NOT NULL,
    processed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_records INTEGER DEFAULT 0
);

-- Main funding rates table
CREATE TABLE funding_rates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    symbol_id INTEGER NOT NULL,
    exchange_id INTEGER NOT NULL,
    collection_id INTEGER NOT NULL,
    funding_rate DECIMAL(12, 10), -- NULL when exchange doesn't offer symbol
    next_funding_time BIGINT, -- Unix timestamp in milliseconds
    funding_interval_hours INTEGER,
    collected_at DATETIME NOT NULL,
    
    FOREIGN KEY (symbol_id) REFERENCES symbols(id),
    FOREIGN KEY (exchange_id) REFERENCES exchanges(id),
    FOREIGN KEY (collection_id) REFERENCES log_collections(id)
);

-- Indexes for performance
CREATE INDEX idx_funding_rates_symbol_exchange ON funding_rates(symbol_id, exchange_id);
CREATE INDEX idx_funding_rates_collected_at ON funding_rates(collected_at);
CREATE INDEX idx_funding_rates_next_funding ON funding_rates(next_funding_time);
CREATE INDEX idx_funding_rates_collection ON funding_rates(collection_id);
CREATE INDEX idx_funding_rates_symbol_time ON funding_rates(symbol_id, collected_at);
CREATE INDEX idx_funding_rates_exchange_time ON funding_rates(exchange_id, collected_at);

-- Composite index for common queries
CREATE INDEX idx_funding_rates_composite ON funding_rates(symbol_id, exchange_id, collected_at);

-- Insert default exchanges
INSERT INTO exchanges (name, display_name) VALUES 
    ('BinPerp', 'Binance Perpetual'),
    ('HlPerp', 'Hyperliquid Perpetual'),
    ('BybitPerp', 'Bybit Perpetual');

-- Views for easier querying
CREATE VIEW v_funding_rates AS
SELECT 
    fr.id,
    s.symbol,
    e.name as exchange,
    e.display_name as exchange_display,
    fr.funding_rate,
    fr.next_funding_time,
    fr.funding_interval_hours,
    fr.collected_at,
    lc.filename as log_file
FROM funding_rates fr
JOIN symbols s ON fr.symbol_id = s.id
JOIN exchanges e ON fr.exchange_id = e.id
JOIN log_collections lc ON fr.collection_id = lc.id;

-- View for latest funding rates per symbol-exchange pair
CREATE VIEW v_latest_funding_rates AS
SELECT 
    s.symbol,
    e.name as exchange,
    e.display_name as exchange_display,
    fr.funding_rate,
    fr.next_funding_time,
    fr.funding_interval_hours,
    fr.collected_at
FROM funding_rates fr
JOIN symbols s ON fr.symbol_id = s.id
JOIN exchanges e ON fr.exchange_id = e.id
JOIN (
    SELECT symbol_id, exchange_id, MAX(collected_at) as max_collected
    FROM funding_rates
    GROUP BY symbol_id, exchange_id
) latest ON fr.symbol_id = latest.symbol_id 
    AND fr.exchange_id = latest.exchange_id 
    AND fr.collected_at = latest.max_collected;

-- View for funding rate statistics
CREATE VIEW v_funding_rate_stats AS
SELECT 
    s.symbol,
    e.name as exchange,
    COUNT(*) as total_records,
    AVG(fr.funding_rate) as avg_funding_rate,
    MIN(fr.funding_rate) as min_funding_rate,
    MAX(fr.funding_rate) as max_funding_rate,
    STDDEV(fr.funding_rate) as stddev_funding_rate,
    MIN(fr.collected_at) as first_record,
    MAX(fr.collected_at) as latest_record
FROM funding_rates fr
JOIN symbols s ON fr.symbol_id = s.id
JOIN exchanges e ON fr.exchange_id = e.id
WHERE fr.funding_rate IS NOT NULL
GROUP BY s.symbol, e.name;