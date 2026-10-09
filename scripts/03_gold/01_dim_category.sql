IF OBJECT_ID('gold.dim_category', 'U') IS NOT NULL
	DROP TABLE gold.dim_category;
GO

CREATE TABLE gold.dim_category(
	category_key INT IDENTITY(1,1) PRIMARY KEY, 
	category_name NVARCHAR(50) NOT NULL UNIQUE
);
GO

--SET IDENTITY_INSERT gold.dim_category ON;
--SET IDENTITY_INSERT gold.dim_category OFF;


INSERT INTO gold.dim_category (category_key, category_name) VALUES (
	-1, 'Unknown');


INSERT INTO gold.dim_category (category_name) 
SELECT DISTINCT correct_value
FROM silver.category_map
WHERE correct_value <> 'Unknown'
ORDER BY correct_value;