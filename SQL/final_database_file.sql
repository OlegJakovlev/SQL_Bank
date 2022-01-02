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
    SWIFT VARCHAR(11) NOT NULL UNIQUE
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
    amount DECIMAL(19, 2) NOT NULL,
    PRIMARY KEY (account_number, currency_ID),
    FOREIGN KEY (account_number) REFERENCES account(account_number),
    FOREIGN KEY (currency_ID) REFERENCES currency_list(currency_ID)
);

CREATE TABLE IF NOT EXISTS loan (
    loan_ID INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    given_amount DECIMAL(19, 2) UNSIGNED NOT NULL,
    repaid_amount DECIMAL(19, 2) UNSIGNED NOT NULL,
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
    amount DECIMAL(19, 2) UNSIGNED NOT NULL,
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
    sell_price DECIMAL(19, 2) UNSIGNED NOT NULL,
    buy_price DECIMAl(19, 2) UNSIGNED NOT NULL,
    available_to_buy BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS account_stock (
    account_number BIGINT UNSIGNED NOT NULL,
    stock_code VARCHAR(5) NOT NULL,
    shares DECIMAL(25, 8) UNSIGNED NOT NULL,
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
    limit_amount DECIMAL(19, 2) UNSIGNED NOT NULL,
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
CREATE OR REPLACE PROCEDURE open_account(IN new_account_number BIGINT UNSIGNED, IN initial_balance BIGINT UNSIGNED)
SQL SECURITY INVOKER
BEGIN
    -- Opening balance is minimum initial_balance
    IF initial_balance > 50 THEN 
        -- Set account status to "OPEN"
        UPDATE banking_system.account
        SET account_status = "Open"
        WHERE account_number = new_account_number;
    END IF;
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

/* #region BRIEF SPECIFIED QUERIES */

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
            AND DAY(payment_due_date) BETWEEN 1 AND 7
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
            payment_due_date BETWEEN
                -- First day of next month with time 23:59:59
                date_add(date_add(TIMESTAMP(CURRENT_DATE, "23:59:59"),INTERVAL - DAY(CURRENT_DATE)+1 DAY), INTERVAL 1 MONTH)

                -- Seventh day of next month with time 23:59:59
                AND date_add(date_add(TIMESTAMP(CURRENT_DATE, "23:59:59"),INTERVAL - DAY(CURRENT_DATE)+7 DAY), INTERVAL 1 MONTH)
        )
    );
*/

/* #endregion */

/* #region 4.2 */
/*
Extract all bank transactions that were made in the past 5 days (please include customer 
and account details).


SELECT client_details.reference_number, client_details.full_name, client_account.account_number, 
bargain.bargain_ID, bargain.amount, currency_list.symbol, currency_list.alphabetic_code, bargain.bargain_date

FROM client_details

INNER JOIN client_account ON client_details.reference_number=client_account.reference_number
INNER JOIN account_iban ON client_account.account_number = account_iban.account_number
INNER JOIN local_bargain ON local_bargain.sender_account_number = client_account.account_number
INNER JOIN international_bargain ON international_bargain.sender_IBAN = account_iban.IBAN
INNER JOIN bargain ON ((bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID) 
    AND bargain.bargain_status = "Succesful" 
    AND bargain_date BETWEEN NOW()-INTERVAL 5 DAY AND NOW())

INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

WHERE bargain.bargain_ID IN ((SELECT bargain_ID FROM outgoing_bargain))
GROUP BY client_account.account_number, currency_list.currency_ID
ORDER BY `bargain`.`bargain_ID` ASC;
*/

/* #endregion */

/* #region 4.3 */
/*
List the customers with balance > 5000 by summing incoming transactions and deduct outgoing


-- Get both international and local incoming transactions for each customer
WITH incoming AS (
	SELECT client_account.*, bargain.bargain_ID, bargain.amount, currency_list.symbol, currency_list.alphabetic_code
    FROM client_account

    -- Get IBAN for international bargains
    INNER JOIN account_iban ON account_iban.account_number = client_account.account_number

    -- Get all transactions
    INNER JOIN local_bargain ON local_bargain.receiver_account_number = client_account.account_number
    INNER JOIN international_bargain ON international_bargain.receiver_IBAN = account_iban.IBAN

    -- Do not care about status, as transactions being added only after it has been finished
    INNER JOIN bargain ON (bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID)

    -- Get currency symbol and alphabetic code
    INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

    -- Only incoming
    WHERE bargain.bargain_ID IN (SELECT bargain_ID FROM incoming_bargain)

    -- Need to group because of join of "international_bargain", same bargains are duplicated
    GROUP BY bargain_ID 
),

-- Sum all the incoming transactions by account number and currency code (same as ID)
summed_incoming AS (
    SELECT reference_number, account_number, SUM(incoming.amount) AS income_amount, incoming.symbol, incoming.alphabetic_code 
    FROM incoming
    GROUP BY incoming.account_number, incoming.alphabetic_code
),

-- Get both international and local outgoing transactions for each customer
outgoing AS (
    SELECT client_account.*, bargain.bargain_ID, bargain.amount, currency_list.symbol, currency_list.alphabetic_code
    FROM client_account

    -- Get IBAN for international bargains
    INNER JOIN account_iban ON client_account.account_number = account_iban.account_number

    -- Get all transactions
    INNER JOIN local_bargain ON local_bargain.sender_account_number = client_account.account_number
    INNER JOIN international_bargain ON international_bargain.sender_IBAN = account_iban.IBAN

    INNER JOIN bargain ON (bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID)

    -- Get currency symbol and alphabetic code
    INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

    -- Only succesful outgoing
    WHERE bargain.bargain_ID IN (SELECT bargain_ID FROM outgoing_bargain) 
    	AND bargain.bargain_status = "Succesful"

    -- Need to group because of join of "international_bargain", same bargains are duplicated
    GROUP BY bargain_ID
),

-- Sum all the outgoing transactions by account number and currency code (same as ID)
summed_outgoing AS (
    SELECT reference_number, account_number, SUM(outgoing.amount) AS outgoing_amount, outgoing.symbol, outgoing.alphabetic_code
    FROM outgoing
    GROUP BY outgoing.account_number, outgoing.alphabetic_code
),

-- Incoming + possible NULL outgoing bargains
all_incoming AS (
    SELECT 
        summed_incoming.reference_number,
        summed_incoming.account_number,
        
        summed_incoming.income_amount,
        summed_outgoing.outgoing_amount,

        summed_incoming.symbol,
        summed_incoming.alphabetic_code

    FROM summed_incoming

    LEFT JOIN summed_outgoing ON summed_outgoing.account_number = summed_incoming.account_number
        AND summed_outgoing.alphabetic_code = summed_incoming.alphabetic_code
),

-- Outgoing + possible NULL incoming bargains
all_outgoing AS (
    SELECT
        summed_outgoing.reference_number,
        summed_outgoing.account_number,
        
        summed_incoming.income_amount,
        summed_outgoing.outgoing_amount,

        summed_outgoing.symbol,
        summed_outgoing.alphabetic_code

    FROM summed_outgoing

    LEFT JOIN summed_incoming ON summed_incoming.account_number = summed_outgoing.account_number
        AND summed_incoming.alphabetic_code = summed_outgoing.alphabetic_code
),
*/

/* User might have only outgoing / incoming bargains, and we need to check that 
without prioritising any (by selecting from any specific table first and joining another)

all_bargains AS (
    SELECT * FROM all_outgoing
    UNION
    SELECT * FROM all_incoming
),

-- Calculate difference for each account and currency
final_table AS (
    SELECT
        all_bargains.reference_number,
        all_bargains.account_number,
        
        -- USE ONLY FOR DEBUG PURPOSES
        -- all_bargains.income_amount, all_bargains.outgoing_amount,
        
        -- If no income / outgoing transactions, replace NULL with 0
        COALESCE(all_bargains.income_amount, 0)-COALESCE(all_bargains.outgoing_amount, 0) AS total,

        all_bargains.symbol,
        all_bargains.alphabetic_code

    FROM all_bargains
)

SELECT * from final_table 
WHERE final_table.total > 5000
ORDER BY account_number ASC;
*/

/*
List the customers with balance > 5000 just from existing table


SELECT client_details.reference_number, client_details.full_name, client_account.account_number,
account_balance.amount, currency_list.symbol, currency_list.alphabetic_code

FROM client_details

INNER JOIN client_account ON client_details.reference_number=client_account.reference_number
INNER JOIN account_balance ON client_account.account_number = account_balance.account_number
INNER JOIN currency_list ON currency_list.currency_ID=account_balance.currency_ID

WHERE account_balance.amount > 5000
ORDER BY `client_account`.`account_number` ASC;
*/

/* #endregion */

/* #region 4.4 */
/*
Total oustandings of bank (sum(incoming) - sum(outgoing))

-- Get both international and local incoming transactions
WITH incoming AS (
	SELECT bargain.bargain_ID, bargain.amount, currency_list.symbol, currency_list.alphabetic_code
    FROM client_account

    -- Get IBAN for international bargains
    INNER JOIN account_iban ON account_iban.account_number = client_account.account_number

    -- Get all transactions
    INNER JOIN local_bargain ON local_bargain.receiver_account_number = client_account.account_number
    INNER JOIN international_bargain ON international_bargain.receiver_IBAN = account_iban.IBAN

    -- Do not care about status, as transactions being added only after it has been finished
    INNER JOIN bargain ON (bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID)

    -- Get currency symbol and alphabetic code
    INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

    -- Only incoming
    WHERE bargain.bargain_ID IN (SELECT bargain_ID FROM incoming_bargain)

    -- Need to group because of join of "international_bargain", same bargains are duplicated
    GROUP BY bargain_ID 
),

-- Sum all the incoming transactions by currency code (same as ID)
summed_incoming AS (
    SELECT SUM(incoming.amount) AS income_amount, incoming.symbol, incoming.alphabetic_code 
    FROM incoming
    GROUP BY incoming.alphabetic_code
),

-- Get both international and local outgoing transactions for each customer
outgoing AS (
    SELECT bargain.bargain_ID, bargain.amount, currency_list.symbol, currency_list.alphabetic_code
    FROM client_account

    -- Get IBAN for international bargains
    INNER JOIN account_iban ON client_account.account_number = account_iban.account_number

    -- Get all transactions
    INNER JOIN local_bargain ON local_bargain.sender_account_number = client_account.account_number
    INNER JOIN international_bargain ON international_bargain.sender_IBAN = account_iban.IBAN

    INNER JOIN bargain ON (bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID)

    -- Get currency symbol and alphabetic code
    INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

    -- All outgoing
    WHERE bargain.bargain_ID IN (SELECT bargain_ID FROM outgoing_bargain)

    -- Need to group because of join of "international_bargain", same bargains are duplicated
    GROUP BY bargain_ID
),

-- Sum all the outgoing transactions by currency code (same as ID)
summed_outgoing AS (
    SELECT SUM(outgoing.amount) AS outgoing_amount, outgoing.symbol, outgoing.alphabetic_code
    FROM outgoing
    GROUP BY outgoing.alphabetic_code
),

-- Incoming + possible NULL outgoing bargains
all_incoming AS (
    SELECT 
        summed_incoming.income_amount,
        summed_outgoing.outgoing_amount,
        summed_incoming.symbol,
        summed_incoming.alphabetic_code

    FROM summed_incoming
    LEFT JOIN summed_outgoing ON summed_outgoing.alphabetic_code = summed_incoming.alphabetic_code
),

-- Outgoing + possible NULL incoming bargains
all_outgoing AS (
    SELECT
        summed_incoming.income_amount,
        summed_outgoing.outgoing_amount,
        summed_outgoing.symbol,
        summed_outgoing.alphabetic_code

    FROM summed_outgoing
    LEFT JOIN summed_incoming ON summed_incoming.alphabetic_code = summed_outgoing.alphabetic_code
),
*/

/* Bank might have only outgoing / incoming bargains, and we need to check that 
without prioritising any (by selecting from any specific table first and joining another)

all_bargains AS (
    SELECT * FROM all_outgoing
    UNION
    SELECT * FROM all_incoming
),

-- Calculate difference for each currency
final_table AS (
    SELECT
        -- USE ONLY FOR DEBUG PURPOSES
        -- all_bargains.income_amount, all_bargains.outgoing_amount,
        
        -- If no income / outgoing transactions, replace NULL with 0
        COALESCE(all_bargains.income_amount, 0)-COALESCE(all_bargains.outgoing_amount, 0) AS total,

        all_bargains.symbol,
        all_bargains.alphabetic_code

    FROM all_bargains
)

SELECT * from final_table;
*/
/* #endregion */

/* #endregion */

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

/* #region TEST DATA */

INSERT INTO `bank_information` (`bank_ID` ,`sort_code`, `SWIFT`) VALUES
(1, "883844", "LSTNGS00"),
(2, "085195", "LSTNGS01"),
(3, "378532", "LSTNGS02"),
(4, "256335", "LSTNGS03"),
(5, "899501", "LSTNGS04"),
(6, "472468", "LSTNGS05"),
(7, "369570", "LSTNGS06"),
(8, "079382", "LSTNGS07"),
(9, "243046", "LSTNGS08"),
(10, "175233", "LSTNGS09");

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

INSERT INTO `stock` (`stock_code`, `stock_name`, `sell_price`, `buy_price`, `available_to_buy`) VALUES
("AAPL", "Apple", 8993.52, 9177.06, 1),
("GOOG", "Google", 3989.74, 4071.16, 1),
("MSFT", "Microsoft", 267.48, 272.94, 1),
("FB", "Facebook", 7397.33, 7548.3, 1),
("AMZN", "Amazon", 4552.15, 4645.05, 1),
("TWTR", "Twitter", 7319.83, 7469.21, 1),
("NFLX", "Netflix", 730.20, 745.1, 1),
("TSLA", "Tesla", 5673.54, 5789.33, 1),
("BABA", "Alibaba", 2957.48, 3017.84, 1),
("NVDA", "Nvidia", 409.09, 417.44, 1),
("AMD", "AMD", 261.31, 266.64, 1),
("INTC", "Intel", 5202.61, 5308.79, 1),
("CSCO", "Cisco", 899.16, 917.51, 1),
("ADBE", "Adobe", 8890.90, 9072.35, 1),
("ADP", "Autodesk", 8115.80, 8281.43, 1),
("CMCSA", "Comcast", 6364.40, 6494.29, 1);

INSERT INTO `regional_information` (`regional_information_ID`, `country_name`, `postcode`, `city_name`) VALUES
(1, "Serbia", "190021", "Anchorage"),
(2, "Tanzania", "56789", "Hamburg"),
(3, "India", "23456", "New York"),
(4, "Zimbabwe", "90123", "Kochi"),
(5, "Spain", "190020", "Wolverhampton"),
(6, "Japan", "CD5 6EF", "Downey"),
(7, "Netherlands", "10579", "Tampa"),
(8, "Vanuatu", "10537", "Corpus Christi"),
(9, "East Timor", "10595", "Saga"),
(10, "Djibouti", "111-0069", "Barnstable");

INSERT INTO `client_details` (`reference_number`, `full_name`, `birth_date`, `adress`, `adress_2`, `regional_information_ID`, `telephone_number`) VALUES
("875931629evz", "Anita Anderson", "1930/11/7", "Parkway Street 4609", "Room 318", 1, "3328161237"),
("018985924yry", "Alice Robinson", "1992/1/6", "Parkway Street 8139", "Room 712", 2, "7269261745"),
("461681961zfu", "Barbara Williams", "1960/9/27", "Circle Street 2965", "Room 665", 3, "667544610"),
("283809469ryu", "Bernice Jones", "1968/7/26", "Pine Street 9145", "Room 340", 4, "4086148947"),
("462043063svi", "Arlene Martinez", "1945/2/2", "Way Street 5943", NULL, 5, "047999752"),
("398028486chd", "Beverly Garcia", "1936/11/15", "Lake Street 7182", NULL, 6, "0465709741"),
("532156034pmg", "Ashley Davis", "1925/3/28", "Hill Street 3037", "Room 54", 7, "770928697"),
("660943612idl", "Beverly Harris", "1991/7/18", "Lake Street 96", "Room 697", 8, "37911522060"),
("090757455kgp", "Beverly Anderson", "1961/3/28", "Maple Street 1802", "Room 513", 9, "7968386236"),
("341852230gbg", "Annette Moore", "1922/3/24", "Pine Street 1049", "Room 943", 10, "9322193724");

INSERT INTO `client_access` (`reference_number`, `password_salt`, `password_hash`) VALUES
("875931629evz", "VkHds)6n_d}E/aZ VC_YZzm7yzJkAbE`Thty$^G+U$#9UX2#_b8+I>])QmTtg&Z_", "d53be64858342ae0b3dbf817a32a69d5adae2abaf0d956e7dcce7cbacb0b9a2272caf9627e39fd3ecb3c5eb065cdaadbd8d4eb709f71c46d98ba889bf00be6eb"),
("018985924yry", "}8a:9_3b.?f@`E1G!BcKMRuovp-?7A~V{UF@6A:@r>#xyWM5rcy*jY<Kq-y|<]sp", "b69cdc8c6cb398487ac4ecbaa1ff84dd79aabae446f9ed6f5b7ed5ada3f7aebe6edb1fedc663be3dccbdc08debb147bf0371225dfde8e911a7c6bff2cde851ee"),
("461681961zfu", "H+i_~ ^=j;gnzw^Q/oa,p&nq}CszIWO`[..#X]V$sLfdRf(ROEGw2'd*zsxbKobF", "f8d247ec66de301e08ea7baa3f917a7764cbf5a2c681d22ea1cfce90b1d04341ac990e0f3dd60e79cf0e19eca35d0b1816b7c1f484a9e708cdfe7fcfdfc89fc0"),
("283809469ryu", "X_t{v<BRs7/mYOtmab'5_6aN|X>yMIA4ZdbdLgT6jbmN,v`_5CkE4o]|d>UKE^09", "aa6b8e67ba6ba528ee8f3eefab3fc248d90df317bebf4eee34f8ea81fcb7147d2ff45baaecb81eab2e2decb88d90697fc9ed1d2fdb4505b1ffa9fc30f376cbc2"),
("462043063svi", "VXVvT;%FH$=S8Ex+-jCV/vq1L@`~'eUW3jT54b_!Ueesg6;q<5Byk>.ONG:$^(r+", "35f2caae0f4aaa9fccadff644bee70b0293dd1b1918230fc13b153a3cce87ddfae59de2ad1caa7db5bae1c0eb0fe2f370e3c25cd4203a0c6dedb3bee5c656cb3"),
("398028486chd", ",4zHD@smc:<(H9dFq~%&De_5XS3IXCL_=7{iSjMEBd0:FnT;SzRZP50?PkKS_NOi", "67ceef66d5ca04143afa4fc266c3ed6d0d747cf5b8e66a3ee4fb2812cfb4cfb3f7e4ddeabdeb3e4f8ecf4ddcbb0067c5d862cad8c849dea8d0beeda9bdbc7cee"),
("532156034pmg", "JaLF(^{|#!fcIrsBlS?m.t'Xwhfo_N=R#X2?bOyvNT+:E| wTN}g[y~C=0mU,fG]", "2cacceb16a06d040c55c02c0f10193e8cc5735ba88ba818ea84242459ff5bd933fd6babfacebcacc9b1aaefe9c8cd08a8a4b3ecc3fd8e0fc563f438ecddd1c6a"),
("660943612idl", "a#Ln`Z4R?E'jYk/8e[9oEq'xvJ/y .46W$&-YF1eh!hKm*m.d5KiJ'M0>30?`w,N", "72b3222b62ec78958ba6da3fca72b645b0df6c7fde7e32f0eb596fc7c32b4ef5ccae7cd1331704a3a3638b9e6fcaaec8beffaeface4d34ce75de8526a1dd96dc"),
("090757455kgp", "8 &q.-0C6fQB^{Q{2fbPQu;M/qQs4Xzhn>R>8QwIBA%[F%RBp4+sG8PV;$GFfm8W", "0bace249efebeb2cde65ea4f4ff92c13fc8c1b2ff6efac89d042ceccaa0b4a62adac3db95c1bec9bfd8f7affbc026e4b7be2bc48a4fb8cf2aeabf41ceb3f5f25"),
("341852230gbg", "yBKuqLic$q=Vm2#%S}d-z&Bj:{T_LN;l7DO&(X>6/Be+}wh`;4Lr0iO[_va73zWU", "3dabb33e47ae210fcc2d37ae13dc8c6decfb1c0e75ebd3bc129ef0dcda0dd16499bbfff6c170ce44fdfc5204fdfe6eff400bccc9bace0cde9cffec0cabdbfb8b");

INSERT INTO `customer_sessions` (`reference_number`, `customer_IP`, `secret_key_salt`, `secret_key_hashed`, `token_salt`, `token_hashed`, `token_expiry_date`) VALUES
("875931629evz", "129.177.146.139", "2=`(Ncc$8]Gy($]{I;63dK+~+9YbO*suZblf~qnB#iUch7q&ZPX.l<%&/haS[.[C", "08acfcdfef26b705ec5effba1a8a36bdace244efa3aaa4c42b5c5dff7b5effbac7ad3c1bb08e1a1db71ef379bb8dffc06ebf44cc6b1e2cee1f68dafcc3b1fdac", "?$3Pm=--muY,7L@|p=XI3@D* !0pC}TxnSy=`lC64^91MPxvx~S/BP4O'Z&;$X8@", "d4babb04318d2d700bfc0d79056dada95da73a1bbe4bcea8feafaafdd05f8be1de5c68cf9e9c5efac146ef2f77572abdcd5e4ececcefbccfdfea6bfddba3ea53", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("090757455kgp", "185.161.151.54", "$%q[v%g7s fI5UpMRSDf^rcuKr3}-WF*1x)mxr{(<j[|LlP=7}*vQLE]^1Hr$]=u", "1988b83e5fba64ff1a13edfeff8f840b65bc97f61bb47abdf336ff6102e879dccf56df846faefbb4bea4d2cf05024b2d308de8e6bf400f00ccc1cb171f8dc4f6", "A|cbbIYhtSzTLki'_7#)p,%_{>{muj5mZ~V>MH:L5x{jsyK&ipA&a86,miu$P*/7", "4e9e4dbf77ec825edf8936edf8c7fbadc2e13a05dea62ecf6c845d85fcbc07b8315b116cc1430fca1ebb6697ab9ea04d11f4d7bdb79dbeaac1aaf7f0ff30a98f", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("461681961zfu", "225.212.217.225", "~<3z?Er =KcT4K=_kgu7+%sGkg`}U?3k +.T,e::(~` H-]aw-5@j<vk;/?&S+=`", "4fd58a2ded3f0ae8dd5d902c1719eaae401c09e0aca506c17ccfc0b413e8df43fd6a4316fdeeb1cc4f3b45a97f217ec01ffefcfffcea4deb8e8703accb7d9ccb", "Qx-#;'xag,=1QC`^J5?8#Q9!fLI[7vU 5oe])}t1R/d#6w^iKD#'(`<[YT6r `1/", "475bd3393d0f4ba047fb7d6c2b1f15bd91b4c266b6a6d012da6fa08ced49ae8d2561e31bcceef897ff8ca5ef0dfae066796ebf5ffbacd158acf2ad02d4afb7ee", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("341852230gbg", "67.181.198.128", ";gD?JN^b@e:0NC:g%9j3^tx#P51OB]}6N^D'+6K##0nNxw`h,Y3gsU:>OrjO)6jl", "d0d6a0adfbc8ae9e4caaf741a19c727b1b72ea10d6fc0f82182b8e20dcc09df2bf4cc87cb2b04b603d0ab53dfd29b15bed1283a932903ad20122b11bd75b979f", "ftP~):{nadeQW770Q~=q/1jKV%v0hYK4+C{>ft; OK}. E-[3wn/T;h#9!.V`fJD", "e9c23e0de3bdf119d13614af25155eddcab7eddd2cb7dfbf4cb8c9ce1c95ebcf2f31fe3de9c3b00a0fa1a76e43d8e6b4024fcbcf062d6bac5adffdebdeb46cad", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("090757455kgp", "254.201.179.179", "?Cl^k1Eawo_`1%sPsOR{o-CrGFAgF*_QC}w5Hn@,k{`R|cV_.(u8_owF kp5/Cql", "bcbd92acbe9b498e05f6ccb8daeed19b9cac84b1fea5a98dd3b0a3eef5aade1d5edc2ffa0dc23affd2ad8b24c5ece5ccd1be8f3db3d92ef3adebce0bfbfbd9bc", "4Fs.G?r(2x>9G:GdGM7 LO<MS`NR@d|L|;U:T?@~+q=p*Mjk5b3+2.yBTgTv'-&A", "d586bdb45afebe1c37a7edff94c03bb37feaeef9add73dde088bbd87fc5c4b5f4ccff4f9a3ec560aacccff0a8accde6d3720e62d0daf1fe3aab7fcdbf9c401dd", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("461681961zfu", "137.191.12.22", "YpN'Y1I[0)$J5:/5.XsSJMr_x-=+@NEmV&vh,59]qFrscK*!5n-V!b.C<nK~%1O<", "8a552b5b00ce7b1c08e33abffa77ec63dbbc8aede349cb3480cdf5d9a3eaeeb9b918bfdbfff18f7ed906dafb55f0b8986fa8de1fc19af017c8c33cc2931ceadf", "?/En/!kZG~e~!3)/Ws@%|-~`~La}q*7+f-swLPhZC?!TD:x>H;96cT+C(q`I.Lr<", "7bdf7e6ad467fefbeab4be0bfcad4b0dee0ee7b148cb9e92b74fdf6abbbd8a9b30c16cdede1d4eecad6a8b01d9ee440ca4bf822bd5d8d5500b532fcdaefefdfa", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("018985924yry", "23.227.192.229", "v[eLf{Fh?Nmajm])}h-)@mLz>w&U<HvikW+_t0qJQM;oAtf;Ts|W9w>K;=Z JWn7", "c8bfe757b1d7ba1ffc2cecaaaa1cad97fe32de4c24adefacba1e83f42fd58edc5eb1dd9bdb4fedbe7309b8fbf40e955cebddd528ed6215bd97a55aacf11e0cd5", "]<~;SWtg~#d&nBxZz?1sxs-0W$O8bLzQT*7KIy7x-7vcTy6)|;^i73meGryyB!w~", "3807bfbb46ffde936060015c84efacffe4f68aff0600e72b4515aea4a0503e01feddba3153f6fd246d349ee36030896d571ce3aa5e1cfdacbc0d7d7ff8cd0cbf", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("660943612idl", "209.7.71.68", "ToH``j$rO?W`/DC=)>]8}ApnZ9vQ'0Gb`BA/s>1o^*K&rvCggENR4OK.sYDmPd7g", "d2c54d4d7dfd529b70b58a265b252ac38b8ac9de63cb71f847df95255acda1e3ab5a9b3ddfeacadaec829d7bcc9388ee54bb7fce1db5da24eabdab2ea75eaefd", "s97AcE;TK`X`RXe(?JED`WpwTllAu!UeOk{OLGizFuA1{~tgTwbOAl<8I}mmY<x+", "ebfcb7bbfeda6e9e5e1e5e36ff4dfd5ddc41ec83aabffc6ab8dd2fa98c42bd8dc71bfa0ca42e1c2ffc9b5ede6fbf507dc44d8ce882ebd887fc7cee6ee570788f", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("660943612idl", "192.139.13.215", "]=ppQxF2zwX&qkVZf6`snG.bF<O5q>p2xu3/;K[an7^)%&|_*qh%d;B?d5NQ>Z6/", "1cae0abfd7b7ea34acd3d3c1bb0fea4a8dd592a59248dfc1e5bcbd353b9cee18b2f3e4ffefa88890113092abfeab2ce839a61eeec408f3a2ec4170ccaf6eccdf", "OP%,&E(!DllfD3+-90|3V34!lcb-$/SrmBz4ts!SVR$6Vyjhz>dE>NU7rBI+i##5", "b1fb3ba8e5cd124c84ae960fc587dc1ebdbdbd4b58e33bdcf6db1e31ccdc96aaa24d0f873ae4f654ace62e04858df162f8bc2feccc608b6c7f00aeb14aeb4b60", DATE_ADD(NOW(), INTERVAL 1 HOUR)),
("341852230gbg", "164.12.118.7", "j&tt}XbbRc'h*}} ;qeH5S`Pe1}MtWXYu>~IjPy{gAohc{].YBoTBsc<RB|PV4I}", "b3b14eca7375f85f8a88acfcbd4ad4216ed5f3e8995240356f9984deef6e6ec8adfad8b3d31ff69a0e85f7eaccafee6f31dfce6a1e76839d214f9adb57f79037", "@IcApWj f|)2]wLw0.c]Te,M@r~}o4(Ew9}Qx.wu^X@DH6qt*@v*s-uR*-< !D V", "da44a79e0a532c5bcf466be93d23ec651befb4fdcc15aa7f7efdd4de05e503e7cfc86edab131286f8fef8d8adb2bdfb744a4dd37dc3ede432bf94b2447cbf54a", DATE_ADD(NOW(), INTERVAL 1 HOUR));

INSERT INTO `account` (`account_number`, `account_status`, `bank_ID`) VALUES
(1, "Open", 4),
(2, "Open", 6),
(3, "Open", 6),
(4, "Waiting for Deposit", 9),
(5, "Waiting for Deposit", 7),
(6, "Open", 8),
(7, "Waiting for Deposit", 7),
(8, "Waiting for Deposit", 9),
(9, "Open", 3),
(10, "Waiting for Deposit", 8),
(11, "Open", 8),
(12, "Waiting for Deposit", 6),
(13, "Waiting for Deposit", 3),
(14, "Open", 5),
(15, "Waiting for Deposit", 4),
(16, "Open", 7),
(17, "Open", 3),
(18, "Open", 9),
(19, "Open", 9),
(20, "Open", 6),
(21, "Open", 7),
(22, "Waiting for Deposit", 9),
(23, "Open", 4),
(24, "Open", 4),
(25, "Waiting for Deposit", 1),
(26, "Open", 5),
(27, "Waiting for Deposit", 5),
(28, "Waiting for Deposit", 8),
(29, "Waiting for Deposit", 5),
(30, "Open", 9),
(31, "Waiting for Deposit", 8),
(32, "Waiting for Deposit", 6),
(33, "Open", 1);

INSERT INTO `client_account` (`reference_number`, `account_number`) VALUES
("090757455kgp", 1),
("018985924yry", 2),
("462043063svi", 3),
("660943612idl", 4),
("283809469ryu", 5),
("398028486chd", 6),
("660943612idl", 7),
("532156034pmg", 8),
("283809469ryu", 9),
("532156034pmg", 10),
("532156034pmg", 11),
("462043063svi", 12),
("532156034pmg", 13),
("875931629evz", 14),
("532156034pmg", 15),
("532156034pmg", 16),
("875931629evz", 17),
("875931629evz", 18),
("018985924yry", 19),
("341852230gbg", 20),
("875931629evz", 21),
("341852230gbg", 22),
("462043063svi", 23),
("462043063svi", 24),
("283809469ryu", 25),
("341852230gbg", 26),
("283809469ryu", 27),
("341852230gbg", 28),
("532156034pmg", 29),
("461681961zfu", 30),
("660943612idl", 31),
("660943612idl", 32),
("018985924yry", 33);

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
(32, "GB0228189000000000000032"),
(33, "GB0228189000000000000033");

INSERT INTO `account_balance` (`account_number`, `currency_ID`, `amount`) VALUES
(1, 1, 107707),
(2, 1, 244641),
(2, 2, 22435),
(2, 3, 78141),
(2, 4, 53278),
(2, 5, 12741),
(2, 6, 228781),
(2, 7, 132159),
(2, 8, 195555),
(2, 9, 181782),
(2, 10, 85088),
(3, 1, 54937),
(3, 2, 190811),
(3, 3, 245629),
(3, 4, 28162),
(3, 5, 195673),
(3, 6, 54970),
(3, 7, 44174),
(6, 1, 224481),
(6, 2, 18951),
(6, 3, 87548),
(6, 4, 132953),
(6, 5, 40690),
(6, 6, 190627),
(6, 7, 190059),
(6, 8, 222502),
(6, 9, 101030),
(6, 10, 76912),
(6, 11, 68777),
(6, 12, 131809),
(9, 1, 209763),
(9, 2, 17775),
(9, 3, 15514),
(9, 4, 215873),
(9, 5, 209298),
(9, 6, 54601),
(9, 7, 131209),
(9, 8, 62958),
(11, 1, 68177),
(11, 2, 8453),
(11, 3, 141389),
(11, 4, 214100),
(11, 5, 34743),
(11, 6, 155497),
(11, 7, 109748),
(11, 8, 110877),
(14, 1, 146441),
(14, 2, 191725),
(14, 3, 150824),
(14, 4, 32901),
(14, 5, 119906),
(14, 6, 121579),
(14, 7, 45960),
(14, 8, 79499),
(16, 1, 69587),
(16, 2, 65321),
(16, 3, 59886),
(16, 4, 186188),
(16, 5, 98093),
(16, 6, 17911),
(16, 7, 174853),
(16, 8, 74495),
(17, 1, 54143),
(17, 2, 23687),
(17, 3, 139627),
(17, 4, 206060),
(17, 5, 68480),
(17, 6, 211337),
(17, 7, 35938),
(17, 8, 4403),
(17, 9, 152082),
(17, 10, 169423),
(17, 11, 92792),
(17, 12, 174680),
(18, 1, 238722),
(18, 2, 180427),
(18, 3, 238761),
(18, 4, 51100),
(18, 5, 222746),
(18, 6, 216731),
(18, 7, 10125),
(19, 1, 198528),
(19, 2, 227847),
(19, 3, 143573),
(19, 4, 127812),
(20, 1, 7079),
(20, 2, 79552),
(20, 3, 87756),
(20, 4, 83010),
(20, 5, 185636),
(20, 6, 136352),
(20, 7, 15239),
(20, 8, 59801),
(20, 9, 73323),
(20, 10, 136435),
(20, 11, 208341),
(20, 12, 243069),
(21, 1, 2983),
(21, 2, 103926),
(21, 3, 65618),
(21, 4, 16563),
(21, 5, 45529),
(21, 6, 143178),
(21, 7, 8414),
(21, 8, 236780),
(23, 1, 22465),
(23, 2, 1037),
(24, 1, 201218),
(24, 2, 35122),
(24, 3, 161692),
(24, 4, 156733),
(24, 5, 155605),
(26, 1, 203807),
(26, 2, 87709),
(26, 3, 70955),
(26, 4, 172800),
(26, 5, 92104),
(26, 6, 111489),
(26, 7, 34030),
(26, 8, 231528),
(30, 1, 204701),
(30, 2, 240112),
(30, 3, 63678),
(33, 1, 34816),
(33, 2, 208085),
(33, 3, 180353),
(33, 4, 152180),
(33, 5, 50552),
(33, 6, 145722),
(33, 7, 76511);

INSERT INTO card_details (`card_ID`, `card_salt`,`card_hash`, `CVV_hash`, `PIN_hash`, `internet_shopping_available`, `frozen`) VALUES
(1, "4;/M+OwD#0210Mm@%4~Cqzo/FRGWuvw]}Y3l>FWtf7ao7Ey,$y0$VT25^SJ?=SP ", "8da8c9915008bcded3bc1fdfe1eb9daacb84c8bcbbec9bec9ccdf41eabe1aae2814d3ed7fbe1dfa79e1ebaebad2aaa668394f77adcea35b9b7cdfa2edbe9ac67", "ad403f4f5d04bedee2cb1a48dfedd0ccdead72dd62fee3cea0faa9c87eb017d6bace856afb3f4dfeed2fe6db85b320cc86ed479963d694cca2a979f0dba7cced", "ab0c25b1d5e2c6c198d79b2b238f68a24227ed7547030c971eefe60effbe0af8b7c1db92a2a8a5d7efadf3632d03be963c8fbbe6b2eb136baf05cd8c560fed83", false, false),
(2, ">&^_=Uox*joN8m<!2qFA*ZX~Dk=[2>gcF~.>;7;l:Qbm)C;n,dx>qZoNRM~g<r,h", "6bc854eb29a936bab90ebd43fc62adbe3e84ef0ec14c2c5c9a553deccd0deaca4452c110caa4eac8c5c32b2efdb22424e09fbdd4df27b3ceebf6ec79bf4eddba", "3a5872adfc62ba7e9b1215cead33abbb4dadc223d1fe782fffa21d60cda9aebf5ad1c1ceee72fad97ecd75fb15fcc5a95ba0e74e6adaceff76ee92ceeeceab52", "b1d1d3a5a8badc3aed4fbf8afaa79c6fe4aab153db7c64296efaa443dda8e5fc08f0f9f01eaaff5c71b8d5c304c0702cbbe7d7ba68b59309e02353496cfd254a", false, false),
(3, "Pi:` 1|}aaGX:.7a;^$B{a-1(TsnpcT@|=M)EZ=nMclq;LdU 3b:[LqtCZ#T}L4M", "e4b5c4f7b86fa9951665f478bf82ae50ceb7d8846a40465c0cbcba07fcccb3d7bb5bad024bb41fb8dfd9fe1e3c07ed862ce01c32a3c3b8df3d4c9cb53880deee", "efd33c57ebcc1f31fbe6dd1ffed0b0af462afc69bbeaceada9593eacf70f9d37ecee599c1e6e2d10d8ad5b4fe4af0ec1e012ae37c05eff9bdaab95afda5bfae6", "7a285ec19fdc9fcf89ee28315c0b0e1adb38d7e62cad1f7a814aadebf1ab561d4ca9cef6ee6bc06dc53caa02a9fa50af389f56a750b0c4ede4be795c631f76a5", false, false),
(4, "Ib'%AwZ~1L.q<,Kf;gH]V.h3VR|*!$U]gI#bhnXFPx*';/*z|f!3t5;S:T[@mpNb", "8d0daffeefa164cbb66c7c1a4ce8a37aa3cb8828a2ac6f997be83fe86e7bef34bba1dd91bec5abdc4de18ec4fd5b5abb0ee81e5ad088265dbeb8c177c86cf0ef", "cd7ee66574143a2fc4e20ca4a59edda162bcdfabffc59fdd45fb5bcbeda8efd9e587830f3f0b88dcdb7aca01ce1e80c9abbefeee499188efb76a0026dd8a4e0f", "f2f4634ac4ca2024b8cf18f8f8561db408bfcfef1c947a3ef9757fd5cca5eff2cd8377dca5ea9ceff612f8ff2fb9edc5edd64dd5b83cacbcee9fc4be7318c0db", false, false),
(5, "pdht&)U@QN/bPM0qB9<3.Ft&kBkkLZA1YYwn`s,1+*)c}q>k%q7gH<vw/[?^[+kR", "b54bf48ef6b6a8daaf6da525fbcae8ffb488cee4e5d9dcf8daee789e6aaa2af9ecc38970c39eb69a3fcccbeab33791d09fd7eea08fcc76d0a9ab72fc3d7e65db", "0f8ff49a8a84cdf4cad1ae8dcdbd4f5dbe038eeaa55c6eaace6fbd508eebd7ede31a4c0bdcafbf5d33d2b875cefead6f6acdb0a01cf0ce38ad915a4cfd7c4a7a", "f20d2acdf12a9ff2ae16dca2039acb96eafc1dfb3eb12b4fd725b5e8db2b7c7aacfc9cfa81b53cd980f1e36bbdeb64ebdd9424d60a678e17fae0ffbe8913bee0", false, false),
(6, "9oYIu/l/g^WS').rD<tDx0AdLeZu7Jk6fH#~Da+PUw<V!5gK32~|[@~ 7GVt:LDd", "fbf13f6cc9db12e8da96d15898daa16cfe9b7553ddfa03852c2171e639e4fdf8cf8e75c38bdcbfafce31bcd856010e6a3e2c6b8d7ad8d62df3398acbddd7b5bb", "3caed15f3b1e8aebabf0bee34eb8859e9fb4a63d8f07dff0d3fc0f2a5934c124bb57eeaceecd0eaa1c9a6cef40b7093bfa6fde5bb419aa2bfc8e6cf4d6f3b7ce", "cfa4d73b4bfe67f15f3c10e91ffb087bdf9c949abfabdbd0854a8e9cf2f40de96924417deb9ae5cab8293c9dd7ec3fe0e38acb9e6902aeea6edcdfdd6eb579af", false, false),
(7, "_vN%hI_AvQx7'#F1Y7SLXM/F0SR63 7=mlMF^^:X;G/E)|FxXnrfrX};LOmE=#Y}", "cdbaca86c9f30d059b6af5cdad6aed25f89f2f3557a2dccbb2cb8c3ef2502dce2fa0aea409eef2939cc7eab4cdb71fa2ba4e53a8befcfa0c753bea0d0ededcbb", "e7436040f4d9a78ca7a21fffcb83ffbaa5dce1bdceedaa4519cf6fdebe5beb0da3557e4bf92bc897560dbda2bba1cfa5a1c0aab3c7faeec5ddf812136f641262", "d7e0f0ba6c5bb62ac95cad766bb54e0cc9aec1fbf813153f48c61facdba0771ce2fd0a33eb3fa41cb857ac3bb384df3d478a17f4f2b46f076aba25b9e0bfcceb", false, false),
(8, "-d.^mf]_U^'H&t?%p1l%#ux8!3)r(XO 2L1w>; QF0FXkjC]CcbfkrTt~B$* (r ", "969de1dfce90c38cd16d4b4a5bbd4df6a8b84161a9bbcafeaf73ff0ab23f48bbbe3ca5ca7cca4dba9bccb83abcd6ab6c97db245ada7b5ba0cae1db34cddd77bc", "f9256bf2dfeaf5e4a9b3b2cd60ad4a463b2ca3e2ffcaba10faba0b537b4f142869af4b23bb3a1086de9526e7fc7768d7e3663a5cc7a6b4cba5cf41bf16fda0ac", "2f1defb0c3c402cebe82ee97e148bdbd4bf4e6b9cee61b1ddcdcb201748a3d3a15246dc9cf008ca7eeb147fef0fbfce56add8f87eaaffbe4e88abc03a6788cba", false, false),
(9, "O,q#fMq,3sTM,PMiwwaN]n4E/CmASn@&D!xT4UvO zWM(u2X$4U!!d`Fwumn6:1/", "6eccd659b4eccd0feca9efcefabab5be0cf4ca3ccdad3cb8ce6abbefe95e58dd00bc87e358908eeb8ef3c18ce37f66d8ff5d55ab7bf0a6c970cd564b1ff9b3f5", "249fcdd910be8bf78822e7fbedb4cdfc8b994bc3bfab884737c2f1f3895ddaa6fca1d007760deede4c09a8d1bdad01542e5cba3ff65cea96255aff08dbf48b2c", "e8b9943cc6daeab1693936caecbaac6ef6b354ce5536bbdcafabbfabe7e1d2eff2ddef9581beca9d28aacfb2c8e6012b6e5ba9aa3d6ab9d4c154543f5b0d1353", false, false),
(10, "B*xXqnN$Ger?/+^s%t/P5YgP1QIkt%,DTT:~_CGk80)6&NwNk>y<yz8j$)6zAheL", "0f314a7eccaacee0350e0faa82a62ed4fe2ddca61a47f19cfb6cedbd4e79bfd9adb881e58dc5cfd16a9ec3f43fac45f8e4f5cc5abea58af1d941af8cfcfeb2f8", "db49dcfb68c9c255fcfc9654fffa0fa06459e5c5317a8b22fbbbfcd9dd81ecbc34d046dc8eef62cc79432f0a42cc6a7f9bf1bb88dd8c4fbb73daa4eabcbf12e5", "9d9ded28cdcf37bde8cdc45b367cad71ceb2fe2c4c5c9be293bd1e7c1f2eaf253ec98e5ea84cfcdf6d5458a5bddce2716c6ca513b14e50da6beeada022caf668", false, false),
(11, "O_.:,}KHC2z/|O,eTOq@;p9c!#e&G6cv~<_Hv*S&p~mlPo|&Zrd$avE1^|G-my5/", "4cfeedc8bbed8a35afecb19cdb9fc7158dfeaafafaaab4babaefb9ed7bad1ecc1d7cf6cdcbee34cef21fce1ce341f7addeba9d2923444ec2bfb85aa70cbaed6b", "138adb3c9abc3afe3bf98ad2301befbfcbd3d96181f45afe5f4786adafcbb1af0b69b9a89c15343cf8dd48f09d62fecdf323ebdeced1c4a91cad7c042b7a1681", "07acb09e8bb1ceb61c5e35bbf6d5c210a3831485dfba62a2eee1abb62b874dbed8ccc6fadff9df5b1120dc4a7f558a6a6dab27e4f2b6ada6458a8023c219acdd", false, false),
(12, "U3g.[;7sw_!veQ!0l/PmGX6%lO0&iIobP9w[9L~>=+VQ+MVUA9`$Kh$QVikk8w{%", "71eeccbd3acf3cce6b8eccf699de6dd1c8b1ab7518fb1ff37feaf17aae068f36da88bf357fc90518eebff277f1d98efd5364e12ed8bee562da11d21cbec655be", "5e4dd115ef38a22f45cc88a8fc7d69b34a58c80fcdf9f6ccf6dffd02d0ec5ec18c09cad6117cecefede7b26dc2713ea7c4fee2bfcdd0dcdafe5ebd1d1f895f38", "ccb665ea3b2aa7a1fa89afbaeb2d5bdbed2c42cdd6ae6cdfb8c2e8e86b127efeb0dcdfa6327d8eb0f5e8ddb84315be4faa85edba8fbdb539da154a5ead8cff47", false, false),
(13, "f~bbRs;~+>R=NW-$0nA2>2,Y$ |?J{Y~drq({oU5hUJ'Lvf~o~fEHlanLp>rkHWI", "8c1dbbdc5dfae8a882b3dca00ef5dd6d2f5f019427bcca7c78a4626cf132a8f910d38a70fa50455b7c4916b06dfd2a9c4f86da2c0f1c3edd1c7a5c9ec319eee4", "5c3f01bfe3b0e7ea8df9618db608fc5abbbd8ee2d082951ab8f8af1dbcc28e0e19f23fde1b9f446b1832f6cdafbad2aacebf684bfc4ec951106214b4f34964df", "41e45953be95f5be090b8dac3ebab0b05ccac9a0f1bc1ee8cc36c88139101085ac08306df7c7eb24bb4a9daa81577c35d3dbbcc3eafc3ccaf95bda8d06c0459c", false, false),
(14, "|9D/mo=V#G$!Iv=A-BfF^[?kVRBk;b[kmtY;N~0&8vKlcmI}`c?LHm1Gyt?M+ppl", "7fbbbbe5d0ceac92763fdd853aadef72d47fc428f700f009242a7cddb65bcf1101cdf82b8cf0bcf590b4e7b7608f7ef30af1eafb08f746acacf43daab848b648", "b856e44fcf277281f3acef11cf2beaf55a1ec0f581da8b3cc0a7b147bb39fa86f2c61df003e894750da4a0f7c1a4cd63ca80db45a58ff5f8948a7f744a8ed2e4", "d95bc6c4dfa85f9aa735621ffff71c4ad12084d59a4ecaeff05a72c3f0edf8e36f9eef6d0fbce0f52f41ac0fca637d3cceb7ab01ae266d8cdc0f6d4e8217b2fa", false, false),
(15, "![tebD)##;-3]@JT_K!@bB~0pN`L|cOG,=<2^Xf$-$]*J9qfIF)^Sk@j7Cp%^Ibo", "d1f04a5bbe87ad93ecdc6c6384bfee6cf6ea90262f4f1e9fbad3d2d9d8d6d8be8eab02fb997fa96f59d6e4d1bb8ec4ccfdea7c52ddfc6d74a7b8e5efd1a4bc4f", "8e9cc9ae86b6debe1afa505fd51613a8edba2bf4bb891e2bfbb9e3f620da91bd18c09aa6bf7ed1660e996a592b4faccb44f1ef41dce5abcad3ee0fe20e4aab85", "acdc3cacef7b3681abdb34717ebbc1e84930add6e45de6168edfbb16fbbbcc058f35fcba13bf84cc5d6fc950fddabb2316dbb2726019d88fcfc4908c70d833bf", false, false),
(16, "(x~lT~MDi10oV<Jn`Wyq=ZUx6|Uc=Kx71+<@R+0z~|n6jg3hB QOIH5hTj~,r9se", "e9aaad6cebc801ecfa568dec70eeb37e39ce6ec058ff7208278f72e46f53a9fbf0bf859cceaedf03adc9b87c2c7a2de1dfe15e2cf4a0a657aa73163aedac71ce", "bce2fed15b4fcbccc88db9b4bd7c3ca91f3a0ac5c11ffbee09d451a78bdf2b50383f1dfb1fc59e5d6ad6ddf1d5fc59be5bf2c787bffb0c7acdfffdb0fcd7858d", "5df1d1cbfd4fd7b8e69df575a2e9979e39cfc2f5e1f67ecb704d0b42c999df8fe042df2ea2d85faec8bf88d792d3715b7c37f1f1f036b3450aeaeae0daa4b4c8", false, false),
(17, "E)J eSykGAGwNGgsd^8./7o91F[9)bb`@J>`SyF>I$jJ]ZLBck,McGjz3xV:^MiB", "94cca7aba34adf305bebf18aaaacd2af08d48f9f5ca6ad7ae19b76def219a8fb38c7b5aea4a0bf6c3cafd8bcf09184bf4cabde724c8523fbaadc6665ca097aa7", "b6b72b837d279cdc34a167df4ffdb5db29ac1b4ce29fb1526cd4a72ad1a74d6deddd0749dbaa97ebefecfbb537daab4d95abba3a7f4ff357def708efb6988ddb", "9fd74dba4c72bbc967ecb230ed8acc3dabf6318dc2ceefbdaa1a5afbb5129662b32b8afc0bb27abc3a0ee390264c3eebaabbbbcaffe9a8db4e05dad0e79ce394", false, false),
(18, "sopml!Vv9,_DZ({%Ke2iv2oP2'G{7&JP;zd6Bl=&N.r%=hs8sYJH:}iyo[I,'@/A", "f37b6836d5ece99046a6cb29585905dba44aae493e0d6ba13950bde530596e4ecef759cc3d9d61b1fffc87a36bc70da8dcfebf0ddbb2d7470ed0a8daa474def9", "a98d0babeefc422c3be11bfddc7244fea6dde12b5cc5afa15ce37069cbd0f0ab58a42aee3a2bb77c3d22cce4de9a2dbe7cbaecd2b6982f1ec46c2f850e746dd1", "d6a8d6a84b8b0ecb21b00c5edc9ac7b59beecbe796812a851aacbbafa9309b7bdd2ca0aaecfd6d92b3452c0bdad11a9fcdff3bd9584edbfdec7fcbd23c497ae3", false, false),
(19, "=d.4Hq$I[.^J1}BYmT=uPt|H1bN3MffhlL6,,D0NwO($ )Uxu:;)|hxLK'l=qTrx", "e69abfc2d6484e629efaf8ea07bc575d2aa67a80deeb72af2cd3aea02cd739b66b8f9d33fb2deffecb07fea7df0fc22839cc7e7e7cf9a39ff89f8e5eb7bc3d37", "fe114bb7fd15e1aa4619ea7242da47cc71cecd4eb4876d842a619affa00c0afac0a9cc53d7f722b4d15fc5af753fabc5be64f39c9ee6e0dcf54fba0b99bad9a8", "f238b360559a8fcccf1e3cce10c3e5f44adbc8b5163bfd2dd2ccfbffd69ebd86af05e340f38bbdfa6dff9ee6b8d32bb6d7484621aaae24579327cded8beecfbb", false, false),
(20, "Osf.K,tp|S*Uto)VbhakhxI$ly3{A['g[xJZwI<QG#mUR59=qoO@ B47]4kru7gu", "a4a87be120f82ccf67fe212f5db68de3fe9c6caac75205a7d6b3ac1daab4b356cbda451f4ebbc6a74b8efbda28561442eacb6cd7f2e9223c76d0f09ed3bfb80d", "c0fe6fdeb3dd85528db50215bb5f6bb62fa7bafc7eca49dd5eb26d5dbb7e2ecd689c35c2bac0a04cfc6a5954fc9c4beb966e8aff2e1ef162f7927578a45cbae8", "afb48f7b66a87fbca9f3ec7acca4e4a1eb4d9d2b0fcdb3fa6eef55fdcd2dcf3a6efd2f5afd3ceee5778ff10be6b673f27eef00893a456efcdc9f8fd4ac298eef", false, false),
(21, "Ax9 ><2%FmF{_vSuel'I|}0P_2lN#Bs+^9Qrh'!-JILO[k;0`XNW60cGoSKb,[zd", "69d731c12689d18463d3ad7f981bfffbda3236cfb90fa9eccb6cce4d39cadedb0bd49d01d94bfbd82d9d703d6ff33f85780e1685fcfd566b6cf8baeee29da6c2", "0010eea600e7cd2ea5f52dc9df4e0e6bf2afc6aff1bf0495de74331d3dccd977ee635c96bf45fffeb82077beb63fca5ba88daea4ef39788cb6dac0f5fd3dfcfd", "1250beddf1d44b00694aeeb64faa343532f9c9ced8ea89bef43a25d1a3dd21ba24fc054cb224f7cbec4089deaea860b491c5f9200c4ecfaec601bb0bb4a4323d", false, false),
(22, "{Wp80Yd=dQax:;hbX@@(*{H:~tHtZVy'hzXF% m7Jo6r`-72+Nn*tY [+3R(pu|1", "da4b2fbce8b5ffbdc3ad7e9eddeedd3ebac548a8b7c6328d924afaeeda8624ae35dcdd37cefdf9ead1f4aa5b76212b4af2929dd1790cafbd9aa6e8d1a2c51a55", "5dfddc3b44c8a4a1fba051564640daa6ee7cefe539c77ad98f50282690af42a7c9bc04fc7f8ff4743144fead325ac5c82a6d9c9fef4702c6aaa2713d3311e6dc", "dadebdede7abcfca430db3e0eaab6d9decf2d9bd9b5ed2dcbfb5dd2aeb6fa146e6dbf3c35aaebdf8b9afea8aa9320622fada28c4cc202a39566ea24b81ec6398", false, false),
(23, "fQEx[{|Jx,Rx&3Nln!~pYx<sIM:)-00NlW#20+%V}UBn1KTInUB8b,MO5zmj[j{+", "cdaa56a5dea0dd5ce0bdd78de81ac3ad2b5bf90ccaac705d0ba6f629ccbbbd88c6c8cda415fc44e2ba723bebedb9434faca431bfa2afec1bd75d592fa818c031", "f7da7c28fcf53fe8c8155bee1afcb203463dbb559d226c9c19c6ac2bbffeefaa6e38dcc404b14ea4883f7c82ab07b4ce34dca9deba8ebd9faa550ffdbe7eea8e", "acb252a973c15cd6ac26d9eac5ee23197e72dfd81bc4020e7da99a4c92ec1d2ba482eed603dfffd21fadbcc049e6aea6a988abdcc2327c0ef7cf8b3c3dcf7b5f", false, false),
(24, "X#-+Wjh!!-[[pF2aIHV)R$f6NJK<:(sYx&aRVS7Nr:P#wLl+dkAQP4l_!';1`,lr", "1ae322eb2bafe2bc0bfc16ac6ffbb1cbb51cfdd3121c80b8d14ba8e76a79fac12af29bcc16bad0d0a59a692b30bf15e1bbead19f74d0da32b51e0cb51bc9c53a", "a70cef317d60ad0e757ae2a736a6437fa1f5a26acee793b11a8452caffa81ebc04cfebc6d1aec28a71f2b6d5bdfbff3dfb6be2f9d9ffc837bc7cb9bff02dfbab", "3a4346c2bc3df1bc47e9cddad84b8b2dbfb0fdca86c8518e7080d6c1443b9fa5d44fcfa8bbaeabaa9ce24a4785d8a7d4dda0e1aadc7cbf07e0b8b8b53e6635de", false, false),
(25, "z zF?Nk,!GhEIZV7+2;WnUIZ6(u|Ki/bJ^fot2z,/jOV)lh~lRBv/9_^&,8;q?4H", "ffbadf58203ddd6c24a24bce5fddfad5df64fc8f2ab9203f605cb2fa7074b31cd111ebe89bf7fbbdab3fefaf516238d4fcdacb4422d33af4c6fff8460dbfc925", "ea2bd968bc1e0b2fcf708e88daa2df2261edf90dba7c76defad8dd8e22af4a078acd0c768fb95fec0bcbd3ed1ea57f0d7a02bbb0e873ee4b85dcab9d095c2aad", "0ee9f56e3e8847bbf3aeadbe5effbe8ec0aa33ded11eba92b3b905dd7dc7e7214d863fbc3f4ad61aacca6eddd24801dc0de30aa631d5badded4d4f42dcfa50a0", false, false),
(26, "_zx-+qT1U4M:ysC>jXX?KB:_#`0$jD$LK]nV|IJrTx+7Pu$cn@X<KG[#Vxsn,9Zn", "42afff5c4648dbbec0bcb64acc94deaddc7b42fae0b6949468c16e845cac8a3d0cf5f3530aa32542bb0abb2ac217362d58bcefdab892e52a5becedcfd9b6b8e2", "2fcb803add3fbc40281bbb2442ab46f8b9d47ebfaabbdeac32ac25a0eba2ff3b9db93fdbecc20ccef6a2ef932ef1fbb9652afe12df2a48fe8449cd3c767645dc", "be5d09d5eca4c6aabdd3f3addab4608ba9a0e8bfd87ed0efe9a3bbafd2cfb39b51b1e58dfa8f7d96c61cd079d45c27dd73f1a74ebbe0ff1e7fa4c74e06fadb9d", false, false),
(27, "1'nNo3/%Gg6g+w/Ph]CKxwzc<=jvj%(*g4.a^&HCC^y69a#6p9`M4>TMi_%>J}q!", "a466f1c3feac3d9d24fa80daacc99cda048c3acf34d597ee1dbaacfecd03eaeca5b134a9322c9fbcf69eacdbeaeed81a9633e5ce8f082c3328ac170f9b47c15c", "8aa2bdc7bc590afccc912cab1b3edc8e4ae845beaa7cf9e17a7e3cd73d6de66e5ce0cda97aacdb45b90dd5ec4d1b3041d9dfed397ffe9dae8a59ea7b16d0a2d2", "0bb6e7e7d2e3dee0bb6d63baaa72fffca8cba1fff8eaa1cfd1932ab4ebeae5effbdc6aacac250e3f7dbe2b0e66ffcabbff67a9185eec9ebdd4c4fa4a15a8071f", false, false),
(28, "jBNII5V^?NK0NZ=hoNPe8~PL*d` )6TrvkoQ1o;BN$A(J,0fQ*=41mo{+dUtY[H}", "b12f3eeeade0fe6f159cff5ac953c8caa7b6e3133ebeabb02f56c47a3a6bebab08aff8a30e4e9f3ffdfeea29add166bcd6cae839b902ee6c8c9ccfa312a630a8", "3fa7c54312bebb0fe69257c74686d67bfa06fd8c6cb66abddf7a1e3abd484d2a8d47d5c83febd7c4de342bdaeb313773b572cac323573cf981dda0f485021ade", "6deb98ecfb3e5ce24faa2fdcf92ecdfad14b92f13cd30cb8fc602c3131ace00afc8aceeee131ff06f038c03c81f28247fa245d7bd6a5acf1c91a9204e0e7c25c", false, false),
(29, "c$iRtX){-wB@i(8=5zB]Zvh$A`o&G*j!Xj0vtyDhZAAi$bzgI6^Aq4}qsJl4@|Nu", "baf6aeacefc0ed65bab26ce0fddbb7285c810e1c37e7a4a5a5e2b163dbafeb3d27d3c40eb4cda5d748101adb44d850fa77adbce8ca55a9e0a280f2e1fbbcccc9", "7784b6cdfbedd7940dfc3c12f15757bbb6e42e8deaff190c707d78d4b1dd050c043fd44ade67e55fe7eece74b8ecf5cf0b26de1993c1f411bb2dece0ef8eabc8", "4ca6adfbbf9d3cfa6350fde8d43f5c7d2dfdbe5c7f02f3636d950badabd6ca85477a7f2fe7ebae6eccddfdfeea16b1ff2c9aafcf0537d4d54b07b5b1913ebcd5", false, false),
(30, "@d8>{2V7>U&c5K,Nr6>X'c8oRXnN8sIX5nA=<j9D#q0x_a82(64ta5~Pjukc#>&1", "b3ed1ffe828ba2248de7baa24259f60dcc7e8fafe19e358be392ccbd9e2aa8ff86c03bbd1eb3add4d4f89fbacd2ee4a0e9de522b4e9feebeae8dddacfcee0fbc", "b11df79e6acab3e96de05ba25b5d4e2ffa3b26eb5a03ab6eef6eccb3a4299224ecbce8f5f2ac3bbbab5ea8db41d7f1ebbbbd2fbe52af0e7e55e9b6b74203bdbe", "1bcd681265d60ccd5f7af6cc223e0d5afd3dae4cd5ffa21d4658abaccdf5f0981dead1dfc3ce17bd90befdf90c72122bbdd724d8a4a8cafda35c54f6ce1fd4ae", false, false),
(31, "ryru/@!Ee+zfI[+_QI/ `~`c+9<JirNU$*w<[)jL2pe9EJ&.Ak5o1-k@1Y~INZYR", "c846ec590e535a9f35d9fdc3fbbb9ce0dcedfc26c6d7df5eacb911fd0590bff8856d25cccf6d8ae3a48e23184f42d6a6faaeebd9cb8474ecd1cf0cd0e756cf0e", "338d1e97c23ad747bc1c627d27ffaec9f2525c141ba6f4ac01a385ffdc7fc6ca04b5acabffebdd7fa4a6dd4c45bbeddfab3bc651951dbfdce82bb2e4711c8336", "212afbefab3234025081ae7e7fe6a4adc29ede7bdb5cce0e2fad1f3d2b6efcaddabde8edf83a4aa76fe629faa53f36535bcc7caafeeace5ebbf925ef4679f2b1", false, false),
(32, "=P|J%o<{=D`MpPFE&LEEV?5HCv-Y6{7j1$7`2?i82O&kua?p(=~{L&`Y^Qx+B&aZ", "d808f4a099e7142797822b3cdc2292b09a0c9d5c71378ec2a7ab12d4cff35591ffff95cae6d7dfc921f8fdb10e3cd2f4ec04c167cbae8ab6b9a1dc1b1bc3c7ae", "1ea1cffba2ededb1d6e8c5f1ca9f199b5eae4fbebe5686350b6c48102e84e80cecaca20eb694ee0c270b1c5dee0c1c9cdbcd9dde49e37c7eb2319fde1eeb0d8e", "e3a8960c4b2afa64bfd7de5be0eafd0abe403b0b9f227e228251f3fba8dd6a74530d1aaa7f4fbccbf5fdd6caca9eb0590fea0df139ddae2f17ffd57becc921ef", false, false),
(33, "X:`*~[Z>doZED%%H']0cA[es%x)n_=eWl@xs%o5]_HR`{ ?wU&JH/09 }SF&oZ=i", "7f0bc783fdcf08cdc4d02d2fa3dadbc4eb4a92aebe68d13b9d5d6b18ee9fdbd52ffb79b8ebb13fefc296159ea774a33a7204d4aa2dfea46c270e27fbffdf7ace", "8aba1fc4ec16a5780b3eddbcb8f164593dc04edcaac41dcddb324bb202cfbf0bd72de3af8fbe2dac76b35eaafc6b3bcfdd3af55cea4ffe8e3e2adc279ff4936c", "c42ef8c0b5386ccebd56bfadf7c5a97e0998b0f6648e7da1abbc5a9e947af3276d7cfcbfda268d374bb80f272ec3bb3c517bca8e2105dcbb3daa5b5b8adb2bfe", false, false),
(34, ">qk]'{xLwGW)}8VA3P1z6I 3muk#nmu rW(4SybP+o39q]66w~UINb|u{Dg&Si8^", "b44dd8ab3cf5ae4d3f0babcfe1fb92cfbd8a01d59a1aabc01ae25efed0aedeb7f4fefb1eff655de5c75c9c0fcd78ae9829069d9c134a5a3edd2a2c122c7349a9", "bee19e4ef6fa066c4eccaf4aedbd06e9683109e2ab844abe54b20f3cf0ec1c8c5aacea6b061db7607ee4d7eefb013fbb0bedcff5164bebeb6eaf270eba1d9e09", "032e3ff6bf4ae61ce2bc7d05baf10bc90edeeeb4de37a37aec4dd0a4bbefe977c6c96fc29d03d2cdba29f196f13ea16dfb56dba8e51e9ee9adfbacef1bbb13ed", false, false),
(35, "j  ndfS-Va(?R(rdKqmS_t1UJ&>WeT+ ~[1F|DzSyJ1SISbakSiW77%W|G=2]m^`", "aabd3da5aa91eff9baacc19cb4882b0cb58f9b3ff2a0edf6acccacccfcdbc3df8b95f7cfd5de5e5fd001ef3fa4d0cf2a7f37fb49df8d6859b9acb11ad55304bd", "0141a8f5a93e2b0c872ca0c98dcda1dbd8d8c9a1e72f54abaf7f54d60fea95c53f6bf953b3ea4898b2d66a4ce27fbae7c17dedead3dadda4c38f22ce5bf5fffb", "299b2fb334af9f3deb84bbaec9d074d756ede8bfd46b3af5c701688d6eb0e23ea85ed9be552d7fcfc1855f450c83dda0f4f77ba61af6e9330faabc90a4ca2dc7", false, false),
(36, ">}J=%k+_+v$.yFrFh=Bq?R,.3:UZ0bV4Z%d7tH{PG7lI}aYz,`tFyGO3fA6xbgg(", "8e6a42cc0c9f8da20ecd9e40caa8cce1fbf06afd7cfab6ecba3e655f5e39c6898dfeb7cabdec6b36ed00adda1ca11f9ee67d7faef2db664e99e2540005b2e3fd", "e302882486dcab579315bbf62fa8cbb84b6fbaf00780fafeda1f99fa413749eac4f6e4e2fdeff9a46ef619ccc4e7e2359d6e838f0acd4ac93bc960a5847387c6", "bfa0de3ab1c103e77bbad6f71eab4dcaa7f14bb0bed88d5e35f2d0da2e8b3198e3cbaa709c36ec1d1959fcaecbff9ae17abe9bf2e84da3cff1ecc2b392bdecca", false, false),
(37, "F6XE{:V)^Bv1P32jh<3d2HB_XOZ0yZf$e(~k]whvnyBY4>5&=&`sMSb4` &O?hh|", "deac7a445ca3dc5dafabd8db3efe7f403b177db7feef779205f1a9ec18cd39233e6093cc1dd5bf49ffa5ecd8ddd2f83f5f4db0f6fc8ba83da19daef9dbcc5f7c", "8fbea70d3c7b2aabdd3de2e729a2f02fdccffe8bc9bc64c414298d4a2fae5891f6beb75b9eac0a8fd4b3eaa8eacc265cc005f3b3cecbf8fa0e9d3877df7c2a3d", "a75ec94d195d22ef56d00b03b4cefff0bd41bccd4edafebdbbd6facfce698a14bcdb18b8debf96cfa2130cdbe74bf5e7d31ad9561f17b6d17d8b1b7dccebdeeb", false, false),
(38, "Cn&K~fw(rAhKa<5487O:M>>D3Z`@PCxz]8(m+O]ugW5H 3=o&]7_^]DCoI7X}7>x", "a26c7cbead7af3c56debceebc921f9edac63ccebcfebcd7aebda49d3b6cb2ea134bc2c8ffd9c4ef131dc1fad4b28fc89ad1dfdd6cac0ef241c1accbd436be8d2", "b07b9ba28bbe581cbf7a9d030b225aefca5bc38d58ebfcaf1125b96866ed5c7c7fd58c90d8af7a24bb19ea1920ebe54eddcfb86f9dfaa663b29f419e585fcfd7", "259b99a4afe813c579b61bfeb2a9d2c3fac75a81de7ea2caafe8f0c7d2ea6a5fd970ac6ae25b70dd962d0ca13b0855acb1eb86a0c7acdb70c2350ab747fa1bf3", false, false),
(39, ";gGz6/aT]+ YTzHEa}a&9:6t6v>nr~Q7ePNDD&GIQC9=q @XZsK8!~BO98&psw'n", "2fc1499d0c4e63374effe96bfb17bbe54b6baeacca2badb8c1b12a59ffeddfb8b8fd01e4be427fb6f94fd9f6cd8df4b5e2de4bbc0d44a73aec4a6f6cc67b0dfe", "efab14c3b3efe4cdeca0ba7cf568d3bd22c96dd114fcf3b37fad106f90de6bfae2aadca9abbc84a2caaf24afee16ae9ec7f2ae31d3f0ce4d54a2beb94fcfcdf2", "9afdde1149d65595523bea7c751c357bdd11337f9ad5df0229d915cbac3ae70099a2bc0216ba42774be7de3f2a7d7be5246fb0daa2ce45f2b10eeaaafb946bff", false, false),
(40, "x#LlqjFc8}~uc:8b@xlv$qmas-Ie6}eIcm?d[QvO?+ni~n]LTa*dha?9xo8Kjn(i", "e28d6fdcdc4025a9e3ea83f12083cd238bdbcbdeaafc590701bfda8e827b1e0b7713efa878ae2e8d2b03e3badc3aeb64e03cbeeedd5a8ccca32da2c8da0439bb", "013aa2280faaba9d8ae9bd154e20a8bbab7e8ae7dc34e89f7eea7aeeddcd6b9b85d4aeff5fe033cebbce790c938bcbedfc0c0ea669a4515fccd8ec59f774fca8", "0bcce0b000fe17e1fafab635d16dd92b50a72161babb0300eefe10337684c3c4f20376afd5a347d8c83e0eb48e0c48f2be5e93d7b19ffdbbbeacebf5cbefb57d", false, false),
(41, "sK#EruMbn6B/dyF1<5OY-l9s{ge3s7&LWhyg&j0&ZUn]%I.[lq&k~6^Pv*TIlv3C", "ccf2c8abef67576a8cc3074e6bd8df0d93ad9ba8c5a30fcee30bdba44bea0999ef729ca9a5ef86a2b0ac9f0aebb1fd4bcfc2b89d2fe9f08c8e7c105a6447691a", "75dfa49af76b8d81c6a758c087f1c750bdecbfbdca51ad0fa0dec73b14d86ebda5fddf4a0ee4bc2c0dcae9d5916a2ba50664ba5d2009b4a1fe9a21f9351d8e62", "5cec5bc3eb6af2937de29f497c5fbad2209abc18f471aeec36decdbad7b9f8ba650cefb13baf5d9c0bebe6e5faed3ebfffcfacff4b1b6d2f8a8a0631f8beccbc", false, false),
(42, "568?b:[_(uP#o2#qOiRp0z< Hl(&w['t#d!L]YJ~Xm,~rhLyx(_BJ)l_;LHj[nhs", "177b10afbb74b34da79d1cfe454ef3bdc47cf353ac922db3cebe9ef1fe84ca6ebad0f3f1e70cee3dfea700e2fdecac6f9d752925c1e375daba4fd7e0d1bcae05", "0c4beec37a7db62d626fa29b2fb3ab4cb9a23adca9a72c073feca43f2e4f9af1061cbdd650b91e6dc2fe1adcf727ace764fc40f7ab3c8373c7a3e7d342fc1937", "7dbb7e1e1e4398ec184ef51ff3bfb021eeaf4afaf55e9b6d97fba5fa1cd8e4bdd0d67f57bf8b21cddd4e52cdabad1c3c2fac6b27bad451638c2493be079e5593", false, false),
(43, "1v]-3{|AbYdq =^*j4{.uaDJz,>>+q`HFPqT+A%zw=dJr_XAASF2tpf3|h?lyXI ", "6c55c8faabbcd7f2fdce1abeedba172ede638acc2f85bc6aa075b0dade6ee1475c79be443a08c9e2cc561ec6bdfda7df0ddaceb8d1f5fff0b1c1baee4db79da1", "da5dc9784cef666ddda70dbcb972c65405459d8fba539aa63ea8c994db3a9bf6eadf147a3dbc200da3bebb88fe07c4e281bef9abef901bab9a0f53fdd3ce8fda", "aaadab4a60b3e1c8ca12aa2bcdae37c9fcdbde265981dde86476ebb0a5f113acf90669179c6dc7ede3c3e0e8b0db4aacc79114feedcea9e602ba34ead0bdf12f", false, false),
(44, "Uu_).qg+]o-;OD]2#cnD/D.&vn'~Ft(igO2&DAE78h%1e[(h3 V Un#FBGaCx#%S", "d6f925a8b965139ff5de440fa7ff0a0da6a2a3fa1564b7f1ce1cb80524322c32c1bb5a72c1197a3a38c34bec00b24b8dadffcbafc0fe8aef1d6edbccabedae2f", "ececcbebea7dd7e5515b46aa2eec3de5c4a0508e1aff5fdd4bbae300c0f66d5a58a934fbcfced0c928afcd065abddde3cfc0a068f74f61cccecc6f61b3b4dcd0", "d4e6acbced4eed6f47ae84f020698bec15ad79efe6fcfa0bdaf8dbede8c2ac95b8f387c8eb96f661b62e8cbe83ce86a58e8ecfb8fca4a1e8d0ea4fd4ecba70ca", false, false),
(45, "mB{M4-U`z2,hRUS!0~Tjq`=}1#]},RY0-CUFA77-w{O{3?`nAV5%E!BQmbJE1+oa", "41bab28ff7cbd6ae3ab6effb6afa9b6b9f40763c5e9bdec4587a9ed77bdbb17f7de45f3f35ffd46598afc4bf00a7ba80c38fc088d918c43dabd5bbe41ba7aa4b", "155b6d75e14c8cea9ffac829ee1f9edb0eef4378f1e37ad757eaa126f45c3ec7ab5804ed62bafa87a6aeb15f59bd23c0d9aa2dad3468d06cb7dfc4cfcbb6a02b", "43ce3e7bcaeee21bf2fbfdc3fd7454de09ad0fc04ec190b0b4127e0bf1c32378cbf8ec22af4dd82667cfbc8b4003574b73f5b6ea51f72eacdbca24ffabd2fabd", false, false),
(46, "^V4Df*%x4&$c>c!CQ%NBUXQr0w;4$Pfh=N#p/Zaq'>vlKy1BR./h+U?Ln)1uQj'4", "74c2bb1ba6b18c82f1e6dbf1ba5f640cca61d5cdec71e79d66fc86a8e99bbd8aa2ab5cbc2c8f6ade2fbe8ffff7da70eca3563dabca0bcca0ecf79a97fdeeefb9", "eb88f262aeb7d9d1a2ebee9befd21cdce5213d50ead8dfacab5b9e70de3c8b28c6d410f782cd52bac38fafaa6daef70008eac6c6e2bc537905546d63dee33da6", "ad17dac299afaeba7fd0cd071ddfd0ce2a36dc42badc3d6bcb83e11e10a7bbadbe27bbaacdc2e0da1be44ea0e039a06eabb2f876385232e5c9bbfcd8f296d8cd", false, false),
(47, "~:/a_;{Z7BBL#Ebh1|aF;gI<%{M-3FFFW9$'Op~`?&:ra6lB GMziFOF~73Er8MJ", "70dbc20cd476e1f8bcecdc22f28f5a5a1399e72de5bdb1de6ffadd0cd727ab3f6769957b1ee84d55d693df2de3c944b4a73efd5573ae9cdfe7a4e7ee1a0af04d", "32244bfba3175aaeaee67fbaa2cbe8ce03faca1793c0b73cd23ba3ac7eb5bc7ef2291c62d9a5c2ab7e2332182eb6fd9a31a7bc4ab0d5adbd39d18a301dad7820", "79ab2df4ce21f36f293e90b22adef7deebeddc1ca6ae1b45d93dcf59bde9c3deddc16c088ffef91b67fddbd0eefefed73f2cb2ffdb1f504c8fc7eba6fc6eddeb", false, false),
(48, "<_r}1EN=u'%lchjeoen90VM65*c-(DiH'^Y?Z&zTykfN.'d,I&-nnyI3^'W4,;_a", "bbbcd6290c1f810fad8df1acff57cafb716807aafedd7e1ec14bebbe6ffff2d0bbc928569c94dbb39ff14d6fe52c72b0fca1efcff66ad3cbedfa5aa95d9bf095", "d2e00f5dc6546e3ebebdd6dc26ffc0dfdeb3a8977aac96dc5e168abbb6f6ebfef4c5724b374d9ddcc3fed48717353dcde75bca38ee2e2c5f2802cceba470ce2a", "ef7ea1f7d6aa199b7c3d5acfbadb6dcce2e5d0ef8bd40eeacac0cc72aac2bebdd3610ade7f27dda4e891e11ce2b3baefacbab9f232af07c1c7a7cd05a971aedf", false, false),
(49, "!N<(;Rn0 ~'>s-]L%[y_2^rQ @=!wvVGvc`xWbs:BR^>o?mS1J80fPs9B)a8DJIT", "cafa17dec8055a9d0e5e9b01ba0c76deb1b4f7bd90bdb3ff7820873e45c9f1becf9f94ef3c6b8cda2fe6dbdfc5176ec63e8d2efe75ae3e7bad1983b91dfa51ce", "d0feb92eef75f19dfa9bfca040ec268b83efb64b2ea0e301a40bdf172a3fbdc48d0a1ac7aad2cbf01c85d1eab9fe001d06ab771ed2b3c59ddbaefbf5964caeb1", "f5fee6ca8b1eab7cb965dbbcb2fcc60e46608c3acf90b0e6bc84cafec5cce854adb2bc3ffa6caa901bcab4ea90cb99be36a2fa63a4ade7f71ca80d4ca72bbc68", false, false),
(50, "O>PGK:,[|C?il5ME_R'%6Y]]rZ(%p75rPwiCy),ni+/m'{hrr69fRpP14DXD=W$O", "1b39bfcbbfda8de54a53f2e8ebaba6aeb55cdd4424e22c1ab34605ec5bd818a7e2dc50131fac198dad2c0542a1a05f34e69c71476237ad86dfb09ab204cae3ab", "a9dbafb03b6febb7b024f64c33b4fa413a2aaf53170ace7a9d137aeeb71d465bf509cbeab3d3c748aedda87ed8adfeec2fa530cbe978533a3fa38cbfd4003aa4", "ed9bedc15c6dbed08b9ef1a6a7317cbda9d6f389c66dbad8d397fdad3edb79a37dcf1faed056deada26fedfbaaf1a8ba3deceecdbcf7ff258491ff01b283c954", false, false),
(51, "2^fbIvJ/oy}zVPaPbw _=* itg:7E}/7l7lEmQ.U-mtyFy BN{}VK9ru(yZK#wFV", "1fda629a309e1ad96becdee07de2bc5a3b79b2b7e3eafda3787cf23b27cf7cfa8a0751cd379e4ebe4f4dad0da8a5b5e01e47b05caa4fcdbbd5f8fb5bc9dec5a9", "8dede83ec01dafc9d444f58cc1bdad0b4c00e1a9d8b3dcae6c61dd069ceffe7c4e1f96a2f4d2db9bcb8a7ec001fab6b6a31e5ab8cdad44ad4dcdb03ff4caacdf", "33a22be01cedf84a1ad5d14ea1dd070a5c972dbe3cf3af0b6d7c3e726d9fabeb8cabcdad8a0c6cf18019afac7aa8bde0fbf9c117bc79c4dd2b0aae31bf21d0f5", false, false),
(52, "b29L I2:x#/697I~>dG4?lpV<<<KLk~&f2g+@Gvnv^y)$Ase{JdOL<{LqL}}#d%P", "8a2deb96dd79fd006ffceaf4c5de78b5dfb9b932df5c1cdfea1e8f83de577cf41acbc8b7cf107590a88abe506add1b71f8e4f4b3e1dbad9a0dcbc871aacd70aa", "abaebaa04d6a4bbc73e86ab18d89fb4eacbbfc8b10271a7f93c6ecb01a0ce61c0e715dfecc73b28c1f07c53814dcebbed5e92fa9cf551743fffad6c8fea1fce4", "bbe700d5e372f1402c6edfb24de8b9939a67dee0adcdbba500f0e1e8ab377aa15ff303cf7bcffc1dd6bda4fbc0f3bc021cb1f0acd095cbd22dee4df4dbfca585", false, false),
(53, "GJ5l,[in4_{ uq_67X4v ,UJh:H78]r^:9q62IE^rLa{b!mPbZ]L^~w0/l[m]5o8", "28fdccaae5ef6a45a8c9acd699efcf25aab32f4bb3cfb0fe2b85f9dd8a2b5fa8be2bba5db871980ec07ef2ca136cfb4dc84cfbd4bede8becae4a58aebf95f025", "f11cceb395fcaadeef0b0ab36ff87d7ddfe65cd266ccfd5d70c7d03d7fbfda9cb2eff78cbeceddbafee7caeff2ddfa5ef1b2eed80bddedad5ce6cee37aeecdc7", "9e48ec24a2fa2cc9adf83fdee497c6fc1ffee9daaccca3886f80a3039481dbdfcb5d5bc6bafc6a3f822db9fed33113def5ebdcd1075f3ef1b9aead9cb511bd45", false, false),
(54, ";ql';01[*lwdx(1a U 'NQ|IPusip/'IfeOl`hFs:20wH,0*B'>E+eQHuc13PgXR", "24654f721c09e6bd051d39eee2fdf9f86abbdbd5d92ffbd3c4db5f1fd54fdb9bdc27bfdbb8f8d87a98a01be73b5efea2289053d4be67f2fb9cf1d0c995bc7fd7", "0b52e3dceac2b0bc68faa664bd03367fbf807fc2efe3fcbe0cdfbf4a86d9dabfaf73aa4bddcedf49baecdebca9abab9ad4cdeaf8e7bf5cb1fb1dc68bc6ebd474", "70f9e7c7dcbfee9da9aafd682f5c2cda7cb7d9214c2c97fac8bb35cd683e83ffeec5aef150dde3e2a1ae3bbabb32d8cceadf179da58cec357f9c2de3bc42cbcb", false, false),
(55, "]NAaRW!{~Q*JirED]45eIYT/C%,-k7=xNO`)|)*_Rd3~M3s70[$uhppZH[D:Yz!a", "ece55e9ba4f1ba9d3daa965f2adfddbdab72791f9a8ac3068beec2fe37cf8c735b8a98c1e70f0ecc6f456cab8beccce6fe0fee1a4fb6bc9a4fde444210d1a458", "b3fecc6adebf3be58f1942cafe22a3860bef8fac6fbab1c38d183f3e8dfdf0646c0f9435dea3cec5c3dcb0337b619232636e8debbfa79e7483323ebf5da72365", "c0ebfab716f56ef18b7d7354adeedda83099aac0e38bf2973abcccffd3bfeec388b409f24b7cd129da87142feefd5e7b1c7438f5c0edfc907f4dc2dafdbc7ac3", false, false),
(56, "%|sHq8V^HV~sH<2LOE7p)@gSxD#+H8]f~d[d+%/Dqy&4SQ=dgL@AUqYe7+g5Pk*4", "addb6acbd131e059bfbd36f992f1baaedd8e3bd5df389846dbecca7d6ea789de78fdc1f5ff6fc933c616f0b2bbbbcdd6ffe3fca61b211c140cf6f6ccca787a57", "cf8d2243ae1bb488aa7c7b3ac23681db9d4ee30b0b4155883bc165eb40a3b6ddcecbbb77f9beb2ffee9a457cc07bb133dc1eb54ccfbed07ea85295dfc242e257", "70cfee6a4b6309fc0fdfd4c6eb50aa727cff9b9e8d9fa6937cbacebc9dbcfdcdc0fec7645cbdbf44dff5f14a3dcdb4dec2288cba16a36be78a94dd062e28aad0", false, false),
(57, "hBON8.@OoBLH7rps,|;VCSp,sv,9ZzK#u1upLpO8O^a}_*<8TY,7jkayCkv?qP&]", "4fb2db3f9bb7ea98a6fef7acbe4fd990fe5473a3ebc1c8cedcb438cfabe0264dcb25cd796de03595c2d58c338e4ff1456cbc022778ded9ebcbdbac3542b24ee7", "73b2dee45a0daa017eecda2c3a6be5324ac80eac228727d83ba096afcd3dc7d5ec3c6f9f4acd41f03da9ff0caad96aabae7a3aacbc1fcef89d1076c4b8012cfa", "e8cd03f77cf8fb90fd2dfc4e18ea920cbcb7ea7aa6eefebbd62b1ee517bb65e5cb2e0482dc1fbab6ecbf0ab8feabbcf0ee4ff9316dda9ac4402be6ca5dcb8c4c", false, false),
(58, "#qHYXg6FEZ|D)05^zu2(XhB7]dJvdR`]w|5tW.=*%j{c%Ba*C0Bb;b^=kXmTjBa;", "51d8d1baf7b4b283bb6a7f51ef8187597046e6daabe0641a9d1ee8be8eed4b336c7260d3dcfe3baa9ce5c3db90de3f62ee3d0afaffef01116b68b893bdccfe7e", "6acc2d9dc037ba8ba2fe5dda99a258ca5c940aaee7439a7a8ccbd1f18fa12c7eefb2bf1d5f7a51beecb3efeefdf37b8639cddff635ebb9f27a60ddaaf06dd95a", "3fffd20b9bed2ad9bdbd2edd78ddee1e743a9e0fe1c1f9eedcf9aaacce907f19c3cb834d6cbcbfdd5bfbcf95d5f15e25ff9df6f2c2c6e7f73ba988e63c38a3fe", false, false),
(59, ";w80uBW{{0Kv'v2AQPLN`j4W3'1V?x<RPi28i&3EgzJC2Ed%OnM{x%X]sQ@+3>Ba", "0ac4cb80c9a9c16ce1b65094f3f6afc17be8c821aad4cdb6fc2e4fcd23d4cb6b5a206bfa77235db5f5f00cafbb8ac94deb4b5d887f4fc3ffbf96dbddf335a52d", "a33850903c6b8fede9def002c42dbce7fd2f9660aac0fc5dceccfc47e64fb09a10e37ab0be82ab7f51b7db3eb398c4abfbae6de30a3fdc7e4d47508ed4b8f72a", "e7cabdedbabcf3cd0a6bddac7ad7d3e7eb5fbd1faff7f9ac5dcec3b372ef91c9e22a855ffe7ce09aad9bccaef5caa3e27a1c71ba3d35ece6a7d3ce2613d06ac7", false, false);

INSERT INTO `account_card` (`card_ID`, `account_number`, `card_main_currency`) VALUES
(1, 18, 9),
(2, 3, 12),
(3, 2, 3),
(4, 18, 11),
(5, 14, 9),
(6, 30, 6),
(7, 9, 11),
(8, 30, 3),
(9, 11, 5),
(10, 24, 9),
(11, 30, 3),
(12, 19, 13),
(13, 14, 5),
(14, 20, 8),
(15, 1, 4),
(16, 2, 7),
(17, 1, 7),
(18, 30, 2),
(19, 1, 12),
(20, 30, 8),
(21, 3, 7),
(22, 19, 2),
(23, 26, 10),
(24, 26, 6),
(25, 6, 12),
(26, 14, 7),
(27, 20, 6),
(28, 9, 13),
(29, 6, 9),
(30, 18, 7),
(31, 20, 5),
(32, 18, 3),
(33, 19, 2),
(34, 24, 4),
(35, 23, 6),
(36, 30, 12),
(37, 23, 9),
(38, 24, 2),
(39, 33, 2),
(40, 18, 5),
(41, 24, 4),
(42, 20, 2),
(43, 20, 13),
(44, 6, 13),
(45, 14, 11),
(46, 30, 8),
(47, 9, 7),
(48, 6, 4),
(49, 14, 8),
(50, 11, 5),
(51, 1, 2),
(52, 17, 10),
(53, 9, 5),
(54, 3, 10),
(55, 23, 10),
(56, 19, 1),
(57, 2, 6),
(58, 2, 6),
(59, 9, 10);

INSERT INTO `card_daily_limit` (`card_ID`, `limit_amount`) VALUES
(1, 313),
(2, 87410),
(3, 10925),
(4, 31584),
(5, 75375),
(6, 77941),
(7, 85886),
(8, 86681),
(9, 64055),
(10, 40025),
(11, 18143),
(12, 77507),
(13, 54739),
(14, 41850),
(15, 96269),
(16, 55454),
(17, 71473),
(18, 92427),
(19, 81320),
(20, 88632),
(21, 86667),
(22, 42895),
(23, 23810),
(24, 18390),
(25, 87997),
(26, 63032),
(27, 76331),
(28, 18331),
(29, 24972),
(30, 60745),
(31, 42726),
(32, 72496),
(33, 83142),
(34, 30668),
(35, 60995),
(36, 33293),
(37, 75409),
(38, 56130),
(39, 13717),
(40, 84152),
(41, 26587),
(42, 72705),
(43, 41271),
(44, 88417),
(45, 83057),
(46, 98133),
(47, 82827),
(48, 28029),
(49, 55433),
(50, 33162),
(51, 61111),
(52, 9168),
(53, 55475),
(54, 58404),
(55, 3375),
(56, 75737),
(57, 92875),
(58, 94886),
(59, 21517);

INSERT INTO `bargain` (`bargain_ID`, `amount`, `currency_ID`, `bargain_status`, `bargain_date`) VALUES
(1, 4218.39, 12, "Pending", "2021/2/10"),
(2, 9508.85, 1, "Pending", "2021/6/27"),
(3, 2176.44, 13, "Succesful", "2021/10/9"),
(4, 670.76, 12, "Failed", "2021/5/28"),
(5, 3935.95, 9, "Failed", "2021/11/8"),
(6, 1192.81, 7, "Pending", "2021/7/27"),
(7, 5378.13, 12, "Waiting for Date", "2021/12/13"),
(8, 7063.7, 7, "Failed", "2021/7/19"),
(9, 7137.59, 8, "Succesful", "2021/3/11"),
(10, 8733.28, 6, "Succesful", "2021/3/15"),
(11, 2319.63, 3, "Failed", "2021/10/18"),
(12, 2553.9, 11, "Waiting for Date", "2021/1/20"),
(13, 6014.07, 4, "Waiting for Date", "2021/3/23"),
(14, 4046.41, 1, "Waiting for Date", "2021/9/28"),
(15, 9721.38, 7, "Pending", "2021/10/13"),
(16, 570.5, 5, "Waiting for Date", "2021/9/1"),
(17, 7116.92, 4, "Pending", "2021/2/3"),
(18, 1052.35, 13, "Pending", "2021/4/9"),
(19, 7021.37, 5, "Succesful", "2021/12/4"),
(20, 3320.22, 11, "Pending", "2021/5/12"),
(21, 9942.44, 11, "Failed", "2021/8/25"),
(22, 8461.0, 9, "Pending", "2021/1/18"),
(23, 6561.26, 9, "Pending", "2021/6/5"),
(24, 6396.7, 9, "Failed", "2021/12/27"),
(25, 7777.86, 3, "Succesful", "2021/10/26"),
(26, 9566.43, 8, "Pending", "2021/3/22"),
(27, 3832.32, 11, "Pending", "2021/5/14"),
(28, 8581.71, 11, "Failed", "2021/10/23"),
(29, 7060.27, 7, "Failed", "2021/7/27"),
(30, 5609.4, 5, "Pending", "2021/8/28"),
(31, 4253.98, 9, "Pending", "2021/2/25"),
(32, 5207.0, 13, "Failed", "2021/3/21"),
(33, 8114.98, 2, "Failed", "2021/11/4"),
(34, 124.72, 3, "Waiting for Date", "2021/2/21"),
(35, 3347.26, 6, "Waiting for Date", "2021/2/26"),
(36, 8579.29, 4, "Succesful", "2021/6/2"),
(37, 3319.87, 6, "Succesful", "2021/11/9"),
(38, 4251.9, 13, "Pending", "2021/6/4"),
(39, 9945.28, 8, "Succesful", "2021/9/23"),
(40, 5294.28, 12, "Waiting for Date", "2021/8/25"),
(41, 3576.29, 13, "Succesful", "2021/9/21"),
(42, 8882.87, 6, "Waiting for Date", "2021/3/1"),
(43, 1610.96, 5, "Pending", "2021/6/12"),
(44, 2854.98, 9, "Pending", "2021/11/9"),
(45, 5031.3, 1, "Pending", "2021/2/21"),
(46, 2826.88, 9, "Succesful", "2021/1/27"),
(47, 3680.36, 11, "Failed", "2021/10/16"),
(48, 1007.59, 10, "Waiting for Date", "2021/5/21"),
(49, 9880.96, 5, "Pending", "2021/11/15"),
(50, 8402.72, 2, "Pending", "2021/12/18"),
(51, 7677.76, 9, "Pending", "2021/5/11"),
(52, 4048.28, 1, "Succesful", "2021/11/16"),
(53, 5892.25, 12, "Succesful", "2021/7/24"),
(54, 2203.78, 5, "Pending", "2021/3/20"),
(55, 3546.03, 2, "Pending", "2021/5/22"),
(56, 6223.91, 4, "Pending", "2021/7/3"),
(57, 6547.19, 8, "Waiting for Date", "2021/12/16"),
(58, 9192.82, 9, "Waiting for Date", "2021/9/5"),
(59, 8678.0, 3, "Succesful", "2021/12/5"),
(60, 2721.64, 6, "Waiting for Date", "2021/6/19"),
(61, 1286.84, 2, "Failed", "2021/4/27"),
(62, 5191.56, 3, "Failed", "2021/3/24"),
(63, 637.58, 12, "Pending", "2021/10/13"),
(64, 1128.91, 12, "Succesful", "2021/10/14"),
(65, 5263.34, 9, "Failed", "2021/3/27"),
(66, 6007.78, 8, "Pending", "2021/12/26"),
(67, 5375.49, 11, "Pending", "2021/8/21"),
(68, 9848.9, 5, "Waiting for Date", "2021/8/7"),
(69, 9881.4, 4, "Succesful", "2021/12/7"),
(70, 8867.42, 6, "Failed", "2021/9/10"),
(71, 2486.11, 2, "Waiting for Date", "2021/12/27"),
(72, 7122.62, 1, "Succesful", "2021/12/18"),
(73, 3370.52, 12, "Waiting for Date", "2021/6/5"),
(74, 6747.02, 4, "Waiting for Date", "2021/10/21"),
(75, 5157.84, 12, "Failed", "2021/4/5"),
(76, 6277.01, 11, "Succesful", "2021/4/26"),
(77, 4867.64, 10, "Succesful", "2021/4/6"),
(78, 2875.96, 2, "Pending", "2021/3/6"),
(79, 8425.79, 6, "Pending", "2021/10/12"),
(80, 9162.88, 10, "Failed", "2021/11/8"),
(81, 4710.3, 13, "Waiting for Date", "2021/2/6"),
(82, 6596.71, 4, "Waiting for Date", "2021/12/11"),
(83, 8441.15, 10, "Waiting for Date", "2021/11/22"),
(84, 2432.14, 3, "Failed", "2021/1/8"),
(85, 9754.74, 13, "Pending", "2021/8/22"),
(86, 7024.39, 12, "Waiting for Date", "2021/11/23"),
(87, 2254.71, 3, "Failed", "2021/1/14"),
(88, 5092.51, 12, "Pending", "2021/12/28"),
(89, 4036.41, 9, "Failed", "2021/1/17"),
(90, 7754.57, 6, "Pending", "2021/11/5"),
(91, 40.31, 7, "Succesful", "2021/6/11"),
(92, 9875.09, 1, "Pending", "2021/4/18"),
(93, 3887.88, 1, "Failed", "2021/8/25"),
(94, 7839.75, 10, "Failed", "2021/5/4"),
(95, 9602.07, 3, "Pending", "2021/12/9"),
(96, 4232.8, 13, "Pending", "2021/1/11"),
(97, 6795.57, 8, "Pending", "2021/3/10"),
(98, 6444.39, 9, "Failed", "2021/3/12"),
(99, 2388.47, 5, "Failed", "2021/12/2"),
(100, 8666.68, 1, "Succesful", "2021/4/16"),
(101, 2023.56, 11, "Pending", "2021/2/14"),
(102, 7832.56, 10, "Succesful", "2021/7/23"),
(103, 1551.21, 3, "Succesful", "2021/4/20"),
(104, 1419.13, 3, "Succesful", "2021/4/1"),
(105, 2843.45, 9, "Pending", "2021/6/26"),
(106, 2054.42, 7, "Failed", "2021/3/6"),
(107, 8523.03, 5, "Pending", "2021/2/10"),
(108, 3634.56, 5, "Succesful", "2021/11/10"),
(109, 4573.02, 7, "Failed", "2021/6/17"),
(110, 7162.38, 9, "Pending", "2021/3/21"),
(111, 4767.85, 12, "Pending", "2021/6/20"),
(112, 9856.58, 2, "Succesful", "2021/7/5"),
(113, 4209.3, 6, "Failed", "2021/2/28"),
(114, 9833.3, 8, "Waiting for Date", "2021/5/2"),
(115, 5844.9, 4, "Failed", "2021/12/17"),
(116, 5803.72, 6, "Failed", "2021/3/16"),
(117, 2132.8, 3, "Succesful", "2021/9/22"),
(118, 9332.12, 1, "Failed", "2021/4/13"),
(119, 8440.18, 1, "Succesful", "2021/8/24"),
(120, 7670.63, 1, "Succesful", "2021/9/19"),
(121, 2270.05, 3, "Waiting for Date", "2021/5/14"),
(122, 4178.97, 7, "Waiting for Date", "2021/6/23"),
(123, 2409.59, 4, "Failed", "2021/11/7"),
(124, 1168.74, 12, "Pending", "2021/2/10"),
(125, 6311.46, 5, "Succesful", "2021/1/9"),
(126, 4731.1, 7, "Pending", "2021/3/19"),
(127, 3651.66, 13, "Pending", "2021/6/14"),
(128, 1748.04, 5, "Pending", "2021/5/20"),
(129, 7517.89, 11, "Succesful", "2021/2/20"),
(130, 6982.53, 11, "Waiting for Date", "2021/11/27"),
(131, 9672.99, 1, "Pending", "2021/10/9"),
(132, 2836.87, 5, "Failed", "2021/5/15"),
(133, 550.23, 13, "Pending", "2021/1/1"),
(134, 6850.85, 5, "Failed", "2021/9/23"),
(135, 1874.7, 3, "Failed", "2021/11/6"),
(136, 5624.25, 1, "Pending", "2021/12/12"),
(137, 9675.88, 12, "Pending", "2021/11/26"),
(138, 2604.95, 1, "Succesful", "2021/11/14"),
(139, 8445.39, 5, "Pending", "2021/3/12"),
(140, 312.71, 1, "Failed", "2021/8/8"),
(141, 7921.14, 2, "Waiting for Date", "2021/6/2"),
(142, 1009.53, 1, "Failed", "2021/1/23"),
(143, 450.03, 11, "Pending", "2021/3/16"),
(144, 7409.45, 11, "Failed", "2021/5/1"),
(145, 9.81, 7, "Pending", "2021/4/17"),
(146, 7871.39, 2, "Pending", "2021/10/28"),
(147, 9471.44, 7, "Waiting for Date", "2021/5/4"),
(148, 4250.21, 1, "Failed", "2021/8/23"),
(149, 7378.04, 5, "Waiting for Date", "2021/11/27"),
(150, 7988.19, 6, "Succesful", "2021/6/21"),
(151, 7.34, 12, "Waiting for Date", "2021/4/3"),
(152, 5061.56, 11, "Waiting for Date", "2021/10/4"),
(153, 3167.29, 3, "Waiting for Date", "2021/10/25"),
(154, 9559.58, 9, "Failed", "2021/8/18"),
(155, 7304.39, 1, "Waiting for Date", "2021/7/3"),
(156, 9406.43, 3, "Failed", "2021/4/14"),
(157, 6408.02, 3, "Failed", "2021/12/28"),
(158, 5932.3, 7, "Waiting for Date", "2021/8/12"),
(159, 1572.29, 7, "Succesful", "2021/9/12"),
(160, 8540.8, 5, "Succesful", "2021/12/8"),
(161, 5916.21, 8, "Failed", "2021/12/1"),
(162, 9213.65, 9, "Waiting for Date", "2021/5/12"),
(163, 5369.41, 7, "Pending", "2021/7/2"),
(164, 3550.37, 2, "Pending", "2021/1/24"),
(165, 1990.65, 13, "Failed", "2021/12/4"),
(166, 1652.9, 2, "Failed", "2021/1/21"),
(167, 3010.9, 3, "Succesful", "2021/7/1"),
(168, 2970.8, 1, "Waiting for Date", "2021/11/14"),
(169, 7449.42, 4, "Pending", "2021/6/18"),
(170, 7167.65, 6, "Waiting for Date", "2021/1/10"),
(171, 5602.4, 4, "Failed", "2021/9/14"),
(172, 8604.31, 2, "Failed", "2021/5/5"),
(173, 2639.36, 1, "Succesful", "2021/2/4"),
(174, 6125.28, 9, "Succesful", "2021/4/11"),
(175, 6890.84, 1, "Pending", "2021/2/28"),
(176, 3949.5, 2, "Failed", "2021/5/2"),
(177, 5666.81, 6, "Waiting for Date", "2021/11/24"),
(178, 8304.05, 2, "Waiting for Date", "2021/9/3"),
(179, 6627.54, 9, "Failed", "2021/5/5"),
(180, 5213.41, 3, "Pending", "2021/3/5"),
(181, 1531.0, 9, "Succesful", "2021/4/12"),
(182, 504.11, 9, "Pending", "2021/9/8"),
(183, 1656.55, 2, "Failed", "2021/11/18"),
(184, 8698.56, 5, "Pending", "2021/6/24"),
(185, 964.19, 11, "Succesful", "2021/4/8"),
(186, 9719.2, 2, "Pending", "2021/4/9"),
(187, 2527.17, 13, "Pending", "2021/7/26"),
(188, 5582.76, 13, "Failed", "2021/2/20"),
(189, 5309.51, 12, "Succesful", "2021/10/28"),
(190, 2434.03, 4, "Pending", "2021/9/10"),
(191, 2803.06, 4, "Failed", "2021/12/23"),
(192, 5630.14, 2, "Pending", "2021/4/5"),
(193, 4309.8, 1, "Waiting for Date", "2021/3/23"),
(194, 4126.31, 10, "Failed", "2021/6/5"),
(195, 9504.84, 8, "Succesful", "2021/5/18"),
(196, 9807.8, 11, "Waiting for Date", "2021/7/22"),
(197, 6244.22, 10, "Succesful", "2021/5/5"),
(198, 5452.87, 13, "Pending", "2021/2/6"),
(199, 8412.65, 13, "Waiting for Date", "2021/12/22"),
(200, 3780.73, 4, "Waiting for Date", "2021/10/21"),
(201, 5959.26, 6, "Pending", "2021/6/16"),
(202, 9485.4, 4, "Waiting for Date", "2021/9/19"),
(203, 1193.46, 13, "Succesful", "2021/1/22"),
(204, 908.96, 13, "Pending", "2021/10/7"),
(205, 1466.33, 2, "Waiting for Date", "2021/12/9"),
(206, 7850.85, 8, "Failed", "2021/9/23"),
(207, 2909.31, 2, "Succesful", "2021/8/24"),
(208, 5747.29, 5, "Succesful", "2021/5/20"),
(209, 3734.12, 6, "Succesful", "2021/1/15"),
(210, 5253.99, 1, "Succesful", "2021/11/20"),
(211, 4579.96, 4, "Pending", "2021/3/15"),
(212, 4970.3, 10, "Waiting for Date", "2021/6/8"),
(213, 3738.88, 7, "Succesful", "2021/3/21"),
(214, 7426.73, 10, "Waiting for Date", "2021/12/21"),
(215, 6612.16, 7, "Succesful", "2021/9/23"),
(216, 259.09, 7, "Failed", "2021/4/26");

INSERT INTO `local_bargain` (`bargain_ID`, `sender_account_number`,	`receiver_account_number`) VALUES
(109, 23, 19),
(110, 14, 1),
(111, 18, 20),
(112, 33, 16),
(113, 23, 3),
(114, 1, 24),
(115, 33, 11),
(116, 17, 6),
(117, 33, 19),
(118, 17, 2),
(119, 11, 30),
(120, 30, 18),
(121, 1, 23),
(122, 20, 21),
(123, 26, 14),
(124, 30, 21),
(125, 17, 11),
(126, 23, 19),
(127, 14, 11),
(128, 24, 3),
(129, 20, 19),
(130, 3, 19),
(131, 17, 18),
(132, 18, 14),
(133, 33, 6),
(134, 9, 33),
(135, 21, 14),
(136, 3, 21),
(137, 26, 33),
(138, 2, 16),
(139, 9, 18),
(140, 26, 11),
(141, 20, 14),
(142, 14, 6),
(143, 30, 19),
(144, 26, 3),
(145, 1, 21),
(146, 9, 19),
(147, 20, 21),
(148, 30, 21),
(149, 3, 16),
(150, 3, 11),
(151, 14, 1),
(152, 33, 19),
(153, 6, 23),
(154, 16, 3),
(155, 11, 3),
(156, 26, 14),
(157, 16, 24),
(158, 20, 1),
(159, 2, 17),
(160, 19, 33),
(161, 26, 24),
(162, 21, 17),
(163, 11, 6),
(164, 16, 3),
(165, 3, 33),
(166, 21, 6),
(167, 6, 16),
(168, 19, 30),
(169, 3, 20),
(170, 17, 6),
(171, 17, 26),
(172, 1, 30),
(173, 17, 26),
(174, 9, 20),
(175, 33, 21),
(176, 2, 30),
(177, 24, 3),
(178, 14, 19),
(179, 1, 3),
(180, 30, 14),
(181, 20, 3),
(182, 1, 19),
(183, 11, 19),
(184, 3, 21),
(185, 6, 21),
(186, 9, 18),
(187, 24, 20),
(188, 24, 11),
(189, 2, 30),
(190, 9, 14),
(191, 24, 33),
(192, 19, 9),
(193, 24, 11),
(194, 21, 11),
(195, 2, 14),
(196, 21, 2),
(197, 6, 21),
(198, 16, 33),
(199, 30, 6),
(200, 9, 17),
(201, 11, 9),
(202, 3, 17),
(203, 18, 6),
(204, 24, 3),
(205, 14, 33),
(206, 1, 9),
(207, 18, 14),
(208, 17, 16),
(209, 11, 19),
(210, 18, 20),
(211, 1, 17),
(212, 2, 17),
(213, 9, 21),
(214, 2, 20),
(215, 6, 30),
(216, 9, 16);

INSERT INTO `international_bargain` (`bargain_ID`, `sender_IBAN`, `receiver_IBAN`) VALUES
(1, "GB0228189000000000000030", "GB0228189000000000000021"),
(2, "GB0228189000000000000026", "GB0228189000000000000016"),
(3, "GB0228189000000000000011", "GB0228189000000000000023"),
(4, "GB0228189000000000000021", "GB0228189000000000000017"),
(5, "GB0228189000000000000026", "GB0228189000000000000014"),
(6, "GB0228189000000000000020", "GB0228189000000000000019"),
(7, "GB0228189000000000000019", "GB0228189000000000000024"),
(8, "GB0228189000000000000018", "GB0228189000000000000014"),
(9, "GB0228189000000000000003", "GB0228189000000000000033"),
(10, "GB0228189000000000000014", "GB0228189000000000000009"),
(11, "GB0228189000000000000017", "GB0228189000000000000002"),
(12, "GB0228189000000000000016", "GB0228189000000000000019"),
(13, "GB0228189000000000000026", "GB0228189000000000000002"),
(14, "GB0228189000000000000016", "GB0228189000000000000003"),
(15, "GB0228189000000000000023", "GB0228189000000000000002"),
(16, "GB0228189000000000000006", "GB0228189000000000000016"),
(17, "GB0228189000000000000018", "GB0228189000000000000020"),
(18, "GB0228189000000000000003", "GB0228189000000000000024"),
(19, "GB0228189000000000000033", "GB0228189000000000000026"),
(20, "GB0228189000000000000006", "GB0228189000000000000023"),
(21, "GB0228189000000000000006", "GB0228189000000000000033"),
(22, "GB0228189000000000000003", "GB0228189000000000000009"),
(23, "GB0228189000000000000003", "GB0228189000000000000014"),
(24, "GB0228189000000000000019", "GB0228189000000000000014"),
(25, "GB0228189000000000000021", "GB0228189000000000000018"),
(26, "GB0228189000000000000018", "GB0228189000000000000023"),
(27, "GB0228189000000000000026", "GB0228189000000000000014"),
(28, "GB0228189000000000000021", "GB0228189000000000000017"),
(29, "GB0228189000000000000017", "GB0228189000000000000026"),
(30, "GB0228189000000000000014", "GB0228189000000000000017"),
(31, "GB0228189000000000000024", "GB0228189000000000000023"),
(32, "GB0228189000000000000016", "GB0228189000000000000003"),
(33, "GB0228189000000000000020", "GB0228189000000000000006"),
(34, "GB0228189000000000000033", "GB0228189000000000000024"),
(35, "GB0228189000000000000018", "GB0228189000000000000033"),
(36, "GB0228189000000000000002", "GB0228189000000000000021"),
(37, "GB0228189000000000000024", "GB0228189000000000000017"),
(38, "GB0228189000000000000001", "GB0228189000000000000026"),
(39, "GB0228189000000000000026", "GB0228189000000000000009"),
(40, "GB0228189000000000000003", "GB0228189000000000000020"),
(41, "GB0228189000000000000001", "GB0228189000000000000023"),
(42, "GB0228189000000000000001", "GB0228189000000000000033"),
(43, "GB0228189000000000000033", "GB0228189000000000000017"),
(44, "GB0228189000000000000017", "GB0228189000000000000019"),
(45, "GB0228189000000000000020", "GB0228189000000000000006"),
(46, "GB0228189000000000000019", "GB0228189000000000000018"),
(47, "GB0228189000000000000019", "GB0228189000000000000021"),
(48, "GB0228189000000000000014", "GB0228189000000000000030"),
(49, "GB0228189000000000000026", "GB0228189000000000000001"),
(50, "GB0228189000000000000011", "GB0228189000000000000023"),
(51, "GB0228189000000000000026", "GB0228189000000000000024"),
(52, "GB0228189000000000000024", "GB0228189000000000000018"),
(53, "GB0228189000000000000018", "GB0228189000000000000001"),
(54, "GB0228189000000000000021", "GB0228189000000000000016"),
(55, "GB0228189000000000000019", "GB0228189000000000000033"),
(56, "GB0228189000000000000030", "GB0228189000000000000002"),
(57, "GB0228189000000000000002", "GB0228189000000000000030"),
(58, "GB0228189000000000000023", "GB0228189000000000000002"),
(59, "GB0228189000000000000011", "GB0228189000000000000003"),
(60, "GB0228189000000000000020", "GB0228189000000000000026"),
(61, "GB0228189000000000000002", "GB0228189000000000000003"),
(62, "GB0228189000000000000001", "GB0228189000000000000024"),
(63, "GB0228189000000000000019", "GB0228189000000000000002"),
(64, "GB0228189000000000000003", "GB0228189000000000000006"),
(65, "GB0228189000000000000017", "GB0228189000000000000009"),
(66, "GB0228189000000000000006", "GB0228189000000000000009"),
(67, "GB0228189000000000000003", "GB0228189000000000000006"),
(68, "GB0228189000000000000018", "GB0228189000000000000024"),
(69, "GB0228189000000000000014", "GB0228189000000000000003"),
(70, "GB0228189000000000000006", "GB0228189000000000000003"),
(71, "GB0228189000000000000003", "GB0228189000000000000023"),
(72, "GB0228189000000000000021", "GB0228189000000000000018"),
(73, "GB0228189000000000000033", "GB0228189000000000000014"),
(74, "GB0228189000000000000030", "GB0228189000000000000016"),
(75, "GB0228189000000000000030", "GB0228189000000000000002"),
(76, "GB0228189000000000000014", "GB0228189000000000000016"),
(77, "GB0228189000000000000002", "GB0228189000000000000030"),
(78, "GB0228189000000000000017", "GB0228189000000000000026"),
(79, "GB0228189000000000000033", "GB0228189000000000000016"),
(80, "GB0228189000000000000011", "GB0228189000000000000017"),
(81, "GB0228189000000000000011", "GB0228189000000000000001"),
(82, "GB0228189000000000000023", "GB0228189000000000000026"),
(83, "GB0228189000000000000023", "GB0228189000000000000014"),
(84, "GB0228189000000000000002", "GB0228189000000000000009"),
(85, "GB0228189000000000000011", "GB0228189000000000000033"),
(86, "GB0228189000000000000003", "GB0228189000000000000001"),
(87, "GB0228189000000000000003", "GB0228189000000000000016"),
(88, "GB0228189000000000000002", "GB0228189000000000000024"),
(89, "GB0228189000000000000014", "GB0228189000000000000001"),
(90, "GB0228189000000000000002", "GB0228189000000000000017"),
(91, "GB0228189000000000000016", "GB0228189000000000000033"),
(92, "GB0228189000000000000001", "GB0228189000000000000009"),
(93, "GB0228189000000000000019", "GB0228189000000000000033"),
(94, "GB0228189000000000000003", "GB0228189000000000000006"),
(95, "GB0228189000000000000033", "GB0228189000000000000024"),
(96, "GB0228189000000000000002", "GB0228189000000000000023"),
(97, "GB0228189000000000000016", "GB0228189000000000000024"),
(98, "GB0228189000000000000002", "GB0228189000000000000023"),
(99, "GB0228189000000000000024", "GB0228189000000000000003"),
(100, "GB0228189000000000000018", "GB0228189000000000000021"),
(101, "GB0228189000000000000033", "GB0228189000000000000002"),
(102, "GB0228189000000000000017", "GB0228189000000000000019"),
(103, "GB0228189000000000000020", "GB0228189000000000000026"),
(104, "GB0228189000000000000014", "GB0228189000000000000030"),
(105, "GB0228189000000000000001", "GB0228189000000000000023"),
(106, "GB0228189000000000000006", "GB0228189000000000000011"),
(107, "GB0228189000000000000001", "GB0228189000000000000011"),
(108, "GB0228189000000000000018", "GB0228189000000000000021");

INSERT INTO `outgoing_bargain` (`bargain_ID`, `planned_date`) VALUES
(1, "2021/9/26"),
(2, "2021/5/23"),
(3, "2021/5/10"),
(4, "2021/8/3"),
(5, "2021/1/19"),
(6, "2021/10/6"),
(7, "2023/2/12"),
(8, "2021/3/22"),
(9, "2021/1/27"),
(10, "2021/12/23"),
(11, "2021/12/27"),
(12, "2023/9/6"),
(13, "2022/2/15"),
(14, "2023/8/15"),
(15, "2021/11/12"),
(16, "2023/10/24"),
(17, "2021/10/6"),
(18, "2021/8/2"),
(19, "2021/12/25"),
(20, "2021/9/8"),
(21, "2021/11/13"),
(22, "2021/3/25"),
(23, "2021/4/1"),
(24, "2021/3/7"),
(25, "2021/2/6"),
(26, "2021/6/13"),
(27, "2021/3/18"),
(28, "2021/3/2"),
(29, "2021/4/10"),
(30, "2021/11/20"),
(31, "2021/8/16"),
(32, "2021/8/26"),
(33, "2021/11/10"),
(34, "2021/3/16"),
(35, "2021/10/5"),
(36, "2021/8/13"),
(37, "2021/9/19"),
(38, "2021/3/7"),
(39, "2021/6/17"),
(40, "2022/10/7"),
(41, "2021/8/26"),
(42, "2023/8/24"),
(43, "2021/7/28"),
(44, "2021/12/6"),
(45, "2021/3/17"),
(46, "2021/2/28"),
(47, "2021/7/16"),
(48, "2021/9/9"),
(49, "2021/1/1"),
(50, "2021/12/10"),
(51, "2021/6/28"),
(52, "2021/4/10"),
(53, "2021/4/8"),
(54, "2021/6/10"),
(55, "2021/2/16"),
(56, "2021/4/21"),
(57, "2021/7/7"),
(58, "2022/2/24"),
(59, "2021/4/2"),
(60, "2022/10/27"),
(61, "2021/7/10"),
(62, "2021/7/28"),
(63, "2021/11/13"),
(64, "2021/3/14"),
(65, "2021/12/13"),
(66, "2021/10/20"),
(67, "2021/6/12"),
(68, "2021/10/22"),
(69, "2021/12/23"),
(70, "2021/7/8"),
(71, "2022/9/9"),
(72, "2021/11/12"),
(73, "2022/1/15"),
(74, "2021/1/25"),
(75, "2021/7/15"),
(76, "2021/8/9"),
(77, "2021/7/22"),
(78, "2021/9/9"),
(79, "2021/11/11"),
(80, "2021/9/24"),
(81, "2022/7/16"),
(82, "2021/6/13"),
(83, "2022/9/2"),
(84, "2021/11/24"),
(85, "2021/7/1"),
(86, "2022/3/1"),
(87, "2021/9/6"),
(88, "2021/10/19"),
(89, "2021/3/21"),
(90, "2021/9/25"),
(91, "2021/2/14"),
(92, "2021/3/11"),
(93, "2021/10/19"),
(94, "2021/8/8"),
(95, "2021/10/24"),
(96, "2021/11/8"),
(97, "2021/7/28"),
(98, "2021/11/7"),
(99, "2021/11/9"),
(100, "2021/3/9"),
(101, "2021/5/8"),
(102, "2021/9/16"),
(103, "2021/7/17"),
(104, "2021/7/19"),
(105, "2021/6/21"),
(106, "2021/6/27"),
(107, "2021/8/11"),
(108, "2021/2/25"),
(109, "2021/10/5"),
(110, "2021/11/17"),
(111, "2021/5/26"),
(112, "2021/4/20"),
(113, "2021/1/10"),
(114, "2022/5/27"),
(115, "2021/11/13"),
(116, "2021/12/20"),
(117, "2021/10/5"),
(118, "2021/6/23"),
(119, "2021/7/14"),
(120, "2021/9/20"),
(121, "2021/9/18"),
(122, "2021/10/20"),
(123, "2021/10/13"),
(124, "2021/4/24"),
(125, "2021/12/16"),
(126, "2021/7/4"),
(127, "2021/7/9"),
(128, "2021/12/11"),
(129, "2021/5/1"),
(130, "2022/9/19"),
(131, "2021/7/28"),
(132, "2021/10/13"),
(133, "2021/12/1"),
(134, "2021/1/7"),
(135, "2021/10/14"),
(136, "2021/11/24"),
(137, "2021/12/24"),
(138, "2021/9/7"),
(139, "2021/10/18"),
(140, "2021/9/16"),
(141, "2022/2/9"),
(142, "2021/4/13"),
(143, "2021/7/26"),
(144, "2021/7/1"),
(145, "2021/4/25"),
(146, "2021/2/2"),
(147, "2023/8/10"),
(148, "2021/10/21"),
(149, "2023/8/15"),
(150, "2021/10/12"),
(151, "2022/3/17"),
(152, "2021/12/24"),
(153, "2022/5/17"),
(154, "2021/5/14"),
(155, "2021/10/4"),
(156, "2021/6/13"),
(157, "2021/12/23"),
(158, "2022/11/20"),
(159, "2021/12/16"),
(160, "2021/1/24"),
(161, "2021/4/15"),
(162, "2021/7/3"),
(163, "2021/1/3"),
(164, "2021/9/22"),
(165, "2021/4/11"),
(166, "2021/9/20"),
(167, "2021/6/27"),
(168, "2022/8/3"),
(169, "2021/11/26"),
(170, "2022/4/4"),
(171, "2021/2/28"),
(172, "2021/2/10"),
(173, "2021/8/5"),
(174, "2021/9/6"),
(175, "2021/1/23"),
(176, "2021/10/6"),
(177, "2022/7/15"),
(178, "2021/12/2"),
(179, "2021/3/16"),
(180, "2021/8/24"),
(181, "2021/10/8"),
(182, "2021/2/2"),
(183, "2021/12/18"),
(184, "2021/8/16"),
(185, "2021/5/15"),
(186, "2021/1/8"),
(187, "2021/2/5"),
(188, "2021/11/20"),
(189, "2021/11/25"),
(190, "2021/2/6"),
(191, "2021/2/17"),
(192, "2021/10/17"),
(193, "2021/9/23"),
(194, "2021/4/18"),
(195, "2021/3/15"),
(196, "2021/2/27"),
(197, "2021/4/4"),
(198, "2021/12/22"),
(199, "2023/12/17"),
(200, "2022/1/4"),
(201, "2021/8/18"),
(202, "2021/5/26"),
(203, "2021/3/26"),
(204, "2021/6/26"),
(205, "2022/8/2"),
(206, "2021/1/8"),
(207, "2021/11/1"),
(208, "2021/4/8"),
(209, "2021/12/4"),
(210, "2021/8/14"),
(211, "2021/7/14"),
(212, "2023/11/28"),
(213, "2021/4/1"),
(214, "2022/10/10"),
(215, "2021/4/4"),
(216, "2021/4/9");

INSERT INTO `incoming_bargain` (`bargain_ID`, `receipt_date`) VALUES
(3, "2021/3/8"),
(9, "2021/12/27"),
(10, "2021/8/7"),
(19, "2021/6/16"),
(25, "2021/4/25"),
(36, "2021/8/2"),
(37, "2021/10/25"),
(39, "2021/4/5"),
(41, "2021/1/13"),
(46, "2021/9/15"),
(52, "2021/9/15"),
(53, "2021/1/14"),
(59, "2021/5/1"),
(64, "2021/1/20"),
(69, "2021/9/28"),
(72, "2021/8/20"),
(76, "2021/3/24"),
(77, "2021/5/20"),
(91, "2021/12/2"),
(100, "2021/2/8"),
(102, "2021/3/23"),
(103, "2021/8/27"),
(104, "2021/10/16"),
(108, "2021/10/4"),
(112, "2021/9/15"),
(117, "2021/4/15"),
(119, "2021/8/7"),
(120, "2021/7/6"),
(125, "2021/1/14"),
(129, "2021/10/5"),
(138, "2021/6/1"),
(150, "2021/1/12"),
(159, "2021/10/8"),
(160, "2021/7/11"),
(167, "2021/2/2"),
(173, "2021/10/18"),
(174, "2021/2/19"),
(181, "2021/8/8"),
(185, "2021/2/16"),
(189, "2021/11/22"),
(195, "2021/12/14"),
(197, "2021/6/27"),
(203, "2021/1/26"),
(207, "2021/8/22"),
(208, "2021/5/10"),
(209, "2021/4/11"),
(210, "2021/6/28"),
(213, "2021/6/7"),
(215, "2021/9/17");

INSERT INTO `account_stock` (`account_number`, `stock_code`, `shares`) VALUES
(1, "AAPL", 714),
(1, "GOOG", 749),
(1, "MSFT", 445),
(1, "FB", 394),
(1, "AMZN", 302),
(1, "TWTR", 967),
(1, "NFLX", 347),
(1, "TSLA", 804),
(1, "BABA", 624),
(1, "NVDA", 836),
(1, "AMD", 898),
(1, "INTC", 226),
(1, "CSCO", 212),
(2, "AAPL", 651),
(3, "AAPL", 37),
(3, "GOOG", 322),
(3, "MSFT", 59),
(3, "FB", 71),
(3, "AMZN", 166),
(3, "TWTR", 601),
(3, "NFLX", 162),
(3, "TSLA", 183),
(3, "BABA", 817),
(3, "NVDA", 134),
(3, "AMD", 583),
(3, "INTC", 762),
(3, "CSCO", 321),
(3, "ADBE", 133),
(6, "AAPL", 557),
(6, "GOOG", 552),
(6, "MSFT", 926),
(6, "FB", 558),
(6, "AMZN", 880),
(6, "TWTR", 426),
(6, "NFLX", 879),
(6, "TSLA", 331),
(6, "BABA", 846),
(6, "NVDA", 20),
(6, "AMD", 245),
(6, "INTC", 104),
(6, "CSCO", 38),
(9, "AAPL", 776),
(9, "GOOG", 742),
(9, "MSFT", 744),
(9, "FB", 109),
(9, "AMZN", 369),
(9, "TWTR", 558),
(9, "NFLX", 200),
(9, "TSLA", 587),
(9, "BABA", 23),
(9, "NVDA", 331),
(9, "AMD", 605),
(9, "INTC", 567),
(9, "CSCO", 83),
(9, "ADBE", 13),
(11, "AAPL", 410),
(14, "AAPL", 870),
(14, "GOOG", 865),
(14, "MSFT", 792),
(14, "FB", 802),
(14, "AMZN", 667),
(14, "TWTR", 631),
(16, "AAPL", 838),
(16, "GOOG", 70),
(17, "AAPL", 171),
(17, "GOOG", 470),
(17, "MSFT", 360),
(18, "AAPL", 230),
(18, "GOOG", 245),
(18, "MSFT", 201),
(18, "FB", 87),
(18, "AMZN", 547),
(18, "TWTR", 700),
(18, "NFLX", 857),
(19, "AAPL", 203),
(19, "GOOG", 307),
(19, "MSFT", 491),
(19, "FB", 339),
(19, "AMZN", 128),
(19, "TWTR", 114),
(19, "NFLX", 165),
(19, "TSLA", 40),
(19, "BABA", 756),
(19, "NVDA", 115),
(20, "AAPL", 619),
(20, "GOOG", 987),
(20, "MSFT", 474),
(21, "AAPL", 494),
(21, "GOOG", 972),
(21, "MSFT", 124),
(21, "FB", 363),
(21, "AMZN", 971),
(21, "TWTR", 890),
(21, "NFLX", 767),
(21, "TSLA", 325),
(21, "BABA", 677),
(21, "NVDA", 706),
(21, "AMD", 199),
(21, "INTC", 778),
(23, "AAPL", 977),
(23, "GOOG", 30),
(23, "MSFT", 325),
(23, "FB", 303),
(23, "AMZN", 856),
(23, "TWTR", 992),
(23, "NFLX", 335),
(23, "TSLA", 20),
(23, "BABA", 607),
(23, "NVDA", 295),
(23, "AMD", 817),
(24, "AAPL", 915),
(24, "GOOG", 412),
(24, "MSFT", 661),
(24, "FB", 449),
(24, "AMZN", 630),
(24, "TWTR", 489),
(24, "NFLX", 57),
(24, "TSLA", 642),
(24, "BABA", 85),
(24, "NVDA", 277),
(24, "AMD", 77),
(24, "INTC", 106),
(24, "CSCO", 421),
(26, "AAPL", 285),
(26, "GOOG", 640),
(26, "MSFT", 810),
(26, "FB", 79),
(26, "AMZN", 432),
(26, "TWTR", 303),
(26, "NFLX", 515),
(26, "TSLA", 582),
(26, "BABA", 714),
(26, "NVDA", 429),
(26, "AMD", 196),
(26, "INTC", 723),
(26, "CSCO", 791),
(26, "ADBE", 225),
(26, "ADP", 522),
(26, "CMCSA", 449),
(30, "AAPL", 991),
(30, "GOOG", 952),
(30, "MSFT", 515),
(30, "FB", 405),
(30, "AMZN", 124),
(30, "TWTR", 541),
(30, "NFLX", 719),
(30, "TSLA", 623),
(33, "AAPL", 706),
(33, "GOOG", 431);

INSERT INTO `loan` (`loan_ID`, `given_amount`, `repaid_amount`, `currency_ID`) VALUES
(1, 22624, 6698, 12),
(2, 78146, 63138, 2),
(3, 63830, 1432, 9),
(4, 68716, 61809, 7),
(5, 18932, 8218, 13),
(6, 58579, 46491, 13),
(7, 2707, 1251, 13),
(8, 75991, 52515, 12),
(9, 16640, 1845, 2),
(10, 46574, 30092, 11),
(11, 53895, 17327, 4),
(12, 88457, 80212, 6),
(13, 75264, 42302, 9),
(14, 88995, 54848, 7),
(15, 84068, 51071, 5),
(16, 71819, 24963, 3),
(17, 97946, 2028, 12),
(18, 54243, 53185, 4),
(19, 9157, 475, 12),
(20, 86854, 24919, 6),
(21, 35393, 19800, 6),
(22, 16071, 10775, 2),
(23, 38031, 16898, 11),
(24, 52667, 12148, 11),
(25, 50031, 46344, 9),
(26, 34996, 5427, 5),
(27, 48197, 11622, 10),
(28, 60925, 18638, 10),
(29, 15805, 965, 8),
(30, 49698, 35269, 4),
(31, 74462, 31338, 7),
(32, 29710, 17036, 1),
(33, 85956, 28673, 4);

INSERT INTO `loan_payment` (`loan_ID`, `total_expected_number_of_payments`, `first_payment_date`, `payment_due_date`) VALUES
(1, 3, "2023/2/28", "2023/2/28 23:59:59"),
(2, 12, "2022/10/17", "2022/10/17 23:59:59"),
(3, 3, "2023/3/26", "2023/3/26 23:59:59"),
(4, 60, "2021/9/24", "2021/9/24 23:59:59"),
(5, 60, "2021/11/2", "2021/11/2 23:59:59"),
(6, 2, "2023/4/1", "2023/4/1 23:59:59"),
(7, 60, "2021/5/3", "2021/5/3 23:59:59"),
(8, 1, "2023/10/15", "2023/10/15 23:59:59"),
(9, 48, "2022/6/3", "2022/6/3 23:59:59"),
(10, 36, "2022/10/13", "2022/10/13 23:59:59"),
(11, 6, "2021/8/13", "2021/8/13 23:59:59"),
(12, 5, "2022/7/15", "2022/7/15 23:59:59"),
(13, 5, "2022/4/17", "2022/4/17 23:59:59"),
(14, 24, "2023/10/1", "2023/10/1 23:59:59"),
(15, 3, "2023/8/26", "2023/8/26 23:59:59"),
(16, 12, "2023/1/14", "2023/1/14 23:59:59"),
(17, 5, "2021/7/6", "2021/7/6 23:59:59"),
(18, 4, "2021/2/23", "2021/2/23 23:59:59"),
(19, 5, "2022/5/6", "2022/5/6 23:59:59"),
(20, 48, "2021/12/20", "2021/12/20 23:59:59"),
(21, 4, "2021/9/25", "2021/9/25 23:59:59"),
(22, 12, "2021/12/19", "2021/12/19 23:59:59"),
(23, 1, "2023/8/20", "2023/8/20 23:59:59"),
(24, 48, "2021/4/11", "2021/4/11 23:59:59"),
(25, 60, "2022/11/1", "2022/11/1 23:59:59"),
(26, 1, "2022/2/18", "2022/2/18 23:59:59"),
(27, 60, "2022/11/13", "2022/11/13 23:59:59"),
(28, 5, "2021/11/8", "2021/11/8 23:59:59"),
(29, 36, "2023/10/1", "2023/10/1 23:59:59"),
(30, 3, "2023/10/20", "2023/10/20 23:59:59"),
(31, 12, "2021/4/22", "2021/4/22 23:59:59"),
(32, 60, "2021/2/5", "2021/2/5 23:59:59"),
(33, 4, "2023/10/4", "2023/10/4 23:59:59");

INSERT INTO `account_loan` (`account_number`, `loan_ID`, `payment_rate`) VALUES
(9, 1, 36968),
(23, 2, 33438),
(33, 3, 160642),
(17, 4, 104666),
(2, 5, 19282),
(2, 6, 36111),
(11, 7, 193089),
(24, 8, 138956),
(20, 9, 218785),
(23, 10, 73348),
(18, 11, 187495),
(11, 12, 130077),
(3, 13, 75034),
(2, 14, 159675),
(20, 15, 153407),
(2, 16, 51163),
(16, 17, 189434),
(23, 18, 175817),
(19, 19, 55182),
(6, 20, 10215),
(23, 21, 210446),
(11, 22, 3181),
(11, 23, 65833),
(23, 24, 248329),
(30, 25, 11634),
(21, 26, 43253),
(1, 27, 148521),
(1, 28, 97104),
(20, 29, 68456),
(3, 30, 237473),
(18, 31, 68432),
(2, 32, 240532);

/* #endregion */