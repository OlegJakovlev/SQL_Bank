import random
from data_generator import *

DEBUG = 0

NUMBER_OF_BANKS = 10
NUMBER_OF_CUSTOMER = 10
MAX_NUMBER_OF_TRANSACTIONS_FOR_ACCOUNT = 50
STOCK_COMMISSION = 0.02

BANK_OPENING_DATE = date(2021, 11, 1)
TODAYS_DATE = date.today()

TODAYS_DATE_STRING = TODAYS_DATE.strftime("%Y/%m/%d")

OUTPUT_FILE_NAME = "generated_data.txt"

# Create banks
banks = []

for i in range(0, NUMBER_OF_BANKS):
    banks.append(str(i+1) + ', "' + str(generate_sort()) + '", "' + generate_swift() + '"')

# Get currency dictionary
currencies = []
counter = 0
currency_dictionary = get_all_currencies()
for i in currency_dictionary:
    counter += 1
    entry = currency_dictionary[i]
    currencies.append(str(counter) + ', "' + i + '", "' + entry + '"')

# Create stocks
stocks = []
stock_dict = get_all_stocks()
for i in stock_dict:
    entry = stock_dict[i]
    initial_price = generate_price()
    stocks.append('"' + i + '", "' + entry + '", ' + str(initial_price * (1 - STOCK_COMMISSION)) + ', ' + str(initial_price))

# Create regional info for customers
regional_info = [ get_random_regional_information() for i in range(NUMBER_OF_CUSTOMER) ]
counter = 1

client_details = []
references_numbers = []

for i in range(NUMBER_OF_CUSTOMER):
    result = ""

    # Generate data
    tmp_ref = generate_reference_number()
    tmp_full_name = generate_full_name()
    tmp_date = generate_date(1900, 2003)
    tmp_address = generate_address()
    tmp_address2 = random.choice([generate_room_string(), "NULL"])
    tmp_number = generate_international_number()

    # Add to list
    references_numbers.append(tmp_ref)

    # Create client details
    result += '"' + tmp_ref + '", "' + tmp_full_name + '", "' + tmp_date + '", "' + tmp_address + '", '
    if (tmp_address2 == "NULL"):
        result += 'NULL, '
    else:
        result += '"' + tmp_address2 + '", '
    
    result += str(i+1) + ', "' + tmp_number + '"'
    
    # Add to list
    client_details.append(result)

# Client access
client_access = []
for i in range(NUMBER_OF_CUSTOMER):
    client_access.append(client_details[i].split(",")[0] + ', "' + generate_salt() + '", "' + generate_hash() + '"')

# Client sessions
client_sessions = []

for i in range(NUMBER_OF_CUSTOMER):
    result = ""
    reference_number = random.choice(references_numbers)
    customer_IP = generate_ip()
    secret_key_salt = generate_salt()
    secret_key_hashed = generate_hash()
    token_salt = generate_salt()
    token_hashed = generate_hash()
    token_expiry_date = "DATE_ADD(NOW(), INTERVAL 1 HOUR)"

    result += '"' + reference_number + '", "' + customer_IP + '", "' + secret_key_salt + '", "' + secret_key_hashed + '", "' + token_salt + '", "' + token_hashed + '", ' + token_expiry_date
    client_sessions.append(result)

# Create accounts for some clients
accounts = []
activated_accounts = []

account_statuses = ["Waiting for Deposit","Open"]

counter = 0
for i in range(0, NUMBER_OF_CUSTOMER):
    for j in range(random.randint(1,5)):
        counter += 1

        result = ""
        status = random.choice(account_statuses)
        bank_ID = str(generate_number(1, NUMBER_OF_BANKS-1))

        if (status != "Waiting for Deposit"):
            activated_accounts.append(counter)

        result += '"' + status + '", ' + bank_ID
        accounts.append(result)

# Link account to client
client_account = []

account_counter = 1
for i in range(len(accounts)):
    ref_number = random.choice(references_numbers)
    account_number = str(account_counter)
    account_counter += 1
    result = '"' + ref_number + '", ' + account_number
    client_account.append(result)

# Account IBAN
account_iban = []
activated_iban = []

for i in range(1, account_counter):
    result = ""
    result +=  str(i) + ', "' + generate_iban(i) + '"'

    if (i in activated_accounts):
        activated_iban.append(result)

    account_iban.append(result)

# Account Balance
account_balance = []
for account_number in activated_accounts:
    for currency_ID in range(1, generate_number(2, len(currencies))):
        result = ""
        result += str(account_number) + ', ' + str(currency_ID) + ', ' + str(generate_number(-10000, 10000))
        account_balance.append(result)

# Customer cards
customer_cards = []
cards_to_accounts = []

card_number = 0
for account_number in range(len(activated_accounts)):
    for random_amount in range(generate_number(1, 5)):
        card_number += 1

        result = str(card_number) + ', "' + generate_salt() + '", "' + generate_hash() + '", "' + generate_hash() + '", "' + generate_hash() + '", false, false'
        
        customer_cards.append(result)

    cards_to_accounts.append(card_number)

# Customer cards to accounts
customer_cards_to_accounts = []

for card_ID in range(card_number):
    result = str( str(card_ID+1) + ', ' + str( random.choice(activated_accounts) ) + ', ' + str(random.randint (1, len(currencies)) ) )
    customer_cards_to_accounts.append(result)

# Create limit for card
card_limits = []
for i in range(0, card_number):
    result = ""
    result += str(i+1) + ', ' + str(generate_number(0, 100000))
    card_limits.append(result)

# Create bargain
bargains = []
bargain_ID = 0
bargain_status = ["Waiting for Date", "Pending","Failed", "Succesful"]
for account in range(1, len(activated_accounts)+1):
    for bargain in range(random.randint(1, MAX_NUMBER_OF_TRANSACTIONS_FOR_ACCOUNT)):
        bargain_ID+=1

        result = ""
        current_bargain_status = random.choice(bargain_status)

        result += str(bargain_ID) + ', ' +str(generate_price()) + ', ' + str(generate_number(1, len(currencies))) + ', "' + random.choice(bargain_status) + '", "' + generate_date_between(BANK_OPENING_DATE, date(2022, 1, 15)) + ' ' + generate_random_time() + '"'
        
        bargains.append(result)

# Create outgoing bargains
outgoing_bargains = []

for i in range(0, len(bargains)):
    result = str(i+1) + ", "

    bargain = bargains[i].split(", ")
    bargain_status = bargain[3][1:-1]
    
    if bargain_status == "Waiting for Date":
        result +='"' + generate_date_between(date(2022, 1, 15), date(2023, 1, 15))

    elif bargain_status == "Pending":
        result += '"' + str(TODAYS_DATE_STRING)

    elif bargain_status == "Failed" or bargain_status == "Succesful":
        result += '"' + generate_date_between(BANK_OPENING_DATE, date.today())

    result += ' ' + generate_random_time() + '"'

    outgoing_bargains.append(result)

# Create incoming bargains
incoming_bargains = []

for i in range(0, len(bargains)):
    result = str(i+1) + ", "

    bargain = bargains[i].split(", ")
    bargain_status = bargain[3][1:-1]

    if bargain_status == "Succesful":
        result += '"' + generate_date_between(BANK_OPENING_DATE, TODAYS_DATE) + ' ' + generate_random_time() + '"'
    else:
        continue
    
    incoming_bargains.append(result)

# Create international bargain
international_bargain = []

for i in range(0, len(bargains)//2):
    result = str(i+1) + ", "
    first_IBAN = ""
    second_IBAN = ""

    while first_IBAN == second_IBAN:
        first_IBAN = random.choice(activated_iban).split(", ")[1][1:-1]
        second_IBAN = random.choice(activated_iban).split(", ")[1][1:-1]

    result += '"' + first_IBAN + '", "' + second_IBAN + '"'
    international_bargain.append(result)

# Create local bargain
local_bargain = []

for i in range(len(bargains)//2, len(bargains)):
    result = str(i+1) + ", "
    first_account_number = ""
    second_account_number = ""

    while first_account_number == second_account_number:
        first_account_number = str(random.choice(activated_accounts))
        second_account_number = str(random.choice(activated_accounts))
    
    result += first_account_number + ', ' + second_account_number
    local_bargain.append(result)

# Add stocks to accounts
stocks_to_accounts = []

for i in activated_accounts:
    for j in range(random.randint(1, len(stocks))):
        result = str(i)
        stock_code = stocks[j].split(", ")[0][1:-1]
        shares = generate_number(1, 1000)
        result += ', "' + stock_code + '", ' + str(shares)
        stocks_to_accounts.append(result)

# Create loans
loans = []
for i in range(1, account_counter+1//2):
    given_amount = generate_number(1, 100000)
    repaid_amount = generate_number(0, given_amount)
    currency_ID = generate_number(1, len(currencies))
    loans.append(str(i) + ", " + str(given_amount) + ', ' + str(repaid_amount) + ', ' + str(currency_ID))

# Add loan payment info
loan_payments = []

for i in range(0, len(loans)):
    total_expected_number_of_payments = random.choice([1,2,3,4,5,6,12,24,36,48,60])
    first_payment_date = generate_date_between(TODAYS_DATE, date(2022, 11, 1))
    payment_due_date = first_payment_date + " 23:59:59"

    loan_payments.append(str(total_expected_number_of_payments) + ', ' + '"' + first_payment_date + '", ' + '"' + payment_due_date + '"')

# Connect loan to account
loan_to_account = []

for i in range(1, len(loans)):
    payment_rate = generate_number(1, 250000)
    result = str(random.choice(activated_accounts)) + ', ' + str(i) + ', ' + str(payment_rate)
    loan_to_account.append(result)
    

if DEBUG:
    #print("All the Banks: ", banks)
    print("One bank: ", banks[0])
    print("\n")

    #print("All the Currencies: ", currencies)
    print("One Currency: ", currencies[0])
    print("\n")

    #print("All the Stocks: ", stocks)
    print("One Stock: ", stocks[0])
    print("\n")

    #print("All the Info: ", regional_info)
    print("One Regional Info: ", str(counter) + ", " + regional_info[0])
    print("\n")

    #print("All the Client Details: ", client_details)
    print("One Client Detail: ", client_details[0])
    print("\n")

    #print("All the Client Access: ", client_access)
    print("One Client Access: ", client_access[0])
    print("\n")

    #print("All the Client Sessions: ", client_sessions)
    print("One Client Session: ", client_sessions[0])
    print("\n")

    #print("All the Accounts: ", accounts)
    print("One Account: ", accounts[0])
    print("\n")

    #print("All the Client Account: ", client_account)
    print("One Client Account: ", client_account[0])
    print("\n")

    #print("All the Account IBAN: ", account_iban)
    print("One Account IBAN: ", account_iban[0])
    print("\n")

    #print("All the Account Balance: ", account_balance)
    print("One Account Balance: ", account_balance[0])
    print("\n")

    #print("All the Customer Cards: ", customer_cards)
    print("One Customer Card: ", customer_cards[0])
    print("\n")

    #print("All the Customer Cards to Accounts: ", customer_cards_to_accounts)
    print("One Customer Cards to Account:", customer_cards_to_accounts[0])
    print("\n")

    #print("All the Card Limits: ", card_limits)
    print("One Card Limit: ", card_limits[0])
    print("\n")

    #print("All the Bargains: ", bargains)
    print("One Bargain: ", bargains[0])
    print("\n")

    #print("All the Outgoing Bargains: ", outgoing_bargains)
    print("One Outgoing Bargain: ", outgoing_bargains[0])
    print("\n")

    #print("All the Incoming Bargains: ", incoming_bargains)
    print("One Incoming Bargain: ", incoming_bargains[0])
    print("\n")

    #print("All the International Bargains: ", international_bargain)
    print("One International Bargain: ", international_bargain[0])
    print("\n")

    #print("All the Local Bargains: ", local_bargain)
    print("One Local Bargain: ", local_bargain[0])
    print("\n")

    #print("All the Stocks to Accounts: ", stocks_to_accounts)
    print("One Stock to Account: ", stocks_to_accounts[0])
    print("\n")

    #print("All the Loans: ", loans)
    print("One Loan: ", loans[0])
    print("\n")

    #print("All the Loan Payments: ", loan_payments)
    print("One Loan Payment: ", loan_payments[0])
    print("\n")

    #print("All the Loan to Accounts: ", loan_to_account)
    print("One Loan to Account: ", loan_to_account[0])
    print("\n")

# Write all data in file
with open(OUTPUT_FILE_NAME, 'w', encoding="utf-8") as outfile:

    # Write bank_information
    outfile.write("INSERT INTO `bank_information` (`bank_ID` ,`sort_code`, `SWIFT`) VALUES\n")
    result = ""
    for i in banks:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Write currency_list
    outfile.write("INSERT INTO `currency_list` (`currency_ID`, `alphabetic_code`, `symbol`) VALUES\n")
    result = ""
    for i in currencies:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Write stock
    outfile.write("INSERT INTO `stock` (`stock_code`, `stock_name`, `sell_price`, `buy_price`) VALUES\n")
    result = ""
    for i in stocks:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Write regional_information
    outfile.write("INSERT INTO `regional_information` (`regional_information_ID`, `country_name`, `postcode`, `city_name`) VALUES\n")
    result = ""
    counter = 0
    for i in regional_info:
        counter += 1
        result += ('(' + str(counter) +', '+ i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create client_details
    outfile.write("INSERT INTO `client_details` (`reference_number`, `full_name`, `birth_date`, `adress`, `adress_2`, `regional_information_ID`, `telephone_number`) VALUES\n")
    result = ""
    for i in client_details:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create client_access
    outfile.write("INSERT INTO `client_access` (`reference_number`, `password_salt`, `password_hash`) VALUES\n")
    result = ""
    for i in client_access:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create customer_sessions
    outfile.write("INSERT INTO `customer_sessions` (`reference_number`, `customer_IP`, `secret_key_salt`, `secret_key_hashed`, `token_salt`, `token_hashed`, `token_expiry_date`) VALUES\n")
    result = ""
    for i in client_sessions:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create account
    outfile.write("INSERT INTO `account` (`account_number`, `account_status`, `bank_ID`) VALUES\n")
    result = ""
    counter = 0
    for i in accounts:
        counter += 1
        result += ( '(' + str(counter) + ", " + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create client_account
    outfile.write("INSERT INTO `client_account` (`reference_number`, `account_number`) VALUES\n")
    result = ""
    for i in client_account:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create account_IBAN
    outfile.write("INSERT INTO `account_IBAN` (`account_number`, `IBAN`) VALUES\n")
    result = ""
    for i in account_iban:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create account_balance
    outfile.write("INSERT INTO `account_balance` (`account_number`, `currency_ID`, `amount`) VALUES\n")
    result = ""
    for i in account_balance:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create card_details
    outfile.write("INSERT INTO card_details (`card_ID`, `card_salt`,`card_hash`, `CVV_hash`, `PIN_hash`, `internet_shopping_available`, `frozen`) VALUES\n")
    result = ""
    for i in customer_cards:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create account_card
    outfile.write("INSERT INTO `account_card` (`card_ID`, `account_number`, `card_main_currency`) VALUES\n")
    result = ""
    for i in customer_cards_to_accounts:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create card_daily_limit
    outfile.write("INSERT INTO `card_daily_limit` (`card_ID`, `limit_amount`) VALUES\n")
    result = ""
    for i in card_limits:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create bargain
    outfile.write("INSERT INTO `bargain` (`bargain_ID`, `amount`, `currency_ID`, `bargain_status`, `bargain_date`) VALUES\n")
    result = ""
    for i in bargains:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create local_bargain
    outfile.write("INSERT INTO `local_bargain` (`bargain_ID`, `sender_account_number`,	`receiver_account_number`) VALUES\n")
    result = ""
    for i in local_bargain:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")
    
    # Create international_bargain
    outfile.write("INSERT INTO `international_bargain` (`bargain_ID`, `sender_IBAN`, `receiver_IBAN`) VALUES\n")
    result = ""
    for i in international_bargain:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create outgoing_bargain
    outfile.write("INSERT INTO `outgoing_bargain` (`bargain_ID`, `planned_date`) VALUES\n")
    result = ""
    for i in outgoing_bargains:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create incoming_bargain
    outfile.write("INSERT INTO `incoming_bargain` (`bargain_ID`, `receipt_date`) VALUES\n")
    result = ""
    for i in incoming_bargains:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create account_stock
    outfile.write("INSERT INTO `account_stock` (`account_number`, `stock_code`, `shares`) VALUES\n")
    result = ""
    for i in stocks_to_accounts:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create loan
    outfile.write("INSERT INTO `loan` (`loan_ID`, `given_amount`, `repaid_amount`, `currency_ID`) VALUES\n")
    result = ""
    for i in loans:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create loan_payment
    outfile.write("INSERT INTO `loan_payment` (`loan_ID`, `total_expected_number_of_payments`, `first_payment_date`, `payment_due_date`) VALUES\n")
    result = ""
    counter = 0
    for i in loan_payments:
        counter += 1
        result += ( '(' + str(counter) + ", " + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")

    # Create account_loan
    outfile.write("INSERT INTO `account_loan` (`account_number`, `loan_ID`, `payment_rate`) VALUES\n")
    result = ""
    for i in loan_to_account:
        result += ( '(' + i + '),\n')
    result = result[:-2]
    outfile.write(result + ";\n\n")