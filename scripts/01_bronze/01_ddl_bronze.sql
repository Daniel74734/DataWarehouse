-- Bronze table for source 1(budgetwise_finance_dataset.csv)
IF OBJECT_ID('bronze.transactions_src1','U') IS NOT NULL
	DROP TABLE bronze.transactions_src1;

CREATE TABLE bronze.transactions_src1(
	 transaction_id NVARCHAR(50),
	 user_id NVARCHAR(50),
	 date NVARCHAR(50),
	 transaction_type NVARCHAR(50),
	 category NVARCHAR(50),
	 amount NVARCHAR(50),
	 payment_mode NVARCHAR(50),
	 location NVARCHAR(50),
	 notes NVARCHAR(100)
);
GO


IF OBJECT_ID('bronze.transactions_src2', 'U')IS NOT NULL
	DROP TABLE bronze.transactions_src2;
-- Bronze table for source 2 (budgetwise_synthetic_dirty.csv)
CREATE TABLE bronze.transactions_src2(
     transaction_id NVARCHAR(50),
	 user_id NVARCHAR(50),
	 date NVARCHAR(50),
	 transaction_type NVARCHAR(50),
	 category NVARCHAR(50),
	 amount NVARCHAR(50),
	 payment_mode NVARCHAR(50),
	 location NVARCHAR(50),
	 notes NVARCHAR(100)
);
GO 