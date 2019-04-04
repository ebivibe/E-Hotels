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

DROP VIEW IF EXISTS roomarea2;
CREATE VIEW roomarea2 AS
  SELECT r.room_number, r.room_id, hc.chain_name, h.hotel_id, h.street_number, h.street_name, h.unit, h.city, h.province, h.country
  FROM Room r
  INNER JOIN Hotel h on r.hotel_id = h.hotel_id
  INNER JOIN HotelChain hc on h.chain_id = hc.chain_id;


DROP VIEW IF EXISTS roomarea;
CREATE VIEW roomarea AS
  SELECT r.room_id, r.damages, h.city, h.province, h.country
  FROM Room r
  INNER JOIN Hotel h on r.hotel_id = h.hotel_id;

  
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
    hc.chain_id = h.chain_id; INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 1', 'hotel1@hotels.com', 270, 'Laurier Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 1, 'hotel1@hotels1.com', 298, 'Third Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (39, 1, 34.17, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 1, 41.67, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 1, 46.67, 5, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (37, 1, 48.33, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (28, 1, 35.83, 2, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (1, 'Bob Stewart', 1, 152, 'Elm Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (1, 1);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (2, 'Bob Rogers', 1, 41, 'Elm Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (3, 'Mary Young', 1, 56, 'Laurier Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (4, 'David Rogers', 1, 45, 'Elm Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (5, 'Natalia Perez', 1, 242, 'Pine Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (6, 'Susan Reed', 318, 'First Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '62 DAY', now() + INTERVAL '66 DAY', false, 3, 6);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '198 DAY', now() + INTERVAL '203 DAY', false, 3, 6);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '67 DAY', now() + INTERVAL '73 DAY', false, 1, 6);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (7, 'Hudi Jones', 91, 'Pine Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '97 DAY', now() + INTERVAL '103 DAY', false, 4, 7);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '207 DAY', now() + INTERVAL '212 DAY', false, 4, 7);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '198 DAY', now() + INTERVAL '199 DAY', false, 1, 7);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (8, 'Alex Young', 208, 'Bay Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '181 DAY', now() + INTERVAL '188 DAY', false, 4, 8);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '10 DAY', now() + INTERVAL '16 DAY', false, 1, 8);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '179 DAY', now() + INTERVAL '183 DAY', false, 2, 8);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 2, 'hotel2@hotels1.com', 152, 'Bank Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 2, 96.67, 6, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (41, 2, 98.33, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 2, 80.00, 5, false, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (15, 2, 83.33, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 2, 81.67, 3, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (9, 'Nick Wilson', 2, 249, 'Bay Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (9, 2);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (10, 'Meg Price', 2, 396, 'Bay Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (11, 'Hudi Wilson', 2, 313, 'Willow Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (12, 'Liam Johnson', 2, 304, 'Main Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (13, 'Jon Smith', 2, 196, 'First Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (14, 'Mary Perez', 118, 'Elm Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '103 DAY', now() + INTERVAL '104 DAY', false, 9, 14);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '78 DAY', now() + INTERVAL '84 DAY', false, 4, 14);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '154 DAY', now() + INTERVAL '155 DAY', false, 1, 14);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (15, 'Elizabeth Brown', 376, 'Bay Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '43 DAY', now() + INTERVAL '50 DAY', false, 3, 15);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '136 DAY', now() + INTERVAL '140 DAY', false, 3, 15);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '125 DAY', now() + INTERVAL '129 DAY', false, 10, 15);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (16, 'Nick Wilson', 9, 'Bank Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '69 DAY', now() + INTERVAL '74 DAY', false, 8, 16);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '80 DAY', now() + INTERVAL '86 DAY', false, 2, 16);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '163 DAY', now() + INTERVAL '170 DAY', false, 7, 16);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 3, 'hotel3@hotels1.com', 70, 'Elm Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (80, 3, 142.50, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 3, 122.50, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (39, 3, 100.00, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 3, 140.00, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 3, 115.00, 6, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (17, 'Susan Wood', 3, 6, 'Pine Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (17, 3);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (18, 'Susan Davis', 3, 400, 'Willow Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (19, 'Ivana Hernandez', 3, 233, 'Bank Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (20, 'Hudi Wilson', 3, 320, 'First Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (21, 'Paul Perez', 3, 21, 'Pine Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (22, 'Hudi Cook', 191, 'Metcalfe Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '136 DAY', now() + INTERVAL '138 DAY', false, 12, 22);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '20 DAY', now() + INTERVAL '25 DAY', false, 15, 22);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '71 DAY', now() + INTERVAL '78 DAY', false, 6, 22);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (23, 'Sahil Price', 155, 'Laurier Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '163 DAY', now() + INTERVAL '168 DAY', false, 6, 23);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '11 DAY', now() + INTERVAL '17 DAY', false, 11, 23);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '168 DAY', now() + INTERVAL '170 DAY', false, 1, 23);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (24, 'Susan Young', 304, 'Elm Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '187 DAY', now() + INTERVAL '192 DAY', false, 8, 24);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '56 DAY', now() + INTERVAL '58 DAY', false, 9, 24);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '54 DAY', now() + INTERVAL '59 DAY', false, 7, 24);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 4, 'hotel4@hotels1.com', 54, 'Oak Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (88, 4, 156.67, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (79, 4, 196.67, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (73, 4, 170.00, 5, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (98, 4, 150.00, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 4, 140.00, 4, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (25, 'Ryan Young', 4, 266, 'Main Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (25, 4);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (26, 'Paul Ward', 4, 274, 'Willow Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (27, 'Natalia Johnson', 4, 104, 'First Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (28, 'Ivana Williams', 4, 289, 'Bay Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (29, 'Nick Wilson', 4, 391, 'Metcalfe Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (30, 'Sahil Brown', 330, 'First Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '181 DAY', now() + INTERVAL '184 DAY', false, 19, 30);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '11 DAY', now() + INTERVAL '12 DAY', false, 18, 30);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '13 DAY', now() + INTERVAL '15 DAY', false, 3, 30);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (31, 'Sahil Stewart', 131, 'First Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '169 DAY', now() + INTERVAL '171 DAY', false, 4, 31);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '189 DAY', now() + INTERVAL '194 DAY', false, 17, 31);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '66 DAY', now() + INTERVAL '69 DAY', false, 7, 31);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (32, 'Alex Johnson', 397, 'Second Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '142 DAY', now() + INTERVAL '148 DAY', false, 7, 32);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '176 DAY', now() + INTERVAL '182 DAY', false, 15, 32);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '74 DAY', now() + INTERVAL '81 DAY', false, 14, 32);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 5, 'hotel5@hotels1.com', 158, 'Pine Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (76, 5, 245.83, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (97, 5, 191.67, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (41, 5, 166.67, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (77, 5, 216.67, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 5, 187.50, 3, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (33, 'Bob Smith', 5, 239, 'Oak Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (33, 5);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (34, 'David Ward', 5, 393, 'Metcalfe Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (35, 'Nick Sanchez', 5, 153, 'Willow Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (36, 'Liam Wilson', 5, 13, 'Willow Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (37, 'Meg Rogers', 5, 279, 'Elm Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (38, 'Emily Jones', 125, 'Pine Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '175 DAY', now() + INTERVAL '179 DAY', false, 11, 38);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '141 DAY', now() + INTERVAL '148 DAY', false, 23, 38);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '71 DAY', now() + INTERVAL '74 DAY', false, 17, 38);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (39, 'Natalia Williams', 374, 'Willow Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '67 DAY', now() + INTERVAL '73 DAY', false, 10, 39);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '28 DAY', now() + INTERVAL '33 DAY', false, 16, 39);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '127 DAY', now() + INTERVAL '131 DAY', false, 4, 39);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (40, 'Natalia Reed', 147, 'Elm Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '90 DAY', now() + INTERVAL '93 DAY', false, 1, 40);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '30 DAY', now() + INTERVAL '32 DAY', false, 10, 40);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '92 DAY', now() + INTERVAL '94 DAY', false, 4, 40);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 1, 'hotel6@hotels1.com', 261, 'Oak Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (36, 6, 45.00, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (76, 6, 45.00, 3, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (51, 6, 33.33, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (70, 6, 37.50, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (50, 6, 44.17, 3, false, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (41, 'David Jones', 6, 152, 'Bank Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (41, 6);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (42, 'Meg Davis', 6, 167, 'First Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (43, 'Ashley Smith', 6, 128, 'Main Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (44, 'Hudi Davis', 6, 154, 'Bay Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (45, 'Natalia Hernandez', 6, 191, 'Bank Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (46, 'Andrew Rogers', 227, 'Bay Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '62 DAY', now() + INTERVAL '66 DAY', false, 8, 46);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '19 DAY', now() + INTERVAL '23 DAY', false, 30, 46);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '103 DAY', now() + INTERVAL '106 DAY', false, 14, 46);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (47, 'Nick Perez', 353, 'Third Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '165 DAY', now() + INTERVAL '171 DAY', false, 11, 47);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '68 DAY', now() + INTERVAL '73 DAY', false, 24, 47);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '108 DAY', now() + INTERVAL '110 DAY', false, 29, 47);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (48, 'Ivana Davis', 194, 'Pine Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '155 DAY', now() + INTERVAL '160 DAY', false, 15, 48);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '73 DAY', now() + INTERVAL '79 DAY', false, 25, 48);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '135 DAY', now() + INTERVAL '138 DAY', false, 6, 48);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 2, 'hotel7@hotels1.com', 89, 'Third Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 7, 70.00, 4, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 7, 100.00, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (50, 7, 66.67, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 7, 83.33, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 7, 95.00, 5, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (49, 'Emily Hernandez', 7, 258, 'Oak Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (49, 7);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (50, 'Ivana Hernandez', 7, 313, 'Bay Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (51, 'Andrew Johnson', 7, 326, 'Third Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (52, 'David Smith', 7, 197, 'Oak Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (53, 'Natalia Perez', 7, 229, 'Laurier Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (54, 'Susan Davis', 320, 'Third Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '62 DAY', now() + INTERVAL '68 DAY', false, 25, 54);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '169 DAY', now() + INTERVAL '175 DAY', false, 10, 54);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '82 DAY', now() + INTERVAL '84 DAY', false, 19, 54);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (55, 'Susan Sanchez', 333, 'Oak Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '148 DAY', now() + INTERVAL '151 DAY', false, 14, 55);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '45 DAY', now() + INTERVAL '46 DAY', false, 12, 55);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '50 DAY', now() + INTERVAL '55 DAY', false, 25, 55);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (56, 'Hudi Jones', 327, 'Elm Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '135 DAY', now() + INTERVAL '138 DAY', false, 17, 56);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '114 DAY', now() + INTERVAL '116 DAY', false, 34, 56);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '202 DAY', now() + INTERVAL '203 DAY', false, 35, 56);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 3, 'hotel8@hotels1.com', 288, 'Third Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (15, 8, 117.50, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 8, 117.50, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 8, 130.00, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (52, 8, 150.00, 4, true, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 8, 130.00, 5, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (57, 'Ivana Reed', 8, 93, 'Third Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (57, 8);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (58, 'Paul Young', 8, 254, 'Bank Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (59, 'Susan Price', 8, 246, 'Oak Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (60, 'Mary Johnson', 8, 11, 'Pine Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (61, 'Bob Cook', 8, 317, 'Main Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (62, 'Ivana Ward', 300, 'Main Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '199 DAY', now() + INTERVAL '206 DAY', false, 37, 62);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '20 DAY', now() + INTERVAL '21 DAY', false, 38, 62);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '71 DAY', now() + INTERVAL '76 DAY', false, 37, 62);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (63, 'David Jones', 86, 'Oak Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '190 DAY', now() + INTERVAL '194 DAY', false, 20, 63);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '16 DAY', now() + INTERVAL '21 DAY', false, 16, 63);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '6 DAY', now() + INTERVAL '12 DAY', false, 34, 63);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (64, 'Emily Perez', 230, 'Bay Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '157 DAY', now() + INTERVAL '164 DAY', false, 36, 64);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '210 DAY', now() + INTERVAL '211 DAY', false, 6, 64);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '118 DAY', now() + INTERVAL '125 DAY', false, 5, 64);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 2', 'hotel2@hotels.com', 68, 'Third Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 1, 'hotel1@hotels2.com', 124, 'Third Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (65, 9, 42.50, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (25, 9, 35.83, 4, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 9, 35.83, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (76, 9, 38.33, 6, false, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (84, 9, 37.50, 6, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (65, 'Sarah Wilson', 9, 393, 'Bank Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (65, 9);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (66, 'Mary Williams', 9, 241, 'Bank Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (67, 'Ivana Sanchez', 9, 306, 'Second Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (68, 'Sahil Price', 9, 76, 'Third Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (69, 'Liam Hernandez', 9, 92, 'Bank Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (70, 'Alex Wilson', 329, 'First Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '2 DAY', now() + INTERVAL '9 DAY', false, 5, 70);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '127 DAY', now() + INTERVAL '134 DAY', false, 28, 70);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '201 DAY', now() + INTERVAL '204 DAY', false, 18, 70);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (71, 'Elizabeth Rogers', 178, 'Third Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '108 DAY', now() + INTERVAL '113 DAY', false, 17, 71);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '188 DAY', now() + INTERVAL '191 DAY', false, 28, 71);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '174 DAY', now() + INTERVAL '178 DAY', false, 21, 71);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (72, 'Mary Hernandez', 324, 'Second Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '112 DAY', now() + INTERVAL '118 DAY', false, 39, 72);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '18 DAY', now() + INTERVAL '19 DAY', false, 40, 72);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '117 DAY', now() + INTERVAL '124 DAY', false, 33, 72);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 2, 'hotel2@hotels2.com', 13, 'Bay Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 10, 71.67, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (24, 10, 90.00, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (7, 10, 81.67, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 10, 85.00, 6, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (33, 10, 75.00, 4, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (73, 'Paul Stewart', 10, 1, 'Third Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (73, 10);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (74, 'Mary Stewart', 10, 136, 'Laurier Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (75, 'Bob Smith', 10, 218, 'First Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (76, 'Alex Rogers', 10, 391, 'Second Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (77, 'Susan Jones', 10, 160, 'Willow Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (78, 'Sarah Perez', 18, 'Pine Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '172 DAY', now() + INTERVAL '173 DAY', false, 31, 78);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '191 DAY', now() + INTERVAL '196 DAY', false, 25, 78);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '64 DAY', now() + INTERVAL '70 DAY', false, 45, 78);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (79, 'Hudi Johnson', 343, 'First Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '172 DAY', now() + INTERVAL '173 DAY', false, 15, 79);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '83 DAY', now() + INTERVAL '88 DAY', false, 45, 79);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '117 DAY', now() + INTERVAL '122 DAY', false, 37, 79);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (80, 'Mary Brown', 268, 'Metcalfe Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '0 DAY', now() + INTERVAL '5 DAY', false, 50, 80);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '76 DAY', now() + INTERVAL '83 DAY', false, 20, 80);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '177 DAY', now() + INTERVAL '179 DAY', false, 1, 80);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 3, 'hotel3@hotels2.com', 108, 'Bank Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 11, 132.50, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (28, 11, 127.50, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (14, 11, 107.50, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (44, 11, 107.50, 6, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 11, 142.50, 5, true, false, true, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (81, 'Andrew Jones', 11, 207, 'Bank Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (81, 11);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (82, 'Andrew Reed', 11, 75, 'Oak Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (83, 'Andrew Brown', 11, 109, 'Elm Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (84, 'Emily Johnson', 11, 167, 'Oak Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (85, 'Ryan Reed', 11, 198, 'Pine Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (86, 'Hudi Hernandez', 205, 'Bay Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '94 DAY', false, 43, 86);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '138 DAY', now() + INTERVAL '140 DAY', false, 19, 86);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '146 DAY', now() + INTERVAL '150 DAY', false, 24, 86);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (87, 'Nick Johnson', 80, 'Bay Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '198 DAY', now() + INTERVAL '202 DAY', false, 19, 87);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '5 DAY', now() + INTERVAL '8 DAY', false, 16, 87);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '56 DAY', now() + INTERVAL '63 DAY', false, 19, 87);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (88, 'Sarah Johnson', 391, 'Elm Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '205 DAY', now() + INTERVAL '207 DAY', false, 52, 88);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '115 DAY', now() + INTERVAL '119 DAY', false, 22, 88);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '35 DAY', now() + INTERVAL '36 DAY', false, 31, 88);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 4, 'hotel4@hotels2.com', 297, 'Elm Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 12, 170.00, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (94, 12, 143.33, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (12, 12, 146.67, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (58, 12, 190.00, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (96, 12, 200.00, 6, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (89, 'Nick Sanchez', 12, 205, 'Pine Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (89, 12);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (90, 'Paul Hernandez', 12, 237, 'Bank Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (91, 'Liam Cook', 12, 93, 'First Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (92, 'Andrew Miller', 12, 303, 'Third Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (93, 'Ivana Wood', 12, 246, 'Pine Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (94, 'Andrew Wood', 301, 'Main Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '44 DAY', now() + INTERVAL '49 DAY', false, 35, 94);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '14 DAY', now() + INTERVAL '17 DAY', false, 5, 94);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '66 DAY', now() + INTERVAL '72 DAY', false, 31, 94);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (95, 'Natalia Reed', 310, 'Second Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '137 DAY', now() + INTERVAL '140 DAY', false, 15, 95);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '147 DAY', now() + INTERVAL '153 DAY', false, 13, 95);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '46 DAY', now() + INTERVAL '47 DAY', false, 19, 95);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (96, 'Mary Miller', 254, 'Metcalfe Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '200 DAY', now() + INTERVAL '202 DAY', false, 56, 96);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '51 DAY', now() + INTERVAL '52 DAY', false, 5, 96);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '168 DAY', now() + INTERVAL '173 DAY', false, 2, 96);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 5, 'hotel5@hotels2.com', 78, 'Main Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 13, 208.33, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 13, 179.17, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (47, 13, 237.50, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (69, 13, 237.50, 5, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (18, 13, 200.00, 2, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (97, 'Bob Price', 13, 156, 'Third Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (97, 13);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (98, 'Alex Smith', 13, 160, 'Laurier Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (99, 'Alex Miller', 13, 216, 'Pine Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (100, 'Mary Wilson', 13, 109, 'Bay Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (101, 'Elizabeth Smith', 13, 120, 'Elm Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (102, 'Natalia Brown', 316, 'Oak Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '86 DAY', now() + INTERVAL '93 DAY', false, 6, 102);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '29 DAY', now() + INTERVAL '36 DAY', false, 44, 102);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '30 DAY', now() + INTERVAL '37 DAY', false, 30, 102);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (103, 'Sarah Young', 114, 'Elm Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '112 DAY', now() + INTERVAL '114 DAY', false, 7, 103);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '38 DAY', now() + INTERVAL '45 DAY', false, 12, 103);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '10 DAY', now() + INTERVAL '15 DAY', false, 63, 103);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (104, 'Nick Johnson', 15, 'Second Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '65 DAY', now() + INTERVAL '70 DAY', false, 54, 104);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '37 DAY', now() + INTERVAL '39 DAY', false, 25, 104);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '191 DAY', now() + INTERVAL '196 DAY', false, 30, 104);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 1, 'hotel6@hotels2.com', 113, 'Pine Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (61, 14, 34.17, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (47, 14, 38.33, 2, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (3, 14, 37.50, 5, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 14, 50.00, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 14, 40.83, 6, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (105, 'David Johnson', 14, 115, 'Willow Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (105, 14);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (106, 'Ryan Stewart', 14, 304, 'Elm Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (107, 'Jon Wood', 14, 81, 'Elm Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (108, 'Susan Hernandez', 14, 312, 'Oak Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (109, 'Alex Smith', 14, 203, 'Oak Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (110, 'Alex Jones', 184, 'Bank Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '40 DAY', now() + INTERVAL '42 DAY', false, 28, 110);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '66 DAY', now() + INTERVAL '71 DAY', false, 46, 110);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '204 DAY', now() + INTERVAL '208 DAY', false, 38, 110);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (111, 'Hudi Price', 224, 'Willow Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '26 DAY', now() + INTERVAL '31 DAY', false, 19, 111);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '170 DAY', now() + INTERVAL '177 DAY', false, 40, 111);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '204 DAY', now() + INTERVAL '209 DAY', false, 11, 111);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (112, 'Jon Stewart', 29, 'Bank Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '52 DAY', now() + INTERVAL '58 DAY', false, 28, 112);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '130 DAY', now() + INTERVAL '132 DAY', false, 39, 112);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '45 DAY', now() + INTERVAL '48 DAY', false, 43, 112);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 2, 'hotel7@hotels2.com', 270, 'Second Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (30, 15, 71.67, 3, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (8, 15, 75.00, 4, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (57, 15, 70.00, 6, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (5, 15, 81.67, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 15, 66.67, 4, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (113, 'Alex Wood', 15, 295, 'Oak Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (113, 15);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (114, 'Sahil Ward', 15, 67, 'Metcalfe Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (115, 'Ashley Sanchez', 15, 186, 'Bank Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (116, 'Sarah Stewart', 15, 298, 'Second Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (117, 'Meg Miller', 15, 379, 'Laurier Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (118, 'Ivana Rogers', 385, 'Main Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '163 DAY', now() + INTERVAL '165 DAY', false, 64, 118);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '4 DAY', now() + INTERVAL '10 DAY', false, 55, 118);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '29 DAY', now() + INTERVAL '36 DAY', false, 34, 118);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (119, 'Alex Hernandez', 256, 'Pine Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '191 DAY', now() + INTERVAL '196 DAY', false, 23, 119);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '51 DAY', now() + INTERVAL '54 DAY', false, 46, 119);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '78 DAY', now() + INTERVAL '81 DAY', false, 66, 119);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (120, 'Ashley Davis', 74, 'Bank Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '70 DAY', now() + INTERVAL '71 DAY', false, 18, 120);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '172 DAY', now() + INTERVAL '179 DAY', false, 8, 120);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '121 DAY', now() + INTERVAL '122 DAY', false, 26, 120);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 3, 'hotel8@hotels2.com', 16, 'Second Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (54, 16, 132.50, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 16, 100.00, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (39, 16, 105.00, 6, true, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 16, 140.00, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (100, 16, 110.00, 5, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (121, 'Mary Perez', 16, 340, 'Pine Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (121, 16);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (122, 'Hudi Rogers', 16, 277, 'Main Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (123, 'Ryan Perez', 16, 144, 'Elm Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (124, 'Nick Brown', 16, 375, 'Third Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (125, 'Ryan Johnson', 16, 72, 'Main Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (126, 'Andrew Hernandez', 141, 'Bank Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '18 DAY', now() + INTERVAL '22 DAY', false, 13, 126);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '46 DAY', now() + INTERVAL '51 DAY', false, 65, 126);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '173 DAY', now() + INTERVAL '175 DAY', false, 37, 126);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (127, 'David Ward', 307, 'Oak Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '208 DAY', now() + INTERVAL '213 DAY', false, 21, 127);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 DAY', now() + INTERVAL '8 DAY', false, 39, 127);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '52 DAY', now() + INTERVAL '53 DAY', false, 4, 127);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (128, 'Susan Brown', 205, 'Willow Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '30 DAY', now() + INTERVAL '31 DAY', false, 15, 128);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '129 DAY', now() + INTERVAL '132 DAY', false, 15, 128);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '188 DAY', now() + INTERVAL '195 DAY', false, 50, 128);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 3', 'hotel3@hotels.com', 54, 'Oak Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 1, 'hotel1@hotels3.com', 228, 'Willow Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 17, 45.00, 4, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (90, 17, 35.83, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (96, 17, 38.33, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 17, 47.50, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (100, 17, 48.33, 3, true, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (129, 'Sarah Ward', 17, 194, 'Pine Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (129, 17);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (130, 'Elizabeth Brown', 17, 127, 'Third Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (131, 'Natalia Smith', 17, 304, 'Second Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (132, 'Liam Smith', 17, 184, 'Oak Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (133, 'Emily Stewart', 17, 248, 'Third Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (134, 'Liam Cook', 166, 'Second Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '8 DAY', now() + INTERVAL '9 DAY', false, 32, 134);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '64 DAY', now() + INTERVAL '71 DAY', false, 38, 134);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '169 DAY', now() + INTERVAL '174 DAY', false, 29, 134);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (135, 'Sahil Smith', 398, 'Willow Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '23 DAY', now() + INTERVAL '28 DAY', false, 8, 135);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '123 DAY', now() + INTERVAL '124 DAY', false, 75, 135);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '106 DAY', now() + INTERVAL '112 DAY', false, 2, 135);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (136, 'Natalia Rogers', 372, 'Second Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '168 DAY', now() + INTERVAL '169 DAY', false, 48, 136);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '159 DAY', now() + INTERVAL '164 DAY', false, 28, 136);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '30 DAY', now() + INTERVAL '36 DAY', false, 17, 136);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 2, 'hotel2@hotels3.com', 54, 'Oak Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (30, 18, 85.00, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 18, 71.67, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 18, 100.00, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (38, 18, 80.00, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (39, 18, 90.00, 4, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (137, 'Jon Young', 18, 225, 'Oak Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (137, 18);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (138, 'Ryan Smith', 18, 175, 'Pine Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (139, 'Elizabeth Hernandez', 18, 137, 'Third Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (140, 'Bob Jones', 18, 11, 'Oak Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (141, 'Nick Stewart', 18, 191, 'Willow Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (142, 'Alex Reed', 22, 'Laurier Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '143 DAY', now() + INTERVAL '146 DAY', false, 18, 142);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '171 DAY', now() + INTERVAL '175 DAY', false, 20, 142);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '196 DAY', now() + INTERVAL '199 DAY', false, 79, 142);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (143, 'Nick Young', 327, 'Bay Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '54 DAY', now() + INTERVAL '56 DAY', false, 6, 143);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '72 DAY', now() + INTERVAL '76 DAY', false, 71, 143);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '21 DAY', now() + INTERVAL '25 DAY', false, 86, 143);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (144, 'Mary Hernandez', 21, 'Bay Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '178 DAY', now() + INTERVAL '183 DAY', false, 34, 144);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '80 DAY', now() + INTERVAL '84 DAY', false, 13, 144);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '123 DAY', now() + INTERVAL '124 DAY', false, 15, 144);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 3, 'hotel3@hotels3.com', 212, 'Third Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 19, 107.50, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (69, 19, 122.50, 5, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 19, 120.00, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 19, 130.00, 3, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 19, 122.50, 2, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (145, 'Natalia Price', 19, 138, 'Oak Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (145, 19);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (146, 'Ryan Jones', 19, 294, 'Pine Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (147, 'Jon Johnson', 19, 319, 'Willow Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (148, 'Nick Jones', 19, 225, 'Metcalfe Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (149, 'Emily Smith', 19, 36, 'Laurier Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (150, 'Ivana Williams', 98, 'Bank Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '192 DAY', now() + INTERVAL '193 DAY', false, 64, 150);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '86 DAY', now() + INTERVAL '92 DAY', false, 87, 150);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '64 DAY', now() + INTERVAL '66 DAY', false, 56, 150);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (151, 'Ivana Jones', 277, 'First Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '37 DAY', now() + INTERVAL '43 DAY', false, 31, 151);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '33 DAY', now() + INTERVAL '34 DAY', false, 36, 151);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '9 DAY', now() + INTERVAL '13 DAY', false, 12, 151);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (152, 'Susan Stewart', 202, 'Bay Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '60 DAY', now() + INTERVAL '63 DAY', false, 73, 152);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '22 DAY', now() + INTERVAL '26 DAY', false, 60, 152);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '36 DAY', now() + INTERVAL '38 DAY', false, 74, 152);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 4, 'hotel4@hotels3.com', 127, 'Willow Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 20, 166.67, 6, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (97, 20, 190.00, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (31, 20, 136.67, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (12, 20, 140.00, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (96, 20, 133.33, 6, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (153, 'Natalia Davis', 20, 49, 'Willow Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (153, 20);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (154, 'Nick Wilson', 20, 225, 'Metcalfe Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (155, 'Liam Johnson', 20, 105, 'Third Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (156, 'Ivana Young', 20, 204, 'Metcalfe Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (157, 'Alex Jones', 20, 41, 'Metcalfe Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (158, 'Hudi Young', 324, 'Willow Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '36 DAY', now() + INTERVAL '38 DAY', false, 17, 158);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '176 DAY', now() + INTERVAL '178 DAY', false, 4, 158);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '180 DAY', now() + INTERVAL '186 DAY', false, 90, 158);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (159, 'Natalia Rogers', 261, 'Oak Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '82 DAY', now() + INTERVAL '87 DAY', false, 61, 159);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '63 DAY', now() + INTERVAL '64 DAY', false, 87, 159);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '194 DAY', now() + INTERVAL '198 DAY', false, 18, 159);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (160, 'Nick Hernandez', 56, 'Laurier Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '54 DAY', now() + INTERVAL '57 DAY', false, 12, 160);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '172 DAY', now() + INTERVAL '179 DAY', false, 5, 160);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '36 DAY', now() + INTERVAL '40 DAY', false, 40, 160);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 5, 'hotel5@hotels3.com', 150, 'Laurier Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 21, 241.67, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (61, 21, 241.67, 2, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 21, 195.83, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 21, 212.50, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (58, 21, 212.50, 2, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (161, 'Alex Ward', 21, 139, 'Laurier Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (161, 21);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (162, 'Ryan Wilson', 21, 148, 'Willow Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (163, 'Mary Smith', 21, 5, 'First Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (164, 'Sarah Jones', 21, 199, 'First Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (165, 'Ashley Price', 21, 345, 'Second Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (166, 'David Hernandez', 81, 'Oak Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '92 DAY', now() + INTERVAL '97 DAY', false, 10, 166);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '129 DAY', now() + INTERVAL '135 DAY', false, 90, 166);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '188 DAY', now() + INTERVAL '193 DAY', false, 27, 166);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (167, 'Nick Ward', 205, 'Oak Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '92 DAY', now() + INTERVAL '93 DAY', false, 37, 167);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '68 DAY', now() + INTERVAL '70 DAY', false, 77, 167);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '170 DAY', now() + INTERVAL '171 DAY', false, 88, 167);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (168, 'Sarah Miller', 124, 'Oak Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '21 DAY', now() + INTERVAL '23 DAY', false, 45, 168);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '11 DAY', now() + INTERVAL '15 DAY', false, 4, 168);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '187 DAY', now() + INTERVAL '188 DAY', false, 46, 168);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 1, 'hotel6@hotels3.com', 34, 'Third Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 22, 47.50, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (44, 22, 49.17, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 22, 45.00, 4, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 22, 42.50, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (47, 22, 44.17, 4, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (169, 'Sahil Williams', 22, 246, 'Elm Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (169, 22);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (170, 'Ashley Reed', 22, 323, 'Laurier Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (171, 'Sahil Reed', 22, 40, 'Main Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (172, 'Nick Cook', 22, 239, 'Pine Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (173, 'Sahil Cook', 22, 252, 'Willow Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (174, 'Ryan Wood', 220, 'Bank Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '105 DAY', now() + INTERVAL '107 DAY', false, 15, 174);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '92 DAY', now() + INTERVAL '98 DAY', false, 36, 174);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '126 DAY', now() + INTERVAL '132 DAY', false, 57, 174);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (175, 'Ivana Ward', 317, 'Metcalfe Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '7 DAY', now() + INTERVAL '12 DAY', false, 65, 175);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '6 DAY', now() + INTERVAL '9 DAY', false, 86, 175);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '68 DAY', now() + INTERVAL '72 DAY', false, 51, 175);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (176, 'Paul Ward', 351, 'Elm Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '83 DAY', now() + INTERVAL '85 DAY', false, 56, 176);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '207 DAY', now() + INTERVAL '214 DAY', false, 35, 176);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '197 DAY', now() + INTERVAL '201 DAY', false, 80, 176);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 2, 'hotel7@hotels3.com', 67, 'Elm Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 23, 96.67, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (4, 23, 93.33, 6, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 23, 86.67, 5, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (17, 23, 73.33, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (35, 23, 86.67, 4, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (177, 'Alex Sanchez', 23, 313, 'Pine Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (177, 23);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (178, 'Liam Reed', 23, 109, 'Willow Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (179, 'Susan Davis', 23, 361, 'First Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (180, 'Meg Brown', 23, 304, 'First Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (181, 'Andrew Brown', 23, 308, 'Elm Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (182, 'Liam Miller', 284, 'Elm Crescent', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '3 DAY', now() + INTERVAL '6 DAY', false, 22, 182);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '202 DAY', now() + INTERVAL '208 DAY', false, 16, 182);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '170 DAY', now() + INTERVAL '177 DAY', false, 89, 182);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (183, 'David Stewart', 120, 'Pine Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '49 DAY', now() + INTERVAL '53 DAY', false, 20, 183);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '180 DAY', now() + INTERVAL '183 DAY', false, 21, 183);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '183 DAY', now() + INTERVAL '188 DAY', false, 76, 183);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (184, 'Susan Johnson', 360, 'Willow Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '192 DAY', now() + INTERVAL '198 DAY', false, 9, 184);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '4 DAY', now() + INTERVAL '11 DAY', false, 102, 184);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '51 DAY', now() + INTERVAL '55 DAY', false, 57, 184);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 3, 'hotel8@hotels3.com', 184, 'Bank Way', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (68, 24, 102.50, 6, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 24, 102.50, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (85, 24, 120.00, 4, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 24, 130.00, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 24, 140.00, 3, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (185, 'Mary Davis', 24, 154, 'First Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (185, 24);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (186, 'Natalia Johnson', 24, 387, 'Second Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (187, 'Liam Smith', 24, 354, 'Oak Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (188, 'Andrew Williams', 24, 193, 'Bank Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (189, 'Meg Brown', 24, 123, 'Metcalfe Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (190, 'Paul Wilson', 268, 'Third Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '89 DAY', now() + INTERVAL '96 DAY', false, 48, 190);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '69 DAY', now() + INTERVAL '70 DAY', false, 73, 190);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '9 DAY', now() + INTERVAL '13 DAY', false, 103, 190);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (191, 'Nick Hernandez', 70, 'Willow Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '155 DAY', now() + INTERVAL '158 DAY', false, 101, 191);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '71 DAY', now() + INTERVAL '75 DAY', false, 85, 191);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '16 DAY', now() + INTERVAL '21 DAY', false, 107, 191);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (192, 'Sahil Smith', 166, 'First Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '93 DAY', now() + INTERVAL '98 DAY', false, 29, 192);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '183 DAY', now() + INTERVAL '187 DAY', false, 69, 192);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '64 DAY', now() + INTERVAL '69 DAY', false, 71, 192);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 4', 'hotel4@hotels.com', 271, 'Pine Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 1, 'hotel1@hotels4.com', 47, 'Laurier Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (35, 25, 35.83, 2, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 25, 49.17, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (5, 25, 39.17, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (30, 25, 40.83, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 25, 48.33, 3, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (193, 'David Sanchez', 25, 60, 'Main Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (193, 25);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (194, 'Paul Price', 25, 3, 'Bank Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (195, 'Liam Williams', 25, 169, 'Willow Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (196, 'Jon Davis', 25, 310, 'Elm Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (197, 'Mary Jones', 25, 40, 'Oak Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (198, 'Jon Brown', 236, 'Willow Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '194 DAY', now() + INTERVAL '197 DAY', false, 103, 198);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '147 DAY', now() + INTERVAL '148 DAY', false, 115, 198);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '202 DAY', now() + INTERVAL '203 DAY', false, 56, 198);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (199, 'Jon Wood', 291, 'Second Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '116 DAY', now() + INTERVAL '120 DAY', false, 77, 199);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '152 DAY', now() + INTERVAL '156 DAY', false, 19, 199);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '148 DAY', now() + INTERVAL '154 DAY', false, 118, 199);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (200, 'Ivana Stewart', 113, 'Oak Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '131 DAY', now() + INTERVAL '134 DAY', false, 31, 200);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '68 DAY', now() + INTERVAL '70 DAY', false, 95, 200);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '209 DAY', now() + INTERVAL '215 DAY', false, 118, 200);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 2, 'hotel2@hotels4.com', 146, 'Oak Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (53, 26, 88.33, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (25, 26, 78.33, 5, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (25, 26, 78.33, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (37, 26, 90.00, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 26, 86.67, 6, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (201, 'Paul Rogers', 26, 200, 'Bay Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (201, 26);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (202, 'Alex Reed', 26, 18, 'Laurier Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (203, 'Paul Hernandez', 26, 176, 'First Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (204, 'Susan Ward', 26, 5, 'Elm Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (205, 'Sarah Young', 26, 375, 'Oak Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (206, 'Natalia Ward', 181, 'Bank Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '95 DAY', now() + INTERVAL '100 DAY', false, 13, 206);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '75 DAY', now() + INTERVAL '76 DAY', false, 45, 206);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '24 DAY', now() + INTERVAL '25 DAY', false, 125, 206);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (207, 'Emily Johnson', 108, 'Bay Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '129 DAY', now() + INTERVAL '133 DAY', false, 1, 207);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '207 DAY', now() + INTERVAL '208 DAY', false, 112, 207);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '186 DAY', now() + INTERVAL '187 DAY', false, 90, 207);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (208, 'Ivana Rogers', 383, 'Bay Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '105 DAY', now() + INTERVAL '110 DAY', false, 7, 208);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '78 DAY', now() + INTERVAL '81 DAY', false, 80, 208);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '47 DAY', now() + INTERVAL '54 DAY', false, 6, 208);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 3, 'hotel3@hotels4.com', 273, 'Second Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (5, 27, 100.00, 5, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (99, 27, 150.00, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (24, 27, 122.50, 6, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (52, 27, 150.00, 4, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (74, 27, 122.50, 5, false, true, true, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (209, 'Liam Brown', 27, 373, 'Elm Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (209, 27);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (210, 'Sarah Johnson', 27, 272, 'Willow Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (211, 'Natalia Rogers', 27, 61, 'Third Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (212, 'Sahil Miller', 27, 95, 'Second Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (213, 'Ivana Jones', 27, 41, 'Metcalfe Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (214, 'Ashley Young', 222, 'Elm Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '7 DAY', now() + INTERVAL '11 DAY', false, 109, 214);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '101 DAY', now() + INTERVAL '107 DAY', false, 126, 214);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '151 DAY', now() + INTERVAL '156 DAY', false, 23, 214);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (215, 'Ashley Price', 363, 'Third Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '126 DAY', now() + INTERVAL '128 DAY', false, 25, 215);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '24 DAY', now() + INTERVAL '26 DAY', false, 58, 215);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '95 DAY', now() + INTERVAL '102 DAY', false, 129, 215);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (216, 'Ivana Jones', 80, 'Willow Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '20 DAY', now() + INTERVAL '21 DAY', false, 52, 216);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '101 DAY', now() + INTERVAL '105 DAY', false, 7, 216);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '115 DAY', now() + INTERVAL '118 DAY', false, 62, 216);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 4, 'hotel4@hotels4.com', 115, 'First Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (90, 28, 133.33, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (94, 28, 196.67, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 28, 186.67, 4, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (31, 28, 176.67, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 28, 183.33, 5, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (217, 'Emily Cook', 28, 335, 'Laurier Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (217, 28);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (218, 'Susan Jones', 28, 209, 'Bay Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (219, 'Paul Davis', 28, 321, 'Bank Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (220, 'Sarah Rogers', 28, 348, 'Laurier Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (221, 'Meg Sanchez', 28, 149, 'Pine Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (222, 'Sarah Hernandez', 32, 'Metcalfe Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '105 DAY', now() + INTERVAL '107 DAY', false, 88, 222);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '204 DAY', now() + INTERVAL '206 DAY', false, 63, 222);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '72 DAY', now() + INTERVAL '79 DAY', false, 19, 222);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (223, 'Sarah Reed', 28, 'Willow Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '129 DAY', now() + INTERVAL '131 DAY', false, 71, 223);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '18 DAY', now() + INTERVAL '20 DAY', false, 1, 223);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '122 DAY', now() + INTERVAL '128 DAY', false, 2, 223);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (224, 'Alex Johnson', 82, 'Third Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '15 DAY', now() + INTERVAL '21 DAY', false, 24, 224);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '174 DAY', now() + INTERVAL '180 DAY', false, 43, 224);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '190 DAY', now() + INTERVAL '192 DAY', false, 46, 224);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 5, 'hotel5@hotels4.com', 131, 'Willow Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (36, 29, 187.50, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (87, 29, 245.83, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (5, 29, 250.00, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 29, 170.83, 2, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 29, 179.17, 2, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (225, 'Ivana Stewart', 29, 38, 'Oak Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (225, 29);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (226, 'Ryan Brown', 29, 337, 'Second Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (227, 'Alex Davis', 29, 138, 'Bay Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (228, 'Ivana Cook', 29, 366, 'Willow Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (229, 'Natalia Price', 29, 45, 'Oak Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (230, 'Ashley Cook', 1, 'Elm Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '72 DAY', now() + INTERVAL '78 DAY', false, 75, 230);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '188 DAY', now() + INTERVAL '191 DAY', false, 139, 230);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '134 DAY', now() + INTERVAL '141 DAY', false, 142, 230);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (231, 'Susan Brown', 151, 'Third Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '172 DAY', now() + INTERVAL '179 DAY', false, 30, 231);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '109 DAY', now() + INTERVAL '113 DAY', false, 36, 231);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '158 DAY', now() + INTERVAL '164 DAY', false, 9, 231);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (232, 'Liam Rogers', 338, 'Oak Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '33 DAY', now() + INTERVAL '35 DAY', false, 139, 232);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '4 DAY', now() + INTERVAL '5 DAY', false, 87, 232);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '109 DAY', now() + INTERVAL '115 DAY', false, 135, 232);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 1, 'hotel6@hotels4.com', 231, 'Laurier Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (39, 30, 44.17, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (7, 30, 43.33, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (74, 30, 35.83, 2, false, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 30, 40.83, 3, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (85, 30, 33.33, 4, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (233, 'Hudi Cook', 30, 193, 'Third Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (233, 30);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (234, 'Andrew Stewart', 30, 232, 'Metcalfe Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (235, 'Susan Hernandez', 30, 178, 'Pine Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (236, 'Mary Stewart', 30, 322, 'Second Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (237, 'Alex Young', 30, 148, 'Main Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (238, 'Paul Miller', 32, 'Elm Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '49 DAY', now() + INTERVAL '53 DAY', false, 90, 238);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '153 DAY', now() + INTERVAL '160 DAY', false, 7, 238);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '135 DAY', now() + INTERVAL '137 DAY', false, 25, 238);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (239, 'Emily Rogers', 279, 'Second Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '16 DAY', now() + INTERVAL '17 DAY', false, 51, 239);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '124 DAY', now() + INTERVAL '129 DAY', false, 134, 239);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '130 DAY', now() + INTERVAL '136 DAY', false, 69, 239);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (240, 'Meg Rogers', 40, 'Second Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '163 DAY', now() + INTERVAL '168 DAY', false, 2, 240);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '38 DAY', now() + INTERVAL '41 DAY', false, 134, 240);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '89 DAY', now() + INTERVAL '90 DAY', false, 74, 240);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 2, 'hotel7@hotels4.com', 245, 'Second Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (36, 31, 83.33, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (18, 31, 95.00, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (40, 31, 66.67, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (30, 31, 95.00, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (96, 31, 70.00, 6, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (241, 'Ryan Hernandez', 31, 296, 'Second Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (241, 31);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (242, 'Nick Rogers', 31, 298, 'Laurier Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (243, 'Jon Johnson', 31, 335, 'Bay Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (244, 'Jon Miller', 31, 4, 'Bay Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (245, 'Hudi Miller', 31, 43, 'Pine Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (246, 'Jon Brown', 272, 'Bank Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '154 DAY', now() + INTERVAL '159 DAY', false, 95, 246);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '199 DAY', now() + INTERVAL '201 DAY', false, 57, 246);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '147 DAY', now() + INTERVAL '148 DAY', false, 74, 246);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (247, 'Paul Brown', 150, 'Third Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '151 DAY', now() + INTERVAL '157 DAY', false, 138, 247);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '61 DAY', now() + INTERVAL '64 DAY', false, 117, 247);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '33 DAY', now() + INTERVAL '36 DAY', false, 14, 247);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (248, 'Mary Reed', 210, 'Bay Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '65 DAY', now() + INTERVAL '68 DAY', false, 125, 248);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '148 DAY', now() + INTERVAL '151 DAY', false, 20, 248);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '28 DAY', now() + INTERVAL '34 DAY', false, 57, 248);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 3, 'hotel8@hotels4.com', 271, 'Bank Street', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (73, 32, 137.50, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (54, 32, 147.50, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 32, 130.00, 5, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 32, 137.50, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 32, 122.50, 3, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (249, 'David Miller', 32, 46, 'Bank Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (249, 32);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (250, 'Ryan Ward', 32, 3, 'Willow Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (251, 'Andrew Smith', 32, 253, 'Second Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (252, 'Andrew Stewart', 32, 347, 'Oak Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (253, 'Andrew Young', 32, 331, 'Willow Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (254, 'Alex Jones', 109, 'Oak Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '4 DAY', now() + INTERVAL '9 DAY', false, 84, 254);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '90 DAY', now() + INTERVAL '96 DAY', false, 151, 254);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '46 DAY', now() + INTERVAL '52 DAY', false, 42, 254);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (255, 'Jon Young', 237, 'Third Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '11 DAY', now() + INTERVAL '17 DAY', false, 43, 255);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '193 DAY', now() + INTERVAL '200 DAY', false, 145, 255);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '200 DAY', now() + INTERVAL '207 DAY', false, 81, 255);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (256, 'Jon Wood', 100, 'Main Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '41 DAY', now() + INTERVAL '48 DAY', false, 45, 256);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '140 DAY', now() + INTERVAL '141 DAY', false, 97, 256);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '82 DAY', now() + INTERVAL '83 DAY', false, 112, 256);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 5', 'hotel5@hotels.com', 10, 'Oak Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 1, 'hotel1@hotels5.com', 100, 'Pine Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 33, 49.17, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (4, 33, 46.67, 2, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (72, 33, 47.50, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 33, 35.83, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (56, 33, 40.00, 5, false, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (257, 'Natalia Cook', 33, 287, 'Bay Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (257, 33);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (258, 'Nick Williams', 33, 178, 'Metcalfe Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (259, 'Mary Hernandez', 33, 48, 'Main Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (260, 'Alex Price', 33, 291, 'First Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (261, 'Ryan Williams', 33, 182, 'Bank Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (262, 'Emily Johnson', 224, 'First Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '100 DAY', now() + INTERVAL '103 DAY', false, 123, 262);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '76 DAY', now() + INTERVAL '78 DAY', false, 41, 262);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '0 DAY', now() + INTERVAL '3 DAY', false, 163, 262);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (263, 'Susan Miller', 351, 'Third Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '132 DAY', now() + INTERVAL '134 DAY', false, 149, 263);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '110 DAY', now() + INTERVAL '117 DAY', false, 73, 263);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '192 DAY', now() + INTERVAL '193 DAY', false, 91, 263);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (264, 'David Wilson', 28, 'First Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '172 DAY', now() + INTERVAL '178 DAY', false, 107, 264);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '60 DAY', now() + INTERVAL '65 DAY', false, 102, 264);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '146 DAY', now() + INTERVAL '148 DAY', false, 66, 264);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 2, 'hotel2@hotels5.com', 215, 'Oak Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (58, 34, 86.67, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 34, 88.33, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 34, 83.33, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 34, 83.33, 5, true, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (20, 34, 71.67, 6, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (265, 'Jon Davis', 34, 329, 'Oak Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (265, 34);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (266, 'Sarah Perez', 34, 242, 'Bay Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (267, 'Andrew Stewart', 34, 386, 'Bay Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (268, 'David Jones', 34, 211, 'Bay Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (269, 'Meg Young', 34, 150, 'Main Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (270, 'Hudi Stewart', 87, 'Bay Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '150 DAY', now() + INTERVAL '153 DAY', false, 91, 270);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '206 DAY', now() + INTERVAL '213 DAY', false, 152, 270);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '68 DAY', now() + INTERVAL '71 DAY', false, 26, 270);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (271, 'Mary Sanchez', 129, 'Bank Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '189 DAY', now() + INTERVAL '191 DAY', false, 142, 271);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '210 DAY', now() + INTERVAL '213 DAY', false, 85, 271);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '147 DAY', now() + INTERVAL '149 DAY', false, 167, 271);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (272, 'Sarah Johnson', 40, 'Pine Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '194 DAY', now() + INTERVAL '201 DAY', false, 74, 272);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '126 DAY', now() + INTERVAL '131 DAY', false, 13, 272);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '158 DAY', now() + INTERVAL '159 DAY', false, 147, 272);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 3, 'hotel3@hotels5.com', 139, 'Oak Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (82, 35, 117.50, 6, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (51, 35, 107.50, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (2, 35, 125.00, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (25, 35, 142.50, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (63, 35, 102.50, 6, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (273, 'Nick Reed', 35, 326, 'Third Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (273, 35);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (274, 'Paul Johnson', 35, 203, 'Third Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (275, 'Bob Price', 35, 326, 'First Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (276, 'Nick Ward', 35, 206, 'Oak Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (277, 'Paul Reed', 35, 207, 'Bank Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (278, 'Natalia Sanchez', 7, 'Main Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '127 DAY', now() + INTERVAL '133 DAY', false, 60, 278);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '167 DAY', now() + INTERVAL '172 DAY', false, 167, 278);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '139 DAY', now() + INTERVAL '145 DAY', false, 152, 278);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (279, 'David Sanchez', 234, 'Elm Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '105 DAY', now() + INTERVAL '112 DAY', false, 92, 279);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '73 DAY', now() + INTERVAL '77 DAY', false, 12, 279);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '103 DAY', now() + INTERVAL '108 DAY', false, 11, 279);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (280, 'Susan Cook', 23, 'Pine Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '23 DAY', now() + INTERVAL '29 DAY', false, 155, 280);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '141 DAY', now() + INTERVAL '148 DAY', false, 93, 280);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '131 DAY', now() + INTERVAL '132 DAY', false, 25, 280);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 4, 'hotel4@hotels5.com', 256, 'Pine Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 36, 133.33, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (63, 36, 136.67, 5, false, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (9, 36, 193.33, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (13, 36, 190.00, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (45, 36, 180.00, 4, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (281, 'Hudi Miller', 36, 326, 'Bay Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (281, 36);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (282, 'David Williams', 36, 266, 'First Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (283, 'Ashley Wood', 36, 391, 'Willow Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (284, 'Andrew Wood', 36, 60, 'Metcalfe Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (285, 'Hudi Price', 36, 163, 'Third Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (286, 'Ashley Smith', 186, 'First Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '159 DAY', now() + INTERVAL '161 DAY', false, 68, 286);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '203 DAY', now() + INTERVAL '209 DAY', false, 155, 286);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '89 DAY', now() + INTERVAL '94 DAY', false, 22, 286);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (287, 'Meg Jones', 200, 'Bank Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '68 DAY', now() + INTERVAL '75 DAY', false, 128, 287);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '62 DAY', now() + INTERVAL '68 DAY', false, 28, 287);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '89 DAY', now() + INTERVAL '92 DAY', false, 95, 287);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (288, 'Liam Sanchez', 81, 'Second Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '118 DAY', now() + INTERVAL '123 DAY', false, 121, 288);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 DAY', now() + INTERVAL '6 DAY', false, 45, 288);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '138 DAY', now() + INTERVAL '142 DAY', false, 125, 288);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 5, 'hotel5@hotels5.com', 276, 'Main Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 37, 191.67, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 37, 200.00, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (85, 37, 204.17, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (15, 37, 204.17, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 37, 166.67, 5, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (289, 'Bob Jones', 37, 82, 'Second Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (289, 37);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (290, 'Ryan Stewart', 37, 325, 'Bank Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (291, 'Sarah Sanchez', 37, 292, 'Bay Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (292, 'Andrew Rogers', 37, 349, 'Third Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (293, 'Andrew Jones', 37, 67, 'Oak Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (294, 'Mary Stewart', 248, 'First Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '63 DAY', now() + INTERVAL '70 DAY', false, 44, 294);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '164 DAY', now() + INTERVAL '167 DAY', false, 171, 294);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '122 DAY', now() + INTERVAL '129 DAY', false, 132, 294);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (295, 'Susan Hernandez', 262, 'Pine Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '87 DAY', now() + INTERVAL '88 DAY', false, 80, 295);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '164 DAY', now() + INTERVAL '169 DAY', false, 12, 295);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '98 DAY', now() + INTERVAL '101 DAY', false, 20, 295);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (296, 'Ashley Ward', 71, 'Third Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '92 DAY', false, 110, 296);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '58 DAY', now() + INTERVAL '61 DAY', false, 138, 296);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '208 DAY', now() + INTERVAL '209 DAY', false, 32, 296);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 1, 'hotel6@hotels5.com', 256, 'Main Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (40, 38, 36.67, 6, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 38, 47.50, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (17, 38, 43.33, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (51, 38, 49.17, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 38, 36.67, 2, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (297, 'Natalia Brown', 38, 38, 'First Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (297, 38);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (298, 'Jon Hernandez', 38, 75, 'Laurier Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (299, 'Ashley Sanchez', 38, 382, 'Metcalfe Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (300, 'Bob Rogers', 38, 385, 'Metcalfe Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (301, 'Sahil Cook', 38, 22, 'Pine Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (302, 'Mary Brown', 274, 'Bay Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '172 DAY', now() + INTERVAL '178 DAY', false, 88, 302);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '91 DAY', now() + INTERVAL '95 DAY', false, 55, 302);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '126 DAY', now() + INTERVAL '133 DAY', false, 51, 302);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (303, 'Ivana Stewart', 185, 'Elm Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '145 DAY', now() + INTERVAL '147 DAY', false, 101, 303);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '169 DAY', now() + INTERVAL '176 DAY', false, 138, 303);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '171 DAY', now() + INTERVAL '176 DAY', false, 109, 303);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (304, 'Bob Hernandez', 349, 'Laurier Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '95 DAY', now() + INTERVAL '100 DAY', false, 121, 304);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '118 DAY', now() + INTERVAL '120 DAY', false, 136, 304);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '26 DAY', now() + INTERVAL '33 DAY', false, 121, 304);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 2, 'hotel7@hotels5.com', 51, 'Elm Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (36, 39, 78.33, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (79, 39, 80.00, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 39, 98.33, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (57, 39, 68.33, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 39, 68.33, 4, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (305, 'David Cook', 39, 213, 'Metcalfe Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (305, 39);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (306, 'Jon Williams', 39, 378, 'Second Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (307, 'David Reed', 39, 302, 'Oak Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (308, 'Bob Davis', 39, 105, 'Pine Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (309, 'Susan Miller', 39, 17, 'Metcalfe Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (310, 'Nick Williams', 247, 'Oak Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '27 DAY', now() + INTERVAL '30 DAY', false, 53, 310);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '96 DAY', now() + INTERVAL '99 DAY', false, 96, 310);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '153 DAY', now() + INTERVAL '159 DAY', false, 40, 310);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (311, 'Paul Hernandez', 178, 'First Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '120 DAY', now() + INTERVAL '121 DAY', false, 119, 311);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '115 DAY', now() + INTERVAL '117 DAY', false, 4, 311);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '117 DAY', now() + INTERVAL '118 DAY', false, 169, 311);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (312, 'Meg Reed', 314, 'First Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '97 DAY', now() + INTERVAL '102 DAY', false, 100, 312);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '105 DAY', now() + INTERVAL '112 DAY', false, 77, 312);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '54 DAY', now() + INTERVAL '61 DAY', false, 111, 312);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 3, 'hotel8@hotels5.com', 101, 'First Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 40, 120.00, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 40, 135.00, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (100, 40, 127.50, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 40, 102.50, 6, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 40, 130.00, 6, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (313, 'Susan Reed', 40, 51, 'Third Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Manages(SSN, hotel_id) VALUES (313, 40);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (314, 'Bob Smith', 40, 26, 'Willow Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (315, 'Ivana Rogers', 40, 50, 'Elm Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (316, 'Bob Davis', 40, 26, 'Oak Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (317, 'Ryan Williams', 40, 390, 'First Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (318, 'Meg Williams', 24, 'Willow Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '93 DAY', now() + INTERVAL '97 DAY', false, 58, 318);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '164 DAY', now() + INTERVAL '170 DAY', false, 31, 318);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 DAY', now() + INTERVAL '5 DAY', false, 19, 318);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (319, 'Mary Wilson', 94, 'First Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '100 DAY', now() + INTERVAL '106 DAY', false, 108, 319);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '125 DAY', now() + INTERVAL '130 DAY', false, 62, 319);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '42 DAY', now() + INTERVAL '47 DAY', false, 124, 319);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (320, 'Ashley Johnson', 54, 'Elm Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '142 DAY', now() + INTERVAL '149 DAY', false, 34, 320);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '21 DAY', now() + INTERVAL '24 DAY', false, 12, 320);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '164 DAY', now() + INTERVAL '169 DAY', false, 151, 320);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (1, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (2, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (2, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (3, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (4, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (5, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (5, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (5, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (6, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (7, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (8, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (9, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (9, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (9, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (10, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (11, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (12, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (13, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (14, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (14, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (15, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (16, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (17, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (18, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (19, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (19, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (20, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (20, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (20, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (21, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (22, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (23, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (24, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (25, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (26, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (27, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (28, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (29, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (30, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (30, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (30, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (31, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (31, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (31, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (31, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (32, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (32, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (32, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (33, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (33, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (33, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (34, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (34, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (35, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (35, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (36, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (38, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (39, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (40, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (40, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (40, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (40, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (41, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (42, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (42, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (42, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (42, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (43, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (44, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (44, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (44, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (44, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (45, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (45, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (46, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (46, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (46, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (46, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (46, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (46, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (47, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (48, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (49, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (50, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (51, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (51, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (52, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (53, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (53, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (53, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (53, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (54, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (55, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (56, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (57, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (58, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (59, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (59, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (60, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (62, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (64, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (64, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (65, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (66, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (66, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (66, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (67, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (68, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (70, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (71, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (71, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (72, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (73, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (73, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (75, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (76, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (76, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (77, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (78, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (79, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (80, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (81, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (81, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (81, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (82, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (83, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (84, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (85, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (86, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (87, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (87, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (87, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (88, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (89, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (90, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (90, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (90, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (91, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (91, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (91, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (91, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (91, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (92, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (93, 'Air conditioner', NULL);
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
INSERT INTO Amenity(room_id, name, description) VALUES (96, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (98, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (99, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (100, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (101, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (101, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (101, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (102, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (103, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (104, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (105, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (105, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (105, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (106, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (106, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (106, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (107, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (108, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (108, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (108, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (108, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (109, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (110, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (111, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (112, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (112, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (112, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (113, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (114, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (115, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (116, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (116, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (116, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (116, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (116, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (117, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (117, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (117, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (118, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (119, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (120, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (121, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (122, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (123, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (123, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (123, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (123, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (124, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (125, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (125, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (126, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (127, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (128, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (128, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (128, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (129, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (130, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (131, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (132, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (133, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (134, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (135, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (136, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (137, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (138, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (139, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (140, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (141, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (142, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (143, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (144, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (145, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (145, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (145, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (146, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (147, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (147, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (147, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (147, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (148, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (149, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (150, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (152, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (153, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (154, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (154, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (155, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (156, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (157, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (158, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (159, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (160, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (161, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (161, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (162, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (163, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (163, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (163, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (164, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (164, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (164, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (165, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (165, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (166, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (166, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (167, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (168, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (169, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (169, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (169, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (170, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (171, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (172, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (173, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (174, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (175, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (175, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (175, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (175, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (175, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (176, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (177, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (178, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (178, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (179, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (180, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (181, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (182, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (183, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (184, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (185, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (185, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (186, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (186, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (186, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (187, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (187, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (187, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (188, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (189, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (190, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (191, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (192, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (192, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (192, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (192, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (193, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (194, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (194, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'TV', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (195, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (196, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (197, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (197, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'Mini-Fridge', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (198, 'Laundry Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (199, 'Air conditioner', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (200, 'Coffee Machine', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (200, 'Room service', NULL);
INSERT INTO Amenity(room_id, name, description) VALUES (200, 'Air conditioner', NULL);
INSERT INTO Role(name, description) VALUES ('Custodian', NULL);
INSERT INTO Role(name, description) VALUES ('Maid', NULL);
INSERT INTO Role(name, description) VALUES ('Bellboy', NULL);
INSERT INTO Role(name, description) VALUES ('Front Desk Person', NULL);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (2, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (3, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (4, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (5, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (10, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (11, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (12, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (13, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (18, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (19, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (20, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (21, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (26, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (27, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (28, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (29, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (34, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (35, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (36, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (37, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (42, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (43, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (44, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (45, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (50, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (51, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (52, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (53, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (58, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (59, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (60, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (61, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (66, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (67, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (68, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (69, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (74, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (75, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (76, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (77, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (82, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (83, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (84, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (85, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (90, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (91, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (92, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (93, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (98, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (99, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (100, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (101, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (106, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (107, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (108, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (109, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (114, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (115, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (116, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (117, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (122, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (123, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (124, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (125, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (130, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (131, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (132, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (133, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (138, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (139, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (140, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (141, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (146, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (147, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (148, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (149, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (154, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (155, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (156, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (157, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (162, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (163, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (164, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (165, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (170, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (171, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (172, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (173, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (178, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (179, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (180, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (181, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (186, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (187, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (188, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (189, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (194, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (195, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (196, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (197, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (202, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (203, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (204, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (205, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (210, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (211, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (212, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (213, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (218, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (219, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (220, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (221, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (226, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (227, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (228, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (229, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (234, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (235, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (236, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (237, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (242, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (243, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (244, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (245, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (250, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (251, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (252, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (253, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (258, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (259, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (260, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (261, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (266, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (267, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (268, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (269, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (274, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (275, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (276, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (277, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (282, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (283, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (284, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (285, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (290, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (291, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (292, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (293, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (298, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (299, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (300, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (301, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (306, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (307, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (308, 4);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (309, 1);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (314, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (315, 2);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (316, 3);
INSERT INTO EmployeeRole(employee_ssn, role_id) VALUES (317, 4);
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (1, '4457248524');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (2, '4065484179');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (3, '3734266527');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (4, '7435271200');
INSERT INTO ChainPhoneNumber(chain_id, phone_number) VALUES (5, '8684970723');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (1, '8474004723');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (2, '4041678920');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (3, '9496079969');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (4, '3668856214');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (5, '4620325196');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (6, '6712720898');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (7, '4580247286');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (8, '3086689500');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (9, '9770187667');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (10, '4531753298');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (11, '8405585570');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (12, '6422866142');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (13, '5187085053');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (14, '5511366644');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (15, '4760162505');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (16, '5482908011');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (17, '7072229638');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (18, '4273205428');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (19, '9011775254');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (20, '8546065340');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (21, '5931017596');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (22, '9071082320');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (23, '2002919160');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (24, '8457926709');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (25, '3248763476');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (26, '8519108808');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (27, '9314550824');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (28, '4501734193');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (29, '1771323533');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (30, '9296910528');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (31, '6404614489');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (32, '1374176219');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (33, '9701227554');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (34, '8072631074');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (35, '6612472252');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (36, '3456006633');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (37, '3073756619');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (38, '8162448282');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (39, '8508031823');
INSERT INTO HotelPhoneNumber(hotel_id, phone_number) VALUES (40, '5793037966');
