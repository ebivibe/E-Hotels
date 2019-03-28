import random

hotel_chain = "HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('%s', '%s', %d, '%s', '%s', '%s', '%s', '%s');"
hotel = "Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (%d, %d, '%s', %d, '%s', '%s', '%s', '%s', '%s');"
employee = "Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (%d, '%s', %d, %d, '%s', '%s', '%s', '%s', '%s', '%s');"
customer = "Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (%d, '%s', %d, '%s', '%s', '%s', '%s', '%s', '%s');"
room = "Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (%d, %d, %.2f, %d, %s, %s, %s, %s);"
booking = "BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (%s, %s, %s, %s, %d, %d);"
amenity = "Amenity(room_id, name, description) VALUES (%d, '%s', %s);"
role = "Role(name, description) VALUES ('%s', %s);"
employeerole = "EmployeeRole(employee_ssn, role_id) VALUES (%d, %d);"
chainphonenumber = "ChainPhoneNumber(chain_id, phone_number) VALUES (%d, '%s');"
hotelphonenumber = "HotelPhoneNumber(hotel_id, phone_number) VALUES (%d, '%s');"
ins = "INSERT INTO "

chains = 5
hotels = 8 # Per chain
rooms = 5 # Per hotel
employees = 5 # Per hotel
customers = 3 # Per hotel
bookings = 3 # Per customer

fname = "MockData.sql"
queries = []

hname = "Hotels "
first_names = ["Bob", "Andrew", "Ashley", "Elizabeth", "Liam", "David", "Hudi", "Alex", "Natalia", "Ivana", "Jon", "Nick", "Ryan", "Meg", "Sarah", "Susan", "Mary", "Emily", "Sahil", "Paul"]
last_names = ["Smith", "Johnson", "Williams", "Jones", "Brown", "Davis", "Miller", "Wilson", "Hernandez", "Young", "Rogers", "Reed", "Cook", "Wood", "Price", "Sanchez", "Stewart", "Ward", "Perez"]
cities = ["Toronto", "London", "Milton", "Ottawa", "Mississauga", "Oshawa", "Oakville", "Brampton", "Hamilton", "Stratford"]
street_names = ["Bank", "First", "Third", "Main", "Second", "Metcalfe", "Bay", "Pine", "Elm", "Oak", "Willow", "Laurier"]
street_types = ["Avenue", "Street", "Crescent", "Boulevard", "Lane", "Way"]
am_names = ["Coffee Machine", "Mini-Fridge", "TV", "Room service", "Air conditioner", "Laundry Machine"]
role_names = ["Custodian", "Maid", "Bellboy", "Front Desk Person"]


n = len(first_names)
m = len(last_names)
c = len(cities)
s = len(street_names)
t = len(street_types)
a = len(am_names)
r = len(role_names)

employee_ssn = 0
customer_ssn = 0
hotel_id = 0
room_ids = 0
reservations = {}

for i in range(chains):
    chain = i + 1
    name = "Hotels " + str(chain)
    email = "hotel%d@hotels.com" % chain
    street_number = random.randint(1, 300)
    street_name = street_names[random.randint(0, s-1)] + " " + street_types[random.randint(0, t-1)]
    city = cities[random.randint(0, c-1)]
    province = "Ontario"
    country = "Canada"
    postal = "X1X 1X1"
    query = ins + (hotel_chain % (name, email, street_number, street_name, city, province, country, postal))
    queries.append(query)
    for j in range(hotels):
        hotel_id += 1
        h = j + 1
        chain_id = i+1
        category = (j % 5) + 1
        email = "hotel%d@hotels%d.com" % (h, chain)
        street_number = random.randint(1, 300)
        street_name = street_names[random.randint(0, s-1)] + " " + street_types[random.randint(0, t-1)]
        city = cities[random.randint(0, c-1)]
        province = "Ontario"
        country = "Canada"
        postal = "X1X 1X1"
        query = ins + (hotel % (chain_id, category, email, street_number, street_name, city, province, country, postal))
        queries.append(query)
        room_numbers = []
        for k in range(rooms):
            room_ids += 1
            room_number = random.randint(1, 100)
            price = random.randint(40, 60) * category / 1.2
            capacity = random.randint(2, 6)
            sea_view = ("%s" % (random.randint(1, 17) > 10)).lower()
            mountain_view = ("%s" % (random.randint(1, 37) > 20)).lower()
            damages = ("%s" % (random.randint(1, 100) < 15)).lower()
            can_be_extended = ("%s" % (random.randint(1, 100) < 50)).lower()
            query = ins + (room % (room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended))
            queries.append(query)
        
        for k in range(employees):
            employee_ssn += 1
            name = first_names[random.randint(0, n-1)] + " " + last_names[random.randint(0, m-1)]
            street_number = random.randint(1, 400)
            street_name = street_names[random.randint(0, s-1)] + " " + street_types[random.randint(0, t-1)]
            city = cities[random.randint(0, c-1)]
            province = "Ontario"
            country = "Canada"
            postal = "X1X 1X1"
            password = "password"
            query = ins + (employee % (employee_ssn, name, hotel_id, street_number, street_name, city, province, country, postal, password))
            queries.append(query)
        
        for k in range(customers):
            customer_ssn += 1
            name = first_names[random.randint(0, n-1)] + " " + last_names[random.randint(0, m-1)]
            street_number = random.randint(1, 400)
            street_name = street_names[random.randint(0, s-1)] + " " + street_types[random.randint(0, t-1)]
            city = cities[random.randint(0, c-1)]
            province = "Ontario"
            country = "Canada"
            postal = "X1X 1X1"
            password = "password"
            query = ins + (customer % (customer_ssn, name, street_number, street_name, city, province, country, postal, password))
            queries.append(query)
            
            for l in range(bookings):
                reservation_date = "now()"
                room_id = random.randint(1, room_ids)
                if room_id not in reservations:
                    reservations[room_id] = []
                while True:
                    in_d = random.randint(0, 70*bookings)
                    out_d = random.randint(in_d+1, in_d + 7)
                    rang = set(range(in_d, out_d))
                    clear = True
                    for reservation in reservations[room_id]:
                        if rang.intersection(reservation) != set():
                            clear = False
                    if clear:
                        reservations[room_id].append(list(rang))
                        break
                check_in_date = "now() + INTERVAL '%d DAY'" % in_d
                check_out_date = "now() + INTERVAL '%d DAY'" % out_d
                checked_in = "false"
                customer_ssn = customer_ssn
                query = ins + (booking % (reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn))
                queries.append(query)

for i in range(room_ids):
    amenities = bin(random.randint(0, (1<<a)-1))[2:]
    if len(amenities) < 6:
        amenities = ('0' * (6-len(amenities))) + amenities
    for j in range(len(amenities)):
        if amenities[j] == "1":
            room_id = i+1
            name = am_names[j]
            description = "NULL"
            query = ins + (amenity % (room_id, name, description))
            queries.append(query)

for i in range(r):
    query = ins + (role % (role_names[i], "NULL"))
    queries.append(query)

for i in range(employee_ssn):
    er = random.randint(1, r)
    query = ins + (employeerole % (i+1, er))
    queries.append(query)

for i in range(chains):
    phone_number = str(random.randint(1000000000, 9999999999))
    query = ins + (chainphonenumber % (i+1, phone_number))
    queries.append(query)

for i in range(hotel_id):
    phone_number = str(random.randint(1000000000, 9999999999))
    query = ins + (hotelphonenumber % (i+1, phone_number))
    queries.append(query)

with open(fname, "w") as f:
    for q in queries:
        f.write(q + "\n")