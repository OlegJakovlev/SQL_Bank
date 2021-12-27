-- Drop database if already exists
DROP DATABASE IF EXISTS banking_system;

-- Create a database
CREATE DATABASE IF NOT EXISTS banking_system;

-- Enable events
SET GLOBAL event_scheduler="ON";

-- Make possible credit transactions
-- https://dev.mysql.com/doc/refman/5.6/en/sql-mode.html#sqlmode_no_unsigned_subtraction
SET sql_mode = 'NO_UNSIGNED_SUBTRACTION';

-- Switch to database
USE banking_system;

/* #region TABLES AND COLUMNS */

/* SHOULD BE BCNF: https://www.studytonight.com/dbms/database-normalization.php */

CREATE TABLE IF NOT EXISTS bank_information (
    bank_ID SMALLINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    sort_code VARCHAR(10) NOT NULL UNIQUE,
    SWIFT VARCHAR (11) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS regional_information (
    regional_information_ID INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    country_name VARCHAR(63) NOT NULL, -- the Separate Customs Territory of Taiwan, Penghu, Kinmen, and Matsu
    postcode VARCHAR(10) NOT NULL,
    city_name VARCHAR(85) NOT NULL
);

CREATE TABLE IF NOT EXISTS client_details (
    reference_number CHAR(12) NOT NULL PRIMARY KEY,
    full_name VARCHAR(60) NOT NULL,
    birth_date DATE NOT NULL,
    adress VARCHAR(30) NOT NULL, -- Henry street 5
    adress_2 VARCHAR(30), -- Apartament 342
    regional_information_ID INT UNSIGNED NOT NULL,
    telephone_number VARCHAR(15) NOT NULL UNIQUE,
    FOREIGN KEY (regional_information_ID) REFERENCES regional_information(regional_information_ID)
);

CREATE TABLE IF NOT EXISTS client_access (
    reference_number CHAR(12) NOT NULL PRIMARY KEY,
    password_salt VARCHAR(64) NOT NULL UNIQUE,
    password_hash VARCHAR(128) NOT NULL,
    FOREIGN KEY (reference_number) REFERENCES client_details(reference_number)
);

CREATE TABLE IF NOT EXISTS account (
    account_number BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    account_status ENUM("Waiting for Deposit","Open","Pending Termination","Closed","Archived") NOT NULL DEFAULT "Waiting for Deposit",
    bank_ID SMALLINT UNSIGNED NOT NULL,
    FOREIGN KEY (bank_ID) REFERENCES bank_information(bank_ID)
);

CREATE TABLE IF NOT EXISTS account_IBAN (
    IBAN VARCHAR(34) NOT NULL PRIMARY KEY,
    account_number BIGINT UNSIGNED NOT NULL,
    FOREIGN KEY (account_number) REFERENCES account(account_number)
);

CREATE TABLE IF NOT EXISTS client_account (
    reference_number CHAR(12) NOT NULL,
    account_number BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (reference_number, account_number),
    FOREIGN KEY (reference_number) REFERENCES client_details(reference_number),
    FOREIGN KEY (account_number) REFERENCES account(account_number)
);

CREATE TABLE IF NOT EXISTS currency_list (
	currency_ID TINYINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    alphabetic_code VARCHAR(3) NOT NULL UNIQUE,
    symbol VARCHAR(3) NOT NULL
);

CREATE TABLE IF NOT EXISTS account_balance (
    account_number BIGINT UNSIGNED NOT NULL,
    currency_ID TINYINT UNSIGNED NOT NULL,
    amount FLOAT(2) NOT NULL,
    PRIMARY KEY (account_number, currency_ID),
    FOREIGN KEY (account_number) REFERENCES account(account_number),
    FOREIGN KEY (currency_ID) REFERENCES currency_list(currency_ID)
);

CREATE TABLE IF NOT EXISTS loan (
    loan_ID INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    given_amount FLOAT(2) NOT NULL,
    repaid_amount FLOAT(2) NOT NULL,
    currency_ID TINYINT UNSIGNED NOT NULL,
    FOREIGN KEY (currency_ID) REFERENCES currency_list(currency_ID)
);

CREATE TABLE IF NOT EXISTS loan_payment (
    loan_ID INT UNSIGNED NOT NULL PRIMARY KEY,
    total_expected_number_of_payments SMALLINT UNSIGNED NOT NULL,
    first_payment_date DATE NOT NULL,
    payment_due_date DATETIME NOT NULL,
    FOREIGN KEY (loan_ID) REFERENCES loan(loan_ID)
);

CREATE TABLE IF NOT EXISTS account_loan (
    account_number BIGINT UNSIGNED NOT NULL,
    loan_ID INT UNSIGNED NOT NULL,
    payment_rate INT UNSIGNED NOT NULL,
    PRIMARY KEY (account_number, loan_ID),
    FOREIGN KEY (account_number) REFERENCES account(account_number),
    FOREIGN KEY (loan_ID) REFERENCES loan(loan_ID)
);

CREATE TABLE IF NOT EXISTS bargain (
    bargain_ID INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    amount FLOAT(2) UNSIGNED NOT NULL,
    currency_ID TINYINT UNSIGNED NOT NULL,
    bargain_status ENUM ("Waiting for Date", "Pending","Failed", "Succesful") NOT NULL DEFAULT "Waiting for Date",
    bargain_date DATETIME NOT NULL,
    bargain_description VARCHAR(255) NOT NULL,
    FOREIGN KEY (currency_ID) REFERENCES currency_list(currency_ID)
);

CREATE TABLE IF NOT EXISTS local_bargain (
    bargain_ID INT UNSIGNED NOT NULL PRIMARY KEY,
    sender_account_number BIGINT UNSIGNED NOT NULL,
    receiver_account_number BIGINT UNSIGNED NOT NULL,
    FOREIGN KEY (bargain_ID) REFERENCES bargain(bargain_ID),
    FOREIGN KEY (sender_account_number) REFERENCES account(account_number),
    FOREIGN KEY (receiver_account_number) REFERENCES account(account_number)
);

CREATE TABLE IF NOT EXISTS international_bargain (
    bargain_ID INT UNSIGNED NOT NULL PRIMARY KEY,
    sender_IBAN VARCHAR(34) NOT NULL,
    receiver_IBAN VARCHAR(34) NOT NULL,
    FOREIGN KEY (bargain_ID) REFERENCES bargain(bargain_ID),
    FOREIGN KEY (sender_IBAN) REFERENCES account_IBAN(IBAN),
    FOREIGN KEY (receiver_IBAN) REFERENCES account_IBAN(IBAN)
);

CREATE TABLE IF NOT EXISTS incoming_bargain (
    bargain_ID INT UNSIGNED NOT NULL PRIMARY KEY,
    receipt_date DATETIME NOT NULL,
    FOREIGN KEY (bargain_ID) REFERENCES bargain(bargain_ID)
);

CREATE TABLE IF NOT EXISTS outgoing_bargain (
    bargain_ID INT UNSIGNED NOT NULL PRIMARY KEY,
    planned_date DATETIME NOT NULL,
    FOREIGN KEY (bargain_ID) REFERENCES bargain(bargain_ID)
);

CREATE TABLE IF NOT EXISTS stock (
    stock_code VARCHAR(5) NOT NULL PRIMARY KEY, -- AAPL
    stock_name VARCHAR(50) NOT NULL UNIQUE, -- Apple
    sell_price FLOAT(2) UNSIGNED NOT NULL,
    buy_price FLOAT(2) UNSIGNED NOT NULL,
    available_to_buy BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS account_stock (
    account_number BIGINT UNSIGNED NOT NULL,
    stock_code VARCHAR(5) NOT NULL,
    shares FLOAT(8) UNSIGNED NOT NULL,
    PRIMARY KEY (account_number, stock_code),
    FOREIGN KEY (account_number) REFERENCES account(account_number),
    FOREIGN KEY (stock_code) REFERENCES stock(stock_code)
);

CREATE TABLE IF NOT EXISTS card_details (
    card_ID BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    card_salt CHAR(64) NOT NULL UNIQUE,
    card_hash CHAR(128) NOT NULL, -- Card hash consist of card number + card expiry date + salt
    CVV_hash CHAR(128) NOT NULL,
    PIN_hash CHAR(128) NOT NULL,
    internet_shopping_available BOOLEAN NOT NULL DEFAULT 0,
    frozen BOOLEAN NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS card_daily_limit (
    card_ID BIGINT UNSIGNED NOT NULL PRIMARY KEY,
    limit_amount FLOAT(2) NOT NULL,
    FOREIGN KEY (card_ID) REFERENCES card_details(card_ID)
);

CREATE TABLE IF NOT EXISTS account_card (
    account_number BIGINT UNSIGNED NOT NULL,
    card_ID BIGINT UNSIGNED NOT NULL,
    card_main_currency TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (account_number, card_ID),
    FOREIGN KEY (account_number) REFERENCES account(account_number),
    FOREIGN KEY (card_ID) REFERENCES card_details(card_ID),
    FOREIGN KEY (card_main_currency) REFERENCES currency_list(currency_ID)
);

CREATE TABLE IF NOT EXISTS customer_sessions (
    session_UUID CHAR(36) NOT NULL PRIMARY KEY DEFAULT UUID(),
    reference_number CHAR(12) NOT NULL,
    customer_IP VARCHAR(46) NOT NULL,
    secret_key_salt CHAR(64) NOT NULL UNIQUE,
    secret_key_hashed VARCHAR(128) NOT NULL,
    token_salt CHAR(64) NOT NULL UNIQUE,
    token_hashed VARCHAR(128) NOT NULL,
    token_expiry_date DATETIME NOT NULL,
    FOREIGN KEY (reference_number) REFERENCES client_details(reference_number)
);

-- USED FOR DEBUGGING PROCEDURES AND FUNCTIONS
/*
INSERT INTO tmptest (test) select concat('myvar is ', bargain_ID);
CREATE TABLE tmptest (
    test VARCHAR (255)
);
*/

/* #endregion */

/* #region USER ROLES */

-- Senior developer
-- Bill Developers
-- Non-Bill Developers
-- Manager
-- Clerk
-- Auditor (support)

CREATE ROLE IF NOT EXISTS 'senior_developer', 'bill_developer', 'non_bill_developer', 'bank_manager', 'bank_clerk', 'bank_auditor';

/* #endregion */

/* #region VIEWS */
-- https://mariadb.com/kb/en/creating-using-views

-- View all account of clients
CREATE OR REPLACE SQL SECURITY INVOKER VIEW view_user_accounts AS
SELECT client_details.reference_number, client_details.full_name, client_account.account_number
FROM client_details
INNER JOIN client_account ON client_details.reference_number=client_account.reference_number;

-- View all balances for each account
CREATE OR REPLACE SQL SECURITY INVOKER VIEW view_account_balance AS
SELECT account_balance.account_number, account_balance.amount, currency_list.alphabetic_code , currency_list.symbol
FROM account_balance
INNER JOIN currency_list ON currency_list.currency_ID=account_balance.currency_ID;

-- View all cards of clients and their daily limit
CREATE OR REPLACE SQL SECURITY INVOKER VIEW view_card_limit AS
SELECT client_account.reference_number, account_card.account_number, account_card.card_ID, card_daily_limit.limit_amount
FROM account_card
INNER JOIN client_account ON account_card.account_number=client_account.account_number
INNER JOIN card_daily_limit ON card_daily_limit.card_ID=account_card.card_ID;

-- View all loans of clients
CREATE OR REPLACE SQL SECURITY INVOKER VIEW view_loans AS
SELECT client_account.reference_number, client_account.account_number, account_loan.loan_ID, loan.repaid_amount, loan.given_amount
FROM client_account
INNER JOIN account_loan ON client_account.account_number=account_loan.account_number
INNER JOIN loan ON account_loan.loan_ID=loan.loan_ID;

-- View all transactions of clients (TODO: Fix bug, incorrect amount)
CREATE OR REPLACE SQL SECURITY INVOKER VIEW view_transactions AS
SELECT client_account.reference_number, client_account.account_number, account_IBAN.IBAN, bargain.amount, currency_list.alphabetic_code
FROM client_account
INNER JOIN account_IBAN ON account_IBAN.account_number=client_account.account_number
INNER JOIN currency_list
INNER JOIN bargain ON bargain_ID IN (
    SELECT bargain_ID FROM local_bargain WHERE sender_account_number=client_account.account_number OR receiver_account_number=client_account.account_number 
    UNION 
    SELECT bargain_ID FROM international_bargain WHERE sender_IBAN=account_IBAN.IBAN OR receiver_IBAN=account_IBAN.IBAN
);

-- View all stocks of clients
CREATE OR REPLACE SQL SECURITY INVOKER VIEW view_stocks AS
SELECT client_account.reference_number, client_account.account_number, account_stock.stock_code, account_stock.shares
FROM client_account
INNER JOIN account_stock ON account_stock.account_number = client_account.account_number;

/* #endregion */

/* #region ROLES PERMISSIONS */
-- https://mariadb.com/kb/en/grant/#table-privileges

-- Auditor (support) can only SELECT transactions, loans, stocks, cards (frozen / internet shopping / limits).
GRANT SELECT (bargain_ID, bargain_date, bargain_status) ON banking_system.bargain TO 'bank_auditor';
GRANT SELECT ON banking_system.loan TO 'bank_auditor';
GRANT SELECT ON banking_system.account_loan TO 'bank_auditor';
GRANT SELECT ON banking_system.loan_payment TO 'bank_auditor';
GRANT SELECT ON banking_system.stock TO 'bank_auditor';
GRANT SELECT (account_number, stock_code) ON banking_system.account_stock TO 'bank_auditor';
GRANT SELECT (card_ID, internet_shopping_available, frozen) ON banking_system.card_details TO 'bank_auditor';
GRANT SELECT ON banking_system.card_daily_limit TO 'bank_auditor';
GRANT SELECT ON banking_system.account_card TO 'bank_auditor';

GRANT SELECT ON banking_system.view_user_accounts TO 'bank_auditor';
GRANT SELECT ON banking_system.view_account_balance TO 'bank_auditor';
GRANT SELECT ON banking_system.view_card_limit TO 'bank_auditor';
GRANT SELECT ON banking_system.view_loans TO 'bank_auditor';
GRANT SELECT ON banking_system.view_transactions TO 'bank_auditor';
GRANT SELECT ON banking_system.view_stocks TO 'bank_auditor';

-- Clerk have Auditor permissions + can INSERT, SELECT transactions, stocks.
GRANT 'bank_auditor' TO 'bank_clerk';
GRANT INSERT, SELECT ON banking_system.bargain TO 'bank_clerk';
GRANT INSERT, SELECT ON banking_system.account_stock TO 'bank_clerk';

-- Manager can INSERT, SELECT, UPDATE customer accounts. May INSERT, SELECT, UPDATE, DELETE transactions, stocks, loans.
GRANT 'bank_clerk' TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.bank_information TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.regional_information TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.client_details TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.account TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.account_IBAN TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.client_account TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.currency_list TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.loan TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.loan_payment TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.account_loan TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.bargain TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.local_bargain TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.international_bargain TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.incoming_bargain TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.outgoing_bargain TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.stock TO 'bank_manager';
GRANT INSERT, SELECT, UPDATE ON banking_system.account_stock TO 'bank_manager';
GRANT SELECT, UPDATE ON banking_system.card_daily_limit TO 'bank_auditor';

-- Non-Bill Developers can only SELECT money balance
GRANT SELECT ON banking_system.bank_information TO 'non_bill_developer';
GRANT ALL ON banking_system.regional_information TO 'non_bill_developer';
GRANT ALL ON banking_system.client_details TO 'non_bill_developer';
GRANT SELECT ON banking_system.client_access TO 'non_bill_developer';
GRANT ALL ON banking_system.account TO 'non_bill_developer';
GRANT ALL ON banking_system.account_IBAN TO 'non_bill_developer';
GRANT ALL ON banking_system.client_account TO 'non_bill_developer';
GRANT SELECT(bargain_ID, bargain_status, bargain_date) ON banking_system.bargain TO 'non_bill_developer';
GRANT SELECT(card_ID, internet_shopping_available, frozen) ON banking_system.card_details TO 'non_bill_developer';
GRANT ALL ON banking_system.card_daily_limit TO 'non_bill_developer';
GRANT ALL ON banking_system.account_card TO 'non_bill_developer';
GRANT SELECT ON customer_sessions TO 'non_bill_developer';

GRANT SELECT ON banking_system.view_user_accounts TO 'non_bill_developer';
GRANT SELECT ON banking_system.view_account_balance TO 'non_bill_developer';
GRANT SELECT ON banking_system.view_card_limit TO 'non_bill_developer';
GRANT SELECT ON banking_system.view_loans TO 'non_bill_developer';
GRANT SELECT ON banking_system.view_transactions TO 'non_bill_developer';
GRANT SELECT ON banking_system.view_stocks TO 'non_bill_developer';

-- Bill Developers can not assign roles to people
GRANT ALL ON banking_system.* TO 'senior_developer', 'bill_developer';

-- Senior developer can add people and assign role to them
GRANT GRANT OPTION ON banking_system.* TO 'senior_developer';

/* #endregion */

/* #region USERS */

CREATE USER IF NOT EXISTS 'typical_auditor' IDENTIFIED BY 'magic123';
GRANT 'bank_auditor' TO 'typical_auditor';
SET DEFAULT ROLE 'bank_auditor' FOR 'typical_auditor'; 

CREATE USER IF NOT EXISTS 'typical_clerk' IDENTIFIED BY 'magic123';
GRANT 'bank_clerk' TO 'typical_clerk';
SET DEFAULT ROLE 'bank_clerk' FOR 'typical_clerk'; 

CREATE USER IF NOT EXISTS 'typical_manager' IDENTIFIED BY 'magic123';
GRANT 'bank_manager' TO 'typical_manager';
SET DEFAULT ROLE 'bank_manager' FOR 'typical_manager'; 

CREATE USER IF NOT EXISTS 'non_bill_dev' IDENTIFIED BY 'magic123';
GRANT 'non_bill_developer' TO 'non_bill_dev';
SET DEFAULT ROLE 'non_bill_developer' FOR 'non_bill_dev';

CREATE USER IF NOT EXISTS 'developer' IDENTIFIED BY 'magic123';
GRANT 'bill_developer' TO 'developer';
SET DEFAULT ROLE 'bill_developer' FOR 'developer';

CREATE USER IF NOT EXISTS 'admin_developer' IDENTIFIED BY 'magic123';
GRANT 'senior_developer' TO 'admin_developer';
SET DEFAULT ROLE 'senior_developer' FOR 'admin_developer';

/* #endregion */

/* #region FUNCTIONS & PROCEDURES */

/* #region OPEN ACCOUNT */

-- Procedure which changes status of account to open

DELIMITER //
CREATE OR REPLACE PROCEDURE open_account(IN new_account_number BIGINT UNSIGNED)
SQL SECURITY INVOKER
BEGIN
    UPDATE banking_system.account
    SET account_status = "Open"
    WHERE account_number = new_account_number;
END;
//
DELIMITER ;

/* #endregion */

/* #region CHANGE TRANSACTION STATUS */

-- Procedure which changes the status of a transaction from 'Waiting' to 'Pending'

DELIMITER //
CREATE OR REPLACE PROCEDURE change_bargain_status_to_pending(IN pending_bargain_ID INT)
SQL SECURITY INVOKER
BEGIN
    UPDATE banking_system.bargain SET bargain_status = "Pending" WHERE bargain_ID = pending_bargain_ID;
END;
//

-- Procedure which changes the status of a transaction from 'Pending' to 'Failed'
DELIMITER //
CREATE OR REPLACE PROCEDURE change_bargain_status_to_failed(IN pending_bargain_ID INT)
SQL SECURITY INVOKER
BEGIN
    UPDATE banking_system.bargain
    SET bargain_status = "Failed"
    WHERE bargain_ID = pending_bargain_ID;
END;
//
DELIMITER ;

-- Procedure which changes the status of a transaction from 'Pending' to 'Succesful'
DELIMITER //

CREATE OR REPLACE PROCEDURE change_bargain_status_to_succesful(IN pending_bargain_ID INT)
SQL SECURITY INVOKER
BEGIN
    UPDATE banking_system.bargain
    SET bargain_status = "Succesful"
    WHERE bargain_ID = pending_bargain_ID;
END; //
DELIMITER ;

-- Procedure which tranfers the money and changes status to "Succesful" or "Failed" accordingly
DELIMITER //

CREATE OR REPLACE PROCEDURE perform_bargain(
    IN current_bargain_status ENUM("Waiting for Date", "Pending","Failed", "Succesful"),
    IN bargain_currency_ID TINYINT UNSIGNED, 
    IN current_bargain_ID INT UNSIGNED,
    IN current_amount INT UNSIGNED
)
SQL SECURITY INVOKER
main:BEGIN
	DECLARE current_sender_account BIGINT UNSIGNED;
    DECLARE current_receiver_account BIGINT UNSIGNED;
    
    -- Try to get account_ID of the sender and receiver by local transactions
    SET current_sender_account = (SELECT sender_account_number FROM banking_system.local_bargain WHERE bargain_ID = current_bargain_ID);
    SET current_receiver_account = (SELECT receiver_account_number FROM banking_system.local_bargain WHERE bargain_ID = current_bargain_ID);
    
    -- Try to get account_ID of the sender and receiver by international transactions
    IF (isnull(current_sender_account) OR isnull(current_receiver_account)) THEN
        SET current_sender_account = (SELECT account_number FROM account_IBAN WHERE IBAN = (SELECT sender_IBAN FROM banking_system.international_bargain WHERE bargain_ID = current_bargain_ID));
        SET current_receiver_account = (SELECT account_number FROM account_IBAN WHERE IBAN = (SELECT receiver_IBAN FROM banking_system.international_bargain WHERE bargain_ID = current_bargain_ID));
    END IF;
    
    -- If current sender or receiver account is null, then set status to "Failed"
    IF (isnull(current_sender_account) OR isnull(current_receiver_account)) THEN
        CALL change_bargain_status_to_failed(current_bargain_ID);
        LEAVE main;
    END IF;
    
    -- Deduct money from sender account
    UPDATE banking_system.account_balance
    SET amount = amount - current_amount
    WHERE account_number = current_sender_account AND currency_ID = bargain_currency_ID;

    -- Add money to receiver account
    UPDATE banking_system.account_balance
    SET amount = amount + current_amount
    WHERE account_number = current_receiver_account AND currency_ID = bargain_currency_ID;

    -- Change bargain status to "Succesful"
    CALL change_bargain_status_to_succesful(current_bargain_ID);

    -- Add bargain to incoming transaction
    INSERT INTO banking_system.incoming_bargain(bargain_ID, receipt_date)
    VALUES (current_bargain_ID, CURRENT_TIMESTAMP);

END; //

DELIMITER ;

/* #endregion */

/* #region TRIGGERS */

-- When user account status changes to OPEN, make income transaction of 50 GBP to new acccount
DELIMITER //

CREATE OR REPLACE TRIGGER `account_status_change_to_open`
AFTER UPDATE ON banking_system.account FOR EACH ROW
BEGIN
    DECLARE new_bargain_ID INT UNSIGNED;
    
    IF NEW.account_status = 'OPEN' THEN
        SET new_bargain_ID = (SELECT MAX(bargain_ID) FROM banking_system.bargain) + 1;

        -- Create new bargain record
        INSERT INTO banking_system.bargain (bargain_ID, amount, currency_ID, bargain_status, bargain_date, bargain_description)
        VALUES (new_bargain_ID, 50, 3, 'Waiting', CURRENT_TIMESTAMP, 'Opening account');

        -- Create local bargain record
        INSERT INTO banking_system.local_bargain (bargain_ID, sender_account_number, receiver_account_number)
        VALUES (new_bargain_ID, '1', NEW.account_number);

        -- Create outgoing bargain record
        INSERT INTO banking_system.outgoing_bargain (bargain_ID, planned_date)
        VALUES (new_bargain_ID, CURRENT_TIMESTAMP);
    END IF;
END; //

DELIMITER ;

/* #endregion */

/* #region EVENTS */

-- Check for any transactions that are with status "Waiting" 
DELIMITER //

CREATE OR REPLACE EVENT check_for_waiting_bargains
ON SCHEDULE EVERY 1 MINUTE DO
BEGIN
	DECLARE current_bargain_ID INT UNSIGNED;
    DECLARE current_planned_date DATETIME;
    DECLARE minute_difference BIGINT;
    DECLARE done BOOLEAN DEFAULT FALSE;

    -- Get list of all "Waiting" bargains
    DECLARE bargain_waiting_list CURSOR FOR SELECT bargain_ID, bargain_date FROM banking_system.bargain WHERE bargain_status = "Waiting for Date";
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN bargain_waiting_list;
    
    -- Foreach loop
    bargain_read:LOOP

        -- Save bargain values
    	FETCH NEXT FROM bargain_waiting_list INTO current_bargain_ID, current_planned_date;
        
        -- NOT FOUND exception
        IF (done) THEN
        	LEAVE bargain_read;
        END IF;
        
        -- Calculate time difference in minutes
        SET minute_difference = TIMESTAMPDIFF(MINUTE, NOW(), current_planned_date);
		
        IF minute_difference <= 0 THEN
            CALL change_bargain_status_to_pending(current_bargain_ID);
        END IF;
    END LOOP;
    
    CLOSE bargain_waiting_list;
    
END; //

DELIMITER ;

-- Check if any bargains are pending and perform them
DELIMITER //
CREATE OR REPLACE EVENT check_for_pending_bargains
ON SCHEDULE EVERY 1 MINUTE DO
BEGIN
    DECLARE current_bargain_ID INT UNSIGNED;
    DECLARE current_bargain_status ENUM ("Waiting for Date", "Pending","Failed", "Succesful");
    DECLARE current_bargain_currency_ID TINYINT UNSIGNED;
    DECLARE current_bargain_amount INT UNSIGNED;
    DECLARE done BOOLEAN DEFAULT FALSE;

    -- Get list of all "Pending" bargains
    DECLARE bargain_waiting_list CURSOR FOR SELECT bargain_ID, amount, currency_ID, bargain_status FROM banking_system.bargain WHERE bargain_status = "Pending";
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN bargain_waiting_list;

    -- Foreach loop
    bargain_read:LOOP

        -- Save bargain values
    	FETCH NEXT FROM bargain_waiting_list INTO current_bargain_ID, current_bargain_amount, current_bargain_currency_ID, current_bargain_status;
        
        -- NOT FOUND exception
        IF done THEN
        	LEAVE bargain_read;
        END IF;

        -- Perform bargain
        CALL perform_bargain(current_bargain_status, current_bargain_currency_ID, current_bargain_ID, current_bargain_amount);
    END LOOP;

    CLOSE bargain_waiting_list;

END; //

DELIMITER ;

/* #endregion */