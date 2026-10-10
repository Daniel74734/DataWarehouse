# BudgetWise Personal Finance Warehouse

End-to-end SQL Server data warehouse (bronze/silver/gold) that cleans two messy personal finance datasets into a star schema for expense analytics.

## What this project is

BudgetWise is a fictional AI-powered expense forecasting tool. It needs one clean, trustworthy source of transactions. This project builds that source: two messy CSV files go in, and a star schema ready for reporting comes out.

## Architecture

| Layer | What it holds |
|---|---|
| Bronze | Raw data exactly as it arrived. Every column is text, with no cleaning. |
| Silver | Cleaned and standardised data: parsed dates, numeric amounts, canonical categories, payment modes and locations, duplicates removed. |
| Gold | Star schema for reporting: one fact table and four dimensions. |

```
CSV files -> bronze -> silver -> gold -> Power BI
```

## Gold star schema

- `fact_transactions`: one row per transaction, with an amount and keys to the four dimensions
- `dim_category`
- `dim_payment_mode`
- `dim_location`
- `dim_date`

Every dimension has an **Unknown** row with key -1, so a transaction with a missing value still links to something.

## Tech stack

SQL Server Developer Edition, SSMS, Power BI Desktop

## Data

The source files are not stored in this repository. Download them from the Kaggle dataset [BudgetWise Personal Finance Dataset](https://www.kaggle.com/datasets/mohammedarfathr/budgetwise-personal-finance-dataset) and use these two files:

- `budgetwise_finance_dataset.csv`
- `budgetwise_synthetic_dirty.csv`

## How to run it

Run the scripts in `scripts/` in this order, using SSMS:

1. `00_init`: creates the database and the three schemas. **Warning:** this script drops and recreates `BudgetWiseDW`.
2. `01_bronze`: create the tables, then the load procedure. Before running, replace `<path_to_data_folder>` in `02_load_bronze.sql` with the folder that holds your CSV files. Then run `EXEC bronze.load_bronze;`
3. `02_silver`: create the tables, the three mapping tables, then the load procedure. Run `EXEC silver.load_silver;`
4. `03_gold`: create the four dimensions and the fact table, then the load procedure. Run `EXEC gold.load_gold;`

## Results

| Check | Result |
|---|---|
| Gold fact rows | 29,067 (matches silver rows with a usable amount) |
| `dim_category` | 15 categories + Unknown |
| `dim_payment_mode` | 4 values + Unknown |
| `dim_location` | 10 cities + Unknown |
| `dim_date` | 2019-01-01 to 2024-12-31 + Unknown |

## Key design decisions

- **Two independent sources.** Their `transaction_id` values overlap by coincidence, so the fact table has its own surrogate key instead of using `transaction_id`.
- **Bronze is a faithful mirror.** No renaming, casting or cleaning happens there.
- **Missing values.** Dates stay NULL in silver. In gold, every missing key maps to the Unknown row (-1).
- **Bad amounts.** Negative values and extreme outliers are set to NULL in silver, and rows with no usable amount are left out of gold.
- **Reloading gold.** The load procedure uses `DELETE` plus an identity reseed, because foreign keys stop `TRUNCATE` from working.
- **Encoding.** Bronze loads with `CODEPAGE = '65001'` (UTF-8) so currency symbols are not corrupted.

## Dashboard

A Power BI dashboard built on the gold layer is in progress and will be added here.

## Documentation

- `docs/data_quality_report_source.md`: problems found in the raw files, before design
- `docs/data_quality_report_warehouse.md`: how each problem was handled, with reconciliation checks

## Author

Daniel Okoh, [GitHub](https://github.com/Daniel74734)