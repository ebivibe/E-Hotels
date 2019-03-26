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
    EXECUTE FUNCTION decr();DROP VIEW IF EXISTS employeeroles;
CREATE VIEW employeeroles AS
  SELECT r.role_id, er.employee_ssn as ssn, r.name, r.description
   FROM Role r
     INNER JOIN EmployeeRole er ON r.role_id = er.role_id ;

DROP VIEW IF EXISTS bookinginfo;
CREATE VIEW bookinginfo as
  SELECT br.booking_id, br.reservation_date, br.check_in_date, br.check_out_date, br.checked_in, br.paid, 
  r.room_number, hc.chain_name, h.street_number, h.street_name, h.unit, h.city, h.province, h.country, h.zip, br.employee_ssn,
  br.customer_ssn
  FROM BookingRental br
  INNER JOIN Room r on br.room_id = r.room_id
  INNER JOIN Hotel h on r.hotel_id = h.hotel_id
  INNER JOIN HotelChain hc on h.chain_id = hc.chain_id;

INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 1', 'hotel1@hotels.com', 112, 'First Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 1, 'hotel1@hotels1.com', 172, 'Elm Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (57, 1, 34.17, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 1, 41.67, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 1, 34.17, 6, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 1, 35.00, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (67, 1, 44.17, 3, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (1, 'Emily Perez', 1, 83, 'Willow Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (2, 'Jon Reed', 1, 265, 'Bay Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (3, 'Sahil Rogers', 1, 191, 'Second Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (4, 'Sahil Sanchez', 1, 268, 'First Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (5, 'Sarah Miller', 1, 199, 'Third Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (1, 'Hudi Jones', 48, 'Oak Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '126 DAY', now() + INTERVAL '130 DAY', false, 5, 1);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '37 DAY', now() + INTERVAL '38 DAY', false, 5, 1);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '93 DAY', now() + INTERVAL '94 DAY', false, 3, 1);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (2, 'Emily Price', 92, 'Second Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '178 DAY', now() + INTERVAL '183 DAY', false, 3, 2);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '106 DAY', now() + INTERVAL '110 DAY', false, 3, 2);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '59 DAY', now() + INTERVAL '66 DAY', false, 5, 2);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (3, 'Alex Price', 41, 'Laurier Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '208 DAY', now() + INTERVAL '215 DAY', false, 4, 3);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '21 DAY', now() + INTERVAL '26 DAY', false, 2, 3);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '161 DAY', now() + INTERVAL '163 DAY', false, 3, 3);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 2, 'hotel2@hotels1.com', 150, 'Willow Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (74, 2, 85.00, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (7, 2, 85.00, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (27, 2, 86.67, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (66, 2, 78.33, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (17, 2, 98.33, 6, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (6, 'Ashley Perez', 2, 145, 'Bank Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (7, 'Andrew Stewart', 2, 275, 'Bay Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (8, 'Mary Stewart', 2, 137, 'Laurier Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (9, 'Meg Ward', 2, 214, 'Oak Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (10, 'Ryan Wilson', 2, 366, 'Second Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (4, 'Nick Price', 9, 'Bay Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '154 DAY', now() + INTERVAL '155 DAY', false, 10, 4);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '108 DAY', now() + INTERVAL '111 DAY', false, 10, 4);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '123 DAY', now() + INTERVAL '130 DAY', false, 1, 4);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (5, 'Natalia Cook', 288, 'Elm Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '61 DAY', now() + INTERVAL '63 DAY', false, 6, 5);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '86 DAY', now() + INTERVAL '90 DAY', false, 2, 5);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '99 DAY', now() + INTERVAL '102 DAY', false, 10, 5);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (6, 'Ryan Reed', 278, 'Pine Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '86 DAY', now() + INTERVAL '92 DAY', false, 7, 6);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '92 DAY', now() + INTERVAL '93 DAY', false, 10, 6);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '114 DAY', now() + INTERVAL '117 DAY', false, 4, 6);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 3, 'hotel3@hotels1.com', 40, 'First Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (51, 3, 125.00, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (40, 3, 145.00, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (55, 3, 137.50, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (63, 3, 145.00, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (50, 3, 135.00, 4, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (11, 'Paul Brown', 3, 11, 'Metcalfe Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (12, 'Ivana Williams', 3, 131, 'Pine Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (13, 'Ryan Wood', 3, 160, 'Second Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (14, 'Emily Perez', 3, 336, 'Laurier Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (15, 'Alex Miller', 3, 120, 'Laurier Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (7, 'Ryan Hernandez', 381, 'Willow Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '129 DAY', now() + INTERVAL '132 DAY', false, 14, 7);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '199 DAY', now() + INTERVAL '205 DAY', false, 2, 7);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '34 DAY', now() + INTERVAL '41 DAY', false, 11, 7);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (8, 'Jon Davis', 9, 'Elm Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '38 DAY', now() + INTERVAL '40 DAY', false, 9, 8);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '40 DAY', now() + INTERVAL '45 DAY', false, 15, 8);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '170 DAY', now() + INTERVAL '173 DAY', false, 15, 8);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (9, 'Jon Reed', 103, 'Metcalfe Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '39 DAY', now() + INTERVAL '41 DAY', false, 7, 9);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '145 DAY', now() + INTERVAL '149 DAY', false, 14, 9);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '63 DAY', now() + INTERVAL '65 DAY', false, 10, 9);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 4, 'hotel4@hotels1.com', 155, 'Metcalfe Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 4, 190.00, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (77, 4, 143.33, 6, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 4, 150.00, 3, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (72, 4, 143.33, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 4, 173.33, 6, true, true, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (16, 'Sahil Reed', 4, 35, 'Bank Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (17, 'Sarah Brown', 4, 383, 'Main Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (18, 'Natalia Jones', 4, 243, 'Third Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (19, 'Hudi Young', 4, 164, 'Metcalfe Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (20, 'Ashley Davis', 4, 76, 'Bay Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (10, 'Hudi Brown', 211, 'Second Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '104 DAY', now() + INTERVAL '106 DAY', false, 3, 10);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '49 DAY', now() + INTERVAL '50 DAY', false, 19, 10);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '158 DAY', now() + INTERVAL '164 DAY', false, 7, 10);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (11, 'Ashley Rogers', 331, 'Willow Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '207 DAY', now() + INTERVAL '212 DAY', false, 20, 11);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '156 DAY', now() + INTERVAL '162 DAY', false, 18, 11);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '108 DAY', now() + INTERVAL '111 DAY', false, 11, 11);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (12, 'David Williams', 122, 'Laurier Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '71 DAY', now() + INTERVAL '75 DAY', false, 9, 12);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '7 DAY', now() + INTERVAL '12 DAY', false, 1, 12);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '165 DAY', now() + INTERVAL '167 DAY', false, 13, 12);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 5, 'hotel5@hotels1.com', 19, 'Bay Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (53, 5, 170.83, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 5, 212.50, 2, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (26, 5, 200.00, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (90, 5, 179.17, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (22, 5, 245.83, 4, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (21, 'Hudi Davis', 5, 55, 'Bank Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (22, 'Sahil Brown', 5, 300, 'Bay Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (23, 'Ashley Miller', 5, 386, 'Bank Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (24, 'Liam Price', 5, 399, 'Laurier Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (25, 'Hudi Cook', 5, 45, 'Bay Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (13, 'Elizabeth Young', 23, 'Second Avenue', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '92 DAY', false, 3, 13);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '54 DAY', now() + INTERVAL '57 DAY', false, 14, 13);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '190 DAY', now() + INTERVAL '192 DAY', false, 21, 13);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (14, 'Natalia Brown', 267, 'Oak Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '151 DAY', now() + INTERVAL '152 DAY', false, 25, 14);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '125 DAY', now() + INTERVAL '129 DAY', false, 14, 14);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '179 DAY', now() + INTERVAL '186 DAY', false, 14, 14);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (15, 'Alex Johnson', 377, 'Metcalfe Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '156 DAY', now() + INTERVAL '161 DAY', false, 5, 15);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '56 DAY', now() + INTERVAL '58 DAY', false, 3, 15);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '155 DAY', now() + INTERVAL '157 DAY', false, 25, 15);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 1, 'hotel6@hotels1.com', 298, 'Metcalfe Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (80, 6, 40.83, 5, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (40, 6, 47.50, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (30, 6, 40.00, 5, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 6, 45.83, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (16, 6, 33.33, 4, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (26, 'Paul Wood', 6, 1, 'Oak Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (27, 'Meg Hernandez', 6, 43, 'Willow Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (28, 'Sahil Sanchez', 6, 58, 'Pine Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (29, 'Bob Stewart', 6, 384, 'Laurier Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (30, 'Natalia Ward', 6, 207, 'Second Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (16, 'Natalia Young', 330, 'Pine Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '173 DAY', now() + INTERVAL '175 DAY', false, 27, 16);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '1 DAY', now() + INTERVAL '7 DAY', false, 11, 16);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '184 DAY', now() + INTERVAL '187 DAY', false, 15, 16);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (17, 'Meg Ward', 143, 'Elm Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '163 DAY', now() + INTERVAL '168 DAY', false, 9, 17);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '77 DAY', now() + INTERVAL '84 DAY', false, 27, 17);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '15 DAY', now() + INTERVAL '22 DAY', false, 12, 17);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (18, 'Ashley Sanchez', 38, 'Bay Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '91 DAY', now() + INTERVAL '95 DAY', false, 1, 18);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '20 DAY', now() + INTERVAL '23 DAY', false, 1, 18);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '168 DAY', now() + INTERVAL '175 DAY', false, 4, 18);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 2, 'hotel7@hotels1.com', 150, 'Main Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (38, 7, 78.33, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 7, 91.67, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (31, 7, 71.67, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (70, 7, 71.67, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (63, 7, 80.00, 3, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (31, 'Ashley Young', 7, 36, 'Willow Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (32, 'Bob Brown', 7, 394, 'Main Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (33, 'Susan Brown', 7, 110, 'First Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (34, 'Liam Hernandez', 7, 219, 'Laurier Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (35, 'Sarah Price', 7, 224, 'Metcalfe Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (19, 'Emily Stewart', 138, 'Laurier Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '84 DAY', now() + INTERVAL '88 DAY', false, 19, 19);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '139 DAY', now() + INTERVAL '145 DAY', false, 29, 19);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '182 DAY', now() + INTERVAL '183 DAY', false, 7, 19);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (20, 'Mary Rogers', 250, 'Oak Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '177 DAY', now() + INTERVAL '178 DAY', false, 12, 20);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '74 DAY', now() + INTERVAL '79 DAY', false, 32, 20);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '100 DAY', now() + INTERVAL '107 DAY', false, 6, 20);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (21, 'Ryan Perez', 368, 'Elm Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '140 DAY', now() + INTERVAL '144 DAY', false, 12, 21);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '75 DAY', now() + INTERVAL '82 DAY', false, 18, 21);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '165 DAY', now() + INTERVAL '170 DAY', false, 2, 21);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (1, 3, 'hotel8@hotels1.com', 34, 'Laurier Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (40, 8, 142.50, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (38, 8, 117.50, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (2, 8, 142.50, 6, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 8, 102.50, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 8, 137.50, 2, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (36, 'Ashley Smith', 8, 222, 'Third Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (37, 'Emily Ward', 8, 215, 'Third Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (38, 'Elizabeth Cook', 8, 382, 'Bank Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (39, 'Meg Stewart', 8, 375, 'Main Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (40, 'Jon Wood', 8, 269, 'Bay Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (22, 'Ryan Miller', 49, 'Bank Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '82 DAY', now() + INTERVAL '87 DAY', false, 26, 22);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '101 DAY', now() + INTERVAL '106 DAY', false, 11, 22);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '178 DAY', now() + INTERVAL '179 DAY', false, 20, 22);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (23, 'Elizabeth Jones', 175, 'Elm Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '53 DAY', now() + INTERVAL '58 DAY', false, 36, 23);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '84 DAY', now() + INTERVAL '91 DAY', false, 4, 23);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '142 DAY', now() + INTERVAL '148 DAY', false, 37, 23);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (24, 'Bob Reed', 270, 'Willow Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '8 DAY', now() + INTERVAL '12 DAY', false, 17, 24);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '139 DAY', now() + INTERVAL '142 DAY', false, 26, 24);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '200 DAY', now() + INTERVAL '204 DAY', false, 24, 24);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 2', 'hotel2@hotels.com', 91, 'Main Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 1, 'hotel1@hotels2.com', 189, 'First Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (13, 9, 45.83, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 9, 45.83, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 9, 47.50, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (94, 9, 39.17, 4, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (64, 9, 35.83, 3, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (41, 'Susan Johnson', 9, 51, 'Willow Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (42, 'Emily Jones', 9, 172, 'Elm Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (43, 'Meg Wood', 9, 112, 'Second Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (44, 'Ivana Williams', 9, 273, 'Bank Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (45, 'Alex Stewart', 9, 370, 'Metcalfe Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (25, 'Nick Ward', 290, 'First Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '185 DAY', now() + INTERVAL '187 DAY', false, 30, 25);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '56 DAY', now() + INTERVAL '61 DAY', false, 45, 25);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '58 DAY', now() + INTERVAL '63 DAY', false, 9, 25);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (26, 'Mary Wood', 291, 'Willow Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '210 DAY', now() + INTERVAL '212 DAY', false, 45, 26);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '15 DAY', now() + INTERVAL '22 DAY', false, 36, 26);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '95 DAY', now() + INTERVAL '99 DAY', false, 26, 26);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (27, 'Natalia Jones', 368, 'Third Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '157 DAY', now() + INTERVAL '159 DAY', false, 22, 27);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '209 DAY', now() + INTERVAL '213 DAY', false, 37, 27);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '168 DAY', now() + INTERVAL '172 DAY', false, 24, 27);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 2, 'hotel2@hotels2.com', 135, 'Bay Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 10, 96.67, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (91, 10, 86.67, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (85, 10, 66.67, 5, false, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (65, 10, 73.33, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 10, 85.00, 5, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (46, 'Liam Jones', 10, 218, 'Laurier Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (47, 'Paul Stewart', 10, 183, 'Third Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (48, 'Sahil Young', 10, 190, 'Laurier Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (49, 'Jon Hernandez', 10, 116, 'Pine Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (50, 'Mary Ward', 10, 372, 'Metcalfe Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (28, 'Emily Reed', 375, 'Main Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '55 DAY', now() + INTERVAL '60 DAY', false, 49, 28);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '131 DAY', now() + INTERVAL '133 DAY', false, 24, 28);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '167 DAY', now() + INTERVAL '172 DAY', false, 36, 28);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (29, 'Sarah Johnson', 291, 'Metcalfe Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '130 DAY', now() + INTERVAL '132 DAY', false, 9, 29);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '22 DAY', now() + INTERVAL '29 DAY', false, 5, 29);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '106 DAY', now() + INTERVAL '112 DAY', false, 9, 29);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (30, 'Elizabeth Hernandez', 204, 'Pine Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '197 DAY', now() + INTERVAL '199 DAY', false, 32, 30);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '44 DAY', now() + INTERVAL '45 DAY', false, 24, 30);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '51 DAY', now() + INTERVAL '57 DAY', false, 28, 30);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 3, 'hotel3@hotels2.com', 32, 'Laurier Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (70, 11, 100.00, 4, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (23, 11, 130.00, 5, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (2, 11, 150.00, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (61, 11, 115.00, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 11, 147.50, 5, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (51, 'David Jones', 11, 207, 'First Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (52, 'Nick Young', 11, 100, 'First Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (53, 'Ryan Ward', 11, 252, 'Metcalfe Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (54, 'Nick Williams', 11, 191, 'Metcalfe Street', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (55, 'Bob Jones', 11, 133, 'Laurier Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (31, 'Elizabeth Miller', 44, 'Second Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '185 DAY', now() + INTERVAL '187 DAY', false, 12, 31);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '186 DAY', now() + INTERVAL '190 DAY', false, 22, 31);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '91 DAY', now() + INTERVAL '94 DAY', false, 9, 31);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (32, 'Ryan Stewart', 305, 'First Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '39 DAY', now() + INTERVAL '44 DAY', false, 17, 32);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '33 DAY', now() + INTERVAL '40 DAY', false, 8, 32);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '113 DAY', now() + INTERVAL '119 DAY', false, 26, 32);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (33, 'Ivana Ward', 124, 'Willow Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '9 DAY', now() + INTERVAL '14 DAY', false, 29, 33);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '15 DAY', now() + INTERVAL '22 DAY', false, 5, 33);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '56 DAY', now() + INTERVAL '62 DAY', false, 2, 33);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 4, 'hotel4@hotels2.com', 118, 'First Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (12, 12, 140.00, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (24, 12, 153.33, 6, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (80, 12, 133.33, 4, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 12, 160.00, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (33, 12, 190.00, 4, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (56, 'Elizabeth Brown', 12, 172, 'First Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (57, 'Sarah Sanchez', 12, 357, 'Second Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (58, 'Elizabeth Ward', 12, 342, 'Laurier Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (59, 'Ashley Hernandez', 12, 77, 'Willow Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (60, 'Mary Miller', 12, 81, 'Third Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (34, 'Ryan Sanchez', 337, 'Third Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '107 DAY', now() + INTERVAL '112 DAY', false, 19, 34);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '111 DAY', now() + INTERVAL '112 DAY', false, 38, 34);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '110 DAY', now() + INTERVAL '112 DAY', false, 22, 34);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (35, 'David Reed', 337, 'Bay Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '76 DAY', now() + INTERVAL '78 DAY', false, 54, 35);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '18 DAY', now() + INTERVAL '25 DAY', false, 21, 35);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '124 DAY', now() + INTERVAL '126 DAY', false, 40, 35);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (36, 'Andrew Stewart', 255, 'Willow Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '121 DAY', now() + INTERVAL '127 DAY', false, 27, 36);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '208 DAY', now() + INTERVAL '215 DAY', false, 31, 36);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '0 DAY', now() + INTERVAL '1 DAY', false, 60, 36);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 5, 'hotel5@hotels2.com', 293, 'Laurier Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (17, 13, 229.17, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 13, 187.50, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (72, 13, 183.33, 4, false, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 13, 204.17, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (98, 13, 200.00, 4, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (61, 'Sarah Brown', 13, 19, 'Elm Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (62, 'David Williams', 13, 133, 'Metcalfe Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (63, 'Ashley Rogers', 13, 287, 'First Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (64, 'David Hernandez', 13, 95, 'First Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (65, 'Meg Young', 13, 229, 'Bank Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (37, 'Susan Rogers', 349, 'First Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '124 DAY', now() + INTERVAL '128 DAY', false, 22, 37);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '206 DAY', now() + INTERVAL '207 DAY', false, 41, 37);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '108 DAY', now() + INTERVAL '115 DAY', false, 48, 37);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (38, 'Sahil Miller', 190, 'Bank Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '66 DAY', now() + INTERVAL '69 DAY', false, 13, 38);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '178 DAY', now() + INTERVAL '179 DAY', false, 31, 38);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '173 DAY', now() + INTERVAL '175 DAY', false, 34, 38);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (39, 'Ryan Rogers', 183, 'First Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '75 DAY', now() + INTERVAL '79 DAY', false, 49, 39);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '152 DAY', now() + INTERVAL '156 DAY', false, 24, 39);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '174 DAY', now() + INTERVAL '181 DAY', false, 37, 39);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 1, 'hotel6@hotels2.com', 94, 'Pine Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (97, 14, 36.67, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (70, 14, 35.00, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 14, 47.50, 5, true, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 14, 45.00, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 14, 44.17, 2, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (66, 'Natalia Hernandez', 14, 350, 'Metcalfe Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (67, 'Bob Smith', 14, 323, 'Oak Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (68, 'Bob Perez', 14, 13, 'Second Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (69, 'Paul Davis', 14, 35, 'Metcalfe Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (70, 'Meg Reed', 14, 56, 'Willow Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (40, 'Jon Johnson', 115, 'Pine Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '164 DAY', now() + INTERVAL '170 DAY', false, 64, 40);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '8 DAY', now() + INTERVAL '13 DAY', false, 9, 40);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '93 DAY', now() + INTERVAL '97 DAY', false, 35, 40);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (41, 'Hudi Sanchez', 16, 'Oak Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '170 DAY', now() + INTERVAL '172 DAY', false, 2, 41);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '164 DAY', now() + INTERVAL '171 DAY', false, 56, 41);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '47 DAY', now() + INTERVAL '48 DAY', false, 6, 41);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (42, 'Alex Wood', 331, 'Bank Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '20 DAY', now() + INTERVAL '21 DAY', false, 27, 42);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '91 DAY', false, 17, 42);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '101 DAY', now() + INTERVAL '106 DAY', false, 47, 42);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 2, 'hotel7@hotels2.com', 66, 'Metcalfe Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 15, 76.67, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 15, 70.00, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (91, 15, 88.33, 6, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 15, 91.67, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (28, 15, 95.00, 2, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (71, 'Jon Ward', 15, 174, 'Pine Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (72, 'Meg Williams', 15, 223, 'Main Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (73, 'Emily Ward', 15, 332, 'Metcalfe Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (74, 'Ashley Wood', 15, 74, 'Oak Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (75, 'Ivana Sanchez', 15, 252, 'Willow Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (43, 'Sarah Young', 114, 'Oak Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '106 DAY', now() + INTERVAL '108 DAY', false, 31, 43);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '209 DAY', now() + INTERVAL '214 DAY', false, 71, 43);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '48 DAY', now() + INTERVAL '49 DAY', false, 53, 43);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (44, 'Jon Ward', 12, 'Laurier Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '50 DAY', now() + INTERVAL '52 DAY', false, 10, 44);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '127 DAY', now() + INTERVAL '130 DAY', false, 26, 44);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '129 DAY', now() + INTERVAL '130 DAY', false, 38, 44);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (45, 'Ivana Price', 171, 'Laurier Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '140 DAY', now() + INTERVAL '144 DAY', false, 32, 45);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '12 DAY', now() + INTERVAL '15 DAY', false, 43, 45);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '145 DAY', now() + INTERVAL '149 DAY', false, 64, 45);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (2, 3, 'hotel8@hotels2.com', 282, 'Bank Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (13, 16, 132.50, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (57, 16, 120.00, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (13, 16, 147.50, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (61, 16, 147.50, 4, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (53, 16, 107.50, 4, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (76, 'Paul Reed', 16, 263, 'Third Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (77, 'Emily Young', 16, 213, 'Third Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (78, 'Jon Wood', 16, 45, 'Third Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (79, 'Natalia Perez', 16, 44, 'Main Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (80, 'Ryan Sanchez', 16, 21, 'Metcalfe Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (46, 'Paul Hernandez', 177, 'Oak Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '50 DAY', now() + INTERVAL '52 DAY', false, 31, 46);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '28 DAY', now() + INTERVAL '35 DAY', false, 71, 46);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '3 DAY', now() + INTERVAL '4 DAY', false, 42, 46);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (47, 'Elizabeth Sanchez', 313, 'Oak Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '95 DAY', false, 21, 47);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '22 DAY', now() + INTERVAL '24 DAY', false, 42, 47);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '27 DAY', now() + INTERVAL '29 DAY', false, 21, 47);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (48, 'Emily Johnson', 378, 'Oak Street', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '105 DAY', now() + INTERVAL '111 DAY', false, 61, 48);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '53 DAY', now() + INTERVAL '59 DAY', false, 69, 48);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '18 DAY', now() + INTERVAL '23 DAY', false, 72, 48);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 3', 'hotel3@hotels.com', 8, 'Pine Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 1, 'hotel1@hotels3.com', 248, 'Second Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (73, 17, 44.17, 5, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (88, 17, 47.50, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (70, 17, 45.83, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (52, 17, 45.83, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (30, 17, 35.83, 4, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (81, 'Paul Reed', 17, 164, 'First Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (82, 'Sahil Young', 17, 43, 'Elm Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (83, 'Paul Smith', 17, 76, 'Bank Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (84, 'Hudi Williams', 17, 108, 'Pine Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (85, 'Liam Williams', 17, 343, 'Third Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (49, 'Natalia Young', 9, 'Metcalfe Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '90 DAY', now() + INTERVAL '97 DAY', false, 47, 49);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '65 DAY', now() + INTERVAL '71 DAY', false, 11, 49);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '195 DAY', now() + INTERVAL '198 DAY', false, 19, 49);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (50, 'Meg Price', 125, 'Willow Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '152 DAY', now() + INTERVAL '158 DAY', false, 66, 50);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '51 DAY', now() + INTERVAL '52 DAY', false, 26, 50);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '6 DAY', now() + INTERVAL '10 DAY', false, 14, 50);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (51, 'Liam Davis', 312, 'Bank Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '134 DAY', now() + INTERVAL '141 DAY', false, 55, 51);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '64 DAY', now() + INTERVAL '71 DAY', false, 16, 51);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '46 DAY', now() + INTERVAL '53 DAY', false, 48, 51);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 2, 'hotel2@hotels3.com', 23, 'Oak Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (77, 18, 85.00, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (75, 18, 91.67, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (15, 18, 86.67, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (39, 18, 93.33, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (41, 18, 71.67, 4, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (86, 'Hudi Ward', 18, 264, 'Laurier Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (87, 'Hudi Smith', 18, 231, 'Oak Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (88, 'David Wilson', 18, 7, 'Willow Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (89, 'Ashley Reed', 18, 301, 'Pine Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (90, 'Nick Cook', 18, 86, 'Second Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (52, 'David Hernandez', 62, 'Metcalfe Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '123 DAY', now() + INTERVAL '126 DAY', false, 18, 52);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '70 DAY', now() + INTERVAL '75 DAY', false, 6, 52);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '6 DAY', now() + INTERVAL '11 DAY', false, 80, 52);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (53, 'Emily Sanchez', 108, 'Willow Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '81 DAY', now() + INTERVAL '82 DAY', false, 47, 53);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '83 DAY', now() + INTERVAL '88 DAY', false, 38, 53);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '109 DAY', now() + INTERVAL '114 DAY', false, 52, 53);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (54, 'Jon Wilson', 312, 'Main Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '84 DAY', now() + INTERVAL '89 DAY', false, 10, 54);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '79 DAY', now() + INTERVAL '82 DAY', false, 74, 54);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '160 DAY', now() + INTERVAL '167 DAY', false, 6, 54);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 3, 'hotel3@hotels3.com', 103, 'First Street', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 19, 125.00, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (1, 19, 112.50, 6, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (21, 19, 102.50, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (18, 19, 125.00, 5, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 19, 150.00, 3, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (91, 'Natalia Johnson', 19, 137, 'Oak Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (92, 'Sarah Davis', 19, 220, 'Third Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (93, 'Emily Wood', 19, 165, 'Willow Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (94, 'Ryan Wood', 19, 85, 'Laurier Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (95, 'Elizabeth Stewart', 19, 356, 'Second Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (55, 'Paul Ward', 108, 'Metcalfe Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '5 DAY', now() + INTERVAL '7 DAY', false, 84, 55);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '150 DAY', now() + INTERVAL '156 DAY', false, 79, 55);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '76 DAY', now() + INTERVAL '80 DAY', false, 38, 55);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (56, 'Ivana Wood', 94, 'Metcalfe Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '13 DAY', now() + INTERVAL '20 DAY', false, 15, 56);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '81 DAY', now() + INTERVAL '83 DAY', false, 16, 56);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '135 DAY', now() + INTERVAL '137 DAY', false, 5, 56);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (57, 'Ryan Miller', 365, 'Elm Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '141 DAY', now() + INTERVAL '148 DAY', false, 58, 57);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '130 DAY', now() + INTERVAL '135 DAY', false, 80, 57);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '0 DAY', now() + INTERVAL '2 DAY', false, 65, 57);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 4, 'hotel4@hotels3.com', 210, 'Bay Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 20, 143.33, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (87, 20, 146.67, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (33, 20, 166.67, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 20, 160.00, 4, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 20, 180.00, 5, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (96, 'Elizabeth Reed', 20, 11, 'Pine Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (97, 'Paul Stewart', 20, 72, 'Bay Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (98, 'David Smith', 20, 37, 'Pine Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (99, 'Nick Reed', 20, 7, 'First Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (100, 'Sarah Rogers', 20, 389, 'Willow Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (58, 'Sahil Brown', 211, 'Bank Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '35 DAY', now() + INTERVAL '42 DAY', false, 91, 58);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '157 DAY', now() + INTERVAL '162 DAY', false, 4, 58);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '180 DAY', now() + INTERVAL '183 DAY', false, 63, 58);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (59, 'Alex Miller', 389, 'Willow Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '98 DAY', now() + INTERVAL '100 DAY', false, 37, 59);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '31 DAY', now() + INTERVAL '38 DAY', false, 63, 59);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '71 DAY', now() + INTERVAL '72 DAY', false, 29, 59);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (60, 'Mary Ward', 46, 'Pine Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '87 DAY', now() + INTERVAL '91 DAY', false, 41, 60);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '210 DAY', now() + INTERVAL '217 DAY', false, 6, 60);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '125 DAY', now() + INTERVAL '132 DAY', false, 10, 60);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 5, 'hotel5@hotels3.com', 203, 'Bay Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 21, 166.67, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (38, 21, 245.83, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (41, 21, 229.17, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 21, 245.83, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (35, 21, 195.83, 5, false, false, true, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (101, 'Mary Cook', 21, 343, 'Bank Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (102, 'Emily Brown', 21, 15, 'Bank Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (103, 'Ivana Reed', 21, 32, 'Willow Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (104, 'Susan Stewart', 21, 259, 'Oak Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (105, 'Nick Ward', 21, 177, 'Metcalfe Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (61, 'Sarah Sanchez', 31, 'Third Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '210 DAY', now() + INTERVAL '213 DAY', false, 44, 61);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '122 DAY', now() + INTERVAL '124 DAY', false, 64, 61);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '98 DAY', now() + INTERVAL '99 DAY', false, 94, 61);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (62, 'Mary Smith', 359, 'Main Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '83 DAY', now() + INTERVAL '86 DAY', false, 98, 62);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '80 DAY', now() + INTERVAL '86 DAY', false, 37, 62);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '31 DAY', now() + INTERVAL '36 DAY', false, 95, 62);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (63, 'Jon Cook', 298, 'Main Boulevard', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '42 DAY', now() + INTERVAL '45 DAY', false, 1, 63);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '107 DAY', now() + INTERVAL '108 DAY', false, 91, 63);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '104 DAY', now() + INTERVAL '110 DAY', false, 2, 63);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 1, 'hotel6@hotels3.com', 83, 'Main Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 22, 35.00, 4, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 22, 40.83, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (67, 22, 49.17, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (19, 22, 39.17, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (18, 22, 50.00, 3, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (106, 'David Williams', 22, 162, 'Metcalfe Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (107, 'Natalia Ward', 22, 377, 'Pine Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (108, 'Nick Ward', 22, 316, 'Oak Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (109, 'Sahil Rogers', 22, 383, 'Main Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (110, 'Nick Price', 22, 109, 'Main Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (64, 'Mary Brown', 334, 'Second Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '57 DAY', now() + INTERVAL '59 DAY', false, 53, 64);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '128 DAY', now() + INTERVAL '132 DAY', false, 73, 64);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '151 DAY', now() + INTERVAL '153 DAY', false, 45, 64);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (65, 'Susan Brown', 196, 'Main Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '152 DAY', now() + INTERVAL '153 DAY', false, 104, 65);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '89 DAY', now() + INTERVAL '96 DAY', false, 12, 65);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '189 DAY', now() + INTERVAL '190 DAY', false, 61, 65);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (66, 'Hudi Ward', 239, 'Oak Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '48 DAY', now() + INTERVAL '55 DAY', false, 3, 66);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '163 DAY', now() + INTERVAL '168 DAY', false, 79, 66);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '4 DAY', now() + INTERVAL '8 DAY', false, 68, 66);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 2, 'hotel7@hotels3.com', 264, 'Elm Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (31, 23, 96.67, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (52, 23, 78.33, 5, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 23, 95.00, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 23, 100.00, 5, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (18, 23, 96.67, 6, false, false, true, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (111, 'David Wilson', 23, 131, 'Bay Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (112, 'Emily Wood', 23, 168, 'Metcalfe Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (113, 'Nick Hernandez', 23, 365, 'Willow Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (114, 'Natalia Reed', 23, 334, 'Bank Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (115, 'Ashley Ward', 23, 147, 'Oak Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (67, 'Ivana Johnson', 184, 'Third Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '9 DAY', now() + INTERVAL '10 DAY', false, 24, 67);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '81 DAY', now() + INTERVAL '87 DAY', false, 104, 67);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '38 DAY', now() + INTERVAL '42 DAY', false, 78, 67);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (68, 'Ivana Cook', 352, 'Oak Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '209 DAY', now() + INTERVAL '213 DAY', false, 42, 68);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '102 DAY', now() + INTERVAL '103 DAY', false, 88, 68);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '145 DAY', now() + INTERVAL '148 DAY', false, 47, 68);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (69, 'Emily Price', 347, 'Pine Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '21 DAY', now() + INTERVAL '28 DAY', false, 31, 69);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '57 DAY', now() + INTERVAL '59 DAY', false, 35, 69);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '132 DAY', now() + INTERVAL '136 DAY', false, 62, 69);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (3, 3, 'hotel8@hotels3.com', 189, 'Willow Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (40, 24, 142.50, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (82, 24, 132.50, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (82, 24, 100.00, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (97, 24, 115.00, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 24, 102.50, 4, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (116, 'Meg Ward', 24, 29, 'Main Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (117, 'Sarah Johnson', 24, 35, 'Willow Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (118, 'Elizabeth Stewart', 24, 17, 'Main Street', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (119, 'Ashley Ward', 24, 58, 'Bank Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (120, 'Nick Jones', 24, 348, 'Third Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (70, 'Ryan Davis', 80, 'Bay Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '13 DAY', now() + INTERVAL '18 DAY', false, 84, 70);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '115 DAY', now() + INTERVAL '121 DAY', false, 79, 70);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '62 DAY', now() + INTERVAL '67 DAY', false, 58, 70);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (71, 'Meg Hernandez', 303, 'Second Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '197 DAY', now() + INTERVAL '200 DAY', false, 115, 71);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '145 DAY', now() + INTERVAL '149 DAY', false, 13, 71);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '22 DAY', now() + INTERVAL '24 DAY', false, 112, 71);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (72, 'Sarah Williams', 251, 'Willow Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '208 DAY', now() + INTERVAL '214 DAY', false, 48, 72);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '87 DAY', now() + INTERVAL '88 DAY', false, 114, 72);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '79 DAY', now() + INTERVAL '85 DAY', false, 36, 72);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 4', 'hotel4@hotels.com', 76, 'Elm Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 1, 'hotel1@hotels4.com', 148, 'First Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (39, 25, 45.83, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (14, 25, 39.17, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (25, 25, 40.83, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (9, 25, 47.50, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 25, 49.17, 2, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (121, 'Bob Wood', 25, 349, 'Metcalfe Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (122, 'Alex Smith', 25, 66, 'Elm Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (123, 'Liam Wood', 25, 162, 'Elm Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (124, 'Alex Sanchez', 25, 304, 'Bank Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (125, 'Liam Young', 25, 249, 'Elm Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (73, 'Ashley Davis', 298, 'First Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '127 DAY', now() + INTERVAL '128 DAY', false, 27, 73);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '37 DAY', now() + INTERVAL '43 DAY', false, 2, 73);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '2 DAY', now() + INTERVAL '6 DAY', false, 49, 73);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (74, 'Emily Price', 173, 'Second Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '193 DAY', now() + INTERVAL '195 DAY', false, 17, 74);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '18 DAY', now() + INTERVAL '24 DAY', false, 66, 74);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '148 DAY', now() + INTERVAL '150 DAY', false, 100, 74);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (75, 'Susan Young', 75, 'Main Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '119 DAY', now() + INTERVAL '125 DAY', false, 99, 75);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '87 DAY', now() + INTERVAL '94 DAY', false, 85, 75);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '102 DAY', now() + INTERVAL '105 DAY', false, 39, 75);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 2, 'hotel2@hotels4.com', 203, 'Main Lane', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (70, 26, 78.33, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (77, 26, 73.33, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (67, 26, 70.00, 6, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (51, 26, 78.33, 3, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (15, 26, 80.00, 5, true, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (126, 'Jon Reed', 26, 276, 'Bank Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (127, 'Ashley Williams', 26, 168, 'Second Lane', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (128, 'Paul Hernandez', 26, 379, 'Pine Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (129, 'Sahil Reed', 26, 373, 'Willow Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (130, 'David Ward', 26, 60, 'Willow Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (76, 'Ashley Sanchez', 154, 'Main Crescent', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '165 DAY', now() + INTERVAL '172 DAY', false, 116, 76);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '201 DAY', now() + INTERVAL '205 DAY', false, 84, 76);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '64 DAY', now() + INTERVAL '67 DAY', false, 27, 76);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (77, 'Nick Smith', 85, 'Pine Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '127 DAY', now() + INTERVAL '133 DAY', false, 31, 77);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '35 DAY', now() + INTERVAL '42 DAY', false, 52, 77);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '84 DAY', now() + INTERVAL '89 DAY', false, 16, 77);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (78, 'Hudi Reed', 201, 'Elm Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '200 DAY', now() + INTERVAL '201 DAY', false, 70, 78);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '111 DAY', now() + INTERVAL '117 DAY', false, 6, 78);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '201 DAY', now() + INTERVAL '207 DAY', false, 119, 78);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 3, 'hotel3@hotels4.com', 59, 'Metcalfe Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 27, 147.50, 5, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 27, 125.00, 6, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (7, 27, 115.00, 4, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 27, 145.00, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (5, 27, 105.00, 3, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (131, 'Hudi Hernandez', 27, 28, 'Willow Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (132, 'Mary Price', 27, 323, 'First Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (133, 'Paul Reed', 27, 365, 'Second Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (134, 'Sahil Hernandez', 27, 367, 'First Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (135, 'Andrew Wilson', 27, 5, 'Pine Crescent', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (79, 'Sahil Rogers', 46, 'Metcalfe Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '14 DAY', now() + INTERVAL '20 DAY', false, 64, 79);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '122 DAY', now() + INTERVAL '125 DAY', false, 2, 79);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '119 DAY', now() + INTERVAL '123 DAY', false, 123, 79);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (80, 'Ivana Miller', 266, 'Oak Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '80 DAY', now() + INTERVAL '87 DAY', false, 122, 80);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '124 DAY', now() + INTERVAL '130 DAY', false, 133, 80);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '71 DAY', now() + INTERVAL '77 DAY', false, 63, 80);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (81, 'Ashley Brown', 73, 'Bank Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '46 DAY', now() + INTERVAL '47 DAY', false, 118, 81);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '182 DAY', now() + INTERVAL '188 DAY', false, 117, 81);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '185 DAY', now() + INTERVAL '186 DAY', false, 99, 81);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 4, 'hotel4@hotels4.com', 217, 'Elm Boulevard', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (92, 28, 183.33, 2, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (46, 28, 143.33, 6, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (55, 28, 136.67, 6, false, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (10, 28, 146.67, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (44, 28, 143.33, 3, true, false, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (136, 'Sarah Ward', 28, 44, 'Metcalfe Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (137, 'Elizabeth Williams', 28, 307, 'Willow Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (138, 'Liam Rogers', 28, 126, 'Laurier Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (139, 'Sarah Sanchez', 28, 195, 'Pine Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (140, 'Nick Reed', 28, 112, 'Third Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (82, 'Ivana Sanchez', 358, 'Second Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '84 DAY', now() + INTERVAL '87 DAY', false, 41, 82);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '157 DAY', now() + INTERVAL '159 DAY', false, 38, 82);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '94 DAY', false, 135, 82);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (83, 'Emily Stewart', 296, 'Willow Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '83 DAY', now() + INTERVAL '90 DAY', false, 125, 83);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '63 DAY', now() + INTERVAL '68 DAY', false, 46, 83);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '136 DAY', now() + INTERVAL '138 DAY', false, 98, 83);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (84, 'Ivana Cook', 65, 'Bay Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '84 DAY', now() + INTERVAL '85 DAY', false, 47, 84);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '170 DAY', now() + INTERVAL '172 DAY', false, 97, 84);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '124 DAY', now() + INTERVAL '129 DAY', false, 121, 84);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 5, 'hotel5@hotels4.com', 51, 'First Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 29, 166.67, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (87, 29, 166.67, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (100, 29, 191.67, 5, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 29, 195.83, 4, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 29, 195.83, 5, false, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (141, 'David Jones', 29, 135, 'Third Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (142, 'Mary Rogers', 29, 346, 'Second Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (143, 'Alex Johnson', 29, 393, 'Metcalfe Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (144, 'Alex Perez', 29, 400, 'Willow Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (145, 'Bob Jones', 29, 154, 'Metcalfe Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (85, 'Meg Davis', 154, 'Metcalfe Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '65 DAY', now() + INTERVAL '71 DAY', false, 9, 85);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '96 DAY', now() + INTERVAL '99 DAY', false, 93, 85);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '140 DAY', now() + INTERVAL '146 DAY', false, 94, 85);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (86, 'Ivana Brown', 65, 'Metcalfe Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '38 DAY', now() + INTERVAL '43 DAY', false, 133, 86);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '114 DAY', now() + INTERVAL '115 DAY', false, 20, 86);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '103 DAY', now() + INTERVAL '108 DAY', false, 127, 86);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (87, 'Sarah Williams', 184, 'First Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '137 DAY', now() + INTERVAL '142 DAY', false, 18, 87);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '201 DAY', now() + INTERVAL '206 DAY', false, 67, 87);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '113 DAY', now() + INTERVAL '119 DAY', false, 127, 87);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 1, 'hotel6@hotels4.com', 104, 'Elm Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (45, 30, 43.33, 3, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (50, 30, 45.83, 6, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (77, 30, 34.17, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (45, 30, 35.00, 5, true, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (56, 30, 47.50, 3, true, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (146, 'Sahil Miller', 30, 374, 'Pine Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (147, 'Emily Sanchez', 30, 89, 'Oak Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (148, 'Hudi Davis', 30, 357, 'Laurier Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (149, 'Liam Cook', 30, 134, 'Elm Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (150, 'Andrew Reed', 30, 132, 'Elm Avenue', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (88, 'Andrew Brown', 121, 'Bank Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '19 DAY', now() + INTERVAL '22 DAY', false, 124, 88);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '67 DAY', now() + INTERVAL '70 DAY', false, 48, 88);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '176 DAY', now() + INTERVAL '182 DAY', false, 1, 88);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (89, 'Nick Williams', 85, 'Oak Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '11 DAY', now() + INTERVAL '12 DAY', false, 59, 89);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '210 DAY', now() + INTERVAL '217 DAY', false, 19, 89);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '206 DAY', now() + INTERVAL '211 DAY', false, 148, 89);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (90, 'Andrew Stewart', 207, 'Oak Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '70 DAY', now() + INTERVAL '75 DAY', false, 95, 90);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '178 DAY', now() + INTERVAL '184 DAY', false, 52, 90);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '161 DAY', now() + INTERVAL '165 DAY', false, 142, 90);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 2, 'hotel7@hotels4.com', 223, 'Bay Street', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (34, 31, 98.33, 4, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (71, 31, 91.67, 3, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (43, 31, 91.67, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (82, 31, 93.33, 2, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (49, 31, 81.67, 3, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (151, 'Sarah Wood', 31, 221, 'Elm Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (152, 'Ashley Reed', 31, 231, 'Willow Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (153, 'Ashley Hernandez', 31, 275, 'Third Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (154, 'Hudi Young', 31, 258, 'Pine Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (155, 'Mary Cook', 31, 49, 'Main Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (91, 'Natalia Jones', 201, 'Pine Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '13 DAY', now() + INTERVAL '16 DAY', false, 44, 91);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '206 DAY', now() + INTERVAL '210 DAY', false, 32, 91);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '62 DAY', now() + INTERVAL '68 DAY', false, 149, 91);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (92, 'Elizabeth Smith', 130, 'Bank Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '181 DAY', now() + INTERVAL '187 DAY', false, 139, 92);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '130 DAY', now() + INTERVAL '136 DAY', false, 77, 92);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '60 DAY', now() + INTERVAL '62 DAY', false, 152, 92);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (93, 'Liam Reed', 78, 'Bank Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '99 DAY', now() + INTERVAL '101 DAY', false, 139, 93);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '58 DAY', now() + INTERVAL '60 DAY', false, 39, 93);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '114 DAY', now() + INTERVAL '115 DAY', false, 64, 93);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (4, 3, 'hotel8@hotels4.com', 138, 'Bay Boulevard', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (9, 32, 142.50, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (80, 32, 125.00, 6, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (22, 32, 110.00, 6, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 32, 122.50, 6, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (85, 32, 132.50, 4, false, true, true, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (156, 'Liam Price', 32, 312, 'Willow Lane', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (157, 'Sahil Jones', 32, 49, 'Elm Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (158, 'Bob Hernandez', 32, 298, 'Elm Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (159, 'Hudi Hernandez', 32, 283, 'Metcalfe Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (160, 'Elizabeth Williams', 32, 351, 'Bank Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (94, 'Ivana Johnson', 80, 'Metcalfe Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '17 DAY', now() + INTERVAL '23 DAY', false, 45, 94);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '160 DAY', now() + INTERVAL '166 DAY', false, 154, 94);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '152 DAY', now() + INTERVAL '157 DAY', false, 8, 94);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (95, 'Emily Wood', 132, 'Second Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '141 DAY', now() + INTERVAL '147 DAY', false, 4, 95);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '201 DAY', now() + INTERVAL '203 DAY', false, 9, 95);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '138 DAY', now() + INTERVAL '142 DAY', false, 48, 95);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (96, 'Bob Perez', 222, 'Oak Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '67 DAY', now() + INTERVAL '71 DAY', false, 36, 96);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '74 DAY', now() + INTERVAL '80 DAY', false, 44, 96);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '12 DAY', now() + INTERVAL '16 DAY', false, 112, 96);
INSERT INTO HotelChain(chain_name, email, street_number, street_name, city, province, country, zip) VALUES ('Hotels 5', 'hotel5@hotels.com', 67, 'Bay Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 1, 'hotel1@hotels5.com', 285, 'Oak Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (6, 33, 39.17, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (63, 33, 41.67, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (86, 33, 50.00, 2, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (28, 33, 33.33, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (76, 33, 41.67, 3, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (161, 'Hudi Young', 33, 202, 'Oak Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (162, 'Jon Brown', 33, 27, 'First Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (163, 'Andrew Perez', 33, 6, 'Oak Street', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (164, 'Paul Stewart', 33, 257, 'Metcalfe Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (165, 'Elizabeth Brown', 33, 11, 'Laurier Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (97, 'Elizabeth Rogers', 371, 'Oak Lane', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '107 DAY', now() + INTERVAL '110 DAY', false, 136, 97);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '73 DAY', now() + INTERVAL '76 DAY', false, 80, 97);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '21 DAY', now() + INTERVAL '24 DAY', false, 133, 97);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (98, 'Andrew Jones', 170, 'Laurier Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '40 DAY', now() + INTERVAL '45 DAY', false, 82, 98);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '140 DAY', now() + INTERVAL '145 DAY', false, 123, 98);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '117 DAY', now() + INTERVAL '124 DAY', false, 12, 98);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (99, 'Emily Rogers', 105, 'Bank Way', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '142 DAY', now() + INTERVAL '148 DAY', false, 87, 99);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '80 DAY', now() + INTERVAL '84 DAY', false, 159, 99);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '101 DAY', now() + INTERVAL '108 DAY', false, 100, 99);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 2, 'hotel2@hotels5.com', 254, 'Third Crescent', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (8, 34, 90.00, 2, false, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (60, 34, 88.33, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (89, 34, 78.33, 5, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (51, 34, 80.00, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (40, 34, 66.67, 4, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (166, 'David Wilson', 34, 227, 'Bank Street', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (167, 'Bob Reed', 34, 22, 'Bay Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (168, 'Ivana Brown', 34, 190, 'Metcalfe Crescent', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (169, 'Ashley Cook', 34, 201, 'Oak Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (170, 'Natalia Wilson', 34, 279, 'Main Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (100, 'Andrew Miller', 320, 'Third Avenue', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '65 DAY', now() + INTERVAL '67 DAY', false, 6, 100);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '144 DAY', now() + INTERVAL '146 DAY', false, 25, 100);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '15 DAY', now() + INTERVAL '18 DAY', false, 61, 100);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (101, 'Meg Williams', 339, 'Metcalfe Avenue', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '110 DAY', now() + INTERVAL '113 DAY', false, 58, 101);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '59 DAY', now() + INTERVAL '64 DAY', false, 130, 101);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '144 DAY', now() + INTERVAL '149 DAY', false, 137, 101);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (102, 'Hudi Hernandez', 339, 'Bay Avenue', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '25 DAY', now() + INTERVAL '30 DAY', false, 66, 102);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '144 DAY', now() + INTERVAL '147 DAY', false, 91, 102);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '60 DAY', now() + INTERVAL '65 DAY', false, 71, 102);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 3, 'hotel3@hotels5.com', 268, 'Metcalfe Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (25, 35, 112.50, 2, true, false, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 35, 132.50, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 35, 100.00, 5, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (29, 35, 122.50, 4, false, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (4, 35, 115.00, 2, false, true, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (171, 'Meg Ward', 35, 55, 'Metcalfe Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (172, 'Nick Hernandez', 35, 244, 'Laurier Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (173, 'Liam Young', 35, 150, 'Third Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (174, 'Susan Johnson', 35, 124, 'Second Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (175, 'Hudi Wilson', 35, 391, 'Elm Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (103, 'Mary Cook', 355, 'Bay Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '64 DAY', now() + INTERVAL '68 DAY', false, 91, 103);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '55 DAY', now() + INTERVAL '61 DAY', false, 89, 103);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '87 DAY', now() + INTERVAL '88 DAY', false, 15, 103);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (104, 'Liam Sanchez', 386, 'Third Boulevard', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '134 DAY', now() + INTERVAL '136 DAY', false, 47, 104);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '114 DAY', now() + INTERVAL '120 DAY', false, 85, 104);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '186 DAY', now() + INTERVAL '188 DAY', false, 10, 104);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (105, 'Mary Johnson', 355, 'Laurier Lane', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '36 DAY', now() + INTERVAL '37 DAY', false, 1, 105);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '179 DAY', now() + INTERVAL '181 DAY', false, 99, 105);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '45 DAY', now() + INTERVAL '48 DAY', false, 30, 105);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 4, 'hotel4@hotels5.com', 193, 'Metcalfe Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (53, 36, 136.67, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (98, 36, 186.67, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 36, 193.33, 3, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (23, 36, 136.67, 5, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (62, 36, 176.67, 2, true, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (176, 'Alex Ward', 36, 271, 'Elm Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (177, 'Jon Young', 36, 327, 'Bank Way', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (178, 'Liam Price', 36, 41, 'Second Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (179, 'Nick Stewart', 36, 265, 'Pine Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (180, 'Meg Hernandez', 36, 126, 'Pine Boulevard', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (106, 'Liam Perez', 363, 'First Crescent', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '21 DAY', now() + INTERVAL '23 DAY', false, 83, 106);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '90 DAY', now() + INTERVAL '91 DAY', false, 142, 106);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '114 DAY', now() + INTERVAL '115 DAY', false, 109, 106);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (107, 'Ashley Wood', 287, 'Willow Avenue', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '128 DAY', now() + INTERVAL '130 DAY', false, 142, 107);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '22 DAY', now() + INTERVAL '29 DAY', false, 99, 107);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '106 DAY', now() + INTERVAL '109 DAY', false, 128, 107);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (108, 'Ashley Sanchez', 35, 'Second Avenue', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '174 DAY', now() + INTERVAL '175 DAY', false, 78, 108);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '90 DAY', now() + INTERVAL '91 DAY', false, 83, 108);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '125 DAY', now() + INTERVAL '129 DAY', false, 95, 108);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 5, 'hotel5@hotels5.com', 8, 'Metcalfe Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 37, 170.83, 4, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (98, 37, 208.33, 3, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 37, 195.83, 2, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (58, 37, 200.00, 2, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (15, 37, 208.33, 5, true, false, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (181, 'Bob Johnson', 37, 107, 'Elm Boulevard', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (182, 'Bob Price', 37, 147, 'Elm Street', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (183, 'Natalia Smith', 37, 306, 'Second Crescent', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (184, 'Ivana Hernandez', 37, 32, 'Willow Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (185, 'Mary Jones', 37, 307, 'Elm Crescent', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (109, 'Sahil Sanchez', 225, 'Bank Avenue', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '50 DAY', now() + INTERVAL '53 DAY', false, 115, 109);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '108 DAY', now() + INTERVAL '112 DAY', false, 182, 109);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '96 DAY', now() + INTERVAL '97 DAY', false, 130, 109);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (110, 'Natalia Price', 251, 'Main Street', 'Ottawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '70 DAY', now() + INTERVAL '75 DAY', false, 166, 110);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '5 DAY', now() + INTERVAL '11 DAY', false, 172, 110);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '27 DAY', now() + INTERVAL '32 DAY', false, 144, 110);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (111, 'Hudi Perez', 147, 'Elm Avenue', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '91 DAY', now() + INTERVAL '95 DAY', false, 103, 111);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '142 DAY', now() + INTERVAL '145 DAY', false, 11, 111);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '32 DAY', now() + INTERVAL '36 DAY', false, 125, 111);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 1, 'hotel6@hotels5.com', 61, 'Elm Way', 'London', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (32, 38, 42.50, 5, false, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (48, 38, 34.17, 4, true, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (74, 38, 45.00, 4, true, true, true, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (81, 38, 49.17, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (31, 38, 43.33, 6, true, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (186, 'Ivana Reed', 38, 25, 'Metcalfe Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (187, 'Bob Perez', 38, 202, 'Metcalfe Crescent', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (188, 'Sahil Hernandez', 38, 321, 'Pine Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (189, 'Jon Jones', 38, 314, 'Pine Street', 'Hamilton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (190, 'Bob Hernandez', 38, 249, 'Pine Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (112, 'Paul Jones', 77, 'Metcalfe Lane', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '80 DAY', now() + INTERVAL '81 DAY', false, 38, 112);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '155 DAY', now() + INTERVAL '161 DAY', false, 29, 112);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '45 DAY', now() + INTERVAL '48 DAY', false, 122, 112);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (113, 'Elizabeth Miller', 284, 'First Lane', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '138 DAY', now() + INTERVAL '140 DAY', false, 22, 113);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '5 DAY', now() + INTERVAL '8 DAY', false, 41, 113);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '160 DAY', now() + INTERVAL '165 DAY', false, 156, 113);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (114, 'Ivana Smith', 53, 'Metcalfe Lane', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '32 DAY', now() + INTERVAL '38 DAY', false, 74, 114);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '206 DAY', now() + INTERVAL '209 DAY', false, 176, 114);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '67 DAY', now() + INTERVAL '73 DAY', false, 81, 114);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 2, 'hotel7@hotels5.com', 40, 'Elm Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (58, 39, 78.33, 6, false, false, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (95, 39, 73.33, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (2, 39, 100.00, 2, true, true, true, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (11, 39, 90.00, 4, false, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (87, 39, 66.67, 4, false, true, false, false);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (191, 'Ryan Miller', 39, 348, 'Second Lane', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (192, 'Alex Ward', 39, 14, 'Elm Way', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (193, 'Alex Williams', 39, 229, 'Third Boulevard', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (194, 'Hudi Price', 39, 359, 'Bay Way', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (195, 'Ashley Wood', 39, 267, 'First Way', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (115, 'Nick Wood', 368, 'First Lane', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '10 DAY', now() + INTERVAL '11 DAY', false, 178, 115);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '125 DAY', now() + INTERVAL '132 DAY', false, 2, 115);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '118 DAY', now() + INTERVAL '121 DAY', false, 113, 115);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (116, 'Susan Wilson', 208, 'Oak Street', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '176 DAY', now() + INTERVAL '177 DAY', false, 52, 116);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '138 DAY', now() + INTERVAL '141 DAY', false, 8, 116);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '70 DAY', now() + INTERVAL '73 DAY', false, 150, 116);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (117, 'Hudi Davis', 310, 'Third Way', 'London', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '111 DAY', now() + INTERVAL '113 DAY', false, 16, 117);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '54 DAY', now() + INTERVAL '58 DAY', false, 25, 117);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '61 DAY', now() + INTERVAL '67 DAY', false, 168, 117);
INSERT INTO Hotel(chain_id, category, email, street_number, street_name, city, province, country, zip) VALUES (5, 3, 'hotel8@hotels5.com', 204, 'Bank Way', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1');
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (42, 40, 147.50, 5, true, false, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 40, 122.50, 2, true, true, false, true);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (93, 40, 115.00, 3, false, true, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (83, 40, 115.00, 2, false, false, false, false);
INSERT INTO Room(room_number, hotel_id, price, capacity, sea_view, mountain_view, damages, can_be_extended) VALUES (59, 40, 150.00, 6, false, false, false, true);
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (196, 'Susan Rogers', 40, 350, 'Metcalfe Boulevard', 'Brampton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (197, 'Elizabeth Smith', 40, 341, 'Bay Boulevard', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (198, 'Liam Ward', 40, 46, 'Elm Way', 'Oshawa', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (199, 'Jon Stewart', 40, 359, 'Second Boulevard', 'Mississauga', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Employee(ssn, name, hotel_id, street_number, street_name, city, province, country, zip, password) VALUES (200, 'Sarah Young', 40, 245, 'Willow Crescent', 'Oakville', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (118, 'Hudi Davis', 108, 'Second Way', 'Milton', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '88 DAY', now() + INTERVAL '94 DAY', false, 90, 118);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '148 DAY', now() + INTERVAL '152 DAY', false, 102, 118);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '165 DAY', now() + INTERVAL '169 DAY', false, 105, 118);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (119, 'Elizabeth Young', 236, 'Metcalfe Way', 'Toronto', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '118 DAY', now() + INTERVAL '121 DAY', false, 94, 119);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '19 DAY', now() + INTERVAL '25 DAY', false, 19, 119);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '69 DAY', now() + INTERVAL '73 DAY', false, 17, 119);
INSERT INTO Customer(ssn, name, street_number, street_name, city, province, country, zip, password) VALUES (120, 'Emily Price', 380, 'Oak Avenue', 'Stratford', 'Ontario', 'Canada', 'X1X 1X1', 'password');
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '84 DAY', now() + INTERVAL '89 DAY', false, 150, 120);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '82 DAY', now() + INTERVAL '86 DAY', false, 58, 120);
INSERT INTO BookingRental(reservation_date, check_in_date, check_out_date, checked_in, room_id, customer_ssn) VALUES (now(), now() + INTERVAL '182 DAY', now() + INTERVAL '183 DAY', false, 199, 120);
