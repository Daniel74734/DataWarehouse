CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN

	DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY

	SET @batch_start_time = GETDATE();


	TRUNCATE TABLE bronze.transactions_src1;
	TRUNCATE TABLE bronze.transactions_src2;

	BULK INSERT bronze.transactions_src1
	FROM '<path_to_data_folder>\budgetwise_finance_dataset.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		FORMAT = 'CSV',
		TABLOCK,
		CODEPAGE = '65001'
	);
	

	BULK INSERT bronze.transactions_src2
	FROM '<path_to_data_folder>\budgetwise_synthetic_dirty.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		FORMAT = 'CSV',
		TABLOCK,
		CODEPAGE = '65001'
	);

	SET @batch_end_time = GETDATE();

	PRINT'=====================================';
		PRINT'Bronze Layer Load is complete';
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

--SELECT * FROM bronze.transactions_src1
--SELECT * FROM bronze.transactions_src2
-- EXEC bronze.load_bronze
--SELECT COUNT(*) FROM bronze.transactions_src1
--SELECT COUNT(*) FROM bronze.transactions_src2