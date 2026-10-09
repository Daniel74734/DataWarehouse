IF OBJECT_ID('gold.dim_location', 'U') IS NOT NULL
	DROP TABLE gold.dim_location;
GO

CREATE TABLE gold.dim_location(
	location_key INT IDENTITY(1,1) PRIMARY KEY, 
	location_name NVARCHAR(50) NOT NULL UNIQUE
);
GO

--SET IDENTITY_INSERT gold.dim_location ON;
--SET IDENTITY_INSERT gold.dim_location OFF;

INSERT INTO gold.dim_location (location_key, location_name) VALUES (
	-1, 'Unknown');

INSERT INTO gold.dim_location (location_name) 
SELECT DISTINCT correct_value
FROM silver.location_map
WHERE correct_value <> 'Unknown'
ORDER BY correct_value;