CREATE OR ALTER PROCEDURE gold.load_gold AS 
BEGIN	
	SET NOCOUNT ON;

	DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;

	BEGIN TRY

	    SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Gold Layer';
        PRINT '================================================';
		BEGIN TRANSACTION;


		DELETE gold.fact_transactions;


		DELETE gold.dim_category;
		DELETE gold.dim_payment_mode;
		DELETE gold.dim_location;
		DELETE gold.dim_date;



		DBCC CHECKIDENT ('gold.dim_category', RESEED, 0);
		DBCC CHECKIDENT ('gold.dim_payment_mode', RESEED, 0);
		DBCC CHECKIDENT ('gold.dim_location', RESEED, 0);


		SET IDENTITY_INSERT gold.dim_category ON;
		INSERT INTO gold.dim_category (category_key, category_name) VALUES (
		-1, 'Unknown');
		SET IDENTITY_INSERT gold.dim_category OFF;

		INSERT INTO gold.dim_category (category_name) 
		SELECT DISTINCT correct_value
		FROM silver.category_map
		WHERE correct_value <> 'Unknown'
		ORDER BY correct_value;



		SET IDENTITY_INSERT gold.dim_location ON;
		INSERT INTO gold.dim_location (location_key, location_name) VALUES (
		-1, 'Unknown');
		SET IDENTITY_INSERT gold.dim_location OFF;

		INSERT INTO gold.dim_location (location_name) 
		SELECT DISTINCT correct_value
		FROM silver.location_map
		WHERE correct_value <> 'Unknown'
		ORDER BY correct_value;


		SET IDENTITY_INSERT gold.dim_payment_mode ON;
		INSERT INTO gold.dim_payment_mode (payment_mode_key, payment_mode_name) VALUES (
		-1, 'Unknown');
		SET IDENTITY_INSERT gold.dim_payment_mode OFF;

		INSERT INTO gold.dim_payment_mode (payment_mode_name) 
		SELECT DISTINCT correct_value
		FROM silver.payment_mode_map
		WHERE correct_value <> 'Unknown'
		ORDER BY correct_value;



		WITH dates AS (
		SELECT 
			CAST('2019-01-01' AS DATE) AS d 
			UNION ALL 
			SELECT DATEADD(DAY, 1, d)
			FROM dates
			WHERE d < '2024-12-31'
		)
		INSERT INTO gold.dim_date
					(date_key, full_date, year_number, quarter_number, month_number, 
					month_name, day_of_month, day_name, is_weekend)
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
		 VALUES (-1, '1900-01-01', 1900, 1, 1, 'Unknown', 1, 'Unknown', 0);

		INSERT INTO gold.fact_transactions (
			transaction_id,
			user_id,
			transaction_type,
			date_key,
			category_key,
			payment_mode_key,
			location_key,
			amount)

		SELECT 
			t.transaction_id,
			t.user_id,
			t.transaction_type,
			COALESCE(CONVERT(INT,CONVERT(CHAR(8),t.transaction_date, 112)), -1),
			COALESCE(c.category_key,-1),
			COALESCE(pm.payment_mode_key,-1),
			COALESCE(l.location_key,-1),
			t.amount
		FROM silver.transactions t
		LEFT JOIN  gold.dim_category c
		ON c.category_name = t.category
		LEFT JOIN gold.dim_payment_mode pm
		ON pm.payment_mode_name = t.payment_mode
		LEFT JOIN gold.dim_location l 
		ON l.location_name = t.location
		WHERE t.amount IS NOT NULL;

		COMMIT TRANSACTION;
        SET @batch_end_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Gold Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';
	END TRY
	BEGIN CATCH
		        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'gold.load_gold FAILED: ' + ERROR_MESSAGE();
		PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING LOADING GOLD LAYER';
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '================================================';
        THROW;
	END CATCH
END;
GO 


--EXEC gold.load_gold;

--SELECT COUNT(*) FROM gold.fact_transactions;   -- 29067
--SELECT COUNT(*) FROM gold.dim_category;        -- 16
--SELECT COUNT(*) FROM gold.dim_payment_mode;    -- 5
--SELECT COUNT(*) FROM gold.dim_location;        -- 11
--SELECT COUNT(*) FROM gold.dim_date;            -- 2193