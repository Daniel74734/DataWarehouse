-- BudgetWiseDW quality checks, from bronze to gold
-- Run this whole file in SSMS after running load_bronze, load_silver and load_gold
-- Every test has an expected value. Look at the final table: PASS = actual matches expected

USE BudgetWiseDW;
GO

SET NOCOUNT ON;

-- Results are collected here and shown at the end
IF OBJECT_ID('tempdb..#results') IS NOT NULL DROP TABLE #results;
CREATE TABLE #results (
    layer      NVARCHAR(10),
    test_name  NVARCHAR(120),
    expected   BIGINT,
    actual     BIGINT
);

-- =====================================================================
-- BRONZE: did both files load?
-- =====================================================================

-- Both bronze tables must have rows (expected 1 means "more than zero")
INSERT INTO #results SELECT 'bronze', 'src1 table has rows', 1, CASE WHEN COUNT_BIG(*) > 0 THEN 1 ELSE 0 END FROM bronze.transactions_src1;
INSERT INTO #results SELECT 'bronze', 'src2 table has rows', 1, CASE WHEN COUNT_BIG(*) > 0 THEN 1 ELSE 0 END FROM bronze.transactions_src2;

-- =====================================================================
-- SILVER: mapping tables
-- =====================================================================

-- Every category left in silver must be a canonical value from the map (NULL is allowed, on purpose)
INSERT INTO #results
SELECT 'silver', 'category values not found in category_map', 0, COUNT_BIG(*)
FROM silver.transactions
WHERE category IS NOT NULL
  AND category NOT IN (SELECT correct_value FROM silver.category_map);

-- Same check for payment mode
INSERT INTO #results
SELECT 'silver', 'payment_mode values not found in payment_mode_map', 0, COUNT_BIG(*)
FROM silver.transactions
WHERE payment_mode IS NOT NULL
  AND payment_mode NOT IN (SELECT correct_value FROM silver.payment_mode_map);

-- Same check for location ('Unknown' is allowed because silver writes it on purpose)
INSERT INTO #results
SELECT 'silver', 'location values not found in location_map', 0, COUNT_BIG(*)
FROM silver.transactions
WHERE location IS NOT NULL
  AND location <> 'Unknown'
  AND location NOT IN (SELECT correct_value FROM silver.location_map);

-- The N/A placeholder in location must be gone
INSERT INTO #results
SELECT 'silver', 'location rows still equal to N/A', 0, COUNT_BIG(*)
FROM silver.transactions
WHERE location = 'N/A';

-- =====================================================================
-- SILVER: amounts and dates
-- =====================================================================

-- Negative amounts must have been set to NULL
INSERT INTO #results
SELECT 'silver', 'rows with a negative amount', 0, COUNT_BIG(*)
FROM silver.transactions
WHERE amount < 0;

-- Outlier amounts (above 100,000) must have been set to NULL
INSERT INTO #results
SELECT 'silver', 'rows with an amount above 100000', 0, COUNT_BIG(*)
FROM silver.transactions
WHERE amount > 100000;

-- Rows with a usable amount: this is the number that should reach gold
INSERT INTO #results
SELECT 'silver', 'rows with a usable amount', 29067, COUNT_BIG(*)
FROM silver.transactions
WHERE amount IS NOT NULL;

-- =====================================================================
-- GOLD: dimensions
-- =====================================================================

-- Each dimension must have exactly one Unknown row with key -1
INSERT INTO #results SELECT 'gold', 'dim_category has one Unknown row (key -1)',     1, COUNT_BIG(*) FROM gold.dim_category     WHERE category_key = -1;
INSERT INTO #results SELECT 'gold', 'dim_payment_mode has one Unknown row (key -1)', 1, COUNT_BIG(*) FROM gold.dim_payment_mode WHERE payment_mode_key = -1;
INSERT INTO #results SELECT 'gold', 'dim_location has one Unknown row (key -1)',     1, COUNT_BIG(*) FROM gold.dim_location     WHERE location_key = -1;
INSERT INTO #results SELECT 'gold', 'dim_date has one Unknown row (key -1)',         1, COUNT_BIG(*) FROM gold.dim_date         WHERE date_key = -1;

-- Row counts of each dimension: canonical values plus the Unknown row
INSERT INTO #results SELECT 'gold', 'dim_category row count (15 + Unknown)',        16,   COUNT_BIG(*) FROM gold.dim_category;
INSERT INTO #results SELECT 'gold', 'dim_payment_mode row count (4 + Unknown)',      5,   COUNT_BIG(*) FROM gold.dim_payment_mode;
INSERT INTO #results SELECT 'gold', 'dim_location row count (10 cities + Unknown)', 11,   COUNT_BIG(*) FROM gold.dim_location;
INSERT INTO #results SELECT 'gold', 'dim_date row count (2019 to 2024 + Unknown)', 2193,  COUNT_BIG(*) FROM gold.dim_date;

-- No dimension may contain the same name twice
INSERT INTO #results
SELECT 'gold', 'duplicate names in dim_category', 0, COUNT_BIG(*)
FROM (SELECT category_name FROM gold.dim_category GROUP BY category_name HAVING COUNT(*) > 1) d;

INSERT INTO #results
SELECT 'gold', 'duplicate names in dim_payment_mode', 0, COUNT_BIG(*)
FROM (SELECT payment_mode_name FROM gold.dim_payment_mode GROUP BY payment_mode_name HAVING COUNT(*) > 1) d;

INSERT INTO #results
SELECT 'gold', 'duplicate names in dim_location', 0, COUNT_BIG(*)
FROM (SELECT location_name FROM gold.dim_location GROUP BY location_name HAVING COUNT(*) > 1) d;

-- =====================================================================
-- GOLD: dim_date logic
-- =====================================================================

-- The real dates must start on 1 Jan 2019 and end on 31 Dec 2024
INSERT INTO #results
SELECT 'gold', 'dim_date first real date is 2019-01-01', 1, COUNT_BIG(*)
FROM (SELECT MIN(full_date) AS d FROM gold.dim_date WHERE date_key <> -1) x
WHERE d = '2019-01-01';

INSERT INTO #results
SELECT 'gold', 'dim_date last real date is 2024-12-31', 1, COUNT_BIG(*)
FROM (SELECT MAX(full_date) AS d FROM gold.dim_date WHERE date_key <> -1) x
WHERE d = '2024-12-31';

-- date_key (YYYYMMDD) must match full_date on every real row
INSERT INTO #results
SELECT 'gold', 'dim_date rows where date_key does not match full_date', 0, COUNT_BIG(*)
FROM gold.dim_date
WHERE date_key <> -1
  AND date_key <> CONVERT(INT, CONVERT(CHAR(8), full_date, 112));

-- is_weekend must be 1 for Saturday and Sunday only
INSERT INTO #results
SELECT 'gold', 'dim_date rows where is_weekend is wrong', 0, COUNT_BIG(*)
FROM gold.dim_date
WHERE date_key <> -1
  AND is_weekend <> CASE WHEN DATENAME(WEEKDAY, full_date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END;

-- =====================================================================
-- GOLD: fact table
-- =====================================================================

-- Fact rows loaded
INSERT INTO #results
SELECT 'gold', 'fact_transactions row count', 29067, COUNT_BIG(*)
FROM gold.fact_transactions;

-- Reconciliation: silver rows with a usable amount must equal gold fact rows (difference should be 0)
INSERT INTO #results
SELECT 'gold', 'silver usable rows minus gold fact rows', 0,
       (SELECT COUNT_BIG(*) FROM silver.transactions WHERE amount IS NOT NULL)
     - (SELECT COUNT_BIG(*) FROM gold.fact_transactions);

-- Reconciliation: total amount in silver must equal total amount in gold (difference should be 0)
INSERT INTO #results
SELECT 'gold', 'silver total amount minus gold total amount', 0,
       CAST(ISNULL((SELECT SUM(amount) FROM silver.transactions WHERE amount IS NOT NULL), 0)
          - ISNULL((SELECT SUM(amount) FROM gold.fact_transactions), 0) AS BIGINT);

-- No NULL amounts may reach the fact table
INSERT INTO #results
SELECT 'gold', 'fact rows with a NULL amount', 0, COUNT_BIG(*)
FROM gold.fact_transactions
WHERE amount IS NULL;

-- Orphan check: every fact key must exist in its dimension
INSERT INTO #results
SELECT 'gold', 'fact rows with a date_key missing from dim_date', 0, COUNT_BIG(*)
FROM gold.fact_transactions f
LEFT JOIN gold.dim_date d ON d.date_key = f.date_key
WHERE d.date_key IS NULL;

INSERT INTO #results
SELECT 'gold', 'fact rows with a category_key missing from dim_category', 0, COUNT_BIG(*)
FROM gold.fact_transactions f
LEFT JOIN gold.dim_category c ON c.category_key = f.category_key
WHERE c.category_key IS NULL;

INSERT INTO #results
SELECT 'gold', 'fact rows with a payment_mode_key missing from dim_payment_mode', 0, COUNT_BIG(*)
FROM gold.fact_transactions f
LEFT JOIN gold.dim_payment_mode p ON p.payment_mode_key = f.payment_mode_key
WHERE p.payment_mode_key IS NULL;

INSERT INTO #results
SELECT 'gold', 'fact rows with a location_key missing from dim_location', 0, COUNT_BIG(*)
FROM gold.fact_transactions f
LEFT JOIN gold.dim_location l ON l.location_key = f.location_key
WHERE l.location_key IS NULL;

-- Unknown counts: rows that point to key -1 (these match the data quality report and dashboard page 4)
INSERT INTO #results SELECT 'gold', 'fact rows with Unknown date',         769, COUNT_BIG(*) FROM gold.fact_transactions WHERE date_key = -1;
INSERT INTO #results SELECT 'gold', 'fact rows with Unknown category',     416, COUNT_BIG(*) FROM gold.fact_transactions WHERE category_key = -1;
INSERT INTO #results SELECT 'gold', 'fact rows with Unknown payment mode', 1182, COUNT_BIG(*) FROM gold.fact_transactions WHERE payment_mode_key = -1;
INSERT INTO #results SELECT 'gold', 'fact rows with Unknown location',     1801, COUNT_BIG(*) FROM gold.fact_transactions WHERE location_key = -1;

-- Silver rows with no date (and a usable amount) must equal fact rows with date_key -1 (difference should be 0)
INSERT INTO #results
SELECT 'gold', 'silver undated usable rows minus gold Unknown-date rows', 0,
       (SELECT COUNT_BIG(*) FROM silver.transactions WHERE transaction_date IS NULL AND amount IS NOT NULL)
     - (SELECT COUNT_BIG(*) FROM gold.fact_transactions WHERE date_key = -1);

-- =====================================================================
-- RESULT: one table, PASS or FAIL for every test
-- =====================================================================

SELECT
    layer,
    test_name,
    expected,
    actual,
    CASE WHEN expected = actual THEN 'PASS' ELSE 'FAIL' END AS result
FROM #results
ORDER BY CASE layer WHEN 'bronze' THEN 1 WHEN 'silver' THEN 2 ELSE 3 END, test_name;

-- Quick summary: how many passed and how many failed
SELECT
    SUM(CASE WHEN expected = actual THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN expected <> actual THEN 1 ELSE 0 END) AS failed,
    COUNT(*) AS total
FROM #results;

DROP TABLE #results;