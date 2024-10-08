CREATE TABLE stocks_real_time (
	time TIMESTAMPTZ NOT NULL,
	symbol TEXT NOT NULL,
	price DOUBLE PRECISION NULL,
	day_volume INT NULL
);

-- create hyprtable
SELECT create_hypertable('stocks_real_time','time');

CREATE INDEX ix_symbol_time ON stocks_real_time (symbol,time DESC);


CREATE TABLE company (
	symbol TEXT NOT NULL,
	name TEXT NOT NULL
);


SELECT * FROM public.stocks_real_time
WHERE time > now() - INTERVAL '1 day';

SELECT * FROM public.stocks_real_time ORDER BY time DESC, price DESC LIMIT 10;

SELECT avg(price) FROM public.stocks_real_time srt JOIN company c ON srt.symbol = c.symbol
WHERE c.name='Apple' AND time > now() - INTERVAL '2 days';

-- create bucket
SELECT time_bucket('1 day',time) as bucket, 
	symbol, avg(price) 
	FROM stocks_real_time srt 
	WHERE time > now() - INTERVAL '1 week' 
	GROUP BY bucket,symbol
	ORDER BY bucket,symbol;


-- create continuous aggregate
SELECT time_bucket('1 day',time) AS day,symbol, 
	max(price) as high, 
	first(price,time) as open,
	last(price,time) as close, 
	min(price) as low 
FROM stocks_real_time srt 
GROUP BY day,symbol
ORDER BY day DESC,symbol;

-- materialized view
CREATE MATERIALIZED VIEW stock_candlestick_daily
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 day',time) AS day,symbol, 
	max(price) as high, 
	first(price,time) as open,
	last(price,time) as close, 
	min(price) as low 
FROM stocks_real_time srt 
GROUP BY day,symbol;


SELECT * FROM stock_candlestick_daily ORDER BY day DESC,symbol;

--  automatic refresh policy
SELECT add_continuous_aggregate_policy('stock_candlestick_daily',
	start_offset=> INTERVAL '3 days',
	end_offset => INTERVAL '1 hour',
	schedule_interval => INTERVAL '1 days'
);

--  Manual refresh policy
CALL refresh_continuous_aggregate('stock_candlestick_daily',now() - INTERVAL '1 week',now());

-- Compression
ALTER TABLE stocks_real_time SET (
	timescaledb.compress,
	timescaledb.compress_orderby = 'time DESC',
	timescaledb.compress_segmentby = 'symbol'
);

-- automatic compression policy
SELECT add_compression_policy('stocks_real_time',INTERVAL '2 weeks');

--  manual compresson (not working)
SELECT compress_chunk(i) 
FROM show_chunks('stocks_real_time', older_then => INTERVAL '2 weeks') i;


--  difference
SELECT pg_size_pretty(before_compression_total_bytes) as "before compression", 
pg_size_pretty(after_compression_total_bytes) as "after compression"
FROM hypertable_compression_stats('stocks_real_time');


-- Automatic Retention Policy
SELECT add_retention_policy('stocks_real_time', INTERVAL '3 weeks');

-- active policies
SELECT * from timescaledb_information.jobs;

-- manual retantion policy (not working)
SELECT drop_chunks(
'stocks_real_time',
older_then=> INTERVAL '2 weeks',
newer_then=> INTERVAL '3 weeks'
);

