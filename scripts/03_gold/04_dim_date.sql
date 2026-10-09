IF OBJECT_ID('gold.dim_date', 'U') IS NOT NULL
	DROP TABLE gold.dim_date;
GO

CREATE TABLE gold.dim_date(
		date_key INT PRIMARY KEY,
		full_date DATE NOT NULL UNIQUE,
		year_number INT NOT NULL,
		quarter_number INT NOT NULL,
		month_number INT NOT NULL,
		month_name NVARCHAR(20) NOT NULL,
		day_of_month INT NOT NULL,
		day_name NVARCHAR(20) NOT NULL,
		is_weekend BIT NOT NULL
);
GO

WITH dates AS (
	SELECT 
		CAST('2019-01-01' AS DATE) AS d 
		UNION ALL 
		SELECT DATEADD(DAY, 1, d)
		FROM dates
		WHERE d < '2024-12-31'
)
INSERT INTO gold.dim_date
	SELECT 
		CONVERT(INT,CONVERT(CHAR(8),d, 112)), 
		d,
		YEAR(d),
		DATEPART(QUARTER, d),
		MONTH(d),
		DATENAME(MONTH, d),
		DAY(d),
		DATENAME(WEEKDAY, d),
		CASE 
			WHEN DATENAME(WEEKDAY, d) IN ('SATURDAY', 'SUNDAY') 
			THEN 1 
			ELSE 0 
		END 
	FROM dates

OPTION(MAXRECURSION 0);


INSERT INTO gold.dim_date
    (date_key, full_date, year_number, quarter_number, month_number,
     month_name, day_of_month, day_name, is_weekend)
VALUES
    (-1, '1900-01-01', 1900, 1, 1, 'Unknown', 1, 'Unknown', 0);

--SELECT COUNT(*) FROM gold.dim_date;   -- 2192
--SELECT TOP 7 date_key, full_date, day_name, is_weekend
--FROM gold.dim_date ORDER BY date_key; -- first row: 20190101, Tuesday, 0

--SELECT COUNT(*) FROM gold.dim_date;                          -- 2193
--SELECT * FROM gold.dim_date WHERE date_key = -1;             -- the Unknown row