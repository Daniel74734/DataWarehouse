-- silver.payment_mode_map: lookup table mapping dirty/misspelled payment mode values (both sources) to correct values
-- populated once as a permanent reference table, joined against from each source during silver cleaning
DROP TABLE IF EXISTS silver.payment_mode_map;
CREATE TABLE silver.payment_mode_map(
	dirty_value VARCHAR (50),
	correct_value VARCHAR(50) NOT NULL
)

INSERT INTO silver.payment_mode_map(dirty_value, correct_value) 
VALUES 
    ('Baank Transfer', 'Bank Transfer'),
    ('Bak Transfer', 'Bank Transfer'),
    ('Ban Transfer', 'Bank Transfer'),
    ('Bank TTransfer', 'Bank Transfer'),
    ('Bank Tarnsfer', 'Bank Transfer'),
    ('Bank Traansfer', 'Bank Transfer'),
    ('Bank Tranfser', 'Bank Transfer'),
    ('Bank Trannsfer', 'Bank Transfer'),
    ('Bank Transefr', 'Bank Transfer'),
    ('Bank Transer', 'Bank Transfer'),
    ('Bank Transfe', 'Bank Transfer'),
    ('Bank Transfeer', 'Bank Transfer'),
    ('Bank Transfer', 'Bank Transfer'),
    ('Bank Transferr', 'Bank Transfer'),
    ('Bank Transffer', 'Bank Transfer'),
    ('Bank Transfr', 'Bank Transfer'),
    ('Bank Transsfer', 'Bank Transfer'),
    ('Bank Trasfer', 'Bank Transfer'),
    ('Bank Trasnfer', 'Bank Transfer'),
    ('Bank Trnasfer', 'Bank Transfer'),
    ('Bank Trnsfer', 'Bank Transfer'),
    ('Bank Trransfer', 'Bank Transfer'),
    ('Bank rTansfer', 'Bank Transfer'),
    ('BankT ransfer', 'Bank Transfer'),
    ('BankTransfer', 'Bank Transfer'),
    ('Bank_Transfer', 'Bank Transfer'),
    ('Bankk Transfer', 'Bank Transfer'),
    ('Bnk Transfer', 'Bank Transfer'),
    ('CASH', 'Cash'),
    ('CCard', 'Card'),
    ('CCash', 'Cash'),
    ('Caard', 'Card'),
    ('Caash', 'Cash'),
    ('Cad', 'Card'),
    ('Cadr', 'Card'),
    ('Cah', 'Cash'),
    ('Cahs', 'Cash'),
    ('Car', 'Card'),
    ('Card', 'Card'),
    ('Cardd', 'Card'),
    ('Carrd', 'Card'),
    ('Cas', 'Cash'),
    ('Cash', 'Cash'),
    ('Cashh', 'Cash'),
    ('Cassh', 'Cash'),
    ('Crad', 'Card'),
    ('Crd', 'Card'),
    ('Csah', 'Cash'),
    ('Csh', 'Cash'),
    ('PI', 'UPI');
 
INSERT INTO silver.payment_mode_map (dirty_value, correct_value)
VALUES
    ('PUI', 'UPI'),
    ('UI', 'UPI'),
    ('UIP', 'UPI'),
    ('UP', 'UPI'),
    ('UPI', 'UPI'),
    ('UPII', 'UPI'),
    ('UPPI', 'UPI'),
    ('UUPI', 'UPI'),
    ('aBnk Transfer', 'Bank Transfer'),
    ('aCrd', 'Card'),
    ('aCsh', 'Cash'),
    ('ank Transfer', 'Bank Transfer'),
    ('ard', 'Card'),
    ('ash', 'Cash'),
    ('bank transfer', 'Bank Transfer'),
    ('card', 'Card');
 

