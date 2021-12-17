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
            AND
            DAY(payment_due_date) BETWEEN 1 AND 7
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
        MONTH(payment_due_date)=MONTH(CURRENT_DATE)+1
        AND
        DAY(payment_due_date) BETWEEN 1 AND 7
    );

/* #endregion */

/* #region 4.2 */
/*
Extract all bank transactions that were made in the past 5 days (please include customer 
and account details).
*/

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

/* #endregion */

/* #region 4.3 */
/*
List the customers with balance > 5000 by summing incoming transactions and deduct outgoing
*/

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

/*
List the customers with balance > 5000 just from existing table
*/

SELECT client_details.reference_number, client_details.full_name, client_account.account_number, account_balance.amount, account_balance.currency_ID, currency_list.symbol
FROM client_details
INNER JOIN client_account ON client_details.reference_number=client_account.reference_number
INNER JOIN account_balance ON client_account.account_number = account_balance.account_number
INNER JOIN currency_list ON currency_list.currency_ID=account_balance.currency_ID
WHERE account_balance.amount > 5000;

/* #endregion */

/* #region 4.4 */
/*
Total oustandings of bank (sum(incoming) - sum(outgoing))
*/

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

