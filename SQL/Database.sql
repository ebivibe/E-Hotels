CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS HotelChain CASCADE;
CREATE TABLE HotelChain (
 chain_id SERIAL PRIMARY KEY,
 chain_name VARCHAR (255) NOT NULL,
 num_hotels INT DEFAULT 0 NOT NULL,
 email VARCHAR(255) NOT NULL,
 street_number INT NOT NULL,
 street_name VARCHAR(255) NOT NULL,
 unit VARCHAR(255),
 city VARCHAR(255) NOT NULL,
 province VARCHAR(255) NOT NULL,
 country VARCHAR(255) NOT NULL,
 zip VARCHAR(255) NOT NULL,
 CONSTRAINT street_number CHECK (street_number > 0),
 CONSTRAINT num_hotels CHECK (num_hotels >= 0)
);

DROP TABLE IF EXISTS ChainPhoneNumber CASCADE;
CREATE TABLE ChainPhoneNumber(
    chain_id INT NOT NULL REFERENCES HotelChain(chain_id) ON DELETE CASCADE,
    phone_number VARCHAR(255) NOT NULL,
    PRIMARY KEY(chain_id, phone_number)
);

DROP TABLE IF EXISTS Hotel CASCADE;
CREATE TABLE Hotel (
 hotel_id SERIAL PRIMARY KEY,
 chain_id INTEGER NOT NULL REFERENCES HotelChain(chain_id) ON DELETE CASCADE,
 category INT NOT NULL,
 num_rooms INT DEFAULT 0 NOT NULL,
 email VARCHAR(255) NOT NULL,
 street_number INT NOT NULL,
 street_name VARCHAR(255) NOT NULL,
 unit VARCHAR(255),
 city VARCHAR(255) NOT NULL,
 province VARCHAR(255) NOT NULL,
 country VARCHAR(255) NOT NULL,
 zip VARCHAR(255) NOT NULL,
 CONSTRAINT street_number check (street_number > 0),
 CONSTRAINT categoryabove check (category >= 1),
 CONSTRAINT categorybelow check (category <= 5)
);

DROP TABLE IF EXISTS HotelPhoneNumber CASCADE;
CREATE TABLE HotelPhoneNumber(
    hotel_id INT NOT NULL REFERENCES Hotel(hotel_id) ON DELETE CASCADE,
    phone_number VARCHAR(255) NOT NULL,
    PRIMARY KEY(hotel_id, phone_number)
);

DROP TABLE IF EXISTS Room CASCADE;
CREATE TABLE Room(
  room_id SERIAL PRIMARY KEY,
  room_number INT NOT NULL,
  hotel_id INT NOT NULL REFERENCES Hotel(hotel_id) ON DELETE CASCADE,
  price INT NOT NULL,
  capacity INT NOT NULL,
  sea_view BOOLEAN NOT NULL,
  mountain_view BOOLEAN NOT NULL,
  damages BOOLEAN NOT NULL,
  can_be_extended BOOLEAN NOT NULL,
  CONSTRAINT room_number CHECK (room_number > 0),
  CONSTRAINT price CHECK (price >= 0),
  CONSTRAINT capacity CHECK (capacity > 0)
);

DROP TABLE IF EXISTS Amenity CASCADE;
CREATE TABLE Amenity(
    room_id INT NOT NULL REFERENCES Room(room_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    PRIMARY KEY(room_id, name)
);

DROP TABLE IF EXISTS Employee CASCADE;
CREATE TABLE Employee (
 SSN INT PRIMARY KEY,
 name VARCHAR (255) NOT NULL,
 hotel_id INT NOT NULL REFERENCES Hotel(hotel_id) ON DELETE CASCADE,
 street_number INT NOT NULL,
 street_name VARCHAR(255) NOT NULL,
 unit VARCHAR(255),
 city VARCHAR(255) NOT NULL,
 province VARCHAR(255) NOT NULL,
 country VARCHAR(255) NOT NULL,
 zip VARCHAR(255) NOT NULL,
 password VARCHAR(255) NOT NULL,
 CONSTRAINT street_number CHECK (street_number > 0),
 CONSTRAINT password CHECK (char_length(password) >= 5)
);

DROP TABLE IF EXISTS Manages CASCADE;
CREATE TABLE Manages(
 SSN INT NOT NULL REFERENCES Employee(SSN) ON DELETE CASCADE,
 hotel_id INT NOT NULL REFERENCES Hotel(hotel_id) ON DELETE CASCADE,
 PRIMARY KEY(SSN, hotel_id)
);

DROP TABLE IF EXISTS Role CASCADE;
CREATE TABLE Role(
 role_id SERIAL PRIMARY KEY,
 name VARCHAR(255) NOT NULL,
 description VARCHAR(255)
);

DROP TABLE IF EXISTS EmployeeRole CASCADE;
CREATE TABLE EmployeeRole(
 employee_ssn INT NOT NULL REFERENCES Employee(SSN) ON DELETE CASCADE,
 role_id INT NOT NULL REFERENCES Role(role_id) ON DELETE CASCADE,
 PRIMARY KEY(employee_ssn, role_id)
);

DROP TABLE IF EXISTS Customer CASCADE;
CREATE TABLE Customer(
    SSN INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    street_number INT NOT NULL,
    street_name VARCHAR(255) NOT NULL,
    unit VARCHAR(255),
    city VARCHAR(255) NOT NULL,
    province VARCHAR(255) NOT NULL,
    country VARCHAR(255) NOT NULL,
    zip VARCHAR(255) NOT NULL,
    registration_date TIMESTAMP DEFAULT NOW() NOT NULL,
    password VARCHAR(255) NOT NULL,
    CONSTRAINT street_number CHECK (street_number > 0),
     CONSTRAINT password CHECK (char_length(password) >= 5)
);

DROP TABLE IF EXISTS BookingRental CASCADE;
CREATE TABLE BookingRental(
    booking_id SERIAL PRIMARY KEY,
    reservation_date TIMESTAMP NOT NULL,
    check_in_date TIMESTAMP NOT NULL,
    check_out_date TIMESTAMP NOT NULL,
    checked_in BOOLEAN DEFAULT FALSE NOT NULL,
    paid BOOLEAN DEFAULT FALSE NOT NULL,
    room_id INT NOT NULL REFERENCES Room(room_id) ON DELETE CASCADE,
    customer_ssn INT NOT NULL REFERENCES Customer(SSN) ON DELETE CASCADE,
    employee_ssn INT REFERENCES Employee(SSN) ON DELETE CASCADE,
    CONSTRAINT booking_id CHECK (booking_id > 0),
    CONSTRAINT dates1 CHECK (check_in_date<check_out_date),
    CONSTRAINT dates2 CHECK (reservation_date<=check_in_date),
    CONSTRAINT overlapping EXCLUDE USING gist (tsrange(check_in_date, check_out_date) WITH &&, room_id WITH =)
);


DROP TABLE IF EXISTS Archive CASCADE;
CREATE TABLE Archive (
    archive_id INT PRIMARY KEY,
    room_number INT NOT NULL,
    street_number INT NOT NULL,
    street_name VARCHAR(255) NOT NULL,
    unit VARCHAR(255),
    hotel_city VARCHAR(255) NOT NULL,
    hotel_province VARCHAR(255) NOT NULL,
    hotel_zip VARCHAR(255) NOT NULL,
    hotel_country VARCHAR(255) NOT NULL,
    check_in_date TIMESTAMP NOT NULL,
    hotel_chain_name VARCHAR(255) NOT NULL,
    reservation_date TIMESTAMP,
    check_out_date TIMESTAMP NOT NULL,
    checked_in BOOLEAN NOT NULL,
    paid BOOLEAN DEFAULT FALSE NOT NULL,
    customer_ssn INT NOT NULL,
    employee_ssn INT,
    CONSTRAINT archive_id CHECK (archive_id > 0),
    CONSTRAINT street_number CHECK (street_number > 0),
    CONSTRAINT room_number CHECK (room_number > 0)
);

CREATE OR REPLACE FUNCTION archive_data() RETURNS TRIGGER AS $archive$
	BEGIN INSERT INTO Archive(archive_id, room_number, street_number, street_name, unit, hotel_city, hotel_province, hotel_country, 
        hotel_zip, check_in_date, hotel_chain_name, reservation_date, check_out_date, customer_ssn, employee_ssn, checked_in, paid)
            SELECT B.booking_id as archive_id,
                R.room_number, 
                H.street_number,
                H.street_name,
                H.unit,
                H.city,
                H.province,
                H.country,
                H.zip,
                B.check_in_date,
                HC.chain_name,
                B.reservation_date,
                B.check_out_date,
                B.customer_ssn,
                B.employee_ssn,
                B.checked_in,
				B.paid
            FROM Room R, 
                Hotel H, 
                HotelChain HC, 
                BookingRental B
            WHERE NEW.booking_id = B.booking_id AND
                B.room_id = R.room_id AND
                R.hotel_id = H.hotel_id AND
                H.chain_id = HC.chain_id;
			RETURN NULL;
	END;
$archive$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_archive() RETURNS TRIGGER AS $update_archive$
    BEGIN UPDATE Archive
        SET checked_in = subquery.checked_in,
            paid = subquery.paid,
            employee_ssn = subquery.employee_ssn,
            check_in_date = subquery.check_in_date,
            check_out_date = subquery.check_out_date,
            room_number = subquery.room_number
        FROM (SELECT R.room_number, 
                B.check_in_date,
                B.check_out_date,
                B.employee_ssn,
                B.checked_in,
				B.paid
            FROM Room R, 
                BookingRental B
            WHERE NEW.booking_id = B.booking_id AND
                B.room_id = R.room_id) as subquery
        WHERE Archive.archive_id = NEW.booking_id;
        RETURN NULL;
    END;
$update_archive$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION inc_room() RETURNS TRIGGER AS $inc_room$
    BEGIN UPDATE Hotel
        SET num_rooms = num_rooms + 1
        WHERE hotel_id = NEW.hotel_id;
    RETURN NULL;
    END;
$inc_room$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION dec_room() RETURNS TRIGGER AS $dec_room$
    BEGIN UPDATE Hotel
        SET num_rooms = num_rooms - 1
        WHERE hotel_id = NEW.hotel_id;
    RETURN NULL;
    END;
$dec_room$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION inc() RETURNS TRIGGER AS $inc$
	BEGIN UPDATE HotelChain 
		SET num_hotels = num_hotels + 1 
		WHERE chain_id = NEW.chain_id;
    RETURN NULL;
	END; 
$inc$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decr() RETURNS TRIGGER AS $decr$
    BEGIN UPDATE HotelChain
        SET num_hotels = num_hotels - 1
        WHERE chain_id = OLD.chain_id;
    RETURN NULL;
    END;
$decr$ LANGUAGE plpgsql;
		
DROP TRIGGER IF EXISTS add_archive ON BookingRental;
CREATE TRIGGER add_archive 
    AFTER INSERT ON BookingRental 
	FOR EACH ROW
	EXECUTE FUNCTION archive_data();		

DROP TRIGGER IF EXISTS update_archive ON BookingRental;
CREATE TRIGGER update_archive
    AFTER UPDATE ON BookingRental
    FOR EACH ROW
    EXECUTE FUNCTION update_archive();

DROP TRIGGER IF EXISTS increment ON Hotel;
CREATE TRIGGER increment 
    AFTER INSERT ON Hotel 
	FOR EACH ROW
	EXECUTE FUNCTION inc();

DROP TRIGGER IF EXISTS decrement ON Hotel;
CREATE TRIGGER decrement
    AFTER DELETE ON Hotel
    FOR EACH ROW
    EXECUTE FUNCTION decr();

DROP TRIGGER IF EXISTS inc_rooms ON Room;
CREATE TRIGGER inc_rooms
    AFTER INSERT ON Room
    FOR EACH ROW
    EXECUTE FUNCTION inc_room();

DROP TRIGGER IF EXISTS dec_rooms ON Room;
CREATE TRIGGER dec_roooms
    AFTER DELETE ON Room
    FOR EACH ROW
    EXECUTE FUNCTION dec_room();DROP VIEW IF EXISTS employeeroles;
CREATE VIEW employeeroles AS
  SELECT r.role_id, er.employee_ssn as ssn, r.name, r.description
   FROM Role r
     INNER JOIN EmployeeRole er ON r.role_id = er.role_id ;

DROP VIEW IF EXISTS bookinginfo;
CREATE VIEW bookinginfo as
  SELECT br.booking_id, br.reservation_date, br.check_in_date, br.check_out_date, br.checked_in, br.paid, 
  r.room_number, hc.chain_name, h.hotel_id, h.street_number, h.street_name, h.unit, h.city, h.province, h.country, h.zip, br.employee_ssn,
  br.customer_ssn
  FROM BookingRental br
  INNER JOIN Room r on br.room_id = r.room_id
  INNER JOIN Hotel h on r.hotel_id = h.hotel_id
  INNER JOIN HotelChain hc on h.chain_id = hc.chain_id;

DROP VIEW IF EXISTS roomarea;
CREATE VIEW roomarea AS
  SELECT r.room_number, r.room_id, hc.chain_name, h.hotel_id, h.street_number, h.street_name, h.unit, h.city, h.province, h.country
  FROM Room r
  INNER JOIN Hotel h on r.hotel_id = h.hotel_id
  INNER JOIN HotelChain hc on h.chain_id = hc.chain_id;
  
DROP VIEW IF EXISTS roomcapacity;
CREATE VIEW roomcapacity AS
  SELECT h.hotel_id, r.room_id, r.room_number, r.capacity, r.can_be_extended
  FROM Hotel h, Room r
  WHERE r.hotel_id = h.hotel_id;

DROP VIEW IF EXISTS roominfo;
CREATE VIEW roominfo AS
  SELECT r.room_id,
    r.room_number,
    r.capacity,
    r.price,
    r.can_be_extended,
    r.sea_view,
    r.mountain_view,
    r.damages,
    h.category,
    h.street_number,
    h.street_name,
    h.unit,
    h.city,
    h.province,
    h.country,
    h.zip,
    hc.chain_name,
    h.num_rooms
  FROM Hotel h, Room r, HotelChain hc
  WHERE h.hotel_id = r.hotel_id AND
    hc.chain_id = h.chain_id; INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 1', 'hotel1@hotels.com', 224, 'Laurier Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 1, 'hotel1@hotels1.com', 48, 'Willow Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 1, 50.00, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (69, 1, 35.83, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 1, 45.83, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (88, 1, 47.50, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (45, 1, 45.00, 5, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (1, 'Ashley Rogers', 1, 304, 'Third Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (2, 'Nick Brown', 1, 123, 'Second Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (3, 'Bob Young', 1, 286, 'Oak Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (4, 'Jon Perez', 1, 170, 'Second Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (5, 'Bob Jones', 1, 399, 'Metcalfe Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (1, 'Elizabeth Johnson', 390, 'Laurier Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '100 DAY', now() + INTERVAL '107 DAY', false, 5, 1);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '143 DAY', now() + INTERVAL '149 DAY', false, 1, 1);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '195 DAY', now() + INTERVAL '198 DAY', false, 3, 1);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (2, 'Bob Wood', 1, 'Pine Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '91 DAY', now() + INTERVAL '96 DAY', false, 3, 2);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '165 DAY', now() + INTERVAL '169 DAY', false, 2, 2);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '22 DAY', now() + INTERVAL '27 DAY', false, 5, 2);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (3, 'David Smith', 383, 'Third Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '91 DAY', now() + INTERVAL '97 DAY', false, 5, 3);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '158 DAY', now() + INTERVAL '165 DAY', false, 2, 3);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '182 DAY', now() + INTERVAL '185 DAY', false, 3, 3);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 2, 'hotel2@hotels1.com', 121, 'Oak Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (15, 2, 81.67, 3, true, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 2, 95.00, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 2, 88.33, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (55, 2, 91.67, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 2, 95.00, 6, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (6, 'Bob Davis', 2, 272, 'Main Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (7, 'Hudi Williams', 2, 400, 'Metcalfe Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (8, 'Alex Stewart', 2, 293, 'First Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (9, 'Paul Brown', 2, 205, 'Metcalfe Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (10, 'Ivana Stewart', 2, 305, 'Third Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (4, 'David Cook', 312, 'Second Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '186 DAY', now() + INTERVAL '190 DAY', false, 2, 4);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '14 DAY', now() + INTERVAL '20 DAY', false, 2, 4);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '178 DAY', now() + INTERVAL '179 DAY', false, 3, 4);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (5, 'Andrew Price', 285, 'Bank Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '44 DAY', now() + INTERVAL '51 DAY', false, 6, 5);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '93 DAY', now() + INTERVAL '100 DAY', false, 10, 5);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '167 DAY', now() + INTERVAL '171 DAY', false, 6, 5);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (6, 'Paul Wilson', 328, 'Elm Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '206 DAY', now() + INTERVAL '207 DAY', false, 7, 6);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '108 DAY', now() + INTERVAL '110 DAY', false, 4, 6);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '27 DAY', now() + INTERVAL '34 DAY', false, 7, 6);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 3, 'hotel3@hotels1.com', 33, 'Laurier Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (87, 3, 150.00, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (2, 3, 135.00, 4, true, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (3, 3, 105.00, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (4, 3, 127.50, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (45, 3, 120.00, 6, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (11, 'Meg Brown', 3, 385, 'Bank Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (12, 'Ashley Young', 3, 129, 'Main Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (13, 'Ashley Jones', 3, 305, 'First Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (14, 'Emily Smith', 3, 55, 'Elm Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (15, 'Liam Stewart', 3, 348, 'Elm Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (7, 'Natalia Price', 130, 'Bay Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '193 DAY', now() + INTERVAL '194 DAY', false, 2, 7);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '90 DAY', now() + INTERVAL '91 DAY', false, 14, 7);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '128 DAY', now() + INTERVAL '132 DAY', false, 3, 7);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (8, 'Natalia Brown', 61, 'Third Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '94 DAY', now() + INTERVAL '99 DAY', false, 13, 8);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '73 DAY', now() + INTERVAL '80 DAY', false, 1, 8);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '27 DAY', now() + INTERVAL '30 DAY', false, 12, 8);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (9, 'Bob Price', 90, 'Willow Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '134 DAY', now() + INTERVAL '138 DAY', false, 15, 9);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '80 DAY', now() + INTERVAL '87 DAY', false, 11, 9);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '129 DAY', now() + INTERVAL '134 DAY', false, 4, 9);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 4, 'hotel4@hotels1.com', 93, 'Third Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 4, 160.00, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 4, 200.00, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (54, 4, 193.33, 3, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 4, 156.67, 2, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 4, 140.00, 6, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (16, 'Jon Cook', 4, 126, 'Main Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (17, 'Sahil Reed', 4, 145, 'Second Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (18, 'Ivana Williams', 4, 238, 'First Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (19, 'Ryan Price', 4, 357, 'Main Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (20, 'David Miller', 4, 80, 'Main Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (10, 'Liam Ward', 20, 'Bank Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '96 DAY', now() + INTERVAL '103 DAY', false, 17, 10);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '57 DAY', now() + INTERVAL '58 DAY', false, 2, 10);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '15 DAY', now() + INTERVAL '16 DAY', false, 4, 10);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (11, 'Ivana Davis', 229, 'Bay Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '116 DAY', now() + INTERVAL '119 DAY', false, 15, 11);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '149 DAY', now() + INTERVAL '153 DAY', false, 12, 11);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '199 DAY', now() + INTERVAL '202 DAY', false, 16, 11);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (12, 'Andrew Johnson', 154, 'Pine Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '183 DAY', now() + INTERVAL '187 DAY', false, 11, 12);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '80 DAY', now() + INTERVAL '87 DAY', false, 10, 12);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '103 DAY', now() + INTERVAL '104 DAY', false, 13, 12);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 5, 'hotel5@hotels1.com', 65, 'Bank Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (68, 5, 250.00, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 5, 225.00, 5, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 5, 241.67, 3, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 5, 208.33, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (36, 5, 250.00, 2, false, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (21, 'Nick Jones', 5, 127, 'Oak Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (22, 'Susan Brown', 5, 219, 'Metcalfe Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (23, 'Susan Davis', 5, 370, 'Metcalfe Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (24, 'Paul Perez', 5, 197, 'Main Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (25, 'David Wood', 5, 6, 'Third Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (13, 'Ryan Williams', 255, 'Elm Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '53 DAY', now() + INTERVAL '55 DAY', false, 1, 13);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '134 DAY', now() + INTERVAL '138 DAY', false, 7, 13);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '164 DAY', now() + INTERVAL '168 DAY', false, 17, 13);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (14, 'Ashley Jones', 269, 'Elm Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '6 DAY', now() + INTERVAL '11 DAY', false, 13, 14);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '53 DAY', now() + INTERVAL '55 DAY', false, 13, 14);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '62 DAY', now() + INTERVAL '66 DAY', false, 25, 14);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (15, 'Ashley Davis', 371, 'Bank Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '73 DAY', now() + INTERVAL '79 DAY', false, 3, 15);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '128 DAY', now() + INTERVAL '135 DAY', false, 13, 15);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '52 DAY', now() + INTERVAL '54 DAY', false, 21, 15);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 1, 'hotel6@hotels1.com', 135, 'Oak Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (73, 6, 37.50, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 6, 37.50, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 6, 33.33, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 6, 42.50, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (91, 6, 48.33, 5, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (26, 'Bob Miller', 6, 79, 'Second Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (27, 'Alex Cook', 6, 116, 'Laurier Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (28, 'Nick Rogers', 6, 364, 'Main Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (29, 'Emily Rogers', 6, 75, 'Bank Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (30, 'Paul Brown', 6, 141, 'Second Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (16, 'Sahil Hernandez', 56, 'Second Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '15 DAY', now() + INTERVAL '21 DAY', false, 15, 16);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '185 DAY', now() + INTERVAL '186 DAY', false, 14, 16);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '24 DAY', now() + INTERVAL '30 DAY', false, 2, 16);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (17, 'Jon Sanchez', 239, 'Willow Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '191 DAY', now() + INTERVAL '196 DAY', false, 28, 17);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '149 DAY', now() + INTERVAL '152 DAY', false, 16, 17);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '94 DAY', now() + INTERVAL '101 DAY', false, 19, 17);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (18, 'Natalia Davis', 278, 'Elm Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '17 DAY', now() + INTERVAL '22 DAY', false, 12, 18);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '3 DAY', now() + INTERVAL '8 DAY', false, 24, 18);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '18 DAY', now() + INTERVAL '20 DAY', false, 24, 18);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 2, 'hotel7@hotels1.com', 185, 'Laurier Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (78, 7, 95.00, 3, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (5, 7, 80.00, 6, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (30, 7, 81.67, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (27, 7, 78.33, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 7, 95.00, 3, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (31, 'Elizabeth Jones', 7, 273, 'Metcalfe Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (32, 'Alex Sanchez', 7, 244, 'Metcalfe Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (33, 'Ivana Reed', 7, 152, 'Bay Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (34, 'Sarah Williams', 7, 83, 'Main Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (35, 'Andrew Davis', 7, 76, 'Metcalfe Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (19, 'Alex Brown', 47, 'Elm Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '91 DAY', false, 16, 19);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '98 DAY', now() + INTERVAL '100 DAY', false, 29, 19);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '142 DAY', now() + INTERVAL '145 DAY', false, 24, 19);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (20, 'Susan Brown', 215, 'Bay Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '184 DAY', now() + INTERVAL '187 DAY', false, 29, 20);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '56 DAY', now() + INTERVAL '60 DAY', false, 25, 20);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '135 DAY', now() + INTERVAL '138 DAY', false, 34, 20);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (21, 'Natalia Wood', 174, 'First Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '56 DAY', now() + INTERVAL '57 DAY', false, 33, 21);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '153 DAY', now() + INTERVAL '157 DAY', false, 29, 21);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '100 DAY', now() + INTERVAL '107 DAY', false, 32, 21);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 3, 'hotel8@hotels1.com', 111, 'Main Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 8, 115.00, 6, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 8, 105.00, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (47, 8, 135.00, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (17, 8, 117.50, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 8, 100.00, 4, false, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (36, 'Ryan Reed', 8, 218, 'Bay Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (37, 'Liam Hernandez', 8, 339, 'Main Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (38, 'Natalia Davis', 8, 399, 'Second Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (39, 'David Rogers', 8, 146, 'Elm Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (40, 'Elizabeth Young', 8, 72, 'Third Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (22, 'Ashley Williams', 164, 'Bay Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '14 DAY', now() + INTERVAL '16 DAY', false, 31, 22);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '105 DAY', now() + INTERVAL '107 DAY', false, 17, 22);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '60 DAY', now() + INTERVAL '66 DAY', false, 40, 22);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (23, 'Hudi Smith', 398, 'Elm Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '30 DAY', now() + INTERVAL '31 DAY', false, 10, 23);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '67 DAY', now() + INTERVAL '72 DAY', false, 14, 23);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '40 DAY', now() + INTERVAL '41 DAY', false, 29, 23);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (24, 'Ryan Johnson', 277, 'Main Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '155 DAY', now() + INTERVAL '159 DAY', false, 28, 24);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '139 DAY', now() + INTERVAL '144 DAY', false, 34, 24);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '131 DAY', now() + INTERVAL '134 DAY', false, 14, 24);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 2', 'hotel2@hotels.com', 2, 'Laurier Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 1, 'hotel1@hotels2.com', 294, 'Willow Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (99, 9, 45.83, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (26, 9, 45.83, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 9, 40.83, 3, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (65, 9, 50.00, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 9, 33.33, 3, true, false, true, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (41, 'David Davis', 9, 246, 'Oak Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (42, 'Nick Rogers', 9, 192, 'Pine Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (43, 'Nick Jones', 9, 270, 'First Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (44, 'Natalia Jones', 9, 318, 'Metcalfe Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (45, 'Elizabeth Williams', 9, 397, 'Second Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (25, 'Paul Wood', 288, 'First Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '73 DAY', now() + INTERVAL '79 DAY', false, 38, 25);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '110 DAY', now() + INTERVAL '115 DAY', false, 16, 25);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '92 DAY', now() + INTERVAL '96 DAY', false, 9, 25);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (26, 'Andrew Ward', 132, 'Metcalfe Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '177 DAY', now() + INTERVAL '179 DAY', false, 27, 26);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '192 DAY', now() + INTERVAL '197 DAY', false, 42, 26);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '161 DAY', now() + INTERVAL '166 DAY', false, 13, 26);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (27, 'Ashley Brown', 94, 'Main Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '104 DAY', now() + INTERVAL '109 DAY', false, 11, 27);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '87 DAY', now() + INTERVAL '93 DAY', false, 12, 27);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '80 DAY', now() + INTERVAL '86 DAY', false, 30, 27);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 2, 'hotel2@hotels2.com', 217, 'Third Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (91, 10, 85.00, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (51, 10, 66.67, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 10, 66.67, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (97, 10, 76.67, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (85, 10, 70.00, 2, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (46, 'Bob Young', 10, 80, 'Willow Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (47, 'Meg Brown', 10, 215, 'Pine Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (48, 'Hudi Cook', 10, 192, 'Elm Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (49, 'Sarah Davis', 10, 65, 'Pine Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (50, 'Bob Hernandez', 10, 147, 'Laurier Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (28, 'Susan Price', 379, 'Bay Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '92 DAY', false, 1, 28);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '24 DAY', now() + INTERVAL '27 DAY', false, 4, 28);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '159 DAY', now() + INTERVAL '162 DAY', false, 29, 28);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (29, 'Andrew Sanchez', 280, 'First Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '200 DAY', now() + INTERVAL '202 DAY', false, 12, 29);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '16 DAY', now() + INTERVAL '22 DAY', false, 16, 29);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '77 DAY', now() + INTERVAL '82 DAY', false, 6, 29);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (30, 'Elizabeth Ward', 246, 'Second Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '146 DAY', now() + INTERVAL '152 DAY', false, 22, 30);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '106 DAY', now() + INTERVAL '109 DAY', false, 45, 30);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '81 DAY', now() + INTERVAL '88 DAY', false, 21, 30);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 3, 'hotel3@hotels2.com', 156, 'Metcalfe Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 11, 132.50, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 11, 110.00, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 11, 122.50, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 11, 120.00, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (45, 11, 150.00, 2, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (51, 'Jon Rogers', 11, 280, 'Oak Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (52, 'Nick Brown', 11, 50, 'Pine Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (53, 'Ashley Reed', 11, 274, 'Laurier Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (54, 'Ryan Hernandez', 11, 98, 'Third Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (55, 'David Brown', 11, 49, 'Elm Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (31, 'Elizabeth Jones', 110, 'Willow Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '161 DAY', now() + INTERVAL '162 DAY', false, 17, 31);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '79 DAY', now() + INTERVAL '80 DAY', false, 46, 31);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '141 DAY', now() + INTERVAL '146 DAY', false, 40, 31);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (32, 'Hudi Perez', 12, 'Main Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '184 DAY', now() + INTERVAL '191 DAY', false, 53, 32);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '23 DAY', now() + INTERVAL '25 DAY', false, 26, 32);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '189 DAY', now() + INTERVAL '190 DAY', false, 27, 32);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (33, 'Natalia Smith', 250, 'Bank Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '10 DAY', now() + INTERVAL '16 DAY', false, 10, 33);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '114 DAY', now() + INTERVAL '121 DAY', false, 53, 33);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '15 DAY', now() + INTERVAL '20 DAY', false, 42, 33);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 4, 'hotel4@hotels2.com', 56, 'Main Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 12, 173.33, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (74, 12, 180.00, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (44, 12, 183.33, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (100, 12, 140.00, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (4, 12, 153.33, 4, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (56, 'Meg Brown', 12, 76, 'Laurier Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (57, 'Ryan Price', 12, 70, 'First Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (58, 'Liam Price', 12, 265, 'Bay Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (59, 'Alex Cook', 12, 96, 'Willow Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (60, 'Emily Miller', 12, 245, 'Metcalfe Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (34, 'Mary Stewart', 266, 'Laurier Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '105 DAY', now() + INTERVAL '107 DAY', false, 41, 34);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '157 DAY', now() + INTERVAL '161 DAY', false, 48, 34);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '48 DAY', now() + INTERVAL '49 DAY', false, 35, 34);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (35, 'David Wilson', 393, 'Bank Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '44 DAY', now() + INTERVAL '50 DAY', false, 3, 35);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '47 DAY', now() + INTERVAL '52 DAY', false, 2, 35);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '198 DAY', now() + INTERVAL '199 DAY', false, 4, 35);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (36, 'Natalia Price', 261, 'Metcalfe Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '104 DAY', now() + INTERVAL '110 DAY', false, 60, 36);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '11 DAY', now() + INTERVAL '15 DAY', false, 47, 36);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '191 DAY', now() + INTERVAL '197 DAY', false, 47, 36);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 5, 'hotel5@hotels2.com', 279, 'Oak Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (8, 13, 204.17, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 13, 220.83, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (58, 13, 170.83, 5, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 13, 187.50, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 13, 241.67, 2, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (61, 'Sahil Wood', 13, 292, 'Laurier Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (62, 'Ashley Perez', 13, 341, 'Willow Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (63, 'Ryan Sanchez', 13, 261, 'Pine Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (64, 'Paul Cook', 13, 238, 'Main Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (65, 'Ashley Reed', 13, 381, 'Willow Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (37, 'Emily Jones', 329, 'Laurier Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '55 DAY', now() + INTERVAL '62 DAY', false, 26, 37);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '27 DAY', now() + INTERVAL '29 DAY', false, 23, 37);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '91 DAY', now() + INTERVAL '96 DAY', false, 14, 37);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (38, 'Jon Davis', 190, 'First Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '170 DAY', now() + INTERVAL '173 DAY', false, 4, 38);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '137 DAY', now() + INTERVAL '138 DAY', false, 20, 38);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '35 DAY', now() + INTERVAL '39 DAY', false, 6, 38);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (39, 'Ivana Smith', 72, 'Bank Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '176 DAY', now() + INTERVAL '182 DAY', false, 35, 39);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '40 DAY', now() + INTERVAL '42 DAY', false, 46, 39);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '94 DAY', now() + INTERVAL '100 DAY', false, 24, 39);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 1, 'hotel6@hotels2.com', 23, 'Pine Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (35, 14, 35.00, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 14, 33.33, 6, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 14, 37.50, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 14, 47.50, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 14, 39.17, 4, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (66, 'Sarah Price', 14, 311, 'Bay Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (67, 'Alex Wilson', 14, 20, 'Metcalfe Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (68, 'David Perez', 14, 62, 'First Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (69, 'Paul Sanchez', 14, 20, 'Bank Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (70, 'David Brown', 14, 278, 'Bay Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (40, 'David Hernandez', 182, 'Elm Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '107 DAY', now() + INTERVAL '109 DAY', false, 7, 40);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '52 DAY', now() + INTERVAL '54 DAY', false, 60, 40);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '2 DAY', now() + INTERVAL '5 DAY', false, 59, 40);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (41, 'David Jones', 276, 'Bay Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '202 DAY', now() + INTERVAL '203 DAY', false, 50, 41);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '2 DAY', now() + INTERVAL '3 DAY', false, 39, 41);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '205 DAY', now() + INTERVAL '206 DAY', false, 3, 41);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (42, 'Ryan Brown', 69, 'Metcalfe Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '137 DAY', now() + INTERVAL '144 DAY', false, 36, 42);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '168 DAY', now() + INTERVAL '170 DAY', false, 9, 42);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '73 DAY', now() + INTERVAL '79 DAY', false, 60, 42);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 2, 'hotel7@hotels2.com', 124, 'Laurier Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 15, 91.67, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (22, 15, 83.33, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (57, 15, 86.67, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (5, 15, 96.67, 5, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 15, 95.00, 2, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (71, 'Emily Miller', 15, 182, 'First Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (72, 'Ashley Perez', 15, 324, 'Bank Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (73, 'Susan Cook', 15, 331, 'Metcalfe Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (74, 'Jon Jones', 15, 126, 'Second Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (75, 'Ivana Miller', 15, 133, 'Third Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (43, 'Ivana Williams', 56, 'Pine Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '199 DAY', now() + INTERVAL '206 DAY', false, 10, 43);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '94 DAY', now() + INTERVAL '96 DAY', false, 7, 43);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '141 DAY', now() + INTERVAL '147 DAY', false, 12, 43);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (44, 'Hudi Miller', 281, 'Pine Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '122 DAY', now() + INTERVAL '129 DAY', false, 1, 44);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '205 DAY', now() + INTERVAL '211 DAY', false, 5, 44);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '33 DAY', now() + INTERVAL '40 DAY', false, 10, 44);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (45, 'Ryan Price', 359, 'Second Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '191 DAY', now() + INTERVAL '193 DAY', false, 38, 45);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '90 DAY', now() + INTERVAL '97 DAY', false, 44, 45);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '187 DAY', now() + INTERVAL '189 DAY', false, 66, 45);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 3, 'hotel8@hotels2.com', 250, 'Laurier Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 16, 140.00, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 16, 147.50, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 16, 115.00, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 16, 102.50, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 16, 107.50, 5, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (76, 'Emily Davis', 16, 278, 'Second Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (77, 'Sahil Jones', 16, 137, 'Metcalfe Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (78, 'David Smith', 16, 303, 'Bank Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (79, 'Emily Young', 16, 134, 'Third Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (80, 'Ivana Cook', 16, 224, 'Pine Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (46, 'Elizabeth Sanchez', 74, 'Bay Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '161 DAY', now() + INTERVAL '167 DAY', false, 64, 46);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '86 DAY', now() + INTERVAL '92 DAY', false, 46, 46);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '16 DAY', now() + INTERVAL '23 DAY', false, 47, 46);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (47, 'Andrew Miller', 143, 'Oak Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '196 DAY', now() + INTERVAL '201 DAY', false, 38, 47);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '171 DAY', now() + INTERVAL '176 DAY', false, 7, 47);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '121 DAY', now() + INTERVAL '126 DAY', false, 61, 47);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (48, 'Bob Wood', 122, 'Oak Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '178 DAY', now() + INTERVAL '180 DAY', false, 1, 48);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '119 DAY', now() + INTERVAL '125 DAY', false, 46, 48);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '102 DAY', now() + INTERVAL '105 DAY', false, 69, 48);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 3', 'hotel3@hotels.com', 273, 'Willow Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 1, 'hotel1@hotels3.com', 291, 'Main Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (97, 17, 43.33, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 17, 37.50, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 17, 49.17, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (20, 17, 49.17, 6, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (56, 17, 39.17, 2, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (81, 'Alex Cook', 17, 173, 'Bank Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (82, 'Natalia Reed', 17, 31, 'Oak Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (83, 'Sahil Smith', 17, 79, 'Main Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (84, 'Jon Cook', 17, 212, 'Metcalfe Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (85, 'Ryan Stewart', 17, 345, 'Elm Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (49, 'Sarah Smith', 150, 'Third Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '90 DAY', now() + INTERVAL '92 DAY', false, 67, 49);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '202 DAY', now() + INTERVAL '204 DAY', false, 7, 49);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '35 DAY', now() + INTERVAL '37 DAY', false, 57, 49);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (50, 'Meg Young', 201, 'Metcalfe Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '59 DAY', now() + INTERVAL '65 DAY', false, 36, 50);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '108 DAY', now() + INTERVAL '113 DAY', false, 25, 50);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '24 DAY', now() + INTERVAL '28 DAY', false, 85, 50);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (51, 'Emily Price', 105, 'Pine Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '164 DAY', now() + INTERVAL '168 DAY', false, 46, 51);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '68 DAY', now() + INTERVAL '71 DAY', false, 84, 51);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '165 DAY', now() + INTERVAL '167 DAY', false, 5, 51);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 2, 'hotel2@hotels3.com', 202, 'Laurier Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (25, 18, 95.00, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (30, 18, 90.00, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (3, 18, 66.67, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 18, 85.00, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (25, 18, 98.33, 3, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (86, 'Bob Ward', 18, 45, 'Willow Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (87, 'David Price', 18, 57, 'Second Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (88, 'Sarah Hernandez', 18, 34, 'Elm Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (89, 'Ryan Wood', 18, 89, 'First Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (90, 'Sarah Rogers', 18, 400, 'Bay Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (52, 'Mary Miller', 149, 'Bank Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '20 DAY', now() + INTERVAL '26 DAY', false, 7, 52);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '114 DAY', now() + INTERVAL '116 DAY', false, 37, 52);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '96 DAY', now() + INTERVAL '101 DAY', false, 84, 52);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (53, 'Nick Price', 108, 'Metcalfe Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '57 DAY', now() + INTERVAL '63 DAY', false, 43, 53);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '43 DAY', now() + INTERVAL '49 DAY', false, 30, 53);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '192 DAY', now() + INTERVAL '198 DAY', false, 88, 53);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (54, 'Elizabeth Reed', 8, 'Laurier Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '154 DAY', now() + INTERVAL '159 DAY', false, 26, 54);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '139 DAY', now() + INTERVAL '143 DAY', false, 33, 54);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '202 DAY', now() + INTERVAL '207 DAY', false, 60, 54);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 3, 'hotel3@hotels3.com', 243, 'Second Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (31, 19, 112.50, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 19, 117.50, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (31, 19, 110.00, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 19, 132.50, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (14, 19, 127.50, 5, false, true, true, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (91, 'Nick Wilson', 19, 316, 'Laurier Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (92, 'Meg Stewart', 19, 188, 'Elm Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (93, 'Nick Davis', 19, 253, 'Oak Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (94, 'Liam Davis', 19, 372, 'Oak Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (95, 'Sahil Wood', 19, 131, 'Oak Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (55, 'Jon Brown', 153, 'Second Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '13 DAY', now() + INTERVAL '15 DAY', false, 18, 55);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '72 DAY', now() + INTERVAL '76 DAY', false, 57, 55);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '209 DAY', now() + INTERVAL '216 DAY', false, 16, 55);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (56, 'Hudi Wilson', 107, 'Laurier Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '166 DAY', now() + INTERVAL '170 DAY', false, 90, 56);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '201 DAY', now() + INTERVAL '208 DAY', false, 24, 56);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '141 DAY', now() + INTERVAL '145 DAY', false, 26, 56);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (57, 'Elizabeth Jones', 183, 'Pine Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '90 DAY', false, 51, 57);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '31 DAY', now() + INTERVAL '38 DAY', false, 86, 57);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '152 DAY', now() + INTERVAL '154 DAY', false, 46, 57);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 4, 'hotel4@hotels3.com', 265, 'Third Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 20, 153.33, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (68, 20, 200.00, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (85, 20, 170.00, 6, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (28, 20, 156.67, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 20, 150.00, 2, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (96, 'Emily Davis', 20, 352, 'Laurier Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (97, 'Alex Rogers', 20, 204, 'Oak Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (98, 'Nick Stewart', 20, 64, 'Bay Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (99, 'Andrew Stewart', 20, 329, 'Third Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (100, 'Sarah Wilson', 20, 143, 'Third Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (58, 'Liam Jones', 349, 'Oak Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '199 DAY', now() + INTERVAL '202 DAY', false, 54, 58);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '55 DAY', now() + INTERVAL '58 DAY', false, 49, 58);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '69 DAY', now() + INTERVAL '76 DAY', false, 83, 58);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (59, 'Liam Young', 236, 'Metcalfe Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '14 DAY', now() + INTERVAL '15 DAY', false, 3, 59);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '158 DAY', now() + INTERVAL '165 DAY', false, 89, 59);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '12 DAY', now() + INTERVAL '15 DAY', false, 82, 59);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (60, 'Paul Young', 383, 'First Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '173 DAY', now() + INTERVAL '175 DAY', false, 86, 60);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '72 DAY', now() + INTERVAL '74 DAY', false, 58, 60);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '61 DAY', now() + INTERVAL '62 DAY', false, 79, 60);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 5, 'hotel5@hotels3.com', 67, 'Laurier Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (58, 21, 212.50, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (77, 21, 204.17, 6, true, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (85, 21, 204.17, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (80, 21, 216.67, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (54, 21, 183.33, 2, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (101, 'Ivana Jones', 21, 23, 'Second Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (102, 'Ivana Brown', 21, 88, 'Main Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (103, 'Alex Cook', 21, 2, 'Third Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (104, 'Jon Stewart', 21, 116, 'Second Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (105, 'Emily Cook', 21, 132, 'Elm Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (61, 'Mary Hernandez', 338, 'Bay Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '57 DAY', now() + INTERVAL '63 DAY', false, 41, 61);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '190 DAY', now() + INTERVAL '197 DAY', false, 85, 61);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '51 DAY', now() + INTERVAL '58 DAY', false, 29, 61);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (62, 'Alex Cook', 245, 'Metcalfe Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '178 DAY', now() + INTERVAL '181 DAY', false, 84, 62);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '70 DAY', now() + INTERVAL '77 DAY', false, 18, 62);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '61 DAY', now() + INTERVAL '62 DAY', false, 11, 62);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (63, 'Nick Miller', 189, 'Oak Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '111 DAY', now() + INTERVAL '112 DAY', false, 94, 63);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '156 DAY', now() + INTERVAL '160 DAY', false, 4, 63);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '205 DAY', now() + INTERVAL '211 DAY', false, 83, 63);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 1, 'hotel6@hotels3.com', 296, 'Main Street', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (96, 22, 43.33, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 22, 43.33, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (72, 22, 44.17, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 22, 33.33, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (94, 22, 46.67, 4, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (106, 'Emily Stewart', 22, 71, 'First Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (107, 'Mary Brown', 22, 395, 'Willow Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (108, 'Natalia Williams', 22, 200, 'Oak Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (109, 'Jon Sanchez', 22, 129, 'Bank Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (110, 'Susan Johnson', 22, 250, 'First Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (64, 'Andrew Young', 296, 'Oak Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '31 DAY', now() + INTERVAL '38 DAY', false, 50, 64);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '194 DAY', now() + INTERVAL '195 DAY', false, 110, 64);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '121 DAY', now() + INTERVAL '124 DAY', false, 74, 64);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (65, 'Jon Reed', 34, 'Pine Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '146 DAY', now() + INTERVAL '152 DAY', false, 47, 65);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '19 DAY', now() + INTERVAL '21 DAY', false, 3, 65);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '35 DAY', now() + INTERVAL '38 DAY', false, 76, 65);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (66, 'David Brown', 104, 'Metcalfe Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '197 DAY', now() + INTERVAL '202 DAY', false, 36, 66);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '155 DAY', now() + INTERVAL '162 DAY', false, 39, 66);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '183 DAY', now() + INTERVAL '185 DAY', false, 87, 66);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 2, 'hotel7@hotels3.com', 261, 'Pine Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (94, 23, 93.33, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (27, 23, 71.67, 6, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 23, 86.67, 5, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 23, 66.67, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 23, 86.67, 3, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (111, 'Emily Davis', 23, 187, 'Main Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (112, 'Emily Cook', 23, 206, 'Third Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (113, 'Alex Johnson', 23, 313, 'Metcalfe Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (114, 'David Wood', 23, 30, 'Willow Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (115, 'Meg Ward', 23, 359, 'Pine Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (67, 'Natalia Brown', 220, 'First Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '38 DAY', now() + INTERVAL '39 DAY', false, 80, 67);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '74 DAY', now() + INTERVAL '76 DAY', false, 36, 67);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '42 DAY', now() + INTERVAL '47 DAY', false, 110, 67);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (68, 'Susan Ward', 113, 'Oak Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '11 DAY', now() + INTERVAL '17 DAY', false, 26, 68);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '41 DAY', now() + INTERVAL '46 DAY', false, 24, 68);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '102 DAY', now() + INTERVAL '108 DAY', false, 64, 68);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (69, 'Mary Wood', 81, 'Oak Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '116 DAY', now() + INTERVAL '122 DAY', false, 56, 69);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '72 DAY', now() + INTERVAL '77 DAY', false, 69, 69);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '136 DAY', now() + INTERVAL '139 DAY', false, 46, 69);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 3, 'hotel8@hotels3.com', 192, 'Bay Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (14, 24, 115.00, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (76, 24, 135.00, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 24, 105.00, 4, true, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (23, 24, 120.00, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (87, 24, 102.50, 4, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (116, 'David Hernandez', 24, 344, 'Laurier Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (117, 'Jon Young', 24, 257, 'Metcalfe Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (118, 'Jon Wilson', 24, 139, 'Main Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (119, 'David Brown', 24, 196, 'Bank Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (120, 'Meg Reed', 24, 64, 'Bank Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (70, 'Andrew Hernandez', 108, 'Bay Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '150 DAY', now() + INTERVAL '151 DAY', false, 92, 70);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '73 DAY', now() + INTERVAL '78 DAY', false, 48, 70);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '109 DAY', now() + INTERVAL '116 DAY', false, 39, 70);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (71, 'Elizabeth Jones', 368, 'Third Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '131 DAY', now() + INTERVAL '132 DAY', false, 8, 71);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '80 DAY', now() + INTERVAL '84 DAY', false, 15, 71);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '122 DAY', now() + INTERVAL '123 DAY', false, 81, 71);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (72, 'Paul Stewart', 22, 'Third Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '137 DAY', now() + INTERVAL '144 DAY', false, 82, 72);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '14 DAY', now() + INTERVAL '21 DAY', false, 14, 72);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '199 DAY', now() + INTERVAL '202 DAY', false, 88, 72);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 4', 'hotel4@hotels.com', 238, 'Oak Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 1, 'hotel1@hotels4.com', 253, 'Oak Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (45, 25, 35.00, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (47, 25, 38.33, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 25, 47.50, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 25, 45.83, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (12, 25, 38.33, 3, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (121, 'Ivana Sanchez', 25, 325, 'Willow Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (122, 'Paul Wilson', 25, 329, 'Second Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (123, 'David Johnson', 25, 117, 'First Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (124, 'Ashley Stewart', 25, 296, 'First Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (125, 'Emily Reed', 25, 351, 'Laurier Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (73, 'Bob Wood', 358, 'Metcalfe Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '198 DAY', now() + INTERVAL '205 DAY', false, 27, 73);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '76 DAY', now() + INTERVAL '78 DAY', false, 114, 73);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '183 DAY', now() + INTERVAL '190 DAY', false, 113, 73);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (74, 'Nick Cook', 67, 'Bay Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '78 DAY', now() + INTERVAL '85 DAY', false, 71, 74);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '189 DAY', now() + INTERVAL '196 DAY', false, 21, 74);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '99 DAY', now() + INTERVAL '102 DAY', false, 73, 74);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (75, 'Meg Hernandez', 399, 'First Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '143 DAY', now() + INTERVAL '145 DAY', false, 125, 75);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '56 DAY', now() + INTERVAL '58 DAY', false, 87, 75);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '84 DAY', now() + INTERVAL '90 DAY', false, 23, 75);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 2, 'hotel2@hotels4.com', 18, 'Willow Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 26, 93.33, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (91, 26, 85.00, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 26, 70.00, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 26, 80.00, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 26, 100.00, 2, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (126, 'Jon Miller', 26, 103, 'Metcalfe Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (127, 'Sarah Jones', 26, 44, 'Bay Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (128, 'Hudi Brown', 26, 268, 'Elm Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (129, 'Meg Rogers', 26, 283, 'Laurier Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (130, 'Hudi Ward', 26, 239, 'Third Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (76, 'Sarah Sanchez', 48, 'Bank Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 DAY', now() + INTERVAL '7 DAY', false, 31, 76);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '65 DAY', now() + INTERVAL '69 DAY', false, 129, 76);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '102 DAY', now() + INTERVAL '104 DAY', false, 14, 76);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (77, 'Liam Davis', 217, 'Third Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '170 DAY', now() + INTERVAL '176 DAY', false, 106, 77);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '165 DAY', now() + INTERVAL '168 DAY', false, 16, 77);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '3 DAY', now() + INTERVAL '7 DAY', false, 7, 77);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (78, 'Elizabeth Smith', 63, 'Elm Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '121 DAY', now() + INTERVAL '128 DAY', false, 85, 78);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '49 DAY', now() + INTERVAL '53 DAY', false, 87, 78);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '114 DAY', now() + INTERVAL '118 DAY', false, 86, 78);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 3, 'hotel3@hotels4.com', 19, 'Main Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 27, 107.50, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (85, 27, 147.50, 4, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 27, 127.50, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (24, 27, 107.50, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 27, 112.50, 2, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (131, 'Paul Rogers', 27, 194, 'Elm Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (132, 'David Wilson', 27, 238, 'Second Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (133, 'Mary Wood', 27, 150, 'Laurier Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (134, 'Ashley Ward', 27, 329, 'Metcalfe Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (135, 'Jon Perez', 27, 137, 'Pine Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (79, 'Liam Cook', 392, 'Bank Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '18 DAY', now() + INTERVAL '19 DAY', false, 38, 79);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '34 DAY', now() + INTERVAL '41 DAY', false, 11, 79);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '157 DAY', now() + INTERVAL '164 DAY', false, 82, 79);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (80, 'Liam Brown', 349, 'Second Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '131 DAY', now() + INTERVAL '137 DAY', false, 72, 80);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '13 DAY', now() + INTERVAL '15 DAY', false, 135, 80);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '37 DAY', now() + INTERVAL '42 DAY', false, 115, 80);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (81, 'Liam Reed', 89, 'First Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '185 DAY', now() + INTERVAL '188 DAY', false, 73, 81);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '164 DAY', now() + INTERVAL '166 DAY', false, 23, 81);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '55 DAY', now() + INTERVAL '60 DAY', false, 119, 81);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 4, 'hotel4@hotels4.com', 59, 'Oak Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 28, 136.67, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (98, 28, 196.67, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 28, 146.67, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (13, 28, 200.00, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (27, 28, 160.00, 5, true, true, true, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (136, 'Ashley Johnson', 28, 267, 'Second Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (137, 'Ivana Brown', 28, 197, 'Main Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (138, 'Elizabeth Jones', 28, 365, 'Bank Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (139, 'Alex Young', 28, 65, 'Third Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (140, 'Liam Jones', 28, 174, 'Willow Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (82, 'Meg Stewart', 132, 'Willow Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '117 DAY', now() + INTERVAL '121 DAY', false, 22, 82);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '106 DAY', now() + INTERVAL '112 DAY', false, 111, 82);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '72 DAY', now() + INTERVAL '75 DAY', false, 110, 82);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (83, 'Ashley Davis', 286, 'First Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '48 DAY', now() + INTERVAL '55 DAY', false, 92, 83);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '199 DAY', now() + INTERVAL '203 DAY', false, 51, 83);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '189 DAY', now() + INTERVAL '190 DAY', false, 51, 83);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (84, 'Ryan Wood', 345, 'Willow Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '121 DAY', now() + INTERVAL '127 DAY', false, 140, 84);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '108 DAY', now() + INTERVAL '115 DAY', false, 103, 84);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '40 DAY', now() + INTERVAL '41 DAY', false, 88, 84);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 5, 'hotel5@hotels4.com', 41, 'Oak Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 29, 179.17, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (84, 29, 229.17, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 29, 216.67, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (23, 29, 183.33, 3, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (22, 29, 229.17, 5, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (141, 'Natalia Smith', 29, 311, 'Second Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (142, 'Susan Davis', 29, 393, 'Willow Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (143, 'Alex Wilson', 29, 322, 'Willow Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (144, 'Nick Wilson', 29, 94, 'Elm Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (145, 'Jon Davis', 29, 68, 'Main Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (85, 'Jon Ward', 79, 'Elm Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '46 DAY', now() + INTERVAL '48 DAY', false, 60, 85);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '12 DAY', now() + INTERVAL '14 DAY', false, 140, 85);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '15 DAY', now() + INTERVAL '22 DAY', false, 64, 85);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (86, 'Susan Wilson', 226, 'Laurier Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '37 DAY', now() + INTERVAL '43 DAY', false, 73, 86);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '90 DAY', now() + INTERVAL '97 DAY', false, 138, 86);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '7 DAY', now() + INTERVAL '8 DAY', false, 69, 86);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (87, 'Nick Brown', 259, 'Third Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '160 DAY', now() + INTERVAL '162 DAY', false, 76, 87);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '59 DAY', now() + INTERVAL '62 DAY', false, 57, 87);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '17 DAY', now() + INTERVAL '19 DAY', false, 22, 87);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 1, 'hotel6@hotels4.com', 86, 'Laurier Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (57, 30, 46.67, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (24, 30, 44.17, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (91, 30, 35.83, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (30, 30, 37.50, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (56, 30, 35.83, 2, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (146, 'Ryan Smith', 30, 363, 'Pine Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (147, 'Hudi Ward', 30, 106, 'Main Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (148, 'David Reed', 30, 219, 'Laurier Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (149, 'Ashley Miller', 30, 359, 'Willow Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (150, 'Ryan Williams', 30, 204, 'Third Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (88, 'Alex Brown', 6, 'Laurier Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '50 DAY', now() + INTERVAL '57 DAY', false, 130, 88);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '98 DAY', now() + INTERVAL '103 DAY', false, 146, 88);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '110 DAY', now() + INTERVAL '115 DAY', false, 28, 88);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (89, 'Emily Miller', 260, 'Oak Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '60 DAY', now() + INTERVAL '66 DAY', false, 2, 89);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '91 DAY', now() + INTERVAL '94 DAY', false, 95, 89);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '68 DAY', now() + INTERVAL '73 DAY', false, 16, 89);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (90, 'Sarah Johnson', 32, 'Metcalfe Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '2 DAY', now() + INTERVAL '7 DAY', false, 149, 90);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '167 DAY', now() + INTERVAL '168 DAY', false, 85, 90);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '134 DAY', now() + INTERVAL '141 DAY', false, 69, 90);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 2, 'hotel7@hotels4.com', 11, 'First Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 31, 86.67, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 31, 96.67, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (96, 31, 93.33, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (76, 31, 96.67, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 31, 100.00, 2, false, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (151, 'Meg Jones', 31, 37, 'Laurier Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (152, 'Emily Wood', 31, 31, 'Bank Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (153, 'Andrew Miller', 31, 169, 'Laurier Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (154, 'Alex Sanchez', 31, 349, 'Third Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (155, 'Nick Wood', 31, 267, 'Main Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (91, 'Alex Perez', 114, 'Oak Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '26 DAY', now() + INTERVAL '29 DAY', false, 21, 91);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '147 DAY', now() + INTERVAL '148 DAY', false, 48, 91);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '158 DAY', now() + INTERVAL '161 DAY', false, 16, 91);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (92, 'Alex Jones', 106, 'Willow Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '166 DAY', now() + INTERVAL '173 DAY', false, 60, 92);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '75 DAY', now() + INTERVAL '78 DAY', false, 72, 92);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '28 DAY', now() + INTERVAL '35 DAY', false, 54, 92);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (93, 'Hudi Stewart', 153, 'Elm Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '42 DAY', now() + INTERVAL '44 DAY', false, 87, 93);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '59 DAY', now() + INTERVAL '60 DAY', false, 155, 93);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '144 DAY', now() + INTERVAL '146 DAY', false, 155, 93);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 3, 'hotel8@hotels4.com', 40, 'Pine Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (57, 32, 132.50, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (24, 32, 140.00, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 32, 120.00, 5, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (55, 32, 137.50, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (79, 32, 115.00, 5, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (156, 'Ashley Perez', 32, 87, 'Laurier Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (157, 'Ryan Brown', 32, 285, 'Third Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (158, 'Nick Brown', 32, 227, 'Third Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (159, 'Emily Wood', 32, 53, 'Bank Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (160, 'Elizabeth Young', 32, 389, 'Oak Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (94, 'David Rogers', 276, 'Metcalfe Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '123 DAY', now() + INTERVAL '129 DAY', false, 99, 94);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '170 DAY', now() + INTERVAL '177 DAY', false, 11, 94);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '103 DAY', now() + INTERVAL '106 DAY', false, 160, 94);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (95, 'Liam Miller', 111, 'First Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '31 DAY', now() + INTERVAL '36 DAY', false, 150, 95);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '127 DAY', now() + INTERVAL '130 DAY', false, 158, 95);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '100 DAY', now() + INTERVAL '104 DAY', false, 129, 95);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (96, 'Jon Sanchez', 11, 'Second Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '200 DAY', now() + INTERVAL '202 DAY', false, 109, 96);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '119 DAY', now() + INTERVAL '123 DAY', false, 102, 96);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '68 DAY', now() + INTERVAL '70 DAY', false, 68, 96);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 5', 'hotel5@hotels.com', 186, 'Bank Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 1, 'hotel1@hotels5.com', 13, 'Laurier Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 33, 34.17, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (50, 33, 47.50, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (74, 33, 35.83, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (96, 33, 42.50, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (2, 33, 44.17, 4, false, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (161, 'Bob Ward', 33, 187, 'Oak Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (162, 'Andrew Rogers', 33, 96, 'Willow Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (163, 'Paul Davis', 33, 83, 'Willow Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (164, 'Alex Wilson', 33, 127, 'Pine Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (165, 'Andrew Miller', 33, 6, 'First Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (97, 'Sarah Perez', 233, 'Pine Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '79 DAY', now() + INTERVAL '83 DAY', false, 70, 97);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '153 DAY', now() + INTERVAL '155 DAY', false, 137, 97);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '75 DAY', now() + INTERVAL '81 DAY', false, 88, 97);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (98, 'Jon Perez', 247, 'Bank Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '126 DAY', now() + INTERVAL '127 DAY', false, 134, 98);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '147 DAY', now() + INTERVAL '151 DAY', false, 15, 98);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '145 DAY', now() + INTERVAL '147 DAY', false, 42, 98);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (99, 'Emily Hernandez', 151, 'Laurier Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '177 DAY', now() + INTERVAL '178 DAY', false, 126, 99);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '100 DAY', now() + INTERVAL '101 DAY', false, 40, 99);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '204 DAY', now() + INTERVAL '206 DAY', false, 134, 99);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 2, 'hotel2@hotels5.com', 58, 'Second Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (67, 34, 95.00, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (12, 34, 91.67, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 34, 93.33, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (91, 34, 91.67, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (27, 34, 83.33, 6, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (166, 'Ashley Price', 34, 199, 'Metcalfe Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (167, 'Mary Ward', 34, 63, 'Bank Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (168, 'Meg Rogers', 34, 141, 'First Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (169, 'Sahil Brown', 34, 369, 'Main Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (170, 'Emily Hernandez', 34, 214, 'Pine Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (100, 'Natalia Hernandez', 211, 'Oak Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '106 DAY', now() + INTERVAL '113 DAY', false, 83, 100);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '87 DAY', now() + INTERVAL '91 DAY', false, 28, 100);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '198 DAY', now() + INTERVAL '200 DAY', false, 128, 100);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (101, 'Sahil Brown', 135, 'First Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '81 DAY', now() + INTERVAL '86 DAY', false, 105, 101);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '71 DAY', now() + INTERVAL '77 DAY', false, 26, 101);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '112 DAY', now() + INTERVAL '113 DAY', false, 44, 101);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (102, 'David Johnson', 203, 'First Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '20 DAY', now() + INTERVAL '23 DAY', false, 94, 102);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '87 DAY', now() + INTERVAL '93 DAY', false, 108, 102);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '89 DAY', now() + INTERVAL '94 DAY', false, 113, 102);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 3, 'hotel3@hotels5.com', 83, 'Pine Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (7, 35, 132.50, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (61, 35, 130.00, 3, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (67, 35, 105.00, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 35, 115.00, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (97, 35, 150.00, 5, false, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (171, 'Ivana Johnson', 35, 304, 'Bay Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (172, 'Nick Reed', 35, 118, 'Elm Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (173, 'Andrew Reed', 35, 355, 'Metcalfe Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (174, 'Ryan Ward', 35, 51, 'Elm Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (175, 'Emily Johnson', 35, 122, 'First Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (103, 'Bob Rogers', 74, 'Second Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '92 DAY', false, 100, 103);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '73 DAY', now() + INTERVAL '74 DAY', false, 122, 103);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '136 DAY', now() + INTERVAL '139 DAY', false, 74, 103);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (104, 'Jon Brown', 114, 'Main Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '101 DAY', now() + INTERVAL '106 DAY', false, 168, 104);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '195 DAY', now() + INTERVAL '201 DAY', false, 151, 104);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '84 DAY', now() + INTERVAL '89 DAY', false, 163, 104);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (105, 'Andrew Hernandez', 27, 'Metcalfe Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '155 DAY', now() + INTERVAL '156 DAY', false, 164, 105);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '51 DAY', now() + INTERVAL '58 DAY', false, 34, 105);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '97 DAY', now() + INTERVAL '99 DAY', false, 6, 105);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 4, 'hotel4@hotels5.com', 16, 'Metcalfe Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 36, 190.00, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (12, 36, 166.67, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 36, 153.33, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (23, 36, 160.00, 3, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (80, 36, 153.33, 3, true, true, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (176, 'Andrew Wilson', 36, 394, 'Oak Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (177, 'Ivana Williams', 36, 351, 'Willow Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (178, 'Alex Hernandez', 36, 123, 'Main Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (179, 'Nick Smith', 36, 174, 'Main Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (180, 'Ivana Sanchez', 36, 162, 'Third Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (106, 'Alex Price', 238, 'Bank Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '27 DAY', now() + INTERVAL '29 DAY', false, 179, 106);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '191 DAY', now() + INTERVAL '196 DAY', false, 159, 106);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '89 DAY', now() + INTERVAL '90 DAY', false, 114, 106);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (107, 'Mary Wood', 124, 'First Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '84 DAY', now() + INTERVAL '89 DAY', false, 20, 107);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '103 DAY', now() + INTERVAL '106 DAY', false, 166, 107);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '180 DAY', now() + INTERVAL '183 DAY', false, 37, 107);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (108, 'Sahil Wilson', 289, 'First Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '62 DAY', now() + INTERVAL '63 DAY', false, 90, 108);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '35 DAY', now() + INTERVAL '38 DAY', false, 15, 108);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '130 DAY', now() + INTERVAL '133 DAY', false, 97, 108);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 5, 'hotel5@hotels5.com', 29, 'Second Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (58, 37, 187.50, 5, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (78, 37, 191.67, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (27, 37, 212.50, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (22, 37, 245.83, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (80, 37, 187.50, 6, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (181, 'Sahil Brown', 37, 29, 'Metcalfe Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (182, 'Paul Williams', 37, 100, 'Bank Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (183, 'Andrew Brown', 37, 213, 'Pine Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (184, 'Emily Young', 37, 266, 'Willow Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (185, 'Natalia Stewart', 37, 171, 'Bank Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (109, 'Mary Johnson', 150, 'Oak Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '107 DAY', now() + INTERVAL '109 DAY', false, 30, 109);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '40 DAY', now() + INTERVAL '45 DAY', false, 117, 109);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '79 DAY', now() + INTERVAL '80 DAY', false, 80, 109);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (110, 'Emily Perez', 331, 'Laurier Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '41 DAY', now() + INTERVAL '46 DAY', false, 2, 110);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '192 DAY', now() + INTERVAL '198 DAY', false, 153, 110);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '135 DAY', now() + INTERVAL '142 DAY', false, 98, 110);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (111, 'Sahil Davis', 27, 'Third Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '138 DAY', now() + INTERVAL '139 DAY', false, 52, 111);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '141 DAY', now() + INTERVAL '147 DAY', false, 39, 111);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '207 DAY', now() + INTERVAL '214 DAY', false, 52, 111);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 1, 'hotel6@hotels5.com', 63, 'Bank Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 38, 48.33, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (88, 38, 49.17, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 38, 40.83, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (41, 38, 47.50, 5, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (2, 38, 42.50, 3, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (186, 'Mary Smith', 38, 68, 'Third Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (187, 'Meg Hernandez', 38, 278, 'Third Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (188, 'Meg Cook', 38, 197, 'Oak Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (189, 'Elizabeth Price', 38, 379, 'Laurier Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (190, 'Ashley Sanchez', 38, 43, 'First Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (112, 'Emily Miller', 25, 'Bank Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '152 DAY', now() + INTERVAL '159 DAY', false, 63, 112);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '43 DAY', now() + INTERVAL '46 DAY', false, 136, 112);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '90 DAY', false, 144, 112);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (113, 'Sahil Jones', 51, 'Laurier Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '208 DAY', now() + INTERVAL '215 DAY', false, 128, 113);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '57 DAY', now() + INTERVAL '61 DAY', false, 175, 113);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '144 DAY', now() + INTERVAL '151 DAY', false, 163, 113);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (114, 'Ryan Davis', 177, 'Third Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '14 DAY', now() + INTERVAL '19 DAY', false, 36, 114);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '24 DAY', now() + INTERVAL '28 DAY', false, 103, 114);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '134 DAY', now() + INTERVAL '135 DAY', false, 39, 114);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 2, 'hotel7@hotels5.com', 130, 'Laurier Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (28, 39, 70.00, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 39, 73.33, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (56, 39, 86.67, 4, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (27, 39, 73.33, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (61, 39, 96.67, 4, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (191, 'Susan Miller', 39, 26, 'Metcalfe Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (192, 'Bob Ward', 39, 256, 'Bank Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (193, 'Liam Sanchez', 39, 327, 'First Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (194, 'Sarah Sanchez', 39, 361, 'Third Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (195, 'Alex Williams', 39, 340, 'Laurier Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (115, 'Sarah Rogers', 123, 'Pine Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '89 DAY', now() + INTERVAL '96 DAY', false, 190, 115);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '5 DAY', now() + INTERVAL '6 DAY', false, 61, 115);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '173 DAY', now() + INTERVAL '179 DAY', false, 113, 115);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (116, 'Alex Sanchez', 251, 'Elm Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '172 DAY', now() + INTERVAL '175 DAY', false, 80, 116);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '98 DAY', now() + INTERVAL '100 DAY', false, 134, 116);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '3 DAY', now() + INTERVAL '10 DAY', false, 4, 116);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (117, 'Andrew Davis', 161, 'Bay Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '82 DAY', now() + INTERVAL '85 DAY', false, 68, 117);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '136 DAY', now() + INTERVAL '142 DAY', false, 111, 117);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '51 DAY', now() + INTERVAL '55 DAY', false, 171, 117);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 3, 'hotel8@hotels5.com', 193, 'Second Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (87, 40, 140.00, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 40, 127.50, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (94, 40, 107.50, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 40, 112.50, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (91, 40, 140.00, 2, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (196, 'Ashley Young', 40, 132, 'Third Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (197, 'Andrew Smith', 40, 108, 'Pine Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (198, 'Alex Price', 40, 363, 'First Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (199, 'Alex Sanchez', 40, 160, 'Main Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (200, 'Sarah Wood', 40, 296, 'Second Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (118, 'Natalia Stewart', 83, 'Third Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '40 DAY', now() + INTERVAL '41 DAY', false, 17, 118);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '5 DAY', now() + INTERVAL '10 DAY', false, 176, 118);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '164 DAY', now() + INTERVAL '171 DAY', false, 95, 118);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (119, 'Emily Rogers', 183, 'Laurier Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '69 DAY', now() + INTERVAL '71 DAY', false, 1, 119);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '191 DAY', now() + INTERVAL '195 DAY', false, 18, 119);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '69 DAY', now() + INTERVAL '75 DAY', false, 88, 119);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (120, 'Alex Rogers', 347, 'Main Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '27 DAY', now() + INTERVAL '28 DAY', false, 141, 120);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '172 DAY', now() + INTERVAL '175 DAY', false, 92, 120);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '47 DAY', now() + INTERVAL '54 DAY', false, 186, 120);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (2, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (2, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (2, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (2, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (5, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (5, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (5, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (9, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (9, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (9, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (9, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (14, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (14, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (14, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (20, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (20, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (23, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (23, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (23, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (30, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (31, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (31, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (31, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (32, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (32, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (33, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (34, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (35, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (35, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (35, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (37, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (37, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (37, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (40, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (40, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (40, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (42, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (44, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (44, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (44, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (45, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (45, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (46, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (50, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (50, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (51, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (51, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (51, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (51, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (53, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (53, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (59, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (60, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (60, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (60, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (61, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (61, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (61, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (63, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (64, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (66, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (66, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (69, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (69, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (71, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (71, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (71, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (73, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (73, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (74, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (76, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (76, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (80, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (80, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (87, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (87, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (90, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (90, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (91, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (94, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (94, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (94, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (95, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (95, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (95, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (95, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (96, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (96, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (96, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (97, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (101, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (105, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (105, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (106, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (106, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (106, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (108, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (112, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (116, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (116, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (117, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (123, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (123, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (125, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (125, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (128, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (141, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (141, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (145, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (145, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (147, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (147, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (147, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (149, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (149, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (149, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (149, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (150, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (150, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (150, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (150, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (150, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (151, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (151, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (151, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (151, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (152, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (152, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (152, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (152, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (154, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (161, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (161, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (161, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (163, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (163, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (164, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (165, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (165, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (166, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (166, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (169, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (169, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (169, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (175, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (175, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (175, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (178, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (178, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (185, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (186, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (186, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (186, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (186, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (187, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (187, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (192, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (192, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (194, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (194, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (196, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (196, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (197, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (197, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (197, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (199, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (200, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (200, 'Laundry Machine', NULL);
INSERT INTO Role(name, description) VALUES ('Custodian', NULL);
INSERT INTO Role(name, description) VALUES ('Maid', NULL);
INSERT INTO Role(name, description) VALUES ('Bellboy', NULL);
INSERT INTO Role(name, description) VALUES ('Front Desk Person', NULL);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (1, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (2, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (3, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (4, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (5, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (6, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (7, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (8, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (9, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (10, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (11, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (12, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (13, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (14, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (15, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (16, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (17, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (18, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (19, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (20, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (21, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (22, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (23, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (24, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (25, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (26, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (27, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (28, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (29, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (30, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (31, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (32, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (33, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (34, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (35, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (36, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (37, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (38, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (39, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (40, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (41, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (42, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (43, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (44, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (45, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (46, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (47, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (48, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (49, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (50, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (51, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (52, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (53, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (54, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (55, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (56, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (57, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (58, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (59, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (60, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (61, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (62, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (63, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (64, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (65, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (66, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (67, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (68, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (69, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (70, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (71, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (72, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (73, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (74, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (75, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (76, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (77, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (78, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (79, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (80, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (81, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (82, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (83, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (84, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (85, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (86, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (87, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (88, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (89, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (90, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (91, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (92, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (93, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (94, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (95, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (96, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (97, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (98, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (99, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (100, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (101, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (102, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (103, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (104, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (105, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (106, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (107, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (108, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (109, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (110, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (111, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (112, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (113, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (114, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (115, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (116, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (117, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (118, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (119, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (120, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (121, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (122, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (123, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (124, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (125, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (126, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (127, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (128, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (129, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (130, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (131, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (132, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (133, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (134, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (135, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (136, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (137, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (138, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (139, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (140, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (141, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (142, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (143, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (144, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (145, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (146, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (147, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (148, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (149, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (150, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (151, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (152, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (153, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (154, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (155, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (156, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (157, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (158, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (159, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (160, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (161, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (162, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (163, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (164, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (165, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (166, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (167, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (168, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (169, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (170, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (171, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (172, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (173, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (174, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (175, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (176, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (177, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (178, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (179, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (180, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (181, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (182, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (183, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (184, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (185, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (186, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (187, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (188, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (189, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (190, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (191, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (192, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (193, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (194, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (195, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (196, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (197, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (198, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (199, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (200, 1);
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (1, '3274457131');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (2, '9021534149');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (3, '4950434025');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (4, '1576921793');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (5, '8538685600');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (1, '6767865006');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (2, '8077321304');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (3, '6042517753');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (4, '2164166743');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (5, '7896655899');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (6, '2623657590');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (7, '9507454187');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (8, '9082570612');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (9, '2806048270');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (10, '2167688794');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (11, '8325608364');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (12, '8084439080');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (13, '3484740506');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (14, '7960408657');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (15, '5474334013');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (16, '2313111387');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (17, '7284346885');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (18, '1951558622');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (19, '6641032533');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (20, '3682758107');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (21, '2362073091');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (22, '4152709836');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (23, '2155004047');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (24, '5352643682');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (25, '3396992913');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (26, '8897429131');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (27, '5570462521');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (28, '2526447699');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (29, '4624230655');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (30, '9412824246');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (31, '6793609353');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (32, '1911274122');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (33, '4888896846');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (34, '7085873801');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (35, '3954300539');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (36, '8201116328');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (37, '1238281643');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (38, '1877403225');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (39, '2749704368');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (40, '2875646015');
