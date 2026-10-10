# BudgetWiseDW Data Quality Report (Warehouse)

Report date: 2026-10-10

This report describes data quality **after** the bronze, silver and gold layers were built. It complements `DATA_QUALITY_REPORT.md`, which profiles the raw source files before any design decisions were made.

## 1. Scope

| Item | Detail |
|---|---|
| Database | BudgetWiseDW (SQL Server) |
| Sources | `budgetwise_finance_dataset.csv` (src1), `budgetwise_synthetic_dirty.csv` (src2) |
| Layers covered | Bronze, silver, gold |
| Date range of transactions | 2019-01-01 to 2024-12-31 |

## 2. Source characteristics

- The two files are **independent transaction populations**. Their `transaction_id` values overlap by coincidence, so they are not duplicate exports of each other. Records from both sources are kept and given a source-prefixed surrogate key.
- src2 has dirtier text values (inconsistent category, payment mode and location spellings) but fewer missing values than src1.

## 3. Issues found and how each was handled

| Area | Issue | Handling | Layer |
|---|---|---|---|
| Encoding | Currency symbols arrived as garbled characters (mojibake) when loaded | Loaded with `CODEPAGE = '65001'` (UTF-8); remaining garbled rupee strings stripped during amount cleaning | Bronze, silver |
| Dates | Four different formats in the source | Parsed with `TRY_CONVERT` styles 101, 105, 5 and 23; unparseable or blank values stay `NULL` | Silver |
| Amounts | Currency text (`Rs.`, `$`, `INR`, rupee symbol) and thousands separators inside the value | Stripped, then converted to `DECIMAL(18,2)` | Silver |
| Amounts | Negative values and extreme outliers (for example 99999999999999) | Set to `NULL` (negative, or above 100,000) | Silver |
| Categories | 229 dirty variants | Mapped to 15 canonical categories in `silver.category_map` | Silver |
| Payment modes | 66 dirty variants | Mapped to 4 canonical values in `silver.payment_mode_map` | Silver |
| Locations | City spelling variants and three-letter abbreviations | Mapped to 10 Indian cities in `silver.location_map`; "Bengaluru" is the canonical spelling | Silver |
| Locations | `N/A` placeholder text | Converted to `Unknown` | Silver |
| Duplicates | Fully identical rows within a source | Removed (first occurrence kept) | Silver |
| ID collisions | Same `transaction_id` with different data | Kept; numeric suffix added to the surrogate key | Silver |
| Missing values | Blank dates, categories, payment modes, locations | Dates stay `NULL` in silver; category and payment mode stay `NULL` in silver; location becomes `Unknown` | Silver |

## 4. Gold layer handling of missing values

Every dimension has an **Unknown member with key -1**. The fact load uses `COALESCE(key, -1)` so no fact row has a missing key.

| Dimension | Rows at Unknown key (-1) in the fact table |
|---|---|
| Date | 769 |
| Category | 416 |
| Payment mode | 1,182 |
| Location | 1,801 |

Rows with a `NULL` amount (missing in the source, or removed as an outlier or negative value) are **excluded from gold**. They remain available in silver.

## 5. Reconciliation checks

| Check | Result |
|---|---|
| Silver rows with a non-null amount | 29,067 |
| Gold fact rows | 29,067 (matches) |
| `dim_category` rows | 16 (15 categories + Unknown) |
| `dim_payment_mode` rows | 5 (4 values + Unknown) |
| `dim_location` rows | 11 (10 cities + Unknown) |
| `dim_date` rows | 2,193 (2,192 days + Unknown) |
| Location values in silver with no match in `dim_location` | 0 |
| Fact rows with a key missing from its dimension | 0 |

The gold load procedure was run twice and produced identical counts, so it is safe to rerun.

## 6. Known limitations

- Silver keeps `NULL` for missing categories and payment modes, while location uses `Unknown`. Gold treats all of them the same way (key -1).
- The outlier rule (negative or above 100,000) is a fixed threshold chosen from profiling, not a statistical test. Valid but very large transactions would also be excluded.
- `Others` and `Misc` remain separate categories.
- Excluding null-amount rows from gold means gold totals describe only transactions with a usable amount.

## 7. Queries used for verification

```sql
-- fact table reconciles with silver
SELECT COUNT(*) FROM silver.transactions WHERE amount IS NOT NULL;
SELECT COUNT(*) FROM gold.fact_transactions;

-- rows that fell back to the Unknown key, per dimension
SELECT COUNT(*) FROM gold.fact_transactions WHERE date_key = -1;
SELECT COUNT(*) FROM gold.fact_transactions WHERE category_key = -1;
SELECT COUNT(*) FROM gold.fact_transactions WHERE payment_mode_key = -1;
SELECT COUNT(*) FROM gold.fact_transactions WHERE location_key = -1;

-- silver values that do not match a gold dimension
SELECT t.location, COUNT(*) AS rows_affected
FROM silver.transactions t
LEFT JOIN gold.dim_location l ON l.location_name = t.location
WHERE t.amount IS NOT NULL AND l.location_key IS NULL AND t.location IS NOT NULL
GROUP BY t.location;
```
