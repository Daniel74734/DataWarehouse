IF OBJECT_ID('gold.fact_transactions', 'U') IS NOT NULL
	DROP TABLE gold.fact_transactions;
GO

CREATE TABLE gold.fact_transactions(
	fact_key INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	transaction_id NVARCHAR(50) NOT NULL,
	user_id NVARCHAR(50) NOT NULL,
	transaction_type NVARCHAR(50) NOT NULL,
	date_key INT NOT NULL,
	category_key INT NOT NULL,
	payment_mode_key INT NOT NULL,
	location_key INT NOT NULL,
	amount DECIMAL(18,2) NOT NULL,
	FOREIGN KEY (date_key) REFERENCES gold.dim_date(date_key),
	FOREIGN KEY (category_key) REFERENCES gold.dim_category(category_key),
	FOREIGN KEY (payment_mode_key) REFERENCES gold.dim_payment_mode(payment_mode_key),
	FOREIGN KEY (location_key) REFERENCES gold.dim_location(location_key)
);
GO


