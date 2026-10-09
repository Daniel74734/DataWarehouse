-- Create the data warehouse database
-- WARNING: this script DROPS and recreates BudgetWiseDW. Do not run it on a database you want to keep.
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'BudgetWiseDW')
BEGIN
	ALTER DATABASE BudgetWiseDW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE BudgetWiseDW;
END;
GO
CREATE DATABASE BudgetWiseDW;
GO

-- Switch into the new database
USE BudgetWiseDW;
GO

-- Bronze layer: raw, untouched data per source
CREATE SCHEMA bronze;
GO

-- Silver layer: cleaned, standardized, deduplicated data
CREATE SCHEMA silver;
GO

-- Gold layer: business-ready star schema for reporting
CREATE SCHEMA gold;
GO