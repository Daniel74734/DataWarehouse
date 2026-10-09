CREATE TABLE silver.transactions(
	surrogate_key NVARCHAR(50) PRIMARY KEY NOT NULL,
	transaction_id NVARCHAR(50),
	user_id NVARCHAR(50),
	transaction_date DATE,
	transaction_type NVARCHAR(50),
	category NVARCHAR(50),
	payment_mode NVARCHAR(50),
	location NVARCHAR(50),
	amount DECIMAL(18,2)
)

