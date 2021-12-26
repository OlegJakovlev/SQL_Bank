/* #region 4.1 */
/*
List all bank customers (including their name and account number) who have their loan 
payment due in the first 7 days of the month (all the months)
*/

SELECT client_details.*, client_account.account_number

FROM `client_details`

INNER JOIN client_account ON client_details.reference_number=client_account.reference_number

WHERE client_account.account_number IN
	(SELECT account_number from `account_loan` WHERE loan_ID IN
    	(SELECT loan_ID FROM `loan_payment` WHERE DAY(payment_due_date) BETWEEN 1 AND 7)
    );

/*
List all bank customers (including their name and account number) who have their loan 
payment due in the first 7 days of the month. (current month)
*/

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

/*
List all bank customers (including their name and account number) who have their loan 
payment due in the first 7 days of the month. (next month)
*/

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

/* #endregion */

/* #region 4.2 */
/*
Extract all bank transactions that were made in the past 5 days (please include customer 
and account details).
*/

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

/* #endregion */

/* #region 4.3 */
/*
List the customers with balance > 5000 by summing incoming transactions and deduct outgoing
*/

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

/* User might have only outgoing / incoming bargains, and we need to check that 
without prioritising any (by selecting from any specific table first and joining another) */

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

/*
List the customers with balance > 5000 just from existing table
*/

SELECT client_details.reference_number, client_details.full_name, client_account.account_number,
account_balance.amount, currency_list.symbol, currency_list.alphabetic_code

FROM client_details

INNER JOIN client_account ON client_details.reference_number=client_account.reference_number
INNER JOIN account_balance ON client_account.account_number = account_balance.account_number
INNER JOIN currency_list ON currency_list.currency_ID=account_balance.currency_ID

WHERE account_balance.amount > 5000
ORDER BY `client_account`.`account_number` ASC;

/* #endregion */

/* #region 4.4 */
/*
Total oustandings of bank (sum(incoming) - sum(outgoing))
*/

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

/* Bank might have only outgoing / incoming bargains, and we need to check that 
without prioritising any (by selecting from any specific table first and joining another) */

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

SELECT * from final_table 

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

        -- Account number with loan within first 7 days of month
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
    SELECT client_details.reference_number, client_details.full_name, client_account.account_number, bargain.bargain_ID,
    bargain.amount, currency_list.symbol, currency_list.alphabetic_code, bargain.bargain_date

    FROM client_details

    INNER JOIN client_account ON client_details.reference_number=client_account.reference_number

    -- Get IBAN for international
    INNER JOIN account_iban ON client_account.account_number = account_iban.account_number
    
    -- Get all bargains
    INNER JOIN local_bargain ON local_bargain.sender_account_number = client_account.account_number
    INNER JOIN international_bargain ON international_bargain.sender_IBAN = account_iban.IBAN
    
    -- Filter outgoing by date and status
    INNER JOIN bargain ON ((bargain.bargain_ID = local_bargain.bargain_ID OR bargain.bargain_ID = international_bargain.bargain_ID) 
        AND bargain.bargain_status = "Succesful" 
        AND bargain_date BETWEEN NOW()-INTERVAL 5 DAY AND NOW())
    
    -- Get currencies
    INNER JOIN currency_list ON currency_list.currency_ID = bargain.currency_ID

    -- All outgoing
    WHERE bargain.bargain_ID IN (SELECT bargain_ID FROM outgoing_bargain)
    
    GROUP BY client_account.account_number, currency_list.currency_ID
    ORDER BY `bargain`.`bargain_ID` ASC;
END;
//
DELIMITER ;
/* #endregion */

