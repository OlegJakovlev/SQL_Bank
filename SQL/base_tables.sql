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
    payment_due_date TIMESTAMP NOT NULL,
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
    bargain_status ENUM ("Waiting for Date", "Pending","Failed", "Succesful") NOT NULL DEFAULT "Pending",
    bargain_date TIMESTAMP NOT NULL,
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
    receipt_date TIMESTAMP NOT NULL,
    FOREIGN KEY (bargain_ID) REFERENCES bargain(bargain_ID)
);

CREATE TABLE IF NOT EXISTS outgoing_bargain (
    bargain_ID INT UNSIGNED NOT NULL PRIMARY KEY,
    planned_date TIMESTAMP NOT NULL,
    FOREIGN KEY (bargain_ID) REFERENCES bargain(bargain_ID)
);

CREATE TABLE IF NOT EXISTS stock (
    stock_code VARCHAR(5) NOT NULL PRIMARY KEY, -- AAPL
    stock_name VARCHAR(50) NOT NULL UNIQUE, -- Apple
    sell_price FLOAT(2) UNSIGNED NOT NULL,
    buy_price FLOAT(2) UNSIGNED NOT NULL,
    available_to_buy BOOLEAN NOT NULL DEFAULT TRUE
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

-- View all transactions of clients
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

/* #region 4.1 */
/*
List all bank customers (including their name and account number) who have their loan 
payment due in the first 7 days of the month (all the months)


SELECT client_details.*, client_account.account_number 
FROM `client_details`
INNER JOIN client_account ON client_details.reference_number=client_account.reference_number 
WHERE client_account.account_number IN 
	(SELECT account_number from `account_loan` WHERE loan_ID IN 
    	(SELECT loan_ID FROM `loan_payment` WHERE DAY(payment_due_date) BETWEEN 1 AND 7)
    );
*/

/*
List all bank customers (including their name and account number) who have their loan 
payment due in the first 7 days of the month. (current month)

SELECT client_details.*, client_account.account_number 
FROM `client_details`
INNER JOIN client_account ON client_details.reference_number=client_account.reference_number 
WHERE client_account.account_number IN 
	(SELECT account_number from `account_loan` WHERE loan_ID IN 
    	(SELECT loan_ID FROM `loan_payment` WHERE 
            MONTH(payment_due_date)=MONTH(CURRENT_DATE)
            AND
            DAY(payment_due_date) BETWEEN 1 AND 7
        )
    );
*/

/*
List all bank customers (including their name and account number) who have their loan 
payment due in the first 7 days of the month. (next month)

SELECT client_details.*, client_account.account_number 
FROM `client_details`
INNER JOIN client_account ON client_details.reference_number=client_account.reference_number 
WHERE client_account.account_number IN 
	(SELECT account_number from `account_loan` WHERE loan_ID IN 
    	(SELECT loan_ID FROM `loan_payment` WHERE 
        MONTH(payment_due_date)=MONTH(CURRENT_DATE)+1
        AND
        DAY(payment_due_date) BETWEEN 1 AND 7
    );
*/

/* #endregion */

/* #region 4.2 */
/*
Extract all bank transactions that were made in the past 5 days (please include customer 
and account details).

SELECT client_details.reference_number, client_details.full_name, client_account.account_number, bargain.bargain_ID, bargain.amount, currency_list.symbol, currency_list.alphabetic_code, bargain.bargain_date
FROM client_details

INNER JOIN client_account ON client_details.reference_number=client_account.reference_number
INNER JOIN account_iban ON client_account.account_number = account_iban.account_number
INNER JOIN local_bargain ON local_bargain.sender_account_number = client_account.account_number
INNER JOIN international_bargain ON international_bargain.sender_IBAN = account_iban.IBAN
INNER JOIN bargain ON ((bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID) AND bargain.bargain_status = "Succesful" AND bargain_date BETWEEN NOW()-INTERVAL 5 DAY AND NOW())
INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

WHERE bargain.bargain_ID IN ((SELECT bargain_ID FROM outgoing_bargain))
GROUP BY client_account.account_number, currency_list.currency_ID
ORDER BY `bargain`.`bargain_ID` ASC;
*/

/* #endregion */

/* #region 4.3 */
/*
List the customers with balance > 5000 by summing incoming transactions and deduct outgoing

WITH incoming AS (
    SELECT client_account.account_number, SUM(bargain.amount) AS income_amount, currency_list.currency_ID, currency_list.symbol, currency_list.alphabetic_code
    FROM client_account

    INNER JOIN account_iban ON client_account.account_number = account_iban.account_number
    INNER JOIN local_bargain ON local_bargain.sender_account_number = client_account.account_number
    INNER JOIN international_bargain ON international_bargain.sender_IBAN = account_iban.IBAN
    INNER JOIN bargain ON bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID
    INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

    WHERE bargain.bargain_ID IN ((SELECT bargain_ID FROM incoming_bargain))
    GROUP BY client_account.account_number, currency_list.currency_ID
),

outgoing AS (
    SELECT client_account.account_number, SUM(bargain.amount) AS outgoing_amount, currency_list.currency_ID, currency_list.symbol, currency_list.alphabetic_code
    FROM client_account

    INNER JOIN account_iban ON client_account.account_number = account_iban.account_number
    INNER JOIN local_bargain ON local_bargain.sender_account_number = client_account.account_number
    INNER JOIN international_bargain ON international_bargain.sender_IBAN = account_iban.IBAN
    INNER JOIN bargain ON ((bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID) AND bargain.bargain_status = "Succesful")
    INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

    WHERE bargain.bargain_ID IN ((SELECT bargain_ID FROM outgoing_bargain))
    GROUP BY client_account.account_number, currency_list.currency_ID
)

SELECT client_details.reference_number, client_details.full_name, incoming.account_number, incoming.income_amount-outgoing.outgoing_amount as total, incoming.currency_ID, incoming.symbol 
FROM incoming

INNER JOIN client_details
INNER JOIN outgoing ON outgoing.account_number = incoming.account_number

WHERE incoming.income_amount-outgoing.outgoing_amount > 5000
GROUP BY incoming.account_number, incoming.currency_ID
*/

/*
List the customers with balance > 5000 just from existing table

SELECT client_details.reference_number, client_details.full_name, client_account.account_number, account_balance.amount, account_balance.currency_ID, currency_list.symbol
FROM client_details
INNER JOIN client_account ON client_details.reference_number=client_account.reference_number
INNER JOIN account_balance ON client_account.account_number = account_balance.account_number
INNER JOIN currency_list ON currency_list.currency_ID=account_balance.currency_ID
WHERE account_balance.amount > 5000;
*/

/* #endregion */

/* #region 4.4 */
/*
Total oustandings of bank (sum(incoming) - sum(outgoing))

WITH incoming AS (
    SELECT SUM(bargain.amount) AS income_amount, currency_list.currency_ID, currency_list.symbol, currency_list.alphabetic_code
    FROM client_account

    INNER JOIN account_iban ON client_account.account_number = account_iban.account_number
    INNER JOIN local_bargain ON local_bargain.sender_account_number = client_account.account_number
    INNER JOIN international_bargain ON international_bargain.sender_IBAN = account_iban.IBAN
    INNER JOIN bargain ON bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID
    INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

    WHERE bargain.bargain_ID IN ((SELECT bargain_ID FROM incoming_bargain))
    GROUP BY currency_list.currency_ID
),

outgoing AS (
    SELECT SUM(bargain.amount) AS outgoing_amount, currency_list.currency_ID, currency_list.symbol, currency_list.alphabetic_code
    FROM client_account

    INNER JOIN account_iban ON client_account.account_number = account_iban.account_number
    INNER JOIN local_bargain ON local_bargain.sender_account_number = client_account.account_number
    INNER JOIN international_bargain ON international_bargain.sender_IBAN = account_iban.IBAN
    INNER JOIN bargain ON bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID
    INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

    WHERE bargain.bargain_ID IN ((SELECT bargain_ID FROM outgoing_bargain))
    GROUP BY currency_list.currency_ID
)

SELECT incoming.income_amount-outgoing.outgoing_amount AS total, incoming.symbol, incoming.alphabetic_code
FROM incoming
INNER JOIN outgoing ON outgoing.currency_ID = incoming.currency_ID
GROUP BY incoming.currency_ID
*/

/* #endregion */

/* #region 5.1 */
/*
List all bank customers (including their name and account number) who have their loan 
payment due in the first 7 days of the month (all the months)
*/

DELIMITER //
CREATE OR REPLACE PROCEDURE get_bank_customers_with_loans_due_first_7_days()
SQL SECURITY INVOKER
BEGIN
    SELECT client_details.*, client_account.account_number
    FROM `client_details`
    INNER JOIN client_account ON client_details.reference_number=client_account.reference_number 
    WHERE client_account.account_number IN 
        (SELECT account_number from `account_loan` WHERE loan_ID IN 
            (SELECT loan_ID FROM `loan_payment` WHERE DAY(payment_due_date) BETWEEN 1 AND 7)
        );
END;
//
DELIMITER ;

/* #endregion */

/* #region 5.2 */
/*
Extract all bank transactions that were made in the past 5 days (please include customer 
and account details).
*/
DELIMITER //
CREATE OR REPLACE PROCEDURE get_last_5_days_transactions()
SQL SECURITY INVOKER
BEGIN
    SELECT client_details.reference_number, client_details.full_name, client_account.account_number, bargain.bargain_ID, bargain.amount, currency_list.symbol, currency_list.alphabetic_code, bargain.bargain_date
    FROM client_details

    INNER JOIN client_account ON client_details.reference_number=client_account.reference_number
    INNER JOIN account_iban ON client_account.account_number = account_iban.account_number
    INNER JOIN local_bargain ON local_bargain.sender_account_number = client_account.account_number
    INNER JOIN international_bargain ON international_bargain.sender_IBAN = account_iban.IBAN
    INNER JOIN bargain ON ((bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID) AND bargain.bargain_status = "Succesful" AND bargain_date BETWEEN NOW()-INTERVAL 5 DAY AND NOW())
    INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

    WHERE bargain.bargain_ID IN ((SELECT bargain_ID FROM outgoing_bargain))
    GROUP BY client_account.account_number, currency_list.currency_ID
    ORDER BY `bargain`.`bargain_ID` ASC;
END;
//
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
    DECLARE current_planned_date TIMESTAMP;
    DECLARE minute_difference BIGINT;
    DECLARE done BOOLEAN DEFAULT FALSE;

    DECLARE bargain_waiting_list CURSOR FOR SELECT bargain_ID, bargain_date FROM banking_system.bargain WHERE bargain_status = "Waiting for Date";
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN bargain_waiting_list;
    
    bargain_read:LOOP
    	FETCH bargain_waiting_list INTO current_bargain_ID, current_planned_date;
        
        IF (done) THEN
        	LEAVE bargain_read;
        END IF;
        
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

    DECLARE bargain_waiting_list CURSOR FOR SELECT bargain_ID, amount, currency_ID, bargain_status FROM banking_system.bargain WHERE bargain_status = "Pending";
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN bargain_waiting_list;

    bargain_read:LOOP
    	FETCH NEXT FROM bargain_waiting_list INTO current_bargain_ID, current_bargain_amount, current_bargain_currency_ID, current_bargain_status;

        IF done THEN
        	LEAVE bargain_read;
        END IF;

        CALL perform_bargain(current_bargain_status, current_bargain_currency_ID, current_bargain_ID, current_bargain_amount);
    END LOOP;

    CLOSE bargain_waiting_list;

END; //

DELIMITER ;

/* #endregion */

/* #region SAMPLE DATA */
INSERT INTO `bank_information` (`bank_ID` ,`sort_code`, `SWIFT`) VALUES
(1, "727295", "LSTNGS00"),
(2, "424208", "LSTNGS01"),
(3, "969830", "LSTNGS02"),
(4, "384295", "LSTNGS03"),
(5, "660804", "LSTNGS04"),
(6, "398928", "LSTNGS05"),
(7, "039856", "LSTNGS06"),
(8, "100693", "LSTNGS07"),
(9, "035797", "LSTNGS08"),
(10, "872376", "LSTNGS09");

INSERT INTO `currency_list` (`currency_ID`, `alphabetic_code`, `symbol`) VALUES
(1, "USD", "$"),
(2, "EUR", "€"),
(3, "GBP", "£"),
(4, "JPY", "¥"),
(5, "CAD", "$"),
(6, "RUB", "₽"),
(7, "INR", "₹"),
(8, "RSD", "din"),
(9, "AUD", "$"),
(10, "CNY", "¥"),
(11, "NZD", "$"),
(12, "CHF", "Fr"),
(13, "SEK", "kr");

INSERT INTO `stock` (`stock_code`, `stock_name`, `sell_price`, `buy_price`) VALUES
("AAPL", "Apple", 4406.766, 4496.7),
("GOOG", "Google", 2869.7634, 2928.33),
("MSFT", "Microsoft", 9315.1548, 9505.26),
("FB", "Facebook", 3841.3451999999997, 3919.74),
("AMZN", "Amazon", 8259.2636, 8427.82),
("TWTR", "Twitter", 9138.8822, 9325.39),
("NFLX", "Netflix", 4801.0788, 4899.06),
("TSLA", "Tesla", 5117.3346, 5221.77),
("BABA", "Alibaba", 2234.7234, 2280.33),
("NVDA", "Nvidia", 8908.591999999999, 9090.4),
("AMD", "AMD", 1896.1725999999999, 1934.87),
("INTC", "Intel", 2866.5686, 2925.07),
("CSCO", "Cisco", 501.6718, 511.91),
("ADBE", "Adobe", 7509.857599999999, 7663.12),
("ADP", "Autodesk", 4457.1968, 4548.16),
("CMCSA", "Comcast", 4324.808599999999, 4413.07);

INSERT INTO `regional_information` (`regional_information_ID`, `country_name`, `postcode`, `city_name`) VALUES
(1, "Sierra Leone", "CD5 6EF", "Tokyo"),
(2, "Marshall Islands", "67890", "Cardiff"),
(3, "Ireland", "CD6 7EF", "Corpus Christi"),
(4, "Cambodia", "190011", "Durham"),
(5, "Luxembourg", "EF6 7GH", "Fort Lauderdale"),
(6, "Mauritius", "190010", "Hereford"),
(7, "Bulgaria", "10575", "Anaheim"),
(8, "Taiwan", "10497", "Seattle"),
(9, "Finland", "111-0061", "Manchester"),
(10, "France", "10575", "Little Rock");

INSERT INTO `client_details` (`reference_number`, `full_name`, `birth_date`, `adress`, `adress_2`, `regional_information_ID`, `telephone_number`) VALUES
("725716482bok", "Beverly White", "1946/1/6", "Pearl Street 5217", NULL, 1, "774390923"),
("733320646icv", "April Rodriguez", "1944/2/25", "Boulevard Street 6933", NULL, 2, "758534347"),
("292492700oda", "Audrey Garcia", "1905/8/20", "Circle Street 5998", "Room 831", 3, "5105000487"),
("438619823jyr", "Beverly Williams", "1961/3/26", "Central Street 3325", NULL, 4, "3655387617"),
("234860962wyv", "Arlene Moore", "1966/4/17", "Place Street 5946", "Room 218", 5, "762992959"),
("254963149stu", "Beverly Johnson", "1902/10/21", "Trail Street 4395", NULL, 6, "27173393140"),
("457959098yts", "Amy Martinez", "2000/12/24", "Parkway Street 6207", NULL, 7, "042007417"),
("341602854jls", "Amanda Robinson", "1903/8/1", "Pearl Street 4727", "Room 99", 8, "40265521142"),
("924349113acf", "Beverly Wilson", "1965/8/1", "Pearl Street 5932", NULL, 9, "4368571000"),
("588996473gmm", "Ashley Brown", "1999/10/20", "Central Street 5610", "Room 981", 10, "266621243");

INSERT INTO `client_access` (`reference_number`, `password_salt`, `password_hash`) VALUES
("725716482bok", "HcD~'#,YMF:fQP4ArIX6cRX5q(,#eyn3XUmc%M^qg3z'2z.d#&{2(Md%)&bgaTMf", "eb148dab62415c8abd4a30e301fd69d6a484ba2fdb7da3170a0bc2faf67dc069826829ec9bd8bd59cea8ff9f49d9b2940bffee9d8dedc80c7b63018bfbe6e6ff"),
("733320646icv", "g,G&>6kY!SD9!5Q^2kCBsCTk4_XV0'bxP-0x^957$2>7T% WI4~T%z;R?ORB^L~F", "61fb34cf29eaef2b464286baada218d53a2b2daae9c3b826c4ee4c8b98c4ae9bbafce39512072bafd1fa6151fbf44a5d4bb00210cc9e82e9ce5b1e8e715dc6b5"),
("292492700oda", "%H}s=>l|WD5]zgy_DT7[i5e)2 Y]_f|l{Bqa}B^lII$#kCe>gVRxbHD2RMp/U)G_", "7a0d2eb72aff32fbea28db9d00a47ded6b6eae12214fad9baab92491afc9ad4a757ae5a9fe25720ad380a3ea93f4a94e9db6b9be5e34beb1ac8bcfcab64bfaa5"),
("438619823jyr", "hv_#FP0D,Q289PEG>ja>Qr/45S%,n(U>[$/ m=M]P8I(JkSuyNo|-__ sf[kg$>=", "e83ae60afdfe3d89fae63d47faecdcbe2efda0d43872bac6dbe227dda6d52194ed2fcfbacfba66c71df3bde2cfbefc3ad89aa9fd98efaac6bdedde4dd4c1cec6"),
("234860962wyv", "nKE+;?.&$_'3Nk?#TV.mXaBh27HDuq4+1B9gm|FADG.,n+!wWR1AG7,3iP%8[RP`", "bde1ae2ef1235bdde58bfd2d7fdddbaaa48d3c1efba01ed2be65386e1ce4ec594b046fe13d5badafa20ced2118f28231c8d36ba10389ea1c77abcfc66fceb0c7"),
("254963149stu", "+L<{!6!=6![J<jBS6go3t3@Gj.g6f[=jx.W?A4p4BFkJI({M,6hG|F`h>?/(0-j^", "cb5171e798ad7cbe064d17b4154e6dabeb78bf7a7ff418c6acfee8b9aa6b342a5cefb5ab1db60fded33ae2ec73eecd4baadb53c264b47cdf6c2db49e9324cdea"),
("457959098yts", "trg|nA~-$G~u# a4,?]_wUmsF.6q[ClZj!,uhUv^c<(qn#b[}Ig:|*h-F?7k)mz1", "badc900febdce077f6f29a84be7dd60f5467c87f0e2503d4d6c4ef9cf7acd2f30b4e1f4ff07e6ae6a504f9f8b56aec401e45aab8c8c365b2ef07ff875a9bf2db"),
("341602854jls", "~a*<[~Q1Oq'>}`:u5xuFug?I]u xRZdAR$*u75]dN+~~+p,~BZ'-V+(b6jBS$[Y1", "8d1dc1cf1d7b652e8de00c7fa9c32fdbbd04faca7dee1d0c9dd2bcb04baa33f6cf2f01f76c81f9eb701c123e39fdbdccdae2ec4f01e9a9f1a80c5ab23ea3d61c"),
("924349113acf", "v;Vd.tP}QhMl1p2kmV/fq!-ZgvYz#f,>>$WIMlU[_(h%>E/g2*8`<%p3BzdsX0qh", "d094592de72a73858eeaaac08d01cd11d91d161cedb5f6ec4fb7424ef3df76a5df19bedcce293be7ed8a7f2c75597eb5b5809dfdc9fdabd7ce7e25cdf2a9ccb6"),
("588996473gmm", "~PJJlUBXuXmO>eEF_>t{XzZ$J)__i:=#7q/d'q=%?h)_stZAHsQw?as~05OaHLzf", "a65b4edef2a6022dd50eeeb7a2aabadd0acaadab33bb88afbdfff96290ddc34fd8ccf211abcec33631df44f6ad81c7c4df5edfea11cfca3c3a29c28c6bb26c3e");

INSERT INTO `customer_sessions` (`reference_number`, `customer_IP`, `secret_key_salt`, `secret_key_hashed`, `token_salt`, `token_hashed`, `token_expiry_date`) VALUES
("457959098yts", "61.207.87.60", ":B-S(4v&ubdKG]2VhUL#LUJ`kx_H0DI8]S7(N@;@<GfW>2uDn{ wwY{G,8u7f*/L", "eb6ebaefa5ca6a97bceaf64ffa1f23b74acd2df39fff4c4acd8ec5e36dcc10f9f9401d0b1a161e0c213febbfae23068d8cbbbcacced142ff62c5adfa26cdcbdb", "EM'o$xOxdV]B3&g,`Iml&f,f<0o,:P8$p{2/CP(gcL4:@{)w~<D8Vdj-9{.NxO8G", "f5d569a9ae517a7f5a0ed90c303e000feab25ba7bcaf3bfc679e919eaeccf42c14868b56efef367e5f89c141f5cfc6eba9b2ba4635c5df0ffcbd36729f22bd2e", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("254963149stu", "161.158.206.176", "S!HmE[AQW5Fb1D3-f`AiNDZltHnEPRiqA*PuZWo:=zO|*h#1cvK/r E279]g$_fc", "a98ffe682ac36f29d4f7e6ebec1c22b95179adb2ac2c0fb4777db59c20ac98cccc5bfecb616fc51e2d86f8ebda7be981083bdef09c74f20d6cc589db2768f074", "^%xDHQJOexiLcklP1LUPf^!pFi9)HpD<h+<vzxZ6ccjr*a!-YR^5zPP,r@t)'2^9", "0315d14c44651c4e66cbfa61da1ea4a3672eeebabcbd804fcb023e0bbebba6fb8b4fae998d0fd0ec2b1ca2bed73a77bb2b2266e04d11f4ea52a29dfc9de1560e", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("254963149stu", "153.147.183.145", ">J2Uq^JpRR426+?E;$A`c5:0CtWw4RUA!-*5HAir^M3o*O7$IISt~4G2e!+JrcX5", "ce249edfff0a5affe0dca68b6ac2a1fc5dcbe706b15d2a7742a26addccaa2ffc7f303621a6b1dce4eb2b69bcdadb6ebf8664ea124d56e7a4ea28dc7e9b068df2", "sVo)fUgD@w<*!(|{8)]ys@?]5nF9hbP#/,FvyvRdHVL#(X}x5Um3(MGsB`!H|]Gr", "00f10fb4aae3ecbcbedb519ed5bf2fabfaedf8502655deb39cad4479c876c4be9fb71f7ec9efcf42aa0be6fc7bedc257e1f5d41d5f9b0bea161cd46cd56dc4c9", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("292492700oda", "242.147.182.192", "+9.,uRpG7_s'j#SEFWa#cUQcEZhHv|oRG51::bpW-:RWPNJ&IeV0}'lrpA;$Y]@F", "224182d89efcf0f53994cd01cea83f8dbbbb2ac7acf4bdafbef8441acaadff8b7d3cdd9b71e8400e6ccf210e0db7f82e9d39fadceefbeabdbce6ae1cff8fea1b", "W!}#f~no8w@zo[)ozbb<i[%HIb B;6r*Nz'1sF/H p@r7=`v0)pK|/lc@F|qHez;", "cebf61aae24cd1af2ceab9b9a06bbc1dcb7ca2d893e9dc2da0bb7af13fd0bcce6bbef8c0b49c34a6417f0e869a8f47fbbbc5bee80e7f37ec8fe802f30b4cd8fe", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("341602854jls", "173.59.209.125", "~(HP6xpnmA{[%'csD(^]UktDe0{_hNO;U1F'MX6h97Vc;?i9[)|C{K`A$z;Q~%}3", "7aa1e4f2b0d23d65db2cfd9e6ca6cd48ee8315a44aef02a3e1c217db2d425ac92502104acb9dbc7909b20a3defd38c7b1b2b7c1d761bc790c3d9ef621be9b85b", "ZHmDof,X-k`xC`T:zb<-.yjufRb,rhQ@-[Z0Zvmpv;1zk?.2eOrWFTt]1|LvAYdd", "fd02ad9ab23b55f56e3c4ce4ec53ee0c3b9b12f7834fc8acc2824e728d7895a12b10b6ac88d467cb6dddde120f3bee8aabce1bec54ea739bb10c3cd3cd0b5dbe", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("438619823jyr", "34.201.223.250", "L<V-f#&j4[mYDHPI;IGhGMdVc[w*ca,cI0}MLkhTuYJ){8LwQTQ2y}[iWa?q9YBc", "fdf8020e0aed38b5fe9ac8b374acba3d2bafdf9bed8c91f5f93db6eef66846bd2e38d8f740fe916c06eaea7b1e17b86dfdfb16b52daab3b73f9b8a9ade60be15", ">}w*D2`J.qs=Os)U]eQWEYk3t::_a$u3TPQG*FiG>GA@d9aHd$RN0})+H.;3efQL", "1ee37ea429fabd6eadc4ce7ce482a0ab992b49fec777ef77baf4cff5b8930adb3aaabee0c3ec4bd6348fc2a9194122123da1ac14ea4b1f07de7b6397772aba48", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("457959098yts", "102.179.36.91", "f00Hz U'w;(}&Lh+>WpB$_q:J80xFqx+%uyr!TQ=fbU0x7t N%m$&MsMbn&isEY4", "cfdcded5a99f7d5cdbc8cb24c35fdad0ee0beccea6de23a6de90b71dcecb69d2a4f9b2eac3aee6a236458efaeeff596a710932fbbfadb9fcb357bafd0118dbb4", "^+R+)iXK1njv!xuZ_$fEg'1jTry)?T!`#cEo2i~2O:{/qvuQAx!{{]Iw>Z!_E)&0", "58fa8c2179beeec0728aade9b90d3adca52ba712bc53748acba2fddfda61d250ccd7c1f5a3e6d4551c5e668a0dccc9ec3e531c3ef6754ddac9e0fadc9ecc4a9b", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("457959098yts", "208.249.120.147", "LTJC.>%?_u#uDi/YIFy_=i8F*~?mhRrSe=4n(:xwZKY2kj(}(<Sfe*ytbh6!S`>b", "e6b0ac4b35eacceec09a2abaee0c4bfcb707205cbf2edb86d9ffc8f1eedeef8e7a4e8fefd63e210bef17d3ff53adabfd1adacf0dda2b07fe024dcf738a851fbd", "'_+)WeR/r{nF]z-rI5,hK0>tBR@taAe0p<qM3 .E=%5q8uxs8rV&u(W7tznU;(Cx", "eb948af6a2a671b6b7acbebfd192e02ebdff8d9ffa5e670533fce85d956cae084ac5adfdcd11b3efedfda6ed92de5b8ef85d7aa5cff2ab7d85dbbe99f09e8502", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("292492700oda", "229.8.19.36", "<p 1L|30/z&Dno&oo6qbelu9E1cRuxu@'8C/FEwiwhMRsxNCP /~{- %X+ABf$J)", "1fcbfd7085044b2bec0a0b16ee1ec4b954d9fb6401f66ea0fa66dd618ceb1744c44437eb3c73aed1109dae6deb2bd7cb22dbedcb2a6d6b0ffde4e672504bf9fc", "Hp0Sw;>f0u$B Z0Vp>Zygue_Lfz=+f.GI7lK<?kQ5 ^U5l[kcNAM_Tcv=2Pm_P9}", "d2fcf756fbe04573fe62627208bffd2b6beedf00b47a08fba8b4cd00dfffaae738eee6f0e5e5fceca53d7ce9feffa288e4cd6d42b9c2fcdc469bc0ced226fdd9", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("438619823jyr", "253.17.181.8", "|~V}G@&J^fZky&tXv$mL`sn=J(p9nwhI4GV#&|?rSBu-8q,% ixw50-Al>7i'Rja", "3b399eb8d55399b2eb8fecff31f2865c42f6f6f5debc1f5b2a5fd33fca426b7c903aed37ad41fb70eae179ef821bc8e5fdb2a0a9bf0d6f36e3f06434afc7004b", "ehwrE;Bv&s@BtJeV9?1w+CK~.TZdrUuX.{j=?tkb7:9@/y.c2}?V:G~d%#^KZn|+", "bb9bcfe39a2c27bd0cdd9c02ed2bbe1ddaf42ad85fa6b4b9edc3ebb527b9dc43a34c2f93c0b9aa4898dba1cf793cdc3afda01685f9edada8d41f4ccc9cba8c3a", DATE_ADD(NOW(), INTERVAL 1 HOUR));

INSERT INTO `account` (`account_number`, `account_status`, `bank_ID`) VALUES
(1, "Waiting for Deposit", 8),
(2, "Open", 8),
(3, "Open", 8),
(4, "Waiting for Deposit", 6),
(5, "Waiting for Deposit", 6),
(6, "Waiting for Deposit", 1),
(7, "Waiting for Deposit", 7),
(8, "Open", 9),
(9, "Waiting for Deposit", 7),
(10, "Open", 5),
(11, "Open", 7),
(12, "Waiting for Deposit", 6),
(13, "Open", 2),
(14, "Open", 8),
(15, "Waiting for Deposit", 6),
(16, "Open", 9),
(17, "Open", 3),
(18, "Open", 2),
(19, "Waiting for Deposit", 9),
(20, "Open", 4),
(21, "Open", 1),
(22, "Waiting for Deposit", 5),
(23, "Open", 1),
(24, "Open", 6),
(25, "Waiting for Deposit", 8),
(26, "Open", 7),
(27, "Open", 1),
(28, "Open", 3),
(29, "Open", 1),
(30, "Waiting for Deposit", 2),
(31, "Open", 1),
(32, "Open", 6);

INSERT INTO `client_account` (`reference_number`, `account_number`) VALUES
("254963149stu", 1),
("725716482bok", 2),
("438619823jyr", 3),
("588996473gmm", 4),
("254963149stu", 5),
("234860962wyv", 6),
("588996473gmm", 7),
("924349113acf", 8),
("234860962wyv", 9),
("438619823jyr", 10),
("234860962wyv", 11),
("588996473gmm", 12),
("254963149stu", 13),
("234860962wyv", 14),
("254963149stu", 15),
("725716482bok", 16),
("588996473gmm", 17),
("341602854jls", 18),
("292492700oda", 19),
("292492700oda", 20),
("292492700oda", 21),
("924349113acf", 22),
("234860962wyv", 23),
("457959098yts", 24),
("725716482bok", 25),
("234860962wyv", 26),
("924349113acf", 27),
("438619823jyr", 28),
("725716482bok", 29),
("341602854jls", 30),
("254963149stu", 31),
("438619823jyr", 32);

INSERT INTO `account_IBAN` (`account_number`, `IBAN`) VALUES
(1, "GB0228189000000000000001"),
(2, "GB0228189000000000000002"),
(3, "GB0228189000000000000003"),
(4, "GB0228189000000000000004"),
(5, "GB0228189000000000000005"),
(6, "GB0228189000000000000006"),
(7, "GB0228189000000000000007"),
(8, "GB0228189000000000000008"),
(9, "GB0228189000000000000009"),
(10, "GB0228189000000000000010"),
(11, "GB0228189000000000000011"),
(12, "GB0228189000000000000012"),
(13, "GB0228189000000000000013"),
(14, "GB0228189000000000000014"),
(15, "GB0228189000000000000015"),
(16, "GB0228189000000000000016"),
(17, "GB0228189000000000000017"),
(18, "GB0228189000000000000018"),
(19, "GB0228189000000000000019"),
(20, "GB0228189000000000000020"),
(21, "GB0228189000000000000021"),
(22, "GB0228189000000000000022"),
(23, "GB0228189000000000000023"),
(24, "GB0228189000000000000024"),
(25, "GB0228189000000000000025"),
(26, "GB0228189000000000000026"),
(27, "GB0228189000000000000027"),
(28, "GB0228189000000000000028"),
(29, "GB0228189000000000000029"),
(30, "GB0228189000000000000030"),
(31, "GB0228189000000000000031"),
(32, "GB0228189000000000000032");

INSERT INTO `account_balance` (`account_number`, `currency_ID`, `amount`) VALUES
(2, 1, 204837),
(2, 2, 163949),
(2, 3, 34995),
(2, 4, 16836),
(2, 5, 202120),
(2, 6, 37594),
(2, 7, 231097),
(3, 1, 51347),
(3, 2, 111080),
(3, 3, 164784),
(8, 1, 49705),
(10, 1, -5914),
(11, 1, 44617),
(11, 2, 85565),
(11, 3, 206367),
(11, 4, 218002),
(11, 5, 160658),
(11, 6, 202886),
(11, 7, 19898),
(11, 8, 10952),
(13, 1, 31107),
(13, 2, 144643),
(13, 3, 79175),
(14, 1, 148859),
(14, 2, 65295),
(14, 3, 8064),
(14, 4, 131508),
(14, 5, 218295),
(14, 6, -1969),
(14, 7, 26245),
(14, 8, 140790),
(14, 9, 53615),
(14, 10, 77832),
(14, 11, 170397),
(14, 12, 247021),
(16, 1, 44719),
(16, 2, 28966),
(16, 3, 161342),
(16, 4, 146631),
(16, 5, 111009),
(16, 6, 132409),
(16, 7, -2626),
(16, 8, 193650),
(16, 9, -1878),
(16, 10, 125079),
(17, 1, 176981),
(17, 2, 146180),
(17, 3, 212503),
(17, 4, 109261),
(17, 5, 84912),
(17, 6, 205934),
(18, 1, 117648),
(18, 2, 65446),
(20, 1, 246717),
(20, 2, 113934),
(20, 3, 209454),
(20, 4, -8250),
(20, 5, 136038),
(21, 1, 53117),
(23, 1, 178190),
(23, 2, 112473),
(23, 3, 87363),
(24, 1, 80493),
(24, 2, 140309),
(24, 3, 92091),
(24, 4, 240572),
(24, 5, 31444),
(26, 1, 213824),
(26, 2, 209149),
(26, 3, 52408),
(26, 4, 222607),
(26, 5, 73262),
(27, 1, 235442),
(27, 2, 2877),
(28, 1, 108062),
(28, 2, 77674),
(28, 3, 249363),
(28, 4, 213396),
(28, 5, 49028),
(28, 6, -9591),
(28, 7, 166384),
(28, 8, 88590),
(28, 9, 210895),
(28, 10, 102496),
(29, 1, 66033),
(29, 2, 245032),
(29, 3, 236972),
(29, 4, 214543),
(29, 5, 153681),
(29, 6, 99647),
(29, 7, 225622),
(29, 8, 42906),
(29, 9, 152013),
(31, 1, 186182),
(31, 2, 162546),
(31, 3, 190972),
(31, 4, 214453),
(31, 5, 195160),
(31, 6, 200035),
(31, 7, 199063),
(31, 8, 33558),
(31, 9, 47113),
(32, 1, 22061),
(32, 2, 140721),
(32, 3, 49506);

INSERT INTO card_details (`card_ID`, `card_salt`,`card_hash`, `CVV_hash`, `PIN_hash`, `internet_shopping_available`, `frozen`) VALUES
(1, "JnXA.$dU[`?$5a0.gEa: H?!dHwV@v#QY@/rd0bZcj/O*$5{i81-{X*Fy/eJTJo[", "dcadbc18a721cbd9f99aa4dbada71ee43fc3ae6b19c262aba8c552ec2ef5ba0deabac969bc4cc18e5322d6c14fc08b854ee3dc77aba3bbc9b439e4ea6bc008b9", "dcd3ece676da8abda6df24e0abf1dafeeaf1cb8b0b4e2aef70d983e0eafca16dff2448c8ee53ef8e9be8a798d2245abb768b7cbec2adcae6d8cd3c59986a5df6", "34dc00d52c2eafba6b9a8c359fd5eecc3347c635a785d5a82f02daad9aaedbfccaab5ebdeed59ab923661fa9bfe6f8a48b1adecebe40daad23629bdfbfb3511b", false, false),
(2, "(hftPY:3|Y$]*2k;|stSLK~UV,;Kn86Z4HGR^~d;HbSMd?|0?)N9^+>SbHK-30kp", "9f0d20bcbb2fb6e1afdf61c5bd5dcacb6dddfd700abcdabee1d5d1cb3bc330452584e82ec5dc7abb935dde5eb99a4dd0f4abad58ace36d9caf5b211ed4029505", "a8c030a40fdf38a24ccc2ae0daf536cef37ddfe4ed0cdd63bdf3e159bf42e1e4f9ceee9b6bda26db8bda6977cb15eec9eda6e2d5ea78f6e9eaa649a4a806bbd1", "8dd568ef9bc549ae4fbafa2baa1890d7e51cbac08fd11d5b715cdecdebc8cecf3cffaffa5c2d4f2f7bc2d1accdfa6957c1d7f9fae0d20acede64faffb71c1ecc", false, false),
(3, "O1^2od}hP=bOCb_QfPHx:aFa-(8%Rs3;I9q;.<5CON!&5~|K>y{Yfy67'tCPY3&>", "621cd8edd6e2ea283b8a79c89d1e91bc5478fce7b70ffcd0567be41bd04eabe0a388ccdb39d2ce26cbe9659fd85d903aafc7e9ad1e58ffca0f462db6f30ddaee", "caf30c89a4dbdab360f4fc3c7ef5abd23791851f1bd45c1adf58fedbe5ce108ffbda9d4b06f16801dfabaaa3235a83c8bf3c7dda74f8659f1a4bb5492bdeaed7", "39ce9fcdbfefeb3c9ca6fbcd9e18c88af37f55b4fb66eb9dcfa6dfdfecdbdfd67c8daef21c37cf9f05d9b70bda77cbe1d9fb372ae7d5a478eed2e6ddb37a0f6a", false, false),
(4, "J-ekhN<rA *_93y=nx-~(93^2_Xcj]I/jEwym~2+/}rh#EFH?ltg36<pfHk|*mOw", "77fdc34ee566501cb3a3fa00736fd9d5e85f5b06f94ea2bbe2fbd1fad12fc9c85ab2b8acc07931d07f4ac6dcfdacd220e545a8d37cb89aefaaab0dd84dbb4dfc", "34ecaf7adf9f4ae2c54fd2bc0d4a07b31cfbf9eb2c64eadbcdb5a309b3effcd0d791ae22b884fb6cd14ebd21098cdb1748c4b0169ce9a2b7123376d41afa035a", "bdcbf692cc6fefbfcaffc86b261aca9d7df799ad9d13fc4cffce85e4c0496ebdbc4e710d0fe7933a49de8bb1ab04fc3e3c0adcdbddaf1b9f588399fe14f0bf1f", false, false),
(5, "i0ldvjk40vX>Q ,KL=#6v)yO?7nw9=4Cj9x_!'+fw.Zg:B]c%6PG:8V##/U=L;?]", "d4af4caf5f3db69e7ba52e0f1bc09bc32bacecedfa97ca0ea36aceb5cf36eabaee423ae57f0be4aee2fcfc2bc3bb7be045fe9ba9db37ca9374a04658a8dcccfc", "0eb2bce9813eabc6124954dcdf1ecf81a1267d9db8acfe7c65edf797ebaefddbd59e5ca8f7f3fa8cb89591d7fe5ac6fdafd43dabed912bb316edcddfbfcc1ddb", "aabccbe4159cbcafde3c5f9ddeea5355f0b7190f3cf2adec828dcebde3fcbacaaf29a7ebefcca6ee44f3ee0a0d9d47dc0484bcfacccf797be01ecffbec9a8822", false, false),
(6, "7,+=n{un0^jM37FZTP +zKLO?=/0P!Qh<T66cihhI1Bw0}y7.eJ3d&K{^;#q;tDp", "bff8bef6a59cdea3cb23d92bd82185d2bccf38ddb26df65a7cece95e4ac0ac2d1b9b7cce88f915ab4306e027abdd7aa7f1dbd933a5fcdc0cb9f11b67bfa2ab1d", "56b54ff8e5c621408bba07f0ac73aacf9d6ddc2a8b7c98c360440197dcc1baf04b7387e8ea0f8a00bb6d83d9cf7931b19e2c8a2e6e1aac4d5cde86bef7930f44", "2b00d1822ae1961c2ed0b691fd8c38ebe9060afcffd5dd9883b0906deb7ca1ec79abe4c0d4f8aee44be7b1af1ce0ecf20f665c92e03b4de9dd54b5d4a356f4c9", false, false),
(7, "rQeK:Uzng6K,oy$p-e@rM'UJL%BJDW&W,owUGE0PU|aRlch]OOn8naY)w`F2UkHO", "03deb66c0c186bc8a0e45d4c26d3ed684ffd7b84f3cd4704933fcade4dffeacdfd7c19fbbefae63f8e1e1bba2d9cd49ac496d1a9bfa53ee6bff86dd143977c6d", "d8c06ad6afefebdbef818d9c252dfbce3b6c52deadd53f8dad0cadcb46dd27b635f153ee0e7b400cad7a92eca76b79c74f1eabbfe46cde3543b3c83748435256", "84c54b33cd8be1eae317fe8112cca27b2b4978711faccbb4de06f94beba30bdc2fb2abbc2aacbfae7cdacc4cdc486afc17758843c4eaa2a5a87a1a8ae7aafa50", false, false),
(8, "KJw(Tul}VpaB~xzBsr}$1n584x:M=YVIE+7X.^PKFpK[w0`WVy5-iMqh9I7q6`=N", "bcd1b60a2335b1a8aaff9bfd4d2164635eabcbe9d71874cac5e8ee78febeed630e0fb6a196404acbefffff63bf49162488bb51ed7051900b4bdda2547cdab205", "c6ffdffabd7a2dda8dc4bcbea8de041acefb7fed209facbfd05b50114b6c32bfe2bf00cccd17c412d9e2aa962bf7ccc6f1efa18f775239ea6fe828bd8a2b9e4d", "ffaadf6329e8bcaccddbfdf2abd7a9460a8fa4fee96d426da7eeb6d09e601d64ef17b19cde7cd72ed6ece6daceafac2fbddebf2ebb6a9b5fffa00c30e0f272c6", false, false),
(9, "3']}y,Hy)D/+d|4C&VmoZ~UP%SWyZQV^8:.nF|o&'b{I~Y8YqDv(yNP4jd?96iA4", "b7b48f06f9c1e5ea4b0c6fbdf840ae2a9cbb3bf7b99a736ac8fbbb0dd01d0bbf34834469dbd448de976daf1f1d6acad76afdafcf57aff8b31bcc0f0e279a741f", "dfda637195bb6fd8eecf4cede0cd86baaa690a03befbc8fabbeea08c0032eefe8fc1cc4b22fbdb53facfcd5c7ed79ce448dde03baccc0febbf90f0eaefd6f32b", "57defd09fbaaa5a2afc1041d00c7026275322fdbd3ddeaddc3c3edcebddc7adbfd821c122aace9ddcc04f2ffa3835473fcd2792a181ea16c18cbbaff29d4ee7b", false, false),
(10, ".!8Uo-iB5EOt(hSUX=B[`ai+`X%cF:@YA*|DUF@@44uDt,'GXa27D<u1j@[#,89A", "ef69594401db040c274e31ccf94c559de50ac9ee4ecbdb19be4a7faafcde8ac7c5d68b16edabc2ec72683ba7cf4e410cae4d3faea2b621e01ef3a463a2bbc5c9", "bdb5cfd56a4703c284a3fd4f3ecd97bfe852e6bdcaf017d7f3744bce6e0a9aefcdd2edbf959744aadf8c51e6dcdbb2f4dbe843ebbed4aba4c39afaf9a73f55ee", "b0c5abbc5bfbe70aeed8bfb69ebe4f3fada8c48eafafe3ece8f985d0eeca4524529ff2a3a6d367d35ccb2f7f19491a8baae82cd1753c1aab01f8eae6a21878a6", false, false),
(11, "&(^1zXv!|^h8[vfY'1=3 &CEtnRTD?2h< AkAyJ-2:d9]}4DE|(ySL{T;#9'20zd", "53c2f3dacfdeb5f01370d173d110099d87c6d5db52832d5f32b11fb5f5ac353cb7be9efcf796c253988bb59eb8de9affcf30ccbb8e9de01bc73e74bd41b1cb05", "cf82bb7dfcd0a6a0645b8e0195fc6aedde1f126baeffccae7715d15b33a54ef3c43fdd0b37d5acaaefe8b84cbc605457afe0affcfc3deb2dbc0afecb6c7bec53", "b16a84abcfffcc8b53eaba1c726fb112e94ccbf94db54d01c3aaaddd2aade9c30b8df5effa0ceb9dc9839acd054be3990cd0c9ff0d4fdbf0c90cd03e1715eced", false, false),
(12, "1,$^6hZ&.3-y]Rn([2rgd443K0s`K-|+)SaVT+oz+KN&{ GcGXEU+HU{B-6&qi8<", "afceb4e5118a2e25266bb531eb0c895ca42b41b6bcd0dfd3c47e6d8efe3508fe61b96f81abd2a0d8fbae4bb97a72de1f8d71bade8ba4de7a8773d1fcfa0f04cf", "d652bea3e76ae906f9e1eb8aee2de71dbfa8eacf059ebe36ec7960ce6c10cf4fcbd6dd4e17422c3ee636008ada0cd4eb1d7cef83038bcd50dd033ef9edf13a4d", "ef3aa1bdb35b4b035ca9cfbcb957dd46dc6bb7b9fcb78f3e5a48efeaec04c3c6febead2041be8c62952b0036b63a3fde81e0a6fe33f100bd34fbeab5cad33adf", false, false),
(13, "V9n%KdY!xyMhIBPgcxc>o1:]0RkKE9SEma([O]B+;/fwk?sK1r/Q}X[Xm;'awB#H", "ed88ca373c48a905de160c004fbffabf5fece7b2b815b4a90d24b30bef3f2fe3e815feff6e56bbfdd2349f7c7feefc363223acc6de006c0bdf70fdbfef7cd78d", "5898b6cf3a4fd5c0b8575b0b8a31fc60da1b178f888d5b1c721aca1c74aada8ca3e91b7feb497ca5e75e34dfff15afafe8cfeb0fcba10ebfc707efe4d1208f37", "d3fa0da6afb67ff635b0097afadbad2a4b39fbc1f9fbe5bf47f2eeb9dbf160cc5fdb56fd6585537e2986dcd35acce5bd6e0cc5ca7742baa8dc4becf7c63d92de", false, false),
(14, "TBF^c5V2(MQvAt.X+hi&|[YOH_|}Q))<+-PD?^oO.Q9L%}jqAvJm(c_vaL2<?:%+", "1412cff5652cb3a15578cb06efaa8a6f87ed1a4bdb7d9fbbf77eae89c8ad3bf1e2a4fad0fa4c74d1c3c563cd5dcda02ee3e3906cfafb365bf2fd5d3a7fcf3ade", "9b352eb311282cb9e9fc8e0e0e29598b04e383ed2d3f35cdace3b09b93d5f5dcd2fc1e7c1d3e002bdfbca632fe7edd74ba1caefbc834adba31bcb24553ad89bd", "fdc46e35757d5dabfcccb0d4eaf2ab54bafc5a8d0a28d2d2e91541ec2d99e05efd473066efe6140ceb7eaecdb56f6e7912c717305e034abb7f4cce8efaaf6dfa", false, false),
(15, "woAd}*zrXA{MkQa,Jqe5{[.;PnO=u_;d<fgb}ZE:uN|'_hag7J$[Vi9SMZM4^RU~", "ec4d778beebd6de0c5eaefcccf13fbab8804c3cfe7ddb4ae8fdfbec9a59f4bbaadc8fc9a367eb6e63cc9e42fe6afbd513dcac2fed1ab5968dcef3a7d687da5a4", "3cf8d5db9aadb6046ceed5facbed55e64fef9fdef2f6c5e83bcfc451fa456c1f8f9cbebbed7be95f0757790fc1f1baea9bd66c7eeb6bfef3534baeebff5309e0", "43eeefe73ec47a3d78ad6cb91ad45fc3fd9b5ee2590c1bf16f4bfd96cec01ba4dd1ea7fad4ea85f8dfe46bc18fbaa2feb7cd5bfa9deaed5dadcbf70e9d89d38e", false, false),
(16, "$B1Y o:G;[fG')ysgXrh VEsSTu$ziY5K}tHL:xFvbvj=9H5e:Q=F`Q^[2tRVf?)", "4a0c41bd7ac0c37df5df1f3d9628d9aeb2312c407a6ccdac7bcca5bf8c4c3e9bbd20438dc4e9db241eb25a5a54d4bdcdfb4ce3aab26a3cbcafd536cc3a50ebc7", "ccb5edd5ced43bfae6a0bdc8b1b8caaeb292b21bde4a19f316b0ac6b8f8ec3a7e4306ce9cba8ee20185c34b31bd70e9d71fcaedbb13d36cbec14425ebd00951c", "9710dd3a204cd5f18af2e27bea8cf0dee083c86a237f2cc2a2b5d2add085122e931afce307c7edeef0bb4ecd7d69a2720d3479a117517dbf9d3eff73f13fdcaf", false, false),
(17, ";xZ5'P?)?=~ra(xZef*r,djq/>)z6Cs]~=&<YskN7_qlTx]=-]&-N9Y)`6?d].$K", "dda824700f7e75fa1cdca7dc6bed6aaafe6d93fbc4fc1fe8267bf0f776bacc5f8622080ded2cf7f551d14da18aada3f9e53fc936c655e2f5a7bef147ac7baa6c", "bc65ecaff9b9dcedaa7fde26b7ecf69c8eed85d9ef5bac7407e1133eb4afd32a11c8addf9aeef36b9dca8ad2133de6d320ffa2c75d7d23f79cce00f68c1f4ae1", "5fb99a7f677f160363d9de35cff191d1119d0adeab1d1ef9f2dce7cc8f5acaeac3ffadcd5d4773caeeecfd0898a31c183c01cdd67f846fabcbe96735acfa8443", false, false),
(18, "Ru!&9#<$rmRT5q1DrRo ^U><ca3RH(R>.z=VDLBl/f`g8=H?F]9n-y*msDc*=va.", "e134712e8c5a528f33b15a5ef00f19b184dd52eca5e8adfeff91ba99f2642eedefadbb059423c05d99a52b8aa98c5520dd8d97fd8be2618e31aabb9ac67ed1ca", "b6fb8216aef7836effc610ff56ec8c0144b8ddec139129dddfdbf490e8fa286ffa6c44a14713a3c1dcca02e2f6a9b8fff1fb036d5c292f9f851a91a3586fdbeb", "5b6133dac87cc7b4b974c3623b8f5652fbcdab0cc2c2ce6a773285c87a676f32fa68f64d2b04ecb88ccdbf42c4fd6abccbeae1febd5cfc8e9b48c7efe54989eb", false, false),
(19, ")hTd?yfz4.(WJ_&IGqwOr%Jzv< I<DMNUb`J:VP7dc2Wh{HnhrmGkep16~3P5)$i", "099d60bca34b051dca11e998c9809361e436255cbac9b34f95b12afcbaa68d1deb9b91af79ecdfd32bdacccdddeafbacccfe70bc12c6dad0df2d4fd8e6bb8c9f", "d2bdff7e75cbb7ce6d841c4aa5edfa13ecfc5d2c39fcaf0c5f7056af6e96fbac5e594d249c0d5d28394e7489b9b00adb5cff1bd241eabcce93578d5aabb61ed1", "d90d6f1c25f0b7c5d966b6f0ab92fcfca9ae2d971e4801fcd013c52e5efbafdddc3be2cda3787f5c6f269ffe6d5ae82ebdc1df3eb716fe6cfe600cf25c2e7c65", false, false),
(20, ">k^R_+3O5.V%(z*#m`I4sD:u9iLii:EqnA%@(MBZ 3H=mti+X|CNFnp*F>ILbrE0", "c3e6aa0fd419ebd8bcfca06ddbdcb52b6f5ed6b384ca26dcb1faf6ec5c3365109599f691be122f22ee3bada1f1bafee695ce7a2694b0f28f4b9e83ec151deeb8", "3e8ba9de0d0a807621451139e9decfd27ea07315ce2cf7dbc0b425cd43ec4095c6e1a92fbacb30cc6324ff0e22c00bc8df9756143022fdba63deff3a5b8f784d", "f17fff4ace7fafa4fa1e5ac44b9bc3b4a8da0a3e6dde3f6b54aaa8d3d1a6fcba70d22beef4eac074a857ccd17e6d2aec7cdfed749ee6ecf61ba333bc4addeacc", false, false),
(21, "K?bF<,P}f#v9''gUW lI{vsPt%(LCTgVEA+!05*&@!M@#7c:&RBA/>$5{HRGFC<6", "ff8672430bdc547be9bcc1306fc08c68dcf3bbaad4261dcc7e4231dfabec10db2506cb012da5edbbecd73dd8389ea273ed325e9f2f1dece6044a1f07faa6ddf9", "67a32bf926efc27fead7b4d7d188cefdd8f5bf7b67ef2aedafd3018fb53aaaec8e36bec8dd9a0a0d36cec459edb9ef3a00c9d0caccf5e1aecfdfe2b31c8ecb3a", "7b35e80a5fdd95eb72683dcb963bada60f90dddae70daba43acc9eb507283fe0a0be5f3cea8b75a30bbefbc575017e47fa47d6ffd2beac2cecd9edf2fca9f866", false, false),
(22, "67@77E5-P]sX'Ghd_5jPMJ3#A_t9sJf+l:.l9*_4'.sE)T}n{o)/3Y)y B<.;2QY", "b278e0d99efec057bbb1c7efde8251c92c78deba7a9af01cfeccfede246df1fdd5de8e64ecc482b5db359ec58f6a731dccbe1c2ef1ba3d7d11b0b9b83c33e6c7", "f70d3a6d8ff5ac76a50bca0561fd61ac8840fd22f8ec98200c1be0dceca8fbe2ee2bf5cb8ce9e5acdaedf8ae7380e9c69b4c9cc8ec4b4cceb8d8e93ece1d162d", "48a7a1dedcb0b0d6470ae1c4a0cc09fcffa4f3d4b1eeb8bc64fa01ed608dcbfeff888861741fc49aa0a83d3930ffc25823557c579ebbfb9ec15dd1cf798a4fe1", false, false),
(23, "'kTW3_2d!W`(1ALd$N(a%<FSrFap:/e%b>9m8q`)Vge~IIYbgBy]4?}?mJ6^0z K", "5f31bcdcac2dddb8ed64dc0ed2220fd8a049f95acd15d8e803aff8eb31bee0ac6ede2e8d115740c3d4ecebf6d5d5bb8c136f61cdcd64cb8c48af973ac650c66b", "cb2abe561481ed9c9b2cbe9ca6d55e73cc76f32f6ffdb0a6af1ce0c1be9ad9eca74fa8fab96ad4be8e863f584a3330fcc71b7a09be53652ad75d9b3a4c2747c6", "3db52e94a07dfefd94ad0919d6cbd89d7d2c02327f120e492cfcd614e3dc7deeda135722327deeff29061bfceafaf1c90a728b162af1edfef530ed9a3d6ac35f", false, false),
(24, "_PjpO'#<wNg6H']?T|Y%h;[)LQ?5!*<4^Je}!MhWyzEE78B[mB,J926LE%Ya]m_?", "386c9e1d80c2d3e89589ad3cf8a4bed6b5eec569081b9dddecd1eff544b2a5bb49e8dd56f42faecaeef0cc1a45dcd60b983afb0ff24cb35d4ac5a9bf71be19b8", "f08abfd4e1476fa92f837f0cfab9a6f2c93ac594e09aeb0fd0d001ed22dd801e5cdbe3ffcfb1db9f8dfc867ec1acf1cd5c0e0fdfacca6c5b4aad7fc2fee79fde", "bdbc005797ccbab7613aedfd4790cefa1e501ebebef4a13ba6827ba6380a99f6e2c17f7e955abaf11bc5e8d3568eb40b4c89b1d18acf60c3360eaa7dbf0cfc56", false, false),
(25, "Np$EK2g2qtrIe`[&1+$._b#R}=<[bfAX_v`lc-%.o]|*M1yB^?z)jOE)0Eyx`+V-", "c4f9adddfba987eca12bd5d17dbf615afb59d60ab65431a57f23fd269d4b6c11116f0dabe0dcbd7d9cdf395f2d507cae2ce6beaec399ed9ed9ec592ab68dbc57", "64bf72dddc7fd2393b8ccb6f296bc8247adc3cdebb8cb0a0d66da8e4fc9fb57b56a156bff38c2f2e1fed43fab784cb67d14d0d26aca60be3d1bbb53f8d3bf051", "59fef9c2b623b78e21b698da0fa052bf5029a247c0bde7bfbeaa632358f2a320076cafaaf26058ce54fee7cfe7716412bf4f7c7d52074bbf93873e88bd85aabb", false, false),
(26, "U0:aM6DV+tfu&6]q`%^J?YdKoux?(l4>ha<I{t>cPrHv'So%To!8+&@y_,>KV~_.", "ef1af8cd955220fbf0fad6858b8109bc637c9fee8a6e7a9f2f30afc2fde53cd711486da67fe381ce9fb4a2fb1b7ad06ba2efd0d8fb8b19dfce213a9bdcebca1b", "b6ba4763a1ad6cea87795f6d3b24063df9db2bbbe9ff7a5e6ddbea900be355f9017ec8ed22582eb780fdcca7602e4e6ddd925a8fcdcb3fadd062edbbb7e45c29", "4bf3b29a2ffcfc32e40b6ce4012a7bbfc1dd5c2fbe3cecceebfadccbf55b7f7aeb8f69f7f7bddf31b7570d66add0c84d0c7485cbfaf4b3cc783cc8f4c7423103", false, false),
(27, "{;8C5bYad1]AF]XG]uY 9 <:lwUnA><&DoRkP21xIFv+#W`djvLg$,|j$O<Sk:&7", "ef9db371fc7eafed4e086ec5452fbebeeaad388b23e26691e6ffdc21ba1bf6cba5a3eced4aaf884db0c5dbf0fecb61daded0ec9fbb2dbe4eec2bc91bf7e8c11b", "b61fbaa1e7d9e25c90ed2effc5ce58c10fb6e32fd3aa8b4bfb3fc3e35bfe2c83ee2ed18fffacceb660abe48dbbd97dec81efe44cbab15755fba66a7f550cdc16", "fd9a4786e4bd1ce6d1daf8b33ec2ba2ac2fdba1dd54ef84bbc17a9caa79ce8fc21eafd8d67add3bc3603a5d7bdcfce0ccc2be29fa3cb0efac59a2edb864a22f8", false, false),
(28, ".! ??0{Da_#SwQLCT~x{Ng{)(n*:=7]LDl,**&MaczTYR2,gHu~TF[L|fWz}1]6F", "ddc369c091ca12aadeeeafabaf3ea313b9f3caee62fcef68c54e05b0ddcc34cbcd51b2cdb3d3e2baa7ed7eabb67fec2ad244195afaee2e2ec5eeea53dad3dfdf", "8b2b4f0329eaaf4bcfd0f8ac96bdcf90acd6ebfce51ea9bab59966cd409ba77884f996aad59f44e20bac0bf8baa19339fe7ad81809cec4cacc5f4ccde17ecc4a", "5564dfd2d0f7baffb25fbefadbe2f0b9f69b2ff3acb5af4f6bfbe1ab94e78e90b3f4cb36b97f974e1a634caf7d01bcfdddcdad44ccce225a29ebd1eb57e5eed0", false, false),
(29, "nT7wc>TIPx,S;AP>ic|Z/;n0( ng!$r_[=9V&ygx$*/ KIz;9?AZ/8lIMFVhOD)D", "a0a4d0cca54633a1a710feb4fcccdfaf604fb0fa1595f8baaaafb9f77b69f1a4a842a73a95ffae7262ddbed6d09ac8fdddecc1c7ad29aaa51dd1d968bd4362d3", "983b0d8b7badad776bd9832bfa948d2cd1dfe8ec4e659b659c1eae1da5ccfaacce8ecf4db4b3eb1fd360453c8fa3cd2b57bdfec7d295748d5fe7eedf58fbc5e7", "a0c9d36509b8ddf26687a5eeee7ab0dbcbfcaafa3b0e1dcebeac893ad0ffe99abdfec9ccd983dbfc20aceaa890a96151fce0d4bba66628abeded55feef41f3e6", false, false),
(30, "P|E]^+NYJuVy-M#-nG<Omgc<PG*|~/!p%/_z0_[FI%V&!)S4nPti?agZ+]A#egi ", "4cf6ca932b80381fde315f1f37e0548db0cccfefcb5dda2f4c3f1efb09a364da1fbb8b9d9f8b5c92ab3a45ac5cc677da03e5df81978e6627287de230bccbf5d7", "e9bbf1e1c839efd2bcca25aedce1aacbddacb9d20bede3dfa3af0a17feca3d8fef3b7bdbafbabb5b1efe60698bfe845cbea2758e6e8a4c96ccb7bbfcdc2e1e7e", "fffcde8a4ca32b7452aba5394eee0cd67735af921d052eb8c2f071aca1ca6dcccefde6cab81bce40b64c9027c2ca1ce91e82279e29aebca6ec3cc1ffa369e557", false, false),
(31, "zB|LU}4f7/3g{co*/OGVZa]gQJ,zIdI%~7jN)z)D4Z@@*7&:H~?ds(_@vY&$:5-D", "3174b2dab8f5dd8ae6e2fe9bd88c91a183be55e3a58a15e228dbdd474db2dd6b9dbfcabd355ffd651bb5a7acb99aaf4af404f7502243abfc74b7ea8e2e0a075a", "defcb7add0b9ce2bb5e3de8aada47dc33ba2caf4dde2ecbd1ba2c7024fffada0e0016db0df725e1d4f1efbc47ec4990feca6ab5b0ebe08dfecb1ab9adf4caac6", "5dc0f4240eeabfcaeedff0e5af40f9d230da84fe232ed5af96c3d7f1dc42ed979dcce509ce153ceaeca77d95fddfe522cefa8bab602ef5eef985afaf3fa865f0", false, false),
(32, "4un{Zz}/R8A-MyT(0G (Wi5Zf zt?7'5Z|e1e6xmk_4f82]Hxa%m}.R6dcX^>bA4", "9d3670e6db52cbfcfffdf41391fadc4caaa838cd648caef6ffaadfb1f9fc6feb1ed87b6bebd9303e2bb1ca1f93a107ac699afb9e0bfe63886f5cbfc47b42fa1f", "03ad821ddfab51d59c7cf9724bcce80f4a84df8bd3bdd99fcc8110ca24c6dabad06e53dd88bc8b3cdbe011ac03dadaf26b9588188ac7305cd8ac3ceee590b264", "a28171aff7bcfdedf8e13a9f9eed1f479d365fecf4fde27d47b4a34fca31337ae0565aa038fea720a9b4adcfb4ff5ee2e13da3099e5ec3bf8b3ac126b1bae7f3", false, false),
(33, "EK?CS_{`xNriVfNtzjZ)jfzY: bW11!{_XFE5JQy8'Om.u]A5?I9h46RFH~j#4rN", "46bee1ff9fc08fd0209300d7704e25f3cffe3bffb83dc3f6d1223ecf14fe682eb052c6fca067ced00a348f30cae2ef53e6e19a7dea2ffcfedcb3f9a5be23f8d8", "abecdc5eb3b1c0cbadae6d1ad5be5a5ecfb8cbd1cdddbff1f0aec32832adbfdafc2ea4cebcc268cecd4afddc9ac72d6ab51d41dca36b61caadaee254f83e22b1", "a9a7862deefca268af31eafa8be9054e8a16d966b35ac3aff8c50f19fe951ecef4c2b61afa99bdf174cad72f3fb3bc1f821ba13acbcdf8ef0ce68cd07ae32fce", false, false),
(34, "p&lYz=l7{[~tngRkukJ;KBT}@A0leyRBe!H:hiU&kl[y&`u>&SFiT:O#GJIpMh'E", "bde5bc91bbd44bd8c50d3c11c7bffe4463ff9be8d05de98eaadbc5b8980b6ea61f7e0cb4ead586cdcfbcddc7cbd72c36d031936f8cd7afdf4a1dbdb3bbaaa8a4", "fb17bf100d450dfdaecf3cc9400f0baab48eaaa4a2d29882f0eacad396ffed278917c27a5a3b9831da0bad627c2b8ae3770a7e87e75ffdcdbac7bb8d2fbdf23b", "0b4eb37cfa1d7be3dbdbbaedecd57627aa3eb8c8fa2fade082edd5ec48ffbac4268ca50fd950a4fa0d2052dde54d5aea5f02f53ddadb6d030f7bac3014a5ba5c", false, false),
(35, "S*KXnZ.xCul2qf@eFs=UgtRMV7i8{,'^6Fc)E Io{U<v#dMj^ygnpzw9#+U:X:x(", "da8d7b3fdcab5b8720c57666cfd8401aa0cd8980b3fe2f784edfb2a35b4bec74dca3822bdae16a212bc68fb75f7c40a3ff142db26d0f30ac3f587ddd1ebd19bd", "5bc122d7befe13fb2db47b0929cc4dd65d76f2ce7dba7ddfcc98bc4e800d1155f14c7bec40e9be5d44cc4a4465f7facce3cecfcecb353d5e0f4e9a71ad4afb6d", "ed17bbd1b6c9c2afcf076cc131e2ba4deaac2fa13d6b874e0f46fefa962bca9d4ddeb51cccc5cc95ad9ef25f12bdce8a3be5f5ec5e6a71b6cebf86de3499d6b5", false, false),
(36, "~j9$($ee1%sVvvcSb:_{GXE$v0Gj_Yi$j_f#:I9){8`HMjzMJ%@k{hjrk!N#LaU3", "1b6f9ba29fcf10a040c26f1ceaed8ebee61e9ab4cdcefa1d2440caed1afc6d72b51ac7ed4fcf3b0e6a18078f4e3c7e38eae7dd6d0c8079b8acd70eb0226bfac1", "d5bd57c59fc259b417fafd0bcb673b1dbf9d9d2ec5d56caf5e0ef8a1de77a517c9edc3a7b8049f58367a2d7bbf4b0f5a2d6370b5e603c2ab11ae007edaa0bf6f", "1f5abdef187510b626dde03b2e03de87f20cceb722ac07dd48fdb1bbdf7bde75be7e7bf9fbccbfdf2e2f84dfc4affdf892f0b68da5cbcc695e0ef0cae4fabd5e", false, false),
(37, "jDU.sEMRN|edVY 7Ou=ik`zEq9D+|>@V/bX$wvUA,pG<en.7p!^ !uFP[}$1^,`c", "2e2ca84e7a9aea5bda5c1f6983197bf2a2ca5ecfcae9255c0faec70edc4a4652d4a475b493062afe41236be65acebc9cf6dd31bfad3bff7f7af9dabeecbd0eb7", "a96b88d8eb6196aaee96aeeeebac50feab10e158fa86de1ac09ebd81b8b539d5ac8d7dab4ddeb6becec9bacabf9e10c8ef7cb7c1a8086b2cddbbd82a6e9dbfe6", "ae29e4cacd6bed8cceba8badc774d023a51dbec1d8ab19be2c427dd6e65387a8255fde39fa533bab549dbed3ad27e78e930bb6e44d4087bbaacef15663fac1f8", false, false),
(38, "t5zXj.BaPv_?V{/U~wYU&(2(LBjO1=~9F4&t(it{I3|$H|#s&XdKbj.^j6GVYmZ>", "7024c414e52abe274c97c6b23fb14ee00fcea8baa4ddbde5d13cdce9cca146f96355b44cec08aaf7cf65fe20aae51dd88b04dce7fd52bc80eec0ed23aaca7f2b", "370afb5eb5ddbb6dababcf1d0b4be5c1bbfae8fdb3a75e07cedaaaaadf6429afbafdf4f30fa86ad47af94d68f02f543deecde4e62e5cf7a41783fc4fd7a592b8", "6304bbdcddf1d085ea5daa9b361aa6bba21cc02abf0e2049cef18ea82ab5dd49d6ef798cba97ec89fb73d8099cb43abaf1c5ff9407e692baef7dcd0f8b2a2565", false, false),
(39, "aXy[U9u>EK#1ogol {+Oj#!BvMJ`{Q:s4`9zA8_x@]Ynt]M{H_T ~Z@-GUBYJ;AD", "edfeeff4d6d1bb24b922c5b39a1f42661fcbdfefea79cf0da047dda2d76a09dcbcac2f745af4bec8bb7f8f3f7cadee4726ad93e21ee5f5792a3a8228acecdce1", "7d33cbbfabaec72cace3824b44fe77facba0fbfd601c22b96df1fc1ad12c01aced2a9f3d75affad413eaaefe3cb5e7bf4fc3fc9694adf9dab389829ce7f6bceb", "3fdd9c1fefc51785f3f4d2f4d671f5fe47baddd2d693b1fa0766cd5ccf4b4cace2c191b5bdeccc95bbce944d297c09fb47a91b6be72ebe3f486d46f606fd22ac", false, false),
(40, "d?N#!^MH$it4OK$dP{dq/CLlg<W}RulX,oZFh /[x&GWC;l,.3+ROaPhi;A,~UzP", "54b16ad2830da5fccea2c23bd90aba568f0ed87d4ffe6f1753b516bda408e4b3a4bedd7f0728f2eed4b364f6be0eaabcd9ce1dea4f613d6dfdddf4028ae19e0d", "87b7fc4eadb4fd5de0dd551c25b9be01a1085cadd67654e54c33c1d9c87f9ebfc716d874336d3239bee98fc2ee7807d8df0dfcb0ad32b073583c2ab7b2eef9ca", "6608124c5777ceda1b6f2354eacac01abd6cb7ca65de5daeead4fadb3cb59fe684e6af56ec3b3f7aac77d9f6b09b389f20babaef8a7e4800a0cfb81dbba5fa6f", false, false),
(41, "Fx(=hbpgIo$vkcCBYu{#R| i.gNOE>YT_$KUkCEH'3o.cK49 !bruhNL|k&'$hpc", "c8de7aa6b4efcf4ad722b664e37a4593bc2cf52ae8c7deccfa92b8dc16ff8deffbe9587c30fafebbec51ffabb02c7beeec0cebbfb44fbedbba2ef8defb200afc", "114f7c1d48087fda6a7b53a929f1279056eebd71e4dee1ac2dbc2dd9a6cadabbdfdc2be3ada7d6b1efe881843bf7ac59ae8ec6c2dcdabfb6faea867dab1c5f0f", "2be8f7f0e8e4c5ae5ddaac1be56d1db8a767effaae2a5bb528aeb8d50342b31afa7fdc1e323ba7ac2accf50c5b3213d11e39d6c3055ebeec2b728fe1b2ae4544", false, false),
(42, "YY?,o`k$9M0Jg63dQVzDI1Pd{ YKT:<XvU+~Rzc9 *hSWq_FSikN#l;563+Ygf7F", "5f243a061b13b5becd23a14e464b4d7ef7b0420c49bb273b4afa9212d36df76cd320209bb029fb14bd67d4dfc07c14d8daafae0d1e522a50956c5a5109cb6ab6", "94d02f0e0283dafaaf1fdcebfe0eac13d3a7c32faaa35bea6ccf3efd43171cae4dab7cffccdc50ccac3a04fbb21a4bcbeeeaded1ca5a42efc2670eadbcfa4baa", "10e29ebadf462d8b1f2e74aba1acba8dae712bac0d1f545bd17b2faf18f2bb44173a01ec57e3edb7bdbf0b50ace71ea10a59dcedea9d78dbeccddab3ee77f67b", false, false),
(43, "PQ=X'h(q1mFI)0K?(Zkr_@k3`*~a@9*b lLO#p/J(Yep&@ysbTzdkH_8I@ zVGN!", "9acbcc5d3f6d7b286da6c365b73af3e5bcd9da9f30d3baec814fcaa9863695ac2fdb0f2b2d6badf70f8c52e524a4e45a7ac6a04d0a60afdcbdb2481d5be9e4f5", "cfba3dad489150edcbefcdbe1b3ec88c54a64d88bb72acdfafa3bbace82c8cb1edc54a58a4bbd8e5351136f55d32fddc9098b1299317a3c5bfb15dc5a1dd9152", "41c129ca54f4119d3dbe0afb92a52d5c4b81672a11cd02ea6d764dd4fa14db24f41de4f381e460987a28f48ab4c8afc753ebfb63e24e9b5b4a97aefda0abfe98", false, false),
(44, "}4?aUK>uNeCZsP)F4@Sb0rL7jW@R p]EE%V'D:OS0AZ`kW59DQb**uCHs,L=mIC.", "812baba90eacb9677e705c0e46b4cff6f87cd6ccab2e394cf2bdc9da7ca01cb94cffdc53ffe9fedbd62e024d5baf73f68adebdadff9590cc634a22e84bdc52fe", "479fcdade56243bbe7fdf06b70c347a6fcd3bcf165f6839cf1188caf1e1cc7fe533feda8b8d5eaded8ec6da13c782dbe35f0372fadee8d60facd32b1ff35d49e", "2afe9512aacfe1fb2e6b451f9b82bba7ccef27ce04c99b4ac5ff85d3d61e364188a1b1ca8a06b5ced6fe40a13d84f589c6ef89efcd8d51aee1c7e6c73a33ea5f", false, false),
(45, "s2pttZ>O`y<}P_J's,Q>&66[YB@F%(q_alI(}kn@_=9Q4Emr#LhUTk4Rle`ozKKI", "0eff7fef46a5fe3c7ddbac37ed6215ba7cdb31b69bc3a465fa7b95e5eeeca6c52ddad02bacccaadf35c2b1cabf9f54ef4b2d9f705b3fee56babfddc01e716ef3", "5727eca682f0edd7731c46759cf9aa9ba75ab4bf756a8dae89a9afe1a6fe82f53e0f83231fe2f3beced7eefdaffaab860de79fdaa8eb4ddfa3ebcfeea5f703f0", "8b1cfcd8cd1798dad13fc314ce77ebc59bd8aabecb65df3bdbacf260c1cdd67b6c084ba1caa54ef87e99bec68acc7abe671dcc564bccd46a62efe8f1ee9f41a7", false, false),
(46, "Pk_)U.7~m(CjfNJLtjv/ *V2X&L0:mQe(Q,Zobx3yp>|d(J>F^>8PWjQpF;!N1`'", "5cfa8ac1fb77be9f0afea9f8dfd26f0fdb3d959775fcb2a76d02ed08b064bbfaa342fbfd6c4c9d70fed62f2bc7cd23ab5f9e41ae6a5bbe22dca9bf2d5ce53cde", "aba10c8f1b1fcd4ab7293dfd0eaf30acd6182a9e8d26eaf28dc1bff0fad8a732ffdc7d002c9c50daeb09c5b43fee075ef61ed5e39e0acea980a1d61fa5fdffff", "bfdc2c15e460a08d1c61ce7da0cdd56b0a3cefebdf9e2d7adbb5a18bf0a7cb1749f1ccfcf2b1ecafec8b00b1ae378ba1abebfd5bdafaeb8e9562df03e179cbb1", false, false),
(47, "]#nZYB.ZJ'{z0} ~_4SMFl>:G_6Ik@F:%1c1+d#;nl^NNiYE^yps89,I!)_;Et4[", "fd04e1f66e15ac438cb901dd762be2d4bbaffff2fbbfd13680f70409fab4a66c9c91d6075bdbfeab3c1ff29d3de5e8724198fb58d2731d405ff5b5a398a1db7f", "ffeb9041cb0abbcea829ef75d119addbb8d11607cd3bafe22fac1be1cdf0ef4ec3e9778cbbaed7c78ebbbcad0eadcef3ce0acff8e904536fcbb93fd803abb72b", "aa0ea85b1e7b932c9059aeb6dcc6ebfe7401eae3ced9ac447cdca80e078d78b2cec5e5afeb12a01d57d0f7caaaeaf4ac4f82dc05511bee3b0e818ccb8b259deb", false, false),
(48, "bL`+P<;GM@7r{vX('#[KjH$U)mu_?N{<~J6]U OY}0w6>sGYJDj+d;;pG1mdfNu!", "5ab96dae1f292eccdcf10e9d7aaacecf0a361dad78eeab3e0a673e85ffcfeafe192b25fbb3eba6da9deae3134b85e6a26a82763e4f238effa99c21894bdda31f", "c926e013b1407edac692f28ebdb2dee83859a0f5bcc6bd0e54719e1161fadae4d8a57dc69ede48acedd5e6fa75bfade1e9da98e2ee87b1aae8180aea31ba34cc", "5fa30454fa56cd0afd6cb549a5cc6b10c4da374d434871857fcc110f9ce552211ad92bcf48daf1ef35ae1aeb98c3adf3b03b33c5c9204d95f85caa4bb305dc2c", false, false),
(49, "irciC3 <dZ<g52|Fh@^rb^H_7.1Iph$5+PVvDgcAmP8Qp8-%WLQIdsmCOuE0<&V<", "739eb69fcdc97d98aecf8cc3b0eb733e7a26aaf1ef6d677e81abcfdd81dbdbff8a9d93c75d1e0efbe2e0d0feae0cbfdcb2bd04c3c9f40359ac100ddf1ad684fc", "f5fe06d9fe850aa404c6f5ceac5d8bb9752a3faba43ceb7baf9d868cb0df5c90b8cbb68a9a36bb9545efdd4ad7752c7dadb0ea571e4effc77d2713dcb32cd8fb", "c1da97d66fbd4fc6bec9e02d00f7121adcfb4b273ed56dbdcbaee3e60a9482d8aa9dbb74237ed69eb297835ddd4cc1ff12e7ffd91aca4f6e2b7ed2bb25d20a37", false, false),
(50, "I'E/IesBG'4n<}`es(eW8EIy}KYbhyb_f}g~R!rV1DNe!G|vtTY;H((/gOGsmr+*", "ea31b5d9edd65810d60aaf1560b5a9a5fc7f892acd4a9cba874b8fa0ec6aa2cda81f0b9b0cfafe894c4c1ff04b77ae84ccff09fef7c837e3cf86b0ababffc85a", "d2a61f623422ef961f38ebbc01df0ce1cfa3e06d216d7a47bfca9cf02411cec2ed8ec18672af7ef87d5a0dbed25ebfefed373f6c13b6adc6d33a18f7df5e2f9f", "bec7d9dff14f744ea5b1bbec6e178d5916fcbaee89968ef7e2cf168209922d5cfd79f33edbd656507476fe7b14ba319fef487717cbc4d2f1a5c8394efda2ece0", false, false);

INSERT INTO `account_card` (`card_ID`, `account_number`, `card_main_currency`) VALUES
(1, 17, 2),
(2, 11, 6),
(3, 29, 11),
(4, 16, 10),
(5, 31, 3),
(6, 26, 11),
(7, 28, 12),
(8, 29, 2),
(9, 23, 4),
(10, 24, 1),
(11, 26, 4),
(12, 32, 1),
(13, 16, 3),
(14, 31, 13),
(15, 23, 3),
(16, 17, 6),
(17, 26, 10),
(18, 21, 13),
(19, 31, 8),
(20, 13, 6),
(21, 27, 12),
(22, 16, 2),
(23, 13, 2),
(24, 18, 13),
(25, 2, 9),
(26, 31, 4),
(27, 20, 10),
(28, 23, 13),
(29, 21, 5),
(30, 14, 2),
(31, 31, 9),
(32, 26, 2),
(33, 18, 7),
(34, 10, 13),
(35, 32, 9),
(36, 16, 12),
(37, 8, 3),
(38, 31, 7),
(39, 23, 5),
(40, 28, 4),
(41, 20, 13),
(42, 8, 7),
(43, 21, 7),
(44, 14, 7),
(45, 32, 3),
(46, 13, 3),
(47, 24, 13),
(48, 31, 5),
(49, 20, 5),
(50, 24, 9);

INSERT INTO `card_daily_limit` (`card_ID`, `limit_amount`) VALUES
(1, 56145),
(2, 23658),
(3, 87014),
(4, 79252),
(5, 77599),
(6, 92196),
(7, 74544),
(8, 11754),
(9, 93968),
(10, 29496),
(11, 73014),
(12, 61842),
(13, 81705),
(14, 13573),
(15, 51301),
(16, 9147),
(17, 78168),
(18, 31223),
(19, 23361),
(20, 30963),
(21, 92978),
(22, 79806),
(23, 15946),
(24, 58086),
(25, 81660),
(26, 47674),
(27, 55384),
(28, 35027),
(29, 56263),
(30, 52827),
(31, 84781),
(32, 4693),
(33, 66377),
(34, 4351),
(35, 67737),
(36, 73201),
(37, 72848),
(38, 78921),
(39, 84649),
(40, 44095),
(41, 202),
(42, 88140),
(43, 15381),
(44, 71683),
(45, 31562),
(46, 5413),
(47, 67267),
(48, 27415),
(49, 8347),
(50, 91479);

INSERT INTO `bargain` (`bargain_ID`, `amount`, `currency_ID`, `bargain_status`, `bargain_date`) VALUES
(1, 5699.3, 6, "Pending", "2021/12/06 8:12:18"),
(2, 313.08, 4, "Failed", "2022/01/15 23:38:19"),
(3, 4842.75, 9, "Waiting for Date", "2021/11/24 21:18:18"),
(4, 1261.62, 9, "Waiting for Date", "2021/11/29 13:34:15"),
(5, 8586.87, 9, "Succesful", "2021/11/28 13:10:11"),
(6, 7778.85, 9, "Pending", "2021/11/14 1:12:56"),
(7, 7297.22, 10, "Failed", "2021/12/28 23:8:58"),
(8, 823.44, 10, "Succesful", "2022/01/13 1:2:13"),
(9, 7998.64, 10, "Failed", "2021/11/30 15:52:24"),
(10, 2013.69, 10, "Pending", "2021/11/18 2:34:50"),
(11, 3943.27, 5, "Pending", "2022/01/07 22:44:23"),
(12, 2482.83, 8, "Failed", "2022/01/15 4:8:48"),
(13, 3951.55, 2, "Pending", "2021/12/31 8:51:52"),
(14, 9149.12, 9, "Succesful", "2021/12/16 0:20:19"),
(15, 6990.7, 3, "Succesful", "2021/11/02 23:52:32"),
(16, 5458.75, 2, "Pending", "2021/11/21 20:11:2"),
(17, 7062.93, 10, "Failed", "2021/11/26 16:17:14"),
(18, 9249.58, 13, "Waiting for Date", "2021/12/06 13:25:50"),
(19, 3386.29, 1, "Failed", "2021/11/17 18:24:23"),
(20, 9593.02, 3, "Pending", "2021/11/10 0:2:43"),
(21, 3299.17, 12, "Pending", "2021/12/27 1:42:30"),
(22, 9945.26, 10, "Failed", "2021/12/02 10:38:44"),
(23, 9339.38, 3, "Waiting for Date", "2021/11/11 0:21:9"),
(24, 2348.35, 13, "Succesful", "2021/12/16 23:21:19"),
(25, 4115.16, 10, "Pending", "2021/12/25 13:34:48"),
(26, 9051.3, 6, "Succesful", "2022/01/09 7:41:58"),
(27, 136.7, 6, "Succesful", "2021/12/11 19:21:18"),
(28, 3077.48, 7, "Pending", "2021/12/08 3:49:38"),
(29, 8219.66, 1, "Waiting for Date", "2021/11/15 11:33:36"),
(30, 1027.26, 5, "Pending", "2021/12/20 12:2:4"),
(31, 3814.88, 7, "Waiting for Date", "2021/11/18 22:2:55"),
(32, 3375.22, 7, "Succesful", "2021/12/20 16:56:45"),
(33, 8124.71, 5, "Succesful", "2021/12/23 23:39:5"),
(34, 3734.03, 12, "Pending", "2021/11/08 14:33:31"),
(35, 1311.18, 1, "Pending", "2022/01/05 10:15:37"),
(36, 8438.06, 13, "Failed", "2021/12/05 16:8:26"),
(37, 5845.16, 9, "Waiting for Date", "2021/12/26 3:21:12"),
(38, 4287.68, 7, "Failed", "2022/01/07 0:34:23"),
(39, 1934.2, 8, "Waiting for Date", "2021/11/04 10:18:20"),
(40, 1861.35, 8, "Pending", "2021/11/17 0:51:38"),
(41, 6143.59, 5, "Failed", "2021/12/12 3:26:2"),
(42, 4404.84, 13, "Waiting for Date", "2022/01/04 15:40:11"),
(43, 6507.51, 12, "Pending", "2022/01/05 14:53:30"),
(44, 4180.69, 5, "Failed", "2021/12/22 15:56:14"),
(45, 365.59, 7, "Pending", "2021/12/27 23:19:41"),
(46, 1390.83, 1, "Failed", "2021/12/08 5:7:9"),
(47, 4210.33, 5, "Pending", "2022/01/12 15:24:14"),
(48, 9921.54, 4, "Pending", "2021/11/30 14:41:23"),
(49, 514.63, 9, "Pending", "2021/11/29 7:30:12"),
(50, 8645.21, 2, "Waiting for Date", "2021/12/27 8:6:15"),
(51, 2684.71, 1, "Failed", "2021/12/25 15:50:14"),
(52, 876.02, 2, "Pending", "2021/11/28 3:31:21"),
(53, 4186.86, 13, "Succesful", "2021/11/01 11:12:37"),
(54, 6447.25, 6, "Waiting for Date", "2021/11/27 6:42:27"),
(55, 3273.11, 6, "Failed", "2021/12/15 5:51:52"),
(56, 3398.9, 11, "Failed", "2021/11/27 0:10:8"),
(57, 3613.13, 5, "Failed", "2021/11/17 8:28:24"),
(58, 4445.92, 2, "Waiting for Date", "2021/11/22 7:33:39"),
(59, 685.39, 2, "Pending", "2021/11/28 17:22:49"),
(60, 539.23, 5, "Waiting for Date", "2021/12/28 2:1:12"),
(61, 7347.54, 9, "Succesful", "2021/12/01 14:25:46"),
(62, 8511.18, 12, "Failed", "2021/12/03 11:39:45"),
(63, 7793.87, 13, "Pending", "2021/12/07 7:39:9"),
(64, 6495.1, 1, "Failed", "2021/12/09 1:53:42"),
(65, 2866.27, 6, "Waiting for Date", "2021/11/16 19:48:29"),
(66, 2036.12, 5, "Succesful", "2021/12/02 1:17:19"),
(67, 3014.74, 6, "Pending", "2021/11/23 0:41:32"),
(68, 4183.05, 11, "Succesful", "2021/11/23 21:41:7"),
(69, 8831.15, 9, "Waiting for Date", "2022/01/01 18:21:44"),
(70, 7669.84, 5, "Waiting for Date", "2021/11/17 18:2:25"),
(71, 4198.47, 13, "Pending", "2021/11/15 2:37:7"),
(72, 3127.83, 8, "Succesful", "2021/11/19 22:38:35"),
(73, 6919.89, 12, "Pending", "2022/01/04 14:23:2"),
(74, 8342.59, 12, "Waiting for Date", "2021/12/13 19:27:47"),
(75, 4775.86, 9, "Succesful", "2021/11/21 16:41:40"),
(76, 5960.0, 9, "Succesful", "2022/01/14 7:31:54"),
(77, 7758.34, 1, "Failed", "2021/11/04 15:34:41"),
(78, 7288.67, 2, "Succesful", "2022/01/08 1:46:19"),
(79, 1213.61, 2, "Succesful", "2021/12/15 13:29:19"),
(80, 7793.57, 2, "Succesful", "2021/11/02 9:0:57"),
(81, 3754.64, 7, "Failed", "2021/11/09 0:42:14"),
(82, 8027.57, 11, "Succesful", "2022/01/03 12:18:2"),
(83, 7958.61, 8, "Failed", "2021/11/16 21:3:45"),
(84, 881.44, 9, "Waiting for Date", "2022/01/09 15:23:17"),
(85, 5714.55, 3, "Failed", "2021/11/12 19:50:1"),
(86, 9146.84, 9, "Waiting for Date", "2021/12/16 21:41:12"),
(87, 3190.34, 8, "Pending", "2021/11/16 9:53:22"),
(88, 7653.22, 3, "Failed", "2022/01/06 8:52:1"),
(89, 1503.58, 4, "Pending", "2021/12/20 3:48:2"),
(90, 6112.14, 6, "Waiting for Date", "2021/12/02 12:10:8"),
(91, 914.15, 12, "Waiting for Date", "2022/01/03 2:54:9"),
(92, 2691.21, 6, "Pending", "2021/12/01 21:29:29"),
(93, 4423.73, 3, "Succesful", "2021/12/22 4:19:55"),
(94, 6889.77, 3, "Failed", "2021/12/20 2:14:7"),
(95, 9018.45, 1, "Succesful", "2022/01/09 6:38:6"),
(96, 3392.25, 9, "Pending", "2021/12/02 1:11:30"),
(97, 2634.42, 8, "Waiting for Date", "2021/12/30 22:35:10"),
(98, 6548.01, 8, "Pending", "2021/12/25 13:50:19"),
(99, 5652.88, 4, "Waiting for Date", "2021/12/10 9:15:40"),
(100, 8714.15, 11, "Failed", "2021/12/24 5:45:7"),
(101, 4785.69, 11, "Succesful", "2021/12/08 22:50:13"),
(102, 224.51, 13, "Waiting for Date", "2021/12/26 6:34:30"),
(103, 8590.54, 7, "Waiting for Date", "2022/01/14 16:2:25"),
(104, 3040.03, 3, "Succesful", "2022/01/06 13:20:6"),
(105, 9811.19, 11, "Waiting for Date", "2021/12/15 3:49:57"),
(106, 2137.39, 11, "Pending", "2021/11/12 14:34:56"),
(107, 2522.96, 5, "Failed", "2021/12/13 16:50:59"),
(108, 8591.2, 2, "Waiting for Date", "2021/12/19 13:53:43"),
(109, 4713.36, 2, "Succesful", "2022/01/09 11:22:41"),
(110, 1974.66, 1, "Waiting for Date", "2022/01/10 4:40:43"),
(111, 9220.63, 9, "Succesful", "2021/11/22 22:52:42"),
(112, 9682.46, 7, "Waiting for Date", "2021/12/05 4:52:19"),
(113, 7132.29, 11, "Pending", "2021/11/12 19:49:10"),
(114, 8474.21, 13, "Failed", "2021/12/19 3:2:3"),
(115, 6027.96, 1, "Pending", "2021/12/16 1:29:46"),
(116, 9563.59, 3, "Failed", "2021/12/27 1:32:27"),
(117, 647.83, 1, "Waiting for Date", "2021/12/30 13:33:53"),
(118, 8734.76, 3, "Failed", "2021/12/13 14:44:34"),
(119, 83.76, 8, "Waiting for Date", "2021/11/02 14:39:51"),
(120, 6175.76, 10, "Failed", "2021/12/15 15:56:23"),
(121, 798.17, 3, "Pending", "2021/12/11 2:1:45"),
(122, 5383.82, 8, "Failed", "2021/11/15 19:19:47"),
(123, 5082.18, 3, "Waiting for Date", "2021/12/01 15:42:58"),
(124, 2291.66, 9, "Pending", "2021/12/16 22:23:31"),
(125, 3549.53, 1, "Pending", "2022/01/06 21:2:8"),
(126, 106.13, 5, "Waiting for Date", "2021/11/17 21:25:47"),
(127, 759.52, 1, "Pending", "2021/12/27 4:28:51"),
(128, 1678.82, 5, "Succesful", "2021/12/14 14:47:58"),
(129, 937.53, 8, "Pending", "2021/11/27 19:1:43"),
(130, 2916.89, 2, "Failed", "2021/12/06 2:41:3"),
(131, 5489.24, 4, "Failed", "2021/12/20 18:55:40"),
(132, 7955.36, 11, "Pending", "2021/12/05 17:49:53"),
(133, 4885.63, 9, "Waiting for Date", "2021/12/13 8:13:15"),
(134, 1179.78, 4, "Succesful", "2021/12/09 5:16:3"),
(135, 9712.84, 12, "Failed", "2021/12/12 13:40:54"),
(136, 4282.52, 9, "Pending", "2021/11/22 9:56:59"),
(137, 4638.45, 1, "Failed", "2021/12/21 21:46:50"),
(138, 6554.01, 4, "Succesful", "2021/12/07 16:48:18"),
(139, 3235.67, 3, "Pending", "2022/01/14 23:40:43"),
(140, 2331.11, 8, "Failed", "2021/11/09 17:31:9"),
(141, 8902.75, 13, "Waiting for Date", "2021/12/17 7:57:57"),
(142, 4697.97, 4, "Waiting for Date", "2022/01/02 7:8:25"),
(143, 2579.31, 6, "Failed", "2021/11/15 10:29:6"),
(144, 6724.07, 13, "Pending", "2021/12/26 3:36:33"),
(145, 9428.63, 2, "Waiting for Date", "2021/12/26 9:36:50"),
(146, 646.05, 3, "Waiting for Date", "2021/12/31 17:51:5"),
(147, 1669.82, 4, "Waiting for Date", "2021/11/11 10:34:3"),
(148, 8499.13, 4, "Succesful", "2021/11/27 2:30:55"),
(149, 4997.81, 12, "Succesful", "2021/11/12 18:45:9"),
(150, 5947.25, 8, "Failed", "2022/01/08 23:13:45"),
(151, 8032.81, 11, "Pending", "2021/11/01 15:23:32"),
(152, 9715.13, 5, "Failed", "2021/11/23 12:10:26"),
(153, 3389.85, 8, "Pending", "2021/11/30 23:10:31"),
(154, 7112.51, 12, "Succesful", "2022/01/12 22:16:58"),
(155, 8959.18, 4, "Waiting for Date", "2021/11/06 7:11:32"),
(156, 9677.8, 11, "Failed", "2021/11/12 8:27:8"),
(157, 3035.14, 5, "Failed", "2021/12/16 9:43:42"),
(158, 3961.69, 6, "Succesful", "2021/11/07 4:21:37"),
(159, 2930.38, 13, "Succesful", "2022/01/08 2:54:51"),
(160, 7010.22, 8, "Waiting for Date", "2022/01/14 2:30:55"),
(161, 4260.2, 5, "Succesful", "2021/11/25 2:13:36"),
(162, 2159.84, 11, "Succesful", "2021/12/11 4:26:16"),
(163, 2100.51, 8, "Pending", "2021/12/17 8:6:6"),
(164, 626.46, 3, "Failed", "2021/11/19 14:26:24"),
(165, 1458.33, 13, "Waiting for Date", "2021/11/27 13:36:57"),
(166, 8795.36, 3, "Pending", "2021/11/28 4:53:32"),
(167, 8291.1, 9, "Failed", "2021/12/22 13:29:43"),
(168, 2146.22, 4, "Failed", "2022/01/04 13:6:21"),
(169, 9769.97, 2, "Waiting for Date", "2021/12/21 5:21:34"),
(170, 4908.55, 4, "Waiting for Date", "2021/11/08 19:24:25"),
(171, 9935.05, 12, "Pending", "2021/11/18 6:12:11"),
(172, 9897.05, 8, "Waiting for Date", "2021/12/28 2:12:13"),
(173, 5913.33, 1, "Pending", "2021/11/11 6:2:29"),
(174, 185.19, 9, "Succesful", "2021/11/20 22:53:21"),
(175, 8914.74, 8, "Waiting for Date", "2021/11/16 21:5:17"),
(176, 1055.17, 7, "Waiting for Date", "2021/12/27 2:2:32"),
(177, 4271.78, 3, "Waiting for Date", "2021/12/25 0:56:50"),
(178, 7613.35, 13, "Failed", "2021/12/12 2:1:38"),
(179, 6006.44, 7, "Pending", "2022/01/05 0:3:14"),
(180, 30.6, 5, "Succesful", "2021/11/07 22:45:24"),
(181, 6252.14, 3, "Failed", "2022/01/15 12:47:36"),
(182, 8052.44, 2, "Pending", "2021/12/09 19:24:39"),
(183, 4449.29, 10, "Waiting for Date", "2021/11/18 7:0:5"),
(184, 2113.29, 9, "Pending", "2022/01/06 19:32:45"),
(185, 2482.17, 4, "Pending", "2021/12/11 14:13:52"),
(186, 7887.94, 12, "Succesful", "2021/12/08 0:53:55"),
(187, 1648.18, 9, "Succesful", "2021/12/06 15:9:49"),
(188, 5107.01, 11, "Failed", "2021/11/20 0:19:55"),
(189, 8347.55, 12, "Failed", "2021/11/18 17:46:40"),
(190, 8222.9, 13, "Pending", "2021/12/14 4:39:44"),
(191, 9788.94, 9, "Waiting for Date", "2021/12/03 11:19:50"),
(192, 2989.2, 4, "Pending", "2021/12/08 20:27:8"),
(193, 5161.38, 5, "Succesful", "2021/12/08 4:17:4"),
(194, 7291.16, 12, "Pending", "2022/01/04 21:35:9"),
(195, 225.99, 5, "Pending", "2022/01/14 16:50:14"),
(196, 2514.15, 10, "Failed", "2022/01/07 5:33:34"),
(197, 174.97, 9, "Pending", "2021/11/17 19:7:28"),
(198, 8825.17, 10, "Pending", "2021/12/10 2:3:54"),
(199, 3183.02, 3, "Pending", "2021/12/02 22:1:37"),
(200, 4771.42, 5, "Waiting for Date", "2021/11/04 8:9:22"),
(201, 9682.76, 12, "Succesful", "2021/11/22 5:22:16"),
(202, 3401.28, 2, "Failed", "2021/11/26 21:5:27"),
(203, 8145.86, 10, "Pending", "2022/01/04 13:43:54"),
(204, 783.12, 5, "Succesful", "2021/12/17 5:20:2"),
(205, 2715.36, 9, "Waiting for Date", "2021/11/05 6:14:5"),
(206, 8470.96, 9, "Succesful", "2021/11/20 14:14:49"),
(207, 7761.62, 4, "Succesful", "2021/11/23 23:31:46"),
(208, 2263.65, 8, "Waiting for Date", "2021/11/01 5:41:10"),
(209, 5481.56, 5, "Failed", "2021/11/13 15:11:23"),
(210, 9768.7, 3, "Waiting for Date", "2021/12/10 8:40:19"),
(211, 3086.5, 8, "Succesful", "2021/11/16 5:17:50"),
(212, 8238.14, 7, "Pending", "2021/11/28 16:36:15"),
(213, 4067.72, 9, "Waiting for Date", "2021/11/06 15:9:50"),
(214, 2817.14, 3, "Pending", "2021/11/22 19:38:28"),
(215, 2912.74, 13, "Pending", "2021/12/06 22:45:33"),
(216, 7192.6, 1, "Failed", "2021/12/01 14:23:2"),
(217, 2353.76, 10, "Succesful", "2021/11/18 18:38:20"),
(218, 5761.57, 8, "Succesful", "2021/12/18 21:0:47"),
(219, 6942.92, 12, "Waiting for Date", "2021/11/02 19:53:42"),
(220, 5212.02, 10, "Waiting for Date", "2021/12/21 16:10:38"),
(221, 3879.16, 5, "Failed", "2022/01/05 4:22:50"),
(222, 7195.18, 13, "Pending", "2021/11/02 1:27:31"),
(223, 8408.7, 10, "Waiting for Date", "2021/12/16 6:54:5"),
(224, 7352.43, 5, "Pending", "2021/11/18 4:4:34"),
(225, 2305.28, 9, "Pending", "2021/12/04 21:44:55"),
(226, 4182.22, 2, "Succesful", "2021/11/09 4:33:14"),
(227, 3131.15, 7, "Pending", "2021/12/08 13:37:0"),
(228, 1580.07, 8, "Pending", "2021/11/11 21:0:18"),
(229, 2160.2, 7, "Waiting for Date", "2022/01/05 3:26:26"),
(230, 3097.23, 1, "Pending", "2021/12/22 2:44:51"),
(231, 4208.87, 12, "Waiting for Date", "2021/12/16 7:48:36"),
(232, 8660.61, 4, "Pending", "2021/11/09 23:8:50"),
(233, 9758.54, 6, "Succesful", "2021/11/18 5:38:8"),
(234, 2029.17, 11, "Waiting for Date", "2022/01/02 14:38:28"),
(235, 9130.94, 10, "Failed", "2021/12/01 19:49:44"),
(236, 8843.03, 1, "Pending", "2021/12/19 5:51:7"),
(237, 3366.06, 3, "Waiting for Date", "2021/11/21 2:31:45"),
(238, 7984.6, 4, "Failed", "2021/11/15 0:20:55"),
(239, 3348.9, 11, "Succesful", "2021/12/14 16:31:25"),
(240, 1901.36, 3, "Waiting for Date", "2022/01/03 13:56:32"),
(241, 3553.79, 6, "Succesful", "2022/01/08 1:28:30"),
(242, 207.82, 7, "Failed", "2021/11/21 3:36:43"),
(243, 364.62, 5, "Waiting for Date", "2021/11/20 5:46:15"),
(244, 6401.24, 2, "Waiting for Date", "2022/01/06 21:48:32"),
(245, 9707.04, 9, "Failed", "2021/12/06 18:17:47"),
(246, 3957.85, 13, "Failed", "2022/01/12 4:45:27"),
(247, 2205.45, 2, "Failed", "2021/11/13 13:27:43"),
(248, 1012.76, 1, "Failed", "2021/11/27 23:8:11"),
(249, 4828.85, 1, "Pending", "2021/11/22 2:28:43"),
(250, 2591.15, 13, "Failed", "2021/12/03 2:38:30"),
(251, 5491.88, 6, "Succesful", "2021/12/15 12:50:24"),
(252, 8763.74, 11, "Pending", "2021/12/24 0:50:19"),
(253, 2950.04, 3, "Pending", "2021/12/23 8:17:19"),
(254, 5983.87, 8, "Succesful", "2021/11/02 20:36:23"),
(255, 1812.95, 7, "Succesful", "2021/12/02 20:6:49"),
(256, 880.43, 12, "Failed", "2021/11/13 0:3:31"),
(257, 3275.0, 4, "Failed", "2021/11/15 10:41:26"),
(258, 1417.96, 2, "Waiting for Date", "2021/12/31 5:33:1"),
(259, 1411.21, 9, "Succesful", "2021/11/10 15:49:19"),
(260, 7946.79, 6, "Failed", "2021/11/28 20:44:39"),
(261, 2699.29, 13, "Waiting for Date", "2021/12/14 15:49:44"),
(262, 6430.8, 8, "Waiting for Date", "2021/11/15 20:14:26"),
(263, 7852.37, 8, "Succesful", "2021/12/04 12:15:48"),
(264, 9582.2, 3, "Pending", "2021/12/25 7:4:15"),
(265, 9986.42, 5, "Waiting for Date", "2021/12/17 15:36:49"),
(266, 3089.68, 6, "Waiting for Date", "2021/12/11 1:40:59"),
(267, 8614.57, 9, "Failed", "2021/12/01 0:3:37"),
(268, 7699.42, 9, "Failed", "2021/12/17 16:45:21"),
(269, 9517.99, 6, "Waiting for Date", "2021/12/12 3:53:40"),
(270, 3563.79, 11, "Failed", "2021/12/13 20:50:30"),
(271, 1596.85, 11, "Waiting for Date", "2022/01/01 12:59:33"),
(272, 8616.12, 1, "Pending", "2021/11/10 16:20:18"),
(273, 2941.06, 5, "Succesful", "2022/01/01 4:8:29"),
(274, 5506.7, 6, "Succesful", "2021/11/12 18:5:57"),
(275, 3780.12, 3, "Waiting for Date", "2021/11/07 6:1:43"),
(276, 1532.67, 10, "Failed", "2022/01/09 7:10:36"),
(277, 5073.5, 7, "Pending", "2022/01/13 1:9:24"),
(278, 7440.28, 13, "Pending", "2021/11/20 3:4:38"),
(279, 484.09, 10, "Waiting for Date", "2021/12/25 21:41:11"),
(280, 6750.21, 5, "Failed", "2021/12/18 15:46:59"),
(281, 450.4, 7, "Waiting for Date", "2021/11/11 21:19:7"),
(282, 4305.27, 4, "Succesful", "2022/01/12 7:4:17"),
(283, 6994.51, 7, "Waiting for Date", "2021/11/16 13:13:54"),
(284, 2221.35, 6, "Waiting for Date", "2021/12/19 8:48:43"),
(285, 8921.18, 5, "Waiting for Date", "2021/11/22 14:29:6"),
(286, 1893.33, 3, "Succesful", "2022/01/15 9:28:51"),
(287, 5079.09, 1, "Waiting for Date", "2021/12/17 8:25:21"),
(288, 1665.98, 11, "Succesful", "2021/11/20 9:39:50"),
(289, 2744.31, 13, "Failed", "2021/12/25 9:24:54"),
(290, 5260.89, 13, "Failed", "2021/11/16 16:30:38"),
(291, 7727.92, 10, "Pending", "2021/11/30 2:17:9"),
(292, 7297.32, 8, "Succesful", "2022/01/13 19:36:22"),
(293, 6458.32, 12, "Failed", "2021/11/29 15:24:7"),
(294, 6896.43, 12, "Pending", "2021/12/11 15:59:26"),
(295, 7647.88, 11, "Failed", "2021/11/02 17:19:58"),
(296, 7873.21, 11, "Succesful", "2022/01/01 16:41:49"),
(297, 3580.02, 13, "Waiting for Date", "2021/11/20 14:31:53"),
(298, 5727.64, 6, "Waiting for Date", "2021/12/25 6:21:1"),
(299, 495.33, 7, "Pending", "2021/11/24 3:26:40"),
(300, 5883.82, 9, "Failed", "2021/12/10 22:16:48"),
(301, 649.42, 1, "Succesful", "2021/12/31 17:44:50"),
(302, 2042.26, 6, "Failed", "2021/12/26 11:56:14"),
(303, 6294.58, 10, "Waiting for Date", "2021/11/16 19:27:59"),
(304, 1984.36, 7, "Pending", "2022/01/08 2:28:32"),
(305, 7576.37, 4, "Waiting for Date", "2021/12/27 1:47:36"),
(306, 2960.25, 13, "Succesful", "2021/11/09 16:26:54"),
(307, 4573.74, 1, "Pending", "2021/12/24 11:51:12"),
(308, 485.42, 1, "Pending", "2021/12/13 7:46:19"),
(309, 8595.76, 1, "Failed", "2021/12/04 16:49:55"),
(310, 8181.01, 3, "Failed", "2021/11/07 8:57:16"),
(311, 6688.61, 3, "Succesful", "2021/11/11 5:15:18"),
(312, 3854.2, 11, "Succesful", "2021/11/16 9:11:4"),
(313, 3374.25, 2, "Succesful", "2021/11/12 22:34:3"),
(314, 7489.84, 6, "Pending", "2021/11/08 0:29:30"),
(315, 8210.27, 6, "Pending", "2022/01/14 15:24:22"),
(316, 2311.97, 1, "Waiting for Date", "2021/11/29 12:37:35"),
(317, 8863.06, 6, "Succesful", "2021/12/15 6:4:5"),
(318, 9105.45, 1, "Failed", "2021/12/18 9:31:42"),
(319, 8610.88, 5, "Waiting for Date", "2021/11/12 9:11:36"),
(320, 1836.81, 5, "Pending", "2021/11/28 16:32:52"),
(321, 3327.4, 9, "Succesful", "2022/01/08 4:8:24"),
(322, 8096.21, 12, "Succesful", "2021/12/31 5:13:54"),
(323, 5184.67, 4, "Pending", "2021/11/28 9:28:20"),
(324, 5913.35, 1, "Waiting for Date", "2021/12/27 11:32:10"),
(325, 1399.6, 7, "Succesful", "2022/01/07 6:28:40"),
(326, 8326.69, 1, "Succesful", "2021/11/23 9:52:28"),
(327, 6562.05, 12, "Failed", "2021/11/07 0:18:14"),
(328, 6494.8, 11, "Pending", "2022/01/01 0:46:8"),
(329, 959.79, 8, "Succesful", "2021/11/19 21:8:53"),
(330, 5613.08, 9, "Succesful", "2022/01/01 0:43:8"),
(331, 6137.94, 10, "Pending", "2021/12/19 20:19:38"),
(332, 9883.83, 11, "Pending", "2022/01/05 8:4:16"),
(333, 1458.65, 1, "Pending", "2022/01/04 10:49:56"),
(334, 6299.6, 4, "Failed", "2021/12/29 21:32:18"),
(335, 8197.24, 12, "Succesful", "2021/12/24 6:44:59"),
(336, 9976.71, 13, "Pending", "2022/01/12 13:19:2"),
(337, 7759.54, 8, "Waiting for Date", "2021/12/07 4:15:36"),
(338, 8376.03, 4, "Pending", "2021/11/20 2:54:21"),
(339, 6595.38, 7, "Waiting for Date", "2021/12/12 10:39:59"),
(340, 1134.37, 1, "Pending", "2021/12/14 5:19:0"),
(341, 5534.76, 11, "Pending", "2021/12/07 1:38:2"),
(342, 8773.12, 12, "Failed", "2021/12/12 11:28:56"),
(343, 1660.41, 1, "Pending", "2021/12/01 18:7:38"),
(344, 8345.13, 8, "Failed", "2021/12/31 2:32:31"),
(345, 6423.3, 3, "Waiting for Date", "2022/01/13 16:47:42"),
(346, 6283.29, 2, "Pending", "2021/12/03 14:1:15"),
(347, 4994.34, 10, "Failed", "2021/11/15 13:20:1"),
(348, 6686.65, 1, "Failed", "2021/12/03 23:21:57"),
(349, 2152.96, 13, "Waiting for Date", "2021/11/15 10:58:22"),
(350, 6050.57, 5, "Succesful", "2022/01/04 19:15:13"),
(351, 401.7, 6, "Succesful", "2021/11/03 1:31:8"),
(352, 6267.82, 6, "Pending", "2022/01/07 15:54:5"),
(353, 8102.52, 4, "Succesful", "2022/01/06 21:24:11"),
(354, 94.55, 9, "Failed", "2022/01/09 18:3:36"),
(355, 3390.24, 1, "Waiting for Date", "2021/11/12 11:59:4"),
(356, 8787.5, 9, "Waiting for Date", "2021/11/14 13:24:13"),
(357, 1278.53, 6, "Failed", "2021/12/23 16:6:24"),
(358, 6501.85, 6, "Pending", "2021/12/14 6:6:28"),
(359, 8009.05, 8, "Pending", "2021/11/12 3:17:44"),
(360, 6704.23, 2, "Succesful", "2021/12/08 4:10:29"),
(361, 5981.44, 4, "Failed", "2021/11/06 8:39:44"),
(362, 5428.46, 5, "Waiting for Date", "2022/01/11 15:19:48"),
(363, 642.54, 7, "Failed", "2021/12/04 5:30:11"),
(364, 5101.06, 11, "Pending", "2021/12/11 10:47:30"),
(365, 4233.0, 7, "Failed", "2021/11/28 7:33:16"),
(366, 2280.37, 2, "Failed", "2021/12/27 9:43:55"),
(367, 6367.28, 6, "Waiting for Date", "2022/01/04 16:48:45"),
(368, 838.3, 10, "Waiting for Date", "2022/01/10 7:39:21"),
(369, 6646.94, 5, "Succesful", "2021/12/18 6:15:4"),
(370, 3400.49, 13, "Succesful", "2021/11/25 1:15:55"),
(371, 9603.96, 12, "Waiting for Date", "2022/01/02 16:56:39"),
(372, 4636.97, 8, "Failed", "2021/12/02 17:50:0"),
(373, 382.47, 6, "Waiting for Date", "2021/11/24 2:24:40"),
(374, 9079.09, 1, "Waiting for Date", "2021/11/24 3:56:10"),
(375, 6064.36, 1, "Failed", "2021/12/13 20:42:1"),
(376, 4814.24, 6, "Pending", "2021/12/26 10:27:13"),
(377, 1731.38, 13, "Waiting for Date", "2021/11/03 10:37:30"),
(378, 4911.72, 7, "Failed", "2021/11/25 14:35:50"),
(379, 5298.53, 6, "Waiting for Date", "2021/12/21 23:47:50"),
(380, 9106.08, 4, "Failed", "2021/12/19 17:28:44"),
(381, 6190.73, 2, "Waiting for Date", "2022/01/14 8:13:56"),
(382, 984.57, 12, "Waiting for Date", "2021/11/08 5:45:39"),
(383, 5511.96, 6, "Waiting for Date", "2021/11/02 15:21:21"),
(384, 9562.61, 13, "Failed", "2022/01/11 18:53:30"),
(385, 4982.54, 1, "Failed", "2021/12/29 7:56:26"),
(386, 5886.04, 4, "Succesful", "2021/12/20 16:57:17"),
(387, 8713.37, 3, "Pending", "2021/12/29 10:18:57"),
(388, 7151.32, 3, "Pending", "2022/01/13 0:45:52"),
(389, 1209.09, 10, "Pending", "2021/12/31 6:22:49"),
(390, 6699.51, 5, "Waiting for Date", "2021/12/04 3:19:9"),
(391, 3805.95, 12, "Waiting for Date", "2021/12/16 15:30:10"),
(392, 3179.87, 5, "Failed", "2021/12/11 5:33:22"),
(393, 1096.9, 4, "Waiting for Date", "2021/12/04 15:29:19"),
(394, 7658.33, 10, "Waiting for Date", "2021/12/27 15:19:22"),
(395, 1422.77, 7, "Failed", "2022/01/06 22:21:50"),
(396, 4806.75, 12, "Pending", "2021/12/19 15:34:46"),
(397, 5390.43, 1, "Waiting for Date", "2021/11/04 22:31:26"),
(398, 7663.51, 7, "Failed", "2022/01/11 11:37:33"),
(399, 4028.76, 7, "Succesful", "2021/11/08 3:30:16"),
(400, 56.66, 4, "Succesful", "2021/11/09 4:47:51"),
(401, 3113.84, 3, "Failed", "2022/01/09 23:10:50"),
(402, 5843.05, 6, "Waiting for Date", "2021/12/17 10:55:53"),
(403, 3470.88, 1, "Succesful", "2021/11/12 5:0:27"),
(404, 9372.52, 6, "Waiting for Date", "2021/12/26 6:36:49"),
(405, 6931.88, 9, "Waiting for Date", "2021/12/31 6:12:50"),
(406, 1520.75, 13, "Pending", "2021/11/14 20:3:43"),
(407, 7482.54, 6, "Pending", "2021/11/22 7:55:41"),
(408, 6539.67, 5, "Pending", "2022/01/12 20:44:32"),
(409, 2463.48, 12, "Pending", "2021/12/23 12:27:34"),
(410, 7067.24, 11, "Waiting for Date", "2021/11/02 17:44:39"),
(411, 3442.7, 11, "Pending", "2021/12/19 16:47:35"),
(412, 4532.88, 3, "Succesful", "2021/11/29 5:56:13"),
(413, 924.57, 13, "Failed", "2022/01/13 10:20:15"),
(414, 5094.51, 12, "Waiting for Date", "2021/11/21 2:3:27"),
(415, 5100.33, 13, "Failed", "2021/12/01 11:48:5"),
(416, 2130.51, 1, "Failed", "2021/11/05 4:1:0"),
(417, 3765.03, 8, "Failed", "2021/11/04 15:6:11"),
(418, 1212.24, 8, "Pending", "2021/11/07 21:50:28"),
(419, 9737.14, 9, "Succesful", "2021/11/04 2:53:54"),
(420, 783.19, 2, "Pending", "2021/11/26 4:37:29"),
(421, 5173.4, 13, "Failed", "2021/12/02 23:49:15"),
(422, 3887.3, 3, "Failed", "2022/01/12 1:45:1"),
(423, 9374.97, 7, "Failed", "2022/01/11 22:36:1"),
(424, 7241.72, 5, "Waiting for Date", "2021/12/05 21:24:51"),
(425, 7113.97, 4, "Succesful", "2021/11/29 6:28:44"),
(426, 704.66, 8, "Failed", "2021/12/05 8:48:0"),
(427, 4201.87, 9, "Waiting for Date", "2021/11/17 20:15:26"),
(428, 739.73, 9, "Failed", "2021/12/15 11:44:4"),
(429, 8074.25, 4, "Succesful", "2021/11/25 20:26:37"),
(430, 5614.0, 11, "Waiting for Date", "2021/11/30 12:11:43"),
(431, 3782.68, 9, "Waiting for Date", "2021/11/04 15:52:36"),
(432, 5581.06, 10, "Pending", "2021/11/24 13:32:28"),
(433, 2021.42, 9, "Failed", "2021/11/24 3:23:31"),
(434, 1478.95, 1, "Failed", "2021/11/14 15:28:3"),
(435, 8020.82, 11, "Waiting for Date", "2022/01/06 4:7:30"),
(436, 8287.91, 10, "Waiting for Date", "2021/12/03 2:39:7"),
(437, 4766.18, 10, "Succesful", "2022/01/10 18:25:41"),
(438, 1690.94, 9, "Pending", "2022/01/07 2:23:59"),
(439, 4339.79, 10, "Pending", "2022/01/05 5:16:19"),
(440, 1049.22, 9, "Failed", "2021/11/09 14:53:41"),
(441, 8530.8, 11, "Pending", "2021/12/03 22:42:25"),
(442, 6747.4, 4, "Succesful", "2021/11/16 11:38:25"),
(443, 9035.88, 9, "Waiting for Date", "2021/12/03 20:43:4"),
(444, 285.01, 3, "Pending", "2021/12/24 7:30:0"),
(445, 8068.29, 2, "Succesful", "2021/12/02 23:49:19"),
(446, 8649.8, 5, "Waiting for Date", "2021/11/04 13:16:9"),
(447, 9388.47, 10, "Pending", "2021/12/23 22:34:6"),
(448, 2266.94, 6, "Pending", "2022/01/07 22:58:37"),
(449, 128.49, 5, "Waiting for Date", "2021/11/12 4:41:58"),
(450, 9321.42, 6, "Pending", "2021/11/09 22:34:49"),
(451, 9818.79, 4, "Failed", "2022/01/09 3:46:44"),
(452, 7111.86, 2, "Succesful", "2022/01/10 20:51:25"),
(453, 5523.2, 8, "Failed", "2022/01/12 8:9:45"),
(454, 9142.96, 13, "Pending", "2022/01/10 21:48:2"),
(455, 597.25, 7, "Pending", "2021/11/07 18:2:19"),
(456, 5938.58, 4, "Pending", "2021/11/20 5:53:12"),
(457, 3946.6, 4, "Waiting for Date", "2021/12/06 11:15:18"),
(458, 9022.7, 4, "Succesful", "2021/11/22 23:50:28"),
(459, 3206.78, 6, "Waiting for Date", "2021/11/08 14:41:13"),
(460, 4377.17, 4, "Pending", "2021/11/01 22:4:13"),
(461, 5500.37, 8, "Waiting for Date", "2022/01/02 11:57:44"),
(462, 5410.02, 1, "Failed", "2021/12/29 3:24:26"),
(463, 3031.56, 3, "Pending", "2021/11/07 13:16:5"),
(464, 1402.85, 11, "Pending", "2021/12/07 23:38:55"),
(465, 778.67, 3, "Pending", "2021/12/12 3:57:6"),
(466, 7282.7, 8, "Pending", "2022/01/04 17:25:49"),
(467, 854.41, 12, "Waiting for Date", "2021/11/19 13:6:20"),
(468, 958.5, 4, "Pending", "2021/12/29 3:55:28"),
(469, 3854.37, 13, "Succesful", "2021/11/15 17:26:9"),
(470, 2014.75, 1, "Waiting for Date", "2022/01/15 12:15:38"),
(471, 8247.1, 1, "Pending", "2021/11/11 15:54:34"),
(472, 9929.25, 11, "Failed", "2021/11/11 2:42:20"),
(473, 4351.98, 3, "Succesful", "2021/11/02 10:17:53"),
(474, 8259.91, 6, "Succesful", "2021/11/02 20:25:44"),
(475, 5995.93, 11, "Pending", "2021/12/28 6:18:41"),
(476, 3801.99, 9, "Succesful", "2021/11/10 2:18:18"),
(477, 4991.54, 2, "Failed", "2021/12/06 14:6:14"),
(478, 6809.75, 5, "Waiting for Date", "2021/11/17 23:49:16"),
(479, 4684.9, 12, "Waiting for Date", "2021/11/16 4:49:49"),
(480, 1240.18, 10, "Pending", "2022/01/11 16:1:5"),
(481, 6212.46, 3, "Succesful", "2021/11/24 17:10:50"),
(482, 8956.58, 3, "Pending", "2021/12/01 14:51:10"),
(483, 6225.18, 5, "Waiting for Date", "2021/12/15 22:34:17"),
(484, 5230.77, 11, "Failed", "2021/12/28 0:39:9"),
(485, 7348.71, 4, "Pending", "2021/12/10 17:51:39"),
(486, 3660.7, 8, "Failed", "2021/11/04 7:38:30"),
(487, 5098.97, 3, "Pending", "2021/11/08 23:23:11"),
(488, 414.84, 1, "Failed", "2021/11/14 3:31:15"),
(489, 2979.42, 9, "Waiting for Date", "2021/12/31 20:14:8");

INSERT INTO `local_bargain` (`bargain_ID`, `sender_account_number`,	`receiver_account_number`) VALUES
(245, 24, 10),
(246, 18, 26),
(247, 21, 8),
(248, 28, 13),
(249, 31, 32),
(250, 29, 28),
(251, 11, 27),
(252, 18, 10),
(253, 10, 18),
(254, 16, 17),
(255, 18, 29),
(256, 20, 10),
(257, 24, 31),
(258, 16, 23),
(259, 13, 21),
(260, 13, 27),
(261, 8, 2),
(262, 11, 13),
(263, 2, 27),
(264, 24, 11),
(265, 10, 23),
(266, 11, 3),
(267, 32, 27),
(268, 18, 20),
(269, 27, 29),
(270, 23, 2),
(271, 17, 13),
(272, 2, 3),
(273, 31, 23),
(274, 13, 27),
(275, 31, 8),
(276, 32, 21),
(277, 26, 29),
(278, 10, 14),
(279, 2, 26),
(280, 26, 20),
(281, 21, 2),
(282, 23, 11),
(283, 17, 14),
(284, 11, 28),
(285, 26, 8),
(286, 28, 21),
(287, 21, 13),
(288, 31, 3),
(289, 24, 21),
(290, 20, 8),
(291, 18, 28),
(292, 28, 16),
(293, 14, 2),
(294, 17, 29),
(295, 14, 17),
(296, 18, 23),
(297, 17, 27),
(298, 21, 2),
(299, 8, 23),
(300, 8, 3),
(301, 11, 24),
(302, 31, 24),
(303, 24, 17),
(304, 26, 32),
(305, 3, 29),
(306, 21, 28),
(307, 8, 18),
(308, 11, 18),
(309, 17, 3),
(310, 31, 28),
(311, 18, 17),
(312, 16, 21),
(313, 11, 24),
(314, 28, 2),
(315, 28, 14),
(316, 11, 13),
(317, 29, 16),
(318, 28, 10),
(319, 16, 27),
(320, 23, 2),
(321, 29, 17),
(322, 11, 21),
(323, 17, 18),
(324, 18, 17),
(325, 3, 20),
(326, 8, 3),
(327, 10, 13),
(328, 21, 24),
(329, 13, 10),
(330, 24, 8),
(331, 32, 27),
(332, 8, 13),
(333, 17, 26),
(334, 26, 29),
(335, 20, 23),
(336, 24, 20),
(337, 31, 23),
(338, 29, 18),
(339, 26, 32),
(340, 21, 11),
(341, 28, 11),
(342, 32, 23),
(343, 11, 13),
(344, 18, 8),
(345, 17, 26),
(346, 20, 3),
(347, 27, 11),
(348, 23, 31),
(349, 16, 17),
(350, 32, 8),
(351, 14, 27),
(352, 13, 31),
(353, 32, 11),
(354, 8, 20),
(355, 26, 10),
(356, 31, 17),
(357, 13, 8),
(358, 14, 8),
(359, 31, 17),
(360, 29, 16),
(361, 10, 16),
(362, 21, 3),
(363, 28, 13),
(364, 10, 32),
(365, 24, 16),
(366, 13, 20),
(367, 20, 18),
(368, 11, 14),
(369, 31, 26),
(370, 27, 2),
(371, 31, 32),
(372, 29, 14),
(373, 26, 3),
(374, 31, 27),
(375, 17, 10),
(376, 8, 11),
(377, 13, 32),
(378, 24, 28),
(379, 21, 16),
(380, 11, 29),
(381, 16, 32),
(382, 21, 3),
(383, 29, 24),
(384, 28, 10),
(385, 24, 17),
(386, 26, 8),
(387, 2, 3),
(388, 8, 13),
(389, 17, 23),
(390, 24, 8),
(391, 23, 2),
(392, 14, 24),
(393, 32, 2),
(394, 3, 2),
(395, 2, 26),
(396, 20, 23),
(397, 23, 16),
(398, 24, 16),
(399, 16, 10),
(400, 13, 27),
(401, 27, 8),
(402, 31, 3),
(403, 29, 14),
(404, 24, 26),
(405, 8, 10),
(406, 23, 31),
(407, 3, 26),
(408, 16, 14),
(409, 13, 24),
(410, 18, 3),
(411, 16, 26),
(412, 29, 24),
(413, 10, 23),
(414, 20, 28),
(415, 26, 16),
(416, 31, 2),
(417, 24, 29),
(418, 13, 23),
(419, 16, 21),
(420, 29, 2),
(421, 24, 32),
(422, 26, 11),
(423, 20, 32),
(424, 24, 3),
(425, 3, 26),
(426, 23, 21),
(427, 8, 18),
(428, 32, 20),
(429, 20, 18),
(430, 17, 31),
(431, 32, 28),
(432, 3, 14),
(433, 8, 3),
(434, 17, 27),
(435, 2, 3),
(436, 26, 13),
(437, 32, 29),
(438, 8, 16),
(439, 13, 32),
(440, 18, 26),
(441, 21, 18),
(442, 13, 23),
(443, 16, 28),
(444, 13, 10),
(445, 14, 17),
(446, 13, 8),
(447, 29, 18),
(448, 3, 21),
(449, 3, 10),
(450, 31, 32),
(451, 23, 11),
(452, 3, 24),
(453, 32, 2),
(454, 8, 18),
(455, 13, 24),
(456, 21, 20),
(457, 28, 11),
(458, 10, 2),
(459, 31, 16),
(460, 8, 13),
(461, 31, 11),
(462, 18, 16),
(463, 29, 18),
(464, 23, 8),
(465, 8, 32),
(466, 18, 2),
(467, 17, 11),
(468, 32, 24),
(469, 3, 11),
(470, 29, 27),
(471, 2, 3),
(472, 17, 3),
(473, 3, 2),
(474, 27, 21),
(475, 11, 10),
(476, 32, 26),
(477, 23, 8),
(478, 3, 27),
(479, 26, 16),
(480, 31, 3),
(481, 24, 8),
(482, 20, 28),
(483, 18, 21),
(484, 10, 23),
(485, 16, 27),
(486, 14, 20),
(487, 3, 18),
(488, 23, 28),
(489, 2, 28);

INSERT INTO `international_bargain` (`bargain_ID`, `sender_IBAN`, `receiver_IBAN`) VALUES
(1, "GB0228189000000000000003", "GB0228189000000000000031"),
(2, "GB0228189000000000000002", "GB0228189000000000000032"),
(3, "GB0228189000000000000024", "GB0228189000000000000029"),
(4, "GB0228189000000000000024", "GB0228189000000000000031"),
(5, "GB0228189000000000000027", "GB0228189000000000000026"),
(6, "GB0228189000000000000002", "GB0228189000000000000017"),
(7, "GB0228189000000000000024", "GB0228189000000000000028"),
(8, "GB0228189000000000000029", "GB0228189000000000000014"),
(9, "GB0228189000000000000021", "GB0228189000000000000010"),
(10, "GB0228189000000000000032", "GB0228189000000000000014"),
(11, "GB0228189000000000000002", "GB0228189000000000000014"),
(12, "GB0228189000000000000021", "GB0228189000000000000010"),
(13, "GB0228189000000000000021", "GB0228189000000000000017"),
(14, "GB0228189000000000000002", "GB0228189000000000000021"),
(15, "GB0228189000000000000016", "GB0228189000000000000017"),
(16, "GB0228189000000000000029", "GB0228189000000000000026"),
(17, "GB0228189000000000000014", "GB0228189000000000000010"),
(18, "GB0228189000000000000002", "GB0228189000000000000017"),
(19, "GB0228189000000000000008", "GB0228189000000000000026"),
(20, "GB0228189000000000000003", "GB0228189000000000000021"),
(21, "GB0228189000000000000027", "GB0228189000000000000026"),
(22, "GB0228189000000000000032", "GB0228189000000000000003"),
(23, "GB0228189000000000000024", "GB0228189000000000000026"),
(24, "GB0228189000000000000032", "GB0228189000000000000018"),
(25, "GB0228189000000000000010", "GB0228189000000000000031"),
(26, "GB0228189000000000000008", "GB0228189000000000000018"),
(27, "GB0228189000000000000021", "GB0228189000000000000024"),
(28, "GB0228189000000000000010", "GB0228189000000000000016"),
(29, "GB0228189000000000000002", "GB0228189000000000000008"),
(30, "GB0228189000000000000024", "GB0228189000000000000023"),
(31, "GB0228189000000000000018", "GB0228189000000000000016"),
(32, "GB0228189000000000000021", "GB0228189000000000000016"),
(33, "GB0228189000000000000024", "GB0228189000000000000013"),
(34, "GB0228189000000000000027", "GB0228189000000000000002"),
(35, "GB0228189000000000000029", "GB0228189000000000000023"),
(36, "GB0228189000000000000024", "GB0228189000000000000017"),
(37, "GB0228189000000000000031", "GB0228189000000000000008"),
(38, "GB0228189000000000000020", "GB0228189000000000000032"),
(39, "GB0228189000000000000024", "GB0228189000000000000013"),
(40, "GB0228189000000000000003", "GB0228189000000000000024"),
(41, "GB0228189000000000000014", "GB0228189000000000000024"),
(42, "GB0228189000000000000031", "GB0228189000000000000011"),
(43, "GB0228189000000000000027", "GB0228189000000000000008"),
(44, "GB0228189000000000000017", "GB0228189000000000000010"),
(45, "GB0228189000000000000017", "GB0228189000000000000013"),
(46, "GB0228189000000000000031", "GB0228189000000000000018"),
(47, "GB0228189000000000000013", "GB0228189000000000000016"),
(48, "GB0228189000000000000011", "GB0228189000000000000029"),
(49, "GB0228189000000000000016", "GB0228189000000000000014"),
(50, "GB0228189000000000000010", "GB0228189000000000000017"),
(51, "GB0228189000000000000002", "GB0228189000000000000014"),
(52, "GB0228189000000000000020", "GB0228189000000000000023"),
(53, "GB0228189000000000000027", "GB0228189000000000000032"),
(54, "GB0228189000000000000026", "GB0228189000000000000029"),
(55, "GB0228189000000000000003", "GB0228189000000000000018"),
(56, "GB0228189000000000000002", "GB0228189000000000000026"),
(57, "GB0228189000000000000024", "GB0228189000000000000028"),
(58, "GB0228189000000000000027", "GB0228189000000000000008"),
(59, "GB0228189000000000000013", "GB0228189000000000000014"),
(60, "GB0228189000000000000032", "GB0228189000000000000008"),
(61, "GB0228189000000000000024", "GB0228189000000000000029"),
(62, "GB0228189000000000000011", "GB0228189000000000000024"),
(63, "GB0228189000000000000027", "GB0228189000000000000002"),
(64, "GB0228189000000000000014", "GB0228189000000000000021"),
(65, "GB0228189000000000000008", "GB0228189000000000000027"),
(66, "GB0228189000000000000018", "GB0228189000000000000031"),
(67, "GB0228189000000000000031", "GB0228189000000000000026"),
(68, "GB0228189000000000000026", "GB0228189000000000000020"),
(69, "GB0228189000000000000027", "GB0228189000000000000021"),
(70, "GB0228189000000000000011", "GB0228189000000000000020"),
(71, "GB0228189000000000000003", "GB0228189000000000000016"),
(72, "GB0228189000000000000029", "GB0228189000000000000032"),
(73, "GB0228189000000000000017", "GB0228189000000000000031"),
(74, "GB0228189000000000000014", "GB0228189000000000000010"),
(75, "GB0228189000000000000013", "GB0228189000000000000017"),
(76, "GB0228189000000000000021", "GB0228189000000000000029"),
(77, "GB0228189000000000000029", "GB0228189000000000000016"),
(78, "GB0228189000000000000003", "GB0228189000000000000011"),
(79, "GB0228189000000000000010", "GB0228189000000000000021"),
(80, "GB0228189000000000000008", "GB0228189000000000000013"),
(81, "GB0228189000000000000008", "GB0228189000000000000010"),
(82, "GB0228189000000000000031", "GB0228189000000000000013"),
(83, "GB0228189000000000000002", "GB0228189000000000000027"),
(84, "GB0228189000000000000003", "GB0228189000000000000021"),
(85, "GB0228189000000000000014", "GB0228189000000000000028"),
(86, "GB0228189000000000000013", "GB0228189000000000000018"),
(87, "GB0228189000000000000020", "GB0228189000000000000016"),
(88, "GB0228189000000000000010", "GB0228189000000000000002"),
(89, "GB0228189000000000000021", "GB0228189000000000000024"),
(90, "GB0228189000000000000002", "GB0228189000000000000003"),
(91, "GB0228189000000000000020", "GB0228189000000000000028"),
(92, "GB0228189000000000000003", "GB0228189000000000000014"),
(93, "GB0228189000000000000032", "GB0228189000000000000018"),
(94, "GB0228189000000000000024", "GB0228189000000000000026"),
(95, "GB0228189000000000000032", "GB0228189000000000000010"),
(96, "GB0228189000000000000024", "GB0228189000000000000010"),
(97, "GB0228189000000000000013", "GB0228189000000000000017"),
(98, "GB0228189000000000000018", "GB0228189000000000000029"),
(99, "GB0228189000000000000024", "GB0228189000000000000031"),
(100, "GB0228189000000000000018", "GB0228189000000000000003"),
(101, "GB0228189000000000000013", "GB0228189000000000000028"),
(102, "GB0228189000000000000021", "GB0228189000000000000017"),
(103, "GB0228189000000000000011", "GB0228189000000000000018"),
(104, "GB0228189000000000000010", "GB0228189000000000000013"),
(105, "GB0228189000000000000002", "GB0228189000000000000020"),
(106, "GB0228189000000000000024", "GB0228189000000000000020"),
(107, "GB0228189000000000000017", "GB0228189000000000000008"),
(108, "GB0228189000000000000010", "GB0228189000000000000014"),
(109, "GB0228189000000000000020", "GB0228189000000000000032"),
(110, "GB0228189000000000000018", "GB0228189000000000000017"),
(111, "GB0228189000000000000029", "GB0228189000000000000017"),
(112, "GB0228189000000000000013", "GB0228189000000000000008"),
(113, "GB0228189000000000000027", "GB0228189000000000000026"),
(114, "GB0228189000000000000014", "GB0228189000000000000029"),
(115, "GB0228189000000000000027", "GB0228189000000000000013"),
(116, "GB0228189000000000000003", "GB0228189000000000000018"),
(117, "GB0228189000000000000021", "GB0228189000000000000002"),
(118, "GB0228189000000000000013", "GB0228189000000000000021"),
(119, "GB0228189000000000000020", "GB0228189000000000000023"),
(120, "GB0228189000000000000032", "GB0228189000000000000014"),
(121, "GB0228189000000000000020", "GB0228189000000000000021"),
(122, "GB0228189000000000000028", "GB0228189000000000000029"),
(123, "GB0228189000000000000031", "GB0228189000000000000029"),
(124, "GB0228189000000000000031", "GB0228189000000000000027"),
(125, "GB0228189000000000000008", "GB0228189000000000000011"),
(126, "GB0228189000000000000002", "GB0228189000000000000013"),
(127, "GB0228189000000000000023", "GB0228189000000000000013"),
(128, "GB0228189000000000000013", "GB0228189000000000000020"),
(129, "GB0228189000000000000032", "GB0228189000000000000014"),
(130, "GB0228189000000000000026", "GB0228189000000000000021"),
(131, "GB0228189000000000000014", "GB0228189000000000000028"),
(132, "GB0228189000000000000027", "GB0228189000000000000017"),
(133, "GB0228189000000000000028", "GB0228189000000000000016"),
(134, "GB0228189000000000000020", "GB0228189000000000000032"),
(135, "GB0228189000000000000002", "GB0228189000000000000014"),
(136, "GB0228189000000000000023", "GB0228189000000000000029"),
(137, "GB0228189000000000000027", "GB0228189000000000000013"),
(138, "GB0228189000000000000011", "GB0228189000000000000013"),
(139, "GB0228189000000000000010", "GB0228189000000000000026"),
(140, "GB0228189000000000000032", "GB0228189000000000000027"),
(141, "GB0228189000000000000018", "GB0228189000000000000017"),
(142, "GB0228189000000000000031", "GB0228189000000000000018"),
(143, "GB0228189000000000000024", "GB0228189000000000000029"),
(144, "GB0228189000000000000031", "GB0228189000000000000011"),
(145, "GB0228189000000000000011", "GB0228189000000000000021"),
(146, "GB0228189000000000000016", "GB0228189000000000000020"),
(147, "GB0228189000000000000027", "GB0228189000000000000032"),
(148, "GB0228189000000000000010", "GB0228189000000000000023"),
(149, "GB0228189000000000000023", "GB0228189000000000000008"),
(150, "GB0228189000000000000024", "GB0228189000000000000008"),
(151, "GB0228189000000000000016", "GB0228189000000000000027"),
(152, "GB0228189000000000000011", "GB0228189000000000000031"),
(153, "GB0228189000000000000014", "GB0228189000000000000008"),
(154, "GB0228189000000000000031", "GB0228189000000000000003"),
(155, "GB0228189000000000000003", "GB0228189000000000000018"),
(156, "GB0228189000000000000024", "GB0228189000000000000031"),
(157, "GB0228189000000000000008", "GB0228189000000000000024"),
(158, "GB0228189000000000000028", "GB0228189000000000000027"),
(159, "GB0228189000000000000017", "GB0228189000000000000003"),
(160, "GB0228189000000000000031", "GB0228189000000000000014"),
(161, "GB0228189000000000000013", "GB0228189000000000000003"),
(162, "GB0228189000000000000003", "GB0228189000000000000031"),
(163, "GB0228189000000000000010", "GB0228189000000000000026"),
(164, "GB0228189000000000000016", "GB0228189000000000000021"),
(165, "GB0228189000000000000008", "GB0228189000000000000016"),
(166, "GB0228189000000000000026", "GB0228189000000000000021"),
(167, "GB0228189000000000000029", "GB0228189000000000000003"),
(168, "GB0228189000000000000023", "GB0228189000000000000021"),
(169, "GB0228189000000000000027", "GB0228189000000000000013"),
(170, "GB0228189000000000000031", "GB0228189000000000000008"),
(171, "GB0228189000000000000020", "GB0228189000000000000002"),
(172, "GB0228189000000000000008", "GB0228189000000000000018"),
(173, "GB0228189000000000000023", "GB0228189000000000000027"),
(174, "GB0228189000000000000028", "GB0228189000000000000003"),
(175, "GB0228189000000000000008", "GB0228189000000000000024"),
(176, "GB0228189000000000000031", "GB0228189000000000000020"),
(177, "GB0228189000000000000021", "GB0228189000000000000018"),
(178, "GB0228189000000000000017", "GB0228189000000000000016"),
(179, "GB0228189000000000000027", "GB0228189000000000000011"),
(180, "GB0228189000000000000028", "GB0228189000000000000002"),
(181, "GB0228189000000000000014", "GB0228189000000000000008"),
(182, "GB0228189000000000000017", "GB0228189000000000000003"),
(183, "GB0228189000000000000031", "GB0228189000000000000029"),
(184, "GB0228189000000000000013", "GB0228189000000000000026"),
(185, "GB0228189000000000000018", "GB0228189000000000000003"),
(186, "GB0228189000000000000018", "GB0228189000000000000002"),
(187, "GB0228189000000000000010", "GB0228189000000000000028"),
(188, "GB0228189000000000000029", "GB0228189000000000000010"),
(189, "GB0228189000000000000032", "GB0228189000000000000014"),
(190, "GB0228189000000000000014", "GB0228189000000000000011"),
(191, "GB0228189000000000000018", "GB0228189000000000000002"),
(192, "GB0228189000000000000032", "GB0228189000000000000023"),
(193, "GB0228189000000000000032", "GB0228189000000000000031"),
(194, "GB0228189000000000000024", "GB0228189000000000000031"),
(195, "GB0228189000000000000003", "GB0228189000000000000023"),
(196, "GB0228189000000000000002", "GB0228189000000000000017"),
(197, "GB0228189000000000000013", "GB0228189000000000000021"),
(198, "GB0228189000000000000017", "GB0228189000000000000016"),
(199, "GB0228189000000000000002", "GB0228189000000000000008"),
(200, "GB0228189000000000000024", "GB0228189000000000000020"),
(201, "GB0228189000000000000028", "GB0228189000000000000002"),
(202, "GB0228189000000000000008", "GB0228189000000000000032"),
(203, "GB0228189000000000000023", "GB0228189000000000000018"),
(204, "GB0228189000000000000029", "GB0228189000000000000013"),
(205, "GB0228189000000000000023", "GB0228189000000000000016"),
(206, "GB0228189000000000000010", "GB0228189000000000000028"),
(207, "GB0228189000000000000010", "GB0228189000000000000021"),
(208, "GB0228189000000000000029", "GB0228189000000000000027"),
(209, "GB0228189000000000000010", "GB0228189000000000000024"),
(210, "GB0228189000000000000029", "GB0228189000000000000017"),
(211, "GB0228189000000000000011", "GB0228189000000000000013"),
(212, "GB0228189000000000000024", "GB0228189000000000000029"),
(213, "GB0228189000000000000029", "GB0228189000000000000028"),
(214, "GB0228189000000000000027", "GB0228189000000000000003"),
(215, "GB0228189000000000000032", "GB0228189000000000000011"),
(216, "GB0228189000000000000011", "GB0228189000000000000008"),
(217, "GB0228189000000000000013", "GB0228189000000000000032"),
(218, "GB0228189000000000000020", "GB0228189000000000000003"),
(219, "GB0228189000000000000003", "GB0228189000000000000017"),
(220, "GB0228189000000000000010", "GB0228189000000000000016"),
(221, "GB0228189000000000000011", "GB0228189000000000000023"),
(222, "GB0228189000000000000032", "GB0228189000000000000011"),
(223, "GB0228189000000000000026", "GB0228189000000000000021"),
(224, "GB0228189000000000000013", "GB0228189000000000000002"),
(225, "GB0228189000000000000024", "GB0228189000000000000020"),
(226, "GB0228189000000000000013", "GB0228189000000000000027"),
(227, "GB0228189000000000000020", "GB0228189000000000000021"),
(228, "GB0228189000000000000010", "GB0228189000000000000024"),
(229, "GB0228189000000000000027", "GB0228189000000000000003"),
(230, "GB0228189000000000000020", "GB0228189000000000000003"),
(231, "GB0228189000000000000028", "GB0228189000000000000029"),
(232, "GB0228189000000000000027", "GB0228189000000000000020"),
(233, "GB0228189000000000000029", "GB0228189000000000000028"),
(234, "GB0228189000000000000026", "GB0228189000000000000027"),
(235, "GB0228189000000000000023", "GB0228189000000000000011"),
(236, "GB0228189000000000000020", "GB0228189000000000000010"),
(237, "GB0228189000000000000021", "GB0228189000000000000020"),
(238, "GB0228189000000000000017", "GB0228189000000000000028"),
(239, "GB0228189000000000000027", "GB0228189000000000000010"),
(240, "GB0228189000000000000026", "GB0228189000000000000032"),
(241, "GB0228189000000000000028", "GB0228189000000000000029"),
(242, "GB0228189000000000000013", "GB0228189000000000000031"),
(243, "GB0228189000000000000031", "GB0228189000000000000003"),
(244, "GB0228189000000000000014", "GB0228189000000000000013");

INSERT INTO `outgoing_bargain` (`bargain_ID`, `planned_date`) VALUES
(1, "2021/11/25 21:10:27"),
(2, "2021/11/24 15:57:43"),
(3, "2022/06/05 19:45:42"),
(4, "2022/09/22 9:58:18"),
(5, "2021/11/08 12:20:52"),
(6, "2021/11/25 16:17:54"),
(7, "2021/11/05 22:41:45"),
(8, "2021/11/02 3:27:41"),
(9, "2021/11/16 3:7:39"),
(10, "2021/11/25 17:5:16"),
(11, "2021/11/25 21:31:23"),
(12, "2021/11/09 23:3:8"),
(13, "2021/11/25 17:38:28"),
(14, "2021/11/22 7:47:15"),
(15, "2021/11/20 21:1:51"),
(16, "2021/11/25 11:26:3"),
(17, "2021/11/13 8:12:53"),
(18, "2022/12/12 6:14:17"),
(19, "2021/11/18 9:36:50"),
(20, "2021/11/25 2:38:25"),
(21, "2021/11/25 15:53:29"),
(22, "2021/11/12 19:47:21"),
(23, "2022/01/31 15:6:35"),
(24, "2021/11/04 15:51:56"),
(25, "2021/11/25 11:59:34"),
(26, "2021/11/19 0:13:31"),
(27, "2021/11/15 10:36:38"),
(28, "2021/11/25 12:5:31"),
(29, "2022/09/23 13:29:38"),
(30, "2021/11/25 23:44:34"),
(31, "2022/12/21 17:18:17"),
(32, "2021/11/09 8:41:46"),
(33, "2021/11/17 13:41:25"),
(34, "2021/11/25 2:31:40"),
(35, "2021/11/25 19:5:36"),
(36, "2021/11/12 19:10:55"),
(37, "2022/03/22 2:49:31"),
(38, "2021/11/17 15:19:15"),
(39, "2022/09/02 22:36:19"),
(40, "2021/11/25 21:47:6"),
(41, "2021/11/07 6:22:38"),
(42, "2022/03/29 22:19:22"),
(43, "2021/11/25 1:42:23"),
(44, "2021/11/15 12:5:38"),
(45, "2021/11/25 3:46:43"),
(46, "2021/11/21 11:12:40"),
(47, "2021/11/25 3:19:10"),
(48, "2021/11/25 3:57:13"),
(49, "2021/11/25 20:52:3"),
(50, "2022/11/14 9:26:17"),
(51, "2021/11/19 16:32:18"),
(52, "2021/11/25 16:32:53"),
(53, "2021/11/15 15:1:36"),
(54, "2022/05/24 16:39:58"),
(55, "2021/11/03 9:27:12"),
(56, "2021/11/07 21:56:51"),
(57, "2021/11/19 22:53:15"),
(58, "2022/06/01 16:31:14"),
(59, "2021/11/25 12:13:14"),
(60, "2022/02/03 21:53:11"),
(61, "2021/11/17 10:21:42"),
(62, "2021/11/08 8:49:27"),
(63, "2021/11/25 3:13:7"),
(64, "2021/11/09 1:15:22"),
(65, "2022/04/02 5:55:11"),
(66, "2021/11/14 8:46:59"),
(67, "2021/11/25 9:40:29"),
(68, "2021/11/19 15:13:3"),
(69, "2022/11/05 4:23:11"),
(70, "2022/11/28 12:14:45"),
(71, "2021/11/25 20:51:46"),
(72, "2021/11/14 14:18:40"),
(73, "2021/11/25 15:54:26"),
(74, "2022/11/19 2:25:52"),
(75, "2021/11/14 5:40:36"),
(76, "2021/11/22 13:0:41"),
(77, "2021/11/23 15:35:13"),
(78, "2021/11/13 19:43:42"),
(79, "2021/11/24 5:45:47"),
(80, "2021/11/20 17:29:52"),
(81, "2021/11/15 3:51:58"),
(82, "2021/11/20 2:53:14"),
(83, "2021/11/08 1:9:8"),
(84, "2022/09/17 0:47:27"),
(85, "2021/11/12 23:17:51"),
(86, "2022/11/17 3:39:44"),
(87, "2021/11/25 22:57:32"),
(88, "2021/11/10 9:45:19"),
(89, "2021/11/25 5:8:36"),
(90, "2022/06/22 9:53:1"),
(91, "2022/09/19 7:31:26"),
(92, "2021/11/25 2:59:55"),
(93, "2021/11/22 0:53:1"),
(94, "2021/11/08 23:25:40"),
(95, "2021/11/24 16:48:29"),
(96, "2021/11/25 4:49:4"),
(97, "2022/09/23 12:5:4"),
(98, "2021/11/25 0:24:44"),
(99, "2022/02/01 11:41:47"),
(100, "2021/11/03 9:24:36"),
(101, "2021/11/14 3:5:4"),
(102, "2022/07/06 16:54:56"),
(103, "2022/02/23 10:28:39"),
(104, "2021/11/18 14:24:59"),
(105, "2022/12/12 11:28:19"),
(106, "2021/11/25 4:44:58"),
(107, "2021/11/10 10:29:3"),
(108, "2022/07/25 12:19:41"),
(109, "2021/11/16 6:7:51"),
(110, "2022/12/14 2:55:24"),
(111, "2021/11/10 18:52:32"),
(112, "2022/07/13 14:40:58"),
(113, "2021/11/25 8:52:56"),
(114, "2021/11/08 3:12:55"),
(115, "2021/11/25 4:14:21"),
(116, "2021/11/01 7:21:26"),
(117, "2022/01/23 17:7:24"),
(118, "2021/11/09 18:37:9"),
(119, "2022/07/17 4:51:39"),
(120, "2021/11/11 4:57:16"),
(121, "2021/11/25 19:17:49"),
(122, "2021/11/11 15:49:24"),
(123, "2022/10/14 12:46:8"),
(124, "2021/11/25 10:38:29"),
(125, "2021/11/25 3:57:58"),
(126, "2022/02/24 2:26:28"),
(127, "2021/11/25 9:26:36"),
(128, "2021/11/12 0:34:58"),
(129, "2021/11/25 21:49:24"),
(130, "2021/11/06 8:4:16"),
(131, "2021/11/15 8:58:51"),
(132, "2021/11/25 15:52:16"),
(133, "2022/12/10 22:34:28"),
(134, "2021/11/23 12:14:46"),
(135, "2021/11/17 17:17:4"),
(136, "2021/11/25 11:35:8"),
(137, "2021/11/20 23:43:57"),
(138, "2021/11/12 10:8:48"),
(139, "2021/11/25 20:19:51"),
(140, "2021/11/08 13:35:12"),
(141, "2022/05/10 11:8:28"),
(142, "2022/11/10 19:50:52"),
(143, "2021/11/25 0:0:25"),
(144, "2021/11/25 10:13:33"),
(145, "2022/07/14 6:44:54"),
(146, "2022/10/05 6:1:9"),
(147, "2022/08/13 9:41:29"),
(148, "2021/11/04 20:25:43"),
(149, "2021/11/21 20:4:53"),
(150, "2021/11/22 17:49:54"),
(151, "2021/11/25 16:27:2"),
(152, "2021/11/06 13:55:26"),
(153, "2021/11/25 6:32:10"),
(154, "2021/11/14 12:0:16"),
(155, "2022/09/07 23:48:12"),
(156, "2021/11/01 23:40:0"),
(157, "2021/11/22 21:46:9"),
(158, "2021/11/16 9:11:37"),
(159, "2021/11/03 4:33:0"),
(160, "2022/10/16 11:25:10"),
(161, "2021/11/17 10:5:4"),
(162, "2021/11/09 23:56:31"),
(163, "2021/11/25 1:34:9"),
(164, "2021/11/20 12:11:36"),
(165, "2022/07/25 0:48:33"),
(166, "2021/11/25 15:21:47"),
(167, "2021/11/16 14:1:44"),
(168, "2021/11/10 7:1:51"),
(169, "2022/08/11 3:24:21"),
(170, "2022/01/23 11:14:23"),
(171, "2021/11/25 23:52:40"),
(172, "2022/11/05 4:4:10"),
(173, "2021/11/25 6:23:22"),
(174, "2021/11/16 14:12:26"),
(175, "2022/12/03 7:58:29"),
(176, "2022/01/22 5:45:54"),
(177, "2022/07/23 7:26:5"),
(178, "2021/11/12 6:37:24"),
(179, "2021/11/25 13:43:55"),
(180, "2021/11/19 16:10:43"),
(181, "2021/11/24 2:9:56"),
(182, "2021/11/25 3:41:10"),
(183, "2022/06/04 7:32:19"),
(184, "2021/11/25 12:20:53"),
(185, "2021/11/25 15:42:48"),
(186, "2021/11/14 17:56:34"),
(187, "2021/11/24 16:43:12"),
(188, "2021/11/15 20:41:25"),
(189, "2021/11/02 14:16:57"),
(190, "2021/11/25 10:47:31"),
(191, "2022/10/26 2:24:24"),
(192, "2021/11/25 21:21:56"),
(193, "2021/11/19 10:4:41"),
(194, "2021/11/25 9:36:47"),
(195, "2021/11/25 7:20:44"),
(196, "2021/11/02 23:35:52"),
(197, "2021/11/25 5:3:45"),
(198, "2021/11/25 2:56:26"),
(199, "2021/11/25 20:2:43"),
(200, "2022/10/09 14:4:54"),
(201, "2021/11/23 3:11:41"),
(202, "2021/11/06 11:45:31"),
(203, "2021/11/25 20:54:33"),
(204, "2021/11/25 22:22:22"),
(205, "2022/10/30 22:18:18"),
(206, "2021/11/13 8:6:47"),
(207, "2021/11/08 9:40:45"),
(208, "2022/10/29 15:2:1"),
(209, "2021/11/19 22:24:25"),
(210, "2022/11/07 13:24:39"),
(211, "2021/11/19 5:7:48"),
(212, "2021/11/25 21:53:23"),
(213, "2022/02/11 18:59:15"),
(214, "2021/11/25 2:50:7"),
(215, "2021/11/25 23:47:58"),
(216, "2021/11/03 13:26:48"),
(217, "2021/11/14 13:37:55"),
(218, "2021/11/03 22:21:49"),
(219, "2022/10/31 22:15:54"),
(220, "2022/07/13 10:2:46"),
(221, "2021/11/22 17:36:28"),
(222, "2021/11/25 18:29:19"),
(223, "2022/03/24 15:35:22"),
(224, "2021/11/25 4:6:43"),
(225, "2021/11/25 6:9:35"),
(226, "2021/11/20 12:40:35"),
(227, "2021/11/25 17:30:50"),
(228, "2021/11/25 22:10:59"),
(229, "2022/07/03 11:20:2"),
(230, "2021/11/25 23:29:48"),
(231, "2022/10/02 6:28:4"),
(232, "2021/11/25 18:35:21"),
(233, "2021/11/14 8:46:44"),
(234, "2022/03/20 18:20:22"),
(235, "2021/11/18 22:40:24"),
(236, "2021/11/25 18:1:4"),
(237, "2022/07/09 12:43:10"),
(238, "2021/11/09 9:48:46"),
(239, "2021/11/25 18:28:5"),
(240, "2022/10/26 18:17:37"),
(241, "2021/11/17 11:3:9"),
(242, "2021/11/10 23:59:40"),
(243, "2022/08/29 16:44:17"),
(244, "2022/08/06 19:7:53"),
(245, "2021/11/18 8:35:9"),
(246, "2021/11/02 8:54:56"),
(247, "2021/11/12 9:11:3"),
(248, "2021/11/07 15:43:31"),
(249, "2021/11/25 8:56:42"),
(250, "2021/11/18 2:34:2"),
(251, "2021/11/07 16:16:59"),
(252, "2021/11/25 11:30:43"),
(253, "2021/11/25 16:31:43"),
(254, "2021/11/24 9:47:9"),
(255, "2021/11/12 19:56:29"),
(256, "2021/11/19 17:16:33"),
(257, "2021/11/16 2:52:33"),
(258, "2022/09/11 6:54:16"),
(259, "2021/11/19 21:5:44"),
(260, "2021/11/19 18:21:3"),
(261, "2022/11/10 23:36:3"),
(262, "2022/06/08 21:26:30"),
(263, "2021/11/05 14:4:4"),
(264, "2021/11/25 12:33:14"),
(265, "2022/03/18 6:59:10"),
(266, "2022/09/21 15:34:38"),
(267, "2021/11/17 18:19:19"),
(268, "2021/11/18 0:16:35"),
(269, "2022/11/28 6:23:43"),
(270, "2021/11/20 7:49:49"),
(271, "2022/04/28 2:5:39"),
(272, "2021/11/25 13:9:20"),
(273, "2021/11/18 8:38:57"),
(274, "2021/11/19 13:9:53"),
(275, "2022/12/18 0:55:35"),
(276, "2021/11/03 15:13:31"),
(277, "2021/11/25 22:7:7"),
(278, "2021/11/25 9:50:8"),
(279, "2022/04/05 18:23:22"),
(280, "2021/11/14 11:10:38"),
(281, "2022/10/21 9:26:52"),
(282, "2021/11/15 5:50:29"),
(283, "2022/04/26 15:37:14"),
(284, "2022/03/19 11:9:24"),
(285, "2022/06/20 22:52:49"),
(286, "2021/11/01 22:21:32"),
(287, "2022/08/16 12:51:23"),
(288, "2021/11/13 13:57:41"),
(289, "2021/11/24 14:55:47"),
(290, "2021/11/25 4:3:12"),
(291, "2021/11/25 7:51:14"),
(292, "2021/11/05 15:3:4"),
(293, "2021/11/04 10:17:22"),
(294, "2021/11/25 8:1:27"),
(295, "2021/11/10 17:15:48"),
(296, "2021/11/14 7:31:23"),
(297, "2022/02/26 9:12:56"),
(298, "2022/11/30 2:9:21"),
(299, "2021/11/25 21:6:11"),
(300, "2021/11/12 13:57:22"),
(301, "2021/11/07 2:20:41"),
(302, "2021/11/01 19:28:42"),
(303, "2022/10/29 14:23:45"),
(304, "2021/11/25 4:31:18"),
(305, "2022/12/21 0:13:8"),
(306, "2021/11/21 7:25:10"),
(307, "2021/11/25 12:6:6"),
(308, "2021/11/25 10:18:54"),
(309, "2021/11/01 1:18:28"),
(310, "2021/11/17 18:57:28"),
(311, "2021/11/15 16:5:50"),
(312, "2021/11/07 9:31:34"),
(313, "2021/11/09 8:54:16"),
(314, "2021/11/25 1:36:7"),
(315, "2021/11/25 6:47:39"),
(316, "2022/02/20 9:13:3"),
(317, "2021/11/15 20:6:36"),
(318, "2021/11/03 3:15:3"),
(319, "2022/11/26 17:30:39"),
(320, "2021/11/25 1:50:26"),
(321, "2021/11/07 20:16:11"),
(322, "2021/11/25 3:1:27"),
(323, "2021/11/25 23:13:21"),
(324, "2022/04/15 8:37:28"),
(325, "2021/11/07 1:19:47"),
(326, "2021/11/06 10:44:0"),
(327, "2021/11/06 8:45:43"),
(328, "2021/11/25 2:47:24"),
(329, "2021/11/06 13:38:46"),
(330, "2021/11/09 16:19:18"),
(331, "2021/11/25 23:36:45"),
(332, "2021/11/25 21:21:2"),
(333, "2021/11/25 16:45:26"),
(334, "2021/11/06 20:46:54"),
(335, "2021/11/11 0:10:2"),
(336, "2021/11/25 8:32:11"),
(337, "2022/03/23 8:15:31"),
(338, "2021/11/25 0:18:28"),
(339, "2022/09/17 15:3:14"),
(340, "2021/11/25 0:10:3"),
(341, "2021/11/25 22:45:38"),
(342, "2021/11/22 5:16:32"),
(343, "2021/11/25 4:38:52"),
(344, "2021/11/11 22:56:42"),
(345, "2022/02/09 6:23:21"),
(346, "2021/11/25 15:49:30"),
(347, "2021/11/12 2:14:15"),
(348, "2021/11/15 12:12:32"),
(349, "2022/11/23 0:43:50"),
(350, "2021/11/11 7:57:3"),
(351, "2021/11/10 11:16:17"),
(352, "2021/11/25 1:47:57"),
(353, "2021/11/24 0:19:10"),
(354, "2021/11/23 5:5:55"),
(355, "2022/04/22 8:46:36"),
(356, "2022/05/16 22:36:45"),
(357, "2021/11/10 15:28:42"),
(358, "2021/11/25 3:11:22"),
(359, "2021/11/25 4:28:49"),
(360, "2021/11/19 8:4:58"),
(361, "2021/11/17 22:35:14"),
(362, "2022/07/24 19:13:37"),
(363, "2021/11/24 10:36:51"),
(364, "2021/11/25 22:28:37"),
(365, "2021/11/12 18:15:34"),
(366, "2021/11/13 21:30:20"),
(367, "2022/08/03 7:56:27"),
(368, "2022/07/20 8:13:7"),
(369, "2021/11/10 14:48:53"),
(370, "2021/11/04 7:44:44"),
(371, "2023/01/08 0:12:11"),
(372, "2021/11/19 19:53:10"),
(373, "2022/05/29 19:41:57"),
(374, "2022/10/28 2:44:43"),
(375, "2021/11/09 12:21:58"),
(376, "2021/11/25 14:52:48"),
(377, "2022/10/23 7:2:51"),
(378, "2021/11/07 6:57:48"),
(379, "2023/01/08 22:53:47"),
(380, "2021/11/01 2:30:11"),
(381, "2022/05/24 11:6:3"),
(382, "2022/02/02 6:11:34"),
(383, "2022/08/25 5:5:30"),
(384, "2021/11/17 7:4:37"),
(385, "2021/11/25 13:53:39"),
(386, "2021/11/06 19:37:8"),
(387, "2021/11/25 19:20:58"),
(388, "2021/11/25 17:27:1"),
(389, "2021/11/25 5:23:46"),
(390, "2022/02/17 20:41:20"),
(391, "2022/08/04 13:23:0"),
(392, "2021/11/23 14:26:22"),
(393, "2022/02/26 22:14:48"),
(394, "2022/07/18 22:33:45"),
(395, "2021/11/03 23:57:46"),
(396, "2021/11/25 7:29:23"),
(397, "2022/05/11 6:18:2"),
(398, "2021/11/22 7:52:59"),
(399, "2021/11/05 12:53:57"),
(400, "2021/11/06 7:8:34"),
(401, "2021/11/09 15:34:36"),
(402, "2022/10/24 23:27:54"),
(403, "2021/11/01 15:42:10"),
(404, "2022/11/25 4:57:25"),
(405, "2022/11/15 11:20:58"),
(406, "2021/11/25 10:38:55"),
(407, "2021/11/25 8:38:17"),
(408, "2021/11/25 22:2:25"),
(409, "2021/11/25 20:29:58"),
(410, "2022/03/22 15:20:22"),
(411, "2021/11/25 14:50:34"),
(412, "2021/11/04 13:17:58"),
(413, "2021/11/02 7:53:21"),
(414, "2022/01/19 8:14:34"),
(415, "2021/11/13 2:54:24"),
(416, "2021/11/04 9:50:45"),
(417, "2021/11/01 21:38:45"),
(418, "2021/11/25 6:23:4"),
(419, "2021/11/17 0:42:59"),
(420, "2021/11/25 15:32:0"),
(421, "2021/11/07 5:40:55"),
(422, "2021/11/20 11:35:15"),
(423, "2021/11/12 8:57:35"),
(424, "2022/03/01 20:36:8"),
(425, "2021/11/19 7:37:50"),
(426, "2021/11/15 2:24:59"),
(427, "2022/03/27 6:40:9"),
(428, "2021/11/19 23:14:32"),
(429, "2021/11/11 3:58:59"),
(430, "2022/04/03 10:50:50"),
(431, "2022/12/17 15:45:1"),
(432, "2021/11/25 3:4:36"),
(433, "2021/11/09 10:40:59"),
(434, "2021/11/24 1:53:28"),
(435, "2022/11/27 5:50:7"),
(436, "2022/06/24 16:16:4"),
(437, "2021/11/03 4:31:40"),
(438, "2021/11/25 10:45:5"),
(439, "2021/11/25 0:31:16"),
(440, "2021/11/16 5:23:55"),
(441, "2021/11/25 4:56:10"),
(442, "2021/11/12 22:17:12"),
(443, "2022/11/02 5:44:2"),
(444, "2021/11/25 3:53:53"),
(445, "2021/11/19 13:53:3"),
(446, "2022/01/17 22:22:48"),
(447, "2021/11/25 9:8:17"),
(448, "2021/11/25 15:40:21"),
(449, "2022/01/27 8:57:54"),
(450, "2021/11/25 15:47:59"),
(451, "2021/11/15 20:1:47"),
(452, "2021/11/10 9:30:7"),
(453, "2021/11/22 12:22:54"),
(454, "2021/11/25 17:27:19"),
(455, "2021/11/25 15:55:7"),
(456, "2021/11/25 6:30:17"),
(457, "2022/04/18 18:36:45"),
(458, "2021/11/08 8:8:2"),
(459, "2022/11/06 13:13:32"),
(460, "2021/11/25 7:8:44"),
(461, "2022/04/01 2:14:46"),
(462, "2021/11/19 7:5:25"),
(463, "2021/11/25 16:59:1"),
(464, "2021/11/25 2:5:54"),
(465, "2021/11/25 14:2:10"),
(466, "2021/11/25 8:32:8"),
(467, "2022/09/01 14:15:36"),
(468, "2021/11/25 19:14:4"),
(469, "2021/11/20 5:22:58"),
(470, "2022/02/14 23:38:10"),
(471, "2021/11/25 21:57:22"),
(472, "2021/11/12 9:31:54"),
(473, "2021/11/16 13:41:28"),
(474, "2021/11/01 0:12:44"),
(475, "2021/11/25 21:0:3"),
(476, "2021/11/02 12:11:44"),
(477, "2021/11/13 7:35:12"),
(478, "2022/03/12 14:3:2"),
(479, "2022/11/21 15:2:0"),
(480, "2021/11/25 23:48:9"),
(481, "2021/11/15 4:1:34"),
(482, "2021/11/25 23:51:11"),
(483, "2022/10/18 18:57:37"),
(484, "2021/11/10 3:4:33"),
(485, "2021/11/25 16:20:1"),
(486, "2021/11/20 5:5:10"),
(487, "2021/11/25 3:48:49"),
(488, "2021/11/11 0:56:49"),
(489, "2022/05/25 15:33:29");

INSERT INTO `incoming_bargain` (`bargain_ID`, `receipt_date`) VALUES
(5, "2021/11/07 0:1:17"),
(8, "2021/11/08 14:55:1"),
(14, "2021/11/16 5:19:7"),
(15, "2021/11/01 5:17:41"),
(24, "2021/11/05 9:3:34"),
(26, "2021/11/23 0:24:2"),
(27, "2021/11/10 17:12:17"),
(32, "2021/11/07 3:28:42"),
(33, "2021/11/05 1:3:34"),
(53, "2021/11/24 6:18:41"),
(61, "2021/11/25 21:2:26"),
(66, "2021/11/20 16:25:28"),
(68, "2021/11/01 16:35:34"),
(72, "2021/11/22 16:59:51"),
(75, "2021/11/18 17:12:59"),
(76, "2021/11/16 16:36:57"),
(78, "2021/11/05 9:12:29"),
(79, "2021/11/17 13:48:8"),
(80, "2021/11/08 18:35:17"),
(82, "2021/11/19 7:56:11"),
(93, "2021/11/11 8:36:25"),
(95, "2021/11/02 11:50:43"),
(101, "2021/11/03 8:38:40"),
(104, "2021/11/01 19:57:48"),
(109, "2021/11/02 16:39:12"),
(111, "2021/11/18 6:56:38"),
(128, "2021/11/16 10:22:14"),
(134, "2021/11/10 11:54:39"),
(138, "2021/11/25 15:38:15"),
(148, "2021/11/19 22:7:27"),
(149, "2021/11/17 10:38:15"),
(154, "2021/11/11 2:19:28"),
(158, "2021/11/16 2:35:2"),
(159, "2021/11/02 11:1:17"),
(161, "2021/11/14 6:44:58"),
(162, "2021/11/04 22:16:34"),
(174, "2021/11/13 9:58:7"),
(180, "2021/11/10 1:9:30"),
(186, "2021/11/24 14:36:41"),
(187, "2021/11/12 0:50:59"),
(193, "2021/11/07 2:39:22"),
(201, "2021/11/03 13:7:25"),
(204, "2021/11/16 23:49:7"),
(206, "2021/11/09 5:18:44"),
(207, "2021/11/08 14:2:43"),
(211, "2021/11/22 11:55:42"),
(217, "2021/11/10 14:36:37"),
(218, "2021/11/08 20:40:18"),
(226, "2021/11/13 20:43:41"),
(233, "2021/11/01 2:15:14"),
(239, "2021/11/22 1:14:38"),
(241, "2021/11/21 20:56:11"),
(251, "2021/11/18 5:49:48"),
(254, "2021/11/15 10:46:56"),
(255, "2021/11/23 17:53:16"),
(259, "2021/11/08 3:40:22"),
(263, "2021/11/25 2:52:39"),
(273, "2021/11/18 9:21:39"),
(274, "2021/11/15 22:10:58"),
(282, "2021/11/13 4:13:47"),
(286, "2021/11/07 14:59:10"),
(288, "2021/11/18 13:15:22"),
(292, "2021/11/08 17:4:34"),
(296, "2021/11/25 19:45:56"),
(301, "2021/11/11 13:12:3"),
(306, "2021/11/15 21:53:52"),
(311, "2021/11/20 12:9:41"),
(312, "2021/11/15 12:11:17"),
(313, "2021/11/14 3:28:14"),
(317, "2021/11/09 2:49:44"),
(321, "2021/11/14 18:14:13"),
(322, "2021/11/22 16:11:14"),
(325, "2021/11/10 16:42:18"),
(326, "2021/11/06 2:40:30"),
(329, "2021/11/18 4:24:5"),
(330, "2021/11/10 0:39:36"),
(335, "2021/11/04 15:32:59"),
(350, "2021/11/15 11:58:12"),
(351, "2021/11/13 0:4:20"),
(353, "2021/11/21 13:18:30"),
(360, "2021/11/04 6:24:55"),
(369, "2021/11/11 20:20:48"),
(370, "2021/11/12 5:29:48"),
(386, "2021/11/05 16:20:16"),
(399, "2021/11/09 20:27:4"),
(400, "2021/11/10 14:46:4"),
(403, "2021/11/02 12:0:47"),
(412, "2021/11/04 0:58:2"),
(419, "2021/11/22 2:2:40"),
(425, "2021/11/05 1:7:15"),
(429, "2021/11/04 21:16:50"),
(437, "2021/11/18 6:48:14"),
(442, "2021/11/21 7:16:22"),
(445, "2021/11/11 13:29:21"),
(452, "2021/11/19 22:37:20"),
(458, "2021/11/22 16:40:22"),
(469, "2021/11/08 19:23:37"),
(473, "2021/11/12 8:56:12"),
(474, "2021/11/21 12:46:2"),
(476, "2021/11/01 11:43:9"),
(481, "2021/11/03 18:39:52");

INSERT INTO `account_stock` (`account_number`, `stock_code`, `shares`) VALUES
(2, "AAPL", 55),
(2, "GOOG", 823),
(2, "MSFT", 873),
(2, "FB", 433),
(2, "AMZN", 899),
(2, "TWTR", 530),
(2, "NFLX", 818),
(2, "TSLA", 845),
(2, "BABA", 924),
(3, "AAPL", 724),
(3, "GOOG", 813),
(3, "MSFT", 702),
(3, "FB", 93),
(3, "AMZN", 251),
(3, "TWTR", 594),
(3, "NFLX", 403),
(3, "TSLA", 281),
(3, "BABA", 779),
(3, "NVDA", 580),
(3, "AMD", 894),
(3, "INTC", 540),
(3, "CSCO", 223),
(3, "ADBE", 982),
(8, "AAPL", 231),
(8, "GOOG", 893),
(8, "MSFT", 231),
(8, "FB", 280),
(8, "AMZN", 804),
(8, "TWTR", 32),
(8, "NFLX", 43),
(8, "TSLA", 908),
(10, "AAPL", 853),
(11, "AAPL", 267),
(11, "GOOG", 741),
(13, "AAPL", 384),
(13, "GOOG", 22),
(13, "MSFT", 853),
(13, "FB", 308),
(14, "AAPL", 929),
(14, "GOOG", 512),
(14, "MSFT", 338),
(14, "FB", 992),
(14, "AMZN", 555),
(14, "TWTR", 801),
(14, "NFLX", 8),
(16, "AAPL", 298),
(16, "GOOG", 527),
(16, "MSFT", 323),
(16, "FB", 538),
(16, "AMZN", 900),
(16, "TWTR", 643),
(16, "NFLX", 301),
(16, "TSLA", 148),
(16, "BABA", 282),
(16, "NVDA", 626),
(17, "AAPL", 716),
(17, "GOOG", 748),
(17, "MSFT", 534),
(17, "FB", 144),
(17, "AMZN", 262),
(17, "TWTR", 607),
(17, "NFLX", 960),
(17, "TSLA", 521),
(17, "BABA", 336),
(18, "AAPL", 386),
(18, "GOOG", 723),
(18, "MSFT", 578),
(18, "FB", 279),
(18, "AMZN", 115),
(18, "TWTR", 501),
(18, "NFLX", 612),
(18, "TSLA", 376),
(18, "BABA", 774),
(18, "NVDA", 278),
(18, "AMD", 777),
(18, "INTC", 817),
(18, "CSCO", 636),
(20, "AAPL", 409),
(20, "GOOG", 230),
(20, "MSFT", 532),
(20, "FB", 904),
(20, "AMZN", 460),
(20, "TWTR", 908),
(20, "NFLX", 173),
(20, "TSLA", 618),
(20, "BABA", 232),
(20, "NVDA", 164),
(20, "AMD", 927),
(20, "INTC", 414),
(20, "CSCO", 727),
(20, "ADBE", 963),
(21, "AAPL", 641),
(21, "GOOG", 351),
(21, "MSFT", 196),
(21, "FB", 608),
(21, "AMZN", 139),
(21, "TWTR", 598),
(21, "NFLX", 663),
(21, "TSLA", 841),
(21, "BABA", 632),
(23, "AAPL", 606),
(24, "AAPL", 302),
(24, "GOOG", 880),
(24, "MSFT", 153),
(24, "FB", 401),
(24, "AMZN", 534),
(26, "AAPL", 3),
(26, "GOOG", 159),
(26, "MSFT", 142),
(26, "FB", 527),
(26, "AMZN", 112),
(26, "TWTR", 235),
(27, "AAPL", 893),
(28, "AAPL", 613),
(28, "GOOG", 652),
(28, "MSFT", 299),
(28, "FB", 830),
(28, "AMZN", 92),
(28, "TWTR", 934),
(29, "AAPL", 752),
(29, "GOOG", 477),
(29, "MSFT", 395),
(29, "FB", 828),
(29, "AMZN", 652),
(29, "TWTR", 727),
(29, "NFLX", 318),
(29, "TSLA", 979),
(29, "BABA", 671),
(29, "NVDA", 806),
(29, "AMD", 401),
(29, "INTC", 503),
(31, "AAPL", 82),
(31, "GOOG", 673),
(31, "MSFT", 815),
(31, "FB", 317),
(31, "AMZN", 984),
(31, "TWTR", 884),
(31, "NFLX", 511),
(31, "TSLA", 407),
(31, "BABA", 434),
(31, "NVDA", 951),
(32, "AAPL", 275),
(32, "GOOG", 422),
(32, "MSFT", 982),
(32, "FB", 4),
(32, "AMZN", 78),
(32, "TWTR", 696),
(32, "NFLX", 218),
(32, "TSLA", 405),
(32, "BABA", 668);

INSERT INTO `loan` (`loan_ID`, `given_amount`, `repaid_amount`, `currency_ID`) VALUES
(1, 119, 33, 11),
(2, 33315, 24345, 8),
(3, 20398, 10700, 1),
(4, 98394, 63097, 7),
(5, 78451, 70945, 2),
(6, 53484, 17098, 8),
(7, 66400, 46013, 10),
(8, 78520, 8383, 8),
(9, 41908, 9203, 8),
(10, 63217, 48147, 1),
(11, 59424, 42325, 6),
(12, 86572, 55797, 12),
(13, 88840, 84995, 6),
(14, 84799, 586, 4),
(15, 38475, 27398, 9),
(16, 19043, 17272, 7),
(17, 41425, 34885, 6),
(18, 84003, 69480, 7),
(19, 46707, 25186, 10),
(20, 57518, 48041, 4),
(21, 78683, 24470, 10),
(22, 88924, 33269, 8),
(23, 85751, 26686, 6),
(24, 25389, 2514, 2),
(25, 15773, 716, 8),
(26, 96463, 60611, 1),
(27, 60879, 33533, 11),
(28, 32006, 25371, 12),
(29, 1527, 775, 3),
(30, 72310, 3402, 9),
(31, 21186, 15997, 8),
(32, 65313, 59480, 12);

INSERT INTO `loan_payment` (`loan_ID`, `total_expected_number_of_payments`, `first_payment_date`, `payment_due_date`) VALUES
(1, 6, "2022/04/17", "2022/04/17 23:59:59"),
(2, 12, "2022/03/04", "2022/03/04 23:59:59"),
(3, 12, "2021/12/08", "2021/12/08 23:59:59"),
(4, 24, "2022/04/02", "2022/04/02 23:59:59"),
(5, 24, "2022/08/30", "2022/08/30 23:59:59"),
(6, 5, "2022/06/28", "2022/06/28 23:59:59"),
(7, 60, "2021/12/06", "2021/12/06 23:59:59"),
(8, 3, "2022/02/04", "2022/02/04 23:59:59"),
(9, 12, "2022/06/02", "2022/06/02 23:59:59"),
(10, 24, "2022/07/04", "2022/07/04 23:59:59"),
(11, 1, "2022/01/07", "2022/01/07 23:59:59"),
(12, 60, "2022/01/14", "2022/01/14 23:59:59"),
(13, 4, "2022/03/07", "2022/03/07 23:59:59"),
(14, 2, "2021/12/19", "2021/12/19 23:59:59"),
(15, 6, "2022/03/24", "2022/03/24 23:59:59"),
(16, 5, "2022/03/04", "2022/03/04 23:59:59"),
(17, 3, "2022/05/24", "2022/05/24 23:59:59"),
(18, 4, "2022/08/22", "2022/08/22 23:59:59"),
(19, 1, "2022/09/19", "2022/09/19 23:59:59"),
(20, 4, "2022/09/19", "2022/09/19 23:59:59"),
(21, 6, "2022/01/29", "2022/01/29 23:59:59"),
(22, 36, "2022/06/04", "2022/06/04 23:59:59"),
(23, 24, "2021/12/15", "2021/12/15 23:59:59"),
(24, 12, "2022/08/28", "2022/08/28 23:59:59"),
(25, 3, "2022/05/27", "2022/05/27 23:59:59"),
(26, 3, "2022/10/02", "2022/10/02 23:59:59"),
(27, 3, "2022/07/18", "2022/07/18 23:59:59"),
(28, 6, "2022/03/20", "2022/03/20 23:59:59"),
(29, 3, "2022/05/30", "2022/05/30 23:59:59"),
(30, 1, "2022/09/15", "2022/09/15 23:59:59"),
(31, 3, "2022/01/24", "2022/01/24 23:59:59"),
(32, 5, "2022/03/23", "2022/03/23 23:59:59");

INSERT INTO `account_loan` (`account_number`, `loan_ID`, `payment_rate`) VALUES
(26, 1, 214928),
(31, 2, 245389),
(18, 3, 73736),
(14, 4, 55015),
(2, 5, 42420),
(23, 6, 151657),
(2, 7, 104590),
(27, 8, 60396),
(13, 9, 149184),
(10, 10, 194977),
(28, 11, 34962),
(13, 12, 228986),
(23, 13, 195309),
(11, 14, 117591),
(13, 15, 86993),
(27, 16, 174520),
(10, 17, 177561),
(17, 18, 85922),
(27, 19, 162705),
(8, 20, 244656),
(32, 21, 117204),
(26, 22, 140004),
(11, 23, 205482),
(14, 24, 113728),
(26, 25, 13491),
(11, 26, 35692),
(8, 27, 198391),
(28, 28, 14026),
(11, 29, 134015),
(11, 30, 42287),
(11, 31, 203992);

/* #endregion */