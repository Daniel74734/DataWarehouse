-- silver.location_map: lookup table mapping dirty/misspelled category spellings (both sources) to correct values
-- populated once as a permanent reference table, joined against from each source during silver cleaning
DROP TABLE IF EXISTS silver.location_map;
CREATE TABLE silver.location_map(
	dirty_value VARCHAR (50),
	correct_value VARCHAR(50) NOT NULL
)

 
INSERT INTO silver.location_map (dirty_value, correct_value) 
VALUES
	('AHM', 'Ahmedabad'),
	('AHMEDABAD', 'Ahmedabad'),
	('BAN', 'Bengaluru'),
	('BANGALORE', 'Bengaluru'),
	('Bengaluru', 'Bengaluru'),
	('CHE', 'Chennai'),
	('Chennai', 'Chennai'),
	('chennai', 'Chennai'),
	('DEL', 'Delhi'),
	('delhi', 'Delhi'),
	('HYD', 'Hyderabad'),
	('hyderabad', 'Hyderabad'),
	('Hyderabad', 'Hyderabad'),
	('JAI', 'Jaipur'),
	('Jaipur', 'Jaipur'),
	('KOL', 'Kolkata'),
	('KOLKATA', 'Kolkata'),
	('kolkata', 'Kolkata'),
	('LUC', 'Lucknow'),
	('Lucknow', 'Lucknow'),
	('MUM', 'Mumbai'),
	('Mumbai', 'Mumbai'),
	('PUN', 'Pune'),
	('PUNE', 'Pune'),
	('Pune', 'Pune');