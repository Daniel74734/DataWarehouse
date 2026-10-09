CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

	DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY

	SET @batch_start_time = GETDATE();

	TRUNCATE TABLE silver.transactions;

	WITH
		cleaned_src1 AS (
		SELECT
			transaction_id,
			user_id,
			COALESCE(
				TRY_CONVERT(DATE, date, 101),
				TRY_CONVERT(DATE, date, 105),
				TRY_CONVERT(DATE, date, 5),
				TRY_CONVERT(DATE, date, 23)
				)
			AS transaction_date,
			transaction_type,
			COALESCE(cm.correct_value, NULLIF(TRIM(b.category),'Unknown')) AS category,
			COALESCE(pm.correct_value, NULLIF(TRIM(b.payment_mode),'Unknown')) AS payment_mode,
			COALESCE(lm.correct_value, NULLIF(NULLIF(TRIM(b.location), ''), 'N/A'), 'Unknown') AS location,
				CASE
				WHEN amount_cleaned < 0 THEN NULL
				WHEN amount_cleaned > 100000 THEN NULL
				ELSE amount_cleaned
			END AS amount
		FROM (
		SELECT
			*,
			TRY_CONVERT(DECIMAL(18,2),
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
									REPLACE(
											REPLACE(amount, 'Rs.', ''),
												'$', ''),
													N'â‚¹', ''),
														N'₹', ''),
															'INR', ''),
																',', '')
				) AS amount_cleaned
		FROM bronze.transactions_src1
		) b
		LEFT JOIN silver.category_map cm
		ON b.category = cm.dirty_value
		LEFT JOIN silver.location_map lm
		ON b.location = lm.dirty_value
		LEFT JOIN silver.payment_mode_map pm
		ON b.payment_mode = pm.dirty_value
		),
		deduped_src1 AS (
			SELECT
				*,
				ROW_NUMBER() OVER(PARTITION BY transaction_id, user_id, transaction_date, transaction_type, category, payment_mode, location, amount ORDER BY (SELECT NULL)) AS dup_rn
			FROM cleaned_src1
			),

		final_src1 AS (
			SELECT
				'SRC1-' + transaction_id +
				CASE
					WHEN COUNT(*) OVER (PARTITION BY transaction_id) > 1
					THEN '-' + CAST(ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY (SELECT NULL)) AS NVARCHAR)
					ELSE ''
				END AS surrogate_key,
			transaction_id,
			user_id,
			transaction_date,
			transaction_type,
			category,
			payment_mode,
			location,
			amount
			FROM deduped_src1
			WHERE dup_rn = 1
		),

		cleaned_src2 AS (
		SELECT
			transaction_id,
			user_id,
				COALESCE(
				TRY_CONVERT(DATE, date, 101),
				TRY_CONVERT(DATE, date, 105),
				TRY_CONVERT(DATE, date, 5),
				TRY_CONVERT(DATE, date, 23)
				)
			AS transaction_date,
			transaction_type,
			COALESCE(cm.correct_value, NULLIF(TRIM(b.category),'Unknown')) AS category,
			COALESCE(pm.correct_value, NULLIF(TRIM(b.payment_mode),'Unknown')) AS payment_mode,
			COALESCE(lm.correct_value, NULLIF(NULLIF(TRIM(b.location), ''), 'N/A'), 'Unknown') AS location,
			CASE
				WHEN amount_cleaned < 0 THEN NULL
				WHEN amount_cleaned > 100000 THEN NULL
				ELSE amount_cleaned
			END AS amount
		FROM(
		SELECT
			*,
			TRY_CONVERT(DECIMAL(18,2),
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
									REPLACE(
											REPLACE(amount, 'Rs.', ''),
												'$', ''),
													N'â‚¹', ''),
														N'₹', ''),
															'INR', ''),
																',', '')
				) AS amount_cleaned
		FROM bronze.transactions_src2
		) b
		LEFT JOIN silver.category_map cm
		ON b.category = cm.dirty_value
		LEFT JOIN silver.location_map lm
		ON b.location = lm.dirty_value
		LEFT JOIN silver.payment_mode_map pm
		ON b.payment_mode = pm.dirty_value
		),
		deduped_src2 AS(
			SELECT
				*,
				ROW_NUMBER() OVER(PARTITION BY transaction_id, user_id, transaction_date, transaction_type, category, payment_mode, location, amount ORDER BY (SELECT NULL)) AS dup_rn
			FROM cleaned_src2
		),
		final_src2 AS(
			SELECT
				'SRC2-' + transaction_id +
				CASE
					WHEN COUNT(*) OVER (PARTITION BY transaction_id) > 1
					THEN '-' + CAST(ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY (SELECT NULL)) AS NVARCHAR)
					ELSE ''
				END AS surrogate_key,
			transaction_id,
			user_id,
			transaction_date,
			transaction_type,
			category,
			payment_mode,
			location,
			amount
			FROM deduped_src2
			WHERE dup_rn = 1
		)

	INSERT INTO silver.transactions (
		surrogate_key,
		transaction_id,
		user_id,
		transaction_date,
		transaction_type,
		category,
		payment_mode,
		location,
		amount
	)

	SELECT * FROM final_src1
	UNION ALL
	SELECT * FROM final_src2;

	SET @batch_end_time = GETDATE();

	PRINT'=====================================';
		PRINT'Silver Layer Load is complete';
		PRINT'	-Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT'======================================';
	END TRY

	BEGIN CATCH

			PRINT'===========================================';
			PRINT'ERROR OCCURED WHILE LOADING DATA';
			PRINT'Error message: ' + ERROR_MESSAGE();
			PRINT'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
			PRINT'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
			PRINT'===========================================';
		THROW;
		END CATCH
END

--SELECT * FROM silver.transactions
--EXEC silver.load_silver 
--SELECT COUNT(*) FROM silver.transactions
--drop procedure silver.load_silver