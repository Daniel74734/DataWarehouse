IF OBJECT_ID('gold.dim_payment_mode', 'U') IS NOT NULL
	DROP TABLE gold.dim_payment_mode;
GO

CREATE TABLE gold.dim_payment_mode(
	payment_mode_key INT IDENTITY(1,1) PRIMARY KEY, 
	payment_mode_name NVARCHAR(50) NOT NULL UNIQUE
);
GO

--SET IDENTITY_INSERT gold.dim_payment_mode ON;
--SET IDENTITY_INSERT gold.dim_payment_mode OFF;

INSERT INTO gold.dim_payment_mode (payment_mode_key, payment_mode_name) VALUES (
	-1, 'Unknown');

INSERT INTO gold.dim_payment_mode (payment_mode_name) 
SELECT DISTINCT correct_value
FROM silver.payment_mode_map
WHERE correct_value <> 'Unknown'
ORDER BY correct_value;