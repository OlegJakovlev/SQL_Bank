import random
import string
from datetime import date, timedelta

# Dictionary of currency code and symbol
currencies = {
    "USD":"$",
    "EUR":"€",
    "GBP":"£",
    "JPY":"¥",
    "CAD":"$",
    "RUB":"₽",
    "INR":"₹",
    "RSD":"din",
    "AUD":"$",
    "CNY":"¥",
    "NZD":"$",
    "CHF":"Fr",
    "SEK":"kr"
}

# Dictionary of stock code and stock name
stocks = {
    'AAPL': 'Apple',
    'GOOG': 'Google',
    'MSFT': 'Microsoft',
    'FB': 'Facebook',
    'AMZN': 'Amazon',
    'TWTR': 'Twitter',
    'NFLX': 'Netflix',
    'TSLA': 'Tesla',
    'BABA': 'Alibaba',
    'NVDA': 'Nvidia',
    'AMD': 'AMD',
    'INTC': 'Intel',
    'CSCO': 'Cisco',
    'ADBE': 'Adobe',
    'ADP': 'Autodesk',
    'CMCSA': 'Comcast'
}

# Array of all country names
country_names = [
    "Afghanistan","Albania","Algeria","Andorra","Angola","Antigua & Deps","Argentina","Armenia","Australia",
    "Austria","Azerbaijan","Bahamas","Bahrain","Bangladesh","Barbados","Belarus","Belgium","Belize","Benin",
    "Bhutan","Bolivia","Bosnia Herzegovina","Botswana","Brazil","Brunei","Bulgaria","Burkina","Burundi","Cambodia",
    "Cameroon","Canada","Cape Verde","Central African Rep","Chad","Chile","China","Colombia","Comoros","Congo",
    "Costa Rica","Croatia","Cuba","Cyprus","Czech Republic","Denmark","Djibouti","Dominica",
    "Dominican Republic","East Timor","Ecuador","Egypt","El Salvador","Equatorial Guinea","Eritrea","Estonia","Ethiopia",
    "Fiji","Finland","France","Gabon","Gambia","Georgia","Germany","Ghana","Greece","Grenada","Guatemala","Guinea","Guinea-Bissau",
    "Guyana","Haiti","Honduras","Hungary","Iceland","India","Indonesia","Iran","Iraq","Ireland","Israel","Italy",
    "Ivory Coast","Jamaica","Japan","Jordan","Kazakhstan","Kenya","Kiribati","Korea North","Korea South","Kosovo","Kuwait","Kyrgyzstan",
    "Laos","Latvia","Lebanon","Lesotho","Liberia","Libya","Liechtenstein","Lithuania","Luxembourg","Macedonia","Madagascar","Malawi",
    "Malaysia","Maldives","Mali","Malta","Marshall Islands","Mauritania","Mauritius","Mexico","Micronesia","Moldova","Monaco",
    "Mongolia","Montenegro","Morocco","Mozambique","Myanmar","Namibia","Nauru","Nepal","Netherlands","New Zealand",
    "Nicaragua","Niger","Nigeria","Norway","Oman","Pakistan","Palau","Panama","Papua New Guinea","Paraguay","Peru","Philippines",
    "Poland","Portugal","Qatar","Romania","Russian Federation","Rwanda","St Kitts & Nevis","St Lucia","Saint Vincent & the Grenadines",
    "Samoa","San Marino","Sao Tome & Principe","Saudi Arabia","Senegal","Serbia","Seychelles","Sierra Leone","Singapore","Slovakia",
    "Slovenia","Solomon Islands","Somalia","South Africa","South Sudan","Spain","Sri Lanka","Sudan","Suriname","Swaziland","Sweden",
    "Switzerland","Syria","Taiwan","Tajikistan","Tanzania","Thailand","Togo","Tonga","Trinidad & Tobago","Tunisia","Turkey","Turkmenistan",
    "Tuvalu","Uganda","Ukraine","United Arab Emirates","United Kingdom","United States","Uruguay","Uzbekistan","Vanuatu",
    "Vatican City","Venezuela","Vietnam","Yemen","Zambia","Zimbabwe"
]

# Array of random cities in world
cities = [
    "Aberdeen", "Abilene", "Akron", "Albany", "Albuquerque", "Alexandria", "Allentown", "Amarillo", "Anaheim", "Anchorage",
    "Ann Arbor", "Antioch", "Apple Valley", "Appleton", "Arlington", "Arvada", "Asheville", "Athens", "Atlanta", "Atlantic City",
    "Augusta", "Aurora", "Austin", "Bakersfield", "Baltimore", "Barnstable", "Baton Rouge", "Beaumont", "Bel Air", "Bellevue",
    "Berkeley", "Bethlehem", "Billings", "Birmingham", "Bloomington", "Boise", "Boise City", "Bonita Springs", "Boston", "Boulder",
    "Bradenton", "Bremerton", "Bridgeport", "Brighton", "Brownsville", "Bryan", "Buffalo", "Burbank", "Burlington", "Cambridge",
    "Canton", "Cape Coral", "Carrollton", "Cary", "Cathedral City", "Cedar Rapids", "Champaign", "Chandler", "Charleston", "Charlotte",
    "Chattanooga", "Chesapeake", "Chicago", "Chula Vista", "Cincinnati", "Clarke County", "Clarksville", "Clearwater", "Cleveland",
    "College Station", "Colorado Springs", "Columbia", "Columbus", "Concord", "Coral Springs", "Corona", "Corpus Christi", "Costa Mesa",
    "Dallas", "Daly City", "Danbury", "Davenport", "Davidson County", "Dayton", "Daytona Beach", "Deltona", "Denton", "Denver",
    "Des Moines", "Detroit", "Downey", "Duluth", "Durham", "El Monte", "El Paso", "Elizabeth", "Elk Grove", "Elkhart", "Erie",
    "Lincoln", "New York","Los Angeles","Chicago","Houston","Phoenix","Philadelphia","San Antonio","San Diego","Dallas",
    "San Jose","Detroit","Jacksonville","Indianapolis","San Francisco","Columbus","Austin","Memphis","Fort Worth","Baltimore",
    "Charlotte","El Paso","Boston","Seattle","Washington","Milwaukee","Denver","Louisville/Jefferson County","Las Vegas",
    "Nashville-Davidson","Oklahoma City","Portland","Tucson","Albuquerque","Atlanta","Long Beach","Fresno","Sacramento",
    "Mesa","Kansas City","Cleveland","Virginia Beach","Omaha","Miami","Oakland","Tulsa","Honolulu","Minneapolis","Colorado Springs",
    "Arlington","Wichita","Raleigh","St. Louis","Santa Ana","Anaheim","Tampa","Cincinnati","Pittsburgh","Bakersfield",
    "Aurora","Toledo","Riverside","Stockton","Corpus Christi","Newark","Anchorage","Buffalo","St. Paul","Lexington-Fayette",
    "Plano","Fort Wayne","St. Petersburg","Glendale","Jersey City","Henderson","Chandler","Greensboro","Scottsdale","Baton Rouge",
    "Birmingham","Norfolk","Madison","New Orleans","Chesapeake","Orlando","Garland","Hialeah","Laredo","Chula Vista","Lubbock","Reno",
    "Akron","Durham","Rochester","Modesto","Montgomery","Fremont","Shreveport","Arlington","Glendale","Oxford","Nottingham","Manchester",
    "Providence","Tacoma","Shreveport","Reno","Richmond","Spokane","Yonkers","Montgomery","Moreno Valley","Columbus","Aurora","Augusta",
    "Mobile","Little Rock","Amarillo","Salt Lake City","Huntington Beach","Grand Rapids","Tallahassee","Huntsville","Knoxville","Worcester",
    "Brownsville","Newport News","Santa Clarita","Fort Lauderdale","Overland Park","Garden Grove","Oceanside","Jackson","Chattanooga","Rancho Cucamonga",
    "Santa Rosa","Port St. Lucie","Tempe","Ontario","Vancouver","Cape Coral","Springfield","Peoria","Pembroke Pines","Eugene","Salem",
    "London", "Birmingham", "Manchester", "Liverpool", "Leeds", "Sheffield", "Bradford", "Bristol", "Cardiff", "Coventry",
    "Edinburgh", "Exeter", "Glasgow", "Kingston upon Hull", "Luton", "Newcastle upon Tyne", "Norwich", "Portsmouth", "Salford",
    "Stoke-on-Trent", "Swansea", "Wolverhampton", "Belfast", "Bournemouth", "Brighton", "Cambridge", "Canterbury", "Cheltenham",
    "Colchester", "Derby", "Dover", "Durham", "Ely", "Gloucester", "Hereford", "Inverness", "Kingston upon Hull", "Lichfield",
    "Moscow","Saint Petersburg","Novosibirsk","Yekaterinburg","Nizhny Novgorod","Samara","Omsk","Kazan","Chelyabinsk","Rostov-on-Don",
    "Aizkraukle", "Aluksnes", "Balvi", "Bauska", "Broceni", "Dagda", "Daugavpils", "Dobele", "Gulbene", "Jekabpils", "Jelgava",
    "Jurmala", "Kuldiga", "Liepaja", "Limbazi", "Ludza", "Madona", "Ogre", "Ozolnieki", "Preili", "Rezekne", "Riga", "Ropazi",
    "Berlin", "Hamburg", "Munich", "Cologne", "Frankfurt", "Stuttgart", "Dortmund", "Dresden", "Leipzig", "Nuremberg", "Düsseldorf",
    "Bremen", "Hannover", "Nürnberg", "Duisburg", "Essen", "Bochum", "Wuppertal", "Bielefeld", "Bonn", "Münster", "Mönchengladbach",
    "Aichi", "Akita", "Aomori", "Chiba", "Ehime", "Fukui", "Fukuoka", "Fukushima", "Gifu", "Gunma", "Hiroshima", "Hokkaido",
    "Hyogo", "Ibaraki", "Ishikawa", "Iwate", "Kagawa", "Kagoshima", "Kanagawa", "Kochi", "Kumamoto", "Kyoto", "Mie", "Miyagi",
    "Miyazaki", "Nagano", "Nagasaki", "Nara", "Niigata", "Oita", "Okayama", "Okinawa", "Osaka", "Saga", "Saitama", "Shiga",
    "Shimane", "Shizuoka", "Tochigi", "Tokushima", "Tokyo", "Tottori", "Toyama", "Wakayama", "Yamagata", "Yamaguchi", "Yamanashi"
]

# Random world postcodes
postcodes = [
    "AB1 2CD", "CD3 4EF", "EF5 6GH", "GH7 8IJ", "IJ9 0KL", "KL1 2MN", "MN3 4OP", "OP5 6QR", "QR7 8ST", "ST4 0UV", "UV1 2WX",
    "WX3 4YZ", "YZ5 6AB", "AB2 3CD", "CD4 5EF", "EF6 7GH", "GH8 9IJ", "IJ0 1KL", "KL2 3MN", "MN4 5OP", "OP6 8QR", "QR9 0ST",
    "ST0 1UV", "UV2 3WX", "WX4 5YZ", "YZ6 7AB", "AB3 4CD", "CD5 6EF", "EF7 8GH", "GH0 9IJ", "IJ1 0KL", "KL3 4MN", "MN5 6OP",
    "OP7 0QR", "QR0 1ST", "ST2 2UV", "UV3 4WX", "WX5 6YZ", "YZ7 8AB", "AB4 5CD", "CD6 7EF", "EF8 9GH", "GH1 0IJ", "IJ2 1KL",
    "12345", "23456", "34567", "45678", "56789", "67890", "78901", "89012", "90123", "01234", "12346", "23456", "34567", "45678",
    "56789", "67890", "78901", "89012", "90123", "01234", "12346", "23456", "34567", "45678", "56789", "67890", "78901", "89012",
    "111-0051", "111-0052", "111-0053", "111-0054", "111-0055", "111-0056", "111-0057", "111-0058", "111-0059", "111-0060", "111-0061",
    "111-0062", "111-0063", "111-0064", "111-0065", "111-0066", "111-0067", "111-0068", "111-0069", "111-0070", "111-0071", "111-0072",
    "111-0073", "111-0074", "111-0075", "111-0076", "111-0077", "111-0078", "111-0079", "111-0080", "111-0081", "111-0082", "111-0083",
    "10369", "10405", "10437", "10457", "10459", "10473", "10477", "10487", "10489", "10491", "10493", "10497", "10499", "10513",
    "10517", "10519", "10523", "10527", "10531", "10533", "10537", "10539", "10549", "10555", "10557", "10559", "10561", "10563",
    "10565", "10567", "10569", "10573", "10575", "10579", "10583", "10585", "10587", "10589", "10591", "10593", "10595", "10597",
    "190000", "190001", "190002", "190003", "190004", "190005", "190006", "190007", "190008", "190009", "190010","190011", "190012",
    "190013", "190014", "190015", "190016", "190017", "190018", "190019", "190020", "190021","190022"
]

generated_sorts = []
def generate_sort():
    result = ""
    while result == "":
        result = ''.join(random.choice(string.digits) for _ in range(6))
        if result in generated_sorts:
            result = ""
    generated_sorts.append(result)
    return result

swift_counter = -1
def generate_swift():
    global swift_counter
    swift_counter += 1
    if (swift_counter < 10):
        return 'LSTNGS0'+str(swift_counter)
    return 'LSTNGS' + str(swift_counter)

def get_all_currencies():
    return currencies

def get_all_stocks():
    return stocks

def get_random_regional_information():
    return '"' + random.choice(country_names) + '", "' + random.choice(postcodes) + '", "' + random.choice(cities) + '"'

generated_reference_numbers = []
def generate_reference_number():
    global generated_reference_numbers
    result = ""
    while result == "":
        numeric_part = "".join(random.choice(string.digits) for _ in range(9))
        letter_part = "".join(random.choice(string.ascii_lowercase) for _ in range(3))
        result += numeric_part + letter_part

        if result in generated_reference_numbers:
            result = ""

    generated_reference_numbers.append(result)
    return result

def generate_full_name():
    first_names = [
        "Alfred", "Alice", "Alison", "Amanda", "Amy", "Andrea", "Angela", "Anita", "Ann", "Anne", "Annette", "Annie", "Antonia",
        "April", "Arlene", "Ashley", "Audrey", "Barbara", "Beatrice", "Bernice", "Beverly", "Beverly", "Beverly", "Beverly"
    ]

    last_names = [
        "Smith", "Johnson", "Williams", "Jones", "Brown", "Davis", "Miller", "Wilson", "Moore", "Taylor", "Anderson", "Thomas",
        "Jackson", "White", "Harris", "Martin", "Thompson", "Garcia", "Martinez", "Robinson", "Clark", "Rodriguez", "Lewis"
    ]

    return random.choice(first_names)+" "+random.choice(last_names)

def generate_date(min_year, max_year, min_month=1, max_month=12, min_day=1, max_day=28):
    year = random.randint(min_year, max_year)
    month = random.randint(min_month, max_month)
    day = random.randint(min_day, max_day)
    return str(year) + "/" + str(month) + "/" + str(day)

def generate_date_between(min_date, max_date):
    tmp = [min_date + timedelta(days=i) for i in range((max_date-min_date).days + 1)]
    return (str(random.choice(tmp)).replace('-','/'))

def generate_random_time():
    return (str(random.randint(0, 23)) + ":" + str(random.randint(0, 59)) + ":" + str(random.randint(0, 59)))

def generate_address():
    streets_names = [
        "Main", "High", "Pearl", "Maple", "Park", "Central", "Pine", "Lake", "Hill", "Parkway", "Church", "Valley", "Avenue",
        "Park", "Street", "Boulevard", "Circle", "Drive", "Road", "Lane", "Place", "Square", "Road", "Way", "Trail", "Circle"
    ]

    random_street = random.choice(streets_names) + " Street"
    random_number = random.randint(1, 9999)
    return random_street + " " + str(random_number)

def generate_room_string():
    result = "Room "
    random_number = random.randint(1, 1000)
    result += str(random_number)
    return result

def generate_international_number():
    result = ""
    for i in range(0, random.randint(9, 11)):
        result += str(random.randint(0, 9))
    return result

def generate_salt(length = 64):
    # Exclude " characters from the list
    punctuation = "!#$%&'()*+,-./:;<=>?@[]^_`{|}~ "
    return ''.join(random.choice(string.ascii_letters + string.digits + punctuation) for _ in range(length))

def generate_hash(length = 128):
    return ''.join(random.choice(string.hexdigits) for _ in range(length)).lower()

def get_account_status():
    possible_statuses = ["Waiting for Deposit","Opened","Pending Termination","Closed","Archived"]
    return random.choice(possible_statuses)

def generate_iban(account_number):
    default_iban_length = 24 #(2 - prefix, 2 suffix, 5 random numbers, 15 account_number)

    iban_prefixes = [
        "AL", "AD", "AT", "AZ", "BH", "BE", "BA", "BR", "BG", "CR", "HR", "CY", "CZ", "DK", "DO", "SV", "EE", "FI", "FR",
        "GE", "DE", "GI", "GR", "GL", "GT", "HU", "IS", "IE", "IL", "IT", "KZ", "KW", "LV", "LB", "LI", "LT", "LU", "MK",
        "MT", "MR", "MU", "MC", "MD", "ME", "NL", "NO", "PL", "PT", "RO", "SM", "SA", "RS", "SK", "SI", "ES", "SE", "CH",
        "TN", "TR", "AE", "GB", "VG"
    ]

    #iban_prefix = random.choice(iban_prefixes)
    #iban_suffix = str(random.randint(0, 9)) + str(random.randint(0, 9))

    iban_prefix = "GB"
    iban_suffix = "02"
    iban_random = "28189"
    
    current_iban_length = len(iban_prefix) + len(iban_suffix) + len(iban_random) + len(str(account_number))
    iban_account_number = ''.join('0' for i in range(default_iban_length-current_iban_length))

    result = iban_prefix + iban_suffix + iban_random + iban_account_number + str(account_number)
    return result

def generate_number(min, max):
    return random.randint(min, max)

def random_bargain_status():
    statuses = ["Pending","Failed", "Succesful"]
    return random.choice(statuses)

def generate_price(min_number = 0.01, max_number = 10000.00, default_round = 2):
    return round(random.uniform(min_number, max_number), default_round)

def generate_bool():
    return random.choice([True, False])

def generate_ip():
    return str(random.randint(0, 255)) + "." + str(random.randint(0, 255)) + "." + str(random.randint(0, 255)) + "." + str(random.randint(0, 255))

if __name__ == "__main__":
    """
    print("Full Name: " + generate_full_name())
    print("Birth Date: " + generate_date(1900, 2003))
    print("Adress: " + generate_address())
    print("Adress 2: " + generate_room_string())
    print("Phone Number: +" + generate_international_number())
    print("Salt: " + generate_salt(64))
    print("Password hash: " + generate_hash(128))
    print("Account Status: " + get_account_status())
    print("Account IBAN: " + generate_iban(generate_number(1, 999999999)))
    print("Bargain Status: " + random_bargain_status())
    print("Stock Price: " + str(generate_price()))
    print("Stock is Freezed: " + str(generate_bool()))
    print("Login IP: " + generate_ip())
    """
    generate_date_between(date(2021, 11, 1), date(2021, 11, 30))