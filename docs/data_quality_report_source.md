# BudgetWise — Data Quality Audit

**Sources:**
- `budgetwise_synthetic_dirty.csv` — 15,836 rows
- `budgetwise_finance_dataset.csv` — 15,900 rows

## 1. Source overlap (the key finding)

These are **not duplicate exports of the same file** — they're two separate, inconsistently-dirtied extracts from the same underlying population:

- Only **3,962 of ~31,700 transaction_ids** appear in both files. The rest are unique to one source or the other.
- All **150 user_ids in File 2 are also present in File 1's 192 users** — same customer base, different transaction slices.
- Each file has its own distinct typo/format "dialect" (see below), which is itself evidence they went through different (or differently-seeded) corruption processes.

**Implication for design:** this isn't a single cleaning pass — it's a **merge/reconcile pattern**. Treat each file as its own bronze source (`bronze.transactions_src1`, `bronze.transactions_src2`), clean independently, then union + dedupe on `transaction_id` at the silver stage, with a rule for what happens when the same transaction_id has conflicting values across sources (e.g. prefer non-null, prefer the more "parseable" record, or flag for review).

## 2. Duplicates

| | File 1 | File 2 |
|---|---|---|
| Duplicate `transaction_id` (within file) | 978 | 1,900 |
| Exact full-row duplicates (within file) | 804 | 900 |

Within-file duplication needs its own dedup step *before* the cross-file merge, or the union will inflate counts further.

## 3. Nulls (out of ~15,800–15,900 rows per file)

| Column | File 1 | File 2 |
|---|---|---|
| date | 344 | 486 |
| category | 158 | 285 |
| amount | 178 | 291 |
| payment_mode | 503 | 808 |
| location | 722 | 1,262 |
| notes | 1,534 | 2,821 |

`transaction_id`, `user_id`, `transaction_type` have zero nulls in both — safe to treat as reliable keys. `notes` is high-null and free text; low value for BI, candidate to drop from the gold model or keep only as an optional attribute.

## 4. Date chaos

At least **4 distinct formats mixed within each file**, plus stray inconsistent one-offs:
- `YYYY-MM-DD`
- `MM/DD/YYYY`
- `DD-MM-YYYY` and `DD-MM-YY`
- `Month DD YYYY` (e.g. "December 22 2021") — File 1 only

Because both `MM/DD/YYYY` and `DD/MM/YYYY`-style separators appear, some values are **structurally ambiguous** (e.g. `03/24/2022` is unambiguous since 24 can't be a month, but `04/05/2022` is not) — flag genuinely ambiguous rows rather than silently guessing.

## 5. Amount — three separate problems bundled into one column

- **Currency symbols mixed in-line:** `$`, `₹` (and no separate currency column) — File 1 also has thousands-separator commas (`$2,030`); File 2 does not.
- **Negative values:** 62 (File 1) / 153 (File 2) negative amounts. Need a business rule — legitimate refunds/adjustments vs. data entry errors — before deciding to keep, flip sign, or exclude.
- **Extreme outliers:** max values of 999,999 and 999,999,999 — clearly injected, not real transactions. These will wreck any average/sum KPI if not capped or excluded; document the threshold you choose.

## 6. Category — inconsistent + misspelled

Same categories appear under many spellings/cases across both files: `Rent`/`Reent`/`Rentt`, `Food`/`Fod`/`FOOD`/`food`/`Foods`, `Salary`/`Salaryy`, `Education`/`Educaton`/`education`, `Entertainment`/`Entertainmennt`/`entertainment`, `Utilities`/`Utilties`/`Utlities`/`Utility`, `Travel`/`Traavel`/`Tavel`/`Travl`. Needs a canonical mapping table (fuzzy-match or manual lookup) rather than a simple `UPPER()`/`TRIM()`, since case-normalizing alone won't fix the misspellings.

## 7. Payment mode — the worst offender

File 1 alone has **60 distinct spellings** of what are really just 4 categories (Cash, Card, UPI, Bank Transfer) — e.g. `Bank Transfer`, `Baank Transfer`, `Bank Tranfser`, `BankT ransfer`, `aBnk Transfer`. File 2 is milder (19 variants) but has its own casing issues (`CASH`/`Cash`/`cash`, `UPi`/`Upi`). This needs a lookup/fuzzy-match table, same as category.

## 8. Location — casing + File 2's abbreviations

- Both files: casing inconsistency (`MUMBAI`/`Mumbai`/`mumbai`).
- File 2 additionally introduces **3-letter abbreviations** (`AHM`, `BAN`, `CHE`, `DEL`, `HYD`, `JAI`, `KOL`, `LUC`, `MUM`, `PUN`) that need mapping back to full city names — and File 2 uses "Bangalore" where File 1 uses "Bengaluru" for the same city, so the canonical list itself needs a decision.

## Recommended next step (Step 3)

Build a canonical lookup/mapping approach for `category`, `payment_mode`, and `location` (small reference tables, not inline CASE statements — more maintainable and it's a nice thing to show in the repo), a documented amount-cleaning rule (strip symbols → cast → cap/flag outliers → decide on negatives), and a date-parsing rule that tries formats in order and flags what doesn't parse rather than defaulting to NaT silently.
